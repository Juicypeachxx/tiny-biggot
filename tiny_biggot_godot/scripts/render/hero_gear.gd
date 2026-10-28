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

const W := 12      # the old hero, in the game's pixels
const H := 14
const CX := 12.0
## 66.3 (his word, 27 Oct, a picture of a floating helm: "armor doesnt fit"): the outfit is drawn at
## the hero picture's own pixels (48 x 56 for the heroes drawn on PixelLab, TB.D to each of the
## game's) and every piece is placed by the hero's own body, measured from the bottom of its picture
## (they share one build: the chin about 45 % of the picture up, the hips about 18 %): the head's
## pieces take its head's own width and top, the body's its chest, the feet its legs. Helms, hoods
## and masks are the hero's own head in the item's colours (so they fit whatever hair or hat is
## under them), with their guards, opening or eye holes; a hat and a crown sit on top of it.
## Shades: o outline, 0 deepest, 2 dark, 1 main, 3 light, 4 shine.
const ORDER := ["body", "feet", "hands", "head", "neck", "trinket", "ring1", "ring2", "offhand"]

## 66.4 (his word, 27 Oct, of the painted armour: "to še vedno deluje smešno in out of the place"): each
## hero has its pieces drawn on it on PixelLab (resprite/tools/gear_pieces.py): one strip a hero,
## assets/gear_pieces/<hero>.png, a cell of the picture's size for each of these, in this order. A
## piece worn is that cell in the item's colours (each pixel the shade of its brightness among the
## piece's); a hero or a piece without a drawing falls back to the shapes below. Amulets, rings and
## charms are small and stay shapes.
const PIECES := ["helm", "hood", "hat", "crown", "mask", "plate", "leather", "robe", "cloak", "boots", "greaves", "gloves", "shield"]
const PIECE_DIR := "res://assets/gear_pieces/"
static var _strips := {}

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

## The hero's picture, its pixels: where it is solid, how bright, and its build (all in its own pixels).
static func _hero(name: String) -> Dictionary:
	if _heroes.has(name):
		return _heroes[name]
	var img := Img.image(name)
	var w := img.get_width() if img != null else W * TB.D
	var h := img.get_height() if img != null else H * TB.D
	var solid := PackedByteArray()
	var bright := PackedFloat32Array()
	solid.resize(w * h)
	bright.resize(w * h)
	var ty := h
	var by := 0
	for y in h:
		for x in w:
			var c := img.get_pixel(x, y) if img != null else Color(0.5, 0.5, 0.5, 1)
			if c.a >= 0.5:
				solid[y * w + x] = 1
				ty = mini(ty, y)
				by = maxi(by, y)
			bright[y * w + x] = c.get_luminance()
	var info := { "name": name, "solid": solid, "bright": bright, "w": w, "h": h, "ty": ty, "by": by }
	var u := float(h) / 56.0                    # the build is measured in a 56-high picture's pixels
	var chin := by - roundi(25.0 * u)
	var hip := by - roundi(10.0 * u)
	info["chin"] = chin
	info["hip"] = hip
	info["eye"] = chin - roundi(7.0 * u)
	info["top"] = maxi(ty, chin - roundi(16.0 * u))   # the top of the head (a tall hat or horns rise above it)
	info["u"] = u
	# The head's middle and width: its widest run round the eyes, through the middle of the picture.
	var mid := w / 2
	var best := [mid - roundi(5 * u), mid + roundi(5 * u)]
	for y in range(info["eye"] - roundi(3 * u), info["eye"] + roundi(3 * u)):
		var r := _run(info, y, mid)
		if r.size() == 2 and r[1] - r[0] > best[1] - best[0] and r[1] - r[0] < roundi(18 * u):
			best = r
	info["hx0"] = best[0]
	info["hx1"] = best[1]
	info["hcx"] = (best[0] + best[1]) / 2.0
	info["tw"] = maxi(roundi(8 * u), (best[1] - best[0]) / 2 + roundi(3 * u))   # the chest's half width
	_heroes[name] = info
	return info

