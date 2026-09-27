# DragonHaven audit

## v0.06.12 published and deployed - 27 September 2026

Published v0.06.12 / Android build 10105 from
`2decc3d0901dbefd4111791214644c2194c2aa08`. The signed `nl.dragonhaven.app`
APK is 583,584,893 bytes; SHA-256
`fea844b7580a588951b3acd81b1c8382c755c18c1d9a17360c8ee6f2e0343af1`.
GitHub's asset digest and size match; the permanent latest download returns 200.
Release: https://github.com/Rakky88/DragonHaven/releases/tag/v0.06.12 .

Validation: 1,329 Flutter tests passed with one intentional opt-in skip,
13 Android unit tests, 56 Edge tests, 28 rollout-helper tests, clean Flutter
analysis and shared VM/Deno ruleset parity. Migration 101 passed local SQL
contracts and rollback-only rehearsals before staging and production application.
All 101 migration versions match; database lint reports zero errors and Auth,
application and rewarded-ad health checks return 200. An initial CLI pooler
authentication timeout occurred during dry-run only; retry succeeded before
the migration was applied. No player data was rewritten by the migration.

The exact worker passed staging before production activation. The verified APK
was publicly downloadable before requiring build 10105. Production gameplay is
enabled with ruleset revision 6 and SHA-256
`7f3d64e90b65515cb1497219f6808ba791aee302ad5a98edad8a3b2d0b33d3fe`.
Authenticated initialization, idempotent replay and state reads pass. Build
10104 is rejected before reads or mutations (Edge 426; SQL upgrade-required),
without changing state or creating intents. Test accounts were removed and
no rollout-tagged accounts remain. Identical SSV source was redeployed with
the release commit provenance; SSV version 19 and bundle hash are verified.

Visual review exercised actual production widgets in an isolated emulator app:
21 scenarios, six visible ranking choices at 320px, 160% text/reduced motion,
Spirit containment and bonus time for all three shapes, 60 increasingly fast
Orbit matches, and altar/shop Quill ordering. Actual Android swipe/tap checks
also passed with no captured Flutter errors. Rewarded-ad handoff tests pass;
the reported physical handset compositor issue still needs a handset playback
check. No physical phone was connected for this release.

Evidence is retained under `.tools/release12/` and `.tools/release12-review/`.
The preparation sections below are historical evidence for this release.

## v0.06.12 release preparation - 27 September 2026

Candidate display/package version 0.06.12, Android build 10105. This release
combines the four prepared changes documented below: relic balance and Quills,
versioned Spirit/Orbit rules, the six-choice ranking layout and ad handoff.
Migration 101 passed a rollback-only rehearsal on staging and was then applied
there with exact migration-history and unchanged runtime/grant checks.

Deployment requires client floor 10105 because earlier apps cannot decode the
new relic and revealed-egg fields. Publish and verify the signed APK before
raising that floor. The worker rollout pauses mutations while switching code,
then changes the ruleset and client floor together. The rollout helper now
records the activation attempt before sending it: after a floor-raising
activation, any error pauses gameplay and retains the new worker/floor for
forward repair instead of restoring an incompatible old serializer. Failures
before activation retain safe rollback. All 28 rollout-helper tests pass,
including an activation reply lost after commit and concurrent runtime changes.

Publication and final production evidence are recorded separately after the
remaining release checks complete. The earlier unreleased sections describe
preparation evidence rather than current publication status.

## Rewarded-ad preparation handoff (unreleased)

Prepared on 27 September 2026; no release, deployment or version bump.
The shop previously retained its full-screen Preparing ads route until the
native ad was dismissed. Both currency shops now remove that exact route and
await its disposal and a Flutter frame before handing control to the SDK.
The hook runs after SSV setup. Foreground and account identity are checked
again afterwards, so backgrounding or signing out during removal cannot start
an ad against the wrong state. A five-second handoff deadline fails without
starting playback and disposes the creative; late completion cannot launch it. Existing
definitely-unshown claim cancellation releases that reservation, while earned
rewards still wait for dismissal and retain signed server verification.

Validation: **44 focused Flutter tests pass**, including both real shop routes
through the production SDK wrapper with a fake native ad. They verify that the
preparation overlay is disposed before native show, early close, deferred
handoffs, handoff failure/deadline, backgrounding, account changes, reward
previews and recovery. Full Flutter analysis is clean. No SDK, Android renderer,
server reward rules, migration or live account data was changed.

Only an emulator is connected. These tests verify the missing UI handoff;
they do not reproduce or prove resolution of the handset's native compositor
symptom (audio playing with stale app content until background/foreground).
Google documents rewarded ads as native overlays above Flutter content:
https://developers.google.com/admob/flutter/rewarded . Keep a physical-device
playback check in the next build's acceptance checks.

## Six visible Trial ranking choices (unreleased)

