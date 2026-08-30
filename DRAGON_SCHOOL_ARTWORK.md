# Dragon School and Packs imagegen sources

Generated on 2026-08-30 with the built-in Codex image-generation tool. All
assets were requested as centered, transparent-background DragonHaven mobile
game sprites with generous padding, no text and no watermark. Final PNGs were
normalized with `tool/prepare_generated_ui_sprite.dart`.

Shared style clause:

> DragonHaven style: rich purple, midnight blue, warm gold and cyan highlights;
> softly painted, polished high-detail fantasy mobile-game icon, readable at
> 48 px, genuine transparent background, generous padding, no frame or text.

Asset prompts:

- `packs_icon.png`: ornate purple-and-gold gift box, cyan gem and star seal.
- `dragon_school_icon.png`: young purple dragon behind an open magical academy
  book within a gold crest. A second edit removed an accidentally baked
  checkerboard while preserving the subject.
- `trial_constellation_node.png`: radiant gold-violet celestial star node.
- `school_graduate.png` / `academy_graduate.png`: purple graduate dragon holding
  a rolled diploma inside a gold laurel academy crest.
- `school_dropout.png` / `dragon_school_dropout.png`: playful purple pupil
  dragon escaping with a crooked graduation cap, singed diploma and gently
  broken gold laurel; affectionate and humorous rather than punitive.
- `school_valedictorian.png` / `dragon_school_valedictorian.png`: triumphant
  purple scholar dragon with immaculate diploma, complete gold laurel, crown
  flourish, magical aura and three radiant stars.
- `game_rune_rush.png`: luminous arcane rune disk in fast magical motion.
- `game_crystal_chase.png`: winged cyan-violet crystal with a bright motion
  trail.
- `game_ember_reflex.png`: sudden bright ember burst rising from an ornate
  training brazier.
- `game_sigil_memory.png`: three floating elemental sigils above an arcane
  memory dais.
- `game_scale_order.png`: ordered enchanted dragon scales spiralling upward.
- `game_shadow_match.png`: paired dragon silhouettes with one subtly mirrored.
- `game_breath_balance.png`: opposing fire and frost dragon breaths balanced
  around a central orb.
- `game_cloud_weave.png`: two intertwined golden feathers weaving through cyan
  and violet cloud rings.
- `game_safe_hoard.png`: protected gold hoard, paired wing shields and one
  visibly cursed violet chest.
- `game_constellation_trace.png`: three star-dragon silhouettes connected by a
  luminous path inside a celestial compass arc.

Lesson backgrounds (portrait 2:3, no characters, text or UI):

- `background_rune_rush.jpg`: violet rune observatory and open practice floor.
- `background_crystal_chase.jpg`: bright crystal courtyard with a clear grid.
- `background_ember_reflex.jpg`: dark academy fire-training hall.
- `background_sigil_memory.jpg`: moonlit arcane library and memory chamber.
- `background_scale_order.jpg`: scholarly hall of iridescent dragon scales.
- `background_shadow_match.jpg`: friendly moonlit shadow theatre.
- `background_breath_balance.jpg`: symmetrical frost-and-fire terrace.
- `background_cloud_weave.jpg`: three-lane academy course above the clouds.
- `background_safe_hoard.jpg`: protected purple-and-gold training treasury.
- `background_constellation_trace.jpg`: rooftop celestial observatory.

Transparent play-piece prompts used the shared style clause and requested one
centered object with generous padding:

- six elemental/celestial memory sigils: flame, wave, leaf, moon, lightning and
  wind;
- one blank gold-edged iridescent scale token;
- one dormant academy training brazier;
- one ornate frost/fire balance gauge and a separate balance orb;
- one cyan-lavender cloud gate;
- one protected treasure pile and one cursed violet chest;
- success sparkle, mistake puff and mentor-shield reaction sprites.

Original generated files remain in the Codex generated-images directory; the
app uses the optimized copies under `assets/images/ui/` and
`assets/images/achievements/`.

Lesson backgrounds and non-square play pieces were normalized with
`tool/prepare_generated_game_asset.dart`; square icons continue to use
`tool/prepare_generated_ui_sprite.dart`.
