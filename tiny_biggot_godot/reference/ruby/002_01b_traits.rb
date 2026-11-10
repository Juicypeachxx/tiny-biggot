# Tiny Biggot - level-up traits, build families and hero skill trees. All original designs.
# Each trait pick applies its effect once; picking it again stacks another rank.

FAMILIES = {
  core: { name: "CORE", col: "tan", hex: "#c9c2a8" },
  pyre: { name: "PYRE", col: "orange", hex: "#e8873a" },
  frost: { name: "FROST", col: "cyan", hex: "#6fd3e0" },
  venom: { name: "VENOM", col: "lime", hex: "#b8e05a" },
  storm: { name: "STORM", col: "cyan", hex: "#4d9be6" },
  blood: { name: "BLOOD", col: "red", hex: "#d8443c" },
  bulwark: { name: "BULWARK", col: "grey", hex: "#8b8f9c" },
  shadow: { name: "SHADOW", col: "purple", hex: "#a35bd6" },
  arcane: { name: "ARCANE", col: "pink", hex: "#e86fb4" },
  fortune: { name: "FORTUNE", col: "gold", hex: "#f2c94c" },
  demolition: { name: "DEMOLITION", col: "orange", hex: "#d8443c" },
  swarm: { name: "SWARM", col: "gold", hex: "#e8873a" },
}

# Family bonuses unlock at 2, 4 and 6 total ranks in that family.
FAMILY_BONUS = {
  pyre: [["+10% BURN CHANCE", lambda { |p| p[:burn] += 0.1 }], ["BURNS DEAL +50% DAMAGE", lambda { |p| p[:burn_dmg] += 0.5 }], ["BURNING FOES TAKE +25% DAMAGE", lambda { |p| p[:vs_burn] += 0.25 }]],
  frost: [["+10% CHILL CHANCE", lambda { |p| p[:chill] += 0.1 }], ["CHILLED FOES TAKE +15% DAMAGE", lambda { |p| p[:vs_chill] += 0.15 }], ["KILLS CHILL NEARBY FOES", lambda { |p| p[:chill_spread] = true }]],
  venom: [["+1 POISON ON HIT", lambda { |p| p[:poison] += 1 }], ["POISON TICKS TWICE AS FAST", lambda { |p| p[:poison_fast] = true }], ["POISON DAMAGE +60%", lambda { |p| p[:poison_dmg] += 0.6 }]],
  storm: [["+10% CHAIN CHANCE", lambda { |p| p[:chain] += 0.1 }], ["LIGHTNING DEALS +50% DAMAGE", lambda { |p| p[:storm_dmg] += 0.5 }], ["HITS HAVE 8% CHANCE TO CALL LIGHTNING", lambda { |p| p[:storm] += 0.08 }]],
  blood: [["+5% CRIT CHANCE", lambda { |p| p[:crit] += 0.05 }], ["CRITS DEAL +0.5X MORE", lambda { |p| p[:crit_mult] += 0.5 }], ["CRITS PIERCE THROUGH FOES", lambda { |p| p[:crit_pierce] = true }]],
  bulwark: [["+10 THORN DAMAGE", lambda { |p| p[:thorns] += 10 }], ["+1 ARMOR AFTER EACH ROOM", lambda { |p| p[:armor_regen] += 1 }], ["20% CHANCE TO IGNORE A HIT", lambda { |p| p[:evade] += 0.2 }]],
  shadow: [["ROLL RECHARGES 15% FASTER", lambda { |p| p[:dodge_cd] *= 0.85 }], ["ROLLING THROUGH FOES DAMAGES THEM", lambda { |p| p[:shadowstep] = true }], ["+50% DAMAGE FOR 1S AFTER A ROLL", lambda { |p| p[:post_roll] = true }]],
  arcane: [["+1 ORBITING MOON", lambda { |p| p[:orbitals] += 1 }], ["SHOTS HOME IN", lambda { |p| p[:homing] += 2.0 }], ["+1 PROJECTILE", lambda { |p| p[:count] += 1 }]],
  fortune: [["+10% GOLD", lambda { |p| p[:gold_mult] *= 1.1 }], ["BETTER RELIC RARITY", lambda { |p| p[:luck] += 1 }], ["+25% DAMAGE", lambda { |p| p[:dmg] *= 1.25 }]],
  demolition: [["BOMBS +25% DAMAGE", lambda { |p| p[:bomb_mult] *= 1.25 }], ["10% OF SHOTS EXPLODE", lambda { |p| p[:shrapnel] += 0.1 }], ["EXPLOSIONS DEAL DOUBLE TO ELITES", lambda { |p| p[:boom_elite] = true }]],
  swarm: [["+1 WISP", lambda { |p| p[:familiars] += 1 }], ["WISPS DEAL +50% DAMAGE", lambda { |p| p[:fam_dmg] += 0.5 }], ["WISPS FIRE TWO SHOTS", lambda { |p| p[:fam_multi] = 2 }]],
}

