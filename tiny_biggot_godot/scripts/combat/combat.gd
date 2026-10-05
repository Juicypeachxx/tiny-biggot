class_name Combat
extends RefCounted
## Combat rules (port of Entities.rb, Combat.rb and the combat parts of
## 04b_items.rb). The Ruby used `alias` to layer the 04b weapon engine over
## the base functions. Each function here is the merged result, in the same
## order: base first, then the 04b additions.

# ---------- Small helpers ----------
static func dread() -> int:
	return G.dread

static func floor_scale() -> float:
	return (1 + 0.42 * G.floor_index) * (1 + 0.15 * dread()) * loop_scale()

## Loop playthroughs: foes, mini-bosses and guardians gain 80% health per loop
## (exactly 1.0 on the first time through).
static func loop_scale() -> float:
	return 1.0 + 0.8 * G.loop

static func shot_mult() -> float:
	return (1 + (0.08 * (dread() - 1) if dread() >= 2 else 0.0)) * (1.0 + 0.06 * G.loop)

static func has_los(a: Object, b: Object) -> bool:
	var d := TB.dist_xy(a.x, a.y, b.x, b.y)
	var n := ceili(d / 6)
	for i in range(1, n):
		var k := float(i) / n
		var x: float = a.x + (b.x - a.x) * k
		var y: float = a.y + (b.y - a.y) * k
		if World.solid(G.room, floori(x / TB.TS), floori(y / TB.TS), World.M_BULLET):
			return false
	return true

static func auto_target(p: Player, max_d: float) -> Enemy:
	var best: Enemy = null
	var bd := max_d
	var fb: Enemy = null
	var fd := max_d
	for e in G.enemies:
		if not e.targetable():
			continue
		var d := TB.dist(p, e)
		if d < fd:
			fd = d
			fb = e
		if d < bd and has_los(p, e):
			bd = d
			best = e
	return best if best != null else fb

## Nearest targetable enemy to (fx, fy). skip: uid -> true.
const NO_SKIP := {}
## Rogues layer: foe positions packed once per shot pass (x, y - z, reach),
## so the shots x foes loops read arrays instead of objects. Only a broad
## phase: the exact tests still use the live foe. _cn = -1 when not built.
const CACHE_MARGIN := 8.0
static var _cx := PackedFloat32Array()
static var _cy := PackedFloat32Array()
static var _cr := PackedFloat32Array()
static var _cn := -1

static func _build_foe_cache() -> void:
	var n := G.enemies.size()
	_cx.resize(n)
	_cy.resize(n)
	_cr.resize(n)
	for i in n:
		var e: Enemy = G.enemies[i]
		_cx[i] = e.x
		_cy[i] = e.y - e.z
		_cr[i] = e.r + 2.0 + CACHE_MARGIN
	_cn = n

## Hot path (every homing shot, every tick): no per-call allocations, inline maths.
static func nearest_enemy(fx: float, fy: float, max_d: float, skip: Dictionary = NO_SKIP) -> Enemy:
	var best: Enemy = null
	var bd := max_d * max_d
	var check_skip := not skip.is_empty()
	if _cn >= 0:
		var lim := max_d + CACHE_MARGIN
		var lim2 := lim * lim
		for i in G.enemies.size():
			if i < _cn:
				var qx := fx - _cx[i]
				var qy := fy - _cy[i]
				if qx * qx + qy * qy >= lim2:
					continue
			var e: Enemy = G.enemies[i]
			if e.spawn_t > 0 or e.hidden or e.hp <= 0:
				continue
			var dx := fx - e.x
			var dy := fy - e.y
			var d := dx * dx + dy * dy
			if d < bd and not (check_skip and skip.has(e.uid)):
				bd = d
				best = e
		return best
	for e: Enemy in G.enemies:
		if e.spawn_t > 0 or e.hidden or e.hp <= 0:
			continue
		var dx := fx - e.x
		var dy := fy - e.y
		var d := dx * dx + dy * dy
		if d < bd and not (check_skip and skip.has(e.uid)):
			bd = d
			best = e
	return best

static func orbital_positions(p: Player) -> Array:
	var out := []
	var n := p.orbitals
	for i in n:
		var a := p.orbit_a + float(i) / n * TAU
		out.append(Vector2(p.x + cos(a) * 20, p.y - 2 + sin(a) * 20))
	return out

# ---------- Spawning foes ----------
static func spawn_enemy(type: String, x: float, y: float, elite: bool = false, instant: bool = false) -> Enemy:
	var d: Dictionary = GameData.ENEMIES[type]
	var hp: float = d["hp"] * floor_scale() * (2.2 if elite else 1.0)
	if d.get("mini", false):
		hp = d["hp"] * (1 + 0.15 * dread()) * loop_scale()   # stage-7 mini-bosses: fixed health like guardians
	if d.get("champion", false):
		hp = d["hp"] * floor_scale()   # rift champions turn up on any floor, so their health grows with it
	var e := Enemy.new()
	e.type = type
	e.d = d
	e.x = x
	e.y = y
	e.r = d["r"] * (1.2 if elite else 1.0)
	e.hp = hp
	e.max_hp = hp
	e.speed = d["speed"] * (1 + G.floor_index * 0.05)
	e.t = randf() * 1.5
	e.elite = elite
	e.spawn_t = 0.0 if instant else 0.75
	e.anim = randf() * 10
	e.scale = d.get("scale", 1.0) * (1.2 if elite else 1.0)
	e.gold = d["gold"] * (3 if elite else 1)
	# Never leave a body wedged inside a pillar or crate.
	if not d.get("fly", false) and World.hits_solid(G.room, e.x, e.y, e.r, World.M_WALKER):
		var sp := World.free_spot(G.room, null, 0, World.M_WALKER, e.r + 1)
		e.x = sp.x
		e.y = sp.y
	G.enemies.append(e)
	if d.get("mini", false):
		G.champ = e   # mini-bosses and champions show the boss bar
	if not instant:
		Snd.play("spawn")
	return e

static func spawn_boss(key: String) -> Enemy:
	var d: Dictionary = GameData.BOSSES[key]
	var hp: float = d["hp"] * (1 + 0.15 * dread()) * loop_scale()
	var e := Enemy.new()
	e.type = "boss"
	e.boss = key
	e.d = d
	e.x = TB.SW / 2.0
	e.y = 7.0 * TB.TS
	e.r = d["r"]
	e.hp = hp
	e.max_hp = hp
	e.speed = 30
	e.t = 1.5
	e.state = &"intro"
	e.elite = true
	e.scale = d["scale"]
	G.enemies.append(e)
	G.boss = e
	Snd.play("roar")
	G.add_shake(6)
	return e

# ---------- Enemy shots ----------
static func eshot(x: float, y: float, a: float, speed: float, spr: String = "red", r: float = 2.5,
		fuse: float = -1.0, burst: String = "") -> void:
	speed *= shot_mult()
	EBullets.add(x, y, cos(a) * speed, sin(a) * speed, spr, r, fuse, burst)

static func ering(x: float, y: float, n: int, speed: float, off: float = 0.0, spr: String = "red",
		has_gap: bool = false, gap_a: float = 0.0, gap_w: float = 0.0) -> void:
	for i in n:
		var a := off + float(i) / n * TAU
		if has_gap and absf(TB.wrap_ang(a - gap_a)) < gap_w:
			continue
		eshot(x, y, a, speed, spr, 4.0 if spr.ends_with("Big") else 2.5)
	Afx.cast(x, y, spr)
	Snd.play("ebullet")

static func efan(x: float, y: float, a: float, n: int, spread: float, speed: float, spr: String = "red") -> void:
	for i in n:
		eshot(x, y, a + ((float(i) / (n - 1) - 0.5) * spread if n > 1 else 0.0), speed, spr)
	Afx.cast(x, y, spr)
	Snd.play("ebullet")

# ---------- Damage to foes ----------
static func player_damage_mult(p: Player) -> float:
	var m := 1.0
	if p.miser: m *= 1 + p.gold / 1000.0
	if p.cap("midas"): m *= 1 + p.gold / 500.0
	if p.desperate > 0: m *= 1 + p.desperate * ((p.max_hp - p.hp) / 2)
	if p.fortress > 0: m *= 1 + p.fortress * mini(p.armor, 5)
	if p.cap("sanguine"): m *= 1 + 0.04 * p.room_kills
	if p.post_roll and p.post_roll_t > 0: m *= 1.5
	if p.full_hp_dmg > 0 and p.hp >= p.max_hp: m *= 1 + p.full_hp_dmg
	return m

static func afflicted(e: Enemy) -> bool:
	return e.burn_t > 0 or e.chill_t > 0 or e.poison > 0 or e.bleed_t > 0 or e.stun_t > 0 or e.curse_t > 0

## Damage bonuses from item abilities (04b hook_mult).
static func hook_mult(p: Player, e: Enemy) -> float:
	var m := 1.0
	if p.moving: m += p.g("moving_dmg")
	else: m += p.g("still_dmg")
	if p.hp <= p.max_hp / 2: m += p.g("low_hp_dmg")
	var d := TB.dist(e, p)
	if d < 60: m += p.g("close_dmg")
	if d > 140: m += p.g("far_dmg")
	if e.elite: m += p.g("elite_dmg")
	if e.is_boss(): m += p.g("boss_dmg")
	m += p.g("armor_dmg") * mini(p.armor, 6)
	m += p.g("gold_dmg") * p.gold / 100.0
	m += p.g("relic_dmg") * p.relics.size()
	if p.g("trait_dmg") > 0:
		var ranks := 0
		for v in p.traits.values():
			ranks += v
		m += p.g("trait_dmg") * ranks
	if p.g("status_dmg") > 0 and afflicted(e): m += p.g("status_dmg")
	if e.hp >= e.max_hp: m += p.g("first_hit")
	if p.g("souls") > 0: m += minf(0.5, p.g("souls") * p.floor_kills)
	if e.mark_t > 0: m += e.mark_v
	m += e.shred
	return m

