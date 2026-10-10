class_name Infusions
extends RefCounted
## Stage 44 INFUSIONS (his pictures, 10 Oct: a wiki's infusions; ideas only, our own names and
## pictures, TRAITS_PLAN.md). A belt item, used like a drink: it steeps your weapon in an element.
## From then on every hit of the weapon itself (a swing, or one of its own shots) deals that
## element's damage too, as a hit of its own that grows with the floor and with all that makes your
## hits stronger, and a quarter of the time its ailment: fire burns, cold chills, lightning shocks,
## poison poisons, nature makes the foe bleed. Holy has no ailment: it deals twice as much to a
## cursed foe and to the unholy (UNHOLY).
##   SAPS     last ROOMS rooms (PIXIE SAP turns into one of them; BLESSED DEW is holy)
##   SPICES   for good
##   AMBERS   for good, and stronger
## Up to SLOTS kinds at once: one more pushes out the oldest that wears off, else the oldest. The
## same kind again is one more stack (its damage once more) and starts its rooms over.
## ENDLESS INFUSION (dex_temper): they never wear off and deal 25% more. SLOW TIME (psy_dilation): a
## room longer every time you use your special. Found on bosses and some elites
## (Consumables.random_kind), in chests (Game.open_choice) and at a shop stall. Expanded game only.

const ROOMS := 10
const SLOTS := 5
const AILMENT := 0.25        # the chance a hit brings the element's ailment
const FLOOR_GROWTH := 0.25   # +25% damage a floor

## element: [the colour of its numbers, its ailment (Statuses), its word]
const ELEMENTS := {
	"fire": ["orange", "burn", "FIRE"],
	"cold": ["cyan", "chill", "COLD"],
	"lightning": ["purple", "shock", "LIGHTNING"],
	"poison": ["lime", "poison", "POISON"],
	"nature": ["green", "bleed", "NATURE"],
	"holy": ["bone", "", "HOLY"],
}
const AILMENT_WORD := { "burn": "BURN", "chill": "CHILL", "shock": "SHOCK", "poison": "POISON", "bleed": "MAKE FOES BLEED" }
## kind (its picture too): [name, element ("": PIXIE SAP), least, most damage a hit, rooms (0: for
## good), weight, colour]
const KINDS := {
	"inf_embersap": ["EMBER SAP", "fire", 1.0, 4.0, ROOMS, 10, "#ff7a2e"],
	"inf_rimesap": ["RIME SAP", "cold", 1.5, 3.5, ROOMS, 10, "#7fd8ff"],
	"inf_sparksap": ["SPARK SAP", "lightning", 0.5, 5.0, ROOMS, 10, "#c890ff"],
	"inf_briarsap": ["BRIAR SAP", "nature", 1.5, 3.5, ROOMS, 10, "#5fc96a"],
	"inf_moldsap": ["MOLD SAP", "poison", 2.5, 3.0, ROOMS, 10, "#8ae04a"],
	"inf_pixiesap": ["PIXIE SAP", "", 0.0, 0.0, ROOMS, 6, "#e889c8"],
	"inf_blessdew": ["BLESSED DEW", "holy", 3.5, 5.0, ROOMS, 6, "#fff3b0"],
	"inf_cinderspice": ["CINDER SPICE", "fire", 1.0, 4.0, 0, 4, "#e8873a"],
	"inf_frostspice": ["FROST SPICE", "cold", 1.5, 3.5, 0, 4, "#4d9be6"],
	"inf_thunderspice": ["THUNDER SPICE", "lightning", 0.5, 5.0, 0, 4, "#f2c94c"],
	"inf_viperspice": ["VIPER SPICE", "poison", 2.0, 3.0, 0, 4, "#63b84f"],
	"inf_blazeamber": ["BLAZE AMBER", "fire", 3.0, 7.0, 0, 2, "#ff9b3a"],
	"inf_glacieramber": ["GLACIER AMBER", "cold", 4.5, 6.0, 0, 2, "#b8ecff"],
	"inf_stormamber": ["STORM AMBER", "lightning", 0.5, 10.0, 0, 2, "#ffe14a"],
}
## What PIXIE SAP can turn into.
const SAPS := ["inf_embersap", "inf_rimesap", "inf_sparksap", "inf_briarsap", "inf_moldsap", "inf_blessdew"]
## Foes holy deals twice as much to (so does any cursed foe): the dead that walk, imps and fiends,
## and the cults and knights that serve the dark.
const UNHOLY := ["skeleton", "ghost", "imp", "cultist", "hexwife", "torchimp", "chimneyimp", "voidling",
	"shadeknight", "eclipsed", "pagewraith", "graveborn", "fiendling", "blackknight", "carrionknight",
	"candlewight", "bloodleech", "rotking", "tombspider", "gargoyle"]

static var stats := {}   # used, hits, worn, pushed (tests)

static func on() -> bool:
	return GameData.rogues()

static func is_kind(k: String) -> bool:
	return KINDS.has(k)

static func roll() -> String:
	var w := {}
	for k in KINDS:
		w[k] = KINDS[k][5]
	return TB.weighted(w)

static func forever(k: String) -> bool:
	return KINDS[k][4] == 0

static func _num(v: float) -> String:
	return str(int(v)) if v == floorf(v) else "%.1f" % v

