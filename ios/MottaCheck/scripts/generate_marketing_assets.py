from pathlib import Path
import math

from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "MarketingAssets" / "Icons" / "app-icon-source-imagegen.png"
ICON_OUT = ROOT / "MottaCheck" / "Assets.xcassets" / "AppIcon.appiconset" / "Icon-1024.png"
SCREENSHOT_DIR = ROOT / "MarketingAssets" / "Screenshots"

BG = (246, 248, 241)
INK = (25, 33, 30)
MUTED = (96, 105, 98)
OLIVE = (38, 97, 77)
CORAL = (199, 70, 55)
BLUE = (54, 86, 158)
MINT = (35, 135, 101)
WHITE = (255, 255, 255)


def font(size, bold=False):
    candidates = [
        r"C:\Windows\Fonts\YuGothB.ttc" if bold else r"C:\Windows\Fonts\YuGothR.ttc",
        r"C:\Windows\Fonts\meiryo.ttc",
        r"C:\Windows\Fonts\msgothic.ttc",
    ]
    for path in candidates:
        if Path(path).exists():
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def cover(img, size):
    ratio = max(size[0] / img.width, size[1] / img.height)
    resized = img.resize((math.ceil(img.width * ratio), math.ceil(img.height * ratio)), Image.Resampling.LANCZOS)
    left = (resized.width - size[0]) // 2
    top = (resized.height - size[1]) // 2
    return resized.crop((left, top, left + size[0], top + size[1]))


def rounded(draw, xy, radius, fill, outline=None, width=1):
    draw.rounded_rectangle(xy, radius=radius, fill=fill, outline=outline, width=width)


def make_icon():
    source = cover(Image.open(SOURCE).convert("RGB"), (1024, 1024))
    overlay = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
    d = ImageDraw.Draw(overlay)
    d.rounded_rectangle((90, 90, 934, 934), radius=190, fill=(255, 255, 255, 44))
    d.ellipse((682, 126, 898, 342), fill=(38, 97, 77, 230))
    d.line((734, 240, 786, 292, 858, 196), fill=(255, 255, 255, 255), width=34, joint="curve")
    source = Image.alpha_composite(source.convert("RGBA"), overlay).convert("RGB")
    source.save(ICON_OUT)
    (ROOT / "MarketingAssets" / "Icons" / "app-icon-1024.png").write_bytes(ICON_OUT.read_bytes())


