class_name Effects
extends RefCounted
## The effect system (design spec sections 2b, 2c and 3). Every item (relic,
## trait, family bonus, skill node, weapon, gear, set, synergy, combo) is data:
## an id plus a list of effects. An effect is one of:
##
##   Stat ops, applied in the listed order, the same as the original Ruby lambdas:
##     ["add", stat, v]            stat += v              (flat)
##     ["mul", stat, v]            stat *= v              (multiplicative %)
##     ["pct", stat, v]            additive %: stat = (base + flat) * (1 + sum of pct) * mults
##     ["set", stat, v]            stat = v
##     ["add_cap", stat, v, cap]   stat = min(cap, stat + v)      cap: number or stat name
##     ["add_floor", stat, v, lo]  stat = max(lo, stat + v)       lo:  number or stat name
##     ["clamp_max", stat, cap]    stat = min(stat, cap)
##     ["at_least", stat, v]       stat = max(stat, v)
##     ["copy", stat, other]       stat = other
##     ["nth", stat, first, d, lo] stat = first if stat == 0 else max(lo, stat + d)
##     ["grant", stat, v]          equipment consumable, granted once per item (never removed)
##     ["hook", key, v]            behaviour switch read by the combat code (gear/weapon abilities)
##   Triggers (procs):
##     { "on": trigger, "do": [action, ...], "chance": p, "every": n, "cd": s, "if": cond, "period": s }
##
## Equipment is reversible: apply(..., -1) undoes every op except "grant", as
## the original 04b apply_tuples did.
##
## Original content is expressed in the same ops and takes the same code paths
## as before. The new mechanics (pct, procs, buffs, synergies, new statuses,
## overcrit) only do work when new content switches them on, and a player
## without procs never draws an extra random number. tests/effects_test.gd and
## tools/replay.sh prove the originals are unchanged.

# ---------- Safety rails (spec section 3) ----------
const MAX_DEPTH := 4           # a trigger may cause triggers at most this many levels deep
const BUDGET := 200            # action executions per logic tick; the rest wait in a queue
const QUEUE_MAX := 2000        # queued actions beyond this are dropped (counted)
const PBULLET_CAP := 1000     # live player shots; beyond it new shots merge their damage into old ones
const ROGUES_PBULLET_CAP := 300  # Rogues layer: lower, for smooth heavy fights on iPad (damage still merges)
const SUMMON_CAP := 24         # wisps (permanent + temporary) per player
const MIN_SHOT_INTERVAL := 1.0 / 60.0   # attack-speed floor: one attack per logic tick
const BUFF_CAP := 64

const TRIGGERS := ["on_hit", "on_crit", "on_kill", "on_roll", "on_damage_taken", "on_heal", "on_room_enter",
	"on_room_clear", "on_level_up", "on_shoot", "every_n_shots", "every_n_seconds", "while_low_hp", "on_pickup",
	"on_potion", "on_weapon_swap", "on_floor_start"]   # last three: new for the step-6 heroes
const ACTIONS := ["nova", "shoot", "explode", "status", "heal", "buff", "chain", "lightning", "summon", "gold",
	"refund_roll", "armor", "drop", "damage", "hurt_self", "xp", "clear_shots", "card", "heat", "scroll",
	"dash", "channel", "invuln", "status_area", "vfx", "area"]   # last five: hero abilities and visuals
const STATUSES := ["burn", "poison", "chill", "bleed", "stun", "curse", "mark", "shock", "vulnerable", "weakened"]
const CONDITIONS := ["elite", "boss", "burning", "poisoned", "chilled", "bleeding", "shocked", "cursed",
	"low_hp", "full_hp", "moving", "still", "crit", "danger", "fighting", "hot"]

static var depth := 0
static var budget := BUDGET
static var queue: Array = []
static var stats := { "procs": 0, "queued": 0, "dropped_depth": 0, "dropped_queue": 0, "merged_shots": 0, "max_depth": 0 }

static func reset_run_state() -> void:
	depth = 0
	budget = BUDGET
	queue.clear()

# ---------- Stat ops ----------
static func _arg(p: Player, v: Variant) -> Variant:
	return p.get(v) if v is String else v

