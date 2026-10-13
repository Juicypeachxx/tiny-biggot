class_name Finesse
extends RefCounted
## 41.1 (his pictures of a wiki's DEXTERITY traits, 10 Oct; ideas only, our own names and pictures,
## TRAITS_PLAN.md): what the Stage 41 traits need, in one place. Expanded game only: in classic
## every hook is 0 and none of these traits are offered.
##   LETHAL HIT    on a foe under half its health: x2 (with LETHALITY: your crit damage instead): a
##                 chance (lethal), every hit from afar (sharpshooter), every lucky hit (cheap_shot)
##   CLOSE         within 50 px of a foe, or always with bows and guns (ballistics)
##   REPEATS       an attack that fires again (p.volleys); after a roll the next ones repeat at x2
##                 (two_steps); a repeat makes what you inflict twice as strong for 4 s (repeat_debuff)
##   TALLY         every 3rd attack, the hits of the next one are sure crits (tally)
##   TICK SPEED    how fast burns, poisons and bleeds tick (clockwork: your fire rate bonus too)
##   SPEED LEAD    your move speed above your hero's own: also fire rate (agility), roll and special
##                 recharge twice over (dynamo)
##   HELPERS       BOSOM BUDDY (+300/200/100% with 1/2/3 helpers), fields give rate (influence)
##   SPECIAL POWER damage your special deals: special_power, +per roll charge (special_per_roll)

const DEX_FAMS := ["edge", "shadow", "fortune"]

static var crit_next := 0
static var tally_n := 0
static var repeat_left := 0
static var repeat_t := 0.0
static var shot_mult := 1.0
static var swagger_t := 4.0
static var stats := {}

static func on() -> bool:
	return GameData.rogues()

static func reset() -> void:
	crit_next = 0
	tally_n = 0
	repeat_left = 0
	repeat_t = 0.0
	shot_mult = 1.0
	swagger_t = 4.0

static func _stat(k: String) -> void:
	stats[k] = stats.get(k, 0) + 1

static func dex_ranks(p: Player) -> int:
	var n := 0
	for f in DEX_FAMS:
		n += int(p.fam.get(f, 0))
	return n

static func speed_lead(p: Player) -> float:
	return maxf(0.0, p.speed / maxf(1.0, float(p.hero.get("speed", p.speed))) - 1.0)

static func helpers(p: Player) -> int:
	return mini(p.familiars, Effects.SUMMON_CAP + Legion.cap_bonus(p)) + G.temp_fams.size() + Summons.thralls.size() + Summons.turrets.size()

# ---------- distances ----------
static func close(p: Player, e: Enemy) -> bool:
	if TB.dist(e, p) < 50.0 + e.r:
		return true
	return on() and p.g("ballistics") > 0 and Might.ranged(p.weapon)

static func far(p: Player, e: Enemy) -> bool:
	return TB.dist(e, p) > 120.0

# ---------- the weapon's rate ----------
static func rate_mult(p: Player) -> float:
	if not on():
		return 1.0
	var m := 1.0
	if p.g("agility") > 0:
		m *= 1.0 + speed_lead(p)
	if p.g("alacrity") > 0 and p.weapon != null and Attributes.scaling(p.weapon)["dex"] != "-":
		m *= 1.0 + p.g("alacrity")
	if p.g("influence") > 0:
		m *= 1.0 + p.g("influence") * Auras.active(p).size()
	if p.g("spellblade") > 0 and Abilities.has_special(p):
		m *= 1.0 + p.g("spellblade") * (1.0 - Abilities.charge(p))
	return m

## Might.roll_rate and Might.special_rate: DYNAMO.
static func recharge_add(p: Player) -> float:
	if not on() or p.g("dynamo") <= 0:
		return 0.0
	return 2.0 * speed_lead(p)

static func special_power(p: Player) -> float:
	if not on():
		return 1.0
	return 1.0 + p.g("special_power") + p.g("special_per_roll") * p.dodge_charges + Arcana.special_add(p) + Marvels.special_add(p)   # (42.1 DEEP THOUGHT; 43.1)

## Legion.dmg_mult: BOSOM BUDDY.
static func helper_mult(p: Player) -> float:
	if not on() or p.g("bff") <= 0:
		return 1.0
	var n := helpers(p)
	if n <= 0:
		return 1.0
	return 1.0 + p.g("bff") * maxf(0.0, 4.0 - n) / 3.0   # bff 3: +300%, +200%, +100%

## Legion.speed: INFLUENCE (helpers too).
static func helper_speed(p: Player) -> float:
	if not on() or p.g("influence") <= 0:
		return 0.0
	return p.g("influence") * Auras.active(p).size()

## DoT ticks: TICKING CLOCK (and tick_haste).
static func tick_rate(p: Player) -> float:
	if not on():
		return 1.0
	var r := 1.0 + p.g("tick_haste")
	if p.g("clockwork") > 0:
		r += maxf(0.0, p.rate * rate_mult(p) - 1.0)
	return r + Arcana.tick_add(p) + Marvels.tick_add(p)   # 42.1 UNRAVELING, BELL CURVE, TIME SLIP; 43.1 MIND STORM

