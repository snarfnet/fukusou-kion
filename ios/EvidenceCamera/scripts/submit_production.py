#!/usr/bin/env python3
import hashlib
import os
import re
import time
from datetime import date
from pathlib import Path

import requests
from PIL import Image, ImageDraw, ImageFont

from asc_helpers import api_json, fail, json_body, make_token, query


APP_ID = os.environ.get("APP_ID", "6779596726")
APP_VERSION = os.environ.get("APP_VERSION", "1.0")
BUILD_NUMBER = os.environ.get("BUILD_NUMBER", "107")
APP_PRICE_JPY = float(os.environ.get("APP_PRICE_JPY", "200"))
SUBMIT_REVIEW = os.environ.get("SUBMIT_REVIEW", "true").lower() == "true"
SCREENSHOT_DIR = Path(os.environ.get("SCREENSHOT_DIR", "MarketingAssets/Screenshots"))

SCREENSHOTS = [
    ("APP_IPHONE_67", [("iphone67_01_proof.png", (1290, 2796))]),
    ("APP_IPAD_PRO_3GEN_129", [("ipad129_01_proof.png", (2048, 2732))]),
]

META = {
    "ja": {
        "description": (
            "証拠カメラ 現場記録は、撮影した写真に日時、位置情報、住所、方角、端末の傾き、"
            "改ざん防止ハッシュ、連続撮影ログを記録するカメラアプリです。\n\n"
            "撮影した写真はアプリ内と写真アプリに保存されます。あとから写真を読み込み、"
            "証拠データを確認できます。\n\n"
            "置き配、清掃報告、工事報告、駐車違反記録、店舗巡回、マンション管理、"
            "交通量調査など、現場の記録を残したい場面で使えます。\n\n"
            "主な機能\n"
            "・日時、位置情報、住所の記録\n"
            "・方角と端末の傾きの記録\n"
            "・改ざん防止ハッシュの保存\n"
            "・連続撮影ログの保存\n"
            "・メモ付きの証拠写真\n"
            "・写真アプリへの自動保存\n"
            "・撮影済み写真から証拠データを確認\n\n"
            "データは端末内で扱います。ログインや外部サービス連携は不要です。"
        ),
        "keywords": "証拠写真,現場記録,置き配,清掃報告,工事報告,巡回,位置情報,カメラ,点検,管理",
        "whatsNew": "初回リリースです。",
        "promotionalText": "日時・位置・方角・傾き・ハッシュを写真に記録。",
        "marketingUrl": "https://snarfnet.github.io/",
        "supportUrl": "https://snarfnet.github.io/",
    }
}


def headers():
    return {"Authorization": f"Bearer {make_token()}", "Content-Type": "application/json"}


def response_json(method, path, **kwargs):
    for _ in range(6):
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


def font(size, bold=False):
    candidates = [
        "/System/Library/Fonts/ヒラギノ角ゴシック W6.ttc" if bold else "/System/Library/Fonts/ヒラギノ角ゴシック W3.ttc",
        "/System/Library/Fonts/Helvetica.ttc",
        "/System/Library/Fonts/Supplemental/Arial.ttf",
    ]
    for candidate in candidates:
        try:
            return ImageFont.truetype(candidate, size)
        except Exception:
            pass
    return ImageFont.load_default()


def draw_text_box(draw, xy, text, font_obj, fill, max_width, line_gap=10):
    x, y = xy
    line = ""
    for char in text:
        test = line + char
        if draw.textbbox((0, 0), test, font=font_obj)[2] <= max_width or not line:
            line = test
            continue
        draw.text((x, y), line, font=font_obj, fill=fill)
        y += font_obj.size + line_gap
        line = char
    if line:
        draw.text((x, y), line, font=font_obj, fill=fill)
        y += font_obj.size + line_gap
    return y


