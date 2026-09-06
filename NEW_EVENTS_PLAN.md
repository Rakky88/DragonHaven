# DragonHaven New Seasonal Events Plan

Last updated: 6 September 2026

Planning baseline: development after app version `v0.05.11`

This is the working plan for the five new seasonal events. It records confirmed
owner decisions, proposals, unanswered questions, implementation work, owner
actions, validation, and release gates. It is deliberately separate from the
implemented-content catalog in
[`SPECIAL_EVENTS_CHESTS_AND_EGGS.md`](SPECIAL_EVENTS_CHESTS_AND_EGGS.md).

When a choice is approved and implemented, the living content catalog must be
updated in the same change. Exact random odds must also be recorded in
[`RANDOM_REWARDS_AND_ODDS.md`](RANDOM_REWARDS_AND_ODDS.md), and an activated
redeem code must be added to [`REDEEM_CODES.md`](REDEEM_CODES.md). Redeem codes
must never be disclosed in public release notes.

## 1. Status legend

| Status | Meaning |
|---|---|
| Confirmed | Explicitly decided by the owner |
| Proposed | Recommended design; still needs owner approval |
| TBD | A material decision is still missing |
| Codex | Implementation or verification can be performed by Codex |
| Owner | Input, account action, visual approval, migration permission, or release permission is required from the owner |

## 2. Program-wide confirmed decisions

- The program contains five separate seasonal events: Halloween, Christmas,
  New Year's Day, Valentine's Day, and Pridefest.
- Every event has exactly one unique event-only Trial.
- An event Trial is accessible only while its owning event occurrence is
  active, except through an explicitly configured personal test occurrence.
- During one active seasonal event, its Trial joins Cavern Flight, Ruin
  Breaker, and Runeweaver as a fourth possible Trial refill result.
- The Trial board still contains at most three visible offers. "Four in the
  rotation" means four eligible kinds, not four simultaneous Trial cards.
- All 30 dragon-family sprites have been visually approved: Hatchling,
  Wyrmling, Might, Arcana, Spirit, and Mastery for all five families.
- Each event and every optional Special Chest or Special Egg owns stable,
  versioned definitions. Values must never be inherited from another event.

### Trial rotation contract

The initial design uses equal selection among the eligible kinds. With one
active event this means a newly refilled slot has:

| Trial kind | Proposed refill chance |
|---|---:|
| Cavern Flight | 25% |
| Ruin Breaker | 25% |
| Runeweaver | 25% |
| Active event Trial | 25% |

The refill is selected independently for each empty slot, so duplicate kinds
remain possible just as they are today. Event Trial offers must persist across
an ordinary app restart, but must not remain playable indefinitely after the
event closes. The exact close-boundary grace rule is still TBD; the recommended
rule is that an already started 60–90 second run may finish, while an unstarted
offer is removed and its slot returns to the normal three-kind pool.

If event windows ever overlap, every active event Trial would technically add
another eligible kind. Before overlapping schedules are released, the owner
must choose whether all are added, one receives priority, or a separate event
slot is introduced.

## 3. Shared event-Trial design

Every event Trial should:

- use one available owned dragon;
- contain one simple Might action, one Spirit action, and one Arcana action;
- last approximately 60–90 seconds;
- use expertise only for small, capped gameplay assistance and never as a
  post-game score multiplier;
- have separately playtested D/C/B/A/S/S+ thresholds;
- reuse the normal Trial XP, chest, S+ relic, and S+ ordinary-emote rules unless
  that event explicitly overrides them;
- split the existing total expertise reward across Might, Spirit, and Arcana
  instead of tripling it;
- support touch, compact screens, tablets, text scaling, reduced motion,
  foreground/background transitions, and deterministic testing; and
- use server-authoritative official attempts for rewarded worldwide rankings.

### Temporary worldwide ranking proposal

