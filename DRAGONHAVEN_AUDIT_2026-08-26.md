# DragonHaven brede audit — 26 augustus 2026

Gecontroleerde release: **v0.04.02**

Gecontroleerde commit: **`8743bb097dcf7dab5c773b4b8f68dc933e9e3e03`**
Platform: Android / Flutter met Supabase voor de online functies

## Samenvatting

DragonHaven heeft een verrassend sterke basis voor een project van deze
omvang. De volledige testset slaagt, de analyzer is schoon, de database heeft
Row Level Security op alle zestien tabellen, de release-APK is correct
ondertekend en de sociale servermigraties zijn gelijk aan productie.

Er zijn geen bevestigde P0-problemen gevonden die nu direct alle gebruikers
blokkeren of een bewezen lek van private data veroorzaken. Voor een grote
openbare lancering zijn er wel zeven onderwerpen met hoge prioriteit:

1. tijdgestuurde Adventure- en Trial-overgangen muteren nu vanuit getters en
   worden daardoor niet altijd direct opgeslagen;
2. de waardevolle offline economie en Trial/Adventure-rewards zijn nog
   client-authoritative;
3. er is geen centrale crash- en non-fatal error logging;
4. een ingelogde gebruiker wacht vóór het eerste Flutter-frame op een online
   refresh;
5. de APK/AAB en beeldbibliotheek zijn zeer groot;
6. de automatische Play Store-AAB-workflow faalt zolang twee GitHub Secrets
   ontbreken;
7. sociale notificaties zijn nog geen echte pushnotificaties wanneer de app
   volledig gesloten is.

Mijn oordeel: **geschikt voor interne tests en een kleine gesloten bèta**, maar
nog niet voor een massale openbare lancering met een eerlijke online economie.

## Wat is gecontroleerd

- `flutter analyze --no-pub`: **0 issues**;
- volledige `flutter test --no-pub`: **207 tests geslaagd**;
- 25 testbestanden en circa 7.100 regels testcode;
- emulatorcontrole van Adventure, refresh-uitleg en het 2×3-winkelraster;
- release-APK: package `nl.dragonhaven.app`, versionName `0.4.2`, versionCode
  `10035`, geldige RSA-4096 releasehandtekening;
- APK: 295.297.609 bytes; AAB: 292.938.116 bytes;
- Supabase: 16 lokale/remote migraties gelijk, 0 database-lintfouten,
  Auth-health 200, Auth-settings 200 en e-mailauthenticatie actief;
- statische controle op bekende secrets in de huidige Git-tree;
- afhankelijkheden gecontroleerd met `flutter pub outdated`;
- 789 bestanden onder `assets`, samen 232.944.873 bytes;
- inhoudshashes van alle assets vergeleken om exacte duplicaten te vinden;
- Android manifest, signing, lokale opslag, notificatiebridge, audio,
  releaseworkflow, sociale RPC's en cloudbackup bekeken.

Dit is een technische audit, geen formele penetratietest, juridische controle,
store-review of gemeten productieloadtest. Gespecialiseerde tools als
Gitleaks, Semgrep, OSV Scanner en een echte screenreader-/devicefarmtest waren
niet geïnstalleerd en zijn dus niet als certificerende scans uitgevoerd.

## Sterke punten

### Code en tests

- De analyzer is volledig schoon.
- De testset dekt gameplayregels, persistence, online social flows,
  notificatiecategorieën, localization completeness, releaseversies,
  Draconomicon-art en sprite-bounds.
- Er zijn compact-screen- en grotere teksttests op onder meer 320–430 pixels
  breed en tot 1,35× tekstschaal.
- Reduced motion wordt gerespecteerd in de tutorial, achievement reveal en
  meerdere grote presentaties.
- De bestaande sprite-tests controleren onder andere alle 100 portraits en
  77 geselecteerde dragon-artbronnen op veilige uitsnede.

### Server en security

- Alle 16 publieke tabellen hebben Row Level Security ingeschakeld en directe
  tabelrechten voor clients zijn ingetrokken.
