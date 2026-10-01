# Tiny Biggot Rogues — Design Spec

Read this fully before writing code. It extends the conversion brief.
Stages 1–2 of the port already exist on the branch.

**Section 0 overrides everything else in this document:** the original game
is preserved, and everything below is an *addition* to it.

---

## 0. GOLDEN RULE: the original game stays the same

The game in `TinyBiggot-Stage2.zip` is the **core and it is not to be
redesigned**. Its existing mechanics, balance, heroes, items, rooms,
controls and feel must be preserved exactly. This document only lists
**additions**.

- **Extend existing systems, never replace them.** Add new entries to the
  existing data tables and hook new effects into the existing code paths.
- **If a requested feature already exists, do not rebuild it.** Verify it
  works, polish it, and extend it only where this spec asks for more.
- **Never delete or rebalance original content** to make room for new
  content. New items are added alongside the originals.
- If an addition genuinely conflicts with the original design, **stop and
  ask the user** instead of changing the original.

### What ALREADY EXISTS in the original (verify, keep, extend)

| Requested feature | Already in original Ruby | Action |
|---|---|---|
| Characters | `HEROES` — 6 heroes: Hexer, Poacher, Brute, Gravedigger, Alchemist, Warden | Keep all 6 unchanged. Add new heroes alongside. |
| Level-up traits | `TRAITS`, `gain_xp`, level/xp/pending, rerolls, luck | Keep. Add new traits into the same system. |
| Trait synergies | `FAMILIES` + `FAMILY_BONUS` (trait families with bonuses) | Keep. Add new families/bonuses. |
| Weapons + archetypes | `WEAPONS`, `ARCH`, `ARCH_DESC` (in 04b_items) | Keep. Add new weapons/archetypes. |
| Tags | `TAG_COLS` | Keep. Reuse/extend tags for synergies. |
| Relics | `RELICS` with common/rare/epic/legend rarities | Keep. Add new relics. |
| Stat multipliers | `MUL_KEYS` | Keep. Extend if new stats need it. |
| Skill tree | `SKILL_BRANCHES`, `HERO_BRANCH`, `TREE_COSTS` | Keep. Add perks + branches for new heroes. |
| Room choice + reward preview | World.rb: "after each room you pick the next door, and every door shows its room type and reward"; `ROOM_KINDS`, `REWARDS`, `roll_reward` | **Already implemented.** Verify and polish only. |
| Enemies, bosses, floors | `ENEMIES`, `BOSSES`, `FLOORS` | Keep. Add new biomes after the existing floors. |
| Meta-progression | `UNLOCKS`, `$meta` | Keep. Extend. |
| Difficulty | `DREAD_DESC` | Keep. |

Anything in sections 2–10 that overlaps this table means **extend the
existing version**, not create a parallel system.

### Step 0a: audit the current build

Before adding anything:
1. Run the project headless and report every error and warning.
2. Run the stability soak test (section 11) against the current build.
3. **Compare the Godot build against the original Ruby, system by
   system** using the table above: what is ported, what is missing, what
   behaves differently. Check numbers (damage, speeds, costs, drop rates)
   match the Ruby source exactly.
4. Check the Ruby→GDScript traps from the conversion brief (negative
   modulo, integer division, truthiness, SeedRng masking) in all ported code.

### Step 0b: polish the existing game

Fix and polish without changing the design:
- Fix every bug and porting mismatch found in 0a.
- Make sure every original hero, trait, relic, weapon, enemy, boss and
  room type works as it did in Ruby.
- Polish: hit feedback, pickup feedback, menu responsiveness, text
  alignment, touch control comfort on iPad — anything that improves feel
  without changing mechanics or balance.
- List every change made, so the user can review it.

**Stop and report** to the user before starting any new feature.

---

## 1. Identity and IP rules (non-negotiable)

- Game title: **Tiny Biggot Rogues** (window title, title screen, project name).
- All characters, weapons, equipment, relics, enemies and text must be
  **original**. Inspiration lists in this document are for *mood and
  archetype only*.
- Do NOT use names, characters, likenesses, logos or text from:
  Tiny Rogues, The Witcher, Berserk, Vagabond, GTA V, Dead Cells,
  Slay the Spire, Crimson Desert, or any other existing work.
  No named weapons from other games (e.g. no "Dragonslayer").
- Homage by archetype is fine: "a scarred monster hunter", "a berserker
  with an absurdly large iron greatsword", "a wandering swordsman".
