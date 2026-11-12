#!/usr/bin/env python3
"""Resize the approved Sheenlisse icon and compose 1206×2622 marketing screenshots.

The icon artwork and the model portraits are used as given. This script only
scales the icon and places the portraits inside a phone mockup. It does not
redraw people or the icon.
"""

from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / "AppStore"
MODELS = ART / "models"
ICON_DIR = ART / "icon"
APP_ICON = ROOT / "App" / "Assets.xcassets" / "AppIcon.appiconset"
WEB = ART / "website"
SOURCE_ICON = ICON_DIR / "sheenlisse-icon.jpg"

SERIF = "/usr/share/fonts/truetype/liberation/LiberationSerif-Bold.ttf"
SANS = "/usr/share/fonts/truetype/macos/Inter-Regular.ttf"
SANS_MED = "/usr/share/fonts/truetype/macos/Inter-Medium.ttf"
SANS_SEMI = "/usr/share/fonts/truetype/macos/Inter-SemiBold.ttf"
SANS_BOLD = "/usr/share/fonts/truetype/macos/Inter-Bold.ttf"

IVORY = (251, 246, 242)
CHAMPAGNE = (243, 228, 212)
ROSE = (201, 107, 120)
GOLD = (184, 137, 106)
PLUM = (60, 36, 48)
INK = (37, 22, 28)
LINE = (230, 213, 207)
WHITE = (255, 255, 255)
FRAME = (28, 28, 30)

CANVAS = (1206, 2622)
ICON_EDGES = (20, 29, 40, 58, 60, 76, 80, 87, 120, 152, 167, 180, 1024)

LIPS = [
    ("Petal", "E7A0A8"),
    ("Rosewater", "D9899A"),
    ("Coral", "E36B55"),
    ("Nude Mauve", "C48B8E"),
    ("Berry", "A63D5C"),
    ("Deep Red", "8E1E2D"),
    ("Brick", "A3473A"),
    ("Plum", "7A3058"),
]
BLUSH = [
    ("Baby Pink", "F2B6C0"),
    ("Peach", "F0A48A"),
    ("Rose", "E48B9A"),
    ("Apricot", "E8A07A"),
    ("Terracotta", "C4745A"),
    ("Plum Flush", "C46B8A"),
]
EYES = [
    ("Champagne", "E6C8A4"),
    ("Soft Taupe", "C4A894"),
    ("Rose", "D9A0AE"),
    ("Smoky Brown", "6E5346"),
    ("Violet", "8E74B8"),
    ("Bronze", "A67848"),
]
REGIONS = {"Lips": LIPS, "Blush": BLUSH, "Eyes": EYES, "Liner": [("Soft Brown", "6B4A3A")], "Brows": [("Taupe", "A0846C")]}
LOOKS = ["Natural", "Evening", "Vibrant", "Fresh"]

SCENES = [
    {
        "file": "01-mirror.png",
        "model": "model-finished.jpg",
        "focus": (0.36, 0.30),
        "look": "Natural",
        "region": "Lips",
        "shade": "Petal",
        "shades": LIPS,
        "intensity": 62,
        "finish": "SATIN",
        "headline": "Color, live\non your face",
        "sub": "Lipstick, blush, eyes, liner, and brows.",
        "compare": False,
    },
    {
        "file": "02-lipstick.png",
        "model": "model-lipstick.jpg",
        "focus": (0.50, 0.32),
        "look": "Natural",
        "region": "Lips",
        "shade": "Rosewater",
        "shades": LIPS,
        "intensity": 70,
        "finish": "SATIN",
        "headline": "A pink lip,\nin the mirror",
        "sub": "Eight shades, from petal to plum.",
        "compare": False,
    },
    {
        "file": "03-blush.png",
        "model": "model-blush.jpg",
        "focus": (0.55, 0.36),
        "look": "Fresh",
        "region": "Blush",
        "shade": "Baby Pink",
        "shades": BLUSH,
        "intensity": 55,
        "finish": "SATIN",
        "headline": "Blush, just\nwhere it belongs",
        "sub": "Soft, or a little stronger.",
        "compare": False,
    },
    {
        "file": "04-eyes.png",
        "model": "model-eyeshadow.jpg",
        "focus": (0.40, 0.32),
        "look": "Evening",
        "region": "Eyes",
        "shade": "Soft Taupe",
        "shades": EYES,
        "intensity": 48,
        "finish": "MATTE",
        "headline": "Eyes, without\nthe guesswork",
        "sub": "Shadow, liner, and brows together.",
        "compare": False,
    },
    {
        "file": "05-compare.png",
        "model": "model-finished.jpg",
        "focus": (0.36, 0.30),
        "look": "Vibrant",
        "region": "Lips",
        "shade": "Coral",
        "shades": LIPS,
        "intensity": 78,
        "finish": "SATIN",
        "headline": "Before on the left.\nColor on the right.",
        "sub": "Drag the line. Nothing is uploaded.",
        "compare": True,
        "split": 0.46,
    },
]


