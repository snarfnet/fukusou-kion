#!/usr/bin/env python3
"""Revoke only the temporary distribution certificate created by this CI run."""

import os

from asc_helpers import api, fail


def main() -> None:
    certificate_id = os.environ.get("ASC_CERTIFICATE_ID", "").strip()
    if not certificate_id:
        print("No CI certificate ID was exported; nothing to revoke.")
        return
    response = api("DELETE", f"/certificates/{certificate_id}")
    if response.status_code not in (200, 204, 404):
        raise RuntimeError(
            f"Could not revoke CI certificate {certificate_id}: "
            f"{response.status_code} {response.text[:400]}"
        )
    print(f"Revoked CI distribution certificate {certificate_id}: {response.status_code}")


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        fail(error)
