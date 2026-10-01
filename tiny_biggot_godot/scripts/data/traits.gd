class_name Traits
extends RefCounted
## Level-up traits, build families and hero skill trees (01b_traits.rb, extended
## by the content batches). Each trait pick applies its effects once; picking
## it again stacks another rank. Rows are
## [id, family, max rank, name, desc, capstone, effects, rarity, tags, tier_effects].
## The original 72 traits (no rarity column) were converted mechanically from
## their Ruby lambdas and are checked against the Ruby by tests/effects_test.gd.

const FAMILIES := {
	"core": { "name": "CORE", "col": "tan", "hex": "#c9c2a8" },
	"pyre": { "name": "PYRE", "col": "orange", "hex": "#e8873a" },
	"frost": { "name": "FROST", "col": "cyan", "hex": "#6fd3e0" },
	"venom": { "name": "VENOM", "col": "lime", "hex": "#b8e05a" },
	"storm": { "name": "STORM", "col": "cyan", "hex": "#4d9be6" },
	"blood": { "name": "BLOOD", "col": "red", "hex": "#d8443c" },
	"bulwark": { "name": "BULWARK", "col": "grey", "hex": "#8b8f9c" },
	"shadow": { "name": "SHADOW", "col": "purple", "hex": "#a35bd6" },
	"arcane": { "name": "ARCANE", "col": "pink", "hex": "#e86fb4" },
	"fortune": { "name": "FORTUNE", "col": "gold", "hex": "#f2c94c" },
	"demolition": { "name": "DEMOLITION", "col": "orange", "hex": "#d8443c" },
	"swarm": { "name": "SWARM", "col": "gold", "hex": "#e8873a" },
	# New archetype families (design spec section 4).
	"edge": { "name": "EDGE", "col": "white", "hex": "#f4ecd8" },
	"fury": { "name": "FURY", "col": "red", "hex": "#e8573a" },
	"malice": { "name": "MALICE", "col": "purple", "hex": "#7a3a8c" },
}

## The 12 build archetypes of the design spec and the family that carries each.
## Nine reuse an original family; crit, berserk and curse are new.
const ARCHETYPES := [
	{ "name": "CRIT", "fam": "edge" }, { "name": "BLEED / BLOOD", "fam": "blood" }, { "name": "FIRE", "fam": "pyre" },
	{ "name": "POISON", "fam": "venom" }, { "name": "LIGHTNING", "fam": "storm" }, { "name": "PROJECTILE STORM", "fam": "arcane" },
	{ "name": "SUMMONER", "fam": "swarm" }, { "name": "ROLL / EVASION", "fam": "shadow" }, { "name": "TANK / THORNS", "fam": "bulwark" },
	{ "name": "BERSERK", "fam": "fury" }, { "name": "GREED", "fam": "fortune" }, { "name": "CURSE", "fam": "malice" },
]

