class_name Enchant
extends RefCounted
## Stage 46 WEAPON ENCHANTMENTS (his pictures of a wiki's "Weapon Enchantments", 10 Oct: "Learn
## from that, we will add this later", then "Ok go 44 and 45, and 46"; ENCHANTMENTS_PLAN.md). Ideas
## only: every one has a name of our own. A weapon carries one enchantment at most (w["ench"], and
## w["ench_v"] for CONTRABAND's pick), on its own copy of the weapon, as the anvil's levels are; a
## new one replaces it. Its name goes before the weapon's (WeaponInfo.display_name), and the item
## card says what it does. Applied and taken back with the weapon (Weapons.equip_weapon, src
## "ench"). Expanded game only: classic weapons stay plain.
##   KINDS   id: [name, group, what it does, effects, more]; more: "el" [element, least, most]
##           (an element's hit on every weapon hit, as an infusion's: Infusions.on_hit), "grade" +-1
##           (every scaling grade a step: Attributes.scaling), "plus" n (anvil levels:
##           WeaponInfo.plus), "needs" an element on the weapon for it to work (has_element).
##   GROUPS  bad, good, grand (legendary), rare (only from their places), old (gone from the game
##           it comes from; kept here, rule 1).
## Where they come from: weapons as they drop (DROP by rarity, Weapons.random_weapon; grand ones
## only on rare or better, bad ones mostly on common), THE ENCHANTER in the expanded shops (pay to
## roll one onto the weapon you hold), and the rare ones from their places: THE WYRM'S BREATH (a
## special room: four breaths, one may char), THE CHOP SHOP's runesmith (RUNESMITHED), THE PAWN
## SHOP's back room (CONTRABAND) and THE FROG POND's silver branch (SPELLBOUND).
## gf hooks read in combat: ench_top (Might.roll), slay_dragon, slay_fiend, slay_boss,
## ench_afflicted, ench_armored, ench_ready (foe_mult), ench_burn (the burn tick), ench_chill and
## ench_shock (Statuses.apply), and the stats they add as Effects ops.

const GROUP_COL := { "bad": "red", "good": "lime", "grand": "gold", "rare": "purple", "old": "cyan" }
const GROUP_HEX := { "bad": "#d8443c", "good": "#8fd14f", "grand": "#f2c94c", "rare": "#a35bd6", "old": "#6fd3e0" }
const GROUP_NAME := { "bad": "FLAWED", "good": "ENCHANTED", "grand": "LEGENDARY", "rare": "RARE", "old": "OLD LORE" }

