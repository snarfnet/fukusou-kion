from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[3]
APP_ROOT = ROOT / "ios" / "SotsualRightTopMaker"
OUT = APP_ROOT / "MarketingAssets" / "Screenshots"
IAP_OUT = APP_ROOT / "MarketingAssets" / "IAPReview"
ASSETS = APP_ROOT / "SotsualRightTopMaker" / "Assets.xcassets"

OUT.mkdir(parents=True, exist_ok=True)
IAP_OUT.mkdir(parents=True, exist_ok=True)

STANDARD = ASSETS / "template_standard_graduation.imageset" / "template_standard_graduation.png"
TRIP = ASSETS / "template_school_trip.imageset" / "template_school_trip.png"
CULTURE = ASSETS / "template_culture_festival.imageset" / "template_culture_festival.png"
MEIJI = ASSETS / "template_meiji_restoration.imageset" / "template_meiji_restoration.png"

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


def draw_center(draw, y, text, text_font, fill, width):
    bbox = draw.textbbox((0, 0), text, font=text_font)
    draw.text(((width - (bbox[2] - bbox[0])) / 2, y), text, font=text_font, fill=fill)


def rounded_mask(size, radius):
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, size[0] - 1, size[1] - 1), radius=radius, fill=255)
    return mask


def rounded_paste(base, image, xy, radius, shadow=False):
    x, y = xy
    mask = rounded_mask(image.size, radius)
    if shadow:
        shadow_mask = mask.filter(ImageFilter.GaussianBlur(18))
        base.paste(Image.new("RGBA", image.size, (0, 0, 0, 55)), (x, y + 12), shadow_mask)
    base.paste(image.convert("RGBA"), xy, mask)


def status_bar(draw, width, y, scale):
    draw.text((int(width * 0.08), y), "9:41", font=font(int(16 * scale), bold=True), fill=(27, 27, 27))
    draw.rounded_rectangle((int(width * 0.84), y + int(7 * scale), int(width * 0.90), y + int(17 * scale)), radius=int(3 * scale), outline=(27, 27, 27), width=max(1, int(scale)))
    draw.rectangle((int(width * 0.845), y + int(10 * scale), int(width * 0.885), y + int(14 * scale)), fill=(27, 27, 27))


def phone_frame(size):
    width, height = size
    scale = min(width / 390, height / 844)
    image = Image.new("RGBA", size, (245, 247, 246, 255))
    draw = ImageDraw.Draw(image)
    status_bar(draw, width, int(14 * scale), scale)
    return image, draw, scale


def button(draw, box, text, scale, dark=True, icon=None):
    fill = (25, 25, 25) if dark else (255, 255, 255)
    outline = None if dark else (220, 220, 220)
    text_fill = (255, 255, 255) if dark else (25, 25, 25)
    draw.rounded_rectangle(box, radius=int(8 * scale), fill=fill, outline=outline, width=max(1, int(scale)))
    label = f"{icon}  {text}" if icon else text
    bbox = draw.textbbox((0, 0), label, font=font(int(16 * scale), bold=True))
    draw.text(((box[0] + box[2] - bbox[2] + bbox[0]) / 2, (box[1] + box[3] - bbox[3] + bbox[1]) / 2 - int(1 * scale)), label, font=font(int(16 * scale), bold=True), fill=text_fill)


def album_preview(width, template_path, scale, with_text=True):
    photo_h = int(width * 0.68)
    band_h = int(width * 0.20) if with_text else 0
    image = Image.new("RGBA", (width, photo_h + band_h), (255, 255, 255, 255))
    photo = cover_resize(Image.open(template_path).convert("RGB"), (width, photo_h))
    image.alpha_composite(photo.convert("RGBA"), (0, 0))
    if with_text:
        draw = ImageDraw.Draw(image)
        draw.rectangle((0, photo_h, width, photo_h + band_h), fill=(255, 255, 255))
        draw_center(draw, photo_h + int(20 * scale), "令和6年度　卒業記念", font(int(22 * scale), serif=True), (15, 15, 15), width)
        draw_center(draw, photo_h + int(55 * scale), "〇〇市立〇〇中学校　3年B組", font(int(18 * scale), serif=True), (15, 15, 15), width)
    return image


