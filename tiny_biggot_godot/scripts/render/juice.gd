class_name Juice
extends RefCounted
## Extra hit, kill and pickup feedback (polish, spec step 0b). Purely visual:
## it has its own random generator and never reads or writes game state that
## logic uses, so the game plays exactly as before (the --classic replays in
## tools/replay.sh prove it). Game code only calls the small notify functions
## below; world_view.gd draws the results.

static var _rng := RandomNumberGenerator.new()
static var pops: Array = []     # { name, x, y, sc, flip, t, max }: white death silhouettes
static var rings: Array = []    # { x, y, r0, r1, t, max, col }: expanding shock rings
static var hurt_t := 0.0        # red screen edge after taking a hit
static var flash_t := 0.0       # brief white screen flash (boss kill)
static var flash_max := 0.15
static var clear_t := 0.0       # room cleared: doors glow
static var recoil := 0.0        # weapon kick after firing (0..1)
static var _last_fire_cd := 0.0
# Hero abilities (step 6+).
static var labels: Array = []   # { text, col, x, y, t, max, big }: ability names, PERFECT!, ...
static var cards: Array = []    # { name, x, y, t }: Cartomancer card pop-ups
static var sigils: Array = []   # { x, y, r, t, max, col }: rotating rune circles
static var spins: Array = []    # { t, max, col }: whirling blades around the hero
static var sparks: Array = []   # { x, y, vx, vy, t, max, col }: own particles (own RNG)
static var _was_ready := true

const CARD_COL := { "BLADES": "#d9d0b4", "STORM": "#6fd3e0", "SHIELD": "#4d9be6", "MEND": "#e86a8e",
	"STAR": "#f2c94c", "WHEEL": "#a35bd6", "COIN": "#f2c94c" }
const CARD_GLYPH := { "BLADES": "/", "STORM": "!", "SHIELD": "O", "MEND": "+", "STAR": "*", "WHEEL": "%", "COIN": "$" }

static func reset() -> void:
	pops.clear()
	rings.clear()
	hurt_t = 0.0
	flash_t = 0.0
	clear_t = 0.0
	recoil = 0.0
	labels.clear()
	cards.clear()
	sigils.clear()
	spins.clear()
	sparks.clear()
	_was_ready = true
	WeaponFx.reset()

# ---------- Notifications from game code ----------
static func kill(e: Enemy, sprite: String) -> void:
	var boss := e.is_boss()
	pops.append({ "name": sprite, "x": e.x, "y": e.y + e.r + (2 if boss else 0) - e.z, "sc": e.scale,
		"flip": e.face < 0, "t": 0.0, "max": 0.35 if boss else 0.16 })
	ring(e.x, e.y, 3, 40.0 if boss else 14.0 * e.scale, 0.5 if boss else 0.18, "#f4ecd8")
	if boss:
		ring(e.x, e.y, 6, 90, 0.8, "#f2c94c")
		flash(0.2)
	if pops.size() > 24:
		pops.pop_front()

static func hurt() -> void:
	hurt_t = 0.35

static func level_up(x: float, y: float) -> void:
	ring(x, y, 4, 34, 0.4, "#b8e05a")

static func room_clear(x: float, y: float) -> void:
	clear_t = 0.6
	ring(x, y, 6, 70, 0.5, "#f2c94c")

static func flash(t: float) -> void:
	flash_t = maxf(flash_t, t)
	flash_max = maxf(t, 0.01)

static func ring(x: float, y: float, r0: float, r1: float, life: float, col: String) -> void:
	rings.append({ "x": x, "y": y, "r0": r0, "r1": r1, "t": 0.0, "max": life, "col": TB.c(col) })
	if rings.size() > 24:
		rings.pop_front()

# ---------- Hero abilities ----------
## An ability fires: its name in big letters, a ring and a burst of sparks.
static func ability(x: float, y: float, name: String, col: String) -> void:
	label(name, col, x, y - 26, true)
	ring(x, y, 4, 46, 0.35, col)
	burst(x, y, col, 18, 90)
	flash(0.06)

static func label(text: String, col: String, x: float, y: float, big: bool = false) -> void:
	labels.append({ "text": text, "col": col, "x": x, "y": y, "t": 0.0, "max": 1.1 if big else 0.8, "big": big })
	if labels.size() > 8:
		labels.pop_front()

