extends Node
## Proves the ported item effects match the ORIGINAL Ruby code exactly.
## tests/ruby_effects.json is produced by running the untouched Ruby scripts
## (tools/gen_ruby_effects.rb): for every hero, a fresh player gets one relic,
## one trait at max rank, one family bonus, one skill node, one gear piece, one
## full gear set or one weapon, and every player field that changed is
## recorded. This test does the same in Godot and compares field by field
## (both "what changed" and "to what value").
## Usage: godot --headless --path . res://tests/effects_test.tscn

const EPS := 1e-6
var _fails := 0
var _checked := 0

func _ready() -> void:
	G.player = null
	var f := FileAccess.open("res://tests/ruby_effects.json", FileAccess.READ)
	var ref: Dictionary = JSON.parse_string(f.get_as_text())
	for h in GameData.HEROES:
		var r: Dictionary = ref[h["id"]]
		var base := _snap(_fresh(h))
		_cmp_base(h["id"], base, r["base"])
		for id in r["relics"]:
			var p := _fresh(h)
			G.add_relic(p, Relics.by_id(id))
			_cmp("%s relic %s" % [h["id"], id], base, _snap(p), r["relics"][id])
		for id in r["traits"]:
			var p := _fresh(h)
			for k in Traits.by_id(id)["max"]:
				Traits.apply(id, p)
			_cmp("%s trait %s" % [h["id"], id], base, _snap(p), r["traits"][id])
		for key in r["bonus"]:
			var p := _fresh(h)
			Traits.apply_bonus(key.left(-1), int(key.right(1)), p)
			_cmp("%s bonus %s" % [h["id"], key], base, _snap(p), r["bonus"][key])
		for n in r["nodes"]:
			var p := _fresh(h)
			Traits.apply_node(n, p)
			_cmp("%s node %s" % [h["id"], n], base, _snap(p), r["nodes"][n])
		for id in r["gear"]:
			var p := _fresh(h)
			if id.begins_with("set:"):
				for g in Gear.all():
					if g["set"] == id.substr(4):
						Gear.equip_gear(p, g)
			else:
				Gear.equip_gear(p, Gear.by_id(id))
			_cmp("%s gear %s" % [h["id"], id], base, _snap(p), r["gear"][id])
		for id in r["weapons"]:
			var p := _fresh(h)
			Weapons.equip_weapon(p, Weapons.by_id(id))
			var s := _snap(p)
			s["wdmg"] = Weapons.wdmg(p)
			s["wrate"] = Weapons.wrate(p)
			s["wrange"] = Weapons.wrange(p)
			_cmp("%s weapon %s" % [h["id"], id], base, s, r["weapons"][id])
	print("effects test: %d item applications compared with the Ruby original, %s" % [_checked,
		"ALL MATCH" if _fails == 0 else "%d MISMATCHES" % _fails])
	get_tree().quit(1 if _fails > 0 else 0)

func _fresh(h: Dictionary) -> Player:
	var p := Player.new(h)
	Weapons.equip_weapon(p, Weapons.by_id(Weapons.HERO_WEAPON[h["id"]]))
	G.player = p
	return p

## Every number/bool field of the player, plus the non-zero gear hooks.
func _snap(p: Player) -> Dictionary:
	var out := {}
	for prop in p.get_property_list():
		if not (prop["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE):
			continue
		var v = p.get(prop["name"])
		if v is int or v is float or v is bool:
			out[prop["name"]] = v
	out["spread"] = p.spread
	var gf := {}
	for k in p.gf:
		if p.gf[k] != 0:
			gf[k] = p.gf[k]
	out["gf"] = gf
	return out

func _same(a: Variant, b: Variant) -> bool:
	if a == null or b == null:
		return a == b
	if (a is int or a is float) and (b is int or b is float):
		return absf(float(a) - float(b)) <= EPS * maxf(1.0, absf(float(b)))
	return a == b

func _fail(what: String) -> void:
	_fails += 1
	if _fails <= 40:
		print("MISMATCH ", what)

func _cmp_base(hero: String, base: Dictionary, want: Dictionary) -> void:
	_checked += 1
	for k in want:
		if k == "gf" or not base.has(k):
			continue
		if not _same(base[k], want[k]):
			_fail("%s base %s: godot %s ruby %s" % [hero, k, base[k], want[k]])

func _cmp(what: String, base: Dictionary, got: Dictionary, want: Dictionary) -> void:
	_checked += 1
	# Fields Ruby changed must change identically in Godot ...
	for k in want:
		if k == "gf":
			continue
		if not got.has(k):
			_fail("%s: field %s missing in Godot" % [what, k])
		elif not _same(got[k], want[k]):
			_fail("%s: %s godot %s ruby %s" % [what, k, got[k], want[k]])
	# ... and Godot must not change anything Ruby left alone.
	for k in got:
		if k == "gf" or want.has(k) or not base.has(k):
			continue
		if not _same(got[k], base[k]):
			_fail("%s: %s changed in Godot (%s -> %s) but not in Ruby" % [what, k, base[k], got[k]])
	var wgf: Dictionary = want.get("gf", base["gf"])
	if wgf.size() != got["gf"].size():
		_fail("%s: gf godot %s ruby %s" % [what, got["gf"], wgf])
	else:
		for k in wgf:
			if not _same(got["gf"].get(k), wgf[k]):
				_fail("%s: gf.%s godot %s ruby %s" % [what, k, got["gf"].get(k), wgf[k]])
