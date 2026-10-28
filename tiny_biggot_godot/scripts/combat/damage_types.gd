class_name DamageTypes
extends RefCounted
## Stage 50 (his word, 11 Oct: "Do stage 50"; GAMEPLAY_PLAN.md): five more damage types for weapons,
## each with its colour, its ailment and its reactions (reactions.gd). A weapon's type is the "dtype"
## on its row (WeaponInfo.damage_type); a hit of the weapon itself (Combat.on_hit_effects) brings the
## ailment 30% of the time, twice that on a crit. Expanded game only (the rows that carry a dtype are
## all past the originals).
##   RADIANT   SEARED (3 s): a seared foe bursts in light when it dies, hurting the foes near it for
##             your weapon's damage. Radiant hits on a cursed foe deal half again.
##   NECROTIC  ROT (stacks up to 10, 4 s): each stack eats 0.5% of the foe's most health a second
##             (guardians, minis and champions 0.15%).
##   DARK      GLOOM (statuses.gd). A dark hit on a foe in deep gloom (5 or more) may call a shade, a
##             wisp that fights for you for 6 s (one time in ten).
##   ENERGY    CHARGED (stacks up to 5, 3 s): the fifth charge discharges in a blast for 150% of the
##             hit around the foe, and the charges start over.
##   SOUND     RATTLED (stacks up to 6, 3 s): from 3 stacks the foe is weakened (slower); the sixth
##             stuns it and the stacks start over.
## Their reactions (reactions.gd): SEARED + GLOOM = ECLIPSE, ROT + POISON = BLIGHT, CHARGED + SHOCK =
## SUPERCONDUCT, RATTLED + CHILL = CRACKLE, RATTLED + CHARGED = FEEDBACK.

const TYPES := ["RADIANT", "NECROTIC", "DARK", "ENERGY", "SOUND"]
const COL := { "RADIANT": "gold", "NECROTIC": "green", "DARK": "purple", "ENERGY": "cyan", "SOUND": "bone" }
const HEX := { "RADIANT": "#fff07a", "NECROTIC": "#7ad04a", "DARK": "#a35bd6", "ENERGY": "#6fe8ff", "SOUND": "#f4ecd8" }
const AILMENT := { "RADIANT": "seared", "NECROTIC": "rot", "DARK": "gloom", "ENERGY": "charged", "SOUND": "rattled" }
const CHANCE := 0.3
const ROT_MAX := 10
const CHARGE_MAX := 5
const RATTLE_MAX := 6

static var stats := {}   # what happened, by name (tests/stage50_test reads it)

static func _stat(k: String) -> void:
	stats[k] = stats.get(k, 0) + 1

## The damage type of the weapon in hand, if it is one of the five ("" else).
static func of(p: Player) -> String:
	if p == null or p.weapon == null:
		return ""
	return String(p.weapon.get("dtype", ""))

static func _big(e: Enemy) -> bool:
	return e.is_boss() or e.d.get("mini", false) or e.d.get("champion", false)

## Combat.on_hit_effects: a hit of the weapon itself.
static func on_hit(p: Player, e: Enemy, dmg: float, crit: bool) -> void:
	var t := of(p)
	if t == "" or e.hp <= 0 or not GameData.rogues():
		return
	if t == "RADIANT" and e.curse_t > 0:
		Combat.damage_enemy(e, dmg * 0.5, { "no_crit": true, "no_mult": true, "col": "gold", "silent": true })
		_stat("smite")
	if t == "DARK" and e.gloom >= 5 and randf() < 0.1 \
			and mini(p.familiars, Effects.SUMMON_CAP) + G.temp_fams.size() < Effects.SUMMON_CAP:
		G.temp_fams.append({ "x": e.x, "y": e.y, "cd": 0.2, "t": 6.0 })
		_stat("shade")
	if e.hp > 0 and randf() < CHANCE * (2.0 if crit else 1.0):
		Statuses.apply(e, AILMENT[t], 1, dmg)

## Statuses.apply: one more charge; the fifth discharges (CAPACITOR: the third, twice as wide;
## LIVE WIRE: lightning leaps from it to foes near it).
static func charge(e: Enemy, n: int, hit_dmg: float) -> void:
	var p := G.player
	var cap := 3 if p != null and p.g("charge_fast") > 0 else CHARGE_MAX
	e.charge = mini(cap, e.charge + n)
	e.charge_t = 3.0
	if e.charge < cap:
		return
	e.charge = 0
	e.charge_t = 0.0
	_stat("discharge")
	Fx.texts.append({ "x": e.x, "y": e.y - e.r - 16, "text": "DISCHARGE!", "col": "cyan", "life": 0.7, "big": false })
	var dmg := maxf(hit_dmg, Weapons.wdmg(p)) * 1.5
	Combat.explode_at(e.x, e.y, dmg, null, 80 if cap < CHARGE_MAX else 40, HEX["ENERGY"])
	var jumps := int(p.g("discharge_chain")) if p != null else 0
	if jumps > 0:
		for o in G.enemies.duplicate():
			if jumps <= 0:
				break
			if o != e and o.targetable() and o.charm_t <= 0 and TB.dist(o, e) < 120.0:
				Combat.lightning(o, dmg * 0.5)
				jumps -= 1

