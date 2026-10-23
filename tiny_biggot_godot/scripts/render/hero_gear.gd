class_name HeroGear
extends RefCounted
## Equipment shown on the hero. Every equipped piece is painted over the hero's
## picture, shaped by the item's "shape" and coloured from its own icon, so a
## helm looks like the helm you picked up. All pieces are composed into one
## small texture per hero and outfit (cached), drawn right after the hero with
## the same position, squash and mirroring. Visual only.
##
## 59.1 (V2, his word, 23 Oct: "make the armour on the hero in the new look too"): drawn like the
## new heroes, at TB.D pixels to each of the game's (24 x 28 over the 12 x 14 hero), with their
## dark outline and five shades. What the hero wears on the body, feet and hands takes the shape
## of that hero's own picture, and its folds and lights: each of the hero's pixels there is given
## the shade of its brightness among them, in the item's colours. What goes on the head, the
## neck, the belt, the rings and the shield in the off hand are shapes of their own.
## 59.3 (his "little bit more pixelated and to fit my previous style"): the heroes have a thick
## near-black outline and dark lines now; armour over them keeps those (_lines), so an armoured
## hero is outlined like a bare one.

const W := 12      # the hero, in the game's pixels
const H := 14
const DW := 24     # the outfit's pixels: two to each of the game's (TB.D)
const DH := 28
const CX := 12.0   # the new heroes stand in the middle of their picture
## Shades: o outline, 0 deepest, 2 dark, 1 main, 3 light, 4 shine.
const ORDER := ["body", "feet", "hands", "head", "neck", "trinket", "ring1", "ring2", "offhand"]

static var _cache := {}
static var _pal := {}
static var _heroes := {}

## The item's colours: its main colour (the commonest in its icon) and a step apart each way.
static func palette(g: Dictionary) -> Dictionary:
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
	var v := clampf(main.v, 0.35, 0.85)
	var s := main.s
	var h := main.h
	_pal[key] = {
		"o": Color.from_hsv(h, 0.6, 0.11),
		"0": Color.from_hsv(h, minf(1.0, s * 1.15 + 0.1), v * 0.38),
		"2": Color.from_hsv(h, minf(1.0, s * 1.1 + 0.05), v * 0.62),
		"1": Color.from_hsv(h, s, v),
		"3": Color.from_hsv(h, s * 0.8, minf(1.0, v * 1.28 + 0.06)),
		"4": Color.from_hsv(h, s * 0.45, minf(1.0, v * 1.55 + 0.15)),
	}
	return _pal[key]

## The hero's picture at the outfit's size: where it is solid, how bright each pixel is, and its
## neck (the narrowest row between the head and the body).
static func _hero(name: String) -> Dictionary:
	if _heroes.has(name):
		return _heroes[name]
	var img := Img.image(name)
	if img != null and img.get_size() != Vector2i(DW, DH):
		img = img.duplicate()
		img.resize(DW, DH, Image.INTERPOLATE_NEAREST)
	var solid := PackedByteArray()
	var bright := PackedFloat32Array()
	solid.resize(DW * DH)
	bright.resize(DW * DH)
	for y in DH:
		for x in DW:
			var c := img.get_pixel(x, y) if img != null else Color(0.5, 0.5, 0.5, 1)
			solid[y * DW + x] = 1 if c.a >= 0.5 else 0
			bright[y * DW + x] = c.get_luminance()
	var neck := 9
	var narrow := 99
	for y in range(7, 14):
		var n := 0
		for x in DW:
			n += solid[y * DW + x]
		if n > 0 and n < narrow:
			narrow = n
			neck = y
	var info := { "solid": solid, "bright": bright, "neck": neck }
	_heroes[name] = info
	return info

static func _in(hi: Dictionary, x: int, y: int) -> bool:
	return x >= 0 and x < DW and y >= 0 and y < DH and hi["solid"][y * DW + x] == 1

## On the hero's own outline.
static func _edge(hi: Dictionary, x: int, y: int) -> bool:
	return not _in(hi, x + 1, y) or not _in(hi, x - 1, y) or not _in(hi, x, y + 1) or not _in(hi, x, y - 1)

## The solid pixels of a row, left to right.
static func _row(hi: Dictionary, y: int) -> Array:
	var out := []
	for x in DW:
		if hi["solid"][y * DW + x] == 1:
			out.append(x)
	return out