## The solid run of a row through x (or the nearest solid pixel to it): [left, right], or [].
static func _run(hi: Dictionary, y: int, x: int) -> Array:
	var c := -1
	for d in 7:
		if _in(hi, x - d, y):
			c = x - d
			break
		if _in(hi, x + d, y):
			c = x + d
			break
	if c < 0:
		return []
	var l := c
	while _in(hi, l - 1, y):
		l -= 1
	var r := c
	while _in(hi, r + 1, y):
		r += 1
	return [l, r]

static func _in(hi: Dictionary, x: int, y: int) -> bool:
	return x >= 0 and x < hi["w"] and y >= 0 and y < hi["h"] and hi["solid"][y * hi["w"] + x] == 1

## On the hero's own outline.
static func _edge(hi: Dictionary, x: int, y: int) -> bool:
	return not _in(hi, x + 1, y) or not _in(hi, x - 1, y) or not _in(hi, x, y + 1) or not _in(hi, x, y - 1)

## The hero's solid pixels in these rows, within this many pixels of the head's middle.
static func _cells(hi: Dictionary, y0: int, y1: int, half: float) -> Array:
	var out := []
	var cx: float = hi["hcx"]
	for y in range(maxi(0, y0), mini(hi["h"], y1 + 1)):
		for x in range(maxi(0, floori(cx - half)), mini(hi["w"], ceili(cx + half) + 1)):
			if _in(hi, x, y):
				out.append(Vector2i(x, y))
	return out

## Light from the top left, as on the new pictures: a shade by place.
static func _lit(x: float, y: float, cx: float = CX, cy: float = 4.0, u: float = 1.0) -> String:
	var d := ((x - cx) * 0.9 + (y - cy) * 0.5) / u
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
	var w: int = hi["w"]
	for p: Vector2i in cells:
		ranked.append([hi["bright"][p.y * w + p.x], p.y, p.x])
	ranked.sort_custom(func(a, b): return a[0] < b[0] or (a[0] == b[0] and (a[1] < b[1] or (a[1] == b[1] and a[2] < b[2]))))
	var out := {}
	var n := ranked.size()
	for i in n:
		var f := float(i) / maxf(1.0, n - 1)
		var lv := "0" if f < 0.1 else ("2" if f < 0.35 else ("1" if f < 0.72 else ("3" if f < 0.93 else "4")))
		out[Vector2i(ranked[i][2], ranked[i][1])] = lv
	return out

## The hero's own near-black outline and lines stay over the armour.
static func _lines(hi: Dictionary, c: Dictionary) -> Dictionary:
	var w: int = hi["w"]
	for p: Vector2i in c:
		if _in(hi, p.x, p.y) and hi["bright"][p.y * w + p.x] < 0.1:
			c[p] = "o"
	return c

## Covered pixels on the hero's outline, or at the given rows' edges, become the piece's outline.
static func _rim(hi: Dictionary, c: Dictionary, cells: Array, rows: Array = []) -> Dictionary:
	for p: Vector2i in cells:
		if _edge(hi, p.x, p.y) or p.y in rows:
			c[p] = "o"
	return c

