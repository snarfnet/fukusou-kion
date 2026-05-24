#!/usr/bin/env python3
import hashlib
import os
import re
import time
from pathlib import Path

import requests

from asc_helpers import api, api_json, fail, json_body, query


ROOT = Path(__file__).resolve().parents[1]
APP_ID = os.environ["APP_ID"]
APP_VERSION = os.environ.get("APP_VERSION", "1.0")
SCREENSHOT_ROOT = ROOT / "MarketingAssets" / "Screenshots"

SCREENSHOT_GROUPS = [
    ("APP_IPHONE_67", "iphone67"),
    ("APP_IPHONE_65", "iphone65"),
    ("APP_IPHONE_55", "iphone55"),
    ("APP_IPAD_PRO_3GEN_129", "ipad129"),
]

LOCALES = {
    "ja": ROOT / "AppStore" / "metadata_ja.md",
    "en-US": ROOT / "AppStore" / "metadata_en.md",
}
APP_INFO = {
    "ja": {
        "name": "煙草屋のおばぁちゃん",
        "subtitle": "昔ながらの知恵袋が流れる",
    },
    "en-US": {
        "name": "Grandma Tobacco Shop",
        "subtitle": "Old-fashioned daily wisdom",
    },
}
PRIVACY_POLICY_URL = "https://snarfnet.github.io/"


def list_all(path):
    rows = []
    while path:
        body = api_json("GET", path)
        rows.extend(body.get("data", []))
        next_url = body.get("links", {}).get("next")
        path = next_url.split("/v1", 1)[1] if next_url else None
    return rows


def section(markdown, heading):
    pattern = rf"^## {re.escape(heading)}\s*\n(.*?)(?=^## |\Z)"
    match = re.search(pattern, markdown, flags=re.M | re.S)
    return match.group(1).strip() if match else ""


def read_meta(locale):
    text = LOCALES[locale].read_text(encoding="utf-8")
    if locale == "ja":
        return {
            "name": section(text, "アプリ名")[:30],
            "subtitle": section(text, "サブタイトル")[:30],
            "promotionalText": section(text, "プロモーションテキスト")[:170],
            "keywords": section(text, "キーワード")[:100],
            "description": section(text, "説明文")[:4000],
            "whatsNew": "初回リリースです。",
        }
    return {
        "name": section(text, "App Name")[:30],
        "subtitle": section(text, "Subtitle")[:30],
        "promotionalText": section(text, "Promotional Text")[:170],
        "keywords": section(text, "Keywords")[:100],
        "description": section(text, "Description")[:4000],
        "whatsNew": "Initial release.",
    }


def find_or_create_version():
    versions = list_all(f"/apps/{APP_ID}/appStoreVersions?{query({'filter[platform]': 'IOS', 'limit': '200'})}")
    for version in versions:
        attrs = version.get("attributes", {})
        if attrs.get("versionString") == APP_VERSION:
            print(f"App Store version exists: {APP_VERSION} ({version['id']}) state={attrs.get('appStoreState')}")
            return version

    payload = {
        "data": {
            "type": "appStoreVersions",
            "attributes": {"platform": "IOS", "versionString": APP_VERSION},
            "relationships": {"app": {"data": {"type": "apps", "id": APP_ID}}},
        }
    }
    version = api_json("POST", "/appStoreVersions", data=json_body(payload))["data"]
    print(f"App Store version created: {APP_VERSION} ({version['id']})")
    return version


