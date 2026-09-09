# Sunwake and Harvestmoon implementation plan

Started after verified release v0.05.26 on 9 September 2026.
Status: implemented and published in v0.05.27 / 10077 on 9 September 2026.
All twelve dragon sprites and the complete contract were approved by the user.
Both personal test previews are available now; the annual public calendar begins
in 2027 as approved. Verification: `RELEASE_V0.05.27_VERIFICATION.md`.

## Requested and resolved presentation

- Sunwake Festival: turquoise lagoon, coral highlights, luminous shells.
  Adventure: Where the Summer Sea Shines, restoring an ancient lighthouse.
  Dragon: Solmanta, pearly sea-glass scales and manta-like wings.
  Trial: Sunwake Surf, steer through currents, avoid reefs and collect sunpearls.
  Conclave concept: a communal decorative coral reef.
- Harvestmoon Festival: cozy copper leaves, olive green, golden moonlit orchard.
  Adventure: The Orchard Beneath the Harvest Moon.
  Dragon: Ciderhorn, applewood branching horns, copper leaves and apple blossoms.
  Trial: Moonlit Orchard, fit fruit shapes into a basket and clear full rows.
  Conclave concept: a communal decorative harvest feast table.
- Both receive their own full app theme, illustrated backgrounds, event logo
  and native launcher/splash art, clear expiry banner, original music and sound,
  event Trial, Special Adventure, hatch achievement and seasonal emotes.
- Six individually generated forms per dragon: Hatchling, Wyrmling, Might,
  Arcana, Spirit and Mastery. Full-body artwork faces screen-right, with real
  transparent margins. Review exact images in the emulator with zoom and notes.
  The user approved all twelve exact sprites in the emulator on 9 September 2026.

## Approved contract (9 September 2026)

- Yearly Sunwake 20 July 00:00 through 27 July 00:00 and Harvestmoon
  7 September 00:00 through 14 September 00:00, Europe/Amsterdam, from 2027.
  Personal 48-hour test versions are available independently of the calendar.
- One solo Adventure per keeper/occurrence, one owned available dragon;
  84 hours base, combined expertise discounts of 15 minutes per point,
  24-hour minimum. A valid start may always finish after event end.
- Per Adventure: 650 XP, +10 Might/Arcana/Spirit and its own Special Chest.
- Each chest: fixed 300 coins, 12 gems and its own single Special Egg.
  Contents remain hidden until opening; distinct persisted definition/version,
  no trading, no cross-event stack merging, no reroll on restore/retry.
- Sunwake Egg: guaranteed Solmanta, 20-hour incubation. Harvestmoon Egg:
  guaranteed Ciderhorn, 18 hours. Both Good, 5% Spectral normally and 10% in
  Golden Hour. Existing Special-family evolution, random gender/law/size/
  personality, hidden personality and expertise caps remain the shared rules.
- Existing Special-tier 10% unique chest-emote roll; ordinary grade Trial
  rewards and established gold/silver/bronze podium chests with new event emotes.
- Cosmetic Conclave progress comes from verified event Trial completions,
  without currency donations or additional economic rewards.

The user explicitly accepted this complete package. Both test codes and release are authorized.

## Implementation and verification sequence

1. Generate and inspect both families, then install an isolated review build
   preserving the existing keeper save and stored review notes.
2. Record the accepted contract as distinct Adventure, Chest and Egg objects.
3. Integrate schedules, definitions, provenance, dragon forms, achievements,
   emotes, original music, all app branding and countdown/notifications.
4. Build both distinct games, expertise assistance, scores, saved bests and
   server-validated attempts. Add verified cosmetic Conclave participation.
5. Exercise forward-only server changes on isolated staging, including expiry,
   duplicate claims, account isolation, inventory overflow and old saved content.
6. Verify gameplay and art on compact/tall emulator layouts, large type,
   reduced motion, music restoration, offline/resume and backup/restore.
7. Update living event/reward/code documentation and the audit. Record open art
   feedback and fixes before considering a subsequent release.

## Completed preparation and accepted implementation

- The release above is complete and verified; its production state is unchanged.
- The independent sprite review now selects only requested families, references
  the actual shipped sprite directory, and persists explicit approvals alongside
  fix notes. A regression test found the former dialog disposed its text
  controller while the closing animation still used it; the dialog now owns
  the controller for its full lifetime. Selection and save/restart tests pass.
- Both original music compositions have been synthesized and their PCM headers,
  peaks and hashes checked. They are integrated as native event music outside the ordinary collection.
  Sources and verification records remain in `future_event_art/music/`.


## Completed release

All seven implementation/verification steps are complete. The full regression
passes 738 tests; exact-commit release and staging worker CI both pass. Native
Android update, compact/reduced-motion layouts, music, launcher branding and
Conclave visuals have been reviewed. Production has 65 matching migrations,
lint 0 and healthy Auth/application endpoints before and after publication.
The public release and permanent APK download are verified against the local
signature, version, SHA-256 and byte size. See `RELEASE_V0.05.27_VERIFICATION.md`.
