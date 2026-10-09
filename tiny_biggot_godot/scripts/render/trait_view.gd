class_name TraitView
extends RefCounted
## The level-up and the trait choice of the expanded game (his ask, 5 Oct, from a clip he sent):
##   1. a starburst: white rays spin out from the hero with a scatter of stars, for BURST seconds;
##   2. the "CHOOSE A TRAIT" panel: a column of rows, each an icon box in its family's colour, the
##      name and the text with its keywords coloured. The rows come in one after another, each
##      with a shine sweeping across it;
##   3. a fourth row: with luck, a fourth trait (each point of luck is a 15% chance); without, a
##      line that says so;
##   4. beside the chosen row, small panels that explain the keywords in its text.
## --classic keeps the original three cards side by side (overlay_view.draw_traits).

const BURST := 0.9      # seconds of starburst before the panel
const ROW_GAP := 0.14   # seconds between rows coming in
const SHINE := 0.45     # seconds a shine takes to cross a row
# 8.5 (his ask, 6 Oct: "revamp traits as" his pictures): wide rows on the left, a column on the right
# with the odds of the next roll and the keyword boxes under it.
const PX := 8           # the panel of rows
const PW := 296
const COL_X := 310      # the right column
const COL_W := 132
const ROW_Y := 30
const ROW_H := 50
const ROW_STEP := 54
const FOOT_Y := 256

