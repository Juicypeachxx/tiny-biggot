"""The traits (464 pictures, tr_*) in his bright look (22 Oct): the reference sheets and the prompts
for SpriteCook, 36 to a 6 x 6 sheet, sorted by family.
python3 resprite/tools/trait_sheets.py   -> resprite/spritecook/refs/traits_tNN.png and traits_plan.json
- Today each trait picture is one flat white shape, and the game paints it in its family's colour
  (trait_view.gd, cube). So the new ones are white shapes with grey shading: the prompt asks for
  white and greys, and tools/trait_fit.py turns what comes back to greys, its lightest pixel
  white, so the game's colour still shows at full strength.
- The reference is on the game's dark colour (tools/fx_ref.py): white shapes vanish on white."""
import json, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from inventory import G, ROOT
import fx_ref

COLS, SCALE, FILL = 6, 7, 0.8
DATA = os.path.join(ROOT, "tiny_biggot_godot", "scripts", "data")

def families():
    """{picture: family} from the rows of traits.gd: [id, family, ...]."""
    out = {}
    for line in open(os.path.join(DATA, "traits.gd")):
        s = line.strip().rstrip(",")
        if s.startswith('["'):
            try:
                r = json.loads(s)
            except ValueError:
                continue
            if len(r) >= 4 and isinstance(r[1], str):
                out.setdefault("tr_" + r[0], r[1])
    return out

def main():
    fam = families()
    names = sorted(f[:-4] for f in os.listdir(G) if f.startswith("tr_") and f.endswith(".png"))
    names.sort(key=lambda n: (fam.get(n, "~"), n))         # the few without a row go last
    out = {}
    per = COLS * COLS
    for idx in range(0, len(names), per):
        cells = names[idx:idx + per]
        key = "t%02d" % (idx // per + 1)
        n = len(cells)
        cells = cells + ["-"] * (per - n)
        ref = os.path.join(ROOT, "resprite", "spritecook", "refs", "traits_%s.png" % key)
        fx_ref.build(ref, COLS, SCALE, [c if c == "-" else c + ":1" for c in cells], FILL)
        prompt = ("A sprite sheet of %d different little white symbol icons in a %d by %d grid, redrawn from the"
                  " reference sheet" % (n, COLS, COLS)) + \
            ("" if n == per else "; only the first %d places are used and the rest stay empty" % n) + \
            ". Every one stays in its own place in the grid and keeps its exact shape, as in the reference." \
            " Each a clean pixel art symbol in white, with soft light grey shading, a few darker grey lines" \
            " and a thin dark outline: white and greys only, no other colours, in the clean look of the style" \
            " guide, with clear empty space between them. Never write any letters or words. No text, no" \
            " labels, no captions, no background."
        out[key] = {"cells": cells, "ref": os.path.relpath(ref, ROOT), "prompt": prompt}
    path = os.path.join(ROOT, "resprite", "spritecook", "refs", "traits_plan.json")
    done = json.load(open(path)) if os.path.exists(path) else {}   # keeps the SpriteCook ids of sheets made
    for k, v in out.items():
        done.setdefault(k, {}).update(v)
    with open(path, "w") as f:
        json.dump(done, f, indent=1)
        f.write("\n")
    print(len(names), "traits in", len(out), "sheets")

if __name__ == "__main__":
    main()
