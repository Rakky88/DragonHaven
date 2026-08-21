# DragonHaven — dragon and furniture artwork audit

Datum: 21 augustus 2026
Appversie: v0.00.02

## Dragon assets

The app contains 101 logical dragon appearances in 41 transparent WebP files:

- one shared Mysterious Egg;
- twenty standalone Hatchlings;
- twenty 2×2 atlases, ordered Wyrmling, Might, Arcana and Spirit.

Each form is independently illustrated. `DragonArt` crops the required frame directly and only applies a silhouette or Prismatic presentation effect; it does not build later forms by attaching shapes to another dragon.

## Automated frame audit

`test/sprite_bounds_test.dart` decodes every runtime image and checks:

- the egg and all twenty Hatchlings contain visible artwork and retain a transparent safety border;
- every one of the eighty Wyrmling/Ascended atlas frames is non-empty and does not touch any crop boundary;
- all twenty-four furniture atlases contain eight separated, non-empty sprites;
- all 192 generated furniture frames retain transparent crop margins.

`tool/pad_sprite_atlases.ps1` applies a consistent 8% transparent safety margin per individual frame. Frames are processed independently, so no neighboring dragon or furniture object can bleed into the visible crop.

All twenty-four generated furniture atlases also pass through `tool/repack_furniture_atlases.py`. It detects the main transparent component for each of the eight fixed cells, isolates and recenters the complete object with a safe gutter, and rejects disconnected fragments belonging to neighboring furniture. A cell-by-cell contact-sheet audit covered all 192 runtime furniture sprites after repacking.

The finalized runtime art is encoded as quality-92 transparent WebP. The visual A/B inspection showed no visible change at app scale, while the in-game artwork dropped from 173,241,745 to 33,285,532 bytes.

## Generation recipes

- Logo: a text-free, transparent premium fantasy-game emblem showing a mysterious luminous egg in a woven nest atop a violet-gold cloud tower, framed by a crescent moon and stars.
- Android icon: the same emblem centered within a generous safe area on a completely solid pure-white square background.
- Tower nest: a wide 16:9 fantasy-game environment with an empty woven nest at the top of a violet tower, moonlit clouds, clear center staging area and no text.
- Furniture: twenty-four themed 4×2 transparent sprite atlases in the fixed order cushion, daybed, planter, bonsai, tapestry, shelf, lantern and orb; isolated full objects, readable game scale, no text or scene background.

The Frost and Mushroom atlases were regenerated from scratch after their first generations failed the transparency requirement.
