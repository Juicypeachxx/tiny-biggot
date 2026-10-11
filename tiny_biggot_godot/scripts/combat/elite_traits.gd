class_name EliteTraits
extends RefCounted
## Elite traits (6.6, "do what is best": his asks of 6 Oct for more variety and foes that stand up
## to a build; expanded game only). Every elite rolls a trait, two from the seventh floor on or on
## a loop; its name shows under it, in the gold of elites.
##   SWIFT      moves 35% faster.
##   PLATED     wears a plate of half its health (scripts/combat/armor.gd): breaking it stuns it.
##   SPLITTING  falls apart into two smaller copies (a third of its health each).
##   VOLATILE   bursts into a slow ring of shots when it dies.
##   MENDING    left alone for 2 s, it heals 5% of its health a second.
## Nothing about the player or the build changes.

const ALL := ["swift", "plated", "splitting", "volatile", "mending"]

static func roll(e: Enemy) -> void:
	if GameData.rogues() and (e.d.get("mini", false) or e.d.get("champion", false)) and Dread.has(12):
		Dread.crown(e)   # 48.1 CROWNED
		return
	if not GameData.rogues() or not e.elite or e.is_boss() or e.d.get("mini", false) or e.d.get("champion", false):
		return
	var n := (2 if G.floor_index >= 6 or G.loop > 0 else 1) + Dread.extra_traits()   # (48.1 TWICE CROWNED)
	var pool := ALL.duplicate()
	for i in n:
		var t: String = pool[randi() % pool.size()]
		pool.erase(t)
		e.traits.append(t)
		if t == "swift":
			e.speed *= 1.35

## Every tick of a living elite with traits (Combat's foe loop).
static func tick(e: Enemy, dt: float) -> void:
	if not e.traits.has("mending"):
		return
	e.mend_t += dt
	if e.mend_t >= 2.0 and e.hp < e.max_hp:
		e.hp = minf(e.max_hp, e.hp + e.max_hp * 0.05 * dt)
		if randf() < 0.2:
			Fx.particle(e.x + TB.rint(-4, 4), e.y - 6, 0, -18, 0.4, "#7ad86a")

## Combat.kill_enemy.
static func on_kill(e: Enemy) -> void:
	if e.traits.is_empty():
		return
	if e.traits.has("volatile"):
		Combat.ering(e.x, e.y - 4, 10, 48, randf(), "red")
		Fx.burst(e.x, e.y - 4, ["#d8443c", "#f2c94c"], 12, 80)
	if e.traits.has("splitting") and GameData.ENEMIES.has(e.type):
		for i in 2:
			var a := randf() * TAU
			var s := Combat.spawn_enemy(e.type, e.x + cos(a) * 8.0, e.y + sin(a) * 8.0, false, true)
			s.max_hp = e.max_hp / 3.0
			s.hp = s.max_hp
			s.scale *= 0.8
			s.r *= 0.8
			s.gold = 0.0

## The names drawn under the elite (world_view).
static func label(e: Enemy) -> String:
	return " ".join(e.traits.map(func(t): return t.to_upper()))
