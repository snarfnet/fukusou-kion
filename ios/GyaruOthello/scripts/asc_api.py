import os
import time
from pathlib import Path

import jwt
import requests

KEY_ID = os.environ.get("ASC_KEY_ID", "WDXGY9WX55")
ISSUER_ID = os.environ.get("ASC_ISSUER_ID", "2be0734f-943a-4d61-9dc9-5d9045c46fec")
KEY_PATH = Path(os.environ.get("ASC_P8_PATH", Path.home() / ".appstoreconnect" / "private_keys" / f"AuthKey_{KEY_ID}.p8"))
BUNDLE_ID = os.environ.get("BUNDLE_ID", "com.tokyonasu.gyaruothello")
BASE_URL = "https://api.appstoreconnect.apple.com/v1"
_TOKEN = None
_TOKEN_EXPIRES_AT = 0


def make_token():
    global _TOKEN, _TOKEN_EXPIRES_AT
    now = int(time.time())
    if _TOKEN and now < _TOKEN_EXPIRES_AT - 60:
        return _TOKEN

    key = KEY_PATH.read_text(encoding="utf-8")
    _TOKEN_EXPIRES_AT = now + 900
    _TOKEN = jwt.encode(
        {"iss": ISSUER_ID, "iat": now, "exp": now + 1200, "aud": "appstoreconnect-v1"},
        key,
        algorithm="ES256",
        headers={"kid": KEY_ID},
    )
    return _TOKEN


def headers():
    return {"Authorization": f"Bearer {make_token()}", "Content-Type": "application/json"}


def api(method, path, **kwargs):
    response = requests.request(method, f"{BASE_URL}{path}", headers=headers(), timeout=120, **kwargs)
    if not response.ok:
        raise RuntimeError(f"{method} {path} failed: {response.status_code} {response.text}")
    return response.json() if response.text else {}


def list_all(path):
    rows = []
    next_path = path
    while next_path:
        payload = api("GET", next_path)
        rows.extend(payload.get("data", []))
        next_url = payload.get("links", {}).get("next")
        next_path = next_url.split("/v1", 1)[1] if next_url and "/v1" in next_url else None
    return rows


def find_app_id():
    payload = api("GET", f"/apps?filter[bundleId]={BUNDLE_ID}")
    items = payload.get("data", [])
    if not items:
        raise RuntimeError(f"App not found in App Store Connect for bundle id: {BUNDLE_ID}")
    return items[0]["id"]


def get_or_create_version(app_id, version_string):
    versions = list_all(f"/apps/{app_id}/appStoreVersions?filter[platform]=IOS&limit=200")
    for item in versions:
        if item["attributes"].get("versionString") == version_string:
            return item["id"]

    payload = api("POST", "/appStoreVersions", json={
        "data": {
            "type": "appStoreVersions",
            "attributes": {"platform": "IOS", "versionString": version_string},
            "relationships": {"app": {"data": {"type": "apps", "id": app_id}}},
        }
    })
    return payload["data"]["id"]