| Rule | Proposed behavior | Status |
|---|---|---|
| Eligibility | Registered and e-mail-verified accounts | Proposed |
| Official attempts | Three per keeper per event occurrence | Proposed |
| Practice | Unlimited; no rewards and no ranking submission | Proposed |
| Counted score | Best verified score for that occurrence | Proposed |
| Tie-breakers | Accuracy, then shortest run time, then earliest submission | Proposed |
| Closing | Freeze at the exact event end and grant prizes exactly once | Confirmed intent; technical rule proposed |
| Results visibility | Read-only for five complete days after event close | Confirmed |
| Next recurrence | New occurrence ID and empty ranking | Confirmed |
| First place | Mythical Chest plus gold event podium emote | Proposed |
| Second place | Dragon Chest plus silver event podium emote | Proposed |
| Third place | Gold Chest plus bronze event podium emote | Proposed |
| Repeat cosmetic | Keep chest; show a win count on the already owned emote | Proposed |

Ranked attempts require a server-issued occurrence ID, deterministic seed,
nonce, short-lived attempt token, and a compact action log that the server can
validate. Submission replay, expired tokens, impossible timing, impossible
scores, and excessive submission rates must be rejected. Prize grants must be
idempotent and recoverable after an interrupted sync.

## 4. Halloween event

### 4.1 Current event card

| Field | Current value | Status |
|---|---|---|
| Event concept | Halloween | Confirmed |
| Dragon family | Gloamgourd | Confirmed |
| Dragon sprites | All six forms approved on 6 September 2026 | Confirmed |
| Event Trial | One unique Halloween Trial | Confirmed |
| Trial rotation | Joins the three standard kinds as the fourth eligible refill kind while active | Confirmed |
| Trial name | Witchlight Ward | Proposed |
| Event display name | Night of the Witchlight / Nacht van het Heksenlicht | Proposed |
| Stable event ID | `halloween_witchlight` | Proposed |
| Event story | Guide Gloamgourd and lost witchlights safely through awakened lantern roots | Proposed |
| First schedule | 25 October 2026 00:00 through 2 November 2026 00:00 | Proposed |
| Timezone | Europe/Amsterdam wall time | Proposed |
| Recurrence | Annually on the same local dates/times | Proposed |
| Special Adventure | Roots Beneath the Lanterns | Proposed; owner must confirm whether the event has an Adventure at all |
| Adventure duration | 72 hours before reduction | Proposed |
| Completion after close | Allowed if started during the active window | Proposed |
| Adventure limit | Once per account per occurrence | Proposed |
| Participation | One available owned dragon; no form/rarity minimum | Proposed |
| Expertise reduction | Combined Might + Spirit + Arcana, 15 minutes per point, minimum 12 hours | Proposed |
| Direct rewards | 500 XP, +13 Might, +13 Spirit, +13 Arcana, one Witchlight Chest | Proposed |
| Advance disclosure | Show XP, expertise, and chest; keep chest contents secret | Proposed |

### 4.2 Halloween Trial proposal

**Witchlight Ward** repeats one cohesive three-step round:

1. Arcana identifies the safe rune before it fades.
2. Spirit guides its witchlight into the protected lantern.
3. Might breaks the approaching curse at the bright timing point.

Correct rounds build a capped combo and increase speed. The proposed failure
rule is three mistakes. Arcana slightly extends rune visibility, Spirit slightly
improves steering/collision tolerance, and Might slightly widens the strike
window. Exact assistance caps, scoring formula, grade thresholds, and final
failure timing will be established through prototype playtesting.

### 4.3 Halloween chest and egg proposal

| Field | Proposed value | Status |
|---|---|---|
| Chest definition | Witchlight Chest, versioned and event-bound | Proposed |
| Chest contents | 313 coins, 13 gems, one Witchlight Egg | Proposed |
| Randomness | Fixed contents | Proposed |
| Tradeability | Never tradeable | Proposed |
| Player disclosure | Do not reveal contents before opening | Proposed |
| Chest art/audio | New closed/open sprites and Halloween opening sound | Needed; Codex |
| Egg definition | Witchlight Egg, versioned and event-bound | Proposed |
| Egg outcome | Gloamgourd only, 100% | Proposed |
| Family type | Special Event; never counts for a rarity achievement | Proposed |
| Incubation | 13h13m13s | Proposed |
| Spectral | 5% normally; 10% when hatching during Golden Hour | Proposed |
| Alignment/personality | Normal random identity rules; personality initially hidden | Proposed |
| Egg tradeability | Never tradeable | Proposed |
| Hatch achievement | Warden of the Witchlight | Proposed |

### 4.4 Outside-season test code

The requested code is `HALLOWEENEVENT`. It is **planned but not active** until
the event is implemented and the active catalog plus `REDEEM_CODES.md` are
updated together.

