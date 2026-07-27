#!/usr/bin/env python3
import os

from asc_helpers import api_json, fail, json_body, query


APP_ID = os.environ["APP_ID"]
BUILD_NUMBER = os.environ["BUILD_NUMBER"]


def main():
    builds = api_json(
        "GET",
        f"/builds?{query({'filter[app]': APP_ID, 'filter[version]': BUILD_NUMBER, 'limit': '1'})}",
    ).get("data", [])
    if not builds:
        raise RuntimeError(f"TestFlight build {BUILD_NUMBER} was not found.")

    build = builds[0]
    state = build.get("attributes", {}).get("processingState")
    if state != "VALID":
        raise RuntimeError(f"Build {BUILD_NUMBER} is not ready: {state}")

    groups = api_json(
        "GET",
        f"/apps/{APP_ID}/betaGroups?{query({'limit': '200', 'fields[betaGroups]': 'name,isInternalGroup,hasAccessToAllBuilds'})}",
    ).get("data", [])
    internal_groups = [
        group for group in groups
        if group.get("attributes", {}).get("isInternalGroup") is True
    ]

    print(f"Found {len(groups)} beta group(s), {len(internal_groups)} internal.")
    for group in groups:
        attrs = group.get("attributes", {})
        print(
            f"Group: {attrs.get('name')} id={group['id']} "
            f"internal={attrs.get('isInternalGroup')} "
            f"all_builds={attrs.get('hasAccessToAllBuilds')}"
        )

    if not internal_groups:
        raise RuntimeError(
            "No internal TestFlight group exists. Create an internal tester group "
            "and add your App Store Connect user."
        )

    payload = {
        "data": [{"type": "builds", "id": build["id"]}],
    }
    for group in internal_groups:
        attrs = group.get("attributes", {})
        api_json(
            "POST",
            f"/v1/betaGroups/{group['id']}/relationships/builds",
            data=json_body(payload),
        )
        print(
            f"Assigned build {BUILD_NUMBER} to internal group "
            f"{attrs.get('name')} ({group['id']})."
        )


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        fail(error)
