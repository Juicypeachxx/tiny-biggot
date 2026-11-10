class_name Marvels
extends RefCounted
## 43.1 (his pictures of a wiki's Super Hero, Esper and Cyborg traits, 10 Oct; ideas only, our own
## names and pictures, TRAITS_PLAN.md): what the Stage 43 traits need, in one place. SUPER traits
## come to every hero; PSYCHIC traits (psy_) only to the Mindwarden, AUGMENT traits (aug_) only to
## the Tinkerer (TraitRules.meets). Expanded game only: in classic every hook is 0 and none of
## these traits are offered.
##   EMPTY SLOTS    damage per empty gear slot (idle_hands, up to +250%)
##   MIND LINK      a share of your helpers' damage bonus is yours (mind_link); one helper alone
##                  hits five times as hard; puppets hit at 30% (marionette)
##   STANDING STILL ailments tick faster (still_ticks); knives make bleeds tick faster (bleed_moon)
##   BURNS          a burn tick also takes a share of the foe's health (burn_pct)
##   SHOCK          more shock a foe can hold (shock_max; Statuses.shock_cap)
##   THE SPECIAL    a laser for 8 s (laser_core), more special power each time it is used and
##                  drinks a room longer (dilation), its blows chill and hit harder (cryo_core),
##                  power counts as special power (power_core)
##   DICE           every die used this run: lucky hit chance (dice_mind)
##   FLOORS         you rise again once a floor (revive_floor)

const SLOTS_LAZY := 0.25
const LAZY_MAX := 2.5

static var laser_t := 0.0
static var laser_cd := 0.0
static var dilation := 0
static var stats := {}

static func on() -> bool:
	return GameData.rogues()

static func reset() -> void:
	laser_t = 0.0
	laser_cd = 0.0
	dilation = 0

static func _stat(k: String) -> void:
	stats[k] = stats.get(k, 0) + 1

## Every gear slot the hero has (Gear.slots: the expanded game's offhand, gloves, rings...) left empty.
static func empty_slots(p: Player) -> int:
	var n := 0
	for k in Gear.slots():
		if p.gear.get(k) == null:
			n += 1
	return n

# ---------- damage ----------
## Might.dmg_mult: IDLE HANDS (empty gear slots), MIND LINK (a quarter of your helpers' bonus).
static func dmg_mult(p: Player) -> float:
	if not on():
		return 1.0
	var m := 1.0
	if p.g("idle_hands") > 0:
		m *= 1.0 + minf(LAZY_MAX, p.g("idle_hands") * empty_slots(p))
	if p.g("mind_link") > 0:
		m *= 1.0 + p.g("mind_link") * maxf(0.0, Legion.dmg_mult(p) - 1.0)
	return m

## Legion.dmg_mult: MIND LINK (one helper alone: x5), PUPPET STRINGS (x0.3).
static func helper_mult(p: Player) -> float:
	if not on():
		return 1.0
	var m := 1.0
	if p.g("mind_link") > 0 and Finesse.helpers(p) == 1:
		m *= 5.0
	if p.g("marionette") > 0:
		m *= 0.3
	return m

## Combat.damage_enemy: HAND-ME-DOWNS (bows and guns crit more).
static func crit_chance(p: Player) -> float:
	if not on() or p.g("ranged_crit") <= 0 or not Might.ranged(p.weapon):
		return 0.0
	return p.g("ranged_crit")

## Combat.damage_enemy: CRYO CORE: the special's blows chill and hit harder.
static func foe_mult(p: Player, e: Enemy) -> float:
	if not on() or p.g("cryo_core") <= 0 or not Might.casting:
		return 1.0
	if e.hp > 0:
		Statuses.apply(e, "chill", 1, 0)
	return 1.0 + p.g("cryo_core")

## Finesse.special_power: SLOW TIME (+10% each special used, up to +200%), OVERDRIVE CORE (power).
static func special_add(p: Player) -> float:
	if not on():
		return 0.0
	var s := 0.0
	if p.g("dilation") > 0:
		s += minf(2.0, 0.1 * dilation)
	if p.g("power_core") > 0:
		s += Might.power(p) / 100.0
	return s

# ---------- ticks ----------
## Finesse.tick_rate: MIND STORM, standing still.
static func tick_add(p: Player) -> float:
	if not on() or p.g("still_ticks") <= 0 or p.moving:
		return 0.0
	return p.g("still_ticks")

## Combat's bleed tick: KITCHEN KNIVES (+10% a moon).
static func bleed_rate(p: Player) -> float:
	if not on() or p.g("bleed_moon") <= 0:
		return 1.0
	return 1.0 + 0.1 * p.orbitals

## Combat's burn tick: INNER FIRE takes a share of the foe's health (a fifth of it from a boss).
static func burn_extra(p: Player, e: Enemy) -> float:
	if not on() or p.g("burn_pct") <= 0:
		return 0.0
	return e.max_hp * p.g("burn_pct") * (0.2 if e.is_boss() else 1.0)

## Lucky.chance: DICE MIND, for every die used this run (Player.dice_used).
static func lucky_add(p: Player) -> float:
	if not on() or p.g("dice_mind") <= 0:
		return 0.0
	return p.g("dice_mind") * p.dice_used

# ---------- events ----------
## Might.cast, the special used: BEAM CORE, SLOW TIME.
static func on_special(p: Player) -> void:
	if not on():
		return
	if p.g("laser_core") > 0:
		laser_t = 8.0
		laser_cd = 0.0
	if p.g("dilation") > 0:
		dilation += 1
		for d in p.drinks:
			d[1] += 1   # a room longer
		Infusions.stretch(p, 1)   # 44: the saps too
		_stat("dilation")

## Game.start_floor: SAINT AND SINNER.
static func on_floor(p: Player) -> void:
	if on() and p.g("revive_floor") > 0:
		p.revive = maxi(p.revive, 1)

## Combat.update_player while the laser runs.
static func tick(p: Player, dt: float) -> void:
	if laser_t <= 0:
		return
	laser_t -= dt
	laser_cd -= dt
	if laser_cd > 0:
		return
	laser_cd = 0.4
	var e := Combat.nearest_enemy(p.x, p.y, 400.0)
	if e != null:
		Combat.spawn_pbullet(p, TB.ang_to(p, e), Weapons.wdmg(p) * 0.8, "rail")
		_stat("laser")
