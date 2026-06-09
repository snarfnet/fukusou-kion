import hashlib
import os
import re
import time

import jwt
import requests

KEY_ID = os.environ["ASC_KEY_ID"]
ISSUER_ID = os.environ["ASC_ISSUER_ID"]
APP_ID = os.environ.get("APP_ID", "6777992670")
APP_VERSION = os.environ.get("APP_VERSION", "1.0")
BUILD_NUMBER = os.environ.get("BUILD_NUMBER", "31")
APP_PRICE_JPY = os.environ.get("APP_PRICE_JPY", "100")
P8_PATH = os.environ.get("ASC_P8_PATH", "/tmp/asc_key.p8")
SCREENSHOT_DIR = "MarketingAssets/Screenshots"

REVIEW_CONTACT = {
    "contactFirstName": "Tokyo",
    "contactLastName": "Nasu",
    "contactEmail": "tokyonasu@yahoo.co.jp",
    "contactPhone": "+81 80-2368-9194",
}

SCREENSHOT_GROUPS = [
    ("APP_IPHONE_67", ["iphone67_01_studio.png", "iphone67_02_gallery.png", "iphone67_03_nft_prep.png"]),
    ("APP_IPHONE_65", ["iphone65_01_studio.png", "iphone65_02_gallery.png", "iphone65_03_nft_prep.png"]),
    ("APP_IPAD_PRO_3GEN_129", ["ipad129_01_studio.png", "ipad129_02_gallery.png", "ipad129_03_nft_prep.png"]),
]

