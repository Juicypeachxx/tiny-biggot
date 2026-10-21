"""A reference sheet for SpriteCook: today's sprites in a grid, enlarged, on clear.
python3 resprite/tools/sheet_ref.py OUT.png COLS [--fill] NAME [NAME...]   ("-" leaves a cell empty)"""
import os, sys
from PIL import Image
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from inventory import G

def build(out, cols, names, fill=False):
    """fill: each sprite scaled on its own to fill its cell (guardians of mixed sizes), else all alike."""
    ims = [None if n == "-" else Image.open(os.path.join(G, n + ".png")).convert("RGBA") for n in names]
    big = max(max(i.width, i.height) for i in ims if i)
    scale = max(1, min(8, 112 // big)) if big <= 56 else max(1, 224 // big)
    cell = 256 if fill else (128 if big * scale <= 112 else 256)
    rows = (len(names) + cols - 1) // cols
    sheet = Image.new("RGBA", (cols * cell, rows * cell), (0, 0, 0, 0))
    for i, im in enumerate(ims):
        if im is None:
            continue
        k = max(1, (cell - 24) // max(im.width, im.height)) if fill else scale
        b = im.resize((im.width * k, im.height * k), Image.NEAREST)
        sheet.alpha_composite(b, ((i % cols) * cell + (cell - b.width) // 2, (i // cols) * cell + (cell - b.height) // 2))
    sheet.save(out)
    return sheet.size, scale

if __name__ == "__main__":
    a = sys.argv[3:]
    print(build(sys.argv[1], int(sys.argv[2]), [n for n in a if n != "--fill"], fill="--fill" in a))
