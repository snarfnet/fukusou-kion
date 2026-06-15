#!/usr/bin/env python3
import hashlib
import os
import re
import tempfile
import time
from pathlib import Path

import requests
from asc_helpers import api, api_json, fail, json_body, query


APP_ID = os.environ["APP_ID"]
APP_VERSION = os.environ.get("APP_VERSION", "1.0")
BUILD_NUMBER = os.environ["BUILD_NUMBER"]
PRICE_JPY = os.environ.get("PRICE_JPY", "1200")
PRIVACY_URL = os.environ.get("PRIVACY_URL", "https://snarfnet.github.io/privacy.html")
ROOT = Path(__file__).resolve().parents[1]

META = {
    "ja": {
        "description": (
            "OAHSPE:α78は、広告なし・買い切りの本格カメラアプリです。\n\n"
            "目指したのは、ただシャッターを押すだけのカメラではありません。撮る前に失敗を見つけ、撮る瞬間のブレや明るさを意識し、撮った後に編集しやすい写真を残す。そんな「撮影前から仕上げまで」を考えたカメラです。\n\n"
            "日常の写真、旅行、料理、商品撮影、ネイル、SNSアイコン、記録写真、室内、夜景、逆光の場面まで、幅広い撮影に向けて作っています。写真に慣れている人は細かく追い込めます。写真が苦手な人でも、ガイドを見ながら落ち着いて撮れます。\n\n"
            "RAW素材モードでは、あとから編集しやすい写真を残せます。色、明るさ、シャドウ、ハイライトを後で調整したい人に向いたモードです。撮って終わりではなく、現像や加工のための素材として写真を残したい時に役立ちます。\n\n"
            "自前ISPモードでは、独自の色作りで写真を仕上げます。iPhone標準カメラとは違う雰囲気を狙い、青みや色かぶりを抑えながら、見やすく扱いやすい写真を目指します。商品、料理、机の上の小物、SNS用の写真など、自然で使いやすい仕上がりを意識しています。\n\n"
            "HDRブラケットは、暗め・標準・明るめの写真を使い、白飛びや黒つぶれを抑えるためのモードです。窓際、逆光、室内、夜景のように明暗差が大きい場面で力を発揮します。明るい部分だけ飛ぶ、暗い部分だけ潰れる。そんな失敗を減らすための機能です。\n\n"
            "低照度スタックは、暗い場所で複数枚を重ね、ノイズを抑えた写真を目指します。夜の部屋、暗めの店内、夕方の街、ライトが少ない場所など、普通に撮ると荒れやすい場面を助けます。\n\n"
            "最強手ブレモードは、撮影中の揺れを見ながら、今撮るべきか、少し待つべきかを判断しやすくします。子ども、ペット、料理、商品、メモ代わりの写真など、撮り直しにくい場面で便利です。保存後の向きにも配慮し、縦横どちらでも自然に見られる写真を目指します。\n\n"
            "目的別Proでは、撮りたいものに合わせてカメラの見方を変えます。商品撮影では中央配置や明るさを意識し、料理では白飛びや質感を見やすくします。ネイルでは指先、プロフィール写真では顔の明るさや余白を意識できます。海外向けにも使いやすいよう、商品撮影はeBayなどの出品写真にも合う考え方にしています。\n\n"
            "プライバシーチェックは、投稿前に気になる写り込みを意識するための機能です。住所、書類、画面、名札、ナンバー、QRコードなど、写真を公開する前に確認したい情報へ注意を向けやすくします。\n\n"
            "水準器、グリッド、ヒストグラム、白飛び警告、フォーカスや露出の補助など、撮影時に役立つ道具も入れています。派手な加工より、失敗を減らし、あとで使いやすい写真を残すことを重視しました。\n\n"
            "OAHSPE:α78には広告がありません。月額料金もありません。1回購入すれば、集中して写真を撮るための道具として使えます。仕事用の写真にも、趣味の写真にも、日常の記録にも使えるカメラです。"
        ),
        "keywords": "カメラ,RAW,HDR,手ブレ,写真,夜景,商品撮影,料理,ネイル,プロカメラ",
        "whatsNew": "初回リリースです。",
        "promotionalText": "RAW、HDR、低照度、手ブレ、目的別Proをまとめた広告なしの買い切りカメラ。",
        "marketingUrl": "https://snarfnet.github.io/",
        "supportUrl": "https://snarfnet.github.io/",
    },
    "en-US": {
        "description": (
            "OAHSPE:α78 is a serious camera app with no ads and no subscription.\n\n"
            "It is built for people who want more than a quick shutter button. The app helps you notice problems before capture, think about shake and exposure while shooting, and save photos that are easier to edit afterward. It is a camera for the full flow: before the shot, during the shot, and after the shot.\n\n"
            "Use it for everyday photos, travel, food, product listings, nails, profile images, records, indoor scenes, night views, and backlit situations. Experienced users can work with more control. Beginners can follow the guides and shoot with more confidence.\n\n"
            "RAW Material mode is made for editing. It helps you keep image material that can be adjusted later for color, brightness, shadows, and highlights. When you want a photo that is not locked into a finished look right away, RAW Material gives you more room to work.\n\n"
            "Custom ISP mode applies OAHSPE:α78's own image processing. It aims for a clean, usable look while reducing unwanted color casts. It is useful for products, food, desk objects, social posts, and other photos where a natural finish matters.\n\n"
            "HDR Bracket mode uses darker, normal, and brighter captures to reduce blown highlights and crushed shadows. It is useful near windows, in backlight, indoors, at night, and in other high-contrast scenes. The goal is simple: keep bright areas from turning white and dark areas from disappearing.\n\n"
            "Low-Light Stack mode combines multiple captures to aim for cleaner photos in dark places. It helps in dim rooms, restaurants, evening streets, and scenes where normal photos can become noisy.\n\n"
            "Stability mode watches camera shake and helps you decide whether to shoot now or hold still for a moment. It is useful for children, pets, food, products, notes, and moments that are hard to repeat. The app also pays attention to saved photo orientation, so portrait and landscape shots are easier to view correctly afterward.\n\n"
            "Purpose Pro changes the camera guidance based on what you are shooting. Product mode focuses on framing, subject size, and brightness for listing photos such as eBay items. Food mode helps you watch highlights and texture. Nail mode focuses on fingertips. Profile mode helps with face brightness and space around the subject.\n\n"
            "Privacy Check helps you notice things you may not want to share. It is designed to draw attention to possible private details such as addresses, documents, screens, name tags, license plates, and QR codes before you post or save a photo publicly.\n\n"
            "The app also includes practical shooting tools such as a level, grid, histogram, highlight warning, focus help, and exposure guidance. OAHSPE:α78 puts less focus on flashy filters and more focus on reducing mistakes and saving photos that are useful later.\n\n"
            "OAHSPE:α78 has no ads. It has no monthly fee. Buy it once and use it as a focused tool for work photos, personal photos, creative shooting, and everyday records."
        ),
        "keywords": "camera,RAW,HDR,stabilizer,photo,night,product,food,nails,pro camera",
        "whatsNew": "Initial release.",
        "promotionalText": "A no-ads, one-time purchase camera for RAW, HDR, low light, stability, and purpose modes.",
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


def app_state(version):
    return version.get("attributes", {}).get("appStoreState")


def find_or_create_version():
    for version in list_all(f"/apps/{APP_ID}/appStoreVersions?filter[platform]=IOS&limit=200"):
        attrs = version.get("attributes", {})
        if attrs.get("versionString") == APP_VERSION:
            print(f"Found version {APP_VERSION}: {version['id']} state={attrs.get('appStoreState')}")
            return version["id"], attrs.get("appStoreState")

    body = api_json("POST", "/appStoreVersions", data=json_body({
        "data": {
            "type": "appStoreVersions",
            "attributes": {"platform": "IOS", "versionString": APP_VERSION},
            "relationships": {"app": {"data": {"type": "apps", "id": APP_ID}}},
        }
    }))
    version = body["data"]
    print(f"Created version {APP_VERSION}: {version['id']}")
    return version["id"], app_state(version)


def update_release_prerequisites(version_id):
    api("PATCH", f"/apps/{APP_ID}", data=json_body({
        "data": {
            "type": "apps",
            "id": APP_ID,
            "attributes": {"contentRightsDeclaration": "DOES_NOT_USE_THIRD_PARTY_CONTENT"},
        }
    }))

    infos = list_all(f"/apps/{APP_ID}/appInfos?limit=10")
    if infos:
        app_info_id = infos[0]["id"]
        response = api("PATCH", f"/appInfos/{app_info_id}", data=json_body({
            "data": {
                "type": "appInfos",
                "id": app_info_id,
                "relationships": {
                    "primaryCategory": {"data": {"type": "appCategories", "id": "PHOTO_AND_VIDEO"}}
                },
            }
        }))
        print(f"Category: {response.status_code}")
        update_age_rating(app_info_id)
        update_app_info_localizations(app_info_id)

    response = api("PATCH", f"/appStoreVersions/{version_id}", data=json_body({
        "data": {
            "type": "appStoreVersions",
            "id": version_id,
            "attributes": {
                "copyright": "2026 Tokyo Nasu",
                "usesIdfa": False,
            },
        }
    }))
    print(f"Version attributes: {response.status_code}")
    ensure_price()
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
        "unrestrictedWebAccess",
        "lootBox",
    ]
    attrs = {key: "NONE" for key in string_keys}
    attrs.update({key: False for key in bool_keys})
    attrs["advertising"] = False
    response = api("PATCH", f"/ageRatingDeclarations/{app_info_id}", data=json_body({
        "data": {"type": "ageRatingDeclarations", "id": app_info_id, "attributes": attrs}
    }))
    print(f"Age rating: {response.status_code}")


def update_app_info_localizations(app_info_id):
    response = api("GET", f"/appInfos/{app_info_id}/appInfoLocalizations?limit=20")
    if response.status_code != 200:
        print(f"App info localizations: {response.status_code}")
        return
    for loc in response.json().get("data", []):
        locale = loc["attributes"].get("locale")
        subtitle = "RAW・HDR・手ブレ補正カメラ" if locale == "ja" else "RAW, HDR, steady shots"
        response = api("PATCH", f"/appInfoLocalizations/{loc['id']}", data=json_body({
            "data": {
                "type": "appInfoLocalizations",
                "id": loc["id"],
                "attributes": {
                    "subtitle": subtitle,
                    "privacyPolicyUrl": PRIVACY_URL,
                },
            }
        }))
        print(f"App info {locale}: {response.status_code}")


def ensure_price():
    response = api(
        "GET",
        f"/apps/{APP_ID}/appPricePoints?"
        f"{query({'filter[territory]': 'JPN', 'fields[appPricePoints]': 'customerPrice', 'limit': '200'})}",
    )
    if response.status_code != 200:
        print(f"Price points: {response.status_code}")
        return
    price_id = None
    for point in response.json().get("data", []):
        price = str(point.get("attributes", {}).get("customerPrice"))
        if price in {PRICE_JPY, f"{PRICE_JPY}.0", f"{PRICE_JPY}.00"}:
            price_id = point["id"]
            break
    if not price_id:
        raise RuntimeError(f"No JPN price point found for {PRICE_JPY} JPY")

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
            "relationships": {
                "appPricePoint": {"data": {"type": "appPricePoints", "id": price_id}}
            },
        }],
    }
    response = api("POST", "/appPriceSchedules", data=json_body(payload))
    print(f"Price {PRICE_JPY} JPY: {response.status_code}")
    if response.status_code not in (200, 201, 409):
        raise RuntimeError(f"Price update failed {response.status_code}: {response.text[:800]}")


