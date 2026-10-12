class_name Barks
extends RefCounted
## 21.1 VOICES (his word, 8 Oct: "make game more alive"): speech bubbles over heads. Expanded game
## only. The hero speaks at big moments (a new floor, low health, a legendary, a guardian down, a
## level, a whole set, rising again, a shop, a run of kills); foes bark now and then (elites taunt
## when they appear, shushers SHH, every guardian opens its fight with a line); an ordinary foe
## near death may turn and run; the camp's people greet you by your hero's name and remember your
## last run (Meta.meta["last_run"], written by G.award_embers).
## Drawing only, with dice of its own: no line ever moves a run's random numbers. Fleeing is the
## one thing here that changes play, and it is chosen by the foe's number, not by dice.

const MAX := 6          # bubbles at once
const LIFE := 2.4       # seconds a line stays up
const HERO_GAP := 6.0   # seconds between two lines of the hero's (big moments jump the queue)
const FOE_GAP := 2.5    # seconds between two foe barks in a room
const FLEE_AT := 0.2    # an ordinary foe below this share of its health may run
const FLEE_TIME := 1.8

static var bubbles: Array = []   # { who: Object or null, x, y, text, t, max, col }
static var _rng := RandomNumberGenerator.new()
static var _hero_t := -99.0
static var _foe_t := 0.0
static var _tick := 0.0
static var _boss_uid := -1
static var _boss_wait := 0.0
static var _taunts := 0
static var _kills := []          # times of recent kills (a run of kills)
static var _kills0 := 0
static var _greeted := {}        # camp: who has greeted you this visit

