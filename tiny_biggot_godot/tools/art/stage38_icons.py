# Stage 38 icons (his word, 9 Oct: alignment and loot; our own pixels): four pieces that grow with an
# alignment, the DOWSING ROD and the JEWELER'S LOUPE.
# Run from the project folder: python3 tools/art/stage38_icons.py   (ART_OUT=<folder>: a preview)
import os
from PIL import Image

G = os.environ.get("ART_OUT", "assets/graphics/")
OUT = "#140f1c"


def grid(dst, rows, pal):
    w = max(len(r) for r in rows)
    im = Image.new("RGBA", (w, len(rows)), (0, 0, 0, 0))
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch in pal:
                c = pal[ch].lstrip("#")
                im.putpixel((x, y), (int(c[0:2], 16), int(c[2:4], 16), int(c[4:6], 16), 255))
    im.save(G + dst + ".png")


def M(rows):
    return [r + r[::-1] for r in rows]


GOLDC = {"q": "#f2c94c", "Q": "#c8963a", "y": "#fff0b0"}

if __name__ == "__main__":
    # SAINT'S SIGIL: a gold sun disc on a chain (GOOD).
    grid("g_saintsigil", M([
        "......",
        ".q...q",
        "..q.oo",
        "...oqq",
        "..oqyy",
        "qoqyqq",
        "..oqyq",
        "...oqq",
        "..q.oo",
        ".q...q",
        "......",
        "......",
    ]), dict(GOLDC, o=OUT))
    # DEVIL'S BARGAIN: a dark ring with a red horned stone (EVIL).
    grid("g_devilsbargain", M([
        "......",
        "...o.o",
        "...oro",
        "..orRr",
        "..orrr",
        "..ojoo",
        ".oj...",
        "oj....",
        "oj....",
        ".oj...",
        "..ojjj",
        "...ooo",
    ]), {"o": OUT, "r": "#d8443c", "R": "#ff8a8a", "j": "#4a3a5c"})
    # MAGISTRATE'S SEAL: a square blue seal with a scale mark (LAWFUL).
    grid("g_magistrateseal", [
        "............",
        ".oooooooooo.",
        ".obbbbbbbbo.",
        ".obBBqqBBbo.",
        ".obBqqqqBbo.",
        ".obBBqqBBbo.",
        ".obBqBBqBbo.",
        ".obBqBBqBbo.",
        ".obbbbbbbbo.",
        ".oooooooooo.",
        "....oQQo....",
        ".....oo.....",
    ], {"o": OUT, "b": "#2a4a8a", "B": "#4d9be6", "q": "#e8f8ff", "Q": "#8b8f9c"})
    # MADCAP'S BELLS: a jester's cap with two bells (CHAOTIC).
    grid("g_madcapbells", [
        ".oo......oo.",
        "oqqo....oyyo",
        "oqqoo..ooyyo",
        ".oo.pp.gg.o.",
        "...oppoggo..",
        "..opppogggo.",
        ".opppppgggo.",
        ".oppppggggo.",
        "oooooooooooo",
        "oyqyqyqyqyqo",
        "oooooooooooo",
        "............",
    ], {"o": OUT, "p": "#a35bd6", "g": "#63b84f", "q": "#f2c94c", "y": "#fff0b0"})
    # DOWSING ROD: a forked hazel stick with a gold tip.
    grid("o_dowsingrod", [
        "o..........o",
        "wo........ow",
        ".wo......ow.",
        "..wo....ow..",
        "...wo..ow...",
        "....wwww....",
        ".....ww.....",
        ".....wW.....",
        ".....wW.....",
        ".....wW.....",
        ".....oqo....",
        "......o.....",
    ], {"o": OUT, "w": "#a8703a", "W": "#7a4a2a", "q": "#f2c94c"})
    # JEWELER'S LOUPE (relic, 10x10): a lens on a ring with a sparkling gem in it.
    grid("relic_jewelersloupe", [
        "...oooo...",
        "..oiiiio..",
        ".oiccCcio.",
        ".oicCgcio.",
        ".oiccgcio.",
        "..oiiiio..",
        "...oIIo...",
        "...oIIo...",
        "....oo....",
        "..........",
    ], {"o": OUT, "i": "#c8ccd8", "I": "#8b8f9c", "c": "#8fd8ff", "C": "#e8f8ff", "g": "#e86fb4"})
    print("stage 38 icons: 6")
