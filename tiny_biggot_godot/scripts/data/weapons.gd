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
}
const ARCH_DESC := {
	"bolt": "FIRES FAST BOLTS", "orb": "HOMING BOLTS", "spin": "SPINNING THROWS THAT PIERCE", "shot": "A SPREAD OF SHOT",
	"flask": "BURSTING THROWS", "boomer": "FLIES OUT AND BACK, HITTING TWICE", "slash": "MELEE ARC IN FRONT OF YOU",
	"thrust": "MELEE THRUST THAT PIERCES A LINE", "beam": "A CONSTANT RAY", "flame": "SHORT CONE OF FLAME",
	"disc": "BOUNCES OFF WALLS", "pulse": "SLOW ORB THAT HURTS ALL NEARBY", "zap": "INSTANT ARCS THAT CHAIN",
	"nova": "A RING OF SHOTS AROUND YOU", "mine": "TOSSES MINES THAT BLOW WHEN FOES COME NEAR", "rail": "PIERCING SHOTS AT HUGE SPEED",
	"burst": "THREE-SHOT BURSTS", "gatling": "FIRES FASTER THE LONGER YOU SHOOT", "whip": "LONG LASH, THE TIP ALWAYS CRITS",
	"summon": "EACH SHOT RAISES A SPIRIT WISP",
}
const BULLET_KIND := { "bolt": "bolt", "orb": "hex", "spin": "spin", "shot": "clod", "flask": "flask", "boomer": "boomer",
	"flame": "fire", "disc": "disc", "pulse": "pulse", "nova": "spark", "mine": "mine", "rail": "rail", "burst": "bolt",
	"gatling": "bolt", "summon": "hex" }
