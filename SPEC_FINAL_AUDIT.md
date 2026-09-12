# DragonHaven current release audit - v0.05.33 / 10083

All 939 Flutter tests pass and analysis is clean. Trial returns animate only
credited event points, including legacy and canonical paths. Meter end icons
no longer hide the liquid: the chest appears after the filling animation ends.
Compact friend rows reserve identical portrait space with and without frames.

Invitation preparation waits for ongoing social/cloud operations; revision
conflicts remain protected and are explained explicitly. Real staging Auth/RPC
tests confirm invitations work without the recipient having an active event
save or open client, and independent preview keys still share correct points.
All temporary probe accounts were removed. Production preflight is healthy
with 83 matching migrations and zero lint errors. The generated worker is
unchanged; no server deployment or authority changes are needed.

See [v0.05.33 verification](RELEASE_V0.05.33_VERIFICATION.md).

## Previous release audit - v0.05.32 / 10082

The event header now contains only the current event's 58dp themed glass meter.
Expiry, server end-event synchronization and switching/restarting previews remove
retired meters. Historical points and earned rewards remain stored, with late
claim eligibility still determined by the adventure completion time. Calendar
dismissals now persist and notify listeners immediately after synchronization.

Flutter analysis is clean. The final full suite passes all 933 tests at
concurrency two. Two school timing failures in an earlier heavily loaded run
also passed on independent rerun, without unrelated gameplay changes.
Event lifecycle, reduced motion and presentation checks pass.
Android emulator review covered Halloween, Valentine, existing-friend selection
and a 320dp viewport with 1.6 text scaling and reduced motion.

Production preflight: 83 matching migrations, zero database lint errors, and
Auth/settings/application health HTTP 200. The generated worker is byte-identical
to v0.05.31; no server deployment, schema or authority-switch change is needed.
See [v0.05.32 verification](RELEASE_V0.05.32_VERIFICATION.md).

## Previous release audit - v0.05.31 / 10081

Verified 12 September 2026: 932 Flutter tests, clean analysis and 27 Edge tests.
Staging and production are schema 83, each with 19 passing rollback-only server
contracts. Production preflight reports matching migrations, zero lint errors
and HTTP 200 for Auth health/settings and application health. Game and economy
authority switches remain disabled; no player was promoted.

Adventure event points arrive only on claim, including late claims for journeys
completed during an event. Legacy ready saves retain their existing credit.
Compact event bars use themed sprites, flying claim particles and reduced-motion
support. Valentine invitations select existing friends; independent preview
keys share progress correctly. All previous event dates and reward odds remain.

See [v0.05.31 verification](RELEASE_V0.05.31_VERIFICATION.md).

## Previous release audit - v0.05.30 / 10080


Verified 12 September 2026: 928 Flutter tests, clean analysis, 27 Edge tests,
MIDI checks and Android native tests pass. Staging and production are schema 82;
19 rollback-only server contracts pass in each environment. The production
preflight confirms matching migrations, zero lint errors and HTTP 200 for Auth
health/settings and application health. Economy/game/migration switches remain
disabled and no player account is promoted. The signed APK updates the existing
emulator installation while retaining Quietstar, one floor, 25 coins, 3 gems
and English. About shows v0.05.30.

Events use points from ordinary Adventures and Trials, not new seasonal
Adventures. Christmas is December 20?26 (7,000 points); Valentine is February
12?16 (10,000 points), both annually in Europe/Amsterdam. Server calendar
queries confirm the upcoming dates. Historical notes below describe earlier
states; the current release evidence takes precedence.

See [v0.05.30 verification](RELEASE_V0.05.30_VERIFICATION.md).

## Historical v0.00.09 — final specification audit

Audited against
`DragonHaven_Codex_Spec_With_Achievements_Rooms_Personalities_DayNight_Audio_Two_Sliders.md`
on 22 August 2026.

## Completed local scope

