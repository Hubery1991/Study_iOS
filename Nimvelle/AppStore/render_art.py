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


# iPhone 16 Pro logical size, drawn at @3x: 402×874 pt → 1206×2622 px.
NATIVE = (1206, 2622)


def pt(value: float) -> int:
    return int(round(value * 3))


class Screen:
    """A full iPhone screen in points. 1 pt = 3 px."""

    def __init__(self):
        self.im = Image.new("RGBA", NATIVE, PAPER + (255,))
        self.draw = ImageDraw.Draw(self.im)

    def refresh(self):
        self.draw = ImageDraw.Draw(self.im)

    def f(self, path, points):
        return font(path, max(10, pt(points)))

    def t(self, x, y, content, face, fill, anchor="lt"):
        self.draw.text((pt(x), pt(y)), content, font=face, fill=fill, anchor=anchor)

    def rrect(self, x0, y0, x1, y1, radius, fill, outline=None, width=0):
        rounded(
            self.im,
            (pt(x0), pt(y0), pt(x1), pt(y1)),
            pt(radius),
            fill,
            outline,
            max(1, pt(width)) if width else 0,
        )
        self.refresh()

    def line(self, x0, y0, x1, y1, fill, width=1):
        self.draw.line([(pt(x0), pt(y0)), (pt(x1), pt(y1))], fill=fill, width=max(1, pt(width)))

    def ellipse(self, x0, y0, x1, y1, fill=None, outline=None, width=1):
        self.draw.ellipse((pt(x0), pt(y0), pt(x1), pt(y1)), fill=fill, outline=outline, width=max(1, pt(width)) if outline else 1)

    def clip_text(self, content, face, width_pt):
        limit = pt(width_pt)
        if self.draw.textlength(content, font=face) <= limit:
            return content
        trimmed = content
        while trimmed and self.draw.textlength(trimmed + "...", font=face) > limit:
            trimmed = trimmed[:-1]
        return (trimmed + "...") if trimmed else content


def chrome(ui: Screen, title: str, active: int, plus: bool = True):
    """Status bar, navigation bar, tab bar, and home indicator. Returns the content band in points."""
    ui.rrect(138, 11, 264, 48, 18, (12, 12, 14))
    ui.t(28, 22, "9:41", ui.f(SANS_BOLD, 16), INK)
    # Minimal signal and battery, kept clear of the island.
    for index, height in enumerate((5, 7, 9, 11)):
        x = 318 + index * 5
        ui.rrect(x, 32 - height, x + 3, 32, 1, INK if index < 3 else LINE)
    ui.rrect(344, 22, 368, 33, 3, None if False else INK, INK, 1)
    ui.rrect(346, 24, 362, 31, 1, INK)

    ui.t(201, 64, title, ui.f(SERIF_REG, 17), INK, anchor="mt")
    # Leaf
    ui.ellipse(18, 66, 32, 80, fill=SAGE_DEEP)
    ui.draw.polygon([(pt(25), pt(60)), (pt(34), pt(74)), (pt(22), pt(74))], fill=SAGE_DEEP)
    if plus:
        ui.t(378, 58, "+", ui.f(SANS, 28), SAGE_DEEP, anchor="mt")

    ui.line(0, 791, 402, 791, LINE, 0.6)
    labels = ["Today", "Month", "Shelf", "Journal"]
    for index, label in enumerate(labels):
        cx = 50.25 + index * 100.5
        color = SAGE_DEEP if index == active else MUTED
        y = 804
        if index == 0:
            ui.ellipse(cx - 8, y, cx + 8, y + 16, outline=color, width=1.6)
        elif index == 1:
            ui.rrect(cx - 8, y, cx + 8, y + 16, 2, None, color, 1.4)
            ui.line(cx - 8, y + 5, cx + 8, y + 5, color, 1.2)
        elif index == 2:
            ui.rrect(cx - 8, y + 1, cx + 8, y + 16, 2, None, color, 1.4)
        else:
            ui.line(cx - 8, y + 3, cx + 8, y + 3, color, 1.4)
            ui.line(cx - 8, y + 8, cx + 5, y + 8, color, 1.4)
            ui.line(cx - 8, y + 13, cx + 8, y + 13, color, 1.4)
        ui.t(cx, 824, label, ui.f(SANS_BOLD if index == active else SANS, 10), color, anchor="mt")
    ui.rrect(134, 858, 268, 863, 3, (90, 86, 80))
    return 108, 784


