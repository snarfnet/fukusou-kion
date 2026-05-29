#!/usr/bin/env python3
import base64
import os
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

import jwt
import requests


KEY_ID = os.environ["ASC_KEY_ID"]
ISSUER = os.environ["ASC_ISSUER_ID"]
P8_PATH = os.environ.get("ASC_P8_PATH", "/tmp/asc_key.p8")
CERT_DIR = Path("/tmp/seiso-signing")
PRIVATE_KEY_PATH = CERT_DIR / "distribution.key"
CSR_PATH = CERT_DIR / "distribution.csr"
CER_PATH = CERT_DIR / "distribution.cer"
P12_PATH = CERT_DIR / "distribution.p12"
P12_PASSWORD = os.environ.get("P12_PASSWORD", "temporary-p12-password")

p8 = open(P8_PATH, encoding="utf-8").read()


def token():
    now = int(time.time())
    payload = {"iss": ISSUER, "iat": now, "exp": now + 1200, "aud": "appstoreconnect-v1"}
    return jwt.encode(payload, p8, algorithm="ES256", headers={"kid": KEY_ID})


def headers():
    return {"Authorization": f"Bearer {token()}", "Content-Type": "application/json"}


def request(method, path, **kwargs):
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
    return response, body


def api_json(method, path, **kwargs):
    response, body = request(method, path, **kwargs)
    if response.status_code >= 400:
        raise RuntimeError(f"{method} {path} failed {response.status_code}: {response.text[:500]}")
    return body


def list_certificates():
    rows = []
    for cert_type in ("IOS_DISTRIBUTION", "DISTRIBUTION"):
        body = api_json("GET", f"/certificates?filter[certificateType]={cert_type}&limit=200")
        rows.extend(body.get("data", []))
    unique = {}
    for cert in rows:
        unique[cert["id"]] = cert
    return list(unique.values())


def parse_date(value):
    if not value:
        return None
    return datetime.fromisoformat(value.replace("Z", "+00:00"))


def revoke_expired_certificate():
    now = datetime.now(timezone.utc)
    expired = []
    for cert in list_certificates():
        attrs = cert.get("attributes", {})
        expiration = parse_date(attrs.get("expirationDate"))
        if expiration and expiration < now:
            expired.append((expiration, cert))
    if not expired:
        return False

    expired.sort(key=lambda item: item[0])
    cert = expired[0][1]
    response, _ = request("DELETE", f"/certificates/{cert['id']}")
    if response.status_code not in (200, 204):
        raise RuntimeError(f"Certificate revoke failed {response.status_code}: {response.text[:500]}")
    print(f"Revoked expired certificate: {cert['id']}", file=sys.stderr, flush=True)
    return True


def generate_csr():
    CERT_DIR.mkdir(parents=True, exist_ok=True)
    subprocess.run(["openssl", "genrsa", "-out", str(PRIVATE_KEY_PATH), "2048"], check=True)
    subprocess.run(
        [
            "openssl",
            "req",
            "-new",
            "-key",
            str(PRIVATE_KEY_PATH),
            "-out",
            str(CSR_PATH),
            "-subj",
            "/CN=SeisoNoKokoroe GitHub Actions/O=Tokyo Nasu/C=JP",
        ],
        check=True,
    )
    return CSR_PATH.read_text(encoding="utf-8")


def create_certificate(csr):
    payload = {
        "data": {
            "type": "certificates",
            "attributes": {"certificateType": "IOS_DISTRIBUTION", "csrContent": csr},
        }
    }
    response, body = request("POST", "/certificates", json=payload)
    if response.status_code in (200, 201):
        return body["data"]

    if response.status_code == 409 and revoke_expired_certificate():
        response, body = request("POST", "/certificates", json=payload)
        if response.status_code in (200, 201):
            return body["data"]

    raise RuntimeError(f"Certificate create failed {response.status_code}: {response.text[:500]}")


def export_p12(certificate):
    content = certificate.get("attributes", {}).get("certificateContent")
    if not content:
        raise RuntimeError("Certificate content is empty.")
    CER_PATH.write_bytes(base64.b64decode(content))
    subprocess.run(
        [
            "openssl",
            "pkcs12",
            "-export",
            "-inkey",
            str(PRIVATE_KEY_PATH),
            "-in",
            str(CER_PATH),
            "-out",
            str(P12_PATH),
            "-passout",
            f"pass:{P12_PASSWORD}",
            "-certpbe",
            "PBE-SHA1-3DES",
            "-keypbe",
            "PBE-SHA1-3DES",
            "-macalg",
            "sha1",
        ],
        check=True,
    )


def main():
    certificate = create_certificate(generate_csr())
    export_p12(certificate)
    print(f"CERTIFICATE_ID={certificate['id']}")
    print(f"GENERATED_P12_PATH={P12_PATH}")
    print(f"GENERATED_P12_PASSWORD={P12_PASSWORD}")


if __name__ == "__main__":
    main()
