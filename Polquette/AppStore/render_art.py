#!/usr/bin/env python3
"""Icons and App Store screenshots for Polquette. Pillow only, no Xcode."""

from pathlib import Path
import math
import shutil

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[1]
STORE = ROOT / "AppStore"
UPLOADS = Path("/home/ubuntu/.cursor/projects/workspace/uploads")
ICON_SRC = UPLOADS / "polquette-icon_27cc.jpg"
MODELS = {
    "red": UPLOADS / "model-red_e6b9.jpg",
    "floral": UPLOADS / "model-floral_a629.jpg",
    "glitter": UPLOADS / "model-glitter_0124.jpg",
    "french": UPLOADS / "model-french_9b9d.jpg",
}

SERIF = "/usr/share/fonts/truetype/liberation/LiberationSerif-Bold.ttf"
SERIF_REG = "/usr/share/fonts/truetype/liberation/LiberationSerif-Regular.ttf"
SANS = "/usr/share/fonts/truetype/macos/Inter-Regular.ttf"
SANS_MED = "/usr/share/fonts/truetype/macos/Inter-Medium.ttf"
SANS_SEMI = "/usr/share/fonts/truetype/macos/Inter-SemiBold.ttf"

INK = (44, 36, 34)
MUTED = (107, 89, 84)
ROSE = (196, 91, 106)
ROSE_DEEP = (139, 58, 73)
GOLD = (198, 161, 91)
PAPER = (255, 249, 244)
IVORY = (246, 239, 232)
BLUSH = (243, 214, 208)
WHITE = (255, 255, 255)
SKIN = (240, 194, 176)
SKIN_DEEP = (226, 174, 156)
LINE = (44, 36, 34, 30)

COLORS = {
    "blush-veil": (244, 194, 200),
    "rosewater": (232, 160, 176),
    "petal": (247, 213, 220),
    "ballet": (243, 211, 200),
    "nude": (230, 199, 178),
    "ivory": (246, 237, 228),
    "burgundy": (110, 36, 51),
    "coral": (233, 120, 106),
    "peach": (240, 164, 138),
    "tangerine": (224, 122, 76),
    "sage": (143, 168, 138),
    "sky": (142, 180, 212),
    "lilac": (199, 176, 214),
    "violet": (122, 92, 138),
    "cherry": (194, 59, 74),
    "ink": (42, 36, 40),
    "gold": (198, 161, 91),
    "white": (247, 244, 241),
    "silver": (201, 205, 212),
}

SHOT = (1206, 2622)


def font(path, size):
    return ImageFont.truetype(path, size)


def nail_unit(shape):
    table = {
        "almond": [(0, -1), (0.34, -0.62), (0.58, -0.08), (0.52, 0.55), (0.28, 1), (-0.28, 1), (-0.52, 0.55), (-0.58, -0.08), (-0.34, -0.62)],
        "square": [(-0.58, -0.92), (0.58, -0.92), (0.72, -0.62), (0.72, 0.55), (0.48, 1), (-0.48, 1), (-0.72, 0.55), (-0.72, -0.62)],
        "coffin": [(-0.30, -1), (0.30, -1), (0.62, -0.05), (0.46, 1), (-0.46, 1), (-0.62, -0.05)],
        "stiletto": [(0, -1), (0.22, -0.42), (0.52, 0.18), (0.40, 1), (-0.40, 1), (-0.52, 0.18), (-0.22, -0.42)],
        "rounded": [(-0.22, -0.98), (0.22, -0.98), (0.70, -0.62), (0.74, 0.35), (0.50, 1), (-0.50, 1), (-0.74, 0.35), (-0.70, -0.62)],
    }
    if shape == "oval":
        return [(math.cos(i / 20 * math.tau - math.pi / 2) * 0.62, math.sin(i / 20 * math.tau - math.pi / 2)) for i in range(20)]
    return table[shape]


def smooth(points):
    count = len(points)
    out = []
    for index in range(count):
        prev = points[index - 1]
        current = points[index]
        nxt = points[(index + 1) % count]
        start = ((prev[0] + current[0]) / 2, (prev[1] + current[1]) / 2)
        end = ((current[0] + nxt[0]) / 2, (current[1] + nxt[1]) / 2)
        for step in range(10):
            t = step / 10
            u = 1 - t
            out.append((
                u * u * start[0] + 2 * u * t * current[0] + t * t * end[0],
                u * u * start[1] + 2 * u * t * current[1] + t * t * end[1],
            ))
    return out


def sprite_points(shape, size):
    w, h = size
    pts = smooth(nail_unit(shape))
    return [(w / 2 + x * w / 2, h / 2 + y * h / 2) for x, y in pts]