def check_mark(ui: Screen, cx, cy, on: bool):
    r = 11
    if on:
        ui.ellipse(cx - r, cy - r, cx + r, cy + r, fill=SAGE)
        ui.line(cx - 5, cy, cx - 1, cy + 4, WHITE, 2)
        ui.line(cx - 1, cy + 4, cx + 6, cy - 5, WHITE, 2)
    else:
        ui.ellipse(cx - r, cy - r, cx + r, cy + r, outline=LINE, width=1.6)


def step_row(ui: Screen, x, y, width, height, title, detail, detail_color, checked):
    check_mark(ui, x + 12, y + height / 2, checked)
    title_face = ui.f(SERIF_REG, 17)
    detail_face = ui.f(SANS, 13)
    ui.t(x + 32, y + 8, title, title_face, INK)
    ui.t(x + 32, y + 30, ui.clip_text(detail, detail_face, width - 36), detail_face, detail_color)
    ui.line(x, y + height - 0.5, x + width, y + height - 0.5, LINE, 0.5)


def paint_today(_portrait=None) -> Image.Image:
    ui = Screen()
    top, bottom = chrome(ui, "Today", 0, plus=True)
    height = bottom - top
    # Header block, then morning (5) and evening (3) rows share the rest.
    header = 118
    morning_label = 36
    evening_label = 36
    rows_h = height - header - morning_label - evening_label
    row_h = rows_h / 8
    y = top
    ui.t(20, y, "Wednesday, November 11", ui.f(SANS, 15), MUTED)
    y += 22
    ui.t(20, y, "Good morning", ui.f(SERIF_REG, 34), INK)
    y += 46
    ui.rrect(20, y, 148, y + 28, 14, (236, 214, 206))
    ui.t(34, y + 5, "5-day streak", ui.f(SANS_BOLD, 13), SAGE_DEEP)
    y += 40
    ui.t(20, y, "Morning", ui.f(SANS_BOLD, 13), SAGE_DEEP)
    ui.t(382, y, "3 of 5", ui.f(SANS_BOLD, 13), INK, anchor="rt")
    y += 20
    ui.rrect(20, y, 382, y + 6, 3, LINE)
    ui.rrect(20, y, 20 + 362 * 0.6, y + 6, 3, SAGE)
    y += 16
    morning = [
        ("Cleanse", "Cloud Milk Cleanser", MUTED, True),
        ("Tone", "Rice Water Toner", MUTED, True),
        ("Serum", "Dawn C Serum", MUTED, True),
        ("Moisturize", "Veil Cream · 10 days left in the open-jar window", AMBER, False),
        ("Sunscreen", "Daily Veil SPF 50", MUTED, False),
    ]
    for title, detail, color, done in morning:
        step_row(ui, 20, y, 362, row_h, title, detail, color, done)
        y += row_h
    y += 8
    ui.t(20, y, "Evening", ui.f(SANS_BOLD, 13), SAGE_DEEP)
    ui.t(382, y, "0 of 3", ui.f(SANS_BOLD, 13), INK, anchor="rt")
    y += 20
    ui.rrect(20, y, 382, y + 6, 3, LINE)
    y += 16
    evening = [
        ("Cleanse", "Cloud Milk Cleanser", MUTED, False),
        ("Tone", "Rice Water Toner", MUTED, False),
        ("Night cream", "Night Repair Cream · 40 days past the open-jar window", ROSE, False),
    ]
    for title, detail, color, done in evening:
        step_row(ui, 20, y, 362, row_h, title, detail, color, done)
        y += row_h
    return ui.im


