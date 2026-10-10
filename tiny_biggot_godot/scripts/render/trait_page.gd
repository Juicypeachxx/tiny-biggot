class_name TraitPage
extends RefCounted
## 41.3 (his ask, 10 Oct: "add cubes around the trait sprites", from his wiki pictures): the pause
## menu's TRAITS page in the expanded game. Every trait you have is a cube (TraitView.cube), STR,
## DEX, INT and the rest in turn, its rank under it. ARROWS or a tap choose one: under the cubes
## its name and text; on the right every family you have, what the chosen one's family gives, the
## synergies and the hidden combos. Any other button goes back. --classic keeps the original text
## list (menu_view.draw_traitlist).

const COLS := 6
const ROWS := 4
const X0 := 14
const Y0 := 30
const STEP_X := 48
const STEP_Y := 48
const COL_X := 304
const COL_W := 134
const DETAIL_Y := 224
const GROUPS := ["str", "dex", "int", "super", ""]

## The traits you have, in their colour groups, then by family and name.
static func owned() -> Array:
	var p := G.player
	var fams: Array = Traits.FAMILIES.keys()
	var out := Traits.all().filter(func(t): return p.traits.has(t["id"]))
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var ga := GROUPS.find(TraitView.group(a))
		var gb := GROUPS.find(TraitView.group(b))
		if ga != gb:
			return ga < gb
		var fa := fams.find(a["fam"])
		var fb := fams.find(b["fam"])
		if fa != fb:
			return fa < fb
		return String(a["name"]) < String(b["name"]))
	return out

## The cubes scroll by rows so the chosen one stays on screen (taps.gd uses it too).
static func first_row(sel: int, n: int) -> int:
	return clampi(sel / COLS - (ROWS - 1), 0, maxi(0, (n + COLS - 1) / COLS - ROWS))

static func cell_rect(i: int, first: int) -> Rect2:
	return Rect2(X0 + (i % COLS) * STEP_X, Y0 + (i / COLS - first) * STEP_Y, 40, 40)

static func draw(ci: CanvasItem) -> void:
	var p := G.player
	var list := owned()
	Gfx.text(ci, "TRAITS  -  LEVEL %d" % p.level, TB.SW / 2, 4, "gold", 2, 0.5)
	var sel := clampi(G.traitlist_i, 0, maxi(0, list.size() - 1))
	var first := first_row(sel, list.size())
	for i in list.size():
		var row := i / COLS - first
		if row < 0 or row >= ROWS:
			continue
		var t: Dictionary = list[i]
		var r := cell_rect(i, first)
		TraitView.cube(ci, r.position.x, r.position.y, t, 2, 1.0, i == sel)
		var rank: int = p.traits[t["id"]]
		var pips := ""
		for k in t["max"]:
			pips += "*" if k < rank else "-"
		Gfx.text(ci, pips, r.get_center().x, r.end.y + 2, "tan", 1, 0.5)
	var below := list.size() - (first + ROWS) * COLS
	var info := "TRAITS %d OF %d" % [TraitRules.counted(p), TraitRules.CAP]   # 41.5: the limit
	if first > 0:
		info += "   ^ %d ABOVE" % (first * COLS)
	if below > 0:
		info += "   %d BELOW" % below
	Gfx.text(ci, info, X0, Y0 - 11, "grey")
	if list.is_empty():
		Gfx.text(ci, "NO TRAITS YET. LEVEL UP BY SLAYING FOES.", X0 + COLS * STEP_X / 2, 80, "grey", 1, 0.5)
	_column(ci, p, list[sel] if not list.is_empty() else {})
	if not list.is_empty():
		_detail(ci, p, list[sel])
	Gfx.text(ci, "ARROWS  CHOOSE     ANY OTHER BUTTON  BACK", TB.SW / 2, 276, "dim", 1, 0.5)

