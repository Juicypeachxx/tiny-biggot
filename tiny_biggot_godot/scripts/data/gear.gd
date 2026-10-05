class_name Gear
extends RefCounted
## Equipment (01c_items.rb GEAR / SETS / STAT_TEXT and the equip and set logic
## of 04b_items.rb, extended by the content batches). Rows are
## [id, name, slot, rarity, tags, set, shape, stats, hooks, desc, effects].
## The first ORIGINAL_COUNT rows are original; new rows may add effects.

const SLOTS := ["head", "body", "feet", "trinket"]
## Design spec section 6 (step 8): gloves, an amulet and two ring slots join the
## original four. Items say "ring"; a ring fills ring1 or ring2 (slot_for).
const NEW_SLOTS := ["hands", "neck", "ring1", "ring2"]
const ITEM_SLOTS := ["head", "body", "feet", "trinket", "hands", "neck", "ring"]
const SLOT_NAME := { "head": "HELM", "body": "ARMOR", "feet": "BOOTS", "trinket": "TRINKET",
	"hands": "GLOVES", "neck": "AMULET", "ring": "RING", "ring1": "RING", "ring2": "RING" }

static var _slots: Array = []

## Equipment slots in play: the original four, plus the new ones unless --classic.
static func slots() -> Array:
	if _slots.is_empty():
		_slots = SLOTS.duplicate()
		if not DebugArgs.has("classic"):
			_slots.append_array(NEW_SLOTS)
	return _slots

