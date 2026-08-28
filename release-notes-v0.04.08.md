# DragonHaven v0.04.08

Deze release versterkt online herstel, cloudback-ups en veilige servermigraties.

## Nieuw en verbeterd

- Cloudback-ups bewaren nu de huidige plus vier vorige revisies gedurende
  maximaal dertig dagen.
- Account Info toont herstelbare back-upgeschiedenis met datum, appversie en
  saveschema; een oudere revisie kan na bevestiging worden hersteld.
- Multi-device conflicten overschrijven voortgang niet meer stil. Je kunt de
  cloud bekijken, lokaal voorlopig behouden, cloud herstellen of bewust de
  cloudkopie vervangen terwijl de vorige revisie herstelbaar blijft.
- Bestaande-save-imports krijgen een afgeschermd auditrapport, plausibiliteits-
  limieten, SHA-256-herkomstbewijs en tijdelijke herstelkopie.
- Timeouts, verlopen sessies, dubbele taps en herhaalde online reward/trade-
  requests worden veiliger en duidelijker afgehandeld.

## Server en kwaliteit

- Productiemigraties 21 tot en met 23 voegen de geauditeerde save-import en
  begrensde cloudrevisiegeschiedenis toe.
- Group Adventure completion, identieke rewards voor deelnemers en replay-
  beveiliging zijn volledig op een geïsoleerde stagingfixture getest.
- De releasegate controleert migratiepariteit, database-lint, publieke Auth,
  analyzer, alle tests, appversie, package-ID, signingcertificaat en hashes.
