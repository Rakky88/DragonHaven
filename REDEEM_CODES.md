# DragonHaven Redeem Codes

Last verified: 9 September 2026

Ruleset: released `v0.05.22`; personal event replacement in migration 59

<!-- reference-source-fingerprint: 88c69b1b6faae4f1 -->

The server command identity allowlist is shared with the durable client journal. A retried redemption retains its original request identity; receipt recovery during a mutation pause does not repeat a grant. This changes no code value, eligibility or catalog reward below.

This private operational ledger lists every active code. Active codes must
never be mentioned in public release notes, store copy, or public support
announcements unless the owner explicitly changes that rule.

The local server-domain candidate delegates redemption to the existing catalog
and checks keeper restrictions using the trusted authenticated owner. The code
values, rewards and restrictions remain unchanged. A new personal event
replaces the previous event for that keeper, with same-event retries retaining
their existing expiry. Started attempts and adventures retain their provenance. This internal candidate is not deployed or exposed as a public
redemption endpoint yet.

Codes are case-sensitive, use only `A-Z` and `0-9`, and unknown or retired
codes return the same inactive result. Seasonal previews are authorized by the
server rather than trusted from the public app catalog.

## Active codes

| Code | Reward | Reward ID | Restriction and behavior |
|---|---|---|---|
| `HALLOWEENEVENT` | **Night of the Witchlight** | `halloween_witchlight` | Any authenticated, email-confirmed keeper; 48-hour reusable personal preview; isolated test ranking; normal permanent Trial rewards, simulated Adventure/Special Chest rewards |
| `CHRISTMASEVENT` | **A Star for the Winter Hearth** | `christmas_winter_hearth` | Keeper `DH-17792DC5`; 48-hour reusable personal preview; isolated test ranking; normal permanent Trial rewards, simulated Adventure/Special Chest rewards |
| `NEWYEARSEVENT` | **When the New Dawn Rings** | `new_year_first_dawn` | Keeper `DH-17792DC5`; 48-hour reusable personal preview; isolated test ranking; normal permanent Trial rewards, simulated Adventure/Special Chest rewards |
| `VALENTINEEVENT` | **Where Two Heartlights Meet** | `valentine_two_heartlights` | Keeper `DH-17792DC5`; 48-hour reusable personal preview; isolated test ranking; normal permanent Trial rewards, simulated Adventure/Special Chest rewards |
| `PRIDEFESTEVENT` | **The Haven of Every Color** | `pride_every_color` | Keeper `DH-17792DC5`; 48-hour reusable personal preview; isolated test ranking; normal permanent Trial rewards, simulated Adventure/Special Chest rewards |

## Security and lifecycle

- The app catalog is for discovery and UI only; it is not access control.
- `redeem_seasonal_event_preview` requires an authenticated, email-confirmed
  account and maps each code to one fixed event. Only Halloween is available to
  every keeper; the other four mappings still require Keeper `DH-17792DC5`.
- A code can be reused only after its previous entitlement expires.
- Repeating an active code returns the original expiry, without extending its
  48-hour window or changing its test ranking key.
- Preview scores use a preview occurrence key and never affect live rankings.
- Test event Trials grant their ordinary permanent rewards and keep personal
  bests. Production test Adventures and their Special Chests still display
  rewards without persisting them; staging can enable those for persistence tests.
- The 8 September 2026 change does not alter code access or entitlement length.
  Halloween's stored test scores are analyzed for 8–22 September separately from
  live rankings (`tool/halloween_trial_calibration_report.sql`).
- Removing a definition from both the app catalog and server mapping retires
  the code without removing legitimate earlier rewards.

## Maintenance contract

The client catalog lives in `lib/models/redeem_code.dart`; server authorization
lives in the immutable base migration 40 and the current forward override
`supabase/migrations/202609070048_halloween_preview_access.sql`. Adding,
removing, redirecting, restricting, or changing a code must update both sources
and this document in the same change.

After review, run:

```text
dart run tool/reference_documentation_guard.dart --update
dart run tool/reference_documentation_guard.dart --verify
flutter test test/reference_documentation_test.dart
```
