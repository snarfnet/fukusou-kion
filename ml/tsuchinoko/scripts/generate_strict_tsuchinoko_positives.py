#!/usr/bin/env python3
from __future__ import annotations

import csv
import random
from pathlib import Path

from generate_shape_focus_dataset import POSITIVE_DIR, MANIFEST, tsuchinoko_shape


def ensure_manifest_rows(rows: list[dict[str, str]]) -> None:
    existing_paths = set()
    with MANIFEST.open(newline="", encoding="utf-8") as handle:
        reader = csv.DictReader(handle)
        fieldnames = reader.fieldnames or ["path", "label", "source", "license_status", "notes", "split"]
        existing = list(reader)
        for row in existing:
            existing_paths.add(row["path"])

    additions = [row for row in rows if row["path"] not in existing_paths]
    if not additions:
        return

    with MANIFEST.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(existing)
        writer.writerows(additions)


def main() -> None:
    POSITIVE_DIR.mkdir(parents=True, exist_ok=True)
    manifest_rows: list[dict[str, str]] = []
    rng = random.Random(15000)

    for index in range(72):
        name = f"tsuchinoko_strict_positive_{index + 1:02d}.png"
        path = POSITIVE_DIR / name
        if not path.exists():
            tsuchinoko_shape(15000 + rng.randint(0, 50000)).save(path)
        split = "val" if index < 18 else "train"
        manifest_rows.append({
            "path": f"raw/positive_synthetic/{name}",
            "label": "tsuchinoko_candidate",
            "source": "procedural_strict_positive",
            "license_status": "approved",
            "notes": "procedural strict positive with short thick grounded tsuchinoko-like body",
            "split": split,
        })

    ensure_manifest_rows(manifest_rows)
    print(f"strict positive manifest rows: {len(manifest_rows)}")


if __name__ == "__main__":
    main()
