#!/usr/bin/env python3
import os
import time

from asc_helpers import api_json, fail, query


APP_ID = os.environ["APP_ID"]
VERSION = os.environ["APP_VERSION"]
BUILD_NUMBER = os.environ["BUILD_NUMBER"]
REVIEW_CONTACT = {
    "contactFirstName": "Tokyo",
    "contactLastName": "Nasu",
    "contactEmail": "tokyonasu@yahoo.co.jp",
    "contactPhone": "+81 80-2368-9194",
    "demoAccountRequired": False,
    "demoAccountName": "",
        "demoAccountPassword": "",
        "notes": (
            "This is a quiet reading app. No login is required. "
            "The app shows household wisdom text over a nostalgic shop illustration. "
            "The tobacco shop setting is used as retro scenery and does not promote smoking. "
            "This is a paid app and does not show ads."
        ),
    }


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
    versions = list_all(f"/apps/{APP_ID}/appStoreVersions?{query({'filter[platform]': 'IOS', 'limit': '50'})}")
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
    try:
        api_json(
            "PATCH",
            f"/builds/{build_id}",
            json={
                "data": {
                    "type": "builds",
                    "id": build_id,
                    "attributes": {"usesNonExemptEncryption": False},
                }
            },
        )
    except Exception as error:
        if "already set" not in str(error):
            raise
    payload = {"data": {"type": "builds", "id": build_id}}
    api_json("PATCH", f"/appStoreVersions/{version_id}/relationships/build", json=payload)


def ensure_review_detail(version_id):
    api_json(
        "PATCH",
        f"/appStoreVersions/{version_id}",
        json={
            "data": {
                "type": "appStoreVersions",
                "id": version_id,
                "attributes": {"copyright": "2026 Tokyo Nasu"},
            }
        },
    )

    detail = api_json("GET", f"/appStoreVersions/{version_id}/appStoreReviewDetail").get("data")
    if detail:
        api_json(
            "PATCH",
            f"/appStoreReviewDetails/{detail['id']}",
            json={
                "data": {
                    "type": "appStoreReviewDetails",
                    "id": detail["id"],
                    "attributes": REVIEW_CONTACT,
                }
            },
        )
        return

    api_json(
        "POST",
        "/appStoreReviewDetails",
        json={
            "data": {
                "type": "appStoreReviewDetails",
                "attributes": REVIEW_CONTACT,
                "relationships": {
                    "appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}}
                },
            }
        },
    )


def submit(version_id):
    submissions = api_json(
        "GET",
        f"/apps/{APP_ID}/reviewSubmissions?{query({'limit': '50'})}",
    ).get("data", [])
    for state in ("READY_FOR_REVIEW", "UNRESOLVED_ISSUES"):
        for submission in [item for item in submissions if item.get("attributes", {}).get("state") == state]:
            try:
                api_json(
                    "PATCH",
                    f"/reviewSubmissions/{submission['id']}",
                    json={
                        "data": {
                            "type": "reviewSubmissions",
                            "id": submission["id"],
                            "attributes": {"canceled": True},
                        }
                    },
                )
            except Exception as error:
                if "not in cancellable state" not in str(error):
                    raise

    for submission in submissions:
        attrs = submission.get("attributes", {})
        if attrs.get("state") == "READY_FOR_REVIEW":
            submission_id = submission["id"]
            break
    else:
        submission_id = None

    if submission_id:
        submission = {"id": submission_id}
    else:
        payload = {
            "data": {
                "type": "reviewSubmissions",
                "attributes": {"platform": "IOS"},
                "relationships": {
                    "app": {"data": {"type": "apps", "id": APP_ID}}
                },
            }
        }
        submission = api_json("POST", "/reviewSubmissions", json=payload)["data"]

    payload = {
        "data": {
            "type": "reviewSubmissionItems",
            "relationships": {
                "reviewSubmission": {
                    "data": {"type": "reviewSubmissions", "id": submission["id"]}
                },
                "appStoreVersion": {
                    "data": {"type": "appStoreVersions", "id": version_id}
                },
            },
        }
    }

    for attempt in range(12):
        try:
            api_json("POST", "/reviewSubmissionItems", json=payload)
            break
        except Exception:
            if attempt == 11:
                raise
            time.sleep(20)

    return api_json(
        "PATCH",
        f"/reviewSubmissions/{submission['id']}",
        json={
            "data": {
                "type": "reviewSubmissions",
                "id": submission["id"],
                "attributes": {"submitted": True},
            }
        },
    )["data"]


def main():
    build = find_build()
    version = find_or_create_version()
    print(f"Using App Store version {VERSION}: {version['id']}")
    print(f"Using build {BUILD_NUMBER}: {build['id']}")
    attach_build(version["id"], build["id"])
    ensure_review_detail(version["id"])
    # ASC can need a short moment after build attachment before accepting submission.
    time.sleep(20)
    submission = submit(version["id"])
    print(f"Submitted for review: {submission['id']}")


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        fail(error)
