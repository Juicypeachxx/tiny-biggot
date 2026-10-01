class_name Traits
extends RefCounted
## Level-up traits, build families and hero skill trees (port of 01b_traits.rb).
## Each trait pick applies its effect once; picking it again stacks another rank.
## Rows are [id, family, max rank, name, desc, capstone]; effects are the
## branches of apply(), converted line by line from the Ruby lambdas.

const FAMILIES := {
	"core": { "name": "CORE", "col": "tan", "hex": "#c9c2a8" },
	"pyre": { "name": "PYRE", "col": "orange", "hex": "#e8873a" },
	"frost": { "name": "FROST", "col": "cyan", "hex": "#6fd3e0" },
	"venom": { "name": "VENOM", "col": "lime", "hex": "#b8e05a" },
	"storm": { "name": "STORM", "col": "cyan", "hex": "#4d9be6" },
	"blood": { "name": "BLOOD", "col": "red", "hex": "#d8443c" },
	"bulwark": { "name": "BULWARK", "col": "grey", "hex": "#8b8f9c" },
	"shadow": { "name": "SHADOW", "col": "purple", "hex": "#a35bd6" },
	"arcane": { "name": "ARCANE", "col": "pink", "hex": "#e86fb4" },
	"fortune": { "name": "FORTUNE", "col": "gold", "hex": "#f2c94c" },
	"demolition": { "name": "DEMOLITION", "col": "orange", "hex": "#d8443c" },
	"swarm": { "name": "SWARM", "col": "gold", "hex": "#e8873a" },
}

## Family bonuses unlock at 2, 4 and 6 total ranks in that family.
const FAMILY_BONUS := {
	"pyre": ["+10% BURN CHANCE", "BURNS DEAL +50% DAMAGE", "BURNING FOES TAKE +25% DAMAGE"],
	"frost": ["+10% CHILL CHANCE", "CHILLED FOES TAKE +15% DAMAGE", "KILLS CHILL NEARBY FOES"],
	"venom": ["+1 POISON ON HIT", "POISON TICKS TWICE AS FAST", "POISON DAMAGE +60%"],
	"storm": ["+10% CHAIN CHANCE", "LIGHTNING DEALS +50% DAMAGE", "HITS HAVE 8% CHANCE TO CALL LIGHTNING"],
	"blood": ["+5% CRIT CHANCE", "CRITS DEAL +0.5X MORE", "CRITS PIERCE THROUGH FOES"],
	"bulwark": ["+10 THORN DAMAGE", "+1 ARMOR AFTER EACH ROOM", "20% CHANCE TO IGNORE A HIT"],
	"shadow": ["ROLL RECHARGES 15% FASTER", "ROLLING THROUGH FOES DAMAGES THEM", "+50% DAMAGE FOR 1S AFTER A ROLL"],
	"arcane": ["+1 ORBITING MOON", "SHOTS HOME IN", "+1 PROJECTILE"],
	"fortune": ["+10% GOLD", "BETTER RELIC RARITY", "+25% DAMAGE"],
	"demolition": ["BOMBS +25% DAMAGE", "10% OF SHOTS EXPLODE", "EXPLOSIONS DEAL DOUBLE TO ELITES"],
	"swarm": ["+1 WISP", "WISPS DEAL +50% DAMAGE", "WISPS FIRE TWO SHOTS"],}

