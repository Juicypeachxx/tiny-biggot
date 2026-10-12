# Stage 58 (his word, 12 Oct, with ten photos of his dog): "I want stage one boss to be custom ...
# i want my dog to be first boss he is hyperactive border collie". ARČI THE PUSSY SLAYER, the first
# floor's guardian. Our own drawing of his dog, made of shapes (like Rex and the Last Laugh,
# tools/art/stage55_finale.py): a black and white border collie, the white blaze down his face, amber
# eyes, black ears with soft tips, a white ruff and chest, white legs with grey specks, a plumed tail
# with a white tip, a pink tongue; his black sunglasses (two of the photos); asleep on his back with
# his tongue out (two more); a frisbee and a chewed stick. Like every guardian he evolves with his
# stages (his ask, 6 Oct): _s2 his sunglasses (his second phase), _s3 the sunglasses and a gold aura.
# Run from the project folder: python3 tools/art/stage58_arci.py
#   ART_OUT=<folder>   write the pictures there instead (a preview)
#   SHEET=<file.png>   also write a contact sheet, six times the size
import os
import sys
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from stage55_finale import Canvas, O, GLINT, rgb  # noqa: E402

OUT = os.environ.get("ART_OUT", "assets/graphics/")

BK = rgb("#35313d")       # his black coat (a shade above the outline, so it reads)
BK_L = rgb("#4b4656")
BK_S = rgb("#5f5a6c")     # its sheen
WH = rgb("#f2efe6")       # his white
WH_D = rgb("#cfc8bc")
SPECK = rgb("#8d8797")
NOSE = rgb("#1c171f")
EYE_A = rgb("#c98a3a")    # amber eyes
EYE_D = rgb("#7a4a1c")
TONGUE = rgb("#ec7f98")
TONGUE_D = rgb("#c45a74")
SHADE = rgb("#141018")    # the sunglasses
SHADE_L = rgb("#5a6a8a")
DISC = rgb("#e86fb4")     # the frisbee
DISC_D = rgb("#b24a86")
DISC_L = rgb("#ffb4dc")
STICK = rgb("#8a5a34")
STICK_D = rgb("#5e3a20")
STICK_L = rgb("#b07a4a")


def _head(c, hx, hy, cool, tongue=True):
    """His head, looking right: black with the white blaze, the white muzzle, amber eye, soft ears."""
    c.ellipse(hx, hy, 5.6, 4.8, BK)                      # skull
    c.ellipse(hx + 4.6, hy + 2.0, 3.4, 2.3, WH)          # muzzle
    c.ellipse(hx + 1.6, hy + 3.2, 2.6, 1.8, WH)          # the white of his cheek and jaw
    c.line(hx + 0.6, hy - 4.2, hx + 2.4, hy + 1.2, WH, 2)  # the blaze, from his crown to his muzzle
    c.rect(hx + 7.4, hy + 0.8, hx + 8.4, hy + 2.0, NOSE)  # nose
    c.set(hx + 7.6, hy + 0.8, BK_S)
    # Ears: black, half up, the tips folding forward (soft and fluffy, a collie's).
    c.poly([(hx - 4.2, hy - 2.0), (hx - 1.4, hy - 3.0), (hx - 3.0, hy - 6.6)], BK)
    c.poly([(hx - 1.0, hy - 3.6), (hx + 1.8, hy - 3.2), (hx + 0.4, hy - 7.0)], BK)
    c.set(hx + 1.2, hy - 6.6, BK)                        # the tips fold over
    c.set(hx + 1.8, hy - 6.0, BK)
    c.set(hx - 2.0, hy - 6.4, BK)
    c.set(hx - 1.4, hy - 5.8, BK)
    c.set(hx - 4.6, hy - 3.4, BK_L)                      # a tuft at the back of the ear
    if cool:
        # His black sunglasses: a wide lens over the eye, the arm back to the ear.
        c.rect(hx + 1.6, hy - 1.4, hx + 5.4, hy + 0.6, SHADE)
        c.set(hx + 2.6, hy - 1.0, SHADE_L)
        c.set(hx + 3.4, hy - 1.0, SHADE_L)
        c.line(hx - 1.4, hy - 0.6, hx + 1.6, hy - 0.6, SHADE)
    else:
        c.rect(hx + 2.6, hy - 1.2, hx + 3.6, hy - 0.2, EYE_A)  # amber eye
        c.set(hx + 3.6, hy - 0.2, EYE_D)
        c.set(hx + 2.6, hy - 1.2, GLINT)
    if tongue:
        c.rect(hx + 5.0, hy + 3.6, hx + 6.0, hy + 5.2, TONGUE)  # happy, panting
        c.set(hx + 5.0, hy + 5.2, TONGUE_D)


