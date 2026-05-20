#!/usr/bin/env python3
import os
import sys
import time
from pathlib import Path

import jwt
import requests


BASE_URL = "https://api.appstoreconnect.apple.com/v1"
APP_ID = os.environ.get("APP_ID", "6771141622")
APP_VERSION = os.environ.get("APP_VERSION", "1.0")
KEY_ID = os.environ["ASC_KEY_ID"]
ISSUER_ID = os.environ["ASC_ISSUER_ID"]
P8_PATH = Path(os.environ.get("ASC_P8_PATH", "/tmp/asc_key.p8"))

SUBMITTED_STATES = {"READY_FOR_REVIEW", "WAITING_FOR_REVIEW", "IN_REVIEW"}
CANCELABLE_STATES = {"CREATED", "UNRESOLVED_ISSUES"}

REVIEW_DETAIL = {
    "contactFirstName": "Tokyo",
    "contactLastName": "Nasu",
    "contactEmail": "tokyonasu@yahoo.co.jp",
    "contactPhone": "+81 80-2368-9194",
    "demoAccountRequired": False,
    "demoAccountName": "",
    "demoAccountPassword": "",
    "notes": (
        "No login is required. The app is a zazen and breathing practice app. "
        "Ads are banner-only and do not interrupt the practice timer. "
        "App privacy information has already been completed in App Store Connect."
    ),
}


def make_token():
    now = int(time.time())
    return jwt.encode(
        {"iss": ISSUER_ID, "iat": now, "exp": now + 1200, "aud": "appstoreconnect-v1"},
        P8_PATH.read_text(encoding="utf-8"),
        algorithm="ES256",
        headers={"kid": KEY_ID},
    )


def headers():
    return {"Authorization": f"Bearer {make_token()}", "Content-Type": "application/json"}


def api(method, path, **kwargs):
    last_response = None
    for _ in range(6):
        last_response = requests.request(method, f"{BASE_URL}{path}", headers=headers(), timeout=120, **kwargs)
        if last_response.status_code not in (401, 429, 500, 502, 503, 504):
            return last_response
        time.sleep(20)
    return last_response


def api_json(method, path, **kwargs):
    response = api(method, path, **kwargs)
    try:
        body = response.json()
    except Exception:
        body = {}
    if response.status_code not in (200, 201, 204):
        raise RuntimeError(f"{method} {path} failed {response.status_code}: {response.text[:1000]}")
    return response, body


def list_all(path):
    rows = []
    next_path = path
    while next_path:
        _, body = api_json("GET", next_path)
        rows.extend(body.get("data", []))
        next_url = body.get("links", {}).get("next")
        next_path = next_url.split("/v1", 1)[1] if next_url else None
    return rows


def find_version():
    versions = list_all(f"/apps/{APP_ID}/appStoreVersions?filter[platform]=IOS&limit=200")
    for version in versions:
        attrs = version.get("attributes", {})
        if attrs.get("versionString") == APP_VERSION:
            state = attrs.get("appStoreState")
            print(f"Version {APP_VERSION}: {version['id']} state={state}")
            return version["id"], state
    raise RuntimeError(f"App Store version not found: {APP_VERSION}")


def ensure_build_selected(version_id):
    response = api("GET", f"/appStoreVersions/{version_id}/build")
    if response.status_code == 404:
        raise RuntimeError("No build is selected for this App Store version.")
    if response.status_code != 200:
        raise RuntimeError(f"Build lookup failed {response.status_code}: {response.text[:1000]}")
    build = response.json().get("data")
    if not build:
        raise RuntimeError("No build is selected for this App Store version.")
    attrs = build.get("attributes", {})
    print(f"Selected build: {attrs.get('version')} ({build['id']})")


def ensure_review_detail(version_id):
    response = api("GET", f"/appStoreVersions/{version_id}/appStoreReviewDetail")
    if response.status_code == 200 and response.json().get("data"):
        detail_id = response.json()["data"]["id"]
        response = api("PATCH", f"/appStoreReviewDetails/{detail_id}", json={
            "data": {"type": "appStoreReviewDetails", "id": detail_id, "attributes": REVIEW_DETAIL}
        })
        if response.status_code not in (200, 201):
            raise RuntimeError(f"Review detail update failed {response.status_code}: {response.text[:1000]}")
        print(f"Review detail updated: {response.status_code}")
        return

    response = api("POST", "/appStoreReviewDetails", json={
        "data": {
            "type": "appStoreReviewDetails",
            "attributes": REVIEW_DETAIL,
            "relationships": {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}}},
        }
    })
    if response.status_code not in (200, 201):
        raise RuntimeError(f"Review detail create failed {response.status_code}: {response.text[:1000]}")
    print(f"Review detail created: {response.status_code}")


def current_review_submissions():
    return list_all(f"/apps/{APP_ID}/reviewSubmissions?limit=50")


def cancel_blocking_submissions():
    for submission in current_review_submissions():
        state = submission.get("attributes", {}).get("state")
        if state in SUBMITTED_STATES:
            print(f"Already submitted: {submission['id']} state={state}")
            return True
        if state not in CANCELABLE_STATES:
            continue

        response = api("PATCH", f"/reviewSubmissions/{submission['id']}", json={
            "data": {
                "type": "reviewSubmissions",
                "id": submission["id"],
                "attributes": {"canceled": True},
            }
        })
        print(f"Canceled stale submission {submission['id']}: {response.status_code}")
    return False


def submit(version_id):
    _, body = api_json("POST", "/reviewSubmissions", json={
        "data": {
            "type": "reviewSubmissions",
            "attributes": {"platform": "IOS"},
            "relationships": {"app": {"data": {"type": "apps", "id": APP_ID}}},
        }
    })
    submission_id = body["data"]["id"]
    print(f"Review submission created: {submission_id}")

    for attempt in range(12):
        response = api("POST", "/reviewSubmissionItems", json={
            "data": {
                "type": "reviewSubmissionItems",
                "relationships": {
                    "reviewSubmission": {"data": {"type": "reviewSubmissions", "id": submission_id}},
                    "appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}},
                },
            }
        })
        print(f"Add review item {attempt + 1}: {response.status_code}")
        if response.status_code in (200, 201):
            break
        time.sleep(20)
    else:
        raise RuntimeError(f"Review item create failed: {response.text[:1000]}")

    response, body = api_json("PATCH", f"/reviewSubmissions/{submission_id}", json={
        "data": {"type": "reviewSubmissions", "id": submission_id, "attributes": {"submitted": True}}
    })
    state = body["data"]["attributes"].get("state")
    print(f"Submitted for review: {submission_id} state={state}")
    return response.status_code


def main():
    version_id, app_store_state = find_version()
    if app_store_state in {"WAITING_FOR_REVIEW", "IN_REVIEW"}:
        print(f"App Store version is already submitted: {app_store_state}")
        return

    ensure_build_selected(version_id)
    ensure_review_detail(version_id)
    if cancel_blocking_submissions():
        return
    submit(version_id)


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        print(str(error), file=sys.stderr)
        sys.exit(1)
