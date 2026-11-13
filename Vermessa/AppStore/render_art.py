#!/usr/bin/env python3
"""Build the Vermessa icon set and five 1206×2622 marketing screenshots.

Portraits and the icon artwork are used as supplied. This script scales and
places them. It does not redraw the person or the wordmark.
"""

from pathlib import Path
import shutil

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / "AppStore"
ICON_DIR = ART / "icon"
MODELS = ART / "models"
SHOTS = ART / "screenshots" / "1206x2622"
WEB = ART / "website"
APP_ICON = ROOT / "App" / "Assets.xcassets" / "AppIcon.appiconset"

SERIF = "/usr/share/fonts/truetype/liberation/LiberationSerif-Bold.ttf"
SANS = "/usr/share/fonts/truetype/macos/Inter-Regular.ttf"
SANS_MED = "/usr/share/fonts/truetype/macos/Inter-Medium.ttf"
SANS_SEMI = "/usr/share/fonts/truetype/macos/Inter-SemiBold.ttf"

PAPER = (243, 230, 220)
CARD = (255, 248, 243)
INK = (44, 20, 24)
MERLOT = (124, 36, 54)
MIST = (107, 70, 74)
LINE = (212, 181, 172)
WHITE = (255, 255, 255)
FRAME = (28, 28, 30)

CANVAS = (1206, 2622)
SCREEN = (700, 1360)
ICON_EDGES = (20, 29, 40, 58, 60, 76, 80, 87, 120, 152, 167, 180, 1024)

SOURCE_CANDIDATES = [
    Path("/workspace/beauty-assets/vermessa"),
    Path("/home/workdir/beauty-assets/vermessa"),
    ART / "incoming",
]


def font(path, size):
    return ImageFont.truetype(path, size)


def hex_rgb(value):
    value = value.lstrip("#")
    return tuple(int(value[i : i + 2], 16) for i in (0, 2, 4))


def luminance(rgb):
    return (0.2126 * rgb[0] + 0.7152 * rgb[1] + 0.0722 * rgb[2]) / 255


def ink_for(rgb):
    return WHITE if luminance(rgb) < 0.45 else INK


def find_sources():
    names = {
        "icon": "icon.jpg",
        "merlot": "hero-merlot.jpg",
        "nude": "nude-pink.jpg",
        "coral": "coral.jpg",
    }
    for folder in SOURCE_CANDIDATES:
        paths = {key: folder / filename for key, filename in names.items()}
        if all(path.exists() for path in paths.values()):
            return paths
    missing = ", ".join(str(SOURCE_CANDIDATES[0] / name) for name in names.values())
    raise SystemExit(f"Approved Vermessa portraits were not found. Expected {missing}")


def rgb_square(path):
    image = Image.open(path).convert("RGB")
    side = min(image.size)
    left = (image.width - side) // 2
    top = (image.height - side) // 2
    return image.crop((left, top, left + side, top + side))


def save_rgb_png(image, path):
    image = image.convert("RGB")
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, "PNG")
    check = Image.open(path)
    if check.mode != "RGB" or "A" in check.getbands():
        raise SystemExit(f"{path} is not opaque RGB")


def write_icons(icon_source):
    master = rgb_square(icon_source)
    ICON_DIR.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(icon_source, ICON_DIR / "vermessa-icon-source.jpg")
    icon_1024 = master.resize((1024, 1024), Image.Resampling.LANCZOS)
    save_rgb_png(icon_1024, ICON_DIR / "AppIcon-1024.png")
    save_rgb_png(icon_1024, APP_ICON / "icon-1024.png")
    for edge in ICON_EDGES:
        if edge == 1024:
            continue
        sized = master.resize((edge, edge), Image.Resampling.LANCZOS)
        save_rgb_png(sized, APP_ICON / f"icon-{edge}.png")
    save_rgb_png(master.resize((32, 32), Image.Resampling.LANCZOS), WEB / "favicon-32.png")
    save_rgb_png(master.resize((180, 180), Image.Resampling.LANCZOS), WEB / "apple-touch-icon.png")


