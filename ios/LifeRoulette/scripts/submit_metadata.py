import hashlib
import os
import sys
import time

import jwt
import requests

KEY_ID = os.environ.get("ASC_KEY_ID")
ISSUER = os.environ.get("ASC_ISSUER_ID")
BUNDLE_ID = os.environ.get("APP_BUNDLE_ID", "com.tokyonasu.numberstory")
APP_ID = os.environ.get("APP_ID")
APP_NAME = os.environ.get("APP_NAME", "数字のお話")
APP_SKU = os.environ.get("APP_SKU", "numberstory")
APP_VERSION = os.environ.get("APP_VERSION", "1.0")
BUILD_NUMBER = os.environ.get("BUILD_NUMBER")
P8_PATH = os.environ.get("ASC_P8_PATH", "/tmp/asc_key.p8")
SCREENSHOT_DIR = "MarketingAssets/Screenshots"

SCREENSHOT_GROUPS = [
    ("APP_IPHONE_67", ["iphone69_01_home.png", "iphone69_02_name.png", "iphone69_03_choice.png", "iphone69_04_history.png"]),
    ("APP_IPHONE_65", ["iphone65_01_home.png", "iphone65_02_name.png", "iphone65_03_choice.png", "iphone65_04_history.png"]),
    ("APP_IPHONE_55", ["iphone55_01_home.png", "iphone55_02_name.png", "iphone55_03_choice.png", "iphone55_04_history.png"]),
    ("APP_IPAD_PRO_3GEN_129", ["ipad129_01_home.png", "ipad129_02_name.png", "ipad129_03_choice.png", "ipad129_04_history.png"]),
]

META = {
    "ja": {
        "description": """数字のお話は、日付、名前、迷っていることを数字に変えて、短い読み解きを返すアプリです。

1から9の数字には、それぞれ違う物語があります。今日の数字を見たり、名前から数字を出したり、迷った時のヒントとして読んだりできます。

結果は履歴に残せます。気に入った読み解きは共有できます。

占いとして気軽に楽しむためのアプリです。大事な判断は、あなたの状況に合わせて決めてください。""",
        "keywords": "数字,占い,数秘術,今日,名前,運勢,診断,ヒント,迷い,物語",
        "whatsNew": "初回リリースです。",
        "promotionalText": "日付や名前を数字に変えて、今の自分に合う短い物語を読みます。",
        "supportUrl": "https://snarfnet.github.io/",
        "marketingUrl": "https://snarfnet.github.io/",
    },
    "en-US": {
        "description": """Number Story turns dates, names, and questions into a simple 1-9 reading.

Use it for today's number, a name-based reading, or a small hint when you feel stuck. Results are saved in history and can be shared.

This app is made for light entertainment. Important decisions should still be based on your own situation.""",
        "keywords": "number,numerology,fortune,today,name,reading,hint,story,choice",
        "whatsNew": "Initial release.",
        "promotionalText": "Turn a date or name into a short number story.",
        "supportUrl": "https://snarfnet.github.io/",
        "marketingUrl": "https://snarfnet.github.io/",
    },
}


def validate_environment():
    missing = [name for name, value in {"ASC_KEY_ID": KEY_ID, "ASC_ISSUER_ID": ISSUER}.items() if not value]
    if missing:
        raise RuntimeError("Missing environment variables: " + ", ".join(missing))
    if not os.path.exists(P8_PATH):
        raise RuntimeError(f"ASC private key was not found: {P8_PATH}")
    for _, filenames in SCREENSHOT_GROUPS:
        for filename in filenames:
            path = os.path.join(SCREENSHOT_DIR, filename)
            if not os.path.exists(path):
                raise RuntimeError(f"Missing screenshot: {path}")


def make_token():
    now = int(time.time())
    with open(P8_PATH, encoding="utf-8") as file:
        private_key = file.read()
    return jwt.encode(
        {"iss": ISSUER, "iat": now, "exp": now + 1200, "aud": "appstoreconnect-v1"},
        private_key,
        algorithm="ES256",
        headers={"kid": KEY_ID},
    )


def headers():
    return {"Authorization": f"Bearer {make_token()}", "Content-Type": "application/json"}


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
    if APP_ID:
        response, body = api_json("GET", f"/apps/{APP_ID}")
        if response.status_code != 200:
            raise RuntimeError(f"APP_ID lookup failed {response.status_code}: {response.text[:500]}")
        print(f"App found by APP_ID: {APP_ID}")
        return APP_ID

    response, body = api_json("GET", f"/apps?filter[bundleId]={BUNDLE_ID}")
    data = body.get("data", [])
    if data:
        app_id = data[0]["id"]
        print(f"App found: {app_id}")
        return app_id

    raise RuntimeError(
        "App Store Connect app record was not found for "
        f"{BUNDLE_ID}. Create the app in App Store Connect first, or set APP_ID to the existing app id."
    )


