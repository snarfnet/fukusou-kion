import importlib.util
import os
from pathlib import Path


BASE_PATH = Path(__file__).resolve().parents[2] / "FukusouKion" / "scripts" / "submit_production.py"
spec = importlib.util.spec_from_file_location("asc_submission_base", BASE_PATH)
base = importlib.util.module_from_spec(spec)
spec.loader.exec_module(base)

base.APP_ID = os.environ.get("WORLD_DRESS_CAMERA_APP_ID", "6794936502")
base.BUNDLE_ID = "com.tokyonasu.worlddresscamera"
base.APP_NAME = "民族衣装カメラ"
base.APP_SKU = "world-dress-camera-ios"
base.APP_VERSION = os.environ.get("APP_VERSION", "1.0")
base.BUILD_NUMBER = os.environ.get("BUILD_NUMBER", "114")
base.APP_PRICE_JPY = os.environ.get("APP_PRICE_JPY", "300")
base.SCREENSHOT_DIR = "AppStore/Screenshots"
base.SCREENSHOT_GROUPS = [
    ("APP_IPHONE_67", ["01-try-on.png", "02-costume-catalog.png", "03-camera-guide.png"]),
]
base.META = {
    "ja": {
        "description": (
            "民族衣装カメラは、全身写真に世界各地の民族衣装を重ねて楽しめるカメラアプリです。\n\n"
            "女性用50種類、男性用50種類、合計100種類の衣装を収録。撮影ガイドに合わせて全身を撮影し、"
            "衣装の位置、大きさ、角度、明るさ、彩度、透明度などを調整できます。自動調整や境界をやわらかくする"
            "機能を使うと、人物と衣装をより自然になじませられます。\n\n"
            "衣装ごとに、地域や民族、歴史、素材、特徴、着用場面を紹介しています。"
            "完成した写真は端末へ保存できます。\n\n"
            "写真の処理は端末内で行います。写真を外部サーバーへ送信することはありません。"
        ),
        "keywords": "民族衣装,着せ替え,カメラ,写真加工,世界,文化,旅行,コスチューム,合成",
        "whatsNew": "初回リリースです。",
        "promotionalText": "世界100種類の民族衣装を、全身写真に重ねて楽しめます。",
        "marketingUrl": "https://snarfnet.github.io/",
        "supportUrl": "https://snarfnet.github.io/",
    },
    "en-US": {
        "description": (
            "World Dress Camera lets you overlay traditional clothing from around the world onto "
            "a full-body photo.\n\nChoose from 100 outfits: 50 for women and 50 for men. Use the "
            "shooting guide, automatic alignment, and controls for position, size, rotation, "
            "brightness, saturation, opacity, and edge softness.\n\nEach outfit includes information "
            "about its region, people, history, materials, features, and occasions. Photo processing "
            "stays on your device and photos are not uploaded to an external server."
        ),
        "keywords": "traditional dress,camera,costume,photo editor,culture,travel,outfit,overlay",
        "whatsNew": "Initial release.",
        "promotionalText": "Try 100 traditional outfits from around the world on your full-body photos.",
        "marketingUrl": "https://snarfnet.github.io/",
        "supportUrl": "https://snarfnet.github.io/",
    },
}


def require_ok(response, label):
    print(f"{label}: {response.status_code}")
    if response.status_code not in (200, 201, 204):
        raise RuntimeError(f"{label} failed {response.status_code}: {response.text[:1200]}")


def ensure_app_info():
    require_ok(base.api("PATCH", f"/apps/{base.APP_ID}", json={
        "data": {
            "type": "apps",
            "id": base.APP_ID,
            "attributes": {"contentRightsDeclaration": "DOES_NOT_USE_THIRD_PARTY_CONTENT"},
        }
    }), "Content rights")
    response, body = base.api_json("GET", f"/apps/{base.APP_ID}/appInfos?limit=10")
    require_ok(response, "App info lookup")
    app_info_id = body["data"][0]["id"]
    require_ok(base.api("PATCH", f"/appInfos/{app_info_id}", json={
        "data": {
            "type": "appInfos",
            "id": app_info_id,
            "relationships": {
                "primaryCategory": {"data": {"type": "appCategories", "id": "PHOTO_AND_VIDEO"}}
            },
        }
    }), "Photo and video category")

    response, body = base.api_json(
        "GET", f"/appInfos/{app_info_id}/appInfoLocalizations?limit=20"
    )
    require_ok(response, "App info localizations")
    for localization in body.get("data", []):
        locale = localization["attributes"].get("locale")
        attrs = {
            "subtitle": "世界100種類の衣装で写真撮影",
            "privacyPolicyUrl": "https://snarfnet.github.io/privacy.html",
        }
        if locale == "ja":
            attrs["name"] = "民族衣装カメラ"
        require_ok(base.api("PATCH", f"/appInfoLocalizations/{localization['id']}", json={
            "data": {
                "type": "appInfoLocalizations",
                "id": localization["id"],
                "attributes": attrs,
            }
        }), f"App info {locale}")

    string_fields = [
        "alcoholTobaccoOrDrugUseOrReferences", "contests", "gamblingSimulated",
        "gunsOrOtherWeapons", "medicalOrTreatmentInformation", "profanityOrCrudeHumor",
        "sexualContentGraphicAndNudity", "sexualContentOrNudity", "horrorOrFearThemes",
        "matureOrSuggestiveThemes", "violenceCartoonOrFantasy",
        "violenceRealisticProlongedGraphicOrSadistic", "violenceRealistic",
    ]
    bool_fields = [
        "messagingAndChat", "gambling", "parentalControls", "ageAssurance",
        "userGeneratedContent", "healthOrWellnessTopics", "unrestrictedWebAccess", "lootBox",
    ]
    rating = {key: "NONE" for key in string_fields}
    rating.update({key: False for key in bool_fields})
    rating["advertising"] = False
    require_ok(base.api("PATCH", f"/ageRatingDeclarations/{app_info_id}", json={
        "data": {"type": "ageRatingDeclarations", "id": app_info_id, "attributes": rating}
    }), "Age rating")