def render_nail(nail, size):
    w, h = size
    image = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    mask = Image.new("L", (w, h), 0)
    pts = sprite_points(nail["shape"], size)
    ImageDraw.Draw(mask).polygon(pts, fill=255)
    bed = Image.new("RGBA", (w, h), (*COLORS[nail["color"]], 255))
    if nail.get("gradient"):
        end = COLORS[nail["gradient"]]
        base = COLORS[nail["color"]]
        grad = Image.new("RGBA", (w, h))
        pixels = grad.load()
        for y in range(h):
            t = y / max(h - 1, 1)
            color = tuple(int(end[i] + (base[i] - end[i]) * t) for i in range(3)) + (255,)
            for x in range(w):
                pixels[x, y] = color
        bed = grad
    if nail["finish"] == "chrome":
        base = COLORS[nail["color"]]
        grad = Image.new("RGBA", (w, h))
        pixels = grad.load()
        for y in range(h):
            for x in range(w):
                t = (x / max(w - 1, 1) + y / max(h - 1, 1)) / 2
                if t < 0.35:
                    u = t / 0.35
                    color = tuple(int(255 + (base[i] - 255) * u) for i in range(3))
                elif t < 0.7:
                    u = (t - 0.35) / 0.35
                    color = tuple(int(base[i] * (1 - 0.45 * u)) for i in range(3))
                else:
                    u = (t - 0.7) / 0.3
                    dark = tuple(int(base[i] * 0.55) for i in range(3))
                    color = tuple(int(dark[i] + (255 - dark[i]) * u) for i in range(3))
                pixels[x, y] = (*color, 255)
        bed = grad
    image.paste(bed, (0, 0), mask)
    if nail.get("french"):
        tip_h = max(4, int(h * nail["coverage"]))
        tip_mask = Image.new("L", (w, h), 0)
        ImageDraw.Draw(tip_mask).rectangle([0, 0, w, tip_h], fill=255)
        tip_mask = Image.frombytes("L", (w, h), bytes(a if b else 0 for a, b in zip(mask.tobytes(), tip_mask.tobytes())))
        tip = Image.new("RGBA", (w, h), (*COLORS[nail["tip"]], 255))
        image.paste(tip, (0, 0), tip_mask)
    draw = ImageDraw.Draw(image)
    if nail["finish"] == "plain":
        pass
    elif nail["finish"] == "gloss":
        draw.ellipse([w * 0.34, h * 0.24, w * 0.56, h * 0.38], fill=(255, 255, 255, 110))
    elif nail["finish"] == "matte":
        shade = Image.new("RGBA", (w, h), (0, 0, 0, 28))
        image.paste(shade, (0, 0), mask)
    elif nail["finish"] == "cream":
        draw.ellipse([w * 0.3, h * 0.34, w * 0.7, h * 0.62], fill=(255, 255, 255, 36))
    elif nail["finish"] == "shimmer":
        draw.ellipse([w * 0.34, h * 0.24, w * 0.56, h * 0.38], fill=(255, 255, 255, 80))
        seed = nail.get("seed", 1) + 9
        for i in range(10):
            seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF
            x = 6 + (seed % max(w - 12, 1))
            seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF
            y = 6 + (seed % max(h - 12, 1))
            draw.ellipse([x, y, x + 2, y + 2], fill=(255, 255, 255, 180))
    elif nail["finish"] == "glitter":
        seed = nail.get("seed", 1)
        for i in range(16):
            seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF
            x = 4 + (seed % (w - 8))
            seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF
            y = 4 + (seed % (h - 8))
            color = (255, 255, 255, 220) if i % 2 == 0 else (*GOLD, 230)
            r = 2 if i % 3 else 3
            draw.ellipse([x, y, x + r, y + r], fill=color)
    if not nail.get("plain_base"):
        cuticle = Image.new("L", (w, h), 0)
        ImageDraw.Draw(cuticle).rectangle([0, int(h * 0.9), w, h], fill=255)
        cuticle_bytes = bytes(min(a, b) for a, b in zip(mask.tobytes(), cuticle.tobytes()))
        shade = Image.new("RGBA", (w, h), (90, 50, 50, 28))
        image.paste(shade, (0, 0), Image.frombytes("L", (w, h), cuticle_bytes))
    draw_decorations(image, nail, size)
    # keep only the nail silhouette
    blank = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    blank.paste(image, (0, 0), mask)
    return blank


