# Release 0.05.42 / 10092 verification

## Scope

Normal account startup opens the server-owned five-tab game after a protected
legacy transfer, or initializes a fresh account using server entropy/time.
Signing in on an empty installation restores confirmed account progress.
See [SERVER_GAMEPLAY_ROLLOUT.md](SERVER_GAMEPLAY_ROLLOUT.md) for the complete
restoration matrix and migration/recovery invariants.

## Validation

- Complete Flutter suite: **1,041 passed, one existing optional skip**.
- Final targeted release checks: **78 passed**; Dart analysis: no issues.
- Edge core: **30 passed**; Edge index type-check passed. VM/JavaScript rule
  parity passed with the current source.
- Rebuilt worker SHA-256:
  `4432796eae24875360ad26e979aba0fafae015d45cecd05b79a1b1698738ef57`
  (1,250,882 bytes). Deployed to staging and production with runtime switches off.
- Real staging fresh and legacy Auth/Edge/SQL creation, activation, replay,
  second-login restoration, profile/achievement publication, Conclave reads,
  private-property redaction and stale-device refusal passed. Synthetic accounts
  were removed; staging runtime restored.
- Normal Flutter AccountStartupApp opened two empty installations into the
  server shell without a device save or legacy import. Complete fixture tests
  preserve materials, tradeable/untradeable relic quantities, fixed eggs/tags,
  dragons, records, active timers, room coordinates, packs and selections.
- Server shell inspected on an isolated emulator app using synthetic rules and
  state: Tower, Altar/materials, relics, Inventory and Adventures. Compact review
  used 320 dp, 1.3 text scale and reduced motion. Fixed navigation labels received
  a small-screen scale bound; page content retains the accessibility scale.
  Temporary review app removed and emulator display settings restored.

## Server

Additive migrations 89-92 were rehearsed and applied to staging, then rehearsed
and applied to production. All four rollback contracts and targeted PostgreSQL
lint passed; schema apply changed no authority switches or player authority.

Mandatory production `tool/release_server_preflight.ps1` passed at
**2026-09-20 15:49:46 UTC**: 92 matching migrations, zero database lint errors,
Auth health/settings and app health all HTTP 200; clock skew 1 ms.

## Android artifact

- Universal APK: `nl.dragonhaven.app`, versionName **0.05.42**, versionCode
  **10092**, non-debuggable; arm64-v8a, armeabi-v7a and x86_64 retained.
- **577,687,331 bytes** (550.93 MiB).
- SHA-256: `0bf455ab7a080c65e79b2aecdf4fd9bdfa14166f8decb8e8b8a55cfdf381b28b`.
- Established signing certificate:
  `477c5a5d7453384ca756265e77af97d5a002a907177ccd2d9065a9bec3414942`.
- Production Firebase configuration used. APK successfully installed over
  v0.05.41 in the emulator; Android reports 0.05.42 / 10092 without debug flag.
  No player save was cleared. Source/art/runtime version checks agree.

## Publication and activation

- Published [v0.05.42](https://github.com/Rakky88/DragonHaven/releases/tag/v0.05.42),
  release ID **392486128**, asset ID **577100838**. Public release creation time:
  **2026-09-20 15:58:51 UTC**; the asset completed afterward, before activation.
- Tag resolves to tested commit
  `ba6b935f5fff0a3d3779867866b307eb7a3c9349`.
- The GitHub asset size and SHA-256 exactly match the artifact above. The latest
  release resolves to v0.05.42 and its permanent download URL responds successfully.
  [Version-specific APK](https://github.com/Rakky88/DragonHaven/releases/download/v0.05.42/DragonHaven.apk)
  and [permanent latest APK](https://github.com/Rakky88/DragonHaven/releases/latest/download/DragonHaven.apk).
- `tool/server_account_activate.py` verified the public artifact, schema and
  reviewed worker hash, then enabled commands and migration for minimum client
  build **10092**. All three shadow switches remain off. The separate legacy
  economy mutation switch remains off.
- One marked synthetic production account passed creation, durable initialization
  retry, onboarding and second-login restore with an identical full public
  snapshot and private state hash. The synthetic account was removed. No real
  player account was edited by the rollout tooling.
- Post-activation mandatory server preflight passed at
  **2026-09-20 16:04:19 UTC**: **92** matching migrations, **0** database lint
  errors, Auth health/settings and application health all **HTTP 200**, clock
  skew **18 ms**.
- Existing players transfer through the compatible app on their next login.
  They should complete that first transfer on the existing installation before
  uninstalling it; subsequent installations restore confirmed server progress.
  Genuine conflicting legacy copies remain reviewable instead of being merged.

Recovery preserves canonical states and receipts: pause new migrations and, if
needed, commands; repair/redeploy the worker and resume. Never return a migrated
account to its stale device save. Activation tooling applies this pause if its
synthetic smoke check fails; no such pause was required for this release.
