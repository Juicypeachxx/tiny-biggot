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
var loop := 0                  # loop playthroughs after the true ending (0 = first time through)
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
var champ: Enemy = null       # a rift champion or floor mini-boss in the room: it gets the boss bar
var god := false              # debug: --god
var menu := 0
var choice: Dictionary = {}    # relic choice: { relics, idx }
var tchoice: Dictionary = {}   # trait offer: { opts, idx }
# Menus (Game.rb).
const TITLE_ITEMS := ["START RUN", "SKILL TREES", "EMBER SHRINE", "CODEX", "HOW TO PLAY", "OPTIONS"]
const PAUSE_ITEMS := ["RESUME", "GEAR", "TRAITS", "RELICS", "OPTIONS", "ABANDON RUN"]
const OPTION_LIST := [["AUTO-AIM FIRE", "autofire"], ["MUSIC", "music"], ["SOUND EFFECTS", "sfx"], ["SCREEN SHAKE", "shake"], ["SHOW FPS", "fps"], ["SHOW GEAR ON HERO", "show_gear"], ["FANCY EFFECTS", "vfx"], ["FAST DRAWING", "fast_draw"], ["BACK", ""]]
const CODEX_COLS := 11
var quit_armed := false
var opt_from: StringName = &"title"
var codex_i := 0
var inv_i := 0                 # Rogues layer: inventory cursor (0-5 backpack, 6-9 belt)
var shrine_i := 0
var tree_hero := 0
var tree_b := 0
var tree_n := 0
var tree_from: StringName = &""
var embers: Array = []         # title-screen ember motes
var _wave_delay := 0.0
var _spawned := false

func _ready() -> void:
	dread = Meta.meta.get("dread", 0)

## Rogues layer: training dummies can be shot at, but they are not a fight.
func dummies_present() -> bool:
	for e in enemies:
		if e.type == "dummy":
			return true
	return false

func enemies_active() -> bool:
	for e in enemies:
		if e.spawn_t <= 0 and not e.hidden and e.type != "dummy":
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
	var hero: Dictionary = GameData.heroes()[hero_index]
	player = Player.new(hero)
	Effects.reset_run_state()
	Weapons.equip_weapon(player, Weapons.by_id(Weapons.HERO_WEAPON[hero["id"]]))
	if DebugArgs.has("weapon"):
		Weapons.equip_weapon(player, Weapons.by_id(DebugArgs.get_str("weapon")))
	run_stats = { "kills": 0, "gold": 0, "time": 0.0, "floor": 1, "bosses": 0, "secrets": 0, "rifts": [] }
	loop = DebugArgs.get_int("loop", 0) if DebugArgs.has("loop") else 0
	floor_index = 0
	familiars = []
	temp_fams = []
	zones = []
	dread = mini(Meta.meta.get("dread", 0), Meta.meta.get("dread_max", 0))
	var p := player
	var owned := tree_owned(hero["id"])
	var tree := Traits.tree_for(hero["id"])
	for bi in tree.size():
		for ni in owned[bi]:
			Traits.apply_node(tree[bi]["nodes"][ni][0], p)
	Attributes.start(p)
	# Step 6 heroes: a passive (effect-system data) and a starting trait.
	if hero.has("effects"):
		Effects.apply(p, hero["effects"], 1, "hero:" + hero["id"])
	if hero.has("trait"):
		p.pending += 1
		take_trait(Traits.by_id(hero["trait"]))
	if Meta.unlocked("perk_gold"): p.gold += 20
	if Meta.unlocked("perk_bombs"): p.bombs += 2
	if Meta.unlocked("perk_potion"):
		p.potions += 1
		p.max_potions = maxi(p.max_potions, p.potions)
	if Meta.unlocked("perk_key"): p.keys += 1
	if Meta.unlocked("perk_heart"):
		p.max_hp += 2
		p.hp += 2
	if GameData.rogues():
		Stars.apply_to(p)   # the constellation (scripts/game/stars.gd)
	if dread >= 5:
		p.max_hp = maxi(2, p.max_hp - 2)
		p.hp = mini(p.hp, p.max_hp)
	if Meta.unlocked("perk_relic"):
		var r := roll_relics(1, "chest")
		if not r.is_empty(): add_relic(p, r[0])
	if p.start_rare:
		var r := roll_relics(1, "iron")
		if not r.is_empty(): add_relic(p, r[0])
	_debug_give(p)
	Meta.meta["runs"] += 1
	Meta.write_save()
	start_floor()

## Playtesting: --give=relic:id,gear:id,trait:id,weapon:id and --combo=ID
## (hands over everything a named combo needs). No effect without the flags.
func _debug_give(p: Player) -> void:
	var items: Array = []
	if DebugArgs.has("give"):
		items.append_array(DebugArgs.get_str("give").split(",", false))
	if DebugArgs.has("combo"):
		for c in Synergies.COMBOS:
			if c["id"] == DebugArgs.get_str("combo"):
				items.append_array(c["needs"])
	for need in items:
		var parts: PackedStringArray = need.split(":")
		if parts.size() == 2 and parts[0] == "belt" and Consumables.is_kind(parts[1]):
			Consumables.take(p, parts[1])
			continue
		if parts.size() == 2 and parts[0] == "pack" and Weapons._by_id.has(parts[1]):
			p.backpack.append(Weapons.by_id(parts[1]))
			continue
		var table := { "relic": Relics, "weapon": Weapons, "gear": Gear, "trait": Traits }
		if parts.size() != 2 or not table.has(parts[0]):
			continue
		table[parts[0]].all()
		if not table[parts[0]]._by_id.has(parts[1]):
			push_warning("--give: unknown " + need)
			continue
		match parts[0]:
			"relic": add_relic(p, Relics.by_id(parts[1]))
			"weapon": Weapons.equip_weapon(p, Weapons.by_id(parts[1]))
			"gear": Gear.equip_gear(p, Gear.by_id(parts[1]))
			"trait":
				var t: Dictionary = Traits.by_id(parts[1])
				for k in t["max"]:
					p.pending += 1
					take_trait(t)
	if DebugArgs.has("heavy"):
		_debug_heavy(p)
	if not items.is_empty():
		Effects.recount_tags(p)

## --heavy: a late-run build to test performance (40 relics, 40 trait
## ranks, a legendary weapon and legendary gear), the same for every run.
func _debug_heavy(p: Player) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var rel := Relics.all().duplicate()
	for i in 40:
		add_relic(p, rel.pop_at(rng.randi() % rel.size()))
	var tr := Traits.all().duplicate()
	var ranks := 0
	while ranks < 40 and not tr.is_empty():
		var t: Dictionary = tr.pop_at(rng.randi() % tr.size())
		for k in t["max"]:
			p.pending += 1
			take_trait(t)
			ranks += 1
	var legends := Weapons.all().filter(func(w): return w["rarity"] == "legend")
	Weapons.equip_weapon(p, legends[rng.randi() % legends.size()])
	for g in Gear.all().filter(func(g): return g["rarity"] == "legend"):
		Gear.equip_gear(p, g)
	Effects.recount_tags(p)
	state = &"play"

func start_floor() -> void:
	if player != null:
		player.floor_kills = 0
	floor_d = World.new_floor(floor_index)
	Saloon.on_floor_start()
	EventRooms.on_floor_start()
	run_stats["floor"] = floor_index + 1
	Meta.meta["best"] = maxi(Meta.meta["best"], floor_index + 1)
	Meta.write_save()
	Snd.music(GameData.floor_music(floor_index))
	room = null
	if FloorMap.wanted():
		FloorMap.generate(floor_d, player)
		floor_d["map"]["cells"][floor_d["map"]["start"]]["visited"] = true
		enter_room(FloorMap.room_at(floor_d["map"]["start"], ""))
	else:
		enter_room(World.make_room(floor_d, "start", "", ""))
	Effects.fire("on_floor_start")
	state = &"play"
	show_banner(GameData.floors()[floor_index]["name"], "FLOOR %d OF %d" % [floor_index + 1, GameData.floors().size()]
		+ ("   DREAD %d" % dread if dread > 0 else "") + ("   LOOP %d" % (loop + 1) if loop > 0 else ""))

const ENTRY_SPOTS := { "s": Vector2(14.0 * 16, 16.0 * 16), "n": Vector2(14.0 * 16, 2.6 * 16),
	"e": Vector2(26.0 * 16 - 2, 9.5 * 16), "w": Vector2(2.0 * 16 + 2, 9.5 * 16) }

