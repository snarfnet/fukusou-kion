#!/usr/bin/env python3
import base64
import hashlib
import os
from pathlib import Path

from asc_helpers import api, api_json, decode_profile, fail, query

BUNDLE_ID = os.environ["APP_BUNDLE_ID"]
PROFILE_NAME = os.environ["PROFILE_NAME"]
CERT_SHA1 = os.environ["IOS_DISTRIBUTION_CERT_SHA1"].replace(":", "").upper()
PROFILE_PATH = (
    Path.home()
    / "Library/MobileDevice/Provisioning Profiles/SukebanMahjong_App_Store.mobileprovision"
)


def cert_sha1(certificate):
    content = certificate.get("attributes", {}).get("certificateContent")
    if not content:
        detail = api_json("GET", f"/certificates/{certificate['id']}")["data"]
        content = detail.get("attributes", {}).get("certificateContent")
    return hashlib.sha1(base64.b64decode(content)).hexdigest().upper() if content else ""


def matching_certificate():
    certificates = []
    for cert_type in ("IOS_DISTRIBUTION", "DISTRIBUTION"):
        certificates.extend(
            api_json(
                "GET",
                f"/certificates?filter[certificateType]={cert_type}&limit=200",
            ).get("data", [])
        )
    for certificate in certificates:
        if cert_sha1(certificate) == CERT_SHA1:
            return certificate
    raise RuntimeError(
        f"Installed distribution certificate is not active in App Store Connect: {CERT_SHA1}"
    )


def profile_certificate_ids(profile_id):
    body = api_json(
        "GET",
        f"/profiles/{profile_id}/relationships/certificates?limit=10",
    )
    return {item["id"] for item in body.get("data", [])}


def ensure_profile(bundle_id, certificate_id):
    existing = api_json(
        "GET",
        f"/profiles?{query({'filter[name]': PROFILE_NAME, 'limit': '200'})}",
    ).get("data", [])
    for profile in existing:
        if (
            profile.get("attributes", {}).get("profileState") == "ACTIVE"
            and certificate_id in profile_certificate_ids(profile["id"])
        ):
            return api_json("GET", f"/profiles/{profile['id']}")["data"]
    for profile in existing:
        response = api("DELETE", f"/profiles/{profile['id']}")
        if response.status_code not in (200, 204):
            raise RuntimeError(f"Could not remove stale profile {profile['id']}")
    payload = {
        "data": {
            "type": "profiles",
            "attributes": {"name": PROFILE_NAME, "profileType": "IOS_APP_STORE"},
            "relationships": {
                "bundleId": {"data": {"type": "bundleIds", "id": bundle_id}},
                "certificates": {
                    "data": [{"type": "certificates", "id": certificate_id}]
                },
            },
        }
    }
    return api_json("POST", "/profiles", json=payload)["data"]


def main():
    bundles = api_json(
        "GET",
        f"/bundleIds?{query({'filter[identifier]': BUNDLE_ID, 'limit': '1'})}",
    ).get("data", [])
    if not bundles:
        raise RuntimeError(f"Bundle ID does not exist: {BUNDLE_ID}")
    certificate = matching_certificate()
    profile = ensure_profile(bundles[0]["id"], certificate["id"])
    content = profile.get("attributes", {}).get("profileContent")
    if not content:
        profile = api_json("GET", f"/profiles/{profile['id']}")["data"]
        content = profile.get("attributes", {}).get("profileContent")
    if not content:
        raise RuntimeError("Provisioning profile content was empty")
    PROFILE_PATH.parent.mkdir(parents=True, exist_ok=True)
    PROFILE_PATH.write_bytes(decode_profile(content))
    print(PROFILE_PATH)


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        fail(error)
