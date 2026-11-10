"""An effect sheet from SpriteCook back into the game's strips, keeping today's forms.
python3 resprite/tools/fx_fit.py SHEET.png DENSITY [--grey] [--clip] [--under] COLS SCALE [--fill F] STRIP:FRAMES [...]
COLS, SCALE, F and the strips are the ones fx_ref.py made the reference with (the sheet is drawn on
the same grid). --grey: the strips the game colours itself (a hit in the weapon's colour, the
swings) are kept as greys, so the colour still comes through. --clip: the new art is kept only
inside today's form and one pixel round it (along a thin shape only, not across), where SpriteCook
drew bigger (the slash, the hit star, the bolts).
--under: today's frame under the new one, where SpriteCook drew less than today (the cut mark). Each frame is cut from its cell where the reference had it, scaled to today's
frame at DENSITY (1: the game's own size, 2: double detail), the flat background taken out, and
the window moved by up to a quarter of a frame (at least 4 pixels) to lie best on today's frame (its
outline is today's form): SpriteCook does not always draw a frame exactly in the middle of its cell. All frames
of a strip share one palette. -> resprite/hd/<strip>.png; prints how much of today's form each
frame covers (1.0: the same)."""
import os, sys
from PIL import Image, ImageChops, ImageFilter
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from inventory import G
from spritecook_fit import HD
import fx_ref

KEY = 16          # colour distance to the background that is background
BASE = os.path.join(os.path.dirname(HD), "spritecook", "fx", "base")
COLOURS = 48      # palette of a strip