## Light from the top left, as on the new pictures: a shade by place.
static func _lit(x: float, y: float, cx: float = CX, cy: float = 4.0) -> String:
	var d := (x - cx) * 0.9 + (y - cy) * 0.5
	if d < -6.0:
		return "3"
	if d < 2.0:
		return "1"
	if d < 7.0:
		return "2"
	return "0"

static func _ell(x: int, y: int, cx: float, cy: float, rx: float, ry: float) -> bool:
	return pow((x + 0.5 - cx) / rx, 2) + pow((y + 0.5 - cy) / ry, 2) <= 1.0

## A shape's outer pixels become its outline.
static func _outline(c: Dictionary) -> Dictionary:
	var out := c.duplicate()
	for p: Vector2i in c:
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			if not c.has(p + d):
				out[p] = "o"
				break
	return out

## Each covered pixel takes the shade of its brightness among the covered pixels: the hero's own
## folds and lights, in the item's colours.
static func _transfer(hi: Dictionary, cells: Array) -> Dictionary:
	var ranked := []
	for p: Vector2i in cells:
		ranked.append([hi["bright"][p.y * DW + p.x], p.y, p.x])
	ranked.sort_custom(func(a, b): return a[0] < b[0] or (a[0] == b[0] and (a[1] < b[1] or (a[1] == b[1] and a[2] < b[2]))))
	var out := {}
	var n := ranked.size()
	for i in n:
		var f := float(i) / maxf(1.0, n - 1)
		var lv := "0" if f < 0.1 else ("2" if f < 0.35 else ("1" if f < 0.72 else ("3" if f < 0.93 else "4")))
		out[Vector2i(ranked[i][2], ranked[i][1])] = lv
	return out

# ---------- on the head: shapes of their own ----------
static func _head(shape: String) -> Dictionary:
	var c := {}
	match shape:
		"hood":
			for y in 13:
				for x in range(1, 23):
					var outer := _ell(x, y, CX, 8.4, 9.4, 8.6) or (y >= 9 and x >= 3 and x <= 20)
					if outer and not _ell(x, y, CX, 8.4, 5.0, 4.6):
						c[Vector2i(x, y)] = _lit(x, y, CX, 5.0)
			for p: Vector2i in c.keys():
				for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					if _ell(p.x + d.x, p.y + d.y, CX, 8.4, 5.0, 4.6):
						c[p] = "0"      # the shadow inside the hood
			for p in [Vector2i(7, 1), Vector2i(8, 1), Vector2i(5, 2), Vector2i(6, 2)]:
				if c.has(p):
					c[p] = "4"
		"hat":
			for y in 5:
				for x in range(7, 17):
					if y == 0 and (x == 7 or x == 16):
						continue
					c[Vector2i(x, y)] = _lit(x, y, CX, 1.0)
			for x in range(7, 17):
				c[Vector2i(x, 4)] = "0"      # the band
			for x in range(2, 22):
				c[Vector2i(x, 5)] = "3" if x < 12 else "1"
			for x in range(1, 23):
				c[Vector2i(x, 6)] = _lit(x, 6, CX, 3.0)
			for x in range(3, 21):
				c[Vector2i(x, 7)] = "0"
			for p in [Vector2i(8, 1), Vector2i(9, 1), Vector2i(8, 2)]:
				c[p] = "4"
		"crown":
			var points := [[4, 6], [7, 9], [10, 13], [14, 16], [17, 19]]
			for i in points.size():
				var a0: int = points[i][0]
				var a1: int = points[i][1]
				var top := 0 if i == 2 else 1
				for y in range(top, 3):
					for x in range(a0, a1 + 1):
						if y == top and x != a0 + (a1 - a0) / 2 and x != a0 + (a1 - a0 + 1) / 2:
							continue
						c[Vector2i(x, y)] = "3" if x < 12 else "1"
			for y in [3, 4, 5]:
				for x in range(4, 20):
					c[Vector2i(x, y)] = "3" if y == 3 else ("1" if y == 4 else "2")
			for x in [7, 11, 12, 16]:
				c[Vector2i(x, 4)] = "4"      # the stones
		"mask":
			for y in range(5, 11):
				for x in range(6, 18):
					if (y == 5 or y == 10) and (x == 6 or x == 17):
						continue
					c[Vector2i(x, y)] = _lit(x, y, CX, 7.0)
			for x in [8, 9, 14, 15]:
				c.erase(Vector2i(x, 7))      # the eye holes
			for x in range(10, 14):
				c[Vector2i(x, 9)] = "0"
			c[Vector2i(7, 6)] = "4"
		_:   # a helm: the dome, the cheek guards and the nose guard, the face left open
			for y in 10:
				for x in DW:
					var dome := y <= 4 and _ell(x, y, CX, 6.6, 8.8, 6.9)
					var cheek := y >= 5 and y <= 9 and ((x >= 3 and x <= 6) or (x >= 17 and x <= 20)) and not (y == 9 and (x == 3 or x == 20))
					var nose := y >= 5 and y <= 7 and (x == 11 or x == 12)
					if dome or cheek or nose:
						c[Vector2i(x, y)] = _lit(x, y)
			for x in range(3, 21):
				if c.has(Vector2i(x, 4)):
					c[Vector2i(x, 4)] = "3" if x < 12 else "1"
			for p in [Vector2i(7, 1), Vector2i(8, 1), Vector2i(6, 2), Vector2i(7, 2), Vector2i(5, 3)]:
				c[p] = "4"
	return _outline(c)

