"""The foes' shots with their dark rim (35.3 clarity), made again round the new pictures, as
tools/art/shot_rims.py makes them round today's: one game pixel of the game's outline colour, part
see-through, outside each frame's own outline (at double detail, two pixels).
python3 resprite/tools/fx_rims.py   -> resprite/hd/ebr_<kind>.png, resprite/hd/orbr_<kind>.png"""
import os, sys
from PIL import Image, ImageChops
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from inventory import G
from spritecook_fit import HD

KINDS = ["red", "redBig", "bone", "water", "ice", "iceBig", "spore", "dark", "darkBig", "fire", "fireBig", "cyan", "page"]
RIM = (20, 15, 28, 150)   # the outline colour of the game (#140f1c), part see-through

def _grow(mask):
    """One pixel more round the solid part, to the four sides (as shot_rims.py does)."""
    out = mask.copy()
    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        out = ImageChops.lighter(out, ImageChops.offset(mask, dx, dy))
    return out

def rimmed(im, d):
    w, h = im.size
    out = Image.new("RGBA", (w + 2 * d, h + 2 * d), (0, 0, 0, 0))
    out.paste(im, (d, d))
    solid = out.getchannel("A").point(lambda a: 255 if a >= 128 else 0)
    ring = solid
    for _ in range(d):
        ring = _grow(ring)
    rim = Image.new("RGBA", out.size, RIM)
    rim.putalpha(ImageChops.multiply(ImageChops.subtract(ring, solid), Image.new("L", out.size, RIM[3])))
    rim.alpha_composite(out)
    return rim

def strip(name, frames):
    new = Image.open(os.path.join(HD, name + ".png")).convert("RGBA")
    d = new.height // Image.open(os.path.join(G, name + ".png")).height
    fw = new.width // frames
    out = Image.new("RGBA", ((fw + 2 * d) * frames, new.height + 2 * d), (0, 0, 0, 0))
    for f in range(frames):
        out.paste(rimmed(new.crop((f * fw, 0, (f + 1) * fw, new.height)), d), (f * (fw + 2 * d), 0))
    return out

if __name__ == "__main__":
    for k in KINDS:
        strip("eb_" + k, 4).save(os.path.join(HD, "ebr_" + k + ".png"))
        strip("orb_" + k, 1).save(os.path.join(HD, "orbr_" + k + ".png"))
    print("rims made round the new shots: %d kinds" % len(KINDS))
