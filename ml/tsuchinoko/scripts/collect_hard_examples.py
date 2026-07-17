#!/usr/bin/env python3
from __future__ import annotations

import csv
import json
import shutil
from collections import Counter
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
EVALUATION_CSV = ROOT / "models" / "evaluation.csv"
REPORT_DIR = ROOT / "models" / "hard_examples"
IMAGE_EXTENSIONS = {".png", ".jpg", ".jpeg", ".webp"}


def read_rows() -> list[dict[str, str]]:
    with EVALUATION_CSV.open(newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle))


def clean_report_dir() -> None:
    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    for child in REPORT_DIR.iterdir():
        if child.is_file() and child.suffix.lower() in IMAGE_EXTENSIONS | {".csv", ".json", ".md"}:
            child.unlink()
        elif child.is_dir():
            shutil.rmtree(child)


def copy_hard_example(row: dict[str, str], index: int) -> str:
    source = ROOT / row["path"]
    kind = "false_positive" if row["expected"] == "not_tsuchinoko" else "false_negative"
    out_dir = REPORT_DIR / kind
    out_dir.mkdir(parents=True, exist_ok=True)
    confidence = row["confidence"].replace(".", "_")
    out_name = f"{index:03d}_{confidence}_{source.name}"
    destination = out_dir / out_name
    shutil.copy2(source, destination)
    return destination.relative_to(ROOT).as_posix()


def main() -> int:
    rows = read_rows()
    hard_rows = [row for row in rows if row.get("correct") != "true"]
    clean_report_dir()

    copied_rows: list[dict[str, str]] = []
    for index, row in enumerate(hard_rows, start=1):
        copied_path = copy_hard_example(row, index)
        copied_rows.append({**row, "copied_path": copied_path})

    counts = Counter(
        "false_positive" if row["expected"] == "not_tsuchinoko" else "false_negative"
        for row in copied_rows
    )
    summary = {
        "total_hard_examples": len(copied_rows),
        "false_positives": counts["false_positive"],
        "false_negatives": counts["false_negative"],
    }

    with (REPORT_DIR / "hard_examples.csv").open("w", newline="", encoding="utf-8") as handle:
        fieldnames = ["path", "expected", "predicted", "confidence", "correct", "copied_path"]
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(copied_rows)

    (REPORT_DIR / "hard_examples.json").write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")

    md_lines = [
        "# Hard Examples",
        "",
        f"- Total: {summary['total_hard_examples']}",
        f"- False positives: {summary['false_positives']}",
        f"- False negatives: {summary['false_negatives']}",
        "",
        "## Files",
        "",
    ]
    for row in copied_rows:
        md_lines.append(f"- `{row['copied_path']}`: expected `{row['expected']}`, predicted `{row['predicted']}`, confidence `{row['confidence']}`")
    (REPORT_DIR / "README.md").write_text("\n".join(md_lines) + "\n", encoding="utf-8")

    print("hard examples")
    print(f"  total: {summary['total_hard_examples']}")
    print(f"  false positives: {summary['false_positives']}")
    print(f"  false negatives: {summary['false_negatives']}")
    print(f"  output: {REPORT_DIR}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
