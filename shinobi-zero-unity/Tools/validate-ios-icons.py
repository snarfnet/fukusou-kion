import json
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parent.parent
ICONSET = ROOT / "Assets" / "Plugins" / "iOS" / "AppIcon.appiconset"
EXPECTED = {
    "Icon-20.png": 20,
    "Icon-20@2x.png": 40,
    "Icon-20@3x.png": 60,
    "Icon-29.png": 29,
    "Icon-29@2x.png": 58,
    "Icon-29@3x.png": 87,
    "Icon-40.png": 40,
    "Icon-40@2x.png": 80,
    "Icon-40@3x.png": 120,
    "Icon-60@2x.png": 120,
    "Icon-60@3x.png": 180,
    "Icon-76.png": 76,
    "Icon-76@2x.png": 152,
    "Icon-83.5@2x.png": 167,
    "Icon-Marketing.png": 1024,
}


def main():
    contents = json.loads((ICONSET / "Contents.json").read_text(encoding="utf-8"))
    referenced = {item.get("filename") for item in contents["images"]}
    for filename, pixels in EXPECTED.items():
        path = ICONSET / filename
        if not path.exists():
            raise SystemExit(f"Missing icon: {filename}")
        with Image.open(path) as image:
            if image.size != (pixels, pixels):
                raise SystemExit(f"Wrong size for {filename}: {image.size}")
            if image.mode != "RGB":
                raise SystemExit(f"App icons must not have alpha: {filename} is {image.mode}")
        if filename not in referenced:
            raise SystemExit(f"Icon not referenced by Contents.json: {filename}")
    print(f"SHINOBI ZERO iOS icons: {len(EXPECTED)} PNG files validated, no alpha channels")


if __name__ == "__main__":
    main()