## The slot an item goes into. A ring takes a free ring slot, otherwise it
## replaces the lower-rarity ring (ring1 on a tie).
static func slot_for(p: Player, g: Dictionary) -> String:
	if g["slot"] != "ring":
		return g["slot"]
	for sl in ["ring1", "ring2"]:
		if p.gear.get(sl) == null:
			return sl
	var order := ["common", "rare", "epic", "legend"]
	return "ring2" if order.find(p.gear["ring2"]["rarity"]) < order.find(p.gear["ring1"]["rarity"]) else "ring1"

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
	"shepherd": {  "name": "SHEPHERD", "tag": "swarm", "b2": [["familiars", 1]], "b4h": [["legion", 1]], "d2": "+1 WISP", "d4": "EVERY 5 KILLS SUMMON A WISP"  },
	# Content batch 1: e2/e4 are effect lists (procs allowed).
	"duelist": { "name": "DUELIST", "tag": "edge", "b2": [["crit", 0.1]], "e4": [{ "on": "on_crit", "chance": 0.5, "do": [["damage", 0.5]] }], "d2": "+10% CRIT CHANCE", "d4": "HALF OF YOUR CRITS STRIKE AGAIN FOR 50%" },
	"ravager": { "name": "RAVAGER", "tag": "fury", "b2": [["dmg", 1.1]], "e4": [{ "on": "while_low_hp", "do": [["buff", "dmg", 0.5, 0], ["buff", "speed", 0.15, 0]] }], "d2": "+10% DAMAGE", "d4": "BELOW HALF HEALTH: +50% DAMAGE, +15% SPEED" },
	# Content batch 3 (step 8) sets.
	"conclave": { "name": "CONCLAVE", "tag": "arcane", "b2": [["echo", 0.15]], "e4": [{ "on": "every_n_shots", "every": 6, "do": [["nova", 8, 0.6, "spark", 1.5]] }], "d2": "15% CHANCE FOR SHOTS TO CAST AGAIN", "d4": "EVERY 6TH ATTACK SPINS OUT A RING OF 8 STARS" },
	"headhunter": { "name": "HEADHUNTER", "tag": "edge", "b2": [["elite_mult", 0.2]], "e4": [{ "on": "on_kill", "if": "elite", "do": [["gold", 8], ["buff", "crit", 1.0, 5.0], ["vfx", "label", "BOUNTY!", "#f2c94c"]] }], "d2": "+20% DAMAGE TO ELITES", "d4": "ELITE KILLS PAY 8 GOLD AND DOUBLE CRIT CHANCE FOR 5S" },
	# Content batch 4 (chaos) sets.
	"jester": { "name": "JESTER", "tag": "fortune", "b2": [["luck", 1]], "e4": [{ "on": "every_n_seconds", "period": 6.0, "if": "fighting", "do": [["chaos"]] }], "d2": "+1 LUCK", "d4": "EVERY 6S IN A FIGHT, SOMETHING RANDOM HAPPENS" },
	"starfall": { "name": "STARFALL", "tag": "pyre", "b2": [["burn", 0.15]], "e4": [{ "on": "every_n_seconds", "period": 4.0, "if": "fighting", "do": [["meteor", 2.0, 32]] }], "d2": "+15% BURN CHANCE", "d4": "EVERY 4S IN A FIGHT A METEOR FALLS ON A FOE" },
	"voidwalker": { "name": "VOIDWALKER", "tag": "shadow", "b2": [["evade", 0.08]], "e4": [{ "on": "on_roll", "cd": 1.0, "do": [["pull", 90, 260], ["explode", 38, 1.2]] }], "d2": "+8% DODGE CHANCE", "d4": "ROLLING DRAGS FOES IN AND BLASTS THEM FOR 120%" },
}

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
	["gamblerdie", "GAMBLER'S LAST DIE", "trinket", "legend", ["fortune"], null, "charm", [["crit", 0.15], ["crit_mult", 0.5], ["luck", 1]], [], "+15% CRIT AND CRITS DEAL MUCH MORE. FORTUNE FAVOURS YOU."],
	# ---------- Content batch 1 (Tiny Biggot Rogues) ----------
	["duel_hat", "DUELIST'S FEATHERCAP", "head", "rare", ["edge"], "duelist", "hat", [["crit", 0.06]], [], "+6% CRIT, AND +30% MORE FOR 3S AFTER ENTERING A ROOM.", [{ "on": "on_room_enter", "do": [["buff", "crit", 0.3, 3.0]] }], "g_butcher_cap"],
	["duel_coat", "DUELIST'S DOUBLET", "body", "rare", ["edge"], "duelist", "leather", [["max_hp", 2]], [], "CRITS GIVE +10% MOVE SPEED FOR 1S.", [{ "on": "on_crit", "do": [["buff", "speed", 0.1, 1.0]] }], "g_gild_vest"],
	["duel_boots", "DUELIST'S STEPS", "feet", "rare", ["edge"], "duelist", "boots", [["speed", 1.06]], [], "ROLLING SHARPENS YOU: +15% CRIT DAMAGE FOR 2S.", [{ "on": "on_roll", "do": [["buff", "crit_mult", 0.15, 2.0]] }], "g_night_boots"],
	["duel_ring", "DUELIST'S SIGNET", "trinket", "epic", ["edge"], "duelist", "ring", [["crit_mult", 0.3]], [], "CRITS DEAL +0.3X. CRITS ON ELITES STRIKE AGAIN FOR 50%.", [{ "on": "on_crit", "if": "elite", "do": [["damage", 0.5]] }], "g_whetring"],
	["rav_helm", "RAVAGER'S HELM", "head", "rare", ["fury"], "ravager", "helm", [["max_hp", 2]], [], "+1 MAX HEART. WHEN HIT, +40% DAMAGE FOR 2S.", [{ "on": "on_damage_taken", "do": [["buff", "dmg", 0.4, 2.0]] }], "g_hornedhelm"],
	["rav_hide", "RAVAGER'S HIDE", "body", "rare", ["fury"], "ravager", "leather", [["max_hp", 2]], [["low_hp_dmg", 0.2]], "+20% DAMAGE WHEN WOUNDED.", [], "g_berserkerhide"],
	["rav_boots", "RAVAGER'S TREADS", "feet", "rare", ["fury"], "ravager", "greaves", [["speed", 1.08]], [], "KILLS GIVE +15% MOVE SPEED FOR 2S.", [{ "on": "on_kill", "do": [["buff", "speed", 0.15, 2.0]] }], "g_butcher_boots"],
	["rav_tooth", "RAVAGER'S FANG", "trinket", "epic", ["fury"], "ravager", "charm", [["dmg", 1.1]], [], "WHEN HIT, +30% DAMAGE FOR 3S.", [{ "on": "on_damage_taken", "do": [["buff", "dmg", 0.3, 3.0]] }], "g_night_fang"],
	["hawkmonocle", "HAWK MONOCLE", "head", "rare", ["edge"], null, "hat", [["crit", 0.08]], [["far_dmg", 0.15]], "+8% CRIT. +15% DAMAGE FROM AFAR.", [], "g_owlhelm"],
	["razorcharm", "RAZOR CHARM", "trinket", "legend", ["edge"], null, "charm", [["crit", 0.12], ["overcrit", 0.5]], [], "+12% CRIT, PAST 100% CAN CRIT AGAIN. CRIT KILLS FLING 3 BLADES.", [{ "on": "on_kill", "if": "crit", "do": [["nova", 3, 0.5, "spark"]] }], "g_gamblerdie"],
	["leechmail", "LEECH-LINK MAIL", "body", "rare", ["blood"], null, "plate", [["armor", 1]], [["leech", 0.015]], "+1 ARMOR. 1.5% OF HITS HEAL.", [], "g_bloodplate"],
	["clotring", "CLOTTING RING", "trinket", "rare", ["blood"], null, "ring", [["bleed", 1]], [], "CRITS MAKE FOES BLEED. KILLING A BLEEDING FOE MAY HEAL.", [{ "on": "on_kill", "chance": 0.05, "if": "bleeding", "do": [["heal", 1]] }], "g_vampirefang"],
	["butchermask", "SCARLET HOOD", "head", "epic", ["blood"], null, "hood", [["dmg", 1.15]], [], "+15% DAMAGE. EACH ROOM COSTS HALF A HEART AND GIVES +30% DAMAGE FOR 12S.", [{ "on": "on_room_enter", "do": [["hurt_self", 1], ["buff", "dmg", 0.3, 12.0]] }], "g_headsman"],
	["ashcloak", "ASHEN CLOAK", "body", "rare", ["pyre"], null, "cloak", [["burn", 0.1]], [["fire_aura", 1]], "FOES NEAR YOU CATCH FIRE.", [], "g_ember_robe"],
	["cinderboots", "CINDER SANDALS", "feet", "common", ["pyre"], null, "boots", [["speed", 1.05]], [], "ROLLING LEAVES A BLAST OF FIRE.", [{ "on": "on_roll", "do": [["explode", 20, 0.5]] }], "g_coalwalkers"],
	["kilnheart", "KILN HEART", "trinket", "epic", ["pyre"], null, "amulet", [["burn", 0.2]], [], "BURNING FOES YOU KILL EXPLODE FOR 80% DAMAGE.", [{ "on": "on_kill", "if": "burning", "do": [["explode", 26, 0.8]] }], "g_emberheartgem"],
	["rotgloves", "ROTTING WRAPS", "body", "common", ["venom"], null, "robe", [["poison", 1]], [], "+1 POISON ON HIT. ENTERING A ROOM, A ROT CLOUD POISONS FOES NEAR YOU.", [{ "on": "on_room_enter", "do": [["status_area", "poison", 1, 70]] }], "g_plague_coat"],
	["miasmamask", "MIASMA MASK", "head", "rare", ["venom"], null, "mask", [["poison", 1]], [["status_dmg", 0.15]], "+15% DAMAGE TO AFFLICTED FOES.", [], "g_plague_mask"],
	["blightboots", "BLIGHTSTEP BOOTS", "feet", "rare", ["venom"], null, "boots", [["speed", 1.05]], [["toxic_steps", 1]], "YOU LEAVE POISON PUDDLES WHILE MOVING. ROLLING POISONS FOES NEAR YOU.", [{ "on": "on_roll", "cd": 1.0, "do": [["status_area", "poison", 1, 50]] }], "g_plague_boots"],
	["conductorhelm", "CONDUCTOR'S HELM", "head", "rare", ["storm"], null, "helm", [["chain", 0.1], ["chain_jumps", 1]], [], "+10% ARC CHANCE, ARCS JUMP 1 FURTHER. ROLLING DISCHARGES ON 2 FOES.", [{ "on": "on_roll", "cd": 1.0, "do": [["bolts", 2, 0.6]] }], "g_thunder_helm"],
	["staticboots", "STATIC STRIDERS", "feet", "rare", ["storm"], null, "boots", [["speed", 1.08]], [], "ROLLING SHOCKS THE NEAREST FOE TWICE.", [{ "on": "on_roll", "do": [["status", "shock", 2]] }], "g_thunder_boots"],
	["lightningrod", "LIGHTNING ROD", "trinket", "epic", ["storm"], null, "amulet", [["rate", 1.08]], [], "EVERY 4 SECONDS, LIGHTNING STRIKES THE NEAREST FOE.", [{ "on": "every_n_seconds", "period": 4.0, "do": [["lightning", 1.0]] }], "g_stormbottle"],
	["splittinglens", "SPLITTING LENS", "head", "rare", ["arcane"], null, "hat", [["shot_speed", 1.1]], [["split", 1]], "SHOTS SPLIT ON THEIR FIRST HIT.", [], "g_seerveil"],
	["volleyrobe", "VOLLEY ROBE", "body", "epic", ["arcane"], null, "robe", [["count", 1]], [], "+1 PROJECTILE. EVERY 15TH ATTACK ALSO FIRES 3 SHOTS BEHIND YOU.", [{ "on": "every_n_shots", "every": 15, "do": [["shoot_at", 3, 0.6, "", 0.3, 3.14159]] }], "g_arch_robe"],
	["ricochetband", "RICOCHET BAND", "trinket", "rare", ["arcane"], null, "ring", [["ricochet", 1]], [], "SHOTS JUMP TO ANOTHER FOE AFTER A HIT. 30% OF KILLS SPARK LIGHTNING.", [{ "on": "on_kill", "chance": 0.3, "do": [["bolts", 1, 0.5]] }], "g_quickring"],
	["beekeeperhat", "KEEPER'S VEIL", "head", "common", ["swarm"], null, "hat", [["fam_dmg", 0.2]], [], "WISPS DEAL 20% MORE. PICKING SOMETHING UP RAISES A WISP FOR 6S.", [{ "on": "on_pickup", "cd": 1.0, "do": [["summon", 6.0]] }], "g_shep_hat"],
	["broodcloak", "BROOD CLOAK", "body", "rare", ["swarm"], null, "cloak", [["max_hp", 2]], [], "WHEN HIT, A WISP RISES FOR 8S.", [{ "on": "on_damage_taken", "do": [["summon", 8.0]] }], "g_shep_cloak"],
	["callingwhistle", "CALLING WHISTLE", "trinket", "epic", ["swarm"], null, "charm", [["familiars", 1], ["fam_rate", 1.15]], [], "+1 WISP, 15% FASTER. LEVELLING UP CALLS A WISP FOR 20S.", [{ "on": "on_level_up", "do": [["summon", 20.0]] }], "g_shep_crook"],
	["fadingcowl", "FADING COWL", "head", "rare", ["shadow"], null, "hood", [["evade", 0.05]], [], "5% DODGE. ROLLING GIVES +30% DAMAGE FOR 1.5S.", [{ "on": "on_roll", "do": [["buff", "dmg", 0.3, 1.5]] }], "g_night_hood"],
	["silkboots", "SILKEN SLIPPERS", "feet", "rare", ["shadow"], null, "boots", [["dodge_cd", 0.85], ["roll_speed", 1.1]], [], "ROLLS RECHARGE FASTER, GO FURTHER AND SHOVE FOES ASIDE.", [{ "on": "on_roll", "cd": 0.5, "do": [["push", 50, 200]] }], "g_ninjatabi"],
	["mirrorcape", "MIRROR CAPE", "body", "epic", ["shadow"], null, "cloak", [["dodge_charges", 1], ["charges", 1]], [], "+1 ROLL CHARGE. ROLLING ERASES NEARBY SHOTS.", [{ "on": "on_roll", "do": [["clear_shots", 32]] }], "g_voidshroud"],
	["anvilhelm", "ANVIL HELM", "head", "rare", ["bulwark"], null, "helm", [["armor", 2], ["speed", 0.95]], [], "+2 ARMOR, A LITTLE SLOWER. WHEN HIT, IT RINGS: FOES NEAR YOU ARE STUNNED.", [{ "on": "on_damage_taken", "do": [["status_area", "stun", 1, 50]] }], "g_bastion_helm"],
	["thornplate", "BRAMBLE PLATE", "body", "rare", ["bulwark"], null, "plate", [["thorns", 15]], [["thorns_nova", 6]], "+15 THORNS. WHEN HIT, FIRE 6 THORNS.", [], "g_spikedmail"],
	["oathstone", "OATHSTONE", "trinket", "epic", ["bulwark"], null, "amulet", [["max_hp", 2]], [], "CLEARING A ROOM GRANTS 1 ARMOR.", [{ "on": "on_room_clear", "do": [["armor", 1]] }], "g_bastion_seal"],
	["skullcap", "BATTLE SKULLCAP", "head", "common", ["fury"], null, "helm", [["dmg", 1.06]], [], "+6% DAMAGE. BELOW HALF HEALTH, +15% MORE.", [{ "on": "while_low_hp", "do": [["buff", "dmg", 0.15, 0]] }], "g_ironmask"],
	["bloodboil", "BLOODBOIL VIAL", "trinket", "rare", ["fury"], null, "charm", [["rate", 1.05]], [], "KILLS GIVE +25% FIRE RATE FOR 1.5S.", [{ "on": "on_kill", "do": [["buff", "rate", 0.25, 1.5]] }], "g_vialbelt"],
	["merchantshat", "MERCHANT'S TRICORN", "head", "rare", ["fortune"], null, "crown", [["gold_mult", 1.15]], [], "+15% GOLD. CLEARING A ROOM PAYS 3 GOLD.", [{ "on": "on_room_clear", "do": [["gold", 3]] }], "g_gild_crown"],
	["coinpurse", "BOTTOMLESS PURSE", "trinket", "rare", ["fortune"], null, "charm", [["luck", 1]], [["gold_dmg", 0.05]], "BETTER RELICS. +5% DAMAGE PER 100 GOLD.", [], "g_ledger"],
	["goldtoes", "GOLD-TOED BOOTS", "feet", "common", ["fortune"], null, "boots", [["speed", 1.05], ["shop_disc", 0.08]], [], "SHOPS 8% CHEAPER. 10% OF ROLLS KICK UP A COIN.", [{ "on": "on_roll", "chance": 0.1, "cd": 1.0, "do": [["drop", "coin"]] }], "g_gild_boots"],
	["thornedcrown", "CROWN OF SPITE", "head", "epic", ["malice"], null, "crown", [["max_hp", -2], ["dmg", 1.3]], [], "+30% DAMAGE BUT -1 MAX HEART. AT FULL HEALTH, KILLS GIVE +20% FOR 2S.", [{ "on": "on_kill", "if": "full_hp", "do": [["buff", "dmg", 0.2, 2.0]] }], "g_crownofthorns"],
	["hexedmantle", "HEXED MANTLE", "body", "rare", ["malice"], null, "robe", [["max_hp", 2]], [], "20% OF HITS CURSE FOES.", [{ "on": "on_hit", "chance": 0.2, "do": [["status", "curse", 1]] }], "g_hunterscoat"],
	["grudgeboots", "GRUDGE BOOTS", "feet", "rare", ["malice"], null, "greaves", [["speed", 1.05]], [], "WHEN HIT, CURSE ALL... THE NEAREST FOE AND MAKE IT VULNERABLE.", [{ "on": "on_damage_taken", "do": [["status", "curse", 1], ["status", "vulnerable", 1]] }], "g_ironboots"],
	["blackpearl", "BLACK PEARL", "trinket", "legend", ["malice"], null, "amulet", [["max_hp", -2]], [], "-1 MAX HEART. +80% DAMAGE. CURSED FOES YOU KILL EXPLODE.", [["pct", "dmg", 0.8], { "on": "on_kill", "if": "cursed", "do": [["explode", 30, 1.0]] }], "g_heartofglass"],
	["pilgrimpack", "PILGRIM'S PACK", "body", "common", [], null, "leather", [["max_potions", 1], ["potion_heal", 2]], [], "+1 POTION SLOT, POTIONS HEAL MORE. HALF OF NEW FLOORS GIVE A POTION.", [{ "on": "on_floor_start", "chance": 0.5, "do": [["drop", "potion"]] }], "g_smugglercoat"],
	["luckyhorseshoe", "BENT HORSESHOE", "trinket", "common", ["fortune"], null, "charm", [["luck", 1]], [], "BETTER RELIC RARITY. 10% OF KILLS PAY 1 GOLD.", [{ "on": "on_kill", "chance": 0.1, "do": [["gold", 1]] }], "g_luckycharm"],
	["scoutboots", "SCOUT'S BOOTS", "feet", "common", [], null, "boots", [["speed", 1.1]], [], "+10% MOVE SPEED, AND +30% MORE FOR 2S AFTER ENTERING A ROOM.", [{ "on": "on_room_enter", "do": [["buff", "speed", 0.3, 2.0]] }], "g_worntboots"],
	["tinkerhelm", "TINKER'S GOGGLES", "head", "rare", ["demolition"], null, "hat", [["bomb_r", 1.2]], [], "BIGGER BLASTS. CLEARING A ROOM GIVES 1 BOMB 40% OF THE TIME.", [{ "on": "on_room_clear", "chance": 0.4, "do": [["drop", "bomb"]] }], "g_sapper_helm"],
	["frostwardcoat", "FROSTWARD COAT", "body", "rare", ["frost"], null, "plate", [["armor", 1], ["chill", 0.1]], [], "+1 ARMOR. +10% CHILL. WHEN HIT, WEAKEN THE NEAREST FOE.", [{ "on": "on_damage_taken", "do": [["status", "weakened", 2]] }], "g_frost_plate"],
	# ---------- Content batch 3 (step 8): equipment ----------
	["brawlerwraps", "BRAWLER'S WRAPS", "hands", "common", ["fury"], null, "gloves", [["rate", 1.06]], [], "+6% FIRE RATE. EVERY 6TH ATTACK ALSO KNOCKS FOES NEAR YOU BACK.", [{ "on": "every_n_shots", "every": 6, "do": [["push", 40, 200]] }], "g_leatherglove"],
	["ironfist", "IRON FIST", "hands", "rare", ["bulwark"], null, "gloves", [["armor", 1]], [], "GRANTS 1 ARMOR. WHEN HIT, PUNCH BACK FOR 200% AT THE NEAREST FOE.", [{ "on": "on_damage_taken", "do": [["damage", 2.0]] }], "g_ironglove"],
	["pickpocket", "PICKPOCKET'S GLOVES", "hands", "rare", ["fortune"], null, "gloves", [["gold_mult", 1.1]], [], "+10% GOLD. 8% OF HITS FILCH 1 GOLD.", [{ "on": "on_hit", "chance": 0.08, "cd": 0.3, "do": [["gold", 1]] }], "g_shadowglove"],
	["alchemistmitts", "ALCHEMIST'S MITTS", "hands", "rare", ["venom"], null, "gloves", [["potion_heal", 1]], [], "POTIONS HEAL MORE. DRINKING ONE POISONS EVERY FOE NEAR YOU.", [{ "on": "on_potion", "do": [["status_area", "poison", 3, 90], ["vfx", "ring", "#63b84f", 60]] }], "g_venomglove"],
	["flintgloves", "FLINT GLOVES", "hands", "common", ["pyre"], null, "gloves", [["burn", 0.12]], [], "+12% BURN CHANCE. CRITS ALWAYS SET FOES ALIGHT.", [{ "on": "on_crit", "do": [["status", "burn", 1]] }], "g_emberglove"],
	["frostgrip", "FROSTGRIP", "hands", "rare", ["frost"], null, "gloves", [["chill", 0.15]], [], "+15% CHILL CHANCE. ROLLING CHILLS EVERY FOE NEAR YOU (EVERY 3S).", [{ "on": "on_roll", "cd": 3.0, "do": [["status_area", "chill", 1, 50]] }], "g_frostglove"],
	["duelistgauntlet", "PARRYING GAUNTLET", "hands", "epic", ["edge", "shadow"], null, "gloves", [["crit", 0.06]], [], "+6% CRIT. A PERFECT DODGE (ROLLING PAST A CLOSE SHOT) ERASES SHOTS NEAR YOU.", [{ "on": "on_roll", "if": "danger", "do": [["clear_shots", 50], ["vfx", "label", "PARRY!", "#f2c94c"]] }], "g_ironglove"],
	["quickdraw", "QUICKDRAW GLOVES", "hands", "rare", ["edge"], null, "gloves", [["rate", 1.05]], [], "+5% FIRE RATE. SWAPPING WEAPONS GIVES +40% FIRE RATE FOR 5S.", [{ "on": "on_weapon_swap", "do": [["buff", "rate", 0.4, 5.0]] }], "g_leatherglove"],
	["stormknuckles", "STORM KNUCKLES", "hands", "epic", ["storm"], null, "gloves", [["chain", 0.1]], [], "+10% ARC CHANCE. CRITS SHOCK.", [{ "on": "on_crit", "do": [["status", "shock", 1]] }], "g_frostglove"],
	["gravedigmitts", "GRAVEDIGGER'S MITTS", "hands", "common", ["demolition"], null, "gloves", [["bombs", 2], ["bomb_mult", 1.15]], [], "+2 BOMBS. BOMBS DEAL +15%. 5% OF KILLS DROP A BOMB.", [{ "on": "on_kill", "chance": 0.05, "do": [["drop", "bomb"]] }], "g_leatherglove"],
	["beastglove", "BEASTMASTER'S GLOVE", "hands", "rare", ["swarm"], null, "gloves", [["fam_dmg", 0.25]], [], "WISPS DEAL +25%. CLEARING A ROOM RAISES A WISP FOR 15S.", [{ "on": "on_room_clear", "do": [["summon", 15.0]] }], "g_clothglove"],
	["midasglove", "TOUCH OF MIDAS", "hands", "legend", ["fortune"], null, "gloves", [["gold_mult", 1.25]], [["gold_dmg", 0.1]], "+25% GOLD. +10% DAMAGE PER 100 GOLD. KILLS HAVE 10% CHANCE TO TURN TO COINS.", [{ "on": "on_kill", "chance": 0.1, "do": [["drop", "coin"], ["drop", "coin"]] }], "g_goldglove"],
	["boneamulet", "BONE AMULET", "neck", "common", ["malice"], null, "amulet", [["curse", 0.08]], [], "8% OF HITS CURSE. CURSED FOES YOU KILL HEAL YOU (5%).", [{ "on": "on_kill", "if": "cursed", "chance": 0.05, "do": [["heal", 1]] }], "g_toothnecklace"],
	["hourglass", "SANDS OF RESPITE", "neck", "rare", ["shadow"], null, "amulet", [["dodge_cd", 0.85]], [], "ROLLS RECHARGE 15% FASTER. ENTERING A ROOM REFUNDS A ROLL.", [{ "on": "on_room_enter", "do": [["refund_roll"]] }], "g_hourglassamulet"],
	["phylactery", "CRACKED PHYLACTERY", "neck", "legend", ["malice", "bulwark"], null, "amulet", [["max_hp", -2]], [], "-1 MAX HEART, BUT YOU RISE ONCE MORE THIS RUN, AND EACH FLOOR STARTS WITH +1 ARMOR.", [["grant", "revive", 1], { "on": "on_floor_start", "do": [["armor", 1]] }], "g_hollowidol"],
	["stormeye", "EYE OF THE GALE", "neck", "rare", ["storm"], null, "amulet", [["chain_jumps", 1]], [], "ARCS JUMP ONE MORE TIME. IN A FIGHT, SHOCK THE NEAREST FOE EVERY 2S.", [{ "on": "every_n_seconds", "period": 2.0, "if": "fighting", "do": [["status", "shock", 1]] }], "g_eyeofstorm"],
	["emberheart", "EMBER LOCKET", "neck", "rare", ["pyre"], null, "amulet", [["burn", 0.1]], [], "+10% BURN. WHEN HIT, SET EVERY FOE NEAR YOU ABLAZE.", [{ "on": "on_damage_taken", "do": [["status_area", "burn", 2, 70]] }], "g_emberheartgem"],
	["wolftooth", "WOLF-TOOTH CHARM", "neck", "common", ["blood"], null, "amulet", [["crit", 0.04]], [], "+4% CRIT. CRITS ON BLEEDING FOES HEAL 1 HALF-HEART 5% OF THE TIME.", [{ "on": "on_crit", "chance": 0.05, "if": "bleeding", "do": [["heal", 1]] }], "g_vampirefang"],
	["frostlocket", "WINTER LOCKET", "neck", "rare", ["frost", "bulwark"], null, "amulet", [["armor", 1]], [], "GRANTS 1 ARMOR. WHEN HIT, FREEZE NEARBY SHOTS AWAY.", [{ "on": "on_damage_taken", "do": [["clear_shots", 60]] }], "g_frost_amulet"],
	["sagestone", "SAGE'S STONE", "neck", "epic", ["arcane"], null, "amulet", [["xp_mult", 1.2]], [], "+20% EXPERIENCE. EVERY LEVEL-UP FIRES A RING OF 16 SPARKS.", [{ "on": "on_level_up", "do": [["nova", 16, 1.0, "spark"]] }], "g_emberheartgem"],
	["dragonscale", "DRAGONSCALE PENDANT", "neck", "epic", ["pyre", "fury"], null, "amulet", [["dmg", 1.1]], [], "+10% DAMAGE. BELOW HALF HEALTH, EVERY 3S A BLAST OF FIRE AROUND YOU.", [{ "on": "every_n_seconds", "period": 3.0, "if": "low_hp", "do": [["explode", 40, 1.5]] }], "g_dragonheart"],
	["deckpendant", "THE LAST CARD", "neck", "legend", ["arcane", "fortune"], null, "amulet", [["luck", 1]], [], "+1 LUCK. IN A FIGHT, DRAW AND PLAY A RANDOM CARD EVERY 8S.", [{ "on": "every_n_seconds", "period": 8.0, "if": "fighting", "do": [["card"]] }], "g_luckycharm"],
	["copperband", "COPPER BAND", "ring", "common", ["storm"], null, "ring", [["chain", 0.06]], [], "+6% ARC CHANCE. 20% OF HITS ON SHOCKED FOES ARC AGAIN.", [{ "on": "on_hit", "if": "shocked", "chance": 0.2, "do": [["chain", 0.4]] }], "g_thunder_ring"],
	["whetband", "WHETSTONE RING", "ring", "common", ["edge"], null, "ring", [["crit_mult", 0.15]], [], "CRITS DEAL +0.15X. 15% OF CRITS MAKE FOES BLEED.", [{ "on": "on_crit", "chance": 0.15, "do": [["status", "bleed", 1]] }], "g_whetring"],
	["cinderring", "CINDER RING", "ring", "common", ["pyre"], null, "ring", [["burn", 0.08]], [], "+8% BURN CHANCE. BURNING FOES LEAVE FIRE WHEN THEY DIE.", [{ "on": "on_kill", "if": "burning", "do": [["zone", "fire", 18, 1.5]] }], "g_ember_ring"],
	["swiftring", "RING OF HASTE", "ring", "common", ["shadow"], null, "ring", [["speed", 1.06]], [], "+6% MOVE SPEED. SHOOTING WHILE MOVING: +10% FIRE RATE.", [{ "on": "on_shoot", "if": "moving", "cd": 0.25, "do": [["buff", "rate", 0.1, 0.3]] }], "g_quickring"],
	["goldband", "GOLD BAND", "ring", "common", ["fortune"], null, "ring", [["gold_mult", 1.12]], [], "+12% GOLD. 30% OF CLEARED ROOMS PAY 3 GOLD.", [{ "on": "on_room_clear", "chance": 0.3, "do": [["gold", 3]] }], "g_gild_ring"],
	["venomring", "ASP RING", "ring", "rare", ["venom"], null, "ring", [["poison", 1]], [], "+1 POISON ON HIT. POISONED FOES YOU KILL SPREAD POISON TO THE NEAREST FOE.", [{ "on": "on_kill", "if": "poisoned", "do": [["status", "poison", 2]] }], "g_ember_ring"],
	["bloodring", "BLOOD-PACT RING", "ring", "rare", ["blood", "malice"], null, "ring", [["dmg", 1.12]], [], "+12% DAMAGE. EVERY 4TH ROOM COSTS HALF A HEART.", [{ "on": "on_room_enter", "every": 4, "do": [["hurt_self", 1]] }], "g_vampirefang"],
	["echoring", "RING OF ECHOES", "ring", "epic", ["arcane"], null, "ring", [["echo", 0.12]], [], "12% OF SHOTS CAST AGAIN, 30% MORE FOR 3S AFTER ENTERING A ROOM.", [{ "on": "on_room_enter", "do": [["buff", "echo", 0.3, 3.0]] }], "g_quickring"],
	["thornring", "THORNED RING", "ring", "rare", ["bulwark"], null, "ring", [["thorns", 12]], [], "+12 THORNS. WHEN HIT, +20% DAMAGE FOR 3S.", [{ "on": "on_damage_taken", "do": [["buff", "dmg", 0.2, 3.0]] }], "g_whetring"],
	["wispring", "WISP-CALLER RING", "ring", "rare", ["swarm"], null, "ring", [["fam_rate", 1.15]], [], "WISPS FIRE 15% FASTER. 10% OF KILLS RAISE A WISP FOR 5S.", [{ "on": "on_kill", "chance": 0.1, "do": [["summon", 5.0]] }], "g_gild_ring"],
	["ragering", "RING OF RANCOR", "ring", "rare", ["fury"], null, "ring", [], [["low_hp_dmg", 0.25]], "+25% DAMAGE WHILE WOUNDED.", [], "g_ember_ring"],
	["bombring", "FUSE RING", "ring", "rare", ["demolition"], null, "ring", [["bomb_mult", 1.2]], [], "BOMBS DEAL +20%. CLEARING A ROOM GIVES 1 BOMB 30% OF THE TIME.", [{ "on": "on_room_clear", "chance": 0.3, "do": [["drop", "bomb"]] }], "g_thunder_ring"],
	["seersring", "SEER'S RING", "ring", "epic", ["arcane", "edge"], null, "ring", [["crit", 0.08], ["homing", 0.8]], [], "+8% CRIT. SHOTS HOME IN A LITTLE. CRITS MARK FOES.", [{ "on": "on_crit", "do": [["status", "mark", 1]] }], "g_whetring"],
	["doomring", "RING OF DOOM", "ring", "legend", ["malice"], null, "ring", [["curse", 0.15]], [], "15% OF HITS CURSE. CURSED FOES YOU KILL EXPLODE FOR 150%, CURSING THOSE NEARBY.", [{ "on": "on_kill", "if": "cursed", "do": [["explode", 34, 1.5], ["status_area", "curse", 1, 40]] }], "g_vampirefang"],
	["conclave_gloves", "CONCLAVE GLOVES", "hands", "rare", ["arcane"], "conclave", "gloves", [["rate", 1.05]], [], "+5% FIRE RATE. EVERY 20TH ATTACK GIVES +30% FOR 2S.", [{ "on": "every_n_shots", "every": 20, "do": [["buff", "rate", 0.3, 2.0]] }], "g_clothglove"],
	["conclave_sigil", "CONCLAVE SIGIL", "neck", "rare", ["arcane"], "conclave", "amulet", [["count", 1]], [], "+1 PROJECTILE. LEVELLING UP FIRES A RING OF 12 SHOTS.", [{ "on": "on_level_up", "do": [["nova", 12, 1.0, ""]] }], "g_eyeofstorm"],
	["conclave_ring_a", "CONCLAVE RING OF DUSK", "ring", "rare", ["arcane"], "conclave", "ring", [["homing", 0.6]], [], "SHOTS HOME IN A LITTLE, AND HARDER FOR 2S AFTER A KILL.", [{ "on": "on_kill", "do": [["buff", "homing", 1.0, 2.0]] }], "g_quickring"],
	["conclave_ring_b", "CONCLAVE RING OF DAWN", "ring", "rare", ["arcane"], "conclave", "ring", [["pierce", 1]], [], "+1 PIERCE. 10% OF HITS MAKE ELITES VULNERABLE.", [{ "on": "on_hit", "if": "elite", "chance": 0.1, "do": [["status", "vulnerable", 1]] }], "g_gild_ring"],
	["hunt_hood", "HEADHUNTER'S HOOD", "head", "rare", ["edge"], "headhunter", "hood", [["crit", 0.05]], [], "+5% CRIT. ELITE KILLS GIVE +25% CRIT FOR 4S.", [{ "on": "on_kill", "if": "elite", "do": [["buff", "crit", 0.25, 4.0]] }], "g_huntershood"],
	["hunt_coat", "HEADHUNTER'S COAT", "body", "rare", ["edge"], "headhunter", "leather", [["max_hp", 2]], [], "+1 MAX HEART. ELITE KILLS GIVE 1 ARMOR.", [{ "on": "on_kill", "if": "elite", "do": [["armor", 1]] }], "g_hunterscoat"],
	["hunt_gloves", "HEADHUNTER'S GLOVES", "hands", "rare", ["edge"], "headhunter", "gloves", [["crit_mult", 0.2]], [], "CRITS DEAL +0.2X. 10% OF HITS ON ELITES MAKE THEM BLEED.", [{ "on": "on_hit", "if": "elite", "chance": 0.1, "do": [["status", "bleed", 1]] }], "g_leatherglove"],
	["hunt_boots", "HEADHUNTER'S BOOTS", "feet", "rare", ["edge"], "headhunter", "boots", [["speed", 1.06]], [], "+6% MOVE SPEED. ELITE KILLS GIVE YOU A ROLL BACK.", [{ "on": "on_kill", "if": "elite", "do": [["refund_roll"]] }], "g_worntboots"],
	["mirehelm", "MIRE-DIVER'S HELM", "head", "rare", ["venom", "bulwark"], null, "helm", [["armor", 1], ["poison", 1]], [], "GRANTS 1 ARMOR. +1 POISON ON HIT. WHEN HIT, YOU SPILL A POOL OF MIRE.", [{ "on": "on_damage_taken", "do": [["zone", "poison", 30, 2.0]] }], "g_ironmask"],
	["monkrobe", "MONK'S HABIT", "body", "rare", ["shadow", "frost"], null, "robe", [["dodge_charges", 1], ["charges", 1]], [], "+1 ROLL CHARGE. ROLLING PAST A CLOSE SHOT CHILLS FOES NEAR YOU.", [{ "on": "on_roll", "if": "danger", "do": [["status_area", "chill", 1, 60]] }], "g_acolyterobe"],
	["warcloak", "WAR-TORN CLOAK", "body", "common", ["fury"], null, "cloak", [["dmg", 1.06]], [], "+6% DAMAGE. ENTERING A ROOM GIVES +20% DAMAGE FOR 5S.", [{ "on": "on_room_enter", "do": [["buff", "dmg", 0.2, 5.0]] }], "g_travelcloak"],
	["rooftopboots", "ROOFRUNNER BOOTS", "feet", "rare", ["shadow"], null, "boots", [["speed", 1.08], ["roll_speed", 1.1]], [], "+8% MOVE SPEED, FASTER ROLLS. ROLLING GIVES +20% FIRE RATE FOR 1S.", [{ "on": "on_roll", "cd": 0.5, "do": [["buff", "rate", 0.2, 1.0]] }], "g_ninjatabi"],
	["eclipsecrown", "CROWN OF THE ECLIPSE", "head", "legend", ["malice", "arcane"], null, "crown", [["dmg", 1.15]], [], "+15% DAMAGE. EACH FLOOR STARTS WITH A SCROLL (A SMALL PERMANENT BOOST).", [{ "on": "on_floor_start", "do": [["scroll"]] }], "g_kingscrown"],
	["snowtreads", "SNOW TREADS", "feet", "common", ["frost"], null, "boots", [["chill", 0.08]], [], "+8% CHILL CHANCE. ENTERING A ROOM CHILLS FOES NEAR YOU.", [{ "on": "on_room_enter", "do": [["status_area", "chill", 1, 80]] }], "g_frost_boots"],
	# ---------- Content batch 4 (chaos): equipment ----------
	["jester_cap", "JESTER'S CAP", "head", "rare", ["fortune"], "jester", "hat", [["crit", 0.05]], [], "JINGLES. +5% CRIT. 5% OF CRITS DO SOMETHING RANDOM.", [{ "on": "on_crit", "chance": 0.05, "cd": 1.0, "do": [["chaos"]] }]],
	["jester_coat", "JESTER'S MOTLEY", "body", "rare", ["fortune", "arcane"], "jester", "leather", [["max_hp", 2]], [], "+1 MAX HEART. WHEN HIT YOU HONK: EVERY FOE NEAR YOU IS FLUNG AWAY.", [{ "on": "on_damage_taken", "do": [["push", 80, 300]] }]],
	["jester_shoes", "JESTER'S CURLY SHOES", "feet", "rare", ["fortune"], "jester", "boots", [["speed", 1.08]], [], "+8% MOVE SPEED. ROLLING DROPS A COIN (EVERY 5S).", [{ "on": "on_roll", "cd": 5.0, "do": [["drop", "coin"]] }]],
	["jester_bauble", "JESTER'S BAUBLE", "trinket", "epic", ["fortune"], "jester", "charm", [["gold_mult", 1.15]], [], "+15% GOLD. 20% OF CRITS PAY 1 GOLD.", [{ "on": "on_crit", "chance": 0.2, "do": [["gold", 1]] }]],
	["star_helm", "STARFALL CROWN", "head", "rare", ["pyre"], "starfall", "crown", [["burn", 0.1]], [], "+10% BURN CHANCE. LEVELLING UP CALLS DOWN A METEOR.", [{ "on": "on_level_up", "do": [["meteor", 2.0, 30]] }]],
	["star_plate", "STARFALL PLATE", "body", "epic", ["pyre", "demolition"], "starfall", "plate", [["armor", 1]], [], "+1 ARMOR. WHEN HIT, A METEOR FALLS ON A FOE FOR 200%.", [{ "on": "on_damage_taken", "do": [["meteor", 2.0, 30]] }]],
	["star_gloves", "STARFALL GAUNTLETS", "hands", "rare", ["pyre"], "starfall", "gloves", [["bomb_mult", 1.2]], [], "BOMBS DEAL +20%. 6% OF KILLS LEAVE A LIT BOMB (HARMLESS TO YOU).", [{ "on": "on_kill", "chance": 0.06, "do": [["bomb", 0.5]] }]],
	["star_boots", "STARFALL GREAVES", "feet", "rare", ["pyre"], "starfall", "greaves", [["speed", 1.06]], [["fire_steps", 1]], "+6% MOVE SPEED, BURNING FOOTPRINTS. ROLLS LAND WITH A SPRAY OF 6 EMBERS.", [{ "on": "on_roll", "cd": 1.0, "do": [["nova", 6, 0.4, "fire"]] }]],
	["void_cowl", "VOIDWALKER COWL", "head", "rare", ["shadow", "malice"], "voidwalker", "hood", [["evade", 0.05]], [], "5% CHANCE TO DODGE A HIT. ROLLS KEEP YOU UNTOUCHABLE 0.3S LONGER.", [{ "on": "on_roll", "cd": 2.0, "do": [["invuln", 0.3]] }]],
	["void_wraps", "VOIDWALKER WRAPS", "hands", "rare", ["shadow"], "voidwalker", "gloves", [["dodge_cd", 0.9]], [], "ROLLS RECHARGE 10% FASTER AND WEAKEN FOES NEAR YOU.", [{ "on": "on_roll", "cd": 1.0, "do": [["status_area", "weakened", 1, 50]] }]],
	["void_amulet", "VOIDWALKER LOCKET", "neck", "epic", ["shadow", "arcane"], "voidwalker", "amulet", [["dodge_charges", 1], ["charges", 1]], [], "+1 ROLL CHARGE. ROLLING AT LOW HEALTH HEALS HALF A HEART (EVERY 10S).", [{ "on": "on_roll", "if": "low_hp", "cd": 10.0, "do": [["heal", 1]] }]],
	["void_ring", "VOIDWALKER BAND", "ring", "rare", ["malice"], "voidwalker", "ring", [["curse", 0.08]], [], "8% OF HITS CURSE. 10% OF HITS ON CURSED FOES WEAKEN THEM.", [{ "on": "on_hit", "if": "cursed", "chance": 0.1, "do": [["status", "weakened", 1]] }]],
	["magnethelm", "MAGNET HELM", "head", "rare", ["storm", "bulwark"], null, "helm", [["armor", 1]], [], "+1 ARMOR. EVERY 3S IN A FIGHT, FOES NEAR YOU ARE DRAGGED IN AND SHOCKED.", [{ "on": "every_n_seconds", "period": 3.0, "if": "fighting", "do": [["pull", 100, 200], ["status_area", "shock", 1, 100]] }]],
	["partyhat", "PARTY HAT", "head", "common", ["fortune"], null, "hat", [["xp_mult", 1.1]], [], "+10% EXPERIENCE. EVERY LEVEL-UP THROWS A PARTY: 20 SPARKS AND 10 GOLD.", [{ "on": "on_level_up", "do": [["nova", 20, 0.8, "spark"], ["gold", 10], ["vfx", "label", "PARTY!", "#e86fb4"]] }]],
	["thirdeye", "THIRD EYE", "head", "epic", ["arcane", "edge"], null, "mask", [["crit", 0.08], ["homing", 1.2]], [], "+8% CRIT. SHOTS HOME IN. CRITS INFLICT A RANDOM AILMENT.", [{ "on": "on_crit", "cd": 0.1, "do": [["rand_status", 1]] }]],
	["bombvest", "POWDERKEG VEST", "body", "rare", ["demolition"], null, "plate", [["armor", 1], ["bombs", 2]], [["bomb_immune", 1]], "+1 ARMOR, +2 BOMBS. YOUR BOMBS CANNOT HURT YOU. WHEN HIT, YOU DROP A LIT ONE.", [{ "on": "on_damage_taken", "do": [["bomb", 0.6]] }]],
	["giantbelt", "GIANT'S GIRDLE", "body", "epic", ["fury"], null, "leather", [["max_hp", 2], ["size", 1.25]], [], "+1 MAX HEART. SHOTS ARE 25% BIGGER, AND EVERY KILL SWELLS THEM 10% MORE FOR 3S.", [{ "on": "on_kill", "do": [["buff", "size", 0.1, 3.0]] }]],
	["ghostsheet", "BEDSHEET GHOST", "body", "rare", ["shadow"], null, "cloak", [["evade", 0.05]], [], "5% DODGE. WHEN HIT YOU SHOUT BOO: SHOTS NEAR YOU VANISH AND NOTHING CAN HURT YOU FOR 1.5S.", [{ "on": "on_damage_taken", "do": [["clear_shots", 60], ["invuln", 1.5], ["vfx", "label", "BOO!", "#f4ecd8"]] }]],
	["hedgehogmail", "HEDGEHOG MAIL", "body", "epic", ["bulwark"], null, "plate", [["armor", 1], ["thorns", 20]], [], "+1 ARMOR, +20 THORNS. EVERY 2S IN A FIGHT, 8 QUILLS FLY OUT AROUND YOU.", [{ "on": "every_n_seconds", "period": 2.0, "if": "fighting", "do": [["nova", 8, 0.5, "spark"]] }]],
	["rocketboots", "ROCKET BOOTS", "feet", "epic", ["demolition", "pyre"], null, "greaves", [["roll_speed", 1.3]], [], "ROLLS GO 30% FURTHER AND LAUNCH WITH A BLAST FOR 100%, LEAVING FIRE BEHIND.", [{ "on": "on_roll", "cd": 0.5, "do": [["explode", 28, 1.0], ["zone", "fire", 14, 2.5]] }]],
	["slipperysoles", "BUTTERED SOLES", "feet", "rare", ["frost"], null, "boots", [["speed", 1.12]], [], "+12% MOVE SPEED. ROLLING MAKES FOES NEAR YOU SLIP: STUNNED FOR 1S (EVERY 2S).", [{ "on": "on_roll", "cd": 2.0, "do": [["status_area", "stun", 1, 50]] }]],
	["springheels", "SPRING HEELS", "feet", "common", ["shadow"], null, "boots", [["dodge_cd", 0.9]], [], "ROLLS RECHARGE 10% FASTER. ROLLING GIVES +30% MOVE SPEED FOR 2S.", [{ "on": "on_roll", "do": [["buff", "speed", 0.3, 2.0]] }]],
	["goldengoose", "GOLDEN GOOSE", "trinket", "legend", ["fortune"], null, "charm", [["luck", 1]], [["gold_dmg", 0.08]], "+1 LUCK. +8% DAMAGE PER 100 GOLD. EVERY 4S IN A FIGHT THE GOOSE LAYS A COIN.", [{ "on": "every_n_seconds", "period": 4.0, "if": "fighting", "do": [["drop", "coin"]] }]],
	["chaosdie", "CHAOS DIE", "trinket", "epic", ["arcane", "fortune"], null, "charm", [["luck", 1]], [], "+1 LUCK. ENTERING A ROOM ROLLS THE DIE. SO DOES EVERY 15TH KILL. ANYTHING CAN HAPPEN.", [{ "on": "on_room_enter", "do": [["chaos"]] }, { "on": "on_kill", "every": 15, "do": [["chaos"]] }]],
	["pocketsun", "POCKET SUN", "trinket", "epic", ["pyre"], null, "amulet", [["burn", 0.15]], [["fire_aura", 1]], "FOES NEAR YOU CATCH FIRE. EVERY 5S IN A FIGHT IT FLARES, IGNITING EVERYTHING AROUND YOU.", [{ "on": "every_n_seconds", "period": 5.0, "if": "fighting", "do": [["status_area", "burn", 2, 100], ["vfx", "ring", "#f2c94c", 100]] }]],
	["stormcloud", "PET STORMCLOUD", "trinket", "rare", ["storm"], null, "charm", [["chain", 0.1]], [], "+10% ARC CHANCE. EVERY 2.5S IN A FIGHT IT ZAPS A RANDOM FOE.", [{ "on": "every_n_seconds", "period": 2.5, "if": "fighting", "do": [["bolts", 1, 0.8]] }]],
	["boxinggloves", "BOXING GLOVES", "hands", "rare", ["fury"], null, "gloves", [["dmg", 1.08]], [], "+8% DAMAGE. EVERY 5TH ATTACK IS A KNOCKOUT: FOES NEAR YOU TAKE 100% AND GO FLYING.", [{ "on": "every_n_shots", "every": 5, "do": [["area", 50, 1.0], ["push", 60, 320]] }]],
	["fireworkmitts", "FIREWORK MITTS", "hands", "epic", ["pyre", "arcane"], null, "gloves", [["crit", 0.06]], [], "+6% CRIT. CRITS FIRE 6 SPARKS AROUND YOU.", [{ "on": "on_crit", "cd": 0.2, "do": [["nova", 6, 0.4, "spark"]] }]],
	["puppetstrings", "PUPPETEER'S STRINGS", "hands", "epic", ["swarm"], null, "gloves", [["familiars", 1]], [], "+1 WISP. 5% OF HITS RAISE ANOTHER FOR 5S.", [{ "on": "on_hit", "chance": 0.05, "cd": 0.2, "do": [["summon", 5.0]] }]],
	["monkeypaw", "MONKEY'S PAW", "hands", "legend", ["malice", "fortune"], null, "gloves", [["luck", 2]], [], "+40% DAMAGE, +2 LUCK. EVERY ROOM GRANTS A RANDOM WISH. ONE IN FOUR COSTS HALF A HEART.", [["pct", "dmg", 0.4], { "on": "on_room_enter", "do": [["chaos"]] }, { "on": "on_room_enter", "chance": 0.25, "do": [["hurt_self", 1]] }]],
	["cowbell", "LOUD COWBELL", "neck", "common", ["fury"], null, "amulet", [["max_hp", 2]], [], "+1 MAX HEART. WHEN HIT, THE CLANG STUNS EVERY FOE NEAR YOU FOR 1S.", [{ "on": "on_damage_taken", "do": [["status_area", "stun", 1, 80], ["vfx", "ring", "#f2c94c", 80]] }]],
	["collapsedstar", "COLLAPSED STAR", "neck", "legend", ["arcane", "shadow"], null, "amulet", [["dmg", 1.1]], [], "+10% DAMAGE. EVERY 5S IN A FIGHT, EVERYTHING NEAR YOU IS DRAGGED IN AND CRUSHED FOR 200%.", [{ "on": "every_n_seconds", "period": 5.0, "if": "fighting", "do": [["pull", 140, 280], ["area", 140, 2.0], ["vfx", "sigil", "#a35bd6", 70]] }]],
	["ricochetring", "RING OF REBOUNDS", "ring", "epic", ["arcane"], null, "ring", [["ricochet", 1], ["bounce", 1]], [], "SHOTS JUMP TO ANOTHER FOE AND OFF A WALL. 5% OF HITS SPLIT OFF A SHOT.", [{ "on": "on_hit", "chance": 0.05, "cd": 0.2, "do": [["shoot", 1, 0.5, "", 0.3]] }]],
	["bigring", "RING OF BIGNESS", "ring", "rare", ["fury"], null, "ring", [["size", 1.35]], [], "EVERYTHING YOU SHOOT IS 35% BIGGER. 10% OF KILLS BURST BIG.", [{ "on": "on_kill", "chance": 0.1, "do": [["explode", 30, 0.6]] }]],
	["tinyring", "RING OF SMALLNESS", "ring", "rare", ["shadow"], null, "ring", [["size", 0.8], ["rate", 1.2]], [], "SHOTS 20% SMALLER, FIRE 20% FASTER. ROLLING ERASES SHOTS NEAR YOU (3S).", [{ "on": "on_roll", "cd": 3.0, "do": [["clear_shots", 30]] }]],
	["twinring", "TWIN-SOUL RING", "ring", "legend", ["arcane"], null, "ring", [["count", 1], ["echo", 0.1]], [], "+1 PROJECTILE. 10% ECHO. EVERY 5TH ATTACK ALSO FIRES 3 SHOTS BEHIND YOU.", [{ "on": "every_n_shots", "every": 5, "do": [["shoot_at", 3, 0.8, "", 0.2, 3.14159]] }]],
	["toadring", "TOAD RING", "ring", "rare", ["venom"], null, "ring", [["poison", 1]], [], "+1 POISON ON HIT. POISONED FOES YOU KILL LEAVE A POISON POOL.", [{ "on": "on_kill", "if": "poisoned", "do": [["zone", "poison", 20, 3.0]] }]],
]

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
		# --classic: original items only (proves the originals play exactly as before).
		for i in (ORIGINAL_COUNT if DebugArgs.has("classic") else ROWS.size()):
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
			Effects.apply_equipment(p, s.get("e2", []), 1, "se2:" + set_id)
		else:
			Weapons.apply_tuples(p, s.get("b4", []), 1, "s4:" + set_id)
			Weapons.apply_hooks(p, s.get("b4h", []), 1)
			Effects.apply_equipment(p, s.get("e4", []), 1, "se4:" + set_id)
		G.toast(s["name"] + " SET: " + (s["d2"] if have == 1 else s["d4"]), "gold")
	while have > tier:
		if have == 1:
			Weapons.apply_tuples(p, s["b2"], -1, "s2:" + set_id)
			Effects.apply_equipment(p, s.get("e2", []), -1, "se2:" + set_id)
		else:
			Weapons.apply_tuples(p, s.get("b4", []), -1, "s4:" + set_id)
			Weapons.apply_hooks(p, s.get("b4h", []), -1)
			Effects.apply_equipment(p, s.get("e4", []), -1, "se4:" + set_id)
		have -= 1
	p.set_tier[set_id] = have

## Equips a piece of gear and returns the piece it replaced (or null).
static func equip_gear(p: Player, g: Dictionary) -> Variant:
	var slot := slot_for(p, g)
	var old = p.gear.get(slot)
	if old != null:
		Weapons.apply_tuples(p, old["stats"], -1, "g:" + old["id"])
		Weapons.apply_hooks(p, old["hooks"], -1)
		if not old["effects"].is_empty():
			Effects.apply_equipment(p, old["effects"], -1, "gfx:" + old["id"])
		p.gear[slot] = null
		update_sets(p, old["set"], -1)
	p.gear[slot] = g
	Weapons.apply_tuples(p, g["stats"], 1, "g:" + g["id"])
	Weapons.apply_hooks(p, g["hooks"], 1)
	if not g["effects"].is_empty():
		Effects.apply_equipment(p, g["effects"], 1, "gfx:" + g["id"])
	update_sets(p, g["set"], 1)
	Meta.meta["found_g"][g["id"]] = true
	if g["new"] or (old != null and old["new"]):
		Effects.recount_tags(p)
	return old
