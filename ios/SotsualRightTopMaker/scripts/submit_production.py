import hashlib
import os
import re
import sys
import time

import jwt
import requests

KEY_ID = os.environ["ASC_KEY_ID"]
ISSUER_ID = os.environ["ASC_ISSUER_ID"]
APP_ID = os.environ.get("APP_ID", "6771327196")
APP_VERSION = os.environ.get("APP_VERSION", "1.0")
BUILD_NUMBER = os.environ.get("BUILD_NUMBER")
P8_PATH = os.environ.get("ASC_P8_PATH", "/tmp/asc_key.p8")
SCREENSHOT_DIR = "MarketingAssets/Screenshots"

SCREENSHOT_GROUPS = [
    ("APP_IPHONE_67", ["iphone67_01_home.png", "iphone67_02_templates.png", "iphone67_03_editor.png"]),
    ("APP_IPAD_PRO_3GEN_129", ["ipad129_01_home.png", "ipad129_02_templates.png", "ipad129_03_editor.png"]),
]

JA_DESCRIPTION = """卒アル右上メーカーは、集合写真の右上にある「あの丸い欠席者枠」をかんたんに作れる画像作成アプリです。

卒業アルバム、修学旅行、体育祭、文化祭、遠足、林間学校など、学校行事の集合写真風テンプレートを選び、写真ライブラリから顔写真を追加するだけで、懐かしい卒アル風の1枚を作れます。

「集合写真にいなかった人を、右上の丸いやつで救いたい」
そんな少し笑える発想から生まれたアプリです。

使い方はシンプルです。

まず、好きな集合写真テンプレートを選びます。
次に、写真ライブラリから顔写真を選択します。
選んだ写真は丸く切り抜かれ、右上の欠席者枠に配置されます。
位置、サイズ、写真の拡大縮小、回転も調整できます。

年度、タイトル、学校名、学年、組も自由に入力できます。

たとえば、

令和6年度　卒業記念
〇〇市立〇〇中学校　3年B組

のような文字を入れて、卒業アルバムらしい雰囲気に仕上げられます。

作成した画像は、写真アプリに保存できます。
友達とのネタ画像、送別会の記念画像、旅行に来られなかった人へのプレゼント、SNSで使う思い出風画像など、いろいろな場面で使えます。

無料テンプレートには、王道の卒アル風、修学旅行風、戦後まもない古写真風を収録しています。
追加テンプレートでは、体育祭、文化祭、遊園地風、林間学校、遠足風など、さらに幅広いシーンを楽しめます。

画像処理は端末内で完結します。
選んだ写真をサーバーへ送信することはありません。
AIによる顔生成や自動加工も行いません。

使用しているテンプレート画像に登場する人物はすべて作成物です。
実際の人物、学校、団体とは関係ありません。

卒アルの右上にいた、あの欠席者枠。
それを、今の写真でかんたんに作れるアプリです。"""

META = {
    "ja": {
        "description": JA_DESCRIPTION,
        "keywords": "卒アル,卒業写真,集合写真,欠席者,写真加工,アルバム,修学旅行,体育祭,文化祭,思い出",
        "whatsNew": "初回リリースです。",
        "promotionalText": "卒アルの右上にいた、あの欠席者枠をかんたん作成。",
        "marketingUrl": "https://snarfnet.github.io/",
        "supportUrl": "https://snarfnet.github.io/",
    },
    "en-US": {
        "description": """Sotsual Right Top Maker helps you create the classic round absentee frame often seen in the upper-right corner of Japanese school album photos.

Choose a class photo-style template, add a face photo from your library, adjust the round crop, then enter the year, title, school name, grade, and class. The finished image can be saved to Photos.

Use it for graduation album-style images, school event memories, farewell gifts, travel photos for someone who could not join, or a playful image to share with friends.

Image processing stays on device. Selected photos are not uploaded to a server, and the app does not use AI face generation or automatic AI editing.

People shown in the included template images are created assets. They are not related to real people, schools, or organizations.""",
        "keywords": "graduation,album,class photo,photo editor,school,template,memory,event,absent",
        "whatsNew": "Initial release.",
        "promotionalText": "Create the classic upper-right absentee frame from school album photos.",
        "marketingUrl": "https://snarfnet.github.io/",
        "supportUrl": "https://snarfnet.github.io/",
    },
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
    return list(existing.values())


def update_metadata(version_id):
    for loc in ensure_localizations(version_id):
        locale = loc["attributes"]["locale"]
        meta = META.get(locale, META["en-US"])
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
                "relationships": {"primaryCategory": {"data": {"type": "appCategories", "id": "PHOTO_AND_VIDEO"}}},
            }
        })
        print(f"Primary category: {response.status_code}")
        update_age_rating(app_info_id)
        update_app_info_localizations(app_info_id)

    response = api("PATCH", f"/appStoreVersions/{version_id}", json={
        "data": {
            "type": "appStoreVersions",
            "id": version_id,
            "attributes": {"copyright": "2026 Tokyo Nasu", "usesIdfa": False},
        }
    })
    print(f"Version attributes: {response.status_code}")
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
    attrs["advertising"] = False
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
        locale = loc["attributes"].get("locale")
        subtitle = "卒アル右上の欠席者枠を作成" if locale == "ja" else "Make school album-style frames"
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
    response, body = api_json("GET", f"/apps/{APP_ID}/relationships/appPriceSchedule")
    if response.status_code == 200 and body.get("data"):
        schedule_id = body["data"]["id"]
        response, body = api_json(
            "GET",
            f"/appPriceSchedules/{schedule_id}/manualPrices"
            "?limit=200&include=appPricePoint,territory"
            "&fields[appPricePoints]=customerPrice"
            "&filter[territory]=JPN",
        )
        if response.status_code == 200:
            price_points = {
                item["id"]: item.get("attributes", {}).get("customerPrice")
                for item in body.get("included", [])
                if item.get("type") == "appPricePoints"
            }
            for item in body.get("data", []):
                attrs = item.get("attributes", {})
                point_id = item.get("relationships", {}).get("appPricePoint", {}).get("data", {}).get("id")
                if attrs.get("endDate") is None and str(price_points.get(point_id)) in ("0", "0.0", "0.00"):
                    print("Free price: already set")
                    return

    response, body = api_json(
        "GET",
        f"/apps/{APP_ID}/appPricePoints?filter[territory]=JPN&fields[appPricePoints]=customerPrice&limit=200",
    )
    points = body.get("data", []) if response.status_code == 200 else []
    if not points:
        print("Free price: skipped")
        return
    price_id = None
    for point in points:
        if str(point.get("attributes", {}).get("customerPrice")) in ("0", "0.0", "0.00"):
            price_id = point["id"]
            break
    price_id = price_id or points[0]["id"]
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
    response = api("POST", "/appPriceSchedules", json=payload)
    print(f"Free price: {response.status_code}")
    if response.status_code not in (200, 201, 409):
        print(response.text[:1000])
    elif response.status_code == 409:
        print(response.text[:1000])


