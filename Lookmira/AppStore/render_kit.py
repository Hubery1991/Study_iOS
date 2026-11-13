#!/usr/bin/env python3
"""Build the Lookmira icon set and the five 1206×2622 App Store screenshots."""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[1]
INCOMING = ROOT / "AppStore" / "incoming"
MODELS = ROOT / "AppStore" / "models"
SAMPLES = ROOT / "App" / "SamplePhotos"
ICON_DIR = ROOT / "AppStore" / "icon"
APPICON = ROOT / "App" / "Assets.xcassets" / "AppIcon.appiconset"
SHOTS = ROOT / "AppStore" / "screenshots" / "1206x2622"
WEB = ROOT / "AppStore" / "website"

SERIF = "/usr/share/fonts/truetype/liberation/LiberationSerif-Bold.ttf"
SERIF_REG = "/usr/share/fonts/truetype/liberation/LiberationSerif-Regular.ttf"
SANS = "/usr/share/fonts/truetype/macos/Inter-Regular.ttf"
SANS_MED = "/usr/share/fonts/truetype/macos/Inter-Medium.ttf"
SANS_SEMI = "/usr/share/fonts/truetype/macos/Inter-SemiBold.ttf"

IVORY = (247, 241, 234)
PAPER = (255, 252, 248)
INK = (42, 33, 28)
SOFT = (92, 81, 72)
PEACH = (201, 106, 85)
DEEP = (163, 75, 60)
BLUSH = (243, 224, 214)
LINE = (230, 220, 210)
WHITE = (255, 255, 255)

W, H = 1206, 2622
SCREEN_W, SCREEN_H = 900, 1956


def font(path, size):
    return ImageFont.truetype(path, size)


def cover(path, w, h, bias=0.42):
    im = Image.open(path).convert("RGB")
    scale = max(w / im.width, h / im.height)
    nw, nh = int(im.width * scale + 0.5), int(im.height * scale + 0.5)
    im = im.resize((nw, nh), Image.Resampling.LANCZOS)
    left = max(0, (nw - w) // 2)
    top = max(0, int((nh - h) * bias))
    return im.crop((left, top, left + w, top + h))


def rounded_mask(size, radius):
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, size[0] - 1, size[1] - 1), radius=radius, fill=255)
    return mask


def paste_round(base, im, xy, radius):
    im = im.convert("RGB")
    mask = rounded_mask(im.size, radius)
    base.paste(im, xy, mask)


def text_w(draw, text, fnt):
    return draw.textlength(text, font=fnt)


def wrap(draw, text, fnt, max_w):
    lines, cur = [], ""
    for word in text.split():
        trial = word if not cur else f"{cur} {word}"
        if text_w(draw, trial, fnt) <= max_w:
            cur = trial
        else:
            if cur:
                lines.append(cur)
            cur = word
    if cur:
        lines.append(cur)
    return lines


def center_text(draw, text, y, fnt, fill, width=W):
    draw.text(((width - text_w(draw, text, fnt)) / 2, y), text, font=fnt, fill=fill)


def pill(draw, xy, fill, outline=None):
    draw.rounded_rectangle(xy, radius=999, fill=fill, outline=outline)


def make_icons(icon_path):
    """Scale the approved full-bleed icon. The word Lookmira is already in the artwork."""
    ICON_DIR.mkdir(parents=True, exist_ok=True)
    APPICON.mkdir(parents=True, exist_ok=True)
    plate = Image.open(icon_path).convert("RGB")
    if plate.size != (1024, 1024):
        plate = plate.resize((1024, 1024), Image.Resampling.LANCZOS)
    plate = plate.convert("RGB")
    assert plate.mode == "RGB" and plate.getbands() == ("R", "G", "B")
    kit = ICON_DIR / "AppIcon-1024.png"
    plate.save(kit, "PNG")
    (APPICON / "icon-1024.png").write_bytes(kit.read_bytes())
    slots = [20, 29, 40, 58, 60, 76, 80, 87, 120, 152, 167, 180, 1024]
    for px in slots:
        slot = plate.resize((px, px), Image.Resampling.LANCZOS).convert("RGB")
        assert slot.mode == "RGB"
        slot.save(APPICON / f"icon-{px}.png", "PNG")
    WEB.mkdir(parents=True, exist_ok=True)
    plate.resize((180, 180), Image.Resampling.LANCZOS).convert("RGB").save(WEB / "apple-touch-icon.png", "PNG")
    plate.resize((32, 32), Image.Resampling.LANCZOS).convert("RGB").save(WEB / "favicon-32.png", "PNG")
    plate.resize((192, 192), Image.Resampling.LANCZOS).convert("RGB").save(WEB / "icon-192.png", "PNG")
    reopened = Image.open(kit)
    assert reopened.size == (1024, 1024) and reopened.mode == "RGB"


