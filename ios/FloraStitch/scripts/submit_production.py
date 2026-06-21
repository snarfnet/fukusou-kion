#!/usr/bin/env python3
import hashlib
import os
import time
from decimal import Decimal
from pathlib import Path

import requests
from requests import RequestException

from asc_helpers import api, api_json


APP_ID = os.environ["APP_ID"]
APP_VERSION = os.environ.get("APP_VERSION", "1.0")
BUILD_NUMBER = os.environ["BUILD_NUMBER"]
APP_PRICE_JPY = Decimal(os.environ.get("APP_PRICE_JPY", "200"))
SCREENSHOT_DIR = Path("MarketingAssets/Screenshots")

SCREENSHOT_GROUPS = [
    ("APP_IPHONE_67", [f"iphone69_{i:02d}.png" for i in range(1, 6)]),
    ("APP_IPHONE_65", [f"iphone65_{i:02d}.png" for i in range(1, 6)]),
    ("APP_IPHONE_55", [f"iphone55_{i:02d}.png" for i in range(1, 6)]),
    ("APP_IPAD_PRO_3GEN_129", [f"ipad129_{i:02d}.png" for i in range(1, 6)]),
]

META = {
    "ja": {
        "description": """Flora Stitchは、花、葉、木の実、つる、小鳥を組み合わせた刺しゅう向けの模様を作るアプリです。

ランダムシードから横長のボーダー柄を生成し、写真を色付きベクタータイルとして混ぜることもできます。

作ったデザインはSVG、DST、PES形式で保存できます。刺しゅうデータの下絵作成、模様の検討、クラフト作品のアイデア出しに使えます。""",
        "keywords": "刺しゅう,SVG,DST,PES,ベクター,花,模様,クラフト,ミシン刺繍,デザイン",
        "whatsNew": "初回リリースです。",
        "promotionalText": "花や葉、小鳥の刺しゅう風ボーダー柄をランダム生成。",
        "marketingUrl": "https://snarfnet.github.io/",
    },
    "en-US": {
        "description": """Flora Stitch creates embroidery-inspired floral border patterns from random seeds.

Generate vines, leaves, flowers, berries, curls, and simple bird line art. You can also import a photo and mix it into the design as colored vector tiles.

Save your design as SVG, DST, or PES for design review, craft planning, and embroidery test workflows.""",
        "keywords": "embroidery,SVG,DST,PES,vector,floral,pattern,craft,stitch,design",
        "whatsNew": "Initial release.",
        "promotionalText": "Generate floral embroidery-style borders from random seeds.",
        "marketingUrl": "https://snarfnet.github.io/",
    },
}


def list_all(path):
    rows = []
    next_path = path
    while next_path:
        body = api_json("GET", next_path)
        rows.extend(body.get("data", []))
        next_url = body.get("links", {}).get("next")
        next_path = next_url.split("/v1", 1)[1] if next_url and "/v1" in next_url else None
    return rows


def api_json_or_none(method, path, **kwargs):
    response = api(method, path, **kwargs)
    try:
        body = response.json()
    except Exception:
        body = {}
    if response.status_code in (200, 201, 204):
        return response, body
    print(f"Optional {method} {path}: {response.status_code} {response.text[:240]}")
    return response, body


def find_or_create_version():
    for version in list_all(f"/apps/{APP_ID}/appStoreVersions?filter[platform]=IOS&limit=200"):
        attrs = version.get("attributes", {})
        if attrs.get("versionString") == APP_VERSION:
            print(f"Found version {APP_VERSION}: {version['id']} state={attrs.get('appStoreState')}")
            return version["id"], attrs.get("appStoreState")

    body = api_json("POST", "/appStoreVersions", json={
        "data": {
            "type": "appStoreVersions",
            "attributes": {"platform": "IOS", "versionString": APP_VERSION},
            "relationships": {"app": {"data": {"type": "apps", "id": APP_ID}}},
        }
    })
    return body["data"]["id"], "PREPARE_FOR_SUBMISSION"


