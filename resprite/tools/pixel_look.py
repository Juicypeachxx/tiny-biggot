"""The pixel look (his ask, 23 Oct: "can you make all sprites and textures little bit more
pixelated and to fit my previous style, now it feels all ai and sterile").
hd_import.py runs it on every new picture it puts into the game; resprite/hd stays as it came.
    python3 resprite/tools/pixel_look.py OUT.png NAME [NAME...]   -> a review sheet: today's
        picture, the new one as it was, the new one in the pixel look (one row each)
What made the new pictures look made by a machine: many soft shades, thin pale edges, a speck of
detail everywhere. Today's pictures (his previous style) are a few flat colours inside a thick
near-black outline. So, on a new picture (two of its pixels to one of the game's):
- few colours: 5 to 16 for a picture (more for a bigger one), found in Oklab, each the mean of
  its pixels, then a little more saturated with lighter middle tones;
- no specks: a pixel unlike all eight around it takes the colour most of them have;
- bigger pixels: where three of the four pixels of one of the game's pixels agree, the fourth
  joins them, unless it stands out (an eye, a line, a glint): most of a picture is then drawn
  in the game's own pixels, and only the fine parts keep the finer ones;
- today's outline: one of the game's pixels thick (half on the old edge, half outside it),
  near-black leaning to the picture's main hue, as today's pictures have it; very dark lines
  inside take the same colour.
Floors and the room kits: six colours and bigger pixels, no outline (a floor runs on). The traits (white shapes the game tints): three greys and bigger pixels. A picture already
at the game's pixel (the effect strips, the orbs) is left as it is."""
import colorsys, hashlib, os, sys
import numpy as np
from PIL import Image

M1 = np.array([[0.4122214708, 0.5363325363, 0.0514459929], [0.2119034982, 0.6806995451, 0.1073969566],
               [0.0883024619, 0.2817188376, 0.6299787005]])
M2 = np.array([[0.2104542553, 0.7936177850, -0.0040720468], [1.9779984951, -2.4285922050, 0.4505937099],
               [0.0259040371, 0.7827717662, -0.8086757660]])
STAND_OUT = 0.10        # Oklab distance: a pixel this far from its neighbours is a feature, not noise
EFFECTS = ("fx_", "shot_")   # glows and trails: a few flat colours would spoil them
TEXTURES = ("kit",)          # the room kits and their floors (kit3_floor)

def oklab(rgb):
    c = rgb / 255.0
    lin = np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)
    return np.cbrt(lin @ M1.T) @ M2.T

def kmeans(pts, n, seed):
    """n centres for the points, the same every time for a picture (k-means++ start)."""
    u = np.unique(pts, axis=0)
    if len(u) <= n:
        return u
    rng = np.random.default_rng(seed)
    cent = [pts[rng.integers(len(pts))]]
    d = ((pts - cent[0]) ** 2).sum(1)
    for _ in range(1, n):
        i = int(np.argmax(d)) if d.sum() == 0 else int(rng.choice(len(pts), p=d / d.sum()))
        cent.append(pts[i])
        d = np.minimum(d, ((pts - pts[i]) ** 2).sum(1))
    cent = np.array(cent)
    for _ in range(15):
        lab = ((pts[:, None, :] - cent[None]) ** 2).sum(2).argmin(1)
        for j in range(n):
            m = lab == j
            if m.any():
                cent[j] = pts[m].mean(0)
    return cent

def quantize(rgba, n, seed):
    """Every opaque pixel's index into a palette of up to n colours (-1: see-through)."""
    op = rgba[..., 3] >= 128
    rgb = rgba[..., :3].astype(np.float64)
    idx = np.full(op.shape, -1, np.int32)
    if not op.any():
        return idx, np.zeros((0, 3))
    pts = oklab(rgb[op])
    cent = kmeans(pts, n, seed)
    lab = ((pts[:, None, :] - cent[None]) ** 2).sum(2).argmin(1)
    idx[op] = lab
    pal = np.zeros((len(cent), 3))
    for j in range(len(cent)):
        m = lab == j
        if m.any():
            pal[j] = rgb[op][m].mean(0)
    return idx, pal

def colours_for(px):
    """How many colours a picture of px of the game's pixels gets (today's have 5 to 17)."""
    return int(np.clip(4 + px ** 0.5 / 2.2, 5, 16))

