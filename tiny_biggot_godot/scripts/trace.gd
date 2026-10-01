class_name Trace
extends RefCounted
## One line of deterministic game state for replay comparisons (--trace).
## A seeded autopilot run must produce byte-identical traces before and after
## a refactor; any change in behaviour, or in how many random numbers the game
## draws, shows up as a differing line.

static func _f(v: float) -> String:
	return "%.4f" % v

static func line(tick: int) -> String:
	var p := G.player
	if p == null or G.room == null:
		return "%d -" % tick
	var parts := [str(tick), String(G.state), str(G.floor_index), str(G.floor_d.get("depth", 0)), G.room.type,
		str(G.room.seed_value), str(G.locked), _f(p.x), _f(p.y), str(p.hp), str(p.max_hp), str(p.armor),
		str(p.gold), _f(p.gold_frac), str(p.bombs), str(p.keys), str(p.potions), str(p.level), str(p.xp),
		str(p.kills), str(p.pending), str(p.charges), _f(p.fire_cd), _f(p.invuln), p.weapon["id"]]
	var gear := []
	for sl in Gear.SLOTS:
		gear.append(p.gear[sl]["id"] if p.gear.get(sl) != null else "-")
	parts.append(",".join(gear))
	var rel := []
	for r in p.relics:
		rel.append(r["id"])
	parts.append(",".join(rel))
	var tk: Array = p.traits.keys()
	tk.sort()
	var tr := []
	for k in tk:
		tr.append("%s:%d" % [k, p.traits[k]])
	parts.append(",".join(tr))
	for k in ["dmg", "rate", "speed", "crit", "life", "size"]:
		parts.append(_f(p.get(k)))
	var es := []
	for e in G.enemies:
		es.append("%s/%s/%s/%s" % [e.type, _f(e.hp), _f(e.x), _f(e.y)])
	parts.append(";".join(es))
	var sx := 0.0
	for i in EBullets.n:
		sx += EBullets.bx[i] + EBullets.by[i] * 3
	parts.append("eb=%d/%s" % [EBullets.n, _f(sx)])
	var px := 0.0
	for b in G.pbullets:
		px += b.x + b.y * 3 + b.dmg
	parts.append("pb=%d/%s" % [G.pbullets.size(), _f(px)])
	parts.append("pk=%d bo=%d zo=%d fam=%d tf=%d obj=%d" % [G.pickups.size(), G.bombs.size(), G.zones.size(),
		G.familiars.size(), G.temp_fams.size(), G.room.objects.size()])
	return " | ".join(parts)
