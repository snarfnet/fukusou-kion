import os
import time

import jwt
import requests


KEY_ID = os.environ["ASC_KEY_ID"]
ISSUER_ID = os.environ["ASC_ISSUER_ID"]
P8_PATH = os.environ.get("ASC_P8_PATH", "/tmp/asc_key.p8")
BUNDLE_ID = os.environ.get("APP_BUNDLE_ID", "com.tokyonasu.shoppromobuilder")
BUNDLE_NAME = os.environ.get("BUNDLE_NAME", "Shop Promo Builder")

PRIVATE_KEY = open(P8_PATH, encoding="utf-8").read()


def token():
    now = int(time.time())
    payload = {"iss": ISSUER_ID, "iat": now, "exp": now + 1200, "aud": "appstoreconnect-v1"}
    return jwt.encode(payload, PRIVATE_KEY, algorithm="ES256", headers={"kid": KEY_ID})


def request(method, path, **kwargs):
    headers = {"Authorization": f"Bearer {token()}", "Content-Type": "application/json"}
    return requests.request(method, f"https://api.appstoreconnect.apple.com/v1{path}", headers=headers, timeout=120, **kwargs)


def main():
    response = request("GET", f"/bundleIds?filter[identifier]={BUNDLE_ID}&limit=1")
    response.raise_for_status()
    data = response.json().get("data", [])
    if data:
        print(f"Bundle ID already exists: {data[0]['id']} {BUNDLE_ID}")
        return

    payload = {
        "data": {
            "type": "bundleIds",
            "attributes": {
                "identifier": BUNDLE_ID,
                "name": BUNDLE_NAME,
                "platform": "IOS",
            },
        }
    }
    response = request("POST", "/bundleIds", json=payload)
    if response.status_code not in (200, 201):
        raise RuntimeError(f"Bundle ID create failed {response.status_code}: {response.text[:800]}")
    print(f"Bundle ID created: {response.json()['data']['id']} {BUNDLE_ID}")


if __name__ == "__main__":
    main()
