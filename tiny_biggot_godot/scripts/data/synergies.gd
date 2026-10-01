class_name Synergies
extends RefCounted
## Tag synergies and named combos (design spec 2c). Content arrives in the
## content batches; this file defines the format.
##
## TAG_SYNERGIES: { "tag": t, "tiers": [ { "need": n, "name", "desc", "effects": [...] }, ... ] }
##   A tier switches on when the player holds `need` points of tag t, counted
##   over new-content relics, weapon, gear and trait ranks. Effects must be
##   reversible (add, mul, pct, hook and procs) because a tier switches off
##   again if gear is swapped away.
## COMBOS: { "id", "name", "desc", "needs": ["relic:id", "weapon:id", "gear:id", "trait:id", ...], "effects": [...] }
##   (ids are unique per table only: the originals have a relic and a weapon
##   both called "lantern", and a relic and a trait both called "echo").
##   Switches on while the player owns every listed item (relic, weapon,
##   gear piece or trait). The player sees a "COMBO" banner when one activates.

const TAG_SYNERGY_DATA := []
const COMBO_DATA := []

static var TAG_SYNERGIES: Array = TAG_SYNERGY_DATA.duplicate(true)
static var COMBOS: Array = COMBO_DATA.duplicate(true)
