# v0.05.35 / 10085 verification

This release reduces the universal APK without changing artwork pixels,
dimensions, transparency, music or sound data. Of 1220 investigated images, 845
have a smaller encoding accepted by both Pillow and Flutter's renderer. Twelve
superseded dragon sprites and three art-prompt documents leave the runtime bundle.
The provenance manifest preserves exact source/runtime hashes and source history.

## Validation

- All 946 Flutter tests pass; analysis is clean. The optional archive-dependent
  pixel review was run separately for all 845 applied images and found no changes.
- Dynamic artwork catalogs resolve to bundled files; hashes match the reviewed
  manifest. Retired files and source archives are absent from the asset manifest.
- The Altar regression test preserves its existing dimension/transparency checks
  while accepting the reviewed PNG and WebP formats.
- The living reference documentation guard and its test pass. Rewards, schedules,
  event point rules, player saves and server authority are unchanged.
- Android emulator artwork review covers dragons, event backgrounds, chests,
  Altar materials/relics and school sprites using the actual runtime catalog paths.
- The signed production APK installs over the existing app. About displays
  v0.05.35; the saved English language, 25 coins, 3 gems and one tower floor remain.
- All 64 public release-note files are free of private operational codes and
  announcements of those codes.
- Production preflight passes: 83 matching migrations, zero lint errors,
  Auth health/settings and application health HTTP 200. No server deployment or
  database mutation is performed.

## Artifact and publication

Package `nl.dragonhaven.app`, version `0.05.35`, build `10085`.
Size: **572826231 bytes**, down **55433883 bytes (8.8234%)** from v0.05.34.
SHA-256: `ee31e4e7a0e89d4ae61b9f1b0816ff6284600ce1deb7d7075272085726b95044`.
Existing signing certificate verified:
`477c5a5d7453384ca756265e77af97d5a002a907177ccd2d9065a9bec3414942`.

The final ZIP contains the reviewed runtime bytes and excludes every retired
asset, prompt document and source archive. All 145 native audio resources match
the baseline bytes. The three ABI libraries remain: arm64-v8a, armeabi-v7a, x86_64.

Publication verified on 13 September 2026 at 11:59:55 UTC. GitHub latest resolves
to v0.05.35; remote asset size and SHA-256 match the signed local file. The
permanent download returns HTTP 200 with the expected content length.
Tag source: `d8e6dc8f8645bf57ac621c0ac5c5ad6a0dd02f23`.

The publisher dry run passed. Windows PowerShell encountered its documented
ShouldProcess failure before mutation. Release and tag state were checked again;
the checksum-verified official portable GitHub CLI completed the publication
with the permanent `DragonHaven.apk` filename.

[Release](https://github.com/Rakky88/DragonHaven/releases/tag/v0.05.35)
[Version APK](https://github.com/Rakky88/DragonHaven/releases/download/v0.05.35/DragonHaven.apk)
[Permanent APK](https://github.com/Rakky88/DragonHaven/releases/latest/download/DragonHaven.apk)
