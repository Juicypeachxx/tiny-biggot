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
	for i in 2:
		var a := AudioStreamPlayer.new()
		add_child(a)
		_amb.append(a)
	_stepper = AudioStreamPlayer.new()
	add_child(_stepper)
	_preload()

## Loads every sound and track now (about a megabyte and a half in all), so the first time one
## plays, in the middle of a fight or as a floor begins, no file has to be opened.
func _preload() -> void:
	for dir in ["res://assets/audio/se/", "res://assets/audio/bgm/", "res://assets/audio/amb/"]:
		for f in DirAccess.get_files_at(dir):
			var base := f.trim_suffix(".import").trim_suffix(".remap")
			if base.ends_with(".wav"):
				_stream(dir + base)

func _stream(path: String) -> AudioStream:
	var s = _streams.get(path)
	if s == null:
		s = load(path) if ResourceLoader.exists(path) else null
		_streams[path] = s if s != null else false
	return s if s is AudioStream else null

## 21.2: own_dice: a sound of something only drawn (a prop falling) varies its pitch with dice of
## its own, so it never moves the run's random numbers.
var _deco_dice := RandomNumberGenerator.new()

func play(name: String, own_dice: bool = false) -> void:
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
		pitch = 94 + (_deco_dice.randi() if own_dice else randi()) % 13
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
			_bgm.volume_db = linear_to_db(_music_level)
			_bgm.play()
	else:
		_bgm.stop()

func refresh() -> void:
	var t := _track if _track >= 0 else 0
	_track = -1
	music(t)

# ---------- 21.3 the sound of each place (Ambience says which place and when) ----------
const AMB_DIR := "res://assets/audio/amb/amb_"
const AMB_VOL := 0.12      # the loops are made equally loud (tools/audio/sounds21.py); this sits them under the music
const AMB_FIGHT := 0.6     # how much of that is left while a room is shut for a fight
const MUSIC_VOL := 0.7     # the music as it always was ...
const MUSIC_CALM := 0.45   # ... and once a room is quiet again (only while a place's loop plays)
const FADE := 0.8          # seconds for a level to settle
const STEP_VOL := 0.2
var _amb: Array[AudioStreamPlayer] = []   # two, so one place fades out as the next fades in
var _amb_cur := 0
var _amb_name := ""
var _amb_level := [0.0, 0.0]
var _calm := false
var _music_level := MUSIC_VOL
var _stepper: AudioStreamPlayer
var steps_taken := 0

## The place's loop: a new place fades in as the old one fades out; "" lets it fade away.
func ambience(name: String) -> void:
	if name == _amb_name:
		return
	_amb_name = name
	_amb_cur = 1 - _amb_cur
	var a := _amb[_amb_cur]
	a.stop()
	_amb_level[_amb_cur] = 0.0
	if name == "":
		_calm = false
		return
	var st := _stream(AMB_DIR + name + ".wav")
	if st == null or _silent:
		return
	a.stream = st
	a.volume_db = -80.0
	a.play(_deco_dice.randf() * st.get_length())   # each visit starts somewhere else in the loop

## A room shut for a fight (false) or quiet (true): the music is fuller in a fight, the place's
## own sound comes up once it is quiet.
func calm(v: bool) -> void:
	_calm = v

## OPTIONS: PLACE SOUNDS (the loops and the footsteps; off with the sound effects too).
func places() -> bool:
	return Meta.opts["sfx"] and Meta.opts.get("places", true)

func ambience_name() -> String:
	return _amb_name

func music_level() -> float:
	return _music_level

## A footstep on this place's floor: a player of its own (it never takes a voice from the fight)
## and dice of its own.
func step(surface: String) -> void:
	if not places():
		return
	steps_taken += 1   # counted for tests/ambience_test (a headless run plays nothing)
	if _silent:
		return
	var st := _stream(SE_DIR + "step_" + surface + ".wav")
	if st == null:
		return
	_stepper.stream = st
	_stepper.pitch_scale = 0.9 + _deco_dice.randf() * 0.2
	_stepper.volume_db = linear_to_db(STEP_VOL * (0.8 + _deco_dice.randf() * 0.2))
	_stepper.play()

func _process(dt: float) -> void:
	for i in 2:
		var goal := 0.0
		if i == _amb_cur and _amb_name != "" and places():
			goal = AMB_VOL * (1.0 if _calm else AMB_FIGHT)
		_amb_level[i] = move_toward(_amb_level[i], goal, dt * AMB_VOL / FADE)
		var a := _amb[i]
		if a.playing:
			if _amb_level[i] <= 0.0 and i != _amb_cur:
				a.stop()
			else:
				a.volume_db = linear_to_db(maxf(_amb_level[i], 0.0001))
	var mg := MUSIC_CALM if _calm and _amb_name != "" else MUSIC_VOL
	if _music_level != mg:
		_music_level = move_toward(_music_level, mg, dt * (MUSIC_VOL - MUSIC_CALM) / FADE)
		_bgm.volume_db = linear_to_db(_music_level)

## Release playbacks on exit so quitting mid-track does not leak the stream.
func _exit_tree() -> void:
	var all: Array[AudioStreamPlayer] = _players.duplicate()
	all.append_array(_amb)
	all.append(_stepper)
	for p in all:
		p.stop()
		p.stream = null
	_bgm.stop()
	_bgm.stream = null
	_streams.clear()

func _on_bgm_finished() -> void:
	if Meta.opts["music"] and _bgm.stream != null:
		_bgm.play()