def home_screen(size):
    image, draw, scale = phone_frame(size)
    width, height = size
    y = int(72 * scale)
    draw_center(draw, y, "卒アル右上メーカー", font(int(26 * scale), bold=True), (20, 24, 24), width)
    draw_center(draw, y + int(42 * scale), "集合写真にいなかった人を、", font(int(14 * scale)), (92, 92, 92), width)
    draw_center(draw, y + int(64 * scale), "あの右上の丸いやつで救うアプリ。", font(int(14 * scale)), (92, 92, 92), width)

    preview_w = int(width * 0.86)
    preview = album_preview(preview_w, STANDARD, scale)
    rounded_paste(image, preview, ((width - preview_w) // 2, int(175 * scale)), int(8 * scale), shadow=True)

    button(draw, (int(24 * scale), int(570 * scale), width - int(24 * scale), int(620 * scale)), "テンプレートを選ぶ", scale, True)
    button(draw, (int(24 * scale), int(632 * scale), width - int(24 * scale), int(680 * scale)), "追加テンプレートを購入", scale, False)

    note = "写真はサーバーへ送らず、端末内で処理します。"
    draw_center(draw, int(710 * scale), note, font(int(11 * scale)), (105, 105, 105), width)
    return image


def template_card(width, height, template_path, name, category, locked, scale):
    image = Image.new("RGBA", (width, height), (255, 255, 255, 255))
    draw = ImageDraw.Draw(image)
    preview = cover_resize(Image.open(template_path).convert("RGB"), (int(126 * scale), int(92 * scale)))
    rounded_paste(image, preview, (int(12 * scale), int(12 * scale)), int(8 * scale))
    draw.text((int(152 * scale), int(18 * scale)), name, font=font(int(16 * scale), bold=True), fill=(20, 20, 20))
    draw.text((int(152 * scale), int(48 * scale)), category, font=font(int(12 * scale), bold=True), fill=(217, 117, 0) if locked else (43, 140, 70))
    draw.text((int(152 * scale), int(72 * scale)), "令和6年度　卒業記念", font=font(int(11 * scale)), fill=(120, 120, 120))
    draw.text((width - int(44 * scale), int(40 * scale)), "鍵" if locked else "›", font=font(int(18 * scale), bold=True), fill=(120, 120, 120))
    return image


def template_screen(size):
    image, draw, scale = phone_frame(size)
    width, _ = size
    draw_center(draw, int(58 * scale), "テンプレート", font(int(20 * scale), bold=True), (20, 20, 20), width)
    rows = [
        (STANDARD, "標準卒アル", "無料", False),
        (TRIP, "修学旅行", "無料", False),
        (CULTURE, "文化祭", "思い出行事パック", True),
        (MEIJI, "明治維新", "思い出行事パック2", True),
    ]
    y = int(100 * scale)
    for item in rows:
        card = template_card(width - int(32 * scale), int(116 * scale), *item, scale)
        rounded_paste(image, card, (int(16 * scale), y), int(8 * scale), shadow=False)
        y += int(130 * scale)
    return image


def editor_screen(size):
    image, draw, scale = phone_frame(size)
    width, height = size
    draw_center(draw, int(58 * scale), "標準卒アル", font(int(20 * scale), bold=True), (20, 20, 20), width)
    canvas = album_preview(width - int(24 * scale), STANDARD, scale)
    rounded_paste(image, canvas, (int(12 * scale), int(96 * scale)), int(6 * scale), shadow=False)

    seg_y = int(545 * scale)
    draw.rounded_rectangle((int(12 * scale), seg_y, width - int(12 * scale), seg_y + int(36 * scale)), radius=int(8 * scale), fill=(232, 235, 235))
    labels = ["写真追加", "丸窓調整", "文字入力", "保存"]
    cell_w = (width - int(24 * scale)) / len(labels)
    draw.rounded_rectangle((int(12 * scale), seg_y, int(12 * scale + cell_w), seg_y + int(36 * scale)), radius=int(8 * scale), fill=(255, 255, 255))
    for index, label in enumerate(labels):
        x = int(12 * scale + index * cell_w)
        bbox = draw.textbbox((0, 0), label, font=font(int(11 * scale), bold=index == 0))
        draw.text((x + (cell_w - (bbox[2] - bbox[0])) / 2, seg_y + int(9 * scale)), label, font=font(int(11 * scale), bold=index == 0), fill=(30, 30, 30))

    panel_y = int(600 * scale)
    draw.rounded_rectangle((int(12 * scale), panel_y, width - int(12 * scale), height - int(20 * scale)), radius=int(8 * scale), fill=(255, 255, 255))
    button(draw, (int(28 * scale), panel_y + int(18 * scale), width - int(28 * scale), panel_y + int(68 * scale)), "顔写真を選ぶ", scale, True, "◯")
    draw.text((int(28 * scale), panel_y + int(86 * scale)), "選んだ写真は丸く切り抜き、右上に配置します。", font=font(int(12 * scale)), fill=(95, 95, 95))
    draw.text((int(28 * scale), panel_y + int(110 * scale)), "位置・サイズ・拡大縮小も調整できます。", font=font(int(12 * scale)), fill=(95, 95, 95))
    return image


def iap_review_image(title, names, filename):
    width, height = 1290, 2796
    image, draw, scale = phone_frame((width, height))
    draw_center(draw, int(90 * scale), "追加テンプレート", font(int(24 * scale), bold=True), (20, 20, 20), width)
    card_x, card_y = int(28 * scale), int(150 * scale)
    card_w, card_h = width - int(56 * scale), int(520 * scale)
    draw.rounded_rectangle((card_x, card_y, card_x + card_w, card_y + card_h), radius=int(10 * scale), fill=(255, 255, 255))
    draw.text((card_x + int(24 * scale), card_y + int(26 * scale)), title, font=font(int(28 * scale), bold=True), fill=(20, 20, 20))
    y = card_y + int(100 * scale)
    for name in names:
        draw.text((card_x + int(26 * scale), y), f"✓ {name}", font=font(int(20 * scale), bold=True), fill=(38, 128, 67))
        y += int(52 * scale)
    button(draw, (card_x + int(24 * scale), card_y + card_h - int(120 * scale), card_x + card_w - int(24 * scale), card_y + card_h - int(62 * scale)), "¥160で購入", scale, True)
    button(draw, (card_x + int(24 * scale), card_y + card_h - int(52 * scale), card_x + card_w - int(24 * scale), card_y + card_h - int(4 * scale)), "購入を復元", scale, False)
    image.convert("RGB").save(IAP_OUT / filename, quality=95)


def save_all():
    devices = [((1290, 2796), "iphone67"), ((2048, 2732), "ipad129")]
    screens = [home_screen, template_screen, editor_screen]
    names = ["01_home", "02_templates", "03_editor"]
    for size, prefix in devices:
        for maker, name in zip(screens, names):
            maker(size).convert("RGB").save(OUT / f"{prefix}_{name}.png", quality=95)

    # Remove old marketing names so ASC gets only actual app UI screenshots.
    for stale in OUT.glob("*_02_editor.png"):
        stale.unlink(missing_ok=True)
    for stale in OUT.glob("*_03_templates.png"):
        stale.unlink(missing_ok=True)

    iap_review_image(
        "思い出行事パック",
        ["体育祭", "文化祭", "例の遊園地", "林間学校", "楽しい遠足"],
        "omoide_event_pack.png",
    )
    iap_review_image(
        "思い出行事パック2",
        ["明治維新", "本気の登山", "例のユニバ", "イ〇〇の物置", "異世界"],
        "absentee_frame_pack_2.png",
    )

    for screenshot in sorted(OUT.glob("*.png")):
        print(f"{screenshot.name}: {Image.open(screenshot).size}")
    for screenshot in sorted(IAP_OUT.glob("*.png")):
        print(f"{screenshot.name}: {Image.open(screenshot).size}")


if __name__ == "__main__":
    save_all()
