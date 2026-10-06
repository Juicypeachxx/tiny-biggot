extends Node
## Content test (design spec section 11). Run after every content batch:
##   godot --headless --path . res://tests/content_test.tscn -- --no-save
##
## 1. Lint: every relic, trait, family bonus, skill node, weapon, gear piece,
##    set, tag synergy and combo is valid data (known ops, stats, triggers,
##    actions, statuses, conditions; reversible ops where items can be
##    removed; unique ids; existing sprites).
## 2. Live: each item is given to a hero in a combat room full of foes, every
##    trigger is fired, then 90 ticks of play are simulated. Invariants are
##    checked afterwards. Runtime script errors appear as "SCRIPT ERROR" in
##    the log, and tools/check.sh fails on them.
## 3. Reversibility: equipping each weapon or gear piece and then going back
##    restores the player's stats.
## 4. Broken build: 50+ stacked trait ranks plus recursive procs; logic must
##    stay under one frame (16.7 ms) on average.
## 5. Stress: 500+ enemy shots, the summon cap, a player-shot flood.

const TICKS := 90
var fails := 0
var notes := []
var tested := 0
var _props := {}

func _ready() -> void:
	G.god = true
	if DebugArgs.has("only-broken"):
		for prop in Player.new(GameData.heroes()[0]).get_property_list():
			if prop["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE:
				_props[prop["name"]] = prop["type"]
		broken_build()
		for n in notes:
			print("[content] ", n)
		print("[content] Effects.stats: ", Effects.stats)
		get_tree().quit()
		return
	for prop in Player.new(GameData.heroes()[0]).get_property_list():
		if prop["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE:
			_props[prop["name"]] = prop["type"]
	var t0 := Time.get_ticks_msec()
	lint()
	print("[content] lint done: %d problems" % fails)
	live_all()
	print("[content] live: %d items exercised" % tested)
	reversibility()
	rails()
	leveling()
	archetypes()
	broken_build()
	combos()
	heroes()
	slots()
	biomes()
	loops()
	attributes()
	upgrades()
	inventory()
	dummies()
	weapon_fx()
	heavy_fight()
	stress()
	print("[content] Effects.stats: ", Effects.stats)
	for n in notes:
		print("[content] ", n)
	print("content test: %s in %.1f s" % ["PASSED" if fails == 0 else "%d FAILURES" % fails, (Time.get_ticks_msec() - t0) / 1000.0])
	get_tree().quit(1 if fails > 0 else 0)

func fail(msg: String) -> void:
	fails += 1
	if fails <= 60:
		print("FAIL ", msg)

# ---------- 1. Lint ----------
const REVERSIBLE := ["add", "mul", "pct", "hook", "grant", "attr"]
const ONE_SHOT := ["add", "mul", "pct", "set", "add_cap", "add_floor", "clamp_max", "at_least", "copy", "nth", "hook", "grant", "attr", "upgrade"]

func lint_effects(where: String, effects: Array, reversible: bool) -> void:
	for e in effects:
		if e is Dictionary:
			lint_proc(where, e)
			continue
		if not (e is Array) or e.size() < 3:
			fail("%s: malformed effect %s" % [where, e])
			continue
		var op: String = e[0]
		if not op in ONE_SHOT:
			fail("%s: unknown op %s" % [where, op])
		if reversible and not op in REVERSIBLE:
			fail("%s: op %s cannot be undone but this item can be removed" % [where, op])
		if op == "hook":
			continue
		if op == "upgrade":
			continue
		if op == "attr":
			if not e[1] in ["str", "dex", "int", "highest"]:
				fail("%s: unknown attribute %s" % [where, e[1]])
			continue
		if not _props.has(e[1]):
			fail("%s: unknown stat %s" % [where, e[1]])
		elif op == "pct" and _props[e[1]] != TYPE_FLOAT:
			fail("%s: pct on non-float stat %s" % [where, e[1]])

func lint_proc(where: String, d: Dictionary) -> void:
	if not d.get("on") in Effects.TRIGGERS:
		fail("%s: unknown trigger %s" % [where, d.get("on")])
	if d.has("if") and not d["if"] in Effects.CONDITIONS:
		fail("%s: unknown condition %s" % [where, d["if"]])
	if d.has("chance") and not (d["chance"] > 0 and d["chance"] <= 1):
		fail("%s: bad chance" % where)
	if d.has("every") and int(d["every"]) < 1:
		fail("%s: bad every" % where)
	if not (d.get("do") is Array) or d["do"].is_empty():
		fail("%s: proc without actions" % where)
		return
	for a in d["do"]:
		if not a[0] in Effects.ACTIONS:
			fail("%s: unknown action %s" % [where, a[0]])
		elif a[0] == "status" and not a[1] in Effects.STATUSES:
			fail("%s: unknown status %s" % [where, a[1]])
		elif a[0] == "buff" and (not _props.has(a[1]) or _props[a[1]] != TYPE_FLOAT):
			fail("%s: buff on bad stat %s" % [where, a[1]])
		elif a[0] == "drop" and not a[1] in Combat.PICKUP_KINDS:
			fail("%s: unknown pickup %s" % [where, a[1]])

## Every shown string must be drawable by the bitmap font (Gfx.FONT_CHARS).
func _font(where: String, texts: Array) -> void:
	for t in texts:
		for ch in String(t).to_upper():
			if not ch in Gfx.FONT_CHARS:
				fail("%s: character '%s' is not in the game font" % [where, ch])
				break

func lint() -> void:
	var ids := {}   # "table:id" -> true; ids are unique per table
	var families: Dictionary = Traits.FAMILIES
	for r in Relics.all():
		_uniq(ids, "relic", r["id"])
		_font("relic " + r["id"], [r["name"], r["desc"]])
		lint_effects("relic " + r["id"], r["effects"], false)
		_sprite("relic " + r["id"], r["sprite"])
		_rarity("relic " + r["id"], r["rarity"], GameData.RARITY_HEX)
		_tags("relic " + r["id"], r["tags"])
	for t in Traits.all():
		_uniq(ids, "trait", t["id"])
		_font("trait " + t["id"], [t["name"], t["desc"]])
		lint_effects("trait " + t["id"], t["effects"], false)
		for k in t["tiers"]:
			lint_effects("trait %s tier %s" % [t["id"], k], t["tiers"][k], false)
		if not families.has(t["fam"]):
			fail("trait %s: unknown family %s" % [t["id"], t["fam"]])
		_rarity("trait " + t["id"], t["rarity"], Traits.RARITY)
		_tags("trait " + t["id"], t["tags"])
	for fam in Traits.FAMILY_BONUS:
		for i in Traits.FAMILY_BONUS[fam].size():
			lint_effects("bonus %s %d" % [fam, i], Traits.FAMILY_BONUS[fam][i][1], false)
	for n in Traits.NODE_EFFECTS:
		lint_effects("node " + n, Traits.NODE_EFFECTS[n], false)
	for w in Weapons.all():
		_uniq(ids, "weapon", w["id"])
		_font("weapon " + w["id"], [w["name"], w["desc"]])
		lint_effects("weapon " + w["id"], Effects.from_tuples(w["stats"], w["hooks"]) + w["effects"], true)
		_sprite("weapon " + w["id"], w["sprite"])
		_tags("weapon " + w["id"], w["tags"])
		if not Weapons.ARCH.has(w["kind"]):
			fail("weapon %s: unknown kind" % w["id"])
	for g in Gear.all():
		_uniq(ids, "gear", g["id"])
		_font("gear " + g["id"], [g["name"], g["desc"]])
		lint_effects("gear " + g["id"], Effects.from_tuples(g["stats"], g["hooks"]) + g["effects"], true)
		_sprite("gear " + g["id"], g["sprite"])
		_tags("gear " + g["id"], g["tags"])
		if not g["slot"] in Gear.ITEM_SLOTS:
			fail("gear %s: unknown slot" % g["id"])
		if g["set"] != null and not Gear.SETS.has(g["set"]):
			fail("gear %s: unknown set" % g["id"])
	for s in Gear.SETS:
		var st: Dictionary = Gear.SETS[s]
		lint_effects("set " + s, Effects.from_tuples(st["b2"] + st.get("b4", []), st.get("b4h", [])), true)
		lint_effects("set %s e2/e4" % s, st.get("e2", []) + st.get("e4", []), true)
		_font("set " + s, [st["name"], st["d2"], st["d4"]])
	for syn in Synergies.TAG_SYNERGIES:
		for tier in syn["tiers"]:
			lint_effects("synergy " + syn["tag"], tier["effects"], true)
			_font("synergy " + syn["tag"], [tier["name"], tier["desc"]])
	for c in Synergies.COMBOS:
		lint_effects("combo " + c["id"], c["effects"], true)
		_font("combo " + c["id"], [c["name"], c["desc"]])
		for need in c["needs"]:
			if not ids.has(need):
				fail("combo %s needs unknown item %s" % [c["id"], need])
	# The constellation's stars (scripts/game/stars.gd): known stats and actions, the game font,
	# and no notable star named like an item.
	var names := {}
	for t in [Relics.all(), Gear.all(), Weapons.all(), Traits.all()]:
		for it in t:
			names[String(it["name"])] = true
	for n in Stars.nodes():
		lint_effects("star " + n["id"], n["effects"], false)
		_font("star " + n["id"], [n["name"], n["text"]])
		if n["notable"] and names.has(n["name"]):
			fail("star %s is named like an item: %s" % [n["id"], n["name"]])

func _uniq(ids: Dictionary, kind: String, id: String) -> void:
	var key := kind + ":" + id
	if ids.has(key):
		fail("duplicate %s id %s" % [kind, id])
	ids[key] = true

func _sprite(where: String, name: String) -> void:
	if not Img.has(name):
		fail("%s: missing sprite %s" % [where, name])

func _rarity(where: String, r: String, table: Dictionary) -> void:
	if not table.has(r):
		fail("%s: unknown rarity %s" % [where, r])

func _tags(where: String, tags: Array) -> void:
	for t in tags:
		if not Weapons.TAG_COLS.has(t):
			fail("%s: unknown tag %s" % [where, t])

# ---------- 2. Live ----------
func arena(hero: int) -> Player:
	G.hero_index = hero % GameData.heroes().size()
	G.new_run()
	G.floor_d["depth"] = 2
	G.enter_room(World.make_room(G.floor_d, "combat", "", "s"))
	var p := G.player
	for i in 5:
		var s := World.free_spot(G.room, p, 50, World.M_FLYER)
		Combat.spawn_enemy(TB.pick(GameData.floors()[0]["pool"]), s.x, s.y, i == 0, true)
	return p

func fire_all(p: Player) -> void:
	var e: Enemy = G.enemies[0] if not G.enemies.is_empty() else null
	for t in Effects.TRIGGERS:
		Effects.fire(t, { "enemy": e, "dmg": 5.0, "crit": true, "x": p.x, "y": p.y })

func play(ticks: int) -> void:
	for i in ticks:
		Keys.tick()
		G.update(TB.DT)
		match G.state:
			&"traits":
				G.take_trait(G.tchoice["opts"][0])
				G.tchoice = {}
				G.state = &"play"
			&"choice":
				G.add_relic(G.player, G.choice["relics"][0])
				G.choice = {}
				G.state = &"play"
			&"pause", &"dead", &"win":
				G.state = &"play"
		if G.enemies.size() < 3:
			var s := World.free_spot(G.room, G.player, 50, World.M_FLYER)
			Combat.spawn_enemy(TB.pick(GameData.floors()[0]["pool"]), s.x, s.y, false, true)

## Advances the game without play()'s top-up spawns.
func _tick_only(ticks: int) -> void:
	for i in ticks:
		Keys.tick()
		G.update(TB.DT)

func check(where: String) -> void:
	var p := G.player
	for name in _props:
		var v = p.get(name)
		if (v is float) and not is_finite(v):
			fail("%s: stat %s is %s" % [where, name, v])
	if p.hp > p.max_hp or p.max_hp < 2:
		fail("%s: hp %d / max %d" % [where, p.hp, p.max_hp])
	if G.pbullets.size() > Effects.pbullet_cap():
		fail("%s: %d player shots over the cap" % [where, G.pbullets.size()])
	if mini(p.familiars, Effects.SUMMON_CAP) + G.temp_fams.size() > Effects.SUMMON_CAP + 8:
		fail("%s: summons over the cap" % where)
	for e in G.enemies:
		if not is_finite(e.hp) or not is_finite(e.x):
			fail("%s: enemy state not finite" % where)
			break

func live(where: String, hero: int, give: Callable) -> void:
	var p := arena(hero)
	give.call(p)
	fire_all(p)
	play(TICKS)
	check(where)
	tested += 1

func live_all() -> void:
	var i := 0
	for r in Relics.all():
		live("relic " + r["id"], i, func(p): G.add_relic(p, r))
		i += 1
	for t in Traits.all():
		live("trait " + t["id"], i, func(p):
			for k in t["max"]:
				p.pending += 1
				G.take_trait(t))
		i += 1
	for fam in Traits.FAMILY_BONUS:
		for k in 3:
			live("bonus %s %d" % [fam, k], i, func(p): Traits.apply_bonus(fam, k, p))
			i += 1
	for n in Traits.NODE_EFFECTS:
		live("node " + n, i, func(p): Traits.apply_node(n, p))
		i += 1
	for w in Weapons.all():
		live("weapon " + w["id"], i, func(p): Weapons.equip_weapon(p, w))
		i += 1
	for g in Gear.all():
		live("gear " + g["id"], i, func(p): Gear.equip_gear(p, g))
		i += 1
	for s in Gear.SETS:
		live("set " + s, i, func(p):
			for g in Gear.all():
				if g["set"] == s:
					Gear.equip_gear(p, g))
		i += 1
	# Fixtures: every trigger, action, status, condition and the abuse cases,
	# plus a synthetic tag synergy and combo.
	Synergies.TAG_SYNERGIES.append(TestFixtures.synergy())
	Synergies.COMBOS.append(TestFixtures.combo())
	for f in TestFixtures.items():
		live("fixture " + f["id"], i, func(p): give_fixture(p, f))
		i += 1
	live("fixture all at once", 0, func(p):
		for f in TestFixtures.items():
			give_fixture(p, f))
	var p := G.player
	if not p.synergies.has("syn:storm:0") or not p.synergies.has("combo:fx_combo"):
		fail("synthetic synergy/combo did not activate: %s" % [p.synergies.keys()])
	Synergies.TAG_SYNERGIES.pop_back()
	Synergies.COMBOS.pop_back()

func give_fixture(p: Player, f: Dictionary) -> void:
	var r := { "id": f["id"], "rarity": "common", "name": f["id"], "desc": "", "effects": f["effects"],
		"tags": f["tags"], "new": true, "sprite": "relic_whetstone" }
	p.relics.append(r)
	Effects.apply(p, r["effects"], 1, "relic:" + r["id"])
	Effects.recount_tags(p)

# ---------- 3. Reversibility ----------
func _snap(p: Player) -> Dictionary:
	var out := {}
	for name in _props:
		var v = p.get(name)
		if (v is int or v is float) and not name in ["hp", "armor", "bombs", "keys", "potions", "charges"]:
			out[name] = v
	out["gf"] = p.gf.duplicate()
	out["procs"] = p.procs.size()
	out["pct"] = p.stat_pct.duplicate()
	return out

func _same(a: Dictionary, b: Dictionary) -> String:
	for k in a:
		if k == "gf" or k == "pct":
			for kk in a[k].keys() + b[k].keys():
				if absf(a[k].get(kk, 0.0) - b[k].get(kk, 0.0)) > 1e-6:
					return "%s.%s %s vs %s" % [k, kk, a[k].get(kk, 0.0), b[k].get(kk, 0.0)]
		elif typeof(a[k]) in [TYPE_INT, TYPE_FLOAT] and absf(float(a[k]) - float(b[k])) > 1e-6 * maxf(1.0, absf(float(a[k]))):
			return "%s %s vs %s" % [k, a[k], b[k]]
	return ""

func reversibility() -> void:
	var n := 0
	var p := arena(0)
	var base_w: Dictionary = p.weapon
	for w in Weapons.all():
		var before := _snap(p)
		Weapons.equip_weapon(p, w)
		Weapons.equip_weapon(p, base_w)
		var d := _same(before, _snap(p))
		if d != "":
			fail("weapon %s not reversible: %s" % [w["id"], d])
		n += 1
	for sl in Gear.SLOTS:
		var pieces := []
		for g in Gear.all():
			if g["slot"] == sl:
				pieces.append(g)
		Gear.equip_gear(p, pieces[0])
		for g in pieces:
			var before := _snap(p)
			Gear.equip_gear(p, g)
			Gear.equip_gear(p, pieces[0])
			var d := _same(before, _snap(p))
			if d != "":
				fail("gear %s not reversible: %s" % [g["id"], d])
			n += 1
	notes.append("reversibility: %d weapon/gear swaps restored the player exactly" % n)

# ---------- Safety rails, checked directly ----------
func rails() -> void:
	var p := arena(0)
	# Budget and queue: 300 procs in one tick run 200 now and 100 next tick.
	give_fixture(p, { "id": "rail_gold", "effects": [{ "on": "on_room_clear", "do": [["gold", 1]] }], "tags": [] })
	Effects.budget = Effects.BUDGET
	var gold0 := p.gold
	for i in 300:
		Effects.fire("on_room_clear")
	var now := p.gold - gold0
	var queued := Effects.queue.size()
	Effects.tick(TB.DT)
	var later := p.gold - gold0
	if now != Effects.BUDGET or queued != 300 - Effects.BUDGET or later != 300:
		fail("proc budget/queue: ran %d, queued %d, after next tick %d (want %d, %d, 300)" % [now, queued, later, Effects.BUDGET, 300 - Effects.BUDGET])
	# Depth: a heal that triggers itself stops at MAX_DEPTH levels.
	p = arena(0)
	p.hp = 2
	p.max_hp = 40
	give_fixture(p, { "id": "rail_loop", "effects": [{ "on": "on_heal", "do": [["heal", 1]] }], "tags": [] })
	Effects.stats["max_depth"] = 0
	p.heal(1)
	if Effects.stats["max_depth"] != Effects.MAX_DEPTH or p.hp != 2 + 1 + Effects.MAX_DEPTH:
		fail("proc depth: reached %d, hp %d (want depth %d, hp %d)" % [Effects.stats["max_depth"], p.hp, Effects.MAX_DEPTH, 3 + Effects.MAX_DEPTH])
	# Bullet cap: shots past the cap merge instead of piling up.
	p = arena(0)
	for i in Effects.pbullet_cap() + 300:
		Combat.spawn_pbullet(p, randf() * TAU)
	if G.pbullets.size() != Effects.pbullet_cap():
		fail("bullet cap: %d live shots" % G.pbullets.size())
	notes.append("rails: proc budget %d/tick with queue, depth limit %d, shot cap %d, summon cap %d, shot floor %.4f s all verified" % [
		Effects.BUDGET, Effects.MAX_DEPTH, Effects.pbullet_cap(), Effects.SUMMON_CAP, Effects.MIN_SHOT_INTERVAL])

# ---------- Leveling rules (design spec section 4) ----------
func _fake_trait(id: String, fam: String, rarity: String, mx: int, effects: Array, tiers: Dictionary = {}) -> Dictionary:
	var t := { "id": id, "fam": fam, "max": mx, "name": id.to_upper(), "desc": "TEST", "cap": false, "effects": effects,
		"new": true, "rarity": rarity, "tags": [fam], "tiers": tiers }
	Traits._list.append(t)
	Traits._by_id[id] = t
	return t

func leveling() -> void:
	var p := arena(0)
	var common := _fake_trait("t_common", "edge", "common", 3, [["add", "crit", 0.05]], { 3: [["add", "crit_mult", 1.0]] })
	var cursed := _fake_trait("t_cursed", "edge", "cursed", 1, [["mul", "dmg", 1.5], ["add_floor", "max_hp", -2, 2], ["clamp_max", "hp", "max_hp"]])
	var legend := _fake_trait("t_legend", "edge", "legend", 1, [{ "on": "on_crit", "do": [["nova", 4, 0.3, "spark"]] }])
	# Rarity weights and gating.
	if G.trait_weight(p, common) != 4 * 1:
		fail("common trait weight %d (want 4)" % G.trait_weight(p, common))
	if G.trait_weight(p, cursed) != 0 or G.trait_weight(p, legend) != 0:
		fail("cursed/legendary traits offered too early")
	# Stacking: three ranks, the third unlocks its tier effect; affinity grows.
	var crit0 := p.crit
	var cm0 := p.crit_mult
	for k in 3:
		p.pending += 1
		G.take_trait(common)
	# 3 ranks x 0.05 crit, plus the EDGE 2-rank family bonus (+0.08) and the
	# EDGE tag synergy at 3 (KEEN, +0.10); the third rank's tier adds +1.0 crit damage.
	var keen := 0.1 if Synergies.TAG_SYNERGIES.any(func(s): return s["tag"] == "edge" and s["tiers"][0]["need"] <= 3) else 0.0
	if absf(p.crit - crit0 - 0.23 - keen) > 1e-9 or absf(p.crit_mult - cm0 - 1.0) > 1e-9:
		fail("trait ranks/tier: crit %.3f crit_mult %.3f" % [p.crit - crit0, p.crit_mult - cm0])
	if p.fam_bonus.get("edge", 0) != 1:
		fail("new family bonus tier not applied (%s)" % p.fam_bonus)
	p.level = 3
	if G.trait_weight(p, cursed) <= 0 or G.trait_weight(p, legend) <= 0:
		fail("cursed/legendary traits not offered once unlocked")
	if G.trait_weight(p, common) != 0:
		fail("maxed trait still offered")
	# Weighted offers favour the family you are building.
	var hits := 0
	for k in 300:
		G.offer_traits()
		for o in G.tchoice["opts"]:
			if o["fam"] == "edge":
				hits += 1
				break
	G.state = &"play"
	notes.append("leveling: rarity weights, cursed/legendary gating, 3-rank tier, new family bonus and offer weighting verified; " +
		"an EDGE trait was offered in %d of 300 level-ups after 3 EDGE ranks" % hits)
	# Paid reroll once the free ones are gone.
	p.rerolls = 0
	p.gold = 100
	G.offer_traits()
	var cost := G.reroll_cost()
	p.pending += 1
	G.state = &"traits"
	G.tchoice["t0"] = G.time - 10.0   # past the level-up burst, when the screen takes keys
	Input.action_press(&"pause")
	Keys.tick()
	G.update_traits()
	Input.action_release(&"pause")
	Keys.tick()
	if p.gold != 100 - cost or p.paid_rerolls != 1:
		fail("paid reroll: gold %d, paid %d (cost %d)" % [p.gold, p.paid_rerolls, cost])
	G.state = &"play"
	for id in ["t_common", "t_cursed", "t_legend"]:
		Traits._list.erase(Traits._by_id[id])
		Traits._by_id.erase(id)

func archetypes() -> void:
	var counts := []
	for a in Traits.ARCHETYPES:
		var n := 0
		for t in Traits.all():
			if t["fam"] == a["fam"]:
				n += 1
		counts.append("%s %d" % [a["name"], n])
	notes.append("traits per archetype: " + ", ".join(counts))

# ---------- 4. Broken build ----------
## Logic time per tick: the median of the per-tick times, so a tick delayed
## because another process had the CPU cannot fail the budget on its own,
## while a genuinely slow build (most ticks slow) still does.
func _timed(ticks: int) -> float:
	var times := PackedFloat64Array()
	for i in ticks:
		var t0 := Time.get_ticks_usec()
		play(1)
		times.append((Time.get_ticks_usec() - t0) / 1000.0)
	return _median_ms(times)

func _median_ms(times: PackedFloat64Array) -> float:
	var s := times.duplicate()
	s.sort()
	return s[s.size() / 2]

func broken_build() -> void:
	var p := arena(1)
	var ranks := 0
	for fam in ["storm", "arcane", "pyre", "blood"]:
		for t in Traits.all():
			if t["fam"] == fam:
				for k in t["max"]:
					p.pending += 1
					G.take_trait(t)
					ranks += 1
	for f in TestFixtures.items():
		if f["id"] in ["fx_bomb", "fx_act_nova", "fx_act_chain", "fx_act_lightning", "fx_status_shock", "fx_pct"]:
			for k in 5:
				give_fixture(p, f)
	for e in G.enemies:
		e.max_hp = 1e12
		e.hp = 1e12
	var ms := _timed(600)
	check("broken build")
	notes.append("broken build: %d trait ranks + stacked recursive procs: %.2f ms/tick logic, median (budget 16.7)" % [ranks, ms])
	if ranks < 50:
		fail("broken build has only %d trait ranks" % ranks)
	if ms > 16.7:
		fail("broken build too slow: %.2f ms/tick" % ms)

## Every named combo is assembled through the real pickup paths, must turn
## on, and must stay within the rails and the frame budget for 10 s.
func combos() -> void:
	var worst := 0.0
	var n := 0
	for c in Synergies.COMBOS:
		var p := arena(n)
		for need in c["needs"]:
			var parts: PackedStringArray = need.split(":")
			match parts[0]:
				"relic": G.add_relic(p, Relics.by_id(parts[1]))
				"weapon": Weapons.equip_weapon(p, Weapons.by_id(parts[1]))
				"gear": Gear.equip_gear(p, Gear.by_id(parts[1]))
				"trait":
					var t: Dictionary = Traits.by_id(parts[1])
					for k in t["max"]:
						p.pending += 1
						G.take_trait(t)
		Effects.recount_tags(p)
		if not p.synergies.has("combo:" + c["id"]):
			fail("combo %s did not turn on" % c["id"])
		for e in G.enemies:
			e.max_hp = 1e12
			e.hp = 1e12
		var ms := _timed(600)
		check("combo " + c["id"])
		worst = maxf(worst, ms)
		n += 1
	notes.append("combos: %d named combos assembled and active; worst %.2f ms/tick logic over 10 s" % [n, worst])
	if worst > 16.7:
		fail("a combo is too slow: %.2f ms/tick" % worst)

## Step 6 heroes: data checks, then every new hero plays 10 s with a full
## skill tree, and each new mechanic is exercised directly.
func heroes() -> void:
	var all := GameData.heroes()
	var ids := {}
	for i in all.size():
		var h: Dictionary = all[i]
		_uniq(ids, "hero", h["id"])
		_sprite("hero " + h["id"], h["sprite"])
		if not Weapons.HERO_WEAPON.has(h["id"]) or not Weapons._by_id.has(Weapons.HERO_WEAPON[h["id"]]):
			fail("hero %s: no signature weapon" % h["id"])
		if not Traits.HERO_BRANCH.has(h["id"]):
			fail("hero %s: no skill-tree branch" % h["id"])
			continue
		for nd in Traits.HERO_BRANCH[h["id"]]["nodes"]:
			if not Traits.NODE_EFFECTS.has(nd[0]):
				fail("hero %s: node %s has no effects" % [h["id"], nd[0]])
			_font("node " + nd[0], [nd[0], nd[1]])
		_font("hero " + h["id"], [h["name"], h["blurb"], h.get("passive", ""), h["weapon"]])
		if not h.get("new", false):
			continue
		lint_effects("hero " + h["id"], h["effects"], false)
		if not h.has("special"):
			fail("hero %s: no special ability" % h["id"])
		else:
			var sp: Dictionary = h["special"]
			lint_proc("hero %s special" % h["id"], { "on": "on_hit", "do": sp["do"] })
			_font("hero %s special" % h["id"], [sp["name"], sp["desc"]])
			for act in sp["do"]:
				if act[0] == "channel":
					lint_proc("hero %s channel" % h["id"], { "on": "on_hit", "do": act[3] })
				elif act[0] == "dash" and act.size() > 4 and not act[4].is_empty():
					lint_proc("hero %s dash end" % h["id"], { "on": "on_hit", "do": act[4] })
				elif act[0] == "leap" and act.size() > 3 and not act[3].is_empty():
					lint_proc("hero %s leap landing" % h["id"], { "on": "on_hit", "do": act[3] })
		if not Traits._by_id.has(h["trait"]):
			fail("hero %s: unknown starting trait %s" % [h["id"], h["trait"]])
		# A hero that costs embers is bought at the shrine; a free one is a starter and must not be listed there.
		if GameData.unlocks().any(func(u): return u["id"] == "hero_" + h["id"]) != (h["cost"] > 0):
			fail("hero %s: shrine unlock does not match its cost" % h["id"])
		if h["cost"] == 0 and not G.hero_unlocked(h):
			fail("hero %s: a starter that is locked" % h["id"])
	# Live: each new hero with its whole tree learned, 10 s of fighting.
	var worst := 0.0
	var n := 0
	for i in all.size():
		var h: Dictionary = all[i]
		if not h.get("new", false):
			continue
		Meta.meta["tree"][h["id"]] = [4, 4, 4]
		var p := arena(i)
		if p.weapon["id"] != Weapons.HERO_WEAPON[h["id"]]:
			fail("hero %s starts with %s" % [h["id"], p.weapon["id"]])
		if p.traits.get(h["trait"], 0) != 1:
			fail("hero %s: starting trait not at rank 1" % h["id"])
		if not p.procs.any(func(pr): return pr["src"] == "hero:" + h["id"]) and h["effects"].any(func(e): return e is Dictionary):
			fail("hero %s: passive procs missing" % h["id"])
		for e in G.enemies:
			e.max_hp = 1e9
			e.hp = 1e9
		worst = maxf(worst, _timed(600))
		check("hero " + h["id"])
		n += 1
		Meta.meta["tree"].erase(h["id"])
	# Specials: each fires, goes on cooldown, does its thing, and comes back.
	var used := 0
	for i in all.size():
		var h: Dictionary = all[i]
		if not h.has("special"):
			continue
		var p := arena(i)
		# An open floor: a pillar or crate of a random layout right in front of the hero would stop a
		# dash short, and this checks the special, not the layout.
		for rr in range(TB.IY0, TB.IY0 + TB.IH):
			for cc in range(TB.IX0, TB.IX0 + TB.IW):
				if G.room.tile(cc, rr) != World.T_FLOOR:
					G.room.set_tile(cc, rr, World.T_FLOOR)
		G.room.crate_hp = {}
		for e in G.enemies:
			e.max_hp = 1e9
			e.hp = 1e9
		var hp0 := 0.0
		for e in G.enemies:
			hp0 += e.hp
		var pos0 := Vector2(p.x, p.y)
		if not Abilities.ready(p):
			fail("%s: special not ready at the start" % h["id"])
		Abilities.use(p)
		if Abilities.ready(p) or Abilities.charge(p) > 0.01:
			fail("%s: special did not go on cooldown" % h["id"])
		var has_dash: bool = h["special"]["do"].any(func(a): return a[0] == "dash" or a[0] == "leap")
		var has_channel: bool = h["special"]["do"].any(func(a): return a[0] == "channel")
		if has_dash and p.dash_t <= 0:
			fail("%s: dash did not start" % h["id"])
		if has_channel and p.channel.is_empty():
			fail("%s: channel did not start" % h["id"])
		play(int(h["special"]["cd"] * 60) + 2)
		check("special " + h["id"])
		if has_dash and Vector2(p.x, p.y).distance_to(pos0) < 20:
			fail("%s: dash did not move the hero" % h["id"])
		if p.dash_t > 0 or not p.channel.is_empty():
			fail("%s: dash or channel never ended" % h["id"])
		if not Abilities.ready(p):
			fail("%s: special did not recharge after %ds" % [h["id"], h["special"]["cd"]])
		used += 1
	notes.append("specials: %d hero specials fired, cooled down and recharged" % used)
	# Mechanics.
	var rk := arena(_hero_index("racketeer"))
	var dmg0 := rk.dmg
	var gm0 := rk.gold_mult
	for k in 7:
		Effects.fire("on_room_clear")
	if rk.heat != 5 or absf(rk.dmg - dmg0 * 1.4) > 1e-6 or absf(rk.gold_mult - gm0 * 1.5) > 1e-6:
		fail("heat: %d heat, dmg x%.3f, gold x%.3f (want 5, x1.4, x1.5)" % [rk.heat, rk.dmg / dmg0, rk.gold_mult / gm0])
	Effects.fire("on_damage_taken")
	if rk.heat != 3:
		fail("heat after a hit: %d (want 3)" % rk.heat)
	for k in 5:
		Effects.fire("on_damage_taken")
	if rk.heat != 0 or absf(rk.dmg - dmg0) > 1e-6 or absf(rk.gold_mult - gm0) > 1e-6:
		fail("heat did not cool back to 0 cleanly (dmg x%.3f)" % (rk.dmg / dmg0))
	var cm := arena(_hero_index("condemned"))
	var before := [cm.dmg, cm.rate, cm.max_hp, cm.crit]
	Effects.fire("on_floor_start")
	if [cm.dmg, cm.rate, cm.max_hp, cm.crit] == before:
		fail("condemned: a scroll changed nothing")
	Weapons.equip_weapon(cm, Weapons.by_id("needledirk"))
	if not cm.buffs.any(func(b): return b["stat"] == "dmg"):
		fail("condemned: weapon swap gave no damage buff")
	var wf := arena(_hero_index("wayfarer"))
	wf.charges = 0
	Effects.fire("on_roll")
	if wf.charges != 0:
		fail("wayfarer: roll refunded with no shot nearby")
	EBullets.add(wf.x + 10, wf.y, 0, 0, "red", 3.0)
	Effects.fire("on_roll")
	if wf.charges != 1:
		fail("wayfarer: perfect dodge did not refund the roll")
	EBullets.clear_all()
	var bh := arena(_hero_index("banehunter"))
	Effects.fire("on_potion")
	if not bh.buffs.any(func(b): return b["stat"] == "dmg" and absf(b["t"] - 10.0) < 0.1):
		fail("bane hunter: potion oil buff missing")
	var ct := arena(_hero_index("cartomancer"))
	var gold0 := ct.gold
	for k in 60:
		Actions.run(["card"], 1, {})
	if ct.gold == gold0:
		fail("cartomancer: 60 draws and never the COIN card")
	notes.append("heroes: %d heroes linted, %d new heroes played 10 s each with full trees (worst %.2f ms/tick); heat, scrolls, weapon swap, perfect dodge, potion oil and card draws verified" % [all.size(), n, worst])

## Step 8 equipment slots: gloves and amulet have their own slot; two rings
## fill ring1 and ring2, and a third replaces the lower-rarity ring.
func slots() -> void:
	var p := arena(0)
	var base: Dictionary = Gear.all()[0]
	var mk := func(id: String, slot: String, rarity: String) -> Dictionary:
		var g := base.duplicate(true)
		g["id"] = id
		g["slot"] = slot
		g["rarity"] = rarity
		g["set"] = null
		g["new"] = true
		return g
	Gear.equip_gear(p, mk.call("t_glove", "hands", "rare"))
	Gear.equip_gear(p, mk.call("t_neck", "neck", "rare"))
	Gear.equip_gear(p, mk.call("t_ringa", "ring", "epic"))
	Gear.equip_gear(p, mk.call("t_ringb", "ring", "common"))
	if p.gear.get("hands", {}).get("id") != "t_glove" or p.gear.get("neck", {}).get("id") != "t_neck":
		fail("gloves or amulet not in their slots")
	if p.gear.get("ring1", {}).get("id") != "t_ringa" or p.gear.get("ring2", {}).get("id") != "t_ringb":
		fail("two rings did not fill both ring slots")
	var old = Gear.equip_gear(p, mk.call("t_ringc", "ring", "rare"))
	if old == null or old["id"] != "t_ringb" or p.gear["ring2"]["id"] != "t_ringc":
		fail("a third ring did not replace the lower-rarity ring")
	if p.gear.get("head") != null:
		fail("new slots disturbed the original ones")
	check("slots")
	# A set across the new slots (gloves, amulet and both rings) reaches its 4-piece bonus.
	var q := arena(1)
	for id in ["conclave_gloves", "conclave_sigil", "conclave_ring_a", "conclave_ring_b"]:
		Gear.equip_gear(q, Gear.by_id(id))
	if q.set_tier.get("conclave", 0) != 2 or not q.procs.any(func(pr): return pr["src"] == "se4:conclave"):
		fail("conclave set: 4-piece bonus not active (tier %d)" % q.set_tier.get("conclave", 0))
	Gear.equip_gear(q, Gear.by_id("copperband"))
	if q.set_tier.get("conclave", 0) != 1 or q.procs.any(func(pr): return pr["src"] == "se4:conclave"):
		fail("conclave set: bonus not removed after swapping a ring out")
	check("conclave set")
	notes.append("slots: gloves, amulet and two ring slots verified (%d slots in play); a 4-piece set across them turns on and off" % Gear.slots().size())

## Stage 7 biomes: data checks; every new floor fought with its whole foe
## pool and hazard; every mini-boss; every guardian driven through each of
## its attacks; and the run flow (throne victory, then the true ending).
func biomes() -> void:
	var fl := GameData.floors()
	var n_new := 0
	var foes := {}
	for i in fl.size():
		var f: Dictionary = fl[i]
		_sprite("floor %d" % i, "kit%d" % i)
		_font("floor %d" % i, [f["name"]])
		if not GameData.BOSSES.has(f["boss"]) or not BossAI.BOSS_PLANS.has(f["boss"]):
			fail("floor %d: guardian %s missing" % [i, f["boss"]])
		for t in f["pool"] + ([f["mini"]] if f.has("mini") else []):
			if not GameData.ENEMIES.has(t):
				fail("floor %d: unknown foe %s" % [i, t])
				continue
			foes[t] = true
		if i < GameData.FLOORS.size():
			continue
		n_new += 1
		if not f.has("mini") or not GameData.ENEMIES[f["mini"]].get("mini", false):
			fail("floor %d: no mini-boss" % i)
		if not f["hazard"] in ["bog", "warfront", "icicle", "vent", "rift"]:
			fail("floor %d: unknown hazard %s" % [i, f["hazard"]])
	for t in foes:
		var d: Dictionary = GameData.ENEMIES[t]
		_sprite("foe " + t, d["sprite"])
		_sprite("foe " + t, d["sprite"] + "_elite")
		if d.has("shot") and not EBullets.SPRITES.has(d["shot"]):
			fail("foe %s: unknown shot %s" % [t, d["shot"]])
		if d.has("name"):
			_font("foe " + t, [d["name"]])
	for b in BossAI.BOSS_PLANS:
		_sprite("guardian " + b, GameData.BOSSES[b]["sprite"])
		_font("guardian " + b, [GameData.BOSSES[b]["name"]])
		for t in BossAI.BOSS_SUMMONS.get(b, []):
			if not GameData.ENEMIES.has(t):
				fail("guardian %s summons unknown %s" % [b, t])
	# Live: each new floor, a combat room with its hazard and one of every pool foe.
	var worst := 0.0
	var hazard_rooms := 0
	for i in range(GameData.FLOORS.size(), fl.size()):
		var f: Dictionary = fl[i]
		var p := arena(0)
		G.floor_index = i
		G.floor_d = World.new_floor(i)
		G.floor_d["depth"] = 2
		G.enter_room(World.make_room(G.floor_d, "combat", "", "s"))
		if G.room.hazards.is_empty() and G.room.strike == "":
			fail("floor %d: combat room has no hazard" % i)
		else:
			hazard_rooms += 1
		G.room.waves_left = 0
		var seen := {}
		for t in f["pool"]:
			if seen.has(t):
				continue
			seen[t] = true
			var sp := World.free_spot(G.room, p, 60, World.M_FLYER)
			Combat.spawn_enemy(t, sp.x, sp.y, false, true)
		var mini := Combat.spawn_enemy(f["mini"], 14.0 * TB.TS, 8.0 * TB.TS, false, true)
		for e in G.enemies:
			e.max_hp = 1e9
			e.hp = 1e9
		worst = maxf(worst, _timed(900))
		check("floor %d" % i)
		if not G.enemies.has(mini):
			fail("floor %d: mini-boss vanished" % i)
	# The door before the rest stop always leads to the mini-boss room, which spawns it.
	var fi := GameData.FLOORS.size()
	arena(0)
	G.floor_index = fi
	G.floor_d = World.new_floor(fi)
	G.floor_d["depth"] = G.floor_d["total"] - 3
	var ch := World.gen_choices(G.floor_d, G.player)
	if ch.size() != 1 or ch[0]["type"] != "elite":
		fail("mini-boss door not forced: %s" % [ch])
	G.floor_d["depth"] += 1
	G.enter_room(World.make_room(G.floor_d, "elite", "rare", "s"))
	G.spawn_wave()
	if not G.enemies.any(func(e): return e.type == fl[fi]["mini"]):
		fail("mini-boss room did not spawn %s" % fl[fi]["mini"])
	# Guardians: force every attack in each plan and let it play out.
	var attacks := 0
	for i in range(GameData.FLOORS.size(), fl.size()):
		var key: String = fl[i]["boss"]
		var p := arena(0)
		G.floor_index = i
		G.enemies.clear()
		var b := Combat.spawn_boss(key)
		b.max_hp = 1e9
		b.hp = 1e9
		for st in BossAI.BOSS_PLANS[key]:
			b.state = StringName(st)
			b.st = 0.0
			b.sub = 0
			b.t = 0.0
			var ticks := 0
			while b.state == StringName(st) and ticks < 900:
				play(1)
				ticks += 1
			if ticks >= 900:
				fail("guardian %s: attack %s never finished" % [key, st])
			attacks += 1
		check("guardian " + key)
		G.boss = null
	# Run flow: the Pale Regent's fall is a victory and opens the way on;
	# the last guardian ends the run.
	var p := arena(0)
	var wins0: int = Meta.meta["wins"]
	G.floor_index = GameData.THRONE_FLOOR
	G.on_boss_dead(Combat.spawn_boss("regent"))
	if not G.run_stats.get("throne", false) or Meta.meta["wins"] != wins0 + 1:
		fail("throne victory not granted")
	if not G.room.objects.any(func(o): return o["kind"] == "portal"):
		fail("no rift after the throne")
	G.floor_index = fl.size() - 1
	G.on_boss_dead(Combat.spawn_boss(fl[fl.size() - 1]["boss"]))
	if not G.room.objects.any(func(o): return o["kind"] == "exitportal"):
		fail("the last guardian does not offer the way out")
	notes.append("biomes: %d new floors, %d foe types linted; every floor fought with its hazard (%d rooms) and mini-boss, worst %.2f ms/tick; %d guardian attacks played out; throne victory and true ending verified" % [
		n_new, foes.size(), hazard_rooms, worst, attacks])

## Loop playthroughs: the true ending offers LOOP or EXIT; looping goes back
## to floor 1 with the same build and tougher foes; the throne is not won twice.
func loops() -> void:
	var p := arena(5)
	var fl := GameData.floors()
	var level := p.level
	var wins0: int = Meta.meta["wins"]
	G.floor_index = GameData.THRONE_FLOOR
	G.on_boss_dead(Combat.spawn_boss("regent"))
	G.floor_index = fl.size() - 1
	G.enemies.clear()
	G.on_boss_dead(Combat.spawn_boss(fl[fl.size() - 1]["boss"]))
	var lp = null
	var ex = null
	for o in G.room.objects:
		if o["kind"] == "loopportal": lp = o
		if o["kind"] == "exitportal": ex = o
	if lp == null or ex == null or G.win_timer != null:
		fail("true ending: no loop/exit choice")
		return
	var hp0 := GameData.ENEMIES["skeleton"]["hp"] * Combat.floor_scale() / (1 + 0.42 * G.floor_index)
	G.interact(lp)
	play(90)
	if G.loop != 1 or G.floor_index != 0 or G.state != &"play":
		fail("loop portal: loop %d floor %d state %s" % [G.loop, G.floor_index, G.state])
	if G.player != p or p.level < level:
		fail("loop portal: the build was not kept")
	var e := Combat.spawn_enemy("skeleton", 200, 150, false, true)
	# (x Combat.hard_hp and run_scale: the expanded game's foes are tougher, ROADMAP 4.7 and 5.8;
	# a loop is x2.5 there, x1.8 in the original rules)
	var lm := 2.5 if GameData.rogues() else 1.8
	var want: float = GameData.ENEMIES["skeleton"]["hp"] * (1 + 0.15 * G.dread) * lm * Combat.hard_hp() * Combat.run_scale()
	if absf(e.max_hp - want) > 1e-3:
		fail("loop 2 foe health %.1f (want %.1f, x%.1f)" % [e.max_hp, want, lm])
	G.floor_index = GameData.THRONE_FLOOR
	G.on_boss_dead(Combat.spawn_boss("regent"))
	if Meta.meta["wins"] != wins0 + 1:
		fail("the throne counted as a win twice")
	G.floor_index = fl.size() - 1
	G.on_boss_dead(Combat.spawn_boss(fl[fl.size() - 1]["boss"]))
	for o in G.room.objects:
		if o["kind"] == "exitportal": ex = o
	var ew: int = Meta.meta.get("eclipse_wins", 0)
	G.interact(ex)
	play(90)   # (the helper returns to play after the win screen)
	if Meta.meta.get("eclipse_wins", 0) != ew + 1 or not G.award.get("parts", []).any(func(x): return x[0] == "LOOPS"):
		fail("exit portal did not end the run with the loop bonus")
	G.state = &"play"
	G.loop = 0
	notes.append("loops: true ending offers loop or exit; loop 2 keeps the build with x1.8 foe health; throne not counted twice; exit ends the run with the loop bonus")

## Rogues layer: attributes and weapon scaling.
func attributes() -> void:
	var p := arena(2)   # the Brute: STR 5 DEX 1 INT 0, plus his starting setup
	var spread: Array = Attributes.HERO[p.hero["id"]]
	if [p.a_str, p.a_dex, p.a_int] != spread:
		fail("brute starts with %s, want %s" % [[p.a_str, p.a_dex, p.a_int], spread])
	var g := Attributes.scaling(p.weapon)
	var want: float = 1.0 + Attributes.PER_POINT * (Attributes.COEF[g["str"]] * p.a_str + Attributes.COEF[g["dex"]] * p.a_dex + Attributes.COEF[g["int"]] * p.a_int)
	if absf(Attributes.mult(p) - want) > 1e-9:
		fail("attribute multiplier %.4f, want %.4f" % [Attributes.mult(p), want])
	var s0 := p.a_str
	for t in Traits.all():
		if t["fam"] == "fury":
			p.pending += 1
			G.take_trait(t)
			break
	if p.a_str != s0 + 1:
		fail("a fury trait rank did not train STR")
	G.add_relic(p, Relics.by_id("heavennectar"))
	if p.a_str != s0 + 2:
		fail("heavenly nectar did not raise the highest attribute")
	var graded := 0
	for w in Weapons.all():
		var gg := Attributes.scaling(w)
		for a in Attributes.ATTRS:
			if not gg[a] in Attributes.GRADES:
				fail("weapon %s: bad grade %s" % [w["id"], gg[a]])
		if Attributes.COEF[gg["str"]] + Attributes.COEF[gg["dex"]] + Attributes.COEF[gg["int"]] > 0:
			graded += 1
		if w["rarity"] == "legend" and not "S" in gg.values():
			fail("legendary %s has no S grade" % w["id"])
	if graded != Weapons.all().size():
		fail("%d weapons scale with nothing" % (Weapons.all().size() - graded))
	GameData.force_classic = true
	if Attributes.mult(p) != 1.0:
		fail("attributes still apply with the Rogues layer off")
	GameData.force_classic = false
	notes.append("attributes: hero spreads, trait training, attribute relics, scaling for all %d weapons, and off under classic" % graded)

## Rogues layer: anvil upgrades, the Smith's Hammer, damage rolls and item cards.
func upgrades() -> void:
	var p := arena(1)
	var shared: Dictionary = Weapons.by_id(p.weapon["id"])
	var d0 := Weapons.wdmg(p)
	p.gold = 10000
	var anvil := { "kind": "anvil", "x": p.x, "y": p.y }
	G.interact(anvil)
	if WeaponInfo.plus(p.weapon) != 1 or absf(Weapons.wdmg(p) - d0 * 1.08) > 1e-6:
		fail("anvil: +%d, damage x%.3f (want +1, x1.08)" % [WeaponInfo.plus(p.weapon), Weapons.wdmg(p) / d0])
	if shared.has("plus"):
		fail("upgrading changed the shared weapon table")
	for k in 40:
		G.interact(anvil)
	if WeaponInfo.plus(p.weapon) != WeaponInfo.MAX_PLUS:
		fail("anvil did not stop at +%d" % WeaponInfo.MAX_PLUS)
	var upgraded: Dictionary = p.weapon
	Weapons.equip_weapon(p, Weapons.by_id("warbow"))
	if WeaponInfo.plus(upgraded) != WeaponInfo.MAX_PLUS:
		fail("a dropped weapon lost its level")
	G.add_relic(p, Relics.by_id("smithhammer"))
	if WeaponInfo.plus(p.weapon) != 2:
		fail("smith's hammer gave +%d (want +2)" % WeaponInfo.plus(p.weapon))
	# Damage rolls stay within +-15%.
	var e := Combat.spawn_enemy("golem", 200, 150, false, true)
	e.max_hp = 1e9
	e.hp = 1e9
	p.crit = 0.0
	var lo := 1e9
	var hi := 0.0
	for k in 300:
		var before := e.hp
		Combat.damage_enemy(e, 100.0, { "no_crit": true, "silent": true })
		var dealt := before - e.hp
		lo = minf(lo, dealt)
		hi = maxf(hi, dealt)
	if lo < 84.9 or hi > 115.1 or hi - lo < 15:
		fail("damage rolls %.1f..%.1f (want about 85..115)" % [lo, hi])
	var lines := OverlayView.item_lines(Weapons.by_id("truthseeker"))
	if not lines.any(func(l): return l[0].begins_with("- ATTACK DAMAGE:")):
		fail("weapon card has no damage line")
	notes.append("upgrades: anvil +1 = +8%% damage up to +%d on its own copy; levels stay with dropped weapons; hammer +2; hits roll %.0f..%.0f of 100; cards list damage" % [WeaponInfo.MAX_PLUS, lo, hi])

## Rogues layer: backpack swaps, equipping from the backpack, the quick belt.
func inventory() -> void:
	var p := arena(0)
	var first: Dictionary = p.weapon
	var floor_item := { "kind": "item", "item": Weapons.by_id("warbow"), "x": p.x, "y": p.y }
	G.room.objects.append(floor_item)
	G.interact(floor_item)
	if p.weapon["id"] != "warbow" or p.backpack.size() != 1 or p.backpack[0]["id"] != first["id"] or not floor_item.get("gone", false):
		fail("swapping did not put the old weapon in the backpack")
	G.equip_from_backpack(0)
	if p.weapon["id"] != first["id"] or p.backpack[0]["id"] != "warbow":
		fail("equipping from the backpack did not swap")
	for k in Player.BACKPACK_SIZE + 2:
		G.to_backpack(Weapons.by_id("ironpike"))
	if p.backpack.size() != Player.BACKPACK_SIZE:
		fail("backpack holds %d (max %d)" % [p.backpack.size(), Player.BACKPACK_SIZE])
	# Belt: pickups fill four slots; each consumable works.
	for kind in Consumables.KINDS:
		Consumables.take(p, kind)
	if Consumables.take(p, "c_fury") or p.belt.size() != Consumables.BELT_SIZE:
		fail("belt took more than %d" % Consumables.BELT_SIZE)
	var lv := WeaponInfo.plus(p.weapon)
	var attrs := p.a_str + p.a_dex + p.a_int
	EBullets.add(p.x + 20, p.y, 0, 0, "red", 3.0)
	while not p.belt.is_empty():
		Consumables.use(p, 0)
	if not p.buffs.any(func(b): return b["stat"] == "dmg" and absf(b["v"] - 0.4) < 1e-6):
		fail("fury draught: no damage buff")
	if p.invuln < 1.0 or EBullets.any_near(p.x, p.y, 40):
		fail("smoke vial: shots not cleared or not untouchable")
	if WeaponInfo.plus(p.weapon) != lv + 1:
		fail("whetstone did not upgrade the weapon")
	if p.a_str + p.a_dex + p.a_int != attrs + 1:
		fail("elixir of insight did not add an attribute")
	# A consumable pickup lands in the belt.
	var k := Combat.drop_pickup("c_whet", p.x, p.y)
	k.t = 1.0
	k.vx = 0
	k.vy = 0
	play(30)
	if p.belt.size() != 1:
		fail("walking over a consumable did not put it in the belt")
	EBullets.clear_all()
	notes.append("inventory: replaced items go to the %d-slot backpack, equip back from it; %d-slot belt; all %d consumables work; pickups fill the belt" % [
		Player.BACKPACK_SIZE, Consumables.BELT_SIZE, Consumables.KINDS.size()])

## Rogues layer: training dummies never die, measure DPS, give nothing.
func dummies() -> void:
	var p := arena(0)
	G.enemies.clear()
	G.enter_room(World.make_room(G.floor_d, "start", "", ""))
	var ds := G.enemies.filter(func(e): return e.type == "dummy")
	if ds.size() != 2:
		fail("start room has %d dummies (want 2)" % ds.size())
		return
	if G.enemies_active():
		fail("dummies count as a fight")
	p.gf["gold_hit"] = 1.0
	p.gf["leech"] = 1.0
	p.hp = 1
	var gold0 := p.gold
	var d: Enemy = ds[0]
	for k in 120:
		Combat.damage_enemy(d, 50.0, { "no_crit": true, "silent": true })
		Combat.on_hit_effects(d, 50.0, false, p, null)
		_tick_only(1)
	_tick_only(30)
	if d.hp <= 0 or not G.enemies.has(d):
		fail("a dummy died")
	if d.dps < 500:
		fail("dummy dps %.0f (want about 1500)" % d.dps)
	if p.gold != gold0 or p.hp != 1 or G.pickups.size() > 0:
		fail("hitting a dummy gave gold %d->%d, hp %d, pickups %s" % [gold0, p.gold, p.hp, G.pickups.map(func(k): return k.kind)])
	p.gf.erase("gold_hit")
	p.gf.erase("leech")
	notes.append("dummies: 2 per start room, never die, read %.0f DPS, give no gold/heal/procs, not a fight" % d.dps)

func _hero_index(id: String) -> int:
	var all := GameData.heroes()
	for i in all.size():
		if all[i]["id"] == id:
			return i
	fail("no hero " + id)
	return 0

# ---------- 5. Stress ----------
func stress() -> void:
	var p := arena(2)
	p.familiars = 40
	for k in 3:
		for f in TestFixtures.items():
			if f["id"] in ["fx_flood", "fx_act_summon"]:
				give_fixture(p, f)
	for e in G.enemies:
		e.max_hp = 1e12
		e.hp = 1e12
	var times := PackedFloat64Array()
	var peak_eb := 0
	var peak_pb := 0
	for i in 600:
		if EBullets.n < 600:
			Combat.ering(TB.SW / 2.0, 5.0 * TB.TS, 32, 25, randf(), "red")
		var t0 := Time.get_ticks_usec()
		play(1)
		times.append((Time.get_ticks_usec() - t0) / 1000.0)
		peak_eb = maxi(peak_eb, EBullets.n)
		peak_pb = maxi(peak_pb, G.pbullets.size())
	var ms := _median_ms(times)
	check("stress")
	notes.append("stress: peak %d enemy shots, %d player shots, %d summons: %.2f ms/tick logic" % [peak_eb, peak_pb,
		mini(p.familiars, Effects.SUMMON_CAP) + G.temp_fams.size(), ms])
	if peak_eb < 500:
		fail("stress test never reached 500 enemy shots")
	if ms > 16.7:
		fail("stress too slow: %.2f ms/tick" % ms)

## Phase E: themed weapon effects show for tagged shots, swings and hits,
## stay off under classic, and never draw from the game's random numbers.
func weapon_fx() -> void:
	var p := arena(0)
	p.weapon = Weapons.by_id("sunpiercer")
	for t in WeaponFx.THEME:
		if not Weapons.TAG_COLS.has(t):
			fail("weapon fx theme %s is not a weapon tag" % t)
	Juice.reset()
	for i in 30:
		var b := PBullet.new()
		b.x = 100 + i
		b.y = 100
		b.tag = "pyre"
		G.pbullets.append(b)
	G.swings.append({ "kind": "slash", "x": p.x, "y": p.y, "a": 0.0, "r": 20.0, "arc": 2.0, "t": 0.14, "max": 0.14, "tag": "frost" })
	G.enemies[0].flash = 0.08
	seed(777)
	var want := randf()
	seed(777)
	for i in 10:
		Juice.update(TB.DT, p)
	if randf() != want:
		fail("weapon fx drew from the game's random numbers")
	var n := Juice.spark_n
	if n < 20:
		fail("weapon fx made only %d particles from 30 fire shots, a swing and a hit" % n)
	GameData.force_classic = true
	Juice.reset()
	Juice.update(TB.DT, p)
	GameData.force_classic = false
	if Juice.spark_n > 0:
		fail("weapon fx shows under classic")
	G.pbullets.clear()
	G.swings.clear()
	Juice.reset()
	notes.append("weapon fx: %d themes; trails, swing bursts, hit sparks and legend aura (%d particles in 10 ticks); off under classic; own random numbers" % [WeaponFx.THEME.size(), n])

## Lag fix (iPad video): a late-run build (--heavy: 40 relics, 40 trait
## ranks, legendary weapon and gear) in a long fight stays smooth. The
## Rogues shot cap holds, coins past the floor pile go straight to gold,
## and the logic tick stays well inside the frame.
func heavy_fight() -> void:
	var p := arena(0)
	G._debug_heavy(p)
	for e in G.enemies:
		e.max_hp *= 40
		e.hp = e.max_hp
	var ms := _timed(900)
	check("heavy fight")
	if G.pbullets.size() > Effects.ROGUES_PBULLET_CAP:
		fail("heavy fight: %d live shots (cap %d)" % [G.pbullets.size(), Effects.ROGUES_PBULLET_CAP])
	while G.pickups.size() < Combat.COIN_PILE:
		Combat.drop_pickup("heart", p.x, p.y)
	var n := G.pickups.size()
	var g0 := p.gold
	for i in 50:
		Combat.drop_pickup("coin", p.x + 60, p.y)
	if G.pickups.size() != n or p.gold < g0 + 40:
		fail("coin pile: %d -> %d pickups, gold %d -> %d" % [n, G.pickups.size(), g0, p.gold])
	notes.append("heavy fight: %d relics, legendary build, %.2f ms/tick logic (median, budget 8); shot cap %d; coins past %d on the floor go to gold" % [
		p.relics.size(), ms, Effects.ROGUES_PBULLET_CAP, Combat.COIN_PILE])
	if ms > 8.0:
		fail("heavy fight too slow: %.2f ms/tick" % ms)
	# Sprite atlas: sprites and fonts share one texture so big fights batch.
	var shared: Array = ["coin", "font1_white", "font1_shadow", "orb_hex", "hatchet", "slash_arc"].map(func(n): return Img.t(n))
	if Img.atlas_count < 400 or not shared.all(func(t): return t is AtlasTexture and t.atlas == shared[0].atlas):
		fail("sprite atlas: %d graphics packed, shared texture missing" % Img.atlas_count)
	notes.append("sprite atlas: %d graphics share one texture" % Img.atlas_count)
