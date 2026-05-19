import hashlib
import os
import sys
import time

import jwt
import requests


KEY_ID = os.environ.get("ASC_KEY_ID", "WDXGY9WX55")
ISSUER = os.environ.get("ASC_ISSUER_ID", "2be0734f-943a-4d61-9dc9-5d9045c46fec")
BUNDLE_ID = os.environ.get("BUNDLE_ID", "com.tokyonasu.dailyangel")
APP_ID = os.environ.get("APP_ID")
APP_VERSION = os.environ.get("APP_VERSION", "1.0")
BUILD_NUMBER = sys.argv[1]
SCREENSHOT_DIR = "MarketingAssets/Screenshots"

SCREENSHOT_GROUPS = [
    ("APP_IPHONE_67", ["iphone67_01.png", "iphone67_02.png", "iphone67_03.png", "iphone67_04.png"]),
    ("APP_IPHONE_65", ["iphone65_01.png", "iphone65_02.png", "iphone65_03.png", "iphone65_04.png"]),
    ("APP_IPHONE_55", ["iphone55_01.png", "iphone55_02.png", "iphone55_03.png", "iphone55_04.png"]),
    ("APP_IPAD_PRO_3GEN_129", ["ipad129_01.png", "ipad129_02.png", "ipad129_03.png", "ipad129_04.png"]),
]

META = {
    "ja": {
        "description": (
            "天使の手紙は、毎日ひとつの短いメッセージを届ける内省アプリです。\n\n"
            "天使語風の言葉、日本語、英語を並べて表示します。"
            "光、夢、月、沈黙、心などのテーマから、今日の気持ちを整える言葉を読めます。\n\n"
            "主な機能:\n"
            "- 365日分のメッセージ\n"
            "- 天使語風、日本語、英語の3段表示\n"
            "- 今日の小さな行動\n"
            "- 気に入った手紙の保存\n"
            "- 毎朝のローカル通知\n\n"
            "未来を断定する占いではありません。静かに自分を整えるための小さな手紙です。"
        ),
        "keywords": "天使,メッセージ,日記,英語,癒し,内省,通知,言葉,夢,スピリチュアル",
        "whatsNew": "初回リリースです。",
    },
    "en-US": {
        "description": (
            "Daily Angel Letter gives you one short reflective message each day.\n\n"
            "Each letter appears in an angelic-inspired phrase, Japanese, and English. "
            "Read calm words around themes like light, dreams, the moon, silence, and the heart.\n\n"
            "Features:\n"
            "- 365 daily messages\n"
            "- Angelic-inspired, Japanese, and English text\n"
            "- One tiny daily action\n"
            "- Save favorite letters\n"
            "- Local morning reminders\n\n"
            "This app does not predict the future. It is a quiet daily letter for reflection."
        ),
        "keywords": "angel,message,daily,letter,journal,reflection,english,dream,calm,reminder",
        "whatsNew": "Initial release.",
    },
}


with open("/tmp/asc_key.p8", encoding="utf-8") as key_file:
    P8 = key_file.read()


