#!/usr/bin/env python3
import os
import time

from asc_helpers import api, api_json, fail, json_body, query


APP_ID = os.environ["APP_ID"]
APP_VERSION = os.environ.get("APP_VERSION", "1.0")
BUILD_NUMBER = os.environ["BUILD_NUMBER"]
PRICE_JPY = os.environ.get("PRICE_JPY", "1200")
PRIVACY_URL = os.environ.get("PRIVACY_URL", "https://snarfnet.github.io/privacy.html")

META = {
    "ja": {
        "description": (
            "OAHSPE:α78は、広告なし・買い切りの高機能カメラです。\n\n"
            "ただ綺麗に撮るだけではなく、撮る前に失敗を見つけ、撮った後に素材として使いやすい写真を残すことを目指しました。"
            "日常の写真、商品撮影、料理、ネイル、旅行、記録写真、SNS用の写真まで、幅広い場面で使えます。\n\n"
            "RAW素材モードでは、編集前提の写真を残せます。RAWと処理済み写真を扱えるので、あとから色や明るさを調整したい人に向いています。"
            "自前ISPモードでは、iPhone標準の見た目とは少し違う、独自の色作りで写真を仕上げます。\n\n"
            "HDRブラケットでは、暗め・標準・明るめの写真をもとに、白飛びや黒つぶれを抑えた写真を狙います。"
            "逆光、室内、夜景のように明暗差が大きい場面で役立ちます。低照度スタックは、暗い場所で複数枚を重ね、ノイズを抑えた写真を目指すモードです。\n\n"
            "最強手ブレモードは、撮影中の揺れを見て、今撮るべきか、少し待つべきかを判断しやすくします。"
            "子ども、ペット、料理、商品など、撮り直しにくい場面で便利です。\n\n"
            "目的別Proでは、商品撮影、料理、ネイル、プロフィール写真など、用途に合わせて見方を変えます。"
            "構図、明るさ、被写体の見え方を意識しながら撮れるので、写真に慣れていない人でも使いやすい設計です。\n\n"
            "プライバシーチェックや撮影ガイドも搭載しています。投稿前に気になる写り込みを意識したい時や、水平、明るさ、ブレを確認しながら撮りたい時に役立ちます。\n\n"
            "OAHSPE:α78は、毎月の料金も広告もありません。1回購入すれば、集中して写真を撮るための道具として使えます。"
        ),
        "keywords": "カメラ,RAW,HDR,手ブレ,写真,夜景,商品撮影,料理,ネイル,プロカメラ",
        "whatsNew": "初回リリースです。",
        "promotionalText": "RAW、HDR、低照度、手ブレ、目的別Proをまとめた広告なしの買い切りカメラ。",
        "marketingUrl": "https://snarfnet.github.io/",
    },
    "en-US": {
        "description": (
            "OAHSPE:α78 is a one-time purchase camera with no ads.\n\n"
            "It is designed not only to take better photos, but also to help you notice problems before you press the shutter. "
            "Use it for everyday photos, product listings, food, nails, travel, records, and social posts.\n\n"
            "RAW Material mode is made for people who want room to edit later. It helps you keep photo material that can be adjusted after capture. "
            "Custom ISP mode gives photos a different look from the standard camera, with OAHSPE:α78's own color processing.\n\n"
            "HDR Bracket mode uses darker, normal, and brighter captures to reduce blown highlights and crushed shadows. "
            "It is useful for backlight, indoor scenes, night views, and other high-contrast situations. Low-Light Stack mode combines multiple captures to aim for cleaner photos in dark places.\n\n"
            "Stability mode watches camera shake and helps you decide whether to shoot now or hold still for a moment. "
            "It is useful when photographing children, pets, food, products, or anything that is hard to repeat.\n\n"
            "Purpose Pro changes the way the camera guides you depending on what you are shooting. "
            "Product photos, food, nails, profile images, and other scenes each need a different way of looking at framing, brightness, and subject placement.\n\n"
            "Privacy Check and shooting guidance are included as practical tools. They help you notice possible privacy risks, tilt, brightness issues, and shake before saving or sharing a photo.\n\n"
            "OAHSPE:α78 has no subscription and no advertising. Buy it once and use it as a focused tool for taking photos."
        ),
        "keywords": "camera,RAW,HDR,stabilizer,photo,night,product,food,nails,pro camera",
        "whatsNew": "Initial release.",
        "promotionalText": "A no-ads, one-time purchase camera for RAW, HDR, low light, stability, and purpose modes.",
        "marketingUrl": "https://snarfnet.github.io/",
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
        if submission.get("attributes", {}).get("state") in {"READY_FOR_REVIEW", "UNRESOLVED_ISSUES"}:
            return submission["id"]
    return None


def submit_for_review(version_id):
    cancel_open_review_submissions()
    response = api("POST", "/reviewSubmissions", data=json_body({
        "data": {
            "type": "reviewSubmissions",
            "attributes": {"platform": "IOS"},
            "relationships": {"app": {"data": {"type": "apps", "id": APP_ID}}},
        }
    }))
    if response.status_code == 201:
        submission_id = response.json()["data"]["id"]
    elif response.status_code == 409:
        submission_id = find_reusable_submission()
        if not submission_id:
            raise RuntimeError(f"Review submission create failed {response.status_code}: {response.text[:800]}")
    else:
        raise RuntimeError(f"Review submission create failed {response.status_code}: {response.text[:800]}")

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
        if response.status_code in (200, 201, 409):
            break
        time.sleep(30)

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
        print(f"Review submit {attempt}/30: {response.status_code} {response.text[:300]}")
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
