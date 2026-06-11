#!/usr/bin/env python3
import os

from asc_helpers import api_json, fail, json_body, query


APP_ID = os.environ["APP_ID"]
APP_NAME = os.environ.get("APP_NAME", "OAHSPE:α78")
DEFAULT_LOCALE = os.environ.get("ASC_APP_NAME_LOCALE", "ja")


def app_infos():
    params = query({"limit": "10"})
    return api_json("GET", f"/apps/{APP_ID}/appInfos?{params}").get("data", [])


def localizations(app_info_id):
    params = query({"limit": "200"})
    return api_json("GET", f"/appInfos/{app_info_id}/appInfoLocalizations?{params}").get("data", [])


def update_localization(localization):
    loc_id = localization["id"]
    locale = localization.get("attributes", {}).get("locale", "unknown")
    payload = {
        "data": {
            "type": "appInfoLocalizations",
            "id": loc_id,
            "attributes": {"name": APP_NAME},
        }
    }
    api_json("PATCH", f"/appInfoLocalizations/{loc_id}", data=json_body(payload))
    print(f"Updated App Store Connect name for {locale}: {APP_NAME}")


def create_localization(app_info_id):
    payload = {
        "data": {
            "type": "appInfoLocalizations",
            "attributes": {
                "locale": DEFAULT_LOCALE,
                "name": APP_NAME,
            },
            "relationships": {
                "appInfo": {"data": {"type": "appInfos", "id": app_info_id}}
            },
        }
    }
    created = api_json("POST", "/appInfoLocalizations", data=json_body(payload))["data"]
    print(f"Created App Store Connect name for {DEFAULT_LOCALE}: {APP_NAME} ({created['id']})")


def main():
    infos = app_infos()
    if not infos:
        raise RuntimeError(f"No appInfo found for app {APP_ID}")

    changed = False
    for info in infos:
        locs = localizations(info["id"])
        if not locs:
            create_localization(info["id"])
            changed = True
            continue

        for loc in locs:
            update_localization(loc)
            changed = True

    if not changed:
        raise RuntimeError(f"No App Info localizations updated for app {APP_ID}")


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        fail(error)