def trait(id, fam, max, name, desc, fx, cap = false)
  { id: id, fam: fam, max: max, name: name, desc: desc, fx: fx, cap: cap }
end

TRAITS = [
  # Core
  trait("vitality", :core, 3, "VITALITY", "+1 MAX HEART, HEAL 1 HEART", lambda { |p| p[:max_hp] += 2; p[:hp] = [p[:max_hp], p[:hp] + 2].min }),
  trait("might", :core, 5, "MIGHT", "+12% DAMAGE", lambda { |p| p[:dmg] *= 1.12 }),
  trait("haste", :core, 5, "HASTE", "+10% FIRE RATE", lambda { |p| p[:rate] *= 1.1 }),
  trait("swiftness", :core, 3, "SWIFTNESS", "+8% MOVE SPEED", lambda { |p| p[:speed] *= 1.08 }),
  trait("reach", :core, 3, "REACH", "+15% RANGE AND SHOT SPEED", lambda { |p| p[:life] *= 1.15; p[:shot_speed] *= 1.15 }),
  trait("precision", :core, 4, "PRECISION", "+6% CRIT CHANCE", lambda { |p| p[:crit] += 0.06 }),
  # Pyre
  trait("kindling", :pyre, 3, "KINDLING", "+15% CHANCE TO BURN", lambda { |p| p[:burn] += 0.15 }),
  trait("searing", :pyre, 3, "SEARING", "BURNS DEAL +40% DAMAGE", lambda { |p| p[:burn_dmg] += 0.4 }),
  trait("wildfire", :pyre, 2, "WILDFIRE", "BURNS LAST LONGER AND LEAP TO NEARBY FOES", lambda { |p| p[:burn_time] += 1.0; p[:burn_leap] += 0.2 }),
  trait("smoulder", :pyre, 3, "SMOULDER", "+10% DAMAGE TO BURNING FOES", lambda { |p| p[:vs_burn] += 0.1 }),
  trait("flametrail", :pyre, 2, "FLAME TRAIL", "ROLLING LEAVES A TRAIL OF FIRE", lambda { |p| p[:fire_trail] += 1 }),
  trait("inferno", :pyre, 1, "INFERNO", "BURNING FOES EXPLODE ON DEATH AND SET OTHERS ABLAZE", lambda { |p| p[:inferno] = true }, true),
  # Frost
  trait("chillbite", :frost, 3, "CHILLBITE", "+15% CHANCE TO CHILL", lambda { |p| p[:chill] += 0.15 }),
  trait("deepcold", :frost, 2, "DEEP COLD", "CHILL LASTS LONGER AND SLOWS MORE", lambda { |p| p[:chill_time] += 1.0; p[:chill_slow] = [0.2, p[:chill_slow] - 0.12].max }),
  trait("frostbite", :frost, 3, "FROSTBITE", "+12% DAMAGE TO CHILLED FOES", lambda { |p| p[:vs_chill] += 0.12 }),
  trait("icearmor", :frost, 1, "ICE ARMOR", "TAKING A HIT CHILLS EVERY FOE NEARBY", lambda { |p| p[:ice_armor] = true }),
  trait("glacial", :frost, 2, "GLACIAL LANCE", "EVERY 5TH SHOT IS A PIERCING ICE LANCE", lambda { |p| p[:lance_n] = p[:lance_n] == 0 ? 5 : [3, p[:lance_n] - 1].max }),
  trait("shatter", :frost, 1, "SHATTER", "CHILLED FOES BELOW 30% HEALTH SHATTER INTO ICE", lambda { |p| p[:shatter] = true }, true),
  # Venom
  trait("toxin", :venom, 3, "TOXIN", "HITS ADD +1 POISON", lambda { |p| p[:poison] += 1 }),
  trait("virulence", :venom, 3, "VIRULENCE", "POISON DEALS +35% DAMAGE", lambda { |p| p[:poison_dmg] += 0.35 }),
  trait("corrode", :venom, 2, "CORRODE", "POISONED FOES TAKE +3% DAMAGE PER STACK", lambda { |p| p[:corrode] += 0.03 }),
  trait("toxiccloud", :venom, 2, "NOXIOUS CLOUD", "KILLS LEAVE A POISON CLOUD", lambda { |p| p[:cloud] += 1 }),
  trait("barbs", :venom, 2, "BARBS", "20% CHANCE TO FIRE AN EXTRA POISON DART", lambda { |p| p[:barbs] += 0.2 }),
  trait("plague", :venom, 1, "PLAGUE", "POISON SPREADS WITH ALL ITS STACKS WHEN A FOE DIES", lambda { |p| p[:plague] = true }, true),
  # Storm
  trait("static", :storm, 3, "STATIC", "+12% CHANCE FOR HITS TO ARC", lambda { |p| p[:chain] += 0.12 }),
  trait("conductor", :storm, 2, "CONDUCTOR", "ARCS JUMP TO 1 MORE FOE", lambda { |p| p[:chain_jumps] += 1 }),
  trait("overload", :storm, 3, "OVERLOAD", "ARCS AND LIGHTNING DEAL +40% DAMAGE", lambda { |p| p[:storm_dmg] += 0.4 }),
  trait("thunderclap", :storm, 2, "THUNDERCLAP", "EVERY 8TH SHOT CALLS LIGHTNING", lambda { |p| p[:thunder_n] = p[:thunder_n] == 0 ? 8 : 5 }),
  trait("livewire", :storm, 2, "LIVE WIRE", "+10% FIRE RATE, +5% MOVE SPEED", lambda { |p| p[:rate] *= 1.1; p[:speed] *= 1.05 }),
  trait("tempest", :storm, 1, "TEMPEST", "EVERY 3 SECONDS, LIGHTNING STRIKES 3 FOES", lambda { |p| p[:tempest] = true }, true),
  # Blood
  trait("keenedge", :blood, 3, "KEEN EDGE", "+7% CRIT CHANCE", lambda { |p| p[:crit] += 0.07 }),
  trait("carnage", :blood, 3, "CARNAGE", "CRITS DEAL +0.35X MORE", lambda { |p| p[:crit_mult] += 0.35 }),
  trait("vampiric", :blood, 2, "VAMPIRIC", "CRITS HAVE 4% CHANCE TO HEAL", lambda { |p| p[:crit_heal] += 0.04 }),
  trait("desperation", :blood, 2, "DESPERATION", "+10% DAMAGE FOR EACH MISSING HEART", lambda { |p| p[:desperate] += 0.1 }),
  trait("lacerate", :blood, 2, "LACERATE", "CRITS MAKE FOES BLEED", lambda { |p| p[:bleed] += 1 }),
  trait("sanguine", :blood, 1, "SANGUINE FRENZY", "EACH KILL GIVES +4% DAMAGE UNTIL THE ROOM ENDS", lambda { |p| p[:sanguine] = true }, true),
  # Bulwark
  trait("plating", :bulwark, 3, "PLATING", "+1 ARMOR", lambda { |p| p[:armor] += 1 }),
  trait("spikes", :bulwark, 3, "SPIKED HIDE", "+10 THORN DAMAGE", lambda { |p| p[:thorns] += 10 }),
  trait("ironskin", :bulwark, 1, "IRON SKIN", "START EACH ROOM WITH AT LEAST 1 ARMOR", lambda { |p| p[:ironskin] = true }),
  trait("shieldbash", :bulwark, 2, "SHIELD BASH", "ROLLING INTO FOES HITS HARDER WITH MORE ARMOR", lambda { |p| p[:bash] += 1; p[:shadowstep] = true }),
  trait("fortress", :bulwark, 2, "FORTRESS", "+8% DAMAGE PER ARMOR (UP TO 5)", lambda { |p| p[:fortress] += 0.08 }),
  trait("unbreakable", :bulwark, 1, "UNBREAKABLE", "WHEN ARMOR BREAKS, RELEASE A NOVA AND ERASE NEARBY SHOTS", lambda { |p| p[:unbreakable] = true }, true),
  # Shadow
  trait("fleet", :shadow, 2, "FLEET", "+1 ROLL CHARGE", lambda { |p| p[:dodge_charges] += 1; p[:charges] += 1 }),
  trait("ambush", :shadow, 3, "AMBUSH", "AFTER A ROLL, YOUR NEXT SHOTS CRIT", lambda { |p| p[:ambush] += 2 }),
  trait("phantom", :shadow, 2, "PHANTOM", "ROLLS GO FURTHER AND KEEP YOU SAFE LONGER", lambda { |p| p[:roll_speed] *= 1.15; p[:roll_time] += 0.06 }),
  trait("evasion", :shadow, 3, "EVASION", "8% CHANCE TO DODGE A HIT", lambda { |p| p[:evade] += 0.08 }),
  trait("smoke", :shadow, 1, "SMOKE BOMB", "ROLLING LEAVES SMOKE THAT ERASES SHOTS", lambda { |p| p[:smoke] = true }),
  trait("nightfall", :shadow, 1, "NIGHTFALL", "ROLL STRIKES DEAL HEAVY DAMAGE AND KILLS REFUND THE ROLL", lambda { |p| p[:nightfall] = true; p[:shadowstep] = true }, true),
  # Arcane
  trait("multicast", :arcane, 2, "MULTICAST", "+1 PROJECTILE, -10% DAMAGE", lambda { |p| p[:count] += 1; p[:dmg] *= 0.9 }),
  trait("seeking", :arcane, 2, "SEEKING", "SHOTS HOME IN", lambda { |p| p[:homing] += 2.0 }),
  trait("orbit", :arcane, 2, "ORBIT", "+1 ORBITING MOON", lambda { |p| p[:orbitals] += 1 }),
  trait("spellweave", :arcane, 3, "SPELLWEAVE", "+15% SHOT SIZE AND DAMAGE", lambda { |p| p[:size] *= 1.15; p[:dmg] *= 1.15 }),
  trait("rebound", :arcane, 2, "REBOUND", "SHOTS BOUNCE OFF WALLS", lambda { |p| p[:bounce] += 1 }),
  trait("echo", :arcane, 1, "ARCANE ECHO", "30% CHANCE FOR EVERY SHOT TO CAST AGAIN", lambda { |p| p[:echo] += 0.3 }, true),
  # Fortune
  trait("prospector", :fortune, 3, "PROSPECTOR", "+20% GOLD", lambda { |p| p[:gold_mult] *= 1.2 }),
  trait("haggler", :fortune, 3, "HAGGLER", "SHOPS 10% CHEAPER", lambda { |p| p[:shop_disc] = [0.6, p[:shop_disc] + 0.1].min }),
  trait("luckyfind", :fortune, 3, "LUCKY FIND", "BETTER RELIC RARITY", lambda { |p| p[:luck] += 1 }),
  trait("interest", :fortune, 2, "INTEREST", "GAIN 8% OF YOUR GOLD AFTER EACH ROOM", lambda { |p| p[:interest] += 0.08 }),
  trait("jackpot", :fortune, 1, "JACKPOT", "ELITES AND GUARDIANS SHOWER GEMS", lambda { |p| p[:jackpot] = true }),
  trait("midas", :fortune, 1, "MIDAS TOUCH", "+1% DAMAGE FOR EVERY 5 GOLD HELD", lambda { |p| p[:midas] = true }, true),
  # Demolition
  trait("satchel", :demolition, 3, "SATCHEL", "+2 BOMBS", lambda { |p| p[:bombs] += 2 }),
  trait("blastradius", :demolition, 3, "BLAST RADIUS", "BOMBS +30% RADIUS AND DAMAGE", lambda { |p| p[:bomb_mult] *= 1.3; p[:bomb_r] *= 1.15 }),
  trait("shrapnel", :demolition, 3, "SHRAPNEL", "12% OF SHOTS EXPLODE ON HIT", lambda { |p| p[:shrapnel] += 0.12 }),
  trait("sapper", :demolition, 1, "SAPPER", "GAIN 1 BOMB AFTER EACH ROOM", lambda { |p| p[:sapper] += 1 }),
  trait("fusemaster", :demolition, 1, "FUSE MASTER", "YOUR BOMBS NO LONGER HURT YOU AND BLOW FASTER", lambda { |p| p[:fuse] = true }),
  trait("cluster", :demolition, 1, "CLUSTER CHARGE", "BOMBS BURST INTO 4 MORE BOMBS", lambda { |p| p[:cluster] = true }, true),
  # Swarm
  trait("wispcall", :swarm, 3, "WISP CALL", "+1 WISP FOLLOWS YOU", lambda { |p| p[:familiars] += 1 }),
  trait("packtactics", :swarm, 3, "PACK TACTICS", "WISPS DEAL +40% DAMAGE", lambda { |p| p[:fam_dmg] += 0.4 }),
  trait("feral", :swarm, 2, "FERAL", "WISPS SHOOT 25% FASTER", lambda { |p| p[:fam_rate] *= 1.25 }),
  trait("carrion", :swarm, 2, "CARRION", "KILLS HAVE 10% CHANCE TO RAISE A SPIRIT", lambda { |p| p[:carrion] += 0.1 }),
  trait("hive", :swarm, 1, "HIVE", "+1 ORBITING MOON AND +1 WISP", lambda { |p| p[:orbitals] += 1; p[:familiars] += 1 }),
  trait("legion", :swarm, 1, "LEGION", "EVERY 5 KILLS SUMMON A TEMPORARY WISP", lambda { |p| p[:legion] = true }, true),
]
TRAIT_BY_ID = {}
TRAITS.each { |t| TRAIT_BY_ID[t[:id]] = t }

