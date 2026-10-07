import colorsys, random, sys, os
from PIL import Image
exec(open(os.path.join(os.path.dirname(__file__) or '.', 'sprites.py')).read())

def hx(h): h=h.lstrip('#'); return tuple(int(h[i:i+2],16)/255 for i in (0,2,4))
def toh(c): return tuple(max(0,min(255,round(v*255))) for v in c)
def hsv(c): return colorsys.rgb_to_hsv(*c)
def rgb(h,s,v): return colorsys.hsv_to_rgb(h%1, max(0,min(1,s)), max(0,min(1,v)))

BONE="#d9cfb0"; SKIN="#e0a47a"; METAL="#9aa3b5"; GOLD="#e8b84a"; WOOD="#8a5a32"

# Each vibe: how a base color becomes three tones (hue shift, saturation, value), the outline,
# rim light (B) and glow halo (C).
VIBES = {
 "A": dict(name="CRISP", tones=[(-0.04,1.15,0.58),(0,1.0,1.0),(0.04,0.75,1.25)], sat=1.1, val=1.05,
           outline=(0.09,0.06,0.13), colored_outline=False, rim=None, halo=0),
 "B": dict(name="GRIM", tones=[(0.07,1.0,0.4),(0.02,0.85,0.76),(-0.02,0.55,1.08)], sat=0.82, val=0.9,
           outline=(0.03,0.03,0.06), colored_outline=False, rim=(0.62,0.92,1.0), halo=90),
 "D": dict(name="CRISP+GLOW", tones=[(0.07,1.2,0.54),(0,1.1,1.0),(-0.05,0.7,1.3)], sat=1.18, val=1.04,
           outline=(0.09,0.06,0.13), colored_outline=True, outline_v=0.11, rim=None, halo=160, halo2=60),
 "C": dict(name="GLOW", tones=[(0.1,1.25,0.48),(0,1.2,1.02),(-0.07,0.65,1.35)], sat=1.3, val=1.0,
           outline=(0.14,0.06,0.2), colored_outline=True, rim=(1.0,0.86,0.5), halo=170, halo2=70),
}

def tones(base, vb):
    h,s,v = hsv(hx(base))
    s*=vb["sat"]; v*=vb["val"]
    warm = h < 0.2 or h > 0.92   # gold, skin, wood, red: highlights lean to yellow, never to pink
    return [toh(rgb(h + (abs(dh) if warm and i == 2 else dh), s*ds, v*dv)) for i,(dh,ds,dv) in enumerate(vb["tones"])]

def sprite(name, vb, rng=None, elite=False):
    meta, grid = S[name]
    m = dict(kv.split(':') for kv in meta.split())
    if elite:   # richer, darker body, hot gold eyes, its own mark (ELITE), gold outline
        h,s_,v = hsv(hx(m.get("main","#888888")))
        m["main"] = "#%02x%02x%02x" % toh(rgb(h, min(1, s_*1.2), v*0.82))
        if not m.get("halo"):   # a glowing body keeps its own light
            m["glow"] = "#ffd84a"
        grid = list(grid)
        for row, over in ELITE.get(name, {}).items():
            grid[row] = "".join(c if c != '.' else g for g, c in zip(grid[row], over))
    mats = {"123": m.get("main","#888888"), "abc": m.get("second","#3f7fbf"), "jkl": m.get("bone", BONE), "456": m.get("skin", SKIN),
            "789": m.get("metal", METAL), "pqr": m.get("gold", GOLD), "uvw": m.get("wood", WOOD)}
    pal = {}
    for keys, base in mats.items():
        t = tones(base, vb)
        for i,k in enumerate(keys): pal[k] = t[i]+(255,)
    g = hx(m.get("glow","#ffffff"))
    pal["x"] = toh(rgb(*(lambda h,s,v:(h,s*0.5,1.0))(*hsv(g))))+(255,)
    pal["y"] = toh(g)+(255,)
    mh = hsv(hx(m.get("main","#888888")))
    pal["0"] = toh(rgb(mh[0]+0.05, 0.5, 0.12)) + (255,)
    oc = vb["outline"]
    if vb["colored_outline"]:
        oc = rgb(mh[0]+0.04, 0.6, vb.get("outline_v", 0.16))
    pal["o"] = toh(oc)+(255,)
    W,H = len(grid[0]), len(grid)
    im = Image.new("RGBA",(W,H),(0,0,0,0)); px = im.load()
    for y,row in enumerate(grid):
        for x,ch in enumerate(row):
            if ch != '.': px[x,y] = pal[ch]
    if elite:
        for y,row in enumerate(grid):
            for x,ch in enumerate(row):
                if ch == 'o': px[x,y] = (242,201,76,255)
    if vb["rim"]:   # cold rim light on the right/top edge of every shape (Dead Cells-like)
        rc = toh(vb["rim"])
        orig = im.copy().load()
        for y,row in enumerate(grid):
            for x,ch in enumerate(row):
                if ch in "123abcjkl456789pqruvw":
                    nx = row[x+1] if x+1 < W else '.'
                    up = grid[y-1][x] if y > 0 else '.'
                    if (nx == 'o' and up == 'o') or ((nx == 'o' or up == 'o') and ch in "3l69rwc"):
                        c = orig[x,y]
                        px[x,y] = tuple(int(c[i]*0.35+rc[i]*0.65) for i in range(3))+(255,)
    if vb["halo"] and m.get("halo"):  # soft glow around glowing pixels, into clear pixels only
        gc = pal["y"][:3]
        src = [(x,y) for y,row in enumerate(grid) for x,ch in enumerate(row) if ch in "xy"]
        for (x,y) in src:
            for dx in (-1,0,1):
                for dy in (-1,0,1):
                    X,Y = x+dx,y+dy
                    if 0<=X<W and 0<=Y<H and grid[Y][X]=='.' and px[X,Y][3]==0:
                        px[X,Y] = gc+(vb["halo"],)
        if vb.get("halo2"):
            for (x,y) in src:
                for dx in (-2,-1,0,1,2):
                    for dy in (-2,-1,0,1,2):
                        X,Y = x+dx,y+dy
                        if 0<=X<W and 0<=Y<H and px[X,Y][3]==0:
                            px[X,Y] = gc+(vb["halo2"],)
    return im

