"""Six ending illustrations, 1920x1080 each, one per ending id.

Each piece gets a distinct composition + hero silhouette so it reads at
thumbnail size:
  wake_them      -- dawn light, cryo pods opening, warm horizon, crowd silhouettes
  let_them_sleep -- dark quiet bay, pods glowing softly, ARIA alone, dim stars
  merge          -- two cores entwined into one hybrid ring, dual-color spiral
  wake_but_leave -- shuttle departing, station shrinking behind, hard trail
  station_wins   -- dead pods, red failure lights, broken ARIA fragments
  the_loop       -- circular corridor of repeated ARIA silhouettes, reset glow
"""
import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import (PAL, arr, grain, lerp, mix, radial_glow, rng_for,  # noqa: E402
                    save, stars, to_img, v_gradient, vignette)

W, H = 1920, 1080


# --------------------------------------------------------------- helpers ---

def pod(dr, x, y, w, h, glow, outline, fill=(10, 22, 40, 255), tilt=0.0):
    """A cryo pod: rounded capsule with inner occupant silhouette + glow."""
    dr.rounded_rectangle([x, y, x + w, y + h], radius=w * 0.35,
                         fill=fill, outline=outline, width=4)
    # occupant: simple head+body silhouette
    cx = x + w / 2
    hr = w * 0.16
    cy = y + h * 0.38
    dr.ellipse([cx - hr, cy - hr, cx + hr, cy + hr],
               fill=(mix((6, 12, 24), glow, 0.35)) + (255,))
    dr.polygon([(cx - hr * 1.7, y + h * 0.82), (cx + hr * 1.7, y + h * 0.82),
                (cx + hr * 1.1, y + h * 0.52), (cx - hr * 1.1, y + h * 0.52)],
               fill=(mix((6, 12, 24), glow, 0.25)) + (255,))
    # status lamp
    lr = w * 0.06
    ly = y + h * 0.12
    dr.ellipse([cx - lr, ly - lr, cx + lr, ly + lr], fill=glow + (255,))


def figure(dr, x, y, h, color, glow_eye=None):
    """Small humanoid silhouette (head + torso + legs), height h, at (x, y)=feet."""
    hw = h * 0.16
    dr.ellipse([x - hw, y - h, x + hw, y - h + 2 * hw], fill=color + (255,))
    dr.polygon([(x - hw * 1.5, y), (x + hw * 1.5, y),
                (x + hw * 1.2, y - h * 0.55), (x - hw * 1.2, y - h * 0.55)],
               fill=color + (255,))
    if glow_eye:
        dr.point((x, y - h * 0.88), fill=glow_eye + (255,))


def aria_bot(dr, cx, cy, s, eye, shell=(20, 46, 76)):
    """ARIA silhouette: hex head + single eye + body, scale s = head radius."""
    pts = []
    for i in range(6):
        a = math.pi / 6 + i * math.pi / 3
        pts.append((cx + s * 1.15 * math.cos(a), cy + s * 1.3 * math.sin(a)))
    dr.polygon(pts, fill=shell + (255,), outline=PAL["cyan"][:3] + (255,))
    er = s * 0.45
    dr.ellipse([cx - er, cy - er, cx + er, cy + er], fill=(8, 18, 34, 255),
               outline=eye + (255,))
    pr = s * 0.18
    dr.ellipse([cx - pr, cy - pr, cx + pr, cy + pr], fill=eye + (255,))
    # body
    dr.rounded_rectangle([cx - s * 0.8, cy + s * 1.4, cx + s * 0.8, cy + s * 2.4],
                         radius=s * 0.2, fill=shell + (255,),
                         outline=PAL["teal"][:3] + (220,))


def base_sky(seed, top, bottom, n_stars=200, horizon=0.72):
    a = arr(W, H)
    v_gradient(a, top, bottom)
    r = rng_for("sky", seed)
    stars(a, r, n=n_stars, bright=150)
    return a, r