## Keywords: word -> [colour, what it means]. Matched on whole words of a trait's text.
const KEYWORDS := {
	"BURN": ["orange", "BURNING FOES TAKE FIRE DAMAGE EVERY HALF SECOND FOR A FEW SECONDS."],
	"BURNS": ["orange", "BURNING FOES TAKE FIRE DAMAGE EVERY HALF SECOND FOR A FEW SECONDS."],
	"POISON": ["lime", "POISON STACKS. EACH STACK DEALS DAMAGE OVER TIME UNTIL IT WEARS OFF."],
	"CHILL": ["cyan", "CHILLED FOES MOVE AND ATTACK MORE SLOWLY."],
	"CHILLED": ["cyan", "CHILLED FOES MOVE AND ATTACK MORE SLOWLY."],
	"BLEED": ["red", "BLEEDING FOES LOSE HEALTH OVER TIME. MOVING MAKES IT WORSE."],
	"CURSE": ["purple", "CURSED FOES TAKE 25% MORE DAMAGE FROM EVERYTHING."],
	"CURSED": ["purple", "CURSED FOES TAKE 25% MORE DAMAGE FROM EVERYTHING."],
	"SHOCK": ["cyan", "SHOCKED FOES TAKE MORE DAMAGE FOR EACH SHOCK ON THEM."],
	"STUN": ["gold", "A STUNNED FOE CANNOT MOVE OR ATTACK FOR A MOMENT."],
	"CRIT": ["gold", "A CRITICAL HIT DEALS MORE DAMAGE. CRIT CHANCE PAST 100% IS NOT WASTED."],
	"CRITS": ["gold", "A CRITICAL HIT DEALS MORE DAMAGE. CRIT CHANCE PAST 100% IS NOT WASTED."],
	"WISP": ["cyan", "A SPIRIT THAT FLIES WITH YOU AND SHOOTS AT YOUR FOES."],
	"WISPS": ["cyan", "SPIRITS THAT FLY WITH YOU AND SHOOT AT YOUR FOES."],
	"ROLL": ["white", "A QUICK DODGE. NOTHING HITS YOU WHILE YOU ROLL. CHARGES REFILL OVER TIME."],
	"ROLLS": ["white", "QUICK DODGES. NOTHING HITS YOU WHILE YOU ROLL. CHARGES REFILL OVER TIME."],
	"ARMOR": ["grey", "EACH POINT OF ARMOR STOPS ONE HIT BEFORE YOUR HEARTS DO."],
	"PIERCE": ["white", "A PIERCING SHOT GOES ON THROUGH THE FOE IT HITS."],
	"THORNS": ["green", "FOES THAT TOUCH YOU TAKE THIS MUCH DAMAGE."],
	"ARC": ["cyan", "AN ARC JUMPS FROM THE FOE YOU HIT TO ONE NEARBY."],
	"ARCS": ["cyan", "ARCS JUMP FROM THE FOE YOU HIT TO ONE NEARBY."],
	"EXPLODE": ["orange", "A BLAST THAT HURTS EVERY FOE AROUND IT."],
	"VULNERABLE": ["pink", "VULNERABLE FOES TAKE MORE DAMAGE FOR A WHILE."],
	"WEAKENED": ["purple", "WEAKENED FOES DEAL LESS DAMAGE."],
	"MARK": ["pink", "A MARKED FOE TAKES EXTRA DAMAGE FROM YOUR NEXT HITS."],
	"ECHO": ["pink", "AN ECHO CASTS A SHOT A SECOND TIME, FOR FREE."],
	"LUCK": ["lime", "LUCK MAKES RARE THINGS LESS RARE, AND CAN ADD A FOURTH TRAIT TO CHOOSE FROM."],
	"FAMILIAR": ["cyan", "A COMPANION THAT FIGHTS AT YOUR SIDE."],
	# 8.2 (his ask, 6 Oct: "make info of perks and stats and all info of the game ... easier to understand
	# the build"): the stats and the alignments in their colour, each with its little icon (ICONS).
	"DAMAGE": ["red", "HOW HARD EACH OF YOUR HITS LANDS."],
	"RATE": ["gold", "FIRE RATE: HOW MANY ATTACKS YOU MAKE EACH SECOND."],
	"SPEED": ["cyan", "HOW FAST YOU OR YOUR SHOTS MOVE."],
	"GOLD": ["gold", "SPENT IN SHOPS, AT THE ANVIL AND ON IDOLS."],
	"HEART": ["red", "YOUR HEALTH. EACH HEART TAKES TWO HITS."],
	"HEARTS": ["red", "YOUR HEALTH. EACH HEART TAKES TWO HITS."],
	"POTION": ["pink", "DRINK IT TO HEAL. REFILLS AT SOME SHRINES AND SHOPS."],
	"STR": ["red", "STRENGTH: RAISES THE DAMAGE OF WEAPONS THAT SCALE WITH IT. EVERY 5 POINTS: +1 MAX HEART."],
	"DEX": ["lime", "DEXTERITY: RAISES THE DAMAGE OF WEAPONS THAT SCALE WITH IT. EACH POINT: +1% CRIT."],
	"INT": ["cyan", "INTELLIGENCE: RAISES THE DAMAGE OF WEAPONS THAT SCALE WITH IT. EACH POINT: +2% BURN, POISON AND LIGHTNING DAMAGE."],
	"GOOD": ["gold", "AN ALIGNMENT. SOME STARS AND PERKS HOLD WHILE IT LEADS (2 OR MORE, NONE HIGHER)."],
	"EVIL": ["red", "AN ALIGNMENT. SOME STARS AND PERKS HOLD WHILE IT LEADS (2 OR MORE, NONE HIGHER)."],
	"LAWFUL": ["cyan", "AN ALIGNMENT. SOME STARS AND PERKS HOLD WHILE IT LEADS (2 OR MORE, NONE HIGHER)."],
	"CHAOTIC": ["purple", "AN ALIGNMENT. SOME STARS AND PERKS HOLD WHILE IT LEADS (2 OR MORE, NONE HIGHER)."],
	"DEVOUT": ["gold", "ONE ALIGNMENT 2 OR MORE AND THE OTHER THREE 1 OR LESS."],
	"GLOOM": ["purple", "GLOOM STACKS UP TO 10. EACH STACK: +8% DAMAGE TAKEN. LASTS 4 SECONDS."],
	"GLOOMED": ["purple", "GLOOM STACKS UP TO 10. EACH STACK: +8% DAMAGE TAKEN. LASTS 4 SECONDS."],
}
## The little icon drawn after a keyword (tools/art/mini_icons.py).
const ICONS := { "DAMAGE": "mi_dmg", "RATE": "mi_rate", "SPEED": "mi_speed", "GOLD": "mi_gold", "HEART": "mi_heart",
	"HEARTS": "mi_heart", "ARMOR": "mi_armor", "CRIT": "mi_crit", "CRITS": "mi_crit", "LUCK": "mi_luck", "POTION": "mi_potion",
	"STR": "mi_str", "DEX": "mi_dex", "INT": "mi_int", "GOOD": "mi_good", "EVIL": "mi_evil", "LAWFUL": "mi_law", "CHAOTIC": "mi_chaos" }
