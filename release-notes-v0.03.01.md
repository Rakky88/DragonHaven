# DragonHaven v0.03.01

## Rooftop Nest artwork

- Replaced the remaining combined egg-and-green-moss artwork with the existing
  standalone Mysterious Egg sprite.
- The Starter Egg, Tower rooftop card and detailed Rooftop Nest now all compose
  the same standalone egg with DragonHaven's separate woven bird-nest sprite.
- The shared nest renderer also keeps onboarding and any other egg preview
  visually consistent.

## Release reliability

- Added a mandatory reusable Supabase server preflight for every future
  release. It compares local and remote migrations, lints the remote schemas
  and checks the public Auth health and e-mail configuration endpoints.
- Online, Friends, Group Adventures and Trades retain the bundled public
  DragonHaven Supabase configuration introduced in v0.03.00.

Existing local progress and online account data remain intact when updating.
