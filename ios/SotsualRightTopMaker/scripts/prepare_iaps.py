import hashlib
import os
import sys
import time

import jwt
import requests

KEY_ID = os.environ["ASC_KEY_ID"]
ISSUER_ID = os.environ["ASC_ISSUER_ID"]
APP_ID = os.environ.get("APP_ID", "6771327196")
P8_PATH = os.environ.get("ASC_P8_PATH", "/tmp/asc_key.p8")
REVIEW_SCREENSHOT_DIR = "MarketingAssets/IAPReview"

IAPS = [
    {
        "product_id": "omoide_event_pack",
        "reference_name": "Sotsual Omoide Event Pack",
        "name_ja": "思い出行事パック",
        "description_ja": "体育祭、文化祭、遊園地風、林間学校、遠足風の5テンプレート。",
        "name_en": "Memory Event Pack",
        "description_en": "Adds five event-style photo templates.",
        "screenshot": "omoide_event_pack.png",
    },
    {
        "product_id": "absentee_frame_pack_2",
        "reference_name": "Sotsual Omoide Event Pack 2",
        "name_ja": "思い出行事パック2",
        "description_ja": "明治維新、登山、ユニバ風、物置風、異世界の5テンプレート。",
        "name_en": "Memory Event Pack 2",
        "description_en": "Adds five extra themed photo templates.",
        "screenshot": "absentee_frame_pack_2.png",
    },
]


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
    url = (
        f"https://api.appstoreconnect.apple.com{path}"
        if path.startswith("/v")
        else f"https://api.appstoreconnect.apple.com/v1{path}"
    )
    for _ in range(6):
        response = requests.request(
            method,
            url,
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
            raise RuntimeError(f"List failed {response.status_code}: {response.text[:1200]}")
        rows.extend(body.get("data", []))
        next_url = body.get("links", {}).get("next")
        if next_url:
            next_path = next_url.split("appstoreconnect.apple.com", 1)[1]
        else:
            next_path = None
    return rows


def find_iap(product_id):
    for item in list_all(f"/apps/{APP_ID}/inAppPurchasesV2?limit=200"):
        if item.get("attributes", {}).get("productId") == product_id:
            return item
    return None


def create_or_update_iap(config):
    existing = find_iap(config["product_id"])
    attrs = {
        "name": config["reference_name"],
        "productId": config["product_id"],
        "inAppPurchaseType": "NON_CONSUMABLE",
        "familySharable": False,
        "reviewNote": "This non-consumable unlocks the paid template pack shown in the app. No login is required.",
    }
    if existing:
        iap_id = existing["id"]
        response = api("PATCH", f"/v2/inAppPurchases/{iap_id}", json={
            "data": {
                "type": "inAppPurchases",
                "id": iap_id,
                "attributes": {
                    "name": config["reference_name"],
                    "familySharable": False,
                    "reviewNote": attrs["reviewNote"],
                },
            }
        })
        print(f"IAP update {config['product_id']}: {response.status_code}")
        return iap_id

    response, body = api_json("POST", "/v2/inAppPurchases", json={
        "data": {
            "type": "inAppPurchases",
            "attributes": attrs,
            "relationships": {"app": {"data": {"type": "apps", "id": APP_ID}}},
        }
    })
    if response.status_code not in (200, 201):
        raise RuntimeError(f"IAP create failed {config['product_id']} {response.status_code}: {response.text[:2000]}")
    iap_id = body["data"]["id"]
    print(f"IAP create {config['product_id']}: {iap_id}")
    return iap_id


def upsert_localization(iap_id, locale, name, description):
    localizations = list_all(f"/v2/inAppPurchases/{iap_id}/inAppPurchaseLocalizations?limit=200")
    existing = next((loc for loc in localizations if loc.get("attributes", {}).get("locale") == locale), None)
    payload = {"locale": locale, "name": name, "description": description}
    if existing:
        response = api("PATCH", f"/inAppPurchaseLocalizations/{existing['id']}", json={
            "data": {
                "type": "inAppPurchaseLocalizations",
                "id": existing["id"],
                "attributes": payload,
            }
        })
        print(f"IAP localization update {locale}: {response.status_code}")
        return
    response = api("POST", "/inAppPurchaseLocalizations", json={
        "data": {
            "type": "inAppPurchaseLocalizations",
            "attributes": payload,
            "relationships": {"inAppPurchaseV2": {"data": {"type": "inAppPurchases", "id": iap_id}}},
        }
    })
    print(f"IAP localization create {locale}: {response.status_code}")
    if response.status_code not in (200, 201, 409):
        print(response.text[:1200])


def ensure_price(iap_id):
    response, body = api_json(
        "GET",
        f"/v2/inAppPurchases/{iap_id}/pricePoints"
        "?filter[territory]=JPN&fields[inAppPurchasePricePoints]=customerPrice&limit=200",
    )
    if response.status_code != 200:
        print(f"IAP price point lookup: {response.status_code} {response.text[:1200]}")
        return
    points = body.get("data", [])
    if not points:
        print("IAP price: skipped, no price points")
        return
    price_id = None
    for point in points:
        if str(point.get("attributes", {}).get("customerPrice")) in ("160", "160.0", "160.00"):
            price_id = point["id"]
            break
    price_id = price_id or points[0]["id"]
    local_id = "${manualPrice0}"
    payload = {
        "data": {
            "type": "inAppPurchasePriceSchedules",
            "relationships": {
                "inAppPurchase": {"data": {"type": "inAppPurchases", "id": iap_id}},
                "baseTerritory": {"data": {"type": "territories", "id": "JPN"}},
                "manualPrices": {"data": [{"type": "inAppPurchasePrices", "id": local_id}]},
            },
        },
        "included": [{
            "type": "inAppPurchasePrices",
            "id": local_id,
            "attributes": {"startDate": None},
            "relationships": {
                "inAppPurchasePricePoint": {"data": {"type": "inAppPurchasePricePoints", "id": price_id}}
            },
        }],
    }
    response = api("POST", "/inAppPurchasePriceSchedules", json=payload)
    print(f"IAP price schedule: {response.status_code}")
    if response.status_code not in (200, 201, 409):
        print(response.text[:1600])


def ensure_availability(iap_id):
    response, body = api_json(
        "GET",
        f"/v2/inAppPurchases/{iap_id}/inAppPurchaseAvailability"
        "?fields[inAppPurchaseAvailabilities]=availableInNewTerritories",
    )
    if response.status_code == 200 and body.get("data"):
        print("IAP availability: already set")
        return

    territories = list_all("/territories?limit=200")
    territory_data = [{"type": "territories", "id": territory["id"]} for territory in territories]
    payload = {
        "data": {
            "type": "inAppPurchaseAvailabilities",
            "attributes": {"availableInNewTerritories": True},
            "relationships": {
                "availableTerritories": {"data": territory_data},
                "inAppPurchase": {"data": {"type": "inAppPurchases", "id": iap_id}},
            },
        }
    }
    response = api("POST", "/inAppPurchaseAvailabilities", json=payload)
    print(f"IAP availability: {response.status_code}")
    if response.status_code not in (200, 201, 409):
        print(response.text[:1600])


def upload_review_screenshot(iap_id, filename):
    path = os.path.join(REVIEW_SCREENSHOT_DIR, filename)
    if not os.path.exists(path):
        raise RuntimeError(f"Missing IAP review screenshot: {path}")
    existing_response, existing_body = api_json("GET", f"/v2/inAppPurchases/{iap_id}/appStoreReviewScreenshot")
    existing = existing_body.get("data") if existing_response.status_code == 200 else None
    if existing:
        api("DELETE", f"/inAppPurchaseAppStoreReviewScreenshots/{existing['id']}")
        time.sleep(5)

    with open(path, "rb") as file:
        data = file.read()
    checksum = hashlib.md5(data).hexdigest()
    response, body = api_json("POST", "/inAppPurchaseAppStoreReviewScreenshots", json={
        "data": {
            "type": "inAppPurchaseAppStoreReviewScreenshots",
            "attributes": {"fileName": filename, "fileSize": len(data)},
            "relationships": {"inAppPurchaseV2": {"data": {"type": "inAppPurchases", "id": iap_id}}},
        }
    })
    if response.status_code not in (200, 201):
        raise RuntimeError(f"IAP screenshot create failed {response.status_code}: {response.text[:2000]}")
    screenshot_id = body["data"]["id"]
    for operation in body["data"]["attributes"]["uploadOperations"]:
        request_headers = {item["name"]: item["value"] for item in operation["requestHeaders"]}
        start = operation["offset"]
        end = start + operation["length"]
        requests.put(operation["url"], headers=request_headers, data=data[start:end], timeout=120)
    response = api("PATCH", f"/inAppPurchaseAppStoreReviewScreenshots/{screenshot_id}", json={
        "data": {
            "type": "inAppPurchaseAppStoreReviewScreenshots",
            "id": screenshot_id,
            "attributes": {"uploaded": True, "sourceFileChecksum": checksum},
        }
    })
    print(f"IAP review screenshot {filename}: {response.status_code}")
    if response.status_code not in (200, 201):
        print(response.text[:1600])


def submit_iap(iap_id):
    response = api("POST", "/inAppPurchaseSubmissions", json={
        "data": {
            "type": "inAppPurchaseSubmissions",
            "relationships": {"inAppPurchaseV2": {"data": {"type": "inAppPurchases", "id": iap_id}}},
        }
    })
    print(f"IAP submission: {response.status_code}")
    if response.status_code not in (200, 201, 409):
        print(response.text[:2000])
    if response.status_code == 409:
        print(response.text[:1200])


def open_review_submission_id():
    response, body = api_json("GET", f"/apps/{APP_ID}/reviewSubmissions?limit=20")
    if response.status_code != 200:
        print(f"Review submission lookup: {response.status_code}")
        return None
    for submission in body.get("data", []):
        state = submission.get("attributes", {}).get("state")
        if state in ("READY_FOR_REVIEW", "WAITING_FOR_REVIEW"):
            print(f"Open review submission: {submission['id']} {state}")
            return submission["id"]
    return None


def attach_iaps_to_open_review(iap_ids):
    submission_id = open_review_submission_id()
    if not submission_id:
        print("Open review submission: none")
        return
    for iap_id in iap_ids:
        response = api("POST", "/reviewSubmissionItems", json={
            "data": {
                "type": "reviewSubmissionItems",
                "relationships": {
                    "reviewSubmission": {"data": {"type": "reviewSubmissions", "id": submission_id}},
                    "inAppPurchase": {"data": {"type": "inAppPurchases", "id": iap_id}},
                },
            }
        })
        print(f"Attach IAP to review {iap_id}: {response.status_code}")
        if response.status_code not in (200, 201, 409):
            print(response.text[:1600])
        elif response.status_code == 409:
            print(response.text[:1200])


def main():
    iap_ids = []
    for config in IAPS:
        iap_id = create_or_update_iap(config)
        iap_ids.append(iap_id)
        upsert_localization(iap_id, "ja", config["name_ja"], config["description_ja"])
        upsert_localization(iap_id, "en-US", config["name_en"], config["description_en"])
        ensure_price(iap_id)
        ensure_availability(iap_id)
        upload_review_screenshot(iap_id, config["screenshot"])
        submit_iap(iap_id)
    attach_iaps_to_open_review(iap_ids)


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        print(str(error), file=sys.stderr)
        sys.exit(1)
