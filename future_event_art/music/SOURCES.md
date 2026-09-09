# Sunwake and Harvestmoon music

Prepared 9 September 2026; not yet part of the live event music catalog.
Both are original DragonHaven compositions, arrangements and synthesized
performances created for these two festivals. No external composition, sample,
recording, soundfont or paid service was used. Reproducible generator:
`tool/build_sunwake_harvestmoon_music.dart`.

- Sunpearl Serenade: 112 BPM, 4/4, 32 bars, synthesized pan/harp/bass;
  `music_event_sunwake_sunpearl_serenade.wav`, 70.571 seconds.
- Orchard Waltz: 92 BPM, 3/4, 32 bars, synthesized flute/harp/bass;
  `music_event_harvestmoon_orchard_waltz.wav`, 64.609 seconds.

Mono 44.1kHz/16-bit PCM. One fixed gain per complete recording targets active
RMS 0.105, bounded below peak 0.8; no time-varying gain or compressor. Matching
verses use identical instrument levels. Short natural note attacks/releases,
fixed room reflections and an end release avoid clicks.

Native event aliases, restoring the saved jukebox and on-device listening are
still to be connected after the event contract intake is resolved.
