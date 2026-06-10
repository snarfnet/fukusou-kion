import base64
import os
import time
from pathlib import Path

import jwt
import requests


KEY_ID = os.environ["ASC_KEY_ID"]
ISSUER_ID = os.environ["ASC_ISSUER_ID"]
P8_PATH = os.environ.get("ASC_P8_PATH", "/tmp/asc_key.p8")
BUNDLE_ID = os.environ.get("APP_BUNDLE_ID", "com.tokyonasu.shoppromobuilder")
PROFILE_NAME = os.environ.get("PROFILE_NAME", "ShopPromoBuilder App Store")
PROFILE_PATH = Path(os.environ.get("PROFILE_PATH", "build/ShopPromoBuilder_App_Store.mobileprovision"))
CERTIFICATE_ID = os.environ.get("CERTIFICATE_ID", "")

PRIVATE_KEY = open(P8_PATH, encoding="utf-8").read()


def token():
    now = int(time.time())
    payload = {"iss": ISSUER_ID, "iat": now, "exp": now + 1200, "aud": "appstoreconnect-v1"}
    return jwt.encode(payload, PRIVATE_KEY, algorithm="ES256", headers={"kid": KEY_ID})


def request(method, path, **kwargs):
    headers = {"Authorization": f"Bearer {token()}", "Content-Type": "application/json"}
    return requests.request(method, f"https://api.appstoreconnect.apple.com/v1{path}", headers=headers, timeout=120, **kwargs)


def get_first(path, label):
    response = request("GET", path)
    response.raise_for_status()
    data = response.json().get("data", [])
    if not data:
        raise RuntimeError(f"No {label} found for {path}")
    return data[0]


def find_bundle_id():
    return get_first(f"/bundleIds?filter[identifier]={BUNDLE_ID}&limit=1", "Bundle ID")


def find_distribution_certificate():
    if CERTIFICATE_ID:
        response = request("GET", f"/certificates/{CERTIFICATE_ID}")
        response.raise_for_status()
        return response.json()["data"]

    response = request("GET", "/certificates?filter[certificateType]=IOS_DISTRIBUTION&limit=200")
    response.raise_for_status()
    certificates = response.json().get("data", [])
    if not certificates:
        raise RuntimeError("No iOS distribution certificate found")
    certificates.sort(key=lambda item: item.get("attributes", {}).get("expirationDate", ""), reverse=True)
    return certificates[0]


def find_profile():
    response = request("GET", f"/profiles?filter[name]={PROFILE_NAME}&filter[profileType]=IOS_APP_STORE&limit=1")
    response.raise_for_status()
    data = response.json().get("data", [])
    return data[0] if data else None


def create_profile(bundle_id, certificate_id):
    payload = {
        "data": {
            "type": "profiles",
            "attributes": {
                "name": PROFILE_NAME,
                "profileType": "IOS_APP_STORE",
            },
            "relationships": {
                "bundleId": {"data": {"type": "bundleIds", "id": bundle_id}},
                "certificates": {"data": [{"type": "certificates", "id": certificate_id}]},
            },
        }
    }
    response = request("POST", "/profiles", json=payload)
    if response.status_code not in (200, 201):
        raise RuntimeError(f"Profile create failed {response.status_code}: {response.text[:800]}")
    return response.json()["data"]


def write_profile(profile):
    content = profile.get("attributes", {}).get("profileContent")
    if not content:
        profile_id = profile["id"]
        response = request("GET", f"/profiles/{profile_id}")
        response.raise_for_status()
        content = response.json()["data"].get("attributes", {}).get("profileContent")
    if not content:
        raise RuntimeError("Profile content was empty")

    PROFILE_PATH.parent.mkdir(parents=True, exist_ok=True)
    PROFILE_PATH.write_bytes(base64.b64decode(content))

    install_dir = Path.home() / "Library" / "MobileDevice" / "Provisioning Profiles"
    install_dir.mkdir(parents=True, exist_ok=True)
    installed_path = install_dir / f"{PROFILE_NAME}.mobileprovision"
    installed_path.write_bytes(PROFILE_PATH.read_bytes())
    print(f"Provisioning profile installed: {installed_path}")


def main():
    bundle = find_bundle_id()
    certificate = find_distribution_certificate()
    profile = find_profile()
    if profile:
        print(f"Profile already exists: {profile['id']} {PROFILE_NAME}")
    else:
        profile = create_profile(bundle["id"], certificate["id"])
        print(f"Profile created: {profile['id']} {PROFILE_NAME}")
    write_profile(profile)


if __name__ == "__main__":
    main()
