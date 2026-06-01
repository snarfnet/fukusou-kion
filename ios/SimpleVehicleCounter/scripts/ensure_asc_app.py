#!/usr/bin/env python3
import os

from asc_helpers import api_json, fail, json_body, query


BUNDLE_ID = os.environ.get("BUNDLE_ID", "com.tokyonasu.simplevehiclecounter")
BUNDLE_NAME = os.environ.get("BUNDLE_NAME", "SimpleVehicleCounter")
APP_NAME = os.environ.get("APP_NAME", "\u7C21\u6613\u8ECA\u4E21\u30AB\u30A6\u30F3\u30BF\u30FC")
APP_SKU = os.environ.get("APP_SKU", "simple-vehicle-counter-ios")


def ensure_bundle_id():
    body = api_json("GET", f"/bundleIds?{query({'filter[identifier]': BUNDLE_ID, 'limit': '1'})}")
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
    bundle = api_json("POST", "/bundleIds", data=json_body(payload))["data"]
    print(f"Bundle ID created: {BUNDLE_ID} ({bundle['id']})")
    return bundle


def ensure_app(bundle):
    body = api_json("GET", f"/apps?{query({'filter[bundleId]': BUNDLE_ID, 'limit': '1'})}")
    if body.get("data"):
        app = body["data"][0]
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
            app = api_json("POST", "/apps", data=json_body(payload))["data"]
            print(f"App created: {app['attributes'].get('name')} ({app['id']})")
            print(f"APP_ID={app['id']}")
            return
        except Exception as error:
            last_error = error

    print(f"Warning: App Store Connect app was not created: {last_error}")


def main():
    bundle = ensure_bundle_id()
    ensure_app(bundle)


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        fail(error)