Prepared on 27 September 2026; no release, deployment or version bump.
The shared World/Friends/Conclave ranking selector now presents the six
standard Trials in two labelled rows: Basic and Ascended. Three equal-width
tiles per row keep the matching Spirit/Might/Arcana games aligned. Full names,
icons and a selected-state check replace the clipped horizontal carousel.
Seasonal rankings retain their separate event tile. Larger accessibility text
can increase tile height and use the existing vertical sheet scroll.
Ranking queries, caching, scores and server behaviour are unchanged.

Validation: 5 ranking widget tests and 98 related social, UI parity and
localization tests pass; Flutter analysis is clean. Real-font screenshots were
reviewed at 286 and 320 logical pixels, with enlarged-text coverage at 1.6x.
Tests verify all six standard choices are initially visible and tappable at
286/320/390 pixels with normal text, Conclave selection of each game, event
expiry and the absence of horizontal scrolling. Reference-document verification
and diff whitespace checks pass.

## Spirit containment and ongoing Orbit acceleration (unreleased)

Prepared on 27 September 2026; no release, production deployment or version bump.
Spirit Alignment v3 renders its player at 86% of the target's linear extent,
with the white highlight clipped inside the player. The gold border is drawn
outside the scoring area. Circle/square/triangle area intersections use that
same geometry; full containment, including off-centre fits, gives 100% and
the existing five-second bonus. Partial coverage is capped at 99% after rounding.
Rune Orbit v2 uses fractional-millisecond windows with speed multiplied by
1.045 per point; the former 260 ms minimum no longer caps new attempts.

Client intents, Edge validation, command handling and replay agree on explicit
Spirit v3 / Orbit v2 capabilities. Missing/older capabilities and restored
checkpoints retain original rules. Unsupported resumes are refused before an
existing attempt can be fenced or changed. This preserves ongoing games and
lost-reply recovery across a coordinated future rollout. No new SQL migration
is required by these two Trial changes. Rewards and expertise assists are not
rerolled.

Validation passed: **1,318 Flutter tests**, one intentional opt-in skip, clean
Flutter analysis, **33 Edge command tests**, shared Dart VM/Deno replay parity,
reference-document verification and diff checks. Boundary tests cover fully
contained/off-centre fits, partial overlap rounding, bonus time and legacy
checkpoints. Real painter raster tests plus visual review confirm that all
three filled shapes and their highlights remain inside the gold contour.
Orbit tests cover 100 consecutive hits, increasing speed through score 1000,
old checkpoints and precise animation timing. New start/resume/restart tests
exercise real canonical commands, including rejected old-client resumes.

## Relic balance and recovery - 27 September 2026 (unreleased)

Prepared changes only: no deployment, version bump, production flag change or
player-state rewrite. The published app remains v0.06.11 / build 10104.

- Altar Moral Echo and Order Sigil are replaced by Moral Prism and Order
  Compass. Legacy saved IDs and queued commands remain readable; counts combine
  old/new stock and consumption drains old stock first. Reads do not normalize
  saves, preventing a false strict-restoration mismatch. Soul Mirror is newly
  craftable at the Compass price (30 Fragments, 2 Essence, no Weaveheart).
- These three crafted, bound relics reveal fixed facts on eggs and owned
  hatched dragons. Soul Mirror personality discovery survives hatching, with
  no hidden-trait reroll. Unknown egg personality is omitted from public views.
- Normal relic gates are multiplied by five: Gold 5%, Dragon 10%, Mythical
  20%, Sinister capped at 100%, direct S+ Trial 5%. The existing weighted pool
  and unique-brooch exclusions remain intact.
- Quill has an independent chest roll: Wooden 1%, Silver 2%, Gold 4%, Dragon
  8%, Mythical 16%, excluded elsewhere. A chest can contain its normal relic
  and a tradeable Quill together; receipts and reveal bundles retain both.
  The bound 100-gem shop Quill is listed first. Renaming consumes crafted,
  then shop-bound, then unreserved tradeable stock, in that order.
- Recovery now recognizes authoritative rewarded_ad_claim_unavailable and
  rewarded_ad_state_changed terminal failures. A fresh confirmed snapshot is
  still required before retiring the durable pending command. Unrecognized,
  malformed or mismatched receipts remain blocked instead of risking a duplicate
  action. Tests cover restart after a lost rejection reply and subsequent play.
  This closes an additional hang; it does not promise immunity to outages or
  unknown outcomes. The earlier stale eggRarityRevealedIds cause was repaired
  in migration 099 and provider cleanup in v0.06.10.

Migration 101 is prepared and locally exercised, not applied: it updates the
dormant SQL chest catalogue/opening, the bound shop catalogue, and the active
canonical trade allowlist.
Production ordinary rewards still use the shared Dart command engine. A future
rollout must coordinate the migration, worker and new app. Old clients reject
the new revealed-egg personality field and do not understand Quill stock/rewards;
raise the minimum supported build to the new APK (or provide explicit old-client
projection support) before exposing these new values. Do not roll the worker
back to one that drops new state after these rewards have been granted.

