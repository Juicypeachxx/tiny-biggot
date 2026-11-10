extends Node
## 60.1 the effects revamp (scripts/render/bits.gd). Run:
##   godot --headless --path . res://tests/bits_test.tscn -- --no-save
## 1 FANCY EFFECTS off: no hook makes a particle or a crack.
## 2 On: each hook makes particles; ten thousand hooks never hold more than CAP particles or CRACKS
##   cracks, nor start more than PER_TICK in a tick; three seconds later every one is gone.
## 3 The game's random numbers are untouched: one seed gives the same numbers with every hook
##   called in between (the hooks are only in the effects, so the replays stay identical).
## 4 A crack only on open floor; a burning, a frozen, a poisoned and a shocked foe each give off
##   their own particles.
## 5 Every kind of particle and a crack are drawn on a canvas.
## Prints "bits test: PASSED" or a FAIL line per problem.

var fails := 0
var _drawn := false

func fail(msg: String) -> void:
	fails += 1
	print("FAIL bits: ", msg)

func _ready() -> void:
	await get_tree().process_frame
	G.hero_index = 0
	G.new_run()
	G.floor_index = 0
	G.start_floor()
	G.enter_room(World.make_room(G.floor_d, "combat", "", "s", { "no_secret": true }))
	G.enemies.clear()
	G.room.waves_left = 0
	G.state = &"play"
	for r in range(4, 16):
		for c in range(2, 26):
			G.room.grid[r * TB.COLS + c] = World.T_FLOOR
	var keep := Vfx.enabled
	_off()
	_on()
	_random()
	_floor_and_foes()
	await _draw()
	Vfx.enabled = keep
	Bits.reset()
	print("bits test: PASSED" if fails == 0 else "bits test: %d FAILED" % fails)
	get_tree().quit()

## Every hook once at (x, y), the tick's limit cleared between them.
func _hooks(x: float, y: float, foe: Enemy) -> Array:
	var made := []
	var calls := [
		func(): Bits.hit(x, y, "pyre"), func(): Bits.hit(x, y, "frost"), func(): Bits.hit(x, y, "venom"),
		func(): Bits.hit(x, y, "storm"), func(): Bits.hit(x, y, "blood"), func(): Bits.hit(x, y, "shadow"),
		func(): Bits.hit(x, y, "arcane"), func(): Bits.hit(x, y, "demolition"), func(): Bits.hit(x, y, "core"),
		func(): Bits.cut(x, y, 0.5, false), func(): Bits.cut(x, y, 0.5, true), func(): Bits.crit(x, y),
		func(): Bits.heavy(x, y, 1.0), func(): Bits.blast(x, y, 30.0, "fire"), func(): Bits.blast(x, y, 30.0, "frost"),
		func(): Bits.blast(x, y, 30.0, "venom"), func(): Bits.blast(x, y, 30.0, "gold"), func(): Bits.blast(x, y, 30.0, "void"),
		func(): Bits.pop(foe, foe.d["sprite"])]
	for c in calls:
		var n0 := Bits.n
		c.call()
		made.append(Bits.n - n0)
		Bits.update(0.0)   # (a new tick: its limit starts again)
	return made

# ---------- 1 ----------
func _off() -> void:
	var foe := Combat.spawn_enemy("skeleton", 200.0, 150.0)
	Vfx.enabled = false
	Bits.reset()
	_hooks(200.0, 150.0, foe)
	if Bits.n != 0 or not Bits.cracks.is_empty():
		fail("FANCY EFFECTS off: %d particles, %d cracks (want none)" % [Bits.n, Bits.cracks.size()])
	G.enemies.clear()
	print("[bits] FANCY EFFECTS off: nothing")

