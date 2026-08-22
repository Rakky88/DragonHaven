# DragonHaven — artwork audit

Date: 21 August 2026
App version: v0.00.09

## Dragon assets

The runtime contains 216 independently illustrated logical dragon appearances
in 87 transparent WebP files:

- one shared Mysterious Egg;
- 42 regular Hatchlings and 42 regular 2×2 form atlases;
- 168 regular atlas frames: Wyrmling, Might, Arcana and Spirit per family;
- one secret Sinister Hatchling and four dedicated Sinister form frames.

`DragonArt` crops the requested frame directly. It only adds presentation
effects for silhouettes and Spectral variants; it never constructs a later
form by attaching shapes to a younger image.

## Automated frame audit

`test/sprite_bounds_test.dart` decodes every runtime asset and verifies:

- the egg, all 42 Hatchlings and the Sinister Hatchling are non-empty and keep
  a transparent safety border;
- every regular and Sinister Wyrmling/Ascended frame stays inside its atlas
  quadrant without bleeding into a neighbouring frame;
- all 24 furniture atlases contain eight separated sprites;
- all 192 atlas furniture frames and eight standalone objects retain safe
  transparent bounds;
- all six chests retain safe transparent bounds;
- the 24 room base/day/night scenes and seven rooftop phases exist at usable
  resolution and are byte-distinct.

The furniture catalog therefore contains 200 real raster objects rather than
placeholder icons or CSS-style shapes.

## Processing

`tool/pad_sprite_atlases.ps1` applies a consistent transparent safety margin to
each individual frame. Furniture cells are isolated and recentered separately,
so neighbouring fragments cannot appear in the in-game crop. Runtime art is
stored as high-quality transparent WebP to keep the APK practical on phones.

The launcher mark is deliberately simple. Android uses a solid white adaptive
icon background, while the in-app header places the mark in a white-and-gold
medallion with an optically corrected crop.
