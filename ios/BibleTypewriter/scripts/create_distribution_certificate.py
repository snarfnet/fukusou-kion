#!/usr/bin/env python3
import hashlib
import os
import subprocess
from pathlib import Path

from asc_helpers import api_json, fail, json_body


KEYCHAIN = os.environ.get("BUILD_KEYCHAIN", "build.keychain")
WORK_DIR = Path("/tmp/bibletypewriter-signing")
KEY_PATH = WORK_DIR / "distribution.key"
CSR_PATH = WORK_DIR / "distribution.csr"
CERT_PATH = WORK_DIR / "distribution.cer"
REVOKE_EXISTING = os.environ.get("REVOKE_EXISTING_DISTRIBUTION_CERTS") == "1"


def run(args):
    print("+", " ".join(str(arg) for arg in args), flush=True)
    subprocess.run(args, check=True)


def generate_csr():
    WORK_DIR.mkdir(parents=True, exist_ok=True)
    run(["openssl", "genrsa", "-out", str(KEY_PATH), "2048"])
    run([
        "openssl",
        "req",
        "-new",
        "-key",
        str(KEY_PATH),
        "-out",
        str(CSR_PATH),
        "-subj",
        "/CN=BibleTypewriter CI Distribution/O=TokyoNasu/C=JP",
    ])


def revoke_existing_certificates():
    certificates = []
    for certificate_type in ("DISTRIBUTION", "IOS_DISTRIBUTION"):
        certificates.extend(api_json("GET", f"/certificates?filter[certificateType]={certificate_type}&limit=100").get("data", []))
    seen_ids = set()
    for certificate in certificates:
        certificate_id = certificate["id"]
        if certificate_id in seen_ids:
            continue
        seen_ids.add(certificate_id)
        print(f"Revoking existing distribution certificate: {certificate_id}")
        api_json("DELETE", f"/certificates/{certificate_id}")


def create_certificate():
    csr_content = CSR_PATH.read_text(encoding="utf-8")
    last_error = None
    for certificate_type in ("DISTRIBUTION", "IOS_DISTRIBUTION"):
        payload = {
            "data": {
                "type": "certificates",
                "attributes": {
                    "certificateType": certificate_type,
                    "csrContent": csr_content,
                },
            }
        }
        try:
            certificate = api_json("POST", "/certificates", data=json_body(payload))["data"]
            print(f"Created certificate: {certificate['id']} ({certificate_type})")
            return certificate
        except Exception as error:
            last_error = error
            print(f"Certificate create failed for {certificate_type}: {error}")
    raise RuntimeError(last_error)


def import_certificate(certificate):
    content = certificate.get("attributes", {}).get("certificateContent")
    if not content:
        raise RuntimeError("Created certificate did not include certificateContent.")

    import base64
    CERT_PATH.write_bytes(base64.b64decode(content))
    run(["security", "import", str(KEY_PATH), "-k", KEYCHAIN, "-T", "/usr/bin/codesign", "-T", "/usr/bin/security"])
    run(["security", "import", str(CERT_PATH), "-k", KEYCHAIN, "-T", "/usr/bin/codesign", "-T", "/usr/bin/security"])
    run(["security", "set-key-partition-list", "-S", "apple-tool:,apple:", "-s", "-k", os.environ["KEYCHAIN_PASSWORD"], KEYCHAIN])

    sha1 = hashlib.sha1(CERT_PATH.read_bytes()).hexdigest().upper()
    print(f"IOS_DISTRIBUTION_CERT_SHA1={sha1}")
    print(f"ASC_CERTIFICATE_ID={certificate['id']}")


def main():
    if REVOKE_EXISTING:
        revoke_existing_certificates()
    generate_csr()
    certificate = create_certificate()
    import_certificate(certificate)


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        fail(error)
