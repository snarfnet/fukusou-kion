#!/usr/bin/env python3
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


OUT = Path("MarketingAssets/Screenshots")
SIZES = {
    "iphone69": (1290, 2796),
    "iphone65": (1242, 2688),
    "iphone55": (1242, 2208),
    "ipad129": (2048, 2732),
}

STATES = [
    {"seed": "48391", "zoom": "100%", "birds": False, "image": False, "format": "SVG", "message": "Ready"},
    {"seed": "82514", "zoom": "125%", "birds": True, "image": False, "format": "SVG", "message": "Generated seed 82514"},
    {"seed": "61972", "zoom": "100%", "birds": True, "image": True, "format": "SVG", "message": "Image motif active: 12 placements in seed 61972"},
    {"seed": "27438", "zoom": "175%", "birds": True, "image": True, "format": "DST", "message": "Choose a Files folder for flora-stitch-27438.dst."},
    {"seed": "93027", "zoom": "500%", "birds": True, "image": False, "format": "PES", "message": "Generated seed 93027"},
]


def font(size, bold=False, serif=False):
    candidates = [
        "C:/Windows/Fonts/YuGothB.ttc" if bold else "C:/Windows/Fonts/YuGothM.ttc",
        "C:/Windows/Fonts/segoeuib.ttf" if bold else "C:/Windows/Fonts/segoeui.ttf",
        "/System/Library/Fonts/NewYork.ttf" if serif else "/System/Library/Fonts/Helvetica.ttc",
    ]
    for path in candidates:
        try:
            return ImageFont.truetype(path, size)
        except Exception:
            pass
    return ImageFont.load_default()


def rounded(draw, box, radius, fill, outline=None, width=1):
    draw.rounded_rectangle(tuple(int(v) for v in box), radius=int(radius), fill=fill, outline=outline, width=width)


def text(draw, xy, value, size, fill="#2b2922", bold=False, serif=False, anchor=None):
    draw.text(xy, value, font=font(size, bold, serif), fill=fill, anchor=anchor)


def draw_app_screen(size, state, slide):
    w, h = size
    s = w / 1290
    img = Image.new("RGB", size, "#F5F1EA")
    draw = ImageDraw.Draw(img)

    status_h = int(62 * s)
    nav_h = int(96 * s)
    pad = int(34 * s)
    content_w = w - pad * 2

    draw.rectangle((0, 0, w, status_h + nav_h), fill="#F9F7F2")
    text(draw, (pad, int(30 * s)), "9:41", int(26 * s), bold=True)
    text(draw, (w - pad, int(30 * s)), "5G  100%", int(24 * s), anchor="ra")
    text(draw, (w / 2, status_h + int(48 * s)), "Flora Stitch", int(34 * s), bold=True, anchor="mm")
    text(draw, (w - pad, status_h + int(50 * s)), "Dice", int(22 * s), bold=True, anchor="rm")

    y = status_h + nav_h + int(26 * s)
    text(draw, (pad, y), "Random floral borders for embroidery", int(42 * s), bold=True, serif=True)
    y += int(56 * s)
    desc = "Create original vine, leaf, flower, berry, fruit, and curl patterns from a seed."
    text(draw, (pad, y), desc, int(24 * s), fill="#6E695F")
    y += int(44 * s)

    preview_h = int((520 if h > 2400 else 430) * s)
    rounded(draw, (pad, y, w - pad, y + preview_h), int(16 * s), "#FFFFFF", "#D8D0C3", max(2, int(2 * s)))
    draw_pattern(draw, (pad + int(36 * s), y + int(40 * s), w - pad - int(36 * s), y + preview_h - int(40 * s)), s, state, slide)
    y += preview_h + int(22 * s)

    draw_zoom_controls(draw, pad, y, content_w, s, state["zoom"])
    y += int(72 * s)

    draw_stats(draw, pad, y, content_w, s, state)
    y += int(86 * s)

    panel_h = h - y - int(38 * s)
    rounded(draw, (pad, y, w - pad, y + panel_h), int(10 * s), "#FFFFFF", "#D8D0C3", max(2, int(2 * s)))
    draw_controls(draw, pad + int(28 * s), y + int(28 * s), content_w - int(56 * s), s, state, panel_h)
    return img


