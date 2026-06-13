#!/usr/bin/env python3
import hashlib
import os
import re
import sys
import time

from asc_helpers import api, api_json, headers, query
import requests


APP_ID = os.environ.get("APP_ID", "6779627060")
APP_VERSION = os.environ.get("APP_VERSION", "1.0")
BUILD_NUMBER = os.environ.get("BUILD_NUMBER", "120")
APP_PRICE_JPY = os.environ.get("APP_PRICE_JPY", "100")
SCREENSHOT_DIR = "MarketingAssets/Screenshots"

SCREENSHOT_GROUPS = [
    ("APP_IPHONE_67", ["iphone67_01_home.png", "iphone67_02_procedure.png", "iphone67_03_office.png"]),
    ("APP_IPHONE_65", ["iphone65_01_home.png", "iphone65_02_procedure.png", "iphone65_03_office.png"]),
    ("APP_IPHONE_55", ["iphone55_01_home.png", "iphone55_02_procedure.png", "iphone55_03_office.png"]),
    ("APP_IPAD_PRO_3GEN_129", ["ipad129_01_home.png", "ipad129_02_procedure.png", "ipad129_03_office.png"]),
]

META = {
    "ja": {
        "description": """役所手続きナビは、引っ越し、出産、相続、退職、結婚など、生活の節目で必要になりやすい行政手続きを整理するアプリです。

状況を選ぶと、必要な手続き、期限、必要書類、提出先、注意点を一覧で確認できます。保存リストで後から見直せます。

全国の自治体名から選択でき、市と東京23区は代表所在地・電話も表示します。GPSから現在地の自治体を探す機能もあります。

このアプリは一般的な案内を整理するものです。実際の必要書類や期限は自治体、勤務先、保険者、個別事情で変わります。申請前に必ず公式情報を確認してください。""",
        "keywords": "役所,手続き,引っ越し,出産,相続,退職,結婚,自治体,期限,必要書類",
        "whatsNew": "初回リリースです。",
        "promotionalText": "生活の節目で必要な役所手続きを整理します。",
        "marketingUrl": "https://snarfnet.github.io/",
        "supportUrl": "https://snarfnet.github.io/",
    },
    "en-US": {
        "description": """Yakusho Tetsuzuki Navi helps organize common Japanese municipal procedures for life events such as moving, childbirth, inheritance, retirement, and marriage.

Choose a situation to review procedure names, deadlines, required documents, submission destinations, and notes. You can save items and check them later.

The app includes a nationwide municipality list. For cities and Tokyo's 23 wards, it also shows representative office address and phone information.

This app provides general guidance only. Actual requirements and deadlines may vary by municipality, employer, insurer, and personal circumstances. Please confirm official information before applying.""",
        "keywords": "japan,city hall,municipal,procedure,moving,birth,marriage,retirement,documents",
        "whatsNew": "Initial release.",
        "promotionalText": "Organize common Japanese municipal procedures.",
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


def find_or_create_version():
    for version in list_all(f"/apps/{APP_ID}/appStoreVersions?{query({'filter[platform]': 'IOS', 'limit': '200'})}"):
        attrs = version.get("attributes", {})
        if attrs.get("versionString") == APP_VERSION:
            print(f"Found version {APP_VERSION}: {version['id']} state={attrs.get('appStoreState')}")
            return version["id"], attrs.get("appStoreState")

    body = api_json(
        "POST",
        "/appStoreVersions",
        json={
            "data": {
                "type": "appStoreVersions",
                "attributes": {"platform": "IOS", "versionString": APP_VERSION},
                "relationships": {"app": {"data": {"type": "apps", "id": APP_ID}}},
            }
        },
    )
    version = body["data"]
    print(f"Created version {APP_VERSION}: {version['id']}")
    return version["id"], version.get("attributes", {}).get("appStoreState")


def ensure_localizations(version_id):
    localizations = list_all(f"/appStoreVersions/{version_id}/appStoreVersionLocalizations?limit=200")
    existing = {item["attributes"]["locale"]: item for item in localizations}
    for locale in META:
        if locale in existing:
            continue
        body = api_json(
            "POST",
            "/appStoreVersionLocalizations",
            json={
                "data": {
                    "type": "appStoreVersionLocalizations",
                    "attributes": {"locale": locale},
                    "relationships": {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}}},
                }
            },
        )
        existing[locale] = body["data"]
        print(f"Localization created: {locale}")
    return list(existing.values())


