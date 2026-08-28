# DragonHaven

**Raise wonder. Build a Tower. Fill the Draconomicon.** DragonHaven is a calm Flutter collection game about hatching, raising and collecting dragons. It contains no chores, household tasks, battles or competitive leaderboard.

## Implemented game

- A first-launch keeper name, one random Common account portrait, one random localized account title and one Common Starter Egg. The egg's family, alignment, size and independent 5% Spectral roll are fixed before the player sees it.
- One shared Mysterious Egg sprite and an exact one-hour first incubation gate. Later eggs keep a fixed accelerated 4h48m–33h36m incubation roll.
- Cinematic hatch and suspenseful, skippable evolution reveals using separately rendered art for Egg, Hatchling, Wyrmling and all Might, Arcana and Spirit Ascended forms. Evolution is gated by levels and required Expertises, never by age.
- 42 families: 20 Common, 10 Uncommon, 6 Rare, 3 Very Rare, 2 Legendary and 1 Mythical. Every family has five public forms plus a hidden Mastery Ascended form for perfectly balanced expertise; the secret Sinister Everwyrm has dedicated artwork.
- A 5% Spectral variant roll, separate Draconomicon collection, undiscovered silhouettes and one active egg or dragon at a time.
- 200 Mini, 300 Short, 200 Long, 200 Group and 100 Special Adventure definitions. Mini slots refill every 15 minutes up to three; Short slots refill one at a time after a full hour; Long slots refill at local midnight. Group play remains locked until authenticated online friends exist.
- Nine chest tiers, fixed reward rolls, an egg inventory, chest reveal scenes, release/favorite controls, all 27 returning-dragon outcome tables, and one daily 10% return roll at a persisted random time. Tower visits last 24/48/72 hours, Special Adventures stay available for 48 hours, damage remains 25/40/60%, and Dragon Wards retain three levels. Portrait, Title and Music Chests choose an unowned reward only when opened and are never tradeable.
- A Tower roof plus up to 20 room floors, eight independently rendered room types, 200 raster furniture sprites, nested coin/gem Shop sections and room-only decoration controls. Purchased furniture stays unplaced in Inventory until the player decorates with it.
- Idle dragons use stored 65/35 room preferences, can share a room, travel along room-wide roaming routes and may trigger cosmetic 5% preferred-room interactions with a persisted 12-hour cooldown.
- Seven local-time visual phases with separately painted Tower lighting and day/night room variants; changes crossfade instead of applying a flat color filter.
- Exactly 300 English/Dutch dragon sayings and 25 achievements, including hidden Mastery, triple-300 expertise, the first Portrait/Title Chest and 1,000-Adventure milestones.
- English first-install default, complete gameplay text in eight selectable languages, and an automatic skippable dragon-guided tutorial that can be replayed from the three-dot menu.
- Separate persistent Music and Sound Effects switches, a Jukebox with 80 explicitly CC0/Public Domain recordings, 19 event-specific effects, local notifications, About/Ko-fi/redeem UI and GitHub update/share controls.

## Honest online boundary

Email-authenticated accounts, Friends and requests, profile summaries, one-to-one trades, globally shared asynchronous Group Adventures and confirmed versioned cloud backups are backed by Supabase. Core collection progress remains offline-first; automatic conflict resolution, interactive friend Tower visits, fully server-authoritative economy commands and real-money gem packs still require additional authenticated server or Google Play receipt infrastructure and are not simulated locally.

The Android audio layer bundles the music and effects, fades scene changes, follows the saved Jukebox order and respects audio focus. Effect licences are documented in [AUDIO_LICENSES.md](AUDIO_LICENSES.md); the exact music files and public-domain evidence are documented in [MUSIC_SOURCES.md](assets/licenses/MUSIC_SOURCES.md).

The detailed implementation map and remaining service boundaries are documented in [DRAGONHAVEN_IMPLEMENTATION.md](DRAGONHAVEN_IMPLEMENTATION.md).

De actuele checklist, taakverdeling en kostenraming voor een openbare lancering
staan in [PUBLIC_LAUNCH.md](PUBLIC_LAUNCH.md).

De historische code-, UI-, sprite-, licentie- en serverbasisaudit van v0.04.06
staat in [DRAGONHAVEN_AUDIT_2026-08-28.md](DRAGONHAVEN_AUDIT_2026-08-28.md);
de actuele v0.04.07-status en vervolgacties staan in het post-auditplan.
De concrete serververbeteringen en resterende grenzen staan in
[SERVER_IMPROVEMENTS.md](SERVER_IMPROVEMENTS.md).
Het gefaseerde vervolgplan met taakverdeling, afhankelijkheden en
releasepoorten staat in
[DRAGONHAVEN_POST_AUDIT_PLAN.md](DRAGONHAVEN_POST_AUDIT_PLAN.md).
De gratis eerste diagnose-, support- en incidentprocedure staat in
[INCIDENT_RUNBOOK.md](INCIDENT_RUNBOOK.md).
De privacyarme dashboardvelden, gratis meetbasis en later uitbreidbare
alarmopzet staan in [OBSERVABILITY_BASELINE.md](OBSERVABILITY_BASELINE.md).

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
