#!/usr/bin/env python3
import base64
import hashlib
import os
import subprocess
from pathlib import Path

from asc_helpers import api_json, fail


CURRENT_SHA1 = os.environ["IOS_DISTRIBUTION_CERT_SHA1"].replace(":", "").upper()
KEYCHAIN = os.environ.get("BUILD_KEYCHAIN", "build.keychain")
KEYCHAIN_PASSWORD = os.environ["KEYCHAIN_PASSWORD"]
P12_PASSWORD = os.environ["P12_PASSWORD"]
WORK_DIR = Path("/tmp/sukeban-mahjong-signing")
OUTPUT_P12 = Path("build/signing/distribution.p12")


def run(arguments):
    subprocess.run(arguments, check=True)


def certificate_sha1(certificate):
    content = certificate.get("attributes", {}).get("certificateContent")
    if not content:
        certificate = api_json("GET", f"/certificates/{certificate['id']}")["data"]
        content = certificate.get("attributes", {}).get("certificateContent")
    return hashlib.sha1(base64.b64decode(content)).hexdigest().upper() if content else ""


def active_certificates():
    certificates = {}
    for certificate_type in ("DISTRIBUTION", "IOS_DISTRIBUTION"):
        for certificate in api_json(
            "GET",
            f"/certificates?filter[certificateType]={certificate_type}&limit=200",
        ).get("data", []):
            certificates[certificate["id"]] = certificate
    return list(certificates.values())


def create_certificate():
    WORK_DIR.mkdir(parents=True, exist_ok=True)
    key_path = WORK_DIR / "distribution.key"
    csr_path = WORK_DIR / "distribution.csr"
    der_path = WORK_DIR / "distribution.cer"
    pem_path = WORK_DIR / "distribution.pem"

    run(["openssl", "genrsa", "-out", str(key_path), "2048"])
    run(
        [
            "openssl",
            "req",
            "-new",
            "-key",
            str(key_path),
            "-out",
            str(csr_path),
            "-subj",
            "/CN=SukebanMahjong CI Distribution/O=TokyoNasu/C=JP",
        ]
    )
    payload = {
        "data": {
            "type": "certificates",
            "attributes": {
                "certificateType": "DISTRIBUTION",
                "csrContent": csr_path.read_text(encoding="utf-8"),
            },
        }
    }
    certificate = api_json("POST", "/certificates", json=payload)["data"]
    der_path.write_bytes(
        base64.b64decode(certificate["attributes"]["certificateContent"])
    )
    run(
        [
            "openssl",
            "x509",
            "-inform",
            "DER",
            "-in",
            str(der_path),
            "-out",
            str(pem_path),
        ]
    )
    OUTPUT_P12.parent.mkdir(parents=True, exist_ok=True)
    run(
        [
            "openssl",
            "pkcs12",
            "-export",
            "-out",
            str(OUTPUT_P12),
            "-inkey",
            str(key_path),
            "-in",
            str(pem_path),
            "-passout",
            f"pass:{P12_PASSWORD}",
            "-name",
            "SukebanMahjong Apple Distribution",
        ]
    )
    run(
        [
            "security",
            "import",
            str(OUTPUT_P12),
            "-k",
            KEYCHAIN,
            "-P",
            P12_PASSWORD,
            "-T",
            "/usr/bin/codesign",
            "-T",
            "/usr/bin/security",
        ]
    )
    run(
        [
            "security",
            "set-key-partition-list",
            "-S",
            "apple-tool:,apple:",
            "-s",
            "-k",
            KEYCHAIN_PASSWORD,
            KEYCHAIN,
        ]
    )
    return certificate_sha1(certificate)


def main():
    if any(certificate_sha1(item) == CURRENT_SHA1 for item in active_certificates()):
        print(f"IOS_DISTRIBUTION_CERT_SHA1={CURRENT_SHA1}")
        print("CREATED_DISTRIBUTION_CERTIFICATE=false")
        return
    new_sha1 = create_certificate()
    print(f"IOS_DISTRIBUTION_CERT_SHA1={new_sha1}")
    print("CREATED_DISTRIBUTION_CERTIFICATE=true")


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        fail(error)
