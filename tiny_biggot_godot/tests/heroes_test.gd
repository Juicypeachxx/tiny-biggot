extends Node
## The ten heroes of ROADMAP 4.8. Run:
##   godot --headless --path . res://tests/heroes_test.tscn -- --no-save
##   1. Data: each is a hero with a sprite, a signature weapon (with an icon, never in loot pools),
##      a starting trait, attributes, an unlock price at the shrine, a special, and a branch of four
##      nodes that each do something; all their text fits the font.
##   2. Each one fights for 30 s (cannot be hurt): its passive does what it says (the action it is
##      built on runs and finds something to do), and its special does too.
##   3. Every branch node applied to its hero in a fight: nothing errs.
## Prints "heroes test: PASSED" or a FAIL line per problem.

## hero -> [the passive's action, the special's action]: "ran:x" or "did:x" (Actions.ran / did),
## "sum:x" (Summons.stats).
const NEW := {
	"beekeeper": ["ran:summon", "ran:status_area"], "tinkerer": ["sum:item_turret", "ran:buff"],
	"boneweaver": ["sum:item_raise", "ran:status_area"], "mirrorknight": ["did:reflect", "ran:invuln"],
	"plaguesaint": ["did:spread", "did:consume"], "frostwitch": ["did:slow_shots", "ran:status_area"],
	"demolitionist": ["did:give", "ran:meteor"], "executioner": ["did:overkill", "did:execute_weakest"],
	"pilgrim": ["ran:heal", "ran:invuln"], "beastmaster": ["ran:charm", "did:charm_area"],
	"clockmaker": ["did:slow_shots", "ran:invuln"],
}

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL heroes: ", msg)

func _ready() -> void:
	await get_tree().process_frame
	seed(3)
	Meta.opts["autofire"] = true
	_data()
	for id in NEW:
		_fight(id)
	print("heroes test: PASSED" if fails == 0 else "heroes test: %d FAILED" % fails)
	get_tree().quit()

func _index(id: String) -> int:
	var all := GameData.heroes()
	for i in all.size():
		if all[i]["id"] == id:
			return i
	return -1

func _fits(id: String, s: String) -> void:
	for ch in s:
		if not ch in Gfx.FONT_CHARS:
			fail("%s: '%s' is not in the font (%s)" % [id, ch, s.left(30)])
			return

func _data() -> void:
	Weapons.all()
	var unlock_ids := GameData.unlocks().map(func(u): return u["id"])
	for id in NEW:
		var i := _index(id)
		if i < 0:
			fail("no hero " + id)
			continue
		var h: Dictionary = GameData.heroes()[i]
		if not Img.has(h["sprite"]):
			fail(id + ": no sprite")
		var wid: String = Weapons.HERO_WEAPON.get(id, "")
		if wid == "" or not Weapons._by_id.has(wid):
			fail(id + ": no signature weapon")
		else:
			if not Img.has(Weapons.by_id(wid)["sprite"]):
				fail(id + ": weapon without an icon")
			for k in 200:
				if Weapons.random_weapon("rare")["id"] == wid:
					fail(id + ": the signature weapon turned up in a loot pool")
					break
		if Traits.by_id(h["trait"]).is_empty():
			fail(id + ": no starting trait " + h["trait"])
		if not Attributes.HERO.has(id):
			fail(id + ": no attributes")
		if not ("hero_" + id) in unlock_ids:
			fail(id + ": not sold at the shrine")
		var br: Dictionary = Traits.HERO_BRANCH.get(id, {})
		if br.get("nodes", []).size() != 4:
			fail(id + ": its branch has %d nodes, not 4" % br.get("nodes", []).size())
		for s in [h["name"], h["passive"], h["weapon"], h["special"]["name"], h["special"]["desc"], h["blurb"].to_upper()]:
			_fits(id, s)

func _start(id: String) -> Player:
	G.hero_index = _index(id)
	G.new_run()
	G.floor_index = 2
	G.start_floor()
	G.god = true
	G.enter_room(World.make_room(G.floor_d, "combat", "", "s", { "no_secret": true }))
	G.room.waves_left = 0
	G.locked = true
	return G.player