## Family bonuses unlock at 2, 4 and 6 total ranks in that family: [name, effects].
## The first eleven are the originals (converted from Ruby); edge, fury and
## malice are new.
const FAMILY_BONUS := {
	"pyre": [["+10% BURN CHANCE", [["add", "burn", 0.1]]], ["BURNS DEAL +50% DAMAGE", [["add", "burn_dmg", 0.5]]], ["BURNING FOES TAKE +25% DAMAGE", [["add", "vs_burn", 0.25]]]],
	"frost": [["+10% CHILL CHANCE", [["add", "chill", 0.1]]], ["CHILLED FOES TAKE +15% DAMAGE", [["add", "vs_chill", 0.15]]], ["KILLS CHILL NEARBY FOES", [["set", "chill_spread", true]]]],
	"venom": [["+1 POISON ON HIT", [["add", "poison", 1]]], ["POISON TICKS TWICE AS FAST", [["set", "poison_fast", true]]], ["POISON DAMAGE +60%", [["add", "poison_dmg", 0.6]]]],
	"storm": [["+10% CHAIN CHANCE", [["add", "chain", 0.1]]], ["LIGHTNING DEALS +50% DAMAGE", [["add", "storm_dmg", 0.5]]], ["HITS HAVE 8% CHANCE TO CALL LIGHTNING", [["add", "storm", 0.08]]]],
	"blood": [["+5% CRIT CHANCE", [["add", "crit", 0.05]]], ["CRITS DEAL +0.5X MORE", [["add", "crit_mult", 0.5]]], ["CRITS PIERCE THROUGH FOES", [["set", "crit_pierce", true]]]],
	"bulwark": [["+10 THORN DAMAGE", [["add", "thorns", 10]]], ["+1 ARMOR AFTER EACH ROOM", [["add", "armor_regen", 1]]], ["20% CHANCE TO IGNORE A HIT", [["add", "evade", 0.2]]]],
	"shadow": [["ROLL RECHARGES 15% FASTER", [["mul", "dodge_cd", 0.85]]], ["ROLLING THROUGH FOES DAMAGES THEM", [["set", "shadowstep", true]]], ["+50% DAMAGE FOR 1S AFTER A ROLL", [["set", "post_roll", true]]]],
	"arcane": [["+1 ORBITING MOON", [["add", "orbitals", 1]]], ["SHOTS HOME IN", [["add", "homing", 2.0]]], ["+1 PROJECTILE", [["add", "count", 1]]]],
	"fortune": [["+10% GOLD", [["mul", "gold_mult", 1.1]]], ["BETTER RELIC RARITY", [["add", "luck", 1]]], ["+25% DAMAGE", [["mul", "dmg", 1.25]]]],
	"demolition": [["BOMBS +25% DAMAGE", [["mul", "bomb_mult", 1.25]]], ["10% OF SHOTS EXPLODE", [["add", "shrapnel", 0.1]]], ["EXPLOSIONS DEAL DOUBLE TO ELITES", [["set", "boom_elite", true]]]],
	"swarm": [["+1 WISP", [["add", "familiars", 1]]], ["WISPS DEAL +50% DAMAGE", [["add", "fam_dmg", 0.5]]], ["WISPS FIRE TWO SHOTS", [["set", "fam_multi", 2]]]],
	"edge": [["+8% CRIT CHANCE", [["add", "crit", 0.08]]],
		["CRITS DEAL +0.5X MORE", [["add", "crit_mult", 0.5]]],
		["CRIT CHANCE PAST 100% CAN CRIT AGAIN", [["add", "overcrit", 0.5]]]],
	"fury": [["+15% DAMAGE BELOW HALF HEALTH", [{ "on": "while_low_hp", "do": [["buff", "dmg", 0.15, 0]] }]],
		["KILLS GIVE +30% FIRE RATE FOR 1.5S", [{ "on": "on_kill", "do": [["buff", "rate", 0.3, 1.5]] }]],
		["TAKING DAMAGE: +40% DAMAGE FOR 4S", [{ "on": "on_damage_taken", "do": [["buff", "dmg", 0.4, 4.0]] }]]],
	"malice": [["20% OF HITS CURSE FOES", [{ "on": "on_hit", "chance": 0.2, "do": [["status", "curse", 1]] }]],
		["HITS ON CURSED FOES MAKE THEM VULNERABLE", [{ "on": "on_hit", "if": "cursed", "do": [["status", "vulnerable", 1]] }]],
		["KILLING A CURSED FOE MAY HEAL", [{ "on": "on_kill", "if": "cursed", "chance": 0.1, "do": [["heal", 1]] }]]],
}

## Trait rarities (design spec section 4). The original traits have no rarity
## column: they show as COMMON, and their capstones as LEGENDARY. Their offer
## weights keep the original formula (G.trait_weight).
const RARITY := {
	"common": { "name": "COMMON", "col": "grey", "hex": "#8b8f9c", "w": 4 },
	"uncommon": { "name": "UNCOMMON", "col": "green", "hex": "#63b84f", "w": 3 },
	"rare": { "name": "RARE", "col": "cyan", "hex": "#4d9be6", "w": 2 },
	"legend": { "name": "LEGENDARY", "col": "gold", "hex": "#f2c94c", "w": 1 },
	"cursed": { "name": "CURSED", "col": "purple", "hex": "#a35bd6", "w": 1 },
}

