# DragonHaven v0.05.21 / 10071

Release preparation on 8 September 2026. Publication evidence will be added after
the signed production artifact, CI and public download checks complete.

## Scope

- Direct Expertise sprite glow, full six-event app/launcher/startup logos and
  compact Draconomicon sprite shortcuts beside both dragon-picker titles.
- Annual New Year windows retain their existing end time across 1 January.
- Visible version, updater version, pubspec and Android build increment one
  step to v0.05.21 / 10071. Regression expectations are updated together.
- Development analysis, 625 tests and visual evidence are recorded in
  `EVENT_BRANDING_VERIFICATION.md`. Release checks use the updated version.

## Server

- Production preflight at 19:43:11 UTC: exact migrations 1–57, lint 0 and
  Auth health/settings/application health HTTP 200; clock skew 64 ms.
- No database migration, Edge Function deployment, Firebase configuration change
  or economy activation is needed. The release retains existing production
  integration and signing. No billing or paid service is enabled.

## Publication strategy

The Android release workflow validates the exact source and retains a signed
Play Store AAB. It has read-only contents permission and does not publish a
GitHub release. The release-publisher script is the only APK publisher; the
stable public asset name remains `DragonHaven.apk`.
