"""ARIA-7 portrait set: neutral / alert / distressed. 512x512 RGBA.

Design: a friendly station-AI avatar -- a luminous core "eye" (iris rings +
pupil aperture) inside a faceted head shell, with antennae and cheek status
lights. Mood changes: eye shape, ring color mix, tilt, glow intensity, crack
overlays for distress. Transparent background.
"""
import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import PAL, mix, rng_for, save, font_for  # noqa: E402

S = 640  # supersample; downscale to 512 for AA
OUT = S // 1


def shell_points(cx, cy, rx, ry, facets, rot=0.0):
    pts = []
    for i in range(facets):
        ang = rot + i * 2 * math.pi / facets
        rr = 0.86 + 0.14 * math.sin(i * 2.7)
        pts.append((cx + rx * rr * math.cos(ang), cy + ry * rr * math.sin(ang)))
    return pts


def mood_params(mood, r):
    if mood == "neutral":
        return dict(eye_h=1.0, iris=PAL["cyan"], accent=PAL["teal"], glow=0.9,
                    tilt=-0.04, brow=8, crack=False, scan=PAL["teal"])
    if mood == "alert":
        return dict(eye_h=1.18, iris=PAL["ice"], accent=PAL["orange"], glow=1.35,
                    tilt=0.05, brow=-10, crack=False, scan=PAL["orange"])
    # distressed
    return dict(eye_h=0.62, iris=PAL["amber"], accent=PAL["red"], glow=0.7,
                tilt=0.12, brow=-22, crack=True, scan=PAL["red"])


