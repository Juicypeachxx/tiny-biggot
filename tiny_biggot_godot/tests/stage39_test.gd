extends Node
## Stage 39 MORE TO FIND (39.1 helmets and body armour, 39.2 magic weapons, 39.3 companions: the rows
## marked 39 in scripts/data/gear.gd, weapons.gd and relics.gd; pictures by tools/art/stage39_items.py).
## Run:
##   godot --headless --path . res://tests/stage39_test.tscn -- --no-save
## Every new helmet and body armour goes into its slot and comes off leaving the hero as before;
## every magic weapon scales with INT first and hurts foes in a fight; every companion brings a
## helper or makes the helpers stronger, and the "every fight" ones come only into a room with a
## fight; every picture is there and the font can draw every word.
## Prints "stage39 test: PASSED" or a FAIL line per problem.

const HEADS := ["featheredcap", "ironsallet", "pointedhat", "bullhelm", "pumpkinhead", "thorncrown", "plaguemask",
	"minerscap", "whisperhood", "kabuto", "circlet", "froghood", "beeveil", "chefhat", "astrohood", "skullhelm"]
const BODIES := ["wandercape", "chainmail", "saffronrobe", "starrobe", "wolfpelt", "alchemistapron", "knightplate",
	"shadowleathers", "priestvestment", "cultistrobe", "barddoublet", "gladiatorharness", "iceplate", "embercoat",
	"feathercloak", "bonearmor"]
const MAGIC := ["acornwand", "rowanwand", "thornwand", "swamprod", "rimewand", "bloodrod", "chimestaff", "tidescepter",
	"stargazer", "sunorb", "crystalball", "voidstaff", "mooncandle", "galeharp", "squeezebox", "duskbell", "glasslute",
	"dawnbeads", "emberscroll", "sparkscroll", "mothbook"]
const PALS := ["acornpal", "glowshroom", "tinyskull", "berrysprite", "beetleshell", "ravenfeather", "beejar", "luckyfrog",
	"ghostlamp", "clockmouse", "dragonegg", "snailshell", "fireflyjar", "wiseowl", "hermitcrab"]

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL stage39: ", msg)

func _start() -> Player:
	G.hero_index = 0
	G.new_run()
	G.floor_index = 2
	G.start_floor()
	G.god = true
	var p := G.player
	p.oath_picks = 0
	p.pending = 0
	_room("treasure")
	G.state = &"play"
	return p

func _room(kind: String) -> void:
	G.enter_room(World.make_room(G.floor_d, kind, "", "s", { "no_secret": true }))
	G.room.objects.clear()
	G.enemies.clear()
	G.room.waves_left = 0

func _font(id: String, txt: String) -> void:
	for ch in txt:
		if not ch in Gfx.FONT_CHARS:
			fail("%s: the font cannot draw %s" % [id, ch])

func _snap(p: Player) -> String:
	var gf := {}
	for k in p.gf:
		if absf(p.gf[k]) > 0.0001:
			gf[k] = snappedf(p.gf[k], 0.0001)
	return str([p.max_hp, snappedf(p.dmg, 0.0001), snappedf(p.rate, 0.0001), snappedf(p.speed, 0.001), snappedf(p.crit, 0.0001),
		p.luck, p.orbitals, p.pierce, p.dodge_charges, snappedf(p.burn, 0.0001), snappedf(p.chill, 0.0001), snappedf(p.chain, 0.0001),
		snappedf(p.evade, 0.0001), p.thorns, p.armor, snappedf(p.gold_mult, 0.0001), snappedf(p.xp_mult, 0.0001),
		snappedf(p.shot_speed, 0.0001), p.a_str, p.a_dex, p.a_int, gf, p.procs.size()])

## Takes off what is in a slot (the same path a swap uses).
func _take_off(p: Player, slot: String) -> void:
	var g = p.gear.get(slot)
	if g == null:
		return
	Weapons.apply_tuples(p, g["stats"], -1, "g:" + g["id"])
	Weapons.apply_hooks(p, g["hooks"], -1)
	if not g["effects"].is_empty():
		Effects.apply_equipment(p, g["effects"], -1, "gfx:" + g["id"])
	p.gear[slot] = null
	Gear.update_sets(p, g["set"], -1)
	if g["new"]:
		Effects.recount_tags(p)

## Four foes in front of the hero where _tick holds them, in an open room. (Stage 57: the foes used to
## come in front of the door the hero walked in by, 64 px lower, and the room's own pillars could
## push some far away or stand in the way: 3 runs in 40 had a weapon that hurt no foe.)
func _foes(p: Player, n: int = 4) -> Array:
	p.x = 14.0 * TB.TS
	p.y = 12.0 * TB.TS
	for r in range(4, 16):
		for c in range(2, 26):
			G.room.grid[r * TB.COLS + c] = World.T_FLOOR
	var out := []
	for i in n:
		var e := Combat.spawn_enemy("skeleton", p.x - 60.0 + i * 40.0, p.y - 50.0 - (i % 2) * 16.0, false, true)
		e.speed = 0.0
		e.max_hp = 1e7
		e.hp = 1e7
		e.spawn_t = 0.0
		out.append(e)
	return out

