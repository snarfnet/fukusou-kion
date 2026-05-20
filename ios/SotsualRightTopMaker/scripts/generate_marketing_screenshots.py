from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[3]
APP_ROOT = ROOT / "ios" / "SotsualRightTopMaker"
OUT = APP_ROOT / "MarketingAssets" / "Screenshots"
ASSETS = APP_ROOT / "SotsualRightTopMaker" / "Assets.xcassets"

OUT.mkdir(parents=True, exist_ok=True)

STANDARD = ASSETS / "template_standard_graduation.imageset" / "template_standard_graduation.png"
TRIP = ASSETS / "template_school_trip.imageset" / "template_school_trip.png"
POSTWAR = ASSETS / "template_postwar.imageset" / "template_postwar.png"

SANS = Path("C:/Windows/Fonts/NotoSansJP-VF.ttf")
SANS_BOLD = Path("C:/Windows/Fonts/BIZ-UDGothicB.ttc")
SERIF = Path("C:/Windows/Fonts/BIZ-UDMinchoM.ttc")


def font(size, serif=False, bold=False):
    path = SERIF if serif else (SANS_BOLD if bold else SANS)
    if path.exists():
        return ImageFont.truetype(str(path), size)
    return ImageFont.truetype("C:/Windows/Fonts/meiryo.ttc", size)


def cover_resize(image, size):
    width, height = image.size
    target_width, target_height = size
    scale = max(target_width / width, target_height / height)
    next_size = (int(width * scale), int(height * scale))
    image = image.resize(next_size, Image.Resampling.LANCZOS)
    left = (next_size[0] - target_width) // 2
    top = (next_size[1] - target_height) // 2
    return image.crop((left, top, left + target_width, top + target_height))


def contain_resize(image, box):
    width, height = image.size
    target_width, target_height = box
    scale = min(target_width / width, target_height / height)
    return image.resize((int(width * scale), int(height * scale)), Image.Resampling.LANCZOS)


def draw_center(draw, y, text, text_font, fill, width):
    bbox = draw.textbbox((0, 0), text, font=text_font)
    draw.text(((width - (bbox[2] - bbox[0])) / 2, y), text, font=text_font, fill=fill)


def draw_multiline_center(draw, y, lines, text_font, fill, width, gap):
    for line in lines:
        bbox = draw.textbbox((0, 0), line, font=text_font)
        draw.text(((width - (bbox[2] - bbox[0])) / 2, y), line, font=text_font, fill=fill)
        y += bbox[3] - bbox[1] + gap


def rounded_paste(base, image, xy, radius):
    x, y = xy
    mask = Image.new("L", image.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, image.size[0] - 1, image.size[1] - 1),
        radius=radius,
        fill=255,
    )
    shadow_mask = mask.filter(ImageFilter.GaussianBlur(18))
    base.paste(Image.new("RGBA", image.size, (0, 0, 0, 70)), (x, y + 18), shadow_mask)
    base.paste(image.convert("RGBA"), xy, mask)


def app_frame(template_path, canvas_width, photo_height, mode="normal"):
    photo = cover_resize(Image.open(template_path).convert("RGB"), (canvas_width, photo_height))
    band_height = max(230, int(photo_height * 0.25))
    frame = Image.new("RGBA", (canvas_width, photo_height + band_height), (255, 255, 255, 255))
    frame.alpha_composite(photo.convert("RGBA"), (0, 0))
    draw = ImageDraw.Draw(frame)
    draw.rectangle((0, photo_height, canvas_width, photo_height + band_height), fill=(255, 255, 255, 255))

    if mode == "postwar":
        title = "昭和24年度　卒業記念写真"
        subtitle = "〇〇町立〇〇中学校　第3学年"
    else:
        title = "令和6年度　卒業記念"
        subtitle = "〇〇市立〇〇中学校　3年B組"

    draw_center(
        draw,
        photo_height + int(band_height * 0.16),
        title,
        font(max(52, int(canvas_width * 0.055)), serif=True),
        (20, 20, 20),
        canvas_width,
    )
    draw_center(
        draw,
        photo_height + int(band_height * 0.56),
        subtitle,
        font(max(42, int(canvas_width * 0.042)), serif=True),
        (20, 20, 20),
        canvas_width,
    )
    return frame


def make_device(size, filename, template_path, headline, sublines, mode="normal"):
    width, height = size
    background = Image.new("RGBA", (width, height), (248, 247, 242, 255))
    draw = ImageDraw.Draw(background)

    top = int(height * 0.055)
    draw_center(
        draw,
        top,
        "卒アル右上メーカー",
        font(int(width * 0.067), serif=True),
        (35, 31, 25),
        width,
    )
    draw_multiline_center(
        draw,
        top + int(width * 0.11),
        sublines,
        font(int(width * 0.034)),
        (84, 76, 64),
        width,
        int(width * 0.014),
    )

    photo_width = int(width * 0.86)
    raw = app_frame(template_path, photo_width, int(photo_width * 0.70), mode=mode)
    preview = contain_resize(raw, (photo_width, int(height * 0.63)))
    rounded_paste(
        background,
        preview,
        ((width - preview.size[0]) // 2, int(height * 0.30)),
        radius=int(width * 0.025),
    )

    draw = ImageDraw.Draw(background)
    pill_width = int(width * 0.48)
    pill_height = int(width * 0.085)
    pill_x = (width - pill_width) // 2
    pill_y = height - int(width * 0.18)
    draw.rounded_rectangle(
        (pill_x, pill_y, pill_x + pill_width, pill_y + pill_height),
        radius=pill_height // 2,
        fill=(43, 39, 33),
    )
    draw_center(
        draw,
        pill_y + int(pill_height * 0.15),
        headline,
        font(int(width * 0.03), bold=True),
        (255, 255, 255),
        width,
    )
    background.convert("RGB").save(OUT / filename, quality=95)


def main():
    for size, prefix in [((1290, 2796), "iphone67"), ((2048, 2732), "ipad129")]:
        make_device(
            size,
            f"{prefix}_01_home.png",
            STANDARD,
            "すぐ作れる",
            ["集合写真に、あの右上の丸を。", "テンプレートを選んで卒アル風に。"],
        )
        make_device(
            size,
            f"{prefix}_02_editor.png",
            TRIP,
            "端末内で保存",
            ["顔写真を丸く切り抜き、位置とサイズを調整。", "写真はサーバーへ送りません。"],
        )
        make_device(
            size,
            f"{prefix}_03_templates.png",
            POSTWAR,
            "テンプレート追加対応",
            ["標準、修学旅行、古写真風。", "行事パックでさらに楽しく。"],
            mode="postwar",
        )

    for screenshot in sorted(OUT.glob("*.png")):
        print(f"{screenshot.name}: {Image.open(screenshot).size}")


if __name__ == "__main__":
    main()
