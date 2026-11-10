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
	# Content batch 4 (chaos) combos.
	{ "id": "bigbang", "name": "BIG BANG", "desc": "FOES YOU KILL CALL DOWN A METEOR (EVERY 0.5S)", "needs": ["weapon:singularity", "gear:collapsedstar"], "effects": [{ "on": "on_kill", "cd": 0.5, "do": [["meteor", 1.5, 30]] }] },
	{ "id": "partytime", "name": "PARTY TIME", "desc": "EVERY 3S IN A FIGHT, 12 SPARKS SPIRAL OUT AND YOU FIRE 20% FASTER", "needs": ["gear:partyhat", "weapon:discoball"], "effects": [{ "on": "every_n_seconds", "period": 3.0, "if": "fighting", "do": [["nova", 12, 0.5, "spark", 2.0], ["buff", "rate", 0.2, 3.0]] }] },
	{ "id": "queenbee", "name": "QUEEN BEE", "desc": "EVERY KILL HATCHES A WISP FOR 5S. WISPS FIRE 30% FASTER", "needs": ["weapon:beehive", "gear:beekeeperhat"], "effects": [{ "on": "on_kill", "do": [["summon", 5.0]] }, ["mul", "fam_rate", 1.3]] },
	{ "id": "goldrush", "name": "GOLD RUSH", "desc": "KILLS PAY 2 GOLD AND GIVE +10% FIRE RATE FOR 2S", "needs": ["weapon:midascannon", "gear:midasglove"], "effects": [{ "on": "on_kill", "do": [["gold", 2], ["buff", "rate", 0.1, 2.0]] }] },
	{ "id": "demoderby", "name": "DEMOLITION DERBY", "desc": "EVERY ROLL DROPS A LIT BOMB THAT CANNOT HURT YOU", "needs": ["gear:rocketboots", "gear:bombvest"], "effects": [{ "on": "on_roll", "cd": 1.0, "do": [["bomb", 0.4]] }] },
	{ "id": "highroller", "name": "HIGH ROLLER", "desc": "CRITS ROLL THE CHAOS DIE (EVERY 4S)", "needs": ["gear:chaosdie", "weapon:slotmachine"], "effects": [{ "on": "on_crit", "cd": 4.0, "do": [["chaos"]] }] },
	{ "id": "absolutezero", "name": "ABSOLUTE ZERO", "desc": "CHILLED FOES YOU KILL FREEZE EVERY FOE NEAR YOU FOR 1S", "needs": ["weapon:frostfist", "gear:slipperysoles"], "effects": [{ "on": "on_kill", "cd": 1.5, "if": "chilled", "do": [["status_area", "stun", 1, 80], ["status_area", "chill", 2, 80], ["vfx", "ring", "#6fd3e0", 80]] }] },
	{ "id": "identitycrisis", "name": "IDENTITY CRISIS", "desc": "20% OF ATTACKS FIRE 3 EXTRA SHOTS", "needs": ["gear:bigring", "gear:tinyring"], "effects": [{ "on": "on_shoot", "chance": 0.2, "do": [["shoot", 3, 0.8, "", 0.2]] }] },
	{ "id": "eruption", "name": "ERUPTION", "desc": "EVERY 3S IN A FIGHT, 2 METEORS FALL", "needs": ["weapon:volcano", "gear:pocketsun"], "effects": [{ "on": "every_n_seconds", "period": 3.0, "if": "fighting", "do": [["meteor", 2.0, 30], ["meteor", 2.0, 30]] }] },
	{ "id": "thunderdome", "name": "THUNDERDOME", "desc": "EVERY 2S IN A FIGHT, 3 BOLTS STRIKE RANDOM FOES", "needs": ["weapon:teslacoil", "gear:stormcloud"], "effects": [{ "on": "every_n_seconds", "period": 2.0, "if": "fighting", "do": [["bolts", 3, 1.0]] }] },
	{ "id": "haunted", "name": "HAUNTED HOUSE", "desc": "WHEN HIT, 3 WISPS RISE FOR 10S", "needs": ["gear:ghostsheet", "weapon:necroflute"], "effects": [{ "on": "on_damage_taken", "do": [["summon", 10.0], ["summon", 10.0], ["summon", 10.0]] }] },
	{ "id": "wishmaster", "name": "WISHMASTER", "desc": "EVERY RANDOM EFFECT HAPPENS TWICE", "needs": ["gear:monkeypaw", "gear:chaosdie"], "effects": [["hook", "chaos_double", 1]] },
	{ "id": "clowncar", "name": "CLOWN CAR", "desc": "CRITS RELEASE A WISP FOR 5S", "needs": ["weapon:clownhammer", "gear:jester_cap"], "effects": [{ "on": "on_crit", "cd": 0.5, "do": [["summon", 5.0]] }] },
	{ "id": "ripandtear", "name": "RIP AND TEAR", "desc": "KILLS GIVE +8% DAMAGE FOR 4S AND HEAL 4% OF THE TIME", "needs": ["weapon:chainsaw", "gear:boxinggloves"], "effects": [{ "on": "on_kill", "do": [["buff", "dmg", 0.08, 4.0]] }, { "on": "on_kill", "chance": 0.04, "do": [["heal", 1]] }] },
	{ "id": "targetlock", "name": "TARGET LOCK", "desc": "EVERY 3S IN A FIGHT A METEOR FALLS FOR 300%", "needs": ["weapon:orbitallaser", "gear:magnethelm"], "effects": [{ "on": "every_n_seconds", "period": 3.0, "if": "fighting", "do": [["meteor", 3.0, 34]] }] },
	{ "id": "bullethell", "name": "BULLET HELL", "desc": "25% OF ATTACKS ALSO FIRE A SPIRAL OF 12 SPARKS", "needs": ["weapon:crossfirebow", "gear:twinring"], "effects": [{ "on": "on_shoot", "chance": 0.25, "do": [["nova", 12, 0.4, "spark", 2.0]] }] },
	{ "id": "eventhorizon", "name": "EVENT HORIZON", "desc": "ROLLING DRAGS FOES TO WHERE YOU STOOD", "needs": ["weapon:gravitymaul", "gear:void_amulet"], "effects": [{ "on": "on_roll", "cd": 1.0, "do": [["pull", 110, 260]] }] },
	# 14.3 (his ask, 7 Oct): HIDDEN trait combos. Two particular traits together unlock a third
	# power; nobody is told which until it is found (Meta.meta["combos_found"]), then trait cards say.
	{ "id": "t_infernalkeg", "hidden": true, "name": "INFERNAL KEG", "desc": "ROLLING DROPS A LIT BOMB ON A POOL OF FIRE", "needs": ["trait:z_scorch", "trait:z_chainreact"], "effects": [{ "on": "on_roll", "cd": 1.0, "do": [["bomb", 0.5]] }] },
	{ "id": "t_stormfront", "hidden": true, "name": "STORMFRONT", "desc": "CRITS CALL LIGHTNING (EVERY 0.5S)", "needs": ["trait:z_static", "trait:z_thunderstep"], "effects": [{ "on": "on_crit", "cd": 0.5, "do": [["lightning", 1.0]] }] },
	{ "id": "t_singularity", "hidden": true, "name": "SINGULARITY", "desc": "EVERY 6S IN A FIGHT, A METEOR FALLS ON THE CROWD", "needs": ["trait:z_horizon", "trait:z_bankshot"], "effects": [{ "on": "every_n_seconds", "period": 6.0, "if": "fighting", "do": [["meteor", 2.5, 40]] }] },
	{ "id": "t_cursedhalo", "hidden": true, "name": "CURSED HALO", "desc": "EVERY 2S IN A FIGHT, CURSE EVERY FOE AROUND YOU", "needs": ["trait:z_hexback", "trait:x_halo"], "effects": [{ "on": "every_n_seconds", "period": 2.0, "if": "fighting", "do": [["status_area", "curse", 1, 120]] }] },
	{ "id": "t_fountain", "hidden": true, "name": "FOUNTAIN", "desc": "HEALING AT FULL HEALTH ALSO ERASES NEARBY SHOTS", "needs": ["trait:z_overflow", "trait:x_heart"], "effects": [{ "on": "on_overheal", "do": [["clear_shots", 80], ["vfx", "ring", "#6fd3e0", 80]] }] },
	{ "id": "t_finalact", "hidden": true, "name": "FINAL ACT", "desc": "CLEARING A ROOM HEALS HALF A HEART AND REFUNDS 2 ROLLS", "needs": ["trait:z_lastword", "trait:sh_dance"], "effects": [{ "on": "on_room_clear", "do": [["heal", 1], ["refund_roll"], ["refund_roll"]] }] },
	{ "id": "t_tailormade", "hidden": true, "name": "TAILOR-MADE", "desc": "ENTERING A ROOM GIVES 1 ARMOR", "needs": ["trait:z_wardrobe", "trait:x_tailor"], "effects": [{ "on": "on_room_enter", "do": [["armor", 1]] }] },
	{ "id": "t_starstorm", "hidden": true, "name": "STARSTORM", "desc": "EVERY 4TH KILL CALLS A METEOR", "needs": ["trait:z_comet", "trait:x_inferno"], "effects": [{ "on": "on_kill", "every": 4, "do": [["meteor", 2.0, 32]] }] },
	{ "id": "t_slipstream", "hidden": true, "name": "SLIPSTREAM", "desc": "ROLLING FIRES A RING OF 8 SPARKS", "needs": ["trait:y_momentum", "trait:x_tailwind"], "effects": [{ "on": "on_roll", "do": [["nova", 8, 0.8, "spark"]] }] },
	{ "id": "t_kingsransom", "hidden": true, "name": "KING'S RANSOM", "desc": "ELITE KILLS RAIN COINS AND PAY 10 GOLD", "needs": ["trait:x_crown", "trait:g_bounty"], "effects": [{ "on": "on_kill", "if": "elite", "do": [["gold", 10], ["drop", "coin"], ["drop", "coin"], ["drop", "coin"]] }] },
	{ "id": "t_blackplague", "hidden": true, "name": "BLACK PLAGUE", "desc": "30% OF HITS ON POISONED FOES CURSE THEM", "needs": ["trait:x_plague", "trait:z_hexback"], "effects": [{ "on": "on_hit", "if": "poisoned", "chance": 0.3, "do": [["status", "curse", 1]] }] },
	{ "id": "t_luckystrike", "hidden": true, "name": "LUCKY STRIKE", "desc": "GOLDEN TOUCH HAPPENS TWICE AS OFTEN AND EVERY ROOM PAYS 3 GOLD", "needs": ["trait:z_midas", "trait:z_dice"], "effects": [{ "on": "on_hit", "chance": 0.03, "do": [["transmute", 6]] }, { "on": "on_room_enter", "do": [["gold", 3]] }] },
	{ "id": "bubblebath", "name": "BUBBLE BATH", "desc": "YOUR SHOTS SPLIT IN TWO WHEN THEY HIT", "needs": ["weapon:bubblewand", "gear:partyhat"], "effects": [["hook", "split", 2]] },
	# Stage 26 (his word, 9 Oct): synergies of the new traits, weapons and reactions.
	{ "id": "t_steamengine", "hidden": true, "name": "STEAM ENGINE", "desc": "EVERY REACTION ALSO CALLS LIGHTNING", "needs": ["weapon:steamblade", "trait:y_alchemist"], "effects": [{ "on": "on_reaction", "do": [["lightning", 1.5]] }] },
	{ "id": "t_plaguestorm", "hidden": true, "name": "PLAGUE STORM", "desc": "EVERY 10TH HIT ON A POISONED FOE CALLS A STORM CLOUD", "needs": ["trait:y_plague", "trait:l_stormherd"], "effects": [{ "on": "on_hit", "if": "poisoned", "every": 10, "do": [["spell", "cloud", 1.0]] }] },
	{ "id": "t_bladedance", "hidden": true, "name": "DANCE OF BLADES", "desc": "20% OF CRITS CONJURE A SPECTRAL BLADE", "needs": ["trait:l_bladestorm", "trait:y_echoedge"], "effects": [{ "on": "on_crit", "chance": 0.2, "cd": 0.3, "do": [["spell", "blade", 0.8]] }] },
	{ "id": "t_starforge", "hidden": true, "name": "STARFORGE", "desc": "EVERY 4S IN A FIGHT, A COMET CROSSES THE ROOM", "needs": ["trait:l_starcaller", "trait:y_meteors"], "effects": [{ "on": "every_n_seconds", "period": 4.0, "if": "fighting", "do": [["spell", "comet", 2.0]] }] },
	{ "id": "t_abyss", "hidden": true, "name": "THE ABYSS", "desc": "15% OF KILLS OPEN A BLACK HOLE", "needs": ["trait:l_voidheart", "weapon:moonwell"], "effects": [{ "on": "on_kill", "chance": 0.15, "do": [["spell", "void", 1.5]] }] },
	{ "id": "t_frozenhour", "hidden": true, "name": "FROZEN HOUR", "desc": "ROLLING STOPS TIME AROUND THE NEAREST FOE", "needs": ["trait:m_chronomancer", "trait:y_frostwake"], "effects": [{ "on": "on_roll", "cd": 3.0, "do": [["spell", "clock", 1.5]] }] },
	{ "id": "t_wyrmfire", "hidden": true, "name": "WYRMFIRE", "desc": "EVERY 3RD ATTACK ALSO SENDS A FIRE SERPENT", "needs": ["trait:m_serpentking", "weapon:hydrarod"], "effects": [{ "on": "every_n_shots", "every": 3, "do": [["spell", "serpent", 1.0]] }] },
	{ "id": "t_handofgod", "hidden": true, "name": "HAND OF GOD", "desc": "CRITS CALL LIGHTNING (EVERY 0.4S)", "needs": ["trait:m_ascendant", "trait:y_stormheart"], "effects": [{ "on": "on_crit", "cd": 0.4, "do": [["lightning", 1.2]] }] },
	{ "id": "t_reactor", "hidden": true, "name": "REACTOR", "desc": "A REACTION HEALS HALF A HEART (AT MOST EVERY 5S)", "needs": ["trait:y_alchemist", "trait:y_catalyst"], "effects": [{ "on": "on_reaction", "cd": 5.0, "do": [["heal", 1]] }] },
]

static var TAG_SYNERGIES: Array = TAG_SYNERGY_DATA.duplicate(true)
static var COMBOS: Array = COMBO_DATA.duplicate(true)
