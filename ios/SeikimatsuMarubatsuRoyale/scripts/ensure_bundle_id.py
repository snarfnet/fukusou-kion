#!/usr/bin/env python3
import os

from asc_helpers import api_json, fail, json_body, query


BUNDLE_ID = os.environ.get("APP_BUNDLE_ID", "com.tokyonasu.seikimatsumarubatsu")
BUNDLE_NAME = os.environ.get("BUNDLE_NAME", "SeikimatsuMarubatsuRoyale")


def main():
    body = api_json("GET", f"/bundleIds?{query({'filter[identifier]': BUNDLE_ID, 'limit': '1'})}")
    if body.get("data"):
        bundle = body["data"][0]
        print(f"Bundle ID already exists: {BUNDLE_ID} ({bundle['id']})")
        print(f"BUNDLE_ID_RESOURCE_ID={bundle['id']}")
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
    bundle = api_json("POST", "/bundleIds", data=json_body(payload))["data"]
    print(f"Bundle ID created: {BUNDLE_ID} ({bundle['id']})")
    print(f"BUNDLE_ID_RESOURCE_ID={bundle['id']}")


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        fail(error)