func enter_room(r: Room) -> void:
	room = r
	EventRooms.on_enter_room()
	Fx.clear()
	Juice.reset()
	EBullets.clear()
	RiftBosses.clear()
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
	champ = null
	win_timer = null
	var p := player
	p.buckler_used = false
	p.volleys = []
	p.trail = []
	p.dodge_t = 0.0
	if p.leap_max > 0:
		# A leap never carries into the next room (a ground charge still does, as before).
		p.dash_t = 0.0
		p.leap_max = 0.0
		p.air = 0.0
		p.dash_end = []
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
	Pets.enter_room(p)
	if not room.objects_ready:
		room.objects_ready = true
		setup_objects(room)
		Hazards.setup(room, floor_index)
		RiftExtras.setup(room)
	if GameData.rogues() and room.type == "start":
		# Rogues layer: two training dummies to test your damage.
		for dx in [5.0, 23.0]:
			var d := Combat.spawn_enemy("dummy", dx * TB.TS, 9.0 * TB.TS, false, true)
			d.max_hp = 1e6
			d.hp = 1e6
	locked = false
	_spawned = false
	match "" if room.cleared else room.type:   # a cleared room on the floor map stays cleared
		"combat", "elite":
			locked = true
			room.waves_left = (2 if room.type == "elite" else 1) + (1 if randf() < 0.25 + 0.08 * floor_index else 0)
			if room.champion != "":
				room.waves_left = 1   # a rift champion's room: the champion and its escort
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
	if GameData.rogues():
		# Rogues layer: a rift world plays its own track and announces itself; event rooms set their scene.
		if room.type != "boss":
			Snd.music(room.theme["music"] if not room.theme.is_empty() else GameData.floor_music(floor_index))
		if not room.theme.is_empty() and room.rift_step == 0:
			show_banner(room.theme["name"], room.theme["sub"])
			if room.theme["id"] == "gaol" and player.hero["id"] == "gaolbird":
				show_banner(room.theme["name"], "BACK SO SOON, LITTLE BIRD?")   # the gaol knows its runaway
		if room.event == "goblin" and not room.cleared:
			room.cleared = true
			Combat.spawn_enemy("goblin", 14.0 * TB.TS, 7.0 * TB.TS, false, true)
			show_banner("A LOOT GOBLIN!", "CATCH IT BEFORE IT SLIPS AWAY")
	dyn_dirty = true
	room_changed.emit()
	if not p.procs.is_empty():
		Effects.fire("on_room_enter")

func open_exits() -> void:
	if room.exits_open:
		return
	room.exits_open = true
	if room.type == "boss" and room.rift_step < 3:
		return
	if not room.theme.is_empty() and room.rift_step < 2:
		# Inside a rift there is one way on: deeper, and then to its champion.
		World.assign_exits(room, [{ "type": "rift", "reward": "rare" if room.rift_step == 0 else "", "theme": room.theme["id"],
			"step": room.rift_step + 1 }])
	elif FloorMap.active():
		if room.on_map:
			FloorMap.link(room)
		else:
			FloorMap.link_back(room)   # a rift's last room, a hidden room: back to the map
	else:
		World.assign_exits(room, World.gen_choices(floor_d, player))
	if room.rift_step == 2 and room.theme.has("guardian"):
		_deeper_door(room)
	for d in room.exits:
		var c: Dictionary = room.exits[d]
		if c["type"] != "vault":
			continue
		var pos := World.door_center(d)
		var ix: int = { "w": 22, "e": -22 }.get(d, 0)
		var iy: int = { "n": 26, "s": -22 }.get(d, 0)
		room.objects.append({ "kind": "lockdoor", "dir": d, "x": pos.x + ix, "y": pos.y + iy })
	dyn_dirty = true

## A new world's champion room: one more door, to the world's guardian (an optional fight).
func _deeper_door(r: Room) -> void:
	for d in ["n", "e", "w"]:
		if d == r.entrance or r.exits.has(d) or r.secret_dirs.has(d):
			continue
		r.exits[d] = { "type": "rift", "reward": "", "theme": r.theme["id"], "step": 3 }
		r.doors[d] = true
		for cr in World.door_tiles(d):
			r.set_tile(cr.x, cr.y, World.T_DOOR)
		return

func leave_room(dir: String) -> void:
	var c = room.exits.get(dir)
	if c == null:
		return
	if c.get("map", false):
		_leave_on_map(dir, c)
		return
	# The second and third rooms of a rift are a detour, like a hidden room: the floor does not advance.
	var inner: bool = c["type"] == "rift" and c.get("step", 0) > 0
	if c["type"] != "secret" and not inner:
		floor_d["depth"] += 1
		floor_d["path"].append(c)
	if c["type"] == "shop":
		floor_d["shop_done"] = true
	if c["type"] == "secret":
		Meta.meta["secrets"] += 1
		run_stats["secrets"] += 1
	var kind: String = c["type"]
	var reward: String = c.get("reward", "")
	var opts := {}
	if kind == "rift":
		var step: int = c.get("step", 0)
		if step == 0:
			floor_d["rift_done"] = true
			run_stats["rifts"].append(c["theme"])
			reward = World.roll_reward(player)
		opts = { "theme": c["theme"], "step": step }
		kind = ["combat", "elite", "elite", "boss"][clampi(step, 0, 3)]
	elif kind == "mystery":
		opts = { "event": TB.pick(MYSTERY_EVENTS) }
		if randf() < 0.18:
			opts["event"] = TB.pick(EventRooms.SPECIAL)   # a special room: rarer than an event
	var nr := World.make_room(floor_d, kind, reward, World.OPP[dir], opts)
	start_fade(func(): enter_room(nr))

## The floor map: through a door to the next room of the map (made the first time), back from a
## room off the map, or into the floor's rift (its three rooms are off the map; the last leads back).
func _leave_on_map(dir: String, c: Dictionary) -> void:
	if c["type"] == "rift" and room.on_map:
		var to: Vector2i = room.cell + World.DIRS[dir]
		var cell: Dictionary = FloorMap.cells()[to]
		floor_d["rift_done"] = true
		run_stats["rifts"].append(cell["theme"])
		FloorMap.close_cell(to)
		var rr := World.make_room(floor_d, "combat", World.roll_reward(player), World.OPP[dir], { "theme": cell["theme"], "step": 0 })
		start_fade(func(): enter_room(rr))
		return
	if c["type"] == "secret" and room.on_map:
		var cell2: Dictionary = FloorMap.cells().get(room.cell + World.DIRS[dir], {})
		if not cell2.is_empty() and not cell2["visited"]:
			Meta.meta["secrets"] += 1
			run_stats["secrets"] += 1
	var nr := FloorMap.step(dir)
	start_fade(func(): enter_room(nr))

## Events of a MYSTERY room, and the ones a hidden room may hold instead of its old three finds.
const MYSTERY_EVENTS := ["wheel", "market", "mimic", "armory", "well", "goblin", "mirror", "library", "safehouse", "saloon",
	"pit", "chopshop", "fortune", "courier", "gallery"]
const SECRET_EVENTS := ["market", "armory", "goblin", "mirror", "library"]

const EVENT_TITLE := {
	"wheel": ["A GAMBLER'S DEN", "THE WHEEL OF FATE TURNS FOR GOLD"], "market": ["THE BLOOD MARKET", "RELICS FOR SALE. THE PRICE IS A HEART"],
	"mimic": ["A QUIET TREASURY", "TWO CHESTS. SOMETHING IS BREATHING"], "armory": ["A FORGOTTEN ARMORY", "TAKE ONE WEAPON. ONLY ONE"],
	"well": ["A WISHING WELL", "A COIN FOR A WISH"], "mirror": ["A HALL OF MIRRORS", "ONE OF THEM IS LOOKING BACK"],
	"library": ["A SEALED LIBRARY", "ONE BOOK IS STILL WARM"], "safehouse": ["A SAFEHOUSE", "A BED, AND MUSIC"],
	"saloon": ["THE LAST DROP SALOON", "DRINKS, DEALS AND BOUNTIES"],
}

