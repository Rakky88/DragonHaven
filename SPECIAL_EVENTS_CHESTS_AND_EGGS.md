# DragonHaven Special Events, Chests, and Eggs

Last verified: 6 September 2026

Ruleset: app version `v0.05.11`

Source baseline: release `v0.05.11`

<!-- reference-source-fingerprint: b8fc53e558d7224f -->

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

### 2.2 Future event concepts (art only; not scheduled)

The concepts below are **not implemented Special Events** and are not entries
in `specialAdventureEventCatalog`. Their artwork is kept outside Flutter's
shipping asset tree, so it cannot appear in gameplay or increase the current
download size. A holiday name must never be treated as an implied date,
recurrence, reward, chest, egg, requirement, or gameplay rule.

| Event concept | Dragon family | What is already decided | Current status |
|---|---|---|---|
| Halloween | Gloamgourd | Charcoal harvest design with pumpkin light, vine horns, witchfire, and guardian wisps; six forms exist | Sprites approved and one event-only Trial confirmed; remaining event/gameplay fields are TBD |
| Christmas | Hollyfrost | White-and-evergreen winter design with golden antlers, holly, frost crystal, and lantern light; six forms exist | Sprites approved and one event-only Trial confirmed; remaining event/gameplay fields are TBD |
| New Year's Day | Dawnchime | Indigo-and-dawn design with chimes, firework fins, turning-year rings, and sunrise ribbons; six forms exist | Sprites approved and one event-only Trial confirmed; remaining event/gameplay fields are TBD |
| Valentine's Day | Rosevow | Rose-quartz vow design with petal wings, thorn-gold armor, and a warm heart gem; six forms exist | Sprites approved and one event-only Trial confirmed; remaining event/gameplay fields are TBD |
| Pridefest | Spectrumplume | Pearl-and-prism festival design with a full-spectrum feather mantle and aurora ribbons; six forms exist | Sprites approved and one event-only Trial confirmed; remaining event/gameplay fields are TBD |

The current art package and review instructions live in
[`future_event_art/dragon_families/README.md`](future_event_art/dragon_families/README.md).
The implementation roadmap and fill-in sheets for all five concepts live in
[`NEW_EVENTS_PLAN.md`](NEW_EVENTS_PLAN.md).

#### Information still required for each future event

Every field not already marked confirmed remains independently configurable for
Halloween, Christmas, New Year's Day, Valentine's Day, and Pridefest. These
decisions must be recorded before the corresponding event is implemented.

| Decision area | Information still needed |
|---|---|
| Identity | Stable event ID, Adventure ID, player-facing title, theme/occasion, and short story |
| Availability | Exact first start and end date **including year**, wall-clock times, timezone, and whether the event recurs |
| Recurrence | If recurring: cadence, first recurrence, timezone, and handling for leap years or other calendar edge cases |
| Start/completion rules | Whether a run started before closing remains finishable; attempts per occurrence; whether parallel copies are allowed |
| Adventure duration | Base journey length, minimum final duration, discount cap, and rounding behavior |
| Participation | Solo or Group Adventure; minimum/maximum dragon and keeper count |
| Dragon requirements | Allowed forms, rarities, families, alignments, levels, ownership/availability rules, and required individual or combined expertise |
| Expertise reduction | Which of Might, Spirit, and Arcana shorten the journey and the exact reduction per point |
| Direct rewards | Every guaranteed or random currency, XP, expertise, relic, chest, egg, Music Chest, furniture, vanity, emote, achievement, or other reward, including quantities and exact odds |
| Reward visibility | Which rewards are shown before starting, which remain secret, and the exact player-facing wording |
| Special Chest | Whether the event awards one at all; if yes, its stable definition/version, name, contents/odds, quantity, tradeability, duplicate and multi-open rules, reveal policy, sprite, and opening audio |
| Egg delivery | Whether the event family comes from a direct egg reward, a Special Chest, another source, or is not awarded by this event |
| Special Egg | If used: stable definition/version, name, exact family pool and odds, incubation duration, speed-up rules, tradeability, acquisition limit, hint, and reveal behavior |
| Dragon rules | Family type/rarity, alignment restrictions, personality visibility, starting stats, evolution requirements, expertise caps, names, Draconomicon behavior, and whether any form grants existing rarity achievements |
| Spectral behavior | Whether the egg/family can be Spectral, its base chance, and whether Golden Hour or another event modifier applies |
| Milestones | Hatch/event achievements, journal entries, titles, badges, follow-up rewards, and duplicate/fallback behavior |
| Event-only Trial | One unique Trial is confirmed per event; its final name, rules, grade thresholds, refill weight, attempt allowance, standard reward behavior, expertise split, and leaderboard/prize rules remain to be resolved |
| Presentation | Event card and detail copy, countdown placement, completed-state UI, localization, accessibility, and reduced-motion treatment |
| Notifications | Availability notification timing, deep link destination, account toggle/default, and recurrence rescheduling |
| Operations | Whether new persisted definition IDs, migrations, server validation, backup/import compatibility, trade support, monitoring, or staging fixtures are required |