- Gevoelige handelingen lopen via begrensde `security definer`-RPC's met een
  vastgezette `search_path`.
- Trades gebruiken reserveringen, transacties, user locks, een limiet van één
  actieve trade, drie succesvolle trades per Amsterdamse dag en expiry.
- Cloudbackups gebruiken revision-based optimistic concurrency en een
  serverlimiet van 2 MiB.
- Het nieuwe achievement- en dragon-aantal deelt alleen getallen; de identiteit
  van achievements en private inventory worden niet aan vrienden gegeven.
- In de huidige bron zijn geen databasewachtwoorden, service-role keys,
  keystores of private sleutels aangetroffen. De Supabase publishable key in de
  client is daarentegen normaal en bedoeld als publieke clientconfiguratie.

### Release

- v0.04.02 is gepubliceerd vanaf de volledige commit-SHA hierboven.
- GitHub tag en `main` wijzen naar exact dezelfde commit.
- `DragonHaven.apk` is volledig geüpload; lokale en GitHub SHA-256 zijn beide
  `f27f500799fc968719a3fbeb6883914f427b012add2d5f469a9dd481ad8ff135`.
- De permanente latest-link verwijst naar v0.04.02.
- De lokale productie-serverpreflight is vóór publicatie geslaagd.

## P1 — hoge prioriteit

### AUD-001 — Tijdgestuurde getters muteren gameplay en kunnen rewards herrollen

Status: **bevestigde logica-/persistencebug**.

`adventuresFor`, `activeAdventureRuns` en `availableTrials` lijken getters of
leesmethodes, maar roepen intern `_refreshAdventureRuns()` of
`_refreshTrialOffers()` aan. `_refreshAdventureRuns()` rolt op dat moment ook
random de Adventure-kist. De UI leest deze waarden tijdens builds, maar die
getterroute slaat de wijziging niet op.

Gevolgen:

- een Adventure kan in het geheugen Completed worden zonder dat `rewardTier`
  al in SharedPreferences staat;
- na geforceerd afsluiten vóór claim/save kan dezelfde Adventure bij de
  volgende start opnieuw een reward rollen;
- Trial-aanbiedingen en Adventure-slots kunnen na herstart anders zijn wanneer
  een UI-build de refresh eerder uitvoerde dan de minuut-refresh;
- de UI-build bepaalt onbedoeld wanneer een gameplaytransactie plaatsvindt;
- tests met alleen een levende provider missen de process-deathvariant.

Bewijs: `lib/providers/dragonhaven_systems.dart` rond regels 427, 513–552,
656–658 en 999–1016; de persistente refresh staat apart in
`lib/providers/household_provider.dart` rond regels 1717–1758.

Aanpak:

1. maak alle publieke getters volledig read-only;
2. voeg één expliciete `advanceTime(now)`-transactie toe;
3. rol een Adventure-reward bij start, of deterministisch uit een opgeslagen
   seed, en bewaar die vóórdat Completed zichtbaar wordt;
4. sla alle offer/refill/statuswijzigingen atomair op en notify daarna;
5. voeg process-deathtests toe voor een net voltooide Adventure en een net
   aangevulde Trial.

### AUD-002 — De kern-economie is nog client-authoritative

Status: **bekende publieke-lanceringsblocker**.

Coins, gems, chest opening, egg rolls, Trial-rewards, lokale Adventures,
expertise, XP en veel achievements worden door Dart op het toestel berekend en
daarna als snapshot gepubliceerd. Trades en Group Adventures zijn veel beter
server-authoritative, maar een aangepaste client kan de offline kernprogressie
nog manipuleren.

Voor een eerlijke openbare economie moeten minimaal chest opening, pity,
Adventure/Trial claims, eggs, valuta, expertise/XP en shopmutaties idempotente
servercommando's worden. Gebruik per actie een unieke request-ID en één
databasetransactie met ownership-, limiet- en replaycontrole.

