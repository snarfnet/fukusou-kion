import hashlib
import os
import re
import sys
import time

import jwt
import requests

KEY_ID = os.environ["ASC_KEY_ID"]
ISSUER_ID = os.environ["ASC_ISSUER_ID"]
APP_ID = os.environ.get("APP_ID") or os.environ.get("CELL_ARTISAN_APP_ID") or "6779956374"
APP_VERSION = os.environ.get("APP_VERSION", "0.1")
BUILD_NUMBER = os.environ.get("BUILD_NUMBER", "143")
APP_PRICE_JPY = os.environ.get("APP_PRICE_JPY", "100")
P8_PATH = os.environ.get("ASC_P8_PATH", "/tmp/asc_key.p8")
SCREENSHOT_DIR = "MarketingAssets/Screenshots"

SCREENSHOT_GROUPS = [
    ("APP_IPHONE_67", ["iphone67_01.png", "iphone67_02.png", "iphone67_03.png"]),
    ("APP_IPHONE_55", ["iphone55_01.png", "iphone55_02.png", "iphone55_03.png"]),
]

META = {
    "ja": {
        "description": """たまにいるエクセル職人は、画像をExcelのセルアートに変換するアプリです。

写真やイラストを選ぶだけで、セルの塗りつぶしで作られた.xlsxファイルを書き出せます。画像を貼り付けるのではなく、ExcelやGoogleスプレッドシートで開けるセル絵として保存します。

横セル数、色数、セルサイズを調整できます。写真向けの高精細設定、軽めの設定、線画向けの設定を選び、仕上がりを見ながら変換できます。

作成したファイルは共有シートからメール、ファイル、クラウドストレージなどへ送れます。ロゴ、キャラクター絵、ドット絵風の画像、SNS用のネタ画像などに使えます。

画像処理とExcelファイル作成は端末内で行います。選択した画像を外部サーバーへ送信しません。""",
        "keywords": "Excel,セルアート,xlsx,ドット絵,画像変換,表計算,ピクセルアート,写真,イラスト,スプレッドシート",
        "whatsNew": "初回リリースです。",
        "promotionalText": "画像をExcelのセルアート.xlsxに変換します。",
        "marketingUrl": "https://snarfnet.github.io/",
        "supportUrl": "https://snarfnet.github.io/",
    },
    "en-US": {
        "description": """Cell Artisan converts images into Excel cell art.

Pick a photo or illustration, adjust the cell count, color count, and cell size, then export a real .xlsx file made from colored spreadsheet cells. The export is not a pasted image.

Use it for pixel-art style images, logos, character art, social posts, and spreadsheet experiments. Files can be shared through Mail, Files, cloud storage, and other apps.

Image processing and workbook creation run on device. Selected images are not uploaded to an external server.""",
        "keywords": "Excel,cell art,xlsx,pixel art,image converter,spreadsheet,photo,illustration,Google Sheets",
        "whatsNew": "Initial release.",
        "promotionalText": "Convert images into Excel cell art .xlsx files.",
        "marketingUrl": "https://snarfnet.github.io/",
        "supportUrl": "https://snarfnet.github.io/",
    },
}


def make_token():
    now = int(time.time())
    with open(P8_PATH, encoding="utf-8") as file:
        private_key = file.read()
    return jwt.encode(
        {"iss": ISSUER_ID, "iat": now, "exp": now + 1200, "aud": "appstoreconnect-v1"},
        private_key,
        algorithm="ES256",
        headers={"kid": KEY_ID},
    )


def headers():
    return {"Authorization": f"Bearer {make_token()}", "Content-Type": "application/json"}


def api(method, path, **kwargs):
    last_response = None
    for _ in range(6):
        last_response = requests.request(
            method,
            f"https://api.appstoreconnect.apple.com/v1{path}",
            headers=headers(),
            timeout=120,
            **kwargs,
        )
        if last_response.status_code not in (401, 429, 500, 502, 503, 504):
            return last_response
        time.sleep(20)
    return last_response


def api_json(method, path, **kwargs):
    response = api(method, path, **kwargs)
    try:
        body = response.json()
    except Exception:
        body = {}
    return response, body