#### Event-specific open choices

- **Halloween / Gloamgourd:** exact Halloween window and recurrence; playful,
  mysterious, or genuinely sinister tone; whether Sinister mechanics or chests
  are involved (they are not implied by the artwork).
- **Christmas / Hollyfrost:** exact winter/Christmas window and recurrence;
  whether the story is explicitly Christmas-themed or broader winter-themed;
  regional/timezone presentation.
- **New Year's Day / Dawnchime:** which timezone owns the year boundary;
  whether availability spans New Year's Eve, New Year's Day, or both; handling
  of the displayed year in recurring copy.
- **Valentine's Day / Rosevow:** exact window and recurrence; whether the story
  focuses on romance, friendship, or both; whether participation is solo or
  cooperative.
- **Pridefest / Spectrumplume:** the exact named occasion and calendar window
  (there is no assumed universal Pridefest date), recurrence, story tone, and
  any community/cooperative focus.

### 2.3 Event-only Trial program (one per event confirmed; not implemented)

Each future event will have one temporary Trial that exists only while that
event occurrence is active. When one event is active, its Trial joins the three
standard Trial kinds as a fourth eligible refill result; the Trial board itself
still shows at most three offers. Equal weighting would make every eligible
kind 25%, but that exact weight still awaits owner confirmation. The individual
game names and mechanics below remain design proposals. They intentionally use
three distinct simple actions so Might, Spirit, and Arcana all matter without
applying an expertise multiplier to the submitted score.

| Event | Proposed Trial | Simple game loop | Might contribution | Spirit contribution | Arcana contribution |
|---|---|---|---|---|---|
| Halloween | **Witchlight Ward** | Protect a lantern through short repeating rounds: identify the safe rune, guide its wisp into the lantern, then strike the curse at the right moment | Makes the strike timing zone slightly wider | Gives slightly more steering control and a smaller wisp collision area | Keeps the safe rune visible slightly longer |
| Christmas | **Hollyfrost Giftforge** | Memorize a tiny gift recipe, stamp it when the forge meter reaches gold, then drag it into the matching sleigh slot while avoiding snowballs | Makes the golden stamping zone slightly wider | Improves drag control and softens obstacle collisions | Extends recipe preview time slightly |
| New Year's Day | **Midnight Chime** | Build one firework at a time: select its shown sigil, launch through a curved ring path, then tap on the midnight chime to burst it | Makes the final chime window slightly wider | Improves launch steering and ring tolerance | Extends sigil visibility slightly |
| Valentine's Day | **Rosevow Relay** | Find two matching heart sigils, trace a safe path between them, then break the thorn lock at its bright point | Makes the thorn-break timing zone slightly wider | Makes path tracing slightly more forgiving | Extends the matching-symbol preview slightly |
| Pridefest | **Prismatic Parade** | Read a two-color light recipe, steer the beam through matching festival hoops, then crack the final dull crystal on the beat | Makes the crystal timing zone slightly wider | Improves beam steering and hoop tolerance | Extends the color-recipe preview slightly |

Recommended common game rules:

- one available owned dragon participates and remains visible/reactive;
- each run lasts about 60–90 seconds and gradually accelerates;
- correct three-action sequences build a capped combo; errors break the combo
  instead of immediately ending the run, with the exact life/error limit still
  TBD;
- the three expertise benefits are deliberately small and capped so developed
  dragons feel useful without making a low-expertise score meaningless;
