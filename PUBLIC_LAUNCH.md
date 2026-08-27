# DragonHaven openbaar lanceren

Laatst gecontroleerd: **27 augustus 2026**

Huidige appversie bij deze controle: **v0.04.03**
Android package name: **`nl.dragonhaven.app`**

Dit is de centrale, levende checklist voor een openbare lancering van
DragonHaven. Bedragen zijn exclusief btw, marketing, klantenservice, juridische
hulp en ontwikkeltijd. Prijzen en store-eisen kunnen veranderen; controleer
voor betaling of publicatie altijd de officiële links onderaan.

## Kort antwoord

Een besloten Android-test kan vrijwel zonder extra maandelijkse kosten. Voor
een serieuze openbare Android-lancering is een realistische technische
ondergrens:

- **US$ 25 eenmalig** voor een Google Play Console-account;
- **US$ 25–45 per maand** voor Supabase Pro plus eventuele productie-e-mail;
- ongeveer **€10–30 per jaar** voor een eigen domein;
- Firebase Cloud Messaging en Crashlytics kunnen in eerste instantie gratis;
- Apple kost pas extra wanneer ook een iPhone/iPad-versie wordt uitgebracht:
  doorgaans **US$ 99 per jaar** voor het Apple Developer Program.

Die ondergrens is geschikt voor een kleine lancering, niet automatisch voor
miljoenen spelers. Verbruik, databasecapaciteit, e-mail, support en monitoring
moeten daarna met het werkelijke gebruik meegroeien.

## Wat al gereed is

- De Android-app heeft een blijvende package name en een vaste release-key.
- Er wordt zowel een gesigneerde APK als een gesigneerde Android App Bundle
  gebouwd. Google Play gebruikt de AAB.
- De releaseprocedure controleert vóór elke release de live Supabase-migraties,
  database-lint, Auth-health en e-mailconfiguratie.
- Bij v0.04.03 waren alle 18 database-migraties gelijk, waren er geen remote
  lintfouten en werkten de gecontroleerde Auth/e-mail-endpoints.
- E-mailaccounts, verificatie, Friends, Trades, globale Group Adventures,
  profielsamenvattingen en cloudback-ups gebruiken Supabase.
- Row Level Security en server-RPC's beschermen de bestaande online sociale
  functies en trades.
- Wachtwoorden worden door Supabase Auth verwerkt en gehasht; DragonHaven hoort
  geen leesbare wachtwoorden in de app of eigen tabellen te bewaren.
- De app bevat een bevestigde, met wachtwoord beveiligde verwijdering van het
  online account.
- Online snapshots zijn gebundeld in één periodieke synchronisatie en worden
  op de achtergrond minder vaak opgehaald. Profiel-, showcase- en
  inventory-snapshots worden alleen geschreven wanneer ze zijn veranderd.
- Lokale save recovery en een handmatige, bevestigde cloudback-up bestaan.
- De releaseworkflow kan een Play-ready AAB als gecontroleerd artifact bouwen.

## Wat nog geen productiegarantie heeft

Deze punten blokkeren niet allemaal een kleine besloten test, maar horen vóór
een grote openbare lancering te zijn opgelost.

- De kernprogressie is nog **offline-first**. Een deel van rewards, chests,
  eggs, shoptransacties en inventory ontstaat nog op het toestel. Daardoor kan
  een aangepaste client in theorie ongeldige voortgang naar online snapshots
  sturen. Voor een eerlijke publieke economie moeten alle waardevolle mutaties
  server-authoritative worden.
- De huidige notificaties zijn lokale notificaties en opgehaalde server-inbox-
  meldingen. Echte push wanneer de app volledig gesloten is vereist Firebase
  Cloud Messaging of een gelijkwaardige pushdienst.
- De standaard Supabase-maildienst is niet bedoeld als volwaardige
  productie-afzender. Een eigen SMTP-provider en correct ingestelde DNS zijn
  nodig voor betrouwbare verificatie- en herstelmails.
- Naast de verwijderknop in de app vereist Google Play ook een openbare
  verwijderpagina op het web.
- Er is nog geen publiek gehoste privacyverklaring/supportpagina vastgelegd.
- Crash- en performance-monitoring moeten nog aan een productieproject worden
  gekoppeld.
- Er is nog geen reproduceerbare loadtest uitgevoerd tegen een aparte
  stagingomgeving.
