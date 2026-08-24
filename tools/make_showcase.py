#!/usr/bin/env python3
"""Generate v2.0.0 art showcase collages from actual game assets.
Output: docs/screenshots/showcase_{banner,portraits,endings,backgrounds}.png
These are ART SHOWCASES (collages of real assets), not in-game screenshots."""
import os
from PIL import Image, ImageDraw, ImageFont, ImageOps

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))  # repo root
ART = os.path.join(ROOT, "LAST_SIGNAL", "assets")
OUT = os.path.join(ROOT, "docs", "screenshots")
os.makedirs(OUT, exist_ok=True)

def font(size):
    for p in ("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
              "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"):
        if os.path.exists(p):
            return ImageFont.truetype(p, size)
    return ImageFont.load_default()

def load(path, box_w, box_h):
    im = Image.open(path).convert("RGB")
    im = ImageOps.contain(im, (box_w, box_h))
    return im

def label(draw, xy, text, size=18, fill=(0, 229, 255)):
    draw.text(xy, text, font=font(size), fill=fill)

BG = (8, 10, 16)
ACCENT = (0, 229, 255)

# ---------- Banner 1280x480 ----------
W, H = 1280, 480
banner = Image.new("RGB", (W, H), BG)
key = load(os.path.join(ART, "art", "keyart_menu.png"), 620, H)
banner.paste(key, (W - key.width, (H - key.height) // 2))
d = ImageDraw.Draw(banner)
lockup_path = os.path.join(ART, "art", "title_lockup.png")
if os.path.exists(lockup_path):
    lk = load(lockup_path, 560, 200)
    banner.paste(lk, (40, 60))
else:
    d.text((40, 80), "LAST SIGNAL", font=font(72), fill=ACCENT)
label(d, (44, 300), "2.0.0  \u2022  DIRECTOR'S CUT", 30)
label(d, (44, 350), "Art showcase \u2014 collage of actual game assets.", 16, (170, 180, 195))
label(d, (44, 375), "Not an in-game screenshot.", 16, (170, 180, 195))
banner.save(os.path.join(OUT, "showcase_banner.png"))

# ---------- Grid helper ----------
def grid(images_with_captions, cols, cell_w, cell_h, title, out_name):
    n = len(images_with_captions)
    rows = (n + cols - 1) // cols
    pad, cap_h, head_h = 12, 26, 56
    Wc = cols * cell_w + (cols + 1) * pad
    Hc = head_h + rows * (cell_h + cap_h + pad) + pad
    sheet = Image.new("RGB", (Wc, Hc), BG)
    d = ImageDraw.Draw(sheet)
    d.text((pad, 14), title, font=font(28), fill=ACCENT)
    d.text((Wc - 320 * len(title) // len(title) - 260, 24), "", font=font(12))
    note_x = pad + d.textlength(title, font=font(28)) + 20
    if note_x < Wc - 340:
        d.text((note_x, 24), "(art showcase \u2014 not a screenshot)", font=font(14), fill=(140, 150, 165))
    f_cap = font(14)
    for i, (path, cap) in enumerate(images_with_captions):
        r, c = divmod(i, cols)
        x = pad + c * (cell_w + pad)
        y = head_h + r * (cell_h + cap_h + pad)
        im = load(path, cell_w, cell_h)
        ox = x + (cell_w - im.width) // 2
        oy = y + (cell_h - im.height) // 2
        sheet.paste(im, (ox, oy))
        d.rectangle([x, y, x + cell_w, y + cell_h], outline=(40, 50, 70), width=1)
        d.text((x + 4, y + cell_h + 6), cap, font=f_cap, fill=(190, 198, 210))
    sheet.save(os.path.join(OUT, out_name))
    print("wrote", out_name, sheet.size)

portraits = [
    ("portraits/aria7_neutral.png",     "ARIA-7 \u2014 Neutral"),
    ("portraits/aria7_alert.png",       "ARIA-7 \u2014 Alert"),
    ("portraits/aria7_distressed.png",  "ARIA-7 \u2014 Distressed"),
    ("art/erebus7_placated.png",        "Erebus-7 \u2014 Placated"),
    ("art/erebus7_cold.png",            "Erebus-7 \u2014 Cold"),
    ("art/erebus7_hostile.png",         "Erebus-7 \u2014 Hostile"),
]
grid([(os.path.join(ART, p), c) for p, c in portraits], 3, 360, 360,
     "Character Portraits", "showcase_portraits.png")

endings = [
    ("endings/ending_wake_them.png",      "Wake Them"),
    ("endings/ending_let_them_sleep.png", "Let Them Sleep"),
    ("endings/ending_merge.png",          "Merge"),
    ("endings/ending_station_wins.png",   "The Station Wins"),
    ("endings/ending_the_loop.png",       "The Loop"),
    ("endings/ending_wake_but_leave.png", "Wake But Leave"),
]
grid([(os.path.join(ART, "art", p), c) for p, c in endings], 3, 360, 270,
     "Ending Illustrations", "showcase_endings.png")

bgs = [
    ("backgrounds/bg_bridge.png",           "Bridge"),
    ("backgrounds/bg_corridor.png",         "Corridor"),
    ("backgrounds/bg_cryobay.png",          "Cryobay"),
    ("backgrounds/bg_engineering.png",      "Engineering"),
    ("backgrounds/bg_medical.png",          "Medical"),
    ("backgrounds/bg_observation_deck.png", "Observation Deck"),
    ("backgrounds/bg_reactor.png",          "Reactor"),
    ("backgrounds/bg_void.png",             "The Void"),
]
grid([(os.path.join(ART, p), c) for p, c in bgs], 4, 300, 225,
     "Station Backgrounds", "showcase_backgrounds.png")

print("done")
