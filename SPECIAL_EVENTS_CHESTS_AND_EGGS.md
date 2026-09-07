# DragonHaven Special Events, Chests, and Eggs

Last verified: 7 September 2026

Ruleset: app version `v0.05.14`

<!-- reference-source-fingerprint: d5095b97509c6845 -->

This is the living implementation reference for scheduled Special Events,
their Special Adventures, event Trials, event-bound Special Chests and Special
Eggs. Update it whenever any linked schedule, reward, requirement, asset,
server rule, or lifecycle changes.

Exact random probabilities are maintained in
[RANDOM_REWARDS_AND_ODDS.md](RANDOM_REWARDS_AND_ODDS.md). Private preview
codes are maintained in [REDEEM_CODES.md](REDEEM_CODES.md) and must never be
copied into public release notes.

## 1. Content ownership model

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

| Event | Trial kind | Player-facing Trial | Loop |
|---|---|---|---|
| Halloween | `witchlightWard` | Witchlight Ward | Read a ward rune, guide its witchlight, break the approaching curse |
| Christmas | `hollyfrostGiftforge` | Hollyfrost Giftforge | Memorize a gift recipe, stamp it at the forge, guide it to the sleigh |
| New Year | `midnightChime` | Midnight Chime | Read the turning sky, strike chimes in rhythm, launch first-dawn light |
| Valentine | `rosevowRelay` | Rosevow Relay | Pair heartlights, guide them through the crossing, seal the shared vow |
| Pridefest | `prismaticParade` | Prismatic Parade | Match color and shape, guide radiant ribbons, complete the parade |

The five Trials each use their own full-screen background, icon, six gameplay
sprites, animated three-phase loop, sounds, and theme. A run lasts 75 seconds.
Might, Spirit, and Arcana provide small capped gameplay assistance; expertise
never multiplies the submitted score.

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

Each new event has a 48-hour reusable personal preview restricted server-side
to Keeper `DH-17792DC5`. Preview rankings are isolated from live occurrences.
Production preview rewards are simulated and cannot change permanent
inventory; staging can grant persistent rewards for idempotency tests. The UI
marks preview occurrences as test events.

## 8. Other chest and egg types

The complete chest enum remains:

- `wooden`, `silver`, `gold`, `dragon`, `mythical`, `sinister`, `special`,
  `portrait`, `title`, and `music`.

The complete egg categories remain:

- **Starter Egg** — first account egg, one standard Common family.
- **Mysterious Egg** — ordinary standard family using its source-chest curve.
- **Sinister Egg** — Sinisterra only, always Evil.
- **Special Egg** — versioned event-bound family and rules from this document.

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
