extends Node
## 14.3 hidden trait combos (synergies.gd "hidden" rows, effects.gd _found_hidden). Run:
##   godot --headless --path . res://tests/combos_test.tscn -- --no-save
## Every hidden combo names two real traits; taking both switches it on, the first time is saved
## as found and trait cards then name the partner; every line fits the pixel font.
## Prints "combos test: PASSED" or a FAIL line per problem.

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL combos: ", msg)

func _ready() -> void:
	await get_tree().process_frame
	seed(143)
	Meta.meta["combos_found"] = {}
	var hid := Synergies.COMBOS.filter(func(c): return c.get("hidden", false))
	if hid.size() < 12:
		fail("only %d hidden combos" % hid.size())
	var names := {}
	for t in Traits.all():
		names[t["name"]] = true
	for c in hid:
		if c["needs"].size() != 2:
			fail("%s needs %d things" % [c["id"], c["needs"].size()])
		for n in c["needs"]:
			if not String(n).begins_with("trait:") or not Traits.has(String(n).trim_prefix("trait:")):
				fail("%s needs %s, not a trait" % [c["id"], n])
		if names.has(c["name"]):
			fail("%s shares its name with a trait" % c["name"])
		for ch in c["name"] + c["desc"] + "HIDDEN COMBO FOUND: ":
			if not ch in Gfx.FONT_CHARS:
				fail("'%s' not in the font: %s" % [ch, c["desc"]])
	G.hero_index = 0
	G.new_run()
	G.state = &"play"
	var p := G.player
	G.take_trait(Traits.by_id("z_static"))
	if p.synergies.has("combo:t_stormfront"):
		fail("STORMFRONT on with one trait")
	if not Effects.found_partners("z_static").is_empty():
		fail("a combo not yet found is shown on a card")
	G.take_trait(Traits.by_id("z_thunderstep"))
	if not p.synergies.has("combo:t_stormfront"):
		fail("STORMFRONT did not switch on")
	if not Meta.meta["combos_found"].has("t_stormfront"):
		fail("the find was not kept")
	var pr := Effects.found_partners("z_static")
	if pr.is_empty() or pr[0][0] != "z_thunderstep":
		fail("the card does not name THUNDER STEP (%s)" % [pr])
	Meta.meta["combos_found"] = {}
	print("combos test: PASSED" if fails == 0 else "combos test: %d FAILED" % fails)
	get_tree().quit()
