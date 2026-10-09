class_name Weapons
extends RefCounted
## Weapons and attack types (port of 01c_items.rb ARCH / WEAPONS and the
## stat helpers of 04b_items.rb). Gear tables arrive with items (stage 5).
## Stat tuples [key, value] apply while a weapon is held: keys in MUL_KEYS
## multiply, all others add. Hooks [key, value] add to the player's gf table.

const MUL_KEYS := ["dmg", "rate", "shot_speed", "life", "size", "speed", "dodge_cd", "gold_mult", "roll_speed",
	"bomb_mult", "bomb_r", "xp_mult", "fam_rate"]
## Consumables are granted once per item, never taken back (04b ONCE_KEYS).
const ONCE_KEYS := ["armor", "bombs", "keys", "potions"]

const TAG_COLS := {
	"pyre": ["#e8873a", "#d8443c", "#f2c94c"], "frost": ["#6fd3e0", "#4d9be6", "#ffffff"], "venom": ["#b8e05a", "#2f6b3a", "#f4ffd0"],
	"storm": ["#4d9be6", "#2b4f8a", "#c8f0ff"], "blood": ["#d8443c", "#8a2a33", "#ff8a8a"], "bulwark": ["#8b8f9c", "#4e4a5e", "#f4ecd8"],
	"shadow": ["#a35bd6", "#5c3483", "#e8c8ff"], "arcane": ["#e86fb4", "#a35bd6", "#ffffff"], "fortune": ["#f2c94c", "#e8873a", "#fffbe0"],
	"demolition": ["#8b8f9c", "#1a1423", "#e8873a"], "swarm": ["#f2c94c", "#7a5236", "#fffbe0"], "core": ["#c9c2a8", "#8b8f9c", "#ffffff"],
	# New archetype tags (design spec section 4).
	"edge": ["#f4ecd8", "#ffffff", "#f2c94c"], "fury": ["#e8573a", "#8a2a33", "#f2c94c"], "malice": ["#7a3a8c", "#3c1d47", "#d8443c"],
}

## Attack types. Defaults are overridden per weapon.
const ARCH := {
	"bolt": { "name": "BOW", "dmg": 3.0, "rate": 4.0, "speed": 250, "life": 0.8, "size": 1.0, "pierce": 0, "count": 1, "spread": 0.12, "homing": 0.0 },
	"orb": { "name": "STAFF", "dmg": 4.0, "rate": 3.0, "speed": 150, "life": 1.0, "size": 1.0, "pierce": 0, "count": 1, "spread": 0.2, "homing": 2.2 },
	"spin": { "name": "THROWN AXE", "dmg": 8.0, "rate": 1.8, "speed": 180, "life": 0.72, "size": 1.6, "pierce": 2, "count": 1, "spread": 0.3, "homing": 0.0 },
	"shot": { "name": "SCATTERGUN", "dmg": 2.4, "rate": 2.2, "speed": 220, "life": 0.5, "size": 1.0, "pierce": 0, "count": 4, "spread": 0.16, "homing": 0.0 },
	"flask": { "name": "FLASK", "dmg": 5.0, "rate": 2.0, "speed": 160, "life": 0.85, "size": 1.0, "pierce": 0, "count": 1, "spread": 0.3, "homing": 0.0 },
	"boomer": { "name": "BOOMERANG", "dmg": 4.5, "rate": 2.0, "speed": 210, "life": 0.9, "size": 1.2, "pierce": 99, "count": 1, "spread": 0.35, "homing": 0.0 },
	"slash": { "name": "SWORD", "dmg": 7.0, "rate": 2.2, "speed": 0, "life": 0, "size": 1.0, "pierce": 99, "count": 1, "spread": 0, "homing": 0.0, "range": 34, "arc": 110 },
	"thrust": { "name": "SPEAR", "dmg": 6.0, "rate": 2.4, "speed": 0, "life": 0, "size": 1.0, "pierce": 99, "count": 1, "spread": 0.3, "homing": 0.0, "range": 58, "width": 8 },
	"beam": { "name": "RAY", "dmg": 1.4, "rate": 10.0, "speed": 0, "life": 0, "size": 1.0, "pierce": 0, "count": 1, "spread": 0, "homing": 0.0, "range": 140 },
	"flame": { "name": "SPRAYER", "dmg": 1.0, "rate": 14.0, "speed": 150, "life": 0.35, "size": 0.8, "pierce": 99, "count": 1, "spread": 0.25, "homing": 0.0 },
	"disc": { "name": "DISC", "dmg": 4.0, "rate": 2.0, "speed": 200, "life": 1.6, "size": 1.2, "pierce": 1, "count": 1, "spread": 0.4, "homing": 0.0, "bounce": 3 },
	"pulse": { "name": "ORB", "dmg": 3.8, "rate": 0.9, "speed": 60, "life": 2.5, "size": 1.4, "pierce": 99, "count": 1, "spread": 0, "homing": 0.0 },
	"zap": { "name": "RUNE", "dmg": 4.0, "rate": 2.5, "speed": 0, "life": 0, "size": 1.0, "pierce": 0, "count": 1, "spread": 0, "homing": 0.0, "range": 130, "chain": 2 },
	"nova": { "name": "CHIME", "dmg": 3.0, "rate": 1.4, "speed": 180, "life": 0.6, "size": 1.0, "pierce": 0, "count": 10, "spread": 0, "homing": 0.0 },
	"mine": { "name": "TRAP", "dmg": 14.0, "rate": 1.5, "speed": 0, "life": 8.0, "size": 1.0, "pierce": 0, "count": 1, "spread": 0, "homing": 0.0 },
	"rail": { "name": "RAILSHOT", "dmg": 14.0, "rate": 1.0, "speed": 600, "life": 0.8, "size": 1.0, "pierce": 99, "count": 1, "spread": 0, "homing": 0.0 },
	"burst": { "name": "BURST GUN", "dmg": 2.6, "rate": 1.6, "speed": 260, "life": 0.75, "size": 1.0, "pierce": 0, "count": 1, "spread": 0.06, "homing": 0.0 },
	"gatling": { "name": "GATLING", "dmg": 1.8, "rate": 5.0, "speed": 260, "life": 0.7, "size": 0.9, "pierce": 0, "count": 1, "spread": 0.08, "homing": 0.0 },
	"whip": { "name": "WHIP", "dmg": 5.0, "rate": 2.0, "speed": 0, "life": 0, "size": 1.0, "pierce": 99, "count": 1, "spread": 0, "homing": 0.0, "range": 70, "width": 6 },
	"summon": { "name": "CALLER", "dmg": 2.5, "rate": 0.8, "speed": 140, "life": 1.0, "size": 1.0, "pierce": 0, "count": 1, "spread": 0, "homing": 2.0 },
	# ROADMAP 4.6 part 1, MAYHEM (scripts/combat/arsenal.gd). "life" is a fuse or a flight time; "radius" a blast.
	"grenade": { "name": "GRENADE", "dmg": 9.0, "rate": 1.1, "speed": 170, "life": 1.5, "size": 1.0, "pierce": 0, "count": 1, "spread": 0.25, "homing": 0.0, "radius": 34 },
	"rocket": { "name": "LAUNCHER", "dmg": 12.0, "rate": 0.9, "speed": 140, "life": 1.6, "size": 1.0, "pierce": 0, "count": 1, "spread": 0.12, "homing": 0.0, "radius": 30 },
	"missile": { "name": "MISSILE POD", "dmg": 4.5, "rate": 0.8, "speed": 150, "life": 3.0, "size": 1.0, "pierce": 0, "count": 1, "spread": 0, "homing": 5.0, "radius": 16, "swarm": 4 },
	"sticky": { "name": "STICKY BOMB", "dmg": 11.0, "rate": 1.3, "speed": 200, "life": 2.5, "size": 1.0, "pierce": 0, "count": 1, "spread": 0.2, "homing": 0.0, "radius": 30 },
	"mortar": { "name": "MORTAR", "dmg": 11.0, "rate": 0.9, "speed": 0, "life": 0.9, "size": 1.0, "pierce": 0, "count": 1, "spread": 0, "homing": 0.0, "radius": 30, "range": 220 },
	"walker": { "name": "WIND-UP BOMB", "dmg": 12.0, "rate": 0.8, "speed": 90, "life": 6.0, "size": 1.0, "pierce": 0, "count": 1, "spread": 0.4, "homing": 0.0, "radius": 30 },
	"strike": { "name": "AIRSTRIKE", "dmg": 9.0, "rate": 0.5, "speed": 0, "life": 1.0, "size": 1.0, "pierce": 0, "count": 1, "spread": 0, "homing": 0.0, "radius": 26, "bombs": 5, "range": 300 },
	"dynamite": { "name": "DYNAMITE", "dmg": 6.0, "rate": 0.9, "speed": 150, "life": 1.3, "size": 1.0, "pierce": 0, "count": 1, "spread": 0.3, "homing": 0.0, "radius": 32 },
	"wave": { "name": "REPULSOR", "dmg": 4.0, "rate": 1.2, "speed": 0, "life": 0, "size": 1.0, "pierce": 99, "count": 1, "spread": 0, "homing": 0.0, "range": 96, "arc": 70, "push": 280 },
	# ROADMAP 4.6 part 2, CHARGE AND COMBO (scripts/combat/charged.gd). For the held kinds (charge, slam, dash)
	# "rate" is how fast a charge fills (full in 1/rate s); "range" is a slam's ring or a dash's length.
	"charge": { "name": "CHARGE CANNON", "dmg": 8.0, "rate": 1.0, "speed": 230, "life": 1.2, "size": 1.0, "pierce": 0, "count": 1, "spread": 0, "homing": 0.0 },
	"slam": { "name": "MAUL", "dmg": 10.0, "rate": 0.9, "speed": 170, "life": 0, "size": 1.0, "pierce": 99, "count": 1, "spread": 0, "homing": 0.0, "range": 70 },
	"dash": { "name": "DASH BLADE", "dmg": 12.0, "rate": 1.1, "speed": 0, "life": 0, "size": 1.0, "pierce": 99, "count": 1, "spread": 0, "homing": 0.0, "range": 90 },
	"javelin": { "name": "JAVELIN", "dmg": 8.0, "rate": 1.3, "speed": 300, "life": 0.7, "size": 1.0, "pierce": 0, "count": 1, "spread": 0, "homing": 0.0 },
	"hook": { "name": "HOOK", "dmg": 8.0, "rate": 1.4, "speed": 340, "life": 0.45, "size": 1.0, "pierce": 0, "count": 1, "spread": 0, "homing": 0.0, "range": 26 },
	"combo": { "name": "COMBO", "dmg": 5.0, "rate": 2.6, "speed": 0, "life": 0, "size": 1.0, "pierce": 99, "count": 1, "spread": 0, "homing": 0.0, "range": 30, "arc": 100 },
	"heat": { "name": "HEAT GUN", "dmg": 2.0, "rate": 7.0, "speed": 260, "life": 0.7, "size": 0.9, "pierce": 0, "count": 1, "spread": 0.08, "homing": 0.0, "heat": 30 },
	"reload": { "name": "MAGAZINE GUN", "dmg": 4.0, "rate": 6.0, "speed": 300, "life": 0.8, "size": 1.0, "pierce": 0, "count": 1, "spread": 0.04, "homing": 0.0, "mag": 6, "reload": 1.0 },
	"orbit": { "name": "STAR GATHERER", "dmg": 5.0, "rate": 2.2, "speed": 230, "life": 1.6, "size": 1.0, "pierce": 0, "count": 1, "spread": 0, "homing": 4.0, "stars": 6 },
	"recall": { "name": "SNAPBACK", "dmg": 7.0, "rate": 1.6, "speed": 480, "life": 0.45, "size": 1.0, "pierce": 99, "count": 1, "spread": 0, "homing": 0.0 },
	# ROADMAP 4.6 part 3, DECK AND DEN (scripts/combat/summons.gd): cards, turrets, summoned fighters.
	"deck": { "name": "CARD DECK", "dmg": 5.0, "rate": 2.0, "speed": 360, "life": 0, "size": 1.0, "pierce": 0, "count": 1, "spread": 0, "homing": 0.0 },
	"turret": { "name": "TURRET KIT", "dmg": 5.0, "rate": 0.5, "speed": 0, "life": 0, "size": 1.0, "pierce": 0, "count": 1, "spread": 0, "homing": 0.0 },
	"thrall": { "name": "SUMMONING", "dmg": 4.0, "rate": 1.4, "speed": 230, "life": 0.9, "size": 1.0, "pierce": 0, "count": 1, "spread": 0.1, "homing": 0.0 },
	"command": { "name": "PET COMMAND", "dmg": 7.0, "rate": 0.9, "speed": 0, "life": 0, "size": 1.0, "pierce": 0, "count": 1, "spread": 0, "homing": 0.0 },
	"mirror": { "name": "MIRROR", "dmg": 2.4, "rate": 2.5, "speed": 260, "life": 0.8, "size": 1.0, "pierce": 0, "count": 1, "spread": 0.1, "homing": 0.0 },
	"swarm": { "name": "SWARM", "dmg": 5.0, "rate": 1.5, "speed": 0, "life": 0, "size": 1.0, "pierce": 0, "count": 1, "spread": 0, "homing": 0.0 },
	"egg": { "name": "EGG", "dmg": 3.6, "rate": 2.6, "speed": 240, "life": 0.8, "size": 1.0, "pierce": 0, "count": 1, "spread": 0.1, "homing": 0.0 },
	# ROADMAP 4.6 part 4, GUNPLAY AND ODDITIES (scripts/combat/oddities.gd).
	"letters": { "name": "LETTER GUN", "dmg": 4.0, "rate": 2.4, "speed": 240, "life": 0.9, "size": 1.0, "pierce": 0, "count": 1, "spread": 0, "homing": 0.0 },
	"bubble": { "name": "BUBBLE GUN", "dmg": 5.0, "rate": 1.8, "speed": 140, "life": 1.5, "size": 1.0, "pierce": 0, "count": 1, "spread": 0, "homing": 0.0 },
	"flak": { "name": "FLAK GUN", "dmg": 3.5, "rate": 4.0, "speed": 300, "life": 0.7, "size": 1.0, "pierce": 0, "count": 1, "spread": 0, "homing": 0.0 },
	"paint": { "name": "PAINT GUN", "dmg": 3.5, "rate": 3.0, "speed": 220, "life": 0.6, "size": 1.0, "pierce": 0, "count": 1, "spread": 0, "homing": 0.0 },
	"slots": { "name": "SLOT GUN", "dmg": 3.6, "rate": 2.0, "speed": 260, "life": 0.8, "size": 1.0, "pierce": 0, "count": 1, "spread": 0.06, "homing": 0.0 },
	"roller": { "name": "ROLLER", "dmg": 6.0, "rate": 0.8, "speed": 110, "life": 3.0, "size": 1.0, "pierce": 0, "count": 1, "spread": 0, "homing": 0.0 },
	"money": { "name": "MONEY GUN", "dmg": 6.0, "rate": 0.8, "speed": 280, "life": 1.0, "size": 1.0, "pierce": 0, "count": 1, "spread": 0, "homing": 0.0 },
	"camera": { "name": "CAMERA", "dmg": 5.0, "rate": 0.9, "speed": 0, "life": 0, "size": 1.0, "pierce": 0, "count": 1, "spread": 0, "homing": 0.0 },
	"ray": { "name": "RAY", "dmg": 1.2, "rate": 8.0, "speed": 0, "life": 0, "size": 1.0, "pierce": 0, "count": 1, "spread": 0, "homing": 0.0 },
	"junk": { "name": "JUNK GUN", "dmg": 5.0, "rate": 1.6, "speed": 200, "life": 0.9, "size": 1.0, "pierce": 0, "count": 1, "spread": 0, "homing": 0.0 },
	"bat": { "name": "BAT", "dmg": 9.0, "rate": 1.2, "speed": 0, "life": 0, "size": 1.0, "pierce": 99, "count": 1, "spread": 0, "homing": 0.0, "range": 30, "arc": 120 },
	"stab": { "name": "DAGGER", "dmg": 4.0, "rate": 4.0, "speed": 0, "life": 0, "size": 1.0, "pierce": 99, "count": 1, "spread": 0, "homing": 0.0, "range": 20 },
	"duel": { "name": "DUEL PISTOL", "dmg": 5.0, "rate": 2.0, "speed": 320, "life": 0.9, "size": 1.0, "pierce": 0, "count": 1, "spread": 0, "homing": 0.0 },
	"shrink": { "name": "SHRINK GUN", "dmg": 3.0, "rate": 1.6, "speed": 260, "life": 0.9, "size": 1.0, "pierce": 0, "count": 1, "spread": 0, "homing": 0.0 },
	"blower": { "name": "BLOWER", "dmg": 3.0, "rate": 4.0, "speed": 0, "life": 0, "size": 1.0, "pierce": 0, "count": 1, "spread": 0, "homing": 0.0 },
	"dome": { "name": "DOME", "dmg": 5.0, "rate": 1.0, "speed": 0, "life": 0, "size": 1.0, "pierce": 0, "count": 1, "spread": 0, "homing": 0.0 },
	"flail": { "name": "FLAIL", "dmg": 6.0, "rate": 1.6, "speed": 0, "life": 0, "size": 1.0, "pierce": 99, "count": 1, "spread": 0, "homing": 0.0, "range": 70 },   # 10.4
	"coin": { "name": "COIN GUN", "dmg": 4.0, "rate": 3.0, "speed": 280, "life": 0.8, "size": 1.0, "pierce": 0, "count": 1, "spread": 0.05, "homing": 0.0 },
	# Stage 23 THE SPELLBOOK (scripts/combat/spells.gd). "life" is how long a spell lasts, "radius" its reach,
	# "range" how far it is cast (for the item card).
	"singularity": { "name": "BLACK HOLE", "dmg": 6.0, "rate": 0.9, "speed": 120, "life": 0.9, "size": 1.0, "pierce": 0, "count": 1, "spread": 0, "homing": 0.0, "radius": 48 },
	"serpent": { "name": "SERPENT", "dmg": 3.0, "rate": 0.8, "speed": 120, "life": 3.0, "size": 1.0, "pierce": 99, "count": 1, "spread": 0, "homing": 0.0 },
	"comet": { "name": "COMET", "dmg": 9.0, "rate": 0.7, "speed": 0, "life": 0, "size": 1.0, "pierce": 99, "count": 1, "spread": 0, "homing": 0.0, "range": 260 },
	"glyph": { "name": "GLYPH", "dmg": 7.0, "rate": 1.2, "speed": 0, "life": 0, "size": 1.0, "pierce": 99, "count": 1, "spread": 0, "homing": 0.0, "range": 260 },
	"blades": { "name": "SPELLBLADES", "dmg": 3.0, "rate": 1.0, "speed": 250, "life": 4.0, "size": 1.0, "pierce": 99, "count": 1, "spread": 0, "homing": 0.0 },
	"chrono": { "name": "TIME STOP", "dmg": 3.0, "rate": 0.5, "speed": 0, "life": 2.2, "size": 1.0, "pierce": 0, "count": 1, "spread": 0, "homing": 0.0, "radius": 56, "range": 260 },
	"prism": { "name": "PRISM", "dmg": 5.0, "rate": 1.6, "speed": 220, "life": 0.9, "size": 1.0, "pierce": 0, "count": 1, "spread": 0, "homing": 0.0 },
	"cloud": { "name": "STORM CLOUD", "dmg": 4.0, "rate": 0.45, "speed": 0, "life": 4.0, "size": 1.0, "pierce": 0, "count": 1, "spread": 0, "homing": 0.0, "range": 320 },
	"pinball": { "name": "PINBALL", "dmg": 3.0, "rate": 1.2, "speed": 300, "life": 2.0, "size": 1.0, "pierce": 99, "count": 1, "spread": 0, "homing": 0.0 },
	"wild": { "name": "WILD MAGIC", "dmg": 6.0, "rate": 1.1, "speed": 0, "life": 0, "size": 1.0, "pierce": 0, "count": 1, "spread": 0, "homing": 0.0, "range": 260 },
	# Stage 31 THE TOYBOX (scripts/combat/toys.gd). "life" is how long a toy lasts, "radius" its reach, "range" how far.
	"shark": { "name": "LAND SHARK", "dmg": 6.0, "rate": 0.8, "speed": 180, "life": 7.0, "size": 1.0, "pierce": 0, "count": 1, "spread": 0, "homing": 0.0, "range": 320 },
	"twister": { "name": "TWISTER", "dmg": 5.0, "rate": 0.5, "speed": 70, "life": 2.6, "size": 1.0, "pierce": 99, "count": 1, "spread": 0, "homing": 0.0, "radius": 22 },
	"disco": { "name": "DISCO BALL", "dmg": 4.0, "rate": 0.9, "speed": 0, "life": 3.0, "size": 1.0, "pierce": 99, "count": 1, "spread": 0, "homing": 0.0, "radius": 140 },
	"yoyo": { "name": "YO-YO", "dmg": 5.0, "rate": 1.6, "speed": 320, "life": 0.45, "size": 1.0, "pierce": 99, "count": 1, "spread": 0, "homing": 0.0, "range": 144 },
	"portal": { "name": "PORTAL", "dmg": 6.0, "rate": 1.4, "speed": 300, "life": 0.6, "size": 1.0, "pierce": 1, "count": 1, "spread": 0, "homing": 0.0, "range": 260 },
	"saw": { "name": "SAW TRAP", "dmg": 4.0, "rate": 1.2, "speed": 240, "life": 6.0, "size": 1.0, "pierce": 99, "count": 1, "spread": 0, "homing": 0.0 },
	"voodoo": { "name": "VOODOO PIN", "dmg": 5.0, "rate": 1.8, "speed": 300, "life": 0.9, "size": 1.0, "pierce": 0, "count": 1, "spread": 0, "homing": 0.0 },
	"anvil": { "name": "ANVIL DROP", "dmg": 14.0, "rate": 0.6, "speed": 0, "life": 5.0, "size": 1.0, "pierce": 99, "count": 1, "spread": 0, "homing": 0.0, "range": 260 },
}
const ARCH_DESC := {
	"bolt": "FIRES FAST BOLTS", "orb": "HOMING BOLTS", "spin": "SPINNING THROWS THAT PIERCE", "shot": "A SPREAD OF SHOT",
	"flask": "BURSTING THROWS", "boomer": "FLIES OUT AND BACK, HITTING TWICE", "slash": "MELEE ARC IN FRONT OF YOU",
	"thrust": "MELEE THRUST THAT PIERCES A LINE", "beam": "A CONSTANT RAY", "flame": "SHORT CONE OF FLAME",
	"disc": "BOUNCES OFF WALLS", "pulse": "SLOW ORB THAT HURTS ALL NEARBY", "zap": "INSTANT ARCS THAT CHAIN",
	"nova": "A RING OF SHOTS AROUND YOU", "mine": "TOSSES MINES THAT BLOW WHEN FOES COME NEAR", "rail": "PIERCING SHOTS AT HUGE SPEED",
	"burst": "THREE-SHOT BURSTS", "gatling": "FIRES FASTER THE LONGER YOU SHOOT", "whip": "LONG LASH, THE TIP ALWAYS CRITS",
	"summon": "EACH SHOT RAISES A SPIRIT WISP",
	"grenade": "BOUNCES ALONG, THEN BLOWS", "rocket": "SPEEDS UP, BLOWS ON IMPACT", "missile": "SMALL MISSILES THAT HUNT FOES",
	"sticky": "STICKS TO FOES AND WALLS, THEN BLOWS", "mortar": "LOBBED OVER WALLS ONTO A FOE", "walker": "A LITTLE BOMB THAT GOES BY ITSELF",
	"strike": "CALLS DOWN A STRIKE", "dynamite": "A BUNDLE OF STICKS THAT SET EACH OTHER OFF", "wave": "A CONE OF FORCE",
	"charge": "HOLD TO CHARGE A SHOT THAT GROWS", "slam": "HOLD TO CHARGE A SLAM: A SHOCKWAVE", "dash": "HOLD TO CHARGE A DASH THROUGH FOES",
	"javelin": "THROW IT, THEN DASH TO IT", "hook": "PULLS A FOE IN, THEN PUNCHES", "combo": "THREE DIFFERENT ATTACKS IN TURN",
	"heat": "FIRES FAST, OVERHEATS AND VENTS", "reload": "A MAGAZINE OF SHOTS, THEN A RELOAD", "orbit": "GATHERS STARS, THEN SENDS THEM",
	"recall": "FLIES OUT AND WAITS TO BE CALLED BACK", "flail": "A BALL ON A CHAIN CIRCLES YOU; ATTACKS LASH IT OUT",
	"deck": "A DECK OF CARDS, ONE PLAYED AN ATTACK", "turret": "BUILDS TURRETS THAT FIGHT BY THEMSELVES", "thrall": "CALLS FIGHTERS TO YOUR SIDE",
	"command": "SENDS A SPIRIT AT THE FOE", "mirror": "IMAGES OF YOU THAT FIGHT TOO", "swarm": "A SWARM YOU SEND AT FOES",
	"egg": "AN EGG THAT HATCHES A DRAGON",
	"letters": "SHOTS THAT SPELL A WORD", "bubble": "BUBBLES THAT TRAP FOES", "flak": "SHOTS THAT POP ENEMY SHOTS",
	"paint": "SHOTS THAT PAINT THE FLOOR", "slots": "EVERY SHOT SPINS THE REELS", "roller": "A BALL THAT ROLLS AND GROWS",
	"money": "SHOTS PAID FOR IN GOLD", "camera": "A FLASH THAT STUNS", "ray": "A RAY THAT FREEZES", "junk": "FIRES JUNK",
	"bat": "KNOCKS FOES FLYING", "stab": "QUICK STABS", "duel": "THE FIRST HIT ON A FOE CRITS", "shrink": "SHRINKS FOES",
	"blower": "A GUST THAT TURNS SHOTS AROUND", "dome": "A DOME THAT STOPS SHOTS", "coin": "SHOOT THE COIN",
	"singularity": "A DARK MOTE THAT BECOMES A BLACK HOLE", "serpent": "A SERPENT OF MAGIC THAT HUNTS FOES",
	"comet": "CALLS A COMET ACROSS THE ROOM", "glyph": "A RUNE UNDER THE FOE ERUPTS", "blades": "CONJURES BLADES THAT FIGHT BY THEMSELVES",
	"chrono": "A CIRCLE WHERE TIME STOPS", "prism": "A CRYSTAL BOLT THAT SPLITS IN THREE", "cloud": "A STORM CLOUD THAT FOLLOWS FOES",
	"pinball": "A BALL OF LIGHT THAT BOUNCES FOE TO FOE", "wild": "A DIFFERENT SPELL EVERY CAST",
	"shark": "A FIN THAT SWIMS UNDER THE FLOOR AND BITES", "twister": "A TWISTER THAT CARRIES FOES AND FLINGS THEM",
	"disco": "A MIRROR BALL THAT MAKES FOES DANCE", "yoyo": "OUT AND BACK ON A STRING THAT CUTS",
	"portal": "SHOTS COME OUT OF A PORTAL BEHIND THE FOE", "saw": "SAW BLADES THAT DIG IN AS TRAPS",
	"voodoo": "PINNED FOES SHARE THEIR PAIN", "anvil": "AN ANVIL FROM THE SKY THAT STAYS AS COVER",
}
const BULLET_KIND := { "bolt": "bolt", "orb": "hex", "spin": "spin", "shot": "clod", "flask": "flask", "boomer": "boomer",
	"flame": "fire", "disc": "disc", "pulse": "pulse", "nova": "spark", "mine": "mine", "rail": "rail", "burst": "bolt",
	"gatling": "bolt", "summon": "hex", "thrall": "hex", "mirror": "bolt", "egg": "hex" }
