class_name Coop
extends RefCounted
## Windows couch co-op (COOP_PLAN.md; the Windows line only, never on the iPad). Up to 4 heroes in
## the same room, each with their own device (Keys.pads). The game was made for one hero (G.player):
## for each hero's own work it runs with G.player set to that hero and Keys set to their pad
## (enter / leave). Foes work against their nearest standing hero, foe shots test every hero, a shot
## belongs to the hero who fired it (PBullet.owner_i), pickups go to the nearest hero. With one
## player none of this runs: the game is exactly as before.

const MAX := 4
const COLORS := ["#e8573a", "#4d9be6", "#7ad86a", "#f2c94c"]   # P1 red, P2 blue, P3 green, P4 gold
const FONT := ["red", "cyan", "lime", "gold"]
const SPOTS := [Vector2(-16, 0), Vector2(16, 0), Vector2(0, 14)]   # where P2 to P4 stand beside P1
const REVIVE_TIME := 3.0
const REVIVE_R := 18.0

static var extras: Array = []        # P2 to P4 (Player)
static var want: Array = []          # hero indexes of the next run, P1 first (joining; --coop=N)
static var pads: Array = [-1]        # each player's pad in Keys (-1: every device)
static var bots: Array = [false]     # played by the test bot (--coop=N)
static var actor := 0                # the hero acting now: their new shots are theirs
static var downs := {}               # downed heroes (Player -> true)
static var revive := {}              # Player -> seconds a friend has stood by them
static var _lead: Player = null      # P1
static var _hs: Array = []           # [P1] + extras, kept between changes
static var _tgt := {}                # foe uid -> [hero index, time to choose again]
static var _building := false
static var _fams: Array = []
static var _bot_t: Array = [0.0, 0.0, 0.0, 0.0]
static var wait_msg := ""            # who the door waits for (drawn by draw_tags)
static var _door_t := 0.0            # how long a hero has waited at a door (the test bots catch up)

static func on() -> bool:
	return not extras.is_empty()

static func count() -> int:
	return 1 + extras.size()

static func lead() -> Player:
	return _lead if _lead != null else G.player

static func heroes() -> Array:
	if _hs.size() != count() or (not _hs.is_empty() and _hs[0] != lead()):
		_hs = [lead()] + extras
	return _hs

static func index_of(p: Player) -> int:
	return heroes().find(p)

static func is_down(p: Player) -> bool:
	return downs.has(p)

## The standing heroes.
static func standing() -> Array:
	return heroes().filter(func(h): return not downs.has(h))

## Hero i's turn: G.player is them, the input is their pad, their new shots are theirs.
static func enter(i: int) -> void:
	G.player = heroes()[i]
	actor = i
	Keys.use_pad(pads[i] if i < pads.size() else -1)

## Back to P1.
static func leave() -> void:
	G.player = lead()
	actor = 0
	Keys.use_pad(pads[0] if not pads.is_empty() else -1)

# ---------- the run ----------
## --coop=N (tests and playing alone): N heroes, P2 on are played by the test bot. Main, before the
## run starts.
static func from_args() -> void:
	if not DebugArgs.has("coop"):
		return
	var n := clampi(DebugArgs.get_int("coop", 1), 1, MAX)
	var order := GameData.hero_order()
	want = [G.hero_index]
	pads = [-1]
	bots = [false]
	Keys.clear_pads()
	for i in range(1, n):
		want.append(order[(order.find(G.hero_index) + i) % order.size()])
		pads.append(Keys.add_pad("bot"))
		bots.append(true)
	Meta.opts["autofire"] = true

## Game.new_run, first: P2 to P4 are each made by a whole run of their own (all a hero gets at the
## start: weapon, tree, traits, perks, stars, the gourd...); P1's run, the last, is the real one.
static func before_run() -> void:
	if _building:
		return
	extras.clear()
	downs.clear()
	revive.clear()
	_tgt.clear()
	_lead = null
	_hs = []
	_fams = []
	if want.size() <= 1:
		return
	_building = true
	var p1_hero := G.hero_index
	var runs0: int = Meta.meta.get("runs", 0)
	for i in range(1, mini(want.size(), MAX)):
		G.hero_index = want[i]
		G.new_run()
		var h: Player = G.player
		h.oath_picks = 0   # (an oath is P1's; level-ups come in turn: C3)
		h.pending = 0
		extras.append(h)
		_fams.append_array(G.familiars)
	G.hero_index = p1_hero
	Meta.meta["runs"] = runs0
	_building = false