- fixed Common Starter Egg, independent 5% Spectral roll, immutable identity,
  exact 24-hour gate, live countdown and tap-for-hint interaction;
- Egg → Hatchling → Wyrmling → Ascended progression with three trained paths;
- 42-family 20/10/6/3/2/1 rarity distribution, 216 logical artworks, unseen
  silhouettes, separate Spectral collection and secret Sinister artwork;
- 24 hidden personality traits with incompatibilities and stable persistence;
- 800 Adventure definitions with duration/reward constraints and Sunday 12:00
  Europe/Amsterdam Group-instance timing;
- six chest tiers, stash, rewards, 27 returning-dragon tables, visits, damage,
  repairs, Dragon Wards and 48-hour Special/Sinister sources;
- 20 humorous bilingual achievements with unique badges and Common-family
  counters that exclude rarer families;
- Rooftop Nest, 20 buildable floors, eight distinct rooms, 200 purchasable
  sprites, data-driven movement/preferences/interactions and seven time phases;
- cinematic hatch/evolution/chest presentations, a persisted priority queue,
  oldest-first evolution reveals, spinning achievement reveals and Android
  music/SFX with two independent persistent switches;
- English default and complete authored text for all nine requested languages,
  including generated content, notifications and 300 dragon sayings;
- About/redeem/Ko-fi, permanent share/update link, white launcher/splash,
  improved topbar branding and robust scrolling/dismissal behaviour.
- a centered animated egg countdown, one uncategorized achievement list with
  persistent list/compact modes, 20 unique color badges with black locked
  silhouettes, and background-only achievement/evolution notifications.

## Intentionally requires external infrastructure

- authenticated friends, friend achievements, Tower visits, trades and account
  synchronization;
- real shared multiplayer Group Adventure participation;
- real-money Google Play gem packs and receipt validation.

Those operations are visibly unavailable instead of inventing fake users,
payments or cloud state. Their screens/data boundaries remain ready for a later
backend phase.

## Release gates

- no chore/task/leaderboard/battle save data or screens remain;
- automated bounds checks cover every dragon, furniture and chest sprite;
- compact 360×640 and 135% text-scale scroll/overflow regression is green;
- About pinned-handle scrolling and pull-to-dismiss regression is green;
- the Language sheet uses the same pinned-handle/pull-to-dismiss behavior and
  presents all visible language names alphabetically;
- release uses the permanent `nl.dragonhaven.app` ID and signing key.

## Event points verification

Test exact point tables, Amsterdam boundaries and recurrence, full day-one completion, late claims and duplicate prevention, independent partner claims, legacy-save compatibility, compact/tall UI, text scaling and reduced motion. Rehearse the new invitation migration in isolated staging before deployment.


Event/social polish (source only): migration 81 adds original-deadline invitation
expiry, creator cancellation of legacy Valentine test invites, raw score event
rankings with regular Trial scopes and a three-day results window, and Conclave
message receipts. Chat refresh/send lanes are independent, reconnect on resume,
preserve messages on read failure and discard stale responses. Existing Tower
floors can change room type for free, including all 20 floors; residents, damage
and saved furniture layouts are preserved. Title Chests cost 500 coins; Inventory
starts with Chests followed by Eggs. Isolated PostgreSQL and client regression
checks cover the changed behavior. Production deployment completed on 12 September 2026 as part of schema 82.

## Release v0.05.30 preparation ? 12 September 2026

After a 30-minute unchanged code/database observation, the annual point-event
calendar was extended: Christmas December 20?26 (7,000 points), Valentine
February 12?16 (10,000 points). Both close at Amsterdam midnight on the
following day. These are event progress bars, not new Special Adventures.
Migration 82 aligns the server calendar. First-year and recurring boundary,
point target, and claim-threshold regressions cover both events. Staging and production rollout, boundary tests and server preflight passed.
Publication verification is recorded in the release evidence.
