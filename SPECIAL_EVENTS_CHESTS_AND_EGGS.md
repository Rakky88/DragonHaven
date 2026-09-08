# DragonHaven Special Events, Chests, and Eggs

Last verified: 7 September 2026

Ruleset: released app `v0.05.16`; dormant server catalog v1 (migration 45)

<!-- reference-source-fingerprint: 374c39a280dc81cd -->

This is the living implementation reference for scheduled Special Events,
their Special Adventures, event Trials, event-bound Special Chests and Special
Eggs. Update it whenever any linked schedule, reward, requirement, asset,
server rule, or lifecycle changes.

Exact random probabilities are maintained in
[RANDOM_REWARDS_AND_ODDS.md](RANDOM_REWARDS_AND_ODDS.md). Private preview
codes are maintained in [REDEEM_CODES.md](REDEEM_CODES.md) and must never be
copied into public release notes.

## 1. Content ownership model

The authenticated server display projection preserves Special Egg catalog art
and Sinister/Special protection, but omits unrevealed lineage, spectral roll,
alignment, size, personality and hatch seed. An Astral Lens reveals rarity;
the Weave Oracle additionally reveals lineage. Nest and historical trade
presentations use the same projection. Hatching reveals the dragon's appearance;
personality still requires its existing reveal. No content odds or rewards change.

The shared command identity schema and durable client journal reuse the original
server intent after a lost response. Replaying a Special Chest, egg return or
hatch outcome does not grant or roll again, including during a mutation pause.

The local server-domain candidate now calls the same Dart rules for opening
event chests, incubating/hatching eggs and claiming solo Special Adventures.
The scheduled event definitions, chest recipes and egg pools remain unchanged.
The current preview reward rules are described in section 7 below. Explicit
activation time also initializes an egg's needs timestamp, so replay does not
depend on the runtime's wall clock. This candidate has no deployed mutation
endpoint or account cutover yet; its canonical state and entropy must come
from the trusted server transaction.

The dormant migration 52 candidate copies the full save verbatim into an
isolated shadow record, retaining Special Chest counts, Special Egg identifiers,
tag information and other fields. Its immutable source and separate Altar
snapshot support the conversion review; live inventory is never changed by
this rehearsal boundary.

Loading the candidate canonical state now checks a semantic asset fingerprint.
Missing/duplicate eggs, changed fixed genetics, silently filtered Special content,
changed tags or stock, and altered progression stop evaluation for reconciliation.
The loader must not grant, reroll or discard assets while preparing an action.
The command envelope preserves unknown save and entity metadata by stable ID,
including through incubation/hatching. Exported ownership and counts replace
their old values, so consumed eggs and spent stock cannot return through merging.
Internal Altar execution uses the authenticated keeper from the transaction;
foreign Altar ownership and unresolved legacy operations block evaluation.
The isolated import preparer reconciles the captured authoritative Altar before
evaluation. Server tags take precedence, discoveries remain, and an already
returned stashed egg grants no second reward. Contradictory returned dragons,
occupied nests or protected Special Eggs stop preparation for review. This
preparer is internal and does not expose an import endpoint or activate accounts.
Candidate migration 53 retains each full source/Altar generation and commits a
prepared shadow copy only while that source, Altar and revision are current.
Historical returns, protected eggs and tags remain reviewable; live ownership
and event rewards are unchanged by preparation.

- A **Special Event** owns one schedule, story, Adventure, Trial, temporary
  music alias, ranking occurrence, and reward contract.
- A **Special Adventure** may award a Special Chest, but this is optional and
  event-specific. A chest recipe is never inferred from another event.
- A **Special Chest** has a stable ID/version and fixed event-specific recipe.
- A **Special Egg** has a stable ID/version, fixed family pool, incubation,
  alignment rules, and Spectral rules.
- Event Special Chests, Special Eggs, preview entitlements, and ranked attempts
  are non-tradeable. Ordinary released-dragon Special Adventures remain a
  separate system.
