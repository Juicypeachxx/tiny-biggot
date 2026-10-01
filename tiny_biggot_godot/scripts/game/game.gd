extends Node
## Game state and run flow (port of Game.rb CCGame). Autoload name: G.

signal room_changed

var state: StringName = &"title"
var time := 0.0
var hero_index := 0
var floor_index := 0
var floor_d: Dictionary = {}
var room: Room = null
var player: Player = null
var locked := false
var shake := 0.0
var hitstop := 0.0
var dyn_dirty := true
var fade: Dictionary = {}      # { t, phase: &"out"/&"in", cb: Callable } or empty
var dread := 0
var banner: Dictionary = {}
var msg: Dictionary = {}
var prompt: Variant = null
var run_stats := {}
var death_by := ""
var state_t := 0.0
var win_timer: Variant = null  # Ruby nil or seconds left
var boss_delay: Variant = null # Ruby nil or seconds left
var award: Dictionary = {}

# Combat state (Ruby @enemies, @pbullets ... ; enemy bullets live in EBullets).
var enemies: Array[Enemy] = []
var pbullets: Array[PBullet] = []
var new_pbullets: Array[PBullet] = []
var pickups: Array = []
var bombs: Array = []
var zones: Array = []
var familiars: Array = []
var temp_fams: Array = []
var swings: Array = []
var boss: Enemy = null
var god := false              # debug: --god
var _wave_delay := 0.0
var _spawned := false

func _ready() -> void:
	dread = Meta.meta.get("dread", 0)

func enemies_active() -> bool:
	for e in enemies:
		if e.spawn_t <= 0 and not e.hidden:
			return true
	return false

func hero_unlocked(h: Dictionary) -> bool:
	return h["cost"] == 0 or Meta.unlocked("hero_" + h["id"])

func add_shake(amount: float) -> void:
	if Meta.opts["shake"]:
		shake = maxf(shake, amount)

func show_banner(text: String, sub: String) -> void:
	banner = { "text": text, "sub": sub, "t": 2.6 }

func toast(text: String, col: String = "white") -> void:
	msg = { "text": text, "col": col, "t": 2.0 }

func start_fade(cb: Callable) -> void:
	fade = { "t": 0.0, "phase": &"out", "cb": cb }

# ---------- Run flow ----------
func new_run() -> void:
	var hero: Dictionary = GameData.HEROES[hero_index]
	player = Player.new(hero)
	Weapons.equip_weapon(player, Weapons.by_id(Weapons.HERO_WEAPON[hero["id"]]))
	if DebugArgs.has("weapon"):
		Weapons.equip_weapon(player, Weapons.by_id(DebugArgs.get_str("weapon")))
	run_stats = { "kills": 0, "gold": 0, "time": 0.0, "floor": 1, "bosses": 0, "secrets": 0 }
	floor_index = 0
	familiars = []
	temp_fams = []
	zones = []
	dread = mini(Meta.meta.get("dread", 0), Meta.meta.get("dread_max", 0))
	var p := player
	if Meta.unlocked("perk_gold"): p.gold += 20
	if Meta.unlocked("perk_bombs"): p.bombs += 2
	if Meta.unlocked("perk_potion"):
		p.potions += 1
		p.max_potions = maxi(p.max_potions, p.potions)
	if Meta.unlocked("perk_key"): p.keys += 1
	if Meta.unlocked("perk_heart"):
		p.max_hp += 2
		p.hp += 2
	if dread >= 5:
		p.max_hp = maxi(2, p.max_hp - 2)
		p.hp = mini(p.hp, p.max_hp)
	# Skill-tree nodes and the relic perks arrive with items (stage 5).
	Meta.meta["runs"] += 1
	Meta.write_save()
	start_floor()

func start_floor() -> void:
	if player != null:
		player.floor_kills = 0
	floor_d = World.new_floor(floor_index)
	run_stats["floor"] = floor_index + 1
	Meta.meta["best"] = maxi(Meta.meta["best"], floor_index + 1)
	Meta.write_save()
	Snd.music(floor_index)
	room = null
	enter_room(World.make_room(floor_d, "start", "", ""))
	state = &"play"
	show_banner(GameData.FLOORS[floor_index]["name"], "FLOOR %d OF %d" % [floor_index + 1, GameData.FLOORS.size()]
		+ ("   DREAD %d" % dread if dread > 0 else ""))

