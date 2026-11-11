#!/usr/bin/env python3
"""Compose the Sheenlisse icon and App Store screenshots.

Screenshots place the original model portraits inside the mirror UI
(look chips, shade row, intensity, before/after) plus a headline.
They are not Simulator captures. This environment has no Xcode.
"""

from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / "AppStore"
MODELS = ART / "models"
ICON_DIR = ART / "icon"
APP_ICON = ROOT / "App" / "Assets.xcassets" / "AppIcon.appiconset"

SERIF = "/usr/share/fonts/truetype/liberation/LiberationSerif-Regular.ttf"
SERIF_BOLD = "/usr/share/fonts/truetype/liberation/LiberationSerif-Bold.ttf"
SANS = "/usr/share/fonts/truetype/macos/Inter-Regular.ttf"
SANS_MED = "/usr/share/fonts/truetype/macos/Inter-Medium.ttf"
SANS_SEMI = "/usr/share/fonts/truetype/macos/Inter-SemiBold.ttf"
SANS_BOLD = "/usr/share/fonts/truetype/macos/Inter-Bold.ttf"

IVORY = (251, 246, 242)
CHAMPAGNE = (243, 228, 212)
ROSE = (201, 107, 120)
GOLD = (184, 137, 106)
PLUM = (44, 26, 34)
INK = (37, 22, 28)
LINE = (230, 213, 207)
WHITE = (255, 255, 255)

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
LINER = [
    ("Soft Brown", "6B4A3A"),
    ("Charcoal", "3E3A3C"),
    ("Black", "1A1A1A"),
    ("Plum Ink", "5A2A44"),
]
BROWS = [
    ("Soft Blonde", "C6A36A"),
    ("Taupe", "A0846C"),
    ("Soft Brown", "7A5A42"),
    ("Deep Brown", "4A3428"),
]
REGIONS = {
    "Lips": LIPS,
    "Blush": BLUSH,
    "Eyes": EYES,
    "Liner": LINER,
    "Brows": BROWS,
}
LOOKS = ["Natural", "Evening", "Vibrant", "Fresh"]

SIZES = {
    "iphone-6.9": (1320, 2868),
    "iphone-6.7": (1284, 2778),
    "iphone-6.5": (1242, 2688),
    "ipad-13": (2064, 2752),
}

SCENES = [
    {
        "file": "01-live-natural.png",
        "model": "model-1-natural.jpg",
        "look": "Natural",
        "region": "Lips",
        "shade": "Petal",
        "intensity": 62,
        "finish": "SATIN",
        "headline": "Color, live\non your face",
        "sub": "Lipstick, blush, eyes, liner, and brows.",
        "mode": "mirror",
        "pill": "TrueDepth",
    },
    {
        "file": "02-evening-shades.png",
        "model": "model-2-evening.jpg",
        "look": "Evening",
        "region": "Lips",
        "shade": "Deep Red",
        "intensity": 90,
        "finish": "MATTE",
        "headline": "Evening,\nin one tap",
        "sub": "A deep lip, a smoky lid, a liner that holds.",
        "mode": "mirror",
        "pill": "TrueDepth",
    },
    {
        "file": "03-before-after.png",
        "model": "model-3-vibrant.jpg",
        "look": "Vibrant",
        "region": "Eyes",
        "shade": "Violet",
        "intensity": 78,
        "finish": "SHIMMER",
        "headline": "Slide from\nbefore to after",
        "sub": "The bare camera on the left. Color on the right.",
        "mode": "compare",
        "pill": "Vision",
        "split": 0.46,
    },
    {
        "file": "04-fresh-intensity.png",
        "model": "model-4-fresh.jpg",
        "look": "Fresh",
        "region": "Lips",
        "shade": "Nude Mauve",
        "intensity": 55,
        "finish": "MATTE",
        "headline": "Soften or\ndeepen the shade",
        "sub": "Every color has its own intensity.",
        "mode": "mirror",
        "pill": "TrueDepth",
    },
    {
        "file": "05-for-your-face.png",
        "model": "model-1-natural.jpg",
        "look": "Natural",
        "region": "Blush",
        "shade": "Baby Pink",
        "intensity": 48,
        "finish": "SATIN",
        "headline": "A look chosen\nfor your face",
        "sub": "Shape and tone, read on this device.",
        "mode": "suggest",
        "pill": "TrueDepth",
    },
]


