class_name Daily
extends RefCounted
## 18.1 THE DAILY TRIAL (his word, 7 Oct): one fixed run a day, from the standing stone in the camp.
## The date chooses the run's seed, its hero (any hero, even one not yet unlocked) and its rule.
## A score at the end (floors, foes, guardians, gold, a win); the day's best is kept
## (Meta.meta["daily_best"]: date -> score) and shown on the stone. Expanded game only.

## id: [name, what it does]
const MODS := {
	"powder": ["POWDER DAY", "KEGS IN EVERY FIGHT. THEIR BLASTS HIT TWICE AS HARD"],
	"elite": ["ELITE HOUR", "HALF OF ALL FOES ARE ELITES"],
	"glass": ["GLASS HEROES", "YOU DEAL DOUBLE DAMAGE BUT HAVE 2 FEWER HEARTS"],
	"gold": ["GOLD RUSH", "DOUBLE GOLD. SHOPS COST HALF AGAIN AS MUCH"],
	"haste": ["HASTE", "YOU AND EVERY FOE MOVE 30% FASTER"],
	"giants": ["BIG GAME", "GUARDIANS HAVE 50% MORE HEALTH AND DROP 2 MORE RELICS"],
}
const EMBERS := 50

static var _prev_hero := -1
static var starting := false   # 19.2: true while start() builds the run (the camp's meal waits)

## Today as a number, YYYYMMDD (DebugArgs --day=N for tests).
static func today() -> int:
	if DebugArgs.has("day"):
		return DebugArgs.get_int("day")
	var d := Time.get_date_dict_from_system()
	return int(d["year"]) * 10000 + int(d["month"]) * 100 + int(d["day"])

## 19.2 the seer: the day after today, as YYYYMMDD.
static func tomorrow() -> int:
	var d := today()
	var u := Time.get_unix_time_from_datetime_dict({ "year": d / 10000, "month": (d / 100) % 100, "day": d % 100, "hour": 12 }) + 86400
	var t := Time.get_datetime_dict_from_unix_time(u)
	return int(t["year"]) * 10000 + int(t["month"]) * 100 + int(t["day"])

static func mod_for(day: int) -> String:
	return MODS.keys()[day % MODS.size()]

static func hero_for(day: int) -> int:
	return (day * 7 + day / 100) % GameData.heroes().size()

static func mod() -> String:
	return G.run_stats.get("daily", "")

static func is_on(id: String) -> bool:
	return G.run_stats.get("daily", "") == id

static func best(day: int) -> int:
	var b: Dictionary = Meta.meta["daily_best"] if Meta.meta.get("daily_best") is Dictionary else {}
	return int(b.get(str(day), 0))

## The stone in the camp: today's run.
static func start(day: int = -1) -> void:
	if day < 0:
		day = today()
	var m := mod_for(day)
	_prev_hero = G.hero_index
	G.hero_index = hero_for(day)
	seed(day)
	starting = true
	G.new_run()
	starting = false
	G.run_stats["daily"] = m
	G.run_stats["daily_day"] = day
	var p := G.player
	match m:
		"glass":
			p.dmg *= 2.0
			p.max_hp = maxi(2, p.max_hp - 4)
			p.hp = mini(p.hp, p.max_hp)
		"gold":
			p.gold_mult *= 2.0
		"haste":
			p.speed *= 1.3
	G.show_banner("THE DAILY TRIAL: " + MODS[m][0], MODS[m][1])

## A run ends (G.award_embers): the score, the day's best, the embers.
static func on_end(win: bool, parts: Array) -> void:
	if not G.run_stats.has("daily"):
		return
	var r := G.run_stats
	var score := G.floor_index * 1000 + int(r["kills"]) * 10 + int(r["bosses"]) * 500 + int(r.get("gold", 0)) + (5000 if win else 0)
	r["daily_score"] = score
	if not (Meta.meta.get("daily_best") is Dictionary):
		Meta.meta["daily_best"] = {}
	var key := str(r.get("daily_day", today()))
	if score > int(Meta.meta["daily_best"].get(key, 0)):
		Meta.meta["daily_best"][key] = score
		r["daily_record"] = true
	parts.append(["DAILY TRIAL", EMBERS])
	if _prev_hero >= 0:
		G.hero_index = _prev_hero
		_prev_hero = -1

static func prompt() -> Array:
	var day := today()
	var m := mod_for(day)
	var h: Dictionary = GameData.heroes()[hero_for(day)]
	var b := best(day)
	return ["THE DAILY TRIAL: " + MODS[m][0], h["name"] + ". " + MODS[m][1] + (". BEST TODAY %d" % b if b > 0 else ""), "BEGIN"]