def ensure_review_detail(version_id):
    payload = {
        "data": {
            "type": "appStoreReviewDetails",
            "attributes": {
                "contactFirstName": "Tokyo",
                "contactLastName": "Nasu",
                "contactPhone": "+1 844 209 0611",
                "contactEmail": "support@snarfnet.github.io",
                "demoAccountRequired": False,
                "notes": "No login is required. The app uses the device camera and photo library add permission.",
            },
            "relationships": {
                "appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}}
            },
        }
    }
    response = api("POST", "/appStoreReviewDetails", data=json_body(payload))
    if response.status_code == 409:
        body = api_json("GET", f"/appStoreVersions/{version_id}/appStoreReviewDetail")
        detail_id = body["data"]["id"]
        payload["data"]["id"] = detail_id
        response = api("PATCH", f"/appStoreReviewDetails/{detail_id}", data=json_body(payload))
    print(f"Review detail: {response.status_code}")


def ensure_localizations(version_id):
    existing = {
        item["attributes"]["locale"]: item
        for item in list_all(f"/appStoreVersions/{version_id}/appStoreVersionLocalizations?limit=200")
    }
    for locale in META:
        if locale in existing:
            continue
        body = api_json("POST", "/appStoreVersionLocalizations", data=json_body({
            "data": {
                "type": "appStoreVersionLocalizations",
                "attributes": {"locale": locale},
                "relationships": {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}}},
            }
        }))
        existing[locale] = body["data"]
    return existing.values()


