class_name Versions
extends RefCounted
## Every build's number, name and tweaks (his word, 9 Oct: "name versions of the game with latest
## tweaks and version number"). Newest first, and the newest is the number in the file VERSION.
## The title screen shows the newest. The IPA build (.github/workflows/build-ipa.yml) reads these
## lines with tools/versions.sh for the release's title and notes and the IPA's file name, and
## names the older releases from theirs. So keep one version a line, number|Name|tweak; tweak,
## with no quote or | inside, and add the new version's line at the top in its [ipa] commit.

const LIST := [
	"36|Food and Drink|FOOD: ten foods give XP and STR, DEX or INT, from food rooms, every shop and elites; Golden food on the deepest floors, hidden rooms and the blood altar: a lasting bonus each, like SUNFRUIT +3% crit or ROYAL HONEYCOMB +1 to all stats; Every drink now also gives a buff for 10 rooms, three at once, shown under the belt; New drinks: APPLE CIDER, SAILOR'S GROG and PLUM WINE; WHEEL OF CHEESE: one more drink buff at once; HOLLOW LEG keeps your drink buffs for good; GOURMAND, PICNIC BASKET and the GOLDEN SPOON",
	"35|Dice and Pace|DICE: REROLL, ALTER and BANISH bend your luck on trait picks, relic choices and backpack items (MENU, HEAL, BOMB or tap the dice); BANISH sends a trait, relic or item away for the whole run; Every shop sells a die and has a DICE CUP that restocks it; Dice from elites, chests, hidden rooms and guardians; HOUSE RULES, FIXED ODDS, HIGH ROLLER, GAMBLER'S POUCH and KNUCKLEBONES; Faster rooms: the next wave comes sooner and foes appear faster; FINISH THEM: the last foes of a room are marked and you hit them harder; CLEAR RUSH: run faster to the door once a room is clear; FIRST SPOILS: a chest after your first fight and an item after the second; Clearer fights: foe shots and warnings are drawn over all your effects with a dark rim, and your hero has a light ring at the feet",
	"34|Luck and Legions|LUCKY HITS: a chance on every hit to strike again, growing with DEX; SPELLSLINGER: crits and lucky hits cast the weapon in your first backpack slot for free; STATIC BUILD-UP, JACKPOT, QUICK FINGERS and the WISHBONE; New hero THE TRICKSHOT, who starts with RUNE CHALK in the backpack; Companions grow together: wisps, skeletons, turrets and pets share damage, speed and how many can be out; Your extra move speed speeds them up: QUICK MARCH and MARCHING BOOTS; GRAVE MARSHAL, BONE BEACON, ENDLESS RANKS; New hero THE BONECALLER, every fight opens with two skeletons",
	"33|Minds and Taverns|Fixed: big green slimes no longer grow tougher without end from the coins they swallow (at most twice and a bit their health now); Fixed: foe shots leaving the room broke the other foe shots for a moment; THE MIND FIELD: halos grow with INT until they fill the room, with six new traits like OVERMIND and DEEP WELL, WITHERING VEIL, BLOOD HAZE and the HORIZON RING; New hero THE MINDWARDEN; THE TAVERN: drinks make you TIPSY, more damage and attack speed that stack up; FROTHY ALE, DARK STOUT and HONEY MEAD for the belt, the saloon gets you tipsy too; Five traits like SURE STRIKE and LAST ORDERS; New hero THE TAVERN KNIGHT",
	"32|Steady and Sound|A full check of everything added since version 24, with every problem it found fixed; HEART OF THE PHOENIX can be worn now; Big fights draw much faster: the remains and scorch marks of fallen foes cost almost nothing to draw now, the same picture; No more stall when a weapon with a huge volley fires into an empty room; Common SUPER traits come from level 2 again; A trait card names the weapon its hidden combo needs and shows COMBO READY while you hold it; The weapon STITCHED DOLL and the trait COMET CALLER have their own names now",
	"31|The Toybox|26 new weapons; 8 new kinds of weapon: LAND SHARKS that swim under the floor and bite, TWISTERS that carry foes and slam them down, a DISCO BALL that makes foes dance, YO-YOS on a cutting string, PORTALS that shoot foes in the back, SAW TRAPS, VOODOO PINS that make pinned foes share their pain, and ANVILS from the sky that stay as cover; SHARKNADO (mythic), MEGALODON, GRAND PIANO, DISCO INFERNO, THE FISH SLAPPER, RUBBER CHICKEN and more; Items can let these toys loose too",
	"30|Oath Vows|Every oath has a vow, like KILL 120 BURNING FOES; keep it and the oath AWAKENS with a second power for the rest of the run; The vow's count shows under the map; THE TRAIT BOOK: a fourth codex page with every trait and oath, lit once you have seen it",
	"29|Oaths and Secrets|Every run opens with an OATH: pick one of three run-shaping traits, from 19; Every trait pick has a rare or better trait in it, and plain traits come up less; 35 new traits, from SPARKPLUG to the mythic DRAGON SOUL; Hidden rooms are never empty: THE GOLDEN GRIMOIRE (a rare trait), A DRAGON'S HOARD, and loot beside every find",
	"28|Version Names|Every version has a name and its tweaks: on the title screen, on its download page and in the name of the IPA file",
	"27|Mythic Armory|A MYTHIC rarity above legendary: guardians, elites and deep drops can give one; Seven mythic armor pieces, one for every slot, like CROWN OF THE STORM KING and HEART OF THE PHOENIX; Six mythic weapons, like WORLD-ENDER and BOW OF THE DAWN GOD; Six more weapons: STARSHELL MORTAR, FROSTFOAM GUN, DECK OF RUNES, SPECTRAL REPEATER, VIPER'S BOW, HAMMER OF THE VOID",
	"26|Mythic Traits|Six legendary traits and six MYTHIC traits; Items can cast spells from the spellbook; Reactions set off traits and synergies; Nine new hidden synergies",
	"25|Reactions|Two ailments on one foe react: MELT, TOXIC BLAST, SHATTER, WITHER, HEMORRHAGE, OVERLOAD; Fourteen new traits; Nine magic weapons and nine melee weapons",
	"24|Brighter Nights|Night floors and the camp at night are lighter, and your lantern reaches further; Armor drops are varied: never the same set twice in a row, and pieces you own come back far less",
	"23|The Spellbook|Ten new kinds of spell and twenty magic weapons; Your slow late fight fixed: giant shots no longer grow over the whole room; Heavy builds run about a quarter faster",
	"22|Endless Descent|Weather and night in the dungeon: storms, fog, dark floors lit by your lantern; THE ENDLESS DESCENT: go as deep as you can, your best depth is kept; A bestiary of every foe you have met; Stability and speed polish",
	"21|A Living World|Speech bubbles: heroes and foes speak at big moments; Rooms keep their story: bones, ink and ash; The sound of every place, and footsteps that change with the floor; A rival adventurer, lost travellers and the ghost of your last hero; Sleeping foes, packs and monsters with lives of their own; The camp follows the iPad's clock",
	"20|Chapter IV|CHAPTER IV, THE LIBRARY: a new world after the Reader, with its own foes, guardians and gear sets; Camp upgrades and a quest board; A second balance pass: the weakest heroes and traits raised",
	"19|Camp Life|THE COOK turns your fish into meals for the next run; Visitors at the camp and a training ground with dummies; Swords and whips gain from extra projectiles",
	"18|Daily Trial|THE DAILY TRIAL: one fixed run a day; A new hero from the story: THE INKLING; A balance pass from many bot runs: the weak raised",
	"17|The Camp|THE CAMP: a home between runs with the Archivist, the Angler and the Bookbinder; Livelier fights: weather on every floor, foes that react to kegs and pots, cover; A speed check of the heaviest rooms",
	"16|Rooms Revamp|Every special room dressed up: the hoard, the stall, the shrine, the vault, hidden rooms, the arena; Pots to break, coin heaps and powder kegs; Rats, moths and butterflies that run from you",
	"15.2|Fishing|Fishing: ponds in rest stops and treasure rooms, 16 fish to catch; THE FISHING HOLE with its dock and THE ANGLER; Every fish has its own sprite",
	"14.4|Chapter III|CHAPTER III after the Redactor: its own floors, foes and guardians",
	"14.3|Trait Combos|Two particular traits together unlock a hidden third power",
	"14.2|The Wardrobe|New armor sets for pets, turrets, rolling, gold and curses; A WARDROBE page with every set and its pieces",
	"13.3|Armor Sets|Completing an armor set is much more rewarding; Creative new traits",
	"13.1|Keyboard Keys|Options: KEYBOARD KEYS, every key can be changed",
	"12.4|The Story|A story told by new characters that ties the floors together; CHAPTER II with new stages; New final bosses and hidden final bosses; Endings and unlocks",
	"11.3|Fresh Fun|New weapons with new kinds, rooms and relics; A little harder",
	"10.5|Flails and Neon|Flails that swing round you on a chain; New heroes: a minstrel, a jester and more; New events: a frog to kiss, a ritual circle; Descriptions that show their live values; An optional NEON look",
	"9.3|Chaos Bosses|Chaos attacks: laser beams, hooks and danger circles, shown before they hit; The final fights become chaos; New bosses: a radiant seraph, a dragon and more",
	"8.5|Super Traits|The trait pick revamped; More SUPER traits",
	"8.4|Alignments|Alignments: GOOD, EVIL, LAWFUL and CHAOTIC; Clear info: coloured keywords everywhere; Stat pickups after fights; Fun traits and synergy traits",
	"7.3|Rimefrost|Boss weaknesses; A trophy for every guardian felled; A new rift world: THE RIMEFROST HOLLOWS",
	"6.6|Elite Traits|Every elite rolls a trait: SWIFT, PLATED and more",
	"6.5|Foes Fight Back|Foes read your real strength and stand up to it; Bosses fight behind armor plates",
	"6.4|Clockwork Spire|A new rift world: THE CLOCKWORK SPIRE; A new hero: THE CLOCKMAKER; Eight clockwork weapons; Save a run and CONTINUE it; Minis and Rex evolve",
	"5.9|Evolved Forms|Guardians change shape at every stage: horns, wings, a third eye, a crown of flames",
	"5.8|Harder|Bosses never skip a stage; Tougher foes and guardians; Longer fights with twists; Guardians evolve with their stages",
	"5.7|Small Extras|THE RAIDER in Brazil; Options: MEET THE HAGGLER",
	"5.6|New Look|The whole sprite revamp: icons, tiles, menus and HUD",
	"5.3a|New Foes|The first three floors' foes and guardians redrawn",
	"5.2b|Hero Picks|The heroes you picked: 15 new designs and 9 old ones remastered",
	"5.2|New Heroes|Heroes and their gear redrawn",
	"5.1|Sprite Sample|The first new sprites, in three looks",
	"4.14|Big Expansion|New worlds, event rooms and the saloon; 20 new foes and new guardians; Pets and REX THE FAT GOLDEN RETRIEVER; A hundred new weapons and new gear; Ten new heroes; Guardians with three stages",
]

## The newest version: [number, name, tweaks].
static func newest() -> PackedStringArray:
	return String(LIST[0]).split("|")

## "V28 VERSION NAMES", for the title screen.
static func label() -> String:
	var v := newest()
	return "V%s %s" % [v[0], v[1].to_upper()]
