import os
import time

import jwt
import requests


KEY_ID = os.environ["ASC_KEY_ID"]
ISSUER_ID = os.environ["ASC_ISSUER_ID"]
P8_PATH = os.environ.get("ASC_P8_PATH", "/tmp/asc_key.p8")
BUNDLE_ID = os.environ.get("APP_BUNDLE_ID", "com.tokyonasu.shoppromobuilder")
APP_NAME = os.environ.get("APP_NAME", "小さな店の宣伝")
APP_SKU = os.environ.get("APP_SKU", "shop-promo-builder")

PRIVATE_KEY = open(P8_PATH, encoding="utf-8").read()


def token():
    now = int(time.time())
    payload = {"iss": ISSUER_ID, "iat": now, "exp": now + 1200, "aud": "appstoreconnect-v1"}
    return jwt.encode(payload, PRIVATE_KEY, algorithm="ES256", headers={"kid": KEY_ID})


def request(method, path, **kwargs):
    headers = {"Authorization": f"Bearer {token()}", "Content-Type": "application/json"}
    return requests.request(method, f"https://api.appstoreconnect.apple.com/v1{path}", headers=headers, timeout=120, **kwargs)


def main():
    response = request("GET", f"/apps?filter[bundleId]={BUNDLE_ID}")
    response.raise_for_status()
    data = response.json().get("data", [])
    if data:
        print(f"ASC app exists: {data[0]['id']}")
        return

    payload = {
        "data": {
            "type": "apps",
            "attributes": {
                "bundleId": BUNDLE_ID,
                "name": APP_NAME,
                "primaryLocale": "ja",
                "sku": APP_SKU,
            },
        }
    }
    response = request("POST", "/apps", json=payload)
    if response.status_code not in (200, 201):
        raise RuntimeError(
            "App Store Connect app record could not be created. "
            "Confirm the Bundle ID exists in Apple Developer and the ASC API key has access. "
            f"{response.status_code}: {response.text[:500]}"
        )
    print(f"ASC app created: {response.json()['data']['id']}")


if __name__ == "__main__":
    main()
