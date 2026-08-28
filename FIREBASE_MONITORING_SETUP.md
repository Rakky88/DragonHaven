# Firebase-monitoring voor DragonHaven

Besluit op 28 augustus 2026: begin gratis met Firebase Spark, Crashlytics en
Performance Monitoring; laat Google Analytics uit. Rick is de enige eerste
alertontvanger. De afgesproken Firebase-retentie geldt, DragonHaven-
supportexports blijven maximaal zeven dagen bewaard en privacyarm incidentbewijs
maximaal dertig dagen.

## Wat al zonder Firebase-config werkt

- De productie-Auth-healthcheck draait ieder uur via GitHub Actions.
- Een storing maakt één SEV-1 GitHub-issue aan en wijst die aan `Rakky88` toe;
  herstel sluit dezelfde melding automatisch.
- Online operaties gebruiken veilige foutcodes, correlation IDs en een begrensd
  lokaal supportrapport zonder e-mail, tokens of save-inhoud.
- De implementatie kan later een externe reporter krijgen zonder de Auth-,
  Friends-, trade-, Adventure- of back-upcode opnieuw te ontwerpen.

## Eenmalige stap die Rick in Firebase moet doen

1. Open <https://console.firebase.google.com/> met het account dat eigenaar van
   DragonHaven moet blijven.
2. Kies **Create a project** en maak bijvoorbeeld `DragonHaven Production`.
3. Laat **Google Analytics uitgeschakeld** en behoud het kosteloze **Spark**-
   abonnement zonder betaalmethode.
4. Kies in Project Overview **Add app → Android**.
5. Vul als Android package name exact `nl.dragonhaven.app` in. De bijnaam is
   vrij; een SHA-certificaat is voor Crashlytics/Performance niet vereist.
6. Download `google-services.json`. Zet dit bestand niet in chat. Plaats het
   rechtstreeks als `android/app/google-services.json` in de werkmap of geef
   aan dat het klaarstaat; Codex kan daarna de officiële FlutterFire-config,
   Crashlytics/Performance-SDK, release-symbolupload en testcrash afronden.
7. Open na de technische koppeling **Crashlytics → Alerts** en laat crashes en
   regressies naar Rick sturen. Maak voorlopig geen tweede ontvanger aan.

De Firebase-clientconfig identificeert het project maar verleent geen
beheertoegang. Service-accountkeys, databasewachtwoorden en toegangstokens horen
nooit in Git of chat. Analytics wordt alleen later toegevoegd na een apart
privacy- en Data Safety-besluit.
