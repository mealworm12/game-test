"""Shared procedural-art toolkit for LAST SIGNAL v2 art package.

House style: ASCII only. Deterministic: every generator seeds its RNG.
Palette: deep-space blues/teals + signal-orange accent, CRT-friendly contrast.
"""
import math
import os
import random

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ASSETS = os.path.join(ROOT, "LAST_SIGNAL", "assets")

# ---------------------------------------------------------------- palette ---
PAL = {
    "void":        (4, 8, 18),
    "deep":        (8, 22, 44),
    "navy":        (12, 38, 72),
    "blue":        (24, 78, 128),
    "teal":        (32, 144, 160),
    "cyan":        (88, 214, 224),
    "ice":         (168, 226, 238),
    "white":       (232, 244, 250),
    "orange":      (255, 140, 26),   # signal-orange accent
    "orange_dim":  (168, 84, 16),
    "amber":       (255, 198, 92),
    "red":         (224, 58, 48),
    "green":       (86, 210, 120),
    "grey_blue":   (70, 96, 122),
    "panel":       (14, 30, 52),
}


def rng_for(*parts):
    """Deterministic RNG from string parts."""
    return random.Random("|".join(str(p) for p in parts))


def arr(w, h):
    return np.zeros((h, w, 3), dtype=np.float64)


def lerp(a, b, t):
    return a + (b - a) * t


def mix(c1, c2, t):
    return tuple(int(lerp(c1[i], c2[i], t)) for i in range(3))


def to_img(a, alpha=None):
    a = np.clip(a, 0, 255).astype(np.uint8)
    if alpha is not None:
        al = np.clip(alpha * 255.0, 0, 255).astype(np.uint8)
        rgba = np.dstack([a, al])
        return Image.fromarray(rgba, "RGBA")
    return Image.fromarray(a, "RGB")


# ------------------------------------------------------------- primitives ---

def v_gradient(a, top, bottom, y0=0.0, y1=1.0):
    h = a.shape[0]
    ys = np.linspace(0, 1, h)
    t = np.clip((ys - y0) / max(y1 - y0, 1e-6), 0, 1)[:, None, None]
    top = np.array(top, dtype=float)[None, None, :]
    bot = np.array(bottom, dtype=float)[None, None, :]
    a += t * bot + (1 - t) * top


def radial_glow(a, cx, cy, radius, color, strength=1.0, falloff=2.2):
    h, w = a.shape[:2]
    yy, xx = np.mgrid[0:h, 0:w]
    d = np.sqrt((xx - cx) ** 2 + (yy - cy) ** 2) / max(radius, 1.0)
    g = np.exp(-(d ** falloff)) * strength
    col = np.array(color, dtype=float)[None, None, :]
    # additive-ish blend toward color
    a += (col - a) * g[..., None]


def stars(a, r, n=220, seed_extra="", bright=200, big_chance=0.04):
    h, w = a.shape[:2]
    for _ in range(n):
        x = r.randint(0, w - 1)
        y = r.randint(0, h - 1)
        b = r.uniform(40, bright)
        c = mix(PAL["ice"], PAL["white"], r.random())
        col = tuple(min(255, int(b * ch / max(c, (1, 1, 1))[0] + b)) for ch in c)
        if r.random() < big_chance:
            rr = r.choice([1, 1, 2])
            a[max(0, y - rr):y + rr + 1, max(0, x - rr):x + rr + 1] = np.maximum(
                a[max(0, y - rr):y + rr + 1, max(0, x - rr):x + rr + 1],
                np.array(col, float))
        else:
            a[y, x] = np.array(col, float)


def scanlines(img, strength=0.06, period=3):
    """CRT scanline overlay on a PIL image."""
    w, h = img.size
    ov = Image.new("L", (w, h), 255)
    dr = ImageDraw.Draw(ov)
    for y in range(0, h, period):
        dr.line([(0, y), (w, y)], fill=int(255 * (1 - strength)))
    out = img.copy().convert("RGBA")
    dark = Image.new("RGBA", (w, h), (0, 0, 0, 255))
    out = Image.composite(out, Image.alpha_composite(out, dark), ov)
    return out.convert("RGB")


def vignette(a, strength=0.55, power=2.0):
    h, w = a.shape[:2]
    yy, xx = np.mgrid[0:h, 0:w]
    d = np.sqrt(((xx - w / 2) / (w / 2)) ** 2 + ((yy - h / 2) / (h / 2)) ** 2) / math.sqrt(2)
    v = 1 - strength * d[:, :, None] ** power
    a *= v


def grain(a, r, amount=3.0):
    n = np.array([r.uniform(-amount, amount) for _ in range(0)])
    noise = np.random.default_rng(r.randint(0, 2 ** 31)).normal(0, amount, a.shape[:2])
    a += noise[:, :, None]


def hbars(a, rows, color_fn, x0f=0.0, x1f=1.0, jitter=0.0, seed=None):
    """Stack of horizontal structural bands (station strata)."""
    h, w = a.shape[:2]
    r = seed or rng_for("hbars")
    y = int(h * 0.05)
    step = h // (rows + 1)
    while y < h * 0.95:
        bh = int(step * r.uniform(0.35, 0.9))
        x0 = int(w * x0f + r.uniform(0, w * jitter))
        x1 = int(w * x1f - r.uniform(0, w * jitter))
        c = color_fn(r)
        a[y:y + bh, x0:x1] = np.array(c, float)
        y += bh + int(step * r.uniform(0.15, 0.5))


def pil_layer(size):
    return Image.new("RGBA", size, (0, 0, 0, 0))


def draw_polygon_glow(base_draw_img, pts, fill, outline=None, width=2):
    dr = ImageDraw.Draw(base_draw_img)
    dr.polygon(pts, fill=fill, outline=outline, width=width)


def blur_rgba(img, rad):
    return img.filter(ImageFilter.GaussianBlur(rad))


def font_for(px):
    """Best-effort monospace TTF; fall back to default bitmap font."""
    candidates = [
        "/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf",
        "/usr/share/fonts/truetype/liberation/LiberationMono-Bold.ttf",
    ]
    for p in candidates:
        if os.path.exists(p):
            try:
                return ImageFont.truetype(p, px)
            except OSError:
                pass
    return ImageFont.load_default()


def text_size(txt, fnt):
    tmp = Image.new("RGB", (8, 8))
    d = ImageDraw.Draw(tmp)
    box = d.textbbox((0, 0), txt, font=fnt)
    return box[2] - box[0], box[3] - box[1]


def save(img, relpath):
    path = os.path.join(ROOT, "LAST_SIGNAL", relpath)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path, "PNG")
    print("saved", relpath, img.size, img.mode)
