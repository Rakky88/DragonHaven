# DragonHaven v0.03.02

## Incubation artwork and portraits

- Corrected all Rooftop Nest incubation views to use one purpose-built,
  transparent egg-in-woven-nest sprite instead of two overlapping layers.
- Standardized circular portrait rendering across Friends, Account and portrait
  reveals with a hard circular crop and consistent artwork scale.

## Trial presentation upgrade

- Added animated D, C, B, A, S and S+ rank crests to the Trial result reveal,
  with the earned coins, XP, stat points and chest shown directly underneath.
- Cavern Flight now uses illustrated stalactite and stalagmite obstacle sprites.
- Ruin Breaker now uses an ornate reaction meter with clearly marked Good and
  Perfect timing zones.
- Runeweaver now uses five unique rune sprites plus a distinct illuminated
  sprite for every rune.
- Added matching Cavern Flight, Ruin Breaker and Runeweaver record icons across
  Trial offers, dragon selection, live scores and every high-score overview.
- Fixed completed Trials briefly becoming "unavailable" before their result
  screen could appear.

## Friends and trades

- Account and favorite-dragon Trial records in friend profiles now start
  collapsed and can be expanded independently.
- Every friend row now has a prominent direct Trade button at its right edge,
  including an active-trade badge when a response is waiting.
- Finalized trades now queue a persistent animated exchange reveal for both
  players, showing the item sent and the item received.

## Release reliability

- Verified local and remote Supabase migrations, remote schema linting, Auth
  health and e-mail authentication configuration before publishing.

Existing local progress and online account data remain intact when updating.
