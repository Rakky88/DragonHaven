# DragonHaven Special Events, Chests, and Eggs

Last verified: 4 September 2026

Ruleset: app version `v0.05.09`

Source baseline: release `v0.05.09`

<!-- reference-source-fingerprint: 6916c5d2e3e0c20d -->

This is the living content catalog for every implemented Special Event,
Special Adventure family, chest type, and egg type in DragonHaven. It records
the current game implementation, including content relationships that are not
yet fully represented in persisted item data.

Exact random percentages, weighted pools, pity rules, and conditional odds live
in [RANDOM_REWARDS_AND_ODDS.md](RANDOM_REWARDS_AND_ODDS.md). This catalog
explains what each item or event *is*, where it belongs, and how its lifecycle
works.

## 1. Content model and terminology

These names describe different concepts:

- A **Special Event** is a scheduled availability window. It owns its story,
  recurrence, start limit, requirements, journey definition, and reward bundle.
- A **Special Adventure** is an Adventure with `AdventureKind.special`. It can
  belong to a scheduled Special Event, but the released-dragon return system
  also creates non-calendar Special Adventures.
- A **Special Chest** is an optional reward belonging to one particular Special
  Adventure definition. Future Special Events do not automatically award one,
  and two Special Events may define completely different Special Chest
  contents.
- A **Special Egg** is an optional, deliberately configured egg. Its possible
  dragon family or families are chosen by the owning event/chest definition;
  “Special Egg” does not globally mean Cluckatrice.

### Current implementation limitation

The intended ownership model above is the design contract for new content. In
the current `v0.05.04` implementation, the inventory still stores one global
`special` chest tier without an event definition ID/version. Opening any such
chest therefore uses the only implemented recipe: the Golden Wings chest with
a Cluckatrice egg, 269 coins, and 10 gems. `DragonEgg` likewise stores the
lineage and egg properties, but not its originating Special Event definition.

Consequences until this is migrated to definition-backed items:

- a future event with different Special Chest or Special Egg contents must not
  reuse the global recipe unchanged;
- traded or imported Special Chests cannot currently prove which event created
  them;
- event-specific item definitions need stable IDs and versions before a second
  distinct Special Chest recipe is released;
- save/import/trade compatibility must keep old Golden Wings items bound to
  their original recipe instead of silently changing their contents.

## 2. Scheduled Special Events

There is currently one entry in `specialAdventureEventCatalog`.

### 2.1 A Wish on Golden Wings

| Field | Current definition |
|---|---|
| Event ID | `golden_wings_birthday` |
| Adventure ID | `special_golden_wings_birthday` |
| English title | A Wish on Golden Wings |
| Dutch title | Een Wens op Gouden Vleugels |
| Theme | A golden birthday wish for a beautiful woman whose kindness brightens the Haven |
| First window | 1 September 2026 00:00 through 3 September 2026 00:00 |
| Recurrence | Every year from 2027, 13 May 00:00 through 14 May 00:00 |
| Schedule timezone | Europe/Amsterdam wall time, including daylight-saving conversion |
| Starts allowed | Once per event occurrence per save/account |
| Journey duration | 10 days before expertise reduction |
| Availability after starting | The run remains finishable after the start window closes |
| Participants | One available owned dragon |
| Expertise reduction | Every combined Might + Spirit + Arcana point removes one hour; minimum duration is one day |
| Event notification | Supported by the Special Events notification category, which defaults to on subject to device permission |

The event card shows its own live availability countdown. The short story is
not repeated in the Adventure detail sheet because `showStoryInDetails` is
currently `false`.

#### Guaranteed completion rewards

- 500 XP for the participating dragon. The Adventure definition and event
  reward metadata both describe this same 500 XP reward; it is not granted
  twice.
- +25 Might, +25 Spirit, and +25 Arcana.
- One Special Chest using the Golden Wings recipe below.
- One relic selected uniformly from Moral Prism, Order Compass, Soul Mirror,
  and Astral Lens.
- One Music Chest if the player has enough remaining unowned tracks for the
  chest to be usable. No replacement reward is granted when the music
  collection has no capacity.

#### Golden Wings Special Chest definition

| Property | Value |
|---|---|
| Inventory tier | `special` |
| Chest sprite | `assets/images/chests/chest_special.webp` |
| Opened sprite | `assets/images/chests/open/chest_special_open.webp` |
| Opening sound | `chest_special` |
| Fixed contents | 269 coins, 10 gems, one Golden Wings Special Egg |
| Additional random find | 10% chance of one still-unowned chest emote |
| Tradeable | Yes in the current app and server inventory model |
| Multi-open | Ten may be opened together when at least ten are owned; each performs a normal independent opening |

