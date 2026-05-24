#!/usr/bin/env python3
import hashlib
import os
import re
import sys
import time

from asc_helpers import api, api_json, json_body, query


APP_ID = os.environ.get("MORIMORI_PHOTO_MAKER_APP_ID") or os.environ.get("APP_ID")
BUNDLE_ID = os.environ.get("APP_BUNDLE_ID", "com.tokyonasu.morimoriphotomaker")
APP_VERSION = os.environ.get("APP_VERSION", "1.0")
BUILD_NUMBER = os.environ.get("BUILD_NUMBER")
SCREENSHOT_DIR = "MarketingAssets/Screenshots"

SCREENSHOT_GROUPS = [
    ("APP_IPHONE_67", ["iphone67_01.png", "iphone67_02.png", "iphone67_03.png"]),
    ("APP_IPAD_PRO_3GEN_129", ["ipad129_01.png", "ipad129_02.png", "ipad129_03.png"]),
]

META = {
    "ja": {
        "description": """盛り盛りフォトメーカーは、写真に髪型、メイク、メガネ、ネイル、感情スタンプ、小物を重ねて遊べる写真デコアプリです。

写真を選んだら、好きなカテゴリーから素材をタップするだけ。位置、大きさ、回転、透明度を調整して、自分だけの盛り盛り画像を作れます。

無料素材に加えて、韓国風、姫盛り、昭和バブル、ヤンキー、ネイル、感情素材などのパックも用意しています。単品パックで必要な素材だけ追加したり、月額サブスクでロック素材をまとめて使ったりできます。

作った画像は写真アプリに保存できます。SNS用のプロフィール画像、友だちへのネタ画像、イベント前の盛り加工にどうぞ。""",
        "keywords": "写真加工,デコ,盛り,メイク,髪型,メガネ,ネイル,スタンプ,かわいい,サブスク",
        "whatsNew": "初回リリースです。",
        "promotionalText": "写真にメイク、髪型、メガネ、ネイルを重ねて、かわいく盛れる写真デコアプリ。",
        "marketingUrl": "https://snarfnet.github.io/",
        "supportUrl": "https://snarfnet.github.io/",
    },
    "en-US": {
        "description": """Morimori Photo Maker is a cute photo decoration app for layering hairstyles, makeup, glasses, nails, emotion stickers, and accessories onto your photos.

Pick a photo, tap a decoration, then adjust position, scale, rotation, and opacity. Create a playful edited image for your album, profile, or social posts.

Use free items, buy individual themed packs, or subscribe monthly to unlock all locked items.""",
        "keywords": "photo,decoration,makeup,hair,glasses,nails,stickers,kawaii,selfie,editor",
        "whatsNew": "Initial release.",
        "promotionalText": "Decorate photos with cute makeup, hair, glasses, nails, and stickers.",
        "marketingUrl": "https://snarfnet.github.io/",
        "supportUrl": "https://snarfnet.github.io/",
    },
}


def list_all(path):
    rows = []
    next_path = path
    while next_path:
        body = api_json("GET", next_path)
        rows.extend(body.get("data", []))
        next_url = body.get("links", {}).get("next")
        next_path = next_url.split("/v1", 1)[1] if next_url else None
    return rows


def find_app_id():
    if APP_ID:
        return APP_ID
    body = api_json("GET", f"/apps?{query({'filter[bundleId]': BUNDLE_ID, 'limit': '1'})}")
    data = body.get("data", [])
    if not data:
        raise RuntimeError(f"App not found for bundle ID: {BUNDLE_ID}")
    return data[0]["id"]


def find_or_create_version(app_id):
    for version in list_all(f"/apps/{app_id}/appStoreVersions?filter[platform]=IOS&limit=200"):
        attrs = version.get("attributes", {})
        if attrs.get("versionString") == APP_VERSION:
            print(f"Found iOS version {APP_VERSION}: {version['id']} state={attrs.get('appStoreState')}")
            return version["id"]

    payload = {
        "data": {
            "type": "appStoreVersions",
            "attributes": {"platform": "IOS", "versionString": APP_VERSION},
            "relationships": {"app": {"data": {"type": "apps", "id": app_id}}},
        }
    }
    version = api_json("POST", "/appStoreVersions", data=json_body(payload))["data"]
    return version["id"]


def ensure_localizations(version_id):
    localizations = list_all(f"/appStoreVersions/{version_id}/appStoreVersionLocalizations?limit=200")
    existing = {item["attributes"]["locale"]: item for item in localizations}
    for locale in META:
        if locale in existing:
            continue
        payload = {
            "data": {
                "type": "appStoreVersionLocalizations",
                "attributes": {"locale": locale},
                "relationships": {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}}},
            }
        }
        item = api_json("POST", "/appStoreVersionLocalizations", data=json_body(payload))["data"]
        existing[locale] = item
    return list(existing.values())


