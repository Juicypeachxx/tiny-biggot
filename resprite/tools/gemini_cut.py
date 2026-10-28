"""His Gemini sprites (Style 1, "gritty dark fantasy") cut from his picture and fitted to double
size for the foes they are: resprite/gemini/style-sheet-21oct.jpg -> resprite/hd/<name>.png."""
import os, sys
from PIL import Image
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from inventory import G, ROOT
from gritty import OUTLINE

SRC = os.path.join(ROOT, "resprite", "gemini", "style-sheet-21oct.jpg")
COLS = [(25, 185), (185, 340), (340, 490), (490, 645)]
ROWS = [(115, 270), (270, 385), (385, 545), (545, 705)]
# Style 1's 4 x 4 grid -> the foe each one clearly is (the green blob and the skull match none)
MAP = {"ammomimic": (0, 0), "bat": (0, 1), "bandsman": (0, 2), "beltfeeder": (0, 3), "beltlink": (1, 0),
       "biker": (1, 1), "bloodleech": (1, 2), "bomber": (2, 0), "bogling": (2, 1), "brasswasp": (2, 2),
       "candlewight": (2, 3), "cogling": (3, 1), "copper": (3, 2), "crawler": (3, 3)}

def pink(c):
    r, g, b = c[:3]
    return r >= 150 and b >= 120 and g <= 120 and r - g > 60 and b - g > 40

def cut(im, cell):
    (x0, x1), (y0, y1) = COLS[cell[1]], ROWS[cell[0]]
    px = im.load()
    ps = [(x, y) for y in range(y0, y1) for x in range(x0, x1) if pink(px[x, y])]
    bx0, bx1 = min(p[0] for p in ps), max(p[0] for p in ps) + 1
    by0, by1 = min(p[1] for p in ps), max(p[1] for p in ps) + 1
    c = im.crop((bx0, by0, bx1, by1)).convert("RGBA")
    q = c.load()
    for y in range(c.height):
        for x in range(c.width):
            if pink(q[x, y]):
                q[x, y] = (0, 0, 0, 0)
    return c.crop(c.getbbox())

def fit(spr, w, h):
    k = min(w / spr.width, h / spr.height)
    nw, nh = max(1, round(spr.width * k)), max(1, round(spr.height * k))
    small = spr.resize((nw, nh), Image.BOX)
    a = small.getchannel("A").point(lambda v: 255 if v >= 120 else 0)
    rgb = small.convert("RGB").quantize(colors=24, method=Image.Quantize.MEDIANCUT).convert("RGB")
    small = rgb.convert("RGBA")
    small.putalpha(a)
    return frame(small, w, h)

def frame(small, w, h, outline=True):
    """The shrunk picture stood at the bottom middle of a w x h canvas, with the outline (SpriteCook's
    pictures bring their own: painting another one over the edge pixels eats thin parts)."""
    nw, nh = small.size
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    out.alpha_composite(small, ((w - nw) // 2, h - nh))
    if not outline:
        return out
    px = out.load()
    src = out.copy().load()
    for y in range(h):   # the same thin dark outline as the rest of the look
        for x in range(w):
            if src[x, y][3] >= 128 and any(not (0 <= x + dx < w and 0 <= y + dy < h) or src[x + dx, y + dy][3] < 128
                                           for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                px[x, y] = OUTLINE
    return out

def main():
    im = Image.open(SRC).convert("RGB")
    out = os.path.join(ROOT, "resprite", "hd")
    os.makedirs(out, exist_ok=True)
    for name, cell in MAP.items():
        old = Image.open(os.path.join(G, name + ".png"))
        fit(cut(im, cell), old.width * 2, old.height * 2).save(os.path.join(out, name + ".png"))
    print("cut %d of his Gemini foes into resprite/hd" % len(MAP))

if __name__ == "__main__":
    main()
