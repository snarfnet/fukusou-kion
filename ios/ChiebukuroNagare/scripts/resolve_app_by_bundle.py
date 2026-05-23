#!/usr/bin/env python3
import os

from asc_helpers import api_json, fail, query


BUNDLE_ID = os.environ["APP_BUNDLE_ID"]


def main():
    body = api_json("GET", f"/apps?{query({'filter[bundleId]': BUNDLE_ID, 'limit': '1'})}")
    apps = body.get("data", [])
    if not apps:
        raise RuntimeError(
            f"App Store Connect app not found for {BUNDLE_ID}. "
            "Create the app record in App Store Connect, then rerun this workflow."
        )

    app = apps[0]
    print(f"Resolved app: {app['attributes'].get('name')} ({app['id']})")
    print(f"APP_ID={app['id']}")


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        fail(error)
