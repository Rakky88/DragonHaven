# DragonHaven v0.05.24 verification

Status: candidate under verification, 9 September 2026.
Target display **0.05.24**, pubspec **0.5.24+10074**, Android **10074**.

## Correction

v0.05.23 corrected seasonal Trial selection, but the shared Special Adventure
picker still displayed and ranked a single focus. It now shows all three
Expertises with individual scores, MAX markers and the player's highlight glow.
Only all-three-highlighted dragons enter the marked section. Each section sorts
by total Expertise, then the existing recommendation/acquisition tie-breakers.
Sorting happens inside the picker so offers, details and Valentine invitation
acceptance use the same behavior. Ordinary Adventures keep their focus rules.

## Event game revision

- Halloween now alternates pumpkin memory and tracing, with no Might timing game.
  New individual wisp/lantern sprites pulse and hover. Finger movements leave
  gently twinkling mint-and-gold sparkles, static with reduced motion.
  The path stays black, seeded, equal length and strictly validated.
- Christmas accelerates and ends after three mistakes; New Year accelerates,
  adds two-note chords at 22s and more often at 45s, and stops on three mistakes.
  Four original C5/D5/E5/G5 effects play through a polyphonic native SoundPool.
- Valentine and Pride retain their approved gameplay, receive illustrated
  hearts/roses/prisms, and have adjusted rank cutoffs: S+ at 5500/10000.
- All new instructions have translations in the eight supported languages.
- Migration 61 extends the existing early-finish exception to Christmas/New Year,
  requires exactly three mistakes, rejects nulls and keeps old full runs valid.
  The canonical economy remains disabled.

Artwork paths, generation mode and prompts: `assets/licenses/TRIAL_ART_SOURCES.md`.
Audio generation: `tool/build_firstlight_notes.dart`, `assets/licenses/MUSIC_SOURCES.md`.


## Evidence

- All six event picker regressions and the existing training/UI checks pass:
  17 tests. These cover visible scores, all/partial/no highlights, total-versus-
  single-score ordering, MAX display data, and opening info without starting.
- Full staging CI [34335950993](https://github.com/Rakky88/DragonHaven/actions/runs/34335950993)
  passed on e815f0b9106f232250470018ddddd07b06ca2766, including analysis, 701
  Flutter tests, Deno/server contracts, canonical worker/client/recovery probes
  and synthetic-data cleanup. Release CI 34337273320 also passed on that source.
  The subsequent sparkle-only UI revision receives its own final release checks.
- Device inspection covered the revised games at normal width and 320dp with
  1.35 text scale and reduced motion; the Halloween trace completed into the next
  memory round. The language list is alphabetized; Dutch survives restart and
  English was restored. Update installation preserved Quietstar and balances.

- Focused interaction tests validate two-finger chords, all four audio IDs,
  bounded acceleration, exact grade boundaries, three-strike endings and two
  successive Halloween memory/trace cycles. Existing trace tests still pass.
- Original waveforms checked: 523.23 / 587.31 / 659.23 / 783.96Hz, 0.60s mono
  44.1kHz 16-bit PCM, no clipping.
- Staging rollback contract passed for migration 61, including ownership, null
  and wrong tokens, null/invalid scores and counts, expiry, elapsed bounds,
  one-use submission, old-client completion and preserving existing bests.
  The rollback rehearsal removed its fixtures. Migration 61 was then applied
  successfully to staging and production. Production preflight at 09:53 UTC
  confirmed 61 matching migrations, zero lint errors, Auth/settings/app HTTP 200.
  Economy and game workers remain disabled in production, with zero nonlegacy
  accounts or shadow states. Final artifact/publication evidence follows below.
