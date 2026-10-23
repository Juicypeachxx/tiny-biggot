"""The items drawn again as chunky pixel art (his pick, 23 Oct: "Test 2 for all items", after
"this in my opinion does not look good, you have some credits left if you find anything like
this resprite it"): the 59.2 designs, chunkier, with a bold outline and flat bright colours.
    python3 resprite/tools/pixel_sheets.py ref GROUP KEY
        -> resprite/spritecook/refs2/<group>_<key>_new.png and _prompt.txt
    python3 resprite/tools/pixel_sheets.py add GROUP KEY ASSET_ID JOB_ID REFERENCE_ID [ROWS SKIP]
        (the sheet downloaded to resprite/spritecook/sheets/pixel_<key>.png first; ROWS and SKIP
        for a sheet that came back short: i02 drew rows 2 to 6 only, so "5 6")
GROUP is weapons, gear, relics or icons; KEY a sheet of its plan (refs/<group>_plan.json).
- The reference: the sheet's pictures as they are in 59.2 (resprite/hd), x4 in the same 6 x 6
  grid. The style guide: the game's own pictures before V2 (spritecook/style-old.png, asset
  e6c03a1e-168d-461e-88ed-ab83464147f5). NB 2.1, 12 credits a sheet.
- The prompt is the plan's (the names, row by row) with the look asked for: pixel art about as
  many pixels across as the game's picture at double size.
- SpriteCook gives the sheet back at its own pixels (about 32 to a cell). Each cut drawing goes
  into resprite/hd/<name>.png as it is where it fits (pixel art shrunk by an odd amount loses its
  pixels), centred where today's picture is drawn (a held weapon turns round that); one bigger
  than the picture is shrunk (spritecook_fit.down). The glow some staffs had under them is not
  kept: it was the square he pointed at.
- The manifest gets the sheet and a "made" picture per cell with "look": "pixel" (hd_import.py
  puts those in as they are); the 59.2 drawing of each becomes an "alternative"."""
import json, os, statistics, sys
from PIL import Image
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from inventory import G, ROOT
from sheet_cut import cut
from spritecook_fit import HD, MANIFEST, down, sha12, trim

REFS = os.path.join(ROOT, "resprite", "spritecook", "refs")
REFS2 = os.path.join(ROOT, "resprite", "spritecook", "refs2")
SHEETS = os.path.join(ROOT, "resprite", "spritecook", "sheets")
RAW = os.path.join(ROOT, "resprite", "spritecook", "pixel")
STYLE = "e6c03a1e-168d-461e-88ed-ab83464147f5"
COLS, CELL = 6, 128
TAIL = ("The words are only to tell you what each one is: never write any names, words or letters in"
        " the picture. Draw each one as pixel art about %d pixels across, in the hand-made look of the"
        " style guide: big square pixels, a bold near-black outline all round, flat bright saturated"
        " colours with one shadow tone and one highlight per colour, simple bold readable shapes, no"
        " soft shading, no gradients, no noise, no anti-aliasing. Clear empty space between them. No"
        " text, no labels, no captions, no background.")

def plan(group, key):
    return json.load(open(os.path.join(REFS, "%s_plan.json" % group)))[key]

def across(cells):
    """How many pixels across a drawing should be: today's pictures at double size, the middle one."""
    return int(statistics.median(max(Image.open(os.path.join(G, n + ".png")).size) * 2 for n in cells if n != "-"))