def ensure_localizations(version_id):
    localizations = list_all(f"/appStoreVersions/{version_id}/appStoreVersionLocalizations?limit=200")
    existing = {item["attributes"]["locale"]: item for item in localizations}

    result = {}
    for locale in LOCALES:
        if locale not in existing:
            payload = {
                "data": {
                    "type": "appStoreVersionLocalizations",
                    "attributes": {"locale": locale},
                    "relationships": {
                        "appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}}
                    },
                }
            }
            existing[locale] = api_json("POST", "/appStoreVersionLocalizations", data=json_body(payload))["data"]

        loc_id = existing[locale]["id"]
        meta = read_meta(locale)
        payload = {
            "data": {
                "type": "appStoreVersionLocalizations",
                "id": loc_id,
                "attributes": {
                    "description": meta["description"],
                    "keywords": meta["keywords"],
                    "marketingUrl": "https://snarfnet.github.io/",
                    "promotionalText": meta["promotionalText"],
                    "supportUrl": "https://snarfnet.github.io/",
                },
            }
        }
        api_json("PATCH", f"/appStoreVersionLocalizations/{loc_id}", data=json_body(payload))
        print(f"Metadata updated: {locale}")
        result[locale] = loc_id

    return result


def ensure_app_info_localizations():
    infos = api_json("GET", f"/apps/{APP_ID}/appInfos?limit=10").get("data", [])
    if not infos:
        return

    info_id = infos[0]["id"]
    api_json(
        "PATCH",
        f"/apps/{APP_ID}",
        data=json_body({
            "data": {
                "type": "apps",
                "id": APP_ID,
                "attributes": {
                    "contentRightsDeclaration": "DOES_NOT_USE_THIRD_PARTY_CONTENT",
                },
            }
        }),
    )
    api_json(
        "PATCH",
        f"/appInfos/{info_id}",
        data=json_body({
            "data": {
                "type": "appInfos",
                "id": info_id,
                "relationships": {
                    "primaryCategory": {
                        "data": {"type": "appCategories", "id": "LIFESTYLE"}
                    }
                },
            }
        }),
    )

    string_keys = [
        "contests",
        "gamblingSimulated",
        "gunsOrOtherWeapons",
        "medicalOrTreatmentInformation",
        "profanityOrCrudeHumor",
        "sexualContentGraphicAndNudity",
        "sexualContentOrNudity",
        "horrorOrFearThemes",
        "matureOrSuggestiveThemes",
        "violenceCartoonOrFantasy",
        "violenceRealisticProlongedGraphicOrSadistic",
        "violenceRealistic",
    ]
    rating_attrs = {key: "NONE" for key in string_keys}
    rating_attrs["alcoholTobaccoOrDrugUseOrReferences"] = "INFREQUENT_OR_MILD"
    rating_attrs.update({
        "messagingAndChat": False,
        "gambling": False,
        "parentalControls": False,
        "ageAssurance": False,
        "userGeneratedContent": False,
        "healthOrWellnessTopics": False,
        "unrestrictedWebAccess": False,
        "lootBox": False,
        "advertising": True,
    })
    api_json(
        "PATCH",
        f"/ageRatingDeclarations/{info_id}",
        data=json_body({
            "data": {
                "type": "ageRatingDeclarations",
                "id": info_id,
                "attributes": rating_attrs,
            }
        }),
    )

    localizations = api_json("GET", f"/appInfos/{info_id}/appInfoLocalizations?limit=50").get("data", [])
    existing = {item["attributes"]["locale"]: item for item in localizations}

    for locale, attrs in APP_INFO.items():
        if locale not in existing:
            payload = {
                "data": {
                    "type": "appInfoLocalizations",
                    "attributes": {"locale": locale, **attrs, "privacyPolicyUrl": PRIVACY_POLICY_URL},
                    "relationships": {"appInfo": {"data": {"type": "appInfos", "id": info_id}}},
                }
            }
            api_json("POST", "/appInfoLocalizations", data=json_body(payload))
            print(f"App info created: {locale}")
            continue

        loc_id = existing[locale]["id"]
        payload = {
            "data": {
                "type": "appInfoLocalizations",
                "id": loc_id,
                "attributes": {**attrs, "privacyPolicyUrl": PRIVACY_POLICY_URL},
            }
        }
        api_json("PATCH", f"/appInfoLocalizations/{loc_id}", data=json_body(payload))
        print(f"App info updated: {locale}")


