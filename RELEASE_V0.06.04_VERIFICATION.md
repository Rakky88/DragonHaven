# DragonHaven v0.06.04 / 10097 verification

## Scope

This release completes the responsiveness follow-up after v0.06.03. Eligible
solo Adventure starts, claims and cancellations use the same bounded optimistic
queue as other deterministic actions. The preview contains only public facts:
the selected dragon, visible offer, server-time-anchored duration and removal of
a claimed run. Chest tier, XP, expertise, evolution and all random outcomes wait
for the authoritative receipt. Rejection rebases or rolls back the preview;
lost replies retain only the sent durable request for exactly-once recovery.

The server-owned social allowlist now admits the existing Aerie contribution
RPC and world/friends/Conclave ranking reads. No gameplay inventory authority is
returned to the social provider. Ranking sheets retry when a silent background
social operation is still settling. Chest reveal supplies a safe default sound,
while Special Chests retain their event-specific sound.

The disabled ad previews moved from Chests to Buy and now show `Free gems` (5)
and `Free coins` (50), with `Watch an ad 3/3`. They still dispatch no command and
grant no currency until the separately documented AdMob and server verification
work is complete.

## Validation

- Focused Adventure, Shop, social and v0.05.41 parity tests: 111 passed.
- Full Flutter suite: 1,108 passed and 1 asset-review test skipped. One
  parallel school-art test observed shared visual state; the complete
  three-case file passed immediately in isolation. Its wait allowance now
  matches the transport's existing ten-second deadline so filesystem load
  cannot make the release gate fail after only 1.5 seconds.
- Android integration exercise for Tower rooms, the nest and Draconomicon:
  passed on the emulator.
- Flutter analysis: no issues in 104.5 seconds.
- Compact-width visual review: the Coin and Gem Buy tabs were rendered at
  320 dp with animations disabled. The currency packs and disabled Free coins
  / Free gems cards remain readable, scrollable and free of overflow.
- Version, updater and startup checks confirm `0.06.04` / build `10097`.

## Server boundary

No migration, Edge Function, ruleset, runtime flag, minimum-build change or
player-data rewrite is required. The Aerie and ranking failure was a client
allowlist regression: the valid RPCs were rejected before reaching Supabase.
Production health and migration parity are rechecked before and after release.

The preflight found 93 matching migrations, zero database lint errors, HTTP
200 from Auth health, Auth settings and `dragonhaven_public_health`, and
application contract version 1. Runtime inspection confirmed server-owned
gameplay and migrations are enabled, legacy mutations and all shadow paths are
disabled, and the minimum supported build remains 10092. No server deployment
or runtime change was made.

## Artifact and publication

Pending final build and publication verification.
