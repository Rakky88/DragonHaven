# Release v0.06.00 / 10093 verification

## Scope

Restores the illustrated server-owned Adventures, Tower, Inventory and My
Dragons UI; adds the logo shortcut to About. The previous release's server
contract, redaction, authority, migrations and durable command engine are
unchanged. The current branch also includes already committed launch-logo and
notification navigation fixes.

Video Chests are disabled previews by the owner's explicit choice. AdMob
onboarding, SDK/consent, signed callbacks and daily claim accounting are pending,
not claimed as operational. See REWARDED_CHESTS_SETUP.md.

## Checks

Production preflight at 2026-09-20 16:42:43 UTC: 92 matching migrations, zero
DB lint errors, Auth health/settings and application health HTTP 200, skew 9 ms.
Flutter analysis passes with no issues. The full suite exercised 1,047 tests
plus one existing optional skip: 1,041 initially passed. After updating the
old UI/version assertions and completing all six additional language tables,
the 85-test subset covering the six failures passed. The Academy visual test
also passes on recheck; its first run timed out under concurrent build load.
The documentation guard's transient review-manifest mismatch cleared after the
isolated emulator build restored the release manifest. Final targeted server
UI, shop preview and reference tests are recorded below when complete.

An isolated emulator app uses synthetic server facts and the real canonical
UI/actions. Normal-size Adventures, Trials, Tower, Inventory, Altar, relics and
My Dragons screenshots were inspected. No player save was cleared. Compact
review and release artifact/publication checks are still pending.
