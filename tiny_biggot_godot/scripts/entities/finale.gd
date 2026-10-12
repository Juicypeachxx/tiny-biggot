class_name Finale
extends RefCounted
## Stage 55 THE LAST LAUGH (his word, 11 Oct: "after final boss there is next final final boss that
## chooses form of most gathered alignment"; FINALE.md). Expanded game only.
##
## Whenever a run would be won (G.on_win: the Critic falls, the book is closed, you walk out after the
## Eclipse...), it is not over yet: something laughs, and the FINAL FINAL BOSS steps out, in the form
## of the alignment you gathered most (GOOD, EVIL, LAWFUL, CHAOTIC; a tie is settled by a coin). You
## are healed, the fight is in its own arena, and it has three forms (BossAI stages, each its own
## picture and moves). Beat it and the run is won with THE LAST LAUGH (+400 embers). Fall to it and
## the run is still won (the book was already kept), but the last laugh is its.
##   GOOD    SIR BRAYSALOT, a dim but noble donkey knight with a carrot for a lance. HEE-HAW (rings
##           with one gap), the lance charge, carrots from the sky, the buck kick, and he trips over
##           his own lance (+50% damage while he lies there). SUPER BRAYSALOT, then ULTRA HOLY.
##   LAWFUL  SENATOR SCALESWORTH, who is certainly not a lizard. The filibuster (a spiral of words),
##           VETO stamps, a NEW TAX (he takes some of your gold, throws it back, and pays it all back
##           when he falls), red tape across the room, and from his second form a tongue that pulls
##           you in. THE MASK SLIPS, then COLD-BLOODED.
##   CHAOTIC PROPHET NIGH, who always said the end is nigh. Sermons (rings with one gap), pamphlets,
##           meteors, the sign slam, and his TRUE BELIEVERS, who flex at you: MOGGED (you crawl at
##           40% speed for a second). THE SKY IS FALLING, then THE END: a countdown, then the sky.
##   EVIL    BARON VON CHONK, a fat cat overlord. He knocks things off a table at you (vases, mugs,
##           a fishbowl, a pot: they shatter where they land), coughs up hairballs that burst, pounces,
##           naps (+50% damage) while his kittens guard him. THE ZOOMIES (he tears round the room),
##           then NINE LIVES: laser eyes and a laser dot that strikes where it settles.
## The fight's own things live in the lists below; tick() moves them (from Hazards.update), clear()
## empties them when the room changes, a stage breaks or the boss falls.

const BOSS := { "good": "braysalot", "law": "scalesworth", "chaos": "prophet", "evil": "chonk" }
const ARENA := { "good": "f_pasture", "law": "f_senate", "chaos": "f_endtimes", "evil": "f_parlour" }
const ALIGN := { "braysalot": "good", "scalesworth": "law", "prophet": "chaos", "chonk": "evil" }
## The name on the boss bar in each form.
const FORMS := {
	"braysalot": ["SIR BRAYSALOT", "SUPER BRAYSALOT", "ULTRA HOLY BRAYSALOT"],
	"scalesworth": ["SENATOR SCALESWORTH", "SCALESWORTH UNMASKED", "COLD-BLOODED SCALESWORTH"],
	"prophet": ["PROPHET NIGH", "PROPHET NIGH, PROVEN RIGHT", "PROPHET NIGH: THE END"],
	"chonk": ["BARON VON CHONK", "BARON VON ZOOMIES", "NINE-LIVES CHONK"],
}
## What each says as a new form begins.
const FORM_LINE := {
	"braysalot": ["I HAVE BECOME... SUPER!", "BEHOLD MY FINAL FORM! I THINK."],
	"scalesworth": ["THAT IS NOT A TONGUE. NO COMMENT.", "FINE. I AM A LIZARD. VOTE FOR ME."],
	"prophet": ["SEE?! THE SKY! I TOLD YOU!", "THIS IS IT! THE END! YAAAH!"],
	"chonk": ["IT IS 3 A.M. ZOOMIES TIME.", "I HAVE NINE LIVES. YOU HAVE ONE."],
}
const COL := { "braysalot": "#f2c94c", "scalesworth": "#6fd3e0", "prophet": "#ff8a2a", "chonk": "#d8443c" }
const LAUGH := { "good": "HEE-HAW-HAW-HAW!", "law": "HEH. HEH. HEH.", "chaos": "HA HA! IT IS NIGH!", "evil": "MWAHAHA... MEOW." }
const WAIT := 2.6        # the laugh before the fight
const EMBERS := 400      # THE LAST LAUGH
const MOG_T := 1.1       # MOGGED: this long at MOG_SLOW of your speed
const MOG_SLOW := 0.4
const MOG_CD := 2.4      # no new MOG this soon after one
const FLEX_R := 64.0     # a believer flexes at you from this close
const DROP_WARN := 0.85  # a shadow on the floor this long before it lands
const LOB_T := 0.75      # a thrown thing in the air
const VULN := 1.5        # a tripped donkey, a napping cat: damage taken
const TRIP_T := 2.2
const PROPS := ["vase", "mug", "bowl", "pot"]

static var wait := 0.0
static var drops: Array = []     # falling from the sky: { x, y, warn, max, kind, r, by, n, spr }
static var lobs: Array = []      # thrown: { x0, y0, x1, y1, t, dur, kind, by }
static var lanes: Array = []     # red tape: { horiz, pos, half, warn, fire, by }
static var tongue := {}          # { ax, ay, a, len, warn, fire, hit, by }
static var dot := {}             # the laser dot: { x, y, t, lock, by }
static var table := {}           # the cat's table while he knocks things off it: { x, y, items }
static var aim := {}             # a lance or a pounce telegraph: { ax, ay, bx, by, r }
static var trail: Array = []     # afterimages of a charge: { x, y, t, name, sc, face }
static var dark := 0.0           # THE END: the room goes dark (drawing)
static var mog_t := 0.0
static var mog_cd := 0.0
static var flexers := {}         # believer uid -> { cd, pose }
static var stats := {}           # what happened, by name (tests/stage55_test reads it)
static var off := false          # tests of the endings before it (realms_test) turn it off
static var _room: WeakRef = null

