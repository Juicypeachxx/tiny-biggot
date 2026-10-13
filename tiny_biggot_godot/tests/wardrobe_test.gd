extends Node
## 14.2 the WARDROBE page (game.gd open_wardrobe / update_wardrobe, menu_view draw_wardrobe). Run:
##   godot --headless --path . res://tests/wardrobe_test.tscn -- --no-save
## It is on the title menu and in the pause menu, opens on the last set looked at, scrolls, goes
## back where it came from, and the pause menu's other items still work.
## Prints "wardrobe test: PASSED" or a FAIL line per problem.

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL wardrobe: ", msg)

func _ready() -> void:
	await get_tree().process_frame
	if not G.title_items().has("WARDROBE"):
		fail("no WARDROBE on the title menu")
	G.state = &"title"
	G.menu = G.title_index("WARDROBE")
	G.open_wardrobe(&"title")
	G.menu = Gear.SETS.size() - 1
	G.update_wardrobe()
	if G.wardrobe_i != Gear.SETS.size() - 1 or MenuView.ward_top() + MenuView.WARD_ROWS < Gear.SETS.size():
		fail("the list does not reach its last set (top %d)" % MenuView.ward_top())
	G.wardrobe_from = &"title"
	G.state = &"title"
	if G.title_items()[G.title_index("WARDROBE")] != "WARDROBE":
		fail("the title menu lost its place")
	G.new_run()
	var items := G.pause_items()
	if items.find("WARDROBE") != items.find("OPTIONS") - 1 or items[items.size() - 1] != "ABANDON RUN":
		fail("the pause menu is %s" % [items])
	G.open_wardrobe(&"pause")
	if G.state != &"wardrobe" or G.menu != Gear.SETS.size() - 1:
		fail("the page did not open on the last set looked at")
	print("wardrobe test: PASSED" if fails == 0 else "wardrobe test: %d FAILED" % fails)
	get_tree().quit()
