#!/usr/bin/env python3
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "MarketingAssets" / "Screenshots" / "iphone67"
ICON = ROOT / "TsuchinokoFinder" / "Assets.xcassets" / "AppIcon.appiconset" / "AppIcon.png"
OUT.mkdir(parents=True, exist_ok=True)

SIZE = (946, 2048)
BG = (3, 34, 32)
PANEL = (8, 26, 26)
CARD = (12, 55, 52)
CYAN = (42, 211, 238)
GREEN = (110, 230, 165)
WHITE = (232, 242, 238)
MUTED = (142, 168, 160)


def font(size, bold=False):
    candidates = [
        "C:/Windows/Fonts/meiryob.ttc" if bold else "C:/Windows/Fonts/meiryo.ttc",
        "C:/Windows/Fonts/YuGothB.ttc" if bold else "C:/Windows/Fonts/YuGothR.ttc",
        "C:/Windows/Fonts/msgothic.ttc",
    ]
    for name in candidates:
        if Path(name).exists():
            return ImageFont.truetype(name, size)
    return ImageFont.load_default()


F = {
    "title": font(48, True),
    "h1": font(40, True),
    "h2": font(30, True),
    "body": font(24),
    "small": font(20),
    "mono": font(22, True),
}


def rounded(draw, box, radius, fill, outline=None, width=1):
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)


def text(draw, xy, value, fill=WHITE, f="body", anchor=None):
    draw.text(xy, value, fill=fill, font=F[f], anchor=anchor)


def fit_text(draw, xy, value, max_width, fill=WHITE, f="body", line_gap=8):
    words = list(value)
    lines = []
    current = ""
    for ch in words:
        trial = current + ch
        width = draw.textbbox((0, 0), trial, font=F[f])[2]
        if width > max_width and current:
            lines.append(current)
            current = ch
        else:
            current = trial
    if current:
        lines.append(current)

    x, y = xy
    for line in lines:
        text(draw, (x, y), line, fill=fill, f=f)
        y += F[f].size + line_gap
    return y


def base():
    img = Image.new("RGB", SIZE, BG)
    draw = ImageDraw.Draw(img)
    rounded(draw, (52, 64, 894, 1988), 58, (4, 20, 20), (87, 132, 128), 3)
    rounded(draw, (78, 112, 868, 1940), 28, PANEL)
    return img, draw


def header(draw, subtitle):
    text(draw, (104, 166), "ツチノコを探す！", f="title")
    text(draw, (108, 228), subtitle, fill=MUTED, f="small")


def camera(draw, y=306, candidate=True):
    box = (110, y, 836, y + 590)
    rounded(draw, box, 16, (4, 38, 34), (31, 95, 90), 2)
    try:
        icon = Image.open(ICON).convert("RGB").resize((726, 590))
        icon = icon.filter(ImageFilter.GaussianBlur(1.2))
        return box, icon
    except Exception:
        return box, None


def paste_camera(img, draw, y=306):
    box, icon = camera(draw, y)
    if icon:
        mask = Image.new("L", (726, 590), 0)
        md = ImageDraw.Draw(mask)
        md.rounded_rectangle((0, 0, 726, 590), radius=16, fill=210)
        img.paste(icon, (110, y), mask)
        overlay = Image.new("RGBA", (726, 590), (0, 20, 18, 108))
        img.paste(overlay, (110, y), overlay)
    rounded(draw, box, 16, None, (31, 95, 90), 2)
    rounded(draw, (146, y + 62, 286, y + 112), 24, (0, 0, 0))
    text(draw, (174, y + 76), "LIVE", fill=(255, 90, 90), f="small")
    rounded(draw, (620, y + 62, 790, y + 112), 24, (0, 0, 0))
    text(draw, (650, y + 76), "端末内解析", fill=WHITE, f="small")
    draw.rounded_rectangle((238, y + 248, 708, y + 438), radius=22, outline=CYAN, width=7)
    text(draw, (473, y + 346), "候補", fill=CYAN, f="h1", anchor="mm")


