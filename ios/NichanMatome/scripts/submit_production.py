import hashlib
import os
import sys
import time

import jwt
import requests

KEY_ID = os.environ["ASC_KEY_ID"]
ISSUER_ID = os.environ["ASC_ISSUER_ID"]
APP_ID = os.environ.get("APP_ID", "6769196238")
APP_VERSION = os.environ.get("APP_VERSION", "1.0")
BUILD_NUMBER = os.environ.get("BUILD_NUMBER")
P8_PATH = os.environ.get("ASC_P8_PATH", "/tmp/asc_key.p8")
SCREENSHOT_DIR = "MarketingAssets/Screenshots"

SCREENSHOT_GROUPS = [
    ("APP_IPHONE_67", ["iphone67_01_home.png", "iphone67_02_insights.png", "iphone67_03_sources.png"]),
]

META = {
    "ja": {
        "description": """まとめ・よみきりは、1000件のRSS配信元から届く記事を、ただ並べずに読みやすく整理するアプリです。

話題クラスタ、3分まとめ、偏りメーター、NG疲れワード、読後メモで、情報の洪水から今読む順番を作れます。

記事本文は元サイトで開きます。アプリ内では見出し、要約、配信元、リンクを扱い、自分用の保存やメモを端末内に残せます。""",
        "keywords": "まとめ,RSS,ニュース,5ch,2ch,話題,あとで読む,メモ,フィルター,速報",
        "whatsNew": "初回リリースです。",
        "promotionalText": "1000ソースを、3分で読める順番に。",
    },
    "en-US": {
        "description": """Matome Yomikiri organizes a large set of Japanese RSS sources into a calmer reading flow.

Use topic clusters, a three-minute digest, category balance, fatigue-word filtering, and personal notes to decide what to read next.

Articles open on their original websites. The app stores headlines, summaries, links, saved items, and your private notes on device.""",
        "keywords": "rss,news,reader,japan,topics,digest,bookmark,notes,filter,headlines",
        "whatsNew": "Initial release.",
        "promotionalText": "Turn 1000 sources into a readable flow.",
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
            raise RuntimeError(f"List failed {response.status_code}: {response.text[:500]}")
        rows.extend(body.get("data", []))
        next_url = body.get("links", {}).get("next")
        next_path = next_url.split("/v1", 1)[1] if next_url else None
    return rows


def find_or_create_version():
    for version in list_all(f"/apps/{APP_ID}/appStoreVersions?filter[platform]=IOS&limit=200"):
        attrs = version.get("attributes", {})
        if attrs.get("versionString") == APP_VERSION:
            print(f"Found version {APP_VERSION}: {version['id']} state={attrs.get('appStoreState')}")
            return version["id"]

    response, body = api_json("POST", "/appStoreVersions", json={
        "data": {
            "type": "appStoreVersions",
            "attributes": {"platform": "IOS", "versionString": APP_VERSION},
            "relationships": {"app": {"data": {"type": "apps", "id": APP_ID}}},
        }
    })
    if response.status_code not in (200, 201):
        raise RuntimeError(f"Version create failed {response.status_code}: {response.text[:500]}")
    return body["data"]["id"]


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
            "data": {
                "type": "appStoreVersionLocalizations",
                "id": loc["id"],
                "attributes": meta,
            }
        })
        if response.status_code == 409 and "whatsNew" in meta:
            meta = {key: value for key, value in meta.items() if key != "whatsNew"}
            response = api("PATCH", f"/appStoreVersionLocalizations/{loc['id']}", json={
                "data": {
                    "type": "appStoreVersionLocalizations",
                    "id": loc["id"],
                    "attributes": meta,
                }
            })
        print(f"Metadata {locale}: {response.status_code}")


def ensure_review_detail(version_id):
    response, body = api_json("GET", f"/appStoreVersions/{version_id}/appStoreReviewDetail")
    if response.status_code == 200 and body.get("data"):
        detail_id = body["data"]["id"]
        response = api("PATCH", f"/appStoreReviewDetails/{detail_id}", json={
            "data": {
                "type": "appStoreReviewDetails",
                "id": detail_id,
                "attributes": review_detail_attributes(),
            }
        })
        print(f"Review detail update: {response.status_code}")
        return

    response = api("POST", "/appStoreReviewDetails", json={
        "data": {
            "type": "appStoreReviewDetails",
            "attributes": review_detail_attributes(),
            "relationships": {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}}},
        }
    })
    print(f"Review detail create: {response.status_code}")


def review_detail_attributes():
    return {
        "contactFirstName": "Tokyo",
        "contactLastName": "Nasu",
        "contactPhone": "+1 844 209 0611",
        "contactEmail": "support@snarfnet.github.io",
        "demoAccountRequired": False,
        "notes": "No login is required. Articles open in Safari View Controller from RSS links.",
    }


def wait_for_build():
    if not BUILD_NUMBER:
        raise RuntimeError("BUILD_NUMBER is required.")
    for index in range(90):
        response, body = api_json(
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
    response = api("PATCH", f"/appScreenshots/{screenshot_id}", json={
        "data": {
            "type": "appScreenshots",
            "id": screenshot_id,
            "attributes": {"uploaded": True, "sourceFileChecksum": checksum},
        }
    })
    print(f"  {filename}: {response.status_code}")


def assign_build(version_id, build_id):
    api("PATCH", f"/builds/{build_id}", json={
        "data": {"type": "builds", "id": build_id, "attributes": {"usesNonExemptEncryption": False}}
    })
    response = api("PATCH", f"/appStoreVersions/{version_id}/relationships/build", json={
        "data": {"type": "builds", "id": build_id}
    })
    print(f"Build assigned: {response.status_code}")


def cancel_open_review_submissions():
    response, body = api_json("GET", f"/apps/{APP_ID}/reviewSubmissions?limit=20")
    if response.status_code != 200:
        return
    for submission in body.get("data", []):
        state = submission.get("attributes", {}).get("state")
        if state in ("READY_FOR_REVIEW", "WAITING_FOR_REVIEW"):
            response = api("PATCH", f"/reviewSubmissions/{submission['id']}", json={
                "data": {
                    "type": "reviewSubmissions",
                    "id": submission["id"],
                    "attributes": {"canceled": True},
                }
            })
            print(f"Canceled review submission {submission['id']}: {response.status_code}")


def submit_for_review(version_id):
    response, body = api_json("POST", "/reviewSubmissions", json={
        "data": {
            "type": "reviewSubmissions",
            "attributes": {"platform": "IOS"},
            "relationships": {"app": {"data": {"type": "apps", "id": APP_ID}}},
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
        time.sleep(30)
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
    response, body = api_json("GET", f"/apps/{APP_ID}")
    if response.status_code != 200:
        raise RuntimeError(f"App lookup failed {response.status_code}: {response.text[:500]}")
    attrs = body["data"]["attributes"]
    print(f"App: {attrs.get('name')} / {attrs.get('bundleId')}")

    version_id = find_or_create_version()
    ensure_review_detail(version_id)
    update_metadata(version_id)
    if os.environ.get("PREPARE_APP_ONLY") == "1":
        print("App Store Connect metadata is ready.")
        return

    build_id = wait_for_build()
    upload_screenshots(version_id)
    print("Waiting for screenshot processing...")
    time.sleep(300)
    assign_build(version_id, build_id)
    cancel_open_review_submissions()
    submit_for_review(version_id)


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        print(str(error), file=sys.stderr)
        sys.exit(1)