## Game.enter_room (after P1 is placed): P2 to P4 come in beside P1, as fresh in the room as P1.
static func enter_room(p: Player) -> void:
	if _building or extras.is_empty():
		return
	if _lead == null:
		_lead = p
		_hs = []
		if not _fams.is_empty():
			G.familiars.append_array(_fams)
			_fams = []
	_tgt.clear()
	for i in extras.size():
		var h: Player = extras[i]
		h.buckler_used = false
		h.volleys = []
		h.trail = []
		h.dodge_t = 0.0
		if h.leap_max > 0:
			h.dash_t = 0.0
			h.leap_max = 0.0
			h.air = 0.0
			h.dash_end = []
		h.room_kills = 0
		if h.ironskin:
			h.armor = maxi(h.armor, 1)
		var s: Vector2 = Vector2(p.x, p.y) + SPOTS[i]
		if World.hits_solid(G.room, s.x, s.y, h.r, World.M_WALKER):
			s = Vector2(p.x, p.y)
		h.x = clampf(s.x, TB.TS, TB.SW - TB.TS)
		h.y = clampf(s.y, TB.TS * 1.3, TB.SH - TB.TS)

# ---------- every tick ----------
## Game.update_play: each standing hero's turn (P1 first, with their own pad).
static func update_heroes(p: Player, dt: float) -> void:
	if extras.is_empty():
		Combat.update_player(p, dt)
		return
	_lead = p
	Keys.use_pad(pads[0])
	if not downs.has(p):
		Combat.update_player(p, dt)
	for i in range(1, count()):
		var h: Player = extras[i - 1]
		if downs.has(h):
			continue
		enter(i)
		if i < bots.size() and bots[i]:
			_bot(i, h, dt)
		Effects.tick(dt)
		Combat.update_player(h, dt)
		leave()
	_revive_tick(dt)

## Combat.update_enemies, for each foe: the hero it works against (its nearest standing one, chosen
## again every second or so). With one hero: that hero.
static func foe_target(e: Enemy, p0: Player) -> Player:
	if extras.is_empty():
		return p0
	var hs := heroes()
	var t = _tgt.get(e.uid)
	if t == null or G.time >= t[1] or downs.has(hs[t[0]]):
		var best := -1
		var bd := INF
		for i in hs.size():
			var h: Player = hs[i]
			if downs.has(h):
				continue
			var d: float = (h.x - e.x) * (h.x - e.x) + (h.y - e.y) * (h.y - e.y)
			if d < bd:
				bd = d
				best = i
		if best < 0:
			best = 0
		t = [best, G.time + 1.0 + float(e.uid % 7) * 0.1]
		_tgt[e.uid] = t
	var tgt: Player = hs[t[0]]
	G.player = tgt
	actor = t[0]
	return tgt

## After the foes: back to P1.
static func foes_done(p0: Player) -> void:
	G.player = p0
	actor = 0

## EBullets.update: a foe shot at (x, y) of radius r on P2 to P4: the hero hit, or -1.
static func shot_hit(x: float, y: float, r: float) -> int:
	for i in extras.size():
		var h: Player = extras[i]
		if downs.has(h) or h.dodge_t > 0 or h.invuln > 0:
			continue
		var rr := r + h.hit_r
		if (h.x - x) * (h.x - x) + (h.y - 2 - y) * (h.y - 2 - y) < rr * rr:
			return i + 1
	return -1

## Hurts hero i as Combat.hurt_player hurts P1.
static func hurt(i: int, amount: int, source: String) -> void:
	var keep: Player = G.player
	var keep_actor := actor
	G.player = heroes()[i]
	actor = i
	Combat.hurt_player(amount, source)
	G.player = keep
	actor = keep_actor

## Your shots, each hero's processed with them as the player (their crits, procs and kills).
static func update_pbullets(dt: float) -> void:
	if extras.is_empty():
		Combat.update_pbullets(dt)
		return
	var n := count()
	var groups := []
	for i in n:
		var g: Array[PBullet] = []
		groups.append(g)
	for b in G.pbullets:
		groups[clampi(b.owner_i, 0, n - 1)].append(b)
	var all: Array[PBullet] = []
	for i in n:
		if groups[i].is_empty():
			continue
		enter(i)
		G.pbullets = groups[i]
		Combat.update_pbullets(dt)
		for b in G.pbullets:
			b.owner_i = i
		all.append_array(G.pbullets)
		leave()
	G.pbullets = all