- Every listed event dragon has the `specialEvent` rarity enum and the visible
  rarity label **Special**. It cannot unlock a Common through Mythical rarity
  achievement.

## 2. Implemented scheduled events

All schedule boundaries are Europe/Amsterdam wall time, including daylight
saving transitions. Every Adventure may finish after its event closes when it
was validly started before the boundary. Except for Valentine, it can be
started once per account per occurrence with one available owned dragon.

| Event ID | Event and Adventure | Window and recurrence | Base journey | Direct completion reward |
|---|---|---|---:|---|
| `golden_wings_birthday` | A Wish on Golden Wings (`special_golden_wings_birthday`) | Launch: 1–3 Sep 2026; then every 13 May 00:00–14 May 00:00 from 2027 | 10 days | 500 XP; +25 Might/Spirit/Arcana; Golden Wings Chest; one random Moral Prism, Order Compass, Soul Mirror, or Astral Lens; one Music Chest if collection capacity remains |
| `halloween_witchlight` | Night of the Witchlight / Roots Beneath the Lanterns (`special_halloween_witchlight`) | 25 Oct 00:00–2 Nov 00:00, annually from 2026 | 72 hours | 500 XP; +13 Might/Spirit/Arcana; Witchlight Chest |
| `christmas_winter_hearth` | A Star for the Winter Hearth / The Starlight Sleigh (`special_christmas_winter_hearth`) | 25 Dec 00:00–27 Dec 00:00, annually from 2026 | 96 hours | 600 XP; +12 Might/Spirit/Arcana; Starlight Gift Chest |
| `new_year_first_dawn` | When the New Dawn Rings / The Bell Beyond Midnight (`special_new_year_first_dawn`) | 31 Dec 18:00–2 Jan 00:00, annually from 2026 | 72 hours | 700 XP; +10 Might/Spirit/Arcana; Firstlight Celebration Chest |
| `valentine_two_heartlights` | Where Two Heartlights Meet / The Rosebound Crossing (`special_valentine_two_heartlights`) | 14 Feb 00:00–15 Feb 00:00, annually from 2027 | 96 hours | Per Keeper: 650 XP; +8 Might/Spirit/Arcana; Twinheart Keepsake Chest; unique Heartbound Pair badge |
| `pride_every_color` | The Haven of Every Color / The Aurora We Weave (`special_pride_every_color`) | 1 Jun 00:00–8 Jun 00:00, annually from 2027 | 84 hours | 700 XP; +10 Might/Spirit/Arcana; Radiant Festival Chest; unique True Colors title |

For the five new events, every combined Might, Spirit, and Arcana point removes
15 minutes from the journey, down to an absolute minimum of 24 hours. Golden
Wings retains its earlier one-hour-per-point rule and one-day minimum.

### Valentine two-Keeper contract

- Exactly two registered Keepers participate, each with one available dragon.
- The creator may invite via friends, Conclave, or Keeper ID; friendship is not
  required.
- The occurrence is consumed atomically only after the partner accepts and the
  creator starts.
- The two dragons' combined Might, Spirit, and Arcana determine the duration.
- The Adventure cannot be aborted.
- Each Keeper independently claims an idempotent server-issued reward. One
  claim cannot consume the other Keeper's reward.
- The server reservation makes both dragons unavailable until completion or a
  declined/invalid pre-start invitation releases them.

### Pride Haven Spectrum

Every verified Prismatic Parade completion contributes to a global decorative
seven-ribbon Haven Spectrum meter. Thresholds are 1, 10, 25, 50, 100, 250, and
500 completions per occurrence. The meter never gates rewards.

## 3. Event Trials

The Trials overview combines its title, refresh timer, rankings button and
seven-day constellation in one purple panel. This layout does not change the
streak rules or rewards.