def paint_month(_portrait=None) -> Image.Image:
    ui = Screen()
    top, bottom = chrome(ui, "Month", 1, plus=False)
    y = top
    ui.t(28, y + 4, "<", ui.f(SANS, 22), SAGE_DEEP)
    ui.t(374, y + 4, ">", ui.f(SANS, 22), SAGE_DEEP, anchor="rt")
    ui.t(201, y, "November 2026", ui.f(SERIF_REG, 22), INK, anchor="mt")
    y += 36
    ui.t(20, y, "5-day streak   ·   longest 21   ·   8 complete days", ui.f(SANS, 13), MUTED)
    y += 28
    col = 362 / 7
    for index, label in enumerate("SMTWTFS"):
        ui.t(20 + col * index + col / 2, y, label, ui.f(SANS_BOLD, 12), MUTED, anchor="mt")
    y += 22
    summary_top = bottom - 248
    row_h = (summary_top - 8 - y) / 5
    weeks = [
        [(1, "C", True), (2, "C", True), (3, "C", True), (4, "-", True), (5, "P", True), (6, "C", True), (7, "C", True)],
        [(8, "C", True), (9, "C", True), (10, "C", True), (11, "P", True), (12, "-", True), (13, "-", True), (14, "-", True)],
        [(15, "-", True), (16, "-", True), (17, "-", True), (18, "-", True), (19, "-", True), (20, "-", True), (21, "-", True)],
        [(22, "-", True), (23, "-", True), (24, "-", True), (25, "-", True), (26, "-", True), (27, "-", True), (28, "-", True)],
        [(29, "-", True), (30, "-", True), (1, "-", False), (2, "-", False), (3, "-", False), (4, "-", False), (5, "-", False)],
    ]
    for week in weeks:
        for index, (day, mark, in_month) in enumerate(week):
            cx = 20 + col * index + col / 2
            num_y = y + 4
            color = INK if in_month else (186, 178, 168)
            if day == 11 and in_month:
                ui.ellipse(cx - 14, num_y - 2, cx + 14, num_y + 26, outline=SAGE_DEEP, width=1.6)
            ui.t(cx, num_y, str(day), ui.f(SERIF_REG, 17), color, anchor="mt")
            dot_y = y + row_h - 16
            if mark == "C":
                ui.ellipse(cx - 4, dot_y, cx + 4, dot_y + 8, fill=SAGE)
            elif mark == "P":
                ui.ellipse(cx - 4, dot_y, cx + 4, dot_y + 8, outline=CLAY, width=2)
        y += row_h
    y = summary_top
    ui.rrect(16, y, 386, bottom - 8, 16, CARD, LINE, 1)
    ui.t(28, y + 12, "Wednesday, November 11", ui.f(SERIF_REG, 18), INK)
    ui.t(28, y + 38, "Morning 3 of 5  ·  Evening 0 of 3", ui.f(SANS, 13), MUTED)
    items = [
        ("Moisturize", "Veil Cream · 10 days left", AMBER, False),
        ("Sunscreen", "Daily Veil SPF 50", MUTED, False),
        ("Night cream", "Past the open-jar window", ROSE, False),
    ]
    iy = y + 64
    row_left = (bottom - 16 - iy) / 3
    for title, detail, color, done in items:
        step_row(ui, 28, iy, 340, row_left, title, detail, color, done)
        iy += row_left
    return ui.im


