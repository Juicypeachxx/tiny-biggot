"""The items in his bright look (22 Oct, his "ok" to all the rest): the reference sheets and the
prompts for SpriteCook, 36 to a 6 x 6 sheet, a group at a time, sorted by kind.
python3 resprite/tools/item_sheets.py GROUP   (gear, relics or icons)
-> resprite/spritecook/refs/<group>_NN.png and <group>_plan.json
- gear: every g_* and o_* picture (helms, armour, boots, gloves, amulets, rings, charms and the
  offhands), each named by its name in the game and its kind (the rows of gear.gd).
- relics: every relic_* picture, by its name (relics.gd).
- icons: the other little pictures (food, drinks, fish, charms, infusions, keys, coins, dice, map
  icons, hearts, frames), by a few plain words.
- The weapon sheets showed that names invite captions under the drawings, so every prompt asks
  never to write them (tools/strip_labels.py takes them away when it does anyway).
Then: tools/sheet_add.py cuts a sheet, tools/weapon_fit.py fits each one into today's outline."""
import json, os, subprocess, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from inventory import G, ROOT, plan

COLS = 6
DATA = os.path.join(ROOT, "tiny_biggot_godot", "scripts", "data")
# Gear kinds in plain words, where the game's word is not one.
GEAR_KIND = {"plate": "plate armour", "leather": "leather armour", "greaves": "armoured boots",
             "offhand": "", "charm": "charm"}
# Pictures of the "other items and icons" group that belong to a character (another frame or pose
# of a foe, a guardian's part): made to match their new character, not here.
ODD = {"bat2", "believer_flex", "hydrahead", "hydraneck", "bullet_saint"}

def _rows(path):
    for line in open(path):
        s = line.strip().rstrip(",")
        if s.startswith('["'):
            try:
                yield json.loads(s)
            except ValueError:
                pass

def gear():
    """{sprite: (words, kind)}: [id, NAME, slot, rarity, tags, set, shape, ...(, sprite)]."""
    out = {}
    for r in _rows(os.path.join(DATA, "gear.gd")):
        if len(r) >= 7 and isinstance(r[1], str) and isinstance(r[6], str):
            sp = r[11] if len(r) > 11 and isinstance(r[11], str) else "g_" + r[0]
            n = r[1].lower().replace("'", "")
            k = GEAR_KIND.get(r[6], r[6])
            out.setdefault(sp, (n if not k or k.split()[-1] in n else "%s (%s)" % (n, k), r[6]))
    out.setdefault("g_shelversarm", ("shelvers arm (gloves)", "gloves"))
    return out

def relics():
    """{sprite: (words, kind)}: [id, rarity, NAME, desc, effects(, tags, sprite)]."""
    out = {}
    for r in _rows(os.path.join(DATA, "relics.gd")):
        if len(r) >= 4 and isinstance(r[2], str):
            sp = r[6] if len(r) > 6 and isinstance(r[6], str) else "relic_" + r[0]
            out.setdefault(sp, (r[2].lower().replace("'", ""), ""))
    return out

ICON_WORDS = {
    "armor": "a little armour shield", "bolt": "a crossbow bolt", "bomb": "a round bomb", "brick": "a brick",
    "card_back": "a playing card face down", "card_front": "a playing card face up", "coin": "a gold coin",
    "curse_mark": "a curse mark", "dynastick": "a stick of dynamite", "ember": "a glowing ember",
    "familiar": "a little spirit familiar", "feather": "a feather", "frog": "a frog", "gem": "a gem",
    "gourd": "a gourd flask", "hatchet": "a little hatchet", "heartPick": "a red heart", "key": "a key",
    "lock": "a padlock", "magazine": "an ammo magazine", "potion": "a red potion", "tome": "a book",
    "tornpage": "a torn page", "fish_oldboot": "an old boot", "fish_soddenscroll": "a wet scroll",
    "fish_oldone": "an old deep sea fish", "rb_anchor": "an anchor", "rb_bell": "a bell",
}
ICON_PREFIX = {"al": "a %s alignment badge", "c": "a drink: %s", "ch": "a %s charm", "d": "a %s draught bottle",
               "die": "a die: %s", "drink": "a little %s bottle", "f": "food: %s", "fish": "a fish: %s",
               "fp": "a %s", "frame": "a square %s frame", "gf": "golden food: %s", "heart": "a %s heart",
               "icon": "a %s map icon", "inf": "a little jar: %s", "mi": "a tiny %s stat icon"}