def _bg(im):
    w, h = im.size
    px = im.load()
    edge = [px[x, y] for x in range(w) for y in (0, h - 1)] + [px[x, y] for y in range(h) for x in (0, w - 1)]
    edge.sort(key=lambda c: c[0] + c[1] + c[2])
    return edge[len(edge) // 2]

def _key(frame, bg):
    out = frame.convert("RGBA")
    px = out.load()
    for y in range(out.height):
        for x in range(out.width):
            c = px[x, y]
            if abs(c[0] - bg[0]) + abs(c[1] - bg[1]) + abs(c[2] - bg[2]) <= KEY:
                px[x, y] = (0, 0, 0, 0)
    return out

def _mask(im):
    a = im.getchannel("A").load()
    return {(x, y) for y in range(im.height) for x in range(im.width) if a[x, y] > 0}

def cover(new, old):
    """How well the new frame lies on today's: shared pixels over all pixels of both (1.0: the same)."""
    a, b = _mask(new), _mask(old)
    return len(a & b) / max(1, len(a | b))

def _solid(im):
    return im.getchannel("A").point(lambda a: 255 if a else 0)

def _window(wide, today, m):
    """The frame-sized window of `wide` (the frame and m pixels round it) that covers today's frame
    best, and how far it moved; on a tie the one nearest the middle."""
    w, h = today.size
    a, b = _solid(wide), _solid(today)
    best = (-1, 0, 0, 0)
    for dy in range(-m, m + 1):
        for dx in range(-m, m + 1):
            win = a.crop((m + dx, m + dy, m + dx + w, m + dy + h))
            s = ImageChops.multiply(win, b).histogram()[255]
            if s > best[0] or (s == best[0] and abs(dx) + abs(dy) < best[3]):
                best = (s, dx, dy, abs(dx) + abs(dy))
    _, dx, dy, _ = best
    return wide.crop((m + dx, m + dy, m + dx + w, m + dy + h)), (dx, dy)

def _grey(im):
    """Lightness only, as a grey picture keeps the colour the game paints it with."""
    a = im.getchannel("A")
    g = im.convert("L").convert("RGBA")
    g.putalpha(a)
    return g

def _shift(mask, dx, dy):
    out = Image.new("L", mask.size, 0)
    out.paste(mask, (dx, dy))
    return out

def _clip(new, today, density):
    """new kept inside today's form grown by one game pixel; a thin shape (a bolt, 5 game pixels or
    less across, with its outline) is not grown across, so it stays as thin as today."""
    solid = today.getchannel("A").point(lambda a: 255 if a else 0)
    box = solid.getbbox() or (0, 0, 1, 1)
    kx = 0 if box[2] - box[0] <= 5 * density else density
    ky = 0 if box[3] - box[1] <= 5 * density else density
    room = solid
    for dx in range(-kx, kx + 1):
        for dy in range(-ky, ky + 1):
            room = ImageChops.lighter(room, _shift(solid, dx, dy))
    out = new.copy()
    out.putalpha(ImageChops.multiply(new.getchannel("A"), room))
    return out

def fit(sheet_path, density, cols, scale, specs, fill=0.8, grey=False, clip=False, under=False):
    sheet = Image.open(sheet_path).convert("RGBA")
    bg = _bg(sheet)
    cells, ref_cell = fx_ref.layout(scale, specs, fill)
    rows = (len(cells) + cols - 1) // cols
    cw, ch = sheet.width / cols, sheet.height / rows
    r = cw / ref_cell                                        # sheet pixels per reference pixel
    strips, report = {}, []
    for k, c in enumerate(cells):
        if c is None:
            continue
        name, i, old = c
        fw, fh = old.width * scale * r, old.height * scale * r     # where the frame lay, on the sheet
        cx = (k % cols) * cw + cw / 2
        cy = (k // cols) * ch + ch / 2
        W, H = old.width * density, old.height * density
        pad = max(4, max(old.width, old.height) // 4)              # game pixels looked at round it
        px, py = pad * fw / old.width, pad * fh / old.height
        wide = sheet.crop((round(cx - fw / 2 - px), round(cy - fh / 2 - py), round(cx + fw / 2 + px), round(cy + fh / 2 + py)))
        size = (W + 2 * pad * density, H + 2 * pad * density)
        shrink = size[0] < wide.width * 0.8                         # much finer than wanted: average, not drop
        wide = _key(wide.resize(size, Image.BOX if shrink else Image.NEAREST), bg)
        today = old.resize((W, H), Image.NEAREST)
        new, moved = _window(wide, today, pad * density)
        if clip:
            new = _clip(new, today, density)
        if under:
            base = _grey(today) if grey else today.copy()
            base.alpha_composite(new)
            new = base
        strips.setdefault(name, []).append((i, new))
        report.append((name, i, round(cover(new, today), 2), moved))
    count = {}
    for sp in specs:
        if sp != "-":
            name, n, _, _, fam = fx_ref.spec(sp)
            count[name if fam is None else "%s#%d" % (name, fam)] = n
    for name, frs in strips.items():
        w, h = frs[0][1].size
        # one family of a shot sheet: the strip to recolour into the others (fx_shots.py)
        path = os.path.join(BASE, name.replace("#", "_") + ".png") if "#" in name else os.path.join(HD, name + ".png")
        out = Image.new("RGBA", (w * count[name], h))
        if len(frs) < count[name] and os.path.exists(path):      # the rest of the strip from earlier sheets
            have = Image.open(path).convert("RGBA")
            if have.size == out.size:
                out = have
        for i, f in frs:
            out.paste(f, (i * w, 0))
        if grey:
            out = _grey(out)
        alpha = out.getchannel("A")
        q = out.convert("RGB").quantize(COLOURS, method=Image.Quantize.MEDIANCUT).convert("RGBA")
        q.putalpha(alpha)
        q.save(path)
    return report

if __name__ == "__main__":
    a = sys.argv[1:]
    grey, clip, under = "--grey" in a, "--clip" in a, "--under" in a
    a = [x for x in a if x not in ("--grey", "--clip", "--under")]
    cols, scale, fill, specs = fx_ref.args(a[2:])
    for row in fit(a[0], int(a[1]), cols, scale, specs, fill, grey, clip, under):
        print(*row)
