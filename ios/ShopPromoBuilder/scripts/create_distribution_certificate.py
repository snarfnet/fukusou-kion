import base64
import os
import time
from datetime import datetime, timezone
from pathlib import Path

import jwt
import requests


KEY_ID = os.environ["ASC_KEY_ID"]
ISSUER_ID = os.environ["ASC_ISSUER_ID"]
P8_PATH = os.environ.get("ASC_P8_PATH", "/tmp/asc_key.p8")
CSR_PATH = Path(os.environ.get("CSR_PATH", "build/distribution.csr"))
CERT_PATH = Path(os.environ.get("CERT_PATH", "build/distribution.cer"))
REVOKE_CERT_SERIAL = os.environ.get("REVOKE_CERT_SERIAL", "").replace(":", "").upper()
GITHUB_ENV = os.environ.get("GITHUB_ENV")

PRIVATE_KEY = open(P8_PATH, encoding="utf-8").read()


def token():
    now = int(time.time())
    payload = {"iss": ISSUER_ID, "iat": now, "exp": now + 1200, "aud": "appstoreconnect-v1"}
    return jwt.encode(payload, PRIVATE_KEY, algorithm="ES256", headers={"kid": KEY_ID})


def request(method, path, **kwargs):
    headers = {"Authorization": f"Bearer {token()}", "Content-Type": "application/json"}
    return requests.request(method, f"https://api.appstoreconnect.apple.com/v1{path}", headers=headers, timeout=120, **kwargs)


def list_certificates():
    response = request("GET", "/certificates?filter[certificateType]=IOS_DISTRIBUTION&limit=200")
    response.raise_for_status()
    return response.json().get("data", [])


def delete_certificate(certificate_id, reason):
    response = request("DELETE", f"/certificates/{certificate_id}")
    if response.status_code not in (200, 204):
        print(f"Could not revoke certificate {certificate_id}: {response.status_code} {response.text[:300]}")
        return False
    print(f"Revoked certificate {certificate_id}: {reason}")
    return True


def clean_revokable_certificates():
    now = datetime.now(timezone.utc)
    for certificate in list_certificates():
        attrs = certificate.get("attributes", {})
        serial = str(attrs.get("serialNumber", "")).replace(":", "").upper()
        expiration = attrs.get("expirationDate", "")

        if REVOKE_CERT_SERIAL and serial == REVOKE_CERT_SERIAL:
            delete_certificate(certificate["id"], f"matched invalid serial {serial}")
            continue

        if expiration:
            try:
                expires_at = datetime.fromisoformat(expiration.replace("Z", "+00:00"))
            except ValueError:
                expires_at = None
            if expires_at and expires_at < now:
                delete_certificate(certificate["id"], f"expired at {expiration}")


def create_certificate():
    csr_content = CSR_PATH.read_text(encoding="utf-8")
    payload = {
        "data": {
            "type": "certificates",
            "attributes": {
                "certificateType": "IOS_DISTRIBUTION",
                "csrContent": csr_content,
            },
        }
    }
    response = request("POST", "/certificates", json=payload)
    if response.status_code not in (200, 201):
        raise RuntimeError(f"Distribution certificate create failed {response.status_code}: {response.text[:1000]}")

    certificate = response.json()["data"]
    content = certificate["attributes"]["certificateContent"]
    CERT_PATH.parent.mkdir(parents=True, exist_ok=True)
    CERT_PATH.write_bytes(base64.b64decode(content))
    print(f"Distribution certificate created: {certificate['id']}")

    if GITHUB_ENV:
        with open(GITHUB_ENV, "a", encoding="utf-8") as env:
            env.write(f"CERTIFICATE_ID={certificate['id']}\n")


def main():
    clean_revokable_certificates()
    create_certificate()


if __name__ == "__main__":
    main()
