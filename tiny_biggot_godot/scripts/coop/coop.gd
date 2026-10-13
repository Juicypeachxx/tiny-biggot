class_name Coop
extends RefCounted
## Windows couch co-op (COOP_PLAN.md; the Windows line only, never on the iPad). Up to 4 heroes in
## the same room, each with their own device (Keys.pads). The game was made for one hero (G.player):
## for each hero's own work it runs with G.player set to that hero and Keys set to their pad
## (enter / leave). Foes work against their nearest standing hero, foe shots test every hero, a shot
## belongs to the hero who fired it (PBullet.owner_i), pickups go to the nearest hero. The players
## join on the title's CO-OP screen (the lobby below). With one player none of this runs: the game is
## exactly as before.

const MAX := 4
const COLORS := ["#e8573a", "#4d9be6", "#7ad86a", "#f2c94c"]   # P1 red, P2 blue, P3 green, P4 gold
const FONT := ["red", "cyan", "lime", "gold"]
const SPOTS := [Vector2(-16, 0), Vector2(16, 0), Vector2(0, 14)]   # where P2 to P4 stand beside P1
const REVIVE_TIME := 3.0
const REVIVE_R := 18.0
const HP_PER := 0.6      # foes and mini-bosses: +60% health for each extra player
const BOSS_PER := 0.75   # guardians: +75%
const WAVE_PER := 0.25   # waves: +25% foes for each extra player (rounded up)

static var extras: Array = []        # P2 to P4 (Player)
static var want: Array = []          # hero indexes of the next run, P1 first (joining; --coop=N)
static var pads: Array = [-1]        # each player's pad in Keys (-1: every device)
static var bots: Array = [false]     # played by the test bot (--coop=N)
static var actor := 0                # the hero acting now: their new shots are theirs
static var turn := -1                # P2 to P4's menu turn (a level-up, a chest, a shop): G.player is them until play goes on
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
static var lobby: Array = []         # the CO-OP screen's joined players, P1 first: { pad, hero, ready, msg, msg_t }
static var draft: Array = []         # an open chest: the players still to pick from it, in turn (indexes)
static var _lmb := false             # the left mouse button last tick (the CO-OP screen's clicks)

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

## A co-op run is being made or played (RunSave leaves it alone: it is not saved for CONTINUE).
static func busy() -> bool:
	return _building or not extras.is_empty()

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

## Back to one player: no party, every device for P1's menus and play.
static func solo() -> void:
	extras.clear()
	want = []
	pads = [-1]
	bots = [false]
	actor = 0
	turn = -1
	downs.clear()
	revive.clear()
	_tgt.clear()
	_lead = null
	_hs = []
	_fams = []
	wait_msg = ""
	_door_t = 0.0
	lobby = []
	draft = []
	Keys.clear_pads()

## Game.update_title, first: the party ends on the title (START RUN is one player again).
static func on_title() -> void:
	if not extras.is_empty() or want.size() > 1 or not Keys.pads.is_empty():
		solo()

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
	draft = []
	if want.size() <= 1:
		return
	_building = true
	var p1_hero := G.hero_index
	var runs0: int = Meta.meta.get("runs", 0)
	for i in range(1, mini(want.size(), MAX)):
		G.hero_index = want[i]
		G.new_run()
		extras.append(G.player)   # (their oath and level-ups come in turn: offer_turn)
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
	if G.state != &"play":
		return
	for i in range(1, count()):
		var h: Player = extras[i - 1]
		if downs.has(h):
			continue
		enter(i)
		if i < bots.size() and bots[i]:
			_bot(i, h, dt)
		Effects.tick(dt)
		Combat.update_player(h, dt)
		if G.state == &"play" and Keys.use():   # a chest, a shop ware, a pedestal, a tome: their own
			var o = _object_near(h)
			if o != null:
				G.interact(o)
		if G.state != &"play":
			turn = i
			return   # their menu: G.player stays theirs until it closes (play_tick)
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

