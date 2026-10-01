class_name Gear
extends RefCounted
## Equipment (01c_items.rb GEAR / SETS / STAT_TEXT and the equip and set logic
## of 04b_items.rb, extended by the content batches). Rows are
## [id, name, slot, rarity, tags, set, shape, stats, hooks, desc, effects].
## The first ORIGINAL_COUNT rows are original; new rows may add effects.

const SLOTS := ["head", "body", "feet", "trinket"]
const SLOT_NAME := { "head": "HELM", "body": "ARMOR", "feet": "BOOTS", "trinket": "TRINKET" }

## Four-piece sets: the 2-piece bonus supports a build, the 4-piece grants that family's capstone power.
const SETS := {
	"emberweave": {  "name": "EMBERWEAVE", "tag": "pyre", "b2": [["burn", 0.2]], "b4h": [["inferno", 1]], "d2": "+20% BURN CHANCE", "d4": "BURNING FOES EXPLODE ON DEATH"  },
	"hoarfrost": {  "name": "HOARFROST", "tag": "frost", "b2": [["chill", 0.2]], "b4h": [["shatter", 1]], "d2": "+20% CHILL CHANCE", "d4": "CHILLED FOES SHATTER BELOW 30%"  },
	"plaguedoc": {  "name": "PLAGUE DOCTOR", "tag": "venom", "b2": [["poison", 1]], "b4h": [["plague", 1]], "d2": "+1 POISON ON HIT", "d4": "POISON SPREADS WHEN FOES DIE"  },
	"thunderborn": {  "name": "THUNDERBORN", "tag": "storm", "b2": [["chain", 0.2]], "b4h": [["tempest", 1]], "d2": "+20% ARC CHANCE", "d4": "LIGHTNING STRIKES 3 FOES EVERY 3S"  },
	"butcher": {  "name": "BUTCHER", "tag": "blood", "b2": [["crit", 0.1]], "b4h": [["sanguine", 1]], "d2": "+10% CRIT CHANCE", "d4": "KILLS STACK +4% DAMAGE FOR THE ROOM"  },
	"bastion": {  "name": "BASTION", "tag": "bulwark", "b2": [["armor", 2]], "b4h": [["unbreakable", 1]], "d2": "+2 ARMOR", "d4": "BROKEN ARMOR RELEASES A NOVA"  },
	"nightstalker": {  "name": "NIGHTSTALKER", "tag": "shadow", "b2": [["dodge_charges", 1], ["charges", 1]], "b4h": [["nightfall", 1]], "d2": "+1 ROLL CHARGE", "d4": "ROLLS STRIKE HARD AND REFUND ON KILLS"  },
	"archmage": {  "name": "ARCHMAGE", "tag": "arcane", "b2": [["count", 1]], "b4": [["echo", 0.3]], "d2": "+1 PROJECTILE", "d4": "30% CHANCE FOR SHOTS TO CAST AGAIN"  },
	"gilded": {  "name": "GILDED", "tag": "fortune", "b2": [["gold_mult", 1.3]], "b4h": [["midas", 1]], "d2": "+30% GOLD", "d4": "+1% DAMAGE PER 5 GOLD HELD"  },
	"sapper": {  "name": "SAPPER", "tag": "demolition", "b2": [["bombs", 3], ["bomb_mult", 1.3]], "b4h": [["cluster", 1]], "d2": "+3 BOMBS, BOMBS +30%", "d4": "BOMBS BURST INTO 4 MORE"  },
	"shepherd": {  "name": "SHEPHERD", "tag": "swarm", "b2": [["familiars", 1]], "b4h": [["legion", 1]], "d2": "+1 WISP", "d4": "EVERY 5 KILLS SUMMON A WISP"  },}