## Lines everyone can say. {HERO} becomes the hero's name.
const HERO := {
	"floor": ["ONWARD.", "DEEPER IT IS.", "HERE WE GO AGAIN.", "SMELLS LIKE TROUBLE.", "NEW FLOOR, NEW TEETH."],
	"hurt": ["THAT HURT.", "NOT YET...", "STILL STANDING.", "I NEED A POTION.", "OW. OW. OW."],
	"legend": ["NOW WE'RE TALKING.", "OH, THAT'S PRETTY.", "LEGENDARY!", "MINE NOW."],
	"boss": ["WHO'S NEXT?", "THAT WAS A BIG ONE.", "AND STAY DOWN.", "ANOTHER ONE FALLS."],
	"level": ["STRONGER.", "I FEEL IT.", "MORE!"],
	"set": ["THE WHOLE SET!", "IT FITS PERFECTLY."],
	"streak": ["TOO EASY.", "NEXT!", "IS THAT ALL?"],
	"revive": ["NOT TODAY.", "BACK AGAIN!", "DEATH CAN WAIT."],
	"shop": ["LET'S SEE THE WARES.", "SHINY THINGS..."],
}
## A hero's own voice for some moments (the rest come from HERO).
const VOICE := {
	"hexer": { "boss": ["HEHEHE. HEXED."], "hurt": ["YOU'LL PAY FOR THAT."], "floor": ["THE SPIRITS ARE RESTLESS."] },
	"poacher": { "legend": ["WHAT A CATCH."], "boss": ["BAGGED IT."], "floor": ["FRESH TRACKS."] },
	"brute": { "boss": ["HAH! WEAK!"], "hurt": ["JUST A SCRATCH."], "streak": ["WHO WANTS MORE?"] },
	"gravedigger": { "floor": ["FRESH EARTH BELOW."], "boss": ["ANOTHER ONE FOR THE PIT."] },
	"alchemist": { "legend": ["FASCINATING..."], "boss": ["AN INTERESTING REACTION."] },
	"warden": { "floor": ["LIGHT THE WAY."], "hurt": ["THE LAMP STILL BURNS."] },
	"gaolbird": { "floor": ["NO BARS CAN HOLD ME."], "boss": ["FREE AS A BIRD."] },
	"banehunter": { "boss": ["THE BOUNTY IS MINE."], "floor": ["THE HUNT GOES ON."] },
	"oathbreaker": { "boss": ["NO MERCY. NO OATHS."], "hurt": ["I HAVE KNOWN WORSE."] },
	"wayfarer": { "floor": ["ONE MORE ROAD."], "boss": ["THE ROAD GOES ON."] },
	"racketeer": { "legend": ["THAT'S WORTH A FORTUNE."], "boss": ["PAY UP."] },
	"condemned": { "revive": ["THEY CAN'T KEEP ME DEAD."], "floor": ["SAME CHAINS, NEW CELL."] },
	"cartomancer": { "legend": ["THE CARDS FORETOLD IT."], "boss": ["THE TOWER FALLS."] },
	"sellsword": { "boss": ["THAT'S ANOTHER PURSE."], "floor": ["FOR COIN AND GLORY."] },
	"beekeeper": { "boss": ["THE HIVE THANKS YOU."], "hurt": ["BZZT."] },
	"tinkerer": { "legend": ["OOH, SPARE PARTS!"], "boss": ["DISMANTLED."] },
	"boneweaver": { "boss": ["YOUR BONES ARE MINE NOW."], "floor": ["THE DEAD WHISPER HERE."] },
	"mirrorknight": { "boss": ["SEE YOURSELF FALL."], "hurt": ["A CRACK IN THE GLASS."] },
	"plaguesaint": { "boss": ["BLESSED ROT."], "floor": ["BREATHE DEEP."] },
	"frostwitch": { "boss": ["FROZEN SOLID."], "floor": ["A CHILL IN THE AIR."] },
	"demolitionist": { "boss": ["KABOOM."], "streak": ["MORE POWDER!"] },
	"executioner": { "boss": ["THE SENTENCE IS CARRIED OUT."], "streak": ["NEXT HEAD."] },
	"pilgrim": { "floor": ["THE PATH CONTINUES."], "revive": ["NOT MY TIME."] },
	"beastmaster": { "boss": ["GOOD HUNT, FRIENDS."], "floor": ["I SMELL BEASTS."] },
	"clockmaker": { "floor": ["RIGHT ON TIME."], "boss": ["YOUR CLOCK HAS STOPPED."] },
	"minstrel": { "boss": ["AND THE CROWD GOES WILD!"], "level": ["A NEW VERSE!"] },
	"jester": { "boss": ["THE JOKE'S ON YOU!"], "hurt": ["NOT FUNNY."] },
	"berserker": { "streak": ["MORE! MORE!"], "hurt": ["PAIN IS FUEL."] },
	"forsaken": { "legend": ["FINALLY, SOME LUCK."], "hurt": ["NOTHING NEW."] },
	"inkling": { "boss": ["SPLAT."], "floor": ["NEW PAGE."] },
}
## What the hero says on arriving on a floor (a few floors have their own line).
const FLOOR_LINES := {
	"THE OSSUARY": ["SO MANY BONES.", "SOMEONE KEEPS THESE TIDY."], "MIREWOOD GROTTO": ["MIND THE MUSHROOMS.", "IT SMELLS GREEN."],
	"THE SUNKEN ARCHIVE": ["WET BOOKS. LOVELY."], "THE CINDERFORGE": ["HOT. VERY HOT."], "RIMEFROST VAULT": ["I CAN SEE MY BREATH."],
	"THE HOLLOW THRONE": ["THE REGENT IS NEAR."], "RAINMARSH HAMLET": ["IT NEVER STOPS RAINING."], "ASHEN WARFRONT": ["A WAR NOBODY WON."],
	"FROSTPEAK MONASTERY": ["QUIET MONKS. SHARP KNIVES."], "NIGHTSPIRE ROOFTOPS": ["DON'T LOOK DOWN."], "THE ECLIPSE": ["THE SUN WENT OUT."],
	"THE INKWELL": ["EVERYTHING IS INK."], "THE BINDERY": ["STITCHED TOGETHER..."], "THE QUILL SPIRE": ["THE AUTHOR WAITS UP THERE."],
	"THE GLOSSARY": ["SO MANY WORDS."], "THE FOOTNOTES": ["READ THE SMALL PRINT."], "THE COVER": ["THE OUTSIDE OF THE STORY."],
	"THE STACKS": ["SHELVES FOREVER."], "THE READING ROOM": ["SHH... SOMEONE'S READING."], "THE HEARTH": ["THEY BURN THE BOOKS HERE."],
}
## Every guardian opens its fight with a line.
const BOSS_LINES := {
	"colossus": "BONES... FOR THE PILE.", "sporemother": "BREATHE DEEP, LITTLE ONE.", "librarian": "OVERDUE. ALL OF YOU.",
	"tyrant": "KNEEL BEFORE THE FORGE!", "rimewarden": "COLD... SO COLD.", "regent": "YOU DARE APPROACH THE THRONE?",
	"bogmatriarch": "SINK, CHILD. SINK.", "ashwarlord": "THE WAR NEVER ENDS.", "frozenabbot": "SILENCE IS A VIRTUE.",
	"crowking": "MY CROWS HAVE WATCHED YOU.", "umbralsun": "THE LIGHT ENDS HERE.", "holycow": "MOOOOOO.",
	"judge": "THE VERDICT IS IN.", "cinderking": "BURN WITH ME.", "unwritten": "...", "stormcrown": "FEEL THE STORM.",
	"bilgehydra": "MORE HEADS THAN YOU.", "brassorgan": "LET THE MUSIC PLAY!", "greatengine": "TICK. TOCK. CRUSH.",
	"glacialmaw": "I HUNGER.", "inkleviathan": "DROWN IN INK.", "thebinder": "I WILL BIND YOU SHUT.",
	"author": "THE END IS MINE TO WRITE.", "redactor": "[REDACTED].", "lexicon": "WORDS. WORDS. WORDS.",
	"erratum": "I AM THE MISTAKE.", "reader": "I HAVE READ THIS PART BEFORE.", "shelver": "OUT OF ORDER!",
	"hush": "...", "critic": "I HAVE READ BETTER.", "admiral": "ALL HANDS ON DECK!", "golemking": "STONE ENDURES.",
	"archmage": "A LESSON, THEN.", "phoenix": "I RISE.", "wyrm": "YOU ARE SMALL.", "chainfiend": "THE CHAINS HUNGER.",
	"seraph": "BE JUDGED.", "rex": "WOOF.",
	"braysalot": "HEE-HAW! I AM THE HERO OF THIS STORY!", "scalesworth": "VOTE FOR ME. OR ELSE.",   # 55 THE LAST LAUGH
	"prophet": "THE END IS NIGH! I TOLD YOU ALL!", "chonk": "YOU ARE IN MY SPOT.",
}
## Foes that bark now and then while they fight you.
const FOE_BARKS := {
	"skeleton": ["*CLATTER*"], "cultist": ["FOR THE REGENT!"], "imp": ["HEHEHE!"], "ghost": ["BOO..."], "knight": ["HALT!"],
	"goblin": ["MINE! ALL MINE!"], "bogling": ["BLUB."], "lancer": ["CHARGE!"], "warpriest": ["REPENT!"], "monk": ["HMMM..."],
	"gunman": ["HANDS UP!"], "crow": ["CAW!"], "inmate": ["FREEDOM!"], "jailer": ["BACK IN YOUR CELL!"], "thug": ["OI!"],
	"copper": ["STOP RIGHT THERE!"], "letterling": ["A!", "Q?", "Z!"], "commaimp": [",,,"], "asterisk": ["*"],
	"citation": ["SEE ABOVE."], "shusher": ["SHH!", "SHHHH!", "QUIET!"], "cardsprite": ["SEE INDEX.", "FILED!"],
	"spectacle": ["I SEE YOU."], "pokerknight": ["STOKE THE FIRE!"], "firedog": ["WOOF!", "GRRR."], "mothling": ["FLUTTER."],
	"sootling": ["COUGH!"], "bookend": ["..."], "scribe": ["NOTED."], "inkmage": ["INK AND BONE!"],
	"ponysquire": ["NEIGH!", "FOR SIR BRAYSALOT!"], "lobbyist": ["SIGN HERE.", "A SMALL DONATION?"], "intern": ["COFFEE?", "IS THIS PAID?"],
	"believer": ["FLEX!", "BEHOLD THESE ARMS!", "IT IS NIGH, BRO."], "kitten": ["MEW!", "MEW?", "HSSS!"],
}
const ELITE_TAUNTS := ["YOU'RE MINE!", "FRESH MEAT.", "COME CLOSER.", "I'VE BEEN WAITING.", "YOU LOOK TIRED."]
const FLEE_LINES := ["RUN!", "NOT LIKE THIS!", "HELP!", "I YIELD!", "MOMMY!"]
## The camp's people: a greeting each, then a word about your last run (the archivist).
const GREET := {
	"n_archivist": ["WELCOME BACK, {HERO}."], "e_angler": ["THEY'RE BITING TODAY, {HERO}."], "c_cook": ["HUNGRY, {HERO}?"],
	"c_build": ["MORE TO BUILD, {HERO}?"], "v_peddler": ["{HERO}! I HAVE JUST THE THING."], "v_bard": ["A SONG FOR {HERO}!"],
	"v_seer": ["I SAW YOU COMING, {HERO}."], "v_monger": ["FRESH FISH, {HERO}?"], "v_gambler": ["FEELING LUCKY, {HERO}?"],
	"v_tinker": ["MIND THE SPRINGS, {HERO}."],
}

