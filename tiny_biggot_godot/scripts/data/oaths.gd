class_name Oaths
extends RefCounted
## 30.1 (his pick, 9 Oct: oaths that grow): every OATH (traits.gd, rarity "oath") carries a VOW, a
## count of something done in the run. Keep it and the oath AWAKENS: a second power joins it for
## the rest of the run, with a banner. The count is a proc of its own, added when the oath is
## sworn (G.take_trait); its "do" is the action ["vow", id] (actions.gd), which calls `progress`.
## A vow that counts the oath's own strikes uses the same trigger, "every" and "cd" as the oath's
## proc, so the two keep step. Progress lives on the hero and is saved with the run:
## p.vows (id -> count) and p.vows_done (id -> true).
##   id: [goal, the vow (shown on the pick), HUD label, count proc (no "do"), what awakening adds,
##        the effects it adds]

const VOWS := {
	"o_flame": [120, "KILL 120 BURNING FOES", "BURNING KILLS", { "on": "on_kill", "if": "burning" },
		"HALF OF THE BURNING FOES YOU KILL LEAVE FIRE. BURNING FOES TAKE +30% MORE",
		[{ "on": "on_kill", "if": "burning", "chance": 0.5, "do": [["zone", "fire", 26, 2.5]] }, ["add", "vs_burn", 0.3]]],
	"o_frost": [120, "KILL 120 CHILLED FOES", "CHILLED KILLS", { "on": "on_kill", "if": "chilled" },
		"EVERY 6S IN A FIGHT, ALL FOES ARE CHILLED. CHILLED FOES TAKE +30% MORE",
		[{ "on": "every_n_seconds", "period": 6.0, "if": "fighting", "do": [["status_area", "chill", 2, 999]] }, ["add", "vs_chill", 0.3]]],
	"o_venom": [120, "KILL 120 POISONED FOES", "POISONED KILLS", { "on": "on_kill", "if": "poisoned" },
		"+2 POISON ON HIT. KILLING A POISONED FOE POISONS THE FOES NEAR YOU",
		[["add", "poison", 2], { "on": "on_kill", "if": "poisoned", "cd": 0.3, "do": [["status_area", "poison", 3, 80], ["vfx", "ring", "#b8e05a", 80]] }]],
	"o_thunder": [250, "CALL LIGHTNING 250 TIMES", "LIGHTNING", { "on": "on_hit", "every": 3, "cd": 0.15 },
		"EVERY 5S IN A FIGHT, LIGHTNING STRIKES 3 FOES. CRITS CALL LIGHTNING TOO",
		[{ "on": "every_n_seconds", "period": 5.0, "if": "fighting", "do": [["bolts", 3, 1.2]] }, { "on": "on_crit", "cd": 0.3, "do": [["lightning", 0.6]] }]],
	"o_blood": [15, "TAKE 15 HITS", "HITS TAKEN", { "on": "on_damage_taken" },
		"+20% DAMAGE. KILLS HEAL HALF A HEART 8% MORE OFTEN",
		[["mul", "dmg", 1.2], { "on": "on_kill", "chance": 0.08, "do": [["heal", 1]] }]],
	"o_swarm": [200, "KILL 200 FOES", "KILLS", { "on": "on_kill" },
		"+2 WISPS. WISPS DEAL +50% DAMAGE",
		[["add", "familiars", 2], ["add", "fam_dmg", 0.5]]],
	"o_steel": [12, "TAKE 12 HITS", "HITS TAKEN", { "on": "on_damage_taken" },
		"+1 MAX HEART, +20 THORNS. WHEN HIT, +1 ARMOR (EVERY 4S)",
		[["add", "max_hp", 2], ["add_cap", "hp", 2, "max_hp"], ["add", "thorns", 20], { "on": "on_damage_taken", "cd": 4.0, "do": [["armor", 1]] }]],
	"o_shadow": [150, "ROLL 150 TIMES", "ROLLS", { "on": "on_roll" },
		"+1 ROLL CHARGE. AFTER A ROLL NOTHING HURTS YOU FOR 0.6S",
		[["add", "dodge_charges", 1], ["add", "charges", 1], { "on": "on_roll", "do": [["invuln", 0.6]] }]],
	"o_archmage": [60, "CALL 60 COMETS", "COMETS", { "on": "every_n_shots", "every": 6 },
		"EVERY 4TH ATTACK ALSO CALLS A COMET. EVERY 20TH OPENS A BLACK HOLE",
		[{ "on": "every_n_shots", "every": 4, "do": [["spell", "comet", 1.0]] }, { "on": "every_n_shots", "every": 20, "do": [["spell", "void", 1.5]] }]],
	"o_greed": [250, "PICK UP 250 COINS", "COINS", { "on": "on_pickup", "if": "coin" },
		"+50% GOLD. EVERY 10TH COIN FIRES A RING OF 8 SHOTS",
		[["mul", "gold_mult", 1.5], { "on": "on_pickup", "if": "coin", "every": 10, "do": [["nova", 8, 0.8, "spark"]] }]],
	"o_duelist": [200, "LAND 200 CRITS", "CRITS", { "on": "on_crit" },
		"+15% CRIT, CRITS DEAL +0.5X. EVERY 2ND CRIT STRIKES AGAIN",
		[["add", "crit", 0.15], ["add", "crit_mult", 0.5], { "on": "on_crit", "every": 2, "cd": 0.1, "do": [["damage", 0.8]] }]],
	"o_rage": [12, "KILL 12 ELITES", "ELITES", { "on": "on_kill", "if": "elite" },
		"+15% DAMAGE. KILLS GIVE +5% FIRE RATE FOR 5S, STACKING",
		[["mul", "dmg", 1.15], { "on": "on_kill", "do": [["buff", "rate", 0.05, 5.0]] }]],
	"o_ruin": [150, "KILL 150 FOES", "KILLS", { "on": "on_kill" },
		"30% OF KILLS SET OFF A BIGGER BLAST TOO. +2 BOMBS",
		[{ "on": "on_kill", "chance": 0.3, "do": [["explode", 48, 0.8]] }, ["add", "bombs", 2]]],
	"o_hexer": [120, "KILL 120 CURSED FOES", "CURSED KILLS", { "on": "on_kill", "if": "cursed" },
		"20% MORE OF YOUR HITS CURSE. HITS ON CURSED FOES DEAL A 25% BONUS HIT",
		[{ "on": "on_hit", "chance": 0.2, "do": [["status", "curse", 1]] }, { "on": "on_hit", "if": "cursed", "cd": 0.05, "do": [["damage", 0.25]] }]],
	"o_grave": [150, "KILL 150 FOES", "KILLS", { "on": "on_kill" },
		"25% MORE OF YOUR KILLS RAISE A SKELETON, AND IT FIGHTS FOR 20S",
		[{ "on": "on_kill", "chance": 0.25, "do": [["raise", 20.0, 1.2]] }]],
	"o_engineer": [10, "CLEAR 10 ROOMS", "ROOMS", { "on": "on_room_clear" },
		"EVERY 5S IN A FIGHT, A STRONGER TURRET JOINS YOU FOR 10S",
		[{ "on": "every_n_seconds", "period": 5.0, "if": "fighting", "do": [["turret", "random", 10.0, 1.5]] }]],
	"o_hourglass": [25, "STOP TIME 25 TIMES", "TIME STOPS", { "on": "every_n_seconds", "period": 10.0, "if": "fighting" },
		"EVERY 5S IN A FIGHT, TIME STOPS AT ANOTHER FOE. ROLLS RECHARGE 25% FASTER",
		[{ "on": "every_n_seconds", "period": 5.0, "if": "fighting", "do": [["spell", "clock", 1.2]] }, ["mul", "dodge_cd", 0.75]]],
	"o_chaos": [12, "CLEAR 12 ROOMS", "ROOMS", { "on": "on_room_clear" },
		"+3 LUCK. EVERY 8TH HIT, SOMETHING RANDOM HAPPENS",
		[["add", "luck", 3], { "on": "on_hit", "every": 8, "cd": 1.0, "do": [["chaos"]] }]],
	"o_dawn": [30, "SHINE 30 TIMES", "RINGS", { "on": "every_n_seconds", "period": 8.0, "if": "fighting" },
		"EVERY 4S IN A FIGHT, ANOTHER RING. HALF OF THE ROOMS YOU CLEAR HEAL HALF A HEART",
		[{ "on": "every_n_seconds", "period": 4.0, "if": "fighting", "do": [["nova", 16, 1.0, "spark", 1.0]] }, { "on": "on_room_clear", "chance": 0.5, "do": [["heal", 1]] }]],
	"o_souls": [8, "SURGE 8 TIMES", "SURGES", { "on": "on_surge" },   # 53.2
		"SURGES DEAL +50% AND STUN EVERY FOE THEY HIT",
		[["hook", "surge_dmg", 0.5], ["hook", "surge_stun", 1]]],
}

