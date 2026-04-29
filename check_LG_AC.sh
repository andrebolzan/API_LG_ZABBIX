#!/usr/bin/env bash
set -u

# Compatibility wrapper for Zabbix template legacy format:
# status;temp_atual;temp_meta;modo;ventilador;consumo

# Fixed install path for Zabbix execution.
BASE_DIR="/usr/lib/zabbix/externalscripts/API_LG_ZABBIX"
V2_TEST_SCRIPT="${BASE_DIR}/lg_cli.py"
ENV_FILE="${BASE_DIR}/.env"
PYTHON_BIN="${PYTHON_BIN:-/usr/bin/python3}"

show_help() {
  cat <<'EOF'
Uso:
  ./check_LG_AC.sh -D <DEVICE_ID>
  ./check_LG_AC.sh --ls

Opcoes:
  -D <DEVICE_ID>   Device ID do equipamento LG (obrigatorio)
  --ls             Lista dispositivos (alias;tipo;id)
  -C <valor>       Reservado para compatibilidade (ignorado)
  -A <valor>       Reservado para compatibilidade (ignorado)
  -h, --help       Exibe esta ajuda
EOF
}

check_env_permissions() {
  # Require .env to not be accessible by "others".
  if [[ -f "$ENV_FILE" ]] && command -v stat >/dev/null 2>&1; then
    local perm other
    perm="$(stat -c '%a' "$ENV_FILE" 2>/dev/null || true)"
    other="${perm: -1}"
    if [[ -n "$other" ]] && (( 10#$other > 0 )); then
      echo "Permissao insegura em $ENV_FILE (use chmod 640 ou 600)." >&2
      exit 10
    fi
  fi
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  show_help
  exit 0
fi

if [[ ! -x "$PYTHON_BIN" ]]; then
  PYTHON_BIN="$(command -v python3 || true)"
fi

check_env_permissions

# Load token/country from fixed absolute .env path.
if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

if [[ "${1:-}" == "--ls" ]]; then
  if [[ ! -f "$V2_TEST_SCRIPT" ]]; then
    echo "Arquivo nao encontrado: $V2_TEST_SCRIPT" >&2
    exit 2
  fi
  exec "$PYTHON_BIN" "$V2_TEST_SCRIPT" ls
fi

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
