#!/usr/bin/env python3
import hashlib
import os
import re
import time
from datetime import date
from pathlib import Path

import requests

from asc_helpers import api_json, fail, json_body, make_token, query


APP_ID = os.environ["APP_ID"]
APP_VERSION = os.environ.get("APP_VERSION", "1.0")
BUILD_NUMBER = os.environ["BUILD_NUMBER"]
APP_PRICE_JPY = float(os.environ.get("APP_PRICE_JPY", "300"))
SCREENSHOT_DIR = Path(os.environ.get("SCREENSHOT_DIR", "MarketingAssets/Screenshots"))

SCREENSHOTS = [
    ("APP_IPHONE_67", ["iphone67_01_angle.png"]),
    ("APP_IPAD_PRO_3GEN_129", ["ipad13_01_angle.png"]),
]

META = {
    "ja": {
        "description": (
            "職人スマホSuper DXは、現場で使う角度計、水平器、単位変換、勾配計算、材料計算、"
            "測定メモ、写真注釈、PDF出力をまとめた道具箱アプリです。\n\n"
            "測定値はワンタップで保存。現場名、タグ、メモを付けて履歴検索できます。"
            "写真には角度、水平OK、矢印、丸印を重ねられます。施工前後の確認や、元請け・施主への説明にも使いやすい形です。\n\n"
            "主な機能\n"
            "・角度計、2軸水平器、ゼロ補正\n"
            "・OK / NG 自動判定しきい値\n"
            "・角度、勾配、坪、平米、畳などの変換\n"
            "・材料数量とロス込み数量の計算\n"
            "・現場チェックリスト、テンプレート\n"
            "・測定履歴、PDFレポート、QR共有\n"
            "・中心線ガイド、写真注釈、音声メモ\n\n"
            "データは端末内に保存します。広告やトラッキングはありません。"
        ),
        "keywords": "角度計,水平器,勾配,現場,施工,職人,材料計算,チェックリスト,PDF,測定",
        "whatsNew": "初回リリースです。",
        "promotionalText": "角度、水平、材料、写真、PDFまで。現場で測って残せる職人向け道具箱。",
        "marketingUrl": "https://snarfnet.github.io/",
        "supportUrl": "https://snarfnet.github.io/",
    }
}


def headers():
    return {"Authorization": f"Bearer {make_token()}", "Content-Type": "application/json"}


def response_json(method, path, **kwargs):
    for attempt in range(6):
        response = requests.request(
            method,
            f"https://api.appstoreconnect.apple.com/v1{path}",
            headers=headers(),
            timeout=120,
            **kwargs,
        )
        if response.status_code not in (401, 429, 500, 502, 503, 504):
            break
        time.sleep(20)
    try:
        body = response.json()
    except Exception:
        body = {}
    return response, body


def list_all(path):
    rows = []
    next_path = path
    while next_path:
        body = api_json("GET", next_path)
        rows.extend(body.get("data", []))
        next_url = body.get("links", {}).get("next")
        next_path = next_url.split("/v1", 1)[1] if next_url else None
    return rows


def find_or_create_version():
    versions = list_all(f"/apps/{APP_ID}/appStoreVersions?{query({'filter[platform]': 'IOS', 'limit': '200'})}")
    for version in versions:
        attrs = version.get("attributes", {})
        if attrs.get("versionString") == APP_VERSION:
            print(f"Found version {APP_VERSION}: {version['id']} state={attrs.get('appStoreState')}")
            return version["id"]

    payload = {
        "data": {
            "type": "appStoreVersions",
            "attributes": {"platform": "IOS", "versionString": APP_VERSION},
            "relationships": {"app": {"data": {"type": "apps", "id": APP_ID}}},
        }
    }
    body = api_json("POST", "/appStoreVersions", data=json_body(payload))
    return body["data"]["id"]


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
        body = api_json("POST", "/appStoreVersionLocalizations", data=json_body(payload))
        existing[locale] = body["data"]
    return list(existing.values())