# ---------- on the head ----------
static func _head(shape: String, hi: Dictionary) -> Dictionary:
	var u: float = hi["u"]
	var cx: float = hi["hcx"]
	var hw: float = (hi["hx1"] - hi["hx0"]) / 2.0 + 0.5
	var top: int = hi["top"]
	var eye: int = hi["eye"]
	var chin: int = hi["chin"]
	var c := {}
	match shape:
		"hood":   # the whole head in the item's colours but an opening for the face, falling to the shoulders
			var cells := _cells(hi, hi["ty"], chin, hw + 1)
			for x in range(floori(cx - hw - 1), ceili(cx + hw + 2)):
				for y in range(chin - roundi(4 * u), chin + roundi(3 * u)):
					if absf(x + 0.5 - cx) > hw - 2 * u and absf(x + 0.5 - cx) <= hw + 1.5:
						cells.append(Vector2i(x, y))
			var face_y := (eye + chin) / 2.0
			var keep := []
			for p: Vector2i in cells:
				if not _ell(p.x, p.y, cx, face_y, hw * 0.62, (chin - eye) * 0.75 + u):
					keep.append(p)
			c = _transfer(hi, keep)
			for p: Vector2i in keep:
				for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					if _ell(p.x + d.x, p.y + d.y, cx, face_y, hw * 0.62, (chin - eye) * 0.75 + u):
						c[p] = "0"      # the shadow inside the hood
			return _lines(hi, _outline(c))
		"mask":   # a band over the lower face, under the eyes
			var cells := _cells(hi, eye + roundi(2 * u), chin - roundi(2 * u), hw * 0.7)
			for p: Vector2i in cells:
				c[p] = _lit(p.x, p.y, cx, eye, u)
			for x in range(floori(cx - hw * 0.7), ceili(cx + hw * 0.7)):
				if c.has(Vector2i(x, eye + roundi(2 * u))):
					c[Vector2i(x, eye + roundi(2 * u))] = "3" if x < cx else "1"   # its lit top edge
			return _outline(c)
		"hat":    # a brim round the head at the eyes' height and a crown on top of it
			var brim := top + roundi((eye - top) * 0.55)
			var bw := hw + 4 * u
			for y in range(brim, brim + roundi(2 * u) + 1):
				for x in range(floori(cx - bw), ceili(cx + bw)):
					c[Vector2i(x, y)] = "3" if x < cx else "1"
			var cw := hw - 1.5 * u
			var ch := roundi(7 * u)
			for y in range(brim - ch, brim):
				for x in range(floori(cx - cw + (1 if y == brim - ch else 0)), ceili(cx + cw - (1 if y == brim - ch else 0))):
					c[Vector2i(x, y)] = _lit(x, y, cx, brim - ch, u)
			for x in range(floori(cx - cw), ceili(cx + cw)):
				c[Vector2i(x, brim - roundi(2 * u))] = "0"      # the band
			c[Vector2i(floori(cx - cw) + 2, brim - ch + 2)] = "4"
			return _outline(c)
		"crown":  # a band on the top of the head and its points above
			var cw := maxf(5 * u, hw - 2.5 * u)
			var band := top + roundi(1 * u)
			var bh := roundi(3 * u)
			for y in range(band, band + bh):
				for x in range(floori(cx - cw), ceili(cx + cw)):
					c[Vector2i(x, y)] = "3" if y == band else ("1" if y < band + bh - 1 else "2")
			var n := 5
			for i in n:
				var px := cx - cw + (2 * cw) * (i + 0.5) / n
				var ph := roundi((4 if i == 2 else 3) * u)
				for y in range(band - ph, band):
					var wd := 1.0 + (y - (band - ph)) * 0.6
					for x in range(floori(px - wd * 0.5), ceili(px + wd * 0.5)):
						c[Vector2i(x, y)] = "3" if x < cx else "1"
			for i in 3:
				c[Vector2i(roundi(cx - cw * 0.6 + cw * 0.6 * i), band + 1)] = "4"      # the stones
			return _outline(c)
		_:        # a helm: the head from its top to the eyes, cheek guards down its sides and a nose guard
			var cells := _cells(hi, hi["ty"], eye - 1, hw + 1)
			var g := maxi(2, roundi(2 * u))
			for y in range(eye - 1, chin - roundi(1 * u)):
				var r := _run(hi, y, roundi(cx))
				if r.size() == 2:
					for k in g:
						cells.append(Vector2i(r[0] + k, y))
						cells.append(Vector2i(r[1] - k, y))
			for y in range(eye - 1, eye + roundi(4 * u)):
				for k in maxi(1, roundi(u)):
					cells.append(Vector2i(roundi(cx) - k, y))
			c = _transfer(hi, cells)
			for p: Vector2i in cells:
				if p.y == eye - 2:
					c[p] = "3" if p.x < cx else "1"      # the brow ridge
			return _lines(hi, _outline(c))

