extends Node
## Ability effects (scripts/render/vfx.gd). Run: godot --headless --path . res://tests/vfx_test.tscn -- --no-save
##   1. Art: every strip exists and divides into whole frames; every colour has its blasts.
##   2. Drawing only: the same seeded fight, effects on and off, ends in the same state,
##      with the same random numbers used and the same particles simulated.
##   3. Hidden particles: the ones an effect replaces are simulated but flagged, the flag
##      follows its particle, and nothing is hidden with the option off.
##   4. Bounded: a flood of every effect never grows a list past its cap.
##   5. Everything ends: with no new effects, every list empties.
##   6. Lightning: the channel is pinned to both ends, stays near the line, forks in pairs.
##   7. A new room starts clean; the option takes effect at once.
##   8. The painters draw every effect without an error.
## Prints "vfx test: PASSED" or a FAIL line per problem.

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL vfx: ", msg)

func _arena() -> Player:
	G.god = true
	G.hero_index = 0
	G.new_run()
	G.floor_d["depth"] = 2
	G.enter_room(World.make_room(G.floor_d, "combat", "", "s"))
	G.room.waves_left = 0
	G.state = &"play"
	G.hitstop = 0.0
	var p := G.player
	p.x = 14.0 * TB.TS
	p.y = 9.5 * TB.TS
	for c in range(4, 25):
		for r in range(6, 13):
			G.room.set_tile(c, r, World.T_FLOOR)
	Keys.tick()
	return p

func _foe(x: float, y: float, hp: float = 100000.0) -> Enemy:
	var e := Combat.spawn_enemy("skeleton", x, y, false, true)
	e.x = x
	e.y = y
	e.max_hp = hp
	e.hp = hp
	return e

func _fancy(on: bool) -> void:
	Meta.opts["vfx"] = on
	Vfx.reset()

func _ready() -> void:
	await get_tree().process_frame
	art()
	drawing_only()
	hidden_particles()
	bounded()
	everything_ends()
	lightning()
	rooms_and_option()
	await painters()
	_fancy(true)
	print("vfx test: PASSED" if fails == 0 else "vfx test: %d FAILED" % fails)
	get_tree().quit(1 if fails > 0 else 0)

# ---------- 1 ----------
func art() -> void:
	for ramp in Vfx.RAMP_HEX:
		for size in ["s", "m"]:
			if not Img.has("fx_blast_%s_%s" % [size, ramp]):
				fail("no blast %s for %s" % [size, ramp])
	for ramp in Vfx.HAS_LARGE:
		if not Img.has("fx_blast_l_" + ramp):
			fail("no large blast for " + ramp)
	for v in Vfx.RAMP.values():
		if not Vfx.RAMP_HEX.has(v):
			fail("colour maps to an unknown ramp " + v)
	var names := ["fx_flame", "fx_flame_s", "fx_smoke", "fx_zap", "fx_shatter", "fx_bubble", "fx_star", "fx_frost",
		"fx_plus", "fx_skull", "fx_mark", "fx_weak", "fx_rock", "fx_scorch", "fx_pool", "glow_white",
		"fx_blast_s_fire", "fx_blast_m_fire", "fx_blast_l_fire"]
	for n in names:
		if not Img.has(n):
			fail("missing graphic " + n)
			continue
		var s := Vfx._strip(n)
		var tex: Texture2D = s[0]
		if s[1] * s[3] != tex.get_width():
			fail("%s: %d px does not divide into %d frames" % [n, tex.get_width(), s[3]])
	if Vfx.FLAME_SPOTS.size() != 5:
		fail("flame layouts")
	for i in Vfx.FLAME_SPOTS.size():
		var spots: Array = Vfx.FLAME_SPOTS[i]
		if spots.size() != i + 1:
			fail("flame layout %d has %d spots" % [i + 1, spots.size()])
		for k in range(1, spots.size()):
			if spots[k].y < spots[k - 1].y:
				fail("flame layout %d is not back to front" % (i + 1))

# ---------- 2 ----------
var _foes: Array = []

