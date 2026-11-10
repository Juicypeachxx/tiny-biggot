"""The weapons fitted the way the game holds them (22 Oct).
python3 resprite/tools/weapon_fit.py [NAME...]   (no names: every weapon with a new drawing)
- The game turns a held weapon round the middle of its picture (world_view.gd, _draw_weapon), so a
  new weapon must sit where today's does, and be as big. spritecook_fit.py stands a picture at the
  bottom middle of its whole box, which suits a foe, not a weapon: so each new drawing
  (resprite/spritecook/<name>.png, cut by sheet_add.py) is shrunk into today's drawn outline at
  double size, and centred on it.
- Today's half-see-through pixels (the glow round 14 magic staffs) stay, enlarged, under the new
  drawing."""
import json, os, sys
from PIL import Image
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from inventory import G
from spritecook_fit import HD, MANIFEST, RAW, down, trim

D = 2   # double detail

def fit(name):
    old = Image.open(os.path.join(G, name + ".png")).convert("RGBA")
    x0, y0, x1, y1 = old.getchannel("A").point(lambda v: 255 if v == 255 else 0).getbbox()
    spr = trim(Image.open(os.path.join(RAW, name + ".png")).convert("RGBA"))
    k = min((x1 - x0) * D / spr.width, (y1 - y0) * D / spr.height, 1.0)   # never enlarged: uneven pixels
    nw, nh = max(1, round(spr.width * k)), max(1, round(spr.height * k))
    out = Image.new("RGBA", (old.width * D, old.height * D), (0, 0, 0, 0))
    glow = old.copy()
    glow.putalpha(old.getchannel("A").point(lambda v: v if v < 255 else 0))
    out.alpha_composite(glow.resize(out.size, Image.NEAREST))
    x = min(max(0, round((x0 + x1) * D / 2 - nw / 2)), out.width - nw)
    y = min(max(0, round((y0 + y1) * D / 2 - nh / 2)), out.height - nh)
    out.alpha_composite(down(spr, nw, nh), (x, y))
    out.save(os.path.join(HD, name + ".png"))

def main(names):
    if not names:
        with open(MANIFEST) as f:
            names = sorted({a["name"] for a in json.load(f)["assets"] if a["kind"] == "made" and a["name"].startswith("w_")})
    for n in names:
        fit(n)
    print("fitted %d weapons the way the game holds them" % len(names))

if __name__ == "__main__":
    main(sys.argv[1:])
