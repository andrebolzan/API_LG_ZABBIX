#!/usr/bin/env python3

"""ThinQ Connect V2 client (official token-based auth).

Based on official LG ThinQ Connect docs and official Python SDK:
- https://smartsolution.developer.lge.com/en/apiManage/thinq_connect
- https://github.com/thinq-connect/pythinqconnect
"""

import argparse
import base64
import json
import os
import sys
import uuid
from pathlib import Path

import requests

API_KEY = "v6GFvkweNo7DK7yD3ylIZ9w52aKBU0eJ7wLXkSR3"
SERVICE_PHASE = "OP"

DEFAULT_COUNTRY = "BR"
DEFAULT_STATE_FILE = Path(__file__).resolve().parent / "lg_v2_state.json"
DEFAULT_ENV_FILE = Path(__file__).resolve().parent / ".env"
DEFAULT_TOKEN_FILE = Path.home() / ".config" / "lg-thinq" / "token"
DEFAULT_COUNTRY_FILE = Path.home() / ".config" / "lg-thinq" / "country"

KIC_COUNTRIES = {
    "AU", "BD", "CN", "HK", "ID", "IN", "JP", "KH", "KR", "LA", "LK",
    "MM", "MY", "NP", "NZ", "PH", "SG", "TH", "TW", "VN",
}

AIC_COUNTRIES = {
    "AG", "AR", "AW", "BB", "BO", "BR", "BS", "BZ", "CA", "CL", "CO", "CR",
    "CU", "DM", "DO", "EC", "GD", "GT", "GY", "HN", "HT", "JM", "KN", "LC",
    "MX", "NI", "PA", "PE", "PR", "PY", "SR", "SV", "TT", "US", "UY", "VC", "VE",
}


class ThinQConnectError(Exception):
    """User-visible API error."""


def _load_dotenv(path: Path) -> None:
    if not path.exists():
        return
    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except OSError:
        return

    for line in lines:
        row = line.strip()
        if not row or row.startswith("#") or "=" not in row:
            continue
        key, value = row.split("=", 1)
        key = key.strip()
        value = value.strip().strip('"').strip("'")
        if key and key not in os.environ:
            os.environ[key] = value


