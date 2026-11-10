class_name StatDrops
extends RefCounted
## 8.3 Stat stacking (his ask, 6 Oct, from a picture of another game: the idea only). Small stat
## pickups with a label over them, which stack up over a run to build a weapon or a build:
## +1 STR / DEX / INT, +2% DAMAGE, +2% FIRE RATE, +1% CRIT, +1% MOVE SPEED, +1 LUCK.
## They come from cleared fights (25%), elites (15%), chests (35%) and guardians (two). Nothing
## is taken away from anything: they only add. Expanded game only.

## kind -> [label, icon, colour, weight]
const KINDS := {
	"s_str": ["+1 STR", "mi_str", "red", 4], "s_dex": ["+1 DEX", "mi_dex", "lime", 4], "s_int": ["+1 INT", "mi_int", "cyan", 4],
	"s_dmg": ["+2% DAMAGE", "mi_dmg", "red", 3], "s_rate": ["+2% FIRE RATE", "mi_rate", "gold", 3],
	"s_crit": ["+1% CRIT", "mi_crit", "gold", 3], "s_speed": ["+1% MOVE SPEED", "mi_speed", "cyan", 2],
	"s_luck": ["+1 LUCK", "mi_luck", "lime", 1],
	"s_spi": ["+1 SPIRIT", "mi_spi", "pink", 2],   # 52
}

static func is_kind(k: String) -> bool:
	return KINDS.has(k)

static func roll() -> String:
	var total := 0
	for k in KINDS:
		total += KINDS[k][3]
	var r := randi() % total
	for k in KINDS:
		r -= KINDS[k][3]
		if r < 0:
			return k
	return "s_str"

## A chance of one stat pickup at x, y.
static func maybe(chance: float, x: float, y: float) -> void:
	if GameData.rogues() and randf() < chance:
		Combat.drop_pickup(roll(), x, y)

## Picked up (Combat.update_pickups).
static func take(p: Player, k: String) -> void:
	match k:
		"s_str": Attributes.add(p, "str", 1)
		"s_dex": Attributes.add(p, "dex", 1)
		"s_int": Attributes.add(p, "int", 1)
		"s_dmg": Effects.apply(p, [["mul", "dmg", 1.02]])
		"s_rate": Effects.apply(p, [["mul", "rate", 1.02]])
		"s_crit": p.crit += 0.01
		"s_speed": Effects.apply(p, [["mul", "speed", 1.01]])
		"s_luck": Attributes.add(p, "lck", 1)
		"s_spi": Attributes.add(p, "spi", 1)   # 52
	p.stat_picks += 1
	Snd.play("relic")
	Fx.float_text(p.x, p.y - 12, KINDS[k][0], KINDS[k][2])

## Its label over it on the floor (world_view).
static func draw_label(ci: CanvasItem, k: Pickup, wob: float) -> void:
	var d: Array = KINDS[k.kind]
	var w := TB.text_w(d[0]) + 6
	var x := roundf(k.x - w / 2.0)
	var y := roundf(k.y - 16 - k.z - wob)
	ci.draw_rect(Rect2(x, y, w, 9), Color(0.05, 0.04, 0.07, 0.85))
	ci.draw_rect(Rect2(x, y + 8, w, 1), TB.c("#5a5770"))
	Gfx.text(ci, d[0], x + 3, y + 2, d[2])
