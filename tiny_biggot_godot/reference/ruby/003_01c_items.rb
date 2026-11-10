# Tiny Biggot - weapons and equipment. Every item is an original design with its own ability.
# Stat tuples [key, value] are applied while an item is equipped and removed when it is unequipped:
# keys in MUL_KEYS multiply, all others add. Hooks [key, value] turn on special behaviours (see 03b_items.rb).

MUL_KEYS = [:dmg, :rate, :shot_speed, :life, :size, :speed, :dodge_cd, :gold_mult, :roll_speed, :bomb_mult, :bomb_r, :xp_mult, :fam_rate]

TAG_COLS = {
  pyre: ["#e8873a", "#d8443c", "#f2c94c"], frost: ["#6fd3e0", "#4d9be6", "#ffffff"], venom: ["#b8e05a", "#2f6b3a", "#f4ffd0"],
  storm: ["#4d9be6", "#2b4f8a", "#c8f0ff"], blood: ["#d8443c", "#8a2a33", "#ff8a8a"], bulwark: ["#8b8f9c", "#4e4a5e", "#f4ecd8"],
  shadow: ["#a35bd6", "#5c3483", "#e8c8ff"], arcane: ["#e86fb4", "#a35bd6", "#ffffff"], fortune: ["#f2c94c", "#e8873a", "#fffbe0"],
  demolition: ["#8b8f9c", "#1a1423", "#e8873a"], swarm: ["#f2c94c", "#7a5236", "#fffbe0"], core: ["#c9c2a8", "#8b8f9c", "#ffffff"],
}

# Attack types. Defaults are overridden per weapon.
ARCH = {
  bolt: { name: "BOW", dmg: 3.0, rate: 4.0, speed: 250, life: 0.8, size: 1.0, pierce: 0, count: 1, spread: 0.12, homing: 0.0 },
  orb: { name: "STAFF", dmg: 4.0, rate: 3.0, speed: 150, life: 1.0, size: 1.0, pierce: 0, count: 1, spread: 0.2, homing: 2.2 },
  spin: { name: "THROWN AXE", dmg: 8.0, rate: 1.8, speed: 180, life: 0.72, size: 1.6, pierce: 2, count: 1, spread: 0.3, homing: 0.0 },
  shot: { name: "SCATTERGUN", dmg: 2.4, rate: 2.2, speed: 220, life: 0.5, size: 1.0, pierce: 0, count: 4, spread: 0.16, homing: 0.0 },
  flask: { name: "FLASK", dmg: 5.0, rate: 2.0, speed: 160, life: 0.85, size: 1.0, pierce: 0, count: 1, spread: 0.3, homing: 0.0 },
  boomer: { name: "BOOMERANG", dmg: 4.5, rate: 2.0, speed: 210, life: 0.9, size: 1.2, pierce: 99, count: 1, spread: 0.35, homing: 0.0 },
  slash: { name: "SWORD", dmg: 7.0, rate: 2.2, speed: 0, life: 0, size: 1.0, pierce: 99, count: 1, spread: 0, homing: 0.0, range: 34, arc: 110 },
  thrust: { name: "SPEAR", dmg: 6.0, rate: 2.4, speed: 0, life: 0, size: 1.0, pierce: 99, count: 1, spread: 0.3, homing: 0.0, range: 58, width: 8 },
  beam: { name: "RAY", dmg: 1.4, rate: 10.0, speed: 0, life: 0, size: 1.0, pierce: 0, count: 1, spread: 0, homing: 0.0, range: 140 },
  flame: { name: "SPRAYER", dmg: 1.0, rate: 14.0, speed: 150, life: 0.35, size: 0.8, pierce: 99, count: 1, spread: 0.25, homing: 0.0 },
  disc: { name: "DISC", dmg: 4.0, rate: 2.0, speed: 200, life: 1.6, size: 1.2, pierce: 1, count: 1, spread: 0.4, homing: 0.0, bounce: 3 },
  pulse: { name: "ORB", dmg: 3.8, rate: 0.9, speed: 60, life: 2.5, size: 1.4, pierce: 99, count: 1, spread: 0, homing: 0.0 },
  zap: { name: "RUNE", dmg: 4.0, rate: 2.5, speed: 0, life: 0, size: 1.0, pierce: 0, count: 1, spread: 0, homing: 0.0, range: 130, chain: 2 },
  nova: { name: "CHIME", dmg: 3.0, rate: 1.4, speed: 180, life: 0.6, size: 1.0, pierce: 0, count: 10, spread: 0, homing: 0.0 },
  mine: { name: "TRAP", dmg: 14.0, rate: 1.5, speed: 0, life: 8.0, size: 1.0, pierce: 0, count: 1, spread: 0, homing: 0.0 },
  rail: { name: "RAILSHOT", dmg: 14.0, rate: 1.0, speed: 600, life: 0.8, size: 1.0, pierce: 99, count: 1, spread: 0, homing: 0.0 },
  burst: { name: "BURST GUN", dmg: 2.6, rate: 1.6, speed: 260, life: 0.75, size: 1.0, pierce: 0, count: 1, spread: 0.06, homing: 0.0 },
  gatling: { name: "GATLING", dmg: 1.8, rate: 5.0, speed: 260, life: 0.7, size: 0.9, pierce: 0, count: 1, spread: 0.08, homing: 0.0 },
  whip: { name: "WHIP", dmg: 5.0, rate: 2.0, speed: 0, life: 0, size: 1.0, pierce: 99, count: 1, spread: 0, homing: 0.0, range: 70, width: 6 },
  summon: { name: "CALLER", dmg: 2.5, rate: 0.8, speed: 140, life: 1.0, size: 1.0, pierce: 0, count: 1, spread: 0, homing: 2.0 },
}
ARCH_DESC = {
  bolt: "FIRES FAST BOLTS", orb: "HOMING BOLTS", spin: "SPINNING THROWS THAT PIERCE", shot: "A SPREAD OF SHOT",
  flask: "BURSTING THROWS", boomer: "FLIES OUT AND BACK, HITTING TWICE", slash: "MELEE ARC IN FRONT OF YOU",
  thrust: "MELEE THRUST THAT PIERCES A LINE", beam: "A CONSTANT RAY", flame: "SHORT CONE OF FLAME",
  disc: "BOUNCES OFF WALLS", pulse: "SLOW ORB THAT HURTS ALL NEARBY", zap: "INSTANT ARCS THAT CHAIN",
  nova: "A RING OF SHOTS AROUND YOU", mine: "TOSSES MINES THAT BLOW WHEN FOES COME NEAR", rail: "PIERCING SHOTS AT HUGE SPEED",
  burst: "THREE-SHOT BURSTS", gatling: "FIRES FASTER THE LONGER YOU SHOOT", whip: "LONG LASH, THE TIP ALWAYS CRITS",
  summon: "EACH SHOT RAISES A SPIRIT WISP",
}

def wpn(id, name, kind, rarity, tags, shape, over, stats, hooks, desc)
  a = ARCH[kind].merge(over)
  a.merge(id: id, name: name, kind: kind, rarity: rarity, tags: tags, shape: shape, stats: stats, hooks: hooks, desc: desc,
          cols: TAG_COLS[tags.first || :core], item: :weapon)
end

