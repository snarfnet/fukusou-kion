from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
WORKSPACE = ROOT.parents[1]
SRC = WORKSPACE / "output" / "playwright" / "cleaning-kokoroe-ios-layout.png"
OUT = ROOT / "MarketingAssets" / "Screenshots"

SIZES = {
    "iphone67_01.png": (1290, 2796),
    "iphone65_01.png": (1242, 2688),
    "iphone55_01.png": (1242, 2208),
}


def font(size):
    candidates = [
        "C:/Windows/Fonts/YuGothB.ttc",
        "C:/Windows/Fonts/meiryob.ttc",
        "C:/Windows/Fonts/msgothic.ttc",
    ]
    for candidate in candidates:
        if Path(candidate).exists():
            return ImageFont.truetype(candidate, size)
    return ImageFont.load_default()


def rounded_paste(base, image, box, radius):
    x, y, w, h = box
    image = image.resize((w, h), Image.LANCZOS)
    mask = Image.new("L", (w, h), 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((0, 0, w, h), radius=radius, fill=255)
    shadow = mask.filter(ImageFilter.GaussianBlur(radius // 3))
    shadow_layer = Image.new("RGBA", base.size, (0, 0, 0, 0))
    shadow_layer.paste((0, 0, 0, 55), (x, y + radius // 3), shadow)
    base.alpha_composite(shadow_layer)
    base.paste(image, (x, y), mask)


def make_canvas(size, title, subtitle):
    w, h = size
    canvas = Image.new("RGBA", size, (246, 244, 235, 255))
    draw = ImageDraw.Draw(canvas)
    for y in range(h):
        tone = int(248 - y / h * 18)
        draw.line((0, y, w, y), fill=(tone, min(255, tone + 5), tone - 9, 255))
    draw.text((80, 70), title, fill=(33, 48, 45), font=font(78))
    draw.text((84, 170), subtitle, fill=(78, 94, 88), font=font(38))
    return canvas


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    src = Image.open(SRC).convert("RGBA")
    for name, size in SIZES.items():
        canvas = make_canvas(size, "清掃の心得", "豆知識、風水、ホウキ針タイマーをひとつに。")
        w, h = size
        phone_w = int(w * 0.68)
        phone_h = int(phone_w * src.height / src.width)
        max_h = h - 310
        if phone_h > max_h:
            phone_h = max_h
            phone_w = int(phone_h * src.width / src.height)
        rounded_paste(canvas, src, ((w - phone_w) // 2, 250, phone_w, phone_h), 56)
        canvas.convert("RGB").save(OUT / name, quality=95)
    print(f"Wrote screenshots to {OUT}")


if __name__ == "__main__":
    main()