def list_all(path):
    rows = []
    next_path = path
    while next_path:
        response, body = api_json("GET", next_path)
        if response.status_code != 200:
            raise RuntimeError(f"List failed {response.status_code}: {response.text[:1200]}")
        rows.extend(body.get("data", []))
        next_url = body.get("links", {}).get("next")
        next_path = next_url.split("/v1", 1)[1] if next_url else None
    return rows


def ensure_app_info():
    response, body = api_json("GET", f"/apps/{APP_ID}/appInfos?limit=10")
    if response.status_code != 200 or not body.get("data"):
        print(f"App info lookup skipped: {response.status_code}")
        return
    app_info_id = body["data"][0]["id"]
    response = api("PATCH", f"/appInfos/{app_info_id}", json={
        "data": {
            "type": "appInfos",
            "id": app_info_id,
            "relationships": {"primaryCategory": {"data": {"type": "appCategories", "id": "GRAPHICS_AND_DESIGN"}}},
        }
    })
    print(f"Primary category: {response.status_code}")
    update_app_info_localizations(app_info_id)
    update_age_rating(app_info_id)


def update_app_info_localizations(app_info_id):
    response, body = api_json("GET", f"/appInfos/{app_info_id}/appInfoLocalizations?limit=20")
    if response.status_code != 200:
        print(f"App info localization lookup: {response.status_code}")
        return
    for loc in body.get("data", []):
        locale = loc["attributes"].get("locale")
        attrs = {
            "subtitle": "画像を.xlsxのセルアートに変換" if locale == "ja" else "Convert images into Excel cell art",
            "privacyPolicyUrl": "https://snarfnet.github.io/privacy.html",
        }
        if locale == "ja":
            attrs["name"] = "たまにいるエクセル職人"
        response = api("PATCH", f"/appInfoLocalizations/{loc['id']}", json={
            "data": {"type": "appInfoLocalizations", "id": loc["id"], "attributes": attrs}
        })
        print(f"App info {locale}: {response.status_code}")


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
    ]
    attrs = {key: "NONE" for key in string_keys}
    attrs.update({key: False for key in bool_keys})
    attrs["advertising"] = False
    response = api("PATCH", f"/ageRatingDeclarations/{app_info_id}", json={
        "data": {"type": "ageRatingDeclarations", "id": app_info_id, "attributes": attrs}
    })
    print(f"Age rating: {response.status_code}")


def find_or_create_version():
    versions = list_all(f"/apps/{APP_ID}/appStoreVersions?limit=200")
    editable_states = {
        "DEVELOPER_REJECTED",
        "PREPARE_FOR_SUBMISSION",
        "REJECTED",
        "WAITING_FOR_REVIEW",
        "INVALID_BINARY",
        "METADATA_REJECTED",
    }
    fallback = None
    for version in versions:
        attrs = version.get("attributes", {})
        print(f"Version candidate: {attrs.get('versionString')} state={attrs.get('appStoreState')} id={version['id']}")
        if attrs.get("versionString") == APP_VERSION:
            print(f"Found version {APP_VERSION}: {version['id']} state={attrs.get('appStoreState')}")
            return version["id"], attrs.get("appStoreState")
        if not fallback and attrs.get("appStoreState") in editable_states:
            fallback = version
    response, body = api_json("POST", "/appStoreVersions", json={
        "data": {
            "type": "appStoreVersions",
            "attributes": {"platform": "IOS", "versionString": APP_VERSION},
            "relationships": {"app": {"data": {"type": "apps", "id": APP_ID}}},
        }
    })
    if response.status_code not in (200, 201):
        if fallback:
            attrs = fallback["attributes"]
            print(
                f"Version create failed {response.status_code}; "
                f"using existing editable version {attrs.get('versionString')} "
                f"state={attrs.get('appStoreState')} id={fallback['id']}"
            )
            return fallback["id"], attrs.get("appStoreState")
        raise RuntimeError(f"Version create failed {response.status_code}: {response.text[:1200]}")
    print(f"Created version {APP_VERSION}: {body['data']['id']}")
    return body["data"]["id"], "PREPARE_FOR_SUBMISSION"


def ensure_localizations(version_id):
    localizations = list_all(f"/appStoreVersions/{version_id}/appStoreVersionLocalizations?limit=200")
    existing = {item["attributes"]["locale"]: item for item in localizations}
    for locale in META:
        if locale in existing:
            continue
        response, body = api_json("POST", "/appStoreVersionLocalizations", json={
            "data": {
                "type": "appStoreVersionLocalizations",
                "attributes": {"locale": locale},
                "relationships": {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}}},
            }
        })
        if response.status_code not in (200, 201):
            print(f"Localization create skipped {locale}: {response.status_code} {response.text[:400]}")
            continue
        existing[locale] = body["data"]
        print(f"Localization created: {locale}")
    return list(existing.values())


