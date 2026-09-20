# v0.06.02 UI and interaction review

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
