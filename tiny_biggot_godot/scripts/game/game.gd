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
var menu := 0
var choice: Dictionary = {}    # relic choice: { relics, idx }
var tchoice: Dictionary = {}   # trait offer: { opts, idx }
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
	Effects.reset_run_state()
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
	var owned := tree_owned(hero["id"])
	var tree := Traits.tree_for(hero["id"])
	for bi in tree.size():
		for ni in owned[bi]:
			Traits.apply_node(tree[bi]["nodes"][ni][0], p)
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
	if Meta.unlocked("perk_relic"):
		var r := roll_relics(1, "chest")
		if not r.is_empty(): add_relic(p, r[0])
	if p.start_rare:
		var r := roll_relics(1, "iron")
		if not r.is_empty(): add_relic(p, r[0])
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
	if not p.procs.is_empty():
		Effects.fire("on_room_enter")

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
## Room furniture (Game.rb setup_objects + 05b_items.rb).
func setup_objects(r: Room) -> void:
	var cx := 14.0 * TB.TS
	var cy := 9.5 * TB.TS
	var f := floor_index
	match r.type:
		"treasure":
			if randf() < 0.35:
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
		"secret":
			var roll := randf()
			if roll < 0.45:
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
	# 05b_items.rb: weapons and gear in shops and treasure rooms.
	match r.type:
		"shop":
			var w := Weapons.random_weapon(Gear.roll_item_rarity(f), player.weapon)
			var g := Gear.random_gear(Gear.roll_item_rarity(f))
			r.objects.append({ "kind": "shop", "item": "weapon", "thing": w, "x": cx - 40, "y": cy + 34, "price": item_price(w) })
			r.objects.append({ "kind": "shop", "item": "gear", "thing": g, "x": cx + 40, "y": cy + 34, "price": item_price(g) })
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
	# 05b_items.rb: guardians drop a weapon and sometimes gear.
	drop_item(Weapons.random_weapon(Gear.roll_item_rarity(floor_index, "boss"), player.weapon), b.x - 20, b.y + 20)
	if randf() < 0.5:
		drop_item(Gear.random_gear(Gear.roll_item_rarity(floor_index, "boss")), b.x + 20, b.y + 20)

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
	var p := player
	# 05b_items.rb: weapons and gear on the floor or for sale.
	if o["kind"] == "item":
		var old = swap_item(o, o["item"])
		if old != null:
			o["item"] = old
			o["t"] = 0.0
		else:
			o["gone"] = true
		return
	if o["kind"] == "shop" and (o["item"] == "weapon" or o["item"] == "gear"):
		if p.gold < o["price"]:
			return deny(o, "NEED %d GOLD" % o["price"])
		p.gold -= o["price"]
		o["gone"] = true
		Snd.play("coin")
		var old = swap_item(o, o["thing"])
		if old != null:
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
	for k in 3:
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
	tchoice = { "opts": opts, "idx": mini(1, opts.size() - 1) }
	state = &"traits"

func take_trait(t: Dictionary) -> void:
	var p := player
	p.traits[t["id"]] = p.traits.get(t["id"], 0) + 1
	Traits.apply(t["id"], p)
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
	menu = tchoice["idx"]
	var go := menu_nav(tchoice["opts"].size(), true)
	tchoice["idx"] = menu
	if Keys.back():
		if player.rerolls > 0:
			player.rerolls -= 1
			Snd.play("confirm")
			offer_traits()
		elif player.gold >= reroll_cost():
			# New (design spec 4): once the free rerolls are gone, rerolls cost gold.
			player.gold -= reroll_cost()
			player.paid_rerolls += 1
			Snd.play("coin")
			offer_traits()
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
		&"play":
			update_play(dt)
		&"pause":
			update_pause()
		&"choice":
			update_choice()
		&"traits":
			update_traits()
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