## Returns true on a critical hit. o: force_crit, no_crit, col, kx, ky, silent, no_mult, boom, bomb.
static func damage_enemy(e: Enemy, dmg: float, o: Dictionary = {}) -> bool:
	if e.hp <= 0 or e.spawn_t > 0 or e.hidden:
		return false
	var p := G.player
	var crit := false
	if GameData.rogues():
		dmg *= 0.85 + 0.3 * randf()   # Rogues layer: every hit rolls within +-15%
	if o.get("force_crit", false) or (not o.get("no_crit", false) and randf() < p.crit + (p.g("chill_crit") if e.chill_t > 0 else 0.0)):
		dmg *= p.crit_mult
		crit = true
		# New stat: crit chance past 100% can crit a second time.
		if p.overcrit > 0 and p.crit > 1.0 and randf() < minf(p.crit - 1.0, 1.0):
			dmg *= p.crit_mult * (1 + p.overcrit)
	if p.rage > 0 and p.hp <= 2: dmg *= 1 + p.rage
	if e.elite and p.elite_mult > 0: dmg *= 1 + p.elite_mult
	if e.burn_t > 0 and p.vs_burn > 0: dmg *= 1 + p.vs_burn
	if e.chill_t > 0 and p.vs_chill > 0: dmg *= 1 + p.vs_chill
	if p.corrode > 0 and e.poison > 0: dmg *= 1 + p.corrode * e.poison
	if e.curse_t > 0: dmg *= 1.25
	if o.get("boom", false) and p.boom_elite and e.elite: dmg *= 2
	if not o.get("no_mult", false): dmg *= player_damage_mult(p) * hook_mult(p, e)
	if e.vuln_t > 0 or e.shock > 0:
		dmg *= Statuses.dmg_mult(e)
	e.hp -= dmg
	e.flash = 0.08
	if o.has("kx") and not e.is_boss():
		e.kx += o["kx"]
		e.ky += o["ky"]
	Fx.float_text(e.x, e.y - e.r - 6, TB.fmt_dmg(dmg), "gold" if crit else o.get("col", "white"), crit)
	if not o.get("silent", false):
		Snd.play("hit")
	if crit:
		Afx.crit(e.x, e.y - e.z - 2.0)
		if p.crit_heal > 0 and e.type != "dummy" and randf() < p.crit_heal:
			p.heal(1)
		if p.bleed > 0:
			e.bleed_t = 3.0
			e.bleed_dps = dmg * 0.25 * p.bleed
	if e.hp > 0 and p.cap("shatter") and e.chill_t > 0 and not e.is_boss() and e.hp < e.max_hp * 0.3:
		e.shattered = true
		e.hp = 0
	if e.hp <= 0:
		kill_enemy(e, o)
	return crit

static func kill_enemy(e: Enemy, o: Dictionary = {}) -> void:
	var p := G.player
	e.hp = 0
	p.kills += 1
	p.room_kills += 1
	G.run_stats["kills"] += 1
	Saloon.on_kill(e)
	var boss := e.is_boss()
	var cols := ["#f4ecd8", "#f2c94c", "#d8443c", "#a35bd6"] if boss else ["#f4ecd8", "#8b8f9c", GameData.SPRITE_COLOR.get(e.d["sprite"], "#d8443c")]
	Fx.burst(e.x, e.y, cols, 60 if boss else 14, 140 if boss else 70, 1.0 if boss else 0.45)
	if boss:
		Vfx.blast(e.x, e.y, 60.0, "#f2c94c")   # a guardian goes up in a cluster of blasts
	Snd.play("boom" if boss else "kill")
	G.add_shake(10 if boss else 2)
	Juice.kill(e, e.d["sprite"] + ("_elite" if e.elite and not boss else ""))
	# Experience.
	var xp: int = 40 + 10 * G.floor_index if boss else GameData.ENEMY_XP.get(e.type, 3) * (3 if e.elite else 1)
	gain_xp(p, xp)
	if GameData.rogues() and (boss or (e.elite and randf() < 0.15)):
		drop_pickup(Consumables.random_kind(), e.x, e.y)   # Rogues layer: belt consumables
	if not boss:
		if e.gold > 0 and randf() < minf(0.95, e.gold * 1.8 * p.gold_drop):
			for i in TB.rint(1, 5 if e.elite else 2):
				drop_pickup("coin", e.x, e.y)
		if randf() < (0.22 if e.elite else 0.03):
			drop_pickup("heart", e.x, e.y)
		var roll := randf()
		if roll < (0.06 if e.elite else 0.012): drop_pickup("ember", e.x, e.y)
		elif roll < (0.14 if e.elite else 0.03): drop_pickup("bomb", e.x, e.y)
		elif roll < (0.2 if e.elite else 0.042): drop_pickup("key", e.x, e.y)
		elif roll < (0.26 if e.elite else 0.054): drop_pickup("armor", e.x, e.y)
		elif e.elite and roll < 0.36: drop_pickup("gem", e.x, e.y)
	if p.jackpot and e.elite:
		for i in 3:
			drop_pickup("gem", e.x, e.y)
	if p.lifesteal > 0 and randf() < p.lifesteal:
		p.heal(1)
	if p.frenzy > 0:
		p.frenzy_t = 2 + p.frenzy
	if o.get("bomb", false) and p.harvest:
		if randf() < 0.3: drop_pickup("bomb", e.x, e.y)
		if randf() < 0.08: drop_pickup("heart", e.x, e.y)
	if p.splinter > 0:
		var n := 4 * p.splinter
		for i in n:
			var a := float(i) / n * TAU + randf()
			_raw_shot(e.x, e.y, a, 180, Weapons.wdmg(p) * 0.5, 0.4, 2.0, 0, "spark", { e.uid: true })
	# Trait death effects.
	if p.cap("inferno") and e.burn_t > 0:
		explode_at(e.x, e.y, Weapons.wdmg(p) * 1.5, e, 30, "#e8873a")
		for o2 in G.enemies:
			if TB.dist(o2, e) < 46:
				o2.burn_t = maxf(o2.burn_t, 3.0 + p.burn_time)
	if e.shattered:
		Fx.burst(e.x, e.y, ["#c8f0ff", "#6fd3e0", "#ffffff"], 18, 90)
		Vfx.shatter(e.x, e.y)
		for i in 8:
			var b := _raw_shot(e.x, e.y, i / 8.0 * TAU, 170, Weapons.wdmg(p) * 0.8, 0.45, 2.5, 1, "lance", { e.uid: true })
			b.chill = true
		Fx.float_text(e.x, e.y - 14, "SHATTER", "cyan")
	if (p.cap("plague") or p.volatile) and e.poison > 0:
		if p.cap("plague"):
			for o2 in G.enemies:
				if o2 != e and TB.dist(o2, e) < 60:
					o2.poison = minf(12, o2.poison + e.poison)
		if p.volatile:
			explode_at(e.x, e.y, Weapons.wdmg(p) * (1 + e.poison * 0.3), e, 28, "#b8e05a")
	if p.cloud > 0:
		G.zones.append({ "x": e.x, "y": e.y, "r": 18 + 6 * p.cloud, "t": 3.0, "kind": "poison", "tick": 0.0 })
	if p.chill_spread and e.chill_t > 0:
		for o2 in G.enemies:
			if TB.dist(o2, e) < 50:
				o2.chill_t = maxf(o2.chill_t, 2.0)
	if p.carrion > 0 and randf() < p.carrion and G.temp_fams.size() < 8:
		G.temp_fams.append({ "x": e.x, "y": e.y, "cd": 0.2, "t": 6.0 })
	if p.cap("legion"):
		p.legion_n += 1
		if p.legion_n >= 5 and G.temp_fams.size() < 6:
			p.legion_n = 0
			G.temp_fams.append({ "x": e.x, "y": e.y, "cd": 0.2, "t": 10.0 })
	if e.type == "slime":
		for i in 2:
			var sl := spawn_enemy("slimelet", e.x + (6 if i == 1 else -6), e.y, false, true)
			sl.kx = 80 if i == 1 else -80
	if e.type == "drowned":
		ering(e.x, e.y, 8 + (4 if e.elite else 0), 60, randf(), "water")
	if e.type == "goblin":
		G.on_goblin_dead(e)
	if boss:
		G.on_boss_dead(e)
	# 04b additions.
	p.floor_kills += 1
	if p.g("kill_explode") > 0:
		explode_at(e.x, e.y, Weapons.wdmg(p) * p.g("kill_explode"), e, 26, "#e8873a", true)
	if p.g("kill_wisp") > 0 and randf() < p.g("kill_wisp") and G.temp_fams.size() < 8:
		G.temp_fams.append({ "x": e.x, "y": e.y, "cd": 0.2, "t": 6.0 })
	if p.g("kill_heal") > 0 and randf() < p.g("kill_heal"):
		p.heal(1)
	if p.g("kill_roll") > 0 and randf() < p.g("kill_roll"):
		p.charges = mini(p.charges + 1, p.dodge_charges)
	if p.g("kill_haste") > 0:
		p.haste_t = maxf(p.haste_t, p.g("kill_haste"))
	if p.g("bomb_on_kill") > 0 and randf() < p.g("bomb_on_kill"):
		drop_pickup("bomb", e.x, e.y)
	# The Gaolbird: kills build tempo and count toward a rally.
	if p.tempo_max > 0:
		Tempo.on_kill(p, e)
	if p.rally_t > 0:
		Rally.on_blow(p, Rally.KILL_BLOWS)
	# Effect system (new content only).
	if e.shock > 0:
		chain_from(e, Weapons.wdmg(p) * 0.3 * e.shock)
	if not p.procs.is_empty():
		Effects.fire("on_kill", { "enemy": e, "x": e.x, "y": e.y, "elite": e.elite })
	if e.elite and not e.is_boss() and randf() < 0.05:
		G.drop_gear_at(e.x, e.y)

static func gain_xp(p: Player, n: int) -> void:
	p.xp += roundi(n * p.xp_mult)
	while p.xp >= GameData.xp_needed(p.level):
		p.xp -= GameData.xp_needed(p.level)
		p.level += 1
		p.pending += 1
		Fx.float_text(p.x, p.y - 18, "LEVEL UP!", "lime")
		Juice.level_up(p.x, p.y)
		Fx.burst(p.x, p.y, ["#b8e05a", "#f2c94c", "#ffffff"], 18, 80)
		Snd.play("unlock")
		if not p.procs.is_empty():
			Effects.fire("on_level_up")

# ---------- Damage to the player ----------
static func hurt_player(amount: int, source: String) -> void:
	var p := G.player
	var before := p.invuln
	var hp0 := p.hp
	_hurt_player_base(p, amount, source)
	# 04b: gear reactions, only when a real hit landed.
	if not (G.state == &"play" and p.invuln > before and p.invuln >= 1.0):
		return
	if G.room != null:
		G.room.hits += 1
	# The Gaolbird: a hit breaks tempo, and lost health can be won back.
	if p.tempo_max > 0:
		Tempo.on_hurt(p)
	if p.rally_n > 0 and p.hp > 0:
		Rally.on_hurt(p, hp0 - p.hp)
	if p.g("frost_skin") > 0:
		for e in G.enemies:
			if TB.dist(e, p) < 90:
				e.chill_t = 2.5
		Fx.burst(p.x, p.y, ["#c8f0ff", "#6fd3e0"], 14, 80)
		Vfx.nova(p.x, p.y, 90.0, "frost")
	if p.g("spark_skin") > 0:
		for e in _nearest_targets(p, 3):
			lightning(e, Weapons.wdmg(p))
	var n := int(p.g("thorns_nova"))
	for i in n:
		spawn_pbullet(p, i * TAU / n, Weapons.wdmg(p) * 0.8, "dart")
	if p.g("reflect_hit") > 0:
		for i in 12:
			spawn_pbullet(p, i * TAU / 12, Weapons.wdmg(p) * 1.2, "spark")
	if not p.procs.is_empty():
		Effects.fire("on_damage_taken", { "x": p.x, "y": p.y })

