# Event Trial balance after v0.05.24

Status: published in v0.05.25 / 10075, 9 September 2026.
Final combined verification: `RELEASE_V0.05.25_VERIFICATION.md`.

| Trial | S+ starts at |
|---|---:|
| Halloween | 2000 |
| New Year | 20000 |
| Valentine | 10000 |
| Pridefest | 12000 |

Halloween A/S move to 1600/1800 so each rank remains reachable. Other lower
boundaries and Christmas grades stay unchanged. New Year's S+ equals the existing
20000 server score cap; no database or reward-pool changes are required.

Christmas now schedules arrivals independently of delivery, at intervals from
2.4s down to .36s. Each parcel has its own fixed travel time, from 4.4s down to
.95s plus up to .35s of Might help. Arrivals overlap; delivering or dragging a
parcel never resets another's deadline. An expired held parcel cannot later
score or deliver a different parcel. Three mistakes lock input synchronously,
including several expiries in a single frame. Repeated feedback stays readable
without duplicate transition keys.

Verification:

- All **703 tests** passed; 23 focused arcade/rank/equipment checks cover the
  exact grade boundaries, increasing pace, concurrent parcels, independent
  deliveries, expiry during a gesture, three-strike endings and recovery into
  the next Halloween round. The documentation guard and its five tests pass.
- Analysis and the final documentation checks are clean.
- Android preview inspected at normal size and 320dp with 1.35 text scale and
  reduced motion. Concurrent gift sprites and the three delivery bays remain
  clear; the third miss ends play at approximately nine seconds in the idle run.
- Screenshots: `release/event-balance-christmas-concurrent.png`,
  `release/event-balance-christmas-game-over.png`,
  `release/event-balance-christmas-compact-overlap.png`.
- Preview used a nonpersistent game and an offline account fixture. The released
  production APK and normal emulator display settings were restored afterward.
- The initial balance-only commit did not require a database change. It is now
  included in v0.05.25; migration 62 concerns personal preview access only.
  The combined release passes 707 tests and post-publication production health.
