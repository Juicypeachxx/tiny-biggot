class_name Moves
extends RefCounted
## 66.2 (his word, 27 Oct: "after that animation of heros and bosses"): heroes and guardians walk and
## attack. Each has a strip, assets/graphics_hd/anim/<picture>.png (resprite/tools/anim_pl.py): row 0
## the walk, row 1 the attack, every frame the size of the picture itself, so a frame stands in for it
## (the same feet, the same box). Only how it looks: the rules never see a frame.
## A frame is cut from its strip the first time it is drawn and kept in Img's cache under its own
## name, so Gfx draws it (and its white silhouette) like any other picture.

const DIR := "res://assets/graphics_hd/anim/"
const FPS := 12.0
## A guardian at rest (no walk, no attack): its own picture.
const CALM := [&"intro", &"pick", &"rest", &"idle", &"stagebreak", &"stun", &"dizzy", &"sleep", &"wait", &"under"]
const WALKS := [&"charge", &"step", &"hop", &"chase", &"walk"]

static var _frames := {}   # picture -> frames in a row (0: no strip)
static var _seen := {}     # a guardian's uid -> [x, y, state, since, moving until]

## How many frames a row of the picture's strip has (0: it has none).
static func count(pic: String) -> int:
	if _frames.has(pic):
		return _frames[pic]
	var n := 0
	var path := DIR + pic + ".png"
	if ResourceLoader.exists(path):
		var strip: Texture2D = load(path)
		var own := Img.t(pic)
		var img := strip.get_image()
		if img != null:
			if img.is_compressed():
				img.decompress()
			var w := own.get_width() * TB.D
			var h := own.get_height() * TB.D
			n = img.get_width() / w if w > 0 else 0
			if img.get_height() < h * 2:
				n = 0
			for row in 2:
				for i in n:
					var tex := ImageTexture.create_from_image(img.get_region(Rect2i(i * w, row * h, w, h)))
					tex.set_size_override(Vector2i(own.get_width(), own.get_height()))
					Img._cache[_name(pic, row, i)] = tex
	_frames[pic] = n
	return n

static func _name(pic: String, row: int, i: int) -> String:
	return "%s@%s%d" % [pic, "wa"[row], i]

## The picture to draw for the hero: walking, attacking (just fired, standing), or its own.
static func hero(p: Player, pic: String, t: float) -> String:
	if not GameData.rogues() or p.dodge_t > 0 or p.leap_max > 0:
		return pic
	var n := count(pic)
	if n == 0:
		return pic
	if p.moving:
		return _name(pic, 0, floori(p.walk_t * FPS) % n)
	if Juice.recoil > 0.0:
		return _name(pic, 1, floori(t * FPS) % n)
	return pic

## The picture to draw for a guardian: its attack played once from the start of each attack, its
## walk while it moves, else its own.
static func boss(e: Enemy, pic: String, t: float) -> String:
	if not GameData.rogues() or e.hidden or e.hp <= 0:
		return pic
	var n := count(pic)
	if n == 0:
		return pic
	var s: Array = _seen.get(e.uid, [])
	if s.is_empty() or s[2] != e.state:
		if _seen.size() > 64:
			_seen.clear()
		s = [e.x, e.y, e.state, t, s[4] if not s.is_empty() else 0.0]
		_seen[e.uid] = s
	if absf(e.x - s[0]) + absf(e.y - s[1]) > 0.05:
		s[4] = t + 0.15
	s[0] = e.x
	s[1] = e.y
	var moving: bool = t < s[4]
	if not e.state in CALM and not e.state in WALKS and e.stun_t <= 0.0:
		return _name(pic, 1, mini(floori((t - s[3]) * FPS), n - 1))
	if moving or e.state in WALKS:
		return _name(pic, 0, floori(t * FPS * (1.5 if e.state == &"charge" else 1.0)) % n)
	return pic

