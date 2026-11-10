class_name Block
extends RefCounted
## 37.1 SHIELDS (his word, 9 Oct: "Ideas for sprites for new stuff, and new stuff to add": offhands;
## our own). An offhand (shields, the hand mirror) can stop hits that would land:
##   block_rate     blocks a 10 s: a hit is stopped every 10 / block_rate seconds (the OAK BUCKLER
##                  1.25: every 8 s). Several add up. A ready block shows as a small shield over
##                  the hero.
##   block_chance   a chance that any hit is stopped (the HAND MIRROR).
##   block_reflect  a stopped hit flies back as 5 shards at the foes, for 150%.
##   block_spikes   a stopped hit sends 8 spikes out around you.
## Checked in Combat._hurt_player_base after rolls, god mode and dodges, before armor and hearts.
## Expanded game only.

const SHARDS := 5
const SPIKES := 8

static var ready := false
static var t := 0.0
static var stats := {}   # blocks, chance (tests)

static func reset() -> void:
	ready = false
	t = 0.0

static func on(p: Player) -> bool:
	return GameData.rogues() and p != null and (p.g("block_rate") > 0 or p.g("block_chance") > 0)

## Combat.update_player: the block comes back.
static func tick(p: Player, dt: float) -> void:
	var rate := p.g("block_rate")
	if rate <= 0 or ready or not GameData.rogues():
		return
	t += dt
	if t >= 10.0 / rate:
		ready = true
		t = 0.0
		Fx.float_text(p.x, p.y - 20, "SHIELD UP", "grey")

## A hit that would land: true when a shield stops it.
static func stop(p: Player) -> bool:
	if not on(p):
		return false
	var by_chance := p.g("block_chance") > 0 and randf() < p.g("block_chance")
	if not ready and not by_chance:
		return false
	if not by_chance:
		ready = false
		t = 0.0
	stats["chance" if by_chance else "blocks"] = stats.get("chance" if by_chance else "blocks", 0) + 1
	p.invuln = maxf(p.invuln, 0.5)
	Fx.burst(p.x, p.y - 4, ["#c8ccd8", "#f4ecd8", "#8b8f9c"], 12, 70)
	Fx.float_text(p.x, p.y - 12, "BLOCKED", "white")
	Juice.ring(p.x, p.y - 4, 4, 24, 0.3, "#e8eef8")
	Snd.play("hit")
	var w := Weapons.wdmg(p)
	if p.g("block_reflect") > 0:
		var e := Combat.nearest_enemy(p.x, p.y, 400.0)
		var a := TB.ang_to(p, e) if e != null else randf() * TAU
		for i in SHARDS:
			Combat.spawn_pbullet(p, a + (i - (SHARDS - 1) / 2.0) * 0.18, w * 1.5 * p.g("block_reflect"), "spark")
	if p.g("block_spikes") > 0:
		for i in SPIKES:
			Combat.spawn_pbullet(p, i * TAU / SPIKES, w * 0.8 * p.g("block_spikes"), "spark")
	if not p.procs.is_empty():
		Effects.fire("on_dodge", { "x": p.x, "y": p.y })
	return true

## A small shield over the hero while a block is ready (world_view, top layer).
static func draw(ci: CanvasItem, p: Player, time: float) -> void:
	if not ready or not on(p):
		return
	var x := roundf(p.x) + 7
	var y := roundf(p.y) - 16 + (1.0 if fmod(time, 1.2) < 0.6 else 0.0)
	ci.draw_rect(Rect2(x - 1, y - 1, 7, 8), TB.c("#140f1c"))
	ci.draw_rect(Rect2(x, y, 5, 4), TB.c("#c8ccd8"))
	ci.draw_rect(Rect2(x + 1, y + 4, 3, 2), TB.c("#c8ccd8"))
	ci.draw_rect(Rect2(x + 2, y + 1, 1, 4), TB.c("#5a5e6c"))
