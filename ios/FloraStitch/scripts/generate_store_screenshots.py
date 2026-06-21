#!/usr/bin/env python3
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


OUT = Path("MarketingAssets/Screenshots")
SIZES = {
    "iphone69": (1290, 2796),
    "iphone65": (1242, 2688),
    "iphone55": (1242, 2208),
    "ipad129": (2048, 2732),
}
SLIDES = [
    ("Flora Stitch", "Random floral vector borders", "Generate flowers, vines, berries, curls, and tiny birds from a seed."),
    ("Import Photos", "Turn images into vector tiles", "Bring a photo into the design and export it as SVG-friendly colored shapes."),
    ("Embroidery Export", "Save SVG, DST, or PES", "Create files for design review and machine test workflows."),
    ("Seed Variations", "Endless garden patterns", "Tap the seed button to create a new ornamental border."),
    ("Zoom Preview", "Inspect every stitch", "Zoom up to 500% and drag around the canvas."),
]


def font(size, bold=False):
    candidates = [
        "C:/Windows/Fonts/YuGothB.ttc" if bold else "C:/Windows/Fonts/YuGothM.ttc",
        "C:/Windows/Fonts/segoeuib.ttf" if bold else "C:/Windows/Fonts/segoeui.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
    ]
    for path in candidates:
        try:
            return ImageFont.truetype(path, size)
        except Exception:
            pass
    return ImageFont.load_default()


def wrap(draw, text, font_obj, max_width):
    words = text.split()
    lines = []
    current = ""
    for word in words:
        trial = f"{current} {word}".strip()
        if draw.textbbox((0, 0), trial, font=font_obj)[2] <= max_width:
            current = trial
        else:
            if current:
                lines.append(current)
            current = word
    if current:
        lines.append(current)
    return lines


def draw_pattern(draw, box, scale):
    x0, y0, x1, y1 = box
    w = x1 - x0
    h = y1 - y0
    mid = y0 + h * 0.58
    green = "#5F743F"
    rose = "#CE6784"
    yellow = "#E8C85A"
    blue = "#77A9C8"
    ink = "#3A3328"
    points = []
    for index in range(80):
        t = index / 79
        x = x0 + 50 * scale + (w - 100 * scale) * t
        y = mid + 45 * scale * __import__("math").sin(t * 7.4)
        points.append((x, y))
    draw.line(points, fill=green, width=max(4, int(5 * scale)), joint="curve")
    for i, (x, y) in enumerate(points[4::7]):
        side = -1 if i % 2 else 1
        draw.ellipse((x - 24 * scale, y + side * 16 * scale - 46 * scale, x + 24 * scale, y + side * 16 * scale + 46 * scale), fill="#89A861", outline=ink, width=max(1, int(2 * scale)))
    for i, (x, y) in enumerate(points[8::12]):
        color = [rose, yellow, blue][i % 3]
        for p in range(7):
            import math
            a = p / 7 * math.pi * 2
            cx = x + math.cos(a) * 28 * scale
            cy = y - 55 * scale + math.sin(a) * 28 * scale
            draw.ellipse((cx - 16 * scale, cy - 20 * scale, cx + 16 * scale, cy + 20 * scale), fill=color, outline=ink, width=max(1, int(1.5 * scale)))
        draw.ellipse((x - 12 * scale, y - 67 * scale, x + 12 * scale, y - 43 * scale), fill="#7B5B35")
    for i, (x, y) in enumerate(points[15::18]):
        draw.arc((x - 45 * scale, y - 95 * scale, x + 45 * scale, y - 5 * scale), 205, 345, fill=ink, width=max(2, int(3 * scale)))
        draw.line((x + 34 * scale, y - 48 * scale, x + 60 * scale, y - 52 * scale), fill=ink, width=max(2, int(3 * scale)))


def make(device, size, slide_index, title, subtitle, body):
    w, h = size
    scale = w / 1290
    img = Image.new("RGB", size, "#F7F4EF")
    draw = ImageDraw.Draw(img)
    pad = int(86 * scale)
    title_font = font(int(82 * scale), True)
    subtitle_font = font(int(48 * scale), True)
    body_font = font(int(34 * scale), False)
    small_font = font(int(28 * scale), True)

    draw.text((pad, int(120 * scale)), title, fill="#27241E", font=title_font)
    draw.text((pad, int(235 * scale)), subtitle, fill="#62733A", font=subtitle_font)
    y = int(310 * scale)
    for line in wrap(draw, body, body_font, w - pad * 2):
        draw.text((pad, y), line, fill="#766F63", font=body_font)
        y += int(46 * scale)

    card = (pad, int(h * 0.38), w - pad, int(h * 0.77))
    draw.rounded_rectangle(card, radius=int(24 * scale), fill="#FFFFFF", outline="#DDD5C7", width=max(2, int(3 * scale)))
    draw_pattern(draw, (card[0] + 30 * scale, card[1] + 40 * scale, card[2] - 30 * scale, card[3] - 40 * scale), scale)

    draw.rounded_rectangle((pad, int(h * 0.82), w - pad, int(h * 0.9)), radius=int(18 * scale), fill="#27241E")
    draw.text((pad + 34 * scale, int(h * 0.842)), f"{slide_index + 1}/5  SVG  DST  PES", fill="#F5E8C5", font=small_font)
    return img


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for device, size in SIZES.items():
        for index, (title, subtitle, body) in enumerate(SLIDES, start=1):
            image = make(device, size, index - 1, title, subtitle, body)
            image.save(OUT / f"{device}_{index:02d}.png")


if __name__ == "__main__":
    main()
