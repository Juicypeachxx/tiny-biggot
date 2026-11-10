# Stage 36 food and drink (his word, 9 Oct: "Ideas for sprites for new stuff, and new stuff to
# add"; ideas only, our own names and pixels). Ten foods, ten golden foods, a cheese, three drinks.
# Run from the project folder: python3 tools/art/stage36_food.py   (then tools/bake_atlas.sh)
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


def shade(hexc, k):
    c = hexc.lstrip("#")
    r, g, b = (int(c[i:i + 2], 16) for i in (0, 2, 4))
    return "#%02x%02x%02x" % tuple(max(0, min(255, round(v * k))) for v in (r, g, b))


# ---------- 36.1 food: +XP and attributes ----------
FOOD = {
    "f_bread": ([
        "..oooooo..",
        ".o122221o.",
        "o12q2q2q1o",
        "o2q2q2q22o",
        "o22222222o",
        "o33333333o",
        ".oooooooo.",
    ], {"1": "#f0c890", "2": "#d89a50", "3": "#a86a30", "q": "#b87838"}),
    "f_berries": ([
        ".....gg..",
        "....gGg..",
        "..oo.o...",
        ".o12o.oo.",
        ".o22oo12o",
        "..oo1o22o",
        "...o12oo.",
        "...o22o..",
        "....oo...",
    ], {"1": "#8fb0ff", "2": "#4d5bd6", "g": "#63b84f", "G": "#3a7a2a"}),
    "f_mushroom": ([
        "..oooooo..",
        ".o122221o.",
        "o12w22w21o",
        "o22222222o",
        "oooo44oooo",
        "...o44o...",
        "...o54o...",
        "...oooo...",
    ], {"1": "#8fd8ff", "2": "#4d9be6", "w": "#f4ecd8", "4": "#e8dcc8", "5": "#b8a888"}),
    "f_drumstick": ([
        "..oooo....",
        ".o1222o...",
        "o122222o..",
        "o222223o..",
        "o22223o...",
        ".o333oo...",
        "..oo.wwo..",
        ".....owwo.",
        "......oo..",
    ], {"1": "#e8a070", "2": "#c8643a", "3": "#8a3a20", "w": "#f4ecd8"}),
    "f_carrot": ([
        "......gg..",
        ".....gGg..",
        "....oog...",
        "...o11o...",
        "..o122o...",
        "..o22o....",
        ".o22o.....",
        ".o2o......",
        "oo........",
    ], {"1": "#ffb070", "2": "#e8873a", "g": "#63b84f", "G": "#3a7a2a"}),
    "f_turnip": ([
        "...g..g...",
        "...gGGg...",
        "....gg....",
        "..oooooo..",
        ".o111111o.",
        ".o2w2222o.",
        ".o222223o.",
        "..o2233o..",
        "...oo3o...",
        "....oo....",
    ], {"1": "#a35bd6", "2": "#f4ecd8", "3": "#c8b8a8", "w": "#ffffff", "g": "#63b84f", "G": "#3a7a2a"}),
    "f_fishpie": ([
        "...ooo.o..",
        "..o44oo4o.",
        "..oooooo..",
        ".o122221o.",
        "o1q2q2q21o",
        "o22222222o",
        "o33333333o",
        ".oooooooo.",
    ], {"1": "#f0c890", "2": "#d89a50", "3": "#a86a30", "q": "#b87838", "4": "#6fa8d8"}),
    "f_nuts": ([
        "..........",
        "...oo.....",
        "..o12o.oo.",
        "..o23oo12o",
        ".oo3oo223o",
        "o12oo12o3o",
        "o223o223oo",
        ".o3o.o33o.",
        "..o...oo..",
    ], {"1": "#e8b880", "2": "#c88a50", "3": "#8a5a30"}),
    "f_plum": ([
        ".....g....",
        "....gGo...",
        "..oooo.o..",
        ".o1222o...",
        "o122222o..",
        "o222223o..",
        "o222233o..",
        ".o2333o...",
        "..oooo....",
    ], {"1": "#d88ae0", "2": "#8a3aa0", "3": "#5a2068", "g": "#63b84f", "G": "#3a7a2a"}),
    "f_cheese": ([
        "......oo..",
        "....oo11o.",
        "..oo1111o.",
        "oo11112o1o",
        "o1111111oo",
        "o22o22222o",
        "o2o2222o2o",
        "o2222o222o",
        "oooooooooo",
    ], {"1": "#ffe08a", "2": "#e8b84a"}),
}