const ROWS := [
	["vitality", "core", 3, "VITALITY", "+1 MAX HEART, HEAL 1 HEART", false],
	["might", "core", 5, "MIGHT", "+12% DAMAGE", false],
	["haste", "core", 5, "HASTE", "+10% FIRE RATE", false],
	["swiftness", "core", 3, "SWIFTNESS", "+8% MOVE SPEED", false],
	["reach", "core", 3, "REACH", "+15% RANGE AND SHOT SPEED", false],
	["precision", "core", 4, "PRECISION", "+6% CRIT CHANCE", false],
	["kindling", "pyre", 3, "KINDLING", "+15% CHANCE TO BURN", false],
	["searing", "pyre", 3, "SEARING", "BURNS DEAL +40% DAMAGE", false],
	["wildfire", "pyre", 2, "WILDFIRE", "BURNS LAST LONGER AND LEAP TO NEARBY FOES", false],
	["smoulder", "pyre", 3, "SMOULDER", "+10% DAMAGE TO BURNING FOES", false],
	["flametrail", "pyre", 2, "FLAME TRAIL", "ROLLING LEAVES A TRAIL OF FIRE", false],
	["inferno", "pyre", 1, "INFERNO", "BURNING FOES EXPLODE ON DEATH AND SET OTHERS ABLAZE", true],
	["chillbite", "frost", 3, "CHILLBITE", "+15% CHANCE TO CHILL", false],
	["deepcold", "frost", 2, "DEEP COLD", "CHILL LASTS LONGER AND SLOWS MORE", false],
	["frostbite", "frost", 3, "FROSTBITE", "+12% DAMAGE TO CHILLED FOES", false],
	["icearmor", "frost", 1, "ICE ARMOR", "TAKING A HIT CHILLS EVERY FOE NEARBY", false],
	["glacial", "frost", 2, "GLACIAL LANCE", "EVERY 5TH SHOT IS A PIERCING ICE LANCE", false],
	["shatter", "frost", 1, "SHATTER", "CHILLED FOES BELOW 30% HEALTH SHATTER INTO ICE", true],
	["toxin", "venom", 3, "TOXIN", "HITS ADD +1 POISON", false],
	["virulence", "venom", 3, "VIRULENCE", "POISON DEALS +35% DAMAGE", false],
	["corrode", "venom", 2, "CORRODE", "POISONED FOES TAKE +3% DAMAGE PER STACK", false],
	["toxiccloud", "venom", 2, "NOXIOUS CLOUD", "KILLS LEAVE A POISON CLOUD", false],
	["barbs", "venom", 2, "BARBS", "20% CHANCE TO FIRE AN EXTRA POISON DART", false],
	["plague", "venom", 1, "PLAGUE", "POISON SPREADS WITH ALL ITS STACKS WHEN A FOE DIES", true],
	["static", "storm", 3, "STATIC", "+12% CHANCE FOR HITS TO ARC", false],
	["conductor", "storm", 2, "CONDUCTOR", "ARCS JUMP TO 1 MORE FOE", false],
	["overload", "storm", 3, "OVERLOAD", "ARCS AND LIGHTNING DEAL +40% DAMAGE", false],
	["thunderclap", "storm", 2, "THUNDERCLAP", "EVERY 8TH SHOT CALLS LIGHTNING", false],
	["livewire", "storm", 2, "LIVE WIRE", "+10% FIRE RATE, +5% MOVE SPEED", false],
	["tempest", "storm", 1, "TEMPEST", "EVERY 3 SECONDS, LIGHTNING STRIKES 3 FOES", true],
	["keenedge", "blood", 3, "KEEN EDGE", "+7% CRIT CHANCE", false],
	["carnage", "blood", 3, "CARNAGE", "CRITS DEAL +0.35X MORE", false],
	["vampiric", "blood", 2, "VAMPIRIC", "CRITS HAVE 4% CHANCE TO HEAL", false],
	["desperation", "blood", 2, "DESPERATION", "+10% DAMAGE FOR EACH MISSING HEART", false],
	["lacerate", "blood", 2, "LACERATE", "CRITS MAKE FOES BLEED", false],
	["sanguine", "blood", 1, "SANGUINE FRENZY", "EACH KILL GIVES +4% DAMAGE UNTIL THE ROOM ENDS", true],
	["plating", "bulwark", 3, "PLATING", "+1 ARMOR", false],
	["spikes", "bulwark", 3, "SPIKED HIDE", "+10 THORN DAMAGE", false],
	["ironskin", "bulwark", 1, "IRON SKIN", "START EACH ROOM WITH AT LEAST 1 ARMOR", false],
	["shieldbash", "bulwark", 2, "SHIELD BASH", "ROLLING INTO FOES HITS HARDER WITH MORE ARMOR", false],
	["fortress", "bulwark", 2, "FORTRESS", "+8% DAMAGE PER ARMOR (UP TO 5)", false],
	["unbreakable", "bulwark", 1, "UNBREAKABLE", "WHEN ARMOR BREAKS, RELEASE A NOVA AND ERASE NEARBY SHOTS", true],
	["fleet", "shadow", 2, "FLEET", "+1 ROLL CHARGE", false],
	["ambush", "shadow", 3, "AMBUSH", "AFTER A ROLL, YOUR NEXT SHOTS CRIT", false],
	["phantom", "shadow", 2, "PHANTOM", "ROLLS GO FURTHER AND KEEP YOU SAFE LONGER", false],
	["evasion", "shadow", 3, "EVASION", "8% CHANCE TO DODGE A HIT", false],
	["smoke", "shadow", 1, "SMOKE BOMB", "ROLLING LEAVES SMOKE THAT ERASES SHOTS", false],
	["nightfall", "shadow", 1, "NIGHTFALL", "ROLL STRIKES DEAL HEAVY DAMAGE AND KILLS REFUND THE ROLL", true],
	["multicast", "arcane", 2, "MULTICAST", "+1 PROJECTILE, -10% DAMAGE", false],
	["seeking", "arcane", 2, "SEEKING", "SHOTS HOME IN", false],
	["orbit", "arcane", 2, "ORBIT", "+1 ORBITING MOON", false],
	["spellweave", "arcane", 3, "SPELLWEAVE", "+15% SHOT SIZE AND DAMAGE", false],
	["rebound", "arcane", 2, "REBOUND", "SHOTS BOUNCE OFF WALLS", false],
	["echo", "arcane", 1, "ARCANE ECHO", "30% CHANCE FOR EVERY SHOT TO CAST AGAIN", true],
	["prospector", "fortune", 3, "PROSPECTOR", "+20% GOLD", false],
	["haggler", "fortune", 3, "HAGGLER", "SHOPS 10% CHEAPER", false],
	["luckyfind", "fortune", 3, "LUCKY FIND", "BETTER RELIC RARITY", false],
	["interest", "fortune", 2, "INTEREST", "GAIN 8% OF YOUR GOLD AFTER EACH ROOM", false],
	["jackpot", "fortune", 1, "JACKPOT", "ELITES AND GUARDIANS SHOWER GEMS", false],
	["midas", "fortune", 1, "MIDAS TOUCH", "+1% DAMAGE FOR EVERY 5 GOLD HELD", true],
	["satchel", "demolition", 3, "SATCHEL", "+2 BOMBS", false],
	["blastradius", "demolition", 3, "BLAST RADIUS", "BOMBS +30% RADIUS AND DAMAGE", false],
	["shrapnel", "demolition", 3, "SHRAPNEL", "12% OF SHOTS EXPLODE ON HIT", false],
	["sapper", "demolition", 1, "SAPPER", "GAIN 1 BOMB AFTER EACH ROOM", false],
	["fusemaster", "demolition", 1, "FUSE MASTER", "YOUR BOMBS NO LONGER HURT YOU AND BLOW FASTER", false],
	["cluster", "demolition", 1, "CLUSTER CHARGE", "BOMBS BURST INTO 4 MORE BOMBS", true],
	["wispcall", "swarm", 3, "WISP CALL", "+1 WISP FOLLOWS YOU", false],
	["packtactics", "swarm", 3, "PACK TACTICS", "WISPS DEAL +40% DAMAGE", false],
	["feral", "swarm", 2, "FERAL", "WISPS SHOOT 25% FASTER", false],
	["carrion", "swarm", 2, "CARRION", "KILLS HAVE 10% CHANCE TO RAISE A SPIRIT", false],
	["hive", "swarm", 1, "HIVE", "+1 ORBITING MOON AND +1 WISP", false],
	["legion", "swarm", 1, "LEGION", "EVERY 5 KILLS SUMMON A TEMPORARY WISP", true],]

