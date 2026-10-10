class_name TraitBook
extends RefCounted
## 30.2 (his pick, 9 Oct: a trait book): the codex's fourth page, TRAITS. Every trait and OATH in
## one list, the rarest first (oaths, mythic, SUPER, legendary, rare, cursed, uncommon, common),
## in two columns. A trait is lit once a pick has shown it to you (Meta "traits_seen"); the ones
## you took say how often (Meta "traits_taken"). Under the list, the chosen one: its text, and an
## oath's vow and what keeping it adds (oaths.gd).

const COLS := 2
const ROWS := 12
const ROW_H := 10
const CELL_W := 200
const TOP := 42
const ORDER := ["oath", "mythic", "super", "legend", "rare", "cursed", "uncommon", "common"]

static var _list: Array = []

static func entries() -> Array:
	if _list.is_empty():
		var fams: Array = Traits.FAMILIES.keys()
		_list = Traits.all().duplicate()
		_list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			var ra := ORDER.find(a["rarity"])
			var rb := ORDER.find(b["rarity"])
			if ra != rb:
				return ra < rb
			var fa := fams.find(a["fam"])
			var fb := fams.find(b["fam"])
			if fa != fb:
				return fa < fb
			return String(a["name"]) < String(b["name"]))
	return _list

static func seen(id: String) -> bool:
	return (Meta.meta.get("traits_seen", {}) as Dictionary).has(id) or taken(id) > 0

static func taken(id: String) -> int:
	return int((Meta.meta.get("traits_taken", {}) as Dictionary).get(id, 0))

## A pick showed it (G.offer_traits).
static func note_seen(t: Dictionary) -> void:
	(Meta.meta.get_or_add("traits_seen", {}) as Dictionary)[t["id"]] = true

## It was taken (G.take_trait).
static func note_taken(t: Dictionary) -> void:
	var d: Dictionary = Meta.meta.get_or_add("traits_taken", {})
	d[t["id"]] = int(d.get(t["id"], 0)) + 1

## The list scrolls so the chosen row stays on screen (taps.gd uses it too).
static func first_row_for(sel: int) -> int:
	var n := entries().size()
	return clampi(sel / COLS - ROWS / 2, 0, maxi(0, (n + COLS - 1) / COLS - ROWS))

static func cell_rect(i: int, first_row: int) -> Rect2:
	var x0 := (TB.SW - COLS * CELL_W) / 2
	return Rect2(x0 + (i % COLS) * CELL_W, TOP + (i / COLS - first_row) * ROW_H, CELL_W - 6, ROW_H)

static func draw(ci: CanvasItem, sel: int) -> void:
	var list := entries()
	var n_seen := 0
	var n_taken := 0
	for t in list:
		if seen(t["id"]):
			n_seen += 1
		if taken(t["id"]) > 0:
			n_taken += 1
	Gfx.text(ci, "%d OF %d FOUND, %d TAKEN" % [n_seen, list.size(), n_taken], TB.SW / 2, 28, "grey", 1, 0.5)
	var first := first_row_for(sel)
	for i in list.size():
		var row := i / COLS - first
		if row < 0 or row >= ROWS:
			continue
		var t: Dictionary = list[i]
		var r := cell_rect(i, first)
		if i == sel:
			ci.draw_rect(Rect2(r.position.x - 3, r.position.y - 2, r.size.x + 4, r.size.y), TB.rgba(232, 135, 58, 90))
		var known := seen(t["id"])
		var box: String = "#ff9b3a" if t["rarity"] == "oath" else Traits.FAMILIES[t["fam"]]["hex"]
		ci.draw_rect(Rect2(r.position.x, r.position.y + 1, 5, 5), TB.c(box) if known else TB.rgba(60, 56, 80, 255))
		Gfx.text(ci, t["name"] if known else "???", r.position.x + 9, r.position.y, Traits.RARITY[t["rarity"]]["col"] if known else "dim")
		var k := taken(t["id"])
		if k > 0:
			Gfx.text(ci, "X%d" % k, r.end.x - 2, r.position.y, "tan", 1, 1)
	_detail(ci, list[clampi(sel, 0, list.size() - 1)])

## The chosen trait, under the list.
static func _detail(ci: CanvasItem, t: Dictionary) -> void:
	var y0 := TOP + ROWS * ROW_H + 4
	Gfx.panel(ci, 24, y0, TB.SW - 48, 254 - y0, "#4e4a5e", "#17121e")
	var rar: Dictionary = Traits.RARITY[t["rarity"]]
	var kind: String = rar["name"] + "  " + Traits.FAMILIES[t["fam"]]["name"]
	TraitView.cube(ci, TB.SW - 76, y0 + 18, t, 2, 1.0, false, seen(t["id"]))   # 41.3: its cube
	if not seen(t["id"]):
		Gfx.text(ci, "UNDISCOVERED", TB.SW / 2, y0 + 12, "grey", 2, 0.5)
		Gfx.text(ci, kind, TB.SW / 2, y0 + 34, rar["col"], 1, 0.5)
		Gfx.text(ci, "SWEAR IT AT THE START OF A RUN" if t["rarity"] == "oath" else "NO PICK HAS SHOWN IT TO YOU YET", TB.SW / 2, y0 + 48, "dim", 1, 0.5)
		return
	Gfx.text(ci, t["name"], 32, y0 + 6, rar["col"], 1)
	Gfx.text(ci, kind + ("  MAX %d" % t["max"] if t["max"] > 1 else ""), TB.SW - 32, y0 + 6, "tan", 1, 1)
	var y := y0 + 18
	var w := TB.SW - 124   # beside the cube
	for part in TraitView.bullets(t["desc"]):
		for line in TraitView.rich_lines(part, w):
			TraitView.draw_line(ci, line, 36, y)
			y += 8
	if Oaths.VOWS.has(t["id"]):
		y += 3
		Gfx.text(ci, "VOW: " + Oaths.vow_text(t["id"]), 36, y, "orange")
		y += 10
		for line in TraitView.rich_lines("AWAKENED: " + Oaths.awake_text(t["id"]), w, "gold"):
			TraitView.draw_line(ci, line, 36, y)
			y += 8
	var k := taken(t["id"])
	Gfx.text(ci, ("TAKEN %d TIMES" % k) if k > 1 else ("TAKEN ONCE" if k == 1 else "SEEN, NEVER TAKEN"), TB.SW - 32, 254 - 12, "tan" if k > 0 else "dim", 1, 1)
