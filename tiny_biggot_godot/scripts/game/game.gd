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
var endless_next := false   # 22.2: the camp's ENDLESS STAIR was taken; the next run goes down for ever
var swings: Array = []
var boss: Enemy = null
var champ: Enemy = null       # a rift champion or floor mini-boss in the room: it gets the boss bar
var rex_call := false         # the title's sleeping Rex was woken: the next run starts beside his barn (rex.gd)
var god := false              # debug: --god
var menu := 0
var choice: Dictionary = {}    # relic choice: { relics, idx }
var tchoice: Dictionary = {}   # trait offer: { opts, idx }
# Menus (Game.rb).
const TITLE_ITEMS := ["START RUN", "SKILL TREES", "EMBER SHRINE", "CODEX", "HOW TO PLAY", "OPTIONS"]
const PAUSE_ITEMS := ["RESUME", "GEAR", "TRAITS", "RELICS", "OPTIONS", "ABANDON RUN"]
const OPTION_LIST := [["AUTO-AIM FIRE", "autofire"], ["MUSIC", "music"], ["SOUND EFFECTS", "sfx"], ["PLACE SOUNDS", "places"], ["SCREEN SHAKE", "shake"], ["SHOW FPS", "fps"], ["SHOW GEAR ON HERO", "show_gear"], ["FANCY EFFECTS", "vfx"], ["FAST DRAWING", "fast_draw"], ["MEET THE HAGGLER", "haggler"], ["STAT COLUMN", "statcol"], ["NEON LOOK", "neon"], ["KEYBOARD KEYS", "@keys"], ["RESET GAME", "@reset"], ["BACK", ""]]   # (48.4 RESET GAME)
var reset_armed := false   # 48.4: RESET GAME pressed once, waiting for the second press
const CODEX_COLS := 11
var quit_armed := false
var wardrobe_from: StringName = &"title"   # 14.2: where the WARDROBE page goes back to
var wardrobe_i := 0
var opt_from: StringName = &"title"
var codex_i := 0
var codex_tab := 0   # 22.3: 0 relics, 1 the bestiary, 2 past runs, 3 the trait book (30.2)
var traitbook_i := 0   # 30.2: the trait chosen in the trait book
var traitlist_i := 0   # 41.3: the cube chosen on the pause menu's TRAITS page (trait_page.gd)
var tome: Dictionary = {}   # 41.5: the trait tome being read (trait_rules.gd)
var tome_i := 0   # 41.5: the trait chosen to give up for it
var bestiary_i := 0
var inv_i := 0                 # Rogues layer: inventory cursor (0-5 backpack, 6-9 belt)
var shrine_i := 0
var tree_hero := 0
var tree_b := 0
var tree_n := 0
var tree_from: StringName = &""
var embers: Array = []         # title-screen ember motes
var _wave_delay := 0.0
var _give_food: Array = []     # --give=food:... (debug pictures)
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
	if hero.has("pack") and GameData.rogues():   # 34.1: a hero who starts with something in the backpack
		player.backpack.append(Weapons.by_id(hero["pack"]))
	if DebugArgs.has("weapon"):
		Weapons.equip_weapon(player, Weapons.by_id(DebugArgs.get_str("weapon")))
	run_stats = { "kills": 0, "gold": 0, "time": 0.0, "floor": 1, "bosses": 0, "secrets": 0, "rifts": [] }
	if (endless_next or DebugArgs.has("endless")) and GameData.rogues():
		Endless.setup()   # 22.2
	endless_next = false   # (taken: a later run from anywhere else is an ordinary one)
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
		for ni in mini(owned[bi], tree[bi]["nodes"].size()):   # (48.3: classic has only the first four)
			Traits.apply_node(tree[bi]["nodes"][ni][0], p)
	Attributes.start(p)
	Alignments.start(p)   # 38.1: some heroes start GOOD, EVIL, LAWFUL or CHAOTIC
	# Step 6 heroes: a passive (effect-system data) and a starting trait.
	if hero.has("effects") and (hero.get("new", false) or GameData.rogues()):   # 20.1: the originals' passives are expanded-only
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
	Trophies.apply(p, hero["id"])   # 7.2: a potion, a relic, a rare relic for 5 / 10 / 20 trophies
	CampLife.on_new_run(p)   # 19.2: the camp's meal, song and parcel
	Dice.start(p)   # 35.1: an ALTER and a BANISH die (the 2 REROLL dice were always there)
	Gourd.start(p)   # 47.1: THE GOURD, full
	Dread.on_new_run(p)   # 48.1 FLAWED STEEL
	Block.reset()   # 37.1
	Might.reset()   # 40.2
	Finesse.reset()   # 41.1
	Arcana.reset()   # 42.1
	Marvels.reset()   # 43.1
	if GameData.rogues() and not DebugArgs.has("no-oath"):   # 29 (his word, 9 Oct): every run opens with an OATH that shapes it
		p.oath_picks = 1
		p.pending += 1
	run_stats["power0"] = Combat.power(p)   # the yardstick of Combat.power_scale
	_debug_give(p)
	Meta.meta["runs"] += 1
	Meta.write_save()
	start_floor()

## Playtesting: --give=relic:id,gear:id,trait:id,weapon:id (and belt:, pack:, charm:, drink:,
## infuse:, ench:, food:) and --combo=ID
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
		if parts.size() == 2 and parts[0] == "charm" and Charms.has(parts[1]):
			if not Charms.wear(p, Charms.by_id(parts[1])):
				p.backpack.append(Charms.by_id(parts[1]))   # 37.2 (slots full: the backpack)
			continue
		if parts.size() == 2 and parts[0] == "drink" and Food.DRINKS.has(parts[1]):
			Food.drink(p, parts[1])   # 36.3: a drink's buff (pictures)
			continue
		if parts.size() == 2 and parts[0] == "infuse" and Infusions.is_kind(parts[1]):
			Infusions.infuse(p, parts[1])   # 44: an infusion on the weapon (pictures)
			continue
		if parts.size() == 2 and parts[0] == "ench" and Enchant.KINDS.has(parts[1]):
			Enchant.give(p, parts[1])   # 46: an enchantment on the weapon (pictures)
			continue
		if parts.size() == 2 and parts[0] == "food" and Food.is_kind(parts[1]):
			_give_food.append(parts[1])   # 36: food on the first room's floor (pictures; start_floor)
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
	if GameData.rogues() and GameData.ALT_GUARDIANS.has(floor_index) and randf() < 0.5:
		floor_d["guardian"] = GameData.ALT_GUARDIANS[floor_index]   # 9.3: half the time, the floor's second guardian
	Saloon.on_floor_start()
	EventRooms.on_floor_start()
	Wanderers.on_floor_start()
	Weather.on_floor_start()   # 22.1 this floor's weather (own dice)
	if Endless.on():
		Endless.on_floor()   # 22.2 the depth, and the record
	run_stats["floor"] = floor_index + 1
	Meta.meta["best"] = maxi(Meta.meta["best"], floor_index + 1)
	Meta.write_save()
	Snd.music(GameData.floor_music(floor_index))
	room = null
	if FloorMap.wanted():
		FloorMap.generate(floor_d, player)
		Dread.on_floor_map(floor_d)   # 48.1 BLOOD TOLL
		floor_d["map"]["cells"][floor_d["map"]["start"]]["visited"] = true
		enter_room(FloorMap.room_at(floor_d["map"]["start"], ""))
	else:
		enter_room(World.make_room(floor_d, "start", "", ""))
	Effects.fire("on_floor_start")
	Marvels.on_floor(player)   # 43.1 SAINT AND SINNER
	AlignShops.on_floor(player)   # 45.1 DAWN BUCKLER
	for i in _give_food.size():   # (--give=food:..., pictures)
		var k := Combat.drop_pickup(_give_food[i], 5.0 * TB.TS + i * 24.0, 6.0 * TB.TS)
		k.vx = 0.0
		k.vy = 0.0
	_give_food.clear()
	state = &"play"
	Barks.hero("floor", true)   # 21.1: a word on arriving
	RunSave.save()   # 6.3: the run can be continued from here
	show_banner(GameData.floors()[floor_index]["name"], Endless.banner_sub() if Endless.on() else
		"FLOOR %d OF %d" % [floor_index + 1, GameData.floors().size()]
		+ ("   DREAD %d" % dread if dread > 0 else "") + ("   LOOP %d" % (loop + 1) if loop > 0 else ""))
	if GameData.rogues() and floor_index == 6:
		toast("HITS NOW COST A WHOLE HEART", "red")   # past the Pale Regent (Combat.foe_hit)

const ENTRY_SPOTS := { "s": Vector2(14.0 * 16, 16.0 * 16), "n": Vector2(14.0 * 16, 2.6 * 16),
	"e": Vector2(26.0 * 16 - 2, 9.5 * 16), "w": Vector2(2.0 * 16 + 2, 9.5 * 16) }

