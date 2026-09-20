# Release 0.05.40 / 10090 verification

Based on published 0.05.39. Shared expertise formulas and removal of all seasonal
score/action ceilings; Birthday is endless with one-miss completion. Detailed
rules: TRIAL_EXPERTISE.md. Authority cutover remains dormant and out of scope.

- Full Flutter suite: 983 passed, one existing opt-in skip, two failures corrected
  (original UTF-8 phrase encoding and migration-version expectation). The entire
  six affected/version/reference test files then passed: 100/100, resolving both.
- Dedicated tests cover formula boundaries, 90.6-second Valentine/Pride play
  beyond 20,000 points and 200 actions, and 6,000 Birthday layers with repeated
  bounded checkpoint restore and one-miss termination.
- Native/JavaScript model parity passed, bundle 1,238,078 bytes.
- Staging migration-87 rehearsal passed all four rollback contracts: shared
  expertise, six uncapped seasonal scores/endless Birthday, endless New Year,
  and canonical event points. Authority flags and real player data unchanged.
- The separate account repair is backed up with private encrypted evidence;
  no player snapshots, tokens or identifying data are committed. Physical phone
  tag/untag succeeds; pending operation cleared; repaired scores and inventory
  confirmed in the new cloud revision.

## Final validation

- Dart analysis: no issues. Full suite plus the corrected files resolves to
  985 passing tests and one existing opt-in skip. Final reference guard and all
  five reference/release-note tests passed.
- Trusted worker compiled and Deno checked, not deployed. Protocol 2, bundle
  1,217,545 bytes; shared ruleset SHA-256
  `35a507ed63180c4c526d09f3caef17745c9602a8a3346c8783409c1bb9b4e57e`.
- Native Birthday reviewed at 411 dp and 320 dp with 1.3 text size and reduced
  animation. No timer, correct one-miss indicator, full title and readable
  intro; tapping the title area placed a layer. No Flutter overflow or
  exception in review logs. Emulator settings restored afterward.
- Signed production update installed on the connected OnePlus, preserving
  account data. Version 0.05.40 / 10090, non-debuggable. Game opened normally;
  active egg incubation and its countdown were visible after installation.

## Server rollout

- Staging: [35509372853](https://github.com/Rakky88/DragonHaven/actions/runs/35509372853).
- Production: [35509481517](https://github.com/Rakky88/DragonHaven/actions/runs/35509481517).
- Exact migration 87 applied; all 87 local/remote migrations match. All four
  contracts passed before and after; synthetic changes rolled back. Dormant
  authority flags and real player data unchanged by the migration.
- Mandatory `tool/release_server_preflight.ps1` passed in production: zero
  database lint errors; Auth health/settings and app health HTTP 200. Contract
  version 1; observed clock skew 1,010 ms at 12:04:05 UTC.

## Artifact

- `nl.dragonhaven.app`, version 0.05.40, build 10090; stable asset DragonHaven.apk.
- 574,261,743 bytes (547.66 MiB), all three existing Android ABIs preserved.
- SHA-256 `8bbe6f540d9abe7e52d33e24717d18324f1b2f9b2bfcfe829cf7bdf373da69ad`.
- APK signature verifies with the existing release certificate
  `477c5a5d7453384ca756265e77af97d5a002a907177ccd2d9065a9bec3414942`.
- Publisher dry run passed; no existing v0.05.40 release or asset.
- Publication verification will be appended after upload.

