extends "res://tests/vfx_test.gd"
## Attack effects (scripts/render/afx.gd, the shot sheets in shot_batch.gd, enemy shots).
## Run: godot --headless --path . res://tests/afx_test.tscn -- --no-save
##   1. Art: every sheet and strip exists and divides into whole frames; every weapon family has
##      its run in the shot sheets.
##   2. Shots: every kind gets a rule in the new look; the shader's tables hold exactly what the
##      rule says (so the batch and the plain painter draw the same thing); the old look is
##      untouched; the two-sprite staff shot sits in two rows side by side.
##   3. The class tables: past 64 classes they are emptied and refilled, never left full.
##   4. A flood of spinning weapons never writes past the batch buffer.
##   5. Drawing only: each hooked piece of the rules run twice, effects on and off, leaves the
##      same foes, hero, shots, particles and random numbers.
##   6. Bounded: the flashes never pass their slots or their per-tick allowance, and all end.
##   7. The painters draw every swing, mark, guardian state and shot without an error, in both
##      looks and with FAST DRAWING on and off.
## Prints "afx test: PASSED" or a FAIL line per problem.

func _ready() -> void:
	await get_tree().process_frame
	afx_art()
	shot_rules()
	class_tables()
	await whirl_flood()
	afx_drawing_only()
	afx_bounded()
	await afx_painters()
	_fancy(true)
	print("afx test: PASSED" if fails == 0 else "afx test: %d FAILED" % fails)
	get_tree().quit(1 if fails > 0 else 0)

# ---------- 1 ----------
func afx_art() -> void:
	var rows := (ShotBatch.TAGS.size() + ShotBatch.PER_ROW - 1) / ShotBatch.PER_ROW
	for sheet in ShotBatch.SHEETS:
		if not Img.has(sheet):
			fail("missing shot sheet " + sheet)
			continue
		var tex := Img.t(sheet)
		var nf: int = ShotBatch.SHEETS[sheet]
		if tex.get_width() % (ShotBatch.PER_ROW * nf) != 0 or tex.get_height() % rows != 0:
			fail("%s is %dx%d: not %d families a row of %d frames, %d rows" % [sheet, tex.get_width(), tex.get_height(),
				ShotBatch.PER_ROW, nf, rows])
	# Every frame keeps a clear 1 px border, so a turned, zoomed shot never shows its neighbour.
	var cells := 0
	for sheet in ShotBatch.SHEETS:
		var img: Image = load("res://assets/graphics/%s.png" % sheet).get_image()
		var nf: int = ShotBatch.SHEETS[sheet]
		var w := img.get_width() / (ShotBatch.PER_ROW * nf)
		var h := img.get_height() / rows
		for ti in ShotBatch.TAGS.size():
			for f in nf:
				var x0 := (ti % ShotBatch.PER_ROW) * nf * w + f * w
				var y0 := (ti / ShotBatch.PER_ROW) * h
				var clear := true
				for x in w:
					if img.get_pixel(x0 + x, y0).a > 0.0 or img.get_pixel(x0 + x, y0 + h - 1).a > 0.0:
						clear = false
				for y in h:
					if img.get_pixel(x0, y0 + y).a > 0.0 or img.get_pixel(x0 + w - 1, y0 + y).a > 0.0:
						clear = false
				cells += 1
				if not clear:
					fail("%s: family %s frame %d touches the edge of its frame" % [sheet, ShotBatch.TAGS[ti], f])
	if cells < 400:
		fail("only %d shot frames were checked" % cells)
	for tag in Weapons.TAG_COLS:
		if not tag in ShotBatch.TAGS:
			fail("weapon family %s has no run in the shot sheets" % tag)
	for t in ShotBatch.PLAIN_TAG.values():
		if not t in ShotBatch.TAGS:
			fail("default family %s is not in the sheets" % t)
	for name in EBullets.SPRITES:
		if not Img.has("eb_" + name):
			fail("missing enemy shot strip eb_" + name)
		elif Img.t("eb_" + name).get_width() % 4 != 0:
			fail("eb_%s does not divide into 4 frames" % name)
		if not Afx.SHOT_COL.has(name):
			fail("no flash colour for enemy shot " + name)
	for i in Afx.STRIPS.size():
		var s := Vfx._strip(Afx.STRIPS[i])
		var tex: Texture2D = s[0]
		if not Img.has(Afx.STRIPS[i]) or s[1] * s[3] != tex.get_width():
			fail("strip %s is missing or does not divide into frames" % Afx.STRIPS[i])
	for n in ["swing_slash", "swing_slash_edge", "swing_thrust", "swing_whip", "fx_flare", "shot_lance", "shot_dart"]:
		if not Img.has(n):
			fail("missing graphic " + n)
	if Img.t("swing_slash").get_size() != Vector2(192, 48) or Img.t("swing_slash_edge").get_size() != Vector2(192, 48):
		fail("the slash strips are not four 48 px frames")
	if Img.t("swing_thrust").get_size() != Vector2(144, 11) or Img.t("swing_whip").get_size() != Vector2(192, 17):
		fail("the thrust or whip strip has the wrong size")
	for boss in BossAI.BOSS_PLANS:
		if not Afx.BOSS_COL.has(boss):
			fail("guardian %s has no colour" % boss)
		var stages: Array = BossAI.STAGE_PLANS.get(boss, [[], []])
		for st in BossAI.BOSS_PLANS[boss] + BossAI.THIRD_PLANS.get(boss, []) + stages[0] + stages[1]:
			if not (StringName(st) in Afx.CASTING or st in ["charge", "slam", "teleport", "beams", "palms", "ascend"] or StringName(st) in Finale.OWN_VISUAL):
				fail("guardian attack %s has no visual rule" % st)

