"""A SpriteCook animation fitted to double size: every frame shrunk by the same amount and stood
in the same place, so the character does not jitter. resprite/spritecook/<name>_<motion>.png (the
sheet as SpriteCook gave it) -> resprite/hd/<name>_<motion>_<i>.png, plus a preview GIF.
python3 resprite/tools/spritecook_anim.py NAME MOTION FRAMES [COLUMNS] [PREVIEW.gif]"""
import os, sys
from PIL import Image
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from inventory import G, ROOT
from gemini_cut import frame
from spritecook_fit import down, density, RAW, HD

def cut(sheet, n, cols):
    rows = (n + cols - 1) // cols
    fw, fh = sheet.width // cols, sheet.height // rows
    return [sheet.crop(((i % cols) * fw, (i // cols) * fh, (i % cols + 1) * fw, (i // cols + 1) * fh)) for i in range(n)]

def fit_all(frames, w, h):
    boxes = [f.getchannel("A").point(lambda v: 255 if v >= 128 else 0).getbbox() for f in frames]
    boxes = [b for b in boxes if b]
    box = (min(b[0] for b in boxes), min(b[1] for b in boxes), max(b[2] for b in boxes), max(b[3] for b in boxes))
    frames = [f.crop(box) for f in frames]
    k = min(w / frames[0].width, h / frames[0].height)
    nw, nh = max(1, round(frames[0].width * k)), max(1, round(frames[0].height * k))
    return [frame(down(f, nw, nh), w, h, outline=False) for f in frames]

def preview(frames, out, unit=6, ms=125):
    bg = []
    for f in frames:
        g = Image.new("RGBA", (f.width * unit, f.height * unit), (34, 30, 40, 255))
        g.alpha_composite(f.resize(g.size, Image.NEAREST))
        bg.append(g.convert("RGB"))
    bg[0].save(out, save_all=True, append_images=bg[1:], duration=ms, loop=0)

def main(name, motion, n, cols=None, gif=None):
    sheet = Image.open(os.path.join(RAW, "%s_%s.png" % (name, motion))).convert("RGBA")
    if cols is None:
        cols = n if sheet.width >= sheet.height * n - n else max(1, round(sheet.width / sheet.height))
    old = Image.open(os.path.join(G, name + ".png"))
    d = density(name, old)
    frames = fit_all(cut(sheet, n, cols), old.width * d, old.height * d)
    for i, f in enumerate(frames):
        f.save(os.path.join(HD, "%s_%s_%d.png" % (name, motion, i)))
    if gif:
        preview(frames, gif)
    print("%s %s: %d frames of %dx%d" % (name, motion, len(frames), frames[0].width, frames[0].height))

if __name__ == "__main__":
    a = sys.argv[1:]
    main(a[0], a[1], int(a[2]), int(a[3]) if len(a) > 3 and a[3].isdigit() else None,
         next((x for x in a[3:] if x.endswith(".gif")), None))