## Applies a list of effects. dir = -1 undoes equipment (reversible ops only).
## src identifies the item for procs and one-time grants ("" = permanent).
static func apply(p: Player, effects: Array, dir: int = 1, src: String = "") -> void:
	var first := src != "" and not p.granted.has(src)
	for e in effects:
		if e is Dictionary:
			if dir > 0:
				add_proc(p, e, src)
			else:
				remove_procs(p, src)
			continue
		var kind: String = e[0]
		var stat: String = e[1]
		match kind:
			"add":
				_set_raw(p, stat, _get_raw(p, stat) + e[2] * dir)
			"mul":
				_set_raw(p, stat, _get_raw(p, stat) * e[2] if dir > 0 else _get_raw(p, stat) / e[2])
			"pct":
				_add_pct(p, stat, e[2] * dir)
			"grant":
				if dir > 0 and (first or src == ""):
					p.set(stat, p.get(stat) + e[2])
			"upgrade":
				# Rogues layer: ["upgrade", "weapon", n] raises your weapon n levels (one-shot).
				if dir > 0 and GameData.rogues():
					WeaponInfo.upgrade(p, int(e[2]))
			"attr":
				# Rogues layer: ["attr", "str"|"dex"|"int"|"highest", n]; reversible.
				Attributes.add(p, Attributes.highest(p) if stat == "highest" else stat, int(e[2]) * dir)
			"hook":
				p.gf[stat] = p.gf.get(stat, 0.0) + e[2] * dir
			"set":
				_set_raw(p, stat, e[2])
			"add_cap":
				_set_raw(p, stat, min(_arg(p, e[3]), _get_raw(p, stat) + e[2]))
			"add_floor":
				_set_raw(p, stat, max(_arg(p, e[3]), _get_raw(p, stat) + e[2]))
			"clamp_max":
				_set_raw(p, stat, min(_get_raw(p, stat), _arg(p, e[2])))
			"at_least":
				_set_raw(p, stat, max(_get_raw(p, stat), e[2]))
			"copy":
				_set_raw(p, stat, p.get(e[2]))
			"nth":
				var cur = _get_raw(p, stat)
				_set_raw(p, stat, e[2] if cur == 0 else max(e[4], cur + e[3]))
			_:
				push_error("Effects: unknown op " + kind)
	if src != "" and dir > 0:
		p.granted[src] = true

## Equipment application with the original 04b clamps (apply_tuples).
static func apply_equipment(p: Player, effects: Array, dir: int, src: String) -> void:
	apply(p, effects, dir, src)
	p.max_hp = maxi(2, p.max_hp)
	p.hp = maxi(mini(p.hp, p.max_hp), 1)
	p.armor = maxi(0, p.armor)
	p.revive = maxi(0, p.revive)
	p.charges = maxi(mini(p.charges, p.dodge_charges), 0)
	p.potions = mini(p.potions, p.max_potions)

## Original weapon/gear stat tuples and hooks as effects (04b apply_tuples rules:
## MUL_KEYS multiply, ONCE_KEYS are granted once, everything else adds, and a
## positive max_hp also raises hp).
static func from_tuples(tuples: Array, hooks: Array = []) -> Array:
	var out := []
	for kv in tuples:
		var k: String = kv[0]
		if k in Weapons.MUL_KEYS:
			out.append(["mul", k, kv[1]])
		elif k in Weapons.ONCE_KEYS:
			out.append(["grant", k, kv[1]])
		else:
			out.append(["add", k, kv[1]])
			if k == "max_hp" and kv[1] > 0:
				out.append(["add", "hp", kv[1]])
	for kv in hooks:
		out.append(["hook", kv[0], kv[1]])
	return out

# Additive-% layer: a stat with pct mods stores (base + flat) * mults * (1 + sum).
# With no pct mods (all original content) values are read and written untouched.
static func _get_raw(p: Player, stat: String) -> Variant:
	var s: float = p.stat_pct.get(stat, 0.0)
	return p.get(stat) if s == 0.0 else p.get(stat) / (1.0 + s)

static func _set_raw(p: Player, stat: String, v: Variant) -> void:
	var s: float = p.stat_pct.get(stat, 0.0)
	p.set(stat, v if s == 0.0 else v * (1.0 + s))

