# DragonHaven — artwork audit

Date: 4 September 2026
App version: v0.05.09

## Dragon assets

The runtime contains 265 logical dragon appearances across 245 runtime asset
paths:

- one shared Mysterious Egg;
- 42 standard families plus the secret Sinisterra and Special Event
  Cluckatrice families;
- 44 standalone Hatchlings and 44 standalone Mastery forms;
- 176 Wyrmling, Might, Arcana and Spirit appearances; and
- 104 individually reviewed standalone intermediate forms, with the remaining
  intermediate appearances cropped from their dedicated 2×2 family atlases.

`DragonArt` crops the requested frame directly. It only adds presentation
effects for silhouettes and Spectral variants; it never constructs a later
form by attaching shapes to a younger image.

## Automated frame audit

`test/sprite_bounds_test.dart` decodes every runtime asset and verifies:

- the egg and all 44 Hatchlings are non-empty and keep a transparent safety
  border;
- every regular and Sinister Wyrmling/Ascended frame stays inside its atlas
  quadrant without bleeding into a neighbouring frame;
- all 264 non-egg dragon appearances contain one coherent illustrated subject,
  without a foreign dragon or neighbouring atlas fragment; intentional
  detached spell effects are explicitly documented by the test;
- all 24 furniture atlases contain eight separated source sprites;
- all 192 generated furniture forms are also exported as proportional,
  individually trimmed runtime WebPs; together with the eight original items,
  all 200 furniture objects retain safe transparent bounds;
- all six chests retain safe transparent bounds;
- the 24 room base/day/night scenes and seven rooftop phases exist at usable
  resolution and are byte-distinct.

The furniture catalog therefore contains 200 real raster objects rather than
placeholder icons or CSS-style shapes. Runtime rendering uses `BoxFit.contain`
on one naturally proportioned file per object, so a wide bed is no longer
stretched into the rectangular room slot and a tall lamp is never clipped by
an atlas transform.

All 24 generated cushion forms were redrawn as empty furniture. They preserve
their theme-specific fabric, trim and ornaments but contain no baked-in dragon;
room dragons remain independent moving sprites.

## Processing

`tool/pad_sprite_atlases.ps1` applies a consistent transparent safety margin to
each individual frame. `tool/clean_dragon_sprites.py` performs a two-phase
subject extraction for every Hatchling and evolution frame: it first isolates
the intended dragon from its source cell, removes edge-connected neutral matte,
then removes any newly disconnected neighbouring subject before recentering the
result inside a transparent safety gutter. The generated review screens cover
the selected normal and Spectral variants on a saturated blue background. The
latest three review rounds were inspected in the Android emulator, followed by
repeated alpha, edge, safe-padding and subject-component audits of every changed
runtime sprite.

`tool/build_furniture_sprites.py` reproduces the empty
cushion import, removes only edge-connected generator background artifacts,
drops measured tiny specks, and exports every atlas cell with its natural
aspect ratio and an eight-percent alpha gutter. Runtime art is stored as
high-quality transparent WebP to keep the APK practical on phones.

The launcher mark is deliberately simple. Android uses a solid white adaptive
icon background, while the in-app header places the mark in a white-and-gold
medallion with an optically corrected crop.
