# Event logos and dragon picker refinement

Development checks after v0.05.20 / Android 10070, recorded on 8 September 2026.
These changes are now included in v0.05.21 / 10071; publication and final server
evidence are in `RELEASE_V0.05.21_VERIFICATION.md`. No database, Edge Function,
Firebase setting, account save or economy switch was changed for this work.

## Behavior and artwork

- My Dragons and the Adventure/Trial Expertise dialogs use the original Might,
  Arcana and Spirit sprites with a colored silhouette glow when selected. Stars
  and the yellow Expertise-row fill are removed. Each toggle remains independent
  and accessible; reduced motion disables the short selection transition.
- Both dragon pickers use the existing Draconomicon sprite in a 48dp touch target
  next to the title. The tooltip/accessibility label remains; the extra text row
  is removed. Returning from the codex preserves the picker without starting it.
- All six events have complete logo variants based on the original wing-and-egg
  mark: Halloween, Christmas, New Year, Valentine, Pride and Golden Wings.
  Transparent 1254px PNG originals are in `assets/images/event_logos/`.
  They were generated with the built-in `image_gen` tool, not the CLI/API path.
  Exact prompts and the reference are in `artwork_sources/event_logos/prompts.json`.
  Generated originals retain their alpha unchanged. Run
  `dart run tool/build_event_branding_icons.dart` to recreate Android density,
  adaptive-icon and splash derivatives with deterministic resizing/padding.

## Android behavior and limits

The Flutter header and Android launcher share the existing Amsterdam event
calendar and account previews. Live events win over previews; earliest end time,
then occurrence key, breaks ties. Three future calendar passes are persisted
locally; expired/personal windows are removed on synchronization. The annual
New Year occurrence remains recognized on 1 January until its configured end.

Seven launcher aliases target the permanently enabled MainActivity. Exactly one
alias is enabled, preserving explicit notification entry into MainActivity.
Android 13+ changes aliases atomically; older Android enables the replacement
before disabling the previous alias. Android 12+ uses the selected launch icon
for the system splash; MainActivity also selects the matching legacy loading
background. The ordinary logo remains the fallback.

An emulator check found that disabling the alias of the visible task can close
it even with DONT_KILL_APP. Launcher changes are therefore deferred while the
activity is visible and applied in onStop. The in-app logo changes immediately.
The persisted calendar also refreshes on inexact local alarms, reboot, app
replacement and clock changes. This requires no new permission or server call.
Android may delay alarms or cache a launcher icon; force-stop requires a later
app open. A fresh installation uses the ordinary icon until first calendar sync.
Existing pinned shortcuts and icon-refresh latency are launcher dependent.

Platform references: [activity aliases](https://developer.android.com/guide/topics/manifest/activity-alias-element),
[PackageManager component states](https://developer.android.com/reference/android/content/pm/PackageManager),
and [Android splash screens](https://developer.android.com/develop/ui/views/launch/splash-screen).

## Verification

- Interaction captures inspected at 360dp, including 1.6x text: Tower, Shop,
  My Dragons details, Trial Expertise dialog and both dragon pickers. Updated
  captures show the actual sprite silhouette glow and full compact titles.
- Tests cover independent highlight toggles, selected sprite states, both
  Draconomicon round trips, event priority/expiry, all six PNG/native assets,
  Amsterdam DST, New Year recurrence boundaries, removal of previews and native
  bridge deduplication/retry after a platform error.
- Shared headless Dart rules compile to JavaScript successfully (940,792 bytes);
  this artifact was not deployed. Reward tables and random draws are unchanged.
- Signed Android x64 preview build succeeds. The local verification entry uses
  an in-memory game and disabled online repository/Firebase; it is ignored by
  Git and is not a release artifact. Android 37 emulator screenshots confirm
  the new Halloween artwork in both the launcher and the cold-start splash.
- Final full suite: **625 tests pass** with `--concurrency=1` (3m43s). Full
  analyzer and the final asset-test analysis report no issues. Living-reference
  verification and its test pass. All six logos are explicit pubspec assets and
  are decoded from the actual Flutter root bundle in the regression test.
- Native preview selection verified Halloween, Christmas, New Year, Valentine
  and Pride with exactly one enabled launcher; selection preserves the visible
  activity and onStop applies the new alias. Golden Wings has no personal
  preview duration; its artwork and real calendar mapping are covered by the
  bundled-asset and calendar tests, not a fabricated preview entitlement.
- The emulator's system UI gesture monitor stalled during concurrent
  verification (21:37, edge-swipe input timeout). Restarting that system UI
  resolved the dialog. Older Android versions and third-party launchers were
  not device tested.
- A 20-second foreground preview restores the ordinary header at expiry;
  leaving the app restores the single default launcher. The published v0.05.20
  / 10070 APK was then reinstalled as an update, preserving the existing game
  (25 coins, 3 gems and its original dragon). Its MainActivity launcher opens
  normally, and the temporary emulator storage threshold was restored to null.

Local evidence is under `release/event-branding-*` and
`release/event-training-*.png`; that directory is not part of the source change.
The original v0.05.20 release and production evidence remains in
`RELEASE_V0.05.20_VERIFICATION.md`.