static func _stat(k: String) -> void:
	stats[k] = stats.get(k, 0) + 1

static func handles(e: Enemy) -> bool:
	return e != null and ALIGN.has(e.boss)

## The arena of a final final boss.
static func arena() -> bool:
	return G.room != null and G.room.theme.get("finale", "") != ""

## Its things are about: in its arena, or wherever one of them fights (tests put them anywhere).
static func live() -> bool:
	return arena() or (G.boss != null and handles(G.boss)) or not (drops.is_empty() and lobs.is_empty() and lanes.is_empty() \
		and tongue.is_empty() and dot.is_empty())

## The alignment gathered most; a tie is settled by a coin.
static func pick(p: Player) -> String:
	var best := -1
	var tied: Array = []
	for k in Alignments.KEYS:
		var v := Alignments.value(p, k)
		if v > best:
			best = v
			tied = [k]
		elif v == best:
			tied.append(k)
	return tied[randi() % tied.size()]

# ---------- The run's end ----------
## G.on_win: the run would be won. The first time, the final final boss comes instead (true: the
## win waits); while it is coming or being fought, a second win (an exit portal walked into
## again) waits too.
static func intercept() -> bool:
	if not GameData.rogues() or Endless.on() or G.player == null:
		return false
	var r := G.run_stats
	if r.get("finale_done", false):
		return false
	if r.has("finale"):
		return true
	if G.player.hp <= 0 or off or DebugArgs.has("no-finale"):
		return false
	begin(pick(G.player))
	return true

## Something laughs: the banner, then (after WAIT) the arena.
static func begin(al: String) -> void:
	G.run_stats["finale"] = al
	G.win_timer = null
	wait = WAIT
	_stat("begin")
	G.show_banner("WAIT. SOMETHING IS LAUGHING", "THE FINAL FINAL BOSS: YOU WERE MOSTLY " + Alignments.NAMES[al])
	G.add_shake(6)
	Snd.play("roar")
	var p := G.player
	for i in 3:
		Fx.texts.append({ "x": p.x + randf_range(-60.0, 60.0), "y": p.y - 40.0 - i * 14.0, "text": LAUGH[al],
			"col": Alignments.COLS[al], "life": 2.0, "big": i == 0 })

## The arena: healed in full, and in.
static func enter(al: String) -> void:
	_stat("enter")
	var p := G.player
	p.hp = p.max_hp
	G._enter_realm(ARENA[al], 3)

## Combat.spawn_boss in the arena: its health keeps pace with how deep the run went.
static func spawned(e: Enemy) -> void:
	var k := 1.0 + 0.15 * (int(G.run_stats.get("chapter", 1)) - 1)
	e.hp *= k
	e.max_hp *= k
	if DebugArgs.has("finale-form"):   # (pictures: --finale-form=2 or 3 starts it in that form)
		e.stage = clampi(DebugArgs.get_int("finale-form", 1), 1, 3)
		e.hp = e.max_hp * (0.6 if e.stage == 2 else (0.3 if e.stage == 3 else 1.0))

## G._realm_won: the final final boss falls. The run is won (after its chests).
static func won(b: Enemy) -> void:
	var r := G.run_stats
	r["finale_done"] = true
	r["finale_won"] = true
	Meta.meta["finale_wins"] = Meta.meta.get("finale_wins", 0) + 1
	Meta.meta[b.boss + "_wins"] = Meta.meta.get(b.boss + "_wins", 0) + 1
	clear()
	_stat("won")
	var room := G.room
	for dx in [-36.0, 36.0]:
		room.objects.append({ "kind": "chest", "x": 14.0 * TB.TS + dx, "y": 10.0 * TB.TS, "boss": true })
	for i in int(r.get("taxed", 0) / 5.0) + 10:
		Combat.drop_pickup("coin", b.x, b.y)   # the senator's taxes, paid back (and then some)
	G.show_banner(FORMS[b.boss][0] + " IS BEATEN", "THE LAST LAUGH IS YOURS")
	Barks.say(b, "NOT... FUNNY...", "red", 2.0)
	G.win_timer = 6.0

## G.on_death in the arena: the run was already won before it came, so it still is.
static func keeps_win(source: String) -> bool:
	var r := G.run_stats
	if not GameData.rogues() or not r.has("finale") or r.get("finale_done", false):
		return false
	r["finale_done"] = true
	r["finale_lost"] = true
	G.death_by = source if source != "" else "the last laugh"
	_stat("lost")
	return true

## The boss bar's name: a final final boss names its form.
static func bar_name(e: Enemy) -> String:
	if handles(e):
		return FORMS[e.boss][clampi(e.stage, 1, 3) - 1]
	return e.d["name"]

## EnemyAI2.adjust_damage (rule "finale"): a donkey on his back, a cat asleep.
static func adjust_damage(e: Enemy, dmg: float) -> float:
	if (e.state == &"trip" or e.state == &"nap") and e.sub == 1:
		return dmg * VULN
	return dmg

## world_view: a tripped donkey lies on his side, a napping cat too.
static func tilt(e: Enemy) -> float:
	if handles(e) and (e.state == &"trip" or e.state == &"nap") and e.sub == 1:
		return -PI / 2.0 * e.face
	return 0.0

## world_view: a believer mid-flex.
static func sprite(e: Enemy, name: String) -> String:
	if e.type == "believer" and flexers.has(e.uid) and flexers[e.uid]["pose"] > 0.0:
		return name.replace("believer", "believer_flex")
	return name

