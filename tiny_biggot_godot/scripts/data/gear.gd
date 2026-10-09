class_name Gear
extends RefCounted
## Equipment (01c_items.rb GEAR / SETS / STAT_TEXT and the equip and set logic
## of 04b_items.rb, extended by the content batches). Rows are
## [id, name, slot, rarity, tags, set, shape, stats, hooks, desc, effects].
## The first ORIGINAL_COUNT rows are original; new rows may add effects.

const SLOTS := ["head", "body", "feet", "trinket"]
## Design spec section 6 (step 8): gloves, an amulet and two ring slots join the
## original four. Items say "ring"; a ring fills ring1 or ring2 (slot_for).
const NEW_SLOTS := ["hands", "neck", "ring1", "ring2", "offhand"]   # 37.1: the offhand
const ITEM_SLOTS := ["head", "body", "feet", "trinket", "hands", "neck", "ring", "offhand"]
const SLOT_NAME := { "head": "HELM", "body": "ARMOR", "feet": "BOOTS", "trinket": "TRINKET",
	"hands": "GLOVES", "neck": "AMULET", "ring": "RING", "ring1": "RING", "ring2": "RING", "offhand": "OFFHAND" }

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
	# ROADMAP 4.7 sets.
	"rimewarden": { "name": "RIMEWARDEN", "tag": "frost", "b2": [["chill", 0.15]], "e4": [{ "on": "every_n_seconds", "period": 3.0, "if": "fighting", "do": [["slow_shots", 80, 0.35]] }], "d2": "+15% CHILL CHANCE", "d4": "EVERY 3S IN A FIGHT, SHOTS NEAR YOU SLOW TO A CRAWL" },
	"blastwright": { "name": "BLASTWRIGHT", "tag": "demolition", "b2": [["bombs", 2], ["bomb_r", 1.25]], "e4": [{ "on": "on_bomb", "do": [["pull", 110, 260]] }], "d2": "+2 BOMBS, BOMBS 25% WIDER", "d4": "A BOMB YOU SET DRAGS FOES IN AROUND IT" },
	"bonecaller": { "name": "BONECALLER", "tag": "malice", "b2": [["familiars", 1]], "e4": [{ "on": "on_kill", "do": [["raise", 8.0, 0.8]] }], "d2": "+1 WISP", "d4": "EVERY FOE YOU KILL RISES AS YOUR SKELETON FOR 8S" },
	"clockwork": { "name": "CLOCKWORK", "tag": "swarm", "b2": [["rate", 1.12]], "e4": [{ "on": "every_n_seconds", "period": 8.0, "if": "fighting", "do": [["turret", "random", 8.0, 1.0]] }], "d2": "+12% FIRE RATE", "d4": "EVERY 8S IN A FIGHT, A RANDOM TURRET SPRINGS UP FOR 8S" },
	# 14.1 (his ask, 7 Oct): sets for styles that had few, and LEGENDARY sets of six pieces
	# ("size": 6: steps at 2, 4 and 6 pieces; the sixth brings "e6"/"d6" and SET MASTERY).
	"stormcaller": { "name": "STORMCALLER", "tag": "storm", "b2": [["chain", 0.15]], "e4": [{ "on": "every_n_shots", "every": 7, "do": [["bolts", 3, 1.0]] }], "d2": "+15% ARC CHANCE", "d4": "EVERY 7TH ATTACK CALLS 3 LIGHTNING STRIKES" },
	"bloodletter": { "name": "BLOODLETTER", "tag": "blood", "b2": [["crit", 0.08]], "e4": [{ "on": "on_crit", "chance": 0.5, "do": [["status", "bleed", 2]] }, { "on": "on_kill", "if": "bleeding", "cd": 3.0, "do": [["heal", 1]] }], "d2": "+8% CRIT CHANCE", "d4": "CRITS OFTEN BLEED. BLEEDING KILLS HEAL (EVERY 3S)" },
	"hexweaver": { "name": "HEXWEAVER", "tag": "malice", "b2": [], "e2": [{ "on": "on_hit", "chance": 0.15, "do": [["status", "curse", 1]] }], "e4": [{ "on": "on_kill", "if": "cursed", "do": [["explode", 40, 1.2]] }], "d2": "15% OF HITS CURSE", "d4": "CURSED FOES EXPLODE WHEN THEY DIE" },
	"viper": { "name": "VIPER", "tag": "venom", "b2": [["poison", 1]], "e4": [{ "on": "on_kill", "if": "poisoned", "do": [["zone", "poison", 30, 3.0]] }], "d2": "+1 POISON ON HIT", "d4": "POISONED FOES LEAVE A POOL OF POISON" },
	"warlord": { "name": "WARLORD", "tag": "fury", "b2": [["dmg", 1.1]], "e4": [{ "on": "on_damage_taken", "do": [["buff", "dmg", 0.5, 4.0], ["buff", "rate", 0.25, 4.0], ["vfx", "label", "WAR CRY!", "#d8443c"]] }], "d2": "+10% DAMAGE", "d4": "WHEN HIT: +50% DAMAGE, +25% FIRE RATE FOR 4S" },
	"beastmaster": { "name": "BEASTMASTER", "tag": "swarm", "b2": [["familiars", 1], ["fam_dmg", 0.2]], "e4": [{ "on": "on_room_enter", "do": [["summon", 12.0], ["summon", 12.0], ["summon", 12.0]] }], "d2": "+1 WISP, WISPS +20%", "d4": "EVERY ROOM BEGINS WITH 3 MORE WISPS FOR 12S" },
	"drifter": { "name": "DRIFTER", "tag": "shadow", "b2": [["dodge_cd", 0.85]], "e4": [{ "on": "on_roll", "do": [["nova", 6, 0.8, "spark"]] }, { "on": "on_kill", "chance": 0.25, "do": [["refund_roll"]] }], "d2": "ROLLS RECHARGE 15% FASTER", "d4": "ROLLING FIRES 6 KNIVES. 25% OF KILLS REFUND A ROLL" },
	"sunforged": { "name": "SUNFORGED", "tag": "pyre", "size": 6, "b2": [["burn", 0.2]], "e4": [{ "on": "every_n_seconds", "period": 5.0, "if": "fighting", "do": [["meteor", 2.0, 30]] }], "e6": [{ "on": "on_kill", "chance": 0.2, "do": [["meteor", 2.0, 30]] }, ["add", "vs_burn", 0.5]], "d2": "+20% BURN CHANCE", "d4": "EVERY 5S IN A FIGHT A METEOR FALLS", "d6": "KILLS MAY CALL METEORS. BURNING FOES TAKE +50%" },
	# 20.3 Chapter IV: a set of the stacks, and the Critic's own (legendary, six).
	"bookworm": { "name": "BOOKWORM", "tag": "arcane", "b2": [["pierce", 1]], "e4": [{ "on": "every_n_shots", "every": 8, "do": [["nova", 10, 0.8, "page"]] }],
		"d2": "+1 PIERCE", "d4": "EVERY 8TH ATTACK SCATTERS 10 PAGES" },
	"criticregalia": { "name": "CRITIC'S REGALIA", "tag": "malice", "size": 6, "b2": [["curse", 0.1]], "e4": [{ "on": "on_kill", "if": "cursed", "do": [["explode", 40, 1.0]] }],
		"e6": [{ "on": "every_n_seconds", "period": 4.0, "if": "fighting", "do": [["execute_weakest", 4.0, 0.0]] }, ["mul", "dmg", 1.25]],
		"d2": "10% OF HITS CURSE", "d4": "CURSED FOES BURST WHEN THEY DIE", "d6": "EVERY 4S IN A FIGHT THE WEAKEST FOE IS STRUCK FOR 400%. +25% DAMAGE" },
	"voidregalia": { "name": "VOID REGALIA", "tag": "shadow", "size": 6, "b2": [["count", 1]], "e4": [{ "on": "on_roll", "do": [["nova", 8, 1.0, "spark"]] }], "e6": [{ "on": "every_n_seconds", "period": 3.0, "if": "fighting", "do": [["clear_shots", 60], ["nova", 12, 1.0, "spark"]] }, ["mul", "dmg", 1.3]], "d2": "+1 PROJECTILE", "d4": "ROLLING FIRES A RING OF 8", "d6": "EVERY 3S: ERASE NEARBY SHOTS, FIRE 12. +30% DAMAGE" },
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
	# ---------- ROADMAP 4.7: forty pieces, four sets (aimed at the thin slots: hands, neck, ring) ----------
	["rime_hood", "RIMEWARDEN HOOD", "head", "rare", ["frost"], "rimewarden", "hood", [["chill", 0.08]], [], "+8% CHILL CHANCE. A QUARTER OF YOUR HITS ON FAR FOES CHILL THEM.", [{ "on": "on_hit", "if": "far", "chance": 0.25, "do": [["status", "chill", 1]] }]],
	["rime_mantle", "RIMEWARDEN MANTLE", "body", "rare", ["frost", "bulwark"], "rimewarden", "cloak", [["armor", 1]], [], "+1 ARMOR. WHEN ARMOR TAKES A HIT, EVERY FOE NEAR YOU FREEZES SOLID FOR 1S.", [{ "on": "on_armor_lost", "do": [["status_area", "chill", 2, 90], ["status_area", "stun", 1, 90], ["vfx", "ring", "#c8f0ff", 90]] }]],
	["rime_grip", "RIMEWARDEN GRIP", "hands", "rare", ["frost"], "rimewarden", "gloves", [["crit", 0.05]], [], "+5% CRIT. A CHILLED FOE YOU KILL PASSES ALL ITS AILMENTS TO THE FOES NEAR IT.", [{ "on": "on_kill", "if": "chilled", "do": [["spread", 70]] }]],
	["rime_bell", "RIMEWARDEN BELL", "neck", "epic", ["frost"], "rimewarden", "amulet", [["dmg", 1.08]], [], "+8% DAMAGE. EVERY 10S IN A FIGHT, A FROST TOTEM RISES BESIDE YOU FOR 8S.", [{ "on": "every_n_seconds", "period": 10.0, "if": "fighting", "do": [["turret", "frost", 8.0, 1.0]] }]],
	["blast_goggles", "BLASTWRIGHT GOGGLES", "head", "rare", ["demolition"], "blastwright", "mask", [["bomb_mult", 1.2]], [], "BOMBS DEAL +20%. SETTING A BOMB MAKES YOU UNTOUCHABLE FOR 0.6S.", [{ "on": "on_bomb", "do": [["invuln", 0.6]] }]],
	["blast_apron", "BLASTWRIGHT APRON", "body", "rare", ["demolition", "bulwark"], "blastwright", "leather", [["max_hp", 2]], [], "+1 MAX HEART. 8% OF KILLS HAND YOU A BOMB.", [{ "on": "on_kill", "chance": 0.08, "do": [["give", "bombs", 1]] }]],
	["blast_mitts", "BLASTWRIGHT MITTS", "hands", "epic", ["demolition", "pyre"], "blastwright", "gloves", [["bombs", 1]], [], "+1 BOMB. EVERY BOMB YOU SET LEAVES A FLAME TURRET BEHIND FOR 6S.", [{ "on": "on_bomb", "do": [["turret", "flame", 6.0, 0.8]] }]],
	["blast_ring", "BLASTWRIGHT BAND", "ring", "rare", ["demolition"], "blastwright", "ring", [["bomb_r", 1.1]], [], "BOMBS 10% WIDER. CLEARING A ROOM HANDS YOU A BOMB.", [{ "on": "on_room_clear", "do": [["give", "bombs", 1]] }]],
	["bone_crown", "BONECALLER CROWN", "head", "epic", ["malice", "swarm"], "bonecaller", "crown", [["fam_dmg", 0.25]], [], "WISPS DEAL +25%. AN ELITE YOU KILL RISES AS YOUR SKELETON FOR 15S, HITTING TWICE AS HARD.", [{ "on": "on_kill", "if": "elite", "do": [["raise", 15.0, 1.6]] }]],
	["bone_ribs", "BONECALLER RIBCAGE", "body", "rare", ["malice"], "bonecaller", "plate", [["max_hp", 2]], [], "+1 MAX HEART. WHEN HIT, A SKELETON CLAWS ITS WAY OUT BESIDE YOU AND FIGHTS FOR 8S.", [{ "on": "on_damage_taken", "do": [["raise", 8.0, 0.8]] }]],
	["bone_rattle", "BONECALLER RATTLE", "neck", "rare", ["malice", "swarm"], "bonecaller", "amulet", [["familiars", 1]], [], "+1 WISP. LEVELLING UP RAISES TWO SKELETONS THAT FIGHT FOR 20S.", [{ "on": "on_level_up", "do": [["raise", 20.0, 1.0], ["raise", 20.0, 1.0]] }]],
	["bone_ring", "BONECALLER SIGNET", "ring", "rare", ["malice"], "bonecaller", "ring", [["curse", 0.08]], [], "8% OF HITS CURSE. 10% OF HITS ON CURSED FOES USE UP ALL THEIR AILMENTS FOR 60% EACH.", [{ "on": "on_hit", "if": "cursed", "chance": 0.1, "do": [["consume", 0.6]] }]],
	["clock_monocle", "CLOCKWORK MONOCLE", "head", "rare", ["swarm", "edge"], "clockwork", "mask", [["crit", 0.06]], [], "+6% CRIT. YOUR FIRST HIT ON EACH FOE STRIKES AGAIN FOR 80%.", [{ "on": "on_hit", "if": "fresh", "do": [["damage", 0.8]] }]],
	["clock_coat", "CLOCKWORK COAT", "body", "rare", ["swarm", "storm"], "clockwork", "plate", [["armor", 1]], [], "+1 ARMOR. WHEN ARMOR TAKES A HIT, A TESLA COIL SPRINGS UP BESIDE YOU FOR 8S.", [{ "on": "on_armor_lost", "do": [["turret", "tesla", 8.0, 1.0]] }]],
	["clock_boots", "CLOCKWORK BOOTS", "feet", "rare", ["swarm"], "clockwork", "boots", [["speed", 1.06]], [], "+6% MOVE SPEED. ROLLING DROPS A SAW TRAP FOR 6S (EVERY 4S).", [{ "on": "on_roll", "cd": 4.0, "do": [["turret", "saw", 6.0, 1.0]] }]],
	["clock_key", "CLOCKWORK KEY", "trinket", "epic", ["swarm"], "clockwork", "charm", [["rate", 1.08]], [], "+8% FIRE RATE. EVERY 15S IN A FIGHT, A MENDING TOTEM RISES FOR 14S: STAND BY IT TO HEAL.", [{ "on": "every_n_seconds", "period": 15.0, "if": "fighting", "do": [["turret", "mend", 14.0, 0.8]] }]],
	["lastriteshood", "HOOD OF LAST RITES", "head", "epic", ["edge", "blood"], null, "hood", [["crit_mult", 0.2]], [], "CRITS DEAL +0.2X. EVERY HIT ON THE LAST FOE IN A ROOM STRIKES AGAIN FOR 100%.", [{ "on": "on_hit", "if": "last_foe", "do": [["damage", 1.0]] }]],
	["polishedcuirass", "POLISHED CUIRASS", "body", "epic", ["bulwark", "arcane"], null, "plate", [["armor", 1]], [], "+1 ARMOR. WHEN ARMOR TAKES A HIT, THE SHOTS NEAR YOU FLY BACK THE WAY THEY CAME, AS YOURS.", [{ "on": "on_armor_lost", "do": [["reflect", 90, 1.0]] }]],
	["ghoststeps", "GHOST STEPS", "feet", "rare", ["shadow"], null, "boots", [["evade", 0.06]], [], "6% DODGE CHANCE. DODGING A HIT GIVES +50% DAMAGE FOR 3S.", [{ "on": "on_dodge", "do": [["buff", "dmg", 0.5, 3.0]] }]],
	["abbotsandals", "ABBOT'S SANDALS", "feet", "rare", ["bulwark"], null, "boots", [["speed", 1.05]], [], "+5% MOVE SPEED. HEALING WHILE AT FULL HEALTH GIVES 1 ARMOR INSTEAD.", [{ "on": "on_overheal", "do": [["armor", 1]] }]],
	["iceskates", "ICE SKATES", "feet", "rare", ["frost", "shadow"], null, "boots", [["speed", 1.1]], [], "+10% MOVE SPEED. ROLLING IN A CROWD (6+ FOES) FREEZES THE FOES NEAR YOU (EVERY 3S).", [{ "on": "on_roll", "if": "crowd", "cd": 3.0, "do": [["status_area", "chill", 2, 70], ["status_area", "stun", 1, 70]] }]],
	["magpieboots", "MAGPIE BOOTS", "feet", "common", ["fortune"], null, "boots", [["speed", 1.05]], [], "+5% MOVE SPEED. PICKING UP A COIN GIVES +25% FIRE RATE FOR 2S.", [{ "on": "on_pickup", "if": "coin", "cd": 1.5, "do": [["buff", "rate", 0.25, 2.0]] }]],
	["unscathedmedal", "UNSCATHED MEDAL", "trinket", "rare", ["edge"], null, "amulet", [["crit", 0.05]], [], "+5% CRIT. CLEARING A ROOM WITHOUT A SCRATCH PAYS 8 GOLD AND GIVES +25% DAMAGE FOR 10S.", [{ "on": "on_room_clear", "if": "unhurt", "do": [["gold", 8], ["buff", "dmg", 0.25, 10.0], ["vfx", "label", "UNSCATHED!", "#f2c94c"]] }]],
	["bribepurse", "BRIBE PURSE", "trinket", "epic", ["fortune", "bulwark"], null, "charm", [["gold_mult", 1.1]], [["gold_guard", 15]], "+10% GOLD. WHILE YOU HAVE 15 GOLD, A HIT THAT WOULD COST HEALTH COSTS 15 GOLD INSTEAD.", []],
	["treasuremap", "TREASURE MAP", "trinket", "rare", ["fortune"], null, "charm", [["luck", 1]], [], "+1 LUCK. A THIRD OF THE CHESTS YOU OPEN HOLD A SPARE KEY.", [{ "on": "on_chest", "chance": 0.33, "do": [["give", "keys", 1]] }]],
	["voodoodoll", "VOODOO DOLL", "trinket", "epic", ["malice"], null, "charm", [["curse", 0.05]], [], "5% OF HITS CURSE. WHEN YOU ARE HIT, THE FOE NEAREST YOU TAKES 300% AND IS CURSED.", [{ "on": "on_damage_taken", "do": [["damage", 3.0], ["status", "curse", 1]] }]],
	["leechgloves", "LEECH GLOVES", "hands", "rare", ["blood"], null, "gloves", [["dmg", 1.05]], [], "+5% DAMAGE. 8% OF THE FOES YOU KILL UP CLOSE HEAL HALF A HEART.", [{ "on": "on_kill", "if": "close", "chance": 0.08, "do": [["heal", 1]] }]],
	["catalystgloves", "CATALYST GLOVES", "hands", "epic", ["venom", "pyre"], null, "gloves", [["burn", 0.1]], [], "+10% BURN CHANCE. A CRIT USES UP EVERY AILMENT ON THE FOE, FOR 60% EACH (EVERY 0.5S).", [{ "on": "on_crit", "cd": 0.5, "do": [["consume", 0.6]] }]],
	["plaguehand", "PLAGUE HAND", "hands", "rare", ["venom"], null, "gloves", [["poison", 1]], [], "+1 POISON ON HIT. 10% OF HITS ON POISONED FOES SPREAD ALL THEIR AILMENTS TO THE FOES NEAR THEM.", [{ "on": "on_hit", "if": "poisoned", "chance": 0.1, "do": [["spread", 50]] }]],
	["pickpocketgloves", "PICKPOCKET GLOVES", "hands", "common", ["fortune", "shadow"], null, "gloves", [["rate", 1.05]], [], "+5% FIRE RATE. A QUARTER OF YOUR FIRST HITS ON A FOE PICK 1 GOLD.", [{ "on": "on_hit", "if": "fresh", "chance": 0.25, "do": [["gold", 1]] }]],
	["bouncerknuckles", "BOUNCER'S KNUCKLES", "hands", "rare", ["fury", "bulwark"], null, "gloves", [["dmg", 1.06]], [], "+6% DAMAGE. 15% OF HITS UP CLOSE STUN THE FOE AND SHOVE EVERY FOE NEAR YOU AWAY.", [{ "on": "on_hit", "if": "close", "chance": 0.15, "do": [["status", "stun", 1], ["push", 40, 260]] }]],
	["saintsmedallion", "SAINT'S MEDALLION", "neck", "epic", ["bulwark", "arcane"], null, "amulet", [["max_hp", 2]], [], "+1 MAX HEART. HEALING WHILE AT FULL HEALTH SENDS OUT A RING OF 12 STARS.", [{ "on": "on_overheal", "do": [["nova", 12, 1.0, "spark"]] }]],
	["mirrorpendant", "MIRROR PENDANT", "neck", "rare", ["arcane", "shadow"], null, "amulet", [["evade", 0.04]], [], "4% DODGE CHANCE. DODGING A HIT SENDS THE SHOTS NEAR YOU BACK THE WAY THEY CAME, AS YOURS.", [{ "on": "on_dodge", "do": [["reflect", 80, 1.2]] }]],
	["howlertooth", "HOWLER'S TOOTH", "neck", "rare", ["fury"], null, "amulet", [["dmg", 1.05]], [], "+5% DAMAGE. IN A CROWD (6+ FOES), EVERY 8S YOUR WAR CRY GIVES +30% DAMAGE FOR 4S.", [{ "on": "every_n_seconds", "period": 8.0, "if": "crowd", "do": [["buff", "dmg", 0.3, 4.0], ["vfx", "label", "WAR CRY!", "#e8573a"]] }]],
	["houndcollar", "BLOODHOUND COLLAR", "neck", "epic", ["blood"], null, "amulet", [["crit", 0.05]], [], "+5% CRIT. HITTING A BLEEDING FOE HEALS HALF A HEART (ONCE EVERY 8S).", [{ "on": "on_hit", "if": "bleeding", "cd": 8.0, "do": [["heal", 1]] }]],
	["merchantscharm", "MERCHANT'S CHARM", "neck", "common", ["fortune"], null, "amulet", [["shop_disc", 0.1]], [], "SHOP PRICES -10%. EVERY PURCHASE COMES WITH A FREE BOMB.", [{ "on": "on_buy", "do": [["give", "bombs", 1]] }]],
	["excessring", "RING OF EXCESS", "ring", "epic", ["fury"], null, "ring", [["dmg", 1.05]], [], "+5% DAMAGE. DAMAGE PAST A KILL CARRIES ON TO THE NEAREST FOE.", [{ "on": "on_kill", "do": [["overkill", 1.0]] }]],
	["frostbitering", "FROSTBITE RING", "ring", "rare", ["frost", "edge"], null, "ring", [["chill", 0.1]], [], "+10% CHILL CHANCE. A QUARTER OF YOUR CRITS ON CHILLED FOES FREEZE THEM SOLID.", [{ "on": "on_crit", "if": "chilled", "chance": 0.25, "do": [["status", "stun", 1]] }]],
	["returnring", "RING OF RETURNING", "ring", "rare", ["arcane"], null, "ring", [["rate", 1.06]], [], "+6% FIRE RATE. SWAPPING WEAPONS FIRES A RING OF 12 SHOTS AND ERASES THE SHOTS NEAR YOU.", [{ "on": "on_weapon_swap", "cd": 1.0, "do": [["nova", 12, 0.8, ""], ["clear_shots", 60]] }]],
	["kindlingring", "KINDLING RING", "ring", "rare", ["pyre"], null, "ring", [["burn", 0.1]], [], "+10% BURN CHANCE. DRINKING A POTION SETS EVERY FOE NEAR YOU ALIGHT.", [{ "on": "on_potion", "do": [["status_area", "burn", 2, 120], ["vfx", "ring", "#e8873a", 120]] }]],
	["hagglerhat", "HAGGLER'S HAT", "head", "legend", ["fortune"], null, "hat", [["luck", 2], ["shop_disc", 0.15]], [], "+2 LUCK, SHOP PRICES -15%. EVERY PURCHASE PAYS 10 GOLD BACK. SCROUNGERS CAN'T PICK YOUR POCKETS.", [{ "on": "on_buy", "do": [["gold", 10]] }]],
	# Boss and mini-boss drops (his ask, 6 Oct; boss_loot.gd).
	["colossusribs", "COLOSSUS RIBCAGE", "body", "legend", ["bulwark"], null, "plate", [["armor", 2], ["max_hp", 2]], [], "+2 ARMOR, +1 MAX HEART. WHEN HIT, 10 BONE SHARDS FLY OUT AROUND YOU.", [{ "on": "on_damage_taken", "do": [["nova", 10, 1.0, "spark"]] }], "g_bone_ribs"],
	["rimewardencrown", "RIME WARDEN'S CROWN", "head", "legend", ["frost"], null, "crown", [["chill", 0.2]], [], "+20% CHILL. ROLLING SLOWS EVERY SHOT NEAR YOU TO A CRAWL (EVERY 3S).", [{ "on": "on_roll", "cd": 3.0, "do": [["slow_shots", 80, 0.35]] }], "g_frost_helm"],
	["regentsignet", "PALE REGENT'S SIGNET", "trinket", "legend", ["malice", "arcane"], null, "ring", [["dmg", 1.15], ["curse", 0.08]], [], "+15% DAMAGE, 8% OF HITS CURSE. AN ELITE YOU KILL GIVES +50% CRIT FOR 5S.", [{ "on": "on_kill", "if": "elite", "do": [["buff", "crit", 0.5, 5.0]] }], "g_gild_ring"],
	["matriarchrobe", "MATRIARCH'S MIRE ROBE", "body", "legend", ["venom", "swarm"], null, "robe", [["poison", 1], ["max_hp", 2]], [], "+1 POISON, +1 MAX HEART. WHEN HIT, YOU SPILL A POISON POOL AND A BOG GNAT (A WISP) JOINS YOU FOR 6S.", [{ "on": "on_damage_taken", "do": [["zone", "poison", 40, 3.0], ["summon", 6.0]] }], "g_plague_coat"],
	["abbotpalms", "FROZEN ABBOT'S PALMS", "hands", "legend", ["frost", "fury"], null, "gloves", [["crit", 0.05], ["chill", 0.1]], [], "+5% CRIT, +10% CHILL. 15% OF HITS ARE A FROZEN PALM: THE FOE IS STUNNED AND CHILLED.", [{ "on": "on_hit", "chance": 0.15, "cd": 0.3, "do": [["status", "stun", 1], ["status", "chill", 2]] }], "g_frostglove"],
	["umbralheart", "HEART OF THE UMBRAL SUN", "neck", "legend", ["malice", "pyre"], null, "amulet", [["dmg", 1.2]], [], "+20% DAMAGE. EVERY 5S IN A FIGHT, AN ECLIPSE: 14 SHOTS RING OUT AND THE FOES NEAR YOU ARE CURSED.", [{ "on": "every_n_seconds", "period": 5.0, "if": "fighting", "do": [["nova", 14, 1.0, "spark"], ["status_area", "curse", 1, 90]] }], "g_collapsedstar"],
	["cindercrown", "CROWN OF CINDERS", "head", "legend", ["pyre"], null, "crown", [["burn", 0.3]], [], "+30% BURN. A BURNING FOE YOU KILL BLOWS UP FOR 120%.", [{ "on": "on_kill", "if": "burning", "do": [["explode", 40, 1.2]] }], "g_star_helm"],
	["stormcrownitem", "THE STORMCROWN", "head", "legend", ["storm"], null, "crown", [["chain", 0.3]], [], "+30% ARC CHANCE. EVERY 4S IN A FIGHT, LIGHTNING STRIKES 3 FOES.", [{ "on": "every_n_seconds", "period": 4.0, "if": "fighting", "do": [["bolts", 3, 1.0]] }], "g_stormcrownhelm"],
	["organpipe", "BRASS ORGAN PIPE", "trinket", "legend", ["arcane"], null, "charm", [["rate", 1.15]], [], "+15% FIRE RATE. EVERY 8TH ATTACK PLAYS A CHORD: 8 SHOTS ALL AROUND YOU.", [{ "on": "every_n_shots", "every": 8, "do": [["nova", 8, 0.8, "spark"]] }], "g_stormbottle"],
	["heronboots", "HERON'S QUILL BOOTS", "feet", "legend", ["storm", "shadow"], null, "boots", [["speed", 1.15]], [], "+15% MOVE SPEED. ROLLING THROWS 6 QUILLS BEHIND YOU.", [{ "on": "on_roll", "cd": 0.5, "do": [["shoot_at", 6, 0.7, "", 0.25, 3.14159]] }], "g_wingedboots"],
	["crackedbell", "THE CRACKED BELL", "neck", "legend", ["bulwark"], null, "amulet", [["max_hp", 2]], [], "+1 MAX HEART. WHEN HIT, IT TOLLS: EVERY FOE NEAR YOU IS STUNNED AND 12 NOTES RING OUT.", [{ "on": "on_damage_taken", "do": [["status_area", "stun", 1, 90], ["nova", 12, 0.6, "spark"]] }], "g_cowbell"],
	["mirehide", "MIRE HULK'S HIDE", "body", "legend", ["bulwark", "venom"], null, "leather", [["max_hp", 4], ["thorns", 20]], [], "+2 MAX HEARTS, +20 THORNS. WHEN ARMOR OR HEALTH TAKES A HIT, THE MIRE SPLASHES: A POISON POOL.", [{ "on": "on_damage_taken", "do": [["zone", "poison", 30, 2.5]] }], "g_berserkerhide"],
	["captainhelm", "IRON CAPTAIN'S HELM", "head", "legend", ["bulwark"], null, "helm", [["armor", 2]], [], "+2 ARMOR. WHEN ARMOR TAKES A HIT, YOU FIRE A VOLLEY OF 6 SHOTS.", [{ "on": "on_armor_lost", "do": [["shoot", 6, 1.0, "", 0.3]] }], "g_bastion_helm"],
	["abbotfists", "STONE ABBOT'S FISTS", "hands", "legend", ["bulwark", "fury"], null, "gloves", [["dmg", 1.12]], [], "+12% DAMAGE. A FIFTH OF HITS UP CLOSE ARE A STONE PALM: THE FOE IS STUNNED, THE OTHERS PUSHED AWAY.", [{ "on": "on_hit", "if": "close", "chance": 0.2, "do": [["status", "stun", 1], ["push", 50, 260]] }], "g_ironglove"],
	["heraldhorn", "HERALD'S HORN", "neck", "legend", ["fury", "malice"], null, "amulet", [["dmg", 1.08]], [], "+8% DAMAGE. ENTERING A ROOM SOUNDS THE HORN: +30% DAMAGE FOR 8S AND THE FOES NEAR YOU ARE WEAKENED.", [{ "on": "on_room_enter", "do": [["buff", "dmg", 0.3, 8.0], ["status_area", "weakened", 1, 120]] }], "g_howlertooth"],
	["keyring", "TURNKEY'S RING OF KEYS", "ring", "legend", ["fortune"], null, "ring", [["keys", 2], ["luck", 1]], [], "+2 KEYS, +1 LUCK. EVERY CHEST YOU OPEN PAYS 15 GOLD.", [{ "on": "on_chest", "do": [["gold", 15]] }], "g_gild_ring"],
	["brokerledger", "BROKER'S LEDGER", "trinket", "legend", ["fortune"], null, "charm", [["gold_mult", 1.3]], [["gold_dmg", 0.1]], "+30% GOLD, +10% DAMAGE PER 100 GOLD HELD. EVERY PURCHASE IS INVESTED: +5% DAMAGE FOR 60S", [{ "on": "on_buy", "do": [["buff", "dmg", 0.05, 60.0]] }], "g_ledger"],
	["mayorhat", "MAYOR'S TOP HAT", "head", "legend", ["fortune"], null, "hat", [["luck", 2]], [], "+2 LUCK. EVERY ROOM YOU CLEAR PAYS ITS TAXES: 6 GOLD.", [{ "on": "on_room_clear", "do": [["gold", 6]] }], "g_partyhat"],
	["landlordsignet", "LANDLORD'S SIGNET", "ring", "legend", ["fortune", "bulwark"], null, "ring", [["shop_disc", 0.2]], [], "SHOP PRICES -20%. EVERY PURCHASE GIVES 1 ARMOR.", [{ "on": "on_buy", "do": [["armor", 1]] }], "g_whetring"],
	["galeboots", "GALE WARDEN'S BOOTS", "feet", "legend", ["storm", "shadow"], null, "greaves", [["speed", 1.12], ["roll_speed", 1.2]], [], "+12% MOVE SPEED, FASTER ROLLS. ROLLING IS A GUST: FOES NEAR YOU ARE BLOWN AWAY.", [{ "on": "on_roll", "cd": 1.0, "do": [["push", 60, 280]] }], "g_sevenleague"],
	["rottingcrown", "THE ROTTING CROWN", "head", "legend", ["venom", "malice"], null, "crown", [["poison", 2]], [], "+2 POISON ON HIT. A POISONED FOE YOU KILL PASSES ALL ITS AILMENTS TO THE FOES NEAR IT.", [{ "on": "on_kill", "if": "poisoned", "do": [["spread", 60]] }], "g_crownofthorns"],
	["foremanhat", "FOREMAN'S HARD HAT", "head", "legend", ["bulwark", "demolition"], null, "helm", [["armor", 2]], [], "+2 ARMOR. ENTERING A ROOM SETS UP A GUN TURRET FOR 10S.", [{ "on": "on_room_enter", "do": [["turret", "gun", 10.0, 1.0]] }], "g_foremanhat"],
	["hoarhelm", "HOARFROST HELM", "head", "legend", ["bulwark", "storm"], null, "helm", [["armor", 2]], [], "+2 ARMOR. WHEN HIT, CHILL EVERY FOE WITHIN 80 FOR A MOMENT.", [{ "on": "on_damage_taken", "do": [["status_area", "chill", 1, 80], ["vfx", "ring", "#8fd8ff", 80]] }], "g_hoarhelm"],
	# 9.3 the second guardians' own gear.
	# 12.4 Chapter II's guardians (boss_loot.gd).
	["binderthread", "THE BINDER'S THREAD", "neck", "legend", ["bulwark"], null, "amulet", [["armor", 1]], [], "+1 ARMOR. +15% FIRE RATE.", [["mul", "rate", 1.15]], "g_binderthread"],
	["shelversarm", "THE SHELVER'S ARM", "hands", "legend", ["fury"], null, "gloves", [["dmg", 1.15]], [], "+15% DAMAGE. EVERY 8TH ATTACK HURLS 3 BOOKS FOR 150%.", [{ "on": "every_n_shots", "every": 8, "do": [["shoot", 3, 1.5, "page", 0.3]] }], "g_shelversarm"],   # 20.3
	["blackbar", "THE BLACK BAR", "head", "legend", ["malice"], null, "helm", [["armor", 2]], [], "+2 ARMOR. +20% DAMAGE. ENTERING A ROOM FIRES A RING OF 12 SHOTS.", [["mul", "dmg", 1.2], { "on": "on_room_enter", "do": [["nova", 12, 0.8, "spark"]] }], "g_blackbar"],
	["admiralhat", "ADMIRAL'S BICORNE", "head", "legend", ["bulwark", "storm"], null, "helm", [["armor", 2]], [], "+2 ARMOR. ENTERING A ROOM FIRES A RING OF 10 SHOTS.", [{ "on": "on_room_enter", "do": [["nova", 10, 0.8, "spark"]] }], "g_admiralhat"],
	["golemplate", "GOLEM KING'S MANTLE", "body", "legend", ["bulwark"], null, "plate", [["armor", 3]], [], "+3 ARMOR. +25 THORNS.", [["add", "thorns", 25]], "g_golemplate"],
	["phoenixplume", "PHOENIX PLUME", "neck", "legend", ["pyre"], null, "amulet", [], [], "YOU RISE ONCE MORE FROM DEATH. +10% DAMAGE.", [["add", "revive", 1], ["mul", "dmg", 1.1]], "g_phoenixplume"],
	["fiendchains", "FIEND'S CHAINS", "hands", "legend", ["blood", "edge"], null, "gloves", [], [], "ROLLING FLINGS 6 HOOKED BLADES AROUND YOU.", [{ "on": "on_roll", "do": [["nova", 6, 1.0, "spark"]] }], "g_fiendchains"],
	# 14.1 new sets (icons: tools/art/set_icons.py).
	["storm_hood", "STORMCALLER HOOD", "head", "rare", ["storm"], "stormcaller", "hood", [["chain", 0.08]], [], "STATIC IN THE STITCHES.", [], "g_storm_hood"],
	["storm_robe", "STORMCALLER ROBE", "body", "rare", ["storm"], "stormcaller", "robe", [["max_hp", 2]], [], "IT CRACKLES WHEN YOU MOVE.", [], "g_storm_robe"],
	["storm_boots", "STORMCALLER BOOTS", "feet", "rare", ["storm"], "stormcaller", "boots", [["speed", 1.06]], [], "LIGHT AS A SPARK.", [], "g_storm_boots"],
	["storm_ring", "STORMCALLER RING", "ring", "epic", ["storm"], "stormcaller", "ring", [["dmg", 1.08]], [], "A BOTTLED BOLT.", [], "g_storm_ring"],
	["blood_cap", "BLOODLETTER CAP", "head", "rare", ["blood"], "bloodletter", "hat", [["crit", 0.05]], [], "STAINED, NEVER WASHED.", [], "g_blood_cap"],
	["blood_coat", "BLOODLETTER COAT", "body", "rare", ["blood"], "bloodletter", "plate", [["max_hp", 2]], [], "HEAVY WITH OLD RED.", [], "g_blood_coat"],
	["blood_gloves", "BLOODLETTER GLOVES", "hands", "rare", ["blood"], "bloodletter", "gloves", [["crit_mult", 0.25]], [], "STEADY HANDS, SHARP CUTS.", [], "g_blood_gloves"],
	["blood_fang", "BLOODLETTER FANG", "neck", "epic", ["blood"], "bloodletter", "amulet", [["dmg", 1.08]], [], "IT IS STILL THIRSTY.", [], "g_blood_fang"],
	["hex_veil", "HEXWEAVER VEIL", "head", "rare", ["malice"], "hexweaver", "hood", [["dmg", 1.05]], [], "EYES THAT WISH YOU HARM.", [], "g_hex_veil"],
	["hex_shroud", "HEXWEAVER SHROUD", "body", "rare", ["malice"], "hexweaver", "robe", [["max_hp", 2]], [], "WOVEN FROM BAD LUCK.", [], "g_hex_shroud"],
	["hex_gloves", "HEXWEAVER GLOVES", "hands", "rare", ["malice"], "hexweaver", "gloves", [["rate", 1.06]], [], "FINGERS THAT KNOT CURSES.", [], "g_hex_gloves"],
	["hex_ring", "HEXWEAVER RING", "ring", "epic", ["malice"], "hexweaver", "ring", [["dmg", 1.08]], [], "A TOAD WAS INVOLVED.", [], "g_hex_ring"],
	["viper_hood", "VIPER HOOD", "head", "rare", ["venom"], "viper", "hood", [["poison", 1]], [], "SCALES ON THE BRIM.", [], "g_viper_hood"],
	["viper_coat", "VIPER COAT", "body", "rare", ["venom"], "viper", "cloak", [["max_hp", 2]], [], "IT SHEDS EVERY SPRING.", [], "g_viper_coat"],
	["viper_tabi", "VIPER TABI", "feet", "rare", ["venom"], "viper", "boots", [["speed", 1.07]], [], "QUIET AS A SNAKE.", [], "g_viper_tabi"],
	["viper_fang", "VIPER FANG", "neck", "epic", ["venom"], "viper", "amulet", [["dmg", 1.08]], [], "STILL DRIPPING.", [], "g_viper_fang"],
	["war_helm", "WARLORD HELM", "head", "rare", ["fury"], "warlord", "helm", [["armor", 1]], [], "HORNS FOR THE FRONT LINE.", [], "g_war_helm"],
	["war_hide", "WARLORD HIDE", "body", "rare", ["fury"], "warlord", "plate", [["max_hp", 2]], [], "SCARRED AND PROUD.", [], "g_war_hide"],
	["war_fists", "WARLORD FISTS", "hands", "rare", ["fury"], "warlord", "gloves", [["dmg", 1.06]], [], "MADE FOR ONE THING.", [], "g_war_fists"],
	["war_ring", "WARLORD RING", "ring", "epic", ["fury"], "warlord", "ring", [["rate", 1.08]], [], "TAKEN FROM A KING.", [], "g_war_ring"],
	["beast_helm", "BEASTMASTER HELM", "head", "rare", ["swarm"], "beastmaster", "helm", [["fam_dmg", 0.15]], [], "THE OWL KNOWS YOUR NAME.", [], "g_beast_helm"],
	["beast_cloak", "BEASTMASTER CLOAK", "body", "rare", ["swarm"], "beastmaster", "cloak", [["max_hp", 2]], [], "FUR FROM FRIENDS.", [], "g_beast_cloak"],
	["beast_glove", "BEASTMASTER GLOVE", "hands", "rare", ["swarm"], "beastmaster", "gloves", [["fam_dmg", 0.15]], [], "A PERCH FOR A WISP.", [], "g_beast_glove"],
	["beast_collar", "BEASTMASTER COLLAR", "neck", "epic", ["swarm"], "beastmaster", "amulet", [["familiars", 1]], [], "A GOOD WISP WEARS IT.", [], "g_beast_collar"],
	["drift_hood", "DRIFTER HOOD", "head", "rare", ["shadow"], "drifter", "hood", [["dodge_cd", 0.92]], [], "NEVER IN ONE PLACE.", [], "g_drift_hood"],
	["drift_cloak", "DRIFTER CLOAK", "body", "rare", ["shadow"], "drifter", "cloak", [["max_hp", 2]], [], "IT FLAPS EVEN INDOORS.", [], "g_drift_cloak"],
	["drift_steps", "DRIFTER STEPS", "feet", "rare", ["shadow"], "drifter", "boots", [["speed", 1.08]], [], "THE FLOOR FORGETS YOU.", [], "g_drift_steps"],
	["drift_ring", "DRIFTER RING", "ring", "epic", ["shadow"], "drifter", "ring", [["evade", 0.05]], [], "SLIPS OFF ANY FINGER BUT YOURS.", [], "g_drift_ring"],
	# 20.3 BOOKWORM and THE CRITIC'S REGALIA.
	["worm_specs", "BOOKWORM SPECTACLES", "head", "rare", ["arcane"], "bookworm", "helm", [["crit", 0.05]], [], "+5% CRIT. FOR READING THE SMALL PRINT.", [], "g_worm_specs"],
	["worm_cardigan", "BOOKWORM CARDIGAN", "body", "rare", ["arcane"], "bookworm", "plate", [["max_hp", 2]], [], "+1 MAX HEART. ELBOW PATCHES INCLUDED.", [], "g_worm_cardigan"],
	["worm_slippers", "BOOKWORM SLIPPERS", "feet", "rare", ["arcane"], "bookworm", "boots", [["speed", 1.06]], [], "+6% SPEED. SILENT IN THE STACKS.", [], "g_worm_slippers"],
	["worm_mitts", "BOOKWORM MITTS", "hands", "rare", ["arcane"], "bookworm", "gloves", [["rate", 1.06]], [], "+6% FIRE RATE. INK ON EVERY FINGERTIP.", [], "g_worm_mitts"],
	["critic_hat", "THE CRITIC'S HAT", "head", "legend", ["malice"], "criticregalia", "helm", [["armor", 1], ["crit", 0.05]], [], "IT HAS SEEN WORSE BOOKS. NOT MANY.", [], "g_critic_hat"],
	["critic_coat", "THE CRITIC'S COAT", "body", "legend", ["malice"], "criticregalia", "plate", [["max_hp", 4]], [], "LINED WITH REJECTED PAGES.", [], "g_critic_coat"],
	["critic_shoes", "THE CRITIC'S SHOES", "feet", "legend", ["malice"], "criticregalia", "boots", [["speed", 1.08]], [], "THEY WALK OUT OF EVERY BAD PLAY.", [], "g_critic_shoes"],
	["critic_gloves", "THE CRITIC'S GLOVES", "hands", "legend", ["malice"], "criticregalia", "gloves", [["dmg", 1.1]], [], "STAINED RED TO THE KNUCKLE.", [], "g_critic_gloves"],
	["critic_monocle", "THE CRITIC'S MONOCLE", "neck", "legend", ["malice"], "criticregalia", "amulet", [["crit", 0.08]], [], "IT FINDS EVERY FLAW.", [], "g_critic_monocle"],
	["critic_signet", "THE CRITIC'S SIGNET", "ring", "legend", ["malice"], "criticregalia", "ring", [["rate", 1.1]], [], "IT SEALS EVERY VERDICT.", [], "g_critic_signet"],
	["sun_crown", "SUNFORGED CROWN", "head", "legend", ["pyre"], "sunforged", "crown", [["burn", 0.1], ["armor", 1]], [], "FORGED IN A DYING SUN.", [], "g_sun_crown"],
	["sun_cuirass", "SUNFORGED CUIRASS", "body", "legend", ["pyre"], "sunforged", "plate", [["max_hp", 4]], [], "WARM TO THE TOUCH. ALWAYS.", [], "g_sun_cuirass"],
	["sun_boots", "SUNFORGED BOOTS", "feet", "legend", ["pyre"], "sunforged", "boots", [["speed", 1.08]], [], "EACH STEP A SMALL DAWN.", [], "g_sun_boots"],
	["sun_gauntlet", "SUNFORGED GAUNTLET", "hands", "legend", ["pyre"], "sunforged", "gloves", [["dmg", 1.1]], [], "HOLDS A FLAME LIKE A COIN.", [], "g_sun_gauntlet"],
	["sun_heart", "SUNFORGED HEART", "neck", "legend", ["pyre"], "sunforged", "amulet", [["rate", 1.1]], [], "IT BEATS IN DAYLIGHT.", [], "g_sun_heart"],
	["sun_band", "SUNFORGED BAND", "ring", "legend", ["pyre"], "sunforged", "ring", [["crit", 0.08]], [], "A RING OF NOON.", [], "g_sun_band"],
	["void_crown", "VOID REGALIA CROWN", "head", "legend", ["shadow"], "voidregalia", "crown", [["dmg", 1.08], ["armor", 1]], [], "A CROWN FOR NOTHING.", [], "g_void_crown"],
	["void_mantle", "VOID REGALIA MANTLE", "body", "legend", ["shadow"], "voidregalia", "cloak", [["max_hp", 4]], [], "STARS FALL INTO ITS FOLDS.", [], "g_void_mantle"],
	["void_steps", "VOID REGALIA STEPS", "feet", "legend", ["shadow"], "voidregalia", "boots", [["dodge_charges", 1], ["charges", 1]], [], "YOU WALK ON THE DARK.", [], "g_void_steps"],
	["void_grip", "VOID REGALIA GRIP", "hands", "legend", ["shadow"], "voidregalia", "gloves", [["rate", 1.1]], [], "IT HOLDS WHAT IS NOT THERE.", [], "g_void_grip"],
	["void_star", "VOID REGALIA STAR", "neck", "legend", ["shadow"], "voidregalia", "amulet", [["crit", 0.08]], [], "A STAR THAT WENT OUT.", [], "g_void_star"],
	["void_band", "VOID REGALIA BAND", "ring", "legend", ["shadow"], "voidregalia", "ring", [["dmg", 1.1]], [], "IT HUMS BELOW HEARING.", [], "g_void_band"],
	# Stage 27 (his word, 9 Oct): MYTHIC armor, one for every slot.
	["stormcrown", "CROWN OF THE STORM KING", "head", "mythic", ["storm", "arcane"], null, "crown", [["dmg", 1.2]], [], "+20% DAMAGE. EVERY 6S IN A FIGHT, A STORM CLOUD FOLLOWS YOUR FOES.", [{ "on": "every_n_seconds", "period": 6.0, "if": "fighting", "do": [["spell", "cloud", 1.2]] }]],
	["eternalaegis", "AEGIS OF ETERNITY", "body", "mythic", ["bulwark", "arcane"], null, "plate", [["armor", 3], ["max_hp", 4]], [], "+3 ARMOR, +2 MAX HEARTS. WHEN HIT, TIME STOPS AROUND THE NEAREST FOE (EVERY 4S).", [{ "on": "on_damage_taken", "cd": 4.0, "do": [["spell", "clock", 1.5]] }]],
	["voidstriders", "STRIDERS OF THE VOID", "feet", "mythic", ["shadow"], null, "boots", [["speed", 1.3]], [], "+30% SPEED. ROLLING OPENS A BLACK HOLE ON THE NEAREST FOE (EVERY 2S).", [{ "on": "on_roll", "cd": 2.0, "do": [["spell", "void", 2.0]] }]],
	["makergauntlets", "GAUNTLETS OF THE MAKER", "hands", "mythic", ["edge", "arcane"], null, "gloves", [["rate", 1.3]], [], "+30% FIRE RATE. EVERY 5TH ATTACK CONJURES A SPECTRAL BLADE.", [{ "on": "every_n_shots", "every": 5, "do": [["spell", "blade", 1.0]] }]],
	["elementring", "RING OF ALL ELEMENTS", "ring", "mythic", ["pyre", "frost", "venom"], null, "ring", [], [["react_dmg", 1.0]], "25% OF HITS ADD A RANDOM AILMENT. REACTIONS HIT TWICE AS HARD.", [{ "on": "on_hit", "chance": 0.25, "do": [["rand_status", 2]] }]],
	["phoenixheart", "HEART OF THE PHOENIX", "neck", "mythic", ["pyre", "blood"], null, "amulet", [["max_hp", 4]], [], "+2 MAX HEARTS. 10% OF KILLS HEAL HALF A HEART. EVERY 8S IN A FIGHT, A FIRE SERPENT.", [{ "on": "on_kill", "chance": 0.1, "do": [["heal", 1]] }, { "on": "every_n_seconds", "period": 8.0, "if": "fighting", "do": [["spell", "serpent", 1.5]] }]],
	# 34.2 THE LEGION PATH: haste turns into the companions' speed.
	["marchingboots", "MARCHING BOOTS", "feet", "rare", ["swarm"], null, "boots", [["speed", 1.1]], [["march", 2]], "+10% MOVE SPEED. EVERY 1% OF EXTRA MOVE SPEED GIVES YOUR COMPANIONS +2% ATTACK SPEED.", [], "g_marchingboots"],
	# 37.1 OFFHANDS (his word, 9 Oct: "Ideas for sprites for new stuff, and new stuff to add"; our own).
	# A new slot beside the weapon. Shields stop hits (block.gd), lanterns carry a field (auras.gd),
	# tomes cast, quivers, flasks, balloons, hearts and more.
	["o_buckler", "OAK BUCKLER", "offhand", "common", ["bulwark"], null, "offhand", [], [["block_rate", 1.25]], "STOPS A HIT EVERY 8S.", [], "o_buckler"],
	["o_kite", "KITE SHIELD", "offhand", "rare", ["bulwark"], null, "offhand", [["max_hp", 2]], [["block_rate", 1.67]], "+1 MAX HEART. STOPS A HIT EVERY 6S.", [], "o_kite"],
	["o_tower", "TOWER SHIELD", "offhand", "epic", ["bulwark"], null, "offhand", [["speed", 0.92]], [["block_rate", 2.5]], "STOPS A HIT EVERY 4S. -8% MOVE SPEED.", [], "o_tower"],
	["o_mirrorshield", "MIRROR SHIELD", "offhand", "legend", ["bulwark", "arcane"], null, "offhand", [], [["block_rate", 1.67], ["block_reflect", 1]], "STOPS A HIT EVERY 6S AND SENDS IT BACK AS 5 SHARDS FOR 150%.", [], "o_mirrorshield"],
	["o_spiketarge", "SPIKED TARGE", "offhand", "rare", ["bulwark", "fury"], null, "offhand", [["thorns", 10]], [["block_rate", 1.43], ["block_spikes", 1]], "+10 THORNS. STOPS A HIT EVERY 7S, AND A BLOCK SENDS OUT 8 SPIKES.", [], "o_spiketarge"],
	["o_handmirror", "HAND MIRROR", "offhand", "epic", ["arcane"], null, "offhand", [], [["block_chance", 0.15], ["block_reflect", 1]], "15% OF HITS ARE STOPPED AND SENT BACK AS SHARDS.", [], "o_handmirror"],
	["o_quiver", "LEATHER QUIVER", "offhand", "common", ["edge"], null, "offhand", [["rate", 1.1], ["pierce", 1]], [], "+10% FIRE RATE. +1 PIERCE.", [], "o_quiver"],
	["o_emberquiver", "EMBER QUIVER", "offhand", "rare", ["pyre"], null, "offhand", [["burn", 0.15], ["rate", 1.05]], [], "+15% BURN CHANCE. +5% FIRE RATE.", [], "o_emberquiver"],
	["o_rimequiver", "RIME QUIVER", "offhand", "rare", ["frost"], null, "offhand", [["chill", 0.15], ["rate", 1.05]], [], "+15% CHILL CHANCE. +5% FIRE RATE.", [], "o_rimequiver"],
	["o_lantern", "TIN LANTERN", "offhand", "common", ["pyre"], null, "offhand", [], [["halo_burn", 1]], "A FIELD OF FIRE AROUND YOU BURNS FOES. IT GROWS WITH INT.", [], "o_lantern"],
	["o_soullantern", "SOUL LANTERN", "offhand", "epic", ["malice"], null, "offhand", [], [["halo_wither", 1], ["aura_reach", 0.15]], "A WITHERING FIELD AROUND YOU CURSES FOES. +15% AURA REACH.", [], "o_soullantern"],
	["o_starlantern", "STAR LANTERN", "offhand", "legend", ["arcane"], null, "offhand", [], [["halo_sun", 1], ["aura_reach", 0.25]], "A FIELD OF SUNLIGHT AROUND YOU BURNS AND HITS FOES. +25% AURA REACH.", [], "o_starlantern"],
	["o_primer", "SPELL PRIMER", "offhand", "common", ["arcane"], null, "offhand", [], [], "+1 INT. EVERY 5S IN A FIGHT, 3 BOLTS STRIKE FOES FOR 60%.", [["attr", "int", 1], { "on": "every_n_seconds", "period": 5.0, "if": "fighting", "do": [["bolts", 3, 0.6]] }], "o_primer"],
	["o_blackgrimoire", "BLACK GRIMOIRE", "offhand", "epic", ["malice", "arcane"], null, "offhand", [], [], "+2 INT. EVERY 4S IN A FIGHT, FOES NEAR YOU ARE CURSED.", [["attr", "int", 2], { "on": "every_n_seconds", "period": 4.0, "if": "fighting", "do": [["status_area", "curse", 1, 90], ["vfx", "ring", "#a35bd6", 90]] }], "o_blackgrimoire"],
	["o_hipflask", "HIP FLASK", "offhand", "common", ["fury"], null, "offhand", [], [["tipsy_gain", 1]], "DRINKS GIVE +1 MORE TIPSY. EVERY ROOM: +1 TIPSY.", [{ "on": "on_room_enter", "do": [["tipsy", 1]] }], "o_hipflask"],
	["o_redvial", "RED VIAL", "offhand", "rare", ["blood"], null, "offhand", [], [], "WHEN A HIT LEAVES YOU LOW, HEAL 2 HEARTS (ONCE A MINUTE).", [{ "on": "on_damage_taken", "if": "low_hp", "cd": 60.0, "do": [["heal", 4]] }], "o_redvial"],
	["o_balloon", "RED BALLOON", "offhand", "common", ["shadow"], null, "offhand", [["speed", 1.1], ["roll_speed", 1.1]], [], "+10% MOVE SPEED. ROLLS GO FURTHER.", [], "o_balloon"],
	["o_balloons", "BALLOON BUNCH", "offhand", "rare", ["shadow"], null, "offhand", [["speed", 1.15], ["dodge_charges", 1]], [], "+15% MOVE SPEED. +1 ROLL CHARGE.", [], "o_balloons"],
	["o_spareheart", "SPARE HEART", "offhand", "rare", ["bulwark"], null, "offhand", [["max_hp", 4]], [], "+2 MAX HEARTS.", [], "o_spareheart"],
	["o_ironheart", "IRON HEART", "offhand", "epic", ["bulwark"], null, "offhand", [], [["room_armor", 1]], "+1 ARMOR AFTER EVERY ROOM.", [], "o_ironheart"],
	["o_bombsatchel", "BOMB SATCHEL", "offhand", "common", ["demolition"], null, "offhand", [["bombs", 3], ["bomb_mult", 1.2]], [], "+3 BOMBS. +20% BOMB DAMAGE. A ROLL DROPS A SMALL BOMB (ONCE A SECOND).", [{ "on": "on_roll", "cd": 1.0, "do": [["bomb", 0.6]] }], "o_bombsatchel"],
	["o_torch", "PITCH TORCH", "offhand", "common", ["pyre"], null, "offhand", [["burn", 0.2]], [], "+20% BURN CHANCE.", [], "o_torch"],
	["o_seerorb", "SEER'S ORB", "offhand", "rare", ["arcane", "fortune"], null, "offhand", [["orbitals", 1], ["luck", 1]], [], "+1 MOON. +1 LUCK.", [], "o_seerorb"],
	["o_warbanner", "WAR BANNER", "offhand", "rare", ["swarm"], null, "offhand", [], [["minion_dmg", 0.3], ["minion_cap", 1]], "COMPANIONS DEAL +30% DAMAGE. +1 COMPANION AT ONCE.", [], "o_warbanner"],
	["o_graveskull", "GRAVE SKULL", "offhand", "epic", ["malice", "swarm"], null, "offhand", [], [], "15% OF YOUR KILLS RAISE A SKELETON FOR 15S.", [{ "on": "on_kill", "chance": 0.15, "do": [["raise", 15.0, 0.8]] }], "o_graveskull"],
	["o_templebell", "TEMPLE BELL", "offhand", "rare", ["bulwark"], null, "offhand", [], [], "EVERY 8S IN A FIGHT, FOES NEAR YOU ARE STUNNED.", [{ "on": "every_n_seconds", "period": 8.0, "if": "fighting", "do": [["status_area", "stun", 1, 70], ["vfx", "ring", "#f2c94c", 70]] }], "o_templebell"],
	["o_lute", "TRAVELLER'S LUTE", "offhand", "rare", ["fortune"], null, "offhand", [], [], "EVERY 10S IN A FIGHT, A SONG: +25% DAMAGE FOR 4S.", [{ "on": "every_n_seconds", "period": 10.0, "if": "fighting", "do": [["buff", "dmg", 0.25, 4.0], ["vfx", "ring", "#e86fb4", 40]] }], "o_lute"],
	["firststar", "SHARD OF THE FIRST STAR", "trinket", "mythic", ["arcane", "pyre"], null, "charm", [["crit", 0.15]], [], "+15% CRIT. EVERY 4TH CRIT CALLS A COMET THROUGH THE FOE.", [{ "on": "on_crit", "every": 4, "do": [["spell", "comet", 2.5]] }]],
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

