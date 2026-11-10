"""A better shrink for the preview: the sheet's colours first (k-means), then each small pixel takes
the colour most of its block has (no averaging into mud), brighter, and V2's outline."""
import os, sys
import numpy as np
from PIL import Image, ImageDraw
sys.path.insert(0, "/home/user/tiny-biggot/resprite/tools")
import pixel_look
from sheet_cut import blobs
from preview import key, grid, OLD, HD, GAME_BG

HERE = os.path.dirname(os.path.abspath(__file__))

def mode_shrink(crop, size):
    rgba = np.asarray(crop)
    idx, pal = pixel_look.quantize(rgba, 14, 7)
    H, W = idx.shape
    k = size / max(H, W)
    h, w = max(1, round(H * k)), max(1, round(W * k))
    out = np.full((h, w), -1, int)
    for y in range(h):
        for x in range(w):
            blk = idx[int(y / k):max(int(y / k) + 1, int((y + 1) / k)), int(x / k):max(int(x / k) + 1, int((x + 1) / k))].ravel()
            op = blk[blk >= 0]
            if len(op) >= 0.45 * len(blk):
                out[y, x] = np.bincount(op).argmax()
    img = np.zeros((h, w, 4), np.uint8)
    pal = pixel_look.punch(pal, 1.15, 0.8)
    img[out >= 0, :3] = np.clip(pal[out[out >= 0]], 0, 255)
    img[out >= 0, 3] = 255
    return Image.fromarray(img, "RGBA")

def weapons(inner, box):
    sheet = key(Image.open(os.path.join(HERE, "weapons_sheet.png")))
    small = sheet.resize((512, 512), Image.BOX)
    cells = {}
    for b in blobs(small, 4):
        nb = b[:4]
        c = int(((nb[1] + nb[3]) / 2) // 128) * 4 + int(((nb[0] + nb[2]) / 2) // 128)
        o = cells.get(c)
        cells[c] = nb if o is None else (min(o[0], nb[0]), min(o[1], nb[1]), max(o[2], nb[2]), max(o[3], nb[3]))
    out = []
    for c in range(16):
        x0, y0, x1, y1 = [v * 4 for v in cells[c]]
        if c == 15:
            x0, y0, x1, y1 = x0 + int((x1 - x0) * 0.16), y0 + int((y1 - y0) * 0.16), x1 - int((x1 - x0) * 0.12), y1 - int((y1 - y0) * 0.04)
        sm = mode_shrink(sheet.crop((x0, y0, x1, y1)), inner)
        canvas = Image.new("RGBA", (box, box), (0, 0, 0, 0))
        canvas.alpha_composite(sm, ((box - sm.width) // 2, (box - sm.height) // 2))
        px = int((np.asarray(canvas)[..., 3] >= 128).sum()) // 4
        out.append(pixel_look.sprite(canvas, "w_new%d" % c, px))
    return out

old = [Image.open(HD + n + ".png").convert("RGBA") for n in OLD]
n24 = weapons(20, 24)
n32 = weapons(28, 32)
a = grid(old, 4, 4, "TODAY'S WEAPONS (V2), x4", 24 * 4 + 16)
b = grid(n24, 4, 4, "NEW, SAME SIZE AS TODAY'S, x4", 24 * 4 + 16)
c = grid(n32, 4, 4, "NEW, A THIRD BIGGER (LEGENDARY), x4", 32 * 4 + 16)
im = Image.new("RGBA", (a.width + b.width + c.width + 24, max(a.height, b.height, c.height)), GAME_BG)
im.alpha_composite(a, (0, 0))
im.alpha_composite(b, (a.width + 12, 0))
im.alpha_composite(c, (a.width + b.width + 24, 0))
im.convert("RGB").save(os.path.join(HERE, "preview_weapons2.png"))
print("ok")
