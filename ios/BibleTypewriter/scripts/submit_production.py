import hashlib
import os
import re
import sys
import time
from decimal import Decimal, InvalidOperation

import jwt
import requests


KEY_ID = os.environ["ASC_KEY_ID"]
ISSUER_ID = os.environ["ASC_ISSUER_ID"]
APP_ID = os.environ.get("APP_ID")
APP_BUNDLE_ID = os.environ.get("APP_BUNDLE_ID", "com.tokyonasu.bibletypewriter")
APP_VERSION = os.environ.get("APP_VERSION", "1.0")
BUILD_NUMBER = os.environ.get("BUILD_NUMBER")
P8_PATH = os.environ.get("ASC_P8_PATH", "/tmp/asc_key.p8")
SCREENSHOT_DIR = "MarketingAssets/Screenshots"

SCREENSHOT_GROUPS = [
    ("APP_IPHONE_67", ["iphone67_01.png", "iphone67_02.png", "iphone67_03.png"]),
    ("APP_IPHONE_65", ["iphone65_01.png", "iphone65_02.png", "iphone65_03.png"]),
    ("APP_IPHONE_55", ["iphone55_01.png", "iphone55_02.png", "iphone55_03.png"]),
    ("APP_IPAD_PRO_3GEN_129", ["ipad129_01.png", "ipad129_02.png", "ipad129_03.png"]),
]

