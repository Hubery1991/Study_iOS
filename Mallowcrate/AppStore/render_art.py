#!/usr/bin/env python3
"""Render the App Store icon set and marketing screenshots.

Icons are resized from the approved artwork at AppStore/icon/approved-source.jpg.
They stay full-bleed squares. iOS applies the rounded mask.

Screenshots are composed at 1206×2622, then the same layout is scaled for the
other required sizes and adapted for iPad. Each shot places the SwiftUI-matching
screen inside an iPhone bezel. This environment has no iOS Simulator.

    python3 Mallowcrate/AppStore/render_art.py
"""

from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
LEVELS = json.loads((ROOT / "AppStore" / "levels.json").read_text())
FONT_BOLD = "/usr/share/fonts/truetype/macos/Inter-Bold.ttf"
FONT_SEMI = "/usr/share/fonts/truetype/macos/Inter-SemiBold.ttf"

SKY_TOP = (126, 200, 255)
SKY_MID = (183, 228, 255)
SKY_BOTTOM = (255, 243, 196)
HILL = (126, 208, 122)
HILL_DEEP = (78, 174, 104)
INK = (74, 52, 40)
INK_SOFT = (122, 91, 72)
CREAM = (255, 248, 238)
CREAM_DEEP = (255, 231, 196)
CORAL = (255, 122, 89)
LEAF = (60, 179, 113)
GOLD = (255, 200, 87)
GOLD_DEEP = (240, 162, 2)
CRATE_BAND = (224, 138, 30)
CRATE_EDGE = (196, 106, 18)
BLUSH = (255, 155, 179)
RASPBERRY = (227, 106, 138)
RASPBERRY_DEEP = (196, 75, 112)
FLOOR = (255, 230, 184)
FLOOR_ALT = (255, 217, 160)
BOARD = (255, 241, 212)
BOARD_RIM = (226, 181, 106)
WHITE = (255, 255, 255)

# Folder, pixel size, layout. iphone-1206 is the source composition.
SHOT_SIZES = [
    ("iphone-1206", 1206, 2622, "phone"),
    ("iphone-6.9", 1320, 2868, "phone"),
    ("iphone-6.7", 1284, 2778, "phone"),
    ("iphone-6.5", 1242, 2688, "phone"),
    ("ipad-13", 2064, 2752, "pad"),
]
ICON_SOURCE = ROOT / "AppStore" / "icon" / "approved-source.jpg"


def font(kind: str, points: float, scale: float) -> ImageFont.FreeTypeFont:
    path = FONT_BOLD if kind == "bold" else FONT_SEMI
    return ImageFont.truetype(path, max(8, int(points * scale)))


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def vertical_gradient(w, h, c1, c2):
    image = Image.new("RGB", (max(1, w), max(1, h)))
    pixels = image.load()
    for y in range(h):
        color = lerp(c1, c2, y / max(1, h - 1))
        for x in range(w):
            pixels[x, y] = color
    return image


