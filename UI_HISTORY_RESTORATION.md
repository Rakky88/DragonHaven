# Historical UI restoration after v0.06.00

## v0.06.02 UI parity and server verification - 20 September 2026

Restored v0.05.41 interactions and presentation while retaining canonical
commands and public snapshots. See `UI_V00541_PARITY_REVIEW.md` for ten review
passes, affected routes, test coverage and explicit server-era differences.
Restored Trial rankings (including Conclave Keepers), smooth Adventure paging,
Group placement/counts, original Adventure details/direct dragon selection,
Tower room ordering, roof/nest countdown, egg details and owned filters, Altar
hold/modal animation, tutorial targets and menu achievement counts. Preserved
improved Account Info and aligned its language control.

Ordinary reconciliation is silent with confirmed content. Unconfirmed actions
remain fenced. Visible-only Group polling now avoids full inventory reads when
membership is unchanged. No production ruleset, migration, minimum build or
account data changes. Production preflight at 19:50 UTC: 93 matching migrations,
zero database lint errors; Auth health/settings and application health HTTP 200.
Release validation and signed artifact evidence are recorded after publication.


Baseline: published v0.05.39, commit
`d71cc8e1f2b09d61684a54d87824be6c8ea631d9`. Its Adventure, Tower,
Inventory, Academy and Altar screen sources are identical to the retained legacy
screens in this working tree (`git diff` is empty for those five files).
The v0.05.38 -> v0.05.39 changes are retained: shared expertise budgets,
Dragon Spark, retraining, Endless Chimes and navigation gestures. The server
cutover happened later; restoring the old mutable HouseholdProvider is not a
valid UI fix.

## Comparison and changes

| Area | Remaining difference in v0.06.00 | Restoration |
| --- | --- | --- |
| Tower | Fixed heading, academy link above roof, expanded room controls taking up floor space | Heading scrolls with tower; original academy artwork/locked state below floors; compact 92px floors with overlapping resident portraits and a management sheet |
| Room visit | Small alert containing a room preview | Full-screen room scene, furniture and residents, retaining one server interaction per visit and server-backed decoration/calling |
| My Dragons | Approximate cards, dropdown, missing filters and diploma markers | Original gallery/list card layouts, highlighted borders, favorite/relic/diploma markers; form/rarity/Spectral filters; bottom-sheet collection and details |
| Dragon details | Plain alert and short school status | 190px artwork, original school report with lesson indicators and public star/attempt counts, wide scrolling sheet |
| Adventures | Text-only active/completed summaries; no tab counts or swipe | Illustrated run summaries with server-clock progress and public reward facts; tab counts/swipe; large detail artwork and wide dragon picker |
| Trials | Plain numeric constellation | Original seven illustrated constellation nodes in purple/gold summary panel; original Trial cards with focus labels, subtitle, account record and play icon |
| Chests | Two-column large-card gallery and only Open 1 | Original full-width chest rows and Open 10, using the existing durable server batch command |
| Relics | Generic gallery; crafted Altar relics missing | Original descriptive rows and empty state; crafted relic stock restored; use routes stay canonical |
| Furniture | Generic tiles without collection controls | Original grid/list, sort chips, type/rarity/placed filters and empty state, reading server ownership/placement |
| Eggs | Very short tiles and alert details | Larger artwork, public incubation/hint, original two-column density at compact widths and wide detail sheets |
| Altar | Simplified crafting cards | Original illustrated recipe cards, material costs, owned counts and use links; existing protected-egg checks/animation retained |
| Academy | Generic lesson list | Original numbered colored lesson cards with focus/team labels and the actual server Keeper Best record |

## Deliberate differences retained

Server snapshots and CanonicalGameActions remain authoritative. Hidden egg DNA,
random seeds and unknown outcomes are never reconstructed to feed legacy widgets.
Account/epoch/revision fences, durable replay, reconnect UI, social reservations,
price confirmations, starter tapping, server notifications and the About logo
remain in place. Server-only recovery flows remain visible when necessary.

Presentation is adapted to public facts: the diploma shows confirmed stars and
attempts, not an invented score or mentor count. Group membership and social
rewards retain the current server routes. Current minigames/event art, reward
rules, dates, probabilities, privacy/account changes and seasonal updates are
preserved. Video chests remain disabled, as explicitly requested.

