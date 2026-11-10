"""The elite looks made from the new pictures (22 Oct, before the engine step).
python3 resprite/tools/elite_hd.py   -> resprite/hd/<X>_elite.png (and <X>_elite_s2, _s3)
- An elite foe is drawn from its own picture, X_elite (world_view.gd). Today's are the base with a
  gold outline and a richer, darker body; import_sheets.elite() makes that look from a picture.
- The new pictures have twice the detail, so the gold outline is two of their pixels deep: as
  thick on screen as today's one.
- A base with no new picture (the wisps, the kitten: kept as they are) keeps today's elite."""
import colorsys, os, sys
from PIL import Image
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from inventory import G, ROOT

HD = os.path.join(ROOT, "resprite", "hd")
GOLD = (242, 201, 76)

def elite(im, depth):
    """Today's elite look at `depth` pixels a game pixel: every pixel up to depth steps from the
    outside turns gold, the rest is richer and darker."""
    im = im.convert("RGBA")
    w, h = im.size
    px = im.load()
    far = depth + 1
    dist = [[far] * w for _ in range(h)]
    edge = []
    for y in range(h):
        for x in range(w):
            if px[x, y][3] < 128:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                q, r = x + dx, y + dy
                if not (0 <= q < w and 0 <= r < h) or px[q, r][3] < 128:
                    dist[y][x] = 1
                    edge.append((x, y))
                    break
    while edge:                                 # steps inwards from the outline, up to depth
        nxt = []
        for x, y in edge:
            d = dist[y][x] + 1
            if d > depth:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                q, r = x + dx, y + dy
                if 0 <= q < w and 0 <= r < h and px[q, r][3] >= 128 and dist[r][q] > d:
                    dist[r][q] = d
                    nxt.append((q, r))
        edge = nxt
    out = im.copy()
    po = out.load()
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a < 128:
                continue
            if dist[y][x] <= depth:
                po[x, y] = GOLD + (a,)
                continue
            hh, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
            rr, gg, bb = colorsys.hsv_to_rgb(hh, min(1.0, s * 1.2), v * 0.82)
            po[x, y] = (int(rr * 255 + 0.5), int(gg * 255 + 0.5), int(bb * 255 + 0.5), a)
    return out

def main():
    made, kept = 0, []
    for f in sorted(os.listdir(G)):
        n = f[:-4]
        if not f.endswith(".png") or "_elite" not in n:
            continue
        base = n.replace("_elite", "")
        hd = os.path.join(HD, base + ".png")
        if not os.path.exists(os.path.join(G, base + ".png")) or not os.path.exists(hd):
            kept.append(n)
            continue
        old = Image.open(os.path.join(G, base + ".png"))
        new = Image.open(hd)
        depth = new.width // old.width
        elite(new, depth).save(os.path.join(HD, n + ".png"))
        made += 1
    print("made %d elite looks from the new pictures; kept as they are: %s" % (made, ", ".join(kept)))

if __name__ == "__main__":
    main()
