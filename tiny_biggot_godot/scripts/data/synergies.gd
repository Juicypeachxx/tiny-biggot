class_name Synergies
extends RefCounted
## Tag synergies and named combos (design spec 2c). Content arrives in the
## content batches; this file defines the format.
##
## TAG_SYNERGIES: { "tag": t, "tiers": [ { "need": n, "name", "desc", "effects": [...] }, ... ] }
##   A tier switches on when the player holds `need` points of tag t, counted
##   over new-content relics, weapon, gear and trait ranks. Effects must be
##   reversible (add, mul, pct, hook and procs) because a tier switches off
##   again if gear is swapped away.
## COMBOS: { "id", "name", "desc", "needs": ["relic:id", "weapon:id", "gear:id", "trait:id", ...], "effects": [...] }
##   (ids are unique per table only: the originals have a relic and a weapon
##   both called "lantern", and a relic and a trait both called "echo").
##   Switches on while the player owns every listed item (relic, weapon,
##   gear piece or trait). The player sees a "COMBO" banner when one activates.

const TAG_SYNERGY_DATA := [
	{ "tag": "edge", "tiers": [{ "need": 3, "name": "KEEN", "desc": "+10% CRIT", "effects": [["add", "crit", 0.1]] }, { "need": 6, "name": "RAZOR'S EDGE", "desc": "CRITS DEAL +0.5X", "effects": [["add", "crit_mult", 0.5]] }] },
	{ "tag": "blood", "tiers": [{ "need": 3, "name": "BLOODLETTING", "desc": "HITS BLEED 10% OF THE TIME", "effects": [{ "on": "on_hit", "chance": 0.1, "do": [["status", "bleed", 1]] }] }, { "need": 6, "name": "RED TIDE", "desc": "KILLS HEAL 3% OF THE TIME", "effects": [{ "on": "on_kill", "chance": 0.03, "do": [["heal", 1]] }] }] },
	{ "tag": "pyre", "tiers": [{ "need": 3, "name": "KINDLED", "desc": "+10% BURN", "effects": [["add", "burn", 0.1]] }, { "need": 6, "name": "WILDFIRE", "desc": "BURNING FOES SPREAD FLAME ON DEATH", "effects": [{ "on": "on_kill", "if": "burning", "do": [["status", "burn", 1]] }] }] },
	{ "tag": "venom", "tiers": [{ "need": 3, "name": "TAINTED", "desc": "+1 POISON ON HIT", "effects": [["add", "poison", 1]] }, { "need": 6, "name": "PLAGUEBRINGER", "desc": "POISON DAMAGE +50%", "effects": [["add", "poison_dmg", 0.5]] }] },
	{ "tag": "storm", "tiers": [{ "need": 3, "name": "CHARGED AIR", "desc": "+10% ARC CHANCE", "effects": [["add", "chain", 0.1]] }, { "need": 6, "name": "THUNDERHEAD", "desc": "EVERY 5S, LIGHTNING STRIKES", "effects": [{ "on": "every_n_seconds", "period": 5.0, "do": [["lightning", 1.0]] }] }] },
	{ "tag": "arcane", "tiers": [{ "need": 3, "name": "SPELLWOVEN", "desc": "+1 PIERCE", "effects": [["add", "pierce", 1]] }, { "need": 6, "name": "STARFALL", "desc": "+1 PROJECTILE", "effects": [["add", "count", 1]] }] },
	{ "tag": "swarm", "tiers": [{ "need": 3, "name": "FLOCK", "desc": "+1 WISP", "effects": [["add", "familiars", 1]] }, { "need": 6, "name": "LEGION", "desc": "WISPS DEAL +50%", "effects": [["add", "fam_dmg", 0.5]] }] },
	{ "tag": "shadow", "tiers": [{ "need": 3, "name": "LIGHT FEET", "desc": "ROLLS RECHARGE 15% FASTER", "effects": [["mul", "dodge_cd", 0.85]] }, { "need": 6, "name": "PHANTOM", "desc": "+1 ROLL CHARGE", "effects": [["add", "dodge_charges", 1], ["add", "charges", 1]] }] },
	{ "tag": "bulwark", "tiers": [{ "need": 3, "name": "STALWART", "desc": "+10 THORNS", "effects": [["add", "thorns", 10]] }, { "need": 6, "name": "IRONCLAD", "desc": "+1 MAX HEART", "effects": [["add", "max_hp", 2]] }] },
	{ "tag": "fury", "tiers": [{ "need": 3, "name": "SEETHING", "desc": "+10% DAMAGE", "effects": [["pct", "dmg", 0.1]] }, { "need": 6, "name": "WARLORD", "desc": "+15% FIRE RATE", "effects": [["pct", "rate", 0.15]] }] },
	{ "tag": "fortune", "tiers": [{ "need": 3, "name": "PROSPEROUS", "desc": "+15% GOLD", "effects": [["mul", "gold_mult", 1.15]] }, { "need": 6, "name": "MIDAS REACH", "desc": "+8% DAMAGE PER 100 GOLD", "effects": [["hook", "gold_dmg", 0.08]] }] },
	{ "tag": "malice", "tiers": [{ "need": 3, "name": "DREADFUL", "desc": "10% OF HITS CURSE", "effects": [{ "on": "on_hit", "chance": 0.1, "do": [["status", "curse", 1]] }] }, { "need": 6, "name": "UNHOLY", "desc": "CURSED FOES ARE VULNERABLE", "effects": [{ "on": "on_hit", "cd": 0.2, "if": "cursed", "do": [["status", "vulnerable", 1]] }] }] },
]
const COMBO_DATA := [
	{ "id": "chainreaction", "name": "CHAIN REACTION", "desc": "SHOCKED FOES YOU KILL CALL LIGHTNING THAT SHOCKS AGAIN", "needs": ["weapon:capacitor", "relic:stormjar"], "effects": [{ "on": "on_kill", "if": "shocked", "do": [["lightning", 1.0], ["status", "shock", 2]] }] },
	{ "id": "bloodmoney", "name": "BLOOD MONEY", "desc": "EACH ROOM'S HEART COST PAYS 5 GOLD. MORE GOLD DAMAGE", "needs": ["relic:cursedcoin", "relic:dragonhoard"], "effects": [{ "on": "on_room_enter", "do": [["gold", 5]] }, ["hook", "gold_dmg", 0.1]] },
	{ "id": "mirrorhall", "name": "HALL OF MIRRORS", "desc": "EVERY SHOT ALSO FIRES A RING OF 6", "needs": ["weapon:thousandcuts", "relic:prismshard"], "effects": [{ "on": "on_shoot", "do": [["nova", 6, 0.35, "spark"]] }] },
	{ "id": "deathspiral", "name": "DEATH SPIRAL", "desc": "AT LOW HEALTH, CRITS HEAL AND OVERCRIT DOUBLES", "needs": ["relic:lastbreath", "relic:killingblow"], "effects": [{ "on": "on_crit", "chance": 0.05, "if": "low_hp", "do": [["heal", 1]] }, ["add", "overcrit", 1.0]] },
	{ "id": "nightmarehost", "name": "THE NIGHTMARE HOST", "desc": "EVERY KILL RAISES A WISP", "needs": ["weapon:courtofshades", "relic:hivemind"], "effects": [{ "on": "on_kill", "do": [["summon", 6.0]] }] },
	{ "id": "dancingflame", "name": "DANCING FLAME", "desc": "ROLLING LEAVES AN EXPLOSION", "needs": ["gear:cinderboots", "relic:afterimage"], "effects": [{ "on": "on_roll", "do": [["explode", 30, 0.8]] }] },
	{ "id": "toxicwalls", "name": "TOXIC FORTRESS", "desc": "WHEN HIT, POISON THE NEAREST FOE HEAVILY", "needs": ["relic:spikedcollar", "relic:toadstool"], "effects": [{ "on": "on_damage_taken", "do": [["status", "poison", 6]] }] },
	{ "id": "goldenduel", "name": "GOLDEN DUEL", "desc": "CRITS PAY 2 GOLD", "needs": ["weapon:gildedrapier", "gear:duel_ring"], "effects": [{ "on": "on_crit", "do": [["gold", 2]] }] },
]

static var TAG_SYNERGIES: Array = TAG_SYNERGY_DATA.duplicate(true)
static var COMBOS: Array = COMBO_DATA.duplicate(true)
