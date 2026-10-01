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

func _ready() -> void:
	dread = Meta.meta.get("dread", 0)

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
	run_stats = { "kills": 0, "gold": 0, "time": 0.0, "floor": 1, "bosses": 0, "secrets": 0 }
	floor_index = 0
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
	room.objects_ready = true
	locked = false
	match room.type:
		"combat", "elite":
			# Enemies and waves arrive with combat (stage 4); until then the doors open at once.
			open_exits()
		"boss":
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
	p.update_move(dt)
	p.try_heal()
	if Keys.aim() != null:
		p.aim_a = Keys.aim()
		if p.dodge_t <= 0:
			p.face = 1 if cos(p.aim_a) >= 0 else -1
	Fx.update(dt)
	if state != &"play":
		return
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
