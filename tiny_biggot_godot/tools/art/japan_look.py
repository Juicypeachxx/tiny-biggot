#!/usr/bin/env python3
"""The pieces of the Japanese-garden look (V2, his reference video of 10 Nov: a koi pond with
lily pads, a tiled-roof gate, shafts of light). Original pixels, drawn here: nothing is taken
from the video but the mood. Run from tiny_biggot_godot/: python3 tools/art/japan_look.py
Writes assets/graphics_hd/jp_*.png at double detail (two pixels to one of the game's); then
tools/bake_atlas.sh. The gate and the props are SpriteCook's (resprite/tools/koi_cut.py)."""
import numpy as np
from PIL import Image, ImageDraw
OUT = "assets/graphics_hd/"
W, H = 896, 576
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
white_alpha(banded(n, 8) * 0.55, "jp_mottle.png")

# Dark towards the edges of the room.
yy, xx = np.mgrid[0:H, 0:W]
dx = np.abs(xx - W / 2) / (W / 2); dy = np.abs(yy - (H / 2 + 8)) / (H / 2)
v = np.clip((np.maximum(dx, dy) ** 2.2 + 0.5 * (dx * dx + dy * dy) - 0.45) * 1.1, 0, 1)
white_alpha(banded(v, 8) * 0.6, "jp_vignette.png")

# Shafts of light, slanting down to the right (the additive layer).
u = (xx * 0.80 - yy * 0.60) / 2.0          # across the shafts
s = np.zeros((H, W))
for c, wd, st in [(-60, 34, 0.55), (40, 22, 0.8), (118, 50, 1.0), (236, 18, 0.5), (300, 40, 0.7)]:
    s = np.maximum(s, st * np.clip(1 - np.abs(u - c) / wd, 0, 1) ** 1.3)
s *= np.clip(1.15 - yy / H * 0.75, 0, 1) * (0.75 + 0.25 * noise(W, H, [(6, 4)], 5))
white_alpha(banded(s, 9) * 0.5, "jp_shafts.png")

# The top wall: a tiled roof over a timber front with lattice panels. 128 x 64, repeats.
im = Image.new("RGBA", (128, 64), hexc("#241b30"))
d = ImageDraw.Draw(im)
tiles = ["#5f4f78", "#685882", "#57486e", "#70608c", "#514366"]
for row in range(4):
    y = row * 10 - 3
    off = 0 if row % 2 == 0 else 6
    for i in range(-1, 12):
        x = i * 12 + off
        c = tiles[rs.randint(len(tiles))]
        d.rounded_rectangle([x, y, x + 11, y + 10], 3, fill=hexc(c), outline=hexc("#32263f"))
        d.line([x + 2, y + 1, x + 9, y + 1], fill=hexc("#9484b0"))       # the lit top edge
        d.line([x + 2, y + 2, x + 5, y + 2], fill=hexc("#8171a0"))
        d.line([x + 3, y + 8, x + 8, y + 8], fill=hexc("#463858"))       # the foot, in shade
d.rectangle([0, 36, 127, 37], fill=hexc("#9484b0"))    # the eave's edge
d.rectangle([0, 38, 127, 41], fill=hexc("#32263f"))
d.rectangle([0, 42, 127, 44], fill=hexc("#d09a34"))    # a gilt beam
d.line([0, 42, 127, 42], fill=hexc("#f0c45a"))
d.rectangle([0, 45, 127, 63], fill=hexc("#4a3020"))    # timber, in the eave's shadow
d.rectangle([0, 45, 127, 47], fill=hexc("#2e1c14"))
for px in (0, 64):                                     # posts
    d.rectangle([px, 42, px + 7, 63], fill=hexc("#c8922e"))
    d.line([px + 1, 42, px + 1, 63], fill=hexc("#f0c45a")); d.rectangle([px + 6, 42, px + 7, 63], fill=hexc("#8a5a1c"))
    d.rectangle([px, 42, px + 7, 42], fill=hexc("#f0c45a"))
# A lattice panel between the first pair of posts, plain boards between the second.
d.rectangle([16, 47, 55, 63], fill=hexc("#c8922e")); d.rectangle([18, 49, 53, 63], fill=hexc("#2e1c14"))
for x in range(22, 53, 5):
    d.line([x, 49, x, 63], fill=hexc("#9a6a24"))
for y in (53, 58):
    d.line([18, y, 53, y], fill=hexc("#9a6a24"))
for x in range(76, 124, 10):
    d.line([x, 47, x, 63], fill=hexc("#2e1c14")); d.line([x + 1, 47, x + 1, 63], fill=hexc("#5e3e28"))
d.line([72, 53, 127, 53], fill=hexc("#5e3e28"))
im.save(OUT + "jp_roof.png")

