"""Stage 61 (his plan, 27 Oct: "with pixle lab you will start with maps and enviroments first"): a
floor's own pictures made on PixelLab, made ready for the game. The pictures as they came, and the
words they were made from (prompts.json), are in resprite/pixellab/<kit>/.
    python3 resprite/tools/pl_kit.py kit0          -> tiny_biggot_godot/assets/graphics_hd/kit0_*.png
    python3 resprite/tools/pl_kit.py kit0 REVIEW.png  -> and a review sheet (everything, four times)
What it writes (two of the picture's pixels to one of the game's; world_view.gd and biome_deco.gd
draw them, only when they are there):
  <kit>_tiles     128 x 128: 16 floor slabs, a tile each (4 x 4); the last row are the rare ones
  <kit>_wallface  the top wall in panels of 4 x 2 tiles side by side: the plain one first
  <kit>_pilaster  a column, 1 x 2 tiles, put over the joins between the panels
  <kit>_walls     256 x 64: the tops of the side and bottom walls, a tile each: left x 4, right x 4
                  (row 0), bottom x 4, the two bottom corners (row 1)
  <kit>_<prop>    the floor's props and wall dressing, each cropped to what it shows
  <kit>_decals    small things lying on the floor, a tile each in one row (BiomeDeco.PIC_DECALS
                  says which kind each is)
PixelLab draws in a palette of its own each time: recolour() moves green-blue stone to the floor's
hue, so the walls and the floor are one place."""
import colorsys, json, os, sys
import numpy as np
from PIL import Image
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sheet_cut import blobs

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
RAW = os.path.join(ROOT, "resprite", "pixellab")
OUT = os.path.join(ROOT, "tiny_biggot_godot", "assets", "graphics_hd")
T = 32          # a tile, in the picture's pixels

def load(kit, name):
    return Image.open(os.path.join(RAW, kit, name + ".png")).convert("RGBA")

def recolour(im, hue, sat=0.75, lo=0.0, hi=1.0, light=1.0):
    """Stone of any hue between lo and hi (0-1, the hue circle) takes `hue`, its saturation times
    `sat` and its lightness times `light`; warm things (flames, bones, wood, rust) keep their colour.
    No hue: the picture as it was drawn (only `light`)."""
    if hue is None:
        if light == 1.0:
            return im
        a = np.array(im).astype(float)
        a[:, :, :3] = np.clip(a[:, :, :3] * light, 0, 255)
        return Image.fromarray(a.round().astype(np.uint8), "RGBA")
    a = np.array(im).astype(float)
    out = a.copy()
    for y in range(a.shape[0]):
        for x in range(a.shape[1]):
            r, g, b, al = a[y, x]
            if al == 0:
                continue
            h, l, s = colorsys.rgb_to_hls(r / 255, g / 255, b / 255)
            if not (lo <= h <= hi) or s > 0.6:
                continue
            nr, ng, nb = colorsys.hls_to_rgb(hue, min(1.0, l * light), s * sat)
            out[y, x, :3] = [nr * 255, ng * 255, nb * 255]
    return Image.fromarray(out.round().astype(np.uint8), "RGBA")

