#!/usr/bin/env python3
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "MarketingAssets" / "Screenshots"
OUT_DIR.mkdir(parents=True, exist_ok=True)

ICON_SOURCE = ROOT / "MarketingAssets" / "AppIcon-1024.png"
SOURCE_DIR = ROOT / "MarketingAssets" / "ImageGenSources"
OVERLAY_DIR = ROOT / "MorimoriPhotoMaker" / "Resources" / "Overlays"

FONT_CANDIDATES = {
    "regular": [
        Path("C:/Windows/Fonts/YuGothM.ttc"),
        Path("C:/Windows/Fonts/meiryo.ttc"),
        Path("/System/Library/Fonts/ヒラギノ角ゴシック W3.ttc"),
        Path("/System/Library/Fonts/Supplemental/Arial Unicode.ttf"),
        Path("/Library/Fonts/Arial Unicode.ttf"),
    ],
    "bold": [
        Path("C:/Windows/Fonts/YuGothB.ttc"),
        Path("C:/Windows/Fonts/meiryob.ttc"),
        Path("/System/Library/Fonts/ヒラギノ角ゴシック W6.ttc"),
        Path("/System/Library/Fonts/Supplemental/Arial Bold.ttf"),
        Path("/Library/Fonts/Arial Unicode.ttf"),
    ],
}


def font(size, bold=False):
    for path in FONT_CANDIDATES["bold" if bold else "regular"]:
        if path.exists():
            return ImageFont.truetype(str(path), size)
    return ImageFont.load_default()


def cover(path, size, focus_y=0.5):
    image = Image.open(path).convert("RGB")
    return cover_image(image, size, focus_y)


def cover_image(image, size, focus_y=0.5):
    scale = max(size[0] / image.width, size[1] / image.height)
    resized = image.resize((round(image.width * scale), round(image.height * scale)), Image.Resampling.LANCZOS)
    left = (resized.width - size[0]) // 2
    top = int((resized.height - size[1]) * focus_y)
    top = max(0, min(top, resized.height - size[1]))
    return resized.crop((left, top, left + size[0], top + size[1]))


def round_mask(size, radius):
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, size[0] - 1, size[1] - 1), radius=radius, fill=255)
    return mask


def paste_round(base, image, box, radius):
    image = image.resize((box[2] - box[0], box[3] - box[1]), Image.Resampling.LANCZOS)
    base.paste(image, box[:2], round_mask(image.size, radius))


def text(draw, xy, value, fill, size, bold=False, anchor="la"):
    draw.text(xy, value, fill=fill, font=font(size, bold), anchor=anchor)


def centered(draw, xy, value, fill, size, bold=False):
    text(draw, xy, value, fill, size, bold, "mm")


def rounded(draw, box, radius, fill, outline=None, width=1):
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)