def ensure_release_prerequisites(version_id):
    api_json_or_none("PATCH", f"/apps/{APP_ID}", json={
        "data": {
            "type": "apps",
            "id": APP_ID,
            "attributes": {"contentRightsDeclaration": "DOES_NOT_USE_THIRD_PARTY_CONTENT"},
        }
    })
    response, body = api_json_or_none("GET", f"/apps/{APP_ID}/appInfos?limit=10")
    app_infos = body.get("data", []) if response.status_code == 200 else []
    if app_infos:
        app_info_id = app_infos[0]["id"]
        api_json_or_none("PATCH", f"/appInfos/{app_info_id}", json={
            "data": {
                "type": "appInfos",
                "id": app_info_id,
                "relationships": {
                    "primaryCategory": {"data": {"type": "appCategories", "id": "GRAPHICS_AND_DESIGN"}}
                },
            }
        })
        update_age_rating(app_info_id)
        update_app_info_localizations(app_info_id)

    api_json_or_none("PATCH", f"/appStoreVersions/{version_id}", json={
        "data": {
            "type": "appStoreVersions",
            "id": version_id,
            "attributes": {"copyright": "2026 Tokyo Nasu", "usesIdfa": False},
        }
    })
    ensure_global_price()
    ensure_global_availability()
    ensure_review_detail(version_id)


def update_age_rating(app_info_id):
    string_keys = [
        "alcoholTobaccoOrDrugUseOrReferences",
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
    bool_keys = [
        "messagingAndChat",
        "gambling",
        "parentalControls",
        "ageAssurance",
        "userGeneratedContent",
        "healthOrWellnessTopics",
        "unrestrictedWebAccess",
        "lootBox",
        "advertising",
    ]
    attrs = {key: "NONE" for key in string_keys}
    attrs.update({key: False for key in bool_keys})
    response, _ = api_json_or_none("PATCH", f"/ageRatingDeclarations/{app_info_id}", json={
        "data": {"type": "ageRatingDeclarations", "id": app_info_id, "attributes": attrs}
    })
    print(f"Age rating: {response.status_code}")


def update_app_info_localizations(app_info_id):
    response, body = api_json_or_none("GET", f"/appInfos/{app_info_id}/appInfoLocalizations?limit=20")
    if response.status_code != 200:
        return
    for loc in body.get("data", []):
        locale = loc["attributes"].get("locale")
        subtitle = "刺しゅう風ベクター生成" if locale == "ja" else "Floral vector stitch maker"
        response, _ = api_json_or_none("PATCH", f"/appInfoLocalizations/{loc['id']}", json={
            "data": {
                "type": "appInfoLocalizations",
                "id": loc["id"],
                "attributes": {
                    "subtitle": subtitle,
                    "privacyPolicyUrl": "https://snarfnet.github.io/privacy.html",
                },
            }
        })
        print(f"App info {locale}: {response.status_code}")


def ensure_global_price():
    price_point = find_jpy_price_point()
    local_id = "${manualPrice0}"
    payload = {
        "data": {
            "type": "appPriceSchedules",
            "relationships": {
                "app": {"data": {"type": "apps", "id": APP_ID}},
                "baseTerritory": {"data": {"type": "territories", "id": "JPN"}},
                "manualPrices": {"data": [{"type": "appPrices", "id": local_id}]},
            },
        },
        "included": [{
            "type": "appPrices",
            "id": local_id,
            "attributes": {"startDate": "2026-06-21"},
            "relationships": {
                "appPricePoint": {"data": {"type": "appPricePoints", "id": price_point["id"]}}
            },
        }],
    }
    response, _ = api_json_or_none("POST", "/appPriceSchedules", json=payload)
    print(f"Global price JPN {APP_PRICE_JPY}: {response.status_code}")


def find_jpy_price_point():
    points = list_all(
        f"/apps/{APP_ID}/appPricePoints?filter[territory]=JPN&fields[appPricePoints]=customerPrice,proceeds&limit=200"
    )
    best = None
    for point in points:
        raw = point.get("attributes", {}).get("customerPrice")
        if raw is None:
            continue
        value = Decimal(str(raw))
        if value == APP_PRICE_JPY:
            print(f"Price point exact: {point['id']} customerPrice={raw}")
            return point
        distance = abs(value - APP_PRICE_JPY)
        if best is None or distance < best[0]:
            best = (distance, point, value)
    if best:
        print(f"Price point nearest: {best[1]['id']} customerPrice={best[2]}")
        return best[1]
    raise RuntimeError("Could not find a JPN app price point.")


def ensure_global_availability():
    response, body = api_json_or_none("GET", f"/apps/{APP_ID}/appAvailabilityV2")
    if response.status_code == 200:
        count = len(body.get("data", []))
        print(f"Availability records found: {count}. App Store Connect should use all configured territories.")
    else:
        print("Availability API was not updated. Confirm all countries/regions in App Store Connect if review blocks.")


def ensure_review_detail(version_id):
    payload = {
        "data": {
            "type": "appStoreReviewDetails",
            "attributes": {
                "contactFirstName": "Tokyo",
                "contactLastName": "Nasu",
                "contactPhone": "+1 844 209 0611",
                "contactEmail": "support@snarfnet.github.io",
                "demoAccountRequired": False,
                "notes": "No login is required. The app creates embroidery-inspired vector designs and saves files locally through the iOS document picker.",
            },
            "relationships": {
                "appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}}
            },
        }
    }
    response, _ = api_json_or_none("POST", "/appStoreReviewDetails", json=payload)
    print(f"Review detail: {response.status_code}")


def ensure_localizations(version_id):
    localizations = list_all(f"/appStoreVersions/{version_id}/appStoreVersionLocalizations?limit=200")
    existing = {item["attributes"]["locale"]: item for item in localizations}
    for locale in META:
        if locale in existing:
            continue
        response = api("POST", "/appStoreVersionLocalizations", json={
            "data": {
                "type": "appStoreVersionLocalizations",
                "attributes": {"locale": locale},
                "relationships": {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}}},
            }
        })
        if response.status_code == 409 and "DUPLICATE_NAME" in response.text:
            print(f"Localization {locale} skipped because the app name is already used in that storefront.")
            continue
        if response.status_code not in (200, 201):
            raise RuntimeError(
                f"POST /appStoreVersionLocalizations failed {response.status_code}: {response.text[:800]}"
            )
        body = response.json()
        existing[locale] = body["data"]
    return list(existing.values())