static func _hurt_player_base(p: Player, amount: int, source: String) -> void:
	if p.invuln > 0 or p.dodge_t > 0 or G.state != &"play" or G.god:
		return
	if p.evade > 0 and randf() < minf(p.evade, 0.6):
		p.invuln = 0.4
		Fx.float_text(p.x, p.y - 12, "DODGED", "purple")
		Fx.burst(p.x, p.y, ["#a35bd6", "#e8c8ff"], 8, 50)
		return
	if p.buckler and not p.buckler_used:
		p.buckler_used = true
		p.invuln = 0.6
		Fx.burst(p.x, p.y, ["#8b8f9c", "#f4ecd8"], 12, 70)
		Fx.float_text(p.x, p.y - 12, "BLOCKED", "grey")
		Snd.play("hit")
		return
	if p.armor > 0:
		p.armor -= 1
		Fx.burst(p.x, p.y, ["#4d9be6", "#6fd3e0", "#f4ecd8"], 12, 70)
		Fx.float_text(p.x, p.y - 12, "ARMOR", "cyan")
		if p.cap("unbreakable"):
			for i in 16:
				spawn_pbullet(p, i / 16.0 * TAU, Weapons.wdmg(p) * 1.5, "spark")
			EBullets.kill_radius(p.x, p.y, 70)
			G.add_shake(4)
	else:
		p.hp -= amount
	if p.ice_armor:
		for e in G.enemies:
			if TB.dist(e, p) < 90:
				e.chill_t = 2.5 + p.chill_time
		Fx.burst(p.x, p.y, ["#c8f0ff", "#6fd3e0"], 16, 90)
		Vfx.nova(p.x, p.y, 90.0, "frost")
	p.invuln = 1.1
	G.hitstop = 0.06
	G.add_shake(5)
	Snd.play("hurt")
	Juice.hurt()
	Fx.burst(p.x, p.y, ["#d8443c", "#8a2a33", "#f4ecd8"], 14, 80)
	EBullets.kill_radius(p.x, p.y, 34)
	if p.ward > 0:
		var n := 12 * p.ward
		for i in n:
			spawn_pbullet(p, float(i) / n * TAU, Weapons.wdmg(p) * 1.2, "hex")
	if p.hp > 0:
		return
	var phoenix := p.g("revive_g") > 0 and not p.phoenix_used
	if p.revive > 0 or phoenix:
		if phoenix:
			p.phoenix_used = true
		else:
			p.revive -= 1
		p.hp = 4
		p.invuln = 2.5
		EBullets.clear_all()
		Fx.burst(p.x, p.y, ["#e8873a", "#f2c94c", "#d8443c"], 40, 120, 0.8, 2)
		Vfx.blast(p.x, p.y, 70.0, "#e8873a")
		G.show_banner("RISEN AGAIN", "YOU CHEAT DEATH ONCE")
		Snd.play("portal")
		return
	G.on_death(source)

static func _nearest_targets(p: Player, k: int) -> Array:
	var list := []
	for e in G.enemies:
		if e.targetable():
			list.append(e)
	list.sort_custom(func(a, b): return TB.dist(p, a) < TB.dist(p, b))
	return list.slice(0, k)

# ---------- Enemies ----------
static func update_enemies(dt: float) -> void:
	var p := G.player
	var room := G.room
	var i := 0
	while i < G.enemies.size():
		var e: Enemy = G.enemies[i]
		i += 1
		if e.hp <= 0:
			continue
		e.anim += dt
		e.flash = maxf(0.0, e.flash - dt)
		if e.spawn_t > 0:
			e.spawn_t -= dt
			continue
		var slow := p.chill_slow if e.chill_t > 0 else 1.0
		e.chill_t = maxf(0.0, e.chill_t - dt)
		if e.curse_t > 0:
			e.curse_t -= dt
		if e.bleed_t > 0:
			e.bleed_t -= dt
			e.bleed_tick -= dt
			if e.bleed_tick <= 0:
				e.bleed_tick = 0.5
				damage_enemy(e, e.bleed_dps * 0.5, { "no_crit": true, "col": "red", "silent": true, "no_mult": true })
			if randf() < 0.25:
				Fx.particle(e.x + TB.rint(-3, 3), e.y, 0, 30, 0.3, "#8a2a33")
			if e.hp <= 0:
				continue
		if e.burn_t > 0:
			e.burn_t -= dt
			e.burn_tick -= dt
			if e.burn_tick <= 0:
				e.burn_tick = 0.5
				damage_enemy(e, (1 + Weapons.wdmg(p) * 0.2) * (1 + p.burn_dmg), { "no_crit": true, "col": "orange", "silent": true })
				if p.burn_leap > 0 and randf() < p.burn_leap:
					for o2 in G.enemies:
						if o2 != e and o2.hp > 0 and o2.burn_t <= 0 and TB.dist(o2, e) < 50:
							o2.burn_t = 3.0 + p.burn_time
							Fx.particle(o2.x, o2.y - 4, 0, -20, 0.4, "#f2c94c", 2)
							break
			if randf() < 0.3:
				Fx.particle(e.x + TB.rint(-4, 4), e.y - 4, 0, -25, 0.3, TB.pick(["#e8873a", "#f2c94c"]))
		if e.poison > 0:
			e.poison_t -= dt
			if e.poison_t <= 0:
				e.poison_t = 0.3 if p.poison_fast else 0.6
				var venom: int = p.fam_bonus.get("venom", 0)
				damage_enemy(e, e.poison * 1.2 * (1 + p.poison_dmg), { "no_crit": venom < 3, "col": "lime", "silent": true })
				e.poison = maxf(0.0, e.poison - 0.25)
		if e.hp <= 0:
			continue
		var ddt := dt * slow
		if e.vuln_t > 0 or e.weak_t > 0 or e.shock_t > 0:
			if e.weak_t > 0:
				ddt *= 0.7
			Statuses.tick(e, dt)
		if e.stun_t > 0:
			e.stun_t -= dt
			if randf() < 0.5:
				Fx.hide = Vfx.enabled   # Vfx draws orbiting stars instead
				Fx.particle(e.x + cos(G.time * 8) * 6, e.y - e.r - 6, 0, 0, 0.05, "#f2c94c")
				Fx.hide = false
			continue
		e.t -= ddt
		if e.is_boss():
			BossAI.update_boss(e, ddt)
		else:
			EnemyAI.run(e, ddt, p)
		if e.kx != 0 or e.ky != 0:
			World.move_body(room, e, e.kx * dt, e.ky * dt, World.M_FLYER if e.d.get("fly", false) else World.M_WALKER)
			e.kx *= 0.82
			e.ky *= 0.82
			if absf(e.kx) < 2: e.kx = 0.0
			if absf(e.ky) < 2: e.ky = 0.0
		if not e.hidden and TB.dist(e, p) < e.r + p.r:
			hurt_player(1, e.d["name"] if e.is_boss() else e.d.get("label", "a " + e.type))
			if p.thorns > 0 and not e.thorn_cd > 0:
				damage_enemy(e, p.thorns, { "no_crit": true, "col": "green" })
				e.thorn_cd = 0.5
		if e.thorn_cd > 0:
			e.thorn_cd -= dt
		if p.orbitals > 0:
			for o in orbital_positions(p):
				if TB.dist_xy(o.x, o.y, e.x, e.y) < e.r + 5 and not p.orbit_hit.has(e.uid):
					p.orbit_hit[e.uid] = 0.35
					damage_enemy(e, Weapons.wdmg(p) * 0.7, {})
	var alive: Array[Enemy] = []
	for e in G.enemies:
		if e.hp > 0:
			alive.append(e)
	G.enemies = alive

static func steer(e: Enemy, tx: float, ty: float, spd: float, dt: float, mode: int) -> int:
	var a := atan2(ty - e.y, tx - e.x)
	var d := TB.dist_xy(tx, ty, e.x, e.y)
	if d < 1:
		return 0
	var s := minf(spd * dt, d)
	if absf(cos(a)) > 0.2:
		e.face = 1 if cos(a) > 0 else -1
	return World.move_body(G.room, e, cos(a) * s, sin(a) * s, mode)

# ---------- Player shots ----------
static var _pool: Array[PBullet] = []

static func new_pbullet() -> PBullet:
	if _pool.is_empty():
		return PBullet.new()
	var b: PBullet = _pool.pop_back()
	b.reset()
	return b

static func recycle(b: PBullet) -> void:
	if _pool.size() < 4096:
		_pool.append(b)

## A plain shot that bypasses the weapon (splinters, shatter shards, familiars).
static func _raw_shot(x: float, y: float, a: float, spd: float, dmg: float, life: float, r: float,
		pierce: int, kind: String, hit: Dictionary, homing: float = 0.0) -> PBullet:
	if G.pbullets.size() + G.new_pbullets.size() >= Effects.pbullet_cap():
		return _merge_shot(dmg)
	var b := new_pbullet()
	b.x = x
	b.y = y
	b.vx = cos(a) * spd
	b.vy = sin(a) * spd
	b.dmg = dmg
	b.life = life
	b.max_life = life
	b.r = r
	b.pierce = pierce
	b.homing = homing
	b.kind = kind
	b.hit = hit
	G.pbullets.append(b)
	return b

## Bullet hard cap (spec section 3): past the cap a new shot is not created.
## Its damage is folded into the newest live shot instead, so damage keeps
## being simulated.
static func _merge_shot(dmg: float) -> PBullet:
	Effects.stats["merged_shots"] += 1
	var b: PBullet = G.pbullets[G.pbullets.size() - 1] if not G.pbullets.is_empty() else G.new_pbullets[G.new_pbullets.size() - 1]
	b.dmg += dmg
	return b

