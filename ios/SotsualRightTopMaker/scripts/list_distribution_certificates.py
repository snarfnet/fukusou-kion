#!/usr/bin/env python3
import base64
import hashlib

from asc_helpers import api_json, fail


def sha1(certificate):
    content = certificate.get("attributes", {}).get("certificateContent")
    if not content:
        detail = api_json("GET", f"/certificates/{certificate['id']}").get("data", certificate)
        content = detail.get("attributes", {}).get("certificateContent")
    if not content:
        return ""
    return hashlib.sha1(base64.b64decode(content)).hexdigest().upper()


def main():
    seen = set()
    for cert_type in ("DISTRIBUTION", "IOS_DISTRIBUTION"):
        rows = api_json("GET", f"/certificates?filter[certificateType]={cert_type}&limit=20").get("data", [])
        print(f"{cert_type}: {len(rows)}")
        for certificate in rows:
            if certificate["id"] in seen:
                continue
            seen.add(certificate["id"])
            attrs = certificate.get("attributes", {})
            print(
                "CERT",
                f"id={certificate['id']}",
                f"type={attrs.get('certificateType')}",
                f"name={attrs.get('name')}",
                f"displayName={attrs.get('displayName')}",
                f"serialNumber={attrs.get('serialNumber')}",
                f"expirationDate={attrs.get('expirationDate')}",
                f"sha1={sha1(certificate)}",
            )


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        fail(error)