## 24.2 (his word, 9 Oct: "make armor sets not repetitive like now: it drops only one set until you
## complete it, and when you complete it it still drops frequently"). Expanded game only:
##   - a started set's missing piece comes now and then: CHASE_BASE + CHASE_STEP a worn piece (x1.6
##     with MASTER TAILOR), where it was 25% + 10% a piece (13.2); the shop still offers one;
##   - a piece you own already (worn or in your pack) is rolled again, so a set you have whole stops
##     dropping;
##   - two gear drops in a row are never from the same set (rolled again, REROLLS times at most).
const CHASE_BASE := 0.08
const CHASE_STEP := 0.04
const REROLLS := 4

static func random_gear(rarity: String) -> Dictionary:
	var p := G.player
	var rogues := GameData.rogues() and p != null
	if rogues and not p.sets.is_empty():
		var have := 0
		for id in p.sets:
			if p.sets[id] < set_size(id):
				have = maxi(have, p.sets[id])
		if have > 0 and randf() < (CHASE_BASE + CHASE_STEP * have) * (1.6 if p.g("tailor") > 0 else 1.0):   # 13.2: the set you started comes looking for you
			var piece = chase_piece(p)
			if piece != null and piece["set"] != G.run_stats.get("last_set", ""):
				_note_drop(piece)
				return piece
	var pool := []
	for g in all():
		if g["rarity"] == rarity and g["id"] != "hagglerhat" and not BossLoot.is_unique(g["id"]) and not Dice.banned(g["id"]):   # (brazil.gd, boss_loot.gd; 35.1)
			pool.append(g)
	if pool.is_empty():   # 35.1: (every one of this rarity banished)
		for g in all():
			if g["rarity"] == rarity:
				pool.append(g)
	var got: Dictionary = TB.pick(pool)
	if rogues:
		for i in REROLLS:
			if not _stale(p, got):
				break
			got = TB.pick(pool)
		_note_drop(got)
	return got

