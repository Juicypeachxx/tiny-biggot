class_name ItemShow
extends RefCounted
## How a weapon or piece of gear shows itself on the floor in the expanded game (his ask, 5 Oct,
## from a clip he sent): sparkles fall onto it, then a beam of light in its rarity's colour
## comes down on it and settles into a soft column; its card names its keywords in colour and
## explains them in small panels beside it. A treasure room may hold three items on pedestals:
## take one and the others sink away.

const FALL := 0.3     # sparkles falling
const FLARE := 0.35   # the beam coming down
const RAR_HEX := { "common": "#c9c2a8", "rare": "#4d9be6", "epic": "#a35bd6", "legend": "#f2c94c" }

static func active() -> bool:
	return GameData.rogues()

## Three items on pedestals (a treasure room, 40% of the time in the expanded game).
static func pedestal_room(r: Room) -> void:
	var cx := 14.0 * TB.TS
	var cy := 9.5 * TB.TS
	var f := G.floor_index
	var seen := {}
	for i in 3:
		var it: Dictionary
		for tries in 8:
			it = Weapons.random_weapon(Gear.roll_item_rarity(f, "elite"), G.player.weapon) if (i == 0 or (i == 2 and randf() < 0.4)) \
				else Gear.random_gear(Gear.roll_item_rarity(f, "elite"))
			if not seen.has(it["id"]):
				break
		seen[it["id"]] = true
		r.objects.append({ "kind": "item", "item": it, "x": cx - 64 + i * 64, "y": cy - 6, "t": 0.0, "group": "pedestal",
			"pedestal": true, "born": -1.0 })

## The beam and the sparkles (world_view.gd, under the item).
static func beam(ci: CanvasItem, o: Dictionary, t: float) -> void:
	if not o.has("born") or o["born"] < 0:
		o["born"] = t + (o["x"] / 900.0 if o.get("pedestal", false) else 0.0)   # pedestals light up one after another
	var k: float = t - o["born"]
	if k < 0:
		return
	var it: Dictionary = o["item"]
	var col := TB.c(RAR_HEX.get(it["rarity"], "#c9c2a8"))
	var x: float = o["x"]
	var y: float = o["y"]
	if k < FALL:
		# Sparkles falling onto the spot.
		for i in 6:
			var sy: float = y - 70 + (k / FALL) * 66 - i * 9
			var sx: float = x + sin(i * 2.3 + k * 9) * 5
			ci.draw_rect(Rect2(roundf(sx), roundf(sy), 1, 3), Color(1, 1, 1, 0.9))
			ci.draw_rect(Rect2(roundf(sx) - 1, roundf(sy) + 1, 3, 1), Color(1, 1, 1, 0.9))
		return
	var q: float = minf((k - FALL) / FLARE, 1.0)
	var settle: float = 0.35 + 0.08 * sin(t * 3 + x)
	var a: float = lerpf(0.9, settle, q) if q >= 1.0 else 0.9 * q + 0.1
	var wdt: float = lerpf(16.0, 9.0, q)
	var top: float = maxf(2.5 * TB.TS, y - 120.0)
	var c0 := Color(col.r, col.g, col.b, 0.0)
	var c1 := Color(col.r, col.g, col.b, a)
	var cw := Color(lerpf(col.r, 1.0, 0.6), lerpf(col.g, 1.0, 0.6), lerpf(col.b, 1.0, 0.6), a)
	ci.draw_polygon(PackedVector2Array([Vector2(x - wdt / 2, top), Vector2(x + wdt / 2, top), Vector2(x + wdt / 2, y + 4), Vector2(x - wdt / 2, y + 4)]),
		PackedColorArray([c0, c0, c1, c1]))
	ci.draw_polygon(PackedVector2Array([Vector2(x - 1.5, top), Vector2(x + 1.5, top), Vector2(x + 1.5, y + 4), Vector2(x - 1.5, y + 4)]),
		PackedColorArray([c0, c0, cw, cw]))
	if q < 1.0:
		ci.draw_circle(Vector2(x, y + 2), 10.0 * (1.0 - q) + 2.0, Color(1, 1, 1, 0.6 * (1.0 - q)))

## A stone pedestal under an item.
static func pedestal(ci: CanvasItem, x: float, y: float) -> void:
	Gfx.sp(ci, "pedestal_stone", x, y + 16)

## Keyword panels for a card at (x, y, w): to its right, or to its left when there is no room.
static func keyword_panels(ci: CanvasItem, text: String, x: float, y: float, w: float) -> void:
	var pw := 92.0
	var px := x + w + 3
	if px + pw > TB.SW - 2:
		px = x - pw - 3
	if px < 2:
		return
	var seen := {}
	for word in text.split(" ", false):
		var key := TraitView._bare(word)
		if not TraitView.KEYWORDS.has(key) or seen.has(TraitView.KEYWORDS[key][1]):
			continue
		seen[TraitView.KEYWORDS[key][1]] = true
		var lines := Gfx.wrap_text(TraitView.KEYWORDS[key][1], int(pw) - 8)
		var h := 14 + lines.size() * 8
		if y + h > TB.SH - 4:
			break
		Gfx.panel(ci, px, y, pw, h, "#8b8f9c", "#0c0b12")
		Gfx.text(ci, key, px + 4, y + 3, TraitView.KEYWORDS[key][0])
		for j in lines.size():
			Gfx.text(ci, lines[j], px + 4, y + 12 + j * 8, "white")
		y += h + 3

## The width rich_line draws (keyword icons included).
static func line_w(s: String, base: String) -> int:
	if base != "white":
		return TB.text_w(s)
	var segs: Array = TraitView.rich_lines(s, 9999)
	return TraitView.line_w(segs[0]) if not segs.is_empty() else 0

## A card line with its keywords and numbers in colour (lines that are all one colour stay so).
static func rich_line(ci: CanvasItem, s: String, x: float, y: float, base: String) -> void:
	if base != "white":
		Gfx.text(ci, s, x, y, base)
		return
	var segs: Array = TraitView.rich_lines(s, 9999)
	if segs.is_empty():
		return
	TraitView.draw_line(ci, segs[0], x, y)
