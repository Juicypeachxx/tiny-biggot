class_name Endless
extends RefCounted
## 22.2 THE ENDLESS DESCENT (his word, 8 Oct: "5"). A mode from the camp (THE ENDLESS STAIR beside
## the portal, then a hero): one hero goes down floor after floor and never comes back up. All twenty floors in
## order, each with its guardian, then on past the Hearth into the Ossuary again a loop deeper,
## where everything is much tougher (the game's own loops). No chapters and no endings: the fallen
## guardian leaves its hoard and the stair down, and how deep you get is the score. Your best
## depth is kept (Meta "endless_best") and shown by the stair, on the floor banner, the HUD and
## the end of the run. Expanded game only.

const NEW_BEST := 50   # embers for going deeper than ever

static func on() -> bool:
	return G.run_stats.get("endless", false)

static func best() -> int:
	return int(Meta.meta.get("endless_best", 0))

## Game.new_run, before the first floor (Game.endless_next was set by the camp's stair).
static func setup() -> void:
	G.run_stats["endless"] = true
	G.run_stats["chapter"] = 4   # every floor of the game, in order
	G.run_stats["best0"] = best()   # the record to beat

## Floors gone down so far, counting this one.
static func depth() -> int:
	return G.loop * GameData.floors().size() + G.floor_index + 1

## Game.start_floor: the depth is kept as you reach it.
static func on_floor() -> void:
	var d := depth()
	G.run_stats["depth"] = d
	var b0 := int(G.run_stats.get("best0", 0))   # (a saved run reads its numbers back as fractions)
	if b0 > 0 and d > b0 and not G.run_stats.get("new_best", false):
		G.run_stats["new_best"] = true
		G.toast("DEEPER THAN EVER BEFORE", "gold")
	if d > best():
		Meta.meta["endless_best"] = d

## The floor banner's second line.
static func banner_sub() -> String:
	return "DEPTH %d   BEST %d" % [depth(), maxi(best(), depth())]

## Game.on_boss_dead: its hoard and the stair down (no endings here).
static func guardian_down(b: Enemy) -> void:
	G.room.objects.append({ "kind": "chest", "x": 14.0 * TB.TS - 28, "y": 10.0 * TB.TS, "boss": true })
	G.room.objects.append({ "kind": "portal", "x": 14.0 * TB.TS + 28, "y": 10.0 * TB.TS })
	G.show_banner(b.d["name"] + " FALLS", "DEPTH %d. THE STAIR GOES ON DOWN" % depth())

## The portal down (Game.interact): past the last floor, round again a loop deeper.
static func next_floor() -> void:
	G.floor_index += 1
	if G.floor_index >= GameData.floors().size():
		G.floor_index = 0
		G.loop += 1
		G.run_stats["loops"] = G.loop
		G.toast("THE STAIR GOES ON. EVERYTHING HERE IS STRONGER", "red")

## Game.award_embers: the depth is the score (in place of floors and loops).
static func score(parts: Array) -> void:
	for i in range(parts.size() - 1, -1, -1):
		if parts[i][0] in ["FLOORS", "LOOPS"]:
			parts.remove_at(i)
	parts.insert(0, ["DEPTH", depth() * 6])
	if G.run_stats.get("new_best", false):
		parts.append(["NEW BEST DEPTH", NEW_BEST])