def gen(mood, seed="aria-7"):
    r = rng_for(seed, mood)
    p = mood_params(mood, r)
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    cx, cy = S * 0.5, S * 0.52

    # --- glow halo behind head
    halo = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    hd = ImageDraw.Draw(halo)
    hd.ellipse([cx - S*0.42, cy - S*0.42, cx + S*0.42, cy + S*0.42],
               fill=p["accent"][:3] + (70,))
    halo = halo.filter(ImageFilter.GaussianBlur(S * 0.09))
    img = Image.alpha_composite(img, halo)

    # --- head shell (faceted hexagonal helmet)
    body = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    bd = ImageDraw.Draw(body)
    head = shell_points(cx, cy, S * 0.30, S * 0.34, 6, rot=math.pi / 6 + p["tilt"])
    bd.polygon(head, fill=(16, 40, 68, 255), outline=p["accent"][:3] + (255,), width=7)
    # facet shading: inner polygon darker/lighter wedges
    for i in range(6):
        j = (i + 1) % 6
        mid = ((head[i][0] + head[j][0]) / 2, (head[i][1] + head[j][1]) / 2)
        wedge = [mid, head[i], (cx, cy)]
        shade = 26 + i * 4
        bd.polygon(wedge, fill=(shade + 12, shade + 28, shade + 52, 110))
    # chin / neck column
    bd.polygon([(cx - S*0.075, cy + S*0.30), (cx + S*0.075, cy + S*0.30),
                (cx + S*0.06, cy + S*0.42), (cx - S*0.06, cy + S*0.42)],
               fill=(12, 30, 54, 255), outline=p["accent"][:3] + (200,), width=4)
    # shoulder base
    bd.rounded_rectangle([cx - S*0.24, cy + S*0.40, cx + S*0.24, cy + S*0.50],
                         radius=S*0.03, fill=(14, 34, 60, 255),
                         outline=p["accent"][:3] + (220,), width=5)
    # chest light bar
    bd.rounded_rectangle([cx - S*0.13, cy + S*0.43, cx + S*0.13, cy + S*0.455],
                         radius=S*0.008, fill=p["scan"][:3] + (235,))
    # antennae
    for sgn in (-1, 1):
        ax = cx + sgn * S * 0.20
        bd.line([(ax, cy - S*0.24), (ax + sgn*S*0.05, cy - S*0.36)],
                fill=p["accent"][:3] + (230,), width=6)
        tipr = S * (0.016 if mood != "alert" else 0.022)
        bd.ellipse([ax + sgn*S*0.05 - tipr, cy - S*0.36 - tipr,
                    ax + sgn*S*0.05 + tipr, cy - S*0.36 + tipr],
                   fill=p["iris"][:3] + (255,))
    img = Image.alpha_composite(img, body)

    # --- visor band
    visor = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    vd = ImageDraw.Draw(visor)
    vy0, vy1 = cy - S*0.115*p["eye_h"]**0.3 - S*0.02, cy + S*0.115*p["eye_h"]**0.3 + S*0.02
    vd.rounded_rectangle([cx - S*0.245, vy0, cx + S*0.245, vy1],
                         radius=S*0.03, fill=(6, 14, 28, 235),
                         outline=p["accent"][:3] + (255,), width=5)
    img = Image.alpha_composite(img, visor)

    # --- the eye: concentric iris rings + aperture pupil
    eye = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ed = ImageDraw.Draw(eye)
    erx, ery = S*0.085, S*0.085*p["eye_h"]
    # outer glow ring
    ed.ellipse([cx-erx*1.5, cy-ery*1.5, cx+erx*1.5, cy+ery*1.5],
               outline=p["iris"][:3] + (120,), width=max(2, int(S*0.012)))
    ed.ellipse([cx-erx, cy-ery, cx+erx, cy+ery],
               fill=(10, 26, 46, 255), outline=p["iris"][:3] + (255,), width=6)
    for k, col in [(0.72, p["accent"]), (0.55, p["iris"]), (0.40, PAL["ice"])]:
        ed.ellipse([cx-erx*k, cy-ery*k, cx+erx*k, cy+ery*k],
                   outline=col[:3] + (230,), width=max(2, int(S*0.010)))
    # pupil aperture
    pr = 0.16 * (1.15 if mood == "alert" else 1.0)
    ed.ellipse([cx-erx*pr, cy-ery*pr, cx+erx*pr, cy+ery*pr],
               fill=PAL["white"][:3] + (255,))
    # radial spokes inside iris
    for i in range(12):
        ang = i * math.pi / 6 + p["tilt"]
        x0 = cx + erx*0.44*math.cos(ang); y0 = cy + ery*0.44*math.sin(ang)
        x1 = cx + erx*0.66*math.cos(ang); y1 = cy + ery*0.66*math.sin(ang)
        ed.line([(x0, y0), (x1, y1)], fill=p["iris"][:3] + (180,), width=3)
    img = Image.alpha_composite(img, eye)

    # --- brow plates (mood cue above visor)
    brows = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    brd = ImageDraw.Draw(brows)
    by = cy - S*0.155 - S*0.01
    for sgn in (-1, 1):
        bx = cx + sgn * S * 0.11
        dy = p["brow"] * S / 640.0
        brd.line([(bx - sgn*S*0.07, by + dy*sgn*-1),
                  (bx + sgn*S*0.07, by - dy*sgn*-1)],
                 fill=p["accent"][:3] + (240,), width=9)
    img = Image.alpha_composite(img, brows)

    # --- distress cracks + flicker pixels
    if p["crack"]:
        cr = Image.new("RGBA", (S, S), (0, 0, 0, 0))
        cd = ImageDraw.Draw(cr)
        for _ in range(7):
            x = r.uniform(cx - S*0.26, cx + S*0.26)
            y = r.uniform(cy - S*0.30, cy + S*0.30)
            pts = [(x, y)]
            for seg in range(r.randint(3, 5)):
                x += r.uniform(-S*0.06, S*0.06)
                y += r.uniform(-S*0.05, S*0.05)
                pts.append((x, y))
            cd.line(pts, fill=(210, 236, 246, 170), width=2)
        img = Image.alpha_composite(img, cr)

    out = img.resize((512, 512), Image.LANCZOS)
    save(out, f"assets/portraits/aria7_{mood}.png")


if __name__ == "__main__":
    for m in ("neutral", "alert", "distressed"):
        gen(m)
