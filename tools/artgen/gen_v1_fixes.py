#!/usr/bin/env python3
"""v1 art MAJOR fixes — seeded regen of flat backgrounds + bg_void,
title lockup (fills canvas), ARIA avatar sprite.

House palette: deep-space blue/teal + signal-orange accent.
Run from repo root: python3 tools/artgen/gen_v1_fixes.py
"""
import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import (PAL, arr, font_for, grain, mix, pil_layer, radial_glow,  # noqa: E402
                    rng_for, save, stars, text_size, to_img, vignette,
                    v_gradient)

BW, BH = 1280, 720


# ------------------------------------------------------------ structure ----
def _panels(dr, r, w, h, n, y0f, y1f, base, edge, accent_chance=0.25):
    """Console panels / wall plating along a band."""
    x = int(w * r.uniform(0.02, 0.08))
    while x < w * 0.95:
        pw = int(r.uniform(w * 0.06, w * 0.16))
        ph = int((y1f - y0f) * h * r.uniform(0.35, 0.8))
        y0 = int(y0f * h + r.uniform(0, (y1f - y0f) * h * 0.3))
        col = mix(base, edge, r.random())
        dr.rectangle([x, y0, min(x + pw, w - 4), y0 + ph], fill=col + (255,),
                     outline=edge + (255,), width=2)
        if r.random() < accent_chance:
            # little indicator lights
            for i in range(r.randint(2, 5)):
                lx = x + 6 + i * 10
                c = [PAL["green"], PAL["orange"], PAL["cyan"], PAL["red"]][r.randint(0, 3)]
                dr.rectangle([lx, y0 + 6, lx + 4, y0 + 10], fill=c + (255,))
        elif r.random() < 0.5:
            # screen glow inside panel
            sc = mix(PAL["teal"], PAL["blue"], r.random())
            dr.rectangle([x + 6, y0 + 6, x + pw - 6, y0 + ph - 6], fill=sc + (90,))
        x += pw + int(r.uniform(8, 26))


def _pipe_run(a, r, horizontal=True):
    """Glowing conduit lines added into the array."""
    h, w = a.shape[:2]
    for _ in range(r.randint(2, 4)):
        col = np.array(mix(PAL["grey_blue"], PAL["teal"], r.random()), float)
        t = r.uniform(0.05, 0.95)
        if horizontal:
            y = int(h * t); ph = r.randint(3, 6)
            a[y:y + ph, :] += (col - a[y:y + ph, :]) * 0.55
        else:
            x = int(w * t); pw = r.randint(3, 6)
            a[:, x:x + pw] += (col - a[:, x:x + pw, :]) * 0.55


def _floor_ceiling(a, r):
    h, w = a.shape[:2]
    # ceiling: darker struts
    ch = int(h * r.uniform(0.10, 0.16))
    a[:ch] *= np.array([0.45, 0.5, 0.6])
    for x in range(0, w, r.randint(70, 120)):
        a[:ch, x:x + 8] *= 0.6
    # floor: slightly lighter deck plating with perspective hint
    fh = int(h * r.uniform(0.12, 0.18))
    a[h - fh:] = a[h - fh:] * 0.85 + np.array([18, 34, 52]) * 0.15
    for i, x in enumerate(range(0, w, 90)):
        xx = x + (i % 2) * 12
        a[h - fh:h, xx:xx + 4] *= 0.72


def _finish(a, r, seed_extra=""):
    grain(a, r, amount=2.2)
    vignette(a, 0.5)
    img = to_img(a)
    # subtle scanlines for CRT feel
    ov = Image.new("L", img.size, 255)
    d = ImageDraw.Draw(ov)
    for y in range(0, BH, 4):
        d.line([(0, y), (BW, y)], fill=246)
    dark = Image.new("RGB", img.size, (0, 0, 0))
    return Image.composite(img, dark, ov)


