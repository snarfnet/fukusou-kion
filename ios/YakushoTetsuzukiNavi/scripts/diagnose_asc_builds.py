#!/usr/bin/env python3
import os

from asc_helpers import api_json, fail, query


APP_ID = os.environ["APP_ID"]


def print_rows(label, rows):
    print(f"{label}: {len(rows)}")
    for item in rows[:20]:
        attrs = item.get("attributes", {})
        print(
            f"- id={item.get('id')} "
            f"type={item.get('type')} "
            f"version={attrs.get('version')} "
            f"processingState={attrs.get('processingState')} "
            f"uploadedDate={attrs.get('uploadedDate')} "
            f"expired={attrs.get('expired')}"
        )


def main():
    app = api_json("GET", f"/apps/{APP_ID}")["data"]
    print(f"App: {app.get('attributes', {}).get('name')} id={app.get('id')}")

    builds = api_json(
        "GET",
        f"/builds?{query({'filter[app]': APP_ID, 'limit': '20', 'sort': '-uploadedDate'})}",
    ).get("data", [])
    print_rows("Builds", builds)

    prerelease_versions = api_json(
        "GET",
        f"/preReleaseVersions?{query({'filter[app]': APP_ID, 'limit': '20', 'sort': '-version'})}",
    ).get("data", [])
    print_rows("Pre-release versions", prerelease_versions)


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        fail(error)