## The chosen trait, under the cubes: its name, rarity, family and rank, then its text as it is now.
static func _detail(ci: CanvasItem, p: Player, t: Dictionary) -> void:
	var fam: Dictionary = Traits.FAMILIES[t["fam"]]
	var col: String = TraitView.GROUP_COL.get(TraitView.group(t), fam["col"])
	Gfx.text(ci, t["name"], X0, DETAIL_Y, col)
	var rank: int = p.traits[t["id"]]
	var kind: String = Traits.RARITY[t["rarity"]]["name"] + "  " + fam["name"] + ("  RANK %d OF %d" % [rank, t["max"]] if t["max"] > 1 else "")
	Gfx.text(ci, kind, TB.SW - 12, DETAIL_Y, "tan", 1, 1)
	var lines := TraitView.rich_lines(Live.desc(t), TB.SW - 28)
	for j in mini(5, lines.size()):
		TraitView.draw_line(ci, lines[j], X0, DETAIL_Y + 10 + j * 8)

## The right column: every family you have (the chosen trait's lit), what that family gives at
## 2, 4 and 6, the synergies and the hidden combos (14.3).
static func _column(ci: CanvasItem, p: Player, t: Dictionary) -> void:
	var x := COL_X
	var y := Y0 - 2
	var fams: Array = p.fam.keys()
	fams.sort_custom(func(a, b): return p.fam[a] > p.fam[b])
	var shown := 0
	for f in fams:
		if y > 104:
			Gfx.text(ci, "AND %d MORE" % (fams.size() - shown), x, y, "grey")
			y += 9
			break
		var fam: Dictionary = Traits.FAMILIES[f]
		if not t.is_empty() and t["fam"] == f:
			ci.draw_rect(Rect2(x - 3, y - 2, COL_W + 4, 11), TB.c("#f2c94c"), false, 1.0)
		Gfx.text(ci, "%s %d" % [fam["name"], p.fam[f]], x, y, fam["col"])
		if Traits.FAMILY_BONUS.has(f):
			var tier: int = p.fam_bonus.get(f, 0)
			var marks := ""
			for k in Traits.FAMILY_BONUS[f].size():
				marks += "*" if k < tier else "-"
			Gfx.text(ci, marks, x + COL_W - 2, y, "tan", 1, 1)
		y += 9
		shown += 1
	if not t.is_empty() and Traits.FAMILY_BONUS.has(t["fam"]):
		var f: String = t["fam"]
		var tier: int = p.fam_bonus.get(f, 0)
		y += 4
		Gfx.text(ci, Traits.FAMILIES[f]["name"] + " GIVES:", x, y, "white")
		y += 10
		for k in Traits.FAMILY_BONUS[f].size():
			var wl := Gfx.wrap_text("%d: %s" % [(k + 1) * 2, Traits.bonus_name(f, k)], COL_W - 2)
			for line in wl:
				Gfx.text(ci, line, x, y, Traits.FAMILIES[f]["col"] if k < tier else "dim")
				y += 8
			y += 1
	var hid := Synergies.COMBOS.filter(func(c): return c.get("hidden", false))
	var fd: Dictionary = Meta.meta.get("combos_found", {}) if Meta.meta.get("combos_found") is Dictionary else {}
	var live := hid.filter(func(c): return p.synergies.has("combo:" + c["id"])).map(func(c): return c["name"])
	y = maxi(y + 4, 184 - (8 if not live.is_empty() else 0))
	Gfx.text(ci, "ACTIVE SYNERGIES: %d" % p.synergies.size(), x, y, "gold")
	Gfx.text(ci, "HIDDEN COMBOS %d OF %d" % [fd.size(), hid.size()], x, y + 10, "purple")
	if not live.is_empty():
		var wl := Gfx.wrap_text("ACTIVE: " + ", ".join(live), COL_W - 2)
		for j in mini(2, wl.size()):
			Gfx.text(ci, wl[j], x, y + 20 + j * 8, "purple")