def ref(group, key):
    p = plan(group, key)
    cells = p["cells"]
    ims = {n: Image.open(os.path.join(HD, n + ".png")).convert("RGBA") for n in cells if n != "-"}
    k = max(1, min(4, (CELL - 16) // max(max(i.size) for i in ims.values())))
    sheet = Image.new("RGBA", (COLS * CELL, COLS * CELL), (0, 0, 0, 0))
    for i, n in enumerate(cells):
        if n == "-":
            continue
        im = ims[n].resize((ims[n].width * k, ims[n].height * k), Image.NEAREST)
        sheet.alpha_composite(im, ((i % COLS) * CELL + (CELL - im.width) // 2, (i // COLS) * CELL + (CELL - im.height) // 2))
    os.makedirs(REFS2, exist_ok=True)
    out = os.path.join(REFS2, "%s_%s_new.png" % (group, key))
    sheet.save(out)
    lead = p["prompt"].split(" Each a clean")[0].split(" The words are only")[0]    # the names, row by row
    lead = lead.replace("keeps its shape, its colours", "keeps its design, its parts, its colours")
    prompt = lead + " " + TAIL % across(cells) + (" No hands, no frames." if group == "weapons" else "")
    open(os.path.join(REFS2, "%s_%s_prompt.txt" % (group, key)), "w").write(prompt + "\n")
    print(out, os.path.getsize(out), "bytes; prompt in", "%s_%s_prompt.txt" % (group, key))

def place(name):
    """The cut drawing into today's picture at double size, centred where today's is drawn."""
    old = Image.open(os.path.join(G, name + ".png")).convert("RGBA")
    x0, y0, x1, y1 = old.getchannel("A").point(lambda v: 255 if v >= 128 else 0).getbbox()
    spr = trim(Image.open(os.path.join(RAW, name + ".png")).convert("RGBA"))
    W, H = old.width * 2, old.height * 2
    if spr.width > W or spr.height > H:
        k = min(W / spr.width, H / spr.height)
        spr = down(spr, max(1, round(spr.width * k)), max(1, round(spr.height * k)))
    out = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    x = min(max(0, round(x0 + x1 - spr.width / 2)), W - spr.width)
    y = min(max(0, round(y0 + y1 - spr.height / 2)), H - spr.height)
    out.alpha_composite(spr, (x, y))
    out.save(os.path.join(HD, name + ".png"))

def add(group, key, asset_id, job_id, reference, rows=COLS, skip=0):
    cells = plan(group, key)["cells"][skip:skip + rows * COLS]
    sheet = "pixel_%s" % key
    path = os.path.join(SHEETS, sheet + ".png")
    os.makedirs(RAW, exist_ok=True)
    report, extra = cut(path, COLS, rows, cells, out_dir=RAW)
    names = [n for n in cells if n != "-"]
    with open(MANIFEST) as f:
        man = json.load(f)
    keep = []
    for a in man["assets"]:
        if a["kind"] == "sheet" and a.get("name") == sheet:
            continue
        if a["kind"] == "made" and a.get("name") in names:
            a = dict(a, kind="alternative", label=a["label"] + " (the 59.2 look; drawn again as chunky pixel art, 23 Oct)")
        keep.append(a)
    keep.append({"label": "%s sheet %s as chunky pixel art (his pick, test 2), 23 Oct" % (group, key), "kind": "sheet",
                 "name": sheet, "asset_id": asset_id, "job_id": job_id, "reference": reference, "style": STYLE,
                 "model": "gemini-nano-banana-2.1", "credits": 12, "cells": cells, "sha12": sha12(path)})
    for i, n in enumerate(cells):
        if n != "-":
            keep.append({"label": "%s, from sheet %s cell %d" % (n, sheet, i), "kind": "made", "name": n, "look": "pixel",
                         "asset_id": asset_id, "sheet_cell": i, "model": "gemini-nano-banana-2.1", "credits": 0,
                         "sha12": sha12(os.path.join(RAW, n + ".png")) if os.path.exists(os.path.join(RAW, n + ".png")) else None})
    man["assets"] = keep
    with open(MANIFEST, "w") as f:
        json.dump(man, f, indent=1)
        f.write("\n")
    empty = [r[0] for r in report if r[0] != "-" and r[1] == 0]
    for n in names:
        if n not in empty:
            place(n)
    print("%s: %d placed; empty cells: %s; pieces outside the grid: %s" % (sheet, len(names) - len(empty), empty or "none", extra or "none"))

if __name__ == "__main__":
    a = sys.argv[1:]
    if a[0] == "ref":
        ref(a[1], a[2])
    elif a[0] == "add":
        add(a[1], a[2], a[3], a[4], a[5], *(int(v) for v in a[6:8]))