The Adventure details intentionally identify the guaranteed Special Chest but
do not reveal its contents to the player before it is opened.

#### Golden Wings Special Egg definition

| Property | Value |
|---|---|
| Egg type | Special Egg |
| Possible family | Cluckatrice only |
| Family type | Special Event |
| Incubation | Exactly 21 hours |
| Spectral chance | 0%; this egg is excluded from both the creation roll and Golden Hour bonus |
| Fixed at creation | Law alignment, moral alignment, size, and personality seed |
| Hatch achievement | `winner_chicken_dinner` — Winner, Winner, Chicken Dinner |

The Cluckatrice family contains Hatchling, Wyrmling, Might, Spirit, Arcana, and
Mastery forms. The egg uses the special egg hint/presentation so it remains
recognizable as event content without revealing its dragon early.

## 3. Other Special Adventures

The game also defines 100 non-calendar Special Adventure routes for the daily
released-dragon return system. They do not appear in
`specialAdventureEventCatalog`, do not recur on a fixed date, and do not use a
Special Chest or Special Egg.

| Route family | Definition IDs | Selection | Availability | Reward |
|---|---|---|---|---|
| A Strange Invitation | `special_1`–`special_90` | A released Hatchling maps to 1–30, Wyrmling to 31–60, and ascended dragon to 61–90; the dragon's stable hatch seed chooses the route inside that block | 48 hours after the return outcome creates it | One fixed, visible Wooden, Silver, Gold, Dragon, or Mythical Chest |
| The Crooked Shadow | `special_91`–`special_100` | A sinister released-dragon outcome and the dragon's stable hatch seed choose one of ten routes | 48 hours after creation | One fixed, visible Sinister Chest |

For both route families:

- only one released-dragon Special Adventure can wait at a time;
- route duration is generated as `8 + (index × 7 mod 113)` hours;
- XP is `180 + 5 × duration in hours`;
- expertise is `25 + floor(duration in hours / 4)` in the route's Might,
  Spirit, or Arcana focus;
- their fixed chest tier is not randomly rolled when the Adventure starts or
  finishes; and
