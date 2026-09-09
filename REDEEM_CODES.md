# DragonHaven Redeem Codes

Last verified: 9 September 2026

Ruleset: v0.05.27 candidate; Sunwake/Harvestmoon and stop mappings in forward migration 64, rehearsed on staging. Production remains schema 63 until rollout.

<!-- reference-source-fingerprint: 33e3121f6f75d457 -->

The server command identity allowlist is shared with the durable client journal. A retried redemption retains its original request identity; receipt recovery during a mutation pause does not repeat a grant. This changes no code value, eligibility or catalog reward below.

This private operational ledger lists every active code. Active codes must
never be mentioned in public release notes, store copy, or public support
announcements unless the owner explicitly changes that rule.

The local server-domain candidate delegates redemption to the existing catalog
and checks keeper restrictions using the trusted authenticated owner. The code
values, rewards and restrictions are listed below. The end-event action uses its
dedicated authenticated RPC, not the dormant game-command grant path. A new personal event
replaces the previous event for that keeper, with same-event retries retaining
their existing expiry. Started attempts and adventures retain their provenance.
The dedicated event-stop and preview RPCs are live. The broader canonical grant
candidate remains dormant in production; it is not a public grant endpoint yet.

Codes are case-sensitive, use only `A-Z` and `0-9`, and unknown or retired
codes return the same inactive result. Seasonal previews are authorized by the
server rather than trusted from the public app catalog.

## Active codes

| Code | Reward | Reward ID | Restriction and behavior |
|---|---|---|---|
| `SUNWAKEEVENT` | **Sunwake Festival** | `sunwake_summer_sea` | Any authenticated, email-confirmed keeper; reusable 48-hour personal preview; ordinary permanent Trial rewards, simulated Adventure/Special Chest rewards and separate cosmetic test progress |
| `HARVESTMOONEVENT` | **Harvestmoon Festival** | `harvestmoon_moonlit_orchard` | Any authenticated, email-confirmed keeper; reusable 48-hour personal preview; ordinary permanent Trial rewards, simulated Adventure/Special Chest rewards and separate cosmetic test progress |
| `BDAYEVENT` | **A Wish on Golden Wings** | `golden_wings_birthday` | Any authenticated, email-confirmed keeper; reusable 48-hour personal preview with Wishcake Tower and Happy Birthday music; ordinary permanent Trial rewards, simulated Adventure/Special Chest rewards |
| `ENDEVENT` | **End own active event** | `end_active_event` | Any authenticated, email-confirmed keeper; removes own previews and dismisses current calendar occurrences until their scheduled end; repeatable, no items granted |
| `HALLOWEENEVENT` | **Night of the Witchlight** | `halloween_witchlight` | Any authenticated, email-confirmed keeper; 48-hour reusable personal preview; isolated test ranking; normal permanent Trial rewards, simulated Adventure/Special Chest rewards |
| `CHRISTMASEVENT` | **A Star for the Winter Hearth** | `christmas_winter_hearth` | Any authenticated keeper with a confirmed email; 48-hour reusable personal preview; isolated test ranking; normal permanent Trial rewards, simulated Adventure/Special Chest rewards |
| `NEWYEARSEVENT` | **When the New Dawn Rings** | `new_year_first_dawn` | Any authenticated keeper with a confirmed email; 48-hour reusable personal preview; isolated test ranking; normal permanent Trial rewards, simulated Adventure/Special Chest rewards |
| `VALENTINEEVENT` | **Where Two Heartlights Meet** | `valentine_two_heartlights` | Any authenticated keeper with a confirmed email; 48-hour reusable personal preview; isolated test ranking; normal permanent Trial rewards, simulated Adventure/Special Chest rewards |
| `PRIDEFESTEVENT` | **The Haven of Every Color** | `pride_every_color` | Any authenticated keeper with a confirmed email; 48-hour reusable personal preview; isolated test ranking; normal permanent Trial rewards, simulated Adventure/Special Chest rewards |

## Ending an active event

`end_my_seasonal_event` accepts `ENDEVENT`, checks the verified authenticated
owner and takes the same per-owner transaction lock as preview activation.
It deletes only that owner's preview activation and records current official
calendar editions (including Golden Wings, Sunwake and Harvestmoon) in `seasonal_event_dismissals` until
their original ending. These rows are private; there are no direct client table
read/write grants. `list_my_seasonal_event_dismissals` returns only the owner.
The app persists and refreshes these stops across sessions/devices, removes
unstarted event offers, restores the ordinary theme/music/launcher schedule,
and retains future annual editions. The normal Android launcher refresh is
deferred until leaving the foreground. Explicitly starting a new preview is
still allowed. Already started trials/adventures, scores and rewards survive.
No other player's event is stopped. Offline failure does not clear local state.

## Security and lifecycle

- The app catalog is for discovery and UI only; it is not access control.
- `redeem_seasonal_event_preview` requires an authenticated, email-confirmed
  account and maps each code to one fixed event. All eight event mappings are available
  to every verified keeper; migration 62 removes the former single-account gate.
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
lives in the immutable base migration 40 and the current forward overrides
`supabase/migrations/202609080059_single_active_event_preview.sql` and
`supabase/migrations/202609090060_end_active_event.sql`. Adding,
removing, redirecting, restricting, or changing a code must update both sources
and this document in the same change.

After review, run:

```text
dart run tool/reference_documentation_guard.dart --update
dart run tool/reference_documentation_guard.dart --verify
flutter test test/reference_documentation_test.dart
```

## 9 September 2026 access update

All previously account-restricted catalog codes now work for every verified
keeper. The app catalog and event metadata agree with forward migration 62.
Activation still affects only the authenticated account, uses one active preview,
retains the existing 48-hour retry expiry and keeps preview ranking provenance.
Anonymous/unverified requests and unknown codes remain rejected. No reward
contents or permanence rules changed. Operational values stay out of release notes.

## Birthday extension

The birthday preview uses the same owner lock, single-active-preview rule and
48-hour retry expiry as the other seven. It grants no item merely for redeeming.
Migration 63 introduced the birthday override;
`supabase/migrations/202609090064_sunwake_harvestmoon.sql` now extends it with the two new events. Calendar dates remain 1–2 September 2026, then 13 May yearly
from 2027 (Europe/Amsterdam). The code and its announcement stay out of release notes.

The new event codes use the same verified-account, retry-expiry, replacement,
end-event and privacy rules. Sunwake/Harvestmoon definitions are version 1 with
300 coins, 12 gems and a guaranteed own-family egg per Special Chest; production
previews display those Adventure/Chest rewards without granting them. Code
values and announcements remain absent from public release notes.
