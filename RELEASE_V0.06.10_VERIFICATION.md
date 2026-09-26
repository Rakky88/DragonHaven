# DragonHaven v0.06.10 / 10103 verification

## Scope

This release adds three Expertise Trials, final-evolution Expertise gifts and
the restored tower-room behavior while keeping the server-authoritative
inventory responsive when a worker or mobile connection is slow. An identical
durable request can take over an abandoned lease after the worker response
budget, while rotating the lease token so a late worker cannot commit. The
client performs one bounded same-request retry, retains its gameplay root
across short connectivity and lifecycle changes, and keeps confirmed inventory
visible while an exclusive operation is awaiting confirmation.

## Validation

- Release source and tag: `30cf76fcb24965af1e789650b16a77d626db020f`.
  The public `v0.06.10` tag points to that exact commit.
- Version, updater and startup checks target `0.06.10` / build `10103`.
- Flutter analysis reports zero issues. The complete Flutter suite passes with
  1,233 tests and one expected skip; the native Android unit tests pass.
- The worker typecheck and all 35 worker tests pass. The isolated migration
  contract and all 14 rollout-helper tests pass.
- Focused engine tests prove that returning or hatching a rarity-revealed egg
  leaves a reloadable canonical save. The Mastery rotation suite proves all
  three specialist Trials can be generated from restored Mastery dragons. It
  also verifies the two-stage focus/variant draw, classic any-dragon access and
  unlocks from owned specialists that are currently on an Adventure.
- Scheduler integration tests prove an overdue Trial board issues one silent
  durable refresh, and that a refresh held behind an active Trial runs exactly
  once when the attempt ends. The timer itself targets the next quarter-hour
  independently from the slower Adventure schedules.
- The signed production APK is non-debuggable, retains all three supported
  Android ABIs and uses the established signing certificate. Its embedded
  application/version metadata and all three AdMob identifiers match the
  release configuration. The physical handset disconnected before the
  non-destructive `adb install -r` update could run; no different device was
  substituted and no app data was cleared.

## Server boundary

- Migration 098 updates only the internal canonical lease primitive. Social and
  trade reservation wrappers remain intact, existing receipts stay replayable,
  and stale workers remain fenced by their rotated lease token.
- Migration 099 removes only stale egg-rarity display markers, advances the
  affected canonical revision and rebuilds its hash and social projection. Its
  staging rehearsal and production repair completed with no wallet or inventory
  rollback; the recovered device subsequently completed normal commands.
- The worker uses one 7.5-second upstream response budget. Production keeps the
  compatible minimum client build at `10102` so v0.06.09 remains usable.
- The final ruleset passed its staging rehearsal against all 99 migrations,
  zero database-lint errors, healthy Auth/application endpoints and the
  authenticated initialization/replay/server-authority smoke. Evidence is in
  `.tools/release71/staging-v0610-final-3`; its ruleset SHA-256 is
  `85b703e4544de72ed6e15fb071805f82048d932296fee212096d6c50aa18545d`.
- The production rollout ran only after the public APK existed and passed the
  same migration, lint, health, authenticated replay and authority checks.
  Evidence is in `.tools/release71/production-v0610-final-2`. Function version
  14 serves the final ruleset while the compatible minimum remains `10102`.

## Rewarded ads

- The rewarded-ad SSV function is active as version 15 from the tagged source.
  Its bundle SHA-256 is
  `cb82503f869b82d1c3e1a0d0d9315ca7598a4d710f04dfd91ba80cd5096acdda`.
- Runtime issuance is enabled for the approved Android AdMob app and the
  separate Gems and Coins rewarded units. The server grants 15 Gems or 150
  Coins, permits three completed rewards per currency per UTC day and gives an
  issued claim a 15-minute lifetime. All 20 signature/replay/issuance tests and
  the function typecheck pass. Activation snapshots are stored in
  `.tools/release71/rewarded-runtime-before-v0610.json` and
  `.tools/release71/rewarded-runtime-after-v0610.json`.
- A genuine watched-ad callback was not fabricated during release validation;
  it remains an on-device production smoke after the physical handset is
  connected again.

## Artifact and publication

- Package: `nl.dragonhaven.app`, version `0.06.10`, build `10103`.
- Signed APK: `release/DragonHaven.apk`, 582,089,071 bytes, SHA-256
  `4e93c34efcda09fd5e17065f04fb65c449cf57f0fb8c1b0f5be4ad0727943888`.
  Signing-certificate SHA-256:
  `477c5a5d7453384ca756265e77af97d5a002a907177ccd2d9065a9bec3414942`.
- GitHub Release: `https://github.com/Rakky88/DragonHaven/releases/tag/v0.06.10`.
  The release is public, is neither a draft nor a prerelease and is GitHub's
  latest release. The tagged asset size and digest equal the local artifact;
  both the versioned and permanent latest-download URLs return HTTP 200.
- Versioned download:
  `https://github.com/Rakky88/DragonHaven/releases/download/v0.06.10/DragonHaven.apk`.
  Permanent latest download:
  `https://github.com/Rakky88/DragonHaven/releases/latest/download/DragonHaven.apk`.
- The Android release workflow completed successfully from the tagged source,
  including its independent server/SSV checks, analysis, full Flutter suite,
  signed Play Store bundle, native jukebox cycle and artifact verification:
  `https://github.com/Rakky88/DragonHaven/actions/runs/36275584345`.
