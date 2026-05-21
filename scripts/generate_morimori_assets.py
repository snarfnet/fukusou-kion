from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "assets" / "morimori-photo-maker"
OUT_DIR.mkdir(parents=True, exist_ok=True)


def lerp(a: int, b: int, t: float) -> int:
    return int(a + (b - a) * t)


def gradient_frame(width: int, height: int, frame: int, total: int) -> Image.Image:
    phase = frame / total
    colors = [
        (255, 38, 130),
        (255, 221, 50),
        (32, 213, 255),
        (255, 94, 214),
    ]
    img = Image.new("RGB", (width, height))
    pix = img.load()
    for y in range(height):
        ty = y / max(1, height - 1)
        wave = (math.sin((ty * 5.4 + phase * 2.0) * math.tau) + 1) / 2
        c1 = colors[int((phase * 3) % len(colors))]
        c2 = colors[(int((phase * 3) + 1) % len(colors))]
        c3 = colors[(int((phase * 3) + 2) % len(colors))]
        mix = tuple(lerp(lerp(c1[i], c2[i], ty), c3[i], wave * 0.35) for i in range(3))
        for x in range(width):
            tx = x / max(1, width - 1)
            pulse = (math.sin((tx * 4.5 - phase * 3.2) * math.tau) + 1) / 2
            pix[x, y] = tuple(min(255, int(mix[i] + pulse * 42)) for i in range(3))
    return img


def star_points(cx: float, cy: float, outer: float, inner: float, points: int = 4):
    pts = []
    for i in range(points * 2):
        angle = -math.pi / 2 + i * math.pi / points
        radius = outer if i % 2 == 0 else inner
        pts.append((cx + math.cos(angle) * radius, cy + math.sin(angle) * radius))
    return pts


def make_kirakira_gif() -> None:
    width, height = 720, 960
    total = 30
    rng = random.Random(20260521)
    particles = [
        {
            "x": rng.random(),
            "y": rng.random(),
            "size": rng.uniform(5, 24),
            "speed": rng.uniform(0.15, 0.75),
            "phase": rng.random(),
            "kind": rng.choice(["star", "dot", "heart"]),
        }
        for _ in range(110)
    ]
    frames = []
    for frame in range(total):
        base = gradient_frame(width, height, frame, total).convert("RGBA")
        glow = Image.new("RGBA", (width, height), (0, 0, 0, 0))
        draw = ImageDraw.Draw(glow)
        phase = frame / total

        for r in range(90, 900, 125):
            alpha = 54 if r % 250 else 82
            draw.ellipse(
                (width / 2 - r, height / 2 - r, width / 2 + r, height / 2 + r),
                outline=(255, 255, 255, alpha),
                width=4,
            )

        for p in particles:
            x = (p["x"] + phase * p["speed"]) % 1.0
            y = (p["y"] + math.sin((phase + p["phase"]) * math.tau) * 0.04) % 1.0
            size = p["size"] * (0.65 + 0.55 * math.sin((phase * 2.5 + p["phase"]) * math.tau))
            cx, cy = x * width, y * height
            alpha = int(120 + 120 * abs(math.sin((phase * 3 + p["phase"]) * math.tau)))
            color = rng.choice(
                [
                    (255, 255, 255, alpha),
                    (255, 244, 90, alpha),
                    (255, 72, 170, alpha),
                    (0, 232, 255, alpha),
                ]
            )
            if p["kind"] == "star":
                draw.polygon(star_points(cx, cy, size, size * 0.25), fill=color)
                draw.line((cx - size * 1.8, cy, cx + size * 1.8, cy), fill=color, width=2)
                draw.line((cx, cy - size * 1.8, cx, cy + size * 1.8), fill=color, width=2)
            elif p["kind"] == "heart":
                draw.ellipse((cx - size, cy - size, cx, cy), fill=color)
                draw.ellipse((cx, cy - size, cx + size, cy), fill=color)
                draw.polygon([(cx - size, cy - size * 0.2), (cx + size, cy - size * 0.2), (cx, cy + size * 1.2)], fill=color)
            else:
                draw.ellipse((cx - size, cy - size, cx + size, cy + size), fill=color)

        glow = glow.filter(ImageFilter.GaussianBlur(0.45))
        base.alpha_composite(glow)
        frames.append(base.convert("P", palette=Image.Palette.ADAPTIVE, colors=128))

    frames[0].save(
        OUT_DIR / "kirakira-max-bg.gif",
        save_all=True,
        append_images=frames[1:],
        duration=70,
        loop=0,
        optimize=True,
        disposal=2,
    )


def make_kirakira_pop_gif() -> None:
    width, height = 720, 960
    total = 28
    rng = random.Random(20260522)
    frames = []
    for frame in range(total):
        phase = frame / total
        base = Image.new("RGBA", (width, height), (255, 82, 168, 255))
        draw = ImageDraw.Draw(base)

        for y in range(0, height, 42):
            offset = int((phase * 120 + y * 0.35) % 84)
            draw.rectangle((-offset, y, width - offset, y + 18), fill=(255, 237, 62, 210))
            draw.rectangle((width - offset, y, width * 2 - offset, y + 18), fill=(255, 237, 62, 210))

        glow = Image.new("RGBA", (width, height), (0, 0, 0, 0))
        g = ImageDraw.Draw(glow)
        for i in range(80):
            angle = i * 0.618 + phase * math.tau * 1.6
            radius = 40 + (i * 19 + frame * 18) % 620
            cx = width / 2 + math.cos(angle) * radius
            cy = height / 2 + math.sin(angle) * radius * 1.18
            size = 8 + (i % 7) * 3
            alpha = 110 + int(120 * abs(math.sin(phase * math.tau * 2 + i)))
            color = rng.choice(
                [
                    (255, 255, 255, alpha),
                    (0, 232, 255, alpha),
                    (255, 52, 196, alpha),
                    (255, 218, 50, alpha),
                ]
            )
            g.polygon(star_points(cx, cy, size, size * 0.25), fill=color)

        for i in range(18):
            cx = (i * 97 + frame * 31) % (width + 120) - 60
            cy = (i * 151 + frame * 23) % (height + 120) - 60
            r = 18 + (i % 4) * 9
            g.ellipse((cx - r, cy - r, cx + r, cy + r), outline=(255, 255, 255, 155), width=4)

        base.alpha_composite(glow.filter(ImageFilter.GaussianBlur(0.35)))
        frames.append(base.convert("P", palette=Image.Palette.ADAPTIVE, colors=128))

    frames[0].save(
        OUT_DIR / "kirakira-pop-bg.gif",
        save_all=True,
        append_images=frames[1:],
        duration=70,
        loop=0,
        optimize=True,
        disposal=2,
    )


if __name__ == "__main__":
    make_kirakira_gif()
    make_kirakira_pop_gif()
    print(OUT_DIR / "kirakira-max-bg.gif")
    print(OUT_DIR / "kirakira-pop-bg.gif")
