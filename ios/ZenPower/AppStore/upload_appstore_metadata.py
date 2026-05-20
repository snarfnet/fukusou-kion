#!/usr/bin/env python3
import hashlib
import os
import sys
import time
from pathlib import Path

import jwt
import requests


BASE_URL = "https://api.appstoreconnect.apple.com/v1"
APP_ID = os.environ.get("APP_ID", "6771141622")
APP_VERSION = os.environ.get("APP_VERSION", "1.0")
BUILD_NUMBER = os.environ.get("BUILD_NUMBER", "6")
KEY_ID = os.environ["ASC_KEY_ID"]
ISSUER_ID = os.environ["ASC_ISSUER_ID"]
P8_PATH = Path(os.environ.get("ASC_P8_PATH", "/tmp/asc_key.p8"))
SCREENSHOT_ROOT = Path("MarketingAssets/Screenshots/iphone_69")
SCREENSHOT_DISPLAY_TYPE = "APP_IPHONE_67"

META = {
    "ja": {
        "description": """禅パワーは、座禅と呼吸を毎日の小さな習慣にするためのアプリです。

忙しい日でも、ほんの数分だけ静かに座る時間を作る。息を整え、姿勢を整え、浮かんでくる考えに気づき、また今に戻る。禅パワーは、その流れを画像つきの説明とシンプルな練習画面で支えます。

はじめて座禅に触れる人でも使いやすいように、難しい言葉をできるだけ避けました。画面を見れば、姿勢の作り方、呼吸の向け方、考えが出てきた時の扱い方を順番に確認できます。長い学習よりも、まず座ってみることを大切にしています。

主な内容:

・座禅タイマー
短い時間から練習を始められます。日々の状態に合わせて、無理なく座る時間を選べます。

・呼吸ガイド
吸う、吐く、静かに待つ。この流れを落ち着いた画面で確認しながら、呼吸へ意識を戻せます。

・画像つきレッスン
姿勢、目線、手の形、呼吸、雑念との向き合い方を、わかりやすい画像と短い説明で学べます。

・今日の禅ことば
練習前や一日の途中に読み返せる、短い禅の言葉を収録しています。気持ちを切り替えるきっかけとして使えます。

・練習記録
座った日、時間、気づきを残せます。続けた日々が見えるので、自分のペースをつかみやすくなります。

・日本語と英語に対応
国内向けにも海外向けにも使いやすい表示を用意しています。

こんな時に使えます:

・朝、仕事や学校の前に頭をすっきりさせたい時
・昼の休憩中に、気持ちをいったん落ち着けたい時
・考えすぎている自分に気づき、呼吸へ戻りたい時
・眠る前に、画面を見すぎた状態から静かな時間へ移りたい時
・座禅を始めたいけれど、何から試せばいいか迷っている時

続けるコツは、長く座ることではなく、今日も一度座ることです。禅パワーでは、短い練習から始めて、記録を残しながら自分のペースを作れます。うまく集中できない日があっても大丈夫です。気づいて、呼吸に戻る。その繰り返しが練習になります。

禅パワーは、完璧な瞑想を目指すアプリではありません。大切なのは、今日の自分の状態に気づき、少しだけ静かな時間を持つことです。集中したい朝、気持ちを整えたい昼、眠る前の落ち着いた時間にも使えます。

広告はバナーのみです。座禅中に全画面広告で練習を止めることはありません。""",
        "keywords": "禅,座禅,瞑想,呼吸,マインドフルネス,習慣,日記,リラックス,集中,睡眠",
        "whatsNew": "初回リリースです。座禅タイマー、呼吸ガイド、画像つきレッスン、練習記録を使えます。",
        "promotionalText": "座禅と呼吸を、毎日の小さな習慣に。画像つきでわかりやすく学べます。",
        "supportUrl": "https://snarfnet.github.io/",
        "marketingUrl": "https://snarfnet.github.io/",
        "subtitle": "座禅と呼吸を毎日の習慣に",
        "privacyPolicyUrl": "https://snarfnet.github.io/privacy.html",
        "screenshots": [
            "ja/01-home.png",
            "ja/02-zazen.png",
            "ja/03-learn.png",
            "ja/04-log.png",
        ],
    },
    "en-US": {
        "description": """Zen Power helps you turn zazen and breathing into a small daily habit.

Even a busy day can hold a few quiet minutes. Sit down, settle your posture, follow your breath, notice thoughts as they appear, and gently return to the present moment. Zen Power supports that simple rhythm with visual lessons, calm practice screens, and a lightweight practice log.

The app is designed for beginners. It avoids complicated language and focuses on what you can try right away: how to sit, where to place your attention, how to breathe, and what to do when your mind gets noisy. Instead of reading a long manual before you begin, you can open the app, choose a short session, and start sitting.

Main features:

・Zazen timer
Start with a short session and build your practice at your own pace.

・Breathing guide
Use a calm visual rhythm to come back to your inhale, exhale, and quiet pause.

・Visual lessons
Learn posture, gaze, hand position, breathing, and how to work with wandering thoughts through clear images and short explanations.

・Daily Zen words
Read a simple phrase before practice, during a break, or at the end of the day.

・Practice log
Record when you sat, how long you practiced, and what you noticed. Seeing your sessions makes it easier to keep going without pressure.

・Japanese and English support
Use Zen Power in either language, whether you are practicing in Japan or overseas.

Zen Power is not about perfect meditation. It is about making room for a quiet reset. Use it in the morning before work, during a midday pause, after a stressful moment, or before sleep.

Ads are banner-only. Your sitting practice is not interrupted by full-screen ads.""",
        "keywords": "zen,zazen,meditation,breathing,mindfulness,habit,journal,calm,focus,relax",
        "whatsNew": "Initial release with a zazen timer, breathing guide, visual lessons, and practice log.",
        "promotionalText": "Make zazen and breathing a small daily habit with clear visual guidance.",
        "supportUrl": "https://snarfnet.github.io/",
        "marketingUrl": "https://snarfnet.github.io/",
        "subtitle": "Zazen and breathing practice",
        "privacyPolicyUrl": "https://snarfnet.github.io/privacy.html",
        "screenshots": [
            "en/01-home.png",
            "en/02-zazen.png",
            "en/03-learn.png",
            "en/04-log.png",
        ],
    },
}