def draw_pattern(draw, box, s, state, slide):
    x0, y0, x1, y1 = box
    w = x1 - x0
    h = y1 - y0
    mid = y0 + h * (0.55 if state["zoom"] != "500%" else 0.48)
    pts = []
    for i in range(120):
        t = i / 119
        x = x0 + w * t
        y = mid + math.sin(t * (7.2 + slide)) * 36 * s
        pts.append((x, y))
    draw.line(pts, fill="#657B45", width=max(4, int(5 * s)), joint="curve")

    for i, (x, y) in enumerate(pts[6::9]):
        side = -1 if i % 2 else 1
        draw.ellipse((x - 18 * s, y + side * 20 * s - 36 * s, x + 18 * s, y + side * 20 * s + 36 * s), fill="#8DAC64", outline="#3A3328", width=max(1, int(2 * s)))
    colors = ["#C95F7C", "#E4BF50", "#78A9C8", "#D78A48"]
    for i, (x, y) in enumerate(pts[10::14]):
        color = colors[(i + slide) % len(colors)]
        cy = y - 55 * s
        for p in range(6):
            a = p / 6 * math.tau
            cx = x + math.cos(a) * 26 * s
            py = cy + math.sin(a) * 26 * s
            draw.ellipse((cx - 13 * s, py - 18 * s, cx + 13 * s, py + 18 * s), fill=color, outline="#3A3328", width=max(1, int(1 * s)))
        draw.ellipse((x - 10 * s, cy - 10 * s, x + 10 * s, cy + 10 * s), fill="#725332")
    for i, (x, y) in enumerate(pts[18::18]):
        draw.ellipse((x - 10 * s, y + 34 * s, x + 10 * s, y + 54 * s), fill="#8D4D50", outline="#3A3328")
        draw.ellipse((x + 12 * s, y + 30 * s, x + 32 * s, y + 50 * s), fill="#AD6255", outline="#3A3328")

    if state["image"]:
        for i in range(5):
            x = x0 + w * (0.18 + i * 0.15)
            y = y0 + h * 0.74 + math.sin(i) * 12 * s
            rounded(draw, (x - 22 * s, y - 22 * s, x + 22 * s, y + 22 * s), int(6 * s), ["#E4B2A0", "#A8C8A0", "#7EA6BC"][i % 3], "#3A3328")

    if state["birds"]:
        for i, x in enumerate([x0 + w * 0.25, x0 + w * 0.68]):
            y = y0 + h * (0.26 + i * 0.08)
            draw_bird(draw, x, y, s * 1.15, "#32302A")


def draw_bird(draw, x, y, s, color):
    pts = [(x - 42 * s, y + 6 * s), (x - 14 * s, y - 14 * s), (x + 22 * s, y - 12 * s), (x + 42 * s, y + 2 * s), (x + 22 * s, y + 16 * s), (x - 14 * s, y + 14 * s), (x - 42 * s, y + 6 * s)]
    draw.line(pts, fill=color, width=max(2, int(3 * s)), joint="curve")
    draw.line((x - 8 * s, y - 8 * s, x + 8 * s, y - 42 * s, x + 20 * s, y - 10 * s), fill=color, width=max(2, int(3 * s)))
    draw.line((x - 15 * s, y + 12 * s, x - 30 * s, y + 36 * s), fill=color, width=max(2, int(3 * s)))


def draw_zoom_controls(draw, x, y, width, s, zoom):
    group_w = int(350 * s)
    start = x + (width - group_w) / 2
    for i, label in enumerate(["-", zoom, "+", "R"]):
        bx = start + i * int(86 * s)
        fill = "#FFFFFF" if i != 1 else "#F5F1EA"
        rounded(draw, (bx, y, bx + int(68 * s), y + int(50 * s)), int(8 * s), fill, "#CFC7B9")
        text(draw, (bx + int(34 * s), y + int(25 * s)), label, int(24 * s), fill="#5E5A50", bold=i == 1, anchor="mm")


def draw_stats(draw, x, y, width, s, state):
    values = [("Seed", state["seed"]), ("Stitches", "4,812"), ("Colors", "8")]
    gap = int(10 * s)
    pill_w = (width - gap * 2) / 3
    for i, (title, value) in enumerate(values):
        bx = x + i * (pill_w + gap)
        rounded(draw, (bx, y, bx + pill_w, y + int(62 * s)), int(10 * s), "#FFFFFF", "#D8D0C3")
        text(draw, (bx + int(16 * s), y + int(17 * s)), title, int(18 * s), fill="#7A756C")
        text(draw, (bx + pill_w - int(16 * s), y + int(35 * s)), value, int(22 * s), bold=True, anchor="rm")


