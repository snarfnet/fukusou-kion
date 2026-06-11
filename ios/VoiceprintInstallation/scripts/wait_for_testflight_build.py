#!/usr/bin/env python3
import os
import time
from datetime import datetime

from asc_helpers import api_json, fail


APP_ID = os.environ["APP_ID"]
BUILD_NUMBER = os.environ["BUILD_NUMBER"]
WAIT_SECONDS = int(os.environ.get("WAIT_SECONDS", "1800"))
POLL_SECONDS = int(os.environ.get("POLL_SECONDS", "30"))
MIN_UPLOADED_AT = os.environ.get("UPLOAD_STARTED_AT", "")


def find_builds():
    builds = api_json("GET", f"/apps/{APP_ID}/builds?limit=10").get("data", [])
    builds = sorted(builds, key=lambda item: item.get("attributes", {}).get("uploadedDate") or "", reverse=True)
    if MIN_UPLOADED_AT:
        min_dt = datetime.fromisoformat(MIN_UPLOADED_AT.replace("Z", "+00:00"))
        builds = [
            item for item in builds
            if item.get("attributes", {}).get("uploadedDate")
            and datetime.fromisoformat(item["attributes"]["uploadedDate"]).astimezone(min_dt.tzinfo) >= min_dt
        ]
    return builds


def main():
    deadline = time.time() + WAIT_SECONDS
    last_state = "not found"

    while time.time() < deadline:
        builds = find_builds()
        if builds:
            build = next((item for item in builds if item.get("attributes", {}).get("version") == BUILD_NUMBER), builds[0])
            attrs = build.get("attributes", {})
            state = attrs.get("processingState", "UNKNOWN")
            version = attrs.get("version")
            uploaded = attrs.get("uploadedDate")
            print(f"Build found: id={build['id']} version={version} state={state} uploaded={uploaded}", flush=True)
            if state in {"VALID", "FAILED", "INVALID"}:
                if state != "VALID":
                    raise RuntimeError(f"Build processing ended with state={state}")
                return
            last_state = state
        else:
            print(f"Build {BUILD_NUMBER} is not visible yet.", flush=True)

        time.sleep(POLL_SECONDS)

    raise RuntimeError(f"Timed out waiting for TestFlight build {BUILD_NUMBER}. Last state: {last_state}")


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        fail(error)