# ---------- 2 ----------
const KINDS := ["bolt", "hex", "clod", "spark", "fire", "flask", "boomer", "spin", "disc", "pulse", "rail", "lance", "dart", "feather", "hatchet"]

func _shot(kind: String, tag: String, r: float = 2.5) -> PBullet:
	var b := Combat.new_pbullet()
	b.kind = kind
	b.tag = tag
	b.icon = Weapons.by_id("pithatchet")["sprite"]
	b.r = r
	b.x = 200.0
	b.y = 150.0
	b.vx = 120.0
	b.vy = 40.0
	b.life = 0.5
	b.max_life = 1.0
	return b

func shot_rules() -> void:
	_fancy(true)
	ShotBatch.reset_table()
	for kind in KINDS:
		for tag in ["", "pyre", "core", "not-a-family"]:
			var b := _shot(kind, tag)
			var dk := ShotBatch.classify(b)
			if b.ds < 0:
				fail("%s/%s has no rule in the new look" % [kind, tag])
				continue
			if dk >= ShotBatch.PLAIN:
				fail("%s/%s is not batched" % [kind, tag])
				continue
			var sp: Array = ShotBatch.specs[b.ds]
			var tex := Img.t(sp[0])
			if not (tex is AtlasTexture):
				fail("%s is not in the atlas" % sp[0])
				continue
			var cell: Rect2 = sp[1]
			var rg: Rect2 = (tex as AtlasTexture).region
			var want := Vector4(rg.position.x + cell.position.x, rg.position.y + cell.position.y, cell.size.x, cell.size.y)
			if ShotBatch._rects[dk] != want:
				fail("%s/%s: the shader would draw %s, the rule says %s" % [kind, tag, ShotBatch._rects[dk], want])
			var pm: Vector4 = ShotBatch._parms[dk]
			if not (is_equal_approx(pm.x, sp[3]) and is_equal_approx(pm.y, sp[4]) and is_equal_approx(pm.z, sp[5] + 10.0 * (sp[2] - 1))
					and is_equal_approx(pm.w, sp[6])):
				fail("%s/%s: the shader's numbers %s do not match the rule" % [kind, tag, pm])
			if ShotBatch.frames[dk] != sp[2] or sp[7] != dk:
				fail("%s/%s: frame count or class link is wrong" % [kind, tag])
			# The frame run must lie inside the sheet.
			if cell.position.x + cell.size.x * sp[2] > tex.get_width() or cell.position.y + cell.size.y > tex.get_height():
				fail("%s/%s: its frames run off the sheet" % [kind, tag])
			var spinning: bool = kind in ["boomer", "spin", "disc", "hatchet"]
			if spinning != (b.dw >= 0):
				fail("%s: whirl %s" % [kind, "missing" if spinning else "not wanted"])
			if b.dw >= 0 and ShotBatch.specs[b.dw][0] != "shot_whirl":
				fail("%s: its whirl rule is not a whirl" % kind)
			if kind == "hex":
				var big: int = sp[8]
				if big < 0 or ShotBatch.specs[big][7] != dk + 1:
					fail("the staff shot's big sprite is not the next row")
	# A family's own colours, and the plain ones for a weapon without a family.
	var a := _shot("bolt", "pyre")
	var c := _shot("bolt", "frost")
	var n := _shot("bolt", "")
	var k := _shot("bolt", "core")
	ShotBatch.classify(a); ShotBatch.classify(c); ShotBatch.classify(n); ShotBatch.classify(k)
	if a.dk == c.dk or a.dk == n.dk:
		fail("families share one bolt")
	if n.dk != k.dk:
		fail("no family and the core family should look the same")
	# Mines stay on the floor layer in both looks.
	var m := _shot("mine", "")
	if ShotBatch.classify(m) != ShotBatch.SKIP:
		fail("a mine is not skipped")
	# The old look: the old rules, no new-look fields.
	_fancy(false)
	for kind in KINDS:
		var b := _shot(kind, "pyre")
		var dk := ShotBatch.classify(b)
		if b.ds != -1 or b.dw != -1:
			fail("%s keeps a new-look rule with the option off" % kind)
		var plain: bool = kind in ["lance", "dart", "pulse", "rail"]
		if plain != (dk == ShotBatch.PLAIN):
			fail("%s: the old look %s batch it" % [kind, "should not" if plain else "should"])
	_fancy(true)

