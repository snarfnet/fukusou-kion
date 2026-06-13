#!/usr/bin/env python3
from pathlib import Path
import textwrap

from PIL import Image, ImageDraw, ImageFont


OUT_DIR = Path("MarketingAssets/Screenshots")

SIZES = {
    "iphone67": (1290, 2796),
    "iphone65": (1242, 2688),
    "iphone55": (1242, 2208),
    "ipad129": (2048, 2732),
}

SCREENS = [
    {
        "slug": "home",
        "title": "役所手続きナビ",
        "subtitle": "引っ越し、出産、相続、退職、結婚。状況を選ぶだけで必要な手続きを整理。",
        "chips": ["期限", "必要書類", "提出先", "注意点"],
        "panel_title": "期限が近い手続き",
        "items": [
            ("転入届", "引っ越し後14日以内"),
            ("児童手当", "出生日・転入日から15日以内"),
            ("健康保険", "退職後14日以内"),
        ],
    },
    {
        "slug": "procedure",
        "title": "必要な手続きを一覧化",
        "subtitle": "手続きごとに期限、必要書類、オンライン可否、窓口の目安を確認。",
        "chips": ["保存", "チェック", "検索", "自治体"],
        "panel_title": "引っ越しの主な手続き",
        "items": [
            ("転出届", "引っ越し前後14日以内"),
            ("マイナンバーカード住所変更", "転入届とあわせて"),
            ("国民健康保険", "加入者は住所変更"),
        ],
    },
    {
        "slug": "office",
        "title": "自治体に合わせて確認",
        "subtitle": "市と東京23区の代表所在地・電話を表示。GPSから現在地の自治体も探せます。",
        "chips": ["GPS", "市役所", "区役所", "電話"],
        "panel_title": "役所情報",
        "items": [
            ("渋谷区役所", "〒150-8010 渋谷区宇田川町 1-1"),
            ("電話", "03-3463-1211（代表）"),
            ("川崎市役所", "〒210-8577 川崎市川崎区宮本町1"),
        ],
    },
]


def font(size, weight="regular"):
    candidates = [
        "/System/Library/Fonts/ヒラギノ角ゴシック W6.ttc" if weight == "bold" else "/System/Library/Fonts/ヒラギノ角ゴシック W3.ttc",
        "/System/Library/Fonts/AppleSDGothicNeo.ttc",
        "/System/Library/Fonts/Supplemental/Arial Unicode.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
        "C:/Windows/Fonts/msgothic.ttc",
        "C:/Windows/Fonts/meiryo.ttc",
        "arial.ttf",
    ]
    for candidate in candidates:
        try:
            return ImageFont.truetype(candidate, size)
        except OSError:
            continue
    return ImageFont.load_default()


def draw_wrapped(draw, xy, text, fill, font_obj, width, line_spacing=10):
    chars_per_line = max(10, int(width / max(font_obj.size * 0.55, 1)))
    lines = []
    for para in text.splitlines():
        lines.extend(textwrap.wrap(para, width=chars_per_line) or [""])
    x, y = xy
    for line in lines:
        draw.text((x, y), line, fill=fill, font=font_obj)
        y += font_obj.size + line_spacing
    return y


def rounded(draw, box, radius, fill, outline=None, width=1):
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)


