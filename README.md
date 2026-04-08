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

## Arquivo lg_v2_state.json

Funcao do arquivo:
- Guardar estado local da integracao v2 para reutilizacao entre execucoes.
- Armazenar principalmente `client_id` (UUID gerado automaticamente) e `country`.

Importante:
- Ele **nao** guarda o PAT/token secreto.
- O token deve ficar em `.env`, variavel de ambiente ou outro local seguro.

## Requisitos

- Python 3
- Biblioteca `requests`
- Personal Access Token (PAT) do ThinQ Connect

Instalacao de dependencia:

```bash
pip3 install requests
```

## Download Para Zabbix

Para baixar direto no diretorio de scripts externos do Zabbix:

```bash
cd /usr/lib/zabbix/externalscripts
git clone https://github.com/andrebolzan/API_LG_ZABBIX.git
cd API_LG_ZABBIX
```

## Permissoes E Diretorio No Zabbix

Ajuste owner/permissoes da pasta:

```bash
sudo chown -R zabbix:zabbix /usr/lib/zabbix/externalscripts/API_LG_ZABBIX
sudo chmod -R 750 /usr/lib/zabbix/externalscripts/API_LG_ZABBIX
```

Configure o diretorio de scripts externos no Zabbix:

- Server: arquivo `zabbix_server.conf`
- Proxy: arquivo `zabbix_proxy.conf`
- Parametro: `ExternalScripts`

Exemplo:

```conf
ExternalScripts=/usr/lib/zabbix/externalscripts/API_LG_ZABBIX
```

Depois reinicie o servico correspondente:

```bash
sudo systemctl restart zabbix-server
# ou
sudo systemctl restart zabbix-proxy
```

## Como Criar o PAT

1. Acesse: `https://connect-pat.lgthinq.com`
2. Faca login com a conta ThinQ.
3. Clique em `ADD NEW TOKEN`.
4. Informe o nome do token.
5. Selecione os recursos (features) que deseja usar.
6. Clique em `CREATE TOKEN`.
7. Copie o token gerado para uso no script.

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

Criar o arquivo `.env` automaticamente:

```bash
cat > .env <<'EOF'
PAT=SEU_PAT
LG_THINQ_COUNTRY=BR
EOF
```

## Comandos

Listar dispositivos (alias;tipo;id):

```bash
python3 teste.py ls
```

Importante para Zabbix:
- O `ID` retornado no `ls` e o identificador que voce deve usar no template/macro do Zabbix.
- Guarde esse `ID` corretamente para cada equipamento monitorado.

Listar dispositivos em JSON:

```bash
python3 teste.py ls --raw
```

Sobre `--raw`:
- O `--raw` exibe todos os dados retornados pela API em JSON (saida completa, sem resumo).

Status de um dispositivo:

```bash
python3 teste.py status <DEVICE_ID> --raw
```

Perfil de um dispositivo:

```bash
python3 teste.py profile <DEVICE_ID> --raw
```

## Grafana (Automatico com Zabbix)

Arquivo pronto para import:
- `grafana_dashboard_zabbix_v2.json`

Esse dashboard usa variaveis para listar automaticamente os equipamentos (hosts) do grupo selecionado no Zabbix.

Passos:
1. Importe o arquivo `grafana_dashboard_zabbix_v2.json` no Grafana.
2. Selecione o datasource do Zabbix (plugin `alexanderzobnin-zabbix-datasource`).
3. Em `Grupo`, escolha o grupo onde estao os hosts com o template LG v2.
4. O dashboard passa a exibir automaticamente todos os hosts/equipamentos desse grupo.
