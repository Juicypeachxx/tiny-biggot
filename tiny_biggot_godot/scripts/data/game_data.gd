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
