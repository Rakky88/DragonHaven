# v0.05.27 / Android 10077 verification

Candidate prepared 9 September 2026. Publication and artifact verification are
recorded below when completed; v0.05.26 remains the public latest meanwhile.

The user approved the twelve Solmanta/Ciderhorn sprites, the complete festival
contract, and publication. Sunwake and Harvestmoon include their own calendar,
Special Adventure, versioned chest/egg, six dragon forms, hatch achievement,
podium emotes, original music/effects, app/launcher theme and distinct Trial.
The shared Conclave decorations use verified completions without economic grants.
Christmas S+ is 7,500; birthday S+ is 10,000 with one miss ending each run.
The starter egg hatching screen no longer offers the Egg Altar shortcut.

## Completed checks

- Full local regression: **738 tests passed**, Flutter analysis: **no issues**.
- Reference documentation verification and all six reference tests passed;
  dormant chest catalog v3 exactly matches its SQL source.
- Shared Dart/JavaScript parity passed; **21 Deno worker tests passed**.
- Both new games fit 320x640 at normal and 1.35 text scale/reduced motion.
  Surf collision outcomes match 30/60/120 FPS; twenty seeds remain navigable.
  Orchard rotation, bounds, complete-row harvesting and three-basket stopping
  pass; birthday ends on the first miss.
- Full new-event Adventure-to-Chest-to-Egg-to-Hatch tests pass, including expiry,
  once-only rewards, 24-hour minimum, exact chest contents and achievements.
  Spectral hatchlings now count toward seasonal hatch achievements too.
- All sprite containment checks pass. The original catalog order and ordinary
  42-family drop pool remain intact; totals are 51 families, 40 achievements and
  161 emotes. Approved dragon art is copied without changing its bytes.
- Migrations 64 and 65 were independently rehearsed with rollback, applied and
  rechecked on staging. Eight event/canonical economy contracts and podium-chat
  validation pass; synthetic fixtures are rolled back.
- Production was upgraded from exactly 63 to 65 migrations. Mandatory preflight
  confirms 65 exact matches, lint 0 and Auth health/settings/application HTTP 200.
  Economy/game mutation switches remain off, push remains on, authority remains
  legacy and canonical state remains empty. No player inventory migration ran.

Artwork provenance: `future_event_art/dragon_families/sunwake_harvestmoon/`.
Original music source and PCM verification: `future_event_art/music/`.
Operational code values and announcements are excluded from public release notes.
