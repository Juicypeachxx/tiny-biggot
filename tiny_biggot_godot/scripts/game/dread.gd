class_name Dread
extends RefCounted
## 48.1 DREAD to 16 (his word, 10 Oct, with three pictures of the other game's 16 "cinders":
## "intended to increase the games difficulty at a pace the player is comfortable with ... played
## at around Cinder 12"; the rules and names here are this game's own). DREAD was already the
## ladder: a level opens with each win, you pick one on the hero screen, more dread pays more
## embers. Levels 1 to 5 keep exactly what they did (rule 1; their growing terms stop growing at
## 5: old()). In the expanded game it now climbs to 16, each level one more rule, all of the lower
## ones still in force:
##   6  FLAWED STEEL    your starting weapon carries a flawed enchantment (enchant.gd)
##   7  COLD START      rolls recharge 3, 2 and 1 s slower on the first three floors
##   8  PACKED HALLS    a fight in five is packed: twice the foes in each wave
##   9  BLOOD TOLL      half the treasure rooms and shrines on the floor map ask a heart at the door
##   10 ESCORTED        every guardian comes with two elite guards
##   11 TIDE OF ROOMS   the first three floors are 3, 2 and 1 rooms shorter, the deep ones longer
##   12 CROWNED         guardians, mini-bosses and champions carry an elite trait
##   13 THE HUNTER      every 8 to 20 fights a rift champion hunts you down in one
##   14 FALTERING NERVE at the start of each guardian stage your damage is halved, back to full
##                      over 20 s (+5% every 2 s)
##   15 PLAGUE          some fights hold a plague carrier: it bursts when it dies, hurting you if
##                      you are close and passing the plague to the foes around it
##   16 TWICE CROWNED   elites carry one more trait
## And every level gives every foe and guardian +0.5% health a floor (their plates come with it).
## STAR DUST (stars.gd) grows with the level too: dust_mult.

const MAX := 16
const CLASSIC_MAX := 5
const NERVE_TIME := 20.0
const PACK := 0.2
const TOLL := 0.5
const PLAGUE := 0.35
const PLAGUE_R := 46.0

static var nerve_t := 0.0

## The highest level that can be opened (the original game's five in classic).
static func cap() -> int:
	return MAX if GameData.rogues() else CLASSIC_MAX

## Level n or more is in force (the new levels: expanded game only).
static func has(n: int) -> bool:
	return G.dread >= n and GameData.rogues()

## The original five levels' growing numbers stop growing at 5.
static func old() -> int:
	return mini(G.dread, CLASSIC_MAX)

## Every foe's and guardian's health: +0.5% a floor for each level (floor 1 counts as 1).
static func hp_mult() -> float:
	if not GameData.rogues() or G.dread <= 0:
		return 1.0
	return 1.0 + 0.005 * G.dread * (G.floor_index + 1)

## STAR DUST's multiplier: +30% a level for 1 to 4, +20% for 5 to 8, +10% for 9 to 12, +5% for 13 to 16.
static func dust_mult(level: int = -1) -> float:
	var l := G.dread if level < 0 else level
	var m := 1.0
	for i in range(1, l + 1):
		m += 0.3 if i <= 4 else (0.2 if i <= 8 else (0.1 if i <= 12 else 0.05))
	return m

static func reset() -> void:
	nerve_t = 0.0

# ---------- the rules ----------
## 6 FLAWED STEEL (Game.new_run, after the hero's weapon).
static func on_new_run(p: Player) -> void:
	reset()
	if has(6) and p.weapon != null:
		Weapons.equip_weapon(p, Enchant.enchanted(p.weapon, TB.pick(Enchant.group_of("bad"))))

## 7 COLD START (Player's roll recharge): seconds added to each roll's recharge.
static func roll_delay() -> float:
	if not has(7) or G.floor_index >= 3:
		return 0.0
	return [3.0, 2.0, 1.0][G.floor_index]

## 8 PACKED HALLS (Game.spawn_wave): the foes of a wave.
static func pack(n: int) -> int:
	if has(8) and G.room != null and G.room.type == "combat" and randf() < PACK:
		return n * 2
	return n

## 11 TIDE OF ROOMS (World.new_floor): rooms on the floor.
static func floor_rooms(index: int, total: int) -> int:
	if not has(11):
		return total
	if index < 3:
		return maxi(5, total - (3 - index))
	if index >= 7:
		return total + mini(3, index - 6)
	return total

## 9 BLOOD TOLL (Game.start_floor, the floor map just made): half the treasure rooms and shrines
## ask a heart at the door.
static func on_floor_map(floor_d: Dictionary) -> void:
	if not has(9) or not floor_d.has("map"):
		return
	for c in floor_d["map"]["cells"].values():
		if c.get("type", "") in ["treasure", "shrine"] and randf() < TOLL:
			c["toll"] = true

