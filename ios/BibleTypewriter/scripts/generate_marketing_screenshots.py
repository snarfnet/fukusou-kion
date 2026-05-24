from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[1]
BG = ROOT / "BibleTypewriter" / "Backgrounds"
OUT = ROOT / "MarketingAssets" / "Screenshots"

SIZES = {
    "iphone67": (1290, 2796),
    "iphone65": (1242, 2688),
    "iphone55": (1242, 2208),
    "ipad129": (2048, 2732),
}


@dataclass(frozen=True)
class Scene:
    category: str
    filename: str
    book: str
    chapter: str
    translation: str
    meta: str
    verses: list[tuple[str, str]]
    controls: tuple[str, str, str]


SCENES = [
    Scene(
        "genesis",
        "chapter_bg_001.jpg",
        "創世記",
        "1章",
        "口語訳",
        "天地創造のはじまり",
        [
            ("1", "はじめに神は天と地とを創造された。"),
            ("2", "地は形なく、むなしく、やみが淵のおもてにあり、神の霊が水のおもてをおおっていた。"),
            ("3", "神は「光あれ」と言われた。すると光があった。"),
        ],
        ("口語訳", "創世記", "1章"),
    ),
    Scene(
        "psalms",
        "chapter_bg_020.jpg",
        "詩篇",
        "23篇",
        "口語訳",
        "静かな祈りの時間",
        [
            ("1", "主はわたしの牧者であって、わたしには乏しいことがない。"),
            ("2", "主はわたしを緑の牧場に伏させ、いこいのみぎわに伴われる。"),
            ("3", "主はわたしの魂をいきかえらせ、み名のためにわたしを正しい道に導かれる。"),
        ],
        ("口語訳", "詩篇", "23篇"),
    ),
    Scene(
        "gospels",
        "chapter_bg_047.jpg",
        "ヨハネによる福音書",
        "1章",
        "WEB",
        "日本語と英語で読む聖書",
        [
            ("1", "In the beginning was the Word, and the Word was with God, and the Word was God."),
            ("2", "The same was in the beginning with God."),
            ("3", "All things were made through him. Without him, nothing was made that has been made."),
        ],
        ("WEB", "John", "1章"),
    ),
]


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    candidates = [
        "C:/Windows/Fonts/YuMincho.ttc",
        "C:/Windows/Fonts/YuGothB.ttc" if bold else "C:/Windows/Fonts/YuGothR.ttc",
        "C:/Windows/Fonts/meiryob.ttc" if bold else "C:/Windows/Fonts/meiryo.ttc",
        "/System/Library/Fonts/ヒラギノ明朝 ProN.ttc",
        "/System/Library/Fonts/ヒラギノ角ゴシック W6.ttc",
        "/System/Library/Fonts/Hiragino Sans GB.ttc",
    ]
    for candidate in candidates:
        path = Path(candidate)
        if path.exists():
            return ImageFont.truetype(str(path), size)
    return ImageFont.load_default()


