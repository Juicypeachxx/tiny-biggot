"""The traits fitted, in white and greys (22 Oct).
python3 resprite/tools/trait_fit.py [NAME...]   (no names: every trait with a new drawing)
- The game paints a trait picture in its family's colour (trait_view.gd, cube), so each new drawing
  (resprite/spritecook/<name>.png, cut by sheet_add.py) becomes greys by its lightness, its lightest
  pixel white: the family colour shows as strongly as on today's flat white shape, and the shading
  shows as darker shades of it.
- Then fitted like the weapons (weapon_fit.py): inside today's drawn outline at double size,
  centred on it."""
import json, os, sys
from PIL import Image
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from inventory import G
from spritecook_fit import HD, MANIFEST, RAW, down, lum, trim
from weapon_fit import D

def grey(im):
    """Greys by lightness, the lightest one white, the see-through kept."""
    px = im.load()
    top = max((lum(px[x, y]) for y in range(im.height) for x in range(im.width) if px[x, y][3] >= 128), default=255)
    k = 255.0 / max(1.0, top)
    for y in range(im.height):
        for x in range(im.width):
            c = px[x, y]
            v = min(255, round(lum(c) * k))
            px[x, y] = (v, v, v, c[3])
    return im

def fit(name):
    old = Image.open(os.path.join(G, name + ".png")).convert("RGBA")
    x0, y0, x1, y1 = old.getchannel("A").point(lambda v: 255 if v >= 128 else 0).getbbox()
    spr = trim(Image.open(os.path.join(RAW, name + ".png")).convert("RGBA"))
    k = min((x1 - x0) * D / spr.width, (y1 - y0) * D / spr.height, 1.0)   # never enlarged: uneven pixels
    nw, nh = max(1, round(spr.width * k)), max(1, round(spr.height * k))
    out = Image.new("RGBA", (old.width * D, old.height * D), (0, 0, 0, 0))
    x = min(max(0, round((x0 + x1) * D / 2 - nw / 2)), out.width - nw)
    y = min(max(0, round((y0 + y1) * D / 2 - nh / 2)), out.height - nh)
    out.alpha_composite(grey(down(spr, nw, nh)), (x, y))
    out.save(os.path.join(HD, name + ".png"))

def main(names):
    if not names:
        with open(MANIFEST) as f:
            names = sorted({a["name"] for a in json.load(f)["assets"] if a["kind"] == "made" and a["name"].startswith("tr_")})
    for n in names:
        fit(n)
    print("fitted %d traits in white and greys" % len(names))

if __name__ == "__main__":
    main(sys.argv[1:])