## 24.2: a drop that would repeat: a piece you own, or one of the set the last gear came from.
static func _stale(p: Player, g: Dictionary) -> bool:
	if owns(p, g["id"]):
		return true
	return g["set"] != null and g["set"] == G.run_stats.get("last_set", "")

static func _note_drop(g: Dictionary) -> void:
	G.run_stats["last_set"] = g["set"] if g["set"] != null else ""

## Whether the hero wears this piece or carries it in the pack.
static func owns(p: Player, id: String) -> bool:
	for sl in p.gear:
		if p.gear[sl] != null and p.gear[sl]["id"] == id:
			return true
	for it in p.backpack:
		if it != null and it.get("item", "") == "gear" and it["id"] == id:
			return true
	return false

## Item rarity for drops, door rewards and shops (04b roll_item_rarity).
static func roll_item_rarity(floor_index: int, source: String = "drop") -> String:
	var f := floor_index
	var w := { "common": maxi(60 - 9 * f, 10), "rare": 30, "epic": 8 + 4 * f, "legend": 2 + 2 * f }
	if source == "boss":
		w = { "common": 0, "rare": 30, "epic": 45, "legend": 25 }
	if source == "elite":
		w = { "common": 0, "rare": 50, "epic": 38, "legend": 12 }
	if GameData.rogues():   # 27 (his word, 9 Oct): MYTHIC weapons and armor, rarest of all: guardians, elites, deep floors
		w["mythic"] = 8 if source == "boss" else (3 if source == "elite" else maxi(0, f - 5))
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
## 13.2 (his ask, 7 Oct: "make armor sets more meaningful, a much more rewarding feel when you
## complete a set, and something to plan for, not just random pieces"). Expanded game only:
##   3 pieces   +1 ARMOR, +8% DAMAGE (a step between the 2- and 4-piece bonuses)
##   4 pieces   the set's own power, plus SET MASTERY: +1 MAX HEART, +12% DAMAGE, an aura in the
##              set's colour; the first time in a run: slow motion, a banner, a full heal and a relic
##   chasing    once a set is started, a gear drop is often one of its missing pieces
##              (chase_piece), and shops offer one.
const B3 := [["armor", 1], ["dmg", 1.08]]
const D3 := "+1 ARMOR, +8% DAMAGE"
const MASTERY := [["max_hp", 2], ["dmg", 1.12]]
const D_MASTERY := "SET MASTERY: +1 MAX HEART, +12% DAMAGE"

