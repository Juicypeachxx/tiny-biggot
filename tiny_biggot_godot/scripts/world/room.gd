class_name Room
extends RefCounted
## One room of a floor (the `room` Hash of World.rb / Game.rb).
## Ruby `nil` strings (reward, entrance) are stored as "".

var type := ""
var reward := ""
var depth := 0
var doors := {}          # dir -> true
var exits := {}          # dir -> { "type": String, "reward": String }
var secret_dirs := {}    # dir -> true (cracked wall, bomb it open)
var sealed := {}         # dir -> true (locked vault door)
var entrance := ""
var cleared := false
var seed_value := 0
var grid := PackedByteArray()   # ROWS * COLS tiles, index r * COLS + c
var crate_hp := {}       # Vector2i(c, r) -> float
var layout := 0
var objects: Array = []          # room objects (Dictionaries)
var objects_ready := false       # Ruby: room[:objects] set
var pickups: Array = []          # pickups waiting in the room before entry
var exits_open := false
var waves_left := 0
# Stage 7 biome hazards (scripts/world/hazards.gd); empty on the original floors.
var hazards: Array = []
var strike := ""
var strike_t := 0.0
var marks: Array = []

func tile(c: int, r: int) -> int:
	if r < 0 or c < 0 or r >= TB.ROWS or c >= TB.COLS:
		return World.T_WALL
	return grid[r * TB.COLS + c]

func set_tile(c: int, r: int, t: int) -> void:
	grid[r * TB.COLS + c] = t
