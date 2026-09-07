# DragonHaven server-authoritative economy contract

Last updated: **7 September 2026**
Released app: **v0.05.18 / 10068**; production **49**, staging **53**.
Migration **49** adds owner-scoped inventory pagination and passed its staging rehearsal and applied contracts in run `34127201082`. Production run `34129277707` then proved identical staging source, rollback rehearsal, exact migration 49, repeated snapshot contract, parity, zero lint errors and health 200. Mutations remain disabled and all accounts remain legacy.
Migrations **45-47** are deployed dormant: chest opening, server inventory guard and item shop.
Production run `34116589237` passed exact staging-source checks, rollback rehearsals, all three contracts, migration parity, zero-error lint and health. Before/after checks prove mutations remain disabled and all accounts remain in legacy compatibility.
Staging runs `34110497546`, `34110676557` and `34111166461` passed rollback contracts, parity, lint and health. No economy activation is included.

## Work in progress: durable client reconciliation (7 September 2026)

### Public display projection candidate

Migration 54 adds a service-only private read for the authenticated Edge worker.
It requires a prepared import and matching build/ruleset, but permits reads
while mutations are paused. The worker returns only the explicit Dart display
projection, owner, revision and `shadow` authority. No live client applies it yet.
The eight projection tests cover Lens versus Oracle, hidden alignment and Soul
Mirror personality, nest/hatch transitions, Special/Sinister appearance and
protection, trade animation payloads, future metadata, and preselected adventure
rewards. Twelve worker tests cover commands and authenticated reads. VM/Deno
parity now includes projections before and after hatching. Staging 54 deployment
and its real paused-read proof are pending; production remains schema 49.
Full client routing, durable application, verified trial transcripts, timezone
rules, normalized social/trade settlement and production cutover remain open.

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