Bewijs: lokale random/rewardmutaties staan onder andere in
`lib/providers/household_provider.dart` rond regels 1263–1385 en
`lib/providers/dragonhaven_systems.dart` rond regels 581–630 en 959–1020.

### AUD-003 — Geen centrale crash-, error- of performance-observability

Status: **productieblocker voor support en incidentrespons**.

`main()` installeert geen `FlutterError.onError`,
`PlatformDispatcher.instance.onError` of `runZonedGuarded`. Er is ook geen
Crashlytics/Sentry-achtige reporter, release-ID in foutmeldingen, breadcrumb,
server request-ID of privacyveilige non-fatal logging.

Audio- en notificatiefouten worden bewust niet-fataal gemaakt, wat goed is voor
gameplay, maar ze verdwijnen volledig. `restoreCloudState` geeft bij elke
exception alleen `false`. Onbekende online fouten worden grotendeels naar één
algemene sociale fout vertaald. Daardoor is een gebruikersmelding lastig te
onderzoeken.

Aanpak:

- voeg een klein `AppErrorReporter`-abstraction toe;
- vang Flutter-, platform- en zone-errors centraal;
- registreer versie, scherm, actie, foutcategorie en correlation-ID, maar geen
  e-mail, wachtwoord, inventory of auth-token;
- laat storage recovery, cloud restore, RPC-fouten, notification delivery en
  asset decode als non-fatal events tellen;
- koppel daarna pas een door jou beheerd Crashlytics- of Sentry-project.

Bewijs: de volledige startflow staat in `lib/main.dart`; functionele catch-
blokken staan onder andere in `lib/services/audio_service.dart`,
`lib/services/notification_service.dart` en
`lib/providers/online_account_provider.dart` rond regels 572–587.

### AUD-004 — Online initialisatie blokkeert het eerste Flutter-frame

Status: **bevestigd startup-risico**.

Voor `runApp()` worden lokale state, Supabase, een volledige ingelogde online
refresh en audio afgewacht. Bij een trage of half bereikbare verbinding kan een
terugkerende ingelogde speler dus lang op het native splashscherm blijven.
Daarna doet `DragonHavenShell` direct nog een online refresh na het eerste
frame.

Bewijs: `lib/main.dart` regels 51, 60, 96 en 106; de extra post-frame refresh
staat in `lib/dragonhaven_app.dart` rond regels 101–105.

Aanpak: start Flutter na de lokale restore, toon de shell, initialiseer online
asynchroon met een timeout en retry-state, en verwijder de dubbele onmiddellijke
refresh. Meet cold start, warm start en signed-in/offline start op echte
toestellen.

### AUD-005 — Artifact en assetbibliotheek zijn te groot

Status: **duidelijke distributie- en performanceprioriteit**.

- APK: circa 281,6 MiB;
- AAB: circa 279,4 MiB;
- `assets`: circa 222 MiB daadwerkelijk relevante beeldmappen, met 224
  dragonbestanden van samen circa 115,8 MB;
- meerdere losse beelden zijn 1,5–4,2 MB.

De AAB past momenteel onder de base-modulegrens, maar een grote-downloadmelding,
langzamere installatie, hogere updatekosten en meer geheugendruk zijn reële
risico's. De debug-emulator had na een verse installatie bovendien zeer lange
assetextractie en een ANR; dat is geen bewijs dat de AOT-release hetzelfde doet,
maar wel een reden voor echte cold-startmetingen.

Aanpak:

1. inventariseer per asset de effectieve schermgrootte en decode-resolutie;
2. downscale beelden die nooit op bronresolutie verschijnen;
3. converteer de resterende grote PNG's waar alpha/kwaliteit dat toelaten;
4. zet families/rooms die niet direct nodig zijn in Play Asset Delivery;
5. verwijder niet-bereikbare legacy assets en audio;
6. stel een CI-budget in voor APK/AAB, grootste asset en totale assetbytes.

### AUD-006 — Automatische Play Store-workflow faalt en release signing faalt niet dicht

Status: **bevestigde operationele fout; handmatige APK-release zelf is gezond**.