## Puts the arena back to one fixed state, so a probe runs from the same place both times.
func _restore(p: Player) -> void:
	for i in _foes.size():
		var e: Enemy = _foes[i]
		e.x = p.x - 80.0 + i * 32.0
		e.y = p.y - 40.0 + (i % 2) * 20.0
		e.hp = 100000.0
		e.max_hp = 100000.0
		e.kx = 0.0
		e.ky = 0.0
		e.burn_t = 0.0
		e.burn_tick = 0.0
		e.poison = 0.0
		e.chill_t = 0.0
		e.bleed_t = 0.0
		e.stun_t = 0.0
		e.curse_t = 0.0
		e.mark_t = 0.0
		e.shock = 0
		e.shock_t = 0.0
		e.vuln_t = 0.0
		e.weak_t = 0.0
		e.shattered = false
		e.flash = 0.0
	# Foes a probe made for itself are gone, and the sound throttle (which decides whether
	# a sound rolls its pitch) starts empty: both runs of a probe happen within one tick.
	G.enemies = G.enemies.filter(func(o): return o in _foes)
	Snd._last.clear()
	G.zones.clear()
	G.bombs.clear()
	G.swings.clear()
	for b in G.pbullets:
		Combat.recycle(b)
	G.pbullets.clear()
	G.new_pbullets.clear()
	G.pickups.clear()
	p.hp = 3
	p.invuln = 0.0
	p.fire_cd = 0.0
	Fx.clear()
	Juice.reset()

func _snapshot(p: Player) -> String:
	var out := [str(randi()), str(randf()), str(Fx.n), str(p.hp), str(p.invuln), str(G.zones.size()), str(G.bombs.size()),
		str(G.pbullets.size() + G.new_pbullets.size()), str(G.pickups.size()), str(G.enemies.size())]
	for e: Enemy in _foes:
		out.append("%.4f %.4f %.4f %.3f %.3f %.3f %.3f %.3f %.3f %d %.3f %.3f %.3f %.2f %.2f" % [e.x, e.y, e.hp, e.burn_t,
			e.chill_t, e.poison, e.stun_t, e.curse_t, e.mark_t, e.shock, e.shock_t, e.vuln_t, e.weak_t, e.kx, e.ky])
	for i in Fx.n:
		out.append("%.3f %.3f %.3f %.3f" % [Fx.px[i], Fx.py[i], Fx.plife[i], Fx.pvx[i]])
	return "\n".join(out)

## Runs one piece of the rules twice from the same state and the same seed, effects
## on and off. Everything the rules can see must come out the same: what happened
## to the foes and the hero, how many random numbers were used, and every particle
## (place, speed and lifetime; only whether it is drawn may differ).
## Effects alive right now, of either module.
func _made() -> int:
	return Vfx.anims.size() + Vfx.bolts.size() + Vfx.glows.size() + Vfx.swirls.size() + Vfx.falls.size() + Afx.live()

func _probe(p: Player, what: String, f: Callable, expect_effect: bool = true) -> void:
	var seen := []
	var made := 0
	for on in [true, false]:
		_fancy(on)
		_restore(p)
		seed(31337)
		f.call()
		if on:
			made = _made()
		elif _made() > 0:
			fail(what + ": made an effect with the option off")
		seen.append(_snapshot(p))
		if Fx.hide:
			fail(what + ": left Fx.hide set")
			Fx.hide = false
	if seen[0] != seen[1]:
		var a: PackedStringArray = seen[0].split("\n")
		var b: PackedStringArray = seen[1].split("\n")
		var at := 0
		while at < mini(a.size(), b.size()) and a[at] == b[at]:
			at += 1
		fail("%s: the effect changed the game (line %d: %s vs %s)" % [what, at,
			a[at] if at < a.size() else "-", b[at] if at < b.size() else "-"])
	if expect_effect and made == 0:
		fail(what + ": no effect was made")