static func spawn_pbullet(p: Player, a: float, dmg: Variant = null, kind: String = "", speed_mul: float = 1.0) -> PBullet:
	var w: Dictionary = p.weapon
	if kind == "":
		kind = Weapons.BULLET_KIND.get(w["kind"], "bolt")
	var sp := Weapons.wspd(p) * (0.94 + randf() * 0.12) * speed_mul
	if sp <= 0:
		sp = 220 * speed_mul
	var life := Weapons.wlife(p)
	if life <= 0:
		life = 0.9
	if kind == "clod" or kind == "fire":
		life *= 0.85 + randf() * 0.3
	var size := Weapons.wsize(p)
	if G.pbullets.size() + G.new_pbullets.size() >= Effects.pbullet_cap():
		return _merge_shot(dmg if dmg != null else Weapons.wdmg(p))
	var b := new_pbullet()
	b.x = p.x + cos(a)
	b.y = p.y - 2 + sin(a)
	b.vx = cos(a) * sp
	b.vy = sin(a) * sp
	b.dmg = dmg if dmg != null else Weapons.wdmg(p)
	b.life = life
	b.max_life = life
	b.r = (2.0 if kind == "fire" else 2.5) * size
	b.pierce = Weapons.wpierce(p)
	b.bounce = Weapons.wbounce(p)
	b.homing = Weapons.whoming(p)
	b.kind = kind
	b.ric = p.ricochet
	b.back = PBullet.BACK_OUT if kind == "boomer" else PBullet.BACK_NONE
	b.bloom = p.bloom
	b.split = p.g("split")
	b.grow = p.g("grow")
	b.accel = p.g("accel")
	b.icon = w["sprite"]
	b.tag = w["tags"][0] if w["tags"].size() > 0 else ""
	if kind == "pulse":
		b.nohit = true
		b.pulse_t = 0.0
		b.linger = p.g("linger")
	if kind == "mine":
		b.nohit = true
		b.vx = 0.0
		b.vy = 0.0
		b.arm = 0.3
		b.life = 8.0
		b.x = p.x + cos(a) * 10
		b.y = p.y + sin(a) * 10
		# Mines are tossed toward the aim and skid to a stop, so they can be planted on archers and casters.
		var tgt: Enemy = null
		var td := INF
		for e in G.enemies:
			if e.targetable() and cos(TB.ang_to(p, e) - a) > 0.85 and TB.dist(p, e) < td:
				td = TB.dist(p, e)
				tgt = e
		var reach := maxf(td - 10, 4) if tgt != null else 50.0
		var toss := minf(reach, 110 * p.shot_speed) * 6.5
		b.has_mv = true
		b.mvx = cos(a) * toss
		b.mvy = sin(a) * toss
	if kind == "rail":
		b.pierce = 99
		b.r = 4.0 * size
	G.pbullets.append(b)
	return b

static func fire_projectiles(p: Player, a: float) -> Array:
	var w: Dictionary = p.weapon
	var n := Weapons.wcount(p)
	var step := Weapons.wspread(p)
	var made := []
	match w["kind"]:
		"nova":
			for i in n:
				made.append(spawn_pbullet(p, a + i * TAU / n))
		"flame":
			for i in n:
				made.append(spawn_pbullet(p, a + (randf() - 0.5) * 2 * step, null, "", 0.8 + randf() * 0.4))
		"mine":
			var live := 0
			for b in G.pbullets:
				if b.kind == "mine":
					live += 1
			if live < 6 + n:
				made.append(spawn_pbullet(p, a))
		_:
			var jit := 0.12 if w["kind"] == "shot" else (step if w["kind"] == "gatling" else 0.0)
			for i in n:
				made.append(spawn_pbullet(p, a + (i - (n - 1) / 2.0) * step + (randf() - 0.5) * jit))
	var bs := p.backshot
	for i in bs:
		made.append(spawn_pbullet(p, a + PI + (i - (bs - 1) / 2.0) * 0.25))
	if w["kind"] == "summon":
		while G.temp_fams.size() >= 4:
			G.temp_fams.pop_front()
		G.temp_fams.append({ "x": p.x, "y": p.y, "cd": 0.3, "t": 6.0 })
	return made

static func player_shoot(p: Player, a: float, echo_ok: bool = true) -> void:
	var w: Dictionary = p.weapon
	p.shot_n += 1
	var forced := false
	if p.ambush_left > 0:
		p.ambush_left -= 1
		forced = true
	var made := []
	match w["kind"]:
		"slash":
			attack_slash(p, a, forced)
			Snd.play("hatchet")
		"thrust":
			var n := Weapons.wcount(p)
			var step := Weapons.wspread(p)
			for i in n:
				attack_line(p, a + (i - (n - 1) / 2.0) * step, Weapons.wrange(p), w.get("width", 8) * Weapons.wsize(p), false, forced)
			Snd.play("hatchet")
		"whip":
			attack_line(p, a, Weapons.wrange(p), w.get("width", 6) * Weapons.wsize(p), true, forced)
			Snd.play("dodge")
		"beam":
			attack_beam(p, a, forced)
			if p.shot_n % 3 == 0:
				Snd.play("shoot")
		"zap":
			attack_zap(p, a, forced)
		_:
			made = fire_projectiles(p, a)
			if w["kind"] == "burst":
				p.volleys.append({ "t": 0.07, "raw": true })
				p.volleys.append({ "t": 0.14, "raw": true })
			var k: String = w["kind"]
			Snd.play("dodge" if k == "flame" else ("hatchet" if k in ["spin", "boomer", "disc"] else ("bolt" if k in ["bolt", "rail"] else "shoot")))
	if forced:
		for b in made:
			b.crit = true
	if p.tempo_max > 0 or p.rally_n > 0:
		for b in made:
			b.own = true   # the Gaolbird: only the weapon's own shots count as blows
	var nb := (p.heavy_n > 0 and p.shot_n % p.heavy_n == 0) or (p.g("nth_big") > 0 and p.shot_n % int(p.g("nth_big")) == 0)
	if nb:
		for b in made:
			b.dmg *= 3
			b.r *= 1.5
	if p.g("nth_nova") > 0 and p.shot_n % int(p.g("nth_nova")) == 0:
		for i in 8:
			spawn_pbullet(p, a + i * TAU / 8, Weapons.wdmg(p) * 0.7, "fire" if "pyre" in w["tags"] else "spark")
	var zn := 0
	for v in [p.thunder_n, int(p.g("nth_zap"))]:
		if v > 0 and (zn == 0 or v < zn):
			zn = v
	if zn > 0 and p.shot_n % zn == 0:
		var t := auto_target(p, 300)
		if t != null:
			lightning(t, Weapons.wdmg(p))
	if p.lance_n > 0 and p.shot_n % p.lance_n == 0:
		var l := spawn_pbullet(p, a, Weapons.wdmg(p) * 1.6, "lance", 1.3)
		l.pierce = 99
		l.r = 4
		l.chill = true
		l.life = 1.0
		l.split = 0
	if p.barbs > 0 and randf() < p.barbs:
		var dt_ := spawn_pbullet(p, a + (randf() - 0.5) * 0.4, Weapons.wdmg(p) * 0.5, "dart", 1.2)
		dt_.poison_add = 2
		dt_.split = 0
	if echo_ok and p.echo > 0 and randf() < p.echo:
		p.volleys.append({ "t": 0.15 })
	if not w["kind"] in ["slash", "thrust", "whip", "beam", "zap"]:
		Fx.particle(p.x + cos(a) * 8, p.y - 2 + sin(a) * 8, 0, 0, 0.06, "#fffbe0", 3)
	if not p.procs.is_empty():
		Effects.fire("on_shoot", { "x": p.x, "y": p.y })
		Effects.fire("every_n_shots", { "x": p.x, "y": p.y })

# ---------- Melee and instant attacks (04b) ----------
static func melee_hit(p: Player, e: Enemy, dmg: float, force_crit: bool = false, kb: float = 90) -> void:
	var a := TB.ang_to(p, e)
	var k := kb * (p.g("knock") if p.g("knock") > 0 else 1.0)
	var crit := damage_enemy(e, dmg, { "kx": cos(a) * k, "ky": sin(a) * k, "force_crit": force_crit })
	on_hit_effects(e, dmg, crit, p, null)

## Cuts enemy shots out of the air when the weapon can parry. test(x, y) -> bool.
static func parry_bullets(p: Player, test: Callable) -> void:
	if p.g("parry") <= 0:
		return
	for i in EBullets.n:
		if not EBullets.alive(i) or EBullets.blife[i] <= 0:
			continue
		var bx := EBullets.bx[i]
		var by := EBullets.by[i]
		if not test.call(bx, by):
			continue
		EBullets.blife[i] = EBullets.KILLED
		Fx.burst(bx, by, ["#f4ecd8", "#ffffff"], 3, 40, 0.2)
		if p.g("reflect") > 0:
			var nb := spawn_pbullet(p, atan2(by - p.y, bx - p.x), Weapons.wdmg(p) * 0.6, "spark", 1.2)
			nb.x = bx
			nb.y = by

static func attack_slash(p: Player, a: float, force_crit: bool) -> void:
	var w: Dictionary = p.weapon
	var r := Weapons.wrange(p)
	var arc: float = w.get("arc", 110) * PI / 180
	var dmg := Weapons.wdmg(p)
	for e in G.enemies.duplicate():
		if not e.targetable():
			continue
		if TB.dist(e, p) - e.r > r:
			continue
		if absf(TB.wrap_ang(TB.ang_to(p, e) - a)) > arc / 2:
			continue
		melee_hit(p, e, dmg, force_crit, 110)
		Afx.cut(e.x, e.y - e.z, TB.ang_to(p, e), false)
	var px := p.x
	var py := p.y
	parry_bullets(p, func(bx: float, by: float) -> bool:
		var d := TB.dist_xy(bx, by, px, py)
		var da := TB.wrap_ang(atan2(by - py, bx - px) - a)
		return d < r + 4 and absf(da) <= arc / 2)
	G.swings.append({ "kind": "slash", "x": p.x, "y": p.y - 2, "a": a, "r": r, "arc": arc, "t": 0.14, "max": 0.14,
		"tag": w["tags"][0] if w["tags"].size() > 0 else "" })

static func attack_line(p: Player, a: float, length: float, width: float, tip_crit: bool, force_crit: bool) -> void:
	var dx := cos(a)
	var dy := sin(a)
	var hits := []
	for e in G.enemies:
		if not e.targetable():
			continue
		var px := e.x - p.x
		var py := e.y - p.y
		var along := px * dx + py * dy
		var perp := absf(px * dy - py * dx)
		if along > -e.r and along < length + e.r and perp < width / 2.0 + e.r:
			hits.append([e, along])
	hits.sort_custom(func(h1, h2): return h1[1] < h2[1])
	for i in hits.size():
		var e: Enemy = hits[i][0]
		var along: float = hits[i][1]
		var dmg := Weapons.wdmg(p) * (1 + p.g("pierce_dmg") * i)
		melee_hit(p, e, dmg, force_crit or (tip_crit and along > length * 0.7), 80)
		Afx.cut(e.x, e.y - e.z, a, true)
	var ox := p.x
	var oy := p.y
	parry_bullets(p, func(bx: float, by: float) -> bool:
		var px := bx - ox
		var py := by - oy
		var al := px * dx + py * dy
		return al > 0 and al < length and absf(px * dy - py * dx) < width / 2.0 + 4)
	var w: Dictionary = p.weapon
	G.swings.append({ "kind": "whip" if tip_crit else "thrust", "x": p.x, "y": p.y - 2, "a": a, "len": length,
		"width": width, "t": 0.12, "max": 0.12, "tag": w["tags"][0] if w["tags"].size() > 0 else "" })

