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

The approved Halloween/Christmas design and proposed New Year design use equal
selection among the eligible kinds. With one active event this means a newly
refilled slot has:

| Trial kind | Proposed refill chance |
|---|---:|
| Cavern Flight | 25% |
| Ruin Breaker | 25% |
| Runeweaver | 25% |
| Active event Trial | 25% |

The refill is selected independently for each empty slot, so duplicate kinds
remain possible just as they are today. Event Trial offers persist across an
ordinary app restart. For Christmas, an offer can only transition into a
started run on 25 or 26 December; an unstarted offer is removed at event close,
while a run genuinely started before that boundary remains finishable afterward.
New Year currently proposes the same boundary contract.

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
- count a completed event Trial toward the Seven-day Trial Constellation under
  the existing maximum of one filled day per local calendar date;
- support touch, compact screens, tablets, text scaling, reduced motion,
  foreground/background transitions, and deterministic testing; and
- use server-authoritative official attempts for rewarded worldwide rankings.

There is no shared three-errors-or-lives rule. Each Trial prototype gets only a
timer or failure mechanic that genuinely belongs to that game's loop.

### Temporary worldwide ranking proposal

| Rule | Proposed behavior | Status |
|---|---|---|
| Eligibility | Registered and e-mail-verified accounts | Confirmed for Christmas; proposed shared default |
| Ranked access | Every event-Trial offer that appears in the normal refill rotation can be played once; no per-event attempt cap | Confirmed for Halloween and Christmas |
| Practice | No separate unlimited practice mode | Confirmed for Halloween and Christmas |
| Per-run reward | Every completed event-Trial offer grants its normal grade reward | Confirmed for Halloween and Christmas |
| Counted score | Best verified score for that occurrence | Confirmed for Halloween and Christmas |
| Tie-breakers | Accuracy, then shortest run time, then earliest submission | Confirmed for Christmas; proposed shared default |
| Closing | Stop new starts at event end, allow an already-started run to finish, then freeze and grant prizes exactly once | Confirmed for Christmas; proposed shared default |
| Results visibility | Full ranking is read-only for five complete days after event close | Confirmed |
| Permanent archive | After five days, retain only the top three in the Seasonal Chronicle | Confirmed for Halloween and Christmas |
| Next recurrence | New occurrence ID and empty live ranking | Confirmed |
| First place | Mythical Chest plus gold event podium emote | Confirmed for Halloween and Christmas |
| Second place | Dragon Chest plus silver event podium emote | Confirmed for Halloween and Christmas |
| Third place | Gold Chest plus bronze event podium emote | Confirmed for Halloween and Christmas |
| Repeat cosmetic | Keep chest; show a win count on the already owned emote | Confirmed for Christmas; proposed shared default |

Ranked attempts require a server-issued occurrence ID, deterministic seed,
nonce, short-lived attempt token, and a compact action log that the server can
validate. Submission replay, expired tokens, impossible timing, impossible
scores, and excessive submission rates must be rejected. Prize grants must be
idempotent and recoverable after an interrupted sync.

For Christmas, a completed offline run still receives its normal local reward,
but only a run started with a valid server attempt token can enter the worldwide
ranking. Expertise points follow the grade table's existing total and balanced
split; a point blocked by one capped expertise moves to the next eligible area
and is discarded only when all three are capped.

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
| Expertise reduction | Combined Might + Spirit + Arcana, 15 minutes per point, minimum 24 hours | Minimum confirmed; remaining values proposed |
| Direct rewards | 500 XP, +13 Might, +13 Spirit, +13 Arcana, one Witchlight Chest | Proposed |
| Advance disclosure | Show XP, expertise, and chest; keep chest contents secret | Proposed |

### 4.2 Halloween Trial proposal

**Witchlight Ward** repeats one cohesive three-step round:

1. Arcana identifies the safe rune before it fades.
2. Spirit guides its witchlight into the protected lantern.
3. Might breaks the approaching curse at the bright timing point.

