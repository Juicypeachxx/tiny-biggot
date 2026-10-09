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

# ---------- 38.1 THE ALIGNMENT REVAMP (his word, 9 Oct, from notes on another game; our own) ----------
## GOOD, EVIL, LAWFUL and CHAOTIC never cancel each other out (each is its own count). Now they also:
##   - decide the end path: 3 or more GOOD (and more than EVIL) opens Heaven at the soul gate, 3 or
##     more EVIL (and more than GOOD) opens Hell, whatever your items lean to (Soul.realm);
##   - set the vendors' prices: a vendor has an alignment; yours matching (more of it than of its
##     opposite) makes it x0.7, the opposite leading makes it x1.4 (Game.price's "al");
##   - start some heroes off (HERO_START);
##   - can be bought at a WAYSHRINE after every guardian: LAWFUL and CHAOTIC always, GOOD once
##     Heaven's ruler has fallen in some run, EVIL once Hell's has;
##   - make some gear grow (dmg_per_good, crit_per_evil, rate_per_law, proc_per_chaos).

const OPPOSITE := { "good": "evil", "evil": "good", "law": "chaos", "chaos": "law" }
const SWAY := 3   # this much GOOD or EVIL decides the soul gate
const HERO_START := { "warden": ["good", 1], "pilgrim": ["good", 2], "mirrorknight": ["good", 1], "plaguesaint": ["good", 1],
	"beekeeper": ["good", 1], "hexer": ["evil", 1], "gravedigger": ["evil", 1], "oathbreaker": ["evil", 1],
	"condemned": ["evil", 1], "forsaken": ["evil", 1], "boneweaver": ["evil", 1], "executioner": ["evil", 1],
	"bonecaller": ["evil", 2], "banehunter": ["law", 1], "clockmaker": ["law", 1], "wayfarer": ["law", 1],
	"tavernknight": ["law", 1], "jester": ["chaos", 1], "berserker": ["chaos", 1], "demolitionist": ["chaos", 1],
	"racketeer": ["chaos", 1], "trickshot": ["chaos", 1], "gaolbird": ["chaos", 1] }

## Game.new_run: some heroes start with a leaning.
static func start(p: Player) -> void:
	if not GameData.rogues():
		return
	var s = HERO_START.get(p.hero.get("id", ""))
	if s != null:
		add(p, s[0], s[1])

## A vendor of alignment `al`: x0.7 when yours matches, x1.4 when its opposite leads you.
static func price_mult(p: Player, al: String) -> float:
	if p == null or not GameData.rogues() or not OPPOSITE.has(al):
		return 1.0
	var mine := value(p, al)
	var opp := value(p, OPPOSITE[al])
	if mine >= 1 and mine > opp:
		return 0.7
	if opp >= 1 and opp > mine:
		return 1.4
	return 1.0

## " (EVIL: CHEAPER FOR YOU)" style note for a vendor's line ("" when the price is plain).
static func price_note(p: Player, al: String) -> String:
	var m := price_mult(p, al)
	if m < 1.0:
		return " (%s: CHEAPER)" % NAMES[al]
	if m > 1.0:
		return " (%s: DEARER)" % NAMES[al]
	return ""

## The soul gate's choice by alignment alone ("" when items decide, Soul.realm).
static func path(p: Player) -> String:
	if p == null or not GameData.rogues():
		return ""
	var good := value(p, "good")
	var evil := value(p, "evil")
	if good >= SWAY and good > evil:
		return "heaven"
	if evil >= SWAY and evil > good:
		return "hell"
	return ""

## The alignments a WAYSHRINE offers now.
static func offered() -> Array:
	var out := ["law", "chaos"]
	if Meta.meta.get("heaven_wins", 0) > 0:
		out.push_front("good")
	if Meta.meta.get("hell_wins", 0) > 0:
		out.insert(1 if out[0] == "good" else 0, "evil")
	return out

## Game.on_boss_dead: a WAYSHRINE under the guardian's hoard: +1 of an alignment for gold.
static func wayshrine(r: Room) -> void:
	if not GameData.rogues():
		return
	var offer := offered()
	var cx := 14.0 * TB.TS
	for i in offer.size():
		r.objects.append({ "kind": "alwayshrine", "al": offer[i], "x": cx - (offer.size() - 1) * 22.0 + i * 44.0,
			"y": 13.4 * TB.TS, "price": G.price(25 + G.floor_index * 5) })

## Paying at a WAYSHRINE (Game.interact): +1 for good, and the soul gate looks again.
static func buy(r: Room, o: Dictionary) -> void:
	var p := G.player
	if o.get("used", false):
		return
	if p.gold < o["price"]:
		return G.deny(o, "NEED %d GOLD" % o["price"])
	p.gold -= o["price"]
	o["used"] = true
	add(p, o["al"], 1)
	Fx.burst(o["x"], o["y"] - 6, [HEX[o["al"]], "#ffffff"], 18, 60)
	Snd.play("relic")
	G.toast("+1 %s (NOW %d)" % [NAMES[o["al"]], value(p, o["al"])], COLS[o["al"]])
	for s in r.objects:
		if s["kind"] == "soulgate":
			var w := Soul.weigh(p)
			s["realm"] = Soul.realm(p)
			s["light"] = w[0]
			s["dark"] = w[1]