const TREE_COSTS := [10, 20, 35, 60]
## [name, desc] per node; effects in apply_node().
const SKILL_BRANCHES := [
	{ "name": "MIGHT", "nodes": [["SHARPENED", "+10% DAMAGE"], ["QUICK HANDS", "+10% FIRE RATE"], ["TRAINED EYE", "+8% CRIT CHANCE"], ["HEIRLOOM", "START WITH A RANDOM RARE RELIC"]] },
	{ "name": "SURVIVAL", "nodes": [["HARDY", "+1 MAX HEART"], ["PADDED", "START WITH 1 ARMOR"], ["NIMBLE", "+1 ROLL CHARGE"], ["SECOND WIND", "ONCE PER RUN, SURVIVE A KILLING BLOW"]] },
]
const HERO_BRANCH := {
	"hexer": { "name": "HEXCRAFT", "nodes": [["CURVING HEX", "HEX BOLTS TURN HARDER"], ["MALEDICT", "20% CHANCE TO CURSE: CURSED FOES TAKE +25%"], ["PIERCING HEX", "+1 PIERCE"], ["HEX BLOOM", "BOLTS SPLIT IN TWO ON THEIR FIRST HIT"]] },
	"poacher": { "name": "MARKSMAN", "nodes": [["LONG SHOT", "+10% SHOT SPEED AND RANGE"], ["HEAVY BOLT", "EVERY 6TH BOLT DEALS TRIPLE DAMAGE"], ["SLICK RELOAD", "ROLLING RELOADS INSTANTLY"], ["VOLLEY", "+2 BOLTS IN A TIGHT SPREAD"]] },
	"brute": { "name": "BERSERKER", "nodes": [["THICK HIDE", "+2 MAX HEARTS"], ["CONCUSS", "HATCHETS HAVE 20% CHANCE TO STUN"], ["FRESH BLOOD", "+25% DAMAGE AT FULL HEALTH"], ["BLOOD RAGE", "BELOW HALF HEALTH: +40% RATE, +20% SPEED"]] },
	"gravedigger": { "name": "UNDERTAKER", "nodes": [["FISTFUL", "+1 CLOD PER THROW"], ["SPARE POWDER", "GAIN 1 BOMB AFTER EACH ROOM"], ["BURY", "CLODS HAVE 15% CHANCE TO STUN"], ["GRAVE HARVEST", "BOMB KILLS DROP BOMBS AND HEARTS"]] },
	"alchemist": { "name": "TRANSMUTER", "nodes": [["POTENT BREW", "+1 POISON ON HIT"], ["WIDE SPLASH", "FLASK BURSTS 40% BIGGER"], ["ELIXIR", "POTIONS HEAL MORE AND MAKE YOU SAFE FOR 3S"], ["VOLATILE MIX", "POISONED FOES EXPLODE ON DEATH"]] },
	"warden": { "name": "LAMPLIGHTER", "nodes": [["BRIGHT FLAME", "+20% LANTERN SIZE"], ["KINDLED", "LANTERN HITS OFTEN BURN"], ["HOMEWARD", "THE LANTERN HITS TWICE AS HARD ON ITS WAY BACK"], ["TWIN FLAME", "THROW TWO LANTERNS AT ONCE"]] },
}