static func attack_beam(p: Player, a: float, force_crit: bool) -> void:
	var w: Dictionary = p.weapon
	var rng := Weapons.wrange(p)
	var dx := cos(a)
	var dy := sin(a)
	var length := rng
	var steps := floori(rng / 4)
	for i in range(1, steps + 1):
		var x := p.x + dx * i * 4
		var y := p.y - 2 + dy * i * 4
		if World.solid(G.room, floori(x / TB.TS), floori(y / TB.TS), World.M_BULLET):
			length = i * 4
			break
	var hits := []
	for e in G.enemies:
		if not e.targetable():
			continue
		var px := e.x - p.x
		var py := e.y - 2 - p.y
		var along := px * dx + py * dy
		if along > 0 and along < length and absf(px * dy - py * dx) < e.r + 3 * Weapons.wsize(p):
			hits.append([e, along])
	hits.sort_custom(func(h1, h2): return h1[1] < h2[1])
	var pc := Weapons.wpierce(p)
	if pc < 99:
		hits = hits.slice(0, 1 + pc)
	if not hits.is_empty() and pc < 99:
		length = hits[hits.size() - 1][1]
	for h in hits:
		melee_hit(p, h[0], Weapons.wdmg(p), force_crit, 10)
	var bt := maxf(0.07, 1.15 / Weapons.wrate(p))
	var keep := []
	for s in G.swings:
		if s["kind"] != "beam":
			keep.append(s)
	G.swings = keep
	G.swings.append({ "kind": "beam", "x": p.x, "y": p.y - 2, "a": a, "len": length, "t": bt, "max": bt,
		"tag": w["tags"][0] if w["tags"].size() > 0 else "" })

static func attack_zap(p: Player, a: float, force_crit: bool) -> void:
	var w: Dictionary = p.weapon
	var rng := Weapons.wrange(p)
	var best: Enemy = null
	var bd := 1e9
	for e in G.enemies:
		if not e.targetable():
			continue
		var d := TB.dist(p, e)
		if d > rng or not has_los(p, e):
			continue
		var da := absf(TB.wrap_ang(TB.ang_to(p, e) - a))
		var score := d + da * 60
		if score < bd:
			bd = score
			best = e
	if best == null:
		return
	var hit := {}
	var cur := Vector2(p.x, p.y - 2)
	var tgt: Enemy = best
	for k in w.get("chain", 2) + p.chain_jumps + 1:
		if tgt == null:
			break
		var n := maxi(ceili(cur.distance_to(Vector2(tgt.x, tgt.y)) / 6), 1)
		Fx.hide = Vfx.enabled   # Vfx draws the arc
		for i in range(0, n + 1):
			var kk := float(i) / n
			Fx.particle(cur.x + (tgt.x - cur.x) * kk + TB.rint(-2, 2), cur.y + (tgt.y - cur.y) * kk + TB.rint(-2, 2),
				0, 0, 0.12, "#6fd3e0" if randf() < 0.5 else "#ffffff")
		Fx.hide = false
		Vfx.arc(cur.x, cur.y, tgt.x, tgt.y, k * 2)
		hit[tgt.uid] = true
		melee_hit(p, tgt, Weapons.wdmg(p), force_crit, 20)
		cur = Vector2(tgt.x, tgt.y)
		tgt = nearest_enemy(tgt.x, tgt.y, 70, hit)
	if randf() < 0.2:
		Snd.play("beam")

# ---------- Hits ----------
static func on_hit_effects(e: Enemy, dmg: float, crit: bool, p: Player, b: PBullet) -> void:
	if e.type == "dummy":
		return   # training dummies: no procs, statuses or loot from hitting them
	# The Gaolbird: a blow is a hit by the weapon itself (a swing, or one of its own shots)
	# on a foe that is still standing; the kill is counted on its own in kill_enemy.
	if (p.tempo_max > 0 or p.rally_t > 0) and e.hp > 0 and (b == null or b.own):
		if p.tempo_max > 0:
			Tempo.on_hit(p)
		if p.rally_t > 0:
			Rally.on_blow(p, 1)
	if p.burn > 0 and randf() < p.burn:
		e.burn_t = 3.0 + p.burn_time
	if (b != null and b.chill) or (p.chill > 0 and randf() < p.chill):
		if e.chill_t <= 0:
			Vfx.puff(e.x, e.y, "frost")
		e.chill_t = 2.0 + p.chill_time
		Fx.burst(e.x, e.y, ["#6fd3e0", "#ffffff"], 5, 30)
	var padd := b.poison_add if b != null else 0
	if p.poison > 0 or padd > 0:
		e.poison = minf(12, e.poison + p.poison + padd)
	if p.stun > 0 and randf() < p.stun:
		e.stun_t = 0.25 if e.is_boss() else 1.0
	if p.curse > 0 and randf() < p.curse:
		e.curse_t = 3.0
	if p.g("mark") > 0:
		e.mark_t = 3.0
		e.mark_v = p.g("mark")
	if p.g("shred") > 0:
		e.shred = minf(5 * p.g("shred"), e.shred + p.g("shred"))
	if p.g("leech") > 0 and randf() < p.g("leech"):
		p.heal(1)
	if p.g("gold_hit") > 0 and randf() < p.g("gold_hit"):
		drop_pickup("coin", e.x, e.y)
	if (p.chain > 0 and randf() < p.chain) or (crit and p.g("crit_chain") > 0):
		chain_from(e, dmg * 0.6)
	var kind := b.kind if b != null else ""
	if p.explode > 0 and e.hp > -999:
		if kind == "flask":
			Vfx.next_col = "#b8e05a"
		explode_at(e.x, e.y, dmg * 0.5 * p.explode, e, 18 + ((8 + 26 * p.splash) if kind == "flask" else 0.0))
	if p.shrapnel > 0 and randf() < p.shrapnel:
		explode_at(e.x, e.y, dmg * 0.6, e, 16, "#e8873a", true)
	if crit and p.g("crit_explode") > 0 and randf() < p.g("crit_explode"):
		explode_at(e.x, e.y, dmg * 0.8, e, 22, "#f2c94c", true)
	if p.storm > 0 and randf() < p.storm:
		lightning(e, dmg)
	if p.g("execute") > 0 and e.hp > 0 and not e.is_boss() and e.hp < e.max_hp * p.g("execute"):
		Fx.float_text(e.x, e.y - 16, "EXECUTE", "red")
		e.hp = 0
		kill_enemy(e, {})
	if not p.procs.is_empty():
		Effects.fire("on_hit", { "enemy": e, "dmg": dmg, "crit": crit })
		if crit:
			Effects.fire("on_crit", { "enemy": e, "dmg": dmg, "crit": true })

static func pbullet_hits(b: PBullet, p: Player) -> void:
	if b.nohit:
		return
	var i := 0
	while i < G.enemies.size():
		if i < _cn:
			var qx := _cx[i] - b.x
			var qy := _cy[i] - b.y
			var qr := _cr[i] + b.r
			if qx * qx + qy * qy >= qr * qr:
				i += 1
				continue
		var e: Enemy = G.enemies[i]
		i += 1
		# Cheap reject first (shots x foes is the hot loop): never closer than the exact test below.
		var dx := e.x - b.x
		var dy := e.y - e.z - b.y
		var reach := e.r + 2.0 + b.r
		if dx * dx + dy * dy >= reach * reach:
			continue
		if e.hp <= 0 or e.spawn_t > 0 or e.hidden or b.hit.has(e.uid):
			continue
		var er := e.r + (2.0 if e.is_boss() else 0.0)
		if TB.dist_xy(e.x, e.y - e.z, b.x, b.y) >= er + b.r:
			continue
		b.hit[e.uid] = true
		var sp := Vector2(b.vx, b.vy).length()
		if sp == 0:
			sp = 1
		var kb := (160.0 if p.weapon["kind"] == "spin" else 70.0) * (p.g("knock") if p.g("knock") > 0 else 1.0)
		var dmg := b.dmg
		if b.back == PBullet.BACK_RETURN and p.back_dmg:
			dmg *= 2
		var crit := damage_enemy(e, dmg, { "kx": b.vx / sp * kb, "ky": b.vy / sp * kb, "force_crit": b.crit })
		on_hit_effects(e, dmg, crit, p, b)
		Fx.burst(b.x, b.y, ["#f4ecd8", "#fffbe0"], 3, 50, 0.2)
		Afx.hit(b.x, b.y, b.tag)
		if b.split > 0 and b.kind != "spark":
			var n := int(b.split)
			var a0 := atan2(b.vy, b.vx)
			for k in n:
				if G.pbullets.size() + G.new_pbullets.size() >= Effects.pbullet_cap():
					_merge_shot(dmg * 0.5)
					continue
				var da := (k - (n - 1) / 2.0) * 0.6 + (0.5 if n == 1 else 0.0)
				var nb := new_pbullet()
				nb.copy_from(b)
				nb.hit = b.hit.duplicate()
				nb.dmg = dmg * 0.5
				nb.r = maxf(b.r * 0.7, 2.0)
				nb.split = 0
				nb.bloom = false
				nb.back = PBullet.BACK_NONE
				nb.kind = "spark" if b.kind in ["boomer", "spin", "disc"] else b.kind
				nb.vx = cos(a0 + da) * sp
				nb.vy = sin(a0 + da) * sp
				nb.life = maxf(b.life, 0.4)
				G.new_pbullets.append(nb)
			b.split = 0
		if b.bloom:
			b.bloom = false
			var a0 := atan2(b.vy, b.vx)
			for da in [-0.5, 0.5]:
				if G.pbullets.size() + G.new_pbullets.size() >= Effects.pbullet_cap():
					_merge_shot(dmg * 0.6)
					continue
				var nb := new_pbullet()
				nb.copy_from(b)
				nb.hit = b.hit.duplicate()
				nb.dmg = dmg * 0.6
				nb.r = b.r * 0.8
				nb.bloom = false
				nb.split = 0
				nb.vx = cos(a0 + da) * sp
				nb.vy = sin(a0 + da) * sp
				G.new_pbullets.append(nb)
		if p.g("pierce_dmg") > 0:
			b.dmg *= 1 + p.g("pierce_dmg")
		if b.pierce > 0:
			b.pierce -= 1
		elif crit and p.crit_pierce:
			pass # Piercing crit: keep flying.
		elif b.ric > 0:
			var t := nearest_enemy(b.x, b.y, 110, b.hit)
			if t != null:
				b.ric -= 1
				var a := TB.ang_to(b, t)
				b.vx = cos(a) * sp
				b.vy = sin(a) * sp
				b.life = maxf(b.life, 0.5)
			else:
				b.life = 0
			break
		else:
			b.life = 0
			break

## Rogues layer: where a shot could possibly touch a foe this tick.
## "hit" marks the room's tiles (16 px) that a foe's reach plus the largest
## shot radius covers; "near" marks 64 px cells with a foe in homing range.
## A shot on an unmarked tile skips the foe loops outright. The marks are
## never tighter than the tests in pbullet_hits and nearest_enemy, so the
## outcome is the same as running those loops.
const NEAR_CELL := 64.0
const NCOLS := 7
const NROWS := 5
const HOMING_RANGE := 120.0
const HOMING_EVERY := 4      # Rogues layer: a homing shot looks for the nearest foe every 4th tick
static var _ghit := PackedByteArray()
static var _gnear := PackedByteArray()

