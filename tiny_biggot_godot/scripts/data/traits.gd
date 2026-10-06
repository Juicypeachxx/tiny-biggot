class_name Traits
extends RefCounted
## Level-up traits, build families and hero skill trees (01b_traits.rb, extended
## by the content batches). Each trait pick applies its effects once; picking
## it again stacks another rank. Rows are
## [id, family, max rank, name, desc, capstone, effects, rarity, tags, tier_effects].
## The original 72 traits (no rarity column) were converted mechanically from
## their Ruby lambdas and are checked against the Ruby by tests/effects_test.gd.

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
	# New archetype families (design spec section 4).
	"edge": { "name": "EDGE", "col": "white", "hex": "#f4ecd8" },
	"fury": { "name": "FURY", "col": "red", "hex": "#e8573a" },
	"malice": { "name": "MALICE", "col": "purple", "hex": "#7a3a8c" },
}

## The 12 build archetypes of the design spec and the family that carries each.
## Nine reuse an original family; crit, berserk and curse are new.
const ARCHETYPES := [
	{ "name": "CRIT", "fam": "edge" }, { "name": "BLEED / BLOOD", "fam": "blood" }, { "name": "FIRE", "fam": "pyre" },
	{ "name": "POISON", "fam": "venom" }, { "name": "LIGHTNING", "fam": "storm" }, { "name": "PROJECTILE STORM", "fam": "arcane" },
	{ "name": "SUMMONER", "fam": "swarm" }, { "name": "ROLL / EVASION", "fam": "shadow" }, { "name": "TANK / THORNS", "fam": "bulwark" },
	{ "name": "BERSERK", "fam": "fury" }, { "name": "GREED", "fam": "fortune" }, { "name": "CURSE", "fam": "malice" },
]

## Family bonuses unlock at 2, 4 and 6 total ranks in that family: [name, effects].
## The first eleven are the originals (converted from Ruby); edge, fury and
## malice are new.
const FAMILY_BONUS := {
	"pyre": [["+10% BURN CHANCE", [["add", "burn", 0.1]]], ["BURNS DEAL +50% DAMAGE", [["add", "burn_dmg", 0.5]]], ["BURNING FOES TAKE +25% DAMAGE", [["add", "vs_burn", 0.25]]]],
	"frost": [["+10% CHILL CHANCE", [["add", "chill", 0.1]]], ["CHILLED FOES TAKE +15% DAMAGE", [["add", "vs_chill", 0.15]]], ["KILLS CHILL NEARBY FOES", [["set", "chill_spread", true]]]],
	"venom": [["+1 POISON ON HIT", [["add", "poison", 1]]], ["POISON TICKS TWICE AS FAST", [["set", "poison_fast", true]]], ["POISON DAMAGE +60%", [["add", "poison_dmg", 0.6]]]],
	"storm": [["+10% CHAIN CHANCE", [["add", "chain", 0.1]]], ["LIGHTNING DEALS +50% DAMAGE", [["add", "storm_dmg", 0.5]]], ["HITS HAVE 8% CHANCE TO CALL LIGHTNING", [["add", "storm", 0.08]]]],
	"blood": [["+5% CRIT CHANCE", [["add", "crit", 0.05]]], ["CRITS DEAL +0.5X MORE", [["add", "crit_mult", 0.5]]], ["CRITS PIERCE THROUGH FOES", [["set", "crit_pierce", true]]]],
	"bulwark": [["+10 THORN DAMAGE", [["add", "thorns", 10]]], ["+1 ARMOR AFTER EACH ROOM", [["add", "armor_regen", 1]]], ["20% CHANCE TO IGNORE A HIT", [["add", "evade", 0.2]]]],
	"shadow": [["ROLL RECHARGES 15% FASTER", [["mul", "dodge_cd", 0.85]]], ["ROLLING THROUGH FOES DAMAGES THEM", [["set", "shadowstep", true]]], ["+50% DAMAGE FOR 1S AFTER A ROLL", [["set", "post_roll", true]]]],
	"arcane": [["+1 ORBITING MOON", [["add", "orbitals", 1]]], ["SHOTS HOME IN", [["add", "homing", 2.0]]], ["+1 PROJECTILE", [["add", "count", 1]]]],
	"fortune": [["+10% GOLD", [["mul", "gold_mult", 1.1]]], ["BETTER RELIC RARITY", [["add", "luck", 1]]], ["+25% DAMAGE", [["mul", "dmg", 1.25]]]],
	"demolition": [["BOMBS +25% DAMAGE", [["mul", "bomb_mult", 1.25]]], ["10% OF SHOTS EXPLODE", [["add", "shrapnel", 0.1]]], ["EXPLOSIONS DEAL DOUBLE TO ELITES", [["set", "boom_elite", true]]]],
	"swarm": [["+1 WISP", [["add", "familiars", 1]]], ["WISPS DEAL +50% DAMAGE", [["add", "fam_dmg", 0.5]]], ["WISPS FIRE TWO SHOTS", [["set", "fam_multi", 2]]]],
	"edge": [["+8% CRIT CHANCE", [["add", "crit", 0.08]]],
		["CRITS DEAL +0.5X MORE", [["add", "crit_mult", 0.5]]],
		["CRIT CHANCE PAST 100% CAN CRIT AGAIN", [["add", "overcrit", 0.5]]]],
	"fury": [["+15% DAMAGE BELOW HALF HEALTH", [{ "on": "while_low_hp", "do": [["buff", "dmg", 0.15, 0]] }]],
		["KILLS GIVE +30% FIRE RATE FOR 1.5S", [{ "on": "on_kill", "do": [["buff", "rate", 0.3, 1.5]] }]],
		["TAKING DAMAGE: +40% DAMAGE FOR 4S", [{ "on": "on_damage_taken", "do": [["buff", "dmg", 0.4, 4.0]] }]]],
	"malice": [["20% OF HITS CURSE FOES", [{ "on": "on_hit", "chance": 0.2, "do": [["status", "curse", 1]] }]],
		["HITS ON CURSED FOES MAKE THEM VULNERABLE", [{ "on": "on_hit", "if": "cursed", "do": [["status", "vulnerable", 1]] }]],
		["KILLING A CURSED FOE MAY HEAL", [{ "on": "on_kill", "if": "cursed", "chance": 0.1, "do": [["heal", 1]] }]]],
}

## Trait rarities (design spec section 4). The original traits have no rarity
## column: they show as COMMON, and their capstones as LEGENDARY. Their offer
## weights keep the original formula (G.trait_weight).
const RARITY := {
	"common": { "name": "COMMON", "col": "grey", "hex": "#8b8f9c", "w": 4 },
	"uncommon": { "name": "UNCOMMON", "col": "green", "hex": "#63b84f", "w": 3 },
	"rare": { "name": "RARE", "col": "cyan", "hex": "#4d9be6", "w": 2 },
	"legend": { "name": "LEGENDARY", "col": "gold", "hex": "#f2c94c", "w": 1 },
	"cursed": { "name": "CURSED", "col": "purple", "hex": "#a35bd6", "w": 1 },
	"super": { "name": "SUPER", "col": "pink", "hex": "#e86fb4", "w": 1 },   # 8.4: big, run-shaping picks
}
## 8.4: a SUPER trait that counts as more ranks of a family (its bonuses come with them).
const PLUS := { "x_titan": ["bulwark", 3], "x_quick": ["shadow", 3], "x_genius": ["arcane", 3] }

