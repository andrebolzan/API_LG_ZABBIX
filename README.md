# API LG Zabbix (V2 Token Method)

Repositorio focado no metodo oficial da LG ThinQ Connect com autenticacao por token (PAT).

Fontes oficiais:
- https://smartsolution.developer.lge.com/en/apiManage/thinq_connect?s=1775682127433
- https://github.com/thinq-connect/pythinqconnect

## Estrutura

- `API_LG.py`: cliente principal da API v2 (token/PAT).
- `teste.py`: atalho para testar rapidamente o mesmo cliente.
- `check_LG_AC.sh`: wrapper para compatibilidade com item antigo do Zabbix.
- `lg_v2_state.json`: arquivo local gerado automaticamente para guardar `client_id` e `country`.

## Requisitos

- Python 3
- Biblioteca `requests`
- Personal Access Token (PAT) do ThinQ Connect

Instalacao de dependencia:

```bash
pip3 install requests
```

## Formas de informar o token

Opcao 1 - por parametro:

```bash
python3 API_LG.py --token "SEU_PAT" -c BR ls
```

Opcao 2 - por variavel de ambiente:

```bash
export LG_THINQ_TOKEN="SEU_PAT"
export LG_THINQ_COUNTRY="BR"
python3 API_LG.py ls
```

Opcao 3 - por arquivo `.env` na raiz do projeto:

```bash
PAT=SEU_PAT
LG_THINQ_COUNTRY=BR
```

## Comandos

Listar dispositivos (alias;tipo;id):

```bash
python3 teste.py ls
```

Listar dispositivos em JSON:

```bash
python3 teste.py ls --raw
```

Status de um dispositivo:

```bash
python3 teste.py status <DEVICE_ID> --raw
```

Perfil de um dispositivo:

```bash
python3 teste.py profile <DEVICE_ID> --raw
```
