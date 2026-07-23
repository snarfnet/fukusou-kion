"""Merge manually verified spots into generated prefecture JSON files."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "Himahie/Resources"


def main() -> None:
    overrides = json.loads((ROOT / "verified_spots.json").read_text(encoding="utf-8"))
    catalog_path = ROOT / "prefectures.json"
    catalog = json.loads(catalog_path.read_text(encoding="utf-8"))
    by_code = {item["code"]: item for item in catalog}

    for override_with_code in overrides:
        override = dict(override_with_code)
        code = override.pop("prefectureCode")
        path = ROOT / f"spots_{code}.json"
        spots = json.loads(path.read_text(encoding="utf-8"))
        spots = [spot for spot in spots if spot["id"] != override["id"] and spot["name"] != override["name"]]
        spots.append(override)
        spots.sort(key=lambda item: item["name"])
        path.write_text(json.dumps(spots, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
        by_code[code]["spotCount"] = len(spots)

    catalog_path.write_text(json.dumps(catalog, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Applied {len(overrides)} verified spots")
    print(f"Total: {sum(item['spotCount'] for item in catalog)}")


if __name__ == "__main__":
    main()
