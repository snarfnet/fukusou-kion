#!/usr/bin/env python3
import base64
import os
import time
from pathlib import Path

import jwt
import requests


KEY_ID = os.environ["ASC_KEY_ID"]
ISSUER = os.environ["ASC_ISSUER_ID"]
BUNDLE_ID = os.environ.get("APP_BUNDLE_ID", "com.tokyonasu.seisonokokoroe")
PROFILE_NAME = os.environ.get("PROFILE_NAME", "SeisoNoKokoroe App Store")
P8_PATH = os.environ.get("ASC_P8_PATH", "/tmp/asc_key.p8")
PROFILE_PATH = Path.home() / "Library/MobileDevice/Provisioning Profiles/SeisoNoKokoroe_App_Store.mobileprovision"

p8 = open(P8_PATH, encoding="utf-8").read()


def token():
    now = int(time.time())
    payload = {"iss": ISSUER, "iat": now, "exp": now + 1200, "aud": "appstoreconnect-v1"}
    return jwt.encode(payload, p8, algorithm="ES256", headers={"kid": KEY_ID})


def headers():
    return {"Authorization": f"Bearer {token()}", "Content-Type": "application/json"}


def api_json(method, path, **kwargs):
    response = requests.request(
        method,
        f"https://api.appstoreconnect.apple.com/v1{path}",
        headers=headers(),
        timeout=120,
        **kwargs,
    )
    try:
        body = response.json()
    except Exception:
        body = {}
    if response.status_code >= 400:
        raise RuntimeError(f"{method} {path} failed {response.status_code}: {response.text[:500]}")
    return body


def find_bundle_id():
    data = api_json("GET", f"/bundleIds?filter[identifier]={BUNDLE_ID}&limit=1").get("data", [])
    if not data:
        raise RuntimeError(f"Bundle ID does not exist: {BUNDLE_ID}")
    return data[0]["id"]


def find_distribution_certificate():
    for cert_type in ("IOS_DISTRIBUTION", "DISTRIBUTION"):
        data = api_json("GET", f"/certificates?filter[certificateType]={cert_type}&limit=20").get("data", [])
        if data:
            return data[0]["id"]
    raise RuntimeError("No Apple distribution certificate found in App Store Connect.")


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
    profile = find_or_create_profile(find_bundle_id(), find_distribution_certificate())
    content = profile.get("attributes", {}).get("profileContent")
    if not content:
        profile = api_json("GET", f"/profiles/{profile['id']}")["data"]
        content = profile.get("attributes", {}).get("profileContent")
    if not content:
        raise RuntimeError("Provisioning profile exists but profileContent is empty.")

    PROFILE_PATH.parent.mkdir(parents=True, exist_ok=True)
    PROFILE_PATH.write_bytes(base64.b64decode(content))
    print(f"PROFILE_NAME={PROFILE_NAME}")
    print(f"PROFILE_PATH={PROFILE_PATH}")


if __name__ == "__main__":
    main()
