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
	{ "id": "banehunter", "name": "THE BANE HUNTER", "sprite": "banehunter", "new": true,
	  "blurb": "A scarred hunter of monsters. Lives off bounties and bitter oils.",
	  "passive": "+25% DAMAGE TO ELITES. A POTION ALSO OILS YOUR BLADE: +40% DAMAGE FOR 10S. EVERY 6S A ROLL CASTS A SIGN: A RING OF SPARKS THAT STUNS THE NEAREST FOE.",
	  "weapon": "BANE SABRE", "hp": 8, "speed": 88, "shot": "slash", "sound": "hatchet", "cost": 160, "trait": "g_bounty",
	  "stats": { "dmg": 7.0, "rate": 2.4, "shot_speed": 0.0, "life": 0.0, "homing": 0.0, "size": 1.0, "pierce": 99 },
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
static var _unlocks: Array = []

## All playable heroes: the originals first (indices 0-5 unchanged), then the
## new ones. --classic leaves the new ones out.
static func heroes() -> Array:
	if _heroes.is_empty():
		_heroes = HEROES.duplicate()
		if not DebugArgs.has("classic"):
			_heroes.append_array(NEW_HEROES)
	return _heroes

static func unlocks() -> Array:
	if _unlocks.is_empty():
		_unlocks = UNLOCKS.duplicate()
		if not DebugArgs.has("classic"):
			for h in NEW_HEROES:
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
}

const BOSSES := {
	"colossus": { "name": "THE BONE COLOSSUS", "sprite": "colossus", "hp": 420, "r": 13, "scale": 2 },
	"sporemother": { "name": "THE SPORE MOTHER", "sprite": "sporemother", "hp": 540, "r": 13, "scale": 2 },
	"librarian": { "name": "THE DROWNED LIBRARIAN", "sprite": "librarian", "hp": 640, "r": 13, "scale": 2 },
	"tyrant": { "name": "THE FORGE TYRANT", "sprite": "tyrant", "hp": 760, "r": 13, "scale": 2 },
	"rimewarden": { "name": "THE RIME WARDEN", "sprite": "rimewarden", "hp": 880, "r": 13, "scale": 2 },
	"regent": { "name": "THE PALE REGENT", "sprite": "regent", "hp": 1000, "r": 13, "scale": 2 },
}

const FLOORS := [
	{ "name": "THE OSSUARY", "accent": "bone", "accent_hex": "#d9d0b4", "pool": ["bat", "slime", "skeleton", "skeleton", "bat", "mushroom"], "boss": "colossus", "rooms": 8 },
	{ "name": "MIREWOOD GROTTO", "accent": "lime", "accent_hex": "#b8e05a", "pool": ["mushroom", "slime", "imp", "ghost", "bat", "skeleton"], "boss": "sporemother", "rooms": 9 },
	{ "name": "THE SUNKEN ARCHIVE", "accent": "cyan", "accent_hex": "#6fd3e0", "pool": ["bookwyrm", "drowned", "ghost", "bookwyrm", "skeleton", "slime"], "boss": "librarian", "rooms": 9 },
	{ "name": "THE CINDERFORGE", "accent": "orange", "accent_hex": "#e8873a", "pool": ["imp", "cultist", "knight", "skeleton", "imp", "mushroom"], "boss": "tyrant", "rooms": 10 },
	{ "name": "RIMEFROST VAULT", "accent": "white", "accent_hex": "#e8f6ff", "pool": ["wisp", "golem", "knight", "wisp", "ghost", "cultist"], "boss": "rimewarden", "rooms": 10 },
	{ "name": "THE HOLLOW THRONE", "accent": "purple", "accent_hex": "#a35bd6", "pool": ["cultist", "knight", "ghost", "drowned", "golem", "bookwyrm", "imp"], "boss": "regent", "rooms": 11 },
]
const BOSS_TRACK := 6

const SPRITE_COLOR := {
	"bat": "#a35bd6", "slime": "#63b84f", "skeleton": "#d9d0b4", "mushroom": "#d8443c", "cultist": "#8a2a33",
	"imp": "#d8443c", "knight": "#8b8f9c", "ghost": "#f4ecd8", "bookwyrm": "#7a5236", "drowned": "#63b84f",
	"wisp": "#6fd3e0", "golem": "#4d9be6", "colossus": "#d9d0b4", "sporemother": "#a35bd6", "librarian": "#2b4f8a",
	"tyrant": "#e8873a", "rimewarden": "#6fd3e0", "regent": "#a35bd6",
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
	"knight": 6, "ghost": 3, "bookwyrm": 3, "drowned": 4, "wisp": 3, "golem": 7 }

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
}
## Door frame colours per room type (Render.rb ROOM_COL).
const ROOM_COL := { "boss": "#d8443c", "treasure": "#f2c94c", "shop": "#63b84f", "shrine": "#a35bd6", "combat": "#8b8f9c",
	"elite": "#d8443c", "rest": "#e8873a", "vault": "#e8873a", "secret": "#e86fb4", "challenge": "#6fd3e0" }
