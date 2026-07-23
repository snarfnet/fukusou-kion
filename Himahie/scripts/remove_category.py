"""Remove one category from every prefecture file and refresh catalog counts."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("category")
    parser.add_argument(
        "--resources",
        type=Path,
        default=Path(__file__).resolve().parents[1] / "Himahie/Resources",
    )
    args = parser.parse_args()

    catalog_path = args.resources / "prefectures.json"
    catalog = json.loads(catalog_path.read_text(encoding="utf-8"))
    removed_total = 0

    for prefecture in catalog:
        path = args.resources / f"{prefecture['fileName']}.json"
        spots = json.loads(path.read_text(encoding="utf-8"))
        kept = [spot for spot in spots if spot.get("category") != args.category]
        removed = len(spots) - len(kept)
        removed_total += removed
        prefecture["spotCount"] = len(kept)
        path.write_text(
            json.dumps(kept, ensure_ascii=False, separators=(",", ":")),
            encoding="utf-8",
        )
        print(f"{prefecture['name']}: -{removed} / {len(kept)}")

    catalog_path.write_text(
        json.dumps(catalog, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    print(f"Removed: {removed_total}")
    print(f"Remaining: {sum(item['spotCount'] for item in catalog)}")


if __name__ == "__main__":
    main()
