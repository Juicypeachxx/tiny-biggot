"""Takes away the names Nano Banana sometimes writes under each drawing of a sheet, though the prompt
asks it not to (22 Oct, weapon sheets w02, w06, w10).
- In each grid cell: the small blobs that lie below the cell's drawing, in its lower part, and
  together make a line wider than it is tall.
- A name that touches its drawing (a wand's handle) is part of the drawing's blob. So in a grid row
  where most cells had a name, everything on that row's line of writing goes (a handle dipping
  into it loses its tip).
python3 resprite/tools/strip_labels.py SHEET.png COLS ROWS OUT.png"""
import os, sys
from PIL import Image
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sheet_cut import blobs

def strip(path, cols, rows, out):
    im = Image.open(path).convert("RGBA")
    w, h = im.size
    ch = h / rows
    cells = {}
    for b in blobs(im, min_area=1):
        c = (min(cols - 1, int(b[5] * cols / w)), min(rows - 1, int(b[6] * rows / h)))
        cells.setdefault(c, []).append(b)
    px = im.load()
    gone = 0
    lines = {}                                      # grid row -> [(top, bottom)] of its names
    for (cx, cy), bs in cells.items():
        main = max(bs, key=lambda b: b[4])
        text = [b for b in bs if b is not main
                and b[3] - b[1] <= ch * 0.2                 # a line of small writing
                and b[1] >= cy * ch + ch * 0.6              # in the cell's lower part
                and b[6] > main[6]]                         # under the drawing's middle
        if not text:
            continue
        x0, x1 = min(b[0] for b in text), max(b[2] for b in text)
        y0, y1 = min(b[1] for b in text), max(b[3] for b in text)
        if x1 - x0 < 1.5 * (y1 - y0):               # not a line of writing: a spark, a drip
            continue
        for b in text:
            for x, y in b[7]:
                px[x, y] = (0, 0, 0, 0)
        gone += len(text)
        lines.setdefault(cy, []).append((y0, y1))
    for cy, ls in lines.items():
        if len(ls) < cols // 2:
            continue
        top = sorted(t for t, _ in ls)[len(ls) // 2] - 1
        bottom = max(b for _, b in ls) + 1
        for y in range(max(0, top), min(h, bottom)):
            for x in range(w):
                px[x, y] = (0, 0, 0, 0)
    im.save(out)
    return gone

if __name__ == "__main__":
    a = sys.argv[1:]
    print("took away %d bits of writing" % strip(a[0], int(a[1]), int(a[2]), a[3]))