# ---------- crits and lethal hits ----------
static func crit_chance(p: Player, e: Enemy) -> float:
	if not on():
		return 0.0
	var c := p.g("crit_dex_rank") * dex_ranks(p)
	if p.g("toxin_crit") > 0 and e.poison > 0:
		c += p.g("toxin_crit") * e.poison
	return c

static func crit_add(p: Player, e: Enemy) -> float:
	if not on():
		return 0.0
	var c := 0.0
	if p.g("shock_critdmg") > 0 and e.shock > 0:
		c += p.g("shock_critdmg") * e.shock
	if p.g("illusion") > 0:
		c += minf(2.5, 1.5 * Lucky.chance(p))
	return c

## A sure crit (COUNTING COUP's hits).
static func sure_crit(o: Dictionary) -> bool:
	if crit_next > 0 and not o.get("silent", false):
		crit_next -= 1
		return true
	return false

## Combat.damage_enemy: what a hit gains on this foe.
static func foe_mult(p: Player, e: Enemy, o: Dictionary) -> float:
	if not on():
		return 1.0
	var m := 1.0
	if p.g("cull") > 0:
		if e.chill_t > 0:
			m *= 1.0 + (1.0 - p.chill_slow)
		if e.weak_t > 0:
			m *= 1.3
	if p.g("harmony") > 0:
		if e.curse_t > 0:
			m *= 1.25
		if o.get("lucky", false):
			m *= 1.25
	if p.g("opportune") > 0:
		var n := Effects.foes_left()
		if n < 4 and far(p, e):
			m *= 1.2
		if n > 2 and close(p, e):
			m *= 1.3
	if e.hp < e.max_hp * 0.5 and lethal(p, e, o):
		m *= p.crit_mult if p.g("lethality") > 0 else 2.0
		_stat("lethal")
	return m

static func lethal(p: Player, e: Enemy, o: Dictionary) -> bool:
	if p.g("sharpshooter") > 0 and far(p, e) and not o.get("silent", false):
		return true
	if p.g("cheap_shot") > 0 and o.get("lucky", false):
		return true
	var c := p.g("lethal")
	return c > 0.0 and not o.get("silent", false) and randf() < c

# ---------- events ----------
## Combat's attack (with Might.on_attack): COUNTING COUP, ONE STEP AHEAD.
static func on_attack(p: Player) -> void:
	if not on():
		return
	if p.g("tally") > 0:
		tally_n += 1
		if tally_n >= 3:
			tally_n = 0
			crit_next = Weapons.wcount(p) * 2
			_stat("tally")
	if repeat_left > 0:
		repeat_left -= 1
		p.volleys.append({ "t": 0.15, "mult": 2.0 })
		_stat("step_ahead")

## A repeat fires (Combat's volleys): HABIT.
static func on_repeat() -> void:
	repeat_t = 4.0

## A roll (Combat.on_roll_start), and SHOWBOAT every 4 s: CLEAN GETAWAY, ONE STEP AHEAD.
static func on_roll(p: Player) -> void:
	if not on():
		return
	if p.g("two_steps") > 0:
		repeat_left = 2
	if p.g("exit") > 0:
		var n := clampi(p.dodge_charges, 1, 3)
		for e in G.enemies.duplicate():
			if e.hp <= 0 or e.type == "dummy":
				continue
			if e.burn_t > 0:
				e.burn_t = maxf(e.burn_t, 3.0 + p.burn_time)
			if e.bleed_t > 0:
				e.bleed_t = maxf(e.bleed_t, 3.0)
			if e.burn_t > 0 or e.bleed_t > 0 or e.poison > 0:
				for i in n:
					if e.hp > 0:
						Might.tick_dots(p, e)
		_stat("getaway")

## Combat.update_player, every tick.
static func tick(p: Player, dt: float) -> void:
	if repeat_t > 0:
		repeat_t -= dt
	if p.g("swagger") > 0 and G.enemies_active():
		swagger_t -= dt
		if swagger_t <= 0:
			swagger_t = 4.0
			on_roll(p)
			Might.on_roll(p)
			if not p.procs.is_empty():
				Effects.fire("on_roll", { "x": p.x, "y": p.y })
			Fx.float_text(p.x, p.y - 26, "SHOWBOAT!", "green")
			_stat("showboat")

## A bleed ticks: TAINTED BLOOD.
static func on_bleed_tick(p: Player, e: Enemy) -> void:
	if p.g("blood_poison") > 0:
		e.poison = minf(12, e.poison + 5)

## HABIT: what you inflict right after a repeat is twice as strong.
static func status_mult(p: Player) -> float:
	return 2.0 if on() and repeat_t > 0 and p.g("repeat_debuff") > 0 else 1.0
