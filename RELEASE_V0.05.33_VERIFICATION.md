# v0.05.33 / 10083 verification

Trial results now present their credited event-point delta after returning from
the result route, for legacy and canonical flows. Zero-point, cancelled and
uncredited outcomes do not present reward particles. Reduced motion suppresses
particles. Existing Adventure claim-only timing remains unchanged.

The complete liquid chamber is unobstructed while filling. The reward chest
appears only after the animated fill reaches its end. Friends and the event
picker share compact themed rows with fixed portrait wells and equal geometry
with or without vanity frames; chat, trade and unread indicators remain.

Valentine synchronization waits for pending social/cloud operations instead of
immediately discarding the invitation. Cloud conflicts remain protected and
produce an explicit message; server eligibility errors are distinguished.

## Verification

- Real staging Auth/RPC probe: invitation succeeds with no recipient event save
  and without the recipient making a request. Subsequent invitation/acceptance
  with independent preview keys shares each keeper's correct contribution.
  All temporary probe accounts were deleted and cleanup checked.
- Production preflight: 83 matching migrations, zero lint errors, Auth health,
  Auth settings and application health HTTP 200.
- Regenerated server worker is unchanged: 1,189,604 bytes, SHA-256
  `af09b2bb4266893fb67de2337f23a5327aca08b0ac36f64a700069f67f4b4e15`.
  No server deployment, migration or authority-switch changes are required.
- All 939 Flutter tests pass; analysis reports no issues. Reference guard is
  synchronized and public release notes contain no private operational codes.
- Android emulator review: unobstructed Halloween and Valentine meters, fully
  filled chest button, and 320dp large-text/reduced-motion layout. A presentation
  harness recorded a five-point return from a simulated C result route into the
  real meter; all particles arrived after the route closed. Actual Trial award
  rules are covered by the passing gameplay suite. The emulator's graphics
  backend was unstable after heavy concurrent builds; software rendering
  completed the visual checks successfully.
- Compact friend rows and the picker were also reviewed with actual sprites
  and both framed/unframed portraits during the preceding implementation.
- Final APK installed over the emulator app: About displays v0.05.33 and the
  saved English language, one floor, 25 coins and 3 gems remain intact.

## Signed APK

Package `nl.dragonhaven.app`, version `0.05.33`, build `10083`.
Size: **628260114 bytes**. SHA-256:
`0d178d13026d7e886ff0bc0634ac022c97a6a0a4da4f5b3e19379514218611c3`.
Existing signing certificate verified:
`477c5a5d7453384ca756265e77af97d5a002a907177ccd2d9065a9bec3414942`.

[Release](https://github.com/Rakky88/DragonHaven/releases/tag/v0.05.33)
[Version APK](https://github.com/Rakky88/DragonHaven/releases/download/v0.05.33/DragonHaven.apk)
[Permanent APK](https://github.com/Rakky88/DragonHaven/releases/latest/download/DragonHaven.apk)

Publication verified: GitHub latest resolves to v0.05.33; asset size and SHA-256
match the local APK, and the permanent download responds HTTP 200. Tag source:
`dc8ef9d4dcf4c53f66ebd148318b88a65faf3396`.