const ORIGINAL_COUNT := 72
const ROWS := [
	["vitality", "core", 3, "VITALITY", "+1 MAX HEART, HEAL 1 HEART", false, [["add", "max_hp", 2], ["add_cap", "hp", 2, "max_hp"]]],
	["might", "core", 5, "MIGHT", "+12% DAMAGE", false, [["mul", "dmg", 1.12]]],
	["haste", "core", 5, "HASTE", "+10% FIRE RATE", false, [["mul", "rate", 1.1]]],
	["swiftness", "core", 3, "SWIFTNESS", "+8% MOVE SPEED", false, [["mul", "speed", 1.08]]],
	["reach", "core", 3, "REACH", "+15% RANGE AND SHOT SPEED", false, [["mul", "life", 1.15], ["mul", "shot_speed", 1.15]]],
	["precision", "core", 4, "PRECISION", "+6% CRIT CHANCE", false, [["add", "crit", 0.06]]],
	["kindling", "pyre", 3, "KINDLING", "+15% CHANCE TO BURN", false, [["add", "burn", 0.15]]],
	["searing", "pyre", 3, "SEARING", "BURNS DEAL +40% DAMAGE", false, [["add", "burn_dmg", 0.4]]],
	["wildfire", "pyre", 2, "WILDFIRE", "BURNS LAST LONGER AND LEAP TO NEARBY FOES", false, [["add", "burn_time", 1.0], ["add", "burn_leap", 0.2]]],
	["smoulder", "pyre", 3, "SMOULDER", "+10% DAMAGE TO BURNING FOES", false, [["add", "vs_burn", 0.1]]],
	["flametrail", "pyre", 2, "FLAME TRAIL", "ROLLING LEAVES A TRAIL OF FIRE", false, [["add", "fire_trail", 1]]],
	["inferno", "pyre", 1, "INFERNO", "BURNING FOES EXPLODE ON DEATH AND SET OTHERS ABLAZE", true, [["set", "inferno", true]]],
	["chillbite", "frost", 3, "CHILLBITE", "+15% CHANCE TO CHILL", false, [["add", "chill", 0.15]]],
	["deepcold", "frost", 2, "DEEP COLD", "CHILL LASTS LONGER AND SLOWS MORE", false, [["add", "chill_time", 1.0], ["add_floor", "chill_slow", -0.12, 0.2]]],
	["frostbite", "frost", 3, "FROSTBITE", "+12% DAMAGE TO CHILLED FOES", false, [["add", "vs_chill", 0.12]]],
	["icearmor", "frost", 1, "ICE ARMOR", "TAKING A HIT CHILLS EVERY FOE NEARBY", false, [["set", "ice_armor", true]]],
	["glacial", "frost", 2, "GLACIAL LANCE", "EVERY 5TH SHOT IS A PIERCING ICE LANCE", false, [["nth", "lance_n", 5, -1, 3]]],
	["shatter", "frost", 1, "SHATTER", "CHILLED FOES BELOW 30% HEALTH SHATTER INTO ICE", true, [["set", "shatter", true]]],
	["toxin", "venom", 3, "TOXIN", "HITS ADD +1 POISON", false, [["add", "poison", 1]]],
	["virulence", "venom", 3, "VIRULENCE", "POISON DEALS +35% DAMAGE", false, [["add", "poison_dmg", 0.35]]],
	["corrode", "venom", 2, "CORRODE", "POISONED FOES TAKE +3% DAMAGE PER STACK", false, [["add", "corrode", 0.03]]],
	["toxiccloud", "venom", 2, "NOXIOUS CLOUD", "KILLS LEAVE A POISON CLOUD", false, [["add", "cloud", 1]]],
	["barbs", "venom", 2, "BARBS", "20% CHANCE TO FIRE AN EXTRA POISON DART", false, [["add", "barbs", 0.2]]],
	["plague", "venom", 1, "PLAGUE", "POISON SPREADS WITH ALL ITS STACKS WHEN A FOE DIES", true, [["set", "plague", true]]],
	["static", "storm", 3, "STATIC", "+12% CHANCE FOR HITS TO ARC", false, [["add", "chain", 0.12]]],
	["conductor", "storm", 2, "CONDUCTOR", "ARCS JUMP TO 1 MORE FOE", false, [["add", "chain_jumps", 1]]],
	["overload", "storm", 3, "OVERLOAD", "ARCS AND LIGHTNING DEAL +40% DAMAGE", false, [["add", "storm_dmg", 0.4]]],
	["thunderclap", "storm", 2, "THUNDERCLAP", "EVERY 8TH SHOT CALLS LIGHTNING", false, [["nth", "thunder_n", 8, -3, 5]]],
	["livewire", "storm", 2, "LIVE WIRE", "+10% FIRE RATE, +5% MOVE SPEED", false, [["mul", "rate", 1.1], ["mul", "speed", 1.05]]],
	["tempest", "storm", 1, "TEMPEST", "EVERY 3 SECONDS, LIGHTNING STRIKES 3 FOES", true, [["set", "tempest", true]]],
	["keenedge", "blood", 3, "KEEN EDGE", "+7% CRIT CHANCE", false, [["add", "crit", 0.07]]],
	["carnage", "blood", 3, "CARNAGE", "CRITS DEAL +0.35X MORE", false, [["add", "crit_mult", 0.35]]],
	["vampiric", "blood", 2, "VAMPIRIC", "CRITS HAVE 4% CHANCE TO HEAL", false, [["add", "crit_heal", 0.04]]],
	["desperation", "blood", 2, "DESPERATION", "+10% DAMAGE FOR EACH MISSING HEART", false, [["add", "desperate", 0.1]]],
	["lacerate", "blood", 2, "LACERATE", "CRITS MAKE FOES BLEED", false, [["add", "bleed", 1]]],
	["sanguine", "blood", 1, "SANGUINE FRENZY", "EACH KILL GIVES +4% DAMAGE UNTIL THE ROOM ENDS", true, [["set", "sanguine", true]]],
	["plating", "bulwark", 3, "PLATING", "+1 ARMOR", false, [["add", "armor", 1]]],
	["spikes", "bulwark", 3, "SPIKED HIDE", "+10 THORN DAMAGE", false, [["add", "thorns", 10]]],
	["ironskin", "bulwark", 1, "IRON SKIN", "START EACH ROOM WITH AT LEAST 1 ARMOR", false, [["set", "ironskin", true]]],
	["shieldbash", "bulwark", 2, "SHIELD BASH", "ROLLING INTO FOES HITS HARDER WITH MORE ARMOR", false, [["add", "bash", 1], ["set", "shadowstep", true]]],
	["fortress", "bulwark", 2, "FORTRESS", "+8% DAMAGE PER ARMOR (UP TO 5)", false, [["add", "fortress", 0.08]]],
	["unbreakable", "bulwark", 1, "UNBREAKABLE", "WHEN ARMOR BREAKS, RELEASE A NOVA AND ERASE NEARBY SHOTS", true, [["set", "unbreakable", true]]],
	["fleet", "shadow", 2, "FLEET", "+1 ROLL CHARGE", false, [["add", "dodge_charges", 1], ["add", "charges", 1]]],
	["ambush", "shadow", 3, "AMBUSH", "AFTER A ROLL, YOUR NEXT SHOTS CRIT", false, [["add", "ambush", 2]]],
	["phantom", "shadow", 2, "PHANTOM", "ROLLS GO FURTHER AND KEEP YOU SAFE LONGER", false, [["mul", "roll_speed", 1.15], ["add", "roll_time", 0.06]]],
	["evasion", "shadow", 3, "EVASION", "8% CHANCE TO DODGE A HIT", false, [["add", "evade", 0.08]]],
	["smoke", "shadow", 1, "SMOKE BOMB", "ROLLING LEAVES SMOKE THAT ERASES SHOTS", false, [["set", "smoke", true]]],
	["nightfall", "shadow", 1, "NIGHTFALL", "ROLL STRIKES DEAL HEAVY DAMAGE AND KILLS REFUND THE ROLL", true, [["set", "nightfall", true], ["set", "shadowstep", true]]],
	["multicast", "arcane", 2, "MULTICAST", "+1 PROJECTILE, -10% DAMAGE", false, [["add", "count", 1], ["mul", "dmg", 0.9]]],
	["seeking", "arcane", 2, "SEEKING", "SHOTS HOME IN", false, [["add", "homing", 2.0]]],
	["orbit", "arcane", 2, "ORBIT", "+1 ORBITING MOON", false, [["add", "orbitals", 1]]],
	["spellweave", "arcane", 3, "SPELLWEAVE", "+15% SHOT SIZE AND DAMAGE", false, [["mul", "size", 1.15], ["mul", "dmg", 1.15]]],
	["rebound", "arcane", 2, "REBOUND", "SHOTS BOUNCE OFF WALLS", false, [["add", "bounce", 1]]],
	["echo", "arcane", 1, "ARCANE ECHO", "30% CHANCE FOR EVERY SHOT TO CAST AGAIN", true, [["add", "echo", 0.3]]],
	["prospector", "fortune", 3, "PROSPECTOR", "+20% GOLD", false, [["mul", "gold_mult", 1.2]]],
	["haggler", "fortune", 3, "HAGGLER", "SHOPS 10% CHEAPER", false, [["add_cap", "shop_disc", 0.1, 0.6]]],
	["luckyfind", "fortune", 3, "LUCKY FIND", "BETTER RELIC RARITY", false, [["add", "luck", 1]]],
	["interest", "fortune", 2, "INTEREST", "GAIN 8% OF YOUR GOLD AFTER EACH ROOM", false, [["add", "interest", 0.08]]],
	["jackpot", "fortune", 1, "JACKPOT", "ELITES AND GUARDIANS SHOWER GEMS", false, [["set", "jackpot", true]]],
	["midas", "fortune", 1, "MIDAS TOUCH", "+1% DAMAGE FOR EVERY 5 GOLD HELD", true, [["set", "midas", true]]],
	["satchel", "demolition", 3, "SATCHEL", "+2 BOMBS", false, [["add", "bombs", 2]]],
	["blastradius", "demolition", 3, "BLAST RADIUS", "BOMBS +30% RADIUS AND DAMAGE", false, [["mul", "bomb_mult", 1.3], ["mul", "bomb_r", 1.15]]],
	["shrapnel", "demolition", 3, "SHRAPNEL", "12% OF SHOTS EXPLODE ON HIT", false, [["add", "shrapnel", 0.12]]],
	["sapper", "demolition", 1, "SAPPER", "GAIN 1 BOMB AFTER EACH ROOM", false, [["add", "sapper", 1]]],
	["fusemaster", "demolition", 1, "FUSE MASTER", "YOUR BOMBS NO LONGER HURT YOU AND BLOW FASTER", false, [["set", "fuse", true]]],
	["cluster", "demolition", 1, "CLUSTER CHARGE", "BOMBS BURST INTO 4 MORE BOMBS", true, [["set", "cluster", true]]],
	["wispcall", "swarm", 3, "WISP CALL", "+1 WISP FOLLOWS YOU", false, [["add", "familiars", 1]]],
	["packtactics", "swarm", 3, "PACK TACTICS", "WISPS DEAL +40% DAMAGE", false, [["add", "fam_dmg", 0.4]]],
	["feral", "swarm", 2, "FERAL", "WISPS SHOOT 25% FASTER", false, [["mul", "fam_rate", 1.25]]],
	["carrion", "swarm", 2, "CARRION", "KILLS HAVE 10% CHANCE TO RAISE A SPIRIT", false, [["add", "carrion", 0.1]]],
	["hive", "swarm", 1, "HIVE", "+1 ORBITING MOON AND +1 WISP", false, [["add", "orbitals", 1], ["add", "familiars", 1]]],
	["legion", "swarm", 1, "LEGION", "EVERY 5 KILLS SUMMON A TEMPORARY WISP", true, [["set", "legion", true]]],
]

