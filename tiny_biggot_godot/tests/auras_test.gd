extends Node
## 33.1 THE MIND FIELD (scripts/combat/auras.gd). Run:
##   godot --headless --path . res://tests/auras_test.tscn -- --no-save
## Reach grows with INT and with OVERMIND / WIDE THOUGHTS; a halo pulses only in a fight and hurts
## or ails what is inside it and nothing outside; HUMMING FIELD makes every pulse hit; the surge
## (MIND SPIRAL) doubles the reach for a while; HORIZON RING sends bigger, harder moons out; the
## Mindwarden starts with a halo and plays 10 s; classic has a reach of 1 and no halos.
## Prints "auras test: PASSED" or a FAIL line per problem.

var fails := 0
var notes := []

func fail(msg: String) -> void:
	fails += 1
	print("FAIL auras: ", msg)

func _start(hero: String = "hexer") -> Player:
	var all := GameData.heroes()
	for i in all.size():
		if all[i]["id"] == hero:
			G.hero_index = i
	G.new_run()
	G.floor_index = 2
	G.start_floor()
	G.god = true
	var p := G.player
	p.oath_picks = 0
	p.pending = 0
	G.enter_room(World.make_room(G.floor_d, "combat", "", "s", { "no_secret": true }))
	G.room.waves_left = 0
	G.enemies.clear()
	G.locked = true
	G.state = &"play"
	Meta.opts["autofire"] = false   # only the halos hit here
	p.x = 14.0 * TB.TS
	p.y = 10.0 * TB.TS
	return p

func _foe(x: float, y: float) -> Enemy:
	var e := Combat.spawn_enemy("skeleton", x, y, false, true)
	e.speed = 0.0
	e.max_hp = 1e7
	e.hp = 1e7
	return e

func _tick(n: int) -> void:
	for i in n:
		var p := G.player
		p.hp = p.max_hp
		Keys.tick()
		G.update(TB.DT)
		if G.state != &"play":
			G.state = &"play"
			G.tchoice = {}
			G.choice = {}

