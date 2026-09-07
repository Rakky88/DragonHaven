# DragonHaven Redeem Codes

Last verified: 7 September 2026

Ruleset: app version `v0.05.13`

<!-- reference-source-fingerprint: 9abb4c03963d8b82 -->

This private operational ledger lists every active code. Active codes must
never be mentioned in public release notes, store copy, or public support
announcements unless the owner explicitly changes that rule.

Codes are case-sensitive, use only `A-Z` and `0-9`, and unknown or retired
codes return the same inactive result. Seasonal previews are authorized by the
server rather than trusted from the public app catalog.

## Active codes

| Code | Reward | Reward ID | Restriction and behavior |
|---|---|---|---|
| `HALLOWEENEVENT` | **Night of the Witchlight** | `halloween_witchlight` | Keeper `DH-17792DC5`; 48-hour reusable personal preview; isolated test ranking; simulated production rewards |
| `CHRISTMASEVENT` | **A Star for the Winter Hearth** | `christmas_winter_hearth` | Keeper `DH-17792DC5`; 48-hour reusable personal preview; isolated test ranking; simulated production rewards |
| `NEWYEARSEVENT` | **When the New Dawn Rings** | `new_year_first_dawn` | Keeper `DH-17792DC5`; 48-hour reusable personal preview; isolated test ranking; simulated production rewards |
| `VALENTINEEVENT` | **Where Two Heartlights Meet** | `valentine_two_heartlights` | Keeper `DH-17792DC5`; 48-hour reusable personal preview; isolated test ranking; simulated production rewards |
| `PRIDEFESTEVENT` | **The Haven of Every Color** | `pride_every_color` | Keeper `DH-17792DC5`; 48-hour reusable personal preview; isolated test ranking; simulated production rewards |

## Security and lifecycle

- The app catalog is for discovery and UI only; it is not access control.
- `redeem_seasonal_event_preview` verifies the authenticated account's Keeper
  ID and maps the code to one fixed event server-side.
- A code can be reused only after its previous entitlement expires.
- Preview scores use a preview occurrence key and never affect live rankings.
- Production preview rewards are displayed but not persisted. Staging may
  persist them to validate save, restore, and idempotency paths.
- Removing a definition from both the app catalog and server mapping retires
  the code without removing legitimate earlier rewards.

## Maintenance contract

The client catalog lives in `lib/models/redeem_code.dart`; server authorization
lives in `supabase/migrations/202609070040_seasonal_events.sql`. Adding,
removing, redirecting, restricting, or changing a code must update both sources
and this document in the same change.

After review, run:

```text
dart run tool/reference_documentation_guard.dart --update
dart run tool/reference_documentation_guard.dart --verify
flutter test test/reference_documentation_test.dart
```
