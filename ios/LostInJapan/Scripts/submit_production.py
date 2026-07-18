import importlib.util
import os
from pathlib import Path


BASE_PATH = Path(__file__).resolve().parents[2] / "LifeRoulette" / "scripts" / "submit_metadata.py"
spec = importlib.util.spec_from_file_location("asc_submission_base", BASE_PATH)
base = importlib.util.module_from_spec(spec)
spec.loader.exec_module(base)

base.BUNDLE_ID = "com.tokyonasu.lostinjapan"
base.APP_NAME = "Lost in Japan - なくしもの案内"
base.APP_SKU = "lost-in-japan-ios"
base.APP_VERSION = os.environ.get("APP_VERSION", "1.0")
base.BUILD_NUMBER = os.environ.get("BUILD_NUMBER", "108")
base.SCREENSHOT_DIR = "MarketingAssets/Screenshots"
base.SCREENSHOT_GROUPS = [
    ("APP_IPHONE_67", [
        "APP_IPHONE_67/01-home.png",
        "APP_IPHONE_67/02-emergency.png",
        "APP_IPHONE_67/03-found-item.png",
    ]),
    ("APP_IPAD_PRO_3GEN_129", [
        "APP_IPAD_PRO_3GEN_129/01-home.png",
        "APP_IPAD_PRO_3GEN_129/02-emergency.png",
        "APP_IPAD_PRO_3GEN_129/03-found-item.png",
    ]),
]
base.META = {
    "en-US": {
        "description": (
            "Lost in Japan helps international visitors take the right steps after losing an item in Japan. "
            "Register what was lost and where it was last seen, then follow a recovery plan for trains, taxis, "
            "hotels, shops, streets, and other common locations.\n\n"
            "Show a clear Japanese assistance card, search for nearby police boxes, and keep each case organized "
            "on your device. Emergency guides cover passports, wallets, phones, payment cards, medicine, missing "
            "children, theft, and approaching departures.\n\n"
            "The interface supports 15 languages. Case details and photos stay on your device. No account, ads, "
            "or subscription is required."
        ),
        "keywords": "Japan,lost property,travel,police box,passport,wallet,phone,tourist,offline",
        "whatsNew": "Initial release with 15-language lost-property guidance.",
        "promotionalText": "Clear next steps when something goes missing during your trip to Japan.",
        "supportUrl": "https://snarfnet.github.io/",
        "marketingUrl": "https://snarfnet.github.io/",
    },
    "ja": {
        "description": (
            "Lost in Japanは、日本を訪れた旅行者が落とし物をしたとき、状況に合った手順を確認できるアプリです。"
            "紛失した品物と最後に見た場所を登録すると、電車、タクシー、ホテル、店舗、路上などに合わせた回収手順を案内します。\n\n"
            "日本語で助けを求めるカード、近くの交番検索、案件ごとの記録機能を備えています。旅券、財布、スマートフォン、"
            "決済カード、薬、迷子、盗難、帰国前の緊急ガイドも収録しています。\n\n"
            "15言語に対応しています。登録した情報と写真は端末内に保存され、アカウント、広告、定期購入はありません。"
        ),
        "keywords": "落とし物,忘れ物,旅行,日本,交番,旅券,財布,スマホ,紛失,訪日",
        "whatsNew": "15言語に対応した落とし物回収ガイドの初回リリースです。",
        "promotionalText": "日本旅行中の落とし物に、状況別のわかりやすい手順を案内します。",
        "supportUrl": "https://snarfnet.github.io/",
        "marketingUrl": "https://snarfnet.github.io/",
    },
}
base.REVIEW_CONTACT = {
    "contactFirstName": "Tokyo",
    "contactLastName": "Nasu",
    "contactEmail": "tokyonasu@yahoo.co.jp",
    "contactPhone": "+81 80-2368-9194",
}


def require_ok(response, label):
    print(f"{label}: {response.status_code}")
    if response.status_code not in (200, 201, 204):
        raise RuntimeError(f"{label} failed {response.status_code}: {response.text[:1600]}")