Gameplay reference tables were reviewed, including conditional combined
Adventure/Trial probabilities; no redeem code or direct redeem reward changes.
Validation passed: **1,297 Flutter tests**, one intentional opt-in skip,
clean Flutter analysis, both chest/shop catalogue verifiers, local PostgreSQL
migration/trade/shop contracts, shared Dart VM/Deno parity, reference-document
verification and diff whitespace checks. Regression coverage includes legacy
stock, egg/dragon Soul Mirror reveals (including lazy personality rendering),
shop order/100-gem bound purchase, independent/double drops, Quill reservations
and consumption, and rejected-ad recovery after restart. No live deployment
or physical-device installation was performed for this prepared change.

## v0.06.11 published ? 27 September 2026

Published `v0.06.11`, Android build **10104**, from
`b2ab4e264f6061938ac3d1f24e9a22cd63aa63e6`. The permanent latest APK URL
returns HTTP 200 and GitHub's asset size and SHA-256 match the signed local
artifact. Package `nl.dragonhaven.app`, display/manifest version `0.06.11`,
all three Android ABIs, production rewarded-ad IDs and the existing release
certificate were verified. No player data or protected local staging files
were changed by the release process.

- Release: https://github.com/Rakky88/DragonHaven/releases/tag/v0.06.11
- Asset: `DragonHaven.apk`, **583,552,121 bytes**.
- SHA-256: `62499b4ce96a2aa3578a6c5c98a348eafdfe90693a784affc337991fe1534020`.
- Certificate SHA-256: `477c5a5d7453384ca756265e77af97d5a002a907177ccd2d9065a9bec3414942`.

Validation passed: **1,280 Flutter tests**, one intentional opt-in skip,
clean Flutter analysis, **56 Edge tests**, **13 Android unit tests**, **23
rollout-helper tests** and three MIDI tests with all 75 tracks verified.
Two existing asynchronous widget tests now await actual persistence receipts
instead of short polling windows. Living-reference verification and the public
release-note privacy scan passed. Thirteen screenshots of the actual Trial
widgets were reviewed on an isolated Android emulator: contact/shatter/miss,
Orbit success/miss, Spirit countdown/bonus/continued play/timeout/restart,
including 320-pixel layouts, enlarged German text and reduced motion. No Flutter
errors occurred. Live Google ad availability on the owner's physical phone was
not retested during this release.

Production schema remains at migration **100**. Its transaction-ID regex fix
was already active; staging was brought to the same schema before rehearsal.
The shared worker was promoted before APK publication using a clean, pushed
candidate, matching local tag/version, the previous public APK digest, an
unchanged minimum client build **10102**, and successful staging proof for the
exact source, schema, compiled ruleset and Edge parser. Authenticated synthetic
initialization, replay and server-authority checks passed with automatic
rollback protection; rollback was not needed. Synthetic users were removed.
Gameplay and migration remain enabled; shadow switches remain disabled.

- Shared ruleset: `f2c5ab4a6b69adb339d06821e5bfc62fe2335a7e204c87e1cfb5686e2554b7ab`.
- Game worker bundle: `403039f677813dbcb4d2cf565ce245e30704ef5b4436fdc73532e2d449232b11`.
- Worker metadata version **16**, runtime ruleset revision **5**.
- SSV metadata version **17**, source `b2ab4e264f6061938ac3d1f24e9a22cd63aa63e6`.

Only the SSV source-revision environment value was advanced after verifying
that all three callback source files and its bundle were byte-identical to the
previous deployment. Setup tokens, ad-unit secrets, reward amounts and issuance
settings were preserved. The project-secret refresh advanced the game worker's
metadata version without changing its code or runtime row. Final mandatory
SSV-aware production preflight at **10:43:37 UTC** passed: 100 matching
migrations, zero database lint errors, Auth/settings/app/SSV HTTP 200, zero
synthetic users and six existing canonical accounts. The initial supplementary
GitHub AAB workflow reached its provenance check before that refresh and was
rerun afterwards; the independently built and verified APK is published.

Local evidence: `.tools/release72/{staging-v0611-final-1,production-v0611-final-1,
ssv-provenance-v0611}`, `artifact-verification.json`, `published-verification.json`,
`build/release11-*` validation logs and `build/release11-review/` screenshots.
The following implementation notes were prepared before publication and are
retained as the change history for this release.

## Unreleased timed Spirit Alignment — 27 September 2026

New Spirit Alignment runs start at exactly 60 seconds, keep cycling through
circle/square/triangle regardless of mistakes, and add five seconds for each
individual displayed 100% placement. Score remains the sum of percentages;
movement no longer accelerates between sets. Spirit assistance still slows
movement without changing geometric overlap or initial time. The HUD shows a
countdown and total shape number, with +5s feedback on every perfect result.
Result-display time counts toward the clock; an input at expiry cannot revive
the run. Checkpoints retain the bonus count and time through pause/resume.

