# Equipment and event release verification

Released: v0.05.22 / 10072. All final checks passed; see `RELEASE_V0.05.22_VERIFICATION.md`.

## Player changes

- Gender appears only in dragon details, after Dragon type and Maturity.
- Expertise icons, names and scores share a vertical center. MAX stays below
  the score row. Existing highlights retain the original Expertise colors.
- Emberheart, Moonweave and Soulbloom Brooch respectively double Might, Arcana
  and Spirit earned by their wearer from Adventures and Trials. Twinstar keeps
  its XP effect. All four share one equipment slot per dragon, with one lifetime
  copy of each per keeper and no consumable, shop, crafting or trade route.
- Every ordinary relic has weight 10 and each eligible brooch weight 1 in the
  existing chest / S+ Trial drop pool. Overall relic-drop rates are unchanged.
- Halloween S+ starts at 2500; S starts at 2250 to remain reachable. The other
  event cutoffs and the 8–22 September raw-score calibration stay unchanged.
- A new personal event replaces the previous personal event. Current previews
  take priority over the ordinary calendar. Existing attempts, adventures,
  rewards and scores keep their original event and reward rules.
- The six events have matching logo, countdown, background and shared UI
  accents. Valentine is pink, Christmas green, New Year blue, Pride uses rainbow
  panels, and Golden Wings has a new illustrated golden background. Existing
  Android aliases switch on background/resume without closing a visible task.

## Evidence

- 51 targeted tests passed, including equipment ownership, replacement, restore,
  matching bonuses, other-dragon isolation, idempotent social claims, canonical
  command parity, translations, event boundaries and the Halloween cutoff.
- Eleven event UI tests passed with real Roboto assets: all six event themes on
  compact screens at 1.35 text scale, dragon detail alignment, and both pickers
  at 1.6 text scale. All six resulting theme captures were visually inspected.
- Deno: 14 Edge-worker tests passed; the compiled Dart rules match the Flutter
  VM fixture. Server bundle is under 1 MB. This does not activate production
  game authority.
- Migrations 58 and 59 each passed their rollback-only contract on registered
  staging. Chest contracts check exact weights and all four lifetime exclusions.
  The event contract checks account isolation, retry expiry, rejected activation,
  old-event refusal and completion of an already-started old-event attempt.
  Staging remained at schema 57 after rehearsal; synthetic changes rolled back.
- Final CI analysis and all 652 tests passed. Android API 37 update preserves
  the original save; Gender, equipment, expertise alignment, six themes, 320dp
  width, 1.35 text and disabled animations were checked on the emulator.
- Staging run 34281388567 passed feature/canonical contracts, actual authenticated
  UI purchases and chest opening, cleanup and final health. Both environments
  now have schema 59 with lint 0 and healthy Auth/settings/application endpoints.
  Production authority is still legacy and game/economic mutations remain off.
- Signed artifact, byte size, digest, production preflight and publication
  evidence are tracked in `RELEASE_V0.05.22_VERIFICATION.md`.

## Artwork

Generated with built-in image_gen, inspected with alpha preserved and generous
runtime padding. Source outputs remain in the generator directory. Runtime:

- `assets/images/relics/emberheart_brooch.png`
- `assets/images/relics/moonweave_brooch.png`
- `assets/images/relics/soulbloom_brooch.png`
- `assets/images/events/golden_wings/trial_background.webp`

Exact prompt sets and tool provenance are recorded in
`artwork_sources/equipment_relics/prompts.json` and
`artwork_sources/golden_wings_background/prompts.json`.