const ORIGINAL_COUNT := 96
const ROWS := [
	# --- Set pieces ---
	["ember_hood", "EMBERWEAVE HOOD", "head", "rare", ["pyre"], "emberweave", "hood", [["burn", 0.1]], [], "SMOULDERING CLOTH."],
	["ember_robe", "EMBERWEAVE ROBE", "body", "rare", ["pyre"], "emberweave", "robe", [["max_hp", 2]], [["fire_aura", 1]], "FOES NEAR YOU CATCH FIRE."],
	["ember_boots", "EMBERWEAVE TREADS", "feet", "rare", ["pyre"], "emberweave", "boots", [["speed", 1.06]], [["fire_steps", 1]], "YOU LEAVE BURNING FOOTPRINTS WHILE MOVING."],
	["ember_ring", "EMBERWEAVE BAND", "trinket", "epic", ["pyre"], "emberweave", "ring", [["dmg", 1.1]], [["status_dmg", 0.15]], "+15% DAMAGE TO AFFLICTED FOES."],
	["frost_helm", "HOARFROST CROWN", "head", "rare", ["frost"], "hoarfrost", "crown", [["chill", 0.1]], [], "ICE FORMS ON YOUR BROW."],
	["frost_plate", "HOARFROST PLATE", "body", "rare", ["frost"], "hoarfrost", "plate", [["armor", 1]], [["frost_skin", 1]], "WHEN HIT, CHILL EVERY FOE NEARBY."],
	["frost_boots", "HOARFROST GREAVES", "feet", "rare", ["frost"], "hoarfrost", "greaves", [["dodge_cd", 0.9]], [], "ROLLS RECHARGE FASTER."],
	["frost_amulet", "HOARFROST LOCKET", "trinket", "epic", ["frost"], "hoarfrost", "amulet", [["crit", 0.05]], [["chill_crit", 0.25]], "+25% CRIT CHANCE AGAINST CHILLED FOES."],
	["plague_mask", "PLAGUE DOCTOR'S MASK", "head", "rare", ["venom"], "plaguedoc", "mask", [["poison", 1]], [], "HERBS IN THE BEAK KEEP THE MIASMA OUT."],
	["plague_coat", "PLAGUE DOCTOR'S COAT", "body", "rare", ["venom"], "plaguedoc", "cloak", [["max_hp", 2]], [], "OILED LEATHER."],
	["plague_boots", "PLAGUE DOCTOR'S BOOTS", "feet", "rare", ["venom"], "plaguedoc", "boots", [["speed", 1.05]], [["toxic_steps", 1]], "YOU LEAVE POISON PUDDLES WHILE MOVING."],
	["plague_censer", "PLAGUE CENSER", "trinket", "epic", ["venom"], "plaguedoc", "amulet", [["dmg", 1.08]], [["status_dmg", 0.2]], "+20% DAMAGE TO AFFLICTED FOES."],
	["thunder_helm", "THUNDERBORN HELM", "head", "rare", ["storm"], "thunderborn", "helm", [["chain", 0.1]], [], "YOUR HAIR STANDS ON END."],
	["thunder_mail", "THUNDERBORN MAIL", "body", "rare", ["storm"], "thunderborn", "plate", [["armor", 1]], [["spark_skin", 1]], "WHEN HIT, LIGHTNING STRIKES NEARBY FOES."],
	["thunder_boots", "THUNDERBORN BOOTS", "feet", "rare", ["storm"], "thunderborn", "boots", [["speed", 1.1]], [], "+10% MOVE SPEED."],
	["thunder_ring", "THUNDERBORN SIGNET", "trinket", "epic", ["storm"], "thunderborn", "ring", [["rate", 1.1]], [["nth_zap", 10]], "EVERY 10TH SHOT CALLS LIGHTNING."],
	["butcher_cap", "BUTCHER'S CAP", "head", "rare", ["blood"], "butcher", "hat", [["crit_mult", 0.25]], [], "CRITS DEAL +0.25X MORE."],
	["butcher_apron", "BUTCHER'S APRON", "body", "rare", ["blood"], "butcher", "leather", [["max_hp", 2]], [["kill_heal", 0.03]], "KILLS HAVE A 3% CHANCE TO HEAL."],
	["butcher_boots", "BUTCHER'S CLOGS", "feet", "rare", ["blood"], "butcher", "boots", [["speed", 1.05]], [["close_dmg", 0.2]], "+20% DAMAGE UP CLOSE."],
	["butcher_hook", "BUTCHER'S HOOK", "trinket", "epic", ["blood"], "butcher", "charm", [["dmg", 1.1]], [["execute", 0.08]], "INSTANTLY KILLS FOES BELOW 8% HEALTH."],
	["bastion_helm", "BASTION GREATHELM", "head", "rare", ["bulwark"], "bastion", "helm", [["armor", 1]], [], "A BUCKET OF STEEL."],
	["bastion_plate", "BASTION PLATE", "body", "epic", ["bulwark"], "bastion", "plate", [["armor", 2], ["max_hp", 2]], [], "WALKING FORTRESS."],
	["bastion_boots", "BASTION SABATONS", "feet", "rare", ["bulwark"], "bastion", "greaves", [["thorns", 10]], [], "SPIKED STEEL TOES."],
	["bastion_seal", "BASTION SEAL", "trinket", "rare", ["bulwark"], "bastion", "amulet", [], [["room_armor", 1]], "GAIN 1 ARMOR AFTER EACH ROOM."],
	["night_hood", "NIGHTSTALKER COWL", "head", "rare", ["shadow"], "nightstalker", "hood", [["evade", 0.06]], [], "6% CHANCE TO DODGE A HIT."],
	["night_cloak", "NIGHTSTALKER CLOAK", "body", "rare", ["shadow"], "nightstalker", "cloak", [["roll_speed", 1.15]], [["roll_ambush", 2]], "AFTER A ROLL, YOUR NEXT 2 SHOTS CRIT."],
	["night_boots", "NIGHTSTALKER SOFTSTEPS", "feet", "epic", ["shadow"], "nightstalker", "boots", [["speed", 1.1], ["dodge_cd", 0.85]], [], "SILENT AND SWIFT."],
	["night_fang", "NIGHTSTALKER FANG", "trinket", "rare", ["shadow"], "nightstalker", "charm", [["crit", 0.06]], [["first_hit", 0.3]], "+30% DAMAGE TO UNHURT FOES."],
	["arch_hat", "ARCHMAGE HAT", "head", "rare", ["arcane"], "archmage", "hat", [["homing", 1.0]], [], "SHOTS CURVE TOWARD FOES."],
	["arch_robe", "ARCHMAGE ROBE", "body", "epic", ["arcane"], "archmage", "robe", [["size", 1.15], ["dmg", 1.1]], [], "BIGGER, STRONGER SHOTS."],
	["arch_boots", "ARCHMAGE SLIPPERS", "feet", "rare", ["arcane"], "archmage", "boots", [["shot_speed", 1.15]], [], "SHOTS FLY 15% FASTER."],
	["arch_orb", "ARCHMAGE ORRERY", "trinket", "rare", ["arcane"], "archmage", "amulet", [["orbitals", 1]], [], "A MOON CIRCLES YOU AND BLOCKS SHOTS."],
	["gild_crown", "GILDED CIRCLET", "head", "rare", ["fortune"], "gilded", "crown", [["luck", 1]], [], "BETTER RELIC RARITY."],
	["gild_vest", "GILDED VEST", "body", "rare", ["fortune"], "gilded", "leather", [["max_hp", 2]], [["gold_dmg", 0.05]], "+5% DAMAGE PER 100 GOLD."],
	["gild_boots", "GILDED BOOTS", "feet", "rare", ["fortune"], "gilded", "boots", [["shop_disc", 0.1]], [], "SHOPS 10% CHEAPER."],
	["gild_ring", "GILDED RING", "trinket", "epic", ["fortune"], "gilded", "ring", [["gold_mult", 1.2]], [["gold_hit", 0.03]], "HITS SOMETIMES SHAKE OUT COINS."],
	["sapper_helm", "SAPPER'S HELMET", "head", "rare", ["demolition"], "sapper", "helm", [["bomb_r", 1.15]], [], "BIGGER BLASTS."],
	["sapper_vest", "SAPPER'S BLAST VEST", "body", "rare", ["demolition"], "sapper", "plate", [["armor", 1]], [["bomb_immune", 1]], "YOUR OWN BOMBS NO LONGER HURT YOU."],
	["sapper_boots", "SAPPER'S BOOTS", "feet", "rare", ["demolition"], "sapper", "greaves", [["speed", 1.05]], [["roll_bomb", 1]], "ROLLING DROPS A BOMB."],
	["sapper_fuse", "SAPPER'S FUSE", "trinket", "epic", ["demolition"], "sapper", "charm", [["shrapnel", 0.1]], [["bomb_on_kill", 0.06]], "10% OF SHOTS EXPLODE. KILLS SOMETIMES DROP BOMBS."],
	["shep_hat", "SHEPHERD'S HAT", "head", "rare", ["swarm"], "shepherd", "hat", [["fam_dmg", 0.25]], [], "WISPS DEAL 25% MORE."],
	["shep_cloak", "SHEPHERD'S CLOAK", "body", "rare", ["swarm"], "shepherd", "cloak", [["max_hp", 2]], [["kill_wisp", 0.08]], "KILLS SOMETIMES RAISE A WISP."],
	["shep_boots", "SHEPHERD'S SANDALS", "feet", "rare", ["swarm"], "shepherd", "boots", [["fam_rate", 1.2]], [], "WISPS FIRE 20% FASTER."],
	["shep_crook", "SHEPHERD'S BELL", "trinket", "epic", ["swarm"], "shepherd", "amulet", [["familiars", 1]], [], "A WISP FOLLOWS YOU."],
	# --- Helms ---
	["tinhelm", "DENTED TIN HELM", "head", "common", ["bulwark"], null, "helm", [["armor", 1]], [], "BETTER THAN NOTHING."],
	["leathercap", "LEATHER CAP", "head", "common", [], null, "hat", [["max_hp", 2]], [], "+1 MAX HEART."],
	["huntershood", "HUNTER'S HOOD", "head", "common", ["shadow"], null, "hood", [["crit", 0.05]], [], "+5% CRIT CHANCE."],
	["scholarcap", "SCHOLAR'S CAP", "head", "common", ["arcane"], null, "hat", [["xp_mult", 1.2]], [], "+20% EXPERIENCE."],
	["ironmask", "IRON DEATHMASK", "head", "rare", ["blood"], null, "mask", [["dmg", 1.15]], [["low_hp_dmg", 0.25]], "+25% DAMAGE WHEN WOUNDED."],
	["owlhelm", "OWL-EYED HELM", "head", "rare", [], null, "helm", [["life", 1.2]], [["far_dmg", 0.2]], "+20% RANGE. +20% DAMAGE FROM AFAR."],
	["crownofthorns", "CROWN OF THORNS", "head", "epic", ["venom"], null, "crown", [["thorns", 15], ["poison", 1]], [["thorns_nova", 8]], "WHEN HIT, FIRE 8 THORNS AROUND YOU."],
	["hornedhelm", "HORNED WARHELM", "head", "epic", ["blood"], null, "helm", [["max_hp", 2], ["dmg", 1.1]], [["kill_haste", 1.5]], "KILLS GIVE A SHORT BURST OF SPEED."],
	["seerveil", "SEER'S VEIL", "head", "epic", ["arcane"], null, "hood", [["luck", 2]], [["trait_dmg", 0.02]], "+2% DAMAGE PER TRAIT RANK. BETTER RELICS."],
	["kingscrown", "CROWN OF THE LOST KING", "head", "legend", ["fortune"], null, "crown", [["gold_mult", 1.5], ["luck", 2]], [["relic_dmg", 0.03]], "+3% DAMAGE FOR EVERY RELIC YOU OWN."],
	["stormcrownhelm", "TEMPEST DIADEM", "head", "legend", ["storm"], null, "crown", [["chain", 0.25], ["chain_jumps", 1]], [["crit_chain", 1]], "CRITS ALWAYS ARC. ARCS JUMP FURTHER."],
	["headsman", "HEADSMAN'S HOOD", "head", "legend", ["blood"], null, "hood", [["crit", 0.1]], [["execute", 0.15]], "+10% CRIT. INSTANTLY KILLS FOES BELOW 15%."],
	# --- Armor ---
	["paddedjack", "PADDED JACK", "body", "common", [], null, "leather", [["max_hp", 2]], [], "+1 MAX HEART."],
	["chainshirt", "CHAIN SHIRT", "body", "common", ["bulwark"], null, "plate", [["armor", 1], ["speed", 0.96]], [], "+1 ARMOR, A LITTLE HEAVY."],
	["travelcloak", "TRAVELLER'S CLOAK", "body", "common", ["shadow"], null, "cloak", [["speed", 1.06], ["evade", 0.03]], [], "LIGHT AND HARD TO HIT."],
	["acolyterobe", "ACOLYTE ROBE", "body", "common", ["arcane"], null, "robe", [["rate", 1.08]], [], "+8% FIRE RATE."],
	["bloodplate", "BLOODSTAINED PLATE", "body", "rare", ["blood"], null, "plate", [["armor", 1], ["max_hp", 2]], [["kill_heal", 0.02]], "KILLS SOMETIMES HEAL."],
	["spikedmail", "SPIKED MAIL", "body", "rare", ["bulwark"], null, "plate", [["armor", 1], ["thorns", 20]], [], "FOES THAT TOUCH YOU REGRET IT."],
	["hunterscoat", "MONSTER HUNTER'S COAT", "body", "rare", [], null, "leather", [["max_hp", 2], ["potion_heal", 2]], [["elite_dmg", 0.25]], "POTIONS HEAL MORE. +25% VS ELITES AND GUARDIANS."],
	["smugglercoat", "SMUGGLER'S COAT", "body", "rare", ["fortune"], null, "cloak", [["max_potions", 1], ["keys", 1]], [], "+1 POTION SLOT AND A SPARE KEY."],
	["mirrorplate", "MIRROR PLATE", "body", "epic", ["arcane"], null, "plate", [["armor", 1]], [["reflect_hit", 1]], "WHEN HIT, FIRE THE PAIN BACK AS 12 SHOTS."],
	["berserkerhide", "BERSERKER HIDE", "body", "epic", ["blood"], null, "leather", [["max_hp", 4], ["armor", -10]], [["low_hp_dmg", 0.4]], "+2 MAX HEARTS BUT NO ARMOR. +40% DAMAGE WHEN WOUNDED."],
	["phoenixmantle", "PHOENIX MANTLE", "body", "legend", ["pyre"], null, "robe", [["max_hp", 2], ["burn", 0.2]], [["revive_g", 1]], "ONCE PER RUN, RISE AGAIN WITH 2 HEARTS."],
	["voidshroud", "VOID SHROUD", "body", "legend", ["shadow"], null, "cloak", [["evade", 0.15], ["dodge_charges", 1], ["charges", 1]], [["roll_nova", 10]], "15% DODGE. +1 ROLL. ROLLING FIRES A RING OF SHOTS."],
	# --- Boots ---
	["worntboots", "WORN BOOTS", "feet", "common", [], null, "boots", [["speed", 1.08]], [], "+8% MOVE SPEED."],
	["ironboots", "IRON BOOTS", "feet", "common", ["bulwark"], null, "greaves", [["armor", 1], ["speed", 0.95]], [], "+1 ARMOR. SLOWER."],
	["sandals", "PILGRIM SANDALS", "feet", "common", [], null, "boots", [["dodge_cd", 0.85]], [], "ROLLS RECHARGE FASTER."],
	["runnersboots", "COURIER BOOTS", "feet", "rare", ["fortune"], null, "boots", [["speed", 1.12]], [["moving_dmg", 0.15]], "+15% DAMAGE WHILE MOVING."],
	["ninjatabi", "SILENT TABI", "feet", "rare", ["shadow"], null, "boots", [["roll_speed", 1.2], ["dodge_charges", 1], ["charges", 1]], [], "+1 ROLL CHARGE. LONGER ROLLS."],
	["anchorboots", "ANCHOR BOOTS", "feet", "rare", ["bulwark"], null, "greaves", [["armor", 1]], [["still_dmg", 0.3]], "+30% DAMAGE WHILE STANDING STILL."],
	["wingedboots", "WINGED BOOTS", "feet", "epic", ["storm"], null, "boots", [["speed", 1.15], ["dodge_cd", 0.8]], [["roll_zap", 1]], "ROLLING CALLS LIGHTNING ON THE NEAREST FOE."],
	["coalwalkers", "COALWALKERS", "feet", "epic", ["pyre"], null, "greaves", [["speed", 1.08], ["burn", 0.1]], [["fire_steps", 1]], "YOU LEAVE BURNING FOOTPRINTS."],
	["sevenleague", "SEVEN-LEAGUE BOOTS", "feet", "legend", [], null, "boots", [["speed", 1.25], ["roll_speed", 1.25], ["dodge_cd", 0.75]], [["moving_dmg", 0.25]], "BLINDINGLY FAST. +25% DAMAGE WHILE MOVING."],
	# --- Trinkets ---
	["luckycharm", "RABBIT'S FOOT", "trinket", "common", ["fortune"], null, "charm", [["luck", 1]], [], "BETTER RELIC RARITY."],
	["whetring", "WHETSTONE RING", "trinket", "common", [], null, "ring", [["dmg", 1.1]], [], "+10% DAMAGE."],
	["quickring", "QUICKSILVER RING", "trinket", "common", [], null, "ring", [["rate", 1.1]], [], "+10% FIRE RATE."],
	["vialbelt", "BELT OF VIALS", "trinket", "common", [], null, "charm", [["max_potions", 1], ["potions", 1]], [], "+1 POTION SLOT AND A POTION."],
	["bombbag", "POWDER BANDOLIER", "trinket", "common", ["demolition"], null, "charm", [["bombs", 3]], [], "+3 BOMBS."],
	["toothnecklace", "WOLF TOOTH NECKLACE", "trinket", "rare", ["blood"], null, "charm", [["crit", 0.08], ["crit_mult", 0.2]], [], "+8% CRIT, CRITS DEAL MORE."],
	["hourglassamulet", "SANDS OF ESCAPE", "trinket", "rare", ["shadow"], null, "amulet", [["dodge_charges", 1], ["charges", 1]], [], "+1 ROLL CHARGE."],
	["emberheartgem", "EMBER HEART", "trinket", "rare", ["pyre"], null, "amulet", [["burn", 0.15]], [["fire_aura", 1]], "FOES NEAR YOU CATCH FIRE."],
	["frostshard", "SHARD OF WINTER", "trinket", "rare", ["frost"], null, "amulet", [["chill", 0.15]], [["chill_crit", 0.15]], "+15% CRIT AGAINST CHILLED FOES."],
	["venomsac", "VENOM SAC", "trinket", "rare", ["venom"], null, "charm", [["poison", 1]], [["status_dmg", 0.15]], "+15% DAMAGE TO AFFLICTED FOES."],
	["stormbottle", "BOTTLED LIGHTNING", "trinket", "rare", ["storm"], null, "amulet", [["chain", 0.15]], [], "+15% ARC CHANCE."],
	["ledger", "MERCHANT'S LEDGER", "trinket", "rare", ["fortune"], null, "charm", [["shop_disc", 0.15]], [["room_gold", 5]], "SHOPS 15% CHEAPER. GAIN 5 GOLD AFTER EACH ROOM."],
	["vampirefang", "VAMPIRE FANG", "trinket", "epic", ["blood"], null, "charm", [["crit", 0.05]], [["leech", 0.02]], "2% OF HITS HEAL YOU."],
	["eyeofstorm", "EYE OF THE STORM", "trinket", "epic", ["storm"], null, "amulet", [["chain", 0.2]], [["nth_zap", 8]], "EVERY 8TH SHOT CALLS LIGHTNING."],
	["hollowidol", "HOLLOW IDOL", "trinket", "epic", ["arcane"], null, "amulet", [["count", 1], ["dmg", 0.92]], [["split", 1]], "+1 PROJECTILE. SHOTS SPLIT ON THEIR FIRST HIT."],
	["grimoire", "BLACK GRIMOIRE", "trinket", "epic", ["shadow"], null, "amulet", [["dmg", 1.15]], [["souls", 0.004]], "EVERY KILL THIS FLOOR ADDS 0.4% DAMAGE."],
	["heartofglass", "HEART OF GLASS", "trinket", "legend", ["arcane"], null, "amulet", [["dmg", 1.5], ["max_hp", -2]], [["crit_explode", 0.2]], "+50% DAMAGE BUT -1 MAX HEART. CRITS SOMETIMES EXPLODE."],
	["dragonheart", "DRAGON'S HEART", "trinket", "legend", ["pyre"], null, "amulet", [["max_hp", 4], ["burn", 0.3]], [["kill_explode", 0.6]], "+2 MAX HEARTS. FOES YOU SLAY EXPLODE IN FLAME."],
	["gamblerdie", "GAMBLER'S LAST DIE", "trinket", "legend", ["fortune"], null, "charm", [["crit", 0.15], ["crit_mult", 0.5], ["luck", 1]], [], "+15% CRIT AND CRITS DEAL MUCH MORE. FORTUNE FAVOURS YOU."],]