const KINDS := {
	# ---- bad
	"dull": ["DULL", "bad", "EVERY SCALING GRADE ONE STEP LOWER", [], { "grade": -1 }],
	"chipped": ["CHIPPED", "bad", "-10% DAMAGE", [["mul", "dmg", 0.9]], {}],
	"cracked": ["CRACKED", "bad", "-20% DAMAGE", [["mul", "dmg", 0.8]], {}],
	"sluggish": ["SLUGGISH", "bad", "-10% FIRE RATE", [["mul", "rate", 0.9]], {}],
	"leaden": ["LEADEN", "bad", "-20% FIRE RATE", [["mul", "rate", 0.8]], {}],
	# ---- good
	"honed": ["HONED", "good", "+10% CRIT CHANCE", [["add", "crit", 0.1]], {}],
	"drakebane": ["DRAKEBANE", "good", "TWICE THE DAMAGE TO WYRMS AND WORMS", [["hook", "slay_dragon", 1]], {}],
	"wicked": ["WICKED", "good", "CRITS DEAL +0.75X MORE", [["add", "crit_mult", 0.75]], {}],
	"venomous": ["VENOMOUS", "good", "HITS DEAL +2-3 POISON DAMAGE AND MAY POISON", [], { "el": ["poison", 2.0, 3.0] }],
	"brisk": ["BRISK", "good", "+10% FIRE RATE", [["mul", "rate", 1.1]], {}],
	"crackling": ["CRACKLING", "good", "HITS DEAL +0.5-7.5 LIGHTNING DAMAGE AND MAY SHOCK", [], { "el": ["lightning", 0.5, 7.5] }],
	"savage": ["SAVAGE", "good", "+10% DAMAGE", [["mul", "dmg", 1.1]], {}],
	"frosted": ["FROSTED", "good", "HITS DEAL +2-3 COLD DAMAGE AND MAY CHILL", [], { "el": ["cold", 2.0, 3.0] }],
	"jolly": ["JOLLY", "good", "+10% LUCKY HIT CHANCE", [["hook", "lucky", 0.1]], {}],
	"heavyhand": ["HEAVY-HANDED", "good", "THE TOP OF EVERY HIT'S ROLL IS 20% HIGHER", [["hook", "ench_top", 1]], {}],
	"smoldering": ["SMOLDERING", "good", "HITS DEAL +2-3.5 FIRE DAMAGE AND MAY BURN", [], { "el": ["fire", 2.0, 3.5] }],
	"steadfast": ["STEADFAST", "good", "HITS THAT DO NOT CRIT DEAL +20%", [["hook", "nocrit_dmg", 0.2]], {}],
	"fiendbane": ["FIENDBANE", "good", "TWICE THE DAMAGE TO IMPS AND FIENDS", [["hook", "slay_fiend", 1]], {}],
	"nimble": ["NIMBLE", "good", "+5 DEX", [["attr", "dex", 5]], {}],
	"learned": ["LEARNED", "good", "+5 INT", [["attr", "int", 5]], {}],
	"brawny": ["BRAWNY", "good", "+5 STR", [["attr", "str", 5]], {}],
	"scalding": ["SCALDING", "good", "BURNS DEAL +25% (WITH FIRE ON THE WEAPON)", [["hook", "ench_burn", 0.25]], { "needs": "fire" }],
	"biting": ["BITING", "good", "CHILLS ARE 25% STRONGER (WITH COLD ON THE WEAPON)", [["hook", "ench_chill", 0.25]], { "needs": "cold" }],
	"humming": ["HUMMING", "good", "SHOCKS ARE 25% STRONGER (WITH LIGHTNING ON THE WEAPON)", [["hook", "ench_shock", 0.25]], { "needs": "lightning" }],
	# ---- grand (legendary)
	"godforged": ["GODFORGED", "grand", "+30% DAMAGE", [["mul", "dmg", 1.3]], {}],
	"dreadful": ["DREADFUL", "grand", "HITS DEAL +2.5-5 NECROTIC DAMAGE AND MAY CURSE", [], { "el": ["necrotic", 2.5, 5.0] }],
	"hallowed": ["HALLOWED", "grand", "HITS DEAL +2.5-5 HOLY DAMAGE, TWICE ON CURSED AND UNHOLY FOES", [], { "el": ["holy", 2.5, 5.0] }],
	"fortunate": ["FORTUNATE", "grand", "+25% LUCKY HIT CHANCE", [["hook", "lucky", 0.25]], {}],
	"kingslayer": ["KINGSLAYER", "grand", "+20% DAMAGE TO GUARDIANS AND MINI-BOSSES", [["hook", "slay_boss", 0.2]], {}],
	"umbral": ["UMBRAL", "grand", "HITS DEAL +1.5-8.5 DARK DAMAGE AND MAY GLOOM", [], { "el": ["dark", 1.5, 8.5] }],
	"phantasmal": ["PHANTASMAL", "grand", "+25% FIRE RATE", [["mul", "rate", 1.25]], {}],
	"deadeye": ["DEADEYE", "grand", "+20% CRIT CHANCE", [["add", "crit", 0.2]], {}],
	"pitiless": ["PITILESS", "grand", "CRITS DEAL +1.25X MORE", [["add", "crit_mult", 1.25]], {}],
	"gleaming": ["GLEAMING", "grand", "+1 WEAPON LEVEL", [], { "plus": 1 }],
	# ---- rare (only from their places)
	"runesmithed": ["RUNESMITHED", "rare", "EVERY SCALING GRADE ONE STEP HIGHER", [], { "grade": 1 }],
	"contraband": ["CONTRABAND", "rare", "ONE OF: +20% DAMAGE, +15% CRIT CHANCE OR +20% FIRE RATE", [], {}],
	"starlit": ["STARLIT", "rare", "+3 WEAPON LEVELS", [], { "plus": 3 }],
	"wyrmfire": ["WYRMFIRE", "rare", "BURNS DEAL TWICE AS MUCH (WITH FIRE ON THE WEAPON)", [["hook", "ench_burn", 1.0]], { "needs": "fire" }],
	"wyrmfrost": ["WYRMFROST", "rare", "CHILLS ARE TWICE AS STRONG (WITH COLD ON THE WEAPON)", [["hook", "ench_chill", 1.0]], { "needs": "cold" }],
	"wyrmstorm": ["WYRMSTORM", "rare", "SHOCKS ARE TWICE AS STRONG (WITH LIGHTNING ON THE WEAPON)", [["hook", "ench_shock", 1.0]], { "needs": "lightning" }],
	"charred": ["CHARRED", "rare", "-50% DAMAGE", [["mul", "dmg", 0.5]], {}],
	"spellbound": ["SPELLBOUND", "rare", "+25% DAMAGE WHILE YOUR SPECIAL IS READY", [["hook", "ench_ready", 0.25]], {}],
	# ---- old (gone from the game it comes from; kept here)
	"unbinding": ["UNBINDING", "old", "ELITES TAKE +25% MORE", [["add", "elite_mult", 0.25]], {}],
	"storied": ["STORIED", "old", "+25% DAMAGE", [["mul", "dmg", 1.25]], {}],
	"cruel": ["CRUEL", "old", "+10% DAMAGE TO FOES WITH AN AILMENT", [["hook", "ench_afflicted", 0.1]], {}],
	"unyielding": ["UNYIELDING", "old", "+25% DAMAGE TO FOES BEHIND A SHIELD OR ARMOUR PLATES", [["hook", "ench_armored", 0.25]], {}],
}
## CONTRABAND's three: [what, effects]
const CONTRABAND := [["+20% DAMAGE", [["mul", "dmg", 1.2]]], ["+15% CRIT CHANCE", [["add", "crit", 0.15]]], ["+20% FIRE RATE", [["mul", "rate", 1.2]]]]
## The chance a weapon drops with one, by its rarity.
const DROP := { "common": 0.1, "rare": 0.18, "epic": 0.25, "legend": 0.32, "mythic": 0.4 }
## Of those: a bad one, by rarity; a grand one (rare or better only).
const BAD := { "common": 0.35, "rare": 0.2, "epic": 0.1, "legend": 0.05, "mythic": 0.0 }
const GRAND := { "common": 0.0, "rare": 0.05, "epic": 0.12, "legend": 0.2, "mythic": 0.3 }
## The foe kinds of DRAKEBANE and FIENDBANE.
const DRAGONS := ["bookwyrm", "wordworm", "ashworm", "wyrm"]
const FIENDS := ["imp", "torchimp", "chimneyimp", "commaimp", "fiendling", "cinderking", "chainfiend"]

