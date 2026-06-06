import hashlib
import os
import time
from pathlib import Path

import requests

from asc_api import api, find_app_id, get_or_create_version, list_all

APP_VERSION = os.environ.get("APP_VERSION", "1.0")
SCREENSHOT_DIR = Path("AppStoreScreenshots")
SCREENSHOT_GROUPS = [
    ("APP_IPHONE_65", ["gyaru-othello-iphone-01.png"]),
    ("APP_IPAD_PRO_3GEN_129", ["gyaru-othello-ipad-01.png"]),
]


def main():
    app_id = find_app_id()
    version_id = get_or_create_version(app_id, APP_VERSION)
    localizations = list_all(f"/appStoreVersions/{version_id}/appStoreVersionLocalizations?limit=20")
    if not localizations:
        raise RuntimeError("No localization found. Run prepare_asc.py first.")

    for loc in localizations:
        locale = loc.get("attributes", {}).get("locale", "unknown")
        print(f"Uploading screenshots for {locale}")
        upload_for_localization(loc["id"])


def upload_for_localization(localization_id):
    existing_sets = list_all(f"/appStoreVersionLocalizations/{localization_id}/appScreenshotSets?limit=200")
    existing_by_type = {item["attributes"]["screenshotDisplayType"]: item["id"] for item in existing_sets}

    for display_type, filenames in SCREENSHOT_GROUPS:
        set_id = existing_by_type.get(display_type) or create_set(localization_id, display_type)
        clear_set(set_id)
        for filename in filenames:
            upload_screenshot(set_id, filename)


def create_set(localization_id, display_type):
    payload = api("POST", "/appScreenshotSets", json={
        "data": {
            "type": "appScreenshotSets",
            "attributes": {"screenshotDisplayType": display_type},
            "relationships": {
                "appStoreVersionLocalization": {
                    "data": {"type": "appStoreVersionLocalizations", "id": localization_id}
                }
            },
        }
    })
    return payload["data"]["id"]


def clear_set(set_id):
    for screenshot in list_all(f"/appScreenshotSets/{set_id}/appScreenshots?limit=200"):
        api("DELETE", f"/appScreenshots/{screenshot['id']}")


def upload_screenshot(set_id, filename):
    path = SCREENSHOT_DIR / filename
    data = path.read_bytes()
    checksum = hashlib.md5(data).hexdigest()
    created = api("POST", "/appScreenshots", json={
        "data": {
            "type": "appScreenshots",
            "attributes": {"fileName": filename, "fileSize": len(data)},
            "relationships": {"appScreenshotSet": {"data": {"type": "appScreenshotSets", "id": set_id}}},
        }
    })
    screenshot_id = created["data"]["id"]

    for operation in created["data"]["attributes"]["uploadOperations"]:
        headers = {item["name"]: item["value"] for item in operation["requestHeaders"]}
        start = operation["offset"]
        end = start + operation["length"]
        response = requests.put(operation["url"], headers=headers, data=data[start:end], timeout=120)
        response.raise_for_status()

    for attempt in range(1, 7):
        try:
            api("PATCH", f"/appScreenshots/{screenshot_id}", json={
                "data": {
                    "type": "appScreenshots",
                    "id": screenshot_id,
                    "attributes": {"uploaded": True, "sourceFileChecksum": checksum},
                }
            })
            print(f"{filename}: uploaded")
            return
        except RuntimeError as error:
            print(f"{filename}: confirm retry {attempt}/6 {error}")
            time.sleep(20)
    raise RuntimeError(f"Screenshot confirm failed: {filename}")


if __name__ == "__main__":
    main()