## Readable lines for stat tuples.
const STAT_TEXT := {
	"dmg": "DAMAGE", "rate": "FIRE RATE", "shot_speed": "SHOT SPEED", "life": "RANGE", "size": "SHOT SIZE", "speed": "MOVE SPEED",
	"dodge_cd": "ROLL RECHARGE", "gold_mult": "GOLD", "roll_speed": "ROLL SPEED", "bomb_mult": "BOMB DAMAGE", "bomb_r": "BOMB RADIUS",
	"xp_mult": "EXPERIENCE", "fam_rate": "WISP FIRE RATE", "max_hp": "MAX HEARTS", "armor": "ARMOR", "crit": "CRIT CHANCE",
	"crit_mult": "CRIT DAMAGE", "burn": "BURN CHANCE", "chill": "CHILL CHANCE", "poison": "POISON ON HIT", "chain": "ARC CHANCE",
	"evade": "DODGE CHANCE", "thorns": "THORNS", "familiars": "WISPS", "orbitals": "MOONS", "homing": "HOMING", "pierce": "PIERCE",
	"count": "PROJECTILES", "luck": "LUCK", "shop_disc": "SHOP DISCOUNT", "bombs": "BOMBS", "keys": "KEYS", "potions": "POTIONS",
	"max_potions": "POTION SLOTS", "potion_heal": "POTION HEALING", "dodge_charges": "ROLL CHARGES", "explode": "BURSTING SHOTS",
	"ricochet": "RICOCHET", "shrapnel": "EXPLODING SHOTS", "fam_dmg": "WISP DAMAGE", "chain_jumps": "ARC JUMPS", "echo": "ECHO",
}