static func _build_foe_grid(rmax: float, want_near: bool) -> void:
	if _ghit.size() != TB.COLS * TB.ROWS:
		_ghit.resize(TB.COLS * TB.ROWS)
		_gnear.resize(NCOLS * NROWS)
	_ghit.fill(0)
	_gnear.fill(0)
	for i in _cn:
		var x := _cx[i]
		var y := _cy[i]
		var rad := _cr[i] + rmax
		var c0 := clampi(floori((x - rad) / TB.TS), 0, TB.COLS - 1)
		var c1 := clampi(floori((x + rad) / TB.TS), 0, TB.COLS - 1)
		var r0 := clampi(floori((y - rad) / TB.TS), 0, TB.ROWS - 1)
		var r1 := clampi(floori((y + rad) / TB.TS), 0, TB.ROWS - 1)
		for r in range(r0, r1 + 1):
			for c in range(c0, c1 + 1):
				_ghit[r * TB.COLS + c] = 1
		if want_near:
			# nearest_enemy first rejects on these same cached positions at range + margin.
			rad = HOMING_RANGE + CACHE_MARGIN
			c0 = clampi(int((x - rad) / NEAR_CELL), 0, NCOLS - 1)
			c1 = clampi(int((x + rad) / NEAR_CELL), 0, NCOLS - 1)
			r0 = clampi(int((y - rad) / NEAR_CELL), 0, NROWS - 1)
			r1 = clampi(int((y + rad) / NEAR_CELL), 0, NROWS - 1)
			for r in range(r0, r1 + 1):
				for c in range(c0, c1 + 1):
					_gnear[r * NCOLS + c] = 1

static func update_pbullets(dt: float) -> void:
	var p := G.player
	var room := G.room
	var list: Array = G.pbullets
	# 04b pre-pass: grow, accelerate, hover, pulse and mines.
	var rmax := 0.0
	var any_homing := false
	var i := 0
	while i < list.size():
		var b: PBullet = list[i]
		i += 1
		if b.grow > 0:
			b.r = minf(b.r + dt * 6 * b.grow, 12.0)
			b.dmg *= 1 + dt * 0.8 * b.grow
		if b.accel > 0:
			var f := pow(b.accel, dt)
			b.vx *= f
			b.vy *= f
		if b.r > rmax:
			rmax = b.r
		if b.homing > 0:
			any_homing = true
		if not b.nohit:
			continue   # only pulse orbs and mines (the kinds that never hit by touch) have more to do here
		if b.kind == "pulse":
			if b.linger > 0 and b.age > b.max_life * 0.25 and not b.hovering:
				b.hovering = true
				b.vx = 0.0
				b.vy = 0.0
				b.life += b.linger
			b.pulse_t -= dt
			if b.pulse_t <= 0:
				b.pulse_t = 0.3
				var rad := 14 + 8 * b.r / 2.5
				for e in G.enemies.duplicate():
					if not e.targetable() or TB.dist(e, b) >= rad + e.r:
						continue
					var crit := damage_enemy(e, b.dmg * 0.5, { "silent": true })
					on_hit_effects(e, b.dmg * 0.5, crit, p, b)
		if b.kind == "mine":
			if b.has_mv:
				var nx := b.x + b.mvx * dt
				var ny := b.y + b.mvy * dt
				if World.solid(room, floori(nx / TB.TS), floori(ny / TB.TS), World.M_BULLET):
					b.has_mv = false
				else:
					b.x = nx
					b.y = ny
					var f := pow(0.0015, dt)
					b.mvx *= f
					b.mvy *= f
					if Vector2(b.mvx, b.mvy).length() < 12:
						b.has_mv = false
			b.arm -= dt
			if b.life < 0.5 and b.arm > -7:
				b.life = maxf(b.life, 0.5)
			if b.arm <= 0:
				var near := false
				for e in G.enemies:
					if e.targetable() and TB.dist(e, b) < 20 + e.r:
						near = true
						break
				if near:
					b.life = 0
					Snd.play("boom")
					G.add_shake(2)
					for e in G.enemies.duplicate():
						if not e.targetable() or TB.dist(e, b) >= 30 + e.r:
							continue
						var crit := damage_enemy(e, b.dmg, { "boom": true })
						on_hit_effects(e, b.dmg, crit, p, b)
					Fx.burst(b.x, b.y, ["#e8873a", "#f2c94c", "#4e4a5e"], 18, 100, 0.4, 2)
					Vfx.blast(b.x, b.y, 30.0)
	# Base update.
	var lens := p.lens
	var lens_max := 0.0
	if lens:
		lens_max = 2.5 * Weapons.wsize(p) * 2.2
		rmax = maxf(rmax + dt * 4, 0.0)   # lens shots swell a little before they are tested
	var use_grid := false
	if GameData.rogues():
		_build_foe_cache()
		_build_foe_grid(rmax, any_homing)
		use_grid = true
	var cn := _cn
	var grid := room.grid
	var ghit := _ghit
	var gnear := _gnear
	var enemies: Array = G.enemies
	var cx := _cx
	var cy := _cy
	var near2 := (HOMING_RANGE + CACHE_MARGIN) * (HOMING_RANGE + CACHE_MARGIN)
	var hom := -1.0       # homing value the three numbers below were worked out for
	var hom_cos := 1.0
	var hom_sin := 0.0
	var hom_tan := 0.0
	i = 0
	while i < list.size():
		var b: PBullet = list[i]
		i += 1
		b.life -= dt
		b.age += dt
		b.rot += dt * 18
		if lens and b.kind != "spark":
			b.r = minf(b.r + dt * 4, lens_max)
			b.dmg += b.dmg * dt * 0.9
		if b.back != PBullet.BACK_NONE:
			if b.back == PBullet.BACK_OUT and b.life < b.max_life * 0.5:
				b.back = PBullet.BACK_RETURN
				b.hit = {}
			if b.back == PBullet.BACK_RETURN:
				var a := atan2(p.y - b.y, p.x - b.x)
				var sp := Vector2(b.vx, b.vy).length()
				b.vx = cos(a) * sp
				b.vy = sin(a) * sp
				b.life = maxf(b.life, 0.02)
				if TB.dist_xy(p.x, p.y, b.x, b.y) < 8:
					b.life = 0
					continue
				b.x += b.vx * dt
				b.y += b.vy * dt
				pbullet_hits(b, p)
				if use_grid and enemies.size() != cn:
					use_grid = false
				continue
		if b.homing > 0:
			if not use_grid or b.homing * dt >= 1.5:
				# The original steering (classic mode, and whenever the foe grid cannot be used).
				var t := nearest_enemy(b.x, b.y, HOMING_RANGE)
				if t != null:
					var cur := atan2(b.vy, b.vx)
					var want := TB.ang_to(b, t)
					var d := TB.wrap_ang(want - cur)
					var turn := clampf(d, -b.homing * dt, b.homing * dt)
					var sp := Vector2(b.vx, b.vy).length()
					var na := cur + turn
					b.vx = cos(na) * sp
					b.vy = sin(na) * sp
			else:
				# Rogues layer: the same steering without the trigonometry, and the
				# search for the nearest foe (a loop over every foe, for every homing
				# shot) is made on every 4th tick of a shot's life. In between the shot
				# keeps steering at the foe it found, from that foe's live position;
				# a foe that dies or hides is dropped at once.
				var bx := b.x
				var by := b.y
				var bd := HOMING_RANGE * HOMING_RANGE
				var tx := 0.0
				var ty := 0.0
				var found := false
				if b.tgt_n > 0:
					b.tgt_n -= 1
					var tg := b.tgt
					if tg != null:
						if tg.hp > 0 and not tg.hidden and tg.spawn_t <= 0:
							tx = tg.x - bx
							ty = tg.y - by
							var td := tx * tx + ty * ty
							if td < bd:
								bd = td
								found = true
						else:
							b.tgt = null
							b.tgt_n = 0
				else:
					b.tgt = null
					b.tgt_n = HOMING_EVERY - 1
					if gnear[clampi(int(by / NEAR_CELL), 0, NROWS - 1) * NCOLS + clampi(int(bx / NEAR_CELL), 0, NCOLS - 1)] != 0:
						for k in cn:
							var qx := cx[k] - bx
							var qy := cy[k] - by
							if qx * qx + qy * qy >= near2:
								continue
							var e: Enemy = enemies[k]
							if e.spawn_t > 0 or e.hidden or e.hp <= 0:
								continue
							var ex := e.x - bx
							var ey := e.y - by
							var ed := ex * ex + ey * ey
							if ed < bd:
								bd = ed
								tx = ex
								ty = ey
								found = true
								b.tgt = e
				if found:
					if b.homing != hom:
						hom = b.homing
						hom_cos = cos(hom * dt)
						hom_sin = sin(hom * dt)
						hom_tan = tan(hom * dt)
					var vx := b.vx
					var vy := b.vy
					var cross := vx * ty - vy * tx
					var dot := vx * tx + vy * ty
					if dot > 0 and absf(cross) <= hom_tan * dot:
						var k2 := sqrt((vx * vx + vy * vy) / bd)
						b.vx = tx * k2
						b.vy = ty * k2
					elif cross >= 0:
						b.vx = vx * hom_cos - vy * hom_sin
						b.vy = vx * hom_sin + vy * hom_cos
					else:
						b.vx = vx * hom_cos + vy * hom_sin
						b.vy = vy * hom_cos - vx * hom_sin
		var nx := b.x + b.vx * dt
		var ny := b.y + b.vy * dt
		var c := floori(nx / TB.TS)
		var r := floori(ny / TB.TS)
		# Inlined World.solid(room, c, r, M_BULLET): anything but floor (or open sky) stops a shot.
		if c < 0 or r < 0 or c >= TB.COLS or r >= TB.ROWS or (grid[r * TB.COLS + c] != World.T_FLOOR and grid[r * TB.COLS + c] != World.T_VOID):
			hit_crate(room, c, r, b.dmg)
			if b.back == PBullet.BACK_OUT:
				b.back = PBullet.BACK_RETURN
				b.hit = {}
			elif b.bounce > 0:
				b.bounce -= 1
				var flipped := false
				if World.solid(room, floori(nx / TB.TS), floori(b.y / TB.TS), World.M_BULLET):
					b.vx = -b.vx
					flipped = true
				if World.solid(room, floori(b.x / TB.TS), floori(ny / TB.TS), World.M_BULLET):
					b.vy = -b.vy
					flipped = true
				if not flipped:
					b.vx = -b.vx
					b.vy = -b.vy
			else:
				b.life = 0
				if p.explode > 0:
					if b.kind == "flask":
						Vfx.next_col = "#b8e05a"
					explode_at(b.x, b.y, b.dmg * 0.6 * p.explode, null, 18 + ((8 + 26 * p.splash) if b.kind == "flask" else 0.0))
				Fx.burst(b.x, b.y, ["#63b84f", "#b8e05a"] if b.kind == "flask" else ["#f4ecd8", "#8b8f9c"], 4, 40, 0.2)
			grid = room.grid
			continue
		b.x = nx
		b.y = ny
		# No foe can reach this tile (c, r are in the room here): skip the foe loop.
		# Not for a shot larger than the grid allowed for, and never once the foe
		# list has changed since the grid was built.
		if use_grid and b.r <= rmax and ghit[r * TB.COLS + c] == 0:
			continue
		pbullet_hits(b, p)
		if use_grid and enemies.size() != cn:
			use_grid = false
	# Compact in place and recycle dead shots.
	list = G.pbullets
	var w := 0
	for k in list.size():
		var b: PBullet = list[k]
		if b.life <= 0:
			recycle(b)
			continue
		list[w] = b
		w += 1
	_cn = -1
	list.resize(w)
	G.pbullets.append_array(G.new_pbullets)
	G.new_pbullets.clear()

