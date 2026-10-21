"""ARCI's stage 2 and 3 pictures, made from the new stage 1 pictures the way today's are made from
today's: stage 2 looks stern (steel-blue eyes under a dark brow), stage 3 adds a dotted gold rim.
resprite/hd/arci{,_lie,_run}.png -> resprite/hd/arci{,_lie,_run}_s2/_s3.png. Eyes and brows are placed
by hand for the SpriteCook pictures of 21 Oct (the lying one has its eyes shut: rim only)."""
import os, sys
from PIL import Image
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from spritecook_fit import HD, lum

STEEL = (90, 106, 138, 255)     # today's stage 2 eye colour
BROW = (20, 16, 24, 255)
GOLD = (242, 201, 76, 255)      # today's stage 3 rim
EYES = {"arci": (53, 12, 57, 15), "arci_run": (65, 20, 70, 23)}           # x0, y0, x1, y1 (x1, y1 not in)
BROWS = {"arci": [(52, 11), (53, 11), (54, 11), (55, 12), (56, 12), (57, 12)],
         "arci_run": [(64, 19), (65, 19), (66, 19), (67, 20), (68, 20), (69, 20)]}

def stern(im, name):
    out = im.copy()
    px = out.load()
    if name in EYES:
        x0, y0, x1, y1 = EYES[name]
        for y in range(y0, y1):
            for x in range(x0, x1):
                c = px[x, y]
                if c[3] >= 128 and 70 <= lum(c) < 230:       # the iris, not the fur or the shine
                    px[x, y] = STEEL
    for (x, y) in BROWS.get(name, []):
        if px[x, y][3] >= 128:
            px[x, y] = BROW
    return out

def rim(im):
    """Every other pair of the outermost pixels turned gold: a dotted rim."""
    out = im.copy()
    px = out.load()
    src = im.load()
    w, h = im.size
    for y in range(h):
        for x in range(w):
            if src[x, y][3] < 128 or ((x + y) // 2) % 2:
                continue
            if any(not (0 <= x + dx < w and 0 <= y + dy < h) or src[x + dx, y + dy][3] < 128
                   for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                px[x, y] = GOLD
    return out

def main():
    for name in ("arci", "arci_lie", "arci_run"):
        im = Image.open(os.path.join(HD, name + ".png")).convert("RGBA")
        s2 = stern(im, name)
        s2.save(os.path.join(HD, name + "_s2.png"))
        rim(s2).save(os.path.join(HD, name + "_s3.png"))
    print("made ARCI's stage 2 and 3 pictures in resprite/hd")

if __name__ == "__main__":
    main()
