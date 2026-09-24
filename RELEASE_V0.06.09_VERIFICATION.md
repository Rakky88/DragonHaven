# DragonHaven v0.06.09 / 10102 verification

## Scope

This release adds Spirit Alignment, Ruin Guard and Rune Orbit with independent
rankings. A new ordinary offer first chooses Arcana, Spirit or Might with equal
probability, or those three plus the event category with equal probability
during an event. Only after that category choice does an eligible account get
the equal classic/new-game choice. The added game requires a matching Ascended
specialist or an Ascended Mastery dragon, and the chosen dragon is checked by
the canonical server when the Trial starts, resumes and checkpoints.

Final evolution now grants +10 to the chosen expertise, or +5 to all three for
Mastery, exactly once and above the previous expertise budget. Tower room
clearing redistributes dragons and gives overflow dragons an exact fifteen
minute break. Decorating identifies furniture already used in another room,
and every bed uses the shared contained rendering bounds. Trial dismissal is
optimistic with server rollback, and the empty-Trials presentation restores
the established DragonHaven design.

## Validation

- Release source: `a6e04cac2d12386cdb0a4f25b3c01d596957723e`.
- Version, updater and startup checks target `0.06.09` / build `10102`.
- `flutter analyze --no-pub`: zero issues.
- Complete Flutter suite: 1,212 passed, one expected opt-in lossless-asset
  review skipped and zero failed.
- The focused feature review passed 88 evolution, Tower, Trial rotation,
  eligibility, geometry, ranking and rollback tests. All 12 canonical UI
  parity cases passed in isolation.
- Reference-document fingerprints were reviewed, updated and verified; all
  five reference-document tests passed and public release notes expose no
  redeem codes.
- The controlled rollout helper passed all 12 rollback, concurrency,
  postflight, version and dormant-staging tests. Its ordinary command, API and
  postflight failures restore the previous worker and runtime automatically.
- The generated gameplay worker uses protocol 2, is 1,291,402 bytes and has
  ruleset SHA-256
  `11b2268d2af75d7710051010a5f4c0ea0a0dbf375185a328f0ce8f5cb9e6199e`.
  Deno typechecking passed, all 31 worker core tests passed, and the native
  Dart/Deno domain-parity probe passed.
- Migration 097 passed its PGlite 0.5.8 rerun, backfill, ranking delegation,
  privilege and projection contract on Node 24.21.0.
- The signed APK installed as an update on the connected Android emulator.
  Android reports `0.06.09` / `10102`; the app opened its account screen and a
  clean relaunch produced no Android fatal exception.

## Server boundary

- Staging advanced from migration 93 to 97 and rehearsed migrations 94-97.
  It had zero canonical accounts before and after the rehearsal. Database lint,
  Auth health, settings and application health passed. An authenticated
  initialize/replay/read smoke test proved the new server authority and exact
  ruleset. Staging function version 51 is ACTIVE and public, while its runtime
  returned to `enabled=false`, `migration_enabled=false` and build `10102`.
- Production applied only additive migrations 96 and 97 while the previous
  worker kept serving. Migration parity is 97/97 with zero database lint
  errors. Auth health, Auth settings and application health returned HTTP 200
  before and after the worker rollout.
- The production gameplay worker is ACTIVE and public as function version 10.
  Its bundle SHA-256 is
  `64f8144836da6bed6e62989c2d517219f4c6eaa349333894cb2d31bdc3e0de73`.
  Runtime revision 3 is enabled for migration and gameplay, requires build
  `10102`, uses the exact ruleset above and keeps all three shadow switches
  disabled. The authenticated initialize/replay/read smoke test passed.
- The unchanged rewarded-ad SSV function was redeployed only to bind its
  provenance to the exact release source. Function version 13 is ACTIVE and
  public, reports source revision
  `a6e04cac2d12386cdb0a4f25b3c01d596957723e`, and retains bundle SHA-256
  `cb82503f869b82d1c3e1a0d0d9315ca7598a4d710f04dfd91ba80cd5096acdda`.
  Its typecheck and all 20 tests passed.
- The rewarded-ad runtime remains dormant with issuance disabled, daily limit
  3, rewards of 15 gems and 150 coins, a fifteen-minute claim lifetime and zero
  claims. Existing gameplay remains available while reward issuance is off.
- Two production apply attempts stopped before any mutation because the
  padded display version needed numeric comparison and the release tag was not
  yet fetched locally. The final protected transaction completed successfully;
  rollback was not required.

## Artifact and publication

- Package: `nl.dragonhaven.app`, version `0.06.09`, build `10102`, not
  debuggable.
- ABIs: `arm64-v8a`, `armeabi-v7a`, `x86_64`.
- Production rewarded-ad unit IDs are embedded and distinct.
- Signing certificate SHA-256:
  `477c5a5d7453384ca756265e77af97d5a002a907177ccd2d9065a9bec3414942`.
- APK size: 581,925,231 bytes.
- APK SHA-256:
  `f699b62ba567aed294a09784ed23f93ca5e7655a243a85e2fe60e71363b58374`.
- GitHub release ID: 395974359; asset ID: 586595111. GitHub reports the
  exact byte size and digest. A fresh permanent-link download produced the
  same byte size and SHA-256. The tag resolves to the exact release source,
  the release is latest, neither draft nor prerelease, and both download URLs
  returned HTTP 200 with the complete asset.
- Release page:
  https://github.com/Rakky88/DragonHaven/releases/tag/v0.06.09
- Versioned APK:
  https://github.com/Rakky88/DragonHaven/releases/download/v0.06.09/DragonHaven.apk
- Permanent latest APK:
  https://github.com/Rakky88/DragonHaven/releases/latest/download/DragonHaven.apk
- Tag-triggered Android release workflow:
  https://github.com/Rakky88/DragonHaven/actions/runs/36043616567
  completed successfully on the exact release commit. Server preflight,
  rewarded-ad deployment parity, Flutter analysis and tests, MIDI checks,
  native Android tests, signing and artifact verification all passed.
- The non-expired `DragonHaven-Play-Store` artifact has ID 10828881974,
  size 1,149,207,625 bytes and ZIP SHA-256
  `0cffa24204da125f62fc3489d019233ab670f4dbb5f6f07e0a55989daab8d044`.
  Its verified `DragonHaven.aab` has SHA-256
  `e89a6432f10ff9fc9a570c0d47446902b1b1365905f65b30185a51f2f6da24e6`
  and the expected production signing certificate.