class Canvas:
    def __init__(self, width, height, scale):
        self.scale = scale
        self.image = Image.new("RGB", (width, height), SKY_TOP)
        self.draw = ImageDraw.Draw(self.image)
        self.point_w = width / scale
        self.point_h = height / scale

    def px(self, value):
        return value * self.scale

    def box(self, x, y, w, h):
        return [self.px(x), self.px(y), self.px(x + w), self.px(y + h)]

    def rounded(self, x, y, w, h, radius, fill, outline=None, width=0):
        self.draw.rounded_rectangle(
            self.box(x, y, w, h),
            radius=self.px(radius),
            fill=fill,
            outline=outline,
            width=max(1, int(self.px(width))) if width else 0,
        )

    def ellipse(self, x, y, w, h, fill, outline=None, width=0):
        self.draw.ellipse(
            self.box(x, y, w, h),
            fill=fill,
            outline=outline,
            width=max(1, int(self.px(width))) if width else 0,
        )

    def paste_gradient_round(self, x, y, w, h, radius, c1, c2):
        pw, ph = max(1, int(self.px(w))), max(1, int(self.px(h)))
        grad = vertical_gradient(pw, ph, c1, c2)
        mask = Image.new("L", (pw, ph), 0)
        ImageDraw.Draw(mask).rounded_rectangle((0, 0, pw - 1, ph - 1), radius=max(1, int(self.px(radius))), fill=255)
        self.image.paste(grad, (int(self.px(x)), int(self.px(y))), mask)

    def paste_gradient_ellipse(self, x, y, w, h, c1, c2):
        pw, ph = max(1, int(self.px(w))), max(1, int(self.px(h)))
        grad = vertical_gradient(pw, ph, c1, c2)
        mask = Image.new("L", (pw, ph), 0)
        ImageDraw.Draw(mask).ellipse((0, 0, pw - 1, ph - 1), fill=255)
        self.image.paste(grad, (int(self.px(x)), int(self.px(y))), mask)

    def text(self, value, x, y, size, fill, kind="bold", anchor="mm"):
        face = font(kind, size, self.scale)
        self.draw.text((self.px(x), self.px(y)), value, font=face, fill=fill, anchor=anchor)

    def text_width(self, value, size, kind="bold"):
        face = font(kind, size, self.scale)
        box = self.draw.textbbox((0, 0), value, font=face)
        return (box[2] - box[0]) / self.scale

    def meadow(self):
        column = Image.new("RGB", (1, self.image.height))
        pixels = column.load()
        for y in range(self.image.height):
            t = y / max(1, self.image.height - 1)
            if t < 0.55:
                color = lerp(SKY_TOP, SKY_MID, t / 0.55)
            else:
                color = lerp(SKY_MID, SKY_BOTTOM, (t - 0.55) / 0.45)
            pixels[0, y] = color
        self.image.paste(column.resize(self.image.size, Image.Resampling.BILINEAR), (0, 0))
        self.draw = ImageDraw.Draw(self.image)
        sun = self.point_w * 0.28
        self.ellipse(self.point_w * 0.82, -sun * 0.42, sun, sun, (255, 227, 138), WHITE, 4)
        self.cloud(self.point_w * 0.18, self.point_h * 0.12, 1)
        self.cloud(self.point_w * 0.55, self.point_h * 0.18, 0.7)
        self.ellipse(-self.point_w * 0.2, self.point_h * 0.86, self.point_w * 1.1, self.point_h * 0.28, HILL_DEEP)
        self.ellipse(self.point_w * 0.25, self.point_h * 0.9, self.point_w * 1.05, self.point_h * 0.22, HILL)

    def cloud(self, x, y, scale):
        self.ellipse(x, y + 6 * scale, 90 * scale, 34 * scale, WHITE)
        self.ellipse(x + 8 * scale, y - 8 * scale, 46 * scale, 36 * scale, WHITE)
        self.ellipse(x + 36 * scale, y - 10 * scale, 54 * scale, 40 * scale, WHITE)

    def mallow(self, x, y, side, facing="down"):
        s = side
        self.ellipse(x + s * 0.28, y + s * 0.8, s * 0.44, s * 0.1, (196, 164, 130))
        self.rounded(x + s * 0.22, y + s * 0.72, s * 0.14, s * 0.12, s * 0.06, (242, 184, 154))
        self.rounded(x + s * 0.62, y + s * 0.72, s * 0.14, s * 0.12, s * 0.06, (242, 184, 154))
        self.paste_gradient_ellipse(x + s * 0.14, y + s * 0.16, s * 0.72, s * 0.62, WHITE, (255, 216, 198))
        self.ellipse(x + s * 0.14, y + s * 0.16, s * 0.72, s * 0.62, None, (231, 179, 154), max(2, s * 0.03))
        self.ellipse(x + s * 0.34, y + s * 0.46, s * 0.32, s * 0.18, (255, 255, 255))
        self.ellipse(x + s * 0.2, y + s * 0.42, s * 0.12, s * 0.08, BLUSH)
        self.ellipse(x + s * 0.66, y + s * 0.42, s * 0.12, s * 0.08, BLUSH)
        nudge = {"left": -0.03, "right": 0.03, "up": 0, "down": 0}[facing]
        lift = -0.02 if facing == "up" else 0
        for origin in (0.28, 0.56):
            self.ellipse(x + s * (origin + nudge), y + s * (0.32 + lift), s * 0.1, s * 0.12, (58, 42, 36))
            self.ellipse(x + s * (origin + nudge + 0.015), y + s * (0.34 + lift), s * 0.035, s * 0.035, WHITE)
        smile_box = self.box(x + s * 0.38, y + s * 0.48, s * 0.24, s * 0.16)
        self.draw.arc(smile_box, 20, 160, fill=(107, 70, 54), width=max(2, int(self.px(s * 0.025))))
        self.ellipse(x + s * 0.18, y + s * 0.08, s * 0.22, s * 0.12, (92, 191, 106))
        self.ellipse(x + s * 0.58, y + s * 0.07, s * 0.22, s * 0.12, (139, 224, 138))
        self.rounded(x + s * 0.46, y + s * 0.12, s * 0.06, s * 0.16, s * 0.03, (47, 138, 69))

    def crate(self, x, y, side, on_goal=False):
        s = side
        self.ellipse(x + s * 0.16, y + s * 0.78, s * 0.68, s * 0.12, (214, 176, 140))
        self.paste_gradient_round(x + s * 0.1, y + s * 0.08, s * 0.8, s * 0.8, s * 0.18, (255, 213, 106), GOLD_DEEP)
        self.rounded(x + s * 0.1, y + s * 0.08, s * 0.8, s * 0.8, s * 0.18, None, CRATE_EDGE, max(2, s * 0.045))
        self.rounded(x + s * 0.1, y + s * 0.22, s * 0.8, s * 0.1, s * 0.04, CRATE_BAND)
        self.rounded(x + s * 0.1, y + s * 0.58, s * 0.8, s * 0.1, s * 0.04, CRATE_BAND)
        self.rounded(x + s * 0.18, y + s * 0.14, s * 0.22, s * 0.08, s * 0.04, (255, 255, 255))
        cx, cy, cs = x + s * 0.38, y + s * 0.34, s * 0.1
        self.ellipse(cx, cy - cs * 0.2, cs, cs, (196, 92, 42))
        self.ellipse(cx - cs * 0.45, cy + cs * 0.35, cs, cs, (196, 92, 42))
        self.ellipse(cx + cs * 0.45, cy + cs * 0.35, cs, cs, (196, 92, 42))
        if on_goal:
            self.ellipse(x + s * 0.04, y + s * 0.02, s * 0.92, s * 0.92, None, WHITE, max(2, s * 0.04))

    def daisy(self, x, y, side, filled=False):
        s = side
        cx, cy = x + s / 2, y + s / 2
        self.ellipse(x + s * 0.12, y + s * 0.12, s * 0.76, s * 0.76, (126, 208, 122))
        for index in range(8):
            # Petals are drawn as ellipses around the center by placing them on a ring.
            import math
            angle = index * math.pi / 4
            px = cx + math.cos(angle) * s * 0.22 - s * 0.09
            py = cy + math.sin(angle) * s * 0.22 - s * 0.14
            self.ellipse(px, py, s * 0.18, s * 0.28, WHITE)
        self.ellipse(cx - s * 0.13, cy - s * 0.13, s * 0.26, s * 0.26, GOLD, WHITE, 1.5)
        if filled:
            self.ellipse(x + s * 0.04, y + s * 0.04, s * 0.92, s * 0.92, None, (255, 236, 170), 2)

    def wall(self, x, y, side):
        s = side
        self.paste_gradient_round(x + s * 0.06, y + s * 0.06, s * 0.88, s * 0.88, s * 0.24, (255, 143, 176), RASPBERRY_DEEP)
        self.rounded(x + s * 0.06, y + s * 0.06, s * 0.88, s * 0.88, s * 0.24, None, (163, 58, 92), max(2, s * 0.04))
        self.ellipse(x + s * 0.28, y + s * 0.16, s * 0.36, s * 0.16, (255, 255, 255))
        for index, color in enumerate((GOLD, WHITE, (126, 208, 255))):
            self.rounded(x + s * (0.24 + index * 0.2), y + s * 0.55, s * 0.1, s * 0.06, s * 0.03, color)

    def floor_tile(self, x, y, side, alt):
        pad = side * 0.06
        self.rounded(x + pad, y + pad, side - pad * 2, side - pad * 2, side * 0.16, FLOOR_ALT if alt else FLOOR)

    def star(self, cx, cy, r, filled):
        import math
        points = []
        for index in range(10):
            angle = index * math.pi / 5 - math.pi / 2
            radius = r if index % 2 == 0 else r * 0.46
            points.append((self.px(cx + math.cos(angle) * radius), self.px(cy + math.sin(angle) * radius)))
        self.draw.polygon(points, fill=GOLD if filled else CREAM_DEEP, outline=CRATE_EDGE)

    def jelly(self, x, y, w, h, title, fill, ink, subtitle=None):
        self.rounded(x, y + 5, w, h, 22, (74, 52, 40))
        self.rounded(x, y, w, h, 22, fill)
        if subtitle:
            self.text(title, x + w / 2, y + h * 0.38, 22, ink)
            self.text(subtitle, x + w / 2, y + h * 0.68, 13, ink, "semi")
        else:
            self.text(title, x + w / 2, y + h / 2, 18, ink)

    def status(self, top):
        y = max(12, top * 0.45)
        self.text("9:41", 46, y, 15, INK, anchor="lm")
        x = self.point_w - 78
        for index in range(4):
            height = 4 + index * 2
            self.rounded(x + index * 6, y - height / 2, 4, height, 1, INK)
        self.rounded(self.point_w - 46, y - 6, 24, 12, 3, None, INK, 1.4)
        self.rounded(self.point_w - 44, y - 4, 14, 8, 2, INK)

    def panel(self, x, y, w, h):
        self.rounded(x, y + 6, w, h, 26, (214, 176, 140))
        self.rounded(x, y, w, h, 26, CREAM)