| Event | Trial kind | Player-facing Trial | Loop |
|---|---|---|---|
| Halloween | `witchlightWard` | Witchlight Ward | Memorize a pumpkin face, trace the witchlight path, break the approaching curse |
| Christmas | `hollyfrostGiftforge` | Hollyfrost Giftforge | Memorize a gift recipe, stamp it at the forge, guide it to the sleigh |
| New Year | `midnightChime` | Midnight Chime | Read the turning sky, strike chimes in rhythm, launch first-dawn light |
| Valentine | `rosevowRelay` | Rosevow Relay | Pair heartlights, guide them through the crossing, seal the shared vow |
| Pridefest | `prismaticParade` | Prismatic Parade | Match color and shape, guide radiant ribbons, complete the parade |

The five Trials each use their own full-screen background, icon, six gameplay
sprites, animated three-phase loop, sounds, and theme. A run lasts 75 seconds.
Might, Spirit, and Arcana provide small capped gameplay assistance; expertise
never multiplies the submitted score.

Witchlight ends on the third mistake or when time expires. Each mistake flashes
red for 300 ms. The server permits an early Witchlight finish only when the
submitted action counts contain exactly three mistakes (at least one second);
other seasonal Trials keep the existing 30-second minimum.

Witchlight Arcana shows a pumpkin lantern to memorize for an extra second
(initially 2.9 seconds), followed by six similar
lantern choices. Six individual painted, transparent pumpkin sprites share the
same silhouette and palette; eye direction and tooth position distinguish the
faces. They preload during the introduction. The Might lantern is extracted
from the complete source outline, including its handle, with transparent padding.
Spirit requires one continuous finger trace from the wisp to the lantern along
the visible winding corridor. Crossing an edge, lifting early, or cancelling
the gesture fails the action and applies the existing two-second penalty.
Fast swipes are checked along their entire movement; tapping the destination
does not complete the path. Every challenge receives a new seeded winding path,
normalized to the same total length. The corridor is black inside a gold edge;
the accepted finger trail remains visible in pale green. Spirit
expertise visibly widens the corridor from 24 to 32 logical pixels (capped at
400 Spirit), with no random forgiveness. Might keeps its timing challenge.

The runtime presentation deliberately carries that art through the complete
flow: a themed HUD emblem and three-phase sprite trail, subtle ambient sprite
motion, event-specific start and result compositions, illustrated compact
Special Adventure cards/details, illustrated empty/error ranking states, and
event-colored ranking headers backed by the corresponding Trial scene. The
Pride Haven Spectrum uses seven actual festival sprites instead of generic
symbols. All five nested event asset directories are declared explicitly in
Flutter's asset bundle. Compact-phone widget coverage at 320×640 and an outer-
edge alpha gate protect the layout and prevent visibly clipped cutouts.

During one active event its Trial joins Cavern Flight, Ruin Breaker, and
Runeweaver as four equally weighted refill candidates: 25% each per empty
slot. The board still holds at most three offers and duplicates remain
possible. An unstarted event offer disappears after closing; a run started
with a valid server session may finish afterward.

Every completed run receives the standard Trial reward. Seasonal expertise is
split without tripling the grade reward:

| Grade | Balanced expertise grant |
|---|---|
| D | +1 to the lowest expertise |
| C | +1 to both lowest expertises |
| B | +1 to all three |
| A | +2 to lowest, +1 to both others |
| S | +2 to both lowest, +1 to highest |
| S+ | +3 to lowest, +2 to both others |

Points blocked by an expertise cap move to another uncapped expertise. A
completed event Trial counts toward the Seven-day Trial Constellation under
the same maximum of one credited completion per local date.

### Worldwide event rankings

- Only registered, email-verified Keepers can start a ranked seasonal Trial.
- The server issues the occurrence, deterministic seed, nonce/token, start,
  and expiry; rejects replay, impossible timing, and scores beyond the
  validated action bound.
- There is no per-event attempt cap or separate practice mode: each naturally
  offered Trial is one rewarded attempt.
- Best verified score wins; ties use accuracy, then shortest duration, then
  earliest submission.
- New starts stop at event close. The full frozen ranking remains visible for
  five days; its top three remain permanently in the Seasonal Chronicle.
