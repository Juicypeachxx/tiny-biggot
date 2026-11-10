#!/usr/bin/env python3
"""The pieces of the Japanese-garden look (V2, his reference video of 10 Nov: a koi pond with
lily pads, a tiled-roof gate, shafts of light). Original pixels, drawn here: nothing is taken
from the video but the mood. Run from tiny_biggot_godot/: python3 tools/art/japan_look.py
Writes assets/graphics/jp_*.png; then tools/bake_atlas.sh."""
import numpy as np
from PIL import Image, ImageDraw
OUT = "assets/graphics/"
W, H = 448, 288
rs = np.random.RandomState(1107)

def hexc(h, a=255):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)

def noise(w, h, cells, seed):
    """Tileable value noise, 0..1."""
    r = np.random.RandomState(seed)
    out = np.zeros((h, w))
    amp = 1.0
    tot = 0.0
    for cx, cy in cells:
        g = r.rand(cy, cx)
        ys = np.arange(h) * cy / h
        xs = np.arange(w) * cx / w
        y0 = ys.astype(int); x0 = xs.astype(int)
        fy = ys - y0; fx = xs - x0
        fy = fy * fy * (3 - 2 * fy); fx = fx * fx * (3 - 2 * fx)
        y1 = (y0 + 1) % cy; x1 = (x0 + 1) % cx
        a = g[np.ix_(y0, x0)]; b = g[np.ix_(y0, x1)]; c = g[np.ix_(y1, x0)]; d = g[np.ix_(y1, x1)]
        out += amp * ((a * (1 - fx) + b * fx) * (1 - fy)[:, None] + (c * (1 - fx) + d * fx) * fy[:, None])
        tot += amp
        amp *= 0.5
    return out / tot

