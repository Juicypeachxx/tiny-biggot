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
	"mythic": { "name": "MYTHIC", "col": "red", "hex": "#ff3a4a", "w": 1 },   # 26: the rarest of all, from level 6
	"oath": { "name": "OATH", "col": "orange", "hex": "#ff9b3a", "w": 1 },   # 29: the pick that opens every run
}
## 29 (his word, 9 Oct: "at the start of the game there are only basic traits"): one row of every
## pick of the expanded game is one of these, when one can be offered.
const SPOTLIGHT := ["rare", "legend", "super", "mythic", "cursed"]
## 8.5 (his ask, 6 Oct: "make some common super traits to refresh runs"): these SUPER traits are
## offered often (weight 4) from level 2; the rest stay rare (weight 1) from level 4.
const COMMON_SUPER := ["x_twin", "x_reflex", "x_surge", "x_hoarder", "x_heart", "x_crown", "x_tailwind", "x_legion"]
## 8.4: a SUPER trait that counts as more ranks of a family (its bonuses come with them).
const PLUS := { "x_titan": ["bulwark", 3], "x_quick": ["shadow", 3], "x_genius": ["arcane", 3],
	"sup_reflexes": ["shadow", 6], "sup_smarts": ["arcane", 6], "sup_strength": ["fury", 6] }   # (43.2)

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
	["b_vein", "blood", 1, "OPEN VEINS", "BLEEDING FOES TAKE A 50% BONUS HIT FROM CRITS", false, [{ "on": "on_crit", "if": "bleeding", "do": [["damage", 0.5]] }], "legend", ["blood", "edge"], {  }],
	["p_tinder", "pyre", 3, "TINDER", "+8% BURN CHANCE", false, [["add", "burn", 0.08]], "common", ["pyre"], {  }],
	["p_ignite", "pyre", 2, "IGNITION", "KILLS ON BURNING FOES EXPLODE", false, [{ "on": "on_kill", "if": "burning", "do": [["explode", 22, 0.5]] }], "uncommon", ["pyre"], {  }],
	["p_ember", "pyre", 2, "EMBERSTORM", "EVERY 3 SECONDS, A BURST OF FIRE AROUND YOU", false, [{ "on": "every_n_seconds", "period": 3.0, "do": [["nova", 8, 0.5, "fire"]] }], "rare", ["pyre"], {  }],
	["p_wildfire", "pyre", 1, "FIRESTORM", "CRITS SET FOES ABLAZE AND BLAST THEM", false, [{ "on": "on_crit", "do": [["status", "burn", 1], ["explode", 20, 0.4]] }], "legend", ["pyre", "edge"], {  }],
	["v_sting", "venom", 3, "STINGER", "10% OF HITS ADD 2 EXTRA POISON", false, [{ "on": "on_hit", "chance": 0.1, "do": [["status", "poison", 2]] }], "common", ["venom"], {  }],
	["v_spread", "venom", 2, "PESTILENCE", "POISONED FOES THAT DIE INFECT THE NEAREST", false, [{ "on": "on_kill", "if": "poisoned", "do": [["status", "poison", 3]] }], "uncommon", ["venom"], {  }],
	["v_frail", "venom", 2, "FRAILTY", "HITS ON POISONED FOES WEAKEN THEM 10% OF THE TIME", false, [{ "on": "on_hit", "chance": 0.1, "if": "poisoned", "do": [["status", "weakened", 1]] }], "uncommon", ["venom"], {  }],
	["v_toxic", "venom", 1, "TOXIC BLOOM", "EVERY 3 SECONDS, POISON THE NEAREST FOE HEAVILY AND THE FOES NEAR YOU A LITTLE", false, [{ "on": "every_n_seconds", "period": 3.0, "do": [["status", "poison", 8], ["status_area", "poison", 2, 60]] }], "rare", ["venom"], {  }],
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
	["w_host", "swarm", 1, "THE HOST", "EACH ROOM BEGINS WITH 4 WISPS FOR 12S", false, [{ "on": "on_room_enter", "do": [["summon", 12.0], ["summon", 12.0], ["summon", 12.0], ["summon", 12.0]] }], "legend", ["swarm"], {  }],
	["sh_blur", "shadow", 3, "BLUR", "AFTER A ROLL, +20% DAMAGE FOR 1S", false, [{ "on": "on_roll", "do": [["buff", "dmg", 0.2, 1.0]] }], "common", ["shadow"], {  }],
	["sh_knives", "shadow", 2, "SHADOW KNIVES", "ROLLING THROWS 6 KNIVES AROUND YOU", false, [{ "on": "on_roll", "do": [["nova", 6, 0.8, "spark"]] }], "uncommon", ["shadow"], {  }],
	["sh_vanish", "shadow", 2, "VANISH", "ROLLING ERASES NEARBY SHOTS", false, [{ "on": "on_roll", "do": [["clear_shots", 30]] }], "rare", ["shadow"], {  }],
	["sh_dance", "shadow", 1, "DEATH DANCE", "+1 ROLL CHARGE. KILLS HAVE 20% CHANCE TO REFUND A ROLL", false, [["add", "dodge_charges", 1], ["add", "charges", 1], { "on": "on_kill", "chance": 0.2, "do": [["refund_roll"]] }], "legend", ["shadow"], {  }],
	["t_brace", "bulwark", 3, "BRACE", "CLEARING A ROOM GRANTS 1 ARMOR 25% OF THE TIME", false, [{ "on": "on_room_clear", "chance": 0.25, "do": [["armor", 1]] }], "common", ["bulwark"], {  }],
	["t_retort", "bulwark", 2, "RETORT", "WHEN HIT, FIRE 12 SPIKES AROUND YOU", false, [{ "on": "on_damage_taken", "do": [["nova", 12, 1.0, "spark"]] }], "uncommon", ["bulwark"], {  }],
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
	# 8.5 (his ask, 6 Oct): more SUPER traits; COMMON_SUPER ones turn up often.
	["x_twin", "arcane", 1, "TWIN SOUL", "+1 PROJECTILE. +20% FIRE RATE", false, [["add", "count", 1], ["mul", "rate", 1.2]], "super", ["arcane"], {  }],
	["x_reflex", "shadow", 1, "LIGHTNING REFLEXES", "+2 ROLL CHARGES. ROLLS RECHARGE 30% FASTER", false, [["add", "dodge_charges", 2], ["add", "charges", 2], ["mul", "dodge_cd", 0.7]], "super", ["shadow"], {  }],
	["x_surge", "core", 1, "STAT SURGE", "+3 STR, +3 DEX AND +3 INT", false, [["attr", "str", 3], ["attr", "dex", 3], ["attr", "int", 3]], "super", ["fury"], {  }],
	["x_hoarder", "fortune", 1, "HOARDER", "EVERY CLEARED ROOM DROPS A STAT PICKUP", false, [{ "on": "on_room_clear", "do": [["drop", "stat"]] }], "super", ["fortune"], {  }],
	["x_legion", "swarm", 1, "LEGION", "EACH ROOM BEGINS WITH 5 WISPS FOR 12S. WISPS DEAL +30% DAMAGE", false, [{ "on": "on_room_enter", "do": [["summon", 12.0], ["summon", 12.0], ["summon", 12.0], ["summon", 12.0], ["summon", 12.0]] }, ["add", "fam_dmg", 0.3]], "super", ["swarm"], {  }],
	["x_glass", "fury", 1, "GLASS CANNON", "+60% DAMAGE. -1 MAX HEART", false, [["mul", "dmg", 1.6], ["add", "max_hp", -2], ["clamp_max", "hp", "max_hp"]], "super", ["fury"], {  }],
	["x_assassin", "edge", 1, "ASSASSIN", "+25% CRIT. CRITS DEAL +0.5X", false, [["add", "crit", 0.25], ["add", "crit_mult", 0.5]], "super", ["edge"], {  }],
	["x_bloodmoon", "blood", 1, "BLOOD MOON", "+15% DAMAGE. KILLS HEAL HALF A HEART 5% OF THE TIME", false, [["mul", "dmg", 1.15], { "on": "on_kill", "chance": 0.05, "do": [["heal", 1]] }], "super", ["blood"], {  }],
	["x_winter", "frost", 1, "WINTER'S HEART", "EVERY SECOND CHILL EVERY FOE. CHILLED FOES TAKE +50% DAMAGE", false, [{ "on": "every_n_seconds", "period": 1.0, "do": [["status_area", "chill", 2, 999]] }, ["add", "vs_chill", 0.5]], "super", ["frost"], {  }],
	["x_inferno", "pyre", 1, "INFERNO", "EVERY 4S BURN EVERY FOE. BURNING FOES TAKE +30% DAMAGE", false, [{ "on": "every_n_seconds", "period": 4.0, "do": [["status_area", "burn", 1, 999]] }, ["add", "vs_burn", 0.3]], "super", ["pyre"], {  }],
	["x_plague", "venom", 1, "PLAGUE LORD", "EVERY 2S POISON EVERY FOE. +50% POISON DAMAGE", false, [{ "on": "every_n_seconds", "period": 2.0, "do": [["status_area", "poison", 1, 999]] }, ["add", "poison_dmg", 0.5]], "super", ["venom"], {  }],
	["x_juggernaut", "bulwark", 1, "JUGGERNAUT", "+2 MAX HEARTS. EVERY NEW FLOOR GIVES 3 ARMOR. +15 THORNS", false, [["add", "max_hp", 4], ["add_cap", "hp", 4, "max_hp"], { "on": "on_floor_start", "do": [["armor", 3]] }, ["add", "thorns", 15]], "super", ["bulwark"], {  }],
	# 8.4 rule-benders.
	["f_idle", "core", 1, "IDLE HANDS", "+20% DAMAGE FOR EACH EMPTY GEAR SLOT", false, [["hook", "idle_dmg", 0.2]], "rare", ["fury"], {  }],
	["f_purse", "fortune", 1, "BOTTOMLESS PURSE", "ANYTHING THAT GROWS WITH GOLD COUNTS YOU AS HOLDING 1000 GOLD OR MORE", false, [["hook", "purse", 1]], "rare", ["fortune"], {  }],
	# 8.4 synergy traits: they grow with what you already do.
	["y_momentum", "shadow", 1, "MOMENTUM", "EVERY ROLL: +1% DAMAGE FOR THE REST OF THE RUN (UP TO +60%)", false, [{ "on": "on_roll", "do": [["stack", "dmg", 0.01, 0.6, "momentum"]] }], "uncommon", ["shadow"], {  }],
	["y_veteran", "core", 1, "VETERAN", "EVERY CLEARED ROOM: +1% DAMAGE FOR THE REST OF THE RUN (UP TO +50%)", false, [{ "on": "on_room_clear", "do": [["stack", "dmg", 0.01, 0.5, "veteran"]] }], "uncommon", ["fury"], {  }],
	["y_collector", "fortune", 1, "COLLECTOR", "+2% DAMAGE FOR EVERY STAT PICKUP TAKEN THIS RUN", false, [["hook", "collect_dmg", 0.02]], "rare", ["fortune"], {  }],
	["y_zealot", "core", 1, "ZEALOT", "+5% DAMAGE FOR EACH POINT OF YOUR HIGHEST ALIGNMENT", false, [["hook", "zealot_dmg", 0.05]], "rare", ["fury"], {  }],
	["y_prism", "arcane", 1, "PRISM", "+15% DAMAGE FOR EACH DIFFERENT AILMENT ON THE FOE YOU HIT. 15% OF HITS ADD ONE", false, [["hook", "prism_dmg", 0.15], { "on": "on_hit", "chance": 0.15, "do": [["rand_status", 1]] }], "rare", ["arcane"], {  }],
	# 13.3 (his ask, 7 Oct: "creative cool traits"). This game's own.
	["z_bankshot", "arcane", 2, "BANK SHOT", "EVERY 5TH SHOT ALSO FIRES 2 SHOTS BEHIND YOU", false, [{ "on": "every_n_shots", "every": 5, "do": [["shoot_at", 2, 0.8, "", 0.25, PI]] }], "uncommon", ["arcane"], {  }],
	["z_scorch", "pyre", 2, "SCORCHED TRAIL", "ROLLING LEAVES A POOL OF FIRE", false, [{ "on": "on_roll", "cd": 0.5, "do": [["zone", "fire", 26, 2.5]] }], "uncommon", ["pyre", "shadow"], {  }],
	["z_comet", "pyre", 1, "FALLING STAR", "EVERY 5TH KILL CALLS DOWN A METEOR", false, [{ "on": "on_kill", "every": 5, "do": [["meteor", 3.0, 36], ["vfx", "label", "STARFALL!", "#f2c94c"]] }], "rare", ["pyre"], {  }],
	["z_static", "storm", 2, "STATIC CLING", "CRITS SHOCK THE FOE AND ARC TO NEARBY FOES", false, [{ "on": "on_crit", "do": [["status", "shock", 1], ["chain", 0.4]] }], "uncommon", ["storm", "edge"], {  }],
	["z_feast", "blood", 1, "NIGHT FEAST", "KILLING A BLEEDING FOE HEALS HALF A HEART (EVERY 4S)", false, [{ "on": "on_kill", "if": "bleeding", "cd": 4.0, "do": [["heal", 1]] }], "rare", ["blood"], {  }],
	["z_midas", "fortune", 1, "GOLDEN TOUCH", "3% OF HITS TURN AN ORDINARY FOE INTO GOLD", false, [{ "on": "on_hit", "chance": 0.03, "do": [["transmute", 6]] }], "rare", ["fortune"], {  }],
	["z_hexback", "malice", 2, "EVIL EYE", "WHEN HIT, CURSE EVERY FOE AROUND YOU", false, [{ "on": "on_damage_taken", "do": [["status_area", "curse", 2, 130], ["vfx", "ring", "#a35bd6", 130]] }], "uncommon", ["malice"], {  }],
	["z_horizon", "arcane", 1, "GRAVITY WELL", "EVERY 5S IN A FIGHT, DRAG FOES TOGETHER AND BLAST THEM FOR 300%", false, [{ "on": "every_n_seconds", "period": 5.0, "if": "fighting", "do": [["pull", 170, 340], ["explode", 90, 3.0], ["vfx", "ring", "#a35bd6", 140]] }], "legend", ["arcane"], {  }],
	["z_overflow", "bulwark", 2, "SPILLOVER", "HEALING AT FULL HEALTH FIRES A RING OF 12 SHOTS", false, [{ "on": "on_overheal", "do": [["nova", 12, 0.8, "spark"]] }], "uncommon", ["bulwark"], {  }],
	["z_lastword", "edge", 2, "LAST WORD", "HITTING THE LAST FOE IN A ROOM STRIKES IT AGAIN FOR 150%", false, [{ "on": "on_hit", "if": "last_foe", "cd": 0.3, "do": [["damage", 1.5]] }], "uncommon", ["edge"], {  }],
	["z_dice", "fortune", 1, "LOADED DICE", "ENTERING A ROOM, SOMETHING RANDOM HAPPENS", false, [{ "on": "on_room_enter", "do": [["chaos"]] }], "rare", ["fortune"], {  }],
	["z_thunderstep", "storm", 1, "THUNDER STEP", "ROLLING INTO A CROWD CALLS 3 LIGHTNING STRIKES", false, [{ "on": "on_roll", "if": "crowd", "cd": 0.8, "do": [["bolts", 3, 1.2]] }], "rare", ["storm", "shadow"], {  }],
	["z_chainreact", "demolition", 2, "POWDER KEG", "KILLS HAVE 16% CHANCE TO LEAVE A LIT BOMB", false, [{ "on": "on_kill", "chance": 0.16, "do": [["bomb", 0.6]] }], "uncommon", ["demolition"], {  }],
	["z_wardrobe", "bulwark", 1, "WARDROBE", "+6% DAMAGE FOR EVERY SET PIECE YOU WEAR", false, [["hook", "wardrobe_dmg", 0.06]], "rare", ["bulwark"], {  }],
	["x_tailor", "bulwark", 1, "MASTER TAILOR", "SET PIECES COME TO YOU FAR MORE OFTEN. +8% DAMAGE PER SET PIECE WORN", false, [["hook", "tailor", 1], ["hook", "wardrobe_dmg", 0.08]], "super", ["bulwark"], {  }],
	["x_halo", "arcane", 1, "HALO OF BLADES", "EVERY 2S IN A FIGHT, A SPINNING RING OF 8 BLADES", false, [{ "on": "every_n_seconds", "period": 2.0, "if": "fighting", "do": [["nova", 8, 0.7, "spark", 3.0]] }], "super", ["arcane"], {  }],
	["g_goldblood", "fortune", 1, "GOLDEN BLOOD", "+1% DAMAGE FOR EVERY 10 GOLD HELD. CRITS PAY 1 GOLD", false, [["set", "miser", true], { "on": "on_crit", "do": [["gold", 1]] }], "legend", ["fortune", "edge"], {  }],
	# Stage 25 (his word, 9 Oct: "add more cool traits"), and two for REACTIONS (reactions.gd).
	["y_stormheart", "storm", 1, "STORM HEART", "EVERY 4TH CRIT CALLS 4 LIGHTNING STRIKES", false, [{ "on": "on_crit", "every": 4, "do": [["bolts", 4, 1.0]] }], "rare", ["storm"], {  }],
	["y_redharvest", "blood", 2, "RED HARVEST", "12% OF KILLS HEAL HALF A HEART", false, [{ "on": "on_kill", "chance": 0.12, "do": [["heal", 1]] }], "uncommon", ["blood"], {  }],
	["y_frostwake", "frost", 2, "FROSTWAKE", "ROLLING CHILLS EVERY FOE AROUND YOU", false, [{ "on": "on_roll", "cd": 1.0, "do": [["status_area", "chill", 2, 110], ["vfx", "ring", "#6fd3e0", 110]] }], "uncommon", ["frost"], {  }],
	["y_echoedge", "edge", 1, "ECHOING EDGE", "EVERY 3RD HIT STRIKES AGAIN FOR 80%", false, [{ "on": "on_hit", "every": 3, "do": [["damage", 0.8]] }], "rare", ["edge"], {  }],
	["y_meteors", "arcane", 1, "METEOR SHOWER", "EVERY 6S IN A FIGHT, 3 METEORS FALL ON FOES", false, [{ "on": "every_n_seconds", "period": 6.0, "if": "fighting", "do": [["meteor", 1.5, 28], ["meteor", 1.5, 28], ["meteor", 1.5, 28]] }], "super", ["arcane"], {  }],
	["y_mirrorskin", "bulwark", 1, "MIRROR SKIN", "WHEN HIT, 20 SHOTS BURST OUT OF YOU", false, [{ "on": "on_damage_taken", "do": [["nova", 20, 1.0, "spark"]] }], "rare", ["bulwark"], {  }],
	["y_plague", "venom", 2, "PLAGUE BEARER", "25% OF KILLS POISON THE FOES AROUND", false, [{ "on": "on_kill", "chance": 0.25, "do": [["status_area", "poison", 3, 70], ["vfx", "ring", "#b8e05a", 70]] }], "uncommon", ["venom"], {  }],
	["y_wildcard", "fortune", 1, "WILD CARD", "EVERY 20TH HIT, SOMETHING RANDOM HAPPENS", false, [{ "on": "on_hit", "every": 20, "cd": 1.5, "do": [["chaos"]] }], "rare", ["fortune"], {  }],
	["y_frenzy", "fury", 2, "BLOOD FRENZY", "KILLS GIVE +4% FIRE RATE FOR 4S, STACKING", false, [{ "on": "on_kill", "do": [["buff", "rate", 0.04, 4.0]] }], "uncommon", ["fury"], {  }],
	["y_dreadlord", "malice", 1, "DREAD LORD", "EVERY 10S IN A FIGHT, CURSE AND WEAKEN EVERY FOE", false, [{ "on": "every_n_seconds", "period": 10.0, "if": "fighting", "do": [["status_area", "curse", 2, 400], ["status_area", "weakened", 2, 400], ["vfx", "ring", "#7a3a8c", 160]] }], "super", ["malice"], {  }],
	["y_thornhide", "bulwark", 2, "THORNHIDE", "WHEN HIT, +1 ARMOR (AT MOST EVERY 6S)", false, [{ "on": "on_damage_taken", "cd": 6.0, "do": [["armor", 1]] }], "uncommon", ["bulwark"], {  }],
	["y_cometroll", "pyre", 1, "COMET ROLL", "ROLLING CALLS A METEOR ON A FOE", false, [{ "on": "on_roll", "cd": 0.8, "do": [["meteor", 1.5, 26]] }], "rare", ["pyre"], {  }],
	["y_alchemist", "arcane", 1, "ALCHEMIST'S EYE", "REACTIONS HIT TWICE AS HARD (TWO AILMENTS ON A FOE REACT)", false, [["hook", "react_dmg", 1.0]], "rare", ["arcane"], {  }],
	["y_catalyst", "venom", 1, "CATALYST", "REACTIONS COME BACK TWICE AS FAST. 20% OF HITS BURN", false, [["hook", "react_fast", 1], ["add", "burn", 0.2]], "rare", ["venom"], {  }],
	# Stage 26 (his word, 9 Oct: "more super cool synergy and legendary and mythic traits"): legendary and MYTHIC
	# traits that cast the spellbook's spells (Actions "spell") or feed on reactions ("on_reaction").
	["l_bladestorm", "edge", 1, "BLADESTORM", "HALF OF YOUR KILLS CONJURE A SPECTRAL BLADE THAT FIGHTS FOR 4S", false, [{ "on": "on_kill", "chance": 0.5, "do": [["spell", "blade", 0.8]] }], "legend", ["edge", "arcane"], {  }],
	["l_starcaller", "arcane", 1, "COMET CALLER", "EVERY 5TH CRIT CALLS A COMET THROUGH THE FOE", false, [{ "on": "on_crit", "every": 5, "do": [["spell", "comet", 2.0]] }], "legend", ["arcane", "pyre"], {  }],
	["l_stormherd", "storm", 1, "STORMHERD", "EVERY 8S IN A FIGHT, A STORM CLOUD FOLLOWS YOUR FOES", false, [{ "on": "every_n_seconds", "period": 8.0, "if": "fighting", "do": [["spell", "cloud", 1.0]] }], "legend", ["storm"], {  }],
	["l_runelord", "malice", 1, "RUNELORD", "EVERY 4TH HIT DRAWS A RUNE UNDER THE FOE THAT ERUPTS", false, [{ "on": "on_hit", "every": 4, "cd": 0.3, "do": [["spell", "glyph", 1.5]] }], "legend", ["malice", "arcane"], {  }],
	["l_voidheart", "shadow", 1, "VOIDHEART", "WHEN HIT, A BLACK HOLE OPENS ON THE NEAREST FOE", false, [{ "on": "on_damage_taken", "cd": 2.0, "do": [["spell", "void", 2.0]] }], "legend", ["shadow"], {  }],
	["l_chainreact", "pyre", 1, "CHAIN REACTION", "EVERY REACTION SETS OFF A BLAST FOR 150% AROUND THE FOE", false, [{ "on": "on_reaction", "do": [["explode", 40, 1.5]] }], "legend", ["pyre", "venom"], {  }],
	["m_ascendant", "core", 1, "ASCENDANT", "EVERY 15S IN A FIGHT: 4S OF GODHOOD. +100% DAMAGE AND FIRE RATE, AND NOTHING HURTS YOU", false, [{ "on": "every_n_seconds", "period": 15.0, "if": "fighting", "do": [["buff", "dmg", 1.0, 4.0], ["buff", "rate", 1.0, 4.0], ["invuln", 4.0], ["vfx", "ring", "#fff07a", 160]] }], "mythic", ["arcane", "fury"], {  }],
	["m_worldbreaker", "demolition", 1, "WORLDBREAKER", "EVERY 4TH KILL CALLS A COMET AND OPENS A BLACK HOLE", false, [{ "on": "on_kill", "every": 4, "do": [["spell", "comet", 3.0], ["spell", "void", 2.5]] }], "mythic", ["demolition", "shadow"], {  }],
	["m_chronomancer", "arcane", 1, "CHRONOMANCER", "EVERY 9S IN A FIGHT, TIME STOPS AROUND THE NEAREST FOE", false, [{ "on": "every_n_seconds", "period": 9.0, "if": "fighting", "do": [["spell", "clock", 2.0]] }], "mythic", ["arcane", "frost"], {  }],
	["m_prismsoul", "arcane", 1, "PRISMATIC SOUL", "15% OF HITS BURST INTO RED, BLUE AND GREEN BOLTS THAT SPLIT AGAIN", false, [{ "on": "on_hit", "chance": 0.15, "cd": 0.15, "do": [["spell", "prism", 0.8]] }], "mythic", ["arcane"], {  }],
	["m_elemental", "core", 1, "ELEMENTAL AVATAR", "REACTIONS COME BACK 4X AS FAST AND HIT 3X AS HARD. 20% OF HITS ADD A RANDOM AILMENT", false, [["hook", "react_fast", 1], ["hook", "react_dmg", 2.0], ["hook", "react_avatar", 1], { "on": "on_hit", "chance": 0.2, "do": [["rand_status", 2]] }], "mythic", ["pyre", "frost", "venom"], {  }],
	["m_serpentking", "venom", 1, "SERPENT KING", "EVERY 6S IN A FIGHT, A FIRE SERPENT HUNTS YOUR FOES", false, [{ "on": "every_n_seconds", "period": 6.0, "if": "fighting", "do": [["spell", "serpent", 1.2]] }], "mythic", ["venom", "pyre"], {  }],
	# Stage 29 (his word, 9 Oct: "make so much new and cool traits so every run could feel different").
	# OATHS open every run (G.offer_traits: one of three, before the first room); the rest join the picks.
	["o_flame", "pyre", 1, "OATH OF FLAME", "EVERY HIT BURNS. BURNING FOES TAKE +30% DAMAGE", false, [["add", "burn", 1.0], ["add", "vs_burn", 0.3]], "oath", ["pyre"], {  }],
	["o_frost", "frost", 1, "OATH OF FROST", "EVERY HIT CHILLS. CHILLED FOES TAKE +30% DAMAGE", false, [["add", "chill", 1.0], ["add", "vs_chill", 0.3]], "oath", ["frost"], {  }],
	["o_venom", "venom", 1, "OATH OF VENOM", "HITS ADD 2 POISON. POISON DEALS +60% DAMAGE", false, [["add", "poison", 2], ["add", "poison_dmg", 0.6]], "oath", ["venom"], {  }],
	["o_thunder", "storm", 1, "OATH OF THUNDER", "EVERY 3RD HIT CALLS LIGHTNING ON THE FOE. CRITS SHOCK", false, [{ "on": "on_hit", "every": 3, "cd": 0.15, "do": [["lightning", 0.8]] }, { "on": "on_crit", "do": [["status", "shock", 1]] }], "oath", ["storm"], {  }],
	["o_blood", "blood", 1, "OATH OF BLOOD", "+40% DAMAGE, -1 MAX HEART. 8% OF KILLS HEAL HALF A HEART", false, [["mul", "dmg", 1.4], ["add_floor", "max_hp", -2, 2], ["clamp_max", "hp", "max_hp"], { "on": "on_kill", "chance": 0.08, "do": [["heal", 1]] }], "oath", ["blood", "fury"], {  }],
	["o_swarm", "swarm", 1, "OATH OF THE SWARM", "+2 WISPS. EVERY ROOM BEGINS WITH 3 MORE FOR 15S", false, [["add", "familiars", 2], { "on": "on_room_enter", "do": [["summon", 15.0], ["summon", 15.0], ["summon", 15.0]] }], "oath", ["swarm"], {  }],
	["o_steel", "bulwark", 1, "OATH OF STEEL", "+2 MAX HEARTS, +20 THORNS. EVERY FLOOR BEGINS WITH 4 ARMOR", false, [["add", "max_hp", 4], ["add_cap", "hp", 4, "max_hp"], ["add", "thorns", 20], { "on": "on_floor_start", "do": [["armor", 4]] }], "oath", ["bulwark"], {  }],
	["o_shadow", "shadow", 1, "OATH OF SHADOWS", "+2 ROLL CHARGES. EVERY ROLL FIRES A RING OF 10 SHOTS", false, [["add", "dodge_charges", 2], ["add", "charges", 2], { "on": "on_roll", "cd": 0.3, "do": [["nova", 10, 0.8, "spark"]] }], "oath", ["shadow"], {  }],
	["o_archmage", "arcane", 1, "OATH OF THE ARCHMAGE", "EVERY 6TH ATTACK CALLS A COMET, EVERY 10TH A RUNE, EVERY 15TH A SPECTRAL BLADE", false, [{ "on": "every_n_shots", "every": 6, "do": [["spell", "comet", 1.5]] }, { "on": "every_n_shots", "every": 10, "do": [["spell", "glyph", 1.2]] }, { "on": "every_n_shots", "every": 15, "do": [["spell", "blade", 0.8]] }], "oath", ["arcane"], {  }],
	["o_greed", "fortune", 1, "OATH OF GREED", "+1% DAMAGE FOR EVERY 10 GOLD HELD. 25% OF KILLS DROP A COIN", false, [["set", "miser", true], { "on": "on_kill", "chance": 0.25, "do": [["drop", "coin"]] }], "oath", ["fortune"], {  }],
	["o_duelist", "edge", 1, "OATH OF THE DUELIST", "+20% CRIT, CRITS DEAL +0.5X. EVERY 4TH CRIT STRIKES AGAIN", false, [["add", "crit", 0.2], ["add", "crit_mult", 0.5], { "on": "on_crit", "every": 4, "cd": 0.1, "do": [["damage", 1.0]] }], "oath", ["edge"], {  }],
	["o_rage", "fury", 1, "OATH OF RAGE", "KILLS GIVE +5% DAMAGE FOR 5S, STACKING. WHEN HIT, +30% FIRE RATE FOR 3S", false, [{ "on": "on_kill", "do": [["buff", "dmg", 0.05, 5.0]] }, { "on": "on_damage_taken", "do": [["buff", "rate", 0.3, 3.0]] }], "oath", ["fury"], {  }],
	["o_ruin", "demolition", 1, "OATH OF RUIN", "30% OF KILLS EXPLODE FOR 60% AROUND THE FOE. +2 BOMBS", false, [{ "on": "on_kill", "chance": 0.3, "do": [["explode", 34, 0.6]] }, ["add", "bombs", 2]], "oath", ["demolition"], {  }],
	["o_hexer", "malice", 1, "OATH OF THE HEXER", "20% OF HITS CURSE. KILLING A CURSED FOE CURSES EVERY FOE NEAR YOU", false, [{ "on": "on_hit", "chance": 0.2, "do": [["status", "curse", 1]] }, { "on": "on_kill", "if": "cursed", "do": [["status_area", "curse", 2, 90], ["vfx", "ring", "#7a3a8c", 90]] }], "oath", ["malice"], {  }],
	["o_grave", "swarm", 1, "OATH OF THE GRAVE", "25% OF KILLS RAISE A SKELETON THAT FIGHTS FOR YOU FOR 10S", false, [{ "on": "on_kill", "chance": 0.25, "do": [["raise", 10.0, 1.0]] }], "oath", ["swarm", "malice"], {  }],
	["o_engineer", "core", 1, "OATH OF THE ENGINEER", "EVERY 10S IN A FIGHT, A TURRET JOINS YOU FOR 10S", false, [{ "on": "every_n_seconds", "period": 10.0, "if": "fighting", "do": [["turret", "random", 10.0, 1.0]] }], "oath", ["demolition"], {  }],
	["o_hourglass", "arcane", 1, "OATH OF THE HOURGLASS", "EVERY 10S IN A FIGHT, TIME STOPS AROUND A FOE. ROLLS RECHARGE 25% FASTER", false, [{ "on": "every_n_seconds", "period": 10.0, "if": "fighting", "do": [["spell", "clock", 1.5]] }, ["mul", "dodge_cd", 0.75]], "oath", ["arcane", "frost"], {  }],
	["o_chaos", "fortune", 1, "OATH OF CHAOS", "EVERY ROOM, SOMETHING RANDOM HAPPENS. SO DOES EVERY 15TH HIT", false, [{ "on": "on_room_enter", "do": [["chaos"]] }, { "on": "on_hit", "every": 15, "cd": 1.0, "do": [["chaos"]] }], "oath", ["fortune"], {  }],
	["o_dawn", "core", 1, "OATH OF DAWN", "+1 MAX HEART. EVERY 8S IN A FIGHT, A RING OF 16 SHOTS OF LIGHT", false, [["add", "max_hp", 2], ["add_cap", "hp", 2, "max_hp"], { "on": "every_n_seconds", "period": 8.0, "if": "fighting", "do": [["nova", 16, 1.0, "spark"]] }], "oath", ["arcane", "bulwark"], {  }],
	["n_sparkplug", "storm", 3, "SPARKPLUG", "10% OF HITS SHOCK", false, [{ "on": "on_hit", "chance": 0.1, "do": [["status", "shock", 1]] }], "common", ["storm"], {  }],
	["n_serrated", "blood", 3, "SERRATED EDGE", "10% OF HITS MAKE THE FOE BLEED", false, [{ "on": "on_hit", "chance": 0.1, "do": [["status", "bleed", 1]] }], "common", ["blood"], {  }],
	["n_coinflip", "fortune", 2, "COIN FLIP", "15% OF KILLS DROP A COIN", false, [{ "on": "on_kill", "chance": 0.15, "do": [["drop", "coin"]] }], "common", ["fortune"], {  }],
	["n_stride", "shadow", 3, "LONG STRIDE", "+6% SPEED. ROLLING GIVES +15% DAMAGE FOR 2S", false, [["mul", "speed", 1.06], { "on": "on_roll", "do": [["buff", "dmg", 0.15, 2.0]] }], "common", ["shadow"], {  }],
	["n_kindled", "pyre", 3, "KINDLED STEEL", "HITS ON BURNING FOES DEAL A 15% BONUS HIT", false, [{ "on": "on_hit", "cd": 0.05, "if": "burning", "do": [["damage", 0.15]] }], "common", ["pyre"], {  }],
	["n_coldsnap", "frost", 3, "WINTER BITE", "KILLS CHILL THE FOES NEAR YOU", false, [{ "on": "on_kill", "cd": 0.5, "do": [["status_area", "chill", 1, 80]] }], "common", ["frost"], {  }],
	["n_trickshot", "edge", 2, "TRICK SHOT", "SHOTS BOUNCE OFF WALLS. +5% CRIT", false, [["add", "bounce", 1], ["add", "crit", 0.05]], "uncommon", ["edge"], {  }],
	["n_satellite", "arcane", 2, "LITTLE MOON", "AN ORB CIRCLES YOU AND BLOCKS SHOTS", false, [["add", "orbitals", 1]], "uncommon", ["arcane", "bulwark"], {  }],
	["n_vampire", "blood", 2, "VAMPIRIC TOUCH", "3% OF CRITS HEAL HALF A HEART", false, [{ "on": "on_crit", "chance": 0.03, "do": [["heal", 1]] }], "uncommon", ["blood", "edge"], {  }],
	["n_shockwave", "bulwark", 2, "SHOCKWAVE", "WHEN HIT, FOES NEAR YOU ARE THROWN BACK AND STUNNED", false, [{ "on": "on_damage_taken", "cd": 1.0, "do": [["push", 110, 300], ["status_area", "stun", 1, 110], ["vfx", "ring", "#f4ecd8", 110]] }], "uncommon", ["bulwark"], {  }],
	["n_huntmark", "edge", 2, "TARGET PRACTICE", "EVERY 5TH HIT MARKS THE FOE", false, [{ "on": "on_hit", "every": 5, "do": [["status", "mark", 1]] }], "uncommon", ["edge"], {  }],
	["n_aftershock", "demolition", 2, "AFTERSHOCK", "EVERY 8TH HIT SETS OFF A SMALL BLAST FOR 80%", false, [{ "on": "on_hit", "every": 8, "cd": 0.1, "do": [["explode", 28, 0.8]] }], "uncommon", ["demolition"], {  }],
	["n_glacial", "frost", 1, "GLACIAL ARMOR", "WHEN HIT, CHILL EVERY FOE NEAR YOU AND GAIN 1 ARMOR (EVERY 5S)", false, [{ "on": "on_damage_taken", "cd": 5.0, "do": [["status_area", "chill", 2, 120], ["armor", 1]] }], "uncommon", ["frost", "bulwark"], {  }],
	["n_emberdance", "pyre", 2, "EMBER DANCE", "ROLLING BURNS EVERY FOE NEAR YOU", false, [{ "on": "on_roll", "cd": 0.8, "do": [["status_area", "burn", 1, 90], ["vfx", "ring", "#e8873a", 90]] }], "uncommon", ["pyre", "shadow"], {  }],
	["n_ricochet", "storm", 2, "PINGBACK", "SHOTS JUMP TO ANOTHER FOE AFTER A HIT", false, [["add", "ricochet", 1]], "uncommon", ["storm", "edge"], {  }],
	["n_forked", "venom", 1, "FORKED TONGUE", "EVERY 4TH HIT ON A POISONED FOE ARCS TO ANOTHER FOE", false, [{ "on": "on_hit", "every": 4, "if": "poisoned", "do": [["chain", 0.5]] }], "rare", ["venom", "storm"], {  }],
	["n_horizon", "shadow", 1, "DARK STAR", "EVERY 10TH KILL OPENS A BLACK HOLE ON A FOE", false, [{ "on": "on_kill", "every": 10, "do": [["spell", "void", 2.0]] }], "rare", ["shadow", "arcane"], {  }],
	["n_pinball", "arcane", 1, "PINBALL WIZARD", "EVERY 7TH ATTACK LAUNCHES A BOUNCING ORB", false, [{ "on": "every_n_shots", "every": 7, "do": [["spell", "pinball", 1.0]] }], "rare", ["arcane"], {  }],
	["n_sentry", "core", 1, "SENTRY POST", "EVERY 15S IN A FIGHT, A TESLA TURRET JOINS YOU FOR 12S", false, [{ "on": "every_n_seconds", "period": 15.0, "if": "fighting", "do": [["turret", "tesla", 12.0, 1.0]] }], "rare", ["demolition", "storm"], {  }],
	["n_reaper", "malice", 1, "REAPER'S TOLL", "EVERY 6S IN A FIGHT, THE MOST WOUNDED FOE TAKES 300%. BELOW 15% IT DIES", false, [{ "on": "every_n_seconds", "period": 6.0, "if": "fighting", "do": [["execute_weakest", 3.0, 0.15]] }], "rare", ["malice", "edge"], {  }],
	["n_parry", "bulwark", 1, "PARRY", "ROLLING TURNS THE FOES' SHOTS NEAR YOU INTO YOURS", false, [{ "on": "on_roll", "cd": 1.0, "do": [["reflect", 80, 1.0]] }], "rare", ["bulwark", "shadow"], {  }],
	["n_silvertongue", "fortune", 1, "SWEET TALK", "EVERY 12S IN A FIGHT, FOES NEAR YOU FIGHT FOR YOU FOR 4S", false, [{ "on": "every_n_seconds", "period": 12.0, "if": "fighting", "do": [["charm_area", 90, 4.0]] }], "rare", ["fortune", "malice"], {  }],
	["n_hailstorm", "frost", 1, "HAILSTORM", "EVERY 7S IN A FIGHT, 12 SHARDS BURST FROM YOU AND FOES NEAR YOU ARE CHILLED", false, [{ "on": "every_n_seconds", "period": 7.0, "if": "fighting", "do": [["nova", 12, 0.8, "spark"], ["status_area", "chill", 2, 140]] }], "rare", ["frost"], {  }],
	["n_tempest", "storm", 1, "EYE OF THE TEMPEST", "EVERY 3S IN A FIGHT, LIGHTNING STRIKES 2 FOES", false, [{ "on": "every_n_seconds", "period": 3.0, "if": "fighting", "do": [["bolts", 2, 1.2]] }], "legend", ["storm"], {  }],
	["n_vipers", "venom", 1, "NEST OF VIPERS", "EVERY 4TH KILL RELEASES A FIRE SERPENT", false, [{ "on": "on_kill", "every": 4, "do": [["spell", "serpent", 1.0]] }], "legend", ["venom", "pyre"], {  }],
	["n_rainbow", "edge", 1, "RAINBOW EDGE", "CRITS SPLIT INTO RED, BLUE AND GREEN BOLTS (EVERY 1S)", false, [{ "on": "on_crit", "cd": 1.0, "do": [["spell", "prism", 0.8]] }], "legend", ["edge", "arcane"], {  }],
	["n_runeward", "bulwark", 1, "RUNE WARD", "WHEN HIT, A RUNE ERUPTS UNDER A FOE. EVERY FLOOR BEGINS WITH 2 ARMOR", false, [{ "on": "on_damage_taken", "cd": 1.5, "do": [["spell", "glyph", 2.0]] }, { "on": "on_floor_start", "do": [["armor", 2]] }], "legend", ["bulwark", "arcane"], {  }],
	["n_overlord", "swarm", 1, "OVERLORD", "+3 WISPS. WISPS DEAL +50% DAMAGE", false, [["add", "familiars", 3], ["add", "fam_dmg", 0.5]], "super", ["swarm"], {  }],
	["n_bulletsea", "arcane", 1, "SEA OF BULLETS", "+2 PROJECTILES. -10% DAMAGE", false, [["add", "count", 2], ["mul", "dmg", 0.9]], "super", ["arcane"], {  }],
	["n_clover", "fortune", 1, "FOUR-LEAF CLOVER", "+3 LUCK. CHESTS GIVE 2 MORE GEMS", false, [["add", "luck", 3], { "on": "on_chest", "do": [["drop", "gem"], ["drop", "gem"]] }], "super", ["fortune"], {  }],
	["n_giantblood", "bulwark", 1, "GIANT'S BLOOD", "+3 MAX HEARTS. SHOTS 30% BIGGER", false, [["add", "max_hp", 6], ["add_cap", "hp", 6, "max_hp"], ["mul", "size", 1.3]], "super", ["bulwark", "fury"], {  }],
	["n_sentence", "malice", 1, "DEATH SENTENCE", "ELITES TAKE +35% DAMAGE. KILLING AN ELITE HEALS A HEART", false, [["add", "elite_mult", 0.35], { "on": "on_kill", "if": "elite", "do": [["heal", 2]] }], "super", ["malice", "edge"], {  }],
	["n_godslayer", "edge", 1, "GODSLAYER", "ELITES TAKE +60% DAMAGE. EVERY 10TH HIT ON A GUARDIAN CALLS A COMET", false, [["add", "elite_mult", 0.6], { "on": "on_hit", "every": 10, "if": "boss", "do": [["spell", "comet", 2.0]] }], "mythic", ["edge"], {  }],
	["n_dragonsoul", "pyre", 1, "DRAGON SOUL", "EVERY HIT BURNS. EVERY 5S IN A FIGHT, 3 METEORS AND A FIRE SERPENT", false, [["add", "burn", 1.0], { "on": "every_n_seconds", "period": 5.0, "if": "fighting", "do": [["meteor", 1.5, 28], ["meteor", 1.5, 28], ["meteor", 1.5, 28], ["spell", "serpent", 1.0]] }], "mythic", ["pyre"], {  }],
	["n_winter", "frost", 1, "ETERNAL WINTER", "EVERY 8S IN A FIGHT, STOP TIME AT A FOE AND CHILL ALL. CHILLED FOES TAKE +50%", false, [{ "on": "every_n_seconds", "period": 8.0, "if": "fighting", "do": [["spell", "clock", 1.5], ["status_area", "chill", 2, 999]] }, ["add", "vs_chill", 0.5]], "mythic", ["frost", "arcane"], {  }],
	# 33.1 THE MIND FIELD (his word, 9 Oct: an INT aura build; ideas only, our own names): auras and
	# halos that grow with INT until they fill the room (scripts/combat/auras.gd).
	["k_innerlight", "arcane", 1, "INNER LIGHT", "A HALO OF YOUR OWN: EVERY SECOND IN A FIGHT, THE FOES IN IT TAKE A HIT. IT GROWS WITH INT", false, [["hook", "halo_mind", 1]], "uncommon", ["arcane"], {  }],
	["k_widethoughts", "arcane", 3, "WIDE THOUGHTS", "+15% AURA REACH", false, [["hook", "aura_reach", 0.15]], "common", ["arcane"], {  }],
	["k_stillmind", "arcane", 2, "STILL MIND", "+1 INT. HALOS PULSE 25% FASTER", false, [["attr", "int", 1], ["hook", "aura_speed", 0.25]], "uncommon", ["arcane"], {  }],
	["k_deepwell", "arcane", 3, "DEEP WELL", "+2 INT. AURAS HIT +3% HARDER FOR EVERY POINT OF INT", false, [["attr", "int", 2], ["hook", "aura_int_dmg", 0.03]], "rare", ["arcane"], {  }],
	["k_hum", "arcane", 2, "HUMMING FIELD", "EVERY HALO PULSE ALSO HITS THE FOES IN IT FOR 30%", false, [["hook", "aura_strike", 0.3]], "rare", ["arcane"], {  }],
	["k_overmind", "arcane", 2, "OVERMIND", "EVERY POINT OF INT GIVES +4% AURA REACH", false, [["hook", "aura_int", 0.04]], "legend", ["arcane"], {  }],
	# 33.2 THE TAVERN (his word, 9 Oct: a STR melee build that needs no crits): drinks make you TIPSY
	# (scripts/combat/tipsy.gd).
	["j_regular", "fury", 2, "REGULAR", "A CLEARED ROOM HAS A 25% CHANCE TO LEAVE AN ALE", false, [{ "on": "on_room_clear", "chance": 0.25, "do": [["drop", "c_ale"]] }], "common", ["fury"], {  }],
	["j_irongut", "fury", 2, "IRON GUT", "DRINKS GIVE +1 MORE TIPSY. TIPSY GOES 4 HIGHER", false, [["hook", "tipsy_gain", 1], ["hook", "tipsy_cap", 4]], "uncommon", ["fury"], {  }],
	["j_appetite", "bulwark", 3, "BIG APPETITE", "+1 MAX HEART. +4% DAMAGE FOR EVERY MAX HEART ABOVE 3", false, [["add", "max_hp", 2], ["add_cap", "hp", 2, "max_hp"], ["hook", "heart_dmg", 0.04]], "uncommon", ["bulwark", "fury"], {  }],
	["j_brawler", "fury", 2, "BAR BRAWLER", "WHILE TIPSY, 15% OF YOUR HITS STUN THE FOE", false, [{ "on": "on_hit", "if": "tipsy", "chance": 0.15, "do": [["status", "stun", 1]] }], "rare", ["fury"], {  }],
	["j_surestrike", "fury", 1, "SURE STRIKE", "YOU NEVER CRIT. EVERY 1% OF CRIT CHANCE GIVES +1.5% DAMAGE INSTEAD", false, [["hook", "sure_strike", 1]], "rare", ["fury", "edge"], {  }],
	["j_lastorders", "fury", 1, "LAST ORDERS", "AT 8+ TIPSY, EVERY 4TH ATTACK SENDS OUT A SHOCKWAVE FOR 150%", false, [{ "on": "every_n_shots", "every": 4, "if": "very_tipsy", "do": [["area", 70, 1.5], ["push", 70, 220], ["vfx", "ring", "#e8b84a", 70]] }], "legend", ["fury"], {  }],
	# 34.1 THE TRIGGER PATH (his word, 9 Oct: a DEX/INT build of high-frequency triggers): lucky hits
	# and the spell slot (scripts/combat/lucky.gd).
	["q_charmed", "fortune", 3, "CHARMED LIFE", "+3% LUCKY HITS: A LUCKY HIT STRIKES AGAIN", false, [["hook", "lucky", 0.03]], "common", ["fortune", "edge"], {  }],
	["q_stars", "edge", 2, "LUCKY STARS", "+1% LUCKY HITS FOR EVERY POINT OF DEX", false, [["hook", "lucky_dex", 0.01]], "rare", ["edge", "fortune"], {  }],
	["q_spellslinger", "arcane", 1, "SPELLSLINGER", "CRITS AND LUCKY HITS CAST THE WEAPON IN YOUR FIRST BACKPACK SLOT, FOR FREE", false, [["hook", "slot_cast", 1]], "rare", ["arcane", "edge"], {  }],
	["q_static", "storm", 2, "STATIC BUILD-UP", "20% OF HITS SHOCK. A FOE AT FULL SHOCK DISCHARGES: LIGHTNING TO 4 FOES FOR 150%", false, [["hook", "static_buildup", 1], { "on": "on_hit", "chance": 0.2, "do": [["status", "shock", 1]] }], "uncommon", ["storm"], {  }],
	["q_quickfingers", "edge", 3, "QUICK FINGERS", "+1 DEX. +1% ATTACK SPEED FOR EVERY POINT OF DEX", false, [["attr", "dex", 1], ["hook", "rate_per_dex", 0.01]], "uncommon", ["edge"], {  }],
	["q_jackpot", "fortune", 1, "JACKPOT", "EVERY 10TH LUCKY HIT CALLS DOWN 5 LIGHTNING BOLTS FOR 200%", false, [{ "on": "on_lucky", "every": 10, "do": [["bolts", 5, 2.0]] }], "legend", ["fortune", "storm"], {  }],
	# 34.2 THE LEGION PATH (his word, 9 Oct: a companion build): one set of numbers for every helper
	# (scripts/combat/legion.gd).
	["h_bonecall", "swarm", 3, "BONE CALL", "+10% COMPANION DAMAGE AND ATTACK SPEED", false, [["hook", "minion_dmg", 0.1], ["hook", "minion_speed", 0.1]], "common", ["swarm"], {  }],
	["h_march", "swarm", 2, "QUICK MARCH", "+6% MOVE SPEED. EVERY 1% OF EXTRA MOVE SPEED GIVES YOUR COMPANIONS +2% ATTACK SPEED", false, [["mul", "speed", 1.06], ["hook", "march", 2.0]], "uncommon", ["swarm", "shadow"], {  }],
	["h_marshal", "swarm", 2, "GRAVE MARSHAL", "+2 COMPANIONS AT ONCE. EVERY FIGHT, A SKELETON CLIMBS OUT BESIDE YOU FOR 20S", false, [["hook", "minion_cap", 2], { "on": "on_room_enter", "do": [["raise", 20.0, 0.8]] }], "rare", ["swarm", "malice"], {  }],
	["h_beacon", "swarm", 2, "BONE BEACON", "YOUR COMPANIONS DEAL +40% DAMAGE", false, [["hook", "minion_dmg", 0.4]], "rare", ["swarm"], {  }],
	# 35.1 DICE (his word, 9 Oct: "a broken sandbox" with dice to bend luck; scripts/game/dice.gd).
	["d_houserules", "fortune", 2, "HOUSE RULES", "+1 ALTER DIE AND +1 BANISH DIE. EVERY DIE YOU USE GIVES 6 GOLD", false, [["add", "alters", 1], ["add", "banishes", 1], { "on": "on_dice", "do": [["gold", 6]] }], "uncommon", ["fortune"], {  }],
	["d_fixedodds", "fortune", 1, "FIXED ODDS", "EVERY DIE YOU USE HAS A 40% CHANCE TO COME BACK", false, [["hook", "dice_back", 0.4]], "rare", ["fortune"], {  }],
	["d_highroller", "fortune", 1, "HIGH ROLLER", "EVERY DIE YOU USE: +4% DAMAGE FOR THE REST OF THE RUN (UP TO +60%). +2 REROLL DICE", false, [["add", "rerolls", 2], { "on": "on_dice", "do": [["stack", "dmg", 0.04, 0.6, "highroller"]] }], "legend", ["fortune"], {  }],
	# Stage 36 FOOD AND DRINK (his word, 9 Oct; scripts/game/food.gd).
	# 37.2 CHARMS (scripts/data/charms.gd).
	# 38.2 LOOT (loot.gd).
	["l_prospector", "fortune", 2, "PROSPECTOR", "+20% TREASURE FIND: A CHANCE OF ONE MORE ITEM FROM CLEARED FIGHTS AND CHESTS", false, [["hook", "treasure_find", 0.2]], "uncommon", ["fortune"], {  }],
	["c_collector", "fortune", 2, "COLLECTOR", "+1 CHARM SLOT. +3% LUCKY HITS", false, [["hook", "charm_slots", 1], ["hook", "lucky", 0.03]], "uncommon", ["fortune"], {  }],
	["j_hollowleg", "fury", 1, "HOLLOW LEG", "YOUR DRINK BUFFS NEVER WEAR OFF. +1 DRINK BUFF AT ONCE", false, [["hook", "drink_forever", 1], ["hook", "drink_slots", 1]], "rare", ["fury"], {  }],
	["j_gourmand", "bulwark", 2, "GOURMAND", "FOOD GIVES TWICE THE XP AND HEALS HALF A HEART", false, [["hook", "food_xp", 1.0], ["hook", "food_heal", 1]], "uncommon", ["bulwark"], {  }],
	["h_ranks", "swarm", 1, "ENDLESS RANKS", "A QUARTER OF YOUR KILLS CALL A WISP FOR 6S. COMPANIONS ATTACK 25% FASTER", false, [["hook", "minion_speed", 0.25], { "on": "on_kill", "chance": 0.25, "do": [["summon", 6.0]] }], "legend", ["swarm"], {  }],
	# 40.3 STRENGTH (his pictures, 10 Oct: a wiki's list of Strength traits; ideas only, our own names
	# and pictures, TRAITS_PLAN.md). What they need is scripts/combat/might.gd; each has its own
	# picture tr_<id> (tools/art/stage40_traits.py).
	["str_secondwind", "fury", 1, "LAST LEGS", "+1 EMPTY HEART. +12% DAMAGE FOR EVERY HEART YOU ARE MISSING.", false, [["add", "max_hp", 2], ["add", "desperate", 0.12]], "uncommon", ["fury"], {  }],
	["str_honest", "bulwark", 1, "HONEST LABOUR", "YOUR SPECIAL AND YOUR ROLLS RECHARGE 20% FASTER. EVERY BONUS TO YOUR ROLL RECHARGE SPEEDS YOUR SPECIAL TOO.", false, [["hook", "special_haste", 0.2], ["hook", "roll_haste", 0.2], ["hook", "honest", 1]], "uncommon", ["bulwark"], {  }],
	["str_ancestors", "bulwark", 1, "ANCESTOR SPIRITS", "2 SPIRIT WISPS FIGHT BESIDE YOU. +20% FIRE RATE.", false, [["add", "familiars", 2], ["mul", "rate", 1.2]], "rare", ["bulwark", "swarm"], {  }],
	["str_pride", "fury", 1, "PRIDE", "TAMING, PUPPETING OR TAUNTING A FOE: +40% DAMAGE OF HITS THAT DO NOT CRIT FOR 8S.", false, [["hook", "pride", 1]], "uncommon", ["fury"], {  }],
	["str_opening", "fury", 1, "OPENING", "AFTER 2S WITHOUT ATTACKING, YOUR NEXT ATTACK GIVES COURAGE: +30% DAMAGE FOR 5S.", false, [["hook", "opening", 1]], "common", ["fury"], {  }],
	["str_savagery", "fury", 1, "SAVAGERY", "EVERY POINT OF STR ALSO GIVES +5% CRIT DAMAGE.", false, [["hook", "critdmg_str", 0.05]], "rare", ["fury"], {  }],
	["str_warcharge", "fury", 1, "WARPATH", "+25 POWER AT +10%, +20% AND +30% MOVE SPEED ABOVE YOUR HERO'S OWN. EACH POWER: +1% DAMAGE.", false, [["hook", "war_charge", 25]], "uncommon", ["fury"], {  }],
	["str_brawn", "fury", 1, "BRAWN", "YOUR STR COUNTS DOUBLE. YOUR DEX AND INT COUNT HALF.", false, [["hook", "focus_str", 1]], "rare", ["fury"], {  }],
	["str_warcry", "fury", 1, "BATTLE HOWL", "USING YOUR SPECIAL SENDS YOU BERSERK: +30% DAMAGE AND FIRE RATE FOR 6S.", false, [{ "on": "on_special", "do": [["buff", "dmg", 0.3, 6.0], ["buff", "rate", 0.3, 6.0], ["vfx", "label", "BERSERK!", "#ff3b6b"]] }], "common", ["fury"], {  }],
	["str_hammer", "bulwark", 1, "HEAVEN'S HAMMER", "25% OF YOUR HITS DROP A HAMMER FROM THE SKY ON THE FOE FOR 150%.", false, [{ "on": "on_hit", "chance": 0.25, "cd": 0.25, "do": [["meteor", 1.5, 22]] }], "rare", ["bulwark"], {  }],
	["str_bluntforce", "demolition", 1, "BLUNT FORCE", "BLUNT HITS (HAMMERS, FISTS, FLAILS) SHAKE A FOE: EVERY 5TH MAKES IT REEL.", false, [["hook", "blunt", 1]], "common", ["demolition"], {  }],
	["str_bonebreaker", "demolition", 1, "BONE BREAKER", "+15% CRUSHING HITS: +50% DAMAGE THAT WEARS A GUARDIAN'S PLATE FASTER. A CRUSHING HIT LEAVES THE FOE VULNERABLE.", false, [["hook", "crush", 0.15], ["hook", "bone_break", 1]], "uncommon", ["demolition"], {  }],
	["str_doublemeasure", "fury", 1, "DOUBLE MEASURE", "YOUR DRINK BUFFS NEVER WEAR OFF, AND EVERY ONE COUNTS TWICE.", false, [["hook", "drink_forever", 1], ["hook", "drink_double", 1]], "legend", ["fury"], {  }],
	["str_crowd", "fury", 1, "CROWD FIGHTER", "+20 POWER FOR EVERY ONE IN THE ROOM: YOU, YOUR HELPERS AND THE FOES (UP TO +100). EACH POWER: +1% DAMAGE.", false, [["hook", "crowd", 20]], "rare", ["fury"], {  }],
	["str_musclememory", "bulwark", 1, "MUSCLE MEMORY", "YOUR SPECIAL RECHARGES 10% FASTER FOR EVERY RANK OF STR TRAITS YOU HAVE.", false, [["hook", "special_str", 0.1]], "uncommon", ["bulwark"], {  }],
	["str_toetotoe", "fury", 1, "TOE TO TOE", "UP CLOSE YOUR HITS ARE RUTHLESS: +30% DAMAGE, AND THEY GO THROUGH A FOE'S GUARD.", false, [["hook", "toe_to_toe", 1]], "common", ["fury"], {  }],
	["str_blastinghands", "demolition", 1, "BLASTING HANDS", "40% OF YOUR HITS EXPLODE ON THE FOE FOR 60%.", false, [{ "on": "on_hit", "chance": 0.4, "cd": 0.12, "do": [["explode", 26, 0.6]] }], "rare", ["demolition"], {  }],
	["str_bloodash", "blood", 1, "BLOOD AND ASH", "BURNS AND BLEEDS STACK UP TO 10 TIMES ON A FOE, EACH STACK 35% AS STRONG. +5% BURN CHANCE, CRITS BLEED.", false, [["hook", "fire_blood", 1], ["add", "burn", 0.05], ["add", "bleed", 0.25]], "rare", ["blood", "pyre"], {  }],
	["str_bigheart", "bulwark", 1, "BIG HEART", "+15% LUCKY HITS FOR EVERY HEART YOU HAVE ROOM FOR.", false, [["hook", "lucky_heart", 0.15]], "legend", ["bulwark", "fortune"], {  }],
	["str_strongarm", "demolition", 1, "STRONG ARM", "HALF YOUR STR ALSO COUNTS AS DEX FOR BOWS, GUNS AND THROWN WEAPONS.", false, [["hook", "heavy_draw", 1]], "uncommon", ["demolition"], {  }],
	["str_holyflame", "bulwark", 1, "HOLY FLAME", "+1 GOOD. WHILE GOOD LEADS, EVERY 10TH HIT IS HOLY: +25% DAMAGE AND FIRE RATE FOR 4S.", false, [["grant", "al_good", 1], { "on": "on_hit", "every": 10, "if": "lead_good", "do": [["buff", "dmg", 0.25, 4.0], ["buff", "rate", 0.25, 4.0]] }], "uncommon", ["bulwark"], {  }],
	["str_rollingthunder", "demolition", 1, "ROLLING THUNDER", "ROLLS RECHARGE 50% FASTER. AFTER A ROLL, YOUR NEXT 5 HITS ARE CRUSHING HITS.", false, [["hook", "roll_haste", 0.5], ["hook", "crush_next", 5]], "rare", ["demolition"], {  }],
	["str_scartissue", "blood", 1, "SCAR TISSUE", "+10% CURSE CHANCE. YOUR CURSE CHANCE ALSO ADDS TO YOUR CRIT CHANCE.", false, [["add", "curse", 0.1], ["hook", "scar_tissue", 1]], "uncommon", ["blood", "malice"], {  }],
	["str_presence", "bulwark", 1, "TOWERING PRESENCE", "YOUR TIMED BUFFS ARE 8% STRONGER FOR EVERY PIECE OF GEAR YOU WEAR.", false, [["hook", "presence", 0.08]], "uncommon", ["bulwark"], {  }],
	["str_packhunter", "blood", 1, "PACK HUNTER", "+1 HELPER AT ONCE, +25% COMPANION DAMAGE. YOUR OWN HITS ROLL TWICE AND KEEP THE LOWER.", false, [["hook", "minion_cap", 1], ["hook", "minion_dmg", 0.25], ["hook", "pack_roll", 1]], "common", ["blood", "swarm"], {  }],
	["str_sharpend", "blood", 1, "SHARP END", "PIERCING HITS (SPEARS, ARROWS, BULLETS) PUNCTURE: EACH STACK +4% DAMAGE TAKEN, UP TO 10.", false, [["hook", "sharp_end", 1]], "common", ["blood"], {  }],
	["str_mightright", "fury", 1, "MIGHT MAKES RIGHT", "+10 POWER. YOUR POWER ALSO MAKES YOUR BURNS, POISONS, BLEEDS AND CURSES STRONGER.", false, [["hook", "power", 10], ["hook", "might_right", 1]], "rare", ["fury"], {  }],
	["str_heavystride", "bulwark", 1, "HEAVY STRIDE", "EVERY PIECE OF GEAR YOU WEAR: +3% DAMAGE, MOVE SPEED AND ROLL RECHARGE.", false, [["hook", "stride", 0.03]], "common", ["bulwark"], {  }],
	["str_seething", "fury", 1, "BOILING BLOOD", "EVERY HIT BUILDS RAGE (A MELEE HIT 5): +1% DAMAGE EACH, UP TO 50. RAGE FADES WHEN YOU STOP.", false, [["hook", "seething", 1]], "common", ["fury"], {  }],
	["str_keenedge", "blood", 1, "BLEEDING EDGE", "SLASHING HITS (SWORDS, AXES, WHIPS) MAKE FOES BLEED.", false, [["hook", "keen_edge", 1]], "common", ["blood"], {  }],
	["str_irondiscipline", "bulwark", 1, "IRON DISCIPLINE", "YOU NEVER CRIT, BUT EVERY HIT IS A CRUSHING HIT: +50% DAMAGE THAT WEARS A GUARDIAN'S PLATE FASTER.", false, [["hook", "resolute", 1]], "rare", ["bulwark"], {  }],
	["str_openwounds", "blood", 1, "OPEN WOUNDS", "YOUR HITS MAKE A FOE'S BURN, POISON AND BLEED TICK AT ONCE (UP TO 4 TIMES A SECOND).", false, [["hook", "open_wounds", 1]], "rare", ["blood"], {  }],
	["str_shadowveil", "blood", 1, "SHADOW VEIL", "+3 MOONS OF SHADOW. A MOON'S HIT PUTS ALL 10 STACKS OF GLOOM ON A FOE AT ONCE.", false, [["add", "orbitals", 3], ["hook", "moon_gloom", 1]], "legend", ["blood", "shadow"], {  }],
	["str_steadyhand", "fury", 1, "STEADY HAND", "YOUR FIRE RATE BONUSES COUNT HALF, BUT EACH ALSO RAISES YOUR DAMAGE TWICE OVER.", false, [["hook", "steady", 1]], "rare", ["fury"], {  }],
	["str_shieldwall", "bulwark", 1, "HOLD THE LINE", "+2 ARMOR. MELEE HITS: +25% DAMAGE WHILE YOUR SHIELD'S BLOCK IS READY, +10% FOR EVERY ARMOR.", false, [["grant", "armor", 2], ["hook", "shield_wall", 1]], "uncommon", ["bulwark"], {  }],
	["str_threat", "fury", 1, "LOOMING THREAT", "LIGHT WEAPONS' HITS TAUNT A FOE: IT TAKES +15% DAMAGE. HEAVY WEAPONS' HITS COW IT: IT SLOWS.", false, [["hook", "threat", 1]], "common", ["fury"], {  }],
	["str_giantgrip", "demolition", 1, "GIANT'S GRIP", "HEAVY WEAPONS (STAVES, BOWS, GREAT BLADES AND HAFTS) SWING 25% FASTER.", false, [["hook", "giant_grip", 1]], "uncommon", ["demolition"], {  }],
	["str_merciless", "blood", 1, "MERCILESS", "YOUR SPECIAL RECHARGES 10% FASTER. ITS HITS LEAVE FOES VULNERABLE, AND WHAT IT INFLICTS IS TWICE AS STRONG.", false, [["hook", "special_haste", 0.1], ["hook", "merciless", 1]], "uncommon", ["blood"], {  }],
	# 41.2 DEXTERITY (his pictures, 10 Oct: a wiki's list of Dexterity traits; ideas only, our own names
	# and pictures, TRAITS_PLAN.md). What they need is scripts/combat/finesse.gd; pictures tr_<id>
	# (tools/art/stage41_traits.py). The list's infusion trait comes with the infusions (Stage 44).
	["dex_ballistics", "edge", 1, "NO DISTANCE", "BOWS, GUNS AND THROWN WEAPONS COUNT AS UP CLOSE, HOWEVER FAR THE FOE: EVERY CLOSE-RANGE BONUS HOLDS. +10% DAMAGE UP CLOSE.", false, [["hook", "ballistics", 1], ["hook", "close_dmg", 0.1]], "uncommon", ["edge"], {  }],
	["dex_agility", "shadow", 1, "FLEET FOOTWORK", "EVERY BONUS TO YOUR MOVE SPEED ALSO RAISES YOUR FIRE RATE.", false, [["hook", "agility", 1]], "rare", ["shadow"], {  }],
	["dex_alacrity", "edge", 1, "NIMBLE GRIP", "+40% FIRE RATE WITH WEAPONS THAT SCALE WITH DEX.", false, [["hook", "alacrity", 0.4]], "uncommon", ["edge"], {  }],
	["dex_ascetic", "shadow", 1, "STILL BREATH", "YOUR SPECIAL HITS 25% HARDER FOR EVERY ROLL CHARGE YOU HAVE.", false, [["hook", "special_per_roll", 0.25]], "uncommon", ["shadow"], {  }],
	["dex_bff", "fortune", 1, "BOSOM BUDDY", "YOUR HELPERS DEAL +300% DAMAGE WHILE YOU HAVE ONE, +200% WITH TWO, +100% WITH THREE.", false, [["hook", "bff", 3]], "rare", ["fortune", "swarm"], {  }],
	["dex_bloodinfection", "edge", 1, "TAINTED BLOOD", "EVERY TICK OF A BLEED ALSO POISONS THE FOE 5 TIMES. CRITS BLEED.", false, [["hook", "blood_poison", 1], ["add", "bleed", 0.25]], "uncommon", ["edge", "venom"], {  }],
	["dex_cheapshot", "fortune", 1, "LOW BLOW", "+5% LUCKY HITS. YOUR LUCKY HITS ARE LETHAL TOO: DOUBLE DAMAGE TO A FOE UNDER HALF HEALTH.", false, [["hook", "lucky", 0.05], ["hook", "cheap_shot", 1]], "uncommon", ["fortune"], {  }],
	["dex_chillaura", "shadow", 1, "WINTER COAT", "A FIELD OF FROST AROUND YOU CHILLS AND HURTS FOES.", false, [["hook", "halo_chill", 1]], "common", ["shadow", "frost"], {  }],
	["dex_cull", "edge", 1, "THIN THE HERD", "SLOWED FOES TAKE AS MUCH MORE DAMAGE AS THEY ARE SLOWED, WEAKENED ONES +30%. EVERY 4S IN A FIGHT THE WEAKEST FOE IS WEAKENED.", false, [["hook", "cull", 1], { "on": "every_n_seconds", "period": 4.0, "if": "fighting", "do": [["status_weakest", "weakened", 2]] }], "rare", ["edge"], {  }],
	["dex_toxins", "edge", 1, "VENOM SIGHT", "EVERY POISON STACK ON A FOE GIVES +1% CRIT CHANCE AGAINST IT. +10% POISON CHANCE.", false, [["hook", "toxin_crit", 0.01], { "on": "on_hit", "chance": 0.1, "do": [["status", "poison", 1]] }], "common", ["edge", "venom"], {  }],
	["dex_dynamo", "shadow", 1, "PERPETUAL MOTION", "EVERY BONUS TO YOUR MOVE SPEED ALSO RECHARGES YOUR ROLLS AND YOUR SPECIAL, TWICE OVER.", false, [["hook", "dynamo", 1]], "rare", ["shadow"], {  }],
	["dex_earnedluck", "fortune", 1, "SELF-MADE LUCK", "EVERY POINT OF DEX ALSO GIVES +2.5% LUCKY HITS.", false, [["hook", "lucky_dex", 0.025]], "rare", ["fortune"], {  }],
	["dex_electric", "edge", 1, "SPARK BRAND", "EVERY SHOCK STACK ON A FOE GIVES +25% CRIT DAMAGE AGAINST IT. 10% OF HITS SHOCK.", false, [["hook", "shock_critdmg", 0.25], { "on": "on_hit", "chance": 0.1, "do": [["status", "shock", 1]] }], "uncommon", ["edge", "storm"], {  }],
	["dex_exit", "shadow", 1, "CLEAN GETAWAY", "A ROLL MAKES EVERY FOE'S BURN AND BLEED LAST LONGER, AND ALL THEIR AILMENTS TICK ONCE FOR EVERY ROLL CHARGE YOU HAVE.", false, [["hook", "exit", 1]], "rare", ["shadow"], {  }],
	["dex_exploit", "edge", 1, "SHRAPNEL SENSE", "YOUR EXPLOSIONS LEAVE FOES VULNERABLE. +10% CHANCE YOUR HITS EXPLODE FOR 50%.", false, [["hook", "boom_vuln", 1], { "on": "on_hit", "chance": 0.1, "cd": 0.15, "do": [["explode", 22, 0.5]] }], "common", ["edge", "demolition"], {  }],
	["dex_grenadier", "edge", 1, "POCKET GRENADES", "EVERY 4S IN A FIGHT YOU LOB A GRENADE AT A FOE FOR 300%.", false, [{ "on": "every_n_seconds", "period": 4.0, "if": "fighting", "do": [["lob", 3.0, 30]] }], "uncommon", ["edge", "demolition"], {  }],
	["dex_harmony", "fortune", 1, "BALANCED BLADE", "+25% DAMAGE TO CURSED FOES, AND YOUR LUCKY HITS DEAL +25%. +5% CURSE CHANCE.", false, [["hook", "harmony", 1], ["add", "curse", 0.05]], "uncommon", ["fortune", "malice"], {  }],
	["dex_influence", "shadow", 1, "FIELD MARSHAL", "+30% FIRE RATE FOR YOU AND YOUR HELPERS FOR EVERY FIELD AROUND YOU.", false, [["hook", "influence", 0.3]], "rare", ["shadow"], {  }],
	["dex_illusion", "fortune", 1, "LOADED LUCK", "YOUR LUCKY HIT CHANCE ALSO ADDS TO YOUR CRIT DAMAGE, ONE AND A HALF TIMES (UP TO +250%).", false, [["hook", "illusion", 1]], "legend", ["fortune"], {  }],
	["dex_intuition", "edge", 1, "INSTINCT", "YOUR DEX COUNTS DOUBLE. YOUR STR AND INT COUNT HALF.", false, [["hook", "focus_dex", 1]], "rare", ["edge"], {  }],
	["dex_lethality", "edge", 1, "KILLING INSTINCT", "+15% LETHAL HITS: A LETHAL HIT ON A FOE UNDER HALF HEALTH USES YOUR CRIT DAMAGE INSTEAD OF DOUBLE.", false, [["hook", "lethal", 0.15], ["hook", "lethality", 1]], "rare", ["edge"], {  }],
	["dex_conductor", "edge", 1, "STORM CONDUIT", "25% OF YOUR HITS SEND LIGHTNING ARCING TO NEARBY FOES.", false, [{ "on": "on_hit", "chance": 0.25, "cd": 0.15, "do": [["chain", 0.8]] }], "uncommon", ["edge", "storm"], {  }],
	["dex_clockwork", "shadow", 1, "TICKING CLOCK", "EVERY BONUS TO YOUR FIRE RATE ALSO MAKES BURNS, POISONS AND BLEEDS TICK FASTER.", false, [["hook", "clockwork", 1]], "rare", ["shadow"], {  }],
	["dex_opportune", "shadow", 1, "OPPORTUNE", "FEWER THAN 4 FOES: +20% DAMAGE FROM AFAR. MORE THAN 2 FOES: +30% DAMAGE UP CLOSE.", false, [["hook", "opportune", 1]], "common", ["shadow"], {  }],
	["dex_pup", "fortune", 1, "GOOD DOG", "A PUP JOINS YOU (OR YOUR PET GROWS A LEVEL). YOUR TIMED BUFFS ARE 50% STRONGER.", false, [["pet", "biscuit", 0], ["hook", "buff_power", 0.5]], "uncommon", ["fortune"], {  }],
	["dex_pointblank", "edge", 1, "MUZZLE FLASH", "BOWS, GUNS AND THROWN WEAPONS: EVERY HIT UP CLOSE IS A CRUSHING HIT (+50%, WEARS PLATES FASTER).", false, [["hook", "point_blank", 1]], "uncommon", ["edge"], {  }],
	["dex_poisonaura", "shadow", 1, "TOXIC CLOUD", "A FIELD OF VENOM AROUND YOU POISONS FOES.", false, [["hook", "halo_poison", 1]], "common", ["shadow", "venom"], {  }],
	["dex_precision", "edge", 1, "BULLSEYE", "+5% CRIT CHANCE FOR EVERY RANK OF DEX TRAITS YOU HAVE.", false, [["hook", "crit_dex_rank", 0.05]], "rare", ["edge"], {  }],
	["dex_morale", "fortune", 1, "HIGH SPIRITS", "CLEARING A FIGHT WITHOUT A SCRATCH: +4% DAMAGE AND FIRE RATE FOR THE REST OF THE RUN (UP TO +40%).", false, [{ "on": "on_room_clear", "if": "unhurt", "do": [["stack", "dmg", 0.04, 0.4, "morale_d"], ["stack", "rate", 0.04, 0.4, "morale_r"], ["vfx", "label", "MORALE!", "#3cf06e"]] }], "uncommon", ["fortune"], {  }],
	["dex_repeat", "shadow", 1, "HABIT", "+10% CHANCE AN ATTACK REPEATS. FOR 4S AFTER A REPEAT, WHAT YOU INFLICT IS TWICE AS STRONG.", false, [["add", "echo", 0.1], ["hook", "repeat_debuff", 1]], "uncommon", ["shadow"], {  }],
	["dex_tally", "edge", 1, "COUNTING COUP", "EVERY 3RD ATTACK, THE HITS OF YOUR NEXT ATTACK ARE SURE CRITS.", false, [["hook", "tally", 1]], "rare", ["edge"], {  }],
	["dex_sharpshooter", "edge", 1, "FAR SIGHT", "FROM AFAR YOUR HITS ARE LETHAL: DOUBLE DAMAGE TO A FOE UNDER HALF HEALTH.", false, [["hook", "sharpshooter", 1]], "uncommon", ["edge"], {  }],
	["dex_spellblade", "shadow", 1, "SPELL EDGE", "UP TO +60% FIRE RATE WHILE YOUR SPECIAL RECHARGES: THE EMPTIER IT IS, THE FASTER YOU ATTACK.", false, [["hook", "spellblade", 0.6]], "uncommon", ["shadow", "arcane"], {  }],
	["dex_blades", "edge", 1, "WHIRLING BLADES", "+2 BLADE MOONS. A MOON'S HIT TEARS A FOE OPEN: IT BLEEDS, AND EVERY TEAR MAKES THE BLEED WORSE.", false, [["add", "orbitals", 2], ["hook", "moon_rupture", 1]], "legend", ["edge", "blood"], {  }],
	["dex_stepwind", "shadow", 1, "GUST STEP", "A ROLL GIVES YOU A TAILWIND: +25% MOVE SPEED AND +15% FIRE RATE FOR 4S.", false, [{ "on": "on_roll", "do": [["buff", "speed", 0.25, 4.0], ["buff", "rate", 0.15, 4.0]] }], "common", ["shadow"], {  }],
	["dex_swagger", "shadow", 1, "SHOWBOAT", "EVERY 4S IN A FIGHT, EVERYTHING THAT HAPPENS WHEN YOU ROLL HAPPENS AGAIN.", false, [["hook", "swagger", 1]], "legend", ["shadow"], {  }],
	["dex_triggermaniac", "fortune", 1, "WELL OILED", "YOUR ITEMS' EFFECTS HIT 10% HARDER FOR EVERY LEVEL YOUR WEAPON HAS BEEN UPGRADED.", false, [["hook", "proc_per_plus", 0.1]], "uncommon", ["fortune"], {  }],
	["dex_twosteps", "shadow", 1, "ONE STEP AHEAD", "AFTER A ROLL YOUR NEXT 2 ATTACKS REPEAT, AND THE REPEATS HIT TWICE AS HARD.", false, [["hook", "two_steps", 1]], "rare", ["shadow"], {  }],
	# 44.1: the list's infusion trait (his pictures, 10 Oct), with the infusions (infusions.gd).
	["dex_temper", "edge", 1, "ENDLESS INFUSION", "YOUR INFUSIONS NEVER WEAR OFF, AND THEY DEAL 25% MORE.", false, [["hook", "infuse_forever", 1], ["hook", "infuse_dmg", 0.25]], "rare", ["edge"], {  }],
	# 42.2 (his pictures, 10 Oct: a wiki's INTELLIGENCE traits; ideas only, our own names and pictures,
	# TRAITS_PLAN.md; scripts/combat/arcana.gd, tools/art/stage42_traits.py)
	["int_anatomy", "malice", 1, "SURGEON'S EYE", "YOUR CRITS ON A BLEEDING FOE DEAL +200% CRIT DAMAGE.", false, [["hook", "anatomy", 2.0]], "rare", ["malice", "blood"], {  }],
	["int_apocalypse", "pyre", 1, "CINDER RAIN", "USING YOUR SPECIAL CALLS DOWN 3 METEORS ON YOUR FOES (200% EACH).", false, [{ "on": "on_special", "do": [["meteor", 2.0, 36], ["meteor", 2.0, 36], ["meteor", 2.0, 36]] }], "legend", ["pyre", "demolition"], {  }],
	["int_familiar", "swarm", 1, "SPELL SPRITE", "+1 WISP: AN ARCANE SPRITE FIGHTS AT YOUR SIDE. YOUR SPECIAL RECHARGES 15% FASTER.", false, [["add", "familiars", 1], ["hook", "special_haste", 0.15]], "uncommon", ["swarm", "arcane"], {  }],
	["int_astromancy", "arcane", 1, "STAR READER", "+5% LUCKY HIT CHANCE, AND EVERY LUCKY HIT STRIKES 2 MORE TIMES.", false, [["hook", "lucky", 0.05], ["hook", "lucky_extra", 2]], "rare", ["arcane", "fortune"], {  }],
	["int_bramble", "venom", 1, "THORN BLOOM", "YOUR POISON ALSO MAKES FOES BLEED. +8 THORNS.", false, [["hook", "poison_bleed", 1], ["add", "thorns", 8]], "common", ["venom", "blood"], {  }],
	["int_burnaura", "pyre", 1, "EMBER MANTLE", "A FIELD OF FIRE AROUND YOU BURNS FOES, 4 TIMES A SECOND.", false, [["hook", "halo_burn", 1], ["hook", "pulse_burn", 3]], "common", ["pyre"], {  }],
	["int_chrono", "arcane", 1, "TIME SLIP", "USING YOUR SPECIAL MAKES BURNS, POISONS AND BLEEDS TICK TWICE AS FAST FOR 10S.", false, [["hook", "time_slip", 1]], "uncommon", ["arcane"], {  }],
	["int_coldblood", "frost", 1, "BRITTLE FROST", "+20% CRIT CHANCE AGAINST CHILLED FOES. +10% CHILL CHANCE.", false, [["hook", "chill_crit", 0.2], ["add", "chill", 0.1]], "common", ["frost"], {  }],
	["int_combustion", "pyre", 1, "FLASHPOINT", "YOUR BURNS DEAL +100% DAMAGE AND OFTEN SPREAD TO A FOE NEARBY.", false, [["add", "burn_dmg", 1.0], ["add", "burn_leap", 0.25]], "uncommon", ["pyre"], {  }],
	["int_corrosive", "venom", 1, "EATING ACID", "POISONING A FOE MAKES IT VULNERABLE. +10% CHANCE YOUR HITS POISON.", false, [["hook", "poison_vuln", 1], { "on": "on_hit", "chance": 0.1, "do": [["status", "poison", 1]] }], "uncommon", ["venom"], {  }],
	["int_dominance", "arcane", 1, "COMMANDING MIND", "EVERY INT POINT: +1.25% TO YOUR TIMED BUFFS AND TO YOUR FIELDS' REACH.", false, [["hook", "buff_int", 0.0125], ["hook", "aura_int", 0.0125]], "rare", ["arcane"], {  }],
	["int_dreamer", "arcane", 1, "DAYDREAM", "UP TO +100 POWER: THE FULLER YOUR SPECIAL'S CHARGE, THE MORE.", false, [["hook", "dreamer", 100]], "uncommon", ["arcane"], {  }],
	["int_balance", "storm", 1, "ELEMENT WHEEL", "EVERY BURN YOU INFLICT ALSO CHILLS, EVERY CHILL SHOCKS, AND EVERY SHOCK BURNS.", false, [["hook", "elem_wheel", 1]], "rare", ["storm", "pyre", "frost"], {  }],
	["int_focus", "arcane", 1, "FOCUSED ELEMENTS", "YOUR FIELDS AND YOUR SPECIAL BURN, CHILL AND SHOCK TWICE AS HARD.", false, [["hook", "elem_focus", 1]], "uncommon", ["arcane"], {  }],
	["int_entropy", "arcane", 1, "UNRAVELING", "+15% SPECIAL RECHARGE. EVERY BONUS TO IT ALSO MAKES BURNS, POISONS AND BLEEDS TICK FASTER.", false, [["hook", "special_haste", 0.15], ["hook", "entropy", 1]], "rare", ["arcane"], {  }],
	["int_horizon", "arcane", 1, "WIDE ORBIT", "+1 MOON. YOUR MOONS CIRCLE TWICE AS FAR OUT AND LEAVE FOES VULNERABLE.", false, [["add", "orbitals", 1], ["hook", "wide_orbit", 1]], "uncommon", ["arcane"], {  }],
	["int_forethought", "arcane", 1, "FORESIGHT", "+1 ARMOR NOW, AND +2 ARMOR AT THE START OF EVERY FLOOR.", false, [["grant", "armor", 1], { "on": "on_floor_start", "do": [["armor", 2]] }], "common", ["arcane", "bulwark"], {  }],
	["int_hextouch", "malice", 1, "WITCH'S MARK", "+15% CURSED HIT CHANCE: A CURSED HIT CURSES ITS FOE. CURSED FOES TAKE +15% MORE FROM YOU.", false, [["hook", "cursed_hit", 0.15], ["hook", "curse_dmg", 0.15]], "common", ["malice"], {  }],
	["int_iceconj", "frost", 1, "ICE VOLLEY", "35% OF YOUR ATTACKS ALSO FIRE 3 ICE SHARDS (50% EACH) THAT CHILL.", false, [{ "on": "on_shoot", "chance": 0.35, "do": [["fan_shots", 3, 0.5, "frost"]] }], "common", ["frost"], {  }],
	["int_ignition", "pyre", 1, "BLAZING BLASTS", "YOUR EXPLOSIONS DEAL +50% AND SET FOES ON FIRE. +10% CHANCE YOUR HITS EXPLODE FOR 50%.", false, [["hook", "ignition", 0.5], { "on": "on_hit", "chance": 0.1, "cd": 0.15, "do": [["explode", 22, 0.5]] }], "common", ["pyre", "demolition"], {  }],
	["int_insight", "arcane", 1, "DEEP THOUGHT", "YOUR SPECIAL HITS 25% HARDER FOR EVERY INT TRAIT YOU HOLD.", false, [["hook", "insight", 0.25]], "rare", ["arcane"], {  }],
	["int_inspiring", "swarm", 1, "RALLYING MIND", "+10 POWER. YOUR POWER ALSO RAISES YOUR HELPERS' DAMAGE, TWICE OVER.", false, [["hook", "power", 10], ["hook", "inspire", 2.0]], "uncommon", ["swarm"], {  }],
	["int_keenmind", "arcane", 1, "MIND OVER MUSCLE", "YOUR INT COUNTS DOUBLE. YOUR STR AND DEX COUNT HALF.", false, [["hook", "focus_int", 1]], "rare", ["arcane"], {  }],
	["int_twice", "storm", 1, "THUNDER TWICE", "EVERY LIGHTNING STRIKE STRIKES AGAIN HALF A SECOND LATER. +8% CHANCE YOUR HITS CALL LIGHTNING.", false, [["hook", "thunder_twice", 1], ["add", "storm", 0.08]], "rare", ["storm"], {  }],
	["int_mageblood", "venom", 1, "ALCHEMIST'S BLOOD", "+1 POTION. EVERY POTION YOU DRINK GIVES +5% DAMAGE FOR THE REST OF THE RUN (UP TO +50%).", false, [["grant", "potions", 1], { "on": "on_potion", "do": [["stack", "dmg", 0.05, 0.5, "alch_blood"]] }], "uncommon", ["venom"], {  }],
	["int_beacon", "swarm", 1, "MIND BEACON", "YOUR HELPERS DEAL UP TO +50% DAMAGE: THE FULLER YOUR SPECIAL'S CHARGE, THE MORE.", false, [["hook", "mind_beacon", 0.5]], "uncommon", ["swarm"], {  }],
	["int_leaf", "venom", 1, "THISTLE THROW", "EVERY 3RD ATTACK ALSO THROWS A THISTLE (150%) THAT PIERCES AND POISONS.", false, [{ "on": "every_n_shots", "every": 3, "do": [["fan_shots", 1, 1.5, "venom"]] }], "common", ["venom"], {  }],
	["int_normaldist", "arcane", 1, "BELL CURVE", "+5% LUCKY HIT CHANCE. YOUR LUCKY HIT CHANCE ALSO SPEEDS UP YOUR MOONS AND HOW FAST BURNS, POISONS AND BLEEDS TICK.", false, [["hook", "lucky", 0.05], ["hook", "bell_curve", 1]], "rare", ["arcane", "fortune"], {  }],
	["int_pocket", "arcane", 1, "SPARE WAND", "EVERY SECOND IN A FIGHT, A SHOOTING WEAPON IN YOUR BACKPACK FIRES AT A FOE ON ITS OWN.", false, [{ "on": "every_n_seconds", "period": 1.0, "if": "fighting", "do": [["pocket_cast"]] }], "rare", ["arcane"], {  }],
	["int_powerhungry", "malice", 1, "HUNGRY MIND", "+1 ARMOR NOW. +20 POWER FOR EVERY ARMOR YOU HAVE (UP TO +100).", false, [["grant", "armor", 1], ["hook", "hungry", 20]], "uncommon", ["malice", "bulwark"], {  }],
	["int_prodigy", "arcane", 1, "WUNDERKIND", "+10% LUCKY HIT CHANCE. YOUR LUCKY HITS COME HALF AGAIN AS OFTEN, AND YOUR CURSED HIT CHANCE IS DOUBLED.", false, [["hook", "lucky", 0.1], ["hook", "lucky_mult", 0.5], ["hook", "curse_x2", 1]], "legend", ["arcane", "fortune"], {  }],
	["int_shockaura", "storm", 1, "STORM MANTLE", "A FIELD OF LIGHTNING AROUND YOU SHOCKS AND HURTS FOES, 4 TIMES A SECOND.", false, [["hook", "halo_shock", 1], ["hook", "pulse_shock", 3]], "common", ["storm"], {  }],
	["int_staticblows", "storm", 1, "BRIMMING STATIC", "25% OF YOUR HITS SHOCK. A FOE AT FULL SHOCK DISCHARGES: LIGHTNING ON UP TO 4 FOES AROUND IT.", false, [["hook", "static_buildup", 1], { "on": "on_hit", "chance": 0.25, "do": [["status", "shock", 1]] }], "uncommon", ["storm"], {  }],
	["int_strongtogether", "swarm", 1, "PACK MIND", "+2 WISPS AND ROOM FOR 2 MORE HELPERS, BUT YOUR HELPERS HIT HALF AS HARD.", false, [["add", "familiars", 2], ["hook", "minion_cap", 2], ["hook", "pack_mind", 1]], "rare", ["swarm"], {  }],
	["int_thaum", "arcane", 1, "THIRD ECHO", "EVERY 3RD ATTACK, YOUR NEXT ATTACK REPEATS.", false, [["hook", "third_echo", 1]], "uncommon", ["arcane"], {  }],
	["int_trickery", "malice", 1, "CHEAP TRICKS", "+20% SNEAKY HIT CHANCE FOR EVERY COMMON PIECE OF GEAR YOU WEAR. A SNEAKY HIT DEALS +60%.", false, [["hook", "trickery", 0.2]], "rare", ["malice", "shadow"], {  }],
	["int_vision", "arcane", 1, "VISION", "EVERY 30TH ATTACK SETS OFF EVERYTHING YOUR SPECIAL SETS OFF AND GIVES +100% DAMAGE FOR 8S.", false, [{ "on": "every_n_shots", "every": 30, "do": [["trigger", "on_special"], ["buff", "dmg", 1.0, 8]] }], "rare", ["arcane"], {  }],
	["int_zoo", "swarm", 1, "MENAGERIE", "YOU AND YOUR HELPERS DEAL +5% DAMAGE FOR EVERY HELPER YOU HAVE.", false, [["hook", "menagerie", 0.05]], "uncommon", ["swarm"], {  }],
	# 43.2 (his pictures, 10 Oct: a wiki's Super Hero, Esper and Cyborg traits; ideas only, our own names
	# and pictures, TRAITS_PLAN.md; scripts/combat/marvels.gd, tools/art/stage43_traits.py). SUPER: every
	# hero; PSYCHIC (psy_): the Mindwarden's own; AUGMENT (aug_): the Tinkerer's own (TraitRules.HERO_ONLY).
	["sup_protection", "bulwark", 1, "IRONCLAD SOUL", "+5 ARMOR NOW, AND +1 ARMOR AFTER EVERY ROOM.", false, [["grant", "armor", 5], ["add", "armor_regen", 1]], "super", ["bulwark"], {  }],
	["sup_fortune", "fortune", 1, "BORN LUCKY", "+5 LUCK. +25% GOLD. +2 KEYS.", false, [["add", "luck", 5], ["mul", "gold_mult", 1.25], ["grant", "keys", 2]], "super", ["fortune"], {  }],
	["sup_reflexes", "shadow", 1, "BLURRED MOTION", "+20 DEX. COUNTS AS 6 MORE SHADOW RANKS.", false, [["attr", "dex", 20]], "super", ["shadow"], {  }],
	["sup_health", "bulwark", 1, "EVERLASTING", "+3 MAX HEARTS. YOUR HEARTS FILL UP AGAIN AFTER EVERY FIGHT.", false, [["add", "max_hp", 6], { "on": "on_room_clear", "do": [["heal", 40]] }], "super", ["bulwark"], {  }],
	["sup_rich", "fortune", 1, "ENDLESS WEALTH", "+100 GOLD. EVERYTHING THAT GROWS WITH YOUR GOLD COUNTS IT AS AT LEAST 1000.", false, [["grant", "gold", 100], ["hook", "purse", 1]], "super", ["fortune"], {  }],
	["sup_smarts", "arcane", 1, "BRAINSTORM", "+20 INT. COUNTS AS 6 MORE ARCANE RANKS.", false, [["attr", "int", 20]], "super", ["arcane"], {  }],
	["sup_speed", "shadow", 1, "WINDRUNNER", "+75% MOVE SPEED AND +20% FIRE RATE.", false, [["mul", "speed", 1.75], ["mul", "rate", 1.2]], "super", ["shadow"], {  }],
	["sup_stamina", "shadow", 1, "TIRELESS", "+3 ROLLS. YOUR ROLLS RECHARGE TWICE AS FAST.", false, [["add", "dodge_charges", 3], ["mul", "dodge_cd", 0.5]], "super", ["shadow"], {  }],
	["sup_strength", "fury", 1, "MOUNTAIN MOVER", "+20 STR. COUNTS AS 6 MORE FURY RANKS.", false, [["attr", "str", 20]], "super", ["fury"], {  }],
	["sup_charged", "storm", 1, "STORMBORN", "EVERY ROLL STRIKES UP TO 12 FOES WITH LIGHTNING. IN A FIGHT, LIGHTNING STRIKES A FOE EVERY 0.67S.", false, [{ "on": "on_roll", "do": [["bolts", 12, 1.0]] }, { "on": "every_n_seconds", "period": 0.67, "if": "fighting", "do": [["bolts", 1, 0.8]] }], "super", ["storm"], {  }],
	["sup_devoted", "core", 1, "SAINT AND SINNER", "+4 GOOD, EVIL, LAWFUL AND CHAOTIC. ONCE EVERY FLOOR YOU RISE AGAIN FROM DEATH. CURSES CANNOT HURT YOU.", false, [["add", "al_good", 4], ["add", "al_evil", 4], ["add", "al_law", 4], ["add", "al_chaos", 4], ["grant", "revive", 1], ["hook", "revive_floor", 1], ["hook", "no_curse", 1]], "super", ["fortune"], {  }],
	["sup_drunkard", "fury", 1, "BOTTOMLESS TANKARD", "+30 TIPSY CAP, +2 DRINK SLOTS. YOU DOWN 4 RANDOM DRINKS NOW, AND ANOTHER AT THE START OF EVERY FLOOR.", false, [["hook", "tipsy_cap", 30], ["hook", "drink_slots", 2], ["drinks", "", 4], { "on": "on_floor_start", "do": [["drink_random", 1]] }], "super", ["fury"], {  }],
	["sup_friendly", "swarm", 1, "BELOVED", "+3 WISPS AND ROOM FOR 3 MORE HELPERS. YOUR HELPERS DEAL +100% DAMAGE.", false, [["add", "familiars", 3], ["hook", "minion_cap", 3], ["hook", "minion_dmg", 1.0]], "super", ["swarm"], {  }],
	["sup_lazy", "malice", 1, "LAZY GENIUS", "+25% DAMAGE FOR EVERY EMPTY GEAR SLOT (UP TO +250%). IN A FIGHT, EVERY FOE WITHERS EVERY HALF SECOND: CURSED AND VULNERABLE.", false, [["hook", "idle_hands", 0.25], { "on": "every_n_seconds", "period": 0.5, "if": "fighting", "do": [["status_area", "curse", 1, 500], ["status_area", "vulnerable", 1, 500]] }], "super", ["malice"], {  }],
	["sup_engine", "arcane", 1, "ARCANE ENGINE", "YOUR SPECIAL RECHARGES 3 TIMES AS FAST. EVERY TIME YOU USE IT: +1 STR, DEX AND INT.", false, [["hook", "special_haste", 2.0], { "on": "on_special", "do": [["attrs", 1]] }], "super", ["arcane"], {  }],
	["psy_energy", "malice", 1, "UNMAKING FIELD", "+30 POWER. A FIELD AROUND YOU UNMAKES FOES: IT CURSES THEM AND LEAVES THEM VULNERABLE.", false, [["hook", "power", 30], ["hook", "halo_wither", 1]], "rare", ["malice", "arcane"], {  }],
	["psy_lightning", "storm", 1, "MIND LIGHTNING", "A FOE CAN HOLD 4 MORE SHOCK. EVERY 3RD ATTACK, A PSI BOLT STRIKES A FOE (150%).", false, [["hook", "shock_max", 4], { "on": "every_n_shots", "every": 3, "do": [["lightning", 1.5]] }], "uncommon", ["storm"], {  }],
	["psy_knives", "malice", 1, "KITCHEN KNIVES", "+3 MOONS: KNIVES THAT MAKE FOES BLEED. EVERY MOON MAKES BLEEDS TICK 10% FASTER.", false, [["add", "orbitals", 3], ["hook", "moon_rupture", 1], ["hook", "bleed_moon", 1]], "uncommon", ["malice", "blood"], {  }],
	["psy_link", "swarm", 1, "MIND LINK", "A QUARTER OF YOUR HELPERS' DAMAGE BONUS IS YOURS TOO. WITH EXACTLY ONE HELPER, IT DEALS +400%.", false, [["hook", "mind_link", 0.25]], "rare", ["swarm"], {  }],
	["psy_rifle", "edge", 1, "HAND-ME-DOWNS", "+20% CRIT CHANCE WITH BOWS AND GUNS. +2 WISPS. +75% CRIT DAMAGE.", false, [["hook", "ranged_crit", 0.2], ["add", "familiars", 2], ["add", "crit_mult", 0.75]], "uncommon", ["edge", "swarm"], {  }],
	["psy_bombard", "arcane", 1, "MIND STORM", "STANDING STILL, YOUR BURNS, POISONS AND BLEEDS TICK 50% FASTER. EVERY 2S IN A FIGHT, 5 PSI BOLTS STRIKE RANDOM FOES (100% EACH).", false, [["hook", "still_ticks", 0.5], { "on": "every_n_seconds", "period": 2.0, "if": "fighting", "do": [["bolts", 5, 1.0]] }], "rare", ["arcane", "storm"], {  }],
	["psy_combust", "pyre", 1, "INNER FIRE", "EVERY BURN TICK ALSO TAKES 1% OF A FOE'S HEALTH (LESS FROM BOSSES). 10% OF YOUR HITS BURST INTO FLAME (100%).", false, [["hook", "burn_pct", 0.01], { "on": "on_hit", "chance": 0.1, "cd": 0.15, "do": [["explode", 24, 1.0], ["status", "burn", 1]] }], "rare", ["pyre"], {  }],
	["psy_complexion", "frost", 1, "WEATHER WITCH", "IN A FIGHT, EVERY FOE BURNS EVERY 8S, CHILLS EVERY 4S, IS SHOCKED EVERY 2S AND POISONED EVERY SECOND.", false, [{ "on": "every_n_seconds", "period": 8.0, "if": "fighting", "do": [["status_area", "burn", 1, 500]] }, { "on": "every_n_seconds", "period": 4.0, "if": "fighting", "do": [["status_area", "chill", 1, 500]] }, { "on": "every_n_seconds", "period": 2.0, "if": "fighting", "do": [["status_area", "shock", 1, 500]] }, { "on": "every_n_seconds", "period": 1.0, "if": "fighting", "do": [["status_area", "poison", 1, 500]] }], "rare", ["frost", "pyre", "storm", "venom"], {  }],
	["psy_marionettes", "swarm", 1, "PUPPET STRINGS", "+2 WISPS AND ROOM FOR 2 MORE HELPERS, BUT YOUR HELPERS DEAL ONLY 30% OF THEIR DAMAGE.", false, [["add", "familiars", 2], ["hook", "minion_cap", 2], ["hook", "marionette", 1]], "uncommon", ["swarm"], {  }],
	["psy_randomness", "fortune", 1, "DICE MIND", "EVERY ROOM YOU CLEAR HANDS YOU A RANDOM DIE. EVERY DIE YOU HAVE USED THIS RUN: +2.5% LUCKY HIT CHANCE.", false, [{ "on": "on_room_clear", "do": [["dice", "any", 1]] }, ["hook", "dice_mind", 0.025]], "rare", ["fortune"], {  }],
	["psy_dilation", "arcane", 1, "SLOW TIME", "EVERY TIME YOU USE YOUR SPECIAL: +10% SPECIAL POWER FOR THE REST OF THE RUN (UP TO +200%), AND YOUR DRINKS AND INFUSIONS LAST A ROOM LONGER.", false, [["hook", "dilation", 1]], "legend", ["arcane"], {  }],
	["aug_freeze", "frost", 1, "CRYO CORE", "YOUR SPECIAL'S BLOWS CHILL AND DEAL +50% DAMAGE.", false, [["hook", "cryo_core", 0.5]], "uncommon", ["frost"], {  }],
	["aug_laser", "storm", 1, "BEAM CORE", "USING YOUR SPECIAL FIRES A BEAM AT A FOE EVERY 0.4S FOR 8S (80% EACH).", false, [["hook", "laser_core", 1]], "rare", ["storm"], {  }],
	["aug_lucky", "fortune", 1, "CHANCE CORE", "USING YOUR SPECIAL MAKES EVERY HIT LUCKY FOR 8S.", false, [{ "on": "on_special", "do": [["lucky_rush", 8]] }], "uncommon", ["fortune"], {  }],
	["aug_mana", "arcane", 6, "FLUX CORE", "+20% SPECIAL RECHARGE A RANK (UP TO +120%).", false, [["hook", "special_haste", 0.2]], "common", ["arcane"], {  }],
	["aug_power", "demolition", 1, "OVERDRIVE CORE", "+10 POWER. YOUR POWER ALSO RAISES YOUR SPECIAL'S DAMAGE, 1% A POINT.", false, [["hook", "power", 10], ["hook", "power_core", 1]], "rare", ["demolition"], {  }],
	# Stage 53 (his word, 11 Oct: "Add new level up traits to pick matching the new additions, also add new effects and
	# mechanic make it very cool and satisfying"): traits for the five damage types and their reactions, SPIRIT and LUCK,
	# the toybox and the SOULS (souls.gd), and an OATH OF SOULS (its vow in oaths.gd).
	["q_sunspot", "arcane", 3, "SUNSPOT", "8% OF HITS SEAR. SEARED FOES TAKE +15% DAMAGE", false, [{ "on": "on_hit", "chance": 0.08, "do": [["status", "seared", 1]] }, ["hook", "vs_seared", 0.15]], "uncommon", ["arcane"], {  }],
	["q_dawnburst", "arcane", 1, "DAWNBURST", "SEARED FOES BURST TWICE AS WIDE. A BURST HEALS HALF A HEART (EVERY 6S)", false, [["hook", "sear_wide", 1], ["hook", "sear_heal", 1]], "rare", ["arcane", "bulwark"], {  }],
	["q_gravemoss", "malice", 3, "GRAVE MOSS", "8% OF HITS ROT. ROT STACKS 5 HIGHER", false, [{ "on": "on_hit", "chance": 0.08, "do": [["status", "rot", 1]] }, ["hook", "rot_max", 5]], "uncommon", ["malice", "venom"], {  }],
	["q_lichtouch", "malice", 1, "LICH TOUCH", "KILLING A ROTTING FOE SPREADS ITS ROT TO THE FOES NEAR IT", false, [["hook", "rot_spread", 1]], "rare", ["malice"], {  }],
	["q_longshadow", "shadow", 3, "LONG SHADOWS", "10% OF HITS GLOOM TWICE. +10% CRIT ON FOES IN DEEP GLOOM", false, [{ "on": "on_hit", "chance": 0.1, "do": [["status", "gloom", 2]] }, ["hook", "gloom_crit", 0.1]], "uncommon", ["shadow"], {  }],
	["q_livewire", "storm", 3, "OPEN CIRCUIT", "8% OF HITS CHARGE. A DISCHARGE LEAPS AS LIGHTNING TO 2 FOES", false, [{ "on": "on_hit", "chance": 0.08, "do": [["status", "charged", 1]] }, ["hook", "discharge_chain", 2]], "uncommon", ["storm"], {  }],
	["q_capacitor", "storm", 1, "CAPACITOR", "FOES DISCHARGE AT 3 CHARGES, NOT 5, IN A BLAST TWICE AS WIDE", false, [["hook", "charge_fast", 1]], "rare", ["storm", "demolition"], {  }],
	["q_bassdrop", "fury", 2, "BASS DROP", "EVERY 4S IN A FIGHT, A BEAT RATTLES EVERY FOE NEAR YOU", false, [{ "on": "every_n_seconds", "period": 4.0, "if": "fighting", "do": [["status_area", "rattled", 1, 110], ["vfx", "ring", "#f4ecd8", 110]] }], "uncommon", ["fury"], {  }],
	["q_resonance", "fury", 1, "RESONANCE", "RATTLED FOES TAKE +4% DAMAGE FOR EACH STACK", false, [["hook", "vs_rattle", 0.04]], "rare", ["fury", "edge"], {  }],
	["q_fivefold", "core", 1, "FIVEFOLD PATH", "12% OF HITS SEAR, ROT, GLOOM, CHARGE OR RATTLE. REACTIONS +30%", false, [{ "on": "on_hit", "chance": 0.12, "cd": 0.05, "do": [["new_ailment", 1]] }, ["hook", "react_dmg", 0.3]], "legend", ["arcane", "malice"], {  }],
	["q_totaleclipse", "shadow", 1, "ECLIPSE CHAIN", "AN ECLIPSE SEARS AND GLOOMS EVERY FOE NEAR IT, SO MORE FOLLOW", false, [["hook", "eclipse_spread", 1]], "legend", ["shadow", "arcane"], {  }],
	["q_conductor", "storm", 1, "THUNDER RELAY", "SUPERCONDUCT AND OVERLOAD ALSO STRIKE 3 FOES WITH LIGHTNING", false, [["hook", "react_chain", 1]], "rare", ["storm"], {  }],
	["q_plaguewind", "venom", 1, "PLAGUE WIND", "BLIGHT SPREADS TWICE AS FAR, AND POISONS TOO", false, [["hook", "blight_far", 1]], "rare", ["venom", "malice"], {  }],
	["q_kindred", "arcane", 3, "KINDRED SPIRIT", "+2 SPIRIT", false, [["attr", "spi", 2]], "common", ["arcane"], {  }],
	["q_spiritfire", "pyre", 1, "SPIRIT FIRE", "YOUR SPECIAL'S BLOWS SEAR AND BURN. +2 SPIRIT", false, [["hook", "spirit_fire", 1], ["attr", "spi", 2]], "rare", ["pyre", "arcane"], {  }],
	["q_ladyluck", "fortune", 3, "LADY LUCK", "+2 LUCK", false, [["attr", "lck", 2]], "common", ["fortune"], {  }],
	["q_highroller", "fortune", 1, "BIG SPENDER", "+1 REROLL. EVERY REROLL: +4% DAMAGE FOR THE RUN (UP TO +40%)", false, [["add", "rerolls", 1], { "on": "on_reroll", "do": [["stack", "dmg", 0.04, 0.4, "highroller"]] }], "rare", ["fortune"], {  }],
	["q_sharkweek", "swarm", 1, "SHARK WEEK", "EVERY 8TH KILL CALLS A LAND SHARK", false, [{ "on": "on_kill", "every": 8, "do": [["toy", "shark", 1.0]] }], "rare", ["swarm", "fury"], {  }],
	["q_dancefloor", "arcane", 1, "DANCE FLOOR", "EVERY 10S IN A FIGHT, A DISCO BALL TURNS OVER YOU", false, [{ "on": "every_n_seconds", "period": 10.0, "if": "fighting", "do": [["toy", "disco", 0.8]] }], "rare", ["arcane", "fortune"], {  }],
	["q_anvilrain", "demolition", 1, "ANVIL RAIN", "WHEN HIT, AN ANVIL FALLS ON A FOE (EVERY 3S)", false, [{ "on": "on_damage_taken", "cd": 3.0, "do": [["toy", "anvil", 1.2]] }], "rare", ["demolition", "bulwark"], {  }],
	["q_pincushion", "malice", 2, "PIN CUSHION", "12% OF CRITS STICK A VOODOO PIN IN THE FOE", false, [{ "on": "on_crit", "chance": 0.12, "do": [["toy", "pin", 1.0]] }], "uncommon", ["malice", "edge"], {  }],
	["q_backdoor", "edge", 1, "BACK DOOR", "EVERY 6TH ATTACK ALSO STRIKES FROM A PORTAL BEHIND THE FOE", false, [{ "on": "every_n_shots", "every": 6, "do": [["toy", "portal", 0.8]] }], "rare", ["edge", "arcane"], {  }],
	["q_soulbound", "core", 1, "SOULBOUND", "A SOUL SURGE NEEDS 20 SOULS, NOT 30", false, [["hook", "soul_fast", 1]], "rare", ["malice"], {  }],
	["q_harvest", "malice", 2, "SOUL FEAST", "EVERY SOUL: +1% DAMAGE FOR 6S, STACKING", false, [{ "on": "on_soul", "do": [["buff", "dmg", 0.01, 6.0]] }], "uncommon", ["malice"], {  }],
	["q_soulstorm", "storm", 1, "SOUL STORM", "A SOUL SURGE ALSO CALLS 8 LIGHTNING STRIKES", false, [{ "on": "on_surge", "do": [["bolts", 8, 1.2]] }], "legend", ["storm", "malice"], {  }],
	["q_spiritwell", "arcane", 1, "SPIRIT WELL", "EVERY SOUL SURGE: +1 SPIRIT FOR THE RUN, AND YOUR SPECIAL IS READY", false, [{ "on": "on_surge", "do": [["spirit", 1], ["ready_special"]] }], "legend", ["arcane"], {  }],
	["q_wispwarden", "swarm", 2, "WISP WARDEN", "EVERY 10TH SOUL CALLS A WISP THAT FIGHTS FOR 8S", false, [{ "on": "on_soul", "every": 10, "do": [["summon", 8.0]] }], "uncommon", ["swarm"], {  }],
	["q_soulavatar", "malice", 1, "AVATAR OF SOULS", "SURGES NEED 15 SOULS, HIT TWICE AS HARD, AND SEAR, ROT AND RATTLE EVERY FOE", false, [["hook", "soul_avatar", 1], ["hook", "surge_dmg", 1.0], { "on": "on_surge", "do": [["status_area", "seared", 1, 999], ["status_area", "rot", 3, 999], ["status_area", "rattled", 2, 999]] }], "mythic", ["malice", "arcane"], {  }],
	["o_souls", "core", 1, "OATH OF SOULS", "SOULS COUNT DOUBLE. A SOUL SURGE HEALS HALF A HEART", false, [["hook", "soul_mult", 1], ["hook", "surge_heal", 1]], "oath", ["malice", "arcane"], {  }],
]

