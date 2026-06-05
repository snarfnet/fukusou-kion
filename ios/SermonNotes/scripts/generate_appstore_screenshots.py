from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


OUT = Path("MarketingAssets/Screenshots")
OUT.mkdir(parents=True, exist_ok=True)

W, H = 1290, 2796
NAVY = (24, 55, 91)
INK = (22, 34, 48)
MUTED = (102, 112, 122)
BG = (250, 247, 239)
CARD = (255, 253, 248)
CHIP = (239, 235, 225)
GOLD = (206, 160, 72)
SAGE = (112, 154, 128)


def font(size, bold=False):
    candidates = [
        "C:/Windows/Fonts/YuGothB.ttc" if bold else "C:/Windows/Fonts/YuGothR.ttc",
        "C:/Windows/Fonts/meiryo.ttc",
        "/System/Library/Fonts/ヒラギノ角ゴシック W6.ttc" if bold else "/System/Library/Fonts/ヒラギノ角ゴシック W3.ttc",
        "/System/Library/Fonts/Helvetica.ttc",
    ]
    for candidate in candidates:
        try:
            return ImageFont.truetype(candidate, size)
        except Exception:
            pass
    return ImageFont.load_default()


def rounded(draw, box, radius, fill, outline=None, width=1):
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)


def text(draw, xy, value, size, fill=INK, bold=False, anchor=None):
    draw.text(xy, value, font=font(size, bold), fill=fill, anchor=anchor)


def phone_frame(draw, x, y, w, h):
    rounded(draw, (x, y, x + w, y + h), 78, (40, 43, 47))
    rounded(draw, (x + 14, y + 14, x + w - 14, y + h - 14), 64, (255, 255, 255))
    return (x + 34, y + 42, x + w - 34, y + h - 42)