META = {
    "en-US": {
        "description": """VoiceprintNFT turns your voice into visual art.

Speak for a few seconds, and the app analyzes the shape of your voice: waveform, pitch, rhythm, silence, energy, and the small changes that make your voice feel personal. From those signals, VoiceprintNFT creates a unique neon artwork.

The result is not a photo, not a face filter, and not a template image. It is generative art drawn from the characteristics of your voice. Some works feel like animals, masks, wings, eyes, constellations, or human silhouettes. Others feel closer to modern line art or electronic poster art. The style changes every time, even when the same person records again.

VoiceprintNFT is designed for people who want personal artwork without using their face, body, or private photos. Your voice becomes the source material, but the app does not store the recorded audio file. It keeps only abstract values used to create the image, such as pitch range, rhythm density, silence pattern, and energy.

After generating an artwork, you can remix it, save it, and export the image with NFT-style metadata. The exported metadata includes traits based on the analyzed voice features, so the artwork has a clear connection to the voice that created it.

VoiceprintNFT also includes a simple NFT preparation flow. Export the PNG and metadata JSON, upload the image to IPFS, replace the image CID in the metadata, then use OpenSea or your preferred minting tool.

The app does not mint or sell NFTs inside the app. It prepares creative assets that you can use outside the app.

VoiceprintNFT is for creative expression, digital identity experiments, generative art, audio art, NFT preparation, and people who want to make something personal without using a camera.

Your voice becomes a visual signature.""",
        "keywords": "voice,nft,generative art,neon,abstract art,opensea,digital art,waveform,audio art,creator",
        "whatsNew": "Initial release.",
        "promotionalText": "Create neon generative art from your voice. Export PNG and metadata for NFT preparation.",
        "marketingUrl": "https://snarfnet.github.io/",
        "supportUrl": "https://snarfnet.github.io/",
    }
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
            raise RuntimeError(f"List failed {response.status_code}: {response.text[:1000]}")
        rows.extend(body.get("data", []))
        next_url = body.get("links", {}).get("next")
        next_path = next_url.split("/v1", 1)[1] if next_url else None
    return rows


def find_or_create_version():
    for version in list_all(f"/apps/{APP_ID}/appStoreVersions?filter[platform]=IOS&limit=200"):
        attrs = version.get("attributes", {})
        if attrs.get("versionString") == APP_VERSION:
            print(f"Found version {APP_VERSION}: {version['id']} state={attrs.get('appStoreState')}")
            return version["id"], attrs.get("appStoreState")

    response, body = api_json("POST", "/appStoreVersions", json={
        "data": {
            "type": "appStoreVersions",
            "attributes": {"platform": "IOS", "versionString": APP_VERSION},
            "relationships": {"app": {"data": {"type": "apps", "id": APP_ID}}},
        }
    })
    if response.status_code not in (200, 201):
        raise RuntimeError(f"Version create failed {response.status_code}: {response.text[:1000]}")
    return body["data"]["id"], "PREPARE_FOR_SUBMISSION"


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
            print(f"Localization created: {locale}")
        else:
            print(f"Localization create skipped {locale}: {response.status_code}")
    return [item for item in existing.values() if item["attributes"]["locale"] in META]


def update_metadata(version_id):
    for loc in ensure_localizations(version_id):
        locale = loc["attributes"]["locale"]
        meta = META[locale]
        response = api("PATCH", f"/appStoreVersionLocalizations/{loc['id']}", json={
            "data": {"type": "appStoreVersionLocalizations", "id": loc["id"], "attributes": meta}
        })
        if response.status_code == 409 and "whatsNew" in meta:
            meta = {key: value for key, value in meta.items() if key != "whatsNew"}
            response = api("PATCH", f"/appStoreVersionLocalizations/{loc['id']}", json={
                "data": {"type": "appStoreVersionLocalizations", "id": loc["id"], "attributes": meta}
            })
        print(f"Metadata {locale}: {response.status_code}")


def ensure_release_prerequisites(version_id):
    response = api("PATCH", f"/apps/{APP_ID}", json={
        "data": {
            "type": "apps",
            "id": APP_ID,
            "attributes": {"contentRightsDeclaration": "DOES_NOT_USE_THIRD_PARTY_CONTENT"},
        }
    })
    print(f"Content rights: {response.status_code}")

    response, body = api_json("GET", f"/apps/{APP_ID}/appInfos?limit=10")
    app_infos = body.get("data", []) if response.status_code == 200 else []
    if app_infos:
        app_info_id = app_infos[0]["id"]
        response = api("PATCH", f"/appInfos/{app_info_id}", json={
            "data": {
                "type": "appInfos",
                "id": app_info_id,
                "relationships": {"primaryCategory": {"data": {"type": "appCategories", "id": "GRAPHICS_AND_DESIGN"}}},
            }
        })
        print(f"Primary category: {response.status_code}")
        update_age_rating(app_info_id)
        update_app_info_localizations(app_info_id)

    response = api("PATCH", f"/appStoreVersions/{version_id}", json={
        "data": {
            "type": "appStoreVersions",
            "id": version_id,
            "attributes": {"copyright": "2026 Tokyo Nasu", "usesIdfa": False, "releaseType": "AFTER_APPROVAL"},
        }
    })
    print(f"Version attributes: {response.status_code}")
    ensure_jpy_price()
    ensure_review_detail(version_id)


def update_age_rating(app_info_id):
    attrs = {
        "alcoholTobaccoOrDrugUseOrReferences": "NONE",
        "contests": "NONE",
        "gamblingSimulated": "NONE",
        "gunsOrOtherWeapons": "NONE",
        "medicalOrTreatmentInformation": "NONE",
        "profanityOrCrudeHumor": "NONE",
        "sexualContentGraphicAndNudity": "NONE",
        "sexualContentOrNudity": "NONE",
        "horrorOrFearThemes": "NONE",
        "matureOrSuggestiveThemes": "NONE",
        "violenceCartoonOrFantasy": "NONE",
        "violenceRealisticProlongedGraphicOrSadistic": "NONE",
        "violenceRealistic": "NONE",
        "messagingAndChat": False,
        "gambling": False,
        "parentalControls": False,
        "ageAssurance": False,
        "userGeneratedContent": False,
        "healthOrWellnessTopics": False,
        "unrestrictedWebAccess": False,
        "lootBox": False,
        "advertising": False,
    }
    response = api("PATCH", f"/ageRatingDeclarations/{app_info_id}", json={
        "data": {"type": "ageRatingDeclarations", "id": app_info_id, "attributes": attrs}
    })
    print(f"Age rating: {response.status_code}")


def update_app_info_localizations(app_info_id):
    response, body = api_json("GET", f"/appInfos/{app_info_id}/appInfoLocalizations?limit=20")
    if response.status_code != 200:
        print(f"App info localization lookup: {response.status_code}")
        return
    for loc in body.get("data", []):
        response = api("PATCH", f"/appInfoLocalizations/{loc['id']}", json={
            "data": {
                "type": "appInfoLocalizations",
                "id": loc["id"],
                "attributes": {
                    "subtitle": "Turn your voice into NFT art",
                    "privacyPolicyUrl": "https://snarfnet.github.io/privacy.html",
                },
            }
        })
        print(f"App info {loc['attributes'].get('locale')}: {response.status_code}")


def ensure_jpy_price():
    response, body = api_json(
        "GET",
        f"/apps/{APP_ID}/appPricePoints?filter[territory]=JPN&fields[appPricePoints]=customerPrice&limit=200",
    )
    points = body.get("data", []) if response.status_code == 200 else []
    while body.get("links", {}).get("next"):
        next_path = body["links"]["next"].split("/v1", 1)[1]
        response, body = api_json("GET", next_path)
        if response.status_code != 200:
            break
        points.extend(body.get("data", []))

    price_id = None
    for point in points:
        if str(point.get("attributes", {}).get("customerPrice")) in (APP_PRICE_JPY, f"{APP_PRICE_JPY}.0", f"{APP_PRICE_JPY}.00"):
            price_id = point["id"]
            break
    if not price_id and points:
        price_id = min(points, key=lambda item: abs(float(item.get("attributes", {}).get("customerPrice") or 0) - float(APP_PRICE_JPY)))["id"]
    if not price_id:
        print("JPY price: skipped")
        return

    local_id = "${manualPrice0}"
    response = api("POST", "/appPriceSchedules", json={
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
            "relationships": {"appPricePoint": {"data": {"type": "appPricePoints", "id": price_id}}},
        }],
    })
    print(f"JPY price: {response.status_code}")
    if response.status_code not in (200, 201, 409):
        print(response.text[:1000])


