class_name KoiScenes
extends RefCounted
## V2, THE KOI GARDEN (his word, 10 Nov, on the first try: "all the positioning is random and
## meaningless"): every fight room of the garden is a planned scene, not props thrown on a
## layout. A scene is a map of the room's inside (26 x 15 tiles), mirrored left to right for half
## the rooms. World.build_room lays its tiles; JapanLook draws each thing where the map has it.
##   .  open water          ~  a deep pool (World.T_VOID: walkers go round, flyers and shots cross)
##   =  a bridge (floor)    o  a stepping stone (floor)    *  the middle of a lily colony (floor)
##   X  a post of the gate (solid; the gate stands over the pair)
##   L stone lantern  P post lamp  B bamboo  S stacked stones  O bonsai rock  W water basin
##   H wayside shrine  T torii      (all solid)
const SCENES := [
	# gate
	["BB......................BB", "B........................B", "..........................", "....S................O....", "..........................", ".......*..........*.......", "..........................", "...........X..X...........", "..........................", "..........L....L..........", "............oo............", "..........................", "....W.......oo.......S....", "B........................B", "BB..........oo..........BB"],
	# avenue
	["..........................", "..B....................B..", ".BB....................BB.", "..........................", "....T....T....T....T......", "..........................", "......................L...", ".o..o..o..o..o..o..o.H....", "......................L...", "..........................", "....T....T....T....T......", "..........................", ".SS....................*..", "..S..*....................", ".........................."],
	# island
	["..........................", "..........................", "...*..................*...", "........~~~~~~~~~~........", ".......~~~~~~~~~~~~.......", ".......~~~......~~~.......", ".......~~..O..H..~~.......", ".....====........====.....", ".......~~........~~.......", ".......~~~......~~~.......", ".......~~~~~..~~~~~.......", "........~~~~..~~~~........", "...L................L.....", "..........................", ".........................."],
	# grove
	["..........................", "..BBB.................S...", "..BB......................", "..B.........*.............", "..................BB......", ".................BBB......", "......W...........B.......", "..........................", ".......BB.................", "......BBB..........L......", ".......B..................", "..................*.......", "...S.................BBB..", "......................BB..", ".........................."],
	# pool
	["..........................", "..........................", "......L............L......", ".........~~~~~~~~.........", "........~~~~~~~~~~........", ".......~~~~~~~~~~~~.......", ".......============.......", ".......============.......", ".......~~~~~~~~~~~~.......", "........~~~~~~~~~~........", ".........~~~~~~~~.........", "......L............L......", "..*....................*..", "..........................", ".........................."],
	# stones
	["..........................", ".B......................B.", "..........................", "..........o..o............", "........o......o..........", "..........................", ".......o...SS...o.....L...", "...........OS.............", ".......o........o.....L...", "..........................", "........o......o..........", "..........o..o............", "...*......................", ".B......................B.", ".........................."],
]
const PROPS := { "L": "koi_lantern", "P": "koi_postlamp", "B": "koi_bamboo", "S": "koi_stones", "O": "koi_bonsai", "W": "koi_basin",
	"H": "koi_shrine", "T": "koi_torii" }
const LAYOUT0 := 400     # room.layout of a scene: LAYOUT0 + 2 * scene + (1 when mirrored)

## Until the garden is a floor of its own it is shown with the test option --koi.
static func on(room: Room) -> bool:
	return DebugArgs.has("koi") and room.theme.is_empty() and room.kit == "" and room.champion == ""

## Picks the room's scene and lays its tiles; returns its layout number.
static func lay(room: Room, rng: SeedRng) -> int:
	var k := rng.int_range(0, SCENES.size() - 1)
	room.layout = LAYOUT0 + 2 * k + (1 if rng.next_f() < 0.5 else 0)
	for r in range(TB.IY0, TB.IY0 + TB.IH):
		for c in range(TB.IX0, TB.IX0 + TB.IW):
			var ch := cell(room, c, r)
			if ch == "~":
				room.set_tile(c, r, World.T_VOID)
			elif ch == "X" or PROPS.has(ch):
				room.set_tile(c, r, World.T_PILLAR)
	return room.layout

static func is_scene(room: Room) -> bool:
	return room.layout >= LAYOUT0 and room.layout < LAYOUT0 + 2 * SCENES.size()

## What the scene has on this tile ("." outside a scene or the room's inside).
static func cell(room: Room, c: int, r: int) -> String:
	if not is_scene(room) or c < TB.IX0 or c >= TB.IX0 + TB.IW or r < TB.IY0 or r >= TB.IY0 + TB.IH:
		return "."
	var x := c - TB.IX0
	if (room.layout - LAYOUT0) % 2 == 1:
		x = TB.IW - 1 - x
	return SCENES[(room.layout - LAYOUT0) / 2][r - TB.IY0][x]