def make_token():
    now = int(time.time())
    return jwt.encode(
        {"iss": ISSUER_ID, "iat": now, "exp": now + 1200, "aud": "appstoreconnect-v1"},
        P8_PATH.read_text(encoding="utf-8"),
        algorithm="ES256",
        headers={"kid": KEY_ID},
    )


def headers():
    return {"Authorization": f"Bearer {make_token()}", "Content-Type": "application/json"}


def api(method, path, **kwargs):
    last_response = None
    for _ in range(6):
        last_response = requests.request(method, f"{BASE_URL}{path}", headers=headers(), timeout=120, **kwargs)
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
    if response.status_code not in (200, 201, 204):
        raise RuntimeError(f"{method} {path} failed {response.status_code}: {response.text[:800]}")
    return body


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
    versions = list_all(f"/apps/{APP_ID}/appStoreVersions?filter[platform]=IOS&limit=200")
    for version in versions:
        attrs = version.get("attributes", {})
        if attrs.get("versionString") == APP_VERSION:
            print(f"Found version {APP_VERSION}: {version['id']} state={attrs.get('appStoreState')}")
            return version["id"]

    body = api_json("POST", "/appStoreVersions", json={
        "data": {
            "type": "appStoreVersions",
            "attributes": {"platform": "IOS", "versionString": APP_VERSION},
            "relationships": {"app": {"data": {"type": "apps", "id": APP_ID}}},
        }
    })
    version_id = body["data"]["id"]
    print(f"Created version {APP_VERSION}: {version_id}")
    return version_id


