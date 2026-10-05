class_name GameData
extends RefCounted
## Game data: heroes, enemies, bosses, floors, room kinds (port of Data.rb and
## the room/xp tables from 01b_traits.rb). Relics, traits, weapons and gear
## live in their own data scripts.

const HEROES := [
	{ "id": "hexer", "name": "THE HEXER", "sprite": "hexer", "blurb": "A crypt witch. Slow hex bolts that curve toward foes.",
	  "weapon": "HEX BOLTS", "hp": 6, "speed": 86, "shot": "hex", "sound": "shoot", "cost": 0,
	  "stats": { "dmg": 4.0, "rate": 3.2, "shot_speed": 150.0, "life": 1.0, "homing": 2.2, "size": 1.0, "pierce": 0 } },
	{ "id": "poacher", "name": "THE POACHER", "sprite": "poacher", "blurb": "A grave robber with a repeating crossbow. Fast and fragile.",
	  "weapon": "REPEATER", "hp": 6, "speed": 96, "shot": "bolt", "sound": "bolt", "cost": 0,
	  "stats": { "dmg": 2.0, "rate": 6.5, "shot_speed": 270.0, "life": 0.75, "homing": 0.0, "size": 1.0, "pierce": 1 } },
	{ "id": "brute", "name": "THE BRUTE", "sprite": "brute", "blurb": "A pit fighter. Hurls heavy hatchets at close range. Tough.",
	  "weapon": "HATCHETS", "hp": 10, "speed": 80, "shot": "hatchet", "sound": "hatchet", "cost": 0,
	  "stats": { "dmg": 8.0, "rate": 1.8, "shot_speed": 180.0, "life": 0.72, "homing": 0.0, "size": 1.6, "pierce": 2 } },
	{ "id": "gravedigger", "name": "THE GRAVEDIGGER", "sprite": "gravedigger", "blurb": "Flings a spray of grave dirt. Starts with extra bombs.",
	  "weapon": "DIRT SPRAY", "hp": 8, "speed": 84, "shot": "clod", "sound": "hatchet", "cost": 40,
	  "stats": { "dmg": 2.4, "rate": 2.4, "shot_speed": 220.0, "life": 0.55, "homing": 0.0, "size": 1.0, "pierce": 0, "count": 4, "spread": 0.16 },
	  "start": { "bombs": 3 } },
	{ "id": "alchemist", "name": "THE ALCHEMIST", "sprite": "alchemist", "blurb": "Throws flasks that burst and poison everything nearby.",
	  "weapon": "FLASKS", "hp": 6, "speed": 88, "shot": "flask", "sound": "shoot", "cost": 80,
	  "stats": { "dmg": 5.0, "rate": 2.0, "shot_speed": 160.0, "life": 0.85, "homing": 0.0, "size": 1.0, "pierce": 0 } },
	{ "id": "warden", "name": "THE WARDEN", "sprite": "warden", "blurb": "A lantern keeper. Hurls a blazing lantern that flies back.",
	  "weapon": "LANTERN", "hp": 8, "speed": 84, "shot": "boomer", "sound": "hatchet", "cost": 140,
	  "stats": { "dmg": 4.5, "rate": 2.0, "shot_speed": 210.0, "life": 0.9, "homing": 0.0, "size": 1.2, "pierce": 99 } },
]