const ORIGINAL_COUNT := 72
const ROWS := [
	["vitality", "core", 3, "VITALITY", "+1 MAX HEART, HEAL 1 HEART", false, [["add", "max_hp", 2], ["add_cap", "hp", 2, "max_hp"]]],
	["might", "core", 5, "MIGHT", "+12% DAMAGE", false, [["mul", "dmg", 1.12]]],
	["haste", "core", 5, "HASTE", "+10% FIRE RATE", false, [["mul", "rate", 1.1]]],
	["swiftness", "core", 3, "SWIFTNESS", "+8% MOVE SPEED", false, [["mul", "speed", 1.08]]],
	["reach", "core", 3, "REACH", "+15% RANGE AND SHOT SPEED", false, [["mul", "life", 1.15], ["mul", "shot_speed", 1.15]]],
	["precision", "core", 4, "PRECISION", "+6% CRIT CHANCE", false, [["add", "crit", 0.06]]],
	["kindling", "pyre", 3, "KINDLING", "+15% CHANCE TO BURN", false, [["add", "burn", 0.15]]],
	["searing", "pyre", 3, "SEARING", "BURNS DEAL +40% DAMAGE", false, [["add", "burn_dmg", 0.4]]],
	["wildfire", "pyre", 2, "WILDFIRE", "BURNS LAST LONGER AND LEAP TO NEARBY FOES", false, [["add", "burn_time", 1.0], ["add", "burn_leap", 0.2]]],
	["smoulder", "pyre", 3, "SMOULDER", "+10% DAMAGE TO BURNING FOES", false, [["add", "vs_burn", 0.1]]],
	["flametrail", "pyre", 2, "FLAME TRAIL", "ROLLING LEAVES A TRAIL OF FIRE", false, [["add", "fire_trail", 1]]],
	["inferno", "pyre", 1, "INFERNO", "BURNING FOES EXPLODE ON DEATH AND SET OTHERS ABLAZE", true, [["set", "inferno", true]]],
	["chillbite", "frost", 3, "CHILLBITE", "+15% CHANCE TO CHILL", false, [["add", "chill", 0.15]]],
	["deepcold", "frost", 2, "DEEP COLD", "CHILL LASTS LONGER AND SLOWS MORE", false, [["add", "chill_time", 1.0], ["add_floor", "chill_slow", -0.12, 0.2]]],
	["frostbite", "frost", 3, "FROSTBITE", "+12% DAMAGE TO CHILLED FOES", false, [["add", "vs_chill", 0.12]]],
	["icearmor", "frost", 1, "ICE ARMOR", "TAKING A HIT CHILLS EVERY FOE NEARBY", false, [["set", "ice_armor", true]]],
	["glacial", "frost", 2, "GLACIAL LANCE", "EVERY 5TH SHOT IS A PIERCING ICE LANCE", false, [["nth", "lance_n", 5, -1, 3]]],
	["shatter", "frost", 1, "SHATTER", "CHILLED FOES BELOW 30% HEALTH SHATTER INTO ICE", true, [["set", "shatter", true]]],
	["toxin", "venom", 3, "TOXIN", "HITS ADD +1 POISON", false, [["add", "poison", 1]]],
	["virulence", "venom", 3, "VIRULENCE", "POISON DEALS +35% DAMAGE", false, [["add", "poison_dmg", 0.35]]],
	["corrode", "venom", 2, "CORRODE", "POISONED FOES TAKE +3% DAMAGE PER STACK", false, [["add", "corrode", 0.03]]],
	["toxiccloud", "venom", 2, "NOXIOUS CLOUD", "KILLS LEAVE A POISON CLOUD", false, [["add", "cloud", 1]]],
	["barbs", "venom", 2, "BARBS", "20% CHANCE TO FIRE AN EXTRA POISON DART", false, [["add", "barbs", 0.2]]],
	["plague", "venom", 1, "PLAGUE", "POISON SPREADS WITH ALL ITS STACKS WHEN A FOE DIES", true, [["set", "plague", true]]],
	["static", "storm", 3, "STATIC", "+12% CHANCE FOR HITS TO ARC", false, [["add", "chain", 0.12]]],
	["conductor", "storm", 2, "CONDUCTOR", "ARCS JUMP TO 1 MORE FOE", false, [["add", "chain_jumps", 1]]],
	["overload", "storm", 3, "OVERLOAD", "ARCS AND LIGHTNING DEAL +40% DAMAGE", false, [["add", "storm_dmg", 0.4]]],
	["thunderclap", "storm", 2, "THUNDERCLAP", "EVERY 8TH SHOT CALLS LIGHTNING", false, [["nth", "thunder_n", 8, -3, 5]]],
	["livewire", "storm", 2, "LIVE WIRE", "+10% FIRE RATE, +5% MOVE SPEED", false, [["mul", "rate", 1.1], ["mul", "speed", 1.05]]],
	["tempest", "storm", 1, "TEMPEST", "EVERY 3 SECONDS, LIGHTNING STRIKES 3 FOES", true, [["set", "tempest", true]]],
	["keenedge", "blood", 3, "KEEN EDGE", "+7% CRIT CHANCE", false, [["add", "crit", 0.07]]],
	["carnage", "blood", 3, "CARNAGE", "CRITS DEAL +0.35X MORE", false, [["add", "crit_mult", 0.35]]],
	["vampiric", "blood", 2, "VAMPIRIC", "CRITS HAVE 4% CHANCE TO HEAL", false, [["add", "crit_heal", 0.04]]],
	["desperation", "blood", 2, "DESPERATION", "+10% DAMAGE FOR EACH MISSING HEART", false, [["add", "desperate", 0.1]]],
	["lacerate", "blood", 2, "LACERATE", "CRITS MAKE FOES BLEED", false, [["add", "bleed", 1]]],
	["sanguine", "blood", 1, "SANGUINE FRENZY", "EACH KILL GIVES +4% DAMAGE UNTIL THE ROOM ENDS", true, [["set", "sanguine", true]]],
	["plating", "bulwark", 3, "PLATING", "+1 ARMOR", false, [["add", "armor", 1]]],
	["spikes", "bulwark", 3, "SPIKED HIDE", "+10 THORN DAMAGE", false, [["add", "thorns", 10]]],
	["ironskin", "bulwark", 1, "IRON SKIN", "START EACH ROOM WITH AT LEAST 1 ARMOR", false, [["set", "ironskin", true]]],
	["shieldbash", "bulwark", 2, "SHIELD BASH", "ROLLING INTO FOES HITS HARDER WITH MORE ARMOR", false, [["add", "bash", 1], ["set", "shadowstep", true]]],
	["fortress", "bulwark", 2, "FORTRESS", "+8% DAMAGE PER ARMOR (UP TO 5)", false, [["add", "fortress", 0.08]]],
	["unbreakable", "bulwark", 1, "UNBREAKABLE", "WHEN ARMOR BREAKS, RELEASE A NOVA AND ERASE NEARBY SHOTS", true, [["set", "unbreakable", true]]],
	["fleet", "shadow", 2, "FLEET", "+1 ROLL CHARGE", false, [["add", "dodge_charges", 1], ["add", "charges", 1]]],
	["ambush", "shadow", 3, "AMBUSH", "AFTER A ROLL, YOUR NEXT SHOTS CRIT", false, [["add", "ambush", 2]]],
	["phantom", "shadow", 2, "PHANTOM", "ROLLS GO FURTHER AND KEEP YOU SAFE LONGER", false, [["mul", "roll_speed", 1.15], ["add", "roll_time", 0.06]]],
	["evasion", "shadow", 3, "EVASION", "8% CHANCE TO DODGE A HIT", false, [["add", "evade", 0.08]]],
	["smoke", "shadow", 1, "SMOKE BOMB", "ROLLING LEAVES SMOKE THAT ERASES SHOTS", false, [["set", "smoke", true]]],
	["nightfall", "shadow", 1, "NIGHTFALL", "ROLL STRIKES DEAL HEAVY DAMAGE AND KILLS REFUND THE ROLL", true, [["set", "nightfall", true], ["set", "shadowstep", true]]],
	["multicast", "arcane", 2, "MULTICAST", "+1 PROJECTILE, -10% DAMAGE", false, [["add", "count", 1], ["mul", "dmg", 0.9]]],
	["seeking", "arcane", 2, "SEEKING", "SHOTS HOME IN", false, [["add", "homing", 2.0]]],
	["orbit", "arcane", 2, "ORBIT", "+1 ORBITING MOON", false, [["add", "orbitals", 1]]],
	["spellweave", "arcane", 3, "SPELLWEAVE", "+15% SHOT SIZE AND DAMAGE", false, [["mul", "size", 1.15], ["mul", "dmg", 1.15]]],
	["rebound", "arcane", 2, "REBOUND", "SHOTS BOUNCE OFF WALLS", false, [["add", "bounce", 1]]],
	["echo", "arcane", 1, "ARCANE ECHO", "30% CHANCE FOR EVERY SHOT TO CAST AGAIN", true, [["add", "echo", 0.3]]],
	["prospector", "fortune", 3, "PROSPECTOR", "+20% GOLD", false, [["mul", "gold_mult", 1.2]]],
	["haggler", "fortune", 3, "HAGGLER", "SHOPS 10% CHEAPER", false, [["add_cap", "shop_disc", 0.1, 0.6]]],
	["luckyfind", "fortune", 3, "LUCKY FIND", "BETTER RELIC RARITY", false, [["add", "luck", 1]]],
	["interest", "fortune", 2, "INTEREST", "GAIN 8% OF YOUR GOLD AFTER EACH ROOM", false, [["add", "interest", 0.08]]],
	["jackpot", "fortune", 1, "JACKPOT", "ELITES AND GUARDIANS SHOWER GEMS", false, [["set", "jackpot", true]]],
	["midas", "fortune", 1, "MIDAS TOUCH", "+1% DAMAGE FOR EVERY 5 GOLD HELD", true, [["set", "midas", true]]],
	["satchel", "demolition", 3, "SATCHEL", "+2 BOMBS", false, [["add", "bombs", 2]]],
	["blastradius", "demolition", 3, "BLAST RADIUS", "BOMBS +30% RADIUS AND DAMAGE", false, [["mul", "bomb_mult", 1.3], ["mul", "bomb_r", 1.15]]],
	["shrapnel", "demolition", 3, "SHRAPNEL", "12% OF SHOTS EXPLODE ON HIT", false, [["add", "shrapnel", 0.12]]],
	["sapper", "demolition", 1, "SAPPER", "GAIN 1 BOMB AFTER EACH ROOM", false, [["add", "sapper", 1]]],
	["fusemaster", "demolition", 1, "FUSE MASTER", "YOUR BOMBS NO LONGER HURT YOU AND BLOW FASTER", false, [["set", "fuse", true]]],
	["cluster", "demolition", 1, "CLUSTER CHARGE", "BOMBS BURST INTO 4 MORE BOMBS", true, [["set", "cluster", true]]],
	["wispcall", "swarm", 3, "WISP CALL", "+1 WISP FOLLOWS YOU", false, [["add", "familiars", 1]]],
	["packtactics", "swarm", 3, "PACK TACTICS", "WISPS DEAL +40% DAMAGE", false, [["add", "fam_dmg", 0.4]]],
	["feral", "swarm", 2, "FERAL", "WISPS SHOOT 25% FASTER", false, [["mul", "fam_rate", 1.25]]],
	["carrion", "swarm", 2, "CARRION", "KILLS HAVE 10% CHANCE TO RAISE A SPIRIT", false, [["add", "carrion", 0.1]]],
	["hive", "swarm", 1, "HIVE", "+1 ORBITING MOON AND +1 WISP", false, [["add", "orbitals", 1], ["add", "familiars", 1]]],
	["legion", "swarm", 1, "LEGION", "EVERY 5 KILLS SUMMON A TEMPORARY WISP", true, [["set", "legion", true]]],

	# ---------- Content batch 1 (Tiny Biggot Rogues) ----------
	["e_steady", "edge", 4, "STEADY AIM", "+5% CRIT CHANCE", false, [["add", "crit", 0.05]], "common", ["edge"], {  }],
	["e_deep", "edge", 3, "DEEP CUTS", "CRITS DEAL +0.3X MORE. RANK 3: +0.5X MORE", false, [["add", "crit_mult", 0.3]], "common", ["edge"], { 3: [["add", "crit_mult", 0.5]] }],
	["e_momentum", "edge", 3, "MOMENTUM", "CRITS GIVE +10% FIRE RATE FOR 1S", false, [{ "on": "on_crit", "do": [["buff", "rate", 0.1, 1.0]] }], "uncommon", ["edge"], {  }],
	["e_exploit", "edge", 2, "EXPLOIT", "CRITS MAKE FOES VULNERABLE 30% OF THE TIME", false, [{ "on": "on_crit", "chance": 0.3, "do": [["status", "vulnerable", 1]] }], "uncommon", ["edge"], {  }],
	["e_cascade", "edge", 2, "CRIT CASCADE", "CRITS HAVE 25% CHANCE TO ARC TO A NEARBY FOE", false, [{ "on": "on_crit", "chance": 0.25, "do": [["chain", 0.5]] }], "rare", ["edge", "storm"], {  }],
	["e_precise", "edge", 3, "PRECISE FOOTWORK", "+3% CRIT. ROLLING GIVES +10% CRIT FOR 2S", false, [["add", "crit", 0.03], { "on": "on_roll", "do": [["buff", "crit", 0.1, 2.0]] }], "uncommon", ["edge", "shadow"], {  }],
	["e_overcrit", "edge", 1, "OVERCRIT", "CRIT CHANCE PAST 100% CRITS AGAIN FOR DOUBLE", false, [["add", "overcrit", 1.0], ["add", "crit", 0.1]], "legend", ["edge"], {  }],
	["e_glass", "edge", 1, "GLASS EDGE", "+25% CRIT, CRITS +1X. -1 MAX HEART", false, [["add", "crit", 0.25], ["add", "crit_mult", 1.0], ["add_floor", "max_hp", -2, 2], ["clamp_max", "hp", "max_hp"]], "cursed", ["edge", "malice"], {  }],
	["f_anger", "fury", 4, "SHORT TEMPER", "WHEN HIT, +20% DAMAGE FOR 3S", false, [{ "on": "on_damage_taken", "do": [["buff", "dmg", 0.2, 3.0]] }], "common", ["fury"], {  }],
	["f_bloodlust", "fury", 3, "BLOODLUST", "KILLS GIVE +10% FIRE RATE FOR 2S", false, [{ "on": "on_kill", "do": [["buff", "rate", 0.1, 2.0]] }], "common", ["fury"], {  }],
	["f_desperate", "fury", 3, "BACK TO THE WALL", "+10% DAMAGE FOR EACH MISSING HEART", false, [["add", "desperate", 0.1]], "uncommon", ["fury", "blood"], {  }],
	["f_berserk", "fury", 3, "BERSERK", "BELOW HALF HEALTH: +20% DAMAGE AND +10% SPEED", false, [{ "on": "while_low_hp", "do": [["buff", "dmg", 0.2, 0], ["buff", "speed", 0.1, 0]] }], "uncommon", ["fury"], {  }],
	["f_thickskull", "fury", 2, "THICK SKULL", "+1 MAX HEART, +8% DAMAGE", false, [["add", "max_hp", 2], ["add_cap", "hp", 2, "max_hp"], ["mul", "dmg", 1.08]], "common", ["fury", "bulwark"], {  }],
	["f_rampage", "fury", 2, "RAMPAGE", "KILLS HAVE 15% CHANCE TO REFUND A ROLL", false, [{ "on": "on_kill", "chance": 0.15, "do": [["refund_roll"]] }], "rare", ["fury", "shadow"], {  }],
	["f_unstoppable", "fury", 1, "UNSTOPPABLE", "BELOW HALF HEALTH, KILLS HEAL 10% OF THE TIME", false, [{ "on": "on_kill", "chance": 0.1, "if": "low_hp", "do": [["heal", 1]] }], "legend", ["fury"], {  }],
	["f_frenzied", "fury", 1, "BLIND FRENZY", "+40% FIRE RATE. -20% SHOT SPEED", false, [["mul", "rate", 1.4], ["mul", "shot_speed", 0.8]], "cursed", ["fury", "malice"], {  }],
	["m_hex", "malice", 4, "LINGERING HEX", "10% OF HITS CURSE FOES", false, [{ "on": "on_hit", "chance": 0.1, "do": [["status", "curse", 1]] }], "common", ["malice"], {  }],
	["m_spite", "malice", 3, "SPITE", "HITS ON CURSED FOES DEAL A 20% BONUS HIT", false, [{ "on": "on_hit", "cd": 0.05, "if": "cursed", "do": [["damage", 0.2]] }], "uncommon", ["malice"], {  }],
	["m_doom", "malice", 2, "DOOM", "CURSED FOES THAT DIE EXPLODE", false, [{ "on": "on_kill", "if": "cursed", "do": [["explode", 26, 0.6]] }], "rare", ["malice", "pyre"], {  }],
	["m_bargain", "malice", 3, "DARK BARGAIN", "+20% DAMAGE. EACH ROOM COSTS HALF A HEART", false, [["mul", "dmg", 1.2], { "on": "on_room_enter", "do": [["hurt_self", 1]] }], "cursed", ["malice"], {  }],
	["m_hunger", "malice", 2, "SOUL HUNGER", "KILLING A CURSED FOE GIVES +20% DAMAGE FOR 3S", false, [{ "on": "on_kill", "if": "cursed", "do": [["buff", "dmg", 0.2, 3.0]] }], "uncommon", ["malice", "fury"], {  }],
	["m_blight", "malice", 2, "BLIGHTED TOUCH", "CURSED FOES ARE ALSO POISONED", false, [{ "on": "on_hit", "if": "cursed", "do": [["status", "poison", 1]] }], "common", ["malice", "venom"], {  }],
	["m_martyr", "malice", 1, "MARTYR", "-1 MAX HEART. WHEN HIT, EVERY FOE NEARBY IS CURSED AND VULNERABLE... THE NEAREST", false, [["add_floor", "max_hp", -2, 2], ["clamp_max", "hp", "max_hp"], { "on": "on_damage_taken", "do": [["status", "curse", 2], ["status", "vulnerable", 2], ["nova", 12, 1.0, "spark"]] }], "cursed", ["malice"], {  }],
	["m_pact", "malice", 1, "INFERNAL PACT", "+80% DAMAGE. HEALING IS HALVED... POTIONS HEAL 1 LESS", false, [["mul", "dmg", 1.8], ["add_floor", "potion_heal", -2, 1]], "legend", ["malice"], {  }],
	["b_haemo", "blood", 3, "HAEMORRHAGE", "15% OF HITS MAKE FOES BLEED", false, [{ "on": "on_hit", "chance": 0.15, "do": [["status", "bleed", 1]] }], "common", ["blood"], {  }],
	["b_transfuse", "blood", 2, "TRANSFUSION", "KILLING A BLEEDING FOE MAY HEAL", false, [{ "on": "on_kill", "chance": 0.06, "if": "bleeding", "do": [["heal", 1]] }], "uncommon", ["blood"], {  }],
	["b_offering", "blood", 2, "BLOOD OFFERING", "EACH ROOM COSTS HALF A HEART FOR +40% DAMAGE FOR 10S", false, [{ "on": "on_room_enter", "do": [["hurt_self", 1], ["buff", "dmg", 0.4, 10.0]] }], "rare", ["blood", "malice"], {  }],
	["b_vein", "blood", 1, "OPEN VEINS", "BLEEDING FOES TAKE A 30% BONUS HIT FROM CRITS", false, [{ "on": "on_crit", "if": "bleeding", "do": [["damage", 0.3]] }], "legend", ["blood", "edge"], {  }],
	["p_tinder", "pyre", 3, "TINDER", "+8% BURN CHANCE", false, [["add", "burn", 0.08]], "common", ["pyre"], {  }],
	["p_ignite", "pyre", 2, "IGNITION", "KILLS ON BURNING FOES EXPLODE", false, [{ "on": "on_kill", "if": "burning", "do": [["explode", 22, 0.5]] }], "uncommon", ["pyre"], {  }],
	["p_ember", "pyre", 2, "EMBERSTORM", "EVERY 3 SECONDS, A BURST OF FIRE AROUND YOU", false, [{ "on": "every_n_seconds", "period": 3.0, "do": [["nova", 8, 0.5, "fire"]] }], "rare", ["pyre"], {  }],
	["p_wildfire", "pyre", 1, "FIRESTORM", "CRITS SET FOES ABLAZE AND BLAST THEM", false, [{ "on": "on_crit", "do": [["status", "burn", 1], ["explode", 20, 0.4]] }], "legend", ["pyre", "edge"], {  }],
	["v_sting", "venom", 3, "STINGER", "10% OF HITS ADD 2 EXTRA POISON", false, [{ "on": "on_hit", "chance": 0.1, "do": [["status", "poison", 2]] }], "common", ["venom"], {  }],
	["v_spread", "venom", 2, "PESTILENCE", "POISONED FOES THAT DIE INFECT THE NEAREST", false, [{ "on": "on_kill", "if": "poisoned", "do": [["status", "poison", 3]] }], "uncommon", ["venom"], {  }],
	["v_frail", "venom", 2, "FRAILTY", "HITS ON POISONED FOES WEAKEN THEM 10% OF THE TIME", false, [{ "on": "on_hit", "chance": 0.1, "if": "poisoned", "do": [["status", "weakened", 1]] }], "uncommon", ["venom"], {  }],
	["v_toxic", "venom", 1, "TOXIC BLOOM", "EVERY 4 SECONDS, POISON THE NEAREST FOE HEAVILY", false, [{ "on": "every_n_seconds", "period": 4.0, "do": [["status", "poison", 6]] }], "rare", ["venom"], {  }],
	["s_charge", "storm", 3, "CHARGED", "10% OF HITS SHOCK", false, [{ "on": "on_hit", "chance": 0.1, "do": [["status", "shock", 1]] }], "common", ["storm"], {  }],
	["s_surge", "storm", 2, "SURGE", "KILLING A SHOCKED FOE CALLS LIGHTNING", false, [{ "on": "on_kill", "if": "shocked", "do": [["lightning", 0.8]] }], "uncommon", ["storm"], {  }],
	["s_static", "storm", 2, "STATIC FIELD", "EVERY 6 SECONDS, LIGHTNING STRIKES THE NEAREST FOE", false, [{ "on": "every_n_seconds", "period": 6.0, "do": [["lightning", 1.0]] }], "rare", ["storm"], {  }],
	["s_dynamo", "storm", 1, "DYNAMO", "+25% FIRE RATE. SHOCK STACKS FASTER", false, [["mul", "rate", 1.25], { "on": "on_hit", "chance": 0.15, "do": [["status", "shock", 1]] }], "legend", ["storm"], {  }],
	["a_fork", "arcane", 2, "FORKING", "SHOTS SPLIT ON THEIR FIRST HIT", false, [["hook", "split", 1]], "rare", ["arcane"], {  }],
	["a_ricochet", "arcane", 2, "BANK SHOT", "SHOTS JUMP TO 1 MORE FOE", false, [["add", "ricochet", 1]], "uncommon", ["arcane"], {  }],
	["a_salvo", "arcane", 3, "SALVO", "EVERY 10TH ATTACK FIRES 6 EXTRA SHOTS", false, [{ "on": "every_n_shots", "every": 10, "do": [["shoot", 6, 0.5, "", 0.15]] }], "uncommon", ["arcane"], {  }],
	["a_storm", "arcane", 1, "BULLET STORM", "+2 PROJECTILES. -20% DAMAGE", false, [["add", "count", 2], ["mul", "dmg", 0.8]], "legend", ["arcane"], {  }],
	["w_call", "swarm", 2, "SPIRIT CALL", "10% OF KILLS RAISE A WISP FOR 6S", false, [{ "on": "on_kill", "chance": 0.1, "do": [["summon", 6.0]] }], "common", ["swarm"], {  }],
	["w_guard", "swarm", 2, "GUARDIAN SPIRITS", "WHEN HIT, RAISE A WISP FOR 8S", false, [{ "on": "on_damage_taken", "do": [["summon", 8.0]] }], "uncommon", ["swarm"], {  }],
	["w_choir", "swarm", 3, "CHOIR", "WISPS DEAL +25% DAMAGE AND FIRE 10% FASTER", false, [["add", "fam_dmg", 0.25], ["mul", "fam_rate", 1.1]], "common", ["swarm"], {  }],
	["w_host", "swarm", 1, "THE HOST", "EACH ROOM BEGINS WITH 3 WISPS FOR 10S", false, [{ "on": "on_room_enter", "do": [["summon", 10.0], ["summon", 10.0], ["summon", 10.0]] }], "legend", ["swarm"], {  }],
	["sh_blur", "shadow", 3, "BLUR", "AFTER A ROLL, +20% DAMAGE FOR 1S", false, [{ "on": "on_roll", "do": [["buff", "dmg", 0.2, 1.0]] }], "common", ["shadow"], {  }],
	["sh_knives", "shadow", 2, "SHADOW KNIVES", "ROLLING THROWS 4 KNIVES AROUND YOU", false, [{ "on": "on_roll", "do": [["nova", 4, 0.6, "spark"]] }], "uncommon", ["shadow"], {  }],
	["sh_vanish", "shadow", 2, "VANISH", "ROLLING ERASES NEARBY SHOTS", false, [{ "on": "on_roll", "do": [["clear_shots", 30]] }], "rare", ["shadow"], {  }],
	["sh_dance", "shadow", 1, "DEATH DANCE", "+1 ROLL CHARGE. KILLS HAVE 20% CHANCE TO REFUND A ROLL", false, [["add", "dodge_charges", 1], ["add", "charges", 1], { "on": "on_kill", "chance": 0.2, "do": [["refund_roll"]] }], "legend", ["shadow"], {  }],
	["t_brace", "bulwark", 3, "BRACE", "CLEARING A ROOM GRANTS 1 ARMOR 25% OF THE TIME", false, [{ "on": "on_room_clear", "chance": 0.25, "do": [["armor", 1]] }], "common", ["bulwark"], {  }],
	["t_retort", "bulwark", 2, "RETORT", "WHEN HIT, FIRE 8 SPIKES AROUND YOU", false, [{ "on": "on_damage_taken", "do": [["nova", 8, 0.8, "spark"]] }], "uncommon", ["bulwark"], {  }],
	["t_hulk", "bulwark", 2, "HULKING", "+1 MAX HEART. +10 THORNS", false, [["add", "max_hp", 2], ["add_cap", "hp", 2, "max_hp"], ["add", "thorns", 10]], "common", ["bulwark"], {  }],
	["t_aegis", "bulwark", 1, "LIVING AEGIS", "WHEN HIT, ERASE NEARBY SHOTS AND GAIN +40% DAMAGE FOR 4S", false, [{ "on": "on_damage_taken", "do": [["clear_shots", 70], ["buff", "dmg", 0.4, 4.0]] }], "legend", ["bulwark"], {  }],
	["g_skim", "fortune", 3, "SKIMMING", "KILLS HAVE 10% CHANCE TO PAY 1 GOLD", false, [{ "on": "on_kill", "chance": 0.1, "do": [["gold", 1]] }], "common", ["fortune"], {  }],
	["g_bounty", "fortune", 2, "BOUNTY HUNTER", "KILLING AN ELITE PAYS 10 GOLD", false, [{ "on": "on_kill", "if": "elite", "do": [["gold", 10]] }], "uncommon", ["fortune"], {  }],
	["g_invest", "fortune", 2, "INVESTMENT", "CLEARING A ROOM PAYS 4 GOLD", false, [{ "on": "on_room_clear", "do": [["gold", 4]] }], "uncommon", ["fortune"], {  }],
	# 8.4 (his ask, 6 Oct, from pictures of another game's trait picks: ideas only, names and numbers
	# are this game's own). SUPER traits: big run-shaping picks, offered from level 4.
	["x_titan", "bulwark", 1, "TITAN'S FRAME", "+12 STR. COUNTS AS 3 MORE BULWARK RANKS", false, [["attr", "str", 12]], "super", ["bulwark"], {  }],
	["x_quick", "shadow", 1, "QUICKSILVER", "+12 DEX. COUNTS AS 3 MORE SHADOW RANKS", false, [["attr", "dex", 12]], "super", ["shadow"], {  }],
	["x_genius", "arcane", 1, "GENIUS", "+12 INT. COUNTS AS 3 MORE ARCANE RANKS", false, [["attr", "int", 12]], "super", ["arcane"], {  }],
	["x_faiths", "core", 1, "ALL FAITHS", "+2 GOOD, EVIL, LAWFUL AND CHAOTIC. YOU RISE ONCE MORE FROM DEATH", false, [["add", "al_good", 2], ["add", "al_evil", 2], ["add", "al_law", 2], ["add", "al_chaos", 2], ["add", "revive", 1]], "super", ["fortune"], {  }],
	["x_crown", "fortune", 1, "FOUR-LEAF CROWN", "+4 LUCK. +40% GOLD", false, [["add", "luck", 4], ["mul", "gold_mult", 1.4]], "super", ["fortune"], {  }],
	["x_heart", "bulwark", 1, "BOTTOMLESS HEART", "+3 MAX HEARTS. CLEARING A ROOM HEALS A HEART", false, [["add", "max_hp", 6], ["add_cap", "hp", 6, "max_hp"], { "on": "on_room_clear", "do": [["heal", 2]] }], "super", ["bulwark"], {  }],
	["x_elements", "arcane", 1, "ELEMENTAL STORM", "EVERY 8S BURN, EVERY 4S CHILL, EVERY 2S SHOCK AND EVERY 1S POISON EVERY FOE", false, [{ "on": "every_n_seconds", "period": 8.0, "do": [["status_area", "burn", 1, 999]] }, { "on": "every_n_seconds", "period": 4.0, "do": [["status_area", "chill", 1, 999]] }, { "on": "every_n_seconds", "period": 2.0, "do": [["status_area", "shock", 1, 999]] }, { "on": "every_n_seconds", "period": 1.0, "do": [["status_area", "poison", 1, 999]] }], "super", ["arcane", "storm"], {  }],
	["x_overcharged", "storm", 1, "OVERCHARGED", "ROLLING CALLS 3 LIGHTNING STRIKES (EVERY 2S). EVERY 3S, LIGHTNING STRIKES", false, [{ "on": "on_roll", "cd": 2.0, "do": [["lightning", 1.0], ["lightning", 1.0], ["lightning", 1.0]] }, { "on": "every_n_seconds", "period": 3.0, "do": [["lightning", 1.0]] }], "super", ["storm"], {  }],
	["x_tailwind", "shadow", 1, "TAILWIND", "+40% MOVE SPEED. +15% FIRE RATE", false, [["mul", "speed", 1.4], ["mul", "rate", 1.15]], "super", ["shadow"], {  }],
	# 8.4 rule-benders.
	["f_idle", "core", 1, "IDLE HANDS", "+20% DAMAGE FOR EACH EMPTY GEAR SLOT", false, [["hook", "idle_dmg", 0.2]], "rare", ["fury"], {  }],
	["f_purse", "fortune", 1, "BOTTOMLESS PURSE", "ANYTHING THAT GROWS WITH GOLD COUNTS YOU AS HOLDING 1000 GOLD OR MORE", false, [["hook", "purse", 1]], "rare", ["fortune"], {  }],
	# 8.4 synergy traits: they grow with what you already do.
	["y_momentum", "shadow", 1, "MOMENTUM", "EVERY ROLL: +1% DAMAGE FOR THE REST OF THE RUN (UP TO +60%)", false, [{ "on": "on_roll", "do": [["stack", "dmg", 0.01, 0.6, "momentum"]] }], "uncommon", ["shadow"], {  }],
	["y_veteran", "core", 1, "VETERAN", "EVERY CLEARED ROOM: +1% DAMAGE FOR THE REST OF THE RUN (UP TO +50%)", false, [{ "on": "on_room_clear", "do": [["stack", "dmg", 0.01, 0.5, "veteran"]] }], "uncommon", ["fury"], {  }],
	["y_collector", "fortune", 1, "COLLECTOR", "+2% DAMAGE FOR EVERY STAT PICKUP TAKEN THIS RUN", false, [["hook", "collect_dmg", 0.02]], "rare", ["fortune"], {  }],
	["y_zealot", "core", 1, "ZEALOT", "+5% DAMAGE FOR EACH POINT OF YOUR HIGHEST ALIGNMENT", false, [["hook", "zealot_dmg", 0.05]], "rare", ["fury"], {  }],
	["y_prism", "arcane", 1, "PRISM", "+10% DAMAGE FOR EACH DIFFERENT AILMENT ON THE FOE YOU HIT", false, [["hook", "prism_dmg", 0.1]], "rare", ["arcane"], {  }],
	["g_goldblood", "fortune", 1, "GOLDEN BLOOD", "+1% DAMAGE FOR EVERY 10 GOLD HELD. CRITS PAY 1 GOLD", false, [["set", "miser", true], { "on": "on_crit", "do": [["gold", 1]] }], "legend", ["fortune", "edge"], {  }],
]

