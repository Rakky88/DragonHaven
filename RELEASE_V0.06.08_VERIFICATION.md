# DragonHaven v0.06.08 / 10101 verification

## Scope

This release restores the animated, interactive Tower room scenes. Dragons
wander through their rooms again, room ambience and inhabitants move, reduced
motion remains respected, and changing a room type stays inside the selected
room. It also moves scheduled Adventure, Trade and Partner refreshes to
best-effort background reads. Brief transport failures no longer interrupt an
otherwise playable server session, while stale replies are fenced from newer
commands and confirmed server state remains authoritative.

## Validation

- Release source: `b3c216d323010ae1366cdfdb14d0173be5c7274d`.
- Version, updater and startup checks target `0.06.08` / build `10101`.
- `flutter analyze --no-pub`: zero issues.
- Complete Flutter suite: 1,169 passed, one expected opt-in lossless-asset
  review skipped and zero failed.
- The Tower room suite exercises movement, server-backed calling and room
  changes, compact layout, account fencing and reduced motion without an
  active ticker.
- The canonical session suites exercise queued optimistic commands,
  non-blocking background reads, stale-reply fencing, lost replies, automatic
  refresh and the heartbeat transport-failure threshold.
- Rewarded-ad SSV: Deno typecheck passed and all 20 tests passed.
- All 75 MIDI tracks passed normalization verification and its three tests
  passed. Native Android unit tests also passed locally and in CI.
- The final APK is non-debuggable, contains the two distinct production
  rewarded-ad unit IDs, resolves AndroidX WorkManager to 2.11.2 and has the
  expected three Android ABIs.
- The signed production APK installed successfully as an update on the
  connected Android emulator. The installed package reports version
  `0.06.08`, build `10101`, opens its account screen and produced no Android
  fatal-exception log entry.

## Server boundary

- No database migration, schema change or gameplay-worker deployment was
  needed for this client release.
- Production migration parity is 95/95 with zero database lint errors.
- Auth health, Auth settings, application health and rewarded SSV health all
  returned HTTP 200 before the release, after the SSV provenance update and
  after publication.
- The application service remains `dragonhaven-online`, contract version 1.
- The unchanged public `rewarded-ad-ssv` function was redeployed only to bind
  its provenance to the exact release source. Function version 11 remains
  ACTIVE and public (`verify_jwt=false`), reports source revision
  `b3c216d323010ae1366cdfdb14d0173be5c7274d`, and retained bundle SHA-256
  `cb82503f869b82d1c3e1a0d0d9315ca7598a4d710f04dfd91ba80cd5096acdda`.
- The final rewarded-ad runtime still has `issue_enabled=false`, daily limit
  3, rewards of 15 gems and 150 coins, claim lifetime 15 minutes and zero
  claims. Existing gameplay therefore remains available while reward issuance
  is dormant.
- Rollback was not required.

## Artifact and publication

- Package: `nl.dragonhaven.app`, version `0.06.08`, build `10101`, not
  debuggable.
- ABIs: `arm64-v8a`, `armeabi-v7a`, `x86_64`.
- Signing certificate SHA-256:
  `477c5a5d7453384ca756265e77af97d5a002a907177ccd2d9065a9bec3414942`.
- APK size: 581,695,207 bytes.
- APK SHA-256:
  `e7744c389964bbe4da32bd126d8dc07003bcf183664883ec691200a6990b3d57`.
- GitHub release ID: 395692774; asset ID: 585978811. GitHub reports the
  same byte size and digest. A fresh permanent-link download produced the same
  byte size and SHA-256. The tag resolves to the exact release source, the
  release is latest, neither draft nor prerelease, and both download URLs
  returned HTTP 200 with the complete expected asset.
- Release page:
  https://github.com/Rakky88/DragonHaven/releases/tag/v0.06.08
- Versioned APK:
  https://github.com/Rakky88/DragonHaven/releases/download/v0.06.08/DragonHaven.apk
- Permanent latest APK:
  https://github.com/Rakky88/DragonHaven/releases/latest/download/DragonHaven.apk
- Tag-triggered Android release workflow:
  https://github.com/Rakky88/DragonHaven/actions/runs/36002847183
  completed successfully on the exact release commit. All release steps
  passed, including rewarded SSV tests and deployment parity, the production
  server preflight, Flutter analysis and tests, the signed Play Store bundle,
  native Android tests and artifact verification.
- GitHub uploaded the non-expired `DragonHaven-Play-Store` artifact (ID
  10810281911; 1,148,938,723 bytes; ZIP SHA-256
  `76623b4c90e77fa8a0dcb01fd46288b6fafefda4324ceeb76c1fbc97d0d4e12e`).
  Its verified `DragonHaven.aab` reports SHA-256
  `f51a3fa3f25c72e264f3c186f1a7c82f0c14e9a152271bb2f8c508ac24a3769c`
  and the expected production signing certificate.
