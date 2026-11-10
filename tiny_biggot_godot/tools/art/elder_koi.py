#!/usr/bin/env python3
"""THE ELDER KOI, the guardian of THE KOI GARDEN (V2; his word, 10 Nov: "can you draw koi boss on
your own"): drawn here, pixel by pixel from shapes, seen from above with its head towards the
player. Three looks, one a stage: a great white and orange koi; the same grown red and gold with
horns and long barbels; a water dragon. Run from tiny_biggot_godot/:
    python3 tools/art/elder_koi.py        -> assets/graphics_hd/elderkoi[_s2|_s3].png (double
detail) and assets/graphics/ (today's size, the game measures by it); then tools/bake_atlas.sh."""
import numpy as np
from PIL import Image

def hexc(h):
    h = h.lstrip("#")
    return np.array([int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)], float)

def blobs(w, h, seed, cells):
    r = np.random.RandomState(seed)
    g = r.rand(cells + 1, cells + 1)
    ys = np.linspace(0, cells - 0.001, h); xs = np.linspace(0, cells - 0.001, w)
    y0 = ys.astype(int); x0 = xs.astype(int)
    fy = (ys - y0)[:, None]; fx = (xs - x0)[None, :]
    fy = fy * fy * (3 - 2 * fy); fx = fx * fx * (3 - 2 * fx)
    return (g[np.ix_(y0, x0)] * (1 - fx) + g[np.ix_(y0, x0 + 1)] * fx) * (1 - fy) + (g[np.ix_(y0 + 1, x0)] * (1 - fx) + g[np.ix_(y0 + 1, x0 + 1)] * fx) * fy

