class_name PBullet
extends RefCounted
## A player shot (the pbullet Hash of Combat.rb / 04b_items.rb).
## Shots carry many per-shot flags, so they are typed objects rather than
## packed arrays, recycled through a free list (Combat.new_pbullet) so a long
## fight allocates nothing after warm-up.

const BACK_NONE := 0     # Ruby back: nil   (not a boomerang)
const BACK_OUT := 1      # Ruby back: false (boomerang flying out)
const BACK_RETURN := 2   # Ruby back: true  (boomerang coming home)

var x := 0.0
var y := 0.0
var vx := 0.0
var vy := 0.0
var dmg := 0.0
var life := 0.0
var max_life := 0.0
var r := 2.5
var pierce := 0
var bounce := 0
var homing := 0.0
var kind := "bolt"
var hit := {}            # enemy uid -> true
var rot := 0.0
var age := 0.0
var ric := 0
var back := BACK_NONE
var crit := false
var bloom := false
var poison_add := 0
var split := 0.0
var grow := 0.0
var accel := 0.0
var icon := ""
var tag := ""
var nohit := false
var pulse_t := 0.0
var linger := 0.0
var hovering := false
var arm := 0.0
var has_mv := false
var mvx := 0.0
var mvy := 0.0
var chill := false
var tgt: Enemy = null    # Rogues layer: the foe a homing shot is steering toward
var tgt_n := 0           # ticks until it looks for the nearest foe again
var dk := -1             # drawing class, worked out by the painter on first draw (ShotBatch); -1 = not yet
var gk := 0              # set with dk: the shot's glow (1 hex, boomer, rail; 2 pulse; 0 none)
var ds := -1             # set with dk: the shot's new-look rule (ShotBatch.specs), -1 in the old look
var dw := -1             # set with dk: the rule of the whirl drawn under a spinning weapon, or -1
var own := false         # fired by the hero's weapon itself (not a proc or a wisp): a blow for tempo and rally
var merged: PBullet = null   # set on a stand-in: the shot flying that this one merged into (Combat._merge_shot)
var cast := false        # 34.1: made by a free cast from the spell slot (lucky.gd): it never casts again

var owner_i: int = Coop.actor   # (Windows co-op: the hero who fired it)

func reset() -> void:
	owner_i = Coop.actor
	x = 0.0; y = 0.0; vx = 0.0; vy = 0.0; dmg = 0.0; life = 0.0; max_life = 0.0; r = 2.5
	pierce = 0; bounce = 0; homing = 0.0; kind = "bolt"; hit = {}; rot = 0.0; age = 0.0; ric = 0
	back = BACK_NONE; crit = false; bloom = false; poison_add = 0; split = 0.0; grow = 0.0; accel = 0.0
	icon = ""; tag = ""; nohit = false; pulse_t = 0.0; linger = 0.0; hovering = false; arm = 0.0
	has_mv = false; mvx = 0.0; mvy = 0.0; chill = false; dk = -1; tgt = null; tgt_n = 0; own = false; merged = null; cast = false

## Ruby b.dup (the hit set is copied separately by the caller, as in Ruby).
func copy_from(b: PBullet) -> void:
	x = b.x; y = b.y; vx = b.vx; vy = b.vy; dmg = b.dmg; life = b.life; max_life = b.max_life; r = b.r
	pierce = b.pierce; bounce = b.bounce; homing = b.homing; kind = b.kind; hit = b.hit; rot = b.rot
	age = b.age; ric = b.ric; back = b.back; crit = b.crit; bloom = b.bloom; poison_add = b.poison_add
	split = b.split; grow = b.grow; accel = b.accel; icon = b.icon; tag = b.tag; nohit = b.nohit
	pulse_t = b.pulse_t; linger = b.linger; hovering = b.hovering; arm = b.arm; has_mv = b.has_mv
	mvx = b.mvx; mvy = b.mvy; chill = b.chill; dk = -1; tgt = null; tgt_n = 0; own = b.own; cast = b.cast
