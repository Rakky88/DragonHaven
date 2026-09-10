# DragonHaven Redeem Codes

Candidate 77: group level requirements are capped at the number of players
multiplied by the current nine-level progression. A two-keeper group that used
to demand level 20 or 24 now requires 18; attainable requirements, expertise,
duration, XP and the stored 70/25/5 chest roll stay the same. Both canonical and
legacy lobby creation use the bound, and only waiting existing lobbies are
repaired. Owned social/group rows allow cascades after the Auth parent is gone,
while direct inventory deletion remains forbidden. The rollback rehearsal
covers all 200 catalog entries and promoted participant/owner deletion without
changing the other keepers' inventories. Rollback run 34492695690 passed on
6f61cf9; migration 77 is not applied yet. Full run 34491961542 applied schema
75/76 and deployed the worker, then stopped at mandatory database lint: two
revoked v74 function bodies still return integer columns. Candidate 78 removes
all seven superseded narrow entry points with RESTRICT; no player data or
current RPC is removed. Its rollback rehearsal is pending. Production stays
schema 65 / v0.05.29; no release has been published.


Staging readiness update: rollback run 34490598706 (`af103f5`) passed the
schema-76 seasonal binding contract, including event/Conclave changes, device
resume, one contribution, closed-event cutoff, old-writer refusal, atomic
rollback and Auth cleanup. Focused real trade run 34490602505 passed every UI
and database assertion; cleanup removed all synthetic users and disabled all
four switches. Schema 75/76 were subsequently applied by run 34491961542. Production stays
schema 65 / v0.05.29.

The canonical event-end command now clears previews and dismisses only the
current calendar editions; local tests retain balances/chests and permit next
year's event. The legacy local provider still uses authenticated online event
control. The full staging candidate now includes one real Sunwake sprite run,
its exact server ranking and one personal reward, followed by event end. Partner
fixtures use the same private activation map that the server publishes. These
new actual-server checks are pending; the full apply remains staging-only.

Previous checkpoints below are historical.

Verified staging evidence: schema 75 was rehearsed with full rollback in run
34489515550 (`e77c9a3`): 3-billion scores, 8-billion-ms durations, ordinary/event
rankings, profile/friend/snapshot readers, podium and exact-number bounds pass.
It remains unapplied; deployed staging stays schema 74. Focused trade run
34489538865 confirms both real receipt animations and lost-confirm recovery.
Its final SQL assertion compared a sparse chest map with a normalized map that
contains explicit zero counts; that assertion now checks exact counts instead.
The sender animation assertion also waits for its route to become visible.
Synthetic cleanup succeeded and all switches are off. Production is unchanged.

Candidate 76 publishes private event preview/dismissal maps and binds each
server-verified seasonal Trial to its original event, closing time and Conclave.
Resume rotates a device ID without duplicating the binding. Completion writes
rankings/contributions atomically; cancellation gives neither. A run finished
after the pinned closing time retains personal rewards but cannot rewrite the
closed ranking or Conclave project. Legacy score/activation writers are fenced.
The rollback rehearsal and actual event UI proof are pending. Cutover, complete
migration and lossless APK reduction still precede the one authorized release.

Previous staging notes below are historical.

Latest staging: run 34486928336 on `9e2d4f9` deployed schema 74 and the
repaired worker. Preflight at 14:15:39 UTC passed with lint 0 and
Auth/settings/app 200. Actual inventory/gameplay, group, partner and Beacon
UI checks passed. The trade probe reached a committed exact exchange and
recovered a lost reply, then failed its sender-animation assertion. Cleanup
removed every synthetic account and disabled all four switches at 14:22:04
UTC. Production remains schema 65 / v0.05.29. Full cutover, migration and
lossless APK reduction remain open; no release yet.

