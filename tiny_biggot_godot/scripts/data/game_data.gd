class_name GameData
extends RefCounted
## Game data: heroes, enemies, bosses, floors, room kinds (port of Data.rb and
## the room/xp tables from 01b_traits.rb). Relics, traits, weapons and gear
## live in their own data scripts.

const HEROES := [
	{ "id": "hexer", "name": "THE HEXER", "sprite": "hexer", "blurb": "A crypt witch. Slow hex bolts that curve toward foes.",
	  "weapon": "HEX BOLTS", "hp": 6, "speed": 86, "shot": "hex", "sound": "shoot", "cost": 0,
	  "stats": { "dmg": 4.0, "rate": 3.2, "shot_speed": 150.0, "life": 1.0, "homing": 2.2, "size": 1.0, "pierce": 0 } },
	{ "id": "poacher", "name": "THE POACHER", "sprite": "poacher", "blurb": "A grave robber with a repeating crossbow. Fast and fragile.",
	  "weapon": "REPEATER", "hp": 6, "speed": 96, "shot": "bolt", "sound": "bolt", "cost": 0,
	  "stats": { "dmg": 2.0, "rate": 6.5, "shot_speed": 270.0, "life": 0.75, "homing": 0.0, "size": 1.0, "pierce": 1 } },
	{ "id": "brute", "name": "THE BRUTE", "sprite": "brute", "blurb": "A pit fighter. Hurls heavy hatchets at close range. Tough.",
	  "weapon": "HATCHETS", "hp": 10, "speed": 80, "shot": "hatchet", "sound": "hatchet", "cost": 0,
	  "stats": { "dmg": 8.0, "rate": 1.8, "shot_speed": 180.0, "life": 0.72, "homing": 0.0, "size": 1.6, "pierce": 2 } },
	{ "id": "gravedigger", "name": "THE GRAVEDIGGER", "sprite": "gravedigger", "blurb": "Flings a spray of grave dirt. Starts with extra bombs.",
	  "weapon": "DIRT SPRAY", "hp": 8, "speed": 84, "shot": "clod", "sound": "hatchet", "cost": 40,
	  "stats": { "dmg": 2.4, "rate": 2.4, "shot_speed": 220.0, "life": 0.55, "homing": 0.0, "size": 1.0, "pierce": 0, "count": 4, "spread": 0.16 },
	  "start": { "bombs": 3 } },
	{ "id": "alchemist", "name": "THE ALCHEMIST", "sprite": "alchemist", "blurb": "Throws flasks that burst and poison everything nearby.",
	  "weapon": "FLASKS", "hp": 6, "speed": 88, "shot": "flask", "sound": "shoot", "cost": 80,
	  "stats": { "dmg": 5.0, "rate": 2.0, "shot_speed": 160.0, "life": 0.85, "homing": 0.0, "size": 1.0, "pierce": 0 } },
	{ "id": "warden", "name": "THE WARDEN", "sprite": "warden", "blurb": "A lantern keeper. Hurls a blazing lantern that flies back.",
	  "weapon": "LANTERN", "hp": 8, "speed": 84, "shot": "boomer", "sound": "hatchet", "cost": 140,
	  "stats": { "dmg": 4.5, "rate": 2.0, "shot_speed": 210.0, "life": 0.9, "homing": 0.0, "size": 1.2, "pierce": 99 } },
]

