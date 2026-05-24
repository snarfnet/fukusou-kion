import json
import os
import time
import urllib.parse

import jwt
import requests


KEY_ID = os.environ["ASC_KEY_ID"]
ISSUER = os.environ["ASC_ISSUER_ID"]
BUNDLE_ID = os.environ.get("APP_BUNDLE_ID", "com.tokyonasu.bibletypewriter")
BUNDLE_NAME = os.environ.get("BUNDLE_NAME", "BibleTypewriter")
APP_NAME = os.environ.get("APP_NAME", "聖書のことば")
APP_SKU = os.environ.get("APP_SKU", "bibletypewriter-ios")
APP_ID = os.environ.get("APP_ID")
P8_PATH = os.environ.get("ASC_P8_PATH", "/tmp/asc_key.p8")


def token():
    now = int(time.time())
    p8 = open(P8_PATH, encoding="utf-8").read()
    return jwt.encode(
        {"iss": ISSUER, "iat": now, "exp": now + 1200, "aud": "appstoreconnect-v1"},
        p8,
        algorithm="ES256",
        headers={"kid": KEY_ID},
    )


def api(method, path, **kwargs):
    response = requests.request(
        method,
        f"https://api.appstoreconnect.apple.com/v1{path}",
        headers={"Authorization": f"Bearer {token()}", "Content-Type": "application/json"},
        timeout=120,
        **kwargs,
    )
    try:
        body = response.json()
    except Exception:
        body = {}
    if response.status_code not in (200, 201, 204):
        raise RuntimeError(f"{method} {path} failed {response.status_code}: {response.text[:800]}")
    return body


def query(params):
    return urllib.parse.urlencode(params)


def ensure_bundle_id():
    body = api("GET", f"/bundleIds?{query({'filter[identifier]': BUNDLE_ID, 'limit': '1'})}")
    if body.get("data"):
        bundle = body["data"][0]
        print(f"Bundle ID already exists: {BUNDLE_ID} ({bundle['id']})")
        return bundle

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
    bundle = api("POST", "/bundleIds", data=json.dumps(payload, ensure_ascii=False))["data"]
    print(f"Bundle ID created: {BUNDLE_ID} ({bundle['id']})")
    return bundle


def ensure_app(bundle):
    if APP_ID:
        print(f"Using existing App Store Connect app: {APP_ID}")
        print(f"APP_ID={APP_ID}")
        return

    body = api("GET", f"/apps?{query({'filter[bundleId]': BUNDLE_ID, 'limit': '1'})}")
    if body.get("data"):
        app = body["data"][0]
        print(f"App already exists: {app['attributes'].get('name')} ({app['id']})")
        print(f"APP_ID={app['id']}")
        return

    payload = {
        "data": {
            "type": "apps",
            "attributes": {
                "name": APP_NAME,
                "primaryLocale": "ja",
                "sku": APP_SKU,
            },
            "relationships": {
                "bundleId": {"data": {"type": "bundleIds", "id": bundle["id"]}}
            },
        }
    }
    try:
        app = api("POST", "/apps", data=json.dumps(payload, ensure_ascii=False))["data"]
    except RuntimeError as error:
        raise RuntimeError(
            "Bundle ID is ready, but this API key cannot create the App Store Connect app record. "
            f"Create the app manually in ASC using bundle ID {BUNDLE_ID}, then rerun this workflow. "
            f"Original error: {error}"
        )
    print(f"App created: {app['attributes'].get('name')} ({app['id']})")
    print(f"APP_ID={app['id']}")


def main():
    bundle = ensure_bundle_id()
    ensure_app(bundle)


if __name__ == "__main__":
    main()
