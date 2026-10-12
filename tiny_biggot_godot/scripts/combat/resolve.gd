class_name Resolve
extends RefCounted
## 56.3 RESOLVE (his playthrough, 12 Oct: "after i make my full build i just melt everything ... the
## bosses just melts in seconds ... make later bosses harder and have beaffier healthpools and armor
## and new mechanic"). Expanded game only; every guardian (the floors', the rifts', the final final
## bosses; not Rex, the good boy).
## A guardian can lose only so much of its health at once: its RESOLVE, the gold bar under its health.
## Every point of health it loses fills the bar; the bar empties slowly by itself. When it is full the
## guardian is UNBROKEN for 3.5 s: a golden shell, no blow hurts it, and it answers with its signature
## attack (Patterns), at most every 7 s. Then the bar is empty again.
## So a build that deals less than the bar empties never meets it, and a stronger one still wins
## faster the stronger it is, but no guardian falls in seconds: it takes at least t_min() seconds of
## fighting (30 s on the first floor, 7 s more each floor after, 140 s at most; 57, his ask "a little
## bit more ... at bosses": it was 25 s, 6 s and 120 s). The build is not
## touched: every blow lands as it always did, on everything else and on a guardian that is not
## UNBROKEN.

const IMMUNE := 3.5
const SIG_GAP := 7.0
const RIFT_GAP := 9.0   # a rift guardian adds one of its patterns this often (Patterns)

static var off := false   # tests of what came before: a guardian falls to the blows they deal

static func on(e: Enemy) -> bool:
	return GameData.rogues() and not off and e.is_boss() and e.boss != "rex"

static func depth() -> int:
	return G.floor_index + 11 * G.loop

## The fewest seconds of fighting a guardian of this depth takes.
static func t_min() -> float:
	return minf(140.0, 30.0 + 7.0 * depth())

## Its resolve: the share of its health it can lose before it is UNBROKEN.
static func cap() -> float:
	return IMMUNE / t_min()

## What the bar loses by itself each second, as a share of the health (a build slower than this never
## fills it: it would take 1.25 t_min() or longer anyway).
static func drain() -> float:
	return 0.8 * cap() / IMMUNE

## Combat.damage_enemy, before the blow: the most of `lose` (health) this blow may take.
static func allow(e: Enemy, lose: float) -> float:
	if not on(e):
		return lose
	if e.unbroken_t > 0:
		return 0.0
	return minf(lose, maxf(0.0, cap() - e.resolve) * e.max_hp)

## After the blow: the health it lost fills the bar; a full bar: UNBROKEN.
static func took(e: Enemy, lost: float) -> void:
	if not on(e) or lost <= 0.0 or e.hp <= 0:
		return
	e.resolve += lost / e.max_hp
	if e.resolve >= cap() * 0.999:
		_unbreak(e)

static func _unbreak(e: Enemy) -> void:
	e.resolve = cap()
	e.unbroken_t = IMMUNE
	Fx.float_text(e.x, e.y - e.r - 16, "UNBROKEN", "gold", true)
	Fx.burst(e.x, e.y - 4, ["#f2c94c", "#fff3b0", "#ffffff"], 16, 90)
	G.add_shake(4)
	Snd.play("shield")
	if e.sig_t <= 0 and e.state != &"stagebreak":
		e.sig_t = SIG_GAP
		Patterns.signature(e)   # 56.4: its answer

## A blow on an UNBROKEN guardian: nothing lands; now and then a word says why.
static func bounce(e: Enemy) -> void:
	if e.bounce_t <= 0:
		e.bounce_t = 0.6
		Fx.float_text(e.x + randf_range(-8, 8), e.y - e.r - 8, "UNBROKEN", "grey")

## Hazards.update, every tick: each guardian's bar empties, its shell fades; a rift guardian adds a
## pattern of its own now and then (56.4).
static func tick(dt: float) -> void:
	if not GameData.rogues():
		return
	for e: Enemy in G.enemies:
		if not on(e) or e.hp <= 0:
			continue
		e.bounce_t -= dt
		e.sig_t -= dt
		if e.unbroken_t > 0:
			e.unbroken_t -= dt
			if e.unbroken_t <= 0:
				e.resolve = 0.0
		else:
			e.resolve = maxf(0.0, e.resolve - drain() * dt)
		if RiftBosses.handles(e) and e.state != &"intro" and e.state != &"phase" and not e.hidden \
				and (e.boss != "arci" or e.phase >= 2):   # 58: the first guardian adds them only in his second phase
			e.pat_t -= dt
			if e.pat_t <= 0:
				e.pat_t = RIFT_GAP
				var ps := Patterns.of(e)
				Patterns.cast(e, ps[e.pat_n % ps.size()], e.phase >= 2)
				e.pat_n += 1