## Player.update_move: MOGGED.
static func speed_mult(p: Player) -> float:
	return MOG_SLOW if mog_t > 0.0 else 1.0

## BossAI._stage_break: a new form. Its name on the banner, its line, a burst of its colour.
static func transform(e: Enemy, to: int) -> void:
	clear()
	_stat("form%d" % to)
	G.show_banner(FORMS[e.boss][to - 1], FORM_LINE[e.boss][to - 2])
	Barks.say(e, FORM_LINE[e.boss][to - 2], "white", 2.4)
	Juice.flash(0.25)
	Fx.burst(e.x, e.y - 10, [COL[e.boss], "#ffffff", "#fff0a0"], 40, 150, 0.8)

static func clear() -> void:
	drops.clear()
	lobs.clear()
	lanes.clear()
	trail.clear()
	tongue = {}
	dot = {}
	table = {}
	aim = {}
	dark = 0.0
	flexers.clear()

# ---------- The moves (BossAI.update_boss: anything it does not know comes here) ----------
static func move(e: Enemy, p: Player, dt: float, h: bool) -> void:
	var cx := e.x
	var cy := e.y - 8.0
	var hard := e.stage >= 2 or h
	match e.state:
		# ----- SIR BRAYSALOT -----
		&"heehaw":   # HEE-HAW: rings that spread, each with one gap
			if e.t <= 0:
				e.t = 0.5
				var n := 22 + e.sub * 2
				Combat.ering(cx, cy, n, 62.0 + e.sub * 10.0, randf() * TAU, "bone" if e.stage < 3 else "page", true,
					TB.ang_to(e, p) + randf_range(-0.7, 0.7), 0.36)
				Fx.float_text(cx, cy - 30, "HEE-HAW!", "white", true)
				G.add_shake(3)
				e.sub += 1
				if e.sub >= (4 if hard else 3):
					BossAI.done(e)
		&"lance":   # the lance charge: a lane lights up, then he runs it, carrots flying off his sides
			_lance(e, p, dt, 3 if e.stage >= 2 else 2, "fire")
		&"carrots":   # carrots from the sky, one on you
			if e.sub == 0:
				e.sub = 1
				var n := 9 if hard else 6
				for i in n:
					var at := Vector2(p.x, p.y) if i == 0 else _floor_spot(p, 120.0)
					_drop(at, "carrot", 13.0, DROP_WARN + i * 0.12, "fire", 6, e)
				Barks.say(e, "CARROTS! FROM THE HEAVENS!", "white", 1.6)
				e.t = DROP_WARN + n * 0.12 + 0.4
			elif e.t <= 0:
				BossAI.done(e)
		&"kick":   # the buck kick: he turns round and kicks a fan at you
			if e.t <= 0:
				e.t = 0.38
				e.face = -1 if p.x > e.x else 1
				Combat.efan(cx, cy + 6, TB.ang_to(e, p), 9 if hard else 7, 1.1, 120, "bone")
				Fx.float_text(cx, cy - 26, "BUCK!", "white", false)
				e.sub += 1
				if e.sub >= 3:
					e.face = 1 if p.x > e.x else -1
					BossAI.done(e)
		&"trip":   # dim, but noble: he trips over his own lance (and takes half again)
			if e.sub == 0:
				e.sub = 1
				e.st = 0.0
				_stat("trip")
				Barks.say(e, "OOPS.", "white", 1.4)
				Fx.float_text(cx, cy - 26, "TRIPPED!", "gold", true)
				G.add_shake(4)
				Snd.play("boom")
			elif e.st >= TRIP_T:
				e.sub = 2
				Barks.say(e, "I MEANT TO DO THAT.", "white", 1.6)
				Combat.ering(e.x, e.y - 4, 16, 70, randf(), "bone")
				BossAI.done(e, 0.3)
		# ----- SENATOR SCALESWORTH -----
		&"speech":   # the filibuster: a spiral of words, and words over his head
			if e.sub == 0:
				e.sub = 1
				Barks.say(e, "AND ANOTHER THING...", "white", 2.0)
			if e.t <= 0:
				e.t = 0.09
				e.angle += 0.21
				var arms := 3 if hard else 2
				for i in arms:
					Combat.eshot(cx, cy, e.angle + float(i) / arms * TAU, 62, "page")
				if int(e.st * 10.0) % 8 == 0:
					Fx.float_text(cx + randf_range(-30.0, 30.0), cy - 30, TB.pick(["BLAH", "BLAH BLAH", "FURTHERMORE", "IN CONCLUSION...", "YIELD? NEVER"]), "white", false)
			if e.st > 3.2:
				BossAI.done(e, 0.9)
		&"veto":   # VETO: stamps come down where you stand
			var n := 5 if hard else 3
			if e.t <= 0:
				if e.sub < n:
					e.t = 0.45
					_drop(Vector2(p.x, p.y), "stamp", 18.0, 0.75, "red", 10, e)
					e.sub += 1
				elif e.sub == n:
					e.t = 1.0
					e.sub += 1
				else:
					BossAI.done(e)
		&"tax":   # NEW TAX: some of your gold flies to him, and comes back as coins you dodge
			if e.sub == 0:
				e.sub = 1
				e.t = 0.6
				var take := mini(int(p.gold * 0.1), 60)
				if take > 0:
					p.gold -= take
					G.run_stats["taxed"] = int(G.run_stats.get("taxed", 0)) + take
					Fx.float_text(p.x, p.y - 22, "-%d GOLD (TAX)" % take, "gold", true)
				Fx.burst(p.x, p.y - 6, ["#f2c94c", "#fff0a0"], 14, 90)
				Barks.say(e, "NEW TAX!", "white", 1.4)
				_stat("tax")
			elif e.t <= 0:
				e.t = 0.35
				Combat.efan(cx, cy, TB.ang_to(e, p), 9, 1.3, 105, "bone")
				e.sub += 1
				if e.sub >= 4:
					Fx.float_text(cx, cy - 26, "NO REFUNDS!", "gold", false)
					BossAI.done(e)
		&"redtape":   # red tape across the room: lanes light up, then strike
			if e.t <= 0 and e.sub < 3:
				e.t = 0.55
				var horiz := e.sub % 2 == 0
				var pos := (p.y if horiz else p.x) + randf_range(-18.0, 18.0)
				lanes.append({ "horiz": horiz, "pos": clampf(pos, (4.0 if horiz else 3.0) * TB.TS, (16.0 if horiz else 25.0) * TB.TS),
					"half": 11.0, "warn": 0.8, "fire": 0.25, "by": e.d["name"] })
				if hard:
					lanes.append({ "horiz": not horiz, "pos": clampf((p.x if horiz else p.y) + randf_range(-40.0, 40.0),
						(3.0 if horiz else 4.0) * TB.TS, (25.0 if horiz else 16.0) * TB.TS), "half": 9.0, "warn": 0.9, "fire": 0.25, "by": e.d["name"] })
				if e.sub == 0:
					Barks.say(e, "RED TAPE!", "white", 1.2)
				e.sub += 1
			elif e.sub >= 3 and e.t <= 0 and lanes.is_empty():
				BossAI.done(e, 0.6)
		&"tongue":   # THWIP: the tongue shoots down a line and pulls you in
			if tongue.is_empty() and e.t <= 0:
				if e.sub < (3 if e.stage >= 3 else 2):
					tongue = { "ax": cx, "ay": cy + 4.0, "a": TB.ang_xy(cx, cy + 4.0, p.x, p.y), "len": 0.0, "warn": 0.55, "fire": 0.0,
						"hit": false, "by": e.d["name"] }
					e.sub += 1
					e.t = 1.2
				else:
					BossAI.done(e, 0.6)
		# ----- PROPHET NIGH -----
		&"sermon":   # REPENT: three shouts, three rings with one gap
			if e.t <= 0:
				e.t = 0.55
				var line: String = ["REPENT!", "THE END IS NIGH!", "I TOLD YOU!", "WAKE UP!"][e.sub % 4]
				Barks.say(e, line, "red", 0.9)
				Combat.ering(cx, cy, 24 + e.sub * 2, 66.0 + e.sub * 8.0, randf() * TAU, "fire", true,
					TB.ang_to(e, p) + randf_range(-0.8, 0.8), 0.34)
				G.add_shake(2)
				e.sub += 1
				if e.sub >= (4 if hard else 3):
					BossAI.done(e)
		&"pamphlets":   # READ THIS: handfuls of pamphlets at you, and some everywhere
			if e.t <= 0:
				e.t = 0.42
				Combat.efan(cx, cy, TB.ang_to(e, p), 5, 0.6, 110, "page")
				for i in 3:
					Combat.eshot(cx, cy, randf() * TAU, randf_range(40.0, 70.0), "page")
				if e.sub == 0:
					Barks.say(e, "READ THIS!", "white", 1.2)
				e.sub += 1
				if e.sub >= 5:
					BossAI.done(e)
		&"meteors":   # THE SKY IS FALLING: meteors at marked spots, two on you
			if e.sub == 0:
				e.sub = 1
				var n := 12 if hard else 8
				for i in n:
					var at := Vector2(p.x, p.y) if i == 0 else (_floor_spot(p, 26.0) if i == 1 else _floor_spot(p, 170.0))
					_drop(at, "meteor", 20.0, 1.0 + i * 0.1, "fire", 8, e)
				Barks.say(e, "THE SKY IS FALLING!", "red", 1.6)
				e.t = 1.0 + n * 0.1 + 0.4
			elif e.t <= 0:
				BossAI.done(e)
		&"signslam", &"pounce":   # he leaps onto where you stand (a ring shows where), and lands hard
			_leap(e, p, dt, 3 if hard else 2, "fire" if e.state == &"signslam" else "dark",
				"NIGH!" if e.state == &"signslam" else "POUNCE!")
		&"doomsday":   # THE END: the room goes dark, a countdown, then the sky comes down
			if e.sub == 0:
				e.sub = 1
				e.t = 0.8
				e.repeat = 3
				Barks.say(e, "IT IS THE END! THE END!", "red", 2.4)
				_stat("doomsday")
			if e.repeat > 0 and e.t <= 0:
				Fx.float_text(cx, cy - 34, str(e.repeat), "red", true)
				Snd.play("deny")
				e.repeat -= 1
				e.t = 0.7
			elif e.repeat == 0 and e.sub == 1 and e.t <= 0:
				e.sub = 2
				Fx.float_text(cx, cy - 34, "THE END!", "red", true)
				G.add_shake(10)
				Snd.play("boom")
				Combat.ering(cx, cy, 30, 80, randf() * TAU, "fireBig")
				for i in 10:
					_drop(_floor_spot(p, 200.0) if i > 0 else Vector2(p.x, p.y), "meteor", 20.0, 0.7 + i * 0.08, "fire", 8, e)
				e.t = 1.8
			elif e.sub == 2 and e.t <= 0:
				BossAI.done(e, 0.8)
		# ----- BARON VON CHONK -----
		&"knock":   # *KNOCK*: a little table, things on it, and one by one off they go, at you
			if e.sub == 0:
				e.sub = 1
				e.t = 0.5
				var items := []
				for i in (5 if hard else 4):
					items.append(TB.pick(PROPS))
				table = { "x": clampf(e.x + 30.0 * e.face, 3.0 * TB.TS, 25.0 * TB.TS), "y": e.y + 8.0, "items": items }
				Barks.say(e, "OH NO. ANYWAY.", "white", 1.6)
			elif e.t <= 0 and not table.is_empty() and not (table["items"] as Array).is_empty():
				e.t = 0.45
				var kind: String = table["items"].pop_back()
				var to := Vector2(p.x + randf_range(-16.0, 16.0), p.y + randf_range(-12.0, 12.0))
				lobs.append({ "x0": table["x"], "y0": table["y"] - 10.0, "x1": to.x, "y1": to.y, "t": 0.0, "dur": LOB_T, "kind": kind,
					"by": e.d["name"] })
				Fx.float_text(table["x"], table["y"] - 24, "*KNOCK*", "white", false)
				Snd.play("ebullet")
				_stat("knock")
			elif e.t <= 0 and not table.is_empty():
				table = {}
				e.t = 0.6
			elif e.t <= 0:
				BossAI.done(e, 0.5)
		&"hairball":   # HACK HACK: a big hairball that bursts
			if e.t <= 0:
				if e.sub % 2 == 0:
					e.t = 0.45
					Fx.float_text(cx, cy - 26, "HACK! HACK!", "white", false)
					G.add_shake(2)
				else:
					e.t = 0.35
					Combat.eshot(cx, cy + 4, TB.ang_to(e, p), 85, "darkBig", 5.0, 0.95, "dark")
					Snd.play("ebullet")
				e.sub += 1
				if e.sub >= (6 if hard else 4):
					BossAI.done(e)
		&"nap":   # a cat nap, and his kittens to guard it (he takes half again)
			if e.sub == 0:
				e.sub = 1
				e.st = 0.0
				_stat("nap")
				Barks.say(e, "GUARD ME, KITTENS. ZZZ.", "white", 1.8)
				for i in 2:
					if G.enemies.size() < 8:
						var s := World.free_spot(G.room, p, 70, World.M_WALKER)
						Combat.spawn_enemy("kitten", s.x, s.y)
			elif e.sub == 1:
				if fmod(e.st, 0.6) < dt:
					Fx.float_text(e.x + 10, e.y - 30, "Z", "white", false)
				if e.st >= TRIP_T + 0.3:
					e.sub = 2
					Barks.say(e, "WHO WOKE ME?", "red", 1.4)
					Combat.ering(e.x, e.y - 4, 18, 75, randf(), "dark")
					BossAI.done(e, 0.3)
		&"zoomies":   # 3 A.M.: he tears round the room in straight lines, leaving fur behind
			if e.sub == 0:
				e.sub = 1
				var a := TB.ang_to(e, p)
				e.vx = cos(a) * 250.0
				e.vy = sin(a) * 250.0
				Barks.say(e, "ZOOMIES!", "white", 1.2)
			var nx := e.x + e.vx * dt
			var ny := e.y + e.vy * dt
			if nx < 2.5 * TB.TS or nx > 25.5 * TB.TS:
				e.vx = -e.vx
				nx = e.x
				e.vy += randf_range(-90.0, 90.0)
			if ny < 3.5 * TB.TS or ny > 16.0 * TB.TS:
				e.vy = -e.vy
				ny = e.y
				e.vx += randf_range(-90.0, 90.0)
			var v := Vector2(e.vx, e.vy).limit_length(280.0)
			e.vx = v.x
			e.vy = v.y
			e.x = nx
			e.y = ny
			e.face = 1 if e.vx > 0 else -1
			if e.t <= 0:
				e.t = 0.09
				Combat.eshot(e.x, e.y - 4, atan2(e.vy, e.vx) + PI + randf_range(-0.5, 0.5), 22, "dark")
				_trail(e)
			if e.st > (3.6 if e.stage >= 3 else 3.0):
				e.vx = 0.0
				e.vy = 0.0
				BossAI.done(e, 0.7)
		&"laserdot":   # the laser dot: it follows you, settles, and a laser strikes there
			if dot.is_empty() and e.t <= 0:
				if e.sub < (3 if e.stage >= 3 else 2):
					dot = { "x": p.x + randf_range(-40.0, 40.0), "y": p.y + randf_range(-30.0, 30.0), "t": 1.6, "lock": 0.45, "by": e.d["name"] }
					if e.sub == 0:
						Barks.say(e, "OOH. A DOT.", "white", 1.4)
					e.sub += 1
					e.t = 2.3
				else:
					BossAI.done(e, 0.5)
		_:
			BossAI.done(e)   # (an unknown move: rest instead)

