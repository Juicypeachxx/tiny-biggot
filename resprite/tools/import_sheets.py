"""Reads the redrawn sheets back into the game (his test, 20 Oct). For every sheet of the plan
(resprite/sheets/plan.json) with a file of the same name in the folder (png, jpg or webp; any size,
it is scaled back to 1024 x 1024), every picture is read from its pink box: the box is found again
near where it was (Gemini moves things a little), each game pixel is the colour most of its square
has, and a square that is mostly pink is see-through. Then what the import makes again from a
redrawn picture: its elite look (richer, darker, a gold outline) and a guardian's two later phases
(the art tools' own form and evolve, the same as before: they rebuild today's phases exactly).

    python3 resprite/tools/import_sheets.py [folder] [--out DIR]

folder: the redrawn sheets (default resprite/done). --out: write there instead of the game
(tests). A picture that comes back the same as it was is left alone."""
import colorsys, json, os, sys
from collections import Counter
from PIL import Image, ImageChops, ImageStat
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from inventory import G, ROOT, R

PLAN = os.path.join(ROOT, "resprite", "sheets", "plan.json")

def pink(c):
    """The pink of the boxes (#FF00FF), and only near it: no game picture uses such a colour."""
    r, g, b = c[:3]
    return r >= 200 and b >= 200 and g <= 70 and abs(r - b) <= 60

def _mask(img):
    """Where the image is pink (255) or not (0)."""
    raw = img.convert("RGB").tobytes()
    return Image.frombytes("L", img.size, bytes(
        255 if raw[i] >= 200 and raw[i + 2] >= 200 and raw[i + 1] <= 70 and abs(raw[i] - raw[i + 2]) <= 60 else 0
        for i in range(0, len(raw), 3)))

def _shifted(m, dx, dy):
    out = Image.new("L", m.size, 0)
    out.paste(m, (dx, dy))
    return out

def _score(a, b):
    return ImageStat.Stat(ImageChops.multiply(a, b)).sum[0]