## A shield in the off hand (at the hero's back side: the left of its picture).
static func _offhand(hi: Dictionary) -> Dictionary:
	var u: float = hi["u"]
	var c := {}
	var sw := roundi(8 * u)
	var sh := roundi(11 * u)
	var x0 := floori(hi["hcx"] - hi["tw"] - 3 * u)
	var y0: int = hi["chin"] + roundi(3 * u)
	for y in sh:
		var inset := maxi(0, y - (sh - sw / 2)) if y > sh - sw / 2 else 0
		for x in range(inset, sw - inset):
			c[Vector2i(x0 + x, y0 + y)] = _lit(x, y, sw / 2.0 - 1, sh * 0.4, u)
	for k in roundi(2 * u):
		for j in roundi(2 * u):
			c[Vector2i(x0 + sw / 2 - 1 + k, y0 + sh / 3 + j)] = "4"   # the boss
	return _outline(c)

# ---------- on the body, the feet and the hands: the hero's own shape ----------
static func _body(shape: String, hi: Dictionary) -> Dictionary:
	var u: float = hi["u"]
	var top: int = hi["chin"] + 1
	var bot: int = hi["by"] - roundi(2 * u) if shape == "robe" else (hi["by"] - roundi(4 * u) if shape == "cloak" else hi["hip"])
	var half: float = hi["tw"]
	var all := _cells(hi, top, bot, half)
	var cells := []
	var cx: float = hi["hcx"]
	for p: Vector2i in all:
		if shape == "cloak" and p.y > top + 2 * u and absf(p.x + 0.5 - cx) < half - 4 * u:
			continue      # a cloak hangs at the sides
		cells.append(p)
	var c := _transfer(hi, cells)
	var step := maxi(3, roundi(4 * u))
	for p: Vector2i in cells:
		match shape:
			"plate":      # plates: a dark seam every few rows, lit just below it
				var k := (p.y - top) % step
				if k == step - 1 and c[p] != "4":
					c[p] = "0"
				elif k == 0 and p.y > top and (c[p] == "2" or c[p] == "1"):
					c[p] = "3"
			"leather":    # a belt with its buckle
				if p.y >= bot - roundi(2 * u) + 1:
					c[p] = "4" if absf(p.x + 0.5 - cx) < 1.5 * u else "0"
			"robe":       # a sash, then folds down to the hem
				if p.y >= hi["hip"] - roundi(1 * u) and p.y <= hi["hip"]:
					c[p] = "3"
				elif p.y > hi["hip"] and (absi(p.x - roundi(cx - 3 * u)) == 0 or absi(p.x - roundi(cx + 3 * u)) == 0):
					c[p] = "0"
			"cloak":      # the clasp
				if p.y <= top + 1 and absf(p.x + 0.5 - cx) < 1.5 * u:
					c[p] = "4"
	for p: Vector2i in cells:
		var clasp := shape == "cloak" and p.y <= top + 1 and absf(p.x + 0.5 - cx) < 1.5 * u
		if (_edge(hi, p.x, p.y) or p.y == top or absf(p.x + 0.5 - cx) >= half - 0.5) and not clasp:
			c[p] = "o"
	return _lines(hi, c)

static func _feet(shape: String, hi: Dictionary) -> Dictionary:
	var u: float = hi["u"]
	var top: int = hi["by"] - roundi((5 if shape == "boots" else 9) * u)      # greaves come up over the shins
	var cells := _cells(hi, top, hi["by"], hi["tw"])
	var c := _transfer(hi, cells)
	for p: Vector2i in cells:
		if p.y == top or (shape == "greaves" and p.y <= top + roundi(2 * u) and (c[p] == "1" or c[p] == "2")):
			c[p] = "3"
	return _lines(hi, _rim(hi, c, cells, [top]))

## Gloves: the ends of the arms, at the hips' height.
static func _hands(hi: Dictionary) -> Dictionary:
	var u: float = hi["u"]
	var cells := []
	var g := roundi(4 * u)
	for y in range(hi["hip"] - roundi(6 * u), hi["hip"] - roundi(1 * u)):
		var r := _run(hi, y, roundi(hi["hcx"]))
		if r.size() == 2 and r[1] - r[0] >= 3 * g:
			for k in g:
				cells.append(Vector2i(r[0] + k, y))
				cells.append(Vector2i(r[1] - k, y))
	var c := _transfer(hi, cells)
	var top: int = hi["hip"] - roundi(6 * u)
	for p: Vector2i in cells:
		if p.y == top:
			c[p] = "3"
	return _lines(hi, _rim(hi, c, cells))

