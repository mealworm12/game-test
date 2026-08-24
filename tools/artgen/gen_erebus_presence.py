"""Erebus-7 station-core presence visuals: cold / hostile / placated. 1024x1024 RGBA.

Abstract geometric station-core imagery: a massive concentric reactor core
(rings, spokes, rotating gimbal arcs) over a dark starfield, with mood-driven
palette and structure:
  cold      -> dim teal/blue, slow symmetric rings
  hostile   -> red-orange, jagged broken rings, aggressive spokes
  placated  -> warm amber/cyan, open rings, gentle bloom
Transparent background (starfield kept faint so it composites over any scene).
"""
import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import PAL, rng_for, save  # noqa: E402

S = 1024


def mood(m):
    if m == "cold":
        return dict(rings=PAL["teal"], core=PAL["cyan"], accent=PAL["blue"],
                    jag=0.0, spokes=16, bloom=PAL["teal"], alpha=235)
    if m == "hostile":
        return dict(rings=PAL["red"], core=PAL["orange"], accent=PAL["orange_dim"],
                    jag=1.0, spokes=24, bloom=PAL["red"], alpha=245)
    return dict(rings=PAL["amber"], core=PAL["ice"], accent=PAL["teal"],
                jag=0.0, spokes=12, bloom=PAL["amber"], alpha=225)


def gen(mood_name, seed="erebus-7"):
    r = rng_for(seed, mood_name)
    p = mood(mood_name)
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))

    # faint starfield
    st = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    sd = ImageDraw.Draw(st)
    for _ in range(260):
        x, y = r.randint(0, S - 1), r.randint(0, S - 1)
        b = r.randint(50, 160)
        sd.point((x, y), fill=(b, b + 10, b + 20, 160))
    img = Image.alpha_composite(img, st)

    cx = cy = S / 2

    # bloom behind core
    bl = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    bd = ImageDraw.Draw(bl)
    R = S * (0.34 if mood_name != "hostile" else 0.38)
    bd.ellipse([cx - R, cy - R, cx + R, cy + R], fill=p["bloom"][:3] + (90,))
    bl = bl.filter(ImageFilter.GaussianBlur(S * 0.10))
    img = Image.alpha_composite(img, bl)

    core = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    cd = ImageDraw.Draw(core)

    # outer gimbal arcs (3 rotated open arcs)
    for i, rot in enumerate((0.3, 0.3 + 2.1, 0.3 + 4.2)):
        rr = S * (0.46 - i * 0.035)
        cd.arc([cx - rr, cy - rr, cx + rr, cy + rr],
               start=math.degrees(rot), end=math.degrees(rot) + 210,
               fill=p["accent"][:3] + (200,), width=8 - i * 2)

    # main rings
    n_rings = 6
    for i in range(n_rings):
        t = i / (n_rings - 1)
        rr = S * (0.40 - t * 0.30)
        jag = p["jag"]
        col = p["rings"][:3] + (p["alpha"],)
        if jag > 0 and i % 2 == 0:
            # jagged broken ring: polyline of shards
            pts = []
            n = 48
            for k in range(n + 1):
                ang = 2 * math.pi * k / n
                j = rr * (1 + jag * 0.10 * math.sin(ang * 9 + i))
                if k % 7 < 5:  # gaps
                    pts.append((cx + j * math.cos(ang), cy + j * math.sin(ang)))
                else:
                    if len(pts) > 1:
                        cd.line(pts, fill=col, width=10)
                    pts = []
            if len(pts) > 1:
                cd.line(pts, fill=col, width=10)
        else:
            cd.ellipse([cx - rr, cy - rr, cx + rr, cy + rr],
                       outline=col, width=max(3, int(12 - t * 8)))

    # radial spokes
    for i in range(p["spokes"]):
        ang = 2 * math.pi * i / p["spokes"]
        r0, r1 = S * 0.10, S * 0.40
        w = 3 if i % 2 else 6
        cd.line([(cx + r0 * math.cos(ang), cy + r0 * math.sin(ang)),
                 (cx + r1 * math.cos(ang), cy + r1 * math.sin(ang))],
                fill=p["accent"][:3] + (170,), width=w)

    # inner core: polygon aperture + hot center
    sides = 8 if mood_name != "hostile" else 3
    rot0 = math.pi / 8
    for k, scale in ((0.20, 1.0), (0.14, 0.62)):
        pts = []
        for i in range(sides):
            ang = rot0 + 2 * math.pi * i / sides
            pts.append((cx + S * scale * math.cos(ang),
                        cy + S * scale * math.sin(ang)))
        cd.polygon(pts, outline=p["core"][:3] + (255,), width=6)
    hot = S * 0.055
    cd.ellipse([cx - hot, cy - hot, cx + hot, cy + hot],
               fill=PAL["white"][:3] + (255,))

    img = Image.alpha_composite(img, core)

    # hostile: crack lightning bolts from core outward
    if mood_name == "hostile":
        lk = Image.new("RGBA", (S, S), (0, 0, 0, 0))
        ld = ImageDraw.Draw(lk)
        for _ in range(9):
            ang = r.uniform(0, 2 * math.pi)
            x, y = cx + S*0.06*math.cos(ang), cy + S*0.06*math.sin(ang)
            pts = [(x, y)]
            d = S * 0.06
            while d < S * 0.45:
                ang += r.uniform(-0.4, 0.4)
                x += d * math.cos(ang); y += d * math.sin(ang)
                pts.append((x, y)); d *= 1.25
            ld.line(pts, fill=PAL["amber"][:3] + (200,), width=3)
        img = Image.alpha_composite(img, lk)

    # placated: soft orbiting motes
    if mood_name == "placated":
        mo = Image.new("RGBA", (S, S), (0, 0, 0, 0))
        md = ImageDraw.Draw(mo)
        for _ in range(26):
            ang = r.uniform(0, 2 * math.pi)
            rr = r.uniform(S * 0.18, S * 0.47)
            x, y = cx + rr * math.cos(ang), cy + rr * math.sin(ang)
            pr = r.uniform(2, 6)
            md.ellipse([x - pr, y - pr, x + pr, y + pr],
                       fill=PAL["ice"][:3] + (200,))
        mo = mo.filter(ImageFilter.GaussianBlur(1.2))
        img = Image.alpha_composite(img, mo)

    save(img, f"assets/art/erebus7_{mood_name}.png")


if __name__ == "__main__":
    for m in ("cold", "hostile", "placated"):
        gen(m)