def update_metadata(version_id):
    for loc in ensure_localizations(version_id):
        locale = loc["attributes"]["locale"]
        meta = META.get(locale, META["en-US"])
        response = api("PATCH", f"/appStoreVersionLocalizations/{loc['id']}", data=json_body({
            "data": {
                "type": "appStoreVersionLocalizations",
                "id": loc["id"],
                "attributes": meta,
            }
        }))
        if response.status_code == 409:
            meta = {key: value for key, value in meta.items() if key != "whatsNew"}
            response = api("PATCH", f"/appStoreVersionLocalizations/{loc['id']}", data=json_body({
                "data": {
                    "type": "appStoreVersionLocalizations",
                    "id": loc["id"],
                    "attributes": meta,
                }
            }))
        print(f"Metadata {locale}: {response.status_code}")


def load_font(size, bold=False):
    from PIL import ImageFont

    candidates = [
        "C:/Windows/Fonts/YuGothB.ttc" if bold else "C:/Windows/Fonts/YuGothM.ttc",
        "C:/Windows/Fonts/meiryob.ttc" if bold else "C:/Windows/Fonts/meiryo.ttc",
        "/System/Library/Fonts/ヒラギノ角ゴシック W6.ttc" if bold else "/System/Library/Fonts/ヒラギノ角ゴシック W3.ttc",
        "C:/Windows/Fonts/segoeuib.ttf" if bold else "C:/Windows/Fonts/segoeui.ttf",
        "C:/Windows/Fonts/arialbd.ttf" if bold else "C:/Windows/Fonts/arial.ttf",
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf" if bold else "/System/Library/Fonts/Supplemental/Arial.ttf",
        "/System/Library/Fonts/Supplemental/Helvetica Bold.ttf" if bold else "/System/Library/Fonts/Supplemental/Helvetica.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
    ]
    for path in candidates:
        if path and Path(path).exists():
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def cover(image, size):
    image = image.convert("RGB")
    src_ratio = image.width / image.height
    dst_ratio = size[0] / size[1]
    if src_ratio > dst_ratio:
        new_h = size[1]
        new_w = int(new_h * src_ratio)
    else:
        new_w = size[0]
        new_h = int(new_w / src_ratio)
    image = image.resize((new_w, new_h))
    left = (new_w - size[0]) // 2
    top = (new_h - size[1]) // 2
    return image.crop((left, top, left + size[0], top + size[1]))


