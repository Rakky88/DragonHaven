# Canonical gameplay integration

Updated: 9 September 2026, after release v0.05.29 / 10079. Production and
staging are on schema 65. The published app retains legacy economy ownership;
production game/economic mutations remain disabled and push enabled. Latest
release pre/postflight evidence: `RELEASE_V0.05.29_VERIFICATION.md`.
The component runs below are dated historical proofs on their stated schemas.

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

The staging lane is not the complete game. Seasonal/group Adventure and trial
screens, remaining care/school interactions and progression still need public
read models and authoritative action routing. Verified trial transcripts,
server calendar/day policy, social/trade settlement, full import reconciliation,
staged migration and recovery remain open. Billing stays explicitly deferred.
At the initial shop rehearsal production was schema 59, legacy authority, game/economic mutations off,
zero shadow copies and production FCM enabled. Last independent production
preflight: 8 September 21:52:19 UTC; see `RELEASE_V0.05.22_VERIFICATION.md`.
A read-only production health check after these staging extensions returned
Auth/settings/application HTTP 200 at 23:42:42 UTC. No production writes were made.

The next implementation boundaries are:

| Area | Remaining work before live ownership |
| --- | --- |
| Trials and school | Server-issued attempt, bounded input transcript, shared score evaluation, expiry/offer/dragon checks and one atomic reward. The existing seasonal score/count/duration checks are not a verified transcript; arbitrary scores remain absent from canonical commands. |
| House and care | Furniture editing, floor reordering and roaming are proven through the actual staging UI and server. Care and school interactions still need authoritative controls. |
| Calendar | Define the keeper's server day and preserve existing constellation/day keys through timezone and daylight-saving transitions; device-clock changes must not create another daily claim. |
| Social and events | Settle group/seasonal Adventures, trades, Beacon contributions and podium prizes against one canonical owner state and the normalized social records. Preserve source event/preview identity on an already-started run. |
| Activation | Finish import reconciliation, lossless representative migrations, recovery and old-client fences, then exercise cutover/rollback in staging. Current shadow copies cannot be promoted by the staging UI. |

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
Registered staging run [34286596835](https://github.com/Rakky88/DragonHaven/actions/runs/34286596835)
passed on source `29c2519`: clean analysis, all 663 tests, Dart/JavaScript parity,
the SQL contracts, and real Altar/egg/name/equipment UI actions. The network
probe verified both unchanged legacy source/wallet and authority, removed its
two synthetic accounts and shadow state, and disabled the game worker. Final
staging preflight at 8 September 22:41:02 UTC: schema 59, lint 0 and Auth,
settings and application health HTTP 200. No production migration or activation
was performed. Actual
staging hatching is not accelerated: the completed hatch cycle is a local
server-clock test, while the network UI probe checks incubation/early refusal.

## Ordinary Adventures extension — 9 September 2026

The staging lane now also exposes persisted Mini/Short/Long offers and active
runs, ordered by end time. Refresh, start, abort, claim, dismiss and Wayfinder
use the same account/revision-fenced durable session. Unknown offer IDs stay in
the snapshot but cannot start through this UI. Invalid run ownership, duplicate
dragon assignments, dates and prematurely disclosed rewards reject the read.
Legacy calendar markers are retained, never used as client deadlines.

The compact dragon picker uses public expertise scores with the same shared
duration formula as the existing game. Its information button shows all three
expertises and highlights without selecting a dragon. The existing Draconomicon
sprite opens the actual collection screen using explicit public collections;
it does not require or instantiate a legacy game provider. Returning preserves
selection. Wayfinder is reachable from both inventory and Adventures.

Four rule/session tests cover lost start/claim replies, early/double claims,
sorted runs, busy dragons, reward-free abort, Wayfinder replacement/capacity and
invalid public data. Two additional widget tests cover inspections, selection,
start/claim recovery, Wayfinder and Dutch 320dp/1.35 text. Local real-font
screenshots are inspected beside the lifecycle captures. The staging probe is
extended to wait for a real one-minute server deadline using a synthetic
trained dragon, refuse an early claim, recover a deliberately lost claim reply,
check one chest/XP/expertise grant, abort another run and use a Wayfinder.
Registered staging run [34289398487](https://github.com/Rakky88/DragonHaven/actions/runs/34289398487)
passed on source `33d4fc5`: clean analysis, all 669 tests, native/JavaScript
parity (970815-byte bundle), SQL contracts and the complete real-network probe.
It waited for the actual server deadline, refused an early claim and recovered
one lost claim receipt with exactly one chest/XP/expertise grant. Abort and
Wayfinder also passed. Both synthetic accounts and all probe shadow state were
removed, the worker disabled, and schema 59/lint 0/Auth/settings/app HTTP 200
confirmed at 23:19:28 UTC on 8 September (9 September local time). The earlier
run 34288453265 stopped at a widget-test scroll issue before any deployment;
scrolling the newly inserted lazy-list row fixed the probe without changing
the game rules or weakening assertions.

## House economy extension — 9 September 2026

The staging Haven screen now exposes room unlock/selection, floor purchases,
stored-factor repairs and ward upgrades. Public tower facts validate floor
indices, unique damage entries, repair-factor bounds and ward levels. Price
quotes use extracted existing pure functions; server commands still decide
eligibility and deduct coins. Confirmation callbacks retain the displayed
revision and login epoch. The existing Shop continues to place owned furniture;
free-form furniture editing, floor reordering and roaming UI are separate work.

Four rule/session tests cover lost unlock/build/repair/upgrade receipts,
insufficient funds, level gates, tower capacity, free reselection and stale or
malformed price data. Two screen tests cover Dutch 320dp/1.35 text, cancel and
confirm, exact debits and sign-out during a floor confirmation. The tower and
room picker were visually inspected with real fonts. Seven additional fixed
phrases are translated for all six extra languages. The staging probe now also
checks a real ward/repair/floor debit and free selection. Run
[34290527414](https://github.com/Rakky88/DragonHaven/actions/runs/34290527414)
passed on `a53fb50` with clean analysis, all 675 tests, native/JavaScript parity
(972155-byte bundle), contracts and the actual house UI proof. Both synthetic
accounts and shadow commands were removed and the worker disabled. Final
schema 59/lint 0/Auth/settings/app HTTP 200 at 23:33:58 UTC on 8 September.
No production activation or schema change is included.

## Dragon preference extension — 9 September 2026

The staging dragon detail screen now sends explicit desired highlight states
for Might/Arcana/Spirit and a favorite dragon ID. The evaluator accepts only
owned hatched dragons, keeps the existing one-favorite rule, and leaves an
already-selected favorite unchanged without incrementing its achievement count.
A repeated highlight intent cannot toggle the chosen state back. The existing
sprite glow and centered scores are reused, with an accessible 48dp tap target.
Adventure selection and its read-only expertise dialog show the saved highlight.

Three rule/session tests cover desired-state retries, lost replies/restart,
unchanged training/XP, one favorite/change counter, protected release and rejected
egg/released/unknown targets or malformed arguments. A real-widget test covers
multiple highlights, unhighlighting and the same glow in Adventure information;
the sprite glow was visually inspected. The Edge test accepts the two exact
command schemas using the authenticated owner and rejects added reward fields.
Run [34291657311](https://github.com/Rakky88/DragonHaven/actions/runs/34291657311)
passed on `32817ed`: clean analysis, all 679 Flutter tests, 15 Edge tests and
native/JavaScript parity (975446-byte probe bundle, including accepted preference
commands). The real UI probe proved highlight/unhighlight, unchanged training,
the glow in Adventure information, one favorite and one counter increment.
All preceding shop/lifecycle/Adventure/house proofs passed again. Both synthetic
accounts and their shadow commands were removed at 23:49:02 UTC; the worker was
disabled. Final staging preflight at 23:49:09 UTC on 8 September confirmed schema
59, lint 0 and Auth/settings/app HTTP 200. This changes no schema, gameplay odds
or production authority.

## Furniture, floor ordering and roaming — resumed after v0.05.29

The house editor reads validated public placements, shows the existing artwork,
and uses the durable command lane to place/move/store owned furniture. It
retains stock when storing an item and never charges a second purchase price.
Coordinates must be finite and bounded, placement targets must be unlocked and
items owned. Malformed public room/coordinate/scale/roaming facts reject the
read instead of being repaired into a plausible client value.

Floor arrows use the existing top-to-bottom permutation and carry residents,
damage and the original repair factors with their room. Room clearing and
explicit roaming on/off reuse existing ownership/capacity rules. A reopened
account cannot reuse an old editor or callback. The editor selection is local;
there is no local alternate balance, furniture ownership or placement save.

Five additional rule/session tests prove lost placement/move/remove/reorder/
clear replies, restart, preserved stock and prices, invalid coordinates,
unowned or locked targets, full-tower refusal and malformed public projections.
Three additional real-widget tests cover Dutch 320dp/large text, room editing,
lost-reply reconciliation, floor arrows, account reentry and roaming without
training changes. The dedicated native/JavaScript fixture and authenticated
Edge tests include these commands. The actual network UI probe now also checks
placement, storing without loss, floor ordering and roaming. Run
[34399422518](https://github.com/Rakky88/DragonHaven/actions/runs/34399422518)
passed on `2a81df7`: clean analysis, 754 Flutter tests, 16 Edge tests,
native/JavaScript parity and every SQL/network/UI contract. The real room
editor and roaming markers were required by the network harness. Both synthetic
accounts and shadow commands were removed, and the worker disabled. The final
preflight at 20:19:18 UTC on 9 September confirmed schema 65, lint 0 and
Auth/settings/application HTTP 200. Dutch 320dp/1.35-text room editing and
reordered tower screenshots were visually inspected under
`release/economy-house-edit-visual/`. No production migration, authority switch,
APK release or economy activation is part of this extension.

## Calendar hardening — after the house editing candidate

The database instant is normalized to UTC before shared rules run. Daily
long-adventure refills and returning-dragon rolls retain their greatest date,
including dismissals, so changing time backward cannot roll/refill again.
Streak credit, migration reconstruction and carry handling use calendar-date
arithmetic instead of elapsed local midnight hours. They preserve already
credited dates and ready rewards on backward clocks. Existing offline gameplay
continues using local date labels; server commands accept no client day/time.

Local tests cover spring/fall US and European transitions, repeated/backward
and new days, ready-streak single claims, no second daily random draw and
identical server results for local/UTC representations of one database instant.
The existing local-label-to-server-day import bridge remains separate: no
existing player has been switched or had day keys rewritten by this change.
Run [34401056711](https://github.com/Rakky88/DragonHaven/actions/runs/34401056711)
passed on `ca558f7` with clean analysis, 759 tests, native/JavaScript parity,
SQL contracts and every network/UI proof. Cleanup removed both synthetic
accounts and disabled the worker; final schema 65/lint 0/Auth/settings/app 200
at 20:35:46 UTC on 9 September. The next candidate also runs calendar tests
explicitly in Europe/Amsterdam and America/New_York and checks that the
process actually loaded different winter/summer UTC offsets.


## House import and care controls

The semantic before/after import guard now includes placements, selected room,
equipped furniture, favorite/roaming/location, active Adventure assignment and
care values. Invalid or forward-unknown placement data, duplicate furniture,
clamped coordinates/needs or changed residents require reconciliation. Reads
and commands cannot silently normalize these into a different saved game.
The source copy is left intact; diagnostics contain category names only.
Synthetic post-hatch and post-damage fixtures now carry their actual valid
favorite/roaming state explicitly instead of relying on read-time repairs.

The active dragon's detail view has the existing 3-gem Starlight Treat and
validated Joy/Energy/Comfort values. An account/revision-bound confirmation
precedes the debit. The existing 25 XP (50 with Twinstar) and +12 capped needs
are unchanged. The durable intent recovers a lost reply without another debit.
Non-active dragons, insufficient gems, malformed care facts and stale callbacks
are refused. Local tests exercise the import guard, lost-reply/restart, caps,
Twinstar, Dutch large text and cancel/confirm. The 16 lifecycle screen tests
pass with real fonts; the care confirmation/details were visually inspected
in `release/economy-care-visual/`. Narrow dragon facts now stack their label
and value to avoid breaking words in half. Actual staging care proof is
included in the network harness and pending the next candidate run.
This does not complete verified Trials/school, social settlement or live import.
