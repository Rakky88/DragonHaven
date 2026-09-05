# DragonHaven Redeem Codes

Last verified: 5 September 2026

Ruleset: app version `v0.05.11`

Source baseline: release `v0.05.11`

<!-- reference-source-fingerprint: 15baf7c8b3ac99e4 -->

This living reference lists every redeem code currently accepted by the game
and the complete permanent reward granted by that code. Codes not listed here
are inactive.

## Redemption rules

- Codes are case-sensitive and use connected capital letters and numbers.
- Each current code unlocks one complete Dragon emote pack exactly as if that
  pack had been purchased in the Shop.
- A redeemed pack permanently unlocks all ten of its emotes for unlimited use
  in personal Friend Messages and Conclave chat.
- Packs and emotes never duplicate. Entering a code for a pack already owned
  does not grant another copy or a substitute reward.

## Active codes

| Code | Reward | Internal reward ID | Exact result |
|---|---|---|---|
| `EMOTEPACK1` | **Cozy Hatchlings** | `cozy_hatchlings` | The complete ten-emote Cozy Hatchlings pack |
| `EMOTEPACK2` | **Infernal Reactions** | `infernal_reactions` | The complete ten-emote Infernal Reactions pack |
| `EMOTEPACK3` | **Celestial Court** | `celestial_court` | The complete ten-emote Celestial Court pack |

## Exact pack contents

### `EMOTEPACK1` — Cozy Hatchlings

- Heart Hug
- Dragon Cocoa
- Blanket Burrito
- Sweet Dreams
- For You
- Shy Wave
- Picnic Snack
- Dragon Cuddle
- Happy Tears
- Good Night

### `EMOTEPACK2` — Infernal Reactions

- Evil Laugh
- Infernal Rage
- Dragon Facepalm
- Suspicious
- Skull Grin
- Set It Ablaze
- Absolutely Not
- Choose Chaos
- Infernal Shock
- Smug

### `EMOTEPACK3` — Celestial Court

- Royal Wave
- Celestial Applause
- Star Sparkle
- Moon Dream
- Star Eyes
- Courtly Bow
- Celestial Celebration
- Ancient Wisdom
- Guardian Salute
- Moon Magic

## Maintenance contract

The active-code catalog lives in `lib/models/redeem_code.dart`. Pack identities
and their exact emote contents live in `lib/models/dragon_emote.dart`. Both are
fingerprinted by the living-reference guard. Adding, removing, or redirecting a
code—or changing the contents of one of its rewards—must update this document
in the same change.

After reviewing the document, run:

```text
dart run tool/reference_documentation_guard.dart --update
dart run tool/reference_documentation_guard.dart --verify
flutter test test/reference_documentation_test.dart
```