static func card(x: float, y: float, name: String) -> void:
	# Several cards at once fan out side by side.
	var k := cards.filter(func(c): return c["t"] < 0.3).size()
	cards.append({ "name": name, "x": x + (k - 1) * 16 + (8 if k == 0 else 0) - 8, "y": y - 18, "t": 0.0 })
	burst(x, y - 12, CARD_COL.get(name, "#ffffff"), 6, 40)
	if cards.size() > 8:
		cards.pop_front()

static func burst(x: float, y: float, col: String, n: int, speed: float) -> void:
	var c := TB.c(col)
	for i in n:
		var a := _rng.randf() * TAU
		var v := speed * (0.4 + _rng.randf() * 0.6)
		sparks.append({ "x": x, "y": y, "vx": cos(a) * v, "vy": sin(a) * v, "t": 0.0, "max": 0.3 + _rng.randf() * 0.3, "col": c })
	while sparks.size() > 300:
		sparks.pop_front()

## ["vfx", kind, colour, size]: visual-only effect data used by hero abilities.
static func vfx(p: Player, a: Array) -> void:
	var col: String = a[2] if a.size() > 2 else "#ffffff"
	match a[1]:
		"ring": ring(p.x, p.y, 4, a[3] if a.size() > 3 else 30, 0.35, col)
		"sigil":
			sigils.append({ "x": p.x, "y": p.y, "r": float(a[3]) if a.size() > 3 else 40.0, "t": 0.0, "max": 0.7, "col": TB.c(col) })
		"spin": spins.append({ "t": 0.0, "max": float(a[3]) if a.size() > 3 else 1.0, "col": TB.c(col) })
		"flash": flash(float(a[3]) if a.size() > 3 else 0.1)
		"burst": burst(p.x, p.y, col, int(a[3]) if a.size() > 3 else 12, 80)
		"label": label(a[2], a[3] if a.size() > 3 else "#ffffff", p.x, p.y - 22)

# ---------- Per logic tick (frozen during hitstop, like the game) ----------
static func update(dt: float, p: Player) -> void:
	for l in [labels, cards, sigils, spins]:
		var j := 0
		while j < l.size():
			l[j]["t"] += dt
			if l[j]["t"] >= (l[j]["max"] if l[j].has("max") else 0.9):
				l.remove_at(j)
			else:
				j += 1
	var k := 0
	while k < sparks.size():
		var sp: Dictionary = sparks[k]
		sp["t"] += dt
		if sp["t"] >= sp["max"]:
			sparks.remove_at(k)
			continue
		sp["x"] += sp["vx"] * dt
		sp["y"] += sp["vy"] * dt
		sp["vx"] *= 0.9
		sp["vy"] *= 0.9
		sp["vy"] += sp.get("g", 0.0) * dt
		k += 1
	if p != null and Abilities.has_special(p):
		var ready := Abilities.ready(p)
		if ready and not _was_ready:
			label("SKILL READY", p.hero["special"].get("col", "#f2c94c"), p.x, p.y - 22)
			ring(p.x, p.y, 2, 22, 0.3, p.hero["special"].get("col", "#f2c94c"))
		_was_ready = ready
		_hero_aura_tick(p)
	for l in [pops, rings]:
		var i := 0
		while i < l.size():
			l[i]["t"] += dt
			if l[i]["t"] >= l[i]["max"]:
				l.remove_at(i)
			else:
				i += 1
	WeaponFx.update(p)
	while sparks.size() > 300:
		sparks.pop_front()
	hurt_t = maxf(0.0, hurt_t - dt)
	flash_t = maxf(0.0, flash_t - dt)
	clear_t = maxf(0.0, clear_t - dt)
	recoil = maxf(0.0, recoil - dt * 9)
	if p != null:
		# The weapon's cooldown jumps back up exactly when it fires.
		if p.fire_cd > _last_fire_cd + 0.001:
			recoil = 1.0
		_last_fire_cd = p.fire_cd

# ---------- Drawing helpers used by world_view.gd ----------
static func draw_pops(ci: CanvasItem) -> void:
	for d in pops:
		var k: float = d["t"] / d["max"]
		var s: float = d["sc"] * (1.0 + k * 0.35)
		Gfx.sp(ci, d["name"], d["x"], d["y"], s, s * (1.0 - k * 0.3), 0.0, d["flip"], 1.0 - k, Color(1, 1, 1, 1))