## Pickups: each to the nearest standing hero (as in Brotato, not shared).
static func update_pickups(dt: float) -> void:
	if extras.is_empty():
		Combat.update_pickups(dt)
		return
	var hs := heroes()
	var groups := []
	for i in hs.size():
		groups.append([])
	for k in G.pickups:
		var best := 0
		var bd := INF
		for i in hs.size():
			var h: Player = hs[i]
			if downs.has(h):
				continue
			var d: float = (h.x - k.x) * (h.x - k.x) + (h.y - k.y) * (h.y - k.y)
			if d < bd:
				bd = d
				best = i
		groups[best].append(k)
	var all := []
	for i in hs.size():
		if groups[i].is_empty():
			continue
		enter(i)
		G.pickups = groups[i]
		Combat.update_pickups(dt)
		all.append_array(G.pickups)
		leave()
	G.pickups = all

# ---------- down, not out ----------
## Combat.hurt_player, before the run would end: in co-op a hero with no hearts left is DOWN, and the
## run goes on while anyone stands. True: it is not over.
static func downed(p: Player, _source: String) -> bool:
	if extras.is_empty():
		return false
	downs[p] = true
	revive.erase(p)
	p.hp = 0
	p.dodge_t = 0.0
	Fx.burst(p.x, p.y, ["#8b8f9c", "#f4ecd8"], 18, 60)
	G.show_banner("P%d IS DOWN" % (index_of(p) + 1), "STAND BY THEM TO HELP THEM UP")
	Snd.play("hurt")
	if standing().is_empty():
		downs.clear()
		return false   # everyone is down: the run ends
	return true

## Standing by a downed friend for REVIVE_TIME brings them back with a heart; a cleared room brings
## every downed hero back.
static func _revive_tick(dt: float) -> void:
	if downs.is_empty():
		return
	for h in downs.keys():
		var near := false
		for o in standing():
			if TB.dist_xy(o.x, o.y, h.x, h.y) < REVIVE_R:
				near = true
		if near:
			revive[h] = revive.get(h, 0.0) + dt
			if revive[h] >= REVIVE_TIME:
				_up(h)
		else:
			revive[h] = maxf(0.0, revive.get(h, 0.0) - dt)

static func on_room_clear() -> void:
	for h in downs.keys():
		_up(h)

static func _up(h: Player) -> void:
	downs.erase(h)
	revive.erase(h)
	h.hp = mini(2, h.max_hp)
	h.invuln = 2.0
	Fx.burst(h.x, h.y, ["#f2c94c", "#ffffff"], 16, 60)
	G.toast("P%d IS BACK UP" % (index_of(h) + 1), FONT[clampi(index_of(h), 0, 3)])
	Snd.play("heal")

# ---------- rooms ----------
## Game.update_play's way out of a cleared room. True: co-op handled it (the party goes when every
## standing hero is at the same door); false: one hero, the game's own check runs.
static func exits() -> bool:
	if extras.is_empty():
		return false
	var room := G.room
	var dir := ""
	var missing := []
	var hs := heroes()
	for i in hs.size():
		var h: Player = hs[i]
		if downs.has(h):
			continue
		var d := _door_of(h)
		if d != "" and room.exits.has(d) and not room.sealed.has(d):
			if dir == "":
				dir = d
			elif d != dir:
				missing.append("P%d" % (i + 1))
		else:
			missing.append("P%d" % (i + 1))
	if dir == "":
		wait_msg = ""
		_door_t = 0.0
		return true
	if not missing.is_empty():
		wait_msg = "THE DOOR WAITS FOR " + ", ".join(missing)
		_door_t += TB.DT
		if _door_t > 3.0:
			_bots_to(dir)   # (only the test bots: they walk badly)
		return true
	wait_msg = ""
	_door_t = 0.0
	var p := lead()   # everyone is at the door: P1 leads the way, the others come along
	p.x = clampf(p.x, TB.TS, TB.SW - TB.TS)
	p.y = clampf(p.y, TB.TS * 1.3, TB.SH - TB.TS)
	G.leave_room(dir)
	return true

static func _door_of(h: Player) -> String:
	if h.y < TB.TS * 1.2: return "n"
	if h.y > TB.SH - TB.TS * 0.7: return "s"
	if h.x < TB.TS * 0.6: return "w"
	if h.x > TB.SW - TB.TS * 0.6: return "e"
	return ""

## The test bots that are not at the door are put by whoever waits there.
static func _bots_to(dir: String) -> void:
	var at: Player = null
	for h in standing():
		if _door_of(h) == dir:
			at = h
	if at == null:
		return
	for i in range(1, count()):
		var h: Player = heroes()[i]
		if i < bots.size() and bots[i] and not downs.has(h) and _door_of(h) != dir:
			h.x = at.x
			h.y = at.y

