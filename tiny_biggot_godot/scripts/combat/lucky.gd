class_name Lucky
extends RefCounted
## 34.1 THE TRIGGER PATH (his word, 9 Oct: a DEX/INT build that "abuses high-frequency trigger
## effects"; ideas only, every name our own).
##   LUCKY HITS  every hit has a chance (gf lucky, plus lucky_dex for every point of DEX) to be
##               lucky: it strikes again for its damage and fires the trigger "on_lucky".
##   SPELL SLOT  with SPELLSLINGER (gf slot_cast), crits and lucky hits cast the weapon in your
##               first backpack slot at the foe, for free (castable kinds only: projectiles and
##               the spellbook). Shots made by a cast never cast again.
##   STATIC BUILD-UP  a foe that reaches the most shock discharges: lightning to 4 foes.
## Expanded game only; a build without lucky hits or the slot rolls no extra dice.

const CASTABLE := ["bolt", "orb", "spin", "shot", "flask", "boomer", "flame", "disc", "pulse", "nova", "burst",
	"gatling", "rail", "zap", "beam"]
const CAST_CD := 0.12
const LUCK_LUCKY := 0.05   # 38.2, 40.0 (his notes: +5%): every point of LUCK, +5% lucky hits
const MAX_CASTS_A_TICK := 2

static var stats := {}        # lucky, casts, discharges (tests)
static var _cd := 0.0
static var _casts := 0
static var _depth := 0
static var rush_t := 0.0      # TRICK SHOT: every hit is lucky for a while

static func reset() -> void:
	_cd = 0.0
	_casts = 0
	rush_t = 0.0

static func tick(dt: float) -> void:
	_cd = maxf(0.0, _cd - dt)
	_casts = 0
	if rush_t > 0:
		rush_t -= dt

static func chance(p: Player) -> float:
	if not GameData.rogues():
		return 0.0
	return p.g("lucky") + p.g("lucky_dex") * p.a_dex + LUCK_LUCKY * p.luck + p.g("lucky_heart") * p.max_hp / 2.0 + (1.0 if rush_t > 0 else 0.0)   # (40.2 BIG HEART)

## The weapon in the first backpack slot, if it can be cast.
static func slot_weapon(p: Player) -> Variant:
	if p.backpack.is_empty():
		return null
	var it: Dictionary = p.backpack[0]
	if it.get("item", "") != "weapon":
		return null
	if not (it["kind"] in CASTABLE or Spells.handles(it["kind"])):
		return null
	return it

## Combat.on_hit_effects, after everything else a hit does.
static func on_hit(e: Enemy, dmg: float, crit: bool, p: Player, b: PBullet) -> void:
	if not GameData.rogues() or _depth > 0 or (b != null and b.cast):
		return
	var c := chance(p)
	var lucky := c > 0.0 and randf() < c
	if lucky:
		stats["lucky"] = stats.get("lucky", 0) + 1
		if e.hp > 0:
			_depth += 1
			Combat.damage_enemy(e, dmg, { "no_crit": true, "col": "lime", "silent": true, "lucky": true })
			_depth -= 1
		Fx.burst(e.x, e.y - 6, ["#7ad86a", "#f2c94c"], 4, 50, 0.25)
		Effects.fire("on_lucky", { "enemy": e, "dmg": dmg })
	if (crit or lucky) and p.g("slot_cast") > 0:
		cast(p, e)

## Casts the spell slot's weapon at a foe (or the nearest one) for free.
static func cast(p: Player, e: Enemy = null) -> bool:
	if _cd > 0 or _casts >= MAX_CASTS_A_TICK or _depth > 0:
		return false
	var w = slot_weapon(p)
	if w == null:
		return false
	if e == null or e.hp <= 0:
		e = Combat.nearest_enemy(p.x, p.y, 400.0)
	if e == null:
		return false
	_cd = CAST_CD
	_casts += 1
	stats["casts"] = stats.get("casts", 0) + 1
	_depth += 1
	var keep: Dictionary = p.weapon
	var keep_n := p.shot_n
	var n0 := G.pbullets.size()
	var m0 := G.new_pbullets.size()
	p.weapon = w
	Combat.player_shoot(p, TB.ang_to(p, e), false)
	p.weapon = keep
	p.shot_n = keep_n
	var more := 1.0 + p.g("slot_dmg")
	for i in range(n0, G.pbullets.size()):
		G.pbullets[i].cast = true
		G.pbullets[i].dmg *= more
	for i in range(m0, G.new_pbullets.size()):
		G.new_pbullets[i].cast = true
		G.new_pbullets[i].dmg *= more
	_depth -= 1
	Fx.burst(p.x, p.y - 6, ["#e86fb4", "#f2c94c"], 5, 40, 0.25)
	return true

## Statuses.apply after a shock: STATIC BUILD-UP discharges a full foe.
static func on_shock(e: Enemy) -> void:
	var p := G.player
	if p == null or p.g("static_buildup") <= 0 or e.shock < Statuses.SHOCK_MAX or _depth > 0:
		return
	e.shock = 0
	stats["discharges"] = stats.get("discharges", 0) + 1
	_depth += 1
	var w := Weapons.wdmg(p) * 1.5 * p.g("static_buildup")
	var hit := 0
	for o in G.enemies.duplicate():
		if hit >= 4:
			break
		if o.targetable() and TB.dist(o, e) < 120.0:
			Combat.lightning(o, w)
			hit += 1
	_depth -= 1
