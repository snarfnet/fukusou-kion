import os
from datetime import date

from asc_api import api, find_app_id, get_or_create_version, list_all

APP_VERSION = os.environ.get("APP_VERSION", "1.0")
TARGET_JPY_PRICE = os.environ.get("TARGET_JPY_PRICE", "100")

LOCALIZATION = {
    "description": (
        "5人のギャルと対面で遊ぶリバーシゲームです。"
        "相手ごとに強さ、表情、プロフィール、ひと言が変わります。"
        "夜景を背景にした立体的な盤面で、ギャルが本当に駒を置くような演出を楽しめます。"
    ),
    "keywords": "リバーシ,オセロ,ボードゲーム,ギャル,対戦,一人用,パズル,夜景",
    "promotionalText": "5人のギャルと夜景の盤面でリバーシ対戦。",
    "marketingUrl": "https://snarfnet.github.io/",
    "supportUrl": "https://snarfnet.github.io/",
    "whatsNew": "初回リリースです。5人のギャル対戦相手、立体盤面、プロフィール、表情変化を収録しました。",
}

APP_INFO = {
    "name": "ギャルオセロ",
    "subtitle": "5人のギャルとリバーシ対戦",
    "privacyPolicyUrl": "https://snarfnet.github.io/privacy.html",
}

REVIEW_CONTACT = {
    "contactFirstName": "Tokyo",
    "contactLastName": "Nasu",
    "contactEmail": "tokyonasu@yahoo.co.jp",
    "contactPhone": "+81 80-2368-9194",
    "demoAccountRequired": False,
    "notes": (
        "ログイン不要です。アプリ起動後、そのままリバーシ対戦を開始できます。"
        "すべての画像はアプリ内に同梱され、外部Web閲覧やユーザー生成コンテンツはありません。"
    ),
}


def main():
    app_id = find_app_id()
    version_id = get_or_create_version(app_id, APP_VERSION)
    set_common_app_settings(app_id, version_id)
    update_app_info(app_id)
    update_localization(version_id)
    update_review_detail(version_id)
    ensure_jpy_price(app_id)
    print(f"ASC metadata prepared for app={app_id} version={version_id}")


def set_common_app_settings(app_id, version_id):
    patch(f"/apps/{app_id}", "apps", app_id, {
        "contentRightsDeclaration": "DOES_NOT_USE_THIRD_PARTY_CONTENT",
    }, "Content rights")
    patch(f"/appStoreVersions/{version_id}", "appStoreVersions", version_id, {
        "copyright": f"{date.today().year} Tokyo Nasu",
        "usesIdfa": False,
        "releaseType": "AFTER_APPROVAL",
    }, "Version settings")


def update_app_info(app_id):
    app_infos = list_all(f"/apps/{app_id}/appInfos?limit=20")
    if not app_infos:
        print("App info not found")
        return

    app_info_id = app_infos[0]["id"]
    try:
        api("PATCH", f"/appInfos/{app_info_id}", json={
            "data": {
                "type": "appInfos",
                "id": app_info_id,
                "relationships": {
                    "primaryCategory": {"data": {"type": "appCategories", "id": "GAMES"}},
                },
            }
        })
        print("Category updated")
    except RuntimeError as error:
        print(f"Category skipped: {error}")

    for loc in list_all(f"/appInfos/{app_info_id}/appInfoLocalizations?limit=20"):
        patch(f"/appInfoLocalizations/{loc['id']}", "appInfoLocalizations", loc["id"], APP_INFO, f"App info {loc['attributes'].get('locale')}")


def update_localization(version_id):
    localizations = list_all(f"/appStoreVersions/{version_id}/appStoreVersionLocalizations?limit=20")
    if not localizations:
        payload = api("POST", "/appStoreVersionLocalizations", json={
            "data": {
                "type": "appStoreVersionLocalizations",
                "attributes": {"locale": "ja", **LOCALIZATION},
                "relationships": {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}}},
            }
        })
        localizations = [payload["data"]]

    for loc in localizations:
        patch(
            f"/appStoreVersionLocalizations/{loc['id']}",
            "appStoreVersionLocalizations",
            loc["id"],
            LOCALIZATION,
            f"Version localization {loc['attributes'].get('locale')}",
        )


def update_review_detail(version_id):
    payload = api("GET", f"/appStoreVersions/{version_id}/appStoreReviewDetail")
    if payload.get("data"):
        detail_id = payload["data"]["id"]
        patch(f"/appStoreReviewDetails/{detail_id}", "appStoreReviewDetails", detail_id, REVIEW_CONTACT, "Review detail")
        return

    api("POST", "/appStoreReviewDetails", json={
        "data": {
            "type": "appStoreReviewDetails",
            "attributes": REVIEW_CONTACT,
            "relationships": {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}}},
        }
    })
    print("Review detail created")


def ensure_jpy_price(app_id):
    points = list_all(f"/apps/{app_id}/appPricePoints?filter[territory]=JPN&filter[customerPrice]={TARGET_JPY_PRICE}&limit=20")
    if not points:
        print(f"Price skipped: JPN customer price {TARGET_JPY_PRICE} was not found. Set it manually in Pricing and Availability.")
        return

    price_id = "${gyaruOthelloPrice}"
    payload = {
        "data": {
            "type": "appPriceSchedules",
            "relationships": {
                "app": {"data": {"type": "apps", "id": app_id}},
                "baseTerritory": {"data": {"type": "territories", "id": "JPN"}},
                "manualPrices": {"data": [{"type": "appPrices", "id": price_id}]},
            },
        },
        "included": [{
            "type": "appPrices",
            "id": price_id,
            "attributes": {"startDate": date.today().isoformat()},
            "relationships": {
                "appPricePoint": {"data": {"type": "appPricePoints", "id": points[0]["id"]}},
            },
        }],
    }
    try:
        api("POST", "/appPriceSchedules", json=payload)
        print(f"Price set: JPN {TARGET_JPY_PRICE}")
    except RuntimeError as error:
        print(f"Price skipped: {error}")


def patch(path, resource_type, resource_id, attrs, label):
    try:
        api("PATCH", path, json={
            "data": {
                "type": resource_type,
                "id": resource_id,
                "attributes": attrs,
            }
        })
        print(f"{label}: updated")
    except RuntimeError as error:
        print(f"{label}: skipped: {error}")


if __name__ == "__main__":
    main()