const ENTRY_SPOTS := { "s": Vector2(14.0 * 16, 16.0 * 16), "n": Vector2(14.0 * 16, 2.6 * 16),
	"e": Vector2(26.0 * 16 - 2, 9.5 * 16), "w": Vector2(2.0 * 16 + 2, 9.5 * 16) }

func enter_room(r: Room) -> void:
	room = r
	Fx.clear()
	EBullets.clear()
	pickups = room.pickups
	enemies = []
	for b in pbullets:
		Combat.recycle(b)
	pbullets = []
	new_pbullets = []
	bombs = []
	zones = []
	swings = []
	boss = null
	win_timer = null
	var p := player
	p.buckler_used = false
	p.volleys = []
	p.trail = []
	p.dodge_t = 0.0
	p.room_kills = 0
	if p.ironskin:
		p.armor = maxi(p.armor, 1)
	if room.entrance != "":
		var s: Vector2 = ENTRY_SPOTS[room.entrance]
		p.x = s.x
		p.y = s.y
	else:
		p.x = 14.0 * TB.TS
		p.y = 10.0 * TB.TS
	for f in familiars:
		f["x"] = p.x
		f["y"] = p.y
	if not room.objects_ready:
		room.objects_ready = true
		setup_objects(room)
	locked = false
	_spawned = false
	match room.type:
		"combat", "elite":
			locked = true
			room.waves_left = (2 if room.type == "elite" else 1) + (1 if randf() < 0.25 + 0.08 * floor_index else 0)
			_wave_delay = 0.35
			Snd.play("door")
		"boss":
			locked = true
			boss_delay = 1.0
			Snd.play("door")
			Snd.music(GameData.BOSS_TRACK)
		"challenge":
			# Exits stay shut until the bell is rung and the waves are beaten, or until the player skips it.
			open_exits()
		_:
			open_exits()
	dyn_dirty = true
	room_changed.emit()

func open_exits() -> void:
	if room.exits_open:
		return
	room.exits_open = true
	if room.type == "boss":
		return
	World.assign_exits(room, World.gen_choices(floor_d, player))
	for d in room.exits:
		var c: Dictionary = room.exits[d]
		if c["type"] != "vault":
			continue
		var pos := World.door_center(d)
		var ix: int = { "w": 22, "e": -22 }.get(d, 0)
		var iy: int = { "n": 26, "s": -22 }.get(d, 0)
		room.objects.append({ "kind": "lockdoor", "dir": d, "x": pos.x + ix, "y": pos.y + iy })
	dyn_dirty = true

func leave_room(dir: String) -> void:
	var c = room.exits.get(dir)
	if c == null:
		return
	if c["type"] != "secret":
		floor_d["depth"] += 1
		floor_d["path"].append(c)
	if c["type"] == "shop":
		floor_d["shop_done"] = true
	if c["type"] == "secret":
		Meta.meta["secrets"] += 1
		run_stats["secrets"] += 1
	var nr := World.make_room(floor_d, c["type"], c.get("reward", ""), World.OPP[dir])
	start_fade(func(): enter_room(nr))

