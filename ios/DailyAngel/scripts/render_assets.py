from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
ICON_DIR = ROOT / "DailyAngel" / "Assets.xcassets" / "AppIcon.appiconset"
SHOT_DIR = ROOT / "MarketingAssets" / "Screenshots"


def font(size, bold=False):
    candidates = [
        "C:/Windows/Fonts/YuGothB.ttc" if bold else "C:/Windows/Fonts/YuGothR.ttc",
        "C:/Windows/Fonts/meiryob.ttc" if bold else "C:/Windows/Fonts/meiryo.ttc",
        "C:/Windows/Fonts/arialbd.ttf" if bold else "C:/Windows/Fonts/arial.ttf",
    ]
    for path in candidates:
        if Path(path).exists():
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def multiline(draw, xy, text, fill, fnt, width, line_gap=10):
    x, y = xy
    line = ""
    for char in text:
        trial = line + char
        if draw.textbbox((0, 0), trial, font=fnt)[2] <= width:
            line = trial
        else:
            draw.text((x, y), line, fill=fill, font=fnt)
            y += fnt.size + line_gap
            line = char
    if line:
        draw.text((x, y), line, fill=fill, font=fnt)
        y += fnt.size + line_gap
    return y


def gradient(size, top=(248, 239, 218), bottom=(219, 238, 229)):
    w, h = size
    small_w = min(320, w)
    small_h = min(520, h)
    img = Image.new("RGB", (small_w, small_h))
    px = img.load()
    for y in range(small_h):
        t = y / max(1, small_h - 1)
        for x in range(small_w):
            side = x / max(1, small_w - 1)
            r = int(top[0] * (1 - t) + bottom[0] * t + 8 * side)
            g = int(top[1] * (1 - t) + bottom[1] * t)
            b = int(top[2] * (1 - t) + bottom[2] * t - 8 * side)
            px[x, y] = (max(0, min(255, r)), max(0, min(255, g)), max(0, min(255, b)))
    return img.resize(size, Image.Resampling.BICUBIC)


def render_icon():
    size = 1024
    img = gradient((size, size), (246, 232, 198), (210, 232, 224)).convert("RGBA")
    glow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    g = ImageDraw.Draw(glow)
    g.ellipse((196, 120, 828, 752), fill=(196, 151, 55, 58))
    glow = glow.filter(ImageFilter.GaussianBlur(28))
    img.alpha_composite(glow)
    d = ImageDraw.Draw(img)
    ink = (20, 31, 46, 255)
    gold = (183, 137, 44, 255)
    teal = (8, 94, 99, 255)

    d.rounded_rectangle((212, 250, 812, 778), radius=72, fill=(255, 252, 242, 220), outline=(27, 35, 50, 34), width=8)
    d.line((286, 386, 512, 540, 738, 386), fill=gold, width=18)
    d.line((286, 642, 448, 504), fill=teal, width=14)
    d.line((738, 642, 576, 504), fill=teal, width=14)
    d.ellipse((470, 290, 554, 374), fill=gold)
    d.text((512, 670), "A", anchor="mm", font=font(176, True), fill=ink)
    img.save(ICON_DIR / "Icon-1024.png")


def phone_frame(draw, x, y, w, h):
    draw.rounded_rectangle((x, y, x + w, y + h), radius=52, fill=(20, 31, 46), outline=(255, 255, 255, 90), width=3)
    draw.rounded_rectangle((x + 18, y + 22, x + w - 18, y + h - 22), radius=36, fill=(245, 238, 220))


def screen_content(base, x, y, w, h, variant):
    d = ImageDraw.Draw(base)
    pad = 42
    d.text((x + pad, y + 58), "天使の手紙", font=font(34, True), fill=(20, 31, 46))
    d.rounded_rectangle((x + pad, y + 122, x + w - pad, y + 176), radius=26, fill=(255, 255, 255, 178))
    d.text((x + pad + 20, y + 134), "LUMIEL ZIRDO CA ORO", font=font(24, True), fill=(18, 55, 96))
    d.rounded_rectangle((x + pad, y + 206, x + w - pad, y + 540), radius=22, fill=(255, 252, 242), outline=(20, 31, 46, 26), width=2)
    if variant == 0:
        title = "今日届いた言葉"
        body = "焦らなくていい。今日の扉は、静かに開きます。"
        action = "朝の光を一分だけ見る。"
    elif variant == 1:
        title = "365日の手紙"
        body = "光、水、風、火、月、夢。テーマごとに言葉を探せます。"
        action = "心に残った言葉を保存。"
    elif variant == 2:
        title = "日本語と英語"
        body = "天使語風の言葉を、日本語と英語の自然なメッセージで読めます。"
        action = "海外向けにもそのまま使える。"
    else:
        title = "毎朝の通知"
        body = "端末内の通知で、朝に短いメッセージを受け取れます。"
        action = "通信なし。記録は端末内。"
    d.text((x + pad + 26, y + 236), title, font=font(30, True), fill=(20, 31, 46))
    multiline(d, (x + pad + 26, y + 294), body, (20, 31, 46), font(25), w - pad * 2 - 52, 12)
    d.rounded_rectangle((x + pad + 26, y + 438, x + w - pad - 26, y + 506), radius=18, fill=(222, 239, 232))
    d.text((x + pad + 48, y + 456), action, font=font(22, True), fill=(6, 83, 88))


def render_shot(path, size, variant):
    w, h = size
    img = gradient(size, (248, 239, 218), (214, 235, 226)).convert("RGBA")
    d = ImageDraw.Draw(img)
    d.ellipse((w - 340, -170, w + 160, 330), outline=(184, 137, 44, 76), width=44)
    d.ellipse((-170, h - 250, 260, h + 170), fill=(12, 95, 102, 30))
    title = ["毎朝、天使から届く", "365日の言葉を収録", "天使語・日本語・英語", "通知も保存も端末内"][variant]
    subtitle = ["短い言葉で一日を整える", "光、夢、月、沈黙などのテーマ", "世界観を壊さず読める", "初回版は通信なしで安心"][variant]
    d.text((68, 74), title, font=font(58 if w < 1300 else 74, True), fill=(20, 31, 46))
    d.text((72, 154 if w < 1300 else 178), subtitle, font=font(30 if w < 1300 else 42), fill=(20, 31, 46, 210))

    pf_w = int(w * (0.72 if w < 1300 else 0.44))
    pf_h = int(h * (0.66 if w < 1300 else 0.72))
    px = (w - pf_w) // 2 if w < 1300 else w - pf_w - 120
    py = h - pf_h - 74
    phone_frame(d, px, py, pf_w, pf_h)
    screen_content(img, px + 18, py + 22, pf_w - 36, pf_h - 44, variant)
    img.convert("RGB").save(path, quality=95)


def main():
    ICON_DIR.mkdir(parents=True, exist_ok=True)
    SHOT_DIR.mkdir(parents=True, exist_ok=True)
    render_icon()
    groups = [
        ("iphone67", (1290, 2796)),
        ("iphone65", (1242, 2688)),
        ("iphone55", (1242, 2208)),
        ("ipad129", (2048, 2732)),
    ]
    for prefix, size in groups:
        for i in range(4):
            render_shot(SHOT_DIR / f"{prefix}_{i + 1:02}.png", size, i)


if __name__ == "__main__":
    main()
