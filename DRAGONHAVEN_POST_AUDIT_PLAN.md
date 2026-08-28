# DragonHaven verbeterplan na audit v0.04.06

Laatst opgesteld: **28 augustus 2026**  
Technische uitgangsversie: **v0.04.06**  
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

- [ ] De release-AAB bouwen en package name, versie, signingcertificaat en hash
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
- [ ] Documenteer herstel bij een mislukte serverpreflight of signingcheck.

### Jij

- [ ] Plaats rechtstreeks in GitHub Actions Secrets:
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

- [ ] Een handmatige CI-run analyse, alle tests, serverpreflight en een
  ondertekende `DragonHaven.aab` volledig groen afrondt.
- [ ] Het signingcertificaat exact overeenkomt met bestaande DragonHaven-
  releases en geen secretwaarde in logs of artifacts staat.
- [ ] Het verificatierapport aan de run gekoppeld is.

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
- [ ] Maak dashboards of dashboardspecificaties voor:
  - Auth-foutpercentage, verificatie en loginlatency;
  - RPC-foutpercentage en p50/p95/p99-latency;
  - trade- en Group Adventure-fouten;
  - databaseverbindingen, CPU, opslag en egress;
  - back-upsuccessen, revision conflicts en restore-uitkomsten;
  - actieve appversies en client/servercompatibiliteit.
- [ ] Voeg synthetische healthchecks toe voor publieke Auth en een veilige,
  read-only applicatiecheck.
- [x] Schrijf een incidentrunbook met ernstniveaus, triage, rollback,
  communicatie en controle na herstel.
- [x] Voeg tests toe die bewijzen dat gevoelige data wordt geredigeerd.

### Jij

- [ ] Maak en bezit het gekozen monitoring/Firebase-project en registreer
  `nl.dragonhaven.app`.
- [ ] Kies in eerste instantie het gratis plan en zet budgetmeldingen aan waar
  de provider dat ondersteunt; een upgrade vereist een apart besluit.
- [ ] Kies wie waarschuwingen ontvangt, tijdens welke uren en via welk kanaal.
- [ ] Stel maandbudget, datalocatie en bewaartermijn in.
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
- [ ] Laat lokale tests en GitHub Actions zoveel mogelijk werk afvangen voordat
  een externe stagingresource wordt belast.
- [ ] Maak reproduceerbare stagingmigraties, testdata en veilige opruimlogica.
- [ ] Automatiseer minimaal deze volledige flow:
  1. signup;
  2. e-mailbevestiging;
  3. eerste login en accountbootstrap;
  4. cloudback-up en restore;
  5. Friends request en acceptatie;
  6. trade reserveren, accepteren en afronden;
  7. Group Adventure aanmaken, deelnemen en afronden.
- [ ] Voeg scenario's toe voor timeout, offline/online wissel, verlopen sessie,
  dubbele request, appherstart en een halverwege mislukte actie.
- [ ] Maak een loadtestprofiel dat snapshotpolling en echte gebruikersacties
  combineert; geen onrealistische constante spam.
- [ ] Laat de test eerst op 100 en daarna 1.000 gelijktijdige synthetische
  gebruikers draaien. Test 5.000–10.000 pas na kosten- en capaciteitsgoedkeuring.
- [ ] Rapporteer p95/p99, foutpercentages, databasebelasting, verbindingen,
  egress en gevonden query/indexproblemen.

### Jij

- [ ] Maak een afzonderlijk Supabase-stagingproject onder jouw account.
- [ ] Start daarvoor met de gratis tier zolang de geplande tests binnen de
  actuele limieten passen.
- [ ] Configureer een staging-e-mailroute/inbox waarmee bevestigingslinks veilig
  geautomatiseerd kunnen worden.
- [ ] Voeg stagingcredentials rechtstreeks als afgeschermde GitHub Environment
  Secrets toe en vereis zo nodig jouw goedkeuring voor runs.
- [ ] Bepaal het testbudget en keur iedere test boven 1.000 gelijktijdige
  gebruikers vooraf goed.
- [ ] Bevestig dat synthetische accounts en testmailadressen geen echte
  persoonsgegevens bevatten.

### Samen klaar wanneer

- [ ] De volledige flow herhaalbaar slaagt op een lege stagingdatabase.
- [ ] Een migratie vanaf de vorige productieschemaversie ook slaagt.
- [ ] Foutscenario's geen dubbele reward, item, trade of Group Adventure
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

- [ ] Breid back-ups uit met save-ID, parent revision, apparaat-ID,
  clientversie, schema-versie en servertijd.
- [ ] Laat de server een verouderde `expectedRevision` atomair weigeren en
  retourneer een specifiek conflict in plaats van een algemene fout.
- [ ] Bouw een conflictvenster met drie veilige acties: cloud bekijken,
  huidige lokale staat behouden/uploaden na bevestiging, of cloud herstellen.
- [ ] Houd een beperkt aantal herstelbare serverrevisies bij volgens de gekozen
  bewaartermijn.
- [ ] Splits later server-owned economievelden af zodat een oude save nooit
  valuta of items kan terugzetten of dupliceren.
- [ ] Maak automatische integratietests met twee apparaten en overlappende
  uploads/restores.
- [ ] Voeg een periodieke restore-test en controle op save-integriteit toe.

### Jij

- [ ] Kies bewaartermijn en aantal herstelrevisies.
- [ ] Kies of back-up handmatig blijft of ook automatisch op veilige momenten
  gebeurt.