- Er is geen iOS-project in deze Windows-workspace. Een iOS-release vraagt een
  Mac, Apple-account, signing/provisioning en afzonderlijke storecontrole.

## Verplichte checklist voor Google Play

| Onderdeel | Wie moet dit doen? | Status/actie |
|---|---|---|
| Play Console-account kopen en identiteit verifiëren | Jij | US$ 25 eenmalig; kies persoonlijk of organisatie. |
| Android-apparaat- en eventuele organisatieverificatie afronden | Jij | Volg de actuele Play Console-prompts. |
| Package name `nl.dragonhaven.app` registreren/verifiëren | Jij, met technische hulp van Codex | Vanaf 30 september 2026 wordt package-nameverificatie breder verplicht. |
| App in Play Console aanmaken | Jij | Naam, standaardtaal, gratis/betaald en verklaringen kiezen. |
| Play App Signing activeren en AAB uploaden | Jij; Codex bouwt/controleert de AAB | Gebruik nooit een ander application ID of een onverwachte release-key. |
| Closed test afronden indien die voor het account geldt | Jij organiseert testers | Nieuwe persoonlijke accounts vallen doorgaans onder de eis van minimaal 12 testers gedurende 14 aaneengesloten dagen. Controleer wat jouw Console toont. |
| Store listing | Jij beslist; Codex kan tekst en beelden voorbereiden | Titel, korte/lange beschrijving, icoon, feature graphic, screenshots, supportcontact. |
| Content rating, doelgroep/leeftijd, ads en app access | Jij verklaart | Antwoorden moeten overeenkomen met de echte app. |
| Data Safety-formulier | Jij blijft verantwoordelijk; Codex kan inventariseren | Beschrijf account-, profiel-, vrienden-, inventory-, diagnostische en notificatiedata correct. |
| Openbare privacyverklaring | Jij bent verwerkingsverantwoordelijke; Codex kan pagina integreren | Publieke HTTPS-URL en link vanuit de app/store. |
| Openbare accountverwijderpagina | Jij levert domein/hosting; Codex kan de flow bouwen | Naast de bestaande in-app verwijdering. |
| Productielanden en releasepad kiezen | Jij | Begin bij voorkeur met een kleine staged rollout. |
| Betalingen voor digitale goederen | Jij opent merchant/betalingsprofiel; Codex implementeert billing | Alleen nodig als gems of andere digitale goederen voor echt geld worden verkocht. Gebruik dan Google Play Billing en server-side aankoopverificatie. |

Let op: de AAB van v0.04.01 is ongeveer **279,3 MiB**. Dat past onder de
500-MB-limiet voor een base module, maar ligt boven de 200-MB-grens waarbij
Google Play een grote-downloadwaarschuwing kan tonen. Voor bereik en
installatieconversie is verdere compressie en/of Play Asset Delivery sterk aan
te raden.

## Wat jij zelf moet regelen

Codex kan code, migraties, tests, documentatie, afbeeldingen, builds en
configuratievoorstellen maken. De volgende handelingen moeten onder jouw naam
of accounts gebeuren:

1. Een Play Console-account bezitten, betalen, voorwaarden accepteren en je
   identiteit verifiëren.
2. Beslissen of je publiceert als persoon of organisatie en wie juridisch de
   app en persoonsgegevens beheert.
3. De privacy-, doelgroep-, content-rating-, advertentie-, handels- en
   landenverklaringen naar waarheid indienen.
4. Een domein en eventueel een supportmailbox beheren.
5. Een SMTP-provider kiezen, betaalgegevens beheren en SPF, DKIM en DMARC bij
   je DNS-provider instellen.
6. Een Firebase-project bezitten en de Android-app met package name
   `nl.dragonhaven.app` registreren. Codex kan daarna FCM en Crashlytics in de
   code koppelen.
7. Eventuele merchant-, belasting- en uitbetalingsgegevens invullen wanneer
   echte aankopen worden toegevoegd.
8. Testers uitnodigen en de vereiste testperiode werkelijk laten doorlopen.
9. Een supportproces beheren voor verwijderverzoeken, privacyvragen,
   verloren accounts, refunds en misbruikmeldingen.

Plaats private sleutels, het databasewachtwoord, service-accountbestanden en de
Android-keystore nooit in Git of openbare documentatie. De Supabase-project-URL
en publishable key mogen in een client staan; de service-role key en het
databasewachtwoord absoluut niet. Omdat databasegegevens tijdens ontwikkeling
zijn gebruikt, is het verstandig het productie-databasewachtwoord en alle ooit
gedeelde private secrets vóór de openbare lancering één keer te roteren.

