"""A reference sheet for SpriteCook: today's sprites in a grid, enlarged, on clear.
python3 resprite/tools/sheet_ref.py OUT.png COLS NAME [NAME...]   ("-" leaves a cell empty)"""
import os, sys
from PIL import Image
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from inventory import G

def build(out, cols, names):
    ims = [None if n == "-" else Image.open(os.path.join(G, n + ".png")).convert("RGBA") for n in names]
    big = max(max(i.width, i.height) for i in ims if i)
    scale = max(1, min(8, 112 // big)) if big <= 56 else max(1, 224 // big)
    cell = 128 if big * scale <= 112 else 256
    rows = (len(names) + cols - 1) // cols
    sheet = Image.new("RGBA", (cols * cell, rows * cell), (0, 0, 0, 0))
    for i, im in enumerate(ims):
        if im is None:
            continue
        b = im.resize((im.width * scale, im.height * scale), Image.NEAREST)
        sheet.alpha_composite(b, ((i % cols) * cell + (cell - b.width) // 2, (i // cols) * cell + (cell - b.height) // 2))
    sheet.save(out)
    return sheet.size, scale

if __name__ == "__main__":
    print(build(sys.argv[1], int(sys.argv[2]), sys.argv[3:]))