# ---------- Area effects ----------
static func lightning(e: Enemy, dmg: float) -> void:
	var p := G.player
	var x := e.x
	var y := e.y
	Fx.hide = Vfx.enabled   # Vfx draws the bolt
	for i in 12:
		Fx.particle(x + TB.rint(-2, 2), y - 60 + i * 5, 0, 0, 0.18, "#ffffff" if i % 2 == 0 else "#6fd3e0", 2)
	Fx.hide = false
	Vfx.strike(x, y)
	Fx.burst(x, y, ["#6fd3e0", "#ffffff"], 10, 70, 0.3)
	if randf() < 0.3:
		Snd.play("beam")
	for o in G.enemies.duplicate():
		if o.hp <= 0:
			continue
		if TB.dist_xy(o.x, o.y, x, y) < 24 + o.r:
			damage_enemy(o, dmg * 1.5 * (1 + p.storm_dmg), { "no_crit": true, "col": "cyan", "silent": true })

static func hit_crate(room: Room, c: int, r: int, dmg: float) -> void:
	if room.tile(c, r) != World.T_CRATE:
		return
	var k := Vector2i(c, r)
	room.crate_hp[k] = room.crate_hp.get(k, 12.0) - dmg
	Fx.burst(c * TB.TS + 8, r * TB.TS + 8, ["#7a5236", "#4b3324"], 3, 40, 0.25)
	if room.crate_hp[k] <= 0:
		room.set_tile(c, r, World.T_FLOOR)
		Fx.burst(c * TB.TS + 8, r * TB.TS + 8, ["#7a5236", "#4b3324", "#e3b08a"], 14, 70, 0.5)
		Snd.play("kill")
		if randf() < 0.35: drop_pickup("coin", c * TB.TS + 8.0, r * TB.TS + 8.0)
		if randf() < 0.05: drop_pickup("heart", c * TB.TS + 8.0, r * TB.TS + 8.0)
		G.dyn_dirty = true

static func chain_from(src: Enemy, dmg: float) -> void:
	var p := G.player
	var hit := { src.uid: true }
	var cur: Enemy = src
	for k in 1 + p.chain_jumps:
		var best: Enemy = null
		var bd := 80.0
		for e in G.enemies:
			if hit.has(e.uid) or not e.targetable():
				continue
			var d := TB.dist(cur, e)
			if d < bd:
				bd = d
				best = e
		if best == null:
			break
		var n := ceili(bd / 6)
		Fx.hide = Vfx.enabled   # Vfx draws the arc
		for i in range(0, n + 1):
			var kk := float(i) / n
			Fx.particle(cur.x + (best.x - cur.x) * kk + TB.rint(-2, 2), cur.y + (best.y - cur.y) * kk + TB.rint(-2, 2),
				0, 0, 0.15, "#6fd3e0" if randf() < 0.5 else "#ffffff")
		Fx.hide = false
		Vfx.arc(cur.x, cur.y, best.x, best.y, k * 3)
		damage_enemy(best, dmg * (1 + p.storm_dmg), { "col": "cyan" })
		hit[best.uid] = true
		cur = best

static func explode_at(x: float, y: float, dmg: float, skip: Enemy, radius: float = 18, col: String = "",
		boom: bool = false, from_bomb: bool = false) -> void:
	Fx.burst(x, y, [col, "#f2c94c", "#fffbe0"] if col != "" else ["#e8873a", "#f2c94c", "#d8443c"],
		8 + roundi(radius / 4), 70 + radius, 0.3)
	Vfx.blast(x, y, radius, col)
	for e in G.enemies.duplicate():
		if e == skip or e.hp <= 0:
			continue
		if TB.dist_xy(e.x, e.y, x, y) >= radius + e.r:
			continue
		damage_enemy(e, dmg, { "no_crit": true, "col": "orange", "silent": true, "boom": boom or from_bomb, "bomb": from_bomb })

# ---------- Pickups ----------
const PICKUP_KINDS := ["coin", "gem", "heart", "potion", "bomb", "key", "armor", "ember",
	"c_fury", "c_smoke", "c_whet", "c_insight"]   # last four: Rogues-layer belt consumables

## Rogues layer: past this many pickups on the floor, new coins go straight
## into your purse (same gold), so long fights with gold-on-hit builds don't
## pile up thousands of coins to simulate and draw (that lagged on iPad).
const COIN_PILE := 60

static func drop_pickup(kind: String, x: float, y: float, t: float = 0.0) -> Pickup:
	var a := randf() * TAU
	var s := 30 + randf() * 50
	if (kind == "coin" or kind == "gem") and G.pickups.size() >= COIN_PILE and GameData.rogues():
		var p := G.player
		p.gold_frac += p.gold_mult * (5 if kind == "gem" else 1)
		var g := floori(p.gold_frac)
		p.gold_frac -= g
		p.gold += g
		G.run_stats["gold"] += g
		Fx.particle(x, y - 3, 0, -20, 0.2, "#f2c94c")
		return null
	var k := Pickup.new()
	k.kind = kind
	k.x = x
	k.y = y
	k.vx = cos(a) * s
	k.vy = sin(a) * s
	k.vz = 60 + randf() * 40
	k.t = t
	G.pickups.append(k)
	return k

static func update_pickups(dt: float) -> void:
	var p := G.player
	var room := G.room
	var rogues := GameData.rogues()
	for k: Pickup in G.pickups:
		k.t += dt
		k.vz -= 300 * dt
		k.z += k.vz * dt
		if k.z < 0:
			k.z = 0.0
			k.vz = -k.vz * 0.4 if absf(k.vz) > 30 else 0.0
		k.vx *= 0.9
		k.vy *= 0.9
		var d := TB.dist(p, k)
		var coinlike := k.kind == "coin" or k.kind == "gem"
		if coinlike and (d < (90 if p.magnet else 40) or not G.locked) and k.t > 0.4:
			var a := atan2(p.y - k.y, p.x - k.x)
			k.vx += cos(a) * 900 * dt
			k.vy += sin(a) * 900 * dt
		if coinlike and not G.locked:
			k.x += k.vx * dt
			k.y += k.vy * dt
		elif rogues and k.vz == 0 and absf(k.vx) + absf(k.vy) < 0.05:
			k.vx = 0.0   # resting: skip the wall test
			k.vy = 0.0
		else:
			World.move_body(room, k, k.vx * dt, k.vy * dt, World.M_WALKER)
		if not (d < 9 and k.t > 0.25):
			continue
		if Consumables.is_kind(k.kind):
			# Rogues layer: belt consumables wait on the floor while the belt is full.
			if Consumables.take(p, k.kind):
				k.dead = true
				Snd.play("relic")
				Fx.float_text(p.x, p.y - 12, Consumables.KINDS[k.kind]["name"], "gold")
			continue
		match k.kind:
			"coin":
				p.gold_frac += p.gold_mult
				var g := floori(p.gold_frac)
				p.gold_frac -= g
				p.gold += g
				G.run_stats["gold"] += g
				k.dead = true
				Snd.play("coin")
				Fx.particle(k.x, k.y - 3, 0, -20, 0.2, "#f2c94c")
			"gem":
				p.gold_frac += 5 * p.gold_mult
				var g := floori(p.gold_frac)
				p.gold_frac -= g
				p.gold += g
				G.run_stats["gold"] += g
				k.dead = true
				Snd.play("coin")
				Fx.float_text(p.x, p.y - 12, "+%d GOLD" % g, "gold")
			"bomb":
				k.dead = true
				p.bombs += 1
				Snd.play("coin")
				Fx.float_text(p.x, p.y - 12, "+BOMB", "white")
			"key":
				k.dead = true
				p.keys += 1
				Snd.play("coin")
				Fx.float_text(p.x, p.y - 12, "+KEY", "gold")
			"armor":
				k.dead = true
				p.armor += 1
				Snd.play("heal")
				Fx.float_text(p.x, p.y - 12, "+ARMOR", "cyan")
			"ember":
				k.dead = true
				p.embers_found += 3
				Snd.play("relic")
				Fx.float_text(p.x, p.y - 12, "+3 EMBERS", "orange")
			"heart":
				if p.hp < p.max_hp:
					k.dead = true
					p.heal(2)
			"potion":
				if p.potions < p.max_potions:
					k.dead = true
					p.potions += 1
					Snd.play("heal")
					Fx.float_text(p.x, p.y - 12, "+POTION", "pink")
	var keep := []
	for k: Pickup in G.pickups:
		if not k.dead:
			keep.append(k)
		elif not p.procs.is_empty():
			Effects.fire("on_pickup", { "x": k.x, "y": k.y, "kind": k.kind })
	G.pickups = keep

# ---------- Bombs ----------
static func update_bombs(dt: float) -> void:
	var fresh := []
	var p := G.player
	var room := G.room
	for b in G.bombs:
		b["t"] -= dt
		if b["t"] > 0:
			continue
		var mini: bool = b.get("mini", false)
		var rad := (20.0 if mini else 32.0) * p.bomb_r
		Snd.play("boom")
		G.add_shake(2 if mini else 5)
		explode_at(b["x"], b["y"], maxf(10.0, Weapons.wdmg(p) * 3) * p.bomb_mult * (0.5 if mini else 1.0), null, rad, "", true, true)
		Fx.burst(b["x"], b["y"], ["#e8873a", "#f2c94c", "#4e4a5e"], 10 if mini else 24, 110, 0.5, 2)
		if not b["safe"] and TB.dist_xy(p.x, p.y, b["x"], b["y"]) < 22:
			hurt_player(1, "your own bomb")
		var c0 := floori((b["x"] - rad) / TB.TS)
		var c1 := floori((b["x"] + rad) / TB.TS)
		var r0 := floori((b["y"] - rad) / TB.TS)
		var r1 := floori((b["y"] + rad) / TB.TS)
		for r in range(r0, r1 + 1):
			for c in range(c0, c1 + 1):
				if room.tile(c, r) == World.T_CRATE:
					hit_crate(room, c, r, 999)
		for d in room.secret_dirs.keys():
			var dc := World.door_center(d)
			if TB.dist_xy(dc.x, dc.y, b["x"], b["y"]) < 44:
				G.open_secret_door(d)
		if p.cap("cluster") and not mini:
			for i in 4:
				var a := i / 4.0 * TAU + 0.4
				fresh.append({ "x": b["x"] + cos(a) * 22, "y": b["y"] + sin(a) * 22, "t": 0.35 + i * 0.05, "safe": true, "mini": true })
	var keep := []
	for b in G.bombs:
		if b["t"] > 0:
			keep.append(b)
	keep.append_array(fresh)
	G.bombs = keep