## W3 (his "go", 12 Oct: a guardian's lasers, chains, circles, the final final bosses' moves, the
## rift guardians' hazards, Stage 56's patterns and some of the rooms' own hazards hurt only P1): a
## hazard that tests the hero (P1, or the hero a foe's turn is for) tests the others too. `touch` takes a Player: true when the
## hazard touches them. Every other standing hero it touches who is not rolling or just hurt is
## hurt, as a stray shot hurts them (Coop.shot_hit). True: someone was. `env`: as the room's own
## hazards hurt (Combat.hurt_player: one heart, however deep).
static func hazard(touch: Callable, source: String, env := false) -> bool:
	var any := false
	for i in count():
		var h: Player = heroes()[i]
		if h == G.player or downs.has(h) or h.dodge_t > 0 or h.invuln > 0:
			continue
		if touch.call(h):
			hurt(i, 1, source, env)
			any = true
	return any

## W4 (his word, 13 Oct: "For coop make that it hurts all"): a foe's body hurts every standing hero it
## touches, not only the one it works against (Combat.update_enemies tests that one: G.player).
## Arči's dashes and leaps and Šefe's chainsaw charge hurt mostly by touch. No lambda: every foe,
## every frame.
static func foe_touch(e: Enemy, source: String) -> void:
	var hs := heroes()
	for i in hs.size():
		var h: Player = hs[i]
		if h == G.player or downs.has(h) or h.dodge_t > 0 or h.invuln > 0:
			continue
		var rr := e.r + h.r
		if (h.x - e.x) * (h.x - e.x) + (h.y - e.y) * (h.y - e.y) < rr * rr:
			hurt(i, 1, source)

## Hurts hero i as Combat.hurt_player hurts P1.
static func hurt(i: int, amount: int, source: String, env := false) -> void:
	var keep: Player = G.player
	var keep_actor := actor
	G.player = heroes()[i]
	actor = i
	Combat.hurt_player(amount, source, env)
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
	var menu_i := -1
	for i in hs.size():
		if groups[i].is_empty():
			continue
		if menu_i >= 0:
			all.append_array(groups[i])   # (a menu opened: the rest wait for the next tick)
			continue
		enter(i)
		G.pickups = groups[i]
		Combat.update_pickups(dt)
		all.append_array(G.pickups)
		leave()
		if G.state != &"play":
			menu_i = i
	G.pickups = all
	if menu_i > 0:
		turn = menu_i
		enter(menu_i)   # (what they picked up opened a menu: it is theirs)

## The nearest thing a hero can use (as Game.update_play finds P1's).
static func _object_near(h: Player):
	var best := 24.0
	var out = null
	for o in G.room.objects:
		if o.get("used", false) or o.get("opened", false) or o.get("gone", false):
			continue
		var d := TB.dist_xy(h.x, h.y, o["x"], o["y"])
		if d < best:
			best = d
			out = o
	return out

# ---------- turns: P2 to P4's own menus ----------
## Game.update_play, first: a P2-P4 menu turn ends once the game is back in play. A P2-P4 press of
## MENU makes the pause theirs: G.player and the keys are theirs, so Game.update_play's own pause
## check opens it (their gear, traits and relics), even a downed player's.
static func play_tick() -> void:
	if turn > 0:
		turn = -1
		leave()
	for i in range(1, count()):
		if i < pads.size() and pads[i] >= 0 and Keys.pads[pads[i]]["trig"].get(&"pause", false):
			turn = i
			enter(i)
			return

## Keys.tick: whose pad the menus listen to (the turn's hero, else P1; anyone's at the end, or when
## that player's controller has been unplugged).
static func menu_pad() -> int:
	if G.state == &"dead" or G.state == &"win":
		return -1
	var i := turn if turn > 0 else 0
	var k: int = pads[i] if i < pads.size() else -1
	if k >= 0 and k < Keys.pads.size() and Keys.pads[k]["kind"] == "joy" and not Keys.pads[k]["dev"] in Input.get_connected_joypads():
		return -1   # (their controller is gone: anyone can finish their menu)
	return k

## Game.update_play, after P1's: P2 to P4's oaths and level-ups, one hero at a time, each with
## their own device, when the room is safe. True: a turn began.
static func offer_turn() -> bool:
	if extras.is_empty() or G.locked:
		return false
	if not (G.enemies.is_empty() or GameData.rogues() and G._only_dummies()):
		return false
	for i in range(1, count()):
		var h: Player = extras[i - 1]
		if h.pending <= 0 or downs.has(h):
			continue
		turn = i
		enter(i)
		G.toast("P%d: YOUR PICK" % (i + 1), FONT[i])
		G.offer_traits()
		if G.state == &"traits" and i < bots.size() and bots[i] and not G.tchoice.is_empty():
			G.take_trait(G.tchoice["opts"][0])   # (the test bot takes the first)
			G.tchoice = {}
			G.state = &"play"
		if G.state != &"play":
			return true
		turn = -1
		leave()
	return false

