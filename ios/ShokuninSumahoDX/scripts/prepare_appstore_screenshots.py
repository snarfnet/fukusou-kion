#!/usr/bin/env python3
from pathlib import Path

from PIL import Image


BG = (246, 243, 237)
SOURCES = [
    ("build/screenshots/compact-iphone.png", "MarketingAssets/Screenshots/iphone67_01_angle.png", (1290, 2796)),
    ("build/screenshots/ipad.png", "MarketingAssets/Screenshots/ipad13_01_angle.png", (2048, 2732)),
]


def contain(src_path, dst_path, size):
    src = Image.open(src_path).convert("RGB")
    canvas = Image.new("RGB", size, BG)
    scale = min(size[0] / src.width, size[1] / src.height)
    resized = src.resize((round(src.width * scale), round(src.height * scale)), Image.Resampling.LANCZOS)
    offset = ((size[0] - resized.width) // 2, (size[1] - resized.height) // 2)
    canvas.paste(resized, offset)
    dst_path.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(dst_path, "PNG", optimize=True)
    print(f"{dst_path}: {canvas.width}x{canvas.height}")


def main():
    for src, dst, size in SOURCES:
        src_path = Path(src)
        if not src_path.exists():
            raise RuntimeError(f"Missing screenshot source: {src}")
        contain(src_path, Path(dst), size)


if __name__ == "__main__":
    main()