## Design spec step 6: new heroes, added after the six originals (which stay
## exactly as they are). Extra fields: "passive" (shown on the hero screen),
## "effects" (applied at the start of every run, effect-system data), "trait"
## (a starting trait at rank 1), "special" (active ability, scripts/combat/abilities.gd)
## and "new". Sprites are recoloured copies of
## original heroes: placeholders until real art exists.
const NEW_HEROES := [
	# A starter (cost 0: free from the first run). An escapee who lives on momentum:
	# tempo and rally are in scripts/combat/tempo.gd and rally.gd, the leap in abilities.gd.
	{ "id": "gaolbird", "name": "THE GAOLBIRD", "sprite": "gaolbird", "new": true,
	  "blurb": "Flew the coop at Blackrock Gaol in a crow mask and has not stood still since.",
	  "passive": "TEMPO: BLOWS AND KILLS BUILD UP TO 10 TEMPO, +2.5% SPEED AND +4% FIRE RATE EACH. AT 10: +20% CRIT, ROLLS CUT FOES. IT FADES IF YOU STOP HITTING, A HIT HALVES IT. RALLY: AFTER A HIT, LAND 6 BLOWS IN 3S TO WIN THE HEART BACK. ROLL THROUGH A FOE TO EXPOSE IT.",
	  "weapon": "IRON TALONS", "hp": 6, "speed": 94, "shot": "slash", "sound": "hatchet", "cost": 0, "trait": "sh_blur", "hud": "tempo",
	  "stats": { "dmg": 3.6, "rate": 3.6, "shot_speed": 0.0, "life": 0.0, "homing": 0.0, "size": 1.0, "pierce": 99 },
	  "effects": [["set", "tempo_max", 10], ["set", "rally_n", 6], ["hook", "roll_expose", 1]],
	  "special": { "name": "TALON DIVE", "cd": 7, "col": "#e86fb4",
		"desc": "LEAP UP AND CRASH DOWN ON THE FOE YOU AIM AT: 300% TO ALL NEARBY, STUN, EXPOSE, ERASE SHOTS, +2 TEMPO. UNTOUCHABLE IN THE AIR.",
		"do": [["leap", 460, 150, [["explode", 46, 3.0], ["status_area", "stun", 1, 52], ["status_area", "vulnerable", 1, 52],
			["clear_shots", 52], ["tempo", 2], ["vfx", "slam", "#e86fb4", 50]]]] } },
	{ "id": "banehunter", "name": "THE BANE HUNTER", "sprite": "banehunter", "new": true,
	  "blurb": "A scarred hunter of monsters. Lives off bounties and bitter oils.",
	  "passive": "+25% DAMAGE TO ELITES. A POTION ALSO OILS YOUR BLADE: +40% DAMAGE FOR 10S. EVERY 6S A ROLL CASTS A SIGN: A RING OF SPARKS THAT STUNS THE NEAREST FOE.",
	  "weapon": "BANE SABRE", "hp": 8, "speed": 88, "shot": "slash", "sound": "hatchet", "cost": 160, "trait": "g_bounty",
	  "stats": { "dmg": 8.0, "rate": 2.6, "shot_speed": 0.0, "life": 0.0, "homing": 0.0, "size": 1.0, "pierce": 99 },
	  "effects": [["add", "elite_mult", 0.25],
		{ "on": "on_potion", "do": [["buff", "dmg", 0.4, 10.0], ["vfx", "label", "BLADE OILED", "#f2c94c"], ["vfx", "ring", "#f2c94c", 30]] },
		{ "on": "on_roll", "cd": 6.0, "do": [["nova", 8, 0.5, "spark"], ["status", "stun", 1], ["vfx", "sigil", "#f2c94c", 30]] }],
	  "special": { "name": "BURNING SIGIL", "cd": 12, "col": "#f2c94c",
		"desc": "A HUGE SIGIL BLASTS EVERY FOE NEAR YOU FOR 250%, STUNS THEM, SETS THEM ABLAZE AND ERASES SHOTS.",
		"do": [["vfx", "sigil", "#f2c94c", 72], ["explode", 72, 2.5], ["status_area", "stun", 1, 80],
			["status_area", "burn", 2, 80], ["clear_shots", 72]] } },
	{ "id": "oathbreaker", "name": "THE OATHBREAKER", "sprite": "oathbreaker", "new": true,
	  "blurb": "A disgraced knight with a slab of iron far too big to be a sword.",
	  "passive": "RAGE: EVERY KILL GIVES +6% DAMAGE FOR 5S, AND IT STACKS. BELOW HALF HEALTH: +30% DAMAGE AND +20% FIRE RATE.",
	  "weapon": "IRON SLAB", "hp": 10, "speed": 80, "shot": "slash", "sound": "hatchet", "cost": 200, "trait": "f_anger",
	  "stats": { "dmg": 16.0, "rate": 0.9, "shot_speed": 0.0, "life": 0.0, "homing": 0.0, "size": 1.0, "pierce": 99 },
	  "effects": [{ "on": "on_kill", "do": [["buff", "dmg", 0.06, 5.0]] },
		{ "on": "while_low_hp", "do": [["buff", "dmg", 0.3, 0], ["buff", "rate", 0.2, 0]] }],
	  "special": { "name": "IRON CYCLONE", "cd": 11, "col": "#d8443c",
		"desc": "SPIN THE SLAB FOR 2S: A WHIRLWIND THAT HITS EVERYTHING AROUND YOU FOR 90% FIVE TIMES A SECOND. UNTOUCHABLE WHILE SPINNING.",
		"do": [["vfx", "spin", "#d9d0b4", 2.0], ["invuln", 2.0], ["channel", 2.0, 0.2, [["area", 40, 0.9], ["clear_shots", 34]]]] } },
	{ "id": "wayfarer", "name": "THE WAYFARER", "sprite": "wayfarer", "new": true,
	  "blurb": "A wandering swordsman who answers every blow with a cleaner one.",
	  "passive": "+10% CRIT. PERFECT DODGE: ROLLING WHILE A SHOT IS CLOSE REFUNDS THE ROLL AND GIVES +60% DAMAGE FOR 1.5S.",
	  "weapon": "WAYFARER'S EDGE", "hp": 6, "speed": 94, "shot": "slash", "sound": "hatchet", "cost": 180, "trait": "e_precise",
	  "stats": { "dmg": 6.0, "rate": 3.0, "shot_speed": 0.0, "life": 0.0, "homing": 0.0, "size": 1.0, "pierce": 99 },
	  "effects": [["add", "crit", 0.1], { "on": "on_roll", "if": "danger", "do": [["refund_roll"], ["buff", "dmg", 0.6, 1.5],
		["vfx", "label", "PERFECT!", "#6fd3e0"], ["vfx", "ring", "#6fd3e0", 36]] }],
	  "special": { "name": "FLASH STEP", "cd": 7, "col": "#6fd3e0",
		"desc": "BLINK FORWARD IN A FLASH, CUTTING EVERY FOE IN THE PATH FOR 400%. UNTOUCHABLE WHILE MOVING.",
		"do": [["vfx", "flash", "#ffffff", 0.08], ["dash", 900, 0.13, 4.0, [["vfx", "ring", "#6fd3e0", 30], ["vfx", "burst", "#6fd3e0", 14]]]] } },
	{ "id": "racketeer", "name": "THE RACKETEER", "sprite": "racketeer", "new": true,
	  "blurb": "A gutter boss with two snub guns. The more trouble, the more pay.",
	  "passive": "+10% GOLD. HEAT: CLEARING A ROOM RAISES HEAT (MAX 5). EACH LEVEL GIVES +8% DAMAGE AND +10% GOLD. GETTING HIT LOSES 2 HEAT.",
	  "weapon": "SNUB GUNS", "hp": 6, "speed": 92, "shot": "bolt", "sound": "bolt", "cost": 220, "trait": "g_skim", "hud": "heat",
	  "stats": { "dmg": 2.4, "rate": 2.0, "shot_speed": 260.0, "life": 0.75, "homing": 0.0, "size": 1.0, "pierce": 0 },
	  "effects": [["mul", "gold_mult", 1.1], { "on": "on_room_clear", "do": [["heat", 1]] }, { "on": "on_damage_taken", "do": [["heat", -2]] }],
	  "special": { "name": "LEAD RAIN", "cd": 12, "col": "#f2c94c",
		"desc": "EMPTY EVERY GUN FOR 2S: A SPIRAL OF 8 SHOTS EVERY 0.15S. +1 HEAT.",
		"do": [["heat", 1], ["channel", 2.0, 0.15, [["nova", 8, 0.55, "bolt", 2.5]]]] } },
	{ "id": "condemned", "name": "THE CONDEMNED", "sprite": "condemned", "new": true,
	  "blurb": "A prisoner the crypt refuses to keep dead. Grabs whatever weapon is near.",
	  "passive": "UNDYING: RISES ONCE PER RUN. EVERY FLOOR, READS A RANDOM SCROLL (DAMAGE, RATE, HEART OR CRIT). SWAPPING WEAPONS GIVES +50% DAMAGE FOR 8S.",
	  "weapon": "SHACKLE FLAIL", "hp": 6, "speed": 88, "shot": "whip", "sound": "hatchet", "cost": 240, "trait": "f_thickskull",
	  "stats": { "dmg": 5.5, "rate": 2.0, "shot_speed": 0.0, "life": 0.0, "homing": 0.0, "size": 1.0, "pierce": 99 },
	  "effects": [["add", "revive", 1], { "on": "on_floor_start", "do": [["scroll"]] },
		{ "on": "on_weapon_swap", "do": [["buff", "dmg", 0.5, 8.0], ["vfx", "label", "FRESH STEEL", "#d8443c"]] }],
	  "special": { "name": "BREAK THE CHAINS", "cd": 14, "col": "#8b8f9c",
		"desc": "SHATTER YOUR SHACKLES: 2S UNTOUCHABLE, ERASE NEARBY SHOTS, FLING 16 CHAIN LINKS AND GAIN +50% DAMAGE FOR 6S.",
		"do": [["vfx", "flash", "#ffffff", 0.2], ["vfx", "ring", "#8b8f9c", 90], ["invuln", 2.0], ["clear_shots", 120],
			["nova", 16, 1.0, "spark"], ["buff", "dmg", 0.5, 6.0]] } },
	{ "id": "cartomancer", "name": "THE CARTOMANCER", "sprite": "cartomancer", "new": true,
	  "blurb": "A card reader who deals fate in sharpened gilt.",
	  "passive": "IN A FIGHT, DRAWS A CARD EVERY 4S AND PLAYS IT: BLADES, STORM, SHIELD, MEND, STAR, WHEEL OR COIN.",
	  "weapon": "GILT DECK", "hp": 6, "speed": 90, "shot": "disc", "sound": "shoot", "cost": 260, "trait": "a_salvo",
	  "stats": { "dmg": 3.0, "rate": 2.6, "shot_speed": 200.0, "life": 1.6, "homing": 0.0, "size": 1.0, "pierce": 1 },
	  "effects": [{ "on": "every_n_seconds", "period": 4.0, "if": "fighting", "do": [["card"]] }],
	  "special": { "name": "STACKED DECK", "cd": 10, "col": "#d8443c",
		"desc": "DEAL THREE CARDS AT ONCE AND FAN 12 RAZOR CARDS AROUND YOU.",
		"do": [["card"], ["card"], ["card"], ["nova", 12, 0.8, "disc"]] } },
	{ "id": "sellsword", "name": "THE SELLSWORD", "sprite": "sellsword", "new": true,
	  "blurb": "A mercenary from far plains. Fights as if still on horseback.",
	  "passive": "CHARGE: ROLLS ARE FASTER AND TRAMPLE FOES FOR 250%. +1 ROLL CHARGE. STARTS WITH 1 ARMOR.",
	  "weapon": "WAR LANCE", "hp": 8, "speed": 86, "shot": "thrust", "sound": "hatchet", "cost": 120, "trait": "t_brace",
	  "stats": { "dmg": 7.5, "rate": 2.0, "shot_speed": 0.0, "life": 0.0, "homing": 0.0, "size": 1.0, "pierce": 99 },
	  "effects": [["set", "shadowstep", true], ["mul", "roll_speed", 1.25], ["add", "dodge_charges", 1], ["add", "charges", 1], ["add", "armor", 1]],
	  "special": { "name": "WAR CHARGE", "cd": 8, "col": "#e8873a",
		"desc": "A LONG CHARGE THAT TRAMPLES FOES FOR 300% AND ENDS IN A SHOCKWAVE FOR 200%.",
		"do": [["dash", 520, 0.4, 3.0, [["explode", 48, 2.0], ["vfx", "ring", "#e8873a", 50]]]] } },
]