# ---------- 3 ----------
func class_tables() -> void:
	_fancy(true)
	ShotBatch.reset_table()
	ShotBatch._reset_frame = -100000
	var made := []
	# Every kind in every family: far more than 64 classes.
	for tag in ShotBatch.TAGS:
		for kind in ["bolt", "hex", "clod", "spark", "fire", "flask", "pulse", "rail", "spin"]:
			var b := _shot(kind, tag)
			ShotBatch.classify(b)
			made.append(b)
	if not ShotBatch.overflow:
		fail("136 classes fitted in 64 rows?")
	if ShotBatch._rects.size() > ShotBatch.MAX_CLASSES:
		fail("the tables grew past their size")
	var plain := 0
	for b: PBullet in made:
		if b.dk == ShotBatch.PLAIN:
			plain += 1
	if plain == 0:
		fail("nothing fell back to the plain painter with the tables full")
	if not ShotBatch.try_reset():
		fail("full tables were not emptied")
	if ShotBatch._rects.size() != 0 or ShotBatch.overflow:
		fail("the tables are not empty after the reset")
	for sp in ShotBatch.specs:
		if sp[7] != -1:
			fail("a rule kept its row through the reset")
			break
	# What is in use takes its place again.
	var again := _shot("bolt", "pyre")
	if ShotBatch.classify(again) >= ShotBatch.PLAIN:
		fail("a shot was not batched after the reset")
	var hx := _shot("hex", "frost")
	if ShotBatch.classify(hx) >= ShotBatch.PLAIN or ShotBatch.specs[ShotBatch.specs[hx.ds][8]][7] != hx.dk + 1:
		fail("the staff shot lost its two rows after the reset")
	# With the tables full, a spinning weapon still has its whirl rule (the plain painter draws it).
	ShotBatch.reset_table()
	for tag in ShotBatch.TAGS:
		for kind in ["bolt", "hex", "clod", "spark", "fire", "flask", "pulse", "rail"]:
			ShotBatch.classify(_shot(kind, tag))
	var late := _shot("disc", "blood")
	late.icon = Weapons.by_id("worldeater")["sprite"]
	if ShotBatch.classify(late) != ShotBatch.PLAIN or late.dw < 0 or late.ds < 0:
		fail("with the tables full a new spinning weapon lost its rule or its whirl")
	ShotBatch._reset_frame = -100000
	ShotBatch.try_reset()
	# A second overflow straight away does not empty them again (no thrashing).
	for tag in ShotBatch.TAGS:
		for kind in ["bolt", "hex", "clod", "spark", "fire", "flask", "pulse", "rail", "spin"]:
			ShotBatch.classify(_shot(kind, tag))
	if ShotBatch.try_reset():
		fail("the tables were emptied twice in a row")
	ShotBatch._reset_frame = -100000
	ShotBatch.reset_table()

