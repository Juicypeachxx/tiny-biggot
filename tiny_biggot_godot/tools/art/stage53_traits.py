# Stage 53 (his word, 11 Oct: new level-up traits for the new additions): a 16 x 16 picture for each
# new trait, one flat white shape that the trait's cube draws in its group's colour, like the others
# (tools/art/stage43_7_traits.py). Drawn with shapes rather than typed in. Our own drawings.
# Run from the project folder: python3 tools/art/stage53_traits.py
#   ART_OUT=<folder>   write the pictures there instead (a preview)
#   SHEET=<file.png>   also write a contact sheet of them, four times the size, with their ids
import math, os
from PIL import Image, ImageDraw

G = os.environ.get("ART_OUT", "assets/graphics/")
W = 255


def canvas():
    im = Image.new("L", (16, 16), 0)
    return im, ImageDraw.Draw(im)


def rays(d, cx, cy, r0, r1, n, off=0.0):
    for k in range(n):
        a = off + k * 2 * math.pi / n
        d.line([(cx + math.cos(a) * r0, cy + math.sin(a) * r0), (cx + math.cos(a) * r1, cy + math.sin(a) * r1)], fill=W)


def wisp(d, cx, cy, s=1.0):
    d.ellipse([cx - 3 * s, cy - 2 * s, cx + 3 * s, cy + 4 * s], fill=W)
    d.polygon([(cx - 2 * s, cy - 1 * s), (cx + 1 * s, cy - 6 * s), (cx + 2 * s, cy)], fill=W)
    d.point([(cx - 1, cy + 1), (cx + 1, cy + 1)], fill=0)


def bolt(d, x, y, s=1.0):
    d.polygon([(x + 3 * s, y), (x - 1 * s, y + 6 * s), (x + 1 * s, y + 6 * s), (x - 2 * s, y + 12 * s), (x + 4 * s, y + 4 * s), (x + 2 * s, y + 4 * s), (x + 5 * s, y)], fill=W)


