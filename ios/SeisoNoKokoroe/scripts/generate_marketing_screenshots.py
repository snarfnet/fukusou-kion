from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "MarketingAssets" / "Screenshots"

SIZES = {
    "iphone67": (1290, 2796),
    "iphone65": (1242, 2688),
    "iphone55": (1242, 2208),
    "ipad129": (2048, 2732),
}

SCENES = [
    {
        "title": "清掃の心得",
        "subtitle": "豆知識をタイプライター風に表示",
        "body": "フローリングは水拭きの前に乾拭きする。\n先にホコリを取ることで汚れが広がらない。",
        "chips": ["キッチン", "5分", "初級"],
    },
    {
        "title": "風水で今日の掃除場所",
        "subtitle": "毎日変わる吉方角とラッキーカラー",
        "body": "玄関を掃除すると運気が上がる。\n靴を揃えるだけでも効果あり。",
        "chips": ["玄関", "3分", "初級"],
    },
    {
        "title": "ホウキ針タイマー",
        "subtitle": "掃除時間をアナログ時計風に管理",
        "body": "短い時間で集中して掃除する方が効果的。\n3分、5分、10分から選べます。",
        "chips": ["全体", "10分", "中級"],
    },
]

GREEN = (46, 112, 92)
DEEP_GREEN = (33, 48, 45)
GOLD = (242, 201, 120)
BG_TOP = (243, 247, 240)
BG_BOTTOM = (250, 245, 230)


def font(size, bold=False):
    candidates = [
        "C:/Windows/Fonts/YuGothB.ttc" if bold else "C:/Windows/Fonts/YuGothR.ttc",
        "C:/Windows/Fonts/meiryob.ttc" if bold else "C:/Windows/Fonts/meiryo.ttc",
        "/System/Library/Fonts/Helvetica.ttc",
    ]
    for candidate in candidates:
        if Path(candidate).exists():
            return ImageFont.truetype(candidate, size)
    return ImageFont.load_default()


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def draw_scene(size_name, size, scene, index):
    w, h = size
    img = Image.new("RGB", size, BG_TOP)
    draw = ImageDraw.Draw(img)

    for y in range(h):
        color = lerp(BG_TOP, BG_BOTTOM, y / h)
        draw.line((0, y, w, y), fill=color)

    margin = int(w * 0.07)
    top = int(h * 0.06)

    label_font = font(max(28, int(w * 0.025)), True)
    title_font = font(max(64, int(w * 0.058)), True)
    sub_font = font(max(34, int(w * 0.032)), False)
    body_font = font(max(32, int(w * 0.030)), False)
    chip_font = font(max(26, int(w * 0.024)), True)

    draw.text((margin, top), "CLEAN NOTE", fill=GREEN, font=label_font)
    draw.text((margin, top + int(w * 0.06)), scene["title"], fill=DEEP_GREEN, font=title_font)
    draw.text((margin, top + int(w * 0.17)), scene["subtitle"], fill=(104, 118, 112), font=sub_font)

    card_top = int(h * 0.28)
    card_bottom = int(h * 0.72)
    card_left = margin
    card_right = w - margin

    draw.rounded_rectangle(
        (card_left, card_top, card_right, card_bottom),
        radius=24,
        fill=GREEN,
    )

    circle_x = card_right - int(w * 0.08)
    circle_y = card_bottom - int(w * 0.04)
    r = int(w * 0.18)
    draw.ellipse(
        (circle_x - r, circle_y - r, circle_x + r, circle_y + r),
        outline=(255, 255, 255, 26),
        width=max(6, int(w * 0.005)),
    )

    text_x = card_left + int(w * 0.05)
    text_y = card_top + int(w * 0.05)

    draw.text((text_x, text_y), scene["chips"][0].upper(), fill=GOLD, font=label_font)
    text_y += int(w * 0.06)

    draw.text((text_x, text_y), scene["title"], fill=(255, 255, 255), font=font(max(48, int(w * 0.046)), True))
    text_y += int(w * 0.10)

    chip_x = text_x
    for chip in scene["chips"]:
        tw = int(draw.textlength(chip, font=chip_font)) + 28
        draw.rounded_rectangle(
            (chip_x, text_y, chip_x + tw, text_y + int(w * 0.04)),
            radius=int(w * 0.02),
            fill=(255, 255, 255, 38),
            outline=(255, 255, 255, 56),
        )
        draw.text((chip_x + 14, text_y + int(w * 0.007)), chip, fill=(255, 255, 255), font=chip_font)
        chip_x += tw + 12
    text_y += int(w * 0.07)

    inner_left = text_x
    inner_right = card_right - int(w * 0.05)
    inner_top = text_y
    inner_bottom = card_bottom - int(w * 0.05)
    draw.rounded_rectangle(
        (inner_left, inner_top, inner_right, inner_bottom),
        radius=18,
        fill=(255, 255, 255, 36),
        outline=(255, 255, 255, 66),
    )

    body_y = inner_top + int(w * 0.03)
    for line in scene["body"].split("\n"):
        draw.text((inner_left + 16, body_y), line, fill=(255, 255, 255), font=body_font)
        body_y += int(body_font.size * 1.6)

    cursor_y = body_y + 4
    draw.rectangle(
        (inner_left + 16, cursor_y, inner_left + 25, cursor_y + int(w * 0.025)),
        fill=GOLD,
    )

    timer_top = int(h * 0.75)
    timer_bottom = int(h * 0.94)
    draw.rounded_rectangle(
        (margin, timer_top, w - margin, timer_bottom),
        radius=24,
        fill=(255, 255, 255, 220),
        outline=(217, 209, 189),
    )

    draw.text((margin + int(w * 0.04), timer_top + int(w * 0.03)), "BROOM TIMER", fill=GREEN, font=label_font)
    draw.text(
        (margin + int(w * 0.04), timer_top + int(w * 0.07)),
        "ホウキ針タイマー",
        fill=DEEP_GREEN,
        font=font(max(36, int(w * 0.034)), True),
    )

    dial_cx = w // 2
    dial_cy = timer_top + int((timer_bottom - timer_top) * 0.62)
    dial_r = int(w * 0.12)
    draw.ellipse(
        (dial_cx - dial_r, dial_cy - dial_r, dial_cx + dial_r, dial_cy + dial_r),
        fill=(243, 247, 240),
        outline=(200, 195, 180),
        width=2,
    )
    draw.text(
        (dial_cx - int(w * 0.04), dial_cy - int(w * 0.02)),
        "10:00",
        fill=DEEP_GREEN,
        font=font(max(30, int(w * 0.028)), True),
    )

    folder = OUT / size_name
    folder.mkdir(parents=True, exist_ok=True)
    img.save(folder / f"{size_name}_{index:02d}.png", optimize=True)


def main():
    for size_name, size in SIZES.items():
        for index, scene in enumerate(SCENES, start=1):
            draw_scene(size_name, size, scene, index)
    print(f"Wrote screenshots to {OUT}")


if __name__ == "__main__":
    main()
