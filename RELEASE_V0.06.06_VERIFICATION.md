# DragonHaven v0.06.06 / 10099 verification

## Scope

This release completes the latest v0.05.40 presentation follow-up for Tower,
My Dragons and Adventures, repairs authenticated startup after signing out and
back in, and restores reliable Android notification permission and delivery.

All gameplay state remains canonical. The notification change does not alter
rewards, timers or account notification choices. It only makes device access
observable, re-registers the device after a permission change and prevents a
failed social notification from being acknowledged as delivered.

## Validation

- Release source: `0877be8009be15705795ea59d220d2e41a19c113`.
- Version, updater and startup checks target `0.06.06` / build `10099`.
- `flutter analyze --no-pub`: zero issues.
- Complete Flutter suite: 1,125 passed, one expected opt-in lossless-asset
  review skipped and zero failed. The runner exited normally without an
  orphaned test process.
- Android native unit tests: 10 passed across notification-channel,
  notification-behavior and jukebox suites.
- `dispatch-social-push`: Deno check passed and all six core tests passed.
- Living reference verification and all five reference tests passed. Recorded
  fingerprints are `ecadb6336c6e542c` for Special content,
  `cd7b98815221dff0` for random rewards and `4a854f015edb8d79` for redeem
  codes. Public release notes contain no redeem-code values.
- All 75 MIDI tracks passed normalization verification; its three unit tests
  passed.
- The Account Info language picker was exercised on Android: all eight visible
  names are alphabetized and English remained selected. The notification
  permission cards, compact width, 1.3 text scale and reduced motion were
  visually reviewed. The overflow menu contains neither duplicate Language nor
  About entries and exposes the achievement count directly.
- The signed production APK was installed as an update on an Android emulator
  and on the connected Oppo CPH2609. Both retained their existing app-data
  inode. The phone opened the authenticated Tower instead of remaining on the
  progress gate; log review contained no fatal Android exception.

## Server boundary

No migration, ruleset, runtime flag, minimum-build change or player-data rewrite
is required. The existing `dispatch-social-push` Edge Function receives one
payload-only change: Firebase is told to use the app's stable
`dragonhaven_events` Android channel. The deployment does not change its JWT
policy, secrets, scheduler or `private.push_runtime` configuration.

Production migration parity, database lint, Auth endpoints, application health,
game runtime and push runtime are checked before and after this isolated function
deployment and again after publication.

### Deployment evidence

- Mandatory production preflight passed immediately before deployment with
  93/93 matching migrations, zero database lint errors, Auth health/settings
  HTTP 200 and application health HTTP 200 on contract version 1.
- The previous worker body was SHA-256
  `9ecbe36204eff242e2f81b8734359c6b95f7f94540c9cb64d835e7a818d4e2ad`
  and did not contain the Android channel field. A detached rollback checkout
  was fixed at v0.06.05 source `d3ae90d6089c60fa0e1141c6e1a553c480dd28fb`.
- Dormant staging received the worker first, moving ACTIVE version 1 to 2.
  Staging push stayed disabled, its endpoint, 45,000 limit, scheduler and Vault
  secret stayed present, and its endpoint returned the expected GET 405 and
  unauthenticated POST 401.
- Production then moved ACTIVE worker version 3 to 4. Its body SHA-256 is
  `f1dde3d59c3f75217be8cb2af41ab47bbce3b223c547a9a4d4994ecbd6e35f6d`
  and contains both `channel_id` and `dragonhaven_events`; `verify_jwt` remains
  false. The same 405/401 endpoint smoke check passed.
- Before and after deployment, gameplay and migration remained enabled,
  minimum client build remained 10092, ruleset SHA-256 remained
  `4432796eae24875360ad26e979aba0fafae015d45cecd05b79a1b1698738ef57`,
  all three shadow switches and legacy mutations remained disabled, and push
  remained enabled at its production endpoint with the 45,000 monthly limit.
  The scheduler and dispatch secret remained present with no pending, leased or
  failed outbox rows. Device registration rose from four to five only after the
  newly installed phone app started.
- Post-deployment and post-publication preflights repeated 93/93 migrations,
  zero lint errors and HTTP 200 for both Auth endpoints and application health.
  Rollback was not required.

## Artifact and publication

- Package: `nl.dragonhaven.app`, version `0.06.06`, build `10099`, not
  debuggable.
- ABIs: `arm64-v8a`, `armeabi-v7a`, `x86_64`.
- Signing certificate SHA-256:
  `477c5a5d7453384ca756265e77af97d5a002a907177ccd2d9065a9bec3414942`.
- APK size: 578,817,955 bytes.
- APK SHA-256:
  `bf747af6d1503e04aab21a36607f0b13505d8e4fa680005eabd19a41c1352f2f`.
- Publisher `-WhatIf` confirmed no existing tag, release or asset and the exact
  size/hash. Windows PowerShell then hit its known pre-mutation `ShouldProcess`
  null-reference fault. A fresh tag/release/draft query confirmed no partial
  state before the official GitHub CLI performed the sole upload.
- GitHub release ID: 394664334; asset ID: 583782525. GitHub reports the same
  byte size and SHA-256 digest. The lightweight tag resolves to the exact
  release source commit, the release is latest, neither draft nor prerelease,
  and both versioned and permanent download URLs returned HTTP 200.
- Release page:
  https://github.com/Rakky88/DragonHaven/releases/tag/v0.06.06
- Versioned APK:
  https://github.com/Rakky88/DragonHaven/releases/download/v0.06.06/DragonHaven.apk
- Permanent latest APK:
  https://github.com/Rakky88/DragonHaven/releases/latest/download/DragonHaven.apk
- Tag-triggered Android release workflow:
  https://github.com/Rakky88/DragonHaven/actions/runs/35864178370
  completed successfully on the exact release commit. All 22 workflow steps
  passed, including the signed Play Store bundle checks. GitHub uploaded the
  non-expired `DragonHaven-Play-Store` artifact (ID 10751947988;
  1,143,689,171 bytes; ZIP SHA-256
  `aaf04110d292ba2a5739daae48dcc0a8875308d636b8f314b0c1fa9bafc3e59a`).
  Its verified `DragonHaven.aab` reports version `0.06.06`, build `10099`,
  SHA-256 `8055a5d2d92eba19a5ab97ec499df9d07a071f1ff4da041d05890813bf8688ca`
  and the expected production signing certificate.
