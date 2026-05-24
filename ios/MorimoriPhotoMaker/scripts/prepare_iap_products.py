#!/usr/bin/env python3
import hashlib
import json
import os
import sys
import time
from pathlib import Path

import requests

from asc_helpers import api, api_json, json_body, query


APP_ID = os.environ.get("MORIMORI_PHOTO_MAKER_APP_ID") or os.environ.get("APP_ID")
BUNDLE_ID = os.environ.get("APP_BUNDLE_ID", "com.tokyonasu.morimoriphotomaker")
CONFIG_PATH = Path("AppStore/iap_products.json")
REVIEW_SCREENSHOT = Path("MarketingAssets/Screenshots/iphone67_02.png")


def list_all(path):
    rows = []
    next_path = path
    while next_path:
        body = api_json("GET", next_path)
        rows.extend(body.get("data", []))
        next_url = body.get("links", {}).get("next")
        if not next_url:
            next_path = None
        elif "/v2/" in next_url:
            next_path = "/v2/" + next_url.split("/v2/", 1)[1]
        elif "/v3/" in next_url:
            next_path = "/v3/" + next_url.split("/v3/", 1)[1]
        else:
            next_path = next_url.split("/v1", 1)[1]
    return rows


def find_app_id():
    if APP_ID:
        return APP_ID
    body = api_json("GET", f"/apps?{query({'filter[bundleId]': BUNDLE_ID, 'limit': '1'})}")
    data = body.get("data", [])
    if not data:
        raise RuntimeError(f"App not found for bundle ID: {BUNDLE_ID}")
    return data[0]["id"]


def load_config():
    return json.loads(CONFIG_PATH.read_text(encoding="utf-8"))


def existing_iaps(app_id):
    rows = list_all(f"/apps/{app_id}/inAppPurchasesV2?limit=200")
    response = api("GET", f"/apps/{app_id}/inAppPurchases?limit=200")
    if response.status_code == 200:
        legacy_rows = response.json().get("data", [])
        print(f"Legacy IAP list count: {len(legacy_rows)}")
        for row in legacy_rows:
            attrs = row.get("attributes", {})
            print(f"Legacy IAP listed: {row.get('id')} {attrs.get('productId')} {attrs.get('state')}")
    else:
        print(f"Legacy IAP list skipped: {response.status_code}")
    print(f"IAP list count: {len(rows)}")
    for row in rows:
        attrs = row.get("attributes", {})
        print(f"IAP listed: {row.get('id')} {attrs.get('productId')} {attrs.get('state')}")
    return {row.get("attributes", {}).get("productId"): row for row in rows}


def find_iap(app_id, product_id):
    response = api(
        "GET",
        f"/apps/{app_id}/inAppPurchasesV2?{query({'filter[productId]': product_id, 'limit': '1'})}",
    )
    if response.status_code != 200:
        return None
    body = response.json()
    data = body.get("data", [])
    if data:
        return data[0]
    return None


def create_iap(app_id, product):
    payload = {
        "data": {
            "type": "inAppPurchases",
            "attributes": {
                "name": product["name"],
                "productId": product["productId"],
                "inAppPurchaseType": "NON_CONSUMABLE",
                "familySharable": False,
                "reviewNote": "This purchase unlocks the listed decoration pack inside the app.",
            },
            "relationships": {
                "app": {"data": {"type": "apps", "id": app_id}},
            },
        }
    }
    response = api("POST", "/v2/inAppPurchases", data=json_body(payload))
    if response.status_code == 201:
        row = response.json()["data"]
        print(f"IAP created: {product['productId']} {row['id']}")
        return row
    if response.status_code == 409:
        print(f"IAP exists/conflict: {product['productId']}")
        print(response.text[:1200])
        return None
    raise RuntimeError(f"IAP create failed {product['productId']}: {response.status_code} {response.text[:1200]}")


def ensure_iap_localization(iap_id, product):
    existing = {
        row.get("attributes", {}).get("locale"): row
        for row in list_all(f"/v2/inAppPurchases/{iap_id}/inAppPurchaseLocalizations?limit=200")
    }
    localizations = {
        "ja": {
            "name": product["name"],
            "description": f"{product['name']}の素材{product['itemCount']}点を解放します。",
        },
        "en-US": {
            "name": product.get("enName", product["id"]),
            "description": f"Unlocks {product['itemCount']} decoration items in this pack.",
        },
    }
    for locale, attrs in localizations.items():
        if locale in existing:
            loc_id = existing[locale]["id"]
            response = api("PATCH", f"/inAppPurchaseLocalizations/{loc_id}", data=json_body({
                "data": {"type": "inAppPurchaseLocalizations", "id": loc_id, "attributes": attrs}
            }))
            print(f"IAP localization update {product['productId']} {locale}: {response.status_code}")
            continue
        payload = {
            "data": {
                "type": "inAppPurchaseLocalizations",
                "attributes": {"locale": locale, **attrs},
                "relationships": {
                    "inAppPurchaseV2": {"data": {"type": "inAppPurchases", "id": iap_id}}
                },
            }
        }
        response = api("POST", "/inAppPurchaseLocalizations", data=json_body(payload))
        print(f"IAP localization create {product['productId']} {locale}: {response.status_code}")
        if response.status_code not in (200, 201, 409):
            print(response.text[:1000])


