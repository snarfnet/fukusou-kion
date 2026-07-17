#!/usr/bin/env python3
import os

from asc_helpers import api, api_json, fail, json_body


APP_ID = os.environ["APP_ID"]
APP_PRICE_JPY = os.environ.get("APP_PRICE_JPY", "100")
START_DATE = os.environ.get("APP_PRICE_START_DATE", "2026-06-02")


def list_all(path):
    items = []
    next_path = path
    while next_path:
        body = api_json("GET", next_path)
        items.extend(body.get("data", []))
        next_url = body.get("links", {}).get("next")
        if not next_url:
            break
        next_path = next_url.split("/v1", 1)[1]
    return items


def find_jpy_price_point(target):
    points = list_all(f"/apps/{APP_ID}/appPricePoints?filter[territory]=JPN&limit=200")
    matches = [point for point in points if price_matches(point, target)]
    if matches:
        return matches[0]
    sample = ", ".join(
        str(point.get("attributes", {}).get("customerPrice")) for point in points[:20]
    )
    raise RuntimeError(f"No JPN app price point found for {target}. Available sample: {sample}")


def price_matches(point, target):
    value = point.get("attributes", {}).get("customerPrice")
    if value is None:
        return False
    try:
        return int(float(str(value))) == int(float(target))
    except ValueError:
        return str(value).strip() == str(target).strip()


def set_jpy_price():
    price_point = find_jpy_price_point(APP_PRICE_JPY)
    local_id = "${manualPriceJpy}"
    payload = {
        "data": {
            "type": "appPriceSchedules",
            "relationships": {
                "app": {"data": {"type": "apps", "id": APP_ID}},
                "baseTerritory": {"data": {"type": "territories", "id": "JPN"}},
                "manualPrices": {"data": [{"type": "appPrices", "id": local_id}]},
            },
        },
        "included": [
            {
                "type": "appPrices",
                "id": local_id,
                "attributes": {"startDate": START_DATE},
                "relationships": {
                    "appPricePoint": {
                        "data": {"type": "appPricePoints", "id": price_point["id"]}
                    }
                },
            }
        ],
    }
    response = api("POST", "/appPriceSchedules", data=json_body(payload))
    print(f"JPY {APP_PRICE_JPY} price schedule: {response.status_code}")
    if response.status_code not in (200, 201, 202, 409):
        raise RuntimeError(f"Price schedule failed {response.status_code}: {response.text[:800]}")


def main():
    set_jpy_price()


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        fail(error)
