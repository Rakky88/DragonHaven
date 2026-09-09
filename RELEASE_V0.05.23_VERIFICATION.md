# DragonHaven v0.05.23 verification

Status: release candidate under verification. Updated 9 September 2026.
Target: app/display **0.05.23**, pubspec **0.5.23+10073**, Android **10073**.
Production migration 60 is applied and healthy. Publication is pending final
artifact verification and the release workflow.

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
- Undiscovered Draconomicon families, silhouette medallions and form tiles keep
  pale parchment/lavender backgrounds, independent of dark event panel colors.
- Compact Special-adventure offers omit the duplicate availability timer, leaving
  room for the title and Expertise. The global banner and full details retain it.
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

## Staging and production

- Staging run [34326484098](https://github.com/Rakky88/DragonHaven/actions/runs/34326484098)
  passed analysis, the full Flutter suite, 15 Edge tests, VM/Deno domain parity
  (990948-byte bundle), six canonical rollback contracts and the event-stop
  contract before and after application. The real SDK/UI probes cover purchases,
  chest replay, tags, Altar, crafting, dragons, adventure recovery, house and
  training preferences. Both synthetic accounts were removed; worker disabled.
  Final staging preflight: **08:06:32 UTC**, schema **60**, lint **0**, HTTP **200**.
- The first staging run applied 60 then stopped at an outdated validation-script
  baseline. The six exact baseline allowlists now also accept schema 60; the
  successful run above repeats all checks. No gameplay rule was bypassed.
- Production dry run contained only `202609090060_end_active_event.sql`.
  Applied exactly that migration. Mandatory preflight at **08:08:25 UTC**:
  schema **60**, lint **0**, Auth/settings/application **HTTP 200**.
  Before/after guards confirm all accounts remain legacy, zero shadow states,
  game/economy mutations disabled and push enabled. No gameplay balances edited.

## Android inspection

Actual API 37 emulator captures in `release/event23-device-*.png` cover the four
new game introductions/boards, normal Tower/Academy artwork, Christmas chat
contrast, all-three-expertise Trial cards/picker, birthday/default transition,
and 320dp/1.35 text scale with system animations disabled. Controls remain usable.
Clean standalone Valentine/Pride introduction icons were checked in the rebuilt
preview after finding old sprite-cutout remnants. Preview saves are nonpersistent;
the final production update must preserve the original saved game.

The Draconomicon addition passed all eight existing visual/bounds, locked-form
and reference checks; Android family overview and expanded silhouettes were
visually checked after loading. The compact Special-card change passed 19
existing screen/reference checks, including the live timer in full details.
The broader canonical economy remains staging-only; this release performs no
production worker or account cutover.
