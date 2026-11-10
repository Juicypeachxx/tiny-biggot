"""THE KOI GARDEN (his reference video, 10 Nov): SpriteCook's gate and prop sheet made ready for
the game (two of the picture's pixels to one of the game's).
    python3 resprite/tools/koi_cut.py     -> tiny_biggot_godot/assets/graphics_hd/koi_*.png
The pictures as they came: resprite/spritecook/koi/ (gate.png, props.png, prompts.txt)."""
import os
import numpy as np
from PIL import Image
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
RAW = os.path.join(ROOT, "resprite", "spritecook", "koi")
OUT = os.path.join(ROOT, "tiny_biggot_godot", "assets", "graphics_hd")
ROOF_H = 78       # the gate's rows above this are its roof (drawn over the hero)
# The sheet's nine, row by row: name, the longer side it gets (in the picture's pixels).
PROPS = [("lantern", 42), ("bamboo", 46), ("shrine", 42), ("bridge", 60), ("bonsai", 44), ("torii", 46),
         ("basin", 40), ("postlamp", 46), ("stones", 34)]

def crop(im):
    return im.crop(im.getbbox())

def fit(im, side):
    """Shrunk so its longer side is `side`: averaged with the clear pixels left out, the edge kept hard."""
    w, h = im.size
    k = side / max(w, h)
    nw, nh = max(1, round(w * k)), max(1, round(h * k))
    a = np.array(im).astype(float)
    a[..., :3] *= a[..., 3:4] / 255.0
    pre = Image.fromarray(a.astype(np.uint8), "RGBA").resize((nw, nh), Image.BOX)
    b = np.array(pre).astype(float)
    al = b[..., 3:4]
    rgb = np.where(al > 0, b[..., :3] * 255.0 / np.maximum(al, 1), 0)
    out = np.dstack([np.clip(rgb, 0, 255), np.where(al >= 128, 255, 0)]).astype(np.uint8)
    return Image.fromarray(out, "RGBA")

gate = Image.open(os.path.join(RAW, "gate.png")).convert("RGBA")
gate.crop((0, 0, gate.width, ROOF_H)).save(os.path.join(OUT, "koi_gate_roof.png"))
base = gate.copy()
base.paste((0, 0, 0, 0), (0, 0, gate.width, ROOF_H))
crop(base).save(os.path.join(OUT, "koi_gate_base.png"))
print("gate", gate.size, "base", crop(base).size, "base box", base.getbbox())

sheet = Image.open(os.path.join(RAW, "props.png")).convert("RGBA")
cw, ch = sheet.width / 3.0, sheet.height / 3.0
for i, (name, side) in enumerate(PROPS):
    cell = sheet.crop((round((i % 3) * cw), round((i // 3) * ch), round((i % 3 + 1) * cw), round((i // 3 + 1) * ch)))
    p = fit(crop(cell), side)
    p.save(os.path.join(OUT, "koi_%s.png" % name))
    print(name, p.size)
