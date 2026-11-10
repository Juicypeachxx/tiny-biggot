# Stage 59 (his word, 13 Oct, with five photos): "slovenian gopnik who acts like gangster and mogg
# peaople he also smoke alot of marijuana and drinks alot of beer". ŠEFE, KING OF THE BLOK, the third
# floor's guardian. Our own cartoon of the type, made of shapes (like Rex, Arči and the Last Laugh,
# tools/art/stage55_finale.py): a shaved head, a duck-lipped pout, a black sweater, grey work
# overalls with one strap down, plain dark sneakers (no brand from the photos); finger guns, the
# gopnik squat with a joint, a beer, zoned out, passed out. Looks: _s2 a gold chain and a little gold
# crown (the king of the blok), _s3 those and red eyes in a haze. His things: a beer can, the giant
# cone, a puff of smoke, a chainsaw, an axe; ŠEFE'S FINGER GUNS (his drop).
# Run from the project folder: python3 tools/art/stage59_sefe.py
#   ART_OUT=<folder>   write the pictures there instead (a preview)
#   SHEET=<file.png>   also write a contact sheet, six times the size
import os
import random
import sys
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from stage55_finale import Canvas, O, GLINT, rgb  # noqa: E402

OUT = os.environ.get("ART_OUT", "assets/graphics/")

SKIN = rgb("#f0c8a8")
SKIN_D = rgb("#d09a80")
STUB = rgb("#d8ae8a")        # the buzz cut (a shade under his skin)
SWEAT = rgb("#2c2a33")       # the black sweater
SWEAT_L = rgb("#423e4c")
PATCH = rgb("#1f1d25")
OVER = rgb("#7c7a86")        # grey work overalls
OVER_D = rgb("#5e5c68")
OVER_L = rgb("#9c9aa6")
BUCKLE = rgb("#c8c8d0")
SHOE = rgb("#25232b")
SOLE = rgb("#e8e4dc")
EYE = rgb("#2a1e1a")
BROW = rgb("#8a6a48")
LIP = rgb("#d8807a")
CAN = rgb("#3e8a3a")
CAN_D = rgb("#2a5e28")
CAN_T = rgb("#c8ccd4")
CAN_B = rgb("#f2c94c")
PAPER = rgb("#f4f0e6")
EMBER = rgb("#ff7a2a")
GOLD = rgb("#f2c94c")
GOLD_D = rgb("#b8902a")
RED_EYE = rgb("#d8443c")
HAZE = rgb("#9ad07a")


def _head(c, cx, hy, look, eyes="side", mouth="pout"):
    """A shaved head: skin, the stubble cap, small ears, side-eye and a duck-lipped pout."""
    c.ellipse(cx, hy, 5.0, 5.6, SKIN)
    c.ellipse(cx - 5.0, hy + 0.6, 1.0, 1.6, SKIN)
    c.ellipse(cx + 5.0, hy + 0.6, 1.0, 1.6, SKIN)
    for y in range(int(hy - 6), int(hy - 2)):
        for x in range(int(cx - 6), int(cx + 6)):
            if c.get(x, y) == SKIN and (x * 2 + y) % 3 == 0:
                c.set(x, y, STUB)
    c.shade(SKIN, SKIN_D, None, cx, hy)
    ec = RED_EYE if look >= 3 else EYE
    if eyes == "side":
        c.set(cx - 2, hy, ec)
        c.set(cx + 3, hy, ec)
        c.line(cx - 3, hy - 2, cx - 1, hy - 2, BROW)   # one brow up
        c.line(cx + 2, hy - 1.4, cx + 4, hy - 1.4, BROW)
    elif eyes == "shut":
        c.line(cx - 3, hy, cx - 1, hy, EYE)
        c.line(cx + 2, hy, cx + 4, hy, EYE)
    elif eyes == "blank":   # zoned out: half shut, staring at nothing
        c.line(cx - 3, hy, cx - 1, hy, EYE)
        c.line(cx + 2, hy, cx + 4, hy, EYE)
        c.set(cx - 2, hy + 1, ec)
        c.set(cx + 3, hy + 1, ec)
    if mouth == "pout":
        c.ellipse(cx + 0.6, hy + 3.4, 1.4, 0.9, LIP)
    elif mouth == "open":
        c.rect(cx, hy + 3, cx + 1, hy + 4, EYE)
    if look >= 2:   # the king of the blok: a little gold crown, tilted
        c.poly([(cx - 3, hy - 5.4), (cx + 3, hy - 6.4), (cx + 3.4, hy - 9.4), (cx + 1.6, hy - 7.6),
                (cx + 0.2, hy - 10.2), (cx - 1.2, hy - 7.6), (cx - 3.2, hy - 8.6)], GOLD)
        c.set(cx, hy - 7, GOLD_D)


