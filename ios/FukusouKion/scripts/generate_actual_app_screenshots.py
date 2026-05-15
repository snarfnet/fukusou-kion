from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "MarketingAssets" / "Screenshots"
OUT.mkdir(parents=True, exist_ok=True)

FONT_PATHS = [
    r"C:\Windows\Fonts\meiryob.ttc",
    r"C:\Windows\Fonts\meiryo.ttc",
    r"C:\Windows\Fonts\YuGothB.ttc",
    r"C:\Windows\Fonts\YuGothM.ttc",
]


def font(size, bold=False):
    paths = FONT_PATHS if bold else FONT_PATHS[1:] + FONT_PATHS[:1]
    for path in paths:
        try:
            return ImageFont.truetype(path, max(8, int(size)))
        except OSError:
            continue
    return ImageFont.load_default()


def scale(value, width):
    return int(value * width / 1320)


def background(width, height):
    strip = Image.new("RGB", (1, height))
    draw = ImageDraw.Draw(strip)
    top = (236, 247, 255)
    bottom = (255, 248, 231)
    for y in range(height):
        t = y / max(1, height - 1)
        color = tuple(int(top[i] * (1 - t) + bottom[i] * t) for i in range(3))
        draw.point((0, y), fill=color)
    return strip.resize((width, height))


def rounded(draw, box, radius, fill, outline=(226, 233, 240)):
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=1)


def wrap(draw, text, max_width, face):
    lines = []
    current = ""
    for char in text:
        candidate = current + char
        if draw.textbbox((0, 0), candidate, font=face)[2] <= max_width or not current:
            current = candidate
        else:
            lines.append(current)
            current = char
    if current:
        lines.append(current)
    return lines


def text(draw, x, y, value, face, fill=(20, 45, 79), max_width=None, gap=7, anchor=None):
    if max_width:
        for line in wrap(draw, value, max_width, face):
            draw.text((x, y), line, font=face, fill=fill)
            y += face.size + gap
        return y
    draw.text((x, y), value, font=face, fill=fill, anchor=anchor)
    return y + face.size


def status_bar(draw, width):
    draw.text((scale(46, width), scale(28, width)), "9:41", font=font(scale(24, width), True), fill=(24, 39, 60))
    draw.text(
        (width - scale(46, width), scale(28, width)),
        "Wi-Fi  100%",
        font=font(scale(18, width)),
        fill=(24, 39, 60),
        anchor="ra",
    )


def tab_bar(draw, width, height, active):
    y = height - scale(124, width)
    rounded(draw, (scale(22, width), y, width - scale(22, width), height - scale(18, width)), scale(30, width), (255, 255, 255))
    tabs = [("ホーム", "⌂"), ("週間", "□"), ("通知", "◉"), ("設定", "⚙")]
    step = (width - scale(80, width)) / 4
    for index, (label, icon) in enumerate(tabs):
        center_x = scale(40, width) + step * (index + 0.5)
        color = (39, 117, 204) if index == active else (132, 145, 160)
        draw.text((center_x, y + scale(24, width)), icon, font=font(scale(28, width), True), fill=color, anchor="ma")
        draw.text((center_x, y + scale(68, width)), label, font=font(scale(18, width), True), fill=color, anchor="ma")


def header(draw, width, y, title, subtitle):
    x = scale(64, width)
    draw.text((x, y), title, font=font(scale(42, width), True), fill=(22, 43, 72))
    y += scale(58, width)
    draw.text((x, y), subtitle, font=font(scale(24, width)), fill=(92, 107, 129))
    return y + scale(48, width)


def banner(draw, width, height):
    x = scale(64, width)
    y = height - scale(238, width)
    box_width = width - scale(128, width)
    box_height = scale(70, width)
    rounded(draw, (x, y, x + box_width, y + box_height), scale(16, width), (238, 243, 248), (215, 224, 233))
    draw.text((x + box_width / 2, y + box_height / 2), "広告", font=font(scale(18, width)), fill=(116, 130, 145), anchor="mm")


def weather_attribution(draw, width, y):
    x = scale(64, width)
    box_width = width - scale(128, width)
    box_height = scale(106, width)
    rounded(draw, (x, y, x + box_width, y + box_height), scale(18, width), (255, 255, 255), (226, 233, 240))
    draw.text(
        (x + scale(24, width), y + scale(22, width)),
        "Weather data provided by  Weather",
        font=font(scale(20, width), True),
        fill=(20, 45, 79),
    )
    draw.text(
        (x + scale(24, width), y + scale(58, width)),
        "https://weatherkit.apple.com/legal-attribution.html",
        font=font(scale(16, width)),
        fill=(39, 117, 204),
    )
    return y + box_height + scale(22, width)


