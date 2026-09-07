# DragonHaven staging-loadtest

Laatst bijgewerkt: **7 september 2026**
Uitgangsversie: **v0.05.16 / productieschema 44 / stagingschema 47**

## Doel en huidige status

Deze test meet realistisch online leesgedrag uitsluitend op het afzonderlijke
Supabase-stagingproject. De dependency-vrije Dart-runner en handmatige GitHub
Actions-workflow zijn lokaal gebouwd en getest. De eerste echte 100-user run
is uitgevoerd; de Auth-begrenzing sloot de vervolgpoort naar 1000 gebruikers.
Productie is niet gewijzigd.

De eerste uitvoerbare stap is 100 gelijktijdige virtuele gebruikers. De stap van
1.000 gebruikers wordt technisch geweigerd zolang geen geslaagd 100-user rapport
met maximaal 2% fouten en 100 geslaagde logins en bootstraps op dezelfde migratieversie is aangeleverd. Andere aantallen, waaronder 5.000 of
10.000, worden door dit profiel niet geaccepteerd.

## Realistische workload

Iedere virtuele gebruiker heeft een eigen bevestigd synthetisch account, logt
eenmaal in, voert de idempotente accountbootstrap uit en gebruikt daarna rustige
wachttijden van acht tot twintig seconden.

| Actie | Verdeling |
| --- | ---: |
| Volledige online snapshot ophalen | 50% |
| Eigen profiel openen | 15% |
| Group Adventures bekijken | 15% |
| Cloudback-upgeschiedenis bekijken | 10% |
| Conclave-overzicht bekijken | 10% |

De test duurt standaard drie minuten en bouwt de belasting gedurende zestig
seconden op. Dit benadert appgebruik beter dan constante requestspam. Schrijvende
economie- of rewardacties zijn bewust niet opgenomen zolang fase 4 nog niet
server-authoritative is.

## Ingebouwde veiligheidsgrenzen

- Alleen handmatige `workflow_dispatch`; nooit een schedule, push- of
  pull-requesttrigger.
- Productie-URL én productie-projectreference worden onafhankelijk in workflow
  en runner hard geweigerd.
- Alleen een `sb_publishable_`-clientkey wordt geaccepteerd; geen service-role
  key of databasewachtwoord.
- Een echte run vereist de exacte tekst
  `RUN_DRAGONHAVEN_STAGING_LOAD_100` of
  `RUN_DRAGONHAVEN_STAGING_LOAD_1000`.
- Het aantal unieke, bevestigde synthetische accounts moet minstens gelijk zijn
  aan het aantal virtuele gebruikers; credentials delen tussen VU's is niet
  toegestaan.
- E-mailadressen, wachtwoorden, tokens, user-id's, responsebody's en savedata
  worden niet gelogd of in artifacts geschreven.
- Een run rapporteert alleen aantallen, veilige foutklassen, responsebytes en
  p50/p95/p99/max-latency per operatie. De nieuwste repositorymigratie wordt
  genoemd, maar nooit ten onrechte als geverifieerde serverstand gepresenteerd.
- De workflow heeft een twintigminuten-timeout en artifacts verlopen na dertig
  dagen.

## Wat Codex heeft gebouwd

- [`tool/staging_load_profile.dart`](tool/staging_load_profile.dart): planmodus,
  targetvalidatie, credentialpoolvalidatie, rustige workload, sequentiële
  100→1.000-poort en privacyarm JSON-rapport.
- [`.github/workflows/staging-load.yml`](.github/workflows/staging-load.yml):
  handmatige plan-/100-/1.000-user workflow met `staging`-environment.
- [`test/staging_load_profile_test.dart`](test/staging_load_profile_test.dart):
  unit tests voor aantallen, productieblokkade, unieke accounts, percentielen en
  de 100→1.000-poort.
- Contracttests bewaken dat workflow en runner geen productie- of service-role
  route krijgen.

## Tijdelijke synthetische accounts

