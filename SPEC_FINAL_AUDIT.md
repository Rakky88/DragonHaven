# DragonHaven v0.00.08 — final specification audit

Audited against
`DragonHaven_Codex_Spec_With_Achievements_Rooms_Personalities_DayNight_Audio_Two_Sliders.md`
on 22 August 2026.

## Completed local scope

- fixed Common Starter Egg, independent 5% Spectral roll, immutable identity,
  exact 24-hour gate, live countdown and tap-for-hint interaction;
- Egg → Hatchling → Wyrmling → Ascended progression with three trained paths;
- 42-family 20/10/6/3/2/1 rarity distribution, 216 logical artworks, unseen
  silhouettes, separate Spectral collection and secret Sinister artwork;
- 24 hidden personality traits with incompatibilities and stable persistence;
- 800 Adventure definitions with duration/reward constraints and Sunday 12:00
  Europe/Amsterdam Group-instance timing;
- six chest tiers, stash, rewards, 27 returning-dragon tables, visits, damage,
  repairs, Dragon Wards and 48-hour Special/Sinister sources;
- 20 humorous bilingual achievements with unique badges and Common-family
  counters that exclude rarer families;
- Rooftop Nest, 20 buildable floors, eight distinct rooms, 200 purchasable
  sprites, data-driven movement/preferences/interactions and seven time phases;
- cinematic hatch/evolution/chest presentations, a persisted priority queue,
  oldest-first evolution reveals, spinning achievement reveals and Android
  music/SFX with two independent persistent switches;
- English default and complete authored text for all nine requested languages,
  including generated content, notifications and 300 dragon sayings;
- About/redeem/Ko-fi, permanent share/update link, white launcher/splash,
  improved topbar branding and robust scrolling/dismissal behaviour.
- a centered animated egg countdown, one uncategorized achievement list with
  persistent list/compact modes, 20 unique color badges with black locked
  silhouettes, and background-only achievement/evolution notifications.

## Intentionally requires external infrastructure

- authenticated friends, friend achievements, Tower visits, trades and account
  synchronization;
- real shared multiplayer Group Adventure participation;
- real-money Google Play gem packs and receipt validation.

Those operations are visibly unavailable instead of inventing fake users,
payments or cloud state. Their screens/data boundaries remain ready for a later
backend phase.

## Release gates

- no chore/task/leaderboard/battle save data or screens remain;
- automated bounds checks cover every dragon, furniture and chest sprite;
- compact 360×640 and 135% text-scale scroll/overflow regression is green;
- About pinned-handle scrolling and pull-to-dismiss regression is green;
- the Language sheet uses the same pinned-handle/pull-to-dismiss behavior and
  presents all visible language names alphabetically;
- release uses the permanent `nl.dragonhaven.app` ID and signing key.
