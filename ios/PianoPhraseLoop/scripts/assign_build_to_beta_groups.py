#!/usr/bin/env python3
import os

from asc_helpers import api_json, fail, json_body, query


APP_ID = os.environ["APP_ID"]
BUILD_NUMBER = os.environ["BUILD_NUMBER"]


def find_build():
    params = query(
        {
            "filter[app]": APP_ID,
            "filter[version]": BUILD_NUMBER,
            "limit": "1",
            "sort": "-uploadedDate",
        }
    )
    builds = api_json("GET", f"/builds?{params}").get("data", [])
    if not builds:
        raise RuntimeError(f"Build {BUILD_NUMBER} was not found for app {APP_ID}")
    return builds[0]


def beta_groups():
    params = query({"filter[app]": APP_ID, "limit": "200"})
    return api_json("GET", f"/betaGroups?{params}").get("data", [])


def assign_build(group_id, build_id):
    payload = {
        "data": [
            {
                "type": "builds",
                "id": build_id,
            }
        ]
    }
    api_json(
        "POST",
        f"/betaGroups/{group_id}/relationships/builds",
        data=json_body(payload),
    )


def main():
    build = find_build()
    build_id = build["id"]
    groups = beta_groups()
    if not groups:
        print("No TestFlight beta groups found. Build is processed, but no group exists to receive it.")
        return

    assigned = 0
    for group in groups:
        group_id = group["id"]
        name = group.get("attributes", {}).get("name", group_id)
        try:
            assign_build(group_id, build_id)
            assigned += 1
            print(f"Assigned build {BUILD_NUMBER} ({build_id}) to TestFlight group: {name}")
        except Exception as error:
            print(f"Could not assign build {BUILD_NUMBER} to group {name}: {error}")

    if assigned == 0:
        raise RuntimeError(f"Build {BUILD_NUMBER} is VALID, but it could not be assigned to any TestFlight group.")


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        fail(error)
