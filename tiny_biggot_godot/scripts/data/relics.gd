class_name Relics
extends RefCounted
## Relics (Data.rb RELICS / LOOT, extended by the content batches).
## Each row is [id, rarity, name, desc, effects, tags, sprite]; new relics
## name an existing sprite to reuse (placeholder art). Effects use the effect
## system (effects/effects.gd). The original 66 relics were converted
## mechanically from their Ruby lambdas (each statement becomes one op, in
## order) and carry no synergy tags. tests/effects_test.gd checks them against
## the Ruby code.

const ORIGINAL_COUNT := 66
const ROWS := [
	["whetstone", "common", "WHETSTONE", "+25% DAMAGE", [["mul", "dmg", 1.25]]],
	["twitch", "common", "TWITCHING FINGER", "+20% FIRE RATE", [["mul", "rate", 1.2]]],
	["splitfang", "rare", "SPLIT FANG", "+1 PROJECTILE, -10% DAMAGE", [["add", "count", 1], ["mul", "dmg", 0.9]]],
	["owl", "common", "OWL FEATHER", "+25% SHOT SPEED AND RANGE", [["mul", "shot_speed", 1.25], ["mul", "life", 1.15]]],
	["sparrow", "common", "SPARROW BOOTS", "+15% MOVE SPEED", [["mul", "speed", 1.15]]],
	["garnet", "rare", "BLOOD GARNET", "+1 MAX HEART, HEALS 1 HEART", [["add", "max_hp", 2], ["add_cap", "hp", 2, "max_hp"]]],
	["bramble", "common", "BRAMBLE RING", "SHOTS PIERCE 1 MORE FOE", [["add", "pierce", 1]]],
	["sap", "rare", "RUBBER SAP", "SHOTS BOUNCE OFF WALLS", [["add", "bounce", 1], ["mul", "life", 1.2]]],
	["seeker", "rare", "SEEKER'S EYE", "SHOTS HOME IN ON FOES", [["add", "homing", 2.5]]],
	["coal", "common", "CINDER COAL", "25% CHANCE TO BURN", [["add", "burn", 0.25]]],
	["needle", "common", "FROST NEEDLE", "25% CHANCE TO CHILL FOES", [["add", "chill", 0.25]]],
	["viper", "common", "VIPER TOOTH", "HITS POISON FOES", [["add", "poison", 1]]],
	["luckycoin", "common", "CROOKED COIN", "+12% CRIT CHANCE", [["add", "crit", 0.12]]],
	["hourglass", "common", "SAND GLASS", "ROLL RECHARGES 35% FASTER", [["mul", "dodge_cd", 0.65]]],
	["lantern", "rare", "GRAVE LANTERN", "KILLS HAVE 6% CHANCE TO HEAL", [["add", "lifesteal", 0.06]]],
	["buckler", "rare", "IRON BUCKLER", "BLOCKS THE FIRST HIT IN EACH ROOM", [["set", "buckler", true]]],
	["moon", "epic", "PALE MOON", "AN ORB CIRCLES YOU AND BLOCKS SHOTS", [["add", "orbitals", 1]]],
	["sapbomb", "rare", "POWDER POUCH", "ROLLING DROPS A BOMB", [["set", "bomb_dodge", true]]],
	["dice", "rare", "LOADED DIE", "15% CHANCE TO FIRE A TRIPLE VOLLEY", [["add", "triple", 0.15]]],
	["arrowhead", "common", "BARBED TIP", "+15% DAMAGE, +15% SHOT SPEED", [["mul", "dmg", 1.15], ["mul", "shot_speed", 1.15]]],
	["thorn", "common", "THORN LEAF", "FOES THAT TOUCH YOU TAKE DAMAGE", [["add", "thorns", 10]]],
	["crown", "rare", "PAUPER'S CROWN", "+50% GOLD, SHOPS 20% CHEAPER", [["mul", "gold_mult", 1.5], ["add_cap", "shop_disc", 0.2, 0.6]]],
	["heavy", "epic", "LEAD SHOT", "BIGGER SHOTS, +30% DAMAGE, -10% RATE", [["mul", "size", 1.35], ["mul", "dmg", 1.3], ["mul", "rate", 0.9]]],
	["fever", "rare", "FEVER SCROLL", "KILLS GRANT A BURST OF FIRE RATE", [["add", "frenzy", 1]]],
	["bonecharm", "rare", "BONE CHARM", "+1 ROLL CHARGE", [["add", "dodge_charges", 1], ["add", "charges", 1]]],
	["glassheart", "epic", "GLASS HEART", "+60% DAMAGE, -1 MAX HEART", [["mul", "dmg", 1.6], ["add_floor", "max_hp", -2, 2], ["clamp_max", "hp", "max_hp"]]],
	["echo", "rare", "ECHO RING", "ALSO FIRES A SHOT BEHIND YOU", [["add", "backshot", 1]]],
	["witcheye", "epic", "WITCH EYE", "+15% CRIT, CRITS DEAL X2.5", [["add", "crit", 0.15], ["at_least", "crit_mult", 2.5]]],
	["rage", "rare", "WRATH EMBER", "+50% DAMAGE WHILE AT 1 HEART OR LESS", [["add", "rage", 0.5]]],
	["lodestone", "rare", "LODESTONE", "PULLS GOLD, +25% GOLD", [["set", "magnet", true], ["mul", "gold_mult", 1.25]]],
	["sigil", "epic", "WARDING SIGIL", "TAKING DAMAGE RELEASES A NOVA", [["add", "ward", 1]]],
	["shells", "rare", "VOLATILE SHELLS", "SHOTS BURST ON IMPACT", [["add", "explode", 1]]],
	["spark", "rare", "CHAIN SPARK", "30% CHANCE HITS ARC TO A NEARBY FOE", [["add", "chain", 0.3]]],
	["keyring", "common", "WARDEN'S KEY", "+1 POTION SLOT, GAIN 1 POTION", [["add", "max_potions", 1], ["add_cap", "potions", 1, "max_potions"]]],
	["tallow", "common", "TALLOW CANDLE", "+1 BOMB, BOMBS DEAL +50% DAMAGE", [["add", "bombs", 1], ["mul", "bomb_mult", 1.5]]],
	["skeletonkey", "common", "SKELETON KEY", "+2 KEYS", [["add", "keys", 2]]],
	["quiver", "common", "QUIVER STRAP", "+10% FIRE RATE, +10% SHOT SPEED", [["mul", "rate", 1.1], ["mul", "shot_speed", 1.1]]],
	["filings", "common", "IRON FILINGS", "+1 ARMOR", [["add", "armor", 1]]],
	["gravedust", "common", "GRAVE DUST", "FOES DROP 30% MORE GOLD", [["mul", "gold_drop", 1.3]]],
	["mothwing", "common", "MOTH WING", "ROLLS GO FURTHER AND FASTER", [["mul", "roll_speed", 1.25]]],
	["bitterroot", "common", "BITTER ROOT", "POTIONS HEAL 1 MORE HEART", [["add", "potion_heal", 2]]],
	["tinwhistle", "common", "TIN WHISTLE", "+10% MOVE SPEED, ROLL RECHARGES FASTER", [["mul", "speed", 1.1], ["mul", "dodge_cd", 0.9]]],
	["chalk", "common", "MAPPER'S CHALK", "HIDDEN WALLS GLOW, +1 BOMB", [["set", "reveal", true], ["add", "bombs", 1]]],
	["rustynail", "common", "RUSTY NAIL", "+1 PIERCE, +10% DAMAGE", [["add", "pierce", 1], ["mul", "dmg", 1.1]]],
	["wispjar", "rare", "WISP JAR", "A WISP FOLLOWS YOU AND SHOOTS FOES", [["add", "familiars", 1]]],
	["emberheart", "rare", "EMBER HEART", "FOES NEAR YOU CATCH FIRE", [["add", "aura", 1]]],
	["boneshield", "rare", "BONE SHIELD", "+2 ARMOR", [["add", "armor", 2]]],
	["huntersmark", "rare", "HUNTER'S MARK", "+35% DAMAGE TO ELITES AND BOSSES", [["add", "elite_mult", 0.35]]],
	["glasslens", "rare", "GLASS LENS", "SHOTS GROW AND HIT HARDER AS THEY FLY", [["set", "lens", true]]],
	["staticcoil", "rare", "STATIC COIL", "EVERY 4 SECONDS, RELEASE A RING OF SPARKS", [["add", "coil", 1]]],
	["bloodoath", "rare", "BLOOD OATH", "+1 MAX HEART FOR EACH GUARDIAN SLAIN", [["set", "oath", true]]],
	["ricochet", "rare", "RICOCHET BEAD", "SHOTS JUMP TO ANOTHER FOE AFTER A HIT", [["add", "ricochet", 1]]],
	["misers", "rare", "MISER'S PURSE", "+1% DAMAGE FOR EVERY 10 GOLD HELD", [["set", "miser", true]]],
	["shadowstep", "rare", "SHADOW STEP", "ROLLING THROUGH FOES DAMAGES THEM", [["set", "shadowstep", true]]],
	["coldiron", "rare", "COLD IRON", "+10% DAMAGE, +15% CHANCE TO CHILL", [["mul", "dmg", 1.1], ["add", "chill", 0.15]]],
	["splinter", "rare", "SPLINTER", "KILLS BURST INTO SHARDS", [["add", "splinter", 1]]],
	["phoenix", "epic", "PHOENIX FEATHER", "ONCE PER RUN, RISE AGAIN WITH 2 HEARTS", [["add", "revive", 1]]],
	["twinwisp", "epic", "TWIN LANTERNS", "TWO WISPS FOLLOW YOU", [["add", "familiars", 2]]],
	["stormcrown", "epic", "STORM CROWN", "HITS MAY CALL DOWN LIGHTNING", [["add", "storm", 0.2]]],
	["hollowmirror", "epic", "HOLLOW MIRROR", "ENEMY SHOTS SLOW DOWN NEAR YOU", [["set", "mirror", true]]],
	["gildedtooth", "epic", "GILDED TOOTH", "SHOPS 30% CHEAPER, +25% GOLD", [["add_cap", "shop_disc", 0.3, 0.6], ["mul", "gold_mult", 1.25]]],
	["overcharge", "epic", "OVERCHARGE", "+1 PROJECTILE, +15% RATE, -1 MAX HEART", [["add", "count", 1], ["mul", "rate", 1.15], ["add_floor", "max_hp", -2, 2], ["clamp_max", "hp", "max_hp"]]],
	["deepeye", "legend", "EYE OF THE DEEP", "+2 PROJECTILES THAT HOME IN", [["add", "count", 2], ["add", "homing", 2.5]]],
	["cindercrown", "legend", "CROWN OF CINDERS", "+50% DAMAGE, SHOTS OFTEN BURN", [["mul", "dmg", 1.5], ["add", "burn", 0.35]]],
	["ageglass", "legend", "GLASS OF AGES", "+2 ROLL CHARGES, ROLLING RELOADS", [["add", "dodge_charges", 2], ["add", "charges", 2], ["set", "roll_reload", true]]],
	["worldseed", "legend", "WORLDSEED", "+2 MAX HEARTS, HEAL FULLY", [["add", "max_hp", 4], ["copy", "hp", "max_hp"]]],
	# ---------- Content batch 1 (Tiny Biggot Rogues) ----------
	["sharpstone", "common", "OILED WHETSTONE", "+7% CRIT CHANCE", [["add", "crit", 0.07]], ["edge"], "relic_whetstone"],
	["keeneye", "common", "KEEN EYE", "CRITS DEAL +0.25X MORE", [["add", "crit_mult", 0.25]], ["edge"], "relic_owl"],
	["firstblood", "rare", "FIRST NICK", "CRITS ON UNHURT FOES DEAL +60%", [["hook", "first_hit", 0.3], ["add", "crit", 0.05]], ["edge"], "relic_needle"],
	["hairtrigger", "rare", "HAIR TRIGGER", "CRITS GIVE +20% FIRE RATE FOR 1S", [{ "on": "on_crit", "do": [["buff", "rate", 0.2, 1.0]] }], ["edge"], "relic_twitch"],
	["killingblow", "legend", "THE KILLING BLOW", "CRIT CHANCE PAST 100% CRITS AGAIN. +20% CRIT", [["add", "crit", 0.2], ["add", "overcrit", 1.0]], ["edge"], "relic_witcheye"],
	["leechtooth", "common", "LEECH TOOTH", "KILLS ON BLEEDING FOES MAY HEAL", [{ "on": "on_kill", "chance": 0.08, "if": "bleeding", "do": [["heal", 1]] }], ["blood"], "relic_garnet"],
	["openwound", "rare", "OPEN WOUND", "HITS HAVE 20% CHANCE TO MAKE FOES BLEED", [{ "on": "on_hit", "chance": 0.2, "do": [["status", "bleed", 1]] }], ["blood"], "relic_thorn"],
	["bloodprice", "rare", "BLOOD PRICE", "+35% DAMAGE. POTIONS HEAL 1 HEART LESS", [["mul", "dmg", 1.35], ["add_floor", "potion_heal", -2, 1]], ["blood", "malice"], "relic_bloodoath"],
	["crimsonfont", "epic", "CRIMSON FONT", "CLEARING A ROOM HEALS HALF A HEART", [{ "on": "on_room_clear", "do": [["heal", 1]] }], ["blood"], "relic_lantern"],
	["matchbook", "common", "DAMP MATCHBOOK", "+12% BURN CHANCE", [["add", "burn", 0.12]], ["pyre"], "relic_coal"],
	["firework", "rare", "FIREWORK", "BURNING FOES EXPLODE WHEN KILLED", [{ "on": "on_kill", "if": "burning", "do": [["explode", 24, 0.7]] }], ["pyre"], "relic_shells"],
	["oilflask", "rare", "LAMP OIL", "BURNS DEAL +60% DAMAGE", [["add", "burn_dmg", 0.6]], ["pyre"], "relic_tallow"],
	["phoenixash", "epic", "PYRE ASH", "BURNING FOES TAKE +30% DAMAGE. +10% BURN", [["add", "vs_burn", 0.3], ["add", "burn", 0.1]], ["pyre"], "relic_cindercrown"],
	["toadstool", "common", "TOADSTOOL", "HITS ADD 1 POISON", [["add", "poison", 1]], ["venom"], "relic_viper"],
	["contagion", "rare", "CONTAGION", "POISONED FOES THAT DIE INFECT THE NEAREST FOE", [{ "on": "on_kill", "if": "poisoned", "do": [["status", "poison", 4]] }], ["venom"], "relic_splinter"],
	["witherroot", "rare", "WITHERROOT", "HITS ON POISONED FOES WEAKEN THEM 15% OF THE TIME", [{ "on": "on_hit", "chance": 0.15, "if": "poisoned", "do": [["status", "weakened", 1]] }], ["venom"], "relic_bitterroot"],
	["blackbile", "epic", "BLACK BILE", "POISON DAMAGE +80%. POISON TICKS FASTER", [["add", "poison_dmg", 0.8], ["set", "poison_fast", true]], ["venom"], "relic_sap"],
	["copperwire", "common", "COPPER WIRE", "+12% CHANCE FOR HITS TO ARC", [["add", "chain", 0.12]], ["storm"], "relic_spark"],
	["stormjar", "rare", "STORM IN A JAR", "15% OF HITS SHOCK. SHOCKED FOES TAKE MORE DAMAGE", [{ "on": "on_hit", "chance": 0.15, "do": [["status", "shock", 1]] }], ["storm"], "relic_staticcoil"],
	["groundingrod", "rare", "GROUNDING SPIKE", "EVERY 5 SECONDS, LIGHTNING STRIKES THE NEAREST FOE", [{ "on": "every_n_seconds", "period": 5.0, "do": [["lightning", 0.8]] }], ["storm"], "relic_stormcrown"],
	["overload", "epic", "OVERLOAD COIL", "ARCS AND LIGHTNING +60%. +1 ARC JUMP", [["add", "storm_dmg", 0.6], ["add", "chain_jumps", 1]], ["storm"], "relic_deepeye"],
	["mirrorbead", "common", "MIRROR BEAD", "+15% SHOT SPEED, SHOTS PIERCE 1 MORE", [["mul", "shot_speed", 1.15], ["add", "pierce", 1]], ["arcane"], "relic_arrowhead"],
	["prismshard", "rare", "PRISM SHARD", "SHOTS SPLIT IN TWO ON THEIR FIRST HIT", [["hook", "split", 1]], ["arcane"], "relic_splitfang"],
	["starchart", "rare", "STAR CHART", "EVERY 8TH ATTACK FIRES A RING OF 8 SPARKS", [{ "on": "every_n_shots", "every": 8, "do": [["nova", 8, 0.5, "spark"]] }], ["arcane"], "relic_moon"],
	["manyhands", "epic", "MANY HANDS", "+2 PROJECTILES, -15% DAMAGE", [["add", "count", 2], ["mul", "dmg", 0.85]], ["arcane"], "relic_overcharge"],
	["glowworm", "common", "GLOW-WORM JAR", "WISPS DEAL +30% DAMAGE", [["add", "fam_dmg", 0.3]], ["swarm"], "relic_wispjar"],
	["broodmother", "rare", "BROOD EGG", "15% OF KILLS RAISE A WISP FOR 6S", [{ "on": "on_kill", "chance": 0.15, "do": [["summon", 6.0]] }], ["swarm"], "relic_twinwisp"],
	["hivemind", "epic", "HIVEMIND", "+1 WISP. WISPS FIRE 30% FASTER", [["add", "familiars", 1], ["mul", "fam_rate", 1.3]], ["swarm"], "relic_echo"],
	["quickcloak", "common", "QUICKSILVER THREAD", "ROLLS RECHARGE 20% FASTER", [["mul", "dodge_cd", 0.8]], ["shadow"], "relic_hourglass"],
	["shadowcut", "rare", "SHADOW CUT", "ROLLING FIRES 6 SHADOW BLADES AROUND YOU", [{ "on": "on_roll", "do": [["nova", 6, 0.8, "spark"]] }], ["shadow"], "relic_shadowstep"],
	["afterimage", "rare", "AFTERIMAGE", "AFTER A ROLL, +40% DAMAGE FOR 1.5S", [{ "on": "on_roll", "do": [["buff", "dmg", 0.4, 1.5]] }], ["shadow"], "relic_mothwing"],
	["nightveil", "epic", "NIGHT VEIL", "+1 ROLL CHARGE. 10% CHANCE TO DODGE A HIT", [["add", "dodge_charges", 1], ["add", "charges", 1], ["add", "evade", 0.1]], ["shadow"], "relic_bonecharm"],
	["ironrations", "common", "IRON RATIONS", "+1 MAX HEART", [["add", "max_hp", 2], ["add_cap", "hp", 2, "max_hp"]], ["bulwark"], "relic_filings"],
	["spikedcollar", "rare", "SPIKED COLLAR", "+15 THORNS. WHEN HIT, FIRE 8 SPIKES", [["add", "thorns", 15], { "on": "on_damage_taken", "do": [["nova", 8, 0.7, "spark"]] }], ["bulwark"], "relic_thorn"],
	["towerkey", "rare", "BASTION KEY", "CLEARING A ROOM GRANTS 1 ARMOR 50% OF THE TIME", [{ "on": "on_room_clear", "chance": 0.5, "do": [["armor", 1]] }], ["bulwark"], "relic_boneshield"],
	["stonehide", "epic", "STONEHIDE", "+2 ARMOR. +6% DAMAGE PER ARMOR (UP TO 5)", [["add", "armor", 2], ["add", "fortress", 0.06]], ["bulwark"], "relic_buckler"],
	["redmist", "common", "RED MIST", "BELOW HALF HEALTH: +25% DAMAGE", [{ "on": "while_low_hp", "do": [["buff", "dmg", 0.25, 0]] }], ["fury"], "relic_rage"],
	["warpaint", "rare", "WAR PAINT", "KILLS GIVE +30% FIRE RATE FOR 2S", [{ "on": "on_kill", "do": [["buff", "rate", 0.3, 2.0]] }], ["fury"], "relic_fever"],
	["grudge", "rare", "OLD GRUDGE", "WHEN HIT, +60% DAMAGE FOR 4S", [{ "on": "on_damage_taken", "do": [["buff", "dmg", 0.6, 4.0]] }], ["fury"], "relic_heavy"],
	["lastbreath", "legend", "LAST BREATH", "BELOW HALF HEALTH: +100% DAMAGE, +30% FIRE RATE, +20% SPEED", [{ "on": "while_low_hp", "do": [["buff", "dmg", 1.0, 0], ["buff", "rate", 0.3, 0], ["buff", "speed", 0.2, 0]] }], ["fury"], "relic_glassheart"],
	["copperpenny", "common", "LUCKY PENNY", "KILLS HAVE 15% CHANCE TO PAY 1 GOLD", [{ "on": "on_kill", "chance": 0.15, "do": [["gold", 1]] }], ["fortune"], "relic_luckycoin"],
	["goldtongue", "rare", "GOLDEN TONGUE", "SHOPS 15% CHEAPER, +20% GOLD", [["add_cap", "shop_disc", 0.15, 0.6], ["mul", "gold_mult", 1.2]], ["fortune"], "relic_gildedtooth"],
	["ledgerofdebt", "rare", "LEDGER OF DEBTS", "+1% DAMAGE FOR EVERY 10 GOLD HELD", [["set", "miser", true]], ["fortune"], "relic_misers"],
	["dragonhoard", "legend", "DRAGON'S HOARD", "+12% DAMAGE PER 100 GOLD. CLEARING A ROOM PAYS 8 GOLD", [["hook", "gold_dmg", 0.12], { "on": "on_room_clear", "do": [["gold", 8]] }], ["fortune"], "relic_crown"],
	["evileye", "common", "EVIL EYE", "15% OF HITS CURSE FOES (+25% DAMAGE TAKEN)", [{ "on": "on_hit", "chance": 0.15, "do": [["status", "curse", 1]] }], ["malice"], "relic_huntersmark"],
	["bargain", "epic", "DEVIL'S BARGAIN", "+70% DAMAGE. -1 MAX HEART", [["mul", "dmg", 1.7], ["add_floor", "max_hp", -2, 2], ["clamp_max", "hp", "max_hp"]], ["malice"], "relic_hollowmirror"],
	["cursedcoin", "rare", "CURSED COIN", "+50% GOLD, BUT EACH ROOM COSTS HALF A HEART", [["mul", "gold_mult", 1.5], { "on": "on_room_enter", "do": [["hurt_self", 1]] }], ["malice", "fortune"], "relic_dice"],
	["voidheart", "legend", "VOID HEART", "CURSED FOES TAKE A 60% BONUS HIT FROM EVERYTHING. 25% OF HITS CURSE", [{ "on": "on_hit", "chance": 0.25, "do": [["status", "curse", 1]] }, { "on": "on_hit", "cd": 0.1, "if": "cursed", "do": [["damage", 0.6]] }], ["malice"], "relic_phoenix"],
	["wanderersmap", "common", "WANDERER'S MAP", "HIDDEN WALLS GLOW. +1 KEY", [["set", "reveal", true], ["add", "keys", 1]], [], "relic_chalk"],
	["emptyflask", "rare", "BOTTOMLESS FLASK", "+1 POTION SLOT. CLEARING A ROOM MAY DROP A POTION", [["add", "max_potions", 1], { "on": "on_room_clear", "chance": 0.25, "do": [["drop", "potion"]] }], [], "relic_keyring"],
	# ---------- Content batch 4 (step 8): relics ----------
	["marshreed", "common", "MARSH REED", "+1 POISON ON HIT", [["add", "poison", 1]], ["venom"], "relic_sap"],
	["warhorn", "common", "CRACKED WARHORN", "ENTERING A ROOM GIVES +25% FIRE RATE FOR 4S", [{ "on": "on_room_enter", "do": [["buff", "rate", 0.25, 4.0]] }], ["fury"], "relic_tinwhistle"],
	["prayerflag", "common", "PRAYER FLAG", "+1 MAX HEART", [["add", "max_hp", 2], ["add", "hp", 2]], ["bulwark"], "relic_chalk"],
	["snowglobe", "common", "SNOW GLOBE", "+15% CHILL CHANCE", [["add", "chill", 0.15]], ["frost"], "relic_moon"],
	["lockpick", "common", "BENT LOCKPICK", "+2 KEYS", [["add", "keys", 2]], ["fortune"], "relic_skeletonkey"],
	["spentcasing", "common", "SPENT CASING", "+8% FIRE RATE AND SHOT SPEED", [["mul", "rate", 1.08], ["mul", "shot_speed", 1.08]], ["edge"], "relic_shells"],
	["candlestub", "common", "CANDLE STUB", "+10% BURN CHANCE. BURNS LAST LONGER", [["add", "burn", 0.1], ["add", "burn_time", 0.5]], ["pyre"], "relic_tallow"],
	["ravenquill", "common", "RAVEN QUILL", "+10% MOVE SPEED", [["mul", "speed", 1.1]], ["shadow"], "relic_mothwing"],
	["copperspool", "common", "COPPER SPOOL", "ARCS JUMP ONE MORE TIME", [["add", "chain_jumps", 1]], ["storm"], "relic_filings"],
	["seedpouch", "common", "SEED POUCH", "+1 WISP", [["add", "familiars", 1]], ["swarm"], "relic_wispjar"],
	["rooftile", "common", "LOOSE ROOF TILE", "EVERY FLOOR STARTS WITH A FREE BOMB", [{ "on": "on_floor_start", "do": [["drop", "bomb"]] }], ["demolition"], "relic_rustynail"],
	["bogwater", "common", "JAR OF BOGWATER", "POISON DEALS +25% DAMAGE", [["add", "poison_dmg", 0.25]], ["venom"], "relic_bitterroot"],
	["stillpond", "rare", "STILL POND", "STANDING STILL, HITS DEAL +30%", [{ "on": "on_hit", "cd": 0.1, "if": "still", "do": [["damage", 0.3]] }], ["edge"], "relic_glasslens"],
	["bloodmoon", "rare", "BLOOD MOON", "BELOW HALF HEALTH: +35% DAMAGE", [{ "on": "while_low_hp", "do": [["buff", "dmg", 0.35, 0]] }], ["blood", "fury"], "relic_bloodoath"],
	["trophyteeth", "rare", "STRING OF TROPHY TEETH", "KILLING AN ELITE DROPS A HEART", [{ "on": "on_kill", "if": "elite", "do": [["drop", "heart"]] }], ["bulwark"], "relic_lantern"],
	["mudcharm", "rare", "MUD-CAKED CHARM", "ROLLING POISONS EVERY FOE NEAR YOU", [{ "on": "on_roll", "do": [["status_area", "poison", 2, 40]] }], ["venom", "shadow"], "relic_gravedust"],
	["ironwill", "rare", "IRON WILL", "WHEN HIT, GAIN 1 ARMOR (EVERY 10S)", [{ "on": "on_damage_taken", "cd": 10.0, "do": [["armor", 1]] }], ["bulwark"], "relic_boneshield"],
	["tailwind", "rare", "TAILWIND", "WHILE MOVING, HITS DEAL +20%", [{ "on": "on_hit", "cd": 0.1, "if": "moving", "do": [["damage", 0.2]] }], ["shadow"], "relic_sparrow"],
	["sparkgap", "rare", "SPARK GAP", "HITS ON SHOCKED FOES DEAL +20%", [{ "on": "on_hit", "cd": 0.1, "if": "shocked", "do": [["damage", 0.2]] }], ["storm"], "relic_staticcoil"],
	["frozentear", "rare", "FROZEN TEAR", "10% OF HITS ON CHILLED FOES SHATTER, HITTING ALL AROUND THEM", [{ "on": "on_hit", "chance": 0.1, "if": "chilled", "do": [["explode", 26, 0.8]] }], ["frost"], "relic_coldiron"],
	["fielddressing", "rare", "FIELD DRESSING", "CLEARING A ROOM HEALS HALF A HEART 25% OF THE TIME", [{ "on": "on_room_clear", "chance": 0.25, "do": [["heal", 1]] }], ["bulwark"], "relic_bramble"],
	["scavsack", "rare", "SCAVENGER'S SACK", "CLEARING A ROOM DROPS A POTION 12% OF THE TIME", [{ "on": "on_room_clear", "chance": 0.12, "do": [["drop", "potion"]] }], ["fortune"], "relic_misers"],
	["kindlingheart", "epic", "KINDLING HEART", "15% OF HITS ON BURNING FOES BURST IN FLAME", [{ "on": "on_hit", "chance": 0.15, "if": "burning", "do": [["explode", 22, 0.5]] }], ["pyre"], "relic_coal"],
	["rotgut", "epic", "ROTGUT FLASK", "20% OF HITS ON POISONED FOES MAKE THEM VULNERABLE", [{ "on": "on_hit", "chance": 0.2, "if": "poisoned", "do": [["status", "vulnerable", 1]] }], ["venom"], "relic_viper"],
	["stormglass", "epic", "STORM GLASS", "EVERY 5TH CRIT CALLS LIGHTNING", [{ "on": "on_crit", "every": 5, "do": [["lightning", 1.5]] }], ["storm", "edge"], "relic_spark"],
	["bladeoil", "rare", "BLADE OIL", "CRITS MAKE FOES BLEED", [{ "on": "on_crit", "do": [["status", "bleed", 1]] }], ["edge", "blood"], "relic_whetstone"],
	["queensjelly", "epic", "QUEEN'S JELLY", "WISPS DEAL +40%. 5% OF KILLS RAISE A WISP FOR 10S", [["add", "fam_dmg", 0.4], { "on": "on_kill", "chance": 0.05, "do": [["summon", 10.0]] }], ["swarm"], "relic_echo"],
	["nightshade", "rare", "NIGHTSHADE", "ROLLING CURSES THE NEAREST FOE", [{ "on": "on_roll", "do": [["status", "curse", 1]] }], ["malice", "shadow"], "relic_witcheye"],
	["towerbanner", "epic", "TOWER BANNER", "EVERY POINT OF ARMOR GIVES +4% DAMAGE", [["hook", "armor_dmg", 0.04]], ["bulwark"], "relic_buckler"],
	["heavypurse", "rare", "HEAVY PURSE", "+5% DAMAGE PER 100 GOLD HELD", [["hook", "gold_dmg", 0.05]], ["fortune"], "relic_luckycoin"],
	["blastingcaps", "rare", "BLASTING CAPS", "BOMBS DEAL +30% IN A 15% WIDER BLAST", [["mul", "bomb_mult", 1.3], ["mul", "bomb_r", 1.15]], ["demolition"], "relic_sapbomb"],
	["echostone", "epic", "ECHO STONE", "10% CHANCE FOR SHOTS TO CAST AGAIN", [["add", "echo", 0.1]], ["arcane"], "relic_ricochet"],
	["loadeddice", "epic", "LOADED DICE", "+2 LUCK. A QUARTER OF YOUR CRITS HIT AGAIN", [["add", "luck", 2], { "on": "on_crit", "chance": 0.25, "do": [["damage", 1.0]] }], ["fortune", "edge"], "relic_dice"],
	["shatteredcrown", "epic", "SHATTERED CROWN", "+40% DAMAGE, BUT -1 MAX HEART", [["mul", "dmg", 1.4], ["add_floor", "max_hp", -2, 2], ["clamp_max", "hp", "max_hp"]], ["malice"], "relic_glassheart"],
	["bloodtithe", "rare", "BLOOD TITHE", "+25% DAMAGE, BUT 2% OF KILLS COST HALF A HEART", [["mul", "dmg", 1.25], { "on": "on_kill", "chance": 0.02, "do": [["hurt_self", 1]] }], ["malice", "blood"], "relic_fever"],
	["hungeringedge", "epic", "HUNGERING EDGE", "+30% DAMAGE, BUT HALF THE ROOMS COST HALF A HEART", [["mul", "dmg", 1.3], { "on": "on_room_enter", "chance": 0.5, "do": [["hurt_self", 1]] }], ["malice", "fury"], "relic_rage"],
	["cursedcompass", "rare", "CURSED COMPASS", "+2 LUCK, BUT -10% MOVE SPEED", [["add", "luck", 2], ["mul", "speed", 0.9]], ["malice", "fortune"], "relic_lodestone"],
	["leadweight", "rare", "LEAD WEIGHT", "+30% DAMAGE, -15% FIRE RATE", [["mul", "dmg", 1.3], ["mul", "rate", 0.85]], ["fury"], "relic_heavy"],
	["voidpact", "epic", "VOID PACT", "+1 ROLL CHARGE AND ROLLS ERASE SHOTS, BUT -1 MAX HEART", [["add", "dodge_charges", 1], ["add", "charges", 1], ["add_floor", "max_hp", -2, 2], ["clamp_max", "hp", "max_hp"], { "on": "on_roll", "do": [["clear_shots", 36]] }], ["malice", "shadow"], "relic_hollowmirror"],
	["warfletching", "rare", "WAR FLETCHING", "+1 PROJECTILE, -10% DAMAGE", [["add", "count", 1], ["mul", "dmg", 0.9]], ["arcane"], "relic_arrowhead"],
	["monasterybell", "rare", "MONASTERY BELL", "ENTERING A ROOM CHILLS EVERY FOE NEAR YOU", [{ "on": "on_room_enter", "do": [["status_area", "chill", 1, 90]] }], ["frost"], "relic_owl"],
	["alleycateye", "rare", "ALLEY CAT'S EYE", "+10% CRIT CHANCE, 5% DODGE CHANCE", [["add", "crit", 0.1], ["add", "evade", 0.05]], ["shadow", "edge"], "relic_seeker"],
	["eclipseshard", "epic", "ECLIPSE SHARD", "IN A FIGHT, EVERY 10S CURSE AND WEAKEN EVERY FOE NEAR YOU", [{ "on": "every_n_seconds", "period": 10.0, "if": "fighting", "do": [["status_area", "curse", 1, 90], ["status_area", "weakened", 1, 90], ["vfx", "ring", "#a35bd6", 90]] }], ["malice"], "relic_overcharge"],
	["fallenstar", "legend", "HEART OF A FALLEN STAR", "+1 MAX HEART. EVERY 4TH ATTACK FIRES A RING OF 12 STARS", [["add", "max_hp", 2], ["add", "hp", 2], { "on": "every_n_shots", "every": 4, "do": [["nova", 12, 0.7, "spark"]] }], ["arcane"], "relic_sigil"],
	["crownofash", "legend", "CROWN OF ASH", "EVERY HIT BURNS. BURNING FOES TAKE +30% DAMAGE", [["add", "burn", 1.0], ["add", "vs_burn", 0.3]], ["pyre"], "relic_crown"],
	["mirroredsoul", "legend", "MIRRORED SOUL", "30% CHANCE FOR SHOTS TO CAST AGAIN", [["add", "echo", 0.3]], ["arcane"], "relic_deepeye"],
	["kingsransom", "legend", "KING'S RANSOM", "+100 GOLD NOW. +15% DAMAGE PER 100 GOLD HELD", [["add", "gold", 100], ["hook", "gold_dmg", 0.15]], ["fortune"], "relic_gildedtooth"],
	["undyingember", "legend", "EMBER OF THE UNDYING", "RISE TWICE MORE THIS RUN", [["add", "revive", 2]], ["bulwark"], "relic_phoenix"],
	["thundertorc", "legend", "THUNDERLORD'S TORC", "15% OF HITS CALL LIGHTNING", [{ "on": "on_hit", "chance": 0.15, "cd": 0.05, "do": [["lightning", 1.0]] }], ["storm"], "relic_stormcrown"],
	["hivecrown", "legend", "CROWN OF THE HIVE", "+3 WISPS. WISPS FIRE 30% FASTER", [["add", "familiars", 3], ["mul", "fam_rate", 1.3]], ["swarm"], "relic_twinwisp"],
	["redgodidol", "legend", "IDOL OF THE RED GOD", "+20% DAMAGE. 10% OF KILLS HEAL HALF A HEART", [["mul", "dmg", 1.2], { "on": "on_kill", "chance": 0.1, "do": [["heal", 1]] }], ["blood"], "relic_garnet"],
	# ---------- Rogues layer: attribute relics ----------
	["tonicmight", "rare", "TONIC OF MIGHT", "+2 STR", [["attr", "str", 2]], ["fury"], "relic_rage"],
	["quickdraught", "rare", "QUICKENING DRAUGHT", "+2 DEX", [["attr", "dex", 2]], ["shadow"], "relic_sparrow"],
	["sagesink", "rare", "SAGE'S INK", "+2 INT", [["attr", "int", 2]], ["arcane"], "relic_owl"],
	["heavennectar", "epic", "HEAVENLY NECTAR", "+1 TO YOUR HIGHEST ATTRIBUTE. +1 MAX HEART", [["attr", "highest", 1], ["add", "max_hp", 2], ["add", "hp", 2]], ["bulwark"], "relic_worldseed"],
	["balancestone", "epic", "STONE OF BALANCE", "+1 STR, +1 DEX, +1 INT", [["attr", "str", 1], ["attr", "dex", 1], ["attr", "int", 1]], ["arcane"], "relic_lodestone"],
]
const BASE_COUNT := 34
const CACHE_1 := ["tallow", "skeletonkey", "quiver", "filings", "gravedust", "mothwing", "bitterroot", "tinwhistle", "chalk", "rustynail"]
const CACHE_2 := ["wispjar", "emberheart", "boneshield", "huntersmark", "glasslens", "staticcoil", "bloodoath", "ricochet", "misers", "shadowstep", "coldiron", "splinter"]
const CACHE_3 := ["phoenix", "twinwisp", "stormcrown", "hollowmirror", "gildedtooth", "overcharge", "deepeye", "cindercrown", "ageglass", "worldseed"]

