class_name Shatter
extends RefCounted
## 47.2 SHATTER (his list of another game's core gameplay, 10 Oct: "Armor Break" among the
## ailments; GAMEPLAY_PLAN.md; the name and numbers are this game's own). An ailment for every foe:
## its stacks (up to MAX, Enemy.shatter) crack its guard, each one +PER damage taken (gf shatter_x
## adds as much again a point: CRACKED GEODE), and they fall away TIME seconds after the last one
## (Enemy.shatter_t; Statuses.apply, dmg_mult, tick). A guardian's armour plates stay as they are
## (armor.gd); shatter counts on top. Where it comes from: blunt weapons' own hits (Might.blunt,
## BLUNT of the time), bombs (BOMB stacks to all they hit) and the SPLITTING WEDGE ("status"
## procs). Shards stick out of a shattered foe, one a stack. Expanded game only.

const MAX := 5
const PER := 0.05
const TIME := 4.0
const BLUNT := 0.15
const BOMB := 2

static var stats := {}   # stacks (tests)

static func on() -> bool:
	return GameData.rogues()

## Statuses.apply "shatter".
static func add(e: Enemy, n: int) -> void:
	e.shatter = mini(MAX, e.shatter + maxi(1, n))
	e.shatter_t = TIME
	stats["stacks"] = stats.get("stacks", 0) + maxi(1, n)

## Statuses.dmg_mult: what a shattered foe takes.
static func mult(e: Enemy) -> float:
	var p := G.player
	var per := PER * (1.0 + (p.g("shatter_x") if p != null else 0.0))
	return 1.0 + per * e.shatter

## Combat.on_hit_effects: a blunt weapon's own blow may shatter.
static func on_hit(p: Player, e: Enemy, b: PBullet) -> void:
	if not on() or e.hp <= 0 or not (b == null or b.own) or not Might.blunt(p.weapon):
		return
	if randf() < BLUNT:
		Statuses.apply(e, "shatter", 1, 0.0)

## Combat.update_bombs: a bomb shatters every foe in its blast.
static func blast(x: float, y: float, r: float, n: int) -> void:
	if not on():
		return
	for e in G.enemies:
		if e.hp > 0 and e.targetable() and TB.dist_xy(e.x, e.y, x, y) < r + e.r:
			Statuses.apply(e, "shatter", n, 0.0)

## world_view: shards in a shattered foe, one a stack, around its body (y: its feet).
const SPOTS := [Vector2(-0.7, -1.3), Vector2(0.75, -0.9), Vector2(-0.2, -1.8), Vector2(0.4, -1.55), Vector2(-0.8, -0.6)]
static func draw(ci: CanvasItem, e: Enemy, y: float) -> void:
	var c0 := TB.c("#c8d0dc")
	var c1 := TB.c("#ffffff")
	for i in mini(e.shatter, SPOTS.size()):
		var sx := roundf(e.x + SPOTS[i].x * e.r)
		var sy := roundf(y + SPOTS[i].y * e.r)
		ci.draw_rect(Rect2(sx, sy, 2, 1), c0)
		ci.draw_rect(Rect2(sx + (1 if i % 2 == 0 else 0), sy - 1, 1, 1), c1)
