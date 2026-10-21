"""Cut a SpriteCook sheet back into its sprites: each blob of solid pixels belongs to the grid cell its
middle falls in, and a cell's blobs are cropped together (a hero and the bird on his shoulder).
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
                xs = [p[0] for p in pts]; ys = [p[1] for p in pts]
                out.append((min(xs), min(ys), max(xs) + 1, max(ys) + 1, len(pts), sum(xs) / len(pts), sum(ys) / len(pts)))
    return out

def cut(path, cols, rows, names, out_dir=RAW):
    im = Image.open(path).convert("RGBA")
    w, h = im.size
    cells = {}
    for b in blobs(im):
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
        mp = mask.load(); ap = im.getchannel("A").load()
        for b in keep:
            for y in range(b[1], b[3]):
                for x in range(b[0], b[2]):
                    if ap[x, y] >= 128:
                        mp[x, y] = 255
        part.putalpha(Image.composite(im.getchannel("A"), Image.new("L", im.size, 0), mask).crop(box))
        part.save(os.path.join(out_dir, n + ".png"))
        report.append((n, len(keep), part.size))
    extra = sorted(set(cells) - set(range(len(names))))
    return report, extra

if __name__ == "__main__":
    a = sys.argv[1:]
    print(cut(a[0], int(a[1]), int(a[2]), a[3:]))