# ---------- a chest: every player picks from it in turn (his pick, 12 Oct) ----------
## Game.open_choice: one more relic in a chest for each extra player (the last to pick still has
## as many to choose from as one player alone).
static func chest_extra() -> int:
	return extras.size()

## Game.open_choice, once the chest's relics are out: whoever opened it picks first, then the
## others in player order after them.
static func draft_start() -> void:
	draft = []
	if extras.is_empty():
		return
	var first := maxi(0, index_of(G.player))
	for k in range(1, count()):
		draft.append((first + k) % count())

## Game.update_choice, after a pick: the next player picks from what is left (what they already
## own is swapped for a new relic; a test bot takes the first). True: the chest stays open for them.
static func draft_next(taken: Dictionary) -> bool:
	if draft.is_empty() or G.choice.is_empty():
		draft = []
		return false
	var rest: Array = G.choice["relics"].filter(func(r): return r != taken)
	while not draft.is_empty() and not rest.is_empty():
		var i: int = draft.pop_front()
		if i == 0:
			turn = -1
			leave()
		else:
			turn = i
			enter(i)
		var ids: Array = rest.map(func(r): return r["id"])
		for k in rest.size():
			if G.player.relics.any(func(r): return r["id"] == rest[k]["id"]):
				var fresh: Array = G.roll_relics(1, G.choice.get("source", "chest"), null, ids)   # (G.player is them: theirs are left out)
				if not fresh.is_empty():
					rest[k] = fresh[0]
					ids.append(fresh[0]["id"])
		if i < bots.size() and bots[i]:
			G.add_relic(G.player, rest.pop_front())   # (the test bot takes the first)
			continue
		G.choice["relics"] = rest
		G.choice["idx"] = mini(1, rest.size() - 1)
		G.choice["alt"] = {}
		Snd.play("select")
		return true
	draft = []
	return false

## OverlayView and Taps: where a chest's first card sits. More than 4 (a chest for several
## players): a row of 4 that follows the chosen card, with a sliver of the others at the edges.
static func choice_x0(n: int, w: int, gap: int) -> int:
	if n <= 4:
		return (TB.SW - (n * w + (n - 1) * gap)) / 2
	var first := clampi(int(G.choice.get("idx", 0)) - 1, 0, n - 4)
	return (TB.SW - (4 * w + 3 * gap)) / 2 - first * (w + gap)

# ---------- difficulty and shares ----------
## Combat.spawn_enemy (per = HP_PER) and spawn_boss (BOSS_PER): more health for each extra player.
static func scale_foe(e: Enemy, per: float) -> void:
	if extras.is_empty() or e == null:
		return
	e.max_hp *= 1.0 + per * extras.size()
	e.hp = e.max_hp

## Game.spawn_wave: more foes for each extra player.
static func wave_size(n: int) -> int:
	if extras.is_empty():
		return n
	return ceili(n * (1.0 + WAVE_PER * extras.size()))

## Combat.kill_enemy: a guardian's experience goes to every standing hero, not just its killer.
static func share_xp(killer: Player, xp: int) -> void:
	if extras.is_empty():
		return
	var keep: Player = G.player
	for h in heroes():
		if h != killer and not downs.has(h):
			G.player = h
			Combat.gain_xp(h, xp)
	G.player = keep

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
		if _door_t > 0.25:
			_bots_to(dir)   # (only the test bots: they walk badly, and the soak bot leading them backs off a door that does not open)
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

# ---------- joining: the CO-OP screen (the title's CO-OP) ----------
## Opens the CO-OP screen: the keyboard and mouse and every controller can join (Brotato's way: up
## to 4 players, each with their own device, each picks a hero; the run starts when all are ready).
## W2: the keyboard is two places, its left half (SPACE joins) and its right half (ENTER joins): one
## keyboard player has every key, two share it (Keys.KB_LEFT, KB_RIGHT).
static func open_lobby() -> void:
	solo()
	Keys.seat(Keys.add_pad("kbm"), false)
	Keys.seat(Keys.add_pad("kb2"), false)
	for d in Input.get_connected_joypads():
		Keys.add_pad("joy", d)
	_lmb = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	G.endless_next = false
	G.state = &"coop"

