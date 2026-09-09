# v0.05.28 / Android 10078 verification

Published 9 September 2026 at 16:38:17 UTC as the verified public latest
release, v0.05.28 / Android 10078. Publication was authorized by the user.

This release improves Sunwake Surf steering and starting speed, plus Moonlit
Orchard full-shape previews and animated row collapse. No database migration,
reward-table change or server-economy activation is included.

Before the version bump, all 47 targeted controls/gameplay/layout/event/reference
tests passed and analysis was clean. Actual Android preview interactions confirm
that steering requires grabbing the dragon, outside taps do not reposition it,
and Harvestmoon previews all four cells of a multi-fruit shape. Compact layouts,
intermediate/final row positions and reduced motion were visually checked.

## Local release checks completed

- 73 release/version/widget/reference tests passed after the version bump.
- Production preflight: 65 matching migrations, database lint 0, public Auth
  health/settings and application health HTTP 200. Economy and game mutations
  remain disabled, push enabled, zero nonlegacy authorities/canonical states.
- Production APK built from `lib/main.dart` on commit
  `5aa9c27441e756a8fd632d45b71f4946655dabad`, using production Firebase/Supabase.
- Package `nl.dragonhaven.app`, version `0.05.28`, Android code `10078`.
  The existing release certificate matches:
  `477c5a5d7453384ca756265e77af97d5a002a907177ccd2d9065a9bec3414942`.
- The final Flutter copy failed because the local disk filled. The complete
  Gradle-produced signed APK was recovered directly and independently verified
  with aapt and apksigner. The incomplete temporary copy was not used or uploaded.
  Local build storage needs attention before another large build.
- The exact production APK installed successfully over the previous emulator
  build. Quietstar, one floor, 25 coins, 3 gems and English remain. About shows
  v0.05.28; the eight languages remain alphabetized by their visible names.
- Publisher read-only dry run succeeded with no existing release or asset.

## Publication verification

- Exact-commit release CI [34376773439](https://github.com/Rakky88/DragonHaven/actions/runs/34376773439)
  passed: **744 tests**, clean analysis, production server preflight, MIDI
  normalization/tests, native Kotlin jukebox tests and a signed AAB.
- One draft was uploaded and verified before being published. Release tag,
  target commit, stable asset name, byte size and GitHub SHA-256 match the
  locally verified production APK. Latest resolves to v0.05.28 and the permanent
  download URL returns HTTP 200 with the correct content length.
- Mandatory production preflight passed again immediately before and after
  publication: 65 matching migrations, lint 0, Auth health/settings/application
  HTTP 200. Read-only guards confirm economy/game mutation switches remain off,
  push on, zero nonlegacy authorities and zero canonical shadow states.
- Audit documentation records the final shipped behavior and completed evidence.

Release: https://github.com/Rakky88/DragonHaven/releases/tag/v0.05.28

Version download: https://github.com/Rakky88/DragonHaven/releases/download/v0.05.28/DragonHaven.apk

Permanent download: https://github.com/Rakky88/DragonHaven/releases/latest/download/DragonHaven.apk

APK size: **627,719,018 bytes** (598.64 MiB).

APK SHA-256: `d3c4e79d4c9e17be1c89ed0ffe671e77b91f252dc48f9a26d78855674c4e57cb`.

Evidence: `release/v0.05.28-artifact.json`,
`release/v0.05.28-remote-verification.json`, `release/release28-about-ready.png`,
`release/release28-home-ready.png`, `release/release28-languages.png`,
`release/summer-controls-visual/`, `release/summer-device-controls-*.png`,
`.tools/release28-ci.txt`, `.tools/release28-version-tests.txt`, and
`.tools/release28-postpublish-preflight.txt`/`release28-postpublish-guard.txt`.