def update_metadata(version_id):
    for loc in ensure_localizations(version_id):
        locale = loc["attributes"]["locale"]
        meta = META.get(locale, META["en-US"]).copy()
        response = api("PATCH", f"/appStoreVersionLocalizations/{loc['id']}", json={
            "data": {"type": "appStoreVersionLocalizations", "id": loc["id"], "attributes": meta}
        })
        if response.status_code == 409 and "whatsNew" in meta:
            meta.pop("whatsNew", None)
            response = api("PATCH", f"/appStoreVersionLocalizations/{loc['id']}", json={
                "data": {"type": "appStoreVersionLocalizations", "id": loc["id"], "attributes": meta}
            })
        print(f"Metadata {locale}: {response.status_code}")
        if response.status_code not in (200, 201):
            print(response.text[:1200])


def ensure_release_prerequisites(version_id):
    response = api("PATCH", f"/apps/{APP_ID}", json={
        "data": {
            "type": "apps",
            "id": APP_ID,
            "attributes": {"contentRightsDeclaration": "DOES_NOT_USE_THIRD_PARTY_CONTENT"},
        }
    })
    print(f"Content rights: {response.status_code}")
    ensure_app_info()
    response = api("PATCH", f"/appStoreVersions/{version_id}", json={
        "data": {
            "type": "appStoreVersions",
            "id": version_id,
            "attributes": {"copyright": "2026 Tokyo Nasu", "usesIdfa": False, "releaseType": "MANUAL"},
        }
    })
    print(f"Version attributes: {response.status_code}")
    ensure_price()
    ensure_review_detail(version_id)


def ensure_price():
    target = str(APP_PRICE_JPY)
    response, body = api_json("GET", f"/apps/{APP_ID}/relationships/appPriceSchedule")
    if response.status_code == 200 and body.get("data"):
        schedule_id = body["data"]["id"]
        response, body = api_json(
            "GET",
            f"/appPriceSchedules/{schedule_id}/manualPrices"
            "?limit=200&include=appPricePoint,territory"
            "&fields[appPricePoints]=customerPrice"
            "&filter[territory]=JPN",
        )
        if response.status_code == 200:
            price_points = {
                item["id"]: str(item.get("attributes", {}).get("customerPrice"))
                for item in body.get("included", [])
                if item.get("type") == "appPricePoints"
            }
            for item in body.get("data", []):
                point_id = item.get("relationships", {}).get("appPricePoint", {}).get("data", {}).get("id")
                if item.get("attributes", {}).get("endDate") is None and price_points.get(point_id) == target:
                    print(f"Price JPN {target}: already set")
                    return

    response, body = api_json(
        "GET",
        f"/apps/{APP_ID}/appPricePoints?filter[territory]=JPN&fields[appPricePoints]=customerPrice&limit=200",
    )
    if response.status_code != 200:
        print(f"Price points lookup: {response.status_code}")
        return
    price_id = None
    for point in body.get("data", []):
        if str(point.get("attributes", {}).get("customerPrice")) == target:
            price_id = point["id"]
            break
    if not price_id:
        raise RuntimeError(f"No JPN price point found for {target} JPY")

    local_id = "${manualPrice0}"
    payload = {
        "data": {
            "type": "appPriceSchedules",
            "attributes": {},
            "relationships": {
                "app": {"data": {"type": "apps", "id": APP_ID}},
                "baseTerritory": {"data": {"type": "territories", "id": "JPN"}},
                "manualPrices": {"data": [{"type": "appPrices", "id": local_id}]},
            },
        },
        "included": [{
            "type": "appPrices",
            "id": local_id,
            "attributes": {"startDate": None},
            "relationships": {"appPricePoint": {"data": {"type": "appPricePoints", "id": price_id}}},
        }],
    }
    response = api("POST", "/appPriceSchedules", json=payload)
    print(f"Price JPN {target}: {response.status_code}")
    if response.status_code not in (200, 201, 409):
        print(response.text[:1200])


