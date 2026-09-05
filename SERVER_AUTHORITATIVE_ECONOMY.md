# DragonHaven server-authoritative economy contract

Last updated: **5 September 2026**
Candidate schema: **migrations 37–38 — dormant and verified on staging, not production**
Current public app: **v0.05.11**

## Purpose and current boundary

DragonHaven currently keeps most gameplay progression in the local/cloud save.
The online schema already mirrors wallets, dragons, eggs, chest stacks,
furniture and relics for import, social play and safe trades, but that mirror is
not yet allowed to become the source of truth for purchases or ordinary reward
claims.

Migration 37 builds the missing transaction boundary without switching it on.
It adds no paid product, changes no current balance and exposes no new mutating
RPC to the app. Every keeper remains in `legacy_client` mode and the global
`mutations_enabled` switch starts as `false`.

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
   staging. Run `33981322674` proved database lint, RLS/revokes, read-only
   contract, dormant defaults, rejected mutations and healthy public endpoints.
3. **Shadow implementation:** add one harmless economy path behind a disabled
   app feature flag; compare results without mutating player value.
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

- implement concrete wallet/shop/chest RPCs around this private foundation;
- move all randomness and collection-cap checks for those paths to PostgreSQL;
- filter server-owned fields out of save restore/import after cutover;
- add staging E2E for replays, conflicting payloads, rate limiting, rollback and
  old-client rejection;
- later extend the same pattern to eggs, dragons, progression and daily claims.

### Rick

- confirm which existing progress must never be reduced without human review;
- approve the migration window, player communication and rollback policy;
- choose compensation behavior for failures and whether earned and purchased
  gems need separate spend rules;
- decide which gameplay stays view-only or queueable during a server outage;
- approve every staging apply, production migration and eventual cutover
  separately.

Migrations 37–38 changed only the isolated staging schema; the global mutation
switch remains disabled and every keeper remains on `legacy_client`. Migration
38 is the applied forward-only timestamp correction after the first staging run
correctly exposed migration 37's ambiguous clock-variable lint finding. No
production project, public release, balance, inventory or other player value is
changed by this staging foundation work.
