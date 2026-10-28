class_name Bonfire
extends RefCounted
## 63 (his plan, 27 Oct: "bonfires from darksouls"; our own design): THE EMBER FIRE. In the expanded
## game, once on each floor, the first fight room cleared halfway down the floor has a ring of
## old standing stones rise in it, cold. Light it (free), feed it kindling for gold (twice at most:
## each makes it burn stronger), then sit by it once: it mends you (half your hearts, three
## quarters, all of them), fills your potions and your rolls, and a kindled fire leaves its warmth
## (more damage for a while). Every fire you light is counted, and pays EMBER SHARDS at the end
## of the run. Pictures drawn on PixelLab (resprite/pixellab/bonfire); the flame is drawn in code.

const HEAL := [0.5, 0.75, 1.0]   # of your hearts, by how kindled it is
const WARMTH := 0.1               # damage, a kindling, for 120 s
const MAX_KINDLE := 2

static func handles(kind: String) -> bool:
	return kind == "bonfire" or kind == "kindling"

## A cleared fight room (Game.on_clear): the floor's ember fire, once, halfway down.
static func on_clear(room: Room) -> void:
	var fd: Dictionary = G.floor_d
	if not GameData.rogues() or fd.get("bonfire", false) or not room.theme.is_empty() or not room.type in ["combat", "elite"]:
		return
	if room.depth < maxi(1, int(fd.get("total", 6)) / 2 - 1):
		return
	var at := _spot(room)
	if at.x < 0:
		return
	fd["bonfire"] = true
	var fire := { "kind": "bonfire", "x": at.x, "y": at.y, "lit": false, "level": 0 }
	room.objects.append(fire)
	room.objects.append({ "kind": "kindling", "x": at.x + 30, "y": at.y + 4 })
	Fx.burst(at.x, at.y, ["#4e4a5e", "#8b8f9c", "#e8873a"], 18, 60)
	G.add_shake(3)
	Snd.play("lock")
	G.toast("A RING OF STONES RISES: AN EMBER FIRE", "orange")

## Open floor for the ring (3 x 2 tiles) and its kindling, as near the middle as can be.
static func _spot(room: Room) -> Vector2:
	var best := Vector2(-1, -1)
	var bd := 1e9
	for r in range(TB.IY0 + 2, TB.IY0 + TB.IH - 3):
		for c in range(TB.IX0 + 2, TB.IX0 + TB.IW - 5):
			var ok := true
			for dr in 2:
				for dc in 5:
					if room.tile(c + dc, r + dr) != World.T_FLOOR:
						ok = false
			if not ok or c + 4 >= 10 and c <= 17 and r + 1 >= 7 and r <= 12:   # (not on the room's middle piece)
				continue
			var p := Vector2((c + 1.5) * TB.TS, (r + 1) * TB.TS)
			var d := p.distance_squared_to(Vector2(14 * TB.TS, 10 * TB.TS))
			for t in room.traps:
				if absi(t["c"] - c - 1) + absi(t["r"] - r) < 4:
					d += 1e6
			if d < bd:
				bd = d
				best = p
	return best

## The room's fire (the kindling's; looked up, not kept: a saved run copies its objects).
static func _fire() -> Dictionary:
	for o in G.room.objects:
		if o["kind"] == "bonfire":
			return o
	return { "lit": false, "level": 0, "x": 0.0, "y": 0.0 }

static func kindle_price(fire: Dictionary) -> int:
	return G.price((12 + G.floor_index * 3) * (fire["level"] + 1))

static func prompt(o: Dictionary) -> Array:
	if o["kind"] == "kindling":
		var fire := _fire()
		if not fire["lit"]:
			return ["KINDLING", "LIGHT THE FIRE FIRST", ""]
		return ["KINDLING", "FEED THE FIRE: IT MENDS MORE AND LEAVES +10% DAMAGE FOR 120S", "PAY %d GOLD" % kindle_price(fire)]
	if not o["lit"]:
		return ["A COLD EMBER FIRE", "LIGHT IT", ""]
	return ["EMBER FIRE" + (" +%d" % o["level"] if o["level"] > 0 else ""), "SIT: MEND %d%% OF YOUR HEARTS, FILL POTIONS AND ROLLS. ONCE" % roundi(HEAL[o["level"]] * 100), ""]