## How many pieces make the set whole (4, or 6 for a LEGENDARY set: 14.1).
static func set_size(set_id: String) -> int:
	return SETS[set_id].get("size", 4)

## The pieces of a set, in row order.
static func pieces(set_id: String) -> Array:
	return all().filter(func(g): return g["set"] == set_id)

## A missing piece of the set the hero is furthest into (null when none is started).
static func chase_piece(p: Player) -> Variant:
	if p == null:
		return null
	var best := ""
	var most := 0
	for id in p.sets:
		if p.sets[id] > most and p.sets[id] < set_size(id):
			best = id
			most = p.sets[id]
	if best == "":
		return null
	var owned := {}
	for sl in p.gear:
		if p.gear[sl] != null:
			owned[p.gear[sl]["id"]] = true
	for it in p.backpack:
		if it != null:
			owned[it["id"]] = true
	var miss := pieces(best).filter(func(g): return not owned.has(g["id"]) and not Dice.banned(g["id"]))
	return TB.pick(miss) if not miss.is_empty() else null

## Whether an item would add to a set the hero has started (the ground and shop show "SET").
static func continues_set(p: Player, it: Dictionary) -> bool:
	if it.get("item", "") != "gear" or it.get("set") == null or p == null or p.sets.get(it["set"], 0) <= 0:
		return false
	return not p.gear.values().any(func(g): return g != null and g["id"] == it["id"])