# ---------- 4 ----------
func whirl_flood() -> void:
	var p := _arena()
	ShotBatch.reset_table()
	ShotBatch._reset_frame = -100000
	_fancy(true)
	Meta.opts["fast_draw"] = true
	var world := WorldView.new()
	add_child(world)
	for count in [10, 300, 900]:
		for b in G.pbullets:
			Combat.recycle(b)
		G.pbullets.clear()
		for i in count:
			var b := _shot("disc", "demolition")
			b.x = 40.0 + (i * 37) % 360
			G.pbullets.append(b)
		world._prepare_shots()
		world._prepare_shots()   # (a table reset, if one was due, happens at the start of a tick)
		var sb: ShotBatch = world._shots
		var shown: int = sb.used
		if shown != count + mini(count, ShotBatch.WHIRL_MAX):
			fail("%d spinning shots: %d instances written, want %d" % [count, shown, count + mini(count, ShotBatch.WHIRL_MAX)])
		if sb.buf.size() != sb.cap * ShotBatch.STRIDE or sb.cap < shown or sb.multimesh.instance_count != sb.cap:
			fail("the batch buffer is too small for what it shows")
		# The batch always draws its whole buffer; what is not in use is parked off-screen.
		if sb.multimesh.visible_instance_count != sb.cap:
			fail("%d spinning shots: the batch draws %d instances, not its whole buffer of %d" % [count, sb.multimesh.visible_instance_count, sb.cap])
		var loose := 0
		for i in range(shown, sb.cap):
			if sb.buf[i * ShotBatch.STRIDE + 3] != ShotBatch.PARK or sb.buf[i * ShotBatch.STRIDE + 7] != ShotBatch.PARK:
				loose += 1
		for i in shown:
			if sb.buf[i * ShotBatch.STRIDE + 3] == ShotBatch.PARK:
				loose += 1
		if loose > 0:
			fail("%d spinning shots: %d instances are not where they should be (in use on screen, the rest parked)" % [count, loose])
	# Fewer shots than the tick before: the ones no longer in use are parked again; none at all: nothing is drawn.
	for count in [5, 0]:
		for b in G.pbullets:
			Combat.recycle(b)
		G.pbullets.clear()
		for i in count:
			var b := _shot("bolt", "pyre")
			b.x = 40.0 + i * 20
			G.pbullets.append(b)
		world._prepare_shots()
		var sb2: ShotBatch = world._shots
		var stray := 0
		for i in range(count, sb2.cap):
			if sb2.buf[i * ShotBatch.STRIDE + 3] != ShotBatch.PARK:
				stray += 1
		if sb2.used != count or stray > 0 or sb2.multimesh.visible_instance_count != (sb2.cap if count > 0 else 0):
			fail("after a flood, %d shots: %d written, %d left on screen, %d instances drawn" % [count, sb2.used, stray, sb2.multimesh.visible_instance_count])
	# The tables fill while shots with whirls are in the air, some drawn by the plain painter:
	# the reset must leave nothing pointing at a row that is gone (this once threw an error).
	ShotBatch.reset_table()
	ShotBatch._reset_frame = -100000
	for b in G.pbullets:
		Combat.recycle(b)
	G.pbullets.clear()
	var i := 0
	for tag in ShotBatch.TAGS:
		for kind in ["bolt", "hex", "clod", "spark", "fire", "flask", "pulse", "rail", "spin", "disc"]:
			var b := _shot(kind, tag)
			b.x = 40.0 + (i * 37) % 360
			i += 1
			G.pbullets.append(b)
	var layer := DrawLayer.new(world._paint_pbullets)
	add_child(layer)
	var resets := 0
	for tick in 4:
		var before := ShotBatch._reset_frame
		world._prepare_shots()
		if ShotBatch._reset_frame != before:
			resets += 1
		for b: PBullet in world._plain:
			if b.dw >= ShotBatch.specs.size() or b.ds >= ShotBatch.specs.size():
				fail("a shot points at a rule that does not exist")
		layer.queue_redraw()
		await get_tree().process_frame
	if resets != 1:
		fail("%d table resets in four ticks of an overfull screen, want exactly one" % resets)
	layer.queue_free()
	ShotBatch._reset_frame = -100000
	ShotBatch.reset_table()
	for b in G.pbullets:
		Combat.recycle(b)
	G.pbullets.clear()
	world.queue_free()
	# The plain painter rounds what the shader gets as 16-bit floats the same way.
	# (Between 128 and 256 a 16-bit float moves in steps of an eighth.)
	var hv := ShotBatch.half(158.355)
	if ShotBatch.half(0.5) != 0.5 or ShotBatch.half(-96.0) != -96.0 or hv == 158.355 or absf(hv - 158.355) > 0.126 or fmod(hv * 8.0, 1.0) != 0.0:
		fail("half() does not round like a 16-bit float (158.355 became %s)" % hv)
	# A lane ends at the wall's face, not inside it.
	for a in [0.0, 0.7, PI * 0.5, 2.4, PI, -1.1]:
		var d := Afx._reach(p.x, p.y, a, 352.0, World.M_FLYER)
		var hx := p.x + cos(a) * d
		var hy := p.y + sin(a) * d
		if World.solid(G.room, floori(hx / TB.TS), floori(hy / TB.TS), World.M_FLYER):
			fail("a lane at angle %.1f ends inside a wall" % a)
		if d < 351.0 and not World.solid(G.room, floori((hx + cos(a) * 1.5) / TB.TS), floori((hy + sin(a) * 1.5) / TB.TS), World.M_FLYER):
			fail("a lane at angle %.1f stops short of the wall" % a)
	# Swings alternate, and a swing keeps its direction however long it is frozen.
	Afx.reset()
	var s1 := { "kind": "slash", "x": 1.0, "y": 1.0, "a": 0.0, "r": 30.0, "arc": 2.0, "t": 0.14, "max": 0.14, "tag": "" }
	var s2 := s1.duplicate()
	G.swings = [s1]
	Afx.update(p, false)
	var first: bool = Afx._flips[0]
	G.swings = [s1, s2]
	Afx.update(p, false)
	if Afx._flips.size() != 2 or Afx._flips[0] != first or Afx._flips[1] == first:
		fail("swings do not alternate, or one changed direction")
	G.time += 1.0     # a hit freezes the swing while the clock runs on
	if Afx._flips[0] != first or not is_same(Afx._swings[0], s1):
		fail("a frozen swing changed direction")
	# The game drops a finished swing from its list after update() has seen it, so the others
	# move up a place before they are drawn: each must still be drawn the way it was given.
	var s3 := s1.duplicate()
	G.swings = [s1, s2, s3]
	Afx.update(p, false)
	var d2 := Afx.mirrored(s2, 0)
	var d3 := Afx.mirrored(s3, 0)
	G.swings = [s2, s3]                   # s1 has ended; the painter runs before the next update
	if d2 == first or d3 != first or Afx.mirrored(s2, 0) != d2 or Afx.mirrored(s3, 0) != d3:
		fail("a swing changed direction when an older one ended")
	# A swing made after update() this tick is drawn the way update() will give it next tick.
	var s4 := s1.duplicate()
	var s5 := s1.duplicate()
	G.swings = [s2, s3, s4, s5]
	var d4 := Afx.mirrored(s4, 0)
	var d5 := Afx.mirrored(s5, 1)
	Afx.update(p, false)
	if Afx._seen(s4) < 0 or Afx.mirrored(s4, 0) != d4 or Afx.mirrored(s5, 0) != d5 or d4 == d5 or d4 == d3:
		fail("a swing not yet seen was drawn one way and then given the other")
	if Afx.mirrored(s2, 0) != d2 or Afx.mirrored(s3, 0) != d3:
		fail("a swing changed direction when new ones began")
	G.swings = []
	Afx.update(p, false)
	if not Afx._flips.is_empty():
		fail("finished swings are still remembered")