func play(n: int, every: Callable = Callable()) -> void:
	for i in n:
		var p := G.player
		p.hp = mini(p.hp, p.max_hp)
		p.x = 14.0 * TB.TS
		p.y = 13.0 * TB.TS
		if every.is_valid():
			every.call(i)
		Keys.tick()
		G.update(TB.DT)
		if G.state != &"play":
			G.state = &"play"
			G.tchoice = {}
			G.choice = {}

func _seen(want: String) -> bool:
	var w := want.split(":")
	match w[0]:
		"ran": return Actions.ran.get(w[1], 0) > 0
		"did": return Actions.did.get(w[1], 0) > 0
		"sum": return Summons.stats.get(w[1], 0) > 0
	return false

## Sturdy foes ahead, a stream of weak (poisoned, chilled) ones, and foes' shots now and then.
func _feed(i: int) -> void:
	var p := G.player
	if i % 15 == 0:
		var w := Combat.spawn_enemy("skeleton", p.x - 24.0 + (i / 15 % 4) * 16.0, p.y - 26.0, false, true)
		w.speed = 0.0
		w.hp = 3.0
		if (i / 15) % 2 == 0:
			w.poison = 5.0   # half of them poisoned (the plague saint passes it on)
	if i % 20 == 0:
		for k in 6:
			var a := k * TAU / 6
			Combat.eshot(p.x + cos(a) * 26.0, p.y - 2 + sin(a) * 26.0, a, 15.0, "red")
	if i % 90 == 45:
		Combat.on_roll_start(p)
		p.bombs = maxi(p.bombs, 1)
		G.bombs.append({ "x": p.x, "y": p.y, "t": 5.0, "safe": true })
		Effects.fire("on_bomb", { "x": p.x, "y": p.y })
	if i % 120 == 60:
		p.hp = maxi(1, p.hp - 1)   # a scratch to heal (the pilgrim heals on entering, below)

func _fight(id: String) -> void:
	Actions.ran.clear()
	Actions.did.clear()
	Summons.stats.clear()
	seed(id.hash())   # each hero's fight is the same whatever runs before it
	var p := _start(id)
	for k in 4:
		var e := Combat.spawn_enemy("skeleton", p.x - 60.0 + k * 40.0, p.y - 110.0, false, true)
		e.speed = 0.0
		e.max_hp = 1e7
		e.hp = 1e7
	play(1)
	if id == "pilgrim":
		p.hp = p.max_hp - 1
		G.enter_room(G.room)   # entering heals
		G.room.waves_left = 0
		G.locked = true
	Effects.stats["procs"] = 0
	play(30 * 60, func(i): _feed(i))
	print("[heroes] %s: %d triggered effects in 30 s" % [id, Effects.stats["procs"]])
	if not _seen(NEW[id][0]):
		fail("%s: its passive (%s) never happened; ran %s did %s" % [id, NEW[id][0], Actions.ran, Actions.did])
	# The special, with weak foes, sturdy foes and shots around.
	Actions.ran.clear()
	Actions.did.clear()
	_feed(0)
	_feed(20)
	for e in G.enemies:
		e.poison = 5.0
		e.burn_t = 3.0
	play(3)
	Abilities.use(p)
	play(60)
	if not _seen(NEW[id][1]):
		fail("%s: its special (%s) did nothing; ran %s did %s" % [id, NEW[id][1], Actions.ran, Actions.did])
	# Every branch node of this hero, applied in a fight.
	var tree: Dictionary = Traits.HERO_BRANCH.get(id, {})
	for n in tree.get("nodes", []):
		if not Traits.NODE_EFFECTS.has(n[0]):
			fail("%s: the node %s does nothing" % [id, n[0]])
			continue
		Effects.apply(p, Traits.NODE_EFFECTS[n[0]], 1, "node:" + n[0])
		_fits(id, n[0] + " " + n[1])
	play(10 * 60, func(i): _feed(i))