## Design spec step 6: new heroes, added after the six originals (which stay
## exactly as they are). Extra fields: "passive" (shown on the hero screen),
## "effects" (applied at the start of every run, effect-system data), "trait"
## (a starting trait at rank 1), "special" (active ability, scripts/combat/abilities.gd)
## and "new". Sprites are recoloured copies of
## original heroes: placeholders until real art exists.
const NEW_HEROES := [
	# A starter (cost 0: free from the first run). An escapee who lives on momentum:
	# tempo and rally are in scripts/combat/tempo.gd and rally.gd, the leap in abilities.gd.
	{ "id": "gaolbird", "name": "THE GAOLBIRD", "sprite": "gaolbird", "new": true,
	  "blurb": "Flew the coop at Blackrock Gaol in a crow mask and has not stood still since.",
	  "passive": "TEMPO: BLOWS AND KILLS BUILD UP TO 10 TEMPO, +2.5% SPEED AND +4% FIRE RATE EACH. AT 10: +20% CRIT, ROLLS CUT FOES. IT FADES IF YOU STOP HITTING, A HIT HALVES IT. RALLY: AFTER A HIT, LAND 6 BLOWS IN 3S TO WIN THE HEART BACK. ROLL THROUGH A FOE TO EXPOSE IT.",
	  "weapon": "IRON TALONS", "hp": 6, "speed": 94, "shot": "slash", "sound": "hatchet", "cost": 0, "trait": "sh_blur", "hud": "tempo",
	  "stats": { "dmg": 3.6, "rate": 3.6, "shot_speed": 0.0, "life": 0.0, "homing": 0.0, "size": 1.0, "pierce": 99 },
	  "effects": [["set", "tempo_max", 10], ["set", "rally_n", 6], ["hook", "roll_expose", 1]],
	  "special": { "name": "TALON DIVE", "cd": 7, "col": "#e86fb4",
		"desc": "LEAP UP AND CRASH DOWN ON THE FOE YOU AIM AT: 300% TO ALL NEARBY, STUN, EXPOSE, ERASE SHOTS, +2 TEMPO. UNTOUCHABLE IN THE AIR.",
		"do": [["leap", 460, 150, [["explode", 46, 3.0], ["status_area", "stun", 1, 52], ["status_area", "vulnerable", 1, 52],
			["clear_shots", 52], ["tempo", 2], ["vfx", "slam", "#e86fb4", 50]]]] } },
	{ "id": "banehunter", "name": "THE BANE HUNTER", "sprite": "banehunter", "new": true,
	  "blurb": "A scarred hunter of monsters. Lives off bounties and bitter oils.",
	  "passive": "+25% DAMAGE TO ELITES. A POTION ALSO OILS YOUR BLADE: +40% DAMAGE FOR 10S. EVERY 6S A ROLL CASTS A SIGN: A RING OF SPARKS THAT STUNS THE NEAREST FOE.",
	  "weapon": "BANE SABRE", "hp": 8, "speed": 88, "shot": "slash", "sound": "hatchet", "cost": 160, "trait": "g_bounty",
	  "stats": { "dmg": 8.0, "rate": 2.6, "shot_speed": 0.0, "life": 0.0, "homing": 0.0, "size": 1.0, "pierce": 99 },
	  "effects": [["add", "elite_mult", 0.25],
		{ "on": "on_potion", "do": [["buff", "dmg", 0.4, 10.0], ["vfx", "label", "BLADE OILED", "#f2c94c"], ["vfx", "ring", "#f2c94c", 30]] },
		{ "on": "on_roll", "cd": 6.0, "do": [["nova", 8, 0.5, "spark"], ["status", "stun", 1], ["vfx", "sigil", "#f2c94c", 30]] }],
	  "special": { "name": "BURNING SIGIL", "cd": 12, "col": "#f2c94c",
		"desc": "A HUGE SIGIL BLASTS EVERY FOE NEAR YOU FOR 250%, STUNS THEM, SETS THEM ABLAZE AND ERASES SHOTS.",
		"do": [["vfx", "sigil", "#f2c94c", 72], ["explode", 72, 2.5], ["status_area", "stun", 1, 80],
			["status_area", "burn", 2, 80], ["clear_shots", 72]] } },
	{ "id": "oathbreaker", "name": "THE OATHBREAKER", "sprite": "oathbreaker", "new": true,
	  "blurb": "A disgraced knight with a slab of iron far too big to be a sword.",
	  "passive": "RAGE: EVERY KILL GIVES +6% DAMAGE FOR 5S, AND IT STACKS. BELOW HALF HEALTH: +30% DAMAGE AND +20% FIRE RATE.",
	  "weapon": "IRON SLAB", "hp": 10, "speed": 80, "shot": "slash", "sound": "hatchet", "cost": 200, "trait": "f_anger",
	  "stats": { "dmg": 16.0, "rate": 0.9, "shot_speed": 0.0, "life": 0.0, "homing": 0.0, "size": 1.0, "pierce": 99 },
	  "effects": [{ "on": "on_kill", "do": [["buff", "dmg", 0.06, 5.0]] },
		{ "on": "while_low_hp", "do": [["buff", "dmg", 0.3, 0], ["buff", "rate", 0.2, 0]] }],
	  "special": { "name": "IRON CYCLONE", "cd": 11, "col": "#d8443c",
		"desc": "SPIN THE SLAB FOR 2S: A WHIRLWIND THAT HITS EVERYTHING AROUND YOU FOR 90% FIVE TIMES A SECOND. UNTOUCHABLE WHILE SPINNING.",
		"do": [["vfx", "spin", "#d9d0b4", 2.0], ["invuln", 2.0], ["channel", 2.0, 0.2, [["area", 40, 0.9], ["clear_shots", 34]]]] } },
	{ "id": "wayfarer", "name": "THE WAYFARER", "sprite": "wayfarer", "new": true,
	  "blurb": "A wandering swordsman who answers every blow with a cleaner one.",
	  "passive": "+10% CRIT. PERFECT DODGE: ROLLING WHILE A SHOT IS CLOSE REFUNDS THE ROLL AND GIVES +60% DAMAGE FOR 1.5S.",
	  "weapon": "WAYFARER'S EDGE", "hp": 6, "speed": 94, "shot": "slash", "sound": "hatchet", "cost": 180, "trait": "e_precise",
	  "stats": { "dmg": 6.0, "rate": 3.0, "shot_speed": 0.0, "life": 0.0, "homing": 0.0, "size": 1.0, "pierce": 99 },
	  "effects": [["add", "crit", 0.1], { "on": "on_roll", "if": "danger", "do": [["refund_roll"], ["buff", "dmg", 0.6, 1.5],
		["vfx", "label", "PERFECT!", "#6fd3e0"], ["vfx", "ring", "#6fd3e0", 36]] }],
	  "special": { "name": "FLASH STEP", "cd": 7, "col": "#6fd3e0",
		"desc": "BLINK FORWARD IN A FLASH, CUTTING EVERY FOE IN THE PATH FOR 400%. UNTOUCHABLE WHILE MOVING.",
		"do": [["vfx", "flash", "#ffffff", 0.08], ["dash", 900, 0.13, 4.0, [["vfx", "ring", "#6fd3e0", 30], ["vfx", "burst", "#6fd3e0", 14]]]] } },
	{ "id": "racketeer", "name": "THE RACKETEER", "sprite": "racketeer", "new": true,
	  "blurb": "A gutter boss with two snub guns. The more trouble, the more pay.",
	  "passive": "+10% GOLD. HEAT: CLEARING A ROOM RAISES HEAT (MAX 5). EACH LEVEL GIVES +8% DAMAGE AND +10% GOLD. GETTING HIT LOSES 2 HEAT.",
	  "weapon": "SNUB GUNS", "hp": 6, "speed": 92, "shot": "bolt", "sound": "bolt", "cost": 220, "trait": "g_skim", "hud": "heat",
	  "stats": { "dmg": 2.4, "rate": 2.0, "shot_speed": 260.0, "life": 0.75, "homing": 0.0, "size": 1.0, "pierce": 0 },
	  "effects": [["mul", "gold_mult", 1.1], { "on": "on_room_clear", "do": [["heat", 1]] }, { "on": "on_damage_taken", "do": [["heat", -2]] }],
	  "special": { "name": "LEAD RAIN", "cd": 12, "col": "#f2c94c",
		"desc": "EMPTY EVERY GUN FOR 2S: A SPIRAL OF 8 SHOTS EVERY 0.15S. +1 HEAT.",
		"do": [["heat", 1], ["channel", 2.0, 0.15, [["nova", 8, 0.55, "bolt", 2.5]]]] } },
	{ "id": "condemned", "name": "THE CONDEMNED", "sprite": "condemned", "new": true,
	  "blurb": "A prisoner the crypt refuses to keep dead. Grabs whatever weapon is near.",
	  "passive": "UNDYING: RISES ONCE PER RUN. EVERY FLOOR, READS A RANDOM SCROLL (DAMAGE, RATE, HEART OR CRIT). SWAPPING WEAPONS GIVES +50% DAMAGE FOR 8S.",
	  "weapon": "SHACKLE FLAIL", "hp": 6, "speed": 88, "shot": "whip", "sound": "hatchet", "cost": 240, "trait": "f_thickskull",
	  "stats": { "dmg": 5.5, "rate": 2.0, "shot_speed": 0.0, "life": 0.0, "homing": 0.0, "size": 1.0, "pierce": 99 },
	  "effects": [["add", "revive", 1], { "on": "on_floor_start", "do": [["scroll"]] },
		{ "on": "on_weapon_swap", "do": [["buff", "dmg", 0.5, 8.0], ["vfx", "label", "FRESH STEEL", "#d8443c"]] }],
	  "special": { "name": "BREAK THE CHAINS", "cd": 14, "col": "#8b8f9c",
		"desc": "SHATTER YOUR SHACKLES: 2S UNTOUCHABLE, ERASE NEARBY SHOTS, FLING 16 CHAIN LINKS AND GAIN +50% DAMAGE FOR 6S.",
		"do": [["vfx", "flash", "#ffffff", 0.2], ["vfx", "ring", "#8b8f9c", 90], ["invuln", 2.0], ["clear_shots", 120],
			["nova", 16, 1.0, "spark"], ["buff", "dmg", 0.5, 6.0]] } },
	{ "id": "cartomancer", "name": "THE CARTOMANCER", "sprite": "cartomancer", "new": true,
	  "blurb": "A card reader who deals fate in sharpened gilt.",
	  "passive": "IN A FIGHT, DRAWS A CARD EVERY 4S AND PLAYS IT: BLADES, STORM, SHIELD, MEND, STAR, WHEEL OR COIN.",
	  "weapon": "GILT DECK", "hp": 6, "speed": 90, "shot": "disc", "sound": "shoot", "cost": 260, "trait": "a_salvo",
	  "stats": { "dmg": 3.0, "rate": 2.6, "shot_speed": 200.0, "life": 1.6, "homing": 0.0, "size": 1.0, "pierce": 1 },
	  "effects": [{ "on": "every_n_seconds", "period": 4.0, "if": "fighting", "do": [["card"]] }],
	  "special": { "name": "STACKED DECK", "cd": 10, "col": "#d8443c",
		"desc": "DEAL THREE CARDS AT ONCE AND FAN 12 RAZOR CARDS AROUND YOU.",
		"do": [["card"], ["card"], ["card"], ["nova", 12, 0.8, "disc"]] } },
	{ "id": "sellsword", "name": "THE SELLSWORD", "sprite": "sellsword", "new": true,
	  "blurb": "A mercenary from far plains. Fights as if still on horseback.",
	  "passive": "CHARGE: ROLLS ARE FASTER AND TRAMPLE FOES FOR 250%. +1 ROLL CHARGE. STARTS WITH 1 ARMOR.",
	  "weapon": "WAR LANCE", "hp": 8, "speed": 86, "shot": "thrust", "sound": "hatchet", "cost": 120, "trait": "t_brace",
	  "stats": { "dmg": 7.5, "rate": 2.0, "shot_speed": 0.0, "life": 0.0, "homing": 0.0, "size": 1.0, "pierce": 99 },
	  "effects": [["set", "shadowstep", true], ["mul", "roll_speed", 1.25], ["add", "dodge_charges", 1], ["add", "charges", 1], ["add", "armor", 1]],
	  "special": { "name": "WAR CHARGE", "cd": 8, "col": "#e8873a",
		"desc": "A LONG CHARGE THAT TRAMPLES FOES FOR 300% AND ENDS IN A SHOCKWAVE FOR 200%.",
		"do": [["dash", 520, 0.4, 3.0, [["explode", 48, 2.0], ["vfx", "ring", "#e8873a", 50]]]] } },
	# ---------- ROADMAP 4.8: ten more heroes (his go, 6 Oct: "do complete stage 4") ----------
	{ "id": "beekeeper", "name": "THE BEEKEEPER", "sprite": "beekeeper", "new": true,
	  "blurb": "Keeps a hive under the floorboards of the crypt. The bees keep her.",
	  "passive": "THE HIVE: EVERY 4TH KILL CALLS A BEE (A WISP) FOR 20S. BEES DEAL +50%. +1 POISON ON HIT.",
	  "weapon": "HIVE SMOKER", "hp": 6, "speed": 88, "shot": "flame", "sound": "shoot", "cost": 140, "trait": "wispcall",
	  "stats": { "dmg": 1.4, "rate": 9.0, "shot_speed": 150.0, "life": 0.5, "homing": 0.0, "size": 1.0, "pierce": 1 },
	  "effects": [["add", "fam_dmg", 0.5], ["add", "poison", 1], { "on": "on_kill", "every": 4, "do": [["summon", 20.0], ["vfx", "label", "BZZZ!", "#f2c94c"]] }],
	  "special": { "name": "SWARM CALL", "cd": 12, "col": "#f2c94c",
		"desc": "CALL FIVE BEES FOR 12S AND POISON EVERY FOE NEAR YOU.",
		"do": [["summon", 12.0], ["summon", 12.0], ["summon", 12.0], ["summon", 12.0], ["summon", 12.0], ["status_area", "poison", 3, 90], ["vfx", "ring", "#f2c94c", 90]] } },
	{ "id": "tinkerer", "name": "THE TINKERER", "sprite": "tinkerer", "new": true,
	  "blurb": "Builds what the fight needs out of what the crypt throws away.",
	  "passive": "ROLLING SETS DOWN A RANDOM TURRET FOR 8S (EVERY 5S): A GUN, A FLAMER, A COIL, A FROST TOTEM, A SAW OR A MENDER.",
	  "weapon": "RIVET GUN", "hp": 6, "speed": 90, "shot": "bolt", "sound": "shoot", "cost": 160, "trait": "satchel",
	  "stats": { "dmg": 3.0, "rate": 4.5, "shot_speed": 260.0, "life": 0.9, "homing": 0.0, "size": 1.0, "pierce": 0 },
	  "effects": [{ "on": "on_roll", "cd": 5.0, "do": [["turret", "random", 8.0, 1.0]] }],
	  "special": { "name": "OVERCLOCK", "cd": 14, "col": "#6fd3e0",
		"desc": "TWO TESLA COILS WITH A BEAM BETWEEN THEM FOR 10S, AND +40% FIRE RATE FOR 5S.",
		"do": [["turret", "tesla", 10.0, 1.2], ["turret", "tesla", 10.0, 1.2], ["buff", "rate", 0.4, 5.0], ["vfx", "flash", "#6fd3e0", 0.15]] } },
	{ "id": "boneweaver", "name": "THE BONEWEAVER", "sprite": "boneweaver", "new": true,
	  "blurb": "Stitches the fallen back together. They are grateful, in their way.",
	  "passive": "A FIFTH OF THE FOES YOU KILL RISE AS YOUR SKELETONS FOR 10S. CURSED FOES ALWAYS RISE. 10% OF HITS CURSE.",
	  "weapon": "BONE STAFF", "hp": 6, "speed": 86, "shot": "orb", "sound": "shoot", "cost": 200, "trait": "carrion",
	  "stats": { "dmg": 4.0, "rate": 2.6, "shot_speed": 190.0, "life": 1.4, "homing": 1.0, "size": 1.0, "pierce": 0 },
	  "effects": [["add", "curse", 0.1], { "on": "on_kill", "chance": 0.2, "do": [["raise", 10.0, 0.9]] }, { "on": "on_kill", "if": "cursed", "do": [["raise", 10.0, 0.9]] }],
	  "special": { "name": "DANSE MACABRE", "cd": 13, "col": "#a35bd6",
		"desc": "FOUR SKELETONS CLAW THEIR WAY OUT AROUND YOU FOR 12S, AND EVERY FOE NEAR YOU IS CURSED.",
		"do": [["raise", 12.0, 1.2], ["raise", 12.0, 1.2], ["raise", 12.0, 1.2], ["raise", 12.0, 1.2], ["status_area", "curse", 2, 100], ["vfx", "sigil", "#a35bd6", 60]] } },
	{ "id": "mirrorknight", "name": "THE MIRROR KNIGHT", "sprite": "mirrorknight", "new": true,
	  "blurb": "Polished her armour until it learned to answer back.",
	  "passive": "ROLLING TURNS THE SHOTS NEAR YOU AROUND: THEY FLY BACK THE WAY THEY CAME, AS YOURS (EVERY 1S). STARTS WITH 1 ARMOR.",
	  "weapon": "BRIGHT BLADE", "hp": 8, "speed": 86, "shot": "slash", "sound": "hatchet", "cost": 180, "trait": "plating",
	  "stats": { "dmg": 7.0, "rate": 2.4, "shot_speed": 0.0, "life": 0.0, "homing": 0.0, "size": 1.0, "pierce": 99 },
	  "effects": [["add", "armor", 1], { "on": "on_roll", "cd": 1.0, "do": [["reflect", 55, 1.0]] }],
	  "special": { "name": "MIRROR WALL", "cd": 10, "col": "#c8d0e0",
		"desc": "EVERY SHOT NEAR YOU FLIES BACK THE WAY IT CAME FOR 150%, AND NOTHING TOUCHES YOU FOR 1S.",
		"do": [["reflect", 150, 1.5], ["invuln", 1.0], ["vfx", "ring", "#c8d0e0", 150]] } },
	{ "id": "plaguesaint", "name": "THE PLAGUE SAINT", "sprite": "plaguesaint", "new": true,
	  "blurb": "Tends the sick of the crypt. Mostly, she makes more of them.",
	  "passive": "+1 POISON ON HIT, 10% OF HITS CURSE. A POISONED FOE YOU KILL PASSES ALL ITS AILMENTS TO THE FOES NEAR IT.",
	  "weapon": "CENSER FLAIL", "hp": 6, "speed": 88, "shot": "whip", "sound": "hatchet", "cost": 200, "trait": "toxin",
	  "stats": { "dmg": 5.0, "rate": 2.2, "shot_speed": 0.0, "life": 0.0, "homing": 0.0, "size": 1.0, "pierce": 99 },
	  "effects": [["add", "poison", 1], ["add", "curse", 0.1], { "on": "on_kill", "if": "poisoned", "do": [["spread", 70]] }],
	  "special": { "name": "LAST RITES", "cd": 12, "col": "#b8e05a",
		"desc": "EVERY AILMENT ON EVERY FOE NEAR YOU IS USED UP AT ONCE, EACH FOR A HIT OF 80%.",
		"do": [["consume_area", 110, 0.8], ["vfx", "ring", "#b8e05a", 110]] } },
	{ "id": "frostwitch", "name": "THE FROST WITCH", "sprite": "frostwitch", "new": true,
	  "blurb": "Where she walks, even arrows think twice.",
	  "passive": "+20% CHILL CHANCE. CHILLED FOES TAKE +30% FROM YOU. EVERY 3S IN A FIGHT, THE SHOTS NEAR YOU SLOW TO HALF SPEED.",
	  "weapon": "ICICLE WAND", "hp": 6, "speed": 88, "shot": "orb", "sound": "shoot", "cost": 180, "trait": "chillbite",
	  "stats": { "dmg": 3.6, "rate": 3.0, "shot_speed": 210.0, "life": 1.3, "homing": 0.0, "size": 1.0, "pierce": 1 },
	  "effects": [["add", "chill", 0.2], ["add", "vs_chill", 0.3], { "on": "every_n_seconds", "period": 3.0, "if": "fighting", "do": [["slow_shots", 70, 0.5]] }],
	  "special": { "name": "BLIZZARD", "cd": 14, "col": "#9fc3ee",
		"desc": "EVERY FOE NEAR YOU FREEZES SOLID FOR 1S, IS CHILLED AND TAKES 150%. EVERY SHOT ON SCREEN SLOWS TO A CRAWL.",
		"do": [["status_area", "stun", 1, 170], ["status_area", "chill", 2, 170], ["area", 170, 1.5], ["slow_shots", 260, 0.3], ["vfx", "ring", "#9fc3ee", 170]] } },
	{ "id": "demolitionist", "name": "THE DEMOLITIONIST", "sprite": "demolitionist", "new": true,
	  "blurb": "Retired from the mines. The mines were glad.",
	  "passive": "A FREE BOMB EVERY 6S IN A FIGHT. BOMBS DEAL +40%, DRAG FOES IN AROUND THEM, AND CANNOT HURT YOU.",
	  "weapon": "BLAST MORTAR", "hp": 8, "speed": 84, "shot": "grenade", "sound": "shoot", "cost": 160, "trait": "blastradius",
	  "stats": { "dmg": 9.0, "rate": 1.1, "shot_speed": 0.0, "life": 0.0, "homing": 0.0, "size": 1.0, "pierce": 0 },
	  "effects": [["mul", "bomb_mult", 1.4], ["hook", "bomb_immune", 1], { "on": "every_n_seconds", "period": 6.0, "if": "fighting", "do": [["give", "bombs", 1]] },
		{ "on": "on_bomb", "do": [["pull", 90, 220]] }],
	  "special": { "name": "CARPET BOMB", "cd": 12, "col": "#e8873a",
		"desc": "FIVE SHELLS FALL ON FOES ACROSS THE ROOM, EACH A BLAST FOR 200% THAT LEAVES FIRE.",
		"do": [["meteor", 2.0, 30], ["meteor", 2.0, 30], ["meteor", 2.0, 30], ["meteor", 2.0, 30], ["meteor", 2.0, 30]] } },
	{ "id": "executioner", "name": "THE EXECUTIONER", "sprite": "executioner", "new": true,
	  "blurb": "Paid by the head. Never misses a payday.",
	  "passive": "DAMAGE PAST A KILL CARRIES ON TO THE NEAREST FOE. FOES BELOW 10% HEALTH DIE AT ONCE.",
	  "weapon": "HEADSMAN'S AXE", "hp": 8, "speed": 84, "shot": "slash", "sound": "hatchet", "cost": 220, "trait": "keenedge",
	  "stats": { "dmg": 12.0, "rate": 1.4, "shot_speed": 0.0, "life": 0.0, "homing": 0.0, "size": 1.0, "pierce": 99 },
	  "effects": [["hook", "execute", 0.1], { "on": "on_kill", "do": [["overkill", 1.0]] }],
	  "special": { "name": "GUILLOTINE", "cd": 9, "col": "#d8443c",
		"desc": "THE BLADE FALLS ON THE MOST WOUNDED FOE IN THE ROOM FOR 600%. BELOW A THIRD OF ITS HEALTH, IT DIES.",
		"do": [["execute_weakest", 6.0, 0.33]] } },
	{ "id": "pilgrim", "name": "THE PILGRIM", "sprite": "pilgrim", "new": true,
	  "blurb": "Walked into the crypt on purpose. Says it is on the way.",
	  "passive": "ENTERING A ROOM HEALS HALF A HEART. HEALING AT FULL HEALTH GIVES 1 ARMOR AND SENDS OUT A RING OF 10 STARS.",
	  "weapon": "PILGRIM'S STAFF", "hp": 6, "speed": 86, "shot": "pulse", "sound": "shoot", "cost": 140, "trait": "vitality",
	  "stats": { "dmg": 4.0, "rate": 1.8, "shot_speed": 0.0, "life": 0.0, "homing": 0.0, "size": 1.0, "pierce": 99 },
	  "effects": [{ "on": "on_room_enter", "do": [["heal", 1]] }, { "on": "on_overheal", "cd": 0.5, "do": [["armor", 1], ["nova", 10, 0.8, "spark"]] }],
	  "special": { "name": "SANCTUARY", "cd": 16, "col": "#f2c94c",
		"desc": "HEAL A HEART, NOTHING TOUCHES YOU FOR 2S, FOES ARE HURLED AWAY AND THE SHOTS NEAR YOU VANISH.",
		"do": [["heal", 2], ["invuln", 2.0], ["push", 120, 320], ["clear_shots", 120], ["vfx", "flash", "#fffbe0", 0.2]] } },
	{ "id": "beastmaster", "name": "THE BEASTMASTER", "sprite": "beastmaster", "new": true,
	  "blurb": "Speaks to anything with teeth. Some of it listens.",
	  "passive": "18% OF HITS TAME AN ORDINARY FOE FOR 8S: IT TURNS AND FIGHTS FOR YOU.",
	  "weapon": "BEAST SPEAR", "hp": 8, "speed": 90, "shot": "thrust", "sound": "hatchet", "cost": 200, "trait": "packtactics",
	  "stats": { "dmg": 7.0, "rate": 2.2, "shot_speed": 0.0, "life": 0.0, "homing": 0.0, "size": 1.0, "pierce": 99 },
	  "effects": [{ "on": "on_hit", "chance": 0.18, "do": [["charm", 8.0]] }],
	  "special": { "name": "CALL OF THE WILD", "cd": 12, "col": "#7a5236",
		"desc": "EVERY ORDINARY FOE NEAR YOU IS TAMED FOR 10S AND FIGHTS FOR YOU.",
		"do": [["charm_area", 100, 10.0], ["vfx", "ring", "#e8873a", 100]] } },
	# 6.4 (his ask, 6 Oct): a hero who keeps time.
	{ "id": "clockmaker", "name": "THE CLOCKMAKER", "sprite": "clockmaker", "new": true,
	  "blurb": "Keeps every clock in the Spire wound. Lately, they keep him.",
	  "passive": "TICK-TOCK: EVERY 12TH SHOT SLOWS EVERY FOE SHOT NEAR YOU FOR A MOMENT AND LOOSES A RING OF 8 GEARS.",
	  "weapon": "GEARWOUND REPEATER", "hp": 6, "speed": 90, "shot": "bolt", "sound": "shoot", "cost": 200, "trait": "sh_blur",
	  "stats": { "dmg": 2.6, "rate": 5.5, "shot_speed": 260.0, "life": 0.9, "homing": 0.0, "size": 1.0, "pierce": 0 },
	  "effects": [{ "on": "every_n_shots", "every": 12, "do": [["slow_shots", 120, 0.5], ["nova", 8, 0.8, "bolt"]] }],
	  "special": { "name": "REWIND", "cd": 14, "col": "#e8b84a",
		"desc": "HEALS A HEART, 2S UNTOUCHABLE, AND +40% FIRE RATE FOR 5S.",
		"do": [["heal", 2], ["invuln", 2.0], ["buff", "rate", 0.4, 5.0], ["vfx", "ring", "#e8b84a", 90]] } },
	# 10.3 (his ask, 6 Oct, from his trailer clips: ideas only, this game's own heroes).
	{ "id": "minstrel", "name": "THE MINSTREL", "sprite": "minstrel", "new": true,
	  "blurb": "Plays the taverns between the floors. The dead are a tough crowd.",
	  "passive": "ENCORE: EVERY 3S IN A FIGHT, A BURST OF 8 NOTES AND +10% FIRE RATE FOR 2S.",
	  "weapon": "SINGING LUTE", "hp": 6, "speed": 90, "shot": "hex", "sound": "shoot", "cost": 160, "trait": "w_choir",
	  "stats": { "dmg": 3.4, "rate": 3.2, "shot_speed": 200.0, "life": 1.0, "homing": 0.6, "size": 1.0, "pierce": 0 },
	  "effects": [{ "on": "every_n_seconds", "period": 3.0, "if": "fighting", "do": [["nova", 8, 0.6, "spark"], ["buff", "rate", 0.1, 2.0]] }],
	  "special": { "name": "BALLAD", "cd": 14, "col": "#e86fb4",
		"desc": "A SONG: HEAL A HEART, +30% DAMAGE, +30% FIRE RATE AND +20% MOVE SPEED FOR 6S.",
		"do": [["heal", 2], ["buff", "dmg", 0.3, 6.0], ["buff", "rate", 0.3, 6.0], ["buff", "speed", 0.2, 6.0], ["vfx", "ring", "#e86fb4", 90]] } },
	{ "id": "jester", "name": "THE JESTER", "sprite": "jester", "new": true,
	  "blurb": "Juggles knives at funerals. Nobody laughs. He laughs.",
	  "passive": "WILD CARD: 15% OF HITS STRIKE A RANDOM AILMENT.",
	  "weapon": "JUGGLING PINS", "hp": 6, "speed": 96, "shot": "hatchet", "sound": "hatchet", "cost": 160, "trait": "g_skim",
	  "stats": { "dmg": 5.0, "rate": 2.4, "shot_speed": 180.0, "life": 1.0, "homing": 0.0, "size": 1.0, "pierce": 1 },
	  "effects": [{ "on": "on_hit", "chance": 0.15, "do": [["rand_status", 1]] }],
	  "special": { "name": "PRATFALL", "cd": 12, "col": "#a35bd6",
		"desc": "TWO RANDOM WILD EFFECTS, AND 1S UNTOUCHABLE.",
		"do": [["chaos"], ["chaos"], ["invuln", 1.0], ["vfx", "ring", "#a35bd6", 80]] } },
	{ "id": "berserker", "name": "THE BERSERKER", "sprite": "berserker", "new": true,
	  "blurb": "Came down the stairs for the fight. Stayed for the next one.",
	  "passive": "FRENZY: EVERY KILL GIVES +5% DAMAGE FOR 4S.",
	  "weapon": "GREAT AXE", "hp": 10, "speed": 86, "shot": "hatchet", "sound": "hatchet", "cost": 180, "trait": "t_hulk",
	  "stats": { "dmg": 12.0, "rate": 1.6, "shot_speed": 0.0, "life": 0.0, "homing": 0.0, "size": 1.2, "pierce": 99 },
	  "effects": [{ "on": "on_kill", "do": [["buff", "dmg", 0.05, 4.0]] }],
	  "special": { "name": "WAR CRY", "cd": 13, "col": "#d8443c",
		"desc": "STUN EVERY FOE NEAR YOU AND +50% DAMAGE FOR 5S.",
		"do": [["status_area", "stun", 1, 90], ["buff", "dmg", 0.5, 5.0], ["vfx", "ring", "#d8443c", 90]] } },
	{ "id": "forsaken", "name": "THE FORSAKEN", "sprite": "forsaken", "new": true,
	  "blurb": "Starts with nothing. Owes nothing. The hardest way down.",
	  "passive": "SCAVENGER: 2 HEARTS AND A RUSTY SHIV. KILLS DROP A STAT PICKUP 4% OF THE TIME.",
	  "weapon": "RUSTY SHIV", "hp": 4, "speed": 94, "shot": "hatchet", "sound": "hatchet", "cost": 220, "trait": "g_skim",
	  "stats": { "dmg": 4.0, "rate": 2.6, "shot_speed": 0.0, "life": 0.0, "homing": 0.0, "size": 0.9, "pierce": 99 },
	  "effects": [{ "on": "on_kill", "chance": 0.04, "do": [["drop", "stat"]] }],
	  "special": { "name": "DESPERATION", "cd": 12, "col": "#8b8f9c",
		"desc": "LOSE HALF A HEART: +60% DAMAGE FOR 5S AND 2S UNTOUCHABLE.",
		"do": [["hurt_self", 1], ["buff", "dmg", 0.6, 5.0], ["invuln", 2.0], ["vfx", "ring", "#8b8f9c", 80]] } },
	# 18.2 (his ask, 7 Oct: "a new hero"): from the story (STORY.md), the drop of ink loose from the page.
	{ "id": "inkling", "name": "THE INKLING", "sprite": "inkling_hero", "new": true,
	  "blurb": "A drop of ink that got loose from the page. Now it writes its own story.",
	  "passive": "INK: A FIFTH OF YOUR HITS LEAVE A POOL OF INK THAT POISONS. HALF OF THE POISONED FOES YOU KILL RISE AS SKETCHED WISPS FOR 6S.",
	  "weapon": "INKWELL QUILL", "hp": 6, "speed": 92, "shot": "orb", "sound": "shoot", "cost": 250, "trait": "z_hexback",
	  "stats": { "dmg": 3.4, "rate": 3.4, "shot_speed": 220.0, "life": 1.1, "homing": 0.5, "size": 1.0, "pierce": 0 },
	  "effects": [{ "on": "on_hit", "chance": 0.2, "cd": 0.4, "do": [["zone", "ink", 20, 3.0]] },
		{ "on": "on_kill", "if": "poisoned", "chance": 0.5, "do": [["summon", 6.0], ["vfx", "label", "SKETCHED!", "#9ab8ff"]] }],
	  "special": { "name": "SKETCH", "cd": 11, "col": "#9ab8ff",
		"desc": "DRAW THREE INK WISPS FOR 10S AND FLOOD THE GROUND ROUND YOU WITH INK: EVERY FOE NEAR YOU IS POISONED.",
		"do": [["summon", 10.0], ["summon", 10.0], ["summon", 10.0], ["status_area", "poison", 3, 100], ["zone", "ink", 40, 4.0], ["vfx", "ring", "#2a2a4a", 100]] } },
	# 33.1 (his word, 9 Oct: the INT aura build, "walk to the exit while everything dies"). Ideas only.
	{ "id": "mindwarden", "name": "THE MINDWARDEN", "sprite": "mindwarden_hero", "new": true,
	  "blurb": "A quiet mind with a loud field. Things that come too close simply stop.",
	  "passive": "PSIONIC FIELD: STARTS WITH INNER LIGHT. EVERY POINT OF INT GIVES +2% MORE AURA REACH AND +2% AURA DAMAGE.",
	  "weapon": "THOUGHTSTONE", "hp": 6, "speed": 90, "shot": "orb", "sound": "shoot", "cost": 260, "trait": "k_innerlight",
	  "stats": { "dmg": 3.0, "rate": 3.0, "shot_speed": 170.0, "life": 1.0, "homing": 1.5, "size": 1.0, "pierce": 0 },
	  "effects": [["hook", "aura_int", 0.02], ["hook", "aura_int_dmg", 0.02]],
	  "special": { "name": "MIND SPIRAL", "cd": 10, "col": "#e86fb4",
		"desc": "YOUR FIELDS REACH TWICE AS FAR FOR 4S, AND A SPIRAL OF 16 MIND BOLTS FLIES OUT.",
		"do": [["aura_surge", 2.0, 4.0], ["nova", 16, 0.8, "hex", 2.0], ["vfx", "sigil", "#e86fb4", 70]] } },
]

