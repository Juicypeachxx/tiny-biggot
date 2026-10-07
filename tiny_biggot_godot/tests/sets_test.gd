extends Node
## 13.2 armor sets (scripts/data/gear.gd). Run:
##   godot --headless --path . res://tests/sets_test.tscn -- --no-save
## Two, three and four pieces each add their step; the fourth brings the set's power and SET
## MASTERY, the big moment once (full health, a relic) and the aura; losing a piece takes it all
## back; a started set comes looking for you (drops and shops); every set line fits the font.
## Prints "sets test: PASSED" or a FAIL line per problem.

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL sets: ", msg)

func _ready() -> void:
	await get_tree().process_frame
	seed(132)
	G.hero_index = 0
	G.new_run()
	G.state = &"play"
	var p := G.player
	var pcs := Gear.pieces("emberweave")
	if pcs.size() != 4:
		fail("EMBERWEAVE has %d pieces" % pcs.size())
		return
	var d0 := p.dmg
	var a0 := p.armor
	var h0 := p.max_hp
	var r0 := p.relics.size()
	Gear.equip_gear(p, pcs[0])
	if Gear.chase_piece(p) == null or Gear.chase_piece(p)["set"] != "emberweave":
		fail("one piece in, no missing piece to chase")
	var chased := 0
	for i in 200:
		if Gear.random_gear("common").get("set") == "emberweave":
			chased += 1
	if chased < 40:
		fail("a started set came looking only %d times in 200 drops" % chased)
	Gear.equip_gear(p, pcs[1])
	Gear.equip_gear(p, pcs[2])
	if p.set_tier.get("emberweave", 0) != 2 or p.armor < a0 + 1:
		fail("three pieces: tier %d, armor %d (was %d)" % [p.set_tier.get("emberweave", 0), p.armor, a0])
	p.hp = 1
	Gear.equip_gear(p, pcs[3])
	if p.set_tier.get("emberweave", 0) != 3:
		fail("four pieces: tier %d" % p.set_tier.get("emberweave", 0))
	if p.relics.size() != r0 + 1 or p.hp != p.max_hp or not G.run_stats.get("sets_done", {}).has("emberweave"):
		fail("the set's completion paid nothing (relics %d, hp %d/%d)" % [p.relics.size(), p.hp, p.max_hp])
	if p.max_hp < h0 + 2 or p.dmg <= d0 * 1.15:
		fail("no SET MASTERY (max hp %d, damage %.2f)" % [p.max_hp, p.dmg])
	if Gear.chase_piece(p) != null:
		fail("a whole set is still chased")
	# Off and on again: the step goes, then comes back without a second relic.
	var hp_full := p.max_hp
	var off: Dictionary = pcs[3]
	p.gear[Gear.slot_for(p, off)] = null
	Weapons.apply_tuples(p, off["stats"], -1, "g:" + off["id"])
	Weapons.apply_hooks(p, off["hooks"], -1)
	Gear.update_sets(p, "emberweave", -1)
	if p.set_tier["emberweave"] != 2 or p.max_hp != hp_full - 2:
		fail("losing a piece kept the mastery (tier %d, max hp %d)" % [p.set_tier["emberweave"], p.max_hp])
	Gear.equip_gear(p, off)
	if p.relics.size() != r0 + 1:
		fail("the set paid twice")
	for id in Gear.SETS:
		var st: Dictionary = Gear.SETS[id]
		for line in [st["d2"], Gear.D3, st["d4"], st.get("d6", ""), Gear.D_MASTERY, st["name"] + " LEGENDARY SET COMPLETE!"]:
			for ch in line:
				if not ch in Gfx.FONT_CHARS:
					fail("'%s' not in the font: %s" % [ch, line])
		if Gear.pieces(id).size() != Gear.set_size(id):
			fail("%s has %d pieces" % [id, Gear.pieces(id).size()])
	_legendary()
	print("sets test: PASSED" if fails == 0 else "sets test: %d FAILED" % fails)
	get_tree().quit()

## 14.1: a LEGENDARY set steps at 2, 4 and 6 pieces; the sixth brings its power and SET MASTERY.
func _legendary() -> void:
	G.new_run()
	G.state = &"play"
	var p := G.player
	var pcs := Gear.pieces("voidregalia")
	var d0 := p.dmg
	var r0 := p.relics.size()
	var want := [0, 1, 1, 2, 2, 3]
	for i in 6:
		Gear.equip_gear(p, pcs[i])
		if p.set_tier.get("voidregalia", 0) != want[i]:
			fail("VOID REGALIA at %d pieces: step %d, want %d" % [i + 1, p.set_tier.get("voidregalia", 0), want[i]])
	if not p.procs.any(func(pr): return pr["src"] == "se6:voidregalia") or p.dmg < d0 * 1.4 or p.relics.size() != r0 + 1:
		fail("six pieces: no six-piece power, mastery or relic (damage %.2f)" % p.dmg)
