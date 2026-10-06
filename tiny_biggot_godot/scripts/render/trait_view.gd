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
const PX := 104         # the panel
const PW := 240
const ROW_Y := 30
const ROW_H := 44
const ROW_STEP := 48

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
	return Rect2(PX + 8, ROW_Y + i * ROW_STEP, PW - 16, ROW_H)

# ---------- Drawing ----------
static func draw(ci: CanvasItem) -> void:
	var c := G.tchoice
	var t := age()
	var p := G.player
	if t < BURST:
		_burst(ci, t / BURST, p)
		return
	ci.draw_rect(Rect2(0, 0, TB.SW, TB.SH), Color(0.02, 0.02, 0.04, minf(0.85, (t - BURST) * 4.0 + 0.5)))
	Gfx.text(ci, "LEVEL %d" % p.level, 52, 34, "lime", 2, 0.5)
	if p.pending > 1:
		Gfx.text(ci, "+%d MORE" % (p.pending - 1), 52, 52, "lime", 1, 0.5)
	# The frame and its title plate.
	var fh := 4 * ROW_STEP + 8
	Gfx.panel(ci, PX, ROW_Y - 6, PW, fh, "#4d9be6", "#0c0b12")
	ci.draw_rect(Rect2(PX + 3, ROW_Y - 3, PW - 6, fh - 6), TB.c("#2b4f8a"), false, 1.0)
	Gfx.panel(ci, TB.SW / 2 - 60, ROW_Y - 20, 120, 14, "#f4ecd8", "#0c0b12")
	Gfx.text(ci, "CHOOSE A TRAIT", TB.SW / 2, ROW_Y - 16, "white", 1, 0.5)
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
			Gfx.text(ci, "INCREASE YOUR LUCK", r.get_center().x, r.position.y + 14, "dim", 1, 0.5)
			Gfx.text(ci, "FOR A CHANCE OF 4 CHOICES", r.get_center().x, r.position.y + 24, "dim", 1, 0.5)
		if k < 1.0:
			_shine(ci, r, k)
	if t >= BURST + 4 * ROW_GAP and c["idx"] < opts.size():
		_keywords(ci, opts[c["idx"]], row_rect(c["idx"]).position.y)
	var reroll := "REROLL (%d LEFT)" % p.rerolls if p.rerolls > 0 else "REROLL (%d GOLD)" % G.reroll_cost()
	Gfx.text(ci, "UP/DOWN  CHOOSE    USE  TAKE    MENU  " + reroll, TB.SW / 2, ROW_Y + fh, "grey", 1, 0.5)

static func _row(ci: CanvasItem, r: Rect2, tr: Dictionary, sel: bool, a: float) -> void:
	var fam: Dictionary = Traits.FAMILIES[tr["fam"]]
	var border: String = "#f2c94c" if sel else "#8b8f9c"
	Gfx.panel(ci, r.position.x, r.position.y, r.size.x, r.size.y, border, "#14121c" if sel else "#0c0b12")
	# The icon box.
	var ib := Rect2(r.position.x + 5, r.position.y + 8, 26, 26)
	Gfx.panel(ci, ib.position.x, ib.position.y, ib.size.x, ib.size.y, fam["hex"], "#0c0b12")
	Gfx.sp(ci, FAM_ICON.get(tr["fam"], "fam_core"), ib.get_center().x, ib.end.y - 3, 2, 2, 0.0, false, a)
	var tx := r.position.x + 36
	Gfx.text(ci, tr["name"], tx, r.position.y + 4, fam["col"], 1, 0.0, true, a)
	var rank: int = G.player.traits.get(tr["id"], 0)
	var pips := ""
	for k in tr["max"]:
		pips += "*" if k < rank else ("+" if k == rank else "-")
	Gfx.text(ci, pips, r.end.x - 5, r.position.y + 4, "tan", 1, 1.0, true, a)
	if tr["new"]:
		var rar: Dictionary = Traits.RARITY[tr["rarity"]]
		Gfx.text(ci, rar["name"], r.end.x - 5, r.end.y - 9, rar["col"], 1, 1.0, true, a)
	var lines := rich_lines(tr["desc"], int(r.size.x) - 42)
	for j in mini(3, lines.size()):
		draw_line(ci, lines[j], tx, r.position.y + 14 + j * 8, a)

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

## Keyword panels beside the panel, level with the chosen row.
static func _keywords(ci: CanvasItem, tr: Dictionary, y: float) -> void:
	var seen := {}
	var x := PX + PW + 6
	var w := TB.SW - x - 4
	for word in (tr["name"] + " " + tr["desc"]).split(" ", false):
		var key := _bare(word)
		if not KEYWORDS.has(key) or seen.has(KEYWORDS[key][1]):
			continue
		seen[KEYWORDS[key][1]] = true
		var lines := Gfx.wrap_text(KEYWORDS[key][1], w - 8)
		var h := 14 + lines.size() * 8
		if y + h > TB.SH - 30:
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
