extends Node
## V2 (his word, 23 Oct, with five photos): VID, THE HURIKAN SLAVE guards the second floor (vid.gd).
## Run: godot --headless --path . res://tests/vid_test.tscn -- --no-save
## 1 Floors: the expanded game's second floor has him (--classic: THE SPORE MOTHER); the fifth floor
##   has THE RIME WARDEN, THE SPORE MOTHER, THE WALRUS ADMIRAL or THE BONE COLOSSUS, each about a
##   quarter of the time, and the three from the second floor have THE RIME WARDEN's health there.
## 2 His name, his line and every word he says in the pixel font (Š, Ž).
## 3 Each of his moves plays out, ends and hurts a hero standing where it was shown: PEACE, LED WALL,
##   CABLES, BEER, ONE MORE CHAPTER; in his metal form PEACE (the horns), HURIKAN, LASSO, WALL OF
##   DEATH, STAGE DIVE. POWER NAP: x1.5, and he does not hit back.
## 4 At half health his metal form (his second phase; _s2), at a quarter full metal (_s3).
## 5 Beaten: he clocks out where he stood (vid_rest); the floor goes on (its portal); his own drop is
##   VID'S CABLE, never found elsewhere.
## Prints "vid test: PASSED" or a FAIL line per problem.

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL vid: ", msg)

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

func _vid() -> Enemy:
	var e := Combat.spawn_boss("vid", true)
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
	seed(60)
	_floors()
	_font()
	_moves()
	_phase()
	_beaten()
	print("vid test: PASSED" if fails == 0 else "vid test: %d FAILED" % fails)
	get_tree().quit()

# ---------- 1 ----------
func _floors() -> void:
	_run(1)
	if G.floor_d.get("guardian", "") != "vid":
		fail("the second floor's guardian is %s (want vid)" % G.floor_d.get("guardian", GameData.floors()[1]["boss"]))
	var seen := {}
	for i in 400:
		G.floor_index = 4
		G.start_floor()
		var k: String = G.floor_d.get("guardian", GameData.floors()[4]["boss"])
		seen[k] = seen.get(k, 0) + 1
	for k in ["rimewarden", "sporemother", "admiral", "colossus"]:
		if seen.get(k, 0) < 60 or seen.get(k, 0) > 140:
			fail("the fifth floor had %s %d times in 400 (want about 100): %s" % [k, seen.get(k, 0), seen])
	if seen.size() != 4:
		fail("the fifth floor's guardians: %s (want the four)" % seen)
	# The Colossus on the fifth floor, from its boss room: THE RIME WARDEN's health.
	_run(4)
	G.floor_d["guardian"] = "colossus"
	G.room.type = "boss"
	G.locked = true
	G.boss = null
	G.boss_delay = 0.01
	_tick(3)
	var got: float = G.boss.max_hp if G.boss != null and G.boss.boss == "colossus" else 0.0
	G.enemies.clear()
	G.boss = null
	var own := Combat.spawn_boss("colossus", true)
	var want: float = own.max_hp * float(GameData.BOSSES["rimewarden"]["hp"]) / float(GameData.BOSSES["colossus"]["hp"])
	G.enemies.clear()
	G.boss = null
	if absf(got - want) > want * 0.02:
		fail("the Colossus on the fifth floor has %.0f health (want THE RIME WARDEN's, %.0f)" % [got, want])
	GameData.force_classic = true
	_run(1)
	if G.floor_d.has("guardian"):
		fail("--classic: the second floor's guardian is %s (want the Spore Mother)" % G.floor_d["guardian"])
	GameData.force_classic = false
	print("[vid] floor 2: vid; floor 5 in 400: %s, the Colossus there at %.0f health; --classic floor 2: sporemother" % [seen, got])

# ---------- 2 ----------
func _font() -> void:
	var nm: String = GameData.BOSSES["vid"]["name"]
	var words := nm + String(GameData.BOSSES["vid"]["line"]) + String(Barks.BOSS_LINES.get("vid", "")) + RiftBosses.PHASE_LINE["vid"] \
		+ "".join(Stages.OWN_LINES["vid"]) + "PEACE!HORNS UP!LED WALL UP!KABLI!ŠE ENO PIVO!ŠE PET MINUT...ŽE?!ŠE EN CHAPTER..." \
		+ "HURIKAAAN!KABEL!WALL OF DEATH!STAGE DIVE!METAL FORM!VID CLOCKED OUTOVERTIME IS OVER"
	for ch in words:
		if not ch in Gfx.FONT_CHARS:
			fail("the font cannot draw %s" % ch)
	print("[vid] %s: every letter of his words in the font" % nm)