def generate_screenshot(path, size):
    path.parent.mkdir(parents=True, exist_ok=True)
    width, height = size
    image = Image.new("RGB", size, "#eff5f9")
    draw = ImageDraw.Draw(image)

    draw.rectangle((0, 0, width, int(height * 0.12)), fill="#17324d")
    draw.text((int(width * 0.07), int(height * 0.045)), "証拠カメラ", font=font(68, True), fill="white")
    draw.text((int(width * 0.07), int(height * 0.083)), "現場写真に信頼性を記録", font=font(32), fill="#cfe5f3")

    margin = int(width * 0.07)
    preview_top = int(height * 0.16)
    preview_bottom = int(height * 0.67)
    draw.rounded_rectangle((margin, preview_top, width - margin, preview_bottom), radius=34, fill="#d6e7ef")
    draw.rectangle((margin + 30, preview_top + 30, width - margin - 30, preview_bottom - 30), fill="#b8d2df")
    draw.line((margin + 80, preview_top + 90, margin + 230, preview_top + 90), fill="white", width=12)
    draw.line((margin + 80, preview_top + 90, margin + 80, preview_top + 240), fill="white", width=12)
    draw.line((width - margin - 80, preview_top + 90, width - margin - 230, preview_top + 90), fill="white", width=12)
    draw.line((width - margin - 80, preview_top + 90, width - margin - 80, preview_top + 240), fill="white", width=12)

    overlay_left = margin + 60
    overlay_top = preview_bottom - int(height * 0.17)
    overlay_right = width - margin - 60
    overlay_bottom = preview_bottom - 48
    draw.rounded_rectangle((overlay_left, overlay_top, overlay_right, overlay_bottom), radius=20, fill="#ffffff")
    draw.text((overlay_left + 30, overlay_top + 26), "2026/06/13 19:48:38", font=font(36, True), fill="#18344f")
    draw.text((overlay_left + 30, overlay_top + 78), "東京都港区芝公園  35.6586, 139.7454", font=font(28), fill="#38566c")
    draw.text((overlay_left + 30, overlay_top + 122), "方角 92°  傾き pitch -2.1° roll 0.8°", font=font(28), fill="#38566c")
    draw.text((overlay_left + 30, overlay_top + 166), "SHA-256  91A3...F02C", font=font(26), fill="#38566c")

    y = int(height * 0.72)
    draw.text((margin, y), "写真に残る記録", font=font(48, True), fill="#17324d")
    y += 76
    features = ["日時", "位置情報", "方角", "端末の傾き", "改ざん防止ハッシュ", "連続撮影ログ"]
    box_w = (width - margin * 2 - 28) // 2
    box_h = 92
    for index, label in enumerate(features):
        x = margin + (index % 2) * (box_w + 28)
        yy = y + (index // 2) * (box_h + 22)
        draw.rounded_rectangle((x, yy, x + box_w, yy + box_h), radius=18, fill="#ffffff")
        draw.ellipse((x + 24, yy + 26, x + 64, yy + 66), fill="#1f91d0")
        draw.text((x + 88, yy + 26), label, font=font(30, True), fill="#17324d")

    note_top = height - int(height * 0.12)
    draw.rounded_rectangle((margin, note_top, width - margin, height - 54), radius=24, fill="#ffffff")
    draw_text_box(
        draw,
        (margin + 34, note_top + 26),
        "置き配、清掃報告、工事報告、店舗巡回、マンション管理、交通量調査に。",
        font(30),
        "#38566c",
        width - margin * 2 - 68,
    )
    image.save(path)


def ensure_screenshot_files():
    for _, files in SCREENSHOTS:
        for filename, size in files:
            path = SCREENSHOT_DIR / filename
            if not path.exists():
                generate_screenshot(path, size)
                print(f"Generated screenshot: {path}")


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
    if "ja" not in existing:
        payload = {
            "data": {
                "type": "appStoreVersionLocalizations",
                "attributes": {"locale": "ja"},
                "relationships": {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}}},
            }
        }
        body = api_json("POST", "/appStoreVersionLocalizations", data=json_body(payload))
        existing["ja"] = body["data"]
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
        if response.status_code not in (200, 201):
            raise RuntimeError(f"Metadata {locale} failed {response.status_code}: {response.text[:1000]}")
        print(f"Metadata {locale}: {response.status_code}")


def update_app_info():
    response, body = response_json("GET", f"/apps/{APP_ID}/appInfos?limit=10")
    if response.status_code != 200 or not body.get("data"):
        print(f"App info skipped: {response.status_code}")
        return
    app_info_id = body["data"][0]["id"]
    response, _ = response_json("PATCH", f"/appInfos/{app_info_id}", json={
        "data": {
            "type": "appInfos",
            "id": app_info_id,
            "relationships": {"primaryCategory": {"data": {"type": "appCategories", "id": "UTILITIES"}}},
        }
    })
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
                    "name": "証拠カメラ 現場記録",
                    "subtitle": "証拠写真と現場記録",
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
    response, _ = response_json("PATCH", f"/ageRatingDeclarations/{app_info_id}", json={
        "data": {"type": "ageRatingDeclarations", "id": app_info_id, "attributes": attrs}
    })
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


def price_value(point):
    attrs = point.get("attributes", {})
    for key in ("customerPrice", "price"):
        try:
            return float(attrs.get(key))
        except Exception:
            pass
    return None


def ensure_price():
    points = list_all("/apps/{app}/appPricePoints?{params}".format(
        app=APP_ID,
        params=query({"filter[territory]": "JPN", "fields[appPricePoints]": "customerPrice", "limit": "200"}),
    ))
    if not points:
        raise RuntimeError("No JPN price points found.")
    exact = [point for point in points if price_value(point) == APP_PRICE_JPY]
    price_point = exact[0] if exact else min(points, key=lambda point: abs((price_value(point) or 0) - APP_PRICE_JPY))
    selected = price_value(price_point)
    if selected != APP_PRICE_JPY:
        raise RuntimeError(f"No exact {APP_PRICE_JPY:g} JPY price point found. Closest was {selected}.")
    print(f"Selected JPN price point: {price_point['id']} customerPrice={selected:g}")
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
    if response.status_code not in (200, 201, 409):
        raise RuntimeError(f"Price schedule failed {response.status_code}: {response.text[:1000]}")
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
        response, _ = response_json("PATCH", f"/appDataUsagesPublishState/{state_id}", json={
            "data": {
                "type": "appDataUsagesPublishState",
                "id": state_id,
                "attributes": {"published": True},
            }
        })
        print(f"App data usage publish: {response.status_code}")