- the leaderboard receives the actual achieved score, never a post-game
  expertise multiplier;
- each event receives its own tuned D/C/B/A/S/S+ thresholds after playtesting;
  and
- controls remain one-thumb friendly, color-blind distinguishable, reduced-
  motion compatible, and deterministic from a server-issued ranked seed.

#### Proposed normal Trial rewards

An official event-Trial completion should reuse the normal Trial grade table:
the existing XP amount, chest roll, S+ relic roll, and S+ ordinary Trial-emote
roll remain unchanged. The normal expertise amount is **split** across Might,
Spirit, and Arcana instead of being granted three times:

| Grade | Total expertise | Proposed balanced split |
|---|---:|---|
| D | 1 | +1 to the participant's lowest expertise |
| C | 2 | +1 to each of the two lowest expertises |
| B | 3 | +1 Might, +1 Spirit, +1 Arcana |
| A | 4 | +2 to the lowest expertise and +1 to the other two |
| S | 5 | +2 to the two lowest expertises and +1 to the highest |
| S+ | 7 | +3 to the lowest expertise and +2 to the other two |

Ties between equally low expertise values need a stable rotation so the same
stat is not always favored. Existing expertise caps still apply; any point that
cannot be placed needs a decided overflow rule before implementation.

#### Proposed temporary worldwide leaderboard

The recommended competition model is:

1. Only registered, e-mail-verified online keepers can submit ranked runs.
   Everyone can still use an offline practice mode without rewards or ranking.
2. Each keeper receives **three official ranked/rewarded attempts per event
   occurrence**. Practice is unlimited, but can never submit a score or grant a
   reward. This avoids a leaderboard decided mainly by grinding. A one-per-day
   model with accumulated unused attempts remains an alternative if longer
   events should encourage daily play.
3. Only a keeper's highest verified score appears. Tie-breakers are higher
   accuracy, then shorter run time, then the earlier submission.
4. The board is live only during that event occurrence. At the exact close it
   becomes read-only, freezes the winners, grants prizes exactly once, and
   remains visible for five complete days with a results-expiry countdown.
5. After those five days the occurrence disappears from the active ranking UI.
   A future recurrence gets a new occurrence ID and a completely empty board.
6. The screen shows the top entries, the keeper's own rank even when outside
   the visible top group, and a distinct podium presentation for places 1–3.

Recommended podium rewards for every event occurrence:

| Place | Chest | Cosmetic |
|---:|---|---|
| 1 | Mythical Chest | Event-specific gold/champion dragon emote |
| 2 | Dragon Chest | Event-specific silver/runner-up dragon emote |
| 3 | Gold Chest | Event-specific bronze/third-place dragon emote |

This would require three podium emotes per event (15 total). Suggested themes
are Gloamgourd lantern reactions, Hollyfrost festive reactions, Dawnchime
firework reactions, Rosevow heart reactions, and Spectrumplume radiant parade
reactions. Whether repeat winners receive no duplicate cosmetic, a replacement,
or a year-specific variant is still TBD.

Ranked attempts and prize delivery must be server-authoritative. The server
should issue the occurrence ID, deterministic seed, nonce, and attempt token;
validate a compact action log against plausible timing and the seeded game;
rate-limit submissions; reject replayed/expired tokens; freeze standings in a
transaction; and create idempotent prize grants. A client-reported score alone
is not sufficient for a worldwide rewarded ranking.

#### Decisions needed before implementation

- approve or rename each of the five Trial concepts;
- confirm equal weighting when the active event Trial joins the refill pool;
- choose three total ranked attempts per occurrence versus accumulated daily
  attempts;
- decide whether every official attempt grants normal rewards or only the best
  completed official attempt;
- approve the balanced expertise split and define capped-point overflow;
- choose error/life rules and final score/grade thresholds after prototypes;
- confirm the proposed top-three chests and whether each podium place gets a
  distinct event emote;
- choose the duplicate reward for a keeper who wins the same podium emote in a
  later recurrence;
- decide whether the frozen top three should also be recorded permanently in a
  Chronicle after the five-day public results window; and
- define moderation/disqualification behavior for invalid ranked submissions.

When one concept is selected for implementation, resolve its own fields only.
Do not copy Golden Wings values or another future concept's choices merely to
fill a blank.

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