def replay(level, moves):
    rows = [list(row) for row in level["rows"]]
    height, width = len(rows), len(rows[0])
    player = None
    crates = set()
    for r, row in enumerate(rows):
        for c, ch in enumerate(row):
            if ch in "@+":
                player = (r, c)
                if ch == "@":
                    rows[r][c] = " "
                else:
                    rows[r][c] = "."
            elif ch in "$*":
                crates.add((r, c))
                rows[r][c] = "." if ch == "*" else " "
    deltas = {"U": (-1, 0), "D": (1, 0), "L": (0, -1), "R": (0, 1)}
    landed = None
    for step, letter in enumerate(moves, start=1):
        dr, dc = deltas[letter]
        r, c = player
        nr, nc = r + dr, c + dc
        if not (0 <= nr < height and 0 <= nc < width) or rows[nr][nc] == "#":
            continue
        if (nr, nc) in crates:
            br, bc = nr + dr, nc + dc
            if not (0 <= br < height and 0 <= bc < width) or rows[br][bc] == "#" or (br, bc) in crates:
                continue
            crates.remove((nr, nc))
            crates.add((br, bc))
            if rows[br][bc] == ".":
                landed = (br, bc, step)
        player = (nr, nc)
    return rows, player, crates, landed


def draw_board(canvas: Canvas, level, moves, origin, cell, sparkle=False):
    rows, player, crates, landed = replay(level, moves)
    height, width = len(rows), len(rows[0])
    board_w = cell * width
    board_h = cell * height
    ox, oy = origin
    canvas.rounded(ox - 12, oy - 12, board_w + 24, board_h + 24, 28, BOARD, BOARD_RIM, 6)
    for r in range(height):
        for c in range(width):
            x, y = ox + c * cell, oy + r * cell
            if rows[r][c] == "#":
                canvas.wall(x, y, cell)
            else:
                canvas.floor_tile(x, y, cell, (r + c) % 2 == 0)
                if rows[r][c] == ".":
                    canvas.daisy(x + cell * 0.08, y + cell * 0.08, cell * 0.84, filled=(r, c) in crates)
            if (r, c) in crates:
                canvas.crate(x + cell * 0.08, y + cell * 0.08, cell * 0.84, on_goal=rows[r][c] == ".")
    pr, pc = player
    canvas.mallow(ox + pc * cell + cell * 0.08, oy + pr * cell + cell * 0.04, cell * 0.84, "right")
    if sparkle and landed:
        br, bc, _ = landed
        import math
        cx = ox + bc * cell + cell / 2
        cy = oy + br * cell + cell / 2
        for index in range(8):
            angle = index * math.pi / 4
            canvas.star(cx + math.cos(angle) * cell * 0.46, cy + math.sin(angle) * cell * 0.46, cell * 0.09, True)
    return board_w, board_h, landed


