#!/usr/bin/env python3
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "..", "YakushoTetsuzukiNavi", "scripts"))
from asc_helpers import api, api_json, fail, query

APP_ID = os.environ["APP_ID"]
BUILD_NUMBER = os.environ["BUILD_NUMBER"]
GROUP_NAME = os.environ.get("BETA_GROUP_NAME", "Internal Testers")


def main():
    params = query({"filter[app]": APP_ID, "filter[version]": BUILD_NUMBER, "limit": "10", "sort": "-uploadedDate"})
    builds = api_json("GET", f"/builds?{params}").get("data", [])
    if not builds:
        raise RuntimeError(f"Build {BUILD_NUMBER} was not found.")
    build = builds[0]
    build_id = build["id"]

    payload = {"data": {"type": "builds", "id": build_id, "attributes": {"usesNonExemptEncryption": False}}}
    response = api("PATCH", f"/builds/{build_id}", json=payload)
    if response.status_code not in (200, 201, 204, 409):
        raise RuntimeError(f"Encryption update failed {response.status_code}: {response.text[:800]}")
    print(f"Export compliance configured for build {BUILD_NUMBER}.")

    groups = api_json("GET", f"/betaGroups?{query({'filter[app]': APP_ID, 'limit': '200'})}").get("data", [])
    internal = next((group for group in groups if group.get("attributes", {}).get("isInternalGroup")), None)
    if internal is None:
        group_payload = {
            "data": {
                "type": "betaGroups",
                "attributes": {"name": GROUP_NAME, "isInternalGroup": True},
                "relationships": {"app": {"data": {"type": "apps", "id": APP_ID}}},
            }
        }
        internal = api_json("POST", "/betaGroups", json=group_payload)["data"]
        print(f"Created internal group {GROUP_NAME}.")

    current = api_json("GET", f"/betaGroups/{internal['id']}/relationships/builds?limit=200").get("data", [])
    if not any(item.get("id") == build_id for item in current):
        api_json("POST", f"/betaGroups/{internal['id']}/relationships/builds", json={"data": [{"type": "builds", "id": build_id}]})
    print(f"Build {BUILD_NUMBER} is available to internal testers.")


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        fail(error)