def font(path, size):
    return ImageFont.truetype(path, size)


def rgb(hex_color):
    hex_color = hex_color.lstrip("#")
    return tuple(int(hex_color[i : i + 2], 16) for i in (0, 2, 4))


def cover(path, size, focus=(0.5, 0.42)):
    image = Image.open(path).convert("RGB")
    scale = max(size[0] / image.width, size[1] / image.height)
    resized = image.resize((int(image.width * scale), int(image.height * scale)), Image.Resampling.LANCZOS)
    left = int((resized.width - size[0]) * focus[0])
    top = int((resized.height - size[1]) * focus[1])
    left = max(0, min(left, resized.width - size[0]))
    top = max(0, min(top, resized.height - size[1]))
    return resized.crop((left, top, left + size[0], top + size[1]))


def vertical_mask(height, stops):
    """stops: list of (fraction, alpha 0-255), linearly interpolated."""
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


def rounded(draw, box, radius, fill, outline=None, width=1):
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)


def text_size(draw, text, face):
    box = draw.textbbox((0, 0), text, font=face)
    return box[2] - box[0], box[3] - box[1]


def draw_icon(size):
    image = Image.new("RGB", (size, size), IVORY)
    draw = ImageDraw.Draw(image)
    for y in range(size):
        t = y / (size - 1)
        color = tuple(int(a + (b - a) * t) for a, b in zip((248, 228, 226), (196, 120, 132)))
        draw.line([(0, y), (size, y)], fill=color)
    cx = cy = size / 2
    oval = [cx - size * 0.28, cy - size * 0.36, cx + size * 0.28, cy + size * 0.36]
    draw.ellipse(oval, outline=GOLD, width=max(2, size // 48))
    inner = [oval[0] + size * 0.035, oval[1] + size * 0.035, oval[2] - size * 0.035, oval[3] - size * 0.035]
    draw.ellipse(inner, outline=(255, 248, 244), width=max(1, size // 180))
    lip = [cx - size * 0.12, cy + size * 0.08, cx + size * 0.12, cy + size * 0.20]
    draw.ellipse(lip, fill=ROSE)
    highlight = [cx - size * 0.05, cy + size * 0.10, cx + size * 0.02, cy + size * 0.125]
    draw.ellipse(highlight, fill=(255, 214, 208))
    return image


def save_icons():
    master = draw_icon(1024)
    ICON_DIR.mkdir(parents=True, exist_ok=True)
    rgb_master = master.convert("RGB")
    rgb_master.save(ICON_DIR / "AppIcon-1024.png", "PNG")
    rgb_master.save(APP_ICON / "icon-1024.png", "PNG")
    for edge in (20, 29, 40, 58, 60, 76, 80, 87, 120, 152, 167, 180):
        resized = rgb_master.resize((edge, edge), Image.Resampling.LANCZOS)
        resized.save(APP_ICON / f"icon-{edge}.png", "PNG")


def scrim(base):
    width, height = base.size
    top_color = Image.new("RGBA", (width, height), (28, 16, 22, 255))
    top_mask = vertical_mask(height, [(0.0, 170), (0.34, 40), (0.48, 0), (1.0, 0)]).resize((width, height))
    bottom_color = Image.new("RGBA", (width, height), (24, 12, 18, 255))
    bottom_mask = vertical_mask(height, [(0.0, 0), (0.55, 0), (1.0, 110)]).resize((width, height))
    out = base.convert("RGBA")
    out.paste(top_color, (0, 0), top_mask)
    out.paste(bottom_color, (0, 0), bottom_mask)
    return out


def draw_compare(photo, split):
    cut = int(photo.width * split)
    left = photo.crop((0, 0, cut, photo.height)).convert("L").convert("RGB")
    left = ImageEnhance.Color(left).enhance(0.15)
    left = ImageEnhance.Brightness(left).enhance(1.05)
    photo.paste(left, (0, 0))
    return photo


def draw_headline(image, headline, sub, scale, top):
    draw = ImageDraw.Draw(image)
    face = font(SERIF, int(54 * scale))
    small = font(SANS_MED, int(16 * scale))
    y = top
    for line in headline.split("\n"):
        draw.text((int(28 * scale), y), line, font=face, fill=WHITE)
        y += int(58 * scale)
    draw.text((int(30 * scale), y + int(6 * scale)), sub, font=small, fill=(255, 236, 230))
    return y + int(36 * scale)


def translucent_round(image, box, radius, fill):
    overlay = Image.new("RGBA", image.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    draw.rounded_rectangle(box, radius=radius, fill=fill)
    image.alpha_composite(overlay)


def draw_icon_button(image, center, radius, kind):
    overlay = Image.new("RGBA", image.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    cx, cy = center
    draw.ellipse([cx - radius, cy - radius, cx + radius, cy + radius], fill=(255, 255, 255, 70))
    ink = (255, 255, 255, 255)
    if kind == "spark":
        draw.line([(cx, cy - radius * 0.45), (cx, cy + radius * 0.45)], fill=ink, width=max(2, radius // 8))
        draw.line([(cx - radius * 0.45, cy), (cx + radius * 0.45, cy)], fill=ink, width=max(2, radius // 8))
        draw.line([(cx - radius * 0.28, cy - radius * 0.28), (cx + radius * 0.28, cy + radius * 0.28)], fill=ink, width=max(2, radius // 10))
        draw.line([(cx + radius * 0.28, cy - radius * 0.28), (cx - radius * 0.28, cy + radius * 0.28)], fill=ink, width=max(2, radius // 10))
    elif kind == "heart":
        r = radius * 0.28
        draw.ellipse([cx - r * 2.05, cy - r * 1.15, cx, cy + r * 0.7], outline=ink, width=max(2, radius // 8))
        draw.ellipse([cx, cy - r * 1.15, cx + r * 2.05, cy + r * 0.7], outline=ink, width=max(2, radius // 8))
        draw.line([(cx - r * 1.7, cy + r * 0.15), (cx, cy + r * 1.7), (cx + r * 1.7, cy + r * 0.15)], fill=ink, width=max(2, radius // 8))
    else:
        draw.ellipse([cx - radius * 0.38, cy - radius * 0.38, cx + radius * 0.38, cy + radius * 0.38], outline=ink, width=max(2, radius // 8))
        draw.ellipse([cx - 2, cy - radius * 0.16, cx + 2, cy - radius * 0.08], fill=ink)
        draw.line([(cx, cy - radius * 0.02), (cx, cy + radius * 0.2)], fill=ink, width=max(2, radius // 8))
    image.alpha_composite(overlay)


def draw_top_bar(image, scale, pill, y):
    draw = ImageDraw.Draw(image)
    word = font(SERIF, int(28 * scale))
    draw.text((int(28 * scale), y), "Sheenlisse", font=word, fill=WHITE)
    pill_font = font(SANS_BOLD, int(13 * scale))
    pw, _ = text_size(draw, pill, pill_font)
    icons_w = int(40 * scale) * 3
    pill_w = pw + int(24 * scale)
    right = image.width - int(22 * scale)
    icon_x = right - icons_w
    pill_x = icon_x - int(12 * scale) - pill_w
    pill_h = int(30 * scale)
    pill_box = [pill_x, y + int(2 * scale), pill_x + pill_w, y + int(2 * scale) + pill_h]
    translucent_round(image, pill_box, pill_h / 2, (255, 255, 255, 64))
    draw = ImageDraw.Draw(image)
    draw.text((pill_x + int(12 * scale), y + int(8 * scale)), pill, font=pill_font, fill=WHITE)
    radius = int(16 * scale)
    for index, kind in enumerate(("spark", "heart", "info")):
        cx = icon_x + index * int(40 * scale) + radius
        draw_icon_button(image, (cx, y + int(17 * scale)), radius, kind)


def draw_deck(canvas, scale, scene, box):
    draw = ImageDraw.Draw(canvas)
    x0, y0, x1, y1 = box
    rounded(draw, box, int(28 * scale), IVORY)
    pad = int(16 * scale)
    x = x0 + pad
    y = y0 + pad
    width = x1 - x0 - pad * 2
    label = font(SANS_BOLD, int(11 * scale))
    draw.text((x, y), "LOOKS", font=label, fill=(120, 90, 98))
    y += int(22 * scale)
    chip_font = font(SANS_SEMI, int(15 * scale))
    cx = x
    for name in LOOKS:
        tw, th = text_size(draw, name, chip_font)
        chip_w = tw + int(28 * scale)
        selected = name == scene["look"]
        fill = ROSE if selected else WHITE
        ink = WHITE if selected else PLUM
        outline = ROSE if selected else LINE
        rounded(draw, [cx, y, cx + chip_w, y + int(36 * scale)], int(18 * scale), fill, outline, 1)
        draw.text((cx + int(14 * scale), y + int(8 * scale)), name, font=chip_font, fill=ink)
        cx += chip_w + int(8 * scale)
    y += int(50 * scale)
    regions = ["Lips", "Blush", "Eyes", "Liner", "Brows"]
    region_font = font(SANS_SEMI, int(13 * scale))
    slot = width / len(regions)
    for index, name in enumerate(regions):
        selected = name == scene["region"]
        face = font(SANS_BOLD if selected else SANS_MED, int(13 * scale))
        tw, _ = text_size(draw, name, face)
        tx = x + index * slot + (slot - tw) / 2
        draw.text((tx, y), name, font=face, fill=PLUM if selected else (140, 110, 118))
        if selected:
            draw.rectangle([tx, y + int(22 * scale), tx + tw, y + int(25 * scale)], fill=GOLD)
    y += int(40 * scale)
    name_font = font(SERIF_BOLD, int(22 * scale))
    draw.text((x, y), scene["shade"], font=name_font, fill=INK)
    finish_font = font(SANS_BOLD, int(12 * scale))
    fw, _ = text_size(draw, scene["finish"], finish_font)
    draw.text((x1 - pad - fw, y + int(8 * scale)), scene["finish"], font=finish_font, fill=GOLD)
    y += int(40 * scale)
    shades = REGIONS[scene["region"]]
    diameter = int(46 * scale)
    gap = int(12 * scale)
    sx = x
    for shade_name, hex_color in shades:
        selected = shade_name == scene["shade"]
        ring = GOLD if selected else WHITE
        ring_w = int(3 * scale) if selected else int(2 * scale)
        draw.ellipse([sx, y, sx + diameter, y + diameter], fill=rgb(hex_color), outline=ring, width=ring_w)
        sx += diameter + gap
        if sx > x1 - pad - diameter:
            break
    y += diameter + int(18 * scale)
    row_font = font(SANS_SEMI, int(14 * scale))
    draw.text((x, y), "Intensity", font=row_font, fill=PLUM)
    percent = f"{scene['intensity']}%"
    pw, _ = text_size(draw, percent, font(SANS_BOLD, int(14 * scale)))
    draw.text((x1 - pad - pw, y), percent, font=font(SANS_BOLD, int(14 * scale)), fill=ROSE)
    # toggle
    toggle_w = int(44 * scale)
    toggle_h = int(26 * scale)
    toggle_x = x1 - pad - pw - int(14 * scale) - toggle_w
    rounded(draw, [toggle_x, y - int(2 * scale), toggle_x + toggle_w, y - int(2 * scale) + toggle_h], toggle_h / 2, ROSE)
    knob = int(20 * scale)
    draw.ellipse(
        [toggle_x + toggle_w - knob - int(3 * scale), y + int(1 * scale), toggle_x + toggle_w - int(3 * scale), y + int(1 * scale) + knob],
        fill=WHITE,
    )
    y += int(36 * scale)
    track_h = int(6 * scale)
    draw.rounded_rectangle([x, y, x1 - pad, y + track_h], radius=track_h / 2, fill=(232, 214, 210))
    fill_to = x + (x1 - pad - x) * (scene["intensity"] / 100)
    draw.rounded_rectangle([x, y, fill_to, y + track_h], radius=track_h / 2, fill=ROSE)
    knob_r = int(11 * scale)
    draw.ellipse([fill_to - knob_r, y + track_h / 2 - knob_r, fill_to + knob_r, y + track_h / 2 + knob_r], fill=WHITE, outline=ROSE, width=max(1, int(scale)))
    y += int(36 * scale)
    labels = [("Compare", scene["mode"] == "compare"), ("Save", False), ("Capture", False)]
    button_w = (width - int(16 * scale)) / 3
    for index, (title, active) in enumerate(labels):
        bx = x + index * (button_w + int(8 * scale))
        fill = ROSE if active else CHAMPAGNE
        ink = WHITE if active else PLUM
        rounded(draw, [bx, y, bx + button_w, y + int(54 * scale)], int(16 * scale), fill)
        face = font(SANS_SEMI, int(13 * scale))
        tw, th = text_size(draw, title, face)
        draw.text((bx + (button_w - tw) / 2, y + int(18 * scale)), title, font=face, fill=ink)
    return y + int(70 * scale)


def draw_suggest_card(canvas, scale, box):
    draw = ImageDraw.Draw(canvas)
    rounded(draw, box, int(22 * scale), WHITE)
    x0, y0, x1, _ = box
    x = x0 + int(18 * scale)
    y = y0 + int(16 * scale)
    kicker = font(SANS_BOLD, int(12 * scale))
    draw.text((x, y), "OVAL  ·  LIGHT", font=kicker, fill=GOLD)
    y += int(28 * scale)
    title = font(SERIF_BOLD, int(28 * scale))
    draw.text((x, y), "Start with Natural.", font=title, fill=INK)
    y += int(42 * scale)
    body = font(SANS, int(15 * scale))
    lines = [
        "An oval face can carry color evenly.",
        "Keep the blush soft and the lip the focus.",
        "Fair skin reads sheer color well.",
    ]
    for line in lines:
        draw.text((x, y), line, font=body, fill=PLUM)
        y += int(24 * scale)
    y += int(12 * scale)
    button = [x, y, x1 - int(18 * scale), y + int(52 * scale)]
    rounded(draw, button, int(16 * scale), ROSE)
    face = font(SANS_BOLD, int(17 * scale))
    tw, _ = text_size(draw, "Try this look", face)
    draw.text((button[0] + (button[2] - button[0] - tw) / 2, y + int(14 * scale)), "Try this look", font=face, fill=WHITE)


def divider(image, split, stop_y):
    draw = ImageDraw.Draw(image)
    x = int(image.width * split)
    draw.line([(x, int(image.height * 0.30)), (x, stop_y)], fill=WHITE, width=max(3, image.width // 360))
    r = max(18, image.width // 36)
    cy = int(image.height * 0.46)
    draw.ellipse([x - r, cy - r, x + r, cy + r], fill=IVORY, outline=GOLD, width=max(3, r // 8))
    arm = r * 0.38
    draw.line([(x - arm, cy), (x + arm, cy)], fill=PLUM, width=max(2, r // 10))
    draw.polygon([(x - arm, cy), (x - arm + r * 0.22, cy - r * 0.16), (x - arm + r * 0.22, cy + r * 0.16)], fill=PLUM)
    draw.polygon([(x + arm, cy), (x + arm - r * 0.22, cy - r * 0.16), (x + arm - r * 0.22, cy + r * 0.16)], fill=PLUM)
    label = font(SANS_BOLD, max(20, image.width // 28))
    y = int(image.height * 0.34)
    for text, cx in (("Before", x * 0.5), ("After", x + (image.width - x) * 0.5)):
        tw, th = text_size(draw, text, label)
        if cx - tw / 2 < 16 or cx + tw / 2 > image.width - 16:
            continue
        box = [cx - tw / 2 - 16, y, cx + tw / 2 + 16, y + th + 16]
        translucent_round(image, box, 16, (20, 12, 16, 140))
        ImageDraw.Draw(image).text((box[0] + 16, box[1] + 6), text, font=label, fill=WHITE)


def render_phone(size, scene):
    photo = cover(MODELS / scene["model"], size, focus=(0.50, 0.36))
    if scene["mode"] == "compare":
        photo = draw_compare(photo, scene["split"])
    image = scrim(photo).convert("RGBA")
    scale = size[0] / 430
    draw_top_bar(image, scale, scene["pill"], int(size[1] * 0.055))
    draw_headline(image, scene["headline"], scene["sub"], scale, int(size[1] * 0.105))
    margin = int(12 * scale)
    if scene["mode"] == "suggest":
        card_h = int(248 * scale)
        top = size[1] - margin - card_h
        draw_suggest_card(image, scale, [margin, top, size[0] - margin, size[1] - margin])
        return image.convert("RGB")
    deck_top = int(size[1] * 0.60)
    if scene["mode"] == "compare":
        divider(image, scene["split"], deck_top - int(8 * scale))
    deck_bottom = size[1] - int(18 * scale)
    draw_deck(image, scale, scene, [margin, deck_top, size[0] - margin, deck_bottom])
    return image.convert("RGB")


def render_ipad(size, scene):
    panel = int(size[0] * 0.36)
    camera_size = (size[0] - panel, size[1])
    photo = cover(MODELS / scene["model"], camera_size, focus=(0.5, 0.40))
    if scene["mode"] == "compare":
        photo = draw_compare(photo, scene.get("split", 0.46))
    camera = scrim(photo).convert("RGBA")
    scale = camera_size[0] / 520
    draw_headline(camera, scene["headline"], scene["sub"], scale * 0.92, int(size[1] * 0.08))
    if scene["mode"] == "compare":
        divider(camera, scene.get("split", 0.46), int(size[1] * 0.92))
    image = Image.new("RGB", size, IVORY)
    image.paste(camera.convert("RGB"), (0, 0))
    draw = ImageDraw.Draw(image)
    px = camera_size[0]
    word = font(SERIF, 42)
    draw.text((px + 28, 36), "Sheenlisse", font=word, fill=INK)
    pill = font(SANS_BOLD, 16)
    draw.rounded_rectangle([px + 28, 96, px + 180, 132], radius=18, fill=CHAMPAGNE)
    draw.text((px + 46, 102), scene["pill"] if scene["mode"] != "suggest" else "For you", font=pill, fill=PLUM)
    if scene["mode"] == "suggest":
        draw_suggest_card(image, 1.2, [px + 24, 168, size[0] - 24, 470])
        note = font(SANS, 18)
        draw.text((px + 36, 496), "A starting point, not a rule.", font=note, fill=(120, 90, 98))
        draw.text((px + 36, size[1] - 80), "Read on this iPad. Nothing is uploaded.", font=note, fill=(120, 90, 98))
    else:
        # panel uses a scale that fits the width
        panel_scale = (panel - 20) / 430
        draw_deck(image, panel_scale, scene, [px + 16, 160, size[0] - 16, 160 + int(760 * panel_scale)])
        note = font(SANS, 18)
        draw.text((px + 28, size[1] - 72), "Saved on this iPad. Nothing is uploaded.", font=note, fill=(120, 90, 98))
    return image


def main():
    save_icons()
    for folder, size in SIZES.items():
        out = ART / "screenshots" / folder
        out.mkdir(parents=True, exist_ok=True)
        for scene in SCENES:
            if folder == "ipad-13":
                image = render_ipad(size, scene)
            else:
                image = render_phone(size, scene)
            dest = out / scene["file"]
            image.save(dest, "PNG", optimize=True)
            print(dest, image.size)


if __name__ == "__main__":
    main()