const TREE_COSTS := [10, 20, 35, 60, 100, 150]   # (48.3: the fifth and sixth skills of a branch)
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
	"minstrel": { "name": "SONGCRAFT", "nodes": [["CRESCENDO", "ENTERING A ROOM: +25% DAMAGE FOR 5S"], ["ECHOING NOTE", "EVERY 10TH ATTACK FIRES 4 EXTRA SHOTS"], ["STEADY RHYTHM", "+10% FIRE RATE"], ["STANDING OVATION", "KILLING AN ELITE HEALS A HEART"]] },
	"jester": { "name": "TOMFOOLERY", "nodes": [["LOADED DICE", "+1 LUCK"], ["HAT TRICK", "ROLLING THROWS 6 KNIVES (EVERY 3S)"], ["SLAPSTICK", "15% OF HITS STUN FOR A MOMENT"], ["THE PUNCHLINE", "CRITS ROLL A RANDOM WILD EFFECT (EVERY 3S)"]] },
	"berserker": { "name": "BLOODLUST", "nodes": [["THICK SKIN", "+1 MAX HEART"], ["RECKLESS", "+15% DAMAGE"], ["BATTLE TRANCE", "KILLS HEAL HALF A HEART 5% OF THE TIME"], ["UNSTOPPABLE", "WHEN HIT, +40% DAMAGE FOR 3S"]] },
	"forsaken": { "name": "SURVIVAL", "nodes": [["ROUGH HANDS", "+1 STR AND +1 DEX"], ["SCROUNGE", "CLEARING A ROOM PAYS 3 GOLD"], ["HARDENED", "EVERY NEW FLOOR GIVES 1 ARMOR"], ["NOTHING LEFT", "BELOW HALF HEALTH: +50% DAMAGE"]] },
	"clockmaker": { "name": "CLOCKWORK", "nodes": [["MAINSPRING", "ENTERING A ROOM: +30% FIRE RATE FOR 6S"], ["ESCAPEMENT", "EVERY 20TH SHOT CHILLS THE FOES NEAR YOU"], ["BALANCE WHEEL", "+1 MAX HEART"], ["GRAND COMPLICATION", "ROLLING SLOWS EVERY FOE SHOT NEAR YOU (EVERY 6S)"]] },
	"inkling": { "name": "INKCRAFT", "nodes": [["INK BLOTS", "10% MORE OF YOUR HITS LEAVE INK"], ["SKETCHBOOK", "+1 WISP"], ["WET PAGES", "+60% POISON DAMAGE"], ["MASTERPIECE", "EVERY 8S IN A FIGHT, A SKETCHED WISP JOINS YOU FOR 8S"]] },
	"mindwarden": { "name": "THE STILL FIELD", "nodes": [["FOCUS", "+2 INT"], ["CLEAR SKY", "+20% AURA REACH"], ["ECHOING MIND", "HALOS PULSE 20% FASTER"], ["THE WIDE WORLD", "EVERY HALO PULSE ALSO HITS THE FOES IN IT FOR 40%"]] },
	"tavernknight": { "name": "THE TAPROOM", "nodes": [["STRONG BREW", "DRINKS GIVE +1 MORE TIPSY"], ["BARREL CHEST", "+1 MAX HEART"], ["SLOW SIPPER", "TIPSY WEARS OFF HALF AS FAST"], ["CLOSING TIME", "EVERY ROOM YOU ENTER POURS YOU AN ALE (+2 TIPSY)"]] },
	"trickshot": { "name": "SLEIGHT OF HAND", "nodes": [["DEFT", "+2 DEX"], ["STACKED ODDS", "+5% LUCKY HITS"], ["LOADED CAST", "CASTS FROM THE SPELL SLOT HIT 30% HARDER"], ["ACE UP THE SLEEVE", "EVERY 6S IN A FIGHT, A FREE CAST FROM THE SPELL SLOT"]] },
	"bonecaller": { "name": "THE BONEYARD", "nodes": [["MARROW", "+1 INT. +10% COMPANION DAMAGE"], ["BRISK BONES", "+20% COMPANION ATTACK SPEED"], ["GRAVE DUST", "+8% MOVE SPEED"], ["THE LONG MARCH", "EVERY 1% OF EXTRA MOVE SPEED GIVES COMPANIONS +1% MORE ATTACK SPEED"]] },
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
	# 10.3
	"CRESCENDO": [{"on": "on_room_enter", "do": [["buff", "dmg", 0.25, 5.0]]}],
	"ECHOING NOTE": [{"on": "every_n_shots", "every": 10, "do": [["shoot", 4, 0.6, "", 0.3]]}],
	"STEADY RHYTHM": [["mul", "rate", 1.1]],
	"STANDING OVATION": [{"on": "on_kill", "if": "elite", "do": [["heal", 2]]}],
	"LOADED DICE": [["add", "luck", 1]],
	"HAT TRICK": [{"on": "on_roll", "cd": 3.0, "do": [["nova", 6, 0.6, "spark"]]}],
	"SLAPSTICK": [{"on": "on_hit", "chance": 0.15, "do": [["status", "stun", 1]]}],
	"THE PUNCHLINE": [{"on": "on_crit", "cd": 3.0, "do": [["chaos"]]}],
	"THICK SKIN": [["add", "max_hp", 2], ["add", "hp", 2]],
	"RECKLESS": [["mul", "dmg", 1.15]],
	"BATTLE TRANCE": [{"on": "on_kill", "chance": 0.05, "do": [["heal", 1]]}],
	"UNSTOPPABLE": [{"on": "on_damage_taken", "do": [["buff", "dmg", 0.4, 3.0]]}],
	"ROUGH HANDS": [["attr", "str", 1], ["attr", "dex", 1]],
	"SCROUNGE": [{"on": "on_room_clear", "do": [["gold", 3]]}],
	"HARDENED": [{"on": "on_floor_start", "do": [["armor", 1]]}],
	"NOTHING LEFT": [{"on": "while_low_hp", "do": [["buff", "dmg", 0.5, 0]]}],
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
	"INK BLOTS": [{"on": "on_hit", "chance": 0.1, "cd": 0.4, "do": [["zone", "ink", 20, 3.0]]}],   # 18.2 the Inkling
	"SKETCHBOOK": [["add", "familiars", 1]],
	"WET PAGES": [["add", "poison_dmg", 0.6]],
	"MASTERPIECE": [{"on": "every_n_seconds", "period": 8.0, "if": "fighting", "do": [["summon", 8.0]]}],
	"FOCUS": [["attr", "int", 2]],   # 33.1 the Mindwarden
	"CLEAR SKY": [["hook", "aura_reach", 0.2]],
	"ECHOING MIND": [["hook", "aura_speed", 0.2]],
	"THE WIDE WORLD": [["hook", "aura_strike", 0.4]],
	"STRONG BREW": [["hook", "tipsy_gain", 1]],   # 33.2 the Tavern Knight
	"BARREL CHEST": [["add", "max_hp", 2], ["add_cap", "hp", 2, "max_hp"]],
	"SLOW SIPPER": [["hook", "tipsy_slow", 1.0]],
	"CLOSING TIME": [{ "on": "on_room_enter", "do": [["tipsy", 2]] }],
	"DEFT": [["attr", "dex", 2]],   # 34.1 the Trickshot
	"STACKED ODDS": [["hook", "lucky", 0.05]],
	"LOADED CAST": [["hook", "slot_dmg", 0.3]],
	"ACE UP THE SLEEVE": [{ "on": "every_n_seconds", "period": 6.0, "if": "fighting", "do": [["slot_cast"]] }],
	"MARROW": [["attr", "int", 1], ["hook", "minion_dmg", 0.1]],   # 34.2 the Bonecaller
	"BRISK BONES": [["hook", "minion_speed", 0.2]],
	"GRAVE DUST": [["mul", "speed", 1.08]],
	"THE LONG MARCH": [["hook", "march", 1.0]],
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
	# 48.3: the fifth and sixth skills (tree_for)
	"DEADLY RHYTHM": [["mul", "rate", 1.1], ["add", "crit", 0.05]],
	"MASTER'S TOUCH": [["mul", "dmg", 1.15]],
	"IRON WILL": [["add", "max_hp", 2], ["add", "hp", 2], ["add", "armor", 1]],
	"LONG ROAD": [["hook", "gourd_sips", 1]],
	"MASTERY": [["hook", "special_haste", 0.2]],
	"LEGEND": [["mul", "dmg", 1.1], ["add", "max_hp", 2], ["add", "hp", 2]],
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
				"tiers": row[9] if row.size() > 9 else {}, "more": [] }
			# 43.7: an old trait's one more effect and its sentence (TraitRevamp), expanded game only.
			if not DebugArgs.has("classic") and TraitRevamp.MORE.has(t["id"]):
				var more: Array = TraitRevamp.MORE[t["id"]]
				t["base_desc"] = String(t["desc"]).trim_suffix(".")
				t["more_text"] = more[0]
				t["desc"] = t["base_desc"] + ". " + more[0]
				t["more"] = more[1]
			_list.append(t)
			_by_id[t["id"]] = t
	return _list