def ensure_review_detail(version_id):
    attrs = {
        "contactFirstName": "Tokyo",
        "contactLastName": "Nasu",
        "contactPhone": "+81 80-2368-9194",
        "contactEmail": "tokyonasu@yahoo.co.jp",
        "demoAccountRequired": False,
        "notes": "ログイン不要です。画像選択、セル数調整、Excelファイル書き出し、共有まで端末内で確認できます。選択した画像は外部サーバーへ送信しません。",
    }
    response, body = api_json("GET", f"/appStoreVersions/{version_id}/appStoreReviewDetail")
    if response.status_code == 200 and body.get("data"):
        detail_id = body["data"]["id"]
        response = api("PATCH", f"/appStoreReviewDetails/{detail_id}", json={
            "data": {"type": "appStoreReviewDetails", "id": detail_id, "attributes": attrs}
        })
        print(f"Review detail update: {response.status_code}")
        return
    response = api("POST", "/appStoreReviewDetails", json={
        "data": {
            "type": "appStoreReviewDetails",
            "attributes": attrs,
            "relationships": {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}}},
        }
    })
    print(f"Review detail create: {response.status_code}")


def wait_for_build():
    for index in range(90):
        response, body = api_json(
            "GET",
            f"/builds?filter[app]={APP_ID}&filter[version]={BUILD_NUMBER}&filter[processingState]=VALID&limit=1",
        )
        if response.status_code == 200 and body.get("data"):
            build_id = body["data"][0]["id"]
            print(f"Build ready: {build_id}")
            return build_id
        print(f"Waiting for build {BUILD_NUMBER}... {index + 1}/90")
        time.sleep(30)
    raise RuntimeError(f"Build {BUILD_NUMBER} did not finish processing.")