def shadowed_panel(base, box, radius, fill=(255, 255, 255), outline=(246, 136, 195)):
    x1, y1, x2, y2 = box
    shadow = Image.new("RGBA", (x2 - x1 + 60, y2 - y1 + 60), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rounded_rectangle((30, 30, x2 - x1 + 30, y2 - y1 + 30), radius=radius, fill=(132, 42, 99, 60))
    shadow = shadow.filter(ImageFilter.GaussianBlur(18))
    base.paste(shadow, (x1 - 30, y1 - 25), shadow)
    draw = ImageDraw.Draw(base)
    rounded(draw, box, radius, fill, outline, 3)


def load_overlay(name, size):
    image = Image.open(OVERLAY_DIR / name).convert("RGBA")
    image.thumbnail((size, size), Image.Resampling.LANCZOS)
    return image


def draw_app_frame(base, box, variant):
    x1, y1, x2, y2 = box
    w, h = x2 - x1, y2 - y1
    draw = ImageDraw.Draw(base)
    shadowed_panel(base, box, max(34, w // 24), fill=(255, 246, 251), outline=(247, 150, 204))

    header_h = int(h * 0.075)
    tabs_h = int(h * 0.08)
    tray_h = int(h * 0.19)
    pad = int(w * 0.035)
    stage = (x1 + pad, y1 + header_h + pad, x2 - pad, y2 - tabs_h - tray_h - pad)

    buttons = ["Photo", "Shop", "Auto", "Share", "Save"]
    bx = x1 + pad
    by = y1 + int(header_h * 0.2)
    for label in buttons:
        bw = int(w * (0.15 if label != "Auto" else 0.22))
        rounded(draw, (bx, by, bx + bw, by + int(header_h * 0.62)), 18, (255, 105, 174))
        centered(draw, (bx + bw // 2, by + int(header_h * 0.31)), label, (255, 255, 255), max(18, int(w * 0.024)), True)
        bx += bw + int(w * 0.018)

    stage_bg = (255, 232, 245) if variant != "shop" else (250, 246, 255)
    rounded(draw, stage, 28, stage_bg, (244, 164, 207), 3)
    if variant == "shop":
        draw_shop_content(draw, stage)
    else:
        if ICON_SOURCE.exists():
            icon = Image.open(ICON_SOURCE).convert("RGB")
            icon = icon.crop((0, 0, icon.width, int(icon.height * 0.52)))
            girl = cover_image(icon, (stage[2] - stage[0], stage[3] - stage[1]), focus_y=0.04)
        else:
            girl = cover(SOURCE_DIR / "morimori-kawaii-source.png", (stage[2] - stage[0], stage[3] - stage[1]), focus_y=0.18)
        paste_round(base, girl, stage, 28)
        add_sample_deco(base, stage, variant)

    tab_y = y2 - tabs_h - tray_h
    tabs = ["Hair", "Glasses", "Nails", "Mood", "Items"]
    tx = x1 + pad
    for index, label in enumerate(tabs):
        tw = int((w - pad * 2) / len(tabs) - 7)
        active = index == (1 if variant == "edit" else 2 if variant == "shop" else 3)
        fill = (230, 45, 135) if active else (255, 225, 241)
        fg = (255, 255, 255) if active else (124, 42, 88)
        rounded(draw, (tx, tab_y + 8, tx + tw, tab_y + tabs_h - 10), 18, fill)
        centered(draw, (tx + tw // 2, tab_y + tabs_h // 2), label, fg, max(18, int(w * 0.024)), True)
        tx += tw + 8

    draw_asset_tray(base, (x1 + pad, y2 - tray_h + 8, x2 - pad, y2 - 14), variant)


def add_sample_deco(base, stage, variant):
    sx1, sy1, sx2, sy2 = stage
    sw, sh = sx2 - sx1, sy2 - sy1
    draw = ImageDraw.Draw(base)
    for px, py, r, color in [(0.18, 0.18, 7, (255, 255, 255)), (0.82, 0.18, 9, (255, 255, 255)), (0.78, 0.56, 6, (255, 255, 255))]:
        cx, cy = sx1 + int(sw * px), sy1 + int(sh * py)
        draw.line((cx - r * 2, cy, cx + r * 2, cy), fill=color, width=max(2, r // 2))
        draw.line((cx, cy - r * 2, cx, cy + r * 2), fill=color, width=max(2, r // 2))
    overlays = [
        ("glasses-heart-rhinestone.png", 0.50, 0.67, 0.34),
        ("hime_part_heart_charm.png", 0.78, 0.22, 0.18),
        ("emotion_tears_blue.png", 0.30, 0.62, 0.16),
    ]
    for name, px, py, ratio in overlays:
        path = OVERLAY_DIR / name
        if not path.exists():
            continue
        overlay = load_overlay(name, int(sw * ratio))
        ox = sx1 + int(sw * px) - overlay.width // 2
        oy = sy1 + int(sh * py) - overlay.height // 2
        base.paste(overlay, (ox, oy), overlay)


def draw_shop_content(draw, stage):
    sx1, sy1, sx2, sy2 = stage
    sw, sh = sx2 - sx1, sy2 - sy1
    title_size = max(24, int(sw * 0.05))
    text(draw, (sx1 + 34, sy1 + 38), "Decoration Shop", (112, 38, 92), title_size, True)
    rows = [
        ("All Access", "Unlock every locked decoration pack", "Subscribe"),
        ("Princess Pack", "Tiaras, ribbons, and cute hair items", "View"),
        ("Cabaret Nail Pack", "Glossy nail decorations", "View"),
        ("Korean Hair Pack", "Trendy hair decorations", "View"),
    ]
    y = sy1 + int(sh * 0.18)
    for index, (name, detail, action_label) in enumerate(rows):
        fill = (255, 239, 249) if index else (255, 221, 241)
        rounded(draw, (sx1 + 28, y, sx2 - 28, y + int(sh * 0.16)), 22, fill, (244, 150, 204), 2)
        text(draw, (sx1 + 54, y + int(sh * 0.055)), name, (104, 36, 88), max(20, int(sw * 0.038)), True)
        text(draw, (sx1 + 54, y + int(sh * 0.105)), detail, (126, 75, 105), max(16, int(sw * 0.026)))
        rounded(draw, (sx2 - 190, y + 26, sx2 - 48, y + int(sh * 0.16) - 26), 18, (230, 45, 135))
        centered(draw, (sx2 - 119, y + int(sh * 0.08)), action_label, (255, 255, 255), max(16, int(sw * 0.026)), True)
        y += int(sh * 0.18)


def draw_asset_tray(base, box, variant):
    x1, y1, x2, y2 = box
    draw = ImageDraw.Draw(base)
    rounded(draw, box, 24, (255, 255, 255), (246, 153, 205), 2)
    assets = [
        ("glasses-heart-rhinestone.png", False),
        ("hime_glasses_heart_jewel.png", True),
        ("cabaret_nail_01.png", variant != "shop"),
        ("emotion_tears_blue.png", True),
        ("korean_fashion_hat_bucket.png", True),
    ]
    gap = 16
    size = min(y2 - y1 - 34, (x2 - x1 - gap * 6) // 5)
    ax = x1 + gap
    ay = y1 + (y2 - y1 - size) // 2
    for name, locked in assets:
        rounded(draw, (ax, ay, ax + size, ay + size), 18, (255, 232, 245), (255, 255, 255), 3)
        path = OVERLAY_DIR / name
        if path.exists():
            image = load_overlay(name, int(size * 0.78))
            base.paste(image, (ax + (size - image.width) // 2, ay + (size - image.height) // 2), image)
        if locked:
            rounded(draw, (ax + size - 42, ay + 8, ax + size - 8, ay + 42), 13, (84, 35, 82))
            centered(draw, (ax + size - 25, ay + 25), "Lock", (255, 255, 255), max(12, size // 8), True)
        ax += size + gap


def make_background(size):
    w, h = size
    bg = Image.new("RGB", size, (255, 239, 249))
    draw = ImageDraw.Draw(bg)
    for y in range(h):
        t = y / max(1, h - 1)
        color = (
            int(255 - 10 * t),
            int(242 - 26 * t),
            int(251 + 8 * t),
        )
        draw.line((0, y, w, y), fill=color)
    return bg


def screenshot(size, title, subtitle, filename, variant, ipad=False):
    w, h = size
    bg = make_background(size)
    draw = ImageDraw.Draw(bg)
    title_size = int(w * (0.072 if not ipad else 0.046))
    subtitle_size = int(w * (0.034 if not ipad else 0.024))
    top = int(h * 0.055)
    centered(draw, (w // 2, top), title, (124, 30, 92), title_size, True)
    centered(draw, (w // 2, top + int(title_size * 1.08)), subtitle, (104, 53, 91), subtitle_size)

    if ipad:
        app_box = (int(w * 0.19), int(h * 0.19), int(w * 0.81), int(h * 0.94))
    else:
        app_box = (int(w * 0.08), int(h * 0.18), int(w * 0.92), int(h * 0.95))
    draw_app_frame(bg, app_box, variant)
    bg.save(OUT_DIR / filename, quality=95)


def main():
    iphone67 = (1290, 2796)
    ipad129 = (2048, 2732)
    shots = [
        ("Pick a photo and decorate", "Layer hair, glasses, nails, and stickers", "edit"),
        ("Add themed packs", "Choose from princess, Korean style, nails, and more", "shop"),
        ("Unlock more decorations", "Use single packs or All Access from the shop", "all"),
    ]
    for index, (title, subtitle, variant) in enumerate(shots, 1):
        screenshot(iphone67, title, subtitle, f"iphone67_{index:02d}.png", variant)
        screenshot(ipad129, title, subtitle, f"ipad129_{index:02d}.png", variant, ipad=True)


if __name__ == "__main__":
    main()
