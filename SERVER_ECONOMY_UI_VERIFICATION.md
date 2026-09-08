# Canonical shop and inventory integration

Updated: 8 September 2026. Verified staging integration included in released v0.05.22 / 10072.

## Scope and boundaries

The ordinary `ShopHubScreen` and furniture, relic and vanity-chest cards now
read through `ShopEconomy`. A legacy game uses its existing provider. A
canonical session uses only its validated public snapshot and durable command
lane. No private save is returned to the app; unknown egg facts stay nullable.
Missing/offline server data never falls back to legacy coins or owned items.

`DRAGONHAVEN_CANONICAL_STAGING=true` starts an isolated app lane before any
legacy game storage is read. It requires `DRAGONHAVEN_ENVIRONMENT=staging`,
the registered staging URL and its public key. Production/arbitrary URLs are
rejected. The Auth key and on-device journals are separate. It offers the real
shop and server inventory with the existing chest reveal, for prepared test
accounts only. No production account is migrated or promoted by this code.

Commands capture the displayed account epoch and game/ruleset revision. Old
callbacks refuse to act after a different account, another purchase or ruleset
change. Two simultaneous matching taps share one persisted intent. Cached
viewing remains possible offline; foreground return needs a fresh read.
An in-flight command still persists while backgrounded, without enabling taps.

The chest reveal now catches opening failures and offers a return to inventory.
It never automatically retries an ambiguous opening or grants a second reward.
This failure handling also improves the existing legacy animation. Large-text
shop tabs scroll and the reconnect control keeps a 48dp icon target.

## Verification

- Seven new rule/transport tests: real catalog purchases and absolute balances,
  untradeable shop relics, duplicate taps, lost receipt and restart, old callbacks,
  account exit, background completion, real chest result decoding and malformed
  public stock. Existing snapshot/session tests also pass (31 tests together).
- Four new screen tests: actual shop purchase/reconnect without modifying the
  simultaneously provided legacy save, Dutch 320dp at 1.35 text scale, clearing
  inventory at sign-out, actual chest reveal and a closable failed opening.
- Local visual checks use Flutter's bundled Roboto/Material icons and real
  assets. Screenshots remain local under `release/economy-ui-visual/`.
- Analysis and the final 652-test CI suite passed. Registered staging workflow
  [34281388567](https://github.com/Rakky88/DragonHaven/actions/runs/34281388567)
  passed the real SDK/session/journal and actual shop/chest widget round trip.
  One title-chest purchase debits 100 coins once; opening consumes one chest
  and grants one title. It rechecked the unchanged legacy source save/wallet
  and authority, removed both synthetic accounts/copies and disabled the worker.
  Final staging preflight at 21:39:13 UTC: schema 59, lint 0, all health HTTP 200.
- Earlier attempts exposed fake/real clock mixing in the network widget probe.
  Auth creation, callbacks, animation delays and cleanup now use the real clock;
  only fixed diagnostic phases can leave the child process. No production
  credentials are passed into the Flutter test child.

## Remaining full-economy work

The staging lane is not the complete game. Other gameplay screens still need
public read models and authoritative action routing; eggs/relics here are
displayed without enabling legacy mutations. Verified trial transcripts,
server calendar/day policy, social/trade settlement, full import reconciliation,
staged migration and recovery remain open. Billing stays explicitly deferred.
Production is schema 59, legacy authority, game/economic mutations off,
zero shadow copies and production FCM enabled. Last independent production
preflight: 8 September 21:35:35 UTC; see `RELEASE_V0.05.22_VERIFICATION.md`.