func drawing_only() -> void:
	var p := _arena()
	_foes.clear()
	for i in 6:
		_foes.append(_foe(0.0, 0.0))
	var e: Enemy = _foes[2]
	_probe(p, "lightning", func(): Combat.lightning(e, 1.0))
	_probe(p, "chain", func(): Combat.chain_from(e, 1.0))
	for r in [12.0, 18.0, 26.0, 34.0, 46.0, 72.0]:
		for col in ["", "#e8873a", "#b8e05a", "#f2c94c"]:
			_probe(p, "blast %d %s" % [r, col], func(): Combat.explode_at(e.x, e.y, 1.0, null, r, col, true))
	_probe(p, "blast on the hero", func(): Combat.explode_at(p.x, p.y, 1.0, null, 72.0, "#e8873a", true))
	_probe(p, "meteor", func(): Actions.run(["meteor", 0.5, 34], 1, {}))
	_probe(p, "pull", func(): Actions.run(["pull", 110, 60], 1, { "x": e.x, "y": e.y }))
	_probe(p, "push", func(): Actions.run(["push", 90, 60], 1, {}))
	_probe(p, "storm", func(): Actions.run(["bolts", 4, 0.5], 1, {}))
	_probe(p, "explode action", func(): Actions.run(["explode", 46, 1.0], 1, { "enemy": e }))
	_probe(p, "hurt self", func(): Actions.run(["hurt_self", 1], 1, {}))
	for st in Effects.STATUSES:
		_probe(p, "status " + st, func(): Statuses.apply(e, st, 1.0, 1.0), st in ["burn", "chill", "curse", "poison"])
	_probe(p, "heal", func():
		p.hp = 1
		p.heal(2))
	_probe(p, "chilling hit", func():
		var was := p.chill
		p.chill = 1.0
		Combat.on_hit_effects(e, 1.0, false, p, null)
		p.chill = was)
	_probe(p, "exploding hit", func():
		var was := p.explode
		p.explode = 1.0
		Combat.on_hit_effects(e, 1.0, false, p, null)
		p.explode = was, false)   # an 18 px blast is the small plain kind: an animation, checked below
	_probe(p, "bomb", func():
		G.bombs.append({ "x": e.x, "y": e.y, "t": 0.0, "safe": true })
		Combat.update_bombs(TB.DT))
	_probe(p, "ice armour", func():
		var god := G.god
		G.god = false
		p.ice_armor = true
		Combat.hurt_player(1, "a test")
		p.ice_armor = false
		G.god = god)
	_probe(p, "shattering kill", func():
		var v := _foe(p.x + 50.0, p.y + 30.0, 5.0)
		v.shattered = true
		Combat.damage_enemy(v, 50.0, { "no_crit": true, "no_mult": true, "silent": true }))
	# The lightning rune's own attack: arcs from the hero along the chain.
	var rune: Dictionary = Weapons.by_id("sparkrune")
	Weapons.equip_weapon(p, rune)
	_probe(p, "rune arcs", func(): Combat.attack_zap(p, 0.0, false))
	# A blast of each size really is the picture it should be.
	_fancy(true)
	_restore(p)
	for row in [[12.0, 24], [26.0, 48], [34.0, 80]]:
		Vfx.reset()
		Vfx.blast(e.x, e.y, row[0], "#e8873a")
		if Vfx.anims.is_empty() or Vfx.anims[0].w != row[1]:
			fail("a blast of reach %d is not the %d px picture" % [row[0], row[1]])
	for dead in G.enemies:
		dead.hp = 0
	G.enemies.clear()
	_foes.clear()

# ---------- 3 ----------
func hidden_particles() -> void:
	seed(7)
	var p := _arena()
	var e := _foe(p.x + 40.0, p.y)
	_fancy(true)
	Fx.clear()
	Combat.lightning(e, 1.0)
	var hidden := 0
	for i in Fx.n:
		hidden += Fx.phide[i]
	if hidden != 12:
		fail("a strike hid %d particles, want its 12" % hidden)
	if Fx.n <= 12:
		fail("a strike's sparks are gone too")
	if Fx.hide:
		fail("Fx.hide was left set")
	# The flag follows its particle through the tidy-up (short-lived visible ones die first).
	Fx.clear()
	Fx.particle(1, 1, 0, 0, 0.05, "#ffffff")
	Fx.hide = true
	Fx.particle(2, 2, 0, 0, 1.0, "#ff0000")
	Fx.hide = false
	Fx.particle(3, 3, 0, 0, 0.05, "#ffffff")
	Fx.particle(4, 4, 0, 0, 1.0, "#00ff00")
	for k in 6:
		Fx.update(TB.DT)
	if Fx.n != 2 or Fx.phide[0] != 1 or Fx.phide[1] != 0 or absf(Fx.px[0] - 2.0) > 0.01 or absf(Fx.px[1] - 4.0) > 0.01:
		fail("the hidden flag did not stay with its particle")
	# A reused slot is visible again.
	Fx.clear()
	Fx.particle(5, 5, 0, 0, 1.0, "#ffffff")
	if Fx.phide[0] != 0:
		fail("a reused slot stayed hidden")
	# The oldest are dropped past the cap: flags move down with them.
	Fx.clear()
	Fx.hide = true
	for i in 10:
		Fx.particle(i, 0, 0, 0, 5.0, "#ffffff")
	Fx.hide = false
	for i in Fx.LIVE_MAX:
		Fx.particle(100 + i, 0, 0, 0, 5.0, "#ffffff")
	Fx.update(TB.DT)
	var left := 0
	for i in Fx.n:
		left += Fx.phide[i]
	if Fx.n != Fx.LIVE_MAX or left != 0:
		fail("after dropping the oldest: %d alive, %d hidden" % [Fx.n, left])
	# A stunned foe's flickering star is replaced by the orbiting ones.
	e.stun_t = 5.0
	Fx.clear()
	for k in 30:
		Combat.update_enemies(TB.DT)
		Fx.update(TB.DT)
		for i in Fx.n:
			if Fx.plife[i] <= 0.05 and Fx.phide[i] == 0 and absf(Fx.py[i] - (e.y - e.r - 6)) < 0.5:
				fail("a stunned foe's old star is still drawn")
	if Fx.hide:
		fail("Fx.hide was left set by a stunned foe")
	e.stun_t = 0.0
	# Off: nothing is hidden.
	_fancy(false)
	Fx.clear()
	Combat.lightning(e, 1.0)
	Combat.chain_from(e, 1.0)
	for i in Fx.n:
		if Fx.phide[i] != 0:
			fail("a particle was hidden with the option off")
			break
	Fx.clear()