def update_metadata(version_id):
    for loc in ensure_localizations(version_id):
        locale = loc["attributes"]["locale"]
        meta = META.get(locale, META["en-US"])
        response = api(
            "PATCH",
            f"/appStoreVersionLocalizations/{loc['id']}",
            json={"data": {"type": "appStoreVersionLocalizations", "id": loc["id"], "attributes": meta}},
        )
        if response.status_code == 409 and "whatsNew" in meta:
            meta = {key: value for key, value in meta.items() if key != "whatsNew"}
            response = api(
                "PATCH",
                f"/appStoreVersionLocalizations/{loc['id']}",
                json={"data": {"type": "appStoreVersionLocalizations", "id": loc["id"], "attributes": meta}},
            )
        print(f"Metadata {locale}: {response.status_code}")
        if response.status_code not in (200, 201):
            print(response.text[:1000])


def update_app_info(app_info_id):
    response = api(
        "PATCH",
        f"/appInfos/{app_info_id}",
        json={
            "data": {
                "type": "appInfos",
                "id": app_info_id,
                "relationships": {"primaryCategory": {"data": {"type": "appCategories", "id": "PRODUCTIVITY"}}},
            }
        },
    )
    print(f"Primary category: {response.status_code}")

    attrs = {
        "alcoholTobaccoOrDrugUseOrReferences": "NONE",
        "contests": "NONE",
        "gamblingSimulated": "NONE",
        "gunsOrOtherWeapons": "NONE",
        "medicalOrTreatmentInformation": "NONE",
        "profanityOrCrudeHumor": "NONE",
        "sexualContentGraphicAndNudity": "NONE",
        "sexualContentOrNudity": "NONE",
        "horrorOrFearThemes": "NONE",
        "matureOrSuggestiveThemes": "NONE",
        "violenceCartoonOrFantasy": "NONE",
        "violenceRealisticProlongedGraphicOrSadistic": "NONE",
        "violenceRealistic": "NONE",
        "messagingAndChat": False,
        "gambling": False,
        "parentalControls": False,
        "ageAssurance": False,
        "userGeneratedContent": False,
        "healthOrWellnessTopics": False,
        "unrestrictedWebAccess": False,
        "lootBox": False,
        "advertising": False,
    }
    response = api(
        "PATCH",
        f"/ageRatingDeclarations/{app_info_id}",
        json={"data": {"type": "ageRatingDeclarations", "id": app_info_id, "attributes": attrs}},
    )
    print(f"Age rating: {response.status_code}")

    body = api_json("GET", f"/appInfos/{app_info_id}/appInfoLocalizations?limit=20")
    for loc in body.get("data", []):
        locale = loc["attributes"].get("locale")
        response = api(
            "PATCH",
            f"/appInfoLocalizations/{loc['id']}",
            json={
                "data": {
                    "type": "appInfoLocalizations",
                    "id": loc["id"],
                    "attributes": {
                        "subtitle": "生活の役所手続きを整理" if locale == "ja" else "Municipal procedure guide",
                        "privacyPolicyUrl": "https://snarfnet.github.io/privacy.html",
                    },
                }
            },
        )
        print(f"App info {locale}: {response.status_code}")


def ensure_release_prerequisites(version_id):
    response = api(
        "PATCH",
        f"/apps/{APP_ID}",
        json={
            "data": {
                "type": "apps",
                "id": APP_ID,
                "attributes": {"contentRightsDeclaration": "DOES_NOT_USE_THIRD_PARTY_CONTENT"},
            }
        },
    )
    print(f"Content rights: {response.status_code}")

    body = api_json("GET", f"/apps/{APP_ID}/appInfos?limit=10")
    if body.get("data"):
        update_app_info(body["data"][0]["id"])

    response = api(
        "PATCH",
        f"/appStoreVersions/{version_id}",
        json={
            "data": {
                "type": "appStoreVersions",
                "id": version_id,
                "attributes": {
                    "copyright": "2026 Tokyo Nasu",
                    "usesIdfa": False,
                    "releaseType": "AFTER_APPROVAL",
                },
            }
        },
    )
    print(f"Version attributes: {response.status_code}")
    ensure_jpy_price()
    ensure_privacy_answers()
    ensure_review_detail(version_id)


