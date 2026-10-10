class_name Gourd
extends RefCounted
## 47.1 THE GOURD (his list of another game's core gameplay, 10 Oct: "a refillable single-use
## health flask"; GAMEPLAY_PLAN.md; the name and numbers are this game's own). Every hero of the
## expanded game carries one: HEAL drinks a sip from it before any potion (Player.try_heal), a sip
## heals 2 hearts and counts as a potion for what you carry (on_potion, ELIXIR), and the gourd fills
## again at the floor's rest stop (once a floor) and whenever a guardian falls. Relics give it more
## sips (gf gourd_sips: WAYFARER'S CORK) or stronger ones (gf gourd_heal, half-hearts: HONEY
## STOPPER). Potions stay as they were (rule 1). Classic has no gourd.

const SIPS := 1
const SIP_HEAL := 4   # half-hearts: 2 hearts

static var stats := {}   # sips, fills (tests)

static func on() -> bool:
	return GameData.rogues()

## Game.new_run: the hero's gourd, full.
static func start(p: Player) -> void:
	if not on():
		return
	p.gourd_max = SIPS
	p.gourd = SIPS

static func max_sips(p: Player) -> int:
	return p.gourd_max + int(p.g("gourd_sips")) if p.gourd_max > 0 else 0

static func heal_amount(p: Player) -> int:
	return SIP_HEAL + int(p.g("gourd_heal"))

## Player.try_heal: a sip, if there is one and a heart to heal. True if it drank.
static func sip(p: Player) -> bool:
	if not on() or p.gourd <= 0 or p.hp >= p.max_hp:
		return false
	p.gourd -= 1
	p.heal(heal_amount(p))
	stats["sips"] = stats.get("sips", 0) + 1
	Fx.float_text(p.x, p.y - 22, "A SIP FROM THE GOURD", "lime")
	return true

## Full again: the rest stop (enter_room), a guardian's fall (Game.on_boss_dead).
static func fill(p: Player) -> void:
	if not on() or p.gourd_max <= 0:
		return
	var m := max_sips(p)
	if p.gourd >= m:
		return
	p.gourd = m
	stats["fills"] = stats.get("fills", 0) + 1
	Fx.float_text(p.x, p.y - 30, "THE GOURD IS FULL", "lime")

## Game.enter_room: the floor's rest stop fills it, once a floor.
static func on_room(p: Player, r: Room) -> void:
	if not on() or r.type != "rest" or G.floor_d.get("gourd_rest", false):
		return
	G.floor_d["gourd_rest"] = true
	fill(p)

## The HUD, before the potions: one gourd a sip, dim when drunk. Returns the x after them.
static func draw_hud(ci: CanvasItem, p: Player, x: float, y: float) -> float:
	var n := max_sips(p)
	for i in n:
		Gfx.at(ci, "gourd", x + 1, y, 1.0 if i < p.gourd else 64 / 255.0)
		x += 9
	return x + (3 if n > 0 else 0)
