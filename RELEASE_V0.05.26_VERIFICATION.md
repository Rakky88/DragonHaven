# DragonHaven v0.05.26 verification

Status: published and verified, 9 September 2026 at 13:20:43 UTC.
Display **0.05.26**, pubspec **0.5.26+10076**, Android **10076**.

This release contains the completed birthday Trial/music/art and Christmas
opening-speed changes documented in `BIRTHDAY_EVENT_VERIFICATION.md`.
It excludes the proposed Sunwake and Harvestmoon events.

Migration 63 was already applied and verified on staging and production.
No database mutation or economy activation is required for this publication.
Fresh release gates and artifact evidence will be recorded below.

## Release gates and visual evidence

- CI [34355223649](https://github.com/Rakky88/DragonHaven/actions/runs/34355223649)
  passes on the exact release commit: **715 Flutter tests**, clean analysis,
  production preflight, signed Android bundle, native jukebox contracts and
  consistent MIDI checks. Local analysis and 68 affected/version tests pass.
  The first local full run found two old version expectations; both were
  updated before the complete successful CI run.
- Production APK uses `lib/main.dart`, production Firebase/Supabase and the
  ordinary persisted account. The private birthday fixture is not the target.
- Installed as an Android update without uninstalling or clearing storage:
  Quietstar, one floor, 25 coins and 3 gems remain. About visibly shows
  v0.05.26 (`release/release26-about.png`, `release/release26-home.png`).
- All eight language names are alphabetical. Dutch survives a forced restart
  (`release/release26-language-restored.png`); English was restored afterward.
- Birthday gameplay, animations, compact 320dp/1.35x layouts and reduced motion
  were exercised in the preceding same-code preview. Native birthday music
  changes back to the saved Reverie selection on expiry. Complete evidence is
  in `BIRTHDAY_EVENT_VERIFICATION.md`.
- Final production preflight at 13:20:40.993 UTC: 63 matching migrations,
  zero lint errors, Auth/settings/app HTTP 200, clock skew 10ms. The post-release
  preflight also passes. Economy/game flags remain false, push true, with zero
  nonlegacy accounts and zero shadow states. No server mutation was required.

## Published artifact

- Source/tag: `efc358462e9b534394448921dd5b61fa915a66dd`.
- Android package `nl.dragonhaven.app`, versionName `0.05.26`, versionCode `10076`.
- Stable signing certificate SHA-256:
  `477c5a5d7453384ca756265e77af97d5a002a907177ccd2d9065a9bec3414942`.
- APK: `release/DragonHaven-v0.05.26.apk`, **542,863,996 bytes**.
- SHA-256: `c2a9302e0abde30f147f438bf1727a46859f4b6c6e89771eeac3e32f46348301`.
- Release ID: `385528557`; public asset name: `DragonHaven.apk`.
- [Release](https://github.com/Rakky88/DragonHaven/releases/tag/v0.05.26)
- [Version APK](https://github.com/Rakky88/DragonHaven/releases/download/v0.05.26/DragonHaven.apk)
- [Permanent latest APK](https://github.com/Rakky88/DragonHaven/releases/latest/download/DragonHaven.apk)

Publisher dry run found no existing release/asset. Draft upload completed once;
publication used that same release ID, the full source SHA and exact notes.
Remote asset size and GitHub SHA-256 match the local APK; latest resolves to
v0.05.26 and the permanent download returns HTTP 200 with the expected size.
Private operational code values and announcements are absent from public notes.