# ---------- 4 ----------
func _caps(where: String) -> void:
	if Vfx.anims.size() > Vfx.ANIM_MAX: fail("%s: %d animations" % [where, Vfx.anims.size()])
	if Vfx.bolts.size() > Vfx.BOLT_MAX: fail("%s: %d bolts" % [where, Vfx.bolts.size()])
	if Vfx.decals.size() > Vfx.DECAL_MAX: fail("%s: %d scorch marks" % [where, Vfx.decals.size()])
	if Vfx.glows.size() > Vfx.GLOW_MAX: fail("%s: %d glows" % [where, Vfx.glows.size()])
	if Vfx.swirls.size() > 6: fail("%s: %d swirls" % [where, Vfx.swirls.size()])
	if Vfx.falls.size() > 6: fail("%s: %d meteors" % [where, Vfx.falls.size()])
	if Vfx._later.size() > 16: fail("%s: %d waiting spark bursts" % [where, Vfx._later.size()])
	if Juice.spark_n > Juice.SPARK_CAP: fail("%s: %d sparks" % [where, Juice.spark_n])
	var crackles := 0
	for b in Vfx.bolts:
		if b.kind == 2:
			crackles += 1
	if crackles > Vfx.CRACKLE_MAX: fail("%s: %d crackles" % [where, crackles])

func bounded() -> void:
	seed(9)
	var p := _arena()
	_fancy(true)
	for i in 30:
		var e := _foe(60.0 + (i % 10) * 34.0, 110.0 + (i / 10) * 30.0)
		e.shock = 5
		e.shock_t = 100.0
		e.burn_t = 100.0
		e.poison = 12.0
		e.chill_t = 100.0
		e.stun_t = 100.0
		e.curse_t = 100.0
		e.weak_t = 100.0
		e.mark_t = 100.0
	for tick in 90:
		for k in 40:
			var x := 40.0 + (k * 37 + tick * 11) % 360
			var y := 50.0 + (k * 23 + tick * 7) % 200
			Vfx.blast(x, y, 10.0 + (k * 9) % 80, ["", "#b8e05a", "#f2c94c", "#6fd3e0", "#a35bd6"][k % 5])
			Vfx.strike(x, y)
			Vfx.arc(x, y, y, x, k % 4)
			Vfx.puff(x, y, "frost")
			Vfx.meteor(x, y)
			Vfx.shatter(x, y)
			Vfx.heal(x, y)
			Vfx.swirl(x, y, 80.0, k % 2 == 0, "#a35bd6")
			Vfx.nova(x, y, 90.0, "frost")
		_caps("in the flood, before the tick")
		Juice.update(TB.DT, p)
		_caps("in the flood")
	if Vfx.anims.is_empty() or Vfx.bolts.is_empty():
		fail("the flood left nothing alive")
	# A blast on the hero is only a ring around them; one elsewhere has its fireball in the middle.
	Vfx.reset()
	Vfx.blast(p.x, p.y, 72.0, "#e8873a")
	for a in Vfx.anims:
		if absf(a.x - p.x) < 12.0 and absf(a.y - p.y) < 12.0 and a.w > 24:
			fail("a big blast on the hero covers them")
	Vfx.reset()
	Vfx.blast(p.x + 120.0, p.y, 46.0, "#e8873a")
	var centre := false
	for a in Vfx.anims:
		if absf(a.x - p.x - 120.0) < 2.0 and a.w == 80:
			centre = true
	if not centre:
		fail("a big blast away from the hero has no fireball")
	for e in G.enemies:
		e.hp = 0
	G.enemies.clear()