Required behavior:

- redeeming it outside the real season activates a personal Halloween preview
  occurrence for the authorized tester;
- the preview makes the Halloween event UI and the fourth Trial rotation entry
  available without changing the real calendar schedule;
- preview Trial scores use a separate preview scope and can never enter, replace,
  or influence a live seasonal worldwide ranking;
- preview state is visibly marked `TEST EVENT` in the UI and diagnostic export;
- the code is never mentioned in public release notes; and
- the normal seasonal occurrence remains untouched and independently playable.

Important: a code embedded in a public app is discoverable and is not access
control. The recommended implementation is an account-scoped, server-approved
tester entitlement. The owner must still decide:

| Missing decision | Recommended value | Owner answer |
|---|---|---|
| Authorized account(s) | Owner's confirmed Keeper ID plus staging test accounts | TBD |
| Preview duration per activation | 48 hours | TBD |
| Redemption reuse | Reusable for authorized testers after the previous preview expires | TBD |
| Production preview rewards | Simulate and display rewards, but do not alter permanent production inventory | TBD |
| Staging preview rewards | Grant real staging rewards to test persistence and idempotency | TBD |
| Preview ranking | Isolated test board or ranking-disabled; never live seasonal | TBD |
| Code retirement | Keep while event QA is needed; server can disable without an app release | TBD |

If the owner instead wants permanent production rewards from the preview, the
code must be one-time per account to prevent farming, and the exact reward
contract must be approved and documented before implementation.

### 4.5 Halloween assets still needed

- event banner and Adventure card treatment;
- Witchlight Trial icon and background;
- rune, witchlight, protected lantern, curse, hit, miss, combo, and result
  sprites/animations;
- closed and opened Witchlight Chest;
- Witchlight Egg and nest presentation;
- gold, silver, and bronze Gloamgourd podium emotes if rankings are approved;
- chest opening sound plus compact Trial feedback effects; and
- optional event music only if explicitly requested and appropriately licensed.

All new visual assets require the same transparent-background, safe-margin,
orientation, in-game-scale, blue-background, and owner-review process already
used for the dragon sprites.

## 5. Christmas event

### 5.1 Current event card

| Field | Current value | Status |
|---|---|---|
| Event concept | Christmas | Confirmed |
| Dragon family | Hollyfrost | Confirmed |
| Dragon sprites | All six forms approved on 6 September 2026 | Confirmed |
| Event Trial | One unique Christmas Trial | Confirmed |
| Trial rotation | Joins the three standard kinds as the fourth eligible refill kind while active | Confirmed program rule |
| Trial name | Hollyfrost Giftforge | Proposed |
| Event display name | A Star for the Winter Hearth / Een Ster voor de Winterhaard | Proposed |
| Stable event ID | `christmas_winter_hearth` | Proposed |
| Event story | Restore a lost sleigh of starlight so Hollyfrost can carry warmth to every room in the Haven | Proposed |
| Calendar window | 25 December 00:00 through 27 December 00:00, covering only 25 and 26 December | Confirmed |
| First scheduled year | 2026 | Proposed |
| Timezone | Europe/Amsterdam wall time | Proposed |
| Recurrence | Annually on the same local dates/times | Proposed |
| Special Adventure | The Starlight Sleigh / De Sterrenlichtslee | Proposed; owner must confirm whether the event has an Adventure at all |
| Adventure duration | 96 hours before reduction | Proposed |
| Completion after close | Allowed if started during the active window | Proposed |
| Adventure limit | Once per account per occurrence | Proposed |
| Participation | One available owned dragon; no form/rarity minimum | Proposed |
| Expertise reduction | Combined Might + Spirit + Arcana, 15 minutes per point, minimum 18 hours | Proposed |
| Direct rewards | 600 XP, +12 Might, +12 Spirit, +12 Arcana, one Starlight Gift Chest | Proposed |
| Advance disclosure | Show XP, expertise, and Special Chest; keep chest contents secret | Proposed |

### 5.2 Story and player presentation proposal

**Short event story:**

> As the longest nights settle over the Haven, the Starlight Sleigh loses its
> guiding star. Hollyfrost gathers every spark of warmth it can find, but needs
> one brave dragon to carry the light home before the winter hearths grow dim.