def column(canvas: Canvas, width):
    if canvas.point_w > 700:
        return (canvas.point_w - width) / 2, width
    side = 22
    return side, canvas.point_w - side * 2


def screen_home(canvas: Canvas, top, bottom):
    canvas.meadow()
    canvas.status(top)
    x, width = column(canvas, 480)
    y = top + 18
    group = min(170, width * 0.4)
    mid = x + width / 2
    canvas.daisy(mid - group * 0.95, y + 50, 72)
    canvas.mallow(mid - 75, y, 150)
    canvas.crate(mid + 55, y + 48, 86)
    y += 176
    canvas.text("Mallowcrate", mid, y, 46, INK)
    y += 36
    canvas.text("Nudge every honey crate onto a daisy.", mid, y, 16, INK_SOFT, "semi")
    y += 36
    canvas.rounded(mid - 78, y, 156, 32, 16, CREAM)
    canvas.text("0 / 108 stars", mid, y + 16, 14, INK)
    y += 52
    canvas.jelly(x, y, width, 64, "Play", CORAL, WHITE, "Level 1 · First Nudge")
    y += 78
    canvas.jelly(x, y, width, 54, "Levels", CREAM, INK)
    y += 68
    gap = 12
    half = (width - gap) / 2
    canvas.jelly(x, y, half, 54, "How to Play", LEAF, WHITE)
    canvas.jelly(x + half + gap, y, half, 54, "Settings", CREAM, INK)
    y += 70
    canvas.text("About", mid, y, 16, INK_SOFT)


def hud_chip(canvas, x, y, w, h, title, value):
    canvas.rounded(x, y, w, h, 16, CREAM)
    canvas.text(title, x + w / 2, y + 14, 11, INK_SOFT)
    canvas.text(value, x + w / 2, y + 36, 20, INK)


