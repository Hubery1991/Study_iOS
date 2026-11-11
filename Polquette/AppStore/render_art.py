#!/usr/bin/env python3
"""Icons and App Store screenshots for Polquette. Pillow only, no Xcode."""

from pathlib import Path
import math
import shutil

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[1]
STORE = ROOT / "AppStore"
UPLOADS = Path("/home/ubuntu/.cursor/projects/workspace/uploads")
MODELS = {
    "blush": UPLOADS / "model-1-blush_cb4a.jpg",
    "burgundy": UPLOADS / "model-2-burgundy_a463.jpg",
    "colorful": UPLOADS / "model-3-colorful_ba69.jpg",
    "nude": UPLOADS / "model-4-nude_25e0.jpg",
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

DEVICES = {
    "iphone-6.9": (1320, 2868),
    "iphone-6.7": (1284, 2778),
    "iphone-6.5": (1242, 2688),
    "ipad-13": (2064, 2752),
}


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

    hand_top = 160
    tool_block = 210 if height > 700 else 170
    hand_box = (width - 48, max(180, height - hand_top - tool_block - 24))
    hand = hand_image(scene["nails"], hand_box)
    image.alpha_composite(hand, (24, hand_top))

    y = hand_top + hand_box[1] + 16
    x = 24
    chip_face = font(SANS_MED, max(15, width // 46))
    for label in ["Shape", "Color", "Finish", "French", "Fade", "Decor"]:
        x, _ = draw_chip(draw, (x, y), label, chip_face, label == scene["tab"])
    y += 62
    if scene["tab"] == "Color":
        x = 24
        for name in ["blush-veil", "rosewater", "petal", "ballet", "nude", "burgundy", "coral", "sage", "lilac", "ink", "gold", "white"]:
            selected = name == scene.get("selected")
            draw.ellipse([x, y, x + 36, y + 36], fill=COLORS[name], outline=GOLD if selected else WHITE, width=4 if selected else 2)
            x += 48
    elif scene["tab"] == "Finish":
        x = 24
        for label in ["Gloss", "Matte", "Cream", "Chrome", "Shimmer", "Glitter"]:
            x, _ = draw_chip(draw, (x, y), label, chip_face, label == scene.get("selected"))
    elif scene["tab"] == "Shape":
        x = 24
        for label in ["Almond", "Square", "Coffin", "Oval", "Stiletto", "Rounded"]:
            x, _ = draw_chip(draw, (x, y), label, chip_face, label == scene.get("selected"))
    elif scene["tab"] == "Decor":
        x = 24
        for label in ["Daisy", "Blossom", "Pearl", "Flake", "Tip line", "Heart"]:
            x, _ = draw_chip(draw, (x, y), label, chip_face, label == scene.get("selected"))
        draw.text((24, y + 58), "Tap a piece to place it. Up to four on a nail.", font=tiny, fill=MUTED)
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


def compose(device, scene, photo):
    width, height = DEVICES[device]
    wide = device.startswith("ipad")
    canvas = Image.new("RGBA", (width, height), scene["bg"] + (255,))
    draw = ImageDraw.Draw(canvas)
    margin = 72 if wide else 56
    kicker = font(SANS_SEMI, 28 if wide else 22)
    headline = font(SERIF, 84 if wide else 68)
    draw.text((margin, 78 if wide else 96), "POLQUETTE", font=kicker, fill=ROSE_DEEP)
    y = 130 if wide else 146
    for line in scene["headline"].split("\n"):
        draw.text((margin, y), line, font=headline, fill=INK)
        y += int(headline.size * 1.05)
    content_top = y + 36
    if wide:
        photo_box = (int(width * 0.40), height - content_top - 72)
        ui_origin = (margin + photo_box[0] + 36, content_top)
        ui_size = (width - ui_origin[0] - margin, photo_box[1])
        photo_origin = (margin, content_top)
    else:
        photo_h = int(height * 0.34)
        photo_box = (width - margin * 2, photo_h)
        photo_origin = (margin, content_top)
        ui_origin = (margin, content_top + photo_h + 28)
        ui_size = (width - margin * 2, height - ui_origin[1] - 48)
    shot = cover(photo, photo_box, anchor=(0.5, scene.get("anchor", 0.46)))
    shot = rounded_mask(shot, 36)
    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle(
        [photo_origin[0] + 8, photo_origin[1] + 14, photo_origin[0] + photo_box[0] + 8, photo_origin[1] + photo_box[1] + 14],
        radius=36,
        fill=(44, 36, 34, 40),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(16))
    canvas.alpha_composite(shadow)
    canvas.alpha_composite(shot, photo_origin)
    panel = studio_panel(ui_size, scene) if scene["kind"] == "studio" else challenge_panel(ui_size)
    panel = rounded_mask(panel, 32)
    ui_shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(ui_shadow).rounded_rectangle(
        [ui_origin[0] + 6, ui_origin[1] + 12, ui_origin[0] + ui_size[0] + 6, ui_origin[1] + ui_size[1] + 12],
        radius=32,
        fill=(44, 36, 34, 36),
    )
    ui_shadow = ui_shadow.filter(ImageFilter.GaussianBlur(14))
    canvas.alpha_composite(ui_shadow)
    canvas.alpha_composite(panel, ui_origin)
    return canvas.convert("RGB")


SCENES = [
    {
        "file": "01-blush-pearl.png",
        "kind": "studio",
        "headline": "Blush Pearl,\nin one tap",
        "bg": (247, 226, 230),
        "photo": "blush",
        "anchor": 0.42,
        "tab": "Color",
        "selected": "blush-veil",
        "nails": blush_set(),
    },
    {
        "file": "02-burgundy-foil.png",
        "kind": "studio",
        "headline": "Burgundy, foil,\nand gold",
        "bg": (243, 230, 204),
        "photo": "burgundy",
        "anchor": 0.50,
        "tab": "Finish",
        "selected": "Gloss",
        "nails": burgundy_set(),
    },
    {
        "file": "03-colorful-bloom.png",
        "kind": "studio",
        "headline": "A bloom on\nevery nail",
        "bg": (232, 222, 242),
        "photo": "colorful",
        "anchor": 0.62,
        "tab": "Decor",
        "selected": "Daisy",
        "nails": bloom_set(),
    },
    {
        "file": "04-nude-gold-line.png",
        "kind": "studio",
        "headline": "A thin gold line",
        "bg": (214, 236, 228),
        "photo": "nude",
        "anchor": 0.52,
        "tab": "Shape",
        "selected": "Almond",
        "nails": nude_set(),
    },
    {
        "file": "05-todays-chair.png",
        "kind": "challenge",
        "headline": "Today’s chair\nis waiting",
        "bg": (246, 239, 232),
        "photo": "blush",
        "anchor": 0.42,
        "tab": "Color",
        "selected": "blush-veil",
        "nails": blush_set(),
    },
]


def draw_icon(size):
    image = Image.new("RGB", (size, size), IVORY)
    draw = ImageDraw.Draw(image)
    for y in range(size):
        t = y / size
        color = tuple(int(IVORY[i] + (BLUSH[i] - IVORY[i]) * t) for i in range(3))
        draw.line([(0, y), (size, y)], fill=color)
    nail = render_nail(
        {
            "shape": "almond",
            "color": "blush-veil",
            "finish": "plain",
            "french": False,
            "decor": [
                {"kind": "line", "color": "gold", "x": 0.5, "y": 0.3, "scale": 1},
                {"kind": "pearl", "color": "white", "x": 0.5, "y": 0.68, "scale": 1.1},
            ],
            "seed": 2,
            "plain_base": True,
        },
        (int(size * 0.46), int(size * 0.70)),
    )
    image.paste(nail, (int(size * 0.27), int(size * 0.14)), nail)
    return image


def copy_models():
    dest = STORE / "models"
    dest.mkdir(parents=True, exist_ok=True)
    names = {
        "blush": "model-1-blush.jpg",
        "burgundy": "model-2-burgundy.jpg",
        "colorful": "model-3-colorful.jpg",
        "nude": "model-4-nude.jpg",
    }
    copied = {}
    for key, filename in names.items():
        target = dest / filename
        shutil.copyfile(MODELS[key], target)
        copied[key] = Image.open(target).convert("RGB")
    return copied


def main():
    photos = copy_models()
    icon = draw_icon(1024)
    if icon.mode != "RGB":
        raise SystemExit(f"icon mode {icon.mode}")
    (STORE / "icon").mkdir(parents=True, exist_ok=True)
    icon_path = STORE / "icon" / "AppIcon-1024.png"
    icon.save(icon_path, "PNG")
    icon_set = ROOT / "App" / "Assets.xcassets" / "AppIcon.appiconset"
    icon_set.mkdir(parents=True, exist_ok=True)
    sizes = [20, 29, 40, 58, 60, 76, 80, 87, 120, 152, 167, 180, 1024]
    for side in sizes:
        resized = icon if side == 1024 else icon.resize((side, side), Image.Resampling.LANCZOS)
        resized.save(icon_set / f"icon-{side}.png", "PNG")
    shutil.copyfile(icon_path, icon_set / "icon-1024.png")
    for device, (width, height) in DEVICES.items():
        folder = STORE / "screenshots" / device
        folder.mkdir(parents=True, exist_ok=True)
        for scene in SCENES:
            image = compose(device, scene, photos[scene["photo"]])
            if image.size != (width, height) or image.mode != "RGB":
                raise SystemExit(f"bad screenshot {device} {image.size} {image.mode}")
            image.save(folder / scene["file"], "PNG")
            print(f"wrote {device}/{scene['file']} {image.size}")
    print(f"wrote {icon_path}")


if __name__ == "__main__":
    main()