def _chain(c, cx, y, look):
    if look >= 2:
        c.line(cx - 4, y, cx, y + 3, GOLD)
        c.line(cx, y + 3, cx + 4, y, GOLD)
        c.set(cx, y + 4, GOLD_D)


def _overalls(c, cx, y0, y1, one_strap=True):
    """The bib and its one strap up (the other hangs down)."""
    c.rect(cx - 4, y0, cx + 4, y1, OVER)
    c.line(cx - 4, y0, cx - 5, y0 - 4, OVER_D, 2)       # the strap that is up
    c.set(cx - 4, y0 + 1, BUCKLE)
    if one_strap:
        c.line(cx + 4, y0, cx + 6, y1 + 3, OVER_D)       # the one that hangs
        c.set(cx + 6, y1 + 3, BUCKLE)
    c.rect(cx - 3, y0 + 3, cx - 1, y0 + 5, OVER_D)      # a pocket


def stand(look):
    """Finger guns: one hand up by his head, one out, both pointing."""
    c = Canvas(32, 41)
    cx = 16
    # legs and sneakers
    c.rect(cx - 5, 26, cx - 1, 36, OVER)
    c.rect(cx + 1, 26, cx + 5, 36, OVER)
    c.line(cx - 1, 27, cx - 1, 36, OVER_D)
    c.rect(cx - 6, 37, cx - 1, 38, SHOE)
    c.rect(cx + 1, 37, cx + 6, 38, SHOE)
    c.rect(cx - 6, 39, cx - 1, 39, SOLE)
    c.rect(cx + 1, 39, cx + 6, 39, SOLE)
    # the black sweater
    c.poly([(cx - 7, 15), (cx + 7, 15), (cx + 6, 27), (cx - 6, 27)], SWEAT)
    c.rect(cx - 7, 15, cx - 5, 17, PATCH)               # shoulder patches
    c.rect(cx + 5, 15, cx + 7, 17, PATCH)
    _overalls(c, cx, 19, 27)
    # arms: finger guns
    c.line(cx - 7, 16, cx - 11, 10, SWEAT, 3)
    c.line(cx - 11, 10, cx - 7, 5, SWEAT, 3)
    c.ellipse(cx - 6.5, 4.5, 1.6, 1.6, SKIN)
    c.line(cx - 5, 4, cx - 2.5, 3.5, SKIN)              # the finger, pointing at his own head
    c.line(cx + 7, 16, cx + 12, 13, SWEAT, 3)
    c.line(cx + 12, 13, cx + 13, 8, SWEAT, 3)
    c.ellipse(cx + 13, 7, 1.6, 1.6, SKIN)
    c.line(cx + 14, 6, cx + 15.5, 4.5, SKIN)            # and one out at you
    c.rect(cx - 2, 13, cx + 2, 14, SKIN)                # neck
    _chain(c, cx, 15, look)
    _head(c, cx, 8, look)
    c.shade(SWEAT, None, SWEAT_L, cx, 20)
    c.shade(OVER, OVER_D, OVER_L, cx, 28)
    c.outline()
    return c.image()