func _tick(n: int, full_hp: bool = true) -> void:
	var p := G.player
	for i in n:
		if full_hp:
			p.hp = p.max_hp
		p.x = 14.0 * TB.TS
		p.y = 12.0 * TB.TS
		Keys.tick()
		G.update(TB.DT)
		if G.state != &"play":
			G.state = &"play"
			G.tchoice = {}
			G.choice = {}

func _ready() -> void:
	var p := _start()
	# 39.1 Helmets and body armour.
	if HEADS.size() + BODIES.size() < 30:
		fail("only %d helmets and armours" % (HEADS.size() + BODIES.size()))
	_take_off(p, "head")
	_take_off(p, "body")
	var base := _snap(p)
	for id in HEADS + BODIES:
		var g: Dictionary = Gear.by_id(id)
		var slot := "head" if id in HEADS else "body"
		if g["slot"] != slot:
			fail("%s is for the %s, not the %s" % [id, g["slot"], slot])
		if not Img.has(g["sprite"]):
			fail("%s has no picture %s" % [id, g["sprite"]])
		_font(id, g["name"] + g["desc"])
		Gear.equip_gear(p, g)
		if p.gear.get(slot) != g:
			fail("%s did not go on" % id)
		_take_off(p, slot)
		if _snap(p) != base:
			fail("%s left a trace: %s -> %s" % [id, base, _snap(p)])
			base = _snap(p)

	# 39.2 Magic weapons: INT first, and they hurt foes.
	Meta.opts["autofire"] = true
	var hurt := 0
	for id in MAGIC:
		var w: Dictionary = Weapons.by_id(id)
		if not Img.has(w["sprite"]):
			fail("%s has no picture %s" % [id, w["sprite"]])
		_font(id, w["name"] + w["desc"])
		var gr := Attributes.scaling(w)
		var c: Dictionary = Attributes.COEF
		if c[gr["int"]] < c[gr["str"]] or c[gr["int"]] < c[gr["dex"]] or c[gr["int"]] < 0.6:
			fail("%s scales %s/%s/%s: INT is not its first stat" % [id, gr["str"], gr["dex"], gr["int"]])
		_room("combat")
		G.locked = true
		Weapons.equip_weapon(p, w)
		var foes := _foes(p)
		_tick(150)
		var dealt := 0.0
		for e in foes:
			dealt += 1e7 - e.hp
		if dealt <= 0.0:
			fail("%s hurt no foe in 2.5 s" % id)
		else:
			hurt += 1

	# 39.3 Companions.
	Meta.opts["autofire"] = false
	for id in PALS:
		var r: Dictionary = Relics.by_id(id)
		if not Img.has(r["sprite"]):
			fail("%s has no picture %s" % [id, r["sprite"]])
		_font(id, r["name"] + r["desc"])
		if not r["tags"].has("swarm") and not r["tags"].has("bulwark"):
			fail("%s is not a companion (tags %s)" % [id, r["tags"]])
	var helpers := {}
	for id in PALS:
		p = _start()
		_room("combat")
		G.locked = true
		var fam0 := p.familiars
		var orb0 := p.orbitals
		var cap0 := Legion.cap_bonus(p)
		var dmg0 := Legion.dmg_mult(p)
		var spd0 := Legion.speed(p)
		Effects.apply(p, Relics.by_id(id)["effects"], 1, "relic:" + id)
		var more := []
		if p.familiars > fam0:
			more.append("wisps")
		if p.orbitals > orb0:
			more.append("moons")
		if Legion.cap_bonus(p) > cap0:
			more.append("cap")
		if Legion.dmg_mult(p) > dmg0 or p.fam_dmg > 0.0:
			more.append("damage")
		if Legion.speed(p) > spd0:
			more.append("speed")
		# Into a room with a fight, and into one without.
		_room("treasure")
		var calm := Summons.turrets.size() + Summons.thralls.size() + G.temp_fams.size()
		_room("combat")
		var fight := Summons.turrets.size() + Summons.thralls.size() + G.temp_fams.size()
		if calm > 0:
			fail("%s brought a helper into a room with no fight" % id)
		if fight > 0:
			more.append("each fight")
		if id == "beejar":
			for i in 40:
				Effects.fire("on_kill", { "enemy": null })
			if not G.temp_fams.is_empty():
				more.append("kills")
		if id == "berrysprite":
			G.locked = true
			_foes(p)
			p.hp = 2
			_tick(26 * 60, false)
			if p.hp > 2:
				more.append("heals")
		if id == "dragonegg":
			G.locked = true
			var foes := _foes(p)
			_tick(7 * 60)
			if foes.any(func(e): return e.burn_t > 0):
				more.append("fire")
		helpers[id] = more
		if more.is_empty():
			fail("%s brought nothing" % id)
	for id in ["glowshroom", "tinyskull", "ravenfeather", "clockmouse"]:
		if not helpers[id].has("each fight"):
			fail("%s brought no helper into a fight" % id)
	print("[stage39] %d helmets, %d armours, %d magic weapons (%d hurt foes), %d companions: %s" % [HEADS.size(),
		BODIES.size(), MAGIC.size(), hurt, PALS.size(), helpers])
	Meta.opts["autofire"] = true

	print("stage39 test: PASSED" if fails == 0 else "stage39 test: %d FAILED" % fails)
	get_tree().quit()
