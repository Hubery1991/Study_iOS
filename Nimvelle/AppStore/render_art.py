#!/usr/bin/env python3
"""Compose the Nimvelle icon and App Store screenshots.

Screenshots place the supplied generated portraits beside a drawing of the
real Today, Month, Shelf, progress, and notes screens. They are not Simulator
captures. This environment has no Xcode.
"""

from __future__ import annotations

import math
import shutil
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / "AppStore"
ASSETS = ROOT / "App" / "Assets.xcassets"
ICON_DIR = ASSETS / "AppIcon.appiconset"
UPLOADS = Path("/home/ubuntu/.cursor/projects/workspace/uploads")

SERIF = "/usr/share/fonts/truetype/liberation/LiberationSerif-Regular.ttf"
SERIF_BOLD = "/usr/share/fonts/truetype/liberation/LiberationSerif-Bold.ttf"
SANS = "/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf"
SANS_BOLD = "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf"

PAPER = (246, 242, 236)
CARD = (253, 250, 246)
INK = (42, 38, 34)
MUTED = (110, 101, 92)
LINE = (218, 208, 195)
SAGE = (126, 143, 120)
SAGE_DEEP = (62, 83, 68)
BLUSH = (228, 199, 190)
CLAY = (196, 164, 138)
AMBER = (196, 138, 74)
ROSE = (168, 90, 82)
DUSK = (142, 122, 146)
WHITE = (255, 252, 248)

SIZES = {
    "iphone-6.9": (1320, 2868),
    "iphone-6.7": (1284, 2778),
    "iphone-6.5": (1242, 2688),
    "ipad-13": (2064, 2752),
}

MODEL_FILES = {
    "serum": "model-1-serum-morning_70a2.jpg",
    "amber": "model-2-amber-bottle_b51f.jpg",
    "moisture": "model-3-moisturizer_c247.jpg",
    "cream": "model-4-cream-jar_8493.jpg",
}
MODEL_NAMES = {
    "serum": "model-1-serum-morning.jpg",
    "amber": "model-2-amber-bottle.jpg",
    "moisture": "model-3-moisturizer.jpg",
    "cream": "model-4-cream-jar.jpg",
}