## The joined place of Keys pad k, or -1.
static func _slot_of(k: int) -> int:
	for s in lobby.size():
		if lobby[s]["pad"] == k:
			return s
	return -1

## A newly joined player's hero: P1's last hero, then the next free ones in the hero screen's order.
static func _first_hero() -> int:
	if lobby.is_empty():
		return G.hero_index
	var order := GameData.hero_order()
	var taken := lobby.map(func(e): return e["hero"])
	var start := order.find(lobby.back()["hero"])
	for j in range(1, order.size() + 1):
		var i: int = order[(start + j) % order.size()]
		if not i in taken and G.hero_unlocked(GameData.heroes()[i]):
			return i
	return G.hero_index

static func _join(k: int, hero: int = -1) -> void:
	if lobby.size() >= MAX:
		return
	lobby.append({ "pad": k, "hero": _first_hero() if hero < 0 else hero, "ready": false, "msg": "", "msg_t": 0.0 })
	Keys.seat(k, true)
	Snd.play("confirm")

static func _ready_up(s: int) -> void:
	var e: Dictionary = lobby[s]
	if G.hero_unlocked(GameData.heroes()[e["hero"]]):
		e["ready"] = true
		Snd.play("confirm")
	else:
		e["msg"] = "UNLOCK IT AT THE SHRINE"
		e["msg_t"] = G.time + 1.5
		Snd.play("deny")

## Game.update (state "coop"): each device on its own. USE joins, then readies; LEFT and RIGHT choose
## a hero; MENU unreadies, then leaves (with nobody joined: back to the title); P1's UP and DOWN set
## the DREAD. A mouse click on a hero chooses it for the keyboard's player, a second click readies.
static func update_lobby() -> void:
	for d in Input.get_connected_joypads():   # (a controller plugged in on this screen can join too)
		var known := false
		for pd in Keys.pads:
			if pd["kind"] == "joy" and pd["dev"] == d:
				known = true
		if not known:
			Keys.add_pad("joy", d)
	var order := GameData.hero_order()
	var leave_screen := false
	for k in Keys.pads.size():
		Keys.use_pad(k)
		var s := _slot_of(k)
		if s < 0:
			if Keys.confirm():
				_join(k)
			elif Keys.back() and lobby.is_empty():
				leave_screen = true
			continue
		var e: Dictionary = lobby[s]
		if Keys.back():
			if e["ready"]:
				e["ready"] = false
			else:
				lobby.remove_at(s)   # (the others move up a place)
				Keys.seat(k, false)
			Snd.play("select")
			continue
		if s == 0:
			var mx: int = mini(Meta.meta.get("dread_max", 0), Dread.cap())
			if mx > 0 and (Keys.up() or Keys.down()):
				Meta.meta["dread"] = (Meta.meta.get("dread", 0) + (1 if Keys.up() else mx)) % (mx + 1)
				Snd.play("select")
		if e["ready"]:
			continue
		if Keys.left() or Keys.right():
			var j := order.find(e["hero"])
			e["hero"] = order[(j + (1 if Keys.right() else order.size() - 1)) % order.size()]
			Snd.play("select")
		elif Keys.confirm():
			_ready_up(s)
	Keys.use_pad(-1)
	var lmb := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if lmb and not _lmb:
		_click(Keys.get_viewport().get_mouse_position())
	_lmb = lmb
	if leave_screen:
		G.state = &"title"
		G.menu = G.title_index("CO-OP")
		Snd.play("select")
		return
	if lobby.size() >= 2 and lobby.all(func(e): return e["ready"]):
		_start()

## A click on the CO-OP screen: on a hero, it is the keyboard player's (joining them first); a click
## on their hero again readies them. (Two on the keyboard: the mouse is the left half's.)
static func _click(at: Vector2) -> void:
	var kp := Keys.mouse_pad()
	if kp < 0:
		return
	var order := GameData.hero_order()
	for j in order.size():
		if not MenuView.hero_cell(j).grow(1).has_point(at):
			continue
		var s := _slot_of(kp)
		if s < 0:
			_join(kp, order[j])
		elif not lobby[s]["ready"]:
			if lobby[s]["hero"] == order[j]:
				_ready_up(s)
			else:
				lobby[s]["hero"] = order[j]
				Snd.play("select")
		return

