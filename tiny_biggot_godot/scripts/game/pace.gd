class_name Pace
extends RefCounted
## 35.2 PACE (his word, 9 Oct: "immediate dopamine and hyper-fast pacing"). Measured first with
## --pace-log (debug_pace.gd, the bot on three heroes): a fight's first foe is up in 0.5 s and the
## next wave follows at once, but the last one or two foes of a room took 1.6-4.3 s a room on
## average (up to 19 s in elite rooms), and walking out took about 2 s. So, in the expanded game:
##   QUICKER WAVES  the next wave comes when the one before is down to its last 2 foes (it waited
##                  for the last one), 0.35 s later (was 0.6); a foe takes 0.55 s to appear (0.75).
##   FINISH THEM    the last wave down to its last one or two foes for 2 s: they are marked (a red
##                  arrow over each) and you hit 30% harder and move 15% faster until it is clear.
##   CLEAR RUSH     a cleared fight: +35% move speed until you leave the room.
##   FIRST SPOILS   the power spike of the first rooms: the first fight of a run leaves an old chest
##                  (a relic to choose), the second a rare or better weapon or armour piece.
## Nothing is toned down: foes are as many and as strong, there is just less waiting.

const WAVE_GATE := 2
const WAVE_GAP := 0.35
const SPAWN_T := 0.55
const TAIL_T := 2.0
const FINISH_DMG := 1.3
const FINISH_SPEED := 1.15
const RUSH_SPEED := 1.35

static var tail_t := 0.0
static var finishing := false
static var rushing := false
static var stats := {}   # finish, rush, spoils (tests)

static func on() -> bool:
	return GameData.rogues()

static func reset() -> void:
	tail_t = 0.0
	finishing = false
	rushing = false

## How long a new foe takes to appear (Combat.spawn_enemy; world_view draws it rising).
static func spawn_time() -> float:
	return SPAWN_T if on() else 0.75

## Foes left that let the next wave in (Game.update_play), and the gap before it.
static func wave_gate() -> int:
	return WAVE_GATE if on() else 1

static func wave_gap() -> float:
	return WAVE_GAP if on() else 0.6

## Every logic tick of a locked fight room (Game.update_play).
static func tick(dt: float, alive: int, waves_left: int) -> void:
	if not on():
		return
	if waves_left <= 0 and alive > 0 and alive <= 2:
		tail_t += dt
		if tail_t >= TAIL_T and not finishing:
			finishing = true
			stats["finish"] = stats.get("finish", 0) + 1
			G.toast("FINISH THEM!", "red")
	else:
		tail_t = 0.0
		finishing = false

## Weapons.wdmg and the hero's walk.
static func dmg_mult() -> float:
	return FINISH_DMG if finishing else 1.0

static func speed_mult() -> float:
	return (FINISH_SPEED if finishing else 1.0) * (RUSH_SPEED if rushing else 1.0)

## Game.enter_room.
static func on_enter() -> void:
	reset()

## Game.room_cleared, for a fight room.
static func on_clear(r: Room) -> void:
	tail_t = 0.0
	finishing = false
	if not on() or not r.type in ["combat", "elite"]:
		return
	rushing = true
	stats["rush"] = stats.get("rush", 0) + 1
	var n: int = G.run_stats.get("fights", 0) + 1
	G.run_stats["fights"] = n
	if not r.theme.is_empty():
		return
	var cx := 14.0 * TB.TS
	var cy := 9.5 * TB.TS
	match n:
		1:
			r.objects.append({ "kind": "chest", "x": cx, "y": cy })
			G.show_banner("FIRST SPOILS", "AN OLD CHEST: CHOOSE A RELIC")
			stats["spoils"] = stats.get("spoils", 0) + 1
		2:
			var f: int = G.floor_index
			var it: Dictionary = Weapons.random_weapon(Gear.roll_item_rarity(f, "elite"), G.player.weapon) if randf() < 0.5 \
				else Gear.random_gear(Gear.roll_item_rarity(f, "elite"))
			G.drop_item(it, cx, cy + 20)
			G.show_banner("SECOND SPOILS", it["name"])
			stats["spoils"] = stats.get("spoils", 0) + 1

## The marks over the last foes (world_view, over the foes).
static func draw(ci: CanvasItem, t: float) -> void:
	if not finishing:
		return
	var bob := roundf(sin(t * 8.0) * 1.5)
	for e in G.enemies:
		if e.hp <= 0 or e.hidden or e.spawn_t > 0 or e.type in ["dummy", "target"]:
			continue
		var x := roundf(e.x)
		var y := roundf(e.y - e.r - 12 + bob)
		ci.draw_rect(Rect2(x - 4, y - 1, 9, 2), TB.c("#140f1c"))
		ci.draw_rect(Rect2(x - 3, y, 7, 1), TB.c("#d8443c"))
		ci.draw_rect(Rect2(x - 3, y + 1, 7, 2), TB.c("#140f1c"))
		ci.draw_rect(Rect2(x - 2, y + 1, 5, 1), TB.c("#ff6a5a"))
		ci.draw_rect(Rect2(x - 2, y + 3, 5, 2), TB.c("#140f1c"))
		ci.draw_rect(Rect2(x - 1, y + 2, 3, 1), TB.c("#d8443c"))
		ci.draw_rect(Rect2(x, y + 3, 1, 1), TB.c("#d8443c"))
