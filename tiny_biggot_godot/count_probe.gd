extends SceneTree
func _init() -> void:
	var w = load("res://scripts/data/weapons.gd").all()
	var r = load("res://scripts/data/relics.gd").all()
	var g = load("res://scripts/data/gear.gd").all()
	var t = load("res://scripts/data/traits.gd").all()
	var GD = load("res://scripts/data/game_data.gd")
	var foes := 0; var champs := 0; var minis := 0
	for k in GD.ENEMIES:
		var d = GD.ENEMIES[k]
		if d.get("champion", false): champs += 1
		elif d.get("mini", false): minis += 1
		elif not k in ["dummy", "target", "goblin", "mimic", "shadow", "casingrat"]: foes += 1
	var slots := {}
	for x in g: slots[x["slot"]] = slots.get(x["slot"], 0) + 1
	print("weapons ", w.size(), " relics ", r.size(), " gear ", g.size(), " ", slots, " traits ", t.size())
	print("foes ", foes, " minibosses ", minis, " champions ", champs, " guardians ", GD.BOSSES.size(), " floors ", GD.floors().size(), " heroes ", GD.heroes().size())
	print("combos ", load("res://scripts/data/synergies.gd").COMBOS.size(), " tag synergies ", load("res://scripts/data/synergies.gd").TAG_SYNERGIES.size())
	quit()
