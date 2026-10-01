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

static func reset() -> void:
	pops.clear()
	rings.clear()
	hurt_t = 0.0
	flash_t = 0.0
	clear_t = 0.0
	recoil = 0.0

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

# ---------- Per logic tick (frozen during hitstop, like the game) ----------
static func update(dt: float, p: Player) -> void:
	for l in [pops, rings]:
		var i := 0
		while i < l.size():
			l[i]["t"] += dt
			if l[i]["t"] >= l[i]["max"]:
				l.remove_at(i)
			else:
				i += 1
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

## Occasional glint on coins and gems.
static func glint(ci: CanvasItem, x: float, y: float) -> void:
	if _rng.randf() < 0.04:
		var c := Color(1, 1, 0.9, 0.9)
		ci.draw_rect(Rect2(roundf(x), roundf(y - 2), 1, 3), c)
		ci.draw_rect(Rect2(roundf(x - 1), roundf(y - 1), 3, 1), c)
