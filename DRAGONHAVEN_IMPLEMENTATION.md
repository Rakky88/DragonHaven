# DragonHaven implementation record

This file maps the supplied specification to v0.00.08. It is an implementation
reference, not an instruction source.

## Local game foundation

- First launch asks for a keeper name and creates one hidden, fixed Common
  Starter Egg with a separate 5% Spectral roll.
- A live `HH:MM:SS` countdown shows the exact remaining part of the first
  24-hour incubation. Later eggs store one immutable 2–14-day duration.
- Tapping the egg reveals a fixed, non-spoiling hint based on affinity and both
  alignment axes. The contained dragon is never rerolled.
- Life stages are Egg, Hatchling, Wyrmling and Ascended. Might, Arcana and
  Spirit select three separate final forms.
- The catalog contains 42 families with the 20/10/6/3/2/1 rarity distribution,
  216 logical appearances including secret Sinister art, silhouettes for unseen
  forms and a separate Spectral Draconomicon collection.
- Personality metadata rolls once at hatch from 24 hidden traits using the
  requested 75% one-trait / 25% two-trait rule and incompatible pairs.

## Content and economy

- 300 Short, 200 Long, 200 Group and 100 Special Adventure definitions.
- Short slots refill one per complete hour; Long slots refill after local
  midnight. Special and Sinister sources expire after 48 hours.
- Six chest tiers have separate artwork, reward rules and reveal sounds.
- All 27 released-dragon maturity/alignment tables, persistent visits,
  25/40/60% room damage, repair prices and three Dragon Ward levels are stored.
- 200 purchasable raster furniture items use 24 validated atlases plus eight
  standalone sprites. Coins and gems remain separate currencies.

## Tower and presentation

- Rooftop Nest plus up to 20 floors, with eight visually distinct room types.
- Seven local-time rooftop states and room-specific base/day/night scenes blend
  through centrally configured 20-minute transition windows. Dawn, Morning,
  Golden Hour and Dusk add their own layered atmosphere rather than one flat
  global tint.
- Idle dragons use staggered active/resting/sleeping states, explicit 65/35
  room preferences and cosmetic 5% preferred-room interactions with a stored
  12-hour cooldown. “Call dragon” uses a calm 3.2-second walk.
- Transparent-bound regression tests cover every dragon, furniture and chest
  crop; resolution/uniqueness tests cover every room and rooftop state.
- Launcher icon and Android splash retain a solid white background.

## UI, settings and release

- Egg phase has no bottom navigation. After hatching the five destinations are
  Adventure, Dragon Tower, Friends, Stash and Shop.
- The overflow contains Account Info, Language and Achievements. The optically
  centered, enlarged logo opens About DragonHaven.
- About has a pinned drag handle, pull-past-top dismissal, a premium branded
  hero, Rick Groot, 2026, v0.00.08, redeem, update/share and Ko-fi controls.
- Language uses the same pinned pull-to-dismiss sheet and lists visible
  language names alphabetically.
- Achievements use one continuous list plus a persistent icon-only compact
  mode. All 20 badges have distinct artwork; locked badges are black
  silhouettes and unlocked badges reveal their full colors.
- Android milestone notifications name newly unlocked achievements and
  evolutions when the app is not in the foreground.
- All long pages and dialogs have explicit scroll behaviour and compact-phone,
  large-text coverage.
- Hatch, evolution and achievement presentations use one persisted queue:
  hatches (including mandatory naming) are first, evolutions follow oldest
  dragon first, and spinning achievement reveals are always last.
- Music and Sound Effects are independent, immediate and persistent. Android
  bundles four calm CC0 ambient loops and 19 distinct event sounds, uses gentle
  fades, restarts safely after audio-focus loss and respects app backgrounding.
- English is the first-install default. All nine selectable languages cover
  fixed UI, notifications, achievements, 800 generated Adventures, 200 shop
  items, egg clues, room interactions and all 300 dragon sayings.
- The permanent update asset is
  `https://github.com/Rakky88/DragonHaven/releases/latest/download/DragonHaven.apk`.

## External-service boundary

These features require authenticated server or store infrastructure and are not
faked locally:

- friends, friend achievements, visits, trades and cross-device account sync;
- globally shared Group Adventure participation/instances;
- real-money Google Play gem products and server-side receipt validation.

The local collection game, offline economy and all content required to connect
those services later remain data-driven and functional without them.

## Verification

- `dart analyze lib test`: clean.
- `flutter test --no-pub`: 76 tests pass.
- Android 17 integration route: passes on `emulator-5554`.
- Signed release: package `nl.dragonhaven.app`, version `0.0.8+10004`, APK
  Signature Scheme v2 verified with the permanent Rick Groot certificate.
- Release APK SHA-256:
  `59c9370452e34ea8c400e1fb1e8db854da65b34351fd2c0f5d82cc64e92c3743`.
