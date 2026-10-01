# Tiny Biggot - game data: heroes, relics, enemies, bosses, floors, unlocks. All original content.

HEROES = [
  { id: "hexer", name: "THE HEXER", sprite: "hexer", blurb: "A crypt witch. Slow hex bolts that curve toward foes.",
    weapon: "HEX BOLTS", hp: 6, speed: 86, shot: "hex", sound: "shoot", cost: 0,
    stats: { dmg: 4.0, rate: 3.2, shot_speed: 150.0, life: 1.0, homing: 2.2, size: 1.0, pierce: 0 } },
  { id: "poacher", name: "THE POACHER", sprite: "poacher", blurb: "A grave robber with a repeating crossbow. Fast and fragile.",
    weapon: "REPEATER", hp: 6, speed: 96, shot: "bolt", sound: "bolt", cost: 0,
    stats: { dmg: 2.0, rate: 6.5, shot_speed: 270.0, life: 0.75, homing: 0.0, size: 1.0, pierce: 1 } },
  { id: "brute", name: "THE BRUTE", sprite: "brute", blurb: "A pit fighter. Hurls heavy hatchets at close range. Tough.",
    weapon: "HATCHETS", hp: 10, speed: 80, shot: "hatchet", sound: "hatchet", cost: 0,
    stats: { dmg: 8.0, rate: 1.8, shot_speed: 180.0, life: 0.72, homing: 0.0, size: 1.6, pierce: 2 } },
  { id: "gravedigger", name: "THE GRAVEDIGGER", sprite: "gravedigger", blurb: "Flings a spray of grave dirt. Starts with extra bombs.",
    weapon: "DIRT SPRAY", hp: 8, speed: 84, shot: "clod", sound: "hatchet", cost: 40,
    stats: { dmg: 2.4, rate: 2.4, shot_speed: 220.0, life: 0.55, homing: 0.0, size: 1.0, pierce: 0, count: 4, spread: 0.16 },
    start: { bombs: 3 } },
  { id: "alchemist", name: "THE ALCHEMIST", sprite: "alchemist", blurb: "Throws flasks that burst and poison everything nearby.",
    weapon: "FLASKS", hp: 6, speed: 88, shot: "flask", sound: "shoot", cost: 80,
    stats: { dmg: 5.0, rate: 2.0, shot_speed: 160.0, life: 0.85, homing: 0.0, size: 1.0, pierce: 0 },
  },
  { id: "warden", name: "THE WARDEN", sprite: "warden", blurb: "A lantern keeper. Hurls a blazing lantern that flies back.",
    weapon: "LANTERN", hp: 8, speed: 84, shot: "boomer", sound: "hatchet", cost: 140,
    stats: { dmg: 4.5, rate: 2.0, shot_speed: 210.0, life: 0.9, homing: 0.0, size: 1.2, pierce: 99 } },
]

def relic(id, rarity, name, desc, fx)
  { id: id, rarity: rarity, name: name, desc: desc, fx: fx }
end