No backend code, migration, production switch or deployment is changed.
The published v0.06.00 asset is not overwritten.

## Verification

- Final complete Flutter suite: **1,051 passed, one existing optional skip**,
  `.tools/ui-history-final-tests.log` (two concurrent workers).
- Final Flutter analysis: **no issues**, `.tools/ui-history-final-analyze.log`.
- Reference guard update/verification and the reference-documentation test pass.
- Earlier high-concurrency run: 1,049 passed, one Academy visual test exceeded
  its 1.5-second reservation wait; all three Academy visual tests passed in
  isolation and the final complete suite passed without changes to that test.
- Added regressions cover Open 10 as one durable batch without local grants,
  crafted relic visibility, non-mutating filters, and report cards at 320 logical
  pixels / Dutch 1.35 text scale. Existing tests verify lost replies, exact prices,
  protected eggs, double crafting, account changes and hidden identities.
- Reviewed real Android screenshots of Tower, My Dragons, Adventure, Trials,
  chests, relics, furniture, Altar and Academy in an isolated synthetic app
  package (`nl.dragonhaven.app.server_review`). Images are stored locally as
  `.tools/history-device-*.png`; compact widget captures with real font rendering
  are in `.tools/history-ui-captures/`.
- The review APK uses synthetic state only. No actual account save is imported,
  cleared or overwritten. No production APK or GitHub release is replaced.
- Production migrations, authority switches, backend code, app version and
  signing configuration are unchanged. Release publishing was explicitly
  deferred by the owner; production release preflight is required when a future
  release is authorized, not claimed as performed for this candidate.

The new room-management sheet additionally captures the session epoch. A
regression reproduced controls returning after signing out and back into the
same account; the corrected sheet hides those controls, and all 21 lifecycle
and server-shell tests pass after that fix.

Final Android follow-up: the current candidate debug APK compiled successfully
(71.6 seconds). Tower, Adventure/Trials, Open 10, My Dragons and About were also
reviewed at 320 logical pixels, 1.3 text scale and reduced motion. The emulator's
size, density, font scale and motion settings were restored afterwards. The
review build's temporary application ID/manifest edits are restored and the
reference guard still verifies. No release build/upload was performed.


## Second comparison: v0.05.40

At the owner's request, checked published v0.05.40 commit
`104eaa025e52564fa838536952086464a48f2c95` separately. Its Adventure,
Tower, Inventory, Academy and Altar sources still match the retained legacy
screens exactly. Theme, dragon art and game icon sources also have no changes
against that release. The v0.05.39 -> v0.05.40 delta concerns minigame rules,
expertise and game presentation; those later changes have not been reverted.

This second pass found and restored further presentation details:

- Eggs: All / Tagged / Untagged chips, lavender collection counter, directly
  accessible Received / Hatch time sorting and list/gallery toggle; tagged
  markers overlay the artwork. Public trade reservations are visible on cards
  and rows, and list rows again show incubation time and received date.
- Empty egg collections show the original illustrated inventory icon; egg
  detail clues use the original padded lavender panel.
- Adventure sections use the original short names and small descriptive
  subtitles with the softer border. Special Adventure cards show their event
  Trial icon again, with the Sinister marker where applicable and the original
  nearly-white, flat card surface.
- Academy enrollment again shows the lesson's 58px artwork and title above
  the pupil selection, matching the historical header.

Server actions and public snapshots still supply all state. Sort/view changes
wait for confirmation; tag filtering does not mutate gameplay. Server-hidden
egg identities remain hidden. Legacy per-slot refresh countdowns are not
invented from client time when the public view does not expose their schedule.
No backend, version, signing or release changes were made.

Second-pass verification:

- Flutter analysis: no issues (`.tools/v0540-final-analyze.log`).
- Inventory/shop/lifecycle/reference checks: 32 passed, including a new
  320px Dutch 1.35-text test for tag filters, delayed server preference
  confirmation and an unchanged local save (`.tools/v0540-tests.log`).
- Adventure/Academy/Trial/lifecycle checks: passed. That run reported a stale
  reference fingerprint after the final section-heading edit; the content
  note was reviewed and updated, then the reference guard verified and all
  five reference tests passed (`.tools/v0540-reference-tests.log`).
