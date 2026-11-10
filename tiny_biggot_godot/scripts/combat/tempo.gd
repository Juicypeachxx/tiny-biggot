class_name Tempo
extends RefCounted
## Tempo: the Gaolbird's momentum (a hero with tempo_max > 0; nobody else
## ever enters this code). Blows and kills build it, one point at a time:
## every point is +2.5% move speed and +4% fire rate. At the top the hero is
## IN FULL FLIGHT: +20% crit, and rolls cut through foes. Stop landing blows
## and it fades; take a hit and half of it is gone.
##
## The bonuses are ordinary additive-% stat effects, applied and taken back
## whenever the level changes (the same way the Racketeer's heat works), so
## every stat screen and every other effect sees them. No random draws.

const GRACE := 3.0          # seconds without a blow before tempo starts to fade
const FADE := 0.7           # seconds per point while it fades
const HITS := 5             # blows that make one point
const SPEED := 0.025
const RATE := 0.04
const FLIGHT_CRIT := 0.2
const COL := "#e86fb4"
const TRAIL_COL := Color("#e86fb4")

static func effects(n: int, full: bool) -> Array:
	var out := [["pct", "speed", SPEED * n], ["pct", "rate", RATE * n]]
	if full:
		out.append(["add", "crit", FLIGHT_CRIT])
		out.append(["hook", "flight", 1])
	return out

static func full(p: Player) -> bool:
	return p.tempo_max > 0 and p.tempo >= p.tempo_max

static func set_to(p: Player, v: int) -> void:
	v = clampi(v, 0, p.tempo_max)
	if v == p.tempo:
		return
	var was_full := full(p)
	# Take back exactly what was given (the list is kept on the player), then give the new level's.
	if not p.tempo_fx.is_empty():
		Effects.apply(p, p.tempo_fx, -1)
	p.tempo = v
	p.tempo_fx = effects(v, full(p)) if v > 0 else []
	if v > 0:
		Effects.apply(p, p.tempo_fx, 1)
	if full(p) and not was_full:
		Juice.full_flight(p)
		Snd.play("unlock")

## Raises (or lowers) tempo; a gain also restarts the fade clock.
static func add(p: Player, n: int) -> void:
	if n > 0:
		p.tempo_t = GRACE + p.g("tempo_hold")
		p.tempo_fade = 0.0
	set_to(p, p.tempo + n)

## A blow landed on a foe (not a training dummy).
static func on_hit(p: Player) -> void:
	p.tempo_t = GRACE + p.g("tempo_hold")
	p.tempo_fade = 0.0
	p.tempo_hits += 1
	if p.tempo_hits >= HITS:
		p.tempo_hits = 0
		add(p, 1)

static func on_kill(p: Player, e: Enemy) -> void:
	add(p, 3 if e.is_boss() else (2 if e.elite else 1))

## A real hit landed on the hero: half the tempo is gone (at most 2 points with the capstone).
static func on_hurt(p: Player) -> void:
	if p.tempo <= 0:
		return
	var lost := (p.tempo + 1) >> 1
	if p.g("tempo_grit") > 0:
		lost = mini(lost, 2)
	set_to(p, p.tempo - lost)
	p.tempo_hits = 0
	Juice.label("TEMPO -%d" % lost, "#8b8f9c", p.x, p.y - 30)

static func update(p: Player, dt: float) -> void:
	if p.tempo <= 0:
		return
	# Afterimages (drawing only): from 6 tempo the running hero leaves pink ghosts.
	if p.tempo >= 6 and p.moving and p.dodge_t <= 0 and p.dash_t <= 0 and int(G.time * 60.0) % 3 == 0:
		p.trail.append({ "x": p.x, "y": p.y, "life": 0.1 + 0.012 * p.tempo, "face": p.face, "col": TRAIL_COL })
	p.tempo_t -= dt
	if p.tempo_t > 0:
		return
	p.tempo_fade += dt
	if p.tempo_fade >= FADE:
		p.tempo_fade = 0.0
		set_to(p, p.tempo - 1)
