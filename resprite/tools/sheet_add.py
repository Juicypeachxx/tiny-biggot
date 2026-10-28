"""A SpriteCook sheet into the game's pictures in one go: the sheet goes into the manifest, it is cut
(sheet_cut.py), each cell becomes the "made" picture of its name (an older "made" one of that name is
dropped: the gritty ones are kept as "alternative") and is fitted (spritecook_fit.py).
python3 resprite/tools/sheet_add.py SHEET ASSET_ID JOB_ID REFERENCE MODEL CREDITS COLSxROWS LABEL NAME...
SHEET is resprite/spritecook/sheets/<SHEET>.png, already downloaded; "-" skips a cell."""
import json, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sheet_cut import cut
from spritecook_fit import MANIFEST, ROOT, main as fit_all, sha12

def add(sheet, asset_id, job_id, ref, model, credits, grid, label, names):
    cols, rows = (int(v) for v in grid.split("x"))
    path = os.path.join(ROOT, "resprite", "spritecook", "sheets", sheet + ".png")
    report, extra = cut(path, cols, rows, names)
    with open(MANIFEST) as f:
        man = json.load(f)
    keep = [a for a in man["assets"] if not (a["kind"] == "made" and a.get("name") in names)
            and not (a["kind"] == "sheet" and a.get("name") == sheet)]
    keep.append({"label": label, "kind": "sheet", "name": sheet, "asset_id": asset_id, "job_id": job_id,
                 "reference": ref, "model": model, "credits": credits, "cells": names, "sha12": sha12(path)})
    for i, n in enumerate(names):
        if n != "-":
            keep.append({"label": "%s, from sheet %s cell %d" % (n, sheet, i), "kind": "made", "name": n,
                         "asset_id": asset_id, "sheet_cell": i, "model": model, "credits": 0, "sha12": None})
    man["assets"] = keep
    with open(MANIFEST, "w") as f:
        json.dump(man, f, indent=1)
        f.write("\n")
    fit_all([n for n in names if n != "-"])
    return report, extra

if __name__ == "__main__":
    a = sys.argv[1:]
    print(add(a[0], a[1], a[2], a[3], a[4], int(a[5]), a[6], a[7], a[8:]))
