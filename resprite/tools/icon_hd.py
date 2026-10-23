"""His icon sheet's relics (toys and gadgets) and fish, at the old ones' size (V2 only, personal use:
resprite/icon_sheet/README.md).
    python3 -I resprite/icon_sheet/cut.py resprite/icon_sheet/sheet.png CUT
    python3 resprite/tools/icon_hd.py CUT
    python3 resprite/tools/hd_import.py
- The icons are 11 to 20 pixels. Drawn as they are (one to each of the game's pixels, like the
  weapons, gear and food from the sheet), a relic would sit on its neighbours (the HUD puts one every
  11 pixels, the lists every 12) and a fish would be twice the old ones (12 x 6) and run off the
  larder. So each goes in as the new picture (resprite/hd) of a picture half its size: it shows at
  the detail of the old ones' new pictures, at about their size.
  - A relic: in the middle of 20 x 20 (the game's: 10 x 10, like the old relics).
  - A fish: on the smallest even box round it (the game draws a fish from the middle of its bottom).
- They go in as they are ("look": "pixel" in the manifest): the icons are pixel art already.
- RELICS, FISH: the icon's number (cut.py) and the picture's name."""
import json, os, sys
from PIL import Image
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from inventory import G
from spritecook_fit import HD, MANIFEST, sha12

RELIC_SIDE = 20
RELICS = [
    (10, "binoculars"), (12, "sandbucket"), (29, "seashell"), (52, "raffleticket"), (53, "windupkey"),
    (71, "filmreel"), (74, "diary"), (75, "gamepad"), (76, "boombox"), (91, "clapperboard"), (92, "palette"),
    (94, "bookstack"), (95, "handheld"), (96, "mixtape"), (114, "treasuremap"), (116, "vinyl"),
    (77, "goldmedal"), (97, "silvermedal"), (117, "bronzemedal"), (82, "starbadge"), (122, "luckystar"),
    (159, "racecup"), (160, "championcup"), (180, "bugnet"), (182, "sandcastle"), (183, "glowsticks"),
    (184, "picnicset"), (260, "goldnuggets"), (263, "lunchbag"), (273, "cauldron"), (296, "turtleshell"),
    (297, "balloons"), (300, "coinpurse"), (301, "ruby"), (374, "butterfly"), (375, "teddybear"),
    (377, "rainbow"), (380, "cherryblossom"), (335, "smartphone"), (336, "microphone"), (338, "luckycard"),
    (339, "sparkler"), (340, "present"), (341, "partycracker"), (358, "camera"), (359, "firecracker"),
    (360, "toydrum"), (361, "briefcase"), (381, "photoframe"), (382, "chessknight"), (384, "oldjournal"),
    (385, "mysterybox"), (387, "toydino"), (171, "goldenbell"), (354, "bouquet"), (357, "bonsai"),
    (353, "victorybanner"), (331, "rainbowfan"), (333, "maracas"), (328, "papermoth"),
]
FISH = [
    (14, "mantaray"), (15, "rockfish"), (16, "clownfish"), (17, "pufferfish"), (18, "bass"), (19, "parrotfish"),
    (20, "blueseahorse"), (35, "blueshark"), (36, "crayfish"), (37, "squid"), (38, "koi"), (39, "goldfish"),
    (40, "mackerel"), (41, "bluetang"), (56, "catfish"), (57, "redsnapper"), (58, "trout"), (59, "angelfish"),
    (60, "perch"), (61, "wrasse"), (62, "swordfish"), (78, "goldseahorse"), (79, "devilfish"), (80, "mudshark"),
    (99, "sunfish"), (100, "greatshark"), (119, "anglerfish"), (120, "dolphin"), (121, "hermitcrab"),
]

def boxed(icon, w, h, bottom=False):
    """The icon in the middle of w x h (at its bottom with bottom=True)."""
    if icon.width > w or icon.height > h:
        raise SystemExit("an icon of %dx%d does not fit %dx%d" % (icon.width, icon.height, w, h))
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    out.alpha_composite(icon, ((w - icon.width) // 2, h - icon.height if bottom else (h - icon.height) // 2))
    return out

def main(cut):
    made = []
    for kind, rows in (("relic", RELICS), ("fish", FISH)):
        for i, rid in rows:
            n = kind + "_" + rid
            icon = Image.open(os.path.join(cut, "i%03d.png" % i)).convert("RGBA")
            if kind == "relic":
                hd = boxed(icon, RELIC_SIDE, RELIC_SIDE)
            else:
                hd = boxed(icon, icon.width + icon.width % 2, icon.height + icon.height % 2, True)
            hd.save(os.path.join(HD, n + ".png"))
            hd.resize((hd.width // 2, hd.height // 2), Image.NEAREST).save(os.path.join(G, n + ".png"))
            made.append((n, i))
    with open(MANIFEST) as f:
        man = json.load(f)
    names = {n for n, _ in made}
    man["assets"] = [a for a in man["assets"] if not (a["kind"] == "made" and a.get("name") in names)]
    for n, i in made:
        man["assets"].append({"label": "%s: his icon sheet, icon %d (resprite/icon_sheet, personal use)" % (n, i),
                              "kind": "made", "name": n, "look": "pixel", "asset_id": None, "credits": 0,
                              "sha12": sha12(os.path.join(HD, n + ".png"))})
    with open(MANIFEST, "w") as f:
        json.dump(man, f, indent=1)
        f.write("\n")
    print(len(RELICS), "relics,", len(FISH), "fish")

if __name__ == "__main__":
    main(sys.argv[1])