def ensure_privacy_answers():
    try:
        body = iris_json("GET", f"/apps/{APP_ID}/dataUsagePublishState")
    except Exception as error:
        print(f"Privacy answers publish skipped: {error}")
        return
    state = body.get("data")
    if not state:
        print("Privacy answers: publish state not found")
        return

    response = iris_api(
        "PATCH",
        f"/appDataUsagesPublishState/{state['id']}",
        json={
            "data": {
                "type": "appDataUsagesPublishState",
                "id": state["id"],
                "attributes": {"published": True},
            }
        },
    )
    print(f"Privacy answers publish: {response.status_code}")
    if response.status_code not in (200, 201, 204, 409):
        print(response.text[:1000])


def iris_api(method, path, **kwargs):
    url = f"https://appstoreconnect.apple.com/iris/v1{path}"
    last_response = None
    for _ in range(6):
        last_response = requests.request(method, url, headers=headers(), timeout=120, **kwargs)
        if last_response.status_code not in (401, 429, 500, 502, 503, 504):
            return last_response
        time.sleep(20)
    return last_response


def iris_json(method, path, **kwargs):
    response = iris_api(method, path, **kwargs)
    try:
        body = response.json()
    except Exception:
        body = {}
    if response.status_code not in (200, 201, 204):
        raise RuntimeError(f"{method} iris {path} failed {response.status_code}: {response.text[:1000]}")
    return body


def ensure_jpy_price():
    body = api_json(
        "GET",
        f"/apps/{APP_ID}/appPricePoints?filter[territory]=JPN&fields[appPricePoints]=customerPrice&limit=200",
    )
    points = body.get("data", [])
    while body.get("links", {}).get("next"):
        next_path = body["links"]["next"].split("/v1", 1)[1]
        body = api_json("GET", next_path)
        points.extend(body.get("data", []))

    price_id = None
    for point in points:
        if str(point.get("attributes", {}).get("customerPrice")) in (APP_PRICE_JPY, f"{APP_PRICE_JPY}.0", f"{APP_PRICE_JPY}.00"):
            price_id = point["id"]
            break
    if not price_id and points:
        price_id = min(points, key=lambda item: abs(float(item.get("attributes", {}).get("customerPrice") or 0) - float(APP_PRICE_JPY)))["id"]
    if not price_id:
        print("JPY price: skipped")
        return

    response = api(
        "POST",
        "/appPriceSchedules",
        json={
            "data": {
                "type": "appPriceSchedules",
                "attributes": {},
                "relationships": {
                    "app": {"data": {"type": "apps", "id": APP_ID}},
                    "baseTerritory": {"data": {"type": "territories", "id": "JPN"}},
                    "manualPrices": {"data": [{"type": "appPrices", "id": "${manualPrice0}"}]},
                },
            },
            "included": [
                {
                    "type": "appPrices",
                    "id": "${manualPrice0}",
                    "attributes": {"startDate": None},
                    "relationships": {"appPricePoint": {"data": {"type": "appPricePoints", "id": price_id}}},
                }
            ],
        },
    )
    print(f"JPY price: {response.status_code}")
    if response.status_code not in (200, 201, 409):
        print(response.text[:1000])