def screen_play(canvas: Canvas, top, bottom, level, moves, sparkle=False, title_extra=""):
    canvas.meadow()
    canvas.status(top)
    x, width = column(canvas, 640)
    y = top + 8
    canvas.ellipse(x, y, 44, 44, CREAM)
    canvas.text("<", x + 22, y + 22, 22, INK)
    canvas.text(f"Level {level['index']}", x + width / 2, y + 6, 13, INK_SOFT)
    canvas.text(level["title"], x + width / 2, y + 26, 20, INK)
    for index in range(3):
        canvas.star(x + width / 2 - 18 + index * 18, y + 48, 6, False)
    y += 62
    chip_w = (width - 16) / 3
    hud_chip(canvas, x, y, chip_w, 52, "MOVES", str(len(moves)))
    hud_chip(canvas, x + chip_w + 8, y, chip_w, 52, "PAR", str(level["par"]))
    hud_chip(canvas, x + (chip_w + 8) * 2, y, chip_w, 52, "BEST", "—")
    y += 66
    pad = 54 if canvas.point_h < 740 else 64
    controls_h = 44 + 12 + pad * 3 + 16
    board_bottom = canvas.point_h - bottom - controls_h - 8
    board_h_room = board_bottom - y
    rows = level["rows"]
    cell = min((width - 8) / len(rows[0]), board_h_room / len(rows), 92)
    bw, bh = cell * len(rows[0]), cell * len(rows)
    origin = (x + (width - bw) / 2, y + max(0, (board_h_room - bh) / 2))
    draw_board(canvas, level, moves, origin, cell, sparkle=sparkle)
    cy = canvas.point_h - bottom - controls_h
    half = (width - 12) / 2
    canvas.rounded(x, cy + 3, half, 44, 22, (214, 176, 140))
    canvas.rounded(x, cy, half, 44, 22, CREAM)
    canvas.text("Undo", x + half / 2, cy + 22, 16, INK)
    canvas.rounded(x + half + 12, cy + 3, half, 44, 22, (214, 176, 140))
    canvas.rounded(x + half + 12, cy, half, 44, 22, CREAM)
    canvas.text("Restart", x + half + 12 + half / 2, cy + 22, 16, INK)
    dpad_y = cy + 56
    cx = x + width / 2
    def bubble(bx, by):
        canvas.ellipse(bx + 2, by + 4, pad, pad, (214, 176, 140))
        canvas.ellipse(bx, by, pad, pad, CREAM)
    bubble(cx - pad / 2, dpad_y)
    canvas.text("^", cx, dpad_y + pad / 2, 18, INK)
    bubble(cx - pad * 1.7, dpad_y + pad + 8)
    canvas.text("<", cx - pad * 1.2, dpad_y + pad + 8 + pad / 2, 18, INK)
    bubble(cx + pad * 0.7, dpad_y + pad + 8)
    canvas.text(">", cx + pad * 1.2, dpad_y + pad + 8 + pad / 2, 18, INK)
    canvas.ellipse(cx - pad / 2, dpad_y + pad + 8, pad, pad, CREAM_DEEP)
    canvas.daisy(cx - pad / 2 + 8, dpad_y + pad + 16, pad - 16)
    bubble(cx - pad / 2, dpad_y + (pad + 8) * 2)
    canvas.text("v", cx, dpad_y + (pad + 8) * 2 + pad / 2, 18, INK)
    if title_extra:
        canvas.text(title_extra, x + 8, y - 8, 12, INK, "semi", anchor="lt")


def screen_win(canvas: Canvas, top, bottom, level):
    screen_play(canvas, top, bottom, level, level["solution"], sparkle=True)
    canvas.draw.rectangle((0, 0, canvas.image.width, canvas.image.height), fill=(40, 28, 24))
    # The rectangle above covers the board. Redraw the play screen, then a translucent wash.
    # Pillow has no easy alpha rect on RGB. Approximate the dim by blending.
    base = canvas.image.copy()
    screen_play(canvas, top, bottom, level, level["solution"], sparkle=False)
    dim = Image.new("RGB", canvas.image.size, (40, 28, 24))
    canvas.image = Image.blend(canvas.image, dim, 0.38)
    canvas.draw = ImageDraw.Draw(canvas.image)
    card_w = min(420, canvas.point_w - 48)
    card_h = 430
    x = (canvas.point_w - card_w) / 2
    y = (canvas.point_h - card_h) / 2
    import random
    rng = random.Random(level["index"])
    colors = [GOLD, CORAL, LEAF, BLUSH, WHITE, SKY_TOP]
    for index in range(26):
        px = rng.random() * canvas.point_w
        py = rng.random() * canvas.point_h * 0.85
        color = colors[index % len(colors)]
        if index % 2 == 0:
            canvas.rounded(px, py, 14, 8, 2, color)
        else:
            canvas.rounded(px, py, 8, 14, 2, color)
    canvas.panel(x, y, card_w, card_h)
    canvas.mallow(x + card_w / 2 - 60, y + 16, 120)
    canvas.text("All tucked in!", x + card_w / 2, y + 156, 32, INK)
    for index in range(3):
        canvas.star(x + card_w / 2 - 48 + index * 48, y + 206, 16, True)
    canvas.text(f"{level['par']} moves  ·  par {level['par']}", x + card_w / 2, y + 246, 16, INK_SOFT, "semi")
    canvas.text("A perfect little nudge.", x + card_w / 2, y + 274, 15, (232, 93, 58), "semi")
    canvas.jelly(x + 22, y + 300, card_w - 44, 58, "Next level", CORAL, WHITE)
    canvas.text("Play again", x + card_w / 2, y + 388, 16, INK)
    # Silence unused base copy; blending already used the live image.
    _ = base