static var _heroes: Array = []
## Tests that compare with the original Ruby set this to run the original rules.
static var force_classic := false

## The Rogues layer (attributes, upgrades, inventory...) is on unless --classic.
static func rogues() -> bool:
	return not force_classic and not DebugArgs.has("classic")
static var _unlocks: Array = []

## All playable heroes: the originals first (indices 0-5 unchanged), then the
## new ones. --classic leaves the new ones out.
static func heroes() -> Array:
	if _heroes.is_empty():
		_heroes = HEROES.duplicate()
		if not DebugArgs.has("classic"):
			_heroes.append_array(NEW_HEROES)
	return _heroes

## The order heroes are shown in on the hero and skill-tree screens: the free ones
## first, then the rest, each group in list order. Only those screens use it;
## G.hero_index and --hero stay indices into heroes(). (With the six originals
## alone, as in --classic, it is simply 0..5.)
static var _order: Array = []
static func hero_order() -> Array:
	if _order.is_empty():
		var all := heroes()
		for i in all.size():
			if all[i]["cost"] == 0:
				_order.append(i)
		for i in all.size():
			if all[i]["cost"] != 0:
				_order.append(i)
	return _order

static func unlocks() -> Array:
	if _unlocks.is_empty():
		_unlocks = UNLOCKS.duplicate()
		if not DebugArgs.has("classic"):
			for h in NEW_HEROES:
				if h["cost"] > 0:   # a hero that costs nothing is a starter: nothing to buy at the shrine
					_unlocks.append({ "id": "hero_" + h["id"], "name": h["name"], "desc": "A NEW HERO: " + h["weapon"], "cost": h["cost"] })
	return _unlocks

const RARITY_COL := { "common": "grey", "rare": "cyan", "epic": "purple", "legend": "gold" }
const RARITY_HEX := { "common": "#8b8f9c", "rare": "#4d9be6", "epic": "#a35bd6", "legend": "#f2c94c" }
const RARITY_NAME := { "common": "COMMON", "rare": "RARE", "epic": "EPIC", "legend": "LEGENDARY" }