def paint_shelf(_portrait=None) -> Image.Image:
    ui = Screen()
    top, bottom = chrome(ui, "Shelf", 2, plus=True)
    y = top
    face = ui.f(SANS, 13)
    y = draw_wrapped(
        ui.draw,
        "A period after opening is the maker's guide for an opened jar. It is not a medical date.",
        face,
        MUTED,
        (pt(20), pt(y)),
        pt(362),
    ) / 3 + 8
    banner_h = 52
    ui.rrect(16, y, 386, y + banner_h, 14, (236, 214, 206))
    ui.t(28, y + 8, "1 jar is past its open-jar window,", ui.f(SANS_BOLD, 14), INK)
    ui.t(28, y + 28, "and 1 is close.", ui.f(SANS_BOLD, 14), INK)
    y += banner_h + 10
    products = [
        ("Night Repair Cream", "Hearth & Co. · Moisturizer", "Almost empty", 0.12, "Opened Oct 2, 2025 · 12 months", "40 days past the open-jar window", ROSE),
        ("Veil Cream", "Hearth & Co. · Moisturizer", "About a quarter", 0.25, "Opened Nov 21, 2025 · 12 months", "10 days left in the open-jar window", AMBER),
        ("Cloud Milk Cleanser", "Hearth & Co. · Cleanser", "About three quarters", 0.75, "Opened Oct 2, 2026 · 12 months", "325 days left in the open-jar window", SAGE_DEEP),
        ("Rice Water Toner", "Hearth & Co. · Toner", "About half", 0.5, "Opened Oct 2, 2026 · 12 months", "325 days left in the open-jar window", SAGE_DEEP),
        ("Dawn C Serum", "Lumen Atelier · Serum", "About three quarters", 0.75, "Opened Sep 22, 2026 · 6 months", "131 days left in the open-jar window", SAGE_DEEP),
        ("Daily Veil SPF 50", "Lumen Atelier · Sunscreen", "About half", 0.5, "Opened Aug 23, 2026 · 12 months", "285 days left in the open-jar window", SAGE_DEEP),
    ]
    gap = 8
    card_h = (bottom - y - gap * (len(products) - 1)) / len(products)
    name_face = ui.f(SERIF_REG, 16)
    small = ui.f(SANS, 12)
    status_face = ui.f(SANS_BOLD, 12)
    for name, brand, fill_label, fraction, opened, status, color in products:
        ui.rrect(16, y, 386, y + card_h - 1, 14, CARD, LINE, 1)
        ui.t(26, y + 8, ui.clip_text(name, name_face, 210), name_face, INK)
        ui.t(376, y + 10, fill_label, ui.f(SANS_BOLD, 11), SAGE_DEEP, anchor="rt")
        ui.t(26, y + 30, brand, small, MUTED)
        bar_y = y + 50
        ui.rrect(26, bar_y, 376, bar_y + 6, 3, LINE)
        ui.rrect(26, bar_y, 26 + 350 * fraction, bar_y + 6, 3, CLAY)
        ui.t(26, y + 60, opened, small, MUTED)
        ui.t(26, y + 78, ui.clip_text(status, status_face, 340), status_face, color)
        y += card_h + gap
    return ui.im