Candidate 75 widens seasonal score/action/duration storage and ordinary/friend
score readers to bigint, preserving exact values through JavaScript's safe
integer ceiling. The rollback probe covers a 3-billion score and 8-billion-ms
run, profile/friend/snapshot readers, event/ordinary rankings, podium, chronicle,
replay and out-of-range rejection. It has not yet been rehearsed or applied.
No event dates, rank cutoffs, reward amounts, probabilities or codes change.

Trial resume candidate: resuming restores the saved game, score and mistakes,
releases a previously held pointer and rotates the attempt ID to fence an old
device. A private clock origin excludes time away. The six-hour expiry remains;
expired attempts can be abandoned without rewards. No score, clock, seed or
checkpoint can be uploaded by the player. All eleven games are replayed across
one saved/resumed checkpoint in the parity fixture. Local restart, lost reply,
old-ID refusal, elapsed-time refusal, expiry and one-reward checks pass. Event
schedules, reward amounts, pools, probabilities and redeem codes do not change.

Trade candidate (migration 74, applied only on staging): one-for-one exchanges reserve one
item per side, retain the existing one-active-trade, three-per-Amsterdam-day
and ten-minute limits, and commit both private inventories together. Eggs keep
their fixed genetics, sex, Special catalog identity, tags and discovered facts.
Ordinary tradeable chest tiers and the six consumable relic types retain their
eligibility; cosmetic/Special chests and all four equipable brooches remain
untradeable. A Chronoshard moves with its exact percentage, without a new roll.
Unknown egg information stays private in offers, receipts and reveal scenes.
No chance, reward table, event schedule or redeem-code value changes. Domain,
Edge and VM/JavaScript parity tests pass. Staging rollback run 34483041422 on
04b7c6a passed atomic two-owner conservation, replay, expiry and legacy fences.
The picker now shows item details before offering, and the existing animated
trade scene accepts masked server data and acknowledges without another grant.
Local UI lost-response/account-switch checks pass. The real two-Auth UI probe
and legacy-trade migration remain open; the first read failed as described above.

Beacon (migration 73, applied only on staging): voluntary donations spend 1–5000 owned Shell
Fragments, capped by the existing shared goal of 5000. The command seals current
Conclave membership and remaining capacity, then commits the exact debit,
project total and existing stage message together. Thresholds remain 500, 2000
and 5000; no personal reward, achievement reward, probability or code catalog
changes. A changed project or membership rolls the command back. The legacy
Altar mutation RPC is fenced for server-owned accounts. Two domain tests and the
existing Beacon-card test pass, including lost-response recovery and stale
account reads. SQL rollback passed in the full schema-73 drill; authenticated
Beacon UI proof passed in focused run 34481864223 as described above.


Partner lifecycle (migration 72, applied only on staging): invitations and acceptance use only
owned, available server dragons; starting seals both keepers and applies the
existing 96-hour duration minus 15 minutes per combined Expertise point, with a
24-hour minimum. A changed/ended event rejects the start atomically. Pending
invitations or accepted trips can be declined/cancelled before departure,
releasing both bindings without rewards. Shared reward contents, preview grant
behavior, odds and the private redeem-code catalog are unchanged. Reconciliation
of already-existing legacy partner invitations remains part of the migration
cutover work; this implementation currently creates new canonical pairs only.

Group lifecycle (migration 71, applied only on staging): membership, owned dragons, shared timing and the existing 70% Gold / 25% Dragon / 5% Mythical roll are sealed together. Actual four-keeper UI and recovery passed on schema 73. No event content, reward pool or probability changed.

Last verified: 10 September 2026

Ruleset: v0.05.29 / 10079 published; production remains at schema 65; current staging verification is recorded above. The next candidate adds Sunwake long-run validation and Academy input authority without changing this code catalog or its rewards. Canonical redemptions wait while a lesson is reserved.

<!-- reference-source-fingerprint: 2805485be0cc1c3b -->