RELICS = [
  # --- base set ---
  relic("whetstone", :common, "WHETSTONE", "+25% DAMAGE", lambda { |p| p[:dmg] *= 1.25 }),
  relic("twitch", :common, "TWITCHING FINGER", "+20% FIRE RATE", lambda { |p| p[:rate] *= 1.2 }),
  relic("splitfang", :rare, "SPLIT FANG", "+1 PROJECTILE, -10% DAMAGE", lambda { |p| p[:count] += 1; p[:dmg] *= 0.9 }),
  relic("owl", :common, "OWL FEATHER", "+25% SHOT SPEED AND RANGE", lambda { |p| p[:shot_speed] *= 1.25; p[:life] *= 1.15 }),
  relic("sparrow", :common, "SPARROW BOOTS", "+15% MOVE SPEED", lambda { |p| p[:speed] *= 1.15 }),
  relic("garnet", :rare, "BLOOD GARNET", "+1 MAX HEART, HEALS 1 HEART", lambda { |p| p[:max_hp] += 2; p[:hp] = [p[:max_hp], p[:hp] + 2].min }),
  relic("bramble", :common, "BRAMBLE RING", "SHOTS PIERCE 1 MORE FOE", lambda { |p| p[:pierce] += 1 }),
  relic("sap", :rare, "RUBBER SAP", "SHOTS BOUNCE OFF WALLS", lambda { |p| p[:bounce] += 1; p[:life] *= 1.2 }),
  relic("seeker", :rare, "SEEKER'S EYE", "SHOTS HOME IN ON FOES", lambda { |p| p[:homing] += 2.5 }),
  relic("coal", :common, "CINDER COAL", "25% CHANCE TO BURN", lambda { |p| p[:burn] += 0.25 }),
  relic("needle", :common, "FROST NEEDLE", "25% CHANCE TO CHILL FOES", lambda { |p| p[:chill] += 0.25 }),
  relic("viper", :common, "VIPER TOOTH", "HITS POISON FOES", lambda { |p| p[:poison] += 1 }),
  relic("luckycoin", :common, "CROOKED COIN", "+12% CRIT CHANCE", lambda { |p| p[:crit] += 0.12 }),
  relic("hourglass", :common, "SAND GLASS", "ROLL RECHARGES 35% FASTER", lambda { |p| p[:dodge_cd] *= 0.65 }),
  relic("lantern", :rare, "GRAVE LANTERN", "KILLS HAVE 6% CHANCE TO HEAL", lambda { |p| p[:lifesteal] += 0.06 }),
  relic("buckler", :rare, "IRON BUCKLER", "BLOCKS THE FIRST HIT IN EACH ROOM", lambda { |p| p[:buckler] = true }),
  relic("moon", :epic, "PALE MOON", "AN ORB CIRCLES YOU AND BLOCKS SHOTS", lambda { |p| p[:orbitals] += 1 }),
  relic("sapbomb", :rare, "POWDER POUCH", "ROLLING DROPS A BOMB", lambda { |p| p[:bomb_dodge] = true }),
  relic("dice", :rare, "LOADED DIE", "15% CHANCE TO FIRE A TRIPLE VOLLEY", lambda { |p| p[:triple] += 0.15 }),
  relic("arrowhead", :common, "BARBED TIP", "+15% DAMAGE, +15% SHOT SPEED", lambda { |p| p[:dmg] *= 1.15; p[:shot_speed] *= 1.15 }),
  relic("thorn", :common, "THORN LEAF", "FOES THAT TOUCH YOU TAKE DAMAGE", lambda { |p| p[:thorns] += 10 }),
  relic("crown", :rare, "PAUPER'S CROWN", "+50% GOLD, SHOPS 20% CHEAPER", lambda { |p| p[:gold_mult] *= 1.5; p[:shop_disc] = [0.6, p[:shop_disc] + 0.2].min }),
  relic("heavy", :epic, "LEAD SHOT", "BIGGER SHOTS, +30% DAMAGE, -10% RATE", lambda { |p| p[:size] *= 1.35; p[:dmg] *= 1.3; p[:rate] *= 0.9 }),
  relic("fever", :rare, "FEVER SCROLL", "KILLS GRANT A BURST OF FIRE RATE", lambda { |p| p[:frenzy] += 1 }),
  relic("bonecharm", :rare, "BONE CHARM", "+1 ROLL CHARGE", lambda { |p| p[:dodge_charges] += 1; p[:charges] += 1 }),
  relic("glassheart", :epic, "GLASS HEART", "+60% DAMAGE, -1 MAX HEART", lambda { |p| p[:dmg] *= 1.6; p[:max_hp] = [2, p[:max_hp] - 2].max; p[:hp] = [p[:hp], p[:max_hp]].min }),
  relic("echo", :rare, "ECHO RING", "ALSO FIRES A SHOT BEHIND YOU", lambda { |p| p[:backshot] += 1 }),
  relic("witcheye", :epic, "WITCH EYE", "+15% CRIT, CRITS DEAL X2.5", lambda { |p| p[:crit] += 0.15; p[:crit_mult] = [p[:crit_mult], 2.5].max }),
  relic("rage", :rare, "WRATH EMBER", "+50% DAMAGE WHILE AT 1 HEART OR LESS", lambda { |p| p[:rage] += 0.5 }),
  relic("lodestone", :rare, "LODESTONE", "PULLS GOLD, +25% GOLD", lambda { |p| p[:magnet] = true; p[:gold_mult] *= 1.25 }),
  relic("sigil", :epic, "WARDING SIGIL", "TAKING DAMAGE RELEASES A NOVA", lambda { |p| p[:ward] += 1 }),
  relic("shells", :rare, "VOLATILE SHELLS", "SHOTS BURST ON IMPACT", lambda { |p| p[:explode] += 1 }),
  relic("spark", :rare, "CHAIN SPARK", "30% CHANCE HITS ARC TO A NEARBY FOE", lambda { |p| p[:chain] += 0.3 }),
  relic("keyring", :common, "WARDEN'S KEY", "+1 POTION SLOT, GAIN 1 POTION", lambda { |p| p[:max_potions] += 1; p[:potions] = [p[:max_potions], p[:potions] + 1].min }),
  # --- cache I (common) ---
  relic("tallow", :common, "TALLOW CANDLE", "+1 BOMB, BOMBS DEAL +50% DAMAGE", lambda { |p| p[:bombs] += 1; p[:bomb_mult] *= 1.5 }),
  relic("skeletonkey", :common, "SKELETON KEY", "+2 KEYS", lambda { |p| p[:keys] += 2 }),
  relic("quiver", :common, "QUIVER STRAP", "+10% FIRE RATE, +10% SHOT SPEED", lambda { |p| p[:rate] *= 1.1; p[:shot_speed] *= 1.1 }),
  relic("filings", :common, "IRON FILINGS", "+1 ARMOR", lambda { |p| p[:armor] += 1 }),
  relic("gravedust", :common, "GRAVE DUST", "FOES DROP 30% MORE GOLD", lambda { |p| p[:gold_drop] *= 1.3 }),
  relic("mothwing", :common, "MOTH WING", "ROLLS GO FURTHER AND FASTER", lambda { |p| p[:roll_speed] *= 1.25 }),
  relic("bitterroot", :common, "BITTER ROOT", "POTIONS HEAL 1 MORE HEART", lambda { |p| p[:potion_heal] += 2 }),
  relic("tinwhistle", :common, "TIN WHISTLE", "+10% MOVE SPEED, ROLL RECHARGES FASTER", lambda { |p| p[:speed] *= 1.1; p[:dodge_cd] *= 0.9 }),
  relic("chalk", :common, "MAPPER'S CHALK", "HIDDEN WALLS GLOW, +1 BOMB", lambda { |p| p[:reveal] = true; p[:bombs] += 1 }),
  relic("rustynail", :common, "RUSTY NAIL", "+1 PIERCE, +10% DAMAGE", lambda { |p| p[:pierce] += 1; p[:dmg] *= 1.1 }),
  # --- cache II (rare) ---
  relic("wispjar", :rare, "WISP JAR", "A WISP FOLLOWS YOU AND SHOOTS FOES", lambda { |p| p[:familiars] += 1 }),
  relic("emberheart", :rare, "EMBER HEART", "FOES NEAR YOU CATCH FIRE", lambda { |p| p[:aura] += 1 }),
  relic("boneshield", :rare, "BONE SHIELD", "+2 ARMOR", lambda { |p| p[:armor] += 2 }),
  relic("huntersmark", :rare, "HUNTER'S MARK", "+35% DAMAGE TO ELITES AND BOSSES", lambda { |p| p[:elite_mult] += 0.35 }),
  relic("glasslens", :rare, "GLASS LENS", "SHOTS GROW AND HIT HARDER AS THEY FLY", lambda { |p| p[:lens] = true }),
  relic("staticcoil", :rare, "STATIC COIL", "EVERY 4 SECONDS, RELEASE A RING OF SPARKS", lambda { |p| p[:coil] += 1 }),
  relic("bloodoath", :rare, "BLOOD OATH", "+1 MAX HEART FOR EACH GUARDIAN SLAIN", lambda { |p| p[:oath] = true }),
  relic("ricochet", :rare, "RICOCHET BEAD", "SHOTS JUMP TO ANOTHER FOE AFTER A HIT", lambda { |p| p[:ricochet] += 1 }),
  relic("misers", :rare, "MISER'S PURSE", "+1% DAMAGE FOR EVERY 10 GOLD HELD", lambda { |p| p[:miser] = true }),
  relic("shadowstep", :rare, "SHADOW STEP", "ROLLING THROUGH FOES DAMAGES THEM", lambda { |p| p[:shadowstep] = true }),
  relic("coldiron", :rare, "COLD IRON", "+10% DAMAGE, +15% CHANCE TO CHILL", lambda { |p| p[:dmg] *= 1.1; p[:chill] += 0.15 }),
  relic("splinter", :rare, "SPLINTER", "KILLS BURST INTO SHARDS", lambda { |p| p[:splinter] += 1 }),
  # --- cache III (epic and legendary) ---
  relic("phoenix", :epic, "PHOENIX FEATHER", "ONCE PER RUN, RISE AGAIN WITH 2 HEARTS", lambda { |p| p[:revive] += 1 }),
  relic("twinwisp", :epic, "TWIN LANTERNS", "TWO WISPS FOLLOW YOU", lambda { |p| p[:familiars] += 2 }),
  relic("stormcrown", :epic, "STORM CROWN", "HITS MAY CALL DOWN LIGHTNING", lambda { |p| p[:storm] += 0.2 }),
  relic("hollowmirror", :epic, "HOLLOW MIRROR", "ENEMY SHOTS SLOW DOWN NEAR YOU", lambda { |p| p[:mirror] = true }),
  relic("gildedtooth", :epic, "GILDED TOOTH", "SHOPS 30% CHEAPER, +25% GOLD", lambda { |p| p[:shop_disc] = [0.6, p[:shop_disc] + 0.3].min; p[:gold_mult] *= 1.25 }),
  relic("overcharge", :epic, "OVERCHARGE", "+1 PROJECTILE, +15% RATE, -1 MAX HEART", lambda { |p| p[:count] += 1; p[:rate] *= 1.15; p[:max_hp] = [2, p[:max_hp] - 2].max; p[:hp] = [p[:hp], p[:max_hp]].min }),
  relic("deepeye", :legend, "EYE OF THE DEEP", "+2 PROJECTILES THAT HOME IN", lambda { |p| p[:count] += 2; p[:homing] += 2.5 }),
  relic("cindercrown", :legend, "CROWN OF CINDERS", "+50% DAMAGE, SHOTS OFTEN BURN", lambda { |p| p[:dmg] *= 1.5; p[:burn] += 0.35 }),
  relic("ageglass", :legend, "GLASS OF AGES", "+2 ROLL CHARGES, ROLLING RELOADS", lambda { |p| p[:dodge_charges] += 2; p[:charges] += 2; p[:roll_reload] = true }),
  relic("worldseed", :legend, "WORLDSEED", "+2 MAX HEARTS, HEAL FULLY", lambda { |p| p[:max_hp] += 4; p[:hp] = p[:max_hp] }),
]
RELIC_BY_ID = {}
RELICS.each { |r| RELIC_BY_ID[r[:id]] = r }
BASE_RELICS = RELICS[0, 34].map { |r| r[:id] }
CACHE_1 = %w(tallow skeletonkey quiver filings gravedust mothwing bitterroot tinwhistle chalk rustynail)
CACHE_2 = %w(wispjar emberheart boneshield huntersmark glasslens staticcoil bloodoath ricochet misers shadowstep coldiron splinter)
CACHE_3 = %w(phoenix twinwisp stormcrown hollowmirror gildedtooth overcharge deepeye cindercrown ageglass worldseed)
RARITY_COL = { common: "grey", rare: "cyan", epic: "purple", legend: "gold" }
RARITY_HEX = { common: "#8b8f9c", rare: "#4d9be6", epic: "#a35bd6", legend: "#f2c94c" }
RARITY_NAME = { common: "COMMON", rare: "RARE", epic: "EPIC", legend: "LEGENDARY" }
# Rarity weights per source.
LOOT = {
  chest: { common: 60, rare: 30, epic: 9, legend: 1 }, shop: { common: 55, rare: 35, epic: 9, legend: 1 },
  iron: { common: 15, rare: 45, epic: 30, legend: 10 }, boss: { common: 20, rare: 45, epic: 28, legend: 7 },
  secret: { common: 25, rare: 40, epic: 25, legend: 10 }, cursed: { common: 0, rare: 30, epic: 50, legend: 20 },
  altar: { common: 30, rare: 45, epic: 20, legend: 5 },
}

