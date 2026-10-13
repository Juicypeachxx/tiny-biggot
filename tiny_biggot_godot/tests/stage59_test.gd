extends Node
## Stage 59 (his word, 13 Oct, with five photos): ŠEFE, KING OF THE BLOK guards the third floor
## (sefe.gd). Run: godot --headless --path . res://tests/stage59_test.tscn -- --no-save
## 1 Floors: the expanded game's third floor has him (--classic: THE DROWNED LIBRARIAN); the fourth
##   floor has THE FORGE TYRANT, THE GOLEM KING or THE DROWNED LIBRARIAN, each about a third of the time.
## 2 His name in the pixel font (Š).
## 3 Each of his moves plays out, ends and hurts a hero standing where it was shown: FINGER GUNS,
##   BEER, THE BIG ONE, CHAINSAW, AXE; MOG: a hero in the cone is MOGGED (slow), one beside it is not;
##   SMOKE BREAK: his clouds slow a hero in them, and six blows make him cough (x1.5, no hits back);
##   ZONED OUT: x1.5, and he does not hit back.
## 4 At half health: the crown and the chain (his second phase; _s2).
## 5 Beaten: he passes out where he stood (sefe_rest); the floor goes on (its portal); his own drop
##   is ŠEFE'S FINGER GUNS, never found elsewhere.
## Prints "stage59 test: PASSED" or a FAIL line per problem.

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL stage59: ", msg)

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

func _sefe() -> Enemy:
	var e := Combat.spawn_boss("sefe", true)
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
	seed(59)
	_floors()
	_font()
	_moves()
	_mog()
	_smoke()
	_phase()
	_beaten()
	print("stage59 test: PASSED" if fails == 0 else "stage59 test: %d FAILED" % fails)
	get_tree().quit()

# ---------- 1 ----------
func _floors() -> void:
	_run(2)
	if G.floor_d.get("guardian", "") != "sefe":
		fail("the third floor's guardian is %s (want sefe)" % G.floor_d.get("guardian", GameData.floors()[2]["boss"]))
	var seen := {}
	for i in 300:
		G.floor_index = 3
		G.start_floor()
		var k: String = G.floor_d.get("guardian", GameData.floors()[3]["boss"])
		seen[k] = seen.get(k, 0) + 1
	for k in ["tyrant", "golemking", "librarian"]:
		if seen.get(k, 0) < 60 or seen.get(k, 0) > 140:
			fail("the fourth floor had %s %d times in 300 (want about 100): %s" % [k, seen.get(k, 0), seen])
	if seen.size() != 3:
		fail("the fourth floor's guardians: %s (want the three)" % seen)
	GameData.force_classic = true
	_run(2)
	if G.floor_d.has("guardian"):
		fail("--classic: the third floor's guardian is %s (want the Librarian)" % G.floor_d["guardian"])
	GameData.force_classic = false
	print("[stage59] floor 3: sefe; floor 4 in 300: %s; --classic floor 3: librarian" % seen)

# ---------- 2 ----------
func _font() -> void:
	var nm: String = GameData.BOSSES["sefe"]["name"]
	for ch in nm + String(GameData.BOSSES["sefe"]["line"]):
		if not ch in Gfx.FONT_CHARS:
			fail("the font cannot draw %s" % ch)
	if Gfx.glyph_index("Š".unicode_at(0)) != Gfx.glyph_index("S".unicode_at(0)):
		fail("Š is not drawn as S with a hook")
	print("[stage59] %s: every letter in the font" % nm)

# ---------- 3 ----------
## One of his moves with the hero standing at `at` (relative to him): [ended in time, hits on the hero].
func _move(move: StringName, at: Vector2, phase: int = 1) -> Array:
	var p := _run(2)
	var e := _sefe()
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
	var after := 0
	for i in 60 * 10:
		p.hp = p.max_hp
		var h0: int = G.room.hits
		Keys.tick()
		G.update(TB.DT)
		G.state = &"play"
		hits += G.room.hits - h0
		p.invuln = minf(p.invuln, 0.05)   # (each touch counts)
		p.x = clampf(p.x, 3.0 * TB.TS, 25.0 * TB.TS)
		if e.state == &"rest" and not ended:
			ended = true
			e.t = 99.0   # (no next move: his last shots fly on, 1.5 s)
		if ended:
			after += 1
			if after >= 90:
				break
	G.enemies.clear()
	EBullets.clear_all()
	return [ended, hits]

func _moves() -> void:
	var got := []
	for m in [[&"fingerguns", Vector2(80, 0), 1], [&"beer", Vector2(70, 0), 1], [&"fingerguns", Vector2(80, 0), 2],
			[&"bigone", Vector2(70, -10), 2], [&"chainsaw", Vector2(80, 0), 2], [&"axe", Vector2(90, 0), 2]]:
		var r := _move(m[0], m[1], m[2])
		if not r[0]:
			fail("%s (phase %d) did not end in 10 s" % [m[0], m[2]])
		elif r[1] <= 0:
			fail("%s (phase %d) never hurt a hero standing where it was shown" % [m[0], m[2]])
		else:
			got.append("%s%s %d" % [m[0], "" if m[2] == 1 else " (king)", r[1]])
	# ZONED OUT: x1.5, and he does not hit back (a hero standing on him).
	var p := _run(2)
	var e := _sefe()
	e.state = &"zoned"
	e.sub = 0
	e.st = 0.0
	_tick(25)
	if e.state != &"zoned" or e.sub != 1 or absf(Sefe.adjust_damage(e, 10.0) - 15.0) > 0.01 or not Sefe.sprite(e).begins_with("sefe_zoned"):
		fail("zoned out: state %s %d, takes %.1f of 10, picture %s" % [e.state, e.sub, Sefe.adjust_damage(e, 10.0), Sefe.sprite(e)])
	p.x = e.x
	p.y = e.y
	p.invuln = 0.0
	var h0: int = G.room.hits
	_tick(30)
	if G.room.hits != h0:
		fail("zoned out: standing on him hurt the hero")
	G.enemies.clear()
	print("[stage59] moves (hits on a hero in their way): %s; zoned out: x1.5, no hits back" % ", ".join(got))