- Keep the game's existing original art. New content can reuse/recolour
  existing sprites or use simple placeholder art, clearly marked.

---

## 2. Core architecture — build this BEFORE any content

Content volume (1,200+ items) is only achievable and stable if items are
**data**, not code.

### 2a. Data-driven content
- Every weapon, equipment piece, relic, trait, perk, enemy and room is a
  data entry (JSON or Godot `Resource`), not a hand-written class.
- An item = metadata + a list of **effects**.

### 2b. Effect system
Effects are small reusable building blocks, combined by data:

- **Stat modifiers:** flat, additive %, multiplicative %. Apply in that
  order: `(base + flat) * (1 + sum_additive) * product(multiplicative)`.
- **Triggers:** `on_hit`, `on_crit`, `on_kill`, `on_roll`, `on_damage_taken`,
  `on_heal`, `on_room_enter`, `on_room_clear`, `on_level_up`, `on_shoot`,
  `every_n_shots`, `every_n_seconds`, `while_low_hp`, `on_pickup`.
- **Actions:** spawn projectile, explode, apply status, heal, gain stat
  for duration, chain lightning, summon, gain gold, refund cooldown, etc.
- **Statuses:** burn, poison, bleed, chill/freeze, shock, curse, vulnerable,
  weakened — each with stacking rules and a tick.
- **Tags** on everything: `fire`, `crit`, `bleed`, `summon`, `projectile`,
  `melee`, `roll`, `greed`, `blood`, `holy`, `curse`, etc. Synergies key off tags.

### 2c. Synergy system
- **Tag synergies:** e.g. 3+ `fire` items → burn spreads on death.
- **Set bonuses** for equipment (2-piece / 4-piece).
- **Named combos:** specific item pairs that unlock a special effect.
  Show the player when a synergy activates — that moment is the reward.

---

## 3. "Broken builds" without a broken game

The player must be able to stack traits into absurd power. "Broken" means
**huge numbers and screen-filling chaos, never crashes or freezes.**

Hard safety rails:
- **Proc depth limit:** a trigger can cause another trigger at most N
  levels deep (e.g. 4). Prevents infinite on-hit → spawn → on-hit loops.
- **Per-frame proc budget:** cap trigger executions per frame; queue the rest.
- **Bullet hard cap** (e.g. 2,000) with pooling. Over cap, merge or skip
  visuals, never stop simulating damage.
- **Attack-speed floor:** minimum interval between shots.
- **Damage as float**, clamp display, never overflow.
- **Summon cap** per player.
- Batch-render bullets and particles (MultiMesh / single `_draw`).

Uncapped on purpose: damage, crit chance past 100% (overcrit), multipliers.

---

## 4. Leveling and traits

- XP from kills. Level up → **choose 1 of 3 traits** (reroll costs gold).
- Rarities: Common / Uncommon / Rare / Legendary / Cursed (strong + drawback).
- Traits **stack**: picking the same trait again increases its tier.
- Weighted offers: traits matching tags you already own appear more often,
  so a build snowballs (this is what makes it feel like proper progression).

### Core build archetypes (each needs ~15–25 supporting traits)
1. **Crit** — crit chance, crit damage, overcrit
2. **Bleed / Blood** — bleed stacks, life-steal, pay HP for power
3. **Fire** — burn, spread, explosions
4. **Poison** — stacking DoT, contagion
5. **Lightning** — chain, shock, attack speed
6. **Projectile storm** — extra projectiles, pierce, ricochet, split
7. **Summoner** — minions, familiars, turrets
8. **Roll / Evasion** — roll attacks, i-frames, roll damage
9. **Tank / Thorns** — armor, reflect, damage from max HP
10. **Berserk** — power at low HP, rage stacks
11. **Greed** — gold scaling, shop power, gold as damage
12. **Curse** — powerful items with drawbacks, scaling with curses

Plus a handful of deliberately **build-defining Legendary traits**
designed to enable broken combos — document each intended combo.

---

## 5. Weapons — target 400+

- Categories: swords, greatswords, daggers, axes, spears, hammers, fists,
  bows, crossbows, guns, wands, staffs, throwing weapons, whips, scythes,
  shields, oddities.
- **Every weapon has a unique ability**, not just different numbers.
  Examples of the bar: "every 7th shot fires backwards and homes",
  "kills drop a spinning blade", "damage grows with distance travelled".
- Rarity + level scaling. Finding a rare weapon must feel like a moment:
  pickup fanfare, name card, ability description.