func enter_room(r: Room) -> void:
	room = r
	Barks.reset()   # 21.1
	EventRooms.on_enter_room()
	Fx.clear()
	Juice.reset()
	EBullets.clear()
	RiftBosses.clear()
	Chaos.clear()
	Arsenal.clear()
	Flail.clear()
	Charged.clear()
	Summons.clear()
	Oddities.clear()
	Spells.clear()
	Toys.clear()   # 31
	Auras.reset()   # 33.1
	Lucky.reset()   # 34.1
	Reactions.clear()
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
	Pace.on_enter()   # 35.2
	if GameData.rogues():
		Food.on_room(p)   # 36.3: the drink buffs have a room less
		Infusions.on_room(p)   # 44: and the saps
		Gourd.on_room(p, room)   # 47.1: the rest stop fills the gourd
	match "" if room.cleared else room.type:   # a cleared room on the floor map stays cleared
		"combat", "elite":
			locked = true
			room.waves_left = (2 if room.type == "elite" else 1) + (1 if randf() < 0.25 + 0.08 * floor_index else 0)
			if GameData.rogues():
				_roll_twist()
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
	if room.type == "barn":
		Rex.on_enter(room)   # Rex asleep on his mat
	if rex_call and GameData.rogues() and room.on_map and room.type != "boss" and Rex.add_door(room):
		rex_call = false     # the title's secret: a door to his barn from this room
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
	if room.type == "shop":
		Barks.hero("shop")   # 21.1
	Ambience.on_room()   # 21.3 the sound of this place
	Wanderers.on_enter_room(room)   # 21.4 the traveller comes along; a rival you helped comes back

func open_exits() -> void:
	if room.exits_open or room.type == "camp":
		return   # 17.2: the camp's way out is its portal
	if room.rift_step == 3 and room.theme.get("realm", false):
		return   # a realm's ruler: the way on is the page portal, or the end (_realm_won)
	room.exits_open = true
	if room.type == "boss" and room.rift_step < 3:
		return
	if not room.theme.is_empty() and room.rift_step < 2:
		# Inside a rift there is one way on: deeper, and then to its champion.
		World.assign_exits(room, [{ "type": "rift", "reward": "rare" if room.rift_step == 0 else "", "theme": room.theme["id"],
			"step": 3 if (room.theme.get("realm", false) or room.theme.get("short", false)) and room.rift_step == 1 else room.rift_step + 1 }])
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
	if c["type"] != "secret" and c["type"] != "barn" and not inner:
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
		opts = { "event": TB.pick(mystery_events()) }
		if randf() < 0.18:
			opts["event"] = TB.pick(EventRooms.specials())   # a special room: rarer than an event
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
	if room.on_map:   # 48.1 BLOOD TOLL: a heart at the door, or it stays shut
		var tc: Dictionary = FloorMap.cells().get(room.cell + World.DIRS[dir], {})
		if not tc.is_empty() and not Dread.pay_toll(player, tc):
			player.x = clampf(player.x, TB.TS * 2.0, TB.SW - TB.TS * 2.0)
			player.y = clampf(player.y, TB.TS * 2.4, TB.SH - TB.TS * 2.0)
			return
	var nr := FloorMap.step(dir)
	start_fade(func(): enter_room(nr))

## 29 (his word, 9 Oct: "there are still some empty hidden rooms"): what a hidden room of the
## expanded game holds. A third an event (with a little loot beside it, so the room is not bare
## once it is done); a relic on a pedestal, or a free iron chest when no relic is left to give
## (an empty pedestal was the empty room); the cursed chest; embers and gems by an iron chest; THE
## GOLDEN GRIMOIRE (one of three rare traits); or A DRAGON'S HOARD.
func _fill_secret(r: Room, cx: float, cy: float, roll: float) -> void:
	if roll < 0.34:
		_setup_event(r, TB.pick(SECRET_EVENTS))
		for i in 5:
			r.pickups.append(_room_pickup("coin", cx + TB.rint(-80, 80), cy + TB.rint(34, 46)))
		r.pickups.append(_room_pickup("gem", cx + 64, cy + 40))
	elif roll < 0.48:
		var rel := roll_relics(1, "secret", r)
		if rel.is_empty():
			r.objects.append({ "kind": "ichest", "x": cx, "y": cy, "free": true })
		else:
			r.objects.append({ "kind": "pedestal", "relic": rel[0], "x": cx, "y": cy })
		for i in 3:
			r.pickups.append(_room_pickup("gem", cx - 24 + i * 24, cy + 30))
	elif roll < 0.60:
		r.objects.append({ "kind": "cchest", "x": cx, "y": cy })
		for i in 6:
			r.pickups.append(_room_pickup("coin", cx + TB.rint(-50, 50), cy + TB.rint(20, 40)))
		r.pickups.append(_room_pickup("ember", cx, cy - 30))
	elif roll < 0.72:
		for i in 3:
			r.pickups.append(_room_pickup("ember", cx - 20 + i * 20, cy))
		for i in 3:
			r.pickups.append(_room_pickup("gem", cx - 20 + i * 20, cy + 20))
		r.objects.append({ "kind": "ichest", "x": cx, "y": cy - 30, "free": true })
	elif roll < 0.86:
		r.objects.append({ "kind": "grimoire", "x": cx, "y": cy })
		for i in 4:
			r.pickups.append(_room_pickup("coin", cx + TB.rint(-60, 60), cy + TB.rint(26, 40)))
		show_banner("A FORGOTTEN STUDY", "A GOLDEN GRIMOIRE LIES OPEN")
	else:
		r.objects.append({ "kind": "chest", "x": cx - 44, "y": cy })
		r.objects.append({ "kind": "ichest", "x": cx + 44, "y": cy, "free": true })
		for i in 16:
			r.pickups.append(_room_pickup("coin", cx + TB.rint(-90, 90), cy + TB.rint(-20, 44)))
		for i in 3:
			r.pickups.append(_room_pickup("gem", cx - 24 + i * 24, cy + 30))
		for i in 2:
			r.pickups.append(_room_pickup("ember", cx - 10 + i * 20, cy - 26))
		show_banner("A DRAGON'S HOARD", "THE DRAGON IS OUT. TAKE WHAT YOU CAN CARRY")
	if randf() < 0.5:   # 35.1: a die left behind
		r.pickups.append(_room_pickup("die_" + Dice.roll_kind(), cx + 30, cy - 22))
	if randf() < 0.3:   # 36.2: golden food
		r.pickups.append(_room_pickup(Food.roll_golden(), cx - 30, cy - 22))

## Events of a MYSTERY room, and the ones a hidden room may hold instead of its old three finds.
const MYSTERY_EVENTS := ["wheel", "market", "mimic", "armory", "well", "goblin", "mirror", "library", "safehouse", "saloon",
	"pit", "chopshop", "fortune", "courier", "gallery"]
const SECRET_EVENTS := ["market", "armory", "goblin", "mirror", "library"]

