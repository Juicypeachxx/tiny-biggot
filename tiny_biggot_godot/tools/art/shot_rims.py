# 35.3 CLARITY (his word, 9 Oct: "perfect visual clarity in bullet hell"): every foe shot gets a
# soft dark rim one pixel outside its own outline, so it reads on bright effects (fire, sparks,
# glows). Writes ebr_<kind>.png (the four-frame strips, FANCY EFFECTS on) and orbr_<kind>.png (the
# plain orbs) beside the originals, which stay as they are. EBullets draws the rimmed ones.
# Run from the project folder: python3 tools/art/shot_rims.py   (then tools/bake_atlas.sh)
from PIL import Image

G = "assets/graphics/"
KINDS = ["red", "redBig", "bone", "water", "ice", "iceBig", "spore", "dark", "darkBig", "fire", "fireBig", "cyan", "page"]
RIM = (20, 15, 28, 150)   # the outline colour of the game (#140f1c), part see-through


def rimmed(im):
    """The picture one pixel larger on every side, with the rim round what is solid."""
    w, h = im.size
    out = Image.new("RGBA", (w + 2, h + 2), (0, 0, 0, 0))
    out.paste(im, (1, 1))
    src = out.load()
    solid = [[src[x, y][3] >= 128 for y in range(h + 2)] for x in range(w + 2)]
    dst = out.copy()
    px = dst.load()
    for y in range(h + 2):
        for x in range(w + 2):
            if src[x, y][3] >= 128:
                continue
            near = False
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < w + 2 and 0 <= ny < h + 2 and solid[nx][ny]:
                    near = True
                    break
            if near:
                px[x, y] = RIM
    return dst


def strip(name, frames):
    im = Image.open(G + name + ".png").convert("RGBA")
    fw = im.width // frames
    out = Image.new("RGBA", ((fw + 2) * frames, im.height + 2), (0, 0, 0, 0))
    for f in range(frames):
        out.paste(rimmed(im.crop((f * fw, 0, (f + 1) * fw, im.height))), (f * (fw + 2), 0))
    return out


if __name__ == "__main__":
    for k in KINDS:
        strip("eb_" + k, 4).save(G + "ebr_" + k + ".png")
        strip("orb_" + k, 1).save(G + "orbr_" + k + ".png")
    print("shot rims written: %d kinds" % len(KINDS))
