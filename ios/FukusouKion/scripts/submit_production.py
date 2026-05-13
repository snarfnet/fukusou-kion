import hashlib
import os
import sys
import time

import jwt
import requests

KEY_ID = os.environ["ASC_KEY_ID"]
ISSUER = os.environ["ASC_ISSUER_ID"]
BUNDLE_ID = os.environ.get("APP_BUNDLE_ID", "com.tokyonasu.fukusoukion")
APP_NAME = os.environ.get("APP_NAME", "服装気温")
APP_SKU = os.environ.get("APP_SKU", "fukusoukion")
APP_VERSION = os.environ.get("APP_VERSION", "1.0")
BUILD_NUMBER = os.environ["BUILD_NUMBER"]
P8_PATH = os.environ.get("ASC_P8_PATH", "/tmp/asc_key.p8")
SCREENSHOT_DIR = "MarketingAssets/Screenshots"
REVIEW_CONTACT = {
    "contactFirstName": "Tokyo",
    "contactLastName": "Nasu",
    "contactEmail": "tokyonasu@yahoo.co.jp",
    "contactPhone": "+81 80-2368-9194",
}

SCREENSHOT_GROUPS = [
    ("APP_IPHONE_67", ["iphone69_01.png", "iphone69_02.png", "iphone69_03.png", "iphone69_04.png"]),
    ("APP_IPHONE_65", ["iphone65_01.png", "iphone65_02.png", "iphone65_03.png", "iphone65_04.png"]),
    ("APP_IPHONE_55", ["iphone55_01.png", "iphone55_02.png", "iphone55_03.png", "iphone55_04.png"]),
    ("APP_IPAD_PRO_3GEN_129", ["ipad129_01.png", "ipad129_02.png", "ipad129_03.png", "ipad129_04.png"]),
]

META = {
    "ja": {
        "description": "朝の服選びを、気温と天気からすばやく。\n\n服装気温は、今日の最高気温・最低気温・降水確率をもとに、女性向けの服装をシンプルに提案します。\n\n半袖、長袖、カーディガン、ジャケット、コートなど、その日の気温に合わせて確認できます。降水確率が高い日は、折りたたみ傘や普通の傘も提案。風が強い日やUV指数が高い日も、ひと目でわかります。\n\n朝7時、8時、9時から通知時間を選べるので、出かける前のチェックにも便利です。",
        "keywords": "服装,気温,天気,傘,降水確率,女性,コーデ,天気予報,UV,通知",
        "whatsNew": "はじめてのリリースです。",
        "promotionalText": "今日の気温に合わせて、服装と傘をすぐチェック。",
    },
    "en-US": {
        "description": "Pick today's outfit faster with weather-based suggestions.\n\nFukusou Kion shows the day's high and low temperature, rain chance, wind, and UV index, then suggests a simple outfit direction. It also recommends whether to bring a foldable umbrella or a full umbrella.\n\nChoose a morning reminder at 7, 8, or 9 AM.",
        "keywords": "outfit,weather,temperature,umbrella,forecast,women,uv,rain,clothes",
        "whatsNew": "Initial release.",
        "promotionalText": "Check today's outfit and umbrella before you leave.",
    },
}

p8 = open(P8_PATH, encoding="utf-8").read()


def token():
    now = int(time.time())
    payload = {"iss": ISSUER, "iat": now, "exp": now + 1200, "aud": "appstoreconnect-v1"}
    return jwt.encode(payload, p8, algorithm="ES256", headers={"kid": KEY_ID})


def headers():
    return {"Authorization": f"Bearer {token()}", "Content-Type": "application/json"}


