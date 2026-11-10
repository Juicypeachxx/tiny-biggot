# The floors' new look (ROADMAP 4.7 part B)

His ask, 5 Oct: "revamp environments, make them less boring". Before, every floor was the same
rectangle with the same square pillars and near-flat tiles; only the colour changed. On 6 Oct he
added "revamp original stages too": the look also applies to the original game (`--classic`).

`scripts/render/biome_deco.gd` (class `BiomeDeco`), hooked into `world_view.gd` (`_paint_bg`,
`_paint_glow`, `_paint_parts`, `refresh`). Drawing only, with its own random numbers (the room's
seed for what is fixed, its own generator for the air): no rule changes, and the six classic
replays stay identical. Rift worlds, Rex's barn and rooms with a kit of their own keep their look.

| Floor | Props (instead of the pillar) | Floor | Centre piece | Wall | Air | Pits |
|---|---|---|---|---|---|---|
| 1 Ossuary | bone pile, coffin, urn | bones, cracks, cobwebs | bone mosaic | skull niches, chains | dust | chasm |
| 2 Mirewood Grotto | stump, giant mushroom, mossy rock | moss, grass, puddles, mushrooms | moss ring | vines, glowing mushrooms | spores | water |
| 3 Sunken Archive | bookshelf, book pile, bust | pages, puddles, seaweed | shallow pool | shelves, windows | bubbles | water |
| 4 Cinderforge | anvil, brazier (lit), iron barrel | glowing cracks, soot, coal, plates | forge grate (lit) | vents, chains | embers | lava |
| 5 Rimefrost Vault | ice crystal, frosted pillar, strongbox | frost, ice cracks, sparkles | frozen patch | icicles, chains | glints | ice |
| 6 Hollow Throne | gilded column, candelabra (lit), armour | marble veins, wax, gold bits | red carpet | portraits, banners | gold dust | chasm |
| 7 Rainmarsh Hamlet | lamppost (lit), hay bale, rain barrel | puddles, mud, grass, leaves | boardwalk | windows, vines | rain | water |
| 8 Ashen Warfront | sandbags, stakes, broken wheel | scorch, ash, arrows, blood | crater | weapon racks, banners | ash | lava |
| 9 Frostpeak Monastery | stone lantern (lit), bell, monk statue | snow, seams, petals | woven mat | prayer flags, chains | snow | ice |
| 10 Nightspire Rooftops | chimney, gargoyle, weathervane | shingles, puddles, feathers | skylight | windows, vents | wind | chasm |
| 11 The Eclipse | obelisk (lit), monolith, floating shard | runes, void cracks | sigil circle (lit) | eyes, chains | motes | void |

New layouts 17-20 (expanded game only, `World.build_room`): pools in the quarters, a broken
channel, sinkholes, long pits. A pit is `World.T_VOID`: heroes and walking foes cannot cross it,
flyers and shots pass over. A hero pushed onto one steps back to floor (`Hazards._off_the_edge`),
and anything dropped on one lands on the nearest floor (`Combat.drop_pickup`).

Checked: screenshots of every floor; classic replays identical; 23 bot soaks of 10 minutes (every
floor, with and without god mode, and one classic), 0 errors, none stuck. Not measured on the
iPad: the frame rate (the room picture is drawn once per room; the air is at most 40 small
rectangles a frame).
