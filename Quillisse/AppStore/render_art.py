#!/usr/bin/env python3
"""Compose Quillisse icons, seed garment stills, and App Store screenshots.

The icon is the approved photograph, resized with no extra mask.
Screenshots are 1206×2622 only: a model portrait, marketing line, and the
Quillisse UI inside an iPhone bezel. They are not Simulator captures.
"""

from __future__ import annotations

import shutil
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / "AppStore"
ASSETS = ROOT / "App" / "Assets.xcassets"
ICON_DIR = ASSETS / "AppIcon.appiconset"
UPLOADS = Path("/home/ubuntu/.cursor/projects/workspace/uploads")
ICON_SRC = next(UPLOADS.glob("quillisse-icon*.jpg"))
MODELS = {
    "office": next(UPLOADS.glob("model-office*.jpg")),
    "weekend": next(UPLOADS.glob("model-weekend*.jpg")),
    "winter": next(UPLOADS.glob("model-winter*.jpg")),
    "evening": next(UPLOADS.glob("model-evening*.jpg")),
}

SERIF = "/usr/share/fonts/truetype/liberation/LiberationSerif-Regular.ttf"
SERIF_BOLD = "/usr/share/fonts/truetype/liberation/LiberationSerif-Bold.ttf"
SERIF_ITALIC = "/usr/share/fonts/truetype/liberation/LiberationSerif-Italic.ttf"
SANS = "/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf"
SANS_BOLD = "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf"

PAPER = (243, 238, 230)
CARD = (252, 249, 244)
INK = (26, 23, 20)
MUTED = (122, 113, 104)
LINE = (214, 204, 190)
OX = (142, 59, 58)
WHITE = (255, 252, 248)

SHOT = (1206, 2622)

GARMENTS: dict[str, Image.Image] = {}


