"""SpriteCook pictures fitted to double size for the sprites they redraw.
resprite/spritecook/<name>.png (saved as SpriteCook gave it) -> resprite/hd/<name>.png, and the
file's sha12 into resprite/spritecook-assets.json. python3 resprite/tools/spritecook_fit.py [NAME...]
Fresh download links: the SpriteCook tool get_asset_metadata(asset_id); they last an hour."""
import hashlib, json, os, sys
from PIL import Image
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from inventory import G, ROOT
from gemini_cut import fit

RAW = os.path.join(ROOT, "resprite", "spritecook")
HD = os.path.join(ROOT, "resprite", "hd")
MANIFEST = os.path.join(ROOT, "resprite", "spritecook-assets.json")

def sha12(path):
    with open(path, "rb") as f:
        return hashlib.sha256(f.read()).hexdigest()[:12]

def trim(im):
    box = im.getchannel("A").point(lambda v: 255 if v >= 128 else 0).getbbox()
    return im.crop(box)

def main(names):
    with open(MANIFEST) as f:
        man = json.load(f)
    done = 0
    for a in man["assets"]:
        n = a.get("name")
        if a["kind"] != "made" or (names and n not in names):
            continue
        raw = os.path.join(RAW, n + ".png")
        if not os.path.exists(raw):
            print("not downloaded yet:", n)
            continue
        a["sha12"] = sha12(raw)
        old = Image.open(os.path.join(G, n + ".png"))
        fit(trim(Image.open(raw).convert("RGBA")), old.width * 2, old.height * 2).save(os.path.join(HD, n + ".png"))
        done += 1
    with open(MANIFEST, "w") as f:
        json.dump(man, f, indent=1)
        f.write("\n")
    print("fitted %d SpriteCook pictures into resprite/hd" % done)

if __name__ == "__main__":
    main(sys.argv[1:])