static func by_id(id: String) -> Dictionary:
	all()
	return _by_id[id]

static func has(id: String) -> bool:
	all()
	return _by_id.has(id)

## 48.3 (his word, 10 Oct: "expand and reset ... hero trees"): two more skills on each branch in the
## expanded game (classic keeps four); a hero's tree can be reset for its embers (Game.update_tree).
const SKILL_MORE := [[["DEADLY RHYTHM", "+10% FIRE RATE AND +5% CRIT"], ["MASTER'S TOUCH", "+15% DAMAGE"]],
	[["IRON WILL", "+1 MAX HEART AND 1 ARMOR"], ["LONG ROAD", "THE GOURD HOLDS ONE MORE SIP"]]]
const HERO_MORE := [["MASTERY", "YOUR SKILL RECHARGES 20% FASTER"], ["LEGEND", "+10% DAMAGE AND +1 MAX HEART"]]
static var _grown := {}

static func tree_for(hero_id: String) -> Array:
	var base: Array = SKILL_BRANCHES + [HERO_BRANCH[hero_id]]
	if not GameData.rogues():
		return base
	if not _grown.has(hero_id):
		var out := []
		for bi in base.size():
			var b: Dictionary = base[bi].duplicate(true)
			b["nodes"] = b["nodes"] + (SKILL_MORE[bi] if bi < 2 else HERO_MORE)
			out.append(b)
		_grown[hero_id] = out
	return _grown[hero_id]

## What a hero's tree cost, for its reset.
static func tree_spent(owned: Array) -> int:
	var n := 0
	for bi in owned.size():
		for ni in int(owned[bi]):
			n += TREE_COSTS[mini(ni, TREE_COSTS.size() - 1)]
	return n

## One rank of a trait. tier_effects (new traits) add extra effects when a
## given rank is reached, e.g. { 3: [...] }. An old trait's "more" (43.7) comes with every rank.
static func apply(id: String, p: Player) -> void:
	var t := by_id(id)
	Effects.apply(p, t["effects"], 1, "trait:" + id)
	if GameData.rogues() and not t.get("more", []).is_empty():   # 43.7 (TraitRevamp)
		Effects.apply(p, t["more"], 1, "trait+:" + id)
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