def update_metadata(version_id):
    for loc in ensure_localizations(version_id):
        locale = loc["attributes"]["locale"]
        meta = META.get(locale, META["ja"])
        payload = {"data": {"type": "appStoreVersionLocalizations", "id": loc["id"], "attributes": meta}}
        response, _ = response_json("PATCH", f"/appStoreVersionLocalizations/{loc['id']}", json=payload)
        if response.status_code == 409:
            attrs = {key: value for key, value in meta.items() if key != "whatsNew"}
            payload["data"]["attributes"] = attrs
            response, _ = response_json("PATCH", f"/appStoreVersionLocalizations/{loc['id']}", json=payload)
        print(f"Metadata {locale}: {response.status_code}")


def update_app_info():
    response, body = response_json("GET", f"/apps/{APP_ID}/appInfos?limit=10")
    if response.status_code != 200 or not body.get("data"):
        print(f"App info skipped: {response.status_code}")
        return
    app_info_id = body["data"][0]["id"]
    payload = {
        "data": {
            "type": "appInfos",
            "id": app_info_id,
            "relationships": {"primaryCategory": {"data": {"type": "appCategories", "id": "UTILITIES"}}},
        }
    }
    response, _ = response_json("PATCH", f"/appInfos/{app_info_id}", json=payload)
    print(f"Primary category: {response.status_code}")
    update_age_rating(app_info_id)
    update_app_info_localizations(app_info_id)


def update_app_info_localizations(app_info_id):
    response, body = response_json("GET", f"/appInfos/{app_info_id}/appInfoLocalizations?limit=50")
    if response.status_code != 200:
        return
    for loc in body.get("data", []):
        payload = {
            "data": {
                "type": "appInfoLocalizations",
                "id": loc["id"],
                "attributes": {
                    "name": "職人スマホSuper DX",
                    "subtitle": "角度・水平・現場メモを一括管理",
                    "privacyPolicyUrl": "https://snarfnet.github.io/privacy.html",
                },
            }
        }
        response, _ = response_json("PATCH", f"/appInfoLocalizations/{loc['id']}", json=payload)
        print(f"App info {loc['attributes'].get('locale')}: {response.status_code}")


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
    payload = {"data": {"type": "ageRatingDeclarations", "id": app_info_id, "attributes": attrs}}
    response, _ = response_json("PATCH", f"/ageRatingDeclarations/{app_info_id}", json=payload)
    print(f"Age rating: {response.status_code}")


def ensure_release_prerequisites(version_id):
    response, _ = response_json("PATCH", f"/apps/{APP_ID}", json={
        "data": {
            "type": "apps",
            "id": APP_ID,
            "attributes": {"contentRightsDeclaration": "DOES_NOT_USE_THIRD_PARTY_CONTENT"},
        }
    })
    print(f"Content rights: {response.status_code}")
    update_app_info()
    response, _ = response_json("PATCH", f"/appStoreVersions/{version_id}", json={
        "data": {
            "type": "appStoreVersions",
            "id": version_id,
            "attributes": {"copyright": "2026 Tokyo Nasu", "usesIdfa": False},
        }
    })
    print(f"Version attributes: {response.status_code}")
    ensure_price()
    ensure_no_data_collected()
    ensure_review_detail(version_id)


