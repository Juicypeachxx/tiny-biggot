class_name BossAI
extends RefCounted
## Guardians (port of Combat.rb BOSS_PLANS / update_boss).

const BOSS_PLANS := {
	"colossus": ["ring", "volley", "slam", "ring", "summon"],
	"sporemother": ["spiral", "burst", "cloud", "summon", "spiral", "burst"],
	"librarian": ["pages", "tide", "ring", "summon", "pages", "tide"],
	"tyrant": ["charge", "sweep", "embers", "charge", "sweep"],
	"rimewarden": ["freeze", "charge", "hail", "shards", "freeze", "charge"],
	"regent": ["teleport", "beams", "spiral", "teleport", "summon", "beams", "curtain"],
	# Stage 7 guardians (new attacks: bogspit, arrowrain, palms, gunline, eclipse).
	"bogmatriarch": ["bogspit", "spiral", "summon", "cloud", "bogspit", "burst"],
	"ashwarlord": ["charge", "arrowrain", "sweep", "summon", "embers", "charge", "arrowrain"],
	"frozenabbot": ["palms", "freeze", "hail", "palms", "shards", "summon"],
	"crowking": ["teleport", "gunline", "spiral", "summon", "gunline", "beams"],
	"umbralsun": ["eclipse", "beams", "curtain", "teleport", "summon", "eclipse", "sweep", "hail"],
	# ROADMAP 4.7 part C (new attacks: halo, verdict, brimstone, hellgate, ink, rewrite).
	"judge": ["halo", "verdict", "beams", "summon", "halo", "spiral", "verdict", "teleport"],
	"cinderking": ["brimstone", "sweep", "hellgate", "summon", "embers", "brimstone", "charge"],
	"unwritten": ["ink", "halo", "brimstone", "rewrite", "eclipse", "verdict", "summon", "ink", "hellgate"],
	# The Holy Cow (brazil.gd): two halves, then it rises again (THIRD_PLANS).
	"holycow": ["moo", "milkrain", "charge", "udder", "moo", "summon"],
}
## Souls-like stages (his ask, 6 Oct; expanded game only, the original game's guardians are as
## they were). Stage 1 is the plan above; at two thirds of its health a guardian breaks into stage
## 2, at one third into stage 3, each with its own plan. A break: it cannot be hurt for a moment,
## every shot vanishes, it roars, the banner speaks, a shockwave. Stage 2 rests less; stage 3 is
## chaos: almost no rest, attacks chain, and a desperation pulse every 3.5 s.
const STAGE_PLANS := {
	"colossus": [["slam", "wall", "volley", "ring", "cross"], ["slam", "flower", "wall", "barrage", "slam", "cross"]],
	"sporemother": [["spiral", "cloud", "flower", "burst", "summon"], ["flower", "barrage", "cloud", "wall", "spiral"]],
	"librarian": [["pages", "tide", "wall", "ink", "summon"], ["ink", "barrage", "pages", "wall", "tide"]],
	"tyrant": [["charge", "embers", "hellgate", "sweep", "cross"], ["charge", "hellgate", "barrage", "brimstone", "charge"]],
	"rimewarden": [["freeze", "hail", "wall", "shards", "charge"], ["freeze", "flower", "hail", "barrage", "shards"]],
	"regent": [["teleport", "beams", "curtain", "wall", "summon", "halo"], ["teleport", "barrage", "curtain", "flower", "beams", "halo"]],
	"bogmatriarch": [["bogspit", "flower", "cloud", "summon", "brimstone"], ["bogspit", "barrage", "flower", "brimstone", "wall"]],
	"ashwarlord": [["charge", "arrowrain", "cross", "embers", "summon"], ["charge", "arrowrain", "barrage", "hellgate", "cross"]],
	"frozenabbot": [["palms", "freeze", "wall", "hail", "shards"], ["palms", "flower", "barrage", "freeze", "wall"]],
	"crowking": [["teleport", "gunline", "wall", "spiral", "summon", "cross"], ["teleport", "gunline", "barrage", "flower", "cross"]],
	"umbralsun": [["eclipse", "beams", "wall", "curtain", "teleport", "halo"], ["eclipse", "barrage", "flower", "curtain", "verdict", "ink"]],
	"judge": [["halo", "verdict", "wall", "beams", "summon"], ["halo", "barrage", "verdict", "flower", "cross"]],
	"cinderking": [["brimstone", "hellgate", "wall", "sweep", "charge"], ["hellgate", "barrage", "brimstone", "flower", "charge"]],
	"unwritten": [["ink", "rewrite", "wall", "halo", "brimstone", "verdict"], ["rewrite", "barrage", "flower", "ink", "hellgate", "eclipse"]],
	"holycow": [["moo", "milkrain", "wall", "udder", "charge"], ["moo", "barrage", "milkrain", "flower", "udder"]],
}
const STAGE_LINE := {
	"colossus": ["ITS RIBS CRACK OPEN", "THE BONES ARE ALL THAT IS LEFT"], "sporemother": ["SHE BURSTS INTO BLOOM", "THE WHOLE GROTTO BREATHES SPORES"],
	"librarian": ["THE TIDE RISES IN THE STACKS", "EVERY BOOK SCREAMS AT ONCE"], "tyrant": ["THE FORGE ROARS", "MOLTEN AND FURIOUS"],
	"rimewarden": ["THE ICE THICKENS", "A WHITEOUT FALLS"], "regent": ["THE CROWN BURNS PALE", "THE REGENT ABANDONS ALL COURTESY"],
	"bogmatriarch": ["THE MIRE STIRS", "THE MARSH ITSELF RISES"], "ashwarlord": ["THE WARHORNS SOUND", "NO RETREAT. NO SURRENDER"],
	"frozenabbot": ["THE PRAYER TURNS COLD", "THE MONASTERY BELL SHATTERS"], "crowking": ["THE MURDER GATHERS", "THE ROOFTOPS GO DARK"],
	"umbralsun": ["THE SUN SPLITS", "TOTAL ECLIPSE"], "judge": ["THE SCALES TIP", "THE FINAL VERDICT"],
	"cinderking": ["THE THRONE OF ASH IGNITES", "HELL ITSELF ANSWERS"], "unwritten": ["THE PAGE TEARS", "THE INK SPILLS EVERYWHERE"],
	"holycow": ["THE UDDERS SWELL", "UNHOLY MOO"],
}
## A guardian's third stage (it rose again: e.phase == 3; brazil.gd).
const THIRD_PLANS := { "holycow": ["ascend", "holyfire", "milkrain", "stampede", "udder", "halo", "summon"] }
const THIRD_SUMMONS := { "holycow": ["scrounger", "scrounger", "crawler"] }
const BOSS_SUMMONS := {
	"colossus": ["bat", "bat", "skeleton"], "sporemother": ["slime", "mushroom", "slime"],
	"tyrant": ["imp", "imp"], "regent": ["cultist", "ghost"], "librarian": ["bookwyrm", "bookwyrm", "drowned"],
	"rimewarden": ["wisp", "wisp"],
	"bogmatriarch": ["bogling", "gnat", "gnat"], "ashwarlord": ["longbowman", "torchimp"], "frozenabbot": ["monk", "monk"],
	"crowking": ["crow", "crow", "gunman"], "umbralsun": ["voidling", "shadeknight"],
	"judge": ["wisp", "knight"], "cinderking": ["torchimp", "imp"], "unwritten": ["voidling", "wisp"],
	"holycow": ["scrounger", "scrounger"],
}
const RING_SPR := { "colossus": "bone", "librarian": "water", "rimewarden": "ice",
	"bogmatriarch": "spore", "ashwarlord": "fire", "frozenabbot": "ice", "crowking": "dark", "umbralsun": "darkBig",
	"judge": "bone", "cinderking": "fireBig", "unwritten": "dark" }