const HERO_WEAPON := { "hexer": "hexwand", "poacher": "repeater", "brute": "pithatchet", "gravedigger": "graveshovel",
	"alchemist": "flasksling", "warden": "lantern",
	# Step 6 heroes (signature weapons are rows after content batch 1).
	"banehunter": "banesabre", "oathbreaker": "ironslab", "wayfarer": "wayfareredge", "racketeer": "snubguns",
	"condemned": "shackleflail", "cartomancer": "giltdeck", "sellsword": "warlance", "gaolbird": "irontalons",
	"beekeeper": "hivesmoker", "tinkerer": "rivetgun", "clockmaker": "gearwound", "minstrel": "lute", "jester": "jugglepins", "berserker": "greataxe", "forsaken": "rustyshiv", "boneweaver": "bonestaff", "mirrorknight": "brightblade",
	"plaguesaint": "censerflail", "frostwitch": "iciclewand", "demolitionist": "blastmortar", "executioner": "headsmansaxe",
	"pilgrim": "pilgrimstaff", "beastmaster": "beastspear", "inkling": "inkquill",
	"mindwarden": "thoughtstone", "tavernknight": "tankardmaul", "trickshot": "quickcrossbow", "bonecaller": "bonecenser" }

## [id, name, kind, rarity, tags, shape, overrides, stats, hooks, desc, effects] (Ruby wpn()).
## The first ORIGINAL_COUNT rows are the original weapons; later rows are new
## content and may add an 11th column of effects (procs, pct stats) and a 12th
## naming an existing sprite to reuse (placeholder art).
const ORIGINAL_COUNT := 113
const ROWS := [
	# --- Bows and crossbows ---
	["repeater", "REPEATER", "bolt", "common", [], "crossbow", { "dmg": 2.0, "rate": 6.5, "speed": 270, "life": 0.75, "pierce": 1  }, [], [], "THE POACHER'S CROSSBOW. FAST AND FLAT."],
	["huntbow", "HUNTING BOW", "bolt", "common", ["fortune"], "bow", { "dmg": 3.5, "rate": 3.6  }, [], [["far_dmg", 0.4]], "SHOTS FROM AFAR HIT 40% HARDER."],
	["streetpistol", "STREET PISTOL", "bolt", "common", ["blood"], "pistol", { "dmg": 3.0, "rate": 4.5, "speed": 300  }, [], [["nth_big", 6]], "EVERY 6TH SHOT HITS FOR TRIPLE DAMAGE."],
	["silvercrossbow", "SILVERED CROSSBOW", "bolt", "rare", ["bulwark"], "crossbow", { "dmg": 3.4, "rate": 4.0, "pierce": 2  }, [], [["elite_dmg", 0.5]], "SILVER BOLTS. +50% DAMAGE TO ELITES AND GUARDIANS."],
	["longrifle", "LONG RIFLE", "bolt", "rare", ["shadow"], "rifle", { "dmg": 9.0, "rate": 1.4, "speed": 420, "life": 0.9, "pierce": 1  }, [], [["still_dmg", 0.6]], "+60% DAMAGE WHILE STANDING STILL."],
	["thornbow", "THORNBOW", "bolt", "epic", ["venom"], "bow", { "dmg": 3.2, "rate": 4.0  }, [["poison", 1]], [["split", 2]], "ARROWS BURST INTO TWO POISON THORNS ON HIT."],
	["sunpiercer", "SUNPIERCER", "bolt", "legend", ["pyre"], "bow", { "dmg": 5.0, "rate": 3.2, "speed": 320, "pierce": 3  }, [["burn", 0.35]], [["nth_nova", 5]], "BURNING ARROWS. EVERY 5TH ERUPTS IN A RING OF FIRE."],
	# --- Staffs and wands ---
	["hexwand", "HEX WAND", "orb", "common", [], "wand", { "dmg": 4.0, "rate": 3.2  }, [], [], "THE HEXER'S WAND. BOLTS CURVE TOWARD FOES."],
	["emberwand", "EMBER WAND", "orb", "common", ["pyre"], "wand", { "dmg": 3.6, "rate": 3.4  }, [["burn", 0.2]], [], "SPARKS OF CINDER THAT OFTEN BURN."],
	["rimerod", "RIME ROD", "orb", "common", ["frost"], "wand", { "dmg": 3.4, "rate": 3.4  }, [["chill", 0.25]], [], "COLD BOLTS THAT CHILL."],
	["witchstaff", "WITCHWOOD STAFF", "orb", "rare", ["arcane"], "orbstaff", { "dmg": 4.2, "rate": 3.0, "homing": 3.0  }, [], [["mark", 0.25]], "BOLTS MARK FOES. MARKED FOES TAKE +25% DAMAGE."],
	["stormcaller", "STORMCALLER", "orb", "rare", ["storm"], "staff", { "dmg": 3.6, "rate": 3.2  }, [["chain", 0.25]], [["nth_zap", 6]], "HITS OFTEN ARC. EVERY 6TH BOLT CALLS LIGHTNING."],
	["soulstaff", "SOULREAVER STAFF", "orb", "epic", ["shadow"], "skullstaff", { "dmg": 4.0, "rate": 3.0  }, [], [["souls", 0.006]], "EVERY KILL THIS FLOOR ADDS 0.6% DAMAGE, UP TO +50%."],
	["laststar", "THE LAST STAR", "orb", "legend", ["arcane"], "orbstaff", { "dmg": 5.0, "rate": 3.0, "homing": 3.5, "size": 1.3  }, [], [["split", 3], ["grow", 1.0]], "BOLTS SWELL AS THEY FLY AND SHATTER INTO 3 STARS."],
	# --- Thrown axes ---
	["pithatchet", "PIT HATCHET", "spin", "common", [], "axe", {  }, [], [], "THE BRUTE'S HATCHET. HEAVY AND PIERCING."],
	["woodaxe", "WOODSMAN'S AXE", "spin", "common", [], "axe", { "dmg": 9.0, "rate": 1.6  }, [], [["knock", 1.8]], "KNOCKS FOES FAR BACK."],
	["bonecleaver", "BONE CLEAVER", "spin", "rare", ["blood"], "cleaver", { "dmg": 10.0, "rate": 1.5  }, [], [["execute", 0.15]], "INSTANTLY KILLS FOES BELOW 15% HEALTH."],
	["tomahawk", "FEATHERED TOMAHAWK", "spin", "rare", ["swarm"], "axe", { "dmg": 7.0, "rate": 2.1, "speed": 220  }, [], [["kill_wisp", 0.15]], "KILLS HAVE 15% CHANCE TO RAISE A SPIRIT WISP."],
	["ragefang", "RAGEFANG AXE", "spin", "epic", ["blood"], "axe", { "dmg": 11.0, "rate": 1.6  }, [], [["low_hp_dmg", 0.8], ["kill_haste", 2.0]], "+80% DAMAGE WHEN WOUNDED. KILLS GIVE A BURST OF SPEED."],
	["twincrescent", "TWIN CRESCENTS", "spin", "legend", ["arcane"], "sickle", { "dmg": 9.0, "rate": 1.8, "count": 2, "spread": 0.5, "pierce": 4  }, [], [["accel", 1.6]], "THROWS TWO BLADES THAT SPEED UP AS THEY FLY."],
	# --- Scatterguns ---
	["graveshovel", "GRAVE SHOVEL", "shot", "common", [], "shovel", { "life": 0.55  }, [], [], "THE GRAVEDIGGER'S SHOVEL. FLINGS GRAVE DIRT."],
	["blunderbuss", "BLUNDERBUSS", "shot", "common", ["demolition"], "blunderbuss", { "dmg": 2.2, "rate": 1.8, "count": 6, "spread": 0.2, "life": 0.45  }, [], [["close_dmg", 0.5]], "+50% DAMAGE UP CLOSE."],
	["sawnoff", "SAWN-OFF", "shot", "rare", ["blood"], "blunderbuss", { "dmg": 2.6, "rate": 1.6, "count": 7, "spread": 0.24, "life": 0.38  }, [], [["knock", 2.0], ["close_dmg", 0.6]], "BRUTAL UP CLOSE, WITH HUGE KNOCKBACK."],
	["nailspitter", "NAIL SPITTER", "shot", "rare", ["venom"], "handcannon", { "dmg": 1.8, "rate": 2.6, "count": 5, "spread": 0.18  }, [["poison", 1]], [["shred", 0.04]], "RUSTY NAILS POISON AND SHRED: +4% DAMAGE TAKEN PER HIT, UP TO 5."],
	["hailcannon", "HAILSTORM CANNON", "shot", "epic", ["frost"], "handcannon", { "dmg": 2.4, "rate": 2.0, "count": 8, "spread": 0.22  }, [["chill", 0.3]], [["status_dmg", 0.3]], "SPRAYS HAIL. +30% DAMAGE TO FOES WITH ANY AILMENT."],
	["dragonbreath", "DRAGON'S BREATH", "shot", "legend", ["pyre"], "blunderbuss", { "dmg": 2.6, "rate": 2.2, "count": 9, "spread": 0.26  }, [["burn", 0.5]], [["kill_explode", 1.0]], "FIRE SHELLS. FOES IT SLAYS EXPLODE IN FLAME."],
	# --- Flasks ---
	["flasksling", "FLASK SLING", "flask", "common", ["venom"], "flaskw", {  }, [["explode", 1], ["poison", 1]], [], "THE ALCHEMIST'S SLING. POISON FLASKS THAT BURST."],
	["firebottle", "FIREBOTTLE", "flask", "common", ["pyre"], "flaskw", { "dmg": 4.5  }, [["explode", 1], ["burn", 0.3]], [], "BURSTS INTO FLAME."],
	["acidjar", "ACID JAR", "flask", "rare", ["venom"], "flaskw", { "dmg": 4.0, "rate": 2.2  }, [["explode", 1], ["poison", 2]], [["shred", 0.05]], "ACID THAT POISONS AND EATS THROUGH ARMOR."],
	["frostvial", "FROST VIAL", "flask", "rare", ["frost"], "flaskw", { "dmg": 4.4  }, [["explode", 1], ["chill", 0.5]], [], "SHATTERS INTO A CHILLING CLOUD."],
	["bottledstorm", "BOTTLED STORM", "flask", "epic", ["storm"], "flaskw", {  }, [["explode", 1], ["chain", 0.5]], [["nth_zap", 4]], "BURSTS INTO ARCS. EVERY 4TH FLASK CALLS LIGHTNING."],
	["panacea", "PANACEA", "flask", "legend", ["arcane"], "flaskw", { "dmg": 6.0, "rate": 2.2  }, [["explode", 2]], [["leech", 0.03], ["status_dmg", 0.4]], "HUGE BLASTS. 3% OF HITS HEAL. +40% VS AFFLICTED FOES."],
	# --- Boomerangs ---
	["lantern", "WARDEN'S LANTERN", "boomer", "common", [], "lanternw", {  }, [], [], "THE WARDEN'S LANTERN. FLIES OUT AND BACK."],
	["boomerang", "HUNTER'S BOOMERANG", "boomer", "common", ["fortune"], "chakram", { "dmg": 4.0, "rate": 2.2, "size": 1.0  }, [], [["gold_hit", 0.04]], "4% OF HITS SHAKE A COIN LOOSE."],
	["chakram", "ROVING CHAKRAM", "boomer", "rare", ["arcane"], "chakram", { "dmg": 4.2, "rate": 2.2, "speed": 240, "size": 1.0  }, [], [["accel", 1.3], ["mark", 0.15]], "SPEEDS UP AND MARKS FOES (+15% DAMAGE TAKEN)."],
	["reaperhook", "REAPER'S HOOK", "boomer", "rare", ["shadow"], "sickle", { "dmg": 5.0, "rate": 1.9  }, [], [["execute", 0.12], ["kill_roll", 0.5]], "EXECUTES WEAK FOES. KILLS OFTEN REFUND A ROLL."],
	["sunlantern", "SUNLANTERN", "boomer", "epic", ["pyre"], "lanternw", { "dmg": 5.5, "size": 1.5  }, [["burn", 0.4]], [["nth_nova", 4]], "BLAZING. EVERY 4TH THROW SPRAYS FLAME."],
	["moonglaive", "MOONGLAIVE", "boomer", "legend", ["frost"], "chakram", { "dmg": 6.0, "count": 2, "spread": 0.6, "size": 1.3  }, [["chill", 0.35]], [["split", 2]], "TWO FROZEN GLAIVES THAT SPLIT WHEN THEY STRIKE."],
	# --- Swords ---
	["rustblade", "RUSTED BLADE", "slash", "common", [], "sword", {  }, [], [], "A PLAIN SWORD. SWINGS IN AN ARC."],
	["sabre", "DUELIST SABRE", "slash", "common", ["shadow"], "rapier", { "dmg": 6.0, "rate": 2.8  }, [], [["parry", 1]], "QUICK SWINGS THAT CUT SHOTS OUT OF THE AIR."],
	["wandererkatana", "WANDERER'S KATANA", "slash", "rare", ["shadow"], "katana", { "dmg": 8.0, "rate": 2.4, "range": 38  }, [], [["parry", 1], ["first_hit", 0.6]], "+60% DAMAGE TO UNHURT FOES. SWINGS CUT SHOTS."],
	["huntsword", "SILVER HUNTSWORD", "slash", "rare", ["bulwark"], "sword", { "dmg": 8.0  }, [], [["elite_dmg", 0.6], ["status_dmg", 0.2]], "MADE FOR HUNTING MONSTERS. +60% VS ELITES AND GUARDIANS."],
	["gallows", "GALLOWS GREATSWORD", "slash", "epic", ["blood"], "greatsword", { "dmg": 18.0, "rate": 1.0, "range": 48, "arc": 150  }, [], [["knock", 2.2], ["low_hp_dmg", 0.5]], "SLOW, WIDE, CRUSHING SWINGS. +50% DAMAGE WHEN WOUNDED."],
	["cinderbrand", "CINDERBRAND", "slash", "epic", ["pyre"], "sword", { "dmg": 9.0  }, [["burn", 0.5]], [["kill_explode", 0.8]], "A BURNING BLADE. FOES IT SLAYS EXPLODE."],
	["mirrorblade", "MIRRORBLADE", "slash", "legend", ["arcane"], "katana", { "dmg": 9.0, "rate": 2.6  }, [], [["parry", 1], ["reflect", 1]], "SWINGS CATCH ENEMY SHOTS AND HURL THEM BACK."],
	# --- Spears ---
	["pike", "FOOTMAN'S PIKE", "thrust", "common", [], "spear", {  }, [], [], "THRUSTS IN A LINE, PIERCING EVERYTHING."],
	["boarspear", "BOAR SPEAR", "thrust", "common", ["bulwark"], "spear", { "dmg": 7.0, "rate": 2.2  }, [["armor", 1]], [["knock", 1.6]], "+1 ARMOR WHILE HELD. BIG KNOCKBACK."],
	["halberd", "WATCHMAN'S HALBERD", "thrust", "rare", ["bulwark"], "halberd", { "dmg": 9.0, "rate": 1.8, "range": 62, "width": 14  }, [], [["parry", 1]], "A WIDE THRUST THAT BLOCKS SHOTS IN ITS PATH."],
	["tidetrident", "TIDECALLER TRIDENT", "thrust", "rare", ["frost"], "trident", { "dmg": 5.0, "count": 3, "spread": 0.3  }, [["chill", 0.3]], [], "THREE PRONGS, THREE THRUSTS."],
	["serpentlance", "SERPENT LANCE", "thrust", "epic", ["venom"], "spear", { "dmg": 8.0, "range": 66  }, [["poison", 2]], [["pierce_dmg", 0.25]], "EACH FOE PIERCED MAKES THE THRUST 25% STRONGER."],
	["stormspear", "STORMSPEAR", "thrust", "legend", ["storm"], "spear", { "dmg": 10.0, "rate": 2.2, "range": 80  }, [["chain", 0.4]], [["nth_zap", 3]], "LONG REACH. EVERY 3RD THRUST CALLS LIGHTNING."],
	# --- Rays ---
	["prismrod", "PRISM ROD", "beam", "common", ["arcane"], "wand", {  }, [], [], "A STEADY RAY OF LIGHT."],
	["burninglens", "BURNING LENS", "beam", "rare", ["pyre"], "orbstaff", { "dmg": 1.3  }, [["burn", 0.12]], [["still_dmg", 0.4]], "FOCUSED SUNLIGHT. STAND STILL TO BURN HOTTER."],
	["leechrod", "LEECHING ROD", "beam", "rare", ["blood"], "skullstaff", { "dmg": 1.3  }, [], [["leech", 0.006]], "A CRIMSON RAY. NOW AND THEN A HIT HEALS YOU."],
	["winterbreath", "WINTER'S BREATH", "beam", "rare", ["frost"], "wand", { "dmg": 1.2  }, [["chill", 0.1]], [["status_dmg", 0.3]], "AN ICY RAY THAT HITS AFFLICTED FOES HARDER."],
	["voidlight", "VOIDLIGHT", "beam", "epic", ["shadow"], "rune", { "dmg": 1.6, "pierce": 99  }, [], [["mark", 0.2]], "PIERCES EVERY FOE IN LINE AND MARKS THEM."],
	["judgement", "JUDGEMENT RAY", "beam", "legend", ["fortune"], "orbstaff", { "dmg": 2.0, "rate": 11.0, "pierce": 99  }, [], [["gold_dmg", 0.1], ["gold_hit", 0.01]], "+10% DAMAGE PER 100 GOLD. HITS SHAKE OUT COINS."],
	# --- Sprayers ---
	["firespitter", "FIRE SPITTER", "flame", "common", ["pyre"], "handcannon", {  }, [["burn", 0.2]], [], "SPRAYS SHORT GOUTS OF FLAME."],
	["bilesprayer", "BILE SPRAYER", "flame", "rare", ["venom"], "flaskw", { "dmg": 0.9  }, [["poison", 1]], [], "A SPRAY OF CAUSTIC BILE."],
	["frostbellows", "FROST BELLOWS", "flame", "rare", ["frost"], "handcannon", { "dmg": 0.9  }, [["chill", 0.15]], [], "BLOWS FREEZING MIST."],
	["locustcenser", "LOCUST CENSER", "flame", "epic", ["swarm"], "lanternw", {  }, [], [["kill_wisp", 0.12]], "BURNING INCENSE THAT RAISES SPIRITS FROM THE SLAIN."],
	["hellmaw", "HELLMAW", "flame", "epic", ["pyre"], "handcannon", { "dmg": 1.3, "rate": 15.0  }, [["burn", 0.35]], [["close_dmg", 0.5]], "A ROARING FURNACE. +50% DAMAGE UP CLOSE."],
	["phoenixbellows", "PHOENIX BELLOWS", "flame", "legend", ["pyre"], "handcannon", { "dmg": 1.4, "rate": 16.0, "life": 0.5  }, [["burn", 0.5]], [["kill_heal", 0.03], ["kill_explode", 0.6]], "LONGER FLAMES. FOES SLAIN BURST AND SOMETIMES HEAL YOU."],
	# --- Discs ---
	["sawblade", "SAWBLADE", "disc", "common", [], "chakram", {  }, [], [], "A BLADE THAT BOUNCES OFF WALLS."],
	["razordisc", "RAZOR DISC", "disc", "common", ["blood"], "chakram", { "dmg": 3.6, "rate": 2.2  }, [], [["shred", 0.03]], "SHREDS: +3% DAMAGE TAKEN PER HIT, UP TO 5."],
	["doubloon", "LUCKY DOUBLOON", "disc", "rare", ["fortune"], "chakram", { "dmg": 3.4, "rate": 2.4  }, [["ricochet", 2]], [["gold_hit", 0.05]], "JUMPS FROM FOE TO FOE AND SHAKES OUT COINS."],
	["thunderring", "THUNDER RING", "disc", "rare", ["storm"], "chakram", { "dmg": 3.8  }, [["chain", 0.3]], [], "A CRACKLING RING THAT ARCS TO NEARBY FOES."],
	["nightstar", "NIGHT STARS", "disc", "epic", ["shadow"], "rune", { "dmg": 4.5, "rate": 2.4, "count": 3, "spread": 0.5  }, [], [["first_hit", 0.5]], "THREE STARS. +50% DAMAGE TO UNHURT FOES."],
	["worldeater", "WORLD-EATER", "disc", "legend", ["demolition"], "chakram", { "dmg": 6.0, "rate": 1.8, "size": 1.6, "bounce": 6  }, [], [["grow", 0.6], ["crit_explode", 0.5]], "A HUNGRY WHEEL THAT GROWS AS IT FLIES. CRITS EXPLODE."],
	# --- Orbs ---
	["emberorb", "EMBER ORB", "pulse", "common", ["pyre"], "orbstaff", {  }, [["burn", 0.15]], [], "A SLOW ORB THAT SEARS EVERYTHING NEAR IT."],
	["frozenheart", "FROZEN HEART", "pulse", "rare", ["frost"], "orbstaff", {  }, [["chill", 0.3]], [], "A DRIFTING SPHERE OF COLD."],
	["plaguebell", "PLAGUE BELL", "pulse", "rare", ["venom"], "lanternw", { "dmg": 2.6, "rate": 1.0  }, [["poison", 1]], [], "A TOLLING SPHERE THAT POISONS ALL AROUND IT."],
	["gravitywell", "GRAVITY WELL", "pulse", "epic", ["arcane"], "orbstaff", { "dmg": 3.4, "size": 1.6  }, [], [["linger", 2.0]], "THE ORB STOPS AND HOVERS, GRINDING ALL NEARBY."],
	["blacksun", "BLACK SUN", "pulse", "legend", ["shadow"], "orbstaff", { "dmg": 4.2, "size": 1.8  }, [], [["linger", 2.5], ["souls", 0.004]], "A DARK STAR THAT HOVERS AND FEEDS ON EVERY KILL."],
	# --- Runes ---
	["sparkrune", "SPARK RUNE", "zap", "common", ["storm"], "rune", {  }, [], [], "INSTANT ARCS THAT JUMP BETWEEN FOES."],
	["coppercoil", "COPPER COIL", "zap", "rare", ["storm"], "gauntlet", { "dmg": 3.4, "rate": 3.2  }, [], [["nth_zap", 5]], "FASTER ARCS. EVERY 5TH CALLS LIGHTNING."],
	["maledict", "MALEDICTION RUNE", "zap", "rare", ["arcane"], "rune", { "dmg": 3.6, "rate": 2.6  }, [], [["mark", 0.3]], "ARCS THAT MARK FOES (+30% DAMAGE TAKEN)."],
	["stormgauntlet", "STORM GAUNTLET", "zap", "epic", ["storm"], "gauntlet", { "dmg": 4.4, "rate": 2.6, "chain": 4  }, [], [["status_dmg", 0.3]], "ARCS JUMP TO 4 FOES."],
	["heavensrod", "HEAVEN'S ROD", "zap", "legend", ["storm"], "staff", { "dmg": 5.0, "rate": 2.4, "chain": 5  }, [["crit", 0.1]], [["crit_explode", 0.3]], "ARCS TO 5 FOES. +10% CRIT, AND CRITS EXPLODE."],
	# --- Chimes ---
	["bonechime", "BONE CHIME", "nova", "common", [], "lanternw", {  }, [], [], "RINGS OUT A BURST IN EVERY DIRECTION."],
	["frostbloom", "FROST BLOOM", "nova", "rare", ["frost"], "orbstaff", { "dmg": 2.8, "count": 12  }, [["chill", 0.3]], [], "A RING OF ICE SHARDS."],
	["bloodstar", "BLOOD STAR", "nova", "rare", ["blood"], "rune", { "rate": 1.5  }, [], [["low_hp_dmg", 0.6]], "+60% DAMAGE WHEN WOUNDED."],
	["thorntome", "TOME OF THORNS", "nova", "epic", ["venom"], "tome", { "rate": 1.6, "count": 14  }, [["poison", 1]], [], "SPRAYS POISON THORNS ALL AROUND YOU."],
	["cataclysm", "CATACLYSM", "nova", "legend", ["demolition"], "tome", { "dmg": 3.6, "rate": 1.6, "count": 16  }, [], [["kill_explode", 0.8], ["roll_nova", 12]], "HUGE RINGS. FOES EXPLODE. ROLLING FIRES A RING TOO."],
	# --- Traps ---
	["snaremine", "SNARE MINES", "mine", "common", ["demolition"], "minetrap", {  }, [], [], "TOSSES MINES THAT BLOW WHEN FOES COME NEAR."],
	["frosttrap", "FROST TRAP", "mine", "rare", ["frost"], "minetrap", { "dmg": 12.0, "rate": 1.3  }, [["chill", 0.6]], [], "MINES THAT FREEZE THE AREA."],
	["spiketrap", "SPIKE TRAP", "mine", "rare", ["blood"], "minetrap", { "dmg": 16.0, "rate": 1.1  }, [], [["execute", 0.1]], "VICIOUS MINES THAT FINISH OFF WEAK FOES."],
	["hivepod", "HIVE POD", "mine", "epic", ["swarm"], "minetrap", { "dmg": 10.0, "rate": 1.3  }, [], [["kill_wisp", 0.3]], "MINES RAISE SPIRITS FROM WHAT THEY KILL."],
	["doomspring", "DOOMSPRING", "mine", "legend", ["demolition"], "minetrap", { "dmg": 22.0  }, [], [["crit_explode", 1.0], ["kill_explode", 0.8]], "MASSIVE MINES. EXPLOSIONS SPAWN EXPLOSIONS."],
	# --- Railshots ---
	["arbalest", "ARBALEST", "rail", "common", [], "crossbow", {  }, [], [], "A HEAVY BOLT THAT GOES THROUGH EVERYTHING."],
	["harpoon", "WHALING HARPOON", "rail", "rare", ["frost"], "spear", { "dmg": 15.0, "rate": 0.9  }, [["chill", 0.4]], [["knock", 2.5]], "SKEWERS AND SHOVES FOES BACK."],
	["handcannon", "HAND CANNON", "rail", "rare", ["demolition"], "handcannon", { "dmg": 16.0, "rate": 0.85  }, [["crit", 0.1]], [["crit_explode", 0.6]], "+10% CRIT. CRITS EXPLODE."],
	["dawnlance", "LANCE OF DAWN", "rail", "epic", ["arcane"], "rifle", { "dmg": 17.0  }, [], [["nth_nova", 3]], "EVERY 3RD SHOT BURSTS INTO A RING OF LIGHT."],
	["deicide", "DEICIDE", "rail", "legend", ["blood"], "rifle", { "dmg": 25.0, "rate": 0.85  }, [], [["boss_dmg", 0.75], ["execute", 0.2]], "BUILT FOR KILLING GODS. +75% VS GUARDIANS, EXECUTES BELOW 20%."],
	# --- Burst guns ---
	["burstpistol", "THREE-ROUND PISTOL", "burst", "common", [], "pistol", {  }, [], [], "FIRES IN BURSTS OF THREE."],
	["alleysprayer", "ALLEY SPRAYER", "burst", "rare", ["shadow"], "pistol", { "dmg": 2.2, "rate": 2.2, "spread": 0.1  }, [], [["moving_dmg", 0.35]], "+35% DAMAGE WHILE MOVING."],
	["triplecrossbow", "TRIPLE CROSSBOW", "burst", "rare", ["bulwark"], "crossbow", { "dmg": 3.0  }, [["pierce", 1]], [["pierce_dmg", 0.2]], "PIERCING BOLTS THAT GROW STRONGER WITH EACH FOE."],
	["gildedrevolver", "GILDED REVOLVER", "burst", "epic", ["fortune"], "pistol", { "dmg": 3.4, "rate": 1.8  }, [], [["gold_dmg", 0.15], ["gold_hit", 0.03]], "+15% DAMAGE PER 100 GOLD. HITS SHAKE OUT COINS."],
	["hailfire", "HAILFIRE", "burst", "legend", ["storm"], "rifle", { "dmg": 3.4, "rate": 2.0  }, [["count", 1]], [["nth_zap", 4], ["moving_dmg", 0.3]], "DOUBLE BURSTS. LIGHTNING EVERY 4TH. +30% WHILE MOVING."],
	# --- Gatlings ---
	["crankgun", "CRANK GUN", "gatling", "common", ["demolition"], "minigun", {  }, [], [], "SPINS UP TO A HAIL OF SHOTS."],
	["rotarybow", "ROTARY BOW", "gatling", "rare", ["swarm"], "minigun", { "dmg": 1.7  }, [], [["kill_wisp", 0.05]], "A SPINNING BOW. KILLS SOMETIMES RAISE WISPS."],
	["bonegrinder", "BONEGRINDER", "gatling", "rare", ["blood"], "minigun", { "dmg": 2.0  }, [], [["shred", 0.02]], "SHREDS: +2% DAMAGE TAKEN PER HIT, UP TO 5."],
	["sunspitter", "SUNSPITTER", "gatling", "epic", ["pyre"], "minigun", { "dmg": 2.0, "rate": 5.5  }, [["burn", 0.15]], [], "A SPINNING STREAM OF FIRE."],
	["dreadnought", "DREADNOUGHT", "gatling", "legend", ["bulwark"], "minigun", { "dmg": 2.4, "rate": 6.0  }, [["armor", 2]], [["armor_dmg", 0.1]], "+2 ARMOR WHILE HELD. +10% DAMAGE PER ARMOR."],
	# --- Whips ---
	["drovewhip", "DROVER'S WHIP", "whip", "common", [], "whip", {  }, [], [], "A LONG LASH. THE TIP ALWAYS CRITS."],
	["chainlash", "CHAIN LASH", "whip", "rare", ["bulwark"], "whip", { "dmg": 6.0, "rate": 1.9  }, [], [["parry", 1]], "THE CHAIN SWATS SHOTS ASIDE."],
	["bramblewhip", "BRAMBLE WHIP", "whip", "rare", ["venom"], "whip", { "rate": 2.2  }, [["poison", 2]], [], "A THORNY LASH THAT POISONS."],
	["lightninglash", "LIGHTNING LASH", "whip", "epic", ["storm"], "whip", { "dmg": 6.0, "rate": 2.2  }, [["chain", 0.4]], [], "A LASH OF LIGHTNING THAT ARCS."],
	["bloodvine", "BLOODVINE", "whip", "legend", ["blood"], "whip", { "dmg": 7.0, "rate": 2.3, "range": 84  }, [], [["leech", 0.04], ["execute", 0.12]], "LONG REACH. HITS CAN HEAL. EXECUTES WEAK FOES."],
	# --- Callers ---
	["gravebell", "GRAVE BELL", "summon", "common", ["swarm"], "skullstaff", {  }, [], [], "EACH TOLL RAISES A WISP FOR 6 SECONDS (UP TO 4)."],
	["hivestaff", "HIVE STAFF", "summon", "rare", ["swarm"], "staff", { "dmg": 2.2, "rate": 1.0  }, [["fam_rate", 1.3]], [], "WISPS FIRE 30% FASTER."],
	["bonetome", "BONE TOME", "summon", "epic", ["swarm"], "tome", { "dmg": 3.0, "rate": 0.9  }, [["familiars", 1]], [["kill_wisp", 0.2]], "A PERMANENT WISP. KILLS RAISE MORE."],
	["warbanner", "WARBANNER", "summon", "legend", ["swarm"], "halberd", { "dmg": 3.2, "rate": 1.0  }, [["familiars", 2], ["fam_dmg", 0.5]], [], "TWO PERMANENT WISPS THAT HIT 50% HARDER."],
	# ---------- Content batch 1 (Tiny Biggot Rogues) ----------
	["needledirk", "NEEDLE DIRK", "slash", "common", ["edge"], "dagger", { "dmg": 4.0, "rate": 4.0, "range": 26, "arc": 70 }, [["crit", 0.1]], [], "A QUICK DAGGER. +10% CRIT. CRITS SPEED UP YOUR NEXT STABS.", [{ "on": "on_crit", "do": [["buff", "rate", 0.15, 1.0]] }], "w_sabre"],
	["drifterblade", "DRIFTER'S BLADE", "slash", "rare", ["edge"], "katana", { "dmg": 8.0, "rate": 2.6, "range": 40 }, [["crit", 0.08]], [["parry", 1]], "A WANDERER'S SWORD. CUTS SHOTS. EVERY 5TH SWING ADDS A 200% FOLLOW-UP CUT.", [{ "on": "every_n_shots", "every": 5, "do": [["damage", 2.0]] }], "w_wandererkatana"],
	["deadeyebow", "DEADEYE LONGBOW", "bolt", "rare", ["edge"], "bow", { "dmg": 6.0, "rate": 2.2, "speed": 360, "pierce": 1 }, [["crit", 0.15], ["crit_mult", 0.5]], [["far_dmg", 0.3]], "+15% CRIT, CRITS DEAL +0.5X. CRITS ON ELITES MARK THEM.", [{ "on": "on_crit", "if": "elite", "do": [["status", "mark", 1]] }], "w_huntbow"],
	["mirrorshard", "SHARDS OF THE MIRROR", "disc", "epic", ["edge"], "rune", { "dmg": 4.0, "rate": 2.4, "count": 2, "spread": 0.4 }, [["crit", 0.2], ["overcrit", 0.5]], [], "+20% CRIT. CRIT PAST 100% CAN CRIT AGAIN. CRITS SPLINTER INTO 2 MORE SHARDS.", [{ "on": "on_crit", "cd": 0.15, "do": [["shoot", 2, 0.4, "", 0.5]] }], "w_nightstar"],
	["truthseeker", "TRUTHSEEKER", "rail", "legend", ["edge"], "rifle", { "dmg": 20.0, "rate": 0.9 }, [["crit", 0.25]], [], "+25% CRIT. EVERY CRIT DETONATES THE TARGET FOR 100% DAMAGE.", [{ "on": "on_crit", "do": [["explode", 30, 1.0]] }], "w_dawnlance"],
	["flayinghook", "FLAYING HOOK", "whip", "common", ["blood"], "whip", { "dmg": 5.0, "rate": 2.1 }, [], [], "A BARBED LASH. 35% OF HITS MAKE FOES BLEED.", [{ "on": "on_hit", "chance": 0.35, "do": [["status", "bleed", 1]] }], "w_chainlash"],
	["sanguinering", "SANGUINE CHAKRAM", "boomer", "rare", ["blood"], "chakram", { "dmg": 4.6, "rate": 2.2, "size": 1.0 }, [], [], "FLIES OUT AND BACK. HITS BLEED. KILLING A BLEEDING FOE MAY HEAL.", [{ "on": "on_hit", "chance": 0.25, "do": [["status", "bleed", 1]] }, { "on": "on_kill", "chance": 0.2, "if": "bleeding", "do": [["heal", 1]] }], "w_razordisc"],
	["pactknives", "PACT KNIVES", "bolt", "rare", ["blood"], "dagger", { "dmg": 2.6, "rate": 2.6, "count": 3, "spread": 0.2 }, [], [], "EACH ROOM BEGINS WITH A BLOOD PRICE: LOSE HALF A HEART, GAIN +60% DAMAGE FOR 10S.", [{ "on": "on_room_enter", "do": [["hurt_self", 1], ["buff", "dmg", 0.6, 10.0]] }], "w_twincrescent"],
	["hemoclaws", "HEMOCLAWS", "slash", "epic", ["blood"], "fists", { "dmg": 3.6, "rate": 5.0, "range": 22, "arc": 90 }, [], [["leech", 0.02]], "TWIN CLAWS. FAST STRIKES, 20% BLEED, 2% OF HITS HEAL.", [{ "on": "on_hit", "chance": 0.2, "do": [["status", "bleed", 1]] }], "w_bonecleaver"],
	["kindlingstaff", "KINDLING STAFF", "orb", "common", ["pyre"], "wand", { "dmg": 3.8, "rate": 3.2 }, [["burn", 0.15]], [], "BOLTS OFTEN BURN. BURNING FOES IT KILLS BURST INTO EMBERS.", [{ "on": "on_kill", "if": "burning", "do": [["explode", 22, 0.6]] }], "w_emberwand"],
	["magmamaul", "MAGMA MAUL", "slash", "rare", ["pyre"], "hammer", { "dmg": 14.0, "rate": 1.1, "range": 36, "arc": 140 }, [["burn", 0.2]], [["knock", 1.8]], "A MOLTEN HAMMER. EVERY 3RD SWING ERUPTS FOR 120% DAMAGE.", [{ "on": "every_n_shots", "every": 3, "do": [["explode", 30, 1.2]] }], "w_gallows"],
	["flarepistol", "FLARE PISTOL", "burst", "rare", ["pyre"], "pistol", { "dmg": 2.8, "rate": 1.7 }, [["burn", 0.3]], [], "SIGNAL FLARES THAT IGNITE. 15% OF HITS POP IN A SMALL BLAST.", [{ "on": "on_hit", "chance": 0.15, "do": [["explode", 18, 0.5]] }], "w_streetpistol"],
	["sunforge", "SUNFORGE HALO", "nova", "epic", ["pyre"], "orbstaff", { "dmg": 3.2, "rate": 1.5, "count": 12 }, [["burn", 0.35]], [], "A RING OF FIRE AROUND YOU. CRITS BURN TWICE AS LONG.", [{ "on": "on_crit", "do": [["status", "burn", 2]] }], "w_cataclysm"],
	["sporelauncher", "SPORE LAUNCHER", "flask", "common", ["venom"], "flaskw", { "dmg": 4.4 }, [["explode", 1], ["poison", 1]], [], "POISON FLASKS. A POISONED FOE IT KILLS INFECTS THE NEAREST FOE.", [{ "on": "on_kill", "if": "poisoned", "do": [["status", "poison", 3]] }], "w_acidjar"],
	["widowneedles", "WIDOW NEEDLES", "bolt", "rare", ["venom"], "crossbow", { "dmg": 1.6, "rate": 5.5, "count": 2, "spread": 0.1 }, [["poison", 1]], [], "A FLURRY OF THIN NEEDLES THAT POISON. EVERY 10TH NEEDLE WEAKENS.", [{ "on": "every_n_shots", "every": 10, "do": [["status", "weakened", 1]] }], "w_nailspitter"],
	["blightcenser", "BLIGHT CENSER", "pulse", "rare", ["venom"], "lanternw", { "dmg": 2.8, "rate": 1.0 }, [["poison", 2]], [["linger", 1.5]], "A HOVERING CLOUD OF ROT THAT POISONS. FOES THAT DIE POISONED SPREAD IT TO FOES NEAR THEM.", [{ "on": "on_kill", "if": "poisoned", "do": [["status_area", "poison", 2, 60]] }], "w_plaguebell"],
	["serpentspine", "SERPENT SPINE", "whip", "epic", ["venom"], "whip", { "dmg": 6.0, "range": 80 }, [["poison", 2]], [], "A LONG POISON LASH. POISONED FOES IT HITS MAY TURN VULNERABLE.", [{ "on": "on_hit", "chance": 0.25, "if": "poisoned", "do": [["status", "vulnerable", 1]] }], "w_bramblewhip"],
	["sparkingrod", "SPARKING ROD", "zap", "common", ["storm"], "rune", { "dmg": 3.8 }, [], [], "INSTANT ARCS. 25% OF HITS SHOCK: SHOCKED FOES TAKE MORE DAMAGE.", [{ "on": "on_hit", "chance": 0.25, "do": [["status", "shock", 1]] }], "w_sparkrune"],
	["thunderlance", "THUNDER LANCE", "thrust", "rare", ["storm"], "spear", { "dmg": 7.0, "range": 70 }, [["chain", 0.3]], [], "A LONG THRUST THAT ARCS. EVERY 4TH THRUST CALLS LIGHTNING.", [{ "on": "every_n_shots", "every": 4, "do": [["lightning", 1.2]] }], "w_stormspear"],
	["capacitor", "CAPACITOR CANNON", "rail", "epic", ["storm"], "handcannon", { "dmg": 15.0, "rate": 0.9 }, [], [], "EACH HIT SHOCKS TWICE. SHOCKED FOES IT KILLS DISCHARGE INTO OTHERS.", [{ "on": "on_hit", "do": [["status", "shock", 2]] }, { "on": "on_kill", "if": "shocked", "do": [["chain", 0.8]] }], "w_handcannon"],
	["stormbreaker", "STORMBREAKER", "gatling", "legend", ["storm"], "minigun", { "dmg": 2.2, "rate": 5.5 }, [["chain", 0.2]], [], "A SPINNING STORM. EVERY 15TH SHOT CALLS LIGHTNING AND SHOCKS.", [{ "on": "every_n_shots", "every": 15, "do": [["lightning", 1.0], ["status", "shock", 1]] }], "w_crankgun"],
	["scatterwand", "SCATTER WAND", "orb", "common", ["arcane"], "wand", { "dmg": 2.6, "rate": 3.0, "count": 2, "spread": 0.3 }, [], [], "TWO BOLTS PER CAST. EVERY 6TH CAST RELEASES A RING OF 6 SPARKS.", [{ "on": "every_n_shots", "every": 6, "do": [["nova", 6, 0.4, "spark"]] }], "w_witchstaff"],
	["prismbow", "PRISM BOW", "bolt", "rare", ["arcane"], "bow", { "dmg": 3.6, "rate": 3.6, "pierce": 1 }, [], [["split", 2]], "PIERCING ARROWS THAT SPLIT INTO TWO WHEN THEY HIT.", [], "w_thornbow"],
	["orreryblades", "ORRERY OF BLADES", "disc", "epic", ["arcane"], "chakram", { "dmg": 3.8, "count": 3, "spread": 0.5, "bounce": 4 }, [], [["accel", 1.2]], "THREE BLADES THAT BOUNCE AND SPEED UP AS THEY FLY.", [], "w_sawblade"],
	["thousandcuts", "THOUSAND CUTS", "burst", "legend", ["arcane"], "pistol", { "dmg": 2.6, "rate": 1.8, "count": 2 }, [["ricochet", 1]], [], "DOUBLE BURSTS THAT RICOCHET. 25% OF VOLLEYS ADD 2 EXTRA SHOTS.", [{ "on": "on_shoot", "chance": 0.25, "do": [["shoot", 2, 0.5, "spark", 0.3]] }], "w_alleysprayer"],
	["wispcrook", "WISPHERD'S CROOK", "summon", "common", ["swarm"], "staff", { "dmg": 2.4 }, [["fam_rate", 1.15]], [], "EACH SHOT RAISES A WISP FOR 6S. WISPS FIRE 15% FASTER. CLEARING A ROOM RAISES A WISP FOR 30S.", [{ "on": "on_room_clear", "do": [["summon", 30.0]] }], "w_hivestaff"],
	["hivelantern", "HIVE LANTERN", "boomer", "rare", ["swarm"], "lanternw", { "dmg": 4.4 }, [], [], "FLIES OUT AND BACK. 20% OF KILLS RAISE A WISP FOR 6S.", [{ "on": "on_kill", "chance": 0.2, "do": [["summon", 6.0]] }], "w_sunlantern"],
	["bonebell", "BONE BELL", "nova", "rare", ["swarm"], "lanternw", { "dmg": 2.8, "rate": 1.5 }, [], [], "RINGS OUT SHOTS. EVERY 5TH TOLL RAISES A WISP FOR 5S.", [{ "on": "every_n_shots", "every": 5, "do": [["summon", 5.0]] }], "w_bonechime"],
	["courtofshades", "COURT OF SHADES", "summon", "legend", ["swarm"], "skullstaff", { "dmg": 3.0, "rate": 1.0 }, [["familiars", 2], ["fam_dmg", 0.5]], [], "TWO PERMANENT WISPS THAT HIT 50% HARDER. EACH ROOM SUMMONS TWO MORE FOR 8S.", [{ "on": "on_room_enter", "do": [["summon", 8.0], ["summon", 8.0]] }], "w_bonetome"],
	["twinshivs", "TWIN SHIVS", "slash", "common", ["shadow"], "dagger", { "dmg": 3.2, "rate": 4.5, "range": 24, "arc": 80 }, [], [], "QUICK STABS. ROLLING SCATTERS 6 SHIVS AROUND YOU.", [{ "on": "on_roll", "do": [["nova", 6, 0.6, "spark"]] }], "w_reaperhook"],
	["smokebow", "SMOKE BOW", "bolt", "rare", ["shadow"], "bow", { "dmg": 3.6, "rate": 3.6 }, [["roll_speed", 1.1]], [], "ROLLING ERASES ENEMY SHOTS NEAR YOU. ROLLS GO 10% FURTHER.", [{ "on": "on_roll", "do": [["clear_shots", 40]] }], "w_silvercrossbow"],
	["eclipsescythe", "ECLIPSE SCYTHE", "slash", "epic", ["shadow"], "scythe", { "dmg": 10.0, "rate": 1.6, "range": 44, "arc": 200 }, [], [["kill_roll", 0.4]], "A HUGE SWEEP ALL AROUND YOU. KILLS OFTEN REFUND A ROLL.", [], "w_reaperhook"],
	["phantomvolley", "PHANTOM VOLLEY", "disc", "legend", ["shadow"], "rune", { "dmg": 4.4, "rate": 2.0 }, [["dodge_charges", 1], ["charges", 1]], [], "+1 ROLL CHARGE. EVERY ROLL FIRES 4 FULL-POWER DISCS ALONG YOUR AIM.", [{ "on": "on_roll", "do": [["shoot", 4, 1.0, "", 0.3]] }], "w_moonglaive"],
	["towershield", "TOWER SHIELD", "thrust", "common", ["bulwark"], "halberd", { "dmg": 5.0, "rate": 1.8, "range": 30, "width": 16 }, [["armor", 1]], [["parry", 1]], "A SHIELD BASH THAT BLOCKS SHOTS. GRANTS 1 ARMOR. WHEN YOU ARE HIT, IT SWATS AWAY SHOTS NEAR YOU.", [{ "on": "on_damage_taken", "do": [["clear_shots", 60]] }], "w_halberd"],
	["spikedgauntlets", "SPIKED GAUNTLETS", "slash", "rare", ["bulwark"], "fists", { "dmg": 4.0, "rate": 3.6, "range": 22, "arc": 90 }, [["thorns", 10]], [], "+10 THORNS. WHEN YOU ARE HIT, FIRE 10 SPIKES AROUND YOU.", [{ "on": "on_damage_taken", "do": [["nova", 10, 0.8, "spark"]] }], "w_stormgauntlet"],
	["ironwoodstaff", "IRONWOOD STAFF", "orb", "rare", ["bulwark"], "staff", { "dmg": 3.8 }, [], [["armor_dmg", 0.08]], "+8% DAMAGE PER ARMOR. 30% CHANCE TO GAIN 1 ARMOR AFTER EACH ROOM.", [{ "on": "on_room_clear", "chance": 0.3, "do": [["armor", 1]] }], "w_stormcaller"],
	["aegisorb", "AEGIS ORB", "pulse", "epic", ["bulwark"], "orbstaff", { "dmg": 3.6 }, [], [], "WHEN HIT, ERASE NEARBY SHOTS AND GAIN +50% DAMAGE FOR 3S.", [{ "on": "on_damage_taken", "do": [["clear_shots", 60], ["buff", "dmg", 0.5, 3.0]] }], "w_frozenheart"],
	["ragecleaver", "RAGE CLEAVER", "slash", "common", ["fury"], "cleaver", { "dmg": 9.0, "rate": 1.6 }, [], [["low_hp_dmg", 0.4]], "+40% DAMAGE WHEN WOUNDED. KILLS GIVE +20% FIRE RATE FOR 2S.", [{ "on": "on_kill", "do": [["buff", "rate", 0.2, 2.0]] }], "w_ragefang"],
	["graveslab", "GRAVESLAB", "slash", "epic", ["fury"], "greatsword", { "dmg": 20.0, "rate": 0.8, "range": 52, "arc": 160 }, [], [["knock", 2.5]], "AN ABSURDLY LARGE SLAB OF IRON. SLOW, WIDE, CRUSHING. KILLS AT LOW HEALTH MAY HEAL.", [{ "on": "on_kill", "chance": 0.12, "if": "low_hp", "do": [["heal", 1]] }], "w_gallows"],
	["warhornaxe", "WARHORN AXE", "spin", "rare", ["fury"], "axe", { "dmg": 9.0, "rate": 1.7 }, [], [], "WHEN HIT, YOU ROAR: +50% FIRE RATE FOR 4S.", [{ "on": "on_damage_taken", "do": [["buff", "rate", 0.5, 4.0]] }], "w_woodaxe"],
	["frenzychain", "FRENZY CHAIN", "whip", "rare", ["fury"], "whip", { "dmg": 5.5, "rate": 2.2 }, [], [], "BELOW HALF HEALTH: +40% FIRE RATE AND +20% DAMAGE.", [{ "on": "while_low_hp", "do": [["buff", "rate", 0.4, 0], ["buff", "dmg", 0.2, 0]] }], "w_drovewhip"],
	["undyinghatchets", "UNDYING HATCHETS", "spin", "legend", ["fury"], "axe", { "dmg": 9.0, "rate": 1.8, "count": 2, "spread": 0.4 }, [], [], "TWO HATCHETS PER THROW. BELOW HALF HEALTH YOUR DAMAGE DOUBLES.", [{ "on": "while_low_hp", "do": [["buff", "dmg", 1.0, 0]] }], "w_pithatchet"],
	["coincannon", "COIN CANNON", "shot", "common", ["fortune"], "blunderbuss", { "dmg": 2.2, "count": 5 }, [], [["gold_hit", 0.03]], "FIRES A SPRAY OF COINS. HITS SHAKE OUT GOLD AND KILLS PAY 1 GOLD.", [{ "on": "on_kill", "do": [["gold", 1]] }], "w_blunderbuss"],
	["gildedrapier", "GILDED RAPIER", "slash", "rare", ["fortune"], "rapier", { "dmg": 6.0, "rate": 2.8 }, [], [["gold_dmg", 0.1]], "+10% DAMAGE PER 100 GOLD HELD. 10% OF CRITS PAY 3 GOLD.", [{ "on": "on_crit", "chance": 0.1, "do": [["gold", 3]] }], "w_huntsword"],
	["luckydeck", "LUCKY DECK", "disc", "rare", ["fortune"], "rune", { "dmg": 2.0, "rate": 2.1, "count": 3, "spread": 0.25 }, [["crit", 0.1]], [], "THROWS THREE PLAYING CARDS. +10% CRIT. CRITS PAY OUT 1 GOLD.", [{ "on": "on_crit", "do": [["gold", 1]] }], "w_doubloon"],
	["tithescepter", "TITHE SCEPTER", "zap", "legend", ["fortune"], "staff", { "dmg": 4.8, "rate": 2.4, "chain": 3 }, [], [["gold_dmg", 0.2], ["gold_hit", 0.05]], "+20% DAMAGE PER 100 GOLD. ARCS SHAKE OUT COINS. CLEARING A ROOM PAYS 5 GOLD.", [{ "on": "on_room_clear", "do": [["gold", 5]] }], "w_heavensrod"],
	["hexsickle", "HEXBOUND SICKLE", "slash", "common", ["malice"], "sickle", { "dmg": 6.0, "rate": 2.4, "arc": 130 }, [], [], "A WIDE CUT THAT CURSES 30% OF FOES IT HITS (+25% DAMAGE TAKEN).", [{ "on": "on_hit", "chance": 0.3, "do": [["status", "curse", 1]] }], "w_twincrescent"],
	["cursedflintlock", "CURSED FLINTLOCK", "rail", "rare", ["malice"], "rifle", { "dmg": 18.0, "rate": 0.9 }, [["max_hp", -2]], [], "-1 MAX HEART WHILE HELD. CURSED FOES IT HITS TAKE A 50% BONUS SHOT.", [{ "on": "on_hit", "if": "cursed", "do": [["damage", 0.5]] }], "w_longrifle"],
	["weepingstaff", "WEEPING IDOL STAFF", "orb", "epic", ["malice"], "skullstaff", { "dmg": 4.2 }, [], [], "+60% DAMAGE. 5% OF CASTS DRAW HALF A HEART OF YOUR BLOOD.", [["pct", "dmg", 0.6], { "on": "on_shoot", "chance": 0.05, "do": [["hurt_self", 1]] }], "w_soulstaff"],
	["doombell", "DOOMSAYER'S KNELL", "nova", "legend", ["malice"], "tome", { "dmg": 3.4, "rate": 1.5, "count": 14 }, [], [], "40% OF HITS CURSE. CURSED FOES IT KILLS EXPLODE FOR 150% DAMAGE.", [{ "on": "on_hit", "chance": 0.4, "do": [["status", "curse", 1]] }, { "on": "on_kill", "if": "cursed", "do": [["explode", 40, 1.5]] }], "w_thorntome"],
	["juggler", "JUGGLER'S PINS", "spin", "rare", ["arcane", "fortune"], "axe", { "dmg": 3.6, "rate": 1.8, "count": 3, "spread": 0.35 }, [], [["accel", 1.15]], "THREE SPINNING PINS THAT SPEED UP. EVERY 8TH THROW TOSSES A RING OF 8.", [{ "on": "every_n_shots", "every": 8, "do": [["nova", 8, 0.5, ""]] }], "w_tomahawk"],
	["bannerpike", "RALLYING PIKE", "thrust", "epic", ["swarm", "bulwark"], "halberd", { "dmg": 7.0, "range": 64 }, [["familiars", 1]], [], "A WISP FOLLOWS YOU. CLEARING A ROOM RAISES TWO WISPS FOR 10S.", [{ "on": "on_room_clear", "do": [["summon", 10.0], ["summon", 10.0]] }], "w_warbanner"],
	# ---------- Hero signature weapons (design spec step 6; never in loot pools) ----------
	["banesabre", "BANE SABRE", "slash", "rare", ["edge"], "katana", { "dmg": 8.0, "rate": 2.6, "range": 36, "arc": 110 }, [["crit", 0.05]], [], "A HUNTER'S SILVERED SABRE. +5% CRIT.", [], "w_huntsword"],
	["ironslab", "IRON SLAB", "slash", "rare", ["fury"], "hammer", { "dmg": 16.0, "rate": 0.9, "range": 46, "arc": 170 }, [], [["knock", 2.2]], "FAR TOO BIG TO BE A SWORD. SLOW, WIDE AND BRUTAL. HITS KNOCK FOES BACK.", [], "w_gallows"],
	["wayfareredge", "WAYFARER'S EDGE", "slash", "rare", ["edge"], "katana", { "dmg": 6.0, "rate": 3.0, "range": 38, "arc": 80 }, [["crit", 0.05]], [["parry", 1]], "A QUICK, NARROW CUT THAT ALSO SLICES SHOTS OUT OF THE AIR.", [], "w_wandererkatana"],
	["snubguns", "SNUB GUNS", "burst", "rare", ["fortune"], "pistol", { "dmg": 2.4, "rate": 2.0, "count": 2, "spread": 0.12 }, [], [], "TWO SHORT GUNS FIRED TOGETHER. KILLS HAVE 15% CHANCE TO DROP A COIN.", [{ "on": "on_kill", "chance": 0.15, "do": [["drop", "coin"]] }], "w_streetpistol"],
	["shackleflail", "SHACKLE FLAIL", "whip", "rare", ["malice"], "whip", { "dmg": 5.5, "rate": 2.0, "range": 64 }, [], [], "A LENGTH OF PRISON CHAIN WITH THE LOCK STILL ON.", [], "w_chainlash"],
	["giltdeck", "GILT DECK", "disc", "rare", ["arcane"], "rune", { "dmg": 3.0, "rate": 2.6, "count": 3, "spread": 0.3 }, [], [], "THROWS THREE SHARPENED CARDS THAT BOUNCE OFF WALLS.", [], "w_doubloon"],
	["warlance", "WAR LANCE", "thrust", "rare", ["bulwark"], "halberd", { "dmg": 7.5, "rate": 2.0, "range": 66 }, [], [], "A LONG CAVALRY LANCE THAT PIERCES A WHOLE LINE.", [], "w_halberd"],
	["irontalons", "IRON TALONS", "slash", "rare", ["shadow", "edge"], "dagger", { "dmg": 3.6, "rate": 3.6, "range": 30, "arc": 120 }, [["crit", 0.05]], [], "TWO HOOKS FILED FROM CELL BARS. +5% CRIT. EVERY 3RD STRIKE IS A SPINNING FINISHER: 150% TO EVERY FOE AROUND YOU.", [{ "on": "every_n_shots", "every": 3, "do": [["area", 38, 1.5], ["vfx", "spin", "#e86fb4", 0.24], ["vfx", "ring", "#f4ecd8", 38]] }]],
	# ---------- Content batch 2 (step 8): weapons ----------
	["bogpump", "BOG PUMP", "flame", "common", ["venom"], "sprayer", { "dmg": 1.1, "rate": 12.0 }, [["poison", 1]], [], "SPRAYS STINKING MIRE WATER THAT POISONS. KILLS LEAVE A POOL OF BOG WATER.", [{ "on": "on_kill", "do": [["zone", "poison", 26, 3.0]] }], "w_bilesprayer"],
	["leechlance", "LEECHING LANCE", "thrust", "rare", ["blood"], "halberd", { "dmg": 6.5, "range": 64 }, [], [["leech", 0.02], ["status_dmg", 0.3]], "A HOLLOW LANCE THAT DRINKS. 2% OF HITS HEAL. +30% DAMAGE TO AFFLICTED FOES.", [], "w_serpentlance"],
	["frogspawn", "FROGSPAWN SATCHEL", "mine", "common", ["venom", "swarm"], "mine", { "dmg": 10.0 }, [["poison", 1]], [], "TOSSES EGG CLUSTERS THAT BURST. 15% OF KILLS HATCH A WISP FOR 4S.", [{ "on": "on_kill", "chance": 0.15, "do": [["summon", 4.0]] }], "w_snaremine"],
	["witchlight", "WITCH-LIGHT LANTERN", "pulse", "rare", ["arcane", "venom"], "lanternw", { "dmg": 3.4 }, [["poison", 1]], [], "A SLOW GREEN LIGHT THAT POISONS ALL IT TOUCHES. EVERY 3RD LIGHT ALSO THROWS 4 SPARKS.", [{ "on": "every_n_shots", "every": 3, "do": [["shoot", 4, 0.5, "spark", 0.4]] }], "w_voidlight"],
	["rainmaker", "RAINMAKER'S ROD", "zap", "epic", ["storm"], "staff", { "dmg": 4.6, "chain": 3 }, [], [], "ARCS JUMP 3 TIMES. IN A FIGHT, CALLS LIGHTNING EVERY 3 SECONDS.", [{ "on": "every_n_seconds", "period": 3.0, "if": "fighting", "do": [["lightning", 1.2]] }], "w_stormcaller"],
	["warbow", "WARBOW", "bolt", "common", ["edge"], "bow", { "dmg": 5.0, "rate": 2.6, "speed": 320, "pierce": 1 }, [["crit", 0.05]], [], "A HEAVY BOW: +5% CRIT, ARROWS PIERCE ONE FOE. STANDING STILL STEADIES YOUR AIM: +20% MORE.", [{ "on": "on_shoot", "if": "still", "cd": 0.4, "do": [["buff", "crit", 0.2, 0.45]] }], "w_huntbow"],
	["volleybow", "VOLLEY BOW", "bolt", "rare", ["arcane"], "bow", { "dmg": 2.2, "rate": 1.8, "count": 5, "spread": 0.12 }, [], [], "LOOSES FIVE ARROWS IN A TIGHT FAN.", [], "w_triplecrossbow"],
	["firepot", "FIREPOT SLING", "flask", "common", ["pyre"], "flaskw", { "dmg": 5.5 }, [["burn", 0.25]], [], "THROWS CLAY POTS OF PITCH. 25% BURN CHANCE. 25% OF POTS LEAVE BURNING PITCH ON THE FLOOR.", [{ "on": "on_hit", "chance": 0.25, "cd": 0.4, "do": [["zone", "fire", 22, 2.5]] }], "w_firebottle"],
	["siegearbalest", "SIEGE ARBALEST", "rail", "rare", ["bulwark"], "crossbow", { "dmg": 18.0, "rate": 0.7 }, [], [["knock", 2.5]], "SLOW, CRUSHING BOLTS THAT HURL FOES BACK. CLEARING A ROOM GIVES 1 ARMOR.", [{ "on": "on_room_clear", "do": [["armor", 1]] }], "w_arbalest"],
	["bannermaul", "BANNER MAUL", "slash", "epic", ["fury", "bulwark"], "hammer", { "dmg": 13.0, "rate": 1.1, "range": 40, "arc": 150 }, [["full_hp_dmg", 0.25]], [], "+25% DAMAGE AT FULL HEALTH. EVERY KILL GIVES +10% FIRE RATE FOR 3S.", [{ "on": "on_kill", "do": [["buff", "rate", 0.1, 3.0]] }], "w_warbanner"],
	["cinderwhip", "CINDER WHIP", "whip", "rare", ["pyre"], "whip", { "dmg": 5.0, "range": 72 }, [["burn", 0.3]], [], "THE TIP SETS FOES ALIGHT. BURNING FOES YOU KILL EXPLODE FOR 80%.", [{ "on": "on_kill", "if": "burning", "do": [["explode", 26, 0.8]] }], "w_bloodvine"],
	["scorchcannon", "SCORCH CANNON", "gatling", "epic", ["pyre"], "minigun", { "dmg": 1.6, "rate": 5.5 }, [["burn", 0.12]], [], "SPINS UP INTO A STREAM OF EMBERS. EVERY 20TH SHOT IS A BURSTING FIREBALL.", [{ "on": "every_n_shots", "every": 20, "do": [["shoot", 1, 3.0, "flask", 0.0]] }], "w_hellmaw"],
	["ironpike", "IRON PIKE", "thrust", "common", ["bulwark"], "halberd", { "dmg": 7.0, "range": 74, "width": 10 }, [["armor", 1]], [], "A LONG, WIDE PIKE. GRANTS 1 ARMOR. WHEN YOU ARE HIT, YOU SHOVE FOES AWAY.", [{ "on": "on_damage_taken", "do": [["push", 70, 280]] }], "w_pike"],
	["prayerbeads", "PRAYER BEADS", "nova", "rare", ["arcane"], "orbstaff", { "dmg": 2.6, "count": 14 }, [], [], "A RING OF 14 BEADS. ROLLING CASTS AN EXTRA RING OF 10.", [{ "on": "on_roll", "cd": 1.0, "do": [["nova", 10, 0.6, "spark"]] }], "w_thunderring"],
	["frostfang", "FROSTBITE FANG", "slash", "common", ["frost"], "dagger", { "dmg": 5.0, "rate": 3.2, "range": 28, "arc": 90 }, [["chill", 0.25], ["vs_chill", 0.2]], [], "QUICK CUTS. CHILLED FOES TAKE +20%. CRITS SHATTER FROST: FOES NEAR THE TARGET ARE CHILLED.", [{ "on": "on_crit", "cd": 0.3, "do": [["status_area", "chill", 1, 40]] }], "w_mirrorblade"],
	["avalanche", "AVALANCHE STAFF", "orb", "epic", ["frost"], "staff", { "dmg": 5.0, "rate": 2.0, "size": 1.6 }, [["chill", 0.35]], [], "HUGE, SLOW SNOWBALLS. A CHILLED FOE YOU KILL BURSTS, HITTING ALL AROUND IT.", [{ "on": "on_kill", "if": "chilled", "do": [["explode", 30, 1.0]] }], "w_winterbreath"],
	["quarterstaff", "MONK'S QUARTERSTAFF", "thrust", "rare", ["shadow"], "halberd", { "dmg": 6.0, "rate": 2.8, "range": 50, "width": 12 }, [], [], "A BROAD SWEEPING STAFF. ROLLING GIVES +40% DAMAGE FOR 2S.", [{ "on": "on_roll", "do": [["buff", "dmg", 0.4, 2.0]] }], "w_pike"],
	["templebell", "TEMPLE BELL", "pulse", "rare", ["bulwark"], "lanternw", { "dmg": 4.0, "rate": 0.8, "size": 1.8 }, [], [], "A BIG, SLOW TOLL. WHEN YOU ARE HIT IT RINGS: 12 SHOTS AROUND YOU.", [{ "on": "on_damage_taken", "do": [["nova", 12, 0.8, "spark"]] }], "w_gravebell"],
	["iciclerepeater", "ICICLE REPEATER", "bolt", "common", ["frost"], "crossbow", { "dmg": 2.2, "rate": 5.0, "speed": 300 }, [["chill", 0.15]], [], "RAPID SHARDS OF ICE. 15% CHILL. CHILLED FOES SHATTER INTO 6 ICE SHARDS WHEN THEY DIE.", [{ "on": "on_kill", "if": "chilled", "do": [["nova", 6, 0.5, "spark"]] }], "w_hailfire"],
	["stillwater", "BLADE OF STILL WATER", "slash", "legend", ["edge", "shadow"], "katana", { "dmg": 9.0, "rate": 2.4, "range": 40 }, [["crit", 0.15]], [], "+15% CRIT. STANDING STILL, HITS STRIKE AGAIN FOR 50%. ROLLING PAST A CLOSE SHOT GIVES +100% DAMAGE FOR 2S.", [{ "on": "on_hit", "cd": 0.15, "if": "still", "do": [["damage", 0.5]] }, { "on": "on_roll", "if": "danger", "do": [["buff", "dmg", 1.0, 2.0]] }], "w_rustblade"],
	["sixshooter", "SIX-SHOOTER", "burst", "common", ["edge"], "pistol", { "dmg": 3.2, "rate": 1.8, "count": 1 }, [["crit", 0.08]], [], "+8% CRIT. EVERY 6TH SHOT ADDS A SLUG FOR 300% TO THE NEAREST FOE.", [{ "on": "every_n_shots", "every": 6, "do": [["damage", 3.0]] }], "w_gildedrevolver"],
	["alleyscatter", "ALLEY SCATTERGUN", "shot", "common", ["fury"], "shotgun", { "dmg": 2.6, "count": 6, "spread": 0.22 }, [], [], "SIX PELLETS AT ONCE. DEVASTATING UP CLOSE.", [], "w_sawnoff"],
	["throwknives", "THROWING KNIVES", "bolt", "rare", ["shadow", "edge"], "dagger", { "dmg": 2.6, "rate": 3.6, "count": 2, "spread": 0.15 }, [["crit", 0.1]], [["kill_roll", 1]], "PAIRS OF KNIVES. +10% CRIT. KILLS REFUND A ROLL.", [], "w_nailspitter"],
	["drumgun", "DRUM GUN", "gatling", "rare", ["fortune"], "minigun", { "dmg": 1.7, "rate": 6.0 }, [], [], "A CHATTERING STREET GUN. 10% OF KILLS DROP A COIN.", [{ "on": "on_kill", "chance": 0.1, "do": [["drop", "coin"]] }], "w_crankgun"],
	["grapnel", "GRAPPLING HOOK", "whip", "rare", ["shadow"], "whip", { "dmg": 5.5, "range": 92 }, [], [], "A VERY LONG REACH. 30% OF HITS MARK THE FOE: MARKED FOES TAKE MORE DAMAGE.", [{ "on": "on_hit", "chance": 0.3, "do": [["status", "mark", 1]] }], "w_harpoon"],
	["smokecharges", "SMOKE CHARGES", "mine", "rare", ["shadow"], "mine", { "dmg": 12.0 }, [], [], "TRAPS THAT BURST. ROLLING ERASES SHOTS AROUND YOU (EVERY 4S).", [{ "on": "on_roll", "cd": 4.0, "do": [["clear_shots", 40]] }], "w_spiketrap"],
	["goldengun", "GOLDEN GUN", "rail", "legend", ["fortune", "edge"], "rifle", { "dmg": 30.0, "rate": 0.6 }, [["crit", 0.2]], [["gold_dmg", 0.1]], "ONE SHOT, ONE KILL. +20% CRIT. KILLS PAY 3 GOLD. +10% DAMAGE PER 100 GOLD.", [{ "on": "on_kill", "do": [["gold", 3]] }], "w_sunpiercer"],
	["crowcaller", "CROWCALLER", "summon", "rare", ["swarm"], "skullstaff", { "dmg": 2.8, "rate": 1.0 }, [], [], "EACH SHOT RAISES A CROW-SPIRIT. 20% OF KILLS CALL ANOTHER FOR 5S.", [{ "on": "on_kill", "chance": 0.2, "do": [["summon", 5.0]] }], "w_gravitywell"],
	["lampflamer", "STREETLAMP FLAMER", "flame", "rare", ["pyre"], "sprayer", { "dmg": 1.2, "rate": 13.0 }, [["burn", 0.2], ["vs_burn", 0.25]], [], "A SHORT, HOT CONE. BURNING FOES TAKE +25%. HITTING A BURNING FOE CAN BLOW IT UP (8%).", [{ "on": "on_hit", "if": "burning", "chance": 0.08, "do": [["explode", 24, 0.8]] }], "w_phoenixbellows"],
	["voidray", "VOID RAY", "beam", "epic", ["malice", "arcane"], "staff", { "dmg": 1.8 }, [], [], "A CONSTANT DARK RAY. 10% OF HITS CURSE AND WEAKEN THE FOE.", [{ "on": "on_hit", "chance": 0.1, "do": [["status", "curse", 1], ["status", "weakened", 1]] }], "w_blacksun"],
	["eclipseorb", "ECLIPSE ORB", "pulse", "legend", ["malice", "storm"], "orbstaff", { "dmg": 5.0, "size": 1.8 }, [], [], "A SLOW BLACK SUN THAT HURTS ALL IT TOUCHES. EVERY KILL CALLS LIGHTNING ON ANOTHER FOE.", [{ "on": "on_kill", "do": [["lightning", 1.0]] }], "w_worldeater"],
	["umbralscythe", "UMBRAL SCYTHE", "slash", "rare", ["malice", "blood"], "scythe", { "dmg": 9.0, "rate": 1.6, "range": 42, "arc": 180 }, [["curse", 0.1]], [], "A HUGE SWEEP. 10% OF HITS CURSE. KILLING A CURSED FOE MAY HEAL HALF A HEART.", [{ "on": "on_kill", "chance": 0.25, "if": "cursed", "do": [["heal", 1]] }], "w_reaperhook"],
	["starfall", "STARFALL CHIME", "nova", "epic", ["arcane", "storm"], "orbstaff", { "dmg": 3.0, "count": 12 }, [], [], "A RING OF 12. EVERY 4TH CHIME ARCS LIGHTNING THROUGH NEARBY FOES.", [{ "on": "every_n_shots", "every": 4, "do": [["chain", 1.0]] }], "w_laststar"],
	["hexchain", "HEX CHAIN", "whip", "common", ["malice"], "whip", { "dmg": 4.5 }, [["curse", 0.15]], [], "15% OF HITS CURSE. LASHING A CURSED FOE ARCS THE HEX TO ANOTHER FOE.", [{ "on": "on_hit", "if": "cursed", "do": [["chain", 0.5]] }], "w_lightninglash"],
	["riftcannon", "RIFT CANNON", "rail", "epic", ["arcane"], "rifle", { "dmg": 16.0, "rate": 0.9 }, [], [], "EACH HIT TEARS A SMALL RIFT THAT BLASTS EVERYTHING NEAR THE FOE.", [{ "on": "on_hit", "cd": 0.1, "do": [["explode", 22, 0.6]] }], "w_judgement"],
	["bloodletter", "BLOODLETTER", "disc", "rare", ["blood"], "rune", { "dmg": 3.8, "bounce": 4 }, [], [], "DISCS THAT BOUNCE 4 TIMES. 25% OF HITS BLEED.", [{ "on": "on_hit", "chance": 0.25, "do": [["status", "bleed", 1]] }], "w_chakram"],
	["bonesaw", "BONE SAW", "spin", "common", ["blood"], "axe", { "dmg": 7.0, "pierce": 3 }, [], [], "A SPINNING SAW THAT CUTS THROUGH THREE FOES.", [], "w_sawblade"],
	["nightwing", "NIGHT-WING STAFF", "summon", "epic", ["swarm", "blood"], "skullstaff", { "dmg": 3.0, "rate": 1.1 }, [["familiars", 1]], [], "EACH SHOT RAISES A SPIRIT. +1 WISP. 5% OF KILLS HEAL HALF A HEART.", [{ "on": "on_kill", "chance": 0.05, "do": [["heal", 1]] }], "w_leechrod"],
	["hivecannon", "HIVE CANNON", "flask", "epic", ["swarm", "venom"], "flaskw", { "dmg": 6.0 }, [["poison", 1]], [], "LOBS HIVES THAT BURST AND POISON. 30% OF HITS RELEASE A WISP FOR 4S.", [{ "on": "on_hit", "chance": 0.3, "do": [["summon", 4.0]] }], "w_hivepod"],
	["shieldcannon", "SHIELD CANNON", "rail", "epic", ["bulwark"], "handcannon", { "dmg": 12.0, "rate": 1.0 }, [["armor", 2]], [], "GRANTS 2 ARMOR. WHEN YOU ARE HIT, FIRE A RING OF 12 SHOTS.", [{ "on": "on_damage_taken", "do": [["nova", 12, 1.0, "spark"]] }], "w_dreadnought"],
	["briarspear", "BRIAR SPEAR", "thrust", "rare", ["bulwark", "venom"], "halberd", { "dmg": 6.0, "range": 60 }, [["thorns", 15], ["poison", 1]], [], "+15 THORNS. THRUSTS POISON. ROLLING TEARS FOES NEAR YOU WITH BRIARS: THEY BLEED.", [{ "on": "on_roll", "cd": 1.0, "do": [["status_area", "bleed", 1, 50]] }], "w_boarspear"],
	["tumbleredge", "TUMBLER'S EDGE", "slash", "common", ["shadow"], "dagger", { "dmg": 5.5, "rate": 3.0, "range": 30 }, [], [], "QUICK CUTS. AFTER A ROLL YOUR CUTS GET +50% CRIT FOR 1S.", [{ "on": "on_roll", "cd": 1.0, "do": [["buff", "crit", 0.5, 1.0]] }], "w_sabre"],
	["phantombow", "PHANTOM BOW", "bolt", "epic", ["shadow", "arcane"], "bow", { "dmg": 4.0, "rate": 3.0, "homing": 2.0 }, [], [], "HOMING GHOST ARROWS. AFTER A ROLL, +50% DAMAGE FOR 2S.", [{ "on": "on_roll", "do": [["buff", "dmg", 0.5, 2.0]] }], "w_rotarybow"],
	["skullsplitter", "SKULLSPLITTER", "spin", "rare", ["fury"], "axe", { "dmg": 10.0, "rate": 1.4 }, [], [], "HEAVY AXES. BELOW HALF HEALTH THEY FLY 40% FASTER.", [{ "on": "while_low_hp", "do": [["buff", "rate", 0.4, 0]] }], "w_bonegrinder"],
	["wrathbuss", "WRATH BLUNDERBUSS", "shot", "epic", ["fury"], "shotgun", { "dmg": 3.0, "count": 7, "spread": 0.3 }, [], [], "SEVEN PELLETS. TAKING A HIT GIVES +50% DAMAGE FOR 4S.", [{ "on": "on_damage_taken", "do": [["buff", "dmg", 0.5, 4.0]] }], "w_blunderbuss"],
	["flippedcoin", "FLIPPED COIN", "disc", "common", ["fortune"], "rune", { "dmg": 3.0 }, [["luck", 1]], [], "+1 LUCK. HALF OF YOUR CRITS PAY 1 GOLD.", [{ "on": "on_crit", "chance": 0.5, "do": [["gold", 1]] }], "w_doubloon"],
	["taxbell", "TAXMAN'S BELL", "nova", "rare", ["fortune"], "orbstaff", { "dmg": 2.8, "count": 10 }, [], [], "A RING OF 10. CLEARING A ROOM PAYS 4 GOLD. ELITE KILLS PAY 6.", [{ "on": "on_room_clear", "do": [["gold", 4]] }, { "on": "on_kill", "if": "elite", "do": [["gold", 6]] }], "w_bonechime"],
	["thornidol", "IDOL OF THORNS", "orb", "rare", ["malice", "bulwark"], "staff", { "dmg": 4.2 }, [["thorns", 10]], [], "+10 THORNS. EACH ROOM COSTS HALF A HEART AND GIVES +40% DAMAGE FOR 15S.", [{ "on": "on_room_enter", "do": [["hurt_self", 1], ["buff", "dmg", 0.4, 15.0]] }], "w_thorntome"],
	["arcsprayer", "ARC SPRAYER", "flame", "epic", ["storm"], "sprayer", { "dmg": 1.0, "rate": 14.0 }, [["chain", 0.15]], [], "A HISSING CONE OF SPARKS. 15% ARC CHANCE. SOME HITS SHOCK.", [{ "on": "on_hit", "chance": 0.04, "do": [["status", "shock", 1]] }], "w_coppercoil"],
	["thunderdrum", "THUNDER DRUM", "pulse", "legend", ["storm", "fury"], "lanternw", { "dmg": 5.0, "rate": 1.0, "size": 1.6 }, [], [], "EVERY HIT SHOCKS. SHOCKED FOES YOU KILL ERUPT INTO 8 SPARKS.", [{ "on": "on_hit", "cd": 0.1, "do": [["status", "shock", 1]] }, { "on": "on_kill", "if": "shocked", "do": [["nova", 8, 0.6, "spark"]] }], "w_bottledstorm"],
	["powdermortar", "POWDER MORTAR", "flask", "rare", ["demolition"], "flaskw", { "dmg": 7.0, "size": 1.3 }, [["bomb_r", 1.25]], [], "BIG BURSTING SHELLS. +25% BOMB RADIUS. 5% OF KILLS DROP A BOMB.", [{ "on": "on_kill", "chance": 0.05, "do": [["drop", "bomb"]] }], "w_hailcannon"],
	["deadfall", "DEADFALL TRAPS", "mine", "epic", ["demolition", "bulwark"], "mine", { "dmg": 12.0 }, [], [], "HEAVY TRAPS. WHEN YOU ARE HIT, GAIN A BOMB (EVERY 8S).", [{ "on": "on_damage_taken", "cd": 8.0, "do": [["drop", "bomb"]] }], "w_frosttrap"],
	# ---------- Content batch 4 (chaos): weapons ----------
	["whimsywand", "WAND OF WHIMSY", "orb", "rare", ["arcane", "fortune"], "wand", { "dmg": 3.8, "rate": 3.2 }, [], [], "EVERY 10TH CAST DOES SOMETHING RANDOM: METEORS, COINS, STORMS, GIANT SHOTS AND MORE.", [{ "on": "every_n_shots", "every": 10, "do": [["chaos"]] }]],
	["meteorstaff", "METEOR STAFF", "orb", "epic", ["pyre"], "staff", { "dmg": 4.4, "rate": 2.8 }, [["burn", 0.2]], [], "BOLTS OFTEN BURN. EVERY 4TH CAST CALLS A METEOR DOWN ON A RANDOM FOE FOR 250%.", [{ "on": "every_n_shots", "every": 4, "do": [["meteor", 2.5, 32]] }]],
	["singularity", "SINGULARITY CANNON", "rail", "legend", ["arcane", "shadow"], "handcannon", { "dmg": 18.0, "rate": 0.8 }, [], [], "EACH SHOT TEARS A HOLE IN THE WORLD: FOES NEAR THE TARGET ARE DRAGGED IN AND BLASTED FOR 80%.", [{ "on": "on_hit", "cd": 0.5, "do": [["pull", 90, 260], ["explode", 34, 0.8]] }]],
	["gravitymaul", "GRAVITY MAUL", "slash", "epic", ["bulwark", "arcane"], "hammer", { "dmg": 13.0, "rate": 1.1, "range": 40, "arc": 150 }, [], [["knock", 1.5]], "EVERY 3RD SWING DRAGS ALL NEARBY FOES TO YOU, THEN ERUPTS FOR 150%.", [{ "on": "every_n_shots", "every": 3, "do": [["pull", 110, 240], ["explode", 46, 1.5]] }]],
	["beehive", "ANGRY BEEHIVE", "gatling", "rare", ["swarm", "venom"], "minigun", { "dmg": 1.3, "rate": 5.5, "homing": 3.0, "speed": 200 }, [["poison", 1]], [], "SPITS HOMING BEES THAT POISON. 15% OF KILLS HATCH A WISP FOR 5S.", [{ "on": "on_kill", "chance": 0.15, "do": [["summon", 5.0]] }]],
	["midascannon", "MIDAS CANNON", "shot", "epic", ["fortune"], "blunderbuss", { "dmg": 2.4, "count": 6, "spread": 0.2 }, [], [["gold_hit", 0.03]], "A SPRAY OF GOLD DUST. 5% OF HITS TURN AN ORDINARY FOE INTO A PILE OF COINS.", [{ "on": "on_hit", "chance": 0.05, "cd": 0.3, "do": [["transmute", 3]] }]],
	["discoball", "DISCO BALL", "pulse", "epic", ["arcane", "storm"], "orbstaff", { "dmg": 3.6, "size": 1.5 }, [], [["linger", 1.5]], "A GLITTERING ORB THAT HOVERS. EVERY HIT INFLICTS A RANDOM AILMENT. EACH CAST SPINS OUT 8 SPARKS.", [{ "on": "on_hit", "cd": 0.1, "do": [["rand_status", 1]] }, { "on": "on_shoot", "do": [["nova", 8, 0.4, "spark", 2.0]] }]],
	["boomstick", "BOOMSTICK", "shot", "rare", ["demolition"], "shotgun", { "dmg": 2.6, "count": 6, "spread": 0.22, "life": 0.45 }, [], [["close_dmg", 0.3]], "+30% DAMAGE UP CLOSE. FOES IT KILLS LEAVE A LIT BOMB 25% OF THE TIME (HARMLESS TO YOU).", [{ "on": "on_kill", "chance": 0.25, "do": [["bomb", 0.5]] }]],
	["razoryoyo", "RAZOR YO-YO", "boomer", "common", ["edge"], "chakram", { "dmg": 4.2, "rate": 2.3, "size": 1.0 }, [["crit", 0.08]], [], "FLIES OUT AND BACK. +8% CRIT. CRITS MAKE YOUR SHOTS 30% BIGGER FOR 3S.", [{ "on": "on_crit", "cd": 0.5, "do": [["buff", "size", 0.3, 3.0]] }]],
	["pinball", "PINBALL CANNON", "disc", "epic", ["fortune", "storm"], "handcannon", { "dmg": 4.0, "rate": 2.0, "bounce": 8 }, [["ricochet", 2]], [], "DISCS BOUNCE 8 TIMES AND JUMP BETWEEN FOES. EVERY HIT GIVES +4% FIRE RATE FOR 2S.", [{ "on": "on_hit", "cd": 0.05, "do": [["buff", "rate", 0.04, 2.0]] }]],
	["teslacoil", "TESLA COIL", "zap", "legend", ["storm"], "gauntlet", { "dmg": 4.6, "rate": 2.6, "chain": 6 }, [], [], "ARCS TO 6 FOES. EVERY KILL CALLS 2 LIGHTNING BOLTS DOWN ON RANDOM FOES.", [{ "on": "on_kill", "cd": 0.25, "do": [["bolts", 2, 1.0]] }]],
	["volcano", "POCKET VOLCANO", "flask", "legend", ["pyre", "demolition"], "flaskw", { "dmg": 6.5, "rate": 2.0, "size": 1.3 }, [["explode", 2], ["burn", 0.4]], [], "HUGE BURNING BLASTS THAT LEAVE POOLS OF FIRE. EVERY 5TH THROW RAINS 3 METEORS.", [{ "on": "on_hit", "cd": 0.3, "do": [["zone", "fire", 16, 3.0]] }, { "on": "every_n_shots", "every": 5, "do": [["meteor", 2.0, 30], ["meteor", 2.0, 30], ["meteor", 2.0, 30]] }]],
	["frostfist", "FROST GIANT'S FIST", "slash", "epic", ["frost", "fury"], "fists", { "dmg": 7.0, "rate": 2.6, "range": 28, "arc": 110 }, [["chill", 0.3]], [["knock", 1.6]], "HEAVY PUNCHES THAT CHILL. EVERY 4TH PUNCH FREEZES EVERY FOE NEAR YOU SOLID FOR 1.5S.", [{ "on": "every_n_shots", "every": 4, "do": [["status_area", "stun", 1.5, 70], ["status_area", "chill", 2, 70], ["vfx", "ring", "#6fd3e0", 70]] }]],
	["slimecannon", "SLIME CANNON", "flask", "rare", ["venom"], "flaskw", { "dmg": 4.6, "rate": 2.2 }, [["explode", 1], ["poison", 1]], [], "LOBS GLOBS THAT BURST AND LEAVE POISON POOLS. POISONED FOES IT KILLS MAY HATCH A WISP.", [{ "on": "on_hit", "cd": 0.3, "do": [["zone", "poison", 16, 3.0]] }, { "on": "on_kill", "chance": 0.2, "if": "poisoned", "do": [["summon", 5.0]] }]],
	["doomclock", "DOOMSDAY CLOCK", "mine", "legend", ["malice"], "minetrap", { "dmg": 18.0 }, [], [], "HEAVY TRAPS. EVERY 10S IN A FIGHT THE CLOCK STRIKES: EVERY FOE NEAR YOU TAKES 400% AND IS CURSED.", [{ "on": "every_n_seconds", "period": 10.0, "if": "fighting", "do": [["area", 220, 4.0], ["status_area", "curse", 2, 220], ["vfx", "flash"], ["vfx", "label", "MIDNIGHT!", "#a35bd6"], ["vfx", "sigil", "#a35bd6", 120]] }]],
	["chainsaw", "RIPSAW", "flame", "epic", ["fury", "blood"], "sprayer", { "dmg": 2.2, "rate": 14.0, "life": 0.2, "speed": 140 }, [], [], "A ROARING SAW WITH TINY REACH. 15% OF HITS BLEED. KILLS GIVE +10% FIRE RATE FOR 3S. +50% DAMAGE WHEN WOUNDED.", [{ "on": "on_hit", "chance": 0.15, "do": [["status", "bleed", 1]] }, { "on": "on_kill", "do": [["buff", "rate", 0.1, 3.0]] }, { "on": "while_low_hp", "do": [["buff", "dmg", 0.5, 0]] }]],
	["slotmachine", "ONE-ARMED BANDIT", "burst", "rare", ["fortune"], "pistol", { "dmg": 2.8, "rate": 1.7 }, [["luck", 1]], [], "+1 LUCK. 10% OF KILLS PULL THE LEVER: SOMETHING RANDOM HAPPENS.", [{ "on": "on_kill", "chance": 0.1, "cd": 1.0, "do": [["chaos"]] }]],
	["orbitallaser", "ORBITAL LASER", "beam", "legend", ["storm", "arcane"], "orbstaff", { "dmg": 1.9, "rate": 11.0, "pierce": 99 }, [], [], "A PIERCING RAY. EVERY 1.5S IN A FIGHT, A BEAM FROM THE SKY STRIKES A RANDOM FOE.", [{ "on": "every_n_seconds", "period": 1.5, "if": "fighting", "do": [["bolts", 1, 1.4]] }]],
	["peppershaker", "GHOST PEPPER SHAKER", "nova", "rare", ["pyre"], "lanternw", { "dmg": 2.8, "count": 12 }, [["burn", 0.3]], [], "A RING OF 12 BURNING FLAKES. ROLLING LEAVES A POOL OF FIRE AND GIVES +25% MOVE SPEED FOR 2S.", [{ "on": "on_roll", "cd": 1.0, "do": [["zone", "fire", 18, 3.0], ["buff", "speed", 0.25, 2.0]] }]],
	["bubblewand", "BUBBLE WAND", "orb", "common", ["frost"], "wand", { "dmg": 4.2, "rate": 2.6, "speed": 95, "size": 1.9, "pierce": 2, "life": 1.6 }, [], [], "BIG, SLOW BUBBLES THAT DRIFT THROUGH 3 FOES. 30% OF HITS WEAKEN.", [{ "on": "on_hit", "chance": 0.3, "do": [["status", "weakened", 1]] }]],
	["clownhammer", "SQUEAKY HAMMER", "slash", "rare", ["fortune", "fury"], "hammer", { "dmg": 10.0, "rate": 1.5, "range": 36, "arc": 130 }, [["crit", 0.1]], [["knock", 3.0]], "SQUEAKS. ABSURD KNOCKBACK. +10% CRIT. CRITS PAY 2 GOLD AND FLING EVERY NEARBY FOE AWAY.", [{ "on": "on_crit", "cd": 0.3, "do": [["gold", 2], ["push", 70, 300]] }]],
	["necroflute", "BONE FLUTE", "summon", "epic", ["swarm", "malice"], "skullstaff", { "dmg": 3.0, "rate": 1.1 }, [["curse", 0.1]], [], "EACH NOTE RAISES A SPIRIT. 10% OF HITS CURSE. CURSED FOES YOU KILL ALWAYS RISE AS A WISP FOR 8S.", [{ "on": "on_kill", "if": "cursed", "do": [["summon", 8.0]] }]],
	["backfire", "BACKFIRE BLUNDERBUSS", "shot", "rare", ["fury", "demolition"], "blunderbuss", { "dmg": 2.6, "count": 5, "spread": 0.22 }, [], [], "EVERY BLAST ALSO FIRES 5 PELLETS BEHIND YOU.", [{ "on": "on_shoot", "do": [["shoot_at", 5, 1.0, "", 0.22, 3.14159]] }]],
	["crossfirebow", "CROSSFIRE BOW", "bolt", "epic", ["arcane", "edge"], "bow", { "dmg": 3.8, "rate": 3.4, "pierce": 1 }, [["crit", 0.05]], [], "EVERY SHOT ALSO LOOSES ARROWS TO YOUR LEFT, RIGHT AND BEHIND. +5% CRIT.", [{ "on": "on_shoot", "do": [["shoot_at", 1, 0.7, "", 0.0, 1.5708], ["shoot_at", 1, 0.7, "", 0.0, -1.5708], ["shoot_at", 1, 0.7, "", 0.0, 3.14159]] }]],
	["tentacle", "KRAKEN TENTACLE", "whip", "epic", ["frost", "venom"], "whip", { "dmg": 6.5, "range": 86 }, [["poison", 1]], [], "A VERY LONG, SLIMY LASH THAT POISONS. EVERY 4TH LASH DRAGS FOES TOWARD YOU AND WEAKENS THEM.", [{ "on": "every_n_shots", "every": 4, "do": [["pull", 120, 220], ["status_area", "weakened", 1, 120]] }]],
	["joustrocket", "JOUSTING ROCKET", "thrust", "rare", ["demolition", "fury"], "spear", { "dmg": 8.0, "range": 70 }, [], [], "A LANCE WITH A FIREWORK TIED ON. 20% OF HITS EXPLODE FOR 80%. ROLLING GIVES +40% DAMAGE FOR 2S.", [{ "on": "on_hit", "chance": 0.2, "do": [["explode", 26, 0.8]] }, { "on": "on_roll", "do": [["buff", "dmg", 0.4, 2.0]] }]],
	["homingaxes", "BLOODHOUND HATCHETS", "spin", "rare", ["swarm", "edge"], "axe", { "dmg": 7.0, "rate": 1.9, "homing": 2.5, "pierce": 3 }, [], [], "AXES THAT HUNT FOES DOWN AND CUT THROUGH 4. KILLS REFUND A ROLL 30% OF THE TIME.", [{ "on": "on_kill", "chance": 0.3, "do": [["refund_roll"]] }]],
	# ---------- ROADMAP 4.6 part 1: MAYHEM (explosives and mischief; scripts/combat/arsenal.gd) ----------
	["pineapple", "PINEAPPLE GRENADE", "grenade", "common", ["demolition"], "grenade", { "shrapnel": 6 }, [], [], "LANDS BY THE FOE YOU AIM AT AND BLOWS AFTER 1.5S. THE BLAST THROWS 6 SHARDS."],
	["skipcharge", "SKIPPING CHARGE", "grenade", "rare", ["demolition", "storm"], "grenade", { "dmg": 8.0, "rate": 1.0, "life": 2.2, "radius": 32, "skips": 3 }, [], [], "HOPS THREE TIMES WITH A SMALL BLAST AT EVERY HOP, THEN A BIG ONE."],
	["pomegranate", "POMEGRANATE", "grenade", "rare", ["swarm", "demolition"], "grenade", { "dmg": 8.0, "rate": 1.0, "life": 1.4, "radius": 30, "cluster": 6 }, [], [], "THE BLAST SCATTERS 6 SEEDS THAT POP ON THEIR OWN."],
	["hoarfrost", "HOARFROST GRENADE", "grenade", "rare", ["frost"], "grenade", { "dmg": 7.0, "life": 1.3, "radius": 36, "freeze": 1.2 }, [], [], "A COLD BLAST: FOES IN IT FREEZE SOLID FOR 1.2S, THEN STAY CHILLED."],
	["fruitcake", "GRANDMA'S FRUITCAKE", "grenade", "epic", ["fortune", "bulwark"], "grenade", { "dmg": 26.0, "rate": 0.45, "speed": 120, "life": 2.6, "radius": 80, "heavy": true, "crumbs": 3 }, [], [], "TOO HEAVY TO BOUNCE. SITS 2.6S, THEN A HUGE BLAST THAT LEAVES CRUMBS: COINS, NOW AND THEN A HEART."],
	["bottlerockets", "BOTTLE ROCKETS", "rocket", "common", ["pyre"], "launcher", { "dmg": 4.0, "rate": 1.3, "count": 3, "spread": 0.25, "speed": 150, "life": 1.2, "radius": 16, "wobble": 1.0 }, [["burn", 0.15]], [], "THREE WOBBLY ROCKETS WITH SMALL BANGS. 15% BURN."],
	["alleyrpg", "BACKALLEY RPG", "rocket", "rare", ["demolition", "fury"], "launcher", { "dmg": 16.0, "rate": 0.7, "speed": 120, "life": 2.0, "radius": 44, "backblast": 1.0 }, [], [], "A BIG ROCKET THAT SPEEDS UP. THE BACKBLAST BURNS FOES BEHIND YOU."],
	["festival", "FESTIVAL LAUNCHER", "rocket", "epic", ["arcane", "pyre"], "launcher", { "dmg": 8.0, "rate": 1.0, "speed": 160, "life": 0.9, "radius": 4, "fireworks": 12 }, [], [], "ROCKETS FLY THROUGH FOES, THEN BURST INTO A STAR OF 12 SPARKS."],
	["pathfinder", "PATHFINDER ROCKET", "rocket", "legend", ["edge", "demolition"], "launcher", { "dmg": 14.0, "rate": 0.8, "speed": 130, "life": 3.0, "radius": 36, "guided": true, "ramp": 1.0 }, [], [], "STEER IT WITH YOUR AIM. THE LONGER IT FLIES, THE HARDER IT HITS: +100% A SECOND."],
	["swarmpod", "SWARM POD", "missile", "epic", ["swarm", "demolition"], "launcher", { "swarm": 6 }, [], [], "SIX LITTLE MISSILES RISE, THEN EACH ONE HUNTS A FOE OF ITS OWN."],
	["lockon", "LOCK-ON LAUNCHER", "missile", "rare", ["edge"], "launcher", { "dmg": 22.0, "rate": 0.6, "radius": 22, "lock": 0.6 }, [], [["elite_dmg", 0.5]], "LOCKS ON TO THE TOUGHEST FOE, THEN A MISSILE THAT NEVER MISSES. +50% TO ELITES."],
	["stickyjar", "STICKY JAR", "sticky", "common", ["demolition", "venom"], "flaskw", { "rolldet": true }, [], [], "STICKS TO FOES AND WALLS. BLOWS AFTER 2.5S, OR AT ONCE WHEN YOU ROLL."],
	["limpets", "LIMPET CHARGES", "sticky", "epic", ["demolition", "shadow"], "mine", { "dmg": 12.0, "rate": 1.6, "speed": 210, "remote": 4 }, [], [], "CHARGES STICK AND WAIT. EVERY 4TH THROW IS THE CLICK: THEY ALL BLOW, EACH 10% HARDER FOR EVERY OTHER."],
	["pocketmortar", "POCKET MORTAR", "mortar", "common", ["demolition"], "mortar", {}, [], [], "LOBS A SHELL OVER WALLS ONTO THE FOE YOU AIM AT."],
	["snowglobe", "SNOWGLOBE MORTAR", "mortar", "epic", ["frost", "arcane"], "mortar", { "dmg": 10.0, "rate": 0.8, "life": 1.0, "radius": 34, "zone": "frost" }, [["vs_chill", 0.3]], [], "THE SHELL LEAVES A SNOWSTORM FOR 3S. CHILLED FOES TAKE +30%."],
	["clockmice", "CLOCKWORK MICE", "walker", "rare", ["swarm", "demolition"], "toy", { "dmg": 10.0, "rate": 0.9, "count": 2, "spread": 0.5, "speed": 95, "radius": 28 }, [], [], "TWO WIND-UP MICE THAT SCURRY TO THE NEAREST FOE AND BLOW UP."],
	["keg", "ROLLING KEG", "walker", "common", ["fury"], "barrel", { "dmg": 14.0, "speed": 150, "life": 5.0, "radius": 34, "roll": 2, "spread": 0.2 }, [], [], "A KEG THAT ROLLS STRAIGHT, BOUNCES OFF TWO WALLS AND BLOWS ON THE FIRST FOE IT MEETS."],
	["signalflare", "SIGNAL FLARE", "strike", "epic", ["pyre", "demolition"], "pistol", {}, [["burn", 0.3]], [], "MARKS A LINE ALONG YOUR AIM. 1S LATER, FIVE BOMBS FALL ALONG IT. 30% BURN."],
	["skyhammer", "SKY HAMMER", "strike", "legend", ["storm", "bulwark"], "rod", { "dmg": 30.0, "rate": 0.55, "life": 0.8, "pillar": true }, [], [], "PAINTS THE TOUGHEST FOE WITH A LIGHT FOR 0.8S. THEN THE SKY HITS IT AND STUNS FOES NEAR IT."],
	["dynamite", "DYNAMITE BUNDLE", "dynamite", "rare", ["demolition", "fury"], "sticks", {}, [], [], "THREE STICKS A THROW, FIZZING 1.3S TO 1.7S. A BLAST SETS OFF EVERY STICK NEAR IT, EACH ONE 25% HARDER."],
	["repulsor", "REPULSOR", "wave", "rare", ["storm", "bulwark"], "gauntlet", { "push": 300 }, [], [], "A CONE OF FORCE THAT HURLS FOES AWAY. FOES SLAMMED INTO A WALL TAKE 150% MORE."],
	["shrapnelgun", "SHRAPNEL SHOTGUN", "shot", "common", ["demolition"], "shotgun", { "dmg": 2.4, "count": 6, "spread": 0.2, "speed": 240, "life": 0.8 }, [], [["wall_shrapnel", 3]], "SIX FAR-FLYING PELLETS. A PELLET THAT HITS A WALL BURSTS INTO 3 SHARDS."],
	["blastknuckles", "BLASTING KNUCKLES", "slash", "epic", ["fury", "demolition"], "fists", { "dmg": 5.0, "rate": 3.2, "range": 24, "arc": 90 }, [], [], "FAST PUNCHES THAT PLANT A CHARGE ON THE FOE. IT BLOWS 0.6S LATER.", [{ "on": "on_hit", "cd": 0.15, "do": [["plant", 0.6, 0.8, 26]] }]],
	["parasite", "PARASITE LAUNCHER", "flask", "epic", ["malice", "swarm"], "flaskw", { "dmg": 4.4, "rate": 1.8 }, [["poison", 1]], [], "GLOBS THAT POISON. 35% OF HITS MAKE THE FOE A PUPPET: IT WALKS INTO ANOTHER FOE AND BURSTS.", [{ "on": "on_hit", "chance": 0.35, "cd": 0.5, "do": [["puppet", 5.0]] }]],
	["piggybank", "PIGGY BANK", "shot", "legend", ["fortune"], "blunderbuss", { "dmg": 2.6, "count": 6, "spread": 0.22 }, [], [["piggy", 30], ["gold_hit", 0.02]], "FIRES A SPRAY OF COINS. EVERY 30 GOLD YOU PICK UP FILLS THE PIG: YOUR NEXT SHOT LAUNCHES IT."],
	# ---------- ROADMAP 4.6 part 2: CHARGE AND COMBO (held to charge, two stages, in turns; scripts/combat/charged.gd) ----------
	["plasmaslug", "PLASMA SLUGGER", "charge", "common", ["arcane"], "cannon", {}, [], [], "HOLD TO CHARGE. THE BALL GROWS BIGGER AND HARDER, AND A FULL CHARGE PIERCES EVERYTHING."],
	["shatterball", "SHATTERBALL", "charge", "rare", ["arcane", "demolition"], "cannon", { "shatter": 8 }, [], [], "A CHARGED BALL THAT BURSTS INTO 8 SHARDS WHERE IT STOPS."],
	["gravityglobe", "GRAVITY GLOBE", "charge", "epic", ["shadow", "arcane"], "orb", { "pull": 1.0, "dmg": 7.0, "speed": 150, "life": 1.6 }, [], [], "A SLOW GLOBE THAT DRAGS FOES TO IT AS IT FLIES, THEN COLLAPSES WITH A BANG."],
	["swiftdraw", "SWIFTDRAW BOW", "charge", "rare", ["edge"], "bow", { "roll_draw": true, "dmg": 9.0, "speed": 380, "life": 0.9, "rate": 0.7 }, [], [], "DRAWS SLOWLY, BUT A ROLL DRAWS IT FULLY AT ONCE. A FULL DRAW ALWAYS CRITS AND PIERCES."],
	["chokeshotgun", "CHOKE SHOTGUN", "charge", "common", ["demolition"], "shotgun", { "tighten": 7, "dmg": 3.0, "speed": 260, "life": 0.55, "rate": 1.4 }, [], [], "HOLD TO CHOKE THE SPREAD: 7 PELLETS GO FROM A WIDE FAN TO ONE TIGHT SLUG."],
	["coldstar", "COLD STAR", "charge", "legend", ["frost", "arcane"], "orb", { "aura": 70.0, "dmg": 11.0 }, [["vs_chill", 0.25]], [], "WHILE YOU CHARGE, FOES NEAR YOU ARE CHILLED. A FULL CHARGE FREEZES WHAT IT HITS."],
	["quakemaul", "QUAKE MAUL", "slam", "rare", ["bulwark", "demolition"], "maul", {}, [], [], "HOLD TO CHARGE, THEN SLAM: A SHOCKWAVE ROLLS OUT ALONG THE FLOOR. A FULL CHARGE STUNS."],
	["emberquake", "EMBERQUAKE MAUL", "slam", "epic", ["pyre"], "maul", { "fire_ring": true }, [["burn", 0.2]], [], "THE SHOCKWAVE LEAVES A RING OF FIRE WHERE IT ENDS. 20% BURN."],
	["aftershock", "AFTERSHOCK HAMMER", "slam", "legend", ["storm", "bulwark"], "hammer", { "aftershocks": 2, "dmg": 12.0 }, [], [], "EVERY SLAM IS FOLLOWED BY TWO SMALLER AFTERSHOCKS."],
	["dashblade", "DASHBLADE", "dash", "rare", ["edge"], "sword", {}, [], [], "HOLD TO CHARGE, THEN DASH THROUGH FOES, CUTTING EACH ONE. NOTHING TOUCHES YOU MID-DASH."],
	["cometlance", "COMET LANCE", "dash", "epic", ["pyre", "demolition"], "lance", { "dash_blast": 1.2, "range": 110 }, [], [], "A LONGER DASH THAT ENDS IN A BLAST."],
	["phantomedge", "PHANTOM EDGE", "dash", "legend", ["shadow", "edge"], "sword", { "phantom": 0.8 }, [], [], "0.5S AFTER EACH DASH, A PHANTOM DASHES THE SAME WAY AND CUTS AGAIN."],
	["warjavelin", "WAR JAVELIN", "javelin", "rare", ["fury"], "spear", {}, [], [], "THROW IT: IT PINS A FOE. YOUR NEXT ATTACK DASHES YOU TO IT, CUTTING ALL ON THE WAY, AND TEARS IT OUT. A MISS COMES BACK."],
	["thunderpike", "THUNDER PIKE", "javelin", "epic", ["storm"], "spear", { "rod": 0.5 }, [], [], "PINNED IN A FOE, IT CALLS LIGHTNING ON FOES NEAR IT UNTIL YOU DASH TO IT."],
	["grapple", "GRAPPLE GAUNTLET", "hook", "rare", ["bulwark", "fury"], "gauntlet", {}, [], [], "A HOOK PULLS A FOE TO YOU, AND THE NEXT ATTACK IS A PUNCH THAT STUNS. BIG FOES PULL YOU TO THEM."],
	["anchorchain", "ANCHOR CHAIN", "hook", "epic", ["bulwark", "demolition"], "chain", { "drag": 1.0, "dmg": 10.0 }, [], [], "THE HOOKED FOE IS DRAGGED THROUGH THE OTHERS, HITTING EACH ONE. THEN THE PUNCH."],
	["cutlass", "CUTLASS AND FLINTLOCK", "combo", "rare", ["fortune", "edge"], "sword", { "steps": ["slash", "slash", "shot"] }, [], [], "TWO CUTS, THEN A PISTOL SHOT THAT ALWAYS CRITS A FOE THE CUTS HIT."],
	["chainglaive", "CHAIN GLAIVE", "combo", "epic", ["arcane", "edge"], "glaive", { "steps": ["sweep", "thrust", "spin"], "linked": true, "dmg": 7.0 }, [], [], "A SWEEP, A THRUST, A SPIN. EACH COMES ONLY IF THE ONE BEFORE IT HIT."],
	["flarefist", "FLAREFIST", "combo", "rare", ["pyre", "fury"], "fists", { "steps": ["jab", "jab", "upper"], "range": 22, "rate": 3.0 }, [], [], "JAB, JAB, THEN A BURNING UPPERCUT THAT STUNS AND SLAMS THE FOE DOWN."],
	["steamrepeater", "STEAM REPEATER", "heat", "rare", ["bulwark"], "repeater", {}, [], [], "FIRES FAST AND HEATS UP. AT FULL HEAT IT VENTS A SCALDING BLAST AROUND YOU, THEN COOLS."],
	["reactorrifle", "REACTOR RIFLE", "heat", "legend", ["pyre", "arcane"], "rifle", { "heat_dmg": 1.0, "dmg": 2.4 }, [], [], "THE HOTTER IT RUNS, THE HARDER IT HITS: UP TO +100%. ITS VENT IS A HUGE BLAST."],
	["deadeye", "DEADEYE REVOLVER", "reload", "rare", ["edge", "fortune"], "pistol", { "mag": 6, "dmg": 7.0, "rate": 4.0, "reload": 1.2, "last_crit": true, "kill_reload": true }, [], [], "SIX SHOTS, THE SIXTH ALWAYS CRITS, THEN A RELOAD. A KILL RELOADS AT ONCE."],
	["magdump", "MAGDUMP CARBINE", "reload", "common", ["demolition"], "rifle", { "mag": 12, "rate": 9.0, "dmg": 2.6, "reload": 1.4, "throw_mag": 5.0 }, [], [], "TWELVE QUICK SHOTS. THE EMPTY MAGAZINE IS THROWN AT THE FOE AND BLOWS UP."],
	["starcaller", "STARCALLER", "orbit", "epic", ["arcane", "swarm"], "rod", {}, [], [], "EACH ATTACK ADDS A STAR CIRCLING YOU THAT HURTS FOES IT TOUCHES. AT SIX THEY ALL FLY OUT AND HUNT."],
	["snapback", "SNAPBACK DISC", "recall", "rare", ["edge", "storm"], "disc", {}, [], [], "FLIES OUT AND SPINS IN PLACE. YOUR NEXT ATTACK CALLS IT BACK THROUGH FOES FOR DOUBLE DAMAGE."],
	# ---------- ROADMAP 4.6 part 3: DECK AND DEN (cards, turrets, summons; scripts/combat/summons.gd) ----------
	["duelistdeck", "DUELIST'S DECK", "deck", "rare", ["edge"], "cards", { "deck": ["strike", "strike", "strike", "bash", "cleave", "flurry"] }, [], [], "PLAYS ONE CARD AN ATTACK: STRIKE, BASH, CLEAVE, FLURRY. THE NEXT THREE SHOW OVER YOUR HEAD."],
	["poisonpack", "POISONER'S PACK", "deck", "epic", ["venom"], "cards", { "deck": ["toxin", "toxin", "toxin", "catalyst", "noxious", "strike"] }, [], [], "TOXIN POISONS, NOXIOUS LEAVES A CLOUD, AND CATALYST DOUBLES THE POISON ON EVERY FOE NEAR ITS TARGET."],
	["shivdeck", "SHIV DECK", "deck", "rare", ["malice", "edge"], "cards", { "deck": ["dance", "dance", "shiv", "shiv", "finisher"] }, [], [], "SHIVS AND BLADE DANCES, THEN THE FINISHER: HARDER FOR EVERY CARD PLAYED SINCE THE LAST SHUFFLE."],
	["countdowndeck", "COUNTDOWN DECK", "deck", "epic", ["demolition"], "cards", { "deck": ["bomb", "strike", "strike", "bash", "flurry"] }, [], [], "THE BOMB CARD LEAVES A BOMB THAT BLOWS WHEN THREE MORE CARDS HAVE BEEN PLAYED."],
	["echodeck", "ECHO DECK", "deck", "legend", ["arcane"], "cards", { "deck": ["double", "strike", "cleave", "double", "flurry", "bash"] }, [], [], "DOUBLE TAP PLAYS THE NEXT CARD TWICE."],
	["ascenddeck", "ASCENDING DECK", "deck", "rare", ["fortune"], "cards", { "deck": ["strike", "strike", "bash", "cleave", "flurry"], "ascend": true }, [], [], "EVERY SHUFFLE UPGRADES ONE CARD: +50% UNTIL YOU LEAVE THE ROOM."],
	["sentrykit", "SENTRY KIT", "turret", "rare", ["bulwark"], "kit", { "turret": "gun" }, [], [], "EACH ATTACK BUILDS A GUN TURRET AT YOUR FEET, TWO AT A TIME. THEY SHOOT THE NEAREST FOE."],
	["flamesentry", "FLAME SENTRY", "turret", "epic", ["pyre"], "kit", { "turret": "flame" }, [["burn", 0.3]], [], "TURRETS THAT SPRAY FIRE AT FOES CLOSE TO THEM. 30% BURN."],
	["teslapair", "TESLA PAIR", "turret", "epic", ["storm"], "coil", { "turret": "tesla" }, [], [], "COILS THAT ZAP FOES NEAR THEM. TWO COILS ARE JOINED BY A BEAM THAT BURNS FOES CROSSING IT."],
	["frostbeacon", "FROST BEACON", "turret", "rare", ["frost"], "beacon", { "turret": "frost" }, [], [], "BEACONS THAT PULSE COLD: FOES NEAR THEM ARE HURT AND CHILLED."],
	["sawtrap", "SAW TRAP", "turret", "common", ["edge"], "trap", { "turret": "saw" }, [], [], "THROWS A SAW TRAP BY THE FOE YOU AIM AT. IT CUTS AND SLOWS WHAT WALKS OVER IT."],
	["mendtotem", "MENDING TOTEM", "turret", "epic", ["venom", "bulwark"], "totem", { "turret": "mend" }, [], [], "TOTEMS THAT ZAP FOES. STANDING BY ONE HEALS HALF A HEART EVERY 12S."],
	["gravecaller", "GRAVECALLER STAFF", "thrall", "epic", ["malice", "shadow"], "staff", { "thrall": "bones" }, [], [], "FOES YOU KILL RISE AS BONE THRALLS THAT FIGHT FOR YOU FOR 12S, UP TO 4."],
	["claygolem", "CLAY GOLEM", "thrall", "legend", ["bulwark"], "clay", { "thrall": "golem", "dmg": 6.0 }, [], [], "EACH ATTACK ADDS CLAY TO YOUR GOLEM. IT GROWS FIVE TIMES, AND FULL-GROWN ITS PUNCHES SHAKE THE FLOOR."],
	["implantern", "IMP LANTERN", "thrall", "rare", ["pyre", "shadow"], "lantern", { "thrall": "imp", "dmg": 6.0 }, [], [], "EACH ATTACK CALLS AN IMP, UP TO 3, THAT FLITS AROUND YOU THROWING FIREBALLS."],
	["wolfhorn", "WOLF HORN", "thrall", "epic", ["fury", "blood"], "horn", { "thrall": "wolf" }, [], [], "EACH BLAST OF THE HORN SENDS THREE SPIRIT WOLVES AT THE FOE YOU AIM AT. THEIR BITES BLEED."],
	["mimicchest", "MIMIC CHEST", "thrall", "rare", ["fortune"], "chest", { "thrall": "mimic", "dmg": 5.0 }, [], [], "A HUNGRY CHEST FOLLOWS YOU. EACH ATTACK IT HOPS ONTO A FOE AND CHOMPS. ITS KILLS DROP A COIN."],
	["petwhistle", "PET WHISTLE", "command", "rare", ["fortune", "fury"], "whistle", { "command": "leap" }, [], [], "YOUR PET'S SPIRIT LEAPS AT THE FOE YOU AIM AT AND BITES, HARDER FOR EACH PET LEVEL. NO PET: A SPIRIT PUP."],
	["shepherdcrook", "SHEPHERD'S CROOK", "command", "epic", ["bulwark", "fortune"], "crook", { "command": "lob" }, [], [], "LOBS A SHEEP ONTO THE FOE YOU AIM AT. IT BAAS, THEN BLOWS UP. WITH A PET, ITS SPIRIT GOES INSTEAD AND BLOWS BIGGER."],
	["lookingglass", "LOOKING GLASS", "mirror", "epic", ["arcane"], "mirror", { "mirror": "image" }, [], [], "EACH ATTACK LEAVES A MIRROR IMAGE OF YOU, TWO AT A TIME, THAT FIRES WHEN YOU FIRE."],
	["doppelganger", "DOPPELGANGER BLADE", "mirror", "legend", ["shadow", "edge"], "sword", { "mirror": "shadow", "dmg": 7.0, "rate": 2.2, "range": 30, "arc": 110 }, [], [], "YOUR SHADOW FOLLOWS ONE SECOND BEHIND YOU AND REPEATS EVERY CUT FROM WHERE IT IS."],
	["batcloud", "BAT CLOUD", "swarm", "rare", ["shadow", "blood"], "bats", { "swarm": "bats" }, [], [], "EACH ATTACK ADDS BATS TO A CLOUD THAT FLIES AT THE FOE YOU AIM AT AND BITES ALL IN IT."],
	["fireflyjar", "FIREFLY JAR", "swarm", "common", ["pyre"], "jar", { "swarm": "fireflies", "dmg": 4.0 }, [], [], "FIREFLIES CIRCLE THE FOE YOU AIM AT AND BURN IT. THREE ON ONE FOE FLARE UP IN A BLAST."],
	["dragonegg", "DRAGON EGG", "egg", "legend", ["pyre", "arcane"], "egg", {}, [], [], "WARM IT BY HITTING FOES: 15 HITS HATCH A BABY DRAGON THAT BREATHES FIRE FOR THE REST OF THE ROOM.", [{ "on": "on_hit", "do": [["warm", 1]] }]],
	["tamerswhip", "TAMER'S WHIP", "whip", "epic", ["fury"], "whip", { "dmg": 5.0 }, [], [], "25% OF HITS TAME AN ORDINARY FOE: FOR 8S IT FIGHTS FOR YOU.", [{ "on": "on_hit", "chance": 0.25, "cd": 1.0, "do": [["charm", 8.0]] }]],
	# ---------- ROADMAP 4.6 part 4: GUNPLAY AND ODDITIES (strange guns and tricks; scripts/combat/oddities.gd) ----------
	["typewriter", "TYPEWRITER", "letters", "common", ["arcane"], "typewriter", { "words": ["BOOM"] }, [], [], "EVERY SHOT IS A LETTER: B, O, O, M. THE LAST ONE'S HIT GOES BOOM."],
	["prophetquill", "PROPHET'S QUILL", "letters", "epic", ["arcane", "malice"], "quill", { "words": ["ZAP", "ICE", "BURN", "GOLD", "DOOM"] }, [], [], "SPELLS A RANDOM WORD, A LETTER A SHOT: ZAP, ICE, BURN, GOLD OR DOOM. THE LAST LETTER'S HIT CASTS IT."],
	["bubbleblaster", "BUBBLE BLASTER", "bubble", "rare", ["frost"], "blaster", {}, [], [], "A BUBBLE TRAPS THE FIRST FOE IT MEETS. YOUR NEXT BUBBLE ON A TRAPPED FOE POPS IT FOR TRIPLE DAMAGE."],
	["soapcannon", "SOAP CANNON", "bubble", "epic", ["frost", "fortune"], "cannon", { "soap": true, "rate": 1.2 }, [], [], "BIG BUBBLES TRAP UP TO THREE FOES TOGETHER. POP ONE AND THEY ALL POP. ON A FOE TOO BIG TO TRAP, A BUBBLE BURSTS."],
	["flakpistol", "FLAK PISTOL", "flak", "rare", ["demolition"], "pistol", {}, [], [], "ITS SHOTS POP THE ENEMY SHOTS THEY TOUCH, UP TO THREE EACH, AND GO ON THROUGH A FOE."],
	["interceptor", "INTERCEPTOR", "flak", "epic", ["storm", "demolition"], "rifle", { "barrage": 15, "dmg": 4.0 }, [], [], "POPS ENEMY SHOTS. FOR EVERY 15 POPPED, A RING OF 12 SHOTS BURSTS FROM YOU."],
	["inkgun", "INK GUN", "paint", "rare", ["shadow"], "pistol", { "colors": ["ink"] }, [], [], "SHOTS SPLASH INK ON THE FLOOR. FOES IN IT ARE SLOWED AND TAKE MORE DAMAGE."],
	["tricolor", "TRICOLOR SPLATTER", "paint", "epic", ["pyre", "frost"], "sprayer", { "colors": ["red", "blue", "yellow"] }, [], [], "PAINT IN TURN: RED BURNS FOES, BLUE CHILLS THEM, AND IN YELLOW YOU MOVE AND FIRE FASTER."],
	["slotpistol", "SLOT PISTOL", "slots", "common", ["fortune"], "pistol", {}, [], [], "EVERY SHOT SPINS THREE REELS. PAIRS AND THREE OF A KIND PAY OUT: SPARKS, LIGHTNING, LUCKY CRITS, COINS, A JACKPOT."],
	["gildedslots", "GILDED SLOTS", "slots", "legend", ["fortune", "pyre"], "pistol", { "stakes": true, "dmg": 4.0 }, [], [], "STAKES A COIN ON EVERY SPIN WHILE YOU HAVE ONE. EVERY PAYOUT IS THREE TIMES BIGGER."],
	["snowroller", "SNOW ROLLER", "roller", "rare", ["frost"], "snowball", {}, [], [], "A SNOWBALL THAT ROLLS ALONG THE FLOOR, GROWING AND CHILLING WHAT IT HITS. IT BURSTS AFTER 3S."],
	["mossboulder", "MOSS BOULDER", "roller", "epic", ["bulwark", "venom"], "boulder", { "moss": true }, [], [], "A BOULDER THAT ROLLS AND GROWS. WHEN IT STOPS IT STANDS AS COVER FOR 5S, STOPPING ENEMY SHOTS."],
	["paydaycannon", "PAYDAY CANNON", "money", "legend", ["fortune"], "cannon", {}, [], [], "EVERY SHOT SPENDS A COIN ON A GOLD SLUG: +1% DAMAGE FOR EVERY COIN YOU HOLD. BROKE, IT FIRES LINT."],
	["flashcamera", "FLASH CAMERA", "camera", "rare", ["arcane"], "camera", {}, [], [], "A FLASH THAT STUNS FOES IN FRONT. A FOE'S THIRD PHOTO DEVELOPS INTO A HUGE CRIT."],
	["glacierray", "GLACIER RAY", "ray", "epic", ["frost"], "ray", { "dmg": 1.6 }, [], [], "A COLD RAY. A FOE HELD IN IT FOR 1.2S FREEZES SOLID, AND SHATTERS INTO ICE IF IT DIES FROZEN."],
	["junkcannon", "JUNK CANNON", "junk", "common", ["demolition", "fortune"], "cannon", {}, [], [], "FIRES JUNK IN TURN: A BOOT KNOCKS FOES BACK, A CAN BOUNCES, A BOTTLE SHATTERS, A TIRE ROLLS THROUGH."],
	["fishcannon", "FISH CANNON", "junk", "rare", ["frost", "fortune"], "cannon", { "fish": true }, [], [], "FIRES LIVE FISH THAT FLOP ON THE FLOOR. FOES THAT STEP ON ONE SLIP AND FALL."],
	["homerunbat", "HOME RUN BAT", "bat", "rare", ["fury"], "bat", {}, [], [], "KNOCKS FOES FLYING. A FLYING FOE HITS THE ONES IT MEETS, AND SLAMS INTO WALLS."],
	["croquetmallet", "CROQUET MALLET", "bat", "epic", ["fortune", "bulwark"], "mallet", { "croquet": true }, [], [], "SENDS THE NEAREST FOE ROLLING STRAIGHT ALONG YOUR AIM, OFF TWO WALLS, THROUGH ALL IN ITS WAY."],
	["backstabdirk", "BACKSTAB DIRK", "stab", "rare", ["shadow", "edge"], "dagger", {}, [], [], "QUICK STABS. A STAB IN THE BACK OF A FOE FACING AWAY ALWAYS CRITS, TWICE AS HARD."],
	["callingcard", "CALLING CARD", "duel", "rare", ["edge", "fortune"], "pistol", {}, [], [], "THE FIRST HIT ON EACH FOE IS A CALLING CARD: FOUR TIMES THE DAMAGE, ALWAYS A CRIT."],
	["shrinkray", "SHRINK RAY", "shrink", "epic", ["arcane", "malice"], "raygun", {}, [], [], "SHRINKS FOES FOR 5S: THEY CAN'T HURT YOU BY TOUCH AND TAKE MORE. WALK ONTO ONE TO SQUASH IT. TOO BIG TO SHRINK: 2.5X DAMAGE."],
	["leafblower", "LEAF BLOWER", "blower", "rare", ["storm", "venom"], "blower", { "dmg": 4.0 }, [], [], "A GUST THAT TURNS ENEMY SHOTS AROUND (NOW THEY ARE YOURS) AND PUSHES FOES BACK."],
	["aegisprojector", "AEGIS PROJECTOR", "dome", "epic", ["bulwark", "storm"], "projector", {}, [], [], "A DOME BY YOU: ENEMY SHOTS THAT ENTER IT POP, AND FOES IN IT ARE BURNED. EACH ATTACK IT LANCES THE NEAREST FOE WITH LIGHT."],
	["coinflipper", "COIN FLIPPER", "coin", "epic", ["fortune", "edge"], "pistol", {}, [], [], "EVERY 3RD SHOT TOSSES A SPINNING COIN. A SHOT THAT HITS THE COIN SPLITS INTO TWO CRITS THAT SEEK FOES."],
	# "You're going to Brazil" (his ask, 6 Oct; brazil.gd): found only from the Haggler and the Holy Cow.
	["cowmilker", "COW MILKER", "gatling", "legend", ["bulwark", "frost"], "minigun", { "dmg": 2.2, "rate": 9.0, "bullet": "spark" }, [["chill", 0.2]], [], "SPRAYS FRESH MILK THAT CHILLS. EVERY 30TH SQUIRT: MOO! A RING OF 16 MILK SHOTS. 5% OF KILLS HEAL HALF A HEART.", [{ "on": "every_n_shots", "every": 30, "do": [["nova", 16, 1.0, "spark"], ["vfx", "label", "MOO!", "#f4ecd8"]] }, { "on": "on_kill", "chance": 0.05, "do": [["heal", 1]] }]],
	["hagglerbargain", "HAGGLER'S BARGAIN", "bolt", "legend", ["fortune"], "pistol", { "dmg": 9.0, "rate": 3.0 }, [["luck", 1]], [["gold_dmg", 0.1]], "+10% DAMAGE PER 100 GOLD. A FIFTH OF HITS HAGGLE 1 GOLD OUT OF THE FOE. EVERY 12TH SHOT THROWS 5 COINS THAT HIT.", [{ "on": "on_hit", "chance": 0.2, "do": [["gold", 1]] }, { "on": "every_n_shots", "every": 12, "do": [["shoot", 5, 0.8, "", 0.2]] }]],
	# ROADMAP 4.8 hero weapons (signature: never in loot pools).
	["hivesmoker", "HIVE SMOKER", "flame", "rare", ["swarm", "venom"], "handcannon", { "dmg": 1.4, "rate": 9.0 }, [["poison", 1]], [], "PUFFS SMOKE THAT SOOTHES BEES AND CHOKES EVERYTHING ELSE.", [], "w_firespitter"],
	["rivetgun", "RIVET GUN", "bolt", "rare", ["swarm"], "pistol", { "dmg": 3.8, "rate": 4.5 }, [], [], "FIRES HOT RIVETS FAST.", [], "w_repeater"],
	["inkquill", "INKWELL QUILL", "orb", "rare", ["venom", "arcane"], "staff", { "dmg": 3.4, "rate": 3.4, "homing": 0.5 }, [["poison", 1]], [], "BOLTS OF INK THAT CURVE TOWARD FOES AND POISON THEM.", [], "w_inkspout"],   # 18.2 the Inkling
	["thoughtstone", "THOUGHTSTONE", "orb", "rare", ["arcane"], "orbstaff", { "dmg": 3.0, "rate": 3.0, "homing": 1.5 }, [], [], "BOLTS OF THOUGHT THAT CURVE TOWARD FOES.", [], "w_thoughtstone"],   # 33.1 the Mindwarden
	["tankardmaul", "TANKARD MAUL", "slash", "rare", ["fury"], "sword", { "dmg": 11.0, "rate": 1.7 }, [], [], "A HEAVY MAUL WITH A TANKARD FOR A HEAD. WIDE, SLOW, LOUD.", [], "w_tankardmaul"],   # 33.2 the Tavern Knight
	["quickcrossbow", "QUICKSILVER CROSSBOW", "bolt", "rare", ["edge"], "repeater", { "dmg": 2.2, "rate": 6.0 }, [], [], "LIGHT BOLTS, VERY FAST.", [], "w_quickcrossbow"],   # 34.1 the Trickshot
	["bonecenser", "BONE CENSER", "thrall", "rare", ["swarm", "malice"], "staff", { "thrall": "bones" }, [], [], "FOES YOU KILL RISE AS SKELETONS THAT FIGHT FOR YOU FOR 12S.", [], "w_bonecenser"],   # 34.2 the Bonecaller
	["bonestaff", "BONE STAFF", "orb", "rare", ["malice"], "staff", { "dmg": 4.0, "rate": 2.6, "homing": 1.0 }, [["curse", 0.05]], [], "HEX BOLTS THAT SEEK THE LIVING.", [], "w_hexwand"],
	["brightblade", "BRIGHT BLADE", "slash", "rare", ["bulwark", "arcane"], "sword", { "dmg": 7.0, "rate": 2.4 }, [], [], "A BLADE POLISHED UNTIL IT SHINES LIKE A MIRROR.", [], "w_sabre"],
	["censerflail", "CENSER FLAIL", "whip", "rare", ["venom", "malice"], "whip", { "dmg": 5.0, "rate": 2.2 }, [["poison", 1]], [], "A SWINGING CENSER OF SICKLY SMOKE.", [], "w_bramblewhip"],
	["iciclewand", "ICICLE WAND", "orb", "rare", ["frost"], "staff", { "dmg": 5.0, "rate": 3.0, "pierce": 2 }, [["chill", 0.15]], [], "SHARDS OF ICE THAT PIERCE TWO FOES.", [], "w_rimerod"],
	["blastmortar", "BLAST MORTAR", "grenade", "rare", ["demolition"], "grenade", { "dmg": 9.0, "rate": 1.1, "shrapnel": 4 }, [], [], "LOBS SHELLS THAT LAND BY THE FOE YOU AIM AT. THE BLAST THROWS 4 SHARDS.", [], "w_pineapple"],
	["headsmansaxe", "HEADSMAN'S AXE", "slash", "rare", ["blood", "edge"], "greatsword", { "dmg": 12.0, "rate": 1.4, "range": 44, "arc": 140 }, [], [], "HEAVY, SLOW AND FINAL.", [], "w_gallows"],
	["pilgrimstaff", "PILGRIM'S STAFF", "pulse", "rare", ["bulwark"], "staff", { "dmg": 5.6, "rate": 1.8 }, [], [], "EACH TAP OF THE STAFF SENDS OUT A PULSE OF LIGHT.", [], "w_sparkrune"],
	["beastspear", "BEAST SPEAR", "thrust", "rare", ["swarm", "edge"], "halberd", { "dmg": 9.0, "rate": 2.5, "range": 56 }, [], [], "A HUNTING SPEAR WITH A BONE TIP.", [], "w_halberd"],
	# Boss and mini-boss drops (his ask, 6 Oct; boss_loot.gd): found only from their owner.
	["bloomspitter", "SPORE MOTHER'S BLOOM", "flame", "legend", ["venom"], "handcannon", { "dmg": 1.6, "rate": 8.0 }, [["poison", 2]], [], "SPRAYS LIVING SPORES: +2 POISON. A POISONED FOE YOU KILL BURSTS INTO A SPORE CLOUD.", [{ "on": "on_kill", "if": "poisoned", "do": [["zone", "poison", 26, 3.0]] }], "w_firespitter"],
	["drownedtome", "THE DROWNED TOME", "orb", "legend", ["arcane", "frost"], "staff", { "dmg": 4.5, "rate": 2.4 }, [["chill", 0.15]], [], "WET PAGES THAT CHILL. EVERY 8TH CAST, THE BOOK FLINGS 10 PAGES ALL AROUND YOU.", [{ "on": "every_n_shots", "every": 8, "do": [["nova", 10, 0.8, "spark"]] }], "w_witchstaff"],
	["tyranthammer", "FORGE TYRANT'S HAMMER", "slash", "legend", ["pyre", "fury"], "greatsword", { "dmg": 16.0, "rate": 1.1, "range": 46, "arc": 160 }, [["burn", 0.4]], [], "A FORGE HAMMER STILL GLOWING. +40% BURN. EVERY 4TH SWING STRIKES THE ANVIL: A BLAST FOR 150%.", [{ "on": "every_n_shots", "every": 4, "do": [["explode", 44, 1.5], ["vfx", "ring", "#e8873a", 44]] }], "w_gallows"],
	["warlordsbow", "ASH WARLORD'S WARBOW", "bolt", "legend", ["fury", "pyre"], "bow", { "dmg": 5.0, "rate": 2.8, "count": 2 }, [["burn", 0.15]], [], "TWO BURNING ARROWS A SHOT. EVERY 10TH VOLLEY CALLS AN ARROW RAIN: A METEOR ON A FOE.", [{ "on": "every_n_shots", "every": 10, "do": [["meteor", 1.8, 30]] }], "w_arbalest"],
	["crowrepeater", "CROW KING'S REPEATER", "gatling", "legend", ["shadow"], "minigun", { "dmg": 2.0, "rate": 9.0 }, [["crit", 0.05]], [], "A RATTLING REPEATER. EVERY 20TH SHOT A CROW (A WISP) FLIES OUT TO FIGHT FOR 8S.", [{ "on": "every_n_shots", "every": 20, "do": [["summon", 8.0]] }], "w_crankgun"],
	["judgescales", "SCALES OF THE AUREATE JUDGE", "pulse", "legend", ["arcane", "storm"], "staff", { "dmg": 5.0, "rate": 1.8 }, [["crit", 0.1]], [], "+10% CRIT. A FIFTH OF HITS PASS JUDGEMENT: LIGHTNING STRIKES THE FOE FOR 100%.", [{ "on": "on_hit", "chance": 0.2, "cd": 0.2, "do": [["lightning", 1.0]] }], "w_sparkrune"],
	["blankquill", "THE BLANK QUILL", "orb", "legend", ["arcane", "malice"], "staff", { "dmg": 6.0, "rate": 2.2, "homing": 1.0 }, [["echo", 0.2]], [], "20% OF SHOTS ARE WRITTEN TWICE. EVERY 10TH SHOT REWRITES THE FIGHT: SOMETHING RANDOM HAPPENS.", [{ "on": "every_n_shots", "every": 10, "do": [["chaos"]] }], "w_hexwand"],
	["hydraheads", "HYDRA'S THREE HEADS", "bolt", "legend", ["venom"], "pistol", { "dmg": 3.4, "rate": 3.0, "count": 3, "spread": 0.3 }, [["poison", 1]], [], "THREE HEADS, THREE BITES: +1 POISON. CUT ONE OFF (A KILL), AND 10% OF THE TIME TWO MORE BITE AT ONCE.", [{ "on": "on_kill", "chance": 0.1, "do": [["shoot", 2, 1.0, "", 0.3]] }], "w_burstpistol"],
	["moldyloaf", "THE MOLDY LOAF", "slash", "legend", ["venom", "bulwark"], "sword", { "dmg": 8.0, "rate": 2.4 }, [["max_hp", 2]], [], "REX'S OWN. +1 MAX HEART. 15% OF HITS SPREAD MOLD (POISON). GOOD BOY: 10% OF KILLS HEAL HALF A HEART.", [{ "on": "on_hit", "chance": 0.15, "do": [["status", "poison", 2]] }, { "on": "on_kill", "chance": 0.1, "do": [["heal", 1]] }], "rex_sword"],
	["captainsanchor", "DROWNED CAPTAIN'S ANCHOR", "thrust", "legend", ["bulwark"], "halberd", { "dmg": 9.0, "rate": 1.6, "range": 58 }, [["armor", 1]], [], "+1 ARMOR. A FIFTH OF HITS HAUL THE FOES NEAR YOUR TARGET IN TOWARD IT.", [{ "on": "on_hit", "chance": 0.2, "do": [["pull", 60, 220]] }], "w_pike"],
	["enforcergun", "ENFORCER'S SCATTERGUN", "shot", "legend", ["fury"], "blunderbuss", { "dmg": 3.0, "count": 7, "spread": 0.3, "rate": 1.4 }, [], [], "SEVEN PELLETS A SHOT. HITS UP CLOSE KNOCK FOES BACK AND STUN THEM 10% OF THE TIME.", [{ "on": "on_hit", "if": "close", "chance": 0.1, "do": [["status", "stun", 1], ["push", 40, 240]] }], "w_burstpistol"],
	["carrionlance", "CARRION LANCE", "thrust", "legend", ["malice"], "halberd", { "dmg": 8.0, "rate": 2.0, "range": 60 }, [["curse", 0.1]], [], "10% OF HITS CURSE. A FIFTH OF THE FOES IT KILLS RISE AS YOUR SKELETONS FOR 8S.", [{ "on": "on_kill", "chance": 0.2, "do": [["raise", 8.0, 0.9]] }], "w_halberd"],
	["rustcleaver", "RUST BUTCHER'S CLEAVER", "slash", "legend", ["blood"], "greatsword", { "dmg": 11.0, "rate": 1.6, "range": 40, "arc": 140 }, [["crit", 0.05]], [], "A THIRD OF HITS MAKE FOES BLEED. KILLING A BLEEDING FOE GIVES +20% DAMAGE FOR 4S.", [{ "on": "on_hit", "chance": 0.33, "do": [["status", "bleed", 1]] }, { "on": "on_kill", "if": "bleeding", "do": [["buff", "dmg", 0.2, 4.0]] }], "w_gallows"],
	["kingpingun", "KINGPIN'S DRUM GUN", "gatling", "legend", ["fortune", "edge"], "minigun", { "dmg": 2.4, "rate": 8.0 }, [["crit", 0.1]], [], "+10% CRIT. EVERY 30TH SHOT EMPTIES THE DRUM: 8 SHOTS IN A SPRAY. KILLS PAY 1 GOLD.", [{ "on": "every_n_shots", "every": 30, "do": [["shoot", 8, 0.8, "", 0.15]] }, { "on": "on_kill", "do": [["gold", 1]] }], "w_crankgun"],
	["marshalsiron", "MARSHAL'S SIX-SHOOTER", "bolt", "legend", ["edge"], "pistol", { "dmg": 7.0, "rate": 3.0 }, [["crit", 0.1]], [], "+10% CRIT. THE SIXTH SHOT IS A FAN OF THREE HEAVY ROUNDS.", [{ "on": "every_n_shots", "every": 6, "do": [["shoot", 3, 1.5, "", 0.2]] }], "w_repeater"],
	# 6.4 (his ask, 6 Oct): clockwork weapons. The Clockmaker's own, then seven to find, then the Great Engine's.
	["gearwound", "GEARWOUND REPEATER", "bolt", "rare", ["storm"], "repeater", { "dmg": 3.4, "rate": 5.5 }, [], [], "SPRING-WOUND BOLTS. EVERY 12TH SHOT SLOWS THE FOES' SHOTS NEAR YOU.", [{ "on": "every_n_shots", "every": 12, "do": [["slow_shots", 120, 0.5]] }], "w_gearwound"],
	# 10.3 the new heroes' own weapons (never in a loot pool: HERO_WEAPON).
	# 11.2 (his ask, 6 Oct, from his trailer clips): GLOOM and prism fans.
	["duskblade", "DUSKBLADE", "slash", "epic", ["malice", "edge"], "sword", { "dmg": 8.0, "rate": 2.2 }, [], [], "HALF ITS HITS ADD GLOOM.", [{ "on": "on_hit", "chance": 0.5, "do": [["status", "gloom", 1]] }], "w_duskblade"],
	["prismfan", "PRISM FAN", "beam", "epic", ["arcane"], "wand", { "count": 3 }, [], [], "A FAN OF THREE RAYS.", [], "w_prismfan"],
	["spectrum", "THE SPECTRUM", "beam", "legend", ["arcane", "storm"], "wand", { "count": 5, "dmg": 1.6 }, [], [], "FIVE RAYS. 10% OF HITS SHOCK, 10% ADD GLOOM.", [{ "on": "on_hit", "chance": 0.1, "do": [["status", "shock", 1]] }, { "on": "on_hit", "chance": 0.1, "do": [["status", "gloom", 1]] }], "w_spectrum"],
	# 10.4 (his ask, 6 Oct): flails, a new kind (flail.gd).
	["morningstar", "MORNING STAR", "flail", "common", ["fury"], "flail", {}, [], [], "A SPIKED BALL ON A CHAIN.", [], "w_flail"],
	["chainflail", "TWIN CHAIN", "flail", "rare", ["edge"], "flail", { "count": 2 }, [], [], "TWO BALLS CIRCLE YOU.", [], "w_flail_rare"],
	["frostflail", "RIMEBALL", "flail", "rare", ["frost"], "flail", {}, [["chill", 0.3]], [], "A BALL OF BLACK ICE. CHILLS WHAT IT HITS.", [], "w_flail_frost"],
	["emberflail", "EMBER MACE", "flail", "epic", ["pyre"], "flail", { "dmg": 7.5 }, [["burn", 0.3]], [], "A BALL OF COALS. SETS WHAT IT HITS ABLAZE.", [], "w_flail_ember"],
	["stormflail", "THUNDERBALL", "flail", "epic", ["storm"], "flail", { "dmg": 7.0 }, [], [["nth_zap", 3]], "EVERY 3RD LASH CALLS LIGHTNING.", [], "w_flail_storm"],
	["skullflail", "THE GRAVE BELL", "flail", "legend", ["malice", "fury"], "flail", { "dmg": 9.0, "count": 3 }, [], [["nth_nova", 4]], "THREE SKULLS ON CHAINS. EVERY 4TH LASH BURSTS INTO A RING.", [], "w_flail_skull"],
	["lute", "SINGING LUTE", "orb", "rare", ["arcane"], "orbstaff", { "dmg": 5.0, "rate": 3.2 }, [], [], "NOTES THAT CURVE TOWARD FOES.", [], "w_lute"],
	["jugglepins", "JUGGLING PINS", "boomer", "rare", ["fortune"], "chakram", { "dmg": 5.0, "rate": 2.4 }, [], [], "PINS THAT FLY OUT AND SPIN BACK.", [], "w_jugglepins"],
	["greataxe", "GREAT AXE", "slash", "rare", ["fury"], "sword", { "dmg": 12.0, "rate": 1.6 }, [], [], "A WIDE, HEAVY SWING.", [], "w_greataxe"],
	["rustyshiv", "RUSTY SHIV", "thrust", "common", ["edge"], "spear", { "dmg": 4.0, "rate": 2.6 }, [], [], "IT IS ALL YOU HAVE.", [], "w_rustyshiv"],
	["pendulum", "THE PENDULUM", "boomer", "epic", ["edge"], "chakram", { "dmg": 7.0, "rate": 1.6 }, [], [], "A HEAVY BLADE ON A CHAIN: OUT AND BACK, HITTING TWICE.", [], "w_pendulum"],
	["springlance", "SPRING LANCE", "slash", "rare", ["edge"], "spear", { "dmg": 8.0, "rate": 2.0 }, [["crit", 0.08]], [], "+8% CRIT. A COILED THRUST.", [], "w_springlance"],
	["cogthrower", "COG THROWER", "spin", "rare", ["demolition"], "disc", { "dmg": 4.0, "rate": 2.6, "pierce": 2 }, [], [], "SPINNING COGS THAT CUT THROUGH TWO FOES.", [], "w_cogthrower"],
	["steamcannon", "STEAM CANNON", "shot", "epic", ["storm"], "handcannon", { "dmg": 3.2, "rate": 1.6, "count": 6, "spread": 0.6 }, [], [], "A BURST OF SCALDING STEAM PELLETS.", [], "w_steamcannon"],
	["chronoblade", "CHRONO BLADE", "slash", "legend", ["arcane"], "sword", { "dmg": 9.0, "rate": 2.4 }, [["crit", 0.1]], [], "+10% CRIT. EVERY 8TH SWING SLOWS EVERY FOE SHOT NEAR YOU.", [{ "on": "every_n_shots", "every": 8, "do": [["slow_shots", 160, 0.3]] }], "w_chronoblade"],
	["tickbomb", "TICKING FLASK", "flask", "rare", ["demolition"], "grenade", { "dmg": 6.0, "rate": 1.4 }, [], [], "BURSTING THROWS. EVERY 6TH CALLS A METEOR DOWN ON A FOE.", [{ "on": "every_n_shots", "every": 6, "do": [["meteor", 1.2, 24]] }], "w_tickbomb"],
	["escapement", "ESCAPEMENT RIFLE", "bolt", "epic", ["edge"], "rifle", { "dmg": 7.0, "rate": 1.8, "speed": 340, "pierce": 3 }, [["crit", 0.12]], [], "+12% CRIT. SHOTS THAT TICK THROUGH THREE FOES.", [], "w_escapement"],
	["enginecore", "ENGINE CORE", "orb", "legend", ["pyre", "storm"], "orbstaff", { "dmg": 6.0, "rate": 2.6 }, [["burn", 0.2]], [["nth_nova", 5]], "THE GREAT ENGINE'S HEART. BURNING BOLTS, AND EVERY 5TH ERUPTS IN A RING OF FIRE.", [], "w_enginecore"],
	["glacierheart", "GLACIER HEART", "orb", "legend", ["storm"], "orbstaff", { "dmg": 6.0, "rate": 2.6 }, [["chill", 0.4]], [["nth_zap", 4]], "THE GLACIAL MAW'S HEART. CHILLING BOLTS, AND EVERY 4TH CALLS DOWN LIGHTNING.", [], "w_glacierheart"],   # 7.3
	# 9.3 the second guardians' weapons.
	# 12.4 Chapter II's guardians (boss_loot.gd).
	["inkspout", "THE INKSPOUT", "orb", "legend", ["arcane", "malice"], "orbstaff", { "dmg": 5.5, "rate": 3.0 }, [["echo", 0.15]], [["nth_nova", 4]], "THE LEVIATHAN'S OWN. 15% OF SHOTS ECHO. EVERY 4TH SHOT BURSTS INTO A RING.", [], "w_inkspout"],
	# 20.3 Chapter IV's guardian drops.
	["hushbell", "THE HUSH BELL", "pulse", "legend", ["arcane", "shadow"], "lanternw", { "dmg": 9.0, "rate": 1.5 }, [], [], "IT RINGS SILENCE. 20% OF ITS HITS STUN. EVERY 3RD RING ERASES THE SHOTS NEAR YOU.", [{ "on": "on_hit", "chance": 0.2, "do": [["status", "stun", 1]] }, { "on": "every_n_shots", "every": 3, "do": [["clear_shots", 70]] }], "w_hushbell"],
	["redpen", "THE RED PEN", "beam", "legend", ["malice", "edge"], "wand", { "dmg": 7.5, "rate": 2.4 }, [["curse", 0.3]], [], "IT CROSSES OUT. 30% OF HITS CURSE. FOES IT FINISHES BURST INTO RED INK FOR 100%.", [{ "on": "on_kill", "do": [["explode", 34, 1.0]] }], "w_redpen"],
	["authorspen", "THE AUTHOR'S PEN", "orb", "legend", ["arcane", "storm"], "staff", { "dmg": 8.0, "rate": 2.6, "homing": 0.6 }, [["echo", 0.25]], [["nth_zap", 4]], "THE LAST WORD. 25% OF SHOTS ARE WRITTEN TWICE. EVERY 4TH CALLS LIGHTNING. EVERY 12TH REWRITES THE FIGHT.", [{ "on": "every_n_shots", "every": 12, "do": [["chaos"]] }], "w_authorspen"],
	["archstaff", "ARCHMAGE'S STAFF", "orb", "legend", ["arcane", "storm"], "orbstaff", { "dmg": 7.0, "rate": 2.4 }, [], [["nth_zap", 3]], "THE TOWER'S OWN. EVERY 3RD BOLT CALLS LIGHTNING.", [], "w_archstaff"],
	["wyrmfang", "WYRMFANG", "slash", "legend", ["frost", "edge"], "sword", { "dmg": 11.0, "rate": 2.0 }, [["chill", 0.35]], [], "A FANG OF WHITE ICE. CHILLS WHAT IT CUTS.", [], "w_wyrmfang"],
	["seraphlance", "SERAPH'S LANCE", "rail", "legend", ["arcane"], "rifle", { "dmg": 18.0, "rate": 1.2, "pierce": 3 }, [], [["nth_nova", 3]], "LIGHT ITSELF. EVERY 3RD SHOT BURSTS INTO A RING.", [], "w_seraphlance"],
	["highcaliber", "THE HIGH CALIBER", "rail", "legend", ["edge", "demolition"], "cannon", { "dmg": 30.0, "rate": 0.8 }, [["pierce", 2]], [], "ONE ENORMOUS ROUND THAT PIERCES. EVERY HIT ON THE LAST FOE IN A ROOM STRIKES AGAIN FOR 150%.", [{ "on": "on_hit", "if": "last_foe", "do": [["damage", 1.5]] }], "w_longrifle"],
	# Stage 23 THE SPELLBOOK (his word, 8 Oct: "more magic weapons with super cool effects"): two of each new kind of spell,
	# the second with a twist (spells.gd).
	["pocketvoid", "POCKET VOID", "singularity", "rare", ["shadow"], "orbstaff", { "dmg": 5.0, "rate": 1.0 }, [], [], "A DARK MOTE. ON THE FIRST FOE IT BECOMES A BLACK HOLE THAT DRAGS FOES IN, THEN COLLAPSES IN A BLAST THAT GROWS WITH EVERY FOE IT HELD."],
	["eventhorizon", "EVENT HORIZON", "singularity", "legend", ["shadow", "arcane"], "orbstaff", { "dmg": 7.5, "rate": 0.9, "devour": true, "radius": 60 }, [], [], "A WIDER BLACK HOLE THAT ALSO EATS ENEMY SHOTS. EVERY SHOT IT EATS MAKES THE COLLAPSE HARDER."],
	["emberwyrm", "EMBER WYRM ROD", "serpent", "rare", ["pyre"], "staff", { "dmg": 3.2, "rate": 0.8 }, [], [], "CALLS A SERPENT OF FIRE THAT HUNTS FOES FOR 3 SECONDS, BURNING ALL ITS BODY TOUCHES AND LEAVING FLAMES BEHIND."],
	["rimeserpent", "RIME SERPENT", "serpent", "epic", ["frost"], "staff", { "dmg": 4.0, "rate": 0.75, "coil": true }, [], [], "A SERPENT OF ICE THAT CHILLS ALL IT TOUCHES AND COILS AROUND A FOE TO CRUSH IT."],
	["cometscepter", "COMET SCEPTER", "comet", "rare", ["pyre", "arcane"], "wand", { "dmg": 9.0, "rate": 0.8 }, [], [], "A COMET CROSSES THE ROOM THROUGH THE FOE YOU AIM AT, BURNING ALL ON ITS PATH, AND BURSTS WHERE IT STRIKES."],
	["starfallen", "THE STARFALLEN", "comet", "legend", ["arcane", "storm"], "wand", { "dmg": 8.0, "rate": 0.7, "shower": 3 }, [], [], "A SHOWER OF THREE COMETS, EACH THROUGH A DIFFERENT FOE."],
	["runechalk", "RUNE CHALK", "glyph", "common", ["arcane"], "wand", { "dmg": 6.5, "rate": 1.3 }, [], [], "DRAWS A RUNE UNDER THE FOE YOU AIM AT. IT ERUPTS IN A PILLAR OF LIGHT THAT STUNS. EVERY 4TH RUNE IS A GREAT ONE."],
	["sundersigil", "SIGIL OF SUNDERING", "glyph", "epic", ["arcane", "malice"], "tome", { "dmg": 6.0, "rate": 1.2, "twice": true }, [], [], "EVERY RUNE ERUPTS TWICE AND LEAVES FOES VULNERABLE. EVERY 4TH IS A GREAT ONE."],
	["dancingsteel", "DANCING STEEL", "blades", "rare", ["edge", "arcane"], "sword", { "dmg": 3.0, "rate": 1.0 }, [], [], "EACH CAST CONJURES A SPECTRAL BLADE THAT HUNTS AND CUTS FOES BY ITSELF FOR 4 SECONDS. UP TO SIX AT ONCE."],
	["thousandedges", "THE THOUSAND EDGES", "blades", "epic", ["edge", "storm"], "sword", { "dmg": 3.5, "rate": 1.1, "waves": true }, [], [], "SPECTRAL BLADES, AND EVERY CUT THROWS A WAVE OF STEEL."],
	["stopwatch", "STOPWATCH WAND", "chrono", "rare", ["arcane", "frost"], "wand", { "dmg": 4.0, "rate": 0.5 }, [], [], "STOPS TIME IN A CIRCLE: FOES FREEZE AND THEIR SHOTS HANG IN THE AIR. WHEN TIME CATCHES UP, THE FOES IT HELD TAKE A BLOW."],
	["aeonglass", "HOURGLASS OF AEONS", "chrono", "legend", ["arcane", "storm"], "orb", { "dmg": 5.0, "rate": 0.5, "reverse": true, "radius": 70 }, [], [], "A WIDER CIRCLE OF STOPPED TIME. WHEN IT ENDS, THE SHOTS IT HELD FLY BACK AT YOUR FOES."],
	["kaleidoscope", "KALEIDOSCOPE", "prism", "rare", ["arcane", "frost"], "wand", { "dmg": 4.5, "rate": 1.6 }, [], [], "A CRYSTAL BOLT THAT SPLITS ON A HIT INTO RED, BLUE AND GREEN BOLTS THAT BURN, CHILL AND POISON, AND THEY SPLIT AGAIN."],
	["fractalcrown", "FRACTAL CROWN", "prism", "epic", ["arcane", "venom"], "orb", { "dmg": 5.0, "rate": 1.6, "fractal": true }, [], [], "PRISM BOLTS THAT SPLIT THREE TIMES OVER: ONE BECOMES TWENTY-SEVEN."],
	["cloudherd", "CLOUDHERD'S CROOK", "cloud", "rare", ["storm"], "staff", { "dmg": 4.0, "rate": 0.45 }, [], [], "CALLS A STORM CLOUD THAT FOLLOWS FOES FOR 4 SECONDS, STRIKING LIGHTNING AND RAINING ICE ON WHAT IS UNDER IT. UP TO THREE."],
	["tempestcore", "TEMPEST CORE", "cloud", "epic", ["storm", "frost"], "orb", { "dmg": 5.0, "rate": 0.45, "tornado": true }, [], [], "STORM CLOUDS THAT SPIN TORNADOES: FOES ARE DRAGGED UNDER THE LIGHTNING, AND FLUNG WHEN IT ENDS."],
	["pinballwand", "ARCANE PINBALL", "pinball", "common", ["arcane", "fortune"], "wand", { "dmg": 2.0, "rate": 1.0 }, [], [], "A BALL OF LIGHT THAT BOUNCES FROM FOE TO FOE 6 TIMES, FASTER AND 10% HARDER EACH TIME. WALLS SEND IT BACK."],
	["orrery", "STARBOUND ORRERY", "pinball", "epic", ["arcane", "storm"], "orb", { "dmg": 2.5, "rate": 1.0, "stars": true, "max": 10 }, [], [], "A PINBALL THAT BOUNCES 10 TIMES, AND EVERY BOUNCE THROWS A SEEKING STAR."],
	["wildsurge", "WAND OF WILD SURGE", "wild", "rare", ["arcane", "fortune"], "wand", { "dmg": 5.0, "rate": 1.1 }, [], [], "EVERY CAST A DIFFERENT SPELL: FIREBALL, ICE, LIGHTNING, MIASMA, GOLD, A SHEEP, A HEAL, A VOID OR A SMITE."],
	["chaoscodex", "THE CHAOS CODEX", "wild", "legend", ["arcane", "malice"], "tome", { "dmg": 7.0, "rate": 1.1, "double": true }, [], [], "WILD MAGIC: TWO DIFFERENT SPELLS AT ONCE, EVERY CAST."],
	# Stage 25 (his word, 9 Oct: "add more cool traits and magic weapons also melee weapons"): several carry two
	# ailments at once, which react (reactions.gd).
	["moonwell", "MOONWELL", "singularity", "epic", ["shadow", "storm"], "orbstaff", { "dmg": 6.0, "rate": 0.9, "devour": true }, [], [["nth_zap", 3]], "A BLACK HOLE THAT EATS ENEMY SHOTS. EVERY 3RD CAST ALSO CALLS LIGHTNING."],
	["hydrarod", "HYDRA'S ROD", "serpent", "legend", ["pyre", "venom"], "staff", { "dmg": 3.5, "rate": 0.8 }, [], [], "A SERPENT OF FIRE WHOSE BITES ALSO POISON: FIRE AND POISON MEET IN A TOXIC BLAST.", [{ "on": "on_hit", "chance": 0.3, "do": [["status", "poison", 2]] }]],
	["skyfall", "SKYFALL STAFF", "comet", "epic", ["pyre", "demolition"], "staff", { "dmg": 9.0, "rate": 0.7 }, [], [], "COMETS, AND EVERY 4TH CAST ALSO DROPS A METEOR ON A FOE.", [{ "on": "every_n_shots", "every": 4, "do": [["meteor", 2.0, 30]] }]],
	["stormsigil", "STORM SIGIL", "glyph", "rare", ["storm", "arcane"], "wand", { "dmg": 6.0, "rate": 1.3 }, [], [["nth_zap", 2]], "RUNES THAT ERUPT, AND EVERY 2ND CALLS LIGHTNING TOO."],
	["timewarp", "TIMEWARP SCEPTER", "chrono", "epic", ["frost", "arcane"], "wand", { "dmg": 5.0, "rate": 0.55, "radius": 64 }, [], [], "STOPPED TIME, AND ITS BLOW CHILLS HALF THE TIME.", [{ "on": "on_hit", "chance": 0.5, "do": [["status", "chill", 2]] }]],
	["rainbowstaff", "RAINBOW STAFF", "prism", "legend", ["arcane", "pyre"], "orb", { "dmg": 5.5, "rate": 1.7, "fractal": true }, [["crit", 0.1]], [], "PRISM BOLTS THAT SPLIT THREE TIMES. +10% CRIT. THEIR BURN AND CHILL MELT FOES."],
	["skybreaker", "SKYBREAKER ORB", "cloud", "legend", ["storm", "frost"], "orb", { "dmg": 5.5, "rate": 0.5, "tornado": true }, [], [["nth_zap", 2]], "STORM CLOUDS WITH TORNADOES. EVERY 2ND CAST CALLS LIGHTNING. 25% SHOCK. ICE AND SHOCK SHATTER FOES.", [{ "on": "on_hit", "chance": 0.25, "do": [["status", "shock", 1]] }]],
	["luckystar", "LUCKY STAR", "pinball", "rare", ["fortune", "arcane"], "orb", { "dmg": 2.5, "rate": 1.1, "max": 8 }, [], [], "A PINBALL OF LIGHT THAT BOUNCES 8 TIMES. 20% OF ITS KILLS DROP A COIN.", [{ "on": "on_kill", "chance": 0.2, "do": [["drop", "coin"]] }]],
	["stormfire", "STORMFIRE ROD", "orb", "epic", ["pyre", "storm"], "staff", { "dmg": 5.5, "rate": 2.6 }, [["burn", 0.3]], [], "BURNING BOLTS, AND 30% SHOCK: FIRE AND SHOCK OVERLOAD INTO LIGHTNING.", [{ "on": "on_hit", "chance": 0.3, "do": [["status", "shock", 1]] }]],
	["thunderfang", "THUNDERFANG", "slash", "epic", ["storm", "edge"], "sword", { "dmg": 9.0, "rate": 2.2 }, [], [["nth_zap", 3]], "A SWORD OF STORM. EVERY 3RD SWING CALLS LIGHTNING."],
	["frostbrand", "FROSTBRAND", "slash", "rare", ["frost", "edge"], "sword", { "dmg": 8.0, "rate": 2.0 }, [["chill", 0.4]], [], "40% OF CUTS CHILL. 30% OF KILLS CHILL THE FOES AROUND.", [{ "on": "on_kill", "chance": 0.3, "do": [["status_area", "chill", 2, 60], ["vfx", "ring", "#6fd3e0", 60]] }]],
	["voidscythe", "VOID SCYTHE", "slash", "legend", ["shadow", "malice"], "sword", { "dmg": 12.0, "rate": 1.6, "arc": 160 }, [["curse", 0.25]], [], "A WIDE REAPING ARC. 25% OF CUTS CURSE. 15% PULL THE FOES AROUND IN.", [{ "on": "on_hit", "chance": 0.15, "cd": 0.5, "do": [["pull", 90, 200]] }]],
	["emberpike", "EMBER PIKE", "thrust", "rare", ["pyre"], "spear", { "dmg": 7.0, "rate": 2.2 }, [["burn", 0.3]], [["nth_nova", 5]], "A BURNING SPEAR. 30% OF THRUSTS BURN. EVERY 5TH BURSTS INTO A RING."],
	["quakehammer", "QUAKE HAMMER", "slam", "legend", ["fury", "demolition"], "hammer", { "dmg": 14.0, "rate": 0.8 }, [], [], "HOLD TO SLAM. EVERY 5TH HIT ERUPTS FOR 200%.", [{ "on": "on_hit", "every": 5, "do": [["explode", 60, 2.0]] }]],
	["serpentlash", "SERPENT LASH", "whip", "rare", ["venom", "malice"], "whip", { "dmg": 5.5, "rate": 2.2 }, [["poison", 1], ["curse", 0.2]], [], "A LASH THAT POISONS, AND 20% CURSE: POISON AND CURSE WITHER FOES."],
	["twinfangs", "TWIN FANGS", "stab", "epic", ["edge", "blood"], "dagger", { "dmg": 4.5, "rate": 4.5 }, [["crit", 0.15]], [], "+15% CRIT. 25% OF CRITS OPEN A BLEEDING WOUND.", [{ "on": "on_crit", "chance": 0.25, "do": [["status", "bleed", 1]] }]],
	["giantsbane", "GIANTSBANE", "bat", "epic", ["fury"], "club", { "dmg": 11.0, "rate": 1.1 }, [], [["boss_dmg", 0.5], ["elite_dmg", 0.5]], "KNOCKS FOES FLYING. +50% DAMAGE TO ELITES AND GUARDIANS."],
	["steamblade", "STEAMFORGED BLADE", "slash", "legend", ["pyre", "frost"], "sword", { "dmg": 10.0, "rate": 2.0 }, [["burn", 0.3], ["chill", 0.3]], [], "IT BURNS AND IT CHILLS: FIRE AND ICE MELT FOES FOR 300%."],
	# Stage 27 (his word, 9 Oct: "can we add mythic armors and other weapons"): MYTHIC weapons, then more of other kinds.
	["worldender", "WORLD-ENDER", "rocket", "mythic", ["demolition", "pyre"], "launcher", { "dmg": 20.0, "rate": 0.8 }, [], [], "ROCKETS THAT BLOW FOES APART. EVERY 3RD HIT CALLS A COMET DOWN.", [{ "on": "on_hit", "every": 3, "do": [["spell", "comet", 2.0]] }]],
	["dawnbow", "BOW OF THE DAWN GOD", "bolt", "mythic", ["arcane", "edge"], "bow", { "dmg": 7.0, "rate": 4.5, "pierce": 3 }, [["crit", 0.2]], [], "ARROWS OF LIGHT THAT PIERCE THREE FOES. +20% CRIT. EVERY 6TH CRIT BURSTS INTO PRISM BOLTS.", [{ "on": "on_crit", "every": 6, "do": [["spell", "prism", 1.0]] }]],
	["eternityedge", "ETERNITY'S EDGE", "slash", "mythic", ["arcane", "frost"], "sword", { "dmg": 16.0, "rate": 2.0 }, [["chill", 0.3]], [], "EVERY 4TH SWING STOPS TIME AROUND THE FOE. 30% CHILL.", [{ "on": "every_n_shots", "every": 4, "do": [["spell", "clock", 1.5]] }]],
	["abyssstaff", "STAFF OF THE ABYSS", "singularity", "mythic", ["shadow", "malice"], "orbstaff", { "dmg": 9.0, "rate": 1.0, "devour": true, "radius": 70 }, [["curse", 0.3]], [], "HUGE BLACK HOLES THAT EAT SHOTS. 30% CURSE. A QUARTER OF ITS KILLS OPEN ANOTHER.", [{ "on": "on_kill", "chance": 0.25, "do": [["spell", "void", 1.5]] }]],
	["dragonlance", "DRAGONLORD'S LANCE", "thrust", "mythic", ["pyre", "fury"], "spear", { "dmg": 14.0, "rate": 2.0 }, [["burn", 0.5]], [], "A LANCE OF DRAGONFIRE. 50% BURN. EVERY 3RD THRUST SENDS A FIRE SERPENT.", [{ "on": "every_n_shots", "every": 3, "do": [["spell", "serpent", 1.2]] }]],
	["thunderking", "SCEPTER OF THE THUNDER KING", "zap", "mythic", ["storm"], "wand", { "dmg": 9.0, "rate": 3.0, "chain": 4 }, [], [["nth_zap", 2]], "LIGHTNING THAT JUMPS 4 TIMES. EVERY 2ND CAST CALLS LIGHTNING, EVERY 6TH A STORM CLOUD.", [{ "on": "every_n_shots", "every": 6, "do": [["spell", "cloud", 1.5]] }]],
	["starshell", "STARSHELL MORTAR", "mortar", "legend", ["pyre", "demolition"], "mortar", { "dmg": 12.0, "rate": 0.9 }, [], [], "LOBBED SHELLS. 20% OF HITS CALL A COMET.", [{ "on": "on_hit", "chance": 0.2, "cd": 0.5, "do": [["spell", "comet", 1.0]] }]],
	["frostfoam", "FROSTFOAM GUN", "bubble", "epic", ["frost"], "blaster", { "dmg": 5.0, "rate": 1.8 }, [["chill", 0.5]], [], "BUBBLES THAT TRAP FOES, AND HALF THE TIME CHILL THEM."],
	["runedeck", "DECK OF RUNES", "deck", "epic", ["arcane"], "cards", { "dmg": 5.0, "rate": 2.0 }, [], [], "A DECK OF CARDS. EVERY 5TH CARD PLAYED DRAWS A RUNE UNDER A FOE.", [{ "on": "every_n_shots", "every": 5, "do": [["spell", "glyph", 1.5]] }]],
	["spectralrepeater", "SPECTRAL REPEATER", "gatling", "legend", ["edge", "arcane"], "minigun", { "dmg": 2.0, "rate": 6.0 }, [], [], "A CHATTERING GUN THAT SPEEDS UP. EVERY 25TH SHOT CONJURES A SPECTRAL BLADE.", [{ "on": "every_n_shots", "every": 25, "do": [["spell", "blade", 1.0]] }]],
	["viperbow", "VIPER'S BOW", "bolt", "epic", ["venom"], "bow", { "dmg": 4.0, "rate": 4.0 }, [["poison", 1]], [], "POISONED ARROWS. 10% OF HITS LET LOOSE A FIRE SERPENT (AT MOST EVERY SECOND).", [{ "on": "on_hit", "chance": 0.1, "cd": 1.0, "do": [["spell", "serpent", 0.6]] }]],
	["voidhammer", "HAMMER OF THE VOID", "slam", "legend", ["shadow", "fury"], "hammer", { "dmg": 16.0, "rate": 0.8 }, [], [], "HOLD TO SLAM. EVERY 4TH HIT OPENS A BLACK HOLE.", [{ "on": "on_hit", "every": 4, "do": [["spell", "void", 1.5]] }]],
	# Stage 31 THE TOYBOX (his word, 9 Oct: "add more fun and crazy weapons with cool effects and new effects 20+"):
	# a weapon of each new kind (toys.gd), one with each twist, and crazy ones that let toys loose (the action "toy").
	["landshark", "LAND SHARK LAUNCHER", "shark", "rare", ["fury", "edge"], "launcher", { "dmg": 6.0, "rate": 0.8 }, [], [], "A FIN SWIMS UNDER THE FLOOR TO A FOE, LEAPS OUT AND BITES. 3 BITES.", []],
	["twisterfan", "TWISTER FAN", "twister", "rare", ["storm"], "orbstaff", { "dmg": 5.0, "rate": 0.5 }, [], [], "A TWISTER THAT LIFTS FOES, SPINS THEM ROUND AND SLAMS THEM DOWN.", []],
	["discostaff", "DISCO STAFF", "disco", "rare", ["arcane"], "orb", { "dmg": 4.0, "rate": 0.9 }, [], [], "A MIRROR BALL OVER YOU. ITS BEAMS HURT FOES AND MAKE THEM DANCE.", []],
	["steelyoyo", "STEEL YO-YO", "yoyo", "rare", ["edge"], "fists", { "dmg": 5.0, "rate": 1.6 }, [], [], "OUT AND BACK ON A STRING THAT CUTS. IT SPINS AT THE FAR END.", []],
	["portalgun", "PORTAL PISTOL", "portal", "rare", ["arcane", "edge"], "pistol", { "dmg": 6.0, "rate": 1.4 }, [], [], "SHOTS GO INTO A PORTAL AND COME OUT BEHIND THE FOE FOR +50%.", []],
	["sawlauncher", "SAW LAUNCHER", "saw", "rare", ["edge", "demolition"], "chakram", { "dmg": 4.0, "rate": 1.2 }, [], [], "SAW BLADES BOUNCE ONCE, THEN DIG IN AS SPINNING TRAPS.", []],
	["stitcheddoll", "STITCHED DOLL", "voodoo", "rare", ["malice"], "rune", { "dmg": 5.0, "rate": 1.8 }, [], [], "PINS STICK IN FOES. A PINNED FOE TAKES 35% OF WHAT ANY OTHER PINNED FOE TAKES.", []],
	["skyanvil", "SKY ANVIL", "anvil", "rare", ["demolition", "bulwark"], "hammer", { "dmg": 14.0, "rate": 0.6 }, [], [], "AN ANVIL FALLS ON THE FOE AND STUNS IT, THEN STAYS 5S AS COVER FROM SHOTS.", []],
	["megalodon", "MEGALODON", "shark", "legend", ["fury", "blood"], "cannon", { "dmg": 7.0, "rate": 0.8, "frenzy": true }, [["bleed", 1]], [], "A GREAT SHARK: 6 BITES, EACH 15% HARDER. CRITS MAKE FOES BLEED.", []],
	["sharknado", "SHARKNADO", "twister", "mythic", ["storm", "fury"], "staff", { "dmg": 7.0, "rate": 0.55, "life": 3.2, "sharks": true }, [], [], "A TWISTER FULL OF SHARKS. THEY DROP OUT ON YOUR FOES AS IT SPINS.", []],
	["discoinferno", "DISCO INFERNO", "disco", "legend", ["arcane", "pyre"], "orb", { "dmg": 4.5, "rate": 1.0, "party": true }, [["burn", 0.4]], [], "TWICE THE BEAMS, SPINNING FASTER. 40% OF HITS BURN.", []],
	["twinyoyos", "TWIN YO-YOS", "yoyo", "epic", ["edge", "shadow"], "fists", { "dmg": 5.0, "rate": 1.7, "twin": true }, [["crit", 0.1]], [], "TWO YO-YOS AT ONCE. +10% CRIT.", []],
	["gatecannon", "GATEWAY CANNON", "portal", "legend", ["arcane", "shadow"], "handcannon", { "dmg": 7.0, "rate": 1.2, "rift": true }, [], [], "THE FAR PORTAL STAYS OPEN AND FIRES 3 TIMES.", []],
	["hungrysaws", "HUNGRY SAWS", "saw", "epic", ["edge", "fury"], "chakram", { "dmg": 4.5, "rate": 1.3, "magnet": true }, [], [], "SAW TRAPS THAT CREEP TOWARD YOUR FOES.", []],
	["doomdoll", "DOOM DOLL", "voodoo", "legend", ["malice", "blood"], "skullstaff", { "dmg": 6.0, "rate": 1.8, "doom": true }, [], [], "PINNED FOES ARE CURSED AND SHARE 60% OF THEIR PAIN.", []],
	["grandpiano", "GRAND PIANO", "anvil", "legend", ["demolition", "arcane"], "tome", { "dmg": 18.0, "rate": 0.55, "piano": true }, [], [], "A GRAND PIANO FROM THE SKY: A WIDER CRUSH, AND 8 NOTES FLY OUT.", []],
	["fishslapper", "THE FISH SLAPPER", "slash", "epic", ["fury", "frost"], "sword", { "dmg": 9.0, "rate": 2.0 }, [["chill", 0.2]], [], "A FROZEN FISH. EVERY 6TH SLAP CALLS A LAND SHARK. 20% OF HITS CHILL.", [{ "on": "every_n_shots", "every": 6, "do": [["toy", "shark", 1.0]] }]],
	["rubberchicken", "RUBBER CHICKEN", "bat", "epic", ["fortune", "fury"], "axe", { "dmg": 8.0, "rate": 1.6 }, [], [], "SQUEAK! KNOCKS FOES FLYING. 20% OF HITS STUN THE FOE.", [{ "on": "on_hit", "chance": 0.2, "cd": 0.2, "do": [["status", "stun", 1], ["vfx", "label", "SQUEAK!", "#f2c94c"]] }]],
	["confetticannon", "CONFETTI CANNON", "shot", "rare", ["fortune", "arcane"], "blunderbuss", { "dmg": 2.5, "rate": 1.5 }, [], [], "A SPRAY OF CONFETTI. KILLS POP INTO 6 MORE BITS.", [{ "on": "on_kill", "do": [["nova", 6, 0.5, "spark"]] }]],
	["pinatastick", "PINATA STICK", "bat", "rare", ["fortune"], "staff", { "dmg": 7.0, "rate": 1.5 }, [], [], "8% OF HITS SHAKE A COIN OUT OF THE FOE. 5% OF KILLS DROP A HEART.", [{ "on": "on_hit", "chance": 0.08, "do": [["drop", "coin"]] }, { "on": "on_kill", "chance": 0.05, "do": [["drop", "heart"]] }]],
	["stormjar", "BOTTLED TWISTER", "flask", "epic", ["storm"], "flaskw", { "dmg": 7.0, "rate": 1.0 }, [], [], "BURSTING JARS. EVERY 4TH THROW LETS A TWISTER OUT.", [{ "on": "every_n_shots", "every": 4, "do": [["toy", "twister", 0.9]] }]],
	["smithsrevenge", "BLACKSMITH'S REVENGE", "slam", "legend", ["demolition", "bulwark"], "hammer", { "dmg": 16.0, "rate": 0.8 }, [], [], "HOLD TO SLAM. EVERY SLAM CALLS 3 ANVILS DOWN ON FOES.", [{ "on": "on_shoot", "do": [["toy", "anvil", 0.8], ["toy", "anvil", 0.8], ["toy", "anvil", 0.8]] }]],
	["partyhorn", "PARTY HORN", "wave", "rare", ["arcane", "fortune"], "sprayer", { "dmg": 5.0, "rate": 1.2 }, [], [], "A BLAST OF NOISE. EVERY 5TH TOOT DROPS A DISCO BALL OVER YOU.", [{ "on": "every_n_shots", "every": 5, "do": [["toy", "disco", 0.7]] }]],
	["cursedcrossbow", "CURSED CROSSBOW", "bolt", "epic", ["malice", "edge"], "crossbow", { "dmg": 6.0, "rate": 2.2 }, [], [], "BOLTS THAT PIN: 15% OF HITS STICK A VOODOO PIN IN THE FOE.", [{ "on": "on_hit", "chance": 0.15, "do": [["toy", "pin", 1.0]] }]],
	["portalbow", "BOW OF ELSEWHERE", "bolt", "legend", ["arcane", "shadow"], "bow", { "dmg": 6.0, "rate": 2.4, "pierce": 1 }, [["crit", 0.1]], [], "ARROWS. EVERY 3RD ONE ALSO COMES OUT OF A PORTAL BEHIND THE FOE.", [{ "on": "every_n_shots", "every": 3, "do": [["toy", "portal", 0.8]] }]],
	["buzzblade", "BUZZ BLADE", "slash", "rare", ["edge", "demolition"], "greatsword", { "dmg": 10.0, "rate": 1.6 }, [], [], "A SPINNING BLADE. EVERY 4TH SWING LEAVES A SAW TRAP ON THE FOE.", [{ "on": "every_n_shots", "every": 4, "do": [["toy", "saw", 0.8]] }]],
]

