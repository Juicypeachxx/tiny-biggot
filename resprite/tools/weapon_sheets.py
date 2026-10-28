"""The weapons (396 pictures, w_*) in his bright look (22 Oct): the reference sheets and the prompts
for SpriteCook, 36 to a 6 x 6 sheet, sorted by kind (the swords together, the staffs together).
python3 resprite/tools/weapon_sheets.py   -> resprite/spritecook/refs/weapons_wNN.png and weapons_plan.json
- Each one is named in the prompt by its name in the game and its kind ("hunting bow", "acid jar
  (potion flask)"), from the rows of scripts/data/weapons.gd.
- The game turns a held weapon round its centre (world_view.gd, _draw_weapon), from the way
  today's picture points (a sword up and to the right, a gun to the right), so the prompt asks
  every one to point the way it does in the reference.
- 14 magic staffs are mostly a soft glow (half see-through): the new drawing goes over today's glow
  (weapon_glow.py), so the inventory's 382 count leaves them out but this list has them."""
import json, os, re, subprocess, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from inventory import G, ROOT

COLS = 6
# The kind in plain words, where the game's word is not one.
KIND = {"orbstaff": "staff with an orb", "flaskw": "potion flask", "lanternw": "lantern", "orb": "magic orb",
        "rune": "rune stone", "handcannon": "hand cannon", "skullstaff": "skull staff", "launcher": "rocket launcher",
        "fists": "knuckle dusters", "tome": "spell book", "cards": "playing cards", "minetrap": "mine",
        "repeater": "repeating crossbow", "disc": "throwing disc", "kit": "tool kit", "sticks": "drum sticks",
        "toy": "toy", "coil": "tesla coil", "beacon": "beacon", "totem": "totem", "sprayer": "sprayer"}
# Pictures no row names (their weapons are made elsewhere): their kind from the name.
EXTRA = {"w_bonecenser": ("BONE CENSER", "lanternw"), "w_glacierheart": ("GLACIER HEART", "orbstaff"),
         "w_quickcrossbow": ("QUICK CROSSBOW", "crossbow"), "w_tankardmaul": ("TANKARD MAUL", "maul"),
         "w_thoughtstone": ("THOUGHT STONE", "orbstaff")}

def rows():
    """{sprite: (NAME, kind)} from weapons.gd: [id, NAME, attack, rarity, families, kind, ...(, sprite)]."""
    out = {}
    for line in open(os.path.join(ROOT, "tiny_biggot_godot", "scripts", "data", "weapons.gd")):
        s = line.strip().rstrip(",")
        if not s.startswith('["'):
            continue
        try:
            r = json.loads(s)
        except ValueError:
            continue
        if len(r) >= 6 and isinstance(r[1], str) and isinstance(r[5], str):
            sp = r[11] if len(r) > 11 and isinstance(r[11], str) else "w_" + r[0]
            out.setdefault(sp, (r[1], r[5]))
    return out

def hint(name, kind):
    n = name.lower().replace("'", "")
    k = KIND.get(kind, kind)
    return n if k.split()[-1] in n else "%s (%s)" % (n, k)

def main():
    known = rows()
    known.update(EXTRA)
    names = sorted(f[:-4] for f in os.listdir(G) if f.startswith("w_") and f.endswith(".png"))
    missing = [n for n in names if n not in known]
    assert not missing, missing
    names.sort(key=lambda n: (known[n][1], n))
    out = {}
    per = COLS * COLS
    for idx in range(0, len(names), per):
        cells = names[idx:idx + per]
        key = "w%02d" % (idx // per + 1)
        n = len(cells)
        cells = cells + ["-"] * (per - n)
        ref = os.path.join(ROOT, "resprite", "spritecook", "refs", "weapons_%s.png" % key)
        subprocess.run(["python3", os.path.join(ROOT, "resprite", "tools", "sheet_ref.py"), ref, str(COLS)] + cells,
                       check=True, capture_output=True)
        lines = []
        for r in range(COLS):
            row = [hint(*known[c]) for c in cells[r * COLS:r * COLS + COLS] if c != "-"]
            if row:
                lines.append(("Row %d, left to right: " if r == 0 else "Row %d: ") % (r + 1) + "; ".join(row) + ".")
        lead = ("A sprite sheet of %d different little weapon icons in a %d by %d grid, redrawn from the reference sheet"
                % (n, COLS, COLS)) + ("" if n == per else "; only the first %d places are used and the rest stay empty" % n) + \
            ". Every one stays in its own place in the grid and keeps its shape, its colours and the way it points, " \
            "as in the reference. "
        tail = " Each a clean, bright, colourful pixel art game item in exactly the look of the style guide, with clear" \
            " empty space between them. No text, no labels, no frames, no background, no hands."
        out[key] = {"cells": cells, "ref": os.path.relpath(ref, ROOT), "prompt": lead + " ".join(lines) + tail}
    path = os.path.join(ROOT, "resprite", "spritecook", "refs", "weapons_plan.json")
    done = json.load(open(path)) if os.path.exists(path) else {}   # keeps the SpriteCook ids of sheets made
    for k, v in out.items():
        done.setdefault(k, {}).update(v)
    with open(path, "w") as f:
        json.dump(done, f, indent=1)
        f.write("\n")
    print(len(names), "weapons in", len(out), "sheets")

if __name__ == "__main__":
    main()
