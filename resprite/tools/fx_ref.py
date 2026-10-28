"""A reference sheet for SpriteCook from effect strips: every frame of each strip in a grid, in
order, enlarged, on the game's dark floor colour (bright effects vanish on white).
python3 resprite/tools/fx_ref.py OUT.png COLS SCALE [--fill F] STRIP:FRAMES[@A-B][#FAMILY] [...]   ("-" leaves a cell empty)
@A-B: only frames A to B of the strip (a long strip over several sheets). #FAMILY: a shot sheet
(shot_*: the weapon families eight to a row, each its FRAMES frames), the family's frames only.
The biggest frame fills F of its cell (0.8 if not given). Nano Banana draws an effect sheet about
179 pixels across whatever the grid, so a frame comes back at about F x 179 / (COLS x biggest)
times today's size: pick COLS and F for the density wanted (1, or 2 for small effects)."""
import os, sys
from PIL import Image
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from inventory import G

DARK = (26, 20, 35, 255)    # 1a1423, the game's darkest colour

PER_ROW = 8                 # weapon families in a row of a shot sheet (ShotBatch.PER_ROW)

def frames(strip, n, family=None):
    im = Image.open(os.path.join(G, strip + ".png")).convert("RGBA")
    if family is None:
        w = im.width // n
        return [im.crop((i * w, 0, i * w + w, im.height)) for i in range(n)]
    w, h = im.width // (PER_ROW * n), im.height // 3
    r, c = divmod(family, PER_ROW)
    return [im.crop(((c * n + i) * w, r * h, (c * n + i + 1) * w, (r + 1) * h)) for i in range(n)]

def spec(s):
    """"fx_blast_l_fire:10@0-3" -> ("fx_blast_l_fire", 10, 0, 3, None); "shot_hex:4#2" -> (.., 2)."""
    name, n = s.rsplit(":", 1)
    a, b, fam = 0, 9999, None
    if "#" in n:
        n, fam = n.split("#")
        fam = int(fam)
    if "@" in n:
        n, r = n.split("@")
        a, b = (int(x) for x in r.split("-"))
    return name, int(n), a, min(b, int(n) - 1), fam

def layout(scale, specs, fill=0.8):
    """[(strip, frame number, frame) or None per cell], the side of a cell."""
    cells = []
    for s in specs:
        if s == "-":
            cells.append(None)
            continue
        name, n, a, b, fam = spec(s)
        key = name if fam is None else "%s#%d" % (name, fam)
        cells += [(key, i, f) for i, f in enumerate(frames(name, n, fam)) if a <= i <= b]
    big = max(max(c[2].width, c[2].height) for c in cells if c) * scale
    return cells, round(big / fill)

def args(a):
    """COLS SCALE [--fill F] SPECS... -> cols, scale, fill, specs."""
    fill = 0.8
    if a[2] == "--fill":
        fill = float(a[3])
        a = a[:2] + a[4:]
    return int(a[0]), int(a[1]), fill, a[2:]

def build(out, cols, scale, specs, fill=0.8):
    cells, cell = layout(scale, specs, fill)
    rows = (len(cells) + cols - 1) // cols
    sheet = Image.new("RGBA", (cols * cell, rows * cell), DARK)
    for i, c in enumerate(cells):
        if c is None:
            continue
        f = c[2]
        b = f.resize((f.width * scale, f.height * scale), Image.NEAREST)
        sheet.alpha_composite(b, ((i % cols) * cell + (cell - b.width) // 2, (i // cols) * cell + (cell - b.height) // 2))
    sheet.convert("RGB").save(out)
    return sheet.size, cell

if __name__ == "__main__":
    cols, scale, fill, specs = args(sys.argv[2:])
    print(build(sys.argv[1], cols, scale, specs, fill))