static var stats := {}   # rolled, enchanted (tests)

static func on() -> bool:
	return GameData.rogues()

static func of(w: Variant) -> String:
	return String(w.get("ench", "")) if w is Dictionary else ""

static func group_of(group: String) -> Array:
	return KINDS.keys().filter(func(k): return KINDS[k][1] == group)

## A random one for a weapon of this rarity (never a rare one: those come from their places).
static func roll(rarity: String) -> String:
	var r := randf()
	if r < BAD.get(rarity, 0.0):
		return TB.pick(group_of("bad"))
	if r < BAD.get(rarity, 0.0) + GRAND.get(rarity, 0.0):
		return TB.pick(group_of("grand") + ["storied", "unbinding"])
	return TB.pick(group_of("good") + ["cruel", "unyielding"])

## Weapons.random_weapon: now and then a weapon drops enchanted (a copy of it).
static func maybe(w: Dictionary) -> Dictionary:
	if not on() or randf() >= DROP.get(w["rarity"], 0.0):
		return w
	stats["rolled"] = stats.get("rolled", 0) + 1
	return enchanted(w, roll(w["rarity"]))

## A copy of the weapon with this enchantment (one at most: a new one replaces the old).
static func enchanted(w: Dictionary, id: String) -> Dictionary:
	var c := w.duplicate()
	c["ench"] = id
	if id == "contraband":
		c["ench_v"] = randi() % CONTRABAND.size()
	else:
		c.erase("ench_v")
	return c