## Furniture of an event room.
func _setup_event(r: Room, ev: String) -> void:
	var cx := 14.0 * TB.TS
	var cy := 9.5 * TB.TS
	var f := floor_index
	r.event = ev
	if EVENT_TITLE.has(ev):
		show_banner(EVENT_TITLE[ev][0], EVENT_TITLE[ev][1])
	elif EventRooms.TITLE.has(ev):
		show_banner(EventRooms.TITLE[ev][0], EventRooms.TITLE[ev][1])
		EventRooms.setup(r, ev)
	match ev:
		"wheel":
			r.objects.append({ "kind": "wheel", "x": cx, "y": cy, "uses": 3 })
		"market":
			# The blood market: three relics, each for a max heart.
			r.objects.append({ "kind": "bloodstall", "x": cx, "y": cy - 34, "used": true })
			var rel := roll_relics(3, "iron", r)
			for i in rel.size():
				r.objects.append({ "kind": "bloodshop", "relic": rel[i], "x": cx - 44 + i * 44, "y": cy + 6 })
		"mimic":
			var left := randf() < 0.5
			r.objects.append({ "kind": "chest" if left else "mimicchest", "x": cx - 28, "y": cy })
			r.objects.append({ "kind": "mimicchest" if left else "chest", "x": cx + 28, "y": cy })
		"armory":
			# Three weapons on show: take one and the others are locked away.
			var seen := {}
			for i in 3:
				var w := Weapons.random_weapon(Gear.roll_item_rarity(f, "elite"), player.weapon)
				for tries in 6:
					if not seen.has(w["id"]):
						break
					w = Weapons.random_weapon(Gear.roll_item_rarity(f, "elite"), player.weapon)
				seen[w["id"]] = true
				r.objects.append({ "kind": "item", "item": w, "x": cx - 48 + i * 48, "y": cy, "t": 0.0, "group": "armory" })
		"well":
			r.objects.append({ "kind": "well", "x": cx, "y": cy, "uses": 5 })
		"mirror":
			r.objects.append({ "kind": "mirror", "x": cx, "y": cy })
		"library":
			r.objects.append({ "kind": "tome", "x": cx, "y": cy })
		"safehouse":
			r.objects.append({ "kind": "bed", "x": cx - 34, "y": cy })
			r.objects.append({ "kind": "jukebox", "x": cx + 34, "y": cy })
		"goblin":
			pass   # the goblin itself appears when the room is entered
		"saloon":
			Saloon.setup(r)

## An event's fight (a mimic, your shadow) is over: the room opens and pays out.
func event_fight_cleared() -> void:
	locked = false
	room.event_fight = false
	dyn_dirty = true
	Snd.play("door")
	var cx := 14.0 * TB.TS
	var cy := 9.5 * TB.TS
	match room.event:
		"mimic":
			room.objects.append({ "kind": "ichest", "x": cx, "y": cy + 26, "free": true })
			for i in 4:
				Combat.drop_pickup("gem", cx, cy + 26)
			show_banner("THE MIMIC IS DEAD", "IT HAD SWALLOWED AN IRON CHEST")
		"mirror":
			var rel := roll_relics(1, "iron", room)
			room.objects.append({ "kind": "pedestal", "relic": rel[0] if not rel.is_empty() else null, "x": cx, "y": cy + 26 })
			show_banner("YOUR SHADOW YIELDS", "IT LEAVES A GIFT BEHIND")
	Snd.play("unlock")

## The loot goblin was caught.
func on_goblin_dead(e: Enemy) -> void:
	for i in 6:
		Combat.drop_pickup("gem", e.x, e.y)
	Combat.drop_pickup("key", e.x, e.y)
	if randf() < 0.35:
		room.objects.append({ "kind": "chest", "x": e.x, "y": e.y })
	else:
		drop_gear_at(e.x, e.y)
	show_banner("GOT IT!", "THE GOBLIN DROPS ITS SACK")
	Snd.play("unlock")

## Opens a hidden door on a free side wall (found by a loose brick or a flawless fight). False when no wall is free.
func reveal_hidden_door(title: String, sub: String) -> bool:
	var sides := []
	for d in ["e", "w"]:
		if d != room.entrance and not room.exits.has(d) and not room.doors.has(d):
			sides.append(d)
	if sides.is_empty():
		return false
	var side: String = TB.pick(sides)
	room.doors[side] = true
	room.secret_dirs[side] = true
	World.open_secret(room, side)
	dyn_dirty = true
	room_changed.emit()
	show_banner(title, sub)
	Snd.play("unlock")
	return true

## Room furniture (Game.rb setup_objects). Chests, shops and shrines are
## placed now so rooms look right; using them arrives with items (stage 5).
## Room furniture (Game.rb setup_objects + 05b_items.rb).
func setup_objects(r: Room) -> void:
	var cx := 14.0 * TB.TS
	var cy := 9.5 * TB.TS
	var f := floor_index
	match r.type:
		"treasure":
			if ItemShow.active() and randf() < 0.4:
				ItemShow.pedestal_room(r)   # the expanded game: three items on pedestals, take one
			elif randf() < 0.35:
				r.objects.append({ "kind": "chest", "x": cx - 24, "y": cy })
				r.objects.append({ "kind": "ichest", "x": cx + 24, "y": cy })
			else:
				r.objects.append({ "kind": "chest", "x": cx, "y": cy })
		"shop":
			var rel := roll_relics(3, "shop", r)
			for i in rel.size():
				var base: int = { "common": 30, "rare": 48, "epic": 70, "legend": 95 }[rel[i]["rarity"]]
				r.objects.append({ "kind": "shop", "item": "relic", "relic": rel[i], "x": cx - 120 + i * 40, "y": cy - 8,
					"price": price(base + f * 8 + TB.rint(0, 8)) })
			var extras := [["potion", 18], ["heart", 12], [TB.pick(["bomb", "key"]), 10], ["armor", 16]]
			for i in extras.size():
				r.objects.append({ "kind": "shop", "item": extras[i][0], "x": cx + 8 + i * 34, "y": cy - 8, "price": price(extras[i][1] + f * 3) })
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
		"mystery":
			_setup_event(r, r.event)
		"secret":
			var roll := randf()
			if GameData.rogues() and randf() < 0.5:
				# Rogues layer: half the hidden rooms hold an event instead.
				_setup_event(r, TB.pick(SECRET_EVENTS))
			elif roll < 0.45:
				var rel := roll_relics(1, "secret", r)
				r.objects.append({ "kind": "pedestal", "relic": rel[0] if not rel.is_empty() else null, "x": cx, "y": cy })
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
			if GameData.rogues():
				r.objects.append({ "kind": "anvil", "x": cx + 56, "y": cy })
	# Pets (expanded game only): a cage in some treasure rooms, vaults and hidden rooms, one for sale in some shops.
	if GameData.rogues():
		var chance: float = { "treasure": 0.12, "vault": 0.35, "secret": 0.2, "shop": 0.25 }.get(r.type, 0.0)
		if chance > 0 and (r.type != "secret" or r.event == "") and randf() < chance:
			var at: Vector2 = { "treasure": Vector2(cx + 100, cy + 10), "vault": Vector2(cx + 84, cy),
				"secret": Vector2(cx + 76, cy - 6), "shop": Vector2(cx, cy + 44) }[r.type]
			r.objects.append(Pets.cage(player, at.x, at.y, "gold" if r.type == "shop" else "key"))
	# Rogues layer: a loose brick in the wall of some quiet rooms opens a hidden door.
	if GameData.rogues() and r.type in ["treasure", "shrine", "rest", "shop"] and randf() < 0.2:
		r.objects.append({ "kind": "brick", "x": (2.0 if randf() < 0.5 else 26.0) * TB.TS, "y": 5.0 * TB.TS })
	# 05b_items.rb: weapons and gear in shops and treasure rooms.
	match r.type:
		"shop":
			var w := Weapons.random_weapon(Gear.roll_item_rarity(f), player.weapon)
			var g := Gear.random_gear(Gear.roll_item_rarity(f))
			r.objects.append({ "kind": "shop", "item": "weapon", "thing": w, "x": cx - 40, "y": cy + 34, "price": item_price(w) })
			r.objects.append({ "kind": "shop", "item": "gear", "thing": g, "x": cx + 40, "y": cy + 34, "price": item_price(g) })
			if GameData.rogues():
				r.objects.append({ "kind": "anvil", "x": cx + 104, "y": cy + 34 })
		"treasure":
			if randf() < 0.35:
				var it: Dictionary = Weapons.random_weapon(Gear.roll_item_rarity(f, "elite"), player.weapon) if randf() < 0.5 \
					else Gear.random_gear(Gear.roll_item_rarity(f, "elite"))
				r.objects.append({ "kind": "item", "item": it, "x": cx, "y": cy + 36, "t": 0.0 })

func _room_pickup(kind: String, x: float, y: float) -> Pickup:
	var k := Pickup.new()
	k.kind = kind
	k.x = x
	k.y = y
	k.t = 1.0
	return k