# ---------- 3 ----------
## One of his moves with the hero standing at `at` (relative to him): [ended in time, hits on the hero].
func _move(move: StringName, at: Vector2, phase: int = 1) -> Array:
	var p := _run(1)
	var e := _vid()
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
	for m in [[&"peace", Vector2(80, 0), 1], [&"ledwall", Vector2(60, 0), 1], [&"cables", Vector2(60, 0), 1],
			[&"beer", Vector2(70, 0), 1], [&"manga", Vector2(28, 0), 1], [&"peace", Vector2(80, 0), 2],
			[&"hurikan", Vector2(70, 0), 2], [&"lasso", Vector2(60, 0), 2], [&"walldeath", Vector2(60, 0), 2],
			[&"dive", Vector2(70, 0), 2], [&"beer", Vector2(70, 0), 2], [&"ledwall", Vector2(60, 0), 2]]:
		var r := _move(m[0], m[1], m[2])
		if not r[0]:
			fail("%s (phase %d) did not end in 10 s" % [m[0], m[2]])
		elif r[1] <= 0:
			fail("%s (phase %d) never hurt a hero standing where it was shown" % [m[0], m[2]])
		else:
			got.append("%s%s %d" % [m[0], "" if m[2] == 1 else " (metal)", r[1]])
	# POWER NAP: x1.5, and he does not hit back (a hero standing on him); then he wakes.
	var p := _run(1)
	var e := _vid()
	e.x = 14.0 * TB.TS
	e.y = 9.0 * TB.TS
	e.state = &"nap"
	e.sub = 0
	e.st = 0.0
	_tick(25)
	if e.state != &"nap" or e.sub != 1 or absf(Vid.adjust_damage(e, 10.0) - 15.0) > 0.01 or not Vid.sprite(e).begins_with("vid_nap"):
		fail("power nap: state %s %d, takes %.1f of 10, picture %s" % [e.state, e.sub, Vid.adjust_damage(e, 10.0), Vid.sprite(e)])
	p.x = e.x
	p.y = e.y
	p.invuln = 0.0
	EBullets.clear_all()
	var h0: int = G.room.hits
	_tick(30)
	if G.room.hits != h0:
		fail("power nap: standing on him hurt the hero")
	var t := 0
	while e.state != &"rest" and t < 300:
		_tick(1)
		t += 1
	if e.state != &"rest":
		fail("power nap: he never woke up")
	G.enemies.clear()
	EBullets.clear_all()
	print("[vid] moves (hits on a hero in their way): %s; power nap: x1.5, no hits back" % ", ".join(got))

# ---------- 4 ----------
func _phase() -> void:
	_run(1)
	var e := _vid()
	if not Resolve.on(e) or Patterns.of(e)[0] != "pinwheel":
		fail("RESOLVE %s, his signature %s (want on, pinwheel)" % [Resolve.on(e), Patterns.of(e)])
	e.hp = e.max_hp * 0.45
	e.t = 0.0
	var t := 0.0
	while t < 4.0 and e.phase < 2:
		_tick(1)
		t += TB.DT
	if e.phase != 2 or not Vid.sprite(e).ends_with("_s2"):
		fail("at half health: phase %d, picture %s (want 2, his metal form: _s2)" % [e.phase, Vid.sprite(e)])
	e.hp = e.max_hp * 0.2
	t = 0.0
	while t < 3.0 and Vid.look(e) < 3:
		_tick(1)
		t += TB.DT
	if not Vid.sprite(e).ends_with("_s3"):
		fail("at a quarter: picture %s (want full metal: _s3)" % Vid.sprite(e))
	for s in ["vid", "vid_peace", "vid_lasso", "vid_panel", "vid_drink", "vid_nap", "vid_manga", "vid_spin", "vid_out"]:
		for lk in ["", "_s2", "_s3"]:
			if not Img.has(s + lk):
				fail("no picture %s" % (s + lk))
	G.enemies.clear()
	EBullets.clear_all()
	print("[vid] his metal form at half health, full metal at a quarter")

# ---------- 5 ----------
func _beaten() -> void:
	_run(1)
	G.room.type = "boss"
	var e := _vid()
	e.hp = 0.0
	Combat.kill_enemy(e)
	var rest := false
	var portal := false
	for o in G.room.objects:
		rest = rest or o["kind"] == "vid_rest"
		portal = portal or o["kind"] == "portal"
	if not rest or not portal:
		fail("beaten: clocked out where he stood %s, the floor's portal %s" % [rest, portal])
	var w := Weapons.by_id("vidcable")
	if BossLoot.DROPS.get("vid", []).back() != "vidcable" or not BossLoot.is_unique("vidcable") or not Img.has(w["sprite"]):
		fail("his drop: %s, unique %s, picture %s" % [BossLoot.DROPS.get("vid", []), BossLoot.is_unique("vidcable"), Img.has(w["sprite"])])
	print("[vid] beaten: he clocks out, the portal opens; his drop: %s" % w["name"])