def icons():
    """{sprite: (words, kind)}, from the picture's name."""
    g, _, _ = plan()
    out = {}
    for n in g["other items and icons"]:
        if n in ODD or n.startswith(("orb_", "orbr_")):          # the foes' shots: done with the effects
            continue
        pre, rest = n.split("_", 1) if "_" in n else ("", n)
        if n in ICON_WORDS:
            out[n] = (ICON_WORDS[n], pre)
        else:
            w = ICON_PREFIX[pre] % rest if pre in ICON_PREFIX else rest
            out[n] = (w.replace("a %s" % rest, "an %s" % rest) if rest[0] in "aeiou" else w, pre)
    return out

GROUPS = {"gear": (gear, "little equipment icons", lambda n: n.startswith(("g_", "o_"))),
          "relics": (relics, "little relic icons", lambda n: n.startswith("relic_")),
          "icons": (icons, "little game item icons", lambda n: True)}

def main(group):
    words, what, mine = GROUPS[group]
    known = words()
    with open(os.path.join(ROOT, "resprite", "spritecook-assets.json")) as f:     # redrawn before: kept
        made = {a["name"] for a in json.load(f)["assets"] if a["kind"] == "made"}
    names = sorted(n for n in known if mine(n) and os.path.exists(os.path.join(G, n + ".png"))
                   and n not in made and not os.path.exists(os.path.join(ROOT, "resprite", "hd", n + ".png")))
    if group == "gear":   # every g_* picture must have its row
        names = sorted(set(names) | {f[:-4] for f in os.listdir(G) if f.startswith("g_") and f.endswith(".png")})
    missing = [n for n in names if n not in known]
    assert not missing, missing
    names.sort(key=lambda n: (known[n][1], n))                  # by kind
    out = {}
    per = COLS * COLS
    for idx in range(0, len(names), per):
        cells = names[idx:idx + per]
        key = "%s%02d" % (group[0], idx // per + 1)
        n = len(cells)
        cells = cells + ["-"] * (per - n)
        ref = os.path.join(ROOT, "resprite", "spritecook", "refs", "%s_%s.png" % (group, key))
        subprocess.run(["python3", os.path.join(ROOT, "resprite", "tools", "sheet_ref.py"), ref, str(COLS)] + cells,
                       check=True, capture_output=True)
        lines = []
        for r in range(COLS):
            row = [known[c][0] for c in cells[r * COLS:r * COLS + COLS] if c != "-"]
            if row:
                lines.append(("Row %d, left to right: " if r == 0 else "Row %d: ") % (r + 1) + "; ".join(row) + ".")
        lead = ("A sprite sheet of %d different %s in a %d by %d grid, redrawn from the reference sheet"
                % (n, what, COLS, COLS)) + ("" if n == per else "; only the first %d places are used and the rest stay empty" % n) + \
            ". Every one stays in its own place in the grid and keeps its shape, its colours and the way it faces, " \
            "as in the reference. "
        tail = " The words are only to tell you what each one is: never write any names, words or letters in the" \
            " picture. Each a clean, bright, colourful pixel art game item in exactly the look of the style guide," \
            " with clear empty space between them. No text, no labels, no captions, no background."
        out[key] = {"cells": cells, "ref": os.path.relpath(ref, ROOT), "prompt": lead + " ".join(lines) + tail}
    path = os.path.join(ROOT, "resprite", "spritecook", "refs", "%s_plan.json" % group)
    done = json.load(open(path)) if os.path.exists(path) else {}   # keeps the SpriteCook ids of sheets made
    for k, v in out.items():
        done.setdefault(k, {}).update(v)
    with open(path, "w") as f:
        json.dump(done, f, indent=1)
        f.write("\n")
    print(len(names), group, "in", len(out), "sheets")

if __name__ == "__main__":
    main(sys.argv[1])
