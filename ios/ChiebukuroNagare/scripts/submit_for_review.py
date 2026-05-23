#!/usr/bin/env python3
import os
import time

from asc_helpers import api_json, fail, query


APP_ID = os.environ["APP_ID"]
VERSION = os.environ["APP_VERSION"]
BUILD_NUMBER = os.environ["BUILD_NUMBER"]


def list_all(path):
    data = []
    while path:
        body = api_json("GET", path)
        data.extend(body.get("data", []))
        path = body.get("links", {}).get("next")
        if path and path.startswith("https://api.appstoreconnect.apple.com/v1"):
            path = path.split("/v1", 1)[1]
    return data


def find_build():
    params = query({
        "filter[app]": APP_ID,
        "filter[version]": BUILD_NUMBER,
        "limit": "10",
        "sort": "-uploadedDate",
    })
    builds = api_json("GET", f"/builds?{params}").get("data", [])
    for build in builds:
        if build.get("attributes", {}).get("processingState") == "VALID":
            return build
    raise RuntimeError(f"Valid processed build not found for build number {BUILD_NUMBER}.")


def find_or_create_version():
    versions = list_all(f"/appStoreVersions?{query({'filter[app]': APP_ID, 'filter[platform]': 'IOS', 'limit': '50'})}")
    for version in versions:
        attrs = version.get("attributes", {})
        if attrs.get("versionString") == VERSION and attrs.get("appStoreState") in {
            "PREPARE_FOR_SUBMISSION",
            "DEVELOPER_REJECTED",
            "REJECTED",
            "METADATA_REJECTED",
            "WAITING_FOR_REVIEW",
        }:
            return version

    payload = {
        "data": {
            "type": "appStoreVersions",
            "attributes": {
                "platform": "IOS",
                "versionString": VERSION,
            },
            "relationships": {
                "app": {"data": {"type": "apps", "id": APP_ID}}
            },
        }
    }
    return api_json("POST", "/appStoreVersions", json=payload)["data"]


def attach_build(version_id, build_id):
    payload = {"data": {"type": "builds", "id": build_id}}
    api_json("PATCH", f"/appStoreVersions/{version_id}/relationships/build", json=payload)


def submit(version_id):
    payload = {
        "data": {
            "type": "appStoreVersionSubmissions",
            "relationships": {
                "appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}}
            },
        }
    }
    return api_json("POST", "/appStoreVersionSubmissions", json=payload)["data"]


def main():
    build = find_build()
    version = find_or_create_version()
    print(f"Using App Store version {VERSION}: {version['id']}")
    print(f"Using build {BUILD_NUMBER}: {build['id']}")
    attach_build(version["id"], build["id"])
    # ASC can need a short moment after build attachment before accepting submission.
    time.sleep(20)
    submission = submit(version["id"])
    print(f"Submitted for review: {submission['id']}")


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        fail(error)