def ensure_review_detail(version_id):
    attrs = review_detail_attributes()
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


def review_detail_attributes():
    return {
        "contactFirstName": "Tokyo",
        "contactLastName": "Nasu",
        "contactPhone": "+81 80-2368-9194",
        "contactEmail": "tokyonasu@yahoo.co.jp",
        "demoAccountRequired": False,
        "notes": "ログイン不要です。写真選択、丸窓調整、文字入力、保存機能を端末内で確認できます。画像処理はサーバーへ送信せず端末内で完結します。テンプレート画像に登場している人物はすべて作成物です。実際の人物、学校、団体とは関係ありません。",
    }


def wait_for_build():
    if not BUILD_NUMBER:
        raise RuntimeError("BUILD_NUMBER is required.")
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
        print(f"  {filename}: upload confirm retry {attempt}/6 status={response.status_code}")
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


def cancel_unresolved_review_submissions():
    response, body = api_json("GET", f"/apps/{APP_ID}/reviewSubmissions?limit=20")
    if response.status_code != 200:
        return None
    ready_id = None
    for submission in body.get("data", []):
        state = submission.get("attributes", {}).get("state")
        submission_id = submission["id"]
        if state == "READY_FOR_REVIEW":
            ready_id = ready_id or submission_id
        elif state == "UNRESOLVED_ISSUES":
            response = api("PATCH", f"/reviewSubmissions/{submission_id}", json={
                "data": {
                    "type": "reviewSubmissions",
                    "id": submission_id,
                    "attributes": {"canceled": True},
                }
            })
            print(f"Canceled unresolved review submission {submission_id}: {response.status_code}")
            time.sleep(60)
        elif state in ("WAITING_FOR_REVIEW", "IN_REVIEW"):
            print(f"Already submitted: {submission_id} {state}")
            return "submitted"
    return ready_id


def submit_for_review(version_id):
    submission_id = cancel_unresolved_review_submissions()
    if submission_id == "submitted":
        return
    if submission_id:
        print(f"Using ready review submission: {submission_id}")
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
        if response.status_code == 409:
            if "SCREENSHOT_UPLOADS_IN_PROGRESS" in response.text:
                print("Screenshots are still processing. Waiting before retry.")
                time.sleep(60)
                continue
            if "ITEM_PART_OF_ANOTHER_SUBMISSION" in response.text:
                match = re.search(r"reviewSubmission with id ([0-9a-f-]+)", response.text)
                if match:
                    finish_review_submission(match.group(1))
                    return
            raise RuntimeError(f"Review item blocked: {response.text[:4000]}")
        time.sleep(30)
    finish_review_submission(submission_id)


def finish_review_submission(submission_id):
    for attempt in range(1, 31):
        response, body = api_json("PATCH", f"/reviewSubmissions/{submission_id}", json={
            "data": {"type": "reviewSubmissions", "id": submission_id, "attributes": {"submitted": True}}
        })
        if response.status_code == 200:
            print(f"Submitted for App Review: {body['data']['attributes']['state']}")
            return
        print(f"Review submit {attempt}/30: {response.status_code}")
        time.sleep(60)
    raise RuntimeError(f"Review submit failed: {response.status_code} {response.text[:1000]}")


def main():
    response, body = api_json("GET", f"/apps/{APP_ID}")
    if response.status_code != 200:
        raise RuntimeError(f"App lookup failed {response.status_code}: {response.text[:1000]}")
    attrs = body["data"]["attributes"]
    print(f"App: {attrs.get('name')} / {attrs.get('bundleId')}")

    version_id, state = find_or_create_version()
    ensure_release_prerequisites(version_id)
    update_metadata(version_id)
    if os.environ.get("PREPARE_APP_ONLY") == "1":
        print("App Store Connect metadata is ready.")
        return
    if state in ("WAITING_FOR_REVIEW", "IN_REVIEW"):
        print(f"Already submitted: {state}")
        return

    build_id = wait_for_build()
    upload_screenshots(version_id)
    print("Waiting for screenshot processing...")
    time.sleep(300)
    assign_build(version_id, build_id)
    submit_for_review(version_id)


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        print(str(error), file=sys.stderr)
        sys.exit(1)