Correct rounds build a capped combo and increase speed. There is no inherited
three-mistake rule: the prototype determines whether Witchlight Ward ends on a
timer, a game-specific failure state, or another mechanic that actually belongs
to this game. Arcana slightly extends rune visibility, Spirit slightly improves
steering/collision tolerance, and Might slightly widens the strike window.
Exact assistance caps, scoring formula, grade thresholds, and final failure
timing will be established through prototype playtesting.

There is no separate practice mode and no per-event attempt allowance. Every
Witchlight Ward offer produced by the ordinary Trial refill system can be
played once, grants its normal Trial reward, and can improve the keeper's best
verified event score.

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
| Family type | Special; never counts for a rarity achievement | Proposed |
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
| Authorized account(s) | `DH-17792DC5` only | Confirmed |
| Preview duration per activation | 48 hours | Confirmed |
| Redemption reuse | Reusable after the previous preview expires | Confirmed |
| Production preview rewards | Simulate and display rewards, but do not alter permanent production inventory | Proposed; Halloween still needs confirmation |
| Staging preview rewards | Grant real staging rewards to test persistence and idempotency | TBD |
| Preview ranking | Isolated test board or ranking-disabled; never live seasonal | TBD for Halloween |
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
| Trial name | Hollyfrost Giftforge | Confirmed |
| Event display name | A Star for the Winter Hearth / Een Ster voor de Winterhaard | Confirmed |
| Stable event ID | `christmas_winter_hearth` | Codex implementation choice |
| Event story | Restore a lost sleigh of starlight so Hollyfrost can carry warmth to every room in the Haven | Confirmed |
| Calendar window | 25 December 00:00 through 27 December 00:00, covering only 25 and 26 December | Confirmed |
| First scheduled year | 2026 | Confirmed |
| Timezone | Europe/Amsterdam wall time | Confirmed |
| Recurrence | Annually on the same local dates/times | Confirmed |
| Special Adventure | The Starlight Sleigh / De Sterrenlichtslee | Confirmed |
| Adventure duration | 96 hours before reduction | Confirmed |
| Completion after close | Allowed if started during the active window | Confirmed |
| Adventure limit | Once per account per occurrence | Confirmed |
| Participation | One available owned dragon; no form/rarity minimum | Confirmed |
| Expertise reduction | Combined Might + Spirit + Arcana, 15 minutes per point, minimum 24 hours | Confirmed |
| Direct rewards | 600 XP, +12 Might, +12 Spirit, +12 Arcana, one Starlight Gift Chest | Confirmed |
| Advance disclosure | Show XP, expertise, and Special Chest; keep chest contents secret | Confirmed |

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

Confirmed notification behavior is one notification at event opening, using
the existing Special Events account toggle and a deep link directly to the
Christmas event. No extra Christmas-morning notification is sent unless the
owner explicitly requests it.

### 5.3 Christmas Trial proposal

**Hollyfrost Giftforge** uses a repeating three-step workshop round:

1. Arcana briefly reveals a small recipe of two or three gift sigils.
2. Might stamps the gift when a moving forge meter reaches its golden zone.
3. Spirit guides the finished gift into the matching sleigh compartment while
   avoiding rolling snowballs and drifting frost.

Correct rounds build a capped **Starlight Chain** and gradually speed up. There
is no precommitted three-mistake rule. Wrong recipes, badly timed stamps, and
collisions reset or reduce the chain; prototype playtesting determines whether
Giftforge also needs a thematic failure condition or simply ends on its normal
run timer. The score then arrives with the normal Trial result animation and
rewards are granted at that moment.

Expertise assistance remains deliberately small:

- Arcana keeps the recipe visible slightly longer;
- Might makes the golden forge zone slightly wider; and
- Spirit improves steering and collision tolerance slightly.

