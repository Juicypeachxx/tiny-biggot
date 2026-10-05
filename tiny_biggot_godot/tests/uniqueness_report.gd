extends Node
## Writes UNIQUENESS.md (ROADMAP 4.1): every weapon, relic and gear piece with a "signature"
## worked out from its data, and the groups whose signatures are the same or nearly so.
## Run: godot --headless --path . res://tests/uniqueness_report.tscn -- --no-save
##
## A signature leaves numbers out on purpose: two swords that differ by 10% damage are one sword.
##   weapon: attack kind | mechanics it changes from its kind (more shots, homing, bounces, ...)
##           | the stats it gives | its hooks | its effects
##   relic:  its effects
##   gear:   slot | the stats it gives | its hooks | its effects
## An effect is "op:stat" for a stat change, "trigger[if cond]>action+action" for a triggered one.
## "Same": identical signatures. "Near": the same apart from which plain stats it gives
## (a weapon: same kind and same effects and mechanics; gear: same slot and same effects).

const OUT := "res://UNIQUENESS.md"
const MECH_KEYS := ["count", "pierce", "homing", "bounce", "chain", "range", "arc", "width", "spread"]

func _ready() -> void:
	var lines := PackedStringArray()
	var weapons := []
	for w in Weapons.all():
		weapons.append({ "id": w["id"], "name": w["name"], "new": w["new"], "sig": _weapon_sig(w), "near": _weapon_near(w),
			"plain": _mech(w) == "" and w["hooks"].is_empty() and _triggered(w["effects"]) == 0 })
	var relics := []
	for r in Relics.all():
		var s := _effects_sig(r["effects"])
		relics.append({ "id": r["id"], "name": r["name"], "new": r["new"], "sig": s, "near": _near_effects(r["effects"]),
			"plain": _triggered(r["effects"]) == 0 })
	var gear := []
	for g in Gear.all():
		gear.append({ "id": g["id"], "name": g["name"], "new": g["new"], "sig": _gear_sig(g), "plain": g["hooks"].is_empty() and _triggered(g["effects"]) == 0,
			"near": g["slot"] + " | " + _tuples_sig(g["stats"]) + " | " + _near_effects(g["effects"]) + " | " + _hooks_sig(g["hooks"]) })
	lines.append("# Uniqueness: what every weapon, relic and gear piece does")
	lines.append("")
	lines.append("Made by `tests/uniqueness_report.tscn` from the game's data (ROADMAP 4.1). Do not edit by hand:")
	lines.append("run it again after changing items. Numbers are left out on purpose: two swords that differ by")
	lines.append("10% damage are one sword. ORIGINAL items are the classic game and are not changed.")
	lines.append("Not seen by the signature: what a hero does with a signature weapon (`Weapons.HERO_WEAPON`),")
	lines.append("and the look of an attack. A gear piece's set counts for \"same\", not for \"near\".")
	lines.append("")
	lines.append("- **Same**: identical signatures.")
	lines.append("- **Near**: the same once it is set aside how much, and in which way, a stat is changed; for a
  weapon also which plain stats it gives (same attack kind, mechanics and triggered effects).
- **Numbers only**: no triggered effect, no hook and (weapons) no mechanic of its own beyond its
  attack kind: it only changes numbers.")
	lines.append("")
	var summary := []
	for part in [["Weapons", weapons], ["Relics", relics], ["Gear", gear]]:
		var same := _groups(part[1], "sig")
		var near := _groups(part[1], "near")
		summary.append([part[0], part[1], same, near])
	lines.append("| | Items | Original | New | In a \"same\" group | In a \"near\" group | New items in a \"near\" group | Numbers only (new) |")
	lines.append("|---|---|---|---|---|---|---|---|")
	for s in summary:
		var items: Array = s[1]
		var news := items.filter(func(x): return x["new"]).size()
		var plain_new := items.filter(func(x): return x["plain"] and x["new"]).size()
		lines.append("| %s | %d | %d | %d | %d | %d | %d | %d (%d) |" % [s[0], items.size(), items.size() - news, news,
			_count_in(s[2]), _count_in(s[3]), _count_in(s[3], true), items.filter(func(x): return x["plain"]).size(), plain_new])
	lines.append("")
	for s in summary:
		lines.append("## %s" % s[0])
		lines.append("")
		lines.append("### Same signature (%d groups)" % s[2].size())
		lines.append("")
		_write_groups(lines, s[2])
		lines.append("### Near (%d groups)" % s[3].size())
		lines.append("")
		_write_groups(lines, s[3])
		var plain: Array = s[1].filter(func(x): return x["plain"])
		lines.append("### Numbers only (%d, %d of them new)" % [plain.size(), plain.filter(func(x): return x["new"]).size()])
		lines.append("")
		var pn := []
		for x in plain:
			pn.append("%s%s" % [x["id"], "" if x["new"] else " (ORIGINAL)"])
		lines.append(", ".join(pn) if not pn.is_empty() else "None.")
		lines.append("")
		lines.append("### Every %s" % s[0].to_lower().trim_suffix("s"))
		lines.append("")
		lines.append("| id | name | | signature |")
		lines.append("|---|---|---|---|")
		for x in s[1]:
			lines.append("| %s | %s | %s | `%s` |" % [x["id"], x["name"], "new" if x["new"] else "ORIGINAL", x["sig"]])
		lines.append("")
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string("\n".join(lines) + "\n")
	f.close()
	for s in summary:
		print("[unique] %s: %d items, %d in a same group (%d groups), %d in a near group (%d groups), %d of them new" % [s[0],
			s[1].size(), _count_in(s[2]), s[2].size(), _count_in(s[3]), s[3].size(), _count_in(s[3], true)])
	print("uniqueness report: wrote ", ProjectSettings.globalize_path(OUT))
	get_tree().quit()

## Groups of two or more by key, largest first.
func _groups(items: Array, key: String) -> Array:
	var by := {}
	for x in items:
		if not by.has(x[key]):
			by[x[key]] = []
		by[x[key]].append(x)
	var out := []
	for k in by:
		if by[k].size() > 1:
			out.append([k, by[k]])
	out.sort_custom(func(a, b): return a[1].size() > b[1].size() or (a[1].size() == b[1].size() and a[0] < b[0]))
	return out

func _count_in(groups: Array, only_new: bool = false) -> int:
	var n := 0
	for g in groups:
		for x in g[1]:
			if not only_new or x["new"]:
				n += 1
	return n

func _write_groups(lines: PackedStringArray, groups: Array) -> void:
	if groups.is_empty():
		lines.append("None.")
		lines.append("")
		return
	for g in groups:
		var names := []
		for x in g[1]:
			names.append("%s%s" % [x["id"], "" if x["new"] else " (ORIGINAL)"])
		lines.append("- %d: `%s`  \n  %s" % [g[1].size(), g[0], ", ".join(names)])
	lines.append("")

func _mech(w: Dictionary) -> String:
	var base: Dictionary = Weapons.ARCH[w["kind"]]
	var out := []
	for k in MECH_KEYS:
		if not w.has(k):
			continue
		var a = base.get(k, 0)
		var b = w[k]
		if (a == 0 or a == 0.0) and b != 0 and b != 0.0:
			out.append(k)              # gains a mechanic its kind does not have
		elif k == "count" and b > a:
			out.append("count+")
		elif k == "count" and b < a:
			out.append("count-")
		elif k in ["pierce", "bounce", "chain"] and b > a:
			out.append(k + "+")
	for k in Arsenal.TWISTS + Charged.TWISTS:
		if w.has(k) and not base.has(k) and w[k]:
			# A twist on a ROADMAP 4.6 kind (arsenal.gd, charged.gd). A list or a word is part of the
			# mechanic (a combo's steps, a mortar's zone); a number is not.
			var v = w[k]
			if v is Array:
				out.append(k + "=" + "/".join(v))
			elif v is String:
				out.append(k + "=" + v)
			else:
				out.append(k)
	return ",".join(out)

func _weapon_sig(w: Dictionary) -> String:
	return "%s | %s | %s | %s | %s" % [w["kind"], _mech(w), _tuples_sig(w["stats"]), _hooks_sig(w["hooks"]), _effects_sig(w["effects"])]

func _weapon_near(w: Dictionary) -> String:
	return "%s | %s | %s | %s" % [w["kind"], _mech(w), _hooks_sig(w["hooks"]), _near_effects(w["effects"])]

func _gear_sig(g: Dictionary) -> String:
	return "%s%s | %s | %s | %s" % [g["slot"], _set_sig(g), _tuples_sig(g["stats"]), _hooks_sig(g["hooks"]), _effects_sig(g["effects"])]

func _set_sig(g: Dictionary) -> String:
	return " set:" + str(g["set"]) if g["set"] != null else ""

func _tuples_sig(tuples: Array) -> String:
	var out := []
	for kv in tuples:
		out.append(str(kv[0]))
	out.sort()
	return ",".join(out)

func _hooks_sig(hooks: Array) -> String:
	var out := []
	for kv in hooks:
		out.append(str(kv[0]))
	out.sort()
	return ",".join(out)

func _effects_sig(effects: Array) -> String:
	var out := []
	for e in effects:
		out.append(_one_effect(e))
	out.sort()
	return "; ".join(out)

## Effects with the way a stat is changed set aside ("add", "mul" and "pct" of damage are all
## "stat:dmg"), for "near".
func _near_effects(effects: Array) -> String:
	var out := []
	for e in effects:
		if e is Array and str(e[0]) in ["add", "mul", "pct"]:
			out.append("stat:" + str(e[1]))
			continue
		out.append(_one_effect(e))
	out.sort()
	return "; ".join(out)

## How many effects are more than a plain stat change.
func _triggered(effects: Array) -> int:
	var n := 0
	for e in effects:
		if not (e is Array and str(e[0]) in ["add", "mul", "pct"]):
			n += 1
	return n

func _one_effect(e) -> String:
	if e is Array:
		return "%s:%s" % [e[0], e[1] if e.size() > 1 else ""]
	if e is Dictionary:
		var head: String = str(e.get("on", "?"))
		if e.has("if"):
			head += "[if " + str(e["if"]) + "]"
		var acts := []
		for a in e.get("do", []):
			var s := str(a[0])
			if s in ["status", "status_area", "buff", "vfx"] and a.size() > 1:
				s += ":" + str(a[1])   # which status or stat is part of what it does
			acts.append(s)
		return head + ">" + "+".join(acts)
	return str(e)
