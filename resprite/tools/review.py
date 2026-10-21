"""Review sheets for him: every picture today (left) and in the new look (right), big enough to
see, in rows with their names. python3 resprite/tools/review.py OUT.png NAME [NAME...]
The new look is resprite/hd/<name>.png when there is one (his Gemini foes), else made now."""
import os, sys
from PIL import Image, ImageDraw
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from inventory import G, ROOT
from gritty import gritty

HD = os.path.join(ROOT, "resprite", "hd")
BG = (34, 30, 40, 255)

def new_of(name):
    p = os.path.join(HD, name + ".png")
    if os.path.exists(p):
        return Image.open(p).convert("RGBA"), True
    return gritty(Image.open(os.path.join(G, name + ".png")), name), False

def sheet(out, names, per_row=6, unit=4):
    cells = []
    for n in names:
        old = Image.open(os.path.join(G, n + ".png")).convert("RGBA")
        new, hand = new_of(n)
        cells.append((n, old, new, hand))
    big = max(max(o.width, o.height) for _, o, _, _ in cells)
    side = big * 2 * unit                      # the new one at `unit`, the old one at twice that
    cw, ch = side * 2 + 30, side + 22
    rows = (len(cells) + per_row - 1) // per_row
    img = Image.new("RGBA", (per_row * cw + 10, rows * ch + 10), BG)
    d = ImageDraw.Draw(img)
    for i, (n, old, new, hand) in enumerate(cells):
        x = 10 + (i % per_row) * cw
        y = 10 + (i // per_row) * ch
        o2 = old.resize((old.width * unit * 2, old.height * unit * 2), Image.NEAREST)
        n2 = new.resize((new.width * unit, new.height * unit), Image.NEAREST)
        img.alpha_composite(o2, (x + (side - o2.width) // 2, y + side - o2.height))
        img.alpha_composite(n2, (x + side + 12 + (side - n2.width) // 2, y + side - n2.height))
        d.text((x, y + side + 4), n + ("  (Gemini)" if hand else ""), fill=(200, 190, 170, 255))
    img.convert("RGB").save(out)
    return img.size

if __name__ == "__main__":
    print(sheet(sys.argv[1], sys.argv[2:]))