# --------------------------------------------------------- backgrounds -----
def bg_bridge():
    """Command bridge: viewport band with stars, console tiers."""
    a = arr(BW, BH)
    v_gradient(a, PAL["void"], PAL["deep"])
    r = rng_for("bg_bridge|v2fix")
    # forward viewport with starfield
    vx0, vx1 = int(BW * 0.18), int(BW * 0.82)
    vy0, vy1 = int(BH * 0.14), int(BH * 0.46)
    sub = arr(vx1 - vx0, vy1 - vy0) * 0 + np.array(PAL["navy"], float) * 0.3
    rs = rng_for("bg_bridge|stars")
    stars(sub, rs, n=420, bright=230, big_chance=0.10)
    a[vy0:vy1, vx0:vx1] = sub
    img = to_img(a)
    lay = pil_layer(img.size)
    dr = ImageDraw.Draw(lay)
    # viewport frame struts
    fr = mix(PAL["grey_blue"], PAL["panel"], 0.5)
    dr.rectangle([vx0 - 22, vy0 - 22, vx1 + 22, vy1 + 22], outline=fr + (255,), width=10)
    dr.line([(BW // 2, vy0 - 22), (BW // 2, vy1 + 22)], fill=fr + (255,), width=8)
    # two console tiers silhouetted with glowing screens
    for tier, (ty, th) in enumerate([(0.62, 0.13), (0.80, 0.15)]):
        y = int(BH * ty)
        dr.polygon([(int(BW*0.06), y + int(BH*th)), (int(BW*0.94), y + int(BH*th)),
                    (int(BW*0.88), y), (int(BW*0.12), y)],
                   fill=mix(PAL["panel"], PAL["deep"], 0.4) + (255,))
        rr = rng_for("bridge|tier", tier)
        for _ in range(rr.randint(6, 9)):
            sx = int(rr.uniform(BW * 0.14, BW * 0.86))
            sw = int(rr.uniform(30, 90)); shh = int(rr.uniform(10, 22))
            c = mix(PAL["teal"], PAL["cyan"], rr.random()) if rr.random() < 0.75 else PAL["orange"]
            dr.rectangle([sx, y + 10, sx + sw, y + 10 + shh], fill=c + (200,))
        # seat silhouettes
    out = Image.alpha_composite(img.convert("RGBA"), lay)
    a2 = np.array(out.convert("RGB")).astype(float)
    return _finish_arr(a2, "bg_bridge")


def _finish_arr(a, name):
    r = rng_for(name, "finish")
    return _finish(a, r)


def bg_corridor():
    a = arr(BW, BH)
    v_gradient(a, PAL["deep"], mix(PAL["void"], PAL["deep"], 0.5))
    r = rng_for("bg_corridor|v2fix")
    img = to_img(a)
    lay = pil_layer(img.size)
    dr = ImageDraw.Draw(lay)
    # one-point perspective corridor
    cx, cy = BW // 2, int(BH * 0.48)
    depth = 6
    for d in range(depth, 0, -1):
        s = d / depth
        hw = int(BW * 0.62 * s); hh = int(BH * 0.42 * s)
        col = mix(mix(PAL["panel"], PAL["navy"], 0.5), mix(PAL["deep"], PAL["navy"], 0.4), 1 - s)
        dr.rectangle([cx - hw, cy - hh, cx + hw, cy + hh],
                     outline=mix(col, PAL["ice"], 0.25) + (235,), width=max(2, int(9 * s)))
    # far end glow door
    radial_glow(a, cx, cy, 190, mix(PAL["teal"], PAL["cyan"], 0.4), strength=0.75)
    dr = ImageDraw.Draw(lay)
    dr.rectangle([cx - 46, cy - 92, cx + 46, cy + 96], fill=mix(PAL["teal"], PAL["white"], 0.25) + (150,),
                 outline=PAL["ice"] + (220,), width=3)
    dr.line([(cx - 20, cy - 60), (cx - 20, cy + 60)], fill=PAL["orange"] + (230,), width=4)
    # wall ribs
    rr = rng_for("corridor|ribs")
    for d in range(depth):
        s = (d + 1) / depth
        hw = int(BW * 0.66 * s); hh = int(BH * 0.46 * s)
        wd = max(2, int(10 * s))
        col = mix(PAL["grey_blue"], PAL["panel"], 0.4)
        dr.line([(cx - hw, cy - hh), (cx - hw, cy + hh)], fill=col + (255,), width=wd)
        dr.line([(cx + hw, cy - hh), (cx + hw, cy + hh)], fill=col + (255,), width=wd)
        # rib lights
        lc = PAL["cyan"] if d % 2 else PAL["orange"]
        rad = max(2, int(5 * s))
        dr.ellipse([cx - hw - rad, cy - int(hh*0.4) - rad, cx - hw + rad, cy - int(hh*0.4) + rad], fill=lc + (255,))
        dr.ellipse([cx + hw - rad, cy - int(hh*0.4) - rad, cx + hw + rad, cy - int(hh*0.4) + rad], fill=lc + (255,))
    _floor_ceiling(np.array(img.convert("RGB")).astype(float)[:1]) if False else None
    out = Image.alpha_composite(img.convert("RGBA"), lay)
    a2 = np.array(out.convert("RGB")).astype(float)
    return _finish_arr(a2, "bg_corridor")


def bg_cryobay():
    a = arr(BW, BH)
    v_gradient(a, mix(PAL["deep"], PAL["void"], 0.4), PAL["navy"])
    r = rng_for("bg_cryobay|v2fix")
    img = to_img(a)
    lay = pil_layer(img.size)
    dr = ImageDraw.Draw(lay)
    # row of cryopods along back wall
    rr = rng_for("cryobay|pods")
    n = 4
    for i in range(n):
        px = int(BW * (0.10 + 0.24 * i))
        pw, ph = 170, 330
        py = int(BH * 0.28)
        body = mix(PAL["panel"], PAL["navy"], 0.6)
        dr.rounded_rectangle([px, py, px + pw, py + ph], radius=60,
                             fill=body + (255,), outline=mix(PAL["grey_blue"], PAL["ice"], 0.3) + (255,), width=4)
        # frosted window with cold teal glow + occupant silhouette
        win = [px + 22, py + 26, px + pw - 22, py + ph - 26]
        dr.rounded_rectangle(win, radius=44, fill=mix(PAL["teal"], PAL["ice"], 0.35) + (110,))
        # occupant: simple reclined figure
        oc = mix(PAL["deep"], PAL["navy"], 0.3)
        wx0, wy0, wx1, wy1 = win
        dr.ellipse([wx0+58, wy0+70, wx0+108, wy0+120], fill=oc + (200,))          # head
        dr.rounded_rectangle([wx0+30, wy0+115, wx1-30, wy0+215], radius=36, fill=oc + (190,))  # torso
        # status light
        stc = PAL["green"] if i % 3 else PAL["orange"]
        dr.ellipse([px + pw//2 - 7, py + ph - 20, px + pw//2 + 7, py + ph - 6], fill=stc + (255,))
        # frost mist
        mr = rng_for("cryo|mist", i)
        for _ in range(26):
            mx = int(mr.uniform(wx0, wx1)); my = int(mr.uniform(wy0, wy1))
            mrad = int(mr.uniform(4, 14))
            mc = mix(PAL["white"], PAL["ice"], mr.random())
            dr.ellipse([mx-mrad, my-mrad, mx+mrad, my+mrad], fill=mc + (26,))
    # overhead cold light bar
    dr.rectangle([int(BW*0.3), int(BH*0.07), int(BW*0.7), int(BH*0.09)], fill=mix(PAL["ice"], PAL["white"], 0.5) + (230,))
    out = Image.alpha_composite(img.convert("RGBA"), lay)
    a2 = np.array(out.convert("RGB")).astype(float)
    # cool cast
    a2[..., 2] *= 1.06
    return _finish_arr(a2, "bg_cryobay")


def bg_engineering():
    a = arr(BW, BH)
    v_gradient(a, mix(PAL["void"], PAL["deep"], 0.6), mix(PAL["deep"], PAL["panel"], 0.4))
    r = rng_for("bg_engineering|v2fix")
    _pipe_run(a, r, horizontal=True)
    _pipe_run(a, r, horizontal=False)
    img = to_img(a)
    lay = pil_layer(img.size)
    dr = ImageDraw.Draw(lay)
    # central reactor column with hot core
    cx = BW // 2
    dr.rectangle([cx - 130, int(BH*0.12), cx + 130, int(BH*0.88)],
                 fill=mix(PAL["panel"], PAL["grey_blue"], 0.5) + (255,),
                 outline=PAL["grey_blue"] + (255,), width=5)
    core_y = int(BH * 0.5)
    for k, (rad, col, alpha) in enumerate([
            (120, PAL["orange_dim"], 160), (86, PAL["orange"], 210),
            (52, PAL["amber"], 240), (26, PAL["white"], 255)]):
        dr.ellipse([cx - rad, core_y - rad, cx + rad, core_y + rad], fill=col + (alpha,))
    # containment ring segments
    for ang in range(0, 360, 30):
        ar = math.radians(ang)
        x1 = cx + int(150 * math.cos(ar)); y1 = core_y + int(150 * math.sin(ar))
        x2 = cx + int(178 * math.cos(ar)); y2 = core_y + int(178 * math.sin(ar))
        dr.line([(x1, y1), (x2, y2)], fill=PAL["grey_blue"] + (255,), width=8)
    # side catwalks
    rr = rng_for("eng|catwalk")
    for ty in (0.30, 0.68):
        y = int(BH * ty)
        dr.line([(0, y), (int(BW*0.33), y)], fill=PAL["grey_blue"] + (255,), width=7)
        dr.line([(int(BW*0.67), y), (BW, y)], fill=PAL["grey_blue"] + (255,), width=7)
        for _ in range(rr.randint(3, 5)):
            lx = int(rr.choice([rr.uniform(10, BW*0.3), rr.uniform(BW*0.7, BW-40)]))
            c = rr.choice([PAL["amber"], PAL["cyan"], PAL["red"]])
            dr.rectangle([lx, y + 10, lx + 8, y + 18], fill=c + (255,))
    out = Image.alpha_composite(img.convert("RGBA"), lay)
    a2 = np.array(out.convert("RGB")).astype(float)
    # reactor bloom into the array
    af = arr(BW, BH) * 0 + a2
    radial_glow(af, cx, core_y, 320, mix(PAL["orange"], PAL["amber"], 0.5), strength=0.35)
    return _finish_arr(af, "bg_engineering")


def bg_medical():
    a = arr(BW, BH)
    v_gradient(a, mix(PAL["deep"], PAL["navy"], 0.3), mix(PAL["panel"], PAL["deep"], 0.5))
    r = rng_for("bg_medical|v2fix")
    img = to_img(a)
    lay = pil_layer(img.size)
    dr = ImageDraw.Draw(lay)
    # med bay: bunk with scanner arch on left, cabinets + monitor right
    bx, by = int(BW*0.12), int(BH*0.52)
    bw_, bh_ = int(BW*0.34), 26
    dr.rectangle([bx, by, bx + bw_, by + bh_], fill=mix(PAL["grey_blue"], PAL["panel"], 0.4) + (255,))
    dr.rectangle([bx, by + bh_, bx + bw_, int(BH*0.9)], fill=mix(PAL["panel"], PAL["void"], 0.4) + (255,))
    # scanner arch over bunk
    dr.arc([bx + int(bw_*0.15), by - 190, bx + int(bw_*0.85), by + 90], 180, 360,
           fill=mix(PAL["cyan"], PAL["ice"], 0.3) + (255,), width=10)
    # gentle heal-light glow
    gx = bx + bw_ // 2
    # wall cabinets
    for i in range(3):
        cxp = int(BW*(0.56 + 0.14*i))
        dr.rectangle([cxp, int(BH*0.18), cxp + int(BW*0.11), int(BH*0.38)],
                     fill=mix(PAL["panel"], PAL["navy"], 0.5) + (255,),
                     outline=PAL["grey_blue"] + (255,), width=3)
        dr.line([(cxp + 6, int(BH*0.28)), (cxp + int(BW*0.11) - 6, int(BH*0.28))],
                fill=mix(PAL["ice"], PAL["teal"], 0.4) + (140,), width=2)
    # vitals monitor
    mx, my = int(BW*0.60), int(BH*0.50)
    dr.rectangle([mx, my, mx + 250, my + 170], fill=PAL["void"] + (255,),
                 outline=PAL["grey_blue"] + (255,), width=4)
    rr = rng_for("med|ekg")
    pts = [(mx + 10 + i * 12, my + 85 + int(34 * math.sin(i * 0.9) * (1 if i % 7 else 3)))
           for i in range(19)]
    dr.line(pts, fill=PAL["green"] + (255,), width=3)
    dr.text((mx + 14, my + 12), "VITALS", font=font_for(18), fill=PAL["ice"] + (220,))
    # cross emblem
    hx, hy = int(BW*0.47), int(BH*0.16)
    dr.rectangle([hx - 14, hy - 40, hx + 14, hy + 40], fill=PAL["ice"] + (235,))
    dr.rectangle([hx - 40, hy - 14, hx + 40, hy + 14], fill=PAL["ice"] + (235,))
    out = Image.alpha_composite(img.convert("RGBA"), lay)
    a2 = np.array(out.convert("RGB")).astype(float)
    radial_glow(a2, gx, by - 40, 260, mix(PAL["cyan"], PAL["ice"], 0.5), strength=0.22)
    return _finish_arr(a2, "bg_medical")


def bg_void():
    """Deep-space exterior: not pure black — starfield, nebula wash, derelict hint."""
    a = arr(BW, BH)
    v_gradient(a, PAL["void"], mix(PAL["void"], PAL["deep"], 0.65))
    r = rng_for("bg_void|v2fix")
    # nebula washes
    nr = rng_for("void|nebula")
    for _ in range(4):
        nx = nr.uniform(0, BW); ny = nr.uniform(0, BH)
        col = nr.choice([mix(PAL["navy"], PAL["blue"], 0.6),
                         mix(PAL["teal"], PAL["blue"], 0.4),
                         mix(PAL["orange_dim"], PAL["navy"], 0.5)])
        radial_glow(a, nx, ny, nr.uniform(260, 520), col, strength=nr.uniform(0.25, 0.45), falloff=2.6)
    sr = rng_for("void|stars")
    stars(a, sr, n=700, bright=235, big_chance=0.10)
    # distant station silhouette
    img = to_img(a)
    lay = pil_layer(img.size)
    dr = ImageDraw.Draw(lay)
    scx, scy = int(BW*0.74), int(BH*0.30)
    sil = mix(PAL["void"], PAL["panel"], 0.35)
    dr.ellipse([scx-70, scy-34, scx+70, scy+34], fill=sil + (255,))
    dr.rectangle([scx-10, scy-64, scx+10, scy+64], fill=sil + (255,))
    dr.ellipse([scx-84, scy-84, scx+84, scy+84], outline=sil + (255,), width=7)
    # tiny beacon lights
    for dx, dy in ((-40, -12), (34, 18), (0, -70)):
        blink = PAL["orange"] if dy < 0 else PAL["cyan"]
        dr.ellipse([scx+dx-3, scy+dy-3, scx+dx+3, scy+dy+3], fill=blink + (255,))
    out = Image.alpha_composite(img.convert("RGBA"), lay)
    a2 = np.array(out.convert("RGB")).astype(float)
    grain(a2, rng_for("void|grain"), amount=1.6)
    return Image.fromarray(np.clip(a2, 0, 255).astype(np.uint8), "RGB")


# ---------------------------------------------------------- title lockup ---
def _pixel_text(text, fnt, scale, color_top, color_bot, tracking=3):
    """Render text with the bitmap fallback font, upscale NN -> chunky pixels."""
    tmp = Image.new("RGBA", (10, 10), (0, 0, 0, 0))
    d = ImageDraw.Draw(tmp)
    widths = []
    total = 0
    for ch in text:
        bb = d.textbbox((0, 0), ch, font=fnt)
        wch = bb[2] - bb[0]
        widths.append((wch, bb))
        total += (wch + tracking) * scale
    total -= tracking * scale
    bb0 = d.textbbox((0, 0), text[0], font=fnt)
    hgt = (bb0[3] - bb0[1]) * scale
    asc = bb0[1] * scale
    img = Image.new("RGBA", (max(total, 1), max(hgt, 1)), (0, 0, 0, 0))
    dr = ImageDraw.Draw(tmp)
    x = 0
    for ch, (wch, bb) in zip(text, widths):
        glyph = Image.new("RGBA", (max(wch, 1), 20), (0, 0, 0, 0))
        gd = ImageDraw.Draw(glyph)
        gd.text((-bb[0], -bb[1]), ch, font=fnt, fill=(255, 255, 255, 255))
        gw = max(wch * scale, 1)
        gh = hgt
        gbig = glyph.resize((gw, gh), Image.NEAREST)
        # vertical gradient tint via mask
        grad = Image.new("RGBA", (gw, gh), (0, 0, 0, 0))
        gdr = ImageDraw.Draw(grad)
        for yy in range(gh):
            t = yy / max(gh - 1, 1)
            c = tuple(int(color_top[i] * (1 - t) + color_bot[i] * t) for i in range(3))
            gdr.line([(0, yy), (gw, yy)], fill=c + (255,))
        img.alpha_composite(Image.composite(grad, Image.new("RGBA", gbig.size, (0, 0, 0, 0)), gbig.split()[3]), (x, 0))
        x += (wch + tracking) * scale
    return img


def title_lockup():
    W, H = 1600, 420
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    title = "LAST SIGNAL"
    f_big = font_for(11)   # bitmap fallback -> upscaled deliberately
    # target: text spans ~92% of canvas width
    scale = 1
    probe = _pixel_text(title, f_big, scale, (255, 255, 255), (255, 255, 255))
    scale = max(1, int((W * 0.92) / max(probe.width, 1)))
    big = _pixel_text(title, f_big, scale, (232, 244, 250), (88, 214, 224), tracking=3)
    # soft glow pass
    glow = big.filter(ImageFilter.GaussianBlur(scale * 1.6))
    tinted = Image.new("RGBA", big.size, PAL["teal"] + (255,))
    glow_t = Image.composite(tinted, Image.new("RGBA", big.size, (0, 0, 0, 0)), glow.split()[3].point(lambda a: a * 0.55))
    tw, th = big.size
    tx = (W - tw) // 2
    ty = int(H * 0.10)
    img.alpha_composite(glow_t, (tx, ty))
    img.alpha_composite(big, (tx, ty))
    # underline: cyan rule with orange leading segment
    uy = ty + th + int(H * 0.07)
    dr = ImageDraw.Draw(img)
    dr.line([(tx, uy), (tx + tw, uy)], fill=(90, 200, 214, 230), width=max(4, scale))
    dr.line([(tx, uy), (tx + int(tw * 0.22), uy)], fill=PAL["orange"] + (255,), width=max(4, scale))
    # subtitle
    sub = "A DEEP-SPACE VISUAL NOVEL"
    f_sub = font_for(11)
    sbig = _pixel_text(sub, f_sub, max(2, scale // 3), (150, 200, 216), (150, 200, 216), tracking=2)
    sx = (W - sbig.width) // 2
    sy = uy + int(H * 0.06)
    img.alpha_composite(sbig, (sx, sy))
    return img


# ------------------------------------------------------------- AI avatar ---
def ai_avatar():
    """ARIA-7 avatar sprite, 32x32, matching portrait palette (dark bg, teal/cyan face)."""
    W = H = 32
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    dr = ImageDraw.Draw(img)
    dark = (14, 18, 26)
    teal = (32, 144, 160)
    cyan = (88, 214, 224)
    ice = (168, 226, 238)
    orange = (255, 140, 26)
    white = (232, 244, 250)
    # head shell
    dr.rectangle([7, 5, 24, 26], fill=dark + (255,))
    dr.rectangle([6, 7, 25, 24], fill=dark + (255,))
    dr.rectangle([8, 4, 23, 27], fill=dark + (255,))
    # faceplate
    dr.rectangle([9, 8, 22, 21], fill=teal + (255,))
    dr.rectangle([10, 9, 21, 17], fill=mix(teal, cyan, 0.45) + (255,))
    # eyes
    dr.rectangle([11, 11, 13, 13], fill=white + (255,))
    dr.rectangle([18, 11, 20, 13], fill=white + (255,))
    dr.point([(12, 12)], orange + (255,))   # asymmetric spark
    # mouth line
    dr.line([(13, 17), (18, 17)], fill=ice + (255,), width=1)
    # antenna + ear pods
    dr.line([(16, 4), (16, 1)], fill=ice + (255,))
    dr.point([(16, 0)], orange + (255,))
    dr.rectangle([4, 12, 6, 18], fill=mix(dark, teal, 0.4) + (255,))
    dr.rectangle([25, 12, 27, 18], fill=mix(dark, teal, 0.4) + (255,))
    dr.point([(5, 14)], cyan + (255,))
    dr.point([(26, 14)], cyan + (255,))
    # neck + shoulders hint
    dr.rectangle([13, 27, 18, 29], fill=mix(dark, (40, 52, 70), 0.5) + (255,))
    dr.rectangle([9, 29, 22, 31], fill=mix(dark, (40, 52, 70), 0.35) + (255,))
    # cheek shading
    dr.point([(10, 19), (21, 19)], mix(teal, dark, 0.35) + (255,))
    return img


def main():
    save(bg_bridge(), "assets/backgrounds/bg_bridge.png")
    save(bg_corridor(), "assets/backgrounds/bg_corridor.png")
    save(bg_cryobay(), "assets/backgrounds/bg_cryobay.png")
    save(bg_engineering(), "assets/backgrounds/bg_engineering.png")
    save(bg_medical(), "assets/backgrounds/bg_medical.png")
    save(bg_void(), "assets/backgrounds/bg_void.png")
    save(title_lockup(), "assets/art/title_lockup.png")
    save(ai_avatar(), "assets/sprites/ai_avatar.png")


if __name__ == "__main__":
    main()