static var _by_id := {}
static var _list: Array = []

## Weapon dictionaries: ARCH defaults merged with the row (Ruby wpn()).
static func all() -> Array:
	if _list.is_empty():
		# --classic: original items only (proves the originals play exactly as before).
		for i in (ORIGINAL_COUNT if DebugArgs.has("classic") else ROWS.size()):
			var row: Array = ROWS[i]
			var w: Dictionary = ARCH[row[2]].duplicate()
			w.merge(row[6], true)
			w.merge({ "id": row[0], "name": row[1], "kind": row[2], "rarity": row[3], "tags": row[4], "shape": row[5],
				"stats": row[7], "hooks": row[8], "desc": row[9], "item": "weapon", "new": i >= ORIGINAL_COUNT,
				"effects": row[10] if row.size() > 10 else [],
				"sprite": row[11] if row.size() > 11 else "w_" + row[0],
				"cols": TAG_COLS[row[4][0] if row[4].size() > 0 else "core"] }, true)
			_list.append(w)
			_by_id[w["id"]] = w
	return _list

static func by_id(id: String) -> Dictionary:
	all()
	return _by_id[id]

## Found only one way (brazil.gd): never in a chest, a shop or a drop.
const UNIQUE := ["cowmilker", "hagglerbargain"]

static func random_weapon(rarity: String, exclude: Variant = null) -> Dictionary:
	var pool := []
	for w in all():
		if w["rarity"] == rarity and not (exclude != null and w["id"] == exclude["id"]) and not HERO_WEAPON.values().has(w["id"]) \
				and not w["id"] in UNIQUE and not BossLoot.is_unique(w["id"]) and not Dice.banned(w["id"]):   # 35.1
			pool.append(w)
	if pool.is_empty():
		for w in all():
			if w["rarity"] == rarity:
				pool.append(w)
	return TB.pick(pool)

