#!/usr/bin/env python3
import os
from pathlib import Path

from asc_helpers import api_json, decode_profile, fail


BUNDLE_ID = os.environ.get("APP_BUNDLE_ID", "com.tokyonasu.seikimatsumarubatsu")
PROFILE_NAME = os.environ.get("PROFILE_NAME", "SeikimatsuMarubatsuRoyale App Store")
PROFILE_PATH = Path.home() / "Library/MobileDevice/Provisioning Profiles/SeikimatsuMarubatsuRoyale_App_Store.mobileprovision"


def find_distribution_certificate():
    for cert_type in ("IOS_DISTRIBUTION", "DISTRIBUTION"):
        data = api_json("GET", f"/certificates?filter[certificateType]={cert_type}&limit=20").get("data", [])
        if data:
            return data[0]
    data = api_json("GET", "/certificates?limit=20").get("data", [])
    if not data:
        raise RuntimeError("No distribution certificate found.")
    return data[0]


def find_or_create_profile(bundle_id, certificate_id):
    existing = api_json("GET", f"/profiles?filter[name]={PROFILE_NAME}&limit=20").get("data", [])
    for profile in existing:
        attrs = profile.get("attributes", {})
        if attrs.get("profileState") == "ACTIVE" and attrs.get("profileContent"):
            return profile

    payload = {
        "data": {
            "type": "profiles",
            "attributes": {"name": PROFILE_NAME, "profileType": "IOS_APP_STORE"},
            "relationships": {
                "bundleId": {"data": {"type": "bundleIds", "id": bundle_id}},
                "certificates": {"data": [{"type": "certificates", "id": certificate_id}]},
            },
        }
    }
    return api_json("POST", "/profiles", json=payload)["data"]


def main():
    data = api_json("GET", f"/bundleIds?filter[identifier]={BUNDLE_ID}&limit=1").get("data", [])
    if not data:
        raise RuntimeError(f"Bundle ID does not exist: {BUNDLE_ID}")

    certificate = find_distribution_certificate()
    profile = find_or_create_profile(data[0]["id"], certificate["id"])
    content = profile.get("attributes", {}).get("profileContent")
    if not content:
        profile = api_json("GET", f"/profiles/{profile['id']}")["data"]
        content = profile.get("attributes", {}).get("profileContent")
    if not content:
        raise RuntimeError("Provisioning profile was created, but profileContent was empty.")

    PROFILE_PATH.parent.mkdir(parents=True, exist_ok=True)
    PROFILE_PATH.write_bytes(decode_profile(content))
    print(PROFILE_PATH)


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        fail(error)