GitHub Actions-run `33016402001` voor deze commit stopte in stap
`Verify linked production server`, omdat de repository secrets
`SUPABASE_ACCESS_TOKEN` en `SUPABASE_DB_PASSWORD` leeg zijn. Daardoor zijn de
CI-analyse, tests, release signing en Play Store-AAB niet uitgevoerd.

Daarnaast kiest `android/app/build.gradle.kts` bij een ontbrekende
`key.properties` stil de debug signing config voor een `release`-build. De
huidige APK is aantoonbaar met de juiste vaste sleutel getekend, maar een
toekomstige handmatige build kan zo ongemerkt update-incompatibel worden.

Aanpak:

- jij voegt beide Supabase Secrets toe in GitHub repository settings;
- rerun daarna de mislukte workflow;
- laat Gradle voor release builds hard falen wanneer release signing ontbreekt;
- controleer in CI de verwachte certificate SHA-256
  `477c5a5d7453384ca756265e77af97d5a002a907177ccd2d9065a9bec3414942`;
- laat tag, `AppInfo.version`, versionName en volledige commit-SHA automatisch
  tegen elkaar controleren.

Bewijs: `.github/workflows/release.yml` regels 45–57 en
`android/app/build.gradle.kts` regels 50–53.

### AUD-007 — Sociale notificaties werken niet als echte push bij gesloten app

Status: **functionele beperking die vóór openbare communicatie duidelijk moet
zijn**.

Friend requests, accepts en trade-events komen in een Supabase inbox. De app
haalt die tijdens een actieve sessie ongeveer elke twee minuten op en maakt dan
een lokale notificatie als de app op dat moment op de achtergrond is. Als het
proces volledig gesloten is, bestaat er geen FCM/APNs-trigger die het toestel
bereikt.

Aanpak: implementeer Firebase Cloud Messaging met servergestuurde push, bewaar
roteerbare device tokens, respecteer de bestaande categorievoorkeuren en zet
geen gevoelige trade-inhoud in het zichtbare bericht.

Bewijs: de polltimer staat in
`lib/providers/online_account_provider.dart` rond regels 566–568; de lokale
bridge staat in `lib/services/notification_service.dart`.

## P2 — middellange prioriteit

### AUD-008 — De zichtbare trade-dagteller kan afwijken van de serverlimiet

Status: **bevestigde UI-/tijdzonebug; de serverlimiet zelf blijft veilig**.

De app berekent `0/3`, `1/3`, enzovoort uit `TradeOffer.updatedAt` en de lokale
toesteldatum. De server telt via `completed_at` in de tijdzone
Europe/Amsterdam. Een acknowledgment wijzigt `updated_at`; rond middernacht of
buiten de Amsterdamse tijdzone kan de UI daardoor een ander dagtotaal tonen dan
de server werkelijk afdwingt.

Bewijs: `lib/providers/online_account_provider.dart` regels 105–114 tegenover
`supabase/migrations/202608240005_trade_limits_and_expiry.sql` regels 80–92,
230 en 332.

Aanpak: laat `get_online_snapshot` een serverberekend
`completed_trades_today` en `daily_trade_limit` teruggeven, of expose minimaal
`completed_at` en gebruik exact dezelfde serverdag.

### AUD-009 — AdventureHub blijft elke seconde rebuilden wanneer hij onzichtbaar is

Status: **bevestigd performance-/batterijprobleem**.

Na het eerste bezoek blijft `AdventureHubScreen` in de `IndexedStack`. Zijn
`Timer.periodic` doet elke seconde `setState`, ook wanneer de gebruiker op
Friends, Tower, Inventory of Shop staat. Dat rebuildt een scherm van circa
2.720 regels en triggert bovendien de muterende getters uit AUD-001.

Bewijs: `lib/screens/adventure_hub_screen.dart` regels 45–49 en
`lib/dragonhaven_app.dart` regels 369–375.

Aanpak: update alleen wanneer de Adventure-tab zichtbaar is, of gebruik een
kleine countdown-listenable per zichtbare timer. Pauseer de clock bij
app-background en bij een offstage route.

