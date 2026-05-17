#!/usr/bin/env python3
import os

from asc_helpers import api_json, fail, query


BUNDLE_ID = os.environ.get("APP_BUNDLE_ID", "com.tokyonasu.seikimatsumarubatsu")


def main():
    body = api_json("GET", f"/apps?{query({'filter[bundleId]': BUNDLE_ID, 'limit': '1'})}")
    data = body.get("data", [])
    if not data:
        raise RuntimeError(
            f"No App Store Connect app exists for {BUNDLE_ID}. "
            "Create the app record in ASC, then rerun the TestFlight workflow."
        )

    app = data[0]
    print(f"Resolved app: {app['attributes'].get('name')} ({app['id']})")
    print(f"APP_ID={app['id']}")


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        fail(error)
