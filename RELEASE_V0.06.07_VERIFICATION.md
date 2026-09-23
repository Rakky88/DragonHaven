# DragonHaven v0.06.07 / 10100 verification

## Scope

This release adds the prepared rewarded-ad flow for Free Gems and Free Coins.
Each shop can offer three rewards per UTC day: 15 gems or 150 coins. The app
loads a Google rewarded ad before asking the server for a one-use claim. The
server accepts payment only after Google's signed server-side verification
(SSV) callback and commits the reward through the canonical revisioned game
command.

The release also moves the current privacy acknowledgement to version
`2026-09-23`, preserves v0.06.06 account startup through the legacy privacy
RPC, and pins AndroidX WorkManager 2.11.2 so the current Google Mobile Ads SDK
starts safely on supported Android devices.

## Validation

- Release source: `5df84ff1c1e5d54abf10597457f6d9dbe03f1d30`.
- Version, updater and startup checks target `0.06.07` / build `10100`.
- `flutter analyze --no-pub`: zero issues.
- Complete Flutter suite: 1,150 passed, one expected opt-in lossless-asset
  review skipped and zero failed.
- Rewarded-ad Flutter/privacy contract suite: 27 passed.
- `rewarded-ad-ssv`: Deno typecheck passed and 20 tests passed.
- All 75 MIDI tracks passed normalization verification and its three tests
  passed.
- The final APK is non-debuggable, contains the production AdMob application
  ID and both distinct production rewarded unit IDs, and resolves AndroidX
  WorkManager to 2.11.2.
- The signed production APK installed successfully as an update on the
  connected Android emulator. The installed package reports version
  `0.06.07`, build `10100`, and opens without an Android startup crash.

## Rewarded-ad rollout and activation gate

- The public developer site serves the exact `app-ads.txt` publisher record
  and the updated privacy notice. The AdMob privacy message is published, and
  the owner completed and saved Google's signed callback verification for both
  rewarded units.
- A disposable confirmed production account was initialized with current
  privacy consent. During the controlled device check, `issue_enabled` was
  enabled only for the test window.
- Google Mobile Ads logged that the production-unit request came from a test
  device, then returned load error 3 (`NO_FILL`). Loading happens before claim
  issuance, so the database remained at zero rewarded claims, the test wallet
  stayed at 25 coins and 3 gems, and no daily slot was consumed.
- The server kill-switch was returned to `issue_enabled=false` immediately.
  The disposable account and all dependent rows were deleted; the final audit
  found zero synthetic users and zero rewarded claims.
- Production reward issuance remains off until AdMob finishes app/account
  readiness and both units return a labelled test ad. Activation additionally
  requires an end-to-end proof for exactly +15 gems and +150 coins, counters
  changing from 3/3 to 2/3, one signed SSV callback and one claimed row per
  completed ad. No new app release is needed to enable issuance after that
  gate passes.

## Server boundary

- Production migration parity is 95/95 with zero database lint errors.
- Auth health, Auth settings, application health and rewarded SSV health all
  returned HTTP 200 before and after publication.
- The application service remains `dragonhaven-online`, contract version 1.
- The public SSV function remains ACTIVE and intentionally public for Google
  callbacks (`verify_jwt=false`). Function version 9 reports source revision
  `5df84ff1c1e5d54abf10597457f6d9dbe03f1d30` and bundle SHA-256
  `cb82503f869b82d1c3e1a0d0d9315ca7598a4d710f04dfd91ba80cd5096acdda`.
- The final runtime is `issue_enabled=false`, daily limit 3, rewards 15 gems
  and 150 coins, and claim lifetime 15 minutes. Existing gameplay remains
  available while rewarded ads are dormant.
- Rollback was not required.

## Artifact and publication

- Package: `nl.dragonhaven.app`, version `0.06.07`, build `10100`, not
  debuggable.
- ABIs: `arm64-v8a`, `armeabi-v7a`, `x86_64`.
- Signing certificate SHA-256:
  `477c5a5d7453384ca756265e77af97d5a002a907177ccd2d9065a9bec3414942`.
- APK size: 581,613,287 bytes.
- APK SHA-256:
  `cdbc76034bccb3f7d6061f2964b144f396c21175e9cad81f7d71c17c05697378`.
- GitHub release ID: 395021364; asset ID: 584516202. GitHub reports the
  same byte size and digest. A fresh download also produced the same byte size
  and SHA-256. The lightweight tag resolves to the exact release source, the
  release is latest, neither draft nor prerelease, and both download URLs
  returned HTTP 200 with the expected content length.
- Release page:
  https://github.com/Rakky88/DragonHaven/releases/tag/v0.06.07
- Versioned APK:
  https://github.com/Rakky88/DragonHaven/releases/download/v0.06.07/DragonHaven.apk
- Permanent latest APK:
  https://github.com/Rakky88/DragonHaven/releases/latest/download/DragonHaven.apk
- Tag-triggered Android release workflow:
  https://github.com/Rakky88/DragonHaven/actions/runs/35914355524
  completed successfully on the exact release commit. All 26 recorded steps
  passed, including rewarded SSV tests/parity, the production server preflight,
  Flutter analysis/tests and the signed Play Store bundle checks.
- GitHub uploaded the non-expired `DragonHaven-Play-Store` artifact (ID
  10774997860; 1,148,799,219 bytes; ZIP SHA-256
  `9b08bcadedb2b65177f35d1af84937d9f8f8b68a060f1ed4c313ab2d3e59db36`).
  Its verified `DragonHaven.aab` reports SHA-256
  `b00ad5b95313ffc516d3a7792ee058ae647d0b2ae34e39c89358c85cb58fab24`
  and the expected production signing certificate.
