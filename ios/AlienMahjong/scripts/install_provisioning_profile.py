#!/usr/bin/env python3
import base64
import os
from pathlib import Path

from asc_helpers import api_json, fail, json_body, query

BUNDLE_ID = os.environ["APP_BUNDLE_ID"]
PROFILE_NAME = os.environ["PROFILE_NAME"]
OUTPUT_PATH = Path(os.environ.get("PROFILE_OUTPUT_PATH", "/tmp/AlienMahjong.mobileprovision"))


def first(path):
    result = api_json("GET", path)
    return result.get("data", [None])[0] if result.get("data") else None


def find_bundle():
    bundle = first(f"/bundleIds?{query({'filter[identifier]': BUNDLE_ID, 'limit': '1'})}")
    if not bundle:
        raise RuntimeError(f"Bundle ID not found: {BUNDLE_ID}")
    return bundle


def find_distribution_certificate():
    certificate_id = os.environ.get("CERTIFICATE_ID")
    if certificate_id:
        return api_json("GET", f"/certificates/{certificate_id}")["data"]
    result = api_json(
        "GET",
        f"/certificates?{query({'filter[certificateType]': 'IOS_DISTRIBUTION', 'limit': '200'})}",
    )
    certificates = result.get("data", [])
    if not certificates:
        raise RuntimeError("No Apple Distribution certificate is available")
    valid = [item for item in certificates if item.get("attributes", {}).get("certificateContent")]
    if not valid:
        raise RuntimeError("No downloadable Apple Distribution certificate is available")
    local_serial = os.environ.get("LOCAL_CERT_SERIAL", "").upper()
    if local_serial:
        matching = [
            item for item in valid
            if item.get("attributes", {}).get("serialNumber", "").upper() == local_serial
        ]
        if not matching:
            raise RuntimeError(
                f"The imported distribution certificate ({local_serial}) is not available in the API"
            )
        return matching[0]
    return sorted(
        valid,
        key=lambda item: item.get("attributes", {}).get("expirationDate", ""),
        reverse=True,
    )[0]


def ensure_profile(bundle, certificate):
    existing = first(
        f"/profiles?{query({'filter[name]': PROFILE_NAME, 'limit': '1'})}"
    )
    if existing:
        api_json("DELETE", f"/profiles/{existing['id']}")

    payload = {
        "data": {
            "type": "profiles",
            "attributes": {"name": PROFILE_NAME, "profileType": "IOS_APP_STORE"},
            "relationships": {
                "bundleId": {"data": {"type": "bundleIds", "id": bundle["id"]}},
                "certificates": {
                    "data": [{"type": "certificates", "id": certificate["id"]}]
                },
            },
        }
    }
    return api_json("POST", "/profiles", json_body(payload))["data"]


def main():
    profile = ensure_profile(find_bundle(), find_distribution_certificate())
    content = profile.get("attributes", {}).get("profileContent")
    if not content:
        profile = api_json("GET", f"/profiles/{profile['id']}")["data"]
        content = profile["attributes"]["profileContent"]
    OUTPUT_PATH.write_bytes(base64.b64decode(content))
    print(f"PROFILE_PATH={OUTPUT_PATH}")


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        fail(error)
