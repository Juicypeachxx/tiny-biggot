"""A pick sheet for him: old (the graphic in the game now), new, old elite, new elite, numbered.
    python3 tools/art/compare.py out.png name name ...   (run from anywhere)"""
import os, sys
from PIL import Image, ImageDraw
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
cwd = os.getcwd(); os.chdir(HERE)
from render import *
os.chdir(cwd)
G = os.path.join(HERE, "..", "..", "assets", "graphics")
vb = VIBES["D"]

def load(n):
    p = os.path.join(G, n + ".png")
    return Image.open(p).convert("RGBA") if os.path.exists(p) else None

def elite_of(n):
    src = ELITE_SRC.get(n, n)
    return sprite(src, vb, elite=True) if (src in ELITE or n in ELITE_SRC) else None

out, names = sys.argv[1], sys.argv[2:]
per = 13
cell = max(max(len(S[n][1][0]), len(S[n][1])) for n in names) + 4
rows = (len(names) + per - 1) // per
band = 4 * cell + 12
c = Image.new("RGBA", (per * cell + 40, rows * band), (46, 40, 60, 255)); d = ImageDraw.Draw(c)
for k, n in enumerate(names):
    x = 40 + (k % per) * cell; y = (k // per) * band
    for i, im in enumerate([load(n), sprite(n, vb), load(n + "_elite"), elite_of(n)]):
        if im is not None:
            c.alpha_composite(im, (x, y + 2 + i * cell))
    d.text((x + 2, y + 4 * cell), str(k + 1), fill=(200, 200, 200, 255))
for r in range(rows):
    for i, l in enumerate(["OLD", "NEW", "OLD", "NEW"]):
        d.text((2, r * band + i * cell + 4), l, fill=(255, 255, 255, 255) if i < 2 else (242, 201, 76, 255))
c.resize((c.width * 5, c.height * 5), Image.NEAREST).save(out)
