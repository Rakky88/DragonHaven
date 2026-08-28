# DragonHaven v0.04.07

## Online account reliability

- Local gameplay and navigation remain available while the first online refresh
  is slow or temporarily unavailable.
- Recoverable online failures now use bounded timeouts and clearer retry paths.
- New accounts show their e-mail confirmation state and can request a new
  confirmation mail without an active session.

## Safer cloud saves

- Cloud saves now track their last known server revision so another device
  cannot be silently overwritten.
- When local and cloud progress conflict, DragonHaven offers a safe cloud restore
  or lets the player continue locally without destroying the remote save.
- Restoring a cloud save first preserves a local recovery copy.

## Support and release safety

- Account Info can create a privacy-safe support report with a support code and
  recent technical events, without e-mail addresses, tokens or save contents.
- Online actions now carry correlation IDs that make failures easier to trace.
- The release pipeline verifies the production server, signing certificate,
  package name, version code and Play Store bundle before publication.