The nested alignment checkpoint has version 2. Version 1 remains supported
with its previous untimed rules. New alignment start/resume payloads explicitly
request `spiritAlignmentVersion: 2`; omission selects the legacy start rules.
The Edge parser, durable intent journal and shared engine validate this narrow
optional capability. The public attempt keeps its exact version-1 shape for
released clients. An old app cannot fence a timed attempt by attempting to
resume it; upgraded clients restore old saved games without converting their
rules. Lost legacy requests keep their original request ID and payload.

The database command lease already accepts and hashes the full bounded payload,
so no migration is needed. A future release must deploy the updated shared
worker and execute-game-command Edge parser before distributing the new APK.
No production deploy, app version change or release was performed here.

Coverage includes timeout boundaries, individual and repeated bonuses,
imperfect continuation, long-run checkpoint replay, restored legacy games,
capability validation, lost replies and compact-screen timer feedback. Trial
offer probabilities, ranking storage, score grades and reward pools are unchanged.

The shared domain probe compiles and produces identical full results in the
Flutter VM and Deno, including timed alignment checkpoints, resumption and
final rewards. All 33 execute-game-command Edge tests pass. The seven model
timer tests, seven version-compatibility tests and four timer widget tests
pass alongside the existing rotation, command-authority and resume suites.
Flutter analysis reports no issues; living references were reviewed and their
fingerprints synchronized. Only the shared-engine fingerprint changes in the
redeem-code reference; its content and rewards are unchanged.
The final default-font regressions also cover scrolling Trial instructions on
small screens. Rune Orbit's test harness now awaits actual checkpoint futures
in the real asynchronous zone, explicitly exercising background autosaving
without a timing-dependent polling loop.

## Unreleased Ruin Guard and Rune Orbit feedback — 27 September 2026

Ruin Guard uses a generated transparent boulder sprite. A dragon anticipates a
matching impact with a short lunge, then recoils as seven clipped pieces of that
same stone spread, rotate and fade with a golden shockwave. Misses retain the
intact falling stone. Reduced motion uses static separated pieces and a success
symbol. Asset provenance and the exact prompt are in
`assets/licenses/TRIAL_ART_SOURCES.md`.

Rune Orbit now rotates stable rune sprites continuously through a visible
golden gate. Misses produce a single fading red wash, border and explicit
lost-heart message; matches use green feedback, a checkmark and a +1 message.
Reduced motion keeps static outcome feedback. Compact score/status headers
remain within a 320-pixel layout with enlarged text.

Both renderers use a read-only, bounded presentation clock between canonical
simulation updates. Rune taps resolve the gate atomically after advancing the
input clock, avoiding the stale-rune race at a timing boundary. Scoring,
collision times, RNG, input encoding/replay, server verification and rewards
are unchanged. No database, deployment, version bump or release is part of
this presentation change.

Validation: 60 targeted Flutter tests pass, including eight dedicated canonical
widget checks covering impacts, misses, separate render frames, pause behavior,
reduced motion, compact layouts and gate-boundary input recording. Canonical
checkpoint submissions remain accepted; existing simulation/replay, trial
widgets, interrupted saves and resumed-session regressions pass. Full Flutter analysis reports no issues and the
reference-documentation guard is synchronized. Font-backed screenshots of
contact, shatter and both Orbit outcomes were reviewed.

## Unreleased rewarded-ad recovery and Adventure presentation - 27 September 2026

Rewarded ads now preload one creative per currency without reserving a daily
claim. A tap opens a full-screen loading surface while the bounded claim request
finishes; the SDK ad is shown only when the app is resumed and the original
account is still active. Timed-out loads dispose late creatives. An earned SDK
callback displays +15 Gems or +150 Coins immediately on dismissal, without
blocking play on SSV polling. The account-scoped display journal survives an
app restart; it cannot authorize spending or modify the confirmed wallet.
Signed SSV remains mandatory for the canonical exactly-once reward. Expired or
cancelled claims roll back the display with an explicit message. A committed
wallet replaces the preview atomically, and settlement after terminal status
requires a newly applied background wallet read rather than an older in-flight
read. Claim recovery commands can coexist with queued ordinary gameplay.

Read-only production incident review found two expired issued claims (Coins
and Gems) and no Google SSV callbacks during their observation window. The user
confirmed that one or both AdMob units lack the saved callback URL. Exact setup
instructions were provided. The bare URL returning `invalid callback` in a
browser is expected. The user subsequently saved both settings; two signed
setup probes returned HTTP 200. A subsequent genuine Coins/150 callback reached
the function but returned HTTP 503: PostgreSQL rejected the `{1,256}` regex
bound with SQLSTATE 2201B. Migration 100 preserves the 1..256 limit with an
explicit length check plus the existing allowed alphabet in the verification
RPC and canonical intent context CHECK. A rolled-back staging rehearsal proved
256-character verification, idempotent replay, context acceptance, 257-character
rejection and preserved grants; its before/after schema hashes match.

