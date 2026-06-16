#!/usr/bin/env python3
import hashlib
import os
import re
import sys
import time

import requests

from asc_helpers import api, api_json, headers, query


APP_ID = os.environ.get("APP_ID", "6780083334")
APP_VERSION = os.environ.get("APP_VERSION", "1.0")
BUILD_NUMBER = os.environ.get("BUILD_NUMBER", "33")
SCREENSHOT_DIR = "MarketingAssets/Screenshots"

SCREENSHOT_GROUPS = [
    ("APP_IPHONE_67", ["iphone67_01_home.png", "iphone67_02_loop.png", "iphone67_03_midi.png"]),
    ("APP_IPHONE_65", ["iphone65_01_home.png", "iphone65_02_loop.png", "iphone65_03_midi.png"]),
    ("APP_IPHONE_55", ["iphone55_01_home.png", "iphone55_02_loop.png", "iphone55_03_midi.png"]),
    ("APP_IPAD_PRO_3GEN_129", ["ipad129_01_home.png", "ipad129_02_loop.png", "ipad129_03_midi.png"]),
]

META = {
    "ja": {
        "description": """ピアノフレーズは、短いピアノのフレーズをランダム生成して聴けるアプリです。

小節数を選び、作成ボタンで候補を出し、気に入ったフレーズを再生やループで確認できます。現在のフレーズはピアノロール風の表示で進行を追えます。

保存したいフレーズはMIDIファイルとして共有できます。DAW、楽譜アプリ、作曲メモに持ち込んで、曲作りの種として使えます。

内蔵のピアノ音源には FreePats の Acoustic Grand Piano を使用しています。""",
        "keywords": "ピアノ,作曲,MIDI,フレーズ,メロディ,コード,音楽,作曲支援,ループ",
        "whatsNew": "初回リリースです。",
        "promotionalText": "短いピアノフレーズを作成し、聴いて、MIDIで保存できます。",
        "marketingUrl": "https://snarfnet.github.io/",
        "supportUrl": "https://snarfnet.github.io/",
    },
    "en-US": {
        "description": """Piano Phrase creates short piano phrase ideas you can listen to, loop, and save.

Choose the number of bars, generate a candidate, and follow the current phrase with a piano-roll style view. When a phrase feels useful, export it as a MIDI file and continue working in your DAW or notation app.

The bundled piano sound uses Acoustic Grand Piano from FreePats.""",
        "keywords": "piano,composition,midi,phrase,melody,chords,music,loop,songwriting",
        "whatsNew": "Initial release.",
        "promotionalText": "Generate short piano phrase ideas and save them as MIDI.",
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
    versions = list_all(f"/apps/{APP_ID}/appStoreVersions?{query({'filter[platform]': 'IOS', 'limit': '200'})}")
    for version in versions:
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
            attrs = {key: value for key, value in meta.items() if key != "whatsNew"}
            response = api(
                "PATCH",
                f"/appStoreVersionLocalizations/{loc['id']}",
                json={"data": {"type": "appStoreVersionLocalizations", "id": loc["id"], "attributes": attrs}},
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
                "relationships": {"primaryCategory": {"data": {"type": "appCategories", "id": "MUSIC"}}},
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
        "advertising": True,
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
        subtitle = "短いピアノフレーズ作成" if locale == "ja" else "Short piano phrase ideas"
        response = api(
            "PATCH",
            f"/appInfoLocalizations/{loc['id']}",
            json={
                "data": {
                    "type": "appInfoLocalizations",
                    "id": loc["id"],
                    "attributes": {
                        "subtitle": subtitle,
                        "privacyPolicyUrl": "https://snarfnet.github.io/privacy.html",
                    },
                }
            },
        )
        print(f"App info {locale}: {response.status_code}")


def iris_api(method, path, **kwargs):
    url = f"https://appstoreconnect.apple.com/iris/v1{path}"
    last_response = None
    for _ in range(6):
        last_response = requests.request(method, url, headers=headers(), timeout=120, **kwargs)
        if last_response.status_code not in (401, 429, 500, 502, 503, 504):
            return last_response
        time.sleep(20)
    return last_response


def publish_existing_privacy_answers():
    response = iris_api("GET", f"/apps/{APP_ID}/dataUsagePublishState")
    if response.status_code not in (200, 201):
        print(f"Privacy answers publish skipped: {response.status_code}")
        return
    body = response.json()
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


def ensure_review_detail(version_id):
    attrs = {
        "contactFirstName": "Tokyo",
        "contactLastName": "Nasu",
        "contactPhone": "+81 80-2368-9194",
        "contactEmail": "tokyonasu@yahoo.co.jp",
        "demoAccountRequired": False,
        "notes": (
            "ログイン不要です。短いピアノフレーズを生成、再生、ループ再生、MIDI保存できます。"
            "上部にAdMobバナー広告を表示します。"
            "内蔵音源として FreePats の Acoustic Grand Piano を使用し、アプリ内にクレジットを表示しています。"
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


def ensure_release_prerequisites(version_id):
    response = api(
        "PATCH",
        f"/apps/{APP_ID}",
        json={
            "data": {
                "type": "apps",
                "id": APP_ID,
                "attributes": {"contentRightsDeclaration": "USES_THIRD_PARTY_CONTENT"},
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
                    "usesIdfa": True,
                    "releaseType": "AFTER_APPROVAL",
                },
            }
        },
    )
    print(f"Version attributes: {response.status_code}")
    publish_existing_privacy_answers()
    ensure_review_detail(version_id)


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