def font(path: str, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(path, max(10, int(size)))


def cover(path: Path, size: tuple[int, int], focus=(0.5, 0.38)) -> Image.Image:
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


def shadow_card(base: Image.Image, box, radius, fill=CARD):
    layer = Image.new("RGBA", base.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    x0, y0, x1, y1 = box
    draw.rounded_rectangle((x0 + 8, y0 + 16, x1 + 8, y1 + 22), radius=radius, fill=(62, 48, 40, 46))
    layer = layer.filter(ImageFilter.GaussianBlur(18))
    base.alpha_composite(layer)
    rounded(base, box, radius, fill, LINE, 2)


def text(draw: ImageDraw.ImageDraw, xy, content, face, fill, anchor="lt"):
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
    lines = wrap(draw, content, face, width)
    for line in lines:
        text(draw, (x, y), line, face, fill)
        y += int(face.size * gap)
    return y


def ellipsize(draw, content, face, width):
    if draw.textlength(content, font=face) <= width:
        return content
    trimmed = content
    while trimmed and draw.textlength(trimmed + "…", font=face) > width:
        trimmed = trimmed[:-1]
    return trimmed + "…"


def copy_models() -> dict[str, Path]:
    dest = ART / "models"
    dest.mkdir(parents=True, exist_ok=True)
    paths = {}
    for key, source_name in MODEL_FILES.items():
        source = UPLOADS / source_name
        if not source.exists():
            matches = sorted(UPLOADS.glob(source_name.split("_")[0] + "*.jpg"))
            if not matches:
                raise SystemExit(f"missing portrait {source_name}")
            source = matches[0]
        target = dest / MODEL_NAMES[key]
        shutil.copyfile(source, target)
        paths[key] = target
    return paths


def draw_icon(size: int) -> Image.Image:
    image = Image.new("RGB", (size, size), (243, 235, 227))
    draw = ImageDraw.Draw(image)
    cx = cy = size / 2
    blush_r = size * 0.36
    draw.ellipse((cx - blush_r, cy - blush_r, cx + blush_r, cy + blush_r), fill=BLUSH)
    ring = size * 0.27
    stroke = max(2, int(size * 0.016))
    draw.ellipse((cx - ring, cy - ring, cx + ring, cy + ring), outline=SAGE_DEEP, width=stroke)
    pts = []
    steps = 280
    rx = size * 0.092
    ry = size * 0.132
    for index in range(steps):
        theta = -math.pi / 2 + (2 * math.pi * index / steps)
        sine = math.sin(theta)
        cosine = math.cos(theta)
        taper = 0.22 + 0.78 * ((1 - sine) / 2) ** 0.72
        pts.append((cx + rx * cosine * taper, cy - ry * sine + size * 0.012))
    draw.polygon(pts, fill=SAGE)
    shine = size * 0.016
    draw.ellipse(
        (cx - size * 0.03, cy + size * 0.01, cx - size * 0.03 + shine, cy + size * 0.01 + shine * 1.35),
        fill=(236, 230, 220),
    )
    return image


def write_icons():
    ICON_DIR.mkdir(parents=True, exist_ok=True)
    master = draw_icon(1024)
    if master.mode != "RGB":
        master = master.convert("RGB")
    (ART / "icon").mkdir(parents=True, exist_ok=True)
    master.save(ART / "icon" / "AppIcon-1024.png", "PNG")
    master.save(ICON_DIR / "icon-1024.png", "PNG")
    shutil.copyfile(ART / "icon" / "AppIcon-1024.png", ART / "icon" / "icon-1024.png")
    for side in (180, 167, 152, 120, 87, 80, 76, 60, 58, 40, 29, 20):
        icon = master.resize((side, side), Image.Resampling.LANCZOS).convert("RGB")
        icon.save(ICON_DIR / f"icon-{side}.png", "PNG")


def leaf_mark(draw, cx, cy, scale, color):
    r = 11 * scale
    draw.ellipse((cx - r, cy - r * 0.2, cx + r * 0.15, cy + r), fill=color)
    draw.polygon([(cx, cy - r * 1.15), (cx + r * 0.85, cy + r * 0.15), (cx - r * 0.1, cy + r * 0.15)], fill=color)


def nav_bar(draw, rect, title, scale, trailing=True):
    x0, y0, x1, _ = rect
    pad = 36 * scale
    leaf_mark(draw, x0 + pad, y0 + 36 * scale, scale, SAGE_DEEP)
    text(draw, ((x0 + x1) / 2, y0 + 18 * scale), title, font(SERIF, 34 * scale), INK, anchor="mt")
    if trailing:
        text(draw, (x1 - pad, y0 + 14 * scale), "+", font(SANS, 40 * scale), SAGE_DEEP, anchor="rt")
    return y0 + 78 * scale


def tab_glyph(draw, kind, cx, cy, scale, color):
    s = 11 * scale
    if kind == "today":
        draw.ellipse((cx - s, cy - s, cx + s, cy + s), outline=color, width=max(2, int(2 * scale)))
        draw.line((cx, cy - s * 0.45, cx, cy + s * 0.15), fill=color, width=max(2, int(2 * scale)))
    elif kind == "month":
        draw.rounded_rectangle((cx - s, cy - s * 0.8, cx + s, cy + s), radius=3, outline=color, width=max(2, int(2 * scale)))
        draw.line((cx - s, cy - s * 0.25, cx + s, cy - s * 0.25), fill=color, width=max(2, int(2 * scale)))
    elif kind == "shelf":
        draw.rounded_rectangle((cx - s, cy - s * 0.7, cx + s, cy + s * 0.9), radius=3, outline=color, width=max(2, int(2 * scale)))
        draw.line((cx - s, cy - s * 0.05, cx + s, cy - s * 0.05), fill=color, width=max(2, int(2 * scale)))
    else:
        draw.line((cx - s, cy - s * 0.55, cx + s, cy - s * 0.55), fill=color, width=max(2, int(2 * scale)))
        draw.line((cx - s, cy, cx + s * 0.7, cy), fill=color, width=max(2, int(2 * scale)))
        draw.line((cx - s, cy + s * 0.55, cx + s, cy + s * 0.55), fill=color, width=max(2, int(2 * scale)))


def tab_bar(base, rect, active, scale):
    x0, _, x1, y1 = rect
    height = 108 * scale
    top = y1 - height
    rounded(base, (x0, top, x1, y1), 0, CARD, LINE, 2)
    draw = ImageDraw.Draw(base)
    labels = [("Today", "today"), ("Month", "month"), ("Shelf", "shelf"), ("Journal", "journal")]
    width = (x1 - x0) / 4
    for index, (label, kind) in enumerate(labels):
        cx = x0 + width * index + width / 2
        color = SAGE_DEEP if index == active else MUTED
        tab_glyph(draw, kind, cx, top + 28 * scale, scale, color)
        text(draw, (cx, top + 56 * scale), label, font(SANS, 18 * scale), color, anchor="mt")
    return top


def check_row(draw, x, y, width, scale, title, detail, detail_color, checked):
    radius = 16 * scale
    cx = x + radius
    cy = y + 22 * scale
    if checked:
        draw.ellipse((cx - radius, cy - radius, cx + radius, cy + radius), fill=SAGE)
        draw.line((cx - radius * 0.45, cy, cx - radius * 0.1, cy + radius * 0.38), fill=WHITE, width=max(2, int(3 * scale)))
        draw.line((cx - radius * 0.1, cy + radius * 0.38, cx + radius * 0.5, cy - radius * 0.4), fill=WHITE, width=max(2, int(3 * scale)))
    else:
        draw.ellipse((cx - radius, cy - radius, cx + radius, cy + radius), outline=LINE, width=max(2, int(2 * scale)))
    text_x = x + radius * 2 + 16 * scale
    text(draw, (text_x, y), title, font(SERIF, 32 * scale), INK)
    detail_y = y + 38 * scale
    end = draw_wrapped(draw, detail, font(SANS, 22 * scale), detail_color, (text_x, detail_y), width - (text_x - x), 1.05)
    return max(end, y + 78 * scale) + 8 * scale


def paint_today(base, rect, scale):
    draw = ImageDraw.Draw(base)
    x0, y0, x1, y1 = rect
    pad = 28 * scale
    y = nav_bar(draw, rect, "Today", scale)
    content_bottom = tab_bar(base, rect, 0, scale)
    draw = ImageDraw.Draw(base)
    text(draw, (x0 + pad, y), "Wednesday, November 11", font(SANS, 22 * scale), MUTED)
    y += 34 * scale
    text(draw, (x0 + pad, y), "Good morning", font(SERIF, 58 * scale), INK)
    y += 78 * scale
    capsule = (x0 + pad, y, x0 + pad + 210 * scale, y + 42 * scale)
    rounded(base, capsule, 21 * scale, (236, 214, 206), None, 0)
    text(draw, (capsule[0] + 18 * scale, capsule[1] + 8 * scale), "5-day streak", font(SANS_BOLD, 20 * scale), SAGE_DEEP)
    y += 62 * scale
    seg_w = x1 - x0 - pad * 2
    seg_h = 48 * scale
    rounded(base, (x0 + pad, y, x0 + pad + seg_w, y + seg_h), 12 * scale, (236, 230, 222), None, 0)
    half = seg_w / 2
    rounded(base, (x0 + pad + 4, y + 4, x0 + pad + half - 2, y + seg_h - 4), 10 * scale, CARD, None, 0)
    text(draw, (x0 + pad + half / 2, y + 12 * scale), "Morning", font(SANS_BOLD, 20 * scale), INK, anchor="mt")
    text(draw, (x0 + pad + half + half / 2, y + 12 * scale), "Evening", font(SANS, 20 * scale), MUTED, anchor="mt")
    y += seg_h + 22 * scale
    text(draw, (x0 + pad, y), "3 of 5", font(SERIF, 40 * scale), INK)
    y += 56 * scale
    bar = (x0 + pad, y, x1 - pad, y + 10 * scale)
    rounded(base, bar, 6 * scale, LINE, None, 0)
    rounded(base, (bar[0], bar[1], bar[0] + (bar[2] - bar[0]) * 0.6, bar[3]), 6 * scale, SAGE, None, 0)
    y += 28 * scale
    rows = [
        ("Cleanse", "Cloud Milk Cleanser", MUTED, True),
        ("Tone", "Rice Water Toner", MUTED, True),
        ("Serum", "Dawn C Serum", MUTED, True),
        ("Moisturize", "Veil Cream · 10 days left in the open-jar window", AMBER, False),
        ("Sunscreen", "Daily Veil SPF 50", MUTED, False),
    ]
    width = x1 - x0 - pad * 2
    for title, detail, color, checked in rows:
        if y > content_bottom - 70 * scale:
            break
        y = check_row(draw, x0 + pad, y, width, scale, title, detail, color, checked)
        draw.line((x0 + pad, y, x1 - pad, y), fill=LINE, width=max(1, int(scale)))
        y += 8 * scale


def paint_month(base, rect, scale):
    draw = ImageDraw.Draw(base)
    x0, y0, x1, y1 = rect
    pad = 24 * scale
    y = nav_bar(draw, rect, "Month", scale, trailing=False)
    content_bottom = tab_bar(base, rect, 1, scale)
    draw = ImageDraw.Draw(base)
    text(draw, ((x0 + x1) / 2, y), "November 2026", font(SERIF, 40 * scale), INK, anchor="mt")
    text(draw, (x0 + pad, y + 6 * scale), "<", font(SANS, 32 * scale), SAGE_DEEP)
    text(draw, (x1 - pad, y + 6 * scale), ">", font(SANS, 32 * scale), SAGE_DEEP, anchor="rt")
    y += 58 * scale
    text(draw, (x0 + pad, y), "5-day streak · longest 21", font(SANS, 22 * scale), MUTED)
    y += 40 * scale
    labels = list("SMTWTFS")
    col_w = (x1 - x0 - pad * 2) / 7
    for index, label in enumerate(labels):
        text(draw, (x0 + pad + col_w * index + col_w / 2, y), label, font(SANS_BOLD, 18 * scale), MUTED, anchor="mt")
    y += 36 * scale
    # day, mark C/P/- , in month
    weeks = [
        [(1, "C"), (2, "C"), (3, "C"), (4, "-"), (5, "P"), (6, "C"), (7, "C")],
        [(8, "C"), (9, "C"), (10, "C"), (11, "P"), (12, "-"), (13, "-"), (14, "-")],
        [(15, "-"), (16, "-"), (17, "-"), (18, "-"), (19, "-"), (20, "-"), (21, "-")],
        [(22, "-"), (23, "-"), (24, "-"), (25, "-"), (26, "-"), (27, "-"), (28, "-")],
        [(29, "-"), (30, "-")],
    ]
    row_h = 62 * scale
    for week in weeks:
        if y + row_h > content_bottom - 210 * scale:
            break
        for index, (day, mark) in enumerate(week):
            cx = x0 + pad + col_w * index + col_w / 2
            if day == 11:
                r = 16 * scale
                draw.ellipse((cx - r, y + 4 * scale, cx + r, y + 4 * scale + r * 2), outline=SAGE_DEEP, width=max(2, int(2 * scale)))
            text(draw, (cx, y + 6 * scale), str(day), font(SERIF, 22 * scale), INK, anchor="mt")
            dot = y + 40 * scale
            if mark == "C":
                draw.ellipse((cx - 5 * scale, dot, cx + 5 * scale, dot + 10 * scale), fill=SAGE)
            elif mark == "P":
                draw.ellipse((cx - 5 * scale, dot, cx + 5 * scale, dot + 10 * scale), outline=CLAY, width=max(2, int(2 * scale)))
        y += row_h
    y += 8 * scale
    text(draw, (x0 + pad, y), "Wednesday, November 11", font(SERIF, 30 * scale), INK)
    y += 40 * scale
    text(draw, (x0 + pad, y), "Morning 3 of 5 · Evening 0 of 3", font(SANS, 20 * scale), MUTED)
    y += 36 * scale
    if y < content_bottom - 40 * scale:
        text(draw, (x0 + pad, y), "Morning", font(SANS_BOLD, 18 * scale), SAGE_DEEP)
        y += 28 * scale
        for title, detail in (
            ("Cleanse", "Cloud Milk Cleanser"),
            ("Tone", "Rice Water Toner"),
            ("Serum", "Dawn C Serum"),
        ):
            if y > content_bottom - 36 * scale:
                break
            y = check_row(draw, x0 + pad, y, x1 - x0 - pad * 2, scale * 0.86, title, detail, MUTED, True)


def product_card(base, draw, box, scale, name, brand, fill_label, fraction, opened, status, status_color):
    x0, y0, x1, y1 = box
    shadow_card(base, box, 22 * scale, CARD)
    draw = ImageDraw.Draw(base)
    pad = 18 * scale
    text(draw, (x0 + pad, y0 + 16 * scale), name, font(SERIF, 30 * scale), INK)
    text(draw, (x1 - pad, y0 + 22 * scale), fill_label, font(SANS_BOLD, 16 * scale), SAGE_DEEP, anchor="rt")
    text(draw, (x0 + pad, y0 + 54 * scale), brand, font(SANS, 18 * scale), MUTED)
    bar_y = y0 + 88 * scale
    rounded(base, (x0 + pad, bar_y, x1 - pad, bar_y + 8 * scale), 4 * scale, LINE, None, 0)
    rounded(base, (x0 + pad, bar_y, x0 + pad + (x1 - x0 - pad * 2) * fraction, bar_y + 8 * scale), 4 * scale, CLAY, None, 0)
    text(draw, (x0 + pad, bar_y + 16 * scale), opened, font(SANS, 16 * scale), MUTED)
    text(draw, (x0 + pad, bar_y + 40 * scale), status, font(SANS_BOLD, 18 * scale), status_color)


def paint_shelf(base, rect, scale):
    draw = ImageDraw.Draw(base)
    x0, y0, x1, y1 = rect
    pad = 24 * scale
    y = nav_bar(draw, rect, "Shelf", scale)
    content_bottom = tab_bar(base, rect, 2, scale)
    draw = ImageDraw.Draw(base)
    y = draw_wrapped(
        draw,
        "A jar’s period after opening is the maker’s guide once the seal is broken. It is not a medical date.",
        font(SANS, 20 * scale),
        MUTED,
        (x0 + pad, y),
        x1 - x0 - pad * 2,
    )
    y += 12 * scale
    banner_h = 78 * scale
    rounded(base, (x0 + pad, y, x1 - pad, y + banner_h), 16 * scale, (236, 214, 206), None, 0)
    draw_wrapped(
        draw,
        "1 jar is past its open-jar window, and 1 is close.",
        font(SANS_BOLD, 20 * scale),
        INK,
        (x0 + pad + 16 * scale, y + 16 * scale),
        x1 - x0 - pad * 2 - 32 * scale,
    )
    y += banner_h + 16 * scale
    cards = [
        ("Night Repair Cream", "Hearth & Co. · Moisturizer", "Almost empty", 0.12, "Opened Oct 2, 2025 · 12 months", "40 days past the open-jar window", ROSE),
        ("Veil Cream", "Hearth & Co. · Moisturizer", "About a quarter", 0.25, "Opened Nov 21, 2025 · 12 months", "10 days left in the open-jar window", AMBER),
        ("Cloud Milk Cleanser", "Hearth & Co. · Cleanser", "About three quarters", 0.75, "Opened Oct 2, 2026 · 12 months", "325 days left in the open-jar window", SAGE_DEEP),
    ]
    card_h = 168 * scale
    for card in cards:
        if y + card_h > content_bottom - 8 * scale:
            break
        product_card(base, draw, (x0 + pad, y, x1 - pad, y + card_h), scale, *card)
        y += card_h + 14 * scale


def paint_notes(base, rect, scale):
    draw = ImageDraw.Draw(base)
    x0, y0, x1, y1 = rect
    pad = 24 * scale
    y = nav_bar(draw, rect, "Journal", scale, trailing=False)
    content_bottom = tab_bar(base, rect, 3, scale)
    draw = ImageDraw.Draw(base)
    seg_w = x1 - x0 - pad * 2
    seg_h = 46 * scale
    rounded(base, (x0 + pad, y, x0 + pad + seg_w, y + seg_h), 12 * scale, (236, 230, 222), None, 0)
    half = seg_w / 2
    rounded(base, (x0 + pad + 4, y + 4, x0 + pad + half - 2, y + seg_h - 4), 10 * scale, CARD, None, 0)
    text(draw, (x0 + pad + half / 2, y + 11 * scale), "Notes", font(SANS_BOLD, 20 * scale), INK, anchor="mt")
    text(draw, (x0 + pad + half * 1.5, y + 11 * scale), "Progress", font(SANS, 20 * scale), MUTED, anchor="mt")
    y += seg_h + 16 * scale
    y = draw_wrapped(
        draw,
        "A personal note for dryness, spots, mood, and sleep. Nimvelle does not assess your skin.",
        font(SANS, 18 * scale),
        MUTED,
        (x0 + pad, y),
        x1 - x0 - pad * 2,
    )
    y += 12 * scale
    text(draw, (x0 + pad, y), "Last 14 days", font(SERIF, 32 * scale), INK)
    y += 46 * scale
    series = [
        ("Dryness", CLAY, [None, 3, None, 2, None, 4, None, 3, 2, 3, 2, 1, 3, None]),
        ("Mood", SAGE, [None, 4, None, 4, None, 3, None, 4, 5, 4, 4, 5, 4, None]),
        ("Sleep", DUSK, [None, 3, None, 4, None, 2, None, 4, 5, 3, 4, 4, 4, None]),
    ]
    chart_h = 70 * scale
    gap = 5 * scale
    count = 14
    bar_w = ((x1 - x0 - pad * 2) - gap * (count - 1)) / count
    for label, color, values in series:
        if y + chart_h > content_bottom - 160 * scale:
            break
        text(draw, (x0 + pad, y), label, font(SANS_BOLD, 16 * scale), MUTED)
        y += 22 * scale
        for index, value in enumerate(values):
            bx = x0 + pad + index * (bar_w + gap)
            if value is None:
                bh = 4 * scale
                fill = LINE
            else:
                bh = max(8 * scale, chart_h * (value / 5))
                fill = color
            draw.rounded_rectangle((bx, y + chart_h - bh, bx + bar_w, y + chart_h), radius=3, fill=fill)
        y += chart_h + 12 * scale
    text(draw, (x0 + pad, y), "9 noted days. 2 days with spots in this window.", font(SANS, 18 * scale), MUTED)
    y += 36 * scale
    if y < content_bottom - 80 * scale:
        shadow_card(base, (x0 + pad, y, x1 - pad, min(content_bottom - 12 * scale, y + 120 * scale)), 18 * scale, CARD)
        draw = ImageDraw.Draw(base)
        text(draw, (x0 + pad + 16 * scale, y + 14 * scale), "Nov 10, 2026", font(SANS_BOLD, 16 * scale), SAGE_DEEP)
        text(draw, (x0 + pad + 16 * scale, y + 40 * scale), "Dry · spots none · bright · sleep sound", font(SANS, 18 * scale), INK)
        text(draw, (x0 + pad + 16 * scale, y + 70 * scale), "A bit dry by evening.", font(SANS, 18 * scale), MUTED)


def paint_progress(base, rect, scale, portrait: Path):
    draw = ImageDraw.Draw(base)
    x0, y0, x1, y1 = rect
    pad = 24 * scale
    y = nav_bar(draw, rect, "Journal", scale, trailing=False)
    content_bottom = tab_bar(base, rect, 3, scale)
    draw = ImageDraw.Draw(base)
    seg_w = x1 - x0 - pad * 2
    seg_h = 46 * scale
    rounded(base, (x0 + pad, y, x0 + pad + seg_w, y + seg_h), 12 * scale, (236, 230, 222), None, 0)
    half = seg_w / 2
    rounded(base, (x0 + pad + half + 2, y + 4, x0 + pad + seg_w - 4, y + seg_h - 4), 10 * scale, CARD, None, 0)
    text(draw, (x0 + pad + half / 2, y + 11 * scale), "Notes", font(SANS, 20 * scale), MUTED, anchor="mt")
    text(draw, (x0 + pad + half * 1.5, y + 11 * scale), "Progress", font(SANS_BOLD, 20 * scale), INK, anchor="mt")
    y += seg_h + 16 * scale
    y = draw_wrapped(
        draw,
        "Once a week is plenty. Photos stay on this device unless you save a copy to Photos.",
        font(SANS, 18 * scale),
        MUTED,
        (x0 + pad, y),
        x1 - x0 - pad * 2,
    )
    y += 14 * scale
    frame_h = min(420 * scale, content_bottom - y - 120 * scale)
    gap = 14 * scale
    frame_w = (x1 - x0 - pad * 2 - gap) / 2
    earlier = cover(portrait, (int(frame_w), int(frame_h)), focus=(0.42, 0.36))
    later = cover(portrait, (int(frame_w), int(frame_h)), focus=(0.58, 0.48))
    for index, (shot, caption, when) in enumerate((
        (earlier, "Earlier", "Nov 4, 2026"),
        (later, "Later", "Nov 11, 2026"),
    )):
        fx = x0 + pad + index * (frame_w + gap)
        shot_rgba = shot.convert("RGBA")
        mask = Image.new("L", shot.size, 0)
        ImageDraw.Draw(mask).rounded_rectangle((0, 0, frame_w, frame_h), radius=int(18 * scale), fill=255)
        base.paste(shot_rgba, (int(fx), int(y)), mask)
        text(draw, (fx, y + frame_h + 8 * scale), caption, font(SANS_BOLD, 16 * scale), MUTED)
        text(draw, (fx, y + frame_h + 30 * scale), when, font(SANS, 18 * scale), INK)
    button_y = y + frame_h + 70 * scale
    if button_y + 54 * scale < content_bottom:
        rounded(base, (x0 + pad, button_y, x1 - pad, button_y + 54 * scale), 14 * scale, SAGE_DEEP, None, 0)
        text(draw, ((x0 + x1) / 2, button_y + 14 * scale), "Add a photo", font(SANS_BOLD, 22 * scale), CARD, anchor="mt")


def compose_phone(size, model: Path, focus, kicker, title, subtitle, painter):
    width, height = size
    canvas = Image.new("RGBA", size, PAPER + (255,))
    photo_h = int(height * 0.34)
    photo = cover(model, (width, photo_h + 40), focus).convert("RGBA")
    canvas.paste(photo, (0, 0))
    fade = Image.new("RGBA", (width, 220), (0, 0, 0, 0))
    fade_draw = ImageDraw.Draw(fade)
    for row in range(220):
        alpha = int(255 * (row / 219) ** 1.15)
        fade_draw.line((0, row, width, row), fill=PAPER + (alpha,))
    canvas.alpha_composite(fade, (0, photo_h - 180))
    draw = ImageDraw.Draw(canvas)
    y = photo_h - 40
    text(draw, (56, y), kicker, font(SANS_BOLD, 22), SAGE_DEEP)
    y += 36
    for line in wrap(draw, title, font(SERIF, 68), width - 112):
        text(draw, (56, y), line, font(SERIF, 68), INK)
        y += 76
    y = draw_wrapped(draw, subtitle, font(SANS, 28), MUTED, (56, y), width - 112)
    y += 28
    card = (36, y, width - 36, height - 36)
    shadow_card(canvas, card, 36, CARD)
    scale = width / 1320
    painter(canvas, card, scale)
    return canvas.convert("RGB")


def compose_pad(size, model: Path, focus, kicker, title, subtitle, painter):
    width, height = size
    canvas = Image.new("RGBA", size, PAPER + (255,))
    margin = 48
    photo_box = (margin, margin, int(width * 0.40), height - margin)
    photo = cover(model, (photo_box[2] - photo_box[0], photo_box[3] - photo_box[1]), focus).convert("RGBA")
    mask = Image.new("L", photo.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, photo.size[0], photo.size[1]), radius=36, fill=255)
    canvas.paste(photo, (photo_box[0], photo_box[1]), mask)
    draw = ImageDraw.Draw(canvas)
    x = photo_box[2] + 48
    y = margin + 8
    text(draw, (x, y), kicker, font(SANS_BOLD, 22), SAGE_DEEP)
    y += 40
    for line in wrap(draw, title, font(SERIF, 64), width - x - margin):
        text(draw, (x, y), line, font(SERIF, 64), INK)
        y += 72
    y = draw_wrapped(draw, subtitle, font(SANS, 26), MUTED, (x, y), width - x - margin)
    y += 28
    card = (x, y, width - margin, height - margin)
    shadow_card(canvas, card, 32, CARD)
    scale = (card[2] - card[0]) / 1100
    painter(canvas, card, scale)
    return canvas.convert("RGB")


def main():
    models = copy_models()
    write_icons()
    icon = Image.open(ART / "icon" / "AppIcon-1024.png")
    if icon.mode != "RGB" or icon.size != (1024, 1024):
        raise SystemExit(f"icon must be 1024 RGB, got {icon.mode} {icon.size}")
    screens = [
        ("01-today.png", "serum", (0.48, 0.42), "TODAY", "The morning, already laid out", "Check off the steps you actually use.", lambda b, r, s: paint_today(b, r, s)),
        ("02-month.png", "amber", (0.40, 0.38), "MONTH", "A month of small check-ins", "Complete days build a streak. Today can still be open.", lambda b, r, s: paint_month(b, r, s)),
        ("03-shelf.png", "cream", (0.46, 0.34), "SHELF", "Before a jar overstays", "The open-jar window is a maker’s guide, not a medical date.", lambda b, r, s: paint_shelf(b, r, s)),
        ("04-progress.png", "moisture", (0.50, 0.40), "PROGRESS", "A week, side by side", "Optional photos stay on this device. Nothing is uploaded.", lambda b, r, s: paint_progress(b, r, s, models["moisture"])),
        ("05-notes.png", "serum", (0.52, 0.36), "NOTES", "Notes for you, not a diagnosis", "Dryness, spots, mood, and sleep. Nimvelle does not assess them.", lambda b, r, s: paint_notes(b, r, s)),
    ]
    for folder, (width, height) in SIZES.items():
        out = ART / "screenshots" / folder
        out.mkdir(parents=True, exist_ok=True)
        for name, model_key, focus, kicker, title, subtitle, painter in screens:
            if folder == "ipad-13":
                image = compose_pad((width, height), models[model_key], focus, kicker, title, subtitle, painter)
            else:
                image = compose_phone((width, height), models[model_key], focus, kicker, title, subtitle, painter)
            if image.size != (width, height) or image.mode != "RGB":
                raise SystemExit(f"{name} {folder} is {image.mode} {image.size}")
            image.save(out / name, "PNG", optimize=True)
            print(f"wrote {out / name}")


if __name__ == "__main__":
    main()