ENEMIES = {
  "bat" => { sprite: "bat", hp: 6, speed: 72, r: 5, ai: :bat, fly: true, gold: 0.25 },
  "slime" => { sprite: "slime", hp: 14, speed: 40, r: 6, ai: :slime, gold: 0.3 },
  "slimelet" => { sprite: "slime", hp: 5, speed: 55, r: 4, ai: :slime, gold: 0.1, scale: 0.7 },
  "skeleton" => { sprite: "skeleton", hp: 11, speed: 42, r: 5, ai: :archer, gold: 0.35 },
  "mushroom" => { sprite: "mushroom", hp: 16, speed: 18, r: 6, ai: :spore, gold: 0.35 },
  "cultist" => { sprite: "cultist", hp: 20, speed: 34, r: 6, ai: :cultist, gold: 0.45 },
  "imp" => { sprite: "imp", hp: 11, speed: 60, r: 5, ai: :imp, fly: true, gold: 0.35 },
  "knight" => { sprite: "knight", hp: 34, speed: 36, r: 6, ai: :knight, gold: 0.6 },
  "ghost" => { sprite: "ghost", hp: 15, speed: 46, r: 5, ai: :ghost, fly: true, gold: 0.35 },
  "bookwyrm" => { sprite: "bookwyrm", hp: 12, speed: 55, r: 5, ai: :book, fly: true, gold: 0.35 },
  "drowned" => { sprite: "drowned", hp: 24, speed: 30, r: 6, ai: :drowned, gold: 0.45 },
  "wisp" => { sprite: "wisp", hp: 9, speed: 80, r: 5, ai: :wisp, fly: true, gold: 0.3 },
  "golem" => { sprite: "golem", hp: 46, speed: 26, r: 7, ai: :golem, gold: 0.7 },
}

