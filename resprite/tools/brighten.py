"""Less grim (his word, 27 Oct: "can you make graphic and mobs les grimmy and dark"): lifts a picture's
dark tones and adds a little colour, leaving its near-black outline as it is.
python3 resprite/tools/brighten.py <strength> <png>...   (in place; the pictures as they came stay in
resprite/pixellab, so this can be redone from them)
strength: 1.0 for foes and heroes, about 0.6 for floors and walls."""
import colorsys, sys
from PIL import Image

def lift(im, k=1.0):
    im = im.convert("RGBA")
    px = im.load()
    gamma = 1.0 - 0.28 * k          # < 1 lifts the darks
    sat = 1.0 + 0.18 * k
    gain = 1.0 + 0.06 * k
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
            if v < 0.08:             # the outline stays as it is
                continue
            v = min(1.0, (v ** gamma) * gain)
            s = min(1.0, s * sat)
            r2, g2, b2 = colorsys.hsv_to_rgb(h, s, v)
            px[x, y] = (round(r2 * 255), round(g2 * 255), round(b2 * 255), a)
    return im

if __name__ == "__main__":
    k = float(sys.argv[1])
    for p in sys.argv[2:]:
        lift(Image.open(p), k).save(p)
