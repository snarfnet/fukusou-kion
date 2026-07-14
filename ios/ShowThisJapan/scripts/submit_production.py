import importlib.util
import os
from pathlib import Path


BASE_PATH = Path(__file__).resolve().parents[2] / "FukusouKion" / "scripts" / "submit_production.py"
spec = importlib.util.spec_from_file_location("asc_submission_base", BASE_PATH)
base = importlib.util.module_from_spec(spec)
spec.loader.exec_module(base)

base.BUNDLE_ID = "com.tokyonasu.showthisjapan"
base.APP_NAME = "Show This Japan"
base.APP_SKU = "show-this-japan-ios"
base.APP_VERSION = os.environ.get("APP_VERSION", "1.0")
base.BUILD_NUMBER = os.environ.get("BUILD_NUMBER", "107")
base.SCREENSHOT_DIR = "output/appstore-1284x2778"
base.SCREENSHOT_GROUPS = [
    ("APP_IPHONE_65", [
        "01-home-1290x2796.png",
        "02-phrase-1290x2796.png",
        "03-emergency-1290x2796.png",
    ])
]
base.META = {
    "en-US": {
        "description": (
            "Show This Japan helps you communicate clearly while traveling in Japan. "
            "Open a phrase card and show the large Japanese text to the person in front of you, "
            "or tap Speak to play the phrase aloud.\n\n"
            "The app includes 150 practical phrases across food, transportation, hotels, shopping, "
            "sightseeing, communication, money, medical situations, emergencies, and basic conversation. "
            "Search in English, save favorites, and reopen recently viewed cards.\n\n"
            "Emergency tools include a profile you can prepare in advance, location assistance, and "
            "confirmation before calling 110 or 119.\n\n"
            "All phrase data works offline. No account, subscription, or external API is required."
        ),
        "keywords": "Japan,travel,Japanese,phrases,translator,offline,tourist,conversation,emergency",
        "whatsNew": "Initial release with 150 offline Japanese phrase cards.",
        "promotionalText": "Show or play the Japanese phrase you need, even when you are offline.",
        "supportUrl": "https://snarfnet.github.io/",
        "marketingUrl": "https://snarfnet.github.io/",
    }
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
        raise RuntimeError(f"{label} failed {response.status_code}: {response.text[:1200]}")


def ensure_app_information(app_id):
    require_ok(base.api("PATCH", f"/apps/{app_id}", json={
        "data": {
            "type": "apps",
            "id": app_id,
            "attributes": {"contentRightsDeclaration": "DOES_NOT_USE_THIRD_PARTY_CONTENT"},
        }
    }), "Content rights")

    response, body = base.api_json("GET", f"/apps/{app_id}/appInfos?limit=10")
    require_ok(response, "App info lookup")
    app_info_id = body["data"][0]["id"]
    require_ok(base.api("PATCH", f"/appInfos/{app_info_id}", json={
        "data": {
            "type": "appInfos",
            "id": app_info_id,
            "relationships": {
                "primaryCategory": {"data": {"type": "appCategories", "id": "TRAVEL"}}
            },
        }
    }), "Travel category")

    response, body = base.api_json("GET", f"/appInfos/{app_info_id}/appInfoLocalizations?limit=20")
    require_ok(response, "App info localizations")
    for localization in body.get("data", []):
        attrs = {
            "subtitle": "Offline Japanese phrase cards",
            "privacyPolicyUrl": "https://snarfnet.github.io/privacy.html",
        }
        require_ok(base.api("PATCH", f"/appInfoLocalizations/{localization['id']}", json={
            "data": {
                "type": "appInfoLocalizations",
                "id": localization["id"],
                "attributes": attrs,
            }
        }), f"App info {localization['attributes'].get('locale')}")

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
    target = "2.99"
    response, schedule = base.api_json("GET", f"/apps/{app_id}/relationships/appPriceSchedule")
    if response.status_code == 200 and schedule.get("data"):
        schedule_id = schedule["data"]["id"]
        response, current = base.api_json(
            "GET",
            f"/appPriceSchedules/{schedule_id}/manualPrices?limit=200&include=appPricePoint,territory"
            "&fields[appPricePoints]=customerPrice&filter[territory]=USA",
        )
        points = {
            item["id"]: str(item.get("attributes", {}).get("customerPrice"))
            for item in current.get("included", []) if item.get("type") == "appPricePoints"
        }
        for price in current.get("data", []):
            point_id = price.get("relationships", {}).get("appPricePoint", {}).get("data", {}).get("id")
            if price.get("attributes", {}).get("endDate") is None and points.get(point_id) == target:
                print("USD 2.99 price: already set")
                return
    response, body = base.api_json(
        "GET",
        f"/apps/{app_id}/appPricePoints?filter[territory]=USA&fields[appPricePoints]=customerPrice&limit=200",
    )
    require_ok(response, "USA price points")
    point = next(
        (item for item in body.get("data", []) if str(item.get("attributes", {}).get("customerPrice")) == target),
        None,
    )
    if not point:
        raise RuntimeError("The USD 2.99 App Store price point was not found.")
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
            "type": "appPrices",
            "id": local_id,
            "attributes": {"startDate": None},
            "relationships": {
                "appPricePoint": {"data": {"type": "appPricePoints", "id": point["id"]}}
            },
        }],
    })
    print(f"USD 2.99 price: {response.status_code}")
    if response.status_code not in (200, 201):
        raise RuntimeError(f"USD 2.99 price failed {response.status_code}: {response.text[:1200]}")