BOSSES = {
  "colossus" => { name: "THE BONE COLOSSUS", sprite: "colossus", hp: 420, r: 13, scale: 2 },
  "sporemother" => { name: "THE SPORE MOTHER", sprite: "sporemother", hp: 540, r: 13, scale: 2 },
  "librarian" => { name: "THE DROWNED LIBRARIAN", sprite: "librarian", hp: 640, r: 13, scale: 2 },
  "tyrant" => { name: "THE FORGE TYRANT", sprite: "tyrant", hp: 760, r: 13, scale: 2 },
  "rimewarden" => { name: "THE RIME WARDEN", sprite: "rimewarden", hp: 880, r: 13, scale: 2 },
  "regent" => { name: "THE PALE REGENT", sprite: "regent", hp: 1000, r: 13, scale: 2 },
}

FLOORS = [
  { name: "THE OSSUARY", accent: "bone", accent_hex: "#d9d0b4", pool: %w(bat slime skeleton skeleton bat mushroom), boss: "colossus", rooms: 8 },
  { name: "MIREWOOD GROTTO", accent: "lime", accent_hex: "#b8e05a", pool: %w(mushroom slime imp ghost bat skeleton), boss: "sporemother", rooms: 9 },
  { name: "THE SUNKEN ARCHIVE", accent: "cyan", accent_hex: "#6fd3e0", pool: %w(bookwyrm drowned ghost bookwyrm skeleton slime), boss: "librarian", rooms: 9 },
  { name: "THE CINDERFORGE", accent: "orange", accent_hex: "#e8873a", pool: %w(imp cultist knight skeleton imp mushroom), boss: "tyrant", rooms: 10 },
  { name: "RIMEFROST VAULT", accent: "white", accent_hex: "#e8f6ff", pool: %w(wisp golem knight wisp ghost cultist), boss: "rimewarden", rooms: 10 },
  { name: "THE HOLLOW THRONE", accent: "purple", accent_hex: "#a35bd6", pool: %w(cultist knight ghost drowned golem bookwyrm imp), boss: "regent", rooms: 11 },
]
BOSS_TRACK = 6