def draw_phone(draw, x, y, w, h, scene):
    rounded(draw, (x, y, x + w, y + h), 46, (18, 22, 21))
    rounded(draw, (x + 14, y + 16, x + w - 14, y + h - 16), 36, (248, 249, 245))
    sx, sy = x + 40, y + 70
    draw.text((sx, sy), "持った？", fill=INK, font=font(max(28, w // 15), True))
    draw.text((sx, sy + 52), scene["small"], fill=MUTED, font=font(max(17, w // 26)))

    card_y = sy + 112
    rounded(draw, (sx, card_y, x + w - 40, card_y + 178), 18, WHITE, (226, 230, 222), 2)
    draw.text((sx + 24, card_y + 22), scene["list"], fill=INK, font=font(max(24, w // 17), True))
    draw.arc((x + w - 118, card_y + 28, x + w - 58, card_y + 88), -90, 220, fill=OLIVE, width=8)
    draw.text((x + w - 116, card_y + 96), scene["progress"], fill=OLIVE, font=font(max(16, w // 28), True))

    items = scene["items"]
    item_y = card_y + 212
    for i, item in enumerate(items[:5]):
        cy = item_y + i * 58
        color = OLIVE if i < scene["checked"] else (160, 166, 158)
        draw.ellipse((sx, cy, sx + 30, cy + 30), outline=color, width=4)
        if i < scene["checked"]:
            draw.line((sx + 7, cy + 16, sx + 14, cy + 23, sx + 24, cy + 8), fill=color, width=4)
        draw.text((sx + 46, cy - 3), item, fill=INK if i >= scene["checked"] else MUTED, font=font(max(20, w // 21), True))

    button_y = y + h - 120
    rounded(draw, (sx, button_y, x + w - 40, button_y + 64), 16, OLIVE)
    draw.text((sx + 46, button_y + 13), scene["button"], fill=WHITE, font=font(max(20, w // 21), True))


def make_screenshot(size, filename, headline, subline, scene, accent):
    w, h = size
    base = Image.new("RGB", size, BG)
    d = ImageDraw.Draw(base)

    source = cover(Image.open(SOURCE).convert("RGB"), size).filter(ImageFilter.GaussianBlur(11))
    tint = Image.new("RGB", size, BG)
    base = Image.blend(source, tint, 0.72)
    d = ImageDraw.Draw(base)

    margin = int(w * 0.075)
    top = int(h * 0.07)
    d.rounded_rectangle((margin, top, margin + int(w * 0.18), top + int(w * 0.052)), radius=18, fill=accent)
    d.text((margin + int(w * 0.026), top + int(w * 0.012)), "忘れ物ゼロ", fill=WHITE, font=font(max(24, int(w * 0.026)), True))

    d.text((margin, top + int(h * 0.095)), headline, fill=INK, font=font(max(58, int(w * 0.072)), True))
    d.text((margin, top + int(h * 0.205)), subline, fill=MUTED, font=font(max(28, int(w * 0.034))))

    phone_w = int(w * (0.58 if w < 1600 else 0.42))
    phone_h = int(phone_w * 2.05)
    phone_x = (w - phone_w) // 2
    phone_y = h - phone_h - int(h * 0.055)
    shadow = Image.new("RGBA", size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rounded_rectangle((phone_x + 14, phone_y + 24, phone_x + phone_w + 14, phone_y + phone_h + 24), radius=52, fill=(0, 0, 0, 42))
    base = Image.alpha_composite(base.convert("RGBA"), shadow.filter(ImageFilter.GaussianBlur(18))).convert("RGB")
    d = ImageDraw.Draw(base)
    draw_phone(d, phone_x, phone_y, phone_w, phone_h, scene)
    base.save(SCREENSHOT_DIR / filename)


def make_all_screenshots():
    scenes = [
        ("01_home", "出る前に、\n必要なものだけ確認", "財布、鍵、スマホ。よく使うリストをすぐ開けます。",
         {"small": "今日使うチェックリスト", "list": "仕事", "progress": "71%", "checked": 4, "button": "全部持った！", "items": ["財布", "鍵", "スマホ", "社員証", "イヤホン"]}, OLIVE),
        ("02_check", "チェック完了が\nひと目でわかる", "進捗を見ながら、忘れやすい物も記録できます。",
         {"small": "チェック進捗", "list": "旅行", "progress": "63%", "checked": 3, "button": "全部持った！", "items": ["財布", "鍵", "スマホ", "充電器", "チケット"]}, CORAL),
        ("03_template", "シーン別テンプレを\nそのまま使える", "仕事、学校、旅行、ジム、病院を用意しました。",
         {"small": "テンプレート", "list": "学校", "progress": "0%", "checked": 0, "button": "リストに追加", "items": ["学生証", "教科書", "ノート", "筆箱", "体操服"]}, BLUE),
        ("04_notice", "朝と出発前に\n通知で思い出す", "出発何分前か、曜日ごとの通知も設定できます。",
         {"small": "通知設定", "list": "平日の朝", "progress": "ON", "checked": 2, "button": "通知を保存", "items": ["朝 7:15", "出発15分前", "月 火 水 木 金", "User Notifications", ""]}, MINT),
        ("05_history", "忘れやすい物を\nランキングで確認", "何を忘れがちか見えるので、次の外出に活かせます。",
         {"small": "履歴", "list": "忘れやすい物", "progress": "TOP", "checked": 1, "button": "テーマを解放", "items": ["充電器 3回", "社員証 2回", "マスク 2回", "保険証 1回", "イヤホン 1回"]}, OLIVE),
    ]
    sizes = {
        "iphone69": (1320, 2868),
        "iphone65": (1242, 2688),
        "iphone55": (1242, 2208),
        "ipad129": (2048, 2732),
    }
    for prefix, size in sizes.items():
        for index, (slug, headline, subline, scene, accent) in enumerate(scenes, 1):
            make_screenshot(size, f"{prefix}_{index:02d}_{slug.split('_', 1)[1]}.png", headline, subline, scene, accent)


if __name__ == "__main__":
    make_icon()
    make_all_screenshots()
