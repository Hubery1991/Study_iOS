#!/usr/bin/env python3
"""Render the Clavewell app icon and App Store screenshots.

The screenshots follow the SwiftUI layout, copy, and colors in App/.
They are composed here because this environment has no iOS Simulator.
"""

from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
ASSET = ROOT / "App" / "Assets.xcassets" / "AppIcon.appiconset"
SHOTS = ROOT / "AppStore" / "screenshots"
ICON_DIR = ROOT / "AppStore" / "icon"

SERIF_B = "/usr/share/fonts/truetype/liberation/LiberationSerif-Bold.ttf"
SERIF_R = "/usr/share/fonts/truetype/liberation/LiberationSerif-Regular.ttf"
SANS_B = "/usr/share/fonts/truetype/macos/Inter-SemiBold.ttf"
SANS_M = "/usr/share/fonts/truetype/macos/Inter-Medium.ttf"
SANS_R = "/usr/share/fonts/truetype/macos/Inter-Regular.ttf"

INK = (18, 13, 31)
SKY = (42, 27, 74)
SHAFT = (12, 10, 20)
BRASS = (232, 193, 106)
PARCHMENT = (246, 240, 228)
MUTED = (181, 169, 196)
CARD = (255, 255, 255)

HUES = {
    "A": ((255, 200, 87), (224, 146, 47)),
    "T": ((95, 208, 208), (30, 142, 158)),
    "M": ((143, 203, 107), (62, 140, 69)),
    "V": ((196, 176, 255), (110, 86, 200)),
    "R": ((255, 155, 179), (226, 91, 134)),
    "S": ((255, 244, 210), (224, 160, 32)),
}

# Row 0 is the rim. This position has no orthogonal group of three.
PLAY_GRID = [
    "......",
    "......",
    "......",
    "......",
    "......",
    "..A...",
    ".TAM.V",
    "RTTMAV",
    "ARMMVA",
    "VARTMR",
]

RESONANCE_GRID = [
    "......",
    "......",
    "......",
    "......",
    "..T...",
    ".TAM.V",
    "RTTMAV",
    "ARMMVA",
    "AARTMR",
    "AAAMVR",
]
RESONANCE_CELLS = {(8, 0), (8, 1), (9, 0), (9, 1), (9, 2)}

OVER_GRID = [
    "ATMRVA",
    "TMRVAT",
    "MRVATM",
    "RVATMR",
    "VATMRV",
    "ATMRVA",
    "TMRVAT",
    "MRVATM",
    "RVATMR",
    "VATMRV",
]


def font(path: str, points: float, scale: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(path, max(1, int(round(points * scale))))


def lerp(a, b, t: float):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(len(a)))


def gradient(width: int, height: int) -> Image.Image:
    column = Image.new("RGB", (1, height))
    draw = ImageDraw.Draw(column)
    for y in range(height):
        draw.point((0, y), fill=lerp(SKY, INK, y / max(1, height - 1)))
    return column.resize((width, height), Image.Resampling.NEAREST)


def glow(base: Image.Image, cx: int, cy: int, radius: int, color, peak: int) -> None:
    size = max(8, radius * 2 // 3)
    small = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    pixels = small.load()
    for y in range(size):
        for x in range(size):
            dx = x - size / 2
            dy = y - size / 2
            distance = (dx * dx + dy * dy) ** 0.5 / (size / 2)
            if distance < 1:
                alpha = int(peak * (1 - distance) ** 2)
                pixels[x, y] = (*color, alpha)
    sprite = small.resize((radius * 2, radius * 2), Image.Resampling.LANCZOS)
    layer = Image.new("RGBA", base.size, (0, 0, 0, 0))
    layer.paste(sprite, (cx - radius, cy - radius), sprite)
    composed = Image.alpha_composite(base.convert("RGBA"), layer)
    base.paste(composed.convert("RGB"))


def rounded(draw: ImageDraw.ImageDraw, box, radius, fill=None, outline=None, width=1):
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)


def text_size(draw, value, face):
    box = draw.textbbox((0, 0), value, font=face)
    return box[2] - box[0], box[3] - box[1]


