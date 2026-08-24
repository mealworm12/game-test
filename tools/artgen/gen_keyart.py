"""Key art + chapter backgrounds for LAST SIGNAL.

Outputs:
  assets/art/keyart_menu.png        1920x1080 main-menu key art
  assets/art/title_lockup.png       transparent title lockup PNG
  assets/backgrounds/bg_observation_deck.png  1280x720 chapter bg
  assets/backgrounds/bg_reactor.png           1280x720 chapter bg
  assets/art/menu_backdrop.png      subtle dark menu backdrop variant
"""
import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import (PAL, arr, font_for, mix, radial_glow, rng_for, save,  # noqa: E402
                    stars, text_size, to_img, v_gradient, vignette)

W, H = 1920, 1080
BW, BH = 1280, 720


def station_hull(dr, cx, cy, R, ring_col, spoke_col, alpha=255):
    """Side-view station: central spindle + two torus rings + solar arrays."""
    # spindle
    dr.line([(cx - R * 0.9, cy), (cx + R * 0.9, cy)], fill=ring_col + (alpha,), width=10)
    # core sphere
    dr.ellipse([cx - R * 0.22, cy - R * 0.22, cx + R * 0.22, cy + R * 0.22],
               fill=(16, 34, 58, alpha), outline=ring_col + (alpha,), width=5)
    # torus rings (perspective ellipses)
    for k in (-1, 1):
        rx = R * 0.55
        ry = R * 0.16
        x = cx + k * R * 0.45
        dr.ellipse([x - rx, cy - ry, x + rx, cy + ry],
                   outline=ring_col + (alpha,), width=7)
    # solar panel wings
    for sgn in (-1, 1):
        px = cx + sgn * (R * 0.62)
        dr.polygon([(px, cy - R*0.05), (px + sgn*R*0.30, cy - R*0.10),
                    (px + sgn*R*0.30, cy + R*0.10), (px, cy + R*0.05)],
                   fill=(12, 28, 50, alpha), outline=PAL["teal"] + (alpha,))
        for i in range(1, 4):
            xx = px + sgn * R * 0.30 * i / 4
            dr.line([(px, cy - R*0.05 + R*0.10*i/4), (px + sgn*R*0.30, cy - R*0.05 + R*0.10*i/4)],
                    fill=PAL["teal"] + (120,))


# ------------------------------------------------------------ key art ------

def keyart_menu():
    a = arr(W, H)
    v_gradient(a, (6, 12, 28), (16, 40, 72), 0.0, 0.85)
    r = rng_for("keyart")
    stars(a, r, n=340, bright=190, big_chance=0.06)
    # distant nebula washes
    radial_glow(a, W * 0.22, H * 0.30, W * 0.30, PAL["navy"], 0.55, 2.4)
    radial_glow(a, W * 0.78, H * 0.62, W * 0.26, PAL["teal"], 0.35, 2.6)
    radial_glow(a, W * 0.62, H * 0.34, W * 0.10, PAL["orange"], 0.30, 2.4)
    img = to_img(a).convert("RGBA")
    dr = ImageDraw.Draw(img)
    # hero station, right of center, large
    station_hull(dr, W * 0.66, H * 0.44, H * 0.34, PAL["cyan"], PAL["teal"])
    # signal beam from station toward lower-left (the "last signal")
    beam = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    bd = ImageDraw.Draw(beam)
    bd.polygon([(W*0.60, H*0.46), (W*0.63, H*0.42), (W*0.10, H*0.86), (W*0.06, H*0.80)],
               fill=PAL["orange"] + (110,))
    beam = beam.filter(ImageFilter.GaussianBlur(6))
    img = Image.alpha_composite(img, beam)
    dr = ImageDraw.Draw(img)
    # tiny ARIA eye at beam origin, foreground lower-left
    cx, cy = W * 0.085, H * 0.84
    s = H * 0.045
    pts = [(cx + s * 1.15 * math.cos(math.pi/6 + i*math.pi/3),
            cy + s * 1.3 * math.sin(math.pi/6 + i*math.pi/3)) for i in range(6)]
    dr.polygon(pts, fill=(18, 42, 70, 255), outline=PAL["cyan"] + (255,))
    er = s * 0.45
    dr.ellipse([cx - er, cy - er, cx + er, cy + er], fill=(8, 18, 34, 255),
               outline=PAL["cyan"] + (255,))
    pr = s * 0.18
    dr.ellipse([cx - pr, cy - pr, cx + pr, cy + pr], fill=PAL["white"] + (255,))
    vignette(a, 0.5)
    return Image.alpha_composite(to_img(a).convert("RGBA"), img)


