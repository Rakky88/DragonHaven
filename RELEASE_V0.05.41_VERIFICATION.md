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

## Publication status

Artifact, publisher dry run and production-APK installation verified. Ready for
authorized publication; final URLs and remote integrity evidence follow.