def ensure_review_detail(version_id):
    attrs = {
        "contactFirstName": "Tokyo",
        "contactLastName": "Nasu",
        "contactPhone": "+81 80-2368-9194",
        "contactEmail": "tokyonasu@yahoo.co.jp",
        "demoAccountRequired": False,
        "notes": (
            "ログイン不要です。状況を選ぶと手続き一覧、期限、必要書類、役所情報を確認できます。"
            "GPS機能は現在地から自治体候補を探すために使います。位置情報は端末外へ送信しません。"
            "本アプリは一般的な行政手続き案内です。申請前に公式情報を確認する注意書きを表示しています。"
        ),
    }
    body = api_json("GET", f"/appStoreVersions/{version_id}/appStoreReviewDetail")
    if body.get("data"):
        detail_id = body["data"]["id"]
        response = api(
            "PATCH",
            f"/appStoreReviewDetails/{detail_id}",
            json={"data": {"type": "appStoreReviewDetails", "id": detail_id, "attributes": attrs}},
        )
        print(f"Review detail update: {response.status_code}")
        return

    response = api(
        "POST",
        "/appStoreReviewDetails",
        json={
            "data": {
                "type": "appStoreReviewDetails",
                "attributes": attrs,
                "relationships": {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}}},
            }
        },
    )
    print(f"Review detail create: {response.status_code}")


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
    raise RuntimeError(f"Build {BUILD_NUMBER} did not finish processing.")


def upload_screenshots(version_id):
    for loc in ensure_localizations(version_id):
        print(f"Screenshots for {loc['attributes']['locale']}")
        sets = list_all(f"/appStoreVersionLocalizations/{loc['id']}/appScreenshotSets?limit=200")
        existing = {item["attributes"]["screenshotDisplayType"]: item["id"] for item in sets}
        for display_type, filenames in SCREENSHOT_GROUPS:
            set_id = existing.get(display_type)
            if not set_id:
                body = api_json(
                    "POST",
                    "/appScreenshotSets",
                    json={
                        "data": {
                            "type": "appScreenshotSets",
                            "attributes": {"screenshotDisplayType": display_type},
                            "relationships": {
                                "appStoreVersionLocalization": {
                                    "data": {"type": "appStoreVersionLocalizations", "id": loc["id"]}
                                }
                            },
                        }
                    },
                )
                set_id = body["data"]["id"]
            for screenshot in list_all(f"/appScreenshotSets/{set_id}/appScreenshots?limit=200"):
                api("DELETE", f"/appScreenshots/{screenshot['id']}")
            for filename in filenames:
                upload_screenshot(set_id, filename)


def upload_screenshot(set_id, filename):
    path = os.path.join(SCREENSHOT_DIR, filename)
    if not os.path.exists(path):
        raise RuntimeError(f"Missing screenshot: {path}")
    with open(path, "rb") as file:
        data = file.read()
    checksum = hashlib.md5(data).hexdigest()
    body = api_json(
        "POST",
        "/appScreenshots",
        json={
            "data": {
                "type": "appScreenshots",
                "attributes": {"fileName": filename, "fileSize": len(data)},
                "relationships": {"appScreenshotSet": {"data": {"type": "appScreenshotSets", "id": set_id}}},
            }
        },
    )
    screenshot_id = body["data"]["id"]
    for operation in body["data"]["attributes"]["uploadOperations"]:
        request_headers = {item["name"]: item["value"] for item in operation["requestHeaders"]}
        start = operation["offset"]
        end = start + operation["length"]
        requests.put(operation["url"], headers=request_headers, data=data[start:end], timeout=120)
    response = None
    for attempt in range(1, 7):
        response = api(
            "PATCH",
            f"/appScreenshots/{screenshot_id}",
            json={
                "data": {
                    "type": "appScreenshots",
                    "id": screenshot_id,
                    "attributes": {"uploaded": True, "sourceFileChecksum": checksum},
                }
            },
        )
        if response.status_code in (200, 201):
            break
        print(f"  {filename}: confirm retry {attempt}/6 status={response.status_code}")
        time.sleep(20)
    print(f"  {filename}: {response.status_code}")


def assign_build(version_id, build_id):
    response = api(
        "PATCH",
        f"/builds/{build_id}",
        json={"data": {"type": "builds", "id": build_id, "attributes": {"usesNonExemptEncryption": False}}},
    )
    print(f"Build encryption declaration: {response.status_code}")
    response = api(
        "PATCH",
        f"/appStoreVersions/{version_id}/relationships/build",
        json={"data": {"type": "builds", "id": build_id}},
    )
    print(f"Build assigned: {response.status_code}")
    if response.status_code not in (200, 204):
        raise RuntimeError(f"Build assign failed {response.status_code}: {response.text[:1000]}")


