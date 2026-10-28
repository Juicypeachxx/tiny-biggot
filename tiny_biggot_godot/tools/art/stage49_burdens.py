# 49.1 Relics that grow with the curses you carry and the foes you have slain (his list of another
# game's core gameplay, 10 Oct; scripts/game/burdens.gd). Our own pixels, 12 x 12: BURDENED IDOL,
# PENITENT'S CHAIN, WIDOW'S VEIL, SINNER'S CROWN, TALLY STICK, BONE ROSARY, REAPER'S LAMP, THE
# HUNDREDFOLD.
# Run from the project folder: python3 tools/art/stage49_burdens.py   (then tools/bake_atlas.sh)
import os
from PIL import Image

G = os.environ.get("ART_OUT", "assets/graphics/")   # (ART_OUT: a folder for a preview)
OUT = "#140f1c"


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


ITEMS = {
    # BURDENED IDOL: a squat stone idol with glowing eyes, a chain round its belly.
    "relic_burdenidol": ([
        "....oooo....",
        "...o2222o...",
        "..o2e22e2o..",
        "..o222222o..",
        "...o2112o...",
        "..o211112o..",
        ".o21111112o.",
        ".o21111112o.",
        ".oc111111co.",
        "..occcccco..",
        "..o333333o..",
        "...oooooo...",
    ], {"o": OUT, "1": "#5c4a6e", "2": "#8a7a9c", "3": "#3a2c48", "e": "#c86ff0", "c": "#8b8f9c"}),
    # PENITENT'S CHAIN: two iron links and a purple padlock.
    "relic_penitentchain": ([
        "....oooo....",
        "...o2222o...",
        "...o2..2o...",
        "...o2222o...",
        "....o22o....",
        "...o2222o...",
        "...o2..2o...",
        "...o2222o...",
        "..oooooooo..",
        "..o333333o..",
        "..o33k333o..",
        "..oooooooo..",
    ], {"o": OUT, "2": "#8b8f9c", "3": "#a35bd6", "k": OUT}),
    # WIDOW'S VEIL: a mourning veil over a shadowed face, one purple tear.
    "relic_widowveil": ([
        "....oooo....",
        "...o1111o...",
        "..o111111o..",
        "..o11ss11o..",
        ".o11ssss11o.",
        ".o11stss11o.",
        ".o111ss111o.",
        "o1111111111o",
        "o1111111111o",
        "o1o11o11o1o.",
        ".o.oo.oo.o..",
        "............",
    ], {"o": OUT, "1": "#6a4a8c", "s": "#241a30", "t": "#c86ff0"}),
    # SINNER'S CROWN: a dark gold crown, a red and a purple stone, dripping red.
    "relic_sinnerscrown": ([
        "............",
        ".o...oo...o.",
        "o2o.o22o.o2o",
        "o22o2222o22o",
        "o2222222222o",
        "o2r22p22r22o",
        "o2222222222o",
        "o3333333333o",
        ".oooooooooo.",
        "..d....d....",
        "..d.........",
        "............",
    ], {"o": OUT, "2": "#b8902a", "3": "#7a5a1a", "r": "#d8443c", "p": "#a35bd6", "d": "#d8443c"}),
    # TALLY STICK: a notched stick, the last notch fresh red.
    "relic_tallystick": ([
        "....oooo....",
        "...o1112o...",
        "...o1112o...",
        "...onnn2o...",
        "...o1112o...",
        "...onnn2o...",
        "...o1112o...",
        "...onnn2o...",
        "...o1112o...",
        "...onnr2o...",
        "...o1112o...",
        "....oooo....",
    ], {"o": OUT, "1": "#c8963a", "2": "#8a5a2a", "n": "#5a3a1a", "r": "#d8443c"}),
    # BONE ROSARY: a string of bone beads and a skull.
    "relic_bonerosary": ([
        "...o.oo.o...",
        "..obobbobo..",
        ".ob......bo.",
        ".ob......bo.",
        "..ob....bo..",
        "...ob..bo...",
        "....oSSo....",
        "...oSSSSo...",
        "...oSeeSo...",
        "...oSSSSo...",
        "....oSSo....",
        "............",
    ], {"o": OUT, "b": "#e8e0c8", "S": "#f4ecd8", "e": OUT}),
    # REAPER'S LAMP: an iron lantern with a pale green soul flame.
    "relic_reaperlamp": ([
        "....oooo....",
        "...o....o...",
        "...oooooo...",
        "..o333333o..",
        "..o3gggg3o..",
        "..o3gffg3o..",
        "..o3gffg3o..",
        "..o3gfFg3o..",
        "..o3gggg3o..",
        "..o333333o..",
        "...oooooo...",
        "....o..o....",
    ], {"o": OUT, "3": "#5a5a6a", "g": "#3f8a4a", "f": "#7ad86a", "F": "#d8f8b0"}),
    # THE HUNDREDFOLD: a skull with red eyes under three red tally marks.
    "relic_hundredfold": ([
        "..r..r..r...",
        "..r..r..r...",
        "...oooooo...",
        "..oSSSSSSo..",
        ".oSSSSSSSSo.",
        ".oSeeSSeeSo.",
        ".oSeeSSeeSo.",
        ".oSSSnnSSSo.",
        "..oSSSSSSo..",
        "...oStStSo..",
        "...oooooo...",
        "............",
    ], {"o": OUT, "S": "#f4ecd8", "e": "#d8443c", "n": OUT, "t": OUT, "r": "#d8443c"}),
}

for name, (rows, pal) in ITEMS.items():
    grid(name, rows, pal)
print("stage 49.1 art:", len(ITEMS), "pictures")
