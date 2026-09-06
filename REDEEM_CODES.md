# DragonHaven Redeem Codes

Last verified: 6 September 2026

Ruleset: app version `v0.05.11`

Source baseline: development after release `v0.05.11`

<!-- reference-source-fingerprint: 85a0007b03ccc207 -->

This living reference lists every redeem code currently accepted by the game
and the complete permanent reward granted by that code. Codes not listed here
are inactive.

## Redemption rules

- Codes are case-sensitive and use connected capital letters and numbers.
- Only codes present in the active catalog can grant a reward.
- Removing a code makes it inactive in the next app build; it does not remove
  rewards that a keeper legitimately received earlier.
- Inactive and unknown well-formed codes return the same inactive result.

## Active codes

There are currently no active redeem codes.

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
