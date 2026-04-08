# API LG para Zabbix

Script Python para integrar dispositivos LG ThinQ (API v2) com o Zabbix via `externalscripts`.

## Base do projeto

Este projeto e baseado em `wideq`, de Sampson (Adrian Sampson):

- https://github.com/sampsyo/wideq

Neste repositorio, a logica customizada fica principalmente em `API_LG.py`.
O `wideq` e obtido do repositorio oficial durante a instalacao para manter a versao atualizada.

## Conteudo do repositorio

- `API_LG.py`: script principal para autenticar, listar dispositivos e executar comandos.
- `install.sh`: instalador automatico para ambiente Zabbix.
- `autenticacaoAPI.txt`: anotacoes de autenticacao e testes.

## Requisitos

- Linux com Zabbix Server/Proxy
- Python 3
- Usuario `zabbix` no sistema
- Acesso a internet para autenticar com a conta LG

## Instalacao

1. Clone este repositorio no servidor Zabbix.
2. Execute o instalador como root:

```bash
sudo bash install.sh
```

O instalador faz:

- Copia `API_LG.py` para `/usr/lib/zabbix/externalscripts/API_LG`
- Baixa o `wideq` direto de `https://github.com/sampsyo/wideq` (com fallback para copia local)
- Cria `/usr/lib/zabbix/externalscripts/API_LG/wideq_state.json` (se nao existir)
- Ajusta permissoes e owner para `zabbix:zabbix` (quando usuario/grupo existem)
- Instala `python3-requests` e `git` (dependencias obrigatorias)

## Primeira autenticacao LG

Execute como usuario do Zabbix:

```bash
sudo -u zabbix python3 /usr/lib/zabbix/externalscripts/API_LG/API_LG.py -c BR -l en-US ls
```

Na primeira execucao, o script vai:

1. Exibir a URL de login LG
2. Pedir a URL de retorno (callback)
3. Salvar o token em `wideq_state.json`

## Testes basicos

Listar dispositivos:

```bash
sudo -u zabbix python3 /usr/lib/zabbix/externalscripts/API_LG/API_LG.py -c BR -l en-US ls
```

Ler informacoes de um dispositivo:

```bash
sudo -u zabbix python3 /usr/lib/zabbix/externalscripts/API_LG/API_LG.py -c BR -l en-US info <DEVICE_ID>
```

Ligar/desligar (AC):

```bash
sudo -u zabbix python3 /usr/lib/zabbix/externalscripts/API_LG/API_LG.py -c BR -l en-US turn <DEVICE_ID> on
sudo -u zabbix python3 /usr/lib/zabbix/externalscripts/API_LG/API_LG.py -c BR -l en-US turn <DEVICE_ID> off
```

## Comandos suportados

- `ls`
- `mon <DEVICE_ID>`
- `info <DEVICE_ID>`
- `turn <DEVICE_ID> on|off`
- `set-temp <DEVICE_ID> <TEMP>`
- `set-temp-freezer <DEVICE_ID> <TEMP>`
- `set-temp-hot-water <DEVICE_ID> <TEMP>`
- `ac-config <DEVICE_ID>`

## Publicar no GitHub

```bash
git add README.md install.sh
git commit -m "Adiciona instalador e documentacao"
git push
```