## MOG: a hero in the cone when he stares is MOGGED; a hero well beside it is not.
func _mog() -> void:
	var got := []
	for case in [[Vector2(70, 0), true], [Vector2(0, -90), false]]:
		var p := _run(2)
		var e := _sefe()
		e.x = 14.0 * TB.TS
		e.y = 9.0 * TB.TS
		var at: Vector2 = case[0]
		p.x = e.x + at.x
		p.y = e.y + at.y
		Finale.mog_t = 0.0
		Finale.mog_cd = 0.0
		e.state = &"mog"
		e.sub = 0
		e.st = 0.0
		# He aims his stare when it begins; then the hero steps aside (or stays).
		_tick(1)
		if not case[1]:
			p.x = e.x
			p.y = e.y - 90.0
			e.ca = 0.0   # (his stare to the right; the hero is above him)
		var mogged := false
		for i in 60:
			p.hp = p.max_hp
			_tick(1)
			if Finale.mog_t > 0.0:
				mogged = true
		if mogged != case[1]:
			fail("MOG: a hero %s was %sMOGGED" % ["in the cone" if case[1] else "beside it", "" if mogged else "not "])
		got.append(mogged)
		G.enemies.clear()
		EBullets.clear_all()
	print("[stage59] MOG: in the cone %s, beside it %s" % got)

## SMOKE BREAK: his clouds slow a hero in them; six blows and he coughs (x1.5, no hits back), then
## the move ends.
func _smoke() -> void:
	var p := _run(2)
	var e := _sefe()
	e.x = 14.0 * TB.TS
	e.y = 9.0 * TB.TS
	p.x = e.x + 80.0
	p.y = e.y
	e.state = &"smoke"
	e.sub = 0
	e.st = 0.0
	_tick(90)
	if Sefe.clouds.is_empty():
		fail("smoke break: no cloud after 1.5 s")
	else:
		var c: Dictionary = Sefe.clouds[0]
		p.x = c["x"]
		p.y = c["y"]
		if Sefe.speed_mult(p) >= 1.0:
			fail("smoke break: a hero in his cloud is not slowed")
	for i in Sefe.COUGH_HITS:
		Combat.damage_enemy(e, 1.0, { "no_crit": true, "no_mult": true })
	_tick(2)
	if e.state != &"smoke" or e.sub != 2 or absf(Sefe.adjust_damage(e, 10.0) - 15.0) > 0.01 or not Sefe.harmless(e):
		fail("smoke break: six blows did not make him cough (state %s %d)" % [e.state, e.sub])
	var t := 0
	while e.state != &"rest" and t < 300:
		_tick(1)
		t += 1
	if e.state != &"rest":
		fail("smoke break: he never got over his cough")
	G.enemies.clear()
	Sefe.clear()
	print("[stage59] smoke break: his clouds slow you; six blows and he coughs")

# ---------- 4 ----------
func _phase() -> void:
	_run(2)
	var e := _sefe()
	if not Resolve.on(e) or Patterns.of(e)[0] != "pinwheel":
		fail("RESOLVE %s, his signature %s (want on, pinwheel)" % [Resolve.on(e), Patterns.of(e)])
	e.hp = e.max_hp * 0.45
	e.t = 0.0
	var t := 0.0
	while t < 4.0 and e.phase < 2:
		_tick(1)
		t += TB.DT
	if e.phase != 2 or not Sefe.sprite(e).ends_with("_s2"):
		fail("at half health: phase %d, picture %s (want 2, the crown: _s2)" % [e.phase, Sefe.sprite(e)])
	G.enemies.clear()
	EBullets.clear_all()
	Sefe.clear()
	print("[stage59] the crown and the chain at half health")

# ---------- 5 ----------
func _beaten() -> void:
	_run(2)
	G.room.type = "boss"
	var e := _sefe()
	e.hp = 0.0
	Combat.kill_enemy(e)
	var rest := false
	var portal := false
	for o in G.room.objects:
		rest = rest or o["kind"] == "sefe_rest"
		portal = portal or o["kind"] == "portal"
	if not rest or not portal:
		fail("beaten: passed out where he stood %s, the floor's portal %s" % [rest, portal])
	var w := Weapons.by_id("sefefingerguns")
	if BossLoot.DROPS.get("sefe", []).back() != "sefefingerguns" or not BossLoot.is_unique("sefefingerguns") or not Img.has(w["sprite"]):
		fail("his drop: %s, unique %s, picture %s" % [BossLoot.DROPS.get("sefe", []), BossLoot.is_unique("sefefingerguns"), Img.has(w["sprite"])])
	print("[stage59] beaten: he passes out, the portal opens; his drop: %s" % w["name"])