### AUD-010 — Lokale alarms overleven een reboot niet en exact-alarmbeleid is niet af

De manifest declareert `SCHEDULE_EXACT_ALARM`, maar er is geen boot receiver om
geplande alarms na een reboot opnieuw te installeren. De code valt netjes terug
op een inexact alarm wanneer exact niet is toegestaan, maar er is geen expliciet
productbesluit of de Play-policy voor exact alarms echt nodig is.

Aanpak: kies één van deze routes:

- verwijder exact-alarmpermission en accepteer inexacte reminders; of
- documenteer de kernfunctionaliteit, begeleid de gebruiker naar special access
  en herscheduleer alarms na reboot/app-update.

Bewijs: `android/app/src/main/AndroidManifest.xml` regels 3–4 en de alarmcode in
`MainActivity.kt` rond regels 268–299.

### AUD-011 — Grote bestanden en verantwoordelijkheden verhogen regressierisico

De codebase bevat circa 40.118 Dart-regels in 75 bestanden. Grootste bestanden:

| Bestand | Regels |
|---|---:|
| `lib/l10n/ui_phrase_translations.dart` | 5.975 |
| `lib/screens/adventure_hub_screen.dart` | 2.720 |
| `lib/providers/household_provider.dart` | 2.072 |
| `lib/providers/dragonhaven_systems.dart` | 1.638 |
| `lib/screens/trial_game_screen.dart` | 1.581 |
| `lib/screens/pet_screen.dart` | 1.565 |
| `lib/screens/friends_screen.dart` | 1.513 |

De provider combineert persistence, economie, achievements, house, eggs,
randomness en tijd. Het Adventures-scherm combineert vijf soorten aanbod,
Trials, actieve/completed runs en Group Adventures.

Aanpak: splits per domein met smalle services/repositories en immutable state.
Begin bij tijd/rewards, daarna online sync, Adventure widgets en Friends/trades.
Behoud de bestaande tests tijdens elke extractie.

### AUD-012 — Localization gebruikt Engelse UI-zinnen als runtime sleutel

`AppStrings.pick()` zoekt voor zeven niet-Engelse/niet-Nederlandse talen de
volledige Engelse zin op in een const map van bijna zesduizend regels. Een
kleine Engelse tekstwijziging maakt daardoor een vertaling onbereikbaar totdat
de map exact is bijgewerkt.

De completeness-test helpt sterk, maar dit blijft foutgevoelig en veroorzaakt
zeer grote diffs. Migreer geleidelijk naar stabiele IDs/ARB + gegenereerde
localizations. Voeg pseudo-localization toe om clipping en ontbrekende keys
zichtbaar te maken.

Bewijs: `lib/l10n/app_strings.dart` regels 41–45 en
`lib/l10n/ui_phrase_translations.dart` vanaf regel 560.

### AUD-013 — UI-testdekking mist goldens, volledige toegankelijkheid en brede form factors

Er zijn goede compacte widgettests, maar geen golden screenshot-baselines,
geen `meetsGuideline`-checks voor contrast/tap targets/labels, geen screenreader-
test en geen landschap/tablet/foldable matrix. De Trials zijn hoofdzakelijk
tap-gestuurd en verdienen expliciete Semantics-acties en alternatieve invoer.

Aanpak:

- goldens voor vijf hoofdpagina's, friend modal, Draconomicon en alle Trial
  complete/rank states;
- Android accessibility guideline-tests;
- 320×640, 430×900, tablet, landscape en 2,0× tekstschaal;
- echte TalkBack-test van Trials, trades, sheets en chest reveals;
- echte 60-fps/jankmeting op een middenklasse Android-toestel.

### AUD-014 — E-mailverificatie werkt technisch, maar redirect-UX is niet end-to-end bewezen

