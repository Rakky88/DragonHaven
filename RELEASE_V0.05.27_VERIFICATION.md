# v0.05.27 / Android 10077 verification

Published 9 September 2026 at 15:50:50 UTC as the verified public latest
release, v0.05.27 / Android 10077.

The user approved the twelve Solmanta/Ciderhorn sprites, the complete festival
contract, and publication. Sunwake and Harvestmoon include their own calendar,
Special Adventure, versioned chest/egg, six dragon forms, hatch achievement,
podium emotes, original music/effects, app/launcher theme and distinct Trial.
The shared Conclave decorations use verified completions without economic grants.
Christmas S+ is 7,500; birthday S+ is 10,000 with one miss ending each run.
The starter egg hatching screen no longer offers the Egg Altar shortcut.

## Completed checks

- Full local regression: **738 tests passed**, Flutter analysis: **no issues**.
- Reference documentation verification and all six reference tests passed;
  dormant chest catalog v3 exactly matches its SQL source.
- Shared Dart/JavaScript parity passed; **21 Deno worker tests passed**.
- Both new games fit 320x640 at normal and 1.35 text scale/reduced motion.
  Surf collision outcomes match 30/60/120 FPS; twenty seeds remain navigable.
  Orchard rotation, bounds, complete-row harvesting and three-basket stopping
  pass; birthday ends on the first miss.
- Full new-event Adventure-to-Chest-to-Egg-to-Hatch tests pass, including expiry,
  once-only rewards, 24-hour minimum, exact chest contents and achievements.
  Spectral hatchlings now count toward seasonal hatch achievements too.
- All sprite containment checks pass. The original catalog order and ordinary
  42-family drop pool remain intact; totals are 51 families, 40 achievements and
  161 emotes. Approved dragon art is copied without changing its bytes.
- Migrations 64 and 65 were independently rehearsed with rollback, applied and
  rechecked on staging. Eight event/canonical economy contracts and podium-chat
  validation pass; synthetic fixtures are rolled back.
- Production was upgraded from exactly 63 to 65 migrations. Mandatory preflight
  confirms 65 exact matches, lint 0 and Auth health/settings/application HTTP 200.
  Economy/game mutation switches remain off, push remains on, authority remains
  legacy and canonical state remains empty. No player inventory migration ran.

Artwork provenance: `future_event_art/dragon_families/sunwake_harvestmoon/`.
Original music source and PCM verification: `future_event_art/music/`.
Operational code values and announcements are excluded from public release notes.

## Publication and native verification

- Source commit: `bde5fc09c678b75de99970de852cfaa908842ed2`.
- Exact-commit release CI [34371375231](https://github.com/Rakky88/DragonHaven/actions/runs/34371375231)
  passed: 738 Flutter tests, clean analysis, mandatory production preflight,
  MIDI normalization/tests, native Kotlin jukebox tests and signed AAB.
- Exact-commit staging CI [34371378563](https://github.com/Rakky88/DragonHaven/actions/runs/34371378563)
  passed with the newly compiled shared worker deployed only to staging.
  Real Auth/Edge/Dart/Postgres probes cover replay, stale requests, purchases,
  chests, Altar, crafting, tags, hatching, rename, equipment, Adventures, houses
  and preferences. Synthetic accounts/commands were removed and staging game
  mutations disabled afterward; live saves and wallets were unchanged.
- The production APK uses `lib/main.dart`, the production Firebase/Supabase
  configuration, package `nl.dragonhaven.app`, version `0.05.27`, code `10077`.
  Signing certificate SHA-256:
  `477c5a5d7453384ca756265e77af97d5a002a907177ccd2d9065a9bec3414942`.
- Installed the exact production APK as an Android update. Original one-floor
  tower, 25 coins, 3 gems and English selection remain; About displays v0.05.27.
  All eight languages remain ordered by their visible names.
- Both Trial intros and gameplay were visually checked on native Android at
  1080x2400 and 320x640 logical pixels with animations disabled. Drag steering,
  fruit placement, scoring, compact controls and timer remain usable. Normal
  emulator dimensions and animation settings were restored afterward.
- Native home themes, all-expertise selection, event music lists and restoration
  were inspected. Both new original tracks produced active 44.1 kHz playback;
  removal returns the ordinary jukebox list without removing collected music.
  Android launcher aliases switch to the selected event when backgrounded.
- Both expanded Conclave decorations were visually inspected at 320x640 and
  1.35 text scale. The screenshot-only test harness lacks Material icon fonts;
  native Android icons were separately confirmed and are bundled correctly.
- Publisher read-only dry run and draft upload passed. The existing draft was
  published once; tag, commit, stable asset name, GitHub digest and byte count
  match the local APK. The permanent latest URL returns HTTP 200.
- Mandatory production preflight passed again immediately before and after
  publication: 65 matching migrations, lint 0, Auth health/settings/application
  HTTP 200. Economy/game activation remains disabled, push enabled, zero
  nonlegacy authorities and zero canonical shadow states.

Release: https://github.com/Rakky88/DragonHaven/releases/tag/v0.05.27

Version download: https://github.com/Rakky88/DragonHaven/releases/download/v0.05.27/DragonHaven.apk

Permanent download: https://github.com/Rakky88/DragonHaven/releases/latest/download/DragonHaven.apk

APK size: **627,719,094 bytes** (598.64 MiB).

APK SHA-256: `a1ed8e00d12783393aa0bf2e8ebceac44aae2f3cc75171b1b7c3541e4c6170ee`.

Evidence: `release/v0.05.27-artifact.json`,
`release/v0.05.27-remote-verification.json`, `release/summer-device-*.png`,
`release/summer-conclave-*.png`, and `release/v0.05.27-staging-ci/`.
Artwork was created with the built-in image generator; exact prompts, selected
sources and hashes are in `ART_PROMPTS.json` and `EVENT_ASSETS.json` under
`future_event_art/dragon_families/sunwake_harvestmoon/`. All twelve approved
family images retain their approved bytes; no placeholder artwork is shipped.
