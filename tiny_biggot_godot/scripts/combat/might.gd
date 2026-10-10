class_name Might
extends RefCounted
## 40.2 (his pictures of a wiki's STRENGTH traits, 10 Oct; ideas only, our own names and pictures,
## TRAITS_PLAN.md): what the Stage 40 traits need, in one place. Expanded game only: in classic
## every hook is 0 and none of these traits are offered.
##   POWER         +1% damage a point: gf power, + war_charge for every +10% of move speed above the
##                 hero's own (3 at most), + crowd for every one in the room (you, your helpers,
##                 foes; 100 at most)
##   CRUSHING HIT  x1.5, and it wears a guardian's plate the way its weakness does (armor.gd): a
##                 chance (crush), or every hit (resolute), or the hits left after a roll (crush_next)
##   RAGE          +1 a hit, +5 a melee hit (seething); +1% damage each, RAGE_MAX at most, 5 lost a
##                 second
##   PUNCTURE      a foe's stacks from thrust hits (sharp_end): +4% damage taken each, 10 at most,
##                 one lost a second
##   INSTABILITY   a foe's stacks from blunt hits (blunt): at 5 it reels (a stun) and starts again
##   PRIDE         after taming, puppeting or taunting a foe: hits that do not crit x1.4 for a while
##   FOCUS         BRAWN: STR counts double, DEX and INT half (Attributes.value)
##   SPECIAL       recharge speed (special_haste, special_str per STR rank, honest: the roll's
##                 recharge bonus too); on_special fires when it is used; casting while its
##                 actions run (MERCILESS)
##   STRIDE        per gear piece worn: damage, move speed and roll recharge (stride)

const RAGE_MAX := 50.0
const RAGE_LOSS := 5.0
const PUNCT_MAX := 10
const STR_FAMS := ["fury", "bulwark", "blood", "demolition"]
const MELEE_KINDS := ["slash", "thrust", "whip", "spin", "flail", "slam", "bat", "dash", "combo", "stab", "hook"]
## Two-handed: staves, bows and the big blades and hafts.
const HEAVY_SHAPES := ["greatsword", "halberd", "axe", "hammer", "maul", "scythe", "cleaver", "spear", "trident", "lance",
	"glaive", "flail", "shovel", "staff", "orbstaff", "skullstaff", "bow", "crossbow", "rifle", "minigun", "cannon",
	"launcher", "mortar", "blunderbuss"]

static var rage := 0.0
static var crush_left := 0
static var pride_t := 0.0
static var last_shot := -99.0
static var casting := false
static var stats := {}

static func on() -> bool:
	return GameData.rogues()

static func reset() -> void:
	rage = 0.0
	crush_left = 0
	pride_t = 0.0
	last_shot = -99.0
	casting = false

static func _stat(k: String) -> void:
	stats[k] = stats.get(k, 0) + 1

# ---------- what a weapon is ----------
static func melee(w) -> bool:
	return w != null and w["kind"] in MELEE_KINDS

static func heavy(w) -> bool:
	return w != null and w.get("shape", "") in HEAVY_SHAPES

static func ranged(w) -> bool:
	return w != null and WeaponInfo.wtype(w) == "RANGED"

## SLASHING, PIERCING or PHYSICAL (blunt) by the weapon's kind, whatever its element.
static func cut(w) -> String:
	return WeaponInfo.KIND_TYPE.get(w["kind"], "PHYSICAL") if w != null else ""

const BLUNT_SHAPES := ["hammer", "maul", "fists", "gauntlet", "flail", "shovel"]
static func blunt(w) -> bool:
	return w != null and (cut(w) == "PHYSICAL" or w.get("shape", "") in BLUNT_SHAPES)

# ---------- counts ----------
static func gear_count(p: Player) -> int:
	var n := 0
	for g in p.gear.values():
		if g != null:
			n += 1
	return n

static func str_ranks(p: Player) -> int:
	var n := 0
	for f in STR_FAMS:
		n += int(p.fam.get(f, 0))
	return n

## You, your helpers and the foes in the room (BRAWLER-like CROWD FIGHTER).
static func crowd(p: Player) -> int:
	var n := 1 + mini(p.familiars, Effects.SUMMON_CAP) + G.temp_fams.size() + Summons.thralls.size() + Summons.turrets.size()
	for e in G.enemies:
		if e.hp > 0 and e.type != "dummy" and e.spawn_t <= 0:
			n += 1
	return n

# ---------- power and damage ----------
static func power(p: Player) -> float:
	if not on() or p == null:
		return 0.0
	var pw := p.g("power")
	if p.g("war_charge") > 0:
		var lead := p.speed / maxf(1.0, float(p.hero.get("speed", p.speed))) - 1.0
		pw += p.g("war_charge") * mini(3, int(floor(lead / 0.1 + 0.0001)))
	if p.g("crowd") > 0:
		pw += minf(100.0, p.g("crowd") * crowd(p))
	return pw

