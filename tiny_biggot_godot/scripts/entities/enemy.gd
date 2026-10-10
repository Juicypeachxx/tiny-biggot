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
var armor := 0.0               # boss armor (scripts/combat/armor.gd)
var max_armor := 0.0
var armor_stage := -1
var traits: Array = []        # elite traits (scripts/combat/elite_traits.gd)
var mend_t := 0.0
var thorn_cd := 0.0
var mark_t := 0.0
var mark_v := 0.0
var shred := 0.0
var shattered := false
# New statuses (effects/statuses.gd), only applied by new content.
var shock := 0
var shock_t := 0.0
var gloom := 0                 # 11.2: GLOOM stacks (statuses.gd)
var gloom_t := 0.0
var shatter := 0               # 47.2: SHATTER stacks (scripts/combat/shatter.gd)
var shatter_t := 0.0
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
var mini_t := 3.0
var dps_log: Array = []       # Rogues layer: training dummy damage per tick (last 3 s)
var dps := 0.0
var flee_t := 0.0              # 21.1: running away, near death (Barks.flee)
var asleep := false            # 21.5 (Lives): asleep until woken
var sleep_t := 0.0             # 21.5: how long it has slept (a fire-dog: how long it has played)
var called := false            # 21.5: it has had its chance to call for help
var provoked := false          # 21.5: a moth or a fire-dog has noticed you (or been hurt)
var rally_t := 0.0             # 21.5: running to a call, faster
var play_cd := 0.0             # 21.5: a fire-dog sits a moment after a catch
var coins := 0                 # 21.5: what a slime has swallowed
var greed_hp := 0.0            # 33 fix: a greedy slime's health before it swallowed anything
var fled := false               # 21.1: it has had its one chance to run
var ghost_hp := -1.0          # Rogues layer: trailing "damage ghost" on health bars (render only)             # stage-7 mini-bosses: time to the next ring burst
# Boss scratch
var cycle := 0
var sub := 0
var angle := 0.0
var beams: Array = []
# New foes (enemy_ai2.gd)
var guard_t := 0.0             # a deacon's shield: half damage while it lasts
var haste_t := 0.0             # a war drum: 50% faster while it lasts
var aux := 0.0
var aux2 := 0.0
var links: Array = []          # a belt feeder's links
var trail: Array = []          # a belt feeder's recent positions (its links follow them)
var lead: WeakRef = null       # a belt link's head (weak, so the two do not keep each other alive)
var has_target := false
var target := Vector2.ZERO
var has_telegraph := false
var telegraph := 0.0
var from := Vector2.ZERO
var to := Vector2.ZERO
var slams := 0
var charges := 0
var repeat := 0
# Rift bosses (rift_bosses.gd)
var phase := 1                 # 2 below half health
var shrink_t := 0.0            # shrunk by the shrink ray: small, no touch damage, squashed underfoot (oddities.gd)
var charm_t := 0.0             # tamed by the tamer's whip: fights other foes (summons.gd)
var puppet_t := 0.0            # a parasite's puppet: walks into other foes, then bursts (arsenal.gd)
var struck := 0                # hits taken while you carry triggered effects (the "fresh" condition, ROADMAP 4.7)
var over := 0.0
var stage := 1                 # a guardian's stage, 1-3 (BossAI.STAGE_PLANS; expanded game only)
var pulse_t := 0.0             # stage 3: the next desperation pulse
var break_t := 0.0             # a mini-boss or rift guardian between stages: unhurt, no AI (stages.gd)                # damage past its death (the "overkill" action, ROADMAP 4.7)
var parts: Array = []          # what it carries: an anchor, a bell, the hydra's heads
var num = null                 # 39.4: its newest damage number, which adds up the next hits (Fx.hit_text)
var puncture := 0              # 40.2 SHARP END: stacks, +4% damage taken each (might.gd)
var punct_t := 0.0
var instab := 0                # 40.2 BLUNT FORCE: at 5 it reels
var burn_n := 0                # 40.2 BLOOD AND ASH: stacks of its burn and its bleed
var bleed_n := 0
var dot_cd := 0.0              # 40.2 OPEN WOUNDS: its ailments ticked by a hit at most this often
var taunt_cd := 0.0            # 40.2 LOOMING THREAT: taunted again only after this

func _init() -> void:
	uid = _next_uid
	_next_uid += 1

func is_boss() -> bool:
	return type == "boss"

func targetable() -> bool:
	return spawn_t <= 0 and not hidden and hp > 0
