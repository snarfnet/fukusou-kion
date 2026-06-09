#!/usr/bin/env python3
import os
import sys
import time

from asc_helpers import api_json, fail


APP_BUNDLE_ID = os.environ.get("APP_BUNDLE_ID", "com.tokyonasu.voiceprintinstallation")
BUILD_NUMBER = sys.argv[1]


def find_app_id():
    apps = api_json("GET", f"/apps?filter[bundleId]={APP_BUNDLE_ID}&limit=1").get("data", [])
    if not apps:
        raise RuntimeError(f"App Store Connect app not found for {APP_BUNDLE_ID}.")
    return apps[0]["id"]


def main():
    app_id = find_app_id()
    print(f"Waiting for TestFlight build {BUILD_NUMBER} to finish processing...")
    for attempt in range(80):
        body = api_json(
            "GET",
            f"/builds?filter[app]={app_id}&filter[version]={BUILD_NUMBER}&limit=1",
        )
        builds = body.get("data", [])
        if builds:
            build = builds[0]
            state = build.get("attributes", {}).get("processingState")
            print(f"Build {BUILD_NUMBER}: {state}")
            if state == "VALID":
                print(f"TESTFLIGHT_BUILD_ID={build['id']}")
                return
            if state == "FAILED":
                raise RuntimeError("Build processing failed in App Store Connect.")
        else:
            print(f"Build {BUILD_NUMBER}: not visible yet")
        time.sleep(30)
    raise RuntimeError("Build did not become VALID within 40 minutes.")


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        fail(error)
