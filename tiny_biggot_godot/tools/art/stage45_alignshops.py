# 45.1 THE ALIGNMENT SHOPS (his notes, 9 Oct): nine relics that grow with an alignment, three for
# each shop (scripts/game/align_shops.gd): GOOD (THE ALMONER), EVIL (THE ASH PEDDLER), LAWFUL (THE
# QUARTERMASTER). Our own pixels, 12 x 12, in the shops' colours.
# Run from the project folder: python3 tools/art/stage45_alignshops.py   (then tools/bake_atlas.sh)
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


GOLD = {"o": OUT, "1": "#f2c94c", "2": "#fff0b0", "3": "#c8963a"}
ITEMS = {
    # ---- GOOD
    "relic_almshalo": ([
        "............",
        "..oooooooo..",
        ".o22222222o.",
        ".o2oooooo2o.",
        "..oooooooo..",
        "............",
        "....oooo....",
        "...o2211o...",
        "..o221111o..",
        "..o211113o..",
        "...o1133o...",
        "....oooo....",
    ], GOLD),
    "relic_mercylamp": ([
        ".....2......",
        "....212.....",
        "....111.....",
        ".....o......",
        "...oooooo...",
        "..o111111ooo",
        ".o12111111o.",
        ".o11111113o.",
        "..o111133o..",
        "...oooooo...",
        "....o11o....",
        "...oooooo...",
    ], GOLD),
    "relic_dawnbuckler": ([
        "...oooooo...",
        "..o111111o..",
        ".o11122111o.",
        "o1112222111o",
        "o1122222211o",
        "o1122222211o",
        "o1112222111o",
        "o1111221111o",
        ".o11111113o.",
        "..o111133o..",
        "...oooooo...",
        "............",
    ], {"o": OUT, "1": "#e8c878", "2": "#fff0b0", "3": "#a8783a"}),
    # ---- EVIL
    "relic_ashcrown": ([
        "..2...2..2..",
        ".2...2..2...",
        "............",
        ".o...oo...o.",
        ".1o.o11o.o1.",
        ".11o1111o11.",
        ".1111111111.",
        ".1r11r11r11.",
        ".1111111111.",
        ".oooooooooo.",
        "............",
        "............",
    ], {"o": OUT, "1": "#4a4458", "2": "#8b8f9c", "r": "#d8443c"}),
    "relic_sinchalice": ([
        ".oooooooooo.",
        ".o22222222o.",
        ".o1rrrrrr1o.",
        "..o1rrrr1o..",
        "...o1111o...",
        "....o11o....",
        ".....oo.....",
        ".....11.....",
        "....o11o....",
        "...oooooo...",
        "......r.....",
        "......r.....",
    ], {"o": OUT, "1": "#8a2a33", "2": "#c8b8a8", "r": "#d8443c"}),
    "relic_gravecoin": ([
        "...oooooo...",
        "..o111111o..",
        ".o11222211o.",
        "o1122222211o",
        "o1220220221o",
        "o1222222221o",
        "o1122002211o",
        ".o12222221o.",
        "..o121121o..",
        "...oooooo...",
        "............",
        "............",
    ], {"o": OUT, "0": OUT, "1": "#6a6478", "2": "#f4ecd8"}),
    # ---- LAWFUL
    "relic_tinstar": ([
        ".....oo.....",
        "....o11o....",
        "....o11o....",
        "oooo1111oooo",
        "o1111111111o",
        ".o11122111o.",
        "..o112211o..",
        "..o111111o..",
        ".o111oo111o.",
        ".o11o..o11o.",
        ".ooo....ooo.",
        "............",
    ], {"o": OUT, "1": "#c8d0dc", "2": "#ffffff"}),
    "relic_duesledger": ([
        ".oooooooooo.",
        ".o11111111o.",
        ".o12222221o.",
        ".o11111111o.",
        ".o11111111o.",
        ".oaaaaaaaao.",
        ".o11111111o.",
        ".o11111111o.",
        ".o11111111o.",
        ".oooooooooo.",
        ".o22222222o.",
        ".oooooooooo.",
    ], {"o": OUT, "1": "#2b6f8a", "2": "#e8dcc0", "a": "#6fd3e0"}),
    "relic_ironwrit": ([
        ".oooooooooo.",
        "o2222222222o",
        ".oooooooooo.",
        "..o222222o..",
        "..o2oooo2o..",
        "..o222222o..",
        "..o2oooo2o..",
        "..o222cc2o..",
        "..o22cccco..",
        ".oooooooooo.",
        "o2222222222o",
        ".oooooooooo.",
    ], {"o": OUT, "2": "#e8dcc0", "c": "#6fd3e0"}),
}

for k, (rows, pal) in ITEMS.items():
    grid(k, rows, pal)
print("stage 45 alignment shop relics: %d" % len(ITEMS))