def squat(look):
    """The gopnik squat: heels flat, knees wide, a joint between two fingers."""
    c = Canvas(32, 33)
    cx = 16
    # shins and sneakers flat on the floor
    c.line(cx - 8, 24, cx - 6, 30, OVER, 4)
    c.line(cx + 8, 24, cx + 6, 30, OVER, 4)
    c.rect(cx - 9, 30, cx - 3, 31, SHOE)
    c.rect(cx + 3, 30, cx + 9, 31, SHOE)
    c.rect(cx - 9, 32, cx - 3, 32, SOLE)
    c.rect(cx + 3, 32, cx + 9, 32, SOLE)
    # thighs out to the knees
    c.line(cx - 3, 23, cx - 9, 22, OVER, 4)
    c.line(cx + 3, 23, cx + 9, 22, OVER, 4)
    c.poly([(cx - 6, 13), (cx + 6, 13), (cx + 5, 24), (cx - 5, 24)], SWEAT)
    c.rect(cx - 6, 13, cx - 4, 15, PATCH)
    c.rect(cx + 4, 13, cx + 6, 15, PATCH)
    _overalls(c, cx, 17, 24)
    # arms over the knees; the right hand up with the joint
    c.line(cx - 6, 14, cx - 9, 21, SWEAT, 3)
    c.ellipse(cx - 9.5, 22.5, 1.5, 1.4, SKIN)
    c.line(cx + 6, 14, cx + 9, 19, SWEAT, 3)
    c.line(cx + 9, 19, cx + 6, 15, SWEAT, 3)
    c.ellipse(cx + 5.4, 13.8, 1.4, 1.4, SKIN)
    c.line(cx + 4, 12.6, cx + 2, 11.4, PAPER)           # the joint, at his lips
    c.set(cx + 4.4, 12.8, EMBER)
    c.rect(cx - 2, 11, cx + 2, 12, SKIN)
    _chain(c, cx, 13, look)
    _head(c, cx, 6, look)
    c.shade(SWEAT, None, SWEAT_L, cx, 18)
    c.shade(OVER, OVER_D, OVER_L, cx, 24)
    c.outline()
    return c.image()


def drink(look):
    """A can up to his mouth, head back: NA ZDRAVJE."""
    c = Canvas(32, 41)
    cx = 16
    c.rect(cx - 5, 26, cx - 1, 36, OVER)
    c.rect(cx + 1, 26, cx + 5, 36, OVER)
    c.rect(cx - 6, 37, cx - 1, 38, SHOE)
    c.rect(cx + 1, 37, cx + 6, 38, SHOE)
    c.rect(cx - 6, 39, cx - 1, 39, SOLE)
    c.rect(cx + 1, 39, cx + 6, 39, SOLE)
    c.poly([(cx - 7, 15), (cx + 7, 15), (cx + 6, 27), (cx - 6, 27)], SWEAT)
    c.rect(cx - 7, 15, cx - 5, 17, PATCH)
    c.rect(cx + 5, 15, cx + 7, 17, PATCH)
    _overalls(c, cx, 19, 27)
    c.line(cx - 7, 16, cx - 9, 25, SWEAT, 3)             # one arm down
    c.ellipse(cx - 9.2, 26.4, 1.5, 1.5, SKIN)
    c.line(cx + 7, 16, cx + 9, 10, SWEAT, 3)             # the can up
    c.rect(cx + 4, 6, cx + 7, 11, CAN)
    c.rect(cx + 4, 6, cx + 7, 6, CAN_T)
    c.line(cx + 4, 9, cx + 7, 9, CAN_B)
    c.ellipse(cx + 8.4, 9.6, 1.4, 1.4, SKIN)
    c.rect(cx - 2, 13, cx + 2, 14, SKIN)
    _chain(c, cx, 15, look)
    _head(c, cx - 1, 8, look, eyes="shut", mouth="open")
    c.shade(SWEAT, None, SWEAT_L, cx, 20)
    c.shade(OVER, OVER_D, OVER_L, cx, 28)
    c.outline()
    return c.image()


