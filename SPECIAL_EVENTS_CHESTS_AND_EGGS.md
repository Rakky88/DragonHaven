# DragonHaven Special Events, Chests, and Eggs

Last reviewed: 9 September 2026; v0.05.27 candidate includes approved Sunwake/Harvestmoon content. Staging and production are at schema 65; database lint and public health checks pass.

The four redesigned Trial introductions use their clean standalone event icons,
avoiding adjacent-frame remnants in the older sprite-sheet cutouts. Halloween now alternates memory and tracing; the former Might timing phase is removed.

Undiscovered Draconomicon family cards, silhouette medallions and form tiles
retain light parchment/lavender surfaces during every event. These surfaces
are deliberately independent of the dark event panels; discovery behavior and
normal/spectral artwork remain unchanged.

The compact Special-adventure offer omits its duplicate availability countdown;
the shared event banner supplies that timer. Trip duration, expertise information
and Start remain on the offer; the full details sheet retains availability.
The shrinking test label keeps an eight-pixel gap from the event title, even
when only a few characters fit.

Ruleset candidate: v0.05.27. Migration 64 adds two approved festivals and one-miss birthday completion, with compatibility for older three-miss clients. Economy activation remains disabled.

The Special Adventure dragon picker now also displays Might, Arcana and Spirit
with their individual scores, MAX markers and selected highlight glow. This
applies to all eight combined-expertise Adventures, including birthday and the
Valentine partner invitation. Only dragons with all three Expertises highlighted
enter the highlighted section. Within each section, combined Expertise sorts
descending; existing recommendation/acquisition order breaks ties. Ordinary
Adventures keep their single-focus display and ordering. Inspecting Expertise
does not select or start a dragon. Duration formulas and rewards are unchanged.

<!-- reference-source-fingerprint: 5ed6aff96e93f135 -->

This is the living implementation reference for scheduled Special Events,
their Special Adventures, event Trials, event-bound Special Chests and Special
Eggs. Update it whenever any linked schedule, reward, requirement, asset,
server rule, or lifecycle changes.

Exact random probabilities are maintained in
[RANDOM_REWARDS_AND_ODDS.md](RANDOM_REWARDS_AND_ODDS.md). Private preview
codes are maintained in [REDEEM_CODES.md](REDEEM_CODES.md) and must never be
copied into public release notes.

## 1. Content ownership model

The isolated canonical staging app now offers egg details, type/tag filters and
ordering, tagging, incubation, hatching, fixed-percentage Chronoshards and Altar
crafting/reveals. Details precede Altar placement; tagged, Special, reserved and
incubating eggs remain protected. A Sinister return requires two confirmations.
Its existing reward remains 25 fragments, 3-5 essence and at most one Weaveheart
with the existing fivefold chance, never five hearts. The interface does not
show odds or pity counters. Quill remains the first craft choice. Server receipts
drive the existing Altar scene; no egg genetics are invented to render its art.
Account/revision checks and durable recovery cover every lifecycle action.
This UI is staging-only and does not activate or change live player ownership,
event schedules, reward pools or probabilities. Evidence and remaining work:
`SERVER_ECONOMY_UI_VERIFICATION.md`.

The ordinary Adventure staging UI shares the existing duration calculation via
public expertise scores, without constructing a private Pet. The extraction
preserves Mini/Short/Long/Group/Special formulas and minimums. This does not
enable seasonal/group starts in the new staging UI or change Special schedules,
requirements, chest odds or rewards. Active run deadlines remain server times;
an in-flight reward stays hidden until the server marks the run ready.

The subsequent staging house controls extract only the existing deterministic
floor/repair/ward price calculations. Egg lifecycle, returning Special
Adventure eligibility, event schedules, chest contents and reward odds remain
unchanged. Room/floor actions use the same durable, server-validated session.

Dragon preference commands now persist the desired expertise highlights and
one favorite in the staging lane. Highlighting changes no training, XP, event
eligibility or reward. Favorite selection preserves the existing release
protection and achievement counter; replaying the same choice cannot increment
it again. Special/Sinister identity, eggs and event schedules are unchanged.

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
| Birthday | `wishcakeTower` | Wishcake Tower | Drop moving cake layers onto the stack; trim overhang, regain a little width after three perfect layers |
| Halloween | `witchlightWard` | Witchlight Ward | Memorize a pumpkin face, then trace the witchlight path; repeat these two games |
| Christmas | `hollyfrostGiftforge` | Hollyfrost Giftforge | Drag moving parcels from a conveyor into matching symbol bays |
| New Year | `midnightChime` | Midnight Chime | Four-lane falling-star rhythm game; strike each chime at the golden line |
| Valentine | `rosevowRelay` | Rosevow Relay | Guide two horizontally mirrored hearts through different, jointly solvable mazes |
| Pridefest | `prismaticParade` | Prismatic Parade | Rotate channels in a 4×4 prism circuit to connect the rainbow source and star |

