#!/usr/bin/env python3
import os
import time

from asc_helpers import api_json, fail, query


def main():
    app_id = os.environ["APP_ID"]
    build_number = os.environ["BUILD_NUM"]
    for _ in range(60):
        result = api_json("GET", f"/builds?{query({'filter[app]': app_id, 'filter[version]': build_number, 'limit': '10'})}")
        builds = result.get("data", [])
        if builds:
            state = builds[0].get("attributes", {}).get("processingState")
            print(f"TestFlight processing state: {state}", flush=True)
            if state == "VALID":
                return
            if state == "FAILED":
                raise RuntimeError("App Store Connect rejected the uploaded build")
        else:
            print("Waiting for the uploaded build to appear...", flush=True)
        time.sleep(30)
    raise RuntimeError("Timed out waiting for TestFlight processing")


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        fail(error)
