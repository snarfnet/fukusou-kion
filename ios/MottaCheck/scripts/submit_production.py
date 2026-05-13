import hashlib
import os
import sys
import time

import jwt
import requests
from requests import RequestException

KEY_ID = os.environ["ASC_KEY_ID"]
ISSUER = os.environ["ASC_ISSUER_ID"]
APP_ID = os.environ.get("APP_ID", "6769013627")
APP_VERSION = os.environ.get("APP_VERSION", "1.0")
BUILD_NUMBER = os.environ["BUILD_NUMBER"]
P8_PATH = os.environ.get("ASC_P8_PATH", "/tmp/asc_key.p8")
SCREENSHOT_DIR = "MarketingAssets/Screenshots"

SCREENSHOT_GROUPS = [
    ("APP_IPHONE_67", ["iphone69_01_home.png", "iphone69_02_check.png", "iphone69_03_template.png", "iphone69_04_notice.png", "iphone69_05_history.png"]),
    ("APP_IPHONE_65", ["iphone65_01_home.png", "iphone65_02_check.png", "iphone65_03_template.png", "iphone65_04_notice.png", "iphone65_05_history.png"]),
    ("APP_IPHONE_55", ["iphone55_01_home.png", "iphone55_02_check.png", "iphone55_03_template.png", "iphone55_04_notice.png", "iphone55_05_history.png"]),
    ("APP_IPAD_PRO_3GEN_129", ["ipad129_01_home.png", "ipad129_02_check.png", "ipad129_03_template.png", "ipad129_04_notice.png", "ipad129_05_history.png"]),
]

META = {
    "ja": {
        "description": """忘れ物ゼロは、外出前の持ち物チェックをすばやく済ませるアプリです。

仕事、学校、旅行、ジム、病院など、よく使うシーンのテンプレートを用意しました。自分用のリストも作れます。

朝や出発前の通知を設定して、財布、鍵、スマホなどを出る前に確認できます。忘れやすい持ち物は履歴で見返せます。""",
        "keywords": "忘れ物,持ち物,チェックリスト,通知,旅行,仕事,学校,ジム,病院,リマインダー",
        "whatsNew": "初回リリースです。",
        "promotionalText": "出る前に、財布、鍵、スマホをすばやくチェック。",
        "marketingUrl": "https://snarfnet.github.io/",
    },
    "en-US": {
        "description": """Forgot Nothing helps you check what to bring before leaving.

Use ready-made templates for work, school, travel, gym, and hospital visits, or create your own list.

Set morning and pre-departure notifications, then review items like your wallet, keys, and phone before you go.""",
        "keywords": "checklist,packing,reminder,travel,work,school,gym,notification,items,forgot",
        "whatsNew": "Initial release.",
        "promotionalText": "Check your wallet, keys, phone, and more before you leave.",
        "marketingUrl": "https://snarfnet.github.io/",
    },
}

p8 = open(P8_PATH, encoding="utf-8").read()


def token():
    now = int(time.time())
    return jwt.encode(
        {"iss": ISSUER, "iat": now, "exp": now + 1200, "aud": "appstoreconnect-v1"},
        p8,
        algorithm="ES256",
        headers={"kid": KEY_ID},
    )


def headers():
    return {"Authorization": f"Bearer {token()}", "Content-Type": "application/json"}


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
            raise RuntimeError(f"List failed {response.status_code}: {response.text[:300]}")
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
        raise RuntimeError(f"Version create failed {response.status_code}: {response.text[:300]}")
    return body["data"]["id"], "PREPARE_FOR_SUBMISSION"


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
            time.sleep(10)


