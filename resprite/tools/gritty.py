"""The gritty dark-fantasy look at double detail (his pick, 21 Oct: "keep the vibe and theme of
it, make same art style vibe on all sprites in the game"), made from the game's own pictures so
every creature and item stays itself:
- twice the size (Scale2x: diagonals stay sharp, no blur);
- a thin near-black outline (the old 2-pixel outline's inner half becomes a shaded edge);
- earthy, muted colours: less saturation, deeper shadows that lean cold, lights that lean warm;
  small bright accents (eyes, gems, flames) stay bright;
- light from the top left (a lit rim on top and left, a shadow on the bottom and right);
- a little grit: specks and a dither in the shadows, the same every time for a picture."""
import colorsys, hashlib

from PIL import Image

OUTLINE = (18, 12, 14, 255)

def scale2x(im):
    """Scale2x (EPX): every pixel becomes four, the corners follow the diagonals."""
    W, H = im.size
    src = im.load()
    out = Image.new("RGBA", (W * 2, H * 2), (0, 0, 0, 0))
    o = out.load()
    def at(x, y):
        if 0 <= x < W and 0 <= y < H:
            c = src[x, y]
            return c if c[3] >= 128 else (0, 0, 0, 0)
        return (0, 0, 0, 0)
    for y in range(H):
        for x in range(W):
            p = at(x, y)
            a, b, c, d = at(x, y - 1), at(x + 1, y), at(x - 1, y), at(x, y + 1)
            e0 = a if (c == a and c != d and a != b) else p
            e1 = b if (a == b and a != c and b != d) else p
            e2 = c if (d == c and d != b and c != a) else p
            e3 = d if (b == d and b != a and d != c) else p
            o[2 * x, 2 * y], o[2 * x + 1, 2 * y], o[2 * x, 2 * y + 1], o[2 * x + 1, 2 * y + 1] = e0, e1, e2, e3
    return out

def _hsv(c):
    return colorsys.rgb_to_hsv(c[0] / 255, c[1] / 255, c[2] / 255)

def _rgb(h, s, v, a=255):
    r, g, b = colorsys.hsv_to_rgb(h % 1.0, max(0.0, min(1.0, s)), max(0.0, min(1.0, v)))
    return (int(r * 255 + 0.5), int(g * 255 + 0.5), int(b * 255 + 0.5), a)

def _accent(c):
    h, s, v = _hsv(c)
    return s > 0.55 and v > 0.72

def grade(c, light):
    """The look's colours: muted and earthy; light -1 (shadow) .. 0 .. 1 (lit)."""
    h, s, v = _hsv(c)
    if _accent(c):
        return _rgb(h, min(1.0, s * 1.05), min(1.0, v * (1.0 + 0.08 * light)), c[3])
    s = s * 0.72
    v = v * 0.86
    warm = h < 0.17 or h > 0.93
    if light > 0:
        v = v + (1 - v) * 0.22 * light
        h = h + (0.012 if warm else -0.01) * light
        s = s * (1 - 0.12 * light)
    elif light < 0:
        v = v * (1 + 0.32 * light)
        h = h + 0.035 * light * (-1 if h < 0.66 and h > 0.2 else 1) if not warm else h - 0.01 * light
        s = min(1.0, s * (1 - 0.15 * light))
    return _rgb(h, s, v, c[3])

