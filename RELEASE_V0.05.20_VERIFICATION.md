# DragonHaven v0.05.20 / 10070

Published and verified on 8 September 2026; APK upload completed at 18:56:53 UTC.
Source: `aaafe6114eece36339ff26410fa4519ac1603e02`.

## Server

- Exact migration/contract source verified against successful staging run
  [34254991384](https://github.com/Rakky88/DragonHaven/actions/runs/34254991384).
- `tool/production_dormant_57.py` applied only migration 57 after all six
  game/import/read/receipt/ruleset/recovery contracts passed in a rollback-only
  transaction. All six passed again after application; no synthetic data remains.
- Production preflight at 18:23:52 UTC: exact migrations 1–57, lint 0,
  Auth health/settings and application health HTTP 200.
- All accounts remain `legacy_client`, economic mutations and game worker off,
  zero canonical game copies. The complete game runtime and existing enabled
  production push switch are unchanged. No live game saves were imported.
- No paid services or billing account were enabled.

## App

- All visible/runtime version sources incremented one step: v0.05.20 / 10070.
  The version regression now checks the build number against pubspec as well.
- Event themes/countdown, Expertise highlights and shared inspection, compact
  Draconomicon shortcuts, permanent dragon sex and ordinary test Trial rewards.
  See `EVENT_THEME_AND_TRAINING_VERIFICATION.md` for gameplay and visual evidence.
- Historical Special Adventure and preview Special Chest exclusions remain;
  the reward policy change applies to event Trials only.

- Complete release workflow
  [34263298633](https://github.com/Rakky88/DragonHaven/actions/runs/34263298633)
  succeeded: production preflight, analysis, all 621 tests, Firebase production
  configuration, stable signing and AAB verification. Living reference and
  private-code release-note checks are included in the test gate.
- The first local suite identified two stale test expectations for build 10069;
  both now reference `AppInfo.buildNumber`. Their 24-test regression run and the
  subsequent complete CI suite pass. No runtime workaround was introduced.
- Emulator-5554: isolated, non-persistent event data at 320dp, font scale 1.35
  and reduced motion. Visually checked the event background/logo/countdown,
  fixed sex icon, independent Expertise toggles, matching highlighted Adventure
  selection, both three-Expertise dialogs and both Draconomicon round-trips.
  The unhighlighted Might Trial correctly puts the dragon in Available Dragons.
  New shortcut labels and Expertise rows remain readable at this size.
- Local screenshot evidence is under `release/release20-*.png`.
- Local build disk exhaustion was resolved by lossless NTFS compression of
  generated build and dependency caches; no save, source or signing key was
  removed. The final production build completed successfully with `lib/main.dart`
  and production Firebase enabled. The isolated preview APK is not distributed.

## APK

- Package: `nl.dragonhaven.app`; version name/code: `0.05.20` / `10070`.
- Local artifact: `release/DragonHaven-v0.05.20.apk`.
- Public filename: `DragonHaven.apk`.
- Size: **506,958,913 bytes**.
- SHA-256: `f1c918bc14b04fa328b9ebee6eda22df8bce22aae2e05c91579cc99e564002cf`.
- Signing certificate SHA-256:
  `477c5a5d7453384ca756265e77af97d5a002a907177ccd2d9065a9bec3414942`.
- Publisher dry run: release and asset absent, no replacement planned.
- Final production APK installed as an update on emulator-5554. The installed
  APK's SHA-256 exactly matches the artifact above. Launch after force-stop succeeds and
  native Firebase Crashlytics initialization is observed. Existing storage and
  the saved language/destination remain; no app data was cleared.
- Density 420, font scale 1.0 and all three animation scales 1 were restored.
  The emulator's temporary storage-reserve override was removed and verified
  unset. Language ordering and persisted selection pass the regression suite.
- Final pre-publication server preflight at 18:50:21 UTC: migrations 57,
  lint 0, Auth health/settings/application HTTP 200.

## Play Store bundle

The signed AAB passed its package/version/certificate gate and is retained in
[workflow artifact 10071146339](https://github.com/Rakky88/DragonHaven/actions/runs/34263298633/artifacts/10071146339).
AAB SHA-256: `32804ab31f10526c80648290deb685f5bf8792fb5823370f7579a8403c30f697`.
This is an artifact build, not a Google Play publication.

## Publication and final server check

- Release `384984492`, asset `551105403`, state `uploaded`.
- GitHub's SHA-256 digest and byte size exactly match the local APK above.
- The release/tag points to the full source commit above. `/releases/latest`
  resolves to v0.05.20. The permanent APK download returns HTTP 200 with
  Content-Length **506,958,913**.
- Post-publication production preflight at **18:57:23 UTC**: exact migrations
  1–57, lint 0, Auth/settings/application HTTP 200, clock skew 78 ms.
- Final read-only state check: economic/game mutations disabled, zero promoted
  accounts or canonical copies, production push enabled. The running group
  adventure still has all four participants and the three marked companions.
  Its cleanup schedule remains active; the last run succeeded and correctly
  retained the accounts pending completion and real-player reward acknowledgement.

[Release page](https://github.com/Rakky88/DragonHaven/releases/tag/v0.05.20) ·
[Version APK](https://github.com/Rakky88/DragonHaven/releases/download/v0.05.20/DragonHaven.apk) ·
[Permanent latest APK](https://github.com/Rakky88/DragonHaven/releases/latest/download/DragonHaven.apk)