WEAPONS = [
  # --- Bows and crossbows ---
  wpn("repeater", "REPEATER", :bolt, :common, [], "crossbow", { dmg: 2.0, rate: 6.5, speed: 270, life: 0.75, pierce: 1 }, [], [], "THE POACHER'S CROSSBOW. FAST AND FLAT."),
  wpn("huntbow", "HUNTING BOW", :bolt, :common, [:fortune], "bow", { dmg: 3.5, rate: 3.6 }, [], [[:far_dmg, 0.4]], "SHOTS FROM AFAR HIT 40% HARDER."),
  wpn("streetpistol", "STREET PISTOL", :bolt, :common, [:blood], "pistol", { dmg: 3.0, rate: 4.5, speed: 300 }, [], [[:nth_big, 6]], "EVERY 6TH SHOT HITS FOR TRIPLE DAMAGE."),
  wpn("silvercrossbow", "SILVERED CROSSBOW", :bolt, :rare, [:bulwark], "crossbow", { dmg: 3.4, rate: 4.0, pierce: 2 }, [], [[:elite_dmg, 0.5]], "SILVER BOLTS. +50% DAMAGE TO ELITES AND GUARDIANS."),
  wpn("longrifle", "LONG RIFLE", :bolt, :rare, [:shadow], "rifle", { dmg: 9.0, rate: 1.4, speed: 420, life: 0.9, pierce: 1 }, [], [[:still_dmg, 0.6]], "+60% DAMAGE WHILE STANDING STILL."),
  wpn("thornbow", "THORNBOW", :bolt, :epic, [:venom], "bow", { dmg: 3.2, rate: 4.0 }, [[:poison, 1]], [[:split, 2]], "ARROWS BURST INTO TWO POISON THORNS ON HIT."),
  wpn("sunpiercer", "SUNPIERCER", :bolt, :legend, [:pyre], "bow", { dmg: 5.0, rate: 3.2, speed: 320, pierce: 3 }, [[:burn, 0.35]], [[:nth_nova, 5]], "BURNING ARROWS. EVERY 5TH ERUPTS IN A RING OF FIRE."),
  # --- Staffs and wands ---
  wpn("hexwand", "HEX WAND", :orb, :common, [], "wand", { dmg: 4.0, rate: 3.2 }, [], [], "THE HEXER'S WAND. BOLTS CURVE TOWARD FOES."),
  wpn("emberwand", "EMBER WAND", :orb, :common, [:pyre], "wand", { dmg: 3.6, rate: 3.4 }, [[:burn, 0.2]], [], "SPARKS OF CINDER THAT OFTEN BURN."),
  wpn("rimerod", "RIME ROD", :orb, :common, [:frost], "wand", { dmg: 3.4, rate: 3.4 }, [[:chill, 0.25]], [], "COLD BOLTS THAT CHILL."),
  wpn("witchstaff", "WITCHWOOD STAFF", :orb, :rare, [:arcane], "orbstaff", { dmg: 4.2, rate: 3.0, homing: 3.0 }, [], [[:mark, 0.25]], "BOLTS MARK FOES. MARKED FOES TAKE +25% DAMAGE."),
  wpn("stormcaller", "STORMCALLER", :orb, :rare, [:storm], "staff", { dmg: 3.6, rate: 3.2 }, [[:chain, 0.25]], [[:nth_zap, 6]], "HITS OFTEN ARC. EVERY 6TH BOLT CALLS LIGHTNING."),
  wpn("soulstaff", "SOULREAVER STAFF", :orb, :epic, [:shadow], "skullstaff", { dmg: 4.0, rate: 3.0 }, [], [[:souls, 0.006]], "EVERY KILL THIS FLOOR ADDS 0.6% DAMAGE, UP TO +50%."),
  wpn("laststar", "THE LAST STAR", :orb, :legend, [:arcane], "orbstaff", { dmg: 5.0, rate: 3.0, homing: 3.5, size: 1.3 }, [], [[:split, 3], [:grow, 1.0]], "BOLTS SWELL AS THEY FLY AND SHATTER INTO 3 STARS."),
  # --- Thrown axes ---
  wpn("pithatchet", "PIT HATCHET", :spin, :common, [], "axe", {}, [], [], "THE BRUTE'S HATCHET. HEAVY AND PIERCING."),
  wpn("woodaxe", "WOODSMAN'S AXE", :spin, :common, [], "axe", { dmg: 9.0, rate: 1.6 }, [], [[:knock, 1.8]], "KNOCKS FOES FAR BACK."),
  wpn("bonecleaver", "BONE CLEAVER", :spin, :rare, [:blood], "cleaver", { dmg: 10.0, rate: 1.5 }, [], [[:execute, 0.15]], "INSTANTLY KILLS FOES BELOW 15% HEALTH."),
  wpn("tomahawk", "FEATHERED TOMAHAWK", :spin, :rare, [:swarm], "axe", { dmg: 7.0, rate: 2.1, speed: 220 }, [], [[:kill_wisp, 0.15]], "KILLS HAVE 15% CHANCE TO RAISE A SPIRIT WISP."),
  wpn("ragefang", "RAGEFANG AXE", :spin, :epic, [:blood], "axe", { dmg: 11.0, rate: 1.6 }, [], [[:low_hp_dmg, 0.8], [:kill_haste, 2.0]], "+80% DAMAGE WHEN WOUNDED. KILLS GIVE A BURST OF SPEED."),
  wpn("twincrescent", "TWIN CRESCENTS", :spin, :legend, [:arcane], "sickle", { dmg: 9.0, rate: 1.8, count: 2, spread: 0.5, pierce: 4 }, [], [[:accel, 1.6]], "THROWS TWO BLADES THAT SPEED UP AS THEY FLY."),
  # --- Scatterguns ---
  wpn("graveshovel", "GRAVE SHOVEL", :shot, :common, [], "shovel", { life: 0.55 }, [], [], "THE GRAVEDIGGER'S SHOVEL. FLINGS GRAVE DIRT."),
  wpn("blunderbuss", "BLUNDERBUSS", :shot, :common, [:demolition], "blunderbuss", { dmg: 2.2, rate: 1.8, count: 6, spread: 0.2, life: 0.45 }, [], [[:close_dmg, 0.5]], "+50% DAMAGE UP CLOSE."),
  wpn("sawnoff", "SAWN-OFF", :shot, :rare, [:blood], "blunderbuss", { dmg: 2.6, rate: 1.6, count: 7, spread: 0.24, life: 0.38 }, [], [[:knock, 2.0], [:close_dmg, 0.6]], "BRUTAL UP CLOSE, WITH HUGE KNOCKBACK."),
  wpn("nailspitter", "NAIL SPITTER", :shot, :rare, [:venom], "handcannon", { dmg: 1.8, rate: 2.6, count: 5, spread: 0.18 }, [[:poison, 1]], [[:shred, 0.04]], "RUSTY NAILS POISON AND SHRED: +4% DAMAGE TAKEN PER HIT, UP TO 5."),
  wpn("hailcannon", "HAILSTORM CANNON", :shot, :epic, [:frost], "handcannon", { dmg: 2.4, rate: 2.0, count: 8, spread: 0.22 }, [[:chill, 0.3]], [[:status_dmg, 0.3]], "SPRAYS HAIL. +30% DAMAGE TO FOES WITH ANY AILMENT."),
  wpn("dragonbreath", "DRAGON'S BREATH", :shot, :legend, [:pyre], "blunderbuss", { dmg: 2.6, rate: 2.2, count: 9, spread: 0.26 }, [[:burn, 0.5]], [[:kill_explode, 1.0]], "FIRE SHELLS. FOES IT SLAYS EXPLODE IN FLAME."),
  # --- Flasks ---
  wpn("flasksling", "FLASK SLING", :flask, :common, [:venom], "flaskw", {}, [[:explode, 1], [:poison, 1]], [], "THE ALCHEMIST'S SLING. POISON FLASKS THAT BURST."),
  wpn("firebottle", "FIREBOTTLE", :flask, :common, [:pyre], "flaskw", { dmg: 4.5 }, [[:explode, 1], [:burn, 0.3]], [], "BURSTS INTO FLAME."),
  wpn("acidjar", "ACID JAR", :flask, :rare, [:venom], "flaskw", { dmg: 4.0, rate: 2.2 }, [[:explode, 1], [:poison, 2]], [[:shred, 0.05]], "ACID THAT POISONS AND EATS THROUGH ARMOR."),
  wpn("frostvial", "FROST VIAL", :flask, :rare, [:frost], "flaskw", { dmg: 4.4 }, [[:explode, 1], [:chill, 0.5]], [], "SHATTERS INTO A CHILLING CLOUD."),
  wpn("bottledstorm", "BOTTLED STORM", :flask, :epic, [:storm], "flaskw", {}, [[:explode, 1], [:chain, 0.5]], [[:nth_zap, 4]], "BURSTS INTO ARCS. EVERY 4TH FLASK CALLS LIGHTNING."),
  wpn("panacea", "PANACEA", :flask, :legend, [:arcane], "flaskw", { dmg: 6.0, rate: 2.2 }, [[:explode, 2]], [[:leech, 0.03], [:status_dmg, 0.4]], "HUGE BLASTS. 3% OF HITS HEAL. +40% VS AFFLICTED FOES."),
  # --- Boomerangs ---
  wpn("lantern", "WARDEN'S LANTERN", :boomer, :common, [], "lanternw", {}, [], [], "THE WARDEN'S LANTERN. FLIES OUT AND BACK."),
  wpn("boomerang", "HUNTER'S BOOMERANG", :boomer, :common, [:fortune], "chakram", { dmg: 4.0, rate: 2.2, size: 1.0 }, [], [[:gold_hit, 0.04]], "4% OF HITS SHAKE A COIN LOOSE."),
  wpn("chakram", "ROVING CHAKRAM", :boomer, :rare, [:arcane], "chakram", { dmg: 4.2, rate: 2.2, speed: 240, size: 1.0 }, [], [[:accel, 1.3], [:mark, 0.15]], "SPEEDS UP AND MARKS FOES (+15% DAMAGE TAKEN)."),
  wpn("reaperhook", "REAPER'S HOOK", :boomer, :rare, [:shadow], "sickle", { dmg: 5.0, rate: 1.9 }, [], [[:execute, 0.12], [:kill_roll, 0.5]], "EXECUTES WEAK FOES. KILLS OFTEN REFUND A ROLL."),
  wpn("sunlantern", "SUNLANTERN", :boomer, :epic, [:pyre], "lanternw", { dmg: 5.5, size: 1.5 }, [[:burn, 0.4]], [[:nth_nova, 4]], "BLAZING. EVERY 4TH THROW SPRAYS FLAME."),
  wpn("moonglaive", "MOONGLAIVE", :boomer, :legend, [:frost], "chakram", { dmg: 6.0, count: 2, spread: 0.6, size: 1.3 }, [[:chill, 0.35]], [[:split, 2]], "TWO FROZEN GLAIVES THAT SPLIT WHEN THEY STRIKE."),
  # --- Swords ---
  wpn("rustblade", "RUSTED BLADE", :slash, :common, [], "sword", {}, [], [], "A PLAIN SWORD. SWINGS IN AN ARC."),
  wpn("sabre", "DUELIST SABRE", :slash, :common, [:shadow], "rapier", { dmg: 6.0, rate: 2.8 }, [], [[:parry, 1]], "QUICK SWINGS THAT CUT SHOTS OUT OF THE AIR."),
  wpn("wandererkatana", "WANDERER'S KATANA", :slash, :rare, [:shadow], "katana", { dmg: 8.0, rate: 2.4, range: 38 }, [], [[:parry, 1], [:first_hit, 0.6]], "+60% DAMAGE TO UNHURT FOES. SWINGS CUT SHOTS."),
  wpn("huntsword", "SILVER HUNTSWORD", :slash, :rare, [:bulwark], "sword", { dmg: 8.0 }, [], [[:elite_dmg, 0.6], [:status_dmg, 0.2]], "MADE FOR HUNTING MONSTERS. +60% VS ELITES AND GUARDIANS."),
  wpn("gallows", "GALLOWS GREATSWORD", :slash, :epic, [:blood], "greatsword", { dmg: 18.0, rate: 1.0, range: 48, arc: 150 }, [], [[:knock, 2.2], [:low_hp_dmg, 0.5]], "SLOW, WIDE, CRUSHING SWINGS. +50% DAMAGE WHEN WOUNDED."),
  wpn("cinderbrand", "CINDERBRAND", :slash, :epic, [:pyre], "sword", { dmg: 9.0 }, [[:burn, 0.5]], [[:kill_explode, 0.8]], "A BURNING BLADE. FOES IT SLAYS EXPLODE."),
  wpn("mirrorblade", "MIRRORBLADE", :slash, :legend, [:arcane], "katana", { dmg: 9.0, rate: 2.6 }, [], [[:parry, 1], [:reflect, 1]], "SWINGS CATCH ENEMY SHOTS AND HURL THEM BACK."),
  # --- Spears ---
  wpn("pike", "FOOTMAN'S PIKE", :thrust, :common, [], "spear", {}, [], [], "THRUSTS IN A LINE, PIERCING EVERYTHING."),
  wpn("boarspear", "BOAR SPEAR", :thrust, :common, [:bulwark], "spear", { dmg: 7.0, rate: 2.2 }, [[:armor, 1]], [[:knock, 1.6]], "+1 ARMOR WHILE HELD. BIG KNOCKBACK."),
  wpn("halberd", "WATCHMAN'S HALBERD", :thrust, :rare, [:bulwark], "halberd", { dmg: 9.0, rate: 1.8, range: 62, width: 14 }, [], [[:parry, 1]], "A WIDE THRUST THAT BLOCKS SHOTS IN ITS PATH."),
  wpn("tidetrident", "TIDECALLER TRIDENT", :thrust, :rare, [:frost], "trident", { dmg: 5.0, count: 3, spread: 0.3 }, [[:chill, 0.3]], [], "THREE PRONGS, THREE THRUSTS."),
  wpn("serpentlance", "SERPENT LANCE", :thrust, :epic, [:venom], "spear", { dmg: 8.0, range: 66 }, [[:poison, 2]], [[:pierce_dmg, 0.25]], "EACH FOE PIERCED MAKES THE THRUST 25% STRONGER."),
  wpn("stormspear", "STORMSPEAR", :thrust, :legend, [:storm], "spear", { dmg: 10.0, rate: 2.2, range: 80 }, [[:chain, 0.4]], [[:nth_zap, 3]], "LONG REACH. EVERY 3RD THRUST CALLS LIGHTNING."),
  # --- Rays ---
  wpn("prismrod", "PRISM ROD", :beam, :common, [:arcane], "wand", {}, [], [], "A STEADY RAY OF LIGHT."),
  wpn("burninglens", "BURNING LENS", :beam, :rare, [:pyre], "orbstaff", { dmg: 1.3 }, [[:burn, 0.12]], [[:still_dmg, 0.4]], "FOCUSED SUNLIGHT. STAND STILL TO BURN HOTTER."),
  wpn("leechrod", "LEECHING ROD", :beam, :rare, [:blood], "skullstaff", { dmg: 1.3 }, [], [[:leech, 0.006]], "A CRIMSON RAY. NOW AND THEN A HIT HEALS YOU."),
  wpn("winterbreath", "WINTER'S BREATH", :beam, :rare, [:frost], "wand", { dmg: 1.2 }, [[:chill, 0.1]], [[:status_dmg, 0.3]], "AN ICY RAY THAT HITS AFFLICTED FOES HARDER."),
  wpn("voidlight", "VOIDLIGHT", :beam, :epic, [:shadow], "rune", { dmg: 1.6, pierce: 99 }, [], [[:mark, 0.2]], "PIERCES EVERY FOE IN LINE AND MARKS THEM."),
  wpn("judgement", "JUDGEMENT RAY", :beam, :legend, [:fortune], "orbstaff", { dmg: 2.0, rate: 11.0, pierce: 99 }, [], [[:gold_dmg, 0.1], [:gold_hit, 0.01]], "+10% DAMAGE PER 100 GOLD. HITS SHAKE OUT COINS."),
  # --- Sprayers ---
  wpn("firespitter", "FIRE SPITTER", :flame, :common, [:pyre], "handcannon", {}, [[:burn, 0.2]], [], "SPRAYS SHORT GOUTS OF FLAME."),
  wpn("bilesprayer", "BILE SPRAYER", :flame, :rare, [:venom], "flaskw", { dmg: 0.9 }, [[:poison, 1]], [], "A SPRAY OF CAUSTIC BILE."),
  wpn("frostbellows", "FROST BELLOWS", :flame, :rare, [:frost], "handcannon", { dmg: 0.9 }, [[:chill, 0.15]], [], "BLOWS FREEZING MIST."),
  wpn("locustcenser", "LOCUST CENSER", :flame, :epic, [:swarm], "lanternw", {}, [], [[:kill_wisp, 0.12]], "BURNING INCENSE THAT RAISES SPIRITS FROM THE SLAIN."),
  wpn("hellmaw", "HELLMAW", :flame, :epic, [:pyre], "handcannon", { dmg: 1.3, rate: 15.0 }, [[:burn, 0.35]], [[:close_dmg, 0.5]], "A ROARING FURNACE. +50% DAMAGE UP CLOSE."),
  wpn("phoenixbellows", "PHOENIX BELLOWS", :flame, :legend, [:pyre], "handcannon", { dmg: 1.4, rate: 16.0, life: 0.5 }, [[:burn, 0.5]], [[:kill_heal, 0.03], [:kill_explode, 0.6]], "LONGER FLAMES. FOES SLAIN BURST AND SOMETIMES HEAL YOU."),
  # --- Discs ---
  wpn("sawblade", "SAWBLADE", :disc, :common, [], "chakram", {}, [], [], "A BLADE THAT BOUNCES OFF WALLS."),
  wpn("razordisc", "RAZOR DISC", :disc, :common, [:blood], "chakram", { dmg: 3.6, rate: 2.2 }, [], [[:shred, 0.03]], "SHREDS: +3% DAMAGE TAKEN PER HIT, UP TO 5."),
  wpn("doubloon", "LUCKY DOUBLOON", :disc, :rare, [:fortune], "chakram", { dmg: 3.4, rate: 2.4 }, [[:ricochet, 2]], [[:gold_hit, 0.05]], "JUMPS FROM FOE TO FOE AND SHAKES OUT COINS."),
  wpn("thunderring", "THUNDER RING", :disc, :rare, [:storm], "chakram", { dmg: 3.8 }, [[:chain, 0.3]], [], "A CRACKLING RING THAT ARCS TO NEARBY FOES."),
  wpn("nightstar", "NIGHT STARS", :disc, :epic, [:shadow], "rune", { dmg: 4.5, rate: 2.4, count: 3, spread: 0.5 }, [], [[:first_hit, 0.5]], "THREE STARS. +50% DAMAGE TO UNHURT FOES."),
  wpn("worldeater", "WORLD-EATER", :disc, :legend, [:demolition], "chakram", { dmg: 6.0, rate: 1.8, size: 1.6, bounce: 6 }, [], [[:grow, 0.6], [:crit_explode, 0.5]], "A HUNGRY WHEEL THAT GROWS AS IT FLIES. CRITS EXPLODE."),
  # --- Orbs ---
  wpn("emberorb", "EMBER ORB", :pulse, :common, [:pyre], "orbstaff", {}, [[:burn, 0.15]], [], "A SLOW ORB THAT SEARS EVERYTHING NEAR IT."),
  wpn("frozenheart", "FROZEN HEART", :pulse, :rare, [:frost], "orbstaff", {}, [[:chill, 0.3]], [], "A DRIFTING SPHERE OF COLD."),
  wpn("plaguebell", "PLAGUE BELL", :pulse, :rare, [:venom], "lanternw", { dmg: 2.6, rate: 1.0 }, [[:poison, 1]], [], "A TOLLING SPHERE THAT POISONS ALL AROUND IT."),
  wpn("gravitywell", "GRAVITY WELL", :pulse, :epic, [:arcane], "orbstaff", { dmg: 3.4, size: 1.6 }, [], [[:linger, 2.0]], "THE ORB STOPS AND HOVERS, GRINDING ALL NEARBY."),
  wpn("blacksun", "BLACK SUN", :pulse, :legend, [:shadow], "orbstaff", { dmg: 4.2, size: 1.8 }, [], [[:linger, 2.5], [:souls, 0.004]], "A DARK STAR THAT HOVERS AND FEEDS ON EVERY KILL."),
  # --- Runes ---
  wpn("sparkrune", "SPARK RUNE", :zap, :common, [:storm], "rune", {}, [], [], "INSTANT ARCS THAT JUMP BETWEEN FOES."),
  wpn("coppercoil", "COPPER COIL", :zap, :rare, [:storm], "gauntlet", { dmg: 3.4, rate: 3.2 }, [], [[:nth_zap, 5]], "FASTER ARCS. EVERY 5TH CALLS LIGHTNING."),
  wpn("maledict", "MALEDICTION RUNE", :zap, :rare, [:arcane], "rune", { dmg: 3.6, rate: 2.6 }, [], [[:mark, 0.3]], "ARCS THAT MARK FOES (+30% DAMAGE TAKEN)."),
  wpn("stormgauntlet", "STORM GAUNTLET", :zap, :epic, [:storm], "gauntlet", { dmg: 4.4, rate: 2.6, chain: 4 }, [], [[:status_dmg, 0.3]], "ARCS JUMP TO 4 FOES."),
  wpn("heavensrod", "HEAVEN'S ROD", :zap, :legend, [:storm], "staff", { dmg: 5.0, rate: 2.4, chain: 5 }, [[:crit, 0.1]], [[:crit_explode, 0.3]], "ARCS TO 5 FOES. +10% CRIT, AND CRITS EXPLODE."),
  # --- Chimes ---
  wpn("bonechime", "BONE CHIME", :nova, :common, [], "lanternw", {}, [], [], "RINGS OUT A BURST IN EVERY DIRECTION."),
  wpn("frostbloom", "FROST BLOOM", :nova, :rare, [:frost], "orbstaff", { dmg: 2.8, count: 12 }, [[:chill, 0.3]], [], "A RING OF ICE SHARDS."),
  wpn("bloodstar", "BLOOD STAR", :nova, :rare, [:blood], "rune", { rate: 1.5 }, [], [[:low_hp_dmg, 0.6]], "+60% DAMAGE WHEN WOUNDED."),
  wpn("thorntome", "TOME OF THORNS", :nova, :epic, [:venom], "tome", { rate: 1.6, count: 14 }, [[:poison, 1]], [], "SPRAYS POISON THORNS ALL AROUND YOU."),
  wpn("cataclysm", "CATACLYSM", :nova, :legend, [:demolition], "tome", { dmg: 3.6, rate: 1.6, count: 16 }, [], [[:kill_explode, 0.8], [:roll_nova, 12]], "HUGE RINGS. FOES EXPLODE. ROLLING FIRES A RING TOO."),
  # --- Traps ---
  wpn("snaremine", "SNARE MINES", :mine, :common, [:demolition], "minetrap", {}, [], [], "TOSSES MINES THAT BLOW WHEN FOES COME NEAR."),
  wpn("frosttrap", "FROST TRAP", :mine, :rare, [:frost], "minetrap", { dmg: 12.0, rate: 1.3 }, [[:chill, 0.6]], [], "MINES THAT FREEZE THE AREA."),
  wpn("spiketrap", "SPIKE TRAP", :mine, :rare, [:blood], "minetrap", { dmg: 16.0, rate: 1.1 }, [], [[:execute, 0.1]], "VICIOUS MINES THAT FINISH OFF WEAK FOES."),
  wpn("hivepod", "HIVE POD", :mine, :epic, [:swarm], "minetrap", { dmg: 10.0, rate: 1.3 }, [], [[:kill_wisp, 0.3]], "MINES RAISE SPIRITS FROM WHAT THEY KILL."),
  wpn("doomspring", "DOOMSPRING", :mine, :legend, [:demolition], "minetrap", { dmg: 22.0 }, [], [[:crit_explode, 1.0], [:kill_explode, 0.8]], "MASSIVE MINES. EXPLOSIONS SPAWN EXPLOSIONS."),
  # --- Railshots ---
  wpn("arbalest", "ARBALEST", :rail, :common, [], "crossbow", {}, [], [], "A HEAVY BOLT THAT GOES THROUGH EVERYTHING."),
  wpn("harpoon", "WHALING HARPOON", :rail, :rare, [:frost], "spear", { dmg: 15.0, rate: 0.9 }, [[:chill, 0.4]], [[:knock, 2.5]], "SKEWERS AND SHOVES FOES BACK."),
  wpn("handcannon", "HAND CANNON", :rail, :rare, [:demolition], "handcannon", { dmg: 16.0, rate: 0.85 }, [[:crit, 0.1]], [[:crit_explode, 0.6]], "+10% CRIT. CRITS EXPLODE."),
  wpn("dawnlance", "LANCE OF DAWN", :rail, :epic, [:arcane], "rifle", { dmg: 17.0 }, [], [[:nth_nova, 3]], "EVERY 3RD SHOT BURSTS INTO A RING OF LIGHT."),
  wpn("deicide", "DEICIDE", :rail, :legend, [:blood], "rifle", { dmg: 25.0, rate: 0.85 }, [], [[:boss_dmg, 0.75], [:execute, 0.2]], "BUILT FOR KILLING GODS. +75% VS GUARDIANS, EXECUTES BELOW 20%."),
  # --- Burst guns ---
  wpn("burstpistol", "THREE-ROUND PISTOL", :burst, :common, [], "pistol", {}, [], [], "FIRES IN BURSTS OF THREE."),
  wpn("alleysprayer", "ALLEY SPRAYER", :burst, :rare, [:shadow], "pistol", { dmg: 2.2, rate: 2.2, spread: 0.1 }, [], [[:moving_dmg, 0.35]], "+35% DAMAGE WHILE MOVING."),
  wpn("triplecrossbow", "TRIPLE CROSSBOW", :burst, :rare, [:bulwark], "crossbow", { dmg: 3.0 }, [[:pierce, 1]], [[:pierce_dmg, 0.2]], "PIERCING BOLTS THAT GROW STRONGER WITH EACH FOE."),
  wpn("gildedrevolver", "GILDED REVOLVER", :burst, :epic, [:fortune], "pistol", { dmg: 3.4, rate: 1.8 }, [], [[:gold_dmg, 0.15], [:gold_hit, 0.03]], "+15% DAMAGE PER 100 GOLD. HITS SHAKE OUT COINS."),
  wpn("hailfire", "HAILFIRE", :burst, :legend, [:storm], "rifle", { dmg: 3.4, rate: 2.0 }, [[:count, 1]], [[:nth_zap, 4], [:moving_dmg, 0.3]], "DOUBLE BURSTS. LIGHTNING EVERY 4TH. +30% WHILE MOVING."),
  # --- Gatlings ---
  wpn("crankgun", "CRANK GUN", :gatling, :common, [:demolition], "minigun", {}, [], [], "SPINS UP TO A HAIL OF SHOTS."),
  wpn("rotarybow", "ROTARY BOW", :gatling, :rare, [:swarm], "minigun", { dmg: 1.7 }, [], [[:kill_wisp, 0.05]], "A SPINNING BOW. KILLS SOMETIMES RAISE WISPS."),
  wpn("bonegrinder", "BONEGRINDER", :gatling, :rare, [:blood], "minigun", { dmg: 2.0 }, [], [[:shred, 0.02]], "SHREDS: +2% DAMAGE TAKEN PER HIT, UP TO 5."),
  wpn("sunspitter", "SUNSPITTER", :gatling, :epic, [:pyre], "minigun", { dmg: 2.0, rate: 5.5 }, [[:burn, 0.15]], [], "A SPINNING STREAM OF FIRE."),
  wpn("dreadnought", "DREADNOUGHT", :gatling, :legend, [:bulwark], "minigun", { dmg: 2.4, rate: 6.0 }, [[:armor, 2]], [[:armor_dmg, 0.1]], "+2 ARMOR WHILE HELD. +10% DAMAGE PER ARMOR."),
  # --- Whips ---
  wpn("drovewhip", "DROVER'S WHIP", :whip, :common, [], "whip", {}, [], [], "A LONG LASH. THE TIP ALWAYS CRITS."),
  wpn("chainlash", "CHAIN LASH", :whip, :rare, [:bulwark], "whip", { dmg: 6.0, rate: 1.9 }, [], [[:parry, 1]], "THE CHAIN SWATS SHOTS ASIDE."),
  wpn("bramblewhip", "BRAMBLE WHIP", :whip, :rare, [:venom], "whip", { rate: 2.2 }, [[:poison, 2]], [], "A THORNY LASH THAT POISONS."),
  wpn("lightninglash", "LIGHTNING LASH", :whip, :epic, [:storm], "whip", { dmg: 6.0, rate: 2.2 }, [[:chain, 0.4]], [], "A LASH OF LIGHTNING THAT ARCS."),
  wpn("bloodvine", "BLOODVINE", :whip, :legend, [:blood], "whip", { dmg: 7.0, rate: 2.3, range: 84 }, [], [[:leech, 0.04], [:execute, 0.12]], "LONG REACH. HITS CAN HEAL. EXECUTES WEAK FOES."),
  # --- Callers ---
  wpn("gravebell", "GRAVE BELL", :summon, :common, [:swarm], "skullstaff", {}, [], [], "EACH TOLL RAISES A WISP FOR 6 SECONDS (UP TO 4)."),
  wpn("hivestaff", "HIVE STAFF", :summon, :rare, [:swarm], "staff", { dmg: 2.2, rate: 1.0 }, [[:fam_rate, 1.3]], [], "WISPS FIRE 30% FASTER."),
  wpn("bonetome", "BONE TOME", :summon, :epic, [:swarm], "tome", { dmg: 3.0, rate: 0.9 }, [[:familiars, 1]], [[:kill_wisp, 0.2]], "A PERMANENT WISP. KILLS RAISE MORE."),
  wpn("warbanner", "WARBANNER", :summon, :legend, [:swarm], "halberd", { dmg: 3.2, rate: 1.0 }, [[:familiars, 2], [:fam_dmg, 0.5]], [], "TWO PERMANENT WISPS THAT HIT 50% HARDER."),
]
WEAPON_BY_ID = {}
WEAPONS.each { |w| WEAPON_BY_ID[w[:id]] = w }