def ensure_review_detail(version_id):
    attrs = {
        "contactFirstName": "Tokyo",
        "contactLastName": "Nasu",
        "contactPhone": "+81 80-2368-9194",
        "contactEmail": "tokyonasu@yahoo.co.jp",
        "demoAccountRequired": False,
        "notes": (
            "ログインは不要です。カメラまたは写真ライブラリから全身写真を選び、衣装を重ねて編集します。"
            "写真処理は端末内で完結し、外部サーバーへ送信しません。広告とアプリ内課金はありません。"
        ),
    }
    response, body = base.api_json(
        "GET", f"/appStoreVersions/{version_id}/appStoreReviewDetail"
    )
    if response.status_code == 200 and body.get("data"):
        detail_id = body["data"]["id"]
        require_ok(base.api("PATCH", f"/appStoreReviewDetails/{detail_id}", json={
            "data": {"type": "appStoreReviewDetails", "id": detail_id, "attributes": attrs}
        }), "Review detail")
    else:
        require_ok(base.api("POST", "/appStoreReviewDetails", json={
            "data": {
                "type": "appStoreReviewDetails",
                "attributes": attrs,
                "relationships": {
                    "appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}}
                },
            }
        }), "Review detail")


def ensure_release_prerequisites(version_id):
    ensure_app_info()
    require_ok(base.api("PATCH", f"/appStoreVersions/{version_id}", json={
        "data": {
            "type": "appStoreVersions",
            "id": version_id,
            "attributes": {
                "copyright": "2026 Tokyo Nasu",
                "usesIdfa": False,
                "releaseType": "AFTER_APPROVAL",
            },
        }
    }), "Version settings")
    ensure_price()
    ensure_review_detail(version_id)


def ensure_price():
    target = str(base.APP_PRICE_JPY)
    response, body = base.api_json("GET", f"/apps/{base.APP_ID}/relationships/appPriceSchedule")
    if response.status_code == 200 and body.get("data"):
        schedule_id = body["data"]["id"]
        response, current = base.api_json(
            "GET",
            f"/appPriceSchedules/{schedule_id}/manualPrices"
            "?limit=200&include=appPricePoint,territory"
            "&fields[appPricePoints]=customerPrice&filter[territory]=JPN",
        )
        if response.status_code == 200:
            points = {
                item["id"]: str(item.get("attributes", {}).get("customerPrice"))
                for item in current.get("included", [])
                if item.get("type") == "appPricePoints"
            }
            for price in current.get("data", []):
                point_id = (
                    price.get("relationships", {})
                    .get("appPricePoint", {})
                    .get("data", {})
                    .get("id")
                )
                if price.get("attributes", {}).get("endDate") is None and points.get(point_id) == target:
                    print(f"Price JPN {target}: already set")
                    return

    response, body = base.api_json(
        "GET",
        f"/apps/{base.APP_ID}/appPricePoints"
        "?filter[territory]=JPN&fields[appPricePoints]=customerPrice&limit=200",
    )
    require_ok(response, "Japan price points")
    point = next(
        (
            item for item in body.get("data", [])
            if str(item.get("attributes", {}).get("customerPrice")) == target
        ),
        None,
    )
    if not point:
        raise RuntimeError(f"The JPY {target} App Store price point was not found.")
    local_id = "${manualPrice0}"
    require_ok(base.api("POST", "/appPriceSchedules", json={
        "data": {
            "type": "appPriceSchedules",
            "relationships": {
                "app": {"data": {"type": "apps", "id": base.APP_ID}},
                "baseTerritory": {"data": {"type": "territories", "id": "JPN"}},
                "manualPrices": {"data": [{"type": "appPrices", "id": local_id}]},
            },
        },
        "included": [{
            "type": "appPrices",
            "id": local_id,
            "attributes": {"startDate": None},
            "relationships": {
                "appPricePoint": {"data": {"type": "appPricePoints", "id": point["id"]}}
            },
        }],
    }), f"Price JPN {target}")


def main():
    app_id = base.find_app_id()
    if app_id != base.APP_ID:
        raise RuntimeError(f"Unexpected App Store Connect app id: {app_id}")
    version_id, state = base.find_or_create_version(app_id)
    if state in ("WAITING_FOR_REVIEW", "IN_REVIEW"):
        print(f"Already submitted: {state}")
        return
    ensure_release_prerequisites(version_id)
    base.update_metadata(version_id)
    build_id = base.wait_for_build(app_id)
    base.cancel_blocking_submissions(app_id)
    base.upload_screenshots(version_id)
    base.wait_for_screenshot_processing(version_id)
    base.assign_build(version_id, build_id)
    base.submit_for_review(app_id, version_id)


if __name__ == "__main__":
    main()