## ai names map to EnemyAI.ai_* functions.
const ENEMIES := {
	"bat": { "sprite": "bat", "hp": 6, "speed": 72, "r": 5, "ai": "bat", "fly": true, "gold": 0.25 },
	"slime": { "sprite": "slime", "hp": 14, "speed": 40, "r": 6, "ai": "slime", "gold": 0.3 },
	"slimelet": { "sprite": "slime", "hp": 5, "speed": 55, "r": 4, "ai": "slime", "gold": 0.1, "scale": 0.7 },
	"skeleton": { "sprite": "skeleton", "hp": 11, "speed": 42, "r": 5, "ai": "archer", "gold": 0.35 },
	"mushroom": { "sprite": "mushroom", "hp": 16, "speed": 18, "r": 6, "ai": "spore", "gold": 0.35 },
	"cultist": { "sprite": "cultist", "hp": 20, "speed": 34, "r": 6, "ai": "cultist", "gold": 0.45 },
	"imp": { "sprite": "imp", "hp": 11, "speed": 60, "r": 5, "ai": "imp", "fly": true, "gold": 0.35 },
	"knight": { "sprite": "knight", "hp": 34, "speed": 36, "r": 6, "ai": "knight", "gold": 0.6 },
	"ghost": { "sprite": "ghost", "hp": 15, "speed": 46, "r": 5, "ai": "ghost", "fly": true, "gold": 0.35 },
	"bookwyrm": { "sprite": "bookwyrm", "hp": 12, "speed": 55, "r": 5, "ai": "book", "fly": true, "gold": 0.35 },
	"drowned": { "sprite": "drowned", "hp": 24, "speed": 30, "r": 6, "ai": "drowned", "gold": 0.45 },
	"wisp": { "sprite": "wisp", "hp": 9, "speed": 80, "r": 5, "ai": "wisp", "fly": true, "gold": 0.3 },
	"golem": { "sprite": "golem", "hp": 46, "speed": 26, "r": 7, "ai": "golem", "gold": 0.7 },
	# Rogues layer: a training dummy in each floor's start room (never dies, shows your DPS).
	"dummy": { "sprite": "dummy", "hp": 1, "speed": 0, "r": 6, "ai": "dummy", "gold": 0.0 },
	# ---------- Stage 7 foes (new biomes). "shot" overrides a behaviour's bullet sprite, "fan" an
	# archer's arrow count; "mini" marks a floor mini-boss (fixed health, own name, extra ring burst).
	# Rainmarsh Hamlet: poison and ambushes.
	"bogling": { "sprite": "bogling", "hp": 16, "speed": 70, "r": 6, "ai": "ambush", "shot": "spore", "gold": 0.4 },
	"gnat": { "sprite": "gnat", "hp": 5, "speed": 84, "r": 4, "ai": "bat", "fly": true, "gold": 0.15 },
	"hexwife": { "sprite": "hexwife", "hp": 20, "speed": 34, "r": 6, "ai": "cultist", "shot": "spore", "gold": 0.45 },
	"mirehulk": { "sprite": "mirehulk", "name": "THE MIRE HULK", "hp": 300, "speed": 24, "r": 10, "ai": "golem", "shot": "spore",
		"scale": 1.8, "mini": true, "gold": 3.0 },
	# Ashen Warfront: archers and cavalry charges.
	"longbowman": { "sprite": "longbowman", "hp": 14, "speed": 40, "r": 5, "ai": "archer", "shot": "bone", "fan": 5, "gold": 0.4 },
	"lancer": { "sprite": "lancer", "hp": 30, "speed": 40, "r": 6, "ai": "knight", "shot": "fire", "gold": 0.55 },
	"warpriest": { "sprite": "warpriest", "hp": 22, "speed": 32, "r": 6, "ai": "cultist", "shot": "fire", "gold": 0.5 },
	"torchimp": { "sprite": "torchimp", "hp": 12, "speed": 62, "r": 5, "ai": "imp", "fly": true, "shot": "fire", "gold": 0.35 },
	"ironcaptain": { "sprite": "ironcaptain", "name": "THE IRON CAPTAIN", "hp": 360, "speed": 40, "r": 10, "ai": "knight", "shot": "fire",
		"scale": 1.8, "mini": true, "gold": 3.0 },
	# Frostpeak Monastery: monks and ice.
	"monk": { "sprite": "monk", "hp": 18, "speed": 72, "r": 5, "ai": "monk", "shot": "ice", "gold": 0.4 },
	"icearcher": { "sprite": "icearcher", "hp": 13, "speed": 42, "r": 5, "ai": "archer", "shot": "ice", "gold": 0.4 },
	"snowlantern": { "sprite": "snowlantern", "hp": 18, "speed": 16, "r": 6, "ai": "spore", "shot": "ice", "gold": 0.35 },
	"stoneabbot": { "sprite": "stoneabbot", "name": "THE STONE ABBOT", "hp": 420, "speed": 26, "r": 10, "ai": "golem", "shot": "ice",
		"scale": 1.8, "mini": true, "gold": 3.0 },
	# Nightspire Rooftops: gunmen.
	"gunman": { "sprite": "gunman", "hp": 16, "speed": 44, "r": 5, "ai": "gunman", "shot": "red", "gold": 0.5 },
	"cutthroat": { "sprite": "cutthroat", "hp": 15, "speed": 58, "r": 5, "ai": "ghost", "fly": true, "shot": "dark", "gold": 0.4 },
	"crow": { "sprite": "crow", "hp": 7, "speed": 88, "r": 4, "ai": "bat", "fly": true, "gold": 0.2 },
	"chimneyimp": { "sprite": "chimneyimp", "hp": 13, "speed": 60, "r": 5, "ai": "imp", "fly": true, "shot": "fire", "gold": 0.35 },
	"enforcer": { "sprite": "enforcer", "name": "THE ENFORCER", "hp": 460, "speed": 30, "r": 10, "ai": "gunman", "shot": "red",
		"burst": 6, "scale": 1.8, "mini": true, "gold": 3.0 },
	# The Eclipse: corrupted everything.
	"voidling": { "sprite": "voidling", "hp": 11, "speed": 86, "r": 5, "ai": "wisp", "fly": true, "shot": "dark", "gold": 0.35 },
	"shadeknight": { "sprite": "shadeknight", "hp": 40, "speed": 42, "r": 6, "ai": "knight", "shot": "dark", "gold": 0.6 },
	"eclipsed": { "sprite": "eclipsed", "hp": 24, "speed": 34, "r": 6, "ai": "cultist", "shot": "dark", "gold": 0.5 },
	"herald": { "sprite": "herald", "name": "THE HERALD OF DUSK", "hp": 520, "speed": 50, "r": 10, "ai": "book", "fly": true, "shot": "dark",
		"scale": 1.8, "mini": true, "gold": 3.0 },
	# ---------- Rift worlds (scripts/data/themes.gd). "label" is how a foe is named when it kills
	# you; "champion" marks a rift's boss (ChampionAI, health grows with the floor).
	# Blackrock Gaol.
	"inmate": { "sprite": "inmate", "hp": 18, "speed": 34, "r": 6, "ai": "drowned", "shot": "bone", "gold": 0.4, "label": "an inmate" },
	"grenadier": { "sprite": "grenadier", "hp": 14, "speed": 38, "r": 5, "ai": "lobber", "shot": "fire", "gold": 0.45, "label": "a grenadier" },
	"jailer": { "sprite": "jailer", "hp": 30, "speed": 38, "r": 6, "ai": "knight", "shot": "bone", "gold": 0.55, "label": "a jailer" },
	"turnkey": { "sprite": "turnkey", "name": "THE TURNKEY", "hp": 170, "speed": 46, "r": 10, "ai": "champion", "shot": "bone",
		"scale": 2.0, "mini": true, "champion": true, "gold": 4.0, "style": "melee",
		"moves": [["charge", 2], ["ring", 14, 62, 2], ["lob", 3], ["summon", "inmate", 2], ["fan", 5, 0.7, 3]] },
	# The Branded Field.
	"graveborn": { "sprite": "graveborn", "hp": 16, "speed": 70, "r": 6, "ai": "ambush", "shot": "dark", "gold": 0.4, "label": "a graveborn" },
	"bandsman": { "sprite": "bandsman", "hp": 14, "speed": 40, "r": 5, "ai": "archer", "shot": "bone", "fan": 3, "gold": 0.4, "label": "a bandsman" },
	"fiendling": { "sprite": "fiendling", "hp": 12, "speed": 62, "r": 5, "ai": "imp", "fly": true, "shot": "dark", "gold": 0.35, "label": "a fiendling" },
	"blackknight": { "sprite": "blackknight", "hp": 36, "speed": 40, "r": 6, "ai": "knight", "shot": "dark", "gold": 0.6, "label": "a black knight" },
	"carrionknight": { "sprite": "carrionknight", "name": "THE CARRION KNIGHT", "hp": 190, "speed": 50, "r": 10, "ai": "champion", "shot": "dark",
		"scale": 2.0, "mini": true, "champion": true, "gold": 4.0, "style": "melee",
		"moves": [["charge", 3], ["fan", 7, 0.9, 2], ["rain", 4], ["ring", 16, 58, 2], ["summon", "fiendling", 2]] },
	# Neon Undercity.
	"drone": { "sprite": "drone", "hp": 10, "speed": 66, "r": 5, "ai": "imp", "fly": true, "shot": "cyan", "gold": 0.35, "label": "a drone" },
	"glitch": { "sprite": "glitch", "hp": 15, "speed": 56, "r": 5, "ai": "ghost", "fly": true, "shot": "cyan", "gold": 0.4, "label": "a glitch" },
	"chrome": { "sprite": "chrome", "hp": 44, "speed": 28, "r": 7, "ai": "golem", "shot": "red", "gold": 0.7, "label": "a chrome bruiser" },
	"turret": { "sprite": "turret", "hp": 20, "speed": 0, "r": 6, "ai": "turret", "shot": "cyan", "gold": 0.4, "label": "a turret" },
	"broker": { "sprite": "broker", "name": "THE BROKER", "hp": 160, "speed": 44, "r": 10, "ai": "champion", "shot": "cyan",
		"scale": 2.0, "mini": true, "champion": true, "gold": 4.0, "style": "ranged",
		"moves": [["blink"], ["spiral", 36], ["burst", 8], ["summon", "drone", 3], ["blink"], ["ring", 18, 66, 3]] },
	# Riot Alley.
	"thug": { "sprite": "thug", "hp": 18, "speed": 70, "r": 5, "ai": "monk", "shot": "red", "gold": 0.4, "label": "a thug" },
	"molotov": { "sprite": "molotov", "hp": 13, "speed": 40, "r": 5, "ai": "lobber", "shot": "fire", "gold": 0.4, "label": "a firebomber" },
	"copper": { "sprite": "copper", "hp": 16, "speed": 44, "r": 5, "ai": "gunman", "shot": "red", "gold": 0.5, "label": "a copper" },
	"bomber": { "sprite": "bomber", "hp": 12, "speed": 78, "r": 6, "ai": "bomber", "shot": "fire", "gold": 0.35, "label": "a mad bomber" },
	"mayor": { "sprite": "mayor", "name": "THE MAYOR", "hp": 165, "speed": 40, "r": 10, "ai": "champion", "shot": "red",
		"scale": 2.0, "mini": true, "champion": true, "gold": 5.0, "style": "ranged",
		"moves": [["summon", "thug", 2], ["burst", 6], ["lob", 4], ["summon", "copper", 2], ["ring", 16, 60, 2], ["summon", "bomber", 2]] },
	# Ashfall Town.
	"orderly": { "sprite": "orderly", "hp": 18, "speed": 60, "r": 5, "ai": "monk", "shot": "dark", "gold": 0.4, "label": "an orderly" },
	"crawler": { "sprite": "crawler", "hp": 8, "speed": 80, "r": 5, "ai": "runner", "gold": 0.2, "label": "a crawler" },
	"static": { "sprite": "static", "hp": 15, "speed": 50, "r": 5, "ai": "ghost", "fly": true, "shot": "dark", "gold": 0.4, "label": "a static shape" },
	"tollkeeper": { "sprite": "tollkeeper", "hp": 22, "speed": 26, "r": 6, "ai": "caller", "summon": "crawler", "shot": "dark", "gold": 0.5, "label": "a tollkeeper" },
	"rustbutcher": { "sprite": "rustbutcher", "name": "THE RUST BUTCHER", "hp": 200, "speed": 42, "r": 10, "ai": "champion", "shot": "darkBig",
		"scale": 2.0, "mini": true, "champion": true, "gold": 4.0, "style": "melee",
		"moves": [["charge", 2], ["ring", 10, 44, 3], ["rain", 5], ["summon", "crawler", 4], ["charge", 3]] },
	# Maple Court.
	"neighbour": { "sprite": "neighbour", "hp": 14, "speed": 46, "r": 5, "ai": "book", "shot": "page", "gold": 0.4, "label": "an angry neighbour" },
	"robovac": { "sprite": "robovac", "hp": 24, "speed": 44, "r": 6, "ai": "knight", "shot": "red", "gold": 0.45, "label": "a robot vacuum" },
	"burglar": { "sprite": "burglar", "hp": 14, "speed": 58, "r": 5, "ai": "ghost", "fly": true, "shot": "dark", "gold": 0.6, "label": "a burglar" },
	"gnome": { "sprite": "gnome", "hp": 16, "speed": 0, "r": 5, "ai": "turret", "shot": "red", "gold": 0.4, "label": "a garden gnome" },
	"landlord": { "sprite": "landlord", "name": "THE LANDLORD", "hp": 160, "speed": 42, "r": 10, "ai": "champion", "shot": "page",
		"scale": 2.0, "mini": true, "champion": true, "gold": 6.0, "style": "ranged",
		"moves": [["fan", 9, 1.2, 3], ["summon", "neighbour", 2], ["lob", 3], ["charge", 1], ["summon", "robovac", 2], ["spiral", 30]] },
	# Heist City.
	"gangster": { "sprite": "gangster", "hp": 16, "speed": 44, "r": 5, "ai": "gunman", "shot": "red", "burst": 4, "gold": 0.6, "label": "a gangster" },
	"biker": { "sprite": "biker", "hp": 24, "speed": 52, "r": 6, "ai": "knight", "shot": "fire", "gold": 0.5, "label": "a biker" },
	"riotcop": { "sprite": "riotcop", "hp": 40, "speed": 28, "r": 7, "ai": "golem", "shot": "red", "gold": 0.6, "label": "a riot cop" },
	"kingpin": { "sprite": "kingpin", "name": "THE KINGPIN", "hp": 210, "speed": 34, "r": 11, "ai": "champion", "shot": "red",
		"scale": 2.0, "mini": true, "champion": true, "gold": 8.0, "style": "ranged",
		"moves": [["burst", 10], ["lob", 3], ["summon", "gangster", 2], ["spiral", 40], ["summon", "biker", 2], ["ring", 20, 64, 2]] },
	# Dustwater.
	"outlaw": { "sprite": "outlaw", "hp": 15, "speed": 46, "r": 5, "ai": "gunman", "shot": "red", "burst": 2, "gold": 0.55, "label": "an outlaw" },
	"dynamiter": { "sprite": "dynamiter", "hp": 14, "speed": 38, "r": 5, "ai": "lobber", "shot": "fire", "gold": 0.45, "label": "a dynamiter" },
	"sharpshooter": { "sprite": "sharpshooter", "hp": 12, "speed": 36, "r": 5, "ai": "gunman", "shot": "bone", "burst": 1, "shot_speed": 260,
		"aim": 0.9, "gold": 0.5, "label": "a sharpshooter" },
	"coyote": { "sprite": "coyote", "hp": 9, "speed": 90, "r": 5, "ai": "runner", "gold": 0.2, "label": "a coyote" },
	"marshal": { "sprite": "marshal", "name": "THE MARSHAL", "hp": 175, "speed": 48, "r": 10, "ai": "champion", "shot": "bone",
		"scale": 2.0, "mini": true, "champion": true, "gold": 5.0, "style": "ranged",
		"moves": [["duel", 3], ["burst", 6], ["lob", 3], ["charge", 1], ["fan", 6, 0.5, 3], ["summon", "coyote", 3]] },
	# Skyreach Isles.
	"galewarden": { "sprite": "galewarden", "name": "THE GALE WARDEN", "hp": 180, "speed": 50, "r": 10, "ai": "champion",
		"shot": "ice", "scale": 2.0, "mini": true, "champion": true, "fly": true, "gold": 5.0, "style": "ranged",
		"moves": [["blink"], ["fan", 7, 0.45, 3], ["spiral", 36], ["summon", "crow", 3], ["ring", 18, 70, 2], ["rain", 5]] },
	# New foes (ROADMAP 4.4, scripts/entities/enemy_ai2.gd). Skyreach Isles.
	"skykite": { "sprite": "skykite", "hp": 10, "speed": 70, "r": 5, "ai": "skykite", "fly": true, "shot": "cyan", "gold": 0.3, "label": "a sky kite" },
	"gustling": { "sprite": "gustling", "hp": 12, "speed": 55, "r": 5, "ai": "gustling", "fly": true, "shot": "cyan", "gold": 0.3, "label": "a gustling" },
	"stormharpy": { "sprite": "stormharpy", "hp": 14, "speed": 60, "r": 5, "ai": "stormharpy", "fly": true, "shot": "cyan", "gold": 0.35, "label": "a storm harpy" },
	"thunderhead": { "sprite": "thunderhead", "hp": 18, "speed": 30, "r": 6, "ai": "thunderhead", "fly": true, "gold": 0.4, "label": "a thunderhead" },
	"mirrorwing": { "sprite": "mirrorwing", "hp": 12, "speed": 90, "r": 5, "ai": "mirrorwing", "fly": true, "shot": "cyan", "gold": 0.35, "label": "a mirrorwing" },
	# The Drowned Bastion.
	"rampartguard": { "sprite": "rampartguard", "hp": 30, "speed": 32, "r": 6, "ai": "rampartguard", "rule": "shield", "gold": 0.5, "label": "a rampart guard" },
	"sludgecrawler": { "sprite": "sludgecrawler", "hp": 16, "speed": 38, "r": 5, "ai": "sludgecrawler", "gold": 0.35, "label": "a sludge crawler" },
	"chainwarden": { "sprite": "chainwarden", "hp": 24, "speed": 36, "r": 6, "ai": "chainwarden", "shot": "bone", "gold": 0.5, "label": "a chain warden" },
	"tidecaller": { "sprite": "tidecaller", "hp": 18, "speed": 34, "r": 5, "ai": "tidecaller", "gold": 0.45, "label": "a tidecaller" },
	"longpike": { "sprite": "longpike", "hp": 18, "speed": 44, "r": 5, "ai": "longpike", "gold": 0.4, "label": "a longpike" },
	# The Caliber Cathedral.
	"shellpriest": { "sprite": "shellpriest", "hp": 20, "speed": 36, "r": 5, "ai": "shellpriest", "shot": "red", "gold": 0.45, "label": "a shell priest" },
	"dervish": { "sprite": "dervish", "hp": 22, "speed": 44, "r": 5, "ai": "dervish", "rule": "dizzy", "shot": "red", "gold": 0.45, "label": "a bullet dervish" },
	"deacon": { "sprite": "deacon", "hp": 16, "speed": 40, "r": 5, "ai": "deacon", "gold": 0.5, "label": "a deacon" },
	"beltfeeder": { "sprite": "beltfeeder", "hp": 26, "speed": 40, "r": 6, "ai": "beltfeeder", "shot": "red", "summon": "beltlink", "gold": 0.5, "label": "a belt feeder" },
	"beltlink": { "sprite": "beltlink", "hp": 12, "speed": 40, "r": 5, "ai": "beltlink", "shot": "red", "gold": 0.1, "label": "a belt link" },
	"ammomimic": { "sprite": "ammomimic", "hp": 22, "speed": 30, "r": 6, "ai": "ammomimic", "shot": "red", "gold": 0.6, "label": "an ammo mimic" },
	# The original floors, expanded game only (EnemyAI2.OLD_FLOOR_EXTRA).
	"tombspider": { "sprite": "tombspider", "hp": 12, "speed": 50, "r": 5, "ai": "tombspider", "gold": 0.3, "label": "a tomb spider" },
	"candlewight": { "sprite": "candlewight", "hp": 14, "speed": 40, "r": 5, "ai": "candlewight", "fly": true, "shot": "fire", "gold": 0.35, "label": "a candlewight" },
	"gargoyle": { "sprite": "gargoyle", "hp": 40, "speed": 70, "r": 6, "ai": "gargoyle", "gold": 0.5, "label": "a gargoyle" },
	"wardrummer": { "sprite": "wardrummer", "hp": 18, "speed": 36, "r": 5, "ai": "wardrummer", "gold": 0.45, "label": "a war drummer" },
	"bloodleech": { "sprite": "bloodleech", "hp": 10, "speed": 55, "r": 4, "ai": "bloodleech", "no_touch": true, "gold": 0.25, "label": "a blood leech" },
	# The Drowned Bastion and the Caliber Cathedral.
	"rotking": { "sprite": "rotking", "name": "THE ROTTING KING", "hp": 190, "speed": 40, "r": 10, "ai": "champion", "shot": "spore",
		"scale": 2.0, "mini": true, "champion": true, "gold": 5.0, "style": "melee",
		"moves": [["charge", 2], ["ring", 16, 60, 3], ["lob", 3], ["summon", "drowned", 3], ["spiral", 30], ["rain", 4]] },
	"highcaliber": { "sprite": "highcaliber", "name": "THE HIGH CALIBER", "hp": 175, "speed": 44, "r": 10, "ai": "champion", "shot": "red",
		"scale": 2.0, "mini": true, "champion": true, "gold": 5.0, "style": "ranged",
		"moves": [["burst", 12], ["fan", 9, 0.35, 3], ["spiral", 44], ["blink"], ["summon", "gunman", 2], ["ring", 24, 70, 2]] },
	"casingrat": { "sprite": "casingrat", "hp": 30, "speed": 100, "r": 5, "ai": "flee", "gold": 0.0, "label": "a casing rat",
		"away": "THE RAT GOT AWAY WITH YOUR GOLD" },
	# Rift mini-bosses (ROADMAP 4.5, scripts/entities/rift_bosses.gd): the last wave of a new world's
	# second room. "champion": health grows with the floor, the world's hazards leave them be.
	"squallheron": { "sprite": "squallheron", "name": "THE SQUALL HERON", "hp": 150, "speed": 70, "r": 9, "ai": "riftboss",
		"shot": "cyan", "scale": 2.0, "mini": true, "champion": true, "fly": true, "gold": 4.0, "rule": "phase" },
	"tidecaptain": { "sprite": "tidecaptain", "name": "THE DROWNED CAPTAIN", "hp": 165, "speed": 40, "r": 9, "ai": "riftboss",
		"shot": "spore", "scale": 2.0, "mini": true, "champion": true, "gold": 4.0, "rule": "phase" },
	"bellringer": { "sprite": "bellringer", "name": "THE BELLRINGER", "hp": 160, "speed": 36, "r": 9, "ai": "riftboss",
		"shot": "bone", "scale": 2.0, "mini": true, "champion": true, "gold": 4.0, "rule": "phase" },
	# Event rooms.
	"target": { "sprite": "target", "hp": 1, "speed": 0, "r": 6, "ai": "target", "gold": 0.0, "label": "a target", "no_touch": true },
	"goblin": { "sprite": "goblin", "hp": 40, "speed": 96, "r": 5, "ai": "flee", "gold": 0.0, "label": "a loot goblin" },
	"mimic": { "sprite": "mimic", "hp": 80, "speed": 46, "r": 8, "ai": "golem", "shot": "red", "scale": 1.3, "gold": 2.0, "label": "a mimic" },
	"shadow": { "sprite": "shadow", "name": "YOUR SHADOW", "hp": 150, "speed": 60, "r": 6, "ai": "champion", "shot": "dark",
		"mini": true, "champion": true, "gold": 0.0, "style": "ranged",
		"moves": [["burst", 5], ["blink"], ["fan", 5, 0.6, 2], ["charge", 1], ["ring", 12, 60, 2]] },
}