def font(path, size):
    return ImageFont.truetype(path, max(8, int(size)))


def rgb(value):
    value = value.lstrip("#")
    return tuple(int(value[i : i + 2], 16) for i in (0, 2, 4))


def cover(path, size, focus):
    image = Image.open(path).convert("RGB")
    scale = max(size[0] / image.width, size[1] / image.height)
    resized = image.resize((round(image.width * scale), round(image.height * scale)), Image.Resampling.LANCZOS)
    left = int((resized.width - size[0]) * focus[0])
    top = int((resized.height - size[1]) * focus[1])
    left = max(0, min(left, resized.width - size[0]))
    top = max(0, min(top, resized.height - size[1]))
    return resized.crop((left, top, left + size[0], top + size[1]))


def text_size(draw, text, face):
    box = draw.textbbox((0, 0), text, font=face)
    return box[2] - box[0], box[3] - box[1]


def rounded(draw, box, radius, fill, outline=None, width=1):
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)


def save_icons():
    master = Image.open(SOURCE_ICON).convert("RGB")
    if master.size != (1024, 1024):
        master = master.resize((1024, 1024), Image.Resampling.LANCZOS)
    ICON_DIR.mkdir(parents=True, exist_ok=True)
    APP_ICON.mkdir(parents=True, exist_ok=True)
    WEB.mkdir(parents=True, exist_ok=True)
    master.save(ICON_DIR / "AppIcon-1024.png", "PNG")
    master.save(APP_ICON / "icon-1024.png", "PNG")
    for edge in ICON_EDGES:
        if edge == 1024:
            continue
        master.resize((edge, edge), Image.Resampling.LANCZOS).save(APP_ICON / f"icon-{edge}.png", "PNG")
    master.resize((32, 32), Image.Resampling.LANCZOS).save(WEB / "favicon-32.png", "PNG")
    master.resize((180, 180), Image.Resampling.LANCZOS).save(WEB / "apple-touch-icon.png", "PNG")


def vertical_mask(height, stops):
    column = Image.new("L", (1, height))
    pix = column.load()
    for y in range(height):
        t = y / max(1, height - 1)
        alpha = stops[-1][1]
        for index in range(len(stops) - 1):
            t0, a0 = stops[index]
            t1, a1 = stops[index + 1]
            if t0 <= t <= t1:
                mix = 0 if t1 == t0 else (t - t0) / (t1 - t0)
                alpha = int(a0 + (a1 - a0) * mix)
                break
        pix[0, y] = alpha
    return column


def scrim(base):
    width, height = base.size
    top = Image.new("RGBA", (width, height), (32, 18, 24, 255))
    top_mask = vertical_mask(height, [(0.0, 150), (0.22, 30), (0.36, 0), (1.0, 0)]).resize((width, height))
    bottom = Image.new("RGBA", (width, height), (24, 12, 18, 255))
    bottom_mask = vertical_mask(height, [(0.0, 0), (0.58, 0), (1.0, 70)]).resize((width, height))
    out = base.convert("RGBA")
    out.paste(top, (0, 0), top_mask)
    out.paste(bottom, (0, 0), bottom_mask)
    return out