const FAM_ICON := { "core": "fam_core", "pyre": "fam_pyre", "frost": "fam_frost", "venom": "fam_venom", "storm": "fam_storm",
	"blood": "fam_blood", "bulwark": "fam_bulwark", "shadow": "fam_shadow", "arcane": "fam_arcane", "fortune": "fam_fortune",
	"demolition": "fam_demolition", "swarm": "fam_swarm", "edge": "fam_edge", "fury": "fam_fury", "malice": "fam_malice" }

static func active() -> bool:
	return GameData.rogues()

static func age() -> float:
	return G.time - G.tchoice.get("t0", -99.0)

static func ready() -> bool:
	return age() >= BURST + 0.15

static func row_rect(i: int) -> Rect2:
	return Rect2(PX + 6, ROW_Y + i * ROW_STEP, PW - 12, ROW_H)

## The reroll's tap zone on the footer line (taps.gd).
static func reroll_rect() -> Rect2:
	return Rect2(TB.SW / 2 + 40, FOOT_Y - 4, 140, 14)

# ---------- Drawing ----------
static func draw(ci: CanvasItem) -> void:
	var c := G.tchoice
	var t := age()
	var p := G.player
	if t < BURST:
		_burst(ci, t / BURST, p)
		return
	ci.draw_rect(Rect2(0, 0, TB.SW, TB.SH), Color(0.02, 0.02, 0.04, minf(0.92, (t - BURST) * 4.0 + 0.5)))
	# The frame: rows on the left, the column on the right with faint diagonal hatching.
	var fh := 4 * ROW_STEP + 8
	Gfx.panel(ci, PX, ROW_Y - 6, COL_X + COL_W + 4 - PX, fh, "#f4ecd8", "#0c0b12")
	ci.draw_rect(Rect2(PX + 3, ROW_Y - 3, COL_X + COL_W - 2 - PX, fh - 6), TB.c("#3a3650"), false, 1.0)
	for k in 14:
		var hx := COL_X + k * 12.0
		ci.draw_line(Vector2(hx, ROW_Y + fh - 12), Vector2(minf(hx + fh - 16, COL_X + COL_W), ROW_Y + fh - 12 - minf(fh - 16, COL_X + COL_W - hx)), Color(0.5, 0.5, 0.6, 0.12), 1.0)
	# 29: the run's opening OATH, and a grimoire's pick, have their own titles.
	var mode: String = c.get("mode", "")
	var title: String = { "oath": "SWEAR AN OATH FOR THIS RUN", "special": "THE GRIMOIRE: A RARE TRAIT" }.get(mode, "CHOOSE A TRAIT")
	var tw := maxi(124, TB.text_w(title) + 16)
	Gfx.panel(ci, TB.SW / 2 - tw / 2, ROW_Y - 22, tw, 15, "#ff9b3a" if mode == "oath" else "#f4ecd8", "#0c0b12")
	Gfx.text(ci, title, TB.SW / 2, ROW_Y - 18, "orange" if mode == "oath" else ("gold" if mode == "special" else "white"), 1, 0.5)
	Gfx.text(ci, "LEVEL %d" % p.level + ("  (+%d MORE)" % (p.pending - 1) if p.pending > 1 else ""), PX + 2, ROW_Y - 18, "lime")
	var opts: Array = c["opts"]
	for i in 4:
		var r := row_rect(i)
		var t0 := BURST + i * ROW_GAP
		if t < t0:
			continue
		var k := clampf((t - t0) / SHINE, 0.0, 1.0)
		if i < opts.size():
			_row(ci, r, opts[i], c["idx"] == i, minf(1.0, k * 2.5))
		else:
			Gfx.panel(ci, r.position.x, r.position.y, r.size.x, r.size.y, "#2a2838", "#0c0b12")
			Gfx.text(ci, "INCREASE YOUR LUCK", r.get_center().x, r.position.y + 17, "dim", 1, 0.5)
			Gfx.text(ci, "FOR A CHANCE OF 4 CHOICES", r.get_center().x, r.position.y + 27, "dim", 1, 0.5)
		if k < 1.0:
			_shine(ci, r, k)
	var oy := ROW_Y
	if t >= BURST:
		oy = _odds(ci, p)
	if t >= BURST + 4 * ROW_GAP and c["idx"] < opts.size():
		_keywords(ci, opts[c["idx"]], oy + 4)
	var reroll := "REROLL (%d LEFT)" % p.rerolls if p.rerolls > 0 else "REROLL (%d GOLD)" % G.reroll_cost()
	Gfx.text(ci, "UP/DOWN  CHOOSE    USE  TAKE    MENU  " + reroll, TB.SW / 2, FOOT_Y, "grey", 1, 0.5)