def ensure_release_prerequisites(version_id):
    api("PATCH", f"/apps/{APP_ID}", json={
        "data": {
            "type": "apps",
            "id": APP_ID,
            "attributes": {"contentRightsDeclaration": "DOES_NOT_USE_THIRD_PARTY_CONTENT"},
        }
    })

    response, body = api_json("GET", f"/apps/{APP_ID}/appInfos?limit=10")
    app_infos = body.get("data", []) if response.status_code == 200 else []
    if app_infos:
        app_info_id = app_infos[0]["id"]
        api("PATCH", f"/appInfos/{app_info_id}", json={
            "data": {
                "type": "appInfos",
                "id": app_info_id,
                "relationships": {
                    "primaryCategory": {"data": {"type": "appCategories", "id": "PRODUCTIVITY"}}
                },
            }
        })
        update_age_rating(app_info_id)
        update_app_info_localizations(app_info_id)

    api("PATCH", f"/appStoreVersions/{version_id}", json={
        "data": {
            "type": "appStoreVersions",
            "id": version_id,
            "attributes": {"copyright": "2026 Tokyo Nasu"},
        }
    })
    response = api("PATCH", f"/appStoreVersions/{version_id}", json={
        "data": {
            "type": "appStoreVersions",
            "id": version_id,
            "attributes": {"usesIdfa": True},
        }
    })
    print(f"IDFA declaration: {response.status_code}")
    ensure_free_price()
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
    attrs["advertising"] = True
    response = api("PATCH", f"/ageRatingDeclarations/{app_info_id}", json={
        "data": {"type": "ageRatingDeclarations", "id": app_info_id, "attributes": attrs}
    })
    print(f"Age rating: {response.status_code}")


def update_app_info_localizations(app_info_id):
    response, body = api_json("GET", f"/appInfos/{app_info_id}/appInfoLocalizations?limit=20")
    if response.status_code != 200:
        return
    for loc in body.get("data", []):
        locale = loc["attributes"].get("locale")
        subtitle = "出る前の持ち物チェック" if locale == "ja" else "Checklist before you leave"
        response = api("PATCH", f"/appInfoLocalizations/{loc['id']}", json={
            "data": {
                "type": "appInfoLocalizations",
                "id": loc["id"],
                "attributes": {
                    "subtitle": subtitle,
                    "privacyPolicyUrl": "https://snarfnet.github.io/privacy.html",
                },
            }
        })
        print(f"App info {locale}: {response.status_code}")


def ensure_free_price():
    response, body = api_json("GET", f"/apps/{APP_ID}/appPricePoints?filter[territory]=USA&limit=1")
    points = body.get("data", []) if response.status_code == 200 else []
    if not points:
        return
    price_id = points[0]["id"]
    local_id = "${manualPrice0}"
    payload = {
        "data": {
            "type": "appPriceSchedules",
            "relationships": {
                "app": {"data": {"type": "apps", "id": APP_ID}},
                "baseTerritory": {"data": {"type": "territories", "id": "USA"}},
                "manualPrices": {"data": [{"type": "appPrices", "id": local_id}]},
            },
        },
        "included": [{
            "type": "appPrices",
            "id": local_id,
            "attributes": {"startDate": "2026-05-13"},
            "relationships": {
                "appPricePoint": {"data": {"type": "appPricePoints", "id": price_id}}
            },
        }],
    }
    response = api("POST", "/appPriceSchedules", json=payload)
    print(f"Free price: {response.status_code}")


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
                "notes": "No login is required.",
            },
            "relationships": {
                "appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}}
            },
        }
    }
    response = api("POST", "/appStoreReviewDetails", json=payload)
    print(f"Review detail: {response.status_code}")


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
    raise RuntimeError(f"Build {BUILD_NUMBER} did not finish processing")


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


def upload_screenshots(version_id):
    for loc in ensure_localizations(version_id):
        locale = loc["attributes"]["locale"]
        print(f"Screenshots for {locale}")
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
                    raise RuntimeError(f"Screenshot set create failed {response.status_code}: {response.text[:300]}")
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
        raise RuntimeError(f"Screenshot create failed {response.status_code}: {response.text[:300]}")
    screenshot_id = body["data"]["id"]
    for operation in body["data"]["attributes"]["uploadOperations"]:
        request_headers = {item["name"]: item["value"] for item in operation["requestHeaders"]}
        start = operation["offset"]
        end = start + operation["length"]
        upload_binary_part(operation["url"], request_headers, data[start:end])
    response = api("PATCH", f"/appScreenshots/{screenshot_id}", json={
        "data": {
            "type": "appScreenshots",
            "id": screenshot_id,
            "attributes": {"uploaded": True, "sourceFileChecksum": checksum},
        }
    })
    print(f"  {filename}: {response.status_code}")


