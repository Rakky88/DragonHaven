# DragonHaven v0.06.03 / 10096 verification

## Scope and reference

Six independent scoped agents compared the server app against v0.05.41
(`5a4a1ef9b9a0e269b89cbeeae2b4cee0d5d07067`). Findings, restored flows and
remaining deliberate limits are in UI_V00541_PARITY_REVIEW.md.

Supported deterministic purchases, collection preferences, profile selections,
dragon highlights/favorite/name, egg tagging/placement, crafting and floor order
can update the display before confirmation. This preview is memory-only and
cannot enter the snapshot cache or authorize another economic action. Rejection
or uncertain transport restores confirmed display; durable receipts reconcile
lost replies exactly once. Random outcomes remain server-issued. This does not
promise zero network latency or offline economic authority.

Successful sequential requests reuse a connection; concurrent requests remain
isolated and account changes/timeouts close the appropriate connections. No
backend deployment, migration, ruleset/minimum-build change or player-data write
is included. Advertising chests stay disabled.

## Validation

- Full Flutter suite: 1,087 passed, one skipped, two initial failures. Both
  failures fixed: long reward labels at compact width and a source-literal
  localization lookup. The complete affected shop suite subsequently passed
  all 9 tests, including a new deterministic all-relic large-text regression.
- Localization/reference suite: 15 passed after corrections.
- Optimistic session tests: six passed (immediate display, confirmed-only cache,
  server rejection, lost committed reply, account change and hidden outcome).
- Transport: 14 tests passed; hatch scheduler: three passed. All new UI history
  tests and ten server-root route sweeps passed in the full suite.
- Final analysis of lib, test and tool: no issues. Reference guard and public
  release-note privacy checks pass.
- Production preflight at 2026-09-20 20:33:32 UTC: 93 matching migrations,
  zero database lint errors, Auth health/settings and application health 200.

Android visual review, final artifact digest and publication confirmation are
recorded below after completion.

## Android artifact and visual review

The signed universal production APK is version `0.06.03`, build `10096`, with
ARM64, ARMv7 and x86_64 libraries. It is 578,490,303 bytes and has SHA-256
`c3568a11ed09bcc73adb039f9e758739fa471314fde14af9adec3378bd4a40d1`.
The expected release certificate SHA-256 is
`477c5a5d7453384ca756265e77af97d5a002a907177ccd2d9065a9bec3414942`.

The isolated Android review package was exercised at normal phone size and at
320dp-equivalent compact width with 1.3 text scale and reduced motion. Captures
cover Tower, My Dragons, dragon details, Adventures, Trials and Altar. The
historical draggable My Dragons sheet, compact Tower rooms, Adventure cards,
Trial constellation/cards and Altar controls render without exceptions. The
large-text routes remain scrollable and the original horizontally scrollable
Adventure tabs remain swipeable.
