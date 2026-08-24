"""UI skin set for LAST SIGNAL. All PNGs in assets/ui/.

  ui_dialog_frame.png   9-slice dialog frame, 48px border, 480x160
  ui_btn_normal.png     360x72 choice button
  ui_btn_hover.png      360x72
  ui_btn_pressed.png    360x72
  ui_backlog_panel.png  640x480 panel
  ui_codex_panel.png    640x480 panel
  ui_save_slot.png      560x120 frame
All 9-slice-able: flat center, decorated borders.
"""
import math
import os
import sys

from PIL import Image, ImageDraw, ImageFilter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import PAL, font_for, mix, rng_for, save  # noqa: E402


def corner_ticks(dr, box, col, tick=14, width=4):
    x0, y0, x1, y1 = box
    for (cx, cy, dx, dy) in ((x0, y0, 1, 1), (x1, y0, -1, 1),
                             (x0, y1, 1, -1), (x1, y1, -1, -1)):
        dr.line([(cx, cy), (cx + dx * tick, cy)], fill=col, width=width)
        dr.line([(cx, cy), (cx, cy + dy * tick)], fill=col, width=width)


def panel(w, h, base, edge, accent, radius=10, width=3, ticks=True,
          header=None, inner_alpha=235):
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    dr = ImageDraw.Draw(img)
    dr.rounded_rectangle([2, 2, w - 3, h - 3], radius=radius,
                         fill=base + (inner_alpha,), outline=edge + (255,), width=width)
    # top accent line
    dr.line([(14, 10), (w - 14, 10)], fill=accent + (200,), width=2)
    if ticks:
        corner_ticks(dr, (6, 6, w - 7, h - 7), accent + (255,))
    if header:
        f = font_for(22)
        dr.text((20, 16), header, font=f, fill=(190, 226, 238, 255))
        dr.line([(16, 46), (w - 16, 46)], fill=edge + (160,), width=1)
    return img


def button(state):
    w, h = 360, 72
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    dr = ImageDraw.Draw(img)
    if state == "normal":
        base, edge, accent, glow = (18, 38, 64), PAL["teal"], PAL["teal"], 0
    elif state == "hover":
        base, edge, accent, glow = (24, 54, 88), PAL["cyan"], PAL["orange"], 1
    else:  # pressed
        base, edge, accent, glow = (12, 26, 46), PAL["blue"], PAL["orange_dim"], 0
    dr.rounded_rectangle([2, 2, w - 3, h - 3], radius=12, fill=base + (240,),
                         outline=edge + (255,), width=3)
    # left accent chevron
    dr.polygon([(16, h // 2 - 12), (30, h // 2), (16, h // 2 + 12)],
               fill=accent + (255,))
    if glow:
        gl = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        gd = ImageDraw.Draw(gl)
        gd.rounded_rectangle([2, 2, w - 3, h - 3], radius=12,
                             outline=accent + (160,), width=8)
        gl = gl.filter(ImageFilter.GaussianBlur(5))
        img = Image.alpha_composite(gl, img)
    return img


def dialog_frame():
    w, h = 480, 160
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    dr = ImageDraw.Draw(img)
    dr.rounded_rectangle([3, 3, w - 4, h - 4], radius=14,
                         fill=(10, 22, 40, 228), outline=PAL["teal"] + (255,), width=3)
    # inner subtle line
    dr.rounded_rectangle([12, 12, w - 13, h - 13], radius=9,
                         outline=(40, 78, 110, 160), width=1)
    # nameplate tab, upper-left
    dr.rounded_rectangle([18, -2, 178, 30], radius=8,
                         fill=(16, 40, 68, 255), outline=PAL["cyan"] + (255,), width=2)
    corner_ticks(dr, (8, 8, w - 9, h - 9), PAL["cyan"] + (255,))
    return img


def backlog_panel():
    return panel(640, 480, (12, 26, 46), PAL["teal"], PAL["cyan"],
                 header="BACKLOG")


def codex_panel():
    return panel(640, 480, (14, 28, 44), PAL["blue"], PAL["orange"],
                 header="CODEX")


def save_slot():
    w, h = 560, 120
    img = panel(w, h, (14, 30, 52), PAL["grey_blue"], PAL["amber"], radius=8)
    dr = ImageDraw.Draw(img)
    # slot preview window on the left
    dr.rounded_rectangle([16, 30, 176, h - 16], radius=6,
                         fill=(6, 14, 28, 255), outline=PAL["teal"] + (220,), width=2)
    # placeholder chapter lines
    for i, ln in enumerate((200, 150, 170)):
        dr.line([(196, 44 + i * 24), (196 + ln, 44 + i * 24)],
                fill=(60, 96, 128, 200), width=8)
    return img


if __name__ == "__main__":
    save(dialog_frame(), "assets/ui/ui_dialog_frame.png")
    save(button("normal"), "assets/ui/ui_btn_normal.png")
    save(button("hover"), "assets/ui/ui_btn_hover.png")
    save(button("pressed"), "assets/ui/ui_btn_pressed.png")
    save(backlog_panel(), "assets/ui/ui_backlog_panel.png")
    save(codex_panel(), "assets/ui/ui_codex_panel.png")
    save(save_slot(), "assets/ui/ui_save_slot.png")
