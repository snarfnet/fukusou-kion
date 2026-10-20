"""App Store Connect helpers. Keys remain in the GitHub runner environment."""
import os
import time
import jwt
import requests

BASE = "https://api.appstoreconnect.apple.com/v1"


def api(method, path, payload=None):
    now = int(time.time())
    token = jwt.encode(
        {"iss": os.environ["ASC_ISSUER_ID"], "iat": now, "exp": now + 600, "aud": "appstoreconnect-v1"},
        os.environ["ASC_PRIVATE_KEY"], algorithm="ES256",
        headers={"kid": os.environ["ASC_KEY_ID"], "typ": "JWT"},
    )
    response = requests.request(method, BASE + path, json=payload,
                                headers={"Authorization": f"Bearer {token}"}, timeout=60)
    if not response.ok:
        try:
            errors = response.json().get("errors", [])
            detail = "; ".join(f"{x.get('code')}: {x.get('detail')}" for x in errors)
        except ValueError:
            detail = response.reason
        raise RuntimeError(f"{method} {path.split('?')[0]}: {response.status_code} {detail}")
    return response.json() if response.content else {}