static var _list: Array = []
static var _by_id := {}

static func all() -> Array:
	if _list.is_empty():
		for row in ROWS:
			var t := { "id": row[0], "fam": row[1], "max": row[2], "name": row[3], "desc": row[4], "cap": row[5] }
			_list.append(t)
			_by_id[t["id"]] = t
	return _list

static func by_id(id: String) -> Dictionary:
	all()
	return _by_id[id]

static func tree_for(hero_id: String) -> Array:
	return SKILL_BRANCHES + [HERO_BRANCH[hero_id]]

static func apply(id: String, p: Player) -> void:
	match id:
		"vitality":
			p.max_hp += 2
			p.hp = min(p.max_hp, p.hp + 2)
		"might":
			p.dmg *= 1.12
		"haste":
			p.rate *= 1.1
		"swiftness":
			p.speed *= 1.08
		"reach":
			p.life *= 1.15
			p.shot_speed *= 1.15
		"precision":
			p.crit += 0.06
		"kindling":
			p.burn += 0.15
		"searing":
			p.burn_dmg += 0.4
		"wildfire":
			p.burn_time += 1.0
			p.burn_leap += 0.2
		"smoulder":
			p.vs_burn += 0.1
		"flametrail":
			p.fire_trail += 1
		"inferno":
			p.inferno = true
		"chillbite":
			p.chill += 0.15
		"deepcold":
			p.chill_time += 1.0
			p.chill_slow = max(0.2, p.chill_slow - 0.12)
		"frostbite":
			p.vs_chill += 0.12
		"icearmor":
			p.ice_armor = true
		"glacial":
			p.lance_n = 5 if p.lance_n == 0 else max(3, p.lance_n - 1)
		"shatter":
			p.shatter = true
		"toxin":
			p.poison += 1
		"virulence":
			p.poison_dmg += 0.35
		"corrode":
			p.corrode += 0.03
		"toxiccloud":
			p.cloud += 1
		"barbs":
			p.barbs += 0.2
		"plague":
			p.plague = true
		"static":
			p.chain += 0.12
		"conductor":
			p.chain_jumps += 1
		"overload":
			p.storm_dmg += 0.4
		"thunderclap":
			p.thunder_n = 8 if p.thunder_n == 0 else 5
		"livewire":
			p.rate *= 1.1
			p.speed *= 1.05
		"tempest":
			p.tempest = true
		"keenedge":
			p.crit += 0.07
		"carnage":
			p.crit_mult += 0.35
		"vampiric":
			p.crit_heal += 0.04
		"desperation":
			p.desperate += 0.1
		"lacerate":
			p.bleed += 1
		"sanguine":
			p.sanguine = true
		"plating":
			p.armor += 1
		"spikes":
			p.thorns += 10
		"ironskin":
			p.ironskin = true
		"shieldbash":
			p.bash += 1
			p.shadowstep = true
		"fortress":
			p.fortress += 0.08
		"unbreakable":
			p.unbreakable = true
		"fleet":
			p.dodge_charges += 1
			p.charges += 1
		"ambush":
			p.ambush += 2
		"phantom":
			p.roll_speed *= 1.15
			p.roll_time += 0.06
		"evasion":
			p.evade += 0.08
		"smoke":
			p.smoke = true
		"nightfall":
			p.nightfall = true
			p.shadowstep = true
		"multicast":
			p.count += 1
			p.dmg *= 0.9
		"seeking":
			p.homing += 2.0
		"orbit":
			p.orbitals += 1
		"spellweave":
			p.size *= 1.15
			p.dmg *= 1.15
		"rebound":
			p.bounce += 1
		"echo":
			p.echo += 0.3
		"prospector":
			p.gold_mult *= 1.2
		"haggler":
			p.shop_disc = min(0.6, p.shop_disc + 0.1)
		"luckyfind":
			p.luck += 1
		"interest":
			p.interest += 0.08
		"jackpot":
			p.jackpot = true
		"midas":
			p.midas = true
		"satchel":
			p.bombs += 2
		"blastradius":
			p.bomb_mult *= 1.3
			p.bomb_r *= 1.15
		"shrapnel":
			p.shrapnel += 0.12
		"sapper":
			p.sapper += 1
		"fusemaster":
			p.fuse = true
		"cluster":
			p.cluster = true
		"wispcall":
			p.familiars += 1
		"packtactics":
			p.fam_dmg += 0.4
		"feral":
			p.fam_rate *= 1.25
		"carrion":
			p.carrion += 0.1
		"hive":
			p.orbitals += 1
			p.familiars += 1
		"legion":
			p.legion = true
		_:
			push_error("Traits.apply: unknown trait " + id)