def ensure_price():
    points = list_all(f"/apps/{APP_ID}/appPricePoints?filter[territory]=JPN&limit=200")
    if not points:
        print("Price skipped: no JPN price points")
        return

    def value(point):
        attrs = point.get("attributes", {})
        for key in ("customerPrice", "price"):
            try:
                return float(attrs.get(key))
            except Exception:
                pass
        return 10**9

    price_point = min(points, key=lambda item: abs(value(item) - APP_PRICE_JPY))
    print(f"Selected JPN price point: {price_point['id']} customerPrice={value(price_point)}")
    payload = {
        "data": {
            "type": "appPriceSchedules",
            "relationships": {
                "app": {"data": {"type": "apps", "id": APP_ID}},
                "baseTerritory": {"data": {"type": "territories", "id": "JPN"}},
                "manualPrices": {"data": [{"type": "appPrices", "id": "${manualPrice0}"}]},
            },
        },
        "included": [{
            "type": "appPrices",
            "id": "${manualPrice0}",
            "attributes": {"startDate": date.today().isoformat()},
            "relationships": {"appPricePoint": {"data": {"type": "appPricePoints", "id": price_point["id"]}}},
        }],
    }
    response, _ = response_json("POST", "/appPriceSchedules", json=payload)
    print(f"Price schedule: {response.status_code}")


def ensure_no_data_collected():
    response, body = response_json("GET", f"/apps/{APP_ID}/dataUsages?include=category,grouping,purpose,dataProtection&limit=500")
    if response.status_code == 200:
        for usage in body.get("data", []):
            delete_response, _ = response_json("DELETE", f"/appDataUsages/{usage['id']}")
            print(f"Delete app data usage {usage['id']}: {delete_response.status_code}")
    payload = {
        "data": {
            "type": "appDataUsages",
            "relationships": {
                "app": {"data": {"type": "apps", "id": APP_ID}},
                "dataProtection": {"data": {"type": "appDataUsageDataProtections", "id": "DATA_NOT_COLLECTED"}},
            },
        }
    }
    response, _ = response_json("POST", "/appDataUsages", json=payload)
    print(f"No data collected usage: {response.status_code}")
    response, body = response_json("GET", f"/apps/{APP_ID}/dataUsagePublishState")
    if response.status_code == 200 and body.get("data"):
        state_id = body["data"]["id"]
        payload = {
            "data": {
                "type": "appDataUsagesPublishState",
                "id": state_id,
                "attributes": {"published": True},
            }
        }
        response, _ = response_json("PATCH", f"/appDataUsagesPublishState/{state_id}", json=payload)
        print(f"App data usage publish: {response.status_code}")


def ensure_review_detail(version_id):
    attrs = {
        "contactFirstName": "Tokyo",
        "contactLastName": "Nasu",
        "contactPhone": "+1 844 209 0611",
        "contactEmail": "tokyonasu@yahoo.co.jp",
        "demoAccountRequired": False,
        "notes": "ログイン不要です。広告、外部通信、トラッキングはありません。写真、音声入力、測定メモは端末内で扱います。",
    }
    response, body = response_json("GET", f"/appStoreVersions/{version_id}/appStoreReviewDetail")
    if response.status_code == 200 and body.get("data"):
        detail_id = body["data"]["id"]
        payload = {"data": {"type": "appStoreReviewDetails", "id": detail_id, "attributes": attrs}}
        response, _ = response_json("PATCH", f"/appStoreReviewDetails/{detail_id}", json=payload)
        print(f"Review detail update: {response.status_code}")
        return
    payload = {
        "data": {
            "type": "appStoreReviewDetails",
            "attributes": attrs,
            "relationships": {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}}},
        }
    }
    response, _ = response_json("POST", "/appStoreReviewDetails", json=payload)
    print(f"Review detail create: {response.status_code}")


def wait_for_build():
    for index in range(60):
        response, body = response_json(
            "GET",
            f"/builds?filter[app]={APP_ID}&filter[version]={BUILD_NUMBER}&filter[processingState]=VALID&limit=1",
        )
        if body.get("data"):
            build_id = body["data"][0]["id"]
            print(f"Build ready: {build_id}")
            return build_id
        print(f"Waiting for build {BUILD_NUMBER}... {index + 1}/60")
        time.sleep(30)
    raise RuntimeError(f"Build {BUILD_NUMBER} did not finish processing.")


