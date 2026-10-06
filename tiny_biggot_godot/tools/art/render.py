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
 "C": dict(name="GLOW", tones=[(0.1,1.25,0.48),(0,1.2,1.02),(-0.07,0.65,1.35)], sat=1.3, val=1.0,
           outline=(0.14,0.06,0.2), colored_outline=True, rim=(1.0,0.86,0.5), halo=170, halo2=70),
}

def tones(base, vb):
    h,s,v = hsv(hx(base))
    s*=vb["sat"]; v*=vb["val"]
    return [toh(rgb(h+dh, s*ds, v*dv)) for dh,ds,dv in vb["tones"]]

def sprite(name, vb, rng=None):
    meta, grid = S[name]
    m = dict(kv.split(':') for kv in meta.split())
    mats = {"123": m.get("main","#888888"), "abc": m.get("second","#3f7fbf"), "jkl": BONE, "456": SKIN,
            "789": METAL, "pqr": GOLD, "uvw": WOOD}
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
        oc = rgb(mh[0]+0.04, 0.6, 0.16)
    pal["o"] = toh(oc)+(255,)
    W,H = len(grid[0]), len(grid)
    im = Image.new("RGBA",(W,H),(0,0,0,0)); px = im.load()
    for y,row in enumerate(grid):
        for x,ch in enumerate(row):
            if ch != '.': px[x,y] = pal[ch]
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

def kit(vb, seed=7):
    """256x64: row 0 sixteen 16px floor tiles (pairs for the checker), row 1 walls (top, face,
    bottom, left, right, void), rows 2-3 the pillar (17x32)."""
    rnd = random.Random(seed)
    T = 16
    im = Image.new("RGBA",(256,64),(0,0,0,0)); px = im.load()
    fl = tones("#4a4060", vb); fl2 = tones("#443a58", vb)
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
    wall = tones("#3a3050", vb); cap = tones("#6a5f85", vb); void = toh(rgb(*hsv(hx("#140f1c")))) if False else (20,15,28,255)
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

def all_for(v):
    vb = VIBES[v]
    out = {n: sprite(n, vb) for n in S}
    out["kit0"] = kit(vb)
    return out