- Original names. Archetype homages allowed (giant iron slab greatsword,
  silver monster-hunter blade, katana of a wandering swordsman,
  sawn-off shotgun, card-throwing deck) — **own names, own designs**.
- Each weapon carries tags so it plugs into synergies.

## 6. Equipment — target 400+

- Slots: Helmet, Armor, Gloves, Boots, Amulet, Ring ×2, Trinket.
- Each piece: stats + **one unique effect**.
- Sets with 2/4-piece bonuses; tag synergies with weapons and traits.

## 7. Relics — target 400+

- Passive, permanent for the run, tagged.
- Mix of: simple strong, conditional, synergy enablers, cursed bargains,
  and a small number of legendary "run-defining" relics.

---

## 8. Characters — original, inspired by archetypes

The 6 original heroes stay exactly as they are. **Add** ~6–8 new characters, each with starting weapon, starting trait, a
unique passive, and its own **skill tree**. Archetype inspirations:

| Archetype (inspired mood) | Playstyle idea |
|---|---|
| Scarred monster hunter (Witcher-like mood) | potions/oils, signs as abilities, bonus vs elites |
| Berserker with a huge iron blade (Berserk-like mood) | slow heavy cleaves, rage, low-HP power |
| Wandering swordsman (Vagabond-like mood) | precise strikes, counters, perfect-dodge rewards |
| Street criminal (GTA-like mood) | guns, gold, chaos, "wanted level" escalation |
| Undying prisoner (Dead Cells-like mood) | weapon swapping, scrolls, respawn mechanic |
| Card-wielder (Slay the Spire-like mood) | ability deck, energy, draw/discard |
| Vast-world mercenary (Crimson Desert-like mood) | mounted charges, versatile combat |

All names, looks and lore original.

### Skill tree (per character)
- Meta-progression between runs, unlocked with a currency earned per run.
- Branches of **helpful perks** (HP, damage, potions, starting gold) and
  **special perks** unique to that character (capstones that change how
  they play).

---

## 9. Biomes and enemies

Keep all original floors, enemies and bosses unchanged. **Add** 5–6 new biomes, each with its own tileset palette, hazards, enemy set,
mini-boss and boss. Mood inspirations:
- Rain-soaked marsh village
- War-torn plains and burning camps
- Ancient crypt (existing game's base)
- Snow mountain monastery
- Night city rooftops and alleys
- Corrupted eclipse realm (final)

Enemies fit their biome thematically and mechanically (marsh: poison and
ambushes; plains: archers and cavalry charges; city: gunmen; etc.).

---

## 10. Room choice with reward preview

**Already implemented in the original** (doors show room type and reward).
Verify it works after the port and polish it. Only add what is missing below,
e.g. new room types or rewards for the new content.

- After clearing a room: **choose 2–3 doors**, randomly generated per area.
- Each door shows **room type** and **reward** before you pick:
  room types: combat, elite, treasure, shop, shrine, rest, challenge, event.
  rewards: gold, weapon, equipment, relic, trait, heal, upgrade, currency.
- Elite/challenge rooms show a better reward — risk vs reward.
- Floor structure guarantees a shop and a rest before each boss.

---

## 11. Stability — test this yourself

- **Content test:** a headless script that loads **every** item, trait,
  relic, weapon and equipment piece, equips it, fires every trigger, and
  checks for errors. Must pass after every content batch.
- **Soak test:** 10+ minutes simulated play with scripted random input
  across multiple floors and characters; no errors, no freezes, object
  counts stable.
- **Broken-build test:** give a test character 50+ stacked traits from
  one archetype; must not crash or drop below playable framerate in a
  headless timing check.
- **Stress test:** 500+ bullets, max summons.
- Report anything that couldn't be tested.

---

## 12. Build order (stop and report at each ★)

1. Audit + polish the existing game (section 0a, 0b). ★
2. Finish the port (stages 3–4 of the brief). ★
3. Effect / trigger / tag / synergy system + safety rails. ★
4. Leveling + trait selection + room choice with reward preview. ★
5. Content batch 1: ~50 weapons, 50 equipment, 50 relics, 60 traits,
   covering every archetype. Run content test. ★ ← user playtests balance here
6. Characters + skill trees. ★
7. Biomes + enemies + bosses. ★
8. Remaining content in batches of 50, content test after each. ★
9. Polish, balance pass, final stability tests. ★

**Quality over quantity:** if 400 of something can't each be genuinely
distinct, stop at fewer good ones and say so. Every item must have a
reason to exist.