def cover(image, size, anchor=(0.5, 0.36)):
    image = image.convert("RGB")
    scale = max(size[0] / image.width, size[1] / image.height)
    resized = image.resize((int(image.width * scale), int(image.height * scale)), Image.Resampling.LANCZOS)
    left = max(0, min(resized.width - size[0], int(resized.width * anchor[0] - size[0] / 2)))
    top = max(0, min(resized.height - size[1], int(resized.height * anchor[1] - size[1] / 2)))
    return resized.crop((left, top, left + size[0], top + size[1]))


def rounded_mask(size, radius):
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, size[0] - 1, size[1] - 1), radius=radius, fill=255)
    return mask


def paste_round(base, image, box, radius):
    image = image.convert("RGBA").resize((box[2] - box[0], box[3] - box[1]), Image.Resampling.LANCZOS)
    image.putalpha(rounded_mask(image.size, radius))
    base.paste(image, (box[0], box[1]), image)


def wrap(draw, text, face, width):
    lines = []
    current = ""
    for word in text.split():
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


def draw_lines(draw, text, face, xy, fill, width, gap=8):
    lines = wrap(draw, text, face, width)
    x, y = xy
    for line in lines:
        draw.text((x, y), line, font=face, fill=fill)
        y += face.size + gap
    return y


class Screen:
    def __init__(self):
        self.image = Image.new("RGB", SCREEN, PAPER)
        self.draw = ImageDraw.Draw(self.image)
        self.draw_status()

    def draw_status(self):
        self.draw.text((28, 18), "9:41", font=font(SANS_SEMI, 28), fill=INK)
        self.draw.rounded_rectangle((SCREEN[0] - 78, 24, SCREEN[0] - 28, 44), radius=6, outline=INK, width=2)
        self.draw.rectangle((SCREEN[0] - 70, 30, SCREEN[0] - 40, 38), fill=INK)
        self.draw.rectangle((SCREEN[0] - 26, 30, SCREEN[0] - 22, 38), fill=INK)

    def tabbar(self, active):
        top = SCREEN[1] - 118
        self.draw.rectangle((0, top, SCREEN[0], SCREEN[1]), fill=CARD)
        self.draw.line((0, top, SCREEN[0], top), fill=LINE, width=2)
        labels = ["Drawer", "Picks", "Worn", "Wish"]
        slot = SCREEN[0] // 4
        for index, label in enumerate(labels):
            color = MERLOT if label == active else MIST
            face = font(SANS_SEMI, 22)
            text_w = self.draw.textlength(label, font=face)
            x = index * slot + (slot - text_w) / 2
            self.draw.ellipse((x + text_w / 2 - 5, top + 16, x + text_w / 2 + 5, top + 26), fill=color)
            self.draw.text((x, top + 36), label, font=face, fill=color)
        self.draw.rounded_rectangle((SCREEN[0] / 2 - 70, SCREEN[1] - 18, SCREEN[0] / 2 + 70, SCREEN[1] - 8), radius=6, fill=(160, 140, 136))

    def chip(self, box, label, selected=False):
        fill = MERLOT if selected else CARD
        text = WHITE if selected else INK
        self.draw.rounded_rectangle(box, radius=22, fill=fill, outline=None if selected else LINE, width=2)
        face = font(SANS_SEMI, 22)
        tw = self.draw.textlength(label, font=face)
        self.draw.text((box[0] + (box[2] - box[0] - tw) / 2, box[1] + 12), label, font=face, fill=text)

    def card(self, box, shade, name, brand, finish):
        self.draw.rounded_rectangle(box, radius=26, fill=CARD)
        swatch = (box[0] + 14, box[1] + 14, box[2] - 14, box[1] + 150)
        self.draw.rounded_rectangle(swatch, radius=20, fill=shade)
        label_fill = ink_for(shade)
        plate = (255, 255, 255) if label_fill == INK else (70, 24, 32)
        self.draw.rounded_rectangle((swatch[0] + 12, swatch[3] - 50, swatch[0] + 12 + int(self.draw.textlength(finish, font=font(SANS_SEMI, 20))) + 28, swatch[3] - 12), radius=16, fill=plate)
        self.draw.text((swatch[0] + 24, swatch[3] - 44), finish, font=font(SANS_SEMI, 20), fill=label_fill)
        self.draw.text((box[0] + 16, box[1] + 162), name, font=font(SERIF, 28), fill=INK)
        self.draw.text((box[0] + 16, box[1] + 198), brand, font=font(SANS, 20), fill=MIST)


