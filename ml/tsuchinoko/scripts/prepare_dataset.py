#!/usr/bin/env python3
from __future__ import annotations

import csv
import random
import shutil
from collections import defaultdict
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "manifests" / "dataset.csv"
TRAIN_RATIO = 0.8
LABELS = ["tsuchinoko_candidate", "not_tsuchinoko"]


def clear_processed() -> None:
    for bucket in ["train", "val"]:
        for label in LABELS:
            label_dir = ROOT / "processed" / bucket / label
            label_dir.mkdir(parents=True, exist_ok=True)
            for path in label_dir.iterdir():
                if path.name != ".gitkeep" and path.is_file():
                    path.unlink()


def main() -> None:
    clear_processed()

    rows = []
    with MANIFEST.open(newline="", encoding="utf-8") as handle:
        reader = csv.DictReader(handle)
        for row in reader:
            if row.get("license_status") == "approved":
                rows.append(row)

    grouped = defaultdict(list)
    forced_train = []
    forced_val = []
    for row in rows:
        split = row.get("split", "").strip()
        if split == "train":
            forced_train.append(row)
        elif split == "val":
            forced_val.append(row)
        else:
            grouped[row["label"]].append(row)

    buckets = [("train", []), ("val", [])]
    train_rows = buckets[0][1]
    val_rows = buckets[1][1]
    train_rows.extend(forced_train)
    val_rows.extend(forced_val)
    rng = random.Random(42)
    for label_rows in grouped.values():
        rng.shuffle(label_rows)
        if len(label_rows) < 3:
            train_rows.extend(label_rows)
            continue
        split = max(1, int(len(label_rows) * TRAIN_RATIO))
        train_rows.extend(label_rows[:split])
        val_rows.extend(label_rows[split:])

    for bucket, bucket_rows in buckets:
        for row in bucket_rows:
            src = ROOT / row["path"]
            if not src.exists():
                print(f"missing: {src}")
                continue
            dst = ROOT / "processed" / bucket / row["label"] / src.name
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src, dst)
            print(f"{bucket}: {src.name} -> {row['label']}")


if __name__ == "__main__":
    main()