The submitted score is the achieved gameplay score and is never multiplied by
expertise. Exact assistance caps, round values, combo cap, acceleration,
game-specific ending behavior, and D/C/B/A/S/S+ thresholds are determined
through prototype playtesting.

The Trial uses the shared four-kind refill contract: while Christmas is active,
each newly filled Trial slot can choose Cavern Flight, Ruin Breaker,
Runeweaver, or Hollyfrost Giftforge, each with a 25% refill chance.
Hollyfrost Giftforge enters the pool at 25 December 00:00 and leaves it at
27 December 00:00; it is therefore seasonally available only on 25 and
26 December. An explicitly authorized personal preview occurrence is the only
outside-season exception.

There is no practice mode or separate attempt allowance. Every Giftforge offer
that appears through the normal Trial refill system can be played once. Every
completed run grants its normal grade reward and can improve the keeper's best
verified Christmas score. The offer can only be started on 25 or 26 December;
if its run has genuinely started before 27 December 00:00, it may be completed
after that boundary. An unstarted offer is removed. A completed Giftforge run
counts toward the Seven-day Trial Constellation under the normal one-day-per-
local-date limit.

### 5.4 Christmas chest and egg proposal

| Field | Proposed value | Status |
|---|---|---|
| Chest definition ID | `christmas_starlight_gift_chest_v1` | Codex implementation choice |
| Player-facing chest name | Starlight Gift Chest / Sterrenlichtgeschenkkist | Confirmed |
| Chest contents | 250 coins, 12 gems, one Starlit Evergreen Egg | Confirmed |
| Randomness | Fixed contents | Confirmed |
| Roll timing | No content roll; identity is fixed when granted | Confirmed |
| Tradeability | Never tradeable | Confirmed |
| Multi-open | Not relevant with one obtainable chest per occurrence; retained version still supports safe inventory display | Confirmed by acquisition limit |
| Player disclosure | Show only that a Special Chest is awarded; do not reveal contents before opening | Confirmed |
| Chest art/audio | New closed/open gift-chest sprites and warm magical bell/unwrap opening sound | Needed; Codex |
| Egg definition ID | `christmas_starlit_evergreen_egg_v1` | Codex implementation choice |
| Player-facing egg name | Starlit Evergreen Egg / Sterrenlicht-dennenei | Confirmed |
| Egg outcome | Hollyfrost only, 100% | Confirmed |
| Family type | Special; never counts for a rarity achievement | Confirmed |
| Incubation | Exactly 25 hours | Confirmed |
| Speed-up | No special tap acceleration; normal incubation rules and eligible relics apply | Confirmed |
| Spectral | 5% normally; 10% when hatching during Golden Hour | Confirmed |
| Moral nature | Always Good and immediately known | Confirmed |
| Order nature | Normal random identity rule | Confirmed |
| Personality | Normal random identity rule; initially hidden | Confirmed |
| Egg tradeability | Never tradeable | Confirmed |
| Acquisition | One guaranteed egg through this event's one chest per occurrence | Confirmed |
| Hint | Warmth glows beneath evergreen frost while a distant bell answers from inside | Codex copy; owner may revise |
| Hatch achievement | A Star in Every Hearth | Confirmed |
| Journal/Draconomicon | Record the event hatch, Special family, and every evolved form normally | Confirmed |

Hollyfrost uses the ordinary non-Infernal evolution levels, expertise caps, and
form rules unless the owner requests a Christmas-specific difference. Its
Special classification keeps it outside Common–Infernal rarity
achievements and ordinary egg pools.

### 5.5 Christmas Trial rewards and ranking proposal

An official Hollyfrost Giftforge run reuses the normal Trial grade reward table.
XP, chest odds, the S+ relic roll, and the S+ ordinary Trial-emote roll remain
unchanged. The normal total expertise reward is distributed across Might,
Spirit, and Arcana using the shared balanced split in section 3. Points blocked
by an expertise cap move to another eligible expertise and are discarded only
when all three are capped.