def screen_levels(canvas: Canvas, top, bottom):
    canvas.meadow()
    canvas.status(top)
    canvas.rounded(0, top, canvas.point_w, 48, 0, CREAM)
    canvas.text("Levels", canvas.point_w / 2, top + 24, 18, INK)
    canvas.text("<", 28, top + 24, 20, INK)
    y = top + 64
    x, width = column(canvas, 680)
    # Pretend the first eight levels are cleared so the select screen shows stars.
    cleared = {1: 3, 2: 3, 3: 2, 4: 3, 5: 3, 6: 2, 7: 3, 8: 1}
    shown = [level for level in LEVELS if level["world"] <= 2]
    world = None
    col_w = 112
    gap = 12
    columns = max(2, int((width + gap) / (col_w + gap)))
    cursor_y = y
    index_in_row = 0
    for level in shown:
        if level["world"] != world:
            world = level["world"]
            if index_in_row:
                cursor_y += 132
                index_in_row = 0
            name = level["worldName"]
            blurb = "First nudges" if world == 1 else "A second crate"
            stars = sum(cleared.get(item["index"], 0) for item in shown if item["world"] == world)
            canvas.panel(x, cursor_y, width, 20 + 36 + 12 + 132 * 2)
            canvas.text(name, x + 18, cursor_y + 28, 24, INK, anchor="lm")
            canvas.text(blurb, x + 18, cursor_y + 50, 14, INK_SOFT, "semi", anchor="lm")
            canvas.text(f"{stars}/18", x + width - 18, cursor_y + 34, 14, INK, anchor="rm")
            cursor_y += 70
            row_x = x + 16
        else:
            row_x = x + 16
        # The panel height above is a guess; draw cells and let the panel be redrawn tighter below.
        _ = row_x
    # Draw cleanly a second time with measured rows. Easier to rebuild this screen.
    canvas.meadow()
    canvas.status(top)
    canvas.rounded(0, top, canvas.point_w, 48, 0, CREAM)
    canvas.text("Levels", canvas.point_w / 2, top + 24, 18, INK)
    canvas.text("<", 28, top + 24, 20, INK)
    cursor_y = top + 64
    for world in (1, 2):
        items = [level for level in LEVELS if level["world"] == world]
        rows_needed = (len(items) + columns - 1) // columns
        card_h = 78 + rows_needed * 128
        canvas.panel(x, cursor_y, width, card_h)
        blurb = "First nudges" if world == 1 else "A second crate"
        name = items[0]["worldName"]
        stars = sum(cleared.get(item["index"], 0) for item in items)
        canvas.text(name, x + 18, cursor_y + 30, 24, INK, anchor="lm")
        canvas.text(blurb, x + 18, cursor_y + 52, 14, INK_SOFT, "semi", anchor="lm")
        canvas.text(f"{stars}/18", x + width - 18, cursor_y + 36, 14, INK, anchor="rm")
        for offset, level in enumerate(items):
            col = offset % columns
            row = offset // columns
            cell_x = x + 16 + col * ((width - 32) / columns)
            cell_w = (width - 32) / columns - 10
            cell_y = cursor_y + 74 + row * 124
            canvas.rounded(cell_x, cell_y, cell_w, 114, 18, (255, 255, 255))
            unlocked = level["index"] <= 9
            canvas.rounded(cell_x + 8, cell_y + 8, cell_w - 16, 48, 14, FLOOR if unlocked else CREAM_DEEP)
            if unlocked:
                canvas.text(str(level["index"]), cell_x + cell_w / 2, cell_y + 32, 22, INK)
            else:
                canvas.rounded(cell_x + cell_w / 2 - 7, cell_y + 18, 14, 11, 3, INK_SOFT)
                canvas.ellipse(cell_x + cell_w / 2 - 5, cell_y + 12, 10, 10, None, INK_SOFT, 2)
            title = level["title"]
            canvas.text(title, cell_x + cell_w / 2, cell_y + 68, 11, INK)
            earned = cleared.get(level["index"], 0)
            for star_index in range(3):
                canvas.star(cell_x + cell_w / 2 - 16 + star_index * 16, cell_y + 86, 6, star_index < earned)
            if earned:
                best = level["par"] + (0 if earned == 3 else 3)
                label = "1 move" if best == 1 else f"{best} moves"
                canvas.text(label, cell_x + cell_w / 2, cell_y + 104, 10, INK_SOFT, "semi")
        cursor_y += card_h + 16


def first_goal_prefix(level):
    rows, _, _, landed = replay(level, "")
    _ = rows
    prefix = ""
    best = None
    for letter in level["solution"]:
        prefix += letter
        _, _, _, landed = replay(level, prefix)
        if landed:
            best = prefix
            break
    return best or level["solution"][:1]