## Puts it on the weapon you hold (re-equipped so its stats come and go with it).
static func give(p: Player, id: String) -> void:
	if p.weapon == null or not on():
		return
	var old := of(p.weapon)
	Weapons.equip_weapon(p, enchanted(p.weapon, id))
	stats["enchanted"] = stats.get("enchanted", 0) + 1
	var d: Array = KINDS[id]
	G.show_banner(WeaponInfo.display_name(p.weapon), what(p.weapon) + (("  (" + KINDS[old][0] + " IS GONE)") if old != "" and old != id else ""))
	Fx.burst(p.x, p.y - 6, ["#a35bd6", "#e889c8", "#ffffff"] if d[1] != "bad" else ["#8a2a33", "#4a4458"], 18, 70)
	Snd.play("unlock" if d[1] != "bad" else "hurt")

## What it does, for the item card and the banner.
static func what(w: Dictionary) -> String:
	var id := of(w)
	if id == "":
		return ""
	if id == "contraband":
		return "CONTRABAND: " + CONTRABAND[int(w.get("ench_v", 0))][0]
	return KINDS[id][0] + ": " + KINDS[id][2]

static func effects(w: Dictionary) -> Array:
	var id := of(w)
	if id == "":
		return []
	if id == "contraband":
		return CONTRABAND[int(w.get("ench_v", 0))][1]
	return KINDS[id][3]

## Weapons.equip_weapon: its effects come with the weapon (dir 1) and go with it (dir -1).
static func on_equip(p: Player, w: Variant, dir: int) -> void:
	if not on() or not (w is Dictionary):
		return
	var fx := effects(w)
	if not fx.is_empty():
		Effects.apply_equipment(p, fx, dir, "ench")

# ---------- what they change ----------
## WeaponInfo.display_name: its name before the weapon's.
static func prefix(w: Dictionary) -> String:
	var id := of(w)
	return (KINDS[id][0] + " ") if id != "" and on() else ""

## WeaponInfo.plus: GLEAMING, STARLIT.
static func plus(w: Dictionary) -> int:
	var id := of(w)
	return int(KINDS[id][4].get("plus", 0)) if id != "" and on() else 0

## Attributes.scaling: DULL, RUNESMITHED.
static func grade_shift(w: Dictionary) -> int:
	var id := of(w)
	return int(KINDS[id][4].get("grade", 0)) if id != "" and on() else 0

## Infusions.on_hit: the element a weapon's enchantment carries: [element, least, most], or [].
static func element(p: Player) -> Array:
	var id := of(p.weapon)
	if id == "" or not on():
		return []
	return KINDS[id][4].get("el", [])

## An element on the weapon: its enchantment's, an infusion's, or its family's (pyre, frost, storm).
static func has_element(p: Player, el: String) -> bool:
	var e := element(p)
	if not e.is_empty() and e[0] == el:
		return true
	for inf in p.infusions:
		if Infusions.KINDS[inf[0]][1] == el:
			return true
	var fam: String = { "fire": "pyre", "cold": "frost", "lightning": "storm" }.get(el, "")
	return p.weapon != null and fam != "" and fam in p.weapon.get("tags", [])

## Combat.damage_enemy: the slayers, KINGSLAYER, CRUEL, UNYIELDING, SPELLBOUND.
static func foe_mult(p: Player, e: Enemy) -> float:
	if not on() or p.weapon == null or of(p.weapon) == "":
		return 1.0
	var m := 1.0
	var kind: String = e.boss if e.boss != "" else e.type
	if p.g("slay_dragon") > 0 and kind in DRAGONS:
		m *= 2.0
	if p.g("slay_fiend") > 0 and kind in FIENDS:
		m *= 2.0
	if p.g("slay_boss") > 0 and (e.is_boss() or e.d.get("mini", false) or e.d.get("champion", false)):
		m *= 1.0 + p.g("slay_boss")
	if p.g("ench_afflicted") > 0 and Combat.afflicted(e):
		m *= 1.0 + p.g("ench_afflicted")
	if p.g("ench_armored") > 0 and (e.guard_t > 0 or (Armor.has(e) and e.armor > 0)):
		m *= 1.0 + p.g("ench_armored")
	if p.g("ench_ready") > 0 and p.special_cd <= 0:
		m *= 1.0 + p.g("ench_ready")
	return m

## The burn tick: SCALDING, WYRMFIRE (with fire on the weapon).
static func burn_mult(p: Player) -> float:
	if not on() or p.g("ench_burn") <= 0 or not has_element(p, "fire"):
		return 1.0
	return 1.0 + p.g("ench_burn")