## The mystery rooms' events; 10.2 adds five more in the expanded game (event_rooms.gd).
func mystery_events() -> Array:
	return MYSTERY_EVENTS + EventRooms.EVENTS_10 if GameData.rogues() else MYSTERY_EVENTS

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
			if rel.is_empty() and GameData.rogues():   # 29: nothing left to sell: the stall's own strongbox
				r.objects.append({ "kind": "ichest", "x": cx, "y": cy + 6, "free": true })
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
			TraitRules.place_tome(r, cx + 56, cy)   # 41.5: a trait tome beside it
		"safehouse":
			r.objects.append({ "kind": "bed", "x": cx - 34, "y": cy })
			r.objects.append({ "kind": "jukebox", "x": cx + 34, "y": cy })
		"goblin":
			# the goblin itself appears when the room is entered; what he dropped while fleeing stays
			if GameData.rogues():   # his ask (6 Oct): no hidden room that feels empty
				for i in 8:
					r.pickups.append(_room_pickup("coin", cx + TB.rint(-60, 60), cy + TB.rint(-30, 40)))
				r.pickups.append(_room_pickup("gem", cx, cy + 30))
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
			if rel.is_empty() and GameData.rogues():   # 29: no relic left to give: an iron chest, never an empty pedestal
				room.objects.append({ "kind": "ichest", "x": cx, "y": cy + 26, "free": true })
			else:
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
			Story.hide_page(r, cx, cy)   # 12.3: Chapter II's torn pages
			var roll := randf()
			if GameData.rogues():
				_fill_secret(r, cx, cy, roll)   # 29: never an empty one
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
		"camp":
			Camp.setup(r)   # 17.2
		"barn":
			Rex.setup_objects(r)
		"rest":
			r.objects.append({ "kind": "campfire", "x": cx, "y": cy })
			if GameData.rogues():
				r.objects.append({ "kind": "anvil", "x": cx + 56, "y": cy })
				Alignments.shrines(r, cx, cy)   # 8.1: take one alignment point
				Story.place(r, cx, cy)   # 12.1: the Archivist by the fire
				Story.bind_shop(r, cx, cy)   # 12.2: the Bookbinder, in Chapter II
				if randf() < 0.45:
					Fishing.place(r, cx - 140, cy + 16, 32.0, 15.0)   # 15.1: a pond
	# Pets (expanded game only): a cage in some treasure rooms, vaults and hidden rooms, one for sale in some shops.
	if GameData.rogues():
		var chance: float = { "treasure": 0.12, "vault": 0.35, "secret": 0.2, "shop": 0.25 }.get(r.type, 0.0)
		if chance > 0 and (r.type != "secret" or r.event == "") and randf() < chance:
			var at: Vector2 = { "treasure": Vector2(cx + 100, cy + 10), "vault": Vector2(cx + 84, cy),
				"secret": Vector2(cx + 76, cy - 6), "shop": Vector2(cx, cy + 44) }[r.type]
			r.objects.append(Pets.cage(player, at.x, at.y, "gold" if r.type == "shop" else "key"))
	# 16: pots along the walls (shoot or roll into them), coin heaps in the hoard.
	if GameData.rogues():
		RoomDress.furnish(r)
	# Rogues layer: a loose brick in the wall of some quiet rooms opens a hidden door.
	if GameData.rogues() and r.type in ["treasure", "shrine", "rest", "shop"] and randf() < 0.2:
		r.objects.append({ "kind": "brick", "x": (2.0 if randf() < 0.5 else 26.0) * TB.TS, "y": 5.0 * TB.TS })
	if GameData.rogues() and r.type == "treasure" and randf() < 0.25:
		Fishing.place(r, cx - 130, cy + 62, 30.0, 14.0)   # 15.1: a pond
	# 05b_items.rb: weapons and gear in shops and treasure rooms.
	match r.type:
		"shop":
			var w := Weapons.random_weapon(Gear.roll_item_rarity(f), player.weapon)
			var g := Gear.random_gear(Gear.roll_item_rarity(f))
			r.objects.append({ "kind": "shop", "item": "weapon", "thing": w, "x": cx - 40, "y": cy + 34, "price": item_price(w) })
			r.objects.append({ "kind": "shop", "item": "gear", "thing": g, "x": cx + 40, "y": cy + 34, "price": item_price(g) })
			if GameData.rogues():
				var sp = Gear.chase_piece(player)   # 13.2: a piece of the set you are building
				if sp != null and sp["id"] != g["id"]:
					r.objects.append({ "kind": "shop", "item": "gear", "thing": sp, "x": cx, "y": cy + 34, "price": item_price(sp) })
				r.objects.append({ "kind": "anvil", "x": cx + 104, "y": cy + 34 })
				Dice.stock_shop(r, cx, cy)   # 35.1: a die for sale and the DICE CUP
				Charms.stock_shop(r, cx, cy)   # 37.2: a charm for sale
				Food.stock_shop(r, cx, cy)   # 36.1: a food for sale
				Infusions.stock_shop(r, cx, cy)   # 44: an infusion for sale
				Enchant.stock_shop(r, cx, cy)   # 46.1: THE ENCHANTER
				TraitRules.place_tome(r, cx - 144, cy + 34, price(28 + f * 4))   # 41.5: a trait tome for sale
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

## Longer fights with more to them (his ask, 6 Oct: "make rooms last longer and add more variety").
## Expanded game: one wave more in every fight, and one room in three has a twist, named on entry.
const TWISTS := { "swarm": ["SWARM", "THEY KEEP COMING"], "hunters": ["HUNTERS", "THE STRONG ONES CAME"],
	"strangers": ["STRANGERS", "FOES FROM DEEPER DOWN"], "ambush": ["AMBUSH", "ONE MORE WAVE"] }
func _roll_twist() -> void:
	room.waves_left += 1
	room.twist = ""
	if not room.theme.is_empty() and room.theme.get("short", false):
		return   # Heaven, Hell, Brazil: their own fights
	if randf() < 0.34:
		room.twist = TB.pick(TWISTS.keys())
		if room.twist == "ambush":
			room.waves_left += 1
		show_banner(TWISTS[room.twist][0], TWISTS[room.twist][1])

func spawn_wave(hard: bool = false) -> void:
	var fdef: Dictionary = GameData.floors()[floor_index]
	var n := TB.rint(3, 4) + mini(floor_index, 4) + (1 if room.depth > 3 else 0)
	var ec := (0.05 if floor_index == 0 else 0.08 + floor_index * 0.035) + (0.08 if dread >= 3 else 0.0) + (0.35 if hard else 0.0)
	if Daily.is_on("elite"):
		ec = maxf(ec, 0.5)   # 18.1 ELITE HOUR
	Brazil.maybe_spawn(room, floor_index)
	if GameData.rogues():
		# The expanded game is a little harder (ROADMAP 4.7): from the third floor one more foe a
		# wave, and 3% more elites. --classic keeps the original numbers.
		n += (1 if floor_index >= 2 else 0) + 1   # cranked up (6 Oct): one more foe a wave from the first floor
		ec += 0.08
		match room.twist:
			"swarm": n += n / 2
			"hunters": ec = minf(0.9, ec * 3.0)
	if room.type == "elite":
		ec += 0.45
	# Stage 7: the elite room before the rest stop holds the floor's mini-boss.
	ec += (0.12 if GameData.rogues() else 0.06) * loop   # loop playthroughs: more elites
	if GameData.rogues():
		ec += 0.04   # 11.3 (his ask, 6 Oct: "a little bit harder")
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
	n = Dread.pack(n)   # 48.1 PACKED HALLS
	var deeper: Array = GameData.floors()[mini(floor_index + 1, GameData.floors().size() - 1)]["pool"]
	var n0 := enemies.size()
	for i in n:
		var type: String = TB.pick(pool)
		if room.twist == "strangers" and room.theme.is_empty() and i % 2 == 0:
			type = TB.pick(deeper)   # STRANGERS: half the wave from the next floor down
		var s := World.free_spot(room, player, 90, World.M_FLYER if GameData.ENEMIES[type].get("fly", false) else World.M_WALKER)
		Combat.spawn_enemy(type, s.x, s.y, randf() < ec)
	Lives.on_wave(enemies.slice(n0), not _spawned)   # 21.5: some of the first wave are asleep
	Dread.maybe_plague(enemies.slice(n0))   # 48.1 PLAGUE
	Dread.maybe_hunter(not _spawned)   # 48.1 THE HUNTER
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
		"food", "golden":
			Food.reward(kind, cx, cy)   # 36.1 / 36.2