func spawn_wave(hard: bool = false) -> void:
	var fdef: Dictionary = GameData.floors()[floor_index]
	var n := TB.rint(3, 4) + mini(floor_index, 4) + (1 if room.depth > 3 else 0)
	var ec := (0.05 if floor_index == 0 else 0.08 + floor_index * 0.035) + (0.08 if dread >= 3 else 0.0) + (0.35 if hard else 0.0)
	if room.type == "elite":
		ec += 0.45
	# Stage 7: the elite room before the rest stop holds the floor's mini-boss.
	ec += 0.06 * loop   # loop playthroughs: more elites
	if fdef.has("mini") and room.type == "elite" and room.theme.is_empty() and room.depth == floor_d["total"] - 2 \
			and not floor_d.get("mini_done", false):
		floor_d["mini_done"] = true
		var mini := Combat.spawn_enemy(fdef["mini"], 14.0 * TB.TS, 8.0 * TB.TS)
		show_banner(mini.d["name"], "A CHAMPION OF " + fdef["name"])
		n = maxi(2, n / 2)
	# Rift worlds: their own foes, and the champion in the last room.
	var pool: Array = fdef["pool"] if room.theme.is_empty() else room.theme["pool"]
	if room.champion != "":
		var ch := Combat.spawn_enemy(room.champion, 14.0 * TB.TS, 7.0 * TB.TS)
		room.champion = ""
		show_banner(ch.d["name"], "CHAMPION OF " + room.theme["name"])
		n = maxi(2, n / 2)
	elif room.rift_step == 1 and room.theme.has("mini") and room.waves_left == 1:
		# A new world's mini-boss is the last wave of its second room (scripts/entities/rift_bosses.gd).
		var mb := Combat.spawn_enemy(room.theme["mini"], 14.0 * TB.TS, 7.0 * TB.TS)
		show_banner(mb.d["name"], "IT KEEPS THE WAY TO THE CHAMPION")
		n = maxi(1, n / 3)
	for i in n:
		var type: String = TB.pick(pool)
		var s := World.free_spot(room, player, 90, World.M_FLYER if GameData.ENEMIES[type].get("fly", false) else World.M_WALKER)
		Combat.spawn_enemy(type, s.x, s.y, randf() < ec)
	room.waves_left -= 1

func give_reward(kind: String) -> void:
	var cx := 14.0 * TB.TS
	var cy := 9.5 * TB.TS
	match kind:
		"weapon": drop_item(Weapons.random_weapon(Gear.roll_item_rarity(floor_index), player.weapon), cx, cy)
		"gear": drop_item(Gear.random_gear(Gear.roll_item_rarity(floor_index)), cx, cy)
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

func room_cleared() -> void:
	locked = false
	room.cleared = true
	Saloon.on_room_clear(room)
	EventRooms.on_room_clear(room)
	Pets.on_room_clear()
	dyn_dirty = true
	Snd.play("door")
	var p := player
	Juice.room_clear(p.x, p.y)
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
	elif not room.theme.is_empty() and room.rift_step == 2:
		# The rift's champion is dead: its hoard, a weapon, embers and gems.
		var cx := 14.0 * TB.TS
		var cy := 9.5 * TB.TS
		room.objects.append({ "kind": "chest", "x": cx, "y": cy, "boss": true })
		drop_item(Weapons.random_weapon(Gear.roll_item_rarity(floor_index, "boss"), player.weapon), cx - 30, cy + 24)
		for i in 3:
			Combat.drop_pickup("ember", cx, cy + 20)
		for i in 5:
			Combat.drop_pickup("gem", cx, cy + 20)
		show_banner("THE RIFT IS BROKEN", "TAKE ITS HOARD. THE DOORS LEAD BACK")
		Snd.play("unlock")
	elif room.reward != "":
		give_reward(room.reward)
	# Rogues layer: a fight won without being hit can reveal a hidden door.
	var flawless: bool = GameData.rogues() and room.type in ["combat", "elite"] and room.theme.is_empty() \
		and room.hits == 0 and room.secret_dirs.is_empty() and randf() < 0.35
	var hidden := ""
	if flawless:
		var sides := ["e", "w"]
		sides.erase(room.entrance)
		hidden = TB.pick(sides)
		room.doors[hidden] = true
		room.secret_dirs[hidden] = true
	open_exits()
	if hidden != "":
		World.open_secret(room, hidden)
		dyn_dirty = true
		room_changed.emit()
		show_banner("FLAWLESS!", "NOT A SCRATCH: A HIDDEN DOOR OPENS")
	if p.g("room_armor") > 0:
		p.armor += int(p.g("room_armor"))
	if p.g("room_gold") > 0:
		var g := int(p.g("room_gold"))
		p.gold += g
		Fx.float_text(p.x, p.y - 22, "+%d GOLD" % g, "gold")
	if not p.procs.is_empty():
		Effects.fire("on_room_clear")

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
	Snd.music(GameData.floor_music(floor_index))
	show_banner(b.d["name"] + " FALLS", "")
	for i in 12:
		Combat.drop_pickup("coin", b.x, b.y)
	Combat.drop_pickup("heart", b.x, b.y)
	Combat.drop_pickup("ember", b.x, b.y)
	RiftBosses.clear()
	if room.rift_step == 3:
		# A rift guardian: its hoard, and the way back to the floor (no portal: the floor goes on).
		show_banner(b.d["name"] + " FALLS", "ITS HOARD IS YOURS. THE WAY BACK IS OPEN")
		room.objects.append({ "kind": "chest", "x": 14.0 * TB.TS, "y": 10.0 * TB.TS, "boss": true })
		drop_item(Weapons.random_weapon(Gear.roll_item_rarity(floor_index, "boss"), player.weapon), b.x - 20, b.y + 20)
		drop_item(Gear.random_gear(Gear.roll_item_rarity(floor_index, "boss")), b.x + 20, b.y + 20)
		for i in 6:
			Combat.drop_pickup("gem", b.x, b.y)
		for i in 2:
			Combat.drop_pickup("ember", b.x, b.y)
		if randf() < 0.5:
			room.objects.append(Pets.cage(player, 14.0 * TB.TS + 56, 10.0 * TB.TS, "free"))
		Snd.music(room.theme["music"])
		open_exits()
		return
	var last := floor_index >= GameData.floors().size() - 1
	if floor_index == GameData.THRONE_FLOOR and not last and not run_stats.get("throne", false):
		throne_victory()
	room.objects.append({ "kind": "chest", "x": 14.0 * TB.TS - (0 if last else 28), "y": 10.0 * TB.TS, "boss": true })
	if last and GameData.floors().size() > GameData.FLOORS.size():
		# The true ending: loop again with your build, or leave in victory.
		show_banner("THE ECLIPSE ENDS", "LOOP AGAIN FOR GLORY, OR LEAVE IN VICTORY")
		room.objects.append({ "kind": "loopportal", "x": 14.0 * TB.TS - 56, "y": 10.0 * TB.TS })
		room.objects.append({ "kind": "exitportal", "x": 14.0 * TB.TS + 56, "y": 10.0 * TB.TS })
	elif last:
		win_timer = 4.5
	else:
		room.objects.append({ "kind": "portal", "x": 14.0 * TB.TS + 28, "y": 10.0 * TB.TS })
	# 05b_items.rb: guardians drop a weapon and sometimes gear.
	drop_item(Weapons.random_weapon(Gear.roll_item_rarity(floor_index, "boss"), player.weapon), b.x - 20, b.y + 20)
	if randf() < 0.5:
		drop_item(Gear.random_gear(Gear.roll_item_rarity(floor_index, "boss")), b.x + 20, b.y + 20)

func award_embers(win: bool) -> void:
	var r := run_stats
	var p := player
	var parts := [["FLOORS", (floor_index + (1 if win else 0)) * 6], ["GUARDIANS", r["bosses"] * 12], ["FOES", r["kills"] / 8],
		["EMBER SHARDS", p.embers_found], ["SECRETS", r["secrets"] * 5], ["LEVEL", p.level]]
	if win or run_stats.get("throne", false):
		parts.append(["VICTORY", 40])
	if win and run_stats.get("throne", false):
		parts.append(["THE ECLIPSE", 80])
	if loop > 0:
		parts.append(["LOOPS", loop * 60])
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

## Stage 7: the Pale Regent falls with the new floors ahead. This is still the
## original game's victory (wins and dread unlock are granted now), and the
## run goes on through the rift into the new biomes.
func throne_victory() -> void:
	run_stats["throne"] = true
	Meta.meta["wins"] += 1
	Meta.meta["dread_max"] = mini(maxi(Meta.meta.get("dread_max", 0), dread + 1), 5)
	Meta.write_save()
	Snd.play("win")
	show_banner("VICTORY! THE THRONE IS BROKEN", "A RIFT OPENS ONTO DARKER LANDS")

