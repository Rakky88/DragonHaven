# Canonical gameplay integration

Updated: 9 September 2026. Shop integration shipped in v0.05.22 / 10072;
the lifecycle extension below is subsequent staging-only work, not a new release.

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

The staging lane is not the complete game. Adventure/house/trial screens still
need public read models and authoritative action routing, including Wayfinder.
Dragon preferences/highlights also need their command route. Verified trial transcripts,
server calendar/day policy, social/trade settlement, full import reconciliation,
staged migration and recovery remain open. Billing stays explicitly deferred.
Production is schema 59, legacy authority, game/economic mutations off,
zero shadow copies and production FCM enabled. Last independent production
preflight: 8 September 21:35:35 UTC; see `RELEASE_V0.05.22_VERIFICATION.md`.

## Egg, Altar and dragon lifecycle extension — 9 September 2026

Typed public dragons/inventory expose validated owned equipment, reservations,
fixed Chronoshard percentages, crafted stock and materials. They preserve
unknown egg identity and unrevealed dragon nature/personality. Contradictory
stock, equipment ownership and duplicate equipment slots fail reconciliation.
No private save is loaded to fill missing fields.

The staging inventory now offers Chests, Eggs, Relics and Altar. Egg filters and
details precede selection; tagging, nest placement, hatching and reveals use
the durable session. The hatch countdown anchors a monotonic clock to server
time; only the server decides whether hatching is due. Altar craft order,
protection, Sinister confirmation and existing rewards remain unchanged.
The existing scene runs after a confirmed return, with reduced-motion support.
Closing it cancels presentation without cancelling or repeating a committed action.

The dragon page shows Gender only in details, after Type and Maturity, and uses
the shared centered expertise badges. Name/Quill rename, evolution, equipment,
dragon reveal relics and release use server commands. The four brooches retain
their one-slot rule. Every callback captures owner, login epoch and displayed
revision before opening a dialog; an old confirmation cannot act even after
the same account logs in again. No automatic retry creates a new intent.

Local checks: four lifecycle rule/session tests cover malformed snapshots,
protected returns, lost reply/restart, duplicate crafting, discoveries, server
hatch timing, Chronoshards, names, equipment and release. Seven widget tests cover
the actual controls, double taps, lost return reconciliation, two Sinister
confirmations, account changes (including open filters), rename completion and
Dutch 320dp/1.35 text. All new fixed phrases have German, Spanish, French,
Italian, Portuguese and Japanese translations in addition to English/Dutch.
Roboto/icon screenshots are inspected under `release/economy-lifecycle-visual/`.
The real staging probe has been extended with Altar/egg/name/equipment UI actions;
its next run and final suite evidence are recorded after completion. Actual
staging hatching is not accelerated: the completed hatch cycle is a local
server-clock test, while the network UI probe checks incubation/early refusal.