## Combat.player_damage_mult.
static func dmg_mult(p: Player) -> float:
	if not on():
		return 1.0
	var m := 1.0 + power(p) / 100.0
	if rage > 0:
		m *= 1.0 + 0.01 * rage
	if p.g("stride") > 0:
		m *= 1.0 + p.g("stride") * gear_count(p)
	return m

## Combat.damage_enemy: what a hit on this foe gains.
static func foe_mult(p: Player, e: Enemy) -> float:
	if not on():
		return 1.0
	var m := 1.0
	if e.puncture > 0:
		m *= 1.0 + 0.04 * e.puncture
	if p.g("toe_to_toe") > 0 and close(p, e):
		m *= 1.3
	if p.g("shield_wall") > 0 and melee(p.weapon):
		m *= 1.0 + (0.25 if Block.ready else 0.0) + 0.1 * p.armor
	return m

static func close(p: Player, e: Enemy) -> bool:
	return Finesse.close(p, e)   # (41.1 NO DISTANCE: bows and guns always count as close)

## TOE TO TOE: a close blow goes through a foe's guard.
static func ruthless(p: Player, e: Enemy) -> bool:
	return on() and p.g("toe_to_toe") > 0 and close(p, e)

## Crit chance a hit gains (SCAR TISSUE: your curse chance), and crit damage (SAVAGERY: per STR).
static func crit_chance(p: Player) -> float:
	return p.curse if on() and p.g("scar_tissue") > 0 else 0.0

static func crit_add(p: Player) -> float:
	if not on() or p.g("critdmg_str") <= 0:
		return 0.0
	return p.g("critdmg_str") * Attributes.value(p, "str")

## IRON DISCIPLINE: no crits at all.
static func no_crit(p: Player) -> bool:
	return on() and p.g("resolute") > 0

## Is this blow a crushing hit? (Rolls only when a chance is there.)
static func crushing(p: Player, e: Enemy = null) -> bool:
	if not on():
		return false
	if p.g("resolute") > 0:
		return true
	if p.g("point_blank") > 0 and e != null and ranged(p.weapon) and Finesse.close(p, e):
		return true   # 41.1 MUZZLE FLASH
	if crush_left > 0:
		crush_left -= 1
		return true
	var c := p.g("crush")
	return c > 0.0 and randf() < c

## The hit's +-15% roll (PACK HUNTER: rolled twice, the lower kept).
static func roll(p: Player) -> float:
	var r := 0.85 + 0.3 * randf()
	if p.g("pack_roll") > 0:
		r = minf(r, 0.85 + 0.3 * randf())
	return r

## MIGHT MAKES RIGHT: ailments as strong as your power.
static func ailment_mult(p: Player) -> float:
	if not on() or p.g("might_right") <= 0:
		return 1.0
	return 1.0 + power(p) / 100.0

## BLOOD AND ASH: a burn or bleed of n stacks ticks for 35% a stack.
static func stack_mult(p: Player, n: int) -> float:
	if not on() or p.g("fire_blood") <= 0:
		return 1.0
	return 0.35 * maxi(1, n)

static func add_stack(p: Player, e: Enemy, kind: String) -> void:
	if not on() or p.g("fire_blood") <= 0:
		return
	if kind == "burn":
		e.burn_n = mini(10, (e.burn_n if e.burn_t > 0 else 0) + 1)
	else:
		e.bleed_n = mini(10, (e.bleed_n if e.bleed_t > 0 else 0) + 1)

# ---------- speeds ----------
static func roll_rate(p: Player) -> float:
	if not on():
		return 1.0
	return 1.0 + p.g("roll_haste") + p.g("stride") * gear_count(p) + Finesse.recharge_add(p)

static func special_rate(p: Player) -> float:
	if not on():
		return 1.0
	var r := 1.0 + p.g("special_haste") + p.g("special_str") * str_ranks(p) + Finesse.recharge_add(p)
	if p.g("honest") > 0:
		r += roll_rate(p) - 1.0
	return r

static func speed_mult(p: Player) -> float:
	if not on() or p.g("stride") <= 0:
		return 1.0
	return 1.0 + p.g("stride") * gear_count(p)

## Effects.add_buff: TOWERING PRESENCE, per gear piece worn.
static func buff_mult(p: Player) -> float:
	if not on() or (p.g("presence") <= 0 and p.g("buff_power") <= 0):
		return 1.0
	return 1.0 + p.g("presence") * gear_count(p) + p.g("buff_power")   # (41.1 GOOD DOG: buff_power)

# ---------- the weapon's rate and damage ----------
## STEADY HAND: fire rate bonuses count half, and raise the damage twice over. GIANT'S GRIP: a
## heavy weapon swings 25% faster.
static func rate_mult(p: Player) -> float:
	if not on():
		return 1.0
	var m := 1.0
	if p.g("steady") > 0 and p.rate > 1.0:
		m *= (1.0 + 0.5 * (p.rate - 1.0)) / p.rate
	if p.g("giant_grip") > 0 and heavy(p.weapon):
		m *= 1.25
	return m

static func wdmg_mult(p: Player) -> float:
	if not on() or p.g("steady") <= 0:
		return 1.0
	return 1.0 + 2.0 * maxf(0.0, p.rate - 1.0)