# ---------- 5 ----------
func everything_ends() -> void:
	var p := _arena()
	_fancy(true)
	Vfx.blast(p.x + 60.0, p.y, 60.0)
	Vfx.strike(p.x - 60.0, p.y)
	Vfx.arc(p.x, p.y, p.x + 50.0, p.y + 20.0, 3)
	Vfx.meteor(p.x + 30.0, p.y + 30.0)
	Vfx.blast(p.x + 30.0, p.y + 30.0, 34.0)
	Vfx.swirl(p.x, p.y, 80.0, true, "#a35bd6")
	Vfx.heal(p.x, p.y)
	Vfx.shatter(p.x, p.y)
	if Vfx.decals.is_empty():
		fail("a blast on open floor left no scorch mark")
	var longest := 0
	for tick in 400:
		Vfx.update(TB.DT)
		if not (Vfx.anims.is_empty() and Vfx.bolts.is_empty() and Vfx.glows.is_empty() and Vfx.swirls.is_empty()
				and Vfx.falls.is_empty() and Vfx._later.is_empty()):
			longest = tick
	if longest > 60:
		fail("an effect was still running after %d ticks" % longest)
	if not Vfx.decals.is_empty():
		fail("a scorch mark never faded")
	# A wall, a pillar or a crate is never scorched.
	G.room.set_tile(5, 5, World.T_PILLAR)
	Vfx.blast(5.5 * TB.TS, 5.5 * TB.TS - 2.0, 40.0)
	if not Vfx.decals.is_empty():
		fail("a pillar was scorched")
	Vfx.reset()

# ---------- 6 ----------
func lightning() -> void:
	_fancy(true)
	Vfx._rng.seed = 5
	for trial in 60:
		var a := Vector2(40.0 + trial * 5, -10.0)
		var b := Vector2(200.0 + (trial * 13) % 90, 90.0 + (trial * 7) % 150)
		var bolt := Vfx.Bolt.new()
		bolt.a = a
		bolt.b = b
		bolt.kind = trial % 2
		bolt.amp = 4.4 if bolt.kind == 0 else 3.5
		for pass_n in 2:
			Vfx._forge(bolt, pass_n == 0)
			var m := bolt.main
			if m.size() < 3:
				fail("a channel of %d points" % m.size())
				continue
			if m[0].distance_to(a) > 1.0 or m[m.size() - 1].distance_to(b) > 1.0:
				fail("the channel is not pinned to its ends")
			var d := (b - a).normalized()
			var worst := 0.0
			for q in m:
				if not (is_finite(q.x) and is_finite(q.y)):
					fail("a point is not finite")
				worst = maxf(worst, absf((q - a).cross(d)))
			if worst > 40.0:
				fail("the channel strayed %.0f px from the line" % worst)
			if bolt.twigs.size() % 2 != 0 or bolt.dash.size() % 2 != 0 or bolt.dash.size() < 2:
				fail("forks or dashes are not point pairs")
			if bolt.kind == 0 and bolt.twigs.size() < 4:
				fail("a strike without forks")
	# A zero-length arc (a foe jumping to itself) must not blow up.
	Vfx.reset()
	Vfx.arc(100.0, 100.0, 100.0, 100.0)
	for tick in 20:
		Vfx.update(TB.DT)
	if not Vfx.bolts.is_empty():
		fail("a zero-length arc never ended")

