# v0.05.31 / 10081 verification

Verified 12 September 2026. Adventure points are credited on reward claim,
using the original completion time for event eligibility. Old ready saves do
not double-credit; group claims follow the same policy. Compact event panels
use existing event logos and chest sprites. Claim particles respect reduced
motion. Valentine opens an alphabetized existing-friend portrait list.
Migration 83 maps independent personal preview keys without changing schedules.

## Checks

- 932 Flutter tests pass; Flutter analysis reports no issues.
- 27 generated-worker Edge tests pass. Ruleset SHA-256:
  `af09b2bb4266893fb67de2337f23a5327aca08b0ac36f64a700069f67f4b4e15`.
- Staging and production both have 83 matching migrations. Nineteen existing
  rollback-only SQL contracts pass on each. The isolated PostgreSQL test also
  verifies separate preview keys, incoming visibility and partner exclusivity.
- Real staging Auth/RPC invitation and acceptance between temporary accounts
  confirm each player's independent contribution; both accounts were removed.
- Production migration rehearsed with rollback before application. Runtime and
  economy authority switches remain disabled; no player account was promoted.
- Required production preflight: zero database lint errors, Auth health/settings
  and application health HTTP 200. Both game workers use the verified bundle.
- Android emulator: real Adventure tab, Halloween and Valentine panels, claim
  1900 -> 1950 and 3150 -> 3200, recorded flying sprites, friend portrait sheet,
  320dp compact layout with 1.6 text scaling; reduced-motion widget checks pass.
- Reference documentation and all fixed UI translations are synchronized.

## Signed APK

Package `nl.dragonhaven.app`, version `0.05.31`, build `10081`.
Size: **628178046 bytes**. SHA-256: `dcd12aea08e277970a0415841483a1affd59502934bb6e7f27b0419e338d84b5`.
Signature verification passes with the existing certificate:
`477c5a5d7453384ca756265e77af97d5a002a907177ccd2d9065a9bec3414942`.

[Release](https://github.com/Rakky88/DragonHaven/releases/tag/v0.05.31)
[Version-specific APK](https://github.com/Rakky88/DragonHaven/releases/download/v0.05.31/DragonHaven.apk)
[Permanent latest APK](https://github.com/Rakky88/DragonHaven/releases/latest/download/DragonHaven.apk)

Publication API, digest and permanent link must be checked after upload.
