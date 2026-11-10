"""Stage review sheets: each guardian or champion in the new look at stage 1, 2 and 3 side by side,
at the size the game shows them (today's picture's size times UNIT), with its name.
python3 resprite/tools/stage_review.py OUT.png NAME [NAME...]"""
import os, sys
from PIL import Image, ImageDraw
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from inventory import G
from review import HD, BG

UNIT = 4

def shown(name):
    old = Image.open(os.path.join(G, name + ".png"))
    new = Image.open(os.path.join(HD, name + ".png")).convert("RGBA")
    f = UNIT * old.width / new.width                      # new pixels per screen pixel, whatever the density
    return new.resize((round(new.width * f), round(new.height * f)), Image.NEAREST)

def sheet(out, names, per_row=4):
    groups = [[shown(n + s) for s in ("", "_s2", "_s3")] for n in names]
    cw = max(sum(p.width for p in g) + 24 for g in groups)
    ch = max(max(p.height for p in g) for g in groups) + 22
    rows = (len(groups) + per_row - 1) // per_row
    img = Image.new("RGBA", (per_row * (cw + 16) + 10, rows * ch + 10), BG)
    d = ImageDraw.Draw(img)
    for i, (n, g) in enumerate(zip(names, groups)):
        x = 10 + (i % per_row) * (cw + 16)
        y = 10 + (i // per_row) * ch
        for p in g:
            img.alpha_composite(p, (x, y + ch - 22 - p.height))
            x += p.width + 12
        d.text((10 + (i % per_row) * (cw + 16), y + ch - 18), n + "  (1, 2, 3)", fill=(200, 190, 170, 255))
    img.convert("RGB").save(out)
    return img.size

if __name__ == "__main__":
    print(sheet(sys.argv[1], sys.argv[2:]))
