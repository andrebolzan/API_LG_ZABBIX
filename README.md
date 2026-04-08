# API LG Zabbix (V2 Token Method)

Repositorio focado no novo metodo oficial da LG ThinQ Connect com autenticacao por token (PAT).

## Estrutura

- `v2/API_LG.py`: cliente principal ThinQ Connect v2.
- `v2/teste.py`: atalho para testes locais.
- `v2/README.md`: documentacao detalhada do fluxo v2.
- `check_LG_AC.sh`: wrapper para compatibilidade com item antigo do Zabbix.

## Referencia oficial

- https://smartsolution.developer.lge.com/en/apiManage/thinq_connect?s=1775682127433
- https://github.com/thinq-connect/pythinqconnect

## Uso rapido

```bash
cd v2
python3 teste.py ls --raw
python3 teste.py status <DEVICE_ID> --raw
```
