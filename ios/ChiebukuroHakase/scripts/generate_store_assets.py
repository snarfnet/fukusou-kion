from __future__ import annotations

import json
import textwrap
from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageFont


ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "ChiebukuroHakase"
OUT = ROOT / "MarketingAssets" / "Screenshots"
BACKGROUND = APP / "Assets.xcassets" / "ChiebukuroBackground.imageset" / "chiebukuro-bg.png"
DATA = APP / "wisdom_data.json"

SIZES = {
    "iphone67": (1290, 2796),
    "iphone65": (1242, 2688),
    "iphone55": (1242, 2208),
    "ipad129": (2048, 2732),
}

MESSAGES = [
    ("50,000件の知恵袋", "昔ながらの暮らしの知恵が、白い文字でゆっくり流れます。"),
    ("博士のおばぁちゃん", "台所、掃除、節約、人づきあい。毎日ひとつずつ読めます。"),
    ("英語版データも収録", "日本語と英語、それぞれ50,000件。静かな読みものアプリです。"),
]


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    candidates = [
        Path("C:/Windows/Fonts/meiryob.ttc" if bold else "C:/Windows/Fonts/meiryo.ttc"),
        Path("C:/Windows/Fonts/YuGothB.ttc" if bold else "C:/Windows/Fonts/YuGothR.ttc"),
        Path("C:/Windows/Fonts/arial.ttf"),
    ]
    for path in candidates:
        if path.exists():
            return ImageFont.truetype(str(path), size)
    return ImageFont.load_default()


def cover(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    scale = max(size[0] / image.width, size[1] / image.height)
    resized = image.resize((int(image.width * scale), int(image.height * scale)), Image.Resampling.LANCZOS)
    left = (resized.width - size[0]) // 2
    top = (resized.height - size[1]) // 2
    return resized.crop((left, top, left + size[0], top + size[1]))


def draw_wrapped(draw: ImageDraw.ImageDraw, text: str, xy: tuple[int, int], width: int, fill, font_obj, line_gap: int) -> int:
    x, y = xy
    for paragraph in text.splitlines():
        if " " in paragraph:
            words = textwrap.wrap(paragraph, 16)
            lines = []
            current = ""
            for word in words:
                candidate = f"{current} {word}".strip()
                if draw.textlength(candidate, font=font_obj) <= width:
                    current = candidate
                else:
                    if current:
                        lines.append(current)
                    current = word
            if current:
                lines.append(current)
        else:
            lines = []
            current = ""
            for char in paragraph:
                candidate = current + char
                if draw.textlength(candidate, font=font_obj) <= width:
                    current = candidate
                else:
                    if current:
                        lines.append(current)
                    current = char
            if current:
                lines.append(current)
        for line in lines:
            draw.text((x, y), line, fill=fill, font=font_obj)
            y += font_obj.size + line_gap
    return y


def make_screen(size_name: str, size: tuple[int, int], index: int, wisdom: dict[str, str]) -> Image.Image:
    bg = cover(Image.open(BACKGROUND).convert("RGB"), size)
    bg = ImageEnhance.Brightness(bg).enhance(0.78)
    image = bg.convert("RGBA")
    draw = ImageDraw.Draw(image)

    w, h = size
    margin = int(w * 0.075)
    top = int(h * 0.12)
    title_size = max(58, int(w * 0.068))
    body_size = max(34, int(w * 0.039))
    wisdom_size = max(40, int(w * 0.043))

    overlay = Image.new("RGBA", size, (0, 0, 0, 0))
    odraw = ImageDraw.Draw(overlay)
    odraw.rectangle((0, 0, w, int(h * 0.34)), fill=(0, 0, 0, 96))
    odraw.rectangle((0, int(h * 0.56), w, h), fill=(0, 0, 0, 122))
    image = Image.alpha_composite(image, overlay)
    draw = ImageDraw.Draw(image)

    label, copy = MESSAGES[index]
    draw.text((margin, top), "煙草屋のおばぁちゃん博士", fill=(255, 255, 255, 232), font=font(max(28, int(w * 0.028))))
    y = top + int(title_size * 0.95)
    draw_wrapped(draw, label, (margin, y), w - margin * 2, (255, 255, 255, 255), font(title_size, True), 14)

    y = int(h * 0.64)
    y = draw_wrapped(draw, copy, (margin, y), w - margin * 2, (255, 255, 255, 235), font(body_size), 16)
    y += int(body_size * 1.1)
    draw.text((margin, y), f"{wisdom['category']} / {wisdom['title']}", fill=(255, 255, 255, 190), font=font(max(26, int(w * 0.028))))
    y += int(body_size * 1.4)
    draw_wrapped(draw, wisdom["content"], (margin, y), w - margin * 2, (255, 255, 255, 255), font(wisdom_size, True), 18)

    return image.convert("RGB")


def main() -> None:
    wisdoms = json.loads(DATA.read_text(encoding="utf-8"))
    for size_name, size in SIZES.items():
        folder = OUT / size_name
        folder.mkdir(parents=True, exist_ok=True)
        for index in range(3):
            image = make_screen(size_name, size, index, wisdoms[index * 137])
            image.save(folder / f"screenshot_{index + 1}.png", optimize=True)
            print(folder / f"screenshot_{index + 1}.png")


if __name__ == "__main__":
    main()
