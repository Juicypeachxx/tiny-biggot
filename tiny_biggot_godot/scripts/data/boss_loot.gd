class_name BossLoot
extends RefCounted
## Every guardian and mini-boss leaves an item of its own when it falls (his ask, 6 Oct: "they drop
## unique equipment or weapon fitted to them"; expanded game only). Found nowhere else: never in a
## chest, a shop or a random drop. The Holy Cow (COW MILKER) and the Haggler (his gun and hat) were
## already so (brazil.gd).

## boss key or foe type -> [weapon or gear, id]
const DROPS := {
	"sporemother": ["weapon", "bloomspitter"],
	"librarian": ["weapon", "drownedtome"],
	"tyrant": ["weapon", "tyranthammer"],
	"ashwarlord": ["weapon", "warlordsbow"],
	"crowking": ["weapon", "crowrepeater"],
	"judge": ["weapon", "judgescales"],
	"unwritten": ["weapon", "blankquill"],
	"bilgehydra": ["weapon", "hydraheads"],
	"rex": ["weapon", "moldyloaf"],
	"arci": ["weapon", "arcifrisbee"],   # 58
	"tidecaptain": ["weapon", "captainsanchor"],
	"enforcer": ["weapon", "enforcergun"],
	"carrionknight": ["weapon", "carrionlance"],
	"rustbutcher": ["weapon", "rustcleaver"],
	"kingpin": ["weapon", "kingpingun"],
	"marshal": ["weapon", "marshalsiron"],
	"highcaliber": ["weapon", "highcaliber"],
	"colossus": ["gear", "colossusribs"],
	"rimewarden": ["gear", "rimewardencrown"],
	"regent": ["gear", "regentsignet"],
	"bogmatriarch": ["gear", "matriarchrobe"],
	"frozenabbot": ["gear", "abbotpalms"],
	"umbralsun": ["gear", "umbralheart"],
	"cinderking": ["gear", "cindercrown"],
	"stormcrown": ["gear", "stormcrownitem"],
	"brassorgan": ["gear", "organpipe"],
	"squallheron": ["gear", "heronboots"],
	"bellringer": ["gear", "crackedbell"],
	"mirehulk": ["gear", "mirehide"],
	"ironcaptain": ["gear", "captainhelm"],
	"stoneabbot": ["gear", "abbotfists"],
	"herald": ["gear", "heraldhorn"],
	"turnkey": ["gear", "keyring"],
	"broker": ["gear", "brokerledger"],
	"mayor": ["gear", "mayorhat"],
	"landlord": ["gear", "landlordsignet"],
	"galewarden": ["gear", "galeboots"],
	"rotking": ["gear", "rottingcrown"],
	"foreman": ["gear", "foremanhat"],     # 6.4
	"greatengine": ["weapon", "enginecore"],
	"hoarknight": ["gear", "hoarhelm"],    # 7.3
	"glacialmaw": ["weapon", "glacierheart"],
	# 9.3 the second guardians.
	"admiral": ["gear", "admiralhat"], "golemking": ["gear", "golemplate"], "archmage": ["weapon", "archstaff"],
	"phoenix": ["gear", "phoenixplume"], "wyrm": ["weapon", "wyrmfang"], "chainfiend": ["gear", "fiendchains"],
	"seraph": ["weapon", "seraphlance"],
	# 12.4 Chapter II.
	"inkleviathan": ["weapon", "inkspout"], "thebinder": ["gear", "binderthread"], "author": ["weapon", "authorspen"],
	"redactor": ["gear", "blackbar"],
	# 20.3 Chapter IV.
	"shelver": ["gear", "shelversarm"], "hush": ["weapon", "hushbell"], "critic": ["weapon", "redpen"],
}

static func is_unique(id: String) -> bool:
	for v in DROPS.values():
		if v[1] == id:
			return true
	return false

## Its owner falls: the item lands by it.
static func drop(e: Enemy) -> void:
	if not GameData.rogues():
		return
	var key: String = e.boss if e.boss != "" else e.type
	if not DROPS.has(key):
		return
	var d: Array = DROPS[key]
	var it: Dictionary = Weapons.by_id(d[1]) if d[0] == "weapon" else Gear.by_id(d[1])
	G.drop_item(it, e.x, e.y + 24)
	Juice.label(it["name"], "#f2c94c", e.x, e.y - 12)