def cover(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    source_ratio = image.width / image.height
    target_ratio = size[0] / size[1]
    if source_ratio > target_ratio:
        h = size[1]
        w = round(h * source_ratio)
    else:
        w = size[0]
        h = round(w / source_ratio)
    image = image.resize((w, h), Image.Resampling.LANCZOS)
    return image.crop(((w - size[0]) // 2, (h - size[1]) // 2, (w + size[0]) // 2, (h + size[1]) // 2))


def rounded_rect(draw: ImageDraw.ImageDraw, box, radius: int, fill, outline=None, width: int = 1) -> None:
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)


def text_height(draw: ImageDraw.ImageDraw, value: str, fnt) -> int:
    box = draw.textbbox((0, 0), value, font=fnt)
    return box[3] - box[1]


def wrap_text(draw: ImageDraw.ImageDraw, text: str, max_width: int, fnt) -> list[str]:
    if " " in text and text.isascii():
        chunks = text.split(" ")
        lines: list[str] = []
        line = ""
        for chunk in chunks:
            candidate = chunk if not line else f"{line} {chunk}"
            if draw.textbbox((0, 0), candidate, font=fnt)[2] <= max_width or not line:
                line = candidate
            else:
                lines.append(line)
                line = chunk
        if line:
            lines.append(line)
        return lines

    lines = []
    line = ""
    for char in text:
        candidate = line + char
        if draw.textbbox((0, 0), candidate, font=fnt)[2] <= max_width or not line:
            line = candidate
        else:
            lines.append(line)
            line = char
    if line:
        lines.append(line)
    return lines


def draw_wrapped(draw: ImageDraw.ImageDraw, text: str, x: int, y: int, max_width: int, fnt, fill, spacing: int) -> int:
    for line in wrap_text(draw, text, max_width, fnt):
        draw.text((x, y), line, font=fnt, fill=fill)
        y += text_height(draw, line, fnt) + spacing
    return y


def draw_header(draw: ImageDraw.ImageDraw, size: tuple[int, int], scene: Scene, margin: int) -> None:
    title_font = font(int(size[0] * 0.092), True)
    small_font = font(int(size[0] * 0.033))
    meta_font = font(int(size[0] * 0.030))

    top = int(size[1] * 0.055)
    draw.text((margin, top), "静かな聖書朗読", font=small_font, fill=(255, 255, 255, 210))
    draw.text((margin, top + int(size[0] * 0.060)), "聖書のことば", font=title_font, fill=(255, 255, 255, 250))
    draw.text(
        (margin, top + int(size[0] * 0.168)),
        scene.meta,
        font=meta_font,
        fill=(255, 255, 255, 174),
    )


def draw_reader_panel(draw: ImageDraw.ImageDraw, image: Image.Image, size: tuple[int, int], scene: Scene, margin: int) -> None:
    panel_top = int(size[1] * 0.215)
    panel_bottom = int(size[1] * 0.770)
    panel_left = margin
    panel_right = size[0] - margin

    panel = Image.new("RGBA", (panel_right - panel_left, panel_bottom - panel_top), (8, 13, 25, 105))
    panel = panel.filter(ImageFilter.GaussianBlur(0.15))
    image.alpha_composite(panel, (panel_left, panel_top))
    draw.rectangle(
        (panel_left, panel_top, panel_right, panel_bottom),
        outline=(255, 255, 255, 58),
        width=max(2, size[0] // 560),
    )

    fade_top = Image.new("RGBA", (panel_right - panel_left, int(size[1] * 0.15)), (0, 0, 0, 0))
    fade_draw = ImageDraw.Draw(fade_top)
    for y in range(fade_top.height):
        alpha = max(0, 150 - int(y * 150 / fade_top.height))
        fade_draw.line((0, y, fade_top.width, y), fill=(6, 10, 22, alpha))
    image.alpha_composite(fade_top, (panel_left, panel_top))

    reference_font = font(int(size[0] * 0.035))
    verse_font = font(int(size[0] * 0.050), True)
    number_font = font(int(size[0] * 0.030), True)
    body_left = panel_left + int(size[0] * 0.060)
    body_width = panel_right - body_left - int(size[0] * 0.060)
    y = panel_top + int(size[0] * 0.075)

    draw.text(
        (body_left, y),
        f"{scene.book} {scene.chapter} / {scene.translation}",
        font=reference_font,
        fill=(255, 255, 255, 210),
    )
    y += int(size[0] * 0.115)

    for index, (number, verse) in enumerate(scene.verses):
        number_fill = (232, 200, 120, 238)
        text_fill = (255, 255, 255, 245 if index == 1 else 218)
        draw.text((body_left, y + int(size[0] * 0.006)), number, font=number_font, fill=number_fill)
        y = draw_wrapped(
            draw,
            verse,
            body_left + int(size[0] * 0.055),
            y,
            body_width - int(size[0] * 0.055),
            verse_font,
            text_fill,
            int(size[0] * 0.018),
        )
        if index == 1:
            cursor_x = body_left + int(size[0] * 0.055) + min(body_width // 2, int(size[0] * 0.30))
            draw.rectangle(
                (cursor_x, y - int(size[0] * 0.060), cursor_x + max(3, size[0] // 360), y - int(size[0] * 0.006)),
                fill=(255, 255, 255, 220),
            )
        y += int(size[0] * 0.055)


def draw_controls(image: Image.Image, size: tuple[int, int], scene: Scene, margin: int) -> None:
    overlay = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    control_top = int(size[1] * 0.795)
    control_bottom = int(size[1] * 0.952)
    left = margin
    right = size[0] - margin
    rounded_rect(
        draw,
        (left, control_top, right, control_bottom),
        radius=0,
        fill=(5, 9, 18, 136),
        outline=(255, 255, 255, 52),
        width=max(2, size[0] // 640),
    )

    gap = int(size[0] * 0.022)
    inner = int(size[0] * 0.030)
    button_h = int(size[0] * 0.085)
    col_w = (right - left - inner * 2 - gap * 2) // 3
    font_small = font(int(size[0] * 0.032), True)

    y = control_top + inner
    for idx, label in enumerate(scene.controls):
        x = left + inner + idx * (col_w + gap)
        rounded_rect(draw, (x, y, x + col_w, y + button_h), 0, (15, 22, 36, 218), (255, 255, 255, 66), max(2, size[0] // 700))
        tw = draw.textbbox((0, 0), label, font=font_small)[2]
        draw.text((x + (col_w - tw) // 2, y + int(button_h * 0.26)), label, font=font_small, fill=(255, 255, 255, 238))
        chevron = "v"
        draw.text((x + col_w - int(size[0] * 0.052), y + int(button_h * 0.24)), chevron, font=font_small, fill=(255, 255, 255, 210))

    y += button_h + gap
    nav_labels = ("‹", "Ⅱ", "›")
    for idx, label in enumerate(nav_labels):
        x = left + inner + idx * (col_w + gap)
        rounded_rect(draw, (x, y, x + col_w, y + button_h), 0, (255, 255, 255, 30), (255, 255, 255, 62), max(2, size[0] // 700))
        tw = draw.textbbox((0, 0), label, font=font_small)[2]
        draw.text((x + (col_w - tw) // 2, y + int(button_h * 0.22)), label, font=font_small, fill=(255, 255, 255, 238))
    image.alpha_composite(overlay)


def render(size: tuple[int, int], scene_index: int) -> Image.Image:
    scene = SCENES[scene_index]
    image = cover(Image.open(BG / scene.category / scene.filename).convert("RGB"), size).convert("RGBA")

    overlay = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    draw.rectangle((0, 0, size[0], size[1]), fill=(3, 7, 17, 82))
    for x in range(size[0]):
        edge = abs((x / size[0]) - 0.5) * 2
        alpha = int(105 * edge)
        draw.line((x, 0, x, size[1]), fill=(0, 0, 0, alpha))
    for y in range(size[1]):
        top = max(0, 1 - y / (size[1] * 0.36))
        bottom = max(0, (y - size[1] * 0.66) / (size[1] * 0.34))
        alpha = int(128 * max(top, bottom))
        draw.line((0, y, size[0], y), fill=(0, 0, 0, alpha))
    image = Image.alpha_composite(image, overlay)

    grain = Image.new("RGBA", size, (0, 0, 0, 0))
    grain_draw = ImageDraw.Draw(grain)
    for y in range(0, size[1], 4):
        grain_draw.line((0, y, size[0], y), fill=(255, 255, 255, 10))
    image = Image.alpha_composite(image, grain)

    margin = int(size[0] * 0.055)
    draw = ImageDraw.Draw(image)
    draw_header(draw, size, scene, margin)
    draw_reader_panel(draw, image, size, scene, margin)
    draw_controls(image, size, scene, margin)

    return ImageEnhance.Sharpness(image.convert("RGB")).enhance(1.03)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for prefix, size in SIZES.items():
        for index in range(3):
            image = render(size, index)
            out = OUT / f"{prefix}_{index + 1:02d}.png"
            image.save(out, "PNG", optimize=True)
            print(out)


if __name__ == "__main__":
    main()
