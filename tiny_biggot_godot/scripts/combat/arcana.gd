class_name Arcana
extends RefCounted
## 42.1 (his pictures of a wiki's INTELLIGENCE traits, 10 Oct; ideas only, our own names and
## pictures, TRAITS_PLAN.md): what the Stage 42 traits need, in one place. Expanded game only: in
## classic every hook is 0 and none of these traits are offered.
##   CURSED HITS   a chance a hit curses its foe (cursed_hit, doubled by curse_x2); a cursed foe
##                 takes more from you (curse_dmg)
##   SNEAKY HITS   a chance a hit lands unseen for +60% (trickery: per common piece of gear worn)
##   THE SPECIAL'S CHARGE AS MANA  power (dreamer) and your helpers' damage (mind_beacon) grow
##                 with how full it is
##   ELEMENTS      the wheel (a burn chills, a chill shocks, a shock burns: elem_wheel), focus (your
##                 fields and your special inflict fire, frost and lightning twice over:
##                 elem_focus), lightning that strikes again (thunder_twice), blasts that burn
##                 (ignition), poison that bleeds (poison_bleed) or leaves foes vulnerable
##                 (poison_vuln)
##   TICK SPEED    special recharge bonuses (entropy), lucky hit chance (bell_curve), 10 s after
##                 the special (time_slip)
##   HELPERS       power for helpers (inspire), damage per helper (menagerie), half as hard
##                 (pack_mind)
##   SHOTS         fan(): shards or a thistle that chill or poison (ICE VOLLEY, THISTLE THROW);
##                 pocket(): a weapon from the backpack fires (SPARE WAND); third_echo: a repeat

const INT_FAMS := ["arcane", "pyre", "frost", "storm", "venom", "malice", "swarm"]
const SNEAKY := 1.6
const WHEEL := { "burn": "chill", "chill": "shock", "shock": "burn" }

static var slip_t := 0.0
static var echo_n := 0
static var echo_next := false
static var later: Array = []   # [seconds, foe, damage]: a lightning strike that comes again
static var _busy := false
static var _again := false
static var stats := {}

static func on() -> bool:
	return GameData.rogues()

static func reset() -> void:
	slip_t = 0.0
	echo_n = 0
	echo_next = false
	later.clear()
	_busy = false
	_again = false

static func _stat(k: String) -> void:
	stats[k] = stats.get(k, 0) + 1

static func int_ranks(p: Player) -> int:
	var n := 0
	for f in INT_FAMS:
		n += int(p.fam.get(f, 0))
	return n

# ---------- power and damage ----------
## Might.power: DAYDREAM (the special's charge), HUNGRY MIND (armor).
static func power_add(p: Player) -> float:
	if not on():
		return 0.0
	var pw := 0.0
	if p.g("dreamer") > 0:
		pw += p.g("dreamer") * Abilities.charge(p)
	if p.g("hungry") > 0:
		pw += minf(100.0, p.g("hungry") * p.armor)
	return pw

## Might.dmg_mult: MENAGERIE (you as well as your helpers).
static func dmg_mult(p: Player) -> float:
	if not on() or p.g("menagerie") <= 0:
		return 1.0
	return 1.0 + p.g("menagerie") * Finesse.helpers(p)

## Legion.dmg_mult: RALLYING MIND, MIND BEACON, MENAGERIE, PACK MIND.
static func helper_mult(p: Player) -> float:
	if not on():
		return 1.0
	var m := 1.0
	if p.g("inspire") > 0:
		m *= 1.0 + p.g("inspire") * Might.power(p) / 100.0
	if p.g("mind_beacon") > 0:
		m *= 1.0 + p.g("mind_beacon") * Abilities.charge(p)
	if p.g("menagerie") > 0:
		m *= 1.0 + p.g("menagerie") * Finesse.helpers(p)
	if p.g("pack_mind") > 0:
		m *= 0.5
	return m

## Finesse.special_power: DEEP THOUGHT, per INT trait.
static func special_add(p: Player) -> float:
	if not on() or p.g("insight") <= 0:
		return 0.0
	return p.g("insight") * int_ranks(p)

## Finesse.tick_rate: UNRAVELING, BELL CURVE, TIME SLIP.
static func tick_add(p: Player) -> float:
	if not on():
		return 0.0
	var r := 0.0
	if p.g("entropy") > 0:
		r += maxf(0.0, Might.special_rate(p) - 1.0)
	if p.g("bell_curve") > 0:
		r += Lucky.chance(p)
	if slip_t > 0:
		r += 1.0
	return r

# ---------- hits ----------
## Combat.damage_enemy, on a crit: SURGEON'S EYE on a bleeding foe.
static func crit_add(p: Player, e: Enemy) -> float:
	if not on() or p.g("anatomy") <= 0 or e.bleed_t <= 0:
		return 0.0
	return p.g("anatomy")

static func cursed_chance(p: Player) -> float:
	return p.g("cursed_hit") * (2.0 if p.g("curse_x2") > 0 else 1.0)

static func sneaky_chance(p: Player) -> float:
	if p.g("trickery") <= 0:
		return 0.0
	var n := 0
	for g in p.gear.values():
		if g is Dictionary and g.get("rarity", "") == "common":
			n += 1
	return p.g("trickery") * n

