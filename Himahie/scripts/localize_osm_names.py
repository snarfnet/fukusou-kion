"""Replace OSM spot names with Japanese labels from the source PBF.

Only records with an explicit ``name:ja`` or ``official_name:ja`` tag are
changed. English names that are the facility's actual name remain untouched.
"""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

import osmium

PROJECT_ROOT = Path(__file__).resolve().parents[1]
JAPANESE_TEXT = re.compile(r"[\u3040-\u30ff\u3400-\u9fff]")


def japanese_name(tags) -> str | None:
    explicit = tags.get("name:ja") or tags.get("official_name:ja")
    if explicit:
        return explicit
    name = tags.get("name")
    english = tags.get("name:en")
    if name and english and name.startswith(english):
        remainder = name[len(english):].lstrip(" /・-–—")
        if remainder and JAPANESE_TEXT.search(remainder):
            return remainder
    return None


def load_target_ids(resources: Path) -> set[tuple[str, int]]:
    targets: set[tuple[str, int]] = set()
    for path in resources.glob("spots_*.json"):
        for spot in json.loads(path.read_text(encoding="utf-8")):
            parts = spot.get("id", "").split("_")
            if len(parts) == 3 and parts[0] == "osm" and parts[1] in {"node", "way"}:
                targets.add((parts[1], int(parts[2])))
    return targets


def localize(resources: Path, pbf: Path) -> tuple[int, int]:
    targets = load_target_ids(resources)
    names: dict[tuple[str, int], str] = {}
    wanted_ids = {osm_id for _, osm_id in targets}
    processor = osmium.FileProcessor(str(pbf)).with_filter(
        osmium.filter.IdFilter(wanted_ids)
    )
    for obj in processor:
        if isinstance(obj, osmium.osm.Node):
            kind = "node"
        elif isinstance(obj, osmium.osm.Way):
            kind = "way"
        else:
            continue
        key = (kind, obj.id)
        if key in targets and (name := japanese_name(obj.tags)):
            names[key] = name

    changed = 0
    for path in resources.glob("spots_*.json"):
        spots = json.loads(path.read_text(encoding="utf-8"))
        file_changed = False
        for spot in spots:
            parts = spot.get("id", "").split("_")
            if len(parts) != 3 or parts[0] != "osm":
                continue
            localized = names.get((parts[1], int(parts[2])))
            if localized and localized != spot.get("name"):
                spot["name"] = localized
                changed += 1
                file_changed = True
        if file_changed:
            spots.sort(key=lambda item: item["name"])
            path.write_text(
                json.dumps(spots, ensure_ascii=False, separators=(",", ":")),
                encoding="utf-8",
            )
    return changed, len(names)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--resources",
        type=Path,
        default=PROJECT_ROOT / "Himahie/Resources",
    )
    parser.add_argument("--pbf", type=Path, required=True)
    args = parser.parse_args()
    changed, japanese_labels = localize(args.resources, args.pbf)
    print(f"Japanese labels found: {japanese_labels}")
    print(f"Spot names changed: {changed}")


if __name__ == "__main__":
    main()