## The donkey's lance charge: aim, a lit lane, the run, `n` times.
static func _lance(e: Enemy, p: Player, dt: float, n: int, spr: String) -> void:
	match e.sub:
		0:
			e.from = Vector2(e.x, e.y)
			var a := TB.ang_to(e, p)
			e.to = Vector2(clampf(e.x + cos(a) * 280.0, 2.5 * TB.TS, 25.5 * TB.TS), clampf(e.y + sin(a) * 280.0, 3.5 * TB.TS, 16.0 * TB.TS))
			aim = { "ax": e.from.x, "ay": e.from.y, "bx": e.to.x, "by": e.to.y, "r": 0.0 }
			e.face = 1 if e.to.x > e.x else -1
			e.st = 0.0
			e.sub = 1
			if e.repeat == 0:
				Barks.say(e, "FOR JUSTICE! AND CARROTS!", "white", 1.4)
		1:
			if e.st >= 0.65:
				e.sub = 2
				e.st = 0.0
				Snd.play("charge")
		2:
			var k := minf(1.0, e.st / 0.42)
			e.x = e.from.x + (e.to.x - e.from.x) * k
			e.y = e.from.y + (e.to.y - e.from.y) * k
			if e.t <= 0:
				e.t = 0.05
				var a := atan2(e.to.y - e.from.y, e.to.x - e.from.x)
				Combat.eshot(e.x, e.y - 6, a + PI / 2, 70, spr)
				Combat.eshot(e.x, e.y - 6, a - PI / 2, 70, spr)
				_trail(e)
			if k >= 1.0:
				aim = {}
				G.add_shake(4)
				e.repeat += 1
				if e.repeat >= n:
					e.repeat = 0
					BossAI.done(e, 0.9)
				else:
					e.sub = 0

