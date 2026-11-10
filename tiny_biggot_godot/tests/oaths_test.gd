extends Node
## 30.1: every OATH's vow, kept. Run:
##   godot --headless --path . res://tests/oaths_test.tscn -- --no-save
## For each oath: a new run in a live fight, the oath sworn (its vow starts at 0 and counts with
## the oath's own trigger), the vow brought to its goal: the oath awakens once (its powers join it,
## the HUD line turns gold), then 3 s of the fight with them. Prints "oaths test: PASSED" or a FAIL
## line per problem.

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL oaths: ", msg)

func _ready() -> void:
	await get_tree().process_frame
	seed(30)
	var n := 0
	for id in Oaths.VOWS:
		_one(id)
		n += 1
	if n != 20:
		fail("%d vows, not 20" % n)   # (53.2: the OATH OF SOULS)
	for t in Traits.all():
		if t["rarity"] == "oath" and not Oaths.VOWS.has(t["id"]):
			fail("the oath %s has no vow" % t["id"])
	print("oaths test: PASSED" if fails == 0 else "oaths test: %d FAILED" % fails)
	get_tree().quit()

func _one(id: String) -> void:
	G.hero_index = 0
	G.new_run()
	G.floor_index = 2
	G.start_floor()
	G.god = true
	G.enter_room(World.make_room(G.floor_d, "combat", "", "s", { "no_secret": true }))
	G.state = &"play"
	var p := G.player
	p.pending += 1
	G.take_trait(Traits.by_id(id))
	if int(p.vows.get(id, -1)) != 0:
		fail("%s: the vow did not start at 0 (%s)" % [id, p.vows.get(id)])
	var procs := p.procs.size()
	var goal: int = Oaths.VOWS[id][0]
	Oaths.progress(p, id, goal - 1)
	if p.vows_done.has(id):
		fail("%s: awakened one step early" % id)
	Oaths.progress(p, id, 1)
	if not p.vows_done.has(id):
		fail("%s: not awakened at its goal" % id)
	var awake := 0
	for pr in p.procs:
		if pr["src"] == "vow:" + id + ":awake":
			awake += 1
	var want := 0
	for e in Oaths.VOWS[id][5]:
		if e is Dictionary:
			want += 1
	if awake != want:
		fail("%s: %d awakened procs, not %d" % [id, awake, want])
	Oaths.progress(p, id, goal)   # kept already: nothing more happens
	if p.procs.size() != procs + awake:
		fail("%s: awakened twice" % id)
	var lines := Oaths.hud_lines(p)
	if lines.size() != 1 or lines[0][1] != "gold":
		fail("%s: HUD line %s" % [id, lines])
	for i in 180:
		p.hp = p.max_hp
		G.update(TB.DT)
		if G.state != &"play":
			G.state = &"play"
			G.tchoice = {}