- First place receives a Mythical Chest and the event's gold podium emote;
  second receives a Dragon Chest and silver emote; third receives a Gold Chest
  and bronze emote.
- Prize IDs are idempotent. A repeated podium finish keeps the chest and
  increments the already-owned emote's win count.
- If connectivity is lost after a valid server start, the normal local Trial
  reward is kept, but that unverified score is excluded from the ranking.

## 4. Event Special Chests

All six definitions are non-tradeable, support safe multi-open if multiple
copies legitimately exist, use their own closed/open art, and roll their
contents only on opening. Event details reveal the chest but keep its contents
secret.

| Chest ID | Chest | Fixed contents | Opening sound |
|---|---|---|---|
| `golden_wings_chest_v1` | Golden Wings Chest | 269 coins, 10 gems, Golden Wings Special Egg | `golden_wings` |
| `witchlight_chest_v1` | Witchlight Chest | 313 coins, 13 gems, Witchlight Egg | `witchlight` |
| `starlight_gift_chest_v1` | Starlight Gift Chest | 250 coins, 12 gems, Starlit Evergreen Egg | `starlight` |
| `firstlight_celebration_chest_v1` | Firstlight Celebration Chest | 365 coins, 12 gems, Turning-Year Egg | `firstlight` |
| `twinheart_keepsake_chest_v1` | Twinheart Keepsake Chest | 214 coins, 14 gems, Rosebound Egg | `twinheart` |
| `radiant_festival_chest_v1` | Radiant Festival Chest | 300 coins, 15 gems, Truecolor Egg | `radiant` |

The event recipe itself is fixed. The normal Special-tier unique chest-emote
find remains a separate 10% no-duplicate roll.

## 5. Event Special Eggs and families

| Egg ID | Egg | Incubation | Guaranteed family | Moral rule | Spectral |
|---|---|---:|---|---|---:|
| `golden_wings_egg_v1` | Golden Wings Special Egg | 21 hours | Cluckatrice | Random, initially hidden | 5%; 10% total during Golden Hour |
| `witchlight_egg_v1` | Witchlight Egg | 13h13m13s | Gloamgourd | Random, initially hidden | 5%; 10% total during Golden Hour |
| `starlit_evergreen_egg_v1` | Starlit Evergreen Egg | 25 hours | Hollyfrost | Always Good and known at hatch | 5%; 10% total during Golden Hour |
| `turning_year_egg_v1` | Turning-Year Egg | 24 hours | Dawnchime | Always Neutral and known at hatch | 5%; 10% total during Golden Hour |
| `rosebound_egg_v1` | Rosebound Egg | 14 hours | Rosevow | Always Good and known at hatch | 5%; 10% total during Golden Hour |
| `truecolor_egg_v1` | Truecolor Egg | 18 hours | Spectrumplume | Always Good and known at hatch | 5%; 10% total during Golden Hour |

Law alignment, size, and personality seed are fixed at egg creation. Moral is
also fixed then, subject to the table. Opening screens, restarting, backup,
restore, or a revealing relic never rerolls an egg. These eggs have no
starter-only tap acceleration.

Hatch achievements:

- Cluckatrice: `winner_chicken_dinner` — Winner, Winner, Chicken Dinner
- Gloamgourd: `warden_of_witchlight` — Warden of the Witchlight
- Hollyfrost: `star_in_every_hearth` — A Star in Every Hearth
- Dawnchime: `first_light_first_flight` — First Light, First Flight
- Rosevow: `two_hearts_one_flight` — Two Hearts, One Flight
- Spectrumplume: `every_color_takes_flight` — Every Color Takes Flight

## 6. Temporary event music and notifications

Each new event temporarily exposes one verified CC0/Public Domain jukebox
alias while its real or private preview occurrence is active. It disappears
after the occurrence and is not part of the 80-track Music Chest collection.
The source performance for every alias is recorded in
`assets/licenses/MUSIC_SOURCES.md`.

