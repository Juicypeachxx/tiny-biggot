"""Review sheet for the floor sets: today's floor and walls (left) and the new look (right), the same
patch of room at the same size on screen, with each place's name.
python3 resprite/tools/floor_review.py OUT.png KIT [KIT...]"""
import json, os, re, sys
from PIL import Image, ImageDraw
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from inventory import G, ROOT
from spritecook_fit import HD

BG = (34, 30, 40, 255)
PW, PH = 96, 64          # the patch of room shown, in game pixels
UNIT = 2                 # on screen: game pixels x2 (the new pictures are already at x2)

def places():
    src = open(os.path.join(ROOT, "tiny_biggot_godot", "scripts", "data", "themes.gd")).read()
    return {k: n.title() for n, k in re.findall(r'"name": "([^"]+)"[^}]{0,200}?"kit": "(kit[0-9a-z_]+)"', src)}

def tiled(tex, w, h):
    out = Image.new("RGBA", (w, h))
    for y in range(0, h, tex.height):
        for x in range(0, w, tex.width):
            out.alpha_composite(tex, (x, y))
    return out

def sheet(out, kits, per_row=4):
    names = places()
    with open(os.path.join(ROOT, "resprite", "spritecook-assets.json")) as f:
        what = {a["name"]: a["label"].split(": ", 1)[1].rsplit(",", 1)[0]
                for a in json.load(f)["assets"] if a["kind"] == "floor"}
    pw, ph = PW * UNIT, PH * UNIT
    cw, ch = pw * 2 + 30, ph + 16 * UNIT + 40
    rows = (len(kits) + per_row - 1) // per_row
    img = Image.new("RGBA", (per_row * cw + 10, rows * ch + 10), BG)
    d = ImageDraw.Draw(img)
    for i, k in enumerate(kits):
        x = 10 + (i % per_row) * cw
        y = 10 + (i // per_row) * ch
        old = Image.open(os.path.join(G, k + ".png")).convert("RGBA")
        cols = old.width // 16
        floor = Image.new("RGBA", (PW, PH))                     # today: the floor tiles as the game mixes them
        for ty in range(PH // 16):
            for tx in range(PW // 16):
                v = ((tx * 7 + ty * 13) % (cols // 2)) * 2 + (tx + ty) % 2
                floor.paste(old.crop((v * 16, 0, v * 16 + 16, 16)), (tx * 16, ty * 16))
        img.alpha_composite(floor.resize((pw, ph), Image.NEAREST), (x, y))
        walls = old.crop((0, 16, 96, 32)).resize((96 * UNIT, 16 * UNIT), Image.NEAREST)
        img.alpha_composite(walls, (x, y + ph + 2))
        new = Image.open(os.path.join(HD, k + "_floor.png")).convert("RGBA")
        img.alpha_composite(tiled(new, pw, ph), (x + pw + 12, y))
        hd = Image.open(os.path.join(HD, k + ".png")).convert("RGBA")
        img.alpha_composite(hd.crop((0, 32, 192, 64)), (x + pw + 12, y + ph + 2))
        label = names.get(k, k)
        d.text((x, y + ph + 16 * UNIT + 6), label, fill=(230, 220, 190, 255))
        d.text((x, y + ph + 16 * UNIT + 20), what.get(k, "")[:60], fill=(160, 150, 135, 255))
    img.convert("RGB").save(out)
    return img.size

if __name__ == "__main__":
    print(sheet(sys.argv[1], sys.argv[2:]))
