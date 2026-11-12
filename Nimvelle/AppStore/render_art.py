#!/usr/bin/env python3
"""Nimvelle icon sizes and the 1206×2622 App Store screenshots.

The icon and the four portraits are used as supplied. People and the icon
artwork are not redrawn. Screenshots are composed here because this
environment has no iOS Simulator. Each one is exactly 1206×2622.
"""

from __future__ import annotations

import shutil
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / "AppStore"
ASSETS = ROOT / "App" / "Assets.xcassets"
ICON_DIR = ASSETS / "AppIcon.appiconset"
WEB = ART / "website"
UPLOADS = Path("/home/ubuntu/.cursor/projects/workspace/uploads")

SERIF = "/usr/share/fonts/truetype/liberation/LiberationSerif-Bold.ttf"
SERIF_REG = "/usr/share/fonts/truetype/liberation/LiberationSerif-Regular.ttf"
SANS = "/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf"
SANS_BOLD = "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf"

PAPER = (246, 242, 236)
CARD = (253, 250, 246)
INK = (42, 38, 34)
MUTED = (110, 101, 92)
LINE = (218, 208, 195)
SAGE = (126, 143, 120)
SAGE_DEEP = (62, 83, 68)
CLAY = (196, 164, 138)
AMBER = (196, 138, 74)
ROSE = (168, 90, 82)
DUSK = (142, 122, 146)
WHITE = (255, 252, 248)
MINT = (214, 236, 228)
MINT_DEEP = (47, 92, 84)
PEARL = (244, 248, 246)

CANVAS = (1206, 2622)
SHOT_DIR = ART / "screenshots" / "1206x2622"

MODEL_SRC = {
    "serum": "model-serum_5d3e.jpg",
    "cream": "model-cream_6069.jpg",
    "jar": "model-jar_56d5.jpg",
    "cleanse": "model-cleanse_b754.jpg",
}
MODEL_NAMES = {
    "serum": "model-serum.jpg",
    "cream": "model-cream.jpg",
    "jar": "model-jar.jpg",
    "cleanse": "model-cleanse.jpg",
}
OLD_MODELS = [
    "model-1-serum-morning.jpg",
    "model-2-amber-bottle.jpg",
    "model-3-moisturizer.jpg",
    "model-4-cream-jar.jpg",
]
ICON_SRC_NAME = "nimvelle-icon_0a08.jpg"


