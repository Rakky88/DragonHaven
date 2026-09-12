# v0.05.30 / Android 10080 verification

Release prepared on 12 September 2026 after the user-authorized 30-minute
unchanged code/database observation (13:08?13:38 Europe/Amsterdam).

## Scope and validation

- Seasonal event progress replaces new Event Adventures; Christmas December
  20?26 needs 7,000 points and Valentine February 12?16 needs 10,000 points.
  Preview durations, stored rewards and chest/egg contents are preserved.
- Flutter analysis: clean. Full suite: 928 passed. Edge worker: 27 passed.
  MIDI normalization: 75 tracks unchanged, three unit tests passed. Native
  Android Gradle unit tests passed.
- First-edition and yearly date boundaries, exact claim thresholds, partner
  progress, post-close claims, preview isolation and documentation guards pass.
  Four visual event-bar tests also ran with real Roboto/Material fonts.
- Staging 79?82 was rehearsed with rollback before apply. Production 65?82 was
  rehearsed with rollback before apply. All 19 server contracts passed on both
  databases. The retired pair-Adventure gate rejects new entries; revoked
  historical machinery is used only to construct compatibility fixtures.
- Real staging Auth/RPC test verifies invitation, acceptance and both partner
  totals. All synthetic accounts were deleted. Production preflight: 82 matching
  migrations, zero lint errors, Auth health/settings and application health 200.
- One pre-deploy application-health request failed transiently; deployment was
  stopped before mutation. Independent and standard repeated checks returned
  200 before rollout. Post-deploy preflight passed.
- Compiled Edge ruleset: 6572d41bf0cf22a609b320b715c217c4834a3c0ab150654e3bfe0bd986572a9b
  (1,185,748 bytes), deployed to both environments. Production economy/game and
  account-migration switches remain disabled; no live account is promoted.
- APK package nl.dragonhaven.app, versionName 0.05.30, versionCode 10080.
  Existing certificate SHA-256:
  477c5a5d7453384ca756265e77af97d5a002a907177ccd2d9065a9bec3414942.
- APK update installation succeeded without clearing data. Quietstar, one floor,
  25 coins, 3 gems and English remain. About displays v0.05.30.

## Artifact

- File: DragonHaven.apk
- Bytes: 628161582
- SHA-256: c3ca374d15ffa23f2b23543dde1499f784f2d8d3a492b9ead187faca138674e3
- Release: https://github.com/Rakky88/DragonHaven/releases/tag/v0.05.30
- Version download: https://github.com/Rakky88/DragonHaven/releases/download/v0.05.30/DragonHaven.apk
- Permanent download: https://github.com/Rakky88/DragonHaven/releases/latest/download/DragonHaven.apk

Publication verification is pending. Local evidence: .tools/release30-*,
release/v0.05.30-artifact.json and release/release30-*.png.
