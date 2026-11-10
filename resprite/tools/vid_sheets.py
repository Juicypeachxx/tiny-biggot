"""VID, THE HURIKAN SLAVE: the new floor guardian (his photos and his words, 23 Oct), V2 only.
    python3 resprite/tools/vid_sheets.py
- Four SpriteCook sheets (resprite/spritecook/sheets/bright_vid*.png, Nano Banana 2.1): his nine poses
  (2K, 18 credits); the same sheet edited into his metal form for stage 2 (2K, 18) and that edited
  into his full metal form for stage 3 (2K, 18); his props (12). The ids are in the manifest.
- Each cell is cut (sheet_cut.py) into resprite/spritecook/vid/, then fitted:
  - a pose at 0.88 of its size on the sheet (he stands as tall as Sefe), on a picture of even sides
    with his feet at the bottom and the middle of his feet in the middle, so he does not jump from
    pose to pose;
  - a prop into its own box (BOX).
  The fitted picture goes to resprite/hd (hd_import.py puts it in the game in the pixel look) and
  the same at half size to the game's own pictures (today's size: the game measures by it).
- Drawn here in code instead (DRAWN): the LED panel off and on, and the manga page. The pixel look
  smeared SpriteCook's: the panel's dot grid went flat and the page's frames grey. They are drawn
  at the game's pixels (each LED two of them) and go in as they are ("look": "pixel"). The plug the
  props sheet has is not used: a spark is drawn by the game.
- The manifest gets the three new sheets and a "made" picture for every cell."""
import json, os, sys
from PIL import Image
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from inventory import G, ROOT
from sheet_cut import cut
from spritecook_fit import HD, MANIFEST, down, sha12, trim

SHEETS = os.path.join(ROOT, "resprite", "spritecook", "sheets")
RAW = os.path.join(ROOT, "resprite", "spritecook", "vid")
POSES = ["vid", "vid_peace", "vid_lasso", "vid_panel", "vid_drink", "vid_nap", "vid_manga", "vid_spin", "vid_out"]
PROPS = ["vid_bottle", "-", "-", "-", "w_vidcable", "-", "-", "-", "-"]
BOX = { "vid_bottle": (26, 12), "w_vidcable": (24, 24) }
DRAWN = ["vid_led", "vid_led_on", "vid_page"]
K = 0.88
STYLE = "8e43ad1a-3a19-479b-89b7-89575ada6626"
SHEET_IDS = [
    ("bright_vid", POSES, "25167620-dabe-4f9a-a89f-cd26b8cab56d", "704649ab-fc46-4c6a-80c6-8e573e1e599e", 18, None),
    ("bright_vid_s2", [n + "_s2" for n in POSES], "0ee13a02-34e6-43db-9244-6fcf30784b68",
     "b3b9596e-9bb6-4543-a958-3329c85ca9be", 18, "his metal form for stage 2 (his word: \"for stage 2 and 3 he"
     " transforms in his metal form because he is metal head who watches alot of anime\"): an edit of bright_vid"),
    ("bright_vid_s3", [n + "_s3" for n in POSES], "071446fc-001c-4bcd-ab3f-aeeb3087f371",
     "faf0e26c-74e5-476d-91d1-c199eb87b84b", 18, "his full metal form for stage 3: an edit of bright_vid_s2"),
    ("bright_vid_props", PROPS, "840339d1-d57b-4095-b19b-aff66e25ef30", "30677544-6131-4bb1-87b0-39a9e2607651", 12,
     "his props: the bottle, an LED panel off and on, a manga page, his cable (his drop), a plug"),
]

def pose(raw):
    """At K, feet at the bottom, the middle of the feet in the middle."""
    w, h = max(1, round(raw.width * K)), max(1, round(raw.height * K))
    spr = down(raw, w, h)
    a = spr.getchannel("A").load()
    xs = [x for y in range(max(0, h - 12), h) for x in range(w) if a[x, y] >= 128]
    fx = sum(xs) / len(xs) if xs else w / 2
    half = int(max(fx, w - fx)) + 1
    W, H = 2 * half + (2 * half) % 2, h + h % 2
    out = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    out.alpha_composite(spr, (round(W / 2 - fx), H - h))
    return out