const TREE_COSTS := [10, 20, 35, 60]
## [name, desc] per node; effects in NODE_EFFECTS.
const SKILL_BRANCHES := [
	{ "name": "MIGHT", "nodes": [["SHARPENED", "+10% DAMAGE"], ["QUICK HANDS", "+10% FIRE RATE"], ["TRAINED EYE", "+8% CRIT CHANCE"], ["HEIRLOOM", "START WITH A RANDOM RARE RELIC"]] },
	{ "name": "SURVIVAL", "nodes": [["HARDY", "+1 MAX HEART"], ["PADDED", "START WITH 1 ARMOR"], ["NIMBLE", "+1 ROLL CHARGE"], ["SECOND WIND", "ONCE PER RUN, SURVIVE A KILLING BLOW"]] },
]
const HERO_BRANCH := {
	"hexer": { "name": "HEXCRAFT", "nodes": [["CURVING HEX", "HEX BOLTS TURN HARDER"], ["MALEDICT", "20% CHANCE TO CURSE: CURSED FOES TAKE +25%"], ["PIERCING HEX", "+1 PIERCE"], ["HEX BLOOM", "BOLTS SPLIT IN TWO ON THEIR FIRST HIT"]] },
	"poacher": { "name": "MARKSMAN", "nodes": [["LONG SHOT", "+10% SHOT SPEED AND RANGE"], ["HEAVY BOLT", "EVERY 6TH BOLT DEALS TRIPLE DAMAGE"], ["SLICK RELOAD", "ROLLING RELOADS INSTANTLY"], ["VOLLEY", "+2 BOLTS IN A TIGHT SPREAD"]] },
	"brute": { "name": "BERSERKER", "nodes": [["THICK HIDE", "+2 MAX HEARTS"], ["CONCUSS", "HATCHETS HAVE 20% CHANCE TO STUN"], ["FRESH BLOOD", "+25% DAMAGE AT FULL HEALTH"], ["BLOOD RAGE", "BELOW HALF HEALTH: +40% RATE, +20% SPEED"]] },
	"gravedigger": { "name": "UNDERTAKER", "nodes": [["FISTFUL", "+1 CLOD PER THROW"], ["SPARE POWDER", "GAIN 1 BOMB AFTER EACH ROOM"], ["BURY", "CLODS HAVE 15% CHANCE TO STUN"], ["GRAVE HARVEST", "BOMB KILLS DROP BOMBS AND HEARTS"]] },
	"alchemist": { "name": "TRANSMUTER", "nodes": [["POTENT BREW", "+1 POISON ON HIT"], ["WIDE SPLASH", "FLASK BURSTS 40% BIGGER"], ["ELIXIR", "POTIONS HEAL MORE AND MAKE YOU SAFE FOR 3S"], ["VOLATILE MIX", "POISONED FOES EXPLODE ON DEATH"]] },
	"warden": { "name": "LAMPLIGHTER", "nodes": [["BRIGHT FLAME", "+20% LANTERN SIZE"], ["KINDLED", "LANTERN HITS OFTEN BURN"], ["HOMEWARD", "THE LANTERN HITS TWICE AS HARD ON ITS WAY BACK"], ["TWIN FLAME", "THROW TWO LANTERNS AT ONCE"]] },
}

