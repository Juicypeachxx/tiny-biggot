# Stages 33-35 icons (his word, 9 Oct: the four build paths). Our own pixel art: halo icons
# recoloured from the game's own halo relics, the rest drawn here as grids.
# Run from the project folder: python3 tools/art/stage33_icons.py   (writes assets/graphics/*.png)
import colorsys, os
from PIL import Image

G = "assets/graphics/"

def recolour(src, dst, hue, sat=1.0, val=1.0):
    im = Image.open(G + src + ".png").convert("RGBA")
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
            if s > 0.15:   # keep outlines and greys
                h = hue
                s = min(1.0, s * sat)
                v = min(1.0, v * val)
            rr, gg, bb = colorsys.hsv_to_rgb(h, s, v)
            px[x, y] = (round(rr * 255), round(gg * 255), round(bb * 255), a)
    im.save(G + dst + ".png")

def grid(dst, rows, pal):
    h = len(rows); w = max(len(r) for r in rows)
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch in pal:
                c = pal[ch].lstrip("#")
                im.putpixel((x, y), (int(c[0:2], 16), int(c[2:4], 16), int(c[4:6], 16), 255))
    im.save(G + dst + ".png")

OUT = "#140f1c"
icons = {}

def stage33():
    recolour("relic_halo_gravity", "relic_halo_wither", 0.80, 1.1, 0.75)   # deep violet
    recolour("relic_halo_ember", "relic_halo_mist", 0.99, 1.2, 0.9)        # blood red
    # HORIZON RING: a ring with two moons on its rim.
    grid("relic_horizonring", [
        "....oooo....",
        "..oo1221oo..",
        ".o12....21o.",
        ".o2......2o.",
        "o1........mo",
        "o2.......mMo",
        "o2........mo",
        "o1........1o",
        ".omo....12o.",
        ".oMmo..21o..",
        "..oo1221oo..",
        "....oooo....",
    ], {"o": OUT, "1": "#e86fb4", "2": "#a35bd6", "m": "#d9d0b4", "M": "#f4ecd8"})


def rendered(names):
    """Grids from sprites.py in the game's look (render.py, look D), written to assets/graphics."""
    here = os.path.dirname(os.path.abspath(__file__))
    ns = {"__file__": os.path.join(here, "render.py")}
    exec(open(os.path.join(here, "render.py")).read(), ns)
    for n in names:
        ns["sprite"](n, ns["VIBES"]["D"]).save(G + n + ".png")

def shade(hexc, k):
    c = hexc.lstrip("#"); r, g, b = (int(c[i:i + 2], 16) for i in (0, 2, 4))
    return "#%02x%02x%02x" % tuple(max(0, min(255, round(v * k))) for v in (r, g, b))

def mug(dst, body, foam="#f4ecd8", band="#8a6a4a"):
    """A drink for the belt: a tankard with its handle, 10x11, foam on top."""
    rows = [
        "..oooooo..",
        ".offfffo..",
        ".offFFfoo.",
        ".o122221oo",
        ".o1bbbb1o.o"[:10],
        ".o122221o.",
        ".o122221oo",
        ".o1bbbb1oo",
        ".o122221o.",
        ".o111111o.",
        "..oooooo..",
    ]
    rows[4] = ".o1bbbb1oo"
    grid(dst, rows, {"o": OUT, "1": shade(body, 0.6), "2": body, "b": band, "f": foam, "F": shade(foam, 0.85)})

def stage33_tavern():
    mug("c_ale", "#e8b84a")
    mug("c_stout", "#5a3a22", foam="#d9c8a8")
    mug("c_mead", "#f2c94c", foam="#fff0b0", band="#c87a3a")

def stage34():
    # WISHBONE: a forked bone.
    grid("relic_wishbone", [
        "............",
        "..o......o..",
        ".o1o....o1o.",
        ".o1o....o1o.",
        "..o1o..o1o..",
        "..o1o..o1o..",
        "...o1oo1o...",
        "....o11o....",
        "....o12o....",
        "....o12o....",
        ".....oo.....",
        "............",
    ], {"o": OUT, "1": "#e8dcc8", "2": "#b8a888"})

if __name__ == "__main__":
    stage33()
    stage33_tavern()
    stage34()
    rendered(["mindwarden_hero", "w_thoughtstone", "tavernknight_hero", "w_tankardmaul", "trickshot_hero", "w_quickcrossbow"])
    print("stage 33 sprites rendered")
