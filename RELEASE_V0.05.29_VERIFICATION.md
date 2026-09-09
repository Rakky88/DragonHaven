# v0.05.29 / Android 10079 verification

Published on 9 September 2026 at 19:52:56 UTC as the verified public latest
release, v0.05.29 / Android 10079. Publication was authorized by the user.

Harvestmoon centers the full shape footprint on the thumb for board touches and
tray dragging. The small floating duplicate is removed. Preview and placement
share the same snapped anchor, including clipped edge rejection.
Sunwake reef width is .25-.025*normalized Might, retaining the .026 dragon radius.
The .42 starting speed rises smoothly to about 1.34 at 75 seconds, capped at 1.4;
gate intervals ease from 1.05 to .56 seconds. Steering remains capped at 1.65
arena widths per second. Rewards, cutoffs, probabilities and server contracts
are unchanged. No database migration or economy activation is included.

The 27 targeted controls, gameplay, layout and release-version checks pass.
They cover centered previews, no extra moving miniature, exact release placement,
both clipped edges, cancelled touches, row collapse, reduced motion, collision
boundaries, Might assistance, continuous acceleration and twenty navigable seeds.

An additional 67 widget/version/reference checks pass. Eleven visual checks
exercise the actual controls and full Trial screens, including 320x640 layouts,
large text, invalid edges, falling rows and reduced motion. Android emulator
review confirms the four-fruit preview, centered tray dragging without the
floating miniature, native rotate icon, and Sunwake grab-and-drag steering.
Moving into coral also reaches the three-collision game-over screen.

## Release checks completed

- Exact-source CI [34395101050](https://github.com/Rakky88/DragonHaven/actions/runs/34395101050)
  passed: **746 tests**, clean analysis, production preflight, MIDI checks,
  native Kotlin jukebox tests and a signed AAB.
- Production APK built successfully from `lib/main.dart` on commit
  `2b83228407aec1416a6508d7a03fe2a341630e3a`, using production Firebase/Supabase.
  The private nonpersistent visual-preview APK was not published.
- Package `nl.dragonhaven.app`, version `0.05.29`, Android code `10079`.
  The existing release certificate matches:
  `477c5a5d7453384ca756265e77af97d5a002a907177ccd2d9065a9bec3414942`.
- The exact production APK installed over the existing emulator app. Quietstar,
  one floor, 25 coins, 3 gems and saved English selection remain. About shows
  v0.05.29; all eight language names remain alphabetized.
- Read-only publisher dry run passed. One draft was uploaded, verified and then
  published. The release tag, source commit, stable asset name, byte size and
  GitHub SHA-256 match. Latest resolves to this version and the permanent
  download returns HTTP 200 with the correct content length.
- Production preflight passed before and after publication: 65 matching
  migrations, lint 0 and Auth health/settings/application HTTP 200. Read-only
  guards confirm economy/game mutation switches off, push on, zero nonlegacy
  authorities and zero canonical shadow states. No database or worker deploy.
- Local storage pressure from the previous release was relieved with NTFS
  compression of generated Flutter caches, saving about 3.47 GB without file
  content changes. Both preview and production builds completed normally.
  This changes local build storage only, not APK size or asset quality.
- The Android 17 emulator framework restarted during preview installation;
  recovery restored local ADB and both native review and the production update
  subsequently completed successfully without clearing saved app data.

Release: https://github.com/Rakky88/DragonHaven/releases/tag/v0.05.29

Version download: https://github.com/Rakky88/DragonHaven/releases/download/v0.05.29/DragonHaven.apk

Permanent download: https://github.com/Rakky88/DragonHaven/releases/latest/download/DragonHaven.apk

APK size: **627,719,026 bytes** (598.64 MiB).

APK SHA-256: `1cd3181847e097542a182119f894576fa338d8d566765f8232b13a775fc864ae`.

Evidence: `release/v0.05.29-artifact.json`,
`release/v0.05.29-remote-verification.json`, `release/release29-about-ready.png`,
`release/release29-home-ready.png`, `release/release29-languages.png`,
`release/release29-harvest-centred-held.png`, `release/release29-harvest-placed.png`,
`release/release29-sunwake-steering.png`, `release/release29-visual/`,
`.tools/release29-ci.txt`, `.tools/release29-controls-recheck.txt`,
`.tools/release29-version-reference.txt`, `.tools/release29-visual.txt`,
`.tools/release29-postpublish-preflight.txt` and
`.tools/release29-postpublish-guard.txt`.
