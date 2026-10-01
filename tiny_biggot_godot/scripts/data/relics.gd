class_name Relics
extends RefCounted
## Relics (Data.rb RELICS / LOOT, extended by the content batches).
## Each row is [id, rarity, name, desc, effects, tags, sprite]; new relics
## name an existing sprite to reuse (placeholder art). Effects use the effect
## system (effects/effects.gd). The original 66 relics were converted
## mechanically from their Ruby lambdas (each statement becomes one op, in
## order) and carry no synergy tags. tests/effects_test.gd checks them against
## the Ruby code.

const ORIGINAL_COUNT := 66
const ROWS := [
	["whetstone", "common", "WHETSTONE", "+25% DAMAGE", [["mul", "dmg", 1.25]]],
	["twitch", "common", "TWITCHING FINGER", "+20% FIRE RATE", [["mul", "rate", 1.2]]],
	["splitfang", "rare", "SPLIT FANG", "+1 PROJECTILE, -10% DAMAGE", [["add", "count", 1], ["mul", "dmg", 0.9]]],
	["owl", "common", "OWL FEATHER", "+25% SHOT SPEED AND RANGE", [["mul", "shot_speed", 1.25], ["mul", "life", 1.15]]],
	["sparrow", "common", "SPARROW BOOTS", "+15% MOVE SPEED", [["mul", "speed", 1.15]]],
	["garnet", "rare", "BLOOD GARNET", "+1 MAX HEART, HEALS 1 HEART", [["add", "max_hp", 2], ["add_cap", "hp", 2, "max_hp"]]],
	["bramble", "common", "BRAMBLE RING", "SHOTS PIERCE 1 MORE FOE", [["add", "pierce", 1]]],
	["sap", "rare", "RUBBER SAP", "SHOTS BOUNCE OFF WALLS", [["add", "bounce", 1], ["mul", "life", 1.2]]],
	["seeker", "rare", "SEEKER'S EYE", "SHOTS HOME IN ON FOES", [["add", "homing", 2.5]]],
	["coal", "common", "CINDER COAL", "25% CHANCE TO BURN", [["add", "burn", 0.25]]],
	["needle", "common", "FROST NEEDLE", "25% CHANCE TO CHILL FOES", [["add", "chill", 0.25]]],
	["viper", "common", "VIPER TOOTH", "HITS POISON FOES", [["add", "poison", 1]]],
	["luckycoin", "common", "CROOKED COIN", "+12% CRIT CHANCE", [["add", "crit", 0.12]]],
	["hourglass", "common", "SAND GLASS", "ROLL RECHARGES 35% FASTER", [["mul", "dodge_cd", 0.65]]],
	["lantern", "rare", "GRAVE LANTERN", "KILLS HAVE 6% CHANCE TO HEAL", [["add", "lifesteal", 0.06]]],
	["buckler", "rare", "IRON BUCKLER", "BLOCKS THE FIRST HIT IN EACH ROOM", [["set", "buckler", true]]],
	["moon", "epic", "PALE MOON", "AN ORB CIRCLES YOU AND BLOCKS SHOTS", [["add", "orbitals", 1]]],
	["sapbomb", "rare", "POWDER POUCH", "ROLLING DROPS A BOMB", [["set", "bomb_dodge", true]]],
	["dice", "rare", "LOADED DIE", "15% CHANCE TO FIRE A TRIPLE VOLLEY", [["add", "triple", 0.15]]],
	["arrowhead", "common", "BARBED TIP", "+15% DAMAGE, +15% SHOT SPEED", [["mul", "dmg", 1.15], ["mul", "shot_speed", 1.15]]],
	["thorn", "common", "THORN LEAF", "FOES THAT TOUCH YOU TAKE DAMAGE", [["add", "thorns", 10]]],
	["crown", "rare", "PAUPER'S CROWN", "+50% GOLD, SHOPS 20% CHEAPER", [["mul", "gold_mult", 1.5], ["add_cap", "shop_disc", 0.2, 0.6]]],
	["heavy", "epic", "LEAD SHOT", "BIGGER SHOTS, +30% DAMAGE, -10% RATE", [["mul", "size", 1.35], ["mul", "dmg", 1.3], ["mul", "rate", 0.9]]],
	["fever", "rare", "FEVER SCROLL", "KILLS GRANT A BURST OF FIRE RATE", [["add", "frenzy", 1]]],
	["bonecharm", "rare", "BONE CHARM", "+1 ROLL CHARGE", [["add", "dodge_charges", 1], ["add", "charges", 1]]],
	["glassheart", "epic", "GLASS HEART", "+60% DAMAGE, -1 MAX HEART", [["mul", "dmg", 1.6], ["add_floor", "max_hp", -2, 2], ["clamp_max", "hp", "max_hp"]]],
	["echo", "rare", "ECHO RING", "ALSO FIRES A SHOT BEHIND YOU", [["add", "backshot", 1]]],
	["witcheye", "epic", "WITCH EYE", "+15% CRIT, CRITS DEAL X2.5", [["add", "crit", 0.15], ["at_least", "crit_mult", 2.5]]],
	["rage", "rare", "WRATH EMBER", "+50% DAMAGE WHILE AT 1 HEART OR LESS", [["add", "rage", 0.5]]],
	["lodestone", "rare", "LODESTONE", "PULLS GOLD, +25% GOLD", [["set", "magnet", true], ["mul", "gold_mult", 1.25]]],
	["sigil", "epic", "WARDING SIGIL", "TAKING DAMAGE RELEASES A NOVA", [["add", "ward", 1]]],
	["shells", "rare", "VOLATILE SHELLS", "SHOTS BURST ON IMPACT", [["add", "explode", 1]]],
	["spark", "rare", "CHAIN SPARK", "30% CHANCE HITS ARC TO A NEARBY FOE", [["add", "chain", 0.3]]],
	["keyring", "common", "WARDEN'S KEY", "+1 POTION SLOT, GAIN 1 POTION", [["add", "max_potions", 1], ["add_cap", "potions", 1, "max_potions"]]],
	["tallow", "common", "TALLOW CANDLE", "+1 BOMB, BOMBS DEAL +50% DAMAGE", [["add", "bombs", 1], ["mul", "bomb_mult", 1.5]]],
	["skeletonkey", "common", "SKELETON KEY", "+2 KEYS", [["add", "keys", 2]]],
	["quiver", "common", "QUIVER STRAP", "+10% FIRE RATE, +10% SHOT SPEED", [["mul", "rate", 1.1], ["mul", "shot_speed", 1.1]]],
	["filings", "common", "IRON FILINGS", "+1 ARMOR", [["add", "armor", 1]]],
	["gravedust", "common", "GRAVE DUST", "FOES DROP 30% MORE GOLD", [["mul", "gold_drop", 1.3]]],
	["mothwing", "common", "MOTH WING", "ROLLS GO FURTHER AND FASTER", [["mul", "roll_speed", 1.25]]],
	["bitterroot", "common", "BITTER ROOT", "POTIONS HEAL 1 MORE HEART", [["add", "potion_heal", 2]]],
	["tinwhistle", "common", "TIN WHISTLE", "+10% MOVE SPEED, ROLL RECHARGES FASTER", [["mul", "speed", 1.1], ["mul", "dodge_cd", 0.9]]],
	["chalk", "common", "MAPPER'S CHALK", "HIDDEN WALLS GLOW, +1 BOMB", [["set", "reveal", true], ["add", "bombs", 1]]],
	["rustynail", "common", "RUSTY NAIL", "+1 PIERCE, +10% DAMAGE", [["add", "pierce", 1], ["mul", "dmg", 1.1]]],
	["wispjar", "rare", "WISP JAR", "A WISP FOLLOWS YOU AND SHOOTS FOES", [["add", "familiars", 1]]],
	["emberheart", "rare", "EMBER HEART", "FOES NEAR YOU CATCH FIRE", [["add", "aura", 1]]],
	["boneshield", "rare", "BONE SHIELD", "+2 ARMOR", [["add", "armor", 2]]],
	["huntersmark", "rare", "HUNTER'S MARK", "+35% DAMAGE TO ELITES AND BOSSES", [["add", "elite_mult", 0.35]]],
	["glasslens", "rare", "GLASS LENS", "SHOTS GROW AND HIT HARDER AS THEY FLY", [["set", "lens", true]]],
	["staticcoil", "rare", "STATIC COIL", "EVERY 4 SECONDS, RELEASE A RING OF SPARKS", [["add", "coil", 1]]],
	["bloodoath", "rare", "BLOOD OATH", "+1 MAX HEART FOR EACH GUARDIAN SLAIN", [["set", "oath", true]]],
	["ricochet", "rare", "RICOCHET BEAD", "SHOTS JUMP TO ANOTHER FOE AFTER A HIT", [["add", "ricochet", 1]]],
	["misers", "rare", "MISER'S PURSE", "+1% DAMAGE FOR EVERY 10 GOLD HELD", [["set", "miser", true]]],
	["shadowstep", "rare", "SHADOW STEP", "ROLLING THROUGH FOES DAMAGES THEM", [["set", "shadowstep", true]]],
	["coldiron", "rare", "COLD IRON", "+10% DAMAGE, +15% CHANCE TO CHILL", [["mul", "dmg", 1.1], ["add", "chill", 0.15]]],
	["splinter", "rare", "SPLINTER", "KILLS BURST INTO SHARDS", [["add", "splinter", 1]]],
	["phoenix", "epic", "PHOENIX FEATHER", "ONCE PER RUN, RISE AGAIN WITH 2 HEARTS", [["add", "revive", 1]]],
	["twinwisp", "epic", "TWIN LANTERNS", "TWO WISPS FOLLOW YOU", [["add", "familiars", 2]]],
	["stormcrown", "epic", "STORM CROWN", "HITS MAY CALL DOWN LIGHTNING", [["add", "storm", 0.2]]],
	["hollowmirror", "epic", "HOLLOW MIRROR", "ENEMY SHOTS SLOW DOWN NEAR YOU", [["set", "mirror", true]]],
	["gildedtooth", "epic", "GILDED TOOTH", "SHOPS 30% CHEAPER, +25% GOLD", [["add_cap", "shop_disc", 0.3, 0.6], ["mul", "gold_mult", 1.25]]],
	["overcharge", "epic", "OVERCHARGE", "+1 PROJECTILE, +15% RATE, -1 MAX HEART", [["add", "count", 1], ["mul", "rate", 1.15], ["add_floor", "max_hp", -2, 2], ["clamp_max", "hp", "max_hp"]]],
	["deepeye", "legend", "EYE OF THE DEEP", "+2 PROJECTILES THAT HOME IN", [["add", "count", 2], ["add", "homing", 2.5]]],
	["cindercrown", "legend", "CROWN OF CINDERS", "+50% DAMAGE, SHOTS OFTEN BURN", [["mul", "dmg", 1.5], ["add", "burn", 0.35]]],
	["ageglass", "legend", "GLASS OF AGES", "+2 ROLL CHARGES, ROLLING RELOADS", [["add", "dodge_charges", 2], ["add", "charges", 2], ["set", "roll_reload", true]]],
	["worldseed", "legend", "WORLDSEED", "+2 MAX HEARTS, HEAL FULLY", [["add", "max_hp", 4], ["copy", "hp", "max_hp"]]],]
