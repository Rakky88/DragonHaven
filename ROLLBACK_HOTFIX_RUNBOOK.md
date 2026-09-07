# DragonHaven rollback- en hotfixrunbook

Laatst bijgewerkt: **7 september 2026**
Uitgangsstand: **app v0.05.17, productie/staging 47, lokale kandidaat 49**

## Doel en harde grens

Dit runbook beschrijft hoe DragonHaven een defecte apprelease of serverwijziging
veilig herstelt. Een app- of productiedatabasewijziging blijft altijd een aparte
externe handeling met expliciete toestemming. Het runbook geeft dus geen
doorlopende toestemming om releases te publiceren, migraties toe te passen,
spelersdata te wijzigen of een Play-rollout te bedienen.

DragonHaven gebruikt twee herstelvormen:

- **app fix-forward:** publiceer een nieuw, hoger versienummer en hogere
  `versionCode`; vervang of downgrade een al geïnstalleerde app nooit stil;
- **database fix-forward:** verander een toegepaste migratie nooit achteraf,
  maar voeg een nieuwe correctiemigratie toe.

Een echte datarestore is alleen het laatste middel. Stop vóór iedere
destructieve handeling wanneer doel, herstelbron, verliesvenster of toestemming
niet exact vaststaat.

## Eerste vijf minuten

1. Maak een willekeurige incident-ID in het formaat `DH-INC-YYYYMMDD-XXX` en
   noteer starttijd in UTC.
2. Classificeer via `INCIDENT_RUNBOOK.md`: SEV-1, SEV-2 of SEV-3.
3. Controleer openbare Auth- en applicatiehealth zonder spelersdata op te halen.
4. Leg de actuele appversie, releasetag, commit, productie-migratiestand en de
   laatste geslaagde staging-/releaseworkflow vast.
5. Bepaal afzonderlijk of de fout in app, servercontract, data, configuratie,
   signing of externe provider zit.
6. Pauzeer een toekomstige Play staged rollout wanneer die actief is. Dit doet
   niets voor reeds geïnstalleerde builds; daarvoor blijft een hotfix nodig.
7. Roteer bij een vermoed secretlek het betrokken geheim. Een code-rollback
   maakt een gelekt geheim niet opnieuw veilig.

Noteer geen e-mail, keepernaam, tokens, savebody of inventory in incidentbewijs.
Gebruik supportcode/correlation ID en alleen het noodzakelijke UTC-venster.

## Beslismatrix

| Situatie | Voorkeursactie | Niet doen |
| --- | --- | --- |
| App crasht, server en data zijn gezond | Nieuwe app-hotfix vanaf exact uitgebrachte commit | Oude APK onder dezelfde tag vervangen of `versionCode` verlagen |
| RPC/constraint is fout maar data is intact | Nieuwe additieve correctiemigratie | Reeds toegepaste SQL herschrijven of uit migration history verwijderen |
| Configuratie of secret is fout | Config corrigeren/secret roteren en daarna healthcheck | Spelersdata herstellen zonder bewijs dat data fout is |
| Mogelijk foutieve waardemutaties | Mutatiepad stoppen zodra daarvoor een geteste serverflag bestaat; bewijs bewaren en handmatig beoordelen | Stil coins, gems, items of dragons afnemen/toekennen |
| Destructieve migratie of datacorruptie | Stop, maak apart herstelplan en bewijs restore op staging | Productie resetten, tabellen leegmaken of blind een oude dump terugzetten |
| Alleen één account lijkt geraakt | Privacyarm supportonderzoek volgens `SUPPORT_PRIVACY_OPERATIONS.md` | Brede rollback op basis van naam, screenshot of onbevestigde aanname |

Er bestaat een geteste globale schakelaar voor de nieuwe servereconomie:
`private.economy_contract.mutations_enabled`. Hij staat uit. Dit is geen
algemene productie-maintenance-schakelaar: huidige legacyspelregels, sociale functies en bestaande
claims vallen er niet allemaal onder. Een incident vereist dus beoordeling van
het daadwerkelijk getroffen pad.

## App-hotfix

### Voorbereiden

1. Begin bij de exacte commit van de openbare releasetag; neem geen toevallige
   lokale wijzigingen mee.
2. Reproduceer de fout en voeg eerst een gerichte regressietest toe.
3. Pas alleen de kleinste noodzakelijke correctie toe.
4. Verhoog zichtbare appversie met `0.00.01` en verhoog `versionCode`; package-ID
   blijft `nl.dragonhaven.app` en de bestaande releasekey blijft verplicht.
5. Wanneer lokale migraties verder zijn dan productie, publiceer geen app die
   dat nieuwe servercontract nodig heeft voordat staging en de afzonderlijk
   goedgekeurde productiemigratie groen zijn.

### Verifiëren

Minimaal verplicht:

- Flutter-analyzer en volledige testset;
- gerichte regressietest voor het incident;
- relevante compacte/reduced-motion of echte-devicecontrole;
- geïsoleerde staging-E2E wanneer online gedrag geraakt wordt;
- `tool/release_server_preflight.ps1` tegen exact het verwachte project;
- package, versie, `versionCode`, APK/AAB-hash en signingfingerprint;
- GitHub releasepublisher-dry-run en de bestaande Actions-releasegate.

Een mislukte test, migration parity, database-lint, Auth-check,
app-healthcheck, versiecheck of signingcheck blokkeert publicatie.

### Uitrollen

1. Vraag expliciete toestemming voor de concrete versie en eventuele migraties.
2. Pas eerst alleen de exact begrensde, bewezen migraties toe wanneer de hotfix
   daarvan afhangt.
3. Herhaal de onafhankelijke serverpreflight.
4. Publiceer een nieuwe onveranderlijke tag/release; wijzig een bestaande
   succesvolle release niet in-place.