def make_token():
    now = int(time.time())
    return jwt.encode(
        {"iss": ISSUER, "iat": now, "exp": now + 1200, "aud": "appstoreconnect-v1"},
        P8,
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
        time.sleep(15)
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
    response, body = api_json("GET", f"/apps?filter[bundleId]={BUNDLE_ID}")
    data = body.get("data", [])
    if not data:
        raise RuntimeError(
            f"App Store Connect app not found for {BUNDLE_ID}. "
            "Create the app record first, or set APP_ID."
        )
    app_id = data[0]["id"]
    print(f"App ID: {app_id}")
    return app_id


def find_or_create_version(app_id):
    for version in list_all(f"/apps/{app_id}/appStoreVersions?filter[platform]=IOS&limit=200"):
        attrs = version.get("attributes", {})
        if attrs.get("versionString") == APP_VERSION:
            print(f"Found version {APP_VERSION}: {version['id']} state={attrs.get('appStoreState')}")
            return version["id"], attrs.get("appStoreState")

    response, body = api_json(
        "POST",
        "/appStoreVersions",
        json={
            "data": {
                "type": "appStoreVersions",
                "attributes": {"platform": "IOS", "versionString": APP_VERSION},
                "relationships": {"app": {"data": {"type": "apps", "id": app_id}}},
            }
        },
    )
    if response.status_code not in (200, 201):
        raise RuntimeError(f"Create version failed {response.status_code}: {response.text[:500]}")
    created = body["data"]
    return created["id"], created["attributes"].get("appStoreState")


def wait_for_build(app_id):
    print(f"Waiting for build {BUILD_NUMBER} to become VALID...")
    for attempt in range(80):
        response, body = api_json(
            "GET",
            f"/builds?filter[app]={app_id}&filter[version]={BUILD_NUMBER}&filter[processingState]=VALID&limit=1",
        )
        if body.get("data"):
            build_id = body["data"][0]["id"]
            print(f"Build ready: {build_id}")
            return build_id
        print(f"Waiting... {attempt + 1}/80")
        time.sleep(30)
    raise RuntimeError("Build did not become VALID within 40 minutes.")


def ensure_localizations(version_id):
    localizations = list_all(f"/appStoreVersions/{version_id}/appStoreVersionLocalizations?limit=200")
    existing = {item["attributes"]["locale"]: item for item in localizations}

    for locale, meta in META.items():
        if locale not in existing:
            response, body = api_json(
                "POST",
                "/appStoreVersionLocalizations",
                json={
                    "data": {
                        "type": "appStoreVersionLocalizations",
                        "attributes": {"locale": locale},
                        "relationships": {
                            "appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}}
                        },
                    }
                },
            )
            if response.status_code in (200, 201):
                existing[locale] = body["data"]

        if locale in existing:
            loc_id = existing[locale]["id"]
            response = api(
                "PATCH",
                f"/appStoreVersionLocalizations/{loc_id}",
                json={
                    "data": {
                        "type": "appStoreVersionLocalizations",
                        "id": loc_id,
                        "attributes": {
                            **meta,
                            "marketingUrl": "https://snarfnet.github.io/",
                        },
                    }
                },
            )
            print(f"Localization {locale}: {response.status_code}")

    return list(existing.values())


def upload_screenshot(set_id, filename):
    path = os.path.join(SCREENSHOT_DIR, filename)
    if not os.path.exists(path):
        raise RuntimeError(f"Missing screenshot: {path}")

    data = open(path, "rb").read()
    checksum = hashlib.md5(data).hexdigest()
    response, body = api_json(
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
    if response.status_code not in (200, 201):
        raise RuntimeError(f"Screenshot create failed {response.status_code}: {response.text[:500]}")

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


def upload_screenshots(version_id):
    for loc in ensure_localizations(version_id):
        print(f"Screenshots for {loc['attributes']['locale']}")
        sets = list_all(f"/appStoreVersionLocalizations/{loc['id']}/appScreenshotSets?limit=200")
        existing = {item["attributes"]["screenshotDisplayType"]: item["id"] for item in sets}

        for display_type, filenames in SCREENSHOT_GROUPS:
            set_id = existing.get(display_type)
            if not set_id:
                response, body = api_json(
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
                if response.status_code not in (200, 201):
                    raise RuntimeError(f"Screenshot set create failed {response.status_code}: {response.text[:500]}")
                set_id = body["data"]["id"]

            for screenshot in list_all(f"/appScreenshotSets/{set_id}/appScreenshots?limit=200"):
                api("DELETE", f"/appScreenshots/{screenshot['id']}")
            for filename in filenames:
                upload_screenshot(set_id, filename)


def assign_build(version_id, build_id):
    response = api(
        "PATCH",
        f"/builds/{build_id}",
        json={"data": {"type": "builds", "id": build_id, "attributes": {"usesNonExemptEncryption": False}}},
    )
    print(f"Export compliance: {response.status_code}")

    response = api(
        "PATCH",
        f"/appStoreVersions/{version_id}/relationships/build",
        json={"data": {"type": "builds", "id": build_id}},
    )
    if response.status_code not in (200, 204):
        raise RuntimeError(f"Build assign failed {response.status_code}: {response.text[:500]}")
    print("Build assigned")


def submit_for_review(app_id, version_id):
    for state in ("UNRESOLVED_ISSUES", "READY_FOR_REVIEW"):
        response, body = api_json("GET", f"/apps/{app_id}/reviewSubmissions?filter[state]={state}&limit=200")
        if response.status_code == 200:
            for submission in body.get("data", []):
                api(
                    "PATCH",
                    f"/reviewSubmissions/{submission['id']}",
                    json={
                        "data": {
                            "type": "reviewSubmissions",
                            "id": submission["id"],
                            "attributes": {"canceled": True},
                        }
                    },
                )

    response, body = api_json(
        "POST",
        "/reviewSubmissions",
        json={
            "data": {
                "type": "reviewSubmissions",
                "attributes": {"platform": "IOS"},
                "relationships": {"app": {"data": {"type": "apps", "id": app_id}}},
            }
        },
    )
    if response.status_code not in (200, 201):
        raise RuntimeError(f"Review submission create failed {response.status_code}: {response.text[:500]}")

    submission_id = body["data"]["id"]
    for attempt in range(12):
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
        print(f"Add review item {attempt + 1}: {response.status_code}")
        if response.status_code in (200, 201):
            break
        time.sleep(20)
    else:
        raise RuntimeError(f"Review item create failed: {response.text[:500]}")

    response, body = api_json(
        "PATCH",
        f"/reviewSubmissions/{submission_id}",
        json={"data": {"type": "reviewSubmissions", "id": submission_id, "attributes": {"submitted": True}}},
    )
    if response.status_code != 200:
        raise RuntimeError(f"Review submit failed {response.status_code}: {response.text[:500]}")
    print(f"Submitted for review: {submission_id} / {body['data']['attributes']['state']}")


def main():
    app_id = find_app_id()
    version_id, state = find_or_create_version(app_id)
    if state in ("WAITING_FOR_REVIEW", "IN_REVIEW"):
        print(f"Already submitted: {state}")
        return
    build_id = wait_for_build(app_id)
    ensure_localizations(version_id)
    upload_screenshots(version_id)
    print("Waiting 5 minutes for screenshot processing...")
    time.sleep(300)
    assign_build(version_id, build_id)
    submit_for_review(app_id, version_id)


if __name__ == "__main__":
    main()
