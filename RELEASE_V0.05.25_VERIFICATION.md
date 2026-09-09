# DragonHaven v0.05.25 verification

Status: published and verified, 9 September 2026.
Display **0.05.25**, pubspec **0.5.25+10075**, Android **10075**.

## Changes

- Trial balance: Halloween S+ 2000 (A 1600 / S 1800), New Year 20000,
  Valentine 10000, Pridefest 12000. Other lower ranks and Christmas grades
  retain their existing values. Christmas parcels arrive independently,
  overlap and accelerate; every parcel keeps its own deadline, and three
  mistakes immediately end play. See `EVENT_TRIAL_BALANCE_VERIFICATION.md`.
- Locked secret achievements sort after named achievements in both list and
  compact grid. Catalog order remains stable within each group and revealing
  a secret returns it to the ordinary group. The reserved Group Adventure
  empty state now uses the existing short localized no-trail message.
- All personal preview mappings are available to every verified keeper.
  Forward migration 62 preserves authenticated ownership, verification, one
  active preview, retry expiry and historical scores/rewards. Operational
  values are recorded only in `REDEEM_CODES.md`, outside public release notes.
- Jukebox reconciliation compares against the last dispatched configuration,
  including natural event boundaries, manual dismissal, resume and switches.
  Ordinary selections, newly collected tracks, shuffle and repeat survive.
  Native playlist changes reevaluate whether to stop, resume or select a song.
  A removed event track cannot consume a non-repeating replacement cycle.
- Android maintains fixed track gain and pauses for audio focus interruptions.
  The 75 MIDI scores have consistent note velocity, volume and expression;
  timing, pitch, release/sustain and source metadata are preserved. No runtime
  compressor pumps the gain. Import tooling and CI enforce the same rule.

## Verified behavior

- Staging CI [34346382070](https://github.com/Rakky88/DragonHaven/actions/runs/34346382070)
  passed on `dd0f8b295af544004f7094b384a0b13aa473c01a`: analysis, all **707 Flutter
  tests**, Deno parity/contracts, migration rehearsal and application, actual
  Auth/Edge/Dart/Postgres commands, client UI recovery and synthetic cleanup.
- Local tests: all previous balance tests passed (703). After the additional
  changes, the full suite found outdated expectations and one transient Windows
  temporary-directory lock; all 207 affected regression tests then passed.
  The final full staging suite above confirms the combined changes.
- Four native Kotlin tests cover event replacement, acquired songs, no-repeat
  completion/restart, unchanged keepalives, all-off/on and shuffled full cycles.
  Three Python tests validate MIDI normalization, idempotence, retained metadata,
  running status/note-off and malformed input. All pass; 75 shipped scores pass
  the read-only normalization guard. Reference documents and their five tests pass.
- Android emulator: list top shows ordinary achievements; list bottom contains
  only `???`. The grid is clear at 320dp, 1.35 text scale and reduced motion.
  Evidence: `release/release25-achievements-top.png`, `-bottom.png`,
  `release25-achievements-320dp-top.png`, `-320dp-grid.png`.
- Actual current Christmas audio (44.1kHz mono) was replaced at the natural
  20-second preview expiry by Reverie (22.05kHz stereo), with an active native
  player and gain 1.0. Both individual song and master switches stop/start the
  actual native player. Evidence: `release/release25-current-event-before-expiry.txt`,
  `-after-expiry.txt`, `release25-song-off.txt`, `-on.txt`,
  `release25-master-off.txt`, `-on.txt`. Preview saves were nonpersistent.
- Final production APK installed as an update without clearing storage. Quietstar,
  the one-floor tower and 25 coins / 3 gems remain. About visibly shows v0.05.25
  (`release/release25-about.png`). The eight language names are alphabetical;
  Dutch survives restart and English was restored. Density 420, font scale 1.0
  and normal animation scales were restored.

## Production and artifact

- Migration 62 applied after staging success. Production preflight at
  2026-09-09T11:46:10Z: **62** matching migrations, **0** lint errors,
  Auth/settings/application **HTTP 200**, clock skew 1ms.
- Economy/game mutation flags remain false, push true, with zero nonlegacy
  accounts and zero canonical shadow states. No paid service or player cutover.
- Package `nl.dragonhaven.app`, versionName `0.05.25`, versionCode `10075`;
  stable certificate `477c5a5d7453384ca756265e77af97d5a002a907177ccd2d9065a9bec3414942`.
- APK `release/DragonHaven-v0.05.25.apk`, **536,790,700 bytes**,
  SHA-256 `dfc6d2ce0dcb30fd7c2779b264a954dec28d28bfee2d9a649f17d25e82d87bad`.
- Publisher dry run confirmed the stable `DragonHaven.apk` asset name and no
  preexisting release. Final publication evidence follows below.

The first release workflow passed analysis, all Flutter tests and production
preflight, then exposed an ordering error: Flutter had not yet generated the
ignored Linux Gradle wrapper when native tests ran. The native step now follows
Flutter's release build. This infrastructure-only correction changes no app or
server runtime source. A new full release workflow verifies that order.

## Final release evidence

- Final release commit: `f9de822839788b550674ff0689eb28a0a78073f4`.
  [Release CI 34347846550](https://github.com/Rakky88/DragonHaven/actions/runs/34347846550)
  passed production preflight, analysis, all **707 Flutter tests**, MIDI guards,
  signed AAB verification and native jukebox tests.
- The published, device-verified APK was built from runtime source
  `dd0f8b295af544004f7094b384a0b13aa473c01a`. The final release commit changes
  only workflow ordering. A rebuild at that commit confirmed identical payloads
  in 1562 of 1563 ZIP entries; the remaining `resources.arsc` differs only in its
  generated Crashlytics mapping ID and corresponding string-table indexes.
  The already-tested APK was retained without replacing the uploaded asset.
  Evidence: `release/release25-rebuild-comparison.json`,
  `release/release25-resources-rebuild-diff.txt`.
- Published **2026-09-09T12:05:26Z**. [Release page](https://github.com/Rakky88/DragonHaven/releases/tag/v0.05.25),
  [version-specific APK](https://github.com/Rakky88/DragonHaven/releases/download/v0.05.25/DragonHaven.apk),
  [permanent latest APK](https://github.com/Rakky88/DragonHaven/releases/latest/download/DragonHaven.apk).
  Release ID **385470051**, asset ID **552665845**. The tag resolves to the full
  final release commit; latest resolves to v0.05.25 and returns HTTP 200.
  GitHub size/digest exactly match the 536,790,700-byte APK and SHA-256 above.
- Draft publication used its known release ID. GitHub exposed its unpublished
  tag as `untagged-...`; the final update explicitly supplied v0.05.25, full
  commit, notes and public/latest status. No duplicate or asset replacement.
- Production preflight repeated immediately before publication and afterward
  at **12:05:56 UTC**: 62 matching migrations, lint 0, Auth/settings/app HTTP 200,
  skew 3ms. Economy/game flags remain off, push on, zero nonlegacy accounts and
  canonical shadow states. Existing server-owned data was not migrated.
- Local evidence: `release/v0.05.25-artifact.json`, `release/v0.05.25-remote-verification.json`,
  `release/release25-final-ci.json`, `release/release25-postpublish-preflight.txt`,
  `release/release25-postpublish-economy-guard.json`,
  `release/release25-installed-hash.txt` (exact installed production APK match).