const TREE_COSTS := [10, 20, 35, 60]
## [name, desc] per node; effects in NODE_EFFECTS.
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
	# Step 6 heroes: the shared MIGHT and SURVIVAL branches plus their own special branch.
	"banehunter": { "name": "MONSTER LORE", "nodes": [["SILVERED EDGE", "+20% MORE DAMAGE TO ELITES"], ["OIL CRAFT", "+1 POTION SLOT AND A FULL POTION"], ["WARDING SIGN", "SIGNS ALSO ERASE SHOTS AROUND YOU"], ["TROPHY TAKER", "KILLING AN ELITE HEALS HALF A HEART AND GIVES +30% DAMAGE FOR 20S"]] },
	"oathbreaker": { "name": "IRON OATH", "nodes": [["BROAD SWING", "+25% SWING SIZE"], ["BLOODIED", "TAKING A HIT GIVES +40% DAMAGE FOR 4S"], ["UNYIELDING", "+1 ARMOR AFTER EACH ROOM"], ["WRATH UNBOUND", "EVERY 4TH SWING SENDS OUT A SHOCKWAVE FOR 150%"]] },
	"wayfarer": { "name": "WAY OF THE BLADE", "nodes": [["CLEAN CUTS", "CRITS DEAL +0.3X MORE"], ["COUNTERSTROKE", "A PERFECT DODGE STRIKES THE NEAREST FOE FOR 300%"], ["FLOWING STEP", "+1 ROLL CHARGE"], ["WIND SEVERS", "A PERFECT DODGE ERASES SHOTS AROUND YOU AND DOUBLES CRIT CHANCE FOR 2S"]] },
	"racketeer": { "name": "THE RACKET", "nodes": [["PROTECTION MONEY", "CLEARING A ROOM PAYS 3 GOLD"], ["HOT STREAK", "AT 3+ HEAT, KILLS FIRE A RING OF 6 SHOTS"], ["COOL HEAD", "GETTING HIT ONLY LOSES 1 HEAT"], ["MOST WANTED", "HEAT CAN RISE TO 8"]] },
	"condemned": { "name": "ESCAPE ARTIST", "nodes": [["SCROLL HOARD", "READ A SECOND SCROLL ON EVERY FLOOR"], ["GRAVE ARSENAL", "SWAPPING WEAPONS REFUNDS A ROLL AND HEALS HALF A HEART (EVERY 20S)"], ["OLD WOUNDS", "+1 MAX HEART"], ["DEATH'S DOOR", "RISE ONE MORE TIME"]] },
	"cartomancer": { "name": "THE ARCANA", "nodes": [["SLEIGHT OF HAND", "IN A FIGHT, DRAW AN EXTRA CARD EVERY 10S"], ["MARKED CARDS", "THROWN CARDS PIERCE +1"], ["HIGH ROLLER", "CLEARING A ROOM DRAWS A CARD"], ["FULL HOUSE", "EVERY CARD PLAYS TWICE"]] },
	"gaolbird": { "name": "JAILBREAK", "nodes": [["KEEP TIME", "TEMPO HOLDS 2S LONGER BEFORE IT FADES"], ["OLD GRUDGE", "RALLY LASTS 1.5S LONGER AND RETURNS 3S SOONER"], ["HOLLOW BONES", "+1 ROLL CHARGE. KILLS IN FULL FLIGHT REFUND A ROLL"], ["MURDER OF CROWS", "KILLS IN FULL FLIGHT FIRE 8 FEATHERS. HITS COST 2 TEMPO"]] },
	"beekeeper": { "name": "THE HIVE", "nodes": [["ROYAL JELLY", "BEES DEAL +25% MORE"], ["WAX COAT", "EVERY FLOOR STARTS WITH 2 ARMOR"], ["STINGERS", "A POISONED FOE YOU KILL PASSES ITS AILMENTS ON"], ["QUEEN'S CALL", "EVERY 6TH KILL CALLS ANOTHER BEE"]] },
	"tinkerer": { "name": "WORKSHOP", "nodes": [["SPARE PARTS", "ENTERING A ROOM SETS UP A GUN TURRET FOR 10S"], ["ARC WELDER", "EVERY 15TH SHOT ZAPS 2 FOES"], ["REINFORCED", "+1 MAX HEART"], ["GRAND DESIGN", "ROLLING ALSO SETS DOWN A FROST TOTEM (EVERY 8S)"]] },
	"boneweaver": { "name": "OSSUARY ARTS", "nodes": [["GRAVE TOUCH", "+10% CURSE CHANCE"], ["BONE ARMOR", "WHEN HIT, A SKELETON RISES BESIDE YOU"], ["SOUL TITHE", "10% OF KILLS HEAL HALF A HEART"], ["ARMY OF BONE", "EVERY ELITE YOU KILL RISES FOR 20S, TWICE AS STRONG"]] },
	"mirrorknight": { "name": "THE POLISHED OATH", "nodes": [["BRIGHT STEEL", "+1 ARMOR"], ["GLARE", "WHEN ARMOR TAKES A HIT, SHOTS NEAR YOU FLY BACK"], ["SILVERING", "REFLECTED SHOTS ARE 50% STRONGER"], ["HALL OF MIRRORS", "EVERY 6S IN A FIGHT, SHOTS NEAR YOU FLY BACK"]] },
	"plaguesaint": { "name": "THE BLACK LITANY", "nodes": [["MIASMA", "+1 POISON ON HIT"], ["CONTAGION", "10% OF HITS ON POISONED FOES SPREAD THEIR AILMENTS"], ["FEVER DREAM", "+20% DAMAGE TO AFFLICTED FOES"], ["PESTILENCE", "CRITS USE UP EVERY AILMENT ON THE FOE (EVERY 1S)"]] },
	"frostwitch": { "name": "HOARFROST CRAFT", "nodes": [["COLD SNAP", "+15% CHILL CHANCE"], ["THIN ICE", "+25% CRIT CHANCE AGAINST CHILLED FOES"], ["DEEP FREEZE", "A QUARTER OF CRITS ON CHILLED FOES FREEZE THEM SOLID"], ["WHITEOUT", "THE SLOWING EVERY 3S REACHES TWICE AS FAR"]] },
	"demolitionist": { "name": "BLASTING CREW", "nodes": [["BIG BANG", "BOMBS 25% WIDER"], ["SPARE CHARGES", "+3 BOMBS AT THE START OF EVERY FLOOR"], ["SHELL SHOCK", "SETTING A BOMB MAKES YOU UNTOUCHABLE FOR 0.5S"], ["CHAIN REACTION", "BOMBS BURST INTO 4 MORE"]] },
	"executioner": { "name": "THE BLOCK", "nodes": [["HEAVY HAND", "+15% DAMAGE"], ["GRIM TALLY", "KILLS GIVE +4% DAMAGE FOR 8S"], ["LAST SENTENCE", "EVERY HIT ON THE LAST FOE IN A ROOM STRIKES AGAIN"], ["NO APPEAL", "FOES BELOW 20% HEALTH DIE AT ONCE"]] },
	"pilgrim": { "name": "THE LONG ROAD", "nodes": [["WAYBREAD", "+1 MAX HEART"], ["BLESSED WATER", "POTIONS HEAL HALF A HEART MORE"], ["HALO", "EVERY 5S IN A FIGHT, 6 STARS FLY OUT"], ["SAINTHOOD", "RISE ONCE MORE THIS RUN"]] },
	"clockmaker": { "name": "CLOCKWORK", "nodes": [["MAINSPRING", "ENTERING A ROOM: +30% FIRE RATE FOR 6S"], ["ESCAPEMENT", "EVERY 20TH SHOT CHILLS THE FOES NEAR YOU"], ["BALANCE WHEEL", "+1 MAX HEART"], ["GRAND COMPLICATION", "ROLLING SLOWS EVERY FOE SHOT NEAR YOU (EVERY 6S)"]] },
	"beastmaster": { "name": "THE WILD", "nodes": [["SOFT WORDS", "4% MORE OF YOUR HITS TAME A FOE"], ["PACK LEADER", "+1 WISP"], ["FERAL BOND", "KILLS GIVE +20% DAMAGE FOR 3S"], ["ALPHA", "EVERY 10S IN A FIGHT, THE FOES CLOSE TO YOU ARE TAMED FOR 8S"]] },
	"sellsword": { "name": "FREE COMPANY", "nodes": [["SPURS", "ROLLS RECHARGE 20% FASTER"], ["SHIELD WALL", "WHEN HIT, ERASE NEARBY SHOTS (EVERY 6S)"], ["WAR PAY", "KILLING AN ELITE PAYS 12 GOLD"], ["THUNDERING CHARGE", "CHARGES HIT TWICE AS HARD AND KILLS REFUND THE ROLL"]] },
}

