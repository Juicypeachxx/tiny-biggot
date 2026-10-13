extends Node
## Balance report (design spec step 9): measures new content against the
## originals instead of guessing. Run: godot --headless --path . res://tests/balance_report.tscn
## Weapons: base damage per second (Weapons.weapon_dps, before procs)
## compared with the median of original weapons of the same type and rarity.
## Flags anything outside 0.6x-1.6x of that median.

func _median(a: Array) -> float:
	if a.is_empty():
		return 0.0
	var s := a.duplicate()
	s.sort()
	return s[s.size() / 2]

func _ready() -> void:
	var by := {}       # kind:rarity -> [dps] of originals
	var by_kind := {}  # kind -> [dps]
	for w in Weapons.all():
		if w["new"]:
			continue
		var d := Weapons.weapon_dps(w)
		by.get_or_add(w["kind"] + ":" + w["rarity"], []).append(d)
		by_kind.get_or_add(w["kind"], []).append(d)
	var flagged := 0
	var n := 0
	print("[balance] weapon dps vs original median of the same type and rarity (flag outside 0.6x-1.6x)")
	for w in Weapons.all():
		if not w["new"] or Weapons.HERO_WEAPON.values().has(w["id"]):
			continue
		n += 1
		var key: String = w["kind"] + ":" + w["rarity"]
		var ref := _median(by.get(key, by_kind.get(w["kind"], [])))
		if ref <= 0:
			print("[balance]   %-16s no original %s to compare" % [w["id"], w["kind"]])
			continue
		var r := Weapons.weapon_dps(w) / ref
		if r < 0.6 or r > 1.6:
			flagged += 1
			print("[balance]   %-16s %-8s %-7s dps %6.1f  ref %6.1f  x%.2f  %s" % [w["id"], w["kind"], w["rarity"],
				Weapons.weapon_dps(w), ref, r, "HIGH" if r > 1.6 else "LOW"])
	print("[balance] %d of %d new weapons flagged" % [flagged, n])
	# Guardians: health per floor, originals vs new.
	print("[balance] guardian health by floor:")
	var fl := GameData.floors()
	for i in fl.size():
		var b: Dictionary = GameData.BOSSES[fl[i]["boss"]]
		print("[balance]   floor %2d %-24s %5d hp  foe scale x%.2f" % [i + 1, b["name"], b["hp"], 1 + 0.42 * i])
	get_tree().quit()