def crop_even(im, box=None, w=None, bottom=True):
    """Cropped to what it shows (or `box`), an even height and width (the game draws it at half),
    `w` wide if given (centred)."""
    box = box or im.getbbox()
    c = im.crop(box)
    cw = w or c.width + c.width % 2
    ch = c.height + c.height % 2
    out = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))
    out.alpha_composite(c, ((cw - c.width) // 2, ch - c.height if bottom else 0))
    return out

def calm(im, keep=0.6, light=1.12, joint=None, sat=1.0):
    """A floor quieter than PixelLab draws it, so what moves on it stands out: each colour nearer
    the picture's mean (`keep` of its difference), a little lighter, the black joints a dark shade
    of the floor's own colour (or `joint`), its colours `sat` as strong."""
    a = np.array(im).astype(float)
    rgb = a[:, :, :3]
    black = rgb.sum(2) < 30
    mean = rgb.reshape(-1, 3).mean(0)
    if joint is None:
        joint = tuple(mean * 0.42)
    if sat != 1.0:
        grey = rgb.mean(2, keepdims=True)
        rgb = grey + (rgb - grey) * sat
    rgb = np.clip((mean + (rgb - mean) * keep) * light, 0, 255)
    rgb[black] = joint
    a[:, :, :3] = rgb
    return Image.fromarray(a.round().astype(np.uint8), "RGBA")

def grid_ok(im):
    """True when the sheet's joints run along the tile grid: the rows (or columns) at the three
    inner tile edges are among the sheet's darkest."""
    a = np.array(im.convert("RGB")).astype(float)
    lum = (a * [0.299, 0.587, 0.114]).sum(2)
    for prof in (lum.mean(1), lum.mean(0)):
        # dark joints, or bright ones (the Cinderforge's lava): far from the sheet's mean
        dev = [max(abs(prof[k * T - 2:k * T + 2] - prof.mean())) for k in (1, 2, 3)]
        if min(dev) > prof.std():
            return True
    return False

def tiles(kit, sheet, rare=4):
    """16 slabs cut on the tile grid, the busiest (bones, moss, the most cracks) last."""
    im = load(kit, sheet)
    if not grid_ok(im):
        print("  WARNING: %s/%s is not a 4 x 4 grid of slabs" % (kit, sheet))
    a = np.array(im.convert("RGB")).astype(int)
    cells = []
    for i in range(16):
        tx, ty = i % 4, i // 4
        t = a[ty * T:ty * T + T, tx * T:tx * T + T]
        lum = (t * [0.299, 0.587, 0.114]).sum(2)
        green = ((t[:, :, 1] > t[:, :, 0] + 15) & (t[:, :, 1] > t[:, :, 2] + 5)).mean()
        score = (lum > 165).mean() * 40 + green * 20 + (lum < 45).mean()
        cells.append([score, i, im.crop((tx * T, ty * T, tx * T + T, ty * T + T)), t.reshape(-1, 3).mean(0)])
    # the plainest and most like the rest first: the game lays the first 8 most (80 in 100), the
    # next 4 less (14), the last 4 rarely (6) (world_view.gd _paint_place)
    middle = np.median([c[3] for c in cells], axis=0)
    for c in cells:
        c[0] += np.abs(c[3] - middle).sum() / 48.0
    cells.sort(key=lambda c: c[0])
    out = Image.new("RGBA", (4 * T, 4 * T))
    for k, (score, i, cell, _) in enumerate(cells):
        # every slab meets the next the same way: a joint along its left edge, as inside the sheet
        px = cell.load()
        for y in range(T):
            if sum(px[1, y][:3]) > 3 * 60:
                px[0, y] = (0, 0, 0, 255)
        out.paste(cell, ((k % 4) * T, (k // 4) * T))
    return out

def wallface(kit, panels, hue):
    """The top wall's panels side by side, recoloured."""
    ims = [recolour(load(kit, p), hue, lo=0.2, hi=0.75) for p in panels]
    out = Image.new("RGBA", (sum(i.width for i in ims), 2 * T))
    x = 0
    for i in ims:
        out.paste(i, (x, 0))
        x += i.width
    return out

def _grow(m, n):
    """The mask grown (n > 0) or shrunk (n < 0) by n pixels, the eight around each counted."""
    for _ in range(abs(n)):
        p = np.pad(m, 1, constant_values=n < 0)
        sh = [p[1 + dy:1 + dy + m.shape[0], 1 + dx:1 + dx + m.shape[1]] for dy in (-1, 0, 1) for dx in (-1, 0, 1)]
        m = np.logical_or.reduce(sh) if n > 0 else np.logical_and.reduce(sh)
    return m

def pilaster(kit, name, hue):
    """The column alone, 1 x 2 tiles: lines one pixel thin around it (the bricks behind it) go."""
    im = recolour(load(kit, name), hue, lo=0.0, hi=1.0, sat=0.5)
    a = np.array(im)
    solid = a[:, :, 3] > 0
    keep = solid & _grow(_grow(solid, -1), 1)
    a[:, :, 3] = np.where(keep, a[:, :, 3], 0)
    im = Image.fromarray(a, "RGBA")
    return crop_even(im, (im.getbbox()[0], 0, im.getbbox()[2], im.height), w=T)

def walls(kit, name, hue, rows=None):
    """Tops of the side and bottom walls from a stone texture: dark, a lit lip on the room's side,
    a black line where the wall drops to the floor."""
    tex = recolour(load(kit, name), hue, lo=0.0, hi=1.0, sat=0.6, light=0.7)
    if rows:
        tex = tex.crop((0, rows[0], tex.width, rows[1]))
    a = np.array(tex).astype(float)
    a[:, :, :3] *= 0.62
    tex = Image.fromarray(a.round().astype(np.uint8), "RGBA")
    lip = (118, 102, 112, 255)
    dark = (8, 5, 12, 255)
    spots = [(0, 0), (T, 0), (0, T // 2), (T // 2, T // 4)]     # four different cuts of the texture
    for k, (sx, sy) in enumerate(spots):
        sx = min(sx, tex.width - T)
        sy = min(sy, tex.height - T)
        cell = tex.crop((sx, sy, sx + T, sy + T))
        left = cell.copy()      # the room is to its right
        right = cell.transpose(Image.FLIP_LEFT_RIGHT)
        bottom = cell.transpose(Image.ROTATE_90)    # the room is above it
        for i in range(T):
            left.putpixel((T - 1, i), dark)
            left.putpixel((T - 2, i), lip)
            left.putpixel((T - 3, i), lip)
            right.putpixel((0, i), dark)
            right.putpixel((1, i), lip)
            right.putpixel((2, i), lip)
            bottom.putpixel((i, 0), dark)
            bottom.putpixel((i, 1), lip)
            bottom.putpixel((i, 2), lip)
        yield k, {"left": left, "right": right, "bottom": bottom}

def build_walls(kit, name, hue, rows=None):
    """Row 0: left x 4, right x 4; row 1: bottom x 4, the bottom-left and bottom-right corners."""
    out = Image.new("RGBA", (8 * T, 2 * T))
    first = None
    for k, cells in walls(kit, name, hue, rows):
        out.paste(cells["left"], (k * T, 0))
        out.paste(cells["right"], ((4 + k) * T, 0))
        out.paste(cells["bottom"], (k * T, T))
        first = first or cells
    # the corners are wall top all through: the lips of the side and the bottom walls end there
    a = np.array(first["left"]).copy()
    a[:, T - 3:] = np.array(first["left"])[:, T - 6:T - 3]
    out.paste(Image.fromarray(a, "RGBA"), (4 * T, T))
    out.paste(Image.fromarray(a, "RGBA").transpose(Image.FLIP_LEFT_RIGHT), (5 * T, T))
    return out

def pick_decals(im, most=8):
    """The separate things on a sheet that fit a tile (not touching its edge, not tiny), the biggest
    first, each a group of its own."""
    bs = blobs(im)
    ok = [(b[4], i) for i, b in enumerate(bs) if 24 <= b[4] and b[2] - b[0] < T - 2 and b[3] - b[1] < T - 2
          and b[0] > 0 and b[1] > 0 and b[2] < im.width - 1 and b[3] < im.height - 1]
    ok.sort(reverse=True)
    return [[i] for _, i in ok[:most]]

def decals(kit, name, groups, hue):
    """The picked blobs of a sheet of small things, a tile each, in one row (a group of blobs is one
    thing: the bits of a broken bone). No groups: pick_decals."""
    im = recolour(load(kit, name), hue, lo=0.45, hi=0.75, sat=0.55)
    bs = blobs(im)
    groups = groups or pick_decals(im)
    # a tile each, or a tile and a half when any of them is bigger than a tile (BiomeDeco reads
    # the size from the sheet's height)
    big = max(max(bs[i][2] for i in g) - min(bs[i][0] for i in g) + 1 for g in groups) > T - 2 or \
          max(max(bs[i][3] for i in g) - min(bs[i][1] for i in g) + 1 for g in groups) > T - 2
    C = T * 3 // 2 if big else T
    out = Image.new("RGBA", (len(groups) * C, C))
    for k, g in enumerate(groups):
        x0 = min(bs[i][0] for i in g)
        y0 = min(bs[i][1] for i in g)
        x1 = max(bs[i][2] for i in g) + 1
        y1 = max(bs[i][3] for i in g) + 1
        mask = Image.new("L", im.size, 0)
        mp = mask.load()
        for i in g:
            for (x, y) in bs[i][7]:
                mp[x, y] = 255
        piece = Image.new("RGBA", im.size)
        piece.paste(im, (0, 0), mask)
        piece = piece.crop((x0, y0, x1, y1))
        out.alpha_composite(piece, (k * C + (C - piece.width) // 2, (C - piece.height) // 2))
    return out

KITS = {
    # Floor 1, the Ossuary. Hue 0.95: the grey mauve of its slabs.
    "kit0": {
        "hue": 0.95,
        "tiles": "floor_slabs",
        "wallface": ["wall_panel_a", "wall_panel_b"],
        "pilaster": "pilaster",
        "walls": ("wall_top", (2, 54)),     # without the grass along its top and bottom
        "props": {"bonepile": "prop_bonepile", "coffin": "prop_coffin", "candles": "prop_candles",
                  "chains": "wall_chains", "skullniche": "wall_skullniche"},
        # bones: two long bones, a hand, the bits of a broken one; pebbles: two stones, two small ones
        "decals": ("decals", [[2], [9], [6], [7, 8, 11, 12, 13, 14, 15, 16], [3], [10], [4, 5]]),
        "calm": (0.6, 1.12, (46, 38, 48)),      # its joints a dark mauve
    },
}

def std(hue=None, props=(), dress=(), calm_args=(), walls_rows=None, decal_groups=None):
    """A floor whose pictures are named as Stage 61.2 made them: tiles, wall_a, wall_b, pilaster,
    walltop, prop_<name>, dress_<name>, decals."""
    names = {p: "prop_" + p for p in props}
    names.update({d: "dress_" + d for d in dress})
    return {"hue": hue, "tiles": "tiles", "wallface": ["wall_a", "wall_b"], "pilaster": "pilaster",
            "walls": ("walltop", walls_rows), "props": names, "decals": ("decals", decal_groups),
            "calm": calm_args}

# Chapter I, floors 2 to 11 (Stage 61.2): props and wall dressing by the names BiomeDeco gives them.
KITS.update({
    # leaves, pebbles, a rock, a twig, a fern (not the grass on squares of earth)
    "kit1": std(props=["stump", "shroom", "mossrock"], dress=["vines", "glowshroom"],
                decal_groups=[[3], [4], [7], [8], [9], [11], [10]]),
    # scrolls, a page, a letter, a quill, a candle, an ink pot, bits of a broken tile (not the open book)
    "kit2": std(props=["shelf", "bookpile", "bust"], dress=["books", "window"], calm_args=(0.5, 1.0, None, 0.7),
                decal_groups=[[0], [1], [2], [3], [5], [6], [7], [9, 8, 10, 11, 12]]),
    # a glowing coal, a lava rock, a hammer, a nut, slag, an iron disc, a burnt one
    # its lava cracks dimmed: fire foes must stand out on it
    "kit3": std(props=["anvil", "brazier", "ironbarrel"], dress=["vent", "chains"], calm_args=(0.42, 0.82, None, 0.55),
                decal_groups=[[1], [0], [13], [8], [6], [2], [16]]),
    # snow piles, a block of ice, an ice shard, a stone, a glint
    "kit4": std(props=["icecrystal", "frostpillar", "strongbox"], dress=["chains"],
                decal_groups=[[2], [5], [42], [46], [51], [0], [18], [50]]),
    # gold coins, a crown, a goblet, a rose, a pearl necklace, wax, marble chips
    "kit5": std(props=["column", "candelabra", "armor"], dress=["portrait"],
                decal_groups=[[2], [15], [12], [13], [19], [4], [3], [20]]),
    # autumn leaves, a puddle, mud, straw, a horseshoe, a lost boot
    "kit6": std(props=["lamppost", "haybale", "rainbarrel"], dress=["window", "vines"],
                decal_groups=[[0], [1], [2], [3], [5], [8], [9], [10]]),
    # broken arrows, a helmet, a shield, a rock, a burnt plank, a sword in the ground
    "kit7": std(props=["sandbags", "stakes", "wagonwheel"], dress=["racks"], calm_args=(0.5, 0.92, None, 0.7),
                decal_groups=[[0], [1], [3], [10], [8], [18], [14]]),
    # prayer beads, an incense stick, pine cones, snow, a paper charm, a scroll
    "kit8": std(props=["stonelantern", "prayerbell", "monkstatue"], dress=["chains"],
                decal_groups=[[5], [8], [11], [3], [2], [13], [18], [17]]),
    # black feathers, coins, a brick, a puddle (not the stacks of roof tiles)
    "kit9": std(props=["chimney", "gargoyle", "weathervane"], dress=["window", "vent"],
                decal_groups=[[1], [2], [3], [5], [6], [10]]),
    # crystals, masks, a star, a shard of ice, an orb, a stone
    # its glowing motifs dimmed: the foes' purple shots must stand out on it
    "kit10": std(props=["obelisk", "monolith", "shard"], dress=["eye", "chains"], calm_args=(0.45, 0.9, None, 0.7),
                 decal_groups=[[3], [2], [12], [14], [29], [19], [25], [17]]),
})

def place(hue=None, calm_args=(), walls_rows=None):
    """A place with no props of its own (Stage 61.3 and 61.4: the chapter floors, the rift worlds,
    the final places, the barn): its floor, walls and column only."""
    k = std(hue=hue, calm_args=calm_args, walls_rows=walls_rows)
    k["decals"] = None
    return k

# Chapters II to IV (61.3) and the special places (61.4): floor, walls and column only.
KITS.update({k: place() for k in ["kit11", "kit12", "kit13", "kit14", "kit15", "kit16", "kit17", "kit18", "kit19",
    "kit_gaol", "kit_brand", "kit_neon", "kit_streets", "kit_fog", "kit_burb", "kit_heist", "kit_dust", "kit_skyreach",
    "kit_bastion", "kit_cathedral", "kit_spire", "kit_rimefrost", "kit_heaven", "kit_hell", "kit_brazil", "kit_seam",
    "kit_redact", "kit_pasture", "kit_senate", "kit_endtimes", "kit_parlour", "kit_barn"]})

def build(kit):
    k = KITS[kit]
    made = {}
    made[kit + "_tiles"] = calm(tiles(kit, k["tiles"]), *k.get("calm", ()))
    if k["decals"]:
        print("%s: decals" % kit, k["decals"][1] or "picked by themselves")
    made[kit + "_wallface"] = wallface(kit, k["wallface"], k["hue"])
    made[kit + "_pilaster"] = pilaster(kit, k["pilaster"], k["hue"])
    made[kit + "_walls"] = build_walls(kit, k["walls"][0], k["hue"], k["walls"][1])
    for name, src in k["props"].items():
        made[kit + "_" + name] = crop_even(load(kit, src))
    if k["decals"]:
        made[kit + "_decals"] = decals(kit, k["decals"][0], k["decals"][1], k["hue"])
    for name, im in made.items():
        im.save(os.path.join(OUT, name + ".png"))
        print(name, im.size)
    return made

def review(made, path, zoom=4):
    ims = list(made.items())
    w = max(im.width for _, im in ims) * zoom + 16
    h = sum(im.height * zoom + 12 for _, im in ims)
    sheet = Image.new("RGBA", (w, h), (70, 70, 80, 255))
    y = 0
    for name, im in ims:
        sheet.alpha_composite(im.resize((im.width * zoom, im.height * zoom), Image.NEAREST), (8, y))
        y += im.height * zoom + 12
    sheet.save(path)

if __name__ == "__main__":
    m = build(sys.argv[1])
    if len(sys.argv) > 2:
        review(m, sys.argv[2])