## Everyone is ready: the party (want, pads) in the order they joined, and the run.
static func _start() -> void:
	var devs := []
	want = []
	for e in lobby:
		want.append(e["hero"])
		devs.append([Keys.pads[e["pad"]]["kind"], Keys.pads[e["pad"]]["dev"]])
	Keys.clear_pads()
	pads = []
	bots = []
	for d in devs:
		pads.append(Keys.add_pad(d[0], d[1]))
		bots.append(d[0] == "bot")   # (tests: a bot device is played by the test bot)
	for s in lobby.size():
		lobby[s]["pad"] = pads[s]
	G.hero_index = want[0]
	Snd.play("confirm")
	Meta.write_save()
	G.start_fade(G.new_run)

## --ui=coop (pictures): the CO-OP screen with three joined, P1 ready; --ui=coopkeys: two on the
## keyboard (P1 its left half, ready; P2 its right half); --ui=coopgear (with --coop=N): P2's gear
## page, as theirs.
static func picture(kind: String) -> void:
	if kind == "coop" or kind == "coopkeys":
		open_lobby()
		_join(0)
		if kind == "coopkeys":
			_join(1)
		else:
			for k in 2:
				_join(Keys.add_pad("bot"))
		lobby[0]["ready"] = true
		return
	if extras.is_empty():
		return
	turn = 1
	enter(1)
	G.state = &"inventory"

static func _device_name(k: int) -> String:
	if k < 0 or k >= Keys.pads.size():
		return ""
	match Keys.pads[k]["kind"]:
		"kbm": return "WASD + MOUSE" if Keys.split() else "KEYBOARD"
		"kb2": return "ARROWS" if Keys.split() else "KEYBOARD"
		"joy": return "PAD %d" % (int(Keys.pads[k]["dev"]) + 1)
	return "BOT"

## W2: a keyboard player's own key for USE or MENU on the CO-OP screen ("SPACE"), or the word itself
## for any other device.
static func _key_word(k: int, a: StringName) -> String:
	var kind: String = Keys.pads[k]["kind"] if k >= 0 and k < Keys.pads.size() else ""
	if kind == "kbm":
		return "SPACE" if a == &"use" else "ESC"
	if kind == "kb2":
		return "ENTER" if a == &"use" else ("BACKSPACE" if Keys.split() else "ESC")
	return "USE" if a == &"use" else "MENU"

## The keyboard's halves nobody has joined with yet (0 left, 1 right).
static func _free_halves() -> Array:
	var out := []
	for half in 2:
		var k := -1
		for i in Keys.pads.size():
			if Keys.pads[i]["kind"] == ("kbm" if half == 0 else "kb2"):
				k = i
		if k >= 0 and _slot_of(k) < 0:
			out.append(half)
	return out

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
		var near := 14.0 if h.weapon != null and WeaponInfo.wtype(h.weapon) == "MELEE" else 50.0   # (melee closes in)
		v = to if to.length() > near + 40.0 else (-to if to.length() < near else to.orthogonal())
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
		if i > 0 and G.state == &"play" and _object_near(h) != null:
			Gfx.text(ci, "USE", roundf(h.x), roundf(h.y - 30), FONT[i], 1, 0.5)   # (P1's prompt is the game's own)
		var c := TB.c(COLORS[i])
		var at := Vector2(roundf(h.x), roundf(h.y) + 6.0)
		ci.draw_arc(at, 8.0, 0.0, TAU, 20, Color(c, 0.75), 1.0)
		if i > 0:
			var ax := h.x + cos(h.aim_a) * 16
			var ay := h.y - 2 + sin(h.aim_a) * 16
			ci.draw_rect(Rect2(roundf(ax - 2), roundf(ay - 2), 4, 4), TB.c("#1a1423"))
			ci.draw_rect(Rect2(roundf(ax - 1), roundf(ay - 1), 2, 2), c)