## Rough power of a weapon, for the "BASE POWER" comparison in prompts.
static func weapon_dps(w: Dictionary) -> float:
	var base: float = w["dmg"] * w["rate"] * maxi(1, w["count"])
	if w["kind"] == "burst": base *= 3
	if w["kind"] == "gatling": base *= 2
	if w["kind"] == "boomer": base *= 2
	if Spells.handles(w["kind"]): base *= Spells.POWER[w["kind"]]   # 23.1: a spell hits many times a cast
	if Toys.handles(w["kind"]): base *= Toys.POWER[w["kind"]]   # 31: so does a toy
	return base

# ---------- Weapon-based stats (04b_items.rb) ----------
static func synergy_mult(p: Player) -> float:
	var w = p.weapon
	if w == null or w["tags"].is_empty():
		return 1.0
	var ranks := 0
	for t in w["tags"]:
		ranks += p.fam.get(t, 0)
	var pieces := 0
	for gi in p.gear.values():
		if gi == null:
			continue
		for t in gi["tags"]:
			if t in w["tags"]:
				pieces += 1
				break
	return 1 + minf(0.08 * ranks, 0.64) + 0.12 * pieces

static func wdmg(p: Player) -> float: return p.weapon["dmg"] * p.dmg * synergy_mult(p) * Attributes.mult(p) * WeaponInfo.upgrade_mult(p.weapon) * Tipsy.dmg_mult(p) * Pace.dmg_mult() * (1.0 + p.g("dmg_per_good") * p.al_good)
static func wrate(p: Player) -> float:
	var r: float = p.weapon["rate"] * p.rate
	if p.weapon["kind"] == "gatling":
		r *= 1 + 2 * p.spin
	if p.haste_t > 0:
		r *= 1.2
	if p.tipsy > 0 or p.g("rate_per_str") > 0:   # 33.2 THE TAVERN: tipsy, and the Tavern Knight's STR
		r *= Tipsy.rate_mult(p) * (1.0 + p.g("rate_per_str") * p.a_str)
	if p.g("rate_per_dex") > 0:   # 34.1 QUICK FINGERS
		r *= 1.0 + p.g("rate_per_dex") * p.a_dex
	if p.g("rate_per_law") > 0:   # 38.1 MAGISTRATE'S SEAL
		r *= 1.0 + p.g("rate_per_law") * p.al_law
	return r
