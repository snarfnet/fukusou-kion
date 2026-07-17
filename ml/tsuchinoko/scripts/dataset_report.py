#!/usr/bin/env python3
from __future__ import annotations

import csv
from collections import Counter
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def count_images(root: Path) -> Counter[tuple[str, str]]:
    counts: Counter[tuple[str, str]] = Counter()
    if not root.exists():
        return counts
    for path in root.rglob("*"):
        if path.suffix.lower() in {".png", ".jpg", ".jpeg", ".webp"}:
            parts = path.relative_to(root).parts
            if len(parts) >= 3:
                counts[(parts[0], parts[1])] += 1
    return counts


def main() -> None:
    manifest = ROOT / "manifests" / "dataset.csv"
    with manifest.open(newline="", encoding="utf-8") as handle:
        rows = list(csv.DictReader(handle))

    manifest_counts = Counter(row["label"] for row in rows if row.get("license_status") == "approved")
    print("approved raw images")
    for label, count in sorted(manifest_counts.items()):
        print(f"  {label}: {count}")

    for title, root in [("processed", ROOT / "processed"), ("augmented", ROOT / "augmented")]:
        print(title)
        counts = count_images(root)
        for (bucket, label), count in sorted(counts.items()):
            print(f"  {bucket}/{label}: {count}")


if __name__ == "__main__":
    main()
