import hashlib
import os
import re
import sys
import time

import requests

from asc_helpers import api_json, fail, json_body, query


APP_ID = os.environ.get("APP_ID", "6777022273")
APP_VERSION = os.environ.get("APP_VERSION", "1.0")
BUILD_NUMBER = os.environ["BUILD_NUMBER"]
APP_PRICE_JPY = float(os.environ.get("APP_PRICE_JPY", "100"))
SCREENSHOT_DIR = "MarketingAssets/Screenshots"

SCREENSHOTS = [
    ("APP_IPHONE_67", ["iphone67_01_home.png", "iphone67_02_editor.png", "iphone67_03_prayer.png"]),
]

META = {
    "ja": {
        "description": "教会ノートは、礼拝メモ、説教メモ、聖書箇所、祈りの課題をまとめて残せるシンプルなノートアプリです。教会で聞いた言葉をすぐに書き、日付・牧師名・教会名・聖書箇所で整理できます。",
        "keywords": "教会,礼拝,説教,聖書,祈り,ノート,メモ,牧師,信仰,クリスチャン",
        "whatsNew": "初回リリースです。",
        "promotionalText": "礼拝、説教、祈りを一つの場所へ。",
        "marketingUrl": "https://snarfnet.github.io/",
        "supportUrl": "https://snarfnet.github.io/",
    },
    "en-US": {
        "description": "Church Notes is a simple notebook for worship services, sermon notes, Bible passages, and prayer requests. Write quickly during church, organize notes by date, pastor, church, and scripture, and revisit what you learned anytime.",
        "keywords": "church,sermon,bible,prayer,notes,journal,pastor,worship,faith,christian",
        "whatsNew": "Initial release.",
        "promotionalText": "Keep worship notes, sermons, and prayers in one place.",
        "marketingUrl": "https://snarfnet.github.io/",
        "supportUrl": "https://snarfnet.github.io/",
    },
}


def api(method, path, **kwargs):
    return api_json(method, path, **kwargs)


def list_all(path):
    rows = []
    next_path = path
    while next_path:
        body = api_json("GET", next_path)
        rows.extend(body.get("data", []))
        next_url = body.get("links", {}).get("next")
        next_path = next_url.split("/v1", 1)[1] if next_url else None
    return rows


def request(method, path, **kwargs):
    for attempt in range(6):
        response = requests.request(
            method,
            f"https://api.appstoreconnect.apple.com/v1{path}",
            headers=_headers(),
            timeout=120,
            **kwargs,
        )
        if response.status_code not in (401, 429, 500, 502, 503, 504):
            return response
        time.sleep(20)
    return response


def _headers():
    from asc_helpers import make_token

    return {"Authorization": f"Bearer {make_token()}", "Content-Type": "application/json"}


def response_json(method, path, **kwargs):
    response = request(method, path, **kwargs)
    try:
        body = response.json()
    except Exception:
        body = {}
    return response, body


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
        meta = META.get(locale, META["en-US"])
        payload = {
            "data": {
                "type": "appStoreVersionLocalizations",
                "id": loc["id"],
                "attributes": meta,
            }
        }
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
            "relationships": {"primaryCategory": {"data": {"type": "appCategories", "id": "PRODUCTIVITY"}}},
        }
    }
    response, _ = response_json("PATCH", f"/appInfos/{app_info_id}", json=payload)
    print(f"Primary category: {response.status_code}")
    update_age_rating(app_info_id)
    update_app_info_localizations(app_info_id)


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


def update_app_info_localizations(app_info_id):
    response, body = response_json("GET", f"/appInfos/{app_info_id}/appInfoLocalizations?limit=50")
    if response.status_code != 200:
        return
    for loc in body.get("data", []):
        locale = loc["attributes"].get("locale")
        subtitle = "礼拝、説教、祈りを残すノート" if locale == "ja" else "Sermons, prayers, Bible notes"
        payload = {
            "data": {
                "type": "appInfoLocalizations",
                "id": loc["id"],
                "attributes": {
                    "subtitle": subtitle,
                    "privacyPolicyUrl": "https://snarfnet.github.io/privacy.html",
                },
            }
        }
        response, _ = response_json("PATCH", f"/appInfoLocalizations/{loc['id']}", json=payload)
        print(f"App info {locale}: {response.status_code}")


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
    ensure_review_detail(version_id)


