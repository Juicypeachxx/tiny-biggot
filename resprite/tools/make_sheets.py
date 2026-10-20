"""Makes the sheets Gemini redraws (his test, 20 Oct: "make me the file so gemini could resprite
the game"). Every sheet is 1024 x 1024: a grey board with a grid of cells; in each cell one game
picture, enlarged with square pixels, on its own pink box (#FF00FF) the size of the picture.
Gemini redraws inside the pink boxes; import_sheets.py reads them back by the same plan
(sheets/plan.json). Run from anywhere: python3 resprite/tools/make_sheets.py"""
import json, os, sys
from PIL import Image
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from inventory import plan, size, G, ROOT

OUT = os.path.join(ROOT, "resprite", "sheets")
SIDE = 1024
PAD = 12                        # grey around every pink box, inside its cell
PINK = (255, 0, 255, 255)
GREY = (42, 42, 42, 255)
LINE = (20, 20, 20, 255)
ORDER = ["heroes", "foes", "guardians", "people and pets", "room things", "weapons", "gear", "relics",
         "traits", "other items and icons"]
CHARACTERS = {"heroes", "foes", "guardians", "people and pets"}
TRY = ["hexer", "brute", "gaolbird", "skeleton", "bat", "slime", "colossus", "w_hexwand", "relic_luckycoin"]

def classes_of(group, names):
    """Pictures of a group by size (the biggest first), each class with its grid: n x n cells.
    A class of fewer than 4 joins the next bigger one, so no sheet is nearly empty."""
    ch = group in CHARACTERS
    bounds = [(24, 6), (64, 3)] if ch else [(16, 8), (32, 5), (64, 3)]
    out = []
    for lim, n in bounds:
        lst = [x for x in names if max(size(x)) <= lim and x not in sum((c[0] for c in out), [])]
        out.append([lst, n])
    for i in range(len(out) - 1):
        if 0 < len(out[i][0]) < 4:
            out[i + 1][0] = out[i][0] + out[i + 1][0]
            out[i][0] = []
    if len(out) > 1 and 0 < len(out[-1][0]) < 4:   # the last class too small: into the one before it
        for i in range(len(out) - 2, -1, -1):
            if out[i][0]:
                out[i][0] += out[-1][0]
                out[-1][0] = []
                out[i][1] = out[-1][1] if max(max(size(x)) for x in out[i][0]) > bounds[i][0] else out[i][1]
                break
    return [(sorted(lst, key=lambda x: (max(size(x)), x)), n) for lst, n in out if lst]

def slug(s):
    return s.replace(" ", "-")

def sheet(file, names, n, plan_out, note):
    cell = SIDE // n
    big = max(max(size(x)) for x in names)
    scale = max(1, min(12, (cell - 2 * PAD) // big))
    img = Image.new("RGBA", (SIDE, SIDE), GREY)
    px = img.load()
    for k in range(1, n):   # the grid
        for t in range(SIDE):
            for d in (-1, 0):
                px[k * cell + d, t] = LINE
                px[t, k * cell + d] = LINE
    entries = []
    for i, name in enumerate(names):
        w, h = size(name)
        cx, cy = (i % n) * cell, (i // n) * cell
        bw, bh = w * scale, h * scale
        bx, by = cx + (cell - bw) // 2, cy + (cell - bh) // 2
        box = Image.new("RGBA", (bw, bh), PINK)
        spr = Image.open(os.path.join(G, name + ".png")).convert("RGBA")
        spr.putalpha(spr.getchannel("A").point(lambda a: 255 if a >= 128 else 0))   # (solid or clear, no pink halos)
        spr = spr.resize((bw, bh), Image.NEAREST)
        box.alpha_composite(spr)
        img.alpha_composite(box, (bx, by))
        entries.append({"name": name, "w": w, "h": h, "box": [bx, by, bw, bh]})
    img.convert("RGB").save(os.path.join(OUT, file))
    plan_out.append({"file": file, "side": SIDE, "cells": n, "scale": scale, "what": note, "pictures": entries})

def main():
    os.makedirs(OUT, exist_ok=True)
    for f in os.listdir(OUT):
        if f.endswith(".png"):
            os.remove(os.path.join(OUT, f))
    groups, made, skipped = plan()
    out = []
    try_names = [t for t in TRY if os.path.exists(os.path.join(G, t + ".png"))]
    sheet("00-try-me-first.png", try_names, 3, out, "a few of everything, to test the style first")
    k = 1
    for g in ORDER:
        names = groups.get(g, [])
        for lst, n in classes_of(g, names):
            cap = n * n
            m = -(-len(lst) // cap)              # sheets for this class
            per = -(-len(lst) // m)              # the same number on each
            for j in range(0, len(lst), per):
                sheet("%02d-%s.png" % (k, slug(g)), lst[j:j + per], n, out, g)
                k += 1
    json.dump({"made_again": made, "kept": skipped, "sheets": out}, open(os.path.join(OUT, "plan.json"), "w"), indent=1)
    print("%d sheets, %d pictures (and the try sheet), %d made again by the import, %d kept" % (
        len(out) - 1, sum(len(s["pictures"]) for s in out[1:]), len(made), len(skipped)))
    for s in out:
        print("  %-34s %3d pictures, each game pixel %d x %d" % (s["file"], len(s["pictures"]), s["scale"], s["scale"]))

if __name__ == "__main__":
    main()
