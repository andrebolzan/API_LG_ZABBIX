# API LG Zabbix - V2 (Token / ThinQ Connect)

Esta pasta contem uma versao nova baseada na API oficial ThinQ Connect da LG.

Fontes oficiais:
- https://smartsolution.developer.lge.com/en/apiManage/thinq_connect?s=1775682127433
- https://github.com/thinq-connect/pythinqconnect

## Estrutura

- `API_LG.py`: cliente principal da API v2 (token/PAT).
- `teste.py`: atalho para testar rapidamente o mesmo cliente.
- `lg_v2_state.json`: arquivo local gerado automaticamente para guardar `client_id` e `country`.

## Requisitos

- Python 3
- Biblioteca `requests`
- Personal Access Token (PAT) do ThinQ Connect

Instalacao de dependencia:

```bash
pip3 install requests
```

## Como obter token (PAT)

1. Acesse a documentacao oficial ThinQ Connect:
   https://smartsolution.developer.lge.com/en/apiManage/thinq_connect?s=1775682127433
2. No portal LG Developer, gere seu Personal Access Token (PAT).
3. Guarde esse token com seguranca.

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

Opcao 3 - por arquivo local do usuario:

```bash
mkdir -p ~/.config/lg-thinq
echo "SEU_PAT" > ~/.config/lg-thinq/token
echo "BR" > ~/.config/lg-thinq/country
chmod 600 ~/.config/lg-thinq/token
python3 API_LG.py ls
```

## Comandos

Listar dispositivos:

```bash
python3 API_LG.py ls
```

Listar dispositivos (JSON formatado):

```bash
python3 API_LG.py ls --raw
```

Status de um dispositivo:

```bash
python3 API_LG.py status <DEVICE_ID> --raw
```

Perfil de um dispositivo:

```bash
python3 API_LG.py profile <DEVICE_ID> --raw
```

## Observacoes

- Esta implementacao usa autenticacao por token (PAT), sem fluxo interativo de callback OAuth antigo.
- O `client_id` e gerado automaticamente (UUID) e salvo em `lg_v2_state.json`.
- Para uso no Zabbix, prefira armazenar o token em variavel de ambiente segura ou arquivo com permissao restrita.
