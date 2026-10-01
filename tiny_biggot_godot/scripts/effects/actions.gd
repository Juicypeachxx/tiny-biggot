class_name Actions
extends RefCounted
## Proc actions (design spec 2b). Each action is data: [name, args...].
## Damage numbers are multiples of the current weapon damage. `stacks` is how
## many times the owning item or trait rank was taken; magnitudes scale with it.
##
##   ["nova", n, dmg_mult, kind]          ring of n shots around the player
##   ["shoot", n, dmg_mult, kind, spread] n extra shots along the aim
##   ["explode", radius, dmg_mult]        blast at the target (or the player)
##   ["status", name, amount]             apply a status to the target (or the nearest foe)
##   ["heal", n]                          heal n half-hearts
##   ["buff", stat, pct, seconds]         temporary additive-% stat bonus
##   ["chain", dmg_mult]                  arc from the target to nearby foes
##   ["lightning", dmg_mult]              lightning strike on the target (or nearest foe)
##   ["summon", seconds]                  temporary wisp (summon cap applies)
##   ["gold", n] / ["armor", n] / ["xp", n]
##   ["refund_roll"]                      +1 roll charge
##   ["drop", kind]                       drop a pickup at the target
##   ["damage", dmg_mult]                 direct hit on the target
##   ["hurt_self", n]                     lose n half-hearts (never lethal; curse drawbacks)
##   ["clear_shots", radius]              erase enemy shots around the player
##   ["card"]                             draw a random card from CARDS and play it (Cartomancer)
##   ["heat", delta]                      raise or lower heat, 0..heat_max (Racketeer)
##   ["scroll"]                           read a random scroll: a small permanent boost (Condemned)
##   ["dash", ...] / ["channel", ...] / ["invuln", s]   hero specials, see abilities.gd
##   ["status_area", name, amount, radius]  apply a status to every foe near the player
##   ["area", radius, dmg_mult]           silent hit on every foe near the player (whirlwinds)
##   nova takes an optional 5th value: spin speed, so repeated novas spiral
##   ["vfx", kind, colour, size]          visual only (Juice): ring, sigil, spin, flash, burst, label

## Cartomancer deck: [name, actions]. The hook "card_double" plays each card twice.
const CARDS := [
	["BLADES", [["shoot", 5, 0.7, "", 0.18]]],
	["STORM", [["lightning", 1.5]]],
	["SHIELD", [["clear_shots", 70]]],
	["MEND", [["heal", 1]]],
	["STAR", [["buff", "crit", 1.0, 3.0]]],
	["WHEEL", [["nova", 10, 0.6, "spark"]]],
	["COIN", [["gold", 3]]],
]
## Condemned scrolls: [text, permanent effect].
const SCROLLS := [
	["+6% DAMAGE", ["mul", "dmg", 1.06]],
	["+6% FIRE RATE", ["mul", "rate", 1.06]],
	["+1 MAX HEART", ["add", "max_hp", 2]],
	["+4% CRIT", ["add", "crit", 0.04]],
]
## Heat per level: +8% damage and +10% gold.
static func heat_effects(h: int) -> Array:
	return [["pct", "dmg", 0.08 * h], ["mul", "gold_mult", 1.0 + 0.1 * h]]

static func _target(ctx: Dictionary) -> Enemy:
	var e: Enemy = ctx.get("enemy")
	if e != null and e.hp > 0:
		return e
	var p := G.player
	return Combat.nearest_enemy(p.x, p.y, 160)

static func _pos(ctx: Dictionary) -> Vector2:
	var e: Enemy = ctx.get("enemy")
	if e != null:
		return Vector2(e.x, e.y)
	if ctx.has("x"):
		return Vector2(ctx["x"], ctx["y"])
	return Vector2(G.player.x, G.player.y)

