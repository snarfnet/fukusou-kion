#!/usr/bin/env python3
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "MarketingAssets" / "Screenshots"
BACKGROUND = ROOT / "PianoPhraseLoop" / "Resources" / "Assets.xcassets" / "PianoForestBackground.imageset" / "piano-forest-background.png"

SIZES = {
    "iphone67": (1290, 2796),
    "iphone65": (1242, 2688),
    "iphone55": (1242, 2208),
    "ipad129": (2048, 2732),
}

SCREENS = [
    ("01_home", "4 bars", "C Mellow 72bpm", "Generate", "Play"),
    ("02_loop", "8 bars", "A Midnight 68bpm", "Loop On", "Bar 3"),
    ("03_midi", "2 bars", "F Bright 84bpm", "MIDI Save", "Share"),
]


def font(size, bold=False):
    candidates = [
        "/System/Library/Fonts/ヒラギノ角ゴシック W6.ttc" if bold else "/System/Library/Fonts/ヒラギノ角ゴシック W3.ttc",
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf" if bold else "/System/Library/Fonts/Supplemental/Arial.ttf",
        "/Library/Fonts/Arial Bold.ttf" if bold else "/Library/Fonts/Arial.ttf",
        "C:/Windows/Fonts/arialbd.ttf" if bold else "C:/Windows/Fonts/arial.ttf",
        "C:/Windows/Fonts/segoeuib.ttf" if bold else "C:/Windows/Fonts/segoeui.ttf",
    ]
    for path in candidates:
        if Path(path).exists():
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def cover(image, size):
    target_w, target_h = size
    scale = max(target_w / image.width, target_h / image.height)
    resized = image.resize((int(image.width * scale), int(image.height * scale)), Image.Resampling.LANCZOS)
    left = (resized.width - target_w) // 2
    top = (resized.height - target_h) // 2
    return resized.crop((left, top, left + target_w, top + target_h))


def rounded(draw, xy, radius, fill, outline=None, width=1):
    draw.rounded_rectangle(xy, radius=radius, fill=fill, outline=outline, width=width)


def centered(draw, xy, text, font_obj, fill):
    x1, y1, x2, y2 = xy
    bounds = draw.textbbox((0, 0), text, font=font_obj)
    tw = bounds[2] - bounds[0]
    th = bounds[3] - bounds[1]
    draw.text((x1 + (x2 - x1 - tw) / 2, y1 + (y2 - y1 - th) / 2 - bounds[1]), text, font=font_obj, fill=fill)