# The banks: mossy garden stones, four 32 x 32 pieces in a row (128 x 32).
im = Image.new("RGBA", (128, 32), hexc("#101a33"))
d = ImageDraw.Draw(im)
for k in range(4):
    x0 = k * 32
    for (x, y, w, h) in [(0, 2, 18, 14), (16, 0, 16, 12), (2, 16, 14, 14), (14, 12, 18, 18)][:: 1 if k % 2 == 0 else -1]:
        x += rs.randint(-2, 3); y += rs.randint(0, 3)
        base = ["#6a6478", "#5c5669", "#787286"][rs.randint(3)]
        d.ellipse([x0 + x, y, x0 + x + w - 1, y + h - 1], fill=hexc(base), outline=hexc("#1c1628"))
        d.arc([x0 + x + 2, y + 2, x0 + x + w - 3, y + h - 3], 200, 320, fill=hexc("#a8a2b6"))
        d.arc([x0 + x + 1, y + 1, x0 + x + w - 2, y + h - 2], 20, 150, fill=hexc("#454053"))
        if rs.rand() < 0.65:                              # moss on top
            d.arc([x0 + x + 1, y, x0 + x + w - 2, y + h - 1], 215, 325, fill=hexc("#5f9a40"), width=2)
            d.point([x0 + x + w // 2, y + 1], fill=hexc("#9bd35c")); d.point([x0 + x + w // 2 - 3, y + 2], fill=hexc("#9bd35c"))
im.save(OUT + "jp_bank.png")

# Lily pads and lotus: a row of 24 x 24 cells (pad, pad, pad with a bud, pad with a lotus, lotus, small pad).
im = Image.new("RGBA", (144, 24), (0, 0, 0, 0))
d = ImageDraw.Draw(im)
def pad(cx, x, y, w, h, ang):
    d.ellipse([cx + x + 1, y + 3, cx + x + w, y + h + 2], fill=hexc("#10264a", 140))      # its shade on the water
    d.ellipse([cx + x, y, cx + x + w - 1, y + h - 1], fill=hexc("#58a644"), outline=hexc("#2c6a34"))
    d.ellipse([cx + x + 3, y + 3, cx + x + w - 5, y + h - 5], fill=hexc("#6cba4c"))
    d.arc([cx + x + 2, y + 2, cx + x + w - 3, y + h - 3], 190, 300, fill=hexc("#a6dc64"))
    mx, my = cx + x + w / 2.0, y + h / 2.0
    for da in (-0.9, 0.9, 2.2, 3.6, 4.6):                   # veins
        d.line([mx, my, mx + np.cos(ang + da) * w * 0.36, my + np.sin(ang + da) * h * 0.36], fill=hexc("#479240"))
    d.pieslice([cx + x - 1, y - 1, cx + x + w, y + h], np.degrees(ang) - 13, np.degrees(ang) + 13, fill=(0, 0, 0, 0))   # the notch
def lotus(x, y):
    for a in range(8):
        px, py = x + np.cos(a * np.pi / 4) * 3.2, y + np.sin(a * np.pi / 4) * 2.6
        d.ellipse([px - 1.6, py - 1.6, px + 1.6, py + 1.6], fill=hexc("#f29a9a" if a % 2 else "#f7c4c0"), outline=hexc("#c46a78"))
    d.ellipse([x - 1.5, y - 1.5, x + 1.5, y + 1.5], fill=hexc("#f7d0c8"))
    d.point([x, y], fill=hexc("#f2c94c"))
pad(0, 2, 2, 20, 18, 0.6); pad(24, 3, 4, 18, 16, 2.6); pad(48, 2, 2, 20, 18, -1.0); d.ellipse([48 + 12, 9, 48 + 15, 12], fill=hexc("#f29a9a"), outline=hexc("#c46a78"))
pad(72, 2, 2, 20, 18, 0.6); lotus(72 + 11, 10)
d.ellipse([96 + 7, 12, 96 + 17, 19], fill=hexc("#10264a", 140)); lotus(96 + 12, 12)
pad(120, 6, 7, 12, 10, 1.8)
im.save(OUT + "jp_pads.png")

# Stepping stones: two flat stones, 24 x 20 each (48 x 20).
im = Image.new("RGBA", (48, 20), (0, 0, 0, 0))
d = ImageDraw.Draw(im)
for k, (w, h) in enumerate([(22, 14), (19, 13)]):
    x0 = k * 24 + (24 - w) // 2
    d.ellipse([x0 + 1, 5, x0 + w, 5 + h], fill=hexc("#0c1c3c", 150))            # shade in the water
    d.ellipse([x0, 2, x0 + w - 1, 2 + h - 1], fill=hexc("#5c5669"), outline=hexc("#1c1628"))
    d.ellipse([x0 + 1, 2, x0 + w - 2, 2 + h - 4], fill=hexc("#8d879c"), outline=hexc("#6a6478"))
    d.arc([x0 + 3, 3, x0 + w - 4, 2 + h - 6], 190, 300, fill=hexc("#b8b2c6"))
    d.point([x0 + w // 2 + 3, 8], fill=hexc("#6a6478")); d.point([x0 + w // 2 - 4, 10], fill=hexc("#6a6478"))
    if k == 0:
        d.line([x0 + 3, 9, x0 + 6, 11], fill=hexc("#5f9a40")); d.point([x0 + 4, 9], fill=hexc("#9bd35c"))
im.save(OUT + "jp_step.png")

# A flat bridge running left to right, one tile (32 x 40: its rails stand above and below the tile).
im = Image.new("RGBA", (32, 40), (0, 0, 0, 0))
d = ImageDraw.Draw(im)
d.rectangle([0, 37, 31, 39], fill=hexc("#0c1c3c", 140))                       # shade on the water
d.rectangle([0, 6, 31, 35], fill=hexc("#8a5a34"))
for x in range(0, 32, 8):                                                     # planks
    d.line([x, 6, x, 35], fill=hexc("#4a2c18")); d.line([x + 1, 6, x + 1, 35], fill=hexc("#a8744a"))
    d.point([x + 4, 12 + (x % 16)], fill=hexc("#6a4426"))
for y in (2, 32):                                                             # red rails
    d.rectangle([0, y, 31, y + 4], fill=hexc("#c8362c"), outline=hexc("#5a1410"))
    d.line([1, y + 1, 30, y + 1], fill=hexc("#f0685a"))
for y in (0, 30):                                                             # a post on each rail
    d.rectangle([13, y, 18, y + 8], fill=hexc("#a82a22"), outline=hexc("#5a1410"))
    d.rectangle([13, y, 18, y + 1], fill=hexc("#2a2230"))
im.save(OUT + "jp_plank.png")
print("ok")