def kit(vb, seed=7, cols=None):
    """256x64: row 0 sixteen 16px floor tiles (pairs for the checker), row 1 walls (top, face,
    bottom, left, right, void), rows 2-3 the pillar (17x32)."""
    rnd = random.Random(seed)
    T = 16
    im = Image.new("RGBA",(256,64),(0,0,0,0)); px = im.load()
    cols = cols or {}
    fl = tones(cols.get("floor", "#4a4060"), vb); fl2 = tones(cols.get("floor2", "#443a58"), vb)
    bone = tones(BONE, vb); moss = tones("#5a7a3a", vb)
    dark = toh(vb["outline"])+(255,)
    def put(x,y,c):
        if 0<=x<256 and 0<=y<64: px[x,y]=c if len(c)==4 else c+(255,)
    for v in range(16):
        base = fl if v%2==0 else fl2
        ox = v*T
        # two slabs per tile, staggered, each with its own light edge and grout
        for y in range(T):
            for x in range(T):
                put(ox+x,y,base[1])
        g = tuple((a+b)//2 for a,b in zip(base[0],base[1]))
        hl = tuple((a*1+b*2)//3 for a,b in zip(base[2],base[1]))
        for y in range(T):
            put(ox+T-1,y,g)
        for x in range(T):
            put(ox+x,T-1,g)
        for x in range(1,T-2):
            put(ox+x,0,hl)
        for y in range(1,T-2):
            put(ox,y,hl)
        if v//2 in (1,5):   # a worn, darker patch
            for k in range(6):
                put(ox+rnd.randint(3,11), rnd.randint(3,11), g)
        for k in range(rnd.randint(1,3)):   # speckles
            put(ox+rnd.randint(1,13), rnd.randint(1,14), base[0] if rnd.random()<0.6 else base[2])
        kind = v//2
        if kind == 2:   # crack
            x,y = ox+rnd.randint(3,10), rnd.randint(2,6)
            for i in range(6):
                put(x,y,dark); y+=1; x+= rnd.choice((-1,0,1))
        if kind == 4 and v%2==0:   # a small bone (half as often)
            for i in range(4): put(ox+5+i,11,bone[1])
            put(ox+4,10,bone[2]); put(ox+4,12,bone[1]); put(ox+9,10,bone[2]); put(ox+9,12,bone[1])
        if kind == 6:   # moss in the grout
            for i in range(5): put(ox+rnd.randint(0,15),7,moss[rnd.randint(0,2)])
            for i in range(4): put(ox+rnd.randint(0,15),15,moss[rnd.randint(1,2)])
        if kind == 7:   # pebbles
            for k in range(3):
                x,y = ox+rnd.randint(2,12), rnd.randint(2,12)
                put(x,y,base[2]); put(x+1,y,base[1]); put(x,y+1,base[0]); put(x+1,y+1,base[0])
    wall = tones(cols.get("wall", "#3a3050"), vb); cap = tones(cols.get("cap", "#6a5f85"), vb); void = toh(rgb(*hsv(hx("#140f1c")))) if False else (20,15,28,255)
    def bricks(ox, oy, w, h, t):
        for y in range(h):
            for x in range(w):
                row = y//4
                edge = (y%4==3) or ((x + (4 if row%2 else 0))%8==7)
                put(ox+x,oy+y, t[0] if edge else (t[2] if y%4==0 else t[1]))
    # 0 top wall (the cap seen from above)
    for y in range(T):
        for x in range(T):
            put(x,16+y, cap[2] if y<2 else (cap[1] if y<13 else cap[0]))
    for x in range(T): put(x,16+15,dark)
    bricks(16,16,T,T,wall)                       # 1 wall face
    for y in range(T):                           # 2 bottom wall: cap with a lip
        for x in range(T):
            put(32+x,16+y, cap[0] if y<2 else (cap[1] if y<12 else cap[2]))
    for y in range(T):                           # 3 left wall, 4 right wall
        for x in range(T):
            put(48+x,16+y, cap[1] if x<13 else (cap[0] if x<15 else dark))
            put(64+x,16+y, cap[1] if x>2 else (cap[0] if x>0 else dark))
        put(48+1,16+y,cap[2]); put(64+3,16+y,cap[2])
    for y in range(T):
        for x in range(T): put(80+x,16+y,void)
    # pillar 17x32: cap on top, bricks below, shadow at the foot
    for y in range(32):
        for x in range(17):
            if y < 12:
                put(x,32+y, cap[2] if y<2 else (cap[1] if y<10 else cap[0]))
            elif y < 28:
                put(x,32+y, wall[0] if x in (0,16) else None or wall[1])
            elif y < 30:
                put(x,32+y, dark)
            else:
                put(x,32+y,(0,0,0,90))
    bricks(1,44,15,16,wall)
    for x in range(17): put(x,32,dark)
    for y in range(28): put(0,32+y,dark); put(16,32+y,dark)
    return im


def remaster(path, vb, elite=False, gentle=False, shade=False):
    """An old graphic kept pixel for pixel, recoloured into the look: the outline tinted by the
    sprite's main colour, colours a little richer, shadows cooler-red, lights toward yellow."""
    im = Image.open(path).convert("RGBA"); px = im.load()
    src0 = im.copy().load()
    from collections import Counter
    cnt = Counter(px[x, y][:3] for y in range(im.height) for x in range(im.width)
                  if px[x, y][3] > 128 and sum(px[x, y][:3]) > 120)
    mh = hsv(tuple(c / 255 for c in cnt.most_common(1)[0][0]))[0] if cnt else 0.08
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if a < 128:
                continue
            h, s, v = hsv((r / 255, g / 255, b / 255))
            if v < 0.16:
                edge = any(not (0 <= x + dx < im.width and 0 <= y + dy < im.height) or src0[x + dx, y + dy][3] < 128
                           for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
                px[x, y] = (242, 201, 76, a) if elite and edge else toh(rgb(mh + 0.04, 0.6, 0.11)) + (a,)
                continue
            if v > 0.7:
                h += 0.005 if (h < 0.2 or h > 0.92) else 0
            elif v < 0.5:
                h += 0.01
            if gentle:
                s, v = s * 1.05, v
            else:
                s, v = s * vb["sat"], v * vb["val"]
            if elite:   # darker, richer, like every elite
                s, v = min(1, s * 1.2), v * 0.82
            px[x, y] = toh(rgb(h, s, v)) + (a,)
    if shade:
        _shade(im, src0)
    return im

def _shade(im, src0):
    """The look's volume on an old icon: light on the edges facing the top-left, shadow on the ones
    facing the bottom-right, and every outline pixel tinted by the colour it borders."""
    W, H = im.width, im.height; px = im.load(); base = im.copy().load()
    def solid(x, y):
        return 0 <= x < W and 0 <= y < H and src0[x, y][3] >= 128
    def dark(x, y):
        return solid(x, y) and hsv(tuple(c / 255 for c in src0[x, y][:3]))[2] < 0.16
    for y in range(H):
        for x in range(W):
            if not solid(x, y):
                continue
            h, s, v = hsv(tuple(c / 255 for c in base[x, y][:3]))
            if dark(x, y):
                near = [base[x + dx, y + dy] for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))
                        if solid(x + dx, y + dy) and not dark(x + dx, y + dy)]
                if near:
                    nh, ns, nv = hsv(tuple(c / 255 for c in near[0][:3]))
                    px[x, y] = toh(rgb(nh + 0.03, min(1, ns * 0.9 + 0.2), 0.13)) + (255,)
                continue
            warm = h < 0.2 or h > 0.92
            if dark(x - 1, y) or dark(x, y - 1) or not solid(x - 1, y) or not solid(x, y - 1):
                px[x, y] = toh(rgb(h + (0.03 if warm else -0.03), s * 0.85, min(1, v * 1.22 + 0.04))) + (255,)
            elif dark(x + 1, y) or dark(x, y + 1) or not solid(x + 1, y) or not solid(x, y + 1):
                px[x, y] = toh(rgb(h + 0.05, min(1, s * 1.1), v * 0.72)) + (255,)

def kit_remaster(path, vb):
    """A floor's tile sheet (kit layout, see kit()) kept as drawn, recoloured into the look; every
    floor tile (row 0) gets kit0's soft bevel: light on its top and left edge, grout below and right."""
    im = Image.open(path).convert("RGBA"); px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r_, g, b, a = px[x, y]
            if a == 0:
                continue
            h, s, v = hsv((r_ / 255, g / 255, b / 255))
            if v > 0.6:
                h += 0.01 if (h < 0.2 or h > 0.92) else -0.01
            elif v < 0.35:
                h += 0.02
            px[x, y] = toh(rgb(h, min(1, s * vb["sat"]), v * vb["val"])) + (a,)
    base = im.copy().load()
    def mix(c, k, to):
        return tuple(int(c[i] * (1 - k) + to[i] * k) for i in range(3)) + (c[3],)
    for t in range(16):
        ox = t * 16
        for i in range(16):
            for (x, y, k, to) in ((ox + i, 0, 0.22, (255, 240, 220)), (ox, i, 0.18, (255, 240, 220)),
                                  (ox + i, 15, 0.25, (10, 6, 20)), (ox + 15, i, 0.2, (10, 6, 20))):
                if base[x, y][3]:
                    px[x, y] = mix(base[x, y], k, to)
    return im

def all_for(v):
    vb = VIBES[v]
    out = {n: sprite(n, vb) for n in S}
    for n in [k for k in out if k.endswith("_new") or k.endswith("_old")]:
        out.pop(n)   # drawings kept only to make an elite from (ELITE_SRC)
    for n in ELITE:
        if not (n.endswith("_new") or n.endswith("_old")):
            out[n + "_elite"] = sprite(n, vb, elite=True)
    for n, src in ELITE_SRC.items():
        out[n + "_elite"] = sprite(src, vb, elite=True)
    src = os.path.join(os.path.dirname(os.path.abspath(__file__)), "src")
    for n in REMASTER:
        out[n] = remaster(os.path.join(src, n + ".png"), vb, gentle=n in GENTLE)
    for n in REMASTER_ELITE:
        out[n + "_elite"] = remaster(os.path.join(src, n + ".png"), vb, elite=True)
    # 5.4: every weapon, gear, relic and pet icon, kept as drawn and recoloured into the look
    # (the ones he wants redrawn get a grid in sprites.py, which wins).
    # 5.5: room objects, shop people, summons, Rex's barn props: as the icons.
    for f in sorted(os.listdir(os.path.join(src, "rooms"))):
        n = f[:-4]
        if n not in S:
            out[n] = remaster(os.path.join(src, "rooms", f), vb, shade=True)
    # 5.6: HUD, pickups, map, family, combo icons, frames and cards (the logos stay as they are).
    for f in sorted(os.listdir(os.path.join(src, "hud"))):
        if f[:-4] not in S:
            out[f[:-4]] = remaster(os.path.join(src, "hud", f), vb, shade=True)
    # 5.5: every floor's tiles but kit0 (drawn new): recoloured, each floor tile bevelled like kit0.
    for n in ("rex", "rex_lie"):   # 6.2: Rex's cute evolutions
        if n in out:
            out[n + "_s2"] = cute(form(out[n], n, 2, vb), 2)
            out[n + "_s3"] = cute(form(out[n], n, 3, vb), 3)
    for n, (kind, burn) in MINIS.items():   # 6.1: minis and champions, and their elites
        for k in (n, n + "_elite"):
            if k in out:
                out[k + "_s2"] = evolve(form(out[k], k, 2, vb), 2, burn)
                out[k + "_s3"] = evolve(form(out[k], k, 3, vb), 3, burn)
    for n, burn in EVOLVE.items():   # the guardians' evolved stages (his ask, 6 Oct)
        if n in out:
            out[n + "_s2"] = evolve(form(out[n], n, 2, vb), 2, burn)
            out[n + "_s3"] = evolve(form(out[n], n, 3, vb), 3, burn)
    for f in sorted(os.listdir(os.path.join(src, "kits"))):
        out[f[:-4]] = kit_remaster(os.path.join(src, "kits", f), vb)
    for f in sorted(os.listdir(os.path.join(src, "icons"))):
        n = f[:-4]
        if n not in S:
            out[n] = remaster(os.path.join(src, "icons", f), vb, shade=True)
    out.pop("hexer_old", None)
    out["kit0"] = kit(vb)
    out["kit_spire"] = kit(vb, 11, { "floor": "#5a4630", "floor2": "#54412c", "wall": "#3a2c22", "cap": "#8a6a3a" })   # 6.4
    out["kit_rimefrost"] = kit(vb, 13, { "floor": "#3a5068", "floor2": "#36495f", "wall": "#24324a", "cap": "#7aa8c8" })   # 7.3
    out["kit11"] = kit(vb, 21, { "floor": "#1e2238", "floor2": "#1b1f33", "wall": "#141628", "cap": "#4d6aa8" })   # 12.2 the Inkwell
    out["kit12"] = kit(vb, 22, { "floor": "#6a5a44", "floor2": "#64553f", "wall": "#3a2c22", "cap": "#c8a878" })   # the Bindery
    out["kit13"] = kit(vb, 23, { "floor": "#3a3448", "floor2": "#363043", "wall": "#241f30", "cap": "#f2c94c" })   # the Quill Spire
    return out

# ---- His ask (6 Oct): a guardian evolves with its stages, more menacing each time. Made from its
# finished sprite, so every guardian keeps its own look: <name>_s2 and <name>_s3, a little bigger
# (spikes and an aura need room), drawn bottom-centred like the original.
EVOLVE = {   # guardian -> the colour it burns with when it evolves
	"colossus": "#ff3b30", "sporemother": "#b8ff3a", "librarian": "#3ad8ff", "tyrant": "#ff8a1a",
	"rimewarden": "#8ae8ff", "regent": "#c05aff", "bogmatriarch": "#9aff3a", "ashwarlord": "#ff5a1a",
	"frozenabbot": "#bff4ff", "crowking": "#ff2a2a", "umbralsun": "#e08aff", "holycow": "#ffd84a",
	"judge": "#fff07a", "cinderking": "#ff6a1a", "unwritten": "#e0e0ff", "stormcrown": "#7ff0ff",
	"bilgehydra": "#5affa0", "brassorgan": "#ff4a3a", "greatengine": "#ff8a1a", "glacialmaw": "#5ad8ff",
	"admiral": "#5ad8ff", "inkleviathan": "#9ab8ff", "thebinder": "#ff4a3a", "author": "#fff07a", "golemking": "#ffb040", "archmage": "#7ff0ff", "phoenix": "#fff07a", "wyrm": "#7ff0ff", "chainfiend": "#ff3020", "seraph": "#fff07a",
}

def evolve(im, stage, burn):
    import random as _r
    rnd = _r.Random(stage * 7919 + im.width * 31 + im.height)
    pad = stage - 1                       # 1 px each side at stage 2, 2 at stage 3; and on top
    W, H = im.width + 2 * pad, im.height + pad
    out = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    out.alpha_composite(im, (pad, pad))
    px = out.load(); base = out.copy().load()
    bc = hx(burn); bh, bs, bv = hsv(bc)
    hot = toh(rgb(bh, bs * (0.5 if stage == 3 else 0.9), 1.0))
    core = (255, 250, 230) if stage == 3 else hot
    def solid(x, y): return 0 <= x < W and 0 <= y < H and base[x, y][3] >= 128
    def dark(c): return hsv(tuple(v / 255 for v in c[:3]))[2] < 0.17
    # the body: angrier, then corrupted; bright glowing pixels (eyes, gems) burn hotter
    for y in range(H):
        for x in range(W):
            c = base[x, y]
            if c[3] < 128 or dark(c):
                continue
            h, s, v = hsv(tuple(k / 255 for k in c[:3]))
            if v > 0.86 and s > 0.45:
                px[x, y] = core + (255,)
                continue
            k = 0.32 if stage == 2 else 0.38
            nh = h + (((bh - h + 0.5) % 1.0) - 0.5) * k
            px[x, y] = toh(rgb(nh, min(1, s * (1.15 if stage == 2 else 1.3)), v * (0.8 if stage == 2 else 0.62))) + (255,)
    # cracks of light through the body
    body = [(x, y) for y in range(H) for x in range(W) if solid(x, y) and not dark(base[x, y])
            and all(solid(x + dx, y + dy) for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))]
    for n in range(3 if stage == 2 else 4 + W // 12):
        if not body:
            break
        x, y = rnd.choice(body)
        for i in range(3 + stage * 2 + W // 10):
            if not solid(x, y) or dark(base[x, y]):
                break
            px[x, y] = (hot if i % 3 else core) + (255,)
            x += rnd.choice((-1, 0, 1)); y += rnd.choice((0, 1, 1))
    # spikes along the top of the silhouette
    tops = {}
    for x in range(W):
        for y in range(H):
            if solid(x, y):
                tops[x] = y
                break
    oc = None
    for x in sorted(tops):
        if x % 3 == 1 and tops[x] - stage >= 0:
            for i in range(1, stage + 1):
                yy = tops[x] - i
                if yy >= 0:
                    px[x, yy] = (hot + (255,)) if (stage == 3 and i == stage) else base[x, tops[x]]
    # stage 3: an aura of its burning colour
    if stage == 3:
        cur = out.copy().load()
        for y in range(H):
            for x in range(W):
                if cur[x, y][3] >= 128:
                    continue
                near = any(0 <= x + dx < W and 0 <= y + dy < H and cur[x + dx, y + dy][3] >= 128
                           for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
                if near:
                    px[x, y] = toh(bc) + (120,)
    return out

# ---- His ask (6 Oct): an evolution you can see in the shape, not only the colour. Hand-drawn parts
# (left-hand versions; the right-hand ones are mirrored) put on each guardian, its own mix per stage,
# before evolve() burns it.
PART = {
	"horn_s": ["o..", "lo.", "lo.", "llo"],
	"horn_b": ["o.....", "lo....", ".lo...", ".llo..", "..llo.", "..lllo"],
	"horn_d": ["o....", "1o...", "11o..", ".11o.", "..11o"],
	"wing": ["o......", "2o.....", "22o....", "222oo..", "2222o..", "22222oo", "2o2o22o", "o.o.o.o"],
	"wingf": ["o.....", "lo....", "llo...", "lllo..", "kllloo", "kkllko", "okkoko", ".o.o.o"],
	"eye3": [".oo.", "oyyo", "oxxo", ".oo."],
	"eyes": ["oyo.oyo", ".o.oyo.", "...o..."],
	"maw": ["ooooooooo", "ol0l0l0lo", "o0yyyyy0o", "o0k0k0k0o", "ooooooooo"],
	"flames": ["y..y..y..y", "yx.yx.yx.y", "oyyoyyoyyo"],
	"spike": ["o..", "9o.", "99o"],
	"tent": ["o.o.o.o.o.", "2o2o2o2o2o", "o2o.o2o.o2", ".o...o...o"],
	"halo": ["q.qq.q", "..q..q"],
}
# guardian -> {stage: [(part, x, y, mirrored pair: right edge x or None, behind)]}, x and y from the
# sprite's top-left; a pair's right copy is placed so it ends at that column.
FORMS = {
	"colossus":    {2: [("horn_s", 2, -3, 14, 0), ("eye3", 6, 1, None, 0)],
	                3: [("horn_b", -2, -5, 18, 1), ("eye3", 6, 1, None, 0), ("spike", -2, 11, 18, 0)]},
	"sporemother": {2: [("tent", 3, 15, None, 1), ("eyes", 5, 2, None, 0)],
	                3: [("tent", 0, 15, None, 1), ("tent", 6, 15, None, 1), ("maw", 4, 9, None, 0), ("eyes", 5, 1, None, 0)]},
	"librarian":   {2: [("eyes", 5, 1, None, 0), ("horn_s", 2, -2, 14, 1)],
	                3: [("wingf", -5, 3, 21, 1), ("eyes", 5, 1, None, 0), ("tent", 3, 14, None, 1), ("horn_d", 1, -4, 15, 1)]},
	"tyrant":      {2: [("horn_d", 0, -4, 16, 1), ("spike", -1, 6, 17, 0)],
	                3: [("flames", 3, -3, None, 0), ("horn_d", -1, -4, 17, 1), ("spike", -2, 6, 18, 0), ("maw", 4, 9, None, 0)]},
	"rimewarden":  {2: [("spike", -1, 5, 17, 0), ("eye3", 6, 0, None, 0)],
	                3: [("horn_b", -3, -4, 19, 1), ("spike", -2, 5, 18, 0), ("spike", -2, 9, 18, 0), ("eye3", 6, 0, None, 0)]},
	"regent":      {2: [("horn_s", 3, -3, 13, 1), ("eye3", 6, 3, None, 0)],
	                3: [("wing", -6, 5, 22, 1), ("horn_b", 0, -5, 16, 1), ("eye3", 6, 3, None, 0)]},
	"bogmatriarch": {2: [("maw", 4, 9, None, 0), ("eyes", 5, 4, None, 0)],
	                3: [("maw", 4, 9, None, 0), ("tent", 3, 15, None, 1), ("horn_d", 0, -3, 16, 1), ("eyes", 5, 4, None, 0)]},
	"ashwarlord":  {2: [("horn_b", -2, -5, 18, 1)],
	                3: [("wing", -6, 4, 22, 1), ("horn_b", -3, -6, 19, 1), ("flames", 3, -4, None, 0)]},
	"frozenabbot": {2: [("spike", -1, 7, 17, 0), ("eye3", 6, 1, None, 0)],
	                3: [("horn_b", -2, -4, 18, 1), ("spike", -2, 7, 18, 0), ("spike", -2, 11, 18, 0), ("eyes", 5, 4, None, 0)]},
	"crowking":    {2: [("wing", -5, 6, 21, 1)],
	                3: [("wing", -6, 3, 22, 1), ("wing", -4, 8, 20, 1), ("eye3", 6, 1, None, 0), ("flames", 3, -3, None, 0)]},
	"umbralsun":   {2: [("eye3", 6, 3, None, 0)],
	                3: [("maw", 4, 8, None, 0), ("eyes", 5, 3, None, 0), ("spike", -3, 6, 19, 1)]},
	"holycow":     {2: [("horn_b", -1, -2, 17, 1), ("halo", 5, -2, None, 1)],
	                3: [("horn_d", -2, -3, 18, 1), ("wing", -6, 6, 22, 1), ("eyes", 5, 3, None, 0), ("flames", 3, -4, None, 0)]},
	"judge":       {2: [("eye3", 6, 2, None, 0), ("wingf", -4, 3, 20, 1)],
	                3: [("wingf", -6, 1, 22, 1), ("wingf", -4, 7, 20, 1), ("eyes", 5, 2, None, 0), ("halo", 5, -3, None, 1)]},
	"cinderking":  {2: [("horn_d", 0, -3, 16, 1), ("flames", 3, -4, None, 0)],
	                3: [("wing", -6, 4, 22, 1), ("horn_b", -2, -5, 18, 1), ("flames", 3, -5, None, 0), ("maw", 4, 9, None, 0)]},
	"unwritten":   {2: [("eyes", 5, 3, None, 0), ("tent", 3, 15, None, 1)],
	                3: [("tent", 0, 15, None, 1), ("tent", 6, 15, None, 1), ("eyes", 4, 2, None, 0), ("eyes", 6, 6, None, 0), ("horn_d", 1, -4, 15, 1)]},
	"stormcrown":  {2: [("spike", 0, 8, 24, 0), ("eye3", 10, 6, None, 0)],
	                3: [("horn_b", 2, -2, 22, 1), ("tent", 7, 21, None, 1), ("eyes", 9, 7, None, 0), ("spike", -1, 8, 25, 0)]},
	"bilgehydra":  {2: [("horn_s", 1, -3, 7, 1), ("horn_s", 9, -3, 15, 1), ("eyes", 9, 12, None, 0)],
	                3: [("horn_b", -1, -5, 9, 1), ("horn_b", 7, -5, 17, 1), ("maw", 8, 14, None, 0), ("tent", 7, 22, None, 1)]},
	"greatengine": {2: [("horn_d", 0, -4, 16, 1), ("spike", -1, 10, 17, 0)],
	                3: [("flames", 3, -3, None, 0), ("horn_b", -2, -5, 18, 1), ("spike", -2, 10, 18, 0), ("spike", -2, 5, 18, 0)]},
	"glacialmaw":  {2: [("horn_d", 0, -4, 16, 1), ("spike", -1, 10, 17, 0)],
	                3: [("horn_b", -2, -5, 18, 1), ("spike", -2, 10, 18, 0), ("spike", -2, 5, 18, 0), ("eyes", 5, 2, None, 0)]},
	"inkleviathan": {2: [("tent", 3, 15, None, 1), ("horn_d", 0, -3, 16, 1)], 3: [("tent", 0, 15, None, 1), ("tent", 6, 15, None, 1), ("eyes", 5, 3, None, 0), ("horn_b", -2, -5, 18, 1)]},
	"thebinder":   {2: [("spike", -1, 8, 17, 0)], 3: [("horn_b", 0, -4, 15, 1), ("spike", -2, 8, 18, 0), ("eye3", 6, 3, None, 0)]},
	"author":      {2: [("wing", -6, 6, 22, 1), ("eye3", 6, 2, None, 0)], 3: [("wing", -6, 3, 22, 1), ("wing", -6, 9, 22, 1), ("eyes", 4, 8, None, 0), ("flames", 3, -4, None, 0)]},
	"admiral":     {2: [("horn_s", 2, -2, 13, 1)], 3: [("horn_b", 0, -4, 15, 1), ("eyes", 5, 4, None, 0)]},
	"golemking":   {2: [("spike", -1, 8, 17, 0)], 3: [("horn_b", 0, -4, 15, 1), ("spike", -2, 8, 18, 0), ("spike", -2, 4, 18, 0)]},
	"archmage":    {2: [("eye3", 6, 1, None, 0)], 3: [("eyes", 4, 9, None, 0), ("tent", 4, 15, None, 1), ("horn_d", 1, -3, 15, 1)]},
	"phoenix":     {2: [("flames", 3, -3, None, 0)], 3: [("flames", 3, -4, None, 0), ("wing", -6, 3, 22, 1), ("eyes", 5, 4, None, 0)]},
	"wyrm":        {2: [("spike", -1, 9, 17, 0), ("horn_d", 0, -4, 16, 1)], 3: [("horn_b", -2, -5, 18, 1), ("wing", -6, 5, 22, 1), ("maw", 5, 10, None, 0)]},
	"chainfiend":  {2: [("horn_d", 0, -4, 16, 1)], 3: [("horn_b", -2, -5, 18, 1), ("flames", 3, -4, None, 0), ("maw", 5, 8, None, 0)]},
	"seraph":      {2: [("eye3", 6, 4, None, 0), ("wing", -6, 6, 22, 1)], 3: [("eyes", 4, 2, None, 0), ("eyes", 6, 9, None, 0), ("wing", -6, 3, 22, 1), ("wing", -6, 9, 22, 1)]},
	"brassorgan":  {2: [("spike", -2, 12, 43, 0), ("eye3", 18, 13, None, 0)],
	                3: [("horn_b", 1, -5, 40, 1), ("spike", -2, 12, 43, 0), ("spike", -2, 18, 43, 0), ("maw", 16, 18, None, 0), ("eyes", 17, 12, None, 0)]},
}

def _part_img(name, vb, meta):
    rows = PART[name]
    W = max(len(r) for r in rows)
    S["_part"] = (PART_META.get(name, meta) if "PART_META" in globals() else meta, [r.ljust(W, ".") for r in rows])
    im = sprite("_part", vb)
    S.pop("_part")
    return im

def form(im, name, stage, vb):
    """The guardian with its stage's parts; the canvas grows to hold them (bottom stays the bottom)."""
    base = name.replace("_elite", "") if name not in FORMS else name
    spec = FORMS.get(base, {}).get(stage, []) or _mini_form(MINIS[base][0], im.width).get(stage, []) if base in MINIS else FORMS.get(base, {}).get(stage, [])
    meta = S[base][0] if base in S else _dominant_meta(im)
    placed = []
    for (pn, x, y, xr, behind) in spec:
        pim = _part_img(pn, vb, meta)
        y = min(y, im.height - pim.height)   # the feet stay on the ground: nothing hangs below the sprite
        placed.append((pim, x, y, behind))
        if xr is not None:
            placed.append((pim.transpose(Image.FLIP_LEFT_RIGHT), xr - pim.width + 1, y, behind))
    x0 = min([0] + [x for _, x, _, _ in placed]); y0 = min([0] + [y for _, _, y, _ in placed])
    x1 = max([im.width] + [x + p.width for p, x, _, _ in placed]); y1 = max([im.height] + [y + p.height for p, _, y, _ in placed])
    # keep the sprite centred: grow the same amount on both sides
    side = max(-x0, x1 - im.width)
    W, H = im.width + 2 * side, im.height - y0 + max(0, y1 - im.height)
    out = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ox, oy = side, -y0
    for p, x, y, b in placed:
        if b: out.alpha_composite(p, (ox + x, oy + y))
    out.alpha_composite(im, (ox, oy))
    for p, x, y, b in placed:
        if not b: out.alpha_composite(p, (ox + x, oy + y))
    return out

# ---- 6.1 (his ask, 6 Oct): mini-bosses, rift minis and champions evolve too: four kinds of form,
# placed for each one's size (12 or 16 wide), each burning in its own colour. Their elites too.
def _mini_form(kind, W):
    c = W // 2   # the middle column pair is c-1, c
    R = lambda x: W - 1 - x   # where the mirrored copy of a part starting at x ends
    if kind == "brute":
        return {2: [("horn_s", 1, -3, R(1), 1)],
		        3: [("horn_b", -2, -5, R(-2), 1), ("spike", -2, 5, R(-2), 0)]}
    if kind == "wing":
        return {2: [("wingf", -4, 1, R(-4), 1)],
		        3: [("wing", -6, 0, R(-6), 1), ("eye3", c - 2, 0, None, 0)]}
    if kind == "maw":
        return {2: [("eyes", c - 3, 0, None, 0)],
		        3: [("maw", c - 4 - (W % 2), W // 2 - 1, None, 0), ("eyes", c - 3, -1, None, 0), ("horn_d", 0, -3, R(0), 1)]}
    return {2: [("spike", -1, 3, R(-1), 0)],
	        3: [("flames", c - 5, -3, None, 0), ("spike", -2, 3, R(-2), 0), ("spike", -2, 7, R(-2), 0)]}

MINIS = {   # mini-boss or champion -> (kind of form, the colour it burns with)
	"mirehulk": ("brute", "#b8ff3a"), "ironcaptain": ("fire", "#ff8a1a"), "stoneabbot": ("maw", "#7ff0ff"),
	"enforcer": ("fire", "#ff3b30"), "herald": ("wing", "#ffe060"), "turnkey": ("brute", "#ff4a3a"),
	"carrionknight": ("wing", "#ff2a2a"), "broker": ("maw", "#ff6ad0"), "mayor": ("fire", "#ffb040"),
	"rustbutcher": ("brute", "#ff3020"), "landlord": ("maw", "#ff6ad0"), "kingpin": ("fire", "#ffd84a"),
	"marshal": ("brute", "#ffa040"), "galewarden": ("wing", "#7ff0ff"), "rotking": ("maw", "#9aff3a"),
	"highcaliber": ("fire", "#ff5a1a"), "squallheron": ("wing", "#8ae8ff"), "tidecaptain": ("brute", "#5affa0"),
	"bellringer": ("maw", "#c05aff"), "shadow": ("maw", "#d08aff"), "foreman": ("brute", "#ffa040"),
	"hoarknight": ("brute", "#8fe8ff"),
	"inkwidow": ("maw", "#c08aff"), "bindingpress": ("brute", "#ffb040"), "headscribe": ("wing", "#fff07a"),
}

def _dominant_meta(im):
    from collections import Counter
    px = im.load()
    cnt = Counter(px[x, y][:3] for y in range(im.height) for x in range(im.width)
                  if px[x, y][3] > 128 and sum(px[x, y][:3]) > 150)
    c = cnt.most_common(1)[0][0] if cnt else (90, 74, 106)
    return "main:#%02x%02x%02x" % c

# ---- 6.2 (his ask, 6 Oct): Rex evolves too, cute and not scary: party Rex (stage 2: a party hat,
# a red bandana, sparkles), super Rex (stage 3: a golden crown, a red hero cape, hearts, a soft glow).
def _bandana(w):
    rows = ["o" * w]
    i = 1
    while w - 2 * i > 1:
        mid = "".join("l" if (k + i) % 4 == 0 else "2" for k in range(w - 2 * i))
        rows.append("." * (i - 1) + "o" + mid + "o" + "." * (i - 1))
        i += 1
    rows.append("." * (i - 1) + "o" * max(1, w - 2 * (i - 1)) + "." * (i - 1))
    return [r[:w].ljust(w, ".") for r in rows]

def _cape(w, h):
    rows = []
    for y in range(h):
        inset = max(0, 3 - y)
        mid = "".join("3" if x < 2 else ("1" if x >= w - 2 * inset - 4 else "2") for x in range(w - 2 * inset - 2))
        rows.append("." * inset + "o" + mid + "o" + "." * inset)
    rows.append("o" * w)
    return rows

PART.update({
	"partyhat": ["...y...", "..oxo..", "..o3o..", ".o3b1o.", ".o3b1o.", "o33b11o", "ooooooo"],
	"crown": ["q.q.q.q.q", "qqqqqqqqq", "qryqyqyrq", "ppppppppp"],
	"heart": [".o.o.", "obobo", "obbbo", ".obo.", "..o.."],
	"sparkle": [".y.", "yxy", ".y."],
	"bandana": _bandana(18),
	"cape": _cape(40, 14),
})
PART_META = {
	"partyhat": "main:#ff6ad0 second:#ffe060 glow:#ffffff", "crown": "main:#e8b84a glow:#ff6ad0",
	"heart": "main:#ff4a6a second:#ff4a6a", "sparkle": "main:#fff4b0 glow:#fff4b0",
	"bandana": "main:#d8443c bone:#f4ecd8", "cape": "main:#c0303a",
}
FORMS.update({
	"rex": {2: [("partyhat", 14, -7, None, 0), ("bandana", 8, 15, None, 0), ("sparkle", 1, 4, 32, 0)],
	        3: [("cape", -3, 15, None, 1), ("crown", 12, -4, None, 0), ("heart", -4, 2, 37, 0), ("sparkle", 0, 10, 33, 0),
	            ("sparkle", 4, -3, 29, 0)]},
	"rex_lie": {2: [("partyhat", 4, -6, None, 0), ("sparkle", 18, 0, None, 0)],
	            3: [("crown", 3, -4, None, 0), ("heart", 16, -2, None, 0), ("heart", 24, 0, None, 0), ("sparkle", 32, 2, None, 0)]},
})

def cute(im, stage):
    """Rex's evolved look: his parts on, then (stage 3) a soft pink-gold glow; never darker."""
    out = im.copy()
    if stage == 3:
        px = out.load(); cur = im.copy().load(); W, H = im.width, im.height
        for y in range(H):
            for x in range(W):
                if cur[x, y][3] < 128 and any(0 <= x + dx < W and 0 <= y + dy < H and cur[x + dx, y + dy][3] >= 128
                                              for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                    px[x, y] = (255, 214, 140, 110)
    return out
