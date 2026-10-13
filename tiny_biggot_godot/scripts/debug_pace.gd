class_name DebugPace
extends RefCounted
## 35.2 PACE (his word, 9 Oct: "immediate dopamine and hyper-fast pacing"). --pace-log, with the
## bot: one line per room with how its time went, and a summary every game minute:
##   [pace] f1 combat waves 2: start 0.6s, fight 14.2s, waits 1.3s, after 3.1s, kills 9
##   start  room entered -> first foe up        fight  first foe -> the room is clear
##   waits  locked with no foe up (between waves) after  clear -> the room is left
## and when the hero reached each level. Reads the game only; changes nothing.

static var _room: Room = null
static var _t0 := 0
static var _first := -1
static var _clear := -1
static var _waits := 0
static var _tail := 0    # the last wave down to its last one or two foes
static var _waves := 0
static var _kills0 := 0
static var _lv := 1
static var _rows := []   # [floor, type, start, fight, waits, after, kills]

static func tick(t: int) -> void:
	if G.player == null or G.room == null:
		return
	var p := G.player
	if p.level > _lv:
		_lv = p.level
		print("[pace] level %d at %.0fs (floor %d)" % [_lv, t / 60.0, G.floor_index + 1])
	if G.room != _room:
		_close(t)
		_room = G.room
		_t0 = t
		_first = -1
		_clear = -1
		_waits = 0
		_tail = 0
		_waves = 0
		_kills0 = int(G.run_stats.get("kills", 0))
		if p.level < _lv:
			_lv = p.level   # a new run
	if G.state != &"play" or not (_room.type in ["combat", "elite"]):
		return
	var foes := 0
	for e in G.enemies:
		if not e.type in ["dummy", "target"]:
			foes += 1
	if foes > 0 and _first < 0:
		_first = t
	if G.locked and _first >= 0 and foes == 0:
		_waits += 1
	if G.locked and _room.waves_left <= 0 and foes > 0 and foes <= 2:
		_tail += 1
	if not G.locked and _first >= 0 and _clear < 0:
		_clear = t

static func _close(t: int) -> void:
	if _room == null or not (_room.type in ["combat", "elite"]) or _first < 0 or _clear < 0:
		return
	var row := [G.floor_index + 1, _room.type, (_first - _t0) / 60.0, (_clear - _first) / 60.0, _waits / 60.0,
		(t - _clear) / 60.0, int(G.run_stats.get("kills", 0)) - _kills0, _tail / 60.0]
	_rows.append(row)
	print("[pace] f%d %s: start %.1fs, fight %.1fs, waits %.1fs, after %.1fs, kills %d, tail %.1fs" % row)

## Averages so far (main.gd, every game minute).
static func summary() -> void:
	print("[pace] state %s, room %s" % [G.state, G.room.type if G.room != null else "-"])
	if _rows.is_empty():
		return
	var s := [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
	for r in _rows:
		for i in 6:
			s[i] += r[i + 2]
	var n := float(_rows.size())
	print("[pace] %d rooms: start %.1fs, fight %.1fs, waits %.1fs, after %.1fs, kills %.1f, tail %.1fs a room" % [
		_rows.size(), s[0] / n, s[1] / n, s[2] / n, s[3] / n, s[4] / n, s[5] / n])
