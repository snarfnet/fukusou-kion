import os
import time

import jwt
import requests


KEY_ID = os.environ["ASC_KEY_ID"]
ISSUER_ID = os.environ["ASC_ISSUER_ID"]
P8_PATH = os.environ.get("ASC_P8_PATH", "/tmp/asc_key.p8")
BUNDLE_ID = os.environ.get("APP_BUNDLE_ID", "com.tokyonasu.shoppromobuilder")
APP_NAME = os.environ.get("APP_NAME", "小さなお店の宣伝ツール")
APP_SKU = os.environ.get("APP_SKU", "shop-promo-builder")
APP_ID = os.environ.get("ASC_APP_ID", "")

PRIVATE_KEY = open(P8_PATH, encoding="utf-8").read()


def token():
    now = int(time.time())
    payload = {"iss": ISSUER_ID, "iat": now, "exp": now + 1200, "aud": "appstoreconnect-v1"}
    return jwt.encode(payload, PRIVATE_KEY, algorithm="ES256", headers={"kid": KEY_ID})


def request(method, path, **kwargs):
    headers = {"Authorization": f"Bearer {token()}", "Content-Type": "application/json"}
    return requests.request(method, f"https://api.appstoreconnect.apple.com/v1{path}", headers=headers, timeout=120, **kwargs)


def update_app_store_name(app_id):
    response = request("GET", f"/apps/{app_id}/appInfos?limit=10")
    if response.status_code != 200:
        print(f"ASC app info name update skipped: {response.status_code} {response.text[:300]}")
        return
    app_infos = response.json().get("data", [])
    if not app_infos:
        print("ASC app info name update skipped: no appInfos found")
        return

    app_info_id = app_infos[0]["id"]
    response = request("GET", f"/appInfos/{app_info_id}/appInfoLocalizations?limit=50")
    if response.status_code != 200:
        print(f"ASC app info localizations skipped: {response.status_code} {response.text[:300]}")
        return

    for localization in response.json().get("data", []):
        localization_id = localization["id"]
        locale = localization.get("attributes", {}).get("locale", "unknown")
        payload = {
            "data": {
                "type": "appInfoLocalizations",
                "id": localization_id,
                "attributes": {"name": APP_NAME},
            }
        }
        update_response = request("PATCH", f"/appInfoLocalizations/{localization_id}", json=payload)
        if update_response.status_code not in (200, 201):
            raise RuntimeError(
                f"ASC app name update failed for {locale}: "
                f"{update_response.status_code} {update_response.text[:500]}"
            )
        print(f"ASC app name updated for {locale}: {APP_NAME}")


def main():
    if APP_ID:
        response = request("GET", f"/apps/{APP_ID}")
        if response.status_code != 200:
            raise RuntimeError(f"ASC app ID {APP_ID} could not be verified: {response.status_code} {response.text[:500]}")
        attrs = response.json()["data"].get("attributes", {})
        print(f"ASC app verified: {APP_ID} {attrs.get('name', APP_NAME)}")
        update_app_store_name(APP_ID)
        return

    response = request("GET", f"/apps?filter[bundleId]={BUNDLE_ID}")
    response.raise_for_status()
    data = response.json().get("data", [])
    if data:
        app_id = data[0]["id"]
        print(f"ASC app exists: {app_id}")
        update_app_store_name(app_id)
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
    app_id = response.json()["data"]["id"]
    print(f"ASC app created: {app_id}")
    update_app_store_name(app_id)


if __name__ == "__main__":
    main()
