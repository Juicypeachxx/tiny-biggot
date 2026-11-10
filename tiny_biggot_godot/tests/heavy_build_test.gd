extends Node
## His slow fight of 8 Oct (a screen recording: floor 12, level 52, THE BLANK QUILL, 31 fps, the
## room hidden under giant shots). Run:
##   godot --headless --path . res://tests/heavy_build_test.tscn -- --no-save
##   1. With the room full of shots, an attack's shots merge into a shot already flying. A heavy
##      shot's x3 and x1.5 (HEAVY BOLT) used to land on that old shot once for every shot merged,
##      attack after attack: it grew to cover the room and its damage tripled over and over. Now
##      a merged shot's share is tripled and the shot flying keeps its size.
##   2. A lance fired at the cap no longer changes the old shot (its reach, its piercing).
##   3. Giant shots fly fewer at once (the cap falls with their size); ordinary shots keep 300.
##   4. Triggers find their procs through an index kept with the procs (equip, unequip, again).
##   5. Past 80 poison pools the oldest dry up; fire pools are left alone.
## Prints "heavy build test: PASSED" or a FAIL line per problem.

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL heavy build: ", msg)

func _ready() -> void:
	await get_tree().process_frame
	seed(8)
	_heavy_at_cap()
	_lance_at_cap()
	_giant_cap()
	_proc_index()
	_poison_pools()
	print("heavy build test: PASSED" if fails == 0 else "heavy build test: %d FAILED" % fails)
	get_tree().quit()

func _start(weapon: String) -> Player:
	G.hero_index = 0
	G.new_run()
	G.floor_index = 2
	G.start_floor()
	G.god = true
	G.enter_room(World.make_room(G.floor_d, "combat", "", "s", { "no_secret": true }))
	G.room.waves_left = 0
	G.state = &"play"
	var p := G.player
	Weapons.equip_weapon(p, Weapons.by_id(weapon))
	p.x = 14.0 * TB.TS
	p.y = 13.0 * TB.TS
	return p

## Fills the room with the player's shots (they stand still, far from any foe).
func _fill(p: Player) -> void:
	G.pbullets.clear()
	while G.pbullets.size() + G.new_pbullets.size() < Effects.pbullet_cap():
		var b := Combat.spawn_pbullet(p, 0.0)
		b.vx = 0.0
		b.vy = 0.0
		b.life = 99.0

func _heavy_at_cap() -> void:
	var p := _start("lute")   # a plain staff: no procs of its own to add shots
	p.procs.clear()
	p.proc_index = {}
	p.count += 14
	p.heavy_n = 1   # every attack heavy
	_fill(p)
	var r0 := 0.0
	for b in G.pbullets:
		r0 = maxf(r0, b.r)
	var per := Weapons.wdmg(p) * Weapons.wcount(p)
	var dmg0 := 0.0
	for b in G.pbullets:
		dmg0 += b.dmg
	for i in 30:
		p.shot_n += 1
		Combat.player_shoot(p, 0.0, false)
	var r1 := 0.0
	var dmg1 := 0.0
	for b in G.pbullets + G.new_pbullets:
		r1 = maxf(r1, b.r)
		dmg1 += b.dmg
	if r1 > r0 * 1.001:
		fail("heavy attacks at the cap made a shot grow from %.1f to %.1f" % [r0, r1])
	var want := per * 3.0 * 30
	if absf((dmg1 - dmg0) - want) > want * 0.01:
		fail("heavy attacks at the cap added %.0f damage, not %.0f (each attack's share tripled once)" % [dmg1 - dmg0, want])

func _lance_at_cap() -> void:
	var p := _start("lute")
	p.procs.clear()
	p.proc_index = {}
	p.lance_n = 1   # every attack also throws a lance
	_fill(p)
	var last: PBullet = G.pbullets[G.pbullets.size() - 1]
	var r0 := last.r
	var pierce0 := last.pierce
	p.shot_n += 1
	Combat.player_shoot(p, 0.0, false)
	if last.r != r0 or last.pierce != pierce0:
		fail("a lance fired at the cap changed a shot already flying (r %.1f->%.1f, pierce %d->%d)" % [r0, last.r, pierce0, last.pierce])