static func wspd(p: Player) -> float: return p.weapon["speed"] * p.shot_speed
static func wlife(p: Player) -> float: return p.weapon["life"] * p.life
static func wsize(p: Player) -> float: return p.weapon["size"] * p.size
static func wpierce(p: Player) -> int: return p.weapon["pierce"] + p.pierce
static func wcount(p: Player) -> int: return maxi(1, p.weapon["count"] + p.count)
static func wspread(p: Player) -> float: return p.spread if p.spread != null else float(p.weapon["spread"])
static func whoming(p: Player) -> float: return p.weapon["homing"] + p.homing
static func wbounce(p: Player) -> int: return p.weapon.get("bounce", 0) + p.bounce
static func wrange(p: Player) -> float:
	return p.weapon.get("range", 40) * (0.85 + 0.15 * p.size) * sqrt(p.life)

# ---------- Equipping (fully reversible) ----------
## Original stat tuples go through the effect system (Effects.from_tuples
## keeps the 04b rules: MUL_KEYS multiply, ONCE_KEYS are granted once, the rest add).
static func apply_tuples(p: Player, tuples: Array, dir: int, src: String = "") -> void:
	Effects.apply_equipment(p, Effects.from_tuples(tuples), dir, src)

static func apply_hooks(p: Player, hooks: Array, dir: int) -> void:
	Effects.apply(p, Effects.from_tuples([], hooks), dir)

## Equips a weapon and returns the old one (or null).
static func equip_weapon(p: Player, w: Dictionary) -> Variant:
	var old = p.weapon
	if old != null:
		apply_tuples(p, old["stats"], -1, "w:" + old["id"])
		apply_hooks(p, old["hooks"], -1)
		if not old["effects"].is_empty():
			Effects.apply_equipment(p, old["effects"], -1, "wfx:" + old["id"])
	p.weapon = w
	apply_tuples(p, w["stats"], 1, "w:" + w["id"])
	apply_hooks(p, w["hooks"], 1)
	if not w["effects"].is_empty():
		Effects.apply_equipment(p, w["effects"], 1, "wfx:" + w["id"])
	p.spin = 0.0
	Meta.meta["found_w"][w["id"]] = true
	if w["new"] or (old != null and old["new"]):
		Effects.recount_tags(p)
	if old != null:
		Effects.fire("on_weapon_swap")
	return old
