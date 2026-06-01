#!/usr/bin/env python3
from __future__ import annotations

import random
import hashlib
from pathlib import Path

from PIL import Image, ImageEnhance, ImageFilter, ImageOps


ROOT = Path(__file__).resolve().parents[1]
PROCESSED = ROOT / "processed"
AUGMENTED = ROOT / "augmented"
LABELS = ["tsuchinoko_candidate", "not_tsuchinoko"]
TRAIN_VARIANTS_PER_IMAGE = 240
VAL_VARIANTS_PER_IMAGE = 48
OUTPUT_SIZE = (512, 384)


def iter_source_images(bucket: str, label: str):
    source_dir = PROCESSED / bucket / label
    for path in sorted(source_dir.glob("*")):
        if path.suffix.lower() in {".png", ".jpg", ".jpeg", ".webp"}:
            yield path


def random_crop(image: Image.Image, rng: random.Random) -> Image.Image:
    width, height = image.size
    scale = rng.uniform(0.68, 1.0)
    crop_w = max(64, int(width * scale))
    crop_h = max(64, int(height * scale))
    left = rng.randint(0, max(0, width - crop_w))
    top = rng.randint(0, max(0, height - crop_h))
    return image.crop((left, top, left + crop_w, top + crop_h))


def add_noise(image: Image.Image, rng: random.Random) -> Image.Image:
    strength = rng.randint(3, 16)
    noise = Image.effect_noise(image.size, strength).convert("L")
    if rng.random() < 0.5:
        noise = ImageOps.colorize(noise, black=(0, 0, 0), white=(strength, strength, strength))
    else:
        noise = Image.merge("RGB", (noise, noise, noise))
    return Image.blend(image, noise, rng.uniform(0.03, 0.12))


def augment(image: Image.Image, seed: int) -> Image.Image:
    rng = random.Random(seed)
    output = image.convert("RGB")

    output = random_crop(output, rng)
    if rng.random() < 0.55:
        output = ImageOps.mirror(output)
    if rng.random() < 0.18:
        output = output.rotate(rng.uniform(-4.0, 4.0), resample=Image.Resampling.BICUBIC, expand=False)

    output = output.resize(OUTPUT_SIZE, Image.Resampling.LANCZOS)
    output = ImageEnhance.Brightness(output).enhance(rng.uniform(0.58, 1.46))
    output = ImageEnhance.Contrast(output).enhance(rng.uniform(0.62, 1.55))
    output = ImageEnhance.Color(output).enhance(rng.uniform(0.38, 1.38))

    if rng.random() < 0.45:
        output = output.filter(ImageFilter.GaussianBlur(radius=rng.uniform(0.2, 1.35)))
    if rng.random() < 0.72:
        output = add_noise(output, rng)
    if rng.random() < 0.32:
        output = ImageOps.grayscale(output).convert("RGB")
    if rng.random() < 0.18:
        output = ImageOps.autocontrast(output, cutoff=rng.uniform(0.0, 1.8))

    return output


def clear_augmented() -> None:
    for bucket in ["train", "val"]:
        for label in LABELS:
            out_dir = AUGMENTED / bucket / label
            out_dir.mkdir(parents=True, exist_ok=True)
            for path in out_dir.glob("*.jpg"):
                path.unlink()


def main() -> None:
    clear_augmented()
    total = 0
    for bucket in ["train", "val"]:
        variants = TRAIN_VARIANTS_PER_IMAGE if bucket == "train" else VAL_VARIANTS_PER_IMAGE
        for label in LABELS:
            out_dir = AUGMENTED / bucket / label
            for source in iter_source_images(bucket, label):
                image = Image.open(source)
                for index in range(variants):
                    seed_text = f"{bucket}:{label}:{source.name}:{index}"
                    seed = int(hashlib.sha256(seed_text.encode("utf-8")).hexdigest()[:8], 16)
                    augmented = augment(image, seed)
                    out_path = out_dir / f"{source.stem}_aug_{index:03d}.jpg"
                    augmented.save(out_path, "JPEG", quality=84, optimize=True)
                    total += 1
    print(f"augmented images: {total}")


if __name__ == "__main__":
    main()