def draw_ad_banner(draw, x, y, w, h, small):
    rounded(draw, (x, y, x + w, y + h), max(6, h // 10), (244, 244, 244, 242))
    centered(draw, (x, y, x + w, y + h), "Advertisement", small, (95, 95, 95, 255))


def draw_keyboard(draw, x, y, w, h):
    white_count = 8
    key_w = w / white_count
    for index in range(white_count):
        kx = x + index * key_w
        fill = (246, 240, 225, 235) if index % 2 == 0 else (255, 249, 235, 235)
        rounded(draw, (kx, y, kx + key_w - 4, y + h), 8, fill, (255, 255, 255, 80), 1)
    for index in [0, 1, 3, 4, 5]:
        kx = x + (index + 0.65) * key_w
        rounded(draw, (kx, y, kx + key_w * 0.55, y + h * 0.58), 6, (14, 15, 20, 245))


def draw_roll(draw, x, y, w, h, progress):
    rounded(draw, (x, y, x + w, y + h), 18, (10, 14, 26, 214), (255, 255, 255, 55), 2)
    for i in range(6):
        yy = y + h * (0.12 + i * 0.15)
        draw.line((x + 28, yy, x + w - 28, yy), fill=(255, 255, 255, 46), width=2)
    notes = [
        (0.06, 0.72, 0.13), (0.21, 0.62, 0.15), (0.35, 0.55, 0.11), (0.48, 0.44, 0.18),
        (0.62, 0.58, 0.12), (0.73, 0.49, 0.16), (0.86, 0.38, 0.10),
    ]
    for start, pitch, length in notes:
        nx = x + 32 + start * (w - 86)
        ny = y + pitch * (h - 42) + 20
        nw = max(34, length * w)
        draw.rounded_rectangle((nx, ny, nx + nw, ny + 12), radius=6, fill=(255, 185, 78, 235))
    px = x + progress * w
    draw.rectangle((px, y + 18, px + 5, y + h - 18), fill=(255, 255, 255, 232))


def draw_segmented(draw, x, y, w, h, labels, active, small):
    rounded(draw, (x, y, x + w, y + h), 12, (18, 20, 28, 214), (255, 255, 255, 55), 1)
    seg_w = w / len(labels)
    for index, label in enumerate(labels):
        sx = x + index * seg_w
        if index == active:
            rounded(draw, (sx + 4, y + 4, sx + seg_w - 4, y + h - 4), 10, (255, 255, 255, 225))
            fill = (18, 18, 20, 255)
        else:
            fill = (255, 255, 255, 220)
        centered(draw, (sx, y, sx + seg_w, y + h), label, small, fill)


def make_screen(size_key, suffix, bar_text, phrase_name, primary, secondary):
    size = SIZES[size_key]
    bg = cover(Image.open(BACKGROUND).convert("RGB"), size).filter(ImageFilter.GaussianBlur(0.8))
    overlay = Image.new("RGBA", size, (0, 0, 0, 0))
    od = ImageDraw.Draw(overlay)
    od.rectangle((0, 0, size[0], size[1]), fill=(0, 0, 0, 116))
    od.rectangle((0, int(size[1] * 0.42), size[0], size[1]), fill=(0, 0, 0, 84))
    image = Image.alpha_composite(bg.convert("RGBA"), overlay)
    draw = ImageDraw.Draw(image)

    margin = int(size[0] * 0.07)
    content_w = size[0] - margin * 2
    top = int(size[1] * 0.045)

    title_font = font(int(size[0] * 0.044), bold=True)
    h1 = font(int(size[0] * 0.07), bold=True)
    h2 = font(int(size[0] * 0.04), bold=True)
    body = font(int(size[0] * 0.031))
    small = font(int(size[0] * 0.026), bold=True)

    draw_ad_banner(draw, margin, top, content_w, int(size[1] * 0.035), small)
    nav_y = top + int(size[1] * 0.055)
    centered(draw, (margin, nav_y, margin + content_w, nav_y + int(size[1] * 0.04)), "Phrase Piano", title_font, (255, 255, 255, 245))

    y = nav_y + int(size[1] * 0.075)
    draw.text((margin, y), bar_text, font=h1, fill=(255, 255, 255, 255))
    draw.text((margin, y + int(size[1] * 0.07)), "Emotional piano motifs with bass motion and resolution.", font=body, fill=(236, 239, 231, 220))

    panel_y = y + int(size[1] * 0.14)
    panel_h = int(size[1] * 0.23)
    rounded(draw, (margin, panel_y, margin + content_w, panel_y + panel_h), 18, (235, 238, 224, 205))
    px = margin + int(content_w * 0.06)
    py = panel_y + int(panel_h * 0.11)
    draw.text((px, py), phrase_name, font=h2, fill=(18, 19, 20, 255))
    draw.text((px, py + int(panel_h * 0.16)), "42 notes", font=body, fill=(70, 70, 75, 255))
    draw_segmented(draw, px, py + int(panel_h * 0.32), int(content_w * 0.88), int(panel_h * 0.16), ["Mellow", "Bright", "Midnight"], 0 if suffix == "01_home" else 2, small)
    draw.text((px, py + int(panel_h * 0.55)), "Length", font=body, fill=(35, 35, 38, 255))
    draw.line((px, py + int(panel_h * 0.72), px + int(content_w * 0.76), py + int(panel_h * 0.72)), fill=(95, 95, 100, 210), width=5)
    knob_x = px + int(content_w * (0.22 if suffix == "03_midi" else 0.54 if suffix == "01_home" else 0.82))
    draw.ellipse((knob_x - 18, py + int(panel_h * 0.72) - 18, knob_x + 18, py + int(panel_h * 0.72) + 18), fill=(255, 174, 66, 255))

    button_y = panel_y + panel_h + int(size[1] * 0.025)
    button_h = int(size[1] * 0.055)
    gap = int(size[0] * 0.028)
    button_w = (content_w - gap) // 2
    rounded(draw, (margin, button_y, margin + button_w, button_y + button_h), 16, (255, 255, 255, 238))
    centered(draw, (margin, button_y, margin + button_w, button_y + button_h), primary, h2, (15, 15, 18, 255))
    rounded(draw, (margin + button_w + gap, button_y, margin + content_w, button_y + button_h), 16, (18, 20, 28, 232), (255, 255, 255, 70), 2)
    centered(draw, (margin + button_w + gap, button_y, margin + content_w, button_y + button_h), secondary, h2, (255, 255, 255, 245))

    roll_title_y = button_y + button_h + int(size[1] * 0.045)
    draw.text((margin, roll_title_y), "Current Phrase", font=h2, fill=(255, 255, 255, 245))
    roll_y = roll_title_y + int(size[1] * 0.05)
    draw_roll(draw, margin, roll_y, content_w, int(size[1] * 0.19), 0.36 if suffix == "01_home" else 0.68)

    keyboard_y = roll_y + int(size[1] * 0.225)
    draw_keyboard(draw, margin, keyboard_y, content_w, int(size[1] * 0.09))
    credit = "Acoustic Grand Piano from FreePats, CC BY 3.0"
    centered(draw, (margin, keyboard_y + int(size[1] * 0.11), margin + content_w, keyboard_y + int(size[1] * 0.14)), credit, body, (255, 255, 255, 190))

    filename = OUT / f"{size_key}_{suffix}.png"
    image.convert("RGB").save(filename, quality=95)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for size_key in SIZES:
        for screen in SCREENS:
            make_screen(size_key, *screen)
    print(f"Generated screenshots in {OUT}")


if __name__ == "__main__":
    main()