def price_point_for_iap(iap_id, yen):
    body = api_json(
        "GET",
        f"/v2/inAppPurchases/{iap_id}/pricePoints?"
        f"{query({'filter[territory]': 'JPN', 'fields[inAppPurchasePricePoints]': 'customerPrice', 'limit': '8000'})}",
    )
    for point in body.get("data", []):
        if str(point.get("attributes", {}).get("customerPrice")) in (str(yen), f"{yen}.0", f"{yen}.00"):
            return point["id"]
    raise RuntimeError(f"No JPN IAP price point for {yen} yen on {iap_id}")


def ensure_iap_price(iap_id, product):
    price_id = price_point_for_iap(iap_id, product["priceYen"])
    local_id = "${price1}"
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
                "inAppPurchaseV2": {"data": {"type": "inAppPurchases", "id": iap_id}},
                "inAppPurchasePricePoint": {"data": {"type": "inAppPurchasePricePoints", "id": price_id}},
            },
        }],
    }
    response = api("POST", "/inAppPurchasePriceSchedules", data=json_body(payload))
    print(f"IAP price {product['productId']} {product['priceYen']} JPY: {response.status_code}")
    if response.status_code not in (200, 201, 409):
        print(response.text[:1200])


def all_territories():
    return [{"type": "territories", "id": row["id"]} for row in list_all("/territories?limit=200")]


def ensure_iap_availability(iap_id, product_id):
    response = api("POST", "/inAppPurchaseAvailabilities", data=json_body({
        "data": {
            "type": "inAppPurchaseAvailabilities",
            "attributes": {"availableInNewTerritories": True},
            "relationships": {
                "inAppPurchase": {"data": {"type": "inAppPurchases", "id": iap_id}},
                "availableTerritories": {"data": all_territories()},
            },
        }
    }))
    print(f"IAP availability all territories {product_id}: {response.status_code}")
    if response.status_code not in (200, 201, 409):
        print(response.text[:1200])


def upload_asset(create_path, relationship_name, relationship_type, owner_id, filename):
    data = filename.read_bytes()
    checksum = hashlib.md5(data).hexdigest()
    body = api_json("POST", create_path, data=json_body({
        "data": {
            "type": create_path.rsplit("/", 1)[-1],
            "attributes": {"fileName": filename.name, "fileSize": len(data)},
            "relationships": {
                relationship_name: {"data": {"type": relationship_type, "id": owner_id}}
            },
        }
    }))
    asset_id = body["data"]["id"]
    for operation in body["data"]["attributes"]["uploadOperations"]:
        request_headers = {item["name"]: item["value"] for item in operation["requestHeaders"]}
        start = operation["offset"]
        end = start + operation["length"]
        requests.put(operation["url"], headers=request_headers, data=data[start:end], timeout=120)
    return asset_id, checksum


def ensure_iap_review_screenshot(iap_id, product_id):
    response = api("GET", f"/v2/inAppPurchases/{iap_id}/appStoreReviewScreenshot")
    if response.status_code == 200 and response.json().get("data"):
        print(f"IAP screenshot exists: {product_id}")
        return
    asset_id, checksum = upload_asset(
        "/inAppPurchaseAppStoreReviewScreenshots",
        "inAppPurchaseV2",
        "inAppPurchases",
        iap_id,
        REVIEW_SCREENSHOT,
    )
    response = api("PATCH", f"/inAppPurchaseAppStoreReviewScreenshots/{asset_id}", data=json_body({
        "data": {
            "type": "inAppPurchaseAppStoreReviewScreenshots",
            "id": asset_id,
            "attributes": {"uploaded": True, "sourceFileChecksum": checksum},
        }
    }))
    print(f"IAP screenshot upload {product_id}: {response.status_code}")


