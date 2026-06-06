import os
import re
import time

from asc_api import api, find_app_id, get_or_create_version, list_all
from prepare_asc import main as prepare_asc
from upload_screenshots import main as upload_screenshots

APP_VERSION = os.environ.get("APP_VERSION", "1.0")
BUILD_NUMBER = os.environ.get("BUILD_NUMBER")


def main():
    if not BUILD_NUMBER:
        raise RuntimeError("BUILD_NUMBER is required.")

    prepare_asc()
    upload_screenshots()

    app_id = find_app_id()
    version_id = get_or_create_version(app_id, APP_VERSION)
    build_id = wait_for_build(app_id)
    assign_build(version_id, build_id)
    print("Waiting for App Store screenshot/build state to settle...")
    time.sleep(180)
    submit_for_review(app_id, version_id)


def wait_for_build(app_id):
    for attempt in range(90):
        payload = api(
            "GET",
            f"/builds?filter[app]={app_id}&filter[version]={BUILD_NUMBER}&sort=-uploadedDate&limit=10",
        )
        for item in payload.get("data", []):
            attrs = item.get("attributes", {})
            state = attrs.get("processingState", "")
            version = attrs.get("version", "")
            print(f"Build {version}: {state}")
            if version == str(BUILD_NUMBER) and state == "VALID":
                return item["id"]
        print(f"Waiting for build processing... {attempt + 1}/90")
        time.sleep(30)
    raise RuntimeError(f"Build {BUILD_NUMBER} did not become VALID.")


def assign_build(version_id, build_id):
    try:
        api("PATCH", f"/builds/{build_id}", json={
            "data": {
                "type": "builds",
                "id": build_id,
                "attributes": {"usesNonExemptEncryption": False},
            }
        })
        print("Build encryption declaration updated")
    except RuntimeError as error:
        print(f"Build encryption declaration skipped: {error}")

    api("PATCH", f"/appStoreVersions/{version_id}/relationships/build", json={
        "data": {"type": "builds", "id": build_id}
    })
    print("Build assigned to App Store version")


def submit_for_review(app_id, version_id):
    existing = find_existing_submission(app_id)
    if existing == "submitted":
        return

    submission_id = existing or create_review_submission(app_id)
    create_review_item(submission_id, version_id)
    finish_review_submission(submission_id)


def find_existing_submission(app_id):
    submissions = list_all(f"/apps/{app_id}/reviewSubmissions?limit=20")
    ready_id = None
    for submission in submissions:
        state = submission.get("attributes", {}).get("state")
        submission_id = submission["id"]
        if state == "READY_FOR_REVIEW":
            ready_id = ready_id or submission_id
        elif state in ("WAITING_FOR_REVIEW", "IN_REVIEW"):
            print(f"Already submitted: {submission_id} {state}")
            return "submitted"
        elif state == "UNRESOLVED_ISSUES":
            try:
                api("PATCH", f"/reviewSubmissions/{submission_id}", json={
                    "data": {
                        "type": "reviewSubmissions",
                        "id": submission_id,
                        "attributes": {"canceled": True},
                    }
                })
                print(f"Canceled unresolved review submission {submission_id}")
                time.sleep(60)
            except RuntimeError as error:
                print(f"Could not cancel unresolved submission {submission_id}: {error}")
    return ready_id


def create_review_submission(app_id):
    payload = api("POST", "/reviewSubmissions", json={
        "data": {
            "type": "reviewSubmissions",
            "attributes": {"platform": "IOS"},
            "relationships": {"app": {"data": {"type": "apps", "id": app_id}}},
        }
    })
    submission_id = payload["data"]["id"]
    print(f"Review submission created: {submission_id}")
    return submission_id


def create_review_item(submission_id, version_id):
    for attempt in range(20):
        try:
            api("POST", "/reviewSubmissionItems", json={
                "data": {
                    "type": "reviewSubmissionItems",
                    "relationships": {
                        "reviewSubmission": {"data": {"type": "reviewSubmissions", "id": submission_id}},
                        "appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}},
                    },
                }
            })
            print("Review item created")
            return
        except RuntimeError as error:
            message = str(error)
            if "SCREENSHOT_UPLOADS_IN_PROGRESS" in message:
                print("Screenshots are still processing. Waiting before retry.")
                time.sleep(60)
                continue
            if "ITEM_PART_OF_ANOTHER_SUBMISSION" in message:
                match = re.search(r"reviewSubmission with id ([0-9a-f-]+)", message)
                if match:
                    finish_review_submission(match.group(1))
                    return
            if "409" in message:
                print(f"Review item conflict, retrying {attempt + 1}/20: {message[:500]}")
                time.sleep(60)
                continue
            raise
    raise RuntimeError("Review item could not be created.")


def finish_review_submission(submission_id):
    for attempt in range(30):
        try:
            payload = api("PATCH", f"/reviewSubmissions/{submission_id}", json={
                "data": {
                    "type": "reviewSubmissions",
                    "id": submission_id,
                    "attributes": {"submitted": True},
                }
            })
            print(f"Submitted for App Review: {payload['data']['attributes'].get('state')}")
            return
        except RuntimeError as error:
            print(f"Review submit retry {attempt + 1}/30: {error}")
            time.sleep(60)
    raise RuntimeError("Review submission did not finish.")


if __name__ == "__main__":
    main()
