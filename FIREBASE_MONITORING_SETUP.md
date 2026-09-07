# Firebase-monitoring en push voor DragonHaven

Bijgewerkt: 7 september 2026. Firebase is kosteloos ingericht onder het
Google-account van de eigenaar. De gepubliceerde app blijft v0.05.18 / 10068;
de nieuwe appcode staat op `feature/free-monitoring-and-growth`.

## Projecten en kosten

| Omgeving | Firebase-project | Android-app-ID |
| --- | --- | --- |
| Productie | `dragonhaven-20ced` (door Rick aangemaakt: Dragonhaven) | `1:136858965382:android:aa1f3f01016f0254720807` |
| Staging | `dragonhaven-prod-rakky88` (weergavenaam DragonHaven Staging) | `1:105248573133:android:116f9962f98042d8330b84` |

De staging-ID is een historische, onveranderlijke project-ID; de build controleert
het expliciete omgevingsregister in `firebase-projects.json`, niet het woord prod.
Beide projecten zijn via de Google Billing API gecontroleerd: geen billingaccount
en billingEnabled=false. Geen Firebase Functions, Firestore, Storage,
BigQuery-export of betaald abonnement ingericht. FCM, Crashlytics en Performance
zijn beschikbaar zonder kosten volgens de
[Firebase-abonnementen](https://firebase.google.com/docs/projects/billing/firebase-pricing-plans).
De bestaande Supabase-quota blijven relevant; zie `GROWTH_AND_COST_PLAN.md`.

## App en privacy

- Firebase Core, Crashlytics, Performance en Messaging zijn aangesloten op de app.
  Een build zonder configuratie behoudt het lokale diagnostiekbuffer.
- Productie verzamelt alleen in releasebuilds; debugverzameling kan uitsluitend
  met de expliciete staging-proefvlag. Project-ID en Android-pakket worden ook
  tijdens de Gradle-build gecontroleerd.
- Google Analytics is in de Android-app gedeactiveerd. Geen chatinhoud,
  spelersnaam, account-ID, save, token, ruwe exception of correlation ID in
  aangepaste crashmeldingen/trace-attributen. Alleen vaste foutcategorieen en
  geschoonde bronlocaties; het native SDK verwerkt technische crashinformatie.
- Traces meten echte operatieduur, met begrensde aantallen en foutmeldingen.
  Meldingen bij dezelfde storing worden beperkt tot een per categorie per vijf minuten.
- Appmeldingsvoorkeuren en Android-toestemming gelden ook voor push. Registratie
  wordt vernieuwd bij tokenrotatie, hervatten, accountwissel en na verloop van tijd.
  Afmelden en verwijderen trekken de registratie in. Verloren verbindingen
  houden een begrensde retry en de bestaande inbox als vangnet.
- Periodiek verversen stopt op de achtergrond. Bij werkende push blijft een
  rustige inboxcontrole per minuut in de voorgrond beschikbaar.

## Server en sleutels

Migraties 50-51 bouwen een private apparaatregistratie, outbox, leases,
begrensde retries, verval en een dispatcher per minuut. Er wordt alleen een
HTTP-aanroep ingepland als er werk is, configuratie aanwezig is en push aanstaat.
Maximaal 45.000 geplande invocaties per kalendermaand; geen automatische upgrade.
De worker verstuurt maximaal 30 meldingen per batch met vijf gelijktijdige requests.
Firebase-acceptatie markeert de duurzame inbox nadrukkelijk niet als gelezen.

Productie blijft schema 49; staging is schema 51. Push staat op staging standaard
uit en de productie-economie blijft uit. De Edge worker en Vault-configuratie
zijn op staging ingericht. De productie-uitrol volgt pas na de complete apppoort.

De aparte serviceaccount per Firebase-project heeft een custom IAM-rol met alleen
`cloudmessaging.messages.create`. Sleutels blijven lokaal in genegeerde
`.tools/firebase-secrets` en voor staging in beschermde GitHub/Edge secrets.
De dispatchsleutel staat in Supabase Vault en het worker secret, nooit in de app.
Clientconfiguratie zit in het beschermde CI-secret
`DRAGONHAVEN_FIREBASE_ANDROID_CONFIG`; `tool/write_firebase_build_config.dart`
valideert deze voor de build. `tool/firebase_free_setup.py` kan de inrichting
herhalen met de officiele Firebase CLI-aanmelding, zonder billing te activeren.

## Bewijs

- Staging rollbackrepetitie 50-51:
  [34136004296](https://github.com/Rakky88/DragonHaven/actions/runs/34136004296).
- Staging apply/worker: schema 51, lint en health geslaagd, push bleef uit:
  [34136928567](https://github.com/Rakky88/DragonHaven/actions/runs/34136928567).
- Echte FCM-deviceproef via cron, Vault en Edge worker:
  [34137456672](https://github.com/Rakky88/DragonHaven/actions/runs/34137456672).
  Generiek Nederlands bericht zichtbaar op emulator-5554 terwijl de app op de
  achtergrond gesloten was. Serverinbox bleef ongelezen. Synthetisch account,
  apparaat, inbox en outbox zijn verwijderd; push terug uitgezet.
  Visueel bewijs: lokaal `release/firebase-staging-push.png`.
- Android-debugbuild zonder Firebase en met gevalideerde stagingconfig slagen.
- Dart-analyse schoon. De volledige Flutter-suite slaagt met 541 tests;
  aanvullende domein-/snapshotproeven en zes pushworker-unitproeven slagen.
- Echte native crash en niet-fatale Fluttermelding zijn via de officiele
  Crashlytics-report-API teruggevonden, elk met een event in het stagingproject.
  Issues `ece9690113b884780b157ecd849ebd37` (FATAL) en
  `33259915c98f8bd7649f741512bcdc04` (NON_FATAL), versie 0.5.18.
  De fatale testcrash toont de leesbare native methode. De eerste veilige
  Fluttermelding bevat opzettelijk alleen de vaste probe-categorie.
- Rick bevestigt op 7 september dat `dh_staging_probe` zichtbaar is in de
  Custom traces-tabel van het staging-Performance-dashboard. Dit sluit de
  dashboardcontrole, naast de eerdere lokale registratie van de trace.
- De echte Gradle-taak `:app:uploadCrashlyticsMappingFileRelease` is succesvol
  uitgevoerd met de gevalideerde stagingconfiguratie. Lokaal bewijs:
  `.tools/firebase-mapping-upload.log`, BUILD SUCCESSFUL (2 min 21 sec).
  De normale openbare app is teruggezet met behoud van opslag; tijdelijke
  probe-tokenbestanden zijn verwijderd en debuglogging is teruggezet naar INFO.

## Nog af te ronden binnen de opdracht

Alertinstellingen voor Rick, productie-uitrol van de geteste koppeling en
appreleasepoort. De volledige resterende servereconomie wordt apart verder
gebouwd; deze koppeling maakt die niet automatisch voltooid.

Gebruik `tool/firebase_staging_probe.dart` alleen met alle stagingdefinities.
Dit tijdelijke entrypoint opent geen gamesave en bevat een zichtbare knop voor
een gecontroleerde crash. Herstel daarna de normale app op het testtoestel.
