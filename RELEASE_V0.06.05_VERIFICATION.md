# DragonHaven v0.06.05 / 10098 verification

## Scope

This release restores the remaining v0.05.40 presentation details requested
after v0.06.04: the Rooftop Nest egg picker, direct Inventory Egg tagging,
selected-dragon actions, Adventure refresh countdowns, Tower alignment and
spacing, My Dragons sheet height and contained dragon artwork.

All gameplay data remains canonical. Egg tags, collection preferences and nest
placement use the existing optimistic command queue and roll back on refusal.
Adventure refresh uses the real offer boundary and confirmed server time.
Random outcomes, rewards, hidden Egg facts and hatching remain server-owned.

## Validation

- Version, updater and startup checks target `0.06.05` / build `10098`.
- Flutter analysis, full tests, server preflight, signed artifact verification,
  device review and publication evidence are recorded below as they complete.

## Server boundary

No migration, Edge Function, ruleset, runtime flag, minimum-build change or
player-data rewrite is required. Production migration parity, database lint,
Auth endpoints and application health are mandatory before and after release.

## Artifact and publication

- Intended tag: `v0.06.05`.
- Intended public asset: `DragonHaven.apk`.
- Permanent latest APK:
  https://github.com/Rakky88/DragonHaven/releases/latest/download/DragonHaven.apk
