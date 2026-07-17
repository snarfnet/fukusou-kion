#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
import hashlib
import shutil
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "manifests" / "dataset.csv"
IMAGE_EXTENSIONS = {".png", ".jpg", ".jpeg", ".webp"}
LABEL_TO_RAW_DIR = {
    "tsuchinoko_candidate": ROOT / "raw" / "positive_field",
    "not_tsuchinoko": ROOT / "raw" / "negative_field",
}
FIELD_DEFAULTS = {
    "tsuchinoko_candidate": ROOT / "field_data" / "positive_review",
    "not_tsuchinoko": ROOT / "field_data" / "negative_review",
}


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def iter_images(root: Path) -> list[Path]:
    return sorted(path for path in root.rglob("*") if path.suffix.lower() in IMAGE_EXTENSIONS)


def read_manifest() -> list[dict[str, str]]:
    with MANIFEST.open(newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle))


def write_manifest(rows: list[dict[str, str]]) -> None:
    fieldnames = ["path", "label", "source", "license_status", "notes"]
    with MANIFEST.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


def existing_hashes(rows: list[dict[str, str]]) -> set[str]:
    hashes: set[str] = set()
    for row in rows:
        raw_path = ROOT / row["path"]
        if raw_path.exists() and raw_path.is_file():
            hashes.add(sha256(raw_path))
    return hashes


def unique_destination(label: str, digest: str, suffix: str) -> Path:
    raw_dir = LABEL_TO_RAW_DIR[label]
    raw_dir.mkdir(parents=True, exist_ok=True)
    base = f"field_{label}_{digest[:12]}"
    candidate = raw_dir / f"{base}{suffix.lower()}"
    index = 2
    while candidate.exists():
        candidate = raw_dir / f"{base}_{index}{suffix.lower()}"
        index += 1
    return candidate


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Import reviewed field images into the tsuchinoko dataset manifest.")
    parser.add_argument("--label", choices=sorted(LABEL_TO_RAW_DIR), required=True)
    parser.add_argument("--source-dir", type=Path, help="Folder to import. Defaults to the matching field_data review folder.")
    parser.add_argument("--license-status", choices=["pending", "approved"], default="pending")
    parser.add_argument("--source", default="field_data")
    parser.add_argument("--notes", default="field image imported after review")
    parser.add_argument("--confirm", action="store_true", help="Copy files and update dataset.csv. Without this, only prints a dry run.")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    source_dir = args.source_dir or FIELD_DEFAULTS[args.label]
    if not source_dir.exists():
        print(f"source directory does not exist: {source_dir}")
        return 1

    rows = read_manifest()
    known_hashes = existing_hashes(rows)
    new_rows: list[dict[str, str]] = []
    skipped = 0

    for source_path in iter_images(source_dir):
        digest = sha256(source_path)
        if digest in known_hashes:
            print(f"skip duplicate: {source_path}")
            skipped += 1
            continue
        destination = unique_destination(args.label, digest, source_path.suffix)
        relative_destination = destination.relative_to(ROOT).as_posix()
        print(f"import: {source_path} -> {relative_destination} ({args.license_status})")
        new_rows.append(
            {
                "path": relative_destination,
                "label": args.label,
                "source": args.source,
                "license_status": args.license_status,
                "notes": args.notes,
            }
        )
        known_hashes.add(digest)
        if args.confirm:
            shutil.copy2(source_path, destination)

    if args.confirm and new_rows:
        rows.extend(new_rows)
        write_manifest(rows)

    mode = "updated" if args.confirm else "dry run"
    print(f"{mode}: {len(new_rows)} import(s), {skipped} duplicate(s)")
    if not args.confirm and new_rows:
        print("run again with --confirm to copy files and update manifests/dataset.csv")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