static var _heroes: Array = []
static var _floors3: Array = []
static var _floors4: Array = []
static var _floors2: Array = []
## Tests that compare with the original Ruby set this to run the original rules.
static var force_classic := false

## The Rogues layer (attributes, upgrades, inventory...) is on unless --classic.
static func rogues() -> bool:
	return not force_classic and not DebugArgs.has("classic")
static var _unlocks: Array = []

## All playable heroes: the originals first (indices 0-5 unchanged), then the
## new ones. --classic leaves the new ones out.
static func heroes() -> Array:
	if _heroes.is_empty():
		_heroes = HEROES.duplicate()
		if not DebugArgs.has("classic"):
			# 20.1: in the expanded game the six originals have a skill too (ORIGINAL_SPECIALS).
			for i in _heroes.size():
				var h: Dictionary = _heroes[i].duplicate()
				h["special"] = ORIGINAL_SPECIALS[h["id"]]
				if ORIGINAL_PASSIVES.has(h["id"]):   # the two free starters also get a passive
					h["passive"] = ORIGINAL_PASSIVES[h["id"]][0]
					h["effects"] = ORIGINAL_PASSIVES[h["id"]][1]
				_heroes[i] = h
			_heroes.append_array(NEW_HEROES)
	return _heroes

## 20.1: the two free starters were still the weakest after their skills: a passive each.
const ORIGINAL_PASSIVES := {
	"hexer": ["HEXCRAFT: EVERY 3RD CAST LOOSES 2 MORE BOLTS. 15% OF HITS CURSE (CURSED FOES TAKE +25%).",
		[["add", "curse", 0.15], { "on": "every_n_shots", "every": 3, "do": [["shoot", 2, 1.0, "hex", 0.35]] }]],
	"poacher": ["QUICK HANDS: EVERY ROLL GIVES +30% FIRE RATE FOR 2S.", [{ "on": "on_roll", "do": [["buff", "rate", 0.3, 2.0]] }]],
}

## 20.1 (his ask, 8 Oct: "a second balance pass"): in a fight with rolls, hits and new rooms the six
## original heroes dealt the least of all (no skill of their own). In the expanded game each now
## has one; --classic plays exactly as before (Abilities.has_special checks GameData.rogues()).
const ORIGINAL_SPECIALS := {
	"hexer": { "name": "WITCHING HOUR", "cd": 10, "col": "#a35bd6",
		"desc": "CURSE EVERY FOE NEAR YOU AND LOOSE A RING OF 12 HEX BOLTS FOR 150%.",
		"do": [["status_area", "curse", 2, 150], ["nova", 12, 1.5, "hex"], ["vfx", "ring", "#a35bd6", 150]] },
	"poacher": { "name": "HUNTER'S VOLLEY", "cd": 9, "col": "#c8a878",
		"desc": "FOUR VOLLEYS OF 7 BOLTS AT YOUR AIM, AND A ROLL COMES BACK.",
		"do": [["refund_roll"], ["channel", 1.2, 0.3, [["shoot", 7, 0.8, "bolt", 0.12]]], ["vfx", "flash", "#f4ecd8", 0.1]] },
	"brute": { "name": "WHIRLWIND", "cd": 11, "col": "#d8443c",
		"desc": "SPIN FOR 1.5S: EVERYTHING AROUND YOU IS HIT FOR 120% FIVE TIMES A SECOND, AND SHOTS NEAR YOU BREAK.",
		"do": [["invuln", 0.5], ["channel", 1.5, 0.2, [["area", 46, 1.2], ["clear_shots", 46], ["vfx", "spin", "#d8443c", 0.2]]]] },
	"gravedigger": { "name": "OPEN GRAVES", "cd": 10, "col": "#8a6a4a",
		"desc": "FOUR GRAVESTONES FALL ON FOES FOR 150% EACH, AND A RING OF 16 CLODS BURSTS FROM YOU.",
		"do": [["nova", 16, 1.0, "clod"], ["meteor", 1.5, 28], ["meteor", 1.5, 28], ["meteor", 1.5, 28], ["meteor", 1.5, 28]] },
	"alchemist": { "name": "GRAND REACTION", "cd": 12, "col": "#7ab04a",
		"desc": "EVERY FOE NEAR YOU IS POISONED THRICE OVER, A POOL OF POISON SPREADS AT YOUR FEET AND 8 FLASKS FLY OUT.",
		"do": [["status_area", "poison", 3, 140], ["zone", "poison", 44, 4.0], ["nova", 8, 1.0, "flask"], ["vfx", "ring", "#7ab04a", 140]] },
	"warden": { "name": "LANTERN FLARE", "cd": 13, "col": "#f2c94c",
		"desc": "THE LANTERN FLARES: FOES NEAR YOU BURN, ARE HURLED BACK AND HIT FOR 200%. +30% FIRE RATE FOR 5S.",
		"do": [["area", 90, 2.0], ["status_area", "burn", 2, 120], ["push", 100, 260], ["buff", "rate", 0.3, 5.0], ["vfx", "flash", "#fff07a", 0.15]] },
}

## The order heroes are shown in on the hero and skill-tree screens: the free ones
## first, then the rest, each group in list order. Only those screens use it;
## G.hero_index and --hero stay indices into heroes(). (With the six originals
## alone, as in --classic, it is simply 0..5.)
static var _order: Array = []
static func hero_order() -> Array:
	if _order.is_empty():
		var all := heroes()
		for i in all.size():
			if all[i]["cost"] == 0:
				_order.append(i)
		for i in all.size():
			if all[i]["cost"] != 0:
				_order.append(i)
	return _order

