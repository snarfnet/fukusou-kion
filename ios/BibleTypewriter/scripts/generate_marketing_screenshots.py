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
        "Genesis",
        "1",
        "WEB",
        "A calm beginning",
        [
            ("1", "In the beginning God created the heavens and the earth."),
            ("2", "Now the earth was formless and empty. Darkness was on the surface of the deep."),
            ("3", "God said, Let there be light, and there was light."),
        ],
        ("WEB", "Genesis", "1"),
    ),
    Scene(
        "psalms",
        "chapter_bg_020.jpg",
        "Psalms",
        "23",
        "KJV",
        "Quiet words for prayer",
        [
            ("1", "The LORD is my shepherd; I shall not want."),
            ("2", "He maketh me to lie down in green pastures: he leadeth me beside the still waters."),
            ("3", "He restoreth my soul: he leadeth me in the paths of righteousness for his name's sake."),
        ],
        ("KJV", "Psalms", "23"),
    ),
    Scene(
        "gospels",
        "chapter_bg_047.jpg",
        "John",
        "1",
        "WEB",
        "WEB / KJV only",
        [
            ("1", "In the beginning was the Word, and the Word was with God, and the Word was God."),
            ("2", "The same was in the beginning with God."),
            ("3", "All things were made through him. Without him, nothing was made that has been made."),
        ],
        ("WEB", "John", "1"),
    ),
]


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    candidates = [
        "C:/Windows/Fonts/YuMincho.ttc",
        "C:/Windows/Fonts/YuGothB.ttc" if bold else "C:/Windows/Fonts/YuGothR.ttc",
        "C:/Windows/Fonts/meiryob.ttc" if bold else "C:/Windows/Fonts/meiryo.ttc",
        "/System/Library/Fonts/Helvetica.ttc",
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
    left = (w - size[0]) // 2
    top = (h - size[1]) // 2
    return image.crop((left, top, left + size[0], top + size[1]))


def rounded_rect(draw: ImageDraw.ImageDraw, box, fill, outline=None, radius=0, width=1):
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)


def draw_wrapped(draw: ImageDraw.ImageDraw, text: str, xy: tuple[int, int], max_width: int, font_obj, fill) -> int:
    x, y = xy
    line = ""
    for word in text.split(" "):
        candidate = f"{line} {word}".strip()
        if draw.textlength(candidate, font=font_obj) <= max_width:
            line = candidate
            continue
        if line:
            draw.text((x, y), line, font=font_obj, fill=fill)
            y += int(font_obj.size * 1.38)
        line = word
    if line:
        draw.text((x, y), line, font=font_obj, fill=fill)
        y += int(font_obj.size * 1.38)
    return y


def draw_scene(size_name: str, size: tuple[int, int], scene: Scene, index: int) -> None:
    bg_path = BG / scene.category / scene.filename
    base = cover(Image.open(bg_path).convert("RGB"), size)
    base = ImageEnhance.Brightness(base).enhance(0.72)
    blur = base.filter(ImageFilter.GaussianBlur(1.2))
    image = Image.blend(base, blur, 0.18).convert("RGBA")
    draw = ImageDraw.Draw(image)

    w, h = size
    margin = int(w * 0.07)
    top = int(h * 0.12)
    title_font = font(max(54, int(w * 0.060)), True)
    body_font = font(max(34, int(w * 0.036)), False)
    small_font = font(max(24, int(w * 0.024)), True)

    overlay = Image.new("RGBA", size, (0, 0, 0, 0))
    odraw = ImageDraw.Draw(overlay)
    odraw.rectangle((0, 0, w, h), fill=(0, 0, 0, 72))
    odraw.rectangle((0, int(h * 0.56), w, h), fill=(0, 0, 0, 92))
    image = Image.alpha_composite(image, overlay)
    draw = ImageDraw.Draw(image)

    draw.text((margin, top), "聖書のことば", font=font(max(30, int(w * 0.030)), True), fill=(255, 255, 255, 225))
    draw.text((margin, top + int(w * 0.07)), scene.meta, font=title_font, fill=(255, 255, 255, 255))
    draw.text((margin, top + int(w * 0.15)), f"{scene.translation} / {scene.book} {scene.chapter}", font=body_font, fill=(255, 255, 255, 220))

    panel_top = int(h * 0.60)
    rounded_rect(draw, (margin, panel_top, w - margin, int(h * 0.89)), fill=(0, 0, 0, 102), outline=(255, 255, 255, 42), radius=0)

    y = panel_top + int(w * 0.045)
    for verse, text in scene.verses:
        y = draw_wrapped(
            draw,
            f"[{verse}] {text}",
            (margin + 26, y),
            w - margin * 2 - 52,
            body_font,
            (255, 255, 255, 242),
        )
        y += int(body_font.size * 0.34)

    chip_y = int(h * 0.91)
    x = margin
    for item in scene.controls:
        tw = int(draw.textlength(item, font=small_font)) + 44
        rounded_rect(draw, (x, chip_y, x + tw, chip_y + 54), fill=(0, 0, 0, 128), outline=(255, 255, 255, 58), radius=0)
        draw.text((x + 22, chip_y + 13), item, font=small_font, fill=(255, 255, 255, 235))
        x += tw + 14

    folder = OUT / size_name
    folder.mkdir(parents=True, exist_ok=True)
    image.convert("RGB").save(folder / f"{size_name}_{index:02d}.png", optimize=True)


def main() -> None:
    for size_name, size in SIZES.items():
        for index, scene in enumerate(SCENES, start=1):
            draw_scene(size_name, size, scene, index)


if __name__ == "__main__":
    main()
