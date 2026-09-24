# DragonHaven v0.06.10 / 10103 verification

## Scope

This reliability release keeps the server-authoritative inventory responsive
when a worker or mobile connection is slow. An identical durable request can
take over an abandoned lease after the worker response budget, while rotating
the lease token so a late worker cannot commit. The client performs one bounded
same-request retry, retains its gameplay root across short connectivity and
lifecycle changes, and keeps confirmed inventory visible while an exclusive
operation is awaiting confirmation.

## Validation

- Release source: pending final commit.
- Version, updater and startup checks target `0.06.10` / build `10103`.
- Flutter analysis reports zero issues. The complete Flutter suite passes with
  1,226 tests and one expected skip; the native Android unit tests pass.
- The worker typecheck and all 35 worker tests pass. The isolated migration
  contract and all 12 rollout-helper tests pass.
- Signed APK checks and device update: pending final release validation.

## Server boundary

- Migration 098 updates only the internal canonical lease primitive. Social and
  trade reservation wrappers remain intact, existing receipts stay replayable,
  and stale workers remain fenced by their rotated lease token.
- The worker uses one 7.5-second upstream response budget. Production keeps the
  compatible minimum client build at `10102` so v0.06.09 remains usable.
- Staging rehearsal, production migration parity, health checks, worker smoke
  test and rollback evidence: pending final release validation.

## Artifact and publication

- Package: `nl.dragonhaven.app`, version `0.06.10`, build `10103`.
- APK digest, size, signing verification, release IDs and permanent download
  verification: pending final release validation.
