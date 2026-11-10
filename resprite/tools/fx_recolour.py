"""The explosions in their other colours, and the last frames of a strip, from the new fire ones.
python3 resprite/tools/fx_recolour.py
- Today the five colours of an explosion (fire, frost, gold, venom, void) are one drawing in five
  palettes, pixel for pixel. So each new colour is the new fire drawing with each colour swapped:
  a new pixel takes the place of today's fire colour nearest it, that place's colour in the other
  palette, and keeps its own lightness against it (the new shading stays).
- The big explosion's last two frames (a few embers) were not drawn again: today's, in the new
  strip's colours.
- SpriteCook drew the bubble's first frame (a dot of three pixels) cyan, not green: today's dot."""
import os, sys
from PIL import Image
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from inventory import G
from spritecook_fit import HD, lum

def _px(im):
    return im.get_flattened_data() if hasattr(im, "get_flattened_data") else im.getdata()

def pairs(a, b):
    """Today's colour in picture a -> the same pixel's colour in picture b (one drawing in two
    palettes), for the solid pixels."""
    out = {}
    for p, q in zip(_px(a.convert("RGBA")), _px(b.convert("RGBA"))):
        if p[3] and q[3]:
            out.setdefault(p[:3], {}).setdefault(q[:3], 0)
            out[p[:3]][q[:3]] += 1
    return {k: max(v, key=v.get) for k, v in out.items()}

def _near(c, cols):
    return min(cols, key=lambda f: (f[0] - c[0]) ** 2 + (f[1] - c[1]) ** 2 + (f[2] - c[2]) ** 2)

def swap(new, m):
    """new with its colours swapped by m (today's colour -> the other palette's): each pixel takes
    the nearest of today's colours, that colour's twin, at its own lightness against it."""
    out = new.convert("RGBA").copy()
    px = out.load()
    memo = {}
    for y in range(out.height):
        for x in range(out.width):
            c = px[x, y]
            if not c[3]:
                continue
            if c[:3] not in memo:
                f = _near(c[:3], list(m))
                k = (lum(c) + 8) / (lum(f) + 8)                  # the new pixel's light against today's
                memo[c[:3]] = tuple(max(0, min(255, round(v * k))) for v in m[f])
            px[x, y] = memo[c[:3]] + (c[3],)
    return out

def recolour(size, ramp):
    m = pairs(Image.open(os.path.join(G, "fx_blast_%s_fire.png" % size)),
              Image.open(os.path.join(G, "fx_blast_%s_%s.png" % (size, ramp))))
    src = Image.open(os.path.join(HD, "fx_blast_%s_fire.png" % size))
    swap(src, m).save(os.path.join(HD, "fx_blast_%s_%s.png" % (size, ramp)))

def tail(strip, n, first):
    """Frames first.. of today's strip, in the new strip's colours (the new frames must be there)."""
    new = Image.open(os.path.join(HD, strip + ".png")).convert("RGBA")
    old = Image.open(os.path.join(G, strip + ".png")).convert("RGBA")
    w, ow = new.width // n, old.width // n
    d = w // ow
    cols = list({c[:3] for c in _px(new.crop((0, 0, first * w, new.height))) if c[3]})
    for i in range(first, n):
        f = old.crop((i * ow, 0, (i + 1) * ow, old.height)).resize((w, new.height), Image.NEAREST)
        px = f.load()
        for y in range(f.height):
            for x in range(f.width):
                c = px[x, y]
                if c[3]:
                    px[x, y] = _near(c[:3], cols) + (c[3],)
        new.paste(Image.new("RGBA", (w, new.height)), (i * w, 0))
        new.alpha_composite(f, (i * w, 0))
    new.save(os.path.join(HD, strip + ".png"))

def today_frame(strip, n, i):
    """Frame i of the new strip replaced by today's, enlarged to the new strip's density."""
    new = Image.open(os.path.join(HD, strip + ".png")).convert("RGBA")
    old = Image.open(os.path.join(G, strip + ".png")).convert("RGBA")
    w, ow = new.width // n, old.width // n
    f = old.crop((i * ow, 0, (i + 1) * ow, old.height)).resize((w, new.height), Image.NEAREST)
    new.paste(f, (i * w, 0))
    new.save(os.path.join(HD, strip + ".png"))

if __name__ == "__main__":
    tail("fx_blast_l_fire", 10, 8)
    today_frame("fx_bubble", 4, 0)
    for size in "sml":
        for ramp in ("frost", "gold", "venom", "void"):
            if os.path.exists(os.path.join(G, "fx_blast_%s_%s.png" % (size, ramp))):
                recolour(size, ramp)
                print("fx_blast_%s_%s" % (size, ramp))