# ---------- 5 ----------
func _restore(p: Player) -> void:
	super._restore(p)
	for pr in p.procs:   # 20.1: the Hexer's own passive counts attacks; both halves start from the same count
		if pr is Dictionary and pr.has("count"):
			pr["count"] = 0
	EBullets.clear()
	p.x = 14.0 * TB.TS
	p.y = 9.5 * TB.TS
	p.aim_a = 0.0

func _snapshot(p: Player) -> String:
	var s := super._snapshot(p)
	var sum := 0.0
	for i in EBullets.n:
		sum += EBullets.bx[i] + EBullets.by[i] * 3.0 + EBullets.bvx[i] * 5.0
	var shots := 0.0
	for b: PBullet in G.pbullets + G.new_pbullets:
		shots += b.x + b.y * 3.0 + b.dmg * 7.0 + b.life
	return s + "\n%d %.3f %d %.3f %d" % [EBullets.n, sum, G.pbullets.size() + G.new_pbullets.size(), shots, G.swings.size()]

func afx_drawing_only() -> void:
	var p := _arena()
	_foes.clear()
	for i in 6:
		_foes.append(_foe(0.0, 0.0))
	var e: Enemy = _foes[3]     # 16 px right of the hero, 20 px down
	for id in ["banesabre", "warlance", "shackleflail", "prismrod"]:
		Weapons.equip_weapon(p, Weapons.by_id(id))
		_probe(p, "attack with " + id, func():
			p.aim_a = TB.ang_to(p, e)
			Combat.player_shoot(p, p.aim_a, false))
	Weapons.equip_weapon(p, Weapons.by_id("repeater"))
	_probe(p, "a shot hitting", func():
		var b := Combat.spawn_pbullet(p, TB.ang_to(p, e))
		b.x = e.x - 2.0
		b.y = e.y
		Combat.update_pbullets(TB.DT))
	_probe(p, "a critical hit", func(): Combat.damage_enemy(e, 5.0, { "force_crit": true }))
	_probe(p, "an enemy ring", func(): Combat.ering(e.x, e.y, 12, 70, 0.3, "fire"))
	_probe(p, "an enemy fan", func(): Combat.efan(e.x, e.y, 1.0, 5, 0.6, 90, "bone"))
	_probe(p, "a fuse shot bursting", func():
		Combat.eshot(e.x, e.y, 0.0, 60, "fireBig", 4, 0.0, "fire")
		EBullets.update(TB.DT))
	# A guardian's attacks, a few ticks of each from the same start.
	for row in [["colossus", &"slam", 60], ["tyrant", &"charge", 120], ["regent", &"teleport", 70], ["regent", &"beams", 80],
			["frozenabbot", &"palms", 40], ["colossus", &"ring", 40]]:
		_probe(p, "guardian %s %s" % [row[0], row[1]], func():
			var boss := Combat.spawn_boss(row[0])
			boss.state = row[1]
			boss.st = 0.0
			boss.sub = 0
			boss.t = 0.0
			boss.x = p.x + 60.0
			boss.y = p.y - 40.0
			for k in row[2]:
				BossAI.update_boss(boss, TB.DT)
				boss.t -= TB.DT
			G.boss = null, false)
	# A knight's crash into a wall.
	_probe(p, "a knight crashing", func():
		var kn := Combat.spawn_enemy("knight", 3.0 * TB.TS, p.y, false, true)
		kn.state = &"charge"
		kn.st = 0.9
		kn.ca = PI
		for k in 40:
			EnemyAI.ai_knight(kn, TB.DT, p), false)
	for dead in G.enemies:
		dead.hp = 0
	G.enemies.clear()
	_foes.clear()
	Weapons.equip_weapon(p, Weapons.by_id("hexwand"))