def load_icon_master() -> Image.Image:
    if not ICON_SOURCE.exists():
        raise SystemExit(f"missing approved icon: {ICON_SOURCE}")
    image = Image.open(ICON_SOURCE).convert("RGB")
    if image.size != (1024, 1024):
        image = image.resize((1024, 1024), Image.Resampling.LANCZOS)
    return image


def render_icons() -> None:
    """Install the approved artwork. Do not redraw it."""
    master = load_icon_master()
    icon_dir = ROOT / "AppStore" / "icon"
    icon_dir.mkdir(parents=True, exist_ok=True)
    master.save(icon_dir / "AppIcon-1024.png", "PNG")
    catalog = ROOT / "App" / "Assets.xcassets" / "AppIcon.appiconset"
    catalog.mkdir(parents=True, exist_ok=True)
    sizes = {
        20: "icon-20.png",
        29: "icon-29.png",
        40: "icon-40.png",
        58: "icon-58.png",
        60: "icon-60.png",
        76: "icon-76.png",
        80: "icon-80.png",
        87: "icon-87.png",
        120: "icon-120.png",
        152: "icon-152.png",
        167: "icon-167.png",
        180: "icon-180.png",
        1024: "icon-1024.png",
    }
    for pixels, name in sizes.items():
        image = master if pixels == 1024 else master.resize((pixels, pixels), Image.Resampling.LANCZOS)
        image.convert("RGB").save(catalog / name, "PNG")
    website = ROOT / "AppStore" / "website"
    master.resize((32, 32), Image.Resampling.LANCZOS).save(website / "favicon.png", "PNG")
    master.resize((180, 180), Image.Resampling.LANCZOS).save(website / "apple-touch-icon.png", "PNG")
    master.resize((64, 64), Image.Resampling.LANCZOS).save(website / "icon-64.png", "PNG")
    print("icons", master.mode, master.size, "no-alpha")


def render_ui(painter) -> Image.Image:
    """iPhone 16 logical screen, rendered at 3x so the bezel stays sharp."""
    width, height = 393 * 3, 852 * 3
    canvas = Canvas(width, height, 3)
    painter(canvas, 59, 34)
    image = canvas.image.convert("RGBA")
    draw = ImageDraw.Draw(image)
    island_w = int(width * 0.30)
    island_h = int(width * 0.088)
    ix = (width - island_w) // 2
    iy = int(height * 0.016)
    draw.rounded_rectangle(
        (ix, iy, ix + island_w, iy + island_h),
        radius=island_h // 2,
        fill=(0, 0, 0, 255),
    )
    return image


