"""The game's pictures sorted for a re-sprite (his test, 20 Oct): what Gemini redraws (the base
pictures, in groups), what the import makes again from them (elite looks, guardian phases), and
what stays as it is (fonts, dots, glows, effect strips, the floor tiles, the logo)."""
import os, re, struct, sys
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
G = os.path.join(ROOT, "tiny_biggot_godot", "assets", "graphics")
ART = os.path.join(ROOT, "tiny_biggot_godot", "tools", "art")
sys.path.insert(0, ART)
import render as R   # the art tools: EVOLVE (guardians) and MINIS (champions) phases

def size(n):
    with open(os.path.join(G, n + ".png"), "rb") as fh:
        h = fh.read(24)
    return struct.unpack(">II", h[16:24])

def _sprites(block):
    return re.findall(r'"sprite":\s*"([^"]+)"', block)

def _gd_blocks():
    src = open(os.path.join(ROOT, "tiny_biggot_godot", "scripts", "data", "game_data.gd")).read()
    def block(start, end):
        i = src.index(start)
        j = src.index(end, i)
        return src[i:j]
    heroes = _sprites(block("const HEROES := [", "static var _heroes"))
    foes = _sprites(block("const ENEMIES := {", "const ALT_GUARDIANS"))
    bosses = _sprites(block("const BOSSES := {", "const FLOORS := ["))
    return heroes, foes, bosses

SKIP_PREFIX = ("font", "px_", "glow_", "fx_", "eb_", "ebr_", "shot_", "logo_", "kit", "shadow")

def soft(n):
    """Mostly half-see-through (a glow, a shadow, smoke): a picture that stays as it is."""
    from PIL import Image
    im = Image.open(os.path.join(G, n + ".png")).convert("RGBA")
    vis = [a for a in im.getchannel("A").tobytes() if a > 0]
    return bool(vis) and sum(1 for a in vis if a < 255) >= 0.3 * len(vis)

def derived(n, names):
    """True: the import makes it from its redrawn base (so Gemini does not draw it)."""
    for st in ("_s2", "_s3"):
        if n.endswith(st):
            b = n[:-3]
            core = b[:-6] if b.endswith("_elite") else b
            if core in R.EVOLVE or core in R.MINIS or core in ("rex", "rex_lie"):
                return b in names
    if n.endswith("_elite"):
        return n[:-6] in names
    return False

def plan():
    names = sorted(f[:-4] for f in os.listdir(G) if f.endswith(".png"))
    names_set = set(names)
    heroes, foes, bosses = _gd_blocks()
    groups = {}
    skipped, made = [], []
    def put(g, n):
        groups.setdefault(g, []).append(n)
    for n in names:
        w, h = size(n)
        if n.startswith(SKIP_PREFIX) or max(w, h) <= 4 or max(w, h) > 64 or (w >= 2.5 * h and w > 20) or soft(n):
            skipped.append(n)
            continue
        if derived(n, names_set):
            made.append(n)
            continue
        base = re.sub(r"(_elite)?(_s[23])?$", "", n)
        if n in heroes or base in heroes or n.endswith("_hero"):
            put("heroes", n)
        elif base in bosses or base in R.EVOLVE or base in R.MINIS or base in ("arci", "sefe", "braysalot", "scalesworth", "nigh", "chonk", "rex") or n.startswith(("arci_", "sefe_", "rex_")) or re.search(r"_s[23]$", n):
            put("guardians", n)
        elif n in foes or base in foes:
            put("foes", n)
        elif n.startswith(("npc_", "pet_", "fam_", "s_", "camp_")):
            put("people and pets", n)
        elif n.startswith("w_"):
            put("weapons", n)
        elif n.startswith("g_"):
            put("gear", n)
        elif n.startswith("relic_"):
            put("relics", n)
        elif n.startswith("tr_"):
            put("traits", n)
        elif n.startswith(("prop_", "wall_", "o_")) or n.startswith("chest"):
            put("room things", n)
        else:
            put("other items and icons", n)
    return groups, made, skipped

if __name__ == "__main__":
    groups, made, skipped = plan()
    tot = 0
    for g, ns in groups.items():
        sizes = sorted(set(max(size(n)) for n in ns))
        print("%-24s %4d   biggest side %s" % (g, len(ns), sizes[-3:]))
        tot += len(ns)
    print("to redraw: %d   made again by the import: %d   kept as they are: %d" % (tot, len(made), len(skipped)))