def font(path: str, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(path, max(8, int(size)))


def find_upload(name: str) -> Path:
    direct = UPLOADS / name
    if direct.exists():
        return direct
    stem = name.split("_")[0]
    matches = sorted(UPLOADS.glob(stem + "*.jpg"))
    if not matches:
        raise SystemExit(f"missing {name}")
    return matches[0]


def cover(path: Path, size: tuple[int, int], focus=(0.5, 0.32)) -> Image.Image:
    image = Image.open(path).convert("RGB")
    width, height = size
    scale = max(width / image.width, height / image.height)
    resized = image.resize((int(image.width * scale), int(image.height * scale)), Image.Resampling.LANCZOS)
    left = int(resized.width * focus[0] - width / 2)
    top = int(resized.height * focus[1] - height / 2)
    left = max(0, min(left, resized.width - width))
    top = max(0, min(top, resized.height - height))
    return resized.crop((left, top, left + width, top + height))


def rounded(base: Image.Image, box, radius, fill, outline=None, width=1):
    layer = Image.new("RGBA", base.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)
    base.alpha_composite(layer)


def text(draw, xy, content, face, fill, anchor="lt"):
    draw.text(xy, content, font=face, fill=fill, anchor=anchor)


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
    return lines or [""]


def draw_wrapped(draw, content, face, fill, xy, width, gap=1.12):
    x, y = xy
    for line in wrap(draw, content, face, width):
        text(draw, (x, y), line, face, fill)
        y += int(face.size * gap)
    return y


def copy_models() -> dict[str, Path]:
    dest = ART / "models"
    dest.mkdir(parents=True, exist_ok=True)
    for old in OLD_MODELS:
        path = dest / old
        if path.exists():
            path.unlink()
    paths = {}
    for key, source_name in MODEL_SRC.items():
        target = dest / MODEL_NAMES[key]
        shutil.copyfile(find_upload(source_name), target)
        paths[key] = target
    return paths


def write_icons():
    ICON_DIR.mkdir(parents=True, exist_ok=True)
    (ART / "icon").mkdir(parents=True, exist_ok=True)
    WEB.mkdir(parents=True, exist_ok=True)
    source = Image.open(find_upload(ICON_SRC_NAME)).convert("RGB")
    if source.size != (1024, 1024):
        source = source.resize((1024, 1024), Image.Resampling.LANCZOS)
    # Full-bleed square. iOS applies its own mask; do not round it here.
    source.save(ART / "icon" / "AppIcon-1024.png", "PNG")
    source.save(ART / "icon" / "icon-1024.png", "PNG")
    source.save(ICON_DIR / "icon-1024.png", "PNG")
    shutil.copyfile(find_upload(ICON_SRC_NAME), ART / "icon" / "nimvelle-icon.jpg")
    for side in (180, 167, 152, 120, 87, 80, 76, 60, 58, 40, 29, 20):
        source.resize((side, side), Image.Resampling.LANCZOS).convert("RGB").save(ICON_DIR / f"icon-{side}.png", "PNG")
    source.resize((32, 32), Image.Resampling.LANCZOS).save(WEB / "favicon-32.png", "PNG")
    source.resize((180, 180), Image.Resampling.LANCZOS).save(WEB / "apple-touch-icon.png", "PNG")
    source.resize((192, 192), Image.Resampling.LANCZOS).save(WEB / "icon-192.png", "PNG")
    master = Image.open(ART / "icon" / "AppIcon-1024.png")
    if master.mode != "RGB" or master.size != (1024, 1024):
        raise SystemExit(f"icon must be 1024 RGB, got {master.mode} {master.size}")


def leaf_mark(draw, cx, cy, scale, color):
    r = 11 * scale
    draw.ellipse((cx - r, cy - r * 0.2, cx + r * 0.15, cy + r), fill=color)
    draw.polygon([(cx, cy - r * 1.15), (cx + r * 0.85, cy + r * 0.15), (cx - r * 0.1, cy + r * 0.15)], fill=color)


def nav_bar(draw, rect, title, scale, trailing=True):
    x0, y0, x1, _ = rect
    pad = 28 * scale
    leaf_mark(draw, x0 + pad + 8 * scale, y0 + 28 * scale, scale, SAGE_DEEP)
    text(draw, ((x0 + x1) / 2, y0 + 10 * scale), title, font(SERIF_REG, 30 * scale), INK, anchor="mt")
    if trailing:
        text(draw, (x1 - pad, y0 + 6 * scale), "+", font(SANS, 36 * scale), SAGE_DEEP, anchor="rt")
    return y0 + 64 * scale


def tab_glyph(draw, kind, cx, cy, scale, color):
    s = 10 * scale
    width = max(2, int(2 * scale))
    if kind == "today":
        draw.ellipse((cx - s, cy - s, cx + s, cy + s), outline=color, width=width)
    elif kind == "month":
        draw.rounded_rectangle((cx - s, cy - s * 0.8, cx + s, cy + s), radius=2, outline=color, width=width)
        draw.line((cx - s, cy - s * 0.2, cx + s, cy - s * 0.2), fill=color, width=width)
    elif kind == "shelf":
        draw.rounded_rectangle((cx - s, cy - s * 0.7, cx + s, cy + s * 0.9), radius=2, outline=color, width=width)
    else:
        draw.line((cx - s, cy - s * 0.5, cx + s, cy - s * 0.5), fill=color, width=width)
        draw.line((cx - s, cy, cx + s * 0.65, cy), fill=color, width=width)
        draw.line((cx - s, cy + s * 0.5, cx + s, cy + s * 0.5), fill=color, width=width)


def tab_bar(base, rect, active, scale):
    x0, _, x1, y1 = rect
    height = 92 * scale
    top = y1 - height
    rounded(base, (x0, top, x1, y1), 0, CARD, LINE, 1)
    draw = ImageDraw.Draw(base)
    labels = [("Today", "today"), ("Month", "month"), ("Shelf", "shelf"), ("Journal", "journal")]
    width = (x1 - x0) / 4
    for index, (label, kind) in enumerate(labels):
        cx = x0 + width * index + width / 2
        color = SAGE_DEEP if index == active else MUTED
        tab_glyph(draw, kind, cx, top + 24 * scale, scale, color)
        text(draw, (cx, top + 48 * scale), label, font(SANS, 16 * scale), color, anchor="mt")
    return top


def check_row(draw, x, y, width, scale, title, detail, detail_color, checked):
    radius = 14 * scale
    cx = x + radius
    cy = y + 18 * scale
    if checked:
        draw.ellipse((cx - radius, cy - radius, cx + radius, cy + radius), fill=SAGE)
        draw.line((cx - radius * 0.45, cy, cx - radius * 0.08, cy + radius * 0.38), fill=WHITE, width=max(2, int(2.4 * scale)))
        draw.line((cx - radius * 0.08, cy + radius * 0.38, cx + radius * 0.5, cy - radius * 0.38), fill=WHITE, width=max(2, int(2.4 * scale)))
    else:
        draw.ellipse((cx - radius, cy - radius, cx + radius, cy + radius), outline=LINE, width=max(2, int(2 * scale)))
    text_x = x + radius * 2 + 14 * scale
    text(draw, (text_x, y), title, font(SERIF_REG, 26 * scale), INK)
    end = draw_wrapped(draw, detail, font(SANS, 18 * scale), detail_color, (text_x, y + 30 * scale), width - (text_x - x))
    return max(end, y + 64 * scale) + 6 * scale


def paint_today(base, rect, scale):
    draw = ImageDraw.Draw(base)
    x0, y0, x1, _ = rect
    pad = 22 * scale
    y = nav_bar(draw, rect, "Today", scale)
    bottom = tab_bar(base, rect, 0, scale)
    draw = ImageDraw.Draw(base)
    text(draw, (x0 + pad, y), "Wednesday, November 11", font(SANS, 18 * scale), MUTED)
    y += 28 * scale
    text(draw, (x0 + pad, y), "Good morning", font(SERIF_REG, 44 * scale), INK)
    y += 58 * scale
    capsule = (x0 + pad, y, x0 + pad + 168 * scale, y + 34 * scale)
    rounded(base, capsule, 17 * scale, (236, 214, 206), None, 0)
    text(draw, (capsule[0] + 14 * scale, capsule[1] + 7 * scale), "5-day streak", font(SANS_BOLD, 16 * scale), SAGE_DEEP)
    y += 50 * scale
    seg_w = x1 - x0 - pad * 2
    seg_h = 40 * scale
    rounded(base, (x0 + pad, y, x0 + pad + seg_w, y + seg_h), 10 * scale, (236, 230, 222), None, 0)
    half = seg_w / 2
    rounded(base, (x0 + pad + 3, y + 3, x0 + pad + half - 2, y + seg_h - 3), 8 * scale, CARD, None, 0)
    text(draw, (x0 + pad + half / 2, y + 9 * scale), "Morning", font(SANS_BOLD, 16 * scale), INK, anchor="mt")
    text(draw, (x0 + pad + half * 1.5, y + 9 * scale), "Evening", font(SANS, 16 * scale), MUTED, anchor="mt")
    y += seg_h + 16 * scale
    text(draw, (x0 + pad, y), "3 of 5", font(SERIF_REG, 32 * scale), INK)
    y += 44 * scale
    rounded(base, (x0 + pad, y, x1 - pad, y + 8 * scale), 4 * scale, LINE, None, 0)
    rounded(base, (x0 + pad, y, x0 + pad + (x1 - x0 - pad * 2) * 0.6, y + 8 * scale), 4 * scale, SAGE, None, 0)
    y += 22 * scale
    rows = [
        ("Cleanse", "Cloud Milk Cleanser", MUTED, True),
        ("Tone", "Rice Water Toner", MUTED, True),
        ("Serum", "Dawn C Serum", MUTED, True),
        ("Moisturize", "Veil Cream · 10 days left in the open-jar window", AMBER, False),
        ("Sunscreen", "Daily Veil SPF 50", MUTED, False),
    ]
    width = x1 - x0 - pad * 2
    for title, detail, color, checked in rows:
        if y > bottom - 40 * scale:
            break
        y = check_row(draw, x0 + pad, y, width, scale, title, detail, color, checked)


def paint_month(base, rect, scale):
    draw = ImageDraw.Draw(base)
    x0, y0, x1, _ = rect
    pad = 18 * scale
    y = nav_bar(draw, rect, "Month", scale, trailing=False)
    bottom = tab_bar(base, rect, 1, scale)
    draw = ImageDraw.Draw(base)
    text(draw, ((x0 + x1) / 2, y), "November 2026", font(SERIF_REG, 30 * scale), INK, anchor="mt")
    text(draw, (x0 + pad, y + 2 * scale), "<", font(SANS, 26 * scale), SAGE_DEEP)
    text(draw, (x1 - pad, y + 2 * scale), ">", font(SANS, 26 * scale), SAGE_DEEP, anchor="rt")
    y += 58 * scale
    text(draw, (x0 + pad, y), "5-day streak · longest 21", font(SANS, 16 * scale), MUTED)
    y += 30 * scale
    col_w = (x1 - x0 - pad * 2) / 7
    for index, label in enumerate("SMTWTFS"):
        text(draw, (x0 + pad + col_w * index + col_w / 2, y), label, font(SANS_BOLD, 14 * scale), MUTED, anchor="mt")
    y += 28 * scale
    weeks = [
        [(1, "C"), (2, "C"), (3, "C"), (4, "-"), (5, "P"), (6, "C"), (7, "C")],
        [(8, "C"), (9, "C"), (10, "C"), (11, "P"), (12, "-"), (13, "-"), (14, "-")],
        [(15, "-"), (16, "-"), (17, "-"), (18, "-"), (19, "-"), (20, "-"), (21, "-")],
        [(22, "-"), (23, "-"), (24, "-"), (25, "-"), (26, "-"), (27, "-"), (28, "-")],
        [(29, "-"), (30, "-")],
    ]
    row_h = 52 * scale
    for week in weeks:
        if y + row_h > bottom - 150 * scale:
            break
        for index, (day, mark) in enumerate(week):
            cx = x0 + pad + col_w * index + col_w / 2
            if day == 11:
                r = 13 * scale
                draw.ellipse((cx - r, y, cx + r, y + r * 2), outline=SAGE_DEEP, width=max(2, int(1.6 * scale)))
            text(draw, (cx, y + 2 * scale), str(day), font(SERIF_REG, 16 * scale), INK, anchor="mt")
            dot = y + 32 * scale
            if mark == "C":
                draw.ellipse((cx - 4 * scale, dot, cx + 4 * scale, dot + 8 * scale), fill=SAGE)
            elif mark == "P":
                draw.ellipse((cx - 4 * scale, dot, cx + 4 * scale, dot + 8 * scale), outline=CLAY, width=max(2, int(1.6 * scale)))
        y += row_h
    y += 6 * scale
    text(draw, (x0 + pad, y), "Wednesday, November 11", font(SERIF_REG, 22 * scale), INK)
    y += 30 * scale
    text(draw, (x0 + pad, y), "Morning 3 of 5 · Evening 0 of 3", font(SANS, 15 * scale), MUTED)


def product_card(base, box, scale, name, brand, fill_label, fraction, opened, status, status_color):
    x0, y0, x1, y1 = box
    rounded(base, box, 16 * scale, CARD, LINE, 1)
    draw = ImageDraw.Draw(base)
    pad = 14 * scale
    text(draw, (x0 + pad, y0 + 12 * scale), name, font(SERIF_REG, 22 * scale), INK)
    text(draw, (x1 - pad, y0 + 16 * scale), fill_label, font(SANS_BOLD, 12 * scale), SAGE_DEEP, anchor="rt")
    text(draw, (x0 + pad, y0 + 40 * scale), brand, font(SANS, 14 * scale), MUTED)
    bar_y = y0 + 66 * scale
    rounded(base, (x0 + pad, bar_y, x1 - pad, bar_y + 7 * scale), 3 * scale, LINE, None, 0)
    rounded(base, (x0 + pad, bar_y, x0 + pad + (x1 - x0 - pad * 2) * fraction, bar_y + 7 * scale), 3 * scale, CLAY, None, 0)
    text(draw, (x0 + pad, bar_y + 14 * scale), opened, font(SANS, 13 * scale), MUTED)
    text(draw, (x0 + pad, bar_y + 34 * scale), status, font(SANS_BOLD, 14 * scale), status_color)


def paint_shelf(base, rect, scale):
    draw = ImageDraw.Draw(base)
    x0, _, x1, _ = rect
    pad = 18 * scale
    y = nav_bar(draw, rect, "Shelf", scale)
    bottom = tab_bar(base, rect, 2, scale)
    draw = ImageDraw.Draw(base)
    y = draw_wrapped(
        draw,
        "A period after opening is the maker's guide for an opened jar. It is not a medical date.",
        font(SANS, 15 * scale),
        MUTED,
        (x0 + pad, y),
        x1 - x0 - pad * 2,
    )
    y += 10 * scale
    banner_h = 58 * scale
    rounded(base, (x0 + pad, y, x1 - pad, y + banner_h), 14 * scale, (236, 214, 206), None, 0)
    draw_wrapped(
        draw,
        "1 jar is past its open-jar window, and 1 is close.",
        font(SANS_BOLD, 15 * scale),
        INK,
        (x0 + pad + 12 * scale, y + 12 * scale),
        x1 - x0 - pad * 2 - 24 * scale,
    )
    y += banner_h + 12 * scale
    cards = [
        ("Night Repair Cream", "Hearth & Co. · Moisturizer", "Almost empty", 0.12, "Opened Oct 2, 2025 · 12 months", "40 days past the open-jar window", ROSE),
        ("Veil Cream", "Hearth & Co. · Moisturizer", "About a quarter", 0.25, "Opened Nov 21, 2025 · 12 months", "10 days left in the open-jar window", AMBER),
        ("Cloud Milk Cleanser", "Hearth & Co. · Cleanser", "About three quarters", 0.75, "Opened Oct 2, 2026 · 12 months", "325 days left in the open-jar window", SAGE_DEEP),
    ]
    card_h = 128 * scale
    for card in cards:
        if y + card_h > bottom - 8 * scale:
            break
        product_card(base, (x0 + pad, y, x1 - pad, y + card_h), scale, *card)
        y += card_h + 10 * scale


def paint_notes(base, rect, scale):
    draw = ImageDraw.Draw(base)
    x0, _, x1, _ = rect
    pad = 18 * scale
    y = nav_bar(draw, rect, "Journal", scale, trailing=False)
    bottom = tab_bar(base, rect, 3, scale)
    draw = ImageDraw.Draw(base)
    seg_w = x1 - x0 - pad * 2
    seg_h = 38 * scale
    rounded(base, (x0 + pad, y, x0 + pad + seg_w, y + seg_h), 10 * scale, (236, 230, 222), None, 0)
    half = seg_w / 2
    rounded(base, (x0 + pad + 3, y + 3, x0 + pad + half - 2, y + seg_h - 3), 8 * scale, CARD, None, 0)
    text(draw, (x0 + pad + half / 2, y + 9 * scale), "Notes", font(SANS_BOLD, 15 * scale), INK, anchor="mt")
    text(draw, (x0 + pad + half * 1.5, y + 9 * scale), "Progress", font(SANS, 15 * scale), MUTED, anchor="mt")
    y += seg_h + 12 * scale
    y = draw_wrapped(
        draw,
        "A personal note. Nimvelle does not assess your skin.",
        font(SANS, 15 * scale),
        MUTED,
        (x0 + pad, y),
        x1 - x0 - pad * 2,
    )
    y += 8 * scale
    text(draw, (x0 + pad, y), "Last 14 days", font(SERIF_REG, 24 * scale), INK)
    y += 34 * scale
    series = [
        ("Dryness", CLAY, [None, 3, None, 2, None, 4, None, 3, 2, 3, 2, 1, 3, None]),
        ("Mood", SAGE, [None, 4, None, 4, None, 3, None, 4, 5, 4, 4, 5, 4, None]),
        ("Sleep", DUSK, [None, 3, None, 4, None, 2, None, 4, 5, 3, 4, 4, 4, None]),
    ]
    chart_h = 52 * scale
    gap = 4 * scale
    count = 14
    bar_w = ((x1 - x0 - pad * 2) - gap * (count - 1)) / count
    for label, color, values in series:
        if y + chart_h > bottom - 90 * scale:
            break
        text(draw, (x0 + pad, y), label, font(SANS_BOLD, 13 * scale), MUTED)
        y += 18 * scale
        for index, value in enumerate(values):
            bx = x0 + pad + index * (bar_w + gap)
            if value is None:
                bh, fill = 4 * scale, LINE
            else:
                bh, fill = max(8 * scale, chart_h * (value / 5)), color
            draw.rounded_rectangle((bx, y + chart_h - bh, bx + bar_w, y + chart_h), radius=2, fill=fill)
        y += chart_h + 8 * scale
    if y < bottom - 36 * scale:
        text(draw, (x0 + pad, y), "9 noted days. 2 days with spots in this window.", font(SANS, 14 * scale), MUTED)


def paint_progress(base, rect, scale, portrait: Path):
    draw = ImageDraw.Draw(base)
    x0, _, x1, _ = rect
    pad = 18 * scale
    y = nav_bar(draw, rect, "Journal", scale, trailing=False)
    bottom = tab_bar(base, rect, 3, scale)
    draw = ImageDraw.Draw(base)
    seg_w = x1 - x0 - pad * 2
    seg_h = 38 * scale
    rounded(base, (x0 + pad, y, x0 + pad + seg_w, y + seg_h), 10 * scale, (236, 230, 222), None, 0)
    half = seg_w / 2
    rounded(base, (x0 + pad + half + 2, y + 3, x0 + pad + seg_w - 3, y + seg_h - 3), 8 * scale, CARD, None, 0)
    text(draw, (x0 + pad + half / 2, y + 9 * scale), "Notes", font(SANS, 15 * scale), MUTED, anchor="mt")
    text(draw, (x0 + pad + half * 1.5, y + 9 * scale), "Progress", font(SANS_BOLD, 15 * scale), INK, anchor="mt")
    y += seg_h + 12 * scale
    y = draw_wrapped(
        draw,
        "Once a week is plenty. Photos stay on this device.",
        font(SANS, 15 * scale),
        MUTED,
        (x0 + pad, y),
        x1 - x0 - pad * 2,
    )
    y += 12 * scale
    frame_h = min(280 * scale, bottom - y - 78 * scale)
    gap = 10 * scale
    frame_w = (x1 - x0 - pad * 2 - gap) / 2
    earlier = cover(portrait, (int(frame_w), int(frame_h)), focus=(0.42, 0.30))
    later = cover(portrait, (int(frame_w), int(frame_h)), focus=(0.62, 0.42))
    for index, (shot, caption, when) in enumerate((
        (earlier, "Earlier", "Nov 4"),
        (later, "Later", "Nov 11"),
    )):
        fx = x0 + pad + index * (frame_w + gap)
        mask = Image.new("L", shot.size, 0)
        ImageDraw.Draw(mask).rounded_rectangle((0, 0, frame_w, frame_h), radius=int(14 * scale), fill=255)
        base.paste(shot.convert("RGBA"), (int(fx), int(y)), mask)
        text(draw, (fx, y + frame_h + 6 * scale), caption, font(SANS_BOLD, 13 * scale), MUTED)
        text(draw, (fx, y + frame_h + 24 * scale), when, font(SANS, 14 * scale), INK)
    button_y = y + frame_h + 52 * scale
    if button_y + 42 * scale < bottom:
        rounded(base, (x0 + pad, button_y, x1 - pad, button_y + 42 * scale), 12 * scale, SAGE_DEEP, None, 0)
        text(draw, ((x0 + x1) / 2, button_y + 10 * scale), "Add a photo", font(SANS_BOLD, 16 * scale), CARD, anchor="mt")


def render_screen(size, painter, scale) -> Image.Image:
    screen = Image.new("RGBA", size, PAPER + (255,))
    width, height = size
    island_w = int(width * 0.31)
    island_h = max(28, int(height * 0.034))
    island_top = int(height * 0.014)
    content_top = island_top + island_h + int(height * 0.008)
    painter(screen, (0, content_top, width, height), scale)
    draw = ImageDraw.Draw(screen)
    ix = (width - island_w) / 2
    draw.rounded_rectangle(
        (ix, island_top, ix + island_w, island_top + island_h),
        radius=island_h / 2,
        fill=(12, 12, 14),
    )
    text(draw, (int(width * 0.08), island_top + island_h * 0.08), "9:41", font(SANS_BOLD, max(12, int(width * 0.038))), INK)
    return screen


def phone_frame(canvas: Image.Image, origin, screen_image: Image.Image):
    x, y = origin
    sw, sh = screen_image.size
    bezel = 14
    radius = 54
    outer = (x - bezel, y - bezel, x + sw + bezel, y + sh + bezel)
    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle(
        (outer[0] + 8, outer[1] + 18, outer[2] + 8, outer[3] + 22),
        radius=radius,
        fill=(40, 70, 64, 70),
    )
    canvas.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(18)))
    draw = ImageDraw.Draw(canvas)
    draw.rounded_rectangle(outer, radius=radius, fill=(38, 40, 42))
    draw.rounded_rectangle(outer, radius=radius, outline=(186, 190, 188), width=2)
    # Side buttons, so the body reads as a phone.
    draw.rounded_rectangle((outer[0] - 3, y + 120, outer[0] + 2, y + 190), radius=2, fill=(70, 72, 74))
    draw.rounded_rectangle((outer[0] - 3, y + 210, outer[0] + 2, y + 280), radius=2, fill=(70, 72, 74))
    draw.rounded_rectangle((outer[2] - 2, y + 170, outer[2] + 3, y + 250), radius=2, fill=(70, 72, 74))
    mask = Image.new("L", screen_image.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, sw, sh), radius=radius - bezel, fill=255)
    canvas.paste(screen_image, (x, y), mask)