static var _list: Array = []
static var _by_id := {}

static func all() -> Array:
	if _list.is_empty():
		for i in ROWS.size():
			var row: Array = ROWS[i]
			var tags: Array = row[4]
			var g := { "id": row[0], "name": row[1], "slot": row[2], "rarity": row[3], "tags": tags, "set": row[5],
				"shape": row[6], "stats": row[7], "hooks": row[8], "desc": row[9], "item": "gear",
				"new": i >= ORIGINAL_COUNT, "effects": row[10] if row.size() > 10 else [],
				"sprite": row[11] if row.size() > 11 else "g_" + row[0],
				"cols": Weapons.TAG_COLS[tags[0] if tags.size() > 0 else "core"] }
			_list.append(g)
			_by_id[g["id"]] = g
	return _list

static func by_id(id: String) -> Dictionary:
	all()
	return _by_id[id]

static func random_gear(rarity: String) -> Dictionary:
	var pool := []
	for g in all():
		if g["rarity"] == rarity:
			pool.append(g)
	return TB.pick(pool)

## Item rarity for drops, door rewards and shops (04b roll_item_rarity).
static func roll_item_rarity(floor_index: int, source: String = "drop") -> String:
	var f := floor_index
	var w := { "common": maxi(60 - 9 * f, 10), "rare": 30, "epic": 8 + 4 * f, "legend": 2 + 2 * f }
	if source == "boss":
		w = { "common": 0, "rare": 30, "epic": 45, "legend": 25 }
	if source == "elite":
		w = { "common": 0, "rare": 50, "epic": 38, "legend": 12 }
	return TB.weighted(w)