def generate_screenshot(path, size, locale, display_type, scenario):
    from PIL import Image, ImageFilter

    sources = {
        "purpose": ROOT / "AppStoreScreenshots" / "01-pro-material.jpg",
        "stability": ROOT / "AppStoreScreenshots" / "02-night-stack.jpg",
        "privacy": ROOT / "AppStoreScreenshots" / "03-auto-isp.jpg",
    }
    source = sources[scenario]
    if not source.exists():
        raise RuntimeError(f"Screenshot source missing: {source}")

    source_image = Image.open(source).convert("RGB")
    background = cover(source_image, size).filter(ImageFilter.GaussianBlur(radius=18))
    background = background.point(lambda value: int(value * 0.74))

    image = source_image.copy()
    image.thumbnail(size, Image.Resampling.LANCZOS)
    left = (size[0] - image.width) // 2
    top = (size[1] - image.height) // 2
    background.paste(image, (left, top))
    background.save(path, "PNG", optimize=True)
    print(f"Prepared screenshot {display_type} {locale} {scenario}: {path} {size[0]}x{size[1]}")


def list_screenshot_sets(localization_id):
    response = api("GET", f"/appStoreVersionLocalizations/{localization_id}/appScreenshotSets?limit=200")
    if response.status_code != 200:
        print(f"List screenshot sets {localization_id}: {response.status_code} {response.text[:500]}")
        return []
    return response.json().get("data", [])