# ---------- Zones (fire, poison, smoke) ----------
static func update_zones(dt: float) -> void:
	var p := G.player
	for z in G.zones:
		z["t"] -= dt
		z["tick"] -= dt
		match z["kind"]:
			"smoke":
				EBullets.kill_radius(z["x"], z["y"], z["r"])
			"fire", "poison":
				if z["tick"] > 0:
					continue
				z["tick"] = 0.4
				for e in G.enemies.duplicate():
					if not e.targetable() or TB.dist_xy(e.x, e.y, z["x"], z["y"]) >= z["r"] + e.r:
						continue
					if z["kind"] == "fire":
						e.burn_t = maxf(e.burn_t, 2.0 + p.burn_time)
						damage_enemy(e, Weapons.wdmg(p) * 0.3, { "no_crit": true, "col": "orange", "silent": true })
					else:
						e.poison = minf(12, e.poison + 1)
	var keep := []
	for z in G.zones:
		if z["t"] > 0:
			keep.append(z)
	G.zones = keep

# ---------- Familiars (wisps) ----------
static func update_familiars(p: Player, dt: float) -> void:
	var fam: Array = G.familiars
	while fam.size() < p.familiars:
		fam.append({ "x": p.x, "y": p.y, "cd": randf() })
	for f in G.temp_fams:
		f["t"] -= dt
	var keep := []
	for f in G.temp_fams:
		if f["t"] > 0:
			keep.append(f)
	G.temp_fams = keep
	var all: Array = fam.slice(0, mini(p.familiars, Effects.SUMMON_CAP)) + G.temp_fams
	for i in all.size():
		var f: Dictionary = all[i]
		var a := G.time * 1.6 + i * TAU / maxi(1, all.size())
		var rad := 26.0 if f.has("t") else 16.0
		var tx := p.x + cos(a) * rad
		var ty := p.y - 12 + sin(a) * 7
		f["x"] += (tx - f["x"]) * minf(1.0, dt * 6)
		f["y"] += (ty - f["y"]) * minf(1.0, dt * 6)
		f["cd"] -= dt
		if not (f["cd"] <= 0 and G.enemies_active()):
			continue
		var t := nearest_enemy(f["x"], f["y"], 220)
		if t == null:
			continue
		f["cd"] = 0.7 / p.fam_rate
		var a2 := TB.ang_xy(f["x"], f["y"], t.x, t.y)
		for k in p.fam_multi:
			var aa := a2 + (k - (p.fam_multi - 1) / 2.0) * 0.18
			_raw_shot(f["x"], f["y"], aa, 220, maxf(2.0, Weapons.wdmg(p) * 0.45) * (1 + p.fam_dmg), 0.9, 2.0, 0, "spark", {}, 3.0)

# ---------- The player's combat turn (update_player, merged) ----------
static func update_player(p: Player, dt: float) -> void:
	var rolling_before := p.dodge_t > 0
	# Gatling spin-up while there is something to shoot.
	if p.weapon["kind"] == "gatling":
		p.spin = minf(1.0, p.spin + dt * 0.5) if G.enemies_active() else maxf(0.0, p.spin - dt)
	var hasted := p.haste_t > 0
	p.haste_t = maxf(0.0, p.haste_t - dt)
	if hasted:
		p.speed *= 1.3
	var bogged := Hazards.in_pool(p)   # stage 7 mire pools (never on original floors)
	if bogged:
		p.speed *= 0.6
	_update_player_base(p, dt)
	if bogged:
		p.speed /= 0.6
	if hasted:
		p.speed /= 1.3
	if not rolling_before and p.dodge_t > 0:
		var n := int(p.g("roll_nova"))
		for i in n:
			spawn_pbullet(p, i * TAU / n, Weapons.wdmg(p) * 0.8, "spark")
		if p.g("roll_zap") > 0:
			var t := auto_target(p, 220)
			if t != null:
				lightning(t, Weapons.wdmg(p) * 1.5)
		p.ambush_left += int(p.g("roll_ambush"))
	if p.moving and (p.g("fire_steps") > 0 or p.g("toxic_steps") > 0):
		p.step_t -= dt
		if p.step_t <= 0:
			p.step_t = 0.18
			if p.g("fire_steps") > 0:
				G.zones.append({ "x": p.x, "y": p.y + 3, "r": 9, "t": 1.4, "kind": "fire", "tick": 0.0 })
			if p.g("toxic_steps") > 0:
				G.zones.append({ "x": p.x, "y": p.y + 3, "r": 11, "t": 2.2, "kind": "poison", "tick": 0.0 })
	for e in G.enemies:
		if e.mark_t > 0:
			e.mark_t -= dt
	if p.tempo_max > 0:
		Tempo.update(p, dt)
	if p.rally_n > 0:
		Rally.update(p, dt)

## Called by Player.start_roll: the combat side effects of starting a roll.
static func on_roll_start(p: Player) -> void:
	if p.smoke:
		G.zones.append({ "x": p.x, "y": p.y, "r": 24, "t": 2.5, "kind": "smoke", "tick": 0.0 })
	if p.bomb_dodge or p.g("roll_bomb") > 0:
		G.bombs.append({ "x": p.x, "y": p.y, "t": 0.7, "safe": true })
	if not p.procs.is_empty():
		Effects.fire("on_roll", { "x": p.x, "y": p.y })

## Called by Player.update_move each tick while rolling.
static func while_rolling(p: Player, dt: float) -> void:
	if p.fire_trail > 0:
		p.trail_t -= dt
		if p.trail_t <= 0:
			p.trail_t = 0.05
			G.zones.append({ "x": p.x, "y": p.y + 2, "r": 9, "t": 1.0 + 0.6 * p.fire_trail, "kind": "fire", "tick": 0.0 })
	if p.g("roll_expose") > 0:
		# The Gaolbird: a roll through a foe leaves it exposed (+25% damage taken) and
		# sets up a crit; in full flight the roll also cuts it for 250%.
		var cut := p.g("flight") > 0
		for e in G.enemies.duplicate():
			if not e.targetable() or p.expose_hit.has(e.uid) or TB.dist(e, p) >= e.r + 10:
				continue
			p.expose_hit[e.uid] = true
			Statuses.apply(e, "vulnerable", 1, Weapons.wdmg(p))
			p.ambush_left = maxi(p.ambush_left, 1)
			Juice.exposed(e.x, e.y - e.r)
			if e.type != "dummy" and p.tempo_max > 0:
				Tempo.on_hit(p)
			if cut:
				damage_enemy(e, Weapons.wdmg(p) * 2.5, { "col": "pink" })
	if p.shadowstep:
		for e in G.enemies.duplicate():
			if not e.targetable() or p.step_hit.has(e.uid):
				continue
			if TB.dist(e, p) >= e.r + 10:
				continue
			p.step_hit[e.uid] = true
			var dmg := Weapons.wdmg(p) * (5.0 if p.cap("nightfall") else 2.5) + p.bash * maxi(p.armor, 5) * Weapons.wdmg(p) * 0.6
			damage_enemy(e, dmg, { "col": "purple" })
			if p.cap("nightfall") and e.hp <= 0:
				p.charges = mini(p.charges + 1, p.dodge_charges)
			Fx.burst(e.x, e.y, ["#a35bd6", "#5c3483"], 8, 50)
			Vfx.puff(e.x, e.y, "void")

static func _update_player_base(p: Player, dt: float) -> void:
	var raging := p.blood_rage and p.hp <= p.max_hp / 2
	p.update_move(dt)
	var manual = Keys.aim()
	var aim = null
	if manual != null:
		aim = manual
	elif Meta.opts["autofire"] or Keys.fire_held():
		var t := auto_target(p, 320)
		if t != null:
			aim = TB.ang_xy(p.x, p.y, t.x, t.y - 2)
	if aim != null:
		p.aim_a = aim
		if manual != null:
			if p.dodge_t <= 0:
				p.face = 1 if cos(aim) >= 0 else -1
		elif absf(cos(aim)) > 0.2 and p.dodge_t <= 0 and not p.moving:
			p.face = 1 if cos(aim) > 0 else -1
	p.fire_cd -= dt
	var rate := Weapons.wrate(p) * (1.45 if p.frenzy_t > 0 else 1.0) * (1.4 if raging else 1.0)
	if aim != null and p.fire_cd <= 0 and p.dodge_t <= 0 and (G.enemies_active() or G.dummies_present()):
		p.fire_cd = maxf(1.0 / rate, Effects.MIN_SHOT_INTERVAL)
		player_shoot(p, aim)
		if p.triple > 0 and randf() < p.triple:
			p.volleys.append({ "t": 0.07 })
			p.volleys.append({ "t": 0.14 })
	var i := 0
	while i < p.volleys.size():
		var v: Dictionary = p.volleys[i]
		v["t"] -= dt
		if v["t"] <= 0:
			if v.get("raw", false):
				var burst := fire_projectiles(p, p.aim_a)
				if p.tempo_max > 0 or p.rally_n > 0:
					for b in burst:
						b.own = true
			else:
				player_shoot(p, p.aim_a)
		i += 1
	var keep := []
	for v in p.volleys:
		if v["t"] > 0:
			keep.append(v)
	p.volleys = keep
	p.try_heal()
	Abilities.update(p, dt)
	if GameData.rogues():
		var bi := Keys.belt()
		if bi >= 0:
			Consumables.use(p, bi)
	if Keys.bomb():
		if p.bombs > 0:
			p.bombs -= 1
			G.bombs.append({ "x": p.x, "y": p.y + 2, "t": 0.7 if p.fuse else 1.1, "safe": p.fuse or p.g("bomb_immune") > 0 })
			Snd.play("place")
		else:
			Snd.play("deny")
	p.orbit_a += dt * 3.2
	for k in p.orbit_hit.keys():
		p.orbit_hit[k] -= dt
		if p.orbit_hit[k] <= 0:
			p.orbit_hit.erase(k)
	# Ember Heart aura.
	if p.aura > 0 or p.g("fire_aura") > 0:
		p.aura_t -= dt
		if p.aura_t <= 0:
			p.aura_t = 0.5
			for e in G.enemies:
				if e.targetable() and TB.dist(e, p) < 38 + 10 * maxi(p.aura, 1):
					e.burn_t = maxf(e.burn_t, 1.6)
	# Static Coil.
	if p.coil > 0 and G.enemies_active():
		p.coil_t -= dt
		if p.coil_t <= 0:
			p.coil_t = 4.0
			var n := 10 * p.coil
			for k in n:
				spawn_pbullet(p, float(k) / n * TAU, Weapons.wdmg(p) * 0.8, "spark")
			Snd.play("ebullet")
	if p.cap("tempest") and G.enemies_active():
		p.tempest_t -= dt
		if p.tempest_t <= 0:
			p.tempest_t = 3.0
			for e in _nearest_targets(p, 3):
				lightning(e, Weapons.wdmg(p) * 1.2)
	update_familiars(p, dt)