def upload_screenshots(version_id):
    for loc in ensure_localizations(version_id):
        print(f"Screenshots for {loc['attributes']['locale']}")
        sets = list_all(f"/appStoreVersionLocalizations/{loc['id']}/appScreenshotSets?limit=200")
        existing = {item["attributes"]["screenshotDisplayType"]: item["id"] for item in sets}
        for display_type, filenames in SCREENSHOTS:
            set_id = existing.get(display_type)
            if not set_id:
                payload = {
                    "data": {
                        "type": "appScreenshotSets",
                        "attributes": {"screenshotDisplayType": display_type},
                        "relationships": {
                            "appStoreVersionLocalization": {"data": {"type": "appStoreVersionLocalizations", "id": loc["id"]}}
                        },
                    }
                }
                body = api_json("POST", "/appScreenshotSets", data=json_body(payload))
                set_id = body["data"]["id"]
            for screenshot in list_all(f"/appScreenshotSets/{set_id}/appScreenshots?limit=200"):
                response, _ = response_json("DELETE", f"/appScreenshots/{screenshot['id']}")
                print(f"  delete screenshot {screenshot['id']}: {response.status_code}")
            for filename in filenames:
                upload_screenshot(set_id, filename)


def upload_screenshot(set_id, filename):
    path = SCREENSHOT_DIR / filename
    if not path.exists():
        raise RuntimeError(f"Missing screenshot: {path}")
    data = path.read_bytes()
    checksum = hashlib.md5(data).hexdigest()
    response, body = response_json("POST", "/appScreenshots", json={
        "data": {
            "type": "appScreenshots",
            "attributes": {"fileName": filename, "fileSize": len(data)},
            "relationships": {"appScreenshotSet": {"data": {"type": "appScreenshotSets", "id": set_id}}},
        }
    })
    if response.status_code not in (200, 201):
        raise RuntimeError(f"Screenshot create failed {response.status_code}: {response.text[:500]}")
    screenshot_id = body["data"]["id"]
    for operation in body["data"]["attributes"]["uploadOperations"]:
        upload_headers = {item["name"]: item["value"] for item in operation["requestHeaders"]}
        start = operation["offset"]
        end = start + operation["length"]
        requests.put(operation["url"], headers=upload_headers, data=data[start:end], timeout=120)
    for attempt in range(1, 7):
        response, _ = response_json("PATCH", f"/appScreenshots/{screenshot_id}", json={
            "data": {
                "type": "appScreenshots",
                "id": screenshot_id,
                "attributes": {"uploaded": True, "sourceFileChecksum": checksum},
            }
        })
        if response.status_code in (200, 201):
            print(f"  {filename}: {response.status_code}")
            return
        print(f"  {filename}: retry {attempt}/6 status={response.status_code}")
        time.sleep(20)
    raise RuntimeError(f"Screenshot upload confirm failed: {filename}")


def assign_build(version_id, build_id):
    response, _ = response_json("PATCH", f"/builds/{build_id}", json={
        "data": {"type": "builds", "id": build_id, "attributes": {"usesNonExemptEncryption": False}}
    })
    print(f"Build encryption: {response.status_code}")
    response, _ = response_json("PATCH", f"/appStoreVersions/{version_id}/relationships/build", json={
        "data": {"type": "builds", "id": build_id}
    })
    print(f"Build assigned: {response.status_code}")


def cancel_open_review_submissions():
    response, body = response_json("GET", f"/apps/{APP_ID}/reviewSubmissions?limit=20")
    if response.status_code != 200:
        return
    for submission in body.get("data", []):
        state = submission.get("attributes", {}).get("state")
        if state in ("UNRESOLVED_ISSUES", "WAITING_FOR_REVIEW"):
            response, _ = response_json("PATCH", f"/reviewSubmissions/{submission['id']}", json={
                "data": {
                    "type": "reviewSubmissions",
                    "id": submission["id"],
                    "attributes": {"canceled": True},
                }
            })
            print(f"Canceled review submission {submission['id']}: {response.status_code}")
            for attempt in range(12):
                response, detail = response_json("GET", f"/reviewSubmissions/{submission['id']}")
                current_state = detail.get("data", {}).get("attributes", {}).get("state")
                if current_state == "COMPLETE":
                    break
                print(f"Waiting for review cancellation {attempt + 1}/12: {current_state}")
                time.sleep(10)