def ensure_version_localizations(version_id):
    localizations = list_all(f"/appStoreVersions/{version_id}/appStoreVersionLocalizations?limit=200")
    existing = {item["attributes"]["locale"]: item for item in localizations}
    for locale in META:
        if locale in existing:
            continue
        body = api_json("POST", "/appStoreVersionLocalizations", json={
            "data": {
                "type": "appStoreVersionLocalizations",
                "attributes": {"locale": locale},
                "relationships": {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}}},
            }
        })
        existing[locale] = body["data"]
    return existing


def update_version_metadata(version_id):
    localizations = ensure_version_localizations(version_id)
    for locale, meta in META.items():
        loc = localizations[locale]
        attrs = {
            key: meta[key]
            for key in ("description", "keywords", "whatsNew", "promotionalText", "supportUrl", "marketingUrl")
        }
        response = api("PATCH", f"/appStoreVersionLocalizations/{loc['id']}", json={
            "data": {"type": "appStoreVersionLocalizations", "id": loc["id"], "attributes": attrs}
        })
        if response.status_code == 409:
            attrs.pop("whatsNew", None)
            response = api("PATCH", f"/appStoreVersionLocalizations/{loc['id']}", json={
                "data": {"type": "appStoreVersionLocalizations", "id": loc["id"], "attributes": attrs}
            })
        if response.status_code not in (200, 201):
            raise RuntimeError(f"Metadata {locale} failed {response.status_code}: {response.text[:800]}")
        print(f"Metadata {locale}: {response.status_code}")


def update_app_info():
    api("PATCH", f"/apps/{APP_ID}", json={
        "data": {
            "type": "apps",
            "id": APP_ID,
            "attributes": {"contentRightsDeclaration": "DOES_NOT_USE_THIRD_PARTY_CONTENT"},
        }
    })
    app_infos = list_all(f"/apps/{APP_ID}/appInfos?limit=10")
    if not app_infos:
        return

    app_info_id = app_infos[0]["id"]
    category_response = api("PATCH", f"/appInfos/{app_info_id}", json={
        "data": {
            "type": "appInfos",
            "id": app_info_id,
            "relationships": {"primaryCategory": {"data": {"type": "appCategories", "id": "LIFESTYLE"}}},
        }
    })
    print(f"App category: {category_response.status_code}")

    for loc in list_all(f"/appInfos/{app_info_id}/appInfoLocalizations?limit=20"):
        locale = loc["attributes"].get("locale")
        meta = META.get(locale)
        if not meta:
            continue
        response = api("PATCH", f"/appInfoLocalizations/{loc['id']}", json={
            "data": {
                "type": "appInfoLocalizations",
                "id": loc["id"],
                "attributes": {
                    "subtitle": meta["subtitle"],
                    "privacyPolicyUrl": meta["privacyPolicyUrl"],
                },
            }
        })
        if response.status_code not in (200, 201):
            raise RuntimeError(f"App info {locale} failed {response.status_code}: {response.text[:800]}")
        print(f"App info {locale}: {response.status_code}")


def update_version_settings(version_id):
    response = api("PATCH", f"/appStoreVersions/{version_id}", json={
        "data": {
            "type": "appStoreVersions",
            "id": version_id,
            "attributes": {
                "copyright": "2026 Tokyo Nasu",
                "usesIdfa": True,
            },
        }
    })
    if response.status_code not in (200, 201):
        raise RuntimeError(f"Version settings failed {response.status_code}: {response.text[:800]}")
    print(f"Version settings: {response.status_code}")


def find_build():
    builds = list_all(
        f"/builds?filter[app]={APP_ID}&filter[version]={BUILD_NUMBER}&filter[processingState]=VALID&limit=10&sort=-uploadedDate"
    )
    if not builds:
        raise RuntimeError(f"VALID build not found: {BUILD_NUMBER}")
    build = builds[0]
    print(f"Build selected: {build['id']} number={BUILD_NUMBER}")
    return build["id"]


