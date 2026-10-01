class_name TB
extends RefCounted
## Core constants and helpers (port of Core.rb).
##
## Ruby -> GDScript traps handled here (see PORTING_NOTES.md):
##  * Ruby `a % b` takes the sign of b; GDScript `%` truncates. Use rmod()/fmodp().
##  * Ruby Integer#/ floors toward -inf; GDScript int/int truncates. Use idiv().
##  * In Ruby only nil and false are falsy; 0, 0.0, "" and [] are truthy.
##    Never write `if angle:` for a number that may legitimately be 0.

const SW := 448
const SH := 288
const TS := 16
const COLS := 28
const ROWS := 18
const IX0 := 1
const IY0 := 2
const IW := 26
const IH := 15
const DT := 1.0 / 60.0

# ---------- Random (Ruby rand / rint / pick) ----------
static func rnd() -> float:
	return randf()

## Ruby rint(a, b): inclusive integer in [a, b].
static func rint(a: int, b: int) -> int:
	return randi_range(a, b)

static func pick(arr: Array) -> Variant:
	return arr[randi() % arr.size()]

# ---------- Math ----------
static func clampf2(v: float, a: float, b: float) -> float:
	return a if v < a else (b if v > b else v)

static func sgn(v: float) -> int:
	return 1 if v > 0 else (-1 if v < 0 else 0)

## Ruby integer division (floors toward negative infinity).
static func idiv(a: int, b: int) -> int:
	return floori(float(a) / float(b))

## Ruby integer modulo (result has the sign of the divisor).
static func rmod(a: int, b: int) -> int:
	return posmod(a, b) if b > 0 else -posmod(-a, -b)

## Ruby float modulo (result has the sign of the divisor).
static func fmodp(a: float, b: float) -> float:
	return fposmod(a, b) if b > 0 else -fposmod(-a, -b)

static func dist(a: Object, b: Object) -> float:
	return Vector2(a.x - b.x, a.y - b.y).length()

static func dist_xy(ax: float, ay: float, bx: float, by: float) -> float:
	return sqrt((ax - bx) * (ax - bx) + (ay - by) * (ay - by))

static func ang_to(a: Object, b: Object) -> float:
	return atan2(b.y - a.y, b.x - a.x)

static func ang_xy(ax: float, ay: float, bx: float, by: float) -> float:
	return atan2(by - ay, bx - ax)

## Shortest signed angle difference (Ruby atan2(sin d, cos d)).
static func wrap_ang(d: float) -> float:
	return atan2(sin(d), cos(d))

## Weighted pick over a Dictionary of key -> weight (insertion order, as in Ruby).
static func weighted(h: Dictionary) -> Variant:
	var t := 0.0
	for k in h:
		t += h[k]
	var x := randf() * t
	for k in h:
		x -= h[k]
		if x < 0:
			return k
	return h.keys()[0]

# ---------- Colours ----------
static var _colors := {}

## "#rrggbb" -> Color, cached.
static func c(hex: String) -> Color:
	var col = _colors.get(hex)
	if col == null:
		col = Color.html(hex)
		_colors[hex] = col
	return col

static func ca(hex: String, a: int) -> Color:
	var col := c(hex)
	return Color(col.r, col.g, col.b, a / 255.0)

static func rgba(r: int, g: int, b: int, a: int = 255) -> Color:
	return Color8(r, g, b, a)

# ---------- Text ----------
static func text_w(s: String, scale: int = 1) -> int:
	var n := s.length()
	return (n * 4 - 1) * scale if n > 0 else 0

## Damage label: exact up to 99,999, then K / M / B / T so huge numbers from
## broken builds never overflow or flood the screen (spec section 3).
static func fmt_dmg(v: float) -> String:
	if not is_finite(v):
		return "INF"
	if v < 100000:
		return str(maxi(1, roundi(v)))
	var units := ["K", "M", "B", "T"]
	var u := -1
	while v >= 1000 and u < units.size() - 1:
		v /= 1000.0
		u += 1
	return ("%.0f" % v if v >= 100 else "%.1f" % v) + units[u]

## Ruby Float#to_s-ish for the "+1.5 HP" style labels.
static func num_str(v: float) -> String:
	return str(int(v)) if v == floor(v) else str(v)