# ---------- 36.2 golden food: a lasting bonus each ----------
GOLD = {"1": "#fff0b0", "2": "#f2c94c", "3": "#c8963a", "s": "#ffffff"}
GOLDEN = {
    "gf_loaf": [
        "........s.",
        "..oooooo..",
        ".o122221o.",
        "o12323231o",
        "o22222222o",
        "o33333333o",
        ".oooooooo.",
    ],
    "gf_sunfruit": [
        "....o.....",
        "...o1o..s.",
        "o..o2o..o.",
        "oo.o2o.oo.",
        ".o12221o..",
        "..o232o...",
        ".o12221o..",
        "oo.o2o.oo.",
        "o..o3o..o.",
        "....o.....",
    ],
    "gf_quince": [
        "....o..s..",
        "...oo.....",
        "..o12o....",
        "..o22o....",
        ".o1222o...",
        "o122222o..",
        "o222223o..",
        "o222233o..",
        ".o2333o...",
        "..oooo....",
    ],
    "gf_tart": [
        "..o.o.o...",
        "..o2o2o.s.",
        "..o222o...",
        ".oooooooo.",
        "o11111111o",
        "o12121212o",
        ".o333333o.",
        "..oooooo..",
    ],
    "gf_egg": [
        "....oo..s.",
        "...o11o...",
        "..o1222o..",
        ".o122222o.",
        ".o222222o.",
        ".o222223o.",
        ".o222233o.",
        "..o2333o..",
        "...oooo...",
    ],
    "gf_bun": [
        ".......s..",
        "..oooooo..",
        ".o111122o.",
        "o1222o212o",
        "o12o22o22o",
        "o122o2223o",
        "o22222233o",
        ".oooooooo.",
    ],
    "gf_jelly": [
        "........s.",
        "..oooooo..",
        ".o11s111o.",
        ".o122222o.",
        ".o122222o.",
        ".o222223o.",
        "o33333333o",
        "oooooooooo",
    ],
    "gf_cookie": [
        "..oooooo..",
        ".o122221o.",
        "o12o22o21o",
        "o2ooo2o2so",
        "o22oooo22o",
        "o2o2oo2o2o",
        "o22o22o23o",
        ".o233332o.",
        "..oooooo..",
    ],
    "gf_date": [
        ".......s..",
        "...oooo...",
        "..o1222o..",
        ".o122223o.",
        ".o222223o.",
        ".o222233o.",
        "..o2333o..",
        "...oooo...",
        "....oo....",
    ],
    "gf_honeycomb": [
        "..oooooo.s",
        ".o1o22o1o.",
        "o12o22o21o",
        "oooooooooo",
        "o2o2222o2o",
        "o3o1222o3o",
        "oooooooooo",
        ".o2o33o2o.",
        "..oooooo..",
    ],
}


def mug(dst, body, foam="#f4ecd8", band="#8a6a4a"):
    """A drink for the belt: a tankard with its handle, 10x11, foam on top (as in stage33_icons)."""
    rows = [
        "..oooooo..",
        ".offfffo..",
        ".offFFfoo.",
        ".o122221oo",
        ".o1bbbb1oo",
        ".o122221o.",
        ".o122221oo",
        ".o1bbbb1oo",
        ".o122221o.",
        ".o111111o.",
        "..oooooo..",
    ]
    grid(dst, rows, {"o": OUT, "1": shade(body, 0.6), "2": body, "b": band, "f": foam, "F": shade(foam, 0.85)})


if __name__ == "__main__":
    for name, (rows, pal) in FOOD.items():
        p = dict(pal)
        p["o"] = OUT
        grid(name, rows, p)
    for name, rows in GOLDEN.items():
        p = dict(GOLD)
        p["o"] = OUT
        grid(name, rows, p)
    # 36.3 three more drinks
    mug("c_cider", "#c8d84a", foam="#f4f0c8")
    mug("c_grog", "#6a4a2a", foam="#c8b898", band="#3a2a1a")
    grid("c_wine", [
        "..oooooo..",
        ".o122221o.",
        ".o2wwww2o.",
        ".o122221o.",
        "..o1221o..",
        "...oaao...",
        "....oo....",
        "....aa....",
        "...oaao...",
        "..oooooo..",
    ], {"o": OUT, "1": "#5a2068", "2": "#8a3aa0", "w": "#d88ae0", "a": "#c8b8a8"})
    # PICNIC BASKET: a wicker basket with a checked cloth; GOLDEN SPOON: a spoon with a shine.
    grid("relic_picnicbasket", [
        "....oooo....",
        "...o.oo.o...",
        "..o......o..",
        ".oooooooooo.",
        "oRwRwRwRwRwo",
        "o1212121212o",
        "o2121212121o",
        "o1212121212o",
        "o2121212121o",
        ".o33333333o.",
        "..oooooooo..",
        "............",
    ], {"o": OUT, "1": "#c8945a", "2": "#a8703a", "3": "#7a4a2a", "R": "#d8443c", "w": "#f4ecd8"})
    grid("relic_goldenspoon", [
        "........ooo.",
        ".......o11so",
        "......o1222o",
        "......o2223o",
        ".......o33o.",
        "......o2oo..",
        ".....o2o....",
        "....o2o.....",
        "...o2o......",
        "..o2o.......",
        ".o3o........",
        ".oo.........",
    ], {"o": OUT, "1": "#fff0b0", "2": "#f2c94c", "3": "#c8963a", "s": "#ffffff"})
    print("stage 36 sprites: %d food, %d golden, 3 drinks, 2 relics" % (len(FOOD), len(GOLDEN)))