def update_metadata(version_id):
    for loc in ensure_localizations(version_id):
        locale = loc["attributes"]["locale"]
        meta = dict(META.get(locale, META["en-US"]))
        response = api("PATCH", f"/appStoreVersionLocalizations/{loc['id']}", json={
            "data": {"type": "appStoreVersionLocalizations", "id": loc["id"], "attributes": meta}
        })
        if response.status_code == 409 and "whatsNew" in meta:
            meta.pop("whatsNew")
            response = api("PATCH", f"/appStoreVersionLocalizations/{loc['id']}", json={
                "data": {"type": "appStoreVersionLocalizations", "id": loc["id"], "attributes": meta}
            })
        print(f"Metadata {locale}: {response.status_code}")


def wait_for_build():
    for index in range(90):
        body = api_json(
            "GET",
            f"/builds?filter[app]={APP_ID}&filter[version]={BUILD_NUMBER}&filter[processingState]=VALID&limit=1",
        )
        if body.get("data"):
            build_id = body["data"][0]["id"]
            print(f"Build ready: {build_id}")
            return build_id
        print(f"Waiting for build processing... {index + 1}/90")
        time.sleep(30)
    raise RuntimeError(f"Build {BUILD_NUMBER} did not finish processing")


def upload_screenshots(version_id):
    for loc in ensure_localizations(version_id):
        locale = loc["attributes"]["locale"]
        print(f"Screenshots for {locale}")
        sets = list_all(f"/appStoreVersionLocalizations/{loc['id']}/appScreenshotSets?limit=200")
        existing = {item["attributes"]["screenshotDisplayType"]: item["id"] for item in sets}
        for display_type, filenames in SCREENSHOT_GROUPS:
            set_id = existing.get(display_type)
            if not set_id:
                body = api_json("POST", "/appScreenshotSets", json={
                    "data": {
                        "type": "appScreenshotSets",
                        "attributes": {"screenshotDisplayType": display_type},
                        "relationships": {
                            "appStoreVersionLocalization": {
                                "data": {"type": "appStoreVersionLocalizations", "id": loc["id"]}
                            }
                        },
                    }
                })
                set_id = body["data"]["id"]
            for screenshot in list_all(f"/appScreenshotSets/{set_id}/appScreenshots?limit=200"):
                api_json_or_none("DELETE", f"/appScreenshots/{screenshot['id']}")
            for filename in filenames:
                upload_screenshot(set_id, filename)