The event card should feel warm rather than purely icy: evergreen, gold,
candlelight, soft snow, and a distant guiding star. The card shows its own live
availability countdown. The detail page separates requirements, approximate
rewards, the Special Adventure, the event Trial, and the temporary ranking.
Chest contents remain hidden until opening.

Recommended notification behavior is one notification at event opening, using
the existing Special Events account toggle and a deep link directly to the
Christmas event. No extra Christmas-morning notification is sent unless the
owner explicitly requests it.

### 5.3 Christmas Trial proposal

**Hollyfrost Giftforge** uses a repeating three-step workshop round:

1. Arcana briefly reveals a small recipe of two or three gift sigils.
2. Might stamps the gift when a moving forge meter reaches its golden zone.
3. Spirit guides the finished gift into the matching sleigh compartment while
   avoiding rolling snowballs and drifting frost.

Correct rounds build a capped **Starlight Chain** and gradually speed up. The
proposed failure rule is three mistakes. A wrong recipe, badly timed stamp, or
collision each consumes one warm hearth light. When all three lights are gone,
the forge gently freezes, the score arrives with the normal Trial result
animation, and rewards are granted at that moment.

Expertise assistance remains deliberately small:

- Arcana keeps the recipe visible slightly longer;
- Might makes the golden forge zone slightly wider; and
- Spirit improves steering and collision tolerance slightly.

The submitted score is the achieved gameplay score and is never multiplied by
expertise. Exact assistance caps, round values, combo cap, acceleration, and
D/C/B/A/S/S+ thresholds are determined through prototype playtesting.

The Trial uses the shared four-kind refill contract: while Christmas is active,
each newly filled Trial slot can choose Cavern Flight, Ruin Breaker,
Runeweaver, or Hollyfrost Giftforge. Equal weighting would give each 25%.
Hollyfrost Giftforge enters the pool at 25 December 00:00 and leaves it at
27 December 00:00; it is therefore seasonally available only on 25 and
26 December. An explicitly authorized personal preview occurrence is the only
outside-season exception.

### 5.4 Christmas chest and egg proposal

| Field | Proposed value | Status |
|---|---|---|
| Chest definition ID | `christmas_starlight_gift_chest_v1` | Proposed |
| Player-facing chest name | Starlight Gift Chest / Sterrenlichtgeschenkkist | Proposed |
| Chest contents | 250 coins, 12 gems, one Starlit Evergreen Egg | Proposed |
| Randomness | Fixed contents | Proposed |
| Roll timing | No content roll; identity is fixed when granted | Proposed |
| Tradeability | Never tradeable | Proposed |
| Multi-open | Not relevant with one obtainable chest per occurrence; retained version still supports safe inventory display | Proposed |
| Player disclosure | Show only that a Special Chest is awarded; do not reveal contents before opening | Proposed |
| Chest art/audio | New closed/open gift-chest sprites and warm magical bell/unwrap opening sound | Needed; Codex |
| Egg definition ID | `christmas_starlit_evergreen_egg_v1` | Proposed |
| Player-facing egg name | Starlit Evergreen Egg / Sterrenlicht-dennenei | Proposed |
| Egg outcome | Hollyfrost only, 100% | Proposed |
| Family type | Special Event; never counts for a rarity achievement | Proposed |
| Incubation | Exactly 25 hours | Proposed |
| Speed-up | No special tap acceleration; normal incubation rules and eligible relics apply | Proposed |
| Spectral | 5% normally; 10% when hatching during Golden Hour | Proposed |
| Moral nature | Always Good and immediately known | Proposed |
| Order nature | Normal random identity rule | Proposed |
| Personality | Normal random identity rule; initially hidden | Proposed |
| Egg tradeability | Never tradeable | Proposed |
| Acquisition | One guaranteed egg through this event's one chest per occurrence | Proposed |
| Hint | Warmth glows beneath evergreen frost while a distant bell answers from inside | Proposed |
| Hatch achievement | A Star in Every Hearth | Proposed |
| Journal/Draconomicon | Record the event hatch, Special Event family, and every evolved form normally | Proposed |

Hollyfrost uses the ordinary non-Infernal evolution levels, expertise caps, and
form rules unless the owner requests a Christmas-specific difference. Its
Special Event classification keeps it outside Common–Infernal rarity
achievements and ordinary egg pools.

