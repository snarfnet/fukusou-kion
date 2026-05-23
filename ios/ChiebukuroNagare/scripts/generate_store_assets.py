#!/usr/bin/env python3
import json
import math
import os
from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[1]
PROJECT_ROOT = ROOT.parents[1]
SOURCE_IMAGE = Path(os.environ.get(
    "CHIEBUKURO_SOURCE_IMAGE",
    r"C:\Users\Windows\Downloads\ChatGPT Image 2026年5月23日 20_45_08.png",
))
ICON_PATH = ROOT / "ChiebukuroNagare" / "Assets.xcassets" / "AppIcon.appiconset" / "Icon-1024.png"
BACKGROUND_PATH = ROOT / "ChiebukuroNagare" / "Assets.xcassets" / "ChiebukuroBackground.imageset" / "chiebukuro-bg.png"
SCREENSHOT_ROOT = ROOT / "MarketingAssets" / "Screenshots"
DATA_PATH = ROOT / "ChiebukuroNagare" / "Resources" / "wisdom_data.json"

FONT_REGULAR = Path(r"C:\Windows\Fonts\NotoSansJP-VF.ttf")
FONT_SERIF = Path(r"C:\Windows\Fonts\yumin.ttf")
FONT_SERIF_BOLD = Path(r"C:\Windows\Fonts\yumindb.ttf")

SIZES = {
    "iphone67": (1290, 2796),
    "iphone65": (1242, 2688),
    "iphone55": (1242, 2208),
    "ipad129": (2048, 2732),
}

SCENES = [
    {
        "title": "煙草屋のおばぁちゃん",
        "subtitle": "昔ながらの知恵袋が、白い文字でゆっくり流れます。",
        "tip_index": 18,
    },
    {
        "title": "10000件の暮らしの知恵",
        "subtitle": "料理、掃除、節約、健康、ことわざ。毎日ふと読みたくなる言葉を集めました。",
        "tip_index": 802,
    },
    {
        "title": "ひとつ終わると、一呼吸",
        "subtitle": "急かさず、詰めこまず。読んだあとに少しだけ余白が残ります。",
        "tip_index": 2094,
    },
    {
        "title": "日本語と英語に対応",
        "subtitle": "端末の言語に合わせて、英語版の知恵袋も表示します。",
        "tip_index": 7431,
    },
]


def font(path, size):
    return ImageFont.truetype(str(path), size=size)


