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

##   Content batch 4 (chaos):
##   ["meteor", dmg_mult, radius]         a meteor falls on a random foe and leaves fire
##   ["bolts", n, dmg_mult]               lightning on n random foes
##   ["pull", radius, force]              drag foes toward the target (or the player)
##   ["push", radius, force]              hurl foes away from the player
##   ["bomb", fuse]                       a lit bomb at the target, harmless to you
##   ["zone", kind, radius, seconds]      fire, poison or smoke pool at the target (or the player)
##   ["transmute", coins]                 an ordinary foe turns into coins
##   ["rand_status", amount]              a random ailment on the target
##   ["shoot_at", n, dmg_mult, kind, spread, angle]  shots at an angle from your aim
##   ["chaos"]                            a random entry of WILD (hook "chaos_double": twice)
##   The Gaolbird:
##   ["tempo", n]                         raise (or lower) tempo, 0..tempo_max (scripts/combat/tempo.gd)
##   ["leap", speed, reach, [actions]]    a hero special: jump onto a foe, see abilities.gd

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
## Chaos table: [label, colour, actions]. Drawn by the "chaos" action.
const WILD := [
	["METEOR!", "#e8873a", [["meteor", 2.5, 34]]],
	["JACKPOT!", "#f2c94c", [["gold", 5], ["drop", "coin"], ["drop", "coin"], ["drop", "coin"]]],
	["FREEZE!", "#6fd3e0", [["status_area", "chill", 2, 130], ["status_area", "stun", 1, 130]]],
	["STORM!", "#6fd3e0", [["bolts", 4, 1.2]]],
	["BLADES!", "#f4ecd8", [["nova", 16, 0.7, "spark", 2.0]]],
	["FRENZY!", "#e8573a", [["buff", "rate", 0.6, 4.0]]],
	["GIANT!", "#e86fb4", [["buff", "size", 1.0, 5.0], ["buff", "dmg", 0.4, 5.0]]],
	["SWARM!", "#f2c94c", [["summon", 8.0], ["summon", 8.0], ["summon", 8.0]]],
	["VORTEX!", "#a35bd6", [["pull", 110, 260], ["explode", 40, 1.5]]],
	["BOOM!", "#e8873a", [["bomb", 0.5]]],
	["MEND!", "#63b84f", [["heal", 1]]],
	["HEX!", "#7a3a8c", [["status_area", "curse", 1, 140], ["status_area", "weakened", 1, 140]]],
]
const RAND_STATUSES := ["burn", "poison", "chill", "bleed", "curse", "shock", "vulnerable", "weakened"]

static func _random_foe() -> Enemy:
	var pool := []
	for e in G.enemies:
		if e.targetable() and e.hp > 0:
			pool.append(e)
	return TB.pick(pool) if not pool.is_empty() else null

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
			Vfx.puff(p.x, p.y, "void")
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
		"leap":
			Abilities.start_leap(p, a)
		"tempo":
			if p.tempo_max > 0:
				Tempo.add(p, int(a[1]) * stacks)
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
		"meteor":
			var e := _random_foe()
			if e == null:
				e = _target(ctx)
			var at := Vector2(e.x, e.y) if e != null else _pos(ctx)
			Fx.hide = Vfx.enabled   # Vfx draws the falling rock
			for i in 10:
				Fx.particle(at.x + 20 - i * 2 + TB.rint(-1, 1), at.y - 70 + i * 7, 0, 0, 0.22, "#f2c94c" if i % 2 == 0 else "#e8873a", 3)
			Fx.hide = false
			Vfx.meteor(at.x, at.y)
			Combat.explode_at(at.x, at.y, w * a[1] * stacks, null, a[2], "#e8873a", true)
			Juice.ring(at.x, at.y, 4, a[2], 0.3, "#e8873a")
			G.zones.append({ "x": at.x, "y": at.y, "r": a[2] * 0.45, "t": 2.0, "kind": "fire", "tick": 0.0 })
			G.add_shake(3)
			Snd.play("boom")
		"bolts":
			for i in mini(int(a[1]) * stacks, 12):
				var e := _random_foe()
				if e != null:
					Combat.lightning(e, w * a[2])
		"pull", "push":
			var at := _pos(ctx) if a[0] == "pull" else Vector2(p.x, p.y)
			var sgn := -1.0 if a[0] == "pull" else 1.0
			for e in G.enemies:
				if not e.targetable() or e.is_boss():
					continue
				var d := TB.dist_xy(e.x, e.y, at.x, at.y)
				if d > a[1] + e.r or d < 4:
					continue
				e.kx += (e.x - at.x) / d * a[2] * sgn
				e.ky += (e.y - at.y) / d * a[2] * sgn
			if a[0] == "pull":
				Juice.ring(at.x, at.y, a[1], 4, 0.3, "#a35bd6")
				Vfx.swirl(at.x, at.y, a[1], true, "#a35bd6")
			else:
				Juice.ring(at.x, at.y, 4, a[1], 0.3, "#f4ecd8")
				Vfx.swirl(at.x, at.y, a[1], false, "#f4ecd8")
		"bomb":
			var at := _pos(ctx)
			if G.bombs.size() < 24:
				G.bombs.append({ "x": at.x, "y": at.y, "t": float(a[1]), "safe": true })
		"zone":
			var at := _pos(ctx)
			if G.zones.size() < 60:
				G.zones.append({ "x": at.x, "y": at.y, "r": float(a[2]), "t": float(a[3]), "kind": a[1], "tick": 0.0 })
		"transmute":
			var e: Enemy = ctx.get("enemy")
			if e != null and e.hp > 0 and not e.elite and not e.is_boss() and e.type != "dummy" and not e.d.get("mini", false):
				for i in int(a[1]) * stacks:
					Combat.drop_pickup("coin", e.x, e.y)
				Juice.label("GOLD!", "#f2c94c", e.x, e.y - 14)
				Juice.burst(e.x, e.y, "#f2c94c", 12, 80)
				Vfx.puff(e.x, e.y, "gold")
				Combat.damage_enemy(e, e.hp + 1.0, { "no_crit": true, "no_mult": true, "col": "gold", "silent": true })
		"rand_status":
			var e := _target(ctx)
			if e != null:
				Statuses.apply(e, TB.pick(RAND_STATUSES), a[1] * stacks, ctx.get("dmg", w))
		"shoot_at":
			var n := mini(int(a[1]) * stacks, 32)
			for i in n:
				Combat.spawn_pbullet(p, p.aim_a + a[5] + (i - (n - 1) / 2.0) * a[4], w * a[2], a[3])
		"chaos":
			for k in (2 if p.g("chaos_double") > 0 else 1):
				var c: Array = TB.pick(WILD)
				# Several rolls at once stack their labels instead of overlapping.
				var up := Juice.labels.filter(func(l): return l["t"] < 0.4).size()
				Juice.label(c[0], c[1], p.x, p.y - 22 - 12 * up, true)
				for b in c[2]:
					run(b, stacks, ctx)
		_:
			push_error("Actions: unknown action " + str(a[0]))