def ensure_review_detail(version_id):
    attrs = {
        **REVIEW_CONTACT,
        "demoAccountRequired": False,
        "demoAccountName": "",
        "demoAccountPassword": "",
        "notes": (
            "VoiceprintNFT generates visual art from short microphone input. "
            "The app analyzes abstract voice features and does not save the original audio recording. "
            "The NFT flow is preparation-only inside the app. Users can export a PNG and metadata JSON, then continue minting outside the app through OpenSea or another service. "
            "The app does not sell NFTs inside the app and does not include in-app purchases."
        ),
    }
    response, body = api_json("GET", f"/appStoreVersions/{version_id}/appStoreReviewDetail")
    if response.status_code == 200 and body.get("data"):
        detail_id = body["data"]["id"]
        response = api("PATCH", f"/appStoreReviewDetails/{detail_id}", json={
            "data": {"type": "appStoreReviewDetails", "id": detail_id, "attributes": attrs}
        })
        print(f"Review detail update: {response.status_code}")
        return

    response = api("POST", "/appStoreReviewDetails", json={
        "data": {
            "type": "appStoreReviewDetails",
            "attributes": attrs,
            "relationships": {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}}},
        }
    })
    print(f"Review detail create: {response.status_code}")


def wait_for_build():
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
                    raise RuntimeError(f"Screenshot set create failed {response.status_code}: {response.text[:1000]}")
                set_id = body["data"]["id"]
            for screenshot in list_all(f"/appScreenshotSets/{set_id}/appScreenshots?limit=200"):
                api("DELETE", f"/appScreenshots/{screenshot['id']}")
            for filename in filenames:
                upload_screenshot(set_id, filename)


def upload_screenshot(set_id, filename):
    path = os.path.join(SCREENSHOT_DIR, filename)
    if not os.path.exists(path):
        raise RuntimeError(f"Missing screenshot: {path}")
    with open(path, "rb") as file:
        data = file.read()
    checksum = hashlib.md5(data).hexdigest()
    response, body = api_json("POST", "/appScreenshots", json={
        "data": {
            "type": "appScreenshots",
            "attributes": {"fileName": filename, "fileSize": len(data)},
            "relationships": {"appScreenshotSet": {"data": {"type": "appScreenshotSets", "id": set_id}}},
        }
    })
    if response.status_code not in (200, 201):
        raise RuntimeError(f"Screenshot create failed {response.status_code}: {response.text[:1000]}")
    screenshot_id = body["data"]["id"]
    for operation in body["data"]["attributes"]["uploadOperations"]:
        request_headers = {item["name"]: item["value"] for item in operation["requestHeaders"]}
        start = operation["offset"]
        end = start + operation["length"]
        requests.put(operation["url"], headers=request_headers, data=data[start:end], timeout=120)
    response = None
    for attempt in range(1, 7):
        response = api("PATCH", f"/appScreenshots/{screenshot_id}", json={
            "data": {
                "type": "appScreenshots",
                "id": screenshot_id,
                "attributes": {"uploaded": True, "sourceFileChecksum": checksum},
            }
        })
        if response.status_code in (200, 201):
            break
        print(f"  {filename}: confirm retry {attempt}/6 status={response.status_code}")
        time.sleep(20)
    print(f"  {filename}: {response.status_code}")


def assign_build(version_id, build_id):
    response = api("PATCH", f"/builds/{build_id}", json={
        "data": {"type": "builds", "id": build_id, "attributes": {"usesNonExemptEncryption": False}}
    })
    print(f"Build encryption declaration: {response.status_code}")
    response = api("PATCH", f"/appStoreVersions/{version_id}/relationships/build", json={
        "data": {"type": "builds", "id": build_id}
    })
    print(f"Build assigned: {response.status_code}")