## Room furniture (Game.rb setup_objects). Chests, shops and shrines are
## placed now so rooms look right; using them arrives with items (stage 5).
func setup_objects(r: Room) -> void:
	var cx := 14.0 * TB.TS
	var cy := 9.5 * TB.TS
	match r.type:
		"treasure":
			if randf() < 0.35:
				r.objects.append({ "kind": "chest", "x": cx - 24, "y": cy })
				r.objects.append({ "kind": "ichest", "x": cx + 24, "y": cy })
			else:
				r.objects.append({ "kind": "chest", "x": cx, "y": cy })
		"shrine":
			var roll := randf()
			if roll < 0.4: r.objects.append({ "kind": "altar", "x": cx, "y": cy })
			elif roll < 0.7: r.objects.append({ "kind": "fountain", "x": cx, "y": cy })
			else: r.objects.append({ "kind": "idol", "x": cx, "y": cy, "uses": 3 })
		"vault":
			r.objects.append({ "kind": "ichest", "x": cx - 26, "y": cy, "free": true })
			r.objects.append({ "kind": "ichest", "x": cx + 26, "y": cy, "free": true })
			for i in 4:
				r.pickups.append(_room_pickup("gem", cx + TB.rint(-40, 40), cy + 30))
		"secret":
			var roll := randf()
			if roll < 0.45:
				pass # Relic pedestal: needs the relic tables (stage 5).
			elif roll < 0.75:
				r.objects.append({ "kind": "cchest", "x": cx, "y": cy })
				for i in 6:
					r.pickups.append(_room_pickup("coin", cx + TB.rint(-50, 50), cy + TB.rint(20, 40)))
			else:
				for i in 3:
					r.pickups.append(_room_pickup("ember", cx - 20 + i * 20, cy))
				for i in 3:
					r.pickups.append(_room_pickup("gem", cx - 20 + i * 20, cy + 20))
		"challenge":
			r.objects.append({ "kind": "bell", "x": cx, "y": cy })
		"rest":
			r.objects.append({ "kind": "campfire", "x": cx, "y": cy })
	# Shop stock needs the relic, weapon and gear tables (stage 5).

func _room_pickup(kind: String, x: float, y: float) -> Pickup:
	var k := Pickup.new()
	k.kind = kind
	k.x = x
	k.y = y
	k.t = 1.0
	return k

func spawn_wave(hard: bool = false) -> void:
	var fdef: Dictionary = GameData.FLOORS[floor_index]
	var n := TB.rint(3, 4) + mini(floor_index, 4) + (1 if room.depth > 3 else 0)
	var ec := (0.05 if floor_index == 0 else 0.08 + floor_index * 0.035) + (0.08 if dread >= 3 else 0.0) + (0.35 if hard else 0.0)
	if room.type == "elite":
		ec += 0.45
	for i in n:
		var type: String = TB.pick(fdef["pool"])
		var s := World.free_spot(room, player, 90, World.M_FLYER if GameData.ENEMIES[type].get("fly", false) else World.M_WALKER)
		Combat.spawn_enemy(type, s.x, s.y, randf() < ec)
	room.waves_left -= 1

func give_reward(kind: String) -> void:
	var cx := 14.0 * TB.TS
	var cy := 9.5 * TB.TS
	match kind:
		"relic": room.objects.append({ "kind": "chest", "x": cx, "y": cy })
		"rare": room.objects.append({ "kind": "ichest", "x": cx, "y": cy, "free": true })
		"gold":
			for i in TB.rint(4, 6): Combat.drop_pickup("gem", cx, cy)
			for i in TB.rint(3, 6): Combat.drop_pickup("coin", cx, cy)
		"heal":
			Combat.drop_pickup("heart", cx - 8, cy)
			Combat.drop_pickup("heart", cx + 8, cy)
			Combat.drop_pickup("potion", cx, cy)
		"supply":
			for i in 2: Combat.drop_pickup("bomb", cx, cy)
			Combat.drop_pickup("key", cx, cy)
		"armor":
			for i in 2: Combat.drop_pickup("armor", cx, cy)
		"level":
			Combat.gain_xp(player, GameData.xp_needed(player.level) - player.xp)
		"embers":
			for i in 3: Combat.drop_pickup("ember", cx, cy)
		"weapon", "gear":
			toast("WEAPON AND GEAR DROPS ARRIVE WITH ITEMS", "grey")