def mote_sprite(radius: int, kind: str) -> Image.Image:
    light, deep = HUES[kind]
    size = radius * 2 + 4
    sprite = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sprite)
    center = size / 2
    steps = max(8, radius)
    for step in range(steps, 0, -1):
        t = step / steps
        color = lerp(deep, light, (1 - t) ** 1.15)
        rr = radius * t
        draw.ellipse((center - rr, center - rr, center + rr, center + rr), fill=(*color, 255))
    rim = max(1, radius // 14)
    draw.ellipse(
        (center - radius, center - radius, center + radius, center + radius),
        outline=(255, 255, 255, 110),
        width=rim,
    )
    hx = center - radius * 0.22
    hy = center - radius * 0.32
    draw.ellipse((hx - radius * 0.22, hy - radius * 0.12, hx + radius * 0.22, hy + radius * 0.12), fill=(255, 255, 255, 150))
    if kind == "S":
        arm = radius * 0.46
        width = max(2, radius // 8)
        ink = (18, 13, 31, 200)
        draw.line((center, center - arm, center, center + arm), fill=ink, width=width)
        draw.line((center - arm, center, center + arm, center), fill=ink, width=width)
        tilt = arm * 0.72
        draw.line((center - tilt, center - tilt, center + tilt, center + tilt), fill=ink, width=width)
        draw.line((center + tilt, center - tilt, center - tilt, center + tilt), fill=ink, width=width)
    return sprite


def paste_mote(base: Image.Image, cx: float, cy: float, radius: int, kind: str, ring=False) -> None:
    sprite = mote_sprite(max(2, radius), kind)
    base.paste(sprite, (int(cx - sprite.size[0] / 2), int(cy - sprite.size[1] / 2)), sprite)
    if ring:
        draw = ImageDraw.Draw(base)
        draw.ellipse(
            (cx - radius - 3, cy - radius - 3, cx + radius + 3, cy + radius + 3),
            outline=BRASS,
            width=max(2, radius // 10),
        )


def draw_background(width: int, height: int, scale: int) -> Image.Image:
    image = gradient(width, height)
    glow(image, width // 2, int(height * 0.08), int(420 * scale), BRASS, 46)
    return image


def status_bar(image: Image.Image, scale: int, safe_top: int, pad: bool) -> None:
    draw = ImageDraw.Draw(image)
    face = font(SANS_B, 15 if not pad else 16, scale)
    width, _ = image.size
    y = int((safe_top * 0.46) * scale) if not pad else int(safe_top * 0.55 * scale)
    if pad:
        label = "9:41"
        tw, th = text_size(draw, label, face)
        draw.text(((width - tw) / 2, y - th / 2), label, font=face, fill=PARCHMENT)
    else:
        draw.text((22 * scale, y), "9:41", font=face, fill=PARCHMENT, anchor="lt")
    right = width - 22 * scale
    battery_w = 25 * scale
    battery_h = 12 * scale
    by = y + 2 * scale
    draw.rounded_rectangle(
        (right - battery_w, by, right, by + battery_h),
        radius=3 * scale,
        outline=PARCHMENT,
        width=max(1, scale),
    )
    draw.rectangle((right + scale, by + 3 * scale, right + 2 * scale, by + battery_h - 3 * scale), fill=PARCHMENT)
    draw.rounded_rectangle(
        (right - battery_w + 2 * scale, by + 2 * scale, right - 5 * scale, by + battery_h - 2 * scale),
        radius=2 * scale,
        fill=PARCHMENT,
    )
    # Four signal bars and a small wifi arc, drawn as original geometry.
    bx = right - battery_w - 8 * scale
    for index, height in enumerate((5, 7, 9, 12)):
        bar_x = bx - (4 - index) * 4 * scale
        draw.rectangle(
            (bar_x, by + battery_h - height * scale / 1.4, bar_x + 2 * scale, by + battery_h),
            fill=PARCHMENT,
        )


def nav_bar(image, scale, safe_top, title, pad=False, controls="game"):
    draw = ImageDraw.Draw(image)
    height = int((50 if pad else 44) * scale)
    top = int(safe_top * scale)
    width = image.size[0]
    layer = Image.new("RGBA", image.size, (0, 0, 0, 0))
    ImageDraw.Draw(layer).rectangle((0, 0, width, top + height), fill=(*INK, 235))
    image.paste(Image.alpha_composite(image.convert("RGBA"), layer).convert("RGB"))
    face = font(SANS_B, 17, scale)
    draw = ImageDraw.Draw(image)
    draw.text((width / 2, top + height / 2), title, font=face, fill=PARCHMENT, anchor="mm")
    py = top + height / 2
    if controls == "game":
        px = 22 * scale
        draw.rounded_rectangle((px, py - 8 * scale, px + 4 * scale, py + 8 * scale), radius=scale, fill=BRASS)
        draw.rounded_rectangle((px + 7 * scale, py - 8 * scale, px + 11 * scale, py + 8 * scale), radius=scale, fill=BRASS)
        sx = width - 36 * scale
        draw.polygon(
            [(sx, py - 4 * scale), (sx + 6 * scale, py - 4 * scale), (sx + 12 * scale, py - 9 * scale),
             (sx + 12 * scale, py + 9 * scale), (sx + 6 * scale, py + 4 * scale), (sx, py + 4 * scale)],
            fill=BRASS,
        )
        draw.arc((sx + 14 * scale, py - 7 * scale, sx + 24 * scale, py + 7 * scale), 300, 60, fill=BRASS, width=max(1, int(1.6 * scale)))
    else:
        px = 26 * scale
        draw.line(
            [(px + 8 * scale, py - 8 * scale), (px, py), (px + 8 * scale, py + 8 * scale)],
            fill=BRASS,
            width=max(2, int(2 * scale)),
        )
    return top + height


def brass_button(image, box, label, scale, ghost=False):
    draw = ImageDraw.Draw(image)
    radius = 16 * scale
    if ghost:
        rounded(draw, box, radius, outline=(*BRASS, ), width=max(2, int(1.5 * scale)))
        # outline with alpha isn't supported on RGB; draw a slightly inset brass stroke
        draw.rounded_rectangle(box, radius=radius, outline=BRASS, width=max(2, int(1.6 * scale)))
        color = PARCHMENT
    else:
        draw.rounded_rectangle(box, radius=radius, fill=BRASS)
        color = INK
    face = font(SANS_B, 18 if not ghost else 17, scale)
    cx = (box[0] + box[2]) / 2
    cy = (box[1] + box[3]) / 2
    draw.text((cx, cy), label, font=face, fill=color, anchor="mm")


def footer_chip(image, box, label, scale, kind):
    overlay = Image.new("RGBA", image.size, (0, 0, 0, 0))
    od = ImageDraw.Draw(overlay)
    od.rounded_rectangle(box, radius=14 * scale, fill=(255, 255, 255, 16))
    image.paste(Image.alpha_composite(image.convert("RGBA"), overlay).convert("RGB"))
    draw = ImageDraw.Draw(image)
    face = font(SANS_B, 15, scale)
    cx = (box[0] + box[2]) / 2 + 8 * scale
    cy = (box[1] + box[3]) / 2
    draw.text((cx, cy), label, font=face, fill=PARCHMENT, anchor="mm")
    ix = box[0] + 22 * scale
    if kind == "gear":
        draw.ellipse((ix, cy - 7 * scale, ix + 14 * scale, cy + 7 * scale), outline=BRASS, width=max(2, scale))
        draw.ellipse((ix + 4 * scale, cy - 3 * scale, ix + 10 * scale, cy + 3 * scale), outline=BRASS, width=max(1, scale))
    else:
        draw.ellipse((ix, cy - 8 * scale, ix + 16 * scale, cy + 8 * scale), outline=BRASS, width=max(2, scale))
        draw.text((ix + 8 * scale, cy + scale), "i", font=font(SERIF_B, 12, scale), fill=BRASS, anchor="mm")


def draw_well(image, origin, cell, grid, highlight=None, guide=True):
    highlight = highlight or set()
    draw = ImageDraw.Draw(image)
    cols = len(grid[0])
    rows = len(grid)
    pad = cell * 0.16
    width = cell * cols + pad * 2
    height = cell * rows + pad * 2
    box = (origin[0], origin[1], origin[0] + width, origin[1] + height)
    draw.rounded_rectangle(box, radius=cell * 0.28, fill=SHAFT)
    draw.rounded_rectangle(box, radius=cell * 0.28, outline=BRASS, width=max(2, int(cell * 0.035)))
    inner = (box[0] + cell * 0.08, box[1] + cell * 0.08, box[2] - cell * 0.08, box[3] - cell * 0.08)
    draw.rounded_rectangle(inner, radius=cell * 0.2, outline=(*lerp(BRASS, SHAFT, 0.55),), width=max(1, int(cell * 0.02)))
    radius = int(cell * 0.36)
    for row, line in enumerate(grid):
        for column, kind in enumerate(line):
            cx = origin[0] + pad + column * cell + cell / 2
            cy = origin[1] + pad + row * cell + cell / 2
            if kind == ".":
                if guide:
                    landing = True
                    for below in range(row + 1, rows):
                        if grid[below][column] == ".":
                            landing = False
                            break
                    # lowest empty: every cell below is filled, or this is the floor
                    filled_below = all(grid[r][column] != "." for r in range(row + 1, rows))
                    empty_above_or_self = grid[row][column] == "."
                    if filled_below and empty_above_or_self:
                        draw.ellipse(
                            (cx - radius, cy - radius, cx + radius, cy + radius),
                            outline=(*lerp(BRASS, SHAFT, 0.45),),
                            width=max(1, int(cell * 0.03)),
                        )
            else:
                paste_mote(image, cx, cy, int(radius * (1.12 if (row, column) in highlight else 1)), kind, ring=(row, column) in highlight)
    return width, height


def queue_chip(image, cx, top, label, kind, diameter, scale):
    draw = ImageDraw.Draw(image)
    face = font(SANS_B, 10, scale)
    draw.text((cx, top), label.upper(), font=face, fill=MUTED, anchor="mt")
    paste_mote(image, cx, top + 16 * scale + diameter / 2, int(diameter / 2), kind)
    name = {"A": "Amber", "T": "Tide", "M": "Moss", "V": "Violet", "R": "Rose", "S": "Spark"}[kind]
    draw.text((cx, top + 18 * scale + diameter + 4 * scale), name, font=font(SANS_M, 11, scale), fill=PARCHMENT, anchor="mt")


def clave_rule(draw, cx, y, scale):
    gaps = [10, 4, 10, 16, 10, 4]
    widths = [10, 4, 10, 10, 4]
    # draw 3-2 as five ticks: long short long | long short
    pieces = [(10, False), (4, False), (10, True), (10, False), (4, False)]
    total = sum(w for w, _ in pieces) + 5 * 4 + 8
    x = cx - total * scale / 2
    for width, gap_after in pieces:
        draw.rounded_rectangle((x, y, x + width * scale, y + 3 * scale), radius=2 * scale, fill=BRASS)
        x += width * scale + (12 if gap_after else 5) * scale


def scene_home(image, scale, safe_top, safe_bottom, pad):
    draw = ImageDraw.Draw(image)
    width, height = image.size
    content_w = min(int(520 * scale), width - int(48 * scale))
    left = (width - content_w) // 2
    kicker = font(SANS_B, 12, scale)
    title = font(SERIF_B, 58, scale)
    tag = font(SANS_M, 16, scale)
    block = []
    block.append(int(22 * scale))
    block.append(text_size(draw, "A WELL OF COLORED LIGHT", kicker)[1] + int(10 * scale))
    block.append(text_size(draw, "Clavewell", title)[1] + int(10 * scale))
    block.append(int(14 * scale))
    block.append(text_size(draw, "Drop motes.", tag)[1] + int(22 * scale))
    block.append(int(168 * scale) + int(20 * scale))
    block.append(int(52 * scale) + int(10 * scale))
    block.append(int(50 * scale) + int(10 * scale))
    block.append(int(50 * scale) + int(22 * scale))
    block.append(int(48 * scale))
    total = sum(block)
    usable_top = int(safe_top * scale) + int(8 * scale)
    usable_bottom = height - int(safe_bottom * scale)
    y = usable_top + max(0, (usable_bottom - usable_top - total) // 2)
    draw.text((width / 2, y), "A WELL OF COLORED LIGHT", font=kicker, fill=BRASS, anchor="mt")
    y += block[1]
    draw.text((width / 2, y), "Clavewell", font=title, fill=PARCHMENT, anchor="mt")
    y += block[2]
    clave_rule(draw, width / 2, y, scale)
    y += block[3]
    draw.text((width / 2, y), "Drop motes. Match three. Keep the rim clear.", font=tag, fill=MUTED, anchor="mt")
    y += block[4]
    mark = int(168 * scale)
    mx = width / 2
    my = y + mark / 2
    draw.ellipse((mx - mark / 2, my - mark / 2, mx + mark / 2, my + mark / 2), fill=(20, 14, 36))
    draw.ellipse((mx - mark / 2, my - mark / 2, mx + mark / 2, my + mark / 2), outline=BRASS, width=max(3, int(mark * 0.045)))
    paste_mote(image, mx, my - mark * 0.12, int(mark * 0.13), "V")
    paste_mote(image, mx - mark * 0.16, my + mark * 0.10, int(mark * 0.15), "A")
    paste_mote(image, mx + mark * 0.17, my + mark * 0.12, int(mark * 0.12), "T")
    y += block[5]
    brass_button(image, (left, y, left + content_w, y + int(52 * scale)), "Play", scale, ghost=False)
    y += block[6]
    brass_button(image, (left, y, left + content_w, y + int(50 * scale)), "How to Play", scale, ghost=True)
    y += block[7]
    brass_button(image, (left, y, left + content_w, y + int(50 * scale)), "Records", scale, ghost=True)
    y += block[8]
    gap = int(12 * scale)
    chip_w = (content_w - gap) // 2
    footer_chip(image, (left, y, left + chip_w, y + int(48 * scale)), "Settings", scale, "gear")
    footer_chip(image, (left + chip_w + gap, y, left + content_w, y + int(48 * scale)), "About", scale, "info")


def scene_game(image, scale, safe_top, safe_bottom, pad, resonance=False):
    width, height = image.size
    content_top = nav_bar(image, scale, safe_top, "Clavewell", pad)
    draw = ImageDraw.Draw(image)
    bottom = height - int((safe_bottom + 12) * scale)
    if pad:
        margin = int(28 * scale)
        left_w = int(250 * scale)
        right_w = int(180 * scale)
        gap = int(24 * scale)
        well_left = margin + left_w + gap
        well_right = width - margin - right_w - gap
        title = font(SERIF_B, 32, scale)
        body = font(SANS_R, 15, scale)
        x = margin
        y = content_top + int(18 * scale)
        draw.text((x, y), "Cadence", font=title, fill=PARCHMENT, anchor="lt")
        y += int(46 * scale)
        detail = "Every few drops, a new row climbs into the well. The pace quickens the longer you last."
        y = wrap(draw, detail, body, x, y, left_w, MUTED, int(22 * scale)) + int(16 * scale)
        draw_score(draw, x, y, "4,280" if not resonance else "6,480", "6,140" if not resonance else "6,480", scale, compact=True)
        y += int(78 * scale)
        draw_rise(draw, x, y, left_w, 4 if not resonance else 4, 6, scale)
        # right queue
        rx = width - margin - right_w / 2
        queue_chip(image, rx, content_top + int(36 * scale), "Now", "A", int(84 * scale), scale)
        queue_chip(image, rx, content_top + int(180 * scale), "Next", "T", int(64 * scale), scale)
        hint = "Match three of a color along an edge." if not resonance else "A chain is ringing."
        wrap(
            draw,
            hint,
            font(SANS_M, 14, scale),
            width - margin - right_w,
            content_top + int(330 * scale),
            right_w,
            MUTED,
            int(20 * scale),
        )
        cell = min((well_right - well_left) / 6.4, (bottom - content_top - int(24 * scale)) / 10.4, 92 * scale)
        grid = RESONANCE_GRID if resonance else PLAY_GRID
        board_w = cell * 6 + cell * 0.32
        board_h = cell * 10 + cell * 0.32
        origin = ((well_left + well_right) / 2 - board_w / 2, content_top + (bottom - content_top - board_h) / 2)
        draw_well(image, origin, cell, grid, RESONANCE_CELLS if resonance else None)
        if resonance:
            banner(image, (origin[0] + board_w / 2, origin[1] + 28 * scale), "Resonance ×2", "+1,200", scale)
        return

    margin = int(16 * scale)
    y = content_top + int(8 * scale)
    draw_score(draw, margin, y, "4,280" if not resonance else "6,480", "6,140" if not resonance else "6,480", scale, compact=False)
    queue_chip(image, width - margin - int(86 * scale), y, "Now", "A", int(52 * scale), scale)
    queue_chip(image, width - margin - int(28 * scale), y + int(8 * scale), "Next", "T", int(40 * scale), scale)
    y += int(108 * scale)
    draw_rise(draw, margin, y, width - margin * 2, 4, 6, scale)
    y += int(42 * scale)
    hint_h = int(28 * scale)
    cell = min((width - margin * 2) / 6.35, (bottom - y - hint_h) / 10.35, 92 * scale)
    grid = RESONANCE_GRID if resonance else PLAY_GRID
    board_w = cell * 6 + cell * 0.32
    origin_x = (width - board_w) / 2
    draw_well(image, (origin_x, y), cell, grid, RESONANCE_CELLS if resonance else None)
    if resonance:
        banner(image, (width / 2, y + 22 * scale), "Resonance ×2", "+1,200", scale)
    hint = "Tap a column to drop the amber mote." if False else "Match three of a color along an edge."
    draw.text((width / 2, bottom - int(4 * scale)), hint, font=font(SANS_M, 13, scale), fill=MUTED, anchor="mb")


def draw_score(draw, x, y, score, best, scale, compact):
    draw.text((x, y), "SCORE", font=font(SANS_B, 11, scale), fill=MUTED, anchor="lt")
    draw.text((x, y + int(14 * scale)), score, font=font(SERIF_B, 34 if compact else 36, scale), fill=PARCHMENT, anchor="lt")
    draw.text((x, y + int(56 * scale)), f"Best {best}", font=font(SANS_M, 13, scale), fill=BRASS, anchor="lt")


def draw_rise(draw, x, y, width, remain, pace, scale):
    draw.text((x, y), f"Rise in {remain}", font=font(SANS_B, 14, scale), fill=PARCHMENT, anchor="lt")
    draw.text((x + width, y), f"Pace {pace}", font=font(SANS_M, 12, scale), fill=MUTED, anchor="rt")
    bar_y = y + int(22 * scale)
    draw.rounded_rectangle((x, bar_y, x + width, bar_y + int(7 * scale)), radius=4 * scale, fill=(255, 255, 255))
    # dim track
    track = Image.new("RGBA", (int(width), int(7 * scale)), (255, 255, 255, 22))
    # redraw properly on the main image
    draw.rounded_rectangle((x, bar_y, x + width, bar_y + int(7 * scale)), radius=4 * scale, fill=(255, 255, 255))
    # The fill above is opaque white; paint a dark track then brass portion.
    draw.rounded_rectangle((x, bar_y, x + width, bar_y + int(7 * scale)), radius=4 * scale, fill=(46, 40, 62))
    fill_w = width * remain / pace
    draw.rounded_rectangle((x, bar_y, x + fill_w, bar_y + int(7 * scale)), radius=4 * scale, fill=BRASS)


def banner(image, center, title, points, scale):
    draw = ImageDraw.Draw(image)
    face = font(SERIF_B, 18, scale)
    sub = font(SANS_B, 13, scale)
    tw, th = text_size(draw, title, face)
    pw, ph = text_size(draw, points, sub)
    width = max(tw, pw) + int(36 * scale)
    height = th + ph + int(22 * scale)
    box = (center[0] - width / 2, center[1], center[0] + width / 2, center[1] + height)
    draw.rounded_rectangle(box, radius=height / 2, fill=INK)
    draw.rounded_rectangle(box, radius=height / 2, outline=BRASS, width=max(1, scale))
    draw.text((center[0], box[1] + int(8 * scale)), title, font=face, fill=PARCHMENT, anchor="mt")
    draw.text((center[0], box[1] + int(8 * scale) + th + int(2 * scale)), points, font=sub, fill=BRASS, anchor="mt")


def wrap(draw, value, face, x, y, width, fill, line_h):
    words = value.split()
    line = ""
    for word in words:
        trial = word if not line else f"{line} {word}"
        if text_size(draw, trial, face)[0] <= width:
            line = trial
        else:
            draw.text((x, y), line, font=face, fill=fill, anchor="lt")
            y += line_h
            line = word
    if line:
        draw.text((x, y), line, font=face, fill=fill, anchor="lt")
        y += line_h
    return y


def scene_over(image, scale, safe_top, safe_bottom, pad):
    width, height = image.size
    content_top = nav_bar(image, scale, safe_top, "Clavewell", pad)
    bottom = height - int((safe_bottom + 8) * scale)
    cell = min((width * 0.72) / 6.4, (bottom - content_top) / 10.5, 78 * scale)
    board_w = cell * 6 + cell * 0.32
    origin = ((width - board_w) / 2, content_top + max(0, (bottom - content_top - cell * 10.4) / 2))
    draw_well(image, origin, cell, OVER_GRID, guide=False)
    overlay = Image.new("RGBA", image.size, (0, 0, 0, 150))
    image.paste(Image.alpha_composite(image.convert("RGBA"), overlay).convert("RGB"))
    draw = ImageDraw.Draw(image)
    width, height = image.size
    card_w = min(int(440 * scale), width - int(48 * scale))
    card_h = int(430 * scale)
    left = (width - card_w) // 2
    top = (height - card_h) // 2
    box = (left, top, left + card_w, top + card_h)
    draw.rounded_rectangle(box, radius=int(24 * scale), fill=INK)
    draw.rounded_rectangle(box, radius=int(24 * scale), outline=BRASS, width=max(2, scale))
    badge = font(SANS_B, 12, scale)
    bw, bh = text_size(draw, "NEW RECORD", badge)
    badge_box = (width / 2 - bw / 2 - 14 * scale, top + 22 * scale, width / 2 + bw / 2 + 14 * scale, top + 22 * scale + bh + 12 * scale)
    draw.rounded_rectangle(badge_box, radius=(bh + 12 * scale) / 2, fill=BRASS)
    draw.text((width / 2, (badge_box[1] + badge_box[3]) / 2), "NEW RECORD", font=badge, fill=INK, anchor="mm")
    y = badge_box[3] + int(16 * scale)
    draw.text((width / 2, y), "The rim silted shut", font=font(SERIF_B, 28, scale), fill=PARCHMENT, anchor="mt")
    y += int(40 * scale)
    draw.text((width / 2, y), "A rise would have pushed a mote past the rim.", font=font(SANS_R, 15, scale), fill=MUTED, anchor="mt")
    y += int(36 * scale)
    draw.text((width / 2, y), "12,840", font=font(SERIF_B, 52, scale), fill=BRASS, anchor="mt")
    y += int(64 * scale)
    draw.text((width / 2, y), "Best 12,840   ·   Chain 4   ·   86 motes", font=font(SANS_M, 13, scale), fill=MUTED, anchor="mt")
    y += int(28 * scale)
    inset = int(22 * scale)
    brass_button(image, (left + inset, y, left + card_w - inset, y + int(52 * scale)), "Play again", scale, ghost=False)
    y += int(62 * scale)
    brass_button(image, (left + inset, y, left + card_w - inset, y + int(50 * scale)), "Home", scale, ghost=True)


def scene_settings(image, scale, safe_top, safe_bottom, pad):
    content_top = nav_bar(image, scale, safe_top, "Settings", pad, controls="back")
    draw = ImageDraw.Draw(image)
    width, _ = image.size
    content_w = min(int(640 * scale), width - int(40 * scale))
    left = (width - content_w) // 2
    y = content_top + int(20 * scale)
    rows = [
        ("Sound", True),
        ("Haptics", True),
        ("Color patterns", False),
        ("Landing guide", True),
    ]
    row_h = int(56 * scale)
    card_h = row_h * len(rows) + int(8 * scale)
    card = (left, y, left + content_w, y + card_h)
    overlay = Image.new("RGBA", image.size, (0, 0, 0, 0))
    od = ImageDraw.Draw(overlay)
    od.rounded_rectangle(card, radius=int(18 * scale), fill=(255, 255, 255, 16), outline=(255, 255, 255, 28), width=max(1, scale))
    image.paste(Image.alpha_composite(image.convert("RGBA"), overlay).convert("RGB"))
    draw = ImageDraw.Draw(image)
    for index, (label, on) in enumerate(rows):
        ry = y + int(4 * scale) + index * row_h
        draw.text((left + int(54 * scale), ry + row_h / 2), label, font=font(SANS_B, 16, scale), fill=PARCHMENT, anchor="lm")
        icon_x = left + int(24 * scale)
        icon_y = ry + row_h / 2
        draw.ellipse((icon_x, icon_y - 8 * scale, icon_x + 16 * scale, icon_y + 8 * scale), outline=BRASS, width=max(2, scale))
        switch(draw, left + content_w - int(74 * scale), icon_y - int(14 * scale), int(52 * scale), int(28 * scale), on, scale)
        if index < len(rows) - 1:
            draw.line((left + int(16 * scale), ry + row_h, left + content_w - int(16 * scale), ry + row_h), fill=(255, 255, 255), width=1)
            # soften the divider by drawing a dark line over the white one
            draw.line(
                (left + int(16 * scale), ry + row_h, left + content_w - int(16 * scale), ry + row_h),
                fill=(58, 50, 74),
                width=max(1, scale // 2 or 1),
            )
    y += card_h + int(16 * scale)
    note = "Color patterns draw a distinct shape on each mote. The landing guide shows where a mote will come to rest. Both are stored only on this device."
    y = wrap(draw, note, font(SANS_R, 14, scale), left, y, content_w, MUTED, int(20 * scale))
    y += int(8 * scale)
    reset = (left, y, left + content_w, y + int(48 * scale))
    draw.rounded_rectangle(reset, radius=int(14 * scale), outline=(255, 180, 192), width=max(2, scale))
    draw.text(((reset[0] + reset[2]) / 2, (reset[1] + reset[3]) / 2), "Reset records", font=font(SANS_B, 16, scale), fill=(255, 180, 192), anchor="mm")
    y = reset[3] + int(12 * scale)
    wrap(
        draw,
        "Resetting removes high scores and lifetime totals. Sound and the other switches stay as they are.",
        font(SANS_R, 13, scale),
        left,
        y,
        content_w,
        MUTED,
        int(18 * scale),
    )


def switch(draw, x, y, w, h, on, scale):
    color = BRASS if on else (70, 62, 88)
    draw.rounded_rectangle((x, y, x + w, y + h), radius=h / 2, fill=color)
    knob = h - int(6 * scale)
    kx = x + w - knob - int(3 * scale) if on else x + int(3 * scale)
    draw.ellipse((kx, y + int(3 * scale), kx + knob, y + int(3 * scale) + knob), fill=PARCHMENT)


def render_screens() -> None:
    devices = [
        ("iphone-6.9", 440, 956, 3, 59, 34, False),
        ("iphone-6.7", 428, 926, 3, 47, 34, False),
        ("iphone-6.5", 414, 896, 3, 44, 34, False),
        ("ipad-13", 1032, 1376, 2, 24, 20, True),
    ]
    scenes = [
        ("01-home", scene_home),
        ("02-gameplay", lambda *args: scene_game(*args, resonance=False)),
        ("03-resonance", lambda *args: scene_game(*args, resonance=True)),
        ("04-game-over", scene_over),
        ("05-settings", scene_settings),
    ]
    for folder, pw, ph, scale, safe_top, safe_bottom, pad in devices:
        out = SHOTS / folder
        out.mkdir(parents=True, exist_ok=True)
        for name, painter in scenes:
            image = draw_background(pw * scale, ph * scale, scale)
            painter(image, scale, safe_top, safe_bottom, pad)
            status_bar(image, scale, safe_top, pad)
            path = out / f"{name}.png"
            image.save(path, "PNG", optimize=True)
            print(f"wrote {path} {image.size}")


def icon_image(size: int) -> Image.Image:
    image = Image.new("RGB", (size, size), INK)
    pixels_radius = int(size * 0.72)
    glow(image, size // 2, int(size * 0.42), pixels_radius, BRASS, 70)
    draw = ImageDraw.Draw(image)
    # Full-bleed night so the rounded mask never shows a corner gap.
    center = size / 2
    radius = size * 0.36
    draw.ellipse((center - radius, center - radius, center + radius, center + radius), fill=(22, 16, 40))
    draw.ellipse(
        (center - radius, center - radius, center + radius, center + radius),
        outline=BRASS,
        width=max(4, int(size * 0.028)),
    )
    draw.ellipse(
        (center - radius * 0.84, center - radius * 0.84, center + radius * 0.84, center + radius * 0.84),
        outline=(*lerp(BRASS, INK, 0.45),),
        width=max(2, int(size * 0.008)),
    )
    paste_mote(image, center, center - radius * 0.22, int(size * 0.075), "V")
    paste_mote(image, center - radius * 0.32, center + radius * 0.2, int(size * 0.09), "A")
    paste_mote(image, center + radius * 0.34, center + radius * 0.24, int(size * 0.072), "T")
    return image.convert("RGB")


def render_icons() -> None:
    master = icon_image(1024)
    assert master.mode == "RGB"
    assert master.size == (1024, 1024)
    ICON_DIR.mkdir(parents=True, exist_ok=True)
    ASSET.mkdir(parents=True, exist_ok=True)
    marketing = ICON_DIR / "AppIcon-1024.png"
    master.save(marketing, "PNG", optimize=True)
    # Confirm the marketing file has no alpha channel.
    check = Image.open(marketing)
    assert check.mode == "RGB", check.mode

    specs = [
        ("iphone", "20x20", "2x", 40),
        ("iphone", "20x20", "3x", 60),
        ("iphone", "29x29", "2x", 58),
        ("iphone", "29x29", "3x", 87),
        ("iphone", "40x40", "2x", 80),
        ("iphone", "40x40", "3x", 120),
        ("iphone", "60x60", "2x", 120),
        ("iphone", "60x60", "3x", 180),
        ("ipad", "20x20", "1x", 20),
        ("ipad", "20x20", "2x", 40),
        ("ipad", "29x29", "1x", 29),
        ("ipad", "29x29", "2x", 58),
        ("ipad", "40x40", "1x", 40),
        ("ipad", "40x40", "2x", 80),
        ("ipad", "76x76", "1x", 76),
        ("ipad", "76x76", "2x", 152),
        ("ipad", "83.5x83.5", "2x", 167),
        ("ios-marketing", "1024x1024", "1x", 1024),
    ]
    images = []
    cache = {}
    for idiom, size_name, scale, pixels in specs:
        filename = f"icon-{pixels}.png"
        if pixels not in cache:
            icon = master if pixels == 1024 else master.resize((pixels, pixels), Image.Resampling.LANCZOS)
            icon = icon.convert("RGB")
            icon.save(ASSET / filename, "PNG", optimize=True)
            cache[pixels] = filename
        images.append({
            "idiom": idiom,
            "size": size_name,
            "scale": scale,
            "filename": cache[pixels],
        })
    contents = {"images": images, "info": {"author": "xcode", "version": 1}}
    (ASSET / "Contents.json").write_text(json.dumps(contents, indent=2) + "\n")
    print(f"wrote icon set ({len(cache)} pixel sizes) and {marketing}")


if __name__ == "__main__":
    render_icons()
    render_screens()
