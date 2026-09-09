# Birthday event and Christmas pacing verification

Reviewed 9 September 2026, after published v0.05.25 / build 10075.
Published in v0.05.26 / build 10076 on 9 September 2026.
Final release evidence: `RELEASE_V0.05.26_VERIFICATION.md`.

## Implemented

- Golden Wings has a reusable, authenticated, account-scoped preview (private
  value in `REDEEM_CODES.md`, never in public release notes).
- Wishcake Tower stacks and trims moving cake layers, accelerates, provides
  modest assistance from all three expertises, and ends at three misses or time.
  Perfect layers score 130 base points, ordinary placements 85, plus the shared
  combo; C/B/A/S/S+ cutoffs are 600/1500/2800/4200/6000.
- Ordinary Trial rewards, preview provenance and saved personal highscores use
  the established flow. The birthday Adventure, Chest and fixed egg contents
  retain their existing rewards and timetable. No new podium prize was added.
- Happy Birthday is an original synthesized instrumental of the public-domain
  1893 melody. The music source record and reproducible arrangement are in
  `assets/licenses/MUSIC_SOURCES.md` and `tool/build_birthday_song.dart`.
- Christmas uses a 35-second offset in both existing speed curves. Initial
  parcel spacing is 1.315s and travel time 2.65s plus Might help. Overlap,
  continuing acceleration, original speed floors and three-strike ending remain.
- The cake icon is original generated art. The missing Golden Wings egg path
  was also repaired with an actual birthday egg asset, hiding its contents.
  Generated originals were copied with their alpha channel intact. Full prompts,
  built-in generation method and final asset paths are recorded in
  `assets/images/events/golden_wings/ART_PROMPTS.json`.

## Calendar coverage

All dates use Europe/Amsterdam. Annual schedule from 2027:
New Year: 31 December 18:00 through 1 January;
Valentine: 14 February; birthday: 13 May; Pride: 1–7 June;
Halloween: 25 October–1 November; Christmas: 25–26 December.
The inaugural birthday was 1–2 September 2026.

There are no events on 2 January–13 February, 15 February–12 May,
14–31 May, 8 June–24 October, 2 November–24 December, or from
27 December until 31 December at 18:00. The summer/autumn gap is largest.

## Verification

- 40 targeted event/game/music/reference tests pass, including actual cake
  stacking, trimming, perfect-width recovery, same-drop repeat protection,
  three-miss completion, preview rewards, highscore round-trip and exact dates.
- Full regression run: 714 tests passed; one source-ledger assertion identified
  the missing raw-resource alias spelling. After that documentation fix, all
  40 tests in `dragonhaven_spec_test.dart` passed. All 715 distinct tests are
  covered; no product behavior was changed after the full run.
- Flutter analysis: no issues. Shared Dart/JavaScript parity passes. The 15
  Edge-worker core contracts pass. Production and staging economy switches
  remain disabled.
- A signed Android preview APK built successfully. It uses a nonpersistent
  local fixture; it is never a publishable release artifact. Native gameplay
  and the birthday icon/background were inspected on emulator-5554, API 37.
- Widget captures at 320 x 640 logical pixels cover normal and 1.35x text with
  reduced motion, intro, seven placed layers, confetti and end state. The
  birthday HUD retains its complete title. The reduced-motion feedback layout
  no longer relies on a zero-duration AnimatedSize.
- The new PNGs pass transparent-corner and edge checks with the full event
  asset suite. No opaque artwork is clipped at their image edges.
- Native audio playback shows mono 44.1kHz output, playing, fixed gain 1.0;
  the birthday alias is present in the Jukebox. The 80-track collection count
  remains unchanged. After a 20-second birthday preview expires, native output
  changes to the saved Reverie track (22.05kHz stereo), playing at gain 1.0.
  The event timer and gold theme disappear together.

## Server

Migration `202609090063_birthday_trial.sql` was first exercised in a rollback
transaction on isolated staging. Synthetic verified/unverified accounts cover
all six previews, same-expiry retries, owner isolation, calendar recurrence,
invalid game/token/score, too-early two-miss completion, three-miss completion
after event end, stored preview bests and duplicate rejection. Fixture rows are
rolled back. After staging apply, the contract passed again and lint was clean.

Production apply used the exact forward migration only. The pre/post guard
confirms economy_enabled=false, game_enabled=false, push_enabled=true,
nonlegacy_accounts=0 and shadow_states=0. Post-apply production preflight:
63 matching migrations, lint errors 0, Auth health 200, Auth settings 200,
application health 200; server time 2026-09-09T12:44:16.380Z, clock skew 16ms.
No inventory, reward, account-authority or worker-activation migration is part
of this update. Evidence: `release/birthday-production-preflight.txt`.

Local visual evidence: `release/birthday-visual/`,
`release/birthday-device-intro-ready.png`,
`release/birthday-device-playing.png` and its next animation frame,
`release/birthday-device-music-ready.png`.

After device verification, the exact published v0.05.25 APK was reinstalled
without uninstalling or clearing app data. The preview fixture is not shipped.