# ---------- Equipment ----------
SLOTS = [:head, :body, :feet, :trinket]
SLOT_NAME = { head: "HELM", body: "ARMOR", feet: "BOOTS", trinket: "TRINKET" }

# Four-piece sets: the 2-piece bonus supports a build, the 4-piece grants that family's capstone power.
SETS = {
  "emberweave" => { name: "EMBERWEAVE", tag: :pyre, b2: [[:burn, 0.2]], b4h: [[:inferno, 1]], d2: "+20% BURN CHANCE", d4: "BURNING FOES EXPLODE ON DEATH" },
  "hoarfrost" => { name: "HOARFROST", tag: :frost, b2: [[:chill, 0.2]], b4h: [[:shatter, 1]], d2: "+20% CHILL CHANCE", d4: "CHILLED FOES SHATTER BELOW 30%" },
  "plaguedoc" => { name: "PLAGUE DOCTOR", tag: :venom, b2: [[:poison, 1]], b4h: [[:plague, 1]], d2: "+1 POISON ON HIT", d4: "POISON SPREADS WHEN FOES DIE" },
  "thunderborn" => { name: "THUNDERBORN", tag: :storm, b2: [[:chain, 0.2]], b4h: [[:tempest, 1]], d2: "+20% ARC CHANCE", d4: "LIGHTNING STRIKES 3 FOES EVERY 3S" },
  "butcher" => { name: "BUTCHER", tag: :blood, b2: [[:crit, 0.1]], b4h: [[:sanguine, 1]], d2: "+10% CRIT CHANCE", d4: "KILLS STACK +4% DAMAGE FOR THE ROOM" },
  "bastion" => { name: "BASTION", tag: :bulwark, b2: [[:armor, 2]], b4h: [[:unbreakable, 1]], d2: "+2 ARMOR", d4: "BROKEN ARMOR RELEASES A NOVA" },
  "nightstalker" => { name: "NIGHTSTALKER", tag: :shadow, b2: [[:dodge_charges, 1], [:charges, 1]], b4h: [[:nightfall, 1]], d2: "+1 ROLL CHARGE", d4: "ROLLS STRIKE HARD AND REFUND ON KILLS" },
  "archmage" => { name: "ARCHMAGE", tag: :arcane, b2: [[:count, 1]], b4: [[:echo, 0.3]], d2: "+1 PROJECTILE", d4: "30% CHANCE FOR SHOTS TO CAST AGAIN" },
  "gilded" => { name: "GILDED", tag: :fortune, b2: [[:gold_mult, 1.3]], b4h: [[:midas, 1]], d2: "+30% GOLD", d4: "+1% DAMAGE PER 5 GOLD HELD" },
  "sapper" => { name: "SAPPER", tag: :demolition, b2: [[:bombs, 3], [:bomb_mult, 1.3]], b4h: [[:cluster, 1]], d2: "+3 BOMBS, BOMBS +30%", d4: "BOMBS BURST INTO 4 MORE" },
  "shepherd" => { name: "SHEPHERD", tag: :swarm, b2: [[:familiars, 1]], b4h: [[:legion, 1]], d2: "+1 WISP", d4: "EVERY 5 KILLS SUMMON A WISP" },
}

