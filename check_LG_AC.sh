#!/usr/bin/env bash
set -u

# Compatibility wrapper for Zabbix template legacy format:
# status;temp_atual;temp_meta;modo;ventilador;consumo

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
V2_TEST_SCRIPT="${SCRIPT_DIR}/v2/teste.py"
PYTHON_BIN="${PYTHON_BIN:-python3}"

DEVICE_ID=""

while getopts ":D:C:A:" opt; do
  case "$opt" in
    D) DEVICE_ID="$OPTARG" ;;
    C) : ;;  # kept for backward compatibility
    A) : ;;  # kept for backward compatibility
    *) ;;
  esac
done

if [[ -z "$DEVICE_ID" ]]; then
  echo "0;;;;;"
  exit 1
fi

if [[ ! -f "$V2_TEST_SCRIPT" ]]; then
  echo "0;;;;;"
  exit 2
fi

RAW_JSON="$($PYTHON_BIN "$V2_TEST_SCRIPT" status "$DEVICE_ID" --raw 2>/dev/null)"
if [[ -z "$RAW_JSON" ]]; then
  echo "0;;;;;"
  exit 3
fi

OUTPUT="$($PYTHON_BIN - "$RAW_JSON" <<'PY'
import json
import math
import sys

try:
    data = json.loads(sys.argv[1])
except Exception:
    print("0;;;;;")
    raise SystemExit(1)

op_mode = ((data.get("operation") or {}).get("airConOperationMode") or "").upper()
status = "1" if op_mode == "POWER_ON" else "0"

# Keep integer-only output for compatibility with current regex preprocessing.
def to_int_str(value, default=""):
    try:
        return str(int(round(float(value))))
    except Exception:
        return default

cur_temp = to_int_str((data.get("temperature") or {}).get("currentTemperature"), "")
tgt_temp = to_int_str((data.get("temperature") or {}).get("targetTemperature"), "")

job_mode = ((data.get("airConJobMode") or {}).get("currentJobMode") or "UNK").upper()
# Legacy template expects 3-4 chars for mode
if len(job_mode) > 4:
    job_mode = job_mode[:4]
if not job_mode:
    job_mode = "UNK"

fan = ((data.get("airFlow") or {}).get("windStrength") or "UNK").upper()
if len(fan) > 4:
    fan = fan[:4]
if not fan:
    fan = "UNK"

# ThinQ Connect state endpoint may not include real-time power in all models.
# Keep field for template compatibility.
consumo = "0"

print(f"{status};{cur_temp};{tgt_temp};{job_mode};{fan};{consumo}")
PY
)"

if [[ -z "$OUTPUT" ]]; then
  echo "0;;;;;"
  exit 4
fi

echo "$OUTPUT"
exit 0