### 5.5 Christmas Trial rewards and ranking proposal

An official Hollyfrost Giftforge run reuses the normal Trial grade reward table.
XP, chest odds, the S+ relic roll, and the S+ ordinary Trial-emote roll remain
unchanged. The normal total expertise reward is distributed across Might,
Spirit, and Arcana using the shared balanced split in section 3.

The proposed ranking rules are the shared rules from section 3: three official
ranked/rewarded attempts per account per Christmas occurrence, unlimited
non-rewarded practice, best verified score, and results frozen for five days
after the event closes.

Proposed Christmas podium cosmetics:

| Place | Chest | Unique Hollyfrost emote |
|---:|---|---|
| 1 | Mythical Chest | **Crowned by Starlight** — jubilant Hollyfrost beneath a golden star crown |
| 2 | Dragon Chest | **Giftwrapped Joy** — Hollyfrost happily tangled in a silver ribbon |
| 3 | Gold Chest | **Snowy Cheer** — Hollyfrost giving a proud bronze-bell salute |

All three are permanent, non-tradeable chat emotes. A repeated podium result
never creates a duplicate; the proposed replacement is a visible podium-win
count on the owned emote while the normal chest prize is still granted.

### 5.6 Outside-season Christmas preview proposal

Recommended redeem code: `CHRISTMASEVENT`. It remains planned and inactive
until the Christmas event is implemented and the active catalog plus
`REDEEM_CODES.md` are updated together.

The preview follows the Halloween safety model:

- only server-authorized Keeper IDs can redeem it;
- redemption outside the season starts a personal 48-hour Christmas preview;
- it enables the event UI, Adventure, chest/egg flow, Giftforge practice, and
  the four-kind Trial rotation for that tester;
- preview scores never enter the real Christmas worldwide ranking;
- production preview rewards are simulated by default, while staging can grant
  persistent staging rewards to test idempotency and save compatibility;
- the UI and diagnostic export clearly identify `TEST EVENT`; and
- the server can disable or re-enable the code without publishing a new app.

The owner must still provide the authorized Keeper ID(s) and approve preview
duration, reuse, production reward isolation, and whether an isolated preview
ranking is useful.

### 5.7 Christmas assets still needed

- event banner, event card treatment, guiding star, sleigh, and winter-hearth
  presentation;
- Hollyfrost Giftforge Trial icon and warm workshop background;
- recipe sigils, forge meter, stamp, gift variants, sleigh compartments,
  snowballs, frost obstacles, three hearth lights, combo, hit/miss, and result
  sprites/animations;
- closed and opened Starlight Gift Chest;
- Starlit Evergreen Egg and nest presentation;
- three Hollyfrost podium emotes if rankings are approved;
- warm magical chest-opening sound, bell/forge/game feedback effects; and
- optional Christmas background music only if explicitly requested and sourced
  from a verified usable recording.

All new visual assets use transparent backgrounds where appropriate, safe
margins, consistent in-game scale, and blue-background owner review before
release.

## 6. New Year's Day event intake

| Field | Current value | Status |
|---|---|---|
| Event concept | New Year's Day | Confirmed |
| Dragon family | Dawnchime; all six sprites approved | Confirmed |
| Event Trial | One unique New Year Trial | Confirmed |
| Trial concept | Midnight Chime: choose sigil, guide firework, burst on the chime | Proposed |
| Trial rotation | Fourth eligible kind while the New Year event is active | Confirmed program rule |
| Display name/story | Not supplied yet | TBD |
| Schedule/timezone/recurrence | Must explicitly define which timezone owns the year boundary | TBD |
| Adventure, requirements, duration and reduction | Not supplied yet | TBD |
| Direct rewards, chest and egg | Not supplied yet | TBD |
| Dawnchime gameplay rules and achievement | Not supplied yet | TBD |
| Ranking and outside-season preview | Not supplied yet | TBD |
| New visual/audio assets | Defined after content choices | TBD |

## 7. Valentine's Day event intake