## The step a number of worn pieces reaches. A 6-piece set steps at 2, 4 and 6.
static func _tier_of(n: int, size: int = 4) -> int:
	if size == 6:
		return 3 if n >= 6 else (2 if n >= 4 else (1 if n >= 2 else 0))
	if not GameData.rogues():
		return 2 if n >= 4 else (1 if n >= 2 else 0)
	return 3 if n >= 4 else (2 if n >= 3 else (1 if n >= 2 else 0))

## Pieces needed for a step.
static func step_need(size: int, tier: int) -> int:
	if size == 6:
		return tier * 2
	return [0, 2, 3, 4][tier]

static func _apply_tier(p: Player, s: Dictionary, set_id: String, tier: int, dir: int) -> void:
	var top := 3 if GameData.rogues() else 2
	var six: bool = s.get("size", 4) == 6
	if tier == 1:
		Weapons.apply_tuples(p, s["b2"], dir, "s2:" + set_id)
		Effects.apply_equipment(p, s.get("e2", []), dir, "se2:" + set_id)
	elif tier == 2 and top == 3 and not six:
		Weapons.apply_tuples(p, B3, dir, "s3:" + set_id)
	elif tier == 2 and six:
		Effects.apply_equipment(p, s.get("e4", []), dir, "se4:" + set_id)
	else:
		if six:
			Effects.apply_equipment(p, s.get("e6", []), dir, "se6:" + set_id)
		else:
			Weapons.apply_tuples(p, s.get("b4", []), dir, "s4:" + set_id)
			Weapons.apply_hooks(p, s.get("b4h", []), dir)
			Effects.apply_equipment(p, s.get("e4", []), dir, "se4:" + set_id)
		if top == 3:
			Weapons.apply_tuples(p, MASTERY, dir, "sm:" + set_id)
			if dir < 0:
				p.hp = mini(p.hp, p.max_hp)

