# v0.05.32 / 10082 verification

Reviewed 12 September 2026. Only the active event has a meter. Server end-event
synchronization, calendar/test expiry and preview switches/restarts hide retired
meters while retaining stored points and earned rewards. Claim-only credit and
late-claim eligibility remain unchanged.

The 58dp glass meter uses event-colored liquid, engraved motifs and existing
logo/chest sprites. It has no visible title or numerical counter; semantics retain
the progress information. Valentine has a compact existing-friend picker button.

## Checks

- Flutter analysis: no issues.
- Final full suite: all 933 tests pass at concurrency two. Two school timing
  failures in an earlier heavily loaded run also passed independently;
  unrelated school gameplay was not changed.
- Event lifecycle tests cover switching/restarting previews, clearing previews,
  natural test/calendar expiry and immediate synchronized calendar dismissal.
- Android emulator: Halloween and Valentine meters, direct portrait friend list,
  320dp width, 1.6 text scaling and reduced motion visually reviewed.
- Final signed APK installed over the emulator app: About shows v0.05.32;
  one floor, 25 coins, 3 gems and the saved English language remain intact.
- Reference documentation guard synchronized; reference tests pass.
- Required production preflight: 83 matching migrations, zero lint errors,
  Auth health/settings and application health HTTP 200.
- Regenerated server worker remains byte-identical to v0.05.31:
  `af09b2bb4266893fb67de2337f23a5327aca08b0ac36f64a700069f67f4b4e15`.
  No migration, worker deployment or authority-switch changes for this release.

## Signed APK

Package `nl.dragonhaven.app`, version `0.05.32`, build `10082`.
Size: **628260150 bytes**. SHA-256:
`7c5d1709267856cf412b35f7ef2ff50c6eabe988154ac8ec95432cc46fc2fa7a`.
Signature verification passes with the existing certificate:
`477c5a5d7453384ca756265e77af97d5a002a907177ccd2d9065a9bec3414942`.

[Release](https://github.com/Rakky88/DragonHaven/releases/tag/v0.05.32)
[Version-specific APK](https://github.com/Rakky88/DragonHaven/releases/download/v0.05.32/DragonHaven.apk)
[Permanent latest APK](https://github.com/Rakky88/DragonHaven/releases/latest/download/DragonHaven.apk)

Publication API, digest and permanent link must be checked after upload.