const BOSSES := {
	"colossus": { "name": "THE BONE COLOSSUS", "sprite": "colossus", "hp": 420, "r": 13, "scale": 2 },
	"sporemother": { "name": "THE SPORE MOTHER", "sprite": "sporemother", "hp": 540, "r": 13, "scale": 2 },
	"librarian": { "name": "THE DROWNED LIBRARIAN", "sprite": "librarian", "hp": 640, "r": 13, "scale": 2 },
	"tyrant": { "name": "THE FORGE TYRANT", "sprite": "tyrant", "hp": 760, "r": 13, "scale": 2 },
	"rimewarden": { "name": "THE RIME WARDEN", "sprite": "rimewarden", "hp": 880, "r": 13, "scale": 2 },
	"regent": { "name": "THE PALE REGENT", "sprite": "regent", "hp": 1000, "r": 13, "scale": 2 },
	# Stage 7 guardians.
	"bogmatriarch": { "name": "THE BOG MATRIARCH", "sprite": "bogmatriarch", "hp": 1200, "r": 13, "scale": 2 },
	"ashwarlord": { "name": "THE ASH WARLORD", "sprite": "ashwarlord", "hp": 1350, "r": 13, "scale": 2 },
	"frozenabbot": { "name": "THE FROZEN ABBOT", "sprite": "frozenabbot", "hp": 1500, "r": 13, "scale": 2 },
	"crowking": { "name": "THE CROW KING", "sprite": "crowking", "hp": 1650, "r": 13, "scale": 2 },
	"umbralsun": { "name": "THE UMBRAL SUN", "sprite": "umbralsun", "hp": 2100, "r": 13, "scale": 2.4 },
	# Rift guardians (ROADMAP 4.5, scripts/entities/rift_bosses.gd): behind the champion of a new
	# world, an optional fight. "rift": health grows with the floor (Combat.spawn_boss).
	"stormcrown": { "name": "THE STORMCROWN", "sprite": "stormcrown", "hp": 400, "r": 14, "scale": 2, "rift": true, "rule": "phase" },
	"bilgehydra": { "name": "THE BILGE HYDRA", "sprite": "bilgehydra", "hp": 440, "r": 18, "scale": 2, "rift": true, "rule": "phase" },
	"brassorgan": { "name": "THE BRASS ORGAN", "sprite": "brassorgan", "hp": 420, "r": 20, "scale": 2, "rift": true, "rule": "phase" },
}

