extends Node
## 59.1 (V2, his word, 23 Oct: "make the armour on the hero in the new look too"): the gear painted
## over the hero (scripts/render/hero_gear.gd).
## Run: godot --headless --path . res://tests/gear_look_test.tscn -- --no-save [--sheet=PATH]
##   1. Every kind of gear on every hero makes an outfit of the hero picture's own pixels (66.3:
##      48 x 56 for the new heroes), drawn at the hero's size in the game.
##   2. What goes on the body, the feet and the hands lies on the hero's own picture.
##   3. The same outfit twice is the same pixels.
## With --sheet=PATH it also writes a picture: every hero bare, then in five outfits.
## Prints "gear look test: PASSED" or a FAIL line per problem.

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL gear look: ", msg)

## One piece of each kind: [slot to wear it in, gear].
func _kinds() -> Array:
	var seen := {}
	var out := []
	for g: Dictionary in Gear.all():
		var k: String = g["slot"] + "/" + g["shape"]
		if seen.has(k):
			continue
		seen[k] = true
		out.append(["ring1" if g["slot"] == "ring" else g["slot"], g])
	return out

func _first(slot: String, shape: String) -> Dictionary:
	for g: Dictionary in Gear.all():
		if g["slot"] == slot and g["shape"] == shape:
			return g
	return {}

func _ready() -> void:
	await get_tree().process_frame
	var heroes: Array = GameData.heroes()
	var kinds := _kinds()
	var outfits := 0
	for h: Dictionary in heroes:
		var hero: String = h["sprite"]
		var body := Img.image(hero)
		var bw := body.get_width()
		var bh := body.get_height()
		for k in kinds:
			var p := Player.new(h)
			p.gear[k[0]] = k[1]
			var tex := HeroGear.texture(p, hero)
			outfits += 1
			if tex == null or tex.get_size() != Vector2(HeroGear.size_of(hero)):   # 64.5: the hero's own size (twice the old for the new heroes)
				fail("%s in %s: no outfit, or not drawn at the hero's size" % [hero, k[1]["id"]])
				continue
			var img := tex.get_image()
			if img.get_size() != Vector2i(bw, bh):
				fail("%s in %s: the outfit is %s, not %dx%d" % [hero, k[1]["id"], img.get_size(), bw, bh])
				continue
			if k[0] in ["body", "feet", "hands"]:
				var out := 0
				for y in bh:
					for x in bw:
						if img.get_pixel(x, y).a > 0.0 and body.get_pixel(x, y).a < 0.5:
							out += 1
				if out > 0:
					fail("%s in %s: %d pixels off the hero's picture" % [hero, k[1]["id"], out])
			HeroGear._cache.clear()
			if HeroGear.texture(p, hero).get_image().get_data() != img.get_data():
				fail("%s in %s: not the same pixels twice" % [hero, k[1]["id"]])
	print("[gear] %d heroes, %d kinds of gear, %d outfits made" % [heroes.size(), kinds.size(), outfits])
	if DebugArgs.has("sheet"):
		_sheet(heroes, DebugArgs.get_str("sheet"))
	print("gear look test: PASSED" if fails == 0 else "gear look test: FAILED (%d)" % fails)
	get_tree().quit(0 if fails == 0 else 1)

## Every hero bare, then in five outfits, three times the picture's size.
func _sheet(heroes: Array, path: String) -> void:
	var sets := [
		{ "head": _first("head", "helm"), "body": _first("body", "plate"), "feet": _first("feet", "greaves"), "hands": _first("hands", "gloves") },
		{ "head": _first("head", "hood"), "body": _first("body", "robe"), "neck": _first("neck", "amulet") },
		{ "head": _first("head", "hat"), "body": _first("body", "leather"), "feet": _first("feet", "boots"), "offhand": _first("offhand", "offhand") },
		{ "head": _first("head", "crown"), "body": _first("body", "cloak"), "trinket": _first("trinket", "charm"), "ring1": _first("ring", "ring"), "ring2": _first("ring", "ring") },
		{ "head": _first("head", "mask"), "body": _first("body", "leather"), "feet": _first("feet", "boots") },
	]
	var k := 3
	var cw := 48 * k + 6
	var chh := 56 * k + 6
	var sheet := Image.create(cw * heroes.size(), chh * (sets.size() + 1), false, Image.FORMAT_RGBA8)
	sheet.fill(Color8(70, 80, 100))
	for i in heroes.size():
		var h: Dictionary = heroes[i]
		var hero: String = h["sprite"]
		for j in sets.size() + 1:
			var im: Image = Img.image(hero).duplicate()
			var iw := im.get_width()
			var ih := im.get_height()
			if j > 0:
				var p := Player.new(h)
				for slot in sets[j - 1]:
					p.gear[slot] = sets[j - 1][slot]
				var o := HeroGear.texture(p, hero).get_image()
				im.blend_rect(o, Rect2i(0, 0, iw, ih), Vector2i.ZERO)
			im.resize(iw * k, ih * k, Image.INTERPOLATE_NEAREST)
			sheet.blend_rect(im, Rect2i(Vector2i.ZERO, im.get_size()), Vector2i(i * cw + 3, j * chh + 3))
	print("[gear] sheet: %s: %s" % [path, error_string(sheet.save_png(path))])
