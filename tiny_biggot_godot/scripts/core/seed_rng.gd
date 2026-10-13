class_name SeedRng
extends RefCounted
## Seeded xorshift RNG so a room's layout stays the same (port of Core.rb SeedRng).
##
## Ruby integers are arbitrary precision, GDScript ints are signed 64-bit.
## The state never exceeds 32 bits after masking, and the largest intermediate
## value is (2^32 - 1) << 13 < 2^45, so every step fits in 64 bits as long as we
## mask after each left shift exactly like the Ruby original.

const MASK := 0xffffffff

var s: int

func _init(seed_value: int) -> void:
	s = seed_value & MASK
	if s == 0:
		s = 1

func next_f() -> float:
	s ^= (s << 13) & MASK
	s ^= s >> 17
	s ^= (s << 5) & MASK
	s &= MASK
	return s / 4294967296.0

## Ruby SeedRng#int(a, b): inclusive.
func int_range(a: int, b: int) -> int:
	return a + floori(next_f() * (b - a + 1))

func pick(arr: Array) -> Variant:
	return arr[floori(next_f() * arr.size())]
