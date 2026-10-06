class_name Soul
extends RefCounted
## Heaven and Hell (ROADMAP 4.7 part C; his ask, 5 Oct: "a story part, final two bosses based on
## your perks like in Tiny Rogues, that unlocks the final final final boss"). What you carry leans
## your soul to the light or the dark: every tag of your weapon, gear, relics and traits counts
## (a trait once per rank). Past the Umbral Sun a SOUL GATE opens to the realm your soul leans to:
## THE GILDED EMPYREAN (light) or THE SCORCHED DEEP (dark), two fights and its ruler. Its fall opens
## the way to THE UNWRITTEN PAGE and the last boss of all. A tie counts as light.

const LIGHT := ["bulwark", "frost", "arcane", "edge", "storm", "swarm"]
const DARK := ["blood", "malice", "shadow", "fury", "pyre", "venom"]

## [light, dark] for what the hero carries now.
static func weigh(p: Player) -> Array:
	var tags := []
	if p.weapon != null:
		tags.append_array(p.weapon.get("tags", []))
	for g in p.gear.values():
		if g != null:
			tags.append_array(g.get("tags", []))
	for r in p.relics:
		tags.append_array(r.get("tags", []))
	for id in p.traits:
		var t: Dictionary = Traits.by_id(id)
		for k in p.traits[id]:
			tags.append_array(t.get("tags", []))
	var light := 0
	var dark := 0
	for t in tags:
		if t in LIGHT:
			light += 1
		elif t in DARK:
			dark += 1
	return [light, dark]

static func realm(p: Player) -> String:
	var w := weigh(p)
	return "heaven" if w[0] >= w[1] else "hell"
