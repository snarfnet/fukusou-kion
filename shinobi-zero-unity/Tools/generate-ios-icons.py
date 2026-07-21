import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parent.parent
SOURCE = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else ROOT / "Docs" / "Art" / "app-icon-source-1254.png"
MASTER = ROOT / "Docs" / "Art" / "app-icon-master-1024.png"
OUTPUT = ROOT / "Assets" / "Plugins" / "iOS" / "AppIcon.appiconset"
PREVIEW = ROOT / "Docs" / "Art" / "app-icon-small-preview.png"

SPECS = [
    ("Icon-20.png", 20, "20x20", "1x", "ipad"),
    ("Icon-20@2x.png", 40, "20x20", "2x", "iphone"),
    ("Icon-20@3x.png", 60, "20x20", "3x", "iphone"),
    ("Icon-29.png", 29, "29x29", "1x", "ipad"),
    ("Icon-29@2x.png", 58, "29x29", "2x", "iphone"),
    ("Icon-29@3x.png", 87, "29x29", "3x", "iphone"),
    ("Icon-40.png", 40, "40x40", "1x", "ipad"),
    ("Icon-40@2x.png", 80, "40x40", "2x", "iphone"),
    ("Icon-40@3x.png", 120, "40x40", "3x", "iphone"),
    ("Icon-60@2x.png", 120, "60x60", "2x", "iphone"),
    ("Icon-60@3x.png", 180, "60x60", "3x", "iphone"),
    ("Icon-76.png", 76, "76x76", "1x", "ipad"),
    ("Icon-76@2x.png", 152, "76x76", "2x", "ipad"),
    ("Icon-83.5@2x.png", 167, "83.5x83.5", "2x", "ipad"),
    ("Icon-Marketing.png", 1024, "1024x1024", "1x", "ios-marketing"),
]


def main():
    if not SOURCE.exists():
        raise SystemExit(f"Icon source not found: {SOURCE}")
    source = Image.open(SOURCE).convert("RGB")
    if source.width != source.height or source.width < 1024:
        raise SystemExit(f"Source must be square and at least 1024px, got {source.size}")
    master = source.resize((1024, 1024), Image.Resampling.LANCZOS)
    master.save(MASTER, format="PNG", optimize=True)

    OUTPUT.mkdir(parents=True, exist_ok=True)
    images = []
    for filename, pixels, logical_size, scale, idiom in SPECS:
        icon = master.resize((pixels, pixels), Image.Resampling.LANCZOS)
        if pixels <= 120:
            icon = icon.filter(ImageFilter.UnsharpMask(radius=.45, percent=55, threshold=3))
        icon.save(OUTPUT / filename, format="PNG", optimize=True)
        images.append({"filename": filename, "idiom": idiom, "scale": scale, "size": logical_size})

    # Reuse shared dimensions for iPad entries required by Apple's asset catalog.
    images.extend([
        {"filename": "Icon-20@2x.png", "idiom": "ipad", "scale": "2x", "size": "20x20"},
        {"filename": "Icon-29@2x.png", "idiom": "ipad", "scale": "2x", "size": "29x29"},
        {"filename": "Icon-40@2x.png", "idiom": "ipad", "scale": "2x", "size": "40x40"},
    ])
    contents = {"images": images, "info": {"author": "xcode", "version": 1}}
    (OUTPUT / "Contents.json").write_text(json.dumps(contents, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    preview = Image.new("RGB", (900, 280), (18, 20, 21))
    draw = ImageDraw.Draw(preview)
    x = 30
    for size in (180, 120, 80, 60, 40, 20):
        icon = master.resize((size, size), Image.Resampling.LANCZOS)
        y = (280 - size) // 2
        preview.paste(icon, (x, y))
        draw.text((x, 250), f"{size}px", fill=(210, 210, 205))
        x += size + 35
    preview.save(PREVIEW, optimize=True)
    print(f"Generated {len(SPECS)} iOS icons from {SOURCE.name}")


if __name__ == "__main__":
    main()