def cancel_blocking_submissions():
    canceled = False
    for state in ("UNRESOLVED_ISSUES",):
        response, body = api_json("GET", f"/apps/{APP_ID}/reviewSubmissions?filter[state]={state}&limit=200")
        if response.status_code != 200:
            continue
        for submission in body.get("data", []):
            submission_id = submission["id"]
            response = api("PATCH", f"/reviewSubmissions/{submission_id}", json={
                "data": {"type": "reviewSubmissions", "id": submission_id, "attributes": {"canceled": True}}
            })
            print(f"Canceled {submission_id}: {response.status_code}")
            canceled = True
    if canceled:
        print("Waiting for cancellation to propagate...")
        time.sleep(30)


def submit_for_review(version_id):
    reusable_submission_id = None
    response, body = api_json("GET", f"/apps/{APP_ID}/reviewSubmissions?limit=20")
    if response.status_code == 200:
        for submission in body.get("data", []):
            state = submission.get("attributes", {}).get("state")
            if state in ("WAITING_FOR_REVIEW", "IN_REVIEW"):
                print(f"Already submitted: {submission['id']} {state}")
                return
            if state == "READY_FOR_REVIEW" and not reusable_submission_id:
                reusable_submission_id = submission["id"]
                print(f"Reusing ready review submission: {reusable_submission_id}")

    if reusable_submission_id:
        submission_id = reusable_submission_id
    else:
        response, body = api_json("POST", "/reviewSubmissions", json={
            "data": {
                "type": "reviewSubmissions",
                "attributes": {"platform": "IOS"},
                "relationships": {"app": {"data": {"type": "apps", "id": APP_ID}}},
            }
        })
        if response.status_code not in (200, 201):
            raise RuntimeError(f"Review submission create failed {response.status_code}: {response.text[:1000]}")
        submission_id = body["data"]["id"]

    if review_submission_has_version(submission_id, version_id):
        finish_review_submission(submission_id)
        return

    for attempt in range(1, 61):
        response = api("POST", "/reviewSubmissionItems", json={
            "data": {
                "type": "reviewSubmissionItems",
                "relationships": {
                    "reviewSubmission": {"data": {"type": "reviewSubmissions", "id": submission_id}},
                    "appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}},
                },
            }
        })
        print(f"Review item {attempt}/60: {response.status_code}")
        if response.status_code in (200, 201):
            finish_review_submission(submission_id)
            return
        if response.status_code == 409 and "SCREENSHOT_UPLOADS_IN_PROGRESS" in response.text:
            time.sleep(60)
            continue
        if response.status_code == 409 and "ITEM_PART_OF_ANOTHER_SUBMISSION" in response.text:
            match = re.search(r"reviewSubmission with id ([0-9a-f-]+)", response.text)
            if match:
                finish_review_submission(match.group(1))
                return
        if response.status_code == 409 and review_submission_has_version(submission_id, version_id):
            finish_review_submission(submission_id)
            return
        if attempt == 1 or attempt % 5 == 0 or attempt == 60:
            print(response.text[:1000])
        time.sleep(30)

    if review_submission_has_version(submission_id, version_id):
        finish_review_submission(submission_id)
        return
    raise RuntimeError("Review submission item was not created.")


def review_submission_has_version(submission_id, version_id):
    response, body = api_json("GET", f"/reviewSubmissions/{submission_id}/items?limit=50")
    if response.status_code != 200:
        print(f"Review item lookup: {response.status_code}")
        return False
    for item in body.get("data", []):
        relationship = item.get("relationships", {}).get("appStoreVersion", {})
        if relationship.get("data", {}).get("id") == version_id:
            print(f"Review submission item ready: {item['id']}")
            return True
    print("Review submission item not ready yet.")
    return False


def finish_review_submission(submission_id):
    for attempt in range(1, 31):
        response, body = api_json("PATCH", f"/reviewSubmissions/{submission_id}", json={
            "data": {"type": "reviewSubmissions", "id": submission_id, "attributes": {"submitted": True}}
        })
        if response.status_code == 200:
            print(f"Submitted for App Review: {body['data']['attributes'].get('state')}")
            return
        print(f"Submit retry {attempt}/30: {response.status_code}")
        print(response.text[:1000])
        time.sleep(30)
    raise RuntimeError("Review submit did not complete.")


def main():
    version_id, state = find_or_create_version()
    if state in ("WAITING_FOR_REVIEW", "IN_REVIEW"):
        print(f"Already submitted: {state}")
        return
    build_id = wait_for_build()
    update_metadata(version_id)
    ensure_release_prerequisites(version_id)
    upload_screenshots(version_id)
    print("Waiting for screenshot processing...")
    time.sleep(300)
    cancel_blocking_submissions()
    assign_build(version_id, build_id)
    submit_for_review(version_id)


if __name__ == "__main__":
    main()