def update_metadata(version_id):
    for loc in ensure_localizations(version_id):
        locale = loc["attributes"]["locale"]
        meta = META.get(locale, META["en-US"])
        payload = {
            "data": {
                "type": "appStoreVersionLocalizations",
                "id": loc["id"],
                "attributes": meta,
            }
        }
        response = api("PATCH", f"/appStoreVersionLocalizations/{loc['id']}", data=json_body(payload))
        if response.status_code == 409 and "whatsNew" in meta:
            meta = {key: value for key, value in meta.items() if key != "whatsNew"}
            payload["data"]["attributes"] = meta
            response = api("PATCH", f"/appStoreVersionLocalizations/{loc['id']}", data=json_body(payload))
        print(f"Metadata {locale}: {response.status_code}")


def ensure_release_prerequisites(app_id, version_id):
    response = api("PATCH", f"/apps/{app_id}", data=json_body({
        "data": {
            "type": "apps",
            "id": app_id,
            "attributes": {"contentRightsDeclaration": "DOES_NOT_USE_THIRD_PARTY_CONTENT"},
        }
    }))
    print(f"Content rights: {response.status_code}")

    infos = list_all(f"/apps/{app_id}/appInfos?limit=10")
    if infos:
        app_info_id = infos[0]["id"]
        response = api("PATCH", f"/appInfos/{app_info_id}", data=json_body({
            "data": {
                "type": "appInfos",
                "id": app_info_id,
                "relationships": {
                    "primaryCategory": {"data": {"type": "appCategories", "id": "PHOTO_AND_VIDEO"}}
                },
            }
        }))
        print(f"Primary category: {response.status_code}")
        update_age_rating(app_info_id)
        update_app_info_localizations(app_info_id)

    response = api("PATCH", f"/appStoreVersions/{version_id}", data=json_body({
        "data": {
            "type": "appStoreVersions",
            "id": version_id,
            "attributes": {"copyright": "2026 Tokyo Nasu", "usesIdfa": False},
        }
    }))
    print(f"Version attributes: {response.status_code}")
    ensure_free_price(app_id)
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
        "lootBox",
    ]
    attrs = {key: "NONE" for key in string_keys}
    attrs.update({key: False for key in bool_keys})
    attrs["advertising"] = False
    attrs["unrestrictedWebAccess"] = False
    response = api("PATCH", f"/ageRatingDeclarations/{app_info_id}", data=json_body({
        "data": {"type": "ageRatingDeclarations", "id": app_info_id, "attributes": attrs}
    }))
    print(f"Age rating: {response.status_code}")


def update_app_info_localizations(app_info_id):
    localizations = list_all(f"/appInfos/{app_info_id}/appInfoLocalizations?limit=20")
    for loc in localizations:
        locale = loc["attributes"].get("locale")
        subtitle = "写真をかわいく盛れるデコアプリ" if locale == "ja" else "Cute photo decoration"
        response = api("PATCH", f"/appInfoLocalizations/{loc['id']}", data=json_body({
            "data": {
                "type": "appInfoLocalizations",
                "id": loc["id"],
                "attributes": {
                    "subtitle": subtitle,
                    "privacyPolicyUrl": "https://snarfnet.github.io/privacy.html",
                },
            }
        }))
        print(f"App info {locale}: {response.status_code}")


def ensure_free_price(app_id):
    response = api("GET", f"/apps/{app_id}/relationships/appPriceSchedule")
    body = response.json() if response.text else {}
    if response.status_code == 200 and body.get("data"):
        schedule_id = body["data"]["id"]
        response = api(
            "GET",
            f"/appPriceSchedules/{schedule_id}/manualPrices"
            "?limit=200&include=appPricePoint,territory"
            "&fields[appPricePoints]=customerPrice"
            "&filter[territory]=JPN",
        )
        body = response.json() if response.text else {}
        if response.status_code == 200:
            price_points = {
                item["id"]: item.get("attributes", {}).get("customerPrice")
                for item in body.get("included", [])
                if item.get("type") == "appPricePoints"
            }
            for item in body.get("data", []):
                attrs = item.get("attributes", {})
                point_id = item.get("relationships", {}).get("appPricePoint", {}).get("data", {}).get("id")
                if attrs.get("endDate") is None and str(price_points.get(point_id)) in ("0", "0.0", "0.00"):
                    print("Free price: already set")
                    return

    body = api_json(
        "GET",
        f"/apps/{app_id}/appPricePoints?filter[territory]=JPN&fields[appPricePoints]=customerPrice&limit=200",
    )
    price_id = None
    for point in body.get("data", []):
        if str(point.get("attributes", {}).get("customerPrice")) in ("0", "0.0", "0.00"):
            price_id = point["id"]
            break
    if not price_id:
        print("Free price: skipped")
        return

    local_id = "${manualPrice0}"
    payload = {
        "data": {
            "type": "appPriceSchedules",
            "attributes": {},
            "relationships": {
                "app": {"data": {"type": "apps", "id": app_id}},
                "baseTerritory": {"data": {"type": "territories", "id": "JPN"}},
                "manualPrices": {"data": [{"type": "appPrices", "id": local_id}]},
            },
        },
        "included": [{
            "type": "appPrices",
            "id": local_id,
            "attributes": {"startDate": None},
            "relationships": {
                "appPricePoint": {"data": {"type": "appPricePoints", "id": price_id}}
            },
        }],
    }
    response = api("POST", "/appPriceSchedules", data=json_body(payload))
    print(f"Free price: {response.status_code}")
    if response.status_code not in (200, 201, 409):
        print(response.text[:1000])


