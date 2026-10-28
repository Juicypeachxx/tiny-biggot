"""Cut a SpriteCook sheet back into its sprites: each blob of solid pixels belongs to the grid cell its
middle falls in, and a cell's blobs are cropped together (a hero and the bird on his shoulder). A blob
that runs over a grid line is cut there first.
python3 resprite/tools/sheet_cut.py SHEET.png COLS ROWS NAME [NAME...]   ("-" skips a cell)
-> resprite/spritecook/<name>.png"""
import os, sys
from PIL import Image
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from spritecook_fit import RAW

def blobs(im, min_area=6):
    a = im.getchannel("A").load()
    w, h = im.size
    seen = bytearray(w * h)
    out = []
    for y in range(h):
        for x in range(w):
            if seen[y * w + x] or a[x, y] < 128:
                continue
            stack, pts = [(x, y)], []
            seen[y * w + x] = 1
            while stack:
                px, py = stack.pop()
                pts.append((px, py))
                for dx in (-1, 0, 1):
                    for dy in (-1, 0, 1):
                        nx, ny = px + dx, py + dy
                        if 0 <= nx < w and 0 <= ny < h and not seen[ny * w + nx] and a[nx, ny] >= 128:
                            seen[ny * w + nx] = 1
                            stack.append((nx, ny))
            if len(pts) >= min_area:
                out.append(_box(pts))
    return out

def _box(pts):
    xs = [p[0] for p in pts]; ys = [p[1] for p in pts]
    return (min(xs), min(ys), max(xs) + 1, max(ys) + 1, len(pts), sum(xs) / len(pts), sum(ys) / len(pts), pts)

def _split(b, size, n, axis):
    """A blob that runs over a grid line (a plume touching the feet above it) is cut in two at its
    thinnest line within a fifth of a cell of that grid line."""
    cell = size / n
    lo, hi = b[axis], b[axis + 2]
    if hi - lo <= cell * 1.15:
        return [b]
    count = {}
    for p in b[7]:
        count[p[axis]] = count.get(p[axis], 0) + 1
    lines = [round(k * cell) for k in range(1, n) if lo < k * cell < hi]
    if not lines:
        return [b]
    g = min(lines, key=lambda v: abs(v - (lo + hi) / 2))
    near = range(max(lo + 1, int(g - cell / 5)), min(hi, int(g + cell / 5) + 1))
    cut_at = min(near, key=lambda v: (count.get(v, 0), abs(v - g)))
    a = [p for p in b[7] if p[axis] < cut_at]
    c = [p for p in b[7] if p[axis] >= cut_at]
    return [part for pts in (a, c) if pts for part in _split(_box(pts), size, n, axis)]

def cut(path, cols, rows, names, out_dir=RAW):
    im = Image.open(path).convert("RGBA")
    w, h = im.size
    cells = {}
    parts = [q for b in blobs(im) for p in _split(b, h, rows, 1) for q in _split(p, w, cols, 0)]
    for b in parts:
        c = min(cols - 1, int(b[5] * cols / w)) + cols * min(rows - 1, int(b[6] * rows / h))
        cells.setdefault(c, []).append(b)
    report = []
    for i, n in enumerate(names):
        bs = cells.get(i, [])
        if n == "-" or not bs:
            report.append((n, 0))
            continue
        main = max(bs, key=lambda b: b[4])
        keep = [b for b in bs if b[4] >= main[4] * 0.02]          # specks off, parts on
        box = (min(b[0] for b in keep), min(b[1] for b in keep), max(b[2] for b in keep), max(b[3] for b in keep))
        part = im.crop(box)
        mask = Image.new("L", im.size, 0)                        # only this cell's blobs (no neighbour's tip)
        mp = mask.load()
        for b in keep:
            for x, y in b[7]:
                mp[x, y] = 255
        part.putalpha(Image.composite(im.getchannel("A"), Image.new("L", im.size, 0), mask).crop(box))
        part.save(os.path.join(out_dir, n + ".png"))
        report.append((n, len(keep), part.size))
    extra = sorted(set(cells) - set(range(len(names))))
    return report, extra

if __name__ == "__main__":
    a = sys.argv[1:]
    print(cut(a[0], int(a[1]), int(a[2]), a[3:]))
