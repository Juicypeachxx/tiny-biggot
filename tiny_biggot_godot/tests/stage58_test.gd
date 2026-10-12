extends Node
## Stage 58 (his word, 12 Oct, with ten photos of his dog): ARČI THE PUSSY SLAYER guards the first
## floor (arci.gd). Run: godot --headless --path . res://tests/stage58_test.tscn -- --no-save
## 1 Floors: the expanded game's first floor has him (--classic: THE BONE COLOSSUS); the second
##   floor has THE SPORE MOTHER, THE WALRUS ADMIRAL or THE BONE COLOSSUS, each about a third of the time.
## 2 His name in the pixel font: Č, Š and Ž are C, S and Z (with a hook drawn over them).
## 3 Each of his moves plays out and ends, and hurts a hero standing where it was shown: BOOP, FRISBEE,
##   HERDING, CAT!, STICK; CRASH: asleep on his back he takes half again as much, and touching him
##   does not hurt.
## 4 At half health: SUNGLASSES ON (his second phase; the cool pictures). His patterns now and then
##   only from then on; RESOLVE as every guardian.
## 5 Beaten: not slain, he rolls over and stays there (arci_rest); the floor goes on (its portal);
##   his own drop is ARČI'S FRISBEE, never found elsewhere.
## Prints "stage58 test: PASSED" or a FAIL line per problem.

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL stage58: ", msg)

func _run(fl: int) -> Player:
	G.hero_index = 0
	G.new_run()
	G.god = false
	G.floor_index = fl
	G.start_floor()
	G.enter_room(World.make_room(G.floor_d, "combat", "", "s", { "no_secret": true }))
	G.enemies.clear()
	G.room.waves_left = 0
	G.locked = true
	G.state = &"play"
	Meta.opts["autofire"] = false
	for r in range(4, 16):
		for c in range(2, 26):
			G.room.grid[r * TB.COLS + c] = World.T_FLOOR
	return G.player

func _arci() -> Enemy:
	var e := Combat.spawn_boss("arci", true)
	e.spawn_t = 0.0
	e.state = &"rest"
	e.t = 99.0
	return e

func _tick(n: int) -> void:
	for i in n:
		Keys.tick()
		G.update(TB.DT)
		if G.state != &"play":
			G.state = &"play"
			G.tchoice = {}
			G.choice = {}

func _ready() -> void:
	await get_tree().process_frame
	seed(58)
	_floors()
	_font()
	_moves()
	_phase()
	_beaten()
	print("stage58 test: PASSED" if fails == 0 else "stage58 test: %d FAILED" % fails)
	get_tree().quit()

# ---------- 1 ----------
func _floors() -> void:
	_run(0)
	if G.floor_d.get("guardian", "") != "arci":
		fail("the first floor's guardian is %s (want arci)" % G.floor_d.get("guardian", GameData.floors()[0]["boss"]))
	var seen := {}
	for i in 300:
		G.floor_index = 1
		G.start_floor()
		var k: String = G.floor_d.get("guardian", GameData.floors()[1]["boss"])
		seen[k] = seen.get(k, 0) + 1
	for k in ["sporemother", "admiral", "colossus"]:
		if seen.get(k, 0) < 60 or seen.get(k, 0) > 140:
			fail("the second floor had %s %d times in 300 (want about 100): %s" % [k, seen.get(k, 0), seen])
	if seen.size() != 3:
		fail("the second floor's guardians: %s (want the three)" % seen)
	GameData.force_classic = true
	_run(0)
	if G.floor_d.has("guardian"):
		fail("--classic: the first floor's guardian is %s (want the Colossus)" % G.floor_d["guardian"])
	GameData.force_classic = false
	print("[stage58] floor 1: arci; floor 2 in 300: %s; --classic floor 1: colossus" % seen)

# ---------- 2 ----------
func _font() -> void:
	var nm: String = GameData.BOSSES["arci"]["name"]
	for ch in nm + "ŠŽ":
		if not ch in Gfx.FONT_CHARS:
			fail("the font cannot draw %s" % ch)
	if Gfx.glyph_index("Č".unicode_at(0)) != Gfx.glyph_index("C".unicode_at(0)) \
			or Gfx.glyph_index("Ž".unicode_at(0)) != Gfx.glyph_index("Z".unicode_at(0)):
		fail("Č and Ž are not drawn as C and Z with a hook")
	if Gfx.glyph_index("Ł".unicode_at(0)) != Gfx.glyph_index("?".unicode_at(0)):
		fail("a letter the font has no picture for is not drawn as ?")
	print("[stage58] %s: every letter in the font" % nm)