The six Trials retain their own full-screen backgrounds, icons, sounds and
themes. Halloween uses a two-phase memory/trace loop. The other five use separate
interactive boards, now illustrated with individual painted gifts, hearts,
roses, rainbow prisms and chimes. All start at 75 seconds; total expertise adds
`round(clamp((Might + Arcana + Spirit) / 300, 0, 3))` seconds. Expertise never
multiplies score. Event offer cards and dragon pickers show all three expertises;
only dragons with all three highlighted appear in the highlighted section.

Christmas independently schedules uniformly chosen parcel symbols (three choices).
New arrivals never wait for an earlier delivery. The spawn interval is
`max(.36, 2.4 - (35 + max(0, activeSeconds)) * .031)` seconds; each parcel crosses the belt in
`max(.95, 4.4 - (35 + max(0, activeSeconds)) * .05) + clamp(Might / 400, 0, 1) * .35` seconds.
The opening interval is 1.315s and travel time is 2.65s plus Might assistance: exactly the former 40-seconds-remaining pace. Both arrivals and travel get faster, producing several concurrent parcels.
A parcel keeps its own deadline and speed from spawn; delivering another gift
never resets it. Held parcels can still expire, and a late release cannot deliver
another parcel. Spirit extends delivery tolerance by up to 8px. There is no
shared delivery cooldown. Catch-up work is bounded to eight queued parcels;
three misses stop play synchronously, including expiry batches after a stalled
frame. Feedback text changes directly without stacking repeated fade-out labels.
New Year beats shorten from 1.10s to a .42s floor at .0105s per active second;
every 16th beat has a 1.5x phrase pause. Note travel shortens from 2.1s to .9s
at .018s per active second, plus up to .4s from Spirit. Travel time is fixed
at spawn. The hit window remains ±180–250ms (Might). After 22 active seconds,
every fourth beat has two notes; after 45 seconds, every second beat does.
Chords always use two distinct lanes and accept two fingers. Each lane has its
own 120ms repeat guard. Four synthesized chimes (C5, D5, E5, G5) play the original
32-note melody; missed notes retain the existing failure sound. Sound is optional.
Valentine moves both hearts simultaneously, mirroring horizontal direction;
a blocked heart waits. Every maze pair is checked for a shared solution before
play. Pride rotates two-ended prism channels and traces the connected beam;
each newly lit cell scores only once per board. Both puzzle games offer 1–3
hints for the whole run based on Arcana. Revisiting a maze state awards nothing.

The five independent arcade games retain the full timer on a mistake, deduct 30 points
without going below zero, reset combo and flash red. They record at most 200
scoring actions and cap score at 20,000, matching the existing server bounds.
Christmas and New Year end after exactly three mistakes, or on timeout.
Christmas deliveries award 120 base points; New Year 130 within 90ms and 100
otherwise; new maze states 55 and a paired finish 120; new lit prisms 70 and a
finished circuit 120. Each scoring action adds the existing capped combo bonus
(minimum zero, maximum 90, +6 per completed round). Grade reward pools are unchanged. Current C/B/A/S/S+ cutoffs are:

| Trial | C | B | A | S | S+ |
|---|---:|---:|---:|---:|---:|
| Halloween | 500 | 1200 | 1600 | 1800 | 2000 |
| Christmas | 500 | 1200 | 2000 | 3000 | 7500 |
| New Year | 500 | 1200 | 2000 | 3000 | 20000 |
| Valentine | 650 | 1600 | 2600 | 3900 | 10000 |
| Pridefest | 1200 | 2900 | 4800 | 7200 | 12000 |

Each boundary is inclusive; D is below C.

Witchlight ends on the third mistake or when time expires. Each mistake flashes
red for 300 ms. Migration 61 permits a finish before 30 seconds for Witchlight, Christmas and
New Year only when submitted action counts contain exactly three mistakes,
with a minimum of one second. Valentine and Pride retain the 30-second minimum.
Ownership, token, expiry, score/action caps, elapsed time and one-use validation
remain enforced. Null scores/counts/duration/tokens are rejected explicitly.