def _load_text_file(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8").strip()
    except OSError:
        return ""


def _load_state(path: Path) -> dict:
    if not path.exists():
        return {}
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return {}
    return data if isinstance(data, dict) else {}


def _save_state(path: Path, state: dict) -> None:
    path.write_text(json.dumps(state, indent=2, ensure_ascii=True), encoding="utf-8")


def _resolve_region(country: str, region_override: str) -> str:
    if region_override:
        return region_override.lower()

    cc = country.upper()
    if cc in KIC_COUNTRIES:
        return "kic"
    if cc in AIC_COUNTRIES:
        return "aic"
    return "eic"


def _new_message_id() -> str:
    return base64.urlsafe_b64encode(uuid.uuid4().bytes).decode("utf-8").rstrip("=")


class ThinQConnectClient:
    def __init__(self, token: str, country: str, client_id: str, region: str = ""):
        self.token = token
        self.country = country.upper()
        self.client_id = client_id
        self.region = _resolve_region(self.country, region)
        self.base_url = f"https://api-{self.region}.lgthinq.com"

    def _headers(self) -> dict:
        return {
            "Authorization": f"Bearer {self.token}",
            "x-country": self.country,
            "x-message-id": _new_message_id(),
            "x-client-id": self.client_id,
            "x-api-key": API_KEY,
            "x-service-phase": SERVICE_PHASE,
        }

    def request(self, method: str, endpoint: str, payload: dict | None = None) -> dict | list:
        url = f"{self.base_url}/{endpoint.lstrip('/')}"
        kwargs = {
            "method": method.upper(),
            "url": url,
            "headers": self._headers(),
            "timeout": 20,
        }
        if payload is not None:
            kwargs["json"] = payload

        response = requests.request(**kwargs)
        response.raise_for_status()
        body = response.json()

        if "error" in body and body["error"]:
            err = body["error"]
            code = err.get("code", "unknown")
            message = err.get("message", "unknown error")
            raise ThinQConnectError(f"LG API error {code}: {message}")

        return body.get("response", {})

    def list_devices(self) -> list:
        data = self.request("GET", "devices")
        return data if isinstance(data, list) else []

    def device_state(self, device_id: str) -> dict:
        data = self.request("GET", f"devices/{device_id}/state")
        return data if isinstance(data, dict) else {}

    def device_profile(self, device_id: str) -> dict:
        data = self.request("GET", f"devices/{device_id}/profile")
        return data if isinstance(data, dict) else {}


def build_client(args: argparse.Namespace) -> ThinQConnectClient:
    state_file = Path(args.state_file)
    state = _load_state(state_file)

    token = (
        args.token
        or os.getenv("PAT")
        or os.getenv("LG_THINQ_TOKEN")
        or _load_text_file(DEFAULT_TOKEN_FILE)
    )
    if not token:
        raise ThinQConnectError(
            "Token nao informado. Use --token, variavel LG_THINQ_TOKEN ou ~/.config/lg-thinq/token"
        )

    country = args.country or os.getenv("LG_THINQ_COUNTRY") or _load_text_file(DEFAULT_COUNTRY_FILE) or DEFAULT_COUNTRY

    client_id = args.client_id or state.get("client_id")
    if not client_id:
        client_id = str(uuid.uuid4())

    state.update({"client_id": client_id, "country": country.upper()})
    _save_state(state_file, state)

    return ThinQConnectClient(token=token, country=country, client_id=client_id, region=args.region)


def cmd_ls(client: ThinQConnectClient, raw: bool) -> int:
    devices = client.list_devices()
    if raw:
        print(json.dumps(devices, ensure_ascii=True, indent=2))
        return 0

    if not devices:
        print("Nenhum dispositivo retornado.")
        return 0

    for dev in devices:
        device_id = dev.get("deviceId", "")
        info = dev.get("deviceInfo") or {}
        alias = info.get("alias", "")
        device_type = info.get("deviceType", "")
        print(f"{alias};{device_type};{device_id}")
    return 0


def cmd_status(client: ThinQConnectClient, device_id: str, raw: bool) -> int:
    state = client.device_state(device_id)
    print(json.dumps(state, ensure_ascii=True, indent=2) if raw else json.dumps(state, ensure_ascii=True))
    return 0


def cmd_profile(client: ThinQConnectClient, device_id: str, raw: bool) -> int:
    profile = client.device_profile(device_id)
    print(json.dumps(profile, ensure_ascii=True, indent=2) if raw else json.dumps(profile, ensure_ascii=True))
    return 0


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="LG ThinQ Connect v2 (token)")
    parser.add_argument("cmd", nargs="?", default="ls", choices=["ls", "status", "profile"])
    parser.add_argument("device_id", nargs="?")
    parser.add_argument("--token", help="Personal Access Token (PAT) do ThinQ Connect")
    parser.add_argument("-c", "--country", help="Codigo do pais (ex: BR, US)")
    parser.add_argument("--client-id", help="Client ID (uuid). Se omitido, usa/salva em estado local")
    parser.add_argument("--region", choices=["aic", "eic", "kic"], help="Override da regiao")
    parser.add_argument("--state-file", default=str(DEFAULT_STATE_FILE), help="Arquivo local para client_id")
    parser.add_argument("--raw", action="store_true", help="Saida JSON formatada")
    return parser.parse_args()


def main() -> int:
    _load_dotenv(DEFAULT_ENV_FILE)
    args = parse_args()
    try:
        client = build_client(args)

        if args.cmd == "ls":
            return cmd_ls(client, args.raw)

        if not args.device_id:
            raise ThinQConnectError("Comando requer device_id: status <DEVICE_ID> ou profile <DEVICE_ID>")

        if args.cmd == "status":
            return cmd_status(client, args.device_id, args.raw)

        if args.cmd == "profile":
            return cmd_profile(client, args.device_id, args.raw)

        raise ThinQConnectError(f"Comando nao suportado: {args.cmd}")

    except requests.HTTPError as exc:
        code = exc.response.status_code if exc.response is not None else "?"
        print(f"Erro HTTP da LG API: {code}", file=sys.stderr)
        return 2
    except ThinQConnectError as exc:
        print(str(exc), file=sys.stderr)
        return 3
    except requests.RequestException as exc:
        print(f"Erro de rede: {exc}", file=sys.stderr)
        return 4


if __name__ == "__main__":
    raise SystemExit(main())
