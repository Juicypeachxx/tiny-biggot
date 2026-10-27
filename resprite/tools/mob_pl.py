"""Foes drawn on PixelLab into the game (64, his plan THE LIVING PIXEL WORLD: "then mobs").
python3 resprite/tools/mob_pl.py mobs1 bat bat2 slime skeleton mushroom
python3 resprite/tools/mob_pl.py mobs_pro/all mushroom=mushroom_n_4 mushroom_elite=mushroom_e_16
  (name=picture: that picture for that name; an elite given so is its own drawing, not a rim)
- resprite/pixellab/<set>/<name>.png: the picture as it came (24 x 24: PixelLab wants a square
  canvas under 32). bat2 (the second wing beat) is made from bat: its wings folded down.
- Trimmed to what is drawn, then set in a box at least as big as the old picture's, its feet on
  the box's bottom and centred; graphics_hd/<name>.png that box, graphics/<name>.png half of it
  (the game measures a picture by its small copy: Img._own).
- <name>_elite in both: the elite look of the new picture (elite_hd.elite: a gold rim).
Then bake the atlas (tools/bake_atlas.sh): the small copies are in it."""
import os, sys
from PIL import Image
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from elite_hd import elite

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
GFX = os.path.join(ROOT, "tiny_biggot_godot", "assets", "graphics")
HD = os.path.join(ROOT, "tiny_biggot_godot", "assets", "graphics_hd")

def fold_wings(b):
    """A flying thing's other wing beat: the wings outside its body flipped down and shortened."""
    out = Image.new("RGBA", b.size, (0, 0, 0, 0))
    x0, y0, x1, y1 = b.getbbox()
    mid, half = (x0 + x1) // 2, 4
    for a, c in [(x0, mid - half), (mid + half, x1)]:
        wing = b.crop((a, 0, c, b.height))
        wb = wing.getbbox()
        if not wb:
            continue
        fw = wing.crop(wb).transpose(Image.FLIP_TOP_BOTTOM)
        fw = fw.resize((fw.width, max(1, int(fw.height * 0.75))), Image.NEAREST)
        out.alpha_composite(fw, (a + wb[0], y0 + 3))
    out.alpha_composite(b.crop((mid - half, 0, mid + half, b.height)), (mid - half, 0))
    return out

def even(n):
    return n + n % 2

def fit(im, old):
    im = im.crop(im.getbbox())
    w, h = max(old[0], even(im.width)), max(old[1], even(im.height))
    box = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    box.alpha_composite(im, ((w - im.width) // 2, h - im.height))
    return box

def main():
    src = os.path.join(ROOT, "resprite", "pixellab", sys.argv[1])
    args = sys.argv[2:]
    named = [a.split("=")[0] for a in args]
    for a in args:
        n, pic = (a.split("=") + [None])[:2]
        p = os.path.join(src, (pic or n) + ".png")
        if n == "bat2" and not os.path.exists(p):
            im = fold_wings(Image.open(os.path.join(src, "bat.png")).convert("RGBA"))
        else:
            im = Image.open(p).convert("RGBA")
        if os.path.exists(os.path.join(HD, n + ".png")):
            old = Image.open(os.path.join(HD, n + ".png")).size
        else:   # only the small picture so far: the box it had, at double detail
            w, h = Image.open(os.path.join(GFX, n + ".png")).size
            old = (w * 2, h * 2)
        hd = fit(im, old)
        if n == "bat2":   # the same box as the first beat, so the bat does not jump
            hd = fit(im, Image.open(os.path.join(HD, "bat.png")).size)
        small = hd.resize((hd.width // 2, hd.height // 2), Image.NEAREST)
        hd.save(os.path.join(HD, n + ".png"))
        small.save(os.path.join(GFX, n + ".png"))
        if not n.endswith("_elite") and n + "_elite" not in named and (os.path.exists(os.path.join(HD, n + "_elite.png")) or os.path.exists(os.path.join(GFX, n + "_elite.png"))):
            elite(hd, 1).save(os.path.join(HD, n + "_elite.png"))   # (a thin rim: the new art has thin parts)
            elite(small, 1).save(os.path.join(GFX, n + "_elite.png"))
        print(n, old, "->", hd.size)

if __name__ == "__main__":
    main()