static func on() -> bool:
	return GameData.rogues()

static func _name() -> String:
	return G.player.hero["name"] if G.player != null else "STRANGER"

static func _pick(lines: Array) -> String:
	return lines[_rng.randi_range(0, lines.size() - 1)] if not lines.is_empty() else ""

## A line over someone's head (who: a Player, an Enemy or a room object Dictionary).
static func say(who: Variant, text: String, col: String = "white", secs: float = LIFE) -> void:
	if not on() or text == "":
		return
	for b in bubbles:
		if is_same(b["who"], who):
			bubbles.erase(b)
			break
	if bubbles.size() >= MAX:
		bubbles.pop_front()
	bubbles.append({ "who": who, "text": text.replace("{HERO}", _name()), "t": 0.0, "max": secs, "col": col })

## The hero speaks (event: a key of HERO). Big moments come through even right after another line.
static func hero(event: String, big: bool = false) -> void:
	if not on() or G.player == null or G.state != &"play" and not big:
		return
	if not big and G.time - _hero_t < HERO_GAP:
		return
	var lines: Array = []
	var own: Dictionary = VOICE.get(G.player.hero["id"], {})
	if own.has(event) and _rng.randf() < 0.6:
		lines = own[event]
	elif event == "floor" and G.room != null and G.room.theme.is_empty():
		var fname: String = GameData.floors()[clampi(G.floor_index, 0, GameData.floors().size() - 1)]["name"]
		lines = FLOOR_LINES.get(fname, HERO["floor"])
	else:
		lines = HERO.get(event, [])
	if lines.is_empty():
		return
	_hero_t = G.time
	say(G.player, _pick(lines), "gold" if big else "white")

