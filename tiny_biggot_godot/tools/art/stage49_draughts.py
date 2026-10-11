# 49.2 ROOM DRAUGHTS (his list of another game's core gameplay, 10 Oct; scripts/game/draughts.gd).
# Our own pixels, 9 x 11: a square-shouldered bottle with a cork and a paper band, so a room
# draught never looks like the round FURY DRAUGHT flask; the liquid's colour says which.
# Run from the project folder: python3 tools/art/stage49_draughts.py   (then tools/bake_atlas.sh)
import os
from PIL import Image

G = os.environ.get("ART_OUT", "assets/graphics/")   # (ART_OUT: a folder for a preview)
OUT = "#140f1c"

BOTTLE = [
    "...ooo...",
    "...oco...",
    "..oo2oo..",
    ".o22222o.",
    "o2111112o",
    "o1h11111o",
    "obbbbbbbo",
    "o1111111o",
    "o1111113o",
    ".o33333o.",
    "..ooooo..",
]

LIQUID = {
    "d_war": ("#e8573a", "#8a2a1a"),      # WARCRY: red
    "d_quick": ("#d8e0ec", "#7a8494"),    # QUICKSILVER: silver
    "d_eagle": ("#f2c94c", "#a8802a"),    # EAGLE-EYE: gold
    "d_storm": ("#6fb4f0", "#2a5a9a"),    # STORMCALL: blue
    "d_ghost": ("#c08ae8", "#5c3483"),    # GHOSTWALK: violet
    "d_leech": ("#b83a4a", "#5a1a22"),    # BLOODLETTER'S: dark red
}


def grid(dst, rows, pal):
    h = len(rows)
    w = max(len(r) for r in rows)
    assert all(len(r) == w for r in rows), dst
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch in pal:
                c = pal[ch].lstrip("#")
                im.putpixel((x, y), (int(c[0:2], 16), int(c[2:4], 16), int(c[4:6], 16), 255))
    im.save(G + dst + ".png")


for name, (light, dark) in LIQUID.items():
    grid(name, BOTTLE, {"o": OUT, "c": "#a8705a", "2": "#e8f0f8", "1": light, "3": dark,
                        "h": "#ffffff", "b": "#e8d8b0"})
print("stage 49.2 art:", len(LIQUID), "pictures")
