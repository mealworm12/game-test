"""Contact sheet builder for visual inspection (upscaled montages)."""
import glob
import os
import sys

from PIL import Image, ImageDraw, ImageFont

CELL = 320


def sheet(paths, out_path, cols=4, upscale=1.0):
    font = ImageFont.load_default()
    rows = (len(paths) + cols - 1) // cols
    W, H = cols * CELL, rows * (CELL + 22)
    sh = Image.new("RGB", (W, H), (18, 18, 24))
    dr = ImageDraw.Draw(sh)
    for i, p in enumerate(paths):
        im = Image.open(p).convert("RGBA")
        im.thumbnail((CELL - 8, CELL - 8))
        bg = Image.new("RGBA", (CELL, CELL), (30, 34, 46, 255))
        bg.paste(im, ((CELL - im.width) // 2, (CELL - im.height) // 2), im)
        x = (i % cols) * CELL
        y = (i // cols) * (CELL + 22)
        sh.paste(bg.convert("RGB"), (x, y))
        dr.text((x + 6, y + CELL + 4), os.path.basename(p), fill=(220, 230, 240), font=font)
    if upscale != 1.0:
        sh = sh.resize((int(W * upscale), int(H * upscale)), Image.LANCZOS)
    sh.save(out_path, "PNG")
    print("sheet:", out_path, sh.size)


if __name__ == "__main__":
    pattern = sys.argv[1]
    out = sys.argv[2]
    cols = int(sys.argv[3]) if len(sys.argv) > 3 else 4
    paths = sorted(glob.glob(pattern))
    assert paths, "no files: " + pattern
    sheet(paths, out, cols)
