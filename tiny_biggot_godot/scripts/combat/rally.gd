class_name Rally
extends RefCounted
## Rally: the Gaolbird wins a lost heart back by striking back at once (a
## hero with rally_n > 0; nobody else ever enters this code). After a hit
## that costs health, the lost half-hearts are at stake for a few seconds:
## land rally_n blows (a kill counts as three) and they come back. Run out
## of time, or take another hit first, and they are gone. Then rally rests
## for a while before it can start again. No random draws of its own.

const WINDOW := 3.0
const COOLDOWN := 8.0
const KILL_BLOWS := 3
const COL := "#f2c94c"

static func active(p: Player) -> bool:
	return p.rally_t > 0

## 0..1 time left, for the HUD and the marker over the hero.
static func time_left(p: Player) -> float:
	return clampf(p.rally_t / (WINDOW + p.g("rally_window")), 0.0, 1.0)

## A real hit took `lost` half-hearts and the hero lives.
static func on_hurt(p: Player, lost: int) -> void:
	if p.rally_t > 0:
		_end(p, false)   # hit again before winning it back
		return
	if p.rally_cd > 0 or lost <= 0:
		return
	p.rally_hp = lost
	p.rally_prog = 0
	p.rally_t = WINDOW + p.g("rally_window")
	Juice.label("RALLY!", COL, p.x, p.y - 22)

static func on_blow(p: Player, n: int) -> void:
	if p.rally_t <= 0:
		return
	p.rally_prog += n
	if p.rally_prog >= p.rally_n:
		_end(p, true)

static func _end(p: Player, won: bool) -> void:
	var back := p.rally_hp
	p.rally_hp = 0
	p.rally_t = 0.0
	p.rally_prog = 0
	p.rally_cd = maxf(1.0, (COOLDOWN if won else COOLDOWN * 0.5) - p.g("rally_haste"))
	if won:
		p.heal(back)
		Juice.rallied(p)
	else:
		Juice.label("LOST", "#8b8f9c", p.x, p.y - 22)

static func update(p: Player, dt: float) -> void:
	if p.rally_cd > 0:
		p.rally_cd -= dt
	if p.rally_t > 0:
		if p.hp >= p.max_hp:
			# Healed to full some other way (a potion, a heart): nothing is at stake any more.
			p.rally_hp = 0
			p.rally_t = 0.0
			p.rally_prog = 0
			return
		p.rally_t -= dt
		if p.rally_t <= 0:
			_end(p, false)