static func unlocks() -> Array:
	if _unlocks.is_empty():
		_unlocks = UNLOCKS.duplicate()
		if not DebugArgs.has("classic"):
			for h in NEW_HEROES:
				if h["cost"] > 0:   # a hero that costs nothing is a starter: nothing to buy at the shrine
					_unlocks.append({ "id": "hero_" + h["id"], "name": h["name"], "desc": "A NEW HERO: " + h["weapon"], "cost": h["cost"] })
	return _unlocks

const RARITY_COL := { "common": "grey", "rare": "cyan", "epic": "purple", "legend": "gold", "mythic": "red" }
const RARITY_HEX := { "common": "#8b8f9c", "rare": "#4d9be6", "epic": "#a35bd6", "legend": "#f2c94c", "mythic": "#ff3a4a" }
const RARITY_NAME := { "common": "COMMON", "rare": "RARE", "epic": "EPIC", "legend": "LEGENDARY", "mythic": "MYTHIC" }   # 27: mythic items

## ai names map to EnemyAI.ai_* functions.
const ENEMIES := {
	"bat": { "sprite": "bat", "hp": 6, "speed": 72, "r": 5, "ai": "bat", "fly": true, "gold": 0.25 },
	"slime": { "sprite": "slime", "hp": 14, "speed": 40, "r": 6, "ai": "slime", "gold": 0.3 },
	"slimelet": { "sprite": "slime", "hp": 5, "speed": 55, "r": 4, "ai": "slime", "gold": 0.1, "scale": 0.7 },
	"skeleton": { "sprite": "skeleton", "hp": 11, "speed": 42, "r": 5, "ai": "archer", "gold": 0.35 },
	"mushroom": { "sprite": "mushroom", "hp": 16, "speed": 18, "r": 6, "ai": "spore", "gold": 0.35 },
	"cultist": { "sprite": "cultist", "hp": 20, "speed": 34, "r": 6, "ai": "cultist", "gold": 0.45 },
	"imp": { "sprite": "imp", "hp": 11, "speed": 60, "r": 5, "ai": "imp", "fly": true, "gold": 0.35 },
	"knight": { "sprite": "knight", "hp": 34, "speed": 36, "r": 6, "ai": "knight", "gold": 0.6 },
	"ghost": { "sprite": "ghost", "hp": 15, "speed": 46, "r": 5, "ai": "ghost", "fly": true, "gold": 0.35 },
	"bookwyrm": { "sprite": "bookwyrm", "hp": 12, "speed": 55, "r": 5, "ai": "book", "fly": true, "gold": 0.35 },
	"drowned": { "sprite": "drowned", "hp": 24, "speed": 30, "r": 6, "ai": "drowned", "gold": 0.45 },
	"wisp": { "sprite": "wisp", "hp": 9, "speed": 80, "r": 5, "ai": "wisp", "fly": true, "gold": 0.3 },
	"golem": { "sprite": "golem", "hp": 46, "speed": 26, "r": 7, "ai": "golem", "gold": 0.7 },
	# Rogues layer: a training dummy in each floor's start room (never dies, shows your DPS).
	"dummy": { "sprite": "dummy", "hp": 1, "speed": 0, "r": 6, "ai": "dummy", "gold": 0.0 },
	# ---------- Stage 7 foes (new biomes). "shot" overrides a behaviour's bullet sprite, "fan" an
	# archer's arrow count; "mini" marks a floor mini-boss (fixed health, own name, extra ring burst).
	# Rainmarsh Hamlet: poison and ambushes.
	"bogling": { "sprite": "bogling", "hp": 16, "speed": 70, "r": 6, "ai": "ambush", "shot": "spore", "gold": 0.4 },
	"gnat": { "sprite": "gnat", "hp": 5, "speed": 84, "r": 4, "ai": "bat", "fly": true, "gold": 0.15 },
	"hexwife": { "sprite": "hexwife", "hp": 20, "speed": 34, "r": 6, "ai": "cultist", "shot": "spore", "gold": 0.45 },
	"mirehulk": { "sprite": "mirehulk", "name": "THE MIRE HULK", "hp": 300, "speed": 24, "r": 10, "ai": "golem", "shot": "spore",
		"scale": 1.8, "mini": true, "gold": 3.0 },
	# Ashen Warfront: archers and cavalry charges.
	"longbowman": { "sprite": "longbowman", "hp": 14, "speed": 40, "r": 5, "ai": "archer", "shot": "bone", "fan": 5, "gold": 0.4 },
	"lancer": { "sprite": "lancer", "hp": 30, "speed": 40, "r": 6, "ai": "knight", "shot": "fire", "gold": 0.55 },
	"warpriest": { "sprite": "warpriest", "hp": 22, "speed": 32, "r": 6, "ai": "cultist", "shot": "fire", "gold": 0.5 },
	"torchimp": { "sprite": "torchimp", "hp": 12, "speed": 62, "r": 5, "ai": "imp", "fly": true, "shot": "fire", "gold": 0.35 },
	"ironcaptain": { "sprite": "ironcaptain", "name": "THE IRON CAPTAIN", "hp": 360, "speed": 40, "r": 10, "ai": "knight", "shot": "fire",
		"scale": 1.8, "mini": true, "gold": 3.0 },
	# Frostpeak Monastery: monks and ice.
	"monk": { "sprite": "monk", "hp": 18, "speed": 72, "r": 5, "ai": "monk", "shot": "ice", "gold": 0.4 },
	"icearcher": { "sprite": "icearcher", "hp": 13, "speed": 42, "r": 5, "ai": "archer", "shot": "ice", "gold": 0.4 },
	"snowlantern": { "sprite": "snowlantern", "hp": 18, "speed": 16, "r": 6, "ai": "spore", "shot": "ice", "gold": 0.35 },
	"stoneabbot": { "sprite": "stoneabbot", "name": "THE STONE ABBOT", "hp": 420, "speed": 26, "r": 10, "ai": "golem", "shot": "ice",
		"scale": 1.8, "mini": true, "gold": 3.0 },
	# Nightspire Rooftops: gunmen.
	"gunman": { "sprite": "gunman", "hp": 16, "speed": 44, "r": 5, "ai": "gunman", "shot": "red", "gold": 0.5 },
	"cutthroat": { "sprite": "cutthroat", "hp": 15, "speed": 58, "r": 5, "ai": "ghost", "fly": true, "shot": "dark", "gold": 0.4 },
	"crow": { "sprite": "crow", "hp": 7, "speed": 88, "r": 4, "ai": "bat", "fly": true, "gold": 0.2 },
	"chimneyimp": { "sprite": "chimneyimp", "hp": 13, "speed": 60, "r": 5, "ai": "imp", "fly": true, "shot": "fire", "gold": 0.35 },
	"enforcer": { "sprite": "enforcer", "name": "THE ENFORCER", "hp": 460, "speed": 30, "r": 10, "ai": "gunman", "shot": "red",
		"burst": 6, "scale": 1.8, "mini": true, "gold": 3.0 },
	# The Eclipse: corrupted everything.
	"voidling": { "sprite": "voidling", "hp": 11, "speed": 86, "r": 5, "ai": "wisp", "fly": true, "shot": "dark", "gold": 0.35 },
	"shadeknight": { "sprite": "shadeknight", "hp": 40, "speed": 42, "r": 6, "ai": "knight", "shot": "dark", "gold": 0.6 },
	"eclipsed": { "sprite": "eclipsed", "hp": 24, "speed": 34, "r": 6, "ai": "cultist", "shot": "dark", "gold": 0.5 },
	"herald": { "sprite": "herald", "name": "THE HERALD OF DUSK", "hp": 520, "speed": 50, "r": 10, "ai": "book", "fly": true, "shot": "dark",
		"scale": 1.8, "mini": true, "gold": 3.0 },
	# 12.2 (his ask, 6 Oct: a story chapter with new stages): CHAPTER II, THE MARGINS (STORY.md).
	# The Inkwell.
	"inkblot": { "sprite": "inkblot", "hp": 30, "speed": 40, "r": 6, "ai": "slime", "shot": "dark", "gold": 0.5, "label": "an inkblot" },
	"quillbat": { "sprite": "quillbat", "hp": 14, "speed": 76, "r": 5, "ai": "bat", "fly": true, "gold": 0.35, "label": "a quill bat" },
	"scrawler": { "sprite": "scrawler", "hp": 24, "speed": 38, "r": 5, "ai": "gunman", "shot": "page", "gold": 0.5, "label": "a scrawler" },
	"smudge": { "sprite": "smudge", "hp": 22, "speed": 44, "r": 6, "ai": "ghost", "fly": true, "shot": "dark", "gold": 0.45, "label": "a smudge" },
	"inkhound": { "sprite": "inkhound", "hp": 26, "speed": 92, "r": 5, "ai": "runner", "gold": 0.45, "label": "an ink hound" },
	"inkwidow": { "sprite": "inkwidow", "name": "THE INK WIDOW", "hp": 560, "speed": 46, "r": 10, "ai": "cultist", "shot": "dark",
		"scale": 1.8, "mini": true, "gold": 3.0 },
	# The Bindery.
	"papercut": { "sprite": "papercut", "hp": 14, "speed": 72, "r": 4, "ai": "imp", "fly": true, "gold": 0.35, "label": "a papercut" },
	"stitcher": { "sprite": "stitcher", "hp": 58, "speed": 28, "r": 7, "ai": "golem", "gold": 0.7, "label": "a stitcher" },
	"folio": { "sprite": "folio", "hp": 26, "speed": 40, "r": 6, "ai": "book", "fly": true, "shot": "page", "gold": 0.5, "label": "a folio" },
	"pressling": { "sprite": "pressling", "hp": 22, "speed": 36, "r": 5, "ai": "lobber", "shot": "page", "gold": 0.5, "label": "a pressling" },
	"pagewraith": { "sprite": "pagewraith", "hp": 14, "speed": 84, "r": 5, "ai": "wisp", "fly": true, "shot": "page", "gold": 0.4, "label": "a page wraith" },
	"bindingpress": { "sprite": "bindingpress", "name": "THE BINDING PRESS", "hp": 600, "speed": 28, "r": 10, "ai": "golem",
		"scale": 1.8, "mini": true, "gold": 3.0 },
	# The Quill Spire.
	"quillknight": { "sprite": "quillknight", "hp": 48, "speed": 44, "r": 6, "ai": "knight", "shot": "dark", "gold": 0.6, "label": "a quill knight" },
	"nibling": { "sprite": "nibling", "hp": 14, "speed": 80, "r": 4, "ai": "bat", "fly": true, "gold": 0.35, "label": "a nibling" },
	"inkmage": { "sprite": "inkmage", "hp": 28, "speed": 34, "r": 6, "ai": "cultist", "shot": "dark", "gold": 0.55, "label": "an ink mage" },
	"sealwarden": { "sprite": "sealwarden", "hp": 30, "speed": 36, "r": 6, "ai": "gunman", "shot": "red", "gold": 0.55, "label": "a seal warden" },
	"scribe": { "sprite": "scribe", "hp": 32, "speed": 40, "r": 6, "ai": "monk", "shot": "page", "gold": 0.55, "label": "a scribe" },
	"headscribe": { "sprite": "headscribe", "name": "THE HEAD SCRIBE", "hp": 640, "speed": 48, "r": 10, "ai": "book", "fly": true, "shot": "page",
		"scale": 1.8, "mini": true, "gold": 3.0 },
	# 14.4 (his ask, 7 Oct): CHAPTER III, THE APPENDIX (STORY.md). The Glossary.
	"letterling": { "sprite": "letterling", "hp": 16, "speed": 74, "r": 5, "ai": "bat", "fly": true, "gold": 0.35, "label": "a letterling" },
	"wordworm": { "sprite": "wordworm", "hp": 30, "speed": 90, "r": 5, "ai": "runner", "gold": 0.5, "label": "a word worm" },
	"definer": { "sprite": "definer", "hp": 30, "speed": 38, "r": 6, "ai": "gunman", "shot": "page", "gold": 0.55, "label": "a definer" },
	"thesaurus": { "sprite": "thesaurus", "hp": 66, "speed": 28, "r": 7, "ai": "golem", "gold": 0.75, "label": "a thesaurus" },
	"commaimp": { "sprite": "commaimp", "hp": 16, "speed": 78, "r": 4, "ai": "imp", "fly": true, "gold": 0.35, "label": "a comma imp" },
	"lexicant": { "sprite": "lexicant", "name": "THE LEXICANT", "hp": 700, "speed": 48, "r": 10, "ai": "book", "fly": true, "shot": "page",
		"scale": 1.8, "mini": true, "gold": 3.0 },
	# The Footnotes.
	"asterisk": { "sprite": "asterisk", "hp": 16, "speed": 86, "r": 5, "ai": "wisp", "fly": true, "shot": "page", "gold": 0.4, "label": "an asterisk" },
	"obelus": { "sprite": "obelus", "hp": 26, "speed": 36, "r": 5, "ai": "lobber", "shot": "page", "gold": 0.55, "label": "an obelus" },
	"ibid": { "sprite": "ibid", "hp": 26, "speed": 46, "r": 6, "ai": "ghost", "fly": true, "shot": "dark", "gold": 0.5, "label": "an ibid" },
	"citation": { "sprite": "citation", "hp": 54, "speed": 44, "r": 6, "ai": "knight", "shot": "dark", "gold": 0.65, "label": "a citation" },
	"smallprint": { "sprite": "smallprint", "hp": 34, "speed": 42, "r": 6, "ai": "slime", "shot": "dark", "gold": 0.5, "label": "the small print" },
	"fineprint": { "sprite": "fineprint", "name": "THE FINE PRINT", "hp": 740, "speed": 30, "r": 10, "ai": "golem",
		"scale": 1.8, "mini": true, "gold": 3.0 },
	# The Cover.
	"gildling": { "sprite": "gildling", "hp": 18, "speed": 80, "r": 5, "ai": "bat", "fly": true, "gold": 0.45, "label": "a gildling" },
	"clasp": { "sprite": "clasp", "hp": 72, "speed": 30, "r": 7, "ai": "golem", "gold": 0.8, "label": "a clasp" },
	"bookmark": { "sprite": "bookmark", "hp": 30, "speed": 96, "r": 5, "ai": "runner", "gold": 0.5, "label": "a bookmark" },
	"spinewarden": { "sprite": "spinewarden", "hp": 58, "speed": 44, "r": 6, "ai": "knight", "shot": "red", "gold": 0.7, "label": "a spine warden" },
	"endpaper": { "sprite": "endpaper", "hp": 32, "speed": 40, "r": 6, "ai": "book", "fly": true, "shot": "page", "gold": 0.6, "label": "an endpaper" },
	"colophon": { "sprite": "colophon", "name": "THE COLOPHON", "hp": 780, "speed": 46, "r": 10, "ai": "cultist", "shot": "red",
		"scale": 1.8, "mini": true, "gold": 3.0 },
	# 20.3 (his word, 8 Oct): CHAPTER IV, THE LIBRARY (STORY.md). The Stacks.
	"mothling": { "sprite": "mothling", "hp": 18, "speed": 80, "r": 5, "ai": "bat", "fly": true, "gold": 0.4, "label": "a mothling" },
	"dustbunny": { "sprite": "dustbunny", "hp": 34, "speed": 50, "r": 6, "ai": "slime", "gold": 0.5, "label": "a dust bunny" },
	"shelfmimic": { "sprite": "shelfmimic", "hp": 36, "speed": 74, "r": 6, "ai": "ambush", "shot": "page", "gold": 0.6, "label": "a shelf mimic" },
	"bookgolem": { "sprite": "bookgolem", "hp": 80, "speed": 28, "r": 7, "ai": "golem", "gold": 0.8, "label": "a book golem" },
	"cardsprite": { "sprite": "cardsprite", "hp": 32, "speed": 40, "r": 6, "ai": "gunman", "shot": "page", "gold": 0.55, "label": "a card sprite" },
	"overdue": { "sprite": "overdue", "name": "THE OVERDUE", "hp": 820, "speed": 32, "r": 10, "ai": "golem", "shot": "page",
		"scale": 1.8, "mini": true, "gold": 3.0 },
	# The Reading Room.
	"shusher": { "sprite": "shusher", "hp": 34, "speed": 44, "r": 6, "ai": "ghost", "fly": true, "shot": "dark", "gold": 0.55, "label": "a shusher" },
	"lampwisp": { "sprite": "lampwisp", "hp": 20, "speed": 84, "r": 5, "ai": "wisp", "fly": true, "shot": "cyan", "gold": 0.45, "label": "a lamp wisp" },
	"bookend": { "sprite": "bookend", "hp": 84, "speed": 26, "r": 7, "ai": "golem", "gold": 0.8, "label": "a bookend" },
	"pagewing": { "sprite": "pagewing", "hp": 18, "speed": 86, "r": 5, "ai": "bat", "fly": true, "gold": 0.4, "label": "a page wing" },
	"spectacle": { "sprite": "spectacle", "hp": 30, "speed": 46, "r": 5, "ai": "gunman", "fly": true, "shot": "cyan", "gold": 0.55, "label": "a pair of spectacles" },
	"quiet": { "sprite": "quiet", "name": "THE QUIET", "hp": 860, "speed": 44, "r": 10, "ai": "cultist", "fly": true, "shot": "dark",
		"scale": 1.8, "mini": true, "gold": 3.0 },
	# The Hearth.
	"cinderpage": { "sprite": "cinderpage", "hp": 20, "speed": 84, "r": 5, "ai": "bat", "fly": true, "gold": 0.45, "label": "a cinder page" },
	"ashworm": { "sprite": "ashworm", "hp": 36, "speed": 96, "r": 5, "ai": "runner", "gold": 0.55, "label": "an ash worm" },
	"pokerknight": { "sprite": "pokerknight", "hp": 70, "speed": 44, "r": 6, "ai": "knight", "shot": "fire", "gold": 0.75, "label": "a poker knight" },
	"firedog": { "sprite": "firedog", "hp": 40, "speed": 38, "r": 6, "ai": "lobber", "shot": "fire", "gold": 0.6, "label": "a fire-dog" },
	"sootling": { "sprite": "sootling", "hp": 20, "speed": 80, "r": 4, "ai": "imp", "fly": true, "gold": 0.4, "label": "a sootling" },
	"kindling": { "sprite": "kindling", "name": "THE KINDLING", "hp": 900, "speed": 46, "r": 10, "ai": "cultist", "shot": "fire",
		"scale": 1.8, "mini": true, "gold": 3.0 },
	# ---------- Rift worlds (scripts/data/themes.gd). "label" is how a foe is named when it kills
	# you; "champion" marks a rift's boss (ChampionAI, health grows with the floor).
	# Blackrock Gaol.
	"inmate": { "sprite": "inmate", "hp": 18, "speed": 34, "r": 6, "ai": "drowned", "shot": "bone", "gold": 0.4, "label": "an inmate" },
	"grenadier": { "sprite": "grenadier", "hp": 14, "speed": 38, "r": 5, "ai": "lobber", "shot": "fire", "gold": 0.45, "label": "a grenadier" },
	"jailer": { "sprite": "jailer", "hp": 30, "speed": 38, "r": 6, "ai": "knight", "shot": "bone", "gold": 0.55, "label": "a jailer" },
	"turnkey": { "sprite": "turnkey", "name": "THE TURNKEY", "hp": 170, "speed": 46, "r": 10, "ai": "champion", "shot": "bone",
		"scale": 2.0, "mini": true, "champion": true, "gold": 4.0, "style": "melee",
		"moves": [["charge", 2], ["ring", 14, 62, 2], ["lob", 3], ["summon", "inmate", 2], ["fan", 5, 0.7, 3]] },
	# The Branded Field.
	"graveborn": { "sprite": "graveborn", "hp": 16, "speed": 70, "r": 6, "ai": "ambush", "shot": "dark", "gold": 0.4, "label": "a graveborn" },
	"bandsman": { "sprite": "bandsman", "hp": 14, "speed": 40, "r": 5, "ai": "archer", "shot": "bone", "fan": 3, "gold": 0.4, "label": "a bandsman" },
	"fiendling": { "sprite": "fiendling", "hp": 12, "speed": 62, "r": 5, "ai": "imp", "fly": true, "shot": "dark", "gold": 0.35, "label": "a fiendling" },
	"blackknight": { "sprite": "blackknight", "hp": 36, "speed": 40, "r": 6, "ai": "knight", "shot": "dark", "gold": 0.6, "label": "a black knight" },
	"carrionknight": { "sprite": "carrionknight", "name": "THE CARRION KNIGHT", "hp": 190, "speed": 50, "r": 10, "ai": "champion", "shot": "dark",
		"scale": 2.0, "mini": true, "champion": true, "gold": 4.0, "style": "melee",
		"moves": [["charge", 3], ["fan", 7, 0.9, 2], ["rain", 4], ["ring", 16, 58, 2], ["summon", "fiendling", 2]] },
	# Neon Undercity.
	"drone": { "sprite": "drone", "hp": 10, "speed": 66, "r": 5, "ai": "imp", "fly": true, "shot": "cyan", "gold": 0.35, "label": "a drone" },
	"glitch": { "sprite": "glitch", "hp": 15, "speed": 56, "r": 5, "ai": "ghost", "fly": true, "shot": "cyan", "gold": 0.4, "label": "a glitch" },
	"chrome": { "sprite": "chrome", "hp": 44, "speed": 28, "r": 7, "ai": "golem", "shot": "red", "gold": 0.7, "label": "a chrome bruiser" },
	"turret": { "sprite": "turret", "hp": 20, "speed": 0, "r": 6, "ai": "turret", "shot": "cyan", "gold": 0.4, "label": "a turret" },
	"broker": { "sprite": "broker", "name": "THE BROKER", "hp": 160, "speed": 44, "r": 10, "ai": "champion", "shot": "cyan",
		"scale": 2.0, "mini": true, "champion": true, "gold": 4.0, "style": "ranged",
		"moves": [["blink"], ["spiral", 36], ["burst", 8], ["summon", "drone", 3], ["blink"], ["ring", 18, 66, 3]] },
	# Riot Alley.
	"thug": { "sprite": "thug", "hp": 18, "speed": 70, "r": 5, "ai": "monk", "shot": "red", "gold": 0.4, "label": "a thug" },
	"molotov": { "sprite": "molotov", "hp": 13, "speed": 40, "r": 5, "ai": "lobber", "shot": "fire", "gold": 0.4, "label": "a firebomber" },
	"copper": { "sprite": "copper", "hp": 16, "speed": 44, "r": 5, "ai": "gunman", "shot": "red", "gold": 0.5, "label": "a copper" },
	"bomber": { "sprite": "bomber", "hp": 12, "speed": 78, "r": 6, "ai": "bomber", "shot": "fire", "gold": 0.35, "label": "a mad bomber" },
	"mayor": { "sprite": "mayor", "name": "THE MAYOR", "hp": 165, "speed": 40, "r": 10, "ai": "champion", "shot": "red",
		"scale": 2.0, "mini": true, "champion": true, "gold": 5.0, "style": "ranged",
		"moves": [["summon", "thug", 2], ["burst", 6], ["lob", 4], ["summon", "copper", 2], ["ring", 16, 60, 2], ["summon", "bomber", 2]] },
	# Ashfall Town.
	"orderly": { "sprite": "orderly", "hp": 18, "speed": 60, "r": 5, "ai": "monk", "shot": "dark", "gold": 0.4, "label": "an orderly" },
	"crawler": { "sprite": "crawler", "hp": 8, "speed": 80, "r": 5, "ai": "runner", "gold": 0.2, "label": "a crawler" },
	"static": { "sprite": "static", "hp": 15, "speed": 50, "r": 5, "ai": "ghost", "fly": true, "shot": "dark", "gold": 0.4, "label": "a static shape" },
	"tollkeeper": { "sprite": "tollkeeper", "hp": 22, "speed": 26, "r": 6, "ai": "caller", "summon": "crawler", "shot": "dark", "gold": 0.5, "label": "a tollkeeper" },
	"rustbutcher": { "sprite": "rustbutcher", "name": "THE RUST BUTCHER", "hp": 200, "speed": 42, "r": 10, "ai": "champion", "shot": "darkBig",
		"scale": 2.0, "mini": true, "champion": true, "gold": 4.0, "style": "melee",
		"moves": [["charge", 2], ["ring", 10, 44, 3], ["rain", 5], ["summon", "crawler", 4], ["charge", 3]] },
	# Maple Court.
	"neighbour": { "sprite": "neighbour", "hp": 14, "speed": 46, "r": 5, "ai": "book", "shot": "page", "gold": 0.4, "label": "an angry neighbour" },
	"robovac": { "sprite": "robovac", "hp": 24, "speed": 44, "r": 6, "ai": "knight", "shot": "red", "gold": 0.45, "label": "a robot vacuum" },
	"burglar": { "sprite": "burglar", "hp": 14, "speed": 58, "r": 5, "ai": "ghost", "fly": true, "shot": "dark", "gold": 0.6, "label": "a burglar" },
	"gnome": { "sprite": "gnome", "hp": 16, "speed": 0, "r": 5, "ai": "turret", "shot": "red", "gold": 0.4, "label": "a garden gnome" },
	"landlord": { "sprite": "landlord", "name": "THE LANDLORD", "hp": 160, "speed": 42, "r": 10, "ai": "champion", "shot": "page",
		"scale": 2.0, "mini": true, "champion": true, "gold": 6.0, "style": "ranged",
		"moves": [["fan", 9, 1.2, 3], ["summon", "neighbour", 2], ["lob", 3], ["charge", 1], ["summon", "robovac", 2], ["spiral", 30]] },
	# Heist City.
	"gangster": { "sprite": "gangster", "hp": 16, "speed": 44, "r": 5, "ai": "gunman", "shot": "red", "burst": 4, "gold": 0.6, "label": "a gangster" },
	"biker": { "sprite": "biker", "hp": 24, "speed": 52, "r": 6, "ai": "knight", "shot": "fire", "gold": 0.5, "label": "a biker" },
	"riotcop": { "sprite": "riotcop", "hp": 40, "speed": 28, "r": 7, "ai": "golem", "shot": "red", "gold": 0.6, "label": "a riot cop" },
	"kingpin": { "sprite": "kingpin", "name": "THE KINGPIN", "hp": 210, "speed": 34, "r": 11, "ai": "champion", "shot": "red",
		"scale": 2.0, "mini": true, "champion": true, "gold": 8.0, "style": "ranged",
		"moves": [["burst", 10], ["lob", 3], ["summon", "gangster", 2], ["spiral", 40], ["summon", "biker", 2], ["ring", 20, 64, 2]] },
	# Dustwater.
	"outlaw": { "sprite": "outlaw", "hp": 15, "speed": 46, "r": 5, "ai": "gunman", "shot": "red", "burst": 2, "gold": 0.55, "label": "an outlaw" },
	"dynamiter": { "sprite": "dynamiter", "hp": 14, "speed": 38, "r": 5, "ai": "lobber", "shot": "fire", "gold": 0.45, "label": "a dynamiter" },
	"sharpshooter": { "sprite": "sharpshooter", "hp": 12, "speed": 36, "r": 5, "ai": "gunman", "shot": "bone", "burst": 1, "shot_speed": 260,
		"aim": 0.9, "gold": 0.5, "label": "a sharpshooter" },
	"coyote": { "sprite": "coyote", "hp": 9, "speed": 90, "r": 5, "ai": "runner", "gold": 0.2, "label": "a coyote" },
	"marshal": { "sprite": "marshal", "name": "THE MARSHAL", "hp": 175, "speed": 48, "r": 10, "ai": "champion", "shot": "bone",
		"scale": 2.0, "mini": true, "champion": true, "gold": 5.0, "style": "ranged",
		"moves": [["duel", 3], ["burst", 6], ["lob", 3], ["charge", 1], ["fan", 6, 0.5, 3], ["summon", "coyote", 3]] },
	# Skyreach Isles.
	"galewarden": { "sprite": "galewarden", "name": "THE GALE WARDEN", "hp": 180, "speed": 50, "r": 10, "ai": "champion",
		"shot": "ice", "scale": 2.0, "mini": true, "champion": true, "fly": true, "gold": 5.0, "style": "ranged",
		"moves": [["blink"], ["fan", 7, 0.45, 3], ["spiral", 36], ["summon", "crow", 3], ["ring", 18, 70, 2], ["rain", 5]] },
	# New foes (ROADMAP 4.4, scripts/entities/enemy_ai2.gd). Skyreach Isles.
	"skykite": { "sprite": "skykite", "hp": 10, "speed": 70, "r": 5, "ai": "skykite", "fly": true, "shot": "cyan", "gold": 0.3, "label": "a sky kite" },
	"gustling": { "sprite": "gustling", "hp": 12, "speed": 55, "r": 5, "ai": "gustling", "fly": true, "shot": "cyan", "gold": 0.3, "label": "a gustling" },
	"stormharpy": { "sprite": "stormharpy", "hp": 14, "speed": 60, "r": 5, "ai": "stormharpy", "fly": true, "shot": "cyan", "gold": 0.35, "label": "a storm harpy" },
	"thunderhead": { "sprite": "thunderhead", "hp": 18, "speed": 30, "r": 6, "ai": "thunderhead", "fly": true, "gold": 0.4, "label": "a thunderhead" },
	"mirrorwing": { "sprite": "mirrorwing", "hp": 12, "speed": 90, "r": 5, "ai": "mirrorwing", "fly": true, "shot": "cyan", "gold": 0.35, "label": "a mirrorwing" },
	# The Drowned Bastion.
	"rampartguard": { "sprite": "rampartguard", "hp": 30, "speed": 32, "r": 6, "ai": "rampartguard", "rule": "shield", "gold": 0.5, "label": "a rampart guard" },
	"sludgecrawler": { "sprite": "sludgecrawler", "hp": 16, "speed": 38, "r": 5, "ai": "sludgecrawler", "gold": 0.35, "label": "a sludge crawler" },
	"chainwarden": { "sprite": "chainwarden", "hp": 24, "speed": 36, "r": 6, "ai": "chainwarden", "shot": "bone", "gold": 0.5, "label": "a chain warden" },
	"tidecaller": { "sprite": "tidecaller", "hp": 18, "speed": 34, "r": 5, "ai": "tidecaller", "gold": 0.45, "label": "a tidecaller" },
	"longpike": { "sprite": "longpike", "hp": 18, "speed": 44, "r": 5, "ai": "longpike", "gold": 0.4, "label": "a longpike" },
	# The Caliber Cathedral.
	"shellpriest": { "sprite": "shellpriest", "hp": 20, "speed": 36, "r": 5, "ai": "shellpriest", "shot": "red", "gold": 0.45, "label": "a shell priest" },
	"dervish": { "sprite": "dervish", "hp": 22, "speed": 44, "r": 5, "ai": "dervish", "rule": "dizzy", "shot": "red", "gold": 0.45, "label": "a bullet dervish" },
	"deacon": { "sprite": "deacon", "hp": 16, "speed": 40, "r": 5, "ai": "deacon", "gold": 0.5, "label": "a deacon" },
	"beltfeeder": { "sprite": "beltfeeder", "hp": 26, "speed": 40, "r": 6, "ai": "beltfeeder", "shot": "red", "summon": "beltlink", "gold": 0.5, "label": "a belt feeder" },
	"beltlink": { "sprite": "beltlink", "hp": 12, "speed": 40, "r": 5, "ai": "beltlink", "shot": "red", "gold": 0.1, "label": "a belt link" },
	"ammomimic": { "sprite": "ammomimic", "hp": 22, "speed": 30, "r": 6, "ai": "ammomimic", "shot": "red", "gold": 0.6, "label": "an ammo mimic" },
	# The original floors, expanded game only (EnemyAI2.OLD_FLOOR_EXTRA).
	"tombspider": { "sprite": "tombspider", "hp": 12, "speed": 50, "r": 5, "ai": "tombspider", "gold": 0.3, "label": "a tomb spider" },
	"candlewight": { "sprite": "candlewight", "hp": 14, "speed": 40, "r": 5, "ai": "candlewight", "fly": true, "shot": "fire", "gold": 0.35, "label": "a candlewight" },
	"gargoyle": { "sprite": "gargoyle", "hp": 40, "speed": 70, "r": 6, "ai": "gargoyle", "gold": 0.5, "label": "a gargoyle" },
	"wardrummer": { "sprite": "wardrummer", "hp": 18, "speed": 36, "r": 5, "ai": "wardrummer", "gold": 0.45, "label": "a war drummer" },
	"bloodleech": { "sprite": "bloodleech", "hp": 10, "speed": 55, "r": 4, "ai": "bloodleech", "no_touch": true, "gold": 0.25, "label": "a blood leech" },
	# The Drowned Bastion and the Caliber Cathedral.
	"rotking": { "sprite": "rotking", "name": "THE ROTTING KING", "hp": 190, "speed": 40, "r": 10, "ai": "champion", "shot": "spore",
		"scale": 2.0, "mini": true, "champion": true, "gold": 5.0, "style": "melee",
		"moves": [["charge", 2], ["ring", 16, 60, 3], ["lob", 3], ["summon", "drowned", 3], ["spiral", 30], ["rain", 4]] },
	"highcaliber": { "sprite": "highcaliber", "name": "THE HIGH CALIBER", "hp": 175, "speed": 44, "r": 10, "ai": "champion", "shot": "red",
		"scale": 2.0, "mini": true, "champion": true, "gold": 5.0, "style": "ranged",
		"moves": [["burst", 12], ["fan", 9, 0.35, 3], ["spiral", 44], ["blink"], ["summon", "gunman", 2], ["ring", 24, 70, 2]] },
	"casingrat": { "sprite": "casingrat", "hp": 30, "speed": 100, "r": 5, "ai": "flee", "gold": 0.0, "label": "a casing rat",
		"away": "THE RAT GOT AWAY WITH YOUR GOLD" },
	# Rift mini-bosses (ROADMAP 4.5, scripts/entities/rift_bosses.gd): the last wave of a new world's
	# second room. "champion": health grows with the floor, the world's hazards leave them be.
	"squallheron": { "sprite": "squallheron", "name": "THE SQUALL HERON", "hp": 150, "speed": 70, "r": 9, "ai": "riftboss",
		"shot": "cyan", "scale": 2.0, "mini": true, "champion": true, "fly": true, "gold": 4.0, "rule": "phase" },
	"tidecaptain": { "sprite": "tidecaptain", "name": "THE DROWNED CAPTAIN", "hp": 165, "speed": 40, "r": 9, "ai": "riftboss",
		"shot": "spore", "scale": 2.0, "mini": true, "champion": true, "gold": 4.0, "rule": "phase" },
	"bellringer": { "sprite": "bellringer", "name": "THE BELLRINGER", "hp": 160, "speed": 36, "r": 9, "ai": "riftboss",
		"shot": "bone", "scale": 2.0, "mini": true, "champion": true, "gold": 4.0, "rule": "phase" },
	# Event rooms.
	"target": { "sprite": "target", "hp": 1, "speed": 0, "r": 6, "ai": "target", "gold": 0.0, "label": "a target", "no_touch": true },
	# "You're going to Brazil" (his ask, 6 Oct; scripts/game/brazil.gd).
	"haggler": { "sprite": "haggler", "name": "THE HAGGLER", "hp": 900, "speed": 52, "r": 7, "ai": "runner", "gold": 0.0, "label": "the haggler" },
	"scrounger": { "sprite": "scrounger", "hp": 24, "speed": 76, "r": 5, "ai": "runner", "gold": 0.6, "label": "a scrounger" },
	# His ask (6 Oct): a human robber for Brazil, a wasteland raider (a scavenger, no real people).
	# 6.4 (his ask, 6 Oct): THE CLOCKWORK SPIRE, a rift world of brass and steam.
	"cogling": { "sprite": "cogling", "hp": 10, "speed": 64, "r": 5, "ai": "bat", "fly": true, "gold": 0.3, "label": "a cogling" },
	"steamjack": { "sprite": "steamjack", "hp": 46, "speed": 28, "r": 7, "ai": "golem", "gold": 0.7, "label": "a steamjack" },
	"boltslinger": { "sprite": "boltslinger", "hp": 16, "speed": 42, "r": 5, "ai": "gunman", "shot": "cyan", "gold": 0.5, "label": "a boltslinger" },
	"gearhound": { "sprite": "gearhound", "hp": 18, "speed": 84, "r": 5, "ai": "runner", "gold": 0.4, "label": "a gearhound" },
	"rivetlobber": { "sprite": "rivetlobber", "hp": 15, "speed": 38, "r": 5, "ai": "lobber", "shot": "fire", "gold": 0.45, "label": "a rivet lobber" },
	"brasswasp": { "sprite": "brasswasp", "hp": 9, "speed": 66, "r": 4, "ai": "imp", "fly": true, "gold": 0.3, "label": "a brass wasp" },
	"foreman": { "sprite": "foreman", "name": "THE FOREMAN", "hp": 185, "speed": 44, "r": 10, "ai": "champion",
		"shot": "fire", "scale": 2.0, "mini": true, "champion": true, "gold": 5.0, "style": "melee",
		"moves": [["charge", 2], ["ring", 16, 60, 3], ["lob", 3], ["summon", "cogling", 3], ["spiral", 30], ["fan", 7, 0.45, 3]] },	# 7.3 (his word "All", 6 Oct): THE RIMEFROST HOLLOWS, a rift world of ice and still air.
	"frostmite": { "sprite": "frostmite", "hp": 10, "speed": 62, "r": 5, "ai": "bat", "fly": true, "gold": 0.3, "label": "a frostmite" },
	"rimebrute": { "sprite": "rimebrute", "hp": 48, "speed": 27, "r": 7, "ai": "golem", "gold": 0.7, "label": "a rime brute" },
	"shardcaster": { "sprite": "shardcaster", "hp": 16, "speed": 42, "r": 5, "ai": "gunman", "shot": "cyan", "gold": 0.5, "label": "a shardcaster" },
	"frostfang": { "sprite": "frostfang", "hp": 18, "speed": 86, "r": 5, "ai": "runner", "gold": 0.4, "label": "a frostfang" },
	"snowlobber": { "sprite": "snowlobber", "hp": 15, "speed": 38, "r": 5, "ai": "lobber", "shot": "water", "gold": 0.45, "label": "a snow lobber" },
	"glimmerwisp": { "sprite": "glimmerwisp", "hp": 9, "speed": 64, "r": 4, "ai": "imp", "fly": true, "gold": 0.3, "label": "a glimmer wisp" },
	"hoarknight": { "sprite": "hoarknight", "name": "THE HOARFROST KNIGHT", "hp": 190, "speed": 42, "r": 10, "ai": "champion",
		"shot": "cyan", "scale": 2.0, "mini": true, "champion": true, "gold": 5.0, "style": "melee",
		"moves": [["charge", 2], ["ring", 18, 58, 3], ["fan", 7, 0.45, 3], ["summon", "frostmite", 3], ["spiral", 30], ["lob", 3]] },

	"raider": { "sprite": "raider", "hp": 34, "speed": 84, "r": 5, "ai": "runner", "gold": 0.8, "label": "a raider" },
	"goblin": { "sprite": "goblin", "hp": 40, "speed": 96, "r": 5, "ai": "flee", "gold": 0.0, "label": "a loot goblin" },
	"mimic": { "sprite": "mimic", "hp": 80, "speed": 46, "r": 8, "ai": "golem", "shot": "red", "scale": 1.3, "gold": 2.0, "label": "a mimic" },
	"shadow": { "sprite": "shadow", "name": "YOUR SHADOW", "hp": 150, "speed": 60, "r": 6, "ai": "champion", "shot": "dark",
		"mini": true, "champion": true, "gold": 0.0, "style": "ranged",
		"moves": [["burst", 5], ["blink"], ["fan", 5, 0.6, 2], ["charge", 1], ["ring", 12, 60, 2]] },
}