func room_cleared() -> void:
	locked = false
	room.cleared = true
	dyn_dirty = true
	Snd.play("door")
	var p := player
	if p.interest > 0 and p.gold > 0:
		var g := floori(p.gold * p.interest)
		if g > 0:
			p.gold += g
			Fx.float_text(p.x, p.y - 16, "+%d INTEREST" % g, "gold")
	if p.sapper > 0: p.bombs += p.sapper
	if p.armor_regen > 0: p.armor += p.armor_regen
	if room.type == "challenge":
		give_reward("rare")
		show_banner("CHALLENGE BEATEN", "AN IRON CHEST APPEARS")
		Snd.play("unlock")
	elif room.reward != "":
		give_reward(room.reward)
	open_exits()
	if p.g("room_armor") > 0:
		p.armor += int(p.g("room_armor"))
	if p.g("room_gold") > 0:
		var g := int(p.g("room_gold"))
		p.gold += g
		Fx.float_text(p.x, p.y - 22, "+%d GOLD" % g, "gold")

func open_secret_door(d: String) -> void:
	if not room.secret_dirs.has(d):
		return
	World.open_secret(room, d)
	dyn_dirty = true
	room_changed.emit()
	show_banner("A HIDDEN ROOM", "THE CRACKED WALL GIVES WAY")
	Snd.play("unlock")

func on_boss_dead(b: Enemy) -> void:
	EBullets.clear_all()
	for e in enemies:
		if e != b and e.hp > 0:
			e.hp = 0
			Fx.burst(e.x, e.y, ["#f4ecd8"], 8, 50)
	locked = false
	room.cleared = true
	dyn_dirty = true
	run_stats["bosses"] += 1
	Meta.meta["bosses"] += 1
	var p := player
	if p.oath:
		p.max_hp += 2
		p.hp += 2
	Snd.music(floor_index)
	show_banner(b.d["name"] + " FALLS", "")
	for i in 12:
		Combat.drop_pickup("coin", b.x, b.y)
	Combat.drop_pickup("heart", b.x, b.y)
	Combat.drop_pickup("ember", b.x, b.y)
	var last := floor_index >= GameData.FLOORS.size() - 1
	room.objects.append({ "kind": "chest", "x": 14.0 * TB.TS - (0 if last else 28), "y": 10.0 * TB.TS, "boss": true })
	if last:
		win_timer = 4.5
	else:
		room.objects.append({ "kind": "portal", "x": 14.0 * TB.TS + 28, "y": 10.0 * TB.TS })

func award_embers(win: bool) -> void:
	var r := run_stats
	var p := player
	var parts := [["FLOORS", (floor_index + (1 if win else 0)) * 6], ["GUARDIANS", r["bosses"] * 12], ["FOES", r["kills"] / 8],
		["EMBER SHARDS", p.embers_found], ["SECRETS", r["secrets"] * 5], ["LEVEL", p.level]]
	if win:
		parts.append(["VICTORY", 40])
	var base := 0
	for x in parts:
		base += x[1]
	var mult := 1 + 0.25 * dread
	var total := roundi(base * mult)
	Meta.meta["embers"] += total
	Meta.meta["kills"] += r["kills"]
	award = { "parts": parts, "mult": mult, "total": total }
	Meta.write_save()

func on_death(source: String) -> void:
	death_by = source if source != "" else "the crypt"
	state = &"dead"
	state_t = 0.0
	award_embers(false)
	Snd.play("die")
	Snd.music(0)

func on_win() -> void:
	Meta.meta["wins"] += 1
	Meta.meta["dread_max"] = mini(maxi(Meta.meta.get("dread_max", 0), dread + 1), 5)
	award_embers(true)
	state = &"win"
	state_t = 0.0
	Snd.play("win")
	Snd.music(0)

func deny(o: Dictionary, text: String) -> void:
	Snd.play("deny")
	Fx.float_text(o["x"], o["y"] - 18, text, "red")

## Room object interaction (Game.rb interact). Stage 4 handles the portal so
## floors can be completed; chests, shops and shrines arrive with items.
func interact(o: Dictionary) -> void:
	match o["kind"]:
		"portal":
			Snd.play("portal")
			start_fade(func():
				floor_index += 1
				player.heal(2)
				start_floor())
		"chest", "ichest", "cchest":
			if o["kind"] == "chest" or o.get("free", false):
				o["opened"] = true
				Snd.play("open")
				Fx.burst(o["x"], o["y"], ["#f2c94c", "#fffbe0"], 16, 60)
				toast("RELIC CHOICES ARRIVE WITH ITEMS", "grey")
			else:
				deny(o, "COMING WITH ITEMS")
		_:
			deny(o, "COMING WITH ITEMS")

