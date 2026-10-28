"""SpriteCook pictures fitted to double size for the sprites they redraw.
resprite/spritecook/<name>.png (saved as SpriteCook gave it) -> resprite/hd/<name>.png, and the
file's sha12 into resprite/spritecook-assets.json. python3 resprite/tools/spritecook_fit.py [NAME...]
Fresh download links: the SpriteCook tool get_asset_metadata(asset_id); they last an hour."""
import hashlib, json, os, re, sys
from PIL import Image
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from inventory import G, ROOT
from gemini_cut import frame

RAW = os.path.join(ROOT, "resprite", "spritecook")
HD = os.path.join(ROOT, "resprite", "hd")
MANIFEST = os.path.join(ROOT, "resprite", "spritecook-assets.json")

def sha12(path):
    with open(path, "rb") as f:
        return hashlib.sha256(f.read()).hexdigest()[:12]

def lum(c):
    return 0.299 * c[0] + 0.587 * c[1] + 0.114 * c[2]

def sat(c):
    return max(c[:3]) - min(c[:3])

def _block(src, W, H, x0, x1, y0, y1):
    """(weight, colour) of every source pixel under the box x0..x1, y0..y1."""
    px = []
    for sy in range(max(0, int(y0)), min(H, int(-(-y1 // 1)))):
        wy = min(y1, sy + 1) - max(y0, sy)
        for sx in range(max(0, int(x0)), min(W, int(-(-x1 // 1)))):
            wx = min(x1, sx + 1) - max(x0, sx)
            px.append((wx * wy, src[sx, sy]))
    return px

def _mean(px):
    tw = sum(w for w, _ in px)
    return tuple(sum(w * c[i] for w, c in px) / tw for i in range(3))

def _accent(c, ml, ms):
    return lum(c) >= ml + 45 or (sat(c) >= ms + 60 and lum(c) >= ml)

def down(spr, nw, nh):
    """Area average, except that a small bright or vivid detail (eyes, gems, spots) keeps its
    colour instead of fading into what is around it. A detail is one that stands out from the
    3 x 3 pixels around it and is rare there (so a skull's teeth are not one)."""
    src = spr.load()
    W, H = spr.size
    fx, fy = W / nw, H / nh
    out = Image.new("RGBA", (nw, nh), (0, 0, 0, 0))
    o = out.load()
    for y in range(nh):
        for x in range(nw):
            px = _block(src, W, H, x * fx, (x + 1) * fx, y * fy, (y + 1) * fy)
            vis = [p for p in px if p[1][3] >= 128]
            vw = sum(w for w, _ in vis)
            if vw < 0.47 * sum(w for w, _ in px):
                continue
            nb = [p for p in _block(src, W, H, (x - 1) * fx, (x + 2) * fx, (y - 1) * fy, (y + 2) * fy) if p[1][3] >= 128]
            around = _mean(nb)
            ml, ms = lum(around), sat(around)
            acc = [p for p in vis if _accent(p[1], ml, ms)]
            rare = sum(w for w, c in nb if _accent(c, ml, ms)) <= 0.25 * sum(w for w, _ in nb)
            col = _mean(acc) if rare and sum(w for w, _ in acc) >= 0.12 * vw else _mean(vis)
            o[x, y] = tuple(int(round(v)) for v in col) + (255,)
    return out

def fit(spr, w, h):
    k = min(w / spr.width, h / spr.height, 1.0)              # never enlarged: uneven pixels
    nw, nh = max(1, round(spr.width * k)), max(1, round(spr.height * k))
    return frame(down(spr, nw, nh), w, h, outline=False)

def _boss_scales():
    src = open(os.path.join(ROOT, "tiny_biggot_godot", "scripts", "data", "game_data.gd")).read()
    block = src[src.index("const BOSSES := {"):src.index("const FLOORS := [")]
    return {m.group(1): float(m.group(2)) for m in re.finditer(r'"sprite":\s*"([^"]+)".*?"scale":\s*([0-9.]+)', block)}

BOSS_SCALE = _boss_scales()

def density(name, old, raw=None):
    """How many new pixels per old one: 2 (double detail), or 4 for a guardian the game draws at twice
    size, when that stays within the atlas's 96 px height (ARCI does not: 2) and SpriteCook drew it big
    enough: on its longer side, after the fit, at least 9/10 of the box (a stage's wide wings in today's
    picture do not count against it). A drawing under three quarters of double size (Sefe's long
    cigarette) stays at 1, the old size."""
    base = re.sub(r"_s[23]$", "", name)
    four = BOSS_SCALE.get(base, 1.0) >= 2 and old.height * 4 <= 96
    if four and raw is not None and max(raw.width / (4 * old.width), raw.height / (4 * old.height)) < 0.9:
        four = False
    if raw is not None and max(raw.width / (2 * old.width), raw.height / (2 * old.height)) < 0.75:
        return 1
    return 4 if four else 2

def trim(im):
    box = im.getchannel("A").point(lambda v: 255 if v >= 128 else 0).getbbox()
    return im.crop(box)

def main(names):
    with open(MANIFEST) as f:
        man = json.load(f)
    done = 0
    for a in man["assets"]:
        n = a.get("name")
        if a["kind"] != "made" or (names and n not in names):
            continue
        raw = os.path.join(RAW, n + ".png")
        if not os.path.exists(raw):
            print("not downloaded yet:", n)
            continue
        a["sha12"] = sha12(raw)
        old = Image.open(os.path.join(G, n + ".png"))
        spr = trim(Image.open(raw).convert("RGBA"))
        d = density(n, old, spr)
        fit(spr, old.width * d, old.height * d).save(os.path.join(HD, n + ".png"))
        done += 1
    with open(MANIFEST, "w") as f:
        json.dump(man, f, indent=1)
        f.write("\n")
    print("fitted %d SpriteCook pictures into resprite/hd" % done)

if __name__ == "__main__":
    main(sys.argv[1:])
