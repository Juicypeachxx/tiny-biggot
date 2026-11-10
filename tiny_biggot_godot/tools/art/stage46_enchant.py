# 46.1 WEAPON ENCHANTMENTS (his pictures, 10 Oct; scripts/game/enchant.gd): the places that put one
# on your weapon. Our own pixels: THE ENCHANTER's lectern (expanded shops), a wyrm's stone head (THE
# WYRM'S BREATH, its breath drawn in code), the runesmith's anvil (THE CHOP SHOP), the back-room crate
# (THE PAWN SHOP) and the silver branch (THE FROG POND).
# Run from the project folder: python3 tools/art/stage46_enchant.py   (then tools/bake_atlas.sh)
import os
from PIL import Image

G = os.environ.get("ART_OUT", "assets/graphics/")   # (ART_OUT: a folder for a preview)
OUT = "#140f1c"


def grid(dst, rows, pal):
    h = len(rows)
    w = max(len(r) for r in rows)
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch in pal:
                c = pal[ch].lstrip("#")
                im.putpixel((x, y), (int(c[0:2], 16), int(c[2:4], 16), int(c[4:6], 16), 255))
    im.save(G + dst + ".png")


ITEMS = {
    # THE ENCHANTER: a lectern with an open book, its pages lit purple.
    "o_enchanter": ([
        "................",
        "..oooooo.oooooo.",
        ".o2222p1o1p2222o",
        ".o22pp21o12pp22o",
        ".o2p2221o1222p2o",
        ".o2222p1o1p2222o",
        "..oooooooooooo..",
        "......o33o......",
        "......o34o......",
        "......o34o......",
        "......o34o......",
        "......o34o......",
        "....oo3344oo....",
        "...o33333444o...",
        "...oooooooooo...",
        "................",
    ], {"o": OUT, "1": "#a35bd6", "2": "#f4ecd8", "p": "#e889c8", "3": "#7a5236", "4": "#4e3424"}),
    # THE WYRM'S BREATH: a wyrm's head carved in stone, its jaw open.
    "o_breath": ([
        "...oo...........",
        "..o11o..........",
        "..o121ooooo.....",
        "...o1222221o....",
        "..o12222222oo...",
        ".o1222e2222221o.",
        ".o122222222222o.",
        ".o12222oooooooo.",
        ".o1222o.........",
        ".o12222oooooooo.",
        ".o122222222222o.",
        "..o1222222221o..",
        "..o1122222211o..",
        "..o3311111133o..",
        ".o333333333333o.",
        ".oooooooooooooo.",
    ], {"o": OUT, "1": "#6a6478", "2": "#8b8f9c", "3": "#4e4a5e", "e": "#f2c94c"}),
    # The runesmith: an anvil with cyan runes cut into its face.
    "o_runeforge": ([
        "................",
        ".oooooooooooo...",
        "o2222222222221oo",
        "o1c1c11c11c11111",
        ".o1111111111111o",
        "..oo11111111ooo.",
        "....o1c1c11o....",
        "....o111111o....",
        "...o11111111o...",
        "..o1111111111o..",
        "..oooooooooooo..",
        "...o33333333o...",
        "..o3444444443o..",
        "..oooooooooooo..",
        "................",
    ], {"o": OUT, "1": "#4e4a5e", "2": "#8b8f9c", "c": "#6fd3e0", "3": "#7a5236", "4": "#4e3424"}),
    # THE PAWN SHOP's back room: a chained crate under a red seal.
    "o_contraband": ([
        "..............",
        ".oooooooooooo.",
        ".o3443344334o.",
        ".occccccccccco",
        ".o3443344334o.",
        ".o34433rr334o.",
        ".occcccrrcccco",
        ".o344334r334o.",
        ".o3443344334o.",
        ".occccccccccco",
        ".o3443344334o.",
        ".oooooooooooo.",
    ], {"o": OUT, "3": "#7a5236", "4": "#a8705a", "c": "#8b8f9c", "r": "#d8443c"}),
    # THE FROG POND's silver branch, its leaves pale.
    "o_branch": ([
        "......l.......",
        ".....lwl...l..",
        "..l...s...lwl.",
        ".lwl..s....s..",
        "..s...s...s...",
        "...s..s..s....",
        "....s.s.s..l..",
        ".....sss..lwl.",
        "......s..ss...",
        "......sss.....",
        "......s.......",
        "......s.......",
        ".....oso......",
        "....o333o.....",
        "...o33333o....",
        "...ooooooo....",
    ], {"o": OUT, "s": "#c8d0dc", "l": "#9fe0c8", "w": "#ffffff", "3": "#4e4a5e"}),
}

for k, (rows, pal) in ITEMS.items():
    grid(k, rows, pal)
print("stage 46 enchantment places: %d" % len(ITEMS))
