class_name Burdens
extends RefCounted
## 49.1 (his list of another game's core gameplay, 10 Oct: "items that grow with gold, curses,
## souls"; GAMEPLAY_PLAN.md; the names and numbers are this game's own): relics that grow with THE
## CURSES YOU CARRY and THE FOES YOU HAVE SLAIN this run, beside the gold ones (gold_dmg).
## A curse you carry: each cursed trait you hold, each curse THE CURSED ARMORY laid on you
## (Player.curse_marks), a flawed enchantment on the weapon in your hand, each cursed relic
## (CURSED_RELICS). Foes slain: the run's kills (Player.kills). The hooks (gf; relics.gd "49.1"):
##   curse_dmg, curse_rate, curse_crit   damage, fire rate and crit for each curse
##   slain_dmg, slain_rate, slain_crit   the same for every 100 foes slain (250 kills: x2.5)
## Read in Combat.hook_mult (damage), Weapons.wrate (fire rate) and Combat.damage_enemy (crit);
## each card shows what it gives now (live.gd). Nothing changes for a hero without them.

const CURSED_RELICS := ["cursedcoin", "cursedcompass", "sinnerscrown"]

static var _at := -1.0
static var _who: Player = null
static var _n := 0

## The curses carried, counted afresh.
static func count(p: Player) -> int:
	if p == null:
		return 0
	var n := p.curse_marks
	for id in p.traits:
		if Traits.by_id(id).get("rarity", "") == "cursed":
			n += 1
	for r in p.relics:
		if r["id"] in CURSED_RELICS:
			n += 1
	if p.weapon != null and Enchant.of(p.weapon) in Enchant.group_of("bad"):
		n += 1
	return n

## The same, counted once a tick (the hooks read it on every hit).
static func curses(p: Player) -> int:
	if p != _who or G.time != _at:
		_who = p
		_at = G.time
		_n = count(p)
	return _n

## Foes slain this run, in hundreds.
static func slain(p: Player) -> float:
	return p.kills / 100.0 if p != null else 0.0

## Combat.hook_mult: damage.
static func dmg(p: Player) -> float:
	var m := 0.0
	if p.g("curse_dmg") > 0:
		m += p.g("curse_dmg") * curses(p)
	if p.g("slain_dmg") > 0:
		m += p.g("slain_dmg") * slain(p)
	return m

## Weapons.wrate: fire rate.
static func rate_mult(p: Player) -> float:
	var m := 1.0
	if p.g("curse_rate") > 0:
		m += p.g("curse_rate") * curses(p)
	if p.g("slain_rate") > 0:
		m += p.g("slain_rate") * slain(p)
	return m

## Combat.damage_enemy: crit chance.
static func crit(p: Player) -> float:
	var c := 0.0
	if p.g("curse_crit") > 0:
		c += p.g("curse_crit") * curses(p)
	if p.g("slain_crit") > 0:
		c += p.g("slain_crit") * slain(p)
	return c
