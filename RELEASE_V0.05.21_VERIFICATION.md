# DragonHaven v0.05.21 / 10071

Published and verified on 8 September 2026; APK upload completed at 20:02:04 UTC.
Source: `7e91aacfaea8491d88e1ccd5d8ba2684524c8621`.

## Scope

- Direct Expertise sprite glow, full six-event app/launcher/startup logos and
  compact Draconomicon sprite shortcuts beside both dragon-picker titles.
- Annual New Year windows retain their existing end time across 1 January.
- Visible version, updater version, pubspec and Android build increment one
  step to v0.05.21 / 10071. Regression expectations are updated together.
- Development analysis, 625 tests and visual evidence are recorded in
  `EVENT_BRANDING_VERIFICATION.md`. Release checks use the updated version.

## Server

- Production preflight at 19:43:11 UTC: exact migrations 1–57, lint 0 and
  Auth health/settings/application health HTTP 200; clock skew 64 ms.
- No database migration, Edge Function deployment, Firebase configuration change
  or economy activation is needed. The release retains existing production
  integration and signing. No billing or paid service is enabled.

## Publication strategy

The Android release workflow validates the exact source and retains a signed
Play Store AAB. It has read-only contents permission and does not publish a
GitHub release. The release-publisher script is the only APK publisher; the
stable public asset name remains `DragonHaven.apk`.

## Build and device verification

- Production build uses `lib/main.dart`, production Firebase project
  `dragonhaven-20ced` and explicit app/build version defines. Build succeeds
  in 189.8 seconds. The isolated preview entry is not packaged for release.
- The updater's mock future version is now calculated from AppInfo, so version
  increments cannot accidentally turn its test fixture into the current release.
  The initial two stale-fixture failures are corrected; all three update-prompt
  tests pass. The other version, load-profile and reference tests passed.
- Emulator-5554 at 320dp, 1.35 text scale and all animation scales zero:
  event header/countdown, direct Expertise glow, toggling Might off, both compact
  picker titles and Draconomicon round trips visually checked. The Trial details
  correctly retain only Arcana/Spirit glow. All preview game state is in memory.
- The production APK installs as an update. Cold launch through Launcher_default
  succeeds; About displays v0.05.21. Installed APK SHA-256 exactly matches the
  artifact below. Existing 25 coins, 3 gems, original dragon and English language
  remain. All eight language names are ordered and the saved selection is intact.
- Native Firebase Crashlytics initialization is observed on production startup.
  No artificial crash or production diagnostic event is generated.
- Density 420, font scale 1.0 and all three animation scales 1 are restored.
  Temporary storage-reserve override is removed and confirmed null; app data
  was never cleared. The ordinary launcher is restored after the preview.
- Local screenshots: `release/release21-compact-*.png` and
  `release/release21-production-*.png`.

## APK

- Package: `nl.dragonhaven.app`; version name/code: `0.05.21` / `10071`.
- Local artifact: `release/DragonHaven-v0.05.21.apk`.
- Stable public filename: `DragonHaven.apk`.
- Size: **516,504,334 bytes**.
- SHA-256: `5b35b10c5aeffb37f24b517f3e5cb3db700622fa9fca0fdca1728da594d1ea2f`.
- Signing certificate SHA-256:
  `477c5a5d7453384ca756265e77af97d5a002a907177ccd2d9065a9bec3414942`.
- APK v2 signature verifies; the certificate matches the installed release key.
- Publisher dry run: release and asset absent, no replacement planned.

Release workflow:
[34270982612](https://github.com/Rakky88/DragonHaven/actions/runs/34270982612).

## CI and Play Store bundle

- The complete workflow above succeeded on the exact release source, including
  production preflight, clean analysis, **625 passing tests**, signing and
  production Firebase configuration. Living-reference and private-code checks
  are included in the test gate.
- The signed AAB is retained in
  [artifact 10074107476](https://github.com/Rakky88/DragonHaven/actions/runs/34270982612/artifacts/10074107476).
  SHA-256: `247f0e9140ea8567527db4b0bae3fa85be9bdde4116cd265842bdf6a0fd4db05`.
  Its certificate matches the stable release key. This is an artifact build,
  not a Google Play publication.

## Publication and final server check

- Final pre-publication production preflight at **19:57:17 UTC**: exact
  migrations 1–57, lint 0, Auth/settings/application HTTP 200; clock skew 66 ms.
- Release **385023641**, asset **551210916**, state `uploaded`.
- GitHub's digest and byte size exactly match the local and installed APK.
  The tag points to the full source commit above. Latest resolves to v0.05.21;
  the permanent APK download returns **HTTP 200**, Content-Length **516504334**.
- Post-publication production preflight at **20:03:24 UTC**: exact migrations
  1–57, lint 0 and Auth/settings/application HTTP 200; clock skew 54 ms.
- No server migration, worker deployment, economy switch, entitlement or
  temporary companion account was modified during this release. Existing
  production monitoring/push configuration remains in place; open economy
  activation work remains open in `DRAGONHAVEN_POST_AUDIT_PLAN.md`.

[Release page](https://github.com/Rakky88/DragonHaven/releases/tag/v0.05.21) ·
[Version APK](https://github.com/Rakky88/DragonHaven/releases/download/v0.05.21/DragonHaven.apk) ·
[Permanent latest APK](https://github.com/Rakky88/DragonHaven/releases/latest/download/DragonHaven.apk)
