# Event theme and training improvements — 8 September 2026

Working change after v0.05.19 / Android 10069. This document records development
verification; it does not announce a new app release or a production economy
cutover. Production remains schema 56, staging schema 57.

## Delivered behavior

- All calendar events apply a shared app palette and decorated logo. Seasonal
  events reuse their existing illustrated backgrounds and emblems. The event
  banner shows the remaining days/hours/minutes/seconds on every main tab.
  Real events take precedence over personal previews. Expiry automatically
  restores the ordinary app appearance. Both clocks are local; no polling is
  added to the server.
- My Dragons details allow independent Might, Arcana and Spirit highlights.
  They persist with the dragon, appear in both expertise dialogs, and determine
  the **Highlighted for this path** section in both pickers. Combined-expertise
  paths match any highlighted expertise. Availability requirements still apply.
- Adventures and Trials have compact Draconomicon shortcuts. Opening and closing
  the codex retains the picker and does not choose or start with a dragon.
  Codex tabs and form counters now accommodate larger text.
- Test event Trials grant their ordinary permanent XP, balanced Expertise,
  chest and eligible S+ relic/emote rewards, record personal bests and count
  toward the daily constellation. An already-consumed offer cannot pay twice.
  Test Special Adventures, paired event journeys and their Special Chests keep
  their production preview exclusions. Live event rankings remain separate.
- Every egg has a fixed 50/50 male/female property. New eggs use a full uniform
  31-bit seed. Existing seeds and seedless legacy identities derive stable
  values without consuming another reward roll. Hatching, evolution, trades and
  restore preserve sex. Hatched dragons have compact labeled icons; public
  unknown-egg projections still omit private properties.
- New labels and the updated tutorial have English, Dutch, German, Spanish,
  French, Italian, Portuguese and Japanese text.

## Halloween calibration

The accepted test attempts were already persisted by the live seasonal RPC.
A read-only production check on 8 September at 17:40 UTC confirmed two accepted
attempts in the requested window. No new table, cron job, migration, entitlement
extension or paid service is necessary.

Run `tool/halloween_trial_calibration_report.sql` through the authenticated
database tooling. Its fixed window is **8 September 00:00 through 22 September
00:00 Europe/Amsterdam**. It reports all attempts, one best per keeper, daily
counts, score buckets and percentiles without exporting names, IDs or tokens.
Preview expiry does not delete stored attempts or bests. Account deletion keeps
its existing cascading deletion behavior. The report does not change grades or
award live podium prizes; review sample size and both score distributions before
choosing new cutoffs.

## Verification

- Five interaction tests cover event priority/expiry, all main destinations,
  independent highlights, both expertise dialogs, both codex round-trips and
  selection preservation at increased text size.
- Four identity tests cover balanced sex assignment, old trades, actual hatch
  and evolution, legacy normalization, unknown fields, persistence and fixed
  property integrity.
- The native Dart and compiled JavaScript outputs agree for all 109 synthetic
  identity fixtures, including seedless and Unicode identities.
- The shared server-game bundle compiles successfully: 940,751 bytes, ruleset
  SHA-256 `832020996f00f85e32cd5d8c261820376fd1432cd578adf02f93aba89bb4850e`.
  This build was not deployed.
- Local screenshots inspected: Tower, Shop, dragon details, Trial expertise,
  Trial picker and Adventure picker. Reproduce captures with
  `test/event_training_ui_test.dart`, optional `ALTAR_CAPTURE=1`,
  `ALTAR_CAPTURE_FONT` and `ALTAR_CAPTURE_ICONS`; files are written under
  `release/event-training-*.png`.
- Full analyzer is clean. All **621 Flutter tests pass** in the final complete
  run, including translations and living-reference checks. The Windows parallel
  test compiler stalled, so the completed run used `--concurrency=1` (3m29s).
- Production Auth health, Auth settings and application health returned **HTTP
  200** at **18:13:50 UTC on 8 September 2026**. This was a read-only check,
  not a release migration-parity preflight.

No production mutations, player migrations or companion-account cleanup were
performed by this feature change. The existing companion cleanup remains gated
on completion and real-player reward acknowledgement.
