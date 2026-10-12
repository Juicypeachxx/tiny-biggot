# Stage 55 (his word, 11 Oct): THE LAST LAUGH, the final final boss, in the form of the alignment
# you gathered most. Four of them, three forms each, their followers, the things they throw and
# their four arenas. Our own drawings, made of shapes (like Rex, tools: rex.gd); no sprite,
# character or name from any game.
#   GOOD    SIR BRAYSALOT, a dim but noble donkey knight with a carrot for a lance (SUPER, then
#           ULTRA HOLY), and his PONY SQUIRES.
#   LAWFUL  SENATOR SCALESWORTH, a big fat politician who is certainly not a lizard (THE MASK
#           SLIPS, then COLD-BLOODED), his LOBBYISTS and INTERNS.
#   CHAOTIC PROPHET NIGH, who has always said the end is nigh (THE SKY IS FALLING, then THE END),
#           and his TRUE BELIEVERS, who flex at you.
#   EVIL    BARON VON CHONK, a fat cat overlord who knocks things off tables at you (THE ZOOMIES,
#           then NINE LIVES), and his kittens.
# Run from the project folder: python3 tools/art/stage55_finale.py
#   ART_OUT=<folder>   write the pictures there instead (a preview)
#   SHEET=<file.png>   also write a contact sheet, four times the size
import math, os, random
from PIL import Image

OUT = os.environ.get("ART_OUT", "assets/graphics/")

O = (20, 15, 28, 255)          # the outline every sprite in the game has
WHITE = (250, 248, 240, 255)
GLINT = (255, 255, 255, 255)
EYE = (30, 22, 30, 255)


def rgb(h):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), 255)


class Canvas:
    def __init__(self, w, h):
        self.w, self.h = w, h
        self.px = [[None] * w for _ in range(h)]

    def set(self, x, y, c):
        x, y = int(math.floor(x)), int(math.floor(y))
        if 0 <= x < self.w and 0 <= y < self.h:
            self.px[y][x] = c

    def get(self, x, y):
        if 0 <= x < self.w and 0 <= y < self.h:
            return self.px[y][x]
        return None

    def ellipse(self, cx, cy, rx, ry, c, only=None):
        for y in range(self.h):
            for x in range(self.w):
                if ((x + 0.5 - cx) / rx) ** 2 + ((y + 0.5 - cy) / ry) ** 2 <= 1.0:
                    if only is None or self.px[y][x] in only:
                        self.px[y][x] = c

    def rect(self, x0, y0, x1, y1, c):
        for y in range(int(y0), int(y1) + 1):
            for x in range(int(x0), int(x1) + 1):
                self.set(x, y, c)

    def line(self, x0, y0, x1, y1, c, w=1):
        n = int(max(abs(x1 - x0), abs(y1 - y0)) * 2) + 1
        for i in range(n + 1):
            t = i / n
            x = x0 + (x1 - x0) * t
            y = y0 + (y1 - y0) * t
            if w <= 1:
                self.set(x, y, c)
            else:
                self.ellipse(x, y, w / 2, w / 2, c)

    def poly(self, pts, c):
        xs = [p[0] for p in pts]
        ys = [p[1] for p in pts]
        for y in range(int(min(ys)), int(max(ys)) + 1):
            for x in range(int(min(xs)), int(max(xs)) + 1):
                if _inside(x + 0.5, y + 0.5, pts):
                    self.set(x, y, c)

    def shade(self, only, dark, light, cx, cy):
        """Pixels of `only` facing down-right from (cx, cy) a shade darker, up-left a shade lighter
        (where they touch the edge of the shape)."""
        src = [row[:] for row in self.px]
        for y in range(self.h):
            for x in range(self.w):
                if src[y][x] != only:
                    continue
                edge_dr = any(self._other(src, x + dx, y + dy, only) for dx, dy in ((1, 0), (0, 1), (1, 1)))
                edge_ul = any(self._other(src, x + dx, y + dy, only) for dx, dy in ((-1, 0), (0, -1), (-1, -1)))
                if edge_dr and (x - cx) + (y - cy) > 0 and dark:
                    self.px[y][x] = dark
                elif edge_ul and (x - cx) + (y - cy) < 0 and light:
                    self.px[y][x] = light

    def _other(self, src, x, y, c):
        return not (0 <= x < self.w and 0 <= y < self.h) or src[y][x] != c

    def outline(self, col=O):
        out = [row[:] for row in self.px]
        for y in range(self.h):
            for x in range(self.w):
                if self.px[y][x] is not None:
                    continue
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    xx, yy = x + dx, y + dy
                    if 0 <= xx < self.w and 0 <= yy < self.h and self.px[yy][xx] not in (None, O):
                        out[y][x] = col
                        break
        self.px = out

    def glow(self, col, gap=0.0, seed=1):
        """A halo one pixel outside the outline (a super form's aura); `gap` leaves some out."""
        rnd = random.Random(seed)
        out = [row[:] for row in self.px]
        for y in range(self.h):
            for x in range(self.w):
                if self.px[y][x] is not None:
                    continue
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    xx, yy = x + dx, y + dy
                    if 0 <= xx < self.w and 0 <= yy < self.h and self.px[yy][xx] == O:
                        if rnd.random() >= gap:
                            out[y][x] = col
                        break
        self.px = out

    def image(self):
        im = Image.new("RGBA", (self.w, self.h), (0, 0, 0, 0))
        for y in range(self.h):
            for x in range(self.w):
                if self.px[y][x] is not None:
                    im.putpixel((x, y), self.px[y][x])
        return im


def _inside(x, y, pts):
    n = len(pts)
    ins = False
    j = n - 1
    for i in range(n):
        xi, yi = pts[i]
        xj, yj = pts[j]
        if (yi > y) != (yj > y) and x < (xj - xi) * (y - yi) / (yj - yi + 1e-9) + xi:
            ins = not ins
        j = i
    return ins


def sparkle(c, x, y, col):
    c.set(x, y, col)
    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        c.set(x + dx, y + dy, col)


def text3(c, x, y, s, col):
    """Tiny 3 x 5 letters for the prophet's sign."""
    F = {
        "E": ["###", "#..", "##.", "#..", "###"], "N": ["#.#", "###", "###", "#.#", "#.#"],
        "D": ["##.", "#.#", "#.#", "#.#", "##."], "!": [".#.", ".#.", ".#.", "...", ".#."],
        "T": ["###", ".#.", ".#.", ".#.", ".#."], "H": ["#.#", "#.#", "###", "#.#", "#.#"],
        "V": ["#.#", "#.#", "#.#", "#.#", ".#."], "O": ["###", "#.#", "#.#", "#.#", "###"],
        "I": ["###", ".#.", ".#.", ".#.", "###"], "G": ["###", "#..", "#.#", "#.#", "###"],
    }
    for ch in s:
        g = F[ch]
        for yy in range(5):
            for xx in range(3):
                if g[yy][xx] == "#":
                    c.set(x + xx, y + yy, col)
        x += 4


