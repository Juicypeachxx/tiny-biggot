"""The traits (464 pictures, tr_*) in his bright look (22 Oct): the reference sheets and the prompts
for SpriteCook, 36 to a 6 x 6 sheet, sorted by family.
python3 resprite/tools/trait_sheets.py [fix]   -> resprite/spritecook/refs/traits_tNN.png (fix: traits_tf2.png)
  and traits_plan.json
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
# The 18 that came back as something else (a piggy bank as a wolf, a glass cannon as a sword):
# drawn again on one sheet, each with plain words for what it shows ("fix").
FIX = {"tr_str_hammer": "a big hammer falling head first", "tr_str_irondiscipline": "a heavy iron weight on a short rope",
       "tr_o_engineer": "a little gun turret on two legs", "tr_shrapnel": "a bomb bursting, sharp fragments flying out",
       "tr_e_cascade": "a chain of sparks jumping in a diagonal line", "tr_e_overcrit": "two stars side by side",
       "tr_g_invest": "a piggy bank", "tr_n_coinflip": "a coin flipping in the air",
       "tr_int_iceconj": "three ice shards flying down", "tr_y_frostwake": "a snowflake over two wavy lines of frost",
       "tr_j_brawler": "a clenched fist", "tr_x_glass": "a little cannon made of glass",
       "tr_y_dreadlord": "a wide low crown of sharp spikes", "tr_int_staticblows": "a block crackling with static, sparks below",
       "tr_n_sparkplug": "a spark plug with a little spark", "tr_q_sharkweek": "a shark fin above water",
       "tr_q_longshadow": "a little standing figure with a long shadow", "tr_n_forked": "a snake's head with its forked tongue out"}

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

def fix():
    """One sheet for FIX, in today's places, with the words of each, twice: rows 4 to 6 are a second
    try of rows 1 to 3, and the better of the two is kept. (A first sheet with each once, tf1, came
    back with its top row cut off and the pictures in grey metal.)"""
    cells = list(FIX) * 2
    n = len(FIX)
    ref = os.path.join(ROOT, "resprite", "spritecook", "refs", "traits_tf2.png")
    fx_ref.build(ref, COLS, SCALE, [c + ":1" for c in cells], FILL)
    lines = []
    for r in range(n // COLS):
        row = [FIX[c] for c in cells[r * COLS:r * COLS + COLS]]
        lines.append(("Rows %d and %d, left to right: " if r == 0 else "Rows %d and %d: ") % (r + 1, r + 4) + "; ".join(row) + ".")
    prompt = ("A sprite sheet of %d little white symbol icons in a %d by %d grid, redrawn from the reference sheet:"
              " rows 4 to 6 are a second try of rows 1 to 3. Every one stays in its own place in the grid, keeps"
              " the size and outline of the reference and shows what the words say. " % (2 * n, COLS, COLS)) + \
        " ".join(lines) + \
        " The words are only to tell you what each one is: never write any names, words or letters in the picture." \
        " Each a clean pixel art symbol in pure white like the reference, with soft light grey shading, a few" \
        " darker grey lines and a thin dark outline: white and greys only, no other colours, not grey metal, in" \
        " the clean look of the style guide, with clear empty space between them. No text, no labels, no captions," \
        " no background."
    return {"tf2": {"cells": cells, "ref": os.path.relpath(ref, ROOT), "prompt": prompt}}

def main():
    if sys.argv[1:] == ["fix"]:
        save(fix())
        print(len(FIX), "traits on the fix sheet")
        return
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
    save(out)
    print(len(names), "traits in", len(out), "sheets")

def save(out):
    path = os.path.join(ROOT, "resprite", "spritecook", "refs", "traits_plan.json")
    done = json.load(open(path)) if os.path.exists(path) else {}   # keeps the SpriteCook ids of sheets made
    for k, v in out.items():
        done.setdefault(k, {}).update(v)
    with open(path, "w") as f:
        json.dump(done, f, indent=1)
        f.write("\n")

if __name__ == "__main__":
    main()
