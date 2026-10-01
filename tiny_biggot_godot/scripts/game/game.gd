extends Node
## Game state and run flow (port of Game.rb CCGame). Autoload name: G.

signal room_changed

var state: StringName = &"title"
var time := 0.0
var hero_index := 0
var floor_index := 0
var floor_d: Dictionary = {}
var room: Room = null
var locked := false
var shake := 0.0
var dyn_dirty := true
var fade: Dictionary = {}      # { t, phase: &"out"/&"in", cb: Callable } or empty
var dread := 0

func _ready() -> void:
	dread = Meta.meta.get("dread", 0)

# ---------- Run flow ----------
func start_floor() -> void:
	floor_d = World.new_floor(floor_index)
	Meta.meta["best"] = maxi(Meta.meta["best"], floor_index + 1)
	Meta.write_save()
	Snd.music(floor_index)
	room = null
	enter_room(World.make_room(floor_d, "start", "", ""))
	state = &"play"

func enter_room(r: Room) -> void:
	room = r
	locked = false
	match room.type:
		"combat", "elite", "boss":
			locked = true
			Snd.play("door")
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
	World.assign_exits(room, World.gen_choices(floor_d, null))
	for d in room.exits:
		var c: Dictionary = room.exits[d]
		if c["type"] != "vault":
			continue
		var pos := World.door_center(d)
		var ix: int = { "w": 22, "e": -22 }.get(d, 0)
		var iy: int = { "n": 26, "s": -22 }.get(d, 0)
		room.objects.append({ "kind": "lockdoor", "dir": d, "x": pos.x + ix, "y": pos.y + iy })
	dyn_dirty = true

func start_fade(cb: Callable) -> void:
	fade = { "t": 0.0, "phase": &"out", "cb": cb }

# ---------- Update ----------
func update(dt: float) -> void:
	time += dt
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

func update_play(_dt: float) -> void:
	# Stage 2 world viewer: USE rolls a new room, BOMB toggles the door lock.
	if Keys.use():
		var kinds := ["combat", "elite", "challenge", "treasure", "shop", "shrine", "vault", "rest", "boss"]
		var kind: String = TB.pick(kinds)
		floor_d["depth"] = TB.rint(0, floor_d["total"] - 1)
		var ent: String = TB.pick(["s", "e", "w", "n"])
		start_fade(func(): enter_room(World.make_room(floor_d, kind, World.roll_reward(null) if kind == "combat" else "", ent)))
	if Keys.bomb():
		locked = not locked
		if not locked:
			open_exits()
		dyn_dirty = true
	if Keys.pause():
		floor_index = (floor_index + 1) % GameData.FLOORS.size()
		start_floor()
