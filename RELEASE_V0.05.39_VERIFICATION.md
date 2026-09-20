# Release 0.05.39 / 10089 verification

Date: 20 September 2026. Based on public v0.05.38, with the shared expertise
feature backported from `fix/server-economy-cutover`. Unfinished account
startup/cutover is excluded. Account authority flags remain disabled.

## Gameplay and compatibility

- Midnight Chime has no game timer, score cap or action-count cap. It keeps
  accelerating and ends at three mistakes; S+ starts at exactly 20,000.
- Long Chime runs use bounded checkpoints. Tests exceed 6,500 notes and 20,000
  points, repeatedly serialize/restore, then finish after three missed notes.
- New Year lanes accept taps across the screen and simultaneous fingers.
  Birthday accepts outside-board taps; Valentine accepts outside-board swipes.
  Spatial puzzles preserve their position-sensitive input.
- Retraining accepts every otherwise eligible dragon. Negative expertise is
  applied first and floors at zero, then the complete planned positive reward
  is limited by remaining shared capacity. Zero/partial source points and
  maxed dragons are covered. Existing underway adventures retain old rewards.
- Shared capacity: 950 normal, 1,100 Sinister, +50 Mastery, fixed private 0-50
  Dragon Spark. Existing earned over-budget points are preserved. One MAX
  indicator belongs to the whole dragon. Spark Astrolabe has the same rare
  drop weight as the four brooches and only joins chest/S+ relic drops.
- Remaining 20,000 score caps: Halloween, Christmas, Valentine, Pride,
  Birthday and Harvestmoon. Sunwake and the three original trials have no
  gameplay score cap. Individual timed trials may end before reaching a cap.

## Automated checks

| Check | Result |
|---|---|
| Final Dart analysis, lib/test/tool | No issues |
| Complete Flutter suite | 978 passed, one existing opt-in skip; three failures described below |
| Entire three affected files after fixes | 31/31 passed, resolving all failures: 981 passing tests overall |
| Final touch-surface and reference tests after HUD change | 8/8 passed |
| Shared-domain Dart VM/JavaScript parity | Passed; 1,237,441-byte bundle; all 11 trial commands |
| Trusted worker compile and Deno type check | Passed; compiled for verification, not deployed |
| Living reference guard | Synchronized |
| All public release-note files | No active redeem codes or code announcements |
| Version, language ordering and persisted language tests | Passed in full suite |

The three initial failures were two old Chime test pilots expecting a timed
finish, and a staging-workflow guard detecting production rollout wiring.
The pilots now deliberately stop playing after 130 seconds; production wiring
was moved to the existing production-only workflow. No guard was weakened.

## Device review

The actual gameplay widgets were exercised in a separate Android review
package, without production accounts. Reviewed normal 411 dp and compact
320 dp widths, 1.3 text scaling and reduced motion. New Year has a full title
and no timer; a header tap scored a note. Birthday header tapping placed one
layer; Valentine swiping outside the board moved the two hearts. Shared
expertise rows, whole-dragon MAX and Astrolabe artwork were inspected. No
Flutter overflow or unhandled exceptions appeared in the review log.
Device display and animation settings were restored afterward.

The signed production APK was installed as an update over 0.05.37 / 10087 on
the emulator, without clearing application data; installed version is
0.05.39 / 10089.

## Server

- Staging schema run: [35481248287](https://github.com/Rakky88/DragonHaven/actions/runs/35481248287).
- Production schema run: [35481397747](https://github.com/Rakky88/DragonHaven/actions/runs/35481397747).
- Migrations 84-86 applied, all 86 local/remote migrations match.
- Partner authority, shared expertise, rare chest catalog and endless-Chime
  SQL contracts passed. Synthetic writes rolled back; six authority flags
  and zero server-authority accounts unchanged.
- Mandatory `tool/release_server_preflight.ps1` passed in production: database
  lint zero errors; Auth health, Auth settings and app health all HTTP 200.
  Application contract version 1, observed clock skew 1,052 ms.

## Artifact

- Package: `nl.dragonhaven.app`; version `0.05.39`; build `10089`.
- Public filename: `DragonHaven.apk`.
- Size: **574,179,823 bytes** (547.58 MiB).
- SHA-256: `735d49ea6042dbebb0b8aca6bd8429e80bfac910e0b21b402385ce8c464e369c`.
- APK signature verified (v2), existing release certificate SHA-256:
  `477c5a5d7453384ca756265e77af97d5a002a907177ccd2d9065a9bec3414942`.
- Retained ABIs: arm64-v8a, armeabi-v7a, x86_64.

## Publication

Pending final publisher dry run and upload. This record is updated after the
release API, remote asset size/digest and permanent download URL are verified.
