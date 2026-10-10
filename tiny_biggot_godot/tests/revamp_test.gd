extends Node
## Stage 43.7 THE OLD TRAITS REVAMPED (his words, 10 Oct: "update mechanic to match latest traits soo
## they wont feel out of match"; scripts/data/trait_revamp.gd). Run:
##   godot --headless --path . res://tests/revamp_test.tscn -- --no-save
## Every trait from before Stage 40 keeps what it did and gains one more effect and one more sentence;
## the text still fits its card; taking a rank gives the effect, giving the trait up takes it back;
## classic has none of it. Prints "revamp test: PASSED" or a FAIL line per problem.

const NEW_PREFIX := ["str_", "dex_", "int_", "sup_", "psy_", "aug_"]

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL revamp: ", msg)

func _old(id: String) -> bool:
	for pre in NEW_PREFIX:
		if id.begins_with(pre):
			return false
	return true

func _start() -> Player:
	G.hero_index = 0
	G.new_run()
	G.floor_index = 2
	G.start_floor()
	G.god = true
	var p := G.player
	p.oath_picks = 0
	p.special_picks = 0
	p.pending = 0
	return p

## The lines a trait's row on the level-up card has for its text (TraitView._row): its sentences as
## bullets, each wrapped to the row's width.
func _row_lines(t: Dictionary) -> int:
	var w := int(TraitView.row_rect(0).size.x) - 66
	var n := 0
	for part in TraitView.bullets(Live.desc(t)):
		n += TraitView.rich_lines(part, w).size()
	return n

## What a trait leaves on a hero: its stats, hooks and procs, after taking every rank of it and after
## giving it up again (TraitRules.remove). The same seed each time.
func _take_and_give_up(t: Dictionary) -> Array:
	seed(7)
	G.hero_index = 0
	G.new_run()
	var p := G.player
	for r in t["max"]:
		p.pending += 1
		G.take_trait(t)
	var took := _state(p)
	TraitRules.remove(p, t["id"])
	return [took, _state(p)]

const STATE := ["crit", "crit_mult", "echo", "rerolls", "luck", "thorns", "storm", "chain", "elite_mult", "dodge_charges",
	"vs_burn", "vs_chill", "burn", "burn_dmg", "burn_leap", "armor_regen", "rate", "a_str", "a_dex", "a_int"]

func _state(p: Player) -> Dictionary:
	var s := {}
	for k in STATE:
		s[k] = snappedf(float(p.get(k)), 0.0001)
	for k in p.gf:
		if absf(p.gf[k]) > 1e-9:
			s["gf." + k] = snappedf(p.gf[k], 0.0001)
	var procs := []
	for pr in p.procs:
		procs.append([pr["src"], pr["stacks"]])
	s["procs"] = procs
	s["armor"] = p.armor
	return s

func _diff(a: Dictionary, b: Dictionary) -> String:
	var out := []
	for k in a:
		if not b.has(k) or a[k] != b[k]:
			out.append("%s %s/%s" % [k, a[k], b.get(k)])
	for k in b:
		if not a.has(k):
			out.append("%s -/%s" % [k, b[k]])
	return ", ".join(out)

func _fight(group: Array) -> void:
	var p := _start()
	for t in group:
		for r in t["max"]:
			p.pending += 1
			G.take_trait(t)
	for t in group:
		for e in t["more"]:
			if e is Array and e[0] == "hook" and p.g(e[1]) <= 0.0:
				fail("%s: its add-on's %s is not there" % [t["id"], e[1]])
	G.enter_room(World.make_room(G.floor_d, "combat", "", "s", { "no_secret": true }))
	G.room.waves_left = 0
	G.enemies.clear()
	G.locked = true
	G.state = &"play"
	for i in 6:
		var e := Combat.spawn_enemy("skeleton", p.x - 40.0 + i * 16.0, p.y - 40.0, false, true)
		e.max_hp = 1e6
		e.hp = 1e6
	for i in 180:
		p.hp = p.max_hp
		Keys.tick()
		G.update(TB.DT)
		if G.state != &"play":
			G.state = &"play"
			G.tchoice = {}
			G.choice = {}

