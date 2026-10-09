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
##   ROADMAP 4.6 weapons (scripts/combat/arsenal.gd):
##   ["plant", delay, dmg_mult, radius]   a charge on the foe that blows a moment later
##   ["puppet", seconds]                  the foe walks into another foe and bursts
##   ["charm", seconds]                   an ordinary foe fights for you (summons.gd)
##   ["warm", n]                          the dragon egg grows warmer; at 15 it hatches (summons.gd)

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

## The ailments on a foe, by status name (the "spread" and "consume" actions).
static func ailments(e: Enemy) -> Array:
	var out := []
	if e.burn_t > 0: out.append("burn")
	if e.poison > 0: out.append("poison")
	if e.chill_t > 0: out.append("chill")
	if e.bleed_t > 0: out.append("bleed")
	if e.curse_t > 0: out.append("curse")
	if e.shock > 0: out.append("shock")
	if e.vuln_t > 0: out.append("vulnerable")
	if e.weak_t > 0: out.append("weakened")
	return out

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

## How often each action ran, and (the ROADMAP 4.7 ones) how often it found something to do:
## tests/items_test reads them.
static var ran := {}
static var did := {}

static func _did(k: String) -> void:
	did[k] = did.get(k, 0) + 1

static func run(a: Array, stacks: int, ctx: Dictionary) -> void:
	var p := G.player
	var w := Weapons.wdmg(p)
	ran[a[0]] = ran.get(a[0], 0) + 1
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
		"aura_surge":   # 33.1 ["aura_surge", times, seconds]: the halos' fields reach further for a while
			Auras.start_surge(a[1], a[2])
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
		"stack":   # 8.4 ["stack", stat, v, cap, key]: +v (a percent of the stat) for good, up to cap
			var have: float = p.gf.get(a[4], 0.0)
			var add := minf(a[2] * stacks, a[3] - have)
			if add > 0:
				Effects._add_pct(p, a[1], add)
				p.gf[a[4]] = have + add
		"drop":
			var at := _pos(ctx)
			Combat.drop_pickup(StatDrops.roll() if a[1] == "stat" else a[1], at.x, at.y)   # "stat": a random stat pickup (8.5)
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
		"toy":
			# 31: ["toy", kind, dmg_mult]: a toy of the toybox at the foe (an anvil with no foe in hand: a random one):
			# shark, twister, disco, portal, saw, pin, anvil (Toys.cast).
			if GameData.rogues():
				var te: Enemy = ctx.get("enemy")
				if te == null or te.hp <= 0:
					te = _random_foe() if String(a[1]) == "anvil" else _target(ctx)
				var at := Vector2(te.x, te.y) if te != null else Vector2(p.x + cos(p.aim_a) * 70.0, p.y + sin(p.aim_a) * 70.0)
				Toys.cast(String(a[1]), p, at.x, at.y, w * float(a[2]) * stacks, te.uid if te != null else -1)
		"vow":   # 30.1: ["vow", oath id]: one more step of that oath's vow; at its goal the oath awakens (oaths.gd)
			Oaths.progress(p, String(a[1]), stacks)
		"spell":
			# 26: ["spell", kind, dmg_mult]: a spell of the spellbook cast at the foe (or ahead of you):
			# void, comet, glyph, blade, clock, prism, cloud, serpent, pinball (Spells.cast).
			if GameData.rogues():
				var se := _target(ctx)
				var at := Vector2(se.x, se.y) if se != null else Vector2(p.x + cos(p.aim_a) * 70.0, p.y + sin(p.aim_a) * 70.0)
				Spells.cast(String(a[1]), p, at.x, at.y, w * float(a[2]) * stacks, se.uid if se != null else -1)
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
		"plant":
			# ["plant", delay, dmg_mult, radius]: a charge on the foe, blowing a moment later (arsenal.gd)
			var e: Enemy = ctx.get("enemy")
			if e != null:
				# A fist or a blade fires no projectiles: each +1 projectile makes the charge stronger and wider.
				var sp: Array = Arsenal.spend(Weapons.wcount(G.player), 1) if G.player.weapon["kind"] in ["slash", "whip"] else [1, 1.0, 1.0]
				Arsenal.plant(e, float(a[1]), Weapons.wdmg(G.player) * float(a[2]) * stacks * sp[1], float(a[3]) * sp[2])
		"puppet":
			# ["puppet", seconds]: the foe walks into another and bursts (arsenal.gd)
			Arsenal.puppet(ctx.get("enemy"), float(a[1]))
		"charm":
			# ["charm", seconds]: an ordinary foe fights for you (summons.gd)
			Summons.charm(ctx.get("enemy"), float(a[1]))
		"warm":
			# ["warm", n]: the dragon egg grows warmer (summons.gd)
			Summons.warm(int(a[1]) * stacks)
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
		# ---------- ROADMAP 4.7 gear and relics ----------
		"turret":
			# ["turret", kind, seconds, dmg_mult]: a 4.6 turret by you for a while (summons.gd).
			Summons.item_turret(String(a[1]), float(a[2]), w * float(a[3]) * stacks)
		"raise":
			# ["raise", seconds, dmg_mult]: a skeleton climbs out where the foe fell (or beside you).
			var at := _pos(ctx)
			Summons.item_raise(at.x, at.y, float(a[1]), w * float(a[2]) * stacks)
		"reflect":
			# ["reflect", radius, dmg_mult]: foes' shots near you fly back the way they came, as yours.
			var shots := EBullets.take_near(p.x, p.y, float(a[1]), 24)
			for o in shots:
				var spd := maxf(200.0, Vector2(o[2], o[3]).length() * 1.4)
				Combat._raw_shot(o[0], o[1], atan2(-o[3], -o[2]), spd, w * float(a[2]) * stacks, 1.2, 3.0, 0, "spark", {})
			if not shots.is_empty():
				_did("reflect")
				Juice.ring(p.x, p.y, 4, a[1], 0.25, "#f4ecd8")
				Juice.label("REFLECT!", "#f4ecd8", p.x, p.y - 22)
		"spread":
			# ["spread", radius]: the foe's ailments jump to every foe near it.
			var src: Enemy = ctx.get("enemy")
			if src != null:
				var names := ailments(src)
				if not names.is_empty():
					var hit := 0
					for f in G.enemies:
						if f != src and f.targetable() and f.charm_t <= 0 and f.type != "dummy" and TB.dist(f, src) <= float(a[1]) + f.r:
							for nm in names:
								Statuses.apply(f, nm, maxf(1.0, ceilf(src.poison * 0.5)) if nm == "poison" else 1.0, w)
							hit += 1
					if hit > 0:
						_did("spread")
						Juice.ring(src.x, src.y, 4, a[1], 0.3, "#63b84f")
		"consume":
			# ["consume", dmg_mult]: every ailment on the foe is used up, each for a hit of dmg_mult.
			var e := _target(ctx)
			if e != null and e.type != "dummy":
				var names := ailments(e)
				if not names.is_empty():
					e.burn_t = 0.0
					e.poison = 0.0
					e.chill_t = 0.0
					e.bleed_t = 0.0
					e.curse_t = 0.0
					e.shock = 0
					e.vuln_t = 0.0
					e.weak_t = 0.0
					_did("consume")
					Juice.label("CONSUMED %d" % names.size(), "#a35bd6", e.x, e.y - 18)
					Juice.burst(e.x, e.y, "#a35bd6", 10, 70)
					Combat.damage_enemy(e, w * float(a[1]) * names.size() * stacks, { "col": "purple" })
		"give":
			# ["give", what, n]: bombs, keys or potions (up to your potion slots).
			var n := int(a[2]) * stacks
			match String(a[1]):
				"bombs": p.bombs += n
				"keys": p.keys += n
				"potions": n = mini(n, p.max_potions - p.potions); p.potions += n
			if n > 0:
				_did("give")
				Fx.float_text(p.x, p.y - 18, "+%d %s" % [n, { "bombs": "BOMB", "keys": "KEY", "potions": "POTION" }[a[1]]], "white")
		"slow_shots":
			# ["slow_shots", radius, k]: foes' shots near you keep only k of their speed.
			if EBullets.slow_near(p.x, p.y, float(a[1]), float(a[2])) > 0:
				_did("slow_shots")
				Juice.ring(p.x, p.y, a[1], 4, 0.35, "#6fd3e0")
		"overkill":
			# ["overkill", share]: damage past a foe's death carries on to the nearest other foe.
			var e: Enemy = ctx.get("enemy")
			if e != null and e.over > 0:
				var t := Combat.nearest_enemy(e.x, e.y, 140)
				if t != null and t != e:
					var dm := e.over * float(a[1]) * stacks
					e.over = 0.0
					_did("overkill")
					Fx.burst(t.x, t.y, ["#d8443c", "#f4ecd8"], 6, 50)
					Summons.flashes.append({ "k": "zap", "x0": e.x, "y0": e.y - 4, "x1": t.x, "y1": t.y - 4, "t": 0.15, "max": 0.15, "col": "#d8443c" })
					Combat.damage_enemy(t, dm, { "col": "red", "no_crit": true, "no_mult": true })
		# ---------- ROADMAP 4.8 heroes ----------
		"charm_area":
			# ["charm_area", radius, seconds]: every ordinary foe near you fights for you (summons.gd).
			for e in G.enemies.duplicate():
				if e.targetable() and TB.dist(e, p) <= float(a[1]) + e.r:
					Summons.charm(e, float(a[2]))
					_did("charm_area")
		"consume_area":
			# ["consume_area", radius, dmg_mult]: every ailment on every foe near you is used up.
			for e in G.enemies.duplicate():
				if e.targetable() and e.hp > 0 and TB.dist(e, p) <= float(a[1]) + e.r:
					run(["consume", a[2]], stacks, { "enemy": e })
		"execute_weakest":
			# ["execute_weakest", dmg_mult, below]: the most wounded foe in the room takes dmg_mult; below
			# that share of its health (not a guardian), it dies.
			var best: Enemy = null
			for e in G.enemies:
				if e.targetable() and e.hp > 0 and e.type != "dummy" and (best == null or e.hp / e.max_hp < best.hp / best.max_hp):
					best = e
			if best != null:
				_did("execute_weakest")
				Fx.burst(best.x, best.y - 6, ["#d8443c", "#f4ecd8"], 16, 90)
				Juice.label("GUILLOTINE!", "#d8443c", best.x, best.y - 20)
				G.add_shake(4)
				if best.hp < best.max_hp * float(a[2]) and not best.is_boss():
					Combat.damage_enemy(best, best.hp * 2.0 + 10.0, { "no_crit": true, "no_mult": true, "col": "red" })
				else:
					Combat.damage_enemy(best, w * float(a[1]) * stacks, { "col": "red" })
		_:
			push_error("Actions: unknown action " + str(a[0]))