# ---------- small pieces ----------
## An amulet: its chain, and the stone on the chest.
static func _neck(hi: Dictionary) -> Dictionary:
	var u: float = hi["u"]
	var top: int = hi["chin"] + 1
	var cx := roundi(hi["hcx"])
	var c := {}
	var n := roundi(4 * u)
	for i in n:
		c[Vector2i(cx - n + i, top + i)] = "2"
		c[Vector2i(cx + n - 1 - i, top + i)] = "2"
	var stone := {}
	var s := roundi(4 * u)
	for y in range(top + n - 1, top + n - 1 + s):
		for x in range(cx - s / 2, cx + s / 2):
			stone[Vector2i(x, y)] = "1"
	stone[Vector2i(cx - 1, top + n)] = "4"
	stone[Vector2i(cx, top + n)] = "3"
	c.merge(_outline(stone), true)
	return c

## A charm at the belt.
static func _trinket(hi: Dictionary) -> Dictionary:
	var u: float = hi["u"]
	var c := {}
	var s := roundi(4 * u)
	var x0 := roundi(hi["hcx"] + hi["tw"] * 0.4)
	var y0: int = hi["hip"] - s / 2
	for y in range(y0, y0 + s + 1):
		for x in range(x0, x0 + s):
			c[Vector2i(x, y)] = "1"
	c[Vector2i(x0 + 1, y0 + 1)] = "4"
	return _outline(c)

## A ring on a hand.
static func _ring(hi: Dictionary, left: bool) -> Dictionary:
	var u: float = hi["u"]
	var y: int = hi["hip"] - roundi(3 * u)
	var r := _run(hi, y, roundi(hi["hcx"]))
	if r.is_empty():
		return {}
	var x: int = r[0] + 1 if left else r[1] - 2
	return { Vector2i(x, y): "4", Vector2i(x + 1, y): "1", Vector2i(x, y + 1): "1", Vector2i(x + 1, y + 1): "2" }

## The piece drawn on this hero (66.4), shaded for the item's colours: {} when it has none.
static func _drawn(hi: Dictionary, key: String) -> Dictionary:
	var name: String = hi["name"]
	if not _strips.has(name):
		var img: Image = null
		if ResourceLoader.exists(PIECE_DIR + name + ".png"):
			var tex: Texture2D = load(PIECE_DIR + name + ".png")
			img = tex.get_image()
			if img != null:
				if img.is_compressed():
					img.decompress()
				img.convert(Image.FORMAT_RGBA8)
		_strips[name] = img
	var strip: Image = _strips[name]
	var i := PIECES.find(key)
	var w: int = hi["w"]
	var h: int = hi["h"]
	if strip == null or i < 0 or strip.get_width() < (i + 1) * w or strip.get_height() != h:
		return {}
	var cells := []
	var lum := {}
	# 67.7 (his word: "make it perfect"): a hood or a helm leaves the face free (PixelLab shaded the
	# face under them too, and that shade is not part of the piece)
	var face := key in ["hood", "helm"]
	var fcx: float = hi["hcx"]
	var fcy: float = (hi["eye"] + hi["chin"]) / 2.0
	var frx: float = (hi["hx1"] - hi["hx0"]) * 0.27 + 0.5
	var fry: float = (hi["chin"] - hi["eye"]) * 0.62 + 1.5
	for y in h:
		for x in w:
			if face and _ell(x, y, fcx, fcy, frx, fry):
				continue
			var c := strip.get_pixel(i * w + x, y)
			if c.a >= 0.5:
				cells.append(Vector2i(x, y))
				lum[Vector2i(x, y)] = c.get_luminance()
	if cells.size() < 6:
		return {}
	if key == "shield":   # 67.7: one shield, the biggest shape, on one side (PixelLab sometimes touched the other arm too)
		var cx: float = hi["hcx"]
		var l := 0
		for c: Vector2i in cells:
			if c.x < cx:
				l += 1
		var on_left := l * 2 >= cells.size()
		var side := []
		for c: Vector2i in cells:
			if (c.x < cx + 1.0) if on_left else (c.x > cx - 1.0):
				side.append(c)
		cells = _biggest(side)
	cells.sort_custom(func(a, b): return lum[a] < lum[b] or (lum[a] == lum[b] and (a.y < b.y or (a.y == b.y and a.x < b.x))))
	var out := {}
	var n := cells.size()
	for k in n:
		var p: Vector2i = cells[k]
		var f := float(k) / maxf(1.0, n - 1)
		if lum[p] < 0.1:
			out[p] = "o"      # its own outline and dark lines stay dark
		else:
			out[p] = "0" if f < 0.12 else ("2" if f < 0.38 else ("1" if f < 0.72 else ("3" if f < 0.93 else "4")))
	return out