const FLOORS := [
	{ "name": "THE OSSUARY", "accent": "bone", "accent_hex": "#d9d0b4", "pool": ["bat", "slime", "skeleton", "skeleton", "bat", "mushroom"], "boss": "colossus", "rooms": 8 },
	{ "name": "MIREWOOD GROTTO", "accent": "lime", "accent_hex": "#b8e05a", "pool": ["mushroom", "slime", "imp", "ghost", "bat", "skeleton"], "boss": "sporemother", "rooms": 9 },
	{ "name": "THE SUNKEN ARCHIVE", "accent": "cyan", "accent_hex": "#6fd3e0", "pool": ["bookwyrm", "drowned", "ghost", "bookwyrm", "skeleton", "slime"], "boss": "librarian", "rooms": 9 },
	{ "name": "THE CINDERFORGE", "accent": "orange", "accent_hex": "#e8873a", "pool": ["imp", "cultist", "knight", "skeleton", "imp", "mushroom"], "boss": "tyrant", "rooms": 10 },
	{ "name": "RIMEFROST VAULT", "accent": "white", "accent_hex": "#e8f6ff", "pool": ["wisp", "golem", "knight", "wisp", "ghost", "cultist"], "boss": "rimewarden", "rooms": 10 },
	{ "name": "THE HOLLOW THRONE", "accent": "purple", "accent_hex": "#a35bd6", "pool": ["cultist", "knight", "ghost", "drowned", "golem", "bookwyrm", "imp"], "boss": "regent", "rooms": 11 },
]