## Family bonus tier i (0..2) of a family.
static func apply_bonus(fam: String, i: int, p: Player) -> void:
	match fam + str(i):
		"pyre0":
			p.burn += 0.1
		"pyre1":
			p.burn_dmg += 0.5
		"pyre2":
			p.vs_burn += 0.25
		"frost0":
			p.chill += 0.1
		"frost1":
			p.vs_chill += 0.15
		"frost2":
			p.chill_spread = true
		"venom0":
			p.poison += 1
		"venom1":
			p.poison_fast = true
		"venom2":
			p.poison_dmg += 0.6
		"storm0":
			p.chain += 0.1
		"storm1":
			p.storm_dmg += 0.5
		"storm2":
			p.storm += 0.08
		"blood0":
			p.crit += 0.05
		"blood1":
			p.crit_mult += 0.5
		"blood2":
			p.crit_pierce = true
		"bulwark0":
			p.thorns += 10
		"bulwark1":
			p.armor_regen += 1
		"bulwark2":
			p.evade += 0.2
		"shadow0":
			p.dodge_cd *= 0.85
		"shadow1":
			p.shadowstep = true
		"shadow2":
			p.post_roll = true
		"arcane0":
			p.orbitals += 1
		"arcane1":
			p.homing += 2.0
		"arcane2":
			p.count += 1
		"fortune0":
			p.gold_mult *= 1.1
		"fortune1":
			p.luck += 1
		"fortune2":
			p.dmg *= 1.25
		"demolition0":
			p.bomb_mult *= 1.25
		"demolition1":
			p.shrapnel += 0.1
		"demolition2":
			p.boom_elite = true
		"swarm0":
			p.familiars += 1
		"swarm1":
			p.fam_dmg += 0.5
		"swarm2":
			p.fam_multi = 2
		_:
			push_error("Traits.apply_bonus: unknown bonus %s %d" % [fam, i])

