# Stage 37.2 charms (his word, 9 Oct: "Ideas for sprites for new stuff"; our own look): a charm is
# a small TOKEN, a coin on a loop of string with a symbol struck into it. 10x12 each: the disc in
# a metal's colours and a 5x5 symbol. Run from the project folder:
#   python3 tools/art/stage37_charms.py   (ART_OUT=<folder> for a preview; then tools/bake_atlas.sh)
import os
from PIL import Image

G = os.environ.get("ART_OUT", "assets/graphics/")
OUT = (20, 15, 28)

DISC = [
    "....ss....",
    "...s..s...",
    "....ss....",
    "..oooooo..",
    ".o111111o.",
    "o11222211o",
    "o12222221o",
    "o12222221o",
    "o12222221o",
    "o11222213o",
    ".o133331o.",
    "..oooooo..",
]
# symbol rows: 5x5, placed with its top-left at (3, 5) - '#' struck, '.' none
SYM = {
    "star": ["..#..", ".###.", "#####", ".#.#.", "#...#"],
    "heart": [".#.#.", "#####", "#####", ".###.", "..#.."],
    "skull": [".###.", "#.#.#", "#####", ".###.", ".#.#."],
    "eye": [".....", ".###.", "##.##", ".###.", "....."],
    "fang": ["#...#", "##.##", "#####", ".#.#.", ".#.#."],
    "leaf": ["...##", "..###", ".###.", "###..", "#...."],
    "flame": ["..#..", ".##..", ".###.", "#####", ".###."],
    "drop": ["..#..", ".###.", ".###.", "#####", ".###."],
    "bolt": ["...##", "..##.", ".####", "..##.", ".##.."],
    "moon": [".###.", "##...", "#....", "##...", ".###."],
    "sun": ["#.#.#", ".###.", "#####", ".###.", "#.#.#"],
    "cross": ["..#..", "..#..", "#####", "..#..", "..#.."],
    "arrow": ["..#..", ".###.", "#.#.#", "..#..", "..#.."],
    "spiral": ["####.", "#..#.", "#.##.", "#....", "#####"],
    "coin": [".###.", "#.#.#", "#.##.", "#.#.#", ".###."],
    "key": [".##..", "#..#.", ".##..", "..###", "..#.#"],
    "wing": ["#....", "##...", "###..", "####.", "#####"],
    "shield": ["#####", "#.#.#", "#####", ".###.", "..#.."],
    "sword": ["....#", "...#.", "#.#..", ".#...", "#.#.."],
    "clover": [".#.#.", "#####", ".###.", "#####", ".#.#."],
    "hourglass": ["#####", ".###.", "..#..", ".###.", "#####"],
    "crown": ["#.#.#", "#####", "#####", ".....", "#####"],
    "die": ["#####", "#.#.#", "#####", "#.#.#", "#####"],
    "wave": [".....", ".#..#", "#.##.", ".....", "#.##."],
    "snow": ["#.#.#", ".###.", "##.##", ".###.", "#.#.#"],
    "feather": ["...##", "..###", ".###.", "##...", "#...."],
    "chain": ["##...", "#.##.", ".#.#.", ".##.#", "...##"],
    "gem": [".###.", "#####", "#####", ".###.", "..#.."],
    "rune": ["#...#", "##.##", "#.#.#", "#...#", "#...#"],
    "bone": ["#...#", ".#.#.", "..#..", ".#.#.", "#...#"],
}
# metal: (rim light, face, rim dark / shade, symbol)
METAL = {
    "bronze": ((232, 168, 104), (200, 120, 64), (138, 74, 40), (90, 44, 22)),
    "silver": ((232, 238, 248), (176, 184, 200), (104, 110, 128), (58, 60, 78)),
    "gold": ((255, 240, 176), (242, 201, 76), (200, 150, 58), (138, 90, 26)),
    "jade": ((184, 232, 168), (99, 184, 79), (58, 122, 42), (24, 70, 30)),
    "ruby": ((255, 138, 138), (216, 68, 60), (138, 42, 51), (255, 220, 200)),
    "obsidian": ((106, 94, 128), (58, 52, 72), (32, 28, 44), (232, 111, 180)),
    "bone": ((244, 236, 216), (216, 204, 180), (168, 152, 128), (90, 70, 50)),
    "azure": ((143, 216, 255), (77, 155, 230), (42, 74, 138), (232, 248, 255)),
}
# charm id -> (symbol, metal)
CHARMS = {
    "ch_star": ("star", "gold"), "ch_heart": ("heart", "ruby"), "ch_skull": ("skull", "bone"),
    "ch_eye": ("eye", "azure"), "ch_fang": ("fang", "bone"), "ch_leaf": ("leaf", "jade"),
    "ch_flame": ("flame", "bronze"), "ch_drop": ("drop", "jade"), "ch_bolt": ("bolt", "azure"),
    "ch_moon": ("moon", "silver"), "ch_sun": ("sun", "gold"), "ch_cross": ("cross", "silver"),
    "ch_arrow": ("arrow", "bronze"), "ch_spiral": ("spiral", "obsidian"), "ch_coin": ("coin", "gold"),
    "ch_key": ("key", "bronze"), "ch_wing": ("wing", "silver"), "ch_shield": ("shield", "silver"),
    "ch_sword": ("sword", "bronze"), "ch_clover": ("clover", "jade"), "ch_hourglass": ("hourglass", "gold"),
    "ch_crown": ("crown", "gold"), "ch_die": ("die", "bone"), "ch_wave": ("wave", "azure"),
    "ch_snow": ("snow", "azure"), "ch_feather": ("feather", "silver"), "ch_chain": ("chain", "obsidian"),
    "ch_gem": ("gem", "ruby"), "ch_rune": ("rune", "obsidian"), "ch_bone": ("bone", "bone"),
}


def token(dst, sym, metal):
    light, face, dark, mark = METAL[metal]
    im = Image.new("RGBA", (10, 12), (0, 0, 0, 0))
    for y, row in enumerate(DISC):
        for x, ch in enumerate(row):
            c = {"o": OUT, "1": light, "2": face, "3": dark, "s": (200, 184, 168)}.get(ch)
            if c:
                im.putpixel((x, y), c + (255,))
    for y, row in enumerate(SYM[sym]):
        for x, ch in enumerate(row):
            if ch == "#":
                im.putpixel((x + 2 + (1 if x >= 0 else 0), y + 5), mark + (255,))
    im.save(G + dst + ".png")


def bracelet():
    """CHARM BRACELET (relic, 10x10): a chain in a ring with three tokens hanging from it."""
    rows = [
        "..oooooo..",
        ".oSssssSo.",
        "oSo....oSo",
        "oso....oso",
        "oSo....oSo",
        ".oSssssSo.",
        "..oqoboro.",
        "..oQoBoRo.",
        "...o.o.o..",
        "..........",
    ]
    pal = {"o": OUT, "s": (200, 204, 216), "S": (139, 143, 156), "q": (242, 201, 76), "Q": (200, 150, 58),
           "b": (77, 155, 230), "B": (42, 74, 138), "r": (216, 68, 60), "R": (138, 42, 51)}
    im = Image.new("RGBA", (10, 10), (0, 0, 0, 0))
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch in pal:
                im.putpixel((x, y), pal[ch] + (255,))
    im.save(G + "relic_charmbracelet.png")


if __name__ == "__main__":
    for cid, (sym, metal) in CHARMS.items():
        token(cid, sym, metal)
    bracelet()
    print("stage 37 charms: %d and the bracelet" % len(CHARMS))
