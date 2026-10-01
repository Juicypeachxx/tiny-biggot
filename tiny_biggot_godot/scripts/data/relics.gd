class_name Relics
extends RefCounted
## Relics (port of Data.rb RELICS / LOOT). Each row is [id, rarity, name, desc];
## the effect of each relic is its branch in apply(), converted line by line
## from the Ruby lambda.

const ROWS := [
	["whetstone", "common", "WHETSTONE", "+25% DAMAGE"],
	["twitch", "common", "TWITCHING FINGER", "+20% FIRE RATE"],
	["splitfang", "rare", "SPLIT FANG", "+1 PROJECTILE, -10% DAMAGE"],
	["owl", "common", "OWL FEATHER", "+25% SHOT SPEED AND RANGE"],
	["sparrow", "common", "SPARROW BOOTS", "+15% MOVE SPEED"],
	["garnet", "rare", "BLOOD GARNET", "+1 MAX HEART, HEALS 1 HEART"],
	["bramble", "common", "BRAMBLE RING", "SHOTS PIERCE 1 MORE FOE"],
	["sap", "rare", "RUBBER SAP", "SHOTS BOUNCE OFF WALLS"],
	["seeker", "rare", "SEEKER'S EYE", "SHOTS HOME IN ON FOES"],
	["coal", "common", "CINDER COAL", "25% CHANCE TO BURN"],
	["needle", "common", "FROST NEEDLE", "25% CHANCE TO CHILL FOES"],
	["viper", "common", "VIPER TOOTH", "HITS POISON FOES"],
	["luckycoin", "common", "CROOKED COIN", "+12% CRIT CHANCE"],
	["hourglass", "common", "SAND GLASS", "ROLL RECHARGES 35% FASTER"],
	["lantern", "rare", "GRAVE LANTERN", "KILLS HAVE 6% CHANCE TO HEAL"],
	["buckler", "rare", "IRON BUCKLER", "BLOCKS THE FIRST HIT IN EACH ROOM"],
	["moon", "epic", "PALE MOON", "AN ORB CIRCLES YOU AND BLOCKS SHOTS"],
	["sapbomb", "rare", "POWDER POUCH", "ROLLING DROPS A BOMB"],
	["dice", "rare", "LOADED DIE", "15% CHANCE TO FIRE A TRIPLE VOLLEY"],
	["arrowhead", "common", "BARBED TIP", "+15% DAMAGE, +15% SHOT SPEED"],
	["thorn", "common", "THORN LEAF", "FOES THAT TOUCH YOU TAKE DAMAGE"],
	["crown", "rare", "PAUPER'S CROWN", "+50% GOLD, SHOPS 20% CHEAPER"],
	["heavy", "epic", "LEAD SHOT", "BIGGER SHOTS, +30% DAMAGE, -10% RATE"],
	["fever", "rare", "FEVER SCROLL", "KILLS GRANT A BURST OF FIRE RATE"],
	["bonecharm", "rare", "BONE CHARM", "+1 ROLL CHARGE"],
	["glassheart", "epic", "GLASS HEART", "+60% DAMAGE, -1 MAX HEART"],
	["echo", "rare", "ECHO RING", "ALSO FIRES A SHOT BEHIND YOU"],
	["witcheye", "epic", "WITCH EYE", "+15% CRIT, CRITS DEAL X2.5"],
	["rage", "rare", "WRATH EMBER", "+50% DAMAGE WHILE AT 1 HEART OR LESS"],
	["lodestone", "rare", "LODESTONE", "PULLS GOLD, +25% GOLD"],
	["sigil", "epic", "WARDING SIGIL", "TAKING DAMAGE RELEASES A NOVA"],
	["shells", "rare", "VOLATILE SHELLS", "SHOTS BURST ON IMPACT"],
	["spark", "rare", "CHAIN SPARK", "30% CHANCE HITS ARC TO A NEARBY FOE"],
	["keyring", "common", "WARDEN'S KEY", "+1 POTION SLOT, GAIN 1 POTION"],
	["tallow", "common", "TALLOW CANDLE", "+1 BOMB, BOMBS DEAL +50% DAMAGE"],
	["skeletonkey", "common", "SKELETON KEY", "+2 KEYS"],
	["quiver", "common", "QUIVER STRAP", "+10% FIRE RATE, +10% SHOT SPEED"],
	["filings", "common", "IRON FILINGS", "+1 ARMOR"],
	["gravedust", "common", "GRAVE DUST", "FOES DROP 30% MORE GOLD"],
	["mothwing", "common", "MOTH WING", "ROLLS GO FURTHER AND FASTER"],
	["bitterroot", "common", "BITTER ROOT", "POTIONS HEAL 1 MORE HEART"],
	["tinwhistle", "common", "TIN WHISTLE", "+10% MOVE SPEED, ROLL RECHARGES FASTER"],
	["chalk", "common", "MAPPER'S CHALK", "HIDDEN WALLS GLOW, +1 BOMB"],
	["rustynail", "common", "RUSTY NAIL", "+1 PIERCE, +10% DAMAGE"],
	["wispjar", "rare", "WISP JAR", "A WISP FOLLOWS YOU AND SHOOTS FOES"],
	["emberheart", "rare", "EMBER HEART", "FOES NEAR YOU CATCH FIRE"],
	["boneshield", "rare", "BONE SHIELD", "+2 ARMOR"],
	["huntersmark", "rare", "HUNTER'S MARK", "+35% DAMAGE TO ELITES AND BOSSES"],
	["glasslens", "rare", "GLASS LENS", "SHOTS GROW AND HIT HARDER AS THEY FLY"],
	["staticcoil", "rare", "STATIC COIL", "EVERY 4 SECONDS, RELEASE A RING OF SPARKS"],
	["bloodoath", "rare", "BLOOD OATH", "+1 MAX HEART FOR EACH GUARDIAN SLAIN"],
	["ricochet", "rare", "RICOCHET BEAD", "SHOTS JUMP TO ANOTHER FOE AFTER A HIT"],
	["misers", "rare", "MISER'S PURSE", "+1% DAMAGE FOR EVERY 10 GOLD HELD"],
	["shadowstep", "rare", "SHADOW STEP", "ROLLING THROUGH FOES DAMAGES THEM"],
	["coldiron", "rare", "COLD IRON", "+10% DAMAGE, +15% CHANCE TO CHILL"],
	["splinter", "rare", "SPLINTER", "KILLS BURST INTO SHARDS"],
	["phoenix", "epic", "PHOENIX FEATHER", "ONCE PER RUN, RISE AGAIN WITH 2 HEARTS"],
	["twinwisp", "epic", "TWIN LANTERNS", "TWO WISPS FOLLOW YOU"],
	["stormcrown", "epic", "STORM CROWN", "HITS MAY CALL DOWN LIGHTNING"],
	["hollowmirror", "epic", "HOLLOW MIRROR", "ENEMY SHOTS SLOW DOWN NEAR YOU"],
	["gildedtooth", "epic", "GILDED TOOTH", "SHOPS 30% CHEAPER, +25% GOLD"],
	["overcharge", "epic", "OVERCHARGE", "+1 PROJECTILE, +15% RATE, -1 MAX HEART"],
	["deepeye", "legend", "EYE OF THE DEEP", "+2 PROJECTILES THAT HOME IN"],
	["cindercrown", "legend", "CROWN OF CINDERS", "+50% DAMAGE, SHOTS OFTEN BURN"],
	["ageglass", "legend", "GLASS OF AGES", "+2 ROLL CHARGES, ROLLING RELOADS"],
	["worldseed", "legend", "WORLDSEED", "+2 MAX HEARTS, HEAL FULLY"],]
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
		for row in ROWS:
			var r := { "id": row[0], "rarity": row[1], "name": row[2], "desc": row[3] }
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

