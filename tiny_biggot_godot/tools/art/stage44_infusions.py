# 44.1 INFUSIONS (his pictures, 10 Oct: a wiki's infusions; ideas only, our own names and pixels).
# Fourteen belt items, each in its element's colours (scripts/game/infusions.gd KINDS):
#   SAPS     a corked vial of coloured sap (10 rooms); PIXIE SAP with sparkles, BLESSED DEW a flask
#            under a halo
#   SPICES   a tied pouch of coloured powder (for good)
#   AMBERS   a glowing chunk of amber-like resin (for good, stronger)
# and the picture of ENDLESS INFUSION (dex_temper): an endless loop over a drop, one flat
# shape for its trait cube (TraitView.cube), like the other trait pictures.
# Run from the project folder: python3 tools/art/stage44_infusions.py   (then tools/bake_atlas.sh)
import os
from PIL import Image

G = os.environ.get("ART_OUT", "assets/graphics/")   # (ART_OUT: a folder for a preview)
OUT = "#140f1c"
CORK = "#8a6a3a"
GLASS = "#c8d0dc"
TIE = "#c8a878"
HALO = "#f2c94c"
WHITE = "#ffffff"


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


def shade(hexc, k):
    c = hexc.lstrip("#")
    r, g, b = (int(c[i:i + 2], 16) for i in (0, 2, 4))
    return "#%02x%02x%02x" % tuple(max(0, min(255, round(v * k))) for v in (r, g, b))


def tint(hexc, k):   # toward white
    c = hexc.lstrip("#")
    r, g, b = (int(c[i:i + 2], 16) for i in (0, 2, 4))
    return "#%02x%02x%02x" % tuple(round(v + (255 - v) * k) for v in (r, g, b))


def pal(col, **more):
    p = {"o": OUT, "1": col, "2": tint(col, 0.45), "3": shade(col, 0.6), "k": CORK, "w": GLASS, "t": TIE,
         "h": HALO, "s": WHITE}
    p.update(more)
    return p


VIAL = [
    "...kkk...",
    "...kkk...",
    "..owwwo..",
    "...o1o...",
    "..o111o..",
    ".o12111o.",
    "o1211111o",
    "o1111111o",
    "o1111133o",
    ".o11133o.",
    "..ooooo..",
]
PIXIE = [
    "s..kkk...",
    "...kkk..s",
    "..owwwo..",
    "...o1o...",
    "..o111o.s",
    ".o12111o.",
    "o1211111o",
    "o1s11111o",
    "o1111133o",
    ".o11133o.",
    "..ooooo..",
]
DEW = [
    "...hhh...",
    "..h...h..",
    "...hhh...",
    "...owo...",
    "..o121o..",
    ".o12111o.",
    "o1211111o",
    "o1111111o",
    ".o11113o.",
    "..ooooo..",
]
POUCH = [
    "...t..t...",
    "....tt....",
    "...oooo...",
    "..o1111o..",
    ".o112111o.",
    "o11211111o",
    "o11111111o",
    "o11111131o",
    ".o111133o.",
    "..oooooo..",
]
AMBER = [
    "...oooo...",
    "..o2211o..",
    ".o221111o.",
    "o22111113o",
    "o2111s133o",
    "o111sss33o",
    ".o111s33o.",
    "..o1133o..",
    "...o13o...",
    "....oo....",
]

# kind: (shape, colour): the colours are the KINDS' own (infusions.gd)
ITEMS = {
    "inf_embersap": (VIAL, "#ff7a2e"),
    "inf_rimesap": (VIAL, "#7fd8ff"),
    "inf_sparksap": (VIAL, "#c890ff"),
    "inf_briarsap": (VIAL, "#5fc96a"),
    "inf_moldsap": (VIAL, "#8ae04a"),
    "inf_pixiesap": (PIXIE, "#e889c8"),
    "inf_blessdew": (DEW, "#fff3b0"),
    "inf_cinderspice": (POUCH, "#e8873a"),
    "inf_frostspice": (POUCH, "#4d9be6"),
    "inf_thunderspice": (POUCH, "#f2c94c"),
    "inf_viperspice": (POUCH, "#63b84f"),
    "inf_blazeamber": (AMBER, "#ff9b3a"),
    "inf_glacieramber": (AMBER, "#b8ecff"),
    "inf_stormamber": (AMBER, "#ffe14a"),
}

# ENDLESS INFUSION: an endless loop over a drop (white on clear, drawn in its cube's colour).
TEMPER = [
    "..###......###..",
    ".#...#....#...#.",
    "#.....#..#.....#",
    "#......##......#",
    "#......##......#",
    "#.....#..#.....#",
    ".#...#....#...#.",
    "..###......###..",
    "................",
    ".......##.......",
    "......####......",
    ".....######.....",
    ".....######.....",
    "....########....",
    ".....######.....",
    "......####......",
]

for k, (shape, col) in ITEMS.items():
    grid(k, shape, pal(col))
grid("tr_dex_temper", TEMPER, {"#": WHITE})
print("stage 44 infusions: %d belt items and a trait picture" % len(ITEMS))