def update_version(version_id):
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
    attrs = {
        **base.REVIEW_CONTACT,
        "demoAccountRequired": False,
        "demoAccountName": "",
        "demoAccountPassword": "",
        "notes": (
            "No login is required. All 150 phrase cards are bundled with the app and work offline. "
            "Tap a card, then tap Speak to hear Japanese audio. Emergency call buttons always show a "
            "confirmation dialog before opening the phone call. Location is requested only when the user "
            "opens emergency location assistance. The app contains no advertising or in-app purchases."
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
                "type": "appStoreReviewDetails",
                "attributes": attrs,
                "relationships": {
                    "appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}}
                },
            }
        }), "Review detail")


def update_metadata(version_id):
    for localization in base.ensure_localizations(version_id):
        locale = localization["attributes"]["locale"]
        attrs = dict(base.META.get(locale, base.META["en-US"]))
        response = base.api("PATCH", f"/appStoreVersionLocalizations/{localization['id']}", json={
            "data": {
                "type": "appStoreVersionLocalizations",
                "id": localization["id"],
                "attributes": attrs,
            }
        })
        if response.status_code == 409:
            attrs.pop("whatsNew", None)
            response = base.api("PATCH", f"/appStoreVersionLocalizations/{localization['id']}", json={
                "data": {
                    "type": "appStoreVersionLocalizations",
                    "id": localization["id"],
                    "attributes": attrs,
                }
            })
        require_ok(response, f"Metadata {locale}")


def screenshots_are_ready(version_id):
    for localization in base.ensure_localizations(version_id):
        sets = base.list_all(
            f"/appStoreVersionLocalizations/{localization['id']}/appScreenshotSets?limit=200"
        )
        iphone_set = next(
            (item for item in sets if item["attributes"]["screenshotDisplayType"] == "APP_IPHONE_65"),
            None,
        )
        if not iphone_set:
            return False
        screenshots = base.list_all(f"/appScreenshotSets/{iphone_set['id']}/appScreenshots?limit=200")
        if len(screenshots) < 3:
            return False
    return True