def ensure_free_price():
    points = api_json("GET", f"/apps/{APP_ID}/appPricePoints?filter[territory]=USA&limit=1").get("data", [])
    if not points:
        return

    local_id = "${manualPrice0}"
    payload = {
        "data": {
            "type": "appPriceSchedules",
            "relationships": {
                "app": {"data": {"type": "apps", "id": APP_ID}},
                "baseTerritory": {"data": {"type": "territories", "id": "USA"}},
                "manualPrices": {"data": [{"type": "appPrices", "id": local_id}]},
            },
        },
        "included": [{
            "type": "appPrices",
            "id": local_id,
            "attributes": {"startDate": "2026-05-23"},
            "relationships": {
                "appPricePoint": {
                    "data": {"type": "appPricePoints", "id": points[0]["id"]}
                }
            },
        }],
    }
    api_json("POST", "/appPriceSchedules", data=json_body(payload))
    print("Free price updated")


def upload_screenshot(set_id, path):
    data = path.read_bytes()
    checksum = hashlib.md5(data).hexdigest()
    payload = {
        "data": {
            "type": "appScreenshots",
            "attributes": {"fileName": path.name, "fileSize": len(data)},
            "relationships": {"appScreenshotSet": {"data": {"type": "appScreenshotSets", "id": set_id}}},
        }
    }
    screenshot = api_json("POST", "/appScreenshots", data=json_body(payload))["data"]

    for operation in screenshot["attributes"]["uploadOperations"]:
        headers = {item["name"]: item["value"] for item in operation["requestHeaders"]}
        start = operation["offset"]
        end = start + operation["length"]
        response = requests.put(operation["url"], headers=headers, data=data[start:end], timeout=120)
        if response.status_code not in (200, 201):
            raise RuntimeError(f"Screenshot binary upload failed {response.status_code}: {response.text[:300]}")

    payload = {
        "data": {
            "type": "appScreenshots",
            "id": screenshot["id"],
            "attributes": {"uploaded": True, "sourceFileChecksum": checksum},
        }
    }
    api_json("PATCH", f"/appScreenshots/{screenshot['id']}", data=json_body(payload))
    print(f"  uploaded {path.name}")


def ensure_screenshot_set(localization_id, display_type):
    sets = list_all(f"/appStoreVersionLocalizations/{localization_id}/appScreenshotSets?limit=200")
    for item in sets:
        if item["attributes"]["screenshotDisplayType"] == display_type:
            set_id = item["id"]
            for screenshot in list_all(f"/appScreenshotSets/{set_id}/appScreenshots?limit=200"):
                api_json("DELETE", f"/appScreenshots/{screenshot['id']}")
            return set_id

    payload = {
        "data": {
            "type": "appScreenshotSets",
            "attributes": {"screenshotDisplayType": display_type},
            "relationships": {
                "appStoreVersionLocalization": {
                    "data": {"type": "appStoreVersionLocalizations", "id": localization_id}
                }
            },
        }
    }
    return api_json("POST", "/appScreenshotSets", data=json_body(payload))["data"]["id"]


def upload_screenshots(localization_ids):
    for locale, localization_id in localization_ids.items():
        print(f"Screenshots: {locale}")
        for display_type, folder in SCREENSHOT_GROUPS:
            paths = sorted((SCREENSHOT_ROOT / folder).glob("*.png"))
            if not paths:
                raise RuntimeError(f"No screenshots found: {SCREENSHOT_ROOT / folder}")
            set_id = ensure_screenshot_set(localization_id, display_type)
            print(f" {display_type}: {len(paths)} files")
            for path in paths:
                upload_screenshot(set_id, path)
            time.sleep(2)


def main():
    version = find_or_create_version()
    ensure_app_info_localizations()
    localization_ids = ensure_localizations(version["id"])
    upload_screenshots(localization_ids)
    print(f"ASC assets uploaded for app {APP_ID}, version {APP_VERSION}.")


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        fail(error)