def xp_needed(level); (10 + 7 * (level ** 1.35)).round; end

ENEMY_XP = { "bat" => 2, "slime" => 3, "slimelet" => 1, "skeleton" => 3, "mushroom" => 3, "cultist" => 4, "imp" => 3,
             "knight" => 6, "ghost" => 3, "bookwyrm" => 3, "drowned" => 4, "wisp" => 3, "golem" => 7 }

# Room choice: rewards shown on each door before you pick it.
REWARDS = {
  relic: { name: "RELIC", icon: "chest", col: "gold" }, gold: { name: "GOLD", icon: "gem", col: "gold" },
  heal: { name: "HEALING", icon: "heartPick", col: "pink" }, supply: { name: "BOMBS + KEY", icon: "bomb", col: "white" },
  armor: { name: "ARMOR", icon: "armor", col: "cyan" }, level: { name: "LEVEL UP", icon: "icon_level", col: "lime" },
  embers: { name: "EMBERS", icon: "ember", col: "orange" }, rare: { name: "IRON CHEST", icon: "chestIron", col: "cyan" },
}
ROOM_KINDS = {
  "combat" => { name: "FIGHT", icon: "icon_combat", col: "white" }, "elite" => { name: "ELITE FIGHT", icon: "icon_elite", col: "red" },
  "treasure" => { name: "TREASURE", icon: "chest", col: "gold" }, "shop" => { name: "SHOP", icon: "icon_shop", col: "green" },
  "shrine" => { name: "SHRINE", icon: "icon_shrine", col: "purple" }, "challenge" => { name: "CHALLENGE", icon: "bell", col: "cyan" },
  "vault" => { name: "VAULT", icon: "lock", col: "orange" }, "secret" => { name: "HIDDEN ROOM", icon: "icon_secret", col: "pink" },
  "boss" => { name: "GUARDIAN", icon: "icon_skull", col: "red" }, "rest" => { name: "CAMPFIRE", icon: "icon_fire", col: "orange" },
}

