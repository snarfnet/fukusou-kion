#!/usr/bin/env python3
from __future__ import annotations

import csv
import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "manifests" / "dataset.csv"
POSITIVE_DIR = ROOT / "raw" / "positive_synthetic"
NEGATIVE_DIR = ROOT / "raw" / "negative"
SIZE = (1024, 768)


def ground_background(rng: random.Random) -> Image.Image:
    base = Image.new("RGB", SIZE, rng.choice([(58, 70, 44), (67, 58, 43), (52, 64, 52), (76, 70, 56)]))
    draw = ImageDraw.Draw(base, "RGBA")

    for _ in range(360):
        x = rng.randint(-80, SIZE[0] + 80)
        y = rng.randint(0, SIZE[1])
        length = rng.randint(30, 150)
        angle = rng.uniform(-0.7, 0.7)
        color = rng.choice([(36, 74, 32, 95), (92, 72, 42, 90), (26, 54, 30, 80), (116, 96, 58, 70)])
        draw.line((x, y, x + math.cos(angle) * length, y + math.sin(angle) * length), fill=color, width=rng.randint(2, 7))

    for _ in range(55):
        x = rng.randint(0, SIZE[0])
        y = rng.randint(0, SIZE[1])
        r = rng.randint(10, 38)
        color = rng.choice([(35, 87, 34, 100), (84, 65, 35, 95), (92, 92, 51, 75)])
        draw.ellipse((x - r, y - r // 2, x + r, y + r // 2), fill=color)

    return base.filter(ImageFilter.GaussianBlur(radius=0.4))


def add_noise(image: Image.Image, rng: random.Random) -> Image.Image:
    draw = ImageDraw.Draw(image, "RGBA")
    for _ in range(2600):
        v = rng.randint(-18, 22)
        alpha = rng.randint(10, 32)
        x = rng.randint(0, SIZE[0] - 1)
        y = rng.randint(0, SIZE[1] - 1)
        color = (max(0, v), max(0, v), max(0, v), alpha) if v >= 0 else (0, 0, 0, alpha)
        draw.point((x, y), fill=color)
    return image


def tsuchinoko_shape(seed: int) -> Image.Image:
    rng = random.Random(seed)
    image = ground_background(rng).convert("RGBA")
    layer = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer, "RGBA")

    cx = rng.randint(420, 610)
    cy = rng.randint(360, 500)
    body_w = rng.randint(470, 620)
    body_h = rng.randint(130, 210)
    tilt = rng.uniform(-9, 9)
    body_color = rng.choice([(95, 79, 49), (86, 70, 45), (112, 94, 58), (73, 67, 48)])

    bbox = (cx - body_w // 2, cy - body_h // 2, cx + body_w // 2, cy + body_h // 2)
    draw.ellipse(bbox, fill=(*body_color, 245), outline=(37, 31, 22, 230), width=6)

    head_x = cx - body_w // 2 + rng.randint(42, 82)
    head_y = cy + rng.randint(-18, 18)
    head_w = rng.randint(115, 155)
    head_h = rng.randint(86, 120)
    draw.ellipse(
        (head_x - head_w // 2, head_y - head_h // 2, head_x + head_w // 2, head_y + head_h // 2),
        fill=(*(max(0, c - 5) for c in body_color), 250),
        outline=(34, 28, 20, 235),
        width=5,
    )
    eye_x = head_x - rng.randint(20, 34)
    eye_y = head_y - rng.randint(12, 24)
    draw.ellipse((eye_x - 8, eye_y - 8, eye_x + 8, eye_y + 8), fill=(8, 8, 7, 245))

    tail_x = cx + body_w // 2 - rng.randint(20, 52)
    tail_y = cy + rng.randint(-10, 20)
    draw.polygon(
        [(tail_x - 30, tail_y - 42), (tail_x + rng.randint(80, 135), tail_y + rng.randint(-8, 18)), (tail_x - 22, tail_y + 44)],
        fill=(*body_color, 235),
        outline=(36, 30, 22, 220),
    )

    for _ in range(180):
        sx = rng.randint(cx - body_w // 2 + 20, cx + body_w // 2 - 20)
        sy = rng.randint(cy - body_h // 2 + 15, cy + body_h // 2 - 15)
        if ((sx - cx) / (body_w / 2)) ** 2 + ((sy - cy) / (body_h / 2)) ** 2 <= 1:
            shade = rng.randint(-22, 28)
            color = tuple(max(0, min(255, c + shade)) for c in body_color)
            draw.ellipse((sx - 5, sy - 3, sx + 5, sy + 3), fill=(*color, rng.randint(85, 160)))

    layer = layer.rotate(tilt, resample=Image.Resampling.BICUBIC, center=(cx, cy))
    image.alpha_composite(layer)
    return add_noise(image.convert("RGB"), rng)


def negative_shape(seed: int) -> Image.Image:
    rng = random.Random(seed)
    image = ground_background(rng).convert("RGBA")
    layer = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer, "RGBA")
    kind = rng.choice(["snake", "hose", "branch"])

    if kind == "snake":
        points = []
        start_x = rng.randint(130, 260)
        base_y = rng.randint(330, 520)
        for index in range(9):
            x = start_x + index * rng.randint(78, 96)
            y = base_y + int(math.sin(index * rng.uniform(0.8, 1.25)) * rng.randint(35, 75))
            points.append((x, y))
        draw.line(points, fill=(72, 62, 44, 245), width=rng.randint(34, 52), joint="curve")
        draw.line(points, fill=(112, 94, 60, 120), width=rng.randint(8, 14), joint="curve")
    elif kind == "hose":
        y = rng.randint(300, 540)
        points = [(80, y), (280, y + rng.randint(-45, 45)), (520, y + rng.randint(-70, 70)), (930, y + rng.randint(-35, 35))]
        draw.line(points, fill=rng.choice([(45, 72, 48, 245), (38, 38, 34, 245), (83, 91, 70, 245)]), width=rng.randint(42, 64), joint="curve")
        draw.line(points, fill=(160, 170, 138, 70), width=8, joint="curve")
    else:
        x1 = rng.randint(70, 160)
        y1 = rng.randint(260, 560)
        x2 = rng.randint(850, 1000)
        y2 = y1 + rng.randint(-70, 70)
        draw.line((x1, y1, x2, y2), fill=(80, 53, 31, 250), width=rng.randint(44, 78))
        for _ in range(rng.randint(4, 8)):
            bx = rng.randint(min(x1, x2), max(x1, x2))
            by = int(y1 + (y2 - y1) * ((bx - x1) / max(1, x2 - x1)))
            draw.line((bx, by, bx + rng.randint(-130, 130), by + rng.randint(-105, 105)), fill=(72, 48, 30, 230), width=rng.randint(14, 32))

    layer = layer.rotate(rng.uniform(-7, 7), resample=Image.Resampling.BICUBIC)
    image.alpha_composite(layer)
    return add_noise(image.convert("RGB"), rng)


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
    NEGATIVE_DIR.mkdir(parents=True, exist_ok=True)
    manifest_rows: list[dict[str, str]] = []

    for index in range(41):
        name = f"tsuchinoko_shape_focus_{index + 1:02d}.png"
        path = POSITIVE_DIR / name
        if not path.exists():
            tsuchinoko_shape(8100 + index).save(path)
        manifest_rows.append({
            "path": f"raw/positive_synthetic/{name}",
            "label": "tsuchinoko_candidate",
            "source": "procedural_shape_focus",
            "license_status": "approved",
            "notes": "procedural thick short body candidate focusing on silhouette and head-body ratio",
            "split": "train",
        })

    for index in range(36):
        name = f"negative_shape_focus_{index + 1:02d}.png"
        path = NEGATIVE_DIR / name
        if not path.exists():
            negative_shape(9100 + index).save(path)
        manifest_rows.append({
            "path": f"raw/negative/{name}",
            "label": "not_tsuchinoko",
            "source": "procedural_shape_focus",
            "license_status": "approved",
            "notes": "procedural hard negative with long thin snake hose or branch silhouette",
            "split": "train",
        })

    ensure_manifest_rows(manifest_rows)
    print(f"shape focus manifest rows: {len(manifest_rows)}")


if __name__ == "__main__":
    main()
