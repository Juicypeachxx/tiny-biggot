"""Armour pieces drawn on each hero (66.4, his word, 27 Oct: the painted armour "still looks funny
and out of place"). python3 -I resprite/tools/gear_pieces.py <dir of edits>
- <dir>/<hero>__<shape>.png: the hero's picture with that piece put on by PixelLab (edit_image_pixen).
- A piece is what the edit changed: each pixel that differs from the hero's own picture (or is new),
  in the rows where that piece is worn, small specks dropped, small holes inside it filled.
- tiny_biggot_godot/assets/gear_pieces/<hero>.png: the hero's pieces side by side, one cell of the
  picture's size each, in SHAPES' order (scripts/render/hero_gear.gd has the same list); the game
  paints each in the colours of the item worn (hero_gear.gd _drawn)."""
import os, sys
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
HD = os.path.join(ROOT, "tiny_biggot_godot", "assets", "graphics_hd")
OUT = os.path.join(ROOT, "tiny_biggot_godot", "assets", "gear_pieces")
SHAPES = ["helm", "hood", "hat", "crown", "mask", "plate", "leather", "robe", "cloak", "boots", "greaves", "gloves", "shield"]

def rows(shape, by):
    """The rows a piece may change, by the build every hero shares (feet on row by, the chin 25 above)."""
    chin, hip = by - 25, by - 10
    if shape in ("helm", "hood", "hat", "crown", "mask"):
        return 0, chin + (6 if shape == "hood" else 3)
    if shape in ("plate", "leather"):
        return chin - 2, hip + 3
    if shape in ("robe", "cloak"):
        return chin - 3, by
    if shape in ("boots", "greaves"):
        return by - (8 if shape == "boots" else 13), by
    if shape == "gloves":
        return hip - 10, hip + 4
    return chin - 2, by      # the shield

def piece(base, edit, shape):
    w, h = base.size
    a, b = base.load(), edit.load()
    by = max(y for y in range(h) for x in range(w) if a[x, y][3] > 127)
    y0, y1 = rows(shape, by)
    on = set()
    for y in range(max(0, y0), min(h, y1 + 1)):
        for x in range(w):
            p, q = a[x, y], b[x, y]
            if q[3] <= 127:
                continue
            if p[3] <= 127 or abs(p[0] - q[0]) + abs(p[1] - q[1]) + abs(p[2] - q[2]) > 30:
                on.add((x, y))
    for _ in range(2):      # holes: a pixel of the edit with three neighbours in the piece
        for y in range(max(0, y0), min(h, y1 + 1)):
            for x in range(w):
                if (x, y) not in on and b[x, y][3] > 127:
                    n = sum((x + dx, y + dy) in on for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
                    if n >= 3:
                        on.add((x, y))
    keep = set()      # specks: groups of fewer than 6 pixels
    seen = set()
    for p in on:
        if p in seen:
            continue
        group, todo = [], [p]
        seen.add(p)
        while todo:
            c = todo.pop()
            group.append(c)
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                d = (c[0] + dx, c[1] + dy)
                if d in on and d not in seen:
                    seen.add(d)
                    todo.append(d)
        if len(group) >= 6:
            keep.update(group)
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    o = out.load()
    for x, y in keep:
        o[x, y] = b[x, y]
    return out, len(keep)

def main():
    src = sys.argv[1]
    os.makedirs(OUT, exist_ok=True)
    heroes = sorted({f.split("__")[0] for f in os.listdir(src) if "__" in f and f.endswith(".png")})
    for hero in heroes:
        base = Image.open(os.path.join(HD, hero + ".png")).convert("RGBA")
        w, h = base.size
        strip = Image.new("RGBA", (w * len(SHAPES), h), (0, 0, 0, 0))
        counts = []
        for i, s in enumerate(SHAPES):
            p = os.path.join(src, hero + "__" + s + ".png")
            if not os.path.exists(p):
                counts.append("-")
                continue
            pc, n = piece(base, Image.open(p).convert("RGBA"), s)
            strip.alpha_composite(pc, (i * w, 0))
            counts.append(str(n))
        strip.save(os.path.join(OUT, hero + ".png"))
        print(hero, " ".join(counts))

if __name__ == "__main__":
    main()