func on_win() -> void:
	if not run_stats.get("throne", false):
		Meta.meta["wins"] += 1
		Meta.meta["dread_max"] = mini(maxi(Meta.meta.get("dread_max", 0), dread + 1), 5)
	else:
		Meta.meta["eclipse_wins"] = Meta.meta.get("eclipse_wins", 0) + 1
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
	if Saloon.handles(o["kind"]):
		return Saloon.interact(o)
	if EventRooms.handles(o["kind"]):
		return EventRooms.interact(o)
	if RiftExtras.handles(o["kind"]):
		return RiftExtras.interact(o)
	if Pets.handles(o["kind"]):
		return Pets.interact(o)
	var p := player
	# 05b_items.rb: weapons and gear on the floor or for sale.
	if o["kind"] == "item":
		if o.has("curse"):
			EventRooms.take_cursed(p, o)
		var old = swap_item(o, o["item"])
		if old != null and not to_backpack(old):
			o["item"] = old
			o["t"] = 0.0
		else:
			o["gone"] = true
		if o.has("group"):
			# An armory lets you take one: the rest are locked away.
			for o2 in room.objects:
				if o2 != o and o2.get("group", "") == o["group"] and not o2.get("gone", false):
					o2["gone"] = true
					Fx.burst(o2["x"], o2["y"], ["#8b8f9c", "#4e4a5e"], 10, 50)
			o.erase("group")
		return
	if o["kind"] == "shop" and (o["item"] == "weapon" or o["item"] == "gear"):
		if p.gold < o["price"]:
			return deny(o, "NEED %d GOLD" % o["price"])
		p.gold -= o["price"]
		o["gone"] = true
		Snd.play("coin")
		var old = swap_item(o, o["thing"])
		if old != null and not to_backpack(old):
			drop_item(old, o["x"], o["y"] - 22)
		return
	match o["kind"]:
		"chest":
			o["opened"] = true
			Snd.play("open")
			Fx.burst(o["x"], o["y"], ["#f2c94c", "#fffbe0"], 16, 60)
			open_choice("boss" if o.get("boss", false) else "chest", o)
		"ichest":
			if not o.get("free", false):
				if p.keys <= 0:
					return deny(o, "NEEDS A KEY")
				p.keys -= 1
			o["opened"] = true
			Snd.play("lock")
			Snd.play("open")
			Fx.burst(o["x"], o["y"], ["#8b8f9c", "#f4ecd8", "#f2c94c"], 18, 60)
			open_choice("iron", o)
		"cchest":
			if p.max_hp <= 2:
				return deny(o, "TOO WEAK")
			o["opened"] = true
			p.max_hp -= 2
			p.hp = mini(p.hp, p.max_hp)
			add_shake(4)
			Snd.play("hurt")
			Fx.burst(o["x"], o["y"], ["#a35bd6", "#5c3483", "#d8443c"], 20, 70)
			open_choice("cursed", o)
		"pedestal":
			o["opened"] = true
			if o["relic"] != null:
				add_relic(p, o["relic"])
				show_banner(o["relic"]["name"], o["relic"]["desc"])
		"shop":
			if p.gold < o["price"]:
				return deny(o, "NEED %d GOLD" % o["price"])
			if o["item"] == "potion" and p.potions >= p.max_potions:
				return deny(o, "POTIONS FULL")
			if o["item"] == "heart" and p.hp >= p.max_hp:
				return deny(o, "HEALTH FULL")
			p.gold -= o["price"]
			o["gone"] = true
			Snd.play("coin")
			match o["item"]:
				"relic":
					add_relic(p, o["relic"])
					show_banner(o["relic"]["name"], o["relic"]["desc"])
				"potion":
					p.potions += 1
					Snd.play("heal")
				"heart": p.heal(2)
				"bomb": p.bombs += 1
				"key": p.keys += 1
				"armor": p.armor += 1
		"altar":
			if p.hp <= 2:
				return deny(o, "TOO WEAK")
			p.hp -= 2
			o["used"] = true
			add_shake(4)
			Snd.play("hurt")
			Fx.burst(o["x"], o["y"], ["#d8443c", "#8a2a33"], 20, 70)
			var r := roll_relics(1, "altar")
			if not r.is_empty():
				add_relic(p, r[0])
				show_banner(r[0]["name"], r[0]["desc"])
		"fountain":
			o["used"] = true
			p.heal(p.max_hp)
			Fx.burst(o["x"], o["y"], ["#6fd3e0", "#f4ecd8"], 20, 60)
		"anvil":
			# Rogues layer: pay gold to upgrade the weapon you hold (+8% damage per level).
			if WeaponInfo.plus(p.weapon) >= WeaponInfo.MAX_PLUS:
				return deny(o, "ALREADY +%d" % WeaponInfo.MAX_PLUS)
			var acost := price(WeaponInfo.anvil_cost(p))
			if p.gold < acost:
				return deny(o, "NEED %d GOLD" % acost)
			p.gold -= acost
			var lv := WeaponInfo.upgrade(p, 1)
			Snd.play("hit")
			G.add_shake(3)
			Fx.burst(o["x"], o["y"] - 4, ["#f2c94c", "#e8873a", "#ffffff"], 18, 70)
			Juice.label("+%d" % lv, "#f2c94c", o["x"], o["y"] - 16, true)
			toast(WeaponInfo.display_name(p.weapon), "gold")
		"campfire":
			o["used"] = true
			p.heal(ceili(p.max_hp / 2.0))
			p.charges = p.dodge_charges
			Fx.burst(o["x"], o["y"], ["#e8873a", "#f2c94c"], 20, 50)
			toast("YOU REST BY THE FIRE", "orange")
		"idol":
			var cost := price(15 + floor_index * 3)
			if p.gold < cost:
				return deny(o, "NEED %d GOLD" % cost)
			p.gold -= cost
			o["uses"] -= 1
			if o["uses"] <= 0:
				o["used"] = true
			Snd.play("coin")
			var roll := randf()
			if roll < 0.28:
				for i in 2:
					Combat.drop_pickup("gem", o["x"], o["y"] + 10)
				toast("THE IDOL PAYS OUT", "gold")
			elif roll < 0.42:
				var r := roll_relics(1, "chest")
				if not r.is_empty():
					add_relic(p, r[0])
					show_banner(r[0]["name"], r[0]["desc"])
			elif roll < 0.62:
				Combat.drop_pickup(TB.pick(["bomb", "key", "armor", "potion"]), o["x"], o["y"] + 10)
				toast("A GIFT FROM THE IDOL", "white")
			elif roll < 0.8:
				toast("THE IDOL KEEPS YOUR GOLD", "grey")
				Snd.play("deny")
			else:
				Combat.hurt_player(1, "a greedy idol")
				toast("THE IDOL BITES", "red")
		"bell":
			o["used"] = true
			Snd.play("bell")
			locked = true
			_spawned = false
			_wave_delay = 0.8
			room.waves_left = 3
			dyn_dirty = true
			show_banner("THE BELL TOLLS", "SURVIVE THREE HARD WAVES")
		"wheel":
			var wcost := price(12 + floor_index * 4)
			if p.gold < wcost:
				return deny(o, "NEED %d GOLD" % wcost)
			p.gold -= wcost
			o["uses"] -= 1
			if o["uses"] <= 0:
				o["used"] = true
			Snd.play("coin")
			o["spin"] = time
			var wr := randf()
			if wr < 0.22:
				for i in 3:
					Combat.drop_pickup("gem", o["x"], o["y"] + 12)
				toast("JACKPOT!", "gold")
			elif wr < 0.40:
				p.heal(2)
				toast("THE WHEEL MENDS YOU", "pink")
			elif wr < 0.52:
				var r := roll_relics(1, "chest")
				if not r.is_empty():
					add_relic(p, r[0])
					show_banner(r[0]["name"], r[0]["desc"])
			elif wr < 0.64:
				Combat.drop_pickup("bomb", o["x"], o["y"] + 12)
				Combat.drop_pickup("key", o["x"], o["y"] + 12)
				toast("SUPPLIES!", "white")
			elif wr < 0.76:
				drop_gear_at(o["x"], o["y"] + 20)
				toast("THE WHEEL DROPS A PRIZE", "cyan")
			elif wr < 0.88:
				toast("BAD LUCK. NOTHING", "grey")
				Snd.play("deny")
			else:
				Combat.hurt_player(1, "the wheel of fate")
				toast("THE WHEEL BITES", "red")
		"bloodshop":
			if p.max_hp <= 2:
				return deny(o, "TOO WEAK")
			p.max_hp -= 2
			p.hp = mini(p.hp, p.max_hp)
			o["gone"] = true
			add_shake(4)
			Snd.play("hurt")
			Fx.burst(o["x"], o["y"], ["#d8443c", "#8a2a33"], 20, 70)
			add_relic(p, o["relic"])
			show_banner(o["relic"]["name"], o["relic"]["desc"])
		"mimicchest":
			o["gone"] = true
			Combat.spawn_enemy("mimic", o["x"], o["y"], false, true)
			locked = true
			room.event_fight = true
			dyn_dirty = true
			add_shake(5)
			Snd.play("roar")
			show_banner("IT HAS TEETH!", "THE CHEST WAS A MIMIC")
		"well":
			var wc := price(8 + floor_index * 2)
			if p.gold < wc:
				return deny(o, "NEED %d GOLD" % wc)
			p.gold -= wc
			o["uses"] -= 1
			if o["uses"] <= 0:
				o["used"] = true
			Snd.play("coin")
			Fx.burst(o["x"], o["y"] + 2, ["#6fd3e0", "#4d9be6", "#f4ecd8"], 10, 50)
			var roll2 := randf()
			if roll2 < 0.35:
				Combat.drop_pickup("heart", o["x"], o["y"] + 14)
				toast("THE WELL GRANTS HEALTH", "pink")
			elif roll2 < 0.55:
				for i in 2:
					Combat.drop_pickup("gem", o["x"], o["y"] + 14)
				toast("YOUR COIN COMES BACK TENFOLD", "gold")
			elif roll2 < 0.70:
				Combat.drop_pickup(TB.pick(["key", "bomb"]), o["x"], o["y"] + 14)
				toast("SOMETHING FLOATS UP", "white")
			elif roll2 < 0.80:
				Combat.drop_pickup("armor", o["x"], o["y"] + 14)
				toast("THE WELL GRANTS PROTECTION", "cyan")
			elif roll2 < 0.86:
				var r := roll_relics(1, "chest")
				if not r.is_empty():
					add_relic(p, r[0])
					show_banner(r[0]["name"], r[0]["desc"])
			else:
				toast("PLOP. NOTHING HAPPENS", "grey")
		"mirror":
			o["used"] = true
			Combat.spawn_enemy("shadow", o["x"], o["y"] - 44, false, true)
			locked = true
			room.event_fight = true
			dyn_dirty = true
			Snd.play("portal")
			show_banner("YOUR SHADOW STEPS OUT", "BEAT IT FOR ITS GIFT")
		"tome":
			if p.hp <= 1:
				return deny(o, "TOO WEAK")
			o["used"] = true
			p.hp -= 1
			Snd.play("hurt")
			Fx.burst(o["x"], o["y"], ["#a35bd6", "#5c3483", "#f2c94c"], 18, 70)
			Combat.gain_xp(p, GameData.xp_needed(p.level) - p.xp)
			toast("FORBIDDEN KNOWLEDGE: A LEVEL GAINED", "purple")
		"bed":
			o["used"] = true
			p.heal(4)
			Fx.burst(o["x"], o["y"], ["#4d9be6", "#f4ecd8"], 14, 50)
			toast("YOU SLEEP SOUNDLY", "cyan")
		"jukebox":
			var jc := price(10 + floor_index * 2)
			if p.gold < jc:
				return deny(o, "NEED %d GOLD" % jc)
			p.gold -= jc
			o["used"] = true
			Snd.play("bell")
			Effects.add_buff(p, "dmg", 0.25, 60.0)
			Effects.add_buff(p, "speed", 0.15, 60.0)
			Fx.burst(o["x"], o["y"], ["#e86fb4", "#f2c94c", "#6fd3e0"], 18, 70)
			toast("A GOOD TUNE: +25% DAMAGE FOR 60S", "pink")
		"brick":
			o["gone"] = true
			Snd.play("lock")
			if not reveal_hidden_door("A HIDDEN ROOM", "THE LOOSE BRICK SLIDES IN"):
				for i in 4:
					Combat.drop_pickup("gem", o["x"], o["y"] + 10)
				toast("A HIDDEN CACHE", "gold")
		"lockdoor":
			if p.keys <= 0:
				return deny(o, "NEEDS A KEY")
			p.keys -= 1
			o["used"] = true
			room.sealed.erase(o["dir"])
			dyn_dirty = true
			Snd.play("lock")
			Snd.play("door")
			toast("THE VAULT DOOR OPENS", "gold")
		"portal":
			Snd.play("portal")
			start_fade(func():
				floor_index += 1
				player.heal(2)
				start_floor())
		"loopportal":
			Snd.play("portal")
			start_fade(func():
				loop += 1
				run_stats["loops"] = loop
				Meta.meta["best_loop"] = maxi(Meta.meta.get("best_loop", 0), loop)
				floor_index = 0
				player.heal(4)
				start_floor())
		"exitportal":
			Snd.play("portal")
			start_fade(on_win)

