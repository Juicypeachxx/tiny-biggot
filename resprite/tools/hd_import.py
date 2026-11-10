"""Puts the new pictures into the game (22 Oct, the engine step: his "ok do the engine and make the ipa").
python3 resprite/tools/hd_import.py   -> tiny_biggot_godot/assets/graphics_hd/
- Every new picture (resprite/hd) of a picture the game has, under the same name. Each must be exactly
  today's size times 1, 2 or 4 (a guardian is drawn at twice its size in the game, so its new
  picture has four of its pixels to one of today's): the game draws it at today's size, with the
  finer pixels (scripts/core/img.gd).
- The floors (<kit>_floor, a texture the game repeats over the room): an odd side is made even
  (one row or column drawn twice), so the floor is a whole number of the game's pixels.
- The two floor marks (a blast's scorch, a pool) came back solid, where today's are see-through
  (a soft dark patch, a faint puddle): they keep today's see-through shape, with the new colours.
  (Solid, a scorch was a dark box on the floor.)
- Not copied: the hexer's idle frames (a test of 21 Oct the game does not use).
- A file that is no longer a new picture is taken away (with its .import).
- The pixel look (23 Oct, his "little bit more pixelated and to fit my previous style"):
  pixel_look.look() on every picture as it goes in; resprite/hd keeps them as they came. An
  elite look (X_elite) is made again from X in the pixel look (elite_hd.elite), so its gold
  outline is the outermost one. A picture SpriteCook drew again as chunky pixel art (the items,
  tools/pixel_sheets.py: "look": "pixel" in the manifest) goes in as it is."""
import os, sys
from PIL import Image, ImageChops
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from inventory import G, ROOT
from pixel_look import look
from elite_hd import elite
import json

HD = os.path.join(ROOT, "resprite", "hd")
SOFT = ("fx_scorch", "fx_pool")
OUT = os.path.join(ROOT, "tiny_biggot_godot", "assets", "graphics_hd")

def _save(im, dst):
    """Writes the picture only when it changed (so Godot does not import it again)."""
    tmp = dst + ".new.png"
    im.save(tmp, optimize=True)
    if os.path.exists(dst) and open(dst, "rb").read() == open(tmp, "rb").read():
        os.remove(tmp)
    else:
        os.replace(tmp, dst)

def main():
    os.makedirs(OUT, exist_ok=True)
    with open(os.path.join(ROOT, "resprite", "spritecook-assets.json")) as fh:
        drawn = {a["name"] for a in json.load(fh)["assets"] if a["kind"] == "made" and a.get("look") == "pixel"}
    kits = {f[:-4] for f in os.listdir(G) if f.startswith("kit") and f.endswith(".png")}
    put, bad, by = set(), [], {1: 0, 2: 0, 4: 0, "floor": 0}
    for f in sorted(os.listdir(HD)):
        if not f.endswith(".png"):
            continue
        n = f[:-4]
        im = Image.open(os.path.join(HD, f))
        if n.endswith("_floor") and n[:-6] in kits:
            w, h = im.size
            if w % 2 or h % 2:
                im = im.convert("RGBA").resize((w + w % 2, h + h % 2), Image.NEAREST)
            _save(look(n, im, None), os.path.join(OUT, f))
            put.add(f)
            by["floor"] += 1
            continue
        old = os.path.join(G, f)
        if not os.path.exists(old):
            continue
        ow, oh = Image.open(old).size
        k = im.width // ow
        if k not in (1, 2, 4) or im.size != (ow * k, oh * k):
            bad.append("%s: %dx%d, today %dx%d" % (n, im.width, im.height, ow, oh))
            continue
        dst = os.path.join(OUT, f)
        base = n.replace("_elite", "")
        if n in SOFT:
            im = im.convert("RGBA")
            soft = Image.open(old).convert("RGBA").getchannel("A").resize(im.size, Image.NEAREST)
            im.putalpha(ImageChops.darker(im.getchannel("A"), soft))     # the lesser of the two
            _save(im, dst)
        elif base != n and os.path.exists(os.path.join(HD, base + ".png")) and os.path.exists(os.path.join(G, base + ".png")):
            b = Image.open(os.path.join(HD, base + ".png"))
            bo = Image.open(os.path.join(G, base + ".png")).size
            _save(elite(look(base, b, bo), b.width // bo[0]), dst)
        elif n in drawn:
            _save(im, dst)
        else:
            _save(look(n, im, (ow, oh)), dst)
        put.add(f)
        by[k] += 1
    gone = 0
    for f in os.listdir(OUT):
        if f.endswith(".png") and f not in put:
            os.remove(os.path.join(OUT, f))
            if os.path.exists(os.path.join(OUT, f + ".import")):
                os.remove(os.path.join(OUT, f + ".import"))
            gone += 1
    print("%d new pictures in the game: %d at today's size, %d with twice the detail, %d with four times "
          "(guardians), %d floors; %d taken away" % (len(put), by[1], by[2], by[4], by["floor"], gone))
    if bad:
        print("NOT a whole multiple of today's size, left out:\n  " + "\n  ".join(bad))
        sys.exit(1)

if __name__ == "__main__":
    main()