def home(width, height):
    image = background(width, height)
    draw = ImageDraw.Draw(image)
    status_bar(draw, width)
    y = header(draw, width, scale(92, width), "今日なに着る？", "東京都新宿区 ・ 晴れ")
    x = scale(54, width)
    card_width = width - scale(108, width)

    rounded(draw, (x, y, x + card_width, y + scale(390, width)), scale(28, width), (241, 251, 255))
    draw.text((x + scale(36, width), y + scale(38, width)), "26°", font=font(scale(96, width), True), fill=(20, 45, 79))
    draw.text((x + scale(42, width), y + scale(150, width)), "最高 29°　最低 21°", font=font(scale(26, width), True), fill=(82, 101, 124))
    draw.text((x + scale(42, width), y + scale(202, width)), "降水確率 30%　UV 高め", font=font(scale(24, width)), fill=(82, 101, 124))
    draw.text((x + card_width - scale(98, width), y + scale(76, width)), "☀", font=font(scale(88, width), True), fill=(245, 170, 50), anchor="mm")
    rounded(
        draw,
        (x + scale(42, width), y + scale(280, width), x + scale(330, width), y + scale(338, width)),
        scale(30, width),
        (31, 79, 128),
        (31, 79, 128),
    )
    draw.text((x + scale(186, width), y + scale(309, width)), "半袖でOK", font=font(scale(26, width), True), fill=(255, 255, 255), anchor="mm")

    y += scale(430, width)
    rounded(draw, (x, y, x + card_width, y + scale(260, width)), scale(28, width), (255, 244, 242))
    draw.text((x + scale(36, width), y + scale(34, width)), "おすすめ服装", font=font(scale(24, width), True), fill=(110, 84, 82))
    draw.text((x + scale(36, width), y + scale(88, width)), "半袖、薄手シャツ", font=font(scale(38, width), True), fill=(20, 45, 79))
    text(
        draw,
        x + scale(36, width),
        y + scale(148, width),
        "日差しが強いので、日焼け止めと薄手の羽織りがあると安心です。",
        font(scale(24, width)),
        (92, 107, 129),
        card_width - scale(72, width),
    )

    y += scale(300, width)
    rounded(draw, (x, y, x + card_width, y + scale(185, width)), scale(28, width), (235, 244, 255))
    draw.text((x + scale(36, width), y + scale(34, width)), "傘いる？", font=font(scale(24, width), True), fill=(72, 89, 112))
    draw.text((x + scale(36, width), y + scale(88, width)), "今日は不要", font=font(scale(34, width), True), fill=(20, 45, 79))
    draw.text((x + card_width - scale(92, width), y + scale(92, width)), "☂", font=font(scale(56, width), True), fill=(80, 132, 191), anchor="mm")

    y += scale(225, width)
    weather_attribution(draw, width, y)

    banner(draw, width, height)
    tab_bar(draw, width, height, 0)
    return image


def advice(width, height):
    image = background(width, height)
    draw = ImageDraw.Draw(image)
    status_bar(draw, width)
    y = header(draw, width, scale(92, width), "おすすめ服装", "気温と雨から今日のコーデを確認")
    x = scale(54, width)
    card_width = width - scale(108, width)
    rows = [
        ("30℃以上", "半袖・薄手・日焼け対策", "暑さが強い日は、通気性のよい素材と帽子がおすすめ。", (255, 241, 226)),
        ("20〜24℃", "長袖シャツ・薄手カーディガン", "朝晩の冷えに合わせて、脱ぎ着しやすい一枚を。", (239, 248, 255)),
        ("10〜14℃", "コート・ニット", "外出時間が長い日は首元まで暖かく。", (244, 241, 255)),
    ]
    for index, (temp, title, body, color) in enumerate(rows):
        top = y + index * scale(265, width)
        rounded(draw, (x, top, x + card_width, top + scale(230, width)), scale(28, width), color)
        draw.text((x + scale(34, width), top + scale(30, width)), temp, font=font(scale(24, width), True), fill=(91, 103, 120))
        draw.text((x + scale(34, width), top + scale(82, width)), title, font=font(scale(34, width), True), fill=(20, 45, 79))
        text(draw, x + scale(34, width), top + scale(138, width), body, font(scale(22, width)), (92, 107, 129), card_width - scale(68, width))

    y += scale(820, width)
    rounded(draw, (x, y, x + card_width, y + scale(210, width)), scale(28, width), (255, 255, 255))
    draw.text((x + scale(34, width), y + scale(34, width)), "追加チェック", font=font(scale(28, width), True), fill=(20, 45, 79))
    for index, item in enumerate(["降水確率40%以上：折りたたみ傘", "70%以上：普通の傘", "UVが高い：日焼け止め推奨"]):
        draw.text((x + scale(44, width), y + scale(90, width) + index * scale(38, width)), "✓ " + item, font=font(scale(22, width)), fill=(73, 94, 118))
    banner(draw, width, height)
    tab_bar(draw, width, height, 0)
    return image