# ---------- Relics, items and traits ----------
func price(v: float) -> int:
	if dread >= 3:
		v *= 1 + 0.08 * dread
	return maxi(1, roundi(v * (1 - player.shop_disc)))

func item_price(item: Dictionary) -> int:
	var base: int = { "common": 26, "rare": 44, "epic": 68, "legend": 96 }[item["rarity"]]
	return price(base + floor_index * 8)

func drop_item(item: Dictionary, x: float, y: float) -> void:
	room.objects.append({ "kind": "item", "item": item, "x": clampf(x, 3 * TB.TS, 25 * TB.TS),
		"y": clampf(y, 4 * TB.TS, 15 * TB.TS), "t": 0.0 })

func drop_gear_at(x: float, y: float) -> void:
	drop_item(Gear.random_gear(Gear.roll_item_rarity(floor_index, "elite")), x, y)

## Rogues layer: a replaced weapon or gear piece goes into the backpack if
## there is room (false: it stays on the floor, as in the original game).
func to_backpack(it: Dictionary) -> bool:
	var p := player
	if not GameData.rogues() or p.backpack.size() >= Player.BACKPACK_SIZE:
		return false
	p.backpack.append(it)
	toast("%s TO BACKPACK" % it["name"], "tan")
	return true

## Equips backpack item i; what it replaces takes its place in the backpack.
func equip_from_backpack(i: int) -> void:
	var p := player
	if i < 0 or i >= p.backpack.size():
		return
	var it: Dictionary = p.backpack[i]
	var old = Weapons.equip_weapon(p, it) if it["item"] == "weapon" else Gear.equip_gear(p, it)
	if old != null:
		p.backpack[i] = old
	else:
		p.backpack.remove_at(i)
	Snd.play("relic")

## Equips a floor or shop item and returns what it replaced (or null).
func swap_item(o: Dictionary, it: Dictionary) -> Variant:
	var p := player
	var old = Weapons.equip_weapon(p, it) if it["item"] == "weapon" else Gear.equip_gear(p, it)
	Snd.play("relic")
	show_banner(it["name"], (Weapons.ARCH[it["kind"]]["name"] if it["item"] == "weapon" else Gear.SLOT_NAME[it["slot"]]) + " - " + it["desc"])
	Fx.burst(o["x"], o["y"], [GameData.RARITY_HEX[it["rarity"]], "#ffffff"], 14, 60)
	return old

func tree_owned(hero_id: String) -> Array:
	if not Meta.meta["tree"].has(hero_id):
		Meta.meta["tree"][hero_id] = [0, 0, 0]
	return Meta.meta["tree"][hero_id]

func relic_pool() -> Array:
	var ids := Relics.base_ids()
	if Meta.unlocked("cache1"): ids += Relics.CACHE_1
	if Meta.unlocked("cache2"): ids += Relics.CACHE_2
	if Meta.unlocked("cache3"): ids += Relics.CACHE_3
	ids += Relics.new_ids()   # new content is always in the pool
	var out := []
	for i in ids:
		out.append(Relics.by_id(i))
	return out

const RARITY_ORDER := ["common", "rare", "epic", "legend"]

func roll_rarity(source: String) -> String:
	var w: Dictionary = Relics.LOOT.get(source, Relics.LOOT["chest"])
	var best := ""
	for k in 1 + (player.luck if player != null else 0):
		var got := String(TB.weighted(w))
		if best == "" or RARITY_ORDER.find(got) > RARITY_ORDER.find(best):
			best = got
	return best

## n relics nobody owns or is already offered in this room (Game.rb roll_relics).
func roll_relics(n: int, source: String = "chest", in_room: Room = null) -> Array:
	var r_room := in_room if in_room != null else room
	var owned := {}
	for r in player.relics:
		owned[r["id"]] = true
	var offered := {}
	if r_room != null:
		for o in r_room.objects:
			if o.get("relic") != null:
				offered[o["relic"]["id"]] = true
	var pool := []
	for r in relic_pool():
		if not owned.has(r["id"]) and not offered.has(r["id"]):
			pool.append(r)
	if pool.size() < n:
		pool = []
		for r in relic_pool():
			if not owned.has(r["id"]):
				pool.append(r)
	var out := []
	for k in n:
		if pool.is_empty():
			break
		var rar := roll_rarity(source)
		var order := ["legend", "epic", "rare", "common"]
		var cands := []
		var i := order.find(rar)
		while cands.is_empty() and i < order.size():
			for r in pool:
				if r["rarity"] == order[i]:
					cands.append(r)
			i += 1
		if cands.is_empty():
			cands = pool
		var r: Dictionary = TB.pick(cands)
		out.append(r)
		pool.erase(r)
	return out