const BASE_COUNT := 34
const CACHE_1 := ["tallow", "skeletonkey", "quiver", "filings", "gravedust", "mothwing", "bitterroot", "tinwhistle", "chalk", "rustynail"]
const CACHE_2 := ["wispjar", "emberheart", "boneshield", "huntersmark", "glasslens", "staticcoil", "bloodoath", "ricochet", "misers", "shadowstep", "coldiron", "splinter"]
const CACHE_3 := ["phoenix", "twinwisp", "stormcrown", "hollowmirror", "gildedtooth", "overcharge", "deepeye", "cindercrown", "ageglass", "worldseed"]

## Rarity weights per source.
const LOOT := {
	"chest": { "common": 60, "rare": 30, "epic": 9, "legend": 1 }, "shop": { "common": 55, "rare": 35, "epic": 9, "legend": 1 },
	"iron": { "common": 15, "rare": 45, "epic": 30, "legend": 10 }, "boss": { "common": 20, "rare": 45, "epic": 28, "legend": 7 },
	"secret": { "common": 25, "rare": 40, "epic": 25, "legend": 10 }, "cursed": { "common": 0, "rare": 30, "epic": 50, "legend": 20 },
	"altar": { "common": 30, "rare": 45, "epic": 20, "legend": 5 },
}

static var _list: Array = []
static var _by_id := {}

static func all() -> Array:
	if _list.is_empty():
		for i in ROWS.size():
			var row: Array = ROWS[i]
			var r := { "id": row[0], "rarity": row[1], "name": row[2], "desc": row[3], "effects": row[4],
				"tags": row[5] if row.size() > 5 else [], "new": i >= ORIGINAL_COUNT,
				"sprite": row[6] if row.size() > 6 else "relic_" + row[0] }
			_list.append(r)
			_by_id[r["id"]] = r
	return _list

static func by_id(id: String) -> Dictionary:
	all()
	return _by_id[id]

static func base_ids() -> Array:
	var out := []
	for i in BASE_COUNT:
		out.append(ROWS[i][0])
	return out

## New-content relic ids (always in the pool).
static func new_ids() -> Array:
	var out := []
	for r in all():
		if r["new"]:
			out.append(r["id"])
	return out

static func apply(id: String, p: Player) -> void:
	Effects.apply(p, by_id(id)["effects"], 1, "relic:" + id)