Every randomly refilled Giftforge offer is an official rewarded run. There is
no per-occurrence attempt limit and no separate practice mode. The best
online-validated score counts. Offline completion still grants the normal
reward but cannot submit a ranked score. Only registered, e-mail-verified
accounts enter the board. Ties resolve by accuracy, then shorter run duration,
then earliest submission. The complete final ranking remains visible for five
days, after which only the occurrence, top-three keepers, their scores, places,
and podium cosmetics are retained permanently in the Seasonal Chronicle.

Confirmed Christmas podium rewards:

| Place | Chest | Unique Hollyfrost emote |
|---:|---|---|
| 1 | Mythical Chest | **Crowned by Starlight** — jubilant Hollyfrost beneath a golden star crown |
| 2 | Dragon Chest | **Giftwrapped Joy** — Hollyfrost happily tangled in a silver ribbon |
| 3 | Gold Chest | **Snowy Cheer** — Hollyfrost giving a proud bronze-bell salute |

All three are permanent, non-tradeable chat emotes. A repeated podium result
never creates a duplicate; it increases a visible podium-win count on the owned
emote while the normal chest prize is still granted.

### 5.6 Outside-season Christmas preview proposal

Confirmed redeem code: `CHRISTMASEVENT`. It remains planned and inactive
until the Christmas event is implemented and the active catalog plus
`REDEEM_CODES.md` are updated together.

The preview follows the Halloween safety model:

- only Keeper ID `DH-17792DC5` can redeem it;
- redemption outside the season starts a personal 48-hour Christmas preview;
- it can be redeemed again after the previous 48-hour preview has expired;
- it enables the event UI, Adventure, simulated chest/egg flow, Giftforge, and
  the four-kind Trial rotation for that tester;
- preview scores enter a separate test ranking and never the real Christmas
  worldwide ranking;
- production preview rewards are simulated and never alter permanent inventory;
- staging uses an explicit test fixture with persistent staging-only rewards to
  verify reward grants and idempotency without changing the production preview
  contract;
- the UI and diagnostic export clearly identify `TEST EVENT`; and
- the server can disable or re-enable the code without publishing a new app.

These preview rules are confirmed for the owner account.

### 5.7 Christmas assets still needed

- event banner, event card treatment, guiding star, sleigh, and winter-hearth
  presentation;
- Hollyfrost Giftforge Trial icon and warm workshop background;
- recipe sigils, forge meter, stamp, gift variants, sleigh compartments,
  snowballs, frost obstacles, hearth-light accents, combo, hit/miss, and result
  sprites/animations;
- closed and opened Starlight Gift Chest;
- Starlit Evergreen Egg and nest presentation;
- three Hollyfrost podium emotes if rankings are approved;
- warm magical chest-opening sound plus bell, forge, and gameplay feedback
  effects; and
- one Christmas background track from an explicitly verified CC0/Public Domain
  recording source.

All new visual assets use transparent backgrounds where appropriate, safe
margins, and consistent in-game scale. The owner has waived a separate visual
review for these non-dragon Christmas assets; Codex must still perform repeated
alpha, crop, scale, contrast, memory, and emulator checks before release.

### 5.8 Temporary Christmas music contract

- The event has one dedicated Christmas background track in addition to its
  new bell, forge, chest, success, error, combo, and result effects.
- The recording must be explicitly verified as CC0/Public Domain for commercial
  app distribution; public-domain composition status alone is insufficient.
- The track becomes temporarily available in the Jukebox when an account enters
  or signs in during an active Christmas occurrence or its authorized preview.
- It is event access, not permanent collection ownership, cannot drop from a
  Music Chest, and does not change Music Chest completion counts or odds.
- At 27 December 00:00—or when a personal preview expires—the track disappears
  from the selectable Jukebox catalog and active playback transitions cleanly
  to the next selected owned track or silence.
- The selected/toggle state of permanent tracks remains untouched.
- It is automatically enabled on first event entry when global music is on,
  remains individually switchable in the Jukebox, and never forces global music
  on.
