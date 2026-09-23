# v0.06.03 UI and interaction review

## Six-agent follow-up against the same v0.05.41 reference

1. Adventures/Trials: original compact active/completed cards, gradients, ready
   reward rows, run detail sheets and draggable Trial picker with personal bests.
2. Tower/Dragons/Nest: original draggable collection toolbar, owned-only filters,
   roaming strip, detail art/fact/XP panels and Trial records; direct nest choice.
3. Inventory/Altar: original egg review and crafted-relic selection/reveal sheets,
   mode animation, Lens/Chronoshard/brooch selectors and dragon reveal animation.
4. Shell/social/Academy: original Academy hero, normalized standings, pupil and
   mentor selection, graduation confirmation; fixed My Dragons modal wrapper.
   Conclave rankings, account language and tutorial routes reviewed.
5. Groups/Shops: compact lobby/active cards and draggable participant details;
   Shop screens already match historical visuals apart from inactive ad chests.
6. Performance/navigation: account-scoped connection reuse, transient refresh
   hidden with existing content, and clocks anchored to confirmed state during
   optimistic display updates. Swipe and dismissal surfaces reviewed.

These are six separately scoped source comparisons, followed by integration
tests and device review, not six claims that every possible screen is identical.
Original UI adapts to large text when necessary. Remaining explicit differences:
egg Discard has no server command; inventory Wayfinder/Quill open their guarded
Adventure/Dragon use routes. Mentor lessons-taught text remains absent. Secret
egg traits/random rewards are never fabricated to fill historical widgets.
Validation and release evidence are recorded in RELEASE_V0.06.03_VERIFICATION.md.

Reference: GitHub tag v0.05.41, commit
`5a4a1ef9b9a0e269b89cbeeae2b4cee0d5d07067` (tag verified against origin).
The comparison uses the historical Flutter source, retained original widgets,
and Android emulator captures. It is not a claim of a pixel-by-pixel comparison
of every possible account, event or animation state.

## Ten review passes

Every pass checks the main route map (Friends/Conclave, Adventures/Trials,
Tower/Nest/Dragons/Academy, Inventory/Altar, Shop and menu). Detailed findings:

1. **Navigation and gestures:** replaced velocity-only Adventure pane switching
   with TabController/TabBarView. Inventory retains its original TabBarView.
   Groups belong in Available, Active and Completed, with joined-group counts.
2. **Layouts and artwork:** compared headers, roof, collection rows, Trial cards,
   Shop and social screens. Restored the compact roof clock and room-order
   control in the original clock/floor-count row. Social and Shop visual changes
   from the reference are the deliberate server trade/disabled video-chest flows.
3. **Detail sheets:** restored the original Adventure information layout and
   close-before-open dragon selection. Corrected Inventory egg details to the
   centered 126px artwork, tag button, known-fact chips, clue and incubation rows;
   Altar uses its separate historical fact-row layout without a duplicate title.
4. **Collections and selectors:** restored Tower drag ordering; owned-kind egg
   filtering and stale-filter reset; removed added wellbeing meters. Found the
   Altar was still using the inventory tile grid: restored its compact egg list.
5. **Journeys and scores:** restored world/friends Trial rankings and seasonal
   shortcuts, including post-event windows. Exercised the actual Conclave
   Keepers entry with only server providers and a returned ranking row. Groups
   now reuse the restored direct-tap Adventure dragon picker.
6. **Tower and nest:** separate nest route with original scene/countdown widget,
   clue and starter taps. Original hatch scheduler remains server-authoritative.
   Reordering sends the existing canonical action, not a local room save.
7. **Actions and animation:** restored Return/Craft segmentation, full-hold Altar
   return, Sinister confirmation and the original modal material animation after
   the receipt. Android capture confirms the modal. Lost-reply test confirms one
   command and reconciliation without a duplicate return.
8. **Tutorial and account:** restored canonical target aliases, including the
   menu, group section, academy and nest. Menu shows achievement progress and
   original icons. Preserved improved Account Info; language row now aligns with
   its other ListTiles and uses the original language-card presentation.
9. **Screen sizes and language:** ten whole-main-route widget sweeps cover
   320/360/390/412/600 logical-pixel widths and starter/hatched states. Each visits
   all five root routes, Adventure/Inventory subtabs, About, account, journal,
   achievements and notification navigation. Android compact Dutch/large-text/
   reduced-motion inspection found a broken Trial title and missing historical
   refresh clock. Restored the shared clock from the confirmed server time and
   let the header controls wrap as a group without splitting the title.
10. **Server boundaries and final regression:** confirmed background refresh
    keeps the last confirmed UI visible; spending remains disabled while the
    session is unconfirmed. Group polling runs only in the visible pane and
    unchanged membership no longer triggers a full inventory synchronization.
    Owner/epoch checks, private egg facts, durable commands and hatch recovery
    remain in place. Server preflight checks 93 matching migrations and healthy
    Auth/application endpoints without a production gameplay deployment.

## Evidence and boundaries

- `test/server_app_widget_test.dart`: ten complete main-route sweeps.
- `test/canonical_ui_parity_test.dart`: finger-tracked swipe, all ranking scopes,
  actual Conclave route, quiet refresh, owned egg filters, canonical reorder.
- `test/canonical_lifecycle_widget_test.dart`: private egg facts, held Altar,
  lost replies, identity transitions and original selector interactions.
