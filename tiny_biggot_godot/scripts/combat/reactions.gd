class_name Reactions
extends RefCounted
## Stage 25 REACTIONS (his word, 9 Oct: "add new effect system"). Expanded game only. A foe carrying
## two ailments that meet reacts, with a word over it, once every COOLDOWN seconds a foe:
##   burn + chill      MELT          a blow for 300% of your weapon's damage; the chill is spent
##   burn + poison     TOXIC BLAST   a blast for 200% around the foe; the poison is spent
##   chill + shock     SHATTER       200% to every foe near it, and it is stunned
##   poison + curse    WITHER        it takes more damage and hits weaker (vulnerable, weakened)
##   bleed + curse     HEMORRHAGE    a blow for 350%
##   shock + burn      OVERLOAD      lightning strikes it
## Traits make reactions harder (react_dmg) or come back sooner (react_fast); some weapons carry
## two ailments at once. Combat.damage_enemy calls `check` after a blow.

const COOLDOWN := 2.0
const NAMES := { "melt": ["MELT!", "orange"], "toxic": ["TOXIC BLAST!", "lime"], "shatter": ["SHATTER!", "cyan"],
	"wither": ["WITHER!", "purple"], "hemorrhage": ["HEMORRHAGE!", "red"], "overload": ["OVERLOAD!", "cyan"],
	# 50.2: the five new damage types' ailments (damage_types.gd)
	"eclipse": ["ECLIPSE!", "purple"], "blight": ["BLIGHT!", "green"], "superconduct": ["SUPERCONDUCT!", "cyan"],
	"crackle": ["CRACKLE!", "cyan"], "feedback": ["FEEDBACK!", "bone"] }

static var _next := {}   # foe uid -> the time it may react again
static var stats := {}   # reactions seen, by name (tests read it)

static func clear() -> void:
	_next.clear()

static func check(e: Enemy) -> void:
	var p := G.player
	if p == null or e.hp <= 0 or e.is_boss() and e.break_t > 0:
		return
	var burn := e.burn_t > 0
	var chill := e.chill_t > 0
	var poison := e.poison > 0
	var curse := e.curse_t > 0
	var bleed := e.bleed_t > 0
	var shock := e.shock > 0
	var r := ""
	if burn and chill: r = "melt"
	elif burn and poison: r = "toxic"
	elif chill and shock: r = "shatter"
	elif poison and curse: r = "wither"
	elif bleed and curse: r = "hemorrhage"
	elif shock and burn: r = "overload"
	elif e.seared_t > 0 and e.gloom > 0: r = "eclipse"   # 50.2: light meets dark
	elif e.rot > 0 and poison: r = "blight"
	elif e.charge > 0 and shock: r = "superconduct"
	elif e.rattle > 0 and chill: r = "crackle"
	elif e.rattle > 0 and e.charge > 0: r = "feedback"
	if r == "" or _next.get(e.uid, 0.0) > G.time:
		return
	_next[e.uid] = G.time + COOLDOWN * (0.5 if p.g("react_fast") > 0 else 1.0) * (0.5 if p.g("react_avatar") > 0 else 1.0)
	stats[r] = stats.get(r, 0) + 1
	var base := Weapons.wdmg(p) * (1.0 + p.g("react_dmg"))
	var w: Array = NAMES[r]
	Fx.texts.append({ "x": e.x, "y": e.y - e.r - 16, "text": w[0], "col": w[1], "life": 0.8, "big": true })
	match r:
		"melt":
			e.chill_t = 0.0
			Fx.burst(e.x, e.y - 4, ["#ffffff", "#c8f0ff", "#e8873a"], 12, 60, 0.4)
			Combat.damage_enemy(e, base * 3.0, { "no_crit": true, "col": "orange", "silent": true })
		"toxic":
			e.poison = 0.0
			Combat.explode_at(e.x, e.y, base * 2.0, null, 36, "#b8e05a")
		"shatter":
			Statuses.apply(e, "stun", 1, base)
			Fx.burst(e.x, e.y - 4, ["#c8f0ff", "#6fd3e0", "#ffffff"], 14, 80, 0.4)
			for o in G.enemies.duplicate():
				if o.targetable() and o.charm_t <= 0 and TB.dist(o, e) < 34.0 + o.r:
					Combat.damage_enemy(o, base * 2.0, { "no_crit": true, "col": "cyan", "silent": true })
		"wither":
			Statuses.apply(e, "vulnerable", 2, base)
			Statuses.apply(e, "weakened", 2, base)
			Fx.burst(e.x, e.y - 4, ["#7a3a8c", "#b8e05a"], 10, 40, 0.5)
		"hemorrhage":
			Fx.burst(e.x, e.y - 4, ["#d8443c", "#8a2a33"], 12, 70, 0.4)
			Combat.damage_enemy(e, base * 3.5, { "no_crit": true, "col": "red", "silent": true })
		"overload":
			Combat.lightning(e, base)
		"eclipse":   # a blast of black light that stuns what stands near
			e.seared_t = 0.0
			Combat.explode_at(e.x, e.y, base * 3.0, null, 44, "#a35bd6")
			for o in G.enemies.duplicate():
				if o.targetable() and o.charm_t <= 0 and TB.dist(o, e) < 50.0 + o.r:
					Statuses.apply(o, "stun", 1, base)
		"blight":   # the poison is spent and the rot spreads to every foe near it
			e.poison = 0.0
			Fx.burst(e.x, e.y - 4, ["#7ad04a", "#3a5a2a", "#b8e05a"], 12, 50, 0.5)
			for o in G.enemies.duplicate():
				if o != e and o.targetable() and o.charm_t <= 0 and TB.dist(o, e) < 60.0 + o.r:
					Statuses.apply(o, "rot", 3, base)
			Combat.damage_enemy(e, base * 2.0, { "no_crit": true, "col": "green", "silent": true })
		"superconduct":   # the charge goes off at once, and lightning leaps on
			e.charge = 0
			e.charge_t = 0.0
			Combat.explode_at(e.x, e.y, base * 2.5, null, 40, "#6fe8ff")
			if e.hp > 0:
				Combat.chain_from(e, base)
		"crackle":   # frozen and shaken: it cracks
			e.chill_t = 0.0
			e.rattle = 0
			Statuses.apply(e, "stun", 1.5, base)
			Combat.damage_enemy(e, base * 2.5, { "no_crit": true, "col": "cyan", "silent": true })
		"feedback":   # sound and energy howl out of it in a ring
			e.rattle = 0
			e.charge = 0
			for k in 12:
				var b := Combat.spawn_pbullet(p, k * TAU / 12.0, base * 0.6, "spark")
				if b != null:
					b.x = e.x
					b.y = e.y - 4.0
	if not p.procs.is_empty():
		Effects.fire("on_reaction", { "enemy": e, "x": e.x, "y": e.y, "dmg": base })   # 26: traits and synergies that feed on it