## Wat Codex daarna kan uitvoeren

Zodra de accounts en keuzes hierboven beschikbaar zijn, kan Codex onder meer:

- een privacy- en accountverwijderwebsite in het project voorbereiden;
- de links en teksten in app, Play listing en Data Safety-inventaris op elkaar
  laten aansluiten;
- Firebase Cloud Messaging en pushvoorkeuren implementeren;
- Crashlytics/performance-monitoring implementeren zonder gevoelige speldata
  onnodig mee te sturen;
- custom SMTP en redirect-URL's controleren;
- reward-, chest-, egg-, shop- en inventorymutaties ombouwen naar idempotente
  server-RPC's;
- server-side aankoopverificatie voor Google Play Billing toevoegen;
- een staging-Supabase-project en geautomatiseerde loadtests maken;
- de assets analyseren, comprimeren en waar passend naar Play Asset Delivery
  verplaatsen;
- storeteksten, screenshots, feature graphic, testnotities en rolloutchecklists
  voorbereiden;
- de bestaande releasepreflight uitbreiden met privacy-, configuratie- en
  artifactcontroles.

## Aanbevolen server-authoritative economie

Voor een openbare game moet de server uiteindelijk de waarheid zijn voor alles
wat waarde heeft. Een veilige mutatie ziet er globaal zo uit:

1. De client vraagt een actie aan, bijvoorbeeld `open_chest(chest_instance_id,
   request_id)`.
2. De server controleert de ingelogde gebruiker, ownership, reserveringen,
   limieten en eerdere verwerking van hetzelfde `request_id`.
3. De server rolt de reward en past chest, inventory, valuta, dragon en auditlog
   in één databasetransactie aan.
4. De server retourneert alleen het definitieve resultaat; de client animeert
   dat resultaat maar bepaalt het niet.
5. Herhaalde of vertraagde requests leveren hetzelfde resultaat op en kunnen
   geen dubbele reward maken.

Pas dit minimaal toe op:

- chest opening en pity;
- eggs ontvangen, reserveren, traden en uitbroeden;
- coins, gems, relics en aankopen;
- adventure- en Trial-rewards;
- expertise/XP/levels en achievements met economische rewards;
- daily limits, trade limits en claimbare beloningen;
- cloud-restoreconflicten.

Bewaar voor belangrijke mutaties een auditlog met user ID, actie, request ID,
bron, verschil vóór/na en servertijd. Geef de client nooit toegang tot een
service-role key.

## E-mail, notificaties en monitoring

### Productie-e-mail

- Gebruik een eigen afzenderdomein, bijvoorbeeld `mail.dragonhaven...`.
- Stel SPF, DKIM en DMARC in.
- Configureer in Supabase de juiste Site URL en toegestane redirect-URL's.
- Test verificatie, opnieuw versturen, wachtwoordherstel, verlopen links en
  accountverwijdering op een fysiek toestel.
- Houd bounce- en spampercentages in de gaten.

### Pushnotificaties

FCM is nodig voor betrouwbare meldingen wanneer DragonHaven niet actief is,
zoals friend requests, acceptaties, tradefases en drie beschikbare Trials.
Bewaar per toestel een roteerbaar push-token, respecteer de bestaande
notificatievoorkeuren en verwijder ongeldige tokens. Stuur geen gevoelige
inventory-inhoud in het zichtbare pushbericht.

### Monitoring

Minimaal aanbevolen dashboards/alerts:

- crash-free users en app-startfouten;
- Auth-fouten, e-mail delivery en verificatiepercentages;
- database CPU, verbindingen, latency, opslag en egress;
- RPC-foutpercentage en p95/p99-latency;
- dubbele of mislukte trade/rewardmutaties;
- backupstatus en een periodiek geteste restore;
- releaseversie, servermigratie en client/servercompatibiliteit.

## Capaciteit en loadtests

Er is geen eerlijk vast getal voor “hoeveel gebruikers tegelijk” zonder een
loadtest. MAU, gelijktijdige sessies en requests per seconde zijn verschillende
maten. Na de snapshotoptimalisatie doet een continu geopende app in de
achtergrond ongeveer één gebundelde online refresh per twee minuten. Als 1.000
gebruikers precies tegelijk actief blijven, is dat gemiddeld ongeveer **8,3
snapshotrequests per seconde**, naast directe acties zoals trades, friends en
Group Adventures. Eén snapshot kan intern meerdere databasequeries uitvoeren.