- [ ] Bevestig de conflictteksten en welke voortgangssamenvatting voor spelers
  begrijpelijk is.
- [ ] Kies RPO en RTO: hoeveel voortgang maximaal verloren mag gaan en binnen
  welke tijd herstel mogelijk moet zijn.
- [ ] Wijs iemand aan die periodieke restore-resultaten controleert.

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
- [ ] Bouw een versieerbaar eenmalig importpad voor bestaande saves met
  validatie, limieten, rapportage en rollback.
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
  lokale bouwtranche (252/252 op 28-08-2026);
- [ ] negatieve, timeout-, retry- en replaypaden zijn getest;
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
3. **Jij:** vul de zes GitHub Actions-secrets uit fase 0 rechtstreeks in.
4. **Codex:** voer daarna M0 uit en bewijs een volledig groene handmatige
   AAB-workflow zonder een release te publiceren.
5. **Jij:** maak het gekozen monitoringproject en een apart Supabase-
   stagingproject aan, beide eerst op een geschikt gratis plan.
6. **Codex:** implementeer M1 en M2 verder, inclusief externe monitoring en
   echte staging-E2E-tests.
7. **Samen:** beoordeel de meetresultaten en leg pas daarna grenzen voor
   capaciteit, alerts en publieke uitrol vast.

## Besluitenlog

| Datum | ID | Besluit | Reden | Gevolg voor plan |
| --- | --- | --- | --- | --- |
| 28-08-2026 | B1 | Lokale weergave en gameplay blijven offline bruikbaar; toekomstige waardevolle online claims en mutaties worden server-authoritative | Eerlijkheid combineren met offline speelbaarheid | M4 mag deze grens als uitgangspunt gebruiken |
| 28-08-2026 | B2 | Bestaande saves krijgen één gelogde import met plausibiliteitslimieten en daarna server-lock; bestaande voortgang wordt nooit stil verwijderd | Veilige overgang zonder trouwe spelers voortgang af te nemen | Importprotocol en compatibiliteitstests mogen worden gebouwd |
| 28-08-2026 | B6-back-up | Per account de laatste vijf cloudrevisies maximaal dertig dagen bewaren | Voldoende herstelruimte met beperkte gratis opslag en privacy-impact | Back-uphistorie, opschoning en herstelkeuze mogen worden gebouwd |
| Nog te bepalen | B3–B5, overige B6 en B7 | Nog niet bevestigd | Beslissen vlak vóór de afhankelijke fase | Alleen de nog afhankelijke delen van M3–M6 wachten |

## Voortgangslog

| Datum | Mijlpaal/taak | Uitgevoerd door | Bewijs of link | Resultaat/vervolg |
| --- | --- | --- | --- | --- |
| 28-08-2026 | Uitgangsaudit v0.04.06 | Codex | `DRAGONHAVEN_AUDIT_2026-08-28.md` | Basis groen; resterende grenzen in dit plan verwerkt |
| 28-08-2026 | M0 workflowhardening | Codex | `.github/workflows/release.yml` | Vroege secretcheck, pubspec-versionCode, AAB-hash/certificaat en bewijsrapport gebouwd; echte CI-run wacht op zes GitHub-secrets |
| 28-08-2026 | M1 gratis diagnostiekbasis | Codex | `lib/services/diagnostic_reporter.dart`, `INCIDENT_RUNBOOK.md` | Supportcodes, veilige export, redactiontests en handmatige healthworkflow gebouwd |
| 28-08-2026 | Productiepreflight na healthrefactor | Codex | `tool/release_server_preflight.ps1` | 20/20 migraties, 0 lintfouten, Auth 200/200; eerste health 24,5 s, clienttimeout daarom 75 s |
| 28-08-2026 | M2 stagingafscheiding | Codex | `.github/workflows/staging.yml`, `lib/config/online_config.dart` | Production/staging/local veilig gescheiden; echte run wacht op gratis stagingproject en secrets |
| 28-08-2026 | M3 conservatieve conflictbeveiliging | Codex | `OnlineAccountProvider`, `StorageService`, `AccountScreen` | Stil cloudoverschrijven geblokkeerd; restore/lokaal-doorgaan gebouwd, force-overwrite wacht op retentie- en historiebeleid |
| 28-08-2026 | Uitgestelde payment-ready grens | Codex | `lib/services/purchase_provider.dart` | Twaalf interne product-ID's en server-verified contract; geen Billing-SDK, liveproducten of kosten geactiveerd |
| 28-08-2026 | Volledige lokale kwaliteitscontrole | Codex | `flutter analyze --no-pub`, `flutter test --no-pub` | Analyzer zonder issues; 252/252 tests geslaagd nadat Android Studio was gesloten |
| 28-08-2026 | Lokalisatie support- en cloudteksten | Codex | `lib/l10n/release_phrase_translations.dart`, `test/localization_completeness_test.dart` | Twaalf nieuwe vaste teksten in alle zes aanvullende talen toegevoegd; 10/10 lokalisatiecontroles geslaagd |

## Onderhoud van dit plan

Werk na iedere relevante release minimaal de uitgangsversie, statusvakjes,
besluitenlog, voortgangslog en releasepoorten bij. Controleer ook of
`PUBLIC_LAUNCH.md`, `SERVER_IMPROVEMENTS.md`, `DISTRIBUTION.md` en de actuele
audit nog naar dezelfde werkelijkheid verwijzen. Geen afgevinkte taak mag alleen
op aannames rusten: voeg altijd een test, workflowrun, dashboard, migratiebewijs
of expliciet gebruikersbesluit toe.