def draw_decorations(image, nail, size):
    w, h = size
    draw = ImageDraw.Draw(image)
    for deco in nail.get("decor", []):
        cx = deco["x"] * w
        cy = deco["y"] * h
        unit = min(w, h) * 0.18 * deco.get("scale", 1)
        color = COLORS[deco["color"]] + (255,)
        kind = deco["kind"]
        if kind == "pearl":
            draw.ellipse([cx - unit * 0.45, cy - unit * 0.45, cx + unit * 0.45, cy + unit * 0.45], fill=color)
            draw.ellipse([cx - unit * 0.28, cy - unit * 0.34, cx - unit * 0.02, cy - unit * 0.08], fill=(255, 255, 255, 230))
        elif kind == "foil":
            flake = [(cx - unit * 0.2, cy - unit * 0.45), (cx + unit * 0.5, cy - unit * 0.1), (cx + unit * 0.15, cy + unit * 0.4), (cx - unit * 0.45, cy + unit * 0.1)]
            draw.polygon(flake, fill=color)
            draw.line(flake + [flake[0]], fill=(255, 255, 255, 160), width=1)
        elif kind == "flower":
            for petal in range(5):
                ang = petal / 5 * math.tau - math.pi / 2
                px = cx + math.cos(ang) * unit * 0.32
                py = cy + math.sin(ang) * unit * 0.32
                draw.ellipse([px - unit * 0.26, py - unit * 0.18, px + unit * 0.26, py + unit * 0.18], fill=color)
            draw.ellipse([cx - unit * 0.14, cy - unit * 0.14, cx + unit * 0.14, cy + unit * 0.14], fill=(*GOLD, 255))
        elif kind == "line":
            draw.line([(cx - unit * 1.5, cy), (cx + unit * 1.5, cy)], fill=color, width=max(2, int(unit * 0.16)))
        elif kind == "gem":
            gem = [(cx, cy - unit * 0.5), (cx + unit * 0.38, cy), (cx, cy + unit * 0.5), (cx - unit * 0.38, cy)]
            draw.polygon(gem, fill=color)
        elif kind == "sticker":
            draw.polygon([(cx, cy - unit * 0.45), (cx + unit * 0.18, cy - unit * 0.12), (cx + unit * 0.48, cy - unit * 0.12), (cx + unit * 0.24, cy + unit * 0.08), (cx + unit * 0.34, cy + unit * 0.48), (cx, cy + unit * 0.22), (cx - unit * 0.34, cy + unit * 0.48), (cx - unit * 0.24, cy + unit * 0.08), (cx - unit * 0.48, cy - unit * 0.12), (cx - unit * 0.18, cy - unit * 0.12)], fill=color)


def hand_image(nails, box):
    width, height = box
    image = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    draw.rounded_rectangle([0, 0, width - 1, height - 1], radius=28, fill=(*BLUSH, 255))
    digits = [
        (0.16, 0.24, 0.26, 0.72, 0.086),
        (0.34, 0.12, 0.38, 0.74, 0.094),
        (0.52, 0.07, 0.52, 0.74, 0.100),
        (0.70, 0.13, 0.66, 0.74, 0.092),
        (0.88, 0.40, 0.70, 0.78, 0.112),
    ]
    prepared = []
    for spec, nail in zip(digits, nails):
        tip = (spec[0] * width, spec[1] * height)
        base = (spec[2] * width, spec[3] * height)
        thick = spec[4] * width
        radius = thick / 2
        draw.line([base, tip], fill=(*SKIN, 255), width=int(thick))
        draw.ellipse([base[0] - radius, base[1] - radius, base[0] + radius, base[1] + radius], fill=(*SKIN, 255))
        draw.ellipse([tip[0] - radius, tip[1] - radius, tip[0] + radius, tip[1] + radius], fill=(*SKIN, 255))
        dx, dy = tip[0] - base[0], tip[1] - base[1]
        length = max(math.hypot(dx, dy), 1)
        nail_w = int(thick * 1.02)
        nail_h = int(min(length * 0.40, nail_w * 1.55))
        along = length - nail_h * 0.42
        center = (base[0] + dx / length * along, base[1] + dy / length * along)
        angle = math.degrees(math.atan2(dx, -dy))
        prepared.append((nail, center, angle, nail_w, nail_h))
    draw.ellipse([width * 0.14, height * 0.62, width * 0.84, height * 0.98], fill=(*SKIN, 255))
    for nail, center, angle, nail_w, nail_h in prepared:
        sprite = render_nail(nail, (max(nail_w, 8), max(nail_h, 12)))
        rotated = sprite.rotate(-angle, expand=True, resample=Image.Resampling.BICUBIC)
        paste_at = (int(center[0] - rotated.width / 2), int(center[1] - rotated.height / 2))
        image.alpha_composite(rotated, paste_at)
    return image