func room_cleared() -> void:
	locked = false
	room.cleared = true
	if room.type in ["combat", "elite"]:
		StatDrops.maybe(0.25, 14.0 * TB.TS, 9.0 * TB.TS)   # 8.3: the middle of the room
		Dice.maybe(0.06, 14.0 * TB.TS, 9.5 * TB.TS)   # 35.1
		Loot.treasure(14.0 * TB.TS + 30, 9.5 * TB.TS)   # 38.2 TREASURE FIND
		AlignShops.on_room_clear(player)   # 45.1 LAMP OF MERCY
	Saloon.on_room_clear(room)
	EventRooms.on_room_clear(room)
	Wanderers.on_room_clear(room)   # 21.4 a ghost, a rival, a lost traveller
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
	Pace.on_clear(room)   # 35.2 CLEAR RUSH and the FIRST SPOILS
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
	Barks.hero("boss", true)   # 21.1
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
	Gourd.fill(p)   # 47.1: a guardian's fall fills the gourd
	if p.oath:
		p.max_hp += 2
		p.hp += 2
	Snd.music(GameData.floor_music(floor_index))
	show_banner(b.d["name"] + " FALLS", "")
	if Trophies.take(GameData.heroes()[hero_index]["id"], b.boss):   # 7.2
		toast("NEW TROPHY: " + b.d["name"], "gold")
	if room.theme.is_empty() and floor_index in [5, 10]:
		Story.reach("f6" if floor_index == 5 else "f11")   # 12.1: the story grows
	for i in 12:
		Combat.drop_pickup("coin", b.x, b.y)
	Combat.drop_pickup("heart", b.x, b.y)
	Combat.drop_pickup("ember", b.x, b.y)
	for i in 2:
		StatDrops.maybe(1.0, b.x, b.y)   # 8.3: a guardian leaves two stat pickups
		Dice.maybe(1.0, b.x, b.y)   # 35.1: and two dice
	RiftBosses.clear()
	Chaos.clear()
	if GameData.rogues() and room.type != "barn":
		_boss_reward(b)
		Alignments.wayshrine(room)   # 38.1: buy an alignment
		AlignShops.place(room)   # 45.1: perhaps a GOOD, EVIL or LAWFUL shop
	BossLoot.drop(b)   # its own item (expanded game)
	if Daily.is_on("giants"):
		for rel in roll_relics(2, "boss"):   # 18.1 BIG GAME
			add_relic(player, rel)
	if Endless.on() and room.type != "barn" and room.rift_step != 3:
		Endless.guardian_down(b)   # 22.2: its hoard and the stair down; no endings
		return
	if room.type == "barn":
		Rex.on_beaten(b)   # a good boy rolls over: his hoard, and he offers to come along
		return
	if room.rift_step == 3 and room.theme.get("realm", false):
		_realm_won(b)
		return
	if room.rift_step == 3:
		# A rift guardian: its hoard, and the way back to the floor (no portal: the floor goes on).
		show_banner(b.d["name"] + " FALLS", "ITS HOARD IS YOURS. THE WAY BACK IS OPEN")
		if b.boss == "holycow":
			drop_item(Weapons.by_id("cowmilker"), b.x, b.y + 30)   # (brazil.gd)
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
	if last and run_stats.get("chapter", 1) == 2:
		_chapter_won(b)   # 12.2: the Author falls
		return
	if last and run_stats.get("chapter", 1) == 3:
		_chapter3_won(b)   # 14.4: the Reader falls
		return
	if last and run_stats.get("chapter", 1) == 4:
		_chapter4_won(b)   # 20.3: the Critic falls
		return
	if floor_index == GameData.THRONE_FLOOR and not last and not run_stats.get("throne", false):
		throne_victory()
	room.objects.append({ "kind": "chest", "x": 14.0 * TB.TS - (0 if last else 28), "y": 10.0 * TB.TS, "boss": true })
	if last and GameData.floors().size() > GameData.FLOORS.size():
		# The true ending: loop again with your build, or leave in victory.
		show_banner("THE ECLIPSE ENDS", "LOOP, LEAVE, OR FOLLOW YOUR SOUL THROUGH THE GATE")
		room.objects.append({ "kind": "loopportal", "x": 14.0 * TB.TS - 56, "y": 10.0 * TB.TS })
		room.objects.append({ "kind": "exitportal", "x": 14.0 * TB.TS + 56, "y": 10.0 * TB.TS })
		# Heaven or Hell (ROADMAP 4.7 part C): where your soul leans.
		var w := Soul.weigh(player)
		room.objects.append({ "kind": "soulgate", "x": 14.0 * TB.TS, "y": 6.0 * TB.TS, "realm": Soul.realm(player),
			"light": w[0], "dark": w[1] })
	elif last:
		win_timer = 4.5
	else:
		room.objects.append({ "kind": "portal", "x": 14.0 * TB.TS + 28, "y": 10.0 * TB.TS })
	# 05b_items.rb: guardians drop a weapon and sometimes gear.
	drop_item(Weapons.random_weapon(Gear.roll_item_rarity(floor_index, "boss"), player.weapon), b.x - 20, b.y + 20)
	if randf() < 0.5:
		drop_item(Gear.random_gear(Gear.roll_item_rarity(floor_index, "boss")), b.x + 20, b.y + 20)

## A guardian falls (his ask, 6 Oct: "a rewarding feeling"; expanded game): a slow-motion finish
## and a flash, a fountain of loot, half your health back, and if it never touched you, FLAWLESS:
## a second chest.
func _boss_reward(b: Enemy) -> void:
	hitstop = 0.5
	Juice.flash(0.35)
	add_shake(12)
	Snd.play("unlock")
	Juice.label("GUARDIAN FELLED!", "#f2c94c", b.x, b.y - 34, true)
	Fx.burst(b.x, b.y, ["#f2c94c", "#fffbe0", "#e8873a", "#f4ecd8"], 60, 170, 0.9, 3)
	for i in 15:
		Combat.drop_pickup("coin", b.x, b.y)
	for i in 4:
		Combat.drop_pickup("gem", b.x, b.y)
	for i in 2:
		Combat.drop_pickup("ember", b.x, b.y)
	player.heal(maxi(2, player.max_hp / 2))
	run_stats["felled"] = run_stats.get("felled", 0) + 1
	if room.hits == 0:
		run_stats["flawless"] = run_stats.get("flawless", 0) + 1
		Juice.label("FLAWLESS!", "#6fd3e0", b.x, b.y - 48, true)
		room.objects.append({ "kind": "chest", "x": 14.0 * TB.TS + 56, "y": 12.0 * TB.TS, "boss": true })
		for i in 3:
			Combat.drop_pickup("gem", b.x, b.y)

## 12.2: the page turns. Chapter II's three floors join the list (GameData.floors) and the run goes on
## with everything the hero carries.
func begin_chapter2() -> void:
	run_stats["chapter"] = 2
	Story.reach("ch2")
	floor_index = GameData.FLOORS.size() + GameData.NEW_FLOORS.size()
	start_floor()
	toast("CHAPTER II: THE MARGINS", "gold")

## 14.4: read on. Chapter III's three floors join the list (after Chapter II's).
func begin_chapter3() -> void:
	run_stats["chapter"] = 3
	Story.reach("ch3")
	floor_index = GameData.FLOORS.size() + GameData.NEW_FLOORS.size() + GameData.CHAPTER2.size()
	start_floor()
	toast("CHAPTER III: THE APPENDIX", "gold")

## 14.4: the Reader falls: the last page is turned, by you. 20.3: close the book there (the run is
## won), or step out of it onto the shelf: CHAPTER IV (STORY.md).
func _chapter3_won(b: Enemy) -> void:
	run_stats["reader"] = true
	Story.reach("reader")
	Meta.meta["reader_wins"] = Meta.meta.get("reader_wins", 0) + 1
	room.objects.append({ "kind": "chest", "x": 14.0 * TB.TS - 28, "y": 10.0 * TB.TS, "boss": true })
	room.objects.append({ "kind": "chest", "x": 14.0 * TB.TS + 28, "y": 10.0 * TB.TS, "boss": true })
	show_banner("THE READER CLOSES THE BOOK", "THE END. OR STEP OUT ONTO THE SHELF")
	room.objects.append({ "kind": "n_endbook", "x": 14.0 * TB.TS - 52, "y": 10.0 * TB.TS + 30 })
	room.objects.append({ "kind": "n_shelf", "x": 14.0 * TB.TS + 52, "y": 10.0 * TB.TS + 30 })

## 20.3: out of the book, onto the shelf. Chapter IV's three floors join the list (after Chapter III's).
func begin_chapter4() -> void:
	run_stats["chapter"] = 4
	Story.reach("ch4")
	floor_index = GameData.FLOORS.size() + GameData.NEW_FLOORS.size() + GameData.CHAPTER2.size() + GameData.CHAPTER3.size()
	start_floor()
	toast("CHAPTER IV: THE LIBRARY", "gold")

## 20.3: the Critic falls silent: the book is kept, on the shelf, for good. The run is won.
func _chapter4_won(b: Enemy) -> void:
	run_stats["critic"] = true
	Story.reach("critic")
	Meta.meta["critic_wins"] = Meta.meta.get("critic_wins", 0) + 1
	for dx in [-48.0, 0.0, 48.0]:
		room.objects.append({ "kind": "chest", "x": 14.0 * TB.TS + dx, "y": 10.0 * TB.TS, "boss": true })
	show_banner("THE CRITIC FALLS SILENT", "THE BOOK IS KEPT. ON THE SHELF, FOR GOOD")
	win_timer = 8.0

## 12.2: the Author falls: the book stays open and the run is won (12.3 adds what is hidden).
func _chapter_won(b: Enemy) -> void:
	run_stats["author"] = true
	Story.reach("author")
	Meta.meta["author_wins"] = Meta.meta.get("author_wins", 0) + 1
	room.objects.append({ "kind": "chest", "x": 14.0 * TB.TS, "y": 10.0 * TB.TS, "boss": true })
	if run_stats.get("pages", 0) >= 3:
		# 12.3: the three torn pages burn, and a door is cut into the page: THE REDACTOR (STORY.md).
		show_banner("THE TORN PAGES BURN", "A DOOR IS CUT INTO THE PAGE. OR CLOSE THE BOOK")
		room.objects.append({ "kind": "n_endbook", "x": 14.0 * TB.TS - 52, "y": 10.0 * TB.TS + 30 })
		room.objects.append({ "kind": "n_redactdoor", "x": 14.0 * TB.TS + 52, "y": 10.0 * TB.TS + 30 })
		return
	show_banner("THE AUTHOR FALLS", "THE BOOK STAYS OPEN. THE STORY IS YOURS")
	win_timer = 6.0