static func _row(ci: CanvasItem, r: Rect2, tr: Dictionary, sel: bool, a: float) -> void:
	var fam: Dictionary = Traits.FAMILIES[tr["fam"]]
	var border: String = "#f2c94c" if sel else "#8b8f9c"
	Gfx.panel(ci, r.position.x, r.position.y, r.size.x, r.size.y, border, "#14121c" if sel else "#0c0b12")
	# The icon box (8.5: bigger, in the family's colour; pink for a SUPER trait).
	var sup: bool = tr["rarity"] == "super"
	var box: String = "#e86fb4" if sup else ("#ff9b3a" if tr["rarity"] == "oath" else fam["hex"])   # 29: an OATH's box in orange
	var ib := Rect2(r.position.x + 6, r.position.y + 7, 36, 36)
	Gfx.panel(ci, ib.position.x, ib.position.y, ib.size.x, ib.size.y, box, "#0c0b12")
	ci.draw_rect(Rect2(ib.position.x + 2, ib.position.y + 2, ib.size.x - 4, ib.size.y - 4), TB.c(box), false, 1.0)
	Gfx.sp(ci, FAM_ICON.get(tr["fam"], "fam_core"), ib.get_center().x, ib.end.y - 5, 2, 2, 0.0, false, a)
	var tx := r.position.x + 48
	Gfx.text(ci, ("SUPER " if sup and not tr["name"].begins_with("SUPER") else "") + tr["name"], tx, r.position.y + 5, "pink" if sup else fam["col"], 1, 0.0, true, a)
	var rank: int = G.player.traits.get(tr["id"], 0)
	var pips := ""
	for k in tr["max"]:
		pips += "*" if k < rank else ("+" if k == rank else "-")
	Gfx.text(ci, pips, r.end.x - 5, r.position.y + 4, "tan", 1, 1.0, true, a)
	if tr["new"]:
		var rar: Dictionary = Traits.RARITY[tr["rarity"]]
		Gfx.text(ci, rar["name"], r.end.x - 5, r.end.y - 9, rar["col"], 1, 1.0, true, a)
	# 14.3: a hidden combo already found with this trait: which trait it pairs with.
	var bottom := r.end.y - 9
	var partners := Effects.found_partners(tr["id"])
	if tr["rarity"] == "oath" and Oaths.VOWS.has(tr["id"]):   # 30.1: the oath's vow, under its text
		Gfx.text(ci, "VOW: " + Oaths.vow_text(tr["id"]) + " TO AWAKEN IT", tx, r.end.y - 9, "orange", 1, 0.0, true, a)
		bottom -= 8
	elif not partners.is_empty():
		var pr: Array = partners[0]
		var ready: bool = G.player.traits.has(pr[0])
		var pname: String = Traits.by_id(pr[0])["name"] if Traits.has(pr[0]) else pr[0].to_upper()
		Gfx.text(ci, ("COMBO READY: " + pr[1]["name"]) if ready else ("COMBO WITH " + pname), tx, r.end.y - 9, "pink" if ready else "purple", 1, 0.0, true, a)
		bottom -= 8
	# Each sentence on its own bullet line (8.5), keywords in colour.
	var y := r.position.y + 16
	for part in bullets(Live.desc(tr)):   # 10.1: with its value now
		var lines := rich_lines(part, int(r.size.x) - 66)
		for j in lines.size():
			if y > bottom:
				return
			if j == 0:
				ci.draw_rect(Rect2(tx, y + 2, 2, 2), TB.c("#f4ecd8"))
			draw_line(ci, lines[j], tx + 5, y, a)
			y += 8

## A trait's text split into its sentences (the bullet lines of a row).
static func bullets(desc: String) -> PackedStringArray:
	var out := PackedStringArray()
	for s in desc.split(". ", false):
		out.append(s.strip_edges().trim_suffix("."))
	return out