## Statuses.apply: BITING, WYRMFROST (chill), HUMMING, WYRMSTORM (shock).
static func status_mult(p: Player, name: String) -> float:
	if not on() or p == null:
		return 1.0
	if name == "chill" and p.g("ench_chill") > 0 and has_element(p, "cold"):
		return 1.0 + p.g("ench_chill")
	if name == "shock" and p.g("ench_shock") > 0 and has_element(p, "lightning"):
		return 1.0 + p.g("ench_shock")
	return 1.0

# ---------- THE ENCHANTER ----------
## An expanded shop: the enchanter's table, between the dice cup and the weapon.
static func stock_shop(r: Room, cx: float, cy: float) -> void:
	r.objects.append({ "kind": "enchanter", "x": cx - 72, "y": cy + 34 })

static func enchanter_price() -> int:
	return G.price(30 + 8 * G.floor_index + 20 * int(G.run_stats.get("enchanter", 0)))

## Paid: an enchantment rolled onto the weapon you hold (a grand one only on rare or better).
static func use_enchanter(o: Dictionary) -> void:
	var p := G.player
	if p.weapon == null:
		return G.deny(o, "HOLD A WEAPON")
	var cost := enchanter_price()
	if p.gold < cost:
		return G.deny(o, "NEED %d GOLD" % cost)
	p.gold -= cost
	G.run_stats["enchanter"] = int(G.run_stats.get("enchanter", 0)) + 1
	give(p, roll(p.weapon["rarity"]))

# ---------- the rare ones' places ----------
## THE WYRM'S BREATH: four breaths, one per visit; a fifth of the time it chars the weapon.
const BREATHS := { "star": ["STARLIGHT", "starlit", "#f2c94c"], "fire": ["FIRE", "wyrmfire", "#e8873a"],
	"ice": ["ICE", "wyrmfrost", "#6fd3e0"], "storm": ["STORM", "wyrmstorm", "#a35bd6"] }

## EventRooms.setup: the room's four stones, a breath in each.
static func setup_breath(r: Room, cx: float, cy: float) -> void:
	var keys := BREATHS.keys()
	for i in keys.size():
		r.objects.append({ "kind": "e_breath", "breath": keys[i], "x": cx - 72 + i * 48, "y": cy })

static func breathe(o: Dictionary) -> void:
	var p := G.player
	if p.weapon == null:
		return G.deny(o, "HOLD A WEAPON")
	for b in G.room.objects:
		if b.get("kind", "") == "e_breath":
			b["used"] = true   # one breath per visit: the other stones go cold
	give(p, "charred" if randf() < 0.2 else BREATHS[o["breath"]][1])

## The runesmith (THE CHOP SHOP), the back room (THE PAWN SHOP), the silver branch (THE FROG POND).
static func special_price(kind: String) -> int:
	match kind:
		"e_runesmith": return G.price(60 + 10 * G.floor_index, "law")
		"e_contraband": return G.price(45 + 8 * G.floor_index, "evil")
	return 0

static func use_special(o: Dictionary) -> void:
	var p := G.player
	if p.weapon == null:
		return G.deny(o, "HOLD A WEAPON")
	if o.get("used", false):
		return G.deny(o, "IT HAS NOTHING MORE TO GIVE")
	var cost := special_price(o["kind"])
	if p.gold < cost:
		return G.deny(o, "NEED %d GOLD" % cost)
	p.gold -= cost
	o["used"] = true
	give(p, { "e_runesmith": "runesmithed", "e_contraband": "contraband", "e_branch": "spellbound" }[o["kind"]])

## THE CHOP SHOP, THE PAWN SHOP and THE FROG POND (EventRooms.setup): each keeps one of these.
static func place_special(r: Room, kind: String, x: float, y: float) -> void:
	if on():
		r.objects.append({ "kind": kind, "x": x, "y": y })

# ---------- in the room (game.gd interact, overlay_view, world_view) ----------
const OBJECTS := ["enchanter", "e_breath", "e_runesmith", "e_contraband", "e_branch"]

static func handles(kind: String) -> bool:
	return kind in OBJECTS

static func interact(o: Dictionary) -> void:
	match o["kind"]:
		"enchanter": use_enchanter(o)
		"e_breath": breathe(o)
		_: use_special(o)