## 9.3 (his ask, 6 Oct): seven floors have a second guardian, met half the time (game.start_floor).
const ALT_GUARDIANS := { 1: "admiral", 3: "golemking", 5: "archmage", 6: "phoenix", 8: "wyrm", 9: "chainfiend", 10: "seraph" }

const BOSSES := {
	"colossus": { "name": "THE BONE COLOSSUS", "sprite": "colossus", "hp": 420, "r": 13, "scale": 2 },
	"sporemother": { "name": "THE SPORE MOTHER", "sprite": "sporemother", "hp": 540, "r": 13, "scale": 2 },
	"librarian": { "name": "THE DROWNED LIBRARIAN", "sprite": "librarian", "hp": 640, "r": 13, "scale": 2 },
	"tyrant": { "name": "THE FORGE TYRANT", "sprite": "tyrant", "hp": 760, "r": 13, "scale": 2 },
	"rimewarden": { "name": "THE RIME WARDEN", "sprite": "rimewarden", "hp": 880, "r": 13, "scale": 2 },
	"regent": { "name": "THE PALE REGENT", "sprite": "regent", "hp": 1000, "r": 13, "scale": 2 },
	# Stage 7 guardians.
	"bogmatriarch": { "name": "THE BOG MATRIARCH", "sprite": "bogmatriarch", "hp": 1200, "r": 13, "scale": 2 },
	"ashwarlord": { "name": "THE ASH WARLORD", "sprite": "ashwarlord", "hp": 1350, "r": 13, "scale": 2 },
	"frozenabbot": { "name": "THE FROZEN ABBOT", "sprite": "frozenabbot", "hp": 1500, "r": 13, "scale": 2 },
	"crowking": { "name": "THE CROW KING", "sprite": "crowking", "hp": 1650, "r": 13, "scale": 2 },
	"umbralsun": { "name": "THE UMBRAL SUN", "sprite": "umbralsun", "hp": 2100, "r": 13, "scale": 2.4 },
	# Heaven and Hell (ROADMAP 4.7 part C, soul.gd): the realm rulers and the last boss of all.
	"holycow": { "name": "THE HOLY COW", "sprite": "holycow", "hp": 520, "r": 13, "scale": 2.4, "rift": true },
	"judge": { "name": "THE AUREATE JUDGE", "sprite": "judge", "hp": 2500, "r": 13, "scale": 2.4 },
	"cinderking": { "name": "THE CINDER KING", "sprite": "cinderking", "hp": 2500, "r": 13, "scale": 2.4 },
	"unwritten": { "name": "THE UNWRITTEN", "sprite": "unwritten", "hp": 3300, "r": 13, "scale": 2.4 },
	# Rift guardians (ROADMAP 4.5, scripts/entities/rift_bosses.gd): behind the champion of a new
	# world, an optional fight. "rift": health grows with the floor (Combat.spawn_boss).
	"stormcrown": { "name": "THE STORMCROWN", "sprite": "stormcrown", "hp": 400, "r": 14, "scale": 2, "rift": true, "rule": "phase" },
	"bilgehydra": { "name": "THE BILGE HYDRA", "sprite": "bilgehydra", "hp": 440, "r": 18, "scale": 2, "rift": true, "rule": "phase" },
	"brassorgan": { "name": "THE BRASS ORGAN", "sprite": "brassorgan", "hp": 420, "r": 20, "scale": 2, "rift": true, "rule": "phase" },
	# A hidden boss after the owner's dog (scripts/entities/rex.gd). "rift": his health grows with the floor too.
	"greatengine": { "name": "THE GREAT ENGINE", "sprite": "greatengine", "hp": 470, "r": 14, "scale": 2, "rift": true },
	"glacialmaw": { "name": "THE GLACIAL MAW", "sprite": "glacialmaw", "hp": 480, "r": 14, "scale": 2, "rift": true },   # 7.3
	# 12.2 Chapter II's guardians (STORY.md); THE AUTHOR is the chapter's last.
	"inkleviathan": { "name": "THE INK LEVIATHAN", "sprite": "inkleviathan", "hp": 2300, "r": 14, "scale": 2.2 },
	"thebinder": { "name": "THE BINDER", "sprite": "thebinder", "hp": 2500, "r": 13, "scale": 2.2 },
	"author": { "name": "THE AUTHOR", "sprite": "author", "hp": 3000, "r": 13, "scale": 2.4 },
	"redactor": { "name": "THE REDACTOR", "sprite": "redactor", "hp": 3800, "r": 13, "scale": 2.4 },   # 12.3 hidden
	# 14.4 Chapter III's guardians; THE READER is the last of all.
	"lexicon": { "name": "THE LEXICON", "sprite": "lexicon", "hp": 3200, "r": 14, "scale": 2.2 },
	"erratum": { "name": "THE ERRATUM", "sprite": "erratum", "hp": 3500, "r": 13, "scale": 2.2 },
	"reader": { "name": "THE READER", "sprite": "reader", "hp": 4600, "r": 14, "scale": 2.5 },
	# 20.3 Chapter IV's guardians; THE CRITIC is the last of all.
	"shelver": { "name": "THE SHELVER", "sprite": "shelver", "hp": 3800, "r": 14, "scale": 2.3 },
	"hush": { "name": "THE HUSH", "sprite": "hush", "hp": 4100, "r": 13, "scale": 2.3 },
	"critic": { "name": "THE CRITIC", "sprite": "critic", "hp": 5200, "r": 14, "scale": 2.5 },
	# 9.3 (his ask, 6 Oct, from another game's boss roster: ideas only, original designs): a second
	# guardian for seven floors (GameData.ALT_GUARDIANS).
	"admiral": { "name": "THE WALRUS ADMIRAL", "sprite": "admiral", "hp": 560, "r": 13, "scale": 2 },
	"golemking": { "name": "THE GOLEM KING", "sprite": "golemking", "hp": 780, "r": 13, "scale": 2 },
	"archmage": { "name": "THE ARCHMAGE", "sprite": "archmage", "hp": 1000, "r": 13, "scale": 2 },
	"phoenix": { "name": "THE PHOENIX", "sprite": "phoenix", "hp": 1150, "r": 13, "scale": 2 },
	"wyrm": { "name": "THE WHITE WYRM", "sprite": "wyrm", "hp": 1500, "r": 13, "scale": 2.2 },
	"chainfiend": { "name": "THE CHAIN FIEND", "sprite": "chainfiend", "hp": 1700, "r": 13, "scale": 2.2 },
	"seraph": { "name": "THE SERAPH", "sprite": "seraph", "hp": 2150, "r": 13, "scale": 2.4 },
	"rex": { "name": "REX THE FAT GOLDEN RETRIEVER", "sprite": "rex", "hp": 380, "r": 18, "scale": 2, "rift": true, "rule": "phase" },
}