Witchlight Arcana shows a pumpkin lantern to memorize for an extra second
(initially 2.9 seconds), followed by six similar
lantern choices. Six individual painted, transparent pumpkin sprites share the
same silhouette and palette; eye direction and tooth position distinguish the
faces. They preload during the introduction.
Spirit requires one continuous finger trace from the wisp to the lantern along
the visible winding corridor. Crossing an edge, lifting early, or cancelling
the gesture fails the action and applies the existing two-second penalty.
Fast swipes are checked along their entire movement; tapping the destination
does not complete the path. Every challenge receives a new seeded winding path,
normalized to the same total length. The corridor is black inside a gold edge;
the accepted finger trail leaves mint-and-gold sparkles that softly twinkle
and drift in place, without a solid stroke. Reduced motion keeps this stardust
static and visible. A painted mint wisp follows the finger; a softly pulsing
pumpkin lantern marks the destination. Decorative motion stops with reduced motion enabled. Spirit
expertise visibly widens the corridor from 24 to 32 logical pixels (capped at
400 Spirit), with no random forgiveness. Completing the trace immediately starts
the next memory round after feedback; Might still contributes to total time assistance.

The runtime presentation deliberately carries that art through the complete
flow: a themed HUD emblem (with a two-phase trail only for Halloween), subtle ambient sprite
motion, event-specific start and result compositions, illustrated compact
Special Adventure cards/details, illustrated empty/error ranking states, and
event-colored ranking headers backed by the corresponding Trial scene. The
Pride Haven Spectrum uses seven actual festival sprites instead of generic
symbols. All five nested event asset directories are declared explicitly in
Flutter's asset bundle. Compact-phone widget coverage at 320×640 and an outer-
edge alpha gate protect the layout and prevent visibly clipped cutouts.

Starting a new event occurrence fills every currently empty slot with that
specific event Trial, keeping existing standard offers and started runs. A
persisted occurrence key prevents a second initial refill after dismissal or
restart. Thereafter, during one active event its Trial joins Cavern Flight, Ruin Breaker, and
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

Each of the six events temporarily exposes one verified CC0/Public Domain or original-synthesis jukebox
alias while its real or private preview occurrence is active. It disappears
after the occurrence and is not part of the 80-track Music Chest collection.
The source performance for every alias is recorded in
`assets/licenses/MUSIC_SOURCES.md`.

One Special Events notification is scheduled for each opening and deep-links
to Adventures. It respects the existing Special Events notification toggle
and device notification permission.

## 7. Private preview contract

Each seasonal event has a 48-hour reusable personal preview available to all
authenticated, email-confirmed keepers (forward migration 63). Rankings remain isolated
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
Pride rainbow panel gradients, and Golden Wings gold. Valentine now uses a
clear rose pink (`#AE4778`) on blush paper (`#FFF3F7`). Collapsed Tower floors
and the Academy entrance retain their original translucent artwork overlays;
event panels no longer paint over those illustrations. Direct-chat buttons use
a pale event tint with a dark ink label for contrast. A compact persistent banner shows the event end time,
including birthday and personal tests. The banner first clips the test label,
then removes it, and wraps only if the official title/timer still cannot fit.
Measurement includes inherited font spacing and accessibility text scale.
Starting a personal event replaces the
previous personal event for that account. The selected preview takes precedence
over the calendar; the most recent start and stable occurrence key break ties.
Migration 59 preserves same-event retry expiry and replaces only activation
records: already started adventures/attempts, earned items and recorded scores
retain their own provenance and original reward rules. Migration 60 adds
account-scoped event dismissal, authenticated and synchronized across sessions.
It ends personal previews and suppresses current official calendar editions
until their original end, including Golden Wings. Future editions and already
started runs survive. The native launcher schedule filters the same dismissal
state; previews explicitly started afterward still work. Expiry or dismissal
restores the normal app theme without reopening the app.

The temporary Christmas track now plays an original instrumental arrangement
of Jingle Bells. Its catalog ID remains `event_winter_hearth_carol`; runtime
resource is `music_event_jingle_bells.wav`. The public-domain composition and
original synthesis are documented in `assets/licenses/MUSIC_SOURCES.md`.
The 80-song Music Chest collection and music-drop probabilities are unchanged.

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