def ensure_app_information(app_id):
    require_ok(base.api("PATCH", f"/apps/{app_id}", json={
        "data": {
            "type": "apps", "id": app_id,
            "attributes": {"contentRightsDeclaration": "DOES_NOT_USE_THIRD_PARTY_CONTENT"},
        }
    }), "Content rights")

    response, body = base.api_json("GET", f"/apps/{app_id}/appInfos?limit=10")
    require_ok(response, "App info lookup")
    app_info_id = body["data"][0]["id"]
    require_ok(base.api("PATCH", f"/appInfos/{app_info_id}", json={
        "data": {
            "type": "appInfos", "id": app_info_id,
            "relationships": {"primaryCategory": {"data": {"type": "appCategories", "id": "TRAVEL"}}},
        }
    }), "Travel category")

    response, body = base.api_json("GET", f"/appInfos/{app_info_id}/appInfoLocalizations?limit=50")
    require_ok(response, "App info localizations")
    for localization in body.get("data", []):
        locale = localization["attributes"].get("locale")
        subtitle = "訪日旅行者の落とし物案内" if locale == "ja" else "Lost-property help in Japan"
        require_ok(base.api("PATCH", f"/appInfoLocalizations/{localization['id']}", json={
            "data": {
                "type": "appInfoLocalizations", "id": localization["id"],
                "attributes": {
                    "subtitle": subtitle,
                    "privacyPolicyUrl": "https://snarfnet.github.io/privacy.html",
                },
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


def ensure_price(app_id):
    target = "2.0"
    response, body = base.api_json(
        "GET", f"/apps/{app_id}/appPricePoints?filter[territory]=USA&fields[appPricePoints]=customerPrice&limit=200"
    )
    require_ok(response, "USA price points")
    point = next(
        (item for item in body.get("data", []) if str(item.get("attributes", {}).get("customerPrice")) == target),
        None,
    )
    if not point:
        raise RuntimeError("The USD 2.00 price point was not found.")
    local_id = "${manualPrice0}"
    response = base.api("POST", "/appPriceSchedules", json={
        "data": {
            "type": "appPriceSchedules",
            "relationships": {
                "app": {"data": {"type": "apps", "id": app_id}},
                "baseTerritory": {"data": {"type": "territories", "id": "USA"}},
                "manualPrices": {"data": [{"type": "appPrices", "id": local_id}]},
            },
        },
        "included": [{
            "type": "appPrices", "id": local_id,
            "attributes": {"startDate": None},
            "relationships": {"appPricePoint": {"data": {"type": "appPricePoints", "id": point["id"]}}},
        }],
    })
    if response.status_code == 409 and "PRICE_SCHEDULE_ALREADY_EXISTS" in response.text:
        print("USD 2.00 price schedule: already configured")
        return
    require_ok(response, "USD 2.00 price schedule")


def update_version(version_id):
    require_ok(base.api("PATCH", f"/appStoreVersions/{version_id}", json={
        "data": {
            "type": "appStoreVersions", "id": version_id,
            "attributes": {
                "copyright": "2026 Tokyo Nasu", "usesIdfa": False, "releaseType": "AFTER_APPROVAL",
            },
        }
    }), "Version settings")

    attrs = {
        **base.REVIEW_CONTACT,
        "demoAccountRequired": False,
        "demoAccountName": "",
        "demoAccountPassword": "",
        "notes": (
            "No login is required. The app stores case details and selected photos only on the device. "
            "Location permission is used only to search for nearby police boxes. The app does not collect "
            "or transmit personal data and contains no advertising or in-app purchases."
        ),
    }
    response, body = base.api_json("GET", f"/appStoreVersions/{version_id}/appStoreReviewDetail")
    if response.status_code == 200 and body.get("data"):
        detail_id = body["data"]["id"]
        require_ok(base.api("PATCH", f"/appStoreReviewDetails/{detail_id}", json={
            "data": {"type": "appStoreReviewDetails", "id": detail_id, "attributes": attrs}
        }), "Review detail")
    else:
        require_ok(base.api("POST", "/appStoreReviewDetails", json={
            "data": {
                "type": "appStoreReviewDetails", "attributes": attrs,
                "relationships": {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}}},
            }
        }), "Review detail")


def update_metadata(version_id):
    for localization in base.ensure_localizations(version_id):
        locale = localization["attributes"]["locale"]
        attrs = dict(base.META.get(locale, base.META["en-US"]))
        response = base.api("PATCH", f"/appStoreVersionLocalizations/{localization['id']}", json={
            "data": {"type": "appStoreVersionLocalizations", "id": localization["id"], "attributes": attrs}
        })
        if response.status_code == 409:
            attrs.pop("whatsNew", None)
            response = base.api("PATCH", f"/appStoreVersionLocalizations/{localization['id']}", json={
                "data": {"type": "appStoreVersionLocalizations", "id": localization["id"], "attributes": attrs}
            })
        require_ok(response, f"Metadata {locale}")


def ensure_no_data_collected(app_id):
    def iris(method, path, **kwargs):
        now = int(base.time.time())
        with open(base.P8_PATH, encoding="utf-8") as file:
            private_key = file.read()
        token = base.jwt.encode(
            {"iss": base.ISSUER, "iat": now, "exp": now + 1200, "aud": "appstoreconnect-v1"},
            private_key, algorithm="ES256", headers={"kid": base.KEY_ID, "typ": "JWT"},
        )
        response = base.requests.request(
            method, f"https://appstoreconnect.apple.com/iris/v1{path}",
            headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"},
            timeout=120, **kwargs,
        )
        try:
            return response, response.json()
        except Exception:
            return response, {}

    response, body = iris("GET", f"/apps/{app_id}/dataUsages?include=dataProtection&limit=500")
    require_ok(response, "Privacy usage lookup")
    if not body.get("data"):
        response, _ = iris("POST", "/appDataUsages", json={
            "data": {
                "type": "appDataUsages",
                "relationships": {
                    "app": {"data": {"type": "apps", "id": app_id}},
                    "dataProtection": {"data": {"type": "appDataUsageDataProtections", "id": "DATA_NOT_COLLECTED"}},
                },
            }
        })
        require_ok(response, "No data collected declaration")
    response, body = iris("GET", f"/apps/{app_id}/dataUsagePublishState")
    require_ok(response, "Privacy publish state")
    state_id = body["data"]["id"]
    response, _ = iris("PATCH", f"/appDataUsagesPublishState/{state_id}", json={
        "data": {"type": "appDataUsagesPublishState", "id": state_id, "attributes": {"published": True}}
    })
    require_ok(response, "Privacy answers publish")


def submit_for_review(app_id, version_id):
    response, body = base.api_json("GET", f"/apps/{app_id}/reviewSubmissions?limit=20")
    require_ok(response, "Review submission lookup")
    reusable = next((item for item in body.get("data", []) if item.get("attributes", {}).get("state") == "READY_FOR_REVIEW"), None)
    if reusable:
        submission_id = reusable["id"]
    else:
        response, body = base.api_json("POST", "/reviewSubmissions", json={
            "data": {
                "type": "reviewSubmissions", "attributes": {"platform": "IOS"},
                "relationships": {"app": {"data": {"type": "apps", "id": app_id}}},
            }
        })
        require_ok(response, "Review submission")
        submission_id = body["data"]["id"]
    require_ok(base.api("POST", "/reviewSubmissionItems", json={
        "data": {
            "type": "reviewSubmissionItems",
            "relationships": {
                "reviewSubmission": {"data": {"type": "reviewSubmissions", "id": submission_id}},
                "appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}},
            },
        }
    }), "Review item")
    for attempt in range(20):
        response, body = base.api_json("PATCH", f"/reviewSubmissions/{submission_id}", json={
            "data": {"type": "reviewSubmissions", "id": submission_id, "attributes": {"submitted": True}}
        })
        if response.status_code == 200:
            print(f"Submitted for App Review: {body['data']['attributes']['state']}")
            return
        print(f"Waiting for submission prerequisites: {attempt + 1}/20 {response.status_code} {response.text[:500]}")
        base.time.sleep(30)
    require_ok(response, "Submit for review")


def main():
    app_id = base.find_app_id()
    version_id, state = base.find_or_create_version(app_id)
    if state in ("WAITING_FOR_REVIEW", "IN_REVIEW"):
        print(f"Already submitted: {state}")
        return
    ensure_app_information(app_id)
    ensure_price(app_id)
    update_version(version_id)
    update_metadata(version_id)
    build_id = base.wait_for_build(app_id)
    base.upload_screenshots(version_id)
    print("Waiting for screenshot processing...")
    base.time.sleep(300)
    base.assign_build(version_id, build_id)
    submit_for_review(app_id, version_id)


if __name__ == "__main__":
    main()