## "+25% DAMAGE" style line for a stat tuple, or "" when it is not shown.
static func stat_line(k: String, v: Variant) -> String:
	if not STAT_TEXT.has(k) or k == "charges":
		return ""
	var name: String = STAT_TEXT[k]
	if k in Weapons.MUL_KEYS:
		var pct := roundi((v - 1) * 100)
		if k == "dodge_cd":
			pct = -pct
		return "%+d%% %s" % [pct, name]
	match k:
		"max_hp":
			return "%+d %s" % [TB.idiv(int(v), 2), name]
		"crit", "burn", "chill", "chain", "evade", "shop_disc", "shrapnel", "echo", "fam_dmg":
			return "%+d%% %s" % [roundi(v * 100), name]
		"homing":
			return "%+.1f %s" % [v, name]
	return "%+d %s" % [int(v), name]

# ---------- Equipping (04b_items.rb) ----------
static func update_sets(p: Player, set_id: Variant, delta: int) -> void:
	if set_id == null:
		return
	var s: Dictionary = SETS[set_id]
	p.sets[set_id] = p.sets.get(set_id, 0) + delta
	var tier := 2 if p.sets[set_id] >= 4 else (1 if p.sets[set_id] >= 2 else 0)
	var have: int = p.set_tier.get(set_id, 0)
	while have < tier:
		have += 1
		if have == 1:
			Weapons.apply_tuples(p, s["b2"], 1, "s2:" + set_id)
		else:
			Weapons.apply_tuples(p, s.get("b4", []), 1, "s4:" + set_id)
			Weapons.apply_hooks(p, s.get("b4h", []), 1)
		G.toast(s["name"] + " SET: " + (s["d2"] if have == 1 else s["d4"]), "gold")
	while have > tier:
		if have == 1:
			Weapons.apply_tuples(p, s["b2"], -1, "s2:" + set_id)
		else:
			Weapons.apply_tuples(p, s.get("b4", []), -1, "s4:" + set_id)
			Weapons.apply_hooks(p, s.get("b4h", []), -1)
		have -= 1
	p.set_tier[set_id] = have

## Equips a piece of gear and returns the piece it replaced (or null).
static func equip_gear(p: Player, g: Dictionary) -> Variant:
	var old = p.gear.get(g["slot"])
	if old != null:
		Weapons.apply_tuples(p, old["stats"], -1, "g:" + old["id"])
		Weapons.apply_hooks(p, old["hooks"], -1)
		if not old["effects"].is_empty():
			Effects.apply_equipment(p, old["effects"], -1, "gfx:" + old["id"])
		p.gear[g["slot"]] = null
		update_sets(p, old["set"], -1)
	p.gear[g["slot"]] = g
	Weapons.apply_tuples(p, g["stats"], 1, "g:" + g["id"])
	Weapons.apply_hooks(p, g["hooks"], 1)
	if not g["effects"].is_empty():
		Effects.apply_equipment(p, g["effects"], 1, "gfx:" + g["id"])
	update_sets(p, g["set"], 1)
	Meta.meta["found_g"][g["id"]] = true
	if g["new"] or (old != null and old["new"]):
		Effects.recount_tags(p)
	return old