| Field | Current value | Status |
|---|---|---|
| Event concept | Valentine's Day | Confirmed |
| Dragon family | Rosevow; all six sprites approved | Confirmed |
| Event Trial | One unique Valentine's Trial | Confirmed |
| Trial concept | Rosevow Relay: match heart sigils, trace safe path, break thorn lock | Proposed |
| Trial rotation | Fourth eligible kind while the Valentine's event is active | Confirmed program rule |
| Display name/story and romance/friendship tone | Not supplied yet | TBD |
| Schedule/timezone/recurrence | Not supplied yet | TBD |
| Solo/cooperative Adventure and requirements | Not supplied yet | TBD |
| Duration, reduction and direct rewards | Not supplied yet | TBD |
| Special Chest/Egg and Rosevow gameplay rules | Not supplied yet | TBD |
| Ranking and outside-season preview | Not supplied yet | TBD |
| New visual/audio assets | Defined after content choices | TBD |

## 8. Pridefest event intake

| Field | Current value | Status |
|---|---|---|
| Event concept | Pridefest | Confirmed |
| Dragon family | Spectrumplume; all six sprites approved | Confirmed |
| Event Trial | One unique Pridefest Trial | Confirmed |
| Trial concept | Prismatic Parade: remember colors, guide beam, crack crystal on beat | Proposed |
| Trial rotation | Fourth eligible kind while the Pridefest event is active | Confirmed program rule |
| Exact named occasion and inclusive story | Not supplied yet | TBD |
| Schedule/timezone/recurrence | No universal date may be assumed | TBD |
| Adventure, participation, requirements and duration | Not supplied yet | TBD |
| Expertise reduction and direct rewards | Not supplied yet | TBD |
| Special Chest/Egg and Spectrumplume gameplay rules | Not supplied yet | TBD |
| Ranking and outside-season preview | Not supplied yet | TBD |
| New visual/audio assets | Defined after content choices | TBD |

## 9. Implementation roadmap per event

| Phase | Codex work | Owner work | Gate |
|---:|---|---|---|
| 1. Contract | Convert approved answers into versioned event, Trial, chest and egg definitions; mark unresolved fields | Approve every material TBD and player-facing name/reward | No gameplay implementation with unresolved schedule, rewards, requirements, or egg contents |
| 2. Data model | Add event occurrence/provenance, Trial kind, preview entitlement and save/import compatibility | Confirm behavior of legacy/imported items | Migration and compatibility tests green |
| 3. Server foundation | Add authoritative ranked-attempt tokens, validation, best-score board, freeze, five-day results and idempotent prizes | Approve staging migration and provide tester account scope | Staging only until security/E2E checks pass |
| 4. Core event | Implement timezone-safe schedule, recurrence, countdown, notification and exact boundary handling | Review copy and timing | Before/at/after boundary tests green |
| 5. Trial rotation | Add the active event kind to refills without increasing board capacity; remove expired unstarted offers | Confirm equal weighting or another exact weight | Deterministic distribution and persistence tests green |
| 6. Minigame | Build mechanics, expertise assistance, score, grading, rewards, pause/background and accessibility behavior | Playtest feel and approve thresholds | Widget, integration and emulator tests green |
| 7. Rewards | Implement Adventure, chest, egg, dragon, achievement and duplicate/cap rules | Approve exact content and presentation | Fixed/random path and idempotency tests green |
| 8. Preview code | Add server-scoped test occurrence and active code reference without release-note disclosure | Provide authorized Keeper ID(s) and approve duration/reward rules | Preview cannot affect seasonal ranking or unauthorized accounts |
| 9. Assets/audio | Generate, integrate, optimize and validate all event art/sound | Visually review all new event assets | No matte, crop, direction, scale or license failures |
| 10. Documentation | Update living event, randomness, redeem-code and audit documents | Confirm final design matches intent | Documentation guard green |
| 11. Release candidate | Full analyzer/tests, staging E2E, server preflight, signed Android build and version increment | Explicitly authorize production migration and release | Stop on any failed gate |

## 10. Cross-event technical architecture

The implementation should be data-driven around separate definitions:

- `SeasonalEventDefinition`: identity, story, schedule, recurrence,
  presentation, notification and linked content IDs;
- `EventTrialDefinition`: owning event/version, Trial mechanics, refill weight,
  expertise assistance, score/grades, attempt and reward rules;
- `EventOccurrence`: exact UTC boundaries derived from configured local wall
  time, completion key and results-retention boundary;
- `SpecialAdventureDefinition`: participation, requirements, duration,
  expertise reduction and direct rewards;