def screen_drawer(portrait):
    ui = Screen()
    hero = cover(portrait, (SCREEN[0] - 40, 430), (0.5, 0.42))
    paste_round(ui.image, hero, (20, 78, SCREEN[0] - 20, 508), 32)
    overlay = Image.new("RGBA", (SCREEN[0] - 40, 180), (0, 0, 0, 0))
    od = ImageDraw.Draw(overlay)
    for y in range(180):
        od.line((0, y, overlay.width, y), fill=(0, 0, 0, int(170 * y / 180)))
    ui.image.paste(overlay, (20, 328), overlay)
    ui.draw.text((40, 390), "The drawer", font=font(SERIF, 54), fill=WHITE)
    ui.draw.text((40, 452), "8 lipsticks at home", font=font(SANS, 26), fill=WHITE)
    ui.draw.rounded_rectangle((20, 528, SCREEN[0] - 20, 598), radius=20, fill=CARD)
    ui.draw.text((40, 546), "Search name, brand, or family", font=font(SANS, 26), fill=MIST)
    shades = [
        ("D0A088", "Bare Apricot", "Clayroom", "Sheer"),
        ("6E2436", "Cellar Merlot", "Orchard Lacquer", "Stain"),
    ]
    gap = 16
    width = (SCREEN[0] - 40 - gap) // 2
    for index, (shade, name, brand, finish) in enumerate(shades):
        left = 20 + index * (width + gap)
        ui.card((left, 620, left + width, 880), hex_rgb(shade), name, brand, finish)
    ui.tabbar("Drawer")
    return ui.image


def screen_detail(portrait):
    ui = Screen()
    shade = hex_rgb("6E2436")
    ui.draw.rounded_rectangle((20, 78, SCREEN[0] - 20, 300), radius=28, fill=shade)
    ui.draw.text((40, 150), "Cellar Merlot", font=font(SERIF, 48), fill=WHITE)
    ui.draw.text((40, 214), "Orchard Lacquer", font=font(SANS, 26), fill=(255, 230, 230))
    photo = cover(portrait, (SCREEN[0] - 40, 360), (0.5, 0.4))
    paste_round(ui.image, photo, (20, 320, SCREEN[0] - 20, 680), 28)
    ui.draw.text((24, 692), "Still shade card. No camera.", font=font(SANS, 22), fill=MIST)
    facts = [("Finish", "Stain"), ("Undertone", "Cool"), ("Color family", "Wine"), ("Occasions", "Date, Evening")]
    y = 736
    for title, value in facts:
        ui.draw.rounded_rectangle((20, y, SCREEN[0] - 20, y + 78), radius=18, fill=CARD)
        ui.draw.text((36, y + 8), title, font=font(SANS_SEMI, 20), fill=MIST)
        ui.draw.text((36, y + 34), value, font=font(SANS, 26), fill=INK)
        y += 90
    ui.draw.rounded_rectangle((20, y, SCREEN[0] - 20, y + 64), radius=18, fill=MERLOT)
    label = "Log as worn today"
    face = font(SANS_SEMI, 26)
    ui.draw.text(((SCREEN[0] - ui.draw.textlength(label, font=face)) / 2, y + 16), label, font=face, fill=WHITE)
    ui.tabbar("Drawer")
    return ui.image


