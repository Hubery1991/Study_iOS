#!/usr/bin/env python3
"""Compose Quillisse icons, seed garment stills, and App Store screenshots.

Screenshots place the supplied model portraits next to a drawing of the real
Today, Closet, Journal, weather, and Atelier screens. They are not Simulator
captures. This environment has no Xcode.
"""

from __future__ import annotations

import shutil
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / "AppStore"
ASSETS = ROOT / "App" / "Assets.xcassets"
ICON_DIR = ASSETS / "AppIcon.appiconset"
MODELS_SRC = Path("/home/ubuntu/.cursor/projects/workspace/uploads")
MODELS = {
    "casual": next(MODELS_SRC.glob("model-1-casual*.jpg")),
    "work": next(MODELS_SRC.glob("model-2-work*.jpg")),
    "evening": next(MODELS_SRC.glob("model-3-evening*.jpg")),
    "weekend": next(MODELS_SRC.glob("model-4-weekend*.jpg")),
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

SIZES = {
    "iphone-6.9": (1320, 2868),
    "iphone-6.7": (1284, 2778),
    "iphone-6.5": (1242, 2688),
    "ipad-13": (2064, 2752),
}

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


def draw_icon(size: int) -> Image.Image:
    image = Image.new("RGB", (size, size), PAPER)
    draw = ImageDraw.Draw(image)
    inset = int(size * 0.1)
    stroke = max(2, size // 48)
    draw.rounded_rectangle(
        (inset, inset, size - inset, size - inset),
        radius=int(size * 0.18),
        outline=OX,
        width=stroke,
    )
    face = font(SERIF_BOLD, int(size * 0.52))
    draw.text((size / 2, size * 0.46), "Q", font=face, fill=OX, anchor="mm")
    rule = int(size * 0.22)
    draw.line((size / 2 - rule, size * 0.74, size / 2 + rule, size * 0.74), fill=OX, width=max(2, size // 80))
    return image


def save_icons():
    master = draw_icon(1024)
    assert master.mode == "RGB"
    (ART / "icon").mkdir(parents=True, exist_ok=True)
    master.save(ART / "icon" / "AppIcon-1024.png")
    ICON_DIR.mkdir(parents=True, exist_ok=True)
    sizes = {
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
    for name, side in sizes.items():
        image = master if side == 1024 else master.resize((side, side), Image.Resampling.LANCZOS)
        image.save(ICON_DIR / name)
        if name == "icon-1024.png":
            image.save(ART / "icon" / name)


def tab_bar(base, y, width, selected, scale):
    rounded(base, (0, y, width, base.height), 0, (250, 246, 240, 255))
    draw = ImageDraw.Draw(base)
    draw.line((0, y, width, y), fill=LINE, width=max(1, int(2 * scale)))
    labels = [("Today", "sun"), ("Closet", "shirt"), ("Atelier", "grid"), ("Journal", "cal")]
    slot = width / 4
    for index, (label, _) in enumerate(labels):
        cx = slot * index + slot / 2
        color = OX if index == selected else MUTED
        face = font(SANS_BOLD if index == selected else SANS, 22 * scale)
        draw.text((cx, y + 62 * scale), label, font=face, fill=color, anchor="mm")
        # tiny mark
        r = 7 * scale
        mark_y = y + 28 * scale
        if index == 0:
            draw.ellipse((cx - r, mark_y - r, cx + r, mark_y + r), outline=color, width=max(2, int(2 * scale)))
        elif index == 1:
            draw.rounded_rectangle((cx - 10 * scale, mark_y - 8 * scale, cx + 10 * scale, mark_y + 10 * scale), radius=3, outline=color, width=max(2, int(2 * scale)))
        elif index == 2:
            draw.rectangle((cx - 10 * scale, mark_y - 8 * scale, cx - 2 * scale, mark_y + 8 * scale), outline=color, width=max(2, int(2 * scale)))
            draw.rectangle((cx + 2 * scale, mark_y - 8 * scale, cx + 10 * scale, mark_y + 8 * scale), outline=color, width=max(2, int(2 * scale)))
        else:
            draw.rounded_rectangle((cx - 10 * scale, mark_y - 8 * scale, cx + 10 * scale, mark_y + 10 * scale), radius=2, outline=color, width=max(2, int(2 * scale)))


def chips(base, xy, labels, selected, scale):
    x, y = xy
    face = font(SANS_BOLD, 24 * scale)
    draw = ImageDraw.Draw(base)
    for label in labels:
        pad = 22 * scale
        tw = draw.textlength(label, font=face)
        w = tw + pad * 2
        h = 52 * scale
        on = label == selected
        rounded(base, (x, y, x + w, y + h), h / 2, INK if on else CARD, None if on else LINE, max(1, int(2 * scale)))
        draw.text((x + w / 2, y + h / 2), label, font=face, fill=CARD if on else INK, anchor="mm")
        x += w + 12 * scale
    return y + 64 * scale


def piece_row(base, names, xy, tile, scale):
    x, y = xy
    label = font(SERIF, 22 * scale)
    small = font(SANS, 16 * scale)
    draw = ImageDraw.Draw(base)
    for name in names:
        still = thumb(name, int(tile))
        rounded(base, (x, y, x + tile, y + tile), 16 * scale, PAPER, LINE, max(1, int(2 * scale)))
        base.paste(still, (int(x + 6), int(y + 6)))
        title = {
            "seed-ivory-blouse": "Ivory blouse",
            "seed-camel-trousers": "Camel trousers",
            "seed-black-blazer": "Black blazer",
            "seed-black-loafers": "Black loafers",
            "seed-blush-scarf": "Blush scarf",
            "seed-white-tee": "White tee",
            "seed-olive-shorts": "Olive shorts",
            "seed-linen-shirt": "Linen shirt",
            "seed-white-sneakers": "Sneakers",
            "seed-coral-dress": "Coral dress",
            "seed-lavender-cardigan": "Lavender layer",
            "seed-nude-heels": "Nude heels",
            "seed-cream-cardigan": "Cream cardigan",
            "seed-light-jeans": "Light jeans",
            "seed-ivory-cami": "Ivory camisole",
            "seed-gold-hoops": "Gold hoops",
        }[name]
        line_y = y + tile + 6 * scale
        for line in wrap(draw, title, label, tile)[:2]:
            draw.text((x, line_y), line, font=label, fill=INK)
            line_y += label.size + 2
        x += tile + 16 * scale


def wordmark(base, center, scale):
    text(base, center, "QUILLISSE", font(SANS_BOLD, 22 * scale), INK, anchor="mm")


def draw_today(base, scale, top):
    width = base.width
    margin = 36 * scale
    y = top
    wordmark(base, (width / 2, y), scale)
    y += 36 * scale
    text(base, (margin, y), "WEDNESDAY", font(SANS_BOLD, 20 * scale), OX)
    y += 28 * scale
    text(base, (margin, y), "11 November", font(SERIF, 64 * scale), INK)
    y += 84 * scale
    y = chips(base, (margin, y), ["Work", "Casual", "Date", "Weekend", "Formal"], "Work", scale)
    y += 8 * scale
    box = (margin, y, width - margin, y + 92 * scale)
    rounded(base, box, 22 * scale, CARD, LINE, max(1, int(2 * scale)))
    draw = ImageDraw.Draw(base)
    draw.ellipse((margin + 24 * scale, y + 28 * scale, margin + 52 * scale, y + 56 * scale), outline=OX, width=max(2, int(3 * scale)))
    text(base, (margin + 70 * scale, y + 22 * scale), "Mild", font(SERIF, 32 * scale), INK)
    text(base, (margin + 70 * scale, y + 54 * scale), "Autumn · chosen on this device", font(SANS, 18 * scale), MUTED)
    text(base, (width - margin - 16 * scale, y + 46 * scale), "Change", font(SANS_BOLD, 22 * scale), OX, anchor="rm")
    y += 112 * scale
    card_bottom = base.height - 150 * scale
    shadow_card(base, (margin, y, width - margin, card_bottom), 28 * scale)
    text(base, (margin + 28 * scale, y + 24 * scale), "SUGGESTED", font(SANS_BOLD, 18 * scale), OX)
    text(base, (width - margin - 48 * scale, y + 18 * scale), "♡", font(SERIF, 40 * scale), OX)
    text(base, (margin + 28 * scale, y + 52 * scale), "Ivory blouse and\nCamel trousers", font(SERIF, 42 * scale), INK)
    text(base, (margin + 28 * scale, y + 168 * scale), "A light layer for a mild day.", font(SERIF_ITALIC, 24 * scale), MUTED)
    text(base, (margin + 28 * scale, y + 204 * scale), "Fits a work day.", font(SERIF_ITALIC, 24 * scale), MUTED)
    text(base, (margin + 28 * scale, y + 240 * scale), "Not worn in the last 7 days.", font(SERIF_ITALIC, 24 * scale), MUTED)
    tile = 150 * scale
    piece_row(
        base,
        ["seed-ivory-blouse", "seed-camel-trousers", "seed-black-blazer", "seed-black-loafers", "seed-blush-scarf"],
        (margin + 28 * scale, y + 290 * scale),
        tile,
        scale,
    )
    button = (margin + 28 * scale, card_bottom - 150 * scale, width - margin - 28 * scale, card_bottom - 70 * scale)
    rounded(base, button, 18 * scale, OX)
    text(base, ((button[0] + button[2]) / 2, (button[1] + button[3]) / 2), "Wear this today", font(SANS_BOLD, 28 * scale), CARD, anchor="mm")
    text(base, (width / 2, card_bottom - 36 * scale), "Another look", font(SANS_BOLD, 22 * scale), INK, anchor="mm")


def draw_closet(base, scale, top):
    width = base.width
    margin = 36 * scale
    y = top
    text(base, (margin, y), "WARDROBE", font(SANS_BOLD, 20 * scale), OX)
    y += 30 * scale
    text(base, (margin, y), "Closet", font(SERIF, 64 * scale), INK)
    y += 86 * scale
    y = chips(base, (margin, y), ["All", "Top", "Bottom", "Dress", "Outerwear"], "All", scale)
    # model band
    photo_h = 460 * scale
    photo = cover(MODELS["casual"], (int(width - margin * 2), int(photo_h)), (0.50, 0.20))
    mask = Image.new("L", photo.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, photo.width, photo.height), radius=28 * scale, fill=255)
    base.paste(photo, (int(margin), int(y)), mask)
    y += photo_h + 22 * scale
    names = [
        ("seed-cream-cardigan", "Cream cardigan", "SMART"),
        ("seed-light-jeans", "Light jeans", "CASUAL"),
        ("seed-ivory-blouse", "Ivory blouse", "SMART"),
        ("seed-camel-trousers", "Camel trousers", "SMART"),
        ("seed-black-blazer", "Black blazer", "SMART"),
        ("seed-white-sneakers", "White sneakers", "CASUAL"),
        ("seed-coral-dress", "Coral midi dress", "FORMAL"),
        ("seed-navy-knit", "Navy knit", "SMART"),
    ]
    gap = 18 * scale
    col_w = (width - margin * 2 - gap) / 2
    tile_h = 250 * scale
    draw = ImageDraw.Draw(base)
    for index, (token, title, formality) in enumerate(names):
        col = index % 2
        row = index // 2
        x = margin + col * (col_w + gap)
        yy = y + row * (tile_h + 92 * scale)
        if yy + tile_h > base.height - 160 * scale:
            break
        still = thumb(token, int(col_w - 8))
        rounded(base, (x, yy, x + col_w, yy + tile_h), 18 * scale, CARD, LINE, max(1, int(2 * scale)))
        still.thumbnail((int(col_w - 24), int(tile_h - 16)), Image.Resampling.LANCZOS)
        base.paste(still, (int(x + (col_w - still.width) / 2), int(yy + 8)))
        draw.text((x + 8, yy + tile_h + 6 * scale), title, font=font(SERIF, 26 * scale), fill=INK)
        draw.text((x + 8, yy + tile_h + 40 * scale), formality, font=font(SANS_BOLD, 16 * scale), fill=MUTED)


def draw_journal(base, scale, top):
    width = base.width
    margin = 36 * scale
    y = top
    text(base, (margin, y), "WORN", font(SANS_BOLD, 20 * scale), OX)
    y += 28 * scale
    text(base, (margin, y), "Journal", font(SERIF, 64 * scale), INK)
    y += 80 * scale
    text(base, (width / 2, y), "November 2026", font(SERIF, 36 * scale), INK, anchor="mt")
    y += 56 * scale
    days = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
    draw = ImageDraw.Draw(base)
    cell = (width - margin * 2) / 7
    for index, label in enumerate(days):
        draw.text((margin + cell * index + cell / 2, y), label, font=font(SANS_BOLD, 14 * scale), fill=MUTED, anchor="mt")
    y += 28 * scale
    # November 2026 starts Sunday. Marks on the 2nd, 5th, 8th, 10th. Selected 2.
    marks = {2, 5, 8, 10}
    number = 1
    for row in range(5):
        for col in range(7):
            if row == 0 and col < 0:
                continue
            if number > 30:
                break
            x = margin + col * cell
            yy = y + row * (78 * scale)
            selected = number == 2
            if selected:
                rounded(base, (x + 4, yy, x + cell - 4, yy + 70 * scale), 12 * scale, INK)
            else:
                rounded(base, (x + 4, yy, x + cell - 4, yy + 70 * scale), 12 * scale, CARD, LINE, 1)
            fill = CARD if selected else INK
            draw.text((x + cell / 2, yy + 16 * scale), str(number), font=font(SERIF, 24 * scale), fill=fill, anchor="mt")
            if number in marks:
                dot = OX if not selected else (232, 186, 181)
                draw.ellipse((x + cell / 2 - 4 * scale, yy + 50 * scale, x + cell / 2 + 4 * scale, yy + 58 * scale), fill=dot)
            number += 1
    y += 5 * 78 * scale + 10 * scale
    shadow_card(base, (margin, y, width - margin, base.height - 150 * scale), 24 * scale)
    text(base, (margin + 24 * scale, y + 20 * scale), "Monday 2 November", font(SERIF, 32 * scale), INK)
    text(base, (margin + 24 * scale, y + 68 * scale), "DATE", font(SANS_BOLD, 18 * scale), OX)
    photo = cover(MODELS["evening"], (int(280 * scale), int(360 * scale)), (0.48, 0.36))
    mask = Image.new("L", photo.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, photo.width, photo.height), radius=18 * scale, fill=255)
    base.paste(photo, (int(margin + 24 * scale), int(y + 110 * scale)), mask)
    piece_row(
        base,
        ["seed-coral-dress", "seed-lavender-cardigan", "seed-nude-heels"],
        (margin + 320 * scale, y + 120 * scale),
        150 * scale,
        scale,
    )
    text(base, (margin + 24 * scale, base.height - 200 * scale), "Remove this day", font(SANS_BOLD, 20 * scale), MUTED)


def draw_weather(base, scale, top):
    width = base.width
    margin = 40 * scale
    y = top
    text(base, (margin, y), "For today", font(SANS_BOLD, 20 * scale), OX)
    y += 34 * scale
    text(base, (margin, y), "Weather", font(SERIF, 60 * scale), INK)
    y += 80 * scale
    note = "The closet uses this choice when it builds a look. It does not need a network."
    draw = ImageDraw.Draw(base)
    for line in wrap(draw, note, font(SERIF_ITALIC, 26 * scale), width - margin * 2):
        draw.text((margin, y), line, font=font(SERIF_ITALIC, 26 * scale), fill=MUTED)
        y += 34 * scale
    y += 16 * scale
    text(base, (margin, y), "WEATHER", font(SANS_BOLD, 18 * scale), MUTED)
    y += 32 * scale
    y = chips(base, (margin, y), ["Hot", "Warm", "Mild", "Cool", "Cold", "Wet"], "Mild", scale)
    y += 10 * scale
    text(base, (margin, y), "Rain", font(SERIF, 32 * scale), INK)
    # switch off
    sw = (width - margin - 90 * scale, y, width - margin, y + 48 * scale)
    rounded(base, sw, 24 * scale, (220, 214, 206))
    draw.ellipse((sw[0] + 4 * scale, sw[1] + 4 * scale, sw[0] + 40 * scale, sw[3] - 4 * scale), fill=CARD)
    y += 70 * scale
    text(base, (margin, y), "SEASON", font(SANS_BOLD, 18 * scale), MUTED)
    y += 32 * scale
    y = chips(base, (margin, y), ["From the date", "Spring", "Summer", "Autumn", "Winter"], "From the date", scale)
    y += 20 * scale
    draw.line((margin, y, width - margin, y), fill=LINE, width=max(1, int(2 * scale)))
    y += 24 * scale
    text(base, (margin, y), "Apple Weather", font(SERIF, 34 * scale), INK)
    sw = (width - margin - 90 * scale, y, width - margin, y + 48 * scale)
    rounded(base, sw, 24 * scale, (220, 214, 206))
    draw.ellipse((sw[0] + 4 * scale, sw[1] + 4 * scale, sw[0] + 40 * scale, sw[3] - 4 * scale), fill=CARD)
    y += 70 * scale
    copy = "Uses location only while you allow it, then keeps a band such as mild or rain. If it is denied or offline, the choice above stays."
    for line in wrap(draw, copy, font(SANS, 22 * scale), width - margin * 2):
        draw.text((margin, y), line, font=font(SANS, 22 * scale), fill=MUTED)
        y += 30 * scale
    y += 18 * scale
    text(base, (margin, y), "Using the weather you chose. No location is involved.", font(SERIF_ITALIC, 24 * scale), INK)


def draw_atelier(base, scale, top):
    width = base.width
    margin = 36 * scale
    y = top
    text(base, (margin, y), "BY HAND", font(SANS_BOLD, 20 * scale), OX)
    y += 28 * scale
    text(base, (margin, y), "Atelier", font(SERIF, 64 * scale), INK)
    y += 78 * scale
    text(base, (margin, y), "A dress stands in for a top and a bottom.", font(SERIF_ITALIC, 24 * scale), MUTED)
    y += 48 * scale
    rows = [
        ("TOP", "White tee", "seed-white-tee", ["seed-white-tee", "seed-ivory-blouse", "seed-ivory-cami", "seed-navy-knit"]),
        ("BOTTOM", "Olive shorts", "seed-olive-shorts", ["seed-olive-shorts", "seed-light-jeans", "seed-camel-trousers"]),
        ("DRESS", "None", None, ["seed-coral-dress"]),
        ("OUTERWEAR", "Blue linen shirt", "seed-linen-shirt", ["seed-linen-shirt", "seed-cream-cardigan", "seed-black-blazer"]),
        ("SHOES", "White sneakers", "seed-white-sneakers", ["seed-white-sneakers", "seed-black-loafers", "seed-nude-heels"]),
    ]
    draw = ImageDraw.Draw(base)
    for label, chosen, selected, options in rows:
        text(base, (margin, y), label, font(SANS_BOLD, 16 * scale), MUTED)
        text(base, (width - margin, y), chosen, font(SERIF, 24 * scale), INK, anchor="rt")
        y += 34 * scale
        x = margin
        tile = 110 * scale
        for token in options:
            still = thumb(token, int(tile - 8))
            border = OX if token == selected else LINE
            thick = 4 if token == selected else 2
            rounded(base, (x, y, x + tile, y + tile), 14 * scale, CARD, border, max(1, int(thick * scale)))
            base.paste(still.resize((int(tile - 16), int(tile - 16))), (int(x + 8), int(y + 8)))
            x += tile + 12 * scale
        y += tile + 18 * scale
        draw.line((margin, y - 8 * scale, width - margin, y - 8 * scale), fill=LINE, width=1)
    y += 8 * scale
    limit = base.height - 300 * scale
    if y > limit:
        y = limit
    rounded(base, (margin, y, width - margin, y + 68 * scale), 16 * scale, OX)
    text(base, (width / 2, y + 34 * scale), "Wear this today", font(SANS_BOLD, 26 * scale), CARD, anchor="mm")
    y += 82 * scale
    rounded(base, (margin, y, width - margin, y + 64 * scale), 16 * scale, CARD, INK, max(1, int(2 * scale)))
    text(base, (width / 2, y + 32 * scale), "Save look", font(SANS_BOLD, 26 * scale), INK, anchor="mm")


def headline_block(base, lines, sub, x, y, scale, fill=WHITE, subfill=None):
    face = font(SERIF, 78 * scale)
    draw = ImageDraw.Draw(base)
    for line in lines:
        draw.text((x, y), line, font=face, fill=fill)
        y += 86 * scale
    if sub:
        draw.text((x, y + 6 * scale), sub, font=font(SANS, 28 * scale), fill=subfill or fill)
    return y


def render_phone(size, kind):
    width, height = size
    scale = width / 1320
    image = Image.new("RGBA", size, PAPER + (255,))
    if kind == "today":
        photo_h = int(height * 0.40)
        photo = cover(MODELS["work"], (width, photo_h), (0.55, 0.30))
        image.paste(photo, (0, 0))
        scrim = Image.new("RGBA", (width, photo_h), (0, 0, 0, 0))
        ImageDraw.Draw(scrim).rectangle((0, 0, width, photo_h), fill=(20, 14, 10, 70))
        image.alpha_composite(scrim)
        headline_block(image, ["Today, already", "decided"], "A work look from your closet", 48 * scale, 150 * scale, scale)
        panel_top = photo_h - 30 * scale
        rounded(image, (0, panel_top, width, height), 36 * scale, PAPER)
        draw_today(image, scale, panel_top + 28 * scale)
        tab_bar(image, height - 120 * scale, width, 0, scale)
    elif kind == "closet":
        headline_block(image, ["Every piece,", "in its place"], "Tagged, photographed, kept here", 48 * scale, 120 * scale, scale, INK, MUTED)
        draw_closet(image, scale, 360 * scale)
        tab_bar(image, height - 120 * scale, width, 1, scale)
    elif kind == "journal":
        headline_block(image, ["A quiet record", "of what you wore"], "The same look waits its turn", 48 * scale, 110 * scale, scale, INK, MUTED)
        draw_journal(image, scale, 340 * scale)
        tab_bar(image, height - 120 * scale, width, 3, scale)
    elif kind == "weather":
        photo_h = int(height * 0.34)
        photo = cover(MODELS["weekend"], (width, photo_h), (0.5, 0.28))
        image.paste(photo, (0, 0))
        scrim = Image.new("RGBA", (width, photo_h), (20, 16, 12, 60))
        image.alpha_composite(scrim)
        headline_block(image, ["Occasion, then", "the weather"], "Offline if you want it that way", 48 * scale, 130 * scale, scale)
        panel_top = photo_h - 24 * scale
        rounded(image, (0, panel_top, width, height), 36 * scale, PAPER)
        draw_weather(image, scale, panel_top + 36 * scale)
        tab_bar(image, height - 120 * scale, width, 0, scale)
    else:
        headline_block(image, ["Or build the look", "yourself"], "Pick each piece from the closet", 48 * scale, 100 * scale, scale, INK, MUTED)
        photo = cover(MODELS["weekend"], (int(250 * scale), int(320 * scale)), (0.5, 0.30))
        mask = Image.new("L", photo.size, 0)
        ImageDraw.Draw(mask).rounded_rectangle((0, 0, photo.width, photo.height), radius=22 * scale, fill=255)
        image.paste(photo, (int(width - 48 * scale - photo.width), int(90 * scale)), mask)
        draw_atelier(image, scale, 430 * scale)
        tab_bar(image, height - 120 * scale, width, 2, scale)
    return image.convert("RGB")


def render_ipad(size, kind):
    width, height = size
    image = Image.new("RGBA", size, PAPER + (255,))
    photo_w = int(width * 0.42)
    model = {
        "today": "work",
        "closet": "casual",
        "journal": "evening",
        "weather": "weekend",
        "atelier": "weekend",
    }[kind]
    focus = (0.52, 0.38) if kind != "closet" else (0.5, 0.34)
    photo = cover(MODELS[model], (photo_w, height), focus)
    image.paste(photo, (0, 0))
    scrim = Image.new("RGBA", (photo_w, height), (0, 0, 0, 0))
    gradient = ImageDraw.Draw(scrim)
    for x in range(photo_w):
        alpha = int(max(0, (x - photo_w * 0.55) / (photo_w * 0.45) * 90))
        gradient.line((x, 0, x, height), fill=(243, 238, 230, alpha))
    image.alpha_composite(scrim)
    # right panel
    panel = Image.new("RGBA", (width - photo_w + 40, height), PAPER + (255,))
    scale = (width - photo_w) / 1100
    headlines = {
        "today": (["Today, already", "decided"], "A work look from your closet"),
        "closet": (["Every piece,", "in its place"], "Tagged, photographed, kept here"),
        "journal": (["A quiet record", "of what you wore"], "The same look waits its turn"),
        "weather": (["Occasion, then", "the weather"], "Offline if you want it that way"),
        "atelier": (["Or build the look", "yourself"], "Pick each piece from the closet"),
    }
    lines, sub = headlines[kind]
    headline_block(panel, lines, sub, 48, 80, scale * 0.92, INK, MUTED)
    body_top = 340 * scale
    if kind == "today":
        draw_today(panel, scale * 0.92, body_top)
    elif kind == "closet":
        draw_closet(panel, scale * 0.86, body_top)
    elif kind == "journal":
        draw_journal(panel, scale * 0.82, body_top)
    elif kind == "weather":
        draw_weather(panel, scale * 0.9, body_top)
    else:
        draw_atelier(panel, scale * 0.82, body_top)
    image.alpha_composite(panel, (photo_w - 40, 0))
    return image.convert("RGB")


def copy_models():
    dest = ART / "models"
    dest.mkdir(parents=True, exist_ok=True)
    names = {
        "casual": "model-1-casual.jpg",
        "work": "model-2-work.jpg",
        "evening": "model-3-evening.jpg",
        "weekend": "model-4-weekend.jpg",
    }
    for key, filename in names.items():
        shutil.copyfile(MODELS[key], dest / filename)


def main():
    copy_models()
    build_garments()
    save_icons()
    scenes = ["today", "closet", "journal", "weather", "atelier"]
    files = {
        "today": "01-todays-look.png",
        "closet": "02-closet.png",
        "journal": "03-journal.png",
        "weather": "04-weather.png",
        "atelier": "05-atelier.png",
    }
    for folder, size in SIZES.items():
        out = ART / "screenshots" / folder
        out.mkdir(parents=True, exist_ok=True)
        for kind in scenes:
            image = render_ipad(size, kind) if folder == "ipad-13" else render_phone(size, kind)
            assert image.size == size, (image.size, size)
            assert image.mode == "RGB"
            image.save(out / files[kind], "PNG")
            print(folder, files[kind], image.size)


if __name__ == "__main__":
    main()