static func _add_pct(p: Player, stat: String, v: float) -> void:
	var raw = _get_raw(p, stat)
	var s: float = p.stat_pct.get(stat, 0.0) + v
	if absf(s) < 1e-9:
		p.stat_pct.erase(stat)
		p.set(stat, raw)
	else:
		p.stat_pct[stat] = maxf(s, -0.95)
		p.set(stat, raw * (1.0 + p.stat_pct[stat]))

# ---------- Procs ----------
static func add_proc(p: Player, def: Dictionary, src: String) -> void:
	for pr in p.procs:
		if pr["src"] == src and pr["def"] == def:
			pr["stacks"] += 1
			return
	p.procs.append({ "def": def, "src": src, "stacks": 1, "count": 0, "cd": 0.0, "timer": 0.0, "active": false })

static func remove_procs(p: Player, src: String) -> void:
	var keep := []
	for pr in p.procs:
		if pr["src"] == src:
			if pr["active"]:
				_while_toggle(p, pr, false)
		else:
			keep.append(pr)
	p.procs = keep

static func _cond(c: String, ctx: Dictionary) -> bool:
	var p := G.player
	var e: Enemy = ctx.get("enemy")
	match c:
		"elite": return e != null and e.elite
		"boss": return e != null and e.is_boss()
		"burning": return e != null and e.burn_t > 0
		"poisoned": return e != null and e.poison > 0
		"chilled": return e != null and e.chill_t > 0
		"bleeding": return e != null and e.bleed_t > 0
		"shocked": return e != null and e.shock > 0
		"cursed": return e != null and e.curse_t > 0
		"low_hp": return p.hp <= p.max_hp / 2
		"full_hp": return p.hp >= p.max_hp
		"moving": return p.moving
		"still": return not p.moving
		"crit": return ctx.get("crit", false)
		"danger": return EBullets.any_near(p.x, p.y, 30.0)   # a shot is close: perfect dodge
		"fighting": return G.enemies_active()
		"hot": return p.heat >= 3
	return false

## Fires a trigger. ctx may carry: enemy, dmg, crit, x, y.
## Live player shot cap (classic keeps the original 1000).
static func pbullet_cap() -> int:
	return ROGUES_PBULLET_CAP if GameData.rogues() else PBULLET_CAP

static func fire(trig: String, ctx: Dictionary = {}) -> void:
	var p := G.player
	if p == null or p.procs.is_empty():
		return
	if depth >= MAX_DEPTH:
		stats["dropped_depth"] += 1
		return
	for pr in p.procs.duplicate():
		var d: Dictionary = pr["def"]
		if d["on"] != trig:
			continue
		if pr["cd"] > 0:
			continue
		if d.has("every"):
			pr["count"] += 1
			if pr["count"] % int(d["every"]) != 0:
				continue
		if d.has("chance") and randf() >= d["chance"]:
			continue
		if d.has("if") and not _cond(d["if"], ctx):
			continue
		pr["cd"] = d.get("cd", 0.0)
		_run(pr, ctx)

static func _run(pr: Dictionary, ctx: Dictionary) -> void:
	if budget <= 0:
		if queue.size() < QUEUE_MAX:
			queue.append([pr, ctx, depth])
			stats["queued"] += 1
		else:
			stats["dropped_queue"] += 1
		return
	budget -= 1
	stats["procs"] += 1
	depth += 1
	stats["max_depth"] = maxi(stats["max_depth"], depth)
	for a in pr["def"]["do"]:
		Actions.run(a, pr["stacks"], ctx)
	depth -= 1