def phone(screen):
    bezel = 22
    outer_w, outer_h = SCREEN_W + bezel * 2, SCREEN_H + bezel * 2
    canvas = Image.new("RGBA", (outer_w + 80, outer_h + 80), (0, 0, 0, 0))
    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rounded_rectangle((40, 48, 40 + outer_w, 48 + outer_h), radius=78, fill=(42, 33, 28, 70))
    shadow = shadow.filter(ImageFilter.GaussianBlur(18))
    canvas = Image.alpha_composite(canvas, shadow)
    body = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    bd = ImageDraw.Draw(body)
    bd.rounded_rectangle((40, 36, 40 + outer_w, 36 + outer_h), radius=76, fill=(28, 28, 30, 255))
    bd.rounded_rectangle((40 + 6, 42, 34 + outer_w, 30 + outer_h), radius=70, fill=(58, 58, 62, 255))
    screen_box = (40 + bezel, 36 + bezel)
    mask = rounded_mask((SCREEN_W, SCREEN_H), 58)
    framed = screen.convert("RGBA")
    body.paste(framed, screen_box, mask)
    # Dynamic Island sits on the glass.
    ix, iy = screen_box
    island_w, island_h = 250, 74
    island = (ix + (SCREEN_W - island_w) / 2, iy + 22, ix + (SCREEN_W + island_w) / 2, iy + 22 + island_h)
    ImageDraw.Draw(body).rounded_rectangle(island, radius=40, fill=(0, 0, 0, 255))
    canvas = Image.alpha_composite(canvas, body)
    return canvas


def status(draw):
    fnt = font(SANS_SEMI, 34)
    draw.text((46, 40), "9:41", font=fnt, fill=INK)
    # battery
    draw.rounded_rectangle((800, 46, 860, 72), radius=6, outline=INK, width=3)
    draw.rectangle((862, 54, 866, 64), fill=INK)
    draw.rounded_rectangle((804, 50, 844, 68), radius=3, fill=INK)


def chip(draw, text, x, y, selected=False, size=30):
    fnt = font(SANS_SEMI, size)
    pad_x, h = 18, size + 28
    w = text_w(draw, text, fnt) + pad_x * 2
    fill = DEEP if selected else BLUSH
    color = WHITE if selected else INK
    pill(draw, (x, y, x + w, y + h), fill)
    draw.text((x + pad_x, y + 12), text, font=fnt, fill=color)
    return w


def card(screen, photo, title, date, tags, summary, box):
    x, y, w, h = box
    layer = Image.new("RGB", (w, h), PAPER)
    d = ImageDraw.Draw(layer)
    photo_h = int(h * 0.62)
    layer.paste(cover(photo, w, photo_h), (0, 0))
    d.text((24, photo_h + 16), title, font=font(SERIF, 40), fill=INK)
    d.text((24, photo_h + 66), date, font=font(SANS, 28), fill=SOFT)
    cx = 24
    for tag in tags:
        cx += chip(d, tag, cx, photo_h + 112) + 10
    d.text((24, photo_h + 186), summary, font=font(SANS, 28), fill=INK)
    paste_round(screen, layer, (x, y), 36)


def diary_screen(photo, selected, title, date, tags, summary):
    screen = Image.new("RGB", (SCREEN_W, SCREEN_H), IVORY)
    d = ImageDraw.Draw(screen)
    status(d)
    d.text((40, 130), "Diary", font=font(SERIF, 64), fill=INK)
    d.text((392, 146), "November 2026", font=font(SERIF, 40), fill=INK)
    days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    for i, name in enumerate(days):
        d.text((48 + i * 122, 230), name, font=font(SANS_SEMI, 26), fill=SOFT)
    marks = {7, 10, 13}
    for n in range(1, 31):
        col = (n - 1) % 7
        row = (n - 1) // 7
        cx = 62 + col * 122
        cy = 290 + row * 78
        if n == selected:
            d.ellipse((cx - 28, cy - 8, cx + 28, cy + 48), fill=DEEP)
            color = WHITE
        else:
            color = INK
        label = str(n)
        d.text((cx - text_w(d, label, font(SANS_SEMI, 32)) / 2, cy), label, font=font(SANS_SEMI, 32), fill=color)
        if n in marks and n != selected:
            d.ellipse((cx - 5, cy + 46, cx + 5, cy + 56), fill=PEACH)
    d.text((40, 760), date, font=font(SERIF, 40), fill=INK)
    card(screen, photo, title, date, tags, summary, (40, 830, 820, 1040))
    return screen