## Rarity weights per source.
const LOOT := {
	"chest": { "common": 60, "rare": 30, "epic": 9, "legend": 1 }, "shop": { "common": 55, "rare": 35, "epic": 9, "legend": 1 },
	"iron": { "common": 15, "rare": 45, "epic": 30, "legend": 10 }, "boss": { "common": 20, "rare": 45, "epic": 28, "legend": 7 },
	"secret": { "common": 25, "rare": 40, "epic": 25, "legend": 10 }, "cursed": { "common": 0, "rare": 30, "epic": 50, "legend": 20 },
	"altar": { "common": 30, "rare": 45, "epic": 20, "legend": 5 },
}

static var _list: Array = []
static var _by_id := {}

static func all() -> Array:
	if _list.is_empty():
		# --classic: original items only (proves the originals play exactly as before).
		for i in (ORIGINAL_COUNT if DebugArgs.has("classic") else ROWS.size()):
			var row: Array = ROWS[i]
			var r := { "id": row[0], "rarity": row[1], "name": row[2], "desc": row[3], "effects": row[4],
				"tags": row[5] if row.size() > 5 else [], "new": i >= ORIGINAL_COUNT,
				"sprite": row[6] if row.size() > 6 else "relic_" + row[0] }
			_list.append(r)
			_by_id[r["id"]] = r
	return _list

static func by_id(id: String) -> Dictionary:
	all()
	return _by_id[id]

static func base_ids() -> Array:
	var out := []
	for i in BASE_COUNT:
		out.append(ROWS[i][0])
	return out

## New-content relic ids (always in the pool).
static func new_ids() -> Array:
	var out := []
	for r in all():
		if r["new"]:
			out.append(r["id"])
	return out

static func apply(id: String, p: Player) -> void:
	Effects.apply(p, by_id(id)["effects"], 1, "relic:" + id)
