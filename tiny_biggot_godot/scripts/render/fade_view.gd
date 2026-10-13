extends Node2D
## Screen fade (RGSS Graphics.brightness during room transitions).

func _draw() -> void:
	var a := 0.0
	if not G.fade.is_empty():
		a = G.fade["t"] if G.fade["phase"] == &"out" else 1.0 - G.fade["t"]
	a = clampf(a, 0.0, 1.0)
	if a > 0.0:
		draw_rect(Rect2(-8, -8, TB.SW + 16, TB.SH + 16), Color(0, 0, 0, a))