def make_image(prefix, size, screen, index):
    w, h = size
    scale = w / 1290
    img = Image.new("RGB", size, "#f3f6fb")
    draw = ImageDraw.Draw(img)

    navy = "#102d55"
    blue = "#1f5f9f"
    light_blue = "#e4edf8"
    line = "#c9d4e2"
    text = "#172033"
    muted = "#607086"
    white = "#ffffff"

    margin = int(72 * scale)
    top = int(92 * scale)
    draw.rectangle((0, 0, w, int(260 * scale)), fill=navy)
    draw.rectangle((0, int(250 * scale), w, int(360 * scale)), fill="#dce8f5")

    draw.text((margin, top), "役所手続きナビ", fill=white, font=font(int(42 * scale), "bold"))
    draw.text((margin, top + int(64 * scale)), "行政手続きの整理アプリ", fill="#d6e6f7", font=font(int(30 * scale)))

    icon_size = int(118 * scale)
    icon_x = w - margin - icon_size
    icon_y = top - int(8 * scale)
    rounded(draw, (icon_x, icon_y, icon_x + icon_size, icon_y + icon_size), int(28 * scale), "#ffffff")
    draw.line((icon_x + int(31 * scale), icon_y + int(62 * scale), icon_x + int(52 * scale), icon_y + int(82 * scale), icon_x + int(88 * scale), icon_y + int(34 * scale)), fill=blue, width=int(9 * scale))

    title_font = font(int(64 * scale), "bold")
    sub_font = font(int(34 * scale))
    y = int(395 * scale)
    y = draw_wrapped(draw, (margin, y), screen["title"], navy, title_font, w - margin * 2, int(14 * scale))
    y += int(22 * scale)
    y = draw_wrapped(draw, (margin, y), screen["subtitle"], muted, sub_font, w - margin * 2, int(10 * scale))
    y += int(40 * scale)

    chip_x = margin
    for chip in screen["chips"]:
        chip_font = font(int(28 * scale), "bold")
        bbox = draw.textbbox((0, 0), chip, font=chip_font)
        chip_w = bbox[2] - bbox[0] + int(42 * scale)
        rounded(draw, (chip_x, y, chip_x + chip_w, y + int(58 * scale)), int(18 * scale), light_blue, "#b8cde4", int(2 * scale))
        draw.text((chip_x + int(21 * scale), y + int(13 * scale)), chip, fill=navy, font=chip_font)
        chip_x += chip_w + int(16 * scale)
    y += int(104 * scale)

    panel_x = margin
    panel_w = w - margin * 2
    panel_h = min(int(980 * scale), h - y - int(175 * scale))
    rounded(draw, (panel_x, y, panel_x + panel_w, y + panel_h), int(28 * scale), white, line, int(2 * scale))
    draw.text((panel_x + int(42 * scale), y + int(42 * scale)), screen["panel_title"], fill=text, font=font(int(42 * scale), "bold"))

    row_y = y + int(126 * scale)
    for title, detail in screen["items"]:
        row_h = int(182 * scale)
        rounded(draw, (panel_x + int(32 * scale), row_y, panel_x + panel_w - int(32 * scale), row_y + row_h), int(18 * scale), "#f8fafc", line, int(1 * scale))
        box = (panel_x + int(58 * scale), row_y + int(50 * scale), panel_x + int(104 * scale), row_y + int(96 * scale))
        draw.rectangle(box, outline=blue, width=int(5 * scale))
        draw.line((box[0] + int(8 * scale), box[1] + int(25 * scale), box[0] + int(21 * scale), box[1] + int(38 * scale), box[0] + int(42 * scale), box[1] + int(10 * scale)), fill=blue, width=int(5 * scale))
        draw.text((panel_x + int(130 * scale), row_y + int(38 * scale)), title, fill=text, font=font(int(34 * scale), "bold"))
        draw.text((panel_x + int(130 * scale), row_y + int(88 * scale)), detail, fill=muted, font=font(int(28 * scale)))
        row_y += row_h + int(22 * scale)

    footer = "本アプリは一般的な案内です。申請前に自治体・勤務先・保険者の公式情報を確認してください。"
    draw_wrapped(draw, (margin, h - int(150 * scale)), footer, "#6d7888", font(int(25 * scale)), w - margin * 2, int(8 * scale))

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    img.save(OUT_DIR / f"{prefix}_{index:02d}_{screen['slug']}.png")


def main():
    for prefix, size in SIZES.items():
        for index, screen in enumerate(SCREENS, start=1):
            make_image(prefix, size, screen, index)
    print(f"Generated screenshots in {OUT_DIR}")


if __name__ == "__main__":
    main()
