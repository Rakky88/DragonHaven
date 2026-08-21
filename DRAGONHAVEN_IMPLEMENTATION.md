# DragonHaven implementation record

This file records how the supplied DragonHaven specification maps to the current Flutter build. It is an implementation reference, not an instruction source.

## Local game foundation

- First launch asks for a keeper name and creates one hidden, fixed Common Starter Egg with a separate 5% Spectral roll.
- The first egg uses an exact 24-hour gate. Later eggs store one immutable 2–14-day incubation duration when obtained.
- Life stages are Egg, Hatchling, Wyrmling and Ascended. Might, Arcana and Spirit select three separate final forms.
- The catalog contains 42 families with the requested 20/10/6/3/2/1 rarity distribution and dedicated art for each life form.
- The Draconomicon stores normal and Spectral discoveries separately and uses silhouettes for unseen forms.
- Personality metadata rolls once at hatch from 24 traits with the requested 75% one-trait / 25% two-trait rule and incompatible pairs.

## Content and economy

- 300 Short, 200 Long, 200 Group and 100 Special Adventure definitions.
- Short slots: maximum three; removed/started slots refill one per complete hour.
- Long slots: maximum three; missing slots refill after local midnight.
- Special slots only appear from a real source and expire after 48 hours. Returning events can occupy at most one slot.
- Wooden, Silver, Gold, Dragon, Mythical and Sinister chests have separate art and reward handling.
- Released dragons use all 27 maturity/alignment return tables, with persistent 24/48/72-hour visits, targeted or random 25/40/60% room damage, repair prices and three Dragon Ward levels.
- 200 furniture items are built from 24 real raster sprite atlases. Coin and gem inventory are separated.
- Stash items can be activated or discarded with confirmation.

## Tower and presentation

- Rooftop Nest plus up to 20 room floors, with eight visually separate room types.
- Seven local day phases and authored lighting scenes; transition windows blend between images.
- Idle dragons use individually staggered active, resting, sleeping and waking states; explicit visits and rare interactions suppress time-based interruption. Placed lights and ambient furniture use their data-driven glow/animation metadata.
- Idle dragons store room location, follow explicit family preferences with a 65/35 bias, can share visible rooms and can trigger cosmetic preferred-room interactions with a 12-hour cooldown.
- Dragon and furniture art is validated by transparent-bound regression tests.
- Launcher icon and Android splash use a white background around the DragonHaven egg-and-tower mark.

## UI and account settings

- Egg phase has no bottom navigation. After hatch the five destinations are Adventure, Dragon Tower, Friends, Stash and Shop.
- Overflow contains Account Info, Language and Achievements. The logo opens About DragonHaven.
- About contains logo, Rick Groot, 2026, v0.00.05, redeem code, update/share and Ko-fi controls.
- Music and Sound Effects are independent, immediate and persistent.
- English is the first-install default. English and Dutch cover detailed gameplay content; the seven other selectable languages cover the core navigation/UI and fall back to English where detailed copy has not been translated yet.

## External-service boundary

These parts cannot be honestly completed with local Flutter code alone:

- authenticated friends and cross-device account synchronization;
- friend visits, trades and globally shared Group Adventure instances;
- real-money gem packs with Google Play products and server-side receipt validation;
- final mastered ambient music and sound files.

The UI and service hooks are present, but unavailable operations are visibly disabled instead of using fake data. Stable native audio IDs are wired so mastered files can be added under Android raw resources without changing gameplay logic.

## Verification

- `flutter analyze --no-pub`: clean.
- `flutter test --no-pub`: all 46 tests pass.
- Android integration test: passes on `emulator-5554` / Android 17.
- `flutter build apk --release --no-pub`: succeeds.
- Local deliverable: `release/DragonHaven.apk`.