def create_screenshot_set(localization_id, display_type):
    response = api("POST", "/appScreenshotSets", data=json_body({
        "data": {
            "type": "appScreenshotSets",
            "attributes": {"screenshotDisplayType": display_type},
            "relationships": {
                "appStoreVersionLocalization": {
                    "data": {"type": "appStoreVersionLocalizations", "id": localization_id}
                }
            },
        }
    }))
    print(f"Create screenshot set {display_type}: {response.status_code}")
    if response.status_code not in (200, 201):
        raise RuntimeError(f"Screenshot set create failed {response.status_code}: {response.text[:1000]}")
    return response.json()["data"]["id"]


def delete_screenshot_set(set_id):
    response = api("DELETE", f"/appScreenshotSets/{set_id}")
    print(f"Delete screenshot set {set_id}: {response.status_code}")
    if response.status_code not in (200, 204, 404):
        raise RuntimeError(f"Screenshot set delete failed {response.status_code}: {response.text[:1000]}")


def screenshot_count(set_id):
    response = api("GET", f"/appScreenshotSets/{set_id}/appScreenshots?limit=200")
    if response.status_code != 200:
        print(f"List screenshots {set_id}: {response.status_code} {response.text[:500]}")
        return 0
    return len(response.json().get("data", []))


def upload_screenshot(set_id, path):
    data = Path(path).read_bytes()
    response = api("POST", "/appScreenshots", data=json_body({
        "data": {
            "type": "appScreenshots",
            "attributes": {"fileName": Path(path).name, "fileSize": len(data)},
            "relationships": {"appScreenshotSet": {"data": {"type": "appScreenshotSets", "id": set_id}}},
        }
    }))
    print(f"Reserve screenshot {Path(path).name}: {response.status_code}")
    if response.status_code not in (200, 201):
        raise RuntimeError(f"Screenshot reserve failed {response.status_code}: {response.text[:1000]}")
    screenshot = response.json()["data"]
    screenshot_id = screenshot["id"]
    for operation in screenshot["attributes"].get("uploadOperations", []):
        headers = {item["name"]: item["value"] for item in operation.get("requestHeaders", [])}
        offset = int(operation.get("offset", 0))
        length = int(operation.get("length", len(data)))
        upload_response = requests.request(operation["method"], operation["url"], headers=headers, data=data[offset:offset + length], timeout=300)
        print(f"Upload screenshot chunk: {upload_response.status_code}")
        if upload_response.status_code not in (200, 201, 204):
            raise RuntimeError(f"Screenshot upload failed {upload_response.status_code}: {upload_response.text[:500]}")
    response = api("PATCH", f"/appScreenshots/{screenshot_id}", data=json_body({
        "data": {
            "type": "appScreenshots",
            "id": screenshot_id,
            "attributes": {"uploaded": True, "sourceFileChecksum": hashlib.md5(data).hexdigest()},
        }
    }))
    print(f"Commit screenshot {Path(path).name}: {response.status_code}")
    if response.status_code not in (200, 201):
        raise RuntimeError(f"Screenshot commit failed {response.status_code}: {response.text[:1000]}")