- Codex selects and verifies the exact recording. The preferred composition is
  **O Christmas Tree**; both the composition and specific recording must satisfy
  the stated commercial-use public-domain/CC0 requirement before inclusion.

## 6. New Year's Day event proposal

| Field | Current value | Status |
|---|---|---|
| Event concept | New Year's Day | Confirmed |
| Dragon family | Dawnchime; all six sprites approved | Confirmed |
| Event Trial | One unique New Year Trial | Confirmed |
| Trial concept | Midnight Chime: read a sigil, guide its firework, burst it on the midnight bell | Proposed |
| Trial rotation | Fourth eligible kind with equal 25% refill chance while the event is active | Proposed |
| Event display name | When the New Dawn Rings / Wanneer de Nieuwe Dageraad Klinkt | Proposed |
| Stable event ID | `new_year_first_dawn` | Codex proposal |
| Event story | Dawnchime must recover the final scattered chimes so the first sunrise can cross the Haven | Proposed |
| First window | 31 December 2026 18:00 through 2 January 2027 00:00 | Proposed |
| Timezone/recurrence | Europe/Amsterdam wall time; annually across the same year boundary | Proposed |
| Special Adventure | The Bell Beyond Midnight / De Klok Voorbij Middernacht | Proposed |
| Adventure duration | 72 hours before reduction | Proposed |
| Completion after close | Adventure and already-started Trial may finish after close; neither can start after close | Proposed |
| Adventure limit | Once per account per occurrence | Proposed |
| Participation | Solo with one available owned dragon; no form/rarity minimum | Proposed |
| Expertise reduction | Combined Might + Spirit + Arcana, 15 minutes per point, minimum 24 hours | Proposed |
| Direct rewards | 700 XP, +10 Might, +10 Spirit, +10 Arcana, one Firstlight Celebration Chest | Proposed |
| Advance disclosure | Show XP, expertise, and Special Chest; keep chest contents secret | Proposed |

### 6.1 Story and presentation proposal

**Short event story:**

> On the last night of the year, the Haven's great sky-bell falls silent and
> the first sunrise loses its path. Dawnchime gathers its scattered notes across
> the darkened towers, searching for the one clear chime that can call a new dawn
> home.

The presentation moves from indigo midnight through gold and coral sunrise.
Firework trails, turning-year rings, hanging chimes, and the first ray of dawn
connect the Adventure, Trial, chest, egg, and ranking. The event card has a live
availability countdown. Its detail page separates requirements, visible
rewards, the Special Adventure, the event Trial, and the temporary ranking.

The proposed access rule has no Tower-level, rarity, family, or alignment gate.
One notification is sent when the event opens, controlled by the existing
Special Events notification toggle and deep-linked to this event.

### 6.2 Special Adventure proposal

**The Bell Beyond Midnight** is a solo, once-per-occurrence journey for one
available dragon. Its 72-hour base duration is reduced by the participating
dragon's combined Might, Spirit, and Arcana at 15 minutes per point, never below
24 hours. Starting is restricted to the active event window; once started, the
Adventure remains safely finishable afterward.

Proposed direct rewards are:

- 700 XP for the participating dragon;
- +10 Might, +10 Spirit, and +10 Arcana; and
- one non-tradeable **Firstlight Celebration Chest**.

The XP, expertise, and presence of the Special Chest are visible before start.
The chest contents are not shown.

### 6.3 Midnight Chime Trial proposal

**Midnight Chime** is a timed approximately 75-second sequence with three short
actions per round:

1. Arcana remembers and selects the briefly shown constellation sigil.
2. Spirit guides the matching firework through curved, moving sky rings.
3. Might strikes the great bell in its bright timing zone so the firework bursts
   exactly on the chime.

