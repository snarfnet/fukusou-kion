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
    app_info_id = update_app_info(app_id)
    if app_info_id:
        update_age_rating(app_info_id)
    update_localization(version_id)
    update_review_detail(version_id)
    ensure_no_data_collected(app_id)
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
        return None

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
    return app_info_id


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
        attrs = dict(LOCALIZATION)
        try:
            api("PATCH", f"/appStoreVersionLocalizations/{loc['id']}", json={
                "data": {
                    "type": "appStoreVersionLocalizations",
                    "id": loc["id"],
                    "attributes": attrs,
                }
            })
            print(f"Version localization {loc['attributes'].get('locale')}: updated")
        except RuntimeError as error:
            if "whatsNew" in str(error):
                attrs.pop("whatsNew", None)
                patch(
                    f"/appStoreVersionLocalizations/{loc['id']}",
                    "appStoreVersionLocalizations",
                    loc["id"],
                    attrs,
                    f"Version localization {loc['attributes'].get('locale')}",
                )
            else:
                print(f"Version localization {loc['attributes'].get('locale')}: skipped: {error}")


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
    patch(
        f"/ageRatingDeclarations/{app_info_id}",
        "ageRatingDeclarations",
        app_info_id,
        attrs,
        "Age rating",
    )


def ensure_no_data_collected(app_id):
    try:
        usages = list_all(f"/apps/{app_id}/dataUsages?include=category,grouping,purpose,dataProtection&limit=500")
        for usage in usages:
            try:
                api("DELETE", f"/appDataUsages/{usage['id']}")
                print(f"Deleted app data usage {usage['id']}")
            except RuntimeError as error:
                print(f"Delete app data usage skipped {usage['id']}: {error}")
    except RuntimeError as error:
        print(f"Data usage lookup skipped: {error}")

    try:
        api("POST", "/appDataUsages", json={
            "data": {
                "type": "appDataUsages",
                "relationships": {
                    "app": {"data": {"type": "apps", "id": app_id}},
                    "dataProtection": {
                        "data": {
                            "type": "appDataUsageDataProtections",
                            "id": "DATA_NOT_COLLECTED",
                        }
                    },
                },
            }
        })
        print("No data collected usage: updated")
    except RuntimeError as error:
        print(f"No data collected usage: skipped: {error}")

    try:
        payload = api("GET", f"/apps/{app_id}/dataUsagePublishState")
        if payload.get("data"):
            state_id = payload["data"]["id"]
            patch(
                f"/appDataUsagesPublishState/{state_id}",
                "appDataUsagesPublishState",
                state_id,
                {"published": True},
                "App data usage publish",
            )
    except RuntimeError as error:
        print(f"App data usage publish skipped: {error}")


def ensure_jpy_price(app_id):
    points = list_all(
        f"/apps/{app_id}/appPricePoints"
        "?filter[territory]=JPN"
        "&fields[appPricePoints]=customerPrice"
        "&limit=200"
    )
    target = None
    closest = None
    closest_delta = None
    for point in points:
        raw_price = point.get("attributes", {}).get("customerPrice")
        customer_price = str(raw_price or "").rstrip("0").rstrip(".")
        try:
            delta = abs(float(raw_price) - float(TARGET_JPY_PRICE))
            if closest is None or delta < closest_delta:
                closest = point
                closest_delta = delta
        except Exception:
            pass
        if customer_price == TARGET_JPY_PRICE:
            target = point
            break
    if not target:
        target = closest
    if not target:
        print("Price skipped: no JPN price points found. Set it manually in Pricing and Availability.")
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
            "attributes": {"startDate": None},
            "relationships": {
                "appPricePoint": {"data": {"type": "appPricePoints", "id": target["id"]}},
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
