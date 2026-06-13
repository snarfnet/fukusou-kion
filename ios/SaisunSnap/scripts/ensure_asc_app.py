#!/usr/bin/env python3
import json
import os

from asc_helpers import api_json, fail, json_body, query


BUNDLE_ID = os.environ["APP_BUNDLE_ID"]
BUNDLE_NAME = os.environ.get("BUNDLE_NAME", "SaisunSnap")
APP_NAME = os.environ.get("APP_NAME", "採寸カメラ")
APP_SKU = os.environ.get("APP_SKU", "saisun-camera-ios")


def ensure_bundle_id():
    existing = api_json("GET", f"/bundleIds?{query({'filter[identifier]': BUNDLE_ID, 'limit': '1'})}").get("data", [])
    if existing:
        bundle = existing[0]
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
    bundle = api_json("POST", "/bundleIds", data=json_body(payload))["data"]
    print(f"Bundle ID created: {BUNDLE_ID} ({bundle['id']})")
    return bundle


def ensure_app(bundle):
    existing = api_json("GET", f"/apps?{query({'filter[bundleId]': BUNDLE_ID, 'limit': '1'})}").get("data", [])
    if existing:
        app = existing[0]
        print(f"App already exists: {app['attributes'].get('name')} ({app['id']})")
        print(f"APP_ID={app['id']}")
        return

    attempts = [
        {
            "data": {
                "type": "apps",
                "attributes": {
                    "bundleId": BUNDLE_ID,
                    "name": APP_NAME,
                    "primaryLocale": "ja",
                    "sku": APP_SKU,
                },
            }
        },
        {
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
        },
    ]

    last_error = None
    for payload in attempts:
        try:
            app = api_json("POST", "/apps", data=json.dumps(payload, ensure_ascii=False))["data"]
            print(f"App created: {app['attributes'].get('name')} ({app['id']})")
            print(f"APP_ID={app['id']}")
            return
        except Exception as error:
            last_error = error

    raise RuntimeError(f"App Store Connect app was not created: {last_error}")


def main():
    bundle = ensure_bundle_id()
    ensure_app(bundle)


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        fail(error)