## Its belt card (Consumables.data): name, what it does, colour.
static func card(k: String) -> Dictionary:
	var d: Array = KINDS[k]
	if d[1] == "":
		return { "name": d[0], "desc": "TURNS INTO A RANDOM SAP: AN ELEMENT ON YOUR WEAPON FOR %d ROOMS" % ROOMS, "col": d[6] }
	var el: Array = ELEMENTS[d[1]]
	var what: String = ("AND MAY " + AILMENT_WORD[el[1]]) if el[1] != "" else "TWICE ON CURSED AND UNHOLY FOES"
	return { "name": d[0], "desc": "WEAPON HITS DEAL +%s-%s %s DAMAGE %s, %s" % [_num(d[2]), _num(d[3]), el[2], what,
		"FOR GOOD" if d[4] == 0 else "FOR %d ROOMS" % d[4]], "col": d[6] }

## A chance of one at x, y (Game.open_choice: chests).
static func maybe(chance: float, x: float, y: float) -> void:
	if on() and G.player != null and randf() < chance:
		Combat.drop_pickup(roll(), x, y)

# ---------- steeping ----------
## Consumables.use: the weapon takes the element.
static func infuse(p: Player, kind: String) -> void:
	if not on() or not KINDS.has(kind):
		return
	if KINDS[kind][1] == "":
		kind = TB.pick(SAPS)   # PIXIE SAP: one of the saps
		Fx.float_text(p.x, p.y - 36, "IT BECOMES " + KINDS[kind][0], "pink")
	stats["used"] = stats.get("used", 0) + 1
	for inf in p.infusions:
		if inf[0] == kind:   # the same again: one more stack, and its rooms start over
			inf[2] += 1
			inf[1] = KINDS[kind][4]
			Fx.float_text(p.x, p.y - 28, "%s X%d" % [KINDS[kind][0], inf[2]], "gold")
			return
	while p.infusions.size() >= SLOTS:
		_push_out(p)
	p.infusions.append([kind, KINDS[kind][4], 1])
	Fx.float_text(p.x, p.y - 28, ELEMENTS[KINDS[kind][1]][2] + " ON YOUR WEAPON", ELEMENTS[KINDS[kind][1]][0])

static func _push_out(p: Player) -> void:
	var i := 0
	for j in p.infusions.size():
		if p.infusions[j][1] > 0:   # the oldest that would wear off goes first
			i = j
			break
	G.toast("%s PUSHED OUT" % KINDS[p.infusions[i][0]][0], "grey")
	p.infusions.remove_at(i)
	stats["pushed"] = stats.get("pushed", 0) + 1

## Game.enter_room: every sap a room less (ENDLESS INFUSION: never).
static func on_room(p: Player) -> void:
	if p == null or p.infusions.is_empty() or p.g("infuse_forever") > 0:
		return
	var i := 0
	while i < p.infusions.size():
		var inf: Array = p.infusions[i]
		if inf[1] > 0:
			inf[1] -= 1
			if inf[1] <= 0:
				p.infusions.remove_at(i)
				stats["worn"] = stats.get("worn", 0) + 1
				G.toast("THE %s WORE OFF" % KINDS[inf[0]][0], "grey")
				continue
		i += 1

## SLOW TIME (Marvels.on_special): every sap n rooms longer.
static func stretch(p: Player, n: int) -> void:
	for inf in p.infusions:
		if inf[1] > 0:
			inf[1] += n

# ---------- the hits ----------
## Combat.on_hit_effects, for a hit of the weapon itself: the elements' hit, and their ailments.
static func on_hit(p: Player, e: Enemy) -> void:
	if p.infusions.is_empty() or e.hp <= 0 or not on():
		return
	var scale := (1.0 + FLOOR_GROWTH * G.floor_index) * (1.0 + p.g("infuse_dmg"))
	var dmg := 0.0
	var best := 0.0
	var col := "white"
	for inf in p.infusions:
		var d: Array = KINDS[inf[0]]
		var el: Array = ELEMENTS[d[1]]
		var v: float = randf_range(d[2], d[3]) * inf[2] * scale
		if d[1] == "holy" and (e.curse_t > 0 or e.type in UNHOLY):
			v *= 2.0
		dmg += v
		if v > best:
			best = v
			col = el[0]
		if el[1] != "" and randf() < AILMENT:
			Statuses.apply(e, el[1], 1, v)
	stats["hits"] = stats.get("hits", 0) + 1
	Combat.damage_enemy(e, dmg, { "silent": true, "no_crit": true, "col": col })

# ---------- shops and the HUD ----------
## An expanded shop: one infusion for sale.
static func stock_shop(r: Room, cx: float, cy: float) -> void:
	var k := roll()
	r.objects.append({ "kind": "shop", "item": "infusion", "infusion": k, "x": cx + 72, "y": cy + 34,   # between the gear and the anvil
		"price": G.price((24 if forever(k) else 14) + G.floor_index * 3) })

## The HUD, after the drinks under the belt: each infusion on, with its rooms left (* for good).
static func draw_hud(ci: CanvasItem, p: Player, x: float, y: float) -> void:
	var always := p.g("infuse_forever") > 0
	for inf in p.infusions:
		Gfx.at(ci, inf[0], x, y - 1)
		var t: String = "*" if always or inf[1] <= 0 else str(inf[1])
		if inf[2] > 1:
			t += "X%d" % inf[2]
		Gfx.text(ci, t, x + 11, y + 2, ELEMENTS[KINDS[inf[0]][1]][0])
		x += 14 + TB.text_w(t)
