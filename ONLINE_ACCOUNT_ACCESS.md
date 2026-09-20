# Online account access — 20 September 2026

The owner selected **16+**, replacing the earlier proposed parent/child route.
Public controller/privacy contact: **Rick Groot**, **groot.rick+Dragonhaven@hotmail.com**.

## Entry and privacy

Normal app startup does not construct a game or generate a device guest save
before a verified account. New keepers read the privacy information and explicitly
confirm 16+ before registration. Email verification precedes keeper-name entry
and the starter egg. Incubation starts once, when the name is submitted.

Returning accounts without the current notice acknowledgement receive a compact
notice with the full text expandable. A server RPC records the version, 16+
self-declaration and server timestamp. This is acknowledgement of information,
not bundled consent for necessary processing. It is not identity-verified age
assurance: no date of birth or identity document is collected.

The notice is available in Account Info and in [PRIVACY.md](PRIVACY.md). The full
notice is Dutch/English; the surrounding UI and summary cover all eight app
languages. Outside Dutch, the full-notice label identifies its English text.
`tool/export_privacy_notice.dart` exports the exact in-app notice.

Crash/performance diagnostics are a separate device preference, default off.
The Android Application applies this choice before Firebase ContentProviders
start, including resetting automatic-reporting overrides left by old releases.
Runtime reporting is guarded too. Withdrawal disables SDK collection and removes
unsent crash reports. Push permission remains independent. The native preference
keys are documented Firebase SDK implementation details and must be rechecked
when upgrading its Android dependencies.

## Connection and save ownership

The root queries an authenticated server endpoint at startup and foreground
return. A cached token alone does not open gameplay. Android network loss closes
the whole game Navigator immediately; a tiny server heartbeat runs every ten
seconds with a five-second UI deadline. A server outage without a network-loss
signal can therefore take up to roughly fifteen seconds to detect. Successful
heartbeats do not restart a running trial. Only a new successful server check can
reopen gameplay after failure. No offline guest fallback is present.

Backgrounding or a detected disconnect retires the current gameplay root;
in-progress minigames are not resumed across that retirement. Already saved
progress and admitted operations are preserved. Source requests may outlive a
UI timeout; the next root waits for their settlement rather than duplicating a
reward. Polling cost is up to 360 small reads per foreground player-hour; revisit
this with the growth/load plan before broad scaling.

Local recovery saves are account-scoped. An existing unassigned device save or
conflicting cloud revision requires explicit comparison and selection. Neither
copy is silently overwritten by signing in. Pending Altar requests and unknown
save metadata survive retirement and retry. Existing player inventories,
highscores, event rules and reward probabilities are unchanged.

As of **v0.05.42 / build 10092**, normal gameplay also uses authoritative server
snapshots and commands. Production commands and migration are enabled with the
reviewed worker and minimum compatible build. Startup reads account authority
before considering device progress. Fresh accounts initialize on the server;
existing accounts complete a protected transfer before entering the server game.
Old clients cannot enter the handoff or overwrite a migrated account.

Install this update and finish the first sign-in on the existing installation
before removing it. After transfer, an empty installation restores confirmed
progress from the account, including inventory, materials, relic tradeability,
active timers, collections, settings and Conclave read receipts. See
[SERVER_GAMEPLAY_ROLLOUT.md](SERVER_GAMEPLAY_ROLLOUT.md) for complete coverage.
Diagnostics consent, push registration and OS permissions remain device-specific.

## Original online-access server change (v0.05.41)

Additive migration **202609200088** adds a private acknowledgement table and three
verified-account RPCs. It changes no existing economy RPCs. The table has RLS and
no direct anon/authenticated grants; account deletion cascades its record.
`tool/online_access_notice_contract.sql` covers rejected missing/false age,
old versions, unverified/deleted users, account isolation, idempotent saves,
permissions and deletion cleanup. Synthetic test rows are rolled back.

The migration and contract were rehearsed, applied and verified on staging,
then rehearsed, applied and verified on production. Both have 88 migrations.
The three new functions passed PostgreSQL lint on both environments. Production
Auth health, Auth settings and application health returned HTTP 200. Runtime
switches and server-owned account counts were unchanged.

Release v0.05.41 / 10091 packages this implementation. Publication evidence is
recorded in [RELEASE_V0.05.41_VERIFICATION.md](RELEASE_V0.05.41_VERIFICATION.md).
The review APK uses a separate emulator-only package.

## Original online-access verification (v0.05.41)

- Complete Flutter suite: **1,025 passed, one existing optional test skipped**.
  Two additional focused tests passed for password-confirmed account deletion:
  reauthentication can retire the old game lease without blocking deletion, and
  completion of account A's deletion cannot sign out a newly selected account B.
- Flutter/Dart analysis and reference-documentation verification passed.
- Android debug build succeeded and installed as `nl.dragonhaven.app.online_review`
  on the emulator. Registration and the expandable notice were visually reviewed.
  The physical phone's production installation and player save were not changed.
- Native Firebase collection defaults were inspected on the emulator. Simulated
  persisted `true` settings from older releases were reset to `false` on startup
  when no diagnostics opt-in existed.
- Migration 88, rollback-only SQL contract tests and lint of all three new RPCs
  passed on staging and production. Public production health was verified at
  **2026-09-20 13:02 UTC** (Auth, Auth settings and app health: HTTP 200).

## Server ownership rollout (v0.05.42)

Schema 92 and the tested worker are deployed. Production initialization replay,
onboarding and a fresh authentication session restored an identical full account
snapshot; the synthetic probe account was deleted. Final server preflight at
**2026-09-20 16:04:19 UTC** reports 92 matching migrations, zero lint errors and
healthy Auth/application endpoints. The complete Flutter suite passed 1,041
tests with one existing optional skip. Publication, signing, artifact and
activation evidence: [RELEASE_V0.05.42_VERIFICATION.md](RELEASE_V0.05.42_VERIFICATION.md).