5. Start in Play later met de kleinste gekozen staged rollout. Rick bedient en
   vergroot of pauzeert die rollout.
6. Controleer direct en na het afgesproken observatievenster Auth,
   applicatiehealth, supportsignalen en de relevante functie.

## Database-hotfix

### Additieve of gedragsmatige correctie

1. Maak migratie `N+1`; wijzig migratie `N` niet wanneer die ergens is toegepast.
2. Houd de correctie compatibel met de huidige openbare client en, waar
   mogelijk, ten minste de direct vorige client.
3. Voeg constraints/RLS/rechten expliciet toe en trek directe tabeltoegang in.
4. Test op de geïsoleerde stagingdatabase: apply, lint, preflight, Auth/app
   health en alle relevante sociale/back-up/trade-E2E.
5. Leg beginstand en de exact toegestane pending set vast in een aparte
   handmatige productieworkflow. Een onverwachte remote of lokale migratie stopt
   de run.
6. Gebruik dry-run vóór apply en bewaar voor/na-bewijs zonder spelersdata.
7. Pas productie alleen na concrete toestemming toe en voer onmiddellijk de
   volledige preflight opnieuw uit.

### Destructieve of transformerende correctie

`drop`, bulk-`delete`, irreversibele typeconversie, sleutelherbouw, verliesrijke
backfill en het overschrijven van spelerwaarde vereisen vóór implementatie een
apart herstelplan met:

- exacte tabellen, rijen/selectiecriteria en verwachte aantallen;
- UTC-cutoff, RPO en maximaal aanvaard gegevensverlies;
- versleutelde herstelbron, eigenaar, bewaartermijn en integriteitshash;
- herstelvolgorde voor schema, data, constraints, RLS en functies;
- op staging gemeten restoreduur tegenover de gekozen RTO;
- validatiequeries en functionele E2E vóór heropening;
- communicatie-, compensatie- en menselijke goedkeuring;
- veilige afbreekcriteria wanneer telling/hash/resultaat afwijkt.

Zonder groen staging-restorebewijs en expliciete productietoestemming wordt zo'n
migratie niet uitgevoerd. Productie gebruikt nooit `db reset`.

## Herstel wanneer de correctie zelf faalt

- Stop de workflow; start niet herhaald met ruimere aannames.
- Bewaar de mislukte run, foutklasse en actuele migratiestand.
- Bij appfalen blijft de vorige openbare release beschikbaar, maar reeds
  bijgewerkte apparaten krijgen een nieuwe hogere hotfix.
- Bij serverfalen bepaal eerst of de transactie volledig is teruggedraaid.
  Alleen een bewezen gedeeltelijke toestand krijgt een idempotente
  reparatiemigratie.
- Een dataterugzetactie blijft geblokkeerd tot bron, cutoff, getroffen accounts,
  verliesvenster en validatie expliciet zijn goedgekeurd.

## Bewijs en afsluiting

Bewaar maximaal privacyarm bewijs:

- incident-ID, UTC-tijdlijn, oorzaak en getroffen functiegroep;
- commits/tags, app-/schema-/contractversies en workflowlinks;
- testtotalen, preflight/lint/healthuitkomst;
- artifactgrootte, SHA-256 en signingfingerprint;
- beslissing, toestemming, observatievenster en eindstatus.

Gebruik standaard maximaal dertig dagen voor technisch incidentbewijs zonder
spelersdata. Sluit pas wanneer de oorzaak is getest, monitoring groen blijft,
supportimpact is beoordeeld en het auditplan de werkelijke stand vermeldt.

## Oefenritme

- Per relevante release: app-hotfixpad op papier controleren.
- Per kwartaal of vóór brede Play-lancering: een niet-destructieve staging
  fix-forwardoefening met fictief incident uitvoeren.
- Vóór iedere destructieve productiemigratie: een echte stagingrestore met
  tellingen, hash en gemeten duur uitvoeren.
- Na een echte SEV-1/SEV-2: binnen zeven dagen een privacyarme evaluatie en
  regressietest vastleggen.

De algemene staging-hotfixoefening blijft open. De begrensde SQL-repetitie
`tool/staging_economy_hotfix_contract.ps1` staat klaar voor staging: zij haalt
de defecte limiter uit onveranderlijke migratie 37 en de correctie uit 38,
installeert uitsluitend sessielokale kopieën en bewijst zowel het historische
falen als de herstelbranches. De echte private functie, rechten, activatie en
migratiehistorie worden niet vervangen. Het uitvoerbewijs vermeldt beide
bronhashes, duur, controles en rollback; de staging-49-workflow bewaart dit naast
lint, serverpreflight en functionele contracten. Uitvoering en resultaat moeten
nog worden vastgelegd. Dit dekt niet de operationele detectie-, communicatie-
en compensatieketen van een volledig incident.

Een afzonderlijke
legacy-import-/herstelproef is geslaagd op 7 september in
[run 34120524533](https://github.com/Rakky88/DragonHaven/actions/runs/34120524533):
volledige rij-/JSON-/SHA-256-gelijkheid, geweigerde nieuwere voortgang/verlopen
backups/verkeerde eigenaar/serveraccounts, transactionele foutafhandeling en
behouden audit/importlock. De synthetische restore bleef onder tien seconden;
de totale aanvraag duurde 1.250 ms. Alles draaide terug, schema 47 en health
bleven groen. Het script heeft alleen tijdelijke helpers voor synthetische
accounts en is geen operationele herstelroute voor echte spelers. Het bewijst
ook geen herstelduur voor een productiedump of grote bestaande inventaris.

Dit runbook zelf wijzigt geen server, release of externe account.