Test vóór openbare uitrol ten minste:

| Scenario | Doel |
|---|---|
| 100 gelijktijdige gebruikers | Functionele baseline en queryprofielen |
| 1.000 gelijktijdige gebruikers | Verwachte vroege piek met realistische acties |
| 5.000–10.000 gelijktijdige gebruikers | Capaciteitsgrens, pooling, indexes en rate limits |
| Hersteltest | Backup terugzetten en data-integriteit controleren |
| Misbruiktest | Request replay, dubbele claims, brute force en rate limiting |

Gebruik een apart stagingproject met synthetische accounts; belast de
productiedatabase niet zomaar. Meet daarna pas welke Supabase-compute nodig is.

## Kostenraming

### Vaste en vroege kosten

| Onderdeel | Indicatie | Opmerking |
|---|---:|---|
| Google Play Console | US$ 25 eenmalig | Android-publicatie |
| Apple Developer Program | US$ 99/jaar | Alleen nodig voor iOS/iPadOS |
| Supabase Pro | vanaf circa US$ 25/maand | Aanbevolen boven een hobby/besloten test |
| Custom SMTP | US$ 0–20/maand bij klein volume | Afhankelijk van provider en e-mailvolume |
| Firebase Cloud Messaging | US$ 0 | Pushdienst zelf is no-cost |
| Firebase Crashlytics | US$ 0 | Crashrapportage zelf is no-cost |
| Domein | circa €10–30/jaar | Schatting; extensie/provider bepalen prijs |
| Statische privacy/delete-site | vaak €0–10/maand | Schatting; kan vaak gratis worden gehost |
| Juridische controle | €0 voor eigen werk tot honderden/duizenden euro's | Optioneel maar verstandig bij commerciële of kindgerichte lancering |
| Marketing en support | niet inbegrepen | Kan uiteindelijk groter zijn dan hosting |

### Ruwe maandraming bij groei

Dit zijn **planningsbandbreedtes**, geen offerte of capaciteitsgarantie. Ze
veronderstellen dat queries efficiënt zijn, assets grotendeels via de store/CDN
komen en e-mail/push geen onverwacht hoog volume heeft.

| Gebruik | Ruwe infra-indicatie per maand |
|---|---:|
| Tot circa 10.000 MAU | US$ 25–75 |
| Circa 100.000 MAU | US$ 75–350 |
| Circa 1 miljoen MAU | US$ 4.000–10.000 |
| Circa 10 miljoen MAU | US$ 40.000–100.000+ |

Waarom de sprong groot wordt: Supabase Pro bevat volgens de huidige prijspagina
100.000 MAU. Boven die bundel wordt Auth per extra MAU berekend. Bij een tarief
van US$ 0,00325 zou alleen de Auth-MAU-overage bij 1 miljoen MAU ongeveer
`(1.000.000 - 100.000) × 0,00325 = US$ 2.925 per maand` zijn. Compute,
databaseopslag, egress, e-mail, observability en support komen daar nog bij.

Supabase Pro bevat ook beperkte compute credits; zwaardere compute-instances
kosten extra. Kies de instance pas na metingen. Scheid grote game-assets van de
database en voorkom onnodig vaak pollen, want egress en querybelasting kunnen
sneller groeien dan het aantal geregistreerde accounts.

### Storecommissie bij echte aankopen

Een gratis app zonder in-app aankopen betaalt geen percentage over downloads.
Wanneer DragonHaven digitale goederen verkoopt, kunnen Google Play- en
Apple-servicefees gelden. Google vermeldt voor deelnemende ontwikkelaars onder
meer een 15%-tarief over de eerste US$ 1 miljoen jaarlijkse omzet en andere
tarieven daarboven of per productcategorie. Controleer het actuele programma
en laat belasting-/consumentenregels beoordelen voordat betalingen live gaan.

## Aanbevolen lanceringsvolgorde

### Fase 1 — eigendom en beleid

- [ ] Play Console-account en identiteit gereed
- [ ] domein, supportadres en juridische eigenaar gekozen
- [ ] doelgroep/leeftijd, landen, verdienmodel en moderatiebeleid gekozen
- [ ] privacyverklaring en verwijderpagina publiek bereikbaar
- [ ] alle tijdens ontwikkeling gebruikte private secrets geroteerd

