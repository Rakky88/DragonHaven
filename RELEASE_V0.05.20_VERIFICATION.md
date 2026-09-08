# DragonHaven v0.05.20 / 10070

Publication in progress, 8 September 2026. Feature source: `4884cec`.

## Server

- Exact migration/contract source verified against successful staging run
  [34254991384](https://github.com/Rakky88/DragonHaven/actions/runs/34254991384).
- `tool/production_dormant_57.py` applied only migration 57 after all six
  game/import/read/receipt/ruleset/recovery contracts passed in a rollback-only
  transaction. All six passed again after application; no synthetic data remains.
- Production preflight at 18:23:52 UTC: exact migrations 1–57, lint 0,
  Auth health/settings and application health HTTP 200.
- All accounts remain `legacy_client`, economic mutations and game worker off,
  zero canonical game copies. The complete game runtime and existing enabled
  production push switch are unchanged. No live game saves were imported.
- No paid services or billing account were enabled.

## App

- All visible/runtime version sources incremented one step: v0.05.20 / 10070.
  The version regression now checks the build number against pubspec as well.
- Event themes/countdown, Expertise highlights and shared inspection, compact
  Draconomicon shortcuts, permanent dragon sex and ordinary test Trial rewards.
  See `EVENT_THEME_AND_TRAINING_VERIFICATION.md` for gameplay and visual evidence.
- Historical Special Adventure and preview Special Chest exclusions remain;
  the reward policy change applies to event Trials only.

Artifact, emulator and final publication verification will be recorded below.