def screen_filters(portrait):
    ui = Screen()
    hero = cover(portrait, (SCREEN[0] - 40, 280), (0.48, 0.38))
    paste_round(ui.image, hero, (20, 78, SCREEN[0] - 20, 358), 28)
    shade = Image.new("RGBA", (SCREEN[0] - 40, 120), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shade)
    for y in range(120):
        sd.line((0, y, shade.width, y), fill=(0, 0, 0, int(150 * y / 120)))
    ui.image.paste(shade, (20, 238), shade)
    ui.draw.text((40, 268), "The drawer", font=font(SERIF, 46), fill=WHITE)
    ui.draw.rounded_rectangle((20, 378, SCREEN[0] - 20, 446), radius=18, fill=CARD)
    ui.draw.text((40, 396), "Search name, brand, or family", font=font(SANS, 24), fill=MIST)
    ui.chip((20, 466, 150, 518), "Nude", selected=True)
    ui.draw.text((170, 478), "Clear", font=font(SANS_SEMI, 24), fill=MERLOT)
    ui.draw.text((24, 536), "2 matching lipsticks", font=font(SANS, 24), fill=MIST)
    shades = [
        ("D0A088", "Bare Apricot", "Clayroom", "Sheer"),
        ("C48984", "Dusty Blush", "Clayroom", "Satin"),
    ]
    gap = 16
    width = (SCREEN[0] - 40 - gap) // 2
    for index, (color, name, brand, finish) in enumerate(shades):
        left = 20 + index * (width + gap)
        ui.card((left, 590, left + width, 860), hex_rgb(color), name, brand, finish)
    ui.tabbar("Drawer")
    return ui.image


def screen_picks():
    ui = Screen()
    ui.draw.text((24, 78), "Picks", font=font(SERIF, 58), fill=INK)
    draw_lines(
        ui.draw,
        "Ranked from lipsticks you own. Quiet shades rise.",
        font(SANS, 26),
        (24, 150),
        MIST,
        SCREEN[0] - 48,
    )
    ui.draw.text((24, 230), "Occasion", font=font(SERIF, 32), fill=INK)
    ui.chip((24, 278, 130, 332), "Any")
    ui.chip((142, 278, 250, 332), "Date", selected=True)
    ui.chip((262, 278, 410, 332), "Evening")
    ui.draw.text((24, 354), "Undertone", font=font(SERIF, 32), fill=INK)
    ui.chip((24, 402, 130, 456), "Any")
    ui.chip((142, 402, 280, 456), "Warm", selected=True)
    ui.chip((292, 402, 420, 456), "Cool")
    rows = [
        ("E15A3C", "1", "Lantern Coral", "Fits date · Matches warm · Quiet for 16 days"),
        ("C4233A", "2", "Glass Cherry", "Fits date · Neutral can bridge warm · Quiet for 21 days"),
        ("6E2436", "3", "Cellar Merlot", "Fits date · Opposite undertone · Not worn yet"),
        ("C48984", "4", "Dusty Blush", "Another occasion · Matches warm · Not worn yet"),
    ]
    y = 480
    for shade, rank, name, reason in rows:
        ui.draw.rounded_rectangle((20, y, SCREEN[0] - 20, y + 168), radius=24, fill=CARD)
        ui.draw.rounded_rectangle((40, y + 24, 128, y + 112), radius=18, fill=hex_rgb(shade))
        ui.draw.text((72, y + 48), rank, font=font(SANS_SEMI, 28), fill=ink_for(hex_rgb(shade)))
        ui.draw.text((148, y + 22), name, font=font(SERIF, 32), fill=INK)
        draw_lines(ui.draw, reason, font(SANS, 22), (148, y + 68), MIST, SCREEN[0] - 190, gap=4)
        y += 184
    ui.tabbar("Picks")
    return ui.image