Only migration 100 was applied to production. The post-change preflight reports
100 matching migrations, zero lint errors and HTTP 200 for Auth, settings,
application and SSV health. The original signed Coins callback was redelivered
unchanged and returned HTTP 200 `ok`; its claim is now verified for 150 Coins,
awaiting collection by the app. No wallet credit was fabricated or manually
written. The earlier attempts without a Google callback remain unconfirmed.
The worker, SSV function bundle, runtime flags, app version and public release
are unchanged. See REWARDED_ADS_RECOVERY_VERIFICATION.md for evidence.

The Android event-icon guard now tracks every started/starting Activity,
including Google's AdActivity, and defers launcher-alias changes until actual
backgrounding. A configuration-change guard and short Activity handoff grace
prevent a pending icon change from interrupting a full-screen overlay. This
repairs a concrete lifecycle race; the user's exact handset failure still
requires on-device verification.

Trial ranking selectors now use readable horizontally scrolling cards with
full names, larger icons and a clear selected state. One event progress bar is
kept above all four Adventure tabs; standalone Trials retains its event bar.
Event schedules, reward amounts, odds and visibility windows are unchanged.
RELICS_GUIDE_NL.md documents every obtainable relic, effect, recipe and exact
conditional drop chance. Historical Golden Wings direct rewards are explicitly
separated from current obtainable routes. Two stale weighted-pool descriptions
in RANDOM_REWARDS_AND_ODDS.md were corrected to the existing 11-relic pool.

Validation: Flutter analysis reports no issues; the full 1,253-test Flutter
run passes with one expected skip, followed by all eight migration contract
tests including the new regex regression. The reference-documentation guard
is synchronized. Five focused native lifecycle/startup tests pass.
The narrow-screen rankings integration test now scrolls the intended card into
view before selecting it; it no longer taps an offscreen control. The physical
phone is not connected; end-to-end display verification on that handset and
confirmation of the app's final collection remain outstanding.

## Published release v0.06.10 / 10103 - 27 September 2026

This release restores the detailed v0.05.40-era tower rooms and movement while
retaining server-owned gameplay, room-type changes and current account work. It
also repairs canonical command recovery: abandoned requests can be taken over
after the worker response budget, late workers are fenced by a rotated lease
token, the app makes one bounded identical-request retry and confirmed state
stays usable through short connectivity or lifecycle changes.

Final evolution now grants Expertise above the normal earned cap: +10 to the
chosen Ascended specialization, or +5 to all three Expertises for Mastery. The
three new specialist Trials join the normal rotation. Focus is selected first
(equal Arcana/Spirit/Might odds, or equal quarters including the event focus
during an active event); players who generally own the matching Ascended form
or a Mastery dragon then receive an equal classic/specialist variant draw. Busy
owned dragons unlock the draw, released dragons do not. Classic Trials still
accept every eligible non-egg dragon. Specialist Trials accept only the
matching Ascended form or Mastery and carry a visible `ASCENDED TRIAL` badge.
The empty Trial state matches the restored presentation, dismissals are
optimistic with rollback, and a silent durable refresh occurs at each overdue
15-minute boundary without interrupting an active Trial or School session.

Rewarded ads are live through server-side verification for the approved AdMob
app and distinct Gems/Coins units: three completed rewards per currency per UTC
day, granting 15 Gems or 150 Coins. The SSV handler verifies signed callbacks,
deduplicates rewards and uses a 15-minute claim lifetime. Its final production
source is the release tag; runtime activation retained zero historical claims.

The signed APK is public at v0.06.10. Analysis is clean; 1,233 Flutter tests
pass with one expected skip, Android app unit tests pass, all 35 command-worker
tests pass, all 20 rewarded-SSV tests pass and all 14 rollout-helper tests pass.
Staging and production both report 99 migrations, zero database-lint errors,
healthy Auth/application endpoints and passing authenticated authority/replay
smoke tests. Production deliberately retains minimum compatible build 10102 so
v0.06.09 remains usable. Exact hashes, rollout evidence and permanent download
links are recorded in `RELEASE_V0.06.10_VERIFICATION.md`.

## v0.05.40 ? 20 September 2026

- All eleven trial assists now use actual expertise points and the requested
  formulas (`TRIAL_EXPERTISE.md`); no 300/400-point assist clamp remains.
- All seasonal gameplay score/action ceilings removed. Birthday has no timer,
  ends at one miss, and persists bounded eight-layer checkpoints. Timed games
  retain their timers; Valentine/Pride add Spirit time as well as total time.
- Short Halloween previews begin after feedback, without a fade consuming
  their visible duration. Client and deterministic replay use the same rules.
- Account incident repaired after encrypted device/cloud backups: an acknowledged
  egg exchange missing from a restored local save was reapplied from its exact
  server receipt. This resolved `egg_not_owned` and the dependent pending tag
  blocking incubation. No net eggs or unrelated progress changed. The owner?s
  two supplied dragon highscores were restored, preserving other/highest scores.
  Tag/untag was checked on the physical device and repaired progress backed up.
- General canonical startup/cutover remains separate unfinished work. This
  narrow repair does not claim a general reconciliation of historical saves.