def align(img, expected):
    """How far Gemini moved the sheet (dx, dy): the shift that lays its pink boxes best over the
    plan's, first coarsely on quarter-size masks, then to the pixel."""
    got = _mask(img)
    q = (img.width // 4, img.height // 4)
    gs, es = got.resize(q, Image.BOX), expected.resize(q, Image.BOX)
    best = max(((dx, dy) for dy in range(-10, 11) for dx in range(-10, 11)),
               key=lambda d: _score(gs, _shifted(es, d[0], d[1])))
    cx, cy = best[0] * 4, best[1] * 4
    return max(((cx + dx, cy + dy) for dy in range(-4, 5) for dx in range(-4, 5)),
               key=lambda d: _score(got, _shifted(expected, d[0], d[1])))

def expected_mask(sh):
    m = Image.new("L", (sh["side"], sh["side"]), 0)
    for p in sh["pictures"]:
        x, y, w, h = p["box"]
        m.paste(255, (x, y, x + w, y + h))
    return m

def read_picture(px, box, w, h):
    bx, by, bw, bh = box
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    o = out.load()
    for j in range(h):
        for i in range(w):
            # the middle of the game pixel's square (its edges blur into the neighbours)
            sx0 = bx + (i + 0.2) * bw / w
            sx1 = bx + (i + 0.8) * bw / w
            sy0 = by + (j + 0.2) * bh / h
            sy1 = by + (j + 0.8) * bh / h
            cols = []
            npink = 0
            for yy in range(int(sy0), max(int(sy0) + 1, int(sy1))):
                for xx in range(int(sx0), max(int(sx0) + 1, int(sx1))):
                    c = px[xx, yy]
                    if pink(c):
                        npink += 1
                    else:
                        cols.append(c[:3])
            if not cols or npink >= len(cols):
                continue
            q = Counter((c[0] >> 4, c[1] >> 4, c[2] >> 4) for c in cols).most_common(1)[0][0]
            near = [c for c in cols if (c[0] >> 4, c[1] >> 4, c[2] >> 4) == q]
            o[i, j] = tuple(sum(c[k] for c in near) // len(near) for k in range(3)) + (255,)
    return out

def elite(im):
    """The elite look made from a picture: a richer, darker body and a gold outline."""
    im = im.copy()
    px = im.load()
    src = im.copy().load()
    W, H = im.size
    for y in range(H):
        for x in range(W):
            r, g, b, a = px[x, y]
            if a < 128:
                continue
            if any(not (0 <= x + dx < W and 0 <= y + dy < H) or src[x + dx, y + dy][3] < 128
                   for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                px[x, y] = (242, 201, 76, a)
                continue
            hh, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
            rr, gg, bb = colorsys.hsv_to_rgb(hh, min(1.0, s * 1.2), v * 0.82)
            px[x, y] = (int(rr * 255 + 0.5), int(gg * 255 + 0.5), int(bb * 255 + 0.5), a)
    return im

def phase(im, name, stage):
    """A guardian's or champion's later phase, made the way the art tools make it."""
    core = name[:-6] if name.endswith("_elite") else name
    vb = R.VIBES["D"]
    if core in ("rex", "rex_lie"):
        return R.cute(R.form(im, name, stage, vb), stage)
    burn = R.EVOLVE[core] if core in R.EVOLVE else R.MINIS[core][1]
    return R.evolve(R.form(im, name, stage, vb), stage, burn)

def same(a, b):
    """The same picture to the eye: the same pixels where it is not clear (clear is clear)."""
    if a.size != b.size:
        return False
    pa, pb = a.load(), b.load()
    for y in range(a.height):
        for x in range(a.width):
            ca, cb = pa[x, y], pb[x, y]
            if (ca[3] >= 128) != (cb[3] >= 128) or (ca[3] >= 128 and ca[:3] != cb[:3]):
                return False
    return True

def _untouched(img, sent, box, box0):
    """The box comes back as it was sent (a sheet put back unchanged, or a picture Gemini left)."""
    x, y, w, h = box
    x0, y0 = box0[0], box0[1]
    a = img.crop((x, y, x + w, y + h))
    b = sent.crop((x0, y0, x0 + w, y0 + h))
    return max(ImageStat.Stat(ImageChops.difference(a, b)).mean) < 3.0

def main():
    args = sys.argv[1:]
    out_dir = G
    if "--out" in args:
        k = args.index("--out")
        out_dir = args[k + 1]
        del args[k:k + 2]
    folder = args[0] if args else os.path.join(ROOT, "resprite", "done")
    plan = json.load(open(PLAN))
    files = {os.path.splitext(f)[0]: os.path.join(folder, f) for f in os.listdir(folder)
             if f.lower().endswith((".png", ".jpg", ".jpeg", ".webp"))}
    os.makedirs(out_dir, exist_ok=True)
    changed = {}
    used = []
    shifts = []
    for sh in plan["sheets"]:
        key = os.path.splitext(sh["file"])[0]
        if key not in files:
            continue
        used.append(sh["file"])
        img = Image.open(files[key]).convert("RGB")
        if img.size != (sh["side"], sh["side"]):
            img = img.resize((sh["side"], sh["side"]), Image.LANCZOS)
        dx, dy = align(img, expected_mask(sh))
        sent = Image.open(os.path.join(os.path.dirname(PLAN), sh["file"])).convert("RGB")
        px = img.load()
        for p in sh["pictures"]:
            x, y, w, h = p["box"]
            box = [x + dx, y + dy, w, h]
            if _untouched(img, sent, box, p["box"]):
                continue   # (left as it was sent: the picture stays as it is, half-clear pixels too)
            new = read_picture(px, box, p["w"], p["h"])
            old = Image.open(os.path.join(G, p["name"] + ".png")).convert("RGBA")
            if same(new, old):
                continue
            changed[p["name"]] = new
        shifts.append("%s %+d,%+d" % (sh["file"][:2], dx, dy))
    for name, im in changed.items():
        im.save(os.path.join(out_dir, name + ".png"))
    made = []
    for n in plan["made_again"]:   # elites first: a champion's elite phases come from its new elite
        if n.endswith("_elite") and n[:-6] in changed:
            changed[n] = elite(changed[n[:-6]])
            changed[n].save(os.path.join(out_dir, n + ".png"))
            made.append(n)
    for n in plan["made_again"]:
        if n[-3:] in ("_s2", "_s3") and n[:-3] in changed:
            im = phase(changed[n[:-3]], n[:-3], int(n[-1]))
            im.save(os.path.join(out_dir, n + ".png"))
            made.append(n)
    print("sheets read: %d (%s)" % (len(used), ", ".join(used) if used else "none"))
    print("moved by Gemini (x,y px): " + ", ".join(shifts))
    print("pictures redrawn: %d; made again from them: %d; written to %s" % (
        len(changed) - len(made), len(made), out_dir))

if __name__ == "__main__":
    main()
