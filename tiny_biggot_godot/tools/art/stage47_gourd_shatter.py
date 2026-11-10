# 47.1 THE GOURD and 47.2 SHATTER (his list of another game's core gameplay, 10 Oct;
# scripts/game/gourd.gd, scripts/combat/shatter.gd). Our own pixels: the gourd on the HUD (7 x 9, by
# the potions) and four relics (12 x 12): WAYFARER'S CORK, HONEY STOPPER, SPLITTING WEDGE, CRACKED GEODE.
# Run from the project folder: python3 tools/art/stage47_gourd_shatter.py   (then tools/bake_atlas.sh)
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


GOURD = {"o": OUT, "1": "#c8963a", "2": "#e8c878", "3": "#8a5a2a", "c": "#7a5236", "g": "#8fd14f"}
ITEMS = {
    # The HUD's gourd: a bottle gourd with a cork and a green cord.
    "gourd": ([
        "..oco..",
        "..oco..",
        ".oggo..",
        ".o21o..",
        "o22111o",
        "o21111o",
        "o11113o",
        ".o113o.",
        "..ooo..",
    ], GOURD),
    # WAYFARER'S CORK: a big cork on a cord.
    "relic_wayfarercork": ([
        "............",
        "....oooo....",
        "...o2222o...",
        "..o221111o..",
        "..o211113o..",
        "..o111133o..",
        "...o1133o...",
        "...o1133o...",
        "....oooo....",
        ".....gg.....",
        "....g..g....",
        ".....gg.....",
    ], {"o": OUT, "1": "#a8705a", "2": "#e8c878", "3": "#7a5236", "g": "#8fd14f"}),
    # HONEY STOPPER: a gourd's stopper dripping honey.
    "relic_honeystopper": ([
        "....oooo....",
        "...o2222o...",
        "...o2111o...",
        "...o1113o...",
        "..oooooooo..",
        "..ohhhhhho..",
        "..ohhhhhho..",
        "...oohhoo...",
        ".....hh.....",
        ".....hh.....",
        "......h.....",
        "......h.....",
    ], {"o": OUT, "1": "#a8705a", "2": "#e8c878", "3": "#7a5236", "h": "#f2c94c"}),
    # SPLITTING WEDGE: an iron wedge split into stone.
    "relic_splitwedge": ([
        "..oooooooo..",
        "..o222222o..",
        "..o211113o..",
        "...o1113o...",
        "...o1113o...",
        "....o13o....",
        "....o13o....",
        "oooooo3ooooo",
        "osss.o..ssso",
        "ossss.o.ssso",
        "osss..o..sso",
        "oooooooooooo",
    ], {"o": OUT, "1": "#8b8f9c", "2": "#c8d0dc", "3": "#4e4a5e", "s": "#7a6a58"}),
    # CRACKED GEODE: a stone split open on violet crystal.
    "relic_crackedgeode": ([
        "............",
        "...oooooo...",
        "..o111111o..",
        ".o11ppp1.1o.",
        ".o1pwppp.1o.",
        "o11ppwpp.11o",
        "o1pppppp.11o",
        "o11pppp.p11o",
        ".o11ppp.11o.",
        ".o111111.1o.",
        "..oooooooo..",
        "............",
    ], {"o": OUT, "1": "#6a6478", "p": "#a35bd6", "w": "#e889c8"}),
}

for k, (rows, pal) in ITEMS.items():
    grid(k, rows, pal)
print("stage 47 gourd and shatter: %d" % len(ITEMS))
