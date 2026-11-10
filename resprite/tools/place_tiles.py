"""66.5 (his pictures and videos, 28 Oct: "the collors, the enviroments ... the aliveness of stages"):
every place's floor slabs drawn again on PixelLab, four places to a request (create_image_pro gives
four pictures, one per place in the order asked).
python3 -I resprite/tools/place_tiles.py <dir with P01_0.png ...> <groups.json>
- groups.json: request -> the four kits in its order (a short last request repeats its last kit).
- tiny_biggot_godot/assets/graphics_hd/<kit>_tiles.png: the 16 slabs, the plainest first (the game
  lays the first eight most, the last four rarely: world_view.gd _paint_place).
- resprite/pixellab/vivid_places/<kit>_tiles_raw.png: the picture as it came."""
import json, os, shutil, sys
import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
HD = os.path.join(ROOT, "tiny_biggot_godot", "assets", "graphics_hd")
KEEP = os.path.join(ROOT, "resprite", "pixellab", "vivid_places")

def plain_first(im):
    a = np.array(im).astype(float)
    ranked = []
    for k in range(16):
        x, y = (k % 4) * 32, (k // 4) * 32
        t = a[y + 4:y + 28, x + 4:x + 28, :3]
        busy = np.abs(t - np.median(t.reshape(-1, 3), axis=0)).sum(2)
        ranked.append(((busy > 60).sum(), k))
    ranked.sort()
    out = Image.new("RGBA", (128, 128))
    for i, (_, k) in enumerate(ranked):
        out.paste(im.crop(((k % 4) * 32, (k // 4) * 32, (k % 4) * 32 + 32, (k // 4) * 32 + 32)), ((i % 4) * 32, (i // 4) * 32))
    return out

def main():
    src, groups = sys.argv[1], json.load(open(sys.argv[2]))
    os.makedirs(KEEP, exist_ok=True)
    done = set()
    for req, kits in sorted(groups.items()):
        for i, kit in enumerate(kits):
            p = os.path.join(src, "%s_%d.png" % (req, i))
            if kit in done or not os.path.exists(p):
                continue
            im = Image.open(p).convert("RGBA")
            if im.size != (128, 128):
                print("skip", kit, im.size)
                continue
            shutil.copy(p, os.path.join(KEEP, kit + "_tiles_raw.png"))
            plain_first(im).save(os.path.join(HD, kit + "_tiles.png"))
            done.add(kit)
    print(len(done), "places")

if __name__ == "__main__":
    main()