def ensure_price():
    response, body = response_json("GET", f"/apps/{APP_ID}/appPricePoints?filter[territory]=JPN&limit=200")
    points = body.get("data", []) if response.status_code == 200 else []
    if not points:
        print(f"Price skipped: {response.status_code}")
        return

    def price_value(point):
        attrs = point.get("attributes", {})
        value = attrs.get("customerPrice") or attrs.get("price") or attrs.get("equalizationsConsidered")
        try:
            return float(value)
        except Exception:
            return 10**9

    price_point = min(points, key=lambda item: abs(price_value(item) - APP_PRICE_JPY))
    price_id = price_point["id"]
    print(f"Selected JPN price point: {price_id} customerPrice={price_value(price_point)}")
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
            "attributes": {"startDate": "2026-06-05"},
            "relationships": {"appPricePoint": {"data": {"type": "appPricePoints", "id": price_id}}},
        }],
    }
    response, _ = response_json("POST", "/appPriceSchedules", json=payload)
    print(f"Price schedule: {response.status_code}")


def ensure_review_detail(version_id):
    attrs = {
        "contactFirstName": "Tokyo",
        "contactLastName": "Nasu",
        "contactPhone": "+1 844 209 0611",
        "contactEmail": "support@snarfnet.github.io",
        "demoAccountRequired": False,
        "notes": "ログイン不要です。広告、外部通信、トラッキングはありません。礼拝メモ、説教メモ、祈りの課題を端末内に保存します。",
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
    for index in range(10):
        response, body = response_json(
            "GET",
            f"/builds?filter[app]={APP_ID}&filter[version]={BUILD_NUMBER}&filter[processingState]=VALID&limit=1",
        )
        if body.get("data"):
            build_id = body["data"][0]["id"]
            print(f"Build ready: {build_id}")
            return build_id
        print(f"Waiting for build {BUILD_NUMBER}... {index + 1}/10")
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
                            "appStoreVersionLocalization": {
                                "data": {"type": "appStoreVersionLocalizations", "id": loc["id"]}
                            }
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
    path = os.path.join(SCREENSHOT_DIR, filename)
    if not os.path.exists(path):
        raise RuntimeError(f"Missing screenshot: {path}")
    data = open(path, "rb").read()
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
        headers = {item["name"]: item["value"] for item in operation["requestHeaders"]}
        start = operation["offset"]
        end = start + operation["length"]
        requests.put(operation["url"], headers=headers, data=data[start:end], timeout=120)
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


def submit_for_review(version_id):
    submission_id = None
    response, body = response_json("GET", f"/apps/{APP_ID}/reviewSubmissions?limit=20")
    if response.status_code == 200:
        for submission in body.get("data", []):
            state = submission.get("attributes", {}).get("state")
            if state == "READY_FOR_REVIEW":
                submission_id = submission["id"]
                break
    if not submission_id:
        response, body = response_json("POST", "/reviewSubmissions", json={
            "data": {
                "type": "reviewSubmissions",
                "attributes": {"platform": "IOS"},
                "relationships": {"app": {"data": {"type": "apps", "id": APP_ID}}},
            }
        })
        if response.status_code not in (200, 201):
            raise RuntimeError(f"Review submission create failed {response.status_code}: {response.text[:1000]}")
        submission_id = body["data"]["id"]

    for attempt in range(1, 6):
        response, _ = response_json("POST", "/reviewSubmissionItems", json={
            "data": {
                "type": "reviewSubmissionItems",
                "relationships": {
                    "reviewSubmission": {"data": {"type": "reviewSubmissions", "id": submission_id}},
                    "appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}},
                },
            }
        })
        print(f"Review item {attempt}/5: {response.status_code}")
        if response.status_code != 201:
            print(response.text[:2000])
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
        if response.status_code not in (200, 201, 409):
            raise RuntimeError(f"Review item failed {response.status_code}: {response.text[:1000]}")
        time.sleep(30)

    for attempt in range(1, 6):
        response, body = response_json("PATCH", f"/reviewSubmissions/{submission_id}", json={
            "data": {"type": "reviewSubmissions", "id": submission_id, "attributes": {"submitted": True}}
        })
        print(f"Review submit {attempt}/5: {response.status_code}")
        if response.status_code == 200:
            print(f"Submitted for App Review: {body['data']['attributes']['state']}")
            return
        print(response.text[:2000])
        time.sleep(60)
    raise RuntimeError(f"Review submit failed: {response.status_code} {response.text[:1000]}")


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
