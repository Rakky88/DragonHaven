# Rewarded-ad recovery and UI verification — 27 September 2026

## Production incident and repair

The first watched-ad attempts had no Google SSV callback. After the owner saved
the callback URL on both AdMob rewarded units, two setup probes returned HTTP
200. A genuine Coins/150 callback subsequently failed with HTTP 503. Its token
hash matched the issued claim and the signed product fields were correct.
PostgREST reported SQLSTATE 2201B on the verification RPC.

PostgreSQL ARE repetition bounds stop at 255; the original `{1,256}` expression
was invalid, as documented in the [PostgreSQL pattern-matching reference](https://www.postgresql.org/docs/15/functions-matching.html).
The same expression occurred in the verification RPC and the
canonical intent's rewarded context CHECK. Migration
`202609270100_rewarded_ad_transaction_regex.sql` changes only those two checks
to an explicit length range of 1..256 plus the existing allowed alphabet. It
preserves service-only access, signature/claim enforcement, amounts, quotas,
deduplication, leases and the existing claim-table CHECK. Lock acquisition is
bounded to five seconds and statement execution to thirty seconds.

Reviewed migration SHA-256:
`ddef84f5a34da772c1e9d7d8c21f9051b9f7595bdd569b14b7f83137f1e395a9`.

The staging rehearsal applied this exact migration in a transaction, created a
synthetic issued claim, verified a 256-character transaction, repeated it and
received `replayed`, and asserted exactly one verified record. A temporary
probe used the actual repaired context CHECK: a valid, fingerprinted
256-character context passed and a recomputed 257-character context failed.
The transaction rolled back; schema hashes, grants and migration history
matched the starting state. All eight Flutter migration contract tests pass.

The production dry run contained only migration 100. After applying it, the
mandatory server preflight reported:

| Check | Result |
|---|---|
| Local/production migration history | 100, matching |
| Database lint errors | 0 |
| Auth health and settings | HTTP 200 |
| Application health | HTTP 200 |
| SSV health | HTTP 200 |
| SSV function | Version 15, unchanged |
| SSV source revision | `30cf76fcb24965af1e789650b16a77d626db020f` |

The original Google-signed Coins callback was redelivered with its raw query,
signature and encoding unchanged. The live verifier returned HTTP 200 `ok` at
09:43 UTC and the claim became `verified`, with 150 Coins awaiting collection
by the app. No unsigned callback, artificial reward or direct wallet edit was
used. Earlier attempts without signed evidence remain unconfirmed. Runtime
flags, worker/ruleset, minimum client build, SSV bundle and app release did not
change. Private incident evidence and operational logs remain in ignored
`.tools/` files, not in this document.

## Unreleased application changes

- Ads are preloaded separately from one-use server claims, with bounded load
  and foreground waits and disposal of late or unused creatives.
- The shop opens a full-screen preparation view on tap; account fencing also
  covers asynchronous SDK setup. It returns to gameplay on ad dismissal.
- An SDK-earned reward appears immediately in the displayed wallet. This is a
  provisional display, not spendable server currency. Signed SSV confirms the
  canonical wallet in the background; terminal failure removes the preview
  with a message. A small account-scoped claim journal supports restarts.
- New confirmed wallets replace previews without duplicate credit. Settlement
  after terminal status waits for a newly applied wallet read, never merely a
  previously running read or a skipped refresh.
- Android tracks all visible app Activities, including AdActivity, before
  changing event launcher icons. Configuration recreation and short handoffs
  cannot trigger a pending alias change over a visible ad.
- Trial rankings use readable horizontal selectors. Adventure has one shared
  event progress bar above its four tabs; standalone Trials keeps its bar.
- RELICS_GUIDE_NL.md contains every current relic, effect, recipe and exact
  conditional probability, with historical event rewards clearly distinguished.

The complete Flutter suite passed with 1,253 tests and one expected skip before
the additional migration regression; all eight migration contract tests then
passed. Flutter analysis is clean, the reference guard verifies, and five
native Activity/startup regression tests pass. Rankings were also inspected at
390px and at 320px with enlarged text.

No new APK has been published or installed. Only an emulator is connected.
The handset foreground symptom is not yet verified against this new app code,
and the app's final collection of the recovered Coins claim is not yet observed.
