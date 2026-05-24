#!/usr/bin/env python3
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "MarketingAssets" / "ImageGenSources"
OUT_DIR = ROOT / "MarketingAssets" / "Screenshots"
OUT_DIR.mkdir(parents=True, exist_ok=True)

SOURCES = [
    SOURCE_DIR / "morimori-glam-nail-source.png",
    SOURCE_DIR / "morimori-korean-fashion-source.png",
    SOURCE_DIR / "morimori-kawaii-source.png",
]

FONT_DIR = Path("C:/Windows/Fonts")


def font(size, bold=False):
    candidates = [
        "YuGothB.ttc" if bold else "YuGothM.ttc",
        "meiryob.ttc" if bold else "meiryo.ttc",
        "arialbd.ttf" if bold else "arial.ttf",
    ]
    for name in candidates:
        path = FONT_DIR / name
        if path.exists():
            return ImageFont.truetype(str(path), size)
    return ImageFont.load_default()


def cover(path, size):
    image = Image.open(path).convert("RGB")
    scale = max(size[0] / image.width, size[1] / image.height)
    resized = image.resize((round(image.width * scale), round(image.height * scale)), Image.Resampling.LANCZOS)
    left = (resized.width - size[0]) // 2
    top = (resized.height - size[1]) // 2
    return resized.crop((left, top, left + size[0], top + size[1]))


def round_rect_mask(size, radius):
    mask = Image.new("L", size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((0, 0, size[0] - 1, size[1] - 1), radius=radius, fill=255)
    return mask


def paste_round(base, image, xy, radius):
    mask = round_rect_mask(image.size, radius)
    base.paste(image, xy, mask)


def draw_text(draw, xy, text, fill, size, bold=False, anchor=None):
    draw.text(xy, text, fill=fill, font=font(size, bold), anchor=anchor)


def card(draw, xy, wh, radius, fill, outline=None, width=1):
    x, y = xy
    w, h = wh
    draw.rounded_rectangle((x, y, x + w, y + h), radius=radius, fill=fill, outline=outline, width=width)


def screenshot(size, source, title, subtitle, filename, ipad=False):
    w, h = size
    bg = Image.new("RGB", size, (255, 236, 246))
    bg_draw = ImageDraw.Draw(bg)
    for y in range(h):
        t = y / h
        color = (
            int(255 * (1 - t) + 250 * t),
            int(242 * (1 - t) + 218 * t),
            int(249 * (1 - t) + 239 * t),
        )
        bg_draw.line((0, y, w, y), fill=color)

    photo_w = int(w * (0.78 if not ipad else 0.58))
    photo_h = int(h * (0.62 if not ipad else 0.70))
    photo = cover(source, (photo_w, photo_h))
    photo = photo.filter(ImageFilter.UnsharpMask(radius=1.2, percent=115))
    px = int(w * (0.11 if not ipad else 0.37))
    py = int(h * (0.21 if not ipad else 0.16))
    shadow = Image.new("RGBA", (photo_w + 36, photo_h + 36), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle((18, 18, photo_w + 18, photo_h + 18), radius=54, fill=(128, 36, 82, 66))
    shadow = shadow.filter(ImageFilter.GaussianBlur(18))
    bg.paste(shadow, (px - 18, py - 18), shadow)
    paste_round(bg, photo, (px, py), 52)

    draw = ImageDraw.Draw(bg)
    top = int(h * 0.055)
    draw_text(draw, (w // 2, top), title, (122, 28, 78), int(w * 0.072 if not ipad else w * 0.046), True, "ma")
    draw_text(draw, (w // 2, top + int(w * 0.095 if not ipad else w * 0.06)), subtitle, (91, 45, 68), int(w * 0.032 if not ipad else w * 0.024), False, "ma")

    panel_w = int(w * (0.84 if not ipad else 0.34))
    panel_h = int(h * (0.18 if not ipad else 0.44))
    panel_x = int(w * (0.08 if not ipad else 0.04))
    panel_y = int(h * (0.76 if not ipad else 0.38))
    card(draw, (panel_x, panel_y), (panel_w, panel_h), 34, (255, 255, 255), (245, 153, 197), 3)

    tab_names = ["髪型", "メガネ", "ネイル", "感情"]
    x = panel_x + 28
    y = panel_y + 24
    for idx, name in enumerate(tab_names):
        fill = (226, 48, 126) if idx == 1 else (255, 228, 241)
        text_fill = (255, 255, 255) if idx == 1 else (111, 43, 77)
        card(draw, (x, y), (int(panel_w * 0.19), int(panel_h * 0.17)), 22, fill)
        draw_text(draw, (x + int(panel_w * 0.095), y + int(panel_h * 0.048)), name, text_fill, int(w * 0.025 if not ipad else w * 0.017), True, "mm")
        x += int(panel_w * 0.21)

    item_y = panel_y + int(panel_h * 0.36)
    item_size = int(panel_h * (0.46 if not ipad else 0.21))
    for i, color in enumerate([(255, 195, 220), (228, 238, 255), (255, 233, 177), (235, 212, 255), (255, 215, 232)]):
        item_x = panel_x + 28 + i * int(item_size * 1.18)
        card(draw, (item_x, item_y), (item_size, item_size), 20, color, (255, 255, 255), 3)
        cx = item_x + item_size // 2
        cy = item_y + item_size // 2
        draw.ellipse((cx - item_size * 0.20, cy - item_size * 0.12, cx + item_size * 0.20, cy + item_size * 0.12), outline=(177, 53, 115), width=5)
        draw.line((cx - item_size * 0.04, cy, cx + item_size * 0.04, cy), fill=(177, 53, 115), width=4)

    badge_text = "全ロック素材は月額680円で使い放題"
    badge_w = int(w * (0.72 if not ipad else 0.36))
    badge_h = int(w * (0.072 if not ipad else 0.04))
    badge_x = int(w * (0.14 if not ipad else 0.04))
    badge_y = int(h * (0.69 if not ipad else 0.87))
    card(draw, (badge_x, badge_y), (badge_w, badge_h), badge_h // 2, (226, 48, 126))
    draw_text(draw, (badge_x + badge_w // 2, badge_y + badge_h // 2), badge_text, (255, 255, 255), int(w * 0.026 if not ipad else w * 0.017), True, "mm")

    out = OUT_DIR / filename
    bg.save(out, quality=95)


def main():
    iphone67 = (1290, 2796)
    ipad129 = (2048, 2732)
    titles = [
        ("写真を選んで、すぐ盛れる", "メイク・髪型・メガネを重ねて自分だけの1枚に"),
        ("パックで世界観を追加", "韓国風、姫盛り、バブル、感情素材までたっぷり"),
        ("ネイルも小物もまとめて", "保存してSNSやアルバムにそのまま使える"),
    ]
    for index, (title, subtitle) in enumerate(titles, 1):
        screenshot(iphone67, SOURCES[index - 1], title, subtitle, f"iphone67_{index:02d}.png")
        screenshot(ipad129, SOURCES[index - 1], title, subtitle, f"ipad129_{index:02d}.png", ipad=True)


if __name__ == "__main__":
    main()