def week(width, height):
    image = background(width, height)
    draw = ImageDraw.Draw(image)
    status_bar(draw, width)
    y = header(draw, width, scale(92, width), "週間の服装", "7日分の天気と服装を一覧")
    x = scale(54, width)
    card_width = width - scale(108, width)
    days = [
        ("今日", "29/21", "半袖シャツ", "傘なし", "☀"),
        ("金", "24/18", "長袖シャツ", "折りたたみ傘", "☁"),
        ("土", "19/14", "ジャケット", "普通の傘", "☂"),
        ("日", "27/20", "薄手シャツ", "傘なし", "☀"),
        ("月", "16/11", "パーカー", "折りたたみ傘", "☁"),
        ("火", "12/8", "コート", "傘なし", "☀"),
        ("水", "22/17", "カーディガン", "傘なし", "☁"),
    ]
    row_height = scale(150, width)
    for index, (day, temp, outfit, umbrella, icon) in enumerate(days):
        top = y + index * (row_height + scale(18, width))
        rounded(draw, (x, top, x + card_width, top + row_height), scale(24, width), (255, 255, 255))
        draw.text((x + scale(34, width), top + scale(44, width)), day, font=font(scale(26, width), True), fill=(20, 45, 79))
        draw.text((x + scale(132, width), top + scale(34, width)), icon, font=font(scale(42, width), True), fill=(245, 170, 50))
        draw.text((x + scale(210, width), top + scale(32, width)), temp + "℃", font=font(scale(28, width), True), fill=(20, 45, 79))
        draw.text((x + scale(210, width), top + scale(84, width)), outfit, font=font(scale(24, width), True), fill=(73, 94, 118))
        rounded(
            draw,
            (x + card_width - scale(260, width), top + scale(48, width), x + card_width - scale(34, width), top + scale(100, width)),
            scale(26, width),
            (235, 244, 255),
            (235, 244, 255),
        )
        draw.text((x + card_width - scale(147, width), top + scale(74, width)), umbrella, font=font(scale(19, width), True), fill=(55, 91, 137), anchor="mm")
    weather_attribution(draw, width, y + len(days) * (row_height + scale(18, width)) + scale(8, width))
    tab_bar(draw, width, height, 1)
    return image


def settings(width, height):
    image = background(width, height)
    draw = ImageDraw.Draw(image)
    status_bar(draw, width)
    y = header(draw, width, scale(92, width), "通知と設定", "朝の服装チェックを自分向けに")
    x = scale(54, width)
    card_width = width - scale(108, width)
    groups = [
        ("朝の通知", "出かける前に服装と傘を確認", ["7:00", "8:00", "9:00"], 1),
        ("体感タイプ", "暑がり・寒がりに合わせて調整", ["暑がり", "普通", "寒がり"], 1),
        ("表示タイプ", "女性向けの提案を表示", ["女性向け", "共通"], 0),
    ]
    for title, subtitle, options, selected in groups:
        rounded(draw, (x, y, x + card_width, y + scale(285, width)), scale(28, width), (255, 255, 255))
        draw.text((x + scale(34, width), y + scale(34, width)), title, font=font(scale(30, width), True), fill=(20, 45, 79))
        draw.text((x + scale(34, width), y + scale(84, width)), subtitle, font=font(scale(22, width)), fill=(92, 107, 129))
        for index, option in enumerate(options):
            button_width = scale(190, width) if len(options) == 3 else scale(250, width)
            gap = scale(40, width)
            left = x + scale(34, width) + index * (button_width + gap)
            top = y + scale(155, width)
            is_selected = index == selected
            fill = (31, 79, 128) if is_selected else (238, 243, 248)
            rounded(draw, (left, top, left + button_width, top + scale(72, width)), scale(36, width), fill, fill)
            draw.text(
                (left + button_width / 2, top + scale(36, width)),
                option,
                font=font(scale(24, width), True),
                fill=(255, 255, 255) if is_selected else (73, 94, 118),
                anchor="mm",
            )
        y += scale(330, width)
    tab_bar(draw, width, height, 2)
    return image


SIZES = {
    "iphone69": (1320, 2868),
    "iphone65": (1242, 2688),
    "iphone55": (1242, 2208),
    "ipad129": (2048, 2732),
}
VIEWS = [home, advice, week, settings]

for prefix, (width, height) in SIZES.items():
    for index, view in enumerate(VIEWS, 1):
        path = OUT / f"{prefix}_{index:02d}.png"
        view(width, height).save(path)
        print(f"wrote {path} {width}x{height}")
