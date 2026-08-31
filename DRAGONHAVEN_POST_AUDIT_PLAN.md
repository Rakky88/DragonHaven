# DragonHaven verbeterplan na audit v0.04.06

Laatst bijgewerkt: **31 augustus 2026**
Technische uitgangsversie: **v0.04.06**

Actuele openbare versie: **v0.05.00**

Actuele productieserver: **31/31 migraties**

Actuele lokale tranche: **v0.05.00 is openbaar uitgebracht met versionCode
10050. Friend Messages, Conclaves, de Supporter-correcties en exacte
Android-notificatietiming zijn groen op analyzer, 347/347 tests, de uitgebreide
staging-E2E, productiepreflight, twee signinggates en compacte/reduced-motion
emulatorcontrole. Migraties 30–31 staan gecontroleerd op productie; de
post-release healthcheck is groen. Daarna is de privacyveilige publieke
applicatiehealthcheck als migratie 32 voorbereid en volledig op geïsoleerde
staging bewezen, inclusief begrensde productieworkflow, klok-/contractvalidatie,
sociale E2E en 348/348 groene tests. Productie blijft bewust op 31/31 totdat
een nieuwe expliciete productiemigratietoestemming volgt.**

Bronnen: [DRAGONHAVEN_AUDIT_2026-08-28.md](DRAGONHAVEN_AUDIT_2026-08-28.md),
[SERVER_IMPROVEMENTS.md](SERVER_IMPROVEMENTS.md),
[DISTRIBUTION.md](DISTRIBUTION.md) en [PUBLIC_LAUNCH.md](PUBLIC_LAUNCH.md)

## Doel van dit document

Dit is de uitvoerbare roadmap voor de punten die na de audit nog openstaan. Het
document maakt per stap duidelijk:

- waarom de stap nodig is en welke andere stappen ervan afhangen;
- wat Codex kan ontwerpen, implementeren, testen en documenteren;
- wat jij in eigen accounts moet beslissen of configureren;
- wanneer de stap aantoonbaar klaar is;
- welke stappen een besloten test, openbare lancering of echte aankopen
  blokkeren.

Dit plan is een levende checklist. Bewijs, besluiten en uitvoeringsdatums horen
na iedere afgeronde stap in dit bestand te worden toegevoegd. Een toekomstige
release blijft aparte, expliciete toestemming vereisen.

## Actuele voortgang per onderdeel

Deze tabel is het korte voortgangsoverzicht. De percentages zijn alleen een
praktische richtwaarde voor de omvang van de mijlpaal; de checkboxes, tests en
bewijslinks verderop bepalen of iets werkelijk klaar is. Bij iedere audittranche
werkt Codex zowel deze tabel als het voortgangslog onderaan bij.

| Onderdeel | Voortgang | Aantoonbaar klaar | Nog door Codex | Nog door jou |
| --- | ---: | --- | --- | --- |
| Google Play-voorbereiding | circa 25% | Permanent package-ID, vaste signing-identiteit, versiecontrole en een ondertekende AAB zijn bewezen | Actuele Play-eisen opnieuw controleren; storeteksten, graphics, Data Safety-inventaris, appgrootte-analyse en rolloutchecklist maken | Play Console openen/verifiëren; app en Play App Signing aanmaken; testers, publieke support/privacy-URL's en storeverklaringen beheren |
| Fase 0 — releasepipeline en secrets | circa 95% | Zes productiesecrets, negen stagingsecrets, APK/AAB-gates, hash- en signingbewijs en openbare release v0.05.00 zijn groen; productie staat gecontroleerd op 31/31 migraties | Gates per release onderhouden en externe acties periodiek op runtime/security-updates controleren | Repositorytoegang periodiek controleren; originele keystore/recovery veilig dubbel bewaren; mogelijk blootgestelde ontwikkelcredentials roteren |
| Fase 1 — monitoring en incidenten | circa 80% | Privacyarme diagnostiek, correlation IDs, redactiontests, dashboardspecificatie en incidentrunbook bestaan; de productie-Auth-check draait elk uur. De read-only applicatiecheck, strikte contract-/klokvalidatie en migratie 32 zijn volledig op staging groen, inclusief 348/348 tests en bestaande sociale E2E | Migratie 32 na toestemming naar productie brengen; daarna de echte productiecheck en testalert bewijzen. Firebase Crashlytics/Performance koppelen zodra de Android-projectconfig bestaat | Gratis Firebase Spark-project maken, `nl.dragonhaven.app` registreren, Analytics uit laten en `google-services.json` veilig in de werkmap zetten; testalert ontvangen en privacy/Data Safety beoordelen |
| Fase 2 — staging en E2E | circa 86% | Afzonderlijke staging, migratiepariteit, account/login, back-up/conflict, Friends, Friend Messages, Conclaves, trade en volledige Group Adventure completion/reward/replay zijn echt getest | E-mailbevestiging automatiseren; realistisch 100-user en daarna 1.000-user loadprofiel meten | Veilige stagingmailroute instellen; bevestigen dat testaccounts geen echte persoonsgegevens zijn; testbudget boven 1.000 gebruikers vooraf goedkeuren |
| Fase 3 — back-up en multi-device | circa 97% | Optimistische revision lock, lokale recovery copy en conflictvenster bestaan; vijf revisies/dertig dagen, automatische 15-minutenback-up plus achtergrondflush en een echte staging-restoreroundtrip zijn bewezen | De eerste automatisch geplande zondagrun controleren; later server-owned velden van restores afschermen | Rick controleert maandelijks het restorebewijs; alleen bij een mislukking of overschrijding van RPO/RTO is een nieuw besluit nodig |
| Fase 4 — server-authoritative economie | circa 15% | Uitgeschakelde payment-providergrens en geauditeerde eenmalige save-import met limieten, hash, rapport en private herstelkopie bestaan | Wallet/ledger/itemtabellen, idempotente RPC's, serverrandomness, compatibiliteitsvenster en gefaseerde migratie van shops, chests, dragons en rewards bouwen | Migratievenster, spelerscommunicatie en gecontroleerd rollbackbeleid goedkeuren; compensatie- en storingsbeleid plus nooit-stil-afnemen-grenzen bevestigen |
| Fase 5 — Google Play Billing | circa 8%, bewust uitgesteld | Product-ID-contract voor valuta en het eenmalige Supporter Pack, idempotente lokale entitlementgrens en uitgeschakelde nepimplementatie houden de architectuur upgradebaar zonder nu kosten te maken | Pas na fase 4 de Billing-SDK, servervalidatie, acknowledgement, refunds/retries en Play-tracktests bouwen | Pas later beslissen wanneer verkoop actief mag worden; merchantprofiel, producten/prijzen/landen, service-identiteit, testers en beleid beheren |
| Fase 6 — support en privacy | circa 20% | Accountverwijdering, veilige supportdiagnostiek en eerste incidentprocedures bestaan | Minimaal supportzoekpad, procedures, least-privilege logging en consistente retentie/verwijdertests bouwen | Publiek supportadres, verantwoordelijken/reactietijden, privacy- en verwijderpagina, wettelijke retentie en productietoegang beheren |
| Fase 7 — capaciteit en rollout | circa 20% | Releasegate, serverpreflight, bewaard buildbewijs en dashboardontwerp bestaan | Eerst loadmetingen verzamelen; daarna query/indexverbeteringen, alarmgrenzen, compatibiliteitsgate en app/database-hotfixoefening bouwen | Capaciteit en budgetalerts op metingen kiezen; rolloutpercentages en pauze-/rollbackbevoegdheid per stap goedkeuren en bewaken |

De eerstvolgende afhankelijkheden die alleen jij kunt wegnemen zijn daarmee
zichtbaar zonder de lange checklist te lezen. Alles waarvoor geen externe
accountactie of productbesluit nodig is, blijft bij Codex staan en wordt gratis
of lokaal gebouwd waar dat verantwoord kan.

## Uitgerolde release v0.05.00

Deze tabel legt vast wat met de expliciet toegestane server- en releaseronde
aantoonbaar is uitgerold en welke niet-blokkerende vervolgpunten nog bestaan.

| Onderdeel | Aantoonbaar uitgerold | Nog door Codex | Nog door jou |
| --- | --- | --- | --- |
| Friend Messages | Vriend-naar-vriendchat, 24-uursweergave, ontvangen toestaan/weigeren, aparte notificatiecategorie, logische deep-link, ongelezen teller, lichte chatpoll en server-side friendship/rate-limitcontrole. De staging-E2E bewijst sturen, ongelezen projectie, lezen en opt-out. | Praktijkgebruik en rate-limittelemetrie blijven volgen; er staat geen releaseblokkade open | Alleen later feedback geven over chat-UX of gewenste limieten |
| Conclaves | 4–20 leden, Public/Request/Invite Only, Flightmaster/Warden/Keeper, 20 emblemen, unieke permanente naam, chat en deelkaarten, Conclave Chronicle, achievement-opt-in, dagelijkse Aerie-bijdrage, 50 levels en 10 Aerie-fasen. De staging-E2E bewijst naamnormalisatie, join, Warden, chat, bijdrage en cleanup. | Balans en schaalgedrag later met echte groepen meten; er staat geen releaseblokkade open | Gewenste Conclave-balans na praktijktest beoordelen |
| Sociale sprites en lokalisatie | Eén eigen berichtenicoon, 20 afzonderlijke emblemen en 10 Aerie-sprites met echte alpha en veiligheidsmarges; alle vaste nieuwe UI-teksten bestaan in acht ondersteunde talen. De productie-APK is op een compacte emulator en met reduced motion gecontroleerd. | Eventuele grotere-tabletpolish meenemen bij een latere visuele tranche | Alleen visuele feedback geven als je later een andere stijl of balans wilt |
| Serverveiligheid | Migraties 30–31 staan op productie. Directe tabeltoegang is ingetrokken, RLS en afgeschermde RPC's vormen de grens, row locks bewaken capaciteit, de dagledger begrenst Aerie-groei en tijdelijke chatdata heeft vijfminuten-cleanup. Database-lint meldt 0 fouten en Auth health/settings geven 200/200. | Reguliere healthchecks, restorebewijzen en dependencyonderhoud blijven uitvoeren | Geen aanvullende configuratie nodig |

De grootste Aerie-fase begint bij level 46. Met 850 XP per level, maximaal
twintig bijdragen van 10 XP per UTC-dag en een duurzame dagledger zijn daarvoor
minimaal `ceil(45 × 850 / 200) = 192` dagen nodig, ook wanneer leden worden
gewisseld.

## Beoogd einddoel: eerst gratis naar Google Play

Het concrete publicatiedoel is een officiële DragonHaven-release in de
**Google Play Store**. De eerste storeversie kan gratis en zonder in-app
aankopen verschijnen. Betalingen zijn geen voorwaarde voor publicatie en blijven
de uitgestelde, optionele fase 5.

Alle technische keuzes in dit plan moeten daarom verenigbaar blijven met:

- het permanente Android application ID `nl.dragonhaven.app`;
- dezelfde veilig bewaarde release-key en later Play App Signing;
- een door Google Play geaccepteerde, ondertekende Android App Bundle (`.aab`);
- correcte versionName/versionCode-verhogingen en updatecompatibiliteit;
- de op het publicatiemoment vereiste Android target API en actuele
  Play-beleidsregels;
- interne/gesloten testtracks en daarna een gecontroleerde productierollout;
- een store listing, icoon, feature graphic, screenshots en supportcontact;
- een openbare privacyverklaring en accountverwijderpagina;
- eerlijke Data Safety-, doelgroep-, content-rating-, advertentie- en
  app-accessverklaringen;
- beheersbare downloadgrootte en controle op echte Android-toestellen;
- een werkende serverpreflight, monitoring, herstelplan en supportproces.

### Wat Codex voor Google Play voorbereidt

- [x] De release-AAB bouwen en package name, versie, signingcertificaat en hash
  controleren.
- [ ] De CI/releasegate onderhouden en vóór iedere storebuild de actuele Play-
  en target-API-eisen opnieuw controleren.
- [ ] Storeteksten, testnotities, screenshots, feature graphic en technische
  Data Safety-inventaris als concept voorbereiden.
- [ ] Privacy- en accountverwijderlinks technisch in app en website integreren
  zodra jij domein/hosting en definitieve teksten hebt gekozen.
- [ ] Appgrootte, assets en dependencies analyseren en optimaliseren waar dit
  zonder merkbaar kwaliteitsverlies kan.
- [ ] Problemen uit interne/gesloten tests oplossen en een staged-rollout- en
  rollbackchecklist opleveren.