def paint_notes(_portrait=None) -> Image.Image:
    ui = Screen()
    top, bottom = chrome(ui, "Journal", 3, plus=False)
    y = top
    ui.rrect(16, y, 386, y + 32, 10, (236, 230, 222))
    ui.rrect(18, y + 2, 200, y + 30, 8, CARD)
    ui.t(109, y + 7, "Notes", ui.f(SANS_BOLD, 13), INK, anchor="mt")
    ui.t(293, y + 7, "Progress", ui.f(SANS, 13), MUTED, anchor="mt")
    y += 42
    y = draw_wrapped(
        ui.draw,
        "A personal note for dryness, spots, mood, and sleep. Nimvelle does not assess your skin.",
        ui.f(SANS, 13),
        MUTED,
        (pt(20), pt(y)),
        pt(362),
    ) / 3 + 6
    ui.t(20, y, "Last 14 days", ui.f(SERIF_REG, 20), INK)
    y += 28
    series = [
        ("Dryness", CLAY, [None, 3, None, 2, None, 4, None, 3, 2, 3, 2, 1, 3, None]),
        ("Mood", SAGE, [None, 4, None, 4, None, 3, None, 4, 5, 4, 4, 5, 4, None]),
        ("Sleep", DUSK, [None, 3, None, 4, None, 2, None, 4, 5, 3, 4, 4, 4, None]),
    ]
    chart_block = 64
    for label, color, values in series:
        ui.t(20, y, label, ui.f(SANS_BOLD, 12), MUTED)
        y += 16
        bar_h = 40
        gap = 4
        count = len(values)
        bar_w = (362 - gap * (count - 1)) / count
        for index, value in enumerate(values):
            bx = 20 + index * (bar_w + gap)
            if value is None:
                bh, fill = 4, LINE
            else:
                bh, fill = max(8, bar_h * (value / 5)), color
            ui.rrect(bx, y + bar_h - bh, bx + bar_w, y + bar_h, 2, fill)
        y += bar_h + 8
    ui.t(20, y, "9 noted days. 2 days with spots in this window.", ui.f(SANS, 12), MUTED)
    y += 22
    ui.t(20, y, "Recent", ui.f(SERIF_REG, 18), INK)
    y += 26
    notes = [
        ("Nov 10, 2026", "Dry · spots none · bright · sleep sound", "A bit dry by evening."),
        ("Nov 9, 2026", "Comfortable · spots none · light · sleep sound", "Felt comfortable all day."),
        ("Nov 7, 2026", "Dry · spots a little · bright · sleep okay", "One small spot on the chin."),
    ]
    gap = 8
    card_h = (bottom - y - gap * (len(notes) - 1)) / len(notes)
    for date, summary, body in notes:
        ui.rrect(16, y, 386, y + card_h - 1, 14, CARD, LINE, 1)
        ui.t(26, y + 8, date, ui.f(SANS_BOLD, 12), SAGE_DEEP)
        ui.t(26, y + 28, ui.clip_text(summary, ui.f(SANS, 13), 340), ui.f(SANS, 13), INK)
        ui.t(26, y + 48, body, ui.f(SANS, 13), MUTED)
        y += card_h + gap
    return ui.im


def paint_progress(portrait: Path) -> Image.Image:
    ui = Screen()
    top, bottom = chrome(ui, "Journal", 3, plus=False)
    y = top
    ui.rrect(16, y, 386, y + 32, 10, (236, 230, 222))
    ui.rrect(202, y + 2, 384, y + 30, 8, CARD)
    ui.t(109, y + 7, "Notes", ui.f(SANS, 13), MUTED, anchor="mt")
    ui.t(293, y + 7, "Progress", ui.f(SANS_BOLD, 13), INK, anchor="mt")
    y += 42
    y = draw_wrapped(
        ui.draw,
        "Once a week is plenty. Photos stay on this device unless you save a copy to Photos.",
        ui.f(SANS, 13),
        MUTED,
        (pt(20), pt(y)),
        pt(362),
    ) / 3 + 8
    list_h = 132
    button_h = 44
    caption_h = 36
    photo_h = bottom - y - caption_h - button_h - list_h - 16
    frame_w = 174
    earlier = cover(portrait, (pt(frame_w), pt(photo_h)), focus=(0.42, 0.32))
    later = cover(portrait, (pt(frame_w), pt(photo_h)), focus=(0.62, 0.40))
    for index, shot in enumerate((earlier, later)):
        fx = 20 + index * (frame_w + 14)
        mask = Image.new("L", shot.size, 0)
        ImageDraw.Draw(mask).rounded_rectangle((0, 0, shot.size[0], shot.size[1]), radius=pt(14), fill=255)
        ui.im.paste(shot.convert("RGBA"), (pt(fx), pt(y)), mask)
        ui.refresh()
    y += photo_h + 6
    ui.t(20, y, "Earlier", ui.f(SANS_BOLD, 12), MUTED)
    ui.t(20, y + 16, "Nov 4, 2026", ui.f(SANS, 13), INK)
    ui.t(208, y, "Later", ui.f(SANS_BOLD, 12), MUTED)
    ui.t(208, y + 16, "Nov 11, 2026", ui.f(SANS, 13), INK)
    y += caption_h
    ui.rrect(16, y, 386, y + button_h, 12, SAGE_DEEP)
    ui.t(201, y + 12, "Add a photo", ui.f(SANS_BOLD, 16), CARD, anchor="mt")
    y += button_h + 12
    ui.t(20, y, "On this device", ui.f(SERIF_REG, 16), INK)
    y += 24
    ui.t(20, y, "Nov 4  ·  earlier", ui.f(SANS, 14), INK)
    ui.t(20, y + 20, "Nov 11  ·  later", ui.f(SANS, 14), INK)
    ui.t(20, y + 48, "Nothing is uploaded.", ui.f(SANS, 13), MUTED)
    return ui.im


