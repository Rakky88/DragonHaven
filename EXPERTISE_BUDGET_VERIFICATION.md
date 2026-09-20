# Shared expertise budget verification

Verified on 20 September 2026 on `fix/server-economy-cutover`.
Implementation commit: `15a7fe413ab7305c2b7219ec70876e023bdda215`.
The only subsequent executable change is the test assertion for the latest
repository migration (84 to 85). No production deployment or release occurred.

## Covered behavior

- Shared 950/1100 capacity, +50 after Mastery and one stable hidden 0-50
  Dragon Spark; no independent expertise caps and no negative values.
- Existing legitimate over-budget totals are preserved. They cannot grow again
  until a transfer creates room. Existing Mastery remains after specialization.
- The Spark survives saves, imports and evolution; public dragon facts omit its
  value until the consumable Spark Astrolabe reveals it. Repeating the reveal
  does not consume another relic.
- Exactly half of Mini, Short and Long catalogs transfer expertise. Both other
  source expertises occur for every target expertise. Costs must be affordable
  when starting and are paid before gains. The ordinary net reward is unchanged;
  existing brooch bonuses still apply to positive rewards.
- Runs started before this change retain their original positive-only reward.
  Their missing `retraining` and Spark fields do not cause a false import loss.
- One MAX badge belongs to the whole dragon. Hidden capacity leaves no blank
  placeholder, progress meter or individual-stat MAX indicator.
- The Astrolabe has one ticket, like each rare brooch; ordinary relics have ten.
  It is consumable and repeatable, absent from shops/crafting, and only joins
  ordinary chest drops and S+ Trial relic drops. Event guaranteed pools are
  unchanged. Artwork, asset paths, all eight app languages and import catalog
  consistency are covered by regression checks.

## Local checks

| Check | Result |
|---|---|
| Dart analysis of lib/test/tool; final lib analysis | No issues |
| Complete Flutter suite, concurrency 2 | 1,032 pass, one opt-in skip; one old migration assertion failed |
| Entire load-profile file after updating that assertion | 11/11 pass; resolves the sole failure, for 1,033 passing tests overall |
| VM versus JavaScript shared-domain parity | Passed; 1,243,222-byte parity bundle |
| Production worker build | Protocol 2; 1,222,778-byte bundle |
| Deno check of execute-game-command | Exit 0 |
| Living reference guard and its five regression tests | Passed |

Worker ruleset SHA-256:
`fb568d9dc27313d786be8a03b50c6ab8900b08b0608944f7e35b78bd032ad087`.

Local logs are under `.tools/expertise-*` and are intentionally not committed.
The full suite includes the expertise, equipment, canonical DTO, legacy import,
asset safety, localization, adventure and widget regressions.

## Staging database contract

[Run 35479746214](https://github.com/Rakky88/DragonHaven/actions/runs/35479746214)
finished successfully on the implementation commit. The
`DragonHaven-staging-expertise-contract` artifact reports:

> PASS: concentrated dragon/showcase/partner scores, negative/oversized refusal,
> rare Astrolabe pool, hidden bonus and retained RPC fences;
> synthetic_changes_rolled_back=true

The drill tests pending migrations inside a single rolled-back transaction.
It accepts 1,200 Might where appropriate, rejects negative and 1,201-point
transport, verifies the chest catalog and keeps underlying partner RPCs private.
It does not activate accounts, deploy the worker, persist schema changes or
touch production players.

## Delivery boundary

Public latest was verified as v0.05.38. Migration 85 is a candidate following
the pending migration 84. Publishing requires the existing server-economy
cutover work and the repository's normal deployment/release checks. This
verification does not mark that wider rollout complete.

Trial assistance formulas and retained 300/400-point assistance caps are listed
in [TRIAL_EXPERTISE.md](TRIAL_EXPERTISE.md).
