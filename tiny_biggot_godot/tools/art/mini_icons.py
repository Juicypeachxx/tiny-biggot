# 8.2 (his ask, 6 Oct): 7x7 icons that sit after a keyword in coloured text and in the HUD's stat
# column. Original pixel art. Run: python3 tools/art/mini_icons.py  (writes assets/graphics/mi_*.png)
import os, sys
from PIL import Image
OUT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(__file__), "..", "..", "assets", "graphics")
# '.' clear, 'o' dark outline, 'a' main, 'b' light, 'c' dark tone
ICONS = {
	"heart": ("#d8443c", [".oo.oo.", "oabobao", "oaaaaao", "oaaaaao", ".oaaao.", "..oao..", "...o..."]),
	"gold": ("#f2c94c", ["..ooo..", ".oaaao.", "oabaaco", "oabaaco", "oaaaaco", ".oacco.", "..ooo.."]),
	"dmg": ("#e8e0d0", ["......b", ".....ba", "....baa", "c..baa.", ".cbaa..", "..cc...", ".c.c..."]),
	"rate": ("#f2c94c", [".......", "a..a...", ".a..a..", "..a..a.", ".a..a..", "a..a...", "......."]),
	"crit": ("#f2c94c", ["...o...", "..oao..", "ooabaoo", "oabbbao", "ooabaoo", "..oao..", "...o..."]),
	"armor": ("#8b8f9c", ["ooooooo", "oabbaao", "oabaaao", "oaaaaco", ".oaaco.", "..oco..", "...o..."]),
	"speed": ("#6fd3e0", [".......", "...oo..", "oo.oao.", "aaa.oao", "oo.oao.", "...oo..", "......."]),
	"luck": ("#63b84f", [".oo.oo.", "oaaoaao", "oaaoaao", ".oooooo", "oaaoaao", "oaao.o.", ".oo.o.."]),
	"str": ("#e8506a", ["..ooo..", ".oaaao.", "oaabao.", "oaaaao.", "oaaaooo", "oaaaaao", ".ooooo."]),
	"dex": ("#8fd84a", ["....oo.", "...oab.", "..oabo.", ".oabo..", "oabo...", "obo....", "oo....."]),
	"int": ("#4fc8f0", ["..ooo..", ".oabao.", "oabbbao", "oaaaaao", ".oaaao.", "..oao..", "..ooo.."]),
	"spi": ("#e88ad8", ["..o....", ".oao...", ".oabo..", "oabbao.", "oabbbao", ".oaaao.", "..ooo.."]),   # 52 SPIRIT
	"good": ("#f2c94c", ["a..a..a", ".a.a.a.", "..aaa..", "aaabaaa", "..aaa..", ".a.a.a.", "a..a..a"]),
	"evil": ("#d8443c", ["o.....o", "ooaaaoo", ".aoaoa.", ".aaaaa.", "..aoa..", "..a.a..", "......."]),
	"law": ("#6fd3e0", ["...a...", "aaaaaaa", "a..a..a", "a..a..a", "aa.a.aa", "...a...", "..aaa.."]),
	"chaos": ("#a35bd6", [".aaaaa.", "a.....a", "a.aaa.a", "a.a.a.a", "a.a...a", "a.aaaa.", "......."]),
	"potion": ("#e8506a", ["..ooo..", "..oao..", ".oaaao.", "oabaaao", "oaaaaao", "oaaaaco", ".ooooo."]),
}
def hx(h):
	h = h.lstrip("#"); return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))
def shade(c, k):
	return tuple(max(0, min(255, int(v * k))) for v in c)
for name, (col, rows) in ICONS.items():
	base = hx(col)
	pal = { "o": (20, 15, 28, 255), "a": base + (255,), "b": shade(base, 1.35) + (255,), "c": shade(base, 0.65) + (255,) }
	im = Image.new("RGBA", (7, 7), (0, 0, 0, 0))
	for y, r in enumerate(rows):
		for x, ch in enumerate(r):
			if ch in pal:
				im.putpixel((x, y), pal[ch])
	im.save(os.path.join(OUT, "mi_" + name + ".png"))
print("wrote", len(ICONS), "icons to", OUT)