def review_submission_for_iap(iap_id, product_id):
    response = api("POST", "/inAppPurchaseSubmissions", data=json_body({
        "data": {
            "type": "inAppPurchaseSubmissions",
            "relationships": {
                "inAppPurchaseV2": {"data": {"type": "inAppPurchases", "id": iap_id}}
            },
        }
    }))
    print(f"IAP review submit {product_id}: {response.status_code}")
    if response.status_code not in (200, 201, 409, 422):
        print(response.text[:1200])
    elif response.status_code in (409, 422):
        print(response.text[:1200])


def existing_subscription_groups(app_id):
    linkages = list_all(f"/apps/{app_id}/relationships/subscriptionGroups?limit=200")
    groups = []
    for linkage in linkages:
        groups.append(api_json("GET", f"/subscriptionGroups/{linkage['id']}")["data"])
    return groups


def ensure_subscription_group(app_id):
    groups = existing_subscription_groups(app_id)
    for group in groups:
        if group.get("attributes", {}).get("referenceName") == "Morimori All Access":
            print(f"Subscription group exists: {group['id']}")
            return group["id"]
    response = api("POST", "/subscriptionGroups", data=json_body({
        "data": {
            "type": "subscriptionGroups",
            "attributes": {"referenceName": "Morimori All Access"},
            "relationships": {"app": {"data": {"type": "apps", "id": app_id}}},
        }
    }))
    if response.status_code != 201:
        raise RuntimeError(f"Subscription group create failed: {response.status_code} {response.text[:1200]}")
    group_id = response.json()["data"]["id"]
    print(f"Subscription group created: {group_id}")
    return group_id


def ensure_subscription(app_id, group_id, subscription):
    rows = []
    for group in existing_subscription_groups(app_id):
        rows.extend(list_all(f"/subscriptionGroups/{group['id']}/subscriptions?limit=200"))
    for row in rows:
        if row.get("attributes", {}).get("productId") == subscription["productId"]:
            print(f"Subscription exists: {subscription['productId']} {row['id']}")
            return row["id"]
    response = api("POST", "/subscriptions", data=json_body({
        "data": {
            "type": "subscriptions",
            "attributes": {
                "name": subscription["name"],
                "productId": subscription["productId"],
                "familySharable": False,
                "reviewNote": "This subscription unlocks all locked decoration packs in the app.",
                "subscriptionPeriod": "ONE_MONTH",
                "groupLevel": 1,
            },
            "relationships": {"group": {"data": {"type": "subscriptionGroups", "id": group_id}}},
        }
    }))
    if response.status_code != 201:
        raise RuntimeError(f"Subscription create failed: {response.status_code} {response.text[:1200]}")
    row = response.json()["data"]
    print(f"Subscription created: {subscription['productId']} {row['id']}")
    return row["id"]


def ensure_subscription_localization(subscription_id, subscription):
    existing = {
        row.get("attributes", {}).get("locale"): row
        for row in list_all(f"/subscriptions/{subscription_id}/subscriptionLocalizations?limit=50")
    }
    localizations = {
        "ja": {
            "name": subscription["name"],
            "description": "すべてのロック素材を月額で使えます。",
        },
        "en-US": {
            "name": "All Access Monthly",
            "description": "Unlocks all locked decoration items with a monthly subscription.",
        },
    }
    for locale, attrs in localizations.items():
        if locale in existing:
            loc_id = existing[locale]["id"]
            response = api("PATCH", f"/subscriptionLocalizations/{loc_id}", data=json_body({
                "data": {"type": "subscriptionLocalizations", "id": loc_id, "attributes": attrs}
            }))
            print(f"Subscription localization update {locale}: {response.status_code}")
            continue
        response = api("POST", "/subscriptionLocalizations", data=json_body({
            "data": {
                "type": "subscriptionLocalizations",
                "attributes": {"locale": locale, **attrs},
                "relationships": {"subscription": {"data": {"type": "subscriptions", "id": subscription_id}}},
            }
        }))
        print(f"Subscription localization create {locale}: {response.status_code}")
        if response.status_code not in (200, 201, 409):
            print(response.text[:1000])


def ensure_subscription_availability(subscription_id):
    response = api("POST", "/subscriptionAvailabilities", data=json_body({
        "data": {
            "type": "subscriptionAvailabilities",
            "attributes": {"availableInNewTerritories": False},
            "relationships": {
                "availableTerritories": {"data": [{"type": "territories", "id": "JPN"}]},
                "subscription": {"data": {"type": "subscriptions", "id": subscription_id}},
            },
        }
    }))
    print(f"Subscription availability JPN: {response.status_code}")
    if response.status_code not in (200, 201, 409):
        print(response.text[:1200])