def draw_controls(draw, x, y, width, s, state, panel_h):
    row_h = int(58 * s)
    text(draw, (x, y + int(28 * s)), "Seed", int(25 * s), bold=True)
    rounded(draw, (x + width - int(190 * s), y, x + width, y + row_h), int(8 * s), "#F7F7F7", "#D1D1D1")
    text(draw, (x + width - int(20 * s), y + row_h / 2), state["seed"], int(24 * s), anchor="rm")
    y += int(76 * s)

    button(draw, x, y, width, row_h, "Dice  New random seed", "#6E8249", "#FFFFFF", s)
    y += int(74 * s)
    button(draw, x, y, width, row_h, "Photo  " + ("Replace image motif" if state["image"] else "Import image motif"), "#FFFFFF", "#2E2B25", s, outline="#CFC7B9")
    y += int(70 * s)
    if state["image"]:
        text(draw, (x, y + int(20 * s)), "Active  Image motif is active", int(21 * s), fill="#5D763D", bold=True)
        y += int(54 * s)

    draw_toggle(draw, x, y, width, s, "Birds", state["birds"])
    y += int(74 * s)
    draw_slider(draw, x, y, width, s, "Density", 0.72)
    y += int(72 * s)
    draw_slider(draw, x, y, width, s, "Branch curl", 0.58)
    y += int(88 * s)

    draw_segmented(draw, x, y, width, s, state["format"])
    y += int(74 * s)
    button(draw, x, y, width, row_h, f"File  Save {state['format']}", "#C35F7A", "#FFFFFF", s)
    y += int(74 * s)
    if y < panel_h:
        text(draw, (x, y + int(18 * s)), state["message"], int(20 * s), fill="#716B61")


def button(draw, x, y, width, height, label, fill, fg, s, outline=None):
    rounded(draw, (x, y, x + width, y + height), int(9 * s), fill, outline)
    text(draw, (x + width / 2, y + height / 2), label, int(23 * s), fill=fg, bold=True, anchor="mm")


def draw_toggle(draw, x, y, width, s, label, on):
    text(draw, (x, y + int(24 * s)), label, int(23 * s), bold=True)
    tx = x + width - int(78 * s)
    rounded(draw, (tx, y + int(5 * s), tx + int(76 * s), y + int(43 * s)), int(20 * s), "#6E8249" if on else "#D7D2C8")
    knob_x = tx + (int(42 * s) if on else int(4 * s))
    draw.ellipse((knob_x, y + int(8 * s), knob_x + int(32 * s), y + int(40 * s)), fill="#FFFFFF")


def draw_slider(draw, x, y, width, s, label, value):
    text(draw, (x, y), label, int(21 * s), fill="#5F5A50", bold=True)
    line_y = y + int(36 * s)
    draw.line((x, line_y, x + width, line_y), fill="#D8D0C3", width=max(3, int(4 * s)))
    draw.line((x, line_y, x + width * value, line_y), fill="#6E8249", width=max(3, int(4 * s)))
    draw.ellipse((x + width * value - 12 * s, line_y - 12 * s, x + width * value + 12 * s, line_y + 12 * s), fill="#FFFFFF", outline="#6E8249", width=max(2, int(2 * s)))


def draw_segmented(draw, x, y, width, s, selected):
    seg_w = width / 3
    rounded(draw, (x, y, x + width, y + int(54 * s)), int(9 * s), "#F5F1EA", "#D8D0C3")
    for i, label in enumerate(["SVG", "DST", "PES"]):
        bx = x + seg_w * i
        if label == selected:
            rounded(draw, (bx + int(4 * s), y + int(4 * s), bx + seg_w - int(4 * s), y + int(50 * s)), int(7 * s), "#FFFFFF")
        text(draw, (bx + seg_w / 2, y + int(27 * s)), label, int(22 * s), bold=True, anchor="mm")


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for device, size in SIZES.items():
        for index, state in enumerate(STATES, start=1):
            draw_app_screen(size, state, index).save(OUT / f"{device}_{index:02d}.png")


if __name__ == "__main__":
    main()