- Android `.tools/history-device-v062-*.png` captures and release logs are local
  evidence; no synthetic review account data is shipped in the production APK.
- The server does not expose the old destructive discard-egg command; it has
  not been simulated locally or silently mapped to an Altar reward. Egg
  incubation retains the existing canonical confirmation. Account improvements,
  protected assets, server failures and reconciliation remain intentional.
- Ad chests remain disabled as previously requested. No migrations, production
  ruleset changes, odds changes, saved-game rewrites or reward grants in this UI
  release.

Published as v0.06.02 / build 10095; final publication and production-health
evidence is recorded in `SERVER_ECONOMY_UI_VERIFICATION.md`.

## Post-v0.06.03 responsiveness and countdown follow-up

Predictable player actions now update the visible server snapshot immediately
and enter a bounded client queue. One durable request is sent at a time against
the latest confirmed revision. Each confirmation rebuilds the remaining
previews from absolute server state; a refusal rolls back its preview and drops
only dependent actions that are no longer valid. A lost response keeps the
already-sent request available for exactly-once recovery and cancels unsent
work. Account changes clear every preview before the new account can render.

The queue covers the existing safe predictions plus Tower room changes and
eligible solo-Adventure cancellation. Random or hidden outcomes, including
hatching and chest contents, remain exclusive server actions and are never
invented locally. Automatic refresh, hatch and milestone work waits for a
confirmed idle session, preventing it from racing player input. Queued requests
beyond the one durable head exist only in memory; process termination discards
those unsent previews without a server effect.

Running Adventure cards and details again show the v0.05.41 remaining-time
label. They advance from confirmed server time using a local monotonic clock,
without extra reads. Combined session, recovery, Adventure, Tower, hatch,
button and ten-route UI regression checks pass. No server code, migration,
ruleset, reward, production setting or player data changed in this follow-up.

## v0.06.04 interaction and service follow-up

Adventure start and claim now join cancellation on the immediate display path.
Starting removes the visible offer, reserves the selected dragon and creates a
server-time-anchored pending run; claiming removes the completed run and frees
the dragon. Pending runs cannot be claimed or cancelled using their provisional
ID. Confirmation replaces them with the authoritative run, while rejection or
an uncertain receipt restores confirmed state. No client preview invents a
chest, XP, expertise, evolution or hidden reward.

The missing Aerie and ranking actions were traced to the server-owned social
allowlist. The client had rejected `conclave.contribute` and scoped ranking reads
before any RPC was sent. Only those social operations and seasonal ranking reads
were admitted. Ranking sheets also retry after background work that intentionally
does not repaint the whole social UI. Gameplay reward mutations remain outside
this provider.

Server Inventory chest reveals now have a default tier sound, with Special Chest
overrides preserved. The deferred ad previews moved to Buy and display `Free
gems` (5) and `Free coins` (50). Their disabled buttons read `Watch an ad 3/3`;
they still contain no SDK, claim command or local grant. Focused Adventure, Shop,
social and parity coverage passes 111 tests, and Flutter analysis reports no
issues. Final release and production-health evidence is recorded in
`RELEASE_V0.06.04_VERIFICATION.md`.

## v0.06.05 historical collection and spacing follow-up

The selected-dragon sheet again uses the v0.05.40 action-card rows. For an
already named dragon, Rename is shown only when a Nameweaver Quill is owned,
and the sanctuary row states that the dragon leaves the Tower. My Dragons no
longer reserves an empty header-sized area, while contained artwork keeps its
natural aspect ratio.

Adventure availability cards again show their historical refresh countdown.
The root app schedules its canonical refresh at the next 15-minute boundary;
Group and event-partner reads no longer poll every few seconds. Manual refresh
uses the existing pull gesture. These reads do not alter rewards or generate
client-owned progress.

The Rooftop Nest chooser restores the v0.05.40 tile/list switch, saved sorting,
hatch-time labels, acquisition dates and public clue text. The standard Egg
collection restores direct tag buttons in both views and retains its historical
details presentation. Selection, tagging, preferences and nest placement still
use canonical commands with optimistic preview and server-error rollback.

Tower controls are right-aligned and the historical top spacing is restored.
Focused widget coverage checks the two Egg picker views, direct tagging without
opening details, dragon actions, Adventure refresh behavior and Tower layout.
No migration, server ruleset, runtime flag, reward, probability or player-data
rewrite is part of this release.

## v0.06.06 interaction and notification follow-up

Tower room changes again begin inside the selected floor, the redundant overview
zoom controls are removed, and dragon-type sorting is available in My Dragons.
Adventure sheets use the restored compact action layout. Available cards now
show both the expertise a dragon gives up and the expertise it trains, matching
the detail view without exposing hidden reward facts.

The server-account startup gate now re-enters authenticated loading after a new
sign-in instead of retaining the previous signed-out error. Account Info keeps
language in its aligned row and removes the duplicate overflow entry.

Notification access is presented as device state rather than a fire-and-forget
button. Permission changes immediately refresh push registration and canonical
egg, Adventure and Trial reminders. Android creates the stable events channel at
process start; Firebase targets the same channel. Social inbox rows are retained
when native presentation fails, while deliberately muted categories remain
handled. The isolated push-function update changes only this channel identifier;
it does not change gameplay runtime, rewards, scheduling or account preferences.
