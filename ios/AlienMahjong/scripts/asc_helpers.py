import json
import os
import sys
import time
import urllib.parse
from pathlib import Path

import jwt
import requests

BASE_URL = "https://api.appstoreconnect.apple.com/v1"
KEY_ID = os.environ["ASC_KEY_ID"]
ISSUER_ID = os.environ["ASC_ISSUER_ID"]
P8_PATH = Path(os.environ.get("ASC_P8_PATH", "/tmp/asc_key.p8"))


def token():
    now = int(time.time())
    return jwt.encode(
        {"iss": ISSUER_ID, "iat": now, "exp": now + 1200, "aud": "appstoreconnect-v1"},
        P8_PATH.read_text(encoding="utf-8"),
        algorithm="ES256",
        headers={"kid": KEY_ID, "typ": "JWT"},
    )


def api_json(method, path, data=None):
    response = requests.request(
        method,
        f"{BASE_URL}{path}",
        headers={"Authorization": f"Bearer {token()}", "Content-Type": "application/json"},
        data=data,
        timeout=120,
    )
    if response.status_code not in (200, 201, 204):
        raise RuntimeError(f"{method} {path} failed {response.status_code}: {response.text[:1000]}")
    return response.json() if response.content else {}


def query(params):
    return urllib.parse.urlencode(params)


def json_body(payload):
    return json.dumps(payload, ensure_ascii=False)


def fail(error):
    print(str(error), file=sys.stderr)
    sys.exit(1)
