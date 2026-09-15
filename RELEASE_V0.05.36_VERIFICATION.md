# v0.05.36 / 10086 verification

This hotfix starts from published v0.05.35 (d8e6dc8), with the Trial point-flight
correction backported from a6976c1. Completing an offer removes its card before
returning from the result route. The flight now uses the surviving Navigator;
the canonical screen also checks the original account and session epoch.
Points and rewards are unchanged. No server-economy cutover changes are included.

## Validation

- Clean Flutter analysis. Full suite: 949 passed, one existing optional archive
  review skipped. The first run exposed missing sparse-checkout test fixtures,
  Windows SQL line endings, stale version assertions and a busy-run timeout;
  after restoring fixtures, normalizing local line endings and updating version
  assertions, the complete suite passed with concurrency two.
- Three real AdventureHub regression tests complete the ordinary Trials at C,
  verify five points and card removal, then verify one return flight without
  duplicate credit. Compact 320dp, enlarged text and reduced-motion checks pass.
- About, updater and package version: v0.05.36 / 10086. Alphabetical language
  presentation and the language-selection widget checks pass.
- The living event reference and source fingerprint are synchronized. The audit
  records the limited hotfix and separately unfinished server transition.
- Production preflight: 83 matching migrations, zero lint errors, public Auth,
  settings and application health HTTP 200 at 20:10:12 UTC on 13 September 2026.
  No database migration, worker deployment or runtime activation was performed.
  Repeated immediately before publication at 20:38:53 UTC with the same healthy
  result (83 matching migrations, zero lint errors, all three HTTP 200).
- All 65 public release-note files checked for private operational codes and
  code announcements. Publisher dry run passed: no existing release/asset.

## Artifact

Package `nl.dragonhaven.app`, version `0.05.36`, build `10086`.
Size: **572826231 bytes**, identical to the previous APK size.
SHA-256: `b53950f3bc51dbea51968e7abf327fb63884120ccd2f3ddb9ff0be52062af99a`.
Signing certificate: `477c5a5d7453384ca756265e77af97d5a002a907177ccd2d9065a9bec3414942`.

All 1218 packaged game assets match the verified v0.05.35 APK byte for byte.
The same arm64-v8a, armeabi-v7a and x86_64 ABIs are present.

Android integration on emulator-5554 passed all four checks: real return flights
for Cavern Flight, Ruin Breaker and Runeweaver, plus compact 320dp/enlarged text/
reduced motion. The signed release installed successfully over v0.05.35 and
Android reports version 0.05.36 / 10086. The saved English Tower still shows
25 coins, 3 gems and one floor. The emulator's System UI crashed during further
screen inspection. A cold headless restart without wiping data completed the
visual review: the captured Android frame shows the themed flying sprites and
`+5` below the active meter after the completed offer disappears. The compact
reduced-motion check also passed again. The review uses an isolated debug
package; its temporary harness and package suffix are not in the release APK.

## Publication

Published and independently verified at **20:45:59 UTC on 13 September 2026**.
Tag source: `889f76711ae6a1b7adac9ecffae3b088b0cbd20f`.
The publisher dry run and publication succeeded. GitHub latest resolves to
v0.05.36; asset size and GitHub SHA-256 match the local signed APK. The permanent
download responds HTTP 200 with the expected content length.

Production postflight at **20:46:03 UTC** passed again: 83 matching migrations,
zero database lint errors, Auth/settings/application health all HTTP 200.
No production database, worker or runtime switch was changed for this release.

[Release](https://github.com/Rakky88/DragonHaven/releases/tag/v0.05.36)
[Version APK](https://github.com/Rakky88/DragonHaven/releases/download/v0.05.36/DragonHaven.apk)
[Permanent APK](https://github.com/Rakky88/DragonHaven/releases/latest/download/DragonHaven.apk)