const NODE_EFFECTS := {
	"SHARPENED": [["mul", "dmg", 1.1]],
	"QUICK HANDS": [["mul", "rate", 1.1]],
	"TRAINED EYE": [["add", "crit", 0.08]],
	"HEIRLOOM": [["set", "start_rare", true]],
	"HARDY": [["add", "max_hp", 2], ["add", "hp", 2]],
	"PADDED": [["add", "armor", 1]],
	"NIMBLE": [["add", "dodge_charges", 1], ["add", "charges", 1]],
	"SECOND WIND": [["add", "revive", 1]],
	"CURVING HEX": [["add", "homing", 0.8]],
	"MALEDICT": [["add", "curse", 0.2]],
	"PIERCING HEX": [["add", "pierce", 1]],
	"HEX BLOOM": [["set", "bloom", true]],
	"LONG SHOT": [["mul", "shot_speed", 1.1], ["mul", "life", 1.1]],
	"HEAVY BOLT": [["set", "heavy_n", 6]],
	"SLICK RELOAD": [["set", "roll_reload", true]],
	"VOLLEY": [["add", "count", 2]],
	"THICK HIDE": [["add", "max_hp", 4], ["add", "hp", 4]],
	"CONCUSS": [["add", "stun", 0.2]],
	"FRESH BLOOD": [["add", "full_hp_dmg", 0.25]],
	"BLOOD RAGE": [["set", "blood_rage", true]],
	"FISTFUL": [["add", "count", 1]],
	"SPARE POWDER": [["add", "sapper", 1]],
	"BURY": [["add", "stun", 0.15]],
	"GRAVE HARVEST": [["set", "harvest", true]],
	"POTENT BREW": [["add", "poison", 1]],
	"WIDE SPLASH": [["add", "splash", 0.4]],
	"ELIXIR": [["add", "potion_heal", 2], ["set", "elixir", true]],
	"VOLATILE MIX": [["set", "volatile", true]],
	"BRIGHT FLAME": [["mul", "size", 1.2]],
	"KINDLED": [["add", "burn", 0.35]],
	"HOMEWARD": [["set", "back_dmg", true]],
	"TWIN FLAME": [["add", "count", 1], ["set", "spread", 0.35]],
}

