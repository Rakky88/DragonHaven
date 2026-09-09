# DragonHaven — artwork audit

Date: 5 September 2026
App version: v0.05.14

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
latest review rounds were inspected in the Android emulator. Cinderlynx Arcana,
Eclipseantler Arcana, Everwyrm Might, Everwyrm Spirit and Sunmuzzle Arcana then
received their final approved repairs, followed by repeated alpha, edge,
safe-padding and subject-component audits of every changed runtime sprite.

`tool/build_furniture_sprites.py` reproduces the empty
cushion import, removes only edge-connected generator background artifacts,
drops measured tiny specks, and exports every atlas cell with its natural
aspect ratio and an eight-percent alpha gutter. Runtime art is stored as
high-quality transparent WebP to keep the APK practical on phones.

The launcher mark is deliberately simple. Android uses a solid white adaptive
icon background, while the in-app header places the mark in a white-and-gold
medallion with an optically corrected crop.


## Sunwake/Harvestmoon approved artwork (9 September 2026, after v0.05.26)

Twelve separately generated RGBA PNGs are prepared for Solmanta and Ciderhorn:
Hatchling, Wyrmling, Might, Arcana, Spirit and Mastery. Both head and body axes
face screen-right. The original PNG bytes and alpha are unchanged; generated
variants with opaque checkerboards were rejected. Every final outer edge has
alpha <= 2 and all visible anatomy remains inside the image. The review adds
an 8% gutter on each side in Flutter, without cropping or altering the bitmap.

The user approved all twelve exact sprites on 9 September 2026. They are now
registered in the candidate family/egg catalog for v0.05.27; not yet published. The isolated review selects just these two families, supports pinch
zoom, and stores explicit approvals as well as requested fixes across restarts.
Full prompts, original/final paths, hashes and alpha bounds:
`future_event_art/dragon_families/sunwake_harvestmoon/ART_PROMPTS.json`.

The two event packages also include 27 individually generated logos, backgrounds,
eggs/chests, gameplay sprites, achievements, podium emotes and Conclave art.
Final prompt/source/output/SHA records are in `future_event_art/dragon_families/
sunwake_harvestmoon/EVENT_ASSETS.json`. Built-in image generation was used;
accepted source bytes are copied unchanged. Android launcher density/padding
exports use `tool/build_event_branding_icons.dart`. Transparent sprite tests
accept invisible alpha quantization up to 2/255 at the new podium corners.