def make():
    out = {}

    im, d = canvas()   # SUNSPOT: a sun
    d.ellipse([4, 4, 11, 11], fill=W)
    rays(d, 7.5, 7.5, 5.5, 7.5, 8)
    out["q_sunspot"] = im

    im, d = canvas()   # DAWNBURST: the sun rising, bursting
    d.pieslice([2, 6, 13, 17], 180, 360, fill=W)
    d.line([(0, 13), (15, 13)], fill=W)
    rays(d, 7.5, 12, 7, 9.5, 7, math.pi)
    out["q_dawnburst"] = im

    im, d = canvas()   # GRAVE MOSS: a gravestone, moss dripping
    d.rounded_rectangle([3, 2, 12, 14], radius=4, fill=W)
    d.line([(7, 5), (7, 9)], fill=0)
    d.line([(5, 6), (9, 6)], fill=0)
    d.line([(1, 15), (14, 15)], fill=W)
    d.point([(4, 13), (11, 12), (12, 13)], fill=0)
    out["q_gravemoss"] = im

    im, d = canvas()   # LICH TOUCH: a bony hand
    for x in (4, 7, 10):
        d.line([(x, 1), (x, 8)], fill=W)
        d.point([(x, 4)], fill=0)
    d.line([(13, 5), (13, 9)], fill=W)
    d.rectangle([4, 8, 13, 12], fill=W)
    d.rectangle([6, 12, 11, 15], fill=W)
    out["q_lichtouch"] = im

    im, d = canvas()   # LONG SHADOWS: a figure and its long shadow
    d.ellipse([2, 1, 5, 4], fill=W)
    d.rectangle([2, 5, 5, 10], fill=W)
    d.polygon([(4, 11), (15, 13), (15, 15), (2, 12)], fill=W)
    out["q_longshadow"] = im

    im, d = canvas()   # OPEN CIRCUIT: a wire broken by a spark
    d.line([(0, 8), (5, 8)], fill=W)
    d.line([(10, 8), (15, 8)], fill=W)
    d.line([(5, 5), (5, 11)], fill=W)
    d.line([(10, 5), (10, 11)], fill=W)
    bolt(d, 6, 2, 0.8)
    out["q_livewire"] = im

    im, d = canvas()   # CAPACITOR: two plates, charged
    d.rectangle([4, 2, 6, 13], fill=W)
    d.rectangle([9, 2, 11, 13], fill=W)
    d.line([(0, 8), (4, 8)], fill=W)
    d.line([(11, 8), (15, 8)], fill=W)
    d.point([(2, 3), (13, 3), (2, 13), (13, 13)], fill=W)
    out["q_capacitor"] = im

    im, d = canvas()   # BASS DROP: a speaker and its waves
    d.rectangle([1, 3, 8, 12], fill=W)
    d.ellipse([3, 5, 6, 10], fill=0)
    d.arc([5, 2, 12, 13], -60, 60, fill=W)
    d.arc([5, 0, 15, 15], -60, 60, fill=W)
    out["q_bassdrop"] = im

    im, d = canvas()   # RESONANCE: rings from a point
    d.ellipse([6, 6, 9, 9], fill=W)
    d.ellipse([3, 3, 12, 12], outline=W)
    d.ellipse([0, 0, 15, 15], outline=W)
    out["q_resonance"] = im

    im, d = canvas()   # FIVEFOLD PATH: a five-point star of dots
    pts = [(7.5 + math.cos(-math.pi / 2 + k * 2 * math.pi / 5) * 6.5, 8 + math.sin(-math.pi / 2 + k * 2 * math.pi / 5) * 6.5) for k in range(5)]
    star = [pts[(k * 2) % 5] for k in range(5)]
    d.polygon(star, outline=W)
    for x, y in pts:
        d.ellipse([x - 1.5, y - 1.5, x + 1.5, y + 1.5], fill=W)
    out["q_fivefold"] = im

    im, d = canvas()   # ECLIPSE CHAIN: a dark disk over a bright one
    d.ellipse([1, 1, 14, 14], fill=W)
    d.ellipse([4, 2, 15, 13], fill=0)
    d.ellipse([12, 12, 15, 15], outline=W)
    out["q_totaleclipse"] = im

    im, d = canvas()   # THUNDER RELAY: a bolt that forks
    bolt(d, 4, 0, 1.0)
    d.line([(9, 9), (14, 14)], fill=W)
    d.line([(9, 9), (14, 6)], fill=W)
    out["q_conductor"] = im

    im, d = canvas()   # PLAGUE WIND: gusts and spores
    d.arc([0, 1, 12, 9], 200, 360, fill=W)
    d.line([(0, 5), (10, 5)], fill=W)
    d.arc([3, 7, 15, 15], 200, 360, fill=W)
    d.line([(3, 11), (13, 11)], fill=W)
    d.point([(13, 3), (14, 8), (2, 14), (8, 14)], fill=W)
    out["q_plaguewind"] = im

    im, d = canvas()   # KINDRED SPIRIT: a wisp
    wisp(d, 7.5, 8, 1.3)
    out["q_kindred"] = im

    im, d = canvas()   # SPIRIT FIRE: a flame with a wisp's eyes
    d.polygon([(8, 0), (13, 8), (12, 13), (8, 15), (4, 13), (3, 8), (6, 4), (7, 7)], fill=W)
    d.point([(6, 10), (9, 10)], fill=0)
    out["q_spiritfire"] = im

    im, d = canvas()   # LADY LUCK: a four-leaf clover
    for x, y in ((4, 1), (9, 1), (4, 6), (9, 6)):
        d.ellipse([x - 3, y, x + 2, y + 5], fill=W)
    d.line([(7, 9), (10, 15)], fill=W)
    out["q_ladyluck"] = im

    im, d = canvas()   # BIG SPENDER: a die
    d.rounded_rectangle([1, 1, 14, 14], radius=3, fill=W)
    for x, y in ((4, 4), (10, 4), (7, 7), (4, 10), (10, 10)):
        d.rectangle([x, y, x + 1, y + 1], fill=0)
    out["q_highroller"] = im

    im, d = canvas()   # SHARK WEEK: a fin over the waves
    d.polygon([(3, 11), (9, 1), (11, 11)], fill=W)
    for x in range(0, 16, 4):
        d.arc([x, 11, x + 4, 15], 180, 360, fill=W)
    out["q_sharkweek"] = im

    im, d = canvas()   # DANCE FLOOR: a mirror ball and its light
    d.ellipse([4, 4, 11, 11], fill=W)
    d.line([(4, 7), (11, 7)], fill=0)
    d.line([(7, 4), (7, 11)], fill=0)
    d.line([(7, 0), (7, 3)], fill=W)
    rays(d, 7.5, 7.5, 6, 8, 6, 0.4)
    out["q_dancefloor"] = im

    im, d = canvas()   # ANVIL RAIN: an anvil falling
    d.polygon([(1, 7), (12, 7), (15, 9), (10, 10), (10, 12), (12, 14), (3, 14), (5, 12), (5, 10), (2, 9)], fill=W)
    for x in (3, 7, 11):
        d.line([(x, 0), (x, 4)], fill=W)
    out["q_anvilrain"] = im

    im, d = canvas()   # PIN CUSHION: a cushion full of pins
    d.ellipse([1, 6, 14, 15], fill=W)
    for x, y in ((4, 2), (8, 1), (12, 3)):
        d.line([(x, y), (7, 9)], fill=W)
        d.rectangle([x - 1, y - 1, x, y], fill=W)
    out["q_pincushion"] = im

    im, d = canvas()   # BACK DOOR: a door, an arrow through it
    d.rectangle([5, 1, 13, 15], outline=W)
    d.point([(11, 8)], fill=W)
    d.line([(0, 8), (8, 8)], fill=W)
    d.polygon([(8, 5), (11, 8), (8, 11)], fill=W)
    out["q_backdoor"] = im

    im, d = canvas()   # SOULBOUND: a wisp in a ring of chain
    d.ellipse([0, 0, 15, 15], outline=W)
    d.ellipse([2, 2, 13, 13], outline=W)
    wisp(d, 7.5, 8.5, 0.8)
    out["q_soulbound"] = im

    im, d = canvas()   # SOUL FEAST: a scythe and a wisp
    d.line([(3, 15), (8, 2)], fill=W)
    d.arc([2, 0, 15, 10], 180, 300, fill=W)
    d.arc([2, 1, 15, 11], 180, 300, fill=W)
    wisp(d, 12, 11, 0.6)
    out["q_harvest"] = im

    im, d = canvas()   # SOUL STORM: a wisp under a bolt
    wisp(d, 5, 10, 0.9)
    bolt(d, 9, 0, 0.8)
    out["q_soulstorm"] = im

    im, d = canvas()   # SPIRIT WELL: a well, a wisp rising from it
    d.rectangle([2, 10, 13, 15], fill=W)
    d.rectangle([4, 11, 11, 13], fill=0)
    d.line([(1, 9), (14, 9)], fill=W)
    wisp(d, 7.5, 4, 0.7)
    out["q_spiritwell"] = im

    im, d = canvas()   # WISP WARDEN: a shield with a wisp
    d.polygon([(1, 1), (14, 1), (14, 8), (7.5, 15), (1, 8)], outline=W)
    wisp(d, 7.5, 7, 0.75)
    out["q_wispwarden"] = im

    im, d = canvas()   # AVATAR OF SOULS: a crowned wisp among wisps
    d.polygon([(4, 4), (5, 0), (7, 3), (8, 0), (10, 3), (11, 0), (12, 4)], fill=W)
    wisp(d, 8, 10, 1.0)
    d.point([(1, 8), (2, 12), (14, 9), (13, 13)], fill=W)
    out["q_soulavatar"] = im

    im, d = canvas()   # OATH OF SOULS: a wisp held in an open hand
    d.rectangle([2, 11, 13, 13], fill=W)
    for x in (2, 13):
        d.line([(x, 7), (x, 11)], fill=W)
    d.line([(4, 15), (11, 15)], fill=W)
    wisp(d, 7.5, 5, 0.8)
    out["o_souls"] = im
    return out