def floor_grid(dr, y0, color, alpha=120, step=90, rows=8):
    for i in range(rows):
        y = y0 + i * step * (1 + i * 0.18)
        if y > H:
            break
        dr.line([(0, y), (W, y)], fill=color + (alpha,), width=2)


# ---------------------------------------------------------------- pieces ---

def wake_them():
    a, r = base_sky("wake", (30, 52, 96), (150, 96, 60), n_stars=140, horizon=0.6)
    # warm dawn glow low on horizon
    radial_glow(a, W * 0.5, H * 0.62, W * 0.42, PAL["amber"], 0.85, 2.4)
    radial_glow(a, W * 0.5, H * 0.62, W * 0.16, PAL["white"], 0.5, 2.0)
    img = to_img(a).convert("RGBA")
    dr = ImageDraw.Draw(img)
    # horizon deck line
    dr.line([(0, H * 0.62), (W, H * 0.62)], fill=PAL["orange"][:3] + (200,), width=4)
    floor_grid(dr, H * 0.66, PAL["orange_dim"], 90)
    # open pods row (lids tilted = opened)
    for i in range(5):
        x = W * 0.10 + i * W * 0.19
        pod(dr, x, H * 0.40, W * 0.075, H * 0.20, PAL["amber"], PAL["ice"][:3])
    # crowd of waking crew silhouettes
    for i in range(14):
        x = r.uniform(W * 0.06, W * 0.94)
        y = r.uniform(H * 0.70, H * 0.94)
        figure(dr, x, y, r.uniform(H * 0.07, H * 0.12), (14, 26, 44))
    # ARIA watching from right, eye bright
    aria_bot(dr, W * 0.86, H * 0.52, H * 0.055, PAL["cyan"])
    vignette(a)
    return Image.alpha_composite(to_img(a).convert("RGBA"), img)


def let_them_sleep():
    a, r = base_sky("sleep", (5, 10, 24), (12, 26, 48), n_stars=260)
    radial_glow(a, W * 0.5, H * 0.5, W * 0.30, PAL["deep"], 0.5, 2.0)
    img = to_img(a).convert("RGBA")
    dr = ImageDraw.Draw(img)
    # two calm rows of sleeping pods, soft teal glow
    for row, y in ((0, H * 0.30), (1, H * 0.58)):
        for i in range(6):
            x = W * 0.06 + i * W * 0.155 + row * W * 0.04
            pod(dr, x, y, W * 0.07, H * 0.17, PAL["teal"], PAL["grey_blue"])
    # dimmed lights: small fading dots above
    for i in range(8):
        x = W * 0.1 + i * W * 0.12
        rr = 4 + i % 3
        dr.ellipse([x - rr, H * 0.12 - rr, x + rr, H * 0.12 + rr],
                   fill=PAL["navy"] + (180,))
    # ARIA small, alone, center foreground, eye dimmed
    aria_bot(dr, W * 0.5, H * 0.80, H * 0.045, PAL["grey_blue"])
    vignette(a, 0.7)
    return Image.alpha_composite(to_img(a).convert("RGBA"), img)