De client weigert onbevestigde accounts en Supabase heeft confirmations aan.
De signup geeft echter geen expliciete `emailRedirectTo` mee; de lokale Supabase
config gebruikt de GitHub latest-releasepagina als `site_url`. Dat kan een
geldige bevestiging opleveren, maar niet de mooiste terugkeer naar de app. De
remote dashboardconfig is niet door deze code-audit bewezen.

Aanpak: maak een eigen HTTPS-confirmatiepagina met duidelijke succes/foutstaat
en een knop terug naar DragonHaven. Test fysiek: nieuw account, resend, verlopen
link, al gebruikte link, password recovery en verschillende mailapps.

Bewijs: `lib/services/supabase_social_repository.dart` regels 34–49 en
`supabase/config.toml` regels 159 en 226.

### AUD-015 — Productie-afhankelijkheden zijn bewust maar te strak verouderd

`flutter pub outdated` meldt onder meer:

- `supabase_flutter` 2.14.2 → resolvable 2.17.2;
- `uuid` 3.0.7 → resolvable 4.6.0;
- bijbehorende Supabase transitive packages hebben eveneens nieuwere versies.

Dit is geen reden om blind te upgraden. Maak een aparte dependency-update met
Auth/session/deeplink-, RPC-, realtime- en persistence-regressietests.

### AUD-016 — Lokale save groeit monolithisch in SharedPreferences

De volledige JSON-state en één volledige backup staan in SharedPreferences.
Dit is eenvoudig en de recoverylogica is goed, maar grote dragon-, activity- en
placementcollecties vergroten serialisatie- en write-kosten. Er is geen lokaal
schema met incrementele transacties.

Aanpak: meet echte savegroottes bij langdurige accounts. Stel een waarschuwings-
en testbudget in; migreer pas bij aantoonbare groei naar een transactionele
lokale database. Houd de bestaande backup/recoveryfunctie behouden.

## P3 — polish en onderhoud

### AUD-017 — Twee achievement sprites zijn byte-voor-byte identiek

`assets/images/achievements/first_ascension.png` en
`assets/images/achievements/triple_mastery.png` hebben exact dezelfde SHA-256
en zijn beide 92.325 bytes. De catalogus gebruikt ze voor twee verschillende
achievements. De huidige test controleert unieke assetnamen, niet unieke
beeldinhoud.

Aanpak: geef Triple Mastery eigen artwork en voeg een inhoudshash-test toe,
met alleen expliciet gedocumenteerde uitzonderingen.

Bewijs: `lib/models/achievement.dart` regels 149 en 204.

### AUD-018 — Audioresources en licentietekst lopen achter op Classic-only

De code speelt voor iedere music scene altijd `reverie`, zoals gewenst. Toch
zijn `tower_day`, `tower_night`, `room` en `reveal` nog gebundeld en noemt
`AUDIO_LICENSES.md` Rêverie nog optioneel en selecteerbaar. Samen zijn alleen
die vier legacytracks ongeveer 8,7 MB.

Ook `README.md` loopt achter: daar staan nog vier actieve ambient tracks en 25
achievements, terwijl de actuele catalogus 30 achievements bevat en Rêverie de
enige soundtrack is.

Aanpak: behoud de licentiehistorie, markeer de tracks als retired of verwijder
ze uit de app resources wanneer geen fallback nodig is, en update de tekst naar
Classic-only.

Bewijs: `MainActivity.kt` regel 348, `AUDIO_LICENSES.md` regels 4, 12–15 en
28, en `README.md` regels 17 en 19.

### AUD-019 — `integration_test` staat bij productie-dependencies

`integration_test` staat onder `dependencies` in plaats van
`dev_dependencies`. Verplaats dit; het is testinfrastructuur en geen runtime-
dependency.

Bewijs: `pubspec.yaml` regel 13.

### AUD-020 — Android backup- en data-extractiebeleid is niet expliciet

Het manifest stelt `allowBackup`, `fullBackupContent` en `dataExtractionRules`
niet expliciet in. Android-defaults en OS-versie bepalen daardoor of lokale
SharedPreferences via platformbackup worden meegenomen. Maak bewust een keuze
voor game-save, device-ID en Supabase-sessiondata en leg die vast in XML.