func _ready() -> void:
	await get_tree().process_frame
	seed(33)
	var p := _start()
	# Reach and INT.
	p.a_int = 0
	var r0 := Auras.reach(p)
	p.a_int = 10
	var r10 := Auras.reach(p)
	if absf(r0 - 1.0) > 1e-6 or absf(r10 - 1.2) > 1e-6:
		fail("reach %.3f at INT 0, %.3f at INT 10 (want 1.0, 1.2)" % [r0, r10])
	G.take_trait(Traits.by_id("k_overmind"))
	p.a_int = 10   # (a trait rank also trains INT)
	if absf(Auras.reach(p) - (1.0 + 0.06 * 10)) > 1e-6:
		fail("OVERMIND: reach %.3f at INT 10 (want 1.6)" % Auras.reach(p))
	p.pending += 1
	G.take_trait(Traits.by_id("k_widethoughts"))
	p.a_int = 10
	if absf(Auras.reach(p) - 1.75) > 1e-6:
		fail("WIDE THOUGHTS: reach %.3f (want 1.75)" % Auras.reach(p))
	p.a_int = 500
	if Auras.reach(p) > Auras.MAX_REACH + 1e-6:
		fail("reach not capped: %.2f" % Auras.reach(p))
	# A halo: nothing outside a fight, the field inside it in a fight, nothing outside the field.
	p = _start()
	p.a_int = 0
	G.add_relic(p, Relics.by_id("sunhalo"))
	if Auras.active(p).size() != 1:
		fail("THE SUN CROWN gives no halo: %s" % [Auras.active(p)])
	Auras.stats.clear()
	_tick(120)
	if Auras.stats.get("sun", 0) > 0:
		fail("a halo pulsed with no foe about")
	var r := Auras.radius(p, "sun")
	var near := _foe(p.x + r * 0.6, p.y)
	var far := _foe(p.x + r + 40.0, p.y)
	_tick(130)
	if Auras.stats.get("sun", 0) < 2:
		fail("the halo pulsed %d times in 2 s of fight" % Auras.stats.get("sun", 0))
	if near.hp >= 1e7 or near.burn_t <= 0:
		fail("the foe inside the field (%.0f of %.0f) took no hit or burn" % [p.x - near.x, r])
	if far.hp < 1e7 or far.burn_t > 0:
		fail("the foe outside the field was touched")
	# INT makes the field reach the far foe.
	p.a_int = 40
	far.burn_t = 0.0
	_tick(70)
	if far.burn_t <= 0:
		fail("at INT 40 (reach %.2f) the field did not reach a foe %.0f away" % [Auras.reach(p), far.x - p.x])
	# HUMMING FIELD: a frost halo hits too.
	p = _start()
	p.a_int = 0
	G.add_relic(p, Relics.by_id("frosthalo"))
	var cold := _foe(p.x + 30.0, p.y)
	_tick(70)
	if cold.hp < 1e7:
		fail("a frost halo hit without HUMMING FIELD")
	G.take_trait(Traits.by_id("k_hum"))
	_tick(70)
	if cold.hp >= 1e7:
		fail("HUMMING FIELD: the frost halo did not hit")
	# The surge.
	var base := Auras.reach(p)
	Actions.run(["aura_surge", 2.0, 1.0], 1, {})
	if absf(Auras.reach(p) - base * 2.0) > 1e-6:
		fail("the surge: reach %.2f, want %.2f" % [Auras.reach(p), base * 2.0])
	_tick(70)
	if absf(Auras.reach(p) - base) > 1e-6:
		fail("the surge did not end")
	# HORIZON RING.
	p = _start()
	p.a_int = 20
	var m0 := Auras.moon_dmg(p)
	G.add_relic(p, Relics.by_id("horizonring"))
	if p.orbitals < 2 or Auras.orbit_radius(p) <= 20.0 or Auras.moon_scale(p) <= 1.0 or Auras.moon_dmg(p) <= m0 * 2.0:
		fail("HORIZON RING: %d moons at %.0f px, x%.2f size, %.2f damage" % [p.orbitals, Auras.orbit_radius(p), Auras.moon_scale(p), Auras.moon_dmg(p)])
	var pos: Array = Combat.orbital_positions(p)
	var moon: Vector2 = pos[0]
	var hit := _foe(moon.x, moon.y)
	hit.x = moon.x
	hit.y = moon.y
	_tick(2)
	if hit.hp >= 1e7:
		fail("a big moon did not hit the foe it touched")
	notes.append("reach x%.2f at INT 20 with HORIZON RING: moons at %.0f px, x%.2f" % [Auras.reach(p), Auras.orbit_radius(p), Auras.moon_scale(p)])
	# The Mindwarden: a halo from the start, and 10 s of a fight.
	p = _start("mindwarden")
	if p.g("halo_mind") < 1 or p.a_int < 6:
		fail("the Mindwarden starts without INNER LIGHT or INT (halo %s, INT %d)" % [p.g("halo_mind"), p.a_int])
	for i in 4:
		_foe(p.x - 60.0 + i * 40.0, p.y - 40.0)
	Auras.stats.clear()
	_tick(600)
	if Auras.stats.get("mind", 0) < 8:
		fail("the Mindwarden's halo pulsed %d times in 10 s" % Auras.stats.get("mind", 0))
	notes.append("the Mindwarden: INT %d, reach x%.2f, %d pulses in 10 s" % [p.a_int, Auras.reach(p), Auras.stats.get("mind", 0)])
	# Classic: no reach.
	GameData.force_classic = true
	if Auras.reach(p) != 1.0:
		fail("classic has an aura reach of %.2f" % Auras.reach(p))
	GameData.force_classic = false
	Meta.opts["autofire"] = true
	for n in notes:
		print("[auras] ", n)
	print("auras test: PASSED" if fails == 0 else "auras test: %d FAILED" % fails)
	get_tree().quit()
