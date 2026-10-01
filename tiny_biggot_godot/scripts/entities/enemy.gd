class_name Enemy
extends RefCounted
## A foe or a guardian (the enemy Hash of Entities.rb / Combat.rb).
## Ruby added AI keys on the fly (e[:wander], e[:orb] ...). They are all
## declared here. Values Ruby tested for nil carry a has_* flag, because 0.0
## is a legitimate value for them.

static var _next_uid := 1

var uid := 0                  # stands in for Ruby object_id in hit sets
var type := ""
var d: Dictionary             # ENEMIES / BOSSES entry
var x := 0.0
var y := 0.0
var r := 5.0
var hp := 1.0
var max_hp := 1.0
var speed := 0.0
var t := 0.0
var state: StringName = &"idle"
var st := 0.0
var vx := 0.0
var vy := 0.0
var flash := 0.0
var burn_t := 0.0
var burn_tick := 0.0
var poison := 0.0
var poison_t := 0.0
var chill_t := 0.0
var elite := false
var face := 1
var kx := 0.0
var ky := 0.0
var spawn_t := 0.0
var anim := 0.0
var hidden := false
var scale := 1.0
var gold := 0.0
var z := 0.0
var boss := ""                # BOSSES key for guardians, "" otherwise
# Status extras
var curse_t := 0.0
var bleed_t := 0.0
var bleed_tick := 0.0
var bleed_dps := 0.0
var stun_t := 0.0
var thorn_cd := 0.0
var mark_t := 0.0
var mark_v := 0.0
var shred := 0.0
var shattered := false
# New statuses (effects/statuses.gd), only applied by new content.
var shock := 0
var shock_t := 0.0
var vuln_t := 0.0
var weak_t := 0.0
# AI scratch
var dash := 0.0
var has_wander := false
var wander := Vector2.ZERO
var wt := 0.0
var ca := 0.0
var ct := 0.0
var dir := 0
var has_orb := false
var orb := 0.0
var has_cyc := false
var cyc := 0.0
var flip := false
var mini_t := 3.0             # stage-7 mini-bosses: time to the next ring burst
# Boss scratch
var cycle := 0
var sub := 0
var angle := 0.0
var beams: Array = []
var has_target := false
var target := Vector2.ZERO
var has_telegraph := false
var telegraph := 0.0
var from := Vector2.ZERO
var to := Vector2.ZERO
var slams := 0
var charges := 0
var repeat := 0

func _init() -> void:
	uid = _next_uid
	_next_uid += 1

func is_boss() -> bool:
	return type == "boss"

func targetable() -> bool:
	return spawn_t <= 0 and not hidden and hp > 0