## A leap onto where you stand: a ring marks the spot, then the landing.
static func _leap(e: Enemy, p: Player, dt: float, n: int, spr: String, word: String) -> void:
	if e.sub == 0:
		e.from = Vector2(e.x, e.y)
		e.to = Vector2(clampf(p.x, 3.0 * TB.TS, 25.0 * TB.TS), clampf(p.y, 4.0 * TB.TS, 15.0 * TB.TS))
		aim = { "ax": e.to.x, "ay": e.to.y, "bx": e.to.x, "by": e.to.y, "r": 26.0 }
		e.sub = 1
		e.st = 0.0
		Snd.play("charge")
	var k := minf(1.0, e.st / 0.8)
	e.x = e.from.x + (e.to.x - e.from.x) * k
	e.y = e.from.y + (e.to.y - e.from.y) * k
	e.z = sin(k * PI) * 40.0
	if k >= 1.0:
		e.z = 0.0
		aim = {}
		G.add_shake(8)
		Snd.play("boom")
		Fx.float_text(e.x, e.y - 34, word, "white", true)
		Combat.ering(e.x, e.y, 24 if e.stage >= 2 else 18, 85, randf(), spr)
		Fx.burst(e.x, e.y + 6, ["#8b8f9c", "#d9d0b4"], 18, 90)
		if TB.dist(e, p) < 26.0 + p.r:
			Combat.hurt_player(1, e.d["name"])
		e.repeat += 1
		if e.repeat >= n:
			e.repeat = 0
			BossAI.done(e, 0.8)
		else:
			e.sub = 0

