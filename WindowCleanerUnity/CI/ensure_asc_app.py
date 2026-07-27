#!/usr/bin/env python3
import os

from asc_helpers import api_json, fail, json_body, query


BUNDLE_ID = os.environ["APP_BUNDLE_ID"]
BUNDLE_NAME = os.environ["BUNDLE_NAME"]
APP_NAME = os.environ["APP_NAME"]
APP_SKU = os.environ["APP_SKU"]


def find_or_create_bundle():
    result = api_json(
        "GET",
        f"/bundleIds?{query({'filter[identifier]': BUNDLE_ID, 'limit': '1'})}",
    )
    if result.get("data"):
        return result["data"][0]

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
    return api_json("POST", "/bundleIds", data=json_body(payload))["data"]


def find_app_without_bundle_filter():
    # Apple's filter[bundleId] endpoint can temporarily return 500 immediately
    # after a Bundle ID is registered. Listing apps avoids that propagation bug.
    result = api_json("GET", "/apps?limit=200")
    for app in result.get("data", []):
        if app.get("attributes", {}).get("bundleId") == BUNDLE_ID:
            return app
    return None


def create_app(bundle):
    payload = {
        "data": {
            "type": "apps",
            "attributes": {
                "name": APP_NAME,
                "primaryLocale": "ja",
                "sku": APP_SKU,
            },
            "relationships": {
                "bundleId": {
                    "data": {"type": "bundleIds", "id": bundle["id"]}
                }
            },
        }
    }
    return api_json("POST", "/apps", data=json_body(payload))["data"]


def main():
    bundle = find_or_create_bundle()
    print(f"Bundle ID ready: {BUNDLE_ID} ({bundle['id']})")
    app = find_app_without_bundle_filter() or create_app(bundle)
    print(f"App ready: {app['attributes'].get('name')} ({app['id']})")
    print(f"APP_ID={app['id']}")


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        fail(error)