- Production schema 87 is verified; authority remains dormant. 985 tests pass
  after the two documented fixes, plus native/JavaScript parity and device review.
  Verification and rollout evidence: `RELEASE_V0.05.40_VERIFICATION.md`.


## Published release v0.05.39 / 10089

Built from public v0.05.38 with the shared-expertise feature backported. The
unfinished account startup/cutover remains on its separate working branch.
All otherwise eligible dragons can take retraining adventures; losses stop at
zero and precede gains. New Year now continues without time/score/action caps,
keeps accelerating, ends after three errors and grants S+ from 20,000.
Its finite checkpoint survives long runs without storing the whole input log.
New Year lanes, Birthday taps and Valentine swipes extend across the screen.
Migration 84 preserves partner authority boundaries, 85 supports expertise and
the rare reveal relic, and 86 extends only New Year validation/lease renewal.
All account authority flags remain off. Migrations 84-86 are now applied in
production: all 86 migrations match, database lint has zero errors, and Auth,
Auth settings and application health return HTTP 200. The staged and production
SQL contracts passed with all synthetic changes rolled back and authority
flags unchanged. Flutter analysis, gameplay/reward tests, VM/JavaScript parity,
worker type checking and documentation guards pass. The signed APK is version
0.05.39 / 10089. See `RELEASE_V0.05.39_VERIFICATION.md` for exact checks and
publication evidence. Release tag `v0.05.39` points to
`d71cc8e1f2b09d61684a54d87824be6c8ea631d9`. GitHub's APK size and SHA-256 match
the local artifact, latest resolves to this release and the stable APK URL
returns HTTP 200. Production public health was rechecked after the rollout:
all three endpoints still return HTTP 200.

## Earlier shared expertise candidate - 20 September 2026 (superseded)

This section records the earlier branch verification. Release 0.05.39 above
supersedes its affordability rule and pending-deployment status: retraining
now accepts dragons with insufficient source points, floors losses at zero,
and awards the planned positive gain within the shared budget.

Implemented shared budgets (950 ordinary / 1100 Sinister, +50 Mastery), private
stable Dragon Spark 0-50, full-dragon MAX, rare consumable Spark Astrolabe and
half-catalog Mini/Short/Long retraining. Costs are checked before starting and
paid before gains; legacy runs keep original rewards and existing over-budget
points are preserved. App and trusted evaluator share the same rules. Public DTOs
hide the Spark until revealed and retain larger specialized scores. Migration
85 widens social/group/partner transport and updates the versioned chest catalog.
The new artwork is reused in a glow/scale reveal; all eight app languages are
covered. Exact trial assistance is documented in TRIAL_EXPERTISE.md.