# ---------- 6 ----------
func afx_bounded() -> void:
	var p := _arena()
	_fancy(true)
	var most := 0
	for tick in 60:
		for k in 40:
			Afx.hit(100.0 + k, 100.0, "pyre")
			Afx.crit(100.0 + k, 110.0)
			Afx.cut(100.0 + k, 120.0, 0.5, k % 2 == 0)
			Afx.cast(100.0 + k, 130.0, "fire")
			Afx.dust(100.0 + k, 140.0)
		if Afx._made > Afx.PER_TICK:
			fail("%d flashes started in one tick" % Afx._made)
		most = maxi(most, Afx.live())
		Afx.update(p, true)
	if most > Afx.SLOTS or most == 0:
		fail("%d flashes alive at once" % most)
	for tick in 20:
		Afx.update(p, false)
	if Afx.live() != 0:
		fail("a flash never ended")
	# A muzzle flash for a gun, none for a blade.
	Weapons.equip_weapon(p, Weapons.by_id("repeater"))
	Afx.update(p, true)
	if Afx.live() != 1:
		fail("no muzzle flash for a crossbow")
	Afx.reset()
	Weapons.equip_weapon(p, Weapons.by_id("banesabre"))
	Afx.update(p, true)
	if Afx.live() != 0:
		fail("a muzzle flash for a sword")
	# Off: nothing.
	_fancy(false)
	Afx.hit(1, 1, "pyre"); Afx.crit(1, 1); Afx.cut(1, 1, 0.0, true); Afx.cast(1, 1, "red"); Afx.dust(1, 1); Afx.warp(1, 1)
	Weapons.equip_weapon(p, Weapons.by_id("repeater"))
	Afx.update(p, true)
	if Afx.live() != 0 or not Vfx.anims.is_empty():
		fail("a flash was made with the option off")
	_fancy(true)
	Weapons.equip_weapon(p, Weapons.by_id("hexwand"))