static var _list: Array = []
static var _by_id := {}

static func all() -> Array:
	if _list.is_empty():
		for i in ROWS.size():
			var row: Array = ROWS[i]
			var t := { "id": row[0], "fam": row[1], "max": row[2], "name": row[3], "desc": row[4], "cap": row[5],
				"effects": row[6], "new": i >= ORIGINAL_COUNT,
				"rarity": row[7] if row.size() > 7 else ("legend" if row[5] else "common"),
				"tags": row[8] if row.size() > 8 else [row[1]],
				"tiers": row[9] if row.size() > 9 else {} }
			_list.append(t)
			_by_id[t["id"]] = t
	return _list

static func by_id(id: String) -> Dictionary:
	all()
	return _by_id[id]

static func tree_for(hero_id: String) -> Array:
	return SKILL_BRANCHES + [HERO_BRANCH[hero_id]]

## One rank of a trait. tier_effects (new traits) add extra effects when a
## given rank is reached, e.g. { 3: [...] }.
static func apply(id: String, p: Player) -> void:
	var t := by_id(id)
	Effects.apply(p, t["effects"], 1, "trait:" + id)
	var rank: int = p.traits.get(id, 0)
	if t["tiers"].has(rank):
		Effects.apply(p, t["tiers"][rank], 1, "trait:%s:%d" % [id, rank])

## Family bonus tier i (0..2).
static func apply_bonus(fam: String, i: int, p: Player) -> void:
	Effects.apply(p, FAMILY_BONUS[fam][i][1], 1, "bonus:%s:%d" % [fam, i])

static func bonus_name(fam: String, i: int) -> String:
	return FAMILY_BONUS[fam][i][0]

static func apply_node(name: String, p: Player) -> void:
	Effects.apply(p, NODE_EFFECTS[name], 1, "node:" + name)