func add_relic(p: Player, r: Dictionary) -> void:
	p.relics.append(r)
	Relics.apply(r["id"], p)
	if r["new"]:
		Effects.recount_tags(p)
	p.charges = mini(p.charges, p.dodge_charges)
	Meta.meta["found"][r["id"]] = true
	Snd.play("relic")

func open_choice(source: String, o: Dictionary) -> void:
	var n := 4 if Meta.unlocked("perk_choice") else 3
	var ch := roll_relics(n, source)
	if ch.is_empty():
		for i in 15:
			Combat.drop_pickup("coin", o["x"], o["y"])
	else:
		choice = { "relics": ch, "idx": mini(1, ch.size() - 1) }
		state = &"choice"

## Offer weight. Original traits keep the original formula exactly. New
## traits (design spec section 4): rarity weight times a snowball affinity
## from ranks already in the family and tag points from new-content items.
## Legendary traits (like capstones) need 3+ ranks in their family, and
## cursed traits only appear from level 3.
func trait_weight(p: Player, t: Dictionary) -> int:
	var rank: int = p.traits.get(t["id"], 0)
	if rank >= t["max"]:
		return 0
	if t["new"]:
		return _new_trait_weight(p, t)
	var fam: int = p.fam.get(t["fam"], 0)
	if t["cap"]:
		return 0 if fam < 3 else 6
	var w := 3
	if t["fam"] != "core":
		w += mini(fam, 4) * 2
	return w

func _new_trait_weight(p: Player, t: Dictionary) -> int:
	var fam: int = p.fam.get(t["fam"], 0)
	if (t["cap"] or t["rarity"] == "legend") and fam < 3:
		return 0
	if t["rarity"] == "cursed" and p.level < 3:
		return 0
	var tagpts := 0
	for tag in t["tags"]:
		tagpts += p.tag_counts.get(tag, 0)
	var affinity := 1 + mini(fam, 4) * 2 + mini(tagpts, 4)
	return Traits.RARITY[t["rarity"]]["w"] * affinity

## Gold price of the next paid reroll (after the free ones run out).
func reroll_cost() -> int:
	return 15 + 10 * player.paid_rerolls

func offer_traits() -> void:
	var p := player
	var cands := []
	for t in Traits.all():
		var w := trait_weight(p, t)
		if w > 0:
			cands.append([t, w])
	var opts := []
	var n_opts := 3
	if TraitView.active() and p.luck > 0 and randf() < minf(0.9, p.luck * 0.15):
		n_opts = 4   # the expanded game: luck can add a fourth trait to choose from
	for k in n_opts:
		if cands.is_empty():
			break
		var tot := 0
		for c in cands:
			tot += c[1]
		var x := randf() * tot
		var idx := 0
		for i in cands.size():
			x -= cands[i][1]
			if x < 0:
				idx = i
				break
		opts.append(cands[idx][0])
		cands.remove_at(idx)
	if opts.is_empty():
		p.pending = 0
		return
	tchoice = { "opts": opts, "idx": 0 if TraitView.active() else mini(1, opts.size() - 1), "t0": time }
	state = &"traits"

func take_trait(t: Dictionary) -> void:
	var p := player
	p.traits[t["id"]] = p.traits.get(t["id"], 0) + 1
	Traits.apply(t["id"], p)
	Attributes.on_trait(p, t["fam"])
	p.charges = mini(p.charges, p.dodge_charges)
	var fam: String = t["fam"]
	p.fam[fam] = p.fam.get(fam, 0) + 1
	if Traits.FAMILY_BONUS.has(fam):
		var tier := mini(p.fam[fam] / 2, 3)
		var have: int = p.fam_bonus.get(fam, 0)
		while have < tier:
			Traits.apply_bonus(fam, have, p)
			var bname := Traits.bonus_name(fam, have)
			have += 1
			toast(Traits.FAMILIES[fam]["name"] + " " + str(have * 2) + ": " + bname, Traits.FAMILIES[fam]["col"])
		p.fam_bonus[fam] = have
	p.pending -= 1
	if t["new"]:
		Effects.recount_tags(p)
	Snd.play("relic")

## RGSS menu_nav: wraps the cursor and returns true on confirm.
func menu_nav(n: int, horizontal: bool = false) -> bool:
	if Keys.left() if horizontal else Keys.up():
		menu = (menu + n - 1) % n
		Snd.play("select")
	if Keys.right() if horizontal else Keys.down():
		menu = (menu + 1) % n
		Snd.play("select")
	return Keys.confirm()

func update_choice() -> void:
	menu = choice["idx"]
	var go := menu_nav(choice["relics"].size(), true)
	choice["idx"] = menu
	if not go:
		return
	var r: Dictionary = choice["relics"][choice["idx"]]
	add_relic(player, r)
	show_banner(r["name"], r["desc"])
	choice = {}
	state = &"play"

## Trait pick: LEFT/RIGHT choose, USE takes it, MENU rerolls (limited).
func update_traits() -> void:
	if TraitView.active() and not TraitView.ready():
		return   # the starburst and the rows coming in
	menu = tchoice["idx"]
	var go := menu_nav(tchoice["opts"].size(), not TraitView.active())
	tchoice["idx"] = menu
	if Keys.back():
		if player.rerolls > 0:
			player.rerolls -= 1
			Snd.play("confirm")
			offer_traits()
			tchoice["t0"] = time - TraitView.BURST   # a reroll: the rows again, not the starburst
		elif player.gold >= reroll_cost():
			# New (design spec 4): once the free rerolls are gone, rerolls cost gold.
			player.gold -= reroll_cost()
			player.paid_rerolls += 1
			Snd.play("coin")
			offer_traits()
			tchoice["t0"] = time - TraitView.BURST
		else:
			Snd.play("deny")
		return
	if not go:
		return
	take_trait(tchoice["opts"][tchoice["idx"]])
	tchoice = {}
	state = &"play"
	if player.pending > 0:
		offer_traits()

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
		&"title": update_title(dt)
		&"stars":
			update_embers(dt)
			StarView.keys(dt)
		&"hero": update_hero()
		&"tree":
			update_embers(dt)
			update_tree()
		&"howto":
			if Keys.any():
				state = &"title"
				Snd.play("select")
		&"options": update_options()
		&"shrine":
			update_embers(dt)
			update_shrine()
		&"codex":
			update_embers(dt)
			update_codex()
		&"pause": update_pause()
		&"inventory": update_inventory()
		&"relics", &"traitlist", &"gearpage":
			if Keys.any():
				state = &"pause"
				Snd.play("select")
		&"choice": update_choice()
		&"traits": update_traits()
		&"dead", &"win":
			update_embers(dt)
			state_t += dt
			if Keys.any() and state_t > 1:
				state = &"title"
				menu = 0
				Snd.play("confirm")
		&"play":
			update_play(dt)

## Rogues layer inventory: LEFT/RIGHT pick a backpack or belt slot (UP/DOWN
## switch rows), USE equips or drinks it, ROLL drops it, MENU goes back.
func update_inventory() -> void:
	var p := player
	if Keys.back():
		state = &"pause"
		Snd.play("select")
		return
	if Keys.left():
		inv_i = (inv_i + 9) % 10
		Snd.play("select")
	if Keys.right():
		inv_i = (inv_i + 1) % 10
		Snd.play("select")
	if Keys.up() or Keys.down():
		inv_i = (inv_i + 6) % 10 if inv_i < 6 else mini(inv_i - 6, 5)
		Snd.play("select")
	if Keys.confirm():
		if inv_i < 6:
			if inv_i < p.backpack.size():
				equip_from_backpack(inv_i)
			else:
				Snd.play("deny")
		else:
			Consumables.use(p, inv_i - 6)
	elif Keys.roll():
		if inv_i < 6 and inv_i < p.backpack.size():
			drop_item(p.backpack[inv_i], p.x, p.y + 14)
			p.backpack.remove_at(inv_i)
			Snd.play("place")
		elif inv_i >= 6 and inv_i - 6 < p.belt.size():
			p.belt.remove_at(inv_i - 6)
			Snd.play("place")

func update_pause() -> void:
	if Keys.back():
		state = &"play"
		Snd.play("select")
		return
	if menu_nav(PAUSE_ITEMS.size()):
		Snd.play("confirm")
		match menu:
			0: state = &"play"
			1:
				state = &"inventory" if GameData.rogues() else &"gearpage"
				inv_i = 0
			2: state = &"traitlist"
			3: state = &"relics"
			4:
				state = &"options"
				opt_from = &"pause"
				menu = 0
			5:
				if quit_armed:
					on_death("giving up")
				else:
					quit_armed = true
	if menu != 5:
		quit_armed = false

