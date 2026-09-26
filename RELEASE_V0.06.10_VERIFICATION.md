# DragonHaven v0.06.10 / 10103 verification

## Scope

This release adds three Expertise Trials, final-evolution Expertise gifts and
the restored tower-room behavior while keeping the server-authoritative
inventory responsive when a worker or mobile connection is slow. An identical
durable request can take over an abandoned lease after the worker response
budget, while rotating the lease token so a late worker cannot commit. The
client performs one bounded same-request retry, retains its gameplay root
across short connectivity and lifecycle changes, and keeps confirmed inventory
visible while an exclusive operation is awaiting confirmation.

## Validation

- Release source: pending final commit.
- Version, updater and startup checks target `0.06.10` / build `10103`.
- Flutter analysis reports zero issues. The complete Flutter suite passes with
  1,233 tests and one expected skip; the native Android unit tests pass.
- The worker typecheck and all 35 worker tests pass. The isolated migration
  contract and all 12 rollout-helper tests pass.
- Focused engine tests prove that returning or hatching a rarity-revealed egg
  leaves a reloadable canonical save. The Mastery rotation suite proves all
  three specialist Trials can be generated from restored Mastery dragons. It
  also verifies the two-stage focus/variant draw, classic any-dragon access and
  unlocks from owned specialists that are currently on an Adventure.
- Scheduler integration tests prove an overdue Trial board issues one silent
  durable refresh, and that a refresh held behind an active Trial runs exactly
  once when the attempt ends. The timer itself targets the next quarter-hour
  independently from the slower Adventure schedules.
- Signed APK checks and device update: pending final release validation.

## Server boundary

- Migration 098 updates only the internal canonical lease primitive. Social and
  trade reservation wrappers remain intact, existing receipts stay replayable,
  and stale workers remain fenced by their rotated lease token.
- Migration 099 removes only stale egg-rarity display markers, advances the
  affected canonical revision and rebuilds its hash and social projection. Its
  staging rehearsal and production repair completed with no wallet or inventory
  rollback; the recovered device subsequently completed normal commands.
- The worker uses one 7.5-second upstream response budget. Production keeps the
  compatible minimum client build at `10102` so v0.06.09 remains usable.
- Staging rehearsal, production migration parity, health checks, worker smoke
  test and rollback evidence: pending final release validation.

## Artifact and publication

- Package: `nl.dragonhaven.app`, version `0.06.10`, build `10103`.
- APK digest, size, signing verification, release IDs and permanent download
  verification: pending final release validation.
