"""Convert guessed false equipment values to unknown for unverified OSM spots."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "Himahie/Resources"
FIELDS = ("airConditioned", "hasSeats", "hasToilet", "hasWifi", "hasPower")


def main() -> None:
    changed = 0
    for path in sorted(ROOT.glob("spots_*.json")):
        spots = json.loads(path.read_text(encoding="utf-8"))
        for spot in spots:
            if spot.get("verificationStatus") == "verified":
                continue
            for field in FIELDS:
                if spot.get(field) is False:
                    spot[field] = None
                    changed += 1
        path.write_text(
            json.dumps(spots, ensure_ascii=False, separators=(",", ":")),
            encoding="utf-8",
        )
    print(f"Converted to unknown: {changed}")


if __name__ == "__main__":
    main()