def upload_binary_part(url, headers, data):
    for attempt in range(1, 6):
        try:
            response = requests.put(url, headers=headers, data=data, timeout=120)
            if response.status_code < 500:
                return response
        except RequestException as error:
            if attempt == 5:
                raise
            print(f"  Upload retry {attempt}/5: {error}")
        time.sleep(5 * attempt)
    return response


def assign_build(version_id, build_id):
    api("PATCH", f"/builds/{build_id}", json={
        "data": {"type": "builds", "id": build_id, "attributes": {"usesNonExemptEncryption": False}}
    })
    response = api("PATCH", f"/appStoreVersions/{version_id}/relationships/build", json={
        "data": {"type": "builds", "id": build_id}
    })
    print(f"Build assigned: {response.status_code}")


def submit_for_review(version_id):
    existing_submission_id = find_reusable_review_submission(prefer_unresolved=True)
    if existing_submission_id:
        print(f"Reusing review submission: {existing_submission_id}")
        submit_review_submission(existing_submission_id)
        return

    response, body = api_json("POST", "/reviewSubmissions", json={
        "data": {
            "type": "reviewSubmissions",
            "attributes": {"platform": "IOS"},
            "relationships": {"app": {"data": {"type": "apps", "id": APP_ID}}},
        }
    })
    if response.status_code == 201:
        submission_id = body["data"]["id"]
    elif response.status_code == 409:
        submission_id = find_reusable_review_submission(prefer_unresolved=False)
        if not submission_id:
            raise RuntimeError(f"Review submission create failed {response.status_code}: {response.text[:300]}")
        print(f"Reusing review submission: {submission_id}")
    else:
        raise RuntimeError(f"Review submission create failed {response.status_code}: {response.text[:300]}")

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
    submit_review_submission(submission_id)


def submit_review_submission(submission_id):
    last_response = None
    for attempt in range(1, 31):
        response, body = api_json("PATCH", f"/reviewSubmissions/{submission_id}", json={
            "data": {"type": "reviewSubmissions", "id": submission_id, "attributes": {"submitted": True}}
        })
        if response.status_code == 200:
            print(f"Submitted for App Review: {body['data']['attributes']['state']}")
            return
        last_response = response
        print(f"Review submit {attempt}/30: {response.status_code}")
        time.sleep(60)
    raise RuntimeError(f"Review submit failed {last_response.status_code}: {last_response.text[:300]}")


def find_reusable_review_submission(prefer_unresolved):
    response, body = api_json("GET", f"/apps/{APP_ID}/reviewSubmissions?limit=20")
    if response.status_code != 200:
        return None
    states = ("UNRESOLVED_ISSUES", "READY_FOR_REVIEW") if prefer_unresolved else ("READY_FOR_REVIEW", "UNRESOLVED_ISSUES")
    for wanted_state in states:
        for submission in body.get("data", []):
            state = submission.get("attributes", {}).get("state")
            if state == wanted_state:
                return submission["id"]
    return None


def main():
    response, body = api_json("GET", f"/apps/{APP_ID}")
    if response.status_code != 200:
        raise RuntimeError(f"App lookup failed {response.status_code}: {response.text[:300]}")
    attrs = body["data"]["attributes"]
    print(f"App: {attrs.get('name')} / {attrs.get('bundleId')}")

    version_id, state = find_or_create_version()
    cancel_open_review_submissions()
    ensure_release_prerequisites(version_id)
    if os.environ.get("PREPARE_APP_ONLY") == "1":
        update_metadata(version_id)
        print("App Store Connect metadata is ready.")
        return

    build_id = wait_for_build()
    update_metadata(version_id)
    upload_screenshots(version_id)
    print("Waiting for screenshot processing...")
    time.sleep(300)
    assign_build(version_id, build_id)
    submit_for_review(version_id)


if __name__ == "__main__":
    main()