# ---------- 7 ----------
var _apainted := 0

func afx_painters() -> void:
	var p := _arena()
	var world := WorldView.new()
	add_child(world)
	# One guardian in each state that has a picture, a knight winding up, a marksman aiming.
	var states := [[&"charge", 1, true], [&"charge", 2, false], [&"slam", 1, false], [&"palms", 1, false], [&"beams", 1, false],
		[&"beams", 2, false], [&"spiral", 0, false], [&"summon", 1, false]]
	var bosses: Array = []
	for i in states.size():
		var boss := Combat.spawn_boss(["tyrant", "regent", "colossus", "umbralsun"][i % 4])
		boss.spawn_t = 0.0
		boss.x = 60.0 + i * 44.0
		boss.y = 90.0
		boss.state = states[i][0]
		boss.sub = states[i][1]
		boss.has_telegraph = states[i][2]
		boss.telegraph = 0.7
		boss.ca = 0.7
		boss.st = 0.3
		boss.to = Vector2(boss.x + 20.0, boss.y + 60.0)
		if boss.state == &"beams":
			boss.beams = [0.3, 1.2, 2.0]
		bosses.append(boss)
	G.boss = null
	var kn := Combat.spawn_enemy("knight", 100.0, 200.0, false, true)
	kn.state = &"tele"
	kn.st = 0.3
	kn.ca = 0.4
	var kc := Combat.spawn_enemy("knight", 140.0, 220.0, false, true)
	kc.state = &"charge"
	kc.ca = 2.0
	var gun := Combat.spawn_enemy("skeleton", 200.0, 200.0, false, true)
	gun.state = &"aim"
	gun.has_telegraph = true
	gun.telegraph = 3.0
	gun.st = 0.2
	for i in EBullets.SPRITES.size() * 3:
		EBullets.add(40.0 + i * 9.0, 60.0, 10, 10, EBullets.SPRITES[i % EBullets.SPRITES.size()], 2.5)
	EBullets.compact()
	for i in KINDS.size() * 2:
		var b := _shot(KINDS[i % KINDS.size()], ["", "frost"][i / KINDS.size()], 2.5 + (i % 3) * 2.0)
		b.x = 50.0 + i * 12.0
		G.pbullets.append(b)
	G.pbullets.append(_shot("mine", ""))
	var layer := DrawLayer.new(func(ci):
		Afx.draw_ground(ci, G.time)
		Afx.draw_marks(ci, G.time)
		Afx.draw_swings(ci, G.time)
		Afx.draw_glow(ci)
		EBullets.draw(ci)
		world._paint_pbullets(ci)
		world._paint_swings(ci)
		world._paint_fx(ci)
		world._paint_glow(ci)
		world._paint_ents(ci)
		_apainted += 1)
	add_child(layer)
	for look in [true, false]:
		_fancy(look)
		for fast in [true, false]:
			Meta.opts["fast_draw"] = fast
			for tick in 12:
				G.swings = [
					{ "kind": "slash", "x": p.x, "y": p.y, "a": 0.4 * tick, "r": 34.0, "arc": 1.9, "t": 0.14 - tick * 0.011, "max": 0.14, "tag": "fury" },
					{ "kind": "thrust", "x": p.x, "y": p.y, "a": 1.0, "len": 58.0, "width": 8.0, "t": 0.12 - tick * 0.01, "max": 0.12, "tag": "" },
					{ "kind": "whip", "x": p.x, "y": p.y, "a": 2.0, "len": 70.0, "width": 6.0, "t": 0.12 - tick * 0.01, "max": 0.12, "tag": "malice" },
					{ "kind": "beam", "x": p.x, "y": p.y, "a": 3.0, "len": 120.0, "t": 0.1, "max": 0.1, "tag": "arcane" },
				]
				if look:
					Afx.hit(p.x, p.y, "frost"); Afx.crit(p.x, p.y); Afx.cut(p.x, p.y, 1.0, tick % 2 == 0)
					Afx.cast(p.x, p.y, "dark"); Afx.dust(p.x, p.y)
				G.time += TB.DT
				for b: PBullet in G.pbullets:
					b.age += TB.DT
				Juice.update(TB.DT, p)
				world._prepare_shots()
				layer.queue_redraw()
				await get_tree().process_frame
	if _apainted == 0:
		print("[afx] this run does not draw (headless without a canvas): painters not exercised")
	else:
		print("[afx] painters ran %d times" % _apainted)
	Meta.opts["fast_draw"] = true
	layer.queue_free()
	world.queue_free()
	G.swings = []
	EBullets.clear()
	for b in G.pbullets:
		Combat.recycle(b)
	G.pbullets.clear()
	for e in G.enemies:
		e.hp = 0
	G.enemies.clear()