def cover(image, size, focus_y=0.48):
    target_w, target_h = size
    scale = max(target_w / image.width, target_h / image.height)
    resized = image.resize((math.ceil(image.width * scale), math.ceil(image.height * scale)), Image.LANCZOS)
    left = max(0, (resized.width - target_w) // 2)
    top = int(max(0, min(resized.height - target_h, resized.height * focus_y - target_h / 2)))
    return resized.crop((left, top, left + target_w, top + target_h))


def fit_text(draw, text, font_obj, max_width):
    lines = []
    current = ""
    for char in text:
        trial = current + char
        if draw.textlength(trial, font=font_obj) <= max_width or not current:
            current = trial
        else:
            lines.append(current)
            current = char
    if current:
        lines.append(current)
    return lines


def draw_multiline(draw, xy, text, font_obj, fill, max_width, line_gap, shadow=True):
    x, y = xy
    for line in fit_text(draw, text, font_obj, max_width):
        if shadow:
            draw.text((x + 3, y + 4), line, font=font_obj, fill=(0, 0, 0, 190))
        draw.text((x, y), line, font=font_obj, fill=fill)
        bbox = draw.textbbox((x, y), line, font=font_obj)
        y += bbox[3] - bbox[1] + line_gap
    return y


def load_tips():
    items = json.loads(DATA_PATH.read_text(encoding="utf-8"))
    tips = []
    for item in items:
        title = item.get("title") or ""
        content = item.get("content") or item.get("text") or ""
        tips.append(f"{title}。{content}".replace("。。", "。"))
    return tips


def draw_controls(draw, size, y, scale):
    w, _ = size
    center_x = w // 2
    button = int(92 * scale)
    gap = int(32 * scale)
    labels = ["‹", "Ⅱ", "›", "おまかせ"]
    widths = [button, button, button, int(210 * scale)]
    total = sum(widths) + gap * (len(widths) - 1)
    x = center_x - total // 2
    for label, width in zip(labels, widths):
        rect = (x, y, x + width, y + button)
        draw.rounded_rectangle(rect, radius=int(28 * scale), fill=(30, 24, 20, 170), outline=(255, 255, 255, 96), width=max(1, int(2 * scale)))
        f = font(FONT_REGULAR, int((42 if label != "おまかせ" else 28) * scale))
        bbox = draw.textbbox((0, 0), label, font=f)
        draw.text((x + (width - (bbox[2] - bbox[0])) / 2, y + (button - (bbox[3] - bbox[1])) / 2 - int(4 * scale)), label, font=f, fill=(255, 255, 255, 235))
        x += width + gap


def make_screenshot(source, tips, key, size):
    w, h = size
    scale = w / 1290
    out_dir = SCREENSHOT_ROOT / key
    out_dir.mkdir(parents=True, exist_ok=True)

    for i, scene in enumerate(SCENES, start=1):
        base = cover(source, size)
        base = ImageEnhance.Color(base).enhance(0.92)
        base = ImageEnhance.Contrast(base).enhance(1.08)

        shade = Image.new("RGBA", size, (0, 0, 0, 0))
        sd = ImageDraw.Draw(shade)
        sd.rectangle((0, 0, w, h), fill=(0, 0, 0, 78))
        sd.rectangle((0, int(h * 0.48), w, h), fill=(0, 0, 0, 108))
        sd.rectangle((0, 0, int(w * 0.25), h), fill=(0, 0, 0, 72))
        sd.rectangle((int(w * 0.75), 0, w, h), fill=(0, 0, 0, 70))
        base = Image.alpha_composite(base.convert("RGBA"), shade)

        vignette = Image.new("L", size, 0)
        vd = ImageDraw.Draw(vignette)
        margin = int(min(w, h) * 0.07)
        vd.rounded_rectangle((margin, margin, w - margin, h - margin), radius=int(80 * scale), fill=220)
        vignette = vignette.filter(ImageFilter.GaussianBlur(int(90 * scale)))
        dark = Image.new("RGBA", size, (0, 0, 0, 92))
        base = Image.composite(base, Image.alpha_composite(base, dark), vignette)

        draw = ImageDraw.Draw(base)
        pad = int(96 * scale)
        safe_top = int(120 * scale)
        mark_font = font(FONT_SERIF, int(34 * scale))
        title_font = font(FONT_SERIF_BOLD, int((66 if w < 1600 else 76) * scale))
        sub_font = font(FONT_REGULAR, int(31 * scale))
        cat_font = font(FONT_REGULAR, int(25 * scale))
        body_font = font(FONT_SERIF_BOLD, int((44 if w < 1600 else 50) * scale))

        draw.text((pad, safe_top), "煙草屋の", font=mark_font, fill=(255, 255, 255, 190))
        y = safe_top + int(56 * scale)
        y = draw_multiline(draw, (pad, y), scene["title"], title_font, (255, 255, 255, 255), w - pad * 2, int(14 * scale))
        y += int(26 * scale)
        y = draw_multiline(draw, (pad, y), scene["subtitle"], sub_font, (255, 255, 255, 225), w - pad * 2, int(8 * scale))

        panel_top = int(h * (0.54 if h > 2400 else 0.48))
        max_width = w - pad * 2
        draw.text((pad, panel_top), "暮らし / 知恵袋", font=cat_font, fill=(255, 255, 255, 170))
        tip = tips[scene["tip_index"] % len(tips)]
        tip = tip[:86] + "…" if len(tip) > 86 else tip
        draw_multiline(draw, (pad, panel_top + int(58 * scale)), tip, body_font, (255, 255, 255, 255), max_width, int(15 * scale))

        cursor_x = pad + int(max_width * 0.86)
        cursor_y = min(h - int(360 * scale), panel_top + int(260 * scale))
        draw.rectangle((cursor_x, cursor_y, cursor_x + max(2, int(4 * scale)), cursor_y + int(58 * scale)), fill=(255, 255, 255, 230))
        draw_controls(draw, size, h - int(210 * scale), scale)

        filename = f"{key}_{i:02d}.png"
        base.convert("RGB").save(out_dir / filename, "PNG", optimize=True)


def main():
    if not SOURCE_IMAGE.exists():
        raise FileNotFoundError(SOURCE_IMAGE)

    source = Image.open(SOURCE_IMAGE).convert("RGB")
    ICON_PATH.parent.mkdir(parents=True, exist_ok=True)
    icon = cover(source, (1024, 1024), focus_y=0.50)
    icon.save(ICON_PATH, "PNG", optimize=True)

    BACKGROUND_PATH.parent.mkdir(parents=True, exist_ok=True)
    source.save(BACKGROUND_PATH, "PNG", optimize=True)

    tips = load_tips()
    for key, size in SIZES.items():
        make_screenshot(source, tips, key, size)

    print(f"Icon: {ICON_PATH}")
    print(f"Background: {BACKGROUND_PATH}")
    print(f"Screenshots: {SCREENSHOT_ROOT}")


if __name__ == "__main__":
    main()