## A bright band that sweeps across a row as it comes in.
static func _shine(ci: CanvasItem, r: Rect2, k: float) -> void:
	var bw := 46.0
	var x := r.position.x - bw + k * (r.size.x + bw * 2)
	var y0 := r.position.y
	var y1 := r.end.y
	var pts := PackedVector2Array([Vector2(x, y0), Vector2(x + bw, y0), Vector2(x + bw - 18, y1), Vector2(x - 18, y1)])
	var edge := Color(0.42, 0.45, 1.0, 0.0)
	var mid := Color(0.86, 0.88, 1.0, 0.75 * (1.0 - k * 0.5))
	ci.draw_polygon(pts, PackedColorArray([edge, mid, mid, edge]))

## The level-up: rays and stars around the hero, then the room dims.
static func _burst(ci: CanvasItem, k: float, p: Player) -> void:
	var c := Vector2(p.x, p.y - 6)
	var fade := 1.0 - k
	if k < 0.2:
		ci.draw_rect(Rect2(0, 0, TB.SW, TB.SH), Color(1, 1, 1, 0.35 * (1.0 - k / 0.2)))
	ci.draw_rect(Rect2(0, 0, TB.SW, TB.SH), Color(0.02, 0.02, 0.04, k * 0.5))
	var spin := k * 1.6
	for i in 7:
		var a := i * TAU / 7.0 + spin + (0.3 if i % 2 == 0 else 0.0)
		var wdt := (0.05 + 0.13 * sin(PI * k)) * (1.0 if i % 2 == 0 else 0.6)
		var rlen := 500.0
		var pts := PackedVector2Array([c, c + Vector2(cos(a - wdt), sin(a - wdt)) * rlen, c + Vector2(cos(a + wdt), sin(a + wdt)) * rlen])
		ci.draw_colored_polygon(pts, Color(0.88, 0.89, 0.97, 0.9 * fade))
	for i in 16:
		var a := i * 2.399 + k * 0.8
		var rr := 12.0 + k * (60.0 + (i % 5) * 22.0)
		var s := Vector2(cos(a), sin(a)) * rr + c
		var tw := 2.0 if (i + floori(k * 20)) % 3 == 0 else 1.0
		var col := Color(1, 1, 1, fade)
		ci.draw_rect(Rect2(roundf(s.x - tw), roundf(s.y), tw * 2 + 1, 1), col)
		ci.draw_rect(Rect2(roundf(s.x), roundf(s.y - tw), 1, tw * 2 + 1), col)
	ci.draw_circle(c, 6.0 + 10.0 * sin(PI * k), Color(1, 1, 1, 0.9 * fade))
	Gfx.text(ci, "LEVEL UP!", c.x, c.y - 30 - k * 10, "white", 2, 0.5, true, fade)

## 8.4 (his ask, 6 Oct): the odds of the next roll, left of the panel: how much of the weight of
## every trait that can be offered (G.trait_weight, the very numbers offer_traits draws with) trains
## each attribute, the chance a SUPER trait is among the first pick, and luck's chance of a 4th row.
static func odds(p: Player) -> Dictionary:
	var w := { "str": 0, "dex": 0, "int": 0, "any": 0, "super": 0 }
	var tot := 0
	for tr in Traits.all():
		var tw: int = G.trait_weight(p, tr)
		if tw <= 0:
			continue
		tot += tw
		var a: String = Attributes.FAMILY_ATTR.get(tr["fam"], "any")
		w[a] += tw
		if tr["rarity"] == "super":
			w["super"] += tw
	var out := {}
	for k in w:
		out[k] = 0.0 if tot == 0 else float(w[k]) / tot
	out["fourth"] = minf(0.9, p.luck * 0.15) if p.luck > 0 else 0.0
	return out

static func _odds(ci: CanvasItem, p: Player) -> float:
	if not G.tchoice.has("odds"):
		G.tchoice["odds"] = odds(p)   # worked out once per pick screen
	var o: Dictionary = G.tchoice["odds"]
	var rows := [["mi_str", "STR", "red", o["str"]], ["mi_dex", "DEX", "lime", o["dex"]], ["mi_int", "INT", "cyan", o["int"]],
		["", "ANY", "tan", o["any"]], ["mi_crit", "SUPER", "pink", o["super"]], ["mi_luck", "4TH ROW", "lime", o["fourth"]]]
	var x := float(COL_X)
	var y := float(ROW_Y)
	var h := 16 + rows.size() * 9
	Gfx.panel(ci, x, y, COL_W, h, "#f4ecd8", "#0c0b12")
	Gfx.text(ci, "NEXT ROLL ODDS:", x + 5, y + 4, "white")
	for i in rows.size():
		var r: Array = rows[i]
		var ry := y + 15 + i * 9
		if r[0] != "":
			Gfx.at(ci, r[0], x + 5, ry - 1)
		Gfx.text(ci, r[1], x + 15, ry, r[2])
		Gfx.text(ci, ">", x + COL_W - 34, ry, "white")
		Gfx.text(ci, "%d%%" % roundi(r[3] * 100.0), x + COL_W - 6, ry, "lime" if r[3] > 0 else "dim", 1, 1.0)
	return y + h

