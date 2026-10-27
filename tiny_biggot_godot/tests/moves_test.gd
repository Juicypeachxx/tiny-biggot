extends Node
## 66.2 Heroes and guardians walk and attack (scripts/render/moves.gd). Run:
##   godot --headless --path . res://tests/moves_test.tscn -- --no-save
## 1 Every strip in assets/graphics_hd/anim/ belongs to a picture, has frames in both rows, and each
##   frame is drawn at that picture's own size with something in it.
## 2 Every hero has a strip. 3 A hero standing is itself, walking is a walk frame, just fired is an
##   attack frame. 4 A guardian at rest is itself, moving walks, attacking plays the attack once.
## Prints "moves test: PASSED" or a FAIL line per problem.

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL moves: ", msg)

func _ready() -> void:
	await get_tree().process_frame
	var strips := 0
	for f in DirAccess.get_files_at(Moves.DIR):
		var base := f.trim_suffix(".import").trim_suffix(".remap")
		if not base.ends_with(".png") or f != base:
			continue
		var pic := base.trim_suffix(".png")
		strips += 1
		if not Img.has(pic):
			fail("%s: a strip with no picture" % pic)
			continue
		var n := Moves.count(pic)
		if n < 4:
			fail("%s: %d frames" % [pic, n])
			continue
		for row in 2:
			for i in n:
				var fn := Moves._name(pic, row, i)
				var tex := Img.t(fn)
				if tex.get_size() != Img.t(pic).get_size():
					fail("%s: drawn at %s, not %s" % [fn, tex.get_size(), Img.t(pic).get_size()])
				elif tex.get_image().get_used_rect().size == Vector2i.ZERO:
					fail("%s: empty" % fn)
	for h: Dictionary in GameData.heroes():
		if Moves.count(h["sprite"]) == 0:
			fail("hero %s has no strip" % h["sprite"])
	G.hero_index = 0
	G.new_run()
	var p: Player = G.player
	var pic: String = p.hero["sprite"]
	p.moving = false
	Juice.recoil = 0.0
	if Moves.hero(p, pic, 1.0) != pic:
		fail("a hero standing is not itself")
	p.moving = true
	if not Moves.hero(p, pic, 1.0).begins_with(pic + "@w"):
		fail("a walking hero: %s" % Moves.hero(p, pic, 1.0))
	p.moving = false
	Juice.recoil = 0.5
	if not Moves.hero(p, pic, 1.0).begins_with(pic + "@a"):
		fail("a hero who just fired: %s" % Moves.hero(p, pic, 1.0))
	Juice.recoil = 0.0
	var e := Enemy.new()
	e.uid = 9999
	e.boss = "colossus"
	e.hp = 10.0
	e.state = &"idle"
	if Moves.boss(e, "colossus", 1.0) != "colossus":
		fail("a guardian at rest is not itself")
	e.x += 5.0
	if not Moves.boss(e, "colossus", 1.05).begins_with("colossus@w"):
		fail("a moving guardian does not walk")
	e.state = &"slam"
	var first := Moves.boss(e, "colossus", 2.0)
	var later := Moves.boss(e, "colossus", 9.0)
	if first != "colossus@a0" or later != "colossus@a%d" % (Moves.count("colossus") - 1):
		fail("an attack: %s then %s" % [first, later])
	print("[moves] %d strips" % strips)
	print("moves test: PASSED" if fails == 0 else "moves test: %d FAILED" % fails)
	get_tree().quit(0 if fails == 0 else 1)