def ensure_no_data_collected(app_id):
    def iris(method, path, **kwargs):
        now = int(base.time.time())
        iris_token = base.jwt.encode(
            {"iss": base.ISSUER, "iat": now, "exp": now + 1200, "aud": "appstoreconnect-v1"},
            base.p8,
            algorithm="ES256",
            headers={"kid": base.KEY_ID, "typ": "JWT"},
        )
        response = base.requests.request(
            method,
            f"https://appstoreconnect.apple.com/iris/v1{path}",
            headers={"Authorization": f"Bearer {iris_token}", "Content-Type": "application/json"},
            timeout=120,
            **kwargs,
        )
        try:
            return response, response.json()
        except Exception:
            return response, {}

    response, body = iris(
        "GET",
        f"/apps/{app_id}/dataUsages?include=category,grouping,purpose,dataProtection&limit=500",
    )
    require_ok(response, "Privacy usage lookup")
    usages = body.get("data", [])
    if not usages:
        response, _ = iris("POST", "/appDataUsages", json={
            "data": {
                "type": "appDataUsages",
                "relationships": {
                    "app": {"data": {"type": "apps", "id": app_id}},
                    "dataProtection": {
                        "data": {"type": "appDataUsageDataProtections", "id": "DATA_NOT_COLLECTED"}
                    },
                },
            }
        })
        require_ok(response, "No data collected declaration")
    response, body = iris("GET", f"/apps/{app_id}/dataUsagePublishState")
    require_ok(response, "Privacy publish state")
    state_id = body["data"]["id"]
    response, _ = iris("PATCH", f"/appDataUsagesPublishState/{state_id}", json={
        "data": {
            "type": "appDataUsagesPublishState",
            "id": state_id,
            "attributes": {"published": True},
        }
    })
    require_ok(response, "Privacy answers publish")


def submit_for_review(app_id, version_id):
    response, body = base.api_json("GET", f"/apps/{app_id}/reviewSubmissions?limit=20")
    require_ok(response, "Review submission lookup")
    reusable = next(
        (
            item for item in body.get("data", [])
            if item.get("attributes", {}).get("state") in ("READY_FOR_REVIEW", "UNRESOLVED_ISSUES")
        ),
        None,
    )
    if reusable:
        submission_id = reusable["id"]
        print(f"Reusing review submission: {submission_id}")
    else:
        response, body = base.api_json("POST", "/reviewSubmissions", json={
            "data": {
                "type": "reviewSubmissions",
                "attributes": {"platform": "IOS"},
                "relationships": {"app": {"data": {"type": "apps", "id": app_id}}},
            }
        })
        require_ok(response, "Review submission")
        submission_id = body["data"]["id"]
    response = base.api("POST", "/reviewSubmissionItems", json={
        "data": {
            "type": "reviewSubmissionItems",
            "relationships": {
                "reviewSubmission": {
                    "data": {"type": "reviewSubmissions", "id": submission_id}
                },
                "appStoreVersion": {
                    "data": {"type": "appStoreVersions", "id": version_id}
                },
            },
        }
    })
    require_ok(response, "Review item")
    response, body = base.api_json("PATCH", f"/reviewSubmissions/{submission_id}", json={
        "data": {
            "type": "reviewSubmissions",
            "id": submission_id,
            "attributes": {"submitted": True},
        }
    })
    require_ok(response, "Submit for review")
    print(f"Submitted for App Review: {body['data']['attributes']['state']}")


def main():
    app_id = base.find_app_id()
    version_id, state = base.find_or_create_version(app_id)
    if state in ("WAITING_FOR_REVIEW", "IN_REVIEW"):
        print(f"Already submitted: {state}")
        return
    ensure_app_information(app_id)
    ensure_price(app_id)
    ensure_no_data_collected(app_id)
    update_version(version_id)
    update_metadata(version_id)
    if screenshots_are_ready(version_id):
        print("Screenshots: already uploaded")
    else:
        base.upload_screenshots(version_id)
        print("Waiting for screenshot processing...")
        base.time.sleep(300)
    build_id = base.wait_for_build(app_id)
    base.assign_build(version_id, build_id)
    submit_for_review(app_id, version_id)


if __name__ == "__main__":
    main()