### Fase 2 — productie-infrastructuur

- [ ] Supabase Pro en productiechecklist beoordeeld
- [ ] custom SMTP, SPF, DKIM, DMARC en Auth redirects getest
- [ ] FCM en Crashlytics gekoppeld
- [ ] backups en een geteste restoreprocedure ingericht
- [ ] rate limits, alerts en incidentcontact ingericht
- [ ] waardevolle economieacties server-authoritative of bewust buiten de
      publieke build gehouden

### Fase 3 — store en gesloten test

- [ ] AAB-grootte verder geoptimaliseerd
- [ ] store listing, screenshots en Data Safety ingevuld
- [ ] interne test voltooid
- [ ] vereiste closed test met voldoende testers voltooid
- [ ] testmatrix op recente en oudere Android-versies uitgevoerd
- [ ] accountregistratie, verificatie, recovery en deletion end-to-end getest

### Fase 4 — gecontroleerde productie-uitrol

- [ ] serverpreflight en databaseback-up vlak vóór release
- [ ] starten met kleine staged rollout, bijvoorbeeld 1–5%
- [ ] crashes, Auth, database, e-mail en support dagelijks volgen
- [ ] pas verhogen naar 20%, 50% en 100% wanneer metrics gezond blijven
- [ ] rollback-/hotfixprocedure vooraf klaarzetten

### Fase 5 — schaal

- [ ] loadtest herhalen met echt verkeersprofiel
- [ ] compute, pooling, indexes, cache en CDN op meetgegevens aanpassen
- [ ] abuse/fraudcontrole en serveraudit uitbreiden
- [ ] kostenalerts en maandbudget instellen
- [ ] support, privacyverzoeken en incidentrespons opschalen

## iOS later

Een iOS-release is een apart traject. Nodig zijn minimaal:

- Apple Developer Program-lidmaatschap;
- toegang tot macOS/Xcode en een iPhone voor echte toesteltests;
- iOS bundle ID, signing certificates en provisioning;
- Apple pushconfiguratie;
- App Store Connect listing, privacylabels en review;
- StoreKit plus server-side verificatie als digitale aankopen worden verkocht.

De Flutter-code is grotendeels herbruikbaar, maar plugins, notificaties,
achtergrondgedrag, audio, permissions en layouts moeten op iOS apart worden
getest.

## Officiële bronnen

- [Google Play Console-account en registratiekosten](https://support.google.com/googleplay/android-developer/answer/6112435)
- [Google Play closed-testingeisen voor nieuwe persoonlijke accounts](https://support.google.com/googleplay/android-developer/answer/14151465)
- [Een app opzetten in Play Console](https://support.google.com/googleplay/android-developer/answer/9859152)
- [Google Play package-nameverificatie vanaf 2026](https://support.google.com/googleplay/android-developer/answer/16984799)
- [Google Play target-API-eisen](https://support.google.com/googleplay/android-developer/answer/11926878)
- [Google Play Data Safety](https://support.google.com/googleplay/android-developer/answer/10144311)
- [Google Play accountverwijdering](https://support.google.com/googleplay/android-developer/answer/13327111)
- [Google Play appgrootte en downloads](https://support.google.com/googleplay/android-developer/answer/9859372)
- [Google Play servicefees](https://support.google.com/googleplay/android-developer/answer/11131145)
- [Apple Developer Program](https://developer.apple.com/programs/)
- [Supabase-prijzen](https://supabase.com/pricing)
- [Supabase compute en kosten](https://supabase.com/docs/guides/platform/manage-your-usage/compute)
- [Supabase-productiechecklist](https://supabase.com/docs/guides/deployment/going-into-prod)
- [Supabase custom SMTP](https://supabase.com/docs/guides/auth/auth-smtp)
- [Firebase-prijzen](https://firebase.google.com/pricing)
- [Firebase-prijsplannen en no-cost producten](https://firebase.google.com/docs/projects/billing/firebase-pricing-plans)
- [Android App Bundle FAQ](https://developer.android.com/guide/app-bundle/faq)

## Bijwerken van dit document

Controleer vóór iedere storelancering ten minste de datum, appversie,
artifactgrootte, Play/Apple-eisen, Supabase-bundels en servicefees. Werk na een
loadtest de capaciteits- en kostenramingen bij met gemeten p95/p99-latency,
databasebelasting, egress en werkelijk gelijktijdige gebruikers.
