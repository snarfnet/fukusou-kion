#!/usr/bin/env python3
import os

from asc_helpers import api_json, fail, json_body, query

BUNDLE_ID = os.environ["APP_BUNDLE_ID"]
BUNDLE_NAME = os.environ["BUNDLE_NAME"]
APP_NAME = os.environ["APP_NAME"]
APP_SKU = os.environ["APP_SKU"]


def ensure_bundle_id():
    body = api_json(
        "GET",
        f"/bundleIds?{query({'filter[identifier]': BUNDLE_ID, 'limit': '1'})}",
    )
    if body.get("data"):
        return body["data"][0]
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


def ensure_app(bundle):
    body = api_json(
        "GET",
        f"/apps?{query({'filter[bundleId]': BUNDLE_ID, 'limit': '1'})}",
    )
    if body.get("data"):
        app = body["data"][0]
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
    app = api_json("POST", "/apps", data=json_body(payload))["data"]
    print(f"APP_ID={app['id']}")


if __name__ == "__main__":
    try:
        ensure_app(ensure_bundle_id())
    except Exception as error:
        fail(error)
