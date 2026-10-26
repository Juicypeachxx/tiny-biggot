"""Stage 60 preview: the 16 new weapons and 4 effects at the game's real size, beside today's."""
import os, sys
import numpy as np
from PIL import Image, ImageDraw
sys.path.insert(0, "/home/user/tiny-biggot/resprite/tools")
import pixel_look
from sheet_cut import blobs

HERE = os.path.dirname(os.path.abspath(__file__))
HD = "/home/user/tiny-biggot/tiny_biggot_godot/assets/graphics_hd/"
BG = np.array([28, 21, 36])
GAME_BG = (26, 20, 35, 255)
NAMES = ["IRON SLAB", "IRON HAND CANNON", "CRANK REPEATER", "SILVER OATH", "SIGNWEAVER'S HAND",
         "STARFIRE BOMB", "HALLOWED GRENADE", "BUNCH BOMB", "WOOLLY WARHEAD", "CRIMSON RUSH",
         "SUPLEX GAUNTLETS", "STORMCALLER SPEAR", "SHARKMOUTH", "GALE KATANA", "BLOODSPIN AXE",
         "TRUESHOT GAUNTLET"]
OLD = ["w_halberd", "w_pike", "w_huntbow", "w_mirrorblade", "w_dashblade", "w_grapple", "w_bottlerockets",
       "w_cometlance", "w_bloodvine", "w_emberorb", "w_abyssstaff", "w_chaoscodex", "w_flashcamera",
       "w_jugglepins", "w_fireflyjar", "w_orrery"]

def key(im, lo=22, hi=52):
    a = np.asarray(im.convert("RGB")).astype(int)
    d = np.sqrt(((a - BG) ** 2).sum(-1))
    alpha = np.clip((d - lo) * 255.0 / (hi - lo), 0, 255).astype(np.uint8)
    return Image.fromarray(np.dstack([a.astype(np.uint8), alpha]), "RGBA")

def weapons():
    sheet = key(Image.open(os.path.join(HERE, "weapons_sheet.png")))
    small = sheet.resize((512, 512), Image.BOX)
    cells = {}
    for b in blobs(small, 4):
        nb = b[:4]
        cx, cy = (nb[0] + nb[2]) / 2, (nb[1] + nb[3]) / 2
        c = int(cy // 128) * 4 + int(cx // 128)
        box = cells.get(c)
        cells[c] = nb if box is None else (min(box[0], nb[0]), min(box[1], nb[1]), max(box[2], nb[2]), max(box[3], nb[3]))
    out = []
    for c in range(16):
        x0, y0, x1, y1 = [v * 4 for v in cells[c]]
        if c == 15:   # the gauntlet's ring of rune-like marks reads as letters: keep the hand only
            x0, y0, x1, y1 = x0 + int((x1 - x0) * 0.16), y0 + int((y1 - y0) * 0.16), x1 - int((x1 - x0) * 0.12), y1 - int((y1 - y0) * 0.04)
        crop = sheet.crop((x0, y0, x1, y1))
        k = 20.0 / max(crop.size)
        sm = crop.resize((max(1, round(crop.width * k)), max(1, round(crop.height * k))), Image.BOX)
        a = np.asarray(sm).copy()
        a[..., 3] = np.where(a[..., 3] >= 110, 255, 0)
        sm = Image.fromarray(a, "RGBA")
        canvas = Image.new("RGBA", (24, 24), (0, 0, 0, 0))
        canvas.alpha_composite(sm, ((24 - sm.width) // 2, (24 - sm.height) // 2))
        px = int((np.asarray(canvas)[..., 3] >= 128).sum()) // 4
        out.append(pixel_look.sprite(canvas, "w_new%d" % c, px))
    return out

def grid(pics, z, cols, title, cell=None):
    cell = cell or (24 * z + 16)
    rows = (len(pics) + cols - 1) // cols
    im = Image.new("RGBA", (cols * cell + 16, rows * cell + 40), GAME_BG)
    d = ImageDraw.Draw(im)
    d.text((10, 10), title, fill=(240, 230, 200, 255))
    for i, p in enumerate(pics):
        big = p.resize((p.width * z, p.height * z), Image.NEAREST)
        x = 8 + (i % cols) * cell + (cell - big.width) // 2
        y = 32 + (i // cols) * cell + (cell - big.height) // 2
        im.alpha_composite(big, (x, y))
    return im

def effects():
    sheet = key(Image.open(os.path.join(HERE, "effects_sheet.png")), 18, 40)
    floor = Image.open(HD + "kit0_floor.png").convert("RGBA")
    hero = Image.open(HD + "brute.png").convert("RGBA") if os.path.exists(HD + "brute.png") else None
    z, fs = 3, 64                     # each frame 64 of the game's double-detail pixels, shown x3
    W = 4 * fs * z + 5 * 12
    rows = []
    for r in range(4):
        strip = Image.new("RGBA", (W, fs * z + 24), GAME_BG)
        for f in range(4):
            tile = Image.new("RGBA", (fs, fs))
            for ty in range(0, fs, floor.height):
                for tx in range(0, fs, floor.width):
                    tile.alpha_composite(floor, (tx, ty))
            if hero is not None and f == 0:
                tile.alpha_composite(hero, (2, fs - hero.height - 2))
            fr = sheet.crop((f * 512, r * 512, f * 512 + 512, r * 512 + 512)).resize((fs, fs), Image.BOX)
            tile.alpha_composite(fr)
            strip.alpha_composite(tile.resize((fs * z, fs * z), Image.NEAREST), (12 + f * (fs * z + 12), 12))
        rows.append(strip)
    out = Image.new("RGBA", (W, sum(s.height for s in rows) + 30), GAME_BG)
    ImageDraw.Draw(out).text((12, 8), "EFFECTS AT GAME SIZE (x3), ON A FLOOR, A HERO FOR SCALE", fill=(240, 230, 200, 255))
    y = 30
    for s in rows:
        out.alpha_composite(s, (0, y))
        y += s.height
    return out

new = weapons()
old = [Image.open(HD + n + ".png").convert("RGBA") for n in OLD]
a = grid(old, 4, 4, "TODAY'S WEAPONS (V2), x4")
b = grid(new, 4, 4, "THE 16 NEW ONES, SAME SIZE, x4")
c = grid(new, 1, 16, "REAL SIZE x1", 30)
both = Image.new("RGBA", (a.width + b.width + 12, max(a.height, b.height) + c.height + 8), GAME_BG)
both.alpha_composite(a, (0, 0))
both.alpha_composite(b, (a.width + 12, 0))
both.alpha_composite(c, (0, max(a.height, b.height) + 8))
both.convert("RGB").save(os.path.join(HERE, "preview_weapons.png"))
for i, p in enumerate(new):
    p.save(os.path.join(HERE, "new_%02d.png" % i))
effects().convert("RGB").save(os.path.join(HERE, "preview_effects.png"))
print("ok")