def upload_screenshots(version_id):
    allowed_display_types = {display_type for display_type, _ in SCREENSHOT_GROUPS}
    for loc in ensure_localizations(version_id):
        locale = loc["attributes"]["locale"]
        print(f"Screenshots for {locale}")
        sets = list_all(f"/appStoreVersionLocalizations/{loc['id']}/appScreenshotSets?limit=200")
        for screenshot_set in sets:
            display_type = screenshot_set["attributes"]["screenshotDisplayType"]
            if display_type in allowed_display_types:
                continue
            for screenshot in list_all(f"/appScreenshotSets/{screenshot_set['id']}/appScreenshots?limit=200"):
                response = api("DELETE", f"/appScreenshots/{screenshot['id']}")
                print(f"  removed {display_type} screenshot {screenshot['id']}: {response.status_code}")
            response = api("DELETE", f"/appScreenshotSets/{screenshot_set['id']}")
            print(f"  removed screenshot set {display_type}: {response.status_code}")
        sets = list_all(f"/appStoreVersionLocalizations/{loc['id']}/appScreenshotSets?limit=200")
        existing = {item["attributes"]["screenshotDisplayType"]: item["id"] for item in sets}
        for display_type, filenames in SCREENSHOT_GROUPS:
            set_id = existing.get(display_type)
            if not set_id:
                response, body = api_json("POST", "/appScreenshotSets", json={
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
                if response.status_code not in (200, 201):
                    raise RuntimeError(f"Screenshot set create failed {response.status_code}: {response.text[:1200]}")
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
    response, body = api_json("POST", "/appScreenshots", json={
        "data": {
            "type": "appScreenshots",
            "attributes": {"fileName": filename, "fileSize": len(data)},
            "relationships": {"appScreenshotSet": {"data": {"type": "appScreenshotSets", "id": set_id}}},
        }
    })
    if response.status_code not in (200, 201):
        raise RuntimeError(f"Screenshot create failed {response.status_code}: {response.text[:1200]}")
    screenshot_id = body["data"]["id"]
    for operation in body["data"]["attributes"]["uploadOperations"]:
        request_headers = {item["name"]: item["value"] for item in operation["requestHeaders"]}
        start = operation["offset"]
        end = start + operation["length"]
        put_response = requests.put(operation["url"], headers=request_headers, data=data[start:end], timeout=120)
        if put_response.status_code not in (200, 201):
            raise RuntimeError(f"Screenshot binary upload failed {put_response.status_code}: {put_response.text[:500]}")
    response = None
    for attempt in range(1, 7):
        response = api("PATCH", f"/appScreenshots/{screenshot_id}", json={
            "data": {
                "type": "appScreenshots",
                "id": screenshot_id,
                "attributes": {"uploaded": True, "sourceFileChecksum": checksum},
            }
        })
        if response.status_code in (200, 201):
            break
        print(f"  {filename}: confirm retry {attempt}/6 status={response.status_code}")
        time.sleep(20)
    print(f"  {filename}: {response.status_code}")
    if response.status_code not in (200, 201):
        raise RuntimeError(f"Screenshot confirm failed {response.status_code}: {response.text[:1200]}")


def assign_build(version_id, build_id):
    response = api("PATCH", f"/builds/{build_id}", json={
        "data": {"type": "builds", "id": build_id, "attributes": {"usesNonExemptEncryption": False}}
    })
    print(f"Build encryption declaration: {response.status_code}")
    response = api("PATCH", f"/appStoreVersions/{version_id}/relationships/build", json={
        "data": {"type": "builds", "id": build_id}
    })
    print(f"Build assigned: {response.status_code}")
    if response.status_code not in (200, 204):
        print(response.text[:1200])


def cancel_unresolved_review_submissions():
    response, body = api_json("GET", f"/apps/{APP_ID}/reviewSubmissions?limit=20")
    if response.status_code != 200:
        return None
    ready_id = None
    for submission in body.get("data", []):
        state = submission.get("attributes", {}).get("state")
        submission_id = submission["id"]
        if state == "READY_FOR_REVIEW":
            ready_id = ready_id or submission_id
        elif state == "UNRESOLVED_ISSUES":
            response = api("PATCH", f"/reviewSubmissions/{submission_id}", json={
                "data": {"type": "reviewSubmissions", "id": submission_id, "attributes": {"canceled": True}}
            })
            print(f"Canceled unresolved submission {submission_id}: {response.status_code}")
            time.sleep(60)
        elif state in ("WAITING_FOR_REVIEW", "IN_REVIEW"):
            print(f"Already submitted: {submission_id} {state}")
            return "submitted"
    return ready_id


def submit_for_review(version_id):
    submission_id = cancel_unresolved_review_submissions()
    if submission_id == "submitted":
        return
    if not submission_id:
        response, body = api_json("POST", "/reviewSubmissions", json={
            "data": {
                "type": "reviewSubmissions",
                "attributes": {"platform": "IOS"},
                "relationships": {"app": {"data": {"type": "apps", "id": APP_ID}}},
            }
        })
        if response.status_code not in (200, 201):
            raise RuntimeError(f"Review submission create failed {response.status_code}: {response.text[:1200]}")
        submission_id = body["data"]["id"]
    print(f"Review submission: {submission_id}")

    for attempt in range(1, 21):
        response = api("POST", "/reviewSubmissionItems", json={
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
                time.sleep(60)
                continue
            if "ITEM_PART_OF_ANOTHER_SUBMISSION" in response.text:
                match = re.search(r"reviewSubmission with id ([0-9a-f-]+)", response.text)
                if match:
                    finish_review_submission(match.group(1))
                    return
            raise RuntimeError(f"Review item blocked: {response.text[:4000]}")
        time.sleep(30)
    finish_review_submission(submission_id)


def finish_review_submission(submission_id):
    for attempt in range(1, 31):
        response, body = api_json("PATCH", f"/reviewSubmissions/{submission_id}", json={
            "data": {"type": "reviewSubmissions", "id": submission_id, "attributes": {"submitted": True}}
        })
        if response.status_code == 200:
            print(f"Submitted for App Review: {body['data']['attributes']['state']}")
            return
        print(f"Review submit {attempt}/30: {response.status_code} {response.text[:500]}")
        time.sleep(60)
    raise RuntimeError(f"Review submit failed: {response.status_code} {response.text[:1200]}")


def main():
    response, body = api_json("GET", f"/apps/{APP_ID}")
    if response.status_code != 200:
        raise RuntimeError(f"App lookup failed {response.status_code}: {response.text[:1200]}")
    attrs = body["data"]["attributes"]
    print(f"App: {attrs.get('name')} / {attrs.get('bundleId')}")

    version_id, state = find_or_create_version()
    if state in ("WAITING_FOR_REVIEW", "IN_REVIEW"):
        print(f"Already submitted: {state}")
        return
    ensure_release_prerequisites(version_id)
    update_metadata(version_id)
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
