#!/usr/bin/env python3
from __future__ import annotations

import csv
import hashlib
import sys
from collections import Counter, defaultdict
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "manifests" / "dataset.csv"
IMAGE_EXTENSIONS = {".png", ".jpg", ".jpeg", ".webp"}
EXPECTED_LABELS = {"tsuchinoko_candidate", "not_tsuchinoko"}
EXPECTED_SPLITS = {"", "train", "val"}
MIN_RAW_PER_LABEL = 8
MIN_AUGMENTED_PER_LABEL = 1500
MAX_BALANCE_RATIO = 1.25


def image_paths(root: Path) -> list[Path]:
    if not root.exists():
        return []
    return sorted(path for path in root.rglob("*") if path.suffix.lower() in IMAGE_EXTENSIONS)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def read_manifest() -> list[dict[str, str]]:
    with MANIFEST.open(newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle))


def check_manifest(rows: list[dict[str, str]]) -> list[str]:
    errors: list[str] = []
    seen_paths: set[str] = set()
    approved_counts: Counter[str] = Counter()

    for index, row in enumerate(rows, start=2):
        path = row.get("path", "")
        label = row.get("label", "")
        status = row.get("license_status", "")
        if not path:
            errors.append(f"dataset.csv:{index}: path is empty")
            continue
        if path in seen_paths:
            errors.append(f"dataset.csv:{index}: duplicate path: {path}")
        seen_paths.add(path)
        if label not in EXPECTED_LABELS:
            errors.append(f"dataset.csv:{index}: unexpected label: {label}")
        split = row.get("split", "").strip()
        if split not in EXPECTED_SPLITS:
            errors.append(f"dataset.csv:{index}: unexpected split: {split}")
        if status == "approved":
            approved_counts[label] += 1
            source_path = ROOT / path
            if not source_path.exists():
                errors.append(f"dataset.csv:{index}: missing approved file: {path}")
            elif source_path.suffix.lower() not in IMAGE_EXTENSIONS:
                errors.append(f"dataset.csv:{index}: unsupported image extension: {path}")

    for label in sorted(EXPECTED_LABELS):
        count = approved_counts[label]
        if count < MIN_RAW_PER_LABEL:
            errors.append(f"approved raw images for {label} is {count}, expected at least {MIN_RAW_PER_LABEL}")

    if approved_counts:
        smallest = min(approved_counts[label] for label in EXPECTED_LABELS)
        largest = max(approved_counts[label] for label in EXPECTED_LABELS)
        if smallest == 0 or largest / smallest > MAX_BALANCE_RATIO:
            errors.append(f"approved raw class balance is too uneven: {dict(approved_counts)}")

    return errors


def check_duplicate_content(paths: list[Path], title: str) -> list[str]:
    errors: list[str] = []
    by_hash: defaultdict[str, list[Path]] = defaultdict(list)
    for path in paths:
        by_hash[sha256(path)].append(path)
    for digest, duplicates in sorted(by_hash.items()):
        if len(duplicates) > 1:
            rels = ", ".join(str(path.relative_to(ROOT)) for path in duplicates[:6])
            extra = "" if len(duplicates) <= 6 else f", +{len(duplicates) - 6} more"
            errors.append(f"{title}: duplicate image content {digest[:12]}: {rels}{extra}")
    return errors


def check_image_health(paths: list[Path], title: str) -> list[str]:
    errors: list[str] = []
    for path in paths:
        rel = path.relative_to(ROOT)
        if path.stat().st_size < 1024:
            errors.append(f"{title}: very small image file: {rel}")
            continue
        try:
            with Image.open(path) as image:
                width, height = image.size
                image.verify()
        except Exception as exc:  # noqa: BLE001 - report bad training assets clearly
            errors.append(f"{title}: cannot read image {rel}: {exc}")
            continue
        if width < 128 or height < 128:
            errors.append(f"{title}: image is too small: {rel} ({width}x{height})")
    return errors


def count_bucket_labels(root: Path) -> Counter[tuple[str, str]]:
    counts: Counter[tuple[str, str]] = Counter()
    for path in image_paths(root):
        rel_parts = path.relative_to(root).parts
        if len(rel_parts) >= 3:
            bucket, label = rel_parts[0], rel_parts[1]
            counts[(bucket, label)] += 1
    return counts


def check_augmented_counts() -> list[str]:
    errors: list[str] = []
    counts = count_bucket_labels(ROOT / "augmented")
    total_by_label: Counter[str] = Counter()
    for (_bucket, label), count in counts.items():
        total_by_label[label] += count

    for label in sorted(EXPECTED_LABELS):
        count = total_by_label[label]
        if count < MIN_AUGMENTED_PER_LABEL:
            errors.append(f"augmented images for {label} is {count}, expected at least {MIN_AUGMENTED_PER_LABEL}")

    if total_by_label:
        smallest = min(total_by_label[label] for label in EXPECTED_LABELS)
        largest = max(total_by_label[label] for label in EXPECTED_LABELS)
        if smallest == 0 or largest / smallest > MAX_BALANCE_RATIO:
            errors.append(f"augmented class balance is too uneven: {dict(total_by_label)}")

    return errors


def main() -> int:
    rows = read_manifest()
    raw_paths = [ROOT / row["path"] for row in rows if row.get("license_status") == "approved" and row.get("path")]
    processed_paths = image_paths(ROOT / "processed")
    augmented_paths = image_paths(ROOT / "augmented")

    errors: list[str] = []
    errors.extend(check_manifest(rows))
    errors.extend(check_duplicate_content(raw_paths, "raw"))
    errors.extend(check_image_health(raw_paths, "raw"))
    errors.extend(check_image_health(processed_paths, "processed"))
    errors.extend(check_image_health(augmented_paths, "augmented"))
    errors.extend(check_augmented_counts())

    print("quality check")
    print(f"  approved raw images: {len(raw_paths)}")
    print(f"  processed images: {len(processed_paths)}")
    print(f"  augmented images: {len(augmented_paths)}")

    if errors:
        print("errors")
        for error in errors:
            print(f"  - {error}")
        return 1

    print("  status: ok")
    return 0


if __name__ == "__main__":
    sys.exit(main())