# ---------- 3 ----------
## One of his moves, with the hero standing at `at` (relative to him): true if it ended in time, and
## how many times the hero was hurt.
func _move(move: StringName, at: Vector2, phase: int = 1) -> Array:
	var p := _run(0)
	var e := _arci()
	e.phase = phase
	e.x = 14.0 * TB.TS
	e.y = 9.0 * TB.TS
	p.x = e.x + at.x
	p.y = e.y + at.y
	e.state = move
	e.sub = 0
	e.st = 0.0
	e.t = 0.0
	e.repeat = 0
	var hits := 0
	var ended := false
	for i in 60 * 8:
		p.hp = p.max_hp
		var h0: int = G.room.hits
		Keys.tick()
		G.update(TB.DT)
		G.state = &"play"
		hits += G.room.hits - h0
		p.invuln = minf(p.invuln, 0.05)   # (each touch counts)
		p.x = clampf(p.x, 3.0 * TB.TS, 25.0 * TB.TS)
		if e.state == &"rest":
			ended = true
			break
	G.enemies.clear()
	return [ended, hits]

func _moves() -> void:
	var got := []
	for m in [[&"boop", Vector2(70, 0), 1], [&"frisbee", Vector2(80, 10), 1], [&"herd", Vector2(70, 0), 1],
			[&"cat", Vector2(90, 0), 1], [&"stick", Vector2(0, 0), 2], [&"boop", Vector2(70, 0), 2], [&"cat", Vector2(90, 0), 2]]:
		var r := _move(m[0], m[1], m[2])
		if not r[0]:
			fail("%s (phase %d) did not end in 8 s" % [m[0], m[2]])
		elif r[1] <= 0:
			fail("%s (phase %d) never hurt a hero standing where it was shown" % [m[0], m[2]])
		else:
			got.append("%s%s %d" % [m[0], "" if m[2] == 1 else " (cool)", r[1]])
	# CRASH: asleep, he takes half again as much, and lying on him does not hurt.
	var p := _run(0)
	var e := _arci()
	e.state = &"crash"
	e.sub = 0
	e.st = 0.0
	_tick(20)
	if e.state != &"crash" or e.sub != 1:
		fail("crash: not asleep after a third of a second (state %s, %d)" % [e.state, e.sub])
	if absf(Arci.adjust_damage(e, 10.0) - 15.0) > 0.01 or not Arci.sprite(e).begins_with("arci_lie"):
		fail("crash: asleep he takes %.1f of 10, picture %s" % [Arci.adjust_damage(e, 10.0), Arci.sprite(e)])
	p.x = e.x
	p.y = e.y
	p.invuln = 0.0
	var h0: int = G.room.hits
	_tick(30)
	if G.room.hits != h0:
		fail("crash: standing on the sleeping dog hurt the hero")
	G.enemies.clear()
	print("[stage58] moves (hits on a hero in their way): %s; crash: x1.5 asleep, no bite" % ", ".join(got))

# ---------- 4 ----------
func _phase() -> void:
	_run(0)
	var e := _arci()
	if not Resolve.on(e) or Patterns.of(e)[0] != "comets":
		fail("RESOLVE %s, his signature %s (want on, comets)" % [Resolve.on(e), Patterns.of(e)])
	# The first phase: no patterns now and then.
	e.state = &"rest"
	e.t = 99.0
	Patterns.clear()
	for i in 60 * 12:
		Resolve.tick(TB.DT)
	if Patterns.busy():
		fail("his first phase cast a pattern on its own")
	# Half health: the sunglasses go on.
	e.hp = e.max_hp * 0.45
	e.t = 0.0
	var t := 0.0
	while t < 4.0 and e.phase < 2:
		_tick(1)
		t += TB.DT
	if e.phase != 2 or not Arci.sprite(e).ends_with("_s2"):
		fail("at half health: phase %d, picture %s (want 2, his sunglasses: _s2)" % [e.phase, Arci.sprite(e)])
	# The second phase: now and then a pattern.
	Patterns.clear()
	e.state = &"rest"
	e.t = 99.0
	var cast := false
	for i in 60 * 12:
		Resolve.tick(TB.DT)
		if Patterns.busy():
			cast = true
	if not cast:
		fail("his second phase cast no pattern in 12 s")
	Patterns.clear()
	G.enemies.clear()
	print("[stage58] sunglasses on at half health; patterns of his own only then")

# ---------- 5 ----------
func _beaten() -> void:
	_run(0)
	G.room.type = "boss"
	var e := _arci()
	e.hp = 0.0
	Combat.kill_enemy(e)
	var rest := false
	var portal := false
	for o in G.room.objects:
		rest = rest or o["kind"] == "arci_rest"
		portal = portal or o["kind"] == "portal"
	if not rest or not portal:
		fail("beaten: asleep where he fell %s, the floor's portal %s" % [rest, portal])
	var w := Weapons.by_id("arcifrisbee")
	if BossLoot.DROPS.get("arci", []).back() != "arcifrisbee" or not BossLoot.is_unique("arcifrisbee") or not Img.has(w["sprite"]):
		fail("his drop: %s, unique %s, picture %s" % [BossLoot.DROPS.get("arci", []), BossLoot.is_unique("arcifrisbee"), Img.has(w["sprite"])])
	for i in 200:
		if Weapons.random_weapon("legend")["id"] == "arcifrisbee":
			fail("ARČI'S FRISBEE came out of a random roll")
			break
	print("[stage58] beaten: he sleeps where he fell, the portal opens; his drop: %s" % w["name"])