def prop(raw, box):
    k = min(box[0] / raw.width, box[1] / raw.height)
    w, h = max(1, round(raw.width * k)), max(1, round(raw.height * k))
    out = Image.new("RGBA", box, (0, 0, 0, 0))
    out.alpha_composite(down(raw, w, h), ((box[0] - w) // 2, (box[1] - h) // 2))
    return out

def _hex(h):
    return tuple(int(h[i:i + 2], 16) for i in (1, 3, 5)) + (255,)

def led(on):
    """An LED panel, 24 x 24: a steel frame, and inside it 5 x 5 LEDs of 2 x 2 (lit: cyan, white on
    the diagonal; off: dark)."""
    im = Image.new("RGBA", (24, 24), _hex("#16141c"))
    px = im.load()
    for i in range(24):
        for j in range(24):
            if not (1 <= i <= 22 and 1 <= j <= 22):
                continue
            if i in (1, 22) or j in (1, 22):
                px[i, j] = _hex("#6a7080" if i == 1 or j == 1 else "#3a3e4a")
            elif 2 <= i <= 21 and 2 <= j <= 21:
                px[i, j] = _hex("#0d2a33" if on else "#121418")
    for a in range(5):
        for b in range(5):
            c = ("#ffffff" if a == b or a + b == 4 else "#5ee8f5") if on else "#26323a"
            for dx in range(2):
                for dy in range(2):
                    px[3 + a * 4 + dx, 3 + b * 4 + dy] = _hex(c)
    return im

def page():
    """A manga page, 16 x 16: white paper with an outline and three frames."""
    im = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    px = im.load()
    for i in range(2, 14):
        for j in range(0, 16):
            px[i, j] = _hex("#16141c" if i in (2, 13) or j in (0, 15) else "#f4f1e8")
    for i in range(4, 12):
        for j in (2, 7, 8, 13):
            px[i, j] = _hex("#4a4858")
    for j in range(2, 14):
        if j not in (7, 8):
            px[4, j] = px[11, j] = _hex("#4a4858")
    for j in range(2, 8):
        px[8, j] = _hex("#4a4858")
    return im

def main():
    os.makedirs(RAW, exist_ok=True)
    made = []
    for n, im in (("vid_led", led(False)), ("vid_led_on", led(True)), ("vid_page", page())):
        im.save(os.path.join(HD, n + ".png"))
        down(im, im.width // 2, im.height // 2).save(os.path.join(G, n + ".png"))
    for sheet, cells, asset, job, credits, label in SHEET_IDS:
        report, extra = cut(os.path.join(SHEETS, sheet + ".png"), 3, 3, cells, out_dir=RAW)
        empty = [r[0] for r in report if r[0] != "-" and r[1] == 0]
        print(sheet, "empty:", empty or "none", "outside:", extra or "none")
        for i, n in enumerate(cells):
            if n == "-" or n in empty:
                continue
            raw = trim(Image.open(os.path.join(RAW, n + ".png")).convert("RGBA"))
            hd = prop(raw, BOX[n]) if n in BOX else pose(raw)
            hd.save(os.path.join(HD, n + ".png"))
            down(hd, hd.width // 2, hd.height // 2).save(os.path.join(G, n + ".png"))
            made.append((n, asset, i))
    with open(MANIFEST) as f:
        man = json.load(f)
    names = {m[0] for m in made} | set(DRAWN)
    sheets = {s[0] for s in SHEET_IDS}
    keep = [a for a in man["assets"] if not (a["kind"] == "made" and a.get("name") in names)
            and not (a["kind"] == "sheet" and a.get("name") in sheets and a.get("name") != "bright_vid")]
    for sheet, cells, asset, job, credits, label in SHEET_IDS[1:]:
        keep.append({"label": "VID, THE HURIKAN SLAVE: " + label + ", 23 Oct", "kind": "sheet", "name": sheet,
                     "asset_id": asset, "job_id": job, "style": [STYLE],
                     "model": "gemini-nano-banana-2.1" + (" 2K" if credits == 18 else ""), "credits": credits,
                     "cells": cells, "sha12": sha12(os.path.join(SHEETS, sheet + ".png"))})
    for n, asset, i in made:
        keep.append({"label": "%s, VID, THE HURIKAN SLAVE, cell %d" % (n, i), "kind": "made", "name": n,
                     "asset_id": asset, "sheet_cell": i, "model": "gemini-nano-banana-2.1", "credits": 0,
                     "sha12": sha12(os.path.join(RAW, n + ".png"))})
    for n in DRAWN:
        keep.append({"label": "%s, VID, THE HURIKAN SLAVE: drawn in code (vid_sheets.py)" % n, "kind": "made",
                     "name": n, "look": "pixel", "asset_id": None, "credits": 0, "sha12": sha12(os.path.join(HD, n + ".png"))})
    man["assets"] = keep
    with open(MANIFEST, "w") as f:
        json.dump(man, f, indent=1)
        f.write("\n")
    print(len(made), "pictures")

if __name__ == "__main__":
    main()
