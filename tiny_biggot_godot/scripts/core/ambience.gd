class_name Ambience
extends RefCounted
## 21.3 THE SOUND OF EACH PLACE (his word, 8 Oct: "make game more alive"). Expanded game only.
## Each world has a quiet loop of its own under the music (dripping crypts, crickets in the grotto,
## rain, the forge, wind and far bells, the hum of the Eclipse, bubbling ink, a library clock, the
## roaring hearth, the camp at night); the hero's feet sound like the floor they walk on; the music
## is fuller while a room is shut for a fight and softer once it is quiet. Sound only: Snd plays it
## all with dice of its own, so nothing here touches the run. The sounds are made from scratch by
## tools/audio/sounds21.py.

## A floor's name -> [loop, footsteps].
const FLOOR := {
	"THE OSSUARY": ["crypt", "stone"], "MIREWOOD GROTTO": ["grotto", "grass"], "THE SUNKEN ARCHIVE": ["water", "water"],
	"THE CINDERFORGE": ["forge", "metal"], "RIMEFROST VAULT": ["wind", "snow"], "THE HOLLOW THRONE": ["crypt", "stone"],
	"RAINMARSH HAMLET": ["rain", "water"], "ASHEN WARFRONT": ["forge", "grass"], "FROSTPEAK MONASTERY": ["wind", "snow"],
	"NIGHTSPIRE ROOFTOPS": ["wind", "wood"], "THE ECLIPSE": ["eclipse", "stone"],
	"THE INKWELL": ["ink", "paper"], "THE BINDERY": ["ink", "paper"], "THE QUILL SPIRE": ["ink", "paper"],
	"THE GLOSSARY": ["ink", "paper"], "THE FOOTNOTES": ["ink", "paper"], "THE COVER": ["ink", "paper"],
	"THE STACKS": ["library", "wood"], "THE READING ROOM": ["library", "wood"], "THE HEARTH": ["hearth", "stone"],
}
## A rift world's id -> [loop, footsteps].
const RIFT := {
	"gaol": ["crypt", "stone"], "cathedral": ["crypt", "stone"], "bastion": ["wind", "stone"], "brand": ["forge", "metal"],
	"brazil": ["library", "paper"], "heist": ["library", "wood"], "burb": ["camp", "grass"], "dust": ["wind", "grass"],
	"fog": ["water", "water"], "heaven": ["wind", "stone"], "hell": ["hearth", "stone"], "neon": ["eclipse", "metal"],
	"redaction": ["ink", "paper"], "rimefrost": ["wind", "snow"], "seam": ["eclipse", "stone"], "skyreach": ["wind", "wood"],
	"spire": ["wind", "stone"], "streets": ["rain", "stone"],
}
const STRIDE := 20.0   # pixels walked between two footsteps (about four a second)

static var _surface := "stone"
static var _walked := 0.0
static var _last := Vector2.ZERO

static func on() -> bool:
	return GameData.rogues()

## [loop, footsteps] for the room the hero is in.
static func here() -> Array:
	var room := G.room
	if room == null:
		return ["", "stone"]
	if room.type == "camp":
		return ["camp", "grass"]
	if not room.theme.is_empty() and RIFT.has(room.theme.get("id", "")):
		return RIFT[room.theme["id"]]
	var fl: Array = GameData.floors()
	if G.floor_index >= 0 and G.floor_index < fl.size():
		return FLOOR.get(fl[G.floor_index]["name"], ["crypt", "stone"])
	return ["crypt", "stone"]

## Game.enter_room: this place's loop (the same place carries on without a break).
static func on_room() -> void:
	if not on():
		Snd.ambience("")
		return
	var h := here()
	Snd.ambience(h[0])
	_surface = h[1]
	_walked = 0.0
	if G.player != null:
		_last = Vector2(G.player.x, G.player.y)

## The run is over (death, a win, back to the title): the place's sound fades away.
static func stop() -> void:
	Snd.ambience("")

## Every tick of play: the music's fight or calm level, and footsteps.
static func tick(p: Player) -> void:
	if not on() or p == null:
		return
	Snd.calm(not G.locked)
	var now := Vector2(p.x, p.y)
	var d := now.distance_to(_last)
	_last = now
	if d > 6.0 or not p.moving or p.dodge_t > 0 or p.air > 0:   # a jump (a door, a blink), a roll, a leap: no step
		return
	_walked += d
	if _walked >= STRIDE:
		_walked -= STRIDE
		Snd.step(_surface)
