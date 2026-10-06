class_name Themes
extends RefCounted
## Rift worlds: themed side stages reached through a RIFT door (one is
## offered on every floor). A rift is three rooms in its world's own tiles,
## with its own foes and hazard: a fight, a harder fight, then the world's
## champion. After the champion the doors lead back to the floor.
##
## Each world is an original homage to a mood, not to any one work: names,
## foes, champions and art are this game's own.
##
##   kit      tile set (assets/graphics/kit_<id>.png, laid out like kit0)
##   pool     foes of its fights (keys of GameData.ENEMIES)
##   champion its boss (a GameData.ENEMIES entry with "champion")
##   mini     (the new worlds) its mini-boss: the last wave of its second room (rift_bosses.gd)
##   guardian (the new worlds) its guardian (GameData.BOSSES), behind a second door in the
##            champion's room: an optional fight
##   hazard   a key of Hazards.THEME (or "")
##   decor    floor markings drawn over the tiles: "road", "rug", "" ...
##   fog      true: drifting fog over the room (drawing only)
##   music    which of the original tracks plays
##   layouts  "isles": the world's own room layouts (islands over open sky, World.T_VOID)

const LIST := [
	{ "id": "gaol", "name": "BLACKROCK GAOL", "sub": "NO ONE LEAVES THE ISLAND", "kit": "kit_gaol", "accent_hex": "#8fa3a0",
	  "pool": ["inmate", "inmate", "grenadier", "jailer", "inmate", "grenadier"], "champion": "turnkey", "hazard": "spikes",
	  "decor": "", "music": 0 },
	{ "id": "brand", "name": "THE BRANDED FIELD", "sub": "THE SKY HAS GONE RED", "kit": "kit_brand", "accent_hex": "#d8443c",
	  "pool": ["graveborn", "bandsman", "fiendling", "blackknight", "bandsman", "fiendling"], "champion": "carrionknight",
	  "hazard": "bloodrain", "decor": "", "music": 5 },
	{ "id": "neon", "name": "NEON UNDERCITY", "sub": "EVERYTHING HERE IS FOR SALE", "kit": "kit_neon", "accent_hex": "#6fd3e0",
	  "pool": ["drone", "glitch", "chrome", "turret", "drone", "glitch"], "champion": "broker", "hazard": "pylons",
	  "decor": "", "music": 2 },
	{ "id": "streets", "name": "RIOT ALLEY", "sub": "THE WHOLE BLOCK HAS GONE MAD", "kit": "kit_streets", "accent_hex": "#e86fb4",
	  "pool": ["thug", "molotov", "copper", "bomber", "thug", "copper"], "champion": "mayor", "hazard": "barrels",
	  "decor": "", "music": 3 },
	{ "id": "fog", "name": "ASHFALL TOWN", "sub": "A SIREN SOUNDS SOMEWHERE IN THE FOG", "kit": "kit_fog", "accent_hex": "#a9b0a6",
	  "pool": ["orderly", "crawler", "static", "tollkeeper", "crawler", "orderly"], "champion": "rustbutcher", "hazard": "ash",
	  "decor": "", "fog": true, "music": 4 },
	{ "id": "burb", "name": "MAPLE COURT", "sub": "A LOVELY HOME. THE RENT IS DUE", "kit": "kit_burb", "accent_hex": "#7fb8a8",
	  "pool": ["neighbour", "robovac", "burglar", "gnome", "neighbour", "robovac"], "champion": "landlord", "hazard": "kitchen",
	  "decor": "rug", "music": 1 },
	{ "id": "heist", "name": "HEIST CITY", "sub": "WATCH THE TRAFFIC", "kit": "kit_heist", "accent_hex": "#f2c94c",
	  "pool": ["gangster", "biker", "riotcop", "gangster", "biker", "gangster"], "champion": "kingpin", "hazard": "traffic",
	  "decor": "road", "music": 2 },
	{ "id": "dust", "name": "DUSTWATER", "sub": "THIS TOWN AIN'T BIG ENOUGH", "kit": "kit_dust", "accent_hex": "#c9a35a",
	  "pool": ["outlaw", "dynamiter", "sharpshooter", "coyote", "outlaw", "coyote"], "champion": "marshal", "hazard": "dynamite",
	  "decor": "", "music": 3 },
	{ "id": "skyreach", "name": "SKYREACH ISLES", "sub": "MIND THE DROP", "kit": "kit_skyreach", "accent_hex": "#9fc3ee",
	  "pool": ["skykite", "gustling", "stormharpy", "thunderhead", "mirrorwing", "crow"], "champion": "galewarden", "mini": "squallheron", "guardian": "stormcrown", "hazard": "gusts",
	  "decor": "", "layouts": "isles", "music": 5 },
	{ "id": "bastion", "name": "THE DROWNED BASTION", "sub": "THE TIDE COMES IN POISONED", "kit": "kit_bastion", "accent_hex": "#63b84f",
	  "pool": ["rampartguard", "sludgecrawler", "chainwarden", "tidecaller", "longpike", "drowned"], "champion": "rotking", "mini": "tidecaptain", "guardian": "bilgehydra", "hazard": "tide",
	  "decor": "", "layouts": "bastion", "music": 4 },
	{ "id": "cathedral", "name": "THE CALIBER CATHEDRAL", "sub": "FLIP A TABLE. SAY A PRAYER", "kit": "kit_cathedral", "accent_hex": "#f2c94c",
	  "pool": ["shellpriest", "dervish", "deacon", "beltfeeder", "ammomimic", "gunman"], "champion": "highcaliber", "mini": "bellringer", "guardian": "brassorgan", "hazard": "turrets",
	  "decor": "", "layouts": "cathedral", "music": 3 },
	# 6.4 (his ask, 6 Oct): a tower of brass and steam. Its guardian fights on the guardians' rules
	# (BossAI: three stages, evolving), like the Holy Cow.
	{ "id": "spire", "name": "THE CLOCKWORK SPIRE", "sub": "EVERYTHING HERE IS WOUND TOO TIGHT", "kit": "kit_spire", "accent_hex": "#e8b84a",
	  "pool": ["cogling", "steamjack", "boltslinger", "gearhound", "rivetlobber", "brasswasp"], "champion": "foreman", "guardian": "greatengine", "hazard": "vent",
	  "decor": "", "music": 2 },
	# 7.3 (his word "All", 6 Oct): caverns of blue ice where nothing thaws. Its guardian fights on the
	# guardians' rules (BossAI: three stages, evolving), like the Great Engine.
	{ "id": "rimefrost", "name": "THE RIMEFROST HOLLOWS", "sub": "NOTHING HERE HAS THAWED IN A THOUSAND YEARS", "kit": "kit_rimefrost", "accent_hex": "#8fd8ff",
	  "pool": ["frostmite", "rimebrute", "shardcaster", "frostfang", "snowlobber", "glimmerwisp"], "champion": "hoarknight", "guardian": "glacialmaw", "hazard": "spikes",
	  "decor": "", "music": 2 },
]

