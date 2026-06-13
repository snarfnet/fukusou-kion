#!/usr/bin/env python3
import os

from asc_helpers import api_json, fail, query


APP_ID = os.environ["APP_ID"]


def main():
    params = query({
        "filter[app]": APP_ID,
        "limit": "20",
        "sort": "-uploadedDate",
    })
    body = api_json("GET", f"/builds?{params}")
    for build in body.get("data", []):
        attrs = build.get("attributes", {})
        print(
            "BUILD "
            f"id={build['id']} "
            f"version={attrs.get('version')} "
            f"processingState={attrs.get('processingState')} "
            f"uploadedDate={attrs.get('uploadedDate')} "
            f"expired={attrs.get('expired')}"
        )


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        fail(error)