## The vow of an oath, as the pick and the trait book show it ("" for a trait without one).
static func vow_text(id: String) -> String:
	return String(VOWS[id][1]) if VOWS.has(id) else ""

## What keeping the vow adds.
static func awake_text(id: String) -> String:
	return String(VOWS[id][4]) if VOWS.has(id) else ""

## An oath is sworn (G.take_trait): its count starts.
static func sworn(p: Player, id: String) -> void:
	if not VOWS.has(id) or p.vows_done.has(id) or p.vows.has(id):
		return
	p.vows[id] = 0
	var cp: Dictionary = (VOWS[id][3] as Dictionary).duplicate(true)
	cp["do"] = [["vow", id]]
	Effects.add_proc(p, cp, "vow:" + id)

## One more step of a vow; at its goal the oath awakens.
static func progress(p: Player, id: String, n: int = 1) -> void:
	if not VOWS.has(id) or p.vows_done.has(id):
		return
	var v: int = int(p.vows.get(id, 0)) + n
	p.vows[id] = v
	if v < int(VOWS[id][0]):
		return
	p.vows_done[id] = true
	Effects.apply(p, VOWS[id][5], 1, "vow:" + id + ":awake")
	p.hp = mini(p.hp, p.max_hp)
	var name: String = Traits.by_id(id)["name"] if Traits.has(id) else id.to_upper()
	G.show_banner("OATH AWAKENED!", name)
	Fx.texts.append({ "x": p.x, "y": p.y - 30, "text": "VOW KEPT!", "col": "orange", "life": 1.2, "big": true })
	Fx.burst(p.x, p.y - 6, ["#ff9b3a", "#f2c94c", "#ffffff"], 24, 90, 0.6)
	Snd.play("relic")

## The HUD's lines, one an oath sworn: [text, colour].
static func hud_lines(p: Player) -> Array:
	var out := []
	for id in p.vows:
		if not VOWS.has(id):
			continue
		if p.vows_done.has(id):
			out.append([String(Traits.by_id(id)["name"]).replace("OATH OF ", "") + " AWAKENED", "gold"])
		else:
			out.append(["VOW: %d/%d %s" % [mini(int(p.vows[id]), int(VOWS[id][0])), int(VOWS[id][0]), VOWS[id][2]], "orange"])
	return out