def elite(im):
    """Like every elite in the game: darker and richer, with a gold outline where it meets the air."""
    im = im.copy()
    px = im.load()
    src = im.copy().load()
    W, H = im.size
    for y in range(H):
        for x in range(W):
            r, g, b, a = px[x, y]
            if a < 128:
                continue
            if (r, g, b) == O[:3]:
                edge = any(not (0 <= x + dx < W and 0 <= y + dy < H) or src[x + dx, y + dy][3] < 128
                           for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
                if edge:
                    px[x, y] = (242, 201, 76, a)
                continue
            m = max(r, g, b)
            k = 0.82
            px[x, y] = (int(r * k + (r - m) * 0.15 if r < m else r * k), int(g * k), int(b * k), a)
    return im


# ---------------------------------------------------------------- SIR BRAYSALOT (GOOD)
DK = rgb("#958b97")      # donkey grey
DK_D = rgb("#6c6274")
DK_L = rgb("#b9b0b8")
MUZ = rgb("#e2d6cc")
MUZ_D = rgb("#c4b4aa")
EAR_IN = rgb("#e8a0ac")
MANE = rgb("#4a3a3c")
HOOF = rgb("#3e3036")
STEEL = rgb("#aab4c4")
STEEL_D = rgb("#76809a")
STEEL_L = rgb("#dfe6f0")
PLUME = rgb("#d84a4a")
PLUME_D = rgb("#a03038")
CAR = rgb("#ee8a2c")
CAR_D = rgb("#c0621e")
CAR_L = rgb("#ffb45a")
LEAF = rgb("#5aae3c")
LEAF_D = rgb("#3a7e2c")
GOLD = rgb("#f2c94c")
GOLD_D = rgb("#c08a2c")
GOLD_L = rgb("#fff0a0")
HOLY = rgb("#fffbe8")


def carrot_lance(c, x0, y0, x1, y1, base_w, col, dark, light, leaf, leaf_d):
    """A carrot held as a lance: thick at the hoof (with its leaves), sharp at the far end."""
    n = 40
    for i in range(n + 1):
        t = i / n
        x = x0 + (x1 - x0) * t
        y = y0 + (y1 - y0) * t
        w = base_w * (1.0 - t) + 0.6
        c.ellipse(x, y, w / 2, w / 2, col)
    # rings across the carrot
    for t in (0.18, 0.36, 0.54, 0.7):
        x = x0 + (x1 - x0) * t
        y = y0 + (y1 - y0) * t
        c.set(x - 1, y, dark)
        c.set(x, y + 1, dark)
    for i in range(4, n - 6, 3):   # a light edge on the upper side
        t = i / n
        c.set(x0 + (x1 - x0) * t - base_w * (1 - t) * 0.3, y0 + (y1 - y0) * t - base_w * (1 - t) * 0.3, light)
    # leaves at the butt end
    c.line(x0, y0, x0 - 4, y0 + 2, leaf, 2)
    c.line(x0, y0, x0 - 2, y0 + 4, leaf_d, 2)
    c.line(x0, y0, x0 - 5, y0 - 1, leaf, 1)


def donkey_head(c, cx, cy, body, body_d, body_l, muz, muz_d, ear_rim, eye_mode, helmet, mane=None):
    """A donkey's long face, seen from the front: broad ears splayed out, eyes high on the sides,
    a big pale muzzle with big nostrils, and the buck teeth."""
    mane = mane or MANE
    for side in (-1, 1):   # the ears: long and broad, leaning out, dark at the tips
        x0, y0 = cx + side * 3.5, cy - 4
        x1, y1 = cx + side * 10, cy - 15
        c.line(x0, y0, x1, y1, body, 4.6)
        c.line(x0 + side * 0.3, y0 - 1, x1 - side * 0.4, y1 + 1.5, ear_rim, 1.8)
        c.ellipse(x1, y1, 1.7, 1.7, mane)
    c.ellipse(cx, cy - 1, 6.5, 6.0, body)           # the forehead and cheeks
    c.ellipse(cx, cy + 6, 6.2, 5.0, body)
    c.ellipse(cx, cy + 7.5, 5.6, 4.2, muz)          # the big pale muzzle
    c.ellipse(cx, cy + 9.0, 4.8, 2.6, muz_d, only=[muz])
    c.ellipse(cx, cy + 7.0, 5.2, 3.4, muz, only=[muz_d])
    c.shade(body, body_d, body_l, cx - 1, cy)
    for nx in (cx - 3, cx + 2):                     # nostrils
        c.rect(nx, cy + 7, nx + 1, cy + 7, muz_d)
        c.set(nx + (1 if nx < cx else 0), cy + 7, EYE)
    c.line(cx - 3, cy + 10, cx + 3, cy + 10, O)     # the mouth line and the buck teeth
    c.rect(cx - 2, cy + 11, cx - 1, cy + 12, WHITE)
    c.rect(cx + 1, cy + 11, cx + 2, cy + 12, WHITE)
    c.set(cx - 1, cy + 12, muz_d)
    c.set(cx + 2, cy + 12, muz_d)
    for side in (-1, 1):   # eyes, high on the sides of the head
        ex = cx + side * 4 - (1 if side < 0 else 0)
        ey = cy - 1
        if eye_mode == "dim":   # heavy lids, and looking at each other: dim, but noble
            c.rect(ex - 1, ey - 1, ex + 2, ey - 1, O)
            c.rect(ex - 1, ey, ex + 2, ey + 1, WHITE)
            c.rect(ex + 2 if side < 0 else ex - 1, ey, ex + 2 if side < 0 else ex - 1, ey + 1, EYE)
        elif eye_mode == "super":   # wide and glowing
            c.rect(ex - 1, ey - 1, ex + 2, ey + 1, rgb("#bff8ff"))
            c.set(ex + (1 if side < 0 else 0), ey, GLINT)
            c.rect(ex - 1, ey - 2, ex + 2, ey - 2, O)
        else:   # holy: closed, at peace
            c.line(ex - 1, ey + 0.5, ex + 2, ey, EYE)
    c.rect(cx - 1, cy - 7, cx + 1, cy - 4, mane)    # a stiff little forelock
    c.set(cx, cy - 8, mane)
    if helmet:   # a small tin pot of a helmet, perched between the ears
        hc, hd, hl = helmet
        c.ellipse(cx, cy - 6.5, 4.6, 2.8, hc)
        c.line(cx - 5, cy - 4.5, cx + 5, cy - 4.5, hd)
        c.set(cx - 2, cy - 8, hl)
        c.set(cx - 1, cy - 8, hl)
        c.set(cx + 2, cy - 7, hd)   # a dent


def braysalot(form):
    if form == 1:
        c = Canvas(38, 38)
        body, body_d, body_l = DK, DK_D, DK_L
        arm, arm_d, arm_l = STEEL, STEEL_D, STEEL_L
        cx, cy = 17, 17
    elif form == 2:
        c = Canvas(40, 40)
        body, body_d, body_l = rgb("#c8a868"), rgb("#94784a"), rgb("#e8d48a")
        arm, arm_d, arm_l = GOLD, GOLD_D, GOLD_L
        cx, cy = 18, 18
    else:
        c = Canvas(54, 44)
        body, body_d, body_l = rgb("#f4ecd8"), rgb("#c8bca4"), WHITE
        arm, arm_d, arm_l = GOLD, GOLD_D, GOLD_L
        cx, cy = 26, 19
    if form == 3:   # wings first, behind everything
        for side in (-1, 1):
            for k in range(5):
                wx = cx + side * (11 + k * 3)
                wy = cy + 9 - k * 3 + (k * k) * 0.35
                c.ellipse(wx, wy, 3.2, 7.0 - k * 0.6, WHITE)
                c.ellipse(wx + side * 0.8, wy + 2, 2.0, 5.0 - k * 0.5, rgb("#e2dccb"))
    # body in its breastplate
    by = cy + 15
    c.ellipse(cx, by, 9.5, 7.0, body)
    c.ellipse(cx, by - 0.5, 8.0, 6.0, arm)
    c.shade(arm, arm_d, arm_l, cx - 1, by - 2)
    c.line(cx, by - 5, cx, by + 4, arm_d)   # the plate's ridge
    c.set(cx - 3, by - 3, arm_l)
    c.set(cx - 4, by - 2, arm_l)
    if form == 1:   # a dent, and a little red cross for the cause
        c.set(cx + 4, by + 1, arm_d)
        c.rect(cx - 5, by + 1, cx - 3, by + 1, PLUME)
        c.rect(cx - 4, by, cx - 4, by + 2, PLUME)
    else:
        c.ellipse(cx - 4, by + 1, 1.6, 1.6, rgb("#ff5a5a") if form == 2 else rgb("#8ad8ff"))
    # legs and hooves
    for lx in (cx - 6, cx + 4):
        c.rect(lx, by + 5, lx + 2, by + 7, body)
        c.rect(lx, by + 8, lx + 2, by + 9, HOOF if form < 3 else GOLD_D)
    if form == 2:   # the golden mane stands up like a flame, behind the head
        for k, (dx, h) in enumerate(((-3, 7), (-1.5, 10), (0, 12), (1.5, 10), (3, 7))):
            c.line(cx + dx, cy - 4, cx + dx * 1.6, cy - 4 - h, GOLD if k % 2 == 0 else GOLD_L, 2.2)
    # the head (and a helmet in form 1)
    donkey_head(c, cx, cy, body, body_d, body_l, MUZ if form < 3 else rgb("#fffaf0"), MUZ_D if form < 3 else rgb("#e8dcc8"),
                body_d if form < 3 else rgb("#e8c8a0"), "dim" if form == 1 else ("super" if form == 2 else "holy"),
                (STEEL, STEEL_D, STEEL_L) if form == 1 else None,
                GOLD_L if form == 2 else (GOLD if form == 3 else None))
    if form == 1:   # the plume
        c.ellipse(cx + 1, cy - 11, 1.6, 3.0, PLUME)
        c.ellipse(cx + 2, cy - 13, 1.3, 2.2, PLUME)
        c.set(cx + 1, cy - 9, PLUME_D)
    if form == 3:   # the halo
        for a in range(0, 360, 6):
            r = math.radians(a)
            c.set(cx + math.cos(r) * 6.5, cy - 18 + math.sin(r) * 2.0, GOLD)
    # the lance
    if form == 1:
        carrot_lance(c, cx + 9, by + 5, cx + 19, 2, 5.0, CAR, CAR_D, CAR_L, LEAF, LEAF_D)
    elif form == 2:
        carrot_lance(c, cx + 9, by + 5, cx + 20, 1, 5.5, rgb("#ffb030"), rgb("#d07a1a"), rgb("#ffe08a"), LEAF, LEAF_D)
    else:
        carrot_lance(c, cx + 9, by + 5, cx + 22, 1, 6.0, rgb("#fff0b0"), rgb("#e0b860"), WHITE, rgb("#9ae86a"), rgb("#5ab43c"))
    c.ellipse(cx + 8, by + 2, 2.2, 2.0, body)   # the hoof that holds it
    c.outline()
    if form == 2:
        c.glow(rgb("#ffe86a"), 0.25, 3)
        for (x, y) in ((3, 8), (35, 10), (4, 32), (33, 35)):
            sparkle(c, x, y, GOLD_L)
    if form == 3:
        c.glow(rgb("#fff6c0"), 0.35, 5)
        for (x, y) in ((4, 5), (49, 7), (2, 27), (51, 31), (14, 41)):
            sparkle(c, x, y, HOLY)
    return c.image()


def ponysquire(flip=False):
    c = Canvas(18, 17)
    body, body_d = rgb("#a8744a"), rgb("#7a5034")
    c.ellipse(9, 11, 6.0, 3.8, body)            # body, side on
    for lx in (5, 7, 11, 13):
        c.rect(lx, 13, lx, 15, body)
        c.set(lx, 16, HOOF)
    c.ellipse(14.5, 6.5, 2.8, 3.2, body)        # head
    c.ellipse(16.2, 8.2, 1.6, 1.4, rgb("#e2c8a8"))
    c.set(14.5, 6, EYE)
    c.rect(11, 5, 12, 10, rgb("#f0e0b0"))       # cream mane
    c.ellipse(14.2, 3.8, 2.6, 1.6, STEEL)       # tin helmet
    c.set(13.5, 3, STEEL_L)
    c.line(3, 9, 1, 12, rgb("#f0e0b0"), 2)       # tail
    c.rect(7, 8, 8, 9, PLUME)                    # a little saddle cloth
    c.shade(body, body_d, None, 9, 9)
    c.outline()
    im = c.image()
    return im.transpose(Image.FLIP_LEFT_RIGHT) if flip else im


# ---------------------------------------------------------------- SENATOR SCALESWORTH (LAWFUL)
SKIN = rgb("#d6d9b4")       # human, more or less
SKIN_D = rgb("#aeb68a")
HAIR = rgb("#2a2a36")
NAVY = rgb("#2c3a68")
NAVY_D = rgb("#1e2648")
NAVY_L = rgb("#46609a")
SHIRT = rgb("#ecebf0")
TIE = rgb("#c83a3a")
TIE_D = rgb("#902830")
LIZ = rgb("#5e9c4a")
LIZ_D = rgb("#3e6e36")
LIZ_L = rgb("#8ccc6a")
BELLY = rgb("#cfd890")
EYE_Y = rgb("#f0d23c")
TONGUE = rgb("#e05a78")


def senator(form):
    if form < 3:
        c = Canvas(34, 36)
        cx = 16
        # the tail behind: a tip in form 1, all of it in form 2
        if form == 1:
            c.line(25, 33, 29, 31, LIZ, 2)
            c.set(30, 30, LIZ)
        else:
            c.line(23, 30, 30, 32, LIZ, 3)
            c.line(30, 32, 32, 27, LIZ, 2)
            c.set(32, 25, LIZ)
        # legs
        c.rect(cx - 6, 30, cx - 2, 33, NAVY_D)
        c.rect(cx + 1, 30, cx + 5, 33, NAVY_D)
        c.rect(cx - 7, 34, cx - 2, 35, EYE)
        c.rect(cx + 1, 34, cx + 6, 35, EYE)
        # the big belly in a suit
        c.ellipse(cx, 23, 11.0, 9.0, NAVY)
        c.shade(NAVY, NAVY_D, NAVY_L, cx - 2, 21)
        # shirt and tie
        c.poly([(cx - 3, 14), (cx + 3, 14), (cx + 1, 26), (cx - 1, 26)], SHIRT)
        if form == 2:   # buttons popped: the shirt strains open
            c.ellipse(cx, 24, 3.4, 4.5, SHIRT)
            c.ellipse(cx, 25, 2.0, 3.0, BELLY)
        c.poly([(cx - 1, 15), (cx + 1, 15), (cx + 1.5, 23), (cx, 25), (cx - 1.5, 23)], TIE)
        c.set(cx, 16, TIE_D)
        c.set(cx + 6, 17, GOLD)   # lapel pin
        # arms, one up to make a point
        c.ellipse(cx - 11, 22, 2.6, 5.0, NAVY)
        c.ellipse(cx - 11, 27.5, 2.0, 1.8, SKIN if form == 1 else LIZ)
        c.line(cx + 10, 20, cx + 14, 12, NAVY, 4)
        c.ellipse(cx + 14.5, 10, 2.0, 2.0, SKIN if form == 1 else LIZ)
        c.line(cx + 15, 8, cx + 15, 5, SKIN if form == 1 else LIZ)   # the finger: "AND ANOTHER THING"
        # the head
        hy = 9
        c.ellipse(cx, hy, 7.5, 6.8, SKIN)
        c.ellipse(cx, hy + 4.5, 6.4, 3.0, SKIN)   # jowls
        c.shade(SKIN, SKIN_D, None, cx, hy)
        if form == 2:   # the right side of the face slips: scales and a yellow eye
            for y in range(hy - 6, hy + 8):
                for x in range(cx + 1, cx + 9):
                    if c.get(x, y) in (SKIN, SKIN_D):
                        c.set(x, y, LIZ if (x + y) % 3 else LIZ_D)
            for y in range(hy - 6, hy + 8, 2):   # the torn edge of the mask
                c.set(cx + 1, y, SKIN_D)
            c.set(cx, hy + 1, SKIN_D)
        # slick hair with a side part
        c.ellipse(cx, hy - 5, 7.4, 2.8, HAIR)
        c.rect(cx - 7, hy - 5, cx - 6, hy, HAIR)
        c.set(cx - 2, hy - 7, rgb("#5a5a70"))
        c.set(cx - 1, hy - 7, rgb("#5a5a70"))
        # eyes
        c.rect(cx - 4, hy, cx - 3, hy + 1, WHITE)
        c.set(cx - 3, hy + 1, EYE)
        if form == 1:
            c.rect(cx + 2, hy, cx + 3, hy + 1, WHITE)
            c.set(cx + 3, hy + 1, EYE)
        else:
            c.rect(cx + 2, hy - 1, cx + 4, hy + 1, EYE_Y)
            c.line(cx + 3, hy - 1, cx + 3, hy + 1, EYE)
        # a wide, wide grin
        c.line(cx - 4, hy + 4, cx + 4, hy + 4, O)
        c.rect(cx - 3, hy + 5, cx + 3, hy + 5, WHITE)
        c.set(cx - 4, hy + 3, O)
        c.set(cx + 4, hy + 3, O)
        if form == 2:   # the tongue, forked
            c.line(cx + 4, hy + 5, cx + 8, hy + 7, TONGUE)
            c.set(cx + 9, hy + 6, TONGUE)
            c.set(cx + 9, hy + 8, TONGUE)
        c.outline()
        if form == 2:
            for (x, y) in ((2, 3), (30, 2)):
                sparkle(c, x, y, LIZ_L)
        return c.image()
    # form 3: COLD-BLOODED, a big fat lizard in what is left of his tie
    c = Canvas(44, 40)
    cx = 21
    c.line(30, 34, 39, 33, LIZ, 5)   # the tail
    c.line(39, 33, 42, 26, LIZ, 3)
    c.line(42, 26, 41, 21, LIZ, 2)
    for lx in (cx - 8, cx + 4):
        c.rect(lx, 33, lx + 4, 36, LIZ_D)
        for k in range(3):
            c.set(lx + k * 2, 37, rgb("#f4ecd8"))   # claws
    c.ellipse(cx, 25, 13.0, 10.5, LIZ)            # body
    c.ellipse(cx, 26, 9.0, 8.0, BELLY)            # belly
    for y in range(20, 34, 3):
        c.line(cx - 7, y, cx + 7, y, rgb("#aeb878"))
    c.ellipse(cx, 26, 9.0, 8.0, BELLY, only=[])   # (keeps the lines)
    c.shade(LIZ, LIZ_D, LIZ_L, cx, 22)
    # the frill spread round the neck
    for a in range(200, 341, 10):
        r = math.radians(a)
        c.line(cx, 13, cx + math.cos(r) * 15, 13 + math.sin(r) * 9, rgb("#e8732a"), 2)
    c.ellipse(cx, 12, 13, 7, rgb("#f0a040"), only=[rgb("#e8732a")])
    # arms with claws
    c.line(cx - 12, 22, cx - 16, 28, LIZ, 4)
    c.line(cx + 12, 22, cx + 16, 16, LIZ, 4)
    for k in range(3):
        c.set(cx - 18 + k, 30, rgb("#f4ecd8"))
        c.set(cx + 17 + k, 14 - k, rgb("#f4ecd8"))
    # head
    c.ellipse(cx, 12, 8.5, 6.5, LIZ)
    c.ellipse(cx, 15, 7.5, 3.5, LIZ)
    c.shade(LIZ, LIZ_D, LIZ_L, cx, 11)
    for (x, y) in ((cx - 4, 8), (cx + 3, 7), (cx, 10), (cx - 6, 12), (cx + 6, 12)):
        c.set(x, y, LIZ_D)   # scales
    for side in (-1, 1):   # yellow eyes with slits
        ex = cx + side * 4 - (1 if side < 0 else 0)
        c.rect(ex, 9, ex + 2, 11, EYE_Y)
        c.line(ex + 1, 9, ex + 1, 11, EYE)
    c.line(cx - 6, 16, cx + 6, 16, O)   # the grin
    for x in range(cx - 5, cx + 6, 2):
        c.set(x, 17, WHITE)
    # what is left of the tie
    c.poly([(cx - 1, 19), (cx + 1, 19), (cx + 2, 25), (cx, 27), (cx - 2, 25)], TIE)
    c.set(cx + 1, 26, None)
    c.outline()
    c.glow(rgb("#9ae86a"), 0.5, 7)
    return c.image()


def lobbyist():
    c = Canvas(14, 17)
    c.ellipse(7, 11, 4.5, 4.0, rgb("#6e6e80"))   # grey suit
    c.poly([(6, 8), (8, 8), (7.5, 13), (6.5, 13)], TIE)
    c.rect(4, 14, 5, 15, EYE)
    c.rect(9, 14, 10, 15, EYE)
    c.ellipse(7, 5, 3.6, 3.4, LIZ)               # head
    c.rect(5, 4, 6, 5, EYE_Y)
    c.set(5, 4, EYE)
    c.rect(8, 4, 9, 5, EYE_Y)
    c.set(9, 4, EYE)
    c.line(5, 7, 9, 7, O)
    c.rect(10, 11, 13, 14, rgb("#7a4a2a"))       # the briefcase
    c.line(11, 10, 12, 10, rgb("#3a2a1a"))
    c.set(11, 12, GOLD)
    c.line(1, 14, 3, 12, LIZ)                    # tail
    c.outline()
    return c.image()


def intern():
    c = Canvas(13, 12)
    c.ellipse(6, 7.5, 3.6, 2.8, rgb("#8ccc6a"))
    c.ellipse(6, 4, 3.0, 2.6, rgb("#8ccc6a"))
    c.set(5, 3, EYE)
    c.set(7, 3, EYE)
    c.line(1, 9, 3, 8, rgb("#8ccc6a"))
    c.rect(9, 6, 11, 9, WHITE)                    # the coffee
    c.rect(9, 6, 11, 6, rgb("#6a4a2a"))
    c.set(12, 7, WHITE)
    c.rect(4, 10, 4, 10, rgb("#5e9c4a"))
    c.rect(8, 10, 8, 10, rgb("#5e9c4a"))
    c.outline()
    return c.image()


# ---------------------------------------------------------------- PROPHET NIGH (CHAOTIC)
ROBE = rgb("#94704a")
ROBE_D = rgb("#6a4e34")
ROBE_L = rgb("#b48c5e")
FLESH = rgb("#dca882")
FLESH_D = rgb("#b07a5a")
BEARD = rgb("#e8e8f0")
BEARD_D = rgb("#b0b0c0")
CARD = rgb("#cfa872")
CARD_D = rgb("#a07c4c")
INK = rgb("#4a2a20")
FIRE = rgb("#ff8a2a")
FIRE_L = rgb("#ffd84a")
FIRE_D = rgb("#d8443c")


def flames(c, x0, x1, y, h, seed):
    rnd = random.Random(seed)
    for x in range(x0, x1 + 1):
        hh = h * (0.5 + rnd.random() * 0.6)
        c.line(x, y, x + rnd.choice((-1, 0, 1)), y - hh, FIRE)
        c.line(x, y, x, y - hh * 0.5, FIRE_L)
        if rnd.random() < 0.3:
            c.set(x, y - hh - 1, FIRE_D)


def prophet(form):
    if form < 3:
        c = Canvas(34, 40)
        cx = 17
        top = 6
        # the robe
        c.poly([(cx - 8, 22), (cx + 8, 22), (cx + 11, 37), (cx - 11, 37)], ROBE)
        c.ellipse(cx, 23, 8.5, 5.0, ROBE)
        c.shade(ROBE, ROBE_D, ROBE_L, cx, 26)
        c.line(cx - 8, 28, cx + 8, 28, rgb("#5a4028"))   # rope belt
        c.line(cx + 2, 28, cx + 3, 32, rgb("#5a4028"))
        if form == 2:   # singed
            for (x, y) in ((cx - 6, 33), (cx + 5, 35), (cx - 2, 36), (cx + 8, 31)):
                c.set(x, y, rgb("#3a2a20"))
        # sandals
        c.rect(cx - 6, 38, cx - 3, 39, rgb("#6a4a2a"))
        c.rect(cx + 3, 38, cx + 6, 39, rgb("#6a4a2a"))
        # arms up, holding the sign
        c.line(cx - 7, 22, cx - 10, top + 9, ROBE, 4)
        c.line(cx + 7, 22, cx + 10, top + 9, ROBE, 4)
        c.ellipse(cx - 10, top + 8, 1.8, 1.8, FLESH)
        c.ellipse(cx + 10, top + 8, 1.8, 1.8, FLESH)
        # head with wild hair and a long beard
        hy = 17
        c.ellipse(cx, hy - 1, 7.0, 5.0, BEARD)        # the hair, everywhere
        for k in range(9):
            a = math.radians(200 + k * 17)
            c.line(cx, hy - 2, cx + math.cos(a) * 9, hy - 2 + math.sin(a) * 6, BEARD)
        c.ellipse(cx, hy, 4.5, 4.2, FLESH)
        c.poly([(cx - 4, hy + 2), (cx + 4, hy + 2), (cx + 2, hy + 10), (cx, hy + 12), (cx - 2, hy + 10)], BEARD)
        c.shade(BEARD, BEARD_D, None, cx, hy)
        # eyes: wide open, tiny pupils (red and glowing in form 2)
        for ex in (cx - 3, cx + 1):
            c.rect(ex, hy - 1, ex + 1, hy, WHITE)
            c.set(ex + (1 if ex < cx else 0), hy - 1, EYE if form == 1 else FIRE_D)
        if form == 2:
            c.set(cx - 2, hy - 2, FIRE_L)
            c.set(cx + 2, hy - 2, FIRE_L)
        # the shouting mouth
        c.rect(cx - 1, hy + 2, cx + 1, hy + 4, rgb("#5a1a1a"))
        c.set(cx, hy + 4, TONGUE)
        # the sign over his head
        c.rect(cx - 10, top, cx + 10, top + 8, CARD)
        c.rect(cx - 10, top + 8, cx + 10, top + 8, CARD_D)
        c.set(cx + 9, top, CARD_D)
        c.set(cx - 10, top + 3, CARD_D)
        text3(c, cx - 8, top + 2, "END", INK)
        text3(c, cx + 4, top + 2, "!", rgb("#c83a3a"))
        c.line(cx + 6, top + 1, cx + 8, top + 7, CARD_D)   # a fold in the cardboard
        if form == 2:
            flames(c, cx - 9, cx + 9, top - 1, 6, 11)
        c.outline()
        if form == 2:
            for (x, y) in ((2, 20), (31, 16), (4, 34)):
                c.set(x, y, FIRE_L)
                c.set(x, y - 1, FIRE)
        return c.image()
    # form 3: THE END. Huge, afloat, burning
    c = Canvas(44, 46)
    cx = 22
    for k in range(7):   # a ragged robe that ends in flames
        x = cx - 12 + k * 4
        c.line(x, 30, x + (1 if k % 2 else -1), 42 - (k % 3), ROBE_D, 3)
    c.ellipse(cx, 29, 12.0, 8.0, ROBE_D)
    for (x0, y0, x1, y1) in ((cx - 7, 24, cx - 4, 33), (cx + 6, 25, cx + 3, 35), (cx - 1, 27, cx + 1, 37)):
        c.line(x0, y0, x1, y1, FIRE, 1)   # cracks of fire
    flames(c, cx - 12, cx + 12, 43, 4, 21)
    # arms flung up to a blazing tablet
    c.line(cx - 10, 26, cx - 15, 9, ROBE_D, 5)
    c.line(cx + 10, 26, cx + 15, 9, ROBE_D, 5)
    c.rect(cx - 15, 1, cx + 15, 10, rgb("#5a4a44"))
    c.rect(cx - 14, 2, cx + 14, 9, rgb("#3a302c"))
    text3(c, cx - 10, 3, "THE", FIRE_L)
    text3(c, cx + 3, 3, "END", FIRE_L)
    flames(c, cx - 14, cx + 14, 1, 3, 31)
    # head: hair like white fire, eyes white light
    hy = 20
    for k in range(13):
        a = math.radians(190 + k * 13)
        c.line(cx, hy - 2, cx + math.cos(a) * 12, hy - 2 + math.sin(a) * 9, BEARD, 2)
    c.ellipse(cx, hy, 5.5, 5.0, FLESH)
    c.poly([(cx - 5, hy + 2), (cx + 5, hy + 2), (cx + 3, hy + 12), (cx, hy + 14), (cx - 3, hy + 12)], BEARD)
    c.rect(cx - 4, hy - 1, cx - 2, hy, GLINT)
    c.rect(cx + 2, hy - 1, cx + 4, hy, GLINT)
    c.rect(cx - 2, hy + 2, cx + 2, hy + 5, rgb("#2a0a0a"))
    c.rect(cx - 1, hy + 3, cx + 1, hy + 4, FIRE)
    c.outline()
    c.glow(rgb("#ff6a2a"), 0.3, 9)
    for (x, y) in ((3, 14), (40, 18), (6, 38), (39, 40)):
        c.set(x, y, FIRE_L)
        c.set(x, y - 1, FIRE)
    return c.image()


def believer(flex):
    c = Canvas(20, 20)
    cx = 10
    c.poly([(cx - 4, 10), (cx + 4, 10), (cx + 5, 17), (cx - 5, 17)], ROBE)   # robe from the waist
    c.rect(cx - 4, 18, cx - 2, 19, rgb("#6a4a2a"))
    c.rect(cx + 2, 18, cx + 4, 19, rgb("#6a4a2a"))
    c.ellipse(cx, 9, 5.5, 3.8, FLESH)          # a chest like a barrel
    c.line(cx, 7, cx, 11, FLESH_D)
    c.set(cx - 2, 9, FLESH_D)
    c.set(cx + 2, 9, FLESH_D)
    if flex:   # both arms up: the double biceps
        for s in (-1, 1):
            c.line(cx + s * 5, 8, cx + s * 8, 7, FLESH, 3)
            c.line(cx + s * 8, 7, cx + s * 8, 2, FLESH, 3)
            c.ellipse(cx + s * 7, 5.5, 2.2, 1.8, FLESH)   # the bulge
            c.set(cx + s * 8, 1, FLESH_D)
    else:   # arms crossed
        c.line(cx - 6, 8, cx - 6, 12, FLESH, 3)
        c.line(cx + 6, 8, cx + 6, 12, FLESH, 3)
        c.line(cx - 5, 12, cx + 5, 11, FLESH, 2)
    c.ellipse(cx, 3.5, 2.8, 2.8, FLESH)        # small bald head
    c.set(cx - 1, 3, EYE)
    c.set(cx + 1, 3, EYE)
    c.line(cx - 1, 5, cx + 1, 5, FLESH_D)
    c.set(cx - 1, 1, rgb("#f4d0b0"))           # the shine
    c.outline()
    if flex:
        sparkle(c, 2, 2, GLINT)
        sparkle(c, 17, 1, GLINT)
    return c.image()


# ---------------------------------------------------------------- BARON VON CHONK (EVIL)
FUR = rgb("#6c6a7e")
FUR_D = rgb("#4a485a")
FUR_L = rgb("#9a98ac")
CHEST = rgb("#f0ece4")
PINK = rgb("#e88ca0")
CUSH = rgb("#7a3c8c")
CUSH_D = rgb("#56286a")
CUSH_L = rgb("#a05ab4")


def cat_face(c, cx, cy, eyes, fur, fur_d):
    # ears
    for s in (-1, 1):
        c.poly([(cx + s * 3, cy - 4), (cx + s * 9, cy - 4), (cx + s * 7.5, cy - 11)], fur)
        c.poly([(cx + s * 4.5, cy - 4.5), (cx + s * 7.5, cy - 4.5), (cx + s * 6.8, cy - 8.5)], PINK)
    c.ellipse(cx, cy, 9.0, 6.5, fur)
    for s in (-1, 1):   # tabby stripes on the forehead
        c.line(cx + s * 1, cy - 6, cx + s * 1, cy - 3, fur_d)
    c.line(cx, cy - 6, cx, cy - 4, fur_d)
    c.ellipse(cx, cy + 2.5, 4.5, 3.0, CHEST)   # muzzle
    c.set(cx, cy + 1, PINK)
    c.set(cx - 1, cy + 1, PINK)
    c.line(cx - 2, cy + 3, cx - 1, cy + 4, O)   # the smug "w"
    c.line(cx, cy + 3, cx - 1, cy + 4, O)
    c.line(cx, cy + 3, cx + 1, cy + 4, O)
    c.line(cx + 1, cy + 3, cx + 2, cy + 3, O)
    for s in (-1, 1):   # whiskers
        c.line(cx + s * 4, cy + 2, cx + s * 10, cy + 1, WHITE)
        c.line(cx + s * 4, cy + 3, cx + s * 10, cy + 4, WHITE)
    for s in (-1, 1):
        ex = cx + s * 4 - (1 if s < 0 else 0)
        if eyes == "smug":   # half shut, yellow, slit
            c.rect(ex - 1, cy - 2, ex + 2, cy - 1, rgb("#e8c83a"))
            c.line(ex - 1, cy - 2, ex + 2, cy - 2, fur_d)
            c.set(ex + (1 if s < 0 else 0), cy - 1, EYE)
        elif eyes == "wild":   # wide, the pupils huge
            c.rect(ex - 1, cy - 3, ex + 2, cy, rgb("#e8c83a"))
            c.rect(ex, cy - 3, ex + 1, cy, EYE)
            c.set(ex, cy - 3, GLINT)
        else:   # red light
            c.rect(ex - 1, cy - 2, ex + 2, cy - 1, rgb("#ff3a3a"))
            c.rect(ex, cy - 2, ex + 1, cy - 2, rgb("#ffd0d0"))


def chonk(form):
    if form == 1:
        c = Canvas(38, 32)
        cx = 19
        c.ellipse(cx, 27, 17.0, 4.5, CUSH)            # the velvet cushion
        c.ellipse(cx, 26, 15.0, 3.0, CUSH_L)
        c.ellipse(cx, 26.5, 13.0, 2.6, CUSH, only=[CUSH_L])
        for x in (cx - 16, cx + 16):
            c.rect(x, 29, x, 31, GOLD)                 # tassels
        c.line(cx + 12, 25, cx + 17, 19, FUR, 3)       # tail up the side
        c.ellipse(cx, 19, 12.5, 8.0, FUR)              # the round, round body
        c.ellipse(cx, 20, 7.0, 6.0, CHEST)
        for x in (cx - 9, cx - 6, cx + 6, cx + 9):
            c.line(x, 14, x + (1 if x > cx else -1), 18, FUR_D)
        c.ellipse(cx - 4, 25, 2.5, 1.6, CHEST)          # tiny paws
        c.ellipse(cx + 4, 25, 2.5, 1.6, CHEST)
        c.shade(FUR, FUR_D, FUR_L, cx, 17)
        cat_face(c, cx, 10, "smug", FUR, FUR_D)
        # the crown, a little to one side, and a monocle
        c.poly([(cx - 3, 3), (cx + 4, 3), (cx + 4, 0), (cx + 2, 1.5), (cx + 0.5, -0.5), (cx - 1, 1.5), (cx - 3, 0)], GOLD)
        c.set(cx, 2, rgb("#d8443c"))
        for a in range(0, 360, 30):
            r = math.radians(a)
            c.set(cx + 4.5 + math.cos(r) * 2.4, 8 + math.sin(r) * 2.4, GOLD)
        c.line(cx + 6, 10, cx + 8, 16, GOLD_D)
        c.outline()
        return c.image()
    if form == 2:   # THE ZOOMIES: fur on end, eyes like saucers, tail a bottle brush
        c = Canvas(40, 34)
        cx = 20
        rnd = random.Random(4)
        c.line(cx + 11, 24, cx + 16, 6, FUR, 5)        # the puffed tail
        for k in range(12):
            y = 8 + k * 1.4
            c.set(cx + 16 + rnd.choice((-3, -2, 2, 3)), y, FUR)
        c.ellipse(cx, 21, 12.5, 8.5, FUR)
        for k in range(16):   # bristling fur all round
            a = math.radians(180 + k * 12)
            c.line(cx + math.cos(a) * 11, 21 + math.sin(a) * 7, cx + math.cos(a) * 14, 21 + math.sin(a) * 10, FUR)
        c.ellipse(cx, 22, 7.0, 6.0, CHEST)
        for lx in (cx - 8, cx - 3, cx + 3, cx + 8):   # legs mid-scramble
            c.rect(lx - 1, 28, lx + 1, 31, FUR)
            c.rect(lx - 1, 32, lx + 1, 32, CHEST)
        c.shade(FUR, FUR_D, FUR_L, cx, 19)
        cat_face(c, cx, 12, "wild", FUR, FUR_D)
        c.poly([(cx + 6, 3), (cx + 12, 4), (cx + 11, 1), (cx + 9, 2), (cx + 8, 0), (cx + 7, 2)], GOLD)   # crown askew
        c.line(cx - 8, 15, cx - 11, 22, GOLD_D)          # the monocle hangs on its chain
        for a in range(0, 360, 40):
            r = math.radians(a)
            c.set(cx - 11 + math.cos(r) * 1.8, 23.5 + math.sin(r) * 1.8, GOLD)
        c.outline()
        for (x0, y0) in ((1, 14), (1, 20), (2, 26)):   # motion lines
            c.line(x0, y0, x0 + 4, y0, WHITE)
        return c.image()
    # form 3: NINE LIVES. Huge, a black-and-white tuxedo, a royal cape, three ghost tails, eyes of red light
    c = Canvas(50, 44)
    cx = 25
    FB, FB_D, FB_L = rgb("#38344a"), rgb("#24202e"), rgb("#58527a")
    GHOST = rgb("#b48cff")
    GHOST_D = rgb("#8a64d8")
    for k, ang in enumerate((-58, -22, 16)):   # ghost tails fanned out behind
        r = math.radians(ang - 90)
        c.line(cx + 6, 32, cx + 6 + math.cos(r) * 19, 32 + math.sin(r) * 17, GHOST if k != 1 else GHOST_D, 3.2)
    c.poly([(cx - 10, 20), (cx + 10, 20), (cx + 20, 42), (cx - 20, 42)], rgb("#8a1a2a"))   # the cape
    c.poly([(cx - 9, 21), (cx + 9, 21), (cx + 12, 30), (cx - 12, 30)], rgb("#a8283a"))
    c.line(cx - 20, 42, cx + 20, 42, WHITE)
    for x in range(cx - 19, cx + 20, 4):
        c.set(x, 41, EYE)   # ermine
    c.ellipse(cx, 31, 12.5, 9.5, FB)                  # the body
    c.ellipse(cx, 32, 7.5, 8.0, CHEST)               # the white shirt front of a tuxedo cat
    c.shade(FB, FB_D, FB_L, cx, 28)
    c.ellipse(cx - 5, 39.5, 3.0, 1.8, CHEST)          # white paws
    c.ellipse(cx + 5, 39.5, 3.0, 1.8, CHEST)
    c.rect(cx - 2, 24, cx + 2, 25, rgb("#d8443c"))   # a bow tie, the colour of blood
    c.set(cx, 24, rgb("#ff7a7a"))
    for s2 in (-1, 1):                                # the cape's ermine collar
        c.rect(cx + s2 * 11 - (3 if s2 > 0 else 0), 20, cx + s2 * 11 + (3 if s2 < 0 else 0), 22, WHITE)
        c.set(cx + s2 * 10, 21, EYE)
    # the head, big, with a white blaze and muzzle
    hx, hy = cx, 15
    for s2 in (-1, 1):
        c.poly([(hx + s2 * 3, hy - 4), (hx + s2 * 10, hy - 4), (hx + s2 * 8.5, hy - 12)], FB)
        c.poly([(hx + s2 * 4.5, hy - 4.5), (hx + s2 * 8.5, hy - 4.5), (hx + s2 * 7.6, hy - 9)], rgb("#c86a8a"))
    c.ellipse(hx, hy, 10.0, 7.5, FB)
    c.shade(FB, FB_D, FB_L, hx, hy - 2)
    c.poly([(hx - 1, hy - 7), (hx + 1, hy - 7), (hx + 3, hy + 1), (hx - 3, hy + 1)], CHEST)   # the blaze
    c.ellipse(hx, hy + 3.0, 5.0, 3.4, CHEST)          # muzzle
    c.set(hx, hy + 1, PINK)
    c.set(hx - 1, hy + 1, PINK)
    c.line(hx - 3, hy + 4, hx + 3, hy + 4, O)         # the grin
    c.set(hx - 3, hy + 3, O)
    c.set(hx + 3, hy + 3, O)
    c.set(hx - 2, hy + 5, WHITE)                      # fangs
    c.set(hx + 2, hy + 5, WHITE)
    for s2 in (-1, 1):                                # whiskers
        c.line(hx + s2 * 5, hy + 2, hx + s2 * 12, hy + 1, WHITE)
        c.line(hx + s2 * 5, hy + 3, hx + s2 * 12, hy + 4, WHITE)
    for s2 in (-1, 1):                                # eyes of red light, slanted
        ex = hx + s2 * 5 - (1 if s2 < 0 else 0)
        c.rect(ex - 1, hy - 2, ex + 2, hy - 1, rgb("#ff3a3a"))
        c.rect(ex, hy - 2, ex + 1, hy - 2, rgb("#ffd0d0"))
        c.set(ex + (2 if s2 < 0 else -1), hy - 3, FB_D)
    c.poly([(hx - 6, hy - 6), (hx + 6, hy - 6), (hx + 7, hy - 13), (hx + 4, hy - 9), (hx + 2, hy - 14), (hx, hy - 10),
            (hx - 2, hy - 14), (hx - 4, hy - 9), (hx - 7, hy - 13)], GOLD)   # the crown
    c.set(hx, hy - 8, rgb("#d8443c"))
    c.set(hx - 4, hy - 7, rgb("#4d9be6"))
    c.set(hx + 4, hy - 7, rgb("#4d9be6"))
    c.line(hx - 6, hy - 6, hx + 6, hy - 6, GOLD_D)
    c.outline()
    c.glow(rgb("#ff3a5a"), 0.45, 13)
    return c.image()


def kitten(col, col_d):
    c = Canvas(12, 11)
    c.ellipse(6, 7.5, 3.8, 2.6, col)
    c.ellipse(6, 4.5, 3.4, 2.8, col)
    c.poly([(3, 3), (5, 3), (3.5, 0)], col)
    c.poly([(7, 3), (9, 3), (8.5, 0)], col)
    c.rect(4, 4, 4, 5, EYE)
    c.rect(7, 4, 7, 5, EYE)
    c.set(4, 4, GLINT)
    c.set(7, 4, GLINT)
    c.set(5.5, 6, PINK)
    c.line(9, 8, 11, 5, col)
    c.set(4, 10, col_d)
    c.set(8, 10, col_d)
    c.outline()
    return c.image()


# ---------------------------------------------------------------- what they throw and drop
def prop(kind):
    if kind == "vase":
        c = Canvas(9, 11)
        c.ellipse(4.5, 7, 3.6, 3.4, rgb("#4d9be6"))
        c.rect(3, 1, 5, 4, rgb("#4d9be6"))
        c.rect(2, 1, 6, 1, rgb("#4d9be6"))
        c.line(1.5, 7, 7.5, 7, WHITE)
        c.set(3, 5, rgb("#bfe0ff"))
    elif kind == "mug":
        c = Canvas(9, 8)
        c.rect(1, 1, 5, 6, WHITE)
        c.rect(1, 1, 5, 1, rgb("#6a4a2a"))
        c.rect(6, 2, 7, 5, WHITE)
        c.set(6, 3, None)
        c.set(3, 4, rgb("#d8443c"))
    elif kind == "bowl":
        c = Canvas(11, 10)
        c.ellipse(5.5, 5.5, 4.6, 4.0, rgb("#bfe8ff"))
        c.rect(2, 1, 8, 2, rgb("#bfe8ff"))
        c.ellipse(5, 6, 1.6, 1.0, rgb("#f08a2a"))
        c.set(7, 6, rgb("#f08a2a"))
        c.set(3, 4, WHITE)
    elif kind == "pot":
        c = Canvas(9, 11)
        c.poly([(1, 5), (8, 5), (7, 10), (2, 10)], rgb("#c8643a"))
        c.rect(1, 5, 7, 5, rgb("#a04a2a"))
        c.line(4.5, 5, 2, 0, LEAF, 2)
        c.line(4.5, 5, 7, 1, LEAF_D, 2)
    elif kind == "carrot":
        c = Canvas(7, 12)
        c.poly([(1, 3), (6, 3), (3.5, 11.5)], CAR)
        c.line(2, 5, 4, 5, CAR_D)
        c.line(3, 8, 4, 8, CAR_D)
        c.line(3.5, 3, 1.5, 0, LEAF)
        c.line(3.5, 3, 5.5, 0, LEAF_D)
    elif kind == "meteor":
        c = Canvas(12, 12)
        c.line(1, 1, 7, 7, FIRE, 3)
        c.line(2, 1, 6, 5, FIRE_L, 1)
        c.ellipse(7.5, 7.5, 3.6, 3.6, rgb("#6a5048"))
        c.set(7, 7, rgb("#8a6a5a"))
        c.set(9, 8, rgb("#4a3430"))
    elif kind == "stamp":
        c = Canvas(13, 13)
        c.rect(5, 0, 7, 4, rgb("#8a5a3a"))
        c.ellipse(6, 1, 2.4, 1.4, rgb("#a8744a"))
        c.rect(1, 5, 11, 8, rgb("#6a4a3a"))
        c.rect(0, 9, 12, 11, rgb("#c83a3a"))
        text3(c, 1, 9, "", WHITE)
    elif kind == "table":
        c = Canvas(26, 12)
        c.rect(0, 0, 25, 3, rgb("#8a5a3a"))
        c.rect(0, 0, 25, 0, rgb("#b4805a"))
        c.rect(2, 4, 3, 11, rgb("#6a4228"))
        c.rect(22, 4, 23, 11, rgb("#6a4228"))
    c.outline()
    return c.image()


# ---------------------------------------------------------------- the arenas' tiles
def kit(src, ramp_floor, ramp_wall, ramp_cap, tint_seed):
    """Re-colours one of the game's own tile sets (256 x 64: row 0 floors, row 1 walls, rows 2-3
    the pillar) by light: each pixel takes the colour of its brightness on the arena's own ramps."""
    im = Image.open(src).convert("RGBA")
    px = im.load()
    out = Image.new("RGBA", im.size, (0, 0, 0, 0))
    po = out.load()
    rnd = random.Random(tint_seed)

    def on_ramp(ramp, v):
        v = max(0.0, min(0.999, v))
        i = v * (len(ramp) - 1)
        a, b = ramp[int(i)], ramp[min(len(ramp) - 1, int(i) + 1)]
        f = i - int(i)
        return tuple(int(a[k] + (b[k] - a[k]) * f) for k in range(3))

    lum = [[0.0] * im.width for _ in range(im.height)]
    lo, hi = {}, {}
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            v = (0.3 * r + 0.59 * g + 0.11 * b) / 255.0
            lum[y][x] = v
            band = 0 if y < 16 else (1 if y < 32 else 2)
            lo[band] = min(lo.get(band, 1.0), v)
            hi[band] = max(hi.get(band, 0.0), v)
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            band = 0 if y < 16 else (1 if y < 32 else 2)
            v = (lum[y][x] - lo[band]) / max(0.01, hi[band] - lo[band])
            ramp = ramp_floor if band == 0 else (ramp_wall if band == 1 else ramp_cap)
            c = on_ramp(ramp, v)
            po[x, y] = c + (a,)
    return out


def ramp(*hexes):
    return [rgb(h)[:3] for h in hexes]


def make():
    out = {}
    for f in (1, 2, 3):
        sfx = "" if f == 1 else "_s%d" % f
        out["braysalot" + sfx] = braysalot(f)
        out["scalesworth" + sfx] = senator(f)
        out["prophet" + sfx] = prophet(f)
        out["chonk" + sfx] = chonk(f)
    foes = {
        "ponysquire": ponysquire(),
        "lobbyist": lobbyist(),
        "intern": intern(),
        "believer": believer(False),
        "kitten": kitten(rgb("#f0a050"), rgb("#c07030")),
    }
    for k, im in foes.items():
        out[k] = im
        out[k + "_elite"] = elite(im)
    out["believer_flex"] = believer(True)
    out["believer_flex_elite"] = elite(out["believer_flex"])
    for k in ("vase", "mug", "bowl", "pot", "carrot", "meteor", "stamp", "table"):
        out["fp_" + k] = prop(k)
    src = os.path.join(OUT if OUT.endswith("/") else OUT + "/", "kit0.png")
    if not os.path.exists(src):
        src = "assets/graphics/kit0.png"
    out["kit_pasture"] = kit(src, ramp("#2e5a2a", "#3e7a34", "#5a9a44", "#7ab858"), ramp("#3a2a1e", "#5a4028", "#7a5a38"),
                             ramp("#4a3220", "#7a5a38", "#c8a060", "#f2e2a8"), 1)
    out["kit_senate"] = kit(src, ramp("#8a8478", "#b8b2a4", "#d8d2c4", "#f0ece0"), ramp("#3a1418", "#5a2028", "#7a2a32"),
                            ramp("#4a3a20", "#8a6a2a", "#c8a040", "#f2d878"), 2)
    out["kit_endtimes"] = kit(src, ramp("#2a1418", "#3e1e1e", "#5a2a20", "#8a3a22"), ramp("#140a10", "#24121a", "#3a1a20"),
                              ramp("#3a1a1a", "#8a2a1a", "#e8602a", "#ffc84a"), 3)
    out["kit_parlour"] = kit(src, ramp("#3a1a3a", "#4e2450", "#643064", "#7a3c7a"), ramp("#1e1226", "#2e1a38", "#3e2448"),
                             ramp("#2e1a38", "#6a4a2a", "#c8a040", "#f2d878"), 4)
    return out


if __name__ == "__main__":
    out = make()
    os.makedirs(OUT, exist_ok=True)
    for k, im in out.items():
        im.save(os.path.join(OUT, k + ".png"))
    sheet = os.environ.get("SHEET")
    if sheet:
        keys = list(out.keys())
        Z = 4
        cols = 8
        cw = max(out[k].width for k in keys if not k.startswith("kit_")) * Z + 8
        ch = max(out[k].height for k in keys if not k.startswith("kit_")) * Z + 8
        sprites = [k for k in keys if not k.startswith("kit_")]
        rows = (len(sprites) + cols - 1) // cols
        kits = [k for k in keys if k.startswith("kit_")]
        H = rows * ch + len(kits) * (64 * 2 + 6) + 8
        im = Image.new("RGBA", (max(cols * cw, 512 + 8), H), (58, 56, 70, 255))
        for i, k in enumerate(sprites):
            s = out[k].resize((out[k].width * Z, out[k].height * Z), Image.NEAREST)
            im.paste(s, ((i % cols) * cw + 4, (i // cols) * ch + 4), s)
        y = rows * ch + 4
        for k in kits:
            s = out[k].resize((512, 128), Image.NEAREST)
            im.paste(s, (4, y), s)
            y += 134
        im.save(sheet)
    print("wrote %d pictures" % len(out))
