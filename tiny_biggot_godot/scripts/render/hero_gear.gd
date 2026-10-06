class_name HeroGear
extends RefCounted
## Equipment shown on the hero. Every equipped piece paints a few pixels over
## the 12x14 hero sprite, shaped by the item's "shape" and coloured from its
## own icon, so a helm looks like the helm you picked up. All pieces are
## composed into one small texture per outfit (cached), drawn right after the
## hero with the same position, squash and mirroring. Visual only.

const W := 12
const H := 14
## Rows of the hero sprite: 0-6 head, 7-10 body, 11 legs, 12 feet.
## o = outline, 1 = main colour, 2 = dark, 3 = light, . = untouched.
const HEAD := {
	"helm": { 0: "....oooo....", 1: "...o1331o...", 2: "..o111111o..", 3: ".o12222221o." },
	"hood": { 0: "....oooo....", 1: "...o1111o...", 2: "..o111111o..", 3: ".o11222211o.", 4: ".o1......1o.", 5: ".o1......1o." },
	"hat": { 0: "....oooo....", 1: "...o1131o...", 2: "...o2222o...", 3: "o1111111111o" },
	"crown": { 0: "..o.o..o.o..", 1: "..1o1oo1o1..", 2: "..11111111..", 3: "..13122131.." },
	"mask": { 4: "..o111111o..", 5: "..o1o11o1o..", 6: "...o1221o..." },
}
const BODY := {
	"plate": { 7: ".o13111112o.", 8: "..11311112..", 9: "..11222212..", 10: "..o111112o.." },
	"robe": { 7: ".o11111111o.", 8: "..11133111..", 9: "..11133111..", 10: "..11111111..", 11: "..o122221o.." },
	"leather": { 7: ".o11111111o.", 8: "..12111121..", 9: "..11222211..", 10: "..o111111o.." },
	"cloak": { 7: ".o13111131o.", 10: "o1........1o", 11: "o1........1o", 12: ".o........o." },
}
const FEET := {
	"boots": { 12: "...12..12..." },
	"greaves": { 11: "...13..31...", 12: "...12..21..." },
}
const HANDS := { 9: ".1........1." }
const NECK := { 7: "....2..2....", 8: ".....31....." }
const TRINKET := { 10: ".......13..." }
const RING1 := { 9: "3..........." }
const RING2 := { 9: "...........3" }
## Paint order: later pieces go over earlier ones.
const ORDER := ["body", "feet", "hands", "head", "neck", "trinket", "ring1", "ring2"]

static var _cache := {}
static var _pal := {}

## [main, dark, light, outline] taken from the item's icon.
static func palette(g: Dictionary) -> Array:
	var key: String = g["sprite"]
	if _pal.has(key):
		return _pal[key]
	var counts := {}
	var img := Img.image(key)      # from the atlas kept in memory: nothing is read back from the graphics card
	if img != null:
		for y in img.get_height():
			for x in img.get_width():
				var c := img.get_pixel(x, y)
				if c.a < 0.5 or c.get_luminance() < 0.09:
					continue
				counts[c] = counts.get(c, 0) + 1
	var main := TB.c(g["cols"][0])
	var best := 0
	for c in counts:
		if counts[c] > best:
			best = counts[c]
			main = c
	var dark: Color = main.darkened(0.35)
	var light: Color = main.lightened(0.45)
	for c in counts:
		if c == main:
			continue
		if c.get_luminance() < main.get_luminance() and (dark == main.darkened(0.35) or c.get_luminance() < dark.get_luminance()):
			dark = c
		if c.get_luminance() > main.get_luminance() and (light == main.lightened(0.45) or c.get_luminance() > light.get_luminance()):
			light = c
	# The outline is tinted by the piece's own colour, as in the art of stage 5 (tools/art).
	_pal[key] = [main, dark, light, Color.from_hsv(main.h, 0.6, 0.11)]
	return _pal[key]

static func _pattern(slot: String, g: Dictionary) -> Dictionary:
	var shape: String = g.get("shape", "")
	match slot:
		"head": return HEAD.get(shape, HEAD["helm"])
		"body": return BODY.get(shape, BODY["leather"])
		"feet": return FEET.get(shape, FEET["boots"])
		"hands": return HANDS
		"neck": return NECK
		"trinket": return TRINKET
		"ring1": return RING1
		"ring2": return RING2
	return {}

## The outfit texture for the player's current gear, or null with nothing equipped.
static func texture(p: Player) -> Texture2D:
	var key := ""
	for slot in ORDER:
		var g = p.gear.get(slot)
		key += (g["id"] if g != null else "") + "|"
	if _cache.has(key):
		return _cache[key]
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	var any := false
	for slot in ORDER:
		var g = p.gear.get(slot)
		if g == null:
			continue
		any = true
		var pal := palette(g)
		var pat := _pattern(slot, g)
		for row in pat:
			var line: String = pat[row]
			for x in W:
				match line[x]:
					"o": img.set_pixel(x, row, pal[3])
					"1": img.set_pixel(x, row, pal[0])
					"2": img.set_pixel(x, row, pal[1])
					"3": img.set_pixel(x, row, pal[2])
	var tex: Texture2D = ImageTexture.create_from_image(img) if any else null
	if _cache.size() > 256:
		_cache.clear()
	_cache[key] = tex
	return tex

## Draws the outfit where Gfx.sp drew the hero (origin at the bottom centre).
static func draw(ci: CanvasItem, p: Player, x: float, y: float, zx: float = 1.0, zy: float = 1.0,
		mirror: bool = false, alpha: float = 1.0) -> void:
	if p == null or not Meta.opts.get("show_gear", true):
		return
	var tex := texture(p)
	if tex == null:
		return
	var px := roundf(x)
	var py := roundf(y)
	var mod := Color(1, 1, 1, alpha)
	if zx == 1.0 and zy == 1.0 and not mirror:
		ci.draw_texture(tex, Vector2(px - W / 2, py - H), mod)
		return
	ci.draw_set_transform(Vector2(px, py), 0.0, Vector2(zx, zy))
	var r := Rect2(-W / 2, -H, -W, H) if mirror else Rect2(-W / 2, -H, W, H)   # negative width: flipped in place
	ci.draw_texture_rect(tex, r, false, mod)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
