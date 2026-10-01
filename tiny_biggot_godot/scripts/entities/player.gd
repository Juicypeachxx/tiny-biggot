class_name Player
extends RefCounted
## The hero (port of Entities.rb create_player and update_player, plus the
## 04b_items.rb additions). Ruby kept the player in one big Hash. Here every
## stat is a typed field with the Ruby default, and relic, trait and gear
## effects reach them with get()/set() by name.

var hero: Dictionary
var x := TB.SW / 2.0
var y := TB.SH / 2.0 + 24
var r := 4.0
var hit_r := 2.5
var face := 1
var aim_a := 0.0
var hp := 6
var max_hp := 6
var potions := 1
var max_potions := 2
var gold := 0
var gold_frac := 0.0
var relics: Array = []
var speed := 86.0
var dmg := 1.0
var rate := 1.0
var shot_speed := 1.0
var life := 1.0
var homing := 0.0
var size := 1.0
var pierce := 0
var count := 0
var spread: Variant = null      # null = use the weapon's spread (Ruby nil)
var bounce := 0
var crit := 0.05
var crit_mult := 2.0
var burn := 0.0
var chill := 0.0
var poison := 0
var chain := 0.0
var explode := 0
var lifesteal := 0.0
var gold_mult := 1.0
var shop_disc := 0.0
var thorns := 0
var orbitals := 0
var dodge_charges := 1
var dodge_cd := 0.9
var frenzy := 0
var rage := 0.0
var backshot := 0
var triple := 0.0
var ward := 0
var buckler := false
var bomb_dodge := false
var magnet := false
var armor := 0
var bombs := 1
var keys := 0
var bomb_mult := 1.0
var gold_drop := 1.0
var roll_speed := 1.0
var potion_heal := 4
var reveal := false
var familiars := 0
var aura := 0
var elite_mult := 0.0
var lens := false
var coil := 0
var oath := false
var ricochet := 0
var miser := false
var shadowstep := false
var splinter := 0
var revive := 0
var storm := 0.0
var mirror := false
var roll_reload := false
var fire_cd := 0.0
var dodge_t := 0.0
var dodge_dir := Vector2(1, 0)
var charges := 1
var charge_t := 0.0
var invuln := 0.0
var frenzy_t := 0.0
var buckler_used := false
var orbit_a := 0.0
var orbit_hit := {}
var walk_t := 0.0
var moving := false
var volleys: Array = []
var kills := 0
var trail: Array = []
var aura_t := 0.0
var coil_t := 0.0
var step_hit := {}
var embers_found := 0
var xp := 0
var level := 1
var pending := 0
var traits := {}
var fam := {}
var fam_bonus := {}
var rerolls := 2
var luck := 0
var burn_dmg := 0.0
var vs_burn := 0.0
var burn_time := 0.0
var burn_leap := 0.0
var fire_trail := 0
var inferno := false
var chill_time := 0.0
var chill_slow := 0.5
var vs_chill := 0.0
var ice_armor := false
var lance_n := 0
var shot_n := 0
var shatter := false
var chill_spread := false
var poison_dmg := 0.0
var corrode := 0.0
var cloud := 0
var barbs := 0.0
var plague := false
var poison_fast := false
var chain_jumps := 0
var storm_dmg := 0.0
var thunder_n := 0
var tempest := false
var tempest_t := 3.0
var crit_heal := 0.0
var desperate := 0.0
var bleed := 0
var sanguine := false
var room_kills := 0
var crit_pierce := false
var armor_regen := 0
var ironskin := false
var bash := 0
var fortress := 0.0
var unbreakable := false
var evade := 0.0
var ambush := 0
var ambush_left := 0
var roll_time := 0.0
var smoke := false
var nightfall := false
var post_roll := false
var post_roll_t := 0.0
var echo := 0.0
var interest := 0.0
var jackpot := false
var midas := false
var shrapnel := 0.0
var sapper := 0
var fuse := false
var cluster := false
var bomb_r := 1.0
var boom_elite := false
var fam_dmg := 0.0
var fam_rate := 1.0
var fam_multi := 1
var carrion := 0.0
var legion := false
var legion_n := 0
var curse := 0.0
var bloom := false
var heavy_n := 0
var stun := 0.0
var full_hp_dmg := 0.0
var blood_rage := false
var harvest := false
var splash := 0.0
var elixir := false
var volatile := false
var back_dmg := false
var start_rare := false
var trail_t := 0.0
# 04b_items.rb: weapons and gear.
var weapon: Variant = null      # weapon Dictionary
var gear := {}                  # slot -> gear Dictionary or null
var gf := {}                    # gear/weapon hook totals (Ruby Hash.new(0))
var sets := {}
var set_tier := {}
var granted := {}
var spin := 0.0
var xp_mult := 1.0
var haste_t := 0.0
var floor_kills := 0
var step_t := 0.0
var phoenix_used := false
# Effect system (effects/effects.gd). Empty for original content.
var procs: Array = []           # active triggers { def, src, stacks, count, cd, timer, active }
var buffs: Array = []           # timed additive-% buffs { stat, v, t }
var stat_pct := {}              # stat -> sum of additive-% modifiers
var tag_counts := {}            # synergy tag -> points from new-content items
var synergies := {}             # active synergy tiers and combos
var overcrit := 0.0             # new stat: crit chance past 100% can crit again
var paid_rerolls := 0           # trait rerolls bought with gold after the free ones
var heat := 0                   # new (Racketeer): heat level, see Actions "heat"
var heat_max := 5

