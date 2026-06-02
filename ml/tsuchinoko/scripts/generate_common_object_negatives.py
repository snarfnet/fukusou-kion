#!/usr/bin/env python3
from __future__ import annotations

import csv
import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "manifests" / "dataset.csv"
NEGATIVE_DIR = ROOT / "raw" / "negative"
SIZE = (1024, 768)


def outdoor_background(rng: random.Random) -> Image.Image:
    base = Image.new("RGB", SIZE, rng.choice([(62, 68, 51), (74, 67, 55), (48, 61, 48), (82, 78, 65)]))
    draw = ImageDraw.Draw(base, "RGBA")

    for _ in range(320):
        x = rng.randint(-60, SIZE[0] + 60)
        y = rng.randint(0, SIZE[1])
        length = rng.randint(20, 180)
        angle = rng.uniform(-0.9, 0.9)
        color = rng.choice([(32, 76, 33, 85), (100, 82, 50, 80), (42, 42, 34, 75), (120, 111, 82, 55)])
        draw.line(
            (x, y, x + math.cos(angle) * length, y + math.sin(angle) * length),
            fill=color,
            width=rng.randint(2, 9),
        )

    for _ in range(70):
        x = rng.randint(0, SIZE[0])
        y = rng.randint(0, SIZE[1])
        r = rng.randint(10, 48)
        color = rng.choice([(34, 92, 36, 90), (98, 73, 38, 85), (111, 105, 66, 60)])
        draw.ellipse((x - r, y - r // 2, x + r, y + r // 2), fill=color)

    return base.filter(ImageFilter.GaussianBlur(radius=rng.uniform(0.2, 0.8)))


def add_camera_noise(image: Image.Image, rng: random.Random) -> Image.Image:
    draw = ImageDraw.Draw(image, "RGBA")
    for _ in range(2200):
        value = rng.randint(-22, 24)
        alpha = rng.randint(8, 30)
        x = rng.randint(0, SIZE[0] - 1)
        y = rng.randint(0, SIZE[1] - 1)
        color = (value, value, value, alpha) if value >= 0 else (0, 0, 0, alpha)
        draw.point((x, y), fill=color)
    if rng.random() < 0.35:
        image = image.filter(ImageFilter.GaussianBlur(radius=rng.uniform(0.15, 0.8)))
    return image


def draw_hat(draw: ImageDraw.ImageDraw, rng: random.Random, cx: int, cy: int, scale: float) -> None:
    w = int(260 * scale)
    h = int(125 * scale)
    color = rng.choice([(30, 34, 38, 245), (112, 81, 45, 245), (43, 87, 66, 245), (142, 133, 108, 245)])
    draw.ellipse((cx - w // 2, cy - h // 2, cx + w // 2, cy + h // 2), fill=color, outline=(18, 18, 18, 210), width=max(2, int(5 * scale)))
    brim_w = int(350 * scale)
    brim_h = int(50 * scale)
    draw.ellipse((cx - brim_w // 2, cy + h // 8, cx + brim_w // 2, cy + h // 8 + brim_h), fill=(*color[:3], 235))


def draw_cloth(draw: ImageDraw.ImageDraw, rng: random.Random, cx: int, cy: int, scale: float) -> None:
    w = int(360 * scale)
    h = int(210 * scale)
    color = rng.choice([(210, 205, 188, 240), (78, 88, 144, 240), (166, 58, 54, 235), (54, 90, 72, 235)])
    points = []
    for index in range(12):
        angle = math.tau * index / 12
        rx = w * rng.uniform(0.35, 0.55)
        ry = h * rng.uniform(0.28, 0.55)
        points.append((cx + int(math.cos(angle) * rx), cy + int(math.sin(angle) * ry)))
    draw.polygon(points, fill=color, outline=(35, 35, 35, 120))
    for _ in range(5):
        x1 = cx + rng.randint(-w // 3, w // 3)
        y1 = cy + rng.randint(-h // 3, h // 3)
        draw.arc((x1 - w // 4, y1 - h // 4, x1 + w // 4, y1 + h // 4), 0, 180, fill=(255, 255, 255, 65), width=max(2, int(4 * scale)))


def draw_bag(draw: ImageDraw.ImageDraw, rng: random.Random, cx: int, cy: int, scale: float) -> None:
    w = int(300 * scale)
    h = int(230 * scale)
    color = rng.choice([(34, 45, 55, 245), (95, 68, 42, 245), (42, 74, 96, 245), (125, 112, 91, 245)])
    draw.rounded_rectangle((cx - w // 2, cy - h // 2, cx + w // 2, cy + h // 2), radius=max(8, int(30 * scale)), fill=color, outline=(20, 20, 20, 210), width=max(2, int(5 * scale)))
    draw.arc((cx - w // 3, cy - h // 2 - int(70 * scale), cx + w // 3, cy - h // 5), 200, 340, fill=(28, 28, 28, 230), width=max(5, int(16 * scale)))


def draw_shoe(draw: ImageDraw.ImageDraw, rng: random.Random, cx: int, cy: int, scale: float) -> None:
    w = int(360 * scale)
    h = int(135 * scale)
    color = rng.choice([(25, 27, 30, 245), (110, 76, 45, 245), (52, 63, 86, 245)])
    draw.rounded_rectangle((cx - w // 2, cy - h // 2, cx + w // 3, cy + h // 2), radius=max(8, int(32 * scale)), fill=color, outline=(15, 15, 15, 220), width=max(2, int(5 * scale)))
    draw.polygon(
        [(cx + w // 4, cy - h // 2), (cx + w // 2, cy - h // 5), (cx + w // 2, cy + h // 2), (cx + w // 4, cy + h // 2)],
        fill=(*color[:3], 235),
    )
    draw.line((cx - w // 3, cy + h // 2, cx + w // 2, cy + h // 2), fill=(230, 230, 220, 220), width=max(3, int(9 * scale)))


def draw_bottle(draw: ImageDraw.ImageDraw, rng: random.Random, cx: int, cy: int, scale: float) -> None:
    w = int(110 * scale)
    h = int(360 * scale)
    color = rng.choice([(180, 210, 220, 150), (70, 120, 95, 190), (90, 105, 160, 185)])
    draw.rounded_rectangle((cx - w // 2, cy - h // 2, cx + w // 2, cy + h // 2), radius=max(8, int(24 * scale)), fill=color, outline=(230, 240, 240, 120), width=max(2, int(4 * scale)))
    draw.rectangle((cx - w // 4, cy - h // 2 - int(50 * scale), cx + w // 4, cy - h // 2 + int(20 * scale)), fill=(45, 62, 74, 220))


def draw_box(draw: ImageDraw.ImageDraw, rng: random.Random, cx: int, cy: int, scale: float) -> None:
    w = int(330 * scale)
    h = int(230 * scale)
    color = rng.choice([(143, 111, 69, 245), (170, 140, 92, 245), (93, 82, 68, 245)])
    draw.rectangle((cx - w // 2, cy - h // 2, cx + w // 2, cy + h // 2), fill=color, outline=(60, 45, 28, 220), width=max(2, int(5 * scale)))
    draw.line((cx - w // 2, cy, cx + w // 2, cy), fill=(70, 48, 30, 160), width=max(2, int(5 * scale)))


def draw_common_negative(seed: int, kind: str) -> Image.Image:
    rng = random.Random(seed)
    image = outdoor_background(rng).convert("RGBA")
    layer = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer, "RGBA")

    cx = rng.randint(320, 700)
    cy = rng.randint(330, 560)
    scale = rng.uniform(0.65, 1.35)
    drawer = {
        "hat": draw_hat,
        "cloth": draw_cloth,
        "bag": draw_bag,
        "shoe": draw_shoe,
        "bottle": draw_bottle,
        "box": draw_box,
    }[kind]
    drawer(draw, rng, cx, cy, scale)

    if rng.random() < 0.55:
        for _ in range(rng.randint(3, 8)):
            x = rng.randint(-50, SIZE[0] + 50)
            y = rng.randint(0, SIZE[1])
            draw.line((x, y, x + rng.randint(-160, 160), y + rng.randint(-80, 80)), fill=(36, 72, 31, 90), width=rng.randint(4, 14))

    layer = layer.rotate(rng.uniform(-9, 9), resample=Image.Resampling.BICUBIC, center=(cx, cy))
    image.alpha_composite(layer)
    return add_camera_noise(image.convert("RGB"), rng)


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
    NEGATIVE_DIR.mkdir(parents=True, exist_ok=True)
    manifest_rows: list[dict[str, str]] = []
    kinds = ["hat", "cloth", "bag", "shoe", "bottle", "box"]

    for kind_index, kind in enumerate(kinds):
        for index in range(12):
            name = f"negative_common_object_{kind}_{index + 1:02d}.png"
            path = NEGATIVE_DIR / name
            if not path.exists():
                draw_common_negative(12000 + kind_index * 100 + index, kind).save(path)
            split = "val" if index < 3 else "train"
            manifest_rows.append({
                "path": f"raw/negative/{name}",
                "label": "not_tsuchinoko",
                "source": "procedural_common_object_negative",
                "license_status": "approved",
                "notes": f"procedural ordinary object negative: {kind}",
                "split": split,
            })

    ensure_manifest_rows(manifest_rows)
    print(f"common object negative manifest rows: {len(manifest_rows)}")


if __name__ == "__main__":
    main()