def ready_review_submission_id():
    response, body = response_json("GET", f"/apps/{APP_ID}/reviewSubmissions?limit=20")
    if response.status_code != 200:
        return None
    for submission in body.get("data", []):
        if submission.get("attributes", {}).get("state") == "READY_FOR_REVIEW":
            return submission["id"]
    return None


def finish_review_submission(submission_id):
    for attempt in range(1, 31):
        response, body = response_json("PATCH", f"/reviewSubmissions/{submission_id}", json={
            "data": {"type": "reviewSubmissions", "id": submission_id, "attributes": {"submitted": True}}
        })
        if response.status_code == 200:
            print(f"Submitted for App Review: {body['data']['attributes']['state']}")
            return
        print(f"Review submit {attempt}/30: {response.status_code}")
        print(response.text[:1000])
        time.sleep(60)
    raise RuntimeError(f"Review submit failed: {response.status_code} {response.text[:1000]}")


def submit_for_review(version_id):
    cancel_open_review_submissions()
    submission_id = ready_review_submission_id()
    if submission_id:
        print(f"Using ready review submission: {submission_id}")
    else:
        response, body = response_json("POST", "/reviewSubmissions", json={
            "data": {
                "type": "reviewSubmissions",
                "attributes": {"platform": "IOS"},
                "relationships": {"app": {"data": {"type": "apps", "id": APP_ID}}},
            }
        })
        if response.status_code not in (200, 201):
            raise RuntimeError(f"Review submission create failed {response.status_code}: {response.text[:2000]}")
        submission_id = body["data"]["id"]

    for attempt in range(1, 21):
        response, _ = response_json("POST", "/reviewSubmissionItems", json={
            "data": {
                "type": "reviewSubmissionItems",
                "relationships": {
                    "reviewSubmission": {"data": {"type": "reviewSubmissions", "id": submission_id}},
                    "appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}},
                },
            }
        })
        print(f"Review item {attempt}/20: {response.status_code}")
        if response.status_code == 201:
            break
        if response.status_code == 409:
            if "SCREENSHOT_UPLOADS_IN_PROGRESS" in response.text:
                print("Screenshots are still processing. Waiting before retry.")
                time.sleep(60)
                continue
            if "ITEM_PART_OF_ANOTHER_SUBMISSION" in response.text:
                match = re.search(r"reviewSubmission with id ([0-9a-f-]+)", response.text)
                if match:
                    finish_review_submission(match.group(1))
                    return
            raise RuntimeError(f"Review item blocked: {response.text[:4000]}")
        if response.status_code not in (200, 201):
            raise RuntimeError(f"Review item failed {response.status_code}: {response.text[:1000]}")
        time.sleep(30)
    else:
        raise RuntimeError(f"Review item failed after retries: {response.status_code} {response.text[:1000]}")

    finish_review_submission(submission_id)


def main():
    response, body = response_json("GET", f"/apps/{APP_ID}")
    if response.status_code != 200:
        raise RuntimeError(f"App lookup failed {response.status_code}: {response.text[:500]}")
    attrs = body["data"]["attributes"]
    print(f"App: {attrs.get('name')} / {attrs.get('bundleId')}")
    version_id = find_or_create_version()
    ensure_release_prerequisites(version_id)
    update_metadata(version_id)
    build_id = wait_for_build()
    upload_screenshots(version_id)
    print("Waiting for screenshot processing...")
    time.sleep(90)
    assign_build(version_id, build_id)
    submit_for_review(version_id)


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        fail(error)
