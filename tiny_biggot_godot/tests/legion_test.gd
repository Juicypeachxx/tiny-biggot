extends Node
## 34.2 THE LEGION PATH (scripts/combat/legion.gd). Run:
##   godot --headless --path . res://tests/legion_test.tscn -- --no-save
## Companion damage and speed reach wisps and skeletons; extra move speed turns into their attack
## speed (QUICK MARCH, MARCHING BOOTS); GRAVE MARSHAL lets more be out at once; the Bonecaller
## opens every fight with skeletons and ARMY OF BONES; classic is untouched.
## Prints "legion test: PASSED" or a FAIL line per problem.

var fails := 0
var notes := []

func fail(msg: String) -> void:
	fails += 1
	print("FAIL legion: ", msg)

func _hero(id: String) -> int:
	var all := GameData.heroes()
	for i in all.size():
		if all[i]["id"] == id:
			return i
	return 0

func _start(hero: String = "hexer") -> Player:
	G.hero_index = _hero(hero)
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
	p.x = 14.0 * TB.TS
	p.y = 12.0 * TB.TS
	return p

func _foes(p: Player, n: int = 4) -> Array:
	var out := []
	for i in n:
		var e := Combat.spawn_enemy("skeleton", p.x - 60.0 + i * 40.0, p.y - 60.0 - (i % 2) * 16.0, false, true)
		e.speed = 0.0
		e.max_hp = 1e7
		e.hp = 1e7
		out.append(e)
	return out

func _dealt(foes: Array) -> float:
	var d := 0.0
	for e in foes:
		d += 1e7 - e.hp
	return d

func _tick(n: int) -> void:
	var p := G.player
	for i in n:
		p.hp = p.max_hp
		p.x = 14.0 * TB.TS
		p.y = 12.0 * TB.TS
		Keys.tick()
		G.update(TB.DT)
		if G.state != &"play":
			G.state = &"play"
			G.tchoice = {}
			G.choice = {}

## Damage wisps deal in 6 s (the hero does not shoot).
func _wisps(dmg: float, spd: float) -> float:
	var p := _start()
	Meta.opts["autofire"] = false
	p.familiars = 3
	p.gf["minion_dmg"] = dmg
	p.gf["minion_speed"] = spd
	var foes := _foes(p)
	_tick(360)
	Meta.opts["autofire"] = true
	return _dealt(foes)

func _ready() -> void:
	await get_tree().process_frame
	seed(342)
	# The numbers.
	var p := _start()
	p.gf["march"] = 2.0
	p.speed = float(p.hero["speed"]) * 1.2
	if absf(Legion.speed(p) - 1.4) > 1e-6:
		fail("QUICK MARCH math: 20%% more speed and march 2 give x%.2f (want x1.4)" % Legion.speed(p))
	# Wisps: damage and speed.
	seed(1)
	var plain := _wisps(0.0, 0.0)
	seed(1)
	var strong := _wisps(1.0, 0.0)
	seed(1)
	var quick := _wisps(0.0, 1.0)
	if plain <= 0 or strong < plain * 1.6 or quick < plain * 1.5:
		fail("wisps: %.0f plain, %.0f with +100%% damage, %.0f with +100%% speed" % [plain, strong, quick])
	notes.append("3 wisps for 6 s: %.0f damage plain, %.0f with +100%% companion damage, %.0f with +100%% speed" % [plain, strong, quick])
	# Skeletons: GRAVE MARSHAL's cap and BONE BEACON's damage.
	p = _start()
	Meta.opts["autofire"] = false
	for i in 9:
		Summons.item_raise(p.x, p.y, 20.0, 5.0)
	var plain_n := Summons.thralls.filter(func(o): return o.get("item", false)).size()
	G.take_trait(Traits.by_id("h_marshal"))
	for i in 9:
		Summons.item_raise(p.x, p.y, 20.0, 5.0)
	var more_n := Summons.thralls.filter(func(o): return o.get("item", false)).size()
	if plain_n != 4 or more_n != 6:
		fail("skeletons out at once: %d, then %d with GRAVE MARSHAL (want 4, 6)" % [plain_n, more_n])
	G.take_trait(Traits.by_id("h_beacon"))
	Summons.item_raise(p.x, p.y, 20.0, 5.0)
	_foes(p)
	_tick(2)
	var boosted: Array = Summons.thralls.filter(func(o): return o.get("lg", false) and absf(o["dmg"] - 5.0 * 1.4) < 1e-6)
	if boosted.is_empty():
		fail("BONE BEACON: no skeleton deals +40%% (%s)" % [Summons.thralls.map(func(o): return o["dmg"])])
	Meta.opts["autofire"] = true
	# The Bonecaller.
	p = _start("bonecaller")
	var bones0 := Summons.thralls.size()
	if bones0 < 2:
		fail("the Bonecaller's fight opened with %d skeletons (want 2)" % bones0)
	Abilities.use(p)
	if Summons.thralls.size() < bones0 + 4:
		fail("ARMY OF BONES: %d skeletons (had %d)" % [Summons.thralls.size(), bones0])
	var foes := _foes(p)
	_tick(600)
	if _dealt(foes) <= 0:
		fail("the Bonecaller dealt nothing in 10 s")
	notes.append("the Bonecaller: %d skeletons after ARMY OF BONES, %.0f damage in 10 s" % [bones0 + 4, _dealt(foes)])
	# Classic.
	GameData.force_classic = true
	if Legion.speed(p) != 1.0 or Legion.dmg_mult(p) != 1.0 or Legion.cap_bonus(p) != 0:
		fail("classic has companion bonuses")
	GameData.force_classic = false
	for n in notes:
		print("[legion] ", n)
	print("legion test: PASSED" if fails == 0 else "legion test: %d FAILED" % fails)
	get_tree().quit()