def gritty(im, name):
    im = im.convert("RGBA")
    W, H = im.size
    p1 = im.load()
    solid1 = [[p1[x, y][3] >= 128 for x in range(W)] for y in range(H)]
    def edge1(x, y):
        return any(not (0 <= x + dx < W and 0 <= y + dy < H) or not solid1[y + dy][x + dx]
                   for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
    dark_rim = [[solid1[y][x] and edge1(x, y) and _hsv(p1[x, y])[2] < 0.3 for x in range(W)] for y in range(H)]
    big = scale2x(im)
    w, h = big.size
    px = big.load()
    solid = [[px[x, y][3] >= 128 for x in range(w)] for y in range(h)]
    def clear(x, y):
        return not (0 <= x < w and 0 <= y < h) or not solid[y][x]
    def reach(x, y, dx, dy, n=3):
        for k in range(1, n + 1):
            if clear(x + dx * k, y + dy * k):
                return k
        return n + 1
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    o = out.load()
    seed = int(hashlib.md5(name.encode()).hexdigest()[:8], 16)
    for y in range(h):
        for x in range(w):
            if not solid[y][x]:
                continue
            c = px[x, y]
            if any(clear(x + dx, y + dy) for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                o[x, y] = OUTLINE
                continue
            if dark_rim[y // 2][x // 2]:   # the old outline's inner half: the colour beside it, in shadow
                near = [px[x + dx, y + dy] for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (-1, -1), (1, -1), (-1, 1))
                        if not clear(x + dx, y + dy) and not dark_rim[(y + dy) // 2][(x + dx) // 2]]
                if near:
                    c = near[0]
            tl = min(reach(x, y, 0, -1), reach(x, y, -1, 0))
            br = min(reach(x, y, 0, 1), reach(x, y, 1, 0))
            light = 0.0
            if tl <= 2:
                light += 0.9 if tl == 1 else 0.45
            if br <= 2:
                light -= 0.9 if br == 1 else 0.5
            light += 0.25 * (0.5 - y / h)          # a little lighter at the top
            hsh = (seed ^ (x * 73856093) ^ (y * 19349663)) & 0xffff
            if not _accent(c):
                if hsh < 0xffff * 0.10:
                    light -= 0.35                      # specks of grit
                elif hsh < 0xffff * 0.14:
                    light += 0.25
                if light < -0.3 and (x + y) % 2 == 0:  # dither in the shadows
                    light -= 0.2
            o[x, y] = grade(c, max(-1.0, min(1.0, light)))
    return out


# ---- v2: a stronger take on the look (darker, more contrast, dithered light, glowing accents) ----
BAYER = ((0.0, 0.5), (0.75, 0.25))

def grade2(c, L):
    """L: -1 (deep shadow) .. 1 (lit). Muted, dark, cold shadows, warm light; accents glow."""
    h, s, v = _hsv(c)
    if _accent(c):
        return _rgb(h, min(1.0, s * 1.15), min(1.0, v * 1.08), c[3])
    s, v = s * 0.62, v * 0.80
    warm = h < 0.17 or h > 0.93
    if L > 0:
        v = v + (1 - v) * 0.30 * L
        h = h + (0.015 if warm else 0.0) * L
        s = s * (1 - 0.18 * L)
    elif L < 0:
        v = v * (1 + 0.52 * L)
        target = 0.70                                   # shadows lean blue-violet
        h = h + (target - h) * 0.12 * (-L) if not warm else h - 0.015 * L
        s = min(1.0, s * (1 + 0.1 * -L))
    return _rgb(h, s, v, c[3])

def gritty2(im, name):
    im = im.convert("RGBA")
    W, H = im.size
    p1 = im.load()
    solid1 = [[p1[x, y][3] >= 128 for x in range(W)] for y in range(H)]
    def edge1(x, y):
        return any(not (0 <= x + dx < W and 0 <= y + dy < H) or not solid1[y + dy][x + dx]
                   for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
    dark_rim = [[solid1[y][x] and edge1(x, y) and _hsv(p1[x, y])[2] < 0.3 for x in range(W)] for y in range(H)]
    big = scale2x(im)
    w, h = big.size
    px = big.load()
    solid = [[px[x, y][3] >= 128 for x in range(w)] for y in range(h)]
    ys = [y for y in range(h) for x in range(w) if solid[y][x]]
    xs = [x for y in range(h) for x in range(w) if solid[y][x]]
    if not xs:
        return big
    x0, x1, y0, y1 = min(xs), max(xs) + 1, min(ys), max(ys) + 1
    def clear(x, y):
        return not (0 <= x < w and 0 <= y < h) or not solid[y][x]
    def reach(x, y, dx, dy, n=3):
        for k in range(1, n + 1):
            if clear(x + dx * k, y + dy * k):
                return k
        return n + 1
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    o = out.load()
    seed = int(hashlib.md5(name.encode()).hexdigest()[:8], 16)
    for y in range(h):
        for x in range(w):
            if not solid[y][x]:
                continue
            c = px[x, y]
            if any(clear(x + dx, y + dy) for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                o[x, y] = OUTLINE
                continue
            if dark_rim[y // 2][x // 2]:
                near = [px[x + dx, y + dy] for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (-1, -1), (1, -1), (-1, 1))
                        if not clear(x + dx, y + dy) and not dark_rim[(y + dy) // 2][(x + dx) // 2]]
                if near:
                    c = near[0]
            tl = min(reach(x, y, 0, -1), reach(x, y, -1, 0))
            br = min(reach(x, y, 0, 1), reach(x, y, 1, 0))
            L = 0.55 - 0.9 * (y - y0) / max(1, y1 - y0) - 0.35 * (x - x0) / max(1, x1 - x0)   # light from the top left
            if tl == 1:
                L += 0.9
            elif tl == 2:
                L += 0.35
            if br == 1:
                L -= 0.8
            elif br == 2:
                L -= 0.35
            hsh = ((seed ^ (x * 73856093) ^ (y * 19349663)) * 2654435761 >> 7) & 0xffff
            if hsh < 0xffff * 0.16:
                L -= 0.45                                    # grit
            elif hsh < 0xffff * 0.22:
                L += 0.3
            L = max(-1.0, min(1.0, L))
            q = (L + 1) * 2 + BAYER[y % 2][x % 2] - 0.5        # dithered between five steps
            L = max(-1.0, min(1.0, round(q) / 2 - 1))
            o[x, y] = grade2(c, L)
    return out