def gradient_canvas() -> Image.Image:
    image = Image.new("RGB", CANVAS, PEARL)
    draw = ImageDraw.Draw(image)
    top = (176, 219, 202)
    bottom = (244, 248, 246)
    for row in range(CANVAS[1]):
        t = row / (CANVAS[1] - 1)
        color = tuple(int(top[i] * (1 - t) + bottom[i] * t) for i in range(3))
        draw.line((0, row, CANVAS[0], row), fill=color)
    return image.convert("RGBA")


def compose(model: Path, focus, kicker, title, subtitle, painter) -> Image.Image:
    canvas = gradient_canvas()
    photo_h = 900
    photo = cover(model, (CANVAS[0], photo_h), focus).convert("RGBA")
    canvas.paste(photo, (0, 0))
    fade_h = 120
    fade = Image.new("RGBA", (CANVAS[0], fade_h), (0, 0, 0, 0))
    fade_draw = ImageDraw.Draw(fade)
    for row in range(fade_h):
        alpha = int(255 * (row / (fade_h - 1)) ** 1.4)
        fade_draw.line((0, row, CANVAS[0], row), fill=(214, 236, 228, alpha))
    canvas.alpha_composite(fade, (0, photo_h - fade_h))
    draw = ImageDraw.Draw(canvas)
    y = photo_h + 18
    text(draw, (56, y), kicker, font(SANS_BOLD, 18), MINT_DEEP)
    y += 28
    for line in wrap(draw, title, font(SERIF, 52), CANVAS[0] - 120):
        text(draw, (56, y), line, font(SERIF, 52), MINT_DEEP)
        y += 58
    y = draw_wrapped(draw, subtitle, font(SANS, 24), (70, 104, 98), (56, y + 2), CANVAS[0] - 140)
    screen_w = 700
    bezel = 14
    bottom_margin = 28
    top = y + 22
    screen_h = CANVAS[1] - top - bezel - bottom_margin
    scale = screen_w / 980
    screen = render_screen((screen_w, screen_h), painter, scale)
    origin = ((CANVAS[0] - screen_w) // 2, top)
    phone_frame(canvas, origin, screen)
    out = canvas.convert("RGB")
    if out.size != CANVAS:
        raise SystemExit(f"canvas {out.size}")
    return out


def clear_old_shots():
    root = ART / "screenshots"
    if not root.exists():
        return
    for child in root.iterdir():
        if child.is_dir() and child.resolve() != SHOT_DIR.resolve():
            shutil.rmtree(child)
        elif child.is_file():
            child.unlink()


def main():
    models = copy_models()
    write_icons()
    clear_old_shots()
    SHOT_DIR.mkdir(parents=True, exist_ok=True)
    screens = [
        ("01-today.png", "serum", (0.48, 0.42), "TODAY", "The morning, already laid out", "Check off the steps you actually use.", lambda b, r, s: paint_today(b, r, s)),
        ("02-month.png", "cream", (0.50, 0.42), "MONTH", "A month of small check-ins", "Complete days build a streak. Today can still be open.", lambda b, r, s: paint_month(b, r, s)),
        ("03-shelf.png", "jar", (0.48, 0.50), "SHELF", "Before a jar overstays", "An open-jar window is a storage guide, not a medical date.", lambda b, r, s: paint_shelf(b, r, s)),
        ("04-notes.png", "cleanse", (0.50, 0.44), "NOTES", "Notes for you, not a diagnosis", "Dryness, spots, mood, and sleep. Nothing is assessed.", lambda b, r, s: paint_notes(b, r, s)),
        ("05-progress.png", "serum", (0.42, 0.40), "PROGRESS", "A week, side by side", "Optional photos stay on this iPhone.", lambda b, r, s: paint_progress(b, r, s, models["serum"])),
    ]
    for name, key, focus, kicker, title, subtitle, painter in screens:
        image = compose(models[key], focus, kicker, title, subtitle, painter)
        if image.size != CANVAS or image.mode != "RGB":
            raise SystemExit(f"{name} is {image.mode} {image.size}")
        image.save(SHOT_DIR / name, "PNG", optimize=True)
        print(f"wrote {SHOT_DIR / name} {image.size}")


if __name__ == "__main__":
    main()