def font(path: str, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(path, max(8, int(size)))


def shade(rgb, factor: float):
    return tuple(max(0, min(255, int(channel * factor))) for channel in rgb)


def cover(path: Path, size: tuple[int, int], focus=(0.5, 0.34)) -> Image.Image:
    image = Image.open(path).convert("RGB")
    width, height = size
    scale = max(width / image.width, height / image.height)
    resized = image.resize((int(image.width * scale), int(image.height * scale)), Image.Resampling.LANCZOS)
    left = int(resized.width * focus[0] - width / 2)
    top = int(resized.height * focus[1] - height / 2)
    left = max(0, min(left, resized.width - width))
    top = max(0, min(top, resized.height - height))
    return resized.crop((left, top, left + width, top + height))


def paste(base: Image.Image, overlay: Image.Image, box):
    if overlay.mode != "RGBA":
        overlay = overlay.convert("RGBA")
    base.alpha_composite(overlay, (int(box[0]), int(box[1])))


def rounded(base: Image.Image, box, radius, fill, outline=None, width=1):
    layer = Image.new("RGBA", base.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)
    base.alpha_composite(layer)


def text(base, xy, content, face, fill, anchor="lt"):
    draw = ImageDraw.Draw(base)
    lines = content.split("\n")
    if len(lines) == 1:
        draw.text(xy, content, font=face, fill=fill, anchor=anchor)
        return
    x, y = xy
    for line in lines:
        draw.text((x, y), line, font=face, fill=fill, anchor="lt")
        y += face.size * 1.05


def wrap(draw, content, face, width):
    words = content.split()
    lines, current = [], ""
    for word in words:
        trial = word if not current else f"{current} {word}"
        if draw.textlength(trial, font=face) <= width:
            current = trial
        else:
            if current:
                lines.append(current)
            current = word
    if current:
        lines.append(current)
    return lines


def shadow_card(base, box, radius, fill=CARD):
    layer = Image.new("RGBA", base.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    x0, y0, x1, y1 = box
    draw.rounded_rectangle((x0 + 6, y0 + 14, x1 + 6, y1 + 18), radius=radius, fill=(40, 28, 22, 48))
    layer = layer.filter(ImageFilter.GaussianBlur(16))
    base.alpha_composite(layer)
    rounded(base, box, radius, fill, LINE, 2)


def new_still() -> tuple[Image.Image, ImageDraw.ImageDraw]:
    image = Image.new("RGB", (800, 1000), PAPER)
    return image, ImageDraw.Draw(image)


def polish(image: Image.Image) -> Image.Image:
    # Soft floor shadow so the still sits on the card.
    canvas = Image.new("RGBA", image.size, (0, 0, 0, 0))
    canvas.paste(image.convert("RGBA"))
    shadow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(shadow)
    draw.ellipse((180, 860, 620, 940), fill=(80, 60, 40, 55))
    shadow = shadow.filter(ImageFilter.GaussianBlur(12))
    return Image.alpha_composite(shadow, canvas).convert("RGB")


def garment_cardigan(color, rib=True):
    image, draw = new_still()
    dark = shade(color, 0.86)
    sleeve_l = [(210, 250), (90, 360), (130, 700), (250, 620)]
    sleeve_r = [(590, 250), (710, 360), (670, 700), (550, 620)]
    body = [(200, 180), (600, 180), (650, 860), (150, 860)]
    draw.polygon(sleeve_l, fill=color, outline=dark)
    draw.polygon(sleeve_r, fill=color, outline=dark)
    draw.polygon(body, fill=color, outline=dark)
    draw.polygon([(360, 250), (440, 250), (470, 860), (330, 860)], fill=PAPER)
    if rib:
        for y in range(820, 860, 8):
            draw.line((160, y, 640, y), fill=dark, width=2)
        for x in (120, 140, 660, 680):
            draw.line((x, 640, x, 700), fill=dark, width=2)
    for y in (420, 520, 620):
        draw.ellipse((384, y, 416, y + 32), fill=shade(color, 0.55))
    return polish(image)


def garment_jeans():
    image, draw = new_still()
    denim = (142, 174, 204)
    dark = (96, 126, 158)
    fade = (176, 198, 220)
    draw.rounded_rectangle((230, 160, 570, 250), radius=20, fill=denim, outline=dark, width=3)
    draw.rectangle((250, 230, 390, 900), fill=denim, outline=dark)
    draw.rectangle((410, 230, 550, 900), fill=denim, outline=dark)
    draw.polygon([(250, 230), (390, 230), (370, 420), (250, 400)], fill=fade)
    draw.polygon([(410, 230), (550, 230), (550, 400), (430, 420)], fill=fade)
    draw.arc((300, 200, 500, 360), 20, 160, fill=dark, width=4)
    draw.line((320, 250, 320, 880), fill=dark, width=2)
    draw.line((480, 250, 480, 880), fill=dark, width=2)
    draw.rounded_rectangle((270, 300, 350, 360), radius=8, outline=dark, width=3)
    draw.rounded_rectangle((450, 300, 530, 360), radius=8, outline=dark, width=3)
    return polish(image)


def garment_trousers(color):
    image, draw = new_still()
    dark = shade(color, 0.78)
    draw.polygon([(250, 170), (550, 170), (520, 240), (280, 240)], fill=color, outline=dark)
    draw.polygon([(270, 230), (390, 230), (370, 900), (230, 900)], fill=color, outline=dark)
    draw.polygon([(410, 230), (530, 230), (570, 900), (430, 900)], fill=color, outline=dark)
    draw.line((320, 250, 300, 880), fill=dark, width=2)
    draw.line((480, 250, 500, 880), fill=dark, width=2)
    draw.line((400, 240, 400, 360), fill=dark, width=2)
    return polish(image)


def garment_shorts(color):
    image, draw = new_still()
    dark = shade(color, 0.75)
    draw.rounded_rectangle((220, 240, 580, 340), radius=16, fill=color, outline=dark, width=3)
    draw.polygon([(230, 320), (390, 320), (400, 700), (210, 700)], fill=color, outline=dark)
    draw.polygon([(410, 320), (570, 320), (590, 700), (400, 700)], fill=color, outline=dark)
    draw.rectangle((250, 400, 330, 470), outline=dark, width=3)
    draw.rectangle((470, 400, 550, 470), outline=dark, width=3)
    draw.line((400, 330, 400, 470), fill=dark, width=2)
    return polish(image)


def garment_top(color, kind):
    image, draw = new_still()
    dark = shade(color, 0.8)
    if kind == "cami":
        draw.polygon([(280, 210), (520, 210), (560, 820), (240, 820)], fill=color, outline=dark)
        draw.line((320, 210, 400, 120), fill=dark, width=8)
        draw.line((480, 210, 400, 120), fill=dark, width=8)
        draw.arc((300, 180, 500, 280), 200, 340, fill=dark, width=4)
    elif kind == "tee":
        draw.polygon([(250, 230), (550, 230), (600, 820), (200, 820)], fill=color, outline=dark)
        draw.polygon([(180, 250), (280, 220), (300, 430), (160, 470)], fill=color, outline=dark)
        draw.polygon([(520, 220), (620, 250), (640, 470), (500, 430)], fill=color, outline=dark)
        draw.ellipse((330, 210, 470, 300), fill=PAPER, outline=dark, width=3)
    elif kind == "blouse":
        draw.polygon([(250, 250), (550, 250), (590, 860), (210, 860)], fill=color, outline=dark)
        draw.polygon([(160, 280), (270, 240), (300, 520), (150, 560)], fill=color, outline=dark)
        draw.polygon([(530, 240), (640, 280), (650, 560), (500, 520)], fill=color, outline=dark)
        draw.polygon([(340, 180), (460, 180), (490, 300), (310, 300)], fill=color, outline=dark)
        draw.line((400, 300, 400, 820), fill=dark, width=2)
        for y in (420, 520, 620):
            draw.ellipse((388, y, 412, y + 22), outline=dark, width=2)
    else:  # knit
        draw.polygon([(230, 210), (570, 210), (610, 840), (190, 840)], fill=color, outline=dark)
        draw.polygon([(140, 240), (260, 210), (290, 560), (130, 600)], fill=color, outline=dark)
        draw.polygon([(540, 210), (660, 240), (670, 600), (510, 560)], fill=color, outline=dark)
        draw.pieslice((320, 160, 480, 280), 200, 340, fill=color, outline=dark)
        for y in range(260, 820, 22):
            draw.line((250, y, 550, y), fill=shade(color, 0.9), width=2)
    return polish(image)


def garment_shirt(color):
    image, draw = new_still()
    dark = shade(color, 0.78)
    draw.polygon([(230, 220), (570, 220), (620, 860), (180, 860)], fill=color, outline=dark)
    draw.polygon([(150, 260), (260, 220), (290, 560), (140, 600)], fill=color, outline=dark)
    draw.polygon([(540, 220), (650, 260), (660, 600), (510, 560)], fill=color, outline=dark)
    draw.polygon([(330, 160), (470, 160), (500, 280), (300, 280)], fill=color, outline=dark)
    draw.polygon([(370, 250), (430, 250), (450, 860), (350, 860)], fill=PAPER)
    for y in (360, 460, 560, 660):
        draw.ellipse((392, y, 412, y + 20), fill=WHITE, outline=dark)
    draw.rectangle((470, 340, 560, 460), outline=dark, width=3)
    return polish(image)


def garment_blazer():
    image, draw = new_still()
    color = (22, 22, 26)
    edge = (70, 70, 76)
    draw.polygon([(140, 280), (250, 200), (280, 620), (120, 680)], fill=color, outline=edge)
    draw.polygon([(550, 200), (660, 280), (680, 680), (520, 620)], fill=color, outline=edge)
    draw.polygon([(210, 180), (590, 180), (640, 880), (160, 880)], fill=color, outline=edge)
    draw.polygon([(330, 200), (400, 430), (250, 860), (190, 860), (250, 280)], fill=shade(color, 1.4))
    draw.polygon([(470, 200), (400, 430), (550, 860), (610, 860), (550, 280)], fill=shade(color, 1.2))
    draw.polygon([(360, 190), (440, 190), (470, 320), (330, 320)], fill=color, outline=edge)
    draw.ellipse((470, 430, 500, 460), fill=(190, 190, 196))
    draw.line((250, 300, 330, 520), fill=edge, width=3)
    return polish(image)


def garment_coat():
    image, draw = new_still()
    color = (196, 156, 108)
    dark = shade(color, 0.75)
    draw.polygon([(150, 300), (250, 190), (290, 640), (130, 700)], fill=color, outline=dark)
    draw.polygon([(550, 190), (650, 300), (670, 700), (510, 640)], fill=color, outline=dark)
    draw.polygon([(200, 160), (600, 160), (660, 920), (140, 920)], fill=color, outline=dark)
    draw.polygon([(370, 200), (430, 200), (460, 900), (340, 900)], fill=shade(color, 0.92))
    for y in (360, 480, 600):
        draw.ellipse((392, y, 416, y + 24), fill=shade(color, 0.55))
    draw.polygon([(300, 150), (500, 150), (470, 250), (330, 250)], fill=color, outline=dark)
    return polish(image)


def garment_dress():
    image, draw = new_still()
    color = (224, 112, 98)
    dark = shade(color, 0.78)
    draw.polygon([(300, 160), (500, 160), (540, 380), (260, 380)], fill=color, outline=dark)
    draw.polygon([(250, 360), (550, 360), (640, 900), (160, 900)], fill=color, outline=dark)
    draw.line((260, 380, 540, 380), fill=dark, width=3)
    draw.ellipse((350, 150, 450, 210), outline=dark, width=4)
    return polish(image)


def garment_sneakers():
    image, draw = new_still()
    body = (246, 246, 244)
    dark = (180, 176, 170)
    sole = (232, 230, 226)
    draw.rounded_rectangle((120, 620, 680, 760), radius=30, fill=sole, outline=dark, width=4)
    draw.polygon([(180, 470), (560, 420), (680, 500), (660, 640), (160, 640)], fill=body, outline=dark)
    draw.polygon([(200, 470), (360, 450), (340, 560), (190, 580)], fill=(230, 230, 228), outline=dark)
    draw.arc((470, 430, 640, 560), 200, 20, fill=dark, width=6)
    draw.line((200, 700, 600, 700), fill=dark, width=3)
    return polish(image)


def garment_loafers():
    image, draw = new_still()
    color = (28, 28, 30)
    edge = (90, 90, 94)
    draw.rounded_rectangle((130, 640, 680, 780), radius=24, fill=(48, 48, 50), outline=edge, width=3)
    draw.polygon([(180, 500), (520, 470), (690, 560), (660, 680), (160, 680)], fill=color, outline=edge)
    draw.pieslice((430, 430, 690, 640), 200, 40, fill=color, outline=edge)
    draw.line((250, 560, 500, 540), fill=(120, 90, 55), width=6)
    return polish(image)


def garment_heels():
    image, draw = new_still()
    color = (214, 176, 140)
    dark = shade(color, 0.7)
    draw.polygon([(160, 620), (520, 560), (690, 620), (640, 690), (180, 700)], fill=color, outline=dark)
    draw.line((230, 700, 250, 860), fill=dark, width=10)
    draw.line((560, 680, 620, 820), fill=dark, width=8)
    draw.line((250, 600, 420, 430), fill=dark, width=6)
    draw.line((470, 560, 560, 430), fill=dark, width=6)
    return polish(image)


def garment_pumps():
    image, draw = new_still()
    color = (24, 24, 28)
    edge = (90, 90, 96)
    draw.polygon([(170, 560), (520, 500), (700, 600), (650, 690), (180, 700)], fill=color, outline=edge)
    draw.line((240, 690, 250, 860), fill=edge, width=10)
    draw.polygon([(250, 540), (430, 500), (400, 620), (230, 640)], fill=(40, 40, 46), outline=edge)
    return polish(image)


def garment_hoops():
    image, draw = new_still()
    gold = (196, 158, 86)
    dark = (140, 108, 48)
    for cx in (300, 500):
        draw.ellipse((cx - 90, 340, cx + 90, 620), outline=gold, width=18)
        draw.ellipse((cx - 54, 376, cx + 54, 584), outline=dark, width=2)
        draw.rectangle((cx - 8, 300, cx + 8, 360), fill=gold)
    return polish(image)


def garment_scarf():
    image, draw = new_still()
    color = (232, 186, 181)
    dark = shade(color, 0.78)
    draw.polygon([(220, 180), (560, 220), (520, 820), (180, 760)], fill=color, outline=dark)
    draw.polygon([(300, 260), (620, 180), (660, 700), (340, 780)], fill=shade(color, 1.05), outline=dark)
    for y in range(300, 760, 36):
        draw.line((240, y, 500, y + 30), fill=dark, width=2)
    return polish(image)


def build_garments():
    items = {
        "seed-cream-cardigan": garment_cardigan((236, 226, 206)),
        "seed-light-jeans": garment_jeans(),
        "seed-white-sneakers": garment_sneakers(),
        "seed-ivory-cami": garment_top((245, 240, 228), "cami"),
        "seed-black-blazer": garment_blazer(),
        "seed-ivory-blouse": garment_top((248, 244, 236), "blouse"),
        "seed-camel-trousers": garment_trousers((198, 160, 112)),
        "seed-black-loafers": garment_loafers(),
        "seed-gold-hoops": garment_hoops(),
        "seed-coral-dress": garment_dress(),
        "seed-lavender-cardigan": garment_cardigan((196, 184, 220)),
        "seed-nude-heels": garment_heels(),
        "seed-white-tee": garment_top((250, 250, 248), "tee"),
        "seed-linen-shirt": garment_shirt((168, 196, 222)),
        "seed-olive-shorts": garment_shorts((122, 128, 78)),
        "seed-navy-knit": garment_top((36, 52, 86), "knit"),
        "seed-charcoal-trousers": garment_trousers((78, 78, 82)),
        "seed-camel-coat": garment_coat(),
        "seed-blush-scarf": garment_scarf(),
        "seed-black-pumps": garment_pumps(),
    }
    GARMENTS.update(items)
    out = ART / "garments"
    out.mkdir(parents=True, exist_ok=True)
    for name, image in items.items():
        image.save(out / f"{name}.png")
        folder = ASSETS / f"{name}.imageset"
        folder.mkdir(parents=True, exist_ok=True)
        image.save(folder / f"{name}.png")
        (folder / "Contents.json").write_text(
            """{
  "images" : [
    { "filename" : "%s.png", "idiom" : "universal" }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
"""
            % name
        )


def thumb(name: str, size: int) -> Image.Image:
    image = GARMENTS[name].copy()
    image.thumbnail((size, size), Image.Resampling.LANCZOS)
    canvas = Image.new("RGB", (size, size), PAPER)
    canvas.paste(image, ((size - image.width) // 2, (size - image.height) // 2))
    return canvas


TERRACOTTA = (161, 69, 46)
GOLD = (201, 139, 80)
SAND = (243, 214, 176)
CREAM = (255, 248, 240)
FRAME = (28, 22, 18)
ISLAND = (12, 10, 9)

ICON_SIZES = {
    "icon-20.png": 20,
    "icon-29.png": 29,
    "icon-40.png": 40,
    "icon-58.png": 58,
    "icon-60.png": 60,
    "icon-76.png": 76,
    "icon-80.png": 80,
    "icon-87.png": 87,
    "icon-120.png": 120,
    "icon-152.png": 152,
    "icon-167.png": 167,
    "icon-180.png": 180,
    "icon-1024.png": 1024,
}

SCREEN = (688, 1472)
BEZEL = 16


def master_icon() -> Image.Image:
    image = Image.open(ICON_SRC).convert("RGB")
    side = min(image.size)
    left = (image.width - side) // 2
    top = (image.height - side) // 2
    image = image.crop((left, top, left + side, top + side))
    if image.size != (1024, 1024):
        image = image.resize((1024, 1024), Image.Resampling.LANCZOS)
    return image


def save_icons():
    master = master_icon()
    assert master.mode == "RGB" and master.size == (1024, 1024)
    (ART / "icon").mkdir(parents=True, exist_ok=True)
    # Drop any earlier generated mark so only the approved icon remains.
    for stale in (ART / "icon").glob("*.png"):
        stale.unlink()
    master.save(ART / "icon" / "AppIcon-1024.png")
    ICON_DIR.mkdir(parents=True, exist_ok=True)
    for name, side in ICON_SIZES.items():
        image = master if side == 1024 else master.resize((side, side), Image.Resampling.LANCZOS)
        assert image.mode == "RGB"
        image.save(ICON_DIR / name)
    web = ART / "website"
    web.mkdir(parents=True, exist_ok=True)
    master.resize((32, 32), Image.Resampling.LANCZOS).save(web / "favicon-32.png")
    master.resize((16, 16), Image.Resampling.LANCZOS).save(web / "favicon-16.png")
    master.resize((180, 180), Image.Resampling.LANCZOS).save(web / "apple-touch-icon.png")


def copy_models():
    dest = ART / "models"
    dest.mkdir(parents=True, exist_ok=True)
    names = {
        "office": "model-office.jpg",
        "weekend": "model-weekend.jpg",
        "winter": "model-winter.jpg",
        "evening": "model-evening.jpg",
    }
    keep = set(names.values())
    for old in dest.glob("*"):
        if old.name not in keep:
            old.unlink()
    for key, filename in names.items():
        shutil.copyfile(MODELS[key], dest / filename)


def canvas_background() -> Image.Image:
    width, height = SHOT
    row = Image.new("RGB", (width, 1))
    draw = ImageDraw.Draw(row)
    for x in range(width):
        t = x / (width - 1)
        color = tuple(int(a + (b - a) * t) for a, b in zip(TERRACOTTA, GOLD))
        draw.point((x, 0), fill=color)
    base = row.resize(SHOT)
    sand = Image.new("RGB", SHOT, SAND)
    mask = Image.new("L", (1, height))
    for y in range(height):
        mask.putpixel((0, y), int(255 * (y / (height - 1)) ** 1.15 * 0.62))
    return Image.composite(sand, base, mask.resize(SHOT))


def phone_frame(screen: Image.Image) -> Image.Image:
    sw, sh = screen.size
    ow, oh = sw + BEZEL * 2, sh + BEZEL * 2
    frame = Image.new("RGBA", (ow, oh), (0, 0, 0, 0))
    draw = ImageDraw.Draw(frame)
    draw.rounded_rectangle((0, 0, ow - 1, oh - 1), radius=78, fill=FRAME)
    draw.rounded_rectangle((3, 3, ow - 4, oh - 4), radius=74, outline=(70, 54, 42), width=2)
    mask = Image.new("L", screen.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, sw - 1, sh - 1), radius=62, fill=255)
    framed = screen.convert("RGBA")
    frame.paste(framed, (BEZEL, BEZEL), mask)
    island_w, island_h = 196, 36
    ix = BEZEL + (sw - island_w) / 2
    iy = BEZEL + 14
    draw.rounded_rectangle((ix, iy, ix + island_w, iy + island_h), radius=island_h / 2, fill=ISLAND)
    # Side buttons.
    draw.rounded_rectangle((-3, 220, 4, 300), radius=2, fill=(48, 38, 30))
    draw.rounded_rectangle((-3, 330, 4, 420), radius=2, fill=(48, 38, 30))
    draw.rounded_rectangle((ow - 4, 280, ow + 3, 400), radius=2, fill=(48, 38, 30))
    return frame


def status_bar(screen: Image.Image):
    draw = ImageDraw.Draw(screen)
    face = font(SANS_BOLD, 22)
    draw.text((28, 22), "9:41", font=face, fill=INK)
    # Battery and signal, kept clear of the island (center 196px).
    x = screen.width - 78
    draw.rounded_rectangle((x, 26, x + 36, 42), radius=4, outline=INK, width=2)
    draw.rectangle((x + 2, 29, x + 26, 39), fill=INK)
    draw.rectangle((x + 37, 32, x + 40, 37), fill=INK)
    draw.arc((screen.width - 130, 22, screen.width - 108, 44), 200, 340, fill=INK, width=2)


def home_indicator(screen: Image.Image):
    draw = ImageDraw.Draw(screen)
    w = 150
    x = (screen.width - w) / 2
    y = screen.height - 16
    draw.rounded_rectangle((x, y, x + w, y + 6), radius=3, fill=(80, 70, 62))


def tab_bar(screen: Image.Image, selected: int):
    h = 78
    y = screen.height - 28 - h
    draw = ImageDraw.Draw(screen)
    draw.rectangle((0, y, screen.width, y + h), fill=(250, 246, 240))
    draw.line((0, y, screen.width, y), fill=LINE, width=2)
    labels = ["Today", "Closet", "Atelier", "Journal"]
    slot = screen.width / 4
    for index, label in enumerate(labels):
        cx = slot * index + slot / 2
        color = OX if index == selected else MUTED
        face = font(SANS_BOLD if index == selected else SANS, 18)
        draw.text((cx, y + 46), label, font=face, fill=color, anchor="mm")
        r = 7
        my = y + 18
        if index == 0:
            draw.ellipse((cx - r, my - r, cx + r, my + r), outline=color, width=2)
        elif index == 1:
            draw.rounded_rectangle((cx - 9, my - 7, cx + 9, my + 8), radius=2, outline=color, width=2)
        elif index == 2:
            draw.rectangle((cx - 9, my - 7, cx - 1, my + 8), outline=color, width=2)
            draw.rectangle((cx + 1, my - 7, cx + 9, my + 8), outline=color, width=2)
        else:
            draw.rounded_rectangle((cx - 9, my - 7, cx + 9, my + 8), radius=2, outline=color, width=2)
    return y


def chips_row(screen, xy, labels, selected):
    x, y = xy
    face = font(SANS_BOLD, 15)
    draw = ImageDraw.Draw(screen)
    height = 36
    for label in labels:
        width = draw.textlength(label, font=face) + 20
        if x + width > screen.width - 16:
            break
        on = label == selected
        rounded(screen, (x, y, x + width, y + height), height / 2, INK if on else CARD, None if on else LINE, 2)
        draw.text((x + width / 2, y + height / 2), label, font=face, fill=CARD if on else INK, anchor="mm")
        x += width + 6
    return y + height + 12


def tile(screen, token, box):
    x0, y0, x1, y1 = box
    rounded(screen, box, 12, PAPER, LINE, 2)
    still = thumb(token, int(min(x1 - x0, y1 - y0) - 8))
    screen.paste(still, (int(x0 + (x1 - x0 - still.width) / 2), int(y0 + 4)))


def screen_base() -> Image.Image:
    image = Image.new("RGBA", SCREEN, PAPER + (255,))
    status_bar(image)
    return image


def ui_today() -> Image.Image:
    image = screen_base()
    tab = tab_bar(image, 0)
    draw = ImageDraw.Draw(image)
    y = 64
    draw.text((image.width / 2, y), "QUILLISSE", font=font(SANS_BOLD, 16), fill=INK, anchor="mt")
    y += 28
    draw.text((22, y), "WEDNESDAY", font=font(SANS_BOLD, 14), fill=OX)
    y += 20
    draw.text((22, y), "11 November", font=font(SERIF, 36), fill=INK)
    y += 48
    y = chips_row(image, (22, y), ["Work", "Casual", "Date", "Weekend", "Formal"], "Work")
    rounded(image, (22, y, image.width - 22, y + 64), 16, CARD, LINE, 2)
    draw.ellipse((40, y + 18, 62, y + 40), outline=OX, width=2)
    draw.text((74, y + 10), "Mild", font=font(SERIF, 24), fill=INK)
    draw.text((74, y + 36), "Autumn · chosen on this device", font=font(SANS, 14), fill=MUTED)
    draw.text((image.width - 32, y + 32), "Change", font=font(SANS_BOLD, 16), fill=OX, anchor="rm")
    y += 78
    card_bottom = tab - 14
    shadow_card(image, (18, y, image.width - 18, card_bottom), 22)
    draw.text((36, y + 16), "SUGGESTED", font=font(SANS_BOLD, 13), fill=OX)
    draw.text((image.width - 48, y + 12), "♡", font=font(SERIF, 28), fill=OX)
    draw.text((36, y + 36), "Ivory blouse and", font=font(SERIF, 28), fill=INK)
    draw.text((36, y + 70), "Camel trousers", font=font(SERIF, 28), fill=INK)
    draw.text((36, y + 112), "A light layer for a mild day.", font=font(SERIF_ITALIC, 16), fill=MUTED)
    draw.text((36, y + 134), "Fits a work day.", font=font(SERIF_ITALIC, 16), fill=MUTED)
    names = ["seed-ivory-blouse", "seed-camel-trousers", "seed-black-blazer", "seed-black-loafers"]
    captions = ["Blouse", "Trousers", "Blazer", "Loafers"]
    gap = 10
    tile_w = (image.width - 72 - gap * 3) / 4
    ty = y + 164
    for index, token in enumerate(names):
        x = 36 + index * (tile_w + gap)
        tile(image, token, (x, ty, x + tile_w, ty + tile_w))
        draw.text((x, ty + tile_w + 4), captions[index], font=font(SANS, 13), fill=INK)
    button = (36, card_bottom - 78, image.width - 36, card_bottom - 28)
    rounded(image, button, 14, OX)
    draw.text(((button[0] + button[2]) / 2, (button[1] + button[3]) / 2), "Wear this today", font=font(SANS_BOLD, 20), fill=CARD, anchor="mm")
    home_indicator(image)
    return image


def ui_closet() -> Image.Image:
    image = screen_base()
    tab = tab_bar(image, 1)
    draw = ImageDraw.Draw(image)
    y = 62
    draw.text((22, y), "WARDROBE", font=font(SANS_BOLD, 13), fill=OX)
    draw.text((image.width - 28, y), "+", font=font(SANS_BOLD, 28), fill=INK, anchor="rt")
    y += 22
    draw.text((22, y), "Closet", font=font(SERIF, 36), fill=INK)
    y += 50
    y = chips_row(image, (22, y), ["All", "Top", "Bottom", "Dress", "Outerwear"], "All")
    items = [
        ("seed-cream-cardigan", "Cream cardigan", "SMART"),
        ("seed-light-jeans", "Light jeans", "CASUAL"),
        ("seed-ivory-blouse", "Ivory blouse", "SMART"),
        ("seed-camel-trousers", "Camel trousers", "SMART"),
        ("seed-black-blazer", "Black blazer", "SMART"),
        ("seed-white-sneakers", "White sneakers", "CASUAL"),
    ]
    gap = 12
    col_w = (image.width - 44 - gap) / 2
    row_h = 168
    for index, (token, title, formality) in enumerate(items):
        col = index % 2
        row = index // 2
        x = 22 + col * (col_w + gap)
        yy = y + row * (row_h + 8)
        if yy + row_h > tab - 8:
            break
        rounded(image, (x, yy, x + col_w, yy + row_h), 14, CARD, LINE, 2)
        still = thumb(token, int(col_w - 20))
        still.thumbnail((int(col_w - 24), 108), Image.Resampling.LANCZOS)
        image.paste(still, (int(x + (col_w - still.width) / 2), int(yy + 6)))
        draw.text((x + 10, yy + 118), title, font=font(SERIF, 16), fill=INK)
        draw.text((x + 10, yy + 140), formality, font=font(SANS_BOLD, 11), fill=MUTED)
    home_indicator(image)
    return image


def ui_journal() -> Image.Image:
    image = screen_base()
    tab = tab_bar(image, 3)
    draw = ImageDraw.Draw(image)
    y = 62
    draw.text((22, y), "WORN", font=font(SANS_BOLD, 13), fill=OX)
    y += 20
    draw.text((22, y), "Journal", font=font(SERIF, 36), fill=INK)
    y += 52
    draw.text((image.width / 2, y), "November 2026", font=font(SERIF, 22), fill=INK, anchor="mt")
    y += 36
    days = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
    cell = (image.width - 32) / 7
    for index, label in enumerate(days):
        draw.text((16 + cell * index + cell / 2, y), label, font=font(SANS_BOLD, 12), fill=MUTED, anchor="mt")
    y += 22
    number = 1
    marks = {2, 5, 8, 10}
    for row in range(5):
        for col in range(7):
            if number > 30:
                break
            x = 16 + col * cell
            yy = y + row * 46
            selected = number == 2
            rounded(image, (x + 2, yy, x + cell - 2, yy + 40), 8, INK if selected else CARD, None if selected else LINE, 1)
            draw.text((x + cell / 2, yy + 6), str(number), font=font(SERIF, 16), fill=CARD if selected else INK, anchor="mt")
            if number in marks:
                dot = (232, 186, 181) if selected else OX
                draw.ellipse((x + cell / 2 - 3, yy + 28, x + cell / 2 + 3, yy + 34), fill=dot)
            number += 1
    y += 5 * 46 + 8
    if y < tab - 150:
        rounded(image, (18, y, image.width - 18, tab - 12), 16, CARD, LINE, 2)
        draw.text((32, y + 12), "Monday 2 November", font=font(SERIF, 20), fill=INK)
        draw.text((32, y + 40), "DATE", font=font(SANS_BOLD, 12), fill=OX)
        tokens = ["seed-coral-dress", "seed-lavender-cardigan", "seed-nude-heels"]
        labels = ["Coral dress", "Lavender layer", "Heels"]
        tw = 96
        for index, token in enumerate(tokens):
            x = 32 + index * (tw + 10)
            tile(image, token, (x, y + 64, x + tw, y + 64 + tw))
            draw.text((x, y + 68 + tw), labels[index], font=font(SANS, 12), fill=INK)
    home_indicator(image)
    return image


def ui_weather() -> Image.Image:
    image = screen_base()
    tab_bar(image, 0)
    draw = ImageDraw.Draw(image)
    y = 64
    draw.text((22, y), "FOR TODAY", font=font(SANS_BOLD, 13), fill=OX)
    y += 22
    draw.text((22, y), "Weather", font=font(SERIF, 36), fill=INK)
    y += 52
    note = "The closet uses this choice. It does not need a network."
    for line in wrap(draw, note, font(SERIF_ITALIC, 16), image.width - 44):
        draw.text((22, y), line, font=font(SERIF_ITALIC, 16), fill=MUTED)
        y += 22
    y += 8
    draw.text((22, y), "WEATHER", font=font(SANS_BOLD, 12), fill=MUTED)
    y += 22
    y = chips_row(image, (22, y), ["Hot", "Warm", "Mild", "Cool", "Cold", "Wet"], "Mild")
    draw.text((22, y + 6), "Rain", font=font(SERIF, 22), fill=INK)
    rounded(image, (image.width - 86, y + 4, image.width - 22, y + 36), 16, (220, 214, 206))
    draw.ellipse((image.width - 82, y + 8, image.width - 58, y + 32), fill=CARD)
    y += 52
    draw.text((22, y), "SEASON", font=font(SANS_BOLD, 12), fill=MUTED)
    y += 22
    y = chips_row(image, (22, y), ["From the date", "Autumn", "Winter"], "From the date")
    draw.line((22, y, image.width - 22, y), fill=LINE, width=2)
    y += 16
    draw.text((22, y), "Apple Weather", font=font(SERIF, 22), fill=INK)
    rounded(image, (image.width - 86, y + 2, image.width - 22, y + 34), 16, (220, 214, 206))
    draw.ellipse((image.width - 82, y + 6, image.width - 58, y + 30), fill=CARD)
    y += 48
    copy = "Location is used only if you turn this on. If it is denied or offline, the choice above stays."
    for line in wrap(draw, copy, font(SANS, 15), image.width - 44):
        draw.text((22, y), line, font=font(SANS, 15), fill=MUTED)
        y += 20
    y += 12
    draw.text((22, y), "Using the weather you chose.", font=font(SERIF_ITALIC, 16), fill=INK)
    home_indicator(image)
    return image


def ui_atelier() -> Image.Image:
    image = screen_base()
    tab = tab_bar(image, 2)
    draw = ImageDraw.Draw(image)
    y = 62
    draw.text((22, y), "BY HAND", font=font(SANS_BOLD, 13), fill=OX)
    y += 20
    draw.text((22, y), "Atelier", font=font(SERIF, 36), fill=INK)
    y += 48
    draw.text((22, y), "A dress stands in for a top and a bottom.", font=font(SERIF_ITALIC, 15), fill=MUTED)
    y += 28
    rows = [
        ("TOP", "Blouse", "seed-ivory-blouse", ["seed-ivory-blouse", "seed-white-tee", "seed-navy-knit"]),
        ("BOTTOM", "Trousers", "seed-camel-trousers", ["seed-camel-trousers", "seed-light-jeans", "seed-charcoal-trousers"]),
        ("OUTERWEAR", "Blazer", "seed-black-blazer", ["seed-black-blazer", "seed-camel-coat", "seed-cream-cardigan"]),
        ("SHOES", "Loafers", "seed-black-loafers", ["seed-black-loafers", "seed-nude-heels", "seed-white-sneakers"]),
    ]
    for label, chosen, selected, options in rows:
        if y > tab - 170:
            break
        draw.text((22, y), label, font=font(SANS_BOLD, 12), fill=MUTED)
        draw.text((image.width - 22, y), chosen, font=font(SERIF, 15), fill=INK, anchor="rt")
        y += 28
        x = 22
        side = 78
        for token in options:
            border = OX if token == selected else LINE
            thick = 3 if token == selected else 2
            rounded(image, (x, y, x + side, y + side), 12, CARD, border, thick)
            still = thumb(token, side - 10)
            image.paste(still, (x + 5, y + 5))
            x += side + 8
        y += side + 14
        draw.line((22, y - 8, image.width - 22, y - 8), fill=LINE, width=1)
    if y < tab - 120:
        rounded(image, (22, y, image.width - 22, y + 48), 14, OX)
        draw.text((image.width / 2, y + 24), "Wear this today", font=font(SANS_BOLD, 18), fill=CARD, anchor="mm")
        y += 58
        rounded(image, (22, y, image.width - 22, y + 46), 14, CARD, INK, 2)
        draw.text((image.width / 2, y + 23), "Save look", font=font(SANS_BOLD, 18), fill=INK, anchor="mm")
    home_indicator(image)
    return image


SCREENS = {
    "today": ui_today,
    "closet": ui_closet,
    "journal": ui_journal,
    "weather": ui_weather,
    "atelier": ui_atelier,
}

SHOTS = [
    {
        "file": "01-today.png",
        "kind": "today",
        "model": "office",
        "focus": (0.48, 0.32),
        "headline": "Today, already\ndecided",
        "sub": "A work look from your closet",
    },
    {
        "file": "02-closet.png",
        "kind": "closet",
        "model": "weekend",
        "focus": (0.50, 0.34),
        "headline": "Every piece,\nin its place",
        "sub": "Tagged and kept on this iPhone",
    },
    {
        "file": "03-journal.png",
        "kind": "journal",
        "model": "evening",
        "focus": (0.50, 0.30),
        "headline": "A quiet record\nof what you wore",
        "sub": "The same look can wait",
    },
    {
        "file": "04-weather.png",
        "kind": "weather",
        "model": "winter",
        "focus": (0.50, 0.32),
        "headline": "Weather, then\nthe day",
        "sub": "Offline, unless you ask Apple",
    },
    {
        "file": "05-atelier.png",
        "kind": "atelier",
        "model": "office",
        "focus": (0.52, 0.36),
        "headline": "Or build the look\nyourself",
        "sub": "Piece by piece, from the closet",
    },
]


def render_shot(spec) -> Image.Image:
    image = canvas_background().convert("RGBA")
    draw = ImageDraw.Draw(image)
    margin = 48
    y = 46
    face = font(SERIF_BOLD, 68)
    for line in spec["headline"].split("\n"):
        draw.text((margin, y), line, font=face, fill=CREAM)
        y += 74
    draw.text((margin, y + 4), spec["sub"], font=font(SANS, 28), fill=(255, 228, 204))
    photo_box = (36, 248, SHOT[0] - 36, 1048)
    photo = cover(MODELS[spec["model"]], (photo_box[2] - photo_box[0], photo_box[3] - photo_box[1]), spec["focus"])
    mask = Image.new("L", photo.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, photo.width, photo.height), radius=36, fill=255)
    image.paste(photo, (photo_box[0], photo_box[1]), mask)
    screen = SCREENS[spec["kind"]]()
    framed = phone_frame(screen)
    shadow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    fx = (SHOT[0] - framed.width) // 2
    fy = SHOT[1] - framed.height - 36
    sd.rounded_rectangle((fx + 12, fy + 24, fx + framed.width + 8, fy + framed.height + 18), radius=78, fill=(60, 30, 16, 70))
    shadow = shadow.filter(ImageFilter.GaussianBlur(18))
    image.alpha_composite(shadow)
    image.alpha_composite(framed, (fx, fy))
    out = image.convert("RGB")
    assert out.size == SHOT and out.mode == "RGB"
    return out


def main():
    copy_models()
    build_garments()
    save_icons()
    out = ART / "screenshots" / "iphone-1206x2622"
    # Remove every previous size folder, including this one, then write only this size.
    shot_root = ART / "screenshots"
    if shot_root.exists():
        for child in shot_root.iterdir():
            if child.is_dir():
                shutil.rmtree(child)
            else:
                child.unlink()
    out.mkdir(parents=True)
    for spec in SHOTS:
        image = render_shot(spec)
        image.save(out / spec["file"], "PNG")
        print(spec["file"], image.size, image.mode)


if __name__ == "__main__":
    main()