## The CO-OP screen (MenuView.draw_coop; mv queues its sprites): the hero grid with each player's
## colour on their hero, a card for each of the four places, how to join and the DREAD.
static func draw_lobby(ci: CanvasItem, mv) -> void:
	var t := G.time
	Gfx.text(ci, "CO-OP: UP TO 4 PLAYERS", TB.SW / 2, 8, "gold", 2, 0.5)
	var order := GameData.hero_order()
	for j in order.size():
		var i: int = order[j]
		var hh: Dictionary = GameData.heroes()[i]
		var r := MenuView.hero_cell(j)
		var open := G.hero_unlocked(hh)
		var on := []
		for k in lobby.size():
			if lobby[k]["hero"] == i:
				on.append(k)
		var col: String = COLORS[on[0]] if not on.is_empty() else ("#4e4a5e" if open else "#2a2838")
		Gfx.panel(ci, r.position.x, r.position.y, r.size.x, r.size.y, col, "#2c2036" if not on.is_empty() else "#17121e")
		mv._sprite(hh["sprite"], r.get_center().x, r.end.y - 3, 1, false, 1.0, Color(0, 0, 0, 0) if open else TB.rgba(62, 56, 78, 255))
		for q in on.size():   # every player on it: their colour along its foot
			ci.draw_rect(Rect2(r.position.x + 1 + q * 6, r.end.y, 5, 2), TB.c(COLORS[on[q]]))
	for k in MAX:
		var x := 18 + k * 104
		var y := 86
		var w := 100
		var hgt := 142
		if k >= lobby.size():
			Gfx.panel(ci, x, y, w, hgt, "#2a2838", "#120e18")
			Gfx.text(ci, "P%d" % (k + 1), x + 6, y + 6, "dim", 2)
			if k == lobby.size():
				var blink := floori(t * 2) % 2 == 0
				Gfx.text(ci, "PRESS USE", x + w / 2, y + 52, FONT[k] if blink else "white", 1, 0.5)
				Gfx.text(ci, "TO JOIN", x + w / 2, y + 62, FONT[k] if blink else "white", 1, 0.5)
				var free := _free_halves()
				var hy := y + 90
				if free.size() == 2:
					Gfx.text(ci, "KEYS: SPACE OR ENTER", x + w / 2, hy, "dim", 1, 0.5)
					Gfx.text(ci, "MOUSE: CLICK A HERO", x + w / 2, hy + 10, "dim", 1, 0.5)
					hy += 20
				elif free.size() == 1:   # (W2: a second player on the same keyboard)
					Gfx.text(ci, "SAME KEYBOARD: " + ("SPACE" if free[0] == 0 else "ENTER"), x + w / 2, hy, "dim", 1, 0.5)
					hy += 10
				Gfx.text(ci, "CONTROLLER: A", x + w / 2, hy, "dim", 1, 0.5)
			continue
		var e: Dictionary = lobby[k]
		var h: Dictionary = GameData.heroes()[e["hero"]]
		var open := G.hero_unlocked(h)
		Gfx.panel(ci, x, y, w, hgt, COLORS[k], "#2c2036" if e["ready"] else "#17121e")
		Gfx.text(ci, "P%d" % (k + 1), x + 6, y + 6, FONT[k], 2)
		Gfx.text(ci, _device_name(e["pad"]), x + w - 6, y + 9, "dim", 1, 1.0)
		var bob := -1 if not e["ready"] and floori(t * 3 + k) % 2 == 1 else 0
		mv._sprite(h["sprite"], x + w / 2, y + 60 + bob, 2, false, 1.0, Color(0, 0, 0, 0) if open else TB.rgba(20, 15, 28, 255))
		var ny := y + 68
		for l in Gfx.wrap_text(h["name"], w - 8):
			Gfx.text(ci, l, x + w / 2, ny, "gold" if open else "dim", 1, 0.5)
			ny += 8
		for l in Gfx.wrap_text(h["weapon"], w - 8).slice(0, 2):
			Gfx.text(ci, l, x + w / 2, ny, "grey", 1, 0.5)
			ny += 8
		var hn: int = mini(h["hp"] / 2, 10)
		for q in hn:
			Gfx.at(ci, "heart_full", roundf(x + w / 2 - hn * 4.5 + q * 9), ny + 1)
		if e["msg"] != "" and G.time < e["msg_t"]:
			Gfx.text(ci, e["msg"], x + w / 2, y + 116, "orange", 1, 0.5)
		elif e["ready"]:
			Gfx.text(ci, "READY", x + w / 2, y + 112, "lime", 2, 0.5)
		elif not open:
			Gfx.text(ci, "LOCKED", x + w / 2, y + 116, "red", 1, 0.5)
		else:
			Gfx.text(ci, _key_word(e["pad"], &"use") + ": READY", x + w / 2, y + 116, "white", 1, 0.5)
		Gfx.text(ci, _key_word(e["pad"], &"pause") + (": LEAVE" if not e["ready"] else ": NOT READY"), x + w / 2, y + 130, "dim", 1, 0.5)
	var line := ""
	var col := "grey"
	if lobby.size() < 2:
		match _free_halves().size():
			2: line = "A SECOND PLAYER JOINS WITH A CONTROLLER, OR TWO SHARE THE KEYBOARD: SPACE (WASD) AND ENTER (ARROWS)"
			1: line = "A SECOND PLAYER JOINS WITH A CONTROLLER, OR ON THIS KEYBOARD WITH %s: THEN IT IS SPLIT IN TWO" % ("SPACE" if _free_halves()[0] == 0 else "ENTER")
			_: line = "A SECOND PLAYER JOINS WITH A CONTROLLER"
	else:
		var wait := []
		for k in lobby.size():
			if not lobby[k]["ready"]:
				wait.append("P%d" % (k + 1))
		line = "WAITING FOR " + ", ".join(wait) if not wait.is_empty() else "EVERYONE IS READY"
		col = "gold" if wait.is_empty() else "tan"
	Gfx.text(ci, line, TB.SW / 2, 233, col, 1, 0.5)
	var mx: int = mini(Meta.meta.get("dread_max", 0), Dread.cap())
	var d := mini(Meta.meta.get("dread", 0), mx)
	if mx > 0:
		Gfx.text(ci, "DREAD %d: %s   (P1: UP / DOWN)" % [d, GameData.DREAD_DESC[d]], TB.SW / 2, 244, "red" if d > 0 else "grey", 1, 0.5)
	Gfx.text(ci, "FOR EACH EXTRA PLAYER: FOES +60% HEALTH, GUARDIANS +75%, 25% MORE FOES. DROPS ARE NOT SHARED.", TB.SW / 2, 254, "dim", 1, 0.5)
	Gfx.text(ci, "EACH PLAYER:  USE  JOIN, THEN READY     < >  HERO     MENU  LEAVE", TB.SW / 2, 266, "grey", 1, 0.5)