static func draw_rings(ci: CanvasItem) -> void:
	for d in rings:
		var k: float = d["t"] / d["max"]
		var e := 1.0 - (1.0 - k) * (1.0 - k)   # ease out
		var r: float = lerpf(d["r0"], d["r1"], e)
		var c: Color = d["col"]
		c.a = (1.0 - k) * 0.9
		ci.draw_arc(Vector2(d["x"], d["y"]), r, 0, TAU, maxi(12, int(r)), c, 1.0, false)

## Screen-space overlays: red edges when hurt or on the last heart, white flash.
static func draw_screen(ci: CanvasItem, p: Player, t: float) -> void:
	var a := 0.0
	if hurt_t > 0:
		a = hurt_t / 0.35 * 0.55
	if p != null and p.hp > 0 and p.hp <= 2 and p.max_hp > 2:
		a = maxf(a, 0.18 + 0.12 * sin(t * 6.0))
	if a > 0.01:
		var w := TB.SW + 24
		var h := TB.SH + 24
		# Three overlapping bands: deeper red toward the edges (4, 8, 12 px).
		var c := Color(0.85, 0.1, 0.12, a / 3.0)
		for band in 3:
			var th := 12 + 4 * (band + 1)
			ci.draw_rect(Rect2(-12, -12, w, th), c)
			ci.draw_rect(Rect2(-12, TB.SH + 12 - th, w, th), c)
			ci.draw_rect(Rect2(-12, -12, th, h), c)
			ci.draw_rect(Rect2(TB.SW + 12 - th, -12, th, h), c)
	if flash_t > 0:
		ci.draw_rect(Rect2(-12, -12, TB.SW + 24, TB.SH + 24), Color(1, 1, 1, flash_t / flash_max * 0.45))

## Vertical light beam over loot of rare or better quality (drawn additive).
static func beam(ci: CanvasItem, x: float, y: float, rarity: String, t: float) -> void:
	if not rarity in ["rare", "epic", "legend"]:
		return
	var c := TB.c(GameData.RARITY_HEX[rarity])
	var tall: int = { "rare": 28, "epic": 40, "legend": 56 }[rarity]
	var pulse := 0.75 + 0.25 * sin(t * 4 + x)
	for i in tall:
		var k: float = float(i) / tall
		c.a = (1.0 - k) * 0.35 * pulse
		ci.draw_rect(Rect2(roundf(x - 3), roundf(y + 4 - i), 6, 1), c)
		c.a *= 1.6
		ci.draw_rect(Rect2(roundf(x - 1), roundf(y + 4 - i), 2, 1), c)

## Per-hero ambient feedback for the new heroes' passives (spawned per tick).
static func _hero_aura_tick(p: Player) -> void:
	match p.hero["id"]:
		"oathbreaker":
			# Rage: embers rise with every stacked kill buff.
			var rage := p.buffs.filter(func(b): return b["stat"] == "dmg").size()
			if _rng.randf() < 0.08 * rage:
				_ember(p, "#d8443c" if _rng.randf() < 0.6 else "#e8873a")
		"racketeer":
			if _rng.randf() < 0.07 * p.heat:
				_ember(p, "#e8873a" if _rng.randf() < 0.5 else "#f2c94c")
		"banehunter":
			# Blade oil glints on the weapon while the potion buff lasts.
			if p.buffs.any(func(b): return b["stat"] == "dmg" and absf(b["v"] - 0.4) < 1e-6) and _rng.randf() < 0.4:
				var wx := p.x + cos(p.aim_a) * 9
				var wy := p.y - 1 + sin(p.aim_a) * 6
				sparks.append({ "x": wx + _rng.randf_range(-2, 2), "y": wy, "vx": 0.0, "vy": -12.0, "t": 0.0, "max": 0.35, "col": TB.c("#f2c94c") })
	if p.dash_t > 0:
		burst(p.x, p.y + 4, p.hero["special"].get("col", "#ffffff"), 2, 30)

static func _ember(p: Player, col: String) -> void:
	sparks.append({ "x": p.x + _rng.randf_range(-6, 6), "y": p.y + 5, "vx": _rng.randf_range(-6, 6), "vy": -30.0 - _rng.randf() * 20,
		"t": 0.0, "max": 0.5 + _rng.randf() * 0.3, "col": TB.c(col) })

