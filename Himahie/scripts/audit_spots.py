"""Audit generated spot data for duplicates and suspicious values."""

from __future__ import annotations

import json
import math
import re
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "Himahie/Resources"


def normalized(value: str) -> str:
    return re.sub(r"[\s・･()（）\-ー]", "", value).casefold()


def distance_m(a: dict, b: dict) -> float:
    lat = math.radians((a["latitude"] + b["latitude"]) / 2)
    dx = math.radians(a["longitude"] - b["longitude"]) * math.cos(lat)
    dy = math.radians(a["latitude"] - b["latitude"])
    return math.hypot(dx, dy) * 6_371_000


def main() -> None:
    catalog = json.loads((ROOT / "prefectures.json").read_text(encoding="utf-8"))
    all_spots: list[dict] = []
    errors: list[str] = []
    for prefecture in catalog:
        spots = json.loads((ROOT / f"{prefecture['fileName']}.json").read_text(encoding="utf-8"))
        if len(spots) != prefecture["spotCount"]:
            errors.append(f"count mismatch: {prefecture['code']}")
        all_spots.extend(spots)

    for spot in all_spots:
        if not spot.get("sourceName") or not spot.get("sourceURL"):
            errors.append(f"missing source: {spot['id']}")
        if spot.get("verificationStatus") == "verified" and not spot.get("officialURL"):
            errors.append(f"verified spot missing official URL: {spot['id']}")

    by_name: dict[str, list[dict]] = defaultdict(list)
    for spot in all_spots:
        by_name[normalized(spot["name"])].append(spot)
        if not (-90 <= spot["latitude"] <= 90 and -180 <= spot["longitude"] <= 180):
            errors.append(f"invalid coordinate: {spot['id']}")

    nearby_duplicates = []
    for group in by_name.values():
        for index, first in enumerate(group):
            for second in group[index + 1:]:
                distance = distance_m(first, second)
                if distance <= 100:
                    nearby_duplicates.append((distance, first, second))

    categories = Counter(spot["category"] for spot in all_spots)
    print(f"spots={len(all_spots)}")
    print(f"verified={sum(spot.get('verificationStatus') == 'verified' for spot in all_spots)}")
    print(f"free_or_likely={sum(spot['price'] == 0 for spot in all_spots)}")
    print(f"price_unknown={sum(spot['price'] < 0 for spot in all_spots)}")
    print(f"air_conditioning_unknown={sum(spot.get('airConditioned') is None for spot in all_spots)}")
    print(f"official_url_present={sum(bool(spot.get('officialURL')) for spot in all_spots)}")
    print(f"nearby_duplicate_pairs={len(nearby_duplicates)}")
    print(f"duplicates_within_30m={sum(item[0] <= 30 for item in nearby_duplicates)}")
    print(f"errors={len(errors)}")
    for category, count in categories.most_common():
        print(f"category:{category}={count}")
    for distance, first, second in sorted(nearby_duplicates, key=lambda item: item[0])[:30]:
        print(f"duplicate:{distance:.0f}m:{first['id']}:{second['id']}:{first['name']}")
    for error in errors[:30]:
        print(f"error:{error}")


if __name__ == "__main__":
    main()
