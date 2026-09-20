# Release 0.05.41 / 10091 verification

This release includes the verified-account online start and 16+ privacy notice
implemented in commit 59af9f9. Full behavior and connection/recovery limitations
are documented in [ONLINE_ACCOUNT_ACCESS.md](ONLINE_ACCOUNT_ACCESS.md).

## Version and checks

- App/About/updater: 0.05.41; pubspec: 0.5.41+10091. The release build explicitly
  uses versionName 0.05.41 and versionCode 10091.
- The implementation passed the complete Flutter suite: 1,025 tests, one
  existing optional skip. Two additional account-deletion session tests passed.
- After the version change, all 85 selected release, load-profile, UI, language,
  reference-documentation and deletion tests passed. Language ordering and
  persisted language selection are covered by the UI suite.
- Complete implementation analysis and the follow-up analysis of changed version
  sources passed. No gameplay/reward changes are included.

## Server

The mandatory `tool/release_server_preflight.ps1` passed against linked
production at **2026-09-20 13:23:14 UTC**: all 88 local/remote migrations match,
zero database lint errors, Auth health/settings and app health all HTTP 200.
Observed server clock skew: 37 ms. Additive privacy migration 88 was already
applied and contract-verified on staging and production before this release.
No server worker deployment, authority switch or player migration is required.

## APK and visual review

- Universal release APK: `nl.dragonhaven.app`, versionName 0.05.41,
  versionCode 10091, non-debuggable. Existing arm64-v8a, armeabi-v7a and x86_64
  support retained. Production Firebase build configuration used.
- Size: **577,457,987 bytes (550.71 MiB)**.
- SHA-256: `7d4683ff5f96b811ec9096d1173f457c9c7e6af8d6920bcc8941bb94d32fe0a7`.
- APK signature verifies with the established certificate
  `477c5a5d7453384ca756265e77af97d5a002a907177ccd2d9065a9bec3414942`.
- Normal registration and privacy screens reviewed in an isolated emulator app,
  including 320 dp width, 1.3 text scale and reduced motion. Content remained
  readable and the privacy link worked; emulator display settings restored.
- Signed production APK installed successfully over the existing emulator app.
  Android reports 0.05.41 / 10091 without the debug flag; normal account-first
  startup opened correctly. No player account was created or save cleared.
- Publisher WhatIf passed: no existing v0.05.41 release or asset. All 70 public
  release-note files passed the private redeem-code content check.

## Publication

Published and independently verified **2026-09-20 13:34:07 UTC**.

- Public latest: **v0.05.41**; release ID 392441073; asset ID 576867524.
- Tag resolves to `5a4a1ef9b9a0e269b89cbeeae2b4cee0d5d07067`.
- GitHub's asset size and SHA-256 exactly match the signed APK above.
- Release page, versioned APK and permanent latest download all return HTTP 200.
- [Release page](https://github.com/Rakky88/DragonHaven/releases/tag/v0.05.41),
  [versioned APK](https://github.com/Rakky88/DragonHaven/releases/download/v0.05.41/DragonHaven.apk),
  [permanent latest APK](https://github.com/Rakky88/DragonHaven/releases/latest/download/DragonHaven.apk).
- Publisher script completed successfully without a replacement or retry.
  Tag-triggered automation only builds an AAB; it cannot publish or replace this APK.
- Production Auth health/settings and app health rechecked after publication at
  **13:34:08 UTC**, all HTTP 200; clock skew 145 ms.