# ---------- 2 ----------
func _on() -> void:
	var foe := Combat.spawn_enemy("skeleton", 200.0, 150.0)
	Vfx.enabled = true
	Bits.reset()
	var made := _hooks(200.0, 150.0, foe)
	for i in made.size():
		if made[i] <= 0:
			fail("hook %d made no particle" % i)
	if Bits.cracks.is_empty():
		fail("a heavy blow and a big blast cracked no floor")
	var most := 0
	var most_cracks := 0
	for k in 10000:
		var n0 := Bits.n
		Bits.blast(100.0 + k % 200, 120.0 + k % 90, 40.0, "fire")
		Bits.heavy(100.0 + (k * 7) % 200, 120.0 + (k * 3) % 90, 1.0)
		if Bits.n - n0 > Bits.PER_TICK:
			fail("%d particles started in one tick (most %d)" % [Bits.n - n0, Bits.PER_TICK])
			break
		most = maxi(most, Bits.n)
		most_cracks = maxi(most_cracks, Bits.cracks.size())
		if k % 3 == 0:
			Bits.update(TB.DT)
	if most > Bits.CAP or most_cracks > Bits.CRACKS:
		fail("%d particles, %d cracks at once (most %d, %d)" % [most, most_cracks, Bits.CAP, Bits.CRACKS])
	for i in 180:
		Bits.update(TB.DT)
	if Bits.n != 0 or not Bits.cracks.is_empty():
		fail("3 s later: %d particles, %d cracks left" % [Bits.n, Bits.cracks.size()])
	G.enemies.clear()
	print("[bits] on: every hook makes particles (%s); at most %d particles and %d cracks at once" % [made, most, most_cracks])

# ---------- 3 ----------
func _random() -> void:
	var foe := Combat.spawn_enemy("skeleton", 200.0, 150.0)
	Vfx.enabled = true
	Bits.reset()
	seed(4242)
	var a := [randf(), randi(), randf_range(0.0, 9.0)]
	seed(4242)
	_hooks(210.0, 140.0, foe)
	for i in 30:
		Bits.update(TB.DT)
	var b := [randf(), randi(), randf_range(0.0, 9.0)]
	if a != b:
		fail("the hooks used the game's random numbers: %s, then %s" % [a, b])
	G.enemies.clear()
	Bits.reset()
	print("[bits] the game's random numbers untouched")

# ---------- 4 ----------
func _floor_and_foes() -> void:
	Vfx.enabled = true
	Bits.reset()
	Bits.crack(8.0, 8.0, 20.0, false)   # the top left corner: wall
	if not Bits.cracks.is_empty():
		fail("a crack on a wall")
	var got := {}
	for st in ["burn", "chill", "poison", "shock"]:
		G.enemies.clear()
		Bits.reset()
		var e := Combat.spawn_enemy("skeleton", 200.0, 150.0)
		e.spawn_t = 0.0
		match st:
			"burn": e.burn_t = 5.0
			"chill": e.chill_t = 5.0
			"poison": e.poison = 5.0
			"shock": e.shock = 2
		for i in 60:
			Bits.update(TB.DT)
		var want: int = { "burn": Bits.K_EMBER, "chill": Bits.K_SHARD, "poison": Bits.K_BUBBLE, "shock": Bits.K_ZAP }[st]
		var seen := 0
		for i in Bits.n:
			if Bits._k[i] == want:
				seen += 1
		got[st] = seen
		if seen == 0:
			fail("a foe with %s gave off none of its particles in 1 s" % st)
	G.enemies.clear()
	Bits.reset()
	print("[bits] cracks only on open floor; afflicted foes give off their particles: %s" % got)

# ---------- 5 ----------
class Canvas extends Node2D:
	var done := false
	func _draw() -> void:
		Bits.draw_ground(self)
		Bits.draw(self)
		done = true

func _draw() -> void:
	Vfx.enabled = true
	Bits.reset()
	var foe := Combat.spawn_enemy("skeleton", 200.0, 150.0)
	_hooks(200.0, 150.0, foe)
	for i in 3:
		Bits.update(TB.DT)
	var kinds := {}
	for i in Bits.n:
		kinds[Bits._k[i]] = true
	var c := Canvas.new()
	add_child(c)
	c.queue_redraw()
	await get_tree().process_frame
	await get_tree().process_frame
	if kinds.size() < 9:
		fail("only %d kinds of particle alive to draw (want all 9): %s" % [kinds.size(), kinds.keys()])
	print("[bits] drawn: %d kinds, %d particles, %d cracks (drawn %s)" % [kinds.size(), Bits.n, Bits.cracks.size(), c.done])
	c.queue_free()
	G.enemies.clear()
