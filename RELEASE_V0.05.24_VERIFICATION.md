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

No reward, timing, random, server-contract or migration changes. Production
remains on schema 60 with the canonical economy disabled.

## Evidence

- All six event picker regressions and the existing training/UI checks pass:
  17 tests. These cover visible scores, all/partial/no highlights, total-versus-
  single-score ordering, MAX display data, and opening info without starting.
- Release analysis, full CI, device inspection, signing, server preflight and
  publication evidence will be recorded after completion.
