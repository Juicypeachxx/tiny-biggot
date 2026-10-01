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
			for i in n:
				Combat.spawn_pbullet(p, float(i) / n * TAU, w * a[2], a[3] if a.size() > 3 else "spark")
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
		_:
			push_error("Actions: unknown action " + str(a[0]))
