# DragonHaven v0.05.22 verification

Release source: `0a736c9075d3e3d06cf54ad35882d32509fe68d7`.
Status: published and verified. Updated 8 September 2026.

## Artifact

- Production target: `lib/main.dart`, production Firebase configuration.
- Display/manifest version: **0.05.22**; Android version code **10072**.
- Package: `nl.dragonhaven.app`; stable public filename: `DragonHaven.apk`.
- Local artifact: `release/DragonHaven-v0.05.22.apk`.
- Size: **518292809 bytes**.
- SHA-256: `31b8cb06437394c0c9bcbbf50d0f2f03fd29c331b2e6e6bf40a7048983641de9`.
- Signing certificate SHA-256:
  `477c5a5d7453384ca756265e77af97d5a002a907177ccd2d9065a9bec3414942`.
- Publisher dry run passed: no existing release/asset collision.
- The separate nonpersistent visual preview APK was never selected for publication.

## Verification

- Local clean full suite passed 648 checks; its four stale version expectations
  were corrected, then all six release-service checks and the About widget passed.
  Final CI analysis and the full suite passed on the source above.
- Analysis clean. Fourteen Deno worker tests and VM/Deno domain parity passed.
  All 77 padded runtime sprites pass the bounds check. Reference documentation
  and catalog-v2 synchronization checks pass.
- Eleven event UI tests: six themes, compact/large-text layouts, details and
  both dragon pickers. See `EQUIPMENT_AND_EVENT_VERIFICATION.md` for gameplay
  evidence and exact built-in image-generation prompt manifests.
- Connected Android API 37 emulator: Gender is the third detail row, gallery
  has no gender badge, expertise sprites/text/scores are centered, Emberheart
  equips and appears on the dragon card. Checked 320dp width, 1.35 text scale
  and system animations disabled, then restored the original device settings.
- All six event palettes were exercised; the birthday background, logo and
  countdown were inspected after loading. Local captures are
  `release/release22-device-*.png`.
- Production APK installed as an update without uninstalling or clearing data.
  About displays v0.05.22; original dragon and 25 coins / 3 gems remain. The
  temporary preview dragon and relics are absent from the production save.
- Installed APK SHA-256 matches the local artifact exactly. Language options
  use their visible-name order; Dutch persisted through restart and the original
  English selection was restored. Default event branding resumed correctly.

## Server

- Migrations 58 (weighted equipment drops) and 59 (one active personal event)
  passed independent rollback contracts on registered staging before deployment.
  Applied staging run 34279886740 also passed six canonical contracts before
  and after deployment, lint and public health. Its subsequent UI test timed
  out; synthetic accounts were removed and the worker was disabled.
- Run 34280764287 confirmed purchase and opening but exposed real/fake clock
  mixing in the probe cleanup/animation. The test now creates Auth and performs
  network callbacks, reveal delays and cleanup on the real clock. Final repeat:
  [34281388567](https://github.com/Rakky88/DragonHaven/actions/runs/34281388567)
  **passed**: actual SDK/session/journal, real shop purchase and chest reveal,
  unchanged legacy save/wallet/authority, synthetic cleanup and disabled worker.
  Final staging health at **21:39:13 UTC**: schema 59, lint 0, all HTTP 200.
- Production was independently checked at exact schema 57, zero lint errors,
  healthy Auth, all legacy accounts, zero shadow states, game/economic mutations
  disabled and push enabled. Dry run contained only migrations 58 and 59.
- Applied exactly 58 and 59. Mandatory production preflight at **21:35:35 UTC**:
  exact schema **59**, lint **0**, Auth/settings/application **HTTP 200**.
  All authority/runtime/zero-shadow checks are unchanged after the migration.
- No production game worker or player-economy activation is included. Existing
  event runs retain their reward provenance. No live gameplay balances were
  edited for release testing.

## Release workflow

https://github.com/Rakky88/DragonHaven/actions/runs/34281504522

Analysis, all **652 tests**, production preflight, signed AAB and artifact upload
passed. AAB SHA-256: `d1e48ff5283b66ce00423f7e39ffc54ba2cb0345769a562f53b80834c1b3b521`.

## Publication

- [Release page](https://github.com/Rakky88/DragonHaven/releases/tag/v0.05.22)
- [Version APK](https://github.com/Rakky88/DragonHaven/releases/download/v0.05.22/DragonHaven.apk)
- [Permanent latest APK](https://github.com/Rakky88/DragonHaven/releases/latest/download/DragonHaven.apk)
- Latest release is v0.05.22. Public latest download responds HTTP 200.
- GitHub asset size and SHA-256 match the local and installed production APK.
- Post-publication mandatory preflight at **21:52:19 UTC** passed: exact schema 59, lint 0,
  Auth/settings/application HTTP 200. Full output remains in
  `release/release22-post-publication-preflight.txt`; runtime/authority checks
  still show legacy accounts, mutations off, zero shadow states and push on.