static func _trail(e: Enemy) -> void:
	if trail.size() < 8:
		trail.append({ "x": e.x, "y": e.y, "t": 0.3, "face": e.face })

## A spot on the floor near you, inside the room.
static func _floor_spot(p: Player, spread: float) -> Vector2:
	return Vector2(clampf(p.x + randf_range(-spread, spread), 2.0 * TB.TS, 26.0 * TB.TS),
		clampf(p.y + randf_range(-spread * 0.7, spread * 0.7), 3.5 * TB.TS, 16.5 * TB.TS))

static func _drop(at: Vector2, kind: String, r: float, warn: float, spr: String, n: int, e: Enemy) -> void:
	drops.append({ "x": at.x, "y": at.y, "warn": warn, "max": warn, "kind": kind, "r": r, "by": e.d["name"], "n": n, "spr": spr })

# ---------- Every tick (Hazards.update) ----------
static func tick(dt: float) -> void:
	if _room == null or _room.get_ref() != G.room:
		clear()
		_room = weakref(G.room)
	mog_t = maxf(0.0, mog_t - dt)
	mog_cd = maxf(0.0, mog_cd - dt)
	if wait > 0.0:
		wait -= dt
		if wait <= 0.0 and G.run_stats.has("finale") and not G.run_stats.get("finale_done", false):
			enter(G.run_stats["finale"])
	if not live():
		return
	var p := G.player
	if G.boss != null and G.boss.d.get("no_flip", false):
		G.boss.face = 1   # the prophet's sign reads the right way round
	dark = maxf(0.0, dark - dt * 0.5) if not (G.boss != null and G.boss.state == &"doomsday") else minf(0.55, dark + dt)
	if not trail.is_empty():
		for tr in trail:
			tr["t"] -= dt
		trail = trail.filter(func(tr): return tr["t"] > 0.0)
	_tick_drops(p, dt)
	_tick_lobs(p, dt)
	_tick_lanes(p, dt)
	_tick_tongue(p, dt)
	_tick_dot(p, dt)
	_tick_flex(p, dt)

static func _tick_drops(p: Player, dt: float) -> void:
	if drops.is_empty():
		return
	var keep := []
	for d in drops:
		d["warn"] -= dt
		if d["warn"] > 0.0:
			keep.append(d)
			continue
		# It lands: whoever stands under it is hit, and it bursts.
		if TB.dist_xy(p.x, p.y, d["x"], d["y"]) < d["r"] + p.r * 0.5:
			Combat.hurt_player(1, d["by"])
		Combat.ering(d["x"], d["y"], d["n"], 70, randf() * TAU, d["spr"])
		Fx.burst(d["x"], d["y"], ["#f4ecd8", "#ff8a2a" if d["kind"] == "meteor" else "#d9d0b4"], 10, 70)
		if d["kind"] == "stamp":
			Fx.float_text(d["x"], d["y"] - 20, "VETOED!", "red", true)
		G.add_shake(3 if d["kind"] == "meteor" else 2)
		_stat("drop_" + String(d["kind"]))
	drops = keep

static func _tick_lobs(p: Player, dt: float) -> void:
	if lobs.is_empty():
		return
	var keep := []
	for l in lobs:
		l["t"] += dt
		if l["t"] < l["dur"]:
			keep.append(l)
			continue
		# It shatters where it lands.
		if TB.dist_xy(p.x, p.y, l["x1"], l["y1"]) < 12.0 + p.r * 0.5:
			Combat.hurt_player(1, l["by"])
		var spr := "water" if l["kind"] == "bowl" else ("page" if l["kind"] == "mug" else "bone")
		Combat.ering(l["x1"], l["y1"], 8, 72, randf() * TAU, spr)
		Fx.burst(l["x1"], l["y1"], ["#f4ecd8", "#4d9be6" if l["kind"] in ["vase", "bowl"] else "#c8643a"], 12, 80)
		Fx.float_text(l["x1"], l["y1"] - 16, "CRASH!", "white", false)
		Snd.play("hit")
		_stat("crash")
	lobs = keep