const FLOORS := [
	{ "name": "THE OSSUARY", "accent": "bone", "accent_hex": "#d9d0b4", "pool": ["bat", "slime", "skeleton", "skeleton", "bat", "mushroom"], "boss": "colossus", "rooms": 8 },
	{ "name": "MIREWOOD GROTTO", "accent": "lime", "accent_hex": "#b8e05a", "pool": ["mushroom", "slime", "imp", "ghost", "bat", "skeleton"], "boss": "sporemother", "rooms": 9 },
	{ "name": "THE SUNKEN ARCHIVE", "accent": "cyan", "accent_hex": "#6fd3e0", "pool": ["bookwyrm", "drowned", "ghost", "bookwyrm", "skeleton", "slime"], "boss": "librarian", "rooms": 9 },
	{ "name": "THE CINDERFORGE", "accent": "orange", "accent_hex": "#e8873a", "pool": ["imp", "cultist", "knight", "skeleton", "imp", "mushroom"], "boss": "tyrant", "rooms": 10 },
	{ "name": "RIMEFROST VAULT", "accent": "white", "accent_hex": "#e8f6ff", "pool": ["wisp", "golem", "knight", "wisp", "ghost", "cultist"], "boss": "rimewarden", "rooms": 10 },
	{ "name": "THE HOLLOW THRONE", "accent": "purple", "accent_hex": "#a35bd6", "pool": ["cultist", "knight", "ghost", "drowned", "golem", "bookwyrm", "imp"], "boss": "regent", "rooms": 11 },
]

