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
##   hazard   a key of Hazards.THEME (or "")
##   decor    floor markings drawn over the tiles: "road", "rug", "" ...
##   fog      true: drifting fog over the room (drawing only)
##   music    which of the original tracks plays

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
]

static var _by_id := {}

static func by_id(id: String) -> Dictionary:
	if _by_id.is_empty():
		for t in LIST:
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
