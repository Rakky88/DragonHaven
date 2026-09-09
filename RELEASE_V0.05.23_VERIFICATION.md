# DragonHaven v0.05.23 verification

Status: release candidate under verification. Updated 9 September 2026.
Target: app/display **0.05.23**, pubspec **0.5.23+10073**, Android **10073**.
No publication or production migration has occurred yet.

## Scope and rules

- Account-scoped event stop, including active official calendar editions and
  personal previews. Authenticated, verified owner only; no direct dismissal
  table access. An explicit new preview can start afterward. Future annual
  editions and already started adventures/attempts survive.
- Calendar dismissal is saved/synchronized and also filters native branding
  and event notifications. Event-specific music disappears with its entitlement.
- Collapsed Tower floor and Academy art keeps its normal translucent overlay.
  Valentine uses rose pink/blush paper; personal-chat buttons use pale backgrounds
  and dark ink. Countdown layout measures inherited fonts/text scale, clips the
  test label first, removes it next, and only then wraps the official content.
- Event cards/pickers use all three Expertises. All three highlights are required
  for their highlighted group; standard Trials retain their single focus.
- One deterministic initial refill per event occurrence, preserving occupied slots.
  Subsequent normal refills retain the four-kind 25% distribution.
- Christmas conveyor delivery, New Year rhythm lanes, paired Valentine maze and
  Pride prism circuits replace the old shared phases. Halloween's seeded pumpkin,
  trace, timing, mistake and grading behavior is unchanged.
- New boards use server-derived seeds, solvability checks, per-board credit
  tracking, bounded generation, full timers, 30-point mistakes and server-compatible
  count/score caps. Reward tables and published grade thresholds are unchanged.
- Original Jingle Bells synthesis: 73.21s PCM; no imported recording or samples.
  Composition source/rights recorded in `assets/licenses/MUSIC_SOURCES.md`.

## Evidence collected so far

- Dart analysis of lib/test/tool: clean.
- 500 paired mazes and 500 prism circuits: solvable, varied, no initial circuit win
  and no repeated credit. Highlight, activation, stop and launcher-schedule tests pass.
- Actual widget gestures: correct/wrong/expired parcel, timed/missed chime, maze
  completion, prism completion and banner truncation/removal/wrap pass.
- Existing seasonal system and Witchlight visual/mechanical tests pass.
- Schema 60 rehearsed on registered staging while schema 59 remained installed:
  authenticated scoping, invalid/unverified refusal without mutation, idempotent
  stop, calendar suppression, preserved started attempt, explicit restart and
  other-owner isolation. All synthetic rows and DDL rolled back.

## Remaining release gates

Full suite and staging integration; full-screen Android visual inspection;
production exact-schema/health checks and migration; signed production build;
artifact signature/version/hash and publisher verification. The broader canonical
economy remains staging-only; no production worker or account cutover is authorized
by this feature release.