## Design spec step 7: five new biomes after the six original floors. Beating
## the Pale Regent still wins the original game; a rift then leads on into
## these. Extra fields: "mini" (mini-boss guarding the room before the rest
## stop), "hazard" (scripts/world/hazards.gd), "music" (track to reuse).
## Tiles come from kit6..kit10 (recoloured copies of the original kits).
const NEW_FLOORS := [
	{ "name": "RAINMARSH HAMLET", "accent": "green", "accent_hex": "#63b84f", "pool": ["bogling", "gnat", "hexwife", "gnat", "drowned", "bogling"],
	  "boss": "bogmatriarch", "mini": "mirehulk", "hazard": "bog", "music": 1, "rooms": 11 },
	{ "name": "ASHEN WARFRONT", "accent": "orange", "accent_hex": "#e8873a", "pool": ["longbowman", "lancer", "warpriest", "torchimp", "longbowman", "skeleton"],
	  "boss": "ashwarlord", "mini": "ironcaptain", "hazard": "warfront", "music": 3, "rooms": 11 },
	{ "name": "FROSTPEAK MONASTERY", "accent": "white", "accent_hex": "#e8f6ff", "pool": ["monk", "icearcher", "snowlantern", "monk", "wisp", "golem"],
	  "boss": "frozenabbot", "mini": "stoneabbot", "hazard": "icicle", "music": 4, "rooms": 12 },
	{ "name": "NIGHTSPIRE ROOFTOPS", "accent": "gold", "accent_hex": "#f2c94c", "pool": ["gunman", "cutthroat", "crow", "chimneyimp", "gunman", "crow"],
	  "boss": "crowking", "mini": "enforcer", "hazard": "vent", "music": 2, "rooms": 12 },
	{ "name": "THE ECLIPSE", "accent": "red", "accent_hex": "#d8443c", "pool": ["voidling", "shadeknight", "eclipsed", "ghost", "golem", "voidling", "cutthroat"],
	  "boss": "umbralsun", "mini": "herald", "hazard": "rift", "music": 5, "rooms": 12 },
]
## 12.2: CHAPTER II, THE MARGINS: three floors after the Unwritten, joined to the list only once
## the page is turned (run_stats["chapter"] == 2; floors()).
const CHAPTER2 := [
	{ "name": "THE INKWELL", "accent": "cyan", "accent_hex": "#4d6aa8", "pool": ["inkblot", "quillbat", "scrawler", "smudge", "inkhound", "inkblot"],
	  "boss": "inkleviathan", "mini": "inkwidow", "hazard": "tide", "music": 5, "rooms": 12 },
	{ "name": "THE BINDERY", "accent": "tan", "accent_hex": "#c8a878", "pool": ["papercut", "stitcher", "folio", "pressling", "pagewraith", "papercut"],
	  "boss": "thebinder", "mini": "bindingpress", "hazard": "spikes", "music": 2, "rooms": 12 },
	{ "name": "THE QUILL SPIRE", "accent": "gold", "accent_hex": "#f2c94c", "pool": ["quillknight", "nibling", "inkmage", "sealwarden", "scribe", "nibling"],
	  "boss": "author", "mini": "headscribe", "hazard": "rift", "music": 5, "rooms": 13 },
]
## 14.4: CHAPTER III, THE APPENDIX: three floors after the Redactor (run_stats["chapter"] == 3).
const CHAPTER3 := [
	{ "name": "THE GLOSSARY", "accent": "cyan", "accent_hex": "#4d6aa8", "pool": ["letterling", "wordworm", "definer", "thesaurus", "commaimp", "letterling"],
	  "boss": "lexicon", "mini": "lexicant", "hazard": "tide", "music": 5, "rooms": 12 },
	{ "name": "THE FOOTNOTES", "accent": "tan", "accent_hex": "#c8a878", "pool": ["asterisk", "obelus", "ibid", "citation", "smallprint", "asterisk"],
	  "boss": "erratum", "mini": "fineprint", "hazard": "spikes", "music": 2, "rooms": 12 },
	{ "name": "THE COVER", "accent": "red", "accent_hex": "#d8443c", "pool": ["gildling", "clasp", "bookmark", "spinewarden", "endpaper", "gildling"],
	  "boss": "reader", "mini": "colophon", "hazard": "rift", "music": 5, "rooms": 13 },
]
## 20.3: CHAPTER IV, THE LIBRARY: three floors after the Reader (run_stats["chapter"] == 4).
const CHAPTER4 := [
	{ "name": "THE STACKS", "accent": "tan", "accent_hex": "#c8a878", "pool": ["mothling", "dustbunny", "shelfmimic", "bookgolem", "cardsprite", "mothling"],
	  "boss": "shelver", "mini": "overdue", "hazard": "books", "music": 2, "rooms": 13 },
	{ "name": "THE READING ROOM", "accent": "lime", "accent_hex": "#7ab04a", "pool": ["shusher", "lampwisp", "bookend", "pagewing", "spectacle", "shusher"],
	  "boss": "hush", "mini": "quiet", "hazard": "lamps", "music": 3, "rooms": 13 },
	{ "name": "THE HEARTH", "accent": "orange", "accent_hex": "#e8873a", "pool": ["cinderpage", "ashworm", "pokerknight", "firedog", "sootling", "cinderpage"],
	  "boss": "critic", "mini": "kindling", "hazard": "hearth", "music": 4, "rooms": 14 },
]

## Index of the original final floor (the Hollow Throne).
const THRONE_FLOOR := 5

static var _floors: Array = []

## All floors: the six originals, then the new biomes. --classic leaves them out.
static func floors() -> Array:
	if G.run_stats.get("chapter", 1) == 2 and GameData.rogues():
		if _floors2.is_empty():
			_floors2 = _main_floors() + CHAPTER2
		return _floors2   # 12.2: Chapter II
	if G.run_stats.get("chapter", 1) == 3 and GameData.rogues():
		if _floors3.is_empty():
			_floors3 = _main_floors() + CHAPTER2 + CHAPTER3
		return _floors3   # 14.4: Chapter III
	if G.run_stats.get("chapter", 1) == 4 and GameData.rogues():
		if _floors4.is_empty():
			_floors4 = _main_floors() + CHAPTER2 + CHAPTER3 + CHAPTER4
		return _floors4   # 20.3: Chapter IV
	return _main_floors()

static func _main_floors() -> Array:
	if _floors.is_empty():
		_floors = FLOORS.duplicate()
		if not DebugArgs.has("classic"):
			# The expanded game: a few new foes join the original floors (the original data is untouched).
			for i in EnemyAI2.OLD_FLOOR_EXTRA:
				var f: Dictionary = _floors[i].duplicate(true)
				f["pool"] = f["pool"] + EnemyAI2.OLD_FLOOR_EXTRA[i]
				_floors[i] = f
			_floors.append_array(NEW_FLOORS)
	return _floors

## Music track for a floor (new floors reuse original tracks).
static func floor_music(i: int) -> int:
	return floors()[i].get("music", i)
const BOSS_TRACK := 6