def screen_worn():
    ui = Screen()
    ui.draw.text((24, 78), "Worn", font=font(SERIF, 58), fill=INK)
    ui.draw.text((24, 152), "A short log of lip color.", font=font(SANS, 28), fill=MIST)
    ui.draw.rounded_rectangle((20, 210, SCREEN[0] - 20, 360), radius=24, fill=CARD)
    ui.draw.text((40, 230), "Today", font=font(SERIF, 36), fill=INK)
    ui.draw.text((40, 284), "Nothing logged for today.", font=font(SANS, 26), fill=MIST)
    ui.draw.rounded_rectangle((20, 384, SCREEN[0] - 20, 456), radius=18, fill=MERLOT)
    label = "Choose a lipstick for today"
    face = font(SANS_SEMI, 26)
    ui.draw.text(((SCREEN[0] - ui.draw.textlength(label, font=face)) / 2, 404), label, font=face, fill=WHITE)
    ui.draw.text((24, 484), "Earlier", font=font(SERIF, 36), fill=INK)
    rows = [
        ("B15C6C", "Yesterday", "Quiet Rose", "Satin"),
        ("D0A088", "November 10", "Bare Apricot", "Sheer"),
        ("A56B86", "November 5", "Mauve Hour", "Cream"),
        ("E15A3C", "October 28", "Lantern Coral", "Cream"),
    ]
    y = 540
    for shade, when, name, finish in rows:
        ui.draw.text((24, y), when, font=font(SERIF, 28), fill=INK)
        ui.draw.ellipse((24, y + 48, 68, y + 92), fill=hex_rgb(shade))
        ui.draw.text((84, y + 46), name, font=font(SANS_SEMI, 26), fill=INK)
        ui.draw.text((84, y + 80), finish, font=font(SANS, 22), fill=MIST)
        ui.draw.text((SCREEN[0] - 150, y + 58), "Remove", font=font(SANS_SEMI, 22), fill=MERLOT)
        y += 130
    ui.tabbar("Worn")
    return ui.image


def phone_bezel(screen):
    bezel = 18
    outer = (screen.width + bezel * 2, screen.height + bezel * 2)
    body = Image.new("RGBA", outer, (0, 0, 0, 0))
    ImageDraw.Draw(body).rounded_rectangle((0, 0, outer[0] - 1, outer[1] - 1), radius=62, fill=FRAME + (255,))
    screen_rgba = screen.convert("RGBA")
    screen_rgba.putalpha(rounded_mask(screen.size, 46))
    body.paste(screen_rgba, (bezel, bezel), screen_rgba)
    island = ImageDraw.Draw(body)
    island_w, island_h = 196, 58
    ix = (outer[0] - island_w) // 2
    iy = bezel + 14
    island.rounded_rectangle((ix, iy, ix + island_w, iy + island_h), radius=29, fill=(0, 0, 0, 255))
    return body