static func set_desc(s: Dictionary, tier: int) -> String:
	var top := 3 if GameData.rogues() else 2
	if tier == 1:
		return s["d2"]
	if s.get("size", 4) == 6:
		return s["d4"] if tier == 2 else s["d6"]
	if tier == 2 and top == 3:
		return D3
	return s["d4"]

## The whole set's own power (the last step's line).
static func full_desc(s: Dictionary) -> String:
	return s.get("d6", s["d4"])

static func update_sets(p: Player, set_id: Variant, delta: int) -> void:
	if set_id == null:
		return
	var s: Dictionary = SETS[set_id]
	p.sets[set_id] = p.sets.get(set_id, 0) + delta
	var tier := _tier_of(p.sets[set_id], s.get("size", 4))
	var top := 3 if GameData.rogues() else 2
	var have: int = p.set_tier.get(set_id, 0)
	while have < tier:
		have += 1
		_apply_tier(p, s, set_id, have, 1)
		if have == top and top == 3:
			_complete(p, s, set_id)
		else:
			G.toast(s["name"] + " SET: " + set_desc(s, have), "gold")
	while have > tier:
		_apply_tier(p, s, set_id, have, -1)
		have -= 1
	p.set_tier[set_id] = have

## A set is whole: the big moment (the first time this run), the aura from now on.
static func _complete(p: Player, s: Dictionary, set_id: String) -> void:
	var done: Dictionary = G.run_stats.get("sets_done", {})
	G.run_stats["sets_done"] = done
	var cols: Array = Weapons.TAG_COLS.get(s["tag"], Weapons.TAG_COLS["core"])
	if done.has(set_id) or G.state != &"play" or Camp.active():   # 20.2: the training ground's sets do not count
		G.toast(s["name"] + " SET COMPLETE: " + full_desc(s), "gold")
		return
	done[set_id] = true
	Meta.meta["sets_done"] = Meta.meta.get("sets_done", 0) + 1
	G.hitstop = 0.45
	Juice.flash(0.4)
	G.add_shake(10)
	Snd.play("unlock")
	Snd.play("relic")
	G.show_banner(s["name"] + (" LEGENDARY SET COMPLETE!" if s.get("size", 4) == 6 else " SET COMPLETE!"), full_desc(s))
	Barks.hero("set", true)   # 21.1
	G.toast(D_MASTERY, "gold")
	for k in 3:
		Fx.burst(p.x, p.y - 6, cols, 26, 70 + k * 40)
	p.hp = p.max_hp
	var rel := G.roll_relics(1, "boss")
	if not rel.is_empty():
		G.add_relic(p, rel[0])

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