## Heaven and Hell (ROADMAP 4.7 part C): a realm's ruler falls and the way to the Unwritten Page
## opens; the Unwritten falls and the run is won, the last ending of all.
func _realm_won(b: Enemy) -> void:
	var id: String = room.theme["id"]
	Story.reach("unwritten" if id == "seam" else "realm")   # 12.1
	if id == "redaction":
		# 12.3: the hidden one falls; the last word of the book is yours.
		run_stats["redactor"] = true
		Story.reach("redactor")
		Meta.meta["redactor_wins"] = Meta.meta.get("redactor_wins", 0) + 1
		room.objects.append({ "kind": "chest", "x": 14.0 * TB.TS, "y": 10.0 * TB.TS, "boss": true })
		# 14.4: close the book here, or read on into the appendix: CHAPTER III (STORY.md).
		show_banner("THE REDACTOR IS ERASED", "CLOSE THE BOOK, OR READ ON")
		room.objects.append({ "kind": "n_endbook", "x": 14.0 * TB.TS - 52, "y": 10.0 * TB.TS + 30 })
		room.objects.append({ "kind": "n_readon", "x": 14.0 * TB.TS + 52, "y": 10.0 * TB.TS + 30 })
		return
	if id == "seam":
		run_stats["unwritten"] = true
		Meta.meta["unwritten_wins"] = Meta.meta.get("unwritten_wins", 0) + 1
		if GameData.rogues():
			# 12.2: end the story here, or turn the page into Chapter II (STORY.md).
			show_banner("THE UNWRITTEN FALLS", "END THE STORY HERE, OR TURN THE PAGE")
			room.objects.append({ "kind": "n_endbook", "x": 14.0 * TB.TS - 52, "y": 10.0 * TB.TS })
			room.objects.append({ "kind": "n_turnpage", "x": 14.0 * TB.TS + 52, "y": 10.0 * TB.TS })
			return
		show_banner("THE UNWRITTEN FALLS", "THE PAGE IS YOURS. WRITE WHAT COMES NEXT")
		win_timer = 5.0
		return
	run_stats["realm"] = id
	Meta.meta[id + "_wins"] = Meta.meta.get(id + "_wins", 0) + 1
	if GameData.rogues() and id in ["heaven", "hell"]:   # 8.1: the realm leaves its mark
		Alignments.add(player, "good" if id == "heaven" else "evil", 2)
	show_banner(b.d["name"] + " FALLS", "A BLANK PAGE OPENS WHERE IT STOOD")
	room.objects.append({ "kind": "chest", "x": 14.0 * TB.TS - 28, "y": 10.0 * TB.TS, "boss": true })
	room.objects.append({ "kind": "pageportal", "x": 14.0 * TB.TS + 28, "y": 10.0 * TB.TS })
	drop_item(Weapons.random_weapon(Gear.roll_item_rarity(floor_index, "boss"), player.weapon), b.x - 20, b.y + 20)
	drop_item(Gear.random_gear(Gear.roll_item_rarity(floor_index, "boss")), b.x + 20, b.y + 20)
	for i in 4:
		Combat.drop_pickup("gem", b.x, b.y)

func _enter_realm(id: String, step: int) -> void:
	var nr := World.make_room(floor_d, "boss" if step == 3 else "combat", "", "s", { "theme": id, "step": step })
	start_fade(func():
		player.heal(4)
		enter_room(nr))

func award_embers(win: bool) -> void:
	RunSave.clear()   # the run is over (6.3)
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
	if run_stats.get("realm", "") != "":
		parts.append(["HEAVEN" if run_stats["realm"] == "heaven" else "HELL", 100])
	if run_stats.get("unwritten", false):
		parts.append(["THE UNWRITTEN", 200])
	if run_stats.get("author", false):
		parts.append(["CHAPTER II", 300])   # 12.2
	if run_stats.get("redactor", false):
		parts.append(["THE REDACTOR", 500])   # 12.3
	if run_stats.get("reader", false):
		parts.append(["CHAPTER III", 600])   # 14.4
	if run_stats.get("critic", false):
		parts.append(["CHAPTER IV", 700])   # 20.3
	if run_stats.get("trophies", 0) > 0:
		parts.append(["NEW TROPHIES", run_stats["trophies"] * Trophies.EMBERS])
	if Endless.on():
		Endless.score(parts)   # 22.2: the depth is the score
	Daily.on_end(win, parts)   # 18.1
	Barks.remember(win)   # 21.1: the camp remembers how it ended
	Quests.on_run_end(win, parts)   # 20.2
	CampBuild.on_run_end()
	var base := 0
	for x in parts:
		base += x[1]
	var mult := 1 + 0.25 * dread
	var total := roundi(base * mult)
	Meta.meta["embers"] += total
	Meta.meta["kills"] += r["kills"]
	award = { "parts": parts, "mult": mult, "total": total }
	if GameData.rogues():   # 48.2 STAR DUST: star points for the constellation
		var dust := Stars.dust_for(win)
		Meta.meta["dust"] = int(Meta.meta.get("dust", 0)) + dust
		award["dust"] = dust
	Bestiary.log_run(win, total)   # 22.3 past runs
	Meta.write_save()

func on_death(source: String) -> void:
	death_by = source if source != "" else "the crypt"
	state = &"dead"
	state_t = 0.0
	Wanderers.on_death(player)   # 21.4: the next run may meet this hero's ghost
	award_embers(false)
	Snd.play("die")
	Snd.music(0)
	Ambience.stop()

## Stage 7: the Pale Regent falls with the new floors ahead. This is still the
## original game's victory (wins and dread unlock are granted now), and the
## run goes on through the rift into the new biomes.
func throne_victory() -> void:
	run_stats["throne"] = true
	Meta.meta["wins"] += 1
	Meta.meta["dread_max"] = mini(maxi(Meta.meta.get("dread_max", 0), dread + 1), Dread.cap())   # (48.1: up to 16)
	Meta.write_save()
	Snd.play("win")
	show_banner("VICTORY! THE THRONE IS BROKEN", "A RIFT OPENS ONTO DARKER LANDS")

func on_win() -> void:
	if not run_stats.get("throne", false):
		Meta.meta["wins"] += 1
		Meta.meta["dread_max"] = mini(maxi(Meta.meta.get("dread_max", 0), dread + 1), Dread.cap())
	else:
		Meta.meta["eclipse_wins"] = Meta.meta.get("eclipse_wins", 0) + 1
	award_embers(true)
	state = &"win"
	state_t = 0.0
	Snd.play("win")
	Snd.music(0)
	Ambience.stop()

func deny(o: Dictionary, text: String) -> void:
	Snd.play("deny")
	Fx.float_text(o["x"], o["y"] - 18, text, "red")