- Reviewed the new egg gallery/list screenshots with real font rendering in
  `.tools/v0540-captures/`. They fit the compact large-text surface.
- The 1,051-test full-suite result above belongs to the preceding restoration
  commit; this smaller second pass uses targeted checks for its changed UI.

Publication remains deferred, as explicitly requested by the owner.

The second-pass Android debug preview compiled successfully (125.6 seconds).
Reviewed Adventure sections and egg gallery/list in the full app shell on the
Android emulator (`.tools/history-device-v0540-*.png`). The isolated synthetic
review package was reinstalled to make space; the actual game package and
account were untouched. Temporary build configuration edits were restored;
there is no Android configuration diff and the reference guard still passes.


## Three additional passes for v0.06.01

Requested v0.05.50 does not exist. GitHub's last v0.05 release is v0.05.42,
so the requested one-before-highest reference is v0.05.41
(`5a4a1ef9b9a0e269b89cbeeae2b4cee0d5d07067`). Compared its retained
Adventure/Tower/Inventory/Academy/Pet sources; these historical presentation
sources have no differences in the current tree. Its account/privacy changes
and later server migration remain intact.

1. Inventory and My Dragons: checked tab spacing, row/gallery controls,
   filters, details and empty collections. Restored the missing illustrated,
   lavender empty-collection panels for chests and dragons.
2. Tower and Academy: checked roof/floors/room scenes, entrance, lesson list,
   enrollment and dragon details. Restored the selected-pupil lavender card,
   bold display name and actual earned star icons. Replaced plain wellbeing
   percentages with the original colored icons and meters, allowing labels
   to wrap at large text sizes. Retained confirmed server commands.
3. Adventure and lifecycle: checked categories, offer cards, run/reward tabs,
   selection sheets, Trials and incubation/reveals. Restored the original
   illustrated Active/Completed empty-state messages. Added automatic hatch
   scheduling in the server shell, using the confirmed server deadline and
   existing durable command; the roof no longer requires pressing Hatch.
   Full-screen Trial/Academy attempts defer automatic hatching. The detail
   sheet retains the existing manual fallback.

The hatch incident was independent of the internet connection: the social
projection rejected an unnamed hatchling because player_dragons requires a
nonempty name. Migration 93 supplies only a temporary social display label;
canonical names, seeds, outcomes and free first naming remain unchanged.
The contract reproduces the old SQL failure, then verifies atomic hatch commit,
receipt replay, stable dragon identity, unchanged wallet and subsequent naming.
The production fix never rewrites an existing save or resets a pending command.

Validation for v0.06.01: the final complete Flutter suite passes **1,055 tests**
with one existing optional skip (`.tools/release61-final-tests.log`). Flutter
analysis is clean. The automatic hatch regressions cover one command/reveal,
lost reply and replay without duplicates, and no hatch before readiness or
after sign-out. The first complete run found a non-catalog wording and an old
migration expectation; both were corrected before the successful final suite.
The required production preflight confirms **93 matching migrations, zero
lint errors, healthy Auth endpoints and healthy app endpoint**. No server
runtime/ruleset or existing game state was changed by migration 93.

Android verification: reviewed the restored screens on an emulator, including
320dp width, 1.3 text scale and reduced animations. About displays v0.06.01.
The automatic hatch opens the original illustrated egg animation without a
Hatch-button tap using a synthetic server test session, then reaches the
original dragon reveal and Choose a name button. The first
extra probe used invalid hand-built fixture state; the corrected probe uses
the same valid provider export as the passing scheduler regression tests.

The signed universal release APK is package `nl.dragonhaven.app`, version
`0.06.01`, build `10094`, non-debuggable and uses the existing signing key.
Size: 578,080,707 bytes. SHA-256:
`95c05abaadb6620353e2e16866fe6688a0f7c919f4c744eacd38a3bcab2bc8d4`.

A later read-only production check confirms the original pending hatch is now
`succeeded` at revision 59, and subsequent naming and presentation completion
also succeeded. Recovery used the original pending command; no save rewrite,
manual reward grant or command reset was necessary.
