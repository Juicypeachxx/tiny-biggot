"""Review for the effects: today's strip (left) and the new one (right), playing, big enough to
see, one row each, on the game's dark floor colour; and a still sheet of every frame.
python3 resprite/tools/fx_review.py OUT (makes OUT.gif and OUT.png) STRIP:FRAMES [STRIP:FRAMES...]"""
import os, sys
from PIL import Image, ImageDraw
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from inventory import G
from spritecook_fit import HD

BG = (26, 20, 35, 255)
SHOW = 160         # the side of a frame on screen, about

def frames(path, n):
    im = Image.open(path).convert("RGBA")
    w = im.width // n
    return [im.crop((i * w, 0, i * w + w, im.height)) for i in range(n)]

def review(out, specs):
    rows = []
    for s in specs:
        name, n = s.rsplit(":", 1)
        old = frames(os.path.join(G, name + ".png"), int(n))
        new = frames(os.path.join(HD, name + ".png"), int(n))
        k = max(1, SHOW // max(old[0].size))
        kn = max(1, old[0].width * k // new[0].width)
        rows.append((name, [f.resize((f.width * k, f.height * k), Image.NEAREST) for f in old],
                     [f.resize((f.width * kn, f.height * kn), Image.NEAREST) for f in new]))
    cw = max(r[1][0].width for r in rows)
    chh = max(r[1][0].height for r in rows)
    W, rh = cw * 2 + 40, chh + 18
    longest = max(len(r[1]) for r in rows)
    gif = []
    for t in range(longest):
        img = Image.new("RGBA", (W, rh * len(rows) + 6), BG)
        d = ImageDraw.Draw(img)
        for j, (name, old, new) in enumerate(rows):
            y = j * rh + 4
            d.text((4, y), name, fill=(200, 190, 170, 255))
            i = t % len(old)
            img.alpha_composite(old[i], (10 + (cw - old[i].width) // 2, y + 14))
            img.alpha_composite(new[i], (cw + 30 + (cw - new[i].width) // 2, y + 14))
        gif.append(img.convert("RGB"))
    gif[0].save(out + ".gif", save_all=True, append_images=gif[1:], duration=110, loop=0)
    # still: today's frames above, the new ones below, each strip
    fw = max(len(r[1]) * (r[1][0].width + 4) for r in rows) + 10
    still = Image.new("RGBA", (fw, sum(r[1][0].height * 2 + 26 for r in rows) + 6), BG)
    d = ImageDraw.Draw(still)
    y = 4
    for name, old, new in rows:
        d.text((4, y), name + "   (above: today, below: new)", fill=(200, 190, 170, 255))
        for i, (o, n) in enumerate(zip(old, new)):
            still.alpha_composite(o, (6 + i * (o.width + 4), y + 14))
            still.alpha_composite(n, (6 + i * (o.width + 4), y + 16 + o.height))
        y += old[0].height * 2 + 26
    still.convert("RGB").save(out + ".png")
    return len(gif)

if __name__ == "__main__":
    print(review(sys.argv[1], sys.argv[2:]))