static func run(a: Array, stacks: int, ctx: Dictionary) -> void:
	var p := G.player
	var w := Weapons.wdmg(p)
	match a[0]:
		"nova":
			var n := mini(int(a[1]) * stacks, 64)
			var off: float = G.time * a[4] if a.size() > 4 else 0.0
			for i in n:
				Combat.spawn_pbullet(p, float(i) / n * TAU + off, w * a[2], a[3] if a.size() > 3 else "spark")
		"shoot":
			var n := mini(int(a[1]) * stacks, 32)
			var spread: float = a[4] if a.size() > 4 else 0.25
			for i in n:
				Combat.spawn_pbullet(p, p.aim_a + (i - (n - 1) / 2.0) * spread, w * a[2], a[3] if a.size() > 3 else "")
		"explode":
			var at := _pos(ctx)
			Combat.explode_at(at.x, at.y, w * a[2] * stacks, null, a[1], "#e8873a", true)
		"status":
			var e := _target(ctx)
			if e != null:
				Statuses.apply(e, a[1], a[2] * stacks, ctx.get("dmg", w))
		"heal":
			p.heal(int(a[1]) * stacks)
		"buff":
			Effects.add_buff(p, a[1], a[2] * stacks, a[3])
		"chain":
			var e := _target(ctx)
			if e != null:
				Combat.chain_from(e, w * a[1] * stacks)
		"lightning":
			var e := _target(ctx)
			if e != null:
				Combat.lightning(e, w * a[1] * stacks)
		"summon":
			if mini(p.familiars, Effects.SUMMON_CAP) + G.temp_fams.size() < Effects.SUMMON_CAP:
				G.temp_fams.append({ "x": p.x, "y": p.y, "cd": 0.2, "t": float(a[1]) })
		"gold":
			p.gold += int(a[1]) * stacks
			G.run_stats["gold"] += int(a[1]) * stacks
		"armor":
			p.armor += int(a[1]) * stacks
		"xp":
			Combat.gain_xp(p, int(a[1]) * stacks)
		"refund_roll":
			p.charges = mini(p.charges + stacks, p.dodge_charges)
		"drop":
			var at := _pos(ctx)
			Combat.drop_pickup(a[1], at.x, at.y)
		"damage":
			var e := _target(ctx)
			if e != null:
				Combat.damage_enemy(e, w * a[1] * stacks, { "no_crit": true, "col": "pink", "silent": true })
		"hurt_self":
			p.hp = maxi(1, p.hp - int(a[1]) * stacks)
			Fx.burst(p.x, p.y, ["#a35bd6", "#5c3483"], 6, 40)
		"clear_shots":
			EBullets.kill_radius(p.x, p.y, a[1])
		"card":
			var c: Array = TB.pick(CARDS)
			Juice.card(p.x, p.y, c[0])
			for k in (2 if p.g("card_double") > 0 else 1):
				for b in c[1]:
					run(b, stacks, ctx)
		"heat":
			var h := clampi(p.heat + int(a[1]) * stacks, 0, p.heat_max)
			if h != p.heat:
				Effects.apply(p, heat_effects(p.heat), -1)
				p.heat = h
				Effects.apply(p, heat_effects(h), 1)
				Fx.float_text(p.x, p.y - 20, "HEAT %d" % h, "orange" if int(a[1]) > 0 else "grey")
		"dash":
			Abilities.start_dash(p, a)
		"channel":
			p.channel = { "t": float(a[1]), "period": float(a[2]), "timer": 0.0, "do": a[3] }
		"area":
			for e in G.enemies.duplicate():
				if e.targetable() and TB.dist(e, p) <= a[1] + e.r:
					Combat.damage_enemy(e, w * a[2] * stacks, { "no_crit": true, "col": "orange", "silent": true })
		"invuln":
			p.invuln = maxf(p.invuln, float(a[1]))
		"status_area":
			for e in G.enemies:
				if e.targetable() and TB.dist(e, p) <= a[3]:
					Statuses.apply(e, a[1], a[2] * stacks, w)
		"vfx":
			Juice.vfx(p, a)
		"scroll":
			var sc: Array = TB.pick(SCROLLS)
			Effects.apply(p, [sc[1]], 1)
			if sc[1][1] == "max_hp":
				p.heal(2)
			Fx.float_text(p.x, p.y - 20, "SCROLL: " + sc[0], "gold")
		_:
			push_error("Actions: unknown action " + str(a[0]))