## Room object interaction (Game.rb interact). Stage 4 handles the portal so
## floors can be completed; chests, shops and shrines arrive with items.
func interact(o: Dictionary) -> void:
	if Saloon.handles(o["kind"]):
		return Saloon.interact(o)
	if Enchant.handles(o["kind"]):
		return Enchant.interact(o)   # 46.1
	if EventRooms.handles(o["kind"]):
		return EventRooms.interact(o)
	if Wanderers.handles(o["kind"]):
		return Wanderers.interact(o)
	if RiftExtras.handles(o["kind"]):
		return RiftExtras.interact(o)
	if Pets.handles(o["kind"]):
		return Pets.interact(o)
	if Rex.handles(o["kind"]):
		return Rex.interact(o)
	if Dice.handles(o["kind"]):
		return Dice.interact(o)   # 35.1 the DICE CUP
	var p := player
	# 05b_items.rb: weapons and gear on the floor or for sale.
	if o["kind"] == "item" and (o["item"] as Dictionary).get("item", "") == "charm":   # 37.2 a charm
		if not Charms.pick_up(p, o["item"]):
			return deny(o, "NO ROOM: TAKE A CHARM OFF")
		o["gone"] = true
		Snd.play("relic")
		Fx.burst(o["x"], o["y"], [GameData.RARITY_HEX[o["item"]["rarity"]], "#ffffff"], 12, 50)
		return
	if o["kind"] == "item":
		if o.has("curse"):
			EventRooms.take_cursed(p, o)
		if (o["item"] as Dictionary).get("rarity", "") == "legend":
			Barks.hero("legend", true)   # 21.1
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
	if o["kind"] == "shop" and o["item"] == "charm":   # 37.2
		if p.gold < o["price"]:
			return deny(o, "NEED %d GOLD" % o["price"])
		if p.charms.size() >= Charms.slots(p) and p.backpack.size() >= Player.BACKPACK_SIZE:
			return deny(o, "NO ROOM: TAKE A CHARM OFF")
		p.gold -= o["price"]
		o["gone"] = true
		Snd.play("coin")
		Effects.fire("on_buy", { "x": o["x"], "y": o["y"] })
		Charms.pick_up(p, o["thing"])
		return
	if o["kind"] == "shop" and (o["item"] == "weapon" or o["item"] == "gear"):
		if p.gold < o["price"]:
			return deny(o, "NEED %d GOLD" % o["price"])
		p.gold -= o["price"]
		o["gone"] = true
		Snd.play("coin")
		Effects.fire("on_buy", { "x": o["x"], "y": o["y"] })
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
			StatDrops.maybe(0.35, o["x"], o["y"] + 10)   # 8.3
			TraitRules.maybe_drop(o["x"] + 30, o["y"] + 4)   # 41.5: sometimes a trait tome
			Effects.fire("on_chest", { "x": o["x"], "y": o["y"] })
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
			Effects.fire("on_chest", { "x": o["x"], "y": o["y"] })
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
			Effects.fire("on_chest", { "x": o["x"], "y": o["y"] })
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
			if o["item"] == "infusion" and p.belt.size() >= Consumables.BELT_SIZE:
				return deny(o, "BELT FULL")
			p.gold -= o["price"]
			o["gone"] = true
			Snd.play("coin")
			Effects.fire("on_buy", { "x": o["x"], "y": o["y"] })
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
				"die": Dice.give(p, o["die"], 1)   # 35.1
				"food": Food.take(p, o["food"])   # 36.1
				"infusion": Consumables.take(p, o["infusion"])   # 44: into the belt
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
			if GameData.rogues() and randf() < 0.3:   # 36.2: the altar may leave golden food too
				Combat.drop_pickup(Food.roll_golden(), o["x"], o["y"] + 14)
		"fountain":
			o["used"] = true
			p.heal(p.max_hp)
			Fx.burst(o["x"], o["y"], ["#6fd3e0", "#f4ecd8"], 20, 60)
		"anvil":
			# Rogues layer: pay gold to upgrade the weapon you hold (+8% damage per level).
			if int(p.weapon.get("plus", 0)) >= WeaponInfo.MAX_PLUS:   # (46: its own levels; an enchantment's come on top)
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
		"alshrine":
			Alignments.take_shrine(room, o)
		"alwayshrine":
			Alignments.buy(room, o)   # 38.1
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
				Combat.hurt_player(1, "a greedy idol", true)
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
				Combat.hurt_player(1, "the wheel of fate", true)
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
		"ttome":   # 41.5: a trait tome
			TraitRules.open_tome(o)
		"grimoire":   # 29: a hidden room's book of traits
			o["used"] = true
			p.special_picks += 1
			p.pending += 1
			Snd.play("relic")
			Fx.burst(o["x"], o["y"], ["#f2c94c", "#e86fb4", "#ffffff"], 20, 70)
			toast("THE GRIMOIRE OPENS: CHOOSE A RARE TRAIT", "gold")
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
				if Endless.on():
					Endless.next_floor()   # 22.2: past the last floor, round again a loop deeper
				else:
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
		"soulgate":
			Snd.play("portal")
			o["used"] = true
			_enter_realm(o["realm"], 0)
		"pageportal":
			Snd.play("portal")
			o["used"] = true
			_enter_realm("seam", 3)

# ---------- Relics, items and traits ----------
## 38.1: `al` is a vendor's alignment (Alignments.price_mult: cheaper when yours matches).
func price(v: float, al: String = "") -> int:
	if al != "":
		v *= Alignments.price_mult(player, al)
	if Daily.is_on("gold"):
		v *= 1.5   # 18.1 GOLD RUSH
	if dread >= 3:
		v *= 1 + 0.08 * Dread.old()
	return maxi(1, roundi(v * (1 - player.shop_disc)))

func item_price(item: Dictionary, al: String = "") -> int:
	var base: int = { "common": 26, "rare": 44, "epic": 68, "legend": 96, "mythic": 140 }[item["rarity"]]
	return price(base + floor_index * 8, al)

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
	if it["item"] == "charm":   # 37.2: into a free charm slot
		if Charms.wear(p, it):
			p.backpack.remove_at(i)
			Snd.play("relic")
		else:
			toast("CHARMS FULL: PICK ONE IN THE ROW AND USE TO TAKE IT OFF", "grey")
			Snd.play("deny")
		return
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
	ids += Relics.new_ids().filter(func(i): return not AlignShops.shop_only(i))   # new content is always in the pool (45.1: the shops' own relics are not)
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
## 35.1: `exclude` (ids) keeps the ones a pick already shows out; banished relics never come.
func roll_relics(n: int, source: String = "chest", in_room: Room = null, exclude: Array = []) -> Array:
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
		if not owned.has(r["id"]) and not offered.has(r["id"]) and not r["id"] in exclude and not Dice.banned(r["id"]):
			pool.append(r)
	if pool.size() < n:
		pool = []
		for r in relic_pool():
			if not owned.has(r["id"]) and not r["id"] in exclude and not Dice.banned(r["id"]):
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
	if r.get("rarity", "") == "legend" and state == &"play":
		Barks.hero("legend", true)   # 21.1
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
		choice = { "relics": ch, "idx": mini(1, ch.size() - 1), "source": source }
		state = &"choice"
	Dice.maybe({ "chest": 0.25, "iron": 0.4, "cursed": 0.6, "boss": 1.0 }.get(source, 0.25), o["x"], o["y"] + 10)   # 35.1
	Charms.maybe({ "chest": 0.2, "iron": 0.3, "cursed": 0.4, "boss": 0.6 }.get(source, 0.2), o["x"] + 20, o["y"] + 16)   # 37.2
	Infusions.maybe({ "chest": 0.2, "iron": 0.3, "cursed": 0.35, "boss": 0.5 }.get(source, 0.2), o["x"] - 20, o["y"] + 16)   # 44
	Loot.treasure(o["x"] - 22, o["y"] + 16)   # 38.2 TREASURE FIND

## Offer weight. Original traits keep the original formula exactly. New
## traits (design spec section 4): rarity weight times a snowball affinity
## from ranks already in the family and tag points from new-content items.
## Legendary traits (like capstones) need 3+ ranks in their family, and
## cursed traits only appear from level 3.
func trait_weight(p: Player, t: Dictionary) -> int:
	var rank: int = p.traits.get(t["id"], 0)
	if rank >= t["max"]:
		return 0
	if GameData.rogues() and not TraitRules.allowed(p, t):
		return 0   # 41.5: 12 traits at most; some only while they can work
	if t["new"]:
		return _new_trait_weight(p, t)
	var fam: int = p.fam.get(t["fam"], 0)
	if t["cap"]:
		return 0 if fam < 3 else 6
	var w := 1 if GameData.rogues() else 3   # 29: the plain originals come up less often in the expanded game
	if t["fam"] != "core":
		w += mini(fam, 4) * 2
	return w

func _new_trait_weight(p: Player, t: Dictionary) -> int:
	var fam: int = p.fam.get(t["fam"], 0)
	if t["rarity"] == "oath":   # 29: only through an oath pick (the start of a run) or a grimoire
		return 0
	if t["rarity"] == "mythic":   # 26: the rarest of all: from level 6, never helped by a family
		return 0 if p.level < 6 else 1
	if (t["cap"] or t["rarity"] == "legend") and fam < 3:
		return 0
	if t["rarity"] == "cursed" and p.level < 3:
		return 0
	if t["rarity"] == "super":   # 8.4 / 8.5: common ones often from level 2, the rest rarely from level 4
		if t["id"] in Traits.COMMON_SUPER:
			return 0 if p.level < 2 else 4
		return 0 if p.level < 3 else 2   # 29: from level 3 (was 4), twice as often
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
	# 29: the run's OATH, or a grimoire's pick of rare traits; with none left to offer, an ordinary pick.
	var mode := ""
	if GameData.rogues():
		mode = "oath" if p.oath_picks > 0 else ("special" if p.special_picks > 0 else "")
	var cands := trait_cands(p, mode)
	if cands.is_empty() and mode != "":
		p.oath_picks = 0
		p.special_picks = 0
		mode = ""
		cands = trait_cands(p, mode)
	var opts := []
	var n_opts := 3
	if TraitView.active() and p.luck > 0 and randf() < minf(0.9, p.luck * 0.15):
		n_opts = 4   # the expanded game: luck can add a fourth trait to choose from
	for k in n_opts:
		if cands.is_empty():
			break
		# 29: the first row of an ordinary pick is a rare-or-better trait when one can be offered.
		var pool := cands
		if k == 0 and mode == "" and GameData.rogues():
			var sp := cands.filter(func(pair): return pair[0]["new"] and pair[0]["rarity"] in Traits.SPOTLIGHT)
			if not sp.is_empty():
				pool = sp
		var tot := 0
		for c in pool:
			tot += c[1]
		var x := randf() * tot
		var idx := 0
		for i in pool.size():
			x -= pool[i][1]
			if x < 0:
				idx = i
				break
		var got: Dictionary = pool[idx][0]
		opts.append(got)
		for i in cands.size():
			if cands[i][0]["id"] == got["id"]:
				cands.remove_at(i)
				break
	if mode == "" and opts.size() < 3 and TraitRules.full(p):
		opts.append_array(TraitRules.stat_rows(p).slice(0, 3 - opts.size()))   # 41.5: stat points
	if opts.is_empty():
		p.pending = 0
		return
	tchoice = { "opts": opts, "idx": 0 if TraitView.active() else mini(1, opts.size() - 1), "t0": time, "mode": mode }
	for t in opts:
		if not t.has("stat"):
			TraitBook.note_seen(t)   # 30.2: lit in the trait book
	state = &"traits"