func _giant_cap() -> void:
	var p := _start("blankquill")
	var base := Weapons.wsize(p)
	if Effects.pbullet_cap() != Effects.ROGUES_PBULLET_CAP:
		fail("ordinary shots: the cap is %d, not %d" % [Effects.pbullet_cap(), Effects.ROGUES_PBULLET_CAP])
	p.size = 6.0 / maxf(0.01, Weapons.wsize(p) / p.size)   # shots six times their size
	if Effects.pbullet_cap() != Effects.GIANT_PBULLET_CAP:
		fail("giant shots (size %.1f): the cap is %d, not %d" % [Weapons.wsize(p), Effects.pbullet_cap(), Effects.GIANT_PBULLET_CAP])
	p.size = 3.0 / maxf(0.01, Weapons.wsize(p) / p.size)
	var c := Effects.pbullet_cap()
	if c <= Effects.GIANT_PBULLET_CAP or c >= Effects.ROGUES_PBULLET_CAP:
		fail("shots three times their size: the cap is %d (between %d and %d expected)" % [c, Effects.GIANT_PBULLET_CAP, Effects.ROGUES_PBULLET_CAP])
	if base > 2.0:
		fail("the blank quill's own shots count as giant (%.2f)" % base)

func _proc_index() -> void:
	var p := _start("blankquill")
	var ring := Gear.by_id("twinring")   # every 5th attack also fires 3 shots behind you
	Gear.equip_gear(p, ring)
	var mine: Variant = null
	for pr in p.procs:
		if pr["src"].contains("twinring"):
			mine = pr
	if mine == null:
		fail("the ring brought no proc")
		return
	for i in 5:
		Effects.fire("every_n_shots", { "x": p.x, "y": p.y })
	if mine["count"] != 5 or not (p.proc_index.get("every_n_shots", []) as Array).has(mine):
		fail("a ring's every-5th-attack proc was not reached through the index (count %d)" % mine["count"])
	Effects.remove_procs(p, mine["src"])
	for i in 5:
		Effects.fire("every_n_shots", { "x": p.x, "y": p.y })
	if mine["count"] != 5 or (p.proc_index.get("every_n_shots", []) as Array).has(mine):
		fail("a proc removed with its ring was still reached (count %d)" % mine["count"])
	Gear.equip_gear(p, ring)
	Effects.fire("every_n_shots", { "x": p.x, "y": p.y })
	var again := false
	for pr in p.proc_index.get("every_n_shots", []):
		if pr["src"].contains("twinring"):
			again = true
	if not again:
		fail("the ring worn again was not found by its trigger")

func _poison_pools() -> void:
	var p := _start("blankquill")
	G.zones.clear()
	for i in 200:
		G.zones.append({ "x": 40.0 + i, "y": 60.0, "r": 10, "t": 5.0, "kind": "poison", "tick": 1.0 })
	for i in 5:
		G.zones.append({ "x": 40.0 + i, "y": 90.0, "r": 10, "t": 5.0, "kind": "fire", "tick": 1.0 })
	Combat.update_zones(TB.DT)
	var poison := G.zones.filter(func(z): return z["kind"] == "poison")
	var fire := G.zones.filter(func(z): return z["kind"] == "fire")
	if poison.size() != Combat.POISON_POOLS:
		fail("%d poison pools left, not %d" % [poison.size(), Combat.POISON_POOLS])
	if fire.size() != 5:
		fail("fire pools were dried up too (%d of 5)" % fire.size())
	if not poison.is_empty() and poison[0]["x"] != 40.0 + 200 - Combat.POISON_POOLS:
		fail("the newest poison pools should stay (first left at x %.0f)" % poison[0]["x"])
