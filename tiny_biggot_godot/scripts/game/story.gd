class_name Story
extends RefCounted
## Stage 12 (his ask, 6 Oct: "make some story, add new npc and final bosses and hidden final bosses
## that fit into the story and game progress with new stages and environments, like a new dlc").
## The story is this game's own; see STORY.md. The world is a book still being written by THE
## AUTHOR; the floors are its chapters, the Umbral Sun a blot of ink, Heaven and Hell notes in the
## margin, the Unwritten the blank page that eats unfinished stories. Past it, CHAPTER II.
##
## What the player has reached is kept between runs (Meta.meta["story"]: milestone -> true) and
## THE ARCHIVIST, met at rest stops, tells it a line at a time (Meta.meta["story_heard"]).
## Expanded game only.

## Milestones: f6 the Pale Regent falls; f11 the Umbral Sun falls; realm a realm's ruler falls;
## unwritten the Unwritten falls; ch2 Chapter II begun; author the Author falls; redactor the
## hidden one falls.
const LINES := [
	["", "THIS WORLD IS A BOOK, STRANGER. SOMEONE IS STILL WRITING IT."],
	["", "EVERY FLOOR IS A CHAPTER. EVERY GUARDIAN, A PAGE THAT BITES."],
	["f6", "THE PALE REGENT WAS THE AUTHOR'S FIRST VILLAIN. HE WAS NEVER MEANT TO WIN."],
	["f6", "AFTER THE REGENT THE INK RAN WILD. THE AUTHOR'S HAND BEGAN TO SHAKE."],
	["f11", "THE UMBRAL SUN IS NO SUN. IT IS A BLOT: A DROP OF INK ON THE SKY."],
	["f11", "PAST THE BLOT LIE THE MARGINS, WHERE THE AUTHOR SCRIBBLED HEAVEN AND HELL."],
	["realm", "JUDGE OR KING, BOTH ARE NOTES IN THE MARGIN. THE STORY GOES ON ELSEWHERE."],
	["unwritten", "THE UNWRITTEN EATS STORIES THAT NEVER END. YOU GAVE IT ONE THAT DID."],
	["unwritten", "TURN THE PAGE AND YOU WILL FIND THE AUTHOR'S DESK. BRING A STRONG HEART."],
	["ch2", "THE INKWELL, THE BINDERY, THE QUILL SPIRE. THE AUTHOR WAITS AT THE TOP."],
	["ch2", "THREE PAGES WERE TORN FROM THE BOOK AND HIDDEN. FIND THEM, ALL THREE."],
	["author", "THE AUTHOR WANTED TO CLOSE THE BOOK. YOU WOULD NOT LET IT."],
	["author", "THE AUTHOR FEARED ONE THING: THE REDACTOR, WHO ERASES EVEN AUTHORS."],
	["redactor", "NOTHING IS ERASED NOW. THE STORY IS YOURS, ALL OF IT. THANK YOU."],
]

static func _db() -> Dictionary:
	if not (Meta.meta.get("story") is Dictionary):
		Meta.meta["story"] = {}
	return Meta.meta["story"]

static func reached(key: String) -> bool:
	return key == "" or _db().has(key)

## A milestone reached (saved). A toast the first time: the Archivist has something new.
static func reach(key: String) -> void:
	if not GameData.rogues() or _db().has(key):
		return
	_db()[key] = true
	Meta.write_save()
	G.toast("THE ARCHIVIST WILL WANT TO HEAR OF THIS", "bone")

## The lines the player may hear now, in order.
static func open_lines() -> Array:
	return LINES.filter(func(l): return reached(l[0]))

## The Archivist: the next line not yet heard, else one heard before.
static func next_line() -> String:
	var open := open_lines()
	var heard: int = Meta.meta.get("story_heard", 0)
	if heard < open.size():
		Meta.meta["story_heard"] = heard + 1
		Meta.write_save()
		return open[heard][1]
	return open[randi() % open.size()][1]

static func has_new() -> bool:
	return Meta.meta.get("story_heard", 0) < open_lines().size()

## A rest stop: the Archivist sits by the fire (always when he has something new, else now and then).
static func place(r: Room, cx: float, cy: float) -> void:
	if GameData.rogues() and (has_new() or randf() < 0.35):
		r.objects.append({ "kind": "n_archivist", "x": cx - 56, "y": cy })

## 12.2: on a Chapter II floor.
static func chapter2() -> bool:
	return GameData.rogues() and G.run_stats.get("chapter", 1) == 2 \
		and G.floor_index >= GameData.FLOORS.size() + GameData.NEW_FLOORS.size()

## THE BOOKBINDER, at Chapter II rest stops: one relic bound into a cover, for gold.
static func bind_shop(r: Room, cx: float, cy: float) -> void:
	if not chapter2():
		return
	var rel := G.roll_relics(1, "iron", r)
	r.objects.append({ "kind": "n_bookbinder", "x": cx + 104, "y": cy - 4,
		"relic": rel[0] if not rel.is_empty() else null, "price": G.price(55 + G.floor_index * 2) })

static func bookbinder(o: Dictionary) -> void:
	var p := G.player
	if o.get("relic") == null:
		G.toast("COME BACK WHEN THE BOOK HAS MORE PAGES", "grey")
		return
	if p.gold < o["price"]:
		G.deny(o, "NEED %d GOLD" % o["price"])
		return
	p.gold -= o["price"]
	G.add_relic(p, o["relic"])
	G.show_banner("THE BOOKBINDER", "\"" + str(o["relic"]["name"]) + ". MIND THE SPINE.\"")
	o["relic"] = null
	Snd.play("coin")

## 12.3: one TORN PAGE in a hidden room of each Chapter II floor. All three carried when the Author
## falls open the way to THE REDACTOR.
static func hide_page(r: Room, cx: float, cy: float) -> void:
	if not chapter2() or G.run_stats.get("page_floors", []).has(G.floor_index):
		return
	if not (G.run_stats.get("page_floors") is Array):
		G.run_stats["page_floors"] = []
	G.run_stats["page_floors"].append(G.floor_index)
	r.objects.append({ "kind": "n_tornpage", "x": cx - 96, "y": cy - 24 })

static func take_page(o: Dictionary) -> void:
	o["gone"] = true
	o["used"] = true
	G.run_stats["pages"] = G.run_stats.get("pages", 0) + 1
	var n: int = G.run_stats["pages"]
	G.show_banner("A TORN PAGE (%d OF 3)" % n, "THE AUTHOR'S DESK WILL KNOW" if n >= 3 else "THE OTHERS ARE HIDDEN ON THE OTHER FLOORS")
	Fx.burst(o["x"], o["y"], ["#f4ecd8", "#d8443c"], 16, 60)
	Snd.play("unlock")

## THE INKLING, wandering into cleared Chapter II fights: it drips on a wall and a hidden door opens.
static func inkling(o: Dictionary) -> void:
	o["used"] = true
	o["gone"] = true
	if not G.reveal_hidden_door("THE INKLING", "\"THE WALL IS ONLY PAPER HERE. TORN PAGES HIDE BEHIND PAPER.\""):
		G.show_banner("THE INKLING", "\"THREE PAGES WERE TORN OUT. THEY HIDE IN THE ROOMS BEHIND THE WALLS.\"")
	Fx.burst(o["x"], o["y"], ["#2a2a4a", "#9ab8ff"], 16, 60)
	Snd.play("select")

static func tell(o: Dictionary) -> void:
	o["talks"] = o.get("talks", 0) + 1
	G.show_banner("THE ARCHIVIST", next_line())
	Snd.play("select")