def _legs_stand(c, y0):
    for x, col in ((19.5, WH), (22.5, WH), (7.5, BK), (10.5, BK)):
        c.rect(x, y0, x + 1.5, y0 + 5, col)
        c.rect(x - 0.5, y0 + 4.2, x + 1.8, y0 + 5.2, WH)   # white feet
    c.set(20, y0 + 2, SPECK)
    c.set(23, y0 + 3, SPECK)
    c.set(21, y0 + 4, SPECK)


def arci(cool=False):
    c = Canvas(34, 27)
    # Tail: a plume up and over, black, with its white tip.
    c.line(7, 14, 3.5, 9, BK, 3)
    c.line(3.5, 9, 3, 4, BK, 3)
    c.ellipse(3.4, 3.2, 1.8, 1.8, WH)
    c.set(2, 6, BK_L)
    # Body: black back, white under him; the white ruff on his chest and neck.
    c.ellipse(14, 15, 9.5, 5.6, BK)
    c.ellipse(15, 18.4, 7.5, 2.4, WH)
    c.ellipse(21.6, 14.6, 4.4, 5.6, WH)
    c.ellipse(20.6, 10.6, 3.2, 3.4, WH)                  # the ruff up his neck
    for x, y in ((26, 12), (26, 15), (25.4, 17.4), (18, 7.6), (17.2, 9.4), (24.8, 18.6)):
        c.set(x, y, WH)                                  # the ruff is ragged
    c.set(4.6, 7.4, BK)
    c.set(1.8, 8.6, BK)
    c.set(5.4, 11.2, BK)
    c.set(9, 11, BK_S)
    c.set(13, 10, BK_S)
    c.set(16, 10, BK_L)
    _legs_stand(c, 19)
    _head(c, 24, 7.6, cool)
    c.shade(BK, None, BK_L, 14, 15)
    c.shade(WH, WH_D, None, 20, 14)
    c.outline()
    return c.image()