One Special Events notification is scheduled for each opening and deep-links
to Adventures. It respects the existing Special Events notification toggle
and device notification permission.

## 7. Private preview contract

Each seasonal event has a 48-hour reusable personal preview. Halloween is
available to authenticated, email-confirmed keepers; the other four previews
remain restricted server-side to Keeper `DH-17792DC5`. Rankings remain isolated
from live occurrences and the UI labels these occurrences as test events.

Updated 8 September 2026: **test event Trials grant the normal permanent Trial
rewards**, including XP, balanced Expertise, grade chest, eligible S+ relic/emote
rolls and daily constellation credit. They also save the dragon's personal best.
Completing the same local offer twice cannot grant twice. Test Special Adventures,
Valentine test journeys and their preview Special Chests still do not grant
permanent rewards in production. Staging may enable those separately for tests.

Halloween's accepted test attempts already persist in `seasonal_trial_attempts`,
with preview bests in `seasonal_trial_bests`. Neither is removed when a personal
preview expires. `tool/halloween_trial_calibration_report.sql` reads the 14 days
from 8 September 00:00 to 22 September 00:00 Europe/Amsterdam: all attempts and
one best per keeper, percentiles, daily counts and 250-point buckets. It exports
no keeper identifiers or tokens and does not change live rankings or grade
thresholds. Insufficient samples should not be treated as reliable cutoffs.

All six calendar events theme the app's shared palette and logo. Each event has
a complete transparent logo derived from the original wing-and-egg mark in
`assets/images/event_logos/`; the shared app header uses that full artwork.
All six have illustrated backgrounds, including a dedicated golden sanctuary
for Golden Wings. Valentine uses pink accents, Christmas green, New Year blue,
Pride rainbow panel gradients, and Golden Wings gold. A compact persistent banner shows the event end time,
including birthday and personal tests. Starting a personal event replaces the
previous personal event for that account. The selected preview takes precedence
over the calendar; the most recent start and stable occurrence key break ties.
Migration 59 preserves same-event retry expiry and replaces only activation
records: already started adventures/attempts, earned items and recorded scores
retain their own provenance and original reward rules. Expiry restores
the normal app theme without reopening the app or polling a server.

Android receives the existing Amsterdam calendar and personal previews locally.
Its launcher aliases use the same six logos, with only one alias enabled at a
time; the underlying MainActivity stays enabled for notifications. A persisted
future calendar and inexact local alarms update the icon while the app is idle;
opening/resuming, reboot and clock/package changes also refresh it. Launcher
changes are deferred until the app leaves view because disabling the visible
task's alias can close it; the in-app logo changes immediately. Android can
delay background alarms or cache launcher icons; after force-stop the next app
open refreshes the icon. The initial installation uses the ordinary icon until
the first calendar synchronization. No new permission, server call or paid
service is required. See `EVENT_BRANDING_VERIFICATION.md` for startup checks.

Annual occurrences spanning December/January retain their original occurrence
key and full configured duration after midnight on 1 January. Event dates,
participation requirements, reward tables and preview entitlements are unchanged.

Halloween's current rank boundaries are 500 / 1200 / 2000 / 2250 / 2500
(C / B / A / S / S+). Other event Trial cutoffs remain unchanged. S+ rewards
use the weighted relic pool documented in `RANDOM_REWARDS_AND_ODDS.md`, including
four unique equipable brooches. Their Expertise bonus applies once within the
wearer's cap; event Adventures and online pair/group rewards use the same rule.
Special Chest contents and each event's direct relic pool remain unchanged.

## 8. Other chest and egg types

The complete chest enum remains:

- `wooden`, `silver`, `gold`, `dragon`, `mythical`, `sinister`, `special`,
  `portrait`, `title`, and `music`.

The complete egg categories remain:

- **Starter Egg** — first account egg, one standard Common family.
- **Mysterious Egg** — ordinary standard family using its source-chest curve.
- **Sinister Egg** — Sinisterra only, always Evil.
- **Special Egg** — versioned event-bound family and rules from this document.