def build_phone(ui: Image.Image) -> Image.Image:
    screen_w, screen_h = ui.size
    bezel = max(18, int(screen_w * 0.034))
    outer_w = screen_w + bezel * 2
    outer_h = screen_h + bezel * 2
    protrude = max(8, int(screen_w * 0.015))
    image = Image.new("RGBA", (outer_w + protrude * 2, outer_h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    x0 = protrude
    metal = (38, 38, 42, 255)
    button = (78, 78, 84, 255)
    # Silent switch and volume on the left, power on the right.
    draw.rounded_rectangle((2, int(outer_h * 0.16), x0 + 3, int(outer_h * 0.21)), radius=4, fill=button)
    draw.rounded_rectangle((2, int(outer_h * 0.24), x0 + 3, int(outer_h * 0.32)), radius=4, fill=button)
    draw.rounded_rectangle((2, int(outer_h * 0.34), x0 + 3, int(outer_h * 0.42)), radius=4, fill=button)
    right = x0 + outer_w - 3
    draw.rounded_rectangle((right, int(outer_h * 0.28), image.width - 2, int(outer_h * 0.40)), radius=4, fill=button)
    radius = int(outer_w * 0.155)
    draw.rounded_rectangle((x0, 0, x0 + outer_w, outer_h), radius=radius, fill=metal)
    draw.rounded_rectangle(
        (x0, 0, x0 + outer_w, outer_h),
        radius=radius,
        outline=(168, 168, 176, 255),
        width=max(3, screen_w // 200),
    )
    mask = Image.new("L", ui.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, screen_w - 1, screen_h - 1),
        radius=int(screen_w * 0.125),
        fill=255,
    )
    image.paste(ui, (x0 + bezel, bezel), mask)
    return image


def candy_background(width: int, height: int) -> Image.Image:
    column = Image.new("RGB", (1, height))
    pixels = column.load()
    top = (255, 112, 64)
    mid = (232, 48, 104)
    bottom = (148, 18, 122)
    for y in range(height):
        t = y / max(1, height - 1)
        if t < 0.45:
            color = lerp(top, mid, t / 0.45)
        else:
            color = lerp(mid, bottom, (t - 0.45) / 0.55)
        pixels[0, y] = color
    image = column.resize((width, height), Image.Resampling.BILINEAR)
    draw = ImageDraw.Draw(image)
    sun = int(width * 0.42)
    draw.ellipse((width - int(sun * 0.72), int(-sun * 0.28), width + int(sun * 0.15), int(sun * 0.62)), fill=(255, 196, 72))
    return image


def fit_font(draw: ImageDraw.ImageDraw, text: str, target: int, max_width: int, kind: str) -> ImageFont.FreeTypeFont:
    size = target
    while size > 18:
        face = font(kind, size, 1)
        box = draw.textbbox((0, 0), text, font=face)
        if box[2] - box[0] <= max_width:
            return face
        size -= 2
    return font(kind, size, 1)


def paint_marketing(width: int, height: int, layout: str, headline: str, subhead: str, phone: Image.Image) -> Image.Image:
    image = candy_background(width, height)
    draw = ImageDraw.Draw(image)
    if layout == "pad":
        phone_h = int(height * 0.70)
        text_block = int(height * 0.16)
    else:
        phone_h = int(height * 0.745)
        text_block = int(height * 0.145)
    phone_w = int(phone_h * phone.width / phone.height)
    max_w = int(width * (0.50 if layout == "pad" else 0.90))
    if phone_w > max_w:
        phone_w = max_w
        phone_h = int(phone_w * phone.height / phone.width)
    fitted = phone.resize((phone_w, phone_h), Image.Resampling.LANCZOS)
    text_top = max(36, int(height * 0.035))
    center = width / 2
    head_size = int(width * (0.062 if layout == "pad" else 0.072))
    sub_size = int(width * (0.026 if layout == "pad" else 0.031))
    head_font = fit_font(draw, headline, head_size, int(width * 0.88), "bold")
    sub_font = fit_font(draw, subhead, sub_size, int(width * 0.86), "semi")
    head_y = text_top + int(text_block * 0.28)
    sub_y = head_y + int(head_size * 1.15)
    for dx, dy in ((0, 4), (0, 0)):
        fill = (120, 18, 64) if dy else (255, 255, 255)
        draw.text((center + dx, head_y + dy), headline, font=head_font, fill=fill, anchor="mm")
    draw.text((center, sub_y), subhead, font=sub_font, fill=(255, 236, 186), anchor="mm")
    px = (width - phone_w) // 2
    py = height - phone_h - int(height * 0.028)
    shadow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    ImageDraw.Draw(shadow).ellipse(
        (px + int(phone_w * 0.12), py + phone_h - int(phone_h * 0.02), px + int(phone_w * 0.88), py + phone_h + int(height * 0.018)),
        fill=(90, 10, 50, 90),
    )
    image = Image.alpha_composite(image.convert("RGBA"), shadow).convert("RGB")
    image.paste(fitted, (px, py), fitted)
    return image


def render_screens() -> None:
    level_play = next(level for level in LEVELS if level["index"] == 22)
    play_moves = level_play["solution"][: max(4, len(level_play["solution"]) // 3)]
    level_undo = next(level for level in LEVELS if level["index"] == 9)
    level_win = level_undo
    scenes = [
        ("01-home", "Meet Mallow", "A marshmallow courier on a daisy meadow.", lambda c, t, b: screen_home(c, t, b)),
        ("02-nudge", "Nudge one crate", "Swipe or tap. Only one crate moves.", lambda c, t, b: screen_play(c, t, b, level_play, play_moves)),
        ("03-undo", "Undo the oops", "Step back, or start the meadow over.", lambda c, t, b: screen_play(c, t, b, level_undo, "LU")),
        ("04-levels", "Pick a meadow", "Six worlds, thirty-six puzzles, stars to chase.", lambda c, t, b: screen_levels(c, t, b)),
        ("05-cleared", "All tucked in", "Three stars if you stay close to par.", lambda c, t, b: screen_win(c, t, b, level_win)),
    ]
    phones = []
    for name, headline, subhead, painter in scenes:
        phones.append((name, headline, subhead, build_phone(render_ui(painter))))
        print(f"ui {name}")
    out = ROOT / "AppStore" / "screenshots"
    for folder, width, height, layout in SHOT_SIZES:
        dest = out / folder
        dest.mkdir(parents=True, exist_ok=True)
        for name, headline, subhead, phone in phones:
            image = paint_marketing(width, height, layout, headline, subhead, phone)
            path = dest / f"{name}.png"
            image.convert("RGB").save(path, "PNG")
            print(f"{path.relative_to(ROOT)} {image.size}")
    # Drop the previous unframed filenames so the kit only has the new set.
    for stale in ("02-gameplay.png", "03-sparkle.png", "04-cleared.png", "05-levels.png"):
        for folder, *_ in SHOT_SIZES:
            old = out / folder / stale
            if old.exists():
                old.unlink()


def main() -> None:
    render_icons()
    render_screens()


if __name__ == "__main__":
    main()