def draw_home(draw, box):
    x1, y1, x2, y2 = box
    draw.rectangle(box, fill=BG)
    text(draw, ((x1 + x2) // 2, y1 + 54), "教会ノート", 30, bold=True, anchor="mm")
    rounded(draw, (x1 + 32, y1 + 116, x2 - 32, y1 + 292), 18, CARD)
    rounded(draw, (x1 + 58, y1 + 148, x1 + 130, y1 + 220), 14, NAVY)
    text(draw, (x1 + 94, y1 + 184), "✝", 46, fill=(255, 255, 255), bold=True, anchor="mm")
    text(draw, (x1 + 154, y1 + 154), "神さまのことばを、心に刻む", 25, bold=True)
    text(draw, (x1 + 154, y1 + 199), "礼拝、説教、祈りを一つの場所へ。", 20, fill=MUTED)
    for i, label in enumerate(["すべて", "礼拝メモ", "説教メモ", "祈りの課題"]):
        xx = x1 + 32 + i * 132
        rounded(draw, (xx, y1 + 326, xx + 116, y1 + 376), 25, NAVY if i == 0 else CHIP)
        text(draw, (xx + 58, y1 + 351), label, 17, fill=(255, 255, 255) if i == 0 else INK, bold=True, anchor="mm")
    rows = [
        ("礼拝メモ", "山田 牧師", "ヨハネ 3:16", "2026年6月7日（日）", "📝"),
        ("説教メモ", "山田 牧師", "マタイ 5:1-12", "2026年5月31日（日）", "📖"),
        ("祈りの課題", "佐藤 牧師", "ピリピ 4:6-7", "2026年5月24日（日）", "🙏"),
        ("感謝のメモ", "田中 牧師", "詩篇 23:1-6", "2026年5月17日（日）", "📝"),
    ]
    yy = y1 + 418
    for title, pastor, scripture, date, icon in rows:
        text(draw, (x1 + 58, yy + 46), icon, 34, fill=NAVY, anchor="mm")
        text(draw, (x1 + 114, yy + 10), date, 16, fill=MUTED)
        text(draw, (x1 + 114, yy + 44), title, 25, bold=True)
        text(draw, (x1 + 114, yy + 84), f"{pastor}      {scripture}", 18, fill=MUTED)
        draw.line((x1 + 114, yy + 124, x2 - 48, yy + 124), fill=(226, 222, 214), width=1)
        yy += 142
    rounded(draw, (x2 - 112, y2 - 184, x2 - 42, y2 - 114), 35, NAVY)
    text(draw, (x2 - 77, y2 - 150), "+", 42, fill=(255, 255, 255), anchor="mm")


def draw_editor(draw, box):
    x1, y1, x2, y2 = box
    draw.rectangle(box, fill=(255, 255, 255))
    text(draw, ((x1 + x2) // 2, y1 + 54), "メモ編集", 30, bold=True, anchor="mm")
    fields = [
        ("タイトル", "山上の説教 - 心の姿勢について"),
        ("牧師名", "山田 牧師"),
        ("教会名", "Grace Church"),
        ("聖書箇所", "マタイ 5:1-12"),
    ]
    yy = y1 + 120
    for label, value in fields:
        text(draw, (x1 + 48, yy), label, 17, fill=MUTED)
        rounded(draw, (x1 + 48, yy + 28, x2 - 48, yy + 92), 8, (252, 251, 248), (218, 214, 206))
        text(draw, (x1 + 68, yy + 49), value, 21)
        yy += 112
    text(draw, (x1 + 48, yy + 4), "メモ", 17, fill=MUTED)
    rounded(draw, (x1 + 48, yy + 34, x2 - 48, yy + 348), 8, (252, 251, 248), (218, 214, 206))
    memo = ["・貧しい人は幸いである", "・柔和な人は幸いである", "・義に飢え渇く人は幸いである", "・心の姿勢が神の国に入る鍵である"]
    for i, line in enumerate(memo):
        text(draw, (x1 + 72, yy + 70 + i * 45), line, 20)
    text(draw, (x1 + 48, yy + 386), "祈りの課題", 17, fill=MUTED)
    rounded(draw, (x1 + 48, yy + 418, x2 - 48, yy + 568), 8, (252, 251, 248), (218, 214, 206))
    text(draw, (x1 + 72, yy + 456), "家族のために祈る", 20)
    text(draw, (x1 + 72, yy + 504), "今週も静かな心で歩めるように", 20)


def draw_prayer(draw, box):
    x1, y1, x2, y2 = box
    draw.rectangle(box, fill=BG)
    text(draw, ((x1 + x2) // 2, y1 + 54), "祈りの課題", 30, bold=True, anchor="mm")
    items = [
        ("家族の健康", "礼拝メモ", False),
        ("新しい働きのために", "説教メモ", False),
        ("感謝を忘れない心", "感謝のメモ", True),
        ("教会の友人のために", "祈りの課題", False),
    ]
    yy = y1 + 132
    for title, source, done in items:
        rounded(draw, (x1 + 38, yy, x2 - 38, yy + 118), 14, CARD)
        text(draw, (x1 + 82, yy + 58), "✓" if done else "○", 31, fill=SAGE if done else NAVY, anchor="mm")
        text(draw, (x1 + 124, yy + 30), title, 23, bold=True)
        text(draw, (x1 + 124, yy + 70), source, 18, fill=MUTED)
        yy += 142


def make(path, title, subtitle, screen):
    img = Image.new("RGB", (W, H), BG)
    draw = ImageDraw.Draw(img)
    for y in range(H):
        blend = y / H
        r = int(BG[0] * (1 - blend) + 238 * blend)
        g = int(BG[1] * (1 - blend) + 232 * blend)
        b = int(BG[2] * (1 - blend) + 220 * blend)
        draw.line((0, y, W, y), fill=(r, g, b))
    text(draw, (92, 190), title, 76, fill=NAVY, bold=True)
    text(draw, (92, 294), subtitle, 34, fill=INK)
    box = phone_frame(draw, 325, 510, 640, 1388)
    screen(draw, box)
    text(draw, (92, 2070), "礼拝メモ、説教メモ、祈りの課題を、", 38, fill=INK)
    text(draw, (92, 2130), "日付・牧師名・聖書箇所で整理できます。", 38, fill=INK)
    img.save(OUT / path)


make("iphone67_01_home.png", "教会ノート", "神さまのことばを、心に刻むために", draw_home)
make("iphone67_02_editor.png", "すばやく記録", "礼拝中でも迷わず書けるメモ画面", draw_editor)
make("iphone67_03_prayer.png", "祈りを続ける", "祈りの課題を残して振り返る", draw_prayer)