## The traits a pick can offer now, with their weights: [[trait, weight]...]. 35.1: a banished
## trait never comes again (Dice).
func trait_cands(p: Player, mode: String) -> Array:
	var cands := []
	for t in Traits.all():
		if p.banished.has(t["id"]):
			continue
		var w := _special_weight(p, t, mode) if mode != "" else trait_weight(p, t)
		if w > 0:
			cands.append([t, w])
	return cands

## 29: only the practice dummy and target are left in the room.
func _only_dummies() -> bool:
	for e in enemies:
		if not e.type in ["dummy", "target"]:
			return false
	return true

## 29: weights of an OATH pick (the oaths alone) and of a grimoire's pick (rare or better, oaths
## too, no family or level needed but a mythic's level 6; no cursed trait).
func _special_weight(p: Player, t: Dictionary, mode: String) -> int:
	if not t["new"] or p.traits.get(t["id"], 0) >= t["max"] or not TraitRules.allowed(p, t):
		return 0
	if mode == "oath":
		return 1 if t["rarity"] == "oath" else 0
	match t["rarity"]:
		"rare": return 3
		"super", "legend", "oath": return 2
		"mythic": return 1 if p.level >= 6 else 0
	return 0

func take_trait(t: Dictionary) -> void:
	var p := player
	if t.has("stat"):
		return TraitRules.take_stat(p, t)   # 41.5: a stat point
	if tchoice.get("opts", []).has(t):   # 29: an oath or a grimoire's pick is spent
		match tchoice.get("mode", ""):
			"oath": p.oath_picks = maxi(0, p.oath_picks - 1)
			"special": p.special_picks = maxi(0, p.special_picks - 1)
	p.traits[t["id"]] = p.traits.get(t["id"], 0) + 1
	Traits.apply(t["id"], p)
	TraitBook.note_taken(t)   # 30.2
	if t["rarity"] == "oath":
		Oaths.sworn(p, t["id"])   # 30.1: its vow starts counting
	Attributes.on_trait(p, t["fam"])
	p.charges = mini(p.charges, p.dodge_charges)
	var fam: String = t["fam"]
	p.fam[fam] = p.fam.get(fam, 0) + 1 + (Traits.PLUS[t["id"]][1] if Traits.PLUS.has(t["id"]) else 0)   # 8.4 SUPER
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
	if Dice.on_choice():   # 35.1: MENU rerolls, HEAL alters the chosen relic, BOMB banishes it
		return
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
	if Dice.on_traits():   # 35.1: HEAL alters the chosen row, BOMB banishes it
		return
	if Keys.back():
		if player.rerolls > 0:
			if GameData.rogues():
				Dice.spend(player, "reroll")   # 35.1: a REROLL die
			else:
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
		&"title":
			Ambience.stop()   # 21.3: the place's sound fades on the title
			update_title(dt)
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
		&"keys": update_keys()
		&"wardrobe": update_wardrobe()
		&"kitchen": CampLife.update_kitchen()   # 19.2
		&"armory": CampLife.update_armory()
		&"plans": CampBuild.update_plans()   # 20.2
		&"board": Quests.update_board()
		&"shrine":
			update_embers(dt)
			update_shrine()
		&"codex":
			update_embers(dt)
			update_codex()
		&"pause": update_pause()
		&"fishing": Fishing.update(dt)   # 15.1
		&"inventory": update_inventory()
		&"relics", &"traitlist", &"gearpage":
			if state == &"traitlist" and GameData.rogues():   # 41.3: the arrows choose a cube
				traitlist_i = _grid_nav(clampi(traitlist_i, 0, maxi(0, TraitPage.owned().size() - 1)), maxi(1, TraitPage.owned().size()), TraitPage.COLS)
			if Keys.any():
				state = &"pause"
				Snd.play("select")
		&"choice": update_choice()
		&"traits": update_traits()
		&"tome": TraitRules.update()   # 41.5
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
	var cells := 10 + (Charms.slots(p) if Charms.on() else 0)   # 37.2: the charm row after the belt
	inv_i = mini(inv_i, cells - 1)
	if Keys.left():
		inv_i = (inv_i + cells - 1) % cells
		Snd.play("select")
	if Keys.right():
		inv_i = (inv_i + 1) % cells
		Snd.play("select")
	if Keys.up() or Keys.down():
		inv_i = mini(inv_i + 6, cells - 1) if inv_i < 6 else mini(inv_i - 6, 5)
		Snd.play("select")
	if inv_i >= 10:   # a charm slot: USE takes it off (into the backpack), ROLL drops it
		var ci := inv_i - 10
		if Keys.confirm():
			if ci < p.charms.size() and p.backpack.size() < Player.BACKPACK_SIZE:
				p.backpack.append(Charms.take_off(p, ci))
				Snd.play("place")
			else:
				Snd.play("deny")
		elif Keys.roll():
			if ci < p.charms.size():
				drop_item(Charms.take_off(p, ci), p.x, p.y + 14)
				Snd.play("place")
		return
	if Keys.confirm():
		if inv_i < 6:
			if inv_i < p.backpack.size():
				equip_from_backpack(inv_i)
			else:
				Snd.play("deny")
		else:
			Consumables.use(p, inv_i - 6)
	elif Dice.on_inventory():   # 35.1: HEAL alters the chosen backpack item, BOMB banishes it
		pass
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
	var items := pause_items()
	if menu_nav(items.size()):
		Snd.play("confirm")
		match items[menu]:
			"RESUME": state = &"play"
			"GEAR":
				state = &"inventory" if GameData.rogues() else &"gearpage"
				inv_i = 0
			"TRAITS":
				state = &"traitlist"
				traitlist_i = 0
			"RELICS": state = &"relics"
			"WARDROBE": open_wardrobe(&"pause")
			"OPTIONS":
				state = &"options"
				opt_from = &"pause"
				menu = 0
			"LEAVE CAMP":
				state = &"title"
				menu = title_index("THE CAMP")
			"ABANDON RUN":
				if quit_armed:
					on_death("giving up")
				else:
					quit_armed = true
	if menu >= items.size() or items[menu] != "ABANDON RUN":
		quit_armed = false

## The pause menu; the expanded game adds the WARDROBE (14.2).
func pause_items() -> Array:
	if Camp.active():
		return Camp.pause_items()   # 17.2
	var out: Array = PAUSE_ITEMS.duplicate()
	if GameData.rogues():
		out.insert(out.find("OPTIONS"), "WARDROBE")
	return out

## 14.2: the WARDROBE page: every set, the pieces found, what each step gives.
func open_wardrobe(from: StringName) -> void:
	wardrobe_from = from
	state = &"wardrobe"
	menu = wardrobe_i

func update_wardrobe() -> void:
	var n := Gear.SETS.size()
	menu_nav(n)
	wardrobe_i = menu
	if Keys.back():
		state = wardrobe_from
		menu = title_index("WARDROBE") if wardrobe_from == &"title" else pause_items().find("WARDROBE")
		Snd.play("select")

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
		out.insert(out.find("CODEX") + 1, "WARDROBE")   # 14.2
		out.insert(out.find("START RUN") + 1, "THE CAMP")   # 17.2
	if RunSave.exists():
		out.insert(0, "CONTINUE")   # 6.3: a saved run
	return out

func title_index(item: String) -> int:
	return maxi(0, title_items().find(item))

func update_title(dt: float) -> void:
	update_embers(dt)
	if Keys.triggered(&"special"):
		Rex.poke()   # the sleeping dog in the corner
	var items := title_items()
	if not menu_nav(items.size()):
		return
	Snd.play("confirm")
	match items[menu]:
		"CONTINUE":
			if not RunSave.load_run():
				RunSave.clear()
				toast("THE SAVED RUN COULD NOT BE READ", "red")
		"START RUN":
			endless_next = false
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
		"WARDROBE": open_wardrobe(&"title")
		"THE CAMP": Camp.enter()
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
		endless_next = false
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