## The biggest group of touching cells.
static func _biggest(cells: Array) -> Array:
	var left := {}
	for c in cells:
		left[c] = true
	var best := []
	while not left.is_empty():
		var start: Vector2i = left.keys()[0]
		left.erase(start)
		var group := [start]
		var todo := [start]
		while not todo.is_empty():
			var c: Vector2i = todo.pop_back()
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1)]:
				if left.has(c + d):
					left.erase(c + d)
					group.append(c + d)
					todo.append(c + d)
		if group.size() > best.size():
			best = group
	return best

static func _piece(slot: String, g: Dictionary, hi: Dictionary) -> Dictionary:
	var shape: String = g.get("shape", "")
	var key: String = { "hands": "gloves", "offhand": "shield" }.get(slot, shape)
	if slot in ["head", "body", "feet", "hands", "offhand"]:
		var d := _drawn(hi, key)
		if not d.is_empty():
			return d
	match slot:
		"head": return _head(shape, hi)
		"body": return _body(shape, hi)
		"feet": return _feet(shape, hi)
		"hands": return _hands(hi)
		"neck": return _neck(hi)
		"trinket": return _trinket(hi)
		"ring1": return _ring(hi, true)
		"ring2": return _ring(hi, false)
		"offhand": return _offhand(hi)
	return {}

## The outfit texture for the player's current gear on this hero, or null with nothing equipped.
## 64.5: the hero's size in the game (12 x 14 the old heroes, 24 x 28 the ones drawn on PixelLab):
## the outfit is drawn over it at that size, with the picture's own finer pixels (66.3).
static func size_of(hero: String) -> Vector2i:
	var t := Img.t(hero)
	return Vector2i(t.get_size()) if t != null else Vector2i(W, H)

## A hero drawn twice the old size (64.5): menus show it at half their zoom, so it keeps its place.
static func big(hero: String) -> bool:
	return size_of(hero).x >= W * 2

static func texture(p: Player, hero: String) -> Texture2D:
	var key := hero + "|"
	for slot in ORDER:
		var g = p.gear.get(slot)
		key += (g["id"] if g != null else "") + "|"
	if _cache.has(key):
		return _cache[key]
	var hi := _hero(hero)
	var img := Image.create(hi["w"], hi["h"], false, Image.FORMAT_RGBA8)
	var any := false
	for slot in ORDER:
		var g = p.gear.get(slot)
		if g == null:
			continue
		any = true
		var pal := palette(g)
		var cells := _piece(slot, g, hi)
		for at: Vector2i in cells:
			if at.x >= 0 and at.x < hi["w"] and at.y >= 0 and at.y < hi["h"]:
				img.set_pixelv(at, pal[cells[at]])
	var tex: Texture2D = null
	if any:
		var it := ImageTexture.create_from_image(img)
		it.set_size_override(size_of(hero))      # drawn at the hero's size, with the finer pixels
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
	var w := float(tex.get_width())
	var h := float(tex.get_height())
	if zx == 1.0 and zy == 1.0 and not mirror:
		ci.draw_texture(tex, Vector2(px - w / 2, py - h), mod)
		return
	ci.draw_set_transform(Vector2(px, py), 0.0, Vector2(zx, zy))
	var r := Rect2(-w / 2, -h, -w, h) if mirror else Rect2(-w / 2, -h, w, h)   # negative width: flipped in place
	ci.draw_texture_rect(tex, r, false, mod)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