Correct rounds build a capped **Dawn Chorus** combo and gradually increase the
pace. A mistake breaks the combo and costs time, but there is no arbitrary
three-error limit and no separate practice mode. The run ends when its timer
expires. Arcana slightly lengthens the sigil preview, Spirit slightly widens the
safe ring path, and Might slightly widens the bell timing zone. These benefits
are capped and never multiply the submitted score.

During the active event, Midnight Chime joins the three ordinary Trial kinds as
a fourth equally weighted refill result. Every refilled offer can be played
once, grants the normal Trial grade reward, and can improve the keeper's best
verified event score. An offer may only be started while the event is active;
an already-started run can finish afterward. It counts toward the Seven-day
Trial Constellation, still subject to the global maximum of one day per local
calendar date.

The proposed expertise distribution and capped-point overflow reuse the now
confirmed Christmas rule: preserve the ordinary grade's total expertise,
allocate its balanced split across all three areas, reroute capped points to an
eligible area, and discard a point only when all three areas are capped.

### 6.4 New Year chest and egg proposal

| Field | Proposed value | Status |
|---|---|---|
| Chest definition ID | `new_year_firstlight_chest_v1` | Codex proposal |
| Chest name | Firstlight Celebration Chest / Eerstelicht-feestkist | Proposed |
| Chest contents | 365 coins, 12 gems, one Turning-Year Egg | Proposed |
| Randomness | Fixed contents | Proposed |
| Tradeability | Never tradeable | Proposed |
| Player disclosure | Show only that a Special Chest is awarded; keep all contents secret until opening | Proposed |
| Chest presentation | Own closed/open sprites and a layered bell, firework, and dawn-burst opening sound | Needed; Codex |
| Egg definition ID | `new_year_turning_year_egg_v1` | Codex proposal |
| Egg name | Turning-Year Egg / Jaarwende-ei | Proposed |
| Egg outcome | Dawnchime only, 100% | Proposed |
| Family type | Special; never counts for an ordinary rarity achievement | Proposed |
| Incubation | Exactly 24 hours | Proposed |
| Speed-up | No special tap acceleration; ordinary eligible incubation effects still apply | Proposed |
| Spectral | 5% normally; 10% when hatching during Golden Hour | Proposed |
| Moral nature | Always Neutral and immediately known, reflecting balance between the old and new year | Proposed |
| Order/personality | Normal random identity rules; personality initially hidden | Proposed |
| Tradeability | Never tradeable | Proposed |
| Hatch achievement | First Light, First Flight | Proposed |

Dawnchime otherwise uses normal evolution levels, expertise requirements and
caps. Its six already approved forms remain classified as Special and outside
ordinary rarity-achievement progress.

### 6.5 Ranking proposal

The New Year ranking reuses the Christmas safety and fairness rules: registered
and e-mail-verified accounts, server-issued attempt tokens, rewarded offline
completion but ranking only for online validated runs, best verified score,
then accuracy, shorter duration, and earliest submission as tie-breakers.

The complete ranking freezes at event close and remains visible for five days.
Afterward only the top three are retained permanently in the Seasonal Chronicle.
A later annual occurrence begins with an empty ranking.

| Place | Chest | Unique Dawnchime emote |
|---:|---|---|
| 1 | Mythical Chest | **Crowned at Midnight** — Dawnchime beneath a crown of golden fireworks |
| 2 | Dragon Chest | **Silver Spark Salute** — Dawnchime ringing a bright silver sky-bell |
| 3 | Gold Chest | **Bronze Dawn Cheer** — Dawnchime greeting the sunrise with a bronze chime |

An already-owned podium emote receives a visible podium-win count instead of a
duplicate; its chest reward is still granted.

### 6.6 Outside-season preview proposal

Proposed redeem code: `NEWYEARSEVENT`, inactive until implementation. The
recommended contract matches Christmas:

- only Keeper ID `DH-17792DC5` can use it;
- it opens a reusable personal 48-hour preview after the previous preview ends;
- production rewards are simulated and cannot change permanent inventory;
- scores use a separate test ranking;
- staging may grant persistent staging rewards for complete reward and
  idempotency verification; and
