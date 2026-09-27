# Server efficiency

## Scope and baseline — 27 September 2026

The v0.06.12 release is published before this separate optimization pass.
This pass concerns database work and operating costs. It does not change item
prices, drop rates, currency rewards, limits, or the server's authority over
player progress.

A read-only production snapshot at 12:16 UTC reported a database size of
37,301,395 bytes. PostgreSQL's cumulative row-update counters included 124,952
updates to `player_dragons` and 18,199 to `social_showcases`. These counters are
not measurements of requests per minute, current player traffic, or savings.
They include historical operation and testing. The snapshot contains table
statistics only, without player identifiers or inventory contents.

The much higher historical inventory-table counters are not a current target:
the legacy `synchronize_trade_inventory` entry point rejects server-owned
accounts, and the current canonical social projection does not write those
egg/chest/relic tables. Optimizing that historical path would not establish a
benefit for current gameplay.

## First target: repeated social projection writes

Before migration 102, every committed canonical state retires all projected
dragons and immediately upserts them again, even for an unrelated inventory
action. With N owned dragons, this makes 2N dragon-row updates. Three separate
projection writers also update the showcase for basic details, Ascended Trial
scores, and collection counts regardless of whether those values changed.

Migration 102 is deployed on staging and production. It now:

- Retires only dragons absent from the new canonical collection; preserves their
  historical UUIDs and restore the same identity when they return.
- Clears an old favorite before setting a replacement, preserving the unique
  favorite constraint regardless of resident order.
- Updates existing dragon rows only when projected fields differ.
- Updates each showcase projection only when its owned fields differ.

Canonical state, wallet revision, projection revision/hash, authorization,
atomic commit, idempotent receipt, and request recovery checks must still run.
An unchanged social projection must not weaken any of those checks.

The same 27-dragon fixture measured 54 dragon updates plus three showcase updates
before the change, and zero updates to those tables afterward for an unrelated
canonical revision. Wallet and projection-revision writes still occur. Both the
local contract and the full staging-schema contract pass, including changes to
all six scores, favoriting, release/restore, service checks and exact replay.

Production deployment and postflight results are recorded in
`SPEC_FINAL_AUDIT.md`. Reduced row writes are not a promise of
an equal reduction in request latency or the Supabase bill: authentication,
network latency, rule evaluation, index checks, and retained bookkeeping remain.

## Existing request scheduling

The one-second adventure/nest/UI clocks render local countdowns. They are not
one-second inventory requests. Canonical offer refreshes follow their next
server-derived deadline; shorter retries are reserved for expired work or
recovery. These behaviors are covered by the existing scheduler tests.

The foreground account safety check runs once per minute and checks a small
status response, not a full inventory snapshot. Social refresh currently runs
every two minutes, Conclave refresh every 30 seconds, and the social notification
fallback every 60 seconds with push available or 15 seconds without it.
Foreground guards and in-flight guards prevent background/overlapping polls.
User actions, app resume, push messages and recovery can cause additional calls.

## Follow-up priorities

1. Compare representative production intervals after deployment; keep table
   update deltas separate from command counts and actual response times.
2. Review background Conclave reads and overlap with full social refreshes.
   Preserve prompt invites, shared activity and notification delivery before
   reducing their frequency.
3. Review global event-invitation expiry on list reads: the cron worker also
   performs expiry, but changing that path requires lock-order and expiration
   correctness tests before deployment.
4. Measure retention and storage growth before pruning. Never remove pending
   commands, receipts required for recovery, ad-verification records or audit
   history merely to reduce storage.

No production load test, automatic plan upgrade, destructive cleanup, or global
statistics reset is part of this pass.