def api(method, path, **kwargs):
    for _ in range(6):
        response = requests.request(
            method,
            f"https://api.appstoreconnect.apple.com/v1{path}",
            headers=headers(),
            timeout=120,
            **kwargs,
        )
        if response.status_code not in (401, 429, 500, 502, 503, 504):
            return response
        time.sleep(20)
    return response


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
            raise RuntimeError(f"List failed {response.status_code}: {response.text[:300]}")
        rows.extend(body.get("data", []))
        next_url = body.get("links", {}).get("next")
        next_path = next_url.split("/v1", 1)[1] if next_url else None
    return rows


def find_app_id():
    response, body = api_json("GET", f"/apps?filter[bundleId]={BUNDLE_ID}")
    data = body.get("data", [])
    if data:
        return data[0]["id"]

    payload = {
        "data": {
            "type": "apps",
            "attributes": {
                "bundleId": BUNDLE_ID,
                "name": APP_NAME,
                "primaryLocale": "ja",
                "sku": APP_SKU,
            },
        }
    }
    response, body = api_json("POST", "/apps", json=payload)
    if response.status_code not in (200, 201):
        raise RuntimeError(
            "App Store Connect app create failed. "
            f"Confirm the Bundle ID exists and WeatherKit is enabled: {response.status_code} {response.text[:300]}"
        )
    return body["data"]["id"]


def find_or_create_version(app_id):
    for version in list_all(f"/apps/{app_id}/appStoreVersions?filter[platform]=IOS&limit=200"):
        attrs = version.get("attributes", {})
        if attrs.get("versionString") == APP_VERSION:
            return version["id"], attrs.get("appStoreState")
    payload = {
        "data": {
            "type": "appStoreVersions",
            "attributes": {"platform": "IOS", "versionString": APP_VERSION},
            "relationships": {"app": {"data": {"type": "apps", "id": app_id}}},
        }
    }
    response, body = api_json("POST", "/appStoreVersions", json=payload)
    if response.status_code not in (200, 201):
        raise RuntimeError(f"Version create failed {response.status_code}: {response.text[:300]}")
    return body["data"]["id"], "PREPARE_FOR_SUBMISSION"


def wait_for_build(app_id):
    for i in range(90):
        response, body = api_json(
            "GET",
            f"/builds?filter[app]={app_id}&filter[version]={BUILD_NUMBER}&filter[processingState]=VALID&limit=1",
        )
        if body.get("data"):
            return body["data"][0]["id"]
        print(f"Waiting for build processing... {i + 1}/90")
        time.sleep(30)
    raise RuntimeError(f"Build {BUILD_NUMBER} did not finish processing")


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
        response, body = api_json("POST", "/appStoreVersionLocalizations", json=payload)
        if response.status_code in (200, 201):
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
        response = api("PATCH", f"/appStoreVersionLocalizations/{loc['id']}", json=payload)
        print(f"Metadata {locale}: {response.status_code}")


def update_review_detail(version_id):
    attrs = {
        **REVIEW_CONTACT,
        "demoAccountRequired": False,
        "demoAccountName": "",
        "demoAccountPassword": "",
        "notes": (
            "This build adds the AppTrackingTransparency permission request before Google Mobile Ads starts. "
            "The ATT prompt is shown shortly after launch, before ads are loaded."
        ),
    }
    response, body = api_json("GET", f"/appStoreVersions/{version_id}/appStoreReviewDetail")
    if response.status_code == 200 and body.get("data"):
        detail_id = body["data"]["id"]
        response = api("PATCH", f"/appStoreReviewDetails/{detail_id}", json={
            "data": {"type": "appStoreReviewDetails", "id": detail_id, "attributes": attrs}
        })
        print(f"Review detail: {response.status_code}")
        return
    payload = {
        "data": {
            "type": "appStoreReviewDetails",
            "attributes": attrs,
            "relationships": {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}}},
        }
    }
    response = api("POST", "/appStoreReviewDetails", json=payload)
    print(f"Review detail create: {response.status_code}")


