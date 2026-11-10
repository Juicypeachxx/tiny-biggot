class_name Draughts
extends RefCounted
## 49.2 ROOM DRAUGHTS (his list of another game's core gameplay, 10 Oct: "room potions";
## GAMEPLAY_PLAN.md; the names and numbers are this game's own). Belt drinks (Consumables) with a
## strong buff that lasts until the room is clear: drunk in a fight, it ends with the fight
## (Game.room_cleared); drunk where all is quiet, it lasts through the next fight. Two of a kind
## count twice. Guardians and elites drop them like the other belt items, and a door can promise
## two ("draught"). 49.3: a door can promise a WHETSTONE ("whet", +1 weapon level, one use: the
## honing stone of his list was already in the belt). Expanded game only.

## kind: [name, what it does, colour, effects]; the sprite is the kind.
const KINDS := {
	"d_war": ["WARCRY DRAUGHT", "+60% DAMAGE", "#d8443c", [["pct", "dmg", 0.6]]],
	"d_quick": ["QUICKSILVER DRAUGHT", "+40% ATTACK SPEED AND +15% MOVE SPEED", "#c8d0e0", [["mul", "rate", 1.4], ["mul", "speed", 1.15]]],
	"d_eagle": ["EAGLE-EYE DRAUGHT", "+25% CRIT CHANCE AND +0.5X CRIT DAMAGE", "#f2c94c", [["add", "crit", 0.25], ["add", "crit_mult", 0.5]]],
	"d_storm": ["STORMCALL DRAUGHT", "+2 PROJECTILES", "#4d9be6", [["add", "count", 2]]],
	"d_ghost": ["GHOSTWALK DRAUGHT", "ROLLS RECHARGE TWICE AS FAST, +1 ROLL CHARGE", "#a35bd6", [["mul", "dodge_cd", 0.5], ["add", "dodge_charges", 1]]],
	"d_leech": ["BLOODLETTER'S DRAUGHT", "A QUARTER OF YOUR KILLS HEAL HALF A HEART", "#b83a4a", [{ "on": "on_kill", "chance": 0.25, "do": [["heal", 1]] }]],
}
const UNTIL := " UNTIL THE ROOM IS CLEAR"
const REWARD_N := 2   # draughts behind a "draught" door

static var stats := {}   # drunk, ended (tests)

static func on() -> bool:
	return GameData.rogues()

static func is_kind(k: String) -> bool:
	return KINDS.has(k)

static func roll() -> String:
	return TB.pick(KINDS.keys())

## Consumables.data: its card.
static func card(k: String) -> Dictionary:
	var d: Array = KINDS[k]
	return { "name": d[0], "desc": d[1] + UNTIL, "col": d[2] }

## Consumables.use: its buff, until the room is clear.
static func drink(p: Player, kind: String) -> void:
	p.draught_n += 1
	var src := "draught:%d" % p.draught_n
	Effects.apply(p, KINDS[kind][3], 1, src)
	p.draughts.append([kind, src])
	stats["drunk"] = stats.get("drunk", 0) + 1
	Fx.float_text(p.x, p.y - 28, KINDS[kind][1], "gold")
	Juice.ring(p.x, p.y, 3, 34, 0.4, KINDS[kind][2])

## Game.room_cleared: every draught on ends.
static func on_clear(p: Player) -> void:
	if p == null or p.draughts.is_empty():
		return
	for d in p.draughts:
		Effects.apply(p, KINDS[d[0]][3], -1, d[1])
	stats["ended"] = stats.get("ended", 0) + p.draughts.size()
	p.draughts.clear()
	p.charges = mini(p.charges, p.dodge_charges)
	G.toast("THE DRAUGHTS WEAR OFF", "grey")

## World.roll_reward: doors that promise draughts, or a whetstone (expanded game only).
static func reward_weights(w: Dictionary) -> void:
	if not on():
		return
	w["draught"] = 7
	w["whet"] = 4

## Game.give_reward.
static func reward(kind: String, cx: float, cy: float) -> void:
	if kind == "whet":
		Combat.drop_pickup("c_whet", cx, cy)
		return
	for i in REWARD_N:
		Combat.drop_pickup(roll(), cx + (i - 0.5) * 16.0, cy)

## The HUD, first on the row under the belt: each draught on. Returns the x after them.
static func draw_hud(ci: CanvasItem, p: Player, x: float, y: float) -> float:
	for d in p.draughts:
		Gfx.at(ci, d[0], x, y - 2)
		x += 11
	Gfx.text(ci, "TILL CLEAR", x + 1, y + 2, "orange")
	return x + TB.text_w("TILL CLEAR") + 7