def upload_screenshot(set_id, filename):
    path = SCREENSHOT_DIR / filename
    if not path.exists():
        raise RuntimeError(f"Missing screenshot: {path}")
    data = path.read_bytes()
    checksum = hashlib.md5(data).hexdigest()
    body = api_json("POST", "/appScreenshots", json={
        "data": {
            "type": "appScreenshots",
            "attributes": {"fileName": filename, "fileSize": len(data)},
            "relationships": {"appScreenshotSet": {"data": {"type": "appScreenshotSets", "id": set_id}}},
        }
    })
    screenshot_id = body["data"]["id"]
    for operation in body["data"]["attributes"]["uploadOperations"]:
        request_headers = {item["name"]: item["value"] for item in operation["requestHeaders"]}
        start = operation["offset"]
        end = start + operation["length"]
        upload_binary_part(operation["url"], request_headers, data[start:end])
    response, _ = api_json_or_none("PATCH", f"/appScreenshots/{screenshot_id}", json={
        "data": {
            "type": "appScreenshots",
            "id": screenshot_id,
            "attributes": {"uploaded": True, "sourceFileChecksum": checksum},
        }
    })
    print(f"  {filename}: {response.status_code}")


def upload_binary_part(url, headers, data):
    for attempt in range(1, 6):
        try:
            response = requests.put(url, headers=headers, data=data, timeout=120)
            if response.status_code < 500:
                return response
        except RequestException as error:
            if attempt == 5:
                raise
            print(f"  Upload retry {attempt}/5: {error}")
        time.sleep(5 * attempt)
    return response


def assign_build(version_id, build_id):
    api_json_or_none("PATCH", f"/builds/{build_id}", json={
        "data": {"type": "builds", "id": build_id, "attributes": {"usesNonExemptEncryption": False}}
    })
    response, _ = api_json_or_none("PATCH", f"/appStoreVersions/{version_id}/relationships/build", json={
        "data": {"type": "builds", "id": build_id}
    })
    print(f"Build assigned: {response.status_code}")


def submit_for_review(version_id):
    response = api("POST", "/appStoreVersionSubmissions", json={
        "data": {
            "type": "appStoreVersionSubmissions",
            "relationships": {
                "appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}}
            },
        }
    })
    print(f"App Store version submission: {response.status_code}")
    if response.status_code in (200, 201):
        print(f"Submitted for App Review: {response.json()['data']['id']}")
        return
    raise RuntimeError(f"App Store version submission failed {response.status_code}: {response.text[:1200]}")


def main():
    body = api_json("GET", f"/apps/{APP_ID}")
    print(f"App: {body['data']['attributes'].get('name')}")
    version_id, state = find_or_create_version()
    if state not in ("PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "REJECTED", "METADATA_REJECTED"):
        print(f"Version state is {state}; continuing only if App Store Connect allows updates.")
    ensure_release_prerequisites(version_id)
    update_metadata(version_id)
    upload_screenshots(version_id)
    print("Waiting for screenshot processing...")
    time.sleep(300)
    build_id = wait_for_build()
    assign_build(version_id, build_id)
    submit_for_review(version_id)


if __name__ == "__main__":
    main()