## Heaven and Hell (ROADMAP 4.7 part C, soul.gd): reached only through the SOUL GATE past the Umbral
## Sun, never offered as a rift. Two fights, then the ruler (step 3: the guardian's room). The
## Unwritten Page is the last room of all.
const REALMS := [
	{ "id": "heaven", "name": "THE GILDED EMPYREAN", "sub": "THE LIGHT HAS WEIGHED YOUR SOUL", "kit": "kit_heaven", "accent_hex": "#f2c94c",
	  "pool": ["wisp", "knight", "golem", "monk", "icearcher", "wisp"], "guardian": "judge", "hazard": "", "decor": "", "music": 5, "realm": true },
	{ "id": "hell", "name": "THE SCORCHED DEEP", "sub": "THE DARK HAS CLAIMED YOUR SOUL", "kit": "kit_hell", "accent_hex": "#d8443c",
	  "pool": ["torchimp", "voidling", "shadeknight", "eclipsed", "cultist", "torchimp"], "guardian": "cinderking", "hazard": "", "decor": "", "music": 5, "realm": true },
	{ "id": "brazil", "name": "BRAZIL", "sub": "YOU'RE NOT SUPPOSED TO BE HERE", "kit": "kit_brazil", "accent_hex": "#8b8f5a",
	  "pool": ["scrounger", "scrounger", "crawler", "scrounger", "thug", "crawler", "raider", "raider"], "guardian": "holycow", "hazard": "", "decor": "",
	  "fog": true, "music": 4, "short": true },
	{ "id": "seam", "name": "THE UNWRITTEN PAGE", "sub": "WHERE THE WORLD WAS FIRST WRITTEN", "kit": "kit_seam", "accent_hex": "#f4ecd8",
	  "pool": ["ghost", "voidling"], "guardian": "unwritten", "hazard": "", "decor": "", "music": 5, "realm": true },
]

static var _by_id := {}

static func by_id(id: String) -> Dictionary:
	if _by_id.is_empty():
		for t in LIST + REALMS:
			_by_id[t["id"]] = t
	return _by_id.get(id, {})

## A world this run has not visited yet (any, once all have been seen).
static func pick(seen: Array) -> String:
	var pool := []
	for t in LIST:
		if not t["id"] in seen:
			pool.append(t["id"])
	if pool.is_empty():
		for t in LIST:
			pool.append(t["id"])
	return TB.pick(pool)