def upload_screenshots(version_id):
    for loc in ensure_localizations(version_id):
        locale = loc["attributes"]["locale"]
        print(f"Screenshots for {locale}")
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
                response, body = api_json("POST", "/appScreenshotSets", json=payload)
                if response.status_code not in (200, 201):
                    raise RuntimeError(f"Screenshot set create failed: {response.text[:300]}")
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
    payload = {
        "data": {
            "type": "appScreenshots",
            "attributes": {"fileName": filename, "fileSize": len(data)},
            "relationships": {"appScreenshotSet": {"data": {"type": "appScreenshotSets", "id": set_id}}},
        }
    }
    response, body = api_json("POST", "/appScreenshots", json=payload)
    if response.status_code not in (200, 201):
        raise RuntimeError(f"Screenshot create failed {response.status_code}: {response.text[:300]}")
    screenshot_id = body["data"]["id"]
    for operation in body["data"]["attributes"]["uploadOperations"]:
        request_headers = {item["name"]: item["value"] for item in operation["requestHeaders"]}
        start = operation["offset"]
        end = start + operation["length"]
        requests.put(operation["url"], headers=request_headers, data=data[start:end], timeout=120)
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
    print(f"  {filename}: {response.status_code}")


def assign_build(version_id, build_id):
    api("PATCH", f"/builds/{build_id}", json={"data": {"type": "builds", "id": build_id, "attributes": {"usesNonExemptEncryption": False}}})
    response = api(
        "PATCH",
        f"/appStoreVersions/{version_id}/relationships/build",
        json={"data": {"type": "builds", "id": build_id}},
    )
    print(f"Build assigned: {response.status_code}")


def cancel_blocking_submissions(app_id):
    canceled = False
    for state in ("UNRESOLVED_ISSUES", "READY_FOR_REVIEW"):
        response, body = api_json("GET", f"/apps/{app_id}/reviewSubmissions?filter[state]={state}&limit=200")
        if response.status_code != 200:
            continue
        for submission in body.get("data", []):
            submission_id = submission["id"]
            response = api("PATCH", f"/reviewSubmissions/{submission_id}", json={
                "data": {
                    "type": "reviewSubmissions",
                    "id": submission_id,
                    "attributes": {"canceled": True},
                }
            })
            print(f"Canceled {submission_id}: {response.status_code}")
            canceled = True
    if canceled:
        print("Waiting for cancellation to propagate...")
        time.sleep(30)


def submit_for_review(app_id, version_id):
    response, body = api_json("POST", "/reviewSubmissions", json={
        "data": {
            "type": "reviewSubmissions",
            "attributes": {"platform": "IOS"},
            "relationships": {"app": {"data": {"type": "apps", "id": app_id}}},
        }
    })
    if response.status_code != 201:
        raise RuntimeError(f"Review submission create failed {response.status_code}: {response.text[:300]}")
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
        time.sleep(30)
    response, body = api_json("PATCH", f"/reviewSubmissions/{submission_id}", json={
        "data": {"type": "reviewSubmissions", "id": submission_id, "attributes": {"submitted": True}}
    })
    if response.status_code != 200:
        raise RuntimeError(f"Review submit failed {response.status_code}: {response.text[:300]}")
    print(f"Submitted for App Review: {body['data']['attributes']['state']}")


def main():
    app_id = find_app_id()
    if os.environ.get("PREPARE_APP_ONLY") == "1":
        find_or_create_version(app_id)
        print("App Store Connect app record is ready.")
        return

    version_id, state = find_or_create_version(app_id)
    if state in ("WAITING_FOR_REVIEW", "IN_REVIEW"):
        print(f"Already submitted: {state}")
        return
    build_id = wait_for_build(app_id)
    update_metadata(version_id)
    update_review_detail(version_id)
    upload_screenshots(version_id)
    print("Waiting for screenshot processing...")
    time.sleep(300)
    cancel_blocking_submissions(app_id)
    assign_build(version_id, build_id)
    submit_for_review(app_id, version_id)


if __name__ == "__main__":
    main()