## Stage 7: per-guardian bullet sprites for shared attacks (originals keep theirs).
const SHOT_SPR := {
	"bogmatriarch": { "spiral": "spore", "burst": "spore", "cloud": "spore" },
	"ashwarlord": { "charge": "fire", "sweep": "fire", "embers": "fire" },
	"frozenabbot": { "freeze": "ice", "hail": "ice", "shards": "ice" },
	"crowking": { "spiral": "dark", "beams": "dark" },
	"umbralsun": { "curtain": "red", "sweep": "dark", "hail": "red", "spiral": "dark" },
	"judge": { "spiral": "bone", "beams": "bone" },
	"cinderking": { "sweep": "fire", "embers": "fire", "charge": "fire" },
	"unwritten": { "eclipse": "dark", "halo": "page" },
}
static func _spr(e: Enemy, attack: String, default: String) -> String:
	return SHOT_SPR.get(e.boss, {}).get(attack, default)

static func half(e: Enemy) -> bool:
	return e.hp < e.max_hp * (0.7 if G.dread >= 4 else 0.5)

static func done(e: Enemy, wait: float = 0.8) -> void:
	var h := half(e)
	e.state = &"rest"
	e.st = 0.0
	e.t = wait * (0.7 if h else 1.0)
	if e.stage == 2:
		e.t *= 0.75
	elif e.stage == 3:
		e.t = 0.05 if randf() < 0.4 else e.t * 0.4   # chaos: half the time the next attack follows at once