const NODE_EFFECTS := {
	# ROADMAP 4.8 hero branches.
	"ROYAL JELLY": [["add", "fam_dmg", 0.25]],
	"WAX COAT": [{"on": "on_floor_start", "do": [["armor", 2]]}],
	"STINGERS": [{"on": "on_kill", "if": "poisoned", "do": [["spread", 60]]}],
	"QUEEN'S CALL": [{"on": "on_kill", "every": 6, "do": [["summon", 20.0]]}],
	"MAINSPRING": [{"on": "on_room_enter", "do": [["buff", "rate", 0.3, 6.0]]}],
	"ESCAPEMENT": [{"on": "every_n_shots", "every": 20, "do": [["status_area", "chill", 2, 110]]}],
	"BALANCE WHEEL": [["add", "max_hp", 2], ["add", "hp", 2]],
	"GRAND COMPLICATION": [{"on": "on_roll", "cd": 6.0, "do": [["slow_shots", 140, 0.4]]}],
	"SPARE PARTS": [{"on": "on_room_enter", "do": [["turret", "gun", 10.0, 1.0]]}],
	"ARC WELDER": [{"on": "every_n_shots", "every": 15, "do": [["bolts", 2, 0.8]]}],
	"REINFORCED": [["add", "max_hp", 2], ["add", "hp", 2]],
	"GRAND DESIGN": [{"on": "on_roll", "cd": 8.0, "do": [["turret", "frost", 8.0, 1.0]]}],
	"GRAVE TOUCH": [["add", "curse", 0.1]],
	"BONE ARMOR": [{"on": "on_damage_taken", "do": [["raise", 10.0, 0.9]]}],
	"SOUL TITHE": [{"on": "on_kill", "chance": 0.1, "do": [["heal", 1]]}],
	"ARMY OF BONE": [{"on": "on_kill", "if": "elite", "do": [["raise", 20.0, 1.8]]}],
	"BRIGHT STEEL": [["add", "armor", 1]],
	"GLARE": [{"on": "on_armor_lost", "do": [["reflect", 80, 1.0]]}],
	"SILVERING": [{"on": "on_roll", "cd": 1.0, "do": [["reflect", 55, 0.5]]}],
	"HALL OF MIRRORS": [{"on": "every_n_seconds", "period": 6.0, "if": "fighting", "do": [["reflect", 70, 1.0]]}],
	"MIASMA": [["add", "poison", 1]],
	"CONTAGION": [{"on": "on_hit", "if": "poisoned", "chance": 0.1, "do": [["spread", 50]]}],
	"FEVER DREAM": [["hook", "status_dmg", 0.2]],
	"PESTILENCE": [{"on": "on_crit", "cd": 1.0, "do": [["consume", 0.6]]}],
	"COLD SNAP": [["add", "chill", 0.15]],
	"THIN ICE": [["hook", "chill_crit", 0.25]],
	"DEEP FREEZE": [{"on": "on_crit", "if": "chilled", "chance": 0.25, "do": [["status", "stun", 1]]}],
	"WHITEOUT": [{"on": "every_n_seconds", "period": 3.0, "if": "fighting", "do": [["slow_shots", 140, 0.5]]}],
	"BIG BANG": [["mul", "bomb_r", 1.25]],
	"SPARE CHARGES": [{"on": "on_floor_start", "do": [["give", "bombs", 3]]}],
	"SHELL SHOCK": [{"on": "on_bomb", "do": [["invuln", 0.5]]}],
	"CHAIN REACTION": [["hook", "cluster", 1]],
	"HEAVY HAND": [["pct", "dmg", 0.15]],
	"GRIM TALLY": [{"on": "on_kill", "do": [["buff", "dmg", 0.04, 8.0]]}],
	"LAST SENTENCE": [{"on": "on_hit", "if": "last_foe", "do": [["damage", 1.0]]}],
	"NO APPEAL": [["hook", "execute", 0.1]],
	"WAYBREAD": [["add", "max_hp", 2], ["add", "hp", 2]],
	"BLESSED WATER": [["add", "potion_heal", 1]],
	"HALO": [{"on": "every_n_seconds", "period": 5.0, "if": "fighting", "do": [["nova", 6, 0.7, "spark"]]}],
	"SAINTHOOD": [["add", "revive", 1]],
	"SOFT WORDS": [{"on": "on_hit", "chance": 0.04, "do": [["charm", 8.0]]}],
	"PACK LEADER": [["add", "familiars", 1]],
	"FERAL BOND": [{"on": "on_kill", "do": [["buff", "dmg", 0.2, 3.0]]}],
	"ALPHA": [{"on": "every_n_seconds", "period": 10.0, "if": "fighting", "do": [["charm_area", 50, 8.0]]}],
	# Step 6 hero branches.
	"SILVERED EDGE": [["add", "elite_mult", 0.2]],
	"OIL CRAFT": [["add", "max_potions", 1], ["add", "potions", 1]],
	"WARDING SIGN": [{ "on": "on_roll", "cd": 6.0, "do": [["clear_shots", 50]] }],
	"TROPHY TAKER": [{ "on": "on_kill", "if": "elite", "do": [["heal", 1], ["buff", "dmg", 0.3, 20.0]] }],
	"BROAD SWING": [["mul", "size", 1.25]],
	"BLOODIED": [{ "on": "on_damage_taken", "do": [["buff", "dmg", 0.4, 4.0]] }],
	"UNYIELDING": [["add", "armor_regen", 1]],
	"WRATH UNBOUND": [{ "on": "every_n_shots", "every": 4, "do": [["explode", 40, 1.5]] }],
	"CLEAN CUTS": [["add", "crit_mult", 0.3]],
	"COUNTERSTROKE": [{ "on": "on_roll", "if": "danger", "do": [["damage", 3.0]] }],
	"FLOWING STEP": [["add", "dodge_charges", 1], ["add", "charges", 1]],
	"WIND SEVERS": [{ "on": "on_roll", "if": "danger", "do": [["clear_shots", 60], ["buff", "crit", 1.0, 2.0]] }],
	"PROTECTION MONEY": [{ "on": "on_room_clear", "do": [["gold", 3]] }],
	"HOT STREAK": [{ "on": "on_kill", "if": "hot", "do": [["nova", 6, 0.5, "spark"]] }],
	"COOL HEAD": [{ "on": "on_damage_taken", "do": [["heat", 1]] }],
	"MOST WANTED": [["add", "heat_max", 3]],
	"SCROLL HOARD": [{ "on": "on_floor_start", "do": [["scroll"]] }],
	"GRAVE ARSENAL": [{ "on": "on_weapon_swap", "cd": 20.0, "do": [["refund_roll"], ["heal", 1]] }],
	"OLD WOUNDS": [["add", "max_hp", 2], ["add", "hp", 2]],
	"DEATH'S DOOR": [["add", "revive", 1]],
	"SLEIGHT OF HAND": [{ "on": "every_n_seconds", "period": 10.0, "if": "fighting", "do": [["card"]] }],
	"MARKED CARDS": [["add", "pierce", 1]],
	"HIGH ROLLER": [{ "on": "on_room_clear", "do": [["card"]] }],
	"FULL HOUSE": [["hook", "card_double", 1]],
	"KEEP TIME": [["hook", "tempo_hold", 2.0]],
	"OLD GRUDGE": [["hook", "rally_window", 1.5], ["hook", "rally_haste", 3.0]],
	"HOLLOW BONES": [["add", "dodge_charges", 1], ["add", "charges", 1], { "on": "on_kill", "if": "flight", "do": [["refund_roll"]] }],
	"MURDER OF CROWS": [["hook", "tempo_grit", 1], { "on": "on_kill", "if": "flight", "do": [["nova", 8, 0.6, "feather"]] }],
	"SPURS": [["mul", "dodge_cd", 0.8]],
	"SHIELD WALL": [{ "on": "on_damage_taken", "cd": 6.0, "do": [["clear_shots", 50]] }],
	"WAR PAY": [{ "on": "on_kill", "if": "elite", "do": [["gold", 12]] }],
	"THUNDERING CHARGE": [["set", "nightfall", true]],
	"SHARPENED": [["mul", "dmg", 1.1]],
	"QUICK HANDS": [["mul", "rate", 1.1]],
	"TRAINED EYE": [["add", "crit", 0.08]],
	"HEIRLOOM": [["set", "start_rare", true]],
	"HARDY": [["add", "max_hp", 2], ["add", "hp", 2]],
	"PADDED": [["add", "armor", 1]],
	"NIMBLE": [["add", "dodge_charges", 1], ["add", "charges", 1]],
	"SECOND WIND": [["add", "revive", 1]],
	"CURVING HEX": [["add", "homing", 0.8]],
	"MALEDICT": [["add", "curse", 0.2]],
	"PIERCING HEX": [["add", "pierce", 1]],
	"HEX BLOOM": [["set", "bloom", true]],
	"LONG SHOT": [["mul", "shot_speed", 1.1], ["mul", "life", 1.1]],
	"HEAVY BOLT": [["set", "heavy_n", 6]],
	"SLICK RELOAD": [["set", "roll_reload", true]],
	"VOLLEY": [["add", "count", 2]],
	"THICK HIDE": [["add", "max_hp", 4], ["add", "hp", 4]],
	"CONCUSS": [["add", "stun", 0.2]],
	"FRESH BLOOD": [["add", "full_hp_dmg", 0.25]],
	"BLOOD RAGE": [["set", "blood_rage", true]],
	"FISTFUL": [["add", "count", 1]],
	"SPARE POWDER": [["add", "sapper", 1]],
	"BURY": [["add", "stun", 0.15]],
	"GRAVE HARVEST": [["set", "harvest", true]],
	"POTENT BREW": [["add", "poison", 1]],
	"WIDE SPLASH": [["add", "splash", 0.4]],
	"ELIXIR": [["add", "potion_heal", 2], ["set", "elixir", true]],
	"VOLATILE MIX": [["set", "volatile", true]],
	"BRIGHT FLAME": [["mul", "size", 1.2]],
	"KINDLED": [["add", "burn", 0.35]],
	"HOMEWARD": [["set", "back_dmg", true]],
	"TWIN FLAME": [["add", "count", 1], ["set", "spread", 0.35]],
}

