#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="/usr/lib/zabbix/externalscripts/API_LG"
STATE_FILE="${TARGET_DIR}/wideq_state.json"

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    echo "Este script precisa ser executado como root (use sudo)."
    exit 1
  fi
}

check_source_files() {
  local missing=0
  for path in "${SCRIPT_DIR}/API_LG.py" "${SCRIPT_DIR}/wideq"; do
    if [[ ! -e "${path}" ]]; then
      echo "Arquivo/pasta obrigatorio nao encontrado: ${path}"
      missing=1
    fi
  done
  if [[ "${missing}" -ne 0 ]]; then
    exit 1
  fi
}

install_python_deps() {
  if python3 -c "import requests" >/dev/null 2>&1; then
    echo "Dependencia Python requests ja instalada."
    return
  fi

  echo "Instalando dependencia Python: requests"
  if command -v apt-get >/dev/null 2>&1; then
    apt-get update
    apt-get install -y python3-requests
  elif command -v dnf >/dev/null 2>&1; then
    dnf install -y python3-requests
  elif command -v yum >/dev/null 2>&1; then
    yum install -y python3-requests
  elif command -v zypper >/dev/null 2>&1; then
    zypper install -y python3-requests
  else
    echo "Gerenciador de pacotes nao suportado. Instale manualmente: pip3 install requests"
    exit 1
  fi
}

copy_project_files() {
  mkdir -p "${TARGET_DIR}"

  cp -f "${SCRIPT_DIR}/API_LG.py" "${TARGET_DIR}/API_LG.py"

  rm -rf "${TARGET_DIR}/wideq"
  cp -a "${SCRIPT_DIR}/wideq" "${TARGET_DIR}/wideq"

  if [[ ! -f "${STATE_FILE}" ]]; then
    echo '{"gateway": {}, "auth": {}}' > "${STATE_FILE}"
  fi

  chmod 755 "${TARGET_DIR}/API_LG.py"
  find "${TARGET_DIR}/wideq" -type f -name "*.py" -exec chmod 644 {} \;
}

fix_owner_if_possible() {
  if getent passwd zabbix >/dev/null 2>&1 && getent group zabbix >/dev/null 2>&1; then
    chown -R zabbix:zabbix "${TARGET_DIR}"
    echo "Permissoes ajustadas para zabbix:zabbix"
  else
    echo "Usuario/grupo zabbix nao encontrado. Ajuste o owner manualmente se necessario."
  fi
}

main() {
  require_root
  check_source_files
  install_python_deps
  copy_project_files
  fix_owner_if_possible

  echo
  echo "Instalacao concluida em: ${TARGET_DIR}"
  echo "Teste rapido: sudo -u zabbix python3 ${TARGET_DIR}/API_LG.py -c BR -l en-US ls"
}

main "$@"