def assign_build(version_id, build_id):
    encryption_response = api("PATCH", f"/builds/{build_id}", json={
        "data": {"type": "builds", "id": build_id, "attributes": {"usesNonExemptEncryption": False}}
    })
    print(f"Encryption setting: {encryption_response.status_code}")

    response = api("PATCH", f"/appStoreVersions/{version_id}/relationships/build", json={
        "data": {"type": "builds", "id": build_id}
    })
    if response.status_code not in (200, 204):
        raise RuntimeError(f"Build assign failed {response.status_code}: {response.text[:800]}")
    print(f"Build assigned: {response.status_code}")


def upload_screenshots(version_id):
    localizations = ensure_version_localizations(version_id)
    for locale, meta in META.items():
        loc = localizations[locale]
        sets = list_all(f"/appStoreVersionLocalizations/{loc['id']}/appScreenshotSets?limit=200")
        existing = {item["attributes"]["screenshotDisplayType"]: item["id"] for item in sets}
        set_id = existing.get(SCREENSHOT_DISPLAY_TYPE)
        if not set_id:
            body = api_json("POST", "/appScreenshotSets", json={
                "data": {
                    "type": "appScreenshotSets",
                    "attributes": {"screenshotDisplayType": SCREENSHOT_DISPLAY_TYPE},
                    "relationships": {
                        "appStoreVersionLocalization": {"data": {"type": "appStoreVersionLocalizations", "id": loc["id"]}}
                    },
                }
            })
            set_id = body["data"]["id"]

        for screenshot in list_all(f"/appScreenshotSets/{set_id}/appScreenshots?limit=200"):
            api("DELETE", f"/appScreenshots/{screenshot['id']}")

        for relative_path in meta["screenshots"]:
            upload_screenshot(set_id, SCREENSHOT_ROOT / relative_path)


def upload_screenshot(set_id, path):
    if not path.exists():
        raise RuntimeError(f"Screenshot not found: {path}")

    data = path.read_bytes()
    checksum = hashlib.md5(data).hexdigest()
    body = api_json("POST", "/appScreenshots", json={
        "data": {
            "type": "appScreenshots",
            "attributes": {"fileName": path.name, "fileSize": len(data)},
            "relationships": {"appScreenshotSet": {"data": {"type": "appScreenshotSets", "id": set_id}}},
        }
    })
    screenshot_id = body["data"]["id"]
    for operation in body["data"]["attributes"]["uploadOperations"]:
        request_headers = {item["name"]: item["value"] for item in operation["requestHeaders"]}
        start = operation["offset"]
        end = start + operation["length"]
        upload_response = requests.put(operation["url"], headers=request_headers, data=data[start:end], timeout=120)
        upload_response.raise_for_status()

    response = api("PATCH", f"/appScreenshots/{screenshot_id}", json={
        "data": {
            "type": "appScreenshots",
            "id": screenshot_id,
            "attributes": {"uploaded": True, "sourceFileChecksum": checksum},
        }
    })
    if response.status_code not in (200, 201):
        raise RuntimeError(f"Screenshot upload failed {path}: {response.status_code} {response.text[:800]}")
    print(f"Screenshot uploaded: {path}")


def main():
    app = api_json("GET", f"/apps/{APP_ID}")["data"]
    print(f"App: {app['attributes'].get('name')} / {app['attributes'].get('bundleId')}")
    version_id = find_or_create_version()
    update_app_info()
    update_version_settings(version_id)
    update_version_metadata(version_id)
    upload_screenshots(version_id)
    assign_build(version_id, find_build())
    print("App Store metadata, screenshots, and build selection are ready.")


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        print(str(error), file=sys.stderr)
        sys.exit(1)