static func draw_sparks(ci: CanvasItem) -> void:
	for sp in sparks:
		var c: Color = sp["col"]
		c.a = 1.0 - sp["t"] / sp["max"]
		ci.draw_rect(Rect2(roundf(sp["x"]), roundf(sp["y"]), 2, 2), c)

## Sigils (rune circles with a rotating star) and the whirling blades.
static func draw_magic(ci: CanvasItem, p: Player, t: float) -> void:
	for sg in sigils:
		var k: float = sg["t"] / sg["max"]
		var r: float = sg["r"] * (0.5 + 0.5 * minf(1.0, k * 3.0))
		var c: Color = sg["col"]
		c.a = 1.0 - k
		var at := Vector2(sg["x"], sg["y"])
		ci.draw_arc(at, r, 0, TAU, 40, c, 1.0, false)
		ci.draw_arc(at, r * 0.8, 0, TAU, 32, c, 1.0, false)
		for tri in 2:
			var pts := PackedVector2Array()
			for v in 4:
				var ang := t * 2.0 + tri * PI / 3.0 + v * TAU / 3.0
				pts.append(at + Vector2(cos(ang), sin(ang) * 0.75) * r * 0.78)
			ci.draw_polyline(pts, c, 1.0, false)
	if p == null:
		return
	for sp in spins:
		var c: Color = sp["col"]
		c.a = 0.9 if sp["max"] - sp["t"] > 0.2 else (sp["max"] - sp["t"]) * 4.5
		var at := Vector2(p.x, p.y + 1)
		for b in 3:
			var a0: float = t * 14.0 + b * TAU / 3.0
			ci.draw_arc(at, 30, a0, a0 + 1.2, 10, c, 3.0, false)
			ci.draw_arc(at, 22, a0 + 0.3, a0 + 1.0, 8, Color(c.r, c.g, c.b, c.a * 0.5), 2.0, false)

## Ability names, PERFECT! and friends, and Cartomancer cards.
static func draw_labels(ci: CanvasItem) -> void:
	for l in labels:
		var k: float = l["t"] / l["max"]
		var sc := 2 if l["big"] else 1
		var rise := -sin(minf(k * 4.0, 1.0) * PI * 0.5) * 6.0 - k * 6.0
		Gfx.text(ci, l["text"], l["x"], l["y"] + rise, _font_col(l["col"]), sc, 0.5, true, clampf((1.0 - k) * 3.0, 0.0, 1.0))
	for c in cards:
		var k: float = c["t"] / 0.9
		var a := clampf((1.0 - k) * 3.0, 0.0, 1.0)
		var x := roundf(c["x"])
		var y := roundf(c["y"] - k * 10.0)
		var col := TB.c(CARD_COL.get(c["name"], "#ffffff"))
		ci.draw_rect(Rect2(x - 1, y - 1, 12, 16), Color(0.08, 0.06, 0.11, a))
		ci.draw_rect(Rect2(x, y, 10, 14), Color(0.96, 0.93, 0.85, a))
		ci.draw_rect(Rect2(x + 1, y + 1, 8, 12), Color(col.r, col.g, col.b, a * 0.35))
		Gfx.text(ci, CARD_GLYPH.get(c["name"], "?"), x + 5, y + 4, "red" if c["name"] in ["MEND", "BLADES"] else "white", 1, 0.5, false, a)
		if cards.size() == 1:   # a single draw names its card; a dealt hand shows symbols only
			Gfx.text(ci, c["name"], x + 5, y + 17, "white", 1, 0.5, true, a)

## Nearest bitmap-font colour for a hex colour (the font has a fixed set).
static func _font_col(hex: String) -> String:
	match hex.to_lower():
		"#f2c94c": return "gold"
		"#6fd3e0", "#4d9be6": return "cyan"
		"#d8443c": return "red"
		"#e86a8e": return "pink"
		"#e8873a": return "orange"
		"#a35bd6": return "purple"
		"#8b8f9c", "#d9d0b4": return "bone"
		"#b8e05a", "#63b84f": return "lime"
	return "white"

## Occasional glint on coins and gems.
static func glint(ci: CanvasItem, x: float, y: float) -> void:
	if _rng.randf() < 0.04:
		var c := Color(1, 1, 0.9, 0.9)
		ci.draw_rect(Rect2(roundf(x), roundf(y - 2), 1, 3), c)
		ci.draw_rect(Rect2(roundf(x - 1), roundf(y - 1), 3, 1), c)
