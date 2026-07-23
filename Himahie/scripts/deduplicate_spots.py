"""Merge same-name OSM objects located within 30 metres."""

from __future__ import annotations

import json
from pathlib import Path

from audit_spots import distance_m, normalized

ROOT = Path(__file__).resolve().parents[1] / "Himahie/Resources"


def information_score(spot: dict) -> int:
    useful = (
        "address", "officialURL", "openingHoursText", "airConditioned",
        "hasSeats", "hasToilet", "hasWifi", "hasPower",
    )
    score = sum(spot.get(key) not in (None, "", "営業時間未確認") for key in useful)
    if spot.get("verificationStatus") == "verified":
        score += 100
    return score


def merge(preferred: dict, other: dict) -> dict:
    merged = dict(preferred)
    for key, value in other.items():
        if merged.get(key) in (None, "", "営業時間未確認") and value not in (None, ""):
            merged[key] = value
    return merged


def deduplicate(spots: list[dict]) -> tuple[list[dict], int]:
    kept: list[dict] = []
    removed = 0
    for spot in spots:
        match_index = next(
            (
                index for index, candidate in enumerate(kept)
                if normalized(candidate["name"]) == normalized(spot["name"])
                and distance_m(candidate, spot) <= 30
            ),
            None,
        )
        if match_index is None:
            kept.append(spot)
            continue
        preferred, other = (
            (spot, kept[match_index])
            if information_score(spot) > information_score(kept[match_index])
            else (kept[match_index], spot)
        )
        kept[match_index] = merge(preferred, other)
        removed += 1
    return kept, removed


def main() -> None:
    catalog_path = ROOT / "prefectures.json"
    catalog = json.loads(catalog_path.read_text(encoding="utf-8"))
    total_removed = 0
    for prefecture in catalog:
        path = ROOT / f"{prefecture['fileName']}.json"
        spots = json.loads(path.read_text(encoding="utf-8"))
        spots, removed = deduplicate(spots)
        total_removed += removed
        prefecture["spotCount"] = len(spots)
        path.write_text(
            json.dumps(spots, ensure_ascii=False, separators=(",", ":")),
            encoding="utf-8",
        )
    catalog_path.write_text(
        json.dumps(catalog, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    print(f"Removed duplicates: {total_removed}")
    print(f"Remaining: {sum(item['spotCount'] for item in catalog)}")


if __name__ == "__main__":
    main()