static func interact(o: Dictionary) -> void:
	var p := G.player
	if o["kind"] == "kindling":
		var fire := _fire()
		if not fire["lit"]:
			return G.deny(o, "LIGHT THE FIRE FIRST")
		var cost := kindle_price(fire)
		if p.gold < cost:
			return G.deny(o, "NEED %d GOLD" % cost)
		p.gold -= cost
		fire["level"] += 1
		fire["t"] = G.time
		if fire["level"] >= MAX_KINDLE:
			o["used"] = true
		Snd.play("coin")
		Fx.burst(fire["x"], fire["y"] - 10, ["#e8873a", "#f2c94c", "#fff07a"], 24, 80)
		G.toast("THE FIRE ROARS HIGHER", "orange")
		return
	if not o["lit"]:
		o["lit"] = true
		o["t"] = G.time
		G.run_stats["fires"] = G.run_stats.get("fires", 0) + 1
		Meta.meta["fires"] = Meta.meta.get("fires", 0) + 1
		Snd.play("unlock")
		Fx.burst(o["x"], o["y"] - 8, ["#e8873a", "#f2c94c"], 26, 70)
		G.show_banner("EMBER FIRE LIT", "REST HERE ONCE. FIRES LIT THIS RUN: %d" % G.run_stats["fires"])
		return
	o["used"] = true
	for k in G.room.objects:
		if k["kind"] == "kindling":
			k["used"] = true
	p.heal(ceili(p.max_hp * HEAL[o["level"]]))
	p.potions = maxi(p.potions, p.max_potions)
	p.charges = p.dodge_charges
	if o["level"] > 0:
		Effects.add_buff(p, "dmg", WARMTH * o["level"], 120.0)
	Snd.play("relic")
	Fx.burst(p.x, p.y, ["#e8873a", "#f2c94c", "#f4ecd8"], 20, 50)
	G.toast("YOU REST BY THE EMBER FIRE", "orange")

## EMBER SHARDS at the run's end (Game.award_embers): two a fire lit.
static func award(parts: Array) -> void:
	var n: int = G.run_stats.get("fires", 0)
	if n > 0:
		parts.append(["EMBER FIRES", n * 2])

# ---------- drawing ----------
static func draw(ci: CanvasItem, o: Dictionary, t: float) -> void:
	var x: float = o["x"]
	var y: float = o["y"]
	if o["kind"] == "kindling":
		var tk := Img.t("bf_kindling")
		if not o.get("used", false) or not _fire()["lit"]:
			ci.draw_texture(tk, Vector2(roundf(x - tk.get_width() / 2.0), roundf(y + 6 - tk.get_height())))
		return
	var lit: bool = o["lit"]
	var tex := Img.t("bf_fire_lit" if lit else "bf_fire_cold")
	var w := tex.get_width()
	var h := tex.get_height()
	ci.draw_texture(tex, Vector2(roundf(x - w / 2.0), roundf(y + 8 - h)))
	if not lit:
		if fmod(t * 0.7, 1.0) < 0.5:   # a last ember, pulsing
			ci.draw_rect(Rect2(x - 1, y - 2, 2, 1), Color(0.95, 0.5, 0.2, 0.4 + 0.4 * sin(t * 4.0)))
		return
	# the flame: tongues that flicker and grow with each kindling; then sparks
	var lv: int = o["level"]
	var rest: bool = o.get("used", false)
	var tall := (7.0 + lv * 4.0) * (0.7 if rest else 1.0)
	var since: float = G.time - o.get("t", -10.0)
	var flare := 1.0 + maxf(0.0, 1.0 - since * 1.5) * 0.8   # a flare when lit or fed
	var base := Vector2(x, y - 4)
	for i in 5:
		var off := (i - 2) * 2.2
		var fl := 0.75 + 0.25 * sin(t * (11.0 + i * 1.7) + i * 2.1)
		var hgt := tall * fl * flare * (1.0 - absf(i - 2) * 0.22)
		var sway := sin(t * 6.0 + i) * 1.0
		ci.draw_colored_polygon(PackedVector2Array([base + Vector2(off - 2.2, 0), base + Vector2(off + 2.2, 0),
			base + Vector2(off + sway, -hgt)]), Color(0.91, 0.45, 0.16, 0.9))
		ci.draw_colored_polygon(PackedVector2Array([base + Vector2(off - 1.1, 0), base + Vector2(off + 1.1, 0),
			base + Vector2(off + sway * 0.6, -hgt * 0.6)]), Color(1.0, 0.85, 0.35, 0.95))
	for i in 3 + lv * 2:
		var f := fmod(t * 0.8 + i * 0.37, 1.0)
		var sp := base + Vector2(sin(i * 2.3 + t) * (3.0 + f * 5.0), -tall - f * (14.0 + lv * 4.0))
		ci.draw_rect(Rect2(sp.x, sp.y, 1, 1), Color(1.0, 0.75, 0.3, 1.0 - f))