def arci_run(cool=False):
    """At full stretch: front legs reaching, back legs pushing, ears back, tail streaming."""
    c = Canvas(38, 24)
    c.line(9, 12, 2.5, 9.5, BK, 3)                       # the tail behind him
    c.ellipse(1.8, 9.2, 1.6, 1.6, WH)
    c.ellipse(16, 12.5, 11, 4.8, BK)
    c.ellipse(17, 15.4, 9, 2.0, WH)
    c.ellipse(24.6, 12.6, 4.0, 4.4, WH)
    # Front legs out in front, back legs out behind.
    c.line(26, 15, 32, 19.5, WH, 2)
    c.line(24, 16, 29, 21, WH, 2)
    c.line(9, 15, 3.5, 19.5, BK, 2)
    c.line(11, 16, 7, 21.5, BK, 2)
    c.set(3, 20, WH)
    c.set(6.5, 22, WH)
    c.set(29, 19, SPECK)
    # The head forward and a little down, the ears flat back.
    hx, hy = 28.0, 8.6
    c.ellipse(hx, hy, 5.0, 4.2, BK)
    c.ellipse(hx + 4.6, hy + 1.8, 3.4, 2.2, WH)
    c.ellipse(hx + 1.6, hy + 3.0, 2.4, 1.6, WH)
    c.line(hx + 0.4, hy - 3.8, hx + 2.4, hy + 1.2, WH, 2)
    c.rect(hx + 7.4, hy + 0.6, hx + 8.4, hy + 1.8, NOSE)
    c.poly([(hx - 4.4, hy - 1.0), (hx - 1.0, hy - 3.0), (hx - 8.0, hy - 4.6)], BK)
    if cool:
        c.rect(hx + 1.6, hy - 1.4, hx + 5.4, hy + 0.6, SHADE)
        c.set(hx + 2.6, hy - 1.0, SHADE_L)
        c.line(hx - 1.4, hy - 0.6, hx + 1.6, hy - 0.6, SHADE)
    else:
        c.rect(hx + 2.6, hy - 1.2, hx + 3.6, hy - 0.2, EYE_A)
        c.set(hx + 2.6, hy - 1.2, GLINT)
    c.rect(hx + 5.0, hy + 3.4, hx + 6.2, hy + 5.6, TONGUE)   # tongue out in the wind
    c.set(hx + 6.2, hy + 5.6, TONGUE_D)
    c.shade(BK, None, BK_L, 16, 12)
    c.shade(WH, WH_D, None, 20, 13)
    c.outline()
    return c.image()


def arci_lie(cool=False):
    """Asleep on his back, paws up, tongue out to one side (his photos)."""
    c = Canvas(36, 20)
    c.ellipse(16, 12.5, 11.5, 5.4, BK)                   # his back on the floor
    c.ellipse(16.5, 10.6, 9.5, 3.6, WH)                  # belly and chest up
    c.line(4.5, 13, 0.8, 16.5, BK, 3)                    # the tail flat out
    c.ellipse(0.9, 17.2, 1.4, 1.4, WH)
    # Paws in the air, bent and curled, white with specks.
    for x0, x1, x2 in ((9.5, 7.6, 6.2), (12.6, 12.0, 10.6), (20.6, 22.4, 24.0), (23.6, 26.6, 28.0)):
        c.line(x0, 9, x1, 4.6, WH, 2)
        c.line(x1, 4.6, x2, 3.4, WH, 2)
        c.set(x2, 3.4, SPECK)
    c.set(16, 13.8, BK_L)
    c.set(12, 14.2, BK_L)
    # The head at the right end, upside down: blaze, ears flopped down, tongue out.
    hx, hy = 29.0, 13.0
    c.ellipse(hx, hy, 5.2, 4.4, BK)
    c.ellipse(hx + 3.8, hy + 1.6, 3.0, 2.2, WH)
    c.line(hx - 1.2, hy - 1.6, hx + 3.0, hy + 1.6, WH, 2)
    c.rect(hx + 6.0, hy + 1.6, hx + 7.0, hy + 2.8, NOSE)
    c.poly([(hx - 3.0, hy + 3.4), (hx + 0.6, hy + 4.0), (hx - 2.0, hy + 6.8)], BK)   # an ear flopped down
    if cool:
        c.rect(hx + 0.6, hy - 1.6, hx + 4.6, hy + 0.2, SHADE)
        c.set(hx + 1.6, hy - 1.2, SHADE_L)
    else:
        c.line(hx + 1.2, hy - 0.6, hx + 3.0, hy - 0.6, NOSE)   # eyes shut, happy
    c.rect(hx + 3.6, hy + 3.4, hx + 5.0, hy + 6.4, TONGUE)
    c.set(hx + 5.0, hy + 6.4, TONGUE_D)
    c.shade(BK, None, BK_L, 16, 12)
    c.shade(WH, WH_D, None, 16, 10)
    c.outline()
    return c.image()