static func reset() -> void:
	bubbles.clear()
	_foe_t = 0.0
	_taunts = 0
	_boss_uid = -1

# ---------- Every tick of play ----------
static func update(dt: float) -> void:
	if not on():
		return
	for i in range(bubbles.size() - 1, -1, -1):
		var b: Dictionary = bubbles[i]
		b["t"] += dt
		var w = b["who"]
		var gone: bool = w is Enemy and ((w as Enemy).hp <= 0 or not G.enemies.has(w))
		if b["t"] >= b["max"] or gone:
			bubbles.remove_at(i)
	if G.state != &"play" or G.player == null or G.room == null:
		return
	_foe_t -= dt
	_tick -= dt
	_streak()
	_boss_line(dt)
	if _tick > 0.0:
		return
	_tick = 0.5   # foes look for something to say twice a second
	if _foe_t > 0.0:
		return
	var p := G.player
	for e in G.enemies:
		if e.hp <= 0 or e.spawn_t > 0 or e.is_boss() or e.hidden or e.asleep or TB.dist(e, p) > 170.0:
			continue
		if e.elite and _taunts < 2 and not e.get_meta("taunted", false):
			e.set_meta("taunted", true)
			_taunts += 1
			say(e, _pick(ELITE_TAUNTS), "red")
			_foe_t = FOE_GAP
			return
		if FOE_BARKS.has(e.type) and _rng.randf() < 0.06:
			say(e, _pick(FOE_BARKS[e.type]), "tan", 1.6)
			_foe_t = FOE_GAP
			return

## A guardian, once it is in the room and awake, opens with its line.
static func _boss_line(dt: float) -> void:
	var b: Enemy = G.boss
	if b == null or b.hp <= 0 or b.uid == _boss_uid:
		return
	if b.spawn_t > 0:
		return
	_boss_wait += dt
	if _boss_wait < 0.8:
		return
	_boss_wait = 0.0
	_boss_uid = b.uid
	say(b, BOSS_LINES.get(b.boss, "YOU WILL GO NO FURTHER."), "red", 3.0)

## A run of kills: six in three seconds.
static func _streak() -> void:
	var k: int = G.run_stats.get("kills", 0)
	if k < _kills0:
		_kills0 = k
	while _kills0 < k:
		_kills0 += 1
		_kills.append(G.time)
	while not _kills.is_empty() and G.time - _kills[0] > 3.0:
		_kills.pop_front()
	if _kills.size() >= 6:
		_kills.clear()
		hero("streak")

# ---------- A foe near death may run (the one part that changes play) ----------
## Called for each active foe before its own AI (Combat.update_enemies). True: it is running.
static func flee(e: Enemy, dt: float, p: Player) -> bool:
	if not on():
		return false
	if e.flee_t > 0.0:
		e.flee_t -= dt
		var a := TB.ang_to(p, e)
		World.move_body(G.room, e, cos(a) * e.speed * 1.3 * dt, sin(a) * e.speed * 1.3 * dt,
			World.M_FLYER if e.d.get("fly", false) else World.M_WALKER)
		e.face = 1 if cos(a) > 0 else -1
		return true
	if e.fled or e.hp > e.max_hp * FLEE_AT or e.elite or e.d.get("mini", false) or e.d.get("champion", false) \
			or e.speed <= 0 or e.type == "dummy" or e.charm_t > 0 or e.puppet_t > 0:
		return false
	e.fled = true
	if e.uid % 3 != 0:   # one foe in three runs (by its number: no dice)
		return false
	e.flee_t = FLEE_TIME
	say(e, _pick(FLEE_LINES), "white", 1.4)
	return true

