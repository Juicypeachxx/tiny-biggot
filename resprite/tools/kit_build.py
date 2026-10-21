"""A floor kit in the new look, at double detail: SpriteCook draws the floor as one seamless texture
(mode "texture"), shrunk to stones of about a tile and calmer; the walls, the pillar and the rest are today's pieces at x2, recoloured to that
texture's colours, so a kit costs one picture.
python3 resprite/tools/kit_build.py KIT TEXTURE.png
-> resprite/hd/<kit>_floor.png (the texture, seamless, any size: the game repeats it over the room)
   resprite/hd/<kit>.png (today's kit layout at x2: floor tiles cut from the texture, walls, pillar)"""
import os, sys
from PIL import Image
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from inventory import G
from spritecook_fit import HD, lum

def _pixels(im):
    return im.get_flattened_data() if hasattr(im, "get_flattened_data") else im.getdata()

def fill_holes(im):
    """Background removal can cut light cracks out of a texture: each hole takes the middle colour of
    its solid neighbours (wrapping round the edges, as the texture repeats)."""
    im = im.convert("RGBA")
    w, h = im.size
    px = im.load()
    holes = [(x, y) for y in range(h) for x in range(w) if px[x, y][3] < 255]
    while holes:
        left = []
        done = {}
        for x, y in holes:
            near = [px[(x + dx) % w, (y + dy) % h] for dx in (-1, 0, 1) for dy in (-1, 0, 1) if dx or dy]
            near = [c for c in near if c[3] == 255]
            if len(near) < 3:
                left.append((x, y))
                continue
            near.sort(key=lum)
            done[(x, y)] = near[len(near) // 2]
        for (x, y), c in done.items():
            px[x, y] = c
        if len(left) == len(holes):
            for x, y in left:
                px[x, y] = (px[x, y][0], px[x, y][1], px[x, y][2], 255)
            break
        holes = left
    return im

SIZE = 136   # the texture's longer side at double detail: stones about the size of the old tiles

def resize(tex, size=SIZE):
    """The texture with its longer side at `size`, still seamless: shrunk as a 3 x 3 patch and the
    middle kept, so its edges are averaged with the far side's pixels. (SpriteCook draws the stones at
    the size of a picture of a floor; the game's characters are much smaller.)"""
    w, h = tex.size
    k = min(1.0, size / max(w, h))                       # never enlarged: uneven pixels
    tw, th = max(1, round(w * k)), max(1, round(h * k))
    big = Image.new("RGBA", (w * 3, h * 3))
    for i in range(3):
        for j in range(3):
            big.paste(tex, (i * w, j * h))
    small = big.resize((tw * 3, th * 3), Image.BOX)
    return small.crop((tw, th, tw * 2, th * 2))

def calm(tex, keep=0.6, light=0.88, most=125):
    """Less contrast and a little darker, so the bright characters stand out on the floor; a pale floor
    (frost, marble) no lighter than `most` on average."""
    px = list(_pixels(tex.convert("RGB")))
    mean = [sum(c[i] for c in px) / len(px) for i in range(3)]
    light = min(light, most / max(1.0, lum(mean)))
    out = tex.convert("RGBA").copy()
    o = out.load()
    for y in range(out.height):
        for x in range(out.width):
            c = o[x, y]
            o[x, y] = tuple(max(0, min(255, round((mean[i] + (c[i] - mean[i]) * keep) * light))) for i in range(3)) + (255,)
    return out

def ramp(tex, n=24):
    """The texture's colours from dark to light, n steps."""
    cols = sorted(_pixels(tex.convert("RGB")), key=lum)
    return [cols[min(len(cols) - 1, int((i + 0.5) * len(cols) / n))] for i in range(n)]

def recolour(piece, old_lo, old_hi, steps, lo=0.0, hi=1.0):
    """Today's piece in the texture's colours: each pixel's lightness picks a step of the ramp."""
    out = piece.copy()
    px = out.load()
    for y in range(out.height):
        for x in range(out.width):
            c = px[x, y]
            if c[3] == 0:
                continue
            t = (lum(c) - old_lo) / max(1.0, old_hi - old_lo)
            t = lo + max(0.0, min(1.0, t)) * (hi - lo)
            r = steps[min(len(steps) - 1, int(t * len(steps)))]
            px[x, y] = (r[0], r[1], r[2], c[3])
    return out

def build(kit, texture, size=SIZE):
    tex = calm(resize(fill_holes(Image.open(texture)), size))
    tex.save(os.path.join(HD, kit + "_floor.png"))
    old = Image.open(os.path.join(G, kit + ".png")).convert("RGBA")
    vis = [c for c in _pixels(old) if c[3]]
    old_lo, old_hi = min(lum(c) for c in vis), max(lum(c) for c in vis)
    steps = ramp(tex)
    hd = Image.new("RGBA", (old.width * 2, old.height * 2), (0, 0, 0, 0))
    for v in range(16):                                   # floor tiles: pieces of the texture in a row
        x = (v * 32) % tex.width
        strip = Image.new("RGBA", (32, 32))
        for k in range(32):
            strip.paste(tex.crop(((x + k) % tex.width, 0, (x + k) % tex.width + 1, 32)), (k, 0))
        hd.paste(strip, (v * 32, 0))
    rest = old.crop((0, 16, old.width, old.height))       # walls, pillar, sky: today's at x2, recoloured
    rest = rest.resize((rest.width * 2, rest.height * 2), Image.NEAREST)
    hd.alpha_composite(recolour(rest, old_lo, old_hi, steps), (0, 32))
    hd.save(os.path.join(HD, kit + ".png"))
    return tex.size

if __name__ == "__main__":
    # a third number keeps a pattern bigger (the kitchen's checker squares: 256, not shrunk)
    print(build(sys.argv[1], sys.argv[2], int(sys.argv[3]) if len(sys.argv) > 3 else SIZE))