Verification is complete for this candidate: analysis is clean; the full suite
passed 1,032 tests with one opt-in skip and one stale migration-version assertion.
After updating that assertion from 84 to 85, all 11 load-profile tests pass,
covering the remaining failure (1,033 passing tests in total). VM/JavaScript
domain parity, worker compilation/type checking and reference guards pass.
Staging run [35479746214](https://github.com/Rakky88/DragonHaven/actions/runs/35479746214)
on commit `15a7fe4` passed the SQL contract, including 1,200-point concentrated
scores, negative/oversized refusal, partner transport, the 65-ticket relic pool,
hidden Spark fields and unchanged RPC fences. All synthetic changes and schema
changes were rolled back. See `EXPERTISE_BUDGET_VERIFICATION.md`.

This candidate is not published or applied to production. The public release
remains v0.05.38; migration 85 and the existing server-economy startup/cutover
work remain pending deployment.


## Published release v0.05.35 / 10085 - lossless APK reduction

The owner scoped this release to APK reduction and its related audit items.
845 runtime images now use smaller encodings with identical dimensions, source
RGBA pixels, ICC profiles and Flutter-decoded premultiplied RGBA output. Only
four PNGs change extension; catalog IDs, progression, rewards and animation
timing remain intact. Twelve superseded dragon sprites and three source prompt
documents are excluded from the bundle. Original bytes remain archived locally
and reproducible from the v0.05.34 source commit recorded in the manifest.

All **946 Flutter tests pass**. The opt-in image review is skipped in the normal
suite but was run separately against all 845 applied files, with zero differing
pixels. The two new inventory checks verify runtime hashes, dynamic catalog
paths and the actual Flutter asset manifest. Analysis is clean, and the living
reference guard is synchronized. The Altar test now decodes both runtime formats
while retaining the existing dimensions and transparency assertions.

The initial concurrent build/test run exposed the existing Trial test's short
startup wait and the old PNG-only Altar assertion. After the assertion update,
all 16 affected tests pass; the complete suite passes with two test workers and
no concurrent Gradle build. No canonical gameplay code was changed for that run.

Android artwork review confirms dragons, event backgrounds, closed/open chests,
Altar materials/relics and school sprites through their real runtime paths.
The signed production APK installs over the previous app, shows v0.05.35 in
About, and retains the saved English language, 25 coins, 3 gems and tower floor.
Production preflight has 83 matching migrations, zero database lint errors and
HTTP 200 for Auth health, Auth settings and app health. No server deployment,
database mutation or authority cutover is part of this release.

See `APP_SIZE_AUDIT.md`, `tool/asset_manifests/lossless_v35.json` and the final
`RELEASE_V0.05.35_VERIFICATION.md` for the signed artifact and publication evidence.

Publication is verified: the signed universal APK is 572826231 bytes, down
55433883 bytes (8.8234%). GitHub latest is v0.05.35, the permanent download returns
HTTP 200, and remote size/SHA-256 match the local artifact. All 145 audio resources
are byte-identical to v0.05.34 and the three ABI libraries are retained.

## Previous published release v0.05.34 / 10084

The Valentine invite control now follows the active occurrence, including when
old Valentine progress synchronizes behind another event. Background cloud
conflicts no longer publish unrelated Conclave/Friends errors; explicit partner
actions open the existing guarded resolution dialog. Divergent progress still
requires a player's choice and is never silently replaced.

Trial ranking selection contains three standard Trials plus one themed event
card. Natural expiry has an exact three-day grace period; replacement and
explicit ending retire old choices across save reload. Earned points and chest
claims remain intact. An open sheet expires its selection and cached rows, and
its controls scroll on short displays with enlarged text.

Validation: all 944 Flutter tests pass; Flutter analysis and the reference
documentation guard are clean. Widget renders were reviewed at 390x844 and
320x568 with 1.6x text, including scrolling to results. The cloud test verifies
that event synchronization still rejects a divergent revision while leaving
the global error/support banner empty. Point/reward schedules and odds are
unchanged; the odds reference fingerprint changed only because its shared
provider source includes the new presentation-retirement code.

The version increased once from v0.05.33 / 10083. All 73 version, updater,
language-order, screen and reference checks pass after the bump. Android emulator
review confirms the Halloween/Valentine ranking cards and invite visibility at
normal width and 320dp with large text and reduced motion. Production preflight
passes with 83 matching migrations, zero lint errors and all three public health
checks returning HTTP 200. No server deployment or database mutation is needed.

See [v0.05.34 verification](RELEASE_V0.05.34_VERIFICATION.md) for artifact and
publication checks.

Publication verified on 13 September 2026: latest resolves to v0.05.34,
the permanent APK URL returns HTTP 200, and remote size/SHA-256 match the
signed local APK. The existing signing certificate is retained.

## Previous release - v0.05.33 / 10083

All 939 Flutter tests pass and analysis is clean. Trial returns animate only
credited event points, including legacy and canonical paths. Meter end icons
no longer hide the liquid: the chest appears after the filling animation ends.
Compact friend rows reserve identical portrait space with and without frames.

Invitation preparation waits for ongoing social/cloud operations; revision
conflicts remain protected and are explained explicitly. Real staging Auth/RPC
tests confirm invitations work without the recipient having an active event
save or open client, and independent preview keys still share correct points.
All temporary probe accounts were removed. Production preflight is healthy
with 83 matching migrations and zero lint errors. The generated worker is
unchanged; no server deployment or authority changes are needed.

See [v0.05.33 verification](RELEASE_V0.05.33_VERIFICATION.md).

## Previous release audit - v0.05.32 / 10082

The event header now contains only the current event's 58dp themed glass meter.
Expiry, server end-event synchronization and switching/restarting previews remove
retired meters. Historical points and earned rewards remain stored, with late
claim eligibility still determined by the adventure completion time. Calendar
dismissals now persist and notify listeners immediately after synchronization.

Flutter analysis is clean. The final full suite passes all 933 tests at
concurrency two. Two school timing failures in an earlier heavily loaded run
also passed on independent rerun, without unrelated gameplay changes.
Event lifecycle, reduced motion and presentation checks pass.
Android emulator review covered Halloween, Valentine, existing-friend selection
and a 320dp viewport with 1.6 text scaling and reduced motion.

Production preflight: 83 matching migrations, zero database lint errors, and
Auth/settings/application health HTTP 200. The generated worker is byte-identical
to v0.05.31; no server deployment, schema or authority-switch change is needed.
See [v0.05.32 verification](RELEASE_V0.05.32_VERIFICATION.md).

## Previous release audit - v0.05.31 / 10081

Verified 12 September 2026: 932 Flutter tests, clean analysis and 27 Edge tests.
Staging and production are schema 83, each with 19 passing rollback-only server
contracts. Production preflight reports matching migrations, zero lint errors
and HTTP 200 for Auth health/settings and application health. Game and economy
authority switches remain disabled; no player was promoted.

Adventure event points arrive only on claim, including late claims for journeys
completed during an event. Legacy ready saves retain their existing credit.
Compact event bars use themed sprites, flying claim particles and reduced-motion
support. Valentine invitations select existing friends; independent preview
keys share progress correctly. All previous event dates and reward odds remain.

See [v0.05.31 verification](RELEASE_V0.05.31_VERIFICATION.md).

## Previous release audit - v0.05.30 / 10080


Verified 12 September 2026: 928 Flutter tests, clean analysis, 27 Edge tests,
MIDI checks and Android native tests pass. Staging and production are schema 82;
19 rollback-only server contracts pass in each environment. The production
preflight confirms matching migrations, zero lint errors and HTTP 200 for Auth
health/settings and application health. Economy/game/migration switches remain
disabled and no player account is promoted. The signed APK updates the existing
emulator installation while retaining Quietstar, one floor, 25 coins, 3 gems
and English. About shows v0.05.30.

Events use points from ordinary Adventures and Trials, not new seasonal
Adventures. Christmas is December 20?26 (7,000 points); Valentine is February
12?16 (10,000 points), both annually in Europe/Amsterdam. Server calendar
queries confirm the upcoming dates. Historical notes below describe earlier
states; the current release evidence takes precedence.

See [v0.05.30 verification](RELEASE_V0.05.30_VERIFICATION.md).

## Historical v0.00.09 — final specification audit

Audited against
`DragonHaven_Codex_Spec_With_Achievements_Rooms_Personalities_DayNight_Audio_Two_Sliders.md`
on 22 August 2026.

## Completed local scope

- fixed Common Starter Egg, independent 5% Spectral roll, immutable identity,
  exact 24-hour gate, live countdown and tap-for-hint interaction;
- Egg → Hatchling → Wyrmling → Ascended progression with three trained paths;
- 42-family 20/10/6/3/2/1 rarity distribution, 216 logical artworks, unseen
  silhouettes, separate Spectral collection and secret Sinister artwork;
- 24 hidden personality traits with incompatibilities and stable persistence;
- 800 Adventure definitions with duration/reward constraints and Sunday 12:00
  Europe/Amsterdam Group-instance timing;
- six chest tiers, stash, rewards, 27 returning-dragon tables, visits, damage,
  repairs, Dragon Wards and 48-hour Special/Sinister sources;
- 20 humorous bilingual achievements with unique badges and Common-family
  counters that exclude rarer families;
- Rooftop Nest, 20 buildable floors, eight distinct rooms, 200 purchasable
  sprites, data-driven movement/preferences/interactions and seven time phases;
- cinematic hatch/evolution/chest presentations, a persisted priority queue,
  oldest-first evolution reveals, spinning achievement reveals and Android
  music/SFX with two independent persistent switches;
- English default and complete authored text for all nine requested languages,
  including generated content, notifications and 300 dragon sayings;
- About/redeem/Ko-fi, permanent share/update link, white launcher/splash,
  improved topbar branding and robust scrolling/dismissal behaviour.
- a centered animated egg countdown, one uncategorized achievement list with
  persistent list/compact modes, 20 unique color badges with black locked
  silhouettes, and background-only achievement/evolution notifications.

## Intentionally requires external infrastructure

- authenticated friends, friend achievements, Tower visits, trades and account
  synchronization;
- real shared multiplayer Group Adventure participation;
- real-money Google Play gem packs and receipt validation.

Those operations are visibly unavailable instead of inventing fake users,
payments or cloud state. Their screens/data boundaries remain ready for a later
backend phase.

## Release gates

- no chore/task/leaderboard/battle save data or screens remain;
- automated bounds checks cover every dragon, furniture and chest sprite;
- compact 360×640 and 135% text-scale scroll/overflow regression is green;
- About pinned-handle scrolling and pull-to-dismiss regression is green;
- the Language sheet uses the same pinned-handle/pull-to-dismiss behavior and
  presents all visible language names alphabetically;
- release uses the permanent `nl.dragonhaven.app` ID and signing key.

## Event points verification

Test exact point tables, Amsterdam boundaries and recurrence, full day-one completion, late claims and duplicate prevention, independent partner claims, legacy-save compatibility, compact/tall UI, text scaling and reduced motion. Rehearse the new invitation migration in isolated staging before deployment.


Event/social polish (source only): migration 81 adds original-deadline invitation
expiry, creator cancellation of legacy Valentine test invites, raw score event
rankings with regular Trial scopes and a three-day results window, and Conclave
message receipts. Chat refresh/send lanes are independent, reconnect on resume,
preserve messages on read failure and discard stale responses. Existing Tower
floors can change room type for free, including all 20 floors; residents, damage
and saved furniture layouts are preserved. Title Chests cost 500 coins; Inventory
starts with Chests followed by Eggs. Isolated PostgreSQL and client regression
checks cover the changed behavior. Production deployment completed on 12 September 2026 as part of schema 82.

## Release v0.05.30 preparation ? 12 September 2026

After a 30-minute unchanged code/database observation, the annual point-event
calendar was extended: Christmas December 20?26 (7,000 points), Valentine
February 12?16 (10,000 points). Both close at Amsterdam midnight on the
following day. These are event progress bars, not new Special Adventures.
Migration 82 aligns the server calendar. First-year and recurring boundary,
point target, and claim-threshold regressions cover both events. Staging and production rollout, boundary tests and server preflight passed.
Publication verification is recorded in the release evidence.