const SPRITE_COLOR := {
	"bat": "#a35bd6", "slime": "#63b84f", "skeleton": "#d9d0b4", "mushroom": "#d8443c", "cultist": "#8a2a33",
	"imp": "#d8443c", "knight": "#8b8f9c", "ghost": "#f4ecd8", "bookwyrm": "#7a5236", "drowned": "#63b84f",
	"wisp": "#6fd3e0", "golem": "#4d9be6", "colossus": "#d9d0b4", "sporemother": "#a35bd6", "librarian": "#2b4f8a",
	"tyrant": "#e8873a", "rimewarden": "#6fd3e0", "regent": "#a35bd6",
	"bogling": "#3f7a5a", "gnat": "#8b8f9c", "hexwife": "#63b84f", "mirehulk": "#63b84f", "longbowman": "#d9d0b4",
	"lancer": "#e8873a", "warpriest": "#e8873a", "torchimp": "#f2c94c", "ironcaptain": "#8b8f9c", "monk": "#e8873a",
	"icearcher": "#c8f0ff", "snowlantern": "#e8f6ff", "stoneabbot": "#8b8f9c", "gunman": "#4e4a5e", "cutthroat": "#5c3483",
	"crow": "#1a1423", "chimneyimp": "#a35bd6", "enforcer": "#4e4a5e", "voidling": "#d8443c", "shadeknight": "#2a2838",
	"eclipsed": "#d8443c", "herald": "#8a2a33", "bogmatriarch": "#3f7a5a", "ashwarlord": "#d8443c",
	"frozenabbot": "#e8f6ff", "crowking": "#5c3483", "umbralsun": "#d8443c",
	"judge": "#f2c94c", "cinderking": "#e8873a", "unwritten": "#f4ecd8", "redactor": "#16141c",
	"haggler": "#5c3483", "scrounger": "#8b8f9c", "raider": "#8a7a5a", "cogling": "#c9a35a", "steamjack": "#8a6a4a", "boltslinger": "#6fd3e0", "gearhound": "#a8705a", "rivetlobber": "#e8873a", "brasswasp": "#f2c94c", "foreman": "#e8873a", "greatengine": "#e8b84a", "frostmite": "#a8e0ff", "rimebrute": "#6a8aa8", "shardcaster": "#7ff0ff", "frostfang": "#c8d8e8", "snowlobber": "#e8f4ff", "glimmerwisp": "#c8f0ff", "hoarknight": "#8fd8ff", "glacialmaw": "#8fd8ff", "admiral": "#8a6a4a", "golemking": "#8a8f9c", "archmage": "#4d9be6", "phoenix": "#e8873a", "wyrm": "#c8f0ff", "chainfiend": "#d8443c", "seraph": "#f2c94c", "inkblot": "#2a2a4a", "letterling": "#e8e0d0", "wordworm": "#4d6aa8", "definer": "#2b4f8a", "thesaurus": "#5a3a2a", "commaimp": "#16141c", "lexicant": "#2b4f8a", "asterisk": "#f2c94c", "obelus": "#8a6a4a", "ibid": "#c8c0e0", "citation": "#5a4a3a", "smallprint": "#3a3028", "fineprint": "#3a3028", "gildling": "#f2c94c", "clasp": "#c9a35a", "bookmark": "#d8443c", "spinewarden": "#6a2a2a", "endpaper": "#8a3a5a", "colophon": "#6a2a2a", "lexicon": "#2b4f8a", "erratum": "#d8443c", "reader": "#e0a47a", "mothling": "#9a8a72", "dustbunny": "#a8a8b0", "shelfmimic": "#6a2a3a", "bookgolem": "#6a4a2a", "cardsprite": "#e8dcc0", "overdue": "#6a4a2a", "shusher": "#6a8a7a", "lampwisp": "#2f8a4a", "bookend": "#8b8f9c", "pagewing": "#f4ecd8", "spectacle": "#c9a35a", "quiet": "#24243a", "cinderpage": "#ff8a3a", "ashworm": "#5e5a6e", "pokerknight": "#3a3850", "firedog": "#3a3a44", "sootling": "#2a2838", "kindling": "#8a5a2a", "shelver": "#6a4a2a", "hush": "#2a3a6a", "critic": "#3a1a2a", "quillbat": "#4d6aa8", "scrawler": "#3a3a5a", "smudge": "#5a5a7a", "inkhound": "#2a2a4a", "inkwidow": "#3a2a5a", "papercut": "#f4ecd8", "stitcher": "#c8a878", "folio": "#a8885a", "pressling": "#8a6a4a", "pagewraith": "#f4ecd8", "bindingpress": "#6b4a2a", "quillknight": "#4a4a6a", "nibling": "#f2c94c", "inkmage": "#3a2a5a", "sealwarden": "#d8443c", "scribe": "#c8a878", "headscribe": "#f2c94c", "inkleviathan": "#4d6aa8", "thebinder": "#c8a878", "author": "#f2c94c", "holycow": "#f4ecd8",
	# Rift worlds and event rooms.
	"inmate": "#63b84f", "grenadier": "#d8443c", "jailer": "#3f7a5a", "turnkey": "#3f7a5a", "graveborn": "#7a3a8c",
	"bandsman": "#7a5236", "fiendling": "#8a2a33", "blackknight": "#2a2838", "carrionknight": "#2a2838", "drone": "#6fd3e0",
	"glitch": "#5c3483", "chrome": "#8b8f9c", "turret": "#6fd3e0", "broker": "#e86fb4", "thug": "#e86fb4", "molotov": "#2f6b3a",
	"copper": "#4d9be6", "bomber": "#d8443c", "mayor": "#f2c94c", "orderly": "#f4ecd8", "crawler": "#a8705a",
	"static": "#8b8f9c", "tollkeeper": "#2a2838", "rustbutcher": "#7a5236", "neighbour": "#e86fb4", "robovac": "#8b8f9c",
	"burglar": "#2a2838", "gnome": "#d8443c", "landlord": "#e86fb4", "gangster": "#2a2838", "biker": "#d8443c",
	"riotcop": "#2b4f8a", "kingpin": "#f4ecd8", "outlaw": "#7a5236", "dynamiter": "#4d9be6", "sharpshooter": "#63b84f",
	"coyote": "#a8705a", "marshal": "#7a5236", "galewarden": "#9fc3ee", "target": "#d8443c", "skykite": "#9fc3ee", "gustling": "#c8f0ff", "stormharpy": "#a35bd6", "thunderhead": "#8b8f9c", "mirrorwing": "#6fd3e0", "rampartguard": "#3f7a5a", "sludgecrawler": "#63b84f", "chainwarden": "#8b8f9c", "tidecaller": "#2b4f8a", "longpike": "#f4ecd8", "shellpriest": "#d8443c", "dervish": "#d8443c", "deacon": "#f4ecd8", "beltfeeder": "#f2c94c", "beltlink": "#f2c94c", "ammomimic": "#7a5236", "tombspider": "#5c3483", "candlewight": "#f4ecd8", "gargoyle": "#8b8f9c", "wardrummer": "#8a2a33", "bloodleech": "#d8443c", "rotking": "#3f7a5a", "highcaliber": "#d8443c", "squallheron": "#9fc3ee", "tidecaptain": "#3f7a5a", "bellringer": "#5c3483", "casingrat": "#8b8f9c", "goblin": "#63b84f", "mimic": "#7a5236", "shadow": "#3c1d47",
}

## Ember Shrine: things to unlock between runs.
const UNLOCKS := [
	{ "id": "hero_gravedigger", "name": "THE GRAVEDIGGER", "desc": "A NEW HERO WHO SPRAYS GRAVE DIRT", "cost": 40 },
	{ "id": "hero_alchemist", "name": "THE ALCHEMIST", "desc": "A NEW HERO WITH POISON FLASKS", "cost": 80 },
	{ "id": "hero_warden", "name": "THE WARDEN", "desc": "A NEW HERO WITH A RETURNING LANTERN", "cost": 140 },
	{ "id": "cache1", "name": "RELIC CACHE I", "desc": "ADDS 10 COMMON RELICS TO THE CRYPT", "cost": 30 },
	{ "id": "cache2", "name": "RELIC CACHE II", "desc": "ADDS 12 RARE RELICS TO THE CRYPT", "cost": 70 },
	{ "id": "cache3", "name": "RELIC CACHE III", "desc": "ADDS 10 EPIC AND LEGENDARY RELICS", "cost": 120 },
	{ "id": "perk_gold", "name": "DEEP POCKETS", "desc": "START EVERY RUN WITH 20 GOLD", "cost": 25 },
	{ "id": "perk_bombs", "name": "HEAVY SATCHEL", "desc": "START EVERY RUN WITH 2 EXTRA BOMBS", "cost": 20 },
	{ "id": "perk_potion", "name": "SPARE FLASK", "desc": "START EVERY RUN WITH 1 EXTRA POTION", "cost": 35 },
	{ "id": "perk_key", "name": "KEY RING", "desc": "START EVERY RUN WITH A KEY", "cost": 30 },
	{ "id": "perk_heart", "name": "IRON WILL", "desc": "START EVERY RUN WITH +1 MAX HEART", "cost": 70 },
	{ "id": "perk_relic", "name": "LUCKY START", "desc": "START EVERY RUN WITH A RANDOM RELIC", "cost": 90 },
	{ "id": "perk_choice", "name": "KEEN EYE", "desc": "CHESTS OFFER 4 RELICS INSTEAD OF 3", "cost": 110 },
]

const DREAD_DESC := [
	"NORMAL", "FOES +15% HEALTH", "FOES +30% HEALTH, FASTER SHOTS", "MORE ELITES, PRICIER SHOPS",
	"GUARDIANS ENRAGE EARLY", "START WITH 1 LESS HEART",
]

## Experience per kill (01b_traits.rb).
const ENEMY_XP := { "bat": 2, "slime": 3, "slimelet": 1, "skeleton": 3, "mushroom": 3, "cultist": 4, "imp": 3,
	# Stage 7 foes.
	"bogling": 4, "gnat": 2, "hexwife": 4, "longbowman": 4, "lancer": 6, "warpriest": 4, "torchimp": 3, "monk": 5,
	"icearcher": 4, "snowlantern": 4, "gunman": 5, "cutthroat": 4, "crow": 2, "chimneyimp": 3, "voidling": 4,
	"shadeknight": 7, "eclipsed": 5, "mirehulk": 40, "ironcaptain": 45, "stoneabbot": 50, "enforcer": 55, "herald": 60,
	"knight": 6, "ghost": 3, "bookwyrm": 3, "drowned": 4, "wisp": 3, "golem": 7,
	# Rift worlds and event rooms.
	"inmate": 4, "grenadier": 4, "jailer": 6, "graveborn": 4, "bandsman": 4, "fiendling": 3, "blackknight": 7, "drone": 3,
	"glitch": 4, "chrome": 7, "turret": 4, "thug": 4, "molotov": 4, "copper": 5, "bomber": 3, "orderly": 4, "crawler": 2,
	"static": 4, "tollkeeper": 5, "neighbour": 4, "robovac": 5, "burglar": 4, "gnome": 4, "gangster": 5, "biker": 5,
	"riotcop": 7, "outlaw": 5, "dynamiter": 4, "sharpshooter": 4, "coyote": 2, "goblin": 10, "haggler": 60, "scrounger": 4, "raider": 5, "cogling": 2, "steamjack": 7, "boltslinger": 4, "gearhound": 3, "rivetlobber": 4, "brasswasp": 2, "foreman": 45, "frostmite": 2, "rimebrute": 7, "shardcaster": 4, "frostfang": 3, "snowlobber": 4, "glimmerwisp": 2, "hoarknight": 45, "inkblot": 5, "letterling": 3, "wordworm": 5, "definer": 5, "thesaurus": 8, "commaimp": 3, "lexicant": 60, "asterisk": 3, "obelus": 5, "ibid": 5, "citation": 7, "smallprint": 5, "fineprint": 60, "gildling": 3, "clasp": 9, "bookmark": 5, "spinewarden": 7, "endpaper": 6, "colophon": 60, "mothling": 3, "dustbunny": 5, "shelfmimic": 6, "bookgolem": 9, "cardsprite": 5, "overdue": 60, "shusher": 6, "lampwisp": 4, "bookend": 9, "pagewing": 3, "spectacle": 5, "quiet": 60, "cinderpage": 4, "ashworm": 6, "pokerknight": 8, "firedog": 6, "sootling": 3, "kindling": 60, "quillbat": 3, "scrawler": 5, "smudge": 4, "inkhound": 4, "inkwidow": 65, "papercut": 3, "stitcher": 8, "folio": 5, "pressling": 5, "pagewraith": 3, "bindingpress": 70, "quillknight": 7, "nibling": 3, "inkmage": 6, "sealwarden": 6, "scribe": 6, "headscribe": 75, "mimic": 15, "shadow": 40,
	"turnkey": 45, "carrionknight": 45, "broker": 45, "mayor": 45, "rustbutcher": 45, "landlord": 45, "kingpin": 45, "marshal": 45, "galewarden": 45, "target": 0, "rotking": 45, "highcaliber": 45, "squallheron": 40, "tidecaptain": 40, "bellringer": 40, "casingrat": 6, "skykite": 3, "gustling": 3, "stormharpy": 4, "thunderhead": 4, "mirrorwing": 4, "rampartguard": 6, "sludgecrawler": 4, "chainwarden": 5, "tidecaller": 5, "longpike": 4, "shellpriest": 5, "dervish": 5, "deacon": 5, "beltfeeder": 6, "beltlink": 2, "ammomimic": 6, "tombspider": 3, "candlewight": 4, "gargoyle": 6, "wardrummer": 4, "bloodleech": 3 }

static func xp_needed(level: int) -> int:
	return roundi(10 + 7 * pow(level, 1.35))

## Room choice: rewards shown on each door before you pick it (01b_traits.rb + 04b_items.rb).
const REWARDS := {
	"relic": { "name": "RELIC", "icon": "chest", "col": "gold" }, "gold": { "name": "GOLD", "icon": "gem", "col": "gold" },
	"heal": { "name": "HEALING", "icon": "heartPick", "col": "pink" }, "supply": { "name": "BOMBS + KEY", "icon": "bomb", "col": "white" },
	"armor": { "name": "ARMOR", "icon": "armor", "col": "cyan" }, "level": { "name": "LEVEL UP", "icon": "icon_level", "col": "lime" },
	"embers": { "name": "EMBERS", "icon": "ember", "col": "orange" }, "rare": { "name": "IRON CHEST", "icon": "chestIron", "col": "cyan" },
	"weapon": { "name": "WEAPON", "icon": "icon_weapon", "col": "orange" }, "gear": { "name": "GEAR", "icon": "icon_gear", "col": "cyan" },
}
const ROOM_KINDS := {
	"combat": { "name": "FIGHT", "icon": "icon_combat", "col": "white" }, "elite": { "name": "ELITE FIGHT", "icon": "icon_elite", "col": "red" },
	"treasure": { "name": "TREASURE", "icon": "chest", "col": "gold" }, "shop": { "name": "SHOP", "icon": "icon_shop", "col": "green" },
	"shrine": { "name": "SHRINE", "icon": "icon_shrine", "col": "purple" }, "challenge": { "name": "CHALLENGE", "icon": "bell", "col": "cyan" },
	"vault": { "name": "VAULT", "icon": "lock", "col": "orange" }, "secret": { "name": "HIDDEN ROOM", "icon": "icon_secret", "col": "pink" },
	"boss": { "name": "GUARDIAN", "icon": "icon_skull", "col": "red" }, "rest": { "name": "CAMPFIRE", "icon": "icon_fire", "col": "orange" },
	# Rift worlds (a themed side stage) and mystery rooms (a random event).
	"rift": { "name": "RIFT", "icon": "riftdoor", "col": "pink" }, "mystery": { "name": "MYSTERY", "icon": "icon_secret", "col": "pink" },
	# The floor map: the way back to where the floor began, and out of a room off the map.
	"start": { "name": "ENTRANCE", "icon": "icon_level", "col": "grey" }, "back": { "name": "BACK", "icon": "icon_level", "col": "grey" },
	"barn": { "name": "REX'S BARN", "icon": "icon_barn", "col": "gold" },   # a hidden boss (rex.gd)
}

## What a door shows: its room kind, with a rift door named after its world
## (and after how deep into the rift it leads).
static func door_kind(c: Dictionary) -> Dictionary:
	var kind: Dictionary = ROOM_KINDS[c["type"]]
	if c["type"] != "rift":
		return kind
	var th := Themes.by_id(c.get("theme", ""))
	var step: int = c.get("step", 0)
	var name: String = th.get("name", "RIFT")
	if step == 1:
		name = "DEEPER IN"
	elif step == 2:
		name = GameData.ENEMIES[th["champion"]]["name"]
	elif step == 3:
		name = GameData.BOSSES[th["guardian"]]["name"]   # deeper still: the world's guardian
	return { "name": name, "icon": "icon_skull" if step >= 2 else kind["icon"], "col": "red" if step >= 2 else kind["col"] }

## Door frame colours per room type (Render.rb ROOM_COL).
const ROOM_COL := { "boss": "#d8443c", "treasure": "#f2c94c", "shop": "#63b84f", "shrine": "#a35bd6", "combat": "#8b8f9c",
	"elite": "#d8443c", "rest": "#e8873a", "vault": "#e8873a", "secret": "#e86fb4", "challenge": "#6fd3e0",
	"rift": "#e86fb4", "mystery": "#a35bd6", "start": "#5c5a78", "back": "#5c5a78", "barn": "#c9a35a" }