### Wat jij voor Google Play moet regelen

- [ ] Een Play Console-account openen, eventuele registratiekosten betalen,
  voorwaarden accepteren en identiteit/organisatie verifiëren.
- [ ] DragonHaven in Play Console aanmaken en Play App Signing configureren.
- [ ] De vereiste testers uitnodigen en de testperiode doorlopen die jouw
  actuele account/Console voorschrijft.
- [ ] Definitieve store-, privacy-, doelgroep-, content-rating-, Data Safety-
  en landenverklaringen onder jouw verantwoordelijkheid indienen.
- [ ] Een publiek supportadres, privacy-URL en accountverwijder-URL beheren.
- [ ] De storebuild uploaden, test-/productietrack kiezen en iedere uitrol
  expliciet goedkeuren.

De uitgebreide, levende storechecklist staat in
[PUBLIC_LAUNCH.md](PUBLIC_LAUNCH.md). Vlak vóór indiening moeten de daarin
genoemde externe eisen opnieuw tegen de actuele officiële Google Play-
documentatie worden gecontroleerd; storebeleid kan veranderen.

## Rollen en veilige samenwerking

### Wat Codex doet

Codex kan binnen de repository:

- Flutter-code, Supabase-migraties, server-RPC's en Row Level Security maken;
- unit-, widget-, integratie-, migratie-, herstel- en loadtests toevoegen;
- GitHub Actions, releasepreflights, dashboardspecificaties en runbooks maken;
- logging en monitoring technisch koppelen en gevoelige velden redigeren;
- builds, versies, handtekeningen en release-artifacts controleren;
- privacy-, support-, store- en technische documentatie als concept opstellen;
- na jouw expliciete toestemming migraties toepassen en een release publiceren.

### Wat jij doet

Alleen jij kunt of moet:

- externe accounts openen, betalen, voorwaarden accepteren en identiteit of
  organisatie verifiëren;
- product-, privacy-, doelgroep-, bewaartermijn- en verdienmodelbesluiten nemen;
- productie- en stagingprojecten aanmaken en eigenaar daarvan blijven;
- secrets rechtstreeks in GitHub, Supabase, Firebase of Google Play invoeren;
- toegang, alertontvangers, budgetten en supportverantwoordelijkheid beheren;
- testers uitnodigen en storeverklaringen onder jouw naam indienen;
- iedere productiemigratie en release expliciet autoriseren.

De Android-keystore, databasewachtwoorden, service-role keys, access tokens en
merchantgegevens mogen nooit in Git, dit document of een chatbericht worden
geplaatst. Codex heeft de geheime waarden niet nodig wanneer jij ze rechtstreeks
in de daarvoor bedoelde secret store zet.

### Wat we samen doen

Voor iedere fase bevestigen we eerst de productkeuzes. Codex voert daarna het
technische werk uit en levert het bewijs. Jij controleert het zichtbare gedrag
op een echt toestel en neemt besluiten die gevolgen hebben voor spelers,
privacy, geld of externe diensten.

## Kosten- en bouwbeleid: eerst gratis, zoveel mogelijk door Codex

Voor alle fasen geldt standaard een **free-first** aanpak:

- Codex bouwt zoveel mogelijk zelf in de bestaande Flutter-, Supabase-, GitHub-
  en documentatieomgeving: tests, scripts, dashboardspecificaties,
  healthchecks, supporttools, migraties, server-RPC's, runbooks en rapportages.
- We gebruiken eerst bestaande gratis mogelijkheden en actuele free tiers,
  zolang die veilig, juridisch passend en voldoende betrouwbaar zijn.
- Een betaalde dienst, upgrade of abonnement wordt pas onderdeel van de
  uitvoering wanneer een gratis oplossing aantoonbaar tekortschiet in
  capaciteit, betrouwbaarheid, beveiliging of storevereisten.
- Codex beschrijft vóór zo'n overstap de gratis optie, beperking, betaalde
  optie, verwachte meerwaarde en eventuele migratiemogelijkheid. Jij neemt het
  kostenbesluit en activeert de betaalde dienst zelf.
- Nieuwe onderdelen worden waar praktisch provider-onafhankelijk gebouwd,
  zodat monitoring, e-mail of hosting later kan worden vervangen zonder de
  hele app opnieuw te bouwen.
- We bouwen beveiligingskritieke infrastructuur niet onnodig zelf. Auth,
  betalingstransport, e-mailbezorging en store-receiptcontrole blijven steunen
  op daarvoor bedoelde platformdiensten; Codex bouwt de veilige integratie,
  validatie en eigen spelregels daaromheen.
- Google Play-accountkosten, een eigen domein, eventuele productie-e-mail en
  verbruik boven free-tierlimieten kunnen uiteindelijk niet technisch worden
  weggeprogrammeerd. Zulke kosten worden nooit zonder jouw expliciete keuze
  geactiveerd.
- Echte betalingen worden zo lang mogelijk uitgesteld. Nieuwe economiecode
  wordt wel **payment-ready** ontworpen: duidelijke wallet- en ledgergrenzen,
  stabiele product-ID-koppelingen, idempotente servercommando's, feature flags
  en een vervangbare aankoopprovider. Daardoor kan Billing later worden
  toegevoegd zonder inventory, shops of saves opnieuw te ontwerpen.
- We koppelen nog geen live betaalprovider en maken nog geen verkoopproducten
  actief alleen om de architectuur te testen. De servereconomie krijgt eerst
  tests met een nep-/sandboxprovider. De echte store-integratie volgt pas vlak
  voordat verkoop daadwerkelijk gewenst is, zodat we geen vroege kosten dragen
  of inmiddels verouderde Billing-code langdurig hoeven te onderhouden.

Per mijlpaal rapporteert Codex daarom ook: **huidige kosten**, **verwachte
free-tiergrens**, **signaal om op te schalen** en **goedkopere terugvaloptie**.

## Huidige veilige basis

Deze auditpunten zijn al gerealiseerd en moeten als regressie-eis blijven
bestaan:

- [x] Lokale gameplay blokkeert niet meer op de eerste online refresh.
- [x] De timeout is na gemeten free-tier cold starts verhoogd naar 75 seconden;
  lokale gameplay en navigatie blijven tijdens die online wachttijd beschikbaar.
- [x] Nieuwe accounts tonen e-mailbevestiging en kunnen opnieuw verzenden.
- [x] Trades zijn server-authoritative en gebruiken atomaire reserveringen.
- [x] Chronoshard-variantdata blijft exact behouden in serverinventaris/trades.
- [x] Music-, Portrait- en Title Chests, shop-relics en Twinstar worden
  server-side uit trades geweerd.
- [x] Cloudback-ups gebruiken revisies en lokale herstelkopieën.
- [x] De verplichte Supabase-preflight controleert migration parity, database
  lint, Auth-health/settings en e-mailauth.
- [x] v0.04.06 is geanalyseerd, met 243 tests gecontroleerd en als ondertekende
  APK gepubliceerd.

Bij iedere wijziging aan Auth, trades, relics, inventory, back-ups of releases
moeten de bestaande tests voor deze punten blijven slagen.

## Besluiten die vóór groot ontwikkelwerk nodig zijn

| ID | Besluit van jou | Aanbevolen startpunt | Blokkeert |
| --- | --- | --- | --- |
| B1 | Moet de kernprogressie volledig offline blijven werken? | Lokale weergave mag offline; waardevolle claims en mutaties vereisen verbinding zodra de economie server-authoritative wordt. | Servereconomie |
| B2 | Hoe gaan bestaande saves naar de serverwaarheid? | Eenmalige, gelogde import met limieten en daarna server-lock; nooit stil bestaande voortgang verwijderen. | Servereconomie |
| B3 | Wat gebeurt bij twee apparaten met verschillende saves? | Eerst een expliciet conflictvenster met keuze en herstelkopieën; geen automatische veld-voor-veld-merge in de eerste versie. | Back-up/multi-device |
| B4 | Wanneer mag echte verkoop van gems worden geactiveerd? | Zo laat mogelijk: houd packs uitgeschakeld, bouw de economie nu payment-ready en koppel Billing pas wanneer verkoop echt gewenst is én economie en receiptvalidatie klaar zijn. | Google Play Billing |
| B5 | Welke monitoringstack en wie krijgt alerts? | Begin met de gratis mogelijkheden van Firebase/Supabase/GitHub en een door Codex gebouwde healthcheck; voeg pas een betaalde dienst toe als metingen de noodzaak bewijzen. | Observability |
| B6 | Welke bewaartermijnen gelden voor back-ups, auditlogs en supportdata? | Kies expliciete termijnen vóórdat extra productiegegevens worden opgeslagen. | Back-up, logging, privacy |
| B7 | Welke schaal is de eerste openbare doelgroep? | Begin met een kleine staged rollout en schaal alleen op gemeten gedrag. | Loadtest en capaciteit |

Codex legt ieder besluit na bevestiging vast in de sectie **Besluitenlog** onderaan.

### Concrete keuzehulp voor monitoring (B5)

De aanbevolen kosteloze begininstelling is:

- Firebase [**Spark**](https://firebase.google.com/docs/projects/billing/firebase-pricing-plans)
  zonder betaalmethode, alleen Crashlytics en Performance
  Monitoring; Google Analytics blijft aanvankelijk uit voor minder dataverzameling;
- Rick ontvangt SEV-1/SEV-2 crash- en bereikbaarheidsalerts direct per e-mail;
  niet-kritieke trends worden tijdens testweken eenmaal per dag bekeken;
- geen extra beheerder totdat er een concrete tweede support-/releasebeheerder is;
- Crashlytics en Performance zijn wereldwijde diensten zonder eigen vaste
  DragonHaven-regiokeuze. Als Analytics later nodig is, wordt Nederland als
  rapportageregio gekozen;
- de officiële [Firebase-retentie](https://firebase.google.com/support/privacy)
  accepteren: Crashlytics circa negentig dagen, Performance
  circa dertig dagen voor IP-gekoppelde events en zestig dagen voor installatie-
  gekoppelde/geanonimiseerde performancegegevens;
- privacyarme DragonHaven-supportexports maximaal zeven dagen bewaren en
  incidentbewijs zonder persoonsgegevens maximaal dertig dagen.

Bevestigd op 28 augustus 2026: Spark plus Crashlytics/Performance, Analytics
uit, Rick als enige eerste alertontvanger en bovenstaande termijnen. De gratis
GitHub-healthalert is gebouwd. De Android-SDK-koppeling wacht alleen nog op het
door Rick aangemaakte Firebase-project en `google-services.json`; exacte stappen
staan in `FIREBASE_MONITORING_SETUP.md`.

### Concrete keuzehulp voor back-up en herstel (B6)

De al bevestigde servergrens is vijf revisies en maximaal dertig dagen. Voor de
resterende keuzes is het aanbevolen startpunt:

- handmatige back-up blijft beschikbaar; daarnaast automatisch na een
  betekenisvolle voortgangsmutatie, maximaal eenmaal per vijftien minuten en
  alleen ingelogd wanneer geen conflict of upload actief is;
- ook proberen bij veilig naar achtergrond gaan; offline wijzigingen wachten
  zonder gameplay te blokkeren tot de volgende verbinding;
- **RPO:** maximaal vijftien minuten online voortgang sinds de laatste geslaagde
  automatische back-up; offline is het verliesvenster noodgedwongen tot de
  eerstvolgende verbinding;
- **RTO:** een speler kan een van de vijf revisies binnen vijftien minuten zelf
  herstellen; een supportherstel heeft als eerste doel vier uur tijdens
  beschikbare supporturen;
- wekelijks een geautomatiseerde restore-integriteitstest op staging en
  maandelijks handmatig bewijs controleren; Rick is in eerste instantie de
  menselijke controle-eigenaar.

Bevestigd op 28 augustus 2026: automatische back-up met vijftienminutengrens,
bovenstaande RPO/RTO en Rick als maandelijkse controle-eigenaar. De automatische
trigger en wekelijkse stagingtest zijn gebouwd; de eerste geplande workflowrun
moet na opname op `main` nog bewijs leveren.

## Prioriteiten en releasepoorten

- **P0 — eerst:** releasepipeline, observability en aparte staging.
- **P1 — vóór brede publieke lancering:** multi-device veiligheid,
  server-authoritative economie, supportdiagnostiek en realistische loadtests.
- **P1 voor betalingen:** Google Play Billing plus server-side
  receiptvalidatie; zonder dit blijven echte aankopen uitgeschakeld.
- **P2 — daarna:** operationele verfijning, automatische capaciteitsrapportage
  en verdere schaaloptimalisatie.

Een besloten test kan met de huidige offline-first grens doorgaan. Een brede
publieke lancering hoort niet door te gaan zolang P0 niet klaar is en de
offline-economierisico's niet expliciet zijn opgelost of geaccepteerd. Echte
gemverkoop mag nooit worden aangezet vóór fase 5 volledig slaagt.

## Fase 0 — releasepipeline en eigendom van secrets

**Prioriteit:** P0  
**Omvang:** klein  
**Reden:** de v0.04.06-tagworkflow kon de tijdelijke Play Store-AAB niet bouwen
omdat de GitHub-repository geen Supabase- en signingsecrets bevatte. De lokale
APK en productiepreflight waren wel geldig.

### Codex

- [x] Voeg een afzonderlijke handmatig startbare pipelinecontrole toe die
  ontbrekende secretnamen vroeg en zonder waarden te loggen meldt.
- [x] Controleer dat de CI-AAB dezelfde package name en signingcertificaat-
  fingerprint gebruikt als de gepubliceerde APK.
- [x] Laat een succesvolle workflow de versie, versionCode, commit, AAB-hash,
  migratie-uitkomst en certificaatfingerprint als verificatierapport bewaren.
- [x] Documenteer herstel bij een mislukte serverpreflight of signingcheck.

### Jij

- [x] Plaats rechtstreeks in GitHub Actions Secrets:
  `DRAGONHAVEN_KEYSTORE_BASE64`, `DRAGONHAVEN_KEYSTORE_PASSWORD`,
  `DRAGONHAVEN_KEY_ALIAS`, `DRAGONHAVEN_KEY_PASSWORD`,
  `SUPABASE_ACCESS_TOKEN` en `SUPABASE_DB_PASSWORD`.
- [ ] Controleer dat alleen noodzakelijke beheerders repository- en
  secrettoegang hebben.
- [ ] Bewaar de originele keystore en recovery-informatie op minimaal twee
  versleutelde, afzonderlijke locaties.
- [ ] Roteer productiecredentials die tijdens ontwikkeling mogelijk buiten de
  bedoelde secret store zijn gebruikt.

### Samen klaar wanneer

- [x] Een handmatige CI-run analyse, alle tests, serverpreflight en een
  ondertekende `DragonHaven.aab` volledig groen afrondt.
- [x] Het signingcertificaat exact overeenkomt met bestaande DragonHaven-
  releases en geen secretwaarde in logs of artifacts staat.
- [x] Het verificatierapport aan de run gekoppeld is.

Bewijs: handmatige GitHub Actions-run
[`33177281257`](https://github.com/Rakky88/DragonHaven/actions/runs/33177281257)
bouwde zonder publicatie versie `0.04.06` (`versionCode 10039`) met commit
`ade9b71939ee642290374a927f2d5f6df3935491`. De AAB-hash was
`C68D448229800BF6663E3CB33EC297032D6D3DA94B3E146B66D4F2B691C21C5E` en de
signingfingerprint kwam overeen met
`477C5A5D7453384CA756265E77AF97D5A002A907177CCD2D9065A9BEC3414942`.
Het tijdelijke bewijsartifact verloopt op 04-09-2026; de run en dit plan
bewaren de controle-uitkomst blijvend.

## Fase 1 — observability, alerts en incidentbasis

**Prioriteit:** P0  
**Omvang:** middelgroot  
**Afhankelijk van:** B5 en B6

### Codex

- [ ] Koppel crash- en performance-monitoring met buildversie, platform en een
  willekeurige technische installatie-ID; log geen wachtwoorden, tokens,
  volledige saves, e-mailadressen of zichtbare keepernamen.
- [x] Voeg veilige request/correlation IDs toe aan Auth-, backup-, Friends-,
  Trade- en Group Adventure-paden.
- [x] Maak dashboards of dashboardspecificaties voor
  (`OBSERVABILITY_BASELINE.md`):
  - Auth-foutpercentage, verificatie en loginlatency;
  - RPC-foutpercentage en p50/p95/p99-latency;
  - trade- en Group Adventure-fouten;
  - databaseverbindingen, CPU, opslag en egress;
  - back-upsuccessen, revision conflicts en restore-uitkomsten;
  - actieve appversies en client/servercompatibiliteit.
- [x] Voeg synthetische healthchecks toe voor publieke Auth.
- [ ] Activeer de veilige, read-only applicatiecheck. Migratie 32, de
  privacyvrije RPC, parsertests, workflowintegratie en exact begrensde
  productiemigratie zijn klaar en op staging bewezen; alleen productieactivatie
  en de daaropvolgende testalert wachten nog.
- [x] Schrijf een incidentrunbook met ernstniveaus, triage, rollback,
  communicatie en controle na herstel.
- [x] Voeg tests toe die bewijzen dat gevoelige data wordt geredigeerd.

### Jij

- [ ] Maak en bezit het gekozen monitoring/Firebase-project en registreer
  `nl.dragonhaven.app`.
- [x] Kies in eerste instantie het gratis plan en zet budgetmeldingen aan waar
  de provider dat ondersteunt; een upgrade vereist een apart besluit.
- [x] Kies wie waarschuwingen ontvangt, tijdens welke uren en via welk kanaal.
- [x] Stel maandbudget, datalocatie en bewaartermijn in.
- [ ] Beoordeel of diagnostische gegevens en toestemming in de
  privacyverklaring/Data Safety moeten worden aangepast.
- [ ] Geef alleen projectconfiguratie via veilige configuratie of secret stores;
  deel geen beheer- of servicecredentials in de app.

### Samen klaar wanneer

- [ ] Een gecontroleerde stagingfout binnen de afgesproken tijd zichtbaar is
  met versie en correlation ID, zonder persoonsgegevens of secrets.
- [ ] Een testalert aankomt bij de juiste ontvanger en het runbook naar de
  oorzaak en herstelactie leidt.
- [ ] Er gedurende minimaal één testperiode een bruikbare latency- en
  foutbaseline is vastgelegd voordat vaste alarmdrempels worden gekozen.

## Fase 2 — gescheiden staging, end-to-endtests en belastingtests

**Prioriteit:** P0  
**Omvang:** groot  
**Afhankelijk van:** fase 0 en bij voorkeur fase 1

### Codex

- [x] Maak omgevinggestuurde configuratie voor lokaal, staging en productie,
  zonder productiecredentials in testbuilds.
- [x] Laat lokale tests en GitHub Actions zoveel mogelijk werk afvangen voordat
  een externe stagingresource wordt belast.
- [x] Maak reproduceerbare stagingmigraties en veilige tweepersoons-testdata met
  opruimlogica voor Friends, trades en Group Adventure-wachtlobby's.
- [ ] Automatiseer minimaal deze volledige flow:
  1. [x] signup en bevestigingsmail aanvragen;
  2. [ ] e-mailbevestiging volledig automatiseren — de eerste staginglink is
     veilig handmatig bevestigd zonder mailboxwachtwoord te delen;
  3. [x] eerste login en idempotente accountbootstrap;
  4. [x] cloudback-up, restore en weigering van een verouderde revisie;
  5. [x] Friends request en acceptatie;
  6. [x] trade reserveren, accepteren, afronden en inventarisbehoud bewijzen;
  7. [x] Group Adventure aanmaken, lijsten, deelnemen en veilig verlaten;
  8. [x] Group Adventure starten, afronden en reward-idempotentie bewijzen.
- [x] Voeg scenario's toe voor timeout, offline/online wissel, verlopen sessie,
  dubbele request, appherstart en een halverwege mislukte actie.
- [ ] Maak een loadtestprofiel dat snapshotpolling en echte gebruikersacties
  combineert; geen onrealistische constante spam.
- [ ] Laat de test eerst op 100 en daarna 1.000 gelijktijdige synthetische
  gebruikers draaien. Test 5.000–10.000 pas na kosten- en capaciteitsgoedkeuring.
- [ ] Rapporteer p95/p99, foutpercentages, databasebelasting, verbindingen,
  egress en gevonden query/indexproblemen.

### Jij

- [x] Maak een afzonderlijk Supabase-stagingproject onder jouw account.
- [x] Start daarvoor met de gratis tier zolang de geplande tests binnen de
  actuele limieten passen.
- [ ] Configureer een staging-e-mailroute/inbox waarmee bevestigingslinks veilig
  geautomatiseerd kunnen worden.
- [x] Richt afzonderlijke stagingaliases in en bevestig beide testaccounts
  zonder het mailboxwachtwoord met Codex te delen.
- [x] Voeg stagingcredentials rechtstreeks als afgeschermde GitHub Environment
  Secrets toe en vereis zo nodig jouw goedkeuring voor runs.

De eerste geïsoleerde stagingrun
[`33176572637`](https://github.com/Rakky88/DragonHaven/actions/runs/33176572637)
is volledig geslaagd: secret- en production-safetychecks, 20 migraties,
Auth/configuratie, schemalint, publieke serverpreflight, analyzer, 252 tests,
APK-build en artifactupload waren groen. Dit was het bewijs voor de publieke
stagingbasis, nog zonder ingelogde sociale acties.

De bevestigde-accountworkflow
[`33180648232`](https://github.com/Rakky88/DragonHaven/actions/runs/33180648232)
is daarna volledig geslaagd. Hij bewees echte password-login met bevestigde
e-mail, idempotente accountbootstrap, profielread, cloud-back-up en restore,
weigering van een stale revisie en het intrekken van de testsessie. Daarna
slaagden analyzer, alle 252 tests, staging-APK en artifactupload opnieuw. De
workflow bewaart geen e-mailadres, wachtwoord, token of user-id in het rapport.

Na bevestiging van het tweede testaccount slaagde de sociale workflow
[`33182884493`](https://github.com/Rakky88/DragonHaven/actions/runs/33182884493)
volledig. De run bewees Friends request/acceptatie en wederzijdse zichtbaarheid,
een atomaire Wooden Chest-ruil met inventarisbehoud, plus Group Adventure
aanmaken/lijsten/deelnemen/verlaten. Tijdelijke vriendschap, trade en wachtlobby
zijn veilig opgeruimd en beide sessies ingetrokken. Analyzer, alle 252 tests,
staging-APK en het bewijsartifact waren opnieuw groen. De workflow bewaart ook
hierbij geen e-mailadres, wachtwoord, token, keepercode of user-id.

Na expliciete toestemming voor een staging-only tijdregeling slaagde ook
[run 33196707499](https://github.com/Rakky88/DragonHaven/actions/runs/33196707499).
De afgeschermde workflow weigerde het productieproject hard, normaliseerde
uitsluitend de tijdelijke synthetische lobby naar de twee beschikbare accounts,
startte vervolgens via de gewone server-RPC en liet alleen de eindtijd verlopen.
Beide deelnemers ontvingen dezelfde serverreward, een tweede acknowledgement
voegde niets toe en de fixture plus testreward zijn weer opgeruimd. Analyzer,
260 tests, staging-APK en bewijsartifact waren groen.

- [ ] Bepaal het testbudget en keur iedere test boven 1.000 gelijktijdige
  gebruikers vooraf goed.
- [ ] Bevestig dat synthetische accounts en testmailadressen geen echte
  persoonsgegevens bevatten.

### Samen klaar wanneer

- [ ] De volledige flow herhaalbaar slaagt op een lege stagingdatabase.
- [x] Een migratie vanaf de vorige productieschemaversie ook slaagt.
- [x] Foutscenario's geen dubbele reward, item, trade of Group Adventure
  veroorzaken.
- [ ] De afgesproken belastingdoelstelling binnen vastgelegde fout- en
  latencygrenzen blijft en productie nooit door de test wordt belast.

## Fase 3 — cloudback-up, restore en multi-device conflicten

**Prioriteit:** P1  
**Omvang:** groot  
**Afhankelijk van:** B3, B6 en fase 2

### Aanbevolen productmodel

Gebruik eerst optimistische revisievergrendeling. Als apparaat A en B vanaf
dezelfde cloudrevision uiteenlopen, mag het tweede apparaat niet stil het eerste
overschrijven. Toon datum, apparaat, revision en een veilige voortgangssamenvatting
en laat de speler expliciet kiezen. Maak vóór iedere keuze een lokale
herstelkopie. Een automatische merge komt pas later, per datadomein, nadat de
economie server-authoritative is.

### Codex

- [x] Breid back-ups uit met save-ID, parent revision, apparaat-ID,
  clientversie, schema-versie en servertijd.
- [x] Laat de server een verouderde `expectedRevision` atomair weigeren en
  retourneer een specifiek conflict in plaats van een algemene fout.
- [x] Bouw een conflictvenster met drie veilige acties: cloud bekijken,
  huidige lokale staat behouden/uploaden na bevestiging, of cloud herstellen.
- [x] Houd een beperkt aantal herstelbare serverrevisies bij volgens de gekozen
  bewaartermijn.
- [ ] Splits later server-owned economievelden af zodat een oude save nooit
  valuta of items kan terugzetten of dupliceren.
- [x] Maak automatische integratietests met twee apparaten en overlappende
  uploads/restores.
- [x] Voeg een periodieke restore-test en controle op save-integriteit toe.

Implementatiebewijs: migraties
`202608280022_cloud_save_revision_history.sql` en
`202608280023_fix_cloud_save_history_conflict_target.sql` bewaren de huidige
plus vier vorige revisies, verwijderen eerdere revisies per account, verwijderen
fysiek alle historie ouder dan dertig dagen via een dagelijkse databasejob en
houden directe tabeltoegang gesloten. De app toont de revisiegeschiedenis met
save-ID, parent revision, apparaat, appversie, saveschema en servertijd. Een
oude revisie herstellen bewaart eerst lokaal herstel; expliciet **Cloud
vervangen** vereist een tweede bevestiging en laat de vorige serverkopie in de
herstelgeschiedenis staan. Unit/integratietests simuleren overlappende apparaten,
stale writes, oudere restore en daarna veilig doorback-uppen.

### Jij

- [x] Kies bewaartermijn en aantal herstelrevisies.
- [x] Kies of back-up handmatig blijft of ook automatisch op veilige momenten
  gebeurt.
- [ ] Bevestig de conflictteksten en welke voortgangssamenvatting voor spelers
  begrijpelijk is.
- [x] Kies RPO en RTO: hoeveel voortgang maximaal verloren mag gaan en binnen
  welke tijd herstel mogelijk moet zijn.
- [x] Wijs iemand aan die periodieke restore-resultaten controleert.

### Samen klaar wanneer

- [ ] Twee apparaten nooit ongemerkt elkaars voortgang overschrijven.
- [ ] Iedere restore een recovery copy achterlaat en server-owned waarde niet
  kan terugdraaien of verdubbelen.
- [ ] Een echte stagingrestore volgens het runbook slaagt en de gemeten
  hersteltijd is vastgelegd.

## Fase 4 — server-authoritative economie

**Prioriteit:** P1 en verplicht vóór echte aankopen  
**Omvang:** extra groot; uitvoeren in meerdere compatibele releases  
**Afhankelijk van:** B1, B2, B6, fase 1–3

### Vaste technische regels

Iedere waardevolle actie gebruikt een ingelogde server-RPC met een unieke
idempotency key. De server controleert ownership en limieten, rolt randomness
op de server en schrijft resultaat plus auditregel in één transactie. Een
herhaalde request retourneert exact hetzelfde resultaat. De client animeert
alleen het serverresultaat en bezit nooit een service-role key.

### Deel 4A — fundament en migratie

#### Codex

- [ ] Ontwerp servertabellen voor wallet, item/egg/chest instances, dragons,
  rewardclaims, idempotency records en een append-only economy auditlog.
- [ ] Maak in wallet/ledger onderscheid tussen bron en mutatietype, zodat later
  een gevalideerde storeaankoop kan worden toegevoegd zonder huidige balances
  of saves te migreren; sla nog geen onnodige betaalgegevens op.
- [x] Definieer een kleine aankoopprovider-interface en uitgeschakelde
  nepimplementatie voor tests. De echte Google Play-implementatie blijft uit.
- [ ] Koppel de provider later pas via een feature flag aan de zichtbare shop,
  nadat de serverwallet en receiptvalidatie bestaan.
- [ ] Voeg constraints, RLS, rate limits en serverfuncties toe.
- [ ] Rond het versieerbare eenmalige importpad af. Protocol/saveversie,
  validatie, plausibiliteitslimieten, privacyarme rapportage, SHA-256-bewijs,
  server-lock en een private herstelkopie van dertig dagen zijn gebouwd;
  migratie en rapportcoherentie zijn op staging bewezen. Gecontroleerde
  rollbackuitvoering blijft open.
- [ ] Maak een compatibiliteitsvenster zodat oude clients geen ongeldige nieuwe
  mutaties kunnen doen.

#### Jij

- [ ] Kies het importbeleid voor bestaande spelers: volledig vertrouwen,
  plausibiliteitslimieten of handmatige beoordeling bij uitzonderingen.
- [ ] Bevestig welke voortgang nooit mag worden afgenomen zonder menselijke
  controle.
- [ ] Keur migratievenster, spelerscommunicatie en rollbackbeleid goed.

### Deel 4B — valuta, shops en chests

#### Codex

- [ ] Verplaats coin/gemmutaties, shopaankopen, chestownership, chestopening,
  pity, collection caps en relicdrops naar atomaire RPC's.
- [ ] Laat alle random rolls en collection checks op de server plaatsvinden.
- [ ] Test replay, dubbele taps, timeouts, reconnects en aangepaste clients.

#### Jij

- [ ] Bevestig economieprijzen, compensatiebeleid bij fouten en of er een
  onderscheid tussen verdiende en gekochte gems nodig is.

### Deel 4C — eggs, dragons, relics en progressie

#### Codex

- [ ] Verplaats eggtoekenning/incubatie/hatch, dragonownership, XP, levels,
  evolution, expertise en economisch relevante achievements naar de server.
- [ ] Bewaar Chronoshard-percentage en Twinstar-equip atomair en uniek.
- [ ] Voorkom dat een oude cloudsave een uitgebroed ei of verbruikte relic
  terugbrengt.

#### Jij

- [ ] Beslis welk spelgedrag tijdens een serverstoring alleen bekeken mag worden
  en welke acties later in een wachtrij mogen.

### Deel 4D — rewards en dagelijkse limieten

#### Codex

- [ ] Verplaats Adventure-, Trial-, minigame-, achievement- en dagelijkse
  claims naar servergestuurde, eenmalige rewardrecords.
- [ ] Laat de server claimtijd, daggrens en relevante scorebewijsgegevens
  valideren.
- [ ] Voeg misbruikdetectie toe voor onmogelijke frequenties, replays en
  afwijkende rewardpatronen zonder automatisch legitieme spelers te straffen.

#### Jij

- [ ] Bepaal wanneer een afwijking alleen wordt gelogd, tijdelijk wordt
  geblokkeerd of door support wordt beoordeeld.

### Samen klaar wanneer

- [ ] Een aangepaste of oude client geen coins, gems, items, dragons of rewards
  kan creëren, verdubbelen of terugzetten.
- [ ] Alle dubbele/vertraagde requests idempotent zijn.
- [ ] Iedere waardemutatie via user UUID, request ID, bron, verschil en
  servertijd controleerbaar is.
- [ ] Een staged migratie van representatieve v0.04.06-saves zonder verlies
  slaagt en rollback aantoonbaar werkt.

## Fase 5 — Google Play Billing en server-side aankoopvalidatie

**Prioriteit:** P1 zodra echte aankopen gewenst zijn  
**Omvang:** groot  
**Afhankelijk van:** B4 en een afgeronde fase 4  
**Huidige veilige toestand:** currency packs blijven uitgeschakeld.

Deze fase wordt bewust pas gestart wanneer jij daadwerkelijk binnen afzienbare
tijd wilt gaan verkopen. De voorbereidende interfaces, ledgervelden en
idempotency uit fase 4 maken die late koppeling mogelijk. Tot dat moment blijven
alle betaalfeature-flags uit, bestaan er geen koopbare liveproducten en is er
geen betaalprovider nodig voor normaal spel of tests.

### Startcriteria voor deze uitgestelde fase

- [ ] De server-authoritative economie en migratie van bestaande spelers zijn
  aantoonbaar stabiel.
- [ ] Jij hebt besloten dat echte verkoop voldoende voordeel biedt tegenover
  commissie, support, administratie en juridische verplichtingen.
- [ ] Producten, prijzen, landen, refundbeleid en testgroep zijn inhoudelijk
  vastgesteld.
- [ ] Privacy, support, monitoring en incidentafhandeling zijn klaar voor
  financiële transacties.
- [ ] De op dat moment actuele Google Play Billing-eisen zijn opnieuw
  gecontroleerd; we implementeren niet jaren vooraf tegen mogelijk verouderde
  API's.

### Codex

- [ ] Integreer Google Play Billing met product-ID's uit configuratie.
- [ ] Stuur purchase tokens via een beveiligde serverfunctie naar de Google Play
  Developer API; vertrouw nooit een clientmelding als aankoopbewijs.
- [ ] Verwerk aankoop, acknowledgement en gemcredit idempotent.
- [ ] Ondersteun pending, cancelled, duplicate, already-owned, offline retry,
  reinstall/restore, refund en revocation.
- [ ] Voeg Real-time Developer Notifications of een periodieke
  reconciliatietaak toe voor refunds en terugboekingen.
- [ ] Maak test- en supportinformatie zonder volledige tokens bloot te geven.
- [ ] Test alle aankoopstaten in een Play-testtrack vóór activatie.

### Jij

- [ ] Open en verifieer Play Console plus merchant/betalingsprofiel.
- [ ] Maak definitieve product-ID's, prijzen en landen aan; product-ID's later
  niet lichtvaardig wijzigen.
- [ ] Maak een minimaal bevoegde service-identiteit voor aankoopvalidatie en
  plaats de credentials rechtstreeks in serversecrets.
- [ ] Configureer licentietesters en interne/gesloten testtracks.
- [ ] Beslis over refunds, minderjarigen, belasting, consumentenvoorwaarden en
  support; laat juridische/fiscale keuzes zo nodig professioneel beoordelen.
- [ ] Vul de store- en Data Safety-informatie naar waarheid in.

### Samen klaar wanneer

- [ ] Testaankoop, pending betaling, annulering, dubbele callback, reinstall,
  refund en revocation allemaal aantoonbaar correct werken.
- [ ] Gems exact één keer worden toegekend en bij een geldige terugboeking
  volgens het gekozen beleid worden verwerkt.
- [ ] Geen servicecredential of volledig purchase token in app, log of Git staat.
- [ ] Packs pas na expliciete go/no-go zichtbaar en koopbaar worden.

## Fase 6 — support, privacy en operationeel beheer

**Prioriteit:** P1 vóór brede publieke lancering  
**Omvang:** middelgroot  
**Afhankelijk van:** B6 en fase 1

### Codex

- [ ] Bouw een minimaal supportzoekpad op Keeper ID naar interne user UUID,
  accountstatus, appversie en relevante correlation IDs; gebruik nooit alleen
  de zichtbare keepernaam.
- [x] Maak een veilige diagnostiekexport waarin tokens, e-mail en volledige
  inventory standaard ontbreken.
- [ ] Documenteer procedures voor verloren account, niet ontvangen e-mail,
  mislukte trade, back-upconflict, verwijdering, refund en vermoed misbruik.
- [ ] Voeg least-privilege rollen en logging van supportinzage toe zodra een
  supporttool wordt gebouwd.
- [ ] Stem verwijdering/retentie af tussen Auth, profiel, saves, auditlogs,
  monitoring en aankoopadministratie.

### Jij

- [ ] Kies een supportadres, verantwoordelijke personen en reactietijden.
- [ ] Bepaal wie productiegegevens mag zien en trek toegang direct in wanneer
  die niet meer nodig is.
- [ ] Stel privacyverklaring, accountverwijderpagina en interne
  bewaartermijnen vast; jij blijft verantwoordelijk voor de inhoud.
- [ ] Beheer verzoeken van spelers en eventuele wettelijke bewaarplichten.

### Samen klaar wanneer

- [ ] Een testsupportmelding vanaf Keeper ID via correlation ID naar de juiste
  serveractie kan worden onderzocht zonder onnodige persoonsgegevens.
- [ ] Verwijdering en retentie in app, server, monitoring en documentatie niet
  met elkaar in tegenspraak zijn.
- [ ] De meest waarschijnlijke incidenten minimaal eenmaal als oefening zijn
  doorlopen.

## Fase 7 — capaciteitsbewijs en gecontroleerde lancering

**Prioriteit:** P1 vóór brede publieke lancering, daarna doorlopend  
**Omvang:** middelgroot na voltooiing van eerdere fasen

### Codex

- [ ] Zet gemeten stagingresultaten om in capaciteitsschattingen, index- of
  queryverbeteringen en concrete alarmdrempels.
- [ ] Breid de releasegate uit met staging-E2E, migratietest, serverpreflight,
  artifactversie, handtekening, hash en client/servercompatibiliteit.
- [ ] Maak een rollback/hotfix-runbook voor app én database; destructieve
  databasemigraties vereisen een apart herstelplan.
- [ ] Maak een rolloutdashboard per appversie en bewaak oude clients.

### Jij

- [ ] Kies Supabase-capaciteit en budgetalerts op basis van metingen, niet op
  gokwerk.
- [ ] Start met een kleine staged rollout en keur iedere vergroting apart goed.
- [ ] Houd support, Auth, e-mail, crashes, RPC's, database en kosten tijdens de
  rollout actief in de gaten.
- [ ] Bepaal wie een rollout kan pauzeren en wie over rollback beslist.

### Samen klaar wanneer

- [ ] Iedere release een volledig bewaard verificatierapport heeft.
- [ ] Een mislukte healthcheck, migratie, test, signingcheck of
  compatibiliteitscheck publicatie automatisch tegenhoudt.
- [ ] Rollback of hotfix in staging geoefend is voordat 100% productie-uitrol
  wordt toegestaan.

## Voorgestelde levervolgorde

Versienummers zijn richtinggevend en worden pas bij uitvoering definitief.

| Mijlpaal | Inhoud | Voornaamste eigenaar | Releasepoort |
| --- | --- | --- | --- |
| M0 | GitHub-secrets, groene AAB-workflow en bewijsartifact | Jij + Codex | Eerstvolgende technische release |
| M1 | Monitoring, redaction, healthchecks en incidentrunbook | Jij + Codex | Externe/bredere test |
| M2 | Stagingproject, volledige E2E-flow en eerste 100/1.000-user loadtest | Jij + Codex | Brede publieke beta |
| M3 | Expliciete multi-device conflicten en geteste restore | Codex, met jouw beleid | Brede publieke beta |
| M4 | Servereconomie in delen 4A–4D en migratie bestaande saves | Codex, met jouw productbesluiten | Eerlijke publieke economie |
| M5 | Uitgestelde Google Play Billing en receiptvalidatie via de voorbereide providergrens | Jij + Codex | Alleen vlak voordat echte verkoop gewenst is |
| M6 | Support/privacy-retentie, capaciteitsbewijs en staged rollout | Jij + Codex | Openbare productie |

M0 en de voorbereidingen voor M1 kunnen tegelijk worden gedaan. M2 volgt zodra
de externe projecten beschikbaar zijn. M3 kan functioneel worden voorbereid
tijdens M2. M4 hoort pas definitief gebouwd te worden nadat B1 en B2 vaststaan.
M5 blijft volledig los en uitgeschakeld totdat M4 bewezen klaar is én jij
besluit dat verkoop daadwerkelijk op korte termijn nodig is. De uitbreidingspunten
ervoor worden wel al in M4 getest.

## Algemene definition of done

Een taak of mijlpaal is pas gereed wanneer:

- [ ] implementatie en relevante migraties zijn gereviewd;
- [x] analyzer en alle bestaande plus nieuwe tests slagen voor de huidige
  lokale bouwtranche (329/329 op 31-08-2026);
- [x] negatieve, timeout-, retry- en replaypaden zijn getest voor de huidige
  online clientgrens; toekomstige server-economiecommando's krijgen opnieuw
  dezelfde verplichte scenario's;
- [ ] compacte UI, grote tekst, reduced motion en minimaal één echt Android-
  toestel waar relevant zijn gecontroleerd;
- [ ] geen secrets of onnodige persoonsgegevens in code, logs of artifacts staan;
- [ ] migratie, rollback en compatibiliteit met de vorige appversie zijn getest;
- [ ] documentatie, runbook en beslissingen zijn bijgewerkt;
- [ ] verplichte productiepreflight slaagt;
- [ ] jij het zichtbare resultaat hebt geaccepteerd en een release expliciet
  hebt toegestaan.

## Eerstvolgende concrete acties

1. **Deels afgerond door jou:** B1, B2 en de bewaartermijn voor cloudback-ups
   onder B6 zijn bevestigd. De overige onderdelen van B3–B7 worden beslist
   voordat de bijbehorende productiefase start.
2. **Afgerond door jou:** Android Studio is gesloten; Codex heeft daarna de
   volledige Flutter-analyzer en alle 252 tests succesvol uitgevoerd.
3. **Afgerond door jou:** de zes repositorysecrets voor signing en productie-
   Supabase en de negen afgeschermde stagingsecrets zijn toegevoegd.
4. **Afgerond door Codex:** M0 is met een volledig groene handmatige AAB-
   workflow bewezen, zonder release, tag of productiewijziging.
5. **Afgerond door jou:** een afzonderlijk gratis Supabase-stagingproject en de
   GitHub Environment `staging` zijn ingericht.
6. **Afgerond samen:** signup, handmatige bevestiging van twee accounts, eerste
   login, accountbootstrap, vijfdelige cloudhistorie, oudere restore, bewuste
   lokale vervanging, stale-conflicten, Friends, trade en Group Adventure van
   create tot completion/reward/replay zijn echt op staging bewezen. De
   begrensde staging-only tijdregeling kan uitsluitend de zojuist aangemaakte
   fixture versnellen en weigert de vaste productiereferentie hard.
7. **Samen:** beoordeel de meetresultaten en leg pas daarna grenzen voor
   capaciteit, alerts en publieke uitrol vast.
8. **Afgerond door Codex:** v0.04.08 is met groene staging- en productie-gates
   gepubliceerd; APK en AAB hebben de vaste release-identiteit en productie
   doorstond na migratie opnieuw lint-, parity- en Auth-controles.
9. **Afgerond door Codex op staging en productie:** M3 bewaart de huidige plus vier vorige
   cloudrevisies gedurende maximaal dertig dagen, toont metadata, ondersteunt
   een expliciete oudere restore en bewaart de vorige cloudkopie bij bewuste
   vervanging. Migraties 21–23 zijn na afzonderlijke expliciete toestemming en
   een exacte 20→23-dry-run naar productie gebracht.
10. **Afgerond en bewezen door Codex:** automatische cloudback-up maximaal
    iedere vijftien minuten, een directe veilige flush bij achtergrond, de
    wekelijkse staging-restorecontrole en de uurlijkse productie-healthalert.
11. **Nog door jou voor volledige Firebase-monitoring:** maak het Spark-project,
    registreer `nl.dragonhaven.app`, laat Analytics uit en zet de gedownloade
    Android-config volgens `FIREBASE_MONITORING_SETUP.md` in de werkmap.
12. **Afgerond door Codex:** v0.04.10 is met 289/289 tests, een groene volledige
    staging-E2E, twee begrensde productiemigraties en dubbele releasegate
    gepubliceerd. Productie staat op 26/26 en de ondertekende APK/AAB gebruiken
    nog steeds de vaste release-identiteit.
13. **Afgerond door Codex:** v0.04.11 is met 298/298 tests, een groene volledige
    staging-E2E, de exact begrensde productiemigratie 26→27, een onafhankelijke
    productiepreflight en dubbele releasegate gepubliceerd. Productie staat op
    27/27; de APK/AAB behouden package `nl.dragonhaven.app` en het vaste
    releasecertificaat. De post-release healthcheck is eveneens groen.
14. **Afgerond door Codex:** v0.04.12 is met 301/301 tests, een lokale en twee
    CI-productiepreflights, compacte/reduced-motion emulatorcontrole en een
    dubbele releasegate gepubliceerd. De online refresh-storm en de
    batch-kistreveal zijn gestabiliseerd en afgeronde Adventures tonen hun
    rewards vooraf. Er waren geen databasemigraties nodig; productie blijft op
    27/27 en de post-release healthcheck is groen.
15. **Afgerond door Codex:** v0.04.13 is met 302/302 tests, een lokale
    productiepreflight, een onafhankelijke productiegate en Android-regressie-
    controles uitgebracht. De app vraagt notificatierechten niet langer
    herhaald of tijdens iedere koude start aan nadat Android ze heeft geweigerd;
    de notificatiepagina toont dan een compacte route naar de systeeminstellingen.
    Dit is op het gemelde fysieke toestel en op een Android-emulator met herhaalde
    koude starts bewezen. Er waren geen database- of servermigraties nodig;
    productie blijft op 27/27 en beide releasegates plus de post-release
    healthcheck zijn groen.
16. **Afgerond door Codex:** v0.04.14 is met 319/319 tests, een volledige
    sociale staging-E2E, de exact begrensde productiemigratie 27→28, een
    onafhankelijke productiepreflight en twee releasegates gepubliceerd.
    Kamerordening, Friend Adventure-uitleg, de 7-daagse Trial-streak, Keeper
    Journal, Dragon Academy en de payment-ready Supporter Pack/Vanity-laag zijn
    uitgerold. Productie staat op 28/28; live aankoop blijft bewust geblokkeerd
    tot fase 4 en server-side Google Play-verificatie gereed zijn. De
    post-release healthcheck is groen.
17. **Afgerond door Codex:** v0.04.15 is met 329/329 tests, een lokale
    productiepreflight en twee onafhankelijke productie-/signinggates
    gepubliceerd. Dragon Academy gebruikt nu tien visueel unieke lessen,
    leerling- en mentorselectie, drie officiële pogingen per les, rapportstatus,
    ranking, beloningen en Dropout/Valedictorian-achievements. Bestaande
    schoolvoortgang migreert via saveschema 47; er was geen databasemigratie
    nodig en productie blijft op 28/28. Compacte breedte en reduced motion zijn
    op de emulator gecontroleerd; de post-release healthcheck is groen.
18. **Afgerond door Codex:** v0.04.16 is met 339/339 tests, volledige staging,
    productiemigratie 29, een onafhankelijke productiepreflight en twee
    signinggates gepubliceerd. De release bevat de Dragon Academy-,
    foregroundmuziek-, blijvende weergave-, badge/Vanity-, Supporter-,
    Music Chest-, Packs-, Friends-refresh- en verzoekbadgeverbeteringen.
    Migratie 29 houdt oudere profiel-RPC's beschikbaar; productie staat op
    29/29 en de post-release healthcheck is groen.
19. **Afgerond door Codex:** v0.05.00 is met 347/347 tests, de uitgebreide
    Friend Messages-/Conclave-staging-E2E, de exact begrensde productiemigratie
    29→31, een onafhankelijke productiepreflight en twee signinggates
    gepubliceerd. Supporter-furniture en -portrait zijn gecorrigeerd en Android
    plant tijdkritische meldingen exact en herstelt ze na herstart, app-update en
    klok-/tijdzonewijzigingen. De APK en Play-ready AAB gebruiken versionCode
    10050 en het vaste releasecertificaat. Compacte breedte en reduced motion
    zijn op de emulator gecontroleerd; productie staat op 31/31 en de
    post-release healthcheck is groen.

## Besluitenlog

| Datum | ID | Besluit | Reden | Gevolg voor plan |
| --- | --- | --- | --- | --- |
| 28-08-2026 | B1 | Lokale weergave en gameplay blijven offline bruikbaar; toekomstige waardevolle online claims en mutaties worden server-authoritative | Eerlijkheid combineren met offline speelbaarheid | M4 mag deze grens als uitgangspunt gebruiken |
| 28-08-2026 | B2 | Bestaande saves krijgen één gelogde import met plausibiliteitslimieten en daarna server-lock; bestaande voortgang wordt nooit stil verwijderd | Veilige overgang zonder trouwe spelers voortgang af te nemen | Importprotocol en compatibiliteitstests mogen worden gebouwd |
| 28-08-2026 | B6-back-up | Per account de laatste vijf cloudrevisies maximaal dertig dagen bewaren | Voldoende herstelruimte met beperkte gratis opslag en privacy-impact | Back-uphistorie, opschoning en herstelkeuze mogen worden gebouwd |
| 28-08-2026 | M2-testtijd | Een hard staging-only tijdregeling mag Group Adventure completion versnellen | Volledige meerdaagse flow veilig en reproduceerbaar testen zonder productiepad | Completion/reward/replay en cleanup zijn volledig bewezen |
| 28-08-2026 | Release 0.04.08 | Migraties 21–23 en de nieuwe release zijn expliciet toegestaan | Auditverbeteringen gecontroleerd naar productie brengen | Productie staat op 23/23 en v0.04.08 is openbaar |
| 28-08-2026 | B5-monitoring | Firebase Spark met Crashlytics/Performance, Analytics uit; Rick ontvangt de eerste alerts; afgesproken providerretentie en 7/30 dagen voor support-/incidentbewijs | Gratis en privacyarm beginnen, later makkelijk uitbreidbaar | Healthalert mag worden geautomatiseerd; Firebase-SDK volgt zodra Rick het project/appconfig heeft gemaakt |
| 28-08-2026 | B6-automatische back-up | Betekenisvolle voortgang maximaal iedere 15 minuten automatisch back-uppen en openstaande voortgang direct veilig flushen bij achtergrond; RPO 15 minuten online, self-service RTO 15 minuten, supportdoel 4 uur; wekelijkse stagingtest en maandelijkse controle door Rick | Voortgang beschermen zonder gameplay of free tier onnodig te belasten | Automatische trigger en wekelijkse restoreworkflow mogen worden gebouwd |
| 28-08-2026 | Release 0.04.09 | Migratie 24 en een afzonderlijke nieuwe apprelease zijn expliciet toegestaan | Expertisegrenzen en aanvullende fixes client/server-consistent uitrollen | Productie staat op 24/24 en v0.04.09 is openbaar na groene staging-, migratie- en dubbele releasegates |
| 28-08-2026 | B4-prijscontract | Zowel de zes coinpacks als de zes gempacks gebruiken later de europrijsladder €1, €2, €5, €10, €20 en €30 | Play-producten vooraf eenduidig voorbereiden zonder betalingen vroeg te activeren | Interne catalogus bewaart de basisprijzen; de live UI moet later altijd Google Plays gelokaliseerde prijs tonen |
| 29-08-2026 | Release 0.04.10 | Broncode, migraties 25–26, staging, productie en de nieuwe apprelease zijn expliciet toegestaan | Special Events, serverondersteuning en de nieuwste spelcorrecties als één gecontroleerde versie uitrollen | Productie staat op 26/26 en v0.04.10 is openbaar na groene staging-, migratie- en dubbele releasegates |
| 30-08-2026 | Release 0.04.11 | Broncode, migratie 27, staging, productie en de nieuwe apprelease zijn expliciet toegestaan | Sinisterra/Sinister Eggs, incubatie tot op de seconde en batchgewijs kisten openen gecontroleerd uitrollen | Productie staat op 27/27 en v0.04.11 is openbaar na groene staging-, migratie-, productie-, tag- en healthgates |
| 30-08-2026 | Release 0.04.12 | Broncode en de nieuwe apprelease zijn expliciet toegestaan; deze tranche bevat geen databasemigratie | De gemelde online refresh-storm, crashgevoelige 10×-kistreveal en onduidelijke Adventure-rewards gecontroleerd herstellen | Productie blijft op 27/27 en v0.04.12 is openbaar na twee groene productie-/releasegates en een groene healthcheck |
| 30-08-2026 | Release 0.04.13 | Broncode en de nieuwe apprelease zijn expliciet toegestaan; deze tranche bevat geen databasemigratie | Voorkomen dat een eerder geweigerde Android-notificatieprompt tijdens koude starts de app naar de achtergrond stuurt en als terugkerende storing aanvoelt | Productie blijft op 27/27 en v0.04.13 is openbaar na fysieke toestelcontrole, emulatorregressie, twee groene releasegates en een groene post-release healthcheck |
| 30-08-2026 | Release 0.04.14 | Broncode, staging, productiemigratie 28 en de nieuwe apprelease zijn expliciet toegestaan | De featuretranche met progression, Dragon Academy en Supporter Vanity gecontroleerd en servercompatibel uitrollen | Productie staat op 28/28 en v0.04.14 is openbaar na groene staging-, migratie-, productie-, tag- en healthgates; echte aankopen blijven uitgeschakeld |
| 31-08-2026 | Release 0.04.15 | Broncode en de nieuwe apprelease zijn expliciet toegestaan; deze tranche bevat geen databasemigratie | De uitgebreide Dragon Academy-opleiding, rapportstatussen, nieuwe sprites en Supporter-/Trial-presentatie gecontroleerd uitrollen | Productie blijft op 28/28 en v0.04.15 is openbaar na lokale preflight, 329 tests, compacte/reduced-motion controle, twee groene releasegates en een groene healthcheck; echte aankopen blijven uitgeschakeld |
| 31-08-2026 | Release 0.04.16 | Broncode, staging, productiemigratie 29 en de nieuwe apprelease zijn expliciet toegestaan | De Dragon Academy-/Vanity-/Supporter-verbeteringen, robuuste Friends-refresh en verzoekbadge gecontroleerd en achterwaarts compatibel uitrollen | Productie staat op 29/29 en v0.04.16 is openbaar na groene lokale checks, staging-, migratie-, productie-, tag- en healthgates. Echte aankopen blijven uitgeschakeld |
| 31-08-2026 | Release 0.05.00 | Broncode, staging, productiemigraties 30–31 en de nieuwe apprelease zijn expliciet toegestaan | Friend Messages en Conclaves plus de notificatie- en Supporter-correcties als serverveilige hoofdversie uitrollen; migratie 31 is de noodzakelijke idempotente lintcorrectie na de eerste stagingpoging | Productie staat op 31/31 en v0.05.00 is openbaar na groene 347-testgate, uitgebreide twee-account staging-E2E, begrensde migratie 29→31, dubbele releasegate, emulatorcontrole en post-release healthcheck; echte aankopen blijven uitgeschakeld |
| Nog te bepalen | B3, B4-activering en B7 | Nog niet bevestigd | Beslissen vlak vóór de afhankelijke fase | Alleen de nog afhankelijke delen van M4–M6 wachten |

## Voortgangslog

| Datum | Mijlpaal/taak | Uitgevoerd door | Bewijs of link | Resultaat/vervolg |
| --- | --- | --- | --- | --- |
| 28-08-2026 | Uitgangsaudit v0.04.06 | Codex | `DRAGONHAVEN_AUDIT_2026-08-28.md` | Basis groen; resterende grenzen in dit plan verwerkt |
| 28-08-2026 | M0 workflowhardening | Codex | `.github/workflows/release.yml` | Vroege secretcheck, pubspec-versionCode, AAB-hash/certificaat en bewijsrapport gebouwd |
| 28-08-2026 | M1 gratis diagnostiekbasis | Codex | `lib/services/diagnostic_reporter.dart`, `INCIDENT_RUNBOOK.md` | Supportcodes, veilige export, redactiontests en handmatige healthworkflow gebouwd |
| 28-08-2026 | Productiepreflight na healthrefactor | Codex | `tool/release_server_preflight.ps1` | 20/20 migraties, 0 lintfouten, Auth 200/200; eerste health 24,5 s, clienttimeout daarom 75 s |
| 28-08-2026 | M2 stagingafscheiding | Codex | `.github/workflows/staging.yml`, `lib/config/online_config.dart` | Production/staging/local veilig gescheiden |
| 28-08-2026 | M3 conservatieve conflictbeveiliging | Codex | `OnlineAccountProvider`, `StorageService`, `AccountScreen` | Stil cloudoverschrijven geblokkeerd; restore/lokaal-doorgaan gebouwd, force-overwrite wacht op retentie- en historiebeleid |
| 28-08-2026 | Uitgestelde payment-ready grens | Codex | `lib/services/purchase_provider.dart` | Twaalf interne product-ID's en server-verified contract; geen Billing-SDK, liveproducten of kosten geactiveerd |
| 28-08-2026 | Volledige lokale kwaliteitscontrole | Codex | `flutter analyze --no-pub`, `flutter test --no-pub` | Analyzer zonder issues; 252/252 tests geslaagd nadat Android Studio was gesloten |
| 28-08-2026 | Lokalisatie support- en cloudteksten | Codex | `lib/l10n/release_phrase_translations.dart`, `test/localization_completeness_test.dart` | Twaalf nieuwe vaste teksten in alle zes aanvullende talen toegevoegd; 10/10 lokalisatiecontroles geslaagd |
| 28-08-2026 | M2 eerste echte stagingverificatie | Jij + Codex | [GitHub Actions-run 33176572637](https://github.com/Rakky88/DragonHaven/actions/runs/33176572637) | Public-only basis: safetychecks, 20 migraties, lint, preflight, analyzer, 252 tests en geïsoleerde APK groen |
| 28-08-2026 | M0 Play Store-readinessbewijs | Jij + Codex | [GitHub Actions-run 33177281257](https://github.com/Rakky88/DragonHaven/actions/runs/33177281257) | Ondertekende AAB, productiepreflight, analyzer en 252 tests groen; bewijsartifact gemaakt, geen release of tag gepubliceerd |
| 28-08-2026 | M2 bevestigde account- en back-up-E2E | Jij + Codex | [GitHub Actions-run 33180648232](https://github.com/Rakky88/DragonHaven/actions/runs/33180648232) | Login, bevestigde e-mail, bootstrap, profiel, back-up/restore, stale-revisionweigering, logout, analyzer, 252 tests en staging-APK groen |
| 28-08-2026 | M2 tweepersoons sociale staging-E2E | Jij + Codex | [GitHub Actions-run 33182884493](https://github.com/Rakky88/DragonHaven/actions/runs/33182884493) | Friends, atomaire chest-trade en Group Adventure create/list/join/leave met veilige cleanup groen; analyzer, 252 tests, staging-APK en bewijsartifact groen; completion/rewardpad blijft open |
| 28-08-2026 | Openbare release v0.04.07 | Codex | [Release](https://github.com/Rakky88/DragonHaven/releases/tag/v0.04.07), [gate 33185616650](https://github.com/Rakky88/DragonHaven/actions/runs/33185616650) | Ondertekende APK gepubliceerd; productiepreflight, analyzer, 252 tests, AAB-signing en hashbewijs groen |
| 28-08-2026 | Negatieve online herstelpaden | Codex | `test/online_social_test.dart` | Verlopen sessie, timeout plus reconnect, dubbele tap, half afgemaakte Group Reward en trade-replay na save/herstart getest; volledige set 256/256 groen |
| 28-08-2026 | Veilige bestaande-save-importbasis | Codex | `202608280021_audited_legacy_inventory_import.sql` | Versie, limieten, privacyarm rapport, SHA-256 en private 30-daagse herstelkopie gebouwd; gecontroleerde rollbackuitvoering volgt |
| 28-08-2026 | Importmigratie op staging | Codex | [Stagingrun 33188269327](https://github.com/Rakky88/DragonHaven/actions/runs/33188269327) | Migratie 21 toegepast; 21/21 parity, schema-lint/preflight, analyzer, 256 tests en staging-APK groen |
| 28-08-2026 | Importstatus/rapport-E2E | Codex | [Stagingrun 33189927346](https://github.com/Rakky88/DragonHaven/actions/runs/33189927346) | Bevestigd account bewijst coherentie: niet geïmporteerd geeft nul auditrecords; geïmporteerd vereist exact één geldig versie-0/1-rapport |
| 28-08-2026 | Gratis dashboardspecificatie | Codex | `OBSERVABILITY_BASELINE.md` | Privacyarme panelen, meetvelden, zeven-dagenbaseline, gratis startbronnen en later upgradepad vastgelegd; echte alerts wachten op eigenaar/projectkeuze |
| 28-08-2026 | M3 herstelbare cloudhistorie | Codex | [Stagingrun 33193296552](https://github.com/Rakky88/DragonHaven/actions/runs/33193296552), migraties 22 en 23 | 23/23 migraties, database-lint/preflight, twee echte revisies, oude-save-readback, stale-writeweigering, analyzer, 259 tests, staging-APK en bewijsartifact groen; productie ongewijzigd op 20 migraties |
| 28-08-2026 | CI-runtimeonderhoud | Codex | [Stagingrun 33194122823](https://github.com/Rakky88/DragonHaven/actions/runs/33194122823), commit `2a52e9af804f8415a6546d1c5c128b2ab4fe912c` | Supabase Setup CLI v3 en Upload Artifact v6 bewezen; 23/23 stagingmigraties, lint/preflight, analyzer, 259 tests, staging-APK en artifact groen |
| 28-08-2026 | Publieke productie-healthcheck | Codex | [Healthrun 33194121092](https://github.com/Rakky88/DragonHaven/actions/runs/33194121092) | Read-only Auth-healthcheck en het driedaagse privacyarme bewijsartifact groen; veilige applicatie-RPC, planning en alerts blijven onder fase 1 open |
| 28-08-2026 | Volledige Group Adventure staging-E2E | Codex | [Stagingrun 33196707499](https://github.com/Rakky88/DragonHaven/actions/runs/33196707499) | Create/join/start/completion, exact één reward per deelnemer, duplicate acknowledgement, claim-replay en volledige cleanup groen via een hard staging-only tijdregeling |
| 28-08-2026 | v0.04.08 releasecandidate op staging | Codex | [Stagingrun 33197572353](https://github.com/Rakky88/DragonHaven/actions/runs/33197572353) | 23/23 migraties, volledige sociale E2E, analyzer, 261 tests en geïsoleerde staging-APK groen |
| 28-08-2026 | Productiemigraties 21–23 | Codex, na jouw toestemming | [Migratierun 33198153589](https://github.com/Rakky88/DragonHaven/actions/runs/33198153589) | Exacte beginstand 20, dry-run, database-lint en Auth groen; productie gecontroleerd naar 23/23 gemigreerd en opnieuw geverifieerd |
| 28-08-2026 | Openbare release v0.04.08 | Codex, na jouw toestemming | [Release](https://github.com/Rakky88/DragonHaven/releases/tag/v0.04.08), [productiegate 33198225157](https://github.com/Rakky88/DragonHaven/actions/runs/33198225157), [taggate 33198930542](https://github.com/Rakky88/DragonHaven/actions/runs/33198930542) | Ondertekende APK van 327.993.256 bytes gepubliceerd; SHA-256 `3880354b1dafebabcc39c824eac8899bfc4a339ad8b5b0b712edb7e971cb2826`; beide productiepreflights, 261 tests en Play-ready AAB groen |
| 28-08-2026 | B5/B6 implementatietranche voor v0.04.09 | Codex | `automatic_cloud_backup.dart`, `weekly-staging-restore.yml`, `health-check.yml`, `FIREBASE_MONITORING_SETUP.md` | Automatische 15-minutenback-up plus achtergrondflush, wekelijkse echte restore en uurlijkse productiecheck met één toegewezen SEV-1-issue gebouwd; Firebase-client wacht uitsluitend op Rick's projectconfig |
| 28-08-2026 | v0.04.09 releasecandidate op staging | Codex | [Stagingrun 33204337160](https://github.com/Rakky88/DragonHaven/actions/runs/33204337160) | Migratie 24, database-lint/preflight, volledige sociale en Group Adventure-E2E, analyzer, 270 tests, geïsoleerde staging-APK en bewijsartifact groen |
| 28-08-2026 | Productiemigratie 24 | Codex, na jouw toestemming | [Migratierun 33204827275](https://github.com/Rakky88/DragonHaven/actions/runs/33204827275) | Exacte beginstand 23, dry-run en database-lint groen; alleen migratie 24 toegepast en daarna 24/24 parity plus Auth opnieuw groen |
| 28-08-2026 | Eerste monitoring- en restorebewijzen | Codex | [Healthrun 33205759992](https://github.com/Rakky88/DragonHaven/actions/runs/33205759992), [restorerun 33205758376](https://github.com/Rakky88/DragonHaven/actions/runs/33205758376) | Productiehealth HTTP-groen; actuele en historische staging-cloudsave succesvol hersteld; beide privacyarme bewijsartifacts dertig dagen bewaard |
| 28-08-2026 | Openbare release v0.04.09 | Codex, na jouw toestemming | [Release](https://github.com/Rakky88/DragonHaven/releases/tag/v0.04.09), [productiegate 33204987488](https://github.com/Rakky88/DragonHaven/actions/runs/33204987488), [taggate 33205588983](https://github.com/Rakky88/DragonHaven/actions/runs/33205588983) | Ondertekende APK van 328.058.796 bytes gepubliceerd; SHA-256 `4b03399bb31545a80af04c3919d4a8e3795bb3d14a627f4cf11903dc704be31a`; beide productiepreflights, 270 tests en Play-ready AAB groen |
| 28-08-2026 | Correcties voor v0.04.10 | Codex | `pet.dart`, `social.dart`, migratie 25 en begrensde workflow 24→25 | Infernal Mastery gebruikt 400 voor Might, Arcana en Spirit; Friends telt ontdekte normale vormen in plaats van families; later via de v0.04.10-tranche bewezen en uitgerold |
| 28-08-2026 | Toekomstig Play-prijscontract | Jij + Codex | `purchase_provider.dart`, `purchase_provider_test.dart` | Voor coins en gems is €1/€2/€5/€10/€20/€30 per pakketpositie vastgelegd; provider blijft bewust uitgeschakeld tot fase 4 en het activeringsbesluit zijn afgerond |
| 29-08-2026 | Special Adventure-framework en Cluckatrice-event | Codex | `special_adventure_test.dart`, migratie 26, [stagingrun 33244546317](https://github.com/Rakky88/DragonHaven/actions/runs/33244546317) | Datagedreven terugkerende events, Special Chest/Egg, Cluckatrice, achievement, eventmelding, 21-uurs incubatie en serverondersteuning bewezen; volledige sociale en Group Adventure-E2E, analyzer en 289 tests groen |
| 29-08-2026 | Automatisch uitkomen en veilige presentaties | Codex | `automatic_hatch_coordinator_test.dart`, `hatch_presentation_test.dart`, commit `581e9bd19c4e29b59b44f413d27a953a7d4bd157` | Eieren komen bij verstreken tijd automatisch uit; Tower toont de resterende tijd; hatch/evolutie/achievement wachten tot een actieve Trial inclusief rewards is afgerond; Cluckatrice-transparantie is opnieuw begrensd getest |
| 29-08-2026 | Productiemigraties 25–26 | Codex, na jouw toestemming | [migratie 25](https://github.com/Rakky88/DragonHaven/actions/runs/33244862612), [migratie 26](https://github.com/Rakky88/DragonHaven/actions/runs/33244914831) | Iedere workflow controleerde de exacte beginstand, dry-run, database-lint, Auth en eindpariteit; productie staat gecontroleerd op 26/26 |
| 29-08-2026 | Openbare release v0.04.10 | Codex, na jouw toestemming | [Release](https://github.com/Rakky88/DragonHaven/releases/tag/v0.04.10), [productiegate 33245012909](https://github.com/Rakky88/DragonHaven/actions/runs/33245012909), [taggate 33245410169](https://github.com/Rakky88/DragonHaven/actions/runs/33245410169) | Ondertekende APK van 335.020.376 bytes gepubliceerd; SHA-256 `2b821fd88daf1ee1143669f3b654019fd3b8fdf18889f9cbe678d98aa36e4497`; productiepreflights, 289 tests en Play-ready AAB groen |
| 29-08-2026 | Post-release productiehealth | Codex | [Healthrun 33245762747](https://github.com/Rakky88/DragonHaven/actions/runs/33245762747) | Publieke productie-endpoints direct na v0.04.10 opnieuw groen; bewijsartifact geüpload en er stond geen open storingsalert |
| 30-08-2026 | v0.04.11 releasecandidate op staging | Codex | [Stagingrun 33281827365](https://github.com/Rakky88/DragonHaven/actions/runs/33281827365) | Migratie 27, database-lint/preflight, volledige sociale en Group Adventure-E2E, analyzer, 298 tests, geïsoleerde staging-APK en bewijsartifact groen |
| 30-08-2026 | Productiemigratie 27 | Codex, na jouw toestemming | [Migratierun 33282124409](https://github.com/Rakky88/DragonHaven/actions/runs/33282124409) | Exacte beginstand 26, publieke healthcheck, database-lint en dry-run groen; alleen migratie 27 toegepast en daarna 27/27 parity plus Auth opnieuw groen |
| 30-08-2026 | Openbare release v0.04.11 | Codex, na jouw toestemming | [Release](https://github.com/Rakky88/DragonHaven/releases/tag/v0.04.11), [productiegate 33282204885](https://github.com/Rakky88/DragonHaven/actions/runs/33282204885), [taggate 33282583148](https://github.com/Rakky88/DragonHaven/actions/runs/33282583148) | Ondertekende APK van 339.929.596 bytes gepubliceerd; SHA-256 `2417cf18393220471c6f09ba59960bce875ed753f3276478c9fe9b56c8d18fd1`; beide productiepreflights, 298 tests en Play-ready AAB groen |
| 30-08-2026 | Post-release productiehealth | Codex | [Healthrun 33282909288](https://github.com/Rakky88/DragonHaven/actions/runs/33282909288) | Publieke productie-endpoints direct na v0.04.11 opnieuw groen; bewijsartifact geüpload en er staat geen open storingsalert |
| 30-08-2026 | Openbare release v0.04.12 | Codex, na jouw toestemming | [Release](https://github.com/Rakky88/DragonHaven/releases/tag/v0.04.12), [productiegate 33303254299](https://github.com/Rakky88/DragonHaven/actions/runs/33303254299), [taggate 33303625899](https://github.com/Rakky88/DragonHaven/actions/runs/33303625899) | Ondertekende APK van 339.962.388 bytes gepubliceerd; SHA-256 `5d93c58c32e072cd5655f1afbeb761b849048529e16a17cc83b3421a7b340155`; package `nl.dragonhaven.app`, versionCode 10045 en vast releasecertificaat bewezen; beide productiepreflights, 301 tests, compacte/reduced-motion UI-controle en Play-ready AAB groen |
| 30-08-2026 | Post-release productiehealth | Codex | [Healthrun 33303962771](https://github.com/Rakky88/DragonHaven/actions/runs/33303962771) | Publieke productie-endpoints direct na v0.04.12 opnieuw groen; bewijsartifact geüpload, productie blijft op 27/27 migraties en er staat geen open storingsalert |
| 30-08-2026 | Openbare release v0.04.13 | Codex, na jouw toestemming | [Release](https://github.com/Rakky88/DragonHaven/releases/tag/v0.04.13), [productiegate 33305564413](https://github.com/Rakky88/DragonHaven/actions/runs/33305564413), [taggate 33305906855](https://github.com/Rakky88/DragonHaven/actions/runs/33305906855) | Ondertekende APK van 339.962.464 bytes gepubliceerd; SHA-256 `ec98434a99feafa2780561b494847763e4278169b6c58b0d769af8c060edbff3`; package `nl.dragonhaven.app`, versionCode 10046 en vast releasecertificaat bewezen; productiepreflight, 302 tests en de nieuwe denied-permission-regressies zijn groen |
| 30-08-2026 | Post-release productiehealth v0.04.13 | Codex | [Healthrun 33306212649](https://github.com/Rakky88/DragonHaven/actions/runs/33306212649) | Publieke productie-endpoints direct na v0.04.13 opnieuw groen; bewijsartifact geüpload, productie blijft op 27/27 migraties en er staat geen open storingsalert |
| 30-08-2026 | Featuretranche voor v0.04.14 | Codex | `new_feature_batch_widget_test.dart`, `household_provider_test.dart`, `sprite_bounds_test.dart`, `online_social_test.dart`, migratie 28 | Kamerordening, Friend Adventure-uitleg, 7-daagse Trial-streak met reset naar nul na een gemiste dag, Keeper Journal, Dragon Academy, vaste Sinisterra-alignment en payment-ready Supporter Pack gebouwd. Het Supporter-portretframe is een selecteerbare Vanity-keuze en wordt compatibel naar vriendenprofielen gesynchroniseerd; de oude profiel-RPC blijft voor bestaande apps bestaan. Static analysis en 319/319 tests zijn groen; live aankoop blijft veilig geblokkeerd tot fase 4 en server-side Google Play-verificatie klaar zijn. |
| 30-08-2026 | v0.04.14 releasecandidate op staging | Codex | [Stagingrun 33329371768](https://github.com/Rakky88/DragonHaven/actions/runs/33329371768) | Migratie 28, volledige twee-account social flow, analyzer, 319 tests, geïsoleerde staging-APK en bewijsartifact groen |
| 30-08-2026 | Productiemigratie 28 en onafhankelijke preflight | Codex, na jouw toestemming | [Migratierun 33329749508](https://github.com/Rakky88/DragonHaven/actions/runs/33329749508), `tool/release_server_preflight.ps1` | Exacte beginstand 27 en dry-run groen; alleen migratie 28 toegepast. Daarna 28/28 parity, 0 database-lintfouten en Auth health/settings 200/200 op project `tnzathhutuwmohmjfrlo` bewezen |
| 30-08-2026 | Openbare release v0.04.14 | Codex, na jouw toestemming | [Release](https://github.com/Rakky88/DragonHaven/releases/tag/v0.04.14), [productiegate 33329828902](https://github.com/Rakky88/DragonHaven/actions/runs/33329828902), [taggate 33330282266](https://github.com/Rakky88/DragonHaven/actions/runs/33330282266) | Ondertekende APK van 345.934.831 bytes gepubliceerd; SHA-256 `f1f77ab4b40be9265e5cd650be888ad803eea161a6a7f0bf19803fcb3eeae49f`; package `nl.dragonhaven.app`, versionCode 10047 en vast releasecertificaat bewezen; beide productiepreflights, 319 tests en Play-ready AAB groen |
| 30-08-2026 | Post-release productiehealth v0.04.14 | Codex | [Healthrun 33330682921](https://github.com/Rakky88/DragonHaven/actions/runs/33330682921) | Publieke productie-endpoints direct na v0.04.14 opnieuw groen; bewijsartifact geüpload, productie staat op 28/28 migraties en er staat geen open storingsalert |
| 31-08-2026 | Dragon Academy-verdieping voor v0.04.15 | Codex | commit `0c38def1a999b8a9d05f59e5e302fc11965a7fd7`, `dragon_school.dart`, `dragon_school_screen.dart`, `household_provider_test.dart`, `new_feature_batch_widget_test.dart`, `sprite_bounds_test.dart` | Tien visueel unieke lessen met eigen achtergronden en speelstukken, leerlingen, teamlessen, mentoren, drie pogingen per les, blijvende scores/sterren, rapportstatussen, Academy Score en nieuwe achievements gebouwd; saveschema 47 bewaart bestaande academievoortgang veilig; analyzer en 329/329 tests groen |
| 31-08-2026 | Openbare release v0.04.15 | Codex, na jouw toestemming | [Release](https://github.com/Rakky88/DragonHaven/releases/tag/v0.04.15), [productiegate 33339570035](https://github.com/Rakky88/DragonHaven/actions/runs/33339570035), [taggate 33340087680](https://github.com/Rakky88/DragonHaven/actions/runs/33340087680) | Ondertekende APK van 355.843.461 bytes gepubliceerd; SHA-256 `9ab67c4164f69c9a4211491cb4afa2c66b7c19123ec6a87ee854fcef802c4180`; package `nl.dragonhaven.app`, versionCode 10048 en vast releasecertificaat bewezen; beide productiepreflights, 329 tests, compacte/reduced-motion UI-controle en Play-ready AAB groen; geen databasemigratie, productie blijft 28/28 |
| 31-08-2026 | Post-release productiehealth v0.04.15 | Codex | [Healthrun 33340431353](https://github.com/Rakky88/DragonHaven/actions/runs/33340431353) | Publieke productie-endpoints direct na v0.04.15 opnieuw groen; bewijsartifact geüpload, productie staat op 28/28 migraties en er staat geen open storingsalert |

| 31-08-2026 | v0.04.16 featuretranche | Codex | commit `89fee10510b0076c2f68adab730877e7ffd69695`, saveschema 48, migratie 29, `audio_service_test.dart`, `household_provider_test.dart`, `new_feature_batch_widget_test.dart`, `online_social_test.dart`, `widget_test.dart` | Dragon Academy-naamgeving en vervroegd afstuderen, gecentreerde Sigil Memory/Shadow Match, uitsluitend voorgrondmuziek, herstelde Trial-constellatie, blijvende My Dragons/Eggs-weergavevoorkeuren, uitbreidbare online badges, plaatsbare Supporter-furniture, een onderscheidende geopende Music Chest, een stabiele heropenbare Packs-pagina en een live rode teller voor inkomende verzoeken op de Friends-tab gebouwd. De Friends-refresh bewaart nu een geldige server-snapshot voordat niet-kritieke onderhoudstaken draaien; een onderhoudsfout kan daardoor niet langer het profiel en de vriendenlijst leegtrekken en krijgt een eigen privacyarme diagnose-operatie. De productiecheck voor Qnosick bewees een bereikbaar account, geldige snapshot en werkend notificatie-acknowledgement zonder gegevens te wijzigen. Analyzer en 339/339 tests zijn groen. |
| 31-08-2026 | v0.04.16 releasecandidate op staging | Codex | [Stagingrun 33376878533](https://github.com/Rakky88/DragonHaven/actions/runs/33376878533) | Migratie 29, databasepreflight, volledige twee-account social- en Group Adventure-E2E, analyzer, 339 tests, geïsoleerde staging-APK en bewijsartifact groen |
| 31-08-2026 | Productiemigratie 29 en onafhankelijke preflight | Codex, na jouw toestemming | [Migratierun 33377566011](https://github.com/Rakky88/DragonHaven/actions/runs/33377566011), `tool/release_server_preflight.ps1` | Exacte beginstand 28, publieke healthcheck, database-lint en dry-run groen; uitsluitend migratie 29 toegepast. Daarna 29/29 parity, 0 database-lintfouten en Auth health/settings 200/200 op project `tnzathhutuwmohmjfrlo` bewezen. Oudere profiel-RPC's blijven beschikbaar |
| 31-08-2026 | Openbare release v0.04.16 | Codex, na jouw toestemming | [Release](https://github.com/Rakky88/DragonHaven/releases/tag/v0.04.16), [productiegate 33377773908](https://github.com/Rakky88/DragonHaven/actions/runs/33377773908), [taggate 33378504659](https://github.com/Rakky88/DragonHaven/actions/runs/33378504659) | Ondertekende APK van 358.433.995 bytes gepubliceerd; SHA-256 `fe94f1d5b33cea84acfe045d6ee8c3269c53575162925e2e4ee89a54206388bf`; package `nl.dragonhaven.app`, versionCode 10049 en vast releasecertificaat bewezen; beide productiepreflights, 339 tests en Play-ready AAB groen; GitHubs versiegebonden en permanente latest-download wijzen naar hetzelfde asset |
| 31-08-2026 | Post-release productiehealth v0.04.16 | Codex | [Healthrun 33379163158](https://github.com/Rakky88/DragonHaven/actions/runs/33379163158) | Publieke productie-endpoints direct na v0.04.16 opnieuw groen; bewijsartifact geüpload, productie staat op 29/29 migraties en er staat geen open storingsalert |
| 31-08-2026 | Lokale Friend Messages- en Conclave-tranche | Codex | migraties `202608310030_friend_messages_and_conclaves.sql` en `202608310031_fix_conclave_function_ambiguity.sql`, `friend_messages_screen.dart`, `conclave_screen.dart`, 31 nieuwe sociale sprites, `social_phrase_translations.dart`, `online_social_test.dart`, `notification_service_test.dart`, `sprite_bounds_test.dart` en `dragonhaven_spec_test.dart` | Vriendenchats en Conclaves zijn lokaal in client en servercontract gebouwd. Alle nieuwe tabellen blijven via RLS en ingetrokken tabelrechten afgeschermd; tijdelijke chatdata heeft vijfminuten-Cron plus opportunistische cleanup; Aerie-progressie kan door maximaal twintig bijdragen per UTC-dag niet sneller dan 192 dagen naar fase 10. De eerste stagingpoging paste migratie 30 toe en stopte vóór E2E op twee lintambiguïteiten; migratie 31 herstelt die idempotent, terwijl productie onaangeraakt op 29/29 blijft. |
| 31-08-2026 | Lokale clientcorrecties na v0.04.16 | Codex | `house_screen.dart`, `profile_portrait_sprite.dart`, `notification_service.dart`, `notification_settings_screen.dart`, `MainActivity.kt`, `DragonHavenAlarmScheduler.kt` en regressietests | Geplaatste Supporter-furniture wordt uit de volledige catalogus gerenderd; het Founding Supporter Portrait gebruikt dezelfde schaal als andere portraits. De oude algemene vertraging van twee minuten en de extra Adventure-seconde zijn verwijderd: eieren, Adventures, volle Trials en Special Events worden op hun exacte spelgrens gepland. Android 12+ controleert expliciete alarmtoegang, biedt een Play-geschikte `SCHEDULE_EXACT_ALARM`-instellingenroute en plant lopende timers opnieuw bij een toestemmingswijziging, toestelherstart, app-update of klok-/tijdzonewijziging; reeds verlopen meldingen worden niet alsnog te laat getoond. Analyzer, 347/347 tests en Android-debugbuild zijn groen; versie 0.4.16, productie 29/29 en de openbare release zijn onaangeraakt. |
| 31-08-2026 | v0.05.00 lokale releasecandidate | Codex, na jouw toestemming | `release-notes-v0.05.00.md`, migraties 30–31, `production-migrate-31.yml`, uitgebreide `staging_social_e2e.ps1` en ondertekende APK | App- en zichtbare versie staan op v0.05.00 met versionCode 10050; analyzer en 347/347 tests zijn groen. De lokale productie-APK heeft package `nl.dragonhaven.app`, het vaste releasecertificaat en de juiste versie; staging, productie en publicatie volgen nog via de externe gates. |
| 31-08-2026 | v0.05.00 releasecandidate op staging | Codex | [Stagingrun 33396777406](https://github.com/Rakky88/DragonHaven/actions/runs/33396777406) | Na een veilig gestopte eerste lintpoging zijn migraties 30–31, database-lint/preflight, Friend Messages, Conclaves, Friends, trade, volledige Group Adventure completion/reward/replay, analyzer, 347 tests, geïsoleerde staging-APK en cleanup groen bewezen. Productie bleef tijdens de correctie onaangeraakt. |
| 31-08-2026 | Productiemigraties 30–31 en onafhankelijke preflight | Codex, na jouw toestemming | [Migratierun 33397552524](https://github.com/Rakky88/DragonHaven/actions/runs/33397552524), `tool/release_server_preflight.ps1` | Exacte beginstand 29, publieke healthcheck, database-lint en dry-run groen; uitsluitend migraties 30–31 toegepast. Daarna 31/31 parity, 0 database-lintfouten, Auth health/settings 200/200 en geconfigureerde e-mailauth op project `tnzathhutuwmohmjfrlo` bewezen. |
| 31-08-2026 | Openbare release v0.05.00 | Codex, na jouw toestemming | [Release](https://github.com/Rakky88/DragonHaven/releases/tag/v0.05.00), [productiegate 33397872901](https://github.com/Rakky88/DragonHaven/actions/runs/33397872901), [taggate 33398718801](https://github.com/Rakky88/DragonHaven/actions/runs/33398718801) | Exact commit `603648c7eb1224ea855b616b7c1729e7839c9da8` getagd. Ondertekende APK van 366.785.471 bytes gepubliceerd; SHA-256 `c0f431393f41c03b6c111e403d7ba465bbe1bbd6318345cf57610e7548c92592`; package `nl.dragonhaven.app`, versionCode 10050 en vast releasecertificaat `477c5a5d7453384ca756265e77af97d5a002a907177ccd2d9065a9bec3414942` bewezen. Beide productiepreflights, 347 tests, compacte/reduced-motion emulatorcontrole en Play-ready AAB zijn groen; versiegebonden en permanente latest-download geven HTTP 200 en hetzelfde GitHub-asset. |
| 31-08-2026 | Post-release productiehealth v0.05.00 | Codex | [Healthrun 33399531445](https://github.com/Rakky88/DragonHaven/actions/runs/33399531445) | Publieke productie-endpoints direct na v0.05.00 opnieuw groen; bewijsartifact geüpload, productie staat op 31/31 migraties en er is geen storingsalert geopend. |
| 31-08-2026 | M1 read-only applicatiehealth gebouwd en op staging bewezen | Codex | migratie `202608310032_public_application_health.sql`, `public_server_health_check.ps1`, `release_server_preflight.ps1`, `test_public_application_health.ps1`, `production-migrate-32.yml`, `dragonhaven_spec_test.dart` en [stagingrun 33402550922](https://github.com/Rakky88/DragonHaven/actions/runs/33402550922) | Een publieke `security invoker`-RPC zonder tabelreads retourneert uitsluitend vaste servicestatus, contractversie en servertijd. De monitor valideert HTTP-status, exact contract en maximaal vijf minuten klokafwijking; productiepreflight eist de check na migratie 32. Stagingmigratie/lint/preflight, positieve/negatieve parsertests, volledige sociale en Group Adventure-E2E, live productie-Auth 200/200, analyzer, 348/348 tests en staging-APK zijn groen. Productie blijft 31/31; alleen productieactivatie en testalert wachten nog. |

## Onderhoud van dit plan

Werk na iedere relevante release minimaal de uitgangsversie, statusvakjes,
besluitenlog, voortgangslog en releasepoorten bij. Controleer ook of
`PUBLIC_LAUNCH.md`, `SERVER_IMPROVEMENTS.md`, `DISTRIBUTION.md` en de actuele
audit nog naar dezelfde werkelijkheid verwijzen. Geen afgevinkte taak mag alleen
op aannames rusten: voeg altijd een test, workflowrun, dashboard, migratiebewijs
of expliciet gebruikersbesluit toe.
