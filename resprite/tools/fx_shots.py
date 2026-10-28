"""Your shots in his bright look: SpriteCook drew one weapon family of each shot (pyre, the orange
one: resprite/spritecook/fx/base/shot_<kind>_2.png, from fx_fit.py); today every family is the same
drawing in its own five colours, so the other sixteen are that drawing with the colours swapped
(fx_recolour.swap), laid out as today's sheets: the families eight to a row, each its frames.
python3 resprite/tools/fx_shots.py   -> resprite/hd/shot_<kind>.png"""
import os, sys
from PIL import Image
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from inventory import G
from spritecook_fit import HD
from fx_recolour import pairs, swap
import fx_ref

BASE = os.path.join(os.path.dirname(HD), "spritecook", "fx", "base")
SHEETS = {"shot_bolt": 2, "shot_pellet": 2, "shot_hex": 4, "shot_hexBig": 4, "shot_spark": 4, "shot_fire": 4,
          "shot_flask": 1, "shot_pulse": 4, "shot_rail": 2, "shot_whirl": 2}     # ShotBatch.SHEETS
FAMILIES, FROM = 17, 2                 # ShotBatch.TAGS; the one SpriteCook drew (pyre)

def strip(frames):
    w, h = frames[0].size
    out = Image.new("RGBA", (w * len(frames), h))
    for i, f in enumerate(frames):
        out.paste(f, (i * w, 0))
    return out

def sheet(kind, n):
    base = Image.open(os.path.join(BASE, "%s_%d.png" % (kind, FROM))).convert("RGBA")
    today = Image.open(os.path.join(G, kind + ".png"))
    cw, ch = today.width // (fx_ref.PER_ROW * n), today.height // 3
    d = base.height // ch
    out = Image.new("RGBA", (today.width * d, today.height * d))
    src = strip(fx_ref.frames(kind, n, FROM))
    for t in range(FAMILIES):
        new = base if t == FROM else swap(base, pairs(src, strip(fx_ref.frames(kind, n, t))))
        r, c = divmod(t, fx_ref.PER_ROW)
        out.paste(new, (c * n * cw * d, r * ch * d))
    out.save(os.path.join(HD, kind + ".png"))
    return d

if __name__ == "__main__":
    for kind, n in SHEETS.items():
        if os.path.exists(os.path.join(BASE, "%s_%d.png" % (kind, FROM))):
            print(kind, "density", sheet(kind, n))
