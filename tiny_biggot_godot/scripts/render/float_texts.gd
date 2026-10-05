class_name FloatTexts
extends Node2D
## Floating damage numbers, kept on the canvas instead of redrawn. A number's
## glyphs never change while it floats: only its place and opacity do. So each
## number gets its own canvas item, its glyphs are drawn into it once, and
## every tick after that costs two calls (move it, fade it) instead of two
## draw calls per character. The picture is the one Fx.draw_texts made: same
## glyphs, same whole-pixel places, same order (older numbers underneath).

var _items: Array[RID] = []          # pool of canvas items (children of this node)
var _free: Array[int] = []
var _active: Array[int] = []         # slots showing a number
var _seen := PackedInt32Array()      # slot -> the tick it was last synced
var _hw := PackedInt32Array()        # slot -> half the text's width (as Fx.draw_texts centred it)
var _lift := PackedFloat32Array()    # slot -> 4 for big numbers, else 0
var _amp := PackedFloat32Array()     # slot -> height of the pop when a number appears
var _tick := 0
var _order := 0

func _exit_tree() -> void:
	for rid in _items:
		RenderingServer.free_rid(rid)
	_items.clear()

func _slot() -> int:
	if not _free.is_empty():
		return _free.pop_back()
	var rid := RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_parent(rid, get_canvas_item())
	_items.append(rid)
	_seen.append(0)
	_hw.append(0)
	_lift.append(0.0)
	_amp.append(0.0)
	return _items.size() - 1

## The glyphs of Gfx.text(…, 0, 0, col, sc) with its shadow, drawn into a canvas item.
func _draw_glyphs(rid: RID, st: String, col: String, sc: int) -> void:
	var sheet := Gfx._sheet(sc, col)
	var shadow := Gfx._shadow(sc)
	var gw := 3 * sc
	var gh := 5 * sc
	var step := 4 * sc
	var x := 0.0
	for i in st.length():
		var idx := Gfx.glyph_index(st.unicode_at(i))
		if idx > 0:
			var src := Rect2(idx * step, 0, gw, gh)
			_add(rid, shadow, Rect2(x, sc, gw, gh), src)
			_add(rid, sheet, Rect2(x, 0, gw, gh), src)
		x += step

func _add(rid: RID, tex: Texture2D, rect: Rect2, src: Rect2) -> void:
	if tex is AtlasTexture:
		src.position += tex.region.position
		RenderingServer.canvas_item_add_texture_rect_region(rid, rect, tex.atlas.get_rid(), src)
	else:
		RenderingServer.canvas_item_add_texture_rect_region(rid, rect, tex.get_rid(), src)

## Once per tick: gives new numbers an item, moves and fades the rest, hides the gone.
func sync() -> void:
	var t0 := Time.get_ticks_usec() if DrawLayer.perf_on else 0
	_tick += 1
	# OPTIONS > FAST DRAWING off: nothing is shown here (WorldView draws the numbers the
	# plain way), and every item is handed back below.
	var list: Array = Fx.texts if Meta.opts.get("fast_draw", true) else []
	for t: Dictionary in list:
		var slot: int = t.get("slot", -1)
		if slot >= 0 and _seen[slot] != _tick - 1:
			slot = -1   # its item was handed back while FAST DRAWING was off
		if slot < 0:
			slot = _slot()
			t["slot"] = slot
			var sc := 2 if t.get("big", false) else 1
			var st := str(t["text"]).to_upper()
			var rid := _items[slot]
			RenderingServer.canvas_item_clear(rid)
			_draw_glyphs(rid, st, t["col"], sc)
			_order += 1
			RenderingServer.canvas_item_set_draw_index(rid, _order)
			RenderingServer.canvas_item_set_visible(rid, true)
			_hw[slot] = (TB.text_w(t["text"], sc) + 1) / 2
			_lift[slot] = 4.0 if sc == 2 else 0.0
			_amp[slot] = 5.0 if sc == 2 else 3.0
			_active.append(slot)
		_seen[slot] = _tick
		var life: float = t["life"]
		# Pop: numbers jump up a few pixels in their first 0.12 s, then drift.
		var jump := -sin(minf((0.7 - life) / 0.12, 1.0) * PI * 0.5) * _amp[slot]
		var rid2 := _items[slot]
		RenderingServer.canvas_item_set_transform(rid2, Transform2D(0.0,
			Vector2(roundf(t["x"] - _hw[slot]), roundf(t["y"] + jump - _lift[slot]))))
		RenderingServer.canvas_item_set_modulate(rid2, Color(1, 1, 1, clampf(life * 3, 0.0, 1.0)))
	# Numbers that are gone give their item back.
	var w := 0
	for k in _active.size():
		var slot := _active[k]
		if _seen[slot] == _tick:
			_active[w] = slot
			w += 1
		else:
			RenderingServer.canvas_item_set_visible(_items[slot], false)
			_free.append(slot)
	_active.resize(w)
	if _order > 1000000:
		_order = 0
	if DrawLayer.perf_on:
		DrawLayer.perf["texts"] = DrawLayer.perf.get("texts", 0) + Time.get_ticks_usec() - t0