def detail_screen(photo, title, date, tags, products, notes, favorite=True):
    screen = Image.new("RGB", (SCREEN_W, SCREEN_H), IVORY)
    d = ImageDraw.Draw(screen)
    status(d)
    screen.paste(cover(photo, 820, 860), (40, 140))
    mask = rounded_mask((820, 860), 40)
    # re-paste with rounded corners
    base = Image.new("RGB", (SCREEN_W, SCREEN_H), IVORY)
    base.paste(screen, (0, 0))
    photo_im = cover(photo, 820, 860)
    base.paste(Image.new("RGB", (820, 860), IVORY), (40, 140))
    paste_round(base, photo_im, (40, 140), 40)
    d = ImageDraw.Draw(base)
    status(d)
    d.text((40, 1024), title, font=font(SERIF, 58), fill=INK)
    d.text((40, 1104), date, font=font(SANS, 32), fill=SOFT)
    cx = 40
    for tag in tags:
        cx += chip(d, tag, cx, 1164) + 12
    heart = "Favorite" if favorite else "Mark as favorite"
    d.text((40, 1250), heart, font=font(SANS_SEMI, 32), fill=DEEP)
    d.text((40, 1324), "Products used", font=font(SERIF, 40), fill=INK)
    y = 1390
    for kind, name in products:
        d.rounded_rectangle((40, y, 860, y + 96), radius=18, fill=PAPER, outline=LINE)
        d.text((60, y + 12), kind, font=font(SANS, 26), fill=SOFT)
        d.text((60, y + 46), name, font=font(SANS_SEMI, 32), fill=INK)
        y += 110
    if notes:
        d.text((40, y + 6), notes, font=font(SANS, 30), fill=INK)
        y += 80
    d.rounded_rectangle((40, 1800, 860, 1884), radius=22, fill=DEEP)
    label = "Recreate this look"
    fnt = font(SANS_SEMI, 34)
    d.text(((SCREEN_W - text_w(d, label, fnt)) / 2, 1824), label, font=fnt, fill=WHITE)
    return base


def products_screen(photo):
    screen = Image.new("RGB", (SCREEN_W, SCREEN_H), IVORY)
    d = ImageDraw.Draw(screen)
    status(d)
    d.text((40, 130), "Edit look", font=font(SERIF, 56), fill=INK)
    photo_im = cover(photo, 820, 560)
    paste_round(screen, photo_im, (40, 220), 36)
    d = ImageDraw.Draw(screen)
    d.text((40, 800), "Choose a photo", font=font(SANS_SEMI, 32), fill=DEEP)
    d.text((40, 860), "Office berry", font=font(SERIF, 52), fill=INK)
    d.text((40, 940), "Worn on  Tuesday, November 10", font=font(SANS, 30), fill=SOFT)
    d.text((40, 1010), "Style", font=font(SERIF, 36), fill=INK)
    chip(d, "Work", 40, 1070, selected=True)
    d.text((40, 1160), "Products used", font=font(SERIF, 36), fill=INK)
    rows = [
        ("Lipstick", "Berry silk"),
        ("Eyeshadow", "Taupe wash"),
        ("Brow", "Soft blonde pencil"),
        ("Foundation", "Light ivory veil"),
        ("Liner", "Fine brown"),
    ]
    y = 1224
    for kind, name in rows:
        d.rounded_rectangle((40, y, 860, y + 100), radius=18, fill=PAPER, outline=LINE)
        d.text((60, y + 30), kind, font=font(SANS_SEMI, 28), fill=DEEP)
        d.text((280, y + 28), name, font=font(SANS, 32), fill=INK)
        y += 114
    d.rounded_rectangle((40, 1820, 860, 1904), radius=22, fill=DEEP)
    label = "Save changes"
    fnt = font(SANS_SEMI, 34)
    d.text(((SCREEN_W - text_w(d, label, fnt)) / 2, 1844), label, font=fnt, fill=WHITE)
    return screen


def search_screen(photo):
    screen = Image.new("RGB", (SCREEN_W, SCREEN_H), IVORY)
    d = ImageDraw.Draw(screen)
    status(d)
    d.text((40, 130), "Looks", font=font(SERIF, 64), fill=INK)
    d.rounded_rectangle((40, 230, 860, 320), radius=22, fill=PAPER, outline=LINE)
    d.text((64, 254), "rose", font=font(SANS, 36), fill=INK)
    cx = 36
    for name, on in (
        ("All", False),
        ("Natural", False),
        ("Work", False),
        ("Evening", True),
        ("Weekend", False),
        ("Party", False),
    ):
        cx += chip(d, name, cx, 348, selected=on, size=26) + 8
    d.text((40, 440), "1 look", font=font(SANS_SEMI, 30), fill=SOFT)
    card(
        screen,
        photo,
        "Rose after dark",
        "Saturday, November 7",
        ["Evening", "Party"],
        "Rose velvet, Smoked plum, Black wing, +2",
        (40, 500, 820, 1180),
    )
    d = ImageDraw.Draw(screen)
    d.rounded_rectangle((40, 1740, 860, 1824), radius=22, fill=DEEP)
    label = "Recreate this look"
    fnt = font(SANS_SEMI, 34)
    d.text(((SCREEN_W - text_w(d, label, fnt)) / 2, 1764), label, font=fnt, fill=WHITE)
    return screen