## A shield in the off hand.
static func _offhand() -> Dictionary:
	var c := {}
	var rows := { 14: [0, 7], 15: [0, 7], 16: [0, 7], 17: [0, 7], 18: [0, 7], 19: [0, 7], 20: [0, 7], 21: [1, 6], 22: [2, 5], 23: [3, 4] }
	for y in rows:
		for x in range(rows[y][0], rows[y][1] + 1):
			c[Vector2i(x, y)] = _lit(x, y, 3.5, 17.0)
	for p in [Vector2i(3, 17), Vector2i(4, 17), Vector2i(3, 18), Vector2i(4, 18)]:
		c[p] = "4"
	return _outline(c)

## The hero's own near-black outline and lines stay over the armour.
static func _lines(hi: Dictionary, c: Dictionary) -> Dictionary:
	for p: Vector2i in c:
		if hi["bright"][p.y * DW + p.x] < 0.1:
			c[p] = "o"
	return c

# ---------- on the body, the feet and the hands: the hero's own shape ----------
static func _body(shape: String, hi: Dictionary) -> Dictionary:
	var top: int = hi["neck"] + 1
	var bot := 24 if shape == "robe" else (25 if shape == "cloak" else 21)
	var cells := []
	for y in range(top, bot + 1):
		var xs := _row(hi, y)
		if xs.is_empty():
			continue
		for x: int in xs:
			if shape == "cloak" and y > top + 1 and x > xs[0] + 3 and x < xs[-1] - 3:
				continue      # a cloak hangs at the sides
			cells.append(Vector2i(x, y))
	var c := _transfer(hi, cells)
	for p: Vector2i in cells:
		match shape:
			"plate":      # plates: a dark seam every fourth row, lit just below it
				var k := (p.y - top) % 4
				if k == 3 and c[p] != "4":
					c[p] = "0"
				elif k == 0 and p.y > top and (c[p] == "2" or c[p] == "1"):
					c[p] = "3"
			"leather":    # a belt with its buckle
				if p.y == bot - 2 or p.y == bot - 1:
					c[p] = "4" if p.x == 11 or p.x == 12 else "0"
			"robe":       # a sash, then folds down to the hem
				if p.y == top + 6:
					c[p] = "3"
				elif p.y >= top + 7 and (p.x == 8 or p.x == 15):
					c[p] = "0"
			"cloak":      # the clasp
				if p.y == top and (p.x == 11 or p.x == 12):
					c[p] = "4"
	for p: Vector2i in cells:
		var clasp := shape == "cloak" and p.y == top and (p.x == 11 or p.x == 12)
		if (_edge(hi, p.x, p.y) or p.y == top) and not clasp:
			c[p] = "o"
	return _lines(hi, c)