static func _tick_lanes(p: Player, dt: float) -> void:
	if lanes.is_empty():
		return
	var keep := []
	for b in lanes:
		if b["warn"] > 0.0:
			b["warn"] -= dt
			if b["warn"] <= 0.0:
				if absf((p.y if b["horiz"] else p.x) - b["pos"]) < b["half"] + p.r * 0.5:
					Combat.hurt_player(1, b["by"])
				G.add_shake(2)
				Snd.play("bolt")
				_stat("tape")
			keep.append(b)
			continue
		b["fire"] -= dt
		if b["fire"] > 0.0:
			keep.append(b)
	lanes = keep

static func _tick_tongue(p: Player, dt: float) -> void:
	if tongue.is_empty():
		return
	var b := G.boss
	if b == null or b.hp <= 0:
		tongue = {}
		return
	tongue["ax"] = b.x
	tongue["ay"] = b.y - 4.0
	if tongue["warn"] > 0.0:
		tongue["warn"] -= dt
		if tongue["warn"] <= 0.0:
			tongue["fire"] = 0.35
			Fx.float_text(b.x, b.y - 30, "THWIP!", "pink", false)
			Snd.play("charge")
		return
	tongue["fire"] -= dt
	tongue["len"] = minf(230.0, tongue["len"] + dt * 1500.0)
	var a: float = tongue["a"]
	var tip: Vector2 = Vector2(tongue["ax"], tongue["ay"]) + Vector2.from_angle(a) * float(tongue["len"])
	if not tongue["hit"] and _near_seg(Vector2(p.x, p.y), Vector2(tongue["ax"], tongue["ay"]), tip, 7.0 + p.r * 0.5):
		tongue["hit"] = true
		Combat.hurt_player(1, tongue["by"])
		var pull := (Vector2(b.x, b.y) - Vector2(p.x, p.y)).normalized() * 50.0
		World.move_body(G.room, p, pull.x, pull.y, World.M_PLAYER)
		_stat("tongue")
	if tongue["fire"] <= 0.0:
		tongue = {}

static func _tick_dot(p: Player, dt: float) -> void:
	if dot.is_empty():
		return
	if dot["t"] > 0.0:   # it follows you, a little behind
		dot["t"] -= dt
		dot["x"] = lerpf(dot["x"], p.x, minf(1.0, dt * 3.0))
		dot["y"] = lerpf(dot["y"], p.y, minf(1.0, dt * 3.0))
		return
	dot["lock"] -= dt
	if dot["lock"] > 0.0:
		return
	if TB.dist_xy(p.x, p.y, dot["x"], dot["y"]) < 16.0 + p.r * 0.5:
		Combat.hurt_player(1, dot["by"])
	Combat.ering(dot["x"], dot["y"], 12, 75, randf() * TAU, "red")
	Fx.burst(dot["x"], dot["y"], ["#ff3a3a", "#ffffff"], 14, 90)
	G.add_shake(4)
	Snd.play("boom")
	_stat("laser")
	dot = {}

## Believers flex at you when you come close: MOGGED.
static func _tick_flex(p: Player, dt: float) -> void:
	for e: Enemy in G.enemies:
		if e.type != "believer" or e.hp <= 0 or e.spawn_t > 0:
			continue
		if not flexers.has(e.uid):
			flexers[e.uid] = { "cd": randf_range(1.0, 2.5), "pose": 0.0 }
		var f: Dictionary = flexers[e.uid]
		f["cd"] -= dt
		f["pose"] = maxf(0.0, f["pose"] - dt)
		if f["cd"] <= 0.0 and TB.dist(e, p) < FLEX_R and e.stun_t <= 0.0:
			f["cd"] = 3.5
			f["pose"] = 0.7
			Fx.float_text(e.x, e.y - 22, "FLEX!", "gold", false)
			_stat("flex")
			if mog_cd <= 0.0 and p.dodge_t <= 0.0:
				mog_t = MOG_T
				mog_cd = MOG_CD
				Fx.float_text(p.x, p.y - 26, "MOGGED!", "pink", true)
				Snd.play("deny")
				_stat("mogged")

static func _near_seg(q: Vector2, a: Vector2, b: Vector2, w: float) -> bool:
	var ab := b - a
	var l2 := ab.length_squared()
	var k := 0.0 if l2 < 0.01 else clampf((q - a).dot(ab) / l2, 0.0, 1.0)
	return q.distance_to(a + ab * k) < w