## [title, what it does, what it costs].
static func prompt(o: Dictionary) -> Array:
	var p := G.player
	var now := of(p.weapon) if p != null else ""
	var swap := (" (%s GOES)" % KINDS[now][0]) if now != "" else ""
	match o["kind"]:
		"enchanter":
			return ["THE ENCHANTER", "AN ENCHANTMENT FOR THE WEAPON YOU HOLD, AT RANDOM. A NEW ONE REPLACES THE OLD" + swap,
				"PAY %d GOLD" % enchanter_price()]
		"e_breath":
			var b: Array = BREATHS[o["breath"]]
			var k: Array = KINDS[b[1]]
			return [b[0] + " BREATH", k[0] + ": " + k[2] + ". ONE TIME IN FIVE IT CHARS THE WEAPON (-50% DAMAGE)" + swap,
				"ONE OF THE FOUR STONES"]
		"e_runesmith":
			return ["THE RUNESMITH", "RUNESMITHED: " + KINDS["runesmithed"][2] + swap,
				"PAY %d GOLD" % special_price(o["kind"]) + Alignments.price_note(p, "law")]
		"e_contraband":
			return ["THE BACK ROOM", "CONTRABAND: " + KINDS["contraband"][2] + swap,
				"PAY %d GOLD" % special_price(o["kind"]) + Alignments.price_note(p, "evil")]
		"e_branch":
			return ["A SILVER BRANCH", "SPELLBOUND: " + KINDS["spellbound"][2] + swap, "TOUCH IT TO YOUR WEAPON"]
	return []

## An enchanted weapon lying on the floor or in a shop glints in its group's colour (world_view).
static func glint(ci: CanvasItem, w: Dictionary, x: float, y: float, t: float) -> void:
	var id := of(w)
	if id == "" or floori(t * 2.5 + x * 0.1) % 3 != 0:
		return
	Gfx.px(ci, TB.c(GROUP_HEX[KINDS[id][1]]), roundf(x + 6), roundf(y - 7))
	Gfx.px(ci, TB.c("#ffffff"), roundf(x + 6), roundf(y - 8))

static func draw(ci: CanvasItem, o: Dictionary, t: float) -> void:
	var x := roundf(o["x"])
	var y := roundf(o["y"])
	var used: bool = o.get("used", false)
	match o["kind"]:
		"enchanter":
			Gfx.sp(ci, "o_enchanter", x, y)
			for k in 3:   # sparks turning over the open book
				var a := t * 2.2 + k * TAU / 3.0
				Gfx.px(ci, TB.c(["#a35bd6", "#e889c8", "#ffffff"][k]), roundf(x + cos(a) * 6), roundf(y - 11 + sin(a) * 2))
			var cost := enchanter_price()
			var label := "%dG" % cost
			Gfx.text(ci, label, roundf(x - TB.text_w(label) / 2), roundf(y + 11), "gold" if G.player.gold >= cost else "red")
		"e_breath":
			var b: Array = BREATHS[o["breath"]]
			Gfx.sp(ci, "o_breath", x, y, 2, 2, 0.0, false, 0.45 if used else 1.0)
			if not used:   # its breath, out of the jaw
				for k in 5:
					var ph := fmod(t * 1.4 + k * 0.2, 1.0)
					Gfx.px(ci, TB.c(b[2]), roundf(x + 13 + ph * 15), roundf(y - 1 + sin(ph * 7.0 + k) * (1.0 + ph * 3.0)), 2)
			Gfx.text(ci, b[0], x, y + 19, "dim" if used else { "star": "gold", "fire": "orange", "ice": "cyan", "storm": "purple" }[o["breath"]], 1, 0.5)
		"e_runesmith":
			Gfx.sp(ci, "o_runeforge", x, y, 2, 2, 0.0, false, 0.45 if used else 1.0)
			if not used and floori(t * 3.0 + x) % 4 == 0:
				Gfx.px(ci, TB.c("#ffffff"), x - 9 + floori(t * 3.0) % 3 * 8, y - 9, 2)
		"e_contraband":
			Gfx.sp(ci, "o_contraband", x, y, 2, 2, 0.0, false, 0.45 if used else 1.0)
		"e_branch":
			Gfx.sp(ci, "o_branch", x, y - 6, 2, 2, 0.0, false, 0.45 if used else 1.0)
			if not used and floori(t * 2.0) % 3 == 0:
				Gfx.px(ci, TB.c("#ffffff"), x + 6, y - 20)