- the UI and diagnostic export label the occurrence as `TEST EVENT`.

### 6.7 Music, sound, and art proposal

The event receives one temporary New Year background track that is automatically
enabled on first event entry when global music is enabled, remains switchable in
the Jukebox, and disappears cleanly after the event or personal preview. Codex
will source an explicitly CC0/Public Domain commercial-use recording; the
recommended musical direction is a distinct festive-bell arrangement of **Auld
Lang Syne**, kept separate from any permanently owned Jukebox recording.

New assets still needed are the event banner/card, first-dawn sky, great bell,
firework rings and trails, Trial UI pieces and reactions, closed/open chest,
egg, three podium emotes, and bell/firework/chest/success/error sounds. Existing
approved Dawnchime family sprites are reused. Whether the owner wants a separate
emulator review of these non-dragon assets remains undecided.

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
4. Approve the balanced expertise split and capped-point overflow behavior.
5. Approve the podium rewards and repeat-emote handling. The five-day full
   result display followed by a permanent top-three Seasonal Chronicle entry is
   already confirmed.
6. Decide Halloween's production preview reward mode, preview ranking mode, and
   whether staging previews grant persistent staging rewards. Keeper ID
   `DH-17792DC5` and reusable 48-hour access are already confirmed.
7. Confirm whether the Halloween event includes the proposed Special Adventure,
   Special Chest, and Special Egg.
8. Approve all exact Adventure/chest/egg/dragon rewards and rules. The minimum
   reduced Adventure duration is already confirmed as 24 hours.
9. Decide whether the event needs its own background music or only effects.
10. Visually approve the new non-dragon event assets after they are created.

## 13. Christmas owner decisions

All material Christmas content choices are resolved. Codex may tune only
implementation-level timing, thresholds, accessibility behavior, responsive
layout, and a game-specific ending mechanic through tests and playtesting. This
does not authorize changing the schedule, rewards, odds, availability, ranking
contract, or preview safety model.

## 14. Current owner decisions still required for New Year

1. Approve or replace the proposed display name, story, stable ID, Adventure
   name, and Dutch names.
2. Confirm the first window (31 December 2026 18:00 through 2 January 2027
   00:00), Europe/Amsterdam timezone, and annual recurrence.
3. Confirm solo participation, one available dragon, once per occurrence,
   72-hour base duration, 15 minutes per combined expertise point, and 24-hour
   minimum.
4. Approve the direct 700 XP, +10 to each expertise, and one Firstlight
   Celebration Chest reward.
5. Confirm the fixed secret chest contents: 365 coins, 12 gems, and one
   Turning-Year Egg; both chest and egg non-tradeable.
6. Confirm the 24-hour Dawnchime-only egg, normal eligible incubation effects,
   5%/10% Golden Hour Spectral rules, and **First Light, First Flight** hatch
   achievement.
7. Approve always Neutral and immediately known for Dawnchime, with random Order
   and initially hidden random personality, or choose another identity rule.
8. Approve the 75-second Midnight Chime loop, timer ending, mistake penalties,
   equal 25% refill weighting, no attempt cap/practice mode, and ordinary Trial
   rewards.
9. Confirm that the Christmas constellation, offline/ranking, eligibility,
   tie-breaker, five-day results, Seasonal Chronicle, podium, and repeat-win
   rules also apply to New Year.
10. Approve `NEWYEARSEVENT`, Keeper ID `DH-17792DC5`, reusable 48-hour preview,
    simulated production rewards, separate test ranking, and persistent staging
    fixtures.
11. Confirm one opening notification and authorize Codex to source a verified
    CC0/Public Domain New Year track in the proposed Auld Lang Syne direction.
12. Decide whether the newly created non-dragon New Year assets require a
    separate emulator approval round or may use Codex's repeated visual checks.

No production migration, public release, paid service, or live server mutation
is authorized by this planning document.