## Game._leave_on_map: a toll door takes a heart (never the last), or will not open. True: go on.
static func pay_toll(p: Player, cell: Dictionary) -> bool:
	if not cell.get("toll", false):
		return true
	if p.hp <= 2:
		G.toast("THE DOOR WANTS A HEART YOU CANNOT SPARE", "red")
		Snd.play("deny")
		return false
	p.hp -= 2
	cell["toll"] = false
	G.toast("THE DOOR DRINKS A HEART", "red")
	Snd.play("hurt")
	Fx.burst(p.x, p.y, ["#d8443c", "#8a2a33"], 14, 60)
	return true

## 10 ESCORTED, 12 CROWNED, 14 FALTERING NERVE (Combat.spawn_boss).
static func on_boss(b: Enemy) -> void:
	if has(12):
		crown(b)
	if has(14):
		nerve_t = NERVE_TIME
	if has(10) and G.room != null and not b.d.get("rift", false):
		var pool: Array = GameData.floors()[G.floor_index].get("pool", [])
		for i in 2:
			if pool.is_empty():
				break
			var s := World.free_spot(G.room, G.player, 70, World.M_WALKER)
			Combat.spawn_enemy(TB.pick(pool), s.x, s.y, true)

## 14 FALTERING NERVE (Stages.tick: a guardian's new stage).
static func on_stage() -> void:
	if has(14):
		nerve_t = NERVE_TIME

static func tick(dt: float) -> void:
	if nerve_t > 0.0:
		nerve_t = maxf(0.0, nerve_t - dt)

## Combat.damage_enemy: x0.5 at the start of a stage, +0.05 every 2 s, back to x1 after 20 s.
static func nerve_mult() -> float:
	if nerve_t <= 0.0:
		return 1.0
	return 0.5 + 0.05 * floorf((NERVE_TIME - nerve_t) / 2.0)

## 12 CROWNED: a guardian, mini-boss or champion carries an elite trait (one that suits a big foe).
static func crown(e: Enemy) -> void:
	if not e.traits.is_empty():
		return
	var t: String = TB.pick(["swift", "volatile", "mending"])
	e.traits.append(t)
	if t == "swift":
		e.speed *= 1.35

## 16 TWICE CROWNED (EliteTraits.roll): one trait more for an elite.
static func extra_traits() -> int:
	return 1 if has(16) else 0

## 13 THE HUNTER (Game.spawn_wave, a fight's first wave): every 8 to 20 fights.
static func maybe_hunter(first: bool) -> void:
	if not has(13) or not first or G.room == null or G.room.type != "combat":
		return
	var left: int = G.run_stats.get("hunter_in", -1)
	if left < 0:
		left = TB.rint(8, 20)
	left -= 1
	if left > 0:
		G.run_stats["hunter_in"] = left
		return
	G.run_stats["hunter_in"] = TB.rint(8, 20)
	var champs: Array = GameData.ENEMIES.keys().filter(func(k): return GameData.ENEMIES[k].get("champion", false))
	if champs.is_empty():
		return
	var s := World.free_spot(G.room, G.player, 110, World.M_WALKER)
	var h := Combat.spawn_enemy(TB.pick(champs), s.x, s.y)
	G.show_banner("THE HUNTER", h.d["name"] + " HAS FOUND YOU")
	G.add_shake(4)

## 15 PLAGUE (Game.spawn_wave): now and then one foe of a wave carries the plague.
static func maybe_plague(wave: Array) -> void:
	if not has(15) or wave.is_empty() or randf() >= PLAGUE:
		return
	var e: Enemy = TB.pick(wave)
	e.plague = true

## Combat.kill_enemy: a carrier bursts, hurts you when close, and passes the plague on.
static func on_kill(e: Enemy) -> void:
	if not e.plague:
		return
	var p := G.player
	Fx.burst(e.x, e.y, ["#7ad86a", "#3f8a4a", "#b8e05a"], 22, 90)
	Vfx.blast(e.x, e.y, PLAGUE_R)
	if p != null and TB.dist_xy(p.x, p.y, e.x, e.y) < PLAGUE_R * 0.6:
		Combat.hurt_player(1, "a plague carrier")
	if Coop.on():   # (W3: the other heroes too)
		Coop.hazard(func(hero: Player) -> bool: return TB.dist_xy(hero.x, hero.y, e.x, e.y) < PLAGUE_R * 0.6, "a plague carrier")
	for o in G.enemies:
		if o != e and o.hp > 0 and not o.plague and TB.dist_xy(o.x, o.y, e.x, e.y) < PLAGUE_R:
			o.plague = true

## world_view: a carrier's green motes.
static func draw(ci: CanvasItem, e: Enemy, y: float, t: float) -> void:
	for k in 3:
		var a := t * 2.0 + k * TAU / 3.0
		Gfx.px(ci, TB.c("#7ad86a" if k != 1 else "#b8e05a"), roundf(e.x + cos(a) * (e.r + 2)), roundf(y - e.r - 2 + sin(a) * 2), 2)