## Expanded game: the stage this guardian should be in now (STAGE_PLANS).
static func _want_stage(e: Enemy) -> int:
	if not GameData.rogues() or not STAGE_PLANS.has(e.boss) or e.phase == 3:
		return e.stage
	return 3 if e.hp < e.max_hp * 0.34 else (2 if e.hp < e.max_hp * 0.67 else 1)

static func _stage_break(e: Enemy, to: int) -> void:
	e.state = &"stagebreak"
	e.st = 0.0
	e.sub = to
	EBullets.clear_all()
	RiftBosses.clear()
	G.show_banner(e.d["name"], STAGE_LINE[e.boss][to - 2])
	G.add_shake(7)
	Snd.play("roar")
	Fx.burst(e.x, e.y, ["#f4ecd8", Afx.BOSS_COL.get(e.boss, "#d8443c")], 26, 120)

static func update_boss(e: Enemy, dt: float) -> void:
	if RiftBosses.handles(e):
		RiftBosses.update(e, dt)   # the rift guardians (scripts/entities/rift_bosses.gd)
		return
	var p := G.player
	var h := half(e)
	e.st += dt
	if e.state == &"intro":
		if e.t <= 0:
			e.state = &"pick"
		return
	# Souls-like stages (expanded game only).
	if e.state == &"stagebreak":
		e.z = sin(e.st * 20.0) * 2.0
		if e.st >= 1.6:
			e.z = 0.0
			e.stage = e.sub
			e.cycle = 0
			Combat.ering(e.x, e.y - 4, 28, 80, randf(), RING_SPR.get(e.boss, "red"))
			Combat.ering(e.x, e.y - 4, 20, 55, randf(), RING_SPR.get(e.boss, "red"))
			G.add_shake(9)
			Snd.play("boom")
			e.state = &"pick"
		return
	var want := _want_stage(e)
	if want > e.stage:
		_stage_break(e, want)
		return
	if e.stage == 3:
		e.pulse_t -= dt
		if e.pulse_t <= 0:
			e.pulse_t = 3.5
			Combat.ering(e.x, e.y - 4, 12, 62, randf(), RING_SPR.get(e.boss, "red"))
	if e.state == &"pick":
		var plan: Array = THIRD_PLANS[e.boss] if e.phase == 3 and THIRD_PLANS.has(e.boss) \
			else (STAGE_PLANS[e.boss][e.stage - 2] if e.stage > 1 and STAGE_PLANS.has(e.boss) else BOSS_PLANS[e.boss])
		var nxt: String = plan[TB.rmod(e.cycle, plan.size())]
		e.cycle += 1
		if nxt == "summon" and (G.enemies.size() > 5 or (not h and e.boss == "colossus")):
			nxt = plan[0]
		if nxt == "curtain" and not h:
			nxt = "spiral"
		e.state = StringName(nxt)
		e.st = 0.0
		e.sub = 0
		e.t = 0.0
		return
	if e.state == &"rest":
		if not e.has_target or TB.dist_xy(e.x, e.y, e.target.x, e.target.y) < 4:
			e.target = Vector2(TB.rint(3 * TB.TS + 40, 25 * TB.TS - 40), TB.rint(4 * TB.TS + 10, 4 * TB.TS + 70))
			e.has_target = true
		Combat.steer(e, e.target.x, e.target.y, 40, dt, World.M_FLYER)
		if e.t <= 0:
			e.state = &"pick"
		return
	var cx := e.x
	var cy := e.y - 4
	match e.state:
		&"ring":
			if e.t <= 0:
				e.t = 0.5
				var n := 20 if h else 16
				Combat.ering(cx, cy, n, 72, e.sub * (PI / n), RING_SPR.get(e.boss, "red"))
				e.sub += 1
				if e.sub >= 4: done(e)
		&"volley":
			if e.t <= 0:
				e.t = 0.42
				Combat.efan(cx, cy, TB.ang_to(e, p), 7 if h else 5, 0.9, 115, "bone")
				e.sub += 1
				if e.sub >= 5: done(e)
		&"slam":
			if e.sub == 0:
				e.from = Vector2(e.x, e.y)
				e.to = Vector2(clampf(p.x, 4 * TB.TS, 24 * TB.TS), clampf(p.y, 4 * TB.TS, 15 * TB.TS))
				e.sub = 1
				e.st = 0.0
				Snd.play("charge")
			var k := minf(1.0, e.st / 0.7)
			e.x = e.from.x + (e.to.x - e.from.x) * k
			e.y = e.from.y + (e.to.y - e.from.y) * k
			e.z = sin(k * PI) * 30
			if k >= 1:
				e.z = 0.0
				G.add_shake(8)
				Snd.play("boom")
				Combat.ering(e.x, e.y, 28 if h else 22, 85, randf(), "bone")
				Fx.burst(e.x, e.y + 8, ["#8b8f9c", "#d9d0b4"], 20, 90)
				Afx.dust(e.x, e.y + 8)
				e.slams += 1
				if e.slams >= (3 if h else 2):
					e.slams = 0
					done(e, 1)
				else:
					e.sub = 0
		&"summon":
			if e.sub == 0:
				e.sub = 1
				for t in (THIRD_SUMMONS[e.boss] if e.phase == 3 and THIRD_SUMMONS.has(e.boss) else BOSS_SUMMONS[e.boss]):
					var s := World.free_spot(G.room, p, 80, World.M_FLYER)
					Combat.spawn_enemy(t, s.x, s.y)
			if e.st > 1:
				done(e, 0.6)
		&"spiral":
			if e.t <= 0:
				e.t = 0.075
				e.angle += 0.19 if e.boss == "regent" else 0.23
				var arms := 4 if h else 2
				for i in arms:
					Combat.eshot(cx, cy, e.angle + float(i) / arms * TAU, 70, "dark" if e.boss == "regent" else _spr(e, "spiral", "spore"))
				if e.boss == "regent":
					for i in arms:
						Combat.eshot(cx, cy, -e.angle + float(i) / arms * TAU + 0.5, 60, "cyan")
				if e.sub % 4 == 0:
					Snd.play("ebullet")
				e.sub += 1
			if e.st > 3.2:
				done(e, 1)
		&"burst":
			if e.t <= 0:
				e.t = 0.6
				var a := TB.ang_to(e, p)
				for i in (14 if h else 10):
					Combat.eshot(cx, cy, a + (randf() - 0.5) * 1.3, 90 + randf() * 60, _spr(e, "burst", "spore"))
				Snd.play("ebullet")
				e.sub += 1
				if e.sub >= 3: done(e)
		&"cloud":
			if e.t <= 0:
				e.t = 0.8
				Combat.ering(cx, cy, 30, 48, randf(), _spr(e, "cloud", "spore"), true, TB.ang_to(e, p) + (randf() - 0.5) * 0.6, 0.32)
				e.sub += 1
				if e.sub >= 4: done(e)
		&"pages":
			if e.t <= 0:
				e.t = 0.09
				e.angle += 0.31
				for i in 3:
					Combat.eshot(cx, cy, e.angle + i * TAU / 3, 66, "page")
				if e.sub % 6 == 0 and h:
					Combat.eshot(cx, cy, TB.ang_to(e, p), 95, "water")
				if e.sub % 4 == 0:
					Snd.play("ebullet")
				e.sub += 1
			if e.st > 3.0:
				done(e, 1)
		&"tide":
			if e.t <= 0:
				e.t = 1.0
				var gap := TB.rint(4, 11)
				var left := e.sub % 2 == 0
				for i in 15:
					if absi(i - gap) <= 1:
						continue
					var y := TB.IY0 * TB.TS + i * TB.TS + 8
					Combat.eshot(TB.IX0 * TB.TS + 4 if left else (TB.IX0 + TB.IW) * TB.TS - 4, y, 0.0 if left else PI, 62, "water")
				Snd.play("ebullet")
				e.sub += 1
				if e.sub >= (5 if h else 4): done(e, 1)
		&"freeze":
			if e.t <= 0:
				e.t = 0.7
				Combat.ering(cx, cy, 28, 46, randf(), "ice", true, TB.ang_to(e, p) + (randf() - 0.5) * 0.5, 0.3)
				e.sub += 1
				if e.sub >= 4: done(e)
		&"hail":
			if e.t <= 0:
				e.t = 0.08 if h else 0.11
				Combat.eshot(TB.rint(TB.IX0 * TB.TS + 8, (TB.IX0 + TB.IW) * TB.TS - 8), TB.IY0 * TB.TS + 4,
					PI / 2 + (randf() - 0.5) * 0.2, 80 + randf() * 40, _spr(e, "hail", "ice"))
				if e.sub % 5 == 0:
					Snd.play("ebullet")
				e.sub += 1
			if e.st > 3.2:
				done(e, 1)
		&"shards":
			if e.t <= 0:
				e.t = 0.5
				Combat.eshot(cx, cy, TB.ang_to(e, p), 110, "iceBig", 4, 0.55, "ice")
				Snd.play("ebullet")
				e.sub += 1
				if e.sub >= (6 if h else 4): done(e, 1)
		&"charge":
			if e.sub == 0:
				e.sub = 1
				e.st = 0.0
				e.ca = TB.ang_to(e, p)
				e.charges += 1
				Snd.play("charge")
			if e.sub == 1:
				e.telegraph = e.ca
				e.has_telegraph = true
				if e.st > 0.55:
					e.sub = 2
					e.st = 0.0
					e.has_telegraph = false
			elif e.sub == 2:
				var hit := World.move_body(G.room, e, cos(e.ca) * 250 * dt, sin(e.ca) * 250 * dt, World.M_FLYER)
				if randf() < 0.6:
					var col: String = TB.pick(["#c8f0ff", "#6fd3e0"]) if e.boss == "rimewarden" else TB.pick(["#e8873a", "#f2c94c"])
					Fx.particle(e.x + TB.rint(-8, 8), e.y + 10, 0, -10, 0.3, col, 2)
				if hit != 0 or e.st > 1.4:
					G.add_shake(7)
					Snd.play("boom")
					Afx.dust(e.x, e.y + 8)
					Combat.ering(e.x, e.y, 16 if h else 12, 80, randf(), "ice" if e.boss == "rimewarden" else _spr(e, "charge", "fire"))
					if e.charges >= 3:
						e.charges = 0
						done(e, 1.2)
					else:
						e.sub = 0
		&"sweep":
			if e.sub == 0:
				e.sub = 1
				e.angle = TB.ang_to(e, p) - 1.9
			if e.t <= 0:
				e.t = 0.055
				e.angle += 0.065
				Combat.eshot(cx, cy, e.angle, 105, _spr(e, "sweep", "fire"))
				if h:
					Combat.eshot(cx, cy, e.angle + PI, 105, _spr(e, "sweep", "fire"))
				Snd.play("ebullet")
			if e.st > 3:
				done(e, 1)
		&"embers":
			if e.t <= 0:
				e.t = 0.35
				var a := TB.ang_to(e, p) + (randf() - 0.5) * 1.6
				Combat.eshot(cx, cy, a, 120, "fireBig", 4, 0.7 + randf() * 0.4, "fire")
				Snd.play("ebullet")
				e.sub += 1
				if e.sub >= (7 if h else 5): done(e, 1.2)
		&"teleport":
			if e.sub == 0:
				e.sub = 1
				e.st = 0.0
				Fx.burst(e.x, e.y, ["#a35bd6", "#5c3483"], 20, 80)
				Afx.warp(e.x, e.y)
				Snd.play("portal")
			if e.sub == 1:
				e.hidden = true
				if e.st > 0.6:
					var s := World.free_spot(G.room, p, 110, World.M_FLYER)
					e.x = clampf(s.x, 4 * TB.TS, 24 * TB.TS)
					e.y = clampf(s.y, 4 * TB.TS, 14 * TB.TS)
					e.hidden = false
					e.sub = 2
					Fx.burst(e.x, e.y, ["#a35bd6", "#f4ecd8"], 20, 80)
					Afx.warp(e.x, e.y)
					Combat.ering(e.x, e.y, 18 if h else 14, 70, randf(), "darkBig")
			if e.sub == 2 and e.st > 1.0:
				done(e, 0.4)
		&"beams":
			if e.sub == 0:
				e.sub = 1
				e.st = 0.0
				var a := TB.ang_to(e, p)
				var n := 5 if h else 3
				e.beams = []
				for i in n:
					e.beams.append(a + (i - (n - 1) / 2.0) * 0.42)
				Snd.play("charge")
			if e.sub == 1 and e.st > 0.85:
				e.sub = 2
				e.st = 0.0
				Snd.play("beam")
				G.add_shake(5)
			if e.sub == 2:
				for ba in e.beams:
					var dx := cos(ba)
					var dy := sin(ba)
					var px := p.x - e.x
					var py := p.y - e.y
					var along := px * dx + py * dy
					var perp := absf(px * dy - py * dx)
					if along > 0 and perp < 7:
						Combat.hurt_player(1, e.d["name"])
				if e.st > 0.35:
					e.beams = []
					e.repeat += 1
					if e.repeat >= 2:
						e.repeat = 0
						done(e, 0.8)
					else:
						e.sub = 0
		&"curtain":
			if e.t <= 0:
				e.t = 1.1
				var gap := TB.rint(2, 22)
				for i in 26:
					if absi(i - gap) <= 1:
						continue
					Combat.eshot(TB.IX0 * TB.TS + i * TB.TS + 8, TB.IY0 * TB.TS + 6, PI / 2, 58, _spr(e, "curtain", "dark"))
				Snd.play("ebullet")
				e.sub += 1
				if e.sub >= 5: done(e, 1)
		# ---------- Stage 7 attacks ----------
		&"bogspit":
			# Lobbed globs that burst into rings where they land.
			if e.t <= 0:
				e.t = 0.45
				var a := TB.ang_to(e, p) + (randf() - 0.5) * 1.2
				Combat.eshot(cx, cy, a, 95 + randf() * 30, "redBig", 4, 0.6 + randf() * 0.4, "spore")
				Snd.play("ebullet")
				e.sub += 1
				if e.sub >= (8 if h else 6): done(e, 1)
		&"arrowrain":
			# Slanted waves of arrows from the top wall, each with a gap to slip through.
			if e.t <= 0:
				e.t = 0.9
				var gap := TB.rint(3, 21)
				var slant := 0.25 if e.sub % 2 == 0 else -0.25
				for i in 26:
					if absi(i - gap) <= 1:
						continue
					Combat.eshot(TB.IX0 * TB.TS + i * TB.TS + 8, TB.IY0 * TB.TS + 6, PI / 2 + slant, 72, "bone", 2)
				Snd.play("ebullet")
				e.sub += 1
				if e.sub >= (6 if h else 4): done(e, 1)
		&"palms":
			# Glide next to the player, then strike: a ring plus an aimed fan.
			if e.sub == 0:
				e.from = Vector2(e.x, e.y)
				var a := TB.ang_to(p, e)
				e.to = Vector2(clampf(p.x + cos(a) * 46, 4 * TB.TS, 24 * TB.TS), clampf(p.y + sin(a) * 46, 4 * TB.TS, 15 * TB.TS))
				e.sub = 1
				e.st = 0.0
				Snd.play("charge")
			var k := minf(1.0, e.st / 0.45)
			e.x = e.from.x + (e.to.x - e.from.x) * k
			e.y = e.from.y + (e.to.y - e.from.y) * k
			if k >= 1:
				G.add_shake(5)
				Snd.play("boom")
				Afx.dust(e.x, e.y + 8)
				Combat.ering(e.x, e.y, 20 if h else 16, 75, randf(), "ice")
				Combat.efan(e.x, e.y, TB.ang_to(e, p), 5, 0.5, 110, "ice")
				e.slams += 1
				if e.slams >= (4 if h else 3):
					e.slams = 0
					done(e, 1)
				else:
					e.sub = 0
		&"gunline":
			# Four rotating lines of fire with aimed triple shots on top.
			if e.t <= 0:
				e.t = 0.07
				e.angle += 0.11 if e.sub % 60 < 30 else -0.11
				for i in 4:
					Combat.eshot(cx, cy, e.angle + i * TAU / 4, 92, "red", 2)
				if e.sub % 8 == 0:
					Combat.efan(cx, cy, TB.ang_to(e, p), 3, 0.15, 140 if h else 120, "red")
					Snd.play("ebullet")
				e.sub += 1
			if e.st > 3.0:
				done(e, 1)
		# ---------- ROADMAP 4.7 part C: the realm rulers and The Unwritten ----------
		&"halo":
			# Rings of light with a gap where you stand: step into the gap.
			if e.t <= 0:
				e.t = 0.6
				var n := 24
				var gap := TB.ang_to(e, p) + (e.sub % 2) * 0.5 - 0.25
				for i in n:
					var a := gap + float(i) / n * TAU
					if absf(TB.wrap_ang(a - gap)) < 0.38:
						continue
					Combat.eshot(cx, cy, a, 74, _spr(e, "halo", "bone"))
				Snd.play("ebullet")
				e.sub += 1
				if e.sub >= (5 if h else 4): done(e)
		&"verdict":
			# Lances of judgement: lanes light up across you, then strike.
			if e.t <= 0 and e.sub < (4 if h else 3):
				e.t = 0.45
				for off in ([-64.0, 0.0, 64.0] if e.sub % 2 == 0 else [-32.0, 32.0]):
					RiftBosses.bands.append({ "horiz": false, "pos": clampf(p.x + off, 2.0 * TB.TS, 26.0 * TB.TS), "half": 10.0,
						"warn": 0.8, "fire": 0.14, "by": e.d["name"], "hit": false })
				if h:
					RiftBosses.bands.append({ "horiz": true, "pos": clampf(p.y, 4.0 * TB.TS, 16.0 * TB.TS), "half": 10.0,
						"warn": 0.8, "fire": 0.14, "by": e.d["name"], "hit": false })
				Snd.play("charge")
				e.sub += 1
			if e.sub >= (4 if h else 3) and e.st > 2.4:
				done(e, 0.8)
		&"brimstone":
			# Burning rings close in on where you stand, each with one way out.
			if e.t <= 0 and e.sub < (4 if h else 3):
				e.t = 0.7
				RiftBosses.rings.append({ "x": p.x, "y": p.y, "r": 110.0, "gap": randf() * TAU, "gw": 0.45, "warn": 0.8,
					"n": 22, "by": e.d["name"] })
				Combat.efan(cx, cy, TB.ang_to(e, p), 5, 0.7, 100, "fire")
				Snd.play("charge")
				e.sub += 1
			if e.sub >= (4 if h else 3) and e.st > 3.0:
				done(e, 0.8)
		&"hellgate":
			# The floor splits: lines of fire across the room, and a spiral from the king.
			if e.sub == 0:
				e.sub = 1
				var horiz := randf() < 0.5
				for i in 4:
					var along := (4.0 + i * 6.5) * TB.TS
					for j in 6:
						var x := along if not horiz else (3.0 + j * 4.2) * TB.TS
						var y := (4.0 + j * 2.3) * TB.TS if not horiz else (4.0 + i * 3.6) * TB.TS
						if G.zones.size() < 60:
							G.zones.append({ "x": x, "y": y, "r": 12.0, "t": 4.0, "kind": "fire", "tick": 0.0 })
				Snd.play("boom")
				G.add_shake(4)
			if e.t <= 0:
				e.t = 0.1
				e.angle += 0.23
				for i in (3 if h else 2):
					Combat.eshot(cx, cy, e.angle + float(i) / (3 if h else 2) * TAU, 62, "fireBig" if i == 0 else "fire")
			if e.st > 3.4:
				done(e, 1)
		&"ink":
			# Ink pours from both walls in rows, each row with a gap.
			if e.t <= 0:
				e.t = 0.9
				var gap := TB.rint(1, 12)
				var left := e.sub % 2 == 0
				for r in 13:
					if absi(r - gap) <= 1:
						continue
					var y := (TB.IY0 + 1 + r) * TB.TS + 8.0
					Combat.eshot(TB.TS + 6.0 if left else TB.SW - TB.TS - 6.0, y, 0.0 if left else PI, 64, "dark" if left else "bone")
				Snd.play("ebullet")
				e.sub += 1
				if e.sub >= (6 if h else 4): done(e, 0.8)
		&"rewrite":
			# The page is wiped clean, it reappears elsewhere, and writes three rings, light then dark.
			if e.sub == 0:
				e.sub = 1
				EBullets.clear_all()
				Fx.burst(e.x, e.y, ["#f4ecd8", "#14101a"], 24, 120)
				e.x = TB.SW - e.x
				e.y = clampf(e.y, 4.0 * TB.TS, 8.0 * TB.TS)
				Snd.play("portal")
				e.t = 0.5
			elif e.t <= 0:
				e.t = 0.35
				Combat.ering(cx, cy, 26 if h else 20, 70, e.sub * 0.12, "bone" if e.sub % 2 == 1 else "dark")
				e.sub += 1
				if e.sub >= 4: done(e, 1)
		# ---------- Stage attacks (expanded game) ----------
		&"wall":
			# A wall of shots all round with one gap that turns: find the gap, wave after wave.
			if e.t <= 0:
				e.t = 0.6
				if e.sub == 0:
					e.angle = TB.ang_to(e, p)
				var n := 30
				for i in n:
					var a := e.angle + float(i) / n * TAU
					if absf(TB.wrap_ang(a - e.angle)) < 0.42:
						continue
					Combat.eshot(cx, cy, a, 64, RING_SPR.get(e.boss, "red"))
				e.angle += 0.55 if e.sub % 2 == 0 else -0.35
				Snd.play("ebullet")
				e.sub += 1
				if e.sub >= (4 if e.stage < 3 else 6): done(e)
		&"flower":
			# Petals: two sets of arms turning opposite ways.
			if e.t <= 0:
				e.t = 0.09
				e.angle += 0.13
				for i in 4:
					Combat.eshot(cx, cy, e.angle + i * TAU / 4, 58, RING_SPR.get(e.boss, "red"))
					Combat.eshot(cx, cy, -e.angle * 1.3 + i * TAU / 4 + 0.4, 72, "page" if i % 2 == 0 else "bone")
			if e.st > 3.0:
				done(e, 1)
		&"cross":
			# Lanes light up across you, along and across, then strike.
			if e.t <= 0 and e.sub < 3:
				e.t = 0.55
				RiftBosses.bands.append({ "horiz": false, "pos": clampf(p.x, 2.0 * TB.TS, 26.0 * TB.TS), "half": 10.0, "warn": 0.75,
					"fire": 0.14, "by": e.d["name"], "hit": false })
				RiftBosses.bands.append({ "horiz": true, "pos": clampf(p.y, 4.0 * TB.TS, 16.0 * TB.TS), "half": 10.0, "warn": 0.75,
					"fire": 0.14, "by": e.d["name"], "hit": false })
				Snd.play("charge")
				e.sub += 1
			if e.sub >= 3 and e.st > 2.4:
				done(e, 0.8)
		&"barrage":
			# Chaos: a fan, a ring or a burst of arms, over and over, in no order.
			if e.t <= 0:
				e.t = 0.28
				match randi() % 3:
					0: Combat.efan(cx, cy, TB.ang_to(e, p), 7, 0.9, 120, "bone")
					1: Combat.ering(cx, cy, 16, 70, randf(), RING_SPR.get(e.boss, "red"))
					_:
						for i in 6:
							Combat.eshot(cx, cy, randf() * TAU, 90 + randf() * 40, "fire")
				Snd.play("ebullet")
			if e.st > 2.6:
				done(e, 1)
		# ---------- The Holy Cow (brazil.gd) ----------
		&"moo":
			# MOO: three rings of milk spread out, each wider than the last.
			if e.t <= 0:
				e.t = 0.45
				Combat.ering(cx, cy, 18 + e.sub * 4, 60 + e.sub * 12, e.sub * 0.2, "page")
				Fx.float_text(cx, cy - 26, "MOO!", "white", true)
				G.add_shake(3)
				e.sub += 1
				if e.sub >= (4 if h else 3): done(e)
		&"milkrain":
			# Milk falls from the ceiling in rows, each row with two gaps.
			if e.t <= 0:
				e.t = 0.8
				var g1 := TB.rint(2, 11)
				var g2 := TB.rint(14, 23)
				for i in 26:
					if absi(i - g1) <= 1 or absi(i - g2) <= 1:
						continue
					Combat.eshot(TB.IX0 * TB.TS + i * TB.TS + 8, TB.IY0 * TB.TS + 6, PI / 2, 60, "page")
				Snd.play("ebullet")
				e.sub += 1
				if e.sub >= (5 if h else 4): done(e, 0.8)
		&"udder":
			# A spray of milk at you, sweeping side to side.
			if e.t <= 0:
				e.t = 0.12
				var a := TB.ang_to(e, p) + sin(e.st * 3.0) * 0.6
				Combat.eshot(cx, cy, a, 110, "page")
				if h:
					Combat.eshot(cx, cy, a + 0.3, 100, "page")
			if e.st > 2.6:
				done(e)
		&"ascend":
			# The third stage: it rises into the air (a ring marks where it lands) and comes down in a blast.
			if e.sub == 0:
				e.sub = 1
				e.from = Vector2(e.x, e.y)
				e.to = Vector2(clampf(p.x, 4 * TB.TS, 24 * TB.TS), clampf(p.y, 4 * TB.TS, 15 * TB.TS))
				RiftBosses.rings.append({ "x": e.to.x, "y": e.to.y, "r": 50.0, "gap": randf() * TAU, "gw": 0.6, "warn": 0.9, "n": 18, "by": e.d["name"] })
				Snd.play("charge")
			var k := minf(1.0, e.st / 0.9)
			e.x = e.from.x + (e.to.x - e.from.x) * k
			e.y = e.from.y + (e.to.y - e.from.y) * k
			e.z = sin(k * PI) * 46
			if k >= 1:
				e.z = 0.0
				G.add_shake(9)
				Snd.play("boom")
				Combat.ering(e.x, e.y, 26, 90, randf(), "page")
				Combat.ering(e.x, e.y, 14, 55, randf(), "bone")
				e.repeat += 1
				if e.repeat >= 2:
					e.repeat = 0
					done(e, 0.9)
				else:
					e.sub = 0
					e.st = 0.0
		&"holyfire":
			# A holy spiral, gold and white, with rings between.
			if e.t <= 0:
				e.t = 0.07
				e.angle += 0.21
				for i in 3:
					Combat.eshot(cx, cy, e.angle + i * TAU / 3, 70, "fire" if i == 0 else "page")
				if e.sub % 14 == 0:
					Combat.ering(cx, cy, 16, 50, randf(), "bone")
				e.sub += 1
			if e.st > 3.4:
				done(e, 1)
		&"stampede":
			# Phantom cows charge across the room in lanes: their lanes light up first.
			if e.t <= 0 and e.sub < 4:
				e.t = 0.5
				RiftBosses.bands.append({ "horiz": true, "pos": clampf(p.y + randf_range(-40.0, 40.0), 4.0 * TB.TS, 16.0 * TB.TS), "half": 12.0,
					"warn": 0.8, "fire": 0.14, "by": e.d["name"], "hit": false })
				Fx.float_text(cx, cy - 26, "MOO!", "white", true)
				e.sub += 1
			if e.sub >= 4 and e.st > 3.0:
				done(e, 0.8)
		&"eclipse":
			# Two counter-rotating spirals, light and dark, and a ring every second.
			if e.t <= 0:
				e.t = 0.08
				e.angle += 0.17
				var arms := 3 if h else 2
				for i in arms:
					Combat.eshot(cx, cy, e.angle + float(i) / arms * TAU, 66, "dark")
					Combat.eshot(cx, cy, -e.angle + float(i) / arms * TAU, 58, "red")
				if e.sub % 12 == 0:
					Combat.ering(cx, cy, 18 if h else 14, 50, randf(), "darkBig")
					Snd.play("ebullet")
				e.sub += 1
			if e.st > 3.6:
				done(e, 1)