Halloween's current rank boundaries are 500 / 1200 / 1600 / 1800 / 2000
(C / B / A / S / S+). Valentine uses 650 / 1600 / 2600 / 3900 / 10000; Pride
uses 1200 / 2900 / 4800 / 7200 / 12000. New Year uses
500 / 1200 / 2000 / 3000 / 20000; Christmas uses 7500 for S+. S+ rewards
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

Seasonal preview access: any signed-in keeper with a confirmed email may activate
any of the six personal 48-hour previews. Active redemptions retain their original
expiry; expired previews can be redeemed again. Production preview Adventures
and Special Chests remain simulated; test Trials grant normal rewards as described
in section 7. Preview scores remain separate from live event rankings. This
does not change the event calendar or grant a Special Chest. Migration 62 is the
current forward-only access override; the app uses the same authenticated RPC.

## Jukebox restoration (release 0.05.25)

Event music is temporary. Natural expiry, manual dismissal and replacing a
personal preview reconcile the native playlist immediately against the last
dispatched configuration. The saved ordinary song selection, shuffle and repeat
remain intact, including music acquired during the event. An empty selection
or disabled master music stays silent. Returning from the background also
reconciles event expiry; unchanged clock ticks do not reset playback cycles.

## Birthday Trial extension (9 September 2026)

Golden Wings now links to Wishcake Tower, its own cake-stacking Trial, and
`event_birthday_wish` (`music_event_happy_birthday.wav`). The 38.125-second
instrumental is a new synthesized arrangement of the public-domain 1893 melody
known as Happy Birthday. No lyrics or third-party performance are imported.
`tool/build_birthday_song.dart` reproduces it. The saved jukebox selection,
shuffle/repeat and master setting survive expiry, replacement and manual stop.
This temporary track is outside the 80 collectible songs.

Wishcake Tower runs for 75 seconds plus the established 0–3 seconds of assistance.
Tap the board or Drop layer to place the moving cake. Only overlap of at least
7% of board width survives; smaller overlaps count as misses. Within 1.8% of
board width, alignment is perfect (Arcana adds up to .7 percentage points).
The base is 44% of board width (Might adds up to 4 percentage points). Every
three consecutive perfect layers restore 2.5 percentage points, capped at the
original base width. A miss resets the base while keeping score and misses.
Three misses end the run. A 420ms drop lock prevents duplicate taps.

Crossing time at each layer spawn is `max(.48, 1.65 - activeSeconds * .012 -
placedLayers * .009) * (1 + clamp(Spirit / 400, 0, 1) * .08)` seconds. It remains
fixed for that moving layer. A seeded fair initial direction alternates after
each drop. Geometry is normalized across screen sizes; essential cake movement
continues with reduced motion, while falling offcuts, confetti and flame sway
are suppressed. Feedback avoids zero-duration layout animation.

Each correct placement scores 85 base points, or 130 for a perfect placement,
plus the existing capped combo bonus. Misses deduct 30 points, floored at zero.
C/B/A/S/S+ thresholds are 600 / 1500 / 2800 / 4200 / 10000, inclusive. Ordinary
Trial grade rewards and balanced expertise apply, also during test previews.
There is no additional birthday podium reward table; stored birthday scores
and the five-day results window use the ordinary leaderboard infrastructure.
The existing Golden Wings Adventure, Chest and predetermined egg contents,
recurrence and item provenance are unchanged. The formerly missing egg artwork
reference now resolves to `events/golden_wings/golden_wings_egg.png`.

Migration 63 adds the birthday preview mapping, calendar window and Trial kind
and accepts an early finish only with exactly three misses. It preserves owner,
token, elapsed-time, score/action caps and one-use checks. Staging rollback
coverage includes all six preview codes, retry expiry, owner isolation, invalid
attempts, post-event completion, score persistence and duplicate rejection.
No public release notes announce operational codes.


## Sunwake and Harvestmoon - approved v0.05.27 content

The user approved all twelve dragon sprites and the full package on 9 September 2026.
Sunwake runs 20-26 July and Harvestmoon 7-13 September, Europe/Amsterdam, first in 2027.
These are seven-day windows, ending at 00:00 the following day. Previews last 48 hours.

