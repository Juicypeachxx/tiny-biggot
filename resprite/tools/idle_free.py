"""A free idle from one still (no credits): the upper body breathes down a pixel and back over 8
frames, and bright details (eyes, gems) pulse. python3 resprite/tools/idle_free.py IN.png OUT.gif"""
import sys
from PIL import Image

def lum(c):
    return 0.299 * c[0] + 0.587 * c[1] + 0.114 * c[2]

def frames(im, n=8, cut=0.6):
    w, h = im.size
    src = im.load()
    ys = [y for y in range(h) for x in range(w) if src[x, y][3]]
    top, bot = min(ys), max(ys)
    split = top + int((bot - top) * cut)             # rows above this breathe; the legs stay
    vis = [src[x, y] for y in range(h) for x in range(w) if src[x, y][3]]
    avg = sum(lum(c) for c in vis) / len(vis)
    glow = {(x, y) for y in range(h) for x in range(w) if src[x, y][3] and lum(src[x, y]) >= avg + 70}
    out = []
    for i in range(n):
        f = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        p = f.load()
        down = 1 if i in (2, 3, 4, 5) else 0          # in, hold, out: a slow breath
        for y in range(h):
            for x in range(w):
                sy = y - down if y <= split else y
                if y == split + 1 and down:         # the row where the body folds keeps its own pixels
                    sy = y
                if 0 <= sy < h:
                    p[x, y] = src[x, sy]
        k = 1.0 + 0.35 * (0.5 - 0.5 * __import__("math").cos(i / n * 6.2832))
        for (x, y) in glow:
            ty = y + down if y <= split else y
            if 0 <= ty < h:
                c = p[x, ty]
                if c[3]:
                    p[x, ty] = tuple(min(255, int(v * k)) for v in c[:3]) + (255,)
        out.append(f)
    return out

if __name__ == "__main__":
    im = Image.open(sys.argv[1]).convert("RGBA")
    fs = frames(im)
    U = 6
    big = [f.resize((f.width * U, f.height * U), Image.NEAREST) for f in fs]
    bg = [Image.new("RGBA", b.size, (34, 30, 40, 255)) for b in big]
    for b, g in zip(big, bg):
        g.alpha_composite(b)
    bg[0].convert("RGB").save(sys.argv[2], save_all=True, append_images=[g.convert("RGB") for g in bg[1:]], duration=150, loop=0)
    print(len(fs), "frames")