De optie `temporary_accounts=true` gebruikt de bestaande beschermde staging-
Management-token voor een afzonderlijke setupwrapper. Deze maakt unieke accounts
op het niet-bezorgbare domein `dragonhaven-load.invalid`, met een willekeurig
wachtwoord per account en een specifieke runmarkering in `app_metadata`.
Admin-create met `email_confirm=true` bevestigt direct en verstuurt geen mail
([Supabase createUser](https://supabase.com/docs/reference/javascript/auth-admin-createuser)).
De benodigde sleutel blijft uitsluitend in de setupwrapper; de Dart-loadrunner
ontvangt een publishable key en normale accountwachtwoorden in zijn procesomgeving.
Er wordt geen sleutel aangemaakt of geroteerd. De Management-route gebruikt
`api-keys?reveal=true` in geheugen ([API-reference](https://supabase.com/docs/reference/api/v1-get-project-api-keys)).

Een finally-blok verwijdert alleen accounts met zowel de exacte runmarkering als
het verwachte synthetische adrespatroon, en controleert daarna opnieuw. Een aparte
`always()`-stap herstelt opruiming na een onderbroken loadstap. Het levenscyclus-
artifact bevat uitsluitend een willekeurige runidentifier en aantallen, zonder
account-ID's, adressen of credentials. Bij een volledige runneruitval kan hetzelfde
script met `-CleanupRunId` worden gebruikt. Opruiming van andere accounts wordt geweigerd.

De bestaande optie met `STAGING_LOAD_CREDENTIALS_JSON` blijft beschikbaar voor een
vooraf ingerichte, uitsluitend synthetische accountpool. Tijdelijke accounts hebben
geen mailbox, signupinstellingen of extra secret nodig. Vóór en na elke echte run
controleert de workflow volledige stagingmigratiepariteit, database-lint en health.
Productie blijft onafhankelijk hard geblokkeerd.

## Uitvoering en bewijs

1. `plan-100` maakt zonder secrets of netwerkbelasting een controleerbaar plan.
2. `run-100` gebruikt de exacte bevestiging en schrijft
   `staging/load-report.json`.
3. Controleer eerst dat de laatste groene staging-verificatierun dezelfde
   migratieversie heeft als `repositoryMigrationVersion`. Noteer vervolgens vlak
   vóór, tijdens en na de loadrun in het Supabase Dashboard: piekverbindingen,
   CPU, database/querylatency, provider-egress, rate limits en eventuele
   query-/indexbevindingen. Clientcode kan die providerwaarden niet betrouwbaar
   afleiden.
4. Beoordeel p95/p99 en fouten. Bij meer dan 2% fouten of een ontbrekende geslaagde login/bootstrap stopt de vervolgpoort.
5. Alleen na een groen rapport krijgt `run-1000` het workflow-run-ID van de
   100-user meting. De workflow downloadt en valideert dat artifact voordat een
   request wordt verstuurd.

Een testresultaat is geen toestemming voor betaalde capaciteit. Eerst meten we
gratis op staging; alleen aantoonbare grenzen kunnen later aanleiding geven tot
een afzonderlijk upgradebesluit.

## Eerste echte meting - 7 september 2026

Run [34115250094](https://github.com/Rakky88/DragonHaven/actions/runs/34115250094),
schema 47, 180 seconden met 60 seconden ramp-up vanaf dezelfde CI-runner:

| Controle | Uitkomst |
| --- | --- |
| Accounts gemaakt / verwijderd | 100 / 100; cleanup opnieuw gecontroleerd |
| Login / bootstrap geslaagd | 59 / 59 |
| Geweigerde login | 41 HTTP 429 |
| Alle aanvragen | 861; 820 geslaagd; 4,762% fouten |
| Lees-RPC's | 702; allemaal geslaagd |
| Snapshot p95 / p99 | 319 / 336 ms |
| p95 overige lees-RPC's | 309-322 ms |
| Preflight na afloop | schema 47, nul lintfouten, Auth/settings/app HTTP 200 |
| 1000-user vervolg | geweigerd; geen run gestart |

De run blijft terecht als **failed** geregistreerd. De uitkomst is geen bewijs
voor 100 of 1000 actieve spelers. De 429-responsen passen bij de gedocumenteerde
Auth-tokenbucket per IP ([Supabase rate limits](https://supabase.com/docs/guides/auth/rate-limits));
alle logins kwamen vanaf dezelfde CI-runner. Het volgende meetontwerp moet
gewone sessieopbouw scheiden van loginpieken en bestaande beveiligingslimieten
respecteren. Provider-CPU, verbindingen en echte egress zijn nog niet gemeten.
De eerdere poging 34114939684 maakte geen accounts; de transportfout is hersteld
met een apart offline contract dat voortaan voor iedere workflowrun draait.