const HERO_WEAPON := { "hexer": "hexwand", "poacher": "repeater", "brute": "pithatchet", "gravedigger": "graveshovel",
	"alchemist": "flasksling", "warden": "lantern",
	# Step 6 heroes (signature weapons are rows after content batch 1).
	"banehunter": "banesabre", "oathbreaker": "ironslab", "wayfarer": "wayfareredge", "racketeer": "snubguns",
	"condemned": "shackleflail", "cartomancer": "giltdeck", "sellsword": "warlance" }

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
	["mirrorshard", "SHARDS OF THE MIRROR", "disc", "epic", ["edge"], "rune", { "dmg": 4.0, "rate": 2.4, "count": 2, "spread": 0.4 }, [["crit", 0.2], ["overcrit", 0.5]], [], "+20% CRIT. CRIT CHANCE PAST 100% CAN CRIT A SECOND TIME.", [], "w_nightstar"],
	["truthseeker", "TRUTHSEEKER", "rail", "legend", ["edge"], "rifle", { "dmg": 20.0, "rate": 0.9 }, [["crit", 0.25]], [], "+25% CRIT. EVERY CRIT DETONATES THE TARGET FOR 100% DAMAGE.", [{ "on": "on_crit", "do": [["explode", 30, 1.0]] }], "w_dawnlance"],
	["flayinghook", "FLAYING HOOK", "whip", "common", ["blood"], "whip", { "dmg": 5.0, "rate": 2.1 }, [], [], "A BARBED LASH. 35% OF HITS MAKE FOES BLEED.", [{ "on": "on_hit", "chance": 0.35, "do": [["status", "bleed", 1]] }], "w_chainlash"],
	["sanguinering", "SANGUINE CHAKRAM", "boomer", "rare", ["blood"], "chakram", { "dmg": 4.6, "rate": 2.2, "size": 1.0 }, [], [], "FLIES OUT AND BACK. HITS BLEED. KILLING A BLEEDING FOE MAY HEAL.", [{ "on": "on_hit", "chance": 0.25, "do": [["status", "bleed", 1]] }, { "on": "on_kill", "chance": 0.2, "if": "bleeding", "do": [["heal", 1]] }], "w_razordisc"],
	["pactknives", "PACT KNIVES", "bolt", "rare", ["blood"], "dagger", { "dmg": 2.6, "rate": 3.4, "count": 3, "spread": 0.2 }, [], [], "EACH ROOM BEGINS WITH A BLOOD PRICE: LOSE HALF A HEART, GAIN +60% DAMAGE FOR 10S.", [{ "on": "on_room_enter", "do": [["hurt_self", 1], ["buff", "dmg", 0.6, 10.0]] }], "w_twincrescent"],
	["hemoclaws", "HEMOCLAWS", "slash", "epic", ["blood"], "fists", { "dmg": 3.6, "rate": 5.0, "range": 22, "arc": 90 }, [], [["leech", 0.02]], "TWIN CLAWS. FAST STRIKES, 20% BLEED, 2% OF HITS HEAL.", [{ "on": "on_hit", "chance": 0.2, "do": [["status", "bleed", 1]] }], "w_bonecleaver"],
	["kindlingstaff", "KINDLING STAFF", "orb", "common", ["pyre"], "wand", { "dmg": 3.8, "rate": 3.2 }, [["burn", 0.15]], [], "BOLTS OFTEN BURN. BURNING FOES IT KILLS BURST INTO EMBERS.", [{ "on": "on_kill", "if": "burning", "do": [["explode", 22, 0.6]] }], "w_emberwand"],
	["magmamaul", "MAGMA MAUL", "slash", "rare", ["pyre"], "hammer", { "dmg": 14.0, "rate": 1.1, "range": 36, "arc": 140 }, [["burn", 0.2]], [["knock", 1.8]], "A MOLTEN HAMMER. EVERY 3RD SWING ERUPTS FOR 120% DAMAGE.", [{ "on": "every_n_shots", "every": 3, "do": [["explode", 30, 1.2]] }], "w_gallows"],
	["flarepistol", "FLARE PISTOL", "burst", "rare", ["pyre"], "pistol", { "dmg": 2.8, "rate": 1.7 }, [["burn", 0.3]], [], "SIGNAL FLARES THAT IGNITE. 15% OF HITS POP IN A SMALL BLAST.", [{ "on": "on_hit", "chance": 0.15, "do": [["explode", 18, 0.5]] }], "w_streetpistol"],
	["sunforge", "SUNFORGE HALO", "nova", "epic", ["pyre"], "orbstaff", { "dmg": 3.2, "rate": 1.5, "count": 12 }, [["burn", 0.35]], [], "A RING OF FIRE AROUND YOU. CRITS BURN TWICE AS LONG.", [{ "on": "on_crit", "do": [["status", "burn", 2]] }], "w_cataclysm"],
	["sporelauncher", "SPORE LAUNCHER", "flask", "common", ["venom"], "flaskw", { "dmg": 4.4 }, [["explode", 1], ["poison", 1]], [], "POISON FLASKS. A POISONED FOE IT KILLS INFECTS THE NEAREST FOE.", [{ "on": "on_kill", "if": "poisoned", "do": [["status", "poison", 3]] }], "w_acidjar"],
	["widowneedles", "WIDOW NEEDLES", "bolt", "rare", ["venom"], "crossbow", { "dmg": 1.6, "rate": 7.0, "count": 2, "spread": 0.1 }, [["poison", 1]], [], "A FLURRY OF THIN NEEDLES THAT POISON. EVERY 10TH NEEDLE WEAKENS.", [{ "on": "every_n_shots", "every": 10, "do": [["status", "weakened", 1]] }], "w_nailspitter"],
	["blightcenser", "BLIGHT CENSER", "pulse", "rare", ["venom"], "lanternw", { "dmg": 2.8, "rate": 1.0 }, [["poison", 2]], [["linger", 1.5]], "A HOVERING CLOUD OF ROT THAT POISONS EVERYTHING NEAR IT.", [], "w_plaguebell"],
	["serpentspine", "SERPENT SPINE", "whip", "epic", ["venom"], "whip", { "dmg": 6.0, "range": 80 }, [["poison", 2]], [], "A LONG POISON LASH. POISONED FOES IT HITS MAY TURN VULNERABLE.", [{ "on": "on_hit", "chance": 0.25, "if": "poisoned", "do": [["status", "vulnerable", 1]] }], "w_bramblewhip"],
	["sparkingrod", "SPARKING ROD", "zap", "common", ["storm"], "rune", { "dmg": 3.8 }, [], [], "INSTANT ARCS. 25% OF HITS SHOCK: SHOCKED FOES TAKE MORE DAMAGE.", [{ "on": "on_hit", "chance": 0.25, "do": [["status", "shock", 1]] }], "w_sparkrune"],
	["thunderlance", "THUNDER LANCE", "thrust", "rare", ["storm"], "spear", { "dmg": 7.0, "range": 70 }, [["chain", 0.3]], [], "A LONG THRUST THAT ARCS. EVERY 4TH THRUST CALLS LIGHTNING.", [{ "on": "every_n_shots", "every": 4, "do": [["lightning", 1.2]] }], "w_stormspear"],
	["capacitor", "CAPACITOR CANNON", "rail", "epic", ["storm"], "handcannon", { "dmg": 15.0, "rate": 0.9 }, [], [], "EACH HIT SHOCKS TWICE. SHOCKED FOES IT KILLS DISCHARGE INTO OTHERS.", [{ "on": "on_hit", "do": [["status", "shock", 2]] }, { "on": "on_kill", "if": "shocked", "do": [["chain", 0.8]] }], "w_handcannon"],
	["stormbreaker", "STORMBREAKER", "gatling", "legend", ["storm"], "minigun", { "dmg": 2.2, "rate": 5.5 }, [["chain", 0.2]], [], "A SPINNING STORM. EVERY 15TH SHOT CALLS LIGHTNING AND SHOCKS.", [{ "on": "every_n_shots", "every": 15, "do": [["lightning", 1.0], ["status", "shock", 1]] }], "w_crankgun"],
	["scatterwand", "SCATTER WAND", "orb", "common", ["arcane"], "wand", { "dmg": 3.4, "rate": 3.0, "count": 2, "spread": 0.3 }, [], [], "TWO BOLTS PER CAST. EVERY 6TH CAST RELEASES A RING OF 6 SPARKS.", [{ "on": "every_n_shots", "every": 6, "do": [["nova", 6, 0.4, "spark"]] }], "w_witchstaff"],
	["prismbow", "PRISM BOW", "bolt", "rare", ["arcane"], "bow", { "dmg": 3.6, "rate": 3.6, "pierce": 1 }, [], [["split", 2]], "PIERCING ARROWS THAT SPLIT INTO TWO WHEN THEY HIT.", [], "w_thornbow"],
	["orreryblades", "ORRERY OF BLADES", "disc", "epic", ["arcane"], "chakram", { "dmg": 3.8, "count": 3, "spread": 0.5, "bounce": 4 }, [], [["accel", 1.2]], "THREE BLADES THAT BOUNCE AND SPEED UP AS THEY FLY.", [], "w_sawblade"],
	["thousandcuts", "THOUSAND CUTS", "burst", "legend", ["arcane"], "pistol", { "dmg": 2.6, "rate": 1.8, "count": 2 }, [["ricochet", 1]], [], "DOUBLE BURSTS THAT RICOCHET. 25% OF VOLLEYS ADD 2 EXTRA SHOTS.", [{ "on": "on_shoot", "chance": 0.25, "do": [["shoot", 2, 0.5, "spark", 0.3]] }], "w_alleysprayer"],
	["wispcrook", "WISPHERD'S CROOK", "summon", "common", ["swarm"], "staff", { "dmg": 2.4 }, [["fam_rate", 1.15]], [], "EACH SHOT RAISES A WISP FOR 6S. WISPS FIRE 15% FASTER.", [], "w_hivestaff"],
	["hivelantern", "HIVE LANTERN", "boomer", "rare", ["swarm"], "lanternw", { "dmg": 4.4 }, [], [], "FLIES OUT AND BACK. 20% OF KILLS RAISE A WISP FOR 6S.", [{ "on": "on_kill", "chance": 0.2, "do": [["summon", 6.0]] }], "w_sunlantern"],
	["bonebell", "BONE BELL", "nova", "rare", ["swarm"], "lanternw", { "dmg": 2.8, "rate": 1.5 }, [], [], "RINGS OUT SHOTS. EVERY 5TH TOLL RAISES A WISP FOR 5S.", [{ "on": "every_n_shots", "every": 5, "do": [["summon", 5.0]] }], "w_bonechime"],
	["courtofshades", "COURT OF SHADES", "summon", "legend", ["swarm"], "skullstaff", { "dmg": 3.0, "rate": 1.0 }, [["familiars", 2], ["fam_dmg", 0.5]], [], "TWO PERMANENT WISPS THAT HIT 50% HARDER. EACH ROOM SUMMONS TWO MORE FOR 8S.", [{ "on": "on_room_enter", "do": [["summon", 8.0], ["summon", 8.0]] }], "w_bonetome"],
	["twinshivs", "TWIN SHIVS", "slash", "common", ["shadow"], "dagger", { "dmg": 3.2, "rate": 4.5, "range": 24, "arc": 80 }, [], [], "QUICK STABS. ROLLING SCATTERS 6 SHIVS AROUND YOU.", [{ "on": "on_roll", "do": [["nova", 6, 0.6, "spark"]] }], "w_reaperhook"],
	["smokebow", "SMOKE BOW", "bolt", "rare", ["shadow"], "bow", { "dmg": 3.6, "rate": 3.6 }, [["roll_speed", 1.1]], [], "ROLLING ERASES ENEMY SHOTS NEAR YOU. ROLLS GO 10% FURTHER.", [{ "on": "on_roll", "do": [["clear_shots", 40]] }], "w_silvercrossbow"],
	["eclipsescythe", "ECLIPSE SCYTHE", "slash", "epic", ["shadow"], "scythe", { "dmg": 10.0, "rate": 1.6, "range": 44, "arc": 200 }, [], [["kill_roll", 0.4]], "A HUGE SWEEP ALL AROUND YOU. KILLS OFTEN REFUND A ROLL.", [], "w_reaperhook"],
	["phantomvolley", "PHANTOM VOLLEY", "disc", "legend", ["shadow"], "rune", { "dmg": 4.4, "rate": 2.0 }, [["dodge_charges", 1], ["charges", 1]], [], "+1 ROLL CHARGE. EVERY ROLL FIRES 4 FULL-POWER DISCS ALONG YOUR AIM.", [{ "on": "on_roll", "do": [["shoot", 4, 1.0, "", 0.3]] }], "w_moonglaive"],
	["towershield", "TOWER SHIELD", "thrust", "common", ["bulwark"], "halberd", { "dmg": 5.0, "rate": 1.8, "range": 30, "width": 16 }, [["armor", 1]], [["parry", 1]], "A SHIELD BASH THAT BLOCKS SHOTS IN ITS PATH. GRANTS 1 ARMOR.", [], "w_halberd"],
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
	["luckydeck", "LUCKY DECK", "disc", "rare", ["fortune"], "rune", { "dmg": 3.4, "rate": 2.4, "count": 3, "spread": 0.25 }, [["crit", 0.1]], [], "THROWS THREE PLAYING CARDS. +10% CRIT. CRITS PAY OUT 1 GOLD.", [{ "on": "on_crit", "do": [["gold", 1]] }], "w_doubloon"],
	["tithescepter", "TITHE SCEPTER", "zap", "legend", ["fortune"], "staff", { "dmg": 4.8, "rate": 2.4, "chain": 3 }, [], [["gold_dmg", 0.2], ["gold_hit", 0.05]], "+20% DAMAGE PER 100 GOLD. ARCS SHAKE OUT COINS. CLEARING A ROOM PAYS 5 GOLD.", [{ "on": "on_room_clear", "do": [["gold", 5]] }], "w_heavensrod"],
	["hexsickle", "HEXBOUND SICKLE", "slash", "common", ["malice"], "sickle", { "dmg": 6.0, "rate": 2.4, "arc": 130 }, [], [], "A WIDE CUT THAT CURSES 30% OF FOES IT HITS (+25% DAMAGE TAKEN).", [{ "on": "on_hit", "chance": 0.3, "do": [["status", "curse", 1]] }], "w_twincrescent"],
	["cursedflintlock", "CURSED FLINTLOCK", "rail", "rare", ["malice"], "rifle", { "dmg": 18.0, "rate": 0.9 }, [["max_hp", -2]], [], "-1 MAX HEART WHILE HELD. CURSED FOES IT HITS TAKE A 50% BONUS SHOT.", [{ "on": "on_hit", "if": "cursed", "do": [["damage", 0.5]] }], "w_longrifle"],
	["weepingstaff", "WEEPING IDOL STAFF", "orb", "epic", ["malice"], "skullstaff", { "dmg": 4.2 }, [], [], "+60% DAMAGE. 5% OF CASTS DRAW HALF A HEART OF YOUR BLOOD.", [["pct", "dmg", 0.6], { "on": "on_shoot", "chance": 0.05, "do": [["hurt_self", 1]] }], "w_soulstaff"],
	["doombell", "DOOMSAYER'S KNELL", "nova", "legend", ["malice"], "tome", { "dmg": 3.4, "rate": 1.5, "count": 14 }, [], [], "40% OF HITS CURSE. CURSED FOES IT KILLS EXPLODE FOR 150% DAMAGE.", [{ "on": "on_hit", "chance": 0.4, "do": [["status", "curse", 1]] }, { "on": "on_kill", "if": "cursed", "do": [["explode", 40, 1.5]] }], "w_thorntome"],
	["juggler", "JUGGLER'S PINS", "spin", "rare", ["arcane", "fortune"], "axe", { "dmg": 5.0, "rate": 2.2, "count": 3, "spread": 0.35 }, [], [["accel", 1.15]], "THREE SPINNING PINS THAT SPEED UP. EVERY 8TH THROW TOSSES A RING OF 8.", [{ "on": "every_n_shots", "every": 8, "do": [["nova", 8, 0.5, ""]] }], "w_tomahawk"],
	["bannerpike", "RALLYING PIKE", "thrust", "epic", ["swarm", "bulwark"], "halberd", { "dmg": 7.0, "range": 64 }, [["familiars", 1]], [], "A WISP FOLLOWS YOU. CLEARING A ROOM RAISES TWO WISPS FOR 10S.", [{ "on": "on_room_clear", "do": [["summon", 10.0], ["summon", 10.0]] }], "w_warbanner"],
	# ---------- Hero signature weapons (design spec step 6; never in loot pools) ----------
	["banesabre", "BANE SABRE", "slash", "rare", ["edge"], "katana", { "dmg": 7.0, "rate": 2.4, "range": 36, "arc": 110 }, [["crit", 0.05]], [], "A HUNTER'S SILVERED SABRE. +5% CRIT.", [], "w_huntsword"],
	["ironslab", "IRON SLAB", "slash", "rare", ["fury"], "hammer", { "dmg": 16.0, "rate": 0.9, "range": 46, "arc": 170 }, [], [["knock", 2.2]], "FAR TOO BIG TO BE A SWORD. SLOW, WIDE AND BRUTAL. HITS KNOCK FOES BACK.", [], "w_gallows"],
	["wayfareredge", "WAYFARER'S EDGE", "slash", "rare", ["edge"], "katana", { "dmg": 6.0, "rate": 3.0, "range": 38, "arc": 80 }, [["crit", 0.05]], [["parry", 1]], "A QUICK, NARROW CUT THAT ALSO SLICES SHOTS OUT OF THE AIR.", [], "w_wandererkatana"],
	["snubguns", "SNUB GUNS", "burst", "rare", ["fortune"], "pistol", { "dmg": 2.4, "rate": 2.0, "count": 2, "spread": 0.12 }, [], [], "TWO SHORT GUNS FIRED TOGETHER. KILLS HAVE 15% CHANCE TO DROP A COIN.", [{ "on": "on_kill", "chance": 0.15, "do": [["drop", "coin"]] }], "w_streetpistol"],
	["shackleflail", "SHACKLE FLAIL", "whip", "rare", ["malice"], "whip", { "dmg": 5.5, "rate": 2.0, "range": 64 }, [], [], "A LENGTH OF PRISON CHAIN WITH THE LOCK STILL ON.", [], "w_chainlash"],
	["giltdeck", "GILT DECK", "disc", "rare", ["arcane"], "rune", { "dmg": 3.0, "rate": 2.6, "count": 3, "spread": 0.3 }, [], [], "THROWS THREE SHARPENED CARDS THAT BOUNCE OFF WALLS.", [], "w_doubloon"],
	["warlance", "WAR LANCE", "thrust", "rare", ["bulwark"], "halberd", { "dmg": 7.5, "rate": 2.0, "range": 66 }, [], [], "A LONG CAVALRY LANCE THAT PIERCES A WHOLE LINE.", [], "w_halberd"],
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

static func random_weapon(rarity: String, exclude: Variant = null) -> Dictionary:
	var pool := []
	for w in all():
		if w["rarity"] == rarity and not (exclude != null and w["id"] == exclude["id"]) and not HERO_WEAPON.values().has(w["id"]):
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

static func wdmg(p: Player) -> float: return p.weapon["dmg"] * p.dmg * synergy_mult(p)
static func wrate(p: Player) -> float:
	var r: float = p.weapon["rate"] * p.rate
	if p.weapon["kind"] == "gatling":
		r *= 1 + 2 * p.spin
	if p.haste_t > 0:
		r *= 1.2
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