# ---------- the test bot (--coop=N) ----------
static func _bot(i: int, h: Player, dt: float) -> void:
	_bot_t[i] -= dt
	if _bot_t[i] > 0:
		return
	_bot_t[i] = 0.4 + randf() * 0.4
	var b: Dictionary = Keys.pads[pads[i]]["bot"]
	for a in [&"move_left", &"move_right", &"move_up", &"move_down", &"roll"]:
		b[a] = false
	var e = Combat.auto_target(h, 400) if G.enemies_active() else null   # (not the practice dummies)
	var v := Vector2(randf() - 0.5, randf() - 0.5)
	if e != null:
		var to := Vector2(e.x - h.x, e.y - h.y)
		v = to if to.length() > 90 else (-to if to.length() < 50 else to.orthogonal())
	elif G.room != null and not G.locked:
		v = Vector2(lead().x - h.x, lead().y - h.y)   # follow P1 to the door
	if v.x < -0.2: b[&"move_left"] = true
	if v.x > 0.2: b[&"move_right"] = true
	if v.y < -0.2: b[&"move_up"] = true
	if v.y > 0.2: b[&"move_down"] = true
	b[&"roll"] = randf() < 0.1

# ---------- drawing ----------
## WorldView._paint_top: a downed hero, grey and still, with the time to help them up.
static func draw_downed(ci: CanvasItem) -> void:
	for h in downs.keys():
		var c := Color(0.55, 0.55, 0.62, 0.7)
		Gfx.at(ci, h.hero["sprite"], h.x - 8, h.y - 12, 0.45)
		ci.draw_rect(Rect2(roundf(h.x - 6), roundf(h.y + 5), 12, 2), c)
		var f: float = revive.get(h, 0.0) / REVIVE_TIME
		if f > 0:
			ci.draw_rect(Rect2(roundf(h.x - 8), roundf(h.y - 18), roundf(16 * f), 2), TB.c("#f2c94c"))

## Every hero's tag (P1 to P4 in their colour) and aim dot; who the door waits for.
static func draw_tags(ci: CanvasItem) -> void:
	if wait_msg != "":
		var w := TB.text_w(wait_msg) + 8
		ci.draw_rect(Rect2((TB.SW - w) / 2, 34, w, 11), Color(0.05, 0.04, 0.07, 0.8))
		Gfx.text(ci, wait_msg, TB.SW / 2, 37, "gold", 1, 0.5)
	var hs := heroes()
	for i in hs.size():
		var h: Player = hs[i]
		Gfx.text(ci, "P%d" % (i + 1), roundf(h.x), roundf(h.y - 22), FONT[i], 1, 0.5)
		if downs.has(h):
			continue
		var c := TB.c(COLORS[i])
		var at := Vector2(roundf(h.x), roundf(h.y) + 6.0)
		ci.draw_arc(at, 8.0, 0.0, TAU, 20, Color(c, 0.75), 1.0)
		if i > 0:
			var ax := h.x + cos(h.aim_a) * 16
			var ay := h.y - 2 + sin(h.aim_a) * 16
			ci.draw_rect(Rect2(roundf(ax - 2), roundf(ay - 2), 4, 4), TB.c("#1a1423"))
			ci.draw_rect(Rect2(roundf(ax - 1), roundf(ay - 1), 2, 2), c)

## HudView: a small panel for P2 to P4 along the bottom (their tag, hearts, gold).
static func draw_hud(ci: CanvasItem) -> void:
	for i in extras.size():
		var h: Player = extras[i]
		var x := 4 + i * 112
		var y := TB.SH - 26
		ci.draw_rect(Rect2(x - 2, y - 2, 108, 11), Color(0.05, 0.04, 0.07, 0.75))
		Gfx.text(ci, "P%d" % (i + 2), x, y, FONT[i + 1])
		if downs.has(h):
			Gfx.text(ci, "DOWN", x + 14, y, "grey")
			continue
		for k in mini(h.max_hp / 2, 8):
			var v := h.hp - k * 2
			Gfx.at(ci, "heart_" + ("full" if v >= 2 else ("half" if v == 1 else "empty")), x + 14 + k * 8, y - 1, 1.0)
		Gfx.text(ci, "%d" % h.gold, x + 104, y, "gold", 1, 1.0)

## HudView's signature: what P2 to P4's panels show.
static func hud_sig() -> Array:
	var out := []
	for h in extras:
		out.append([h.hp, h.max_hp, h.gold, downs.has(h)])
	return out