- optional `SpecialChestDefinition`: immutable versioned contents, reveal,
  trade, stack, sprite and audio behavior;
- optional `SpecialEggDefinition`: immutable versioned family pool, incubation,
  Spectral, hint, trade and achievement behavior;
- `EventRankingSeason`: occurrence-scoped attempts, verified scores, frozen
  podium, prize grants and five-day expiry; and
- `EventPreviewEntitlement`: account scope, code source, preview boundaries,
  isolation mode and revocation.

Stored chests and eggs retain definition IDs and versions after an event ends.
Different event items cannot merge into one ambiguous `special` stack. Backup,
restore, import, trade, offline resume, app update and clock/timezone changes
must preserve their original meaning.

## 11. Verification matrix

Every event needs automated and emulator coverage for:

- immediately before, exactly at, and immediately after start/end;
- annual recurrence and Europe/Amsterdam daylight-saving changes;
- normal calendar access versus personal preview access;
- four-kind refill eligibility, statistical weight, duplicate offers, restart,
  expired offers and event close during a run;
- all grades, score boundaries, expertise caps, reward rolls and no-duplicate
  cosmetics;
- interrupted claims, double taps, offline completion and repeated server calls;
- ranking token replay, tampered logs, impossible timings, ties, freeze, prize
  retry and five-day result expiry;
- authenticated, unauthenticated, unverified and unauthorized-code accounts;
- save/load, cloud backup, audited import, old saves and definition-version
  compatibility;
- small phones, tall phones, tablets, large text, reduced motion and screen
  rotation where supported;
- notification permission states, foreground/background behavior and deep
  links; and
- sprite alpha, bounds, direction, scale, memory use, APK size and audio
  licensing.

## 12. Current owner decisions still required for Halloween

1. Approve or replace every `Proposed` value in section 4.
2. Confirm equal 25% Trial refill weighting.
3. Choose the event-close behavior for an unstarted offer and a run already in
   progress.
4. Approve three official ranked attempts and whether all three grant rewards.
5. Approve the balanced expertise split and capped-point overflow behavior.
6. Approve the podium rewards, repeat-emote handling, and whether any result is
   permanently recorded after the five-day display.
7. Provide the Keeper ID(s) allowed to use `HALLOWEENEVENT`.
8. Approve preview duration, reuse, inventory/reward isolation, and test-ranking
   behavior.
9. Confirm whether the Halloween event includes the proposed Special Adventure,
   Special Chest, and Special Egg.
10. Approve all exact Adventure/chest/egg/dragon rewards and rules.
11. Decide whether the event needs its own background music or only effects.
12. Visually approve the new non-dragon event assets after they are created.

## 13. Current owner decisions still required for Christmas

1. Approve or replace the proposed event and Adventure names, story, first
   scheduled year, timezone, recurrence, duration, participation, repeat limit,
   and expertise reduction in section 5.1. The 25–26 December calendar window
   is already confirmed.
2. Confirm whether Christmas includes the proposed Special Adventure,
   Starlight Gift Chest, and Starlit Evergreen Egg.
3. Approve the exact direct rewards and the fixed chest contents.
4. Approve a 25-hour incubation, 5%/10% Spectral rule, always-Good moral nature,
   normal Order/personality rules, and non-tradeability.
5. Approve **A Star in Every Hearth** as the hatch achievement.
6. Approve or rename **Hollyfrost Giftforge** and its recipe, forge-timing, and
   sleigh-guidance mechanics.
7. Confirm equal 25% Trial refill weighting during the Christmas event.
8. Choose the event-close behavior for an unstarted Giftforge offer and a run
   already in progress.
9. Approve three official ranked attempts, normal rewards for every official
   attempt, the balanced expertise split, and capped-point overflow behavior.
10. Approve the top-three chests, three proposed Hollyfrost emotes, repeat-win
    counter, and five-day frozen results period.
11. Confirm `CHRISTMASEVENT`, provide authorized Keeper ID(s), and approve its
    preview duration, reuse, reward isolation, and preview-ranking behavior.
12. Decide whether Christmas receives its own background music or only new
    ambient/game/chest sound effects.
13. Visually approve the new non-dragon Christmas assets after creation.

No production migration, public release, paid service, or live server mutation
is authorized by this planning document.
