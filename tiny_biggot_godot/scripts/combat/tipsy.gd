class_name Tipsy
extends RefCounted
## 33.2 THE TAVERN (his word, 9 Oct: a STR melee build that needs no crits; ideas only, our own
## names). Drinks make you TIPSY: each stack multiplies your damage by 1.06 and your attack speed
## by 1.04, compounding (8 stacks: x1.59 damage, x1.37 speed). A stack wears off every 12 s.
## IRON GUT and the Tavern Knight raise what a drink gives and how high it goes; LAST ORDERS and
## BAR BRAWLER key off it (conditions "tipsy" and "very_tipsy"). The hero sways a little while
## tipsy (drawing only: aiming is not touched). Expanded game only.

const BASE_CAP := 8
const DMG_PER := 0.06
const RATE_PER := 0.04
const DECAY := 12.0
const VERY := 8

static func cap(p: Player) -> int:
	return BASE_CAP + int(p.g("tipsy_cap"))

## A drink: n stacks (and IRON GUT's extra).
static func add(p: Player, n: float) -> void:
	if p == null or not GameData.rogues():
		return
	var before := p.tipsy
	p.tipsy = minf(cap(p), p.tipsy + n + p.g("tipsy_gain"))
	p.tipsy_t = DECAY * (1.0 + p.g("tipsy_slow"))
	if int(p.tipsy) > int(before):
		Juice.label("TIPSY x%d" % int(p.tipsy), "#e8b84a", p.x, p.y - 30)

static func tick(p: Player, dt: float) -> void:
	if p.tipsy <= 0:
		return
	p.tipsy_t -= dt
	if p.tipsy_t <= 0:
		p.tipsy = maxf(0.0, p.tipsy - 1.0)
		p.tipsy_t = DECAY * (1.0 + p.g("tipsy_slow"))

static func dmg_mult(p: Player) -> float:
	return 1.0 if p.tipsy <= 0 else pow(1.0 + DMG_PER, int(p.tipsy))

static func rate_mult(p: Player) -> float:
	return 1.0 if p.tipsy <= 0 else pow(1.0 + RATE_PER, int(p.tipsy))

## How far the hero leans while tipsy (radians, drawing only).
static func sway(p: Player, t: float) -> float:
	if p.tipsy <= 0:
		return 0.0
	return sin(t * 2.3) * 0.006 * minf(p.tipsy, 10.0)
