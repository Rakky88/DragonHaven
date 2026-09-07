# DragonHaven v0.05.19 / 10069

Source: `6982eba07394d7b6a7a08032f9f053ebbe680235`.

## App and server checks

- Complete release workflow: [34157071933](https://github.com/Rakky88/DragonHaven/actions/runs/34157071933), success.
- 596 tests passed; analysis clean. Reference documentation and private-code
  release-note checks passed.
- Production: exact migrations 1–56, lint 0, Auth/settings/application health 200.
  Migrations 50–56 first passed all six rollback-only contracts against the exact
  staging-proven SQL. All game accounts stay `legacy_client`; economic mutations
  and the shadow game worker remain disabled, with zero canonical game copies.
- Production Firebase config validated for `dragonhaven-20ced`; Android native
  Crashlytics initialization observed. Worker refuses unauthenticated POST (401)
  and accepts authorized empty work (200, zero leases). Production push enabled
  after the complete app gate; its empty scheduler tick creates no HTTP request.
  No billing account or paid Firebase product was enabled.
- Final APK installed on emulator-5554 with existing storage preserved.
  Altar sorting and Expertise inspection exercised with isolated preview data.
  Final production APK tutorial visually checked through Conclave, Academy,
  Inventory/Altar and completion. Checked 320dp width, 1.35 text scale and reduced
  motion, including scrolling long explanations and reset on the next step.
  Device density/font/animation settings restored afterwards.

## APK

- Package: `nl.dragonhaven.app`
- Version name/code: `0.05.19` / `10069`
- Local artifact: `release/DragonHaven-v0.05.19.apk`
- Public filename: `DragonHaven.apk`
- Size: **506,860,061 bytes**
- SHA-256: `1c7ef66f611dc3a73bef5d07d7cae666ff9f207a7b0f25a9c2b5bab64d556570`
- Signing certificate SHA-256:
  `477c5a5d7453384ca756265e77af97d5a002a907177ccd2d9065a9bec3414942`
- Publisher dry run: release/asset absent; no replacement planned.
- Public upload verified on 7 September 2026, 20:08 UTC: release `384294199`,
  asset `549315915`, uploaded; GitHub's SHA-256 digest and byte size match the
  local APK exactly. The tag points to the source commit above, and `/latest`
  resolves to v0.05.19. The permanent download returned HTTP 200 with
  Content-Length 506,860,061.
- Post-publication server preflight at 20:08:56 UTC: migrations 56, lint 0,
  Auth/settings/application 200, application clock skew 36 ms. Read-only
  authority verification still shows zero promoted accounts and shadow copies,
  game/economy mutations disabled, and production push enabled.

[Release page](https://github.com/Rakky88/DragonHaven/releases/tag/v0.05.19) ·
[Version APK](https://github.com/Rakky88/DragonHaven/releases/download/v0.05.19/DragonHaven.apk) ·
[Permanent latest APK](https://github.com/Rakky88/DragonHaven/releases/latest/download/DragonHaven.apk)

## Play Store bundle

The signed AAB passed its package/version/certificate gate and is retained in
[workflow artifact 10031511477](https://github.com/Rakky88/DragonHaven/actions/runs/34157071933/artifacts/10031511477).
AAB SHA-256: `f3c38c2347c524e4189e349ad1ff49c23515685107bc64559a5759a138085577`.
This is an artifact build, not a Google Play publication.

## Authorized temporary group companions

Love → Kisses → Hugs joined the approved Keeper's lobby using their own Auth
sessions and the normal join RPC. The four-player adventure ends on
**10 September 2026, 03:13:35 UTC / 05:13:35 Europe/Amsterdam**.
The server's hourly cleanup waits until completion and all real participants'
reward acknowledgements. It only deletes the three fixed, privately marked
synthetic users and then unschedules itself. Its first run succeeded and
correctly retained all accounts while the adventure was running.
The post-publication check again confirmed four participants, all three marked
companions retained, active cleanup scheduling, and a successful last cleanup run.