## Design spec step 7: five new biomes after the six original floors. Beating
## the Pale Regent still wins the original game; a rift then leads on into
## these. Extra fields: "mini" (mini-boss guarding the room before the rest
## stop), "hazard" (scripts/world/hazards.gd), "music" (track to reuse).
## Tiles come from kit6..kit10 (recoloured copies of the original kits).
const NEW_FLOORS := [
	{ "name": "RAINMARSH HAMLET", "accent": "green", "accent_hex": "#63b84f", "pool": ["bogling", "gnat", "hexwife", "gnat", "drowned", "bogling"],
	  "boss": "bogmatriarch", "mini": "mirehulk", "hazard": "bog", "music": 1, "rooms": 11 },
	{ "name": "ASHEN WARFRONT", "accent": "orange", "accent_hex": "#e8873a", "pool": ["longbowman", "lancer", "warpriest", "torchimp", "longbowman", "skeleton"],
	  "boss": "ashwarlord", "mini": "ironcaptain", "hazard": "warfront", "music": 3, "rooms": 11 },
	{ "name": "FROSTPEAK MONASTERY", "accent": "white", "accent_hex": "#e8f6ff", "pool": ["monk", "icearcher", "snowlantern", "monk", "wisp", "golem"],
	  "boss": "frozenabbot", "mini": "stoneabbot", "hazard": "icicle", "music": 4, "rooms": 12 },
	{ "name": "NIGHTSPIRE ROOFTOPS", "accent": "gold", "accent_hex": "#f2c94c", "pool": ["gunman", "cutthroat", "crow", "chimneyimp", "gunman", "crow"],
	  "boss": "crowking", "mini": "enforcer", "hazard": "vent", "music": 2, "rooms": 12 },
	{ "name": "THE ECLIPSE", "accent": "red", "accent_hex": "#d8443c", "pool": ["voidling", "shadeknight", "eclipsed", "ghost", "golem", "voidling", "cutthroat"],
	  "boss": "umbralsun", "mini": "herald", "hazard": "rift", "music": 5, "rooms": 12 },
]
## Index of the original final floor (the Hollow Throne).
const THRONE_FLOOR := 5

static var _floors: Array = []

## All floors: the six originals, then the new biomes. --classic leaves them out.
static func floors() -> Array:
	if _floors.is_empty():
		_floors = FLOORS.duplicate()
		if not DebugArgs.has("classic"):
			# The expanded game: a few new foes join the original floors (the original data is untouched).
			for i in EnemyAI2.OLD_FLOOR_EXTRA:
				var f: Dictionary = _floors[i].duplicate(true)
				f["pool"] = f["pool"] + EnemyAI2.OLD_FLOOR_EXTRA[i]
				_floors[i] = f
			_floors.append_array(NEW_FLOORS)
	return _floors

## Music track for a floor (new floors reuse original tracks).
static func floor_music(i: int) -> int:
	return floors()[i].get("music", i)
const BOSS_TRACK := 6

const SPRITE_COLOR := {
	"bat": "#a35bd6", "slime": "#63b84f", "skeleton": "#d9d0b4", "mushroom": "#d8443c", "cultist": "#8a2a33",
	"imp": "#d8443c", "knight": "#8b8f9c", "ghost": "#f4ecd8", "bookwyrm": "#7a5236", "drowned": "#63b84f",
	"wisp": "#6fd3e0", "golem": "#4d9be6", "colossus": "#d9d0b4", "sporemother": "#a35bd6", "librarian": "#2b4f8a",
	"tyrant": "#e8873a", "rimewarden": "#6fd3e0", "regent": "#a35bd6",
	"bogling": "#3f7a5a", "gnat": "#8b8f9c", "hexwife": "#63b84f", "mirehulk": "#63b84f", "longbowman": "#d9d0b4",
	"lancer": "#e8873a", "warpriest": "#e8873a", "torchimp": "#f2c94c", "ironcaptain": "#8b8f9c", "monk": "#e8873a",
	"icearcher": "#c8f0ff", "snowlantern": "#e8f6ff", "stoneabbot": "#8b8f9c", "gunman": "#4e4a5e", "cutthroat": "#5c3483",
	"crow": "#1a1423", "chimneyimp": "#a35bd6", "enforcer": "#4e4a5e", "voidling": "#d8443c", "shadeknight": "#2a2838",
	"eclipsed": "#d8443c", "herald": "#8a2a33", "bogmatriarch": "#3f7a5a", "ashwarlord": "#d8443c",
	"frozenabbot": "#e8f6ff", "crowking": "#5c3483", "umbralsun": "#d8443c",
	# Rift worlds and event rooms.
	"inmate": "#63b84f", "grenadier": "#d8443c", "jailer": "#3f7a5a", "turnkey": "#3f7a5a", "graveborn": "#7a3a8c",
	"bandsman": "#7a5236", "fiendling": "#8a2a33", "blackknight": "#2a2838", "carrionknight": "#2a2838", "drone": "#6fd3e0",
	"glitch": "#5c3483", "chrome": "#8b8f9c", "turret": "#6fd3e0", "broker": "#e86fb4", "thug": "#e86fb4", "molotov": "#2f6b3a",
	"copper": "#4d9be6", "bomber": "#d8443c", "mayor": "#f2c94c", "orderly": "#f4ecd8", "crawler": "#a8705a",
	"static": "#8b8f9c", "tollkeeper": "#2a2838", "rustbutcher": "#7a5236", "neighbour": "#e86fb4", "robovac": "#8b8f9c",
	"burglar": "#2a2838", "gnome": "#d8443c", "landlord": "#e86fb4", "gangster": "#2a2838", "biker": "#d8443c",
	"riotcop": "#2b4f8a", "kingpin": "#f4ecd8", "outlaw": "#7a5236", "dynamiter": "#4d9be6", "sharpshooter": "#63b84f",
	"coyote": "#a8705a", "marshal": "#7a5236", "galewarden": "#9fc3ee", "target": "#d8443c", "skykite": "#9fc3ee", "gustling": "#c8f0ff", "stormharpy": "#a35bd6", "thunderhead": "#8b8f9c", "mirrorwing": "#6fd3e0", "rampartguard": "#3f7a5a", "sludgecrawler": "#63b84f", "chainwarden": "#8b8f9c", "tidecaller": "#2b4f8a", "longpike": "#f4ecd8", "shellpriest": "#d8443c", "dervish": "#d8443c", "deacon": "#f4ecd8", "beltfeeder": "#f2c94c", "beltlink": "#f2c94c", "ammomimic": "#7a5236", "tombspider": "#5c3483", "candlewight": "#f4ecd8", "gargoyle": "#8b8f9c", "wardrummer": "#8a2a33", "bloodleech": "#d8443c", "rotking": "#3f7a5a", "highcaliber": "#d8443c", "squallheron": "#9fc3ee", "tidecaptain": "#3f7a5a", "bellringer": "#5c3483", "casingrat": "#8b8f9c", "goblin": "#63b84f", "mimic": "#7a5236", "shadow": "#3c1d47",
}