## Combat.damage_enemy: CURSED HITS curse the foe, SNEAKY HITS land unseen for +60%, a cursed foe
## takes more (WITCH'S MARK). No dice for a build without them, and none for a tick or a blast.
static func foe_mult(p: Player, e: Enemy, o: Dictionary) -> float:
	if not on():
		return 1.0
	var m := 1.0
	var plain: bool = not o.get("silent", false)
	var ch := cursed_chance(p)
	if plain and ch > 0.0 and randf() < ch:
		Statuses.apply(e, "curse", 1, 0)
		_stat("cursed")
	if e.curse_t > 0 and p.g("curse_dmg") > 0:
		m *= 1.0 + p.g("curse_dmg")
	var sn := sneaky_chance(p)
	if plain and sn > 0.0 and randf() < sn:
		m *= SNEAKY
		Fx.float_text(e.x, e.y - e.r - 14, "SNEAKY", "purple")
		_stat("sneaky")
	return m

# ---------- statuses ----------
## Statuses.apply: FOCUSED ELEMENTS: fire, frost and lightning from your fields and your special.
static func focus_mult(p: Player, name: String) -> float:
	if on() and p.g("elem_focus") > 0 and (Might.casting or Auras.pulsing) and name in WHEEL:
		return 2.0
	return 1.0

## Statuses.apply, once the status holds: THORN BLOOM, EATING ACID, ELEMENT WHEEL. What these add
## sets off nothing more.
static func on_status(p: Player, e: Enemy, name: String, hit_dmg: float) -> void:
	if not on() or _busy or e.hp <= 0:
		return
	_busy = true
	if name == "poison":
		if p.g("poison_bleed") > 0:
			Statuses.apply(e, "bleed", 1, maxf(hit_dmg, Weapons.wdmg(p)))
		if p.g("poison_vuln") > 0:
			Statuses.apply(e, "vulnerable", 1, 0)
	if p.g("elem_wheel") > 0 and WHEEL.has(name):
		Statuses.apply(e, WHEEL[name], 1, hit_dmg)
		_stat("wheel")
	_busy = false

# ---------- lightning, moons, blasts ----------
## Combat.lightning: THUNDER TWICE: the strike comes again half a second later (once).
static func on_lightning(p: Player, e: Enemy, dmg: float) -> void:
	if on() and p.g("thunder_twice") > 0 and not _again and later.size() < 24:
		later.append([0.5, e, dmg])

## Auras.orbit_radius: WIDE ORBIT.
static func orbit_mult(p: Player) -> float:
	return 2.0 if on() and p.g("wide_orbit") > 0 else 1.0

## Combat.update_player: BELL CURVE: the moons turn faster with your lucky hit chance.
static func orbit_speed(p: Player) -> float:
	return 1.0 + Lucky.chance(p) if on() and p.g("bell_curve") > 0 else 1.0

## Combat.explode_at: BLAZING BLASTS.
static func blast_mult(p: Player) -> float:
	return 1.0 + p.g("ignition") if on() and p != null and p.g("ignition") > 0 else 1.0

# ---------- events ----------
## Combat's attack (with Finesse.on_attack): THIRD ECHO.
static func on_attack(p: Player) -> void:
	if not on() or p.g("third_echo") <= 0:
		return
	if echo_next:
		echo_next = false
		p.volleys.append({ "t": 0.15 })
		_stat("third_echo")
	echo_n += 1
	if echo_n >= 3:
		echo_n = 0
		echo_next = true

## Might.cast, the special used: TIME SLIP.
static func on_special(p: Player) -> void:
	if on() and p.g("time_slip") > 0:
		slip_t = 10.0 * p.g("time_slip")
		Fx.float_text(p.x, p.y - 26, "TIME SLIPS", "cyan")

## Combat.update_player, while something is pending.
static func tick(p: Player, dt: float) -> void:
	if slip_t > 0:
		slip_t -= dt
	var i := 0
	while i < later.size():
		later[i][0] -= dt
		if later[i][0] > 0:
			i += 1
			continue
		var e: Enemy = later[i][1]
		var dmg: float = later[i][2]
		later.remove_at(i)
		if e.hp > 0:
			_again = true
			Combat.lightning(e, dmg)
			_again = false
			_stat("thunder")

# ---------- shots ----------
## ["fan_shots", n, dmg_mult, family]: n shots in a fan along your aim, in a family's colour; frost
## chills, venom poisons and pierces (ICE VOLLEY, THISTLE THROW).
static func fan(p: Player, n: int, dmg: float, fam: String) -> void:
	for i in n:
		var b := Combat.spawn_pbullet(p, p.aim_a + (i - (n - 1) / 2.0) * 0.22, dmg, "spark")
		if b == null:
			continue
		b.tag = fam
		match fam:
			"frost":
				b.chill = true
			"venom":
				b.poison_add = 2
				b.pierce += 1
	_stat("fan")

## ["pocket_cast"]: SPARE WAND: a shooting weapon from your backpack fires at the nearest foe.
static func pocket(p: Player) -> void:
	var ws := []
	for it in p.backpack:
		if it is Dictionary and it.get("item", "") == "weapon" and (it["kind"] in Lucky.CASTABLE or Spells.handles(it["kind"])):
			ws.append(it)
	if ws.is_empty():
		return
	if Lucky.cast(p, null, ws[randi() % ws.size()]):
		_stat("pocket")
