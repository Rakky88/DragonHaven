# Release v0.06.00 / 10093 verification

## Scope

Restores the illustrated server-owned Adventures, Tower, Inventory and My
Dragons UI; adds the logo shortcut to About. The previous release's server
contract, redaction, authority, migrations and durable command engine are
unchanged. The current branch also includes already committed launch-logo and
notification navigation fixes.

Video Chests are disabled previews by the owner's explicit choice. AdMob
onboarding, SDK/consent, signed callbacks and daily claim accounting are pending,
not claimed as operational. See REWARDED_CHESTS_SETUP.md.

## Checks

Production preflight at 2026-09-20 16:42:43 UTC: 92 matching migrations, zero
DB lint errors, Auth health/settings and application health HTTP 200, skew 9 ms.
Flutter analysis passes with no issues. The full suite exercised 1,047 tests
plus one existing optional skip: 1,041 initially passed. After updating the
old UI/version assertions and completing all six additional language tables,
the 85-test subset covering the six failures passed. The Academy visual test
also passes on recheck; its first run timed out under concurrent build load.
The documentation guard's transient review-manifest mismatch cleared after the
isolated emulator build restored the release manifest. Final targeted server
UI, shop preview and reference tests: **18 passed**. Final analysis: **no issues**.

An isolated emulator app uses synthetic server facts and the real canonical
UI/actions. Normal-size Adventures, Trials, Tower, Inventory, Altar, relics and
My Dragons screenshots were inspected. No player save was cleared. Compact
320 dp / 1.3 text scale / reduced motion Adventures, Tower, Inventory and About
were visually checked. Original emulator display/font/animation settings were
restored. The About logo opens the complete existing sheet with v0.06.00.

## Android artifact

- Package `nl.dragonhaven.app`, versionName `0.06.00`, versionCode `10093`.
- Non-debuggable, universal APK retaining arm64-v8a, armeabi-v7a and x86_64.
- Size: **577,720,199 bytes**.
- SHA-256: `3428d8f13920a548c7bd28f4a7db4c93366ff75b3b0ff88546ca2af43f94770d`.
- Verified release signer SHA-256:
  `477c5a5d7453384ca756265e77af97d5a002a907177ccd2d9065a9bec3414942`.
- Production build configuration and Firebase definitions retained.
- Publisher WhatIf passed: tag and asset did not exist, no replacement.
- Release source: `7e7578f6474f78fb036503f3e6a5021d24f1b351`.

## Server

Final mandatory preflight at **2026-09-20 16:59:34 UTC**: **92** matching
migrations, **0** lint errors, Auth health/settings and application health all
**HTTP 200**, clock skew **224 ms**. No migration, deployment, production player
mutation or authority-switch change was performed.

## Publication

Published and verified at **2026-09-20 17:08:13 UTC**.

- Release ID **392505341**, asset ID **577204510**.
- Tag `v0.06.00` resolves to the exact source commit above.
- GitHub asset size and SHA-256 match the local artifact exactly.
- Latest release resolves to `v0.06.00`.
- Release page, version APK and permanent latest APK all returned HTTP 200.
- The PowerShell publisher created the release but its upload connection closed
  without adding an asset. That upload process was cancelled, the empty release
  was queried again, and the official GitHub CLI attached the verified APK to
  that same release. No release/tag/asset was deleted or replaced.

[Release](https://github.com/Rakky88/DragonHaven/releases/tag/v0.06.00) |
[Version APK](https://github.com/Rakky88/DragonHaven/releases/download/v0.06.00/DragonHaven.apk) |
[Permanent APK](https://github.com/Rakky88/DragonHaven/releases/latest/download/DragonHaven.apk)