The server command identity allowlist is shared with the durable client journal. A retried redemption retains its original request identity; receipt recovery during a mutation pause does not repeat a grant. This changes no code value, eligibility or catalog reward below.

This private operational ledger lists every active code. Active codes must
never be mentioned in public release notes, store copy, or public support
announcements unless the owner explicitly changes that rule.

The local server-domain candidate delegates redemption to the existing catalog
and checks keeper restrictions using the trusted authenticated owner. The code
values, rewards and restrictions are listed below. The end-event action uses its
dedicated authenticated RPC, not the dormant game-command grant path. A new personal event
replaces the previous event for that keeper, with same-event retries retaining
their existing expiry. Started attempts and adventures retain their provenance.
The dedicated event-stop and preview RPCs are live. The broader canonical grant
candidate remains dormant in production; it is not a public grant endpoint yet.

The device clock bridge preserves preview/dismissal instants when a legacy save
is uploaded for canonical migration. No code value, reward, eligibility or expiry
length is changed. Unresolved local timestamps cannot be silently interpreted by
the staging importer.

Codes are case-sensitive, use only `A-Z` and `0-9`, and unknown or retired
codes return the same inactive result. Seasonal previews are authorized by the
server rather than trusted from the public app catalog.

## Active codes

| Code | Reward | Reward ID | Restriction and behavior |
|---|---|---|---|
| `SUNWAKEEVENT` | **Sunwake Festival** | `sunwake_summer_sea` | Any authenticated, email-confirmed keeper; reusable 48-hour personal preview; ordinary permanent Trial rewards, simulated Adventure/Special Chest rewards and separate cosmetic test progress |
| `HARVESTMOONEVENT` | **Harvestmoon Festival** | `harvestmoon_moonlit_orchard` | Any authenticated, email-confirmed keeper; reusable 48-hour personal preview; ordinary permanent Trial rewards, simulated Adventure/Special Chest rewards and separate cosmetic test progress |
| `BDAYEVENT` | **A Wish on Golden Wings** | `golden_wings_birthday` | Any authenticated, email-confirmed keeper; reusable 48-hour personal preview with Wishcake Tower and Happy Birthday music; ordinary permanent Trial rewards, simulated Adventure/Special Chest rewards |
| `ENDEVENT` | **End own active event** | `end_active_event` | Any authenticated, email-confirmed keeper; removes own previews and dismisses current calendar occurrences until their scheduled end; repeatable, no items granted |
| `HALLOWEENEVENT` | **Night of the Witchlight** | `halloween_witchlight` | Any authenticated, email-confirmed keeper; 48-hour reusable personal preview; isolated test ranking; normal permanent Trial rewards, simulated Adventure/Special Chest rewards |
| `CHRISTMASEVENT` | **A Star for the Winter Hearth** | `christmas_winter_hearth` | Any authenticated keeper with a confirmed email; 48-hour reusable personal preview; isolated test ranking; normal permanent Trial rewards, simulated Adventure/Special Chest rewards |
| `NEWYEARSEVENT` | **When the New Dawn Rings** | `new_year_first_dawn` | Any authenticated keeper with a confirmed email; 48-hour reusable personal preview; isolated test ranking; normal permanent Trial rewards, simulated Adventure/Special Chest rewards |
| `VALENTINEEVENT` | **Where Two Heartlights Meet** | `valentine_two_heartlights` | Any authenticated keeper with a confirmed email; 48-hour reusable personal preview; isolated test ranking; normal permanent Trial rewards, simulated Adventure/Special Chest rewards |
| `PRIDEFESTEVENT` | **The Haven of Every Color** | `pride_every_color` | Any authenticated keeper with a confirmed email; 48-hour reusable personal preview; isolated test ranking; normal permanent Trial rewards, simulated Adventure/Special Chest rewards |

## Ending an active event