def punch(pal, sat=1.18, lift=0.85):
    """Today's colours: more saturated, lighter middle tones."""
    out = []
    for r, g, b in pal:
        h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
        rr, gg, bb = colorsys.hsv_to_rgb(h, min(1.0, s * sat), v ** lift)
        out.append((rr * 255, gg * 255, bb * 255))
    return np.array(out).reshape(-1, 3)

def outline_colour(pal, idx):
    """Near-black leaning to the picture's main hue (today's: 28,13,11 on a red, 11,28,14 on a green)."""
    cnt = np.bincount(idx[idx >= 0], minlength=len(pal))
    xs = ys = 0.0
    for j, (r, g, b) in enumerate(pal):
        h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
        xs += cnt[j] * s * v * np.cos(2 * np.pi * h)
        ys += cnt[j] * s * v * np.sin(2 * np.pi * h)
    h = (np.arctan2(ys, xs) / (2 * np.pi)) % 1.0
    r, g, b = colorsys.hsv_to_rgb(h, 0.62, 0.12)
    return np.array((r * 255, g * 255, b * 255))

def _around(a, fill):
    """The eight neighbours of every cell, stacked on a last axis."""
    H, W = a.shape
    p = np.pad(a, 1, constant_values=fill)
    return np.stack([p[1 + dy:1 + dy + H, 1 + dx:1 + dx + W]
                     for dy in (-1, 0, 1) for dx in (-1, 0, 1) if dy or dx], -1)

def despeckle(idx):
    """A pixel unlike all eight around it takes the colour most of them have."""
    nb = _around(idx, -2)
    out = idx.copy()
    ys, xs = np.nonzero(((nb == idx[..., None]).sum(-1) == 0) & (idx >= 0))
    for y, x in zip(ys, xs):
        v = nb[y, x]
        v = v[v >= 0]
        if len(v) >= 5:
            out[y, x] = np.bincount(v).argmax()
    return out