## The relic's effect (Ruby r[:fx].call(p)).
static func apply(id: String, p: Player) -> void:
	match id:
		"whetstone":
			p.dmg *= 1.25
		"twitch":
			p.rate *= 1.2
		"splitfang":
			p.count += 1
			p.dmg *= 0.9
		"owl":
			p.shot_speed *= 1.25
			p.life *= 1.15
		"sparrow":
			p.speed *= 1.15
		"garnet":
			p.max_hp += 2
			p.hp = min(p.max_hp, p.hp + 2)
		"bramble":
			p.pierce += 1
		"sap":
			p.bounce += 1
			p.life *= 1.2
		"seeker":
			p.homing += 2.5
		"coal":
			p.burn += 0.25
		"needle":
			p.chill += 0.25
		"viper":
			p.poison += 1
		"luckycoin":
			p.crit += 0.12
		"hourglass":
			p.dodge_cd *= 0.65
		"lantern":
			p.lifesteal += 0.06
		"buckler":
			p.buckler = true
		"moon":
			p.orbitals += 1
		"sapbomb":
			p.bomb_dodge = true
		"dice":
			p.triple += 0.15
		"arrowhead":
			p.dmg *= 1.15
			p.shot_speed *= 1.15
		"thorn":
			p.thorns += 10
		"crown":
			p.gold_mult *= 1.5
			p.shop_disc = min(0.6, p.shop_disc + 0.2)
		"heavy":
			p.size *= 1.35
			p.dmg *= 1.3
			p.rate *= 0.9
		"fever":
			p.frenzy += 1
		"bonecharm":
			p.dodge_charges += 1
			p.charges += 1
		"glassheart":
			p.dmg *= 1.6
			p.max_hp = max(2, p.max_hp - 2)
			p.hp = min(p.hp, p.max_hp)
		"echo":
			p.backshot += 1
		"witcheye":
			p.crit += 0.15
			p.crit_mult = max(p.crit_mult, 2.5)
		"rage":
			p.rage += 0.5
		"lodestone":
			p.magnet = true
			p.gold_mult *= 1.25
		"sigil":
			p.ward += 1
		"shells":
			p.explode += 1
		"spark":
			p.chain += 0.3
		"keyring":
			p.max_potions += 1
			p.potions = min(p.max_potions, p.potions + 1)
		"tallow":
			p.bombs += 1
			p.bomb_mult *= 1.5
		"skeletonkey":
			p.keys += 2
		"quiver":
			p.rate *= 1.1
			p.shot_speed *= 1.1
		"filings":
			p.armor += 1
		"gravedust":
			p.gold_drop *= 1.3
		"mothwing":
			p.roll_speed *= 1.25
		"bitterroot":
			p.potion_heal += 2
		"tinwhistle":
			p.speed *= 1.1
			p.dodge_cd *= 0.9
		"chalk":
			p.reveal = true
			p.bombs += 1
		"rustynail":
			p.pierce += 1
			p.dmg *= 1.1
		"wispjar":
			p.familiars += 1
		"emberheart":
			p.aura += 1
		"boneshield":
			p.armor += 2
		"huntersmark":
			p.elite_mult += 0.35
		"glasslens":
			p.lens = true
		"staticcoil":
			p.coil += 1
		"bloodoath":
			p.oath = true
		"ricochet":
			p.ricochet += 1
		"misers":
			p.miser = true
		"shadowstep":
			p.shadowstep = true
		"coldiron":
			p.dmg *= 1.1
			p.chill += 0.15
		"splinter":
			p.splinter += 1
		"phoenix":
			p.revive += 1
		"twinwisp":
			p.familiars += 2
		"stormcrown":
			p.storm += 0.2
		"hollowmirror":
			p.mirror = true
		"gildedtooth":
			p.shop_disc = min(0.6, p.shop_disc + 0.3)
			p.gold_mult *= 1.25
		"overcharge":
			p.count += 1
			p.rate *= 1.15
			p.max_hp = max(2, p.max_hp - 2)
			p.hp = min(p.hp, p.max_hp)
		"deepeye":
			p.count += 2
			p.homing += 2.5
		"cindercrown":
			p.dmg *= 1.5
			p.burn += 0.35
		"ageglass":
			p.dodge_charges += 2
			p.charges += 2
			p.roll_reload = true
		"worldseed":
			p.max_hp += 4
			p.hp = p.max_hp
		_:
			push_error("Relics.apply: unknown relic " + id)