## Specifieke beoordeling van de nieuwe v0.04.02-wijzigingen

- Friend modal toont alleen het aantal achievements; de identiteit blijft
  privé. **Goed.**
- Draconomicon scheidt owned dragons van ontdekte families. **Goed**, met de
  kanttekening dat friend-counts client-published en dus cosmetisch, niet
  competitief betrouwbaar zijn.
- Completed is een apart tabblad en claims verdwijnen na afhandeling. **Goed**,
  maar AUD-001 moet voorkomen dat de random reward vóór claim niet duurzaam is.
- Adventure-uitleg is kort, per type en visueel passend. **Goed.**
- Het winkelraster is visueel duidelijk en bleef zonder overflow in de
  gecontroleerde emulator. Voeg nog 320px/2,0×-tests toe.
- Account Info heeft nu een logischere Vanity/Preferences-hiërarchie. **Goed.**
- De nieuwe servercounts zijn begrensd en alleen authenticated uitvoerbaar.
  **Goed.** Oudere clients publiceren deze velden pas na update; tijdelijk nul
  is daardoor verwacht.

## Aanbevolen uitvoervolgorde

### Eerstvolgende technische patch

1. AUD-001: pure getters + persistente/deterministische tijdtransities;
2. AUD-008: serverberekende trade-dagteller;
3. AUD-009: offstage Adventure-clock stoppen;
4. AUD-006: release signing fail-closed en SHA-check;
5. AUD-017/018/019: duplicate art, retired audio en dependencyplaatsing;
6. regressietests en een kleine patchrelease.

### Voor een openbare bèta

1. centrale error reporting en privacyfilter;
2. startup niet langer door netwerk blokkeren;
3. GitHub Secrets instellen en groene AAB-workflow afdwingen;
4. echte e-mailverificatie-/recoverytest op toestel;
5. package-sizebudget en eerste assetoptimalisatie;
6. accessibility- en device-matrix.

### Voor een grote publieke economie

1. server-authoritative reward/economycommands;
2. FCM push en token lifecycle;
3. stagingproject, loadtest, database/querymetrics en alerts;
4. eigen SMTP, privacy/delete-site en store compliance;
5. fraud/replay/auditlogs en incidentprocedure.

## Wat jij nog moet doen

1. Voeg in GitHub onder **Settings → Secrets and variables → Actions** toe:
   - `SUPABASE_ACCESS_TOKEN`;
   - `SUPABASE_DB_PASSWORD`.
2. Rerun workflow
   `https://github.com/Rakky88/DragonHaven/actions/runs/33016402001` en controleer
   dat `DragonHaven-Play-Store` als AAB-artifact verschijnt.
3. Maak/bezit een Firebase- of Sentry-project wanneer crashrapportage en push
   worden geïmplementeerd; Codex kan daarna de technische koppeling doen.
4. Regel de account-, privacy-, SMTP-, store- en juridische punten uit
   `PUBLIC_LAUNCH.md` vóór een echte openbare lancering.

De Supabase access token en het databasewachtwoord zijn secrets. Zet ze nooit
in broncode, een issue, release notes of dit document.

## Hercontrolecriteria

Een volgende brede audit mag deze punten pas sluiten wanneer:

- process-deathtests bewijzen dat completed rewards en nieuwe offers stabiel
  blijven;
- een gemanipuleerde client geen economische reward zelf kan toekennen;
- een testcrash en non-fatal event met de juiste release-ID zichtbaar zijn;
- signed-in offline cold start snel naar bruikbare UI gaat;
- GitHub Actions volledig groen een correct gesigneerde AAB oplevert;
- de artifactgrootte aantoonbaar is gedaald en bewaakt wordt;
- friend/trade push een volledig gesloten app bereikt;
- trade `x/3` exact gelijk blijft aan de server rond Amsterdamse middernacht;
- TalkBack, groot lettertype, tablet en landscape een vastgelegde testmatrix
  hebben.
