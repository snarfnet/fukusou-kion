"""Create only TYPO-owned temporary signing assets; never revoke existing identities."""
import base64
import json
import os
from pathlib import Path
import plistlib
import sys
import time

from cryptography import x509
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.hazmat.primitives.serialization import pkcs12
from cryptography.x509.oid import NameOID

from asc import api

BUNDLE = "com.tokyonasu.typo"
APP_ID = "6824906557"
TEAM = "83VGKGSQUH"
TEMP = Path(os.environ["RUNNER_TEMP"])
STATE = TEMP / "typo-signing-state.json"


def prepare():
    bundles = api("GET", f"/bundleIds?filter[identifier]={BUNDLE}")["data"]
    if not bundles:
        raise RuntimeError("TYPO's registered bundle ID is missing.")
    apps = api("GET", f"/apps?filter[bundleId]={BUNDLE}")["data"]
    if not apps or apps[0]["id"] != APP_ID:
        raise RuntimeError("TYPO's App Store Connect record does not match.")
    key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    csr = (x509.CertificateSigningRequestBuilder()
           .subject_name(x509.Name([x509.NameAttribute(NameOID.COMMON_NAME, "TYPO CI")]))
           .sign(key, hashes.SHA256()))
    certificate = api("POST", "/certificates", {"data": {"type": "certificates", "attributes": {
        "certificateType": "DISTRIBUTION",
        "csrContent": csr.public_bytes(serialization.Encoding.PEM).decode()
    }}})["data"]
    state = {"certificate": certificate["id"]}
    STATE.write_text(json.dumps(state))
    cert = x509.load_der_x509_certificate(base64.b64decode(certificate["attributes"]["certificateContent"]))
    password = os.environ["SIGNING_PASSWORD"]
    p12 = pkcs12.serialize_key_and_certificates(b"TYPO CI", key, cert, None,
                                               serialization.BestAvailableEncryption(password.encode()))
    p12_path = TEMP / "typo-distribution.p12"
    p12_path.write_bytes(p12)
    p12_path.chmod(0o600)
    profile_name = "TYPO CI " + os.environ["GITHUB_RUN_ID"] + "-" + os.environ.get("GITHUB_RUN_ATTEMPT", "1")
    profile = api("POST", "/profiles", {"data": {"type": "profiles", "attributes": {
        "name": profile_name, "profileType": "IOS_APP_STORE"
    }, "relationships": {
        "bundleId": {"data": {"type": "bundleIds", "id": bundles[0]["id"]}},
        "certificates": {"data": [{"type": "certificates", "id": certificate["id"]}]}
    }}})["data"]
    state["profile"] = profile["id"]
    STATE.write_text(json.dumps(state))
    profile_bytes = base64.b64decode(profile["attributes"]["profileContent"])
    for folder in [Path.home() / "Library/MobileDevice/Provisioning Profiles",
                   Path.home() / "Library/Developer/Xcode/UserData/Provisioning Profiles"]:
        folder.mkdir(parents=True, exist_ok=True)
        (folder / (profile["attributes"]["uuid"] + ".mobileprovision")).write_bytes(profile_bytes)
    fingerprint = cert.fingerprint(hashes.SHA1()).hex().upper()
    with open(os.environ["GITHUB_ENV"], "a") as env:
        env.write("TYPO_PROFILE_NAME=" + profile_name + "\nTYPO_CERT_SHA1=" + fingerprint + "\n")
    with (TEMP / "typo-export-options.plist").open("wb") as stream:
        plistlib.dump({"method": "app-store-connect", "destination": "export", "teamID": TEAM,
                      "signingStyle": "manual", "signingCertificate": fingerprint,
                      "provisioningProfiles": {BUNDLE: profile_name},
                      "manageAppVersionAndBuildNumber": False, "uploadSymbols": True}, stream)
    print("TYPO-only distribution certificate and provisioning profile prepared.")


def cleanup():
    if not STATE.exists():
        return
    state = json.loads(STATE.read_text())
    # IDs originate exclusively from resources created by this job.
    for key, endpoint in [("profile", "/profiles/"), ("certificate", "/certificates/")]:
        if state.get(key):
            api("DELETE", endpoint + state[key])
            state.pop(key)
            STATE.write_text(json.dumps(state))
    print("Temporary TYPO signing assets removed. Existing certificates were not modified.")


def wait_for_build():
    build_number = os.environ["TYPO_BUILD_NUMBER"]
    deadline = time.monotonic() + 1800
    while time.monotonic() < deadline:
        builds = api("GET", f"/builds?filter[app]={APP_ID}&filter[version]={build_number}&limit=10")["data"]
        if builds:
            build = builds[0]
            state = build["attributes"]["processingState"]
            print("TestFlight processing:", state, flush=True)
            if state == "VALID":
                summary = Path(os.environ["GITHUB_STEP_SUMMARY"])
                with summary.open("a") as stream:
                    stream.write(f"## TYPO TestFlight\nBuild {build_number}: **VALID**\n\n")
                    stream.write(f"App Store Connect: https://appstoreconnect.apple.com/apps/{APP_ID}/testflight\n")
                Path("build/testflight-result.json").write_text(json.dumps({
                    "appID": APP_ID, "bundleID": BUNDLE, "build": build_number,
                    "buildID": build["id"], "processingState": state
                }, indent=2))
                return
            if state in ["FAILED", "INVALID"]:
                raise RuntimeError("Apple rejected processing of the build: " + state)
        else:
            print("Waiting for the uploaded build to appear.", flush=True)
        time.sleep(30)
    raise TimeoutError("Apple is still processing the build. Check App Store Connect before uploading another.")


if __name__ == "__main__":
    {"prepare": prepare, "cleanup": cleanup, "wait": wait_for_build}[sys.argv[1]]()