def ensure_screenshots(version_id):
    specs = {
        "APP_IPHONE_65": (1242, 2688),
        "APP_IPAD_PRO_3GEN_129": (2048, 2732),
    }
    localizations = list_all(f"/appStoreVersions/{version_id}/appStoreVersionLocalizations?limit=200")
    with tempfile.TemporaryDirectory() as tmp:
        tmp_dir = Path(tmp)
        for loc in localizations:
            locale = loc["attributes"]["locale"]
            for display_type, size in specs.items():
                sets = [
                    item for item in list_screenshot_sets(loc["id"])
                    if item.get("attributes", {}).get("screenshotDisplayType") == display_type
                ]
                for screenshot_set in sets:
                    delete_screenshot_set(screenshot_set["id"])
                    time.sleep(2)
                set_id = create_screenshot_set(loc["id"], display_type)
                for index, scenario in enumerate(["purpose", "stability", "privacy"], start=1):
                    path = tmp_dir / f"oahspe-{locale}-{display_type}-{index}-{scenario}.png"
                    generate_screenshot(path, size, locale, display_type, scenario)
                    upload_screenshot(set_id, path)


def wait_for_build():
    params = query({
        "filter[app]": APP_ID,
        "filter[version]": BUILD_NUMBER,
        "filter[processingState]": "VALID",
        "limit": "1",
    })
    for index in range(90):
        body = api_json("GET", f"/builds?{params}")
        if body.get("data"):
            build = body["data"][0]
            print(f"Build ready: {build['id']}")
            return build["id"]
        print(f"Waiting for build {BUILD_NUMBER}... {index + 1}/90")
        time.sleep(30)
    raise RuntimeError(f"Build {BUILD_NUMBER} did not finish processing")


def assign_build(version_id, build_id):
    api("PATCH", f"/builds/{build_id}", data=json_body({
        "data": {"type": "builds", "id": build_id, "attributes": {"usesNonExemptEncryption": False}}
    }))
    response = api("PATCH", f"/appStoreVersions/{version_id}/relationships/build", data=json_body({
        "data": {"type": "builds", "id": build_id}
    }))
    print(f"Build assigned: {response.status_code}")
    if response.status_code not in (200, 204):
        raise RuntimeError(f"Build assign failed {response.status_code}: {response.text[:800]}")


def cancel_open_review_submissions():
    response = api("GET", f"/apps/{APP_ID}/reviewSubmissions?limit=20")
    if response.status_code != 200:
        return
    for submission in response.json().get("data", []):
        state = submission.get("attributes", {}).get("state")
        if state in {"READY_FOR_REVIEW", "WAITING_FOR_REVIEW"}:
            response = api("PATCH", f"/reviewSubmissions/{submission['id']}", data=json_body({
                "data": {
                    "type": "reviewSubmissions",
                    "id": submission["id"],
                    "attributes": {"canceled": True},
                }
            }))
            print(f"Canceled review submission {submission['id']}: {response.status_code}")
            time.sleep(10)