static var _list: Array = []
static var _by_id := {}

static func all() -> Array:
	if _list.is_empty():
		# --classic: original items only (proves the originals play exactly as before).
		for i in (ORIGINAL_COUNT if DebugArgs.has("classic") else ROWS.size()):
			var row: Array = ROWS[i]
			var t := { "id": row[0], "fam": row[1], "max": row[2], "name": row[3], "desc": row[4], "cap": row[5],
				"effects": row[6], "new": i >= ORIGINAL_COUNT,
				"rarity": row[7] if row.size() > 7 else ("legend" if row[5] else "common"),
				"tags": row[8] if row.size() > 8 else [row[1]],
				"tiers": row[9] if row.size() > 9 else {} }
			_list.append(t)
			_by_id[t["id"]] = t
	return _list

static func by_id(id: String) -> Dictionary:
	all()
	return _by_id[id]

static func tree_for(hero_id: String) -> Array:
	return SKILL_BRANCHES + [HERO_BRANCH[hero_id]]

## One rank of a trait. tier_effects (new traits) add extra effects when a
## given rank is reached, e.g. { 3: [...] }.
static func apply(id: String, p: Player) -> void:
	var t := by_id(id)
	Effects.apply(p, t["effects"], 1, "trait:" + id)
	var rank: int = p.traits.get(id, 0)
	if t["tiers"].has(rank):
		Effects.apply(p, t["tiers"][rank], 1, "trait:%s:%d" % [id, rank])

## Family bonus tier i (0..2).
static func apply_bonus(fam: String, i: int, p: Player) -> void:
	Effects.apply(p, FAMILY_BONUS[fam][i][1], 1, "bonus:%s:%d" % [fam, i])

static func bonus_name(fam: String, i: int) -> String:
	return FAMILY_BONUS[fam][i][0]

static func apply_node(name: String, p: Player) -> void:
	Effects.apply(p, NODE_EFFECTS[name], 1, "node:" + name)
