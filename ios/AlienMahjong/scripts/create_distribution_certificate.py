#!/usr/bin/env python3
import base64
from datetime import datetime, timezone
import os
from pathlib import Path

from asc_helpers import api_json, fail, json_body, query

CSR_PATH = Path(os.environ["CERTIFICATE_CSR_PATH"])
OUTPUT_PATH = Path(os.environ["CERTIFICATE_OUTPUT_PATH"])


def is_expired(item):
    value = item.get("attributes", {}).get("expirationDate")
    if not value:
        return False
    return datetime.fromisoformat(value.replace("Z", "+00:00")) <= datetime.now(timezone.utc)


def main():
    profile_result = api_json(
        "GET",
        f"/profiles?{query({'filter[name]': os.environ['PROFILE_NAME'], 'include': 'certificates', 'limit': '1'})}",
    )
    replaceable_ids = {
        item["id"] for item in profile_result.get("included", [])
        if item.get("type") == "certificates"
    }
    if profile_result.get("data"):
        api_json("DELETE", f"/profiles/{profile_result['data'][0]['id']}")

    result = api_json(
        "GET",
        f"/certificates?{query({'filter[certificateType]': 'IOS_DISTRIBUTION', 'limit': '200'})}",
    )
    for certificate in result.get("data", []):
        attributes = certificate.get("attributes", {})
        if (
            is_expired(certificate)
            or certificate["id"] in replaceable_ids
            or attributes.get("name") == "Moonshot Mahjong CI"
        ):
            api_json("DELETE", f"/certificates/{certificate['id']}")
            print(f"Removed replaceable certificate {certificate['id']}")

    payload = {
        "data": {
            "type": "certificates",
            "attributes": {
                "certificateType": "IOS_DISTRIBUTION",
                "csrContent": CSR_PATH.read_text(),
            },
        }
    }
    certificate = api_json("POST", "/certificates", json_body(payload))["data"]
    OUTPUT_PATH.write_bytes(
        base64.b64decode(certificate["attributes"]["certificateContent"])
    )
    print(f"CERTIFICATE_ID={certificate['id']}")


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        fail(error)
