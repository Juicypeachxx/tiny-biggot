class_name Brazil
extends RefCounted
## "You're going to Brazil" (his ask, 6 Oct; an easter egg, expanded game only). Once a run, rarely,
## THE HAGGLER turns up in a fight: a junk peddler with a huge hat and a great deal of health. He
## walks after you. Kill him: a pile of gold, his gun (HAGGLER'S BARGAIN) and his hat. Let him catch
## you: "YOU'RE GOING TO BRAZIL!", and you are dragged off to BRAZIL, a dark, grimy wasteland where
## SCROUNGERS (scrap rats) nag you without end and pick your pockets. Two fights, then THE HOLY
## COW: two halves, and when it falls it rises again, harder, with new moves. Beaten, it leaves the
## COW MILKER, and the way back to your floor. (He asked for gypsies as the robbers; they are rats
## here: a real people is never the joke.) Names, story and art are this game's own.

const SPAWN_CHANCE := 0.03     # per wave, floors 1-10, once a run
const NAGS := ["SPARE A COIN?", "NICE BOOTS. MINE NOW", "GIVE GIVE GIVE", "JUST A LITTLE GOLD", "WHAT'S IN THE POCKETS?",
	"YOU LOOK RICH", "SHINY! SHINY!", "FINDERS KEEPERS", "NO REFUNDS", "PSST. HEY. HEY."]

static var _nag_t := 0.0

## spawn_wave: maybe the Haggler joins this fight.
static func maybe_spawn(room: Room, floor_index: int) -> void:
	if not GameData.rogues() or G.run_stats.get("haggler", false) or not room.theme.is_empty() or floor_index > 9:
		return
	if room.type != "combat" and room.type != "elite":
		return
	if randf() >= SPAWN_CHANCE:
		return
	G.run_stats["haggler"] = true
	var s := World.free_spot(room, G.player, 120)
	Combat.spawn_enemy("haggler", s.x, s.y)
	G.show_banner("THE HAGGLER", "HE WANTS A WORD. DON'T LET HIM CATCH YOU")

## The Haggler touched you: off to Brazil.
static func caught(e: Enemy) -> void:
	if G.state != &"play" or not G.fade.is_empty():
		return
	G.enemies.erase(e)
	G.show_banner("YOU'RE GOING TO BRAZIL!", "HE GOT YOU")
	Snd.play("portal")
	G.add_shake(6)
	var nr := World.make_room(G.floor_d, "combat", "", "s", { "theme": "brazil", "step": 0 })
	G.start_fade(func(): G.enter_room(nr))

## A scrounger's touch: it robs you (the Haggler's hat keeps your pockets shut).
static func rob(e: Enemy) -> void:
	var p := G.player
	var hat = p.gear.get("head")
	if hat != null and hat["id"] == "hagglerhat":
		return
	var n := mini(p.gold, 3 + G.floor_index)
	if n <= 0:
		return
	p.gold -= n
	Fx.float_text(p.x, p.y - 20, "-%d GOLD" % n, "gold")
	Fx.float_text(e.x, e.y - 14, "MINE!", "gold")
	e.gold += n * 0.5   # half of it comes back if you catch the thief

## The Haggler down: his hoard, his gun and his hat.
static func on_kill(e: Enemy) -> void:
	for i in 30:
		Combat.drop_pickup("coin", e.x, e.y)
	for i in 6:
		Combat.drop_pickup("gem", e.x, e.y)
	G.drop_item(Weapons.by_id("hagglerbargain"), e.x - 16, e.y + 10)
	G.drop_item(Gear.by_id("hagglerhat"), e.x + 16, e.y + 10)
	G.show_banner("THE HAGGLER FALLS", "NO MORE HAGGLING. HIS THINGS ARE YOURS")

## Every tick in Brazil: the scroungers nag.
static func tick(dt: float) -> void:
	if G.room == null or G.room.theme.get("id", "") != "brazil":
		return
	_nag_t -= dt
	if _nag_t > 0:
		return
	_nag_t = 2.2
	var them := G.enemies.filter(func(o): return o.type == "scrounger" and o.hp > 0)
	if not them.is_empty():
		var o: Enemy = them[randi() % them.size()]
		Fx.float_text(o.x, o.y - 14, NAGS[randi() % NAGS.size()], "bone")

## THE HOLY COW: when it falls the first time it rises again, harder (Combat.damage_enemy).
static func cow_rises(e: Enemy) -> bool:
	if e.boss != "holycow" or e.phase >= 3:
		return false
	e.phase = 3
	e.hp = e.max_hp
	e.state = &"pick"
	e.cycle = 0
	EBullets.clear_all()
	G.show_banner("THE HOLY COW RISES AGAIN", "IT WAS ONLY RESTING")
	G.add_shake(8)
	Snd.play("roar")
	Fx.burst(e.x, e.y, ["#f4ecd8", "#f2c94c"], 30, 130)
	return true
