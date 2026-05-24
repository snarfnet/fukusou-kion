#!/usr/bin/env python3
import os
import sys

from asc_helpers import api, api_json, json_body, query


APP_ID = os.environ.get("MORIMORI_PHOTO_MAKER_APP_ID") or os.environ.get("APP_ID")
BUNDLE_ID = os.environ.get("APP_BUNDLE_ID", "com.tokyonasu.morimoriphotomaker")


def find_app_id():
    if APP_ID:
        return APP_ID
    body = api_json("GET", f"/apps?{query({'filter[bundleId]': BUNDLE_ID, 'limit': '1'})}")
    data = body.get("data", [])
    if not data:
        raise RuntimeError(f"App not found for bundle ID: {BUNDLE_ID}")
    return data[0]["id"]


def cancel_review_submissions(app_id):
    body = api_json("GET", f"/apps/{app_id}/reviewSubmissions?limit=50")
    canceled = 0
    for submission in body.get("data", []):
        state = submission.get("attributes", {}).get("state")
        if state not in (
            "READY_FOR_REVIEW",
            "WAITING_FOR_REVIEW",
            "IN_REVIEW",
            "UNRESOLVED_ISSUES",
        ):
            print(f"Skip review submission {submission['id']}: {state}")
            continue
        response = api("PATCH", f"/reviewSubmissions/{submission['id']}", data=json_body({
            "data": {
                "type": "reviewSubmissions",
                "id": submission["id"],
                "attributes": {"canceled": True},
            }
        }))
        print(f"Cancel review submission {submission['id']} state={state}: {response.status_code}")
        if response.status_code == 200:
            canceled += 1
        elif response.status_code not in (409, 422):
            print(response.text[:1200])
    print(f"Canceled review submissions: {canceled}")


def main():
    cancel_review_submissions(find_app_id())


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        print(str(error), file=sys.stderr)
        sys.exit(1)