def draw(W, H, P):
    yy, xx = np.mgrid[0:H, 0:W].astype(float)
    col = np.zeros((H, W, 3)); mask = np.zeros((H, W), bool)
    def put(m, c):
        col[m] = c; mask[m] = True
    # the spine, from the nose (u = 0, at the bottom) to the root of the tail (u = 1)
    us = np.linspace(0, 1, 160)
    sy = P["nose_y"] - us * P["len"]
    sx = W / 2 + P["sway"] * np.sin(us * np.pi * P["waves"] + P["phase"]) * (0.25 + 0.75 * us)
    wd = np.interp(us, P["prof_u"], P["prof_w"])
    d2 = (xx[..., None] - sx) ** 2 + (yy[..., None] - sy) ** 2
    k = np.argmin(d2 / np.maximum(wd, 0.5) ** 2, axis=2)
    dist = np.sqrt(np.take_along_axis(d2, k[..., None], 2)[..., 0]); u = us[k]; w = wd[k]
    side = xx - sx[k]
    body = dist <= w
    # tail fin: two lobes fanning up from the root
    tx, ty = sx[-1], sy[-1]
    for sgn in (-1, 1):
        a = np.arctan2(-(yy - ty), (xx - tx) * sgn)          # 90 deg = straight up
        r = np.hypot(xx - tx, yy - ty)
        lobe = (r < P["tail"] * (0.75 + 0.25 * np.cos((a - 1.1) * 3))) & (a > 0.55) & (a < 1.75) & ~body
        put(lobe, P["fin"]); put(lobe & (np.sin(a * 14) > 0.55), P["fin_d"])
    # side fins (pectoral, and the small ones further back)
    for fu, fl, fw in P["fins"]:
        i = int(fu * 159)
        for sgn in (-1, 1):
            cx, cy = sx[i] + sgn * (wd[i] + fl * 0.35), sy[i] - fl * 0.25
            ang = 0.9 * sgn
            rx = (xx - cx) * np.cos(ang) + (yy - cy) * np.sin(ang); ry = -(xx - cx) * np.sin(ang) + (yy - cy) * np.cos(ang)
            fin = ((rx / (fw * 0.5)) ** 2 + (ry / (fl * 0.5)) ** 2 <= 1) & ~body
            put(fin, P["fin"]); put(fin & (np.abs(np.sin(rx * 1.3)) > 0.8), P["fin_d"])
    # the body: base, patches, shade at the edges, a lit back
    put(body, P["base"])
    pat = blobs(W, H, P["seed"], 5)
    put(body & (pat > P["patch_at"]), P["patch"])
    if "patch2" in P:
        put(body & (blobs(W, H, P["seed"] + 7, 6) > 0.7), P["patch2"])
    if P.get("scales"):
        sc = (((u * P["len"] / 3.0).astype(int) + (np.abs(side) / 3.0 + 0.5 * ((u * P["len"] / 3.0).astype(int) % 2)).astype(int)) % 2 == 0)
        col[body & sc] *= 0.86
    edge = body & (dist > w - 2.2)
    col[edge] *= 0.72
    col[body & (dist > w - 4.0) & (side > 0) & ~edge] *= 0.88
    lit = body & (dist < w * 0.45) & (side < 0) & (side > -w * 0.4)
    col[lit] = np.minimum(255, col[lit] * 1.12 + 10)
    ridge = body & (np.abs(side) < 0.8) & (u > 0.2) & (u < 0.95)
    col[ridge] *= 0.8
    # mane (the dragon): spikes along the back
    for mu in P.get("mane", []):
        i = int(mu * 159)
        for sgn in (-1, 1):
            cx, cy = sx[i] + sgn * (wd[i] + 1.5), sy[i]
            sp = (np.abs(yy - cy) + np.abs(xx - cx) * 0.6 < 3.2) & ((xx - cx) * sgn > -1.5) & ~body
            put(sp, P["mane_c"])
    # the head: eyes, mouth, barbels, horns
    hx, hy = sx[0], sy[0]
    for sgn in (-1, 1):
        ex, ey = hx + sgn * P["eye_dx"], hy - P["eye_dy"]
        put(np.hypot(xx - ex, yy - ey) < 2.3, hexc("#1a1020")); put(np.hypot(xx - ex + 0.5, yy - ey + 0.5) < 1.0, P["eye"])
        for j in range(P["barbel"]):                        # a barbel curling out and down
            t = j / max(1, P["barbel"] - 1)
            bx = hx + sgn * (3 + t * P["barbel"] * 0.55 + 2 * np.sin(t * 3)); by = hy + 2 + t * P["barbel"] * 0.45
            put((np.abs(xx - bx) < 0.8) & (np.abs(yy - by) < 0.8), P["barbel_c"])
        if P.get("horn"):
            for j in range(P["horn"]):
                t = j / (P["horn"] - 1.0)
                bx = hx + sgn * (P["eye_dx"] - 1 + t * P["horn"] * 0.5); by = hy - P["eye_dy"] - 3 - t * P["horn"] * 0.8
                put(np.hypot(xx - bx, yy - by) < 1.6 - t, P["horn_c"])
                if P.get("antler") and j in (P["horn"] // 2, P["horn"] * 3 // 4):
                    for q in range(4):
                        put(np.hypot(xx - (bx + sgn * q), yy - (by - q * 0.6)) < 0.9, P["horn_c"])
    put((np.abs(xx - hx) < 2.0) & (np.abs(yy - (hy + P["mouth"])) < 0.8), hexc("#3a1420"))
    # the outline
    out = np.zeros_like(mask)
    out[1:, :] |= mask[:-1, :]; out[:-1, :] |= mask[1:, :]; out[:, 1:] |= mask[:, :-1]; out[:, :-1] |= mask[:, 1:]
    out &= ~mask
    im = np.zeros((H, W, 4), np.uint8)
    im[..., :3] = np.clip(col, 0, 255); im[..., 3] = mask * 255
    im[out] = (*P["line"].astype(int), 255)
    return Image.fromarray(im, "RGBA")

KOI = dict(nose_y=58, len=40, sway=3.0, waves=1.0, phase=0.0, prof_u=[0, 0.06, 0.3, 0.7, 1], prof_w=[5, 9, 11.5, 7, 2.5], tail=15,
    fins=[(0.28, 13, 8), (0.72, 8, 5)], base=hexc("#f6f0f2"), patch=hexc("#f08a2c"), patch_at=0.56, fin=hexc("#f8dcc8"), fin_d=hexc("#e8a878"),
    eye=hexc("#ffffff"), eye_dx=6.5, eye_dy=5, barbel=5, barbel_c=hexc("#f8dcc8"), mouth=-1, line=hexc("#2a1830"), seed=4)
ELDER = dict(KOI, len=44, sway=4.5, prof_w=[5.5, 10, 13, 8, 3], tail=19, fins=[(0.28, 17, 10), (0.55, 9, 6), (0.75, 10, 6)],
    base=hexc("#d8362c"), patch=hexc("#f6cf52"), patch_at=0.6, patch2=hexc("#f6f0f2"), fin=hexc("#f6cf52"), fin_d=hexc("#d08a2c"),
    eye=hexc("#6fe8f0"), barbel=11, barbel_c=hexc("#f6cf52"), horn=5, horn_c=hexc("#f6cf52"), nose_y=62, seed=9)
DRAGON = dict(ELDER, len=58, sway=9.0, waves=1.9, phase=0.4, prof_u=[0, 0.05, 0.2, 0.6, 1], prof_w=[5.5, 10, 11, 8.5, 3], tail=17,
    fins=[(0.22, 13, 7), (0.62, 11, 6)], base=hexc("#2a8fb8"), patch=hexc("#1c5f94"), patch_at=0.6, patch2=hexc("#7fe0e8"), scales=True,
    fin=hexc("#bff4f0"), fin_d=hexc("#5fc8d8"), eye=hexc("#ffe86a"), barbel=17, barbel_c=hexc("#e8fbff"), horn=9, antler=True,
    horn_c=hexc("#f6e08a"), mane=[0.12, 0.2, 0.28, 0.36, 0.44, 0.52, 0.6, 0.68, 0.76, 0.84], mane_c=hexc("#e8fbff"), nose_y=78, line=hexc("#101c38"), seed=13)

def save(name, im):
    W, H = im.size
    im.save("assets/graphics_hd/%s.png" % name)
    a = np.array(im).astype(float); a[..., :3] *= a[..., 3:4] / 255
    s = np.array(Image.fromarray(a.astype(np.uint8), "RGBA").resize((W // 2, H // 2), Image.BOX)).astype(float)
    al = s[..., 3:4]
    s = np.dstack([np.where(al > 0, s[..., :3] * 255 / np.maximum(al, 1), 0), np.where(al >= 128, 255, 0)])
    Image.fromarray(np.clip(s, 0, 255).astype(np.uint8), "RGBA").save("assets/graphics/%s.png" % name)

# Each look and its swimming: four pictures, the body's wave moving down it (<name>, <name>_f1..f3).
for name, (W, H, P) in {"elderkoi": (64, 66, KOI), "elderkoi_s2": (72, 76, ELDER), "elderkoi_s3": (80, 92, DRAGON)}.items():
    for f in range(4):
        Q = dict(P, phase=P["phase"] + f * np.pi / 2, sway=P["sway"] if f == 0 else P["sway"] * 1.15)
        save(name + ("_f%d" % f if f else ""), draw(W, H, Q))
    print(name)