# ---------- The camp: greetings ----------
static func camp_tick() -> void:
	if not on() or G.player == null or G.room == null:
		return
	var p := G.player
	for o in G.room.objects:
		var k: String = o["kind"]
		if not GREET.has(k) or _greeted.has(k):
			continue
		if TB.dist_xy(p.x, p.y, o["x"], o["y"]) > 70.0:   # before the prompt shows (24 px)
			continue
		_greeted[k] = true
		var line: String = _pick(GREET[k])
		if k == "n_archivist" or (k == "v_seer" and _rng.randf() < 0.5):
			line = last_run_line()
		say(o, line, "bone", 3.2)
		return

static func camp_reset() -> void:
	_greeted.clear()
	bubbles.clear()

## What the archivist (or the seer) says about your last run.
static func last_run_line() -> String:
	var r: Dictionary = Meta.meta["last_run"] if Meta.meta.get("last_run") is Dictionary else {}
	if r.is_empty():
		return "WELCOME, {HERO}. YOUR STORY STARTS HERE."
	if r.get("win", false):
		return "I HEARD! %s. WELL DONE, %s." % [r.get("ending", "A WIN"), r.get("hero", "{HERO}")]
	return "FLOOR %d, AND %s. IT HAPPENS, %s." % [int(r.get("floor", 1)), str(r.get("by", "THE CRYPT")).to_upper(), r.get("hero", "{HERO}")]

## G.award_embers: remember how the run ended, for the camp.
static func remember(win: bool) -> void:
	if not on() or G.player == null or G.run_stats.get("camp", false):
		return
	var r := G.run_stats
	var ending := "THE THRONE"
	for k in [["critic", "THE BOOK IS KEPT"], ["reader", "THE LAST PAGE"], ["redactor", "NOTHING ERASED"], ["author", "THE AUTHOR FELL"],
			["unwritten", "THE UNWRITTEN"]]:
		if r.get(k[0], false):
			ending = k[1]
			break
	Meta.meta["last_run"] = { "hero": G.player.hero["name"], "floor": G.floor_index + 1, "by": G.death_by, "win": win, "ending": ending }

# ---------- Drawing (the text layer) ----------
static func draw(ci: CanvasItem) -> void:
	for b in bubbles:
		var w = b["who"]
		var x := 0.0
		var y := 0.0
		var h := 18.0
		if w is Player:
			x = (w as Player).x
			y = (w as Player).y
		elif w is Enemy:
			var e: Enemy = w
			x = e.x
			y = e.y - e.z
			h = 10.0 + e.r * 1.6 * float(e.d.get("scale", 1.0)) + (14.0 if e.is_boss() else 0.0)
		elif w is Dictionary:
			x = w["x"]
			y = w["y"]
			h = 24.0
		else:
			continue
		var text: String = b["text"]
		var tw := text.length() * 4 - 1
		var bw := tw + 8
		var bx := clampf(roundf(x - bw / 2.0), 2.0, TB.SW - bw - 2.0)
		var by := roundf(y - h - 14.0)
		if by < 34.0:
			by = roundf(y + 12.0)   # no room above (the HUD): under the speaker instead
		var t: float = b["t"]
		var a := clampf(t / 0.12, 0.0, 1.0) * clampf((b["max"] - t) / 0.35, 0.0, 1.0)
		ci.draw_rect(Rect2(bx - 1, by - 1, bw + 2, 11), Color(0.95, 0.92, 0.85, 0.85 * a))
		ci.draw_rect(Rect2(bx, by, bw, 9), Color(0.1, 0.08, 0.13, 0.92 * a))
		var tx := clampf(roundf(x), bx + 3.0, bx + bw - 4.0)
		var ty := by + 10.0 if by < y else by - 2.0
		if by < y:
			ci.draw_colored_polygon(PackedVector2Array([Vector2(tx - 2, by + 10), Vector2(tx + 2, by + 10), Vector2(tx, by + 13)]), Color(0.95, 0.92, 0.85, 0.85 * a))
		else:
			ci.draw_colored_polygon(PackedVector2Array([Vector2(tx - 2, by - 1), Vector2(tx + 2, by - 1), Vector2(tx, ty - 2)]), Color(0.95, 0.92, 0.85, 0.85 * a))
		Gfx.text(ci, text, bx + 4, by + 2, b["col"], 1, 0.0, false, a)