Every egg fixes a permanent male/female value when its hatch seed and other
properties are created, with 50/50 chances. New seed draws use the full 31-bit
range; the stable sex bit consumes no additional reward roll. Existing eggs and
dragons derive the same value from their saved seed; very old seedless identities
use a stable identity hash. The value survives incubation, hatching, evolution,
trade and restore. Small labeled male/female icons appear only for hatched
dragons, and unknown eggs do not expose sex or their private seed in projections.

## 9. Non-calendar Special Adventures

The daily released-dragon system still owns 100 separate non-calendar routes:

- `special_1`–`special_90`, A Strange Invitation, fixed visible ordinary chest;
- `special_91`–`special_100`, The Crooked Shadow, fixed visible Sinister Chest.

They wait for 48 hours, use their existing duration/XP/expertise formulas, do
not enter an event Trial rotation, and never consume a scheduled event
occurrence key.

## 10. Persistence and server ownership

- Save schema 53 persists event preview expiries, event Trial offers and local
  bests, claimed prize IDs, podium-emote win counts, event chests/eggs, badge
  ownership, and applied Valentine reward IDs.
- Supabase migration `202609070040_seasonal_events.sql` owns preview
  authorization, attempt tokens, rankings, frozen prizes, Chronicle records,
  Valentine invitations/reservations/claims, and Pride community progress.
- Event tables have RLS enabled, direct table access revoked, and only narrow
  authenticated RPCs granted.
- Ranking and paired-Adventure rewards are applied locally once and then
  acknowledged; refresh/restart cannot duplicate them.

## 11. Maintenance and source files

After any relevant change, update this document and
`RANDOM_REWARDS_AND_ODDS.md`, update `REDEEM_CODES.md` when preview codes
change, then run:

```text
dart run tool/reference_documentation_guard.dart --update
dart run tool/reference_documentation_guard.dart --verify
flutter test test/reference_documentation_test.dart
```

Primary sources are `lib/models/adventure.dart`, `lib/models/trial.dart`,
`lib/models/dragon_egg.dart`, `lib/models/dragon_lineage.dart`,
`lib/providers/dragonhaven_systems.dart`, `lib/screens/seasonal_trial_game.dart`,
`lib/screens/adventure_hub_screen.dart`, and
`supabase/migrations/202609070040_seasonal_events.sql`.

## Egg Altar and protection

The Altar egg picker shares Inventory's saved Received/Hatch time sorting,
supports reversing the order and combining it with All/Tagged/Untagged filters.
Opening an egg still shows its details before selection; filtering or sorting
never reveals hidden traits or changes return eligibility.

Inventory tabs are ordered Eggs, Chests, Altar, Relics, Furniture.
The permanent Egg Altar has its own Inventory > Altar tab and is also reachable
from the nest screen. Selecting an egg first opens its details, with known
properties, hidden-property placeholders, incubation, acquisition date and hint;
placing it on the altar requires a separate choice. Protected eggs can be
inspected but cannot be selected for return. The info button contains a single
tutorial text block without odds. The Weaveheart guarantee counter is hidden.
Nameweaver's Quill appears first in crafting; recipe cards show effects and
material costs without drop-source or exclusivity labels.

The altar rests in a painted twilight grove. A fixed stone sprite, contact
shadow and foreground bowl rim integrate the selected egg. The 5.2-second
ritual continuously charges, lifts, dissolves, releases motes, fades and rests;
twelve overlapping light ribbons replace the mismatched old sprite crossfades.
Rewards fade into a reserved space, keeping the dialog stable. Reduced motion
shows the completed scene after a short transition.
Inventory eggs can be tagged and untagged without a material cost. Tags, scan
knowledge and returned IDs persist across saves, nest activation and authorized
trades. A newer explicit tag revision wins over an older backup. The selection
and the committing action both reject protected eggs.