BAYER = np.array([[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]) / 16.0

def banded(v, levels, w=W, h=H):
    """Alpha in a few flat steps, with an ordered dither where two steps meet (pixel art, no blur)."""
    d = np.tile(BAYER, (h // 4 + 1, w // 4 + 1))[:h, :w]
    q = np.floor(v * levels + (d - 0.5) * 0.6)
    return np.clip(q / levels, 0, 1)

def white_alpha(a, name):
    im = np.zeros((a.shape[0], a.shape[1], 4), np.uint8)
    im[..., :3] = 255
    im[..., 3] = (a * 255).astype(np.uint8)
    Image.fromarray(im).save(OUT + name)

# The soft clouds in the water: drawn twice by the game (a light and a dark tint).
n = noise(W, H, [(4, 3), (8, 6), (16, 12)], 11)
n = np.clip((n - 0.45) * 3.2, 0, 1)
white_alpha(banded(n, 5) * 0.55, "jp_mottle.png")

# Dark towards the edges of the room.
yy, xx = np.mgrid[0:H, 0:W]
dx = np.abs(xx - W / 2) / (W / 2); dy = np.abs(yy - (H / 2 + 8)) / (H / 2)
v = np.clip((np.maximum(dx, dy) ** 2.2 + 0.5 * (dx * dx + dy * dy) - 0.45) * 1.1, 0, 1)
white_alpha(banded(v, 5) * 0.6, "jp_vignette.png")

# Shafts of light, slanting down to the right (the additive layer).
u = (xx * 0.80 - yy * 0.60)          # across the shafts
s = np.zeros((H, W))
for c, wd, st in [(-60, 34, 0.55), (40, 22, 0.8), (118, 50, 1.0), (236, 18, 0.5), (300, 40, 0.7)]:
    s = np.maximum(s, st * np.clip(1 - np.abs(u - c) / wd, 0, 1) ** 1.3)
s *= np.clip(1.15 - yy / H * 0.75, 0, 1) * (0.75 + 0.25 * noise(W, H, [(6, 4)], 5))
white_alpha(banded(s, 6) * 0.5, "jp_shafts.png")

# The top wall: a tiled roof over a timber front with lattice panels. 64 x 32, repeats.
im = Image.new("RGBA", (64, 32), hexc("#2b2338"))
d = ImageDraw.Draw(im)
tiles = ["#6b6383", "#746b8e", "#625a7a", "#7b7196", "#5c5473"]
for row in range(4):
    y = row * 5 - 1
    off = 0 if row % 2 == 0 else 3
    for i in range(-1, 12):
        x = i * 6 + off
        c = tiles[rs.randint(len(tiles))]
        d.rectangle([x, y, x + 5, y + 4], fill=hexc(c))
        d.line([x, y, x + 4, y], fill=hexc("#a699b8"))             # the lit top edge
        d.line([x + 5, y, x + 5, y + 4], fill=hexc("#463d5c"))       # the joint
        d.point([x, y + 4], fill=hexc("#463d5c")); d.point([x + 4, y + 4], fill=hexc("#463d5c"))  # rounded foot
d.rectangle([0, 18, 63, 18], fill=hexc("#a699b8"))    # the eave's edge
d.rectangle([0, 19, 63, 20], fill=hexc("#3a2f48"))
d.rectangle([0, 21, 63, 21], fill=hexc("#c9a24a"))    # a gilt beam
d.rectangle([0, 22, 63, 31], fill=hexc("#4a3628"))    # timber, in the eave's shadow
d.rectangle([0, 22, 63, 23], fill=hexc("#33241c"))
for px in (0, 32):                                     # posts
    d.rectangle([px, 21, px + 3, 31], fill=hexc("#8a6a4a"))
    d.line([px, 21, px, 31], fill=hexc("#b08a5a")); d.line([px + 3, 21, px + 3, 31], fill=hexc("#5e4532"))
# A lattice panel between the first pair of posts, plain boards between the second.
d.rectangle([8, 23, 27, 31], fill=hexc("#b88a50")); d.rectangle([9, 24, 26, 31], fill=hexc("#3a2a22"))
for x in range(11, 26, 3):
    d.line([x, 24, x, 31], fill=hexc("#b88a50"))
for y in (26, 29):
    d.line([9, y, 26, y], fill=hexc("#b88a50"))
for x in range(38, 62, 5):
    d.line([x, 23, x, 31], fill=hexc("#3a2a22"))
d.line([36, 26, 63, 26], fill=hexc("#5e4532"))
im.save(OUT + "jp_roof.png")

# The banks: mossy garden stones, four 16 x 16 pieces in a row (64 x 16).
im = Image.new("RGBA", (64, 16), hexc("#16233f"))
d = ImageDraw.Draw(im)
for k in range(4):
    x0 = k * 16
    for (x, y, w, h) in [(0, 1, 9, 7), (8, 0, 8, 6), (1, 8, 7, 7), (7, 6, 9, 9)][:: 1 if k % 2 == 0 else -1]:
        x += rs.randint(-1, 2); y += rs.randint(0, 2)
        base = ["#57506c", "#4c4662", "#625a78"][rs.randint(3)]
        d.ellipse([x0 + x, y, x0 + x + w - 1, y + h - 1], fill=hexc(base), outline=hexc("#241d33"))
        d.line([x0 + x + 2, y + 1, x0 + x + w - 3, y + 1], fill=hexc("#8f86a8"))
        if rs.rand() < 0.6:                              # moss on top
            d.line([x0 + x + 2, y, x0 + x + w - 3, y], fill=hexc("#6c9a4a"))
            d.point([x0 + x + 3, y + 1], fill=hexc("#8fc24f"))
im = im.crop((0, 0, 64, 16))
im.save(OUT + "jp_bank.png")

# Lily pads and lotus: a row of 12 x 12 cells (pad, pad, pad with a bud, pad with a lotus, lotus, small pad).
im = Image.new("RGBA", (72, 12), (0, 0, 0, 0))
d = ImageDraw.Draw(im)
def pad(cx, x, y, w, h, notch):
    d.ellipse([cx + x, y + 1, cx + x + w - 1, y + h], fill=hexc("#17304f", 150))      # its shade on the water
    d.ellipse([cx + x, y, cx + x + w - 1, y + h - 1], fill=hexc("#5ea646"), outline=hexc("#3c7a3a"))
    d.arc([cx + x + 1, y + 1, cx + x + w - 2, y + h - 2], 180, 300, fill=hexc("#9bd35c"))
    mx, my = cx + x + w // 2, y + h // 2
    ex, ey = notch
    d.line([mx, my, mx + ex, my + ey], fill=hexc("#2f5f86"))
    d.point([mx, my], fill=hexc("#3c7a3a"))
def lotus(x, y):
    for (ox, oy) in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
        d.point([x + ox, y + oy], fill=hexc("#f0a8a0"))
    d.point([x - 1, y - 1], fill=hexc("#f7d0c8")); d.point([x + 1, y - 1], fill=hexc("#f7d0c8"))
    d.point([x, y], fill=hexc("#f2c94c"))
pad(0, 1, 1, 10, 9, (4, 3)); pad(12, 1, 2, 9, 8, (-4, 2)); pad(24, 1, 1, 10, 9, (3, -4)); d.point([24 + 7, 6], fill=hexc("#f0a8a0"))
pad(36, 1, 1, 10, 9, (4, 3)); lotus(36 + 5, 5)
lotus(48 + 5, 6); d.point([48 + 5, 8], fill=hexc("#17304f", 150))
pad(60, 3, 3, 6, 5, (2, 2))
im.save(OUT + "jp_pads.png")
print("ok")