def same_nail(**kwargs):
    nail = {
        "shape": "almond",
        "color": "ballet",
        "finish": "gloss",
        "french": False,
        "coverage": 0.28,
        "tip": "white",
        "decor": [],
        "seed": 3,
    }
    nail.update(kwargs)
    return [dict(nail, seed=i + 1) for i in range(5)]


def blush_set():
    nails = same_nail(shape="almond", color="blush-veil", finish="shimmer")
    for nail in nails:
        nail["decor"] = [{"kind": "pearl", "color": "white", "x": 0.5, "y": 0.62, "scale": 0.85}]
    return nails


def burgundy_set():
    nails = same_nail(shape="coffin", color="burgundy", finish="gloss")
    for nail in nails:
        nail["decor"] = [
            {"kind": "foil", "color": "gold", "x": 0.38, "y": 0.36, "scale": 0.9},
            {"kind": "foil", "color": "gold", "x": 0.66, "y": 0.6, "scale": 0.75},
        ]
    return nails


def bloom_set():
    pairs = [("petal", "coral"), ("lilac", "tangerine"), ("sky", "cherry"), ("peach", "violet"), ("ivory", "sage")]
    nails = []
    for index, (base, tip) in enumerate(pairs):
        nails.append({
            "shape": "oval",
            "color": base,
            "finish": "gloss",
            "french": True,
            "coverage": 0.32,
            "tip": tip,
            "seed": index + 4,
            "decor": [{"kind": "flower", "color": tip, "x": 0.5, "y": 0.64, "scale": 0.9}],
        })
    return nails


def nude_set():
    nails = same_nail(shape="almond", color="nude", finish="cream")
    for nail in nails:
        nail["decor"] = [{"kind": "line", "color": "gold", "x": 0.5, "y": 0.28, "scale": 1}]
    return nails


def red_set():
    return same_nail(shape="rounded", color="cherry", finish="gloss")


def floral_set():
    nails = same_nail(shape="oval", color="lilac", finish="gloss")
    for nail in nails:
        nail["decor"] = [{"kind": "flower", "color": "white", "x": 0.5, "y": 0.58, "scale": 0.95}]
    return nails


def glitter_set():
    return same_nail(shape="almond", color="gold", finish="glitter")


def french_set():
    return same_nail(shape="rounded", color="ivory", finish="gloss", french=True, coverage=0.28, tip="white")


def rounded_mask(image, radius):
    image = image.convert("RGBA")
    mask = Image.new("L", image.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, image.size[0] - 1, image.size[1] - 1], radius=radius, fill=255)
    image.putalpha(mask)
    return image


def cover(image, size, anchor=(0.5, 0.46)):
    tw, th = size
    scale = max(tw / image.width, th / image.height)
    resized = image.resize((int(image.width * scale), int(image.height * scale)), Image.Resampling.LANCZOS)
    left = int((resized.width - tw) * anchor[0])
    top = int((resized.height - th) * anchor[1])
    left = max(0, min(left, resized.width - tw))
    top = max(0, min(top, resized.height - th))
    return resized.crop((left, top, left + tw, top + th))


def text_size(draw, text, face):
    box = draw.textbbox((0, 0), text, font=face)
    return box[2] - box[0], box[3] - box[1]


def draw_chip(draw, xy, label, face, selected):
    x, y = xy
    tw, th = text_size(draw, label, face)
    pad_x, pad_y = 18, 10
    box = [x, y, x + tw + pad_x * 2, y + th + pad_y * 2]
    fill = ROSE if selected else PAPER
    outline = ROSE if selected else (230, 220, 214)
    draw.rounded_rectangle(box, radius=(box[3] - box[1]) / 2, fill=fill, outline=outline, width=2)
    draw.text((x + pad_x, y + pad_y - 2), label, font=face, fill=WHITE if selected else INK)
    return box[2] + 12, box[3] - box[1]


