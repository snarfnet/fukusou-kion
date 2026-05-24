from __future__ import annotations

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

SCENES = [
    ("genesis", "chapter_bg_001.jpg", "静かな背景に、聖書のことばが一文字ずつ流れます。", "創世記 1 / 口語訳", "はじめに神は天と地とを創造された。"),
    ("psalms", "chapter_bg_020.jpg", "口語訳、WEB、KJVを切り替えて読めます。", "詩篇 23 / 口語訳", "主はわたしの牧者であって、わたしには乏しいことがない。"),
    ("gospels", "chapter_bg_047.jpg", "章が終わると、ひと呼吸して次の章へ進みます。", "ヨハネによる福音書 1 / 口語訳", "初めに言があった。言は神と共にあった。"),
]


def font(size: int, bold: bool = False):
    candidates = [
        "C:/Windows/Fonts/YuGothB.ttc" if bold else "C:/Windows/Fonts/YuGothR.ttc",
        "C:/Windows/Fonts/meiryo.ttc",
        "C:/Windows/Fonts/msgothic.ttc",
    ]
    for candidate in candidates:
        if Path(candidate).exists():
            return ImageFont.truetype(candidate, size)
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


def draw_wrapped(draw: ImageDraw.ImageDraw, text: str, xy, max_width: int, fnt, fill, spacing: int = 10):
    words = list(text)
    lines: list[str] = []
    line = ""
    for char in words:
        test = line + char
        if draw.textbbox((0, 0), test, font=fnt)[2] <= max_width or not line:
            line = test
        else:
            lines.append(line)
            line = char
    if line:
        lines.append(line)
    x, y = xy
    for line in lines:
        draw.text((x, y), line, font=fnt, fill=fill)
        y += draw.textbbox((0, 0), line, font=fnt)[3] + spacing


def render(size: tuple[int, int], scene_index: int) -> Image.Image:
    category, filename, headline, reference, verse = SCENES[scene_index]
    image = cover(Image.open(BG / category / filename).convert("RGB"), size).convert("RGBA")

    veil = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(veil)
    d.rectangle((0, 0, size[0], size[1]), fill=(2, 6, 14, 78))
    image = Image.alpha_composite(image, veil)

    margin = int(size[0] * 0.07)
    title_font = font(int(size[0] * 0.074), True)
    sub_font = font(int(size[0] * 0.034), False)
    ref_font = font(int(size[0] * 0.032), False)
    verse_font = font(int(size[0] * 0.050), True)

    d = ImageDraw.Draw(image)
    d.text((margin, int(size[1] * 0.055)), "聖書のことば", font=title_font, fill=(255, 255, 255, 245))
    draw_wrapped(d, headline, (margin, int(size[1] * 0.145)), size[0] - margin * 2, sub_font, (255, 255, 255, 205), spacing=int(size[0] * 0.014))

    panel_top = int(size[1] * 0.34)
    panel_bottom = int(size[1] * 0.76)
    panel = Image.new("RGBA", (size[0] - margin * 2, panel_bottom - panel_top), (8, 13, 25, 90))
    panel = panel.filter(ImageFilter.GaussianBlur(0.2))
    image.alpha_composite(panel, (margin, panel_top))
    d.rectangle((margin, panel_top, size[0] - margin, panel_bottom), outline=(255, 255, 255, 54), width=max(2, size[0] // 620))

    d.text((margin + int(size[0] * 0.05), panel_top + int(size[0] * 0.055)), reference, font=ref_font, fill=(255, 255, 255, 200))
    d.text((margin + int(size[0] * 0.05), panel_top + int(size[0] * 0.15)), verse, font=verse_font, fill=(255, 255, 255, 245))
    d.text((margin + int(size[0] * 0.05), panel_top + int(size[0] * 0.25)), "｜", font=verse_font, fill=(255, 255, 255, 190))

    return ImageEnhance.Sharpness(image.convert("RGB")).enhance(1.02)


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