def price_point_for_subscription(subscription_id, yen):
    body = api_json(
        "GET",
        f"/subscriptions/{subscription_id}/pricePoints?"
        f"{query({'filter[territory]': 'JPN', 'fields[subscriptionPricePoints]': 'customerPrice', 'limit': '8000'})}",
    )
    for point in body.get("data", []):
        if str(point.get("attributes", {}).get("customerPrice")) in (str(yen), f"{yen}.0", f"{yen}.00"):
            return point["id"]
    raise RuntimeError(f"No JPN subscription price point for {yen} yen on {subscription_id}")


def ensure_subscription_price(subscription_id, subscription):
    price_id = price_point_for_subscription(subscription_id, subscription["priceYen"])
    price_points = [{"id": price_id}]
    price_points.extend(list_all(f"/subscriptionPricePoints/{price_id}/equalizations?limit=200"))
    created = 0
    conflicts = 0
    failures = 0
    for point in price_points:
        response = api("POST", "/subscriptionPrices", data=json_body({
            "data": {
                "type": "subscriptionPrices",
                "attributes": {"startDate": None, "preserveCurrentPrice": False},
                "relationships": {
                    "subscription": {"data": {"type": "subscriptions", "id": subscription_id}},
                    "subscriptionPricePoint": {"data": {"type": "subscriptionPricePoints", "id": point["id"]}},
                },
            }
        }))
        if response.status_code in (200, 201):
            created += 1
        elif response.status_code == 409:
            conflicts += 1
        else:
            failures += 1
            print(f"Subscription price point failed {point['id']}: {response.status_code} {response.text[:500]}")
        time.sleep(0.2)
    print(
        f"Subscription prices from {subscription['priceYen']} JPY: "
        f"created={created} conflicts={conflicts} failures={failures}"
    )


def ensure_subscription_review_screenshot(subscription_id):
    response = api("GET", f"/subscriptions/{subscription_id}/appStoreReviewScreenshot")
    if response.status_code == 200 and response.json().get("data"):
        print("Subscription screenshot exists")
        return
    asset_id, checksum = upload_asset(
        "/subscriptionAppStoreReviewScreenshots",
        "subscription",
        "subscriptions",
        subscription_id,
        REVIEW_SCREENSHOT,
    )
    response = api("PATCH", f"/subscriptionAppStoreReviewScreenshots/{asset_id}", data=json_body({
        "data": {
            "type": "subscriptionAppStoreReviewScreenshots",
            "id": asset_id,
            "attributes": {"uploaded": True, "sourceFileChecksum": checksum},
        }
    }))
    print(f"Subscription screenshot upload: {response.status_code}")


def review_submission_for_subscription(subscription_id):
    response = api("POST", "/subscriptionSubmissions", data=json_body({
        "data": {
            "type": "subscriptionSubmissions",
            "relationships": {"subscription": {"data": {"type": "subscriptions", "id": subscription_id}}},
        }
    }))
    print(f"Subscription review submit: {response.status_code}")
    if response.status_code not in (200, 201, 409, 422):
        print(response.text[:1200])
    elif response.status_code in (409, 422):
        print(response.text[:1200])


def main():
    app_id = find_app_id()
    config = load_config()

    for product in config["nonConsumablePacks"]:
        row = find_iap(app_id, product["productId"]) or create_iap(app_id, product)
        if row is None:
            row = find_iap(app_id, product["productId"])
            if row is None:
                print(f"IAP exists but could not be read by product ID; skipped: {product['productId']}")
                continue
        iap_id = row["id"]
        print(f"IAP state {product['productId']}: {row.get('attributes', {}).get('state')}")
        ensure_iap_localization(iap_id, product)
        ensure_iap_price(iap_id, product)
        ensure_iap_availability(iap_id, product["productId"])
        ensure_iap_review_screenshot(iap_id, product["productId"])
        if os.environ.get("SUBMIT_PURCHASES_FOR_REVIEW") == "1":
            review_submission_for_iap(iap_id, product["productId"])
        time.sleep(1)

    group_id = ensure_subscription_group(app_id)
    for subscription in config.get("subscriptions", []):
        subscription_id = ensure_subscription(app_id, group_id, subscription)
        ensure_subscription_localization(subscription_id, subscription)
        ensure_subscription_availability(subscription_id)
        ensure_subscription_price(subscription_id, subscription)
        ensure_subscription_review_screenshot(subscription_id)
        if os.environ.get("SUBMIT_PURCHASES_FOR_REVIEW") == "1":
            review_submission_for_subscription(subscription_id)

    print("IAP setup finished.")