def result_card(draw, y, confidence=86):
    rounded(draw, (110, y, 836, y + 250), 18, CARD, (35, 120, 112), 2)
    text(draw, (150, y + 62), "ツチノコ候補", f="h1")
    text(draw, (154, y + 116), f"信頼度 {confidence}%", fill=MUTED, f="body")
    cx, cy, r = 720, y + 118, 58
    draw.ellipse((cx - r, cy - r, cx + r, cy + r), outline=(55, 87, 84), width=14)
    draw.arc((cx - r, cy - r, cx + r, cy + r), -90, int(-90 + confidence * 3.6), fill=CYAN, width=14)
    text(draw, (cx, cy - 14), f"{confidence}%", fill=WHITE, f="small", anchor="mm")
    text(draw, (154, y + 184), "候補判定ライン", fill=WHITE, f="small")
    draw.rounded_rectangle((154, y + 216, 790, y + 226), radius=5, fill=(52, 88, 84))
    draw.rounded_rectangle((154, y + 216, 640, y + 226), radius=5, fill=CYAN)


def button(draw, box, label, fill):
    rounded(draw, box, 16, fill)
    text(draw, ((box[0] + box[2]) // 2, box[1] + 32), label, fill=(4, 30, 30), f="h2", anchor="mm")


def screen_main():
    img, draw = base()
    header(draw, "山道や草むらの映像から候補を探す")
    paste_camera(img, draw)
    result_card(draw, 930, 86)
    button(draw, (110, 1220, 446, 1322), "停止", CYAN)
    button(draw, (500, 1220, 836, 1322), "リセット", (236, 242, 239))
    rounded(draw, (110, 1385, 836, 1548), 18, (5, 35, 34), (28, 103, 98), 2)
    text(draw, (150, 1428), "通知", fill=CYAN, f="h2")
    text(draw, (150, 1482), "候補を検知したら端末に通知", fill=WHITE, f="body")
    rounded(draw, (690, 1446, 792, 1496), 25, CYAN)
    draw.ellipse((742, 1450, 788, 1496), fill=WHITE)
    img.save(OUT / "iphone67_01_main.png", optimize=True)


def screen_threshold():
    img, draw = base()
    header(draw, "何千枚もの想像画像で候補を判定")
    paste_camera(img, draw, 300)
    result_card(draw, 930, 76)
    rounded(draw, (110, 1235, 836, 1512), 18, (5, 35, 34), (28, 103, 98), 2)
    text(draw, (150, 1280), "調整できる判定ライン", fill=CYAN, f="h2")
    fit_text(draw, (150, 1340), "慎重に探したいときは高めに、広く候補を拾いたいときは低めにできます。", 620, fill=WHITE, f="body")
    draw.rounded_rectangle((150, 1462, 792, 1478), radius=8, fill=(52, 88, 84))
    draw.rounded_rectangle((150, 1462, 628, 1478), radius=8, fill=CYAN)
    rounded(draw, (110, 1570, 836, 1772), 18, (5, 35, 34), (28, 103, 98), 2)
    fit_text(draw, (150, 1618), "枝、根、ホース、普通の蛇などを見間違えにくいよう調整しています。", 620, fill=WHITE, f="body")
    img.save(OUT / "iphone67_02_threshold.png", optimize=True)


def screen_log():
    img, draw = base()
    header(draw, "候補ログと通知で見逃しを減らす")
    paste_camera(img, draw, 300)
    rounded(draw, (110, 930, 836, 1255), 18, CARD, (35, 120, 112), 2)
    text(draw, (150, 982), "候補ログ", fill=CYAN, f="h2")
    logs = [("09:42:18", "86%"), ("09:38:02", "78%"), ("09:31:44", "69%")]
    y = 1042
    for stamp, score in logs:
        rounded(draw, (150, y, 796, y + 54), 12, (22, 70, 66))
        text(draw, (178, y + 13), stamp, f="small")
        text(draw, (716, y + 13), score, fill=CYAN, f="small")
        y += 70
    rounded(draw, (110, 1305, 836, 1535), 18, (5, 35, 34), (28, 103, 98), 2)
    text(draw, (150, 1353), "端末通知", fill=CYAN, f="h2")
    fit_text(draw, (150, 1413), "候補を検知したタイミングで通知。画面を見続けなくても反応に気づきやすくなります。", 620, fill=WHITE, f="body")
    rounded(draw, (110, 1595, 836, 1797), 18, (5, 35, 34), (28, 103, 98), 2)
    fit_text(draw, (150, 1645), "映像は端末内で解析。外部送信せず、現地確認のきっかけとして使えます。", 620, fill=WHITE, f="body")
    img.save(OUT / "iphone67_03_log.png", optimize=True)


def main():
    screen_main()
    screen_threshold()
    screen_log()


if __name__ == "__main__":
    main()