def find_reusable_submission():
    response = api("GET", f"/apps/{APP_ID}/reviewSubmissions?limit=20")
    if response.status_code != 200:
        return None
    for submission in response.json().get("data", []):
        if submission.get("attributes", {}).get("state") in {"READY_FOR_REVIEW", "UNRESOLVED_ISSUES", "REJECTED"}:
            return submission["id"]
    return None


def existing_submission_id_from_item_error(response):
    try:
        body = response.json()
    except Exception:
        body = {}

    text = response.text
    for error in body.get("errors", []):
        detail = error.get("detail", "")
        match = re.search(r"reviewSubmission with id ([0-9a-f-]+)", detail)
        if match:
            return match.group(1)
        text += "\n" + detail

    match = re.search(r"reviewSubmission with id ([0-9a-f-]+)", text)
    return match.group(1) if match else None


def submit_for_review(version_id):
    cancel_open_review_submissions()
    response = api("POST", "/reviewSubmissions", data=json_body({
        "data": {
            "type": "reviewSubmissions",
            "attributes": {"platform": "IOS"},
            "relationships": {
                "app": {"data": {"type": "apps", "id": APP_ID}},
            },
        }
    }))
    print(f"Review submission create: {response.status_code}")
    if response.status_code == 201:
        submission_id = response.json()["data"]["id"]
    elif response.status_code == 409:
        print(response.text[:1000])
        submission_id = find_reusable_submission()
        if not submission_id:
            raise RuntimeError(f"Review submission create failed {response.status_code}: {response.text[:1000]}")
    else:
        raise RuntimeError(f"Review submission create failed {response.status_code}: {response.text[:1000]}")

    for attempt in range(20):
        response = api("POST", "/reviewSubmissionItems", data=json_body({
            "data": {
                "type": "reviewSubmissionItems",
                "relationships": {
                    "reviewSubmission": {"data": {"type": "reviewSubmissions", "id": submission_id}},
                    "appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}},
                },
            }
        }))
        print(f"Review item {attempt + 1}/20: {response.status_code}")
        if response.status_code in (200, 201):
            break
        if response.status_code == 409:
            print(response.text[:1000])
            existing_submission_id = existing_submission_id_from_item_error(response)
            if existing_submission_id:
                submission_id = existing_submission_id
                print(f"Using existing review submission: {submission_id}")
                break
            raise RuntimeError(f"Review item create failed {response.status_code}: {response.text[:1000]}")
        time.sleep(30)
    else:
        raise RuntimeError(f"Review item create failed {response.status_code}: {response.text[:1000]}")

    last_response = None
    for attempt in range(1, 31):
        response = api("PATCH", f"/reviewSubmissions/{submission_id}", data=json_body({
            "data": {"type": "reviewSubmissions", "id": submission_id, "attributes": {"submitted": True}}
        }))
        if response.status_code == 200:
            state = response.json()["data"]["attributes"].get("state")
            print(f"Submitted for App Review: {state}")
            return
        last_response = response
        print(f"Review submit {attempt}/30: {response.status_code} {response.text[:500]}")
        time.sleep(60)
    raise RuntimeError(f"Review submit failed {last_response.status_code}: {last_response.text[:1000]}")


def main():
    body = api_json("GET", f"/apps/{APP_ID}")
    attrs = body["data"]["attributes"]
    print(f"App: {attrs.get('name')} / {attrs.get('bundleId')}")

    version_id, state = find_or_create_version()
    if state in {"WAITING_FOR_REVIEW", "IN_REVIEW", "PENDING_DEVELOPER_RELEASE", "PROCESSING_FOR_APP_STORE"}:
        print(f"Already submitted or processing: {state}")
        return

    update_release_prerequisites(version_id)
    update_metadata(version_id)
    ensure_screenshots(version_id)
    if os.environ.get("PREPARE_ONLY") == "1":
        print("Prepared App Store Connect metadata only.")
        return

    build_id = wait_for_build()
    assign_build(version_id, build_id)
    submit_for_review(version_id)


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        fail(error)