static func _feet(shape: String, hi: Dictionary) -> Dictionary:
	var top := 24 if shape == "boots" else 21      # greaves come up over the shins
	var cells := []
	for y in range(top, DH):
		for x: int in _row(hi, y):
			cells.append(Vector2i(x, y))
	var c := _transfer(hi, cells)
	for p: Vector2i in cells:
		if p.y == top or (shape == "greaves" and (p.y == top + 1 or p.y == top + 2) and (c[p] == "1" or c[p] == "2")):
			c[p] = "3"
		if _edge(hi, p.x, p.y):
			c[p] = "o"
	return _lines(hi, c)

static func _hands(hi: Dictionary) -> Dictionary:
	var cells := []
	for y in range(17, 21):
		var xs := _row(hi, y)
		if xs.size() >= 6:
			for x in xs.slice(0, 3) + xs.slice(xs.size() - 3):
				cells.append(Vector2i(x, y))
	var c := _transfer(hi, cells)
	for p: Vector2i in cells:
		if p.y == 17:
			c[p] = "3"
		if _edge(hi, p.x, p.y):
			c[p] = "o"
	return _lines(hi, c)

# ---------- small pieces ----------
## An amulet: its chain, and the stone on the chest.
static func _neck(hi: Dictionary) -> Dictionary:
	var top: int = hi["neck"] + 1
	var c := {}
	for i in 4:
		c[Vector2i(8 + i, top + i)] = "2"
		c[Vector2i(15 - i, top + i)] = "2"
	var stone := {}
	for y in range(top + 3, top + 6):
		for x in range(10, 14):
			stone[Vector2i(x, y)] = "1"
	stone[Vector2i(11, top + 4)] = "4"
	stone[Vector2i(12, top + 4)] = "3"
	c.merge(_outline(stone), true)
	return c

## A charm at the belt.
static func _trinket() -> Dictionary:
	var c := {}
	for y in range(19, 23):
		for x in range(15, 19):
			c[Vector2i(x, y)] = "1"
	c[Vector2i(16, 20)] = "4"
	return _outline(c)

## A ring on a hand.
static func _ring(hi: Dictionary, left: bool) -> Dictionary:
	var xs := _row(hi, 18)
	if xs.is_empty():
		return {}
	var x: int = xs[0] + 1 if left else xs[-1] - 2
	return { Vector2i(x, 18): "4", Vector2i(x + 1, 18): "1", Vector2i(x, 19): "1", Vector2i(x + 1, 19): "2" }

static func _piece(slot: String, g: Dictionary, hi: Dictionary) -> Dictionary:
	var shape: String = g.get("shape", "")
	match slot:
		"head": return _head(shape)
		"body": return _body(shape, hi)
		"feet": return _feet(shape, hi)
		"hands": return _hands(hi)
		"neck": return _neck(hi)
		"trinket": return _trinket()
		"ring1": return _ring(hi, true)
		"ring2": return _ring(hi, false)
		"offhand": return _offhand()
	return {}

## The outfit texture for the player's current gear on this hero, or null with nothing equipped.
static func texture(p: Player, hero: String) -> Texture2D:
	var key := hero + "|"
	for slot in ORDER:
		var g = p.gear.get(slot)
		key += (g["id"] if g != null else "") + "|"
	if _cache.has(key):
		return _cache[key]
	var img := Image.create(DW, DH, false, Image.FORMAT_RGBA8)
	var any := false
	var hi := _hero(hero)
	for slot in ORDER:
		var g = p.gear.get(slot)
		if g == null:
			continue
		any = true
		var pal := palette(g)
		var cells := _piece(slot, g, hi)
		for at: Vector2i in cells:
			if at.x >= 0 and at.x < DW and at.y >= 0 and at.y < DH:
				img.set_pixelv(at, pal[cells[at]])
	var tex: Texture2D = null
	if any:
		var it := ImageTexture.create_from_image(img)
		it.set_size_override(Vector2i(W, H))      # drawn at the hero's size, with the finer pixels
		tex = it
	if _cache.size() > 256:
		_cache.clear()
	_cache[key] = tex
	return tex

## Draws the outfit where Gfx.sp drew the hero (origin at the bottom centre).
static func draw(ci: CanvasItem, p: Player, x: float, y: float, zx: float = 1.0, zy: float = 1.0,
		mirror: bool = false, alpha: float = 1.0, hero: String = "") -> void:
	if p == null or not Meta.opts.get("show_gear", true):
		return
	var tex := texture(p, hero if hero != "" else String(p.hero["sprite"]))
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