def gear(id, name, slot, rarity, tags, set, shape, stats, hooks, desc)
  { id: id, name: name, slot: slot, rarity: rarity, tags: tags, set: set, shape: shape, stats: stats, hooks: hooks, desc: desc,
    cols: TAG_COLS[tags.first || :core], item: :gear }
end

GEAR = [
  # --- Set pieces ---
  gear("ember_hood", "EMBERWEAVE HOOD", :head, :rare, [:pyre], "emberweave", "hood", [[:burn, 0.1]], [], "SMOULDERING CLOTH."),
  gear("ember_robe", "EMBERWEAVE ROBE", :body, :rare, [:pyre], "emberweave", "robe", [[:max_hp, 2]], [[:fire_aura, 1]], "FOES NEAR YOU CATCH FIRE."),
  gear("ember_boots", "EMBERWEAVE TREADS", :feet, :rare, [:pyre], "emberweave", "boots", [[:speed, 1.06]], [[:fire_steps, 1]], "YOU LEAVE BURNING FOOTPRINTS WHILE MOVING."),
  gear("ember_ring", "EMBERWEAVE BAND", :trinket, :epic, [:pyre], "emberweave", "ring", [[:dmg, 1.1]], [[:status_dmg, 0.15]], "+15% DAMAGE TO AFFLICTED FOES."),
  gear("frost_helm", "HOARFROST CROWN", :head, :rare, [:frost], "hoarfrost", "crown", [[:chill, 0.1]], [], "ICE FORMS ON YOUR BROW."),
  gear("frost_plate", "HOARFROST PLATE", :body, :rare, [:frost], "hoarfrost", "plate", [[:armor, 1]], [[:frost_skin, 1]], "WHEN HIT, CHILL EVERY FOE NEARBY."),
  gear("frost_boots", "HOARFROST GREAVES", :feet, :rare, [:frost], "hoarfrost", "greaves", [[:dodge_cd, 0.9]], [], "ROLLS RECHARGE FASTER."),
  gear("frost_amulet", "HOARFROST LOCKET", :trinket, :epic, [:frost], "hoarfrost", "amulet", [[:crit, 0.05]], [[:chill_crit, 0.25]], "+25% CRIT CHANCE AGAINST CHILLED FOES."),
  gear("plague_mask", "PLAGUE DOCTOR'S MASK", :head, :rare, [:venom], "plaguedoc", "mask", [[:poison, 1]], [], "HERBS IN THE BEAK KEEP THE MIASMA OUT."),
  gear("plague_coat", "PLAGUE DOCTOR'S COAT", :body, :rare, [:venom], "plaguedoc", "cloak", [[:max_hp, 2]], [], "OILED LEATHER."),
  gear("plague_boots", "PLAGUE DOCTOR'S BOOTS", :feet, :rare, [:venom], "plaguedoc", "boots", [[:speed, 1.05]], [[:toxic_steps, 1]], "YOU LEAVE POISON PUDDLES WHILE MOVING."),
  gear("plague_censer", "PLAGUE CENSER", :trinket, :epic, [:venom], "plaguedoc", "amulet", [[:dmg, 1.08]], [[:status_dmg, 0.2]], "+20% DAMAGE TO AFFLICTED FOES."),
  gear("thunder_helm", "THUNDERBORN HELM", :head, :rare, [:storm], "thunderborn", "helm", [[:chain, 0.1]], [], "YOUR HAIR STANDS ON END."),
  gear("thunder_mail", "THUNDERBORN MAIL", :body, :rare, [:storm], "thunderborn", "plate", [[:armor, 1]], [[:spark_skin, 1]], "WHEN HIT, LIGHTNING STRIKES NEARBY FOES."),
  gear("thunder_boots", "THUNDERBORN BOOTS", :feet, :rare, [:storm], "thunderborn", "boots", [[:speed, 1.1]], [], "+10% MOVE SPEED."),
  gear("thunder_ring", "THUNDERBORN SIGNET", :trinket, :epic, [:storm], "thunderborn", "ring", [[:rate, 1.1]], [[:nth_zap, 10]], "EVERY 10TH SHOT CALLS LIGHTNING."),
  gear("butcher_cap", "BUTCHER'S CAP", :head, :rare, [:blood], "butcher", "hat", [[:crit_mult, 0.25]], [], "CRITS DEAL +0.25X MORE."),
  gear("butcher_apron", "BUTCHER'S APRON", :body, :rare, [:blood], "butcher", "leather", [[:max_hp, 2]], [[:kill_heal, 0.03]], "KILLS HAVE A 3% CHANCE TO HEAL."),
  gear("butcher_boots", "BUTCHER'S CLOGS", :feet, :rare, [:blood], "butcher", "boots", [[:speed, 1.05]], [[:close_dmg, 0.2]], "+20% DAMAGE UP CLOSE."),
  gear("butcher_hook", "BUTCHER'S HOOK", :trinket, :epic, [:blood], "butcher", "charm", [[:dmg, 1.1]], [[:execute, 0.08]], "INSTANTLY KILLS FOES BELOW 8% HEALTH."),
  gear("bastion_helm", "BASTION GREATHELM", :head, :rare, [:bulwark], "bastion", "helm", [[:armor, 1]], [], "A BUCKET OF STEEL."),
  gear("bastion_plate", "BASTION PLATE", :body, :epic, [:bulwark], "bastion", "plate", [[:armor, 2], [:max_hp, 2]], [], "WALKING FORTRESS."),
  gear("bastion_boots", "BASTION SABATONS", :feet, :rare, [:bulwark], "bastion", "greaves", [[:thorns, 10]], [], "SPIKED STEEL TOES."),
  gear("bastion_seal", "BASTION SEAL", :trinket, :rare, [:bulwark], "bastion", "amulet", [], [[:room_armor, 1]], "GAIN 1 ARMOR AFTER EACH ROOM."),
  gear("night_hood", "NIGHTSTALKER COWL", :head, :rare, [:shadow], "nightstalker", "hood", [[:evade, 0.06]], [], "6% CHANCE TO DODGE A HIT."),
  gear("night_cloak", "NIGHTSTALKER CLOAK", :body, :rare, [:shadow], "nightstalker", "cloak", [[:roll_speed, 1.15]], [[:roll_ambush, 2]], "AFTER A ROLL, YOUR NEXT 2 SHOTS CRIT."),
  gear("night_boots", "NIGHTSTALKER SOFTSTEPS", :feet, :epic, [:shadow], "nightstalker", "boots", [[:speed, 1.1], [:dodge_cd, 0.85]], [], "SILENT AND SWIFT."),
  gear("night_fang", "NIGHTSTALKER FANG", :trinket, :rare, [:shadow], "nightstalker", "charm", [[:crit, 0.06]], [[:first_hit, 0.3]], "+30% DAMAGE TO UNHURT FOES."),
  gear("arch_hat", "ARCHMAGE HAT", :head, :rare, [:arcane], "archmage", "hat", [[:homing, 1.0]], [], "SHOTS CURVE TOWARD FOES."),
  gear("arch_robe", "ARCHMAGE ROBE", :body, :epic, [:arcane], "archmage", "robe", [[:size, 1.15], [:dmg, 1.1]], [], "BIGGER, STRONGER SHOTS."),
  gear("arch_boots", "ARCHMAGE SLIPPERS", :feet, :rare, [:arcane], "archmage", "boots", [[:shot_speed, 1.15]], [], "SHOTS FLY 15% FASTER."),
  gear("arch_orb", "ARCHMAGE ORRERY", :trinket, :rare, [:arcane], "archmage", "amulet", [[:orbitals, 1]], [], "A MOON CIRCLES YOU AND BLOCKS SHOTS."),
  gear("gild_crown", "GILDED CIRCLET", :head, :rare, [:fortune], "gilded", "crown", [[:luck, 1]], [], "BETTER RELIC RARITY."),
  gear("gild_vest", "GILDED VEST", :body, :rare, [:fortune], "gilded", "leather", [[:max_hp, 2]], [[:gold_dmg, 0.05]], "+5% DAMAGE PER 100 GOLD."),
  gear("gild_boots", "GILDED BOOTS", :feet, :rare, [:fortune], "gilded", "boots", [[:shop_disc, 0.1]], [], "SHOPS 10% CHEAPER."),
  gear("gild_ring", "GILDED RING", :trinket, :epic, [:fortune], "gilded", "ring", [[:gold_mult, 1.2]], [[:gold_hit, 0.03]], "HITS SOMETIMES SHAKE OUT COINS."),
  gear("sapper_helm", "SAPPER'S HELMET", :head, :rare, [:demolition], "sapper", "helm", [[:bomb_r, 1.15]], [], "BIGGER BLASTS."),
  gear("sapper_vest", "SAPPER'S BLAST VEST", :body, :rare, [:demolition], "sapper", "plate", [[:armor, 1]], [[:bomb_immune, 1]], "YOUR OWN BOMBS NO LONGER HURT YOU."),
  gear("sapper_boots", "SAPPER'S BOOTS", :feet, :rare, [:demolition], "sapper", "greaves", [[:speed, 1.05]], [[:roll_bomb, 1]], "ROLLING DROPS A BOMB."),
  gear("sapper_fuse", "SAPPER'S FUSE", :trinket, :epic, [:demolition], "sapper", "charm", [[:shrapnel, 0.1]], [[:bomb_on_kill, 0.06]], "10% OF SHOTS EXPLODE. KILLS SOMETIMES DROP BOMBS."),
  gear("shep_hat", "SHEPHERD'S HAT", :head, :rare, [:swarm], "shepherd", "hat", [[:fam_dmg, 0.25]], [], "WISPS DEAL 25% MORE."),
  gear("shep_cloak", "SHEPHERD'S CLOAK", :body, :rare, [:swarm], "shepherd", "cloak", [[:max_hp, 2]], [[:kill_wisp, 0.08]], "KILLS SOMETIMES RAISE A WISP."),
  gear("shep_boots", "SHEPHERD'S SANDALS", :feet, :rare, [:swarm], "shepherd", "boots", [[:fam_rate, 1.2]], [], "WISPS FIRE 20% FASTER."),
  gear("shep_crook", "SHEPHERD'S BELL", :trinket, :epic, [:swarm], "shepherd", "amulet", [[:familiars, 1]], [], "A WISP FOLLOWS YOU."),
  # --- Helms ---
  gear("tinhelm", "DENTED TIN HELM", :head, :common, [:bulwark], nil, "helm", [[:armor, 1]], [], "BETTER THAN NOTHING."),
  gear("leathercap", "LEATHER CAP", :head, :common, [], nil, "hat", [[:max_hp, 2]], [], "+1 MAX HEART."),
  gear("huntershood", "HUNTER'S HOOD", :head, :common, [:shadow], nil, "hood", [[:crit, 0.05]], [], "+5% CRIT CHANCE."),
  gear("scholarcap", "SCHOLAR'S CAP", :head, :common, [:arcane], nil, "hat", [[:xp_mult, 1.2]], [], "+20% EXPERIENCE."),
  gear("ironmask", "IRON DEATHMASK", :head, :rare, [:blood], nil, "mask", [[:dmg, 1.15]], [[:low_hp_dmg, 0.25]], "+25% DAMAGE WHEN WOUNDED."),
  gear("owlhelm", "OWL-EYED HELM", :head, :rare, [], nil, "helm", [[:life, 1.2]], [[:far_dmg, 0.2]], "+20% RANGE. +20% DAMAGE FROM AFAR."),
  gear("crownofthorns", "CROWN OF THORNS", :head, :epic, [:venom], nil, "crown", [[:thorns, 15], [:poison, 1]], [[:thorns_nova, 8]], "WHEN HIT, FIRE 8 THORNS AROUND YOU."),
  gear("hornedhelm", "HORNED WARHELM", :head, :epic, [:blood], nil, "helm", [[:max_hp, 2], [:dmg, 1.1]], [[:kill_haste, 1.5]], "KILLS GIVE A SHORT BURST OF SPEED."),
  gear("seerveil", "SEER'S VEIL", :head, :epic, [:arcane], nil, "hood", [[:luck, 2]], [[:trait_dmg, 0.02]], "+2% DAMAGE PER TRAIT RANK. BETTER RELICS."),
  gear("kingscrown", "CROWN OF THE LOST KING", :head, :legend, [:fortune], nil, "crown", [[:gold_mult, 1.5], [:luck, 2]], [[:relic_dmg, 0.03]], "+3% DAMAGE FOR EVERY RELIC YOU OWN."),
  gear("stormcrownhelm", "TEMPEST DIADEM", :head, :legend, [:storm], nil, "crown", [[:chain, 0.25], [:chain_jumps, 1]], [[:crit_chain, 1]], "CRITS ALWAYS ARC. ARCS JUMP FURTHER."),
  gear("headsman", "HEADSMAN'S HOOD", :head, :legend, [:blood], nil, "hood", [[:crit, 0.1]], [[:execute, 0.15]], "+10% CRIT. INSTANTLY KILLS FOES BELOW 15%."),
  # --- Armor ---
  gear("paddedjack", "PADDED JACK", :body, :common, [], nil, "leather", [[:max_hp, 2]], [], "+1 MAX HEART."),
  gear("chainshirt", "CHAIN SHIRT", :body, :common, [:bulwark], nil, "plate", [[:armor, 1], [:speed, 0.96]], [], "+1 ARMOR, A LITTLE HEAVY."),
  gear("travelcloak", "TRAVELLER'S CLOAK", :body, :common, [:shadow], nil, "cloak", [[:speed, 1.06], [:evade, 0.03]], [], "LIGHT AND HARD TO HIT."),
  gear("acolyterobe", "ACOLYTE ROBE", :body, :common, [:arcane], nil, "robe", [[:rate, 1.08]], [], "+8% FIRE RATE."),
  gear("bloodplate", "BLOODSTAINED PLATE", :body, :rare, [:blood], nil, "plate", [[:armor, 1], [:max_hp, 2]], [[:kill_heal, 0.02]], "KILLS SOMETIMES HEAL."),
  gear("spikedmail", "SPIKED MAIL", :body, :rare, [:bulwark], nil, "plate", [[:armor, 1], [:thorns, 20]], [], "FOES THAT TOUCH YOU REGRET IT."),
  gear("hunterscoat", "MONSTER HUNTER'S COAT", :body, :rare, [], nil, "leather", [[:max_hp, 2], [:potion_heal, 2]], [[:elite_dmg, 0.25]], "POTIONS HEAL MORE. +25% VS ELITES AND GUARDIANS."),
  gear("smugglercoat", "SMUGGLER'S COAT", :body, :rare, [:fortune], nil, "cloak", [[:max_potions, 1], [:keys, 1]], [], "+1 POTION SLOT AND A SPARE KEY."),
  gear("mirrorplate", "MIRROR PLATE", :body, :epic, [:arcane], nil, "plate", [[:armor, 1]], [[:reflect_hit, 1]], "WHEN HIT, FIRE THE PAIN BACK AS 12 SHOTS."),
  gear("berserkerhide", "BERSERKER HIDE", :body, :epic, [:blood], nil, "leather", [[:max_hp, 4], [:armor, -10]], [[:low_hp_dmg, 0.4]], "+2 MAX HEARTS BUT NO ARMOR. +40% DAMAGE WHEN WOUNDED."),
  gear("phoenixmantle", "PHOENIX MANTLE", :body, :legend, [:pyre], nil, "robe", [[:max_hp, 2], [:burn, 0.2]], [[:revive_g, 1]], "ONCE PER RUN, RISE AGAIN WITH 2 HEARTS."),
  gear("voidshroud", "VOID SHROUD", :body, :legend, [:shadow], nil, "cloak", [[:evade, 0.15], [:dodge_charges, 1], [:charges, 1]], [[:roll_nova, 10]], "15% DODGE. +1 ROLL. ROLLING FIRES A RING OF SHOTS."),
  # --- Boots ---
  gear("worntboots", "WORN BOOTS", :feet, :common, [], nil, "boots", [[:speed, 1.08]], [], "+8% MOVE SPEED."),
  gear("ironboots", "IRON BOOTS", :feet, :common, [:bulwark], nil, "greaves", [[:armor, 1], [:speed, 0.95]], [], "+1 ARMOR. SLOWER."),
  gear("sandals", "PILGRIM SANDALS", :feet, :common, [], nil, "boots", [[:dodge_cd, 0.85]], [], "ROLLS RECHARGE FASTER."),
  gear("runnersboots", "COURIER BOOTS", :feet, :rare, [:fortune], nil, "boots", [[:speed, 1.12]], [[:moving_dmg, 0.15]], "+15% DAMAGE WHILE MOVING."),
  gear("ninjatabi", "SILENT TABI", :feet, :rare, [:shadow], nil, "boots", [[:roll_speed, 1.2], [:dodge_charges, 1], [:charges, 1]], [], "+1 ROLL CHARGE. LONGER ROLLS."),
  gear("anchorboots", "ANCHOR BOOTS", :feet, :rare, [:bulwark], nil, "greaves", [[:armor, 1]], [[:still_dmg, 0.3]], "+30% DAMAGE WHILE STANDING STILL."),
  gear("wingedboots", "WINGED BOOTS", :feet, :epic, [:storm], nil, "boots", [[:speed, 1.15], [:dodge_cd, 0.8]], [[:roll_zap, 1]], "ROLLING CALLS LIGHTNING ON THE NEAREST FOE."),
  gear("coalwalkers", "COALWALKERS", :feet, :epic, [:pyre], nil, "greaves", [[:speed, 1.08], [:burn, 0.1]], [[:fire_steps, 1]], "YOU LEAVE BURNING FOOTPRINTS."),
  gear("sevenleague", "SEVEN-LEAGUE BOOTS", :feet, :legend, [], nil, "boots", [[:speed, 1.25], [:roll_speed, 1.25], [:dodge_cd, 0.75]], [[:moving_dmg, 0.25]], "BLINDINGLY FAST. +25% DAMAGE WHILE MOVING."),
  # --- Trinkets ---
  gear("luckycharm", "RABBIT'S FOOT", :trinket, :common, [:fortune], nil, "charm", [[:luck, 1]], [], "BETTER RELIC RARITY."),
  gear("whetring", "WHETSTONE RING", :trinket, :common, [], nil, "ring", [[:dmg, 1.1]], [], "+10% DAMAGE."),
  gear("quickring", "QUICKSILVER RING", :trinket, :common, [], nil, "ring", [[:rate, 1.1]], [], "+10% FIRE RATE."),
  gear("vialbelt", "BELT OF VIALS", :trinket, :common, [], nil, "charm", [[:max_potions, 1], [:potions, 1]], [], "+1 POTION SLOT AND A POTION."),
  gear("bombbag", "POWDER BANDOLIER", :trinket, :common, [:demolition], nil, "charm", [[:bombs, 3]], [], "+3 BOMBS."),
  gear("toothnecklace", "WOLF TOOTH NECKLACE", :trinket, :rare, [:blood], nil, "charm", [[:crit, 0.08], [:crit_mult, 0.2]], [], "+8% CRIT, CRITS DEAL MORE."),
  gear("hourglassamulet", "SANDS OF ESCAPE", :trinket, :rare, [:shadow], nil, "amulet", [[:dodge_charges, 1], [:charges, 1]], [], "+1 ROLL CHARGE."),
  gear("emberheartgem", "EMBER HEART", :trinket, :rare, [:pyre], nil, "amulet", [[:burn, 0.15]], [[:fire_aura, 1]], "FOES NEAR YOU CATCH FIRE."),
  gear("frostshard", "SHARD OF WINTER", :trinket, :rare, [:frost], nil, "amulet", [[:chill, 0.15]], [[:chill_crit, 0.15]], "+15% CRIT AGAINST CHILLED FOES."),
  gear("venomsac", "VENOM SAC", :trinket, :rare, [:venom], nil, "charm", [[:poison, 1]], [[:status_dmg, 0.15]], "+15% DAMAGE TO AFFLICTED FOES."),
  gear("stormbottle", "BOTTLED LIGHTNING", :trinket, :rare, [:storm], nil, "amulet", [[:chain, 0.15]], [], "+15% ARC CHANCE."),
  gear("ledger", "MERCHANT'S LEDGER", :trinket, :rare, [:fortune], nil, "charm", [[:shop_disc, 0.15]], [[:room_gold, 5]], "SHOPS 15% CHEAPER. GAIN 5 GOLD AFTER EACH ROOM."),
  gear("vampirefang", "VAMPIRE FANG", :trinket, :epic, [:blood], nil, "charm", [[:crit, 0.05]], [[:leech, 0.02]], "2% OF HITS HEAL YOU."),
  gear("eyeofstorm", "EYE OF THE STORM", :trinket, :epic, [:storm], nil, "amulet", [[:chain, 0.2]], [[:nth_zap, 8]], "EVERY 8TH SHOT CALLS LIGHTNING."),
  gear("hollowidol", "HOLLOW IDOL", :trinket, :epic, [:arcane], nil, "amulet", [[:count, 1], [:dmg, 0.92]], [[:split, 1]], "+1 PROJECTILE. SHOTS SPLIT ON THEIR FIRST HIT."),
  gear("grimoire", "BLACK GRIMOIRE", :trinket, :epic, [:shadow], nil, "amulet", [[:dmg, 1.15]], [[:souls, 0.004]], "EVERY KILL THIS FLOOR ADDS 0.4% DAMAGE."),
  gear("heartofglass", "HEART OF GLASS", :trinket, :legend, [:arcane], nil, "amulet", [[:dmg, 1.5], [:max_hp, -2]], [[:crit_explode, 0.2]], "+50% DAMAGE BUT -1 MAX HEART. CRITS SOMETIMES EXPLODE."),
  gear("dragonheart", "DRAGON'S HEART", :trinket, :legend, [:pyre], nil, "amulet", [[:max_hp, 4], [:burn, 0.3]], [[:kill_explode, 0.6]], "+2 MAX HEARTS. FOES YOU SLAY EXPLODE IN FLAME."),
  gear("gamblerdie", "GAMBLER'S LAST DIE", :trinket, :legend, [:fortune], nil, "charm", [[:crit, 0.15], [:crit_mult, 0.5], [:luck, 1]], [], "+15% CRIT AND CRITS DEAL MUCH MORE. FORTUNE FAVOURS YOU."),
]
GEAR_BY_ID = {}
GEAR.each { |g| GEAR_BY_ID[g[:id]] = g }

