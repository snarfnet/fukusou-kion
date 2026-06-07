#!/usr/bin/env python3
import os

from asc_helpers import api_json, fail, query


APP_ID = os.environ["APP_ID"]
BUILD_NUMBER = os.environ["BUILD_NUMBER"]
BETA_GROUP_NAME = os.environ.get("BETA_GROUP_NAME", "Internal Testers")


def find_build():
    params = query(
        {
            "filter[app]": APP_ID,
            "filter[version]": BUILD_NUMBER,
            "include": "betaGroups,buildBetaDetail",
            "limit": "10",
            "sort": "-uploadedDate",
        }
    )
    builds = api_json("GET", f"/builds?{params}").get("data", [])
    if not builds:
        raise RuntimeError(f"Build {BUILD_NUMBER} was not found for app {APP_ID}.")
    return builds[0]


def mark_no_non_exempt_encryption(build_id):
    payload = {
        "data": {
            "type": "builds",
            "id": build_id,
            "attributes": {"usesNonExemptEncryption": False},
        }
    }
    api_json("PATCH", f"/builds/{build_id}", json=payload)
    print(f"Marked build {BUILD_NUMBER} as not using non-exempt encryption.")


def beta_groups():
    params = query({"filter[app]": APP_ID, "limit": "200"})
    return api_json("GET", f"/betaGroups?{params}").get("data", [])


def find_or_create_internal_group():
    groups = beta_groups()
    internal_groups = [
        group
        for group in groups
        if group.get("attributes", {}).get("isInternalGroup")
    ]
    if internal_groups:
        return internal_groups[0]

    payload = {
        "data": {
            "type": "betaGroups",
            "attributes": {
                "name": BETA_GROUP_NAME,
                "isInternalGroup": True,
            },
            "relationships": {
                "app": {"data": {"type": "apps", "id": APP_ID}},
            },
        }
    }
    group = api_json("POST", "/betaGroups", json=payload)["data"]
    print(f"Created internal beta group: {group['id']} ({BETA_GROUP_NAME})")
    return group


def add_build_to_group(build_id, group_id):
    existing = api_json(
        "GET",
        f"/betaGroups/{group_id}/relationships/builds?limit=200",
    ).get("data", [])
    if any(item.get("id") == build_id for item in existing):
        print(f"Build {BUILD_NUMBER} is already in beta group {group_id}.")
        return

    payload = {"data": [{"type": "builds", "id": build_id}]}
    api_json("POST", f"/betaGroups/{group_id}/relationships/builds", json=payload)
    print(f"Added build {BUILD_NUMBER} to beta group {group_id}.")


def main():
    build = find_build()
    build_id = build["id"]
    attrs = build.get("attributes", {})
    print(
        "Configuring build "
        f"id={build_id} version={attrs.get('version')} "
        f"state={attrs.get('processingState')} "
        f"usesNonExemptEncryption={attrs.get('usesNonExemptEncryption')}"
    )
    mark_no_non_exempt_encryption(build_id)
    group = find_or_create_internal_group()
    add_build_to_group(build_id, group["id"])


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        fail(error)
