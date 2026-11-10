class_name TestFixtures
extends RefCounted
## Synthetic items used only by tests/content_test.gd. Together they reach
## every trigger, action, status and condition of the effect system, plus
## deliberately abusive cases that must hit the safety rails:
## a proc recursion bomb, a heal loop and a shot flood. Never shipped.

static func items() -> Array:
	var out := []
	# One per trigger.
	for t in Effects.TRIGGERS:
		var d := { "on": t, "do": [["damage", 0.5]] }
		match t:
			"every_n_shots": d["every"] = 3
			"every_n_seconds": d["period"] = 0.5
			"while_low_hp": d["do"] = [["buff", "dmg", 0.5, 0]]
		out.append({ "id": "fx_trig_" + t, "effects": [d], "tags": ["pyre"] })
	# One per action (on hit).
	var acts := [["nova", 6, 0.3, "spark"], ["shoot", 3, 0.4, "", 0.2], ["explode", 24, 0.5], ["status", "burn", 1],
		["heal", 1], ["buff", "rate", 0.2, 2.0], ["chain", 0.4], ["lightning", 0.5], ["summon", 3.0], ["gold", 1],
		["refund_roll"], ["armor", 1], ["drop", "coin"], ["damage", 0.3], ["hurt_self", 1], ["xp", 1], ["clear_shots", 40],
		["card"], ["heat", 1], ["scroll"], ["dash", 600, 0.1, 1.0, [["explode", 20, 0.5]]],
		["channel", 0.4, 0.1, [["area", 30, 0.3]]], ["invuln", 0.2], ["status_area", "burn", 1, 50],
		["vfx", "sigil", "#f2c94c", 30], ["area", 30, 0.3],
		["tempo", 1], ["leap", 400, 80, [["explode", 20, 0.5], ["vfx", "slam", "#e86fb4", 30]]]]
	for a in acts:
		out.append({ "id": "fx_act_" + a[0], "effects": [{ "on": "on_hit", "chance": 0.3, "do": [a] }], "tags": ["storm"] })
	# One per status and per condition.
	for s in Effects.STATUSES:
		out.append({ "id": "fx_status_" + s, "effects": [{ "on": "on_hit", "do": [["status", s, 1]] }], "tags": ["venom"] })
	for c in Effects.CONDITIONS:
		out.append({ "id": "fx_if_" + c, "effects": [{ "on": "on_hit", "if": c, "cd": 0.2, "do": [["nova", 4, 0.2, "spark"]] }], "tags": [] })
	# Stat layers: flat, additive % and multiplicative together, and overcrit.
	out.append({ "id": "fx_pct", "effects": [["add", "crit", 1.2], ["pct", "dmg", 0.5], ["pct", "rate", 0.3],
		["mul", "dmg", 1.2], ["pct", "speed", 0.1], ["add", "overcrit", 0.5]], "tags": ["edge"] })
	# Abuse cases: these must be stopped by the rails, not crash or freeze.
	out.append({ "id": "fx_bomb", "effects": [{ "on": "on_hit", "do": [["nova", 12, 0.2, "spark"], ["chain", 0.3]] }], "tags": [] })
	out.append({ "id": "fx_heal_loop", "effects": [{ "on": "on_heal", "do": [["heal", 1]] }, { "on": "on_hit", "do": [["heal", 1]] }], "tags": [] })
	out.append({ "id": "fx_flood", "effects": [{ "on": "on_shoot", "do": [["shoot", 32, 0.2, "spark", 0.05], ["nova", 64, 0.2, "spark"]] }], "tags": [] })
	return out

## A tag synergy and a named combo over fixture items, injected for the test.
static func synergy() -> Dictionary:
	return { "tag": "storm", "tiers": [
		{ "need": 2, "name": "TEST STORM I", "desc": "", "effects": [["pct", "rate", 0.2], { "on": "on_kill", "do": [["lightning", 0.5]] }] },
		{ "need": 4, "name": "TEST STORM II", "desc": "", "effects": [["add", "chain", 0.2]] }] }

static func combo() -> Dictionary:
	return { "id": "fx_combo", "name": "TEST COMBO", "desc": "", "needs": ["relic:fx_act_nova", "relic:fx_act_chain"],
		"effects": [["pct", "dmg", 0.25], { "on": "on_crit", "do": [["explode", 20, 0.3]] }] }