# ---------- 7 ----------
func rooms_and_option() -> void:
	var p := _arena()
	_fancy(true)
	Vfx.blast(p.x + 60.0, p.y, 60.0)
	Vfx.strike(p.x - 60.0, p.y)
	G.enter_room(World.make_room(G.floor_d, "combat", "", "s"))
	if not (Vfx.anims.is_empty() and Vfx.bolts.is_empty() and Vfx.decals.is_empty() and Vfx.glows.is_empty()):
		fail("effects came along into the next room")
	# The Options row exists and flips the switch at once.
	var row := -1
	for i in G.OPTION_LIST.size():
		if G.OPTION_LIST[i][1] == "vfx":
			row = i
	if row < 0:
		fail("no FANCY EFFECTS row in Options")
	if not Meta.opts.has("vfx"):
		fail("no saved default for the option")
	var last_y: int = MenuView.OPT_Y0 + (G.OPTION_LIST.size() - 1) * MenuView.OPT_DY
	if last_y + MenuView.OPT_DY > TB.SH - 8:
		fail("the Options list runs off the screen (last row at %d)" % last_y)
	_fancy(false)
	Vfx.blast(p.x + 60.0, p.y, 60.0)
	Vfx.strike(p.x, p.y)
	Vfx.arc(0, 0, 50, 50)
	Vfx.meteor(p.x, p.y)
	Vfx.heal(p.x, p.y)
	Vfx.swirl(p.x, p.y, 50.0, true, "#ffffff")
	Vfx.shatter(p.x, p.y)
	Vfx.puff(p.x, p.y, "fire")
	Vfx.nova(p.x, p.y, 90.0, "frost")
	if not (Vfx.anims.is_empty() and Vfx.bolts.is_empty() and Vfx.decals.is_empty() and Vfx.glows.is_empty()
			and Vfx.swirls.is_empty() and Vfx.falls.is_empty() and Vfx.next_delay == 0.0):
		fail("an effect was made with the option off")
	_fancy(true)

# ---------- 8 ----------
var _painted := 0

func painters() -> void:
	var p := _arena()
	_fancy(true)
	for i in 10:
		var e := _foe(80.0 + i * 30.0, 120.0 + (i % 3) * 30.0)
		e.r = 4.0 + i * 1.2
		e.shock = 3
		e.shock_t = 100.0
		e.burn_t = 100.0
		e.poison = 12.0
		e.chill_t = 100.0
		e.stun_t = 100.0
		e.curse_t = 100.0
		e.weak_t = 100.0
		e.mark_t = 100.0
	for k in 5:
		G.zones.append({ "x": 100.0 + k * 50.0, "y": 200.0, "r": 6.0 + k * 8.0, "t": 0.2 + k, "kind": "fire", "tick": 9.0 })
		G.zones.append({ "x": 100.0 + k * 50.0, "y": 90.0, "r": 6 + k * 8, "t": 0.2 + k, "kind": "poison", "tick": 9.0 })
	G.zones.append({ "x": p.x, "y": p.y, "r": 24, "t": 2.5, "kind": "smoke", "tick": 0.0 })
	var layer := DrawLayer.new(func(ci):
		Vfx.draw_floor(ci, G.time)
		Vfx.draw_ground(ci, G.time)
		Vfx.draw_over(ci, G.time)
		Vfx.draw_glow(ci)
		_painted += 1)
	add_child(layer)
	# Every moment of every effect's life is drawn at least once.
	for tick in 40:
		if tick % 20 == 0:
			Vfx.blast(p.x + 70.0, p.y, 70.0, "#f2c94c")
			Vfx.blast(p.x, p.y, 70.0)
			Vfx.blast(p.x - 70.0, p.y, 10.0, "#6fd3e0")
			Vfx.strike(p.x - 60.0, p.y)
			Vfx.arc(p.x, p.y, p.x + 50.0, p.y + 20.0, 2)
			Vfx.meteor(p.x + 30.0, p.y + 30.0)
			Vfx.blast(p.x + 30.0, p.y + 30.0, 34.0)
			Vfx.swirl(p.x, p.y, 80.0, true, "#a35bd6")
			Vfx.swirl(p.x, p.y, 80.0, false, "#f4ecd8")
			Vfx.heal(p.x, p.y)
			Vfx.shatter(p.x, p.y)
			Vfx.nova(p.x, p.y, 90.0, "frost")
		G.time += TB.DT
		Juice.update(TB.DT, p)
		layer.queue_redraw()
		await get_tree().process_frame
	if _painted == 0:
		print("[vfx] this run does not draw (headless without a canvas): painters not exercised")
	else:
		print("[vfx] painters ran %d times" % _painted)
	layer.queue_free()
	G.zones.clear()
	for e in G.enemies:
		e.hp = 0
	G.enemies.clear()