def snap(idx, plab):
    """Each of the game's pixels (2 x 2 here): three that agree take the fourth along, unless it
    stands out from them. See-through counts as a colour: a notch fills, and a stray pixel at the
    edge goes, but not one of a thin line (two or more pixels around it are drawn). Two and two
    of colours close to each other become the one more common around them."""
    H, W = idx.shape
    h2, w2 = H // 2 * 2, W // 2 * 2
    b = idx[:h2, :w2].reshape(h2 // 2, 2, w2 // 2, 2).transpose(0, 2, 1, 3).reshape(h2 // 2, w2 // 2, 4)
    drawn = (_around(idx >= 0, False)).sum(-1)
    out = b.copy()
    for q in range(4):
        others = np.delete(b, q, axis=2)
        agree = (others == others[..., :1]).all(-1) & (b[..., q] != others[..., 0])
        ys, xs = np.nonzero(agree)
        for y, x in zip(ys, xs):
            maj, odd = b[y, x, (q + 1) % 4], b[y, x, q]
            if maj >= 0 and odd >= 0 and np.sqrt(((plab[maj] - plab[odd]) ** 2).sum()) > STAND_OUT:
                continue
            if maj < 0 and drawn[2 * y + q // 2, 2 * x + q % 2] >= 2:
                continue
            out[y, x, q] = maj
    # two and two of colours close to each other: all four take the one more common around it
    for y, x in zip(*np.nonzero((b >= 0).all(-1))):
        u, n = np.unique(b[y, x], return_counts=True)
        if len(u) != 2 or n[0] != 2 or np.sqrt(((plab[u[0]] - plab[u[1]]) ** 2).sum()) > STAND_OUT:
            continue
        area = idx[max(0, 2 * y - 2):2 * y + 4, max(0, 2 * x - 2):2 * x + 4]
        out[y, x, :] = u[0] if (area == u[0]).sum() >= (area == u[1]).sum() else u[1]
    res = idx.copy()
    res[:h2, :w2] = out.reshape(h2 // 2, w2 // 2, 2, 2).transpose(0, 2, 1, 3).reshape(h2, w2)
    return res

def _edge(op):
    p = np.pad(op, 1, constant_values=False)
    inside = p[:-2, 1:-1] & p[2:, 1:-1] & p[1:-1, :-2] & p[1:-1, 2:]
    return op & ~inside

def _ring(op):
    p = np.pad(op, 1)
    return (p[:-2, 1:-1] | p[2:, 1:-1] | p[1:-1, :-2] | p[1:-1, 2:]) & ~op

def _seed(name):
    return int(hashlib.md5(name.encode()).hexdigest()[:8], 16)

def _paint(idx, pal):
    op = idx >= 0
    img = np.zeros(idx.shape + (4,), np.uint8)
    if len(pal):
        img[op, :3] = np.clip(pal[idx[op]], 0, 255).round()
    img[op, 3] = 255
    return img

def sprite(im, name, px):
    """A creature, an item, a prop: px is how many of the game's pixels it covers."""
    rgba = np.asarray(im.convert("RGBA"))
    idx, pal = quantize(rgba, colours_for(px) + 2, _seed(name))
    if not len(pal):
        return im
    idx = snap(despeckle(idx), oklab(pal))
    pal = punch(pal)
    oc = outline_colour(pal, idx).round()
    img = _paint(idx, pal)
    op = idx >= 0
    dark = op & (pal.max(1)[np.maximum(idx, 0)] < 0.22 * 255)
    img[dark, :3] = oc
    img[_edge(op), :3] = oc
    ring = _ring(op)
    img[ring, :3] = oc
    img[ring, 3] = 255
    return Image.fromarray(img, "RGBA")

def flat(im, name, px):
    """A floor, a room kit: six colours and bigger pixels, no outline (a floor runs on).
    (Drawn in the game's own pixels, the stones' joints came out ragged: 23 Oct.)"""
    rgba = np.asarray(im.convert("RGBA"))
    idx, pal = quantize(rgba, 6, _seed(name))
    if not len(pal):
        return im
    idx = snap(despeckle(idx), oklab(pal))
    img = _paint(idx, punch(pal, 1.1, 0.95))
    img[..., 3] = np.where(idx >= 0, rgba[..., 3], 0)
    return Image.fromarray(img, "RGBA")

def trait(im, name):
    """A trait's white shape with grey shading: white and two greys, bigger pixels."""
    rgba = np.asarray(im.convert("RGBA"))
    idx, pal = quantize(rgba, 3, _seed(name))
    if not len(pal):
        return im
    idx = snap(despeckle(idx), oklab(pal))
    pal = pal * (255.0 / max(1.0, pal.max()))       # the lightest is white, as before
    return Image.fromarray(_paint(idx, pal), "RGBA")

def look(name, im, old_size):
    """The pixel look of the new picture `im` of `name` (today's picture is old_size; None: a new
    floor). A picture with no finer pixels than the game's, or an effect, is left as it is."""
    if (old_size and im.width <= old_size[0]) or name.startswith(EFFECTS):
        return im
    if name.startswith("tr_"):
        return trait(im, name)
    px = int((np.asarray(im.convert("RGBA"))[..., 3] >= 128).sum()) // 4
    if name.startswith(TEXTURES):
        return flat(im, name, px)
    return sprite(im, name, px)

def review(out, names):
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    from inventory import G, ROOT
    hd = os.path.join(ROOT, "resprite", "hd")
    S = 5                       # screen pixels to the game's: about the iPad's
    cols = []
    for n in names:
        new = Image.open(os.path.join(hd, n + ".png")).convert("RGBA")
        op = os.path.join(G, n + ".png")
        old = Image.open(op).convert("RGBA") if os.path.exists(op) else None
        size = old.size if old else (new.width // 2, new.height // 2)
        k = new.width // size[0]
        gw, gh = size[0] * (2 if k == 4 else 1), size[1] * (2 if k == 4 else 1)
        col = [old.resize((gw * S, gh * S), Image.NEAREST) if old else Image.new("RGBA", (gw * S, gh * S)),
               new.resize((gw * S, gh * S), Image.NEAREST),
               look(n, new, old.size if old else None).resize((gw * S, gh * S), Image.NEAREST)]
        cols.append(col)
    cw = [max(c[0].width, 40) + 12 for c in cols]
    rh = [max(c[i].height for c in cols) + 12 for i in range(3)]
    sheet = Image.new("RGBA", (sum(cw) + 12, sum(rh) + 12), (60, 66, 84, 255))
    x = 12
    for c, w in zip(cols, cw):
        y = 12
        for im, h in zip(c, rh):
            sheet.alpha_composite(im, (x, y))
            y += h
        x += w
    sheet.save(out)
    print("%s: %dx%d" % (out, sheet.width, sheet.height))

if __name__ == "__main__":
    review(sys.argv[1], sys.argv[2:])
