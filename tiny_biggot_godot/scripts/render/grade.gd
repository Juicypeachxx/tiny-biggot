class_name Grade
extends RefCounted
## 66.5 (his word, 28 Oct, with two videos of a bright, very colourful pixel game: "like this the same
## vibe and enviroments and all"; before that: "now iss all grimmy and not alive and boring"): the
## world's colours lifted every frame, one pass over the screen under the HUD: more colour (SAT),
## more punch (CONTRAST) and a little more light (LIFT). Only the look; --no-grade turns it off
## (pictures to compare), and the option "grade" set to false.

const SAT := 1.3
const CONTRAST := 1.08
const LIFT := 1.04

const SHADER := """
shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform float sat = 1.5;
uniform float contrast = 1.1;
uniform float lift = 1.05;
void fragment() {
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(vec3(l), c, sat);
	c = (c - 0.5) * contrast + 0.5;
	COLOR = vec4(clamp(c * lift, 0.0, 1.0), 1.0);
}
"""

static var _shader: Shader

static func on() -> bool:
	return GameData.rogues() and Meta.opts.get("grade", true) and not DebugArgs.has("no-grade")

static func material() -> ShaderMaterial:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = SHADER
	var m := ShaderMaterial.new()
	m.shader = _shader
	m.set_shader_parameter("sat", SAT)
	m.set_shader_parameter("contrast", CONTRAST)
	m.set_shader_parameter("lift", LIFT)
	return m

static func paint(ci: CanvasItem) -> void:
	if on():
		ci.draw_rect(Rect2(0, 0, TB.SW, TB.SH), Color.WHITE)