def title_lockup():
    img = Image.new("RGBA", (1600, 420), (0, 0, 0, 0))
    dr = ImageDraw.Draw(img)
    title = "LAST SIGNAL"
    f_big = font_for(150)
    f_sub = font_for(40)
    # letter-spaced title
    spacing = 14
    total = 0
    widths = []
    for ch in title:
        wch = text_size(ch, f_big)[0]
        widths.append(wch)
        total += wch + spacing
    x = (1600 - total) // 2
    for i, ch in enumerate(title):
        # subtle vertical gradient on glyphs via double draw
        dr.text((x, 90), ch, font=f_big, fill=(90, 200, 214, 255))
        dr.text((x, 84), ch, font=f_big, fill=(232, 244, 250, 255))
        x += widths[i] + spacing
    # underline with orange accent segment
    tw = total - spacing
    dr.line([(x - tw, 268), (x - spacing, 268)], fill=(90, 200, 214, 220), width=5)
    dr.line([(x - tw, 268), (x - tw + tw * 0.22, 268)], fill=PAL["orange"] + (255,), width=5)
    sub = "A DEEP-SPACE VISUAL NOVEL"
    wsub = text_size(sub, f_sub)[0]
    dr.text(((1600 - wsub) // 2, 292), sub, font=f_sub, fill=(150, 200, 216, 235))
    return img


# --------------------------------------------------------- backgrounds ----

def bg_observation_deck():
    a = arr(BW, BH)
    v_gradient(a, (5, 10, 24), (14, 34, 60), 0.0, 0.7)
    r = rng_for("obsdeck")
    stars(a, r, n=300, bright=200, big_chance=0.08)
    radial_glow(a, BW * 0.70, BH * 0.30, BW * 0.22, PAL["navy"], 0.6, 2.4)
    img = to_img(a).convert("RGBA")
    dr = ImageDraw.Draw(img)
    # huge panoramic window frame: slanted mullions over the starfield
    for i in range(6):
        x = BW * (0.08 + i * 0.17)
        dr.line([(x, BH * 0.06), (x + BW*0.05, BH * 0.62)],
                fill=(40, 70, 100, 255), width=10)
    dr.line([(0, BH * 0.62), (BW, BH * 0.50)], fill=(46, 78, 110, 255), width=12)
    dr.line([(0, BH * 0.055), (BW, BH * 0.045)], fill=(46, 78, 110, 255), width=10)
    # deck floor with reflective panels
    dr.rectangle([0, BH * 0.62, BW, BH], fill=(10, 22, 40, 255))
    for i in range(7):
        y = BH * 0.62 + i * BH * 0.055
        dr.line([(0, y), (BW, y)], fill=PAL["navy"] + (160,), width=2)
    # observation consoles silhouettes
    for x in (BW*0.12, BW*0.5, BW*0.86):
        dr.rounded_rectangle([x - 60, BH*0.50, x + 60, BH*0.62], radius=8,
                             fill=(16, 34, 58, 255), outline=PAL["teal"] + (220,), width=3)
        dr.ellipse([x - 12, BH*0.545, x + 12, BH*0.569], fill=PAL["orange"] + (255,))
    # distant station through window
    station_hull(dr, BW * 0.72, BH * 0.28, BH * 0.14, PAL["ice"], PAL["teal"], alpha=230)
    vignette(a, 0.45)
    return Image.alpha_composite(to_img(a).convert("RGBA"), img)


def bg_reactor():
    a = arr(BW, BH)
    v_gradient(a, (10, 8, 14), (26, 20, 30), 0.0, 0.8)
    r = rng_for("reactor")
    radial_glow(a, BW * 0.5, BH * 0.42, BW * 0.30, PAL["orange_dim"], 0.7, 2.2)
    radial_glow(a, BW * 0.5, BH * 0.42, BW * 0.12, PAL["orange"], 0.5, 2.0)
    img = to_img(a).convert("RGBA")
    dr = ImageDraw.Draw(img)
    cx, cy = BW * 0.5, BH * 0.42
    # containment rings
    for i in range(4):
        rr = BW * (0.08 + i * 0.055)
        dr.ellipse([cx - rr, cy - rr, cx + rr, cy + rr],
                   outline=PAL["amber"] + (200 - i * 30,), width=5 - i)
    # core
    dr.ellipse([cx - 34, cy - 34, cx + 34, cy + 34], fill=PAL["white"] + (255,),
               outline=PAL["orange"] + (255,), width=4)
    # support struts to floor corners
    for sx in (0.0, 1.0):
        dr.line([(cx, cy), (BW * sx, BH * 0.78)], fill=(60, 50, 44, 255), width=14)
    # catwalk floor
    dr.rectangle([0, BH * 0.78, BW, BH], fill=(14, 14, 20, 255))
    dr.line([(0, BH * 0.78), (BW, BH * 0.78)], fill=PAL["orange_dim"] + (200,), width=4)
    for i in range(10):
        x = i * BW / 10
        dr.line([(x, BH * 0.78), (x, BH)], fill=(30, 28, 34, 255), width=4)
    # warning stanchions
    for x in (BW*0.2, BW*0.8):
        dr.rectangle([x - 8, BH * 0.60, x + 8, BH * 0.78], fill=(40, 36, 40, 255))
        dr.ellipse([x - 10, BH * 0.585, x + 10, BH * 0.605], fill=PAL["orange"] + (255,))
    # steam wisps
    wisps = Image.new("RGBA", (BW, BH), (0, 0, 0, 0))
    wd = ImageDraw.Draw(wisps)
    for _ in range(14):
        x = r.uniform(BW*0.3, BW*0.7); y = r.uniform(BH*0.2, BH*0.6)
        rr = r.uniform(10, 30)
        wd.ellipse([x-rr, y-rr, x+rr, y+rr], fill=(200, 180, 160, 26))
    wisps = wisps.filter(ImageFilter.GaussianBlur(12))
    img = Image.alpha_composite(img, wisps)
    vignette(a, 0.55)
    return Image.alpha_composite(to_img(a).convert("RGBA"), img)


def menu_backdrop():
    """Subtle, dark, low-contrast backdrop for menus (text must stay readable)."""
    a = arr(BW, BH)
    v_gradient(a, (7, 13, 26), (10, 22, 40), 0.0, 1.0)
    r = rng_for("menubd")
    stars(a, r, n=140, bright=90)
    radial_glow(a, BW * 0.5, BH * 0.55, BW * 0.4, PAL["deep"], 0.4, 2.0)
    img = to_img(a).convert("RGBA")
    dr = ImageDraw.Draw(img)
    # faint grid
    for x in range(0, BW, 64):
        dr.line([(x, 0), (x, BH)], fill=(20, 40, 66, 60), width=1)
    for y in range(0, BH, 64):
        dr.line([(0, y), (BW, y)], fill=(20, 40, 66, 60), width=1)
    # very faint station ghost upper-right
    ghost = Image.new("RGBA", (BW, BH), (0, 0, 0, 0))
    station_hull(ImageDraw.Draw(ghost), BW * 0.78, BH * 0.24, BH * 0.12,
                 PAL["teal"], PAL["teal"], alpha=60)
    ghost = ghost.filter(ImageFilter.GaussianBlur(2))
    img = Image.alpha_composite(img, ghost)
    return img


if __name__ == "__main__":
    save(keyart_menu(), "assets/art/keyart_menu.png")
    save(title_lockup(), "assets/art/title_lockup.png")
    save(bg_observation_deck(), "assets/backgrounds/bg_observation_deck.png")
    save(bg_reactor(), "assets/backgrounds/bg_reactor.png")
    save(menu_backdrop(), "assets/art/menu_backdrop.png")