HERO_WEAPON = { "hexer" => "hexwand", "poacher" => "repeater", "brute" => "pithatchet", "gravedigger" => "graveshovel",
                "alchemist" => "flasksling", "warden" => "lantern" }

# Readable lines for stat tuples.
STAT_TEXT = {
  dmg: "DAMAGE", rate: "FIRE RATE", shot_speed: "SHOT SPEED", life: "RANGE", size: "SHOT SIZE", speed: "MOVE SPEED",
  dodge_cd: "ROLL RECHARGE", gold_mult: "GOLD", roll_speed: "ROLL SPEED", bomb_mult: "BOMB DAMAGE", bomb_r: "BOMB RADIUS",
  xp_mult: "EXPERIENCE", fam_rate: "WISP FIRE RATE", max_hp: "MAX HEARTS", armor: "ARMOR", crit: "CRIT CHANCE",
  crit_mult: "CRIT DAMAGE", burn: "BURN CHANCE", chill: "CHILL CHANCE", poison: "POISON ON HIT", chain: "ARC CHANCE",
  evade: "DODGE CHANCE", thorns: "THORNS", familiars: "WISPS", orbitals: "MOONS", homing: "HOMING", pierce: "PIERCE",
  count: "PROJECTILES", luck: "LUCK", shop_disc: "SHOP DISCOUNT", bombs: "BOMBS", keys: "KEYS", potions: "POTIONS",
  max_potions: "POTION SLOTS", potion_heal: "POTION HEALING", dodge_charges: "ROLL CHARGES", explode: "BURSTING SHOTS",
  ricochet: "RICOCHET", shrapnel: "EXPLODING SHOTS", fam_dmg: "WISP DAMAGE", chain_jumps: "ARC JUMPS", echo: "ECHO",
}

def stat_line(k, v)
  name = STAT_TEXT[k]
  return nil unless name
  return nil if k == :charges
  if MUL_KEYS.include?(k)
    pct = ((v - 1) * 100).round
    pct = -pct if k == :dodge_cd
    return format("%+d%% %s", pct, name)
  end
  case k
  when :max_hp then format("%+d %s", v / 2, name)
  when :crit, :burn, :chill, :chain, :evade, :shop_disc, :shrapnel, :echo, :fam_dmg then format("%+d%% %s", (v * 100).round, name)
  when :homing then format("%+.1f %s", v, name)
  else format("%+d %s", v, name)
  end
end