def white(im):
    rgba = Image.new("RGBA", im.size, (0, 0, 0, 0))
    rgba.putalpha(im.point(lambda v: 255 if v > 0 else 0))
    px = Image.new("RGBA", im.size, (255, 255, 255, 255))
    px.putalpha(rgba.getchannel("A"))
    return px


def sheet(path, pics):
    z, cols = 4, 8
    cw, ch = 16 * z + 24, 16 * z + 20
    out = Image.new("RGB", (cols * cw, ((len(pics) + cols - 1) // cols) * ch), (12, 11, 18))
    d = ImageDraw.Draw(out)
    for i, (k, im) in enumerate(pics.items()):
        x, y = (i % cols) * cw + 12, (i // cols) * ch + 4
        out.paste(Image.new("RGB", (16 * z, 16 * z), (232, 120, 60)), (x, y), white(im).resize((16 * z, 16 * z), Image.NEAREST))
        d.text((x - 8, y + 16 * z + 2), k[:14], fill=(200, 200, 200))
    out.save(path)


pics = make()
for k, im in pics.items():
    white(im).save(os.path.join(G, "tr_" + k + ".png"))
if os.environ.get("SHEET"):
    sheet(os.environ["SHEET"], pics)
print("stage 53 trait pictures: %d" % len(pics))