def find_or_create_version(app_id):
    for version in list_all(f"/apps/{app_id}/appStoreVersions?filter[platform]=IOS&limit=200"):
        attrs = version.get("attributes", {})
        if attrs.get("versionString") == APP_VERSION:
            state = attrs.get("appStoreState")
            print(f"Version found: {version['id']} state={state}")
            return version["id"], state

    payload = {
        "data": {
            "type": "appStoreVersions",
            "attributes": {"platform": "IOS", "versionString": APP_VERSION},
            "relationships": {"app": {"data": {"type": "apps", "id": app_id}}},
        }
    }
    response, body = api_json("POST", "/appStoreVersions", json=payload)
    if response.status_code not in (200, 201):
        raise RuntimeError(f"Version create failed {response.status_code}: {response.text[:500]}")
    version_id = body["data"]["id"]
    print(f"Version created: {version_id}")
    return version_id, "PREPARE_FOR_SUBMISSION"


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
        response = api(
            "PATCH",
            f"/appStoreVersionLocalizations/{loc['id']}",
            json={
                "data": {
                    "type": "appStoreVersionLocalizations",
                    "id": loc["id"],
                    "attributes": meta,
                }
            },
        )
        if response.status_code == 409 and "whatsNew" in meta:
            meta = {key: value for key, value in meta.items() if key != "whatsNew"}
            response = api(
                "PATCH",
                f"/appStoreVersionLocalizations/{loc['id']}",
                json={
                    "data": {
                        "type": "appStoreVersionLocalizations",
                        "id": loc["id"],
                        "attributes": meta,
                    }
                },
            )
        print(f"Metadata {locale}: {response.status_code}")
        if response.status_code not in (200, 201):
            raise RuntimeError(f"Metadata failed {locale}: {response.text[:500]}")


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
                    raise RuntimeError(f"Screenshot set create failed {response.status_code}: {response.text[:500]}")
                set_id = body["data"]["id"]
            for screenshot in list_all(f"/appScreenshotSets/{set_id}/appScreenshots?limit=200"):
                api("DELETE", f"/appScreenshots/{screenshot['id']}")
            for filename in filenames:
                upload_screenshot(set_id, filename)


def upload_screenshot(set_id, filename):
    path = os.path.join(SCREENSHOT_DIR, filename)
    with open(path, "rb") as file:
        data = file.read()
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
    if response.status_code not in (200, 201):
        raise RuntimeError(f"Screenshot upload failed {filename}: {response.text[:500]}")


def wait_for_build(app_id):
    if not BUILD_NUMBER:
        raise RuntimeError("BUILD_NUMBER is required to attach a build.")
    for attempt in range(90):
        response, body = api_json(
            "GET",
            f"/builds?filter[app]={app_id}&filter[version]={BUILD_NUMBER}&filter[processingState]=VALID&limit=1",
        )
        if body.get("data"):
            build_id = body["data"][0]["id"]
            print(f"Build ready: {build_id}")
            return build_id
        print(f"Waiting for build processing... {attempt + 1}/90")
        time.sleep(30)
    raise RuntimeError(f"Build {BUILD_NUMBER} did not finish processing")


def assign_build(version_id, build_id):
    api(
        "PATCH",
        f"/builds/{build_id}",
        json={"data": {"type": "builds", "id": build_id, "attributes": {"usesNonExemptEncryption": False}}},
    )
    response = api(
        "PATCH",
        f"/appStoreVersions/{version_id}/relationships/build",
        json={"data": {"type": "builds", "id": build_id}},
    )
    print(f"Build assigned: {response.status_code}")
    if response.status_code not in (200, 204):
        raise RuntimeError(f"Build assign failed {response.status_code}: {response.text[:500]}")


def submit_app_store_version(version_id):
    response = api(
        "POST",
        "/appStoreVersionSubmissions",
        json={
            "data": {
                "type": "appStoreVersionSubmissions",
                "relationships": {
                    "appStoreVersion": {
                        "data": {"type": "appStoreVersions", "id": version_id}
                    }
                },
            }
        },
    )
    print(f"App Store version submission: {response.status_code}")
    return response


def submit_for_review(app_id, version_id):
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
    if response.status_code != 201:
        raise RuntimeError(f"Review submission create failed {response.status_code}: {response.text[:500]}")
    submission_id = body["data"]["id"]

    item_created = False
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
            item_created = True
            break
        time.sleep(30)
    if not item_created:
        print("Review item was not created separately; continuing because appStoreVersionForReview is set.")

    response, body = api_json(
        "PATCH",
        f"/reviewSubmissions/{submission_id}",
        json={"data": {"type": "reviewSubmissions", "id": submission_id, "attributes": {"submitted": True}}},
    )
    if response.status_code != 200:
        raise RuntimeError(f"Review submit failed {response.status_code}: {response.text[:500]}")
    print(f"Submitted for App Review: {body['data']['attributes']['state']}")


def main():
    validate_environment()
    app_id = find_app_id()
    version_id, state = find_or_create_version(app_id)
    update_metadata(version_id)

    if os.environ.get("PREPARE_APP_ONLY") == "1":
        print("App Store Connect metadata is ready.")
        return

    if state in ("WAITING_FOR_REVIEW", "IN_REVIEW"):
        print(f"Already submitted: {state}")
        return

    build_id = wait_for_build(app_id)
    upload_screenshots(version_id)
    print("Waiting for screenshot processing...")
    time.sleep(300)
    assign_build(version_id, build_id)
    response = submit_app_store_version(version_id)
    if response.status_code in (200, 201):
        print("Submitted for App Review via appStoreVersionSubmissions.")
        return
    submit_for_review(app_id, version_id)


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        print(str(error), file=sys.stderr)
        sys.exit(1)