- the random daily return outcome that may create one is documented in
  [RANDOM_REWARDS_AND_ODDS.md](RANDOM_REWARDS_AND_ODDS.md#5-released-dragon-daily-return-system).

These routes are “special” by Adventure kind, but they are not scheduled
Special Events and do not consume the once-per-event occurrence key.

## 4. Complete chest catalog

The exact loot odds and collection formulas are in
[section 1 of RANDOM_REWARDS_AND_ODDS.md](RANDOM_REWARDS_AND_ODDS.md#1-chest-contents).

| Enum key | Player-facing type | Main purpose | Tradeable | Content behavior |
|---|---|---|---:|---|
| `wooden` | Wooden Chest | Entry chest from Adventures and other rewards | Yes | Random coins, possible Mysterious Egg, possible unique chest emote; never gems or relics |
| `silver` | Silver Chest | Early/mid-tier reward | Yes | Random coins and gems, possible Mysterious Egg and unique chest emote |
| `gold` | Gold Chest | Mid-tier reward | Yes | Random coins and gems, possible Mysterious Egg, relic, and unique chest emote |
| `dragon` | Dragon Chest | High-tier dragon reward | Yes | Random coins/gems, guaranteed Mysterious Egg, possible relic and unique chest emote |
| `mythical` | Mythical Chest | Very high-tier reward | Yes | Random coins/gems, guaranteed Mysterious Egg, possible relic and unique chest emote |
| `sinister` | Sinister Chest | Secret/sinister route reward | Yes | Random coins/gems, guaranteed relic, and guaranteed egg split between Sinister Egg and ordinary Mysterious Egg |
| `special` | Special Chest | Optional event-specific container | Yes currently | Current global recipe is the Golden Wings chest described in section 2.1 |
| `portrait` | Portrait Chest | Unlock one unowned standard portrait | No | Uniform selection from the remaining standard portrait collection |
| `title` | Title Chest | Unlock one unowned standard title | No | Uniform selection from the remaining standard title collection |
| `music` | Music Chest | Unlock one unowned jukebox track | No | Uniform selection from the remaining music collection |

Collection chests cannot be opened when their relevant collection is complete.
Portrait, Title, and Music Chests are separate from supporter-exclusive vanity
and music ownership. Current shop prices are 100 gems for a Portrait Chest, 100
coins for a Title Chest, and 250 gems for a Music Chest.

## 5. Complete egg catalog

| Egg type | How it is created | Possible dragon | Incubation | Spectral behavior |
|---|---|---|---:|---:|
| Starter Egg | New-account starter state | One of 20 standard Common families, uniform | 1 hour before starter-only tap acceleration | 5% at creation; exactly 10% total when hatching during Golden Hour |
| Mysterious Egg | Ordinary egg result from Wooden, Silver, Gold, Dragon, Mythical, or the ordinary branch of a Sinister Chest | One standard non-secret family using the source chest's rarity curve | Uniform 4h48m–33h36m in six-minute steps | 5% at creation; exactly 10% total when hatching during Golden Hour |
| Sinister Egg | 50% branch of every Sinister Chest | Sinisterra only; secret Mythical and always Evil | 6h06m06s | 5% at creation; exactly 10% total when hatching during Golden Hour |
| Special Egg | A configured Special Chest/event reward | Defined by that event; currently Cluckatrice only for Golden Wings | Defined by that event; currently 21 hours | Defined by that event; currently 0% for Golden Wings |

Egg identity values are fixed when the egg object is created. Opening another
screen, restarting, backing up, restoring, or applying a revealing relic does
not reroll the family, rarity, alignment, size, Spectral state, duration, or
personality seed. Starter tapping only changes remaining time.

Sinisterra is a secret Mythical family. Cluckatrice has the separate Special
Event type and therefore cannot unlock the Mythical-dragon achievement. Both
families are excluded from ordinary Starter and Mysterious Egg family pools.

## 6. Lifecycle and persistence rules

### Event lifecycle

1. The schedule resolver converts the event's Europe/Amsterdam wall-clock
   window to UTC.
2. The event appears only while the current instant is inside that window.
3. Starting stores both `specialEventId` and a unique occurrence key on the
   Adventure run and permanently records that occurrence as started.
4. The Adventure may complete after the event window closes.
5. Claiming grants the stored chest tier plus the event definition's expertise,
   relic, and conditional Music Chest rewards.

### Chest and egg lifecycle

1. Awarding a chest increments the appropriate inventory tier.
2. Random chest contents are rolled when the chest is opened, not when it is
   awarded.
3. Creating an egg fixes every hidden dragon property and its incubation
   duration.
4. Incubation and hatching reveal that fixed dragon; they do not roll a new
   family.

## 7. Required maintenance for every content change

Update this file in the same change whenever any of the following happens:

- a Special Event or Special Adventure is added, removed, rescheduled, renamed,
  rebalanced, or given different requirements, duration reduction, story,
  notifications, or rewards;
- a Special Chest/Special Egg definition, content relationship, provenance,
  trade rule, sprite, sound, hatch result, or achievement changes;
- any chest type or egg type is added, removed, renamed, or changes its creation
  and lifecycle behavior;
- persistence, import, backup, trade, or migration behavior changes for these
  items.

Also update [RANDOM_REWARDS_AND_ODDS.md](RANDOM_REWARDS_AND_ODDS.md) whenever a
change adds or modifies a random choice, probability, weighted pool, pity rule,
range, conditional chance, or no-duplicate rule.

After reviewing both documents, run:

```text
dart run tool/reference_documentation_guard.dart --update
dart run tool/reference_documentation_guard.dart --verify
flutter test test/reference_documentation_test.dart
```

The fingerprints are deliberately derived from the implementation files, not
from Git timestamps. Relevant source changes therefore fail the documentation
test until the living references have been reviewed and re-signed.

## 8. Primary source-of-truth files

- `lib/models/adventure.dart` — Adventure catalogs, event schedule metadata,
  requirements, durations, and reward bundles.
- `lib/providers/dragonhaven_systems.dart` — event windows, start/claim logic,
  released-dragon routes, notifications, and reward granting.
- `lib/models/chest.dart` and `lib/providers/household_provider.dart` — chest
  types, tradeability, opening recipes, egg construction, and collection rules.
- `lib/models/dragon_egg.dart` and `lib/models/dragon_lineage.dart` — persisted
  egg identity and dragon-family pools.
- `lib/models/achievement.dart` — event hatch and sinister completion
  achievements.
- `lib/screens/adventure_hub_screen.dart` — player-visible event countdown,
  requirements, and reward presentation.
- `supabase/migrations/202608290026_special_chest_trade_support.sql` — current
  Special Chest server inventory/import/trade support.