## Statuses.apply: rattled more; from 3 weakened, the sixth stuns.
static func rattle(e: Enemy, n: int) -> void:
	e.rattle = mini(RATTLE_MAX, e.rattle + n)
	e.rattle_t = 3.0
	if e.rattle >= 3:
		e.weak_t = maxf(e.weak_t, 0.6)
	if e.rattle >= RATTLE_MAX:
		e.rattle = 0
		e.stun_t = maxf(e.stun_t, 0.25 if _big(e) else 0.9)
		_stat("rattled")
		Fx.texts.append({ "x": e.x, "y": e.y - e.r - 16, "text": "RATTLED!", "col": "bone", "life": 0.7, "big": false })

## Statuses.tick: rot eats a share of the foe's most health every half second.
static func tick_rot(e: Enemy, dt: float) -> void:
	e.rot_tick -= dt
	if e.rot_tick > 0.0:
		return
	e.rot_tick = 0.5
	var pct := 0.0015 if _big(e) else 0.005
	Combat.damage_enemy(e, e.max_hp * pct * 0.5 * e.rot, { "no_crit": true, "no_mult": true, "col": "green", "silent": true })
	_stat("rot")

static var _heal_t := 0.0   # 53.2 DAWNBURST: the next burst that may heal (G.time)

## Combat.kill_enemy: a seared foe bursts in light (DAWNBURST: twice as wide, and it may heal); a
## rotting foe's rot spreads to the foes near it (LICH TOUCH).
static func on_death(e: Enemy) -> void:
	var p := G.player
	if not GameData.rogues() or p == null:
		return
	if e.rot > 0 and p.g("rot_spread") > 0:
		var n := e.rot
		e.rot = 0
		for o in G.enemies.duplicate():
			if o != e and o.hp > 0 and o.targetable() and o.charm_t <= 0 and TB.dist(o, e) < 70.0 + o.r:
				Statuses.apply(o, "rot", n, Weapons.wdmg(p))
		_stat("rot_spread")
	if e.seared_t <= 0.0:
		return
	e.seared_t = 0.0
	_stat("burst")
	var wide := p.g("sear_wide") > 0
	Combat.explode_at(e.x, e.y, Weapons.wdmg(p), e, 80 if wide else 40, HEX["RADIANT"])
	if p.g("sear_heal") > 0 and G.time >= _heal_t:
		_heal_t = G.time + 6.0
		p.heal(1)

## Over the foes (world_view): a mark for each of the new ailments.
static func draw_over(ci: CanvasItem, t: float) -> void:
	for e in G.enemies:
		if e.seared_t <= 0.0 and e.rot <= 0 and e.charge <= 0 and e.rattle <= 0:
			continue
		var top := Vector2(e.x, e.y - e.r - 10.0)
		var x := top.x - 8.0
		if e.seared_t > 0.0:   # a little sun
			var c := Color(1.0, 0.95, 0.5)
			ci.draw_rect(Rect2(roundf(x), roundf(top.y), 2, 2), c)
			for k in 4:
				var m := Vector2(x + 1.0, top.y + 1.0) + Vector2.from_angle(t * 4.0 + k * PI / 2.0) * 3.0
				ci.draw_rect(Rect2(roundf(m.x), roundf(m.y), 1, 1), c)
			x += 7.0
		if e.rot > 0:   # green drips, one more for every few stacks
			for k in mini(3, 1 + e.rot / 4):
				var dy := fmod(t * 6.0 + k * 1.7, 4.0)
				ci.draw_rect(Rect2(roundf(x + k * 2.0), roundf(top.y + dy), 1, 2), Color(0.48, 0.82, 0.29))
			x += 7.0
		if e.charge > 0:   # a pip for each charge
			for k in e.charge:
				ci.draw_rect(Rect2(roundf(x + k * 2.0), roundf(top.y), 1, 2), Color(0.45, 0.92, 1.0) if fmod(t * 8.0, 2.0) < 1.6 else Color(1, 1, 1))
			x += 2.0 * e.charge + 3.0
		if e.rattle > 0:   # sound waves
			for k in mini(3, (e.rattle + 1) / 2):
				ci.draw_arc(Vector2(x, top.y + 1.0), 2.0 + k * 2.0, -0.9, 0.9, 6, Color(0.96, 0.93, 0.85, 0.9 - k * 0.2), 1.0)
