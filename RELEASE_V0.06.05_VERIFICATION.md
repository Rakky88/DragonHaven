# DragonHaven v0.06.05 / 10098 verification

## Scope

This release restores the remaining v0.05.40 presentation details requested
after v0.06.04: the Rooftop Nest egg picker, direct Inventory Egg tagging,
selected-dragon actions, Adventure refresh countdowns, Tower alignment and
spacing, My Dragons sheet height and contained dragon artwork.

All gameplay data remains canonical. Egg tags, collection preferences and nest
placement use the existing optimistic command queue and roll back on refusal.
Adventure refresh uses the real offer boundary and confirmed server time.
Random outcomes, rewards, hidden Egg facts and hatching remain server-owned.

## Validation

- Full Flutter suite: 1,113 passed and 1 asset-review test skipped.
- Flutter analysis: no issues.
- Version, updater, localization and startup checks confirm `0.06.05` / build
  `10098`; reference-documentation checks and the reference guard passed.
- MIDI validation checked 75 tracks without adjustment; all 3 MIDI unit tests
  passed.
- Android native/jukebox tests completed successfully: 188 Gradle tasks, 11
  executed and 177 up-to-date.
- The signed release APK installed over the existing Android emulator app while
  preserving its install data, and cold-launched as version `0.06.05` / build
  `10098`.
- The changed authenticated UI was exercised from the same frozen source against
  the isolated synthetic review server at normal size and at 320 dp with 1.3x
  text and animations disabled. Adventure timers, Tower alignment, My Dragons,
  dragon art and actions, the Egg tile/list tag controls and details, and both
  Rooftop Nest picker views rendered without overflow.

## Server boundary

No migration, Edge Function, ruleset, runtime flag, minimum-build change or
player-data rewrite was required. Production migration parity, database lint,
Auth endpoints and application health were checked before and after release;
neither check mutated the server.

Both checks found 93 matching migrations, zero database lint errors, HTTP 200
from Auth health, Auth settings and `dragonhaven_public_health`, and application
contract version 1. The preflight measured 365 ms, 144 ms and 456 ms for those
three endpoints with 54 ms clock skew. The postflight measured 249 ms, 144 ms
and 348 ms with 43 ms clock skew.

Runtime inspection before and after publication confirmed server-owned gameplay
and migrations are enabled, the minimum supported build remains `10092`, legacy
mutations and all three shadow paths remain disabled, and the ruleset SHA-256 is
`4432796eae24875360ad26e979aba0fafae015d45cecd05b79a1b1698738ef57`.

## Artifact and publication

- Release source commit:
  `d3ae90d6089c60fa0e1141c6e1a553c480dd28fb`.
- Tag: `v0.06.05`; normal latest release, neither draft nor prerelease.
- GitHub release ID: `394465399`; asset ID: `583378225`.
- APK: `DragonHaven.apk`, package `nl.dragonhaven.app`, version `0.06.05`,
  build `10098`, 578,686,879 bytes.
- APK SHA-256:
  `5a9b7b49c9c2fc6edf17a98fc21c719ee952b07cdedffa2f1c9456da066ca025`.
- Signing certificate SHA-256:
  `477c5a5d7453384ca756265e77af97d5a002a907177ccd2d9065a9bec3414942`.
- Native ABIs: `arm64-v8a`, `armeabi-v7a`, `x86_64`; the APK is not
  debuggable.
- GitHub release, versioned APK and permanent latest-download endpoints all
  returned HTTP 200. GitHub's asset size and SHA-256 digest match the local
  artifact exactly.
- The tag-triggered [Android release workflow](https://github.com/Rakky88/DragonHaven/actions/runs/35839497390)
  completed its independent server, analysis, full-test, MIDI, signed Play AAB,
  native-jukebox and artifact-upload gates successfully in 15 minutes 21
  seconds.

Release page: https://github.com/Rakky88/DragonHaven/releases/tag/v0.06.05

Versioned APK: https://github.com/Rakky88/DragonHaven/releases/download/v0.06.05/DragonHaven.apk

Permanent latest APK: https://github.com/Rakky88/DragonHaven/releases/latest/download/DragonHaven.apk