def zoned(look):
    """Zoned out: sitting on the floor, hunched over a can, staring at nothing."""
    c = Canvas(32, 28)
    cx = 16
    c.line(cx - 6, 22, cx + 10, 24, OVER, 4)             # legs out in front
    c.line(cx - 4, 24, cx + 12, 25, OVER_D, 2)
    c.rect(cx + 10, 22, cx + 13, 26, SHOE)
    c.rect(cx + 13, 22, cx + 13, 26, SOLE)
    c.poly([(cx - 8, 11), (cx + 3, 10), (cx + 4, 22), (cx - 8, 23)], SWEAT)
    c.rect(cx - 6, 14, cx + 2, 22, OVER)
    c.line(cx - 6, 14, cx - 7, 11, OVER_D, 2)
    c.line(cx + 2, 14, cx + 4, 21, OVER_D)
    c.line(cx - 1, 12, cx + 6, 17, SWEAT, 3)             # arms round the can
    c.rect(cx + 6, 14, cx + 9, 19, CAN)
    c.rect(cx + 6, 14, cx + 9, 14, CAN_T)
    c.line(cx + 6, 17, cx + 9, 17, CAN_B)
    c.ellipse(cx + 5.6, 17.4, 1.4, 1.4, SKIN)
    _chain(c, cx - 2, 12, look)
    _head(c, cx - 1, 6, look, eyes="blank", mouth="none")
    c.shade(SWEAT, None, SWEAT_L, cx - 2, 16)
    c.outline()
    return c.image()


def out(look):
    """Passed out on his back, snoring, the can rolled away."""
    c = Canvas(42, 17)
    cy = 9
    c.ellipse(7, cy, 5.0, 4.6, SKIN)                     # head at the left
    for y in range(cy - 5, cy + 5):
        for x in range(1, 5):
            if c.get(x, y) == SKIN and (x + y) % 2 == 0:
                c.set(x, y, STUB)
    c.line(5, cy - 1, 7, cy - 1, EYE)                   # eyes shut
    c.line(5, cy + 2, 7, cy + 2, EYE)
    c.ellipse(10.4, cy, 1.0, 1.3, EYE)                  # mouth open, snoring
    c.poly([(12, cy - 5), (24, cy - 5), (24, cy + 5), (12, cy + 5)], SWEAT)
    c.rect(15, cy - 4, 24, cy + 4, OVER)
    c.rect(24, cy - 4, 36, cy - 1, OVER)                # legs
    c.rect(24, cy + 1, 36, cy + 4, OVER)
    c.rect(36, cy - 5, 38, cy - 1, SHOE)
    c.rect(36, cy + 1, 38, cy + 5, SHOE)
    c.rect(39, cy - 5, 39, cy - 1, SOLE)
    c.rect(39, cy + 1, 39, cy + 5, SOLE)
    c.line(14, cy - 5, 18, cy - 7, SWEAT, 2)            # an arm flung out
    c.ellipse(19, cy - 7.4, 1.3, 1.3, SKIN)
    if look >= 2:
        c.line(13, cy - 2, 13, cy + 2, GOLD)
        c.poly([(2, cy - 6), (5, cy - 7), (4, cy - 9), (2, cy - 8)], GOLD)   # the crown, slipped
    if look >= 3:
        c.set(6, cy - 1, RED_EYE)
    c.shade(SWEAT, None, SWEAT_L, 18, cy)
    c.shade(OVER, OVER_D, OVER_L, 28, cy)
    c.outline()
    return c.image()


def can():
    c = Canvas(7, 10)
    c.rect(1, 1, 5, 8, CAN)
    c.rect(1, 1, 5, 1, CAN_T)
    c.rect(1, 8, 5, 8, CAN_D)
    c.line(1, 4, 5, 4, CAN_B)
    c.set(2, 2, GLINT)
    c.outline()
    return c.image()