def icon_button(image, center, radius, kind):
    overlay = Image.new("RGBA", image.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    cx, cy = center
    draw.ellipse([cx - radius, cy - radius, cx + radius, cy + radius], fill=(255, 255, 255, 64))
    ink = (255, 255, 255, 255)
    stroke = max(2, radius // 7)
    if kind == "spark":
        draw.line([(cx, cy - radius * 0.42), (cx, cy + radius * 0.42)], fill=ink, width=stroke)
        draw.line([(cx - radius * 0.42, cy), (cx + radius * 0.42, cy)], fill=ink, width=stroke)
    elif kind == "heart":
        r = radius * 0.26
        draw.ellipse([cx - r * 2.0, cy - r * 1.1, cx + 1, cy + r * 0.55], outline=ink, width=stroke)
        draw.ellipse([cx - 1, cy - r * 1.1, cx + r * 2.0, cy + r * 0.55], outline=ink, width=stroke)
        draw.line([(cx - r * 1.55, cy + r * 0.2), (cx, cy + r * 1.65)], fill=ink, width=stroke)
        draw.line([(cx, cy + r * 1.65), (cx + r * 1.55, cy + r * 0.2)], fill=ink, width=stroke)
    else:
        draw.ellipse(
            [cx - radius * 0.36, cy - radius * 0.36, cx + radius * 0.36, cy + radius * 0.36],
            outline=ink,
            width=stroke,
        )
        draw.ellipse([cx - 2, cy - radius * 0.16, cx + 2, cy - radius * 0.05], fill=ink)
    image.alpha_composite(overlay)


def draw_deck(canvas, scale, scene, box):
    draw = ImageDraw.Draw(canvas)
    x0, y0, x1, y1 = box
    rounded(draw, box, int(26 * scale), IVORY)
    pad = int(14 * scale)
    x = x0 + pad
    width = x1 - x0 - pad * 2
    y = y0 + pad
    draw.text((x, y), "LOOKS", font=font(SANS_BOLD, 11 * scale), fill=(120, 90, 98))
    y += int(20 * scale)
    chip_font = font(SANS_SEMI, 14 * scale)
    cx = x
    for name in LOOKS:
        tw, _ = text_size(draw, name, chip_font)
        chip_w = tw + int(24 * scale)
        selected = name == scene["look"]
        rounded(
            draw,
            [cx, y, cx + chip_w, y + int(32 * scale)],
            int(16 * scale),
            ROSE if selected else WHITE,
            ROSE if selected else LINE,
            1,
        )
        draw.text((cx + int(12 * scale), y + int(7 * scale)), name, font=chip_font, fill=WHITE if selected else PLUM)
        cx += chip_w + int(7 * scale)
    y += int(44 * scale)
    regions = ["Lips", "Blush", "Eyes", "Liner", "Brows"]
    slot = width / len(regions)
    for index, name in enumerate(regions):
        selected = name == scene["region"]
        face = font(SANS_BOLD if selected else SANS_MED, 13 * scale)
        tw, _ = text_size(draw, name, face)
        tx = x + index * slot + (slot - tw) / 2
        draw.text((tx, y), name, font=face, fill=PLUM if selected else (140, 110, 118))
        if selected:
            draw.rectangle([tx, y + int(20 * scale), tx + tw, y + int(23 * scale)], fill=GOLD)
    y += int(34 * scale)
    draw.text((x, y), scene["shade"], font=font(SERIF, 22 * scale), fill=INK)
    finish = scene["finish"]
    fw, _ = text_size(draw, finish, font(SANS_BOLD, 11 * scale))
    draw.text((x1 - pad - fw, y + int(8 * scale)), finish, font=font(SANS_BOLD, 11 * scale), fill=GOLD)
    y += int(38 * scale)
    diameter = int(40 * scale)
    gap = int(10 * scale)
    sx = x
    for shade_name, hex_color in scene["shades"]:
        if sx + diameter > x1 - pad + 2:
            break
        selected = shade_name == scene["shade"]
        draw.ellipse(
            [sx, y, sx + diameter, y + diameter],
            fill=rgb(hex_color),
            outline=GOLD if selected else WHITE,
            width=int(3 * scale) if selected else max(1, int(2 * scale)),
        )
        sx += diameter + gap
    y += diameter + int(16 * scale)
    draw.text((x, y), "Intensity", font=font(SANS_SEMI, 14 * scale), fill=PLUM)
    percent = f"{scene['intensity']}%"
    percent_font = font(SANS_BOLD, 14 * scale)
    pw, _ = text_size(draw, percent, percent_font)
    draw.text((x1 - pad - pw, y), percent, font=percent_font, fill=ROSE)
    toggle_w = int(42 * scale)
    toggle_h = int(24 * scale)
    toggle_x = x1 - pad - pw - int(12 * scale) - toggle_w
    rounded(draw, [toggle_x, y - int(2 * scale), toggle_x + toggle_w, y - int(2 * scale) + toggle_h], toggle_h / 2, ROSE)
    knob = int(18 * scale)
    draw.ellipse(
        [toggle_x + toggle_w - knob - int(3 * scale), y + int(1 * scale), toggle_x + toggle_w - int(3 * scale), y + 1 * scale + knob],
        fill=WHITE,
    )
    y += int(32 * scale)
    track_h = max(4, int(6 * scale))
    draw.rounded_rectangle([x, y, x1 - pad, y + track_h], radius=track_h / 2, fill=(232, 214, 210))
    fill_to = x + (x1 - pad - x) * (scene["intensity"] / 100)
    draw.rounded_rectangle([x, y, fill_to, y + track_h], radius=track_h / 2, fill=ROSE)
    knob_r = int(10 * scale)
    draw.ellipse(
        [fill_to - knob_r, y + track_h / 2 - knob_r, fill_to + knob_r, y + track_h / 2 + knob_r],
        fill=WHITE,
        outline=ROSE,
        width=max(1, int(scale)),
    )
    y += int(28 * scale)
    labels = [("Compare", scene["compare"]), ("Save", False), ("Capture", False)]
    button_w = (width - int(14 * scale)) / 3
    for index, (title, active) in enumerate(labels):
        bx = x + index * (button_w + int(7 * scale))
        rounded(draw, [bx, y, bx + button_w, y + int(48 * scale)], int(14 * scale), ROSE if active else CHAMPAGNE)
        face = font(SANS_SEMI, 13 * scale)
        tw, _ = text_size(draw, title, face)
        draw.text((bx + (button_w - tw) / 2, y + int(14 * scale)), title, font=face, fill=WHITE if active else PLUM)
    return y + int(48 * scale)


def render_screen(size, scene):
    photo = cover(MODELS / scene["model"], size, scene["focus"])
    if scene["compare"]:
        cut = int(size[0] * scene["split"])
        left = ImageEnhance.Color(photo.crop((0, 0, cut, size[1])).convert("L").convert("RGB")).enhance(0.2)
        photo.paste(left, (0, 0))
    image = scrim(photo)
    scale = size[0] / 390
    draw = ImageDraw.Draw(image)
    island_w = int(size[0] * 0.29)
    island_h = int(size[0] * 0.088)
    island_x = (size[0] - island_w) / 2
    island_y = int(size[0] * 0.028)
    rounded(draw, [island_x, island_y, island_x + island_w, island_y + island_h], island_h / 2, (0, 0, 0))
    draw.text((int(22 * scale), island_y + int(6 * scale)), "9:41", font=font(SANS_SEMI, 15 * scale), fill=WHITE)

    bar_y = island_y + island_h + int(14 * scale)
    draw.text((int(18 * scale), bar_y), "Sheenlisse", font=font(SERIF, 26 * scale), fill=WHITE)
    pill = "TrueDepth"
    pill_font = font(SANS_BOLD, 12 * scale)
    pw, _ = text_size(draw, pill, pill_font)
    radius = int(15 * scale)
    icons_w = radius * 2 * 3 + int(8 * scale) * 2
    right = size[0] - int(16 * scale)
    icon_x = right - icons_w
    pill_w = pw + int(22 * scale)
    pill_h = int(28 * scale)
    pill_x = icon_x - int(10 * scale) - pill_w
    overlay = Image.new("RGBA", image.size, (0, 0, 0, 0))
    ImageDraw.Draw(overlay).rounded_rectangle(
        [pill_x, bar_y + int(2 * scale), pill_x + pill_w, bar_y + int(2 * scale) + pill_h],
        radius=pill_h / 2,
        fill=(255, 255, 255, 70),
    )
    image.alpha_composite(overlay)
    ImageDraw.Draw(image).text((pill_x + int(11 * scale), bar_y + int(8 * scale)), pill, font=pill_font, fill=WHITE)
    for index, kind in enumerate(("spark", "heart", "info")):
        icon_button(image, (icon_x + radius + index * (radius * 2 + int(8 * scale)), bar_y + int(16 * scale)), radius, kind)

    margin = int(12 * scale)
    deck_h = int(372 * scale)
    deck_top = size[1] - margin - deck_h
    if scene["compare"]:
        cut = int(size[0] * scene["split"])
        draw = ImageDraw.Draw(image)
        draw.line([(cut, int(size[1] * 0.34)), (cut, deck_top - int(8 * scale))], fill=WHITE, width=max(3, int(2 * scale)))
        r = int(16 * scale)
        cy = int(size[1] * 0.48)
        draw.ellipse([cut - r, cy - r, cut + r, cy + r], fill=IVORY, outline=GOLD, width=max(2, int(scale)))
        label = font(SANS_BOLD, 13 * scale)
        for text, cx in (("Before", cut * 0.5), ("After", cut + (size[0] - cut) * 0.5)):
            tw, th = text_size(draw, text, label)
            box = [cx - tw / 2 - 12, int(size[1] * 0.36), cx + tw / 2 + 12, int(size[1] * 0.36) + th + 12]
            if box[0] < 8 or box[2] > size[0] - 8:
                continue
            chip = Image.new("RGBA", image.size, (0, 0, 0, 0))
            ImageDraw.Draw(chip).rounded_rectangle(box, radius=14, fill=(20, 12, 16, 150))
            image.alpha_composite(chip)
            ImageDraw.Draw(image).text((box[0] + 12, box[1] + 5), text, font=label, fill=WHITE)
    draw_deck(image, scale, scene, [margin, deck_top, size[0] - margin, size[1] - margin])
    # Clip the screen to its rounded rectangle by masking later in the phone.
    return image.convert("RGBA")


def paste_rounded(base, sprite, box, radius):
    x0, y0, x1, y1 = [int(v) for v in box]
    sprite = sprite.resize((x1 - x0, y1 - y0), Image.Resampling.LANCZOS)
    mask = Image.new("L", sprite.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, sprite.size[0], sprite.size[1]], radius=radius, fill=255)
    base.paste(sprite.convert("RGB"), (x0, y0), mask)


def render_shot(scene):
    canvas = Image.new("RGB", CANVAS, (248, 228, 226))
    draw = ImageDraw.Draw(canvas)
    for y in range(CANVAS[1]):
        t = y / (CANVAS[1] - 1)
        color = tuple(int(a + (b - a) * t) for a, b in zip((248, 226, 224), (243, 214, 196)))
        draw.line([(0, y), (CANVAS[0], y)], fill=color)

    headline = font(SERIF, 72)
    sub = font(SANS_MED, 28)
    y = 78
    for line in scene["headline"].split("\n"):
        draw.text((64, y), line, font=headline, fill=PLUM)
        y += 84
    draw.text((68, y + 6), scene["sub"], font=sub, fill=(122, 84, 96))

    phone_h = 1988
    phone_w = int(phone_h * 0.482)
    px = (CANVAS[0] - phone_w) // 2
    py = 360
    bezel = 16
    radius = 78
    shadow = Image.new("RGBA", CANVAS, (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle(
        [px + 8, py + 18, px + phone_w + 8, py + phone_h + 18],
        radius=radius,
        fill=(80, 40, 48, 55),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(18))
    canvas = canvas.convert("RGBA")
    canvas.alpha_composite(shadow)
    draw = ImageDraw.Draw(canvas)
    rounded(draw, [px, py, px + phone_w, py + phone_h], radius, FRAME)
    # Side buttons.
    draw.rounded_rectangle([px - 4, py + 280, px + 2, py + 360], radius=2, fill=(54, 54, 58))
    draw.rounded_rectangle([px - 4, py + 390, px + 2, py + 490], radius=2, fill=(54, 54, 58))
    draw.rounded_rectangle([px + phone_w - 2, py + 340, px + phone_w + 4, py + 470], radius=2, fill=(54, 54, 58))

    screen_box = [px + bezel, py + bezel, px + phone_w - bezel, py + phone_h - bezel]
    screen = render_screen((screen_box[2] - screen_box[0], screen_box[3] - screen_box[1]), scene)
    paste_rounded(canvas, screen, screen_box, radius - 18)
    return canvas.convert("RGB")


def main():
    save_icons()
    out = ART / "screenshots"
    out.mkdir(parents=True, exist_ok=True)
    for scene in SCENES:
        image = render_shot(scene)
        if image.size != CANVAS:
            raise SystemExit(f"bad size {image.size}")
        dest = out / scene["file"]
        image.save(dest, "PNG", optimize=True)
        print(dest, image.size)


if __name__ == "__main__":
    main()
