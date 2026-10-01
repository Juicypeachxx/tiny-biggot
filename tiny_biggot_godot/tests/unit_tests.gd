extends Node
## Small logic tests run headless: godot --headless --path . res://tests/unit_tests.tscn
## Reference values come from running the original Ruby code (see comments).

var _fails := 0

func _ready() -> void:
	_test_seed_rng()
	_test_ruby_math()
	print("unit tests: %s" % ("PASSED" if _fails == 0 else "%d FAILED" % _fails))
	get_tree().quit(1 if _fails > 0 else 0)

func _eq(name: String, got: Variant, want: Variant) -> void:
	if str(got) != str(want):
		_fails += 1
		print("FAIL %s: got %s want %s" % [name, got, want])

func _test_seed_rng() -> void:
	# ruby: r = SeedRng.new(123456789); 5.times.map { r.next_f.round(9) }
	var r := SeedRng.new(123456789)
	var got := []
	for i in 5:
		got.append(snappedf(r.next_f(), 0.000000001))
	_eq("seed_rng next_f", got, [0.632127719, 0.521264364, 0.291056335, 0.88943642, 0.739823954])
	# ruby: r = SeedRng.new(987654321 ^ 0x5bd1e995); 8.times.map { r.int(0,7) }
	r = SeedRng.new(987654321 ^ 0x5bd1e995)
	got = []
	for i in 8:
		got.append(r.int_range(0, 7))
	_eq("seed_rng int", got, [5, 4, 0, 6, 7, 6, 7, 6])
	# ruby: SeedRng.new(0) behaves like seed 1
	r = SeedRng.new(0)
	_eq("seed_rng zero seed", snappedf(r.next_f(), 0.00000001), 0.00006295)

func _test_ruby_math() -> void:
	_eq("idiv -7/2", TB.idiv(-7, 2), -4)        # ruby: -7 / 2 == -4
	_eq("idiv 7/2", TB.idiv(7, 2), 3)
	_eq("rmod -1%5", TB.rmod(-1, 5), 4)         # ruby: -1 % 5 == 4
	_eq("rmod 7%-3", TB.rmod(7, -3), -2)        # ruby: 7 % -3 == -2
	_eq("fmodp -0.5%3.6", snappedf(TB.fmodp(-0.5, 3.6), 0.001), 3.1)
	_eq("xp_needed 1", GameData.xp_needed(1), 17)   # ruby: (10 + 7 * (1 ** 1.35)).round
	_eq("xp_needed 5", GameData.xp_needed(5), 71)   # ruby: (10 + 7 * (5 ** 1.35)).round
