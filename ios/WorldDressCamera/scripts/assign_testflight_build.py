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
    tester_count = 0
    for group in internal_groups:
        attrs = group.get("attributes", {})
        testers = api_json(
            "GET",
            f"/v1/betaGroups/{group['id']}/betaTesters?"
            f"{query({'limit': '200', 'fields[betaTesters]': 'state,inviteType'})}",
        ).get("data", [])
        tester_count += len(testers)
        print(
            f"Internal group {attrs.get('name')} contains "
            f"{len(testers)} tester(s)."
        )
        for tester in testers:
            tester_attrs = tester.get("attributes", {})
            print(
                f"Tester status: state={tester_attrs.get('state')} "
                f"inviteType={tester_attrs.get('inviteType')}"
            )
        if attrs.get("hasAccessToAllBuilds") is True:
            print(
                f"Group {attrs.get('name')} already has automatic access "
                f"to all builds, including {BUILD_NUMBER}."
            )
            continue
        api_json(
            "POST",
            f"/v1/betaGroups/{group['id']}/relationships/builds",
            data=json_body(payload),
        )
        print(
            f"Assigned build {BUILD_NUMBER} to internal group "
            f"{attrs.get('name')} ({group['id']})."
        )

    if tester_count == 0:
        raise RuntimeError(
            "The internal groups have access to build "
            f"{BUILD_NUMBER}, but contain no testers. Add your App Store "
            "Connect user to the internal TestFlight group."
        )


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        fail(error)
