# DragonHaven server-authoritative economy contract

## Social projection verified; reservation integration candidate (10 September)

Migration **68** passed its rollback rehearsal in run
[34464063663](https://github.com/Rakky88/DragonHaven/actions/runs/34464063663)
and was then applied and verified in full staging run
[34464193111](https://github.com/Rakky88/DragonHaven/actions/runs/34464193111)
on `3fc02c1`. All 858 tests, timezone checks, Edge/parity checks and the real
app/server harness passed. The projection contract passed before and after
apply. Final health at **10:16:16 UTC**: 68 migrations, lint 0 and all three
HTTP endpoints 200. Synthetic accounts were removed and worker/social/
projection switches disabled. Production stays on schema 65, release 29.

The next candidate, migration 69, seals one database-owned group/partner
dragon-reservation view into each command lease and the public snapshot.
Changed sources refuse commit with an explicit rollback result; receipt replay
still returns the original result after a reward releases its dragon. Domain
and public display share the same ownership/conflict validation. The five
local reservation tests include real Trial/Academy starts, release refusal,
ordinary adventure preservation, owner changes and pupil/mentor collisions.
Legacy social lifecycle/acknowledgment RPCs are fenced for promoted accounts.
**New canonical create/join/leave/partner action screens are not connected yet;
this candidate establishes their reservation boundary. Migration 69 is not
yet rehearsed or applied.** Two-owner trades, Conclave/rankings, full gameplay
cutover, representative migration and lossless APK reduction remain open.


## Current checkpoint: 10 September 2026

Staging run [34462032107](https://github.com/Rakky88/DragonHaven/actions/runs/34462032107)
on `bd4f548` passed all **858 tests**, clean analysis, Amsterdam/New York timer
and calendar tests, Edge contracts, native/JavaScript parity and the actual
Auth/Edge/Postgres app harness. Original Trial, Academy, profile and milestone
screens completed without render errors. Group, partner and podium rewards
were claimed once through the UI and acknowledged in the same transaction;
the partner's own reward remained available. Both synthetic accounts and all
command journals were removed, both staging switches disabled. Final staging
preflight: **67 migrations, lint 0, Auth/settings/application HTTP 200 at
09:52:51 UTC**. Production remains on schema 65 and release v0.05.29 / 10079;
no player has been promoted or production reward source consumed.

Next candidate: migration 68 projects committed wallet totals, owned dragon
facts and social showcase data atomically with the canonical revision. It
preserves historical dragon UUIDs while marking released dragons unavailable.
A separate, disabled-by-default rehearsal switch isolates shadow copies.
Old authenticated RPCs cannot overwrite server-owned wallet/dragon/inventory
or showcase rows. An explicit rollback contract covers projection failure,
receipt replay, exact balances, stale discoveries, release/return identities
and old-client refusal. **Migration 68 is not yet applied or verified on
staging.** Social lifecycle/reservations, two-owner trades, Conclave/rankings,
full gameplay cutover and representative player migration remain open, then
lossless APK reduction and the single authorized release.

The dated component sections below are historical evidence, not a claim that
the full server economy or release is complete.

Last updated: **10 September 2026**

Release **v0.05.29 / 10079** is published and verified. At publication, production and staging
had **65 migrations**. Latest production pre/postflight: parity 65, lint 0 and
Auth/settings/application HTTP 200; accounts remain legacy, game/economic
mutations disabled, zero shadow copies, production push enabled. See
`RELEASE_V0.05.29_VERIFICATION.md`. The older per-component runs below retain
their original schema numbers and timestamps.

Resumed after v0.05.29: authoritative furniture placement/removal, floor
reordering and roaming passed staging run 34399422518 on `2a81df7` (754 tests).
UTC server days, monotonic daily markers and DST-safe streak arithmetic passed
run 34401056711 on `ca558f7` (759 tests). Both runs proved real UI/network
behavior, cleaned their synthetic state, disabled the worker and passed schema
65/lint 0/Auth/settings/application health. House/resident/care import guards
and the existing 3-gem Starlight Treat control passed run 34403445166 on
`cd3b6e9`: 766 tests, explicit Dutch/US DST tests, 16 Edge tests, native/JS
parity and the actual server/UI harness. The same candidate fixes rapid-tap
Runeweaver duplicate completion. Staging cleanup and final health passed at
21:01:55 UTC; production read-only parity/lint/health passed at 21:02:55 UTC.
This remains partial gameplay integration, not live migration or full economy
completion. See `SERVER_ECONOMY_UI_VERIFICATION.md`.

The resumed audit now connects the ordinary furniture/relic/vanity shop and
chest reveal to the canonical session in an explicit staging-only app lane.
The lane starts before legacy storage loads, uses separate Auth/cache keys,
and rejects production URLs. Shop counts and balances come from a validated
public projection; absent or stale state never falls back to local stock.
A shared action boundary fences callbacks by account epoch and observed
revision. Opening failure leaves an exit instead of a stuck animation.
Local real-rule and widget tests cover lost receipts, double taps, background
completion, account changes, paused/offline browsing and one server chest grant.
Real Auth/Edge/Postgres UI proof passed in run 34281388567, including cleanup
and final health; see `SERVER_ECONOMY_UI_VERIFICATION.md`.
The full existing gameplay UI, verified trials, social settlement and player
migration/cutover remain open. No production authority switch was changed.

The subsequent egg/Altar/dragon UI extension passed staging run 34286596835
on source `29c2519`, including all 663 tests, native/JavaScript parity and real
Auth/Edge/Postgres commands driven from the screens. It covers tags, Sinister
return, crafting/discovery, nest incubation, Quill rename and exclusive brooch
equipment, with local server-clock hatch/Chronoshard and lost-reply coverage.
Cleanup removed its synthetic accounts and shadow state, disabled the worker,
and rechecked schema 59, lint 0 and health HTTP 200 at 22:41:02 UTC.
Ordinary Adventures/Wayfinder passed run 34289398487 on `33d4fc5`: all 669 tests,
native/JavaScript parity, an actual server deadline, early-claim refusal and
one reward after a deliberately lost claim. Cleanup and final staging health
passed at 23:19:28 UTC on 8 September. House purchases, repairs and wards passed
run 34290527414 on `a53fb50`, all 675 tests and real UI commands; cleanup and
schema 59/lint 0/health 200 at 23:33:58 UTC. Dragon preferences and the combined
UI regression passed run 34291657311 on `32817ed`: all 679 Flutter tests,
15 Edge tests, native/JavaScript parity and actual server interactions. Cleanup
removed both synthetic accounts and shadow data, disabled the worker, and final
schema 59/lint 0/Auth/settings/app HTTP 200 passed at 23:49:09 UTC. Current component
evidence and explicit remaining boundaries are maintained in
`SERVER_ECONOMY_UI_VERIFICATION.md`.

Previous release evidence:
Released app: **v0.05.19 / 10069**; production **56**, staging **57**.
Release workflow 34157071933 passed with 596 tests; APK/latest-download and
post-publication server checks passed. See `RELEASE_V0.05.19_VERIFICATION.md`.
Production migrations 50–56 were applied after exact staging-source evidence
34153525465 and rollback-only contracts for push/game/import/read/receipt/ruleset.
Mandatory preflight: exact 56-migration parity, lint 0, Auth/settings/app 200.
All accounts remain legacy; economic mutations and the game worker are disabled,
with zero shadow copies. This rollout does not enable live server economy.
Migration **49** adds owner-scoped inventory pagination and passed its staging rehearsal and applied contracts in run `34127201082`. Production run `34129277707` then proved identical staging source, rollback rehearsal, exact migration 49, repeated snapshot contract, parity, zero lint errors and health 200. Mutations remain disabled and all accounts remain legacy.
Migrations **45-47** are deployed dormant: chest opening, server inventory guard and item shop.
Production run `34116589237` passed exact staging-source checks, rollback rehearsals, all three contracts, migration parity, zero-error lint and health. Before/after checks prove mutations remain disabled and all accounts remain in legacy compatibility.
Staging runs `34110497546`, `34110676557` and `34111166461` passed rollback contracts, parity, lint and health. No economy activation is included.

## Implementation and verification history

The dated records below retain the state of each earlier rehearsal and rollout.
The overview above and `SERVER_ECONOMY_UI_VERIFICATION.md` track the latest
component evidence and remaining activation work.

### Resumed after v0.05.19: damaged-journal recovery

The owner authorized continuing the server economy after the release. Candidate
migration 57 adds an idempotent recovery boundary for damaged local intents.
Recovery cancels only unfinished shadow leases and advances the game revision
without changing assets. Already committed receipts remain available. New
commands must name the revision originally observed; delayed pre-recovery
requests receive a durable refusal, including previously unseen request UUIDs.
The unfenced lease RPC is no longer executable by the service role.

The client retains a separate two-copy recovery marker until the new boundary,
fresh absolute snapshot and display are durable. Interrupted cleanup, a lost
response, corrupt recovery markers and account switches cannot reopen the
command lane early or invent a new purchase. A healthy original intent still
uses ordinary receipt reconciliation. Recovery works while mutations are paused.

The exact migration and database contract passed a rollback-only rehearsal on
registered staging. All 604 Flutter tests, 14 worker tests and full analysis pass.
Run [34254991384](https://github.com/Rakky88/DragonHaven/actions/runs/34254991384),
source `f4cc7f2c8de6c87fd6b3d37f2f91ab326d419a6a`, then applied exactly 57,
repeated all six contracts before/after, deployed the worker and proved real
Auth/Edge/Dart/Postgres recovery, stale-request refusal and paused cancellation.
Both synthetic accounts, copies, intents and recovery receipts were removed;
runtime returned to disabled. Final staging parity 57, lint 0, Auth/settings/app
200. Production remains on 56 with legacy accounts and economic mutations off.

The next client component is `CanonicalGameSession`: owner/epoch-scoped display,
fresh-read permission to act, one command at a time, durable intent/recovery
resumption and offline cached viewing. It remains detached from main/UI while
the session behavior is tested; no shadow inventory replaces a live save.
Eight session tests and the 26 existing transport/reconciliation tests pass.
The staging probe also exercises the actual Flutter session and filesystem
journals with a real authenticated synthetic account: dropping a committed HTTP
receipt, restarting, then corrupting both intent files. This passed in
[34256256939](https://github.com/Rakky88/DragonHaven/actions/runs/34256256939),
source `65a4705958f2d56159211dc3619d584bcb267766`. One purchase charge survived
the lost response; corrupt-intent recovery created no additional purchase.
Its child received no service/management credentials. Final cleanup, schema 57,
lint 0 and Auth/settings/app 200 passed, with the staging game runtime disabled.
This completes the current session/recovery component. The subsequently requested
event theming, training highlights, picker shortcuts, Halloween test scoring/
rewards and persistent dragon sex are now implemented as an unreleased feature
change. All 621 Flutter tests, full analysis and reference checks pass. The
updated shared game bundle compiles, and native/web sex values agree for 109
synthetic identities. Production health remains 200/200/200; no schema or runtime
switch changed. See `EVENT_THEME_AND_TRAINING_VERIFICATION.md`. Full live economy
routing remains open; the weighted economy checklist is not advanced by these
product features.

### Public display projection candidate

Migration 54 adds a service-only private read for the authenticated Edge worker.
It requires a prepared import and matching build/ruleset, but permits reads
while mutations are paused. The worker returns only the explicit Dart display
projection, owner, revision and `shadow` authority. No live client applies it yet.
The eight projection tests cover Lens versus Oracle, hidden alignment and Soul
Mirror personality, nest/hatch transitions, Special/Sinister appearance and
protection, trade animation payloads, future metadata, and preselected adventure
rewards. Twelve worker tests cover commands and authenticated reads. VM/Deno
parity now includes projections before and after hatching. Staging run
[34150477904](https://github.com/Rakky88/DragonHaven/actions/runs/34150477904)
applied exactly migration 54, passed contracts 52–54 before and after, and proved
real authenticated projection, hidden eggs, committed rename/return visibility
and paused reads. Synthetic accounts/copies were removed; runtime is disabled.
Final parity: schema 54, lint 0, Auth/settings/app 200; production remains 49.
Full client routing, durable application, verified trial transcripts, timezone
rules, normalized social/trade settlement and production cutover remain open.

The client now has a distinct immutable `CanonicalGameSnapshot`, nullable egg
facts, owner/revision validation, session-epoch fences and a bounded reader.
Its private display journal flushes a separate revision fence before the full
snapshot, detects corrupted cache bytes, preserves the greatest surviving
revision and repairs display files only from a fresh read. Fourteen tests cover
real projection decoding, delayed/ABA account switches, timeout, concurrency,
checksum corruption, interruption between files and equal-revision conflicts.
These are display/transport components; no production UI applies shadow data.

The detached client command coordinator now journals two checksummed copies of
each intent, resumes the same UUID/payload, fetches a snapshot at least as new as
the receipt/cache, persists it, applies the absolute display and acknowledges
last. Eleven tests cover lost commit responses, local save failures, duplicate
submits, account changes, old receipts, durable refusals and damaged journals.
If both intent copies are unreadable it deliberately requires recovery instead
of guessing a fresh purchase; the recovery candidate described above now handles
that case without exposing private intent history. Migration 55 lets completed success/failure receipts replay
while mutations are paused or the ruleset changed, while new/unfinished leases
remain gated. Run
[34151895090](https://github.com/Rakky88/DragonHaven/actions/runs/34151895090)
applied exactly 55 after contracts 52–55, deployed the compiled worker and proved
both paused success and failure replay with new mutations refused. The original
live save/wallet stayed unchanged, synthetic accounts were removed and runtime
was disabled. Final schema 55, lint 0, Auth/settings/app 200.

The staged client transport now uses the confirmed existing Supabase session,
an account epoch, a fixed staging URL, redirect refusal and per-request HTTP
clients that close on completion/timeout. Response streams are bounded at 9 MiB.
Seven SDK-backed local tests cover authorization, ownership, ABA account changes,
closed stalled connections, response limits and durable refusal status. It has
no service credentials and cannot target production. Main/UI wiring is pending.

Local migration 56 adds a monotonic ruleset revision to public observations.
Changing compiled rules increments it; pausing mutations or a no-op does not.
The client journals both game and ruleset revision floors, so a new projection
can replace the same game revision after an upgrade, and a delayed old worker
cannot undo that update. Sixteen snapshot tests include partial rules-only writes
and delayed downgrade refusal. Run
[34153525465](https://github.com/Rakky88/DragonHaven/actions/runs/34153525465)
applied exactly 56, passed contracts 52–56 and the real Auth/Edge/Dart/Postgres
probe. Both synthetic accounts and all shadow commands were removed; runtime
is disabled. Final schema 56, lint 0, Auth/settings/app 200.

The Altar picker, adventure Expertise details, tutorial review and v0.05.19
release are complete. The owner has resumed the server-economy assignment.
Full live economy routing, verified trials, social settlement and account
cutover remain explicit open work.

### Shared rules candidate

`GameCommandEngine` now evaluates catalog purchases, bounded chest openings,
relic use, incubation/hatching, dragon progression, solo adventures, housing,
constellation claims and Altar actions using the existing Dart rules. Flutter
keeps its native notifier/audio/notification/storage adapters. The server
build uses no device storage, audio or pre-commit notifications. Translation
data and preference enums are shared without importing Flutter.

The compiled internal entrypoint is under 1 MB locally. The first synthetic
VM/Deno comparison passes, including absolute state, hidden egg properties,
reward values and generated identities. Twelve contract tests cover the private
entropy vector, deterministic retries, wallet limits, failed batches, rejected
client grants/scores, tags, Sinister confirmation, quill consumption and
server-clock incubation. The asset fence also refuses a load that silently
discards owned content, changes fixed egg/Chronoshard properties, duplicates
identities or changes progression. Such saves require reconciliation first.
The export envelope also retains unknown top-level and entity metadata by ID
through hatching and dragon transfers, while replacing authoritative stock.
Altar callbacks are bound to the trusted keeper. Foreign ownership and a pending
legacy Altar operation refuse commands until import reconciliation is complete.
This is deployed only as a detached staging candidate. The live economy has
not been activated.

The worker must obtain state/time/owner/secret seed from PostgreSQL, reserve one
intent per owner, then commit by revision comparison in one transaction. Public
requests may contain only whitelisted intents. Full save conversion, private
egg projection, normalized trade/Altar/social synchronization, validated trial
transcripts, server timezone behavior, durable full client application and
staging cutover/restore exercises remain open. The entrypoint intentionally
does not accept arbitrary score, reward, paid entitlement or settlement grants.
The current production mutation switch remains off.

The `execute-game-command` worker now validates each bearer token with Supabase
Auth and takes only a protocol/build, request UUID, whitelisted action and its
bounded identity arguments. It reserves the private database lease, invokes the
compiled Dart rules and commits by lease/revision. It returns a bounded receipt
marked `shadow`, never the private save, hidden egg genetics, entropy or lease.
Nine worker tests cover forged input, cross-owner results, concurrent/repeated
intents, lost commit responses, durable domain refusals and stream limits.
The staging apply/probe workflow builds the exact ruleset, rehearses migration
52, deploys the worker and exercises real synthetic Auth requests before cleanup.
The full live inventory projection and app integration remain separate work.

`GameImportPreparation` is an internal, tested copy-preparation step. It binds
the captured Altar owner/revision, preserves discoveries while using exact server
tags, reconciles previously returned stashed eggs without another reward, and
refuses stale/missing ledgers, mixed offline stock and contradictory returned
dragons/nests/Special Eggs. Six behavior tests pass. Unknown owned content and
missing fixed relic values still require review. This does not yet perform a
database preparation commit, refresh an old import generation or promote anyone.

Migration 52 adds a detached shadow copy of the full cloud save, an immutable
source/hash plus the separately captured authoritative Altar, and a private
command transaction. Only service-role RPCs can read a seed/state or claim a
lease. The original seed/time survive a retry; expired workers are fenced by a
new token, conflicting payloads fail, and one owner has at most one pending
command. State and receipt commit together by revision comparison. The schema
constrains these copies to `shadow` and cannot activate live economy ownership.
Initial staging run
[34143594035](https://github.com/Rakky88/DragonHaven/actions/runs/34143594035)
passed the full-copy, lease/replay, owner, wallet and account-deletion contracts
and rolled back all schema, fixtures and changes. Captured Altar state still needs
explicit reconciliation before any production conversion.
Run `34146256475` subsequently applied exactly 52 and deployed the shadow worker:
the contract passed before and after, with parity 52, zero lint errors and healthy
Auth/application endpoints. The first HTTP probe stopped before creating test
accounts because its management response was not parseable; this is not yet a
successful end-to-end worker proof. Production remains at 49.

That proof subsequently passed in
[34147658644](https://github.com/Rakky88/DragonHaven/actions/runs/34147658644),
source `19979ee`: real confirmed Auth, Edge, compiled Dart and PostgreSQL;
purchases, concurrent/repeated chest opening, tags, Sinister confirmation and
25-fragment/3-5-essence/0-1-heart return, then crafting and consuming a quill.
The original live save and wallet remained equal. Both synthetic accounts and
all shadow rows were removed, runtime disabled, schema parity 52, lint zero and
health 200. CI ruleset SHA-256:
`11fc9bc5f68b6cec93da60abab7918b164a32810831283f888b3eb8297ffbd81`,
901,387 bytes. All 552 local Flutter tests pass. This proves the detached worker
path; it does not activate the live economy or validate every remaining reward.

Candidate migration 53 retains immutable import generations when a cloud save
or the authoritative Altar changes. Its service-only preparation commit checks
the current generation, source, Altar, game revision, pending command and ruleset,
then stores the prepared shadow copy and immutable receipt atomically. Wallet
coins/gems cannot change during preparation. Retries replay the original receipt;
account deletion cascades through all generations. This candidate has not yet
been applied; its separate staging rollback contract is the next gate.
That rollback contract passed in
[34148415163](https://github.com/Rakky88/DragonHaven/actions/runs/34148415163):
immutable generations, changing cloud/Altar snapshots, pending/revision fences,
receipt replay, unchanged live state and account cleanup. The staging apply
workflow now also runs the internal `prepare_staging_game_import.ts` against a
captured synthetic Altar, repeats its receipt, then runs the proven game actions.
The operator tool is restricted to registered staging and never logs its private
source, seed or service key. Applying 53 and this combined probe are still pending.
The combined gate has now passed in
[34148722971](https://github.com/Rakky88/DragonHaven/actions/runs/34148722971),
source `5cdfc22`: exactly 53 applied, both rollback contracts repeated, the
captured Altar prepared and replayed through compiled Dart, then all real game
probe actions passed. Cleanup removed both accounts and shadow records, runtime
returned to disabled, and final parity 53/lint zero/Auth+app health 200 passed.
Production remains 49 and all live accounts retain legacy ownership.

`EconomySnapshotStore` now persists complete owner-scoped snapshots outside
cloud backups, with atomic replacement and monotonic wallet/server revisions.
`EconomyChestReconciler` retains the original request through lost responses,
local disk failures, game-save failures and account switches; acknowledgement
happens only after both the snapshot journal and game projection succeed.
Six new real-filesystem/recovery tests and the nine existing snapshot-reader
tests pass. The production UI remains dormant until full inventory conversion
and game-projection integration have been completed. This boundary is not yet
an enabled purchase flow or a complete egg/dragon economy.

## Purpose and current boundary

DragonHaven currently keeps most gameplay progression in the local/cloud save.
The online schema already mirrors wallets, dragons, eggs, chest stacks,
furniture and relics for import, social play and safe trades, but that mirror is
not yet allowed to become the source of truth for purchases or ordinary reward
claims.

Migration 37 builds the missing transaction boundary without switching it on.
Migration 39, already applied dormant in production and staging, adds the first concrete, idempotent vanity-chest purchase
RPC, but it is still unreachable because every keeper remains in
`legacy_client` mode, the app feature flag is `false` and the global
`mutations_enabled` switch starts as `false`. Neither migration adds a live paid
product or changes a current balance.

This is deliberately free-first: it uses PostgreSQL and Supabase capabilities
already present in the project. The same ledger can later distinguish earned
currency from a validated Google Play purchase without storing card details,
receipts or unnecessary personal data.

## Ownership model

| Valuable state | Authoritative table after its later cutover | Foundation in migration 37 |
| --- | --- | --- |
| Coins and gems | Existing `player_wallets` | Revisioned balance plus append-only ledger entries |
| Dragons | Existing `player_dragons` | Existing per-owner instances remain the target |
| Eggs | Existing `player_eggs` | Existing per-owner instances remain the target |
| Chests | `player_chest_instances` | One row per chest, preserving source and tradeability |
| Relics and other collectibles | `player_item_instances` | One row per collectible with lifecycle and bounded metadata |
| One-time/daily rewards | `economy_reward_claims` | Unique `(owner, claim_type, claim_key)` claim identity |
| Request replay protection | `economy_mutation_requests` | Unique `(owner, request_id)` plus request SHA-256 |
| Economy audit | `economy_ledger_entries` | Append-only source, mutation, delta, balance and server time |

The current aggregate `player_chests` and `player_relics` tables remain intact
for compatibility. They are not silently copied to instances by migration 37;
that conversion needs an explicit, measurable staging migration and rollback
proof after the player-progression policy is approved.

## Mutation lifecycle

Every future economy-changing public RPC must execute the following steps in
one database transaction:

1. Require an authenticated `auth.uid()` and call
   `private.assert_economy_client` with protocol and app build.
2. Call `private.begin_economy_mutation` with a client-generated UUID, operation
   name and bounded JSON request.
3. If that UUID already succeeded or failed with the same request hash, return
   the stored result. A reused UUID with another operation or payload fails as
   `economy_idempotency_conflict`.
4. Lock the affected ownership rows, validate availability and caps, and make
   every random roll on the server.
5. Apply the balance/instance/claim change and append its ledger rows.
6. Store the complete privacy-safe response with
   `private.complete_economy_mutation`. A controlled failure stores only a
   stable failure code through `private.fail_economy_mutation`.
7. Commit once. Any exception rolls the ownership mutation, ledger and request
   completion back together.

Rate limiting happens only for a new request. A legitimate retry with the same
UUID therefore returns its earlier result instead of consuming another reward
or another rate-limit slot.

## Ledger semantics

Each entry records:

- keeper UUID and optional idempotency request UUID;
- asset kind and stable asset key;
- mutation type, such as `credit`, `debit`, `grant`, `consume`, `transfer_in`,
  `transfer_out` or `refund`;
- source type, such as Adventure, Trial, chest, shop, trade, purchase or system;
- signed quantity difference and, for coins/gems, non-negative balance after;
- optional bounded source reference and bounded non-personal metadata;
- immutable database time.

An update/delete trigger rejects changes to existing ledger rows, including for
ordinary administrative code. Corrections must be new compensating entries, so
history remains reviewable. The sole deletion exception is the nested
foreign-key cascade caused by full account/profile deletion; this prevents the
ledger from defeating the user's account-deletion right. Direct table access is
revoked from `anon` and `authenticated`; clients receive only purpose-built RPC
results.

## Compatibility window

`player_economy_authority.authority_mode` supports three explicit stages:

- `legacy_client`: current behavior; new economy mutation helpers reject use;
- `shadow`: later compare client intentions with a server calculation without
  awarding or subtracting anything;
- `server`: only the server may accept valuable mutations.

The private contract separately stores the protocol version, minimum app build
and global emergency switch. A future mutating RPC is accepted only when the
global switch is enabled, the keeper is in `server` mode, both protocol versions
match and the app build is not below the minimum. `get_my_economy_contract` is a
read-only authenticated projection that lets a client decide whether to keep
using legacy behavior, participate in shadow verification or require an update.

Old clients must never be promoted to `server` mode. Before the first keeper is
promoted, cloud-save restore/import must also be changed so server-owned fields
cannot be restored, duplicated or overwritten by an old save.

## Privacy and retention

- No email address, display name, chat content or payment card data belongs in
  these tables.
- No purchase token or raw store receipt belongs in these tables.
- Request and result JSON are bounded to 32 KiB; item/ledger metadata is bounded
  to 8 KiB and reward plans to 16 KiB.
- Request records default to a 30-day expiry marker. Physical cleanup will only
  be added once replay/support retention and refund requirements are agreed;
  until then no cleanup job may silently weaken idempotency.
- Full account/profile deletion cascades through the keeper's economy rows,
  including ledger history. Normal ledger edits and standalone deletes remain
  blocked.
- The public contract RPC returns only mode, protocol/build requirements and
  revision numbers—never inventory or ledger contents.

## Safe rollout sequence

1. **Local candidate:** static contract tests, formatting and full Flutter suite.
2. **Staging schema — passed:** migrations 37–38 have exact parity on isolated
   staging. Runs `33981322674` and `33981974136` proved database lint,
   RLS/revokes, the read-only contract, dormant defaults, idempotent replay,
   payload-conflict and old-client rejection, rate limiting, transactional
   rollback and healthy public endpoints.
3. **Dormant mutations — deployed and proven:** migrations 39 and 45-47 provide
   vanity-chest purchases, chest opening, a legacy-upload guard, furniture and
   shop relics on production/staging 47. Rollback contracts and client tests
   cover replay, fixed rewards, prices, ownership and atomic ledgers. All
   production accounts remain in legacy mode and mutations remain disabled.
4. **Representative migration:** convert copies of real-shaped but synthetic
   saves, verify totals and hashes, then prove a forward-only rollback exercise.
5. **Small server cohort:** enable `server` per selected staging keeper, never
   globally first; test double taps, timeouts, reconnects and older clients.
6. **Production schema:** separate permission and migration gate. Keep all
   authority rows `legacy_client` and global mutations disabled.
7. **Production cutover:** separate product decision and explicit permission,
   with player communication, support coverage, monitoring and compensation
   policy already accepted.

Database rollback is fix-forward. Applied migration files are never rewritten
and production is never reset. Before server authority is enabled, disabling the
feature flag and global mutation switch is sufficient because no current app
path depends on migration 37.

## Still required before valuable server mutations

### Codex

- prove candidate 49's complete paginated inventory read on staging, then wire
  owner-scoped durable snapshot application before acknowledging pending intents;
- build the full save-to-instance conversion; the old trade mirror omits valuable
  non-tradeable and special content and is not a complete conversion source;
- extend the existing atomic purchases/opening to the remaining shops;
- execute the shared rules with private server entropy and commit randomness,
  collection checks and full inventory changes atomically through PostgreSQL;
- filter server-owned fields out of save restore/import after cutover;
- add timeout/reconnect and double-submit E2E around the first concrete mutation
  RPC; foundation-level replay, conflicting payload, rate-limit, rollback and
  old-client rejection are already proven on staging;
- later extend the same pattern to eggs, dragons, progression and daily claims.

### Rick

- confirm which existing progress must never be reduced without human review;
- approve the migration window, player communication and rollback policy;
- choose compensation behavior for failures and whether earned and purchased
  gems need separate spend rules;
- decide which gameplay stays view-only or queueable during a server outage;
- decide the production migration/cutover window and its player impact. Current
  audit authorization covers isolated staging development and rehearsals.

The production project has migrations 1-49; staging additionally has push migrations 50-51 and shadow game/import migrations 52-53. Migration 48 only opens
the simulated Halloween preview to verified keepers (production run `34127198552`). The global mutation
switch remains disabled and every production keeper remains on `legacy_client`. Migration 38
is the immutable forward fix for the timestamp ambiguity found in migration 37.
The authorized v0.05.18 public release ships the UI and client compatibility changes.
It does not activate economy ownership for players.

## Proven legacy-import restore rehearsal

Run `34120524533` executes `tool/legacy_import_restore_contract.sql` only against
synthetic staging accounts. Temporary helpers restore the private pre-import
snapshot and prove complete JSON/row equality and SHA-256 equality for wallets,
dragons, eggs, chest stacks, relics, furniture and discovered lineages. Tests
reject changed inventory, expired backups, wrong owners and server authority;
partial-write failures roll back. The existing audit and one-time import marker
remain intact, preventing a second grant. All rehearsal changes then roll back.

The request took 1,250 ms and the synthetic restore stayed under ten seconds.
This is neither a production restore RPC nor a measured RTO for real large
inventories. A reviewed operational procedure and aggregate-to-instance
conversion still need implementation before cutover.

## Dormant deployed inventory snapshot (migration 49)

`get_my_economy_inventory_page` reads absolute coins/gems, wallet/server revision
and up to 100 current chest/item instances. A shared owner lock makes each page
consistent; subsequent pages must name the first page's server revision. A
mutation invalidates the cursor with `economy_snapshot_changed`. Consumed items
and opened chests are excluded. Reserved/equipped ownership and fixed
Chronoshard percentages remain explicit. Internal metadata, source references
and hidden egg identities are never returned. The endpoint requires server
authority and compatible clients but stays readable when mutations are disabled.

`EconomyInventoryReader` checks ownership, types, revisions, strict row ordering
and cursors, discards partial downloads and permits one fresh attempt after a
revision conflict. Minimum receipt/local revisions prevent stale reconciliation.
It returns an immutable complete snapshot; it does not mutate the game, overwrite
storage or acknowledge an intent. Durable local application, egg/dragon snapshot
support and UI activation remain open. Nine client behavior tests are green.
Staging run `34127201082` passed the rollback rehearsal, applied exactly 49,
repeated the inventory contract and the foundation/vanity/chest/item-shop
contracts, and proved 49 migrations, zero lint errors and healthy endpoints.
All synthetic contract changes rolled back; economy activation remains disabled.

## Phase 4B chest-opening candidate, 7 September 2026

`open_chest_instances` accepts one request UUID and 1-10 distinct instance UUIDs.
It uses the existing protocol/build/global/owner gates, a per-owner advisory
lock, authority/wallet/chest row locks and the append-only ledger. Each chest
also keeps its receipt so even a different request UUID cannot reroll rewards.
The bounded JSON response contains absolute wallet balances/revisions and
instance identities; callers must reconcile by revision, never add reward
amounts to local balances on replay. A completed collection does not consume a
vanity chest. A bad/foreign/reserved chest rolls the entire batch back.

The pure catalog exporter snapshots all current vanity/emote/lineage/relic and
Special catalogs. Server crypto draws use rejection sampling for inclusive
integer ranges; the private deterministic probability helper allows exact edge
checks without exposing client-supplied randomness through an RPC.
[PostgreSQL random-data reference](https://www.postgresql.org/docs/17/pgcrypto.html#PGCRYPTO-RANDOM-DATA-FUNCS).
Egg pity is recomputed inside the batch and includes the occupied nest. Hidden
identity is not included in the opening receipt. Chronoshard's percentage and
Twinstar's lifetime acquisition are persisted independently of client backups.

The account-scoped `EconomyChestIntentStore` flushes an intent before sending,
keeps it through timeout/restart, rejects replacement by a second intent, and
requires explicit acknowledgement after successful reconciliation. It remains
a dormant integration boundary; the production UI still opens local chests.
Migration 46 denies legacy import/sync for server accounts, including access to
renamed wrapper functions; it does not rewrite or remove legacy player saves.

Validation: `tool/chest_opening_contract.sql` creates only synthetic users and
rolls back all switches, ownership, grants and assertions. The staging workflow
first rehearses both migrations with that contract. Applying them is a separate
boolean within the same staging-only workflow and requires the rehearsal to pass.
Remaining: full aggregate-to-instance import/rollback, authoritative snapshot
reconciliation and activation, remaining shops, egg/dragon lifecycle and reward
claims. These items are not marked complete by this candidate.

## Dormant item shop candidate (migration 47)

`purchase_economy_item` handles catalog furniture and the four purchasable Mystic
Relics. The request contains identities only; price, currency and tradeability
come from a versioned server snapshot verified against every client shop item.
Furniture already owned, equipped or reserved returns the existing instance
without a second charge. Relics may be purchased repeatedly for 500 gems and
are non-tradeable, matching the app. Supporter goods and non-shop relics cannot
be selected. Replay returns the original outcome, including insufficient funds;
a player must make a fresh purchase intent after obtaining more currency.

The staging contract covers exact prices, receipt replay, duplicate furniture,
ledger conservation, prohibited goods, relic tradeability and insufficient funds.
Starlight Treat and room unlocks depend on the phase 4C dragon lifecycle and are
not implemented by this RPC. Paid products remain disabled.

## Academy input authority candidate (10 September 2026)

All ten Academy lessons now share a seeded, elapsed-time model between the
existing game screen and the server. Start reserves pupils and mentor; finish
accepts bounded timed inputs, replays them and awards the existing stars/XP
once. The client cannot submit a score. Abandoning consumes a zero-star attempt
without crediting the mentor. Lost start/finish replies recover the same attempt
and receipt; account changes hide the former participant data. Graduation is
also a checked command. These screens remain in the detached staging lane.

Focused domain, recovery and real-sprite widget tests pass. Native Dart and the
compiled JavaScript agree for all ten lesson command sequences. Dutch narrow
screens were inspected in `release/economy-school-visual/`. Full-suite and actual
staging Auth/Edge/Postgres proof are pending for this candidate. Production
remains schema 65 with legacy authority and disabled game/economy mutations.

The accompanying Sunwake change removes the game timer and 20,000-point cap,
starts faster, and ends on the third collision. A one-hour actual model run and
an eight-hour rollback SQL contract pass. Migration 66 adds owned-attempt lease
renewal and elapsed-time score/action bounds. It has only been rollback-rehearsed
on staging so far. The app header now keeps the full brand visible and shows
compact balances, with exact totals on tap. Both changes wait for the complete
economy and lossless APK work before release. No APK reduction is claimed yet.


Academy staging proof completed in run
[34446694129](https://github.com/Rakky88/DragonHaven/actions/runs/34446694129)
on `b56d71827fa2f7fb471a37f2b106797ce603da34`: clean analysis, 801 Flutter
tests, both timezone suites, 16 Edge tests and native/JavaScript parity.
The actual UI harness built five floors, enrolled a pupil, played the real
20-second Rune Rush lesson, and verified one three-star attempt and the exact
XP reward. All preceding shop/Altar/dragon/Adventure/house/care probes also pass.
Migration 66 was rehearsed, applied on staging, and rechecked with both old
summer and new eight-hour Sunwake rollback contracts. The worker bundle is
1,057,115 bytes, ruleset `5998021ddc6ce477fc998af67720069c2cacbe06e6517a6a271a4c84def558c6`.
Both synthetic accounts and shadow commands were removed and the worker disabled
at 06:56:41 UTC; final staging schema 66, lint 0, Auth/settings/application 200
at 06:56:47 UTC on 10 September. Production remains schema 65 and unchanged.
This proves the Academy component; verified Trials, remaining care/social
settlement and migration/cutover are still open. The user explicitly requires
all economy work and quality-preserving APK reduction before the next release.


Trial verification foundation now has shared pure models for the three classic
games and four puzzle/rhythm events, plus shared Witchlight route geometry and
checkpointable Sunwake simulation. Existing art/controls are retained. Local
widget regressions, twelve input/model tests and native/JavaScript parity pass;
a one-hour Sunwake run restored every five seconds preserves every action and
uses bounded snapshots. No trial finish command is enabled by this foundation.
Remaining trial work: complete the shared score/session adapter, wire all eleven
screens to bounded input chunks, validate rewards/reservations on the server,
and prove actual staging replay/recovery before cutover. Existing Academy proof
above remains the deployed staging component. Production is still unchanged.

The trial-model foundation also passes the complete 813-test Flutter suite and
clean analysis. Native/JavaScript probe bundle: 1,082,642 bytes; all gameplay
outputs, RNG/checkpoint state and route coordinates match exactly.


## Verified Trial command and UI candidate (10 September 2026)

All eleven Trials now share the same input-driven simulation in the original
sprite screens and the command engine. Start reserves the offer and dragon and
issues a server seed. Bounded timestamp/control chunks update private checkpoints;
finish derives the score and grants the existing reward exactly once. The public
view contains no replay checkpoint or hidden dragon genetics. Abandoning consumes
the offer without a reward. Lost start/checkpoint/finish replies recover the
original journal entry; account changes fence the former game. Backgrounding or
failed persistence pauses play, including releasing a held dragon/path safely.
The seven-day constellation UI uses the existing authoritative claim command.

Sunwake retains faster acceleration, thumb capture and maximum steering speed,
with no gameplay time/score ceiling and three mistakes to finish. Its stored
personal high score now uses the protocol's exact-integer range instead of the
old one-billion cap. Seasonal selection shows all three expertises and groups
only dragons highlighted in all three; compact codex and expertise details use
the account-scoped public view. The original animations and artwork are retained.

Seventy focused regression/recovery tests and eight seasonal sprite/input screen
tests pass. All eleven complete command runs match exactly between the Flutter
VM and Deno, including every private checkpoint and final reward (probe bundle
1,123,143 bytes, Deno 872 ms). This caught and fixed JavaScript's 32-bit shift
behavior when creating the Witchlight seed. The eight loaded sprite screens were
reviewed in `release/economy-trial-visual/`. The complete 838-test Flutter suite, clean analysis and 17 Edge tests pass.
Real staging proof for this candidate is pending. The real staging harness now selects a dragon, plays
Ruin Breaker through its normal UI and checks the consumed offer and exact XP.

Remaining: trusted social settlement/rankings, remaining care/presentation actions,
legacy timestamp/import reconciliation, full client cutover/recovery and lossless
APK reduction. Production is unchanged, still schema 65 and legacy authority.
The user requires this entire trajectory before publishing version 0.05.30.

The expensive eleven-Trial command pilot is included explicitly in the VM/Deno
parity fixture; unrelated UI fixtures do not rerun it. This keeps parallel UI
checks from competing with a repeated simulation benchmark.


## Care, profile and milestone command candidate — 10 September 2026

Owned portrait/title/badge/frame selections, favorite-dragon room calls,
cosmetic room visits and milestone acknowledgments now use exact owner-bound
commands. Public profile/milestone views reject contradictory ownership and
malformed events. Room identity, damage and capacity are checked on the server;
the existing 5% cosmetic interaction and 12-hour cooldown are unchanged. A lost
receipt cannot reroll an interaction. No cosmetic command grants inventory or XP.
The existing hatch/evolution/achievement scenes consume public dragon appearance
facts, retain their sprites and audio, and acknowledge already-saved milestones.
The pending queue survives process death; owner changes clear the old reveal.
Trade presentation routing remains part of the pending social settlement work.

Five rule/recovery tests and four actual screen tests pass, including lost
receipts, ownership/capacity refusal, cooldown expiry, one acknowledgment,
account exit and the original hatch/evolution scenes. Four loaded 320dp Dutch
screens at 1.35 text scale were reviewed in `release/economy-milestone-visual/`;
evolution text now centers when it wraps. Full analysis and 18 Edge tests pass.
The native/JavaScript probe includes the new cosmetic commands and all eleven
Trials: exact parity, 1,133,288-byte probe bundle, about 855 ms in Deno.
The complete 847-test Flutter suite also passes, including the reference check.
Actual staging proof remains to be completed.

Trial staging run 34454679215 passed 838 tests, parity, schema 66/lint 0/health
and the preceding real server/UI paths, but its Trial command wait failed.
Run 34456071154 exposed a widget-clock regression in the attempted harness fix.
Both runs removed synthetic accounts/commands and disabled the worker. The
harness now restricts real-clock route construction to the Trial startup;
other scene transitions keep the widget clock. No production state was changed.
Do not count either failed workflow as complete Trial integration evidence.

Remaining release gates: finish real Trial/care proof, trusted social settlement
and rankings, trade presentation, import/calendar reconciliation, full gameplay
routing and migration/cutover recovery, then quality-preserving APK reduction.
Version remains 0.05.29 / 10079; production remains schema 65 and legacy-owned.
The user explicitly requested all of this before the next release.


## Social source claims candidate — 10 September 2026

Migration 67 and the shared command engine add group/partner/podium claims using
facts sealed from their normalized server sources. A client supplies only the
source ID. Commit rechecks the source under lock and stores canonical inventory
with the source acknowledgment in the same SQL transaction. Changed/claimed or
foreign sources and early claims fail without a grant. Replays recover the same
receipt. A known SQL rollback is durably refused; an ambiguous timeout retains
the original request. Shadow social actions default off. No production authority
is activated. Ready claim cards use explicitly projected identities, never raw
source rewards or private lease context, and clear on account change.

Five domain tests, two projection/widget tests, clean analysis and 20 Edge tests
pass. Six social claim/replay cases join the eleven-Trial/care parity probe:
VM/Deno outputs match exactly; probe bundle 1,145,723 bytes, Deno about 901 ms.
The full suite and migration-67 rollback/actual-server rehearsals are still pending.
The actual staging harness now checks all three claim cards and their exact XP,
chests/emote, then independently checks the source acknowledgment rows and the
unchanged partner claim. It retains cleanup of synthetic users and disables both
worker and shadow-social switches, including on failure.

Trial/care integration is still not signed off: run 34457265872 reached a verified
Trial result but its combined assertion failed. Run 34458729595 isolated this to
a renderer exception; reserved attempt, consumed offer, result dialog and exact XP
passed. Both runs cleaned all synthetic state and disabled the worker. The latest
harness classifies renderer errors without logging SDK/session data. Run 34459977706
was cancelled during setup before server work; replacement 34460031303 is pending.

Still open: complete real Trial/care/social evidence, canonical group/partner
lifecycle and reservations, trades and reveal, Beacon/rankings, normalized mirrors,
legacy timestamp/import reconciliation, complete gameplay routing and safe live
cutover/rollback. Lossless APK reduction follows those gates. App version remains
0.05.29 / 10079; production remains schema 65, staging currently schema 66.


## Clock bridge and Trial build regression — 10 September 2026

The ordinary app now writes known timer instants as explicit UTC when uploading
a legacy cloud save. Conversion runs on the device using each timestamp's
historical local rules, preserves its epoch (including microseconds), and leaves
calendar labels, inventory and unknown metadata intact. Canonical preparation
refuses unresolved local timestamps instead of interpreting them in the server's
timezone. Explicit offsets are normalized before preparation; adventure deadline
fingerprints compare instants rather than ISO spelling. Egg/dragon received dates
and journal date/time labels continue to display in the device's local timezone;
journal day labels use DST-safe calendar arithmetic.

Four bridge tests and the import/Trial regression set pass (17 total). Tests cover
all stored timer locations, immutable input, unchanged assets/day credits, unknown
metadata, offset/microsecond preservation, invalid dates and rejection before
migration. Linux staging runs both calendar and bridge tests under Amsterdam and
New York timezone rules. Local analysis is clean. VM/Deno parity passes including
explicit-offset conversion and all social/care/Trial paths (probe 1,149,553 bytes,
Deno about 923 ms). Full-suite and actual staging evidence are pending for this
candidate; users still require the new app's UTC upload before canonical capture.

Run 34460031303 classified the Trial renderer exception as a session notification
during ancestor build; it cleaned staging and disabled the worker. A local test
with the actual account Consumer reproduced the same error. Reserving the Trial
now starts after the route's first frame, and that regression passes with the
existing result, artwork and exact reward. This corrects a real UI lifecycle bug;
no game score, reward or input timing rule is changed. Run 34460608919 exercises
the preceding social-source candidate (migration 67) and does not yet include
this fix. Production remains unchanged and no release/version increment is made.

The complete local run passed 857 of 858 tests. The sole failure was the shop
fixture's two-second filesystem wait under parallel sprite load, followed by a
locked temporary directory during early teardown. Its wait now matches the
transport's bounded ten-second deadline; all four focused shop tests pass.
The staging workflow reruns the entire suite sequentially before deployment.