## 48.3 (his word): a hero's tree reset, every ember back; the first press asks, the second does it.
var tree_reset_armed := false
func tree_reset() -> void:
	var h: Dictionary = GameData.heroes()[tree_hero]
	var owned := tree_owned(h["id"])
	var spent := Traits.tree_spent(owned)
	if spent <= 0:
		Snd.play("deny")
		toast("NOTHING LEARNED YET", "grey")
		return
	if not tree_reset_armed:
		tree_reset_armed = true
		Snd.play("deny")
		toast("AGAIN TO RESET: %d EMBERS BACK" % spent, "orange")
		return
	tree_reset_armed = false
	Meta.meta["embers"] += spent
	Meta.meta["tree"][h["id"]] = [0, 0, 0]
	Meta.write_save()
	Snd.play("unlock")
	toast("TREE RESET: +%d EMBERS" % spent, "gold")

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
	if Keys.left() or Keys.right() or Keys.up() or Keys.down() or Keys.aim_left_trig() or Keys.aim_right_trig():
		tree_reset_armed = false   # (48.3: a reset asks again after moving)
	if Keys.left():
		tree_b = (tree_b + 2) % 3
		Snd.play("select")
	if Keys.right():
		tree_b = (tree_b + 1) % 3
		Snd.play("select")
	var tn: int = Traits.tree_for(GameData.heroes()[tree_hero]["id"])[tree_b]["nodes"].size()   # (48.3: six in the expanded game)
	if Keys.up():
		tree_n = (tree_n + tn - 1) % tn
		Snd.play("select")
	if Keys.down():
		tree_n = (tree_n + 1) % tn
		Snd.play("select")
	if Keys.bomb():
		tree_reset()   # 48.3: twice, and the tree is reset for its embers
		return
	if Keys.back():
		state = &"hero" if tree_from == &"hero" else Camp.back_state()
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
		state = Camp.back_state()
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
	if Keys.roll():
		codex_tab = (codex_tab + 1) % MenuView.CODEX_TABS.size()   # 22.3: the next page
		Snd.play("select")
	if codex_tab == 0:
		codex_i = _grid_nav(codex_i, Relics.all().size(), CODEX_COLS)
	elif codex_tab == 1:
		bestiary_i = _grid_nav(bestiary_i, Bestiary.entries().size(), Bestiary.COLS)
	elif codex_tab == 3:
		traitbook_i = _grid_nav(traitbook_i, TraitBook.entries().size(), TraitBook.COLS)
	if Keys.back() or Keys.confirm():
		state = &"title"
		menu = title_index("CODEX")
		Snd.play("select")

## A grid's arrows: LEFT/RIGHT step, UP/DOWN a row (the codex pages).
func _grid_nav(i: int, n: int, cols: int) -> int:
	if Keys.left():
		i = (i + n - 1) % n
		Snd.play("select")
	if Keys.right():
		i = (i + 1) % n
		Snd.play("select")
	if Keys.up():
		i = TB.rmod(i - cols, n)
		Snd.play("select")
	if Keys.down():
		i = (i + cols) % n
		Snd.play("select")
	return i

func update_options() -> void:
	var go := menu_nav(OPTION_LIST.size())
	var back_menu := title_index("OPTIONS") if opt_from == &"title" else pause_items().find("OPTIONS")
	if Keys.back():
		state = opt_from
		menu = back_menu
		Snd.play("select")
		return
	var key: String = OPTION_LIST[menu][1]
	if key != "@reset":
		reset_armed = false
	if key == "@reset":   # 48.4 (his word): every bit of progress starts over, after a second press
		if go:
			if opt_from != &"title":
				Snd.play("deny")
				toast("RESET THE GAME FROM THE TITLE'S OPTIONS", "orange")
			elif not reset_armed:
				reset_armed = true
				Snd.play("deny")
				toast("PRESS AGAIN TO ERASE ALL PROGRESS", "red")
			else:
				reset_armed = false
				Meta.reset_progress()
				hero_index = 0
				state = &"title"
				menu = 0
				Snd.play("boom")
				toast("THE GAME STARTS OVER", "red")
		return
	if key == "@keys":
		if go:
			state = &"keys"   # 13.1: the keyboard keys page
			menu = 0
			Keys.hold_off = 6
			Snd.play("select")
		return
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
		if key == "neon":
			room_changed.emit()   # 10.5: the room is drawn again in the chosen look
		Snd.play("confirm")
		Meta.write_save()

## 13.1: the keyboard keys page. Pick an action, press a key; RESET puts every key back.
func update_keys() -> void:
	if Keys.capturing != &"":
		# Keys._input takes the next key press. 22.4: a tap (USE), BACK or MENU, or a wait of
		# CAPTURE_MAX seconds, ends it: an iPad with no keyboard was stuck on this page.
		Keys.capture_t += TB.DT
		if Keys.capture_t > Keys.CAPTURE_MAX or (Keys.capture_t > 0.25 and (Keys.confirm() or Keys.back())):
			Keys.capturing = &""
			Keys.hold_off = 12
			Snd.play("select")
		return
	if Keys.hold_off > 0:
		Keys.hold_off -= 1
		return
	var n := Keys.REBIND.size() + 2
	var go := menu_nav(n)
	if Keys.back() or (go and menu == n - 1):
		state = &"options"
		menu = OPTION_LIST.map(func(o): return o[1]).find("@keys")   # (48.4: RESET GAME stands after it)
		Snd.play("select")
		return
	if not go:
		return
	if menu == n - 2:
		Keys.reset_keys()
		Meta.write_save()
		Snd.play("confirm")
		return
	Keys.capturing = Keys.REBIND[menu][0]
	Keys.capture_t = 0.0
	Snd.play("select")

## The app goes to the background (iPad locked, another app opened): a fight in progress waits
## in the pause menu, and the progress so far is saved in case iOS closes the app meanwhile.
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if state == &"play":
			state = &"pause"
			menu = 0
			quit_armed = false
		Meta.write_save()

## 47.6 (his clip of a run at 14 to 19 frames a second): the logic each part of a tick costs, in
## microseconds since the last breakdown (main.gd turns it into the SHOW FPS breakdown line).
var lprof := {}
var _lp_t := 0
func _lp(k: String) -> void:
	var now := Time.get_ticks_usec()
	lprof[k] = lprof.get(k, 0) + now - _lp_t
	_lp_t = now

func update_play(dt: float) -> void:
	run_stats["time"] += dt
	Combat.track_power(dt)
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
	_lp_t = Time.get_ticks_usec()   # (47.6: what each part costs, for the SHOW FPS breakdown)
	Dread.tick(dt)   # 48.1 FALTERING NERVE
	Effects.tick(dt)
	_lp("PROCS")
	Combat.update_player(p, dt)
	_lp("HERO")
	Ambience.tick(p)   # 21.3 footsteps, the music's fight or calm level
	if state != &"play":
		return
	_lp_t = Time.get_ticks_usec()
	Combat.update_enemies(dt)
	_lp("FOES")
	Combat.update_pbullets(dt)
	_lp("SHOTS")
	EBullets.update(dt)
	_lp("FOE SHOTS")
	Combat.update_pickups(dt)
	_lp("PICKUPS")
	Combat.update_bombs(dt)
	Combat.update_zones(dt)
	_lp("POOLS")
	Hazards.update(dt)
	EventRooms.update(dt)
	_lp("SPELLS")
	Fx.update(dt)
	Barks.update(dt)   # 21.1 voices
	if Camp.active():
		Barks.camp_tick()
	Juice.update(dt, p)
	_lp("FX")
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
		# 35.2 PACE: the next wave when the one before is down to its last 2 (Pace.wave_gate).
		if room.waves_left > 0 and alive <= (Pace.wave_gate() if _spawned else 0):
			_wave_delay -= dt
			if _wave_delay <= 0:
				spawn_wave(room.type == "challenge")
				_spawned = true
				_wave_delay = Pace.wave_gap()
		elif alive == 0 and room.waves_left <= 0:
			room_cleared()
		elif room.type != "challenge":
			Pace.tick(dt, alive, room.waves_left)   # 35.2 FINISH THEM
	if room.event_fight and locked and enemies.is_empty():
		event_fight_cleared()
	if room.type == "boss" and locked and boss == null and boss_delay != null:
		boss_delay -= dt
		if boss_delay <= 0:
			boss_delay = null
			if room.rift_step == 3:
				Combat.spawn_boss(room.theme["guardian"])
				if room.theme["id"] == "seam":
					show_banner(boss.d["name"], "THE LAST BOSS OF ALL")
				elif room.theme["id"] == "redaction":
					show_banner(boss.d["name"], "IT ERASES EVEN AUTHORS")
				elif room.theme.get("realm", false):
					show_banner(boss.d["name"], "RULER OF " + room.theme["name"])
				else:
					show_banner(boss.d["name"], "GUARDIAN OF " + room.theme["name"])
			else:
				Combat.spawn_boss(floor_d.get("guardian", GameData.floors()[floor_index]["boss"]))   # 9.3: maybe the second guardian
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
	# Level-ups wait until the room is safe (29: the start room's practice dummy and target do not
	# count in the expanded game, so the run's OATH comes at once).
	if p.pending > 0 and not locked and (enemies.is_empty() or GameData.rogues() and _only_dummies()):
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
