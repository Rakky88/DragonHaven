# DragonHaven

**Raise wonder. Build a Tower. Fill the Draconomicon.** DragonHaven is a calm Flutter collection game about hatching, raising and collecting dragons. It contains no chores, household tasks, battles or competitive leaderboard.

## Implemented game

- A first-launch keeper name and one Common Starter Egg. Its family, alignment, size and independent 5% Spectral roll are fixed before the player sees it.
- One shared Mysterious Egg sprite and an exact 24-hour first incubation gate. Later eggs keep a fixed 2–14-day incubation roll.
- Cinematic hatch and evolution reveals using separately rendered art for Egg, Hatchling, Wyrmling and all Might, Arcana and Spirit Ascended forms.
- 42 families: 20 Common, 10 Uncommon, 6 Rare, 3 Very Rare, 2 Legendary and 1 Mythical. Every family has five distinct logical forms; the secret Sinister Everwyrm has dedicated artwork.
- A 5% Spectral variant roll, separate Draconomicon collection, undiscovered silhouettes and one active egg or dragon at a time.
- 300 Short, 200 Long, 200 Group and 100 Special Adventure definitions. Short slots refill one at a time after a full hour; Long slots refill at local midnight. Group play remains locked until authenticated online friends exist.
- Six chest tiers, fixed reward rolls, an egg stash, chest reveal scenes, release/favorite controls, all 27 weekly returning-dragon outcome tables, Tower visits, 25/40/60% damage and three Dragon Ward levels.
- A Tower roof plus up to 20 room floors, eight independently rendered room types, 200 raster furniture sprites, coin/gem shop tabs and room-only decoration controls.
- Idle dragons use stored 65/35 room preferences, can share a room, roam on refresh and may trigger cosmetic 5% preferred-room interactions with a persisted 12-hour cooldown.
- Seven local-time visual phases with separately painted Tower lighting and day/night room variants; changes crossfade instead of applying a flat color filter.
- Exactly 300 English/Dutch dragon sayings and 20 humorous achievements.
- English first-install default, complete English/Dutch gameplay text and nine selectable core UI languages.
- Separate persistent Music and Sound Effects switches, native Android audio hooks, local notifications, About/Ko-fi/redeem UI and GitHub update/share controls.

## Honest online boundary

Friends, cross-device account sync, trades, friend Tower visits, shared Group Adventure instances and real-money gem packs require authenticated server state and Google Play product/receipt validation. The screens and service boundaries are present, but this repository deliberately does not simulate online people, purchases or synchronization locally.

The native audio layer has stable IDs and all important gameplay cues are wired. Final mastered music and sound files are not bundled yet; missing raw resources fail silently without affecting gameplay.

The detailed implementation map and remaining service boundaries are documented in [DRAGONHAVEN_IMPLEMENTATION.md](DRAGONHAVEN_IMPLEMENTATION.md).

## Run and verify

```powershell
flutter pub get
flutter analyze --no-pub
flutter test --no-pub
flutter build apk --release --no-pub
```

Regenerate the white adaptive launcher icon and splash resources after changing the DragonHaven logo:

```powershell
powershell -ExecutionPolicy Bypass -File .\tool\generate_android_branding.ps1
dart run flutter_launcher_icons
```

The permanent Android application ID is `nl.dragonhaven.app`. Every future release must keep this ID and use the same release key so updates install over DragonHaven correctly. Release instructions are in [DISTRIBUTION.md](DISTRIBUTION.md).
