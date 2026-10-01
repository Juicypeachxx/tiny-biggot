extends Node
## Sound effects and music (port of Core.rb `Snd`). Autoload name: Snd.
##
## Sound effects go through a fixed pool of players, and the per-sound frame
## gaps from the original stop a hail of shots from flooding the mixer.

const SE_DIR := "res://assets/audio/se/cc_"
const BGM_DIR := "res://assets/audio/bgm/cc_track"
const POOL := 16
const GAP := { "shoot": 3, "hit": 3, "ebullet": 5, "coin": 2, "bolt": 3, "hatchet": 3 }
const PITCHED := ["shoot", "hit", "kill", "bolt", "hatchet", "ebullet", "spawn"]

var _last := {}
var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _bgm: AudioStreamPlayer
var _track := -1
## Headless runs (CI checks) load streams but never start playbacks: the dummy
## audio driver does not release a playing stream at exit and reports a leak.
var _silent := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_silent = DisplayServer.get_name() == "headless" or DebugArgs.has("shot")
	for i in POOL:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_bgm = AudioStreamPlayer.new()
	add_child(_bgm)
	_bgm.finished.connect(_on_bgm_finished)

func _stream(path: String) -> AudioStream:
	var s = _streams.get(path)
	if s == null:
		s = load(path) if ResourceLoader.exists(path) else null
		_streams[path] = s if s != null else false
	return s if s is AudioStream else null

func play(name: String) -> void:
	if not Meta.opts["sfx"]:
		return
	var f := Engine.get_physics_frames()
	var g: int = GAP.get(name, 0)
	if g > 0 and _last.has(name) and f - _last[name] < g:
		return
	_last[name] = f
	var st := _stream(SE_DIR + name + ".wav")
	if st == null:
		return
	var pitch := 100
	if name in PITCHED:
		pitch = 94 + randi() % 13
	var vol := 55 if name == "ebullet" else 85
	if _silent:
		return
	var p := _players[_next]
	_next = (_next + 1) % POOL
	p.stream = st
	p.pitch_scale = pitch / 100.0
	p.volume_db = linear_to_db(vol / 100.0)
	p.play()

func music(n: int) -> void:
	if _track == n and Meta.opts["music"]:
		return
	_track = n
	if Meta.opts["music"]:
		var st := _stream(BGM_DIR + str(n) + ".wav")
		if st != null and not _silent:
			_bgm.stream = st
			_bgm.volume_db = linear_to_db(0.7)
			_bgm.play()
	else:
		_bgm.stop()

func refresh() -> void:
	var t := _track if _track >= 0 else 0
	_track = -1
	music(t)

## Release playbacks on exit so quitting mid-track does not leak the stream.
func _exit_tree() -> void:
	for p in _players:
		p.stop()
		p.stream = null
	_bgm.stop()
	_bgm.stream = null
	_streams.clear()

func _on_bgm_finished() -> void:
	if Meta.opts["music"] and _bgm.stream != null:
		_bgm.play()