def studio_panel(size, scene):
    width, height = size
    image = Image.new("RGBA", (width, height), (*PAPER, 255))
    draw = ImageDraw.Draw(image)
    title_face = font(SERIF, max(28, width // 22))
    small = font(SANS_MED, max(16, width // 42))
    tiny = font(SANS, max(14, width // 48))
    draw.text((28, 26), "Studio", font=title_face, fill=INK)
    controls = ["Undo", "Redo", "Save"]
    x = width - 28
    for label in reversed(controls):
        tw, th = text_size(draw, label, small)
        x -= tw
        draw.text((x, 36), label, font=small, fill=ROSE_DEEP if label != "Save" else INK)
        x -= 22
    draw.text((28, 96), "Painting all five", font=font(SERIF_REG, max(20, width // 30)), fill=INK)
    pill = "All five"
    pw, ph = text_size(draw, pill, small)
    pill_box = [width - pw - 64, 90, width - 24, 90 + ph + 18]
    draw.rounded_rectangle(pill_box, radius=20, fill=INK)
    draw.text((pill_box[0] + 16, pill_box[1] + 8), pill, font=small, fill=WHITE)

    hand_top = 148
    tool_block = 300 if scene.get("tab") == "French" else 220
    hand_box = (width - 48, max(180, height - hand_top - tool_block - 24))
    hand = hand_image(scene["nails"], hand_box)
    image.alpha_composite(hand, (24, hand_top))

    y = hand_top + hand_box[1] + 12
    x = 16
    chip_face = font(SANS_MED, max(13, min(18, width // 42)))
    for label in ["Shape", "Color", "Finish", "French", "Fade", "Decor"]:
        if x > width - 70:
            break
        x, chip_h = draw_chip(draw, (x, y), label, chip_face, label == scene["tab"])
    y += 54
    if scene["tab"] == "Color":
        x = 16
        for name in ["blush-veil", "petal", "nude", "cherry", "burgundy", "coral", "sage", "lilac", "gold", "white"]:
            if x > width - 40:
                break
            selected = name == scene.get("selected")
            draw.ellipse([x, y, x + 32, y + 32], fill=COLORS[name], outline=GOLD if selected else WHITE, width=4 if selected else 2)
            x += 42
    elif scene["tab"] == "Finish":
        x = 16
        for label in ["Gloss", "Matte", "Cream", "Chrome", "Shimmer", "Glitter"]:
            x, _ = draw_chip(draw, (x, y), label, chip_face, label == scene.get("selected"))
    elif scene["tab"] == "Shape":
        x = 16
        for label in ["Almond", "Square", "Coffin", "Oval", "Stiletto", "Rounded"]:
            if x > width - 80:
                break
            x, _ = draw_chip(draw, (x, y), label, chip_face, label == scene.get("selected"))
    elif scene["tab"] == "Decor":
        x = 16
        for label in ["Daisy", "Blossom", "Pearl", "Flake", "Heart"]:
            x, _ = draw_chip(draw, (x, y), label, chip_face, label == scene.get("selected"))
        draw.text((16, y + 50), "Tap a piece to place it. Up to four on a nail.", font=tiny, fill=MUTED)
    elif scene["tab"] == "French":
        draw.text((16, y), "French tip", font=chip_face, fill=INK)
        toggle = [width - 78, y - 2, width - 20, y + 26]
        draw.rounded_rectangle(toggle, radius=14, fill=ROSE)
        draw.ellipse([toggle[2] - 24, toggle[1] + 3, toggle[2] - 4, toggle[3] - 3], fill=WHITE)
        draw.text((16, y + 40), "Tip color", font=tiny, fill=MUTED)
        x = 16
        for name in ["white", "nude", "blush-veil", "gold"]:
            selected = name == scene.get("selected")
            draw.ellipse([x, y + 64, x + 28, y + 92], fill=COLORS[name], outline=INK if selected else WHITE, width=3 if selected else 1)
            x += 38
        draw.text((16, y + 104), "Length", font=tiny, fill=MUTED)
        draw.rounded_rectangle([16, y + 128, width - 20, y + 136], radius=4, fill=(230, 214, 214))
        draw.ellipse([width * 0.42, y + 122, width * 0.42 + 22, y + 144], fill=ROSE)
    return image


def challenge_panel(size):
    width, height = size
    image = Image.new("RGBA", (width, height), (*IVORY, 255))
    draw = ImageDraw.Draw(image)
    title = font(SERIF, max(28, width // 24))
    body = font(SANS, max(16, width // 42))
    semi = font(SANS_SEMI, max(16, width // 42))
    draw.text((28, 24), "Today’s chair", font=title, fill=INK)
    card = [24, 90, width - 24, 360]
    draw.rounded_rectangle(card, radius=22, fill=PAPER, outline=(230, 220, 214), width=2)
    draw.text((48, 112), "Today: Blush Pearl", font=font(SERIF, max(24, width // 28)), fill=INK)
    note = "Almond nails, a blush color, shimmer, and pearls on at least three nails."
    draw_wrapped(draw, note, font(SANS, max(16, width // 44)), (48, 168), width - 96, MUTED)
    draw_stars(draw, (48, 250), 2)
    button = [48, 292, 250, 338]
    draw.rounded_rectangle(button, radius=18, fill=INK)
    draw.text((72, 302), "Design this", font=semi, fill=WHITE)

    draw.text((28, 390), "The book of chairs", font=title, fill=INK)
    rows = [
        ("1. Blush Pearl", "Mira, a morning guest", 3, False),
        ("2. Burgundy Foil", "Elena, after six", 2, False),
        ("3. Colorful Bloom", "A guest from the garden", 0, False),
        ("4. Nude Gold Line", "A quiet afternoon", 0, True),
        ("5. Midnight Chrome", "A late booking", 0, True),
        ("6. Sage Cream", "A Saturday regular", 0, True),
        ("7. Coral Glitter", "A birthday table", 0, True),
    ]
    y = 460
    for name, client, stars, locked in rows:
        if y + 110 > height - 20:
            break
        draw.rounded_rectangle([24, y, width - 24, y + 100], radius=18, fill=PAPER, outline=(230, 220, 214), width=2)
        draw.text((44, y + 16), name, font=semi, fill=INK)
        draw.text((44, y + 52), client, font=body, fill=MUTED)
        if locked:
            draw.text((width - 110, y + 36), "Locked", font=body, fill=MUTED)
        else:
            draw_stars(draw, (width - 130, y + 36), stars)
        y += 116
    return image


def draw_wrapped(draw, text, face, origin, width, fill):
    words = text.split()
    line = ""
    x, y = origin
    for word in words:
        trial = word if not line else line + " " + word
        if text_size(draw, trial, face)[0] <= width:
            line = trial
        else:
            draw.text((x, y), line, font=face, fill=fill)
            y += int(face.size * 1.35)
            line = word
    if line:
        draw.text((x, y), line, font=face, fill=fill)


def draw_stars(draw, origin, filled):
    x, y = origin
    for index in range(3):
        color = GOLD if index < filled else (210, 200, 194)
        cx, cy, r = x + index * 28 + 10, y + 10, 9
        points = []
        for k in range(10):
            ang = k / 10 * math.tau - math.pi / 2
            radius = r if k % 2 == 0 else r * 0.45
            points.append((cx + math.cos(ang) * radius, cy + math.sin(ang) * radius))
        draw.polygon(points, fill=color)


def looks_panel(size):
    width, height = size
    image = Image.new("RGBA", (width, height), (*IVORY, 255))
    draw = ImageDraw.Draw(image)
    title = font(SERIF, max(26, width // 16))
    body = font(SANS, max(13, width // 48))
    semi = font(SANS_SEMI, max(14, width // 44))
    draw.text((20, 8), "Looks", font=title, fill=INK)
    cards = [
        ("Blush Pearl", "Almond, blush veil, shimmer, and a pearl.", blush_set()),
        ("Colorful Bloom", "A bright tip and a tiny flower on each nail.", bloom_set()),
        ("Ivory French", "Rounded ivory nails with a classic white tip.", french_set()),
    ]
    y = 64
    card_h = max(180, (height - y - 16) // len(cards) - 12)
    for name, blurb, nails in cards:
        if y + card_h > height - 8:
            break
        draw.rounded_rectangle([16, y, width - 16, y + card_h], radius=18, fill=PAPER, outline=(230, 220, 214), width=2)
        draw.text((32, y + 12), name, font=font(SERIF, max(18, width // 28)), fill=INK)
        draw.text((32, y + 42), blurb, font=body, fill=MUTED)
        button_top = y + card_h - 48
        hand_top = y + 68
        hand_h = max(80, button_top - hand_top - 12)
        hand = hand_image(nails, (width - 64, hand_h))
        image.alpha_composite(hand, (32, hand_top))
        draw.rounded_rectangle([32, button_top, 196, button_top + 32], radius=14, fill=INK)
        draw.text((46, button_top + 6), "Use this look", font=semi, fill=WHITE)
        y += card_h + 12
    return image


def lilac_canvas(size):
    small = Image.new("RGB", (24, 48))
    pix = small.load()
    stops = [(214, 170, 216), (244, 176, 198), (246, 206, 186)]
    for y in range(48):
        for x in range(24):
            t = x / 23 * 0.72 + y / 47 * 0.28
            if t < 0.5:
                u = t / 0.5
                a, b = stops[0], stops[1]
            else:
                u = (t - 0.5) / 0.5
                a, b = stops[1], stops[2]
            pix[x, y] = tuple(int(a[i] + (b[i] - a[i]) * u) for i in range(3))
    return small.resize(size, Image.Resampling.BICUBIC)


def phone_frame(ui):
    """Place the app UI in a flat-sided iPhone with a Dynamic Island."""
    status_h = 86
    screen_w = ui.width
    screen_h = ui.height + status_h
    screen = Image.new("RGBA", (screen_w, screen_h), (*PAPER, 255))
    draw = ImageDraw.Draw(screen)
    time_face = font(SANS_SEMI, 22)
    draw.text((28, 28), "9:41", font=time_face, fill=INK)
    battery = [screen_w - 58, 30, screen_w - 26, 48]
    draw.rounded_rectangle(battery, radius=4, outline=INK, width=2)
    draw.rectangle([battery[2] + 2, 36, battery[2] + 5, 42], fill=INK)
    draw.rounded_rectangle([battery[0] + 3, battery[1] + 3, battery[0] + 22, battery[3] - 3], radius=2, fill=INK)
    screen.alpha_composite(ui, (0, status_h))
    island_w, island_h = int(screen_w * 0.34), 40
    island = [(screen_w - island_w) // 2, 22, (screen_w + island_w) // 2, 22 + island_h]
    draw.rounded_rectangle(island, radius=island_h / 2, fill=(12, 12, 14))
    draw.ellipse([island[2] - 28, island[1] + 10, island[2] - 12, island[3] - 10], fill=(28, 32, 40))
    draw.ellipse([island[2] - 23, island[1] + 15, island[2] - 17, island[3] - 15], fill=(70, 90, 120))

    bezel = 14
    body = Image.new("RGBA", (screen_w + bezel * 2 + 10, screen_h + bezel * 2), (0, 0, 0, 0))
    bdraw = ImageDraw.Draw(body)
    outer = [4, 0, body.width - 6, body.height - 1]
    bdraw.rounded_rectangle(outer, radius=58, fill=(28, 28, 31))
    bdraw.rounded_rectangle([outer[0] + 2, outer[1] + 2, outer[2] - 2, outer[3] - 2], radius=54, outline=(88, 88, 94), width=2)
    # Side buttons sit on the metal edge.
    bdraw.rounded_rectangle([0, 150, 6, 196], radius=2, fill=(64, 64, 70))
    bdraw.rounded_rectangle([0, 230, 6, 310], radius=2, fill=(64, 64, 70))
    bdraw.rounded_rectangle([0, 330, 6, 410], radius=2, fill=(64, 64, 70))
    bdraw.rounded_rectangle([body.width - 6, 260, body.width - 1, 360], radius=2, fill=(64, 64, 70))
    mask = Image.new("L", screen.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, screen_w - 1, screen_h - 1], radius=46, fill=255)
    screen.putalpha(mask)
    body.alpha_composite(screen, (bezel + 4, bezel))
    return body


def compose(scene, photo):
    canvas = lilac_canvas(SHOT).convert("RGBA")
    draw = ImageDraw.Draw(canvas)
    margin = 52
    headline = font(SERIF, 64)
    sub = font(SANS, 30)
    y = 64
    for line in scene["headline"].split("\n"):
        draw.text((margin, y), line, font=headline, fill=INK)
        y += 72
    draw.text((margin, y + 6), scene["sub"], font=sub, fill=(90, 58, 78))
    y += 56
    photo_h = 780
    photo_box = (SHOT[0] - margin * 2, photo_h)
    shot = cover(photo, photo_box, anchor=(0.5, scene.get("anchor", 0.5)))
    shot = rounded_mask(shot, 32)
    photo_origin = (margin, y)
    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle(
        [photo_origin[0] + 6, photo_origin[1] + 12, photo_origin[0] + photo_box[0] + 6, photo_origin[1] + photo_box[1] + 12],
        radius=32,
        fill=(70, 40, 60, 46),
    )
    canvas.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(14)))
    canvas.alpha_composite(shot, photo_origin)

    ui_w = 760
    phone_top_guess = photo_origin[1] + photo_box[1] + 22
    ui_h = max(1080, SHOT[1] - phone_top_guess - 86 - 36 - 48)
    if scene["kind"] == "studio":
        panel = studio_panel((ui_w, ui_h), scene)
    elif scene["kind"] == "looks":
        panel = looks_panel((ui_w, ui_h))
    else:
        panel = challenge_panel((ui_w, ui_h))
    phone = phone_frame(panel)
    scale = min(1.0, (SHOT[1] - (photo_origin[1] + photo_box[1] + 28) - 36) / phone.height)
    if scale < 1:
        phone = phone.resize((int(phone.width * scale), int(phone.height * scale)), Image.Resampling.LANCZOS)
    px = (SHOT[0] - phone.width) // 2
    py = photo_origin[1] + photo_box[1] + 28
    phone_shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(phone_shadow).rounded_rectangle(
        [px + 16, py + 20, px + phone.width - 8, py + phone.height + 10],
        radius=60,
        fill=(60, 30, 50, 60),
    )
    canvas.alpha_composite(phone_shadow.filter(ImageFilter.GaussianBlur(18)))
    canvas.alpha_composite(phone, (px, py))
    return canvas.convert("RGB")


SCENES = [
    {
        "file": "01-cherry-studio.png",
        "kind": "studio",
        "headline": "Cherry, on\nevery nail",
        "sub": "Paint all five, or just one finger.",
        "photo": "red",
        "anchor": 0.58,
        "tab": "Color",
        "selected": "cherry",
        "nails": red_set(),
    },
    {
        "file": "02-lavender-looks.png",
        "kind": "looks",
        "headline": "A look, in\none tap",
        "sub": "Start from a set, then change any nail.",
        "photo": "floral",
        "anchor": 0.62,
        "tab": "Decor",
        "selected": "Daisy",
        "nails": floral_set(),
    },
    {
        "file": "03-gold-glitter.png",
        "kind": "studio",
        "headline": "Gold glitter,\nheld up close",
        "sub": "Gloss, cream, chrome, shimmer, or glitter.",
        "photo": "glitter",
        "anchor": 0.52,
        "tab": "Finish",
        "selected": "Glitter",
        "nails": glitter_set(),
    },
    {
        "file": "04-french-tip.png",
        "kind": "studio",
        "headline": "A quiet\nFrench tip",
        "sub": "Choose the tip color and how long it sits.",
        "photo": "french",
        "anchor": 0.48,
        "tab": "French",
        "selected": "white",
        "nails": french_set(),
    },
    {
        "file": "05-salon-chairs.png",
        "kind": "challenge",
        "headline": "Today’s chair\nis waiting",
        "sub": "Twelve appointments. Up to three stars.",
        "photo": "red",
        "anchor": 0.42,
        "tab": "Color",
        "selected": "cherry",
        "nails": french_set(),
    },
]


def install_icon(master):
    if master.mode != "RGB" or master.size != (1024, 1024):
        master = master.convert("RGB").resize((1024, 1024), Image.Resampling.LANCZOS)
    if master.mode != "RGB":
        raise SystemExit(f"icon mode {master.mode}")
    (STORE / "icon").mkdir(parents=True, exist_ok=True)
    icon_path = STORE / "icon" / "AppIcon-1024.png"
    master.save(icon_path, "PNG")
    icon_set = ROOT / "App" / "Assets.xcassets" / "AppIcon.appiconset"
    icon_set.mkdir(parents=True, exist_ok=True)
    for side in [20, 29, 40, 58, 60, 76, 80, 87, 120, 152, 167, 180, 1024]:
        resized = master if side == 1024 else master.resize((side, side), Image.Resampling.LANCZOS)
        if resized.mode != "RGB":
            resized = resized.convert("RGB")
        resized.save(icon_set / f"icon-{side}.png", "PNG")
    web = STORE / "website"
    master.resize((32, 32), Image.Resampling.LANCZOS).save(web / "favicon-32.png", "PNG")
    master.resize((180, 180), Image.Resampling.LANCZOS).save(web / "apple-touch-icon.png", "PNG")
    return icon_path


def copy_models():
    dest = STORE / "models"
    dest.mkdir(parents=True, exist_ok=True)
    for old in dest.glob("*"):
        old.unlink()
    names = {
        "red": "model-red.jpg",
        "floral": "model-floral.jpg",
        "glitter": "model-glitter.jpg",
        "french": "model-french.jpg",
    }
    copied = {}
    for key, filename in names.items():
        target = dest / filename
        shutil.copyfile(MODELS[key], target)
        copied[key] = Image.open(target).convert("RGB")
    return copied


def main():
    photos = copy_models()
    icon = Image.open(ICON_SRC).convert("RGB")
    icon_path = install_icon(icon)
    shot_root = STORE / "screenshots"
    if shot_root.exists():
        shutil.rmtree(shot_root)
    folder = shot_root / "iphone-1206x2622"
    folder.mkdir(parents=True)
    for scene in SCENES:
        image = compose(scene, photos[scene["photo"]])
        if image.size != SHOT or image.mode != "RGB":
            raise SystemExit(f"bad screenshot {image.size} {image.mode}")
        image.save(folder / scene["file"], "PNG")
        print(f"wrote iphone-1206x2622/{scene['file']} {image.size} {image.mode}")
    print(f"wrote {icon_path}")


if __name__ == "__main__":
    main()