def ensure_review_detail(version_id):
    attrs = {
        "contactFirstName": "Tokyo",
        "contactLastName": "Nasu",
        "contactPhone": "+1 844 209 0611",
        "contactEmail": "support@snarfnet.github.io",
        "demoAccountRequired": False,
        "notes": "ログイン不要です。写真は端末内で処理します。アプリ内課金はStoreKitで単品パック購入と月額サブスクに対応しています。",
    }
    response = api("GET", f"/appStoreVersions/{version_id}/appStoreReviewDetail")
    body = response.json() if response.text else {}
    if response.status_code == 200 and body.get("data"):
        detail_id = body["data"]["id"]
        response = api("PATCH", f"/appStoreReviewDetails/{detail_id}", data=json_body({
            "data": {"type": "appStoreReviewDetails", "id": detail_id, "attributes": attrs}
        }))
        print(f"Review detail update: {response.status_code}")
        return
    response = api("POST", "/appStoreReviewDetails", data=json_body({
        "data": {
            "type": "appStoreReviewDetails",
            "attributes": attrs,
            "relationships": {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}}},
        }
    }))
    print(f"Review detail create: {response.status_code}")


def wait_for_build(app_id):
    if not BUILD_NUMBER:
        raise RuntimeError("BUILD_NUMBER is required.")
    for index in range(90):
        body = api_json(
            "GET",
            f"/builds?filter[app]={app_id}&filter[version]={BUILD_NUMBER}&filter[processingState]=VALID&limit=1",
        )
        if body.get("data"):
            build_id = body["data"][0]["id"]
            print(f"Build ready: {build_id}")
            return build_id
        print(f"Waiting for build processing... {index + 1}/90")
        time.sleep(30)
    raise RuntimeError(f"Build {BUILD_NUMBER} did not finish processing.")


def upload_screenshots(version_id):
    for loc in ensure_localizations(version_id):
        print(f"Screenshots for {loc['attributes']['locale']}")
        sets = list_all(f"/appStoreVersionLocalizations/{loc['id']}/appScreenshotSets?limit=200")
        existing = {item["attributes"]["screenshotDisplayType"]: item["id"] for item in sets}
        for display_type, filenames in SCREENSHOT_GROUPS:
            set_id = existing.get(display_type)
            if not set_id:
                payload = {
                    "data": {
                        "type": "appScreenshotSets",
                        "attributes": {"screenshotDisplayType": display_type},
                        "relationships": {
                            "appStoreVersionLocalization": {
                                "data": {"type": "appStoreVersionLocalizations", "id": loc["id"]}
                            }
                        },
                    }
                }
                set_id = api_json("POST", "/appScreenshotSets", data=json_body(payload))["data"]["id"]
            for screenshot in list_all(f"/appScreenshotSets/{set_id}/appScreenshots?limit=200"):
                api("DELETE", f"/appScreenshots/{screenshot['id']}")
            for filename in filenames:
                upload_screenshot(set_id, filename)