def merge():
    a, r = base_sky("merge", (8, 14, 34), (20, 40, 70), n_stars=180)
    radial_glow(a, W * 0.5, H * 0.5, W * 0.36, PAL["teal"], 0.8, 2.2)
    radial_glow(a, W * 0.5, H * 0.5, W * 0.20, PAL["amber"], 0.5, 2.2)
    img = to_img(a).convert("RGBA")
    dr = ImageDraw.Draw(img)
    cx, cy = W * 0.5, H * 0.48
    # entwined double helix rings: teal + amber strands
    for k in range(2):
        col = (PAL["cyan"] if k == 0 else PAL["amber"])
        pts = []
        for t in range(0, 360, 4):
            ang = math.radians(t)
            rr = W * 0.30 * (0.55 + 0.45 * math.sin(ang))
            x = cx + rr * math.cos(ang + k * math.pi)
            y = cy + rr * 0.62 * math.sin(ang + k * math.pi)
            pts.append((x, y))
        dr.line(pts, fill=col[:3] + (230,), width=8)
    # merged core: hexagon inside circle, dual eye
    R = H * 0.16
    dr.ellipse([cx - R, cy - R * 0.8, cx + R, cy + R * 0.8],
               fill=(10, 22, 42, 255), outline=PAL["ice"][:3] + (255,), width=6)
    hexpts = []
    for i in range(6):
        ang = math.pi / 6 + i * math.pi / 3
        hexpts.append((cx + R * 0.62 * math.cos(ang), cy + R * 0.5 * math.sin(ang)))
    dr.polygon(hexpts, outline=PAL["orange"][:3] + (255,), width=5)
    for sgn, col in ((-1, PAL["cyan"]), (1, PAL["amber"])):
        ex = cx + sgn * R * 0.22
        dr.ellipse([ex - 16, cy - 16, ex + 16, cy + 16], fill=col[:3] + (255,))
    # departing-station streaks
    for _ in range(10):
        x0 = r.uniform(0, W); y0 = r.uniform(0, H)
        ln = r.uniform(60, 200)
        dr.line([(x0, y0), (x0 + ln, y0 - ln * 0.2)],
                fill=PAL["grey_blue"] + (90,), width=2)
    vignette(a)
    return Image.alpha_composite(to_img(a).convert("RGBA"), img)


