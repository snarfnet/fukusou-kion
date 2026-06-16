#!/usr/bin/env python3
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "MarketingAssets" / "Screenshots"
BACKGROUND = ROOT / "PianoPhraseLoop" / "Resources" / "Assets.xcassets" / "PianoForestBackground.imageset" / "piano-forest-background.png"
ICON = ROOT / "PianoPhraseLoop" / "Resources" / "Assets.xcassets" / "AppIcon.appiconset" / "AppIcon_1024.png"

SIZES = {
    "iphone67": (1290, 2796),
    "iphone65": (1242, 2688),
    "iphone55": (1242, 2208),
    "ipad129": (2048, 2732),
}

SCREENS = [
    ("01_home", "Piano Phrase", "Create short piano ideas that feel emotional, memorable, and ready to develop."),
    ("02_loop", "Loop By Bars", "Listen to the phrase move through each bar, then generate the next candidate."),
    ("03_midi", "Save As MIDI", "Keep the melody you like and bring it into your DAW or notation app."),
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


def round_rect(draw, xy, radius, fill, outline=None, width=1):
    draw.rounded_rectangle(xy, radius=radius, fill=fill, outline=outline, width=width)


def text_wrap(draw, text, font_obj, max_width):
    lines = []
    words = text.split()
    current = ""
    for word in words:
        candidate = f"{current} {word}".strip()
        if draw.textbbox((0, 0), candidate, font=font_obj)[2] <= max_width:
            current = candidate
        else:
            if current:
                lines.append(current)
            current = word
    if current:
        lines.append(current)
    return lines


def draw_roll(draw, x, y, w, h, accent):
    round_rect(draw, (x, y, x + w, y + h), 26, (8, 12, 24, 204), (255, 255, 255, 38), 2)
    for i in range(6):
        yy = y + 48 + i * (h - 96) / 5
        draw.line((x + 38, yy, x + w - 38, yy), fill=(255, 255, 255, 34), width=2)
    notes = [
        (0.06, 0.65, 0.13), (0.20, 0.57, 0.18), (0.35, 0.48, 0.12), (0.47, 0.38, 0.20),
        (0.62, 0.52, 0.12), (0.72, 0.42, 0.18), (0.84, 0.34, 0.10),
    ]
    for start, pitch, length in notes:
        nx = x + 44 + start * (w - 110)
        ny = y + 48 + pitch * (h - 108)
        nw = max(42, length * w)
        draw.rounded_rectangle((nx, ny, nx + nw, ny + 14), radius=7, fill=accent)
    px = x + w * 0.58
    draw.rectangle((px, y + 32, px + 7, y + h - 32), fill=(255, 255, 255, 222))


def make_screen(size_key, suffix, title, subtitle):
    size = SIZES[size_key]
    bg = cover(Image.open(BACKGROUND).convert("RGB"), size).filter(ImageFilter.GaussianBlur(1.4))
    overlay = Image.new("RGBA", size, (0, 0, 0, 0))
    od = ImageDraw.Draw(overlay)
    od.rectangle((0, 0, size[0], size[1]), fill=(0, 0, 0, 96))
    od.rectangle((0, int(size[1] * 0.52), size[0], size[1]), fill=(0, 0, 0, 90))
    image = Image.alpha_composite(bg.convert("RGBA"), overlay)
    draw = ImageDraw.Draw(image)

    margin = int(size[0] * 0.075)
    top = int(size[1] * 0.075)
    icon_size = int(size[0] * 0.18)
    icon = Image.open(ICON).convert("RGBA").resize((icon_size, icon_size), Image.Resampling.LANCZOS)
    mask = Image.new("L", (icon_size, icon_size), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, icon_size, icon_size), radius=int(icon_size * 0.22), fill=255)
    icon.putalpha(mask)
    image.alpha_composite(icon, (margin, top))

    title_font = font(int(size[0] * 0.086), bold=True)
    body_font = font(int(size[0] * 0.039))
    small_font = font(int(size[0] * 0.031), bold=True)
    draw.text((margin, top + icon_size + int(size[1] * 0.045)), title, font=title_font, fill=(255, 248, 226, 255))

    line_y = top + icon_size + int(size[1] * 0.145)
    for line in text_wrap(draw, subtitle, body_font, size[0] - margin * 2):
        draw.text((margin, line_y), line, font=body_font, fill=(238, 244, 232, 232))
        line_y += int(size[0] * 0.052)

    panel_w = size[0] - margin * 2
    panel_h = int(size[1] * 0.27)
    panel_y = int(size[1] * 0.58)
    draw_roll(draw, margin, panel_y, panel_w, panel_h, (255, 185, 78, 230))

    button_y = panel_y + panel_h + int(size[1] * 0.035)
    button_h = int(size[1] * 0.055)
    gap = int(size[0] * 0.028)
    button_w = (panel_w - gap) // 2
    round_rect(draw, (margin, button_y, margin + button_w, button_y + button_h), 18, (255, 255, 255, 235))
    round_rect(draw, (margin + button_w + gap, button_y, margin + panel_w, button_y + button_h), 18, (8, 12, 24, 196), (255, 255, 255, 110), 2)
    draw.text((margin + int(button_w * 0.28), button_y + int(button_h * 0.30)), "Generate", font=small_font, fill=(15, 18, 22, 255))
    draw.text((margin + button_w + gap + int(button_w * 0.34), button_y + int(button_h * 0.30)), "Loop", font=small_font, fill=(255, 255, 255, 238))

    filename = OUT / f"{size_key}_{suffix}.png"
    image.convert("RGB").save(filename, quality=95)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for size_key in SIZES:
        for suffix, title, subtitle in SCREENS:
            make_screen(size_key, suffix, title, subtitle)
    print(f"Generated screenshots in {OUT}")


if __name__ == "__main__":
    main()