## Ember Shrine: things to unlock between runs.
const UNLOCKS := [
	{ "id": "hero_gravedigger", "name": "THE GRAVEDIGGER", "desc": "A NEW HERO WHO SPRAYS GRAVE DIRT", "cost": 40 },
	{ "id": "hero_alchemist", "name": "THE ALCHEMIST", "desc": "A NEW HERO WITH POISON FLASKS", "cost": 80 },
	{ "id": "hero_warden", "name": "THE WARDEN", "desc": "A NEW HERO WITH A RETURNING LANTERN", "cost": 140 },
	{ "id": "cache1", "name": "RELIC CACHE I", "desc": "ADDS 10 COMMON RELICS TO THE CRYPT", "cost": 30 },
	{ "id": "cache2", "name": "RELIC CACHE II", "desc": "ADDS 12 RARE RELICS TO THE CRYPT", "cost": 70 },
	{ "id": "cache3", "name": "RELIC CACHE III", "desc": "ADDS 10 EPIC AND LEGENDARY RELICS", "cost": 120 },
	{ "id": "perk_gold", "name": "DEEP POCKETS", "desc": "START EVERY RUN WITH 20 GOLD", "cost": 25 },
	{ "id": "perk_bombs", "name": "HEAVY SATCHEL", "desc": "START EVERY RUN WITH 2 EXTRA BOMBS", "cost": 20 },
	{ "id": "perk_potion", "name": "SPARE FLASK", "desc": "START EVERY RUN WITH 1 EXTRA POTION", "cost": 35 },
	{ "id": "perk_key", "name": "KEY RING", "desc": "START EVERY RUN WITH A KEY", "cost": 30 },
	{ "id": "perk_heart", "name": "IRON WILL", "desc": "START EVERY RUN WITH +1 MAX HEART", "cost": 70 },
	{ "id": "perk_relic", "name": "LUCKY START", "desc": "START EVERY RUN WITH A RANDOM RELIC", "cost": 90 },
	{ "id": "perk_choice", "name": "KEEN EYE", "desc": "CHESTS OFFER 4 RELICS INSTEAD OF 3", "cost": 110 },
]

const DREAD_DESC := [
	"NORMAL", "FOES +15% HEALTH", "FOES +30% HEALTH, FASTER SHOTS", "MORE ELITES, PRICIER SHOPS",
	"GUARDIANS ENRAGE EARLY", "START WITH 1 LESS HEART",
]

## Experience per kill (01b_traits.rb).
const ENEMY_XP := { "bat": 2, "slime": 3, "slimelet": 1, "skeleton": 3, "mushroom": 3, "cultist": 4, "imp": 3,
	# Stage 7 foes.
	"bogling": 4, "gnat": 2, "hexwife": 4, "longbowman": 4, "lancer": 6, "warpriest": 4, "torchimp": 3, "monk": 5,
	"icearcher": 4, "snowlantern": 4, "gunman": 5, "cutthroat": 4, "crow": 2, "chimneyimp": 3, "voidling": 4,
	"shadeknight": 7, "eclipsed": 5, "mirehulk": 40, "ironcaptain": 45, "stoneabbot": 50, "enforcer": 55, "herald": 60,
	"knight": 6, "ghost": 3, "bookwyrm": 3, "drowned": 4, "wisp": 3, "golem": 7,
	# Rift worlds and event rooms.
	"inmate": 4, "grenadier": 4, "jailer": 6, "graveborn": 4, "bandsman": 4, "fiendling": 3, "blackknight": 7, "drone": 3,
	"glitch": 4, "chrome": 7, "turret": 4, "thug": 4, "molotov": 4, "copper": 5, "bomber": 3, "orderly": 4, "crawler": 2,
	"static": 4, "tollkeeper": 5, "neighbour": 4, "robovac": 5, "burglar": 4, "gnome": 4, "gangster": 5, "biker": 5,
	"riotcop": 7, "outlaw": 5, "dynamiter": 4, "sharpshooter": 4, "coyote": 2, "goblin": 10, "mimic": 15, "shadow": 40,
	"turnkey": 45, "carrionknight": 45, "broker": 45, "mayor": 45, "rustbutcher": 45, "landlord": 45, "kingpin": 45, "marshal": 45, "galewarden": 45, "target": 0, "rotking": 45, "highcaliber": 45, "squallheron": 40, "tidecaptain": 40, "bellringer": 40, "casingrat": 6, "skykite": 3, "gustling": 3, "stormharpy": 4, "thunderhead": 4, "mirrorwing": 4, "rampartguard": 6, "sludgecrawler": 4, "chainwarden": 5, "tidecaller": 5, "longpike": 4, "shellpriest": 5, "dervish": 5, "deacon": 5, "beltfeeder": 6, "beltlink": 2, "ammomimic": 6, "tombspider": 3, "candlewight": 4, "gargoyle": 6, "wardrummer": 4, "bloodleech": 3 }

static func xp_needed(level: int) -> int:
	return roundi(10 + 7 * pow(level, 1.35))

## Room choice: rewards shown on each door before you pick it (01b_traits.rb + 04b_items.rb).
const REWARDS := {
	"relic": { "name": "RELIC", "icon": "chest", "col": "gold" }, "gold": { "name": "GOLD", "icon": "gem", "col": "gold" },
	"heal": { "name": "HEALING", "icon": "heartPick", "col": "pink" }, "supply": { "name": "BOMBS + KEY", "icon": "bomb", "col": "white" },
	"armor": { "name": "ARMOR", "icon": "armor", "col": "cyan" }, "level": { "name": "LEVEL UP", "icon": "icon_level", "col": "lime" },
	"embers": { "name": "EMBERS", "icon": "ember", "col": "orange" }, "rare": { "name": "IRON CHEST", "icon": "chestIron", "col": "cyan" },
	"weapon": { "name": "WEAPON", "icon": "icon_weapon", "col": "orange" }, "gear": { "name": "GEAR", "icon": "icon_gear", "col": "cyan" },
}
const ROOM_KINDS := {
	"combat": { "name": "FIGHT", "icon": "icon_combat", "col": "white" }, "elite": { "name": "ELITE FIGHT", "icon": "icon_elite", "col": "red" },
	"treasure": { "name": "TREASURE", "icon": "chest", "col": "gold" }, "shop": { "name": "SHOP", "icon": "icon_shop", "col": "green" },
	"shrine": { "name": "SHRINE", "icon": "icon_shrine", "col": "purple" }, "challenge": { "name": "CHALLENGE", "icon": "bell", "col": "cyan" },
	"vault": { "name": "VAULT", "icon": "lock", "col": "orange" }, "secret": { "name": "HIDDEN ROOM", "icon": "icon_secret", "col": "pink" },
	"boss": { "name": "GUARDIAN", "icon": "icon_skull", "col": "red" }, "rest": { "name": "CAMPFIRE", "icon": "icon_fire", "col": "orange" },
	# Rift worlds (a themed side stage) and mystery rooms (a random event).
	"rift": { "name": "RIFT", "icon": "riftdoor", "col": "pink" }, "mystery": { "name": "MYSTERY", "icon": "icon_secret", "col": "pink" },
	# The floor map: the way back to where the floor began, and out of a room off the map.
	"start": { "name": "ENTRANCE", "icon": "icon_level", "col": "grey" }, "back": { "name": "BACK", "icon": "icon_level", "col": "grey" },
}

## What a door shows: its room kind, with a rift door named after its world
## (and after how deep into the rift it leads).
static func door_kind(c: Dictionary) -> Dictionary:
	var kind: Dictionary = ROOM_KINDS[c["type"]]
	if c["type"] != "rift":
		return kind
	var th := Themes.by_id(c.get("theme", ""))
	var step: int = c.get("step", 0)
	var name: String = th.get("name", "RIFT")
	if step == 1:
		name = "DEEPER IN"
	elif step == 2:
		name = GameData.ENEMIES[th["champion"]]["name"]
	elif step == 3:
		name = GameData.BOSSES[th["guardian"]]["name"]   # deeper still: the world's guardian
	return { "name": name, "icon": "icon_skull" if step >= 2 else kind["icon"], "col": "red" if step >= 2 else kind["col"] }

## Door frame colours per room type (Render.rb ROOM_COL).
const ROOM_COL := { "boss": "#d8443c", "treasure": "#f2c94c", "shop": "#63b84f", "shrine": "#a35bd6", "combat": "#8b8f9c",
	"elite": "#d8443c", "rest": "#e8873a", "vault": "#e8873a", "secret": "#e86fb4", "challenge": "#6fd3e0",
	"rift": "#e86fb4", "mystery": "#a35bd6", "start": "#5c5a78", "back": "#5c5a78" }