## Per-tick upkeep: refills the proc budget, drains the queue, runs timers,
## buffs and while-conditions. Does nothing for a player without procs or buffs.
static func tick(dt: float) -> void:
	budget = BUDGET
	var p := G.player
	if p == null:
		return
	if not queue.is_empty():
		var q := queue
		queue = []
		for item in q:
			var ctx: Dictionary = item[1]
			var e = ctx.get("enemy")
			if e != null and e.hp <= 0:
				ctx = ctx.duplicate()
				ctx.erase("enemy")
			var saved := depth
			depth = item[2]
			_run(item[0], ctx)
			depth = saved
	if not p.buffs.is_empty():
		var keep := []
		for b in p.buffs:
			b["t"] -= dt
			if b["t"] > 0:
				keep.append(b)
			else:
				_add_pct(p, b["stat"], -b["v"])
		p.buffs = keep
	for pr in p.procs:
		if pr["cd"] > 0:
			pr["cd"] -= dt
		var d: Dictionary = pr["def"]
		match d["on"]:
			"every_n_seconds":
				pr["timer"] += dt
				if pr["timer"] >= d.get("period", 1.0):
					pr["timer"] = 0.0
					if not d.has("if") or _cond(d["if"], {}):
						_run(pr, {})
			"while_low_hp":
				var on := p.hp <= p.max_hp / 2
				if on != pr["active"]:
					_while_toggle(p, pr, on)

## "while" procs hold their stat ops only while the condition is true.
static func _while_toggle(p: Player, pr: Dictionary, on: bool) -> void:
	pr["active"] = on
	for a in pr["def"]["do"]:
		if a[0] == "buff":
			_add_pct(p, a[1], a[2] * pr["stacks"] * (1 if on else -1))

static func add_buff(p: Player, stat: String, v: float, dur: float) -> void:
	if p.buffs.size() >= BUFF_CAP:
		return
	_add_pct(p, stat, v)
	p.buffs.append({ "stat": stat, "v": v, "t": dur })

# ---------- Tags, synergies and named combos (spec 2c) ----------
## Counts tags of new-content items only. Original items keep feeding the
## original systems (family bonuses, weapon synergy, sets), so a run made of
## original content plays exactly as before.
static func recount_tags(p: Player) -> void:
	var counts := {}
	var owned := {}
	for r in p.relics:
		owned["relic:" + r["id"]] = true
		if r.get("new", false):
			for t in r["tags"]:
				counts[t] = counts.get(t, 0) + 1
	if p.weapon != null:
		owned["weapon:" + p.weapon["id"]] = true
		if p.weapon.get("new", false):
			for t in p.weapon["tags"]:
				counts[t] = counts.get(t, 0) + 1
	for g in p.gear.values():
		if g == null:
			continue
		owned["gear:" + g["id"]] = true
		if g.get("new", false):
			for t in g["tags"]:
				counts[t] = counts.get(t, 0) + 1
	for id in p.traits:
		owned["trait:" + id] = true
		var t: Dictionary = Traits.by_id(id)
		if t.get("new", false):
			for tag in t["tags"]:
				counts[tag] = counts.get(tag, 0) + p.traits[id]
	p.tag_counts = counts
	_update_synergies(p, owned)

static func _update_synergies(p: Player, owned: Dictionary) -> void:
	for syn in Synergies.TAG_SYNERGIES:
		var tag: String = syn["tag"]
		var have: int = p.tag_counts.get(tag, 0)
		for i in syn["tiers"].size():
			var tier: Dictionary = syn["tiers"][i]
			var key := "syn:%s:%d" % [tag, i]
			var on: bool = have >= tier["need"]
			if on and not p.synergies.has(key):
				p.synergies[key] = true
				apply(p, tier["effects"], 1, key)
				G.show_banner("SYNERGY: " + tier["name"], tier["desc"])
				Snd.play("unlock")
			elif not on and p.synergies.has(key):
				p.synergies.erase(key)
				apply(p, tier["effects"], -1, key)
	for c in Synergies.COMBOS:
		var key: String = "combo:" + c["id"]
		var on := true
		for need in c["needs"]:
			if not owned.has(need):
				on = false
		if on and not p.synergies.has(key):
			p.synergies[key] = true
			apply(p, c["effects"], 1, key)
			G.show_banner("COMBO: " + c["name"], c["desc"])
			Snd.play("unlock")
		elif not on and p.synergies.has(key):
			p.synergies.erase(key)
			apply(p, c["effects"], -1, key)

## True when the item carries any new mechanic, so callers can skip work otherwise.
static func has_new(p: Player) -> bool:
	return not p.procs.is_empty() or not p.buffs.is_empty()