func _init(h: Dictionary) -> void:
	hero = h
	hp = h["hp"]
	max_hp = h["hp"]
	speed = float(h["speed"])
	# Hero stat blocks only seed the base values; the 04b version resets them to
	# 1.0 multipliers because the weapon carries the real numbers.
	var start: Dictionary = h.get("start", {})
	for k in start:
		set(k, get(k) + start[k])

## Ruby gf(p, k): hook total, 0 when absent.
func g(k: String) -> float:
	return gf.get(k, 0.0)

## Ruby cap?(p, k): the trait/relic flag or a gear hook is active.
func cap(k: String) -> bool:
	var v = get(k)
	if v is bool:
		if v:
			return true
	elif (v is int or v is float) and v != 0:
		return true
	return g(k) > 0

# ---------- Movement, roll, aim (update_player) ----------
## Movement half of update_player; Combat.update_player wraps it with
## aiming, firing, bombs, auras and familiars.
func update_move(dt: float) -> Vector2:
	var room := G.room
	invuln = maxf(0.0, invuln - dt)
	frenzy_t = maxf(0.0, frenzy_t - dt)
	post_roll_t = maxf(0.0, post_roll_t - dt)
	var raging := blood_rage and hp <= max_hp / 2
	if charges < dodge_charges:
		charge_t += dt
		if charge_t >= dodge_cd:
			charge_t = 0.0
			charges += 1
	var mv := Keys.move()
	var vx := 0.0
	var vy := 0.0
	if Keys.roll() and dodge_t <= 0 and charges > 0:
		start_roll(mv)
	if dodge_t > 0:
		dodge_t -= dt
		vx = dodge_dir.x * 215 * roll_speed
		vy = dodge_dir.y * 215 * roll_speed
		trail.append({ "x": x, "y": y, "life": 0.18, "face": face })
		Combat.while_rolling(self, dt)
	else:
		var spd := speed * (1.2 if raging else 1.0)
		vx = mv.x * spd
		vy = mv.y * spd
	moving = Vector2(vx, vy).length() > 5
	if moving:
		walk_t += dt
	if absf(vx) > 5 and dodge_t <= 0:
		face = 1 if vx > 0 else -1
	World.move_body(room, self, vx * dt, vy * dt, World.M_PLAYER)
	var i := 0
	while i < trail.size():
		trail[i]["life"] -= dt
		if trail[i]["life"] <= 0:
			trail.remove_at(i)
		else:
			i += 1
	return mv

func start_roll(mv: Vector2) -> void:
	charges -= 1
	dodge_t = 0.26 * (1.12 if roll_speed > 1 else 1.0) + roll_time
	if ambush > 0:
		ambush_left = ambush
	post_roll_t = dodge_t + 1.0
	var d := mv if absf(mv.x) + absf(mv.y) > 0.1 else Vector2(float(face), 0.0)
	dodge_dir = d / d.length()
	step_hit = {}
	if roll_reload:
		fire_cd = 0.0
	Snd.play("dodge")
	Combat.on_roll_start(self)

## Potion on HEAL (Keys.heal) - part of update_player.
func try_heal() -> void:
	if not Keys.heal():
		return
	if potions > 0 and hp < max_hp:
		potions -= 1
		heal(potion_heal)
		if elixir:
			invuln = maxf(invuln, 3.0)
		Effects.fire("on_potion")
	else:
		Snd.play("deny")

func heal(n: int) -> void:
	var before := hp
	hp = mini(max_hp, hp + n)
	if hp > before:
		if not procs.is_empty():
			Effects.fire("on_heal", { "x": x, "y": y })
		var gained := (hp - before) / 2.0
		Fx.float_text(x, y - 12, "+" + TB.num_str(gained) + " HP", "pink")
		Snd.play("heal")
		Fx.burst(x, y, ["#d8443c", "#ff8a8a"], 10, 40)
