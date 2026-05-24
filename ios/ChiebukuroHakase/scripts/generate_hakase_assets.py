from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageEnhance, ImageFilter


SOURCE = Path(r"C:\Users\Windows\Downloads\ChatGPT Image 2026年5月24日 10_34_31.png")
ROOT = Path(__file__).resolve().parents[1] / "ChiebukuroHakase" / "Assets.xcassets"
BACKGROUND = ROOT / "ChiebukuroBackground.imageset" / "chiebukuro-bg.png"
ICON = ROOT / "AppIcon.appiconset" / "Icon-1024.png"


def center_crop(image: Image.Image, size: int) -> Image.Image:
    width, height = image.size
    edge = min(width, height)
    left = (width - edge) // 2
    top = max(0, int((height - edge) * 0.32))
    return image.crop((left, top, left + edge, top + edge)).resize(
        (size, size),
        Image.Resampling.LANCZOS,
    )


def portrait_background(image: Image.Image) -> Image.Image:
    canvas_size = (1290, 2796)
    base = image.copy()
    scale = max(canvas_size[0] / base.width, canvas_size[1] / base.height)
    base = base.resize(
        (int(base.width * scale), int(base.height * scale)),
        Image.Resampling.LANCZOS,
    )
    left = (base.width - canvas_size[0]) // 2
    top = (base.height - canvas_size[1]) // 2
    base = base.crop((left, top, left + canvas_size[0], top + canvas_size[1]))
    base = base.filter(ImageFilter.GaussianBlur(18))
    base = ImageEnhance.Brightness(base).enhance(0.62)

    foreground = image.copy()
    fg_width = canvas_size[0]
    fg_height = int(foreground.height * (fg_width / foreground.width))
    foreground = foreground.resize((fg_width, fg_height), Image.Resampling.LANCZOS)

    result = base
    y = 360
    result.paste(foreground, (0, y))

    veil = Image.new("RGBA", canvas_size, (0, 0, 0, 0))
    for yy in range(canvas_size[1]):
        edge = min(yy / 620, (canvas_size[1] - yy) / 720, 1)
        alpha = int((1 - max(0, edge)) * 120)
        for xx in range(canvas_size[0]):
            veil.putpixel((xx, yy), (0, 0, 0, alpha))
    return Image.alpha_composite(result.convert("RGBA"), veil).convert("RGB")


def main() -> None:
    image = Image.open(SOURCE).convert("RGB")
    BACKGROUND.parent.mkdir(parents=True, exist_ok=True)
    ICON.parent.mkdir(parents=True, exist_ok=True)
    portrait_background(image).save(BACKGROUND, optimize=True)
    center_crop(image, 1024).save(ICON, optimize=True)
    print(f"background: {BACKGROUND}")
    print(f"icon: {ICON}")


if __name__ == "__main__":
    main()