def cancel_unresolved_review_submissions():
    body = api_json("GET", f"/apps/{APP_ID}/reviewSubmissions?limit=20")
    ready_id = None
    for submission in body.get("data", []):
        state = submission.get("attributes", {}).get("state")
        submission_id = submission["id"]
        if state == "READY_FOR_REVIEW":
            ready_id = ready_id or submission_id
        elif state == "UNRESOLVED_ISSUES":
            response = api(
                "PATCH",
                f"/reviewSubmissions/{submission_id}",
                json={"data": {"type": "reviewSubmissions", "id": submission_id, "attributes": {"canceled": True}}},
            )
            print(f"Canceled unresolved review submission {submission_id}: {response.status_code}")
            time.sleep(60)
        elif state in ("WAITING_FOR_REVIEW", "IN_REVIEW"):
            print(f"Already submitted: {submission_id} {state}")
            return "submitted"
    return ready_id


def submit_for_review(version_id):
    submission_id = cancel_unresolved_review_submissions()
    if submission_id == "submitted":
        return
    if submission_id:
        print(f"Using ready review submission: {submission_id}")
    else:
        body = api_json(
            "POST",
            "/reviewSubmissions",
            json={
                "data": {
                    "type": "reviewSubmissions",
                    "attributes": {"platform": "IOS"},
                    "relationships": {"app": {"data": {"type": "apps", "id": APP_ID}}},
                }
            },
        )
        submission_id = body["data"]["id"]

    for attempt in range(20):
        response = api(
            "POST",
            "/reviewSubmissionItems",
            json={
                "data": {
                    "type": "reviewSubmissionItems",
                    "relationships": {
                        "reviewSubmission": {"data": {"type": "reviewSubmissions", "id": submission_id}},
                        "appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}},
                    },
                }
            },
        )
        print(f"Review item {attempt + 1}/20: {response.status_code}")
        if response.status_code == 201:
            break
        if response.status_code == 409:
            if "SCREENSHOT_UPLOADS_IN_PROGRESS" in response.text:
                time.sleep(60)
                continue
            if "ITEM_PART_OF_ANOTHER_SUBMISSION" in response.text:
                match = re.search(r"reviewSubmission with id ([0-9a-f-]+)", response.text)
                if match:
                    finish_review_submission(match.group(1))
                    return
            raise RuntimeError(f"Review item blocked: {response.text[:4000]}")
        time.sleep(30)
    else:
        raise RuntimeError(f"Review item create failed: {response.text[:1000]}")
    finish_review_submission(submission_id)


def finish_review_submission(submission_id):
    for attempt in range(1, 31):
        response = api(
            "PATCH",
            f"/reviewSubmissions/{submission_id}",
            json={"data": {"type": "reviewSubmissions", "id": submission_id, "attributes": {"submitted": True}}},
        )
        if response.status_code == 200:
            body = response.json()
            print(f"Submitted for App Review: {body['data']['attributes']['state']}")
            return
        print(f"Review submit {attempt}/30: {response.status_code}")
        print(response.text[:1000])
        time.sleep(60)
    raise RuntimeError(f"Review submit failed: {response.status_code} {response.text[:1000]}")


def main():
    body = api_json("GET", f"/apps/{APP_ID}")
    attrs = body["data"]["attributes"]
    print(f"App: {attrs.get('name')} / {attrs.get('bundleId')}")

    version_id, state = find_or_create_version()
    ensure_release_prerequisites(version_id)
    update_metadata(version_id)
    if os.environ.get("PREPARE_APP_ONLY") == "1":
        print("App Store Connect metadata is ready.")
        return
    if state in ("WAITING_FOR_REVIEW", "IN_REVIEW"):
        print(f"Already submitted: {state}")
        return

    build_id = wait_for_build()
    upload_screenshots(version_id)
    print("Waiting for screenshot processing...")
    time.sleep(300)
    assign_build(version_id, build_id)
    submit_for_review(version_id)


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        print(str(error), file=sys.stderr)
        sys.exit(1)