META = {
    "ja": {
        "description": """聖書のことばは、静かな背景の上に聖書本文を一文字ずつ流す読書アプリです。

口語訳、WEB、KJVを切り替えながら、創世記、詩篇、福音書などを落ち着いた画面で読めます。本文は白い文字でゆっくり表示され、上へ流れた文字は少しずつ薄れて消えます。章が終わると、ひと呼吸おいて次の章へ進みます。

背景は聖書の書巻に合わせて変わります。創世記には天地創造を思わせる星空、詩篇には静かな水辺、福音書には朝の湖畔、黙示録には雲と金色の光。派手な演出ではなく、読む時間を邪魔しない余白を大切にしました。

主な機能:
- 口語訳、WEB、KJVの切り替え
- 書名と章の選択
- タイポライター風の本文表示
- 一時停止、前の章、次の章、おまかせ選択
- 書巻カテゴリに合わせた背景
- iPhone SEからPro Maxまで読みやすい縦画面設計

祈りの前、眠る前、移動中の短い時間に。聖書のことばを、静かに眺めるためのアプリです。""",
        "keywords": "聖書,口語訳,KJV,WEB,祈り,詩篇,福音書,創世記,読書,キリスト教",
        "whatsNew": "初回リリースです。",
        "promotionalText": "聖書のことばが、静かな背景に一文字ずつ流れます。",
        "marketingUrl": "https://snarfnet.github.io/",
        "supportUrl": "https://snarfnet.github.io/",
    },
    "en-US": {
        "description": """Bible Typewriter is a quiet scripture reading app that displays Bible text one character at a time over calm, sacred backgrounds.

Switch between Kougo Japanese, WEB, and KJV, choose a book and chapter, then let the words flow slowly on screen. Text that reaches the top gently fades away, and when a chapter ends, the app pauses for a moment before moving to the next chapter.

Backgrounds change with the book category: a creation-like starry sky for Genesis, still water for Psalms, dawn by the lake for the Gospels, and soft golden clouds for Revelation. The design keeps the center calm and readable, with no loud effects.

Features:
- Kougo Japanese, WEB, and KJV
- Book and chapter selection
- Typewriter-style scripture display
- Pause, previous, next, and random chapter controls
- Backgrounds matched to Bible categories
- Portrait layout tuned for iPhone SE through Pro Max

Use it before prayer, before sleep, or whenever you want a slower way to sit with scripture.""",
        "keywords": "bible,scripture,kjv,web,japanese,prayer,psalms,gospel,genesis,reading",
        "whatsNew": "Initial release.",
        "promotionalText": "A quiet typewriter-style Bible reader.",
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
    last = None
    for _ in range(6):
        last = requests.request(
            method,
            f"https://api.appstoreconnect.apple.com/v1{path}",
            headers=headers(),
            timeout=120,
            **kwargs,
        )
        if last.status_code not in (401, 429, 500, 502, 503, 504):
            return last
        time.sleep(20)
    return last


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
            raise RuntimeError(f"List failed {response.status_code}: {response.text[:500]}")
        rows.extend(body.get("data", []))
        next_url = body.get("links", {}).get("next")
        next_path = next_url.split("/v1", 1)[1] if next_url else None
    return rows


def find_app_id():
    if APP_ID:
        return APP_ID
    response, body = api_json("GET", f"/apps?filter[bundleId]={APP_BUNDLE_ID}&limit=1")
    if response.status_code != 200 or not body.get("data"):
        raise RuntimeError(f"App not found for bundle ID: {APP_BUNDLE_ID}")
    return body["data"][0]["id"]


def find_or_create_version(app_id):
    for version in list_all(f"/apps/{app_id}/appStoreVersions?filter[platform]=IOS&limit=200"):
        attrs = version.get("attributes", {})
        if attrs.get("versionString") == APP_VERSION:
            print(f"Found version {APP_VERSION}: {version['id']} state={attrs.get('appStoreState')}")
            return version["id"], attrs.get("appStoreState")

    response, body = api_json("POST", "/appStoreVersions", json={
        "data": {
            "type": "appStoreVersions",
            "attributes": {"platform": "IOS", "versionString": APP_VERSION},
            "relationships": {"app": {"data": {"type": "apps", "id": app_id}}},
        }
    })
    if response.status_code not in (200, 201):
        raise RuntimeError(f"Version create failed {response.status_code}: {response.text[:500]}")
    data = body["data"]
    return data["id"], data["attributes"].get("appStoreState")


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
        if response.status_code in (200, 201):
            existing[locale] = body["data"]
    return list(existing.values())


def update_metadata(version_id):
    for loc in ensure_localizations(version_id):
        locale = loc["attributes"]["locale"]
        meta = META.get(locale, META["en-US"])
        response = api("PATCH", f"/appStoreVersionLocalizations/{loc['id']}", json={
            "data": {"type": "appStoreVersionLocalizations", "id": loc["id"], "attributes": meta}
        })
        if response.status_code == 409 and "whatsNew" in meta:
            fallback = {key: value for key, value in meta.items() if key != "whatsNew"}
            response = api("PATCH", f"/appStoreVersionLocalizations/{loc['id']}", json={
                "data": {"type": "appStoreVersionLocalizations", "id": loc["id"], "attributes": fallback}
            })
        print(f"Metadata {locale}: {response.status_code}")


def ensure_release_prerequisites(app_id, version_id):
    response = api("PATCH", f"/apps/{app_id}", json={
        "data": {
            "type": "apps",
            "id": app_id,
            "attributes": {"contentRightsDeclaration": "USES_THIRD_PARTY_CONTENT"},
        }
    })
    print(f"Content rights: {response.status_code}")

    response, body = api_json("GET", f"/apps/{app_id}/appInfos?limit=10")
    app_infos = body.get("data", []) if response.status_code == 200 else []
    if app_infos:
        app_info_id = app_infos[0]["id"]
        response = api("PATCH", f"/appInfos/{app_info_id}", json={
            "data": {
                "type": "appInfos",
                "id": app_info_id,
                "relationships": {
                    "primaryCategory": {"data": {"type": "appCategories", "id": "BOOKS"}}
                },
            }
        })
        print(f"Primary category: {response.status_code}")
        update_age_rating(app_info_id)
        update_app_info_localizations(app_info_id)

    response = api("PATCH", f"/appStoreVersions/{version_id}", json={
        "data": {
            "type": "appStoreVersions",
            "id": version_id,
            "attributes": {
                "copyright": "2026 Tokyo Nasu",
                "usesIdfa": False,
            },
        }
    })
    print(f"Version attributes: {response.status_code}")
    ensure_lowest_paid_price(app_id)
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
    response = api("PATCH", f"/ageRatingDeclarations/{app_info_id}", json={
        "data": {"type": "ageRatingDeclarations", "id": app_info_id, "attributes": attrs}
    })
    print(f"Age rating: {response.status_code}")


def update_app_info_localizations(app_info_id):
    response, body = api_json("GET", f"/appInfos/{app_info_id}/appInfoLocalizations?limit=20")
    if response.status_code != 200:
        return
    for loc in body.get("data", []):
        locale = loc["attributes"].get("locale")
        subtitle = "静かな聖書タイポライター" if locale == "ja" else "A quiet Bible typewriter"
        response = api("PATCH", f"/appInfoLocalizations/{loc['id']}", json={
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


def ensure_lowest_paid_price(app_id):
    points = list_all(f"/apps/{app_id}/appPricePoints?filter[territory]=USA&limit=200")
    paid = []
    for point in points:
        attrs = point.get("attributes", {})
        price = attrs.get("customerPrice")
        proceeds = attrs.get("proceeds")
        numeric = parse_price(price) or parse_price(proceeds)
        if numeric is not None and numeric > 0:
            paid.append((numeric, point))
    if not paid:
        raise RuntimeError("No paid App Store price point found.")

    paid.sort(key=lambda item: item[0])
    price_point = paid[0][1]
    price_value = paid[0][0]
    local_id = "${newprice-0}"
    payload = {
        "data": {
            "type": "appPriceSchedules",
            "attributes": {},
            "relationships": {
                "app": {"data": {"type": "apps", "id": app_id}},
                "baseTerritory": {"data": {"type": "territories", "id": "USA"}},
                "manualPrices": {"data": [{"type": "appPrices", "id": local_id}]},
            },
        },
        "included": [{
            "type": "appPrices",
            "id": local_id,
            "attributes": {"startDate": None},
            "relationships": {
                "appPricePoint": {"data": {"type": "appPricePoints", "id": price_point["id"]}}
            },
        }],
    }
    response = api("POST", "/appPriceSchedules", json=payload)
    print(f"Lowest paid price ({price_value}): {response.status_code}")
    if response.status_code not in (200, 201):
        print(response.text[:1200])


def parse_price(value):
    if value is None:
        return None
    try:
        return Decimal(str(value))
    except (InvalidOperation, ValueError):
        return None


def ensure_review_detail(version_id):
    attrs = {
        "contactFirstName": "Tokyo",
        "contactLastName": "Nasu",
        "contactPhone": "+1 844 209 0611",
        "contactEmail": "support@snarfnet.github.io",
        "demoAccountRequired": False,
        "notes": "ログイン不要です。口語訳、WEB、KJVを選び、書名と章を選択すると本文がタイポライター風に表示されます。有料アプリのため広告はありません。",
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


def wait_for_build(app_id):
    if not BUILD_NUMBER:
        raise RuntimeError("BUILD_NUMBER is required.")
    for index in range(90):
        response, body = api_json(
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
                    raise RuntimeError(f"Screenshot set create failed {response.status_code}: {response.text[:500]}")
                set_id = body["data"]["id"]
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
    response, body = api_json("POST", "/appScreenshots", json={
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
        request_headers = {item["name"]: item["value"] for item in operation["requestHeaders"]}
        start = operation["offset"]
        end = start + operation["length"]
        requests.put(operation["url"], headers=request_headers, data=data[start:end], timeout=120)
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
        print(f"  {filename}: upload confirm retry {attempt}/6 status={response.status_code}")
        time.sleep(20)
    print(f"  {filename}: {response.status_code}")


def assign_build(version_id, build_id):
    api("PATCH", f"/builds/{build_id}", json={
        "data": {"type": "builds", "id": build_id, "attributes": {"usesNonExemptEncryption": False}}
    })
    response = api("PATCH", f"/appStoreVersions/{version_id}/relationships/build", json={
        "data": {"type": "builds", "id": build_id}
    })
    print(f"Build assigned: {response.status_code}")


def cancel_open_review_submissions(app_id):
    response, body = api_json("GET", f"/apps/{app_id}/reviewSubmissions?limit=20")
    if response.status_code != 200:
        return
    for submission in body.get("data", []):
        state = submission.get("attributes", {}).get("state")
        if state in ("UNRESOLVED_ISSUES", "WAITING_FOR_REVIEW"):
            response = api("PATCH", f"/reviewSubmissions/{submission['id']}", json={
                "data": {
                    "type": "reviewSubmissions",
                    "id": submission["id"],
                    "attributes": {"canceled": True},
                }
            })
            print(f"Canceled review submission {submission['id']}: {response.status_code}")


def ready_review_submission_id(app_id):
    response, body = api_json("GET", f"/apps/{app_id}/reviewSubmissions?limit=20")
    if response.status_code != 200:
        return None
    for submission in body.get("data", []):
        if submission.get("attributes", {}).get("state") == "READY_FOR_REVIEW":
            return submission["id"]
    return None


def submit_for_review(app_id, version_id):
    cancel_open_review_submissions(app_id)
    submission_id = ready_review_submission_id(app_id)
    if not submission_id:
        response, body = api_json("POST", "/reviewSubmissions", json={
            "data": {
                "type": "reviewSubmissions",
                "attributes": {"platform": "IOS"},
                "relationships": {"app": {"data": {"type": "apps", "id": app_id}}},
            }
        })
        if response.status_code not in (200, 201):
            raise RuntimeError(f"Review submission create failed {response.status_code}: {response.text[:500]}")
        submission_id = body["data"]["id"]

    for attempt in range(20):
        response = api("POST", "/reviewSubmissionItems", json={
            "data": {
                "type": "reviewSubmissionItems",
                "relationships": {
                    "reviewSubmission": {"data": {"type": "reviewSubmissions", "id": submission_id}},
                    "appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}},
                },
            }
        })
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
    finish_review_submission(submission_id)


def finish_review_submission(submission_id):
    for attempt in range(1, 31):
        response, body = api_json("PATCH", f"/reviewSubmissions/{submission_id}", json={
            "data": {"type": "reviewSubmissions", "id": submission_id, "attributes": {"submitted": True}}
        })
        if response.status_code == 200:
            print(f"Submitted for App Review: {body['data']['attributes']['state']}")
            return
        print(f"Review submit {attempt}/30: {response.status_code}")
        time.sleep(60)
    raise RuntimeError(f"Review submit failed: {response.status_code} {response.text[:500]}")


def main():
    app_id = find_app_id()
    response, body = api_json("GET", f"/apps/{app_id}")
    if response.status_code != 200:
        raise RuntimeError(f"App lookup failed {response.status_code}: {response.text[:500]}")
    attrs = body["data"]["attributes"]
    print(f"App: {attrs.get('name')} / {attrs.get('bundleId')}")

    version_id, state = find_or_create_version(app_id)
    if state in ("WAITING_FOR_REVIEW", "IN_REVIEW"):
        print(f"Already submitted: {state}")
        return

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