SPRITE_COLOR = {
  "bat" => "#a35bd6", "slime" => "#63b84f", "skeleton" => "#d9d0b4", "mushroom" => "#d8443c", "cultist" => "#8a2a33",
  "imp" => "#d8443c", "knight" => "#8b8f9c", "ghost" => "#f4ecd8", "bookwyrm" => "#7a5236", "drowned" => "#63b84f",
  "wisp" => "#6fd3e0", "golem" => "#4d9be6", "colossus" => "#d9d0b4", "sporemother" => "#a35bd6", "librarian" => "#2b4f8a",
  "tyrant" => "#e8873a", "rimewarden" => "#6fd3e0", "regent" => "#a35bd6",
}

# Ember Shrine: things to unlock between runs.
UNLOCKS = [
  { id: "hero_gravedigger", name: "THE GRAVEDIGGER", desc: "A NEW HERO WHO SPRAYS GRAVE DIRT", cost: 40 },
  { id: "hero_alchemist", name: "THE ALCHEMIST", desc: "A NEW HERO WITH POISON FLASKS", cost: 80 },
  { id: "hero_warden", name: "THE WARDEN", desc: "A NEW HERO WITH A RETURNING LANTERN", cost: 140 },
  { id: "cache1", name: "RELIC CACHE I", desc: "ADDS 10 COMMON RELICS TO THE CRYPT", cost: 30 },
  { id: "cache2", name: "RELIC CACHE II", desc: "ADDS 12 RARE RELICS TO THE CRYPT", cost: 70 },
  { id: "cache3", name: "RELIC CACHE III", desc: "ADDS 10 EPIC AND LEGENDARY RELICS", cost: 120 },
  { id: "perk_gold", name: "DEEP POCKETS", desc: "START EVERY RUN WITH 20 GOLD", cost: 25 },
  { id: "perk_bombs", name: "HEAVY SATCHEL", desc: "START EVERY RUN WITH 2 EXTRA BOMBS", cost: 20 },
  { id: "perk_potion", name: "SPARE FLASK", desc: "START EVERY RUN WITH 1 EXTRA POTION", cost: 35 },
  { id: "perk_key", name: "KEY RING", desc: "START EVERY RUN WITH A KEY", cost: 30 },
  { id: "perk_heart", name: "IRON WILL", desc: "START EVERY RUN WITH +1 MAX HEART", cost: 70 },
  { id: "perk_relic", name: "LUCKY START", desc: "START EVERY RUN WITH A RANDOM RELIC", cost: 90 },
  { id: "perk_choice", name: "KEEN EYE", desc: "CHESTS OFFER 4 RELICS INSTEAD OF 3", cost: 110 },
]

DREAD_DESC = [
  "NORMAL", "FOES +15% HEALTH", "FOES +30% HEALTH, FASTER SHOTS", "MORE ELITES, PRICIER SHOPS",
  "GUARDIANS ENRAGE EARLY", "START WITH 1 LESS HEART",
]