def frisbee():
    c = Canvas(12, 6)
    c.ellipse(6, 3, 5.6, 2.6, DISC)
    c.ellipse(6, 2.6, 3.8, 1.4, DISC_L)
    c.ellipse(6, 2.8, 2.2, 0.8, DISC)
    c.line(1.5, 4, 10.5, 4, DISC_D)
    c.outline()
    return c.image()


def stick():
    """His chewing stick, grown big for the fight: knots and bark, chewed at one end."""
    c = Canvas(30, 6)
    c.line(1, 3.4, 28, 2.4, STICK, 3)
    c.line(2, 4.0, 27, 3.2, STICK_D)
    c.line(4, 2.2, 24, 1.6, STICK_L)
    c.set(10, 1, STICK)
    c.set(11, 0, STICK)
    c.set(19, 4.4, STICK_D)
    c.set(0, 3, STICK_D)
    c.set(1, 2, STICK_L)
    c.outline()
    return c.image()


def frisbee_icon():
    """ARČI'S FRISBEE, his drop: the weapon's picture."""
    c = Canvas(16, 16)
    c.ellipse(8, 8.5, 6.8, 4.6, DISC)
    c.ellipse(8, 7.8, 4.8, 2.8, DISC_L)
    c.ellipse(8, 8.2, 2.8, 1.4, DISC)
    c.line(2.5, 10.5, 13.5, 10.5, DISC_D)
    c.set(5, 13, DISC_D)
    c.set(11, 13, DISC_D)
    # A tooth mark: he has had it in his mouth.
    c.set(12, 6, WH)
    c.set(13, 7, WH)
    c.outline()
    return c.image()


GOLD = rgb("#f2c94c")


def pad(im):
    """One clear pixel round the picture (room for the aura; every look the same size)."""
    out = Image.new("RGBA", (im.width + 2, im.height + 2), (0, 0, 0, 0))
    out.paste(im, (1, 1))
    return out


def aura(im, gap=0.3, seed=58):
    """The third look: a gold halo just outside his outline, here and there (a super form)."""
    import random
    rnd = random.Random(seed)
    out = im.copy()
    src = im.load()
    px = out.load()
    for y in range(im.height):
        for x in range(im.width):
            if src[x, y][3] > 0:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                xx, yy = x + dx, y + dy
                if 0 <= xx < im.width and 0 <= yy < im.height and src[xx, yy][:3] == O[:3] and src[xx, yy][3] > 0:
                    if rnd.random() >= gap:
                        px[x, y] = GOLD
                    break
    return out


def make():
    out = {}
    for name, fn in (("arci", arci), ("arci_run", arci_run), ("arci_lie", arci_lie)):
        out[name] = pad(fn(False))
        out[name + "_s2"] = pad(fn(True))
        out[name + "_s3"] = aura(pad(fn(True)))
    out["arci_frisbee"] = frisbee()
    out["arci_stick"] = stick()
    out["w_arcifrisbee"] = frisbee_icon()
    return out


if __name__ == "__main__":
    out = make()
    os.makedirs(OUT, exist_ok=True)
    for k, im in out.items():
        im.save(os.path.join(OUT, k + ".png"))
    sheet = os.environ.get("SHEET")
    if sheet:
        Z = 6
        keys = list(out.keys())
        cw = max(out[k].width for k in keys) * Z + 12
        ch = max(out[k].height for k in keys) * Z + 12
        cols = 3
        rows = (len(keys) + cols - 1) // cols
        im = Image.new("RGBA", (cols * cw, rows * ch), (196, 184, 160, 255))   # the Ossuary's floor colour
        for i, k in enumerate(keys):
            s = out[k].resize((out[k].width * Z, out[k].height * Z), Image.NEAREST)
            im.paste(s, ((i % cols) * cw + 6, (i // cols) * ch + 6), s)
        im.save(sheet)
    print("wrote %d pictures" % len(out))
