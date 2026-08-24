"""Verify every generated art asset: PNG integrity, size/mode, non-trivial
histogram, and build upscaled contact-sheet montages for human inspection.

Usage: python3 tools/artgen/verify_assets.py [--sheets DIR]
Exit code 1 if any check fails.
"""
import glob
import os
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
ASSETS = os.path.join(ROOT, "LAST_SIGNAL", "assets")

EXPECTED = {
    "portraits/aria7_neutral.png": (512, 512, "RGBA"),
    "portraits/aria7_alert.png": (512, 512, "RGBA"),
    "portraits/aria7_distressed.png": (512, 512, "RGBA"),
    "art/erebus7_cold.png": (1024, 1024, "RGBA"),
    "art/erebus7_hostile.png": (1024, 1024, "RGBA"),
    "art/erebus7_placated.png": (1024, 1024, "RGBA"),
    "art/endings/ending_wake_them.png": (1920, 1080, "RGBA"),
    "art/endings/ending_let_them_sleep.png": (1920, 1080, "RGBA"),
    "art/endings/ending_merge.png": (1920, 1080, "RGBA"),
    "art/endings/ending_wake_but_leave.png": (1920, 1080, "RGBA"),
    "art/endings/ending_station_wins.png": (1920, 1080, "RGBA"),
    "art/endings/ending_the_loop.png": (1920, 1080, "RGBA"),
    "art/keyart_menu.png": (1920, 1080, "RGBA"),
    "art/title_lockup.png": (1600, 420, "RGBA"),
    "art/menu_backdrop.png": (1280, 720, "RGBA"),
    "backgrounds/bg_observation_deck.png": (1280, 720, "RGBA"),
    "backgrounds/bg_reactor.png": (1280, 720, "RGBA"),
    "ui/ui_dialog_frame.png": (480, 160, "RGBA"),
    "ui/ui_btn_normal.png": (360, 72, "RGBA"),
    "ui/ui_btn_hover.png": (360, 72, "RGBA"),
    "ui/ui_btn_pressed.png": (360, 72, "RGBA"),
    "ui/ui_backlog_panel.png": (640, 480, "RGBA"),
    "ui/ui_codex_panel.png": (640, 480, "RGBA"),
    "ui/ui_save_slot.png": (560, 120, "RGBA"),
}

failures = []
for rel, (ew, eh, emode) in sorted(EXPECTED.items()):
    path = os.path.join(ASSETS, rel)
    if not os.path.exists(path):
        failures.append(f"MISSING {rel}")
        continue
    try:
        im = Image.open(path)
        im.load()
    except Exception as exc:
        failures.append(f"CORRUPT {rel}: {exc}")
        continue
    if im.size != (ew, eh):
        failures.append(f"SIZE {rel}: {im.size} != {(ew, eh)}")
    if im.mode != emode:
        failures.append(f"MODE {rel}: {im.mode} != {emode}")
    rgb = np.asarray(im.convert("RGB")).astype(float)
    hist_std = rgb.std()
    mean_lum = rgb.mean()
    if hist_std < 8:
        failures.append(f"FLAT {rel}: histogram std={hist_std:.1f} (<8, near-solid)")
    if im.mode == "RGBA":
        alpha = np.asarray(im)[:, :, 3]
        visible = alpha > 32
        min_vis = 0.002 if "title_lockup" in rel else 0.02  # lockups are mostly transparent
        if visible.mean() < min_vis:
            failures.append(f"EMPTY-ALPHA {rel}: <{min_vis:.1%} visible pixels")
        elif visible.any():
            vis_lum = rgb[visible].mean()
            if vis_lum < 6:
                failures.append(f"NEAR-BLACK {rel}: visible-pixel lum={vis_lum:.1f}")
            print(f"ok  {rel:44s} {im.size} {im.mode} std={hist_std:5.1f} "
                  f"lum={mean_lum:5.1f} vis_lum={vis_lum:5.1f}")
            continue
    if mean_lum < 6:
        failures.append(f"NEAR-BLACK {rel}: mean lum={mean_lum:.1f}")
    print(f"ok  {rel:44s} {im.size} {im.mode} std={hist_std:5.1f} lum={mean_lum:5.1f}")

# extra PNGs present but not in manifest?
all_pngs = {
    os.path.relpath(p, ASSETS).replace(os.sep, "/")
    for p in glob.glob(os.path.join(ASSETS, "**", "*.png"), recursive=True)
}
unexpected = all_pngs - set(EXPECTED)
for u in sorted(unexpected):
    print(f"note  unexpected (not in verify manifest): {u}")

# contact sheets
sheet_dir = os.path.join(ROOT, "tools", "artgen", "sheets")
os.makedirs(sheet_dir, exist_ok=True)
sys.path.insert(0, HERE)
from contact_sheet import sheet  # noqa: E402

groups = {
    "portraits": "portraits/*.png",
    "erebus": "art/erebus7_*.png",
    "endings": "art/endings/*.png",
    "keyart": "art/keyart_*.png",
    "ui": "ui/*.png",
    "backgrounds_new": "backgrounds/bg_obs*.png",
}
made = []
for name, pat in groups.items():
    paths = sorted(glob.glob(os.path.join(ASSETS, pat)))
    if not paths:
        continue
    out = os.path.join(sheet_dir, f"sheet_{name}.png")
    sheet(paths, out, cols=min(3, len(paths)), upscale=1.6)
    made.append(out)

if failures:
    print("\nFAILURES:")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print(f"\nAll {len(EXPECTED)} assets verified. Sheets: {made}")