def phone_frame(canvas: Image.Image, origin, screen_image: Image.Image):
    x, y = origin
    sw, sh = screen_image.size
    bezel = max(12, int(sw * 0.022))
    radius = max(36, int(sw * 0.115))
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
    photo_h = 640
    photo = cover(model, (CANVAS[0], photo_h), focus).convert("RGBA")
    canvas.paste(photo, (0, 0))
    fade_h = 90
    fade = Image.new("RGBA", (CANVAS[0], fade_h), (0, 0, 0, 0))
    fade_draw = ImageDraw.Draw(fade)
    for row in range(fade_h):
        alpha = int(255 * (row / (fade_h - 1)) ** 1.35)
        fade_draw.line((0, row, CANVAS[0], row), fill=(214, 236, 228, alpha))
    canvas.alpha_composite(fade, (0, photo_h - fade_h))
    draw = ImageDraw.Draw(canvas)
    y = photo_h + 16
    text(draw, (48, y), kicker, font(SANS_BOLD, 16), MINT_DEEP)
    y += 24
    for line in wrap(draw, title, font(SERIF, 46), CANVAS[0] - 100):
        text(draw, (48, y), line, font(SERIF, 46), MINT_DEEP)
        y += 52
    y = draw_wrapped(draw, subtitle, font(SANS, 22), (70, 104, 98), (48, y + 2), CANVAS[0] - 100)
    bezel_guess = 16
    bottom_margin = 22
    top = int(y + 18)
    avail = CANVAS[1] - top - bottom_margin
    screen_h = int(avail - 2 * bezel_guess)
    screen_w = int(screen_h * NATIVE[0] / NATIVE[1])
    if screen_w + 48 > CANVAS[0]:
        screen_w = CANVAS[0] - 48
        screen_h = int(screen_w * NATIVE[1] / NATIVE[0])
    native = painter()
    if native.size != NATIVE:
        raise SystemExit(f"native screen {native.size}")
    screen = native.resize((screen_w, screen_h), Image.Resampling.LANCZOS)
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
        ("01-today.png", "serum", (0.48, 0.42), "TODAY", "The morning, already laid out", "Check off the steps you actually use.", paint_today),
        ("02-month.png", "cream", (0.50, 0.42), "MONTH", "A month of small check-ins", "Complete days build a streak. Today can still be open.", paint_month),
        ("03-shelf.png", "jar", (0.48, 0.50), "SHELF", "Before a jar overstays", "An open-jar window is a storage guide, not a medical date.", paint_shelf),
        ("04-notes.png", "cleanse", (0.50, 0.44), "NOTES", "Notes for you, not a diagnosis", "Dryness, spots, mood, and sleep. Nothing is assessed.", paint_notes),
        ("05-progress.png", "serum", (0.42, 0.40), "PROGRESS", "A week, side by side", "Optional photos stay on this iPhone.", lambda: paint_progress(models["serum"])),
    ]
    for name, key, focus, kicker, title, subtitle, painter in screens:
        image = compose(models[key], focus, kicker, title, subtitle, painter)
        if image.size != CANVAS or image.mode != "RGB":
            raise SystemExit(f"{name} is {image.mode} {image.size}")
        image.save(SHOT_DIR / name, "PNG", optimize=True)
        print(f"wrote {SHOT_DIR / name} {image.size}")


if __name__ == "__main__":
    main()