def wake_but_leave():
    a, r = base_sky("leave", (10, 16, 36), (26, 34, 58), n_stars=220)
    radial_glow(a, W * 0.72, H * 0.42, W * 0.24, PAL["orange"], 0.55, 2.2)
    img = to_img(a).convert("RGBA")
    dr = ImageDraw.Draw(img)
    # Erebus-7 shrinking to a bright point, upper right
    sx, sy = W * 0.72, H * 0.42
    dr.ellipse([sx - 46, sy - 46, sx + 46, sy + 46], outline=PAL["red"][:3] + (200,), width=4)
    dr.ellipse([sx - 20, sy - 20, sx + 20, sy + 20], outline=PAL["orange"][:3] + (230,), width=3)
    dr.ellipse([sx - 7, sy - 7, sx + 7, sy + 7], fill=PAL["white"] + (255,))
    # shuttle: arrow wedge lower-left, engine trail to the right
    bx, by = W * 0.30, H * 0.66
    dr.polygon([(bx - W*0.10, by + H*0.06), (bx + W*0.06, by + H*0.02),
                (bx + W*0.10, by), (bx + W*0.06, by - H*0.02),
                (bx - W*0.10, by - H*0.06)], fill=(18, 34, 56, 255),
               outline=PAL["cyan"][:3] + (255,))
    dr.ellipse([bx - W*0.045, by - 10, bx - W*0.045 + 20, by + 10],
               fill=PAL["cyan"][:3] + (255,))
    # engine trail: fading dashes
    for i in range(16):
        x0 = bx - W * 0.10 - i * 26
        al = max(20, 220 - i * 14)
        dr.line([(x0, by), (x0 - 18, by)],
                fill=mix(PAL["orange"], PAL["red"], i / 16) + (al,), width=8 - i // 4)
    # crew silhouettes inside shuttle window glow
    dr.rounded_rectangle([bx + W*0.005, by - 14, bx + W*0.045, by + 14],
                         radius=6, fill=PAL["amber"] + (220,))
    vignette(a)
    return Image.alpha_composite(to_img(a).convert("RGBA"), img)


def station_wins():
    a, r = base_sky("wins", (8, 6, 14), (30, 12, 14), n_stars=120)
    radial_glow(a, W * 0.5, H * 0.45, W * 0.34, PAL["red"], 0.6, 2.4)
    img = to_img(a).convert("RGBA")
    dr = ImageDraw.Draw(img)
    # row of dark failed pods, red X lamps
    for i in range(6):
        x = W * 0.07 + i * W * 0.15
        pod(dr, x, H * 0.30, W * 0.075, H * 0.19, PAL["red"], (60, 30, 34))
        cx, cy = x + W * 0.0375, H * 0.30 + H * 0.095
        rr = 7
        dr.line([(cx - rr, cy - rr), (cx + rr, cy + rr)], fill=PAL["red"][:3] + (255,), width=3)
        dr.line([(cx - rr, cy + rr), (cx + rr, cy - rr)], fill=PAL["red"][:3] + (255,), width=3)
    # broken ARIA fragments scattered on floor
    for _ in range(9):
        x = r.uniform(W * 0.15, W * 0.85)
        y = r.uniform(H * 0.68, H * 0.92)
        s = r.uniform(8, 26)
        pts = [(x + s * math.cos(a0), y + s * 0.6 * math.sin(a0))
               for a0 in [r.uniform(0, 6.28) for _ in range(4)]]
        dr.polygon(pts, fill=(16, 30, 48, 255), outline=PAL["grey_blue"] + (200,))
    # looming station core eye, upper half, hostile red
    cx, cy = W * 0.5, H * 0.16
    dr.ellipse([cx - 150, cy - 90, cx + 150, cy + 90],
               outline=PAL["red"][:3] + (230,), width=6)
    dr.ellipse([cx - 60, cy - 36, cx + 60, cy + 36],
               fill=(20, 8, 10, 255), outline=PAL["orange"][:3] + (255,), width=4)
    dr.ellipse([cx - 18, cy - 11, cx + 18, cy + 11], fill=PAL["red"][:3] + (255,))
    vignette(a, 0.7)
    return Image.alpha_composite(to_img(a).convert("RGBA"), img)


def the_loop():
    a, r = base_sky("loop", (6, 12, 26), (14, 28, 52), n_stars=160)
    radial_glow(a, W * 0.5, H * 0.5, W * 0.30, PAL["blue"], 0.6, 2.2)
    img = to_img(a).convert("RGBA")
    dr = ImageDraw.Draw(img)
    cx, cy = W * 0.5, H * 0.5
    # circular corridor: concentric rings with tick marks
    for i in range(5):
        rr = W * (0.10 + i * 0.075)
        dr.ellipse([cx - rr, cy - rr * 0.9, cx + rr, cy + rr * 0.9],
                   outline=PAL["teal"][:3] + (150 - i * 20,), width=3)
    # repeated ARIA silhouettes around the ring (reset cycle)
    n = 10
    for i in range(n):
        ang = 2 * math.pi * i / n
        rr = W * 0.245
        x = cx + rr * math.cos(ang)
        y = cy + rr * 0.9 * math.sin(ang)
        s = 14 + 10 * math.sin(ang)  # pseudo-depth
        aria_bot(dr, x, y, s, PAL["cyan"] if i % 3 else PAL["ice"])
    # central reset glyph: circular arrow
    R = W * 0.06
    dr.arc([cx - R, cy - R, cx + R, cy + R], 30, 300,
           fill=PAL["orange"][:3] + (255,), width=10)
    ax, ay = cx + R * math.cos(math.radians(30)), cy + R * math.sin(math.radians(30))
    dr.polygon([(ax - 16, ay - 6), (ax + 12, ay), (ax - 8, ay + 18)],
               fill=PAL["orange"][:3] + (255,))
    vignette(a)
    return Image.alpha_composite(to_img(a).convert("RGBA"), img)


GENS = {
    "wake_them": wake_them,
    "let_them_sleep": let_them_sleep,
    "merge": merge,
    "wake_but_leave": wake_but_leave,
    "station_wins": station_wins,
    "the_loop": the_loop,
}

if __name__ == "__main__":
    import sys as _s
    names = _s.argv[1:] or list(GENS)
    for name in names:
        img = GENS[name]()
        save(img, f"assets/art/endings/ending_{name}.png")