Every Special-family egg is excluded, including legacy eggs with no specialEggId.
Nest eggs and trade-reserved eggs are excluded. Sinisterra is Mythical and may be
returned: hold the return button and accept an additional Sinister confirmation.
The confirmation describes the permanent return without listing rewards.
Sinister always gives 25 Shell Fragments and 3–5 Draconic Essence (uniform), with
an independent 10% chance of one Weaveheart. No hidden
rarity, Spectral state or source affects the reward table. Exact probabilities
and the account-wide Weaveheart guarantee are in RANDOM_REWARDS_AND_ODDS.md.

The Altar adds Moral Echo, Order Sigil, craftable Astral Lens, Weave Oracle and
Nameweaver's Quill. Oracle reveals the fixed family and rarity, without awarding
a hatch or discovery. Quill renames one already-named hatched dragon and costs
10 Fragments + 1 Essence. First naming remains free. Existing Astral Lens drops,
shop and trade stock remain intact. Crafted stock and materials cannot be traded.

Online material spending and returns use a separate server ledger with atomic,
idempotent commands, per-egg ownership checks and permanent returned-ID markers.
The legacy inventory registration trust boundary remains; this feature does not
activate the broader economy cutover. Lost responses retry the persisted command
ID. The forward balance migration 202609070044 preserves existing receipts and
wallet balances. See EGG_ALTAR_DESIGN_DRAFT.md for recipes and the complete implemented design.

Conclaves have a shared cosmetic Weave Beacon with voluntary Shell Fragment gifts
and milestones at 500, 2000 and 5000. It gives no stat or reward bonuses. Only a
milestone-crossing gift posts one aggregate project message; individual egg
returns never post to chat. The progress caps at 5000.

## Dormant server chest opening (audit phase 4B)

Migration 45 adds server-side opening for ordinary, Sinister, Special, portrait,
title and music chest instances. All existing probabilities, inclusive currency
ranges and eligible pools above are preserved. The client catalog snapshot is
checked by `tool/economy_chest_catalog.dart --verify`; future catalog changes
require a forward migration. Oracle and Nameweaver's Quill remain Altar-only;
Astral Lens remains in the normal relic pool.

Each owner-locked transaction handles at most ten distinct owned chest IDs.
The stored receipt and ledger prevent both request retries and a new request ID
from rerolling an already opened chest. A full vanity collection leaves its
chest unopened. Pity is recomputed after each granted egg and is inactive while
an egg remains in inventory or in the nest. Independent server draws preserve
Sinister's 50% Sinisterra chance, guaranteed relic, and ordinary fallback pool.
Chronoshard's 10-90% value is stored once per relic instance; all four brooches' lifetime
acquisition marker excludes it from subsequent drops, including after consumption.

Special chest identity must be supplied by the trusted import/grant procedure;
unknown or missing event IDs fail without consuming the chest. Special eggs use
the event's exact incubation seconds and fixed moral/hatch-disclosure rule.
Opening receipts omit hidden lineage, hatch seed and personality. The future
hatch flow still needs to implement the Golden Hour spectral bonus.

This path is not activated for players. The existing app opening flow and
production economy authority flags remain unchanged. Migration 46 blocks legacy
inventory synchronization/import for a future server-owned account, while legacy
accounts keep their existing behavior. End-to-end cutover, instance conversion,
server egg lifecycle and client reconciliation remain separate audit work.

Release v0.05.17: the compact seasonal HUD scales its phase icons within the available width; Altar tag/details actions wrap when text needs more space. Trial rules and rewards are unchanged.

Halloween preview access: any signed-in keeper with a confirmed email may redeem
its existing personal 48-hour preview. The other four event previews remain
restricted to their configured keeper. Active redemptions retain their original
expiry; expired previews can be redeemed again. Production preview Adventures
and Special Chests remain simulated; test Trials grant normal rewards as described
in section 7. Preview scores remain separate from live event rankings. This
does not change the event calendar or grant a Special Chest. Migration 48 is the
forward-only server override; the current app already uses that RPC.