| Content | Sunwake Festival | Harvestmoon Festival |
|---|---|---|
| Event ID | `sunwake_summer_sea` | `harvestmoon_moonlit_orchard` |
| Adventure | Where the Summer Sea Shines | The Orchard Beneath the Harvest Moon |
| Adventure ID | `special_sunwake_summer_sea` | `special_harvestmoon_moonlit_orchard` |
| Trial | Sunwake Surf (sunwakeSurf) | Moonlit Orchard (moonlitOrchard) |
| Chest | sunwake_chest_v1 | harvestmoon_chest_v1 |
| Egg | sunwake_egg_v1 | harvestmoon_egg_v1 |
| Family | Solmanta | Ciderhorn |
| Incubation | 20 hours | 18 hours |
| Hatch achievement | Light Across the Lagoon | Beneath the Harvest Moon |
| Music | Sunpearl Serenade | Orchard Waltz |
| Conclave decoration | Coral reef lighthouse | Harvest feast |

Both Adventures are solo, one available owned dragon, once per keeper/occurrence.
84-hour base duration, 15-minute discount per combined Might/Arcana/Spirit point,
24-hour floor; a valid start remains finishable after expiry. Each grants 650 XP,
+10 per expertise, and its own Special Chest. Each chest grants 300 coins, 12 gems,
and exactly one guaranteed own-family egg. Shared special-chest emote probability
remains 10%, with no duplicate from the eligible unlock pool. No ordinary pool changes.
Eggs are Special, Good, protected from Altar returns, untradeable; gender/law/size/
personality use existing shared generation. Spectral is 5%, or 10% during Golden Hour.
Six approved PNG forms per family use existing evolution and expertise-cap rules.
Both have their own theme, background, icon/launcher/splash, music, effects, hatch
achievement and gold/silver/bronze podium emotes with established podium rewards.

Sunwake: a 75-second steering game with three lanes. Each gate has one uniformly
random safe lane/sunpearl and two reefs. Fixed 120Hz simulation preserves collisions
across render rates. The first gate spawns after .20 seconds. Speed is
min(.78, .42 + t*.005), with interval max(.60, 1.05-t*.008) seconds.
Steering must begin by holding the dragon, then dragging horizontally. A tap
elsewhere never moves it. Speed is capped at 1.65 arena widths per second;
releasing/cancelling stops pursuit of the previous target. The current only
drifts the dragon while it is not being held; one active thumb owns steering.
Might narrows collision width, Arcana widens pearl pickup, Spirit reduces current.
A clean pearl gives 130 base points, a clean passage without a pearl 70; three hits end.
Harvestmoon: a 75-second 6x7 packing game, three rotatable fruit shapes per tray.
Seven normal shapes, three uniformly sampled fruits, four uniform orientations.
Single-piece probability .10 + .035*(normalized Might+Arcana+Spirit), maximum .205.
A held touch or dragged tray shape previews every occupied target cell; valid
placements are green and invalid footprints red. Releasing places the shape;
cancellation/outside drops do not place it. Full horizontal rows fade for .18
seconds, then rows above move down over .44 seconds. Input waits for that .62
second transition. Reduced motion displays the final board immediately.
A blocked basket resets after the transition plus .85 seconds.
A placement earns 55+12 per
fruit, or 130 when harvesting a row; shared combo bonuses apply. Invalid placement
is neutral. No remaining shape fitting in any orientation loses a basket; three end.
Both use D/C/B/A/S/S+ cutoffs 0/500/1500/3000/5000/8000 with ordinary Trial rewards.
Personal preview Trials give ordinary rewards and keep preview score provenance;
preview Adventures/Chests remain simulated and do not grant permanent special items.

The two Conclave projects advance at 1/5/15/30/60 verified completed runs with at
least one successful action. Membership is captured at start; each run counts once.
Official progress is durable by Conclave/event/occurrence, has no currency reward,
and is visible only to members. Preview progress stays separate, uses the last 48h,
and cannot unlock the permanent decoration. No donations or economy flags change.
Migration 64 was rehearsed with rollback, applied to staging, linted and tested again.
It also extends end-event dismissal, saved score identities and dormant chest catalog v3.

## Current birthday and Christmas balance in v0.05.27

Birthday ends immediately after the first missed layer, retaining the earned tower.
This is one life per run, not one attempt per account. D/C/B/A/S/S+ cutoffs are
0/600/1500/2800/4200/10000. Migration 64 accepts one-miss early finishes and retains
compatibility for older clients reporting three misses. Christmas uses
0/500/1200/2000/3000/7500, retaining the faster start, acceleration and three misses.
The Egg Altar shortcut is hidden while the starter egg hatches.

Seasonal hatch achievements accept normal and Spectral hatchlings alike. Migration 65
allows the exact shipped seasonal podium emotes in friend and Conclave chats, retaining
friendship, membership, recipient preferences, payload bounds and rate limits.