def compose(portrait, headline, subhead, screen, anchor):
    """Place the portrait across the top so the face stays clear of the phone."""
    portrait = portrait.convert("RGB")
    scale = CANVAS[0] / portrait.width
    resized = portrait.resize((CANVAS[0], max(1, int(portrait.height * scale))), Image.Resampling.LANCZOS)
    # If the scaled photo is shorter than the canvas, extend it with the lower edge color.
    if resized.height < CANVAS[1]:
        edge = resized.crop((0, resized.height - 4, resized.width, resized.height)).resize((CANVAS[0], 1))
        color = edge.getpixel((CANVAS[0] // 2, 0))
        canvas = Image.new("RGB", CANVAS, color)
        canvas.paste(resized, (0, 0))
    else:
        # Bias the crop toward the face (upper portion) using the anchor.
        top = int((resized.height - CANVAS[1]) * anchor[1])
        top = max(0, min(resized.height - CANVAS[1], top))
        canvas = resized.crop((0, top, CANVAS[0], top + CANVAS[1]))
    canvas = canvas.convert("RGBA")
    device = phone_bezel(screen)
    phone_top = CANVAS[1] - device.height - 28
    # Copy stays above the phone so a line cannot slip out beside the bezel.
    band_top = max(0, phone_top - 320)
    scrim = Image.new("RGBA", CANVAS, (0, 0, 0, 0))
    sd = ImageDraw.Draw(scrim)
    for y in range(band_top, phone_top):
        span = max(1, phone_top - band_top)
        alpha = int(210 * (y - band_top) / span)
        sd.line((0, y, CANVAS[0], y), fill=(28, 10, 14, min(230, alpha)))
    canvas = Image.alpha_composite(canvas, scrim)
    text_layer = Image.new("RGBA", CANVAS, (0, 0, 0, 0))
    draw = ImageDraw.Draw(text_layer)
    text_bottom = draw_lines(draw, headline, font(SERIF, 58), (56, band_top + 18), WHITE, CANVAS[0] - 112, gap=4)
    draw_lines(draw, subhead, font(SANS, 30), (56, text_bottom + 12), (255, 236, 230), CANVAS[0] - 112, gap=6)
    text_layer = text_layer.crop((0, 0, CANVAS[0], phone_top))
    canvas.paste(text_layer, (0, 0), text_layer)
    shadow = Image.new("RGBA", device.size, (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle((0, 0, device.width - 1, device.height - 1), radius=62, fill=(0, 0, 0, 120))
    shadow = shadow.filter(ImageFilter.GaussianBlur(16))
    x = (CANVAS[0] - device.width) // 2
    canvas.paste(shadow, (x, phone_top + 14), shadow)
    canvas.paste(device, (x, phone_top), device)
    return canvas.convert("RGB")


def main():
    sources = find_sources()
    write_icons(sources["icon"])
    MODELS.mkdir(parents=True, exist_ok=True)
    portraits = {}
    for key, filename in (("merlot", "hero-merlot.jpg"), ("nude", "nude-pink.jpg"), ("coral", "coral.jpg")):
        destination = MODELS / filename
        shutil.copyfile(sources[key], destination)
        portraits[key] = Image.open(destination).convert("RGB")
    sets = {
        "merlot": ROOT / "App" / "Assets.xcassets" / "PortraitMerlot.imageset" / "portrait.jpg",
        "nude": ROOT / "App" / "Assets.xcassets" / "PortraitNude.imageset" / "portrait.jpg",
        "coral": ROOT / "App" / "Assets.xcassets" / "PortraitCoral.imageset" / "portrait.jpg",
    }
    for key, path in sets.items():
        portraits[key].save(path, "JPEG", quality=92)

    scenes = [
        ("01-drawer.png", portraits["merlot"], "Your lipsticks, kept in one drawer.", "Finish, undertone, and occasion, from the colors you already own.", screen_drawer(portraits["merlot"]), (0.5, 0.34)),
        ("02-shade-card.png", portraits["merlot"], "A card for every shade you own.", "Name, brand, finish, and the exact color. A tube photo is optional.", screen_detail(portraits["merlot"]), (0.52, 0.30)),
        ("03-filters.png", portraits["nude"], "Find a nude, a matte, a Friday shade.", "Filter the drawer by finish, undertone, color family, or occasion.", screen_filters(portraits["nude"]), (0.48, 0.33)),
        ("04-picks.png", portraits["coral"], "Suggestions from your own tubes.", "Ranked for the occasion, the undertone, and how long the shade has been quiet.", screen_picks(), (0.5, 0.32)),
        ("05-worn-today.png", portraits["coral"], "What did you wear today?", "A short history of lip color. Not a makeup diary — just the shade.", screen_worn(), (0.46, 0.36)),
    ]
    if SHOTS.exists():
        for old in SHOTS.glob("*"):
            old.unlink()
    SHOTS.mkdir(parents=True, exist_ok=True)
    # Remove any other screenshot size folders if a previous run created them.
    extra_root = ART / "screenshots"
    for child in extra_root.iterdir():
        if child.is_dir() and child.name != "1206x2622":
            shutil.rmtree(child)
    for filename, portrait, headline, subhead, screen, anchor in scenes:
        image = compose(portrait, headline, subhead, screen, anchor)
        if image.size != CANVAS:
            raise SystemExit(f"{filename} is {image.size}, expected {CANVAS}")
        path = SHOTS / filename
        image.save(path, "PNG")
        print(path, image.size, image.mode)
    pngs = sorted(SHOTS.glob("*.png"))
    if len(pngs) != 5:
        raise SystemExit(f"expected 5 screenshots, found {len(pngs)}")


if __name__ == "__main__":
    main()