def ensure_iap_localization(iap_id, product):
    existing = {
        row.get("attributes", {}).get("locale"): row
        for row in list_all(f"/v2/inAppPurchases/{iap_id}/inAppPurchaseLocalizations?limit=200")
    }
    localizations = {
        "ja": {
            "name": product["name"],
            "description": f"{product['name']}の素材{product['itemCount']}点を解放します。",
        },
        "en-US": {
            "name": product.get("enName", product["id"]),
            "description": f"Unlocks {product['itemCount']} decoration items in this pack.",
        },
    }
    for locale, attrs in localizations.items():
        if locale in existing:
            loc_id = existing[locale]["id"]
            response = api("PATCH", f"/inAppPurchaseLocalizations/{loc_id}", data=json_body({
                "data": {"type": "inAppPurchaseLocalizations", "id": loc_id, "attributes": attrs}
            }))
            print(f"IAP localization update {product['productId']} {locale}: {response.status_code}")
            continue
        payload = {
            "data": {
                "type": "inAppPurchaseLocalizations",
                "attributes": {"locale": locale, **attrs},
                "relationships": {
                    "inAppPurchaseV2": {"data": {"type": "inAppPurchases", "id": iap_id}}
                },
            }
        }
        response = api("POST", "/inAppPurchaseLocalizations", data=json_body(payload))
        print(f"IAP localization create {product['productId']} {locale}: {response.status_code}")
        if response.status_code not in (200, 201, 409):
            print(response.text[:1000])


def ensure_subscription_localization(subscription_id, subscription):
    existing = {
        row.get("attributes", {}).get("locale"): row
        for row in list_all(f"/subscriptions/{subscription_id}/subscriptionLocalizations?limit=50")
    }
    localizations = {
        "ja": {
            "name": subscription["name"],
            "description": "すべてのロック素材を月額で使えます。",
        },
        "en-US": {
            "name": subscription.get("enName", "All Access Monthly"),
            "description": "Unlocks all locked decoration items with a monthly subscription.",
        },
    }
    for locale, attrs in localizations.items():
        if locale in existing:
            loc_id = existing[locale]["id"]
            response = api("PATCH", f"/subscriptionLocalizations/{loc_id}", data=json_body({
                "data": {"type": "subscriptionLocalizations", "id": loc_id, "attributes": attrs}
            }))
            print(f"Subscription localization update {locale}: {response.status_code}")
            continue
        response = api("POST", "/subscriptionLocalizations", data=json_body({
            "data": {
                "type": "subscriptionLocalizations",
                "attributes": {"locale": locale, **attrs},
                "relationships": {"subscription": {"data": {"type": "subscriptions", "id": subscription_id}}},
            }
        }))
        print(f"Subscription localization create {locale}: {response.status_code}")
        if response.status_code not in (200, 201, 409):
            print(response.text[:1000])


def main():
    app_id = find_app_id()
    config = load_config()
    known_iaps = existing_iaps(app_id)

    for product in config["nonConsumablePacks"]:
        row = known_iaps.get(product["productId"]) or find_iap(app_id, product["productId"]) or create_iap(app_id, product)
        if row is None:
            row = find_iap(app_id, product["productId"])
            if row is None:
                print(f"IAP exists but could not be read by product ID; skipped: {product['productId']}")
                continue
        iap_id = row["id"]
        state = row.get("attributes", {}).get("state")
        print(f"IAP state {product['productId']}: {state}")
        if state in {"WAITING_FOR_REVIEW", "IN_REVIEW"}:
            print(f"IAP under review; metadata not changed: {product['productId']}")
            continue
        ensure_iap_localization(iap_id, product)
        ensure_iap_price(iap_id, product)
        ensure_iap_availability(iap_id, product["productId"])
        ensure_iap_review_screenshot(iap_id, product["productId"])
        if os.environ.get("SUBMIT_PURCHASES_FOR_REVIEW") == "1":
            review_submission_for_iap(iap_id, product["productId"])
        time.sleep(1)

    group_id = ensure_subscription_group(app_id)
    for subscription in config.get("subscriptions", []):
        subscription_id = ensure_subscription(app_id, group_id, subscription)
        ensure_subscription_localization(subscription_id, subscription)
        ensure_subscription_availability(subscription_id)
        ensure_subscription_price(subscription_id, subscription)
        ensure_subscription_review_screenshot(subscription_id)
        if os.environ.get("SUBMIT_PURCHASES_FOR_REVIEW") == "1":
            review_submission_for_subscription(subscription_id)

    print("IAP setup finished.")


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        print(str(error), file=sys.stderr)
        sys.exit(1)