# Hero skill trees: three branches of four nodes. The last node of the third branch is each hero's signature perk.
TREE_COSTS = [10, 20, 35, 60]
SKILL_BRANCHES = [
  { name: "MIGHT", nodes: [
    ["SHARPENED", "+10% DAMAGE", lambda { |p| p[:dmg] *= 1.1 }],
    ["QUICK HANDS", "+10% FIRE RATE", lambda { |p| p[:rate] *= 1.1 }],
    ["TRAINED EYE", "+8% CRIT CHANCE", lambda { |p| p[:crit] += 0.08 }],
    ["HEIRLOOM", "START WITH A RANDOM RARE RELIC", lambda { |p| p[:start_rare] = true }]] },
  { name: "SURVIVAL", nodes: [
    ["HARDY", "+1 MAX HEART", lambda { |p| p[:max_hp] += 2; p[:hp] += 2 }],
    ["PADDED", "START WITH 1 ARMOR", lambda { |p| p[:armor] += 1 }],
    ["NIMBLE", "+1 ROLL CHARGE", lambda { |p| p[:dodge_charges] += 1; p[:charges] += 1 }],
    ["SECOND WIND", "ONCE PER RUN, SURVIVE A KILLING BLOW", lambda { |p| p[:revive] += 1 }]] },
]
HERO_BRANCH = {
  "hexer" => { name: "HEXCRAFT", nodes: [
    ["CURVING HEX", "HEX BOLTS TURN HARDER", lambda { |p| p[:homing] += 0.8 }],
    ["MALEDICT", "20% CHANCE TO CURSE: CURSED FOES TAKE +25%", lambda { |p| p[:curse] += 0.2 }],
    ["PIERCING HEX", "+1 PIERCE", lambda { |p| p[:pierce] += 1 }],
    ["HEX BLOOM", "BOLTS SPLIT IN TWO ON THEIR FIRST HIT", lambda { |p| p[:bloom] = true }]] },
  "poacher" => { name: "MARKSMAN", nodes: [
    ["LONG SHOT", "+10% SHOT SPEED AND RANGE", lambda { |p| p[:shot_speed] *= 1.1; p[:life] *= 1.1 }],
    ["HEAVY BOLT", "EVERY 6TH BOLT DEALS TRIPLE DAMAGE", lambda { |p| p[:heavy_n] = 6 }],
    ["SLICK RELOAD", "ROLLING RELOADS INSTANTLY", lambda { |p| p[:roll_reload] = true }],
    ["VOLLEY", "+2 BOLTS IN A TIGHT SPREAD", lambda { |p| p[:count] += 2 }]] },
  "brute" => { name: "BERSERKER", nodes: [
    ["THICK HIDE", "+2 MAX HEARTS", lambda { |p| p[:max_hp] += 4; p[:hp] += 4 }],
    ["CONCUSS", "HATCHETS HAVE 20% CHANCE TO STUN", lambda { |p| p[:stun] += 0.2 }],
    ["FRESH BLOOD", "+25% DAMAGE AT FULL HEALTH", lambda { |p| p[:full_hp_dmg] += 0.25 }],
    ["BLOOD RAGE", "BELOW HALF HEALTH: +40% RATE, +20% SPEED", lambda { |p| p[:blood_rage] = true }]] },
  "gravedigger" => { name: "UNDERTAKER", nodes: [
    ["FISTFUL", "+1 CLOD PER THROW", lambda { |p| p[:count] += 1 }],
    ["SPARE POWDER", "GAIN 1 BOMB AFTER EACH ROOM", lambda { |p| p[:sapper] += 1 }],
    ["BURY", "CLODS HAVE 15% CHANCE TO STUN", lambda { |p| p[:stun] += 0.15 }],
    ["GRAVE HARVEST", "BOMB KILLS DROP BOMBS AND HEARTS", lambda { |p| p[:harvest] = true }]] },
  "alchemist" => { name: "TRANSMUTER", nodes: [
    ["POTENT BREW", "+1 POISON ON HIT", lambda { |p| p[:poison] += 1 }],
    ["WIDE SPLASH", "FLASK BURSTS 40% BIGGER", lambda { |p| p[:splash] += 0.4 }],
    ["ELIXIR", "POTIONS HEAL MORE AND MAKE YOU SAFE FOR 3S", lambda { |p| p[:potion_heal] += 2; p[:elixir] = true }],
    ["VOLATILE MIX", "POISONED FOES EXPLODE ON DEATH", lambda { |p| p[:volatile] = true }]] },
  "warden" => { name: "LAMPLIGHTER", nodes: [
    ["BRIGHT FLAME", "+20% LANTERN SIZE", lambda { |p| p[:size] *= 1.2 }],
    ["KINDLED", "LANTERN HITS OFTEN BURN", lambda { |p| p[:burn] += 0.35 }],
    ["HOMEWARD", "THE LANTERN HITS TWICE AS HARD ON ITS WAY BACK", lambda { |p| p[:back_dmg] = true }],
    ["TWIN FLAME", "THROW TWO LANTERNS AT ONCE", lambda { |p| p[:count] += 1; p[:spread] = 0.35 }]] },
}

def tree_for(hero_id); SKILL_BRANCHES + [HERO_BRANCH[hero_id]]; end