# ---------- events ----------
## Combat.update_player, every tick.
static func tick(p: Player, dt: float) -> void:
	if rage > 0:
		rage = maxf(0.0, rage - RAGE_LOSS * dt)
	if pride_t > 0:
		pride_t -= dt

## Combat.update_enemies, every foe every tick.
static func tick_foe(e: Enemy, dt: float) -> void:
	if e.puncture > 0:
		e.punct_t -= dt
		if e.punct_t <= 0:
			e.puncture -= 1
			e.punct_t = 1.0
	if e.dot_cd > 0:
		e.dot_cd -= dt

## Combat's attack: OPENING (an attack after 2 s without one gives COURAGE).
static func on_attack(p: Player) -> void:
	if p.g("opening") > 0 and G.time - last_shot >= 2.0:
		Effects.add_buff(p, "dmg", 0.3 * p.g("opening"), 5.0)
		Fx.float_text(p.x, p.y - 26, "COURAGE", "gold")
		_stat("courage")
	last_shot = G.time

## A roll: ROLLING THUNDER's crushing hits.
static func on_roll(p: Player) -> void:
	if p.g("crush_next") > 0:
		crush_left = maxi(crush_left, int(p.g("crush_next")))

## A foe tamed, made a puppet or taunted: PRIDE (and the on_taunt items).
static func taunted(e: Enemy) -> void:
	var p := G.player
	if p == null or not on():
		return
	if p.g("pride") > 0:
		pride_t = maxf(pride_t, 8.0)
		_stat("pride")
	if not p.procs.is_empty():
		Effects.fire("on_taunt", { "enemy": e })

## Combat.on_hit_effects: what the weapon's own hits do to the foe.
static func on_hit(p: Player, e: Enemy, dmg: float, crit: bool) -> void:
	if not on() or p.weapon == null or e.hp <= 0:
		return
	var w: Dictionary = p.weapon
	if p.g("seething") > 0:
		rage = minf(RAGE_MAX, rage + (5.0 if melee(w) else 1.0) * p.g("seething"))
	var kt := cut(w)
	if p.g("sharp_end") > 0 and kt == "PIERCING":
		e.puncture = mini(PUNCT_MAX, e.puncture + 1)
		e.punct_t = 1.0
	if p.g("blunt") > 0 and blunt(w):
		e.instab += 1
		if e.instab >= 5:
			e.instab = 0
			Statuses.apply(e, "stun", 1, 0)
			Fx.float_text(e.x, e.y - e.r - 12, "REELS", "tan")
			_stat("reel")
	if p.g("keen_edge") > 0 and kt == "SLASHING":
		Statuses.apply(e, "bleed", 1, dmg)
		add_stack(p, e, "bleed")
	if p.g("threat") > 0:
		if heavy(w):
			Statuses.apply(e, "weakened", 1, 0)
		elif e.taunt_cd <= 0:
			e.taunt_cd = 3.0
			Statuses.apply(e, "mark", 1, 0)
			taunted(e)
	if p.g("open_wounds") > 0 and e.dot_cd <= 0:
		e.dot_cd = 0.25
		tick_dots(p, e)
	if casting and p.g("merciless") > 0:
		Statuses.apply(e, "vulnerable", 1, 0)

## Combat.damage_enemy, after a crushing hit: BONE BREAKER leaves the foe vulnerable.
static func crushed(p: Player, e: Enemy) -> void:
	_stat("crushing")
	if p.g("bone_break") > 0 and e.hp > 0:
		Statuses.apply(e, "vulnerable", 1, 0)
	if randf() < 0.3:
		Fx.burst(e.x, e.y - 4, ["#c8d0dc", "#f4ecd8"], 3, 50)

## OPEN WOUNDS: a foe's burns, poisons and bleeds tick at once.
static func tick_dots(p: Player, e: Enemy) -> void:
	if e.burn_t > 0:
		Combat.damage_enemy(e, (1 + Weapons.wdmg(p) * 0.2) * (1 + p.burn_dmg) * ailment_mult(p) * stack_mult(p, e.burn_n),
			{ "no_crit": true, "col": "orange", "silent": true })
	if e.hp > 0 and e.poison > 0:
		Combat.damage_enemy(e, e.poison * 1.2 * (1 + p.poison_dmg) * ailment_mult(p), { "no_crit": true, "col": "lime", "silent": true })
	if e.hp > 0 and e.bleed_t > 0:
		Combat.damage_enemy(e, e.bleed_dps * 0.5 * ailment_mult(p) * stack_mult(p, e.bleed_n),
			{ "no_crit": true, "col": "red", "silent": true, "no_mult": true })
	_stat("open_wounds")

## Abilities.use: the special's actions run with casting on (MERCILESS), then on_special.
static func cast(p: Player, actions: Array) -> void:
	casting = true
	for a in actions:
		Actions.run(a, 1, {})
	casting = false
	if not p.procs.is_empty():
		Effects.fire("on_special", { "x": p.x, "y": p.y })