# ---------- Drawing ----------
## Under the people (world_view): what warns. Shadows where things will land, the lit lanes, the
## lance's path, the tongue's line, the dot.
static func draw_ground(ci: CanvasItem, t: float) -> void:
	if not live():
		return
	if dark > 0.0:
		ci.draw_rect(Rect2(0, 0, TB.SW, TB.SH), Color(0.05, 0.0, 0.03, dark))
	var blink := fmod(t * 8.0, 2.0) < 1.0
	for d in drops:
		var k: float = 1.0 - clampf(d["warn"] / d["max"], 0.0, 1.0)
		var at := Vector2(d["x"], d["y"])
		ci.draw_circle(at, d["r"] * (0.3 + 0.7 * k), Color(0.08, 0.02, 0.06, 0.35 + 0.25 * k))
		ci.draw_arc(at, d["r"], 0.0, TAU, 24, Color(1.0, 0.45, 0.3, 0.9 if blink else 0.5), 1.0)
	for b in lanes:
		if b["warn"] <= 0.0:
			continue
		var rect := Rect2(TB.TS, b["pos"] - b["half"], TB.SW - 2 * TB.TS, b["half"] * 2) if b["horiz"] \
			else Rect2(b["pos"] - b["half"], 2 * TB.TS, b["half"] * 2, 15 * TB.TS)
		ci.draw_rect(rect, Color(0.85, 0.2, 0.2, 0.12 + 0.12 * (1.0 - b["warn"] / 0.9)))
		var edge := Color(0.95, 0.3, 0.3, 0.95 if blink else 0.55)
		if b["horiz"]:
			ci.draw_rect(Rect2(rect.position.x, rect.position.y, rect.size.x, 1), edge)
			ci.draw_rect(Rect2(rect.position.x, rect.end.y - 1, rect.size.x, 1), edge)
		else:
			ci.draw_rect(Rect2(rect.position.x, rect.position.y, 1, rect.size.y), edge)
			ci.draw_rect(Rect2(rect.end.x - 1, rect.position.y, 1, rect.size.y), edge)
	if not aim.is_empty():
		if aim["r"] > 0.0:
			ci.draw_arc(Vector2(aim["ax"], aim["ay"]), aim["r"], 0.0, TAU, 28, Color(1.0, 0.4, 0.3, 0.9 if blink else 0.5), 1.0)
			ci.draw_circle(Vector2(aim["ax"], aim["ay"]), aim["r"], Color(0.9, 0.2, 0.2, 0.12))
		else:
			ci.draw_line(Vector2(aim["ax"], aim["ay"]), Vector2(aim["bx"], aim["by"]), Color(1.0, 0.4, 0.3, 0.75 if blink else 0.35), 9.0)
	if not tongue.is_empty() and tongue["warn"] > 0.0:
		var a: float = tongue["a"]
		var o := Vector2(tongue["ax"], tongue["ay"])
		ci.draw_line(o, o + Vector2.from_angle(a) * 230.0, Color(0.9, 0.35, 0.47, 0.8 if blink else 0.35), 1.0)
	if not dot.is_empty():
		var at := Vector2(dot["x"], dot["y"])
		if dot["t"] <= 0.0:
			ci.draw_arc(at, 16.0, 0.0, TAU, 24, Color(1.0, 0.25, 0.25, 0.95 if blink else 0.5), 1.0)
			ci.draw_circle(at, 16.0, Color(1.0, 0.1, 0.1, 0.15))
		ci.draw_circle(at, 2.0, Color(1.0, 0.15, 0.15))
		ci.draw_circle(at, 1.0, Color(1.0, 0.8, 0.8))
	for tr in trail:
		var b := G.boss
		if b == null:
			break
		var nm := _boss_sprite(b)
		Gfx.sp(ci, nm, tr["x"], tr["y"] + b.r + 2, b.scale, b.scale, 0.0, tr["face"] < 0, tr["t"] * 1.5, Color(1.0, 0.9, 0.6, 0.6))

static func _boss_sprite(b: Enemy) -> String:
	var key: String = b.d["sprite"]
	return key + "_s%d" % b.stage if b.stage > 1 and Img.has(key + "_s%d" % b.stage) else key

## Over the people (world_view): falling things, thrown things, the table, the strikes, the tongue,
## a tripped donkey's stars and MOGGED.
static func draw_over(ci: CanvasItem, t: float) -> void:
	if mog_t > 0.0 and G.player != null:   # a little cloud of shame over your head
		var p := G.player
		Gfx.text(ci, "MOGGED", p.x, p.y - 26 + sin(t * 10.0) * 1.5, "pink", 1, 0.5)
	if not live():
		return
	for d in drops:
		var k: float = 1.0 - clampf(d["warn"] / d["max"], 0.0, 1.0)
		if k < 0.35:
			continue
		var fall := (1.0 - (k - 0.35) / 0.65) * 120.0
		Gfx.sp(ci, "fp_" + String(d["kind"]), d["x"], d["y"] - fall, 1.5, 1.5)
	for l in lobs:
		var k: float = l["t"] / l["dur"]
		var x: float = l["x0"] + (l["x1"] - l["x0"]) * k
		var y: float = l["y0"] + (l["y1"] - l["y0"]) * k - sin(k * PI) * 46.0
		Gfx.sp(ci, "fp_" + String(l["kind"]), x, y, 1.5, 1.5, k * TAU * 1.5)
	if not table.is_empty():
		Gfx.sp(ci, "fp_table", table["x"], table["y"], 1.0, 1.0)
		var items: Array = table["items"]
		for i in items.size():
			Gfx.sp(ci, "fp_" + String(items[i]), table["x"] - 9.0 + i * 5.0, table["y"] - 11.0, 1.0, 1.0)
	for b in lanes:
		if b["warn"] > 0.0:
			continue
		var rect := Rect2(TB.TS, b["pos"] - 4, TB.SW - 2 * TB.TS, 8) if b["horiz"] else Rect2(b["pos"] - 4, 2 * TB.TS, 8, 15 * TB.TS)
		ci.draw_rect(rect, Color(0.85, 0.15, 0.15, 0.9))
		ci.draw_rect(rect.grow(-2), Color(1.0, 0.45, 0.4, 1.0))
	if not tongue.is_empty() and tongue["warn"] <= 0.0:
		var a: float = tongue["a"]
		var o := Vector2(tongue["ax"], tongue["ay"])
		var tip: Vector2 = o + Vector2.from_angle(a) * float(tongue["len"])
		ci.draw_line(o, tip, Color(0.88, 0.35, 0.47), 3.0)
		ci.draw_line(o, tip, Color(1.0, 0.6, 0.7), 1.0)
		ci.draw_circle(tip, 3.0, Color(0.88, 0.35, 0.47))
	var b := G.boss
	if b != null and handles(b) and (b.state == &"trip" or b.state == &"nap") and b.sub == 1:
		var top := Vector2(b.x, b.y - b.r * 1.5 - 14.0)
		for k in 3:   # stars round a donkey's head, or a cat's dream bubble
			var a := t * 4.0 + k * TAU / 3.0
			var at := top + Vector2(cos(a) * 9.0, sin(a) * 3.0)
			ci.draw_rect(Rect2(roundf(at.x), roundf(at.y), 2, 2), TB.c("#fff07a" if b.state == &"trip" else "#bfefff"))