# ---------- Menus (Game.rb) ----------
func update_embers(dt: float) -> void:
	if embers.size() < 50 and randf() < 0.5:
		embers.append({ "x": randf() * TB.SW, "y": TB.SH + 4.0, "vy": -(10 + randf() * 25), "vx": (randf() - 0.5) * 8,
			"life": 6 + randf() * 4, "col": TB.pick(["#e8873a", "#f2c94c", "#d8443c"]) })
	var keep := []
	for e in embers:
		e["x"] += (e["vx"] + sin(time * 2 + e["y"] * 0.05) * 6) * dt
		e["y"] += e["vy"] * dt
		e["life"] -= dt
		if e["life"] > 0 and e["y"] >= -4:
			keep.append(e)
	embers = keep

## The title menu; the expanded game adds the constellation (scripts/game/stars.gd).
func title_items() -> Array:
	var out: Array = TITLE_ITEMS.duplicate()
	if GameData.rogues():
		out.insert(2, "CONSTELLATION")
	return out

func title_index(item: String) -> int:
	return maxi(0, title_items().find(item))

func update_title(dt: float) -> void:
	update_embers(dt)
	var items := title_items()
	if not menu_nav(items.size()):
		return
	Snd.play("confirm")
	match items[menu]:
		"START RUN":
			state = &"hero"
			menu = hero_index
		"SKILL TREES":
			state = &"tree"
			tree_hero = hero_index
			tree_b = 0
			tree_n = 0
		"CONSTELLATION": StarView.open()
		"EMBER SHRINE":
			state = &"shrine"
			menu = shrine_i
		"CODEX":
			state = &"codex"
			menu = codex_i
		"HOW TO PLAY": state = &"howto"
		_:
			state = &"options"
			opt_from = &"title"
			menu = 0

func update_hero() -> void:
	# LEFT/RIGHT walk the hero screen's order (free heroes first), not the list order.
	var order := GameData.hero_order()
	menu = order.find(hero_index)
	var go := menu_nav(order.size(), true)
	hero_index = order[menu]
	var mx: int = Meta.meta.get("dread_max", 0)
	if mx > 0:
		if Keys.up():
			Meta.meta["dread"] = (Meta.meta.get("dread", 0) + 1) % (mx + 1)
			Snd.play("select")
		if Keys.down():
			Meta.meta["dread"] = (Meta.meta.get("dread", 0) + mx) % (mx + 1)
			Snd.play("select")
	if Keys.roll():
		state = &"tree"
		tree_hero = hero_index
		tree_b = 0
		tree_n = 0
		tree_from = &"hero"
		Snd.play("select")
		return
	if Keys.back():
		state = &"title"
		menu = 0
		Snd.play("select")
		Meta.write_save()
		return
	if not go:
		return
	var h: Dictionary = GameData.heroes()[hero_index]
	if hero_unlocked(h):
		Snd.play("confirm")
		Meta.write_save()
		start_fade(new_run)
	else:
		Snd.play("deny")
		toast("UNLOCK THIS HERO AT THE EMBER SHRINE", "orange")

## Skill tree: LEFT/RIGHT pick a branch, UP/DOWN a node, USE buys, AIM LEFT/RIGHT change hero.
func update_tree() -> void:
	var order := GameData.hero_order()
	var n := order.size()
	if Keys.aim_left_trig():
		tree_hero = order[(order.find(tree_hero) + n - 1) % n]
		Snd.play("select")
	if Keys.aim_right_trig():
		tree_hero = order[(order.find(tree_hero) + 1) % n]
		Snd.play("select")
	if Keys.left():
		tree_b = (tree_b + 2) % 3
		Snd.play("select")
	if Keys.right():
		tree_b = (tree_b + 1) % 3
		Snd.play("select")
	if Keys.up():
		tree_n = (tree_n + 3) % 4
		Snd.play("select")
	if Keys.down():
		tree_n = (tree_n + 1) % 4
		Snd.play("select")
	if Keys.back():
		state = &"hero" if tree_from == &"hero" else &"title"
		menu = hero_index if tree_from == &"hero" else title_index("SKILL TREES")
		tree_from = &""
		Snd.play("select")
		return
	if not Keys.confirm():
		return
	var h: Dictionary = GameData.heroes()[tree_hero]
	var owned := tree_owned(h["id"])
	if not hero_unlocked(h):
		Snd.play("deny")
		toast("UNLOCK THIS HERO FIRST", "orange")
		return
	if owned[tree_b] > tree_n:
		Snd.play("deny")
		toast("ALREADY LEARNED", "grey")
		return
	if owned[tree_b] < tree_n:
		Snd.play("deny")
		toast("LEARN THE SKILL ABOVE FIRST", "red")
		return
	var cost: int = Traits.TREE_COSTS[tree_n]
	if Meta.meta["embers"] < cost:
		Snd.play("deny")
		toast("NOT ENOUGH EMBERS", "red")
		return
	Meta.meta["embers"] -= cost
	owned[tree_b] += 1
	Meta.write_save()
	Snd.play("unlock")
	toast(Traits.tree_for(h["id"])[tree_b]["nodes"][tree_n][0] + " LEARNED", "gold")

func update_shrine() -> void:
	menu = shrine_i
	var go := menu_nav(GameData.unlocks().size())
	shrine_i = menu
	if Keys.back():
		state = &"title"
		menu = title_index("EMBER SHRINE")
		Snd.play("select")
		return
	if not go:
		return
	var u: Dictionary = GameData.unlocks()[shrine_i]
	if Meta.unlocked(u["id"]):
		Snd.play("deny")
		toast("ALREADY UNLOCKED", "grey")
	elif Meta.meta["embers"] < u["cost"]:
		Snd.play("deny")
		toast("NOT ENOUGH EMBERS", "red")
	else:
		Meta.meta["embers"] -= u["cost"]
		Meta.meta["unlocked"][u["id"]] = true
		Meta.write_save()
		Snd.play("unlock")
		toast(u["name"] + " UNLOCKED", "gold")

func update_codex() -> void:
	var n := Relics.all().size()
	if Keys.left():
		codex_i = (codex_i + n - 1) % n
		Snd.play("select")
	if Keys.right():
		codex_i = (codex_i + 1) % n
		Snd.play("select")
	if Keys.up():
		codex_i = TB.rmod(codex_i - CODEX_COLS, n)
		Snd.play("select")
	if Keys.down():
		codex_i = (codex_i + CODEX_COLS) % n
		Snd.play("select")
	if Keys.back() or Keys.confirm():
		state = &"title"
		menu = title_index("CODEX")
		Snd.play("select")

func update_options() -> void:
	var go := menu_nav(OPTION_LIST.size())
	var back_menu := title_index("OPTIONS") if opt_from == &"title" else 4
	if Keys.back():
		state = opt_from
		menu = back_menu
		Snd.play("select")
		return
	var key: String = OPTION_LIST[menu][1]
	if go or (key != "" and (Keys.left() or Keys.right())):
		if key == "":
			state = opt_from
			menu = back_menu
			Snd.play("select")
			return
		Meta.opts[key] = not Meta.opts[key]
		if key == "music":
			Snd.refresh()
		if key == "vfx":
			Vfx.reset()   # takes effect at once; nothing in play depends on it
		Snd.play("confirm")
		Meta.write_save()

## The app goes to the background (iPad locked, another app opened): a fight in progress waits
## in the pause menu, and the progress so far is saved in case iOS closes the app meanwhile.
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if state == &"play":
			state = &"pause"
			menu = 0
			quit_armed = false
		Meta.write_save()

func update_play(dt: float) -> void:
	run_stats["time"] += dt
	if Keys.pause():
		state = &"pause"
		menu = 0
		quit_armed = false
		Snd.play("select")
		return
	if hitstop > 0:
		hitstop -= dt
		return
	var p := player
	Effects.tick(dt)
	Combat.update_player(p, dt)
	if state != &"play":
		return
	Combat.update_enemies(dt)
	Combat.update_pbullets(dt)
	EBullets.update(dt)
	Combat.update_pickups(dt)
	Combat.update_bombs(dt)
	Combat.update_zones(dt)
	Hazards.update(dt)
	EventRooms.update(dt)
	Fx.update(dt)
	Juice.update(dt, p)
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
	if room.event_fight and locked and enemies.is_empty():
		event_fight_cleared()
	if room.type == "boss" and locked and boss == null and boss_delay != null:
		boss_delay -= dt
		if boss_delay <= 0:
			boss_delay = null
			if room.rift_step == 3:
				Combat.spawn_boss(room.theme["guardian"])
				show_banner(boss.d["name"], "GUARDIAN OF " + room.theme["name"])
			else:
				Combat.spawn_boss(GameData.floors()[floor_index]["boss"])
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
	# Level-ups wait until the room is safe.
	if p.pending > 0 and not locked and enemies.is_empty():
		offer_traits()
		return
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
