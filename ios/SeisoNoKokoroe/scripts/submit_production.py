import hashlib
import os
import sys
import time

import jwt
import requests

KEY_ID = os.environ["ASC_KEY_ID"]
ISSUER = os.environ["ASC_ISSUER_ID"]
BUNDLE_ID = os.environ.get("APP_BUNDLE_ID", "com.tokyonasu.seisonokokoroe")
APP_NAME = os.environ.get("APP_NAME", "\u6e05\u6383\u306e\u5fc3\u5f97")
APP_SKU = os.environ.get("APP_SKU", "seisonokokoroe")
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
    ("APP_IPHONE_67", "iphone67", 3),
    ("APP_IPHONE_65", "iphone65", 3),
    ("APP_IPHONE_55", "iphone55", 3),
    ("APP_IPAD_PRO_3GEN_129", "ipad129", 3),
]

META = {
    "ja": {
        "description": (
            "\u6383\u9664\u306e\u8c46\u77e5\u8b58\u3092\u30bf\u30a4\u30d7\u30e9\u30a4\u30bf\u30fc\u98a8\u306b\u8868\u793a\u3002\n\n"
            "\u98a8\u6c34\u3067\u4eca\u65e5\u306e\u6383\u9664\u5834\u6240\u3068\u5409\u65b9\u89d2\u3092\u63d0\u6848\u3002"
            "\u30db\u30a6\u30ad\u91dd\u30bf\u30a4\u30de\u30fc\u3067\u77ed\u6642\u9593\u96c6\u4e2d\u6383\u9664\u3002\n\n"
            "\u30ad\u30c3\u30c1\u30f3\u30fb\u6d74\u5ba4\u30fb\u30c8\u30a4\u30ec\u30fb\u7384\u95a2\u30fb\u30ea\u30d3\u30f3\u30b0\u306a\u3069"
            "\u5834\u6240\u5225\u306b\u691c\u7d22\u3067\u304d\u307e\u3059\u3002\n\n"
            "\u521d\u7d1a\u30fb\u4e2d\u7d1a\u30fb\u4e0a\u7d1a\u306e\u96e3\u6613\u5ea6\u4ed8\u304d\u3002"
            "\u6240\u8981\u6642\u9593\u3082\u8868\u793a\u3055\u308c\u308b\u306e\u3067\u3001\u30b9\u30ad\u30de\u6642\u9593\u306b\u3074\u3063\u305f\u308a\u3002"
        ),
        "keywords": "\u6383\u9664,\u8c46\u77e5\u8b58,\u98a8\u6c34,\u30bf\u30a4\u30de\u30fc,\u30ad\u30c3\u30c1\u30f3,\u6d74\u5ba4,\u30c8\u30a4\u30ec,\u7384\u95a2,\u6383\u9664\u6a5f,\u30d2\u30f3\u30c8",
        "whatsNew": "\u306f\u3058\u3081\u3066\u306e\u30ea\u30ea\u30fc\u30b9\u3067\u3059\u3002",
        "promotionalText": "\u6383\u9664\u306e\u8c46\u77e5\u8b58\u3001\u98a8\u6c34\u3001\u30bf\u30a4\u30de\u30fc\u3092\u3072\u3068\u3064\u306b\u3002",
    },
    "en-US": {
        "description": (
            "Cleaning tips displayed in a typewriter style.\n\n"
            "Feng shui suggests today's cleaning spot and lucky direction. "
            "Use the broom-hand timer for focused short cleaning sessions.\n\n"
            "Search by area: kitchen, bathroom, toilet, entrance, living room. "
            "Difficulty levels and time estimates included."
        ),
        "keywords": "cleaning,tips,feng shui,timer,kitchen,bathroom,toilet,housework,broom,hint",
        "whatsNew": "Initial release.",
        "promotionalText": "Cleaning tips, feng shui, and a broom timer in one app.",
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
    if response.status_code in (200, 201):
        return body["data"]["id"]
    raise RuntimeError(
        f"App not found and could not create for {BUNDLE_ID}: {response.status_code} {response.text[:300]}"
    )


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
            "Cleaning tips app with daily cleaning suggestions and a broom-hand timer. No login required. "
            "This build fixes the launch issue and replaces screenshots with App Store images that do not include non-iOS status bars."
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
        for display_type, prefix, count in SCREENSHOT_GROUPS:
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
            for i in range(1, count + 1):
                upload_screenshot(set_id, f"{prefix}/{prefix}_{i:02d}.png")


def upload_screenshot(set_id, rel_path):
    path = os.path.join(SCREENSHOT_DIR, rel_path)
    if not os.path.exists(path):
        raise RuntimeError(f"Missing screenshot: {path}")
    data = open(path, "rb").read()
    checksum = hashlib.md5(data).hexdigest()
    filename = os.path.basename(rel_path)
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
    print(f"  {rel_path}: {response.status_code}")


def assign_build(version_id, build_id):
    api("PATCH", f"/builds/{build_id}", json={
        "data": {"type": "builds", "id": build_id, "attributes": {"usesNonExemptEncryption": False}}
    })
    response = api(
        "PATCH",
        f"/appStoreVersions/{version_id}/relationships/build",
        json={"data": {"type": "builds", "id": build_id}},
    )
    print(f"Build assigned: {response.status_code}")


def cancel_blocking_submissions(app_id):
    canceled = False
    response, body = api_json("GET", f"/apps/{app_id}/reviewSubmissions?limit=200")
    if response.status_code != 200:
        return
    for submission in body.get("data", []):
        submission_id = submission["id"]
        state = submission.get("attributes", {}).get("state")
        print(f"Review submission {submission_id}: {state}")
        if state in ("IN_REVIEW", "COMPLETE", "CANCELED"):
            continue
        response = api("PATCH", f"/reviewSubmissions/{submission_id}", json={
            "data": {
                "type": "reviewSubmissions",
                "id": submission_id,
                "attributes": {"canceled": True},
            }
        })
        print(f"Canceled {submission_id}: {response.status_code} {response.text[:300]}")
        canceled = True
    if canceled:
        print("Waiting for cancellation to propagate...")
        time.sleep(90)


def submit_for_review(app_id, version_id):
    cancel_blocking_submissions(app_id)
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
    last_item_error = ""
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
        last_item_error = response.text[:1000]
        print(last_item_error)
        time.sleep(30)
    else:
        raise RuntimeError(f"Review item create failed after 20 attempts: {last_item_error}")
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
