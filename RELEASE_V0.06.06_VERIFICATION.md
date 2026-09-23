# DragonHaven v0.06.06 / 10099 verification

## Scope

This release completes the latest v0.05.40 presentation follow-up for Tower,
My Dragons and Adventures, repairs authenticated startup after signing out and
back in, and restores reliable Android notification permission and delivery.

All gameplay state remains canonical. The notification change does not alter
rewards, timers or account notification choices. It only makes device access
observable, re-registers the device after a permission change and prevents a
failed social notification from being acknowledged as delivered.

## Validation

- Version, updater and startup checks target `0.06.06` / build `10099`.
- Flutter analysis, full tests, server preflight, Edge Function verification,
  signed artifact verification, device review and publication evidence are
  recorded below as they complete.

## Server boundary

No migration, ruleset, runtime flag, minimum-build change or player-data rewrite
is required. The existing `dispatch-social-push` Edge Function receives one
payload-only change: Firebase is told to use the app's stable
`dragonhaven_events` Android channel. The deployment does not change its JWT
policy, secrets, scheduler or `private.push_runtime` configuration.

Production migration parity, database lint, Auth endpoints, application health,
game runtime and push runtime are checked before and after this isolated function
deployment and again after publication.

## Artifact and publication

- Intended tag: `v0.06.06`.
- Intended public asset: `DragonHaven.apk`.
- Permanent latest APK:
  https://github.com/Rakky88/DragonHaven/releases/latest/download/DragonHaven.apk