# ---------- Update ----------
func update(dt: float) -> void:
	time += dt
	if not banner.is_empty():
		banner["t"] -= dt
		if banner["t"] <= 0:
			banner = {}
	if not msg.is_empty():
		msg["t"] -= dt
		if msg["t"] <= 0:
			msg = {}
	shake = maxf(0.0, shake - dt * 30)
	if not fade.is_empty():
		fade["t"] += dt / 0.16
		if fade["phase"] == &"out" and fade["t"] >= 1:
			var cb: Callable = fade["cb"]
			fade["phase"] = &"in"
			fade["t"] = 0.0
			cb.call()
		elif fade["phase"] == &"in" and fade["t"] >= 1:
			fade = {}
		return
	match state:
		&"play":
			update_play(dt)
		&"pause":
			update_pause()
		&"dead", &"win":
			state_t += dt
			if Keys.any() and state_t > 1:
				# Title menu arrives in stage 7: restart a run for now.
				start_fade(new_run)

func update_pause() -> void:
	# Full pause menu arrives in stage 7. MENU or USE resumes.
	if Keys.back() or Keys.confirm():
		state = &"play"
		Snd.play("select")

func update_play(dt: float) -> void:
	run_stats["time"] += dt
	if Keys.pause():
		state = &"pause"
		Snd.play("select")
		return
	if hitstop > 0:
		hitstop -= dt
		return
	var p := player
	Combat.update_player(p, dt)
	if state != &"play":
		return
	Combat.update_enemies(dt)
	Combat.update_pbullets(dt)
	EBullets.update(dt)
	Combat.update_pickups(dt)
	Combat.update_bombs(dt)
	Combat.update_zones(dt)
	Fx.update(dt)
	var keep := []
	for w in swings:
		w["t"] -= dt
		if w["t"] > 0:
			keep.append(w)
	swings = keep
	if state != &"play":
		return
	if room.type in ["combat", "elite", "challenge"] and locked:
		var alive := enemies.size()
		if room.waves_left > 0 and alive <= (1 if _spawned else 0):
			_wave_delay -= dt
			if _wave_delay <= 0:
				spawn_wave(room.type == "challenge")
				_spawned = true
				_wave_delay = 0.6
		elif alive == 0 and room.waves_left <= 0:
			room_cleared()
	if room.type == "boss" and locked and boss == null and boss_delay != null:
		boss_delay -= dt
		if boss_delay <= 0:
			boss_delay = null
			Combat.spawn_boss(GameData.FLOORS[floor_index]["boss"])
			show_banner(boss.d["name"], "")
	if win_timer != null:
		win_timer -= dt
		var all_open := true
		for o in room.objects:
			if o["kind"] == "chest" and not o.get("opened", false):
				all_open = false
		if win_timer <= 0 and all_open:
			win_timer = null
			on_win()
			return
	# Level-ups (trait picks) arrive with items in stage 5; p.pending keeps counting.
	prompt = null
	var best := 24.0
	for o in room.objects:
		if o.get("used", false) or o.get("opened", false) or o.get("gone", false):
			continue
		var d := TB.dist_xy(p.x, p.y, o["x"], o["y"])
		if d < best:
			best = d
			prompt = o
	if prompt != null and Keys.use():
		interact(prompt)
	if not locked:
		var dir := ""
		if p.y < TB.TS * 1.2: dir = "n"
		elif p.y > TB.SH - TB.TS * 0.7: dir = "s"
		elif p.x < TB.TS * 0.6: dir = "w"
		elif p.x > TB.SW - TB.TS * 0.6: dir = "e"
		if dir != "" and room.exits.has(dir) and not room.sealed.has(dir):
			p.x = clampf(p.x, TB.TS, TB.SW - TB.TS)
			p.y = clampf(p.y, TB.TS * 1.3, TB.SH - TB.TS)
			leave_room(dir)