def marketing(headline, sub):
    canvas = Image.new("RGB", (W, H), IVORY)
    d = ImageDraw.Draw(canvas)
    d.rectangle((0, 0, W, 18), fill=DEEP)
    d.text((72, 64), "LOOKMIRA", font=font(SANS_SEMI, 30), fill=DEEP)
    head = font(SERIF, 78)
    lines = wrap(d, headline, head, W - 144)
    y = 120
    for line in lines:
        d.text((72, y), line, font=head, fill=INK)
        y += 92
    y += 8
    sub_font = font(SANS, 36)
    for line in wrap(d, sub, sub_font, W - 144):
        d.text((72, y), line, font=sub_font, fill=SOFT)
        y += 48
    return canvas, y + 28


def compose(screen, headline, sub, out):
    canvas, top = marketing(headline, sub)
    device = phone(screen)
    # Fit the device under the copy, centered, without clipping.
    max_h = H - top - 48
    scale = min(1.0, max_h / device.height, (W - 40) / device.width)
    if scale != 1:
        device = device.resize((int(device.width * scale), int(device.height * scale)), Image.Resampling.LANCZOS)
    x = (W - device.width) // 2
    y = top + max(0, (H - top - 36 - device.height) // 2)
    canvas.paste(device, (x, y), device)
    assert canvas.size == (W, H)
    canvas.save(out, "PNG")
    check = Image.open(out)
    assert check.size == (W, H), check.size


def main():
    icon = INCOMING / "icon.jpg"
    everyday = INCOMING / "hero-everyday.jpg"
    evening = INCOMING / "evening.jpg"
    work = INCOMING / "work.jpg"
    for path in (icon, everyday, evening, work):
        if not path.exists():
            raise SystemExit(f"missing approved artwork {path}")
    MODELS.mkdir(parents=True, exist_ok=True)
    SAMPLES.mkdir(parents=True, exist_ok=True)
    # Keep the approved JPEG bytes. Do not re-encode or substitute another face.
    (MODELS / "everyday.jpg").write_bytes(everyday.read_bytes())
    (MODELS / "evening.jpg").write_bytes(evening.read_bytes())
    (MODELS / "work.jpg").write_bytes(work.read_bytes())
    (SAMPLES / "sample-everyday.jpg").write_bytes(everyday.read_bytes())
    (SAMPLES / "sample-evening.jpg").write_bytes(evening.read_bytes())
    (SAMPLES / "sample-work.jpg").write_bytes(work.read_bytes())
    make_icons(icon)
    SHOTS.mkdir(parents=True, exist_ok=True)
    # Remove anything that is not one of the five final shots.
    for old in SHOTS.glob("*"):
        if old.is_file():
            old.unlink()
    compose(
        diary_screen(
            everyday, 13, "Soft peach morning", "Friday, November 13",
            ["Natural", "Weekend"], "Peach coral satin, Light ivory veil, Warm apricot cream, +1",
        ),
        "Write the look down.",
        "A photo, the products, and the day you wore it.",
        SHOTS / "01-diary.png",
    )
    compose(
        diary_screen(
            work, 10, "Office berry", "Tuesday, November 10",
            ["Work"], "Berry silk, Taupe wash, Soft blonde pencil, +2",
        ),
        "The month, at a glance.",
        "Every finished look sits on the day you wore it.",
        SHOTS / "02-calendar.png",
    )
    compose(
        detail_screen(
            evening,
            "Rose after dark",
            "Saturday, November 7",
            ["Evening", "Party"],
            [("Lipstick", "Rose velvet"), ("Eyeshadow", "Smoked plum"), ("Liner", "Black wing")],
            "Dinner lighting. This is the rose lipstick to repeat.",
        ),
        "Wear it again.",
        "Favorite a look, then recreate it on a new day.",
        SHOTS / "03-evening.png",
    )
    compose(
        products_screen(work),
        "The products, listed.",
        "Lipstick, shadow, liner, and brow, beside the photo.",
        SHOTS / "04-products.png",
    )
    compose(
        search_screen(evening),
        "Find it later.",
        "Search a style tag or the name of a product.",
        SHOTS / "05-search.png",
    )
    shots = sorted(SHOTS.glob("*.png"))
    assert len(shots) == 5, [p.name for p in shots]
    print("screenshots", [p.name for p in shots])


if __name__ == "__main__":
    main()