func _ready() -> void:
	# Every old trait has its add-on, and only old traits do.
	var old := 0
	for t in Traits.all():
		if not _old(t["id"]):
			if TraitRevamp.MORE.has(t["id"]):
				fail("%s is a new trait but has an add-on" % t["id"])
			continue
		old += 1
		if not TraitRevamp.MORE.has(t["id"]):
			fail("%s has no add-on" % t["id"])
			continue
		var more: Array = TraitRevamp.MORE[t["id"]]
		if t["more"] != more[1] or not String(t["desc"]).ends_with(more[0]):
			fail("%s: its add-on is not in its text and effects" % t["id"])
		if (more[1] as Array).is_empty():
			fail("%s: an add-on with no effect" % t["id"])
	for id in TraitRevamp.MORE:
		if not Traits.has(id):
			fail("add-on for %s, which is no trait" % id)
	if old != TraitRevamp.MORE.size():
		fail("%d old traits, %d add-ons" % [old, TraitRevamp.MORE.size()])
	print("[revamp] %d old traits, %d add-ons" % [old, TraitRevamp.MORE.size()])

	# The text fits its row on the level-up card (4 lines), as every new trait's does.
	var p := _start()
	var worst := 0
	for t in Traits.all():
		var n := _row_lines(t)
		var room := 3 if t["rarity"] == "oath" and Oaths.VOWS.has(t["id"]) else 4   # an oath's vow takes a line
		worst = maxi(worst, n)
		if n > room:
			fail("%s: its text takes %d lines on the level-up card (%d fit): %s" % [t["id"], n, room, Live.desc(t)])
	print("[revamp] the longest text takes %d lines" % worst)

	# Every rank of every old trait gives its add-on, and giving the trait up takes it all back: the
	# same hero takes the trait to its last rank and gives it up twice, with and without its add-on.
	var differ := 0
	for t in Traits.all():
		if not _old(t["id"]):
			continue
		var with_more := _take_and_give_up(t)
		var more: Array = t["more"]
		t["more"] = []
		var without := _take_and_give_up(t)
		t["more"] = more
		if with_more[0] == without[0]:
			fail("%s: its add-on changes nothing" % t["id"])
		else:
			differ += 1
		with_more[1].erase("armor")   # armor an add-on hands you once is yours to keep, as an old trait's is
		without[1].erase("armor")
		if with_more[1] != without[1]:
			fail("%s given up: its add-on stays (%s)" % [t["id"], _diff(with_more[1], without[1])])
	print("[revamp] %d traits taken to their last rank and given up, with and without their add-on" % differ)

	# Every old trait at its last rank in a live fight, 20 traits at a time (a run holds 12): no
	# error, and every hook of each add-on there.
	var t0 := Time.get_ticks_msec()
	var group := []
	var groups := 0
	for t in Traits.all():
		if _old(t["id"]) and t["rarity"] != "oath":
			group.append(t)
		if group.size() == 20 or (t == Traits.all().back() and not group.is_empty()):
			_fight(group)
			groups += 1
			group = []
	print("[revamp] %d fights of 20 old traits at their last rank (%d ms)" % [groups, Time.get_ticks_msec() - t0])

	# Classic: the old effects only.
	GameData.force_classic = true
	var c := _start()
	var gf0: Dictionary = c.gf.duplicate()
	c.pending += 1
	G.take_trait(Traits.by_id("might"))
	if c.g("crush") != float(gf0.get("crush", 0.0)):
		fail("classic: MIGHT gave a crushing hit chance")
	GameData.force_classic = false

	print("revamp test: PASSED" if fails == 0 else "revamp test: %d FAILED" % fails)
	get_tree().quit()