def upload_screenshot(set_id, filename):
    path = os.path.join(SCREENSHOT_DIR, filename)
    if not os.path.exists(path):
        raise RuntimeError(f"Missing screenshot: {path}")
    data = open(path, "rb").read()
    checksum = hashlib.md5(data).hexdigest()
    body = api_json("POST", "/appScreenshots", data=json_body({
        "data": {
            "type": "appScreenshots",
            "attributes": {"fileName": filename, "fileSize": len(data)},
            "relationships": {"appScreenshotSet": {"data": {"type": "appScreenshotSets", "id": set_id}}},
        }
    }))
    screenshot_id = body["data"]["id"]
    for operation in body["data"]["attributes"]["uploadOperations"]:
        request_headers = {item["name"]: item["value"] for item in operation["requestHeaders"]}
        start = operation["offset"]
        end = start + operation["length"]
        import requests
        requests.put(operation["url"], headers=request_headers, data=data[start:end], timeout=120)
    for attempt in range(1, 7):
        response = api("PATCH", f"/appScreenshots/{screenshot_id}", data=json_body({
            "data": {
                "type": "appScreenshots",
                "id": screenshot_id,
                "attributes": {"uploaded": True, "sourceFileChecksum": checksum},
            }
        }))
        if response.status_code in (200, 201):
            break
        print(f"  {filename}: upload confirm retry {attempt}/6 status={response.status_code}")
        time.sleep(20)
    print(f"  {filename}: {response.status_code}")


def assign_build(version_id, build_id):
    api("PATCH", f"/builds/{build_id}", data=json_body({
        "data": {"type": "builds", "id": build_id, "attributes": {"usesNonExemptEncryption": False}}
    }))
    response = api("PATCH", f"/appStoreVersions/{version_id}/relationships/build", data=json_body({
        "data": {"type": "builds", "id": build_id}
    }))
    print(f"Build assigned: {response.status_code}")


def cancel_open_review_submissions(app_id):
    body = api_json("GET", f"/apps/{app_id}/reviewSubmissions?limit=20")
    for submission in body.get("data", []):
        state = submission.get("attributes", {}).get("state")
        if state in ("UNRESOLVED_ISSUES", "WAITING_FOR_REVIEW"):
            response = api("PATCH", f"/reviewSubmissions/{submission['id']}", data=json_body({
                "data": {
                    "type": "reviewSubmissions",
                    "id": submission["id"],
                    "attributes": {"canceled": True},
                }
            }))
            print(f"Canceled review submission {submission['id']}: {response.status_code}")


def ready_review_submission_id(app_id):
    body = api_json("GET", f"/apps/{app_id}/reviewSubmissions?limit=20")
    for submission in body.get("data", []):
        if submission.get("attributes", {}).get("state") == "READY_FOR_REVIEW":
            return submission["id"]
    return None


def submit_for_review(app_id, version_id):
    cancel_open_review_submissions(app_id)
    submission_id = ready_review_submission_id(app_id)
    if not submission_id:
        submission_id = api_json("POST", "/reviewSubmissions", data=json_body({
            "data": {
                "type": "reviewSubmissions",
                "attributes": {"platform": "IOS"},
                "relationships": {"app": {"data": {"type": "apps", "id": app_id}}},
            }
        }))["data"]["id"]

    for attempt in range(20):
        response = api("POST", "/reviewSubmissionItems", data=json_body({
            "data": {
                "type": "reviewSubmissionItems",
                "relationships": {
                    "reviewSubmission": {"data": {"type": "reviewSubmissions", "id": submission_id}},
                    "appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}},
                },
            }
        }))
        print(f"Review item {attempt + 1}/20: {response.status_code}")
        if response.status_code == 201:
            break
        if response.status_code == 409 and "SCREENSHOT_UPLOADS_IN_PROGRESS" in response.text:
            time.sleep(60)
            continue
        if response.status_code == 409 and "ITEM_PART_OF_ANOTHER_SUBMISSION" in response.text:
            match = re.search(r"reviewSubmission with id ([0-9a-f-]+)", response.text)
            if match:
                submission_id = match.group(1)
                break
        if response.status_code != 409:
            time.sleep(30)
            continue
        raise RuntimeError(f"Review item blocked: {response.text[:4000]}")

    for attempt in range(1, 31):
        response = api("PATCH", f"/reviewSubmissions/{submission_id}", data=json_body({
            "data": {"type": "reviewSubmissions", "id": submission_id, "attributes": {"submitted": True}}
        }))
        if response.status_code == 200:
            print("Submitted for App Review.")
            return
        print(f"Review submit {attempt}/30: {response.status_code}")
        time.sleep(60)
    raise RuntimeError(f"Review submit failed: {response.status_code} {response.text[:500]}")


def main():
    app_id = find_app_id()
    version_id = find_or_create_version(app_id)
    ensure_release_prerequisites(app_id, version_id)
    update_metadata(version_id)
    if os.environ.get("PREPARE_APP_ONLY") == "1":
        print("App Store Connect metadata is ready.")
        return

    build_id = wait_for_build(app_id)
    upload_screenshots(version_id)
    print("Waiting for screenshot processing...")
    time.sleep(300)
    assign_build(version_id, build_id)
    submit_for_review(app_id, version_id)


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        print(str(error), file=sys.stderr)
        sys.exit(1)