def ensure_review_detail(version_id):
    attrs = {
        "contactFirstName": "Tokyo",
        "contactLastName": "Nasu",
        "contactPhone": "+1 844 209 0611",
        "contactEmail": "tokyonasu@yahoo.co.jp",
        "demoAccountRequired": False,
        "notes": (
            "ログイン不要です。カメラ、位置情報、モーション、写真ライブラリ権限を使います。"
            "撮影すると日時、位置、方角、傾き、ハッシュ、連続撮影ログを写真メタデータと端末内記録に保存します。"
            "外部サーバーへの送信はありません。実機での確認をお願いします。"
        ),
    }
    response, body = response_json("GET", f"/appStoreVersions/{version_id}/appStoreReviewDetail")
    if response.status_code == 200 and body.get("data"):
        detail_id = body["data"]["id"]
        response, _ = response_json("PATCH", f"/appStoreReviewDetails/{detail_id}", json={
            "data": {"type": "appStoreReviewDetails", "id": detail_id, "attributes": attrs}
        })
        print(f"Review detail update: {response.status_code}")
        return
    response, _ = response_json("POST", "/appStoreReviewDetails", json={
        "data": {
            "type": "appStoreReviewDetails",
            "attributes": attrs,
            "relationships": {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}}},
        }
    })
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
    ensure_screenshot_files()
    for loc in ensure_localizations(version_id):
        print(f"Screenshots for {loc['attributes']['locale']}")
        sets = list_all(f"/appStoreVersionLocalizations/{loc['id']}/appScreenshotSets?limit=200")
        existing = {item["attributes"]["screenshotDisplayType"]: item["id"] for item in sets}
        for display_type, files in SCREENSHOTS:
            set_id = existing.get(display_type)
            if not set_id:
                body = api_json("POST", "/appScreenshotSets", data=json_body({
                    "data": {
                        "type": "appScreenshotSets",
                        "attributes": {"screenshotDisplayType": display_type},
                        "relationships": {
                            "appStoreVersionLocalization": {"data": {"type": "appStoreVersionLocalizations", "id": loc["id"]}}
                        },
                    }
                }))
                set_id = body["data"]["id"]
            for screenshot in list_all(f"/appScreenshotSets/{set_id}/appScreenshots?limit=200"):
                response, _ = response_json("DELETE", f"/appScreenshots/{screenshot['id']}")
                print(f"  delete screenshot {screenshot['id']}: {response.status_code}")
            for filename, _ in files:
                upload_screenshot(set_id, filename)


def upload_screenshot(set_id, filename):
    path = SCREENSHOT_DIR / filename
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
        raise RuntimeError(f"Screenshot create failed {response.status_code}: {response.text[:1000]}")
    screenshot_id = body["data"]["id"]
    for operation in body["data"]["attributes"]["uploadOperations"]:
        upload_headers = {item["name"]: item["value"] for item in operation["requestHeaders"]}
        start = operation["offset"]
        end = start + operation["length"]
        put_response = requests.put(operation["url"], headers=upload_headers, data=data[start:end], timeout=120)
        if put_response.status_code not in (200, 201):
            raise RuntimeError(f"Screenshot binary upload failed {put_response.status_code}: {put_response.text[:500]}")
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
    if response.status_code not in (200, 204):
        raise RuntimeError(f"Build assign failed {response.status_code}: {response.text[:1000]}")
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
    if not SUBMIT_REVIEW:
        print("Prepared production metadata. Review submission skipped by SUBMIT_REVIEW=false.")
        return
    cancel_open_review_submissions()
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
        if response.status_code == 409 and "SCREENSHOT_UPLOADS_IN_PROGRESS" in response.text:
            time.sleep(60)
            continue
        if response.status_code == 409 and "ITEM_PART_OF_ANOTHER_SUBMISSION" in response.text:
            match = re.search(r"reviewSubmission with id ([0-9a-f-]+)", response.text)
            if match:
                finish_review_submission(match.group(1))
                return
        raise RuntimeError(f"Review item failed {response.status_code}: {response.text[:2000]}")
    else:
        raise RuntimeError(f"Review item failed after retries: {response.status_code} {response.text[:1000]}")
    finish_review_submission(submission_id)


def main():
    response, body = response_json("GET", f"/apps/{APP_ID}")
    if response.status_code != 200:
        raise RuntimeError(f"App lookup failed {response.status_code}: {response.text[:500]}")
    attrs = body["data"]["attributes"]
    print(f"App: {attrs.get('name')} / {attrs.get('bundleId')}")
    print(f"Submitting build {BUILD_NUMBER} at {APP_PRICE_JPY:g} JPY.")
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