## The pages that belong to one player: whose they are, in their colour (MenuView, last).
const TURN_WORDS := { &"pause": "MENU", &"options": "MENU", &"keys": "MENU", &"wardrobe": "WARDROBE",
	&"inventory": "GEAR", &"gearpage": "GEAR", &"traitlist": "TRAITS", &"relics": "RELICS",
	&"choice": "PICK", &"traits": "PICK", &"tome": "TOME", &"fishing": "CATCH" }

## Whose page it is ("P2'S GEAR"), or "" when it is nobody's own.
static func turn_label() -> String:
	if extras.is_empty() or not TURN_WORDS.has(G.state):
		return ""
	return "P%d'S %s" % [(turn if turn > 0 else 0) + 1, TURN_WORDS[G.state]]

static func draw_turn(ci: CanvasItem) -> void:
	var label := turn_label()
	if label == "":
		return
	if G.state == &"choice" and not G.choice.is_empty():   # a chest for several: who picks next, more cards
		if not draft.is_empty():
			var names: Array = draft.map(func(k): return "P%d" % (k + 1))
			Gfx.text(ci, "THEN " + ", ".join(names) + " PICK FROM WHAT IS LEFT", TB.SW / 2, 58, "tan", 1, 0.5)
		var n: int = G.choice["relics"].size()
		if n > 4:
			var first := clampi(int(G.choice["idx"]) - 1, 0, n - 4)
			if first > 0:
				Gfx.text(ci, "<", 2, 137, "gold", 2)
			if first + 4 < n:
				Gfx.text(ci, ">", TB.SW - 8, 137, "gold", 2)
	var i := turn if turn > 0 else 0
	var c := TB.c(COLORS[i])
	ci.draw_rect(Rect2(1, 1, TB.SW - 2, TB.SH - 2), c, false, 2.0)
	var w := TB.text_w(label, 2) + 10
	var x := TB.SW - 3 - w   # (the top right corner: the pages keep their own things on the left)
	ci.draw_rect(Rect2(x, 3, w, 16), Color(0.05, 0.04, 0.07, 0.92))
	ci.draw_rect(Rect2(x, 3, w, 16), c, false, 1.0)
	Gfx.text(ci, label, x + 5, 6, FONT[i], 2)

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