def cone():
    """THE BIG ONE: the giant cone, its paper with little flowers, glowing at the wide end."""
    c = Canvas(44, 10)
    c.poly([(1, 4), (1, 5), (40, 8.6), (40, 0.4)], PAPER)
    for x in range(6, 40, 5):
        c.set(x, 4 + (x // 5) % 3 - 1, rgb("#e86fb4"))
    c.rect(40, 1, 42, 8, EMBER)
    c.set(42, 3, rgb("#ffd060"))
    c.set(41, 6, rgb("#ffd060"))
    c.outline()
    return c.image()


def smoke():
    """A puff of smoke (soft, a little see-through)."""
    im = Image.new("RGBA", (14, 11), (0, 0, 0, 0))
    px = im.load()
    rnd = random.Random(59)
    for y in range(11):
        for x in range(14):
            d = ((x - 6.5) / 6.5) ** 2 + ((y - 5.5) / 5.0) ** 2
            for (bx, by, br) in ((4, 6, 3.5), (9, 4.5, 3.8), (8, 7, 3.2)):
                if ((x - bx) ** 2 + (y - by) ** 2) <= br * br and d <= 1.15:
                    shade = 214 if (x + y + rnd.randint(0, 1)) % 3 else 190
                    px[x, y] = (shade, shade - 4, shade + 6, 200)
                    break
    return im


def chainsaw():
    c = Canvas(28, 11)
    c.rect(1, 3, 10, 9, rgb("#e8873a"))                 # the orange body
    c.rect(1, 3, 10, 4, rgb("#f4ecd8"))
    c.line(2, 2, 8, 2, SHOE)                            # the handle
    c.rect(11, 5, 26, 7, rgb("#aab4c4"))                # the bar
    for x in range(11, 27, 2):
        c.set(x, 4, rgb("#5a5e6a"))                     # the chain's teeth
        c.set(x, 8, rgb("#5a5e6a"))
    c.outline()
    return c.image()


def axe():
    c = Canvas(14, 15)
    c.line(2, 13, 10, 3, rgb("#c8955a"), 2)             # the handle
    c.poly([(8, 1), (13, 2), (12, 8), (9, 5)], rgb("#5a6a8a"))   # the head, blue-grey
    c.line(12, 2, 12, 8, rgb("#c8d0e0"))                # the edge
    c.outline()
    return c.image()


def fingerguns_icon():
    """ŠEFE'S FINGER GUNS: a hand making a finger gun, and its PEW."""
    c = Canvas(16, 16)
    c.ellipse(6, 9, 3.6, 3.0, SKIN)
    c.line(8, 7, 13, 7, SKIN, 2)                        # the finger
    c.line(5, 5.5, 5, 7, SKIN, 2)                       # the thumb up
    c.rect(3, 11, 7, 14, SWEAT)                         # the sleeve
    c.set(14, 5, GOLD)
    c.set(15, 4, GOLD)
    c.set(15, 7, GOLD)
    c.shade(SKIN, SKIN_D, None, 6, 9)
    c.outline()
    return c.image()


def pad(im):
    out_im = Image.new("RGBA", (im.width + 2, im.height + 2), (0, 0, 0, 0))
    out_im.paste(im, (1, 1))
    return out_im


def haze(im, gap=0.35, seed=59):
    """The third look: a green haze just outside his outline, here and there."""
    rnd = random.Random(seed)
    res = im.copy()
    src = im.load()
    px = res.load()
    for y in range(im.height):
        for x in range(im.width):
            if src[x, y][3] > 0:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                xx, yy = x + dx, y + dy
                if 0 <= xx < im.width and 0 <= yy < im.height and src[xx, yy][:3] == O[:3] and src[xx, yy][3] > 0:
                    if rnd.random() >= gap:
                        px[x, y] = HAZE
                    break
    return res


def make():
    res = {}
    for name, fn in (("sefe", stand), ("sefe_squat", squat), ("sefe_drink", drink), ("sefe_zoned", zoned), ("sefe_out", out)):
        res[name] = pad(fn(1))
        res[name + "_s2"] = pad(fn(2))
        res[name + "_s3"] = haze(pad(fn(3)))
    res["sefe_can"] = can()
    res["sefe_cone"] = cone()
    res["sefe_smoke"] = smoke()
    res["sefe_chainsaw"] = chainsaw()
    res["sefe_axe"] = axe()
    res["w_sefefingerguns"] = fingerguns_icon()
    return res


if __name__ == "__main__":
    res = make()
    os.makedirs(OUT, exist_ok=True)
    for k, im in res.items():
        im.save(os.path.join(OUT, k + ".png"))
    sheet = os.environ.get("SHEET")
    if sheet:
        Z = 6
        keys = list(res.keys())
        cw = max(res[k].width for k in keys) * Z + 12
        ch = max(res[k].height for k in keys) * Z + 12
        cols = 3
        rows = (len(keys) + cols - 1) // cols
        im = Image.new("RGBA", (cols * cw, rows * ch), (120, 130, 140, 255))
        for i, k in enumerate(keys):
            s = res[k].resize((res[k].width * Z, res[k].height * Z), Image.NEAREST)
            im.paste(s, ((i % cols) * cw + 6, (i // cols) * ch + 6), s)
        im.save(sheet)
    print("wrote %d pictures" % len(res))