## Skill-tree node effect, keyed by node name.
static func apply_node(name: String, p: Player) -> void:
	match name:
		"SHARPENED":
			p.dmg *= 1.1
		"QUICK HANDS":
			p.rate *= 1.1
		"TRAINED EYE":
			p.crit += 0.08
		"HEIRLOOM":
			p.start_rare = true
		"HARDY":
			p.max_hp += 2
			p.hp += 2
		"PADDED":
			p.armor += 1
		"NIMBLE":
			p.dodge_charges += 1
			p.charges += 1
		"SECOND WIND":
			p.revive += 1
		"CURVING HEX":
			p.homing += 0.8
		"MALEDICT":
			p.curse += 0.2
		"PIERCING HEX":
			p.pierce += 1
		"HEX BLOOM":
			p.bloom = true
		"LONG SHOT":
			p.shot_speed *= 1.1
			p.life *= 1.1
		"HEAVY BOLT":
			p.heavy_n = 6
		"SLICK RELOAD":
			p.roll_reload = true
		"VOLLEY":
			p.count += 2
		"THICK HIDE":
			p.max_hp += 4
			p.hp += 4
		"CONCUSS":
			p.stun += 0.2
		"FRESH BLOOD":
			p.full_hp_dmg += 0.25
		"BLOOD RAGE":
			p.blood_rage = true
		"FISTFUL":
			p.count += 1
		"SPARE POWDER":
			p.sapper += 1
		"BURY":
			p.stun += 0.15
		"GRAVE HARVEST":
			p.harvest = true
		"POTENT BREW":
			p.poison += 1
		"WIDE SPLASH":
			p.splash += 0.4
		"ELIXIR":
			p.potion_heal += 2
			p.elixir = true
		"VOLATILE MIX":
			p.volatile = true
		"BRIGHT FLAME":
			p.size *= 1.2
		"KINDLED":
			p.burn += 0.35
		"HOMEWARD":
			p.back_dmg = true
		"TWIN FLAME":
			p.count += 1
			p.spread = 0.35
		_:
			push_error("Traits.apply_node: unknown node " + name)