## Keyword panels beside the panel, level with the chosen row.
static func _keywords(ci: CanvasItem, tr: Dictionary, y: float) -> void:
	var seen := {}
	var x := COL_X
	var w := COL_W
	for word in (tr["name"] + " " + tr["desc"]).split(" ", false):
		var key := _bare(word)
		if not KEYWORDS.has(key) or seen.has(KEYWORDS[key][1]):
			continue
		seen[KEYWORDS[key][1]] = true
		var lines := Gfx.wrap_text(KEYWORDS[key][1], w - 8)
		var h := 14 + lines.size() * 8
		if y + h > FOOT_Y - 8:
			break
		Gfx.panel(ci, x, y, w, h, "#8b8f9c", "#0c0b12")
		Gfx.text(ci, key, x + 4, y + 3, KEYWORDS[key][0])
		for j in lines.size():
			Gfx.text(ci, lines[j], x + 4, y + 12 + j * 8, "white")
		y += h + 3

static func _bare(word: String) -> String:
	var out := ""
	for ch in word.to_upper():
		if ch >= "A" and ch <= "Z":
			out += ch
	return out

## A text broken into lines of [word, colour, icon]: keywords in their colour with their icon,
## numbers in lime.
static func rich_lines(s: String, max_w: int, base: String = "white") -> Array:
	var lines := []
	var cur := []
	var cur_w := 0
	for word in s.split(" ", false):
		var col := base
		var key := _bare(word)
		if KEYWORDS.has(key):
			col = KEYWORDS[key][0]
		elif word.length() > 0 and (word[0] == "+" or word[0] == "-" or (word[0] >= "0" and word[0] <= "9")):
			col = "lime"
		var seg := [word, col, ICONS.get(key, "")]
		var ww := seg_w(seg)
		if cur_w > 0 and cur_w + 4 + ww > max_w:
			lines.append(cur)
			cur = []
			cur_w = 0
		cur.append(seg)
		cur_w += (4 if cur_w > 0 else 0) + ww
	if not cur.is_empty():
		lines.append(cur)
	return lines

## Like Gfx.wrap_text, but counting the keyword icons (for lines drawn with ItemShow.rich_line).
static func wrap_rich(s: String, max_w: int) -> PackedStringArray:
	var out := PackedStringArray()
	for line in rich_lines(s, max_w):
		out.append(" ".join(line.map(func(sg): return sg[0])))
	return out

static func seg_w(seg: Array) -> int:
	return TB.text_w(seg[0]) + (8 if seg.size() > 2 and seg[2] != "" else 0)

static func line_w(line: Array) -> int:
	var w := 0
	for seg in line:
		w += seg_w(seg) + 4
	return maxi(0, w - 4)

## One line of rich_lines at x (its left edge), y.
static func draw_line(ci: CanvasItem, line: Array, x: float, y: float, alpha: float = 1.0) -> void:
	for seg in line:
		Gfx.text(ci, seg[0], x, y, seg[1], 1, 0.0, true, alpha)
		if seg.size() > 2 and seg[2] != "":
			Gfx.at(ci, seg[2], x + TB.text_w(seg[0]) + 1, y - 1, alpha)
		x += seg_w(seg) + 4

## A whole text, wrapped to max_w and coloured; align 0 = left edge at x, 0.5 = centred on x.
## Returns how many lines it took (8 px each).
static func draw_rich(ci: CanvasItem, s: String, x: float, y: float, max_w: int, align: float = 0.0, base: String = "white", alpha: float = 1.0) -> int:
	var lines := rich_lines(s, max_w, base)
	for j in lines.size():
		draw_line(ci, lines[j], x - line_w(lines[j]) * align, y + j * 8, alpha)
	return lines.size()