`end_my_seasonal_event` accepts `ENDEVENT`, checks the verified authenticated
owner and takes the same per-owner transaction lock as preview activation.
It deletes only that owner's preview activation and records current official
calendar editions (including Golden Wings, Sunwake and Harvestmoon) in `seasonal_event_dismissals` until
their original ending. These rows are private; there are no direct client table
read/write grants. `list_my_seasonal_event_dismissals` returns only the owner.
The app persists and refreshes these stops across sessions/devices, removes
unstarted event offers, restores the ordinary theme/music/launcher schedule,
and retains future annual editions. The normal Android launcher refresh is
deferred until leaving the foreground. Explicitly starting a new preview is
still allowed. Already started trials/adventures, scores and rewards survive.
No other player's event is stopped. Offline failure does not clear local state.

## Security and lifecycle

- The app catalog is for discovery and UI only; it is not access control.
- `redeem_seasonal_event_preview` requires an authenticated, email-confirmed
  account and maps each code to one fixed event. All eight event mappings are available
  to every verified keeper; migration 62 removes the former single-account gate.
- A code can be reused only after its previous entitlement expires.
- Repeating an active code returns the original expiry, without extending its
  48-hour window or changing its test ranking key.
- Preview scores use a preview occurrence key and never affect live rankings.
- Test event Trials grant their ordinary permanent rewards and keep personal
  bests. Production test Adventures and their Special Chests still display
  rewards without persisting them; staging can enable those for persistence tests.
- The 8 September 2026 change does not alter code access or entitlement length.
  Halloween's stored test scores are analyzed for 8–22 September separately from
  live rankings (`tool/halloween_trial_calibration_report.sql`).
- Removing a definition from both the app catalog and server mapping retires
  the code without removing legitimate earlier rewards.

## Maintenance contract

The client catalog lives in `lib/models/redeem_code.dart`; server authorization
lives in the immutable base migration 40 and the current forward overrides
`supabase/migrations/202609080059_single_active_event_preview.sql` and
`supabase/migrations/202609090060_end_active_event.sql`. Adding,
removing, redirecting, restricting, or changing a code must update both sources
and this document in the same change.

After review, run:

```text
dart run tool/reference_documentation_guard.dart --update
dart run tool/reference_documentation_guard.dart --verify
flutter test test/reference_documentation_test.dart
```

## 9 September 2026 access update

All previously account-restricted catalog codes now work for every verified
keeper. The app catalog and event metadata agree with forward migration 62.
Activation still affects only the authenticated account, uses one active preview,
retains the existing 48-hour retry expiry and keeps preview ranking provenance.
Anonymous/unverified requests and unknown codes remain rejected. No reward
contents or permanence rules changed. Operational values stay out of release notes.

## Birthday extension

The birthday preview uses the same owner lock, single-active-preview rule and
48-hour retry expiry as the other seven. It grants no item merely for redeeming.
Migration 63 introduced the birthday override;
`supabase/migrations/202609090064_sunwake_harvestmoon.sql` now extends it with the two new events. Calendar dates remain 1–2 September 2026, then 13 May yearly
from 2027 (Europe/Amsterdam). The code and its announcement stay out of release notes.

The new event codes use the same verified-account, retry-expiry, replacement,
end-event and privacy rules. Sunwake/Harvestmoon definitions are version 1 with
300 coins, 12 gems and a guaranteed own-family egg per Special Chest; production
previews display those Adventure/Chest rewards without granting them. Code
values and announcements remain absent from public release notes.

Review 10 September 2026 (verified Trial candidate): the redeem catalog, account
availability, event-preview activation and rewards are unchanged. The canonical
Trial screen now replays bounded inputs before granting the existing ordinary
Trial rewards during a preview; preview Special Adventure/Chest exclusions stay
as documented. No redeem information is added to public release notes.

Social-reservation integration review (10 September 2026): the command evaluator
uses separately verified dragon reservations before executing an action.
No active code, entitlement, reward content or quantity changed in this step.
