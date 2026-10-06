class_name Alignments
extends RefCounted
## 8.1 Alignments (his ask, 6 Oct, from pictures of another game: the idea only; the perks,
## numbers and icons are this game's own). Four leanings a run can take: GOOD, EVIL, LAWFUL and
## CHAOTIC (Player.al_good / al_evil / al_law / al_chaos). Points come from the four little shrines
## in each rest stop (one per rest stop), from Heaven (+2 GOOD) and Hell (+2 EVIL), and from the
## constellation's four diagonal spokes (stars.gd). Perks there hold while an alignment LEADS (2 or
## more and no other higher) or while you are DEVOUT (one alignment 2 or more, the other three 1 or
## less): Effects conditions "lead_good" ... and "devout", and "while_align" procs.
## Expanded game only.

const KEYS := ["good", "evil", "law", "chaos"]
const NAMES := { "good": "GOOD", "evil": "EVIL", "law": "LAWFUL", "chaos": "CHAOTIC" }
const COLS := { "good": "gold", "evil": "red", "law": "cyan", "chaos": "purple" }
const HEX := { "good": "#f2c94c", "evil": "#d8443c", "law": "#6fd3e0", "chaos": "#a35bd6" }
const ICON := { "good": "al_good", "evil": "al_evil", "law": "al_law", "chaos": "al_chaos" }

static func value(p: Player, k: String) -> int:
	return int(p.get("al_" + k))

static func add(p: Player, k: String, n: int) -> void:
	p.set("al_" + k, value(p, k) + n)

## The alignment leads: 2 or more, and no other is higher.
static func leads(p: Player, k: String) -> bool:
	var v := value(p, k)
	if v < 2:
		return false
	for o in KEYS:
		if value(p, o) > v:
			return false
	return true

## Devout: one alignment is 2 or more and the other three are 1 or less.
static func devout(p: Player) -> bool:
	var high := 0
	for k in KEYS:
		var v := value(p, k)
		if v >= 2:
			high += 1
		elif v > 1:
			return false
	return high == 1

static func holds(p: Player, need: String) -> bool:
	if p == null or not GameData.rogues():
		return false
	if need == "devout":
		return devout(p)
	return need in KEYS and leads(p, need)

## A rest stop's four shrines (game.gd room setup), in a row under the campfire.
static func shrines(r: Room, cx: float, cy: float) -> void:
	for i in KEYS.size():
		r.objects.append({ "kind": "alshrine", "al": KEYS[i], "x": cx - 66 + i * 44, "y": cy + 46 })

## Touching a shrine: +1 of its alignment; the others in the room go quiet.
static func take_shrine(r: Room, o: Dictionary) -> void:
	var p := G.player
	add(p, o["al"], 1)
	for s in r.objects:
		if s["kind"] == "alshrine":
			s["used"] = true
	Fx.burst(o["x"], o["y"] - 6, [HEX[o["al"]], "#ffffff"], 18, 60)
	Snd.play("relic")
	G.toast("+1 %s (NOW %d)" % [NAMES[o["al"]], value(p, o["al"])], COLS[o["al"]])
