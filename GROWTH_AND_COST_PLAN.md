# DragonHaven: groei naar 100, 1.000 en 10.000 spelers

Peildatum: 7 september 2026. Kostenbeleid: geen betaalde diensten inschakelen.
Dit document is een capaciteitsplan, geen garantie dat een bepaald spelersaantal
binnen gratis infrastructuur past. Bedragen en quota moeten vóór een overstap
opnieuw worden gecontroleerd.

## Wat tellen we?

Geregistreerde accounts kosten blijvende opslag. Dagelijks actieve spelers
(DAU) bepalen vooral maandverkeer. Gelijktijdig actieve spelers (CCU) bepalen
piekbelasting. Een app die op de achtergrond blijft pollen veroorzaakt ook
verkeer; een geïnstalleerde app hoeft geen permanente databaseverbinding te hebben.

| Groei in accounts | Illustratieve DAU, 30% | Illustratieve piek-CCU, 10% | Wat moet worden bewezen? |
| --- | ---: | ---: | --- |
| 100 | 30 | 10 | Complete account- en herstelrondgang met echte inventarisomvang; foutloze piek van 10 en reserve tot 100 |
| 1.000 | 300 | 100 | Opslag-/verkeersprognose, volwassen inventarissen en gemengde lees-/schrijflast tot 100 tegelijk |
| 10.000 | 3.000 | 1.000 | Afzonderlijke nieuwe capaciteitsmeting op 1.000 tegelijk; de bestaande proef is afgekeurd |

De percentages zijn planningsaannames. Bij 100, 1.000 of 10.000 **tegelijk**
actieve spelers zijn aparte proeven nodig. Een MAU-quota is geen bewijs van
databasecapaciteit. De onderstaande budgetberekeningen blijven parametriseerbaar.

## Gratis uitgangspunt

Volgens de actuele leveranciersdocumentatie:

| Onderdeel | Gratis grens / keuze | Betekenis voor DragonHaven |
| --- | --- | --- |
| Firebase Spark | Crashlytics, Performance Monitoring en FCM zonder gebruikskosten | Monitoring en push; Analytics uit, geen betaald Google Cloud-product aanzetten |
| Supabase Database | 500 MB database per project, gedeelde CPU en 500 MB RAM | Tabellen én indexen meten; 50.000 MAU betekent niet dat 50.000 grote inventarissen passen |
| Supabase verkeer | 5 GB niet-gecachete egress per maand; daarnaast 5 GB gecachet | RPC/backup-downloads vallen niet vanzelf onder CDN-cacheverkeer |
| Supabase Storage | 1 GB bestandopslag | Bestaande appafbeeldingen blijven in de appdistributie; geen sprites per speler kopiëren |
| Supabase Edge Functions | 500.000 aanroepen per maand | Push in batches; geen functieaanroep per individuele poll |
| Supabase Realtime | 200 piekverbindingen en 2 miljoen berichten per maand | Geen automatische overstap naar één permanente verbinding per speler |
| Projecten | Twee actieve gratis Supabase-projecten | Bestaande productie en staging gebruiken; geen derde omgeving als stil kostenpad |

Bronnen: [Firebase prijsmodel](https://firebase.google.com/docs/projects/billing/firebase-pricing-plans),
[Supabase prijzen](https://supabase.com/pricing),
[Supabase quota](https://supabase.com/docs/guides/platform/billing-on-supabase),
[egressdefinities](https://supabase.com/docs/guides/platform/manage-your-usage/egress).

Firebase-push vereist wel een vertrouwde afzender. Die bouwen we op de bestaande
Supabase-server met een wachtrij en een begrensde worker. FCM gebruiken vereist
geen Firestore-database of betaalde Firebase Cloud Functions. App-installatie-
identifiers en diagnostiek blijven onder de beschreven monitoringprivacy vallen.

## Wat is al gemeten?

- Stagingrun `34119032803`: 100 gelijktijdige, vooraf aangemelde testaccounts,
  60 seconden opbouw plus 180 seconden steady state, 1.544 reads zonder fouten.
  P95 per pad: 239–298 ms. Dit betrof verse, kleine inventarissen en lezen.
- Run `34121385770`: 1.000 tegelijk actief, maar 3.729 van 7.769 reads eindigden
  in een netwerk-time-out: 47,998%. Deze capaciteit is **niet geaccepteerd**.
  De oorzaak is nog niet geïsoleerd. Alle synthetische accounts zijn opgeruimd.
- Er is geen capaciteitsbewijs voor 10.000 CCU. Ook 100 volwassen inventarissen,
  writes, langdurige belasting, piek-DB-verbindingen en echte maand-egress zijn
  hiermee nog niet volledig bewezen.

Gedetailleerd bewijs: [STAGING_LOAD_TEST.md](STAGING_LOAD_TEST.md).

## Waar gaan opslag en verkeer heen?

Een voorbeeld van 100 KiB per volledige save, één huidige save en vijf
historische revisies, vraagt alleen daarvoor al circa 600 KiB per account.
Dat is ongeveer 59 MiB bij 100 accounts, 586 MiB bij 1.000 en 5,7 GiB bij
10.000. Dit is een ruwe ongecomprimeerde payloadsom; PostgreSQL-compressie,
rij-/indexoverhead, economie-instances, chat en ledger moeten werkelijk worden
gemeten. De bewaartermijn mag niet stil worden verkort om deze rekensom passend
te maken.

Een tweede voorbeeld: 30 minuten per DAU per dag, één response van 2 KiB elke
15 seconden, dertig dagen per maand. Dat geeft ongeveer 0,69 GiB bij 100 DAU,
6,9 GiB bij 1.000 en 68,7 GiB bij 10.000. Dit sluit Auth, overige RPC's, retries,
backups, push en headers nog uit. Pollen gedurende 24 uur is veel duurder.

De werkelijke app heeft meerdere refreshpaden. Daarom meten we per pad:
aanvragen, payloadbytes, duur, foutfase, cachehits, dagvolume en retryvolume.
Een synthetische readtest vervangt die productiemeting niet.

## Wat verandert wanneer?

| Niveau | Database | App, netwerk en overige infrastructuur | Toelatingspoort |
| --- | --- | --- | --- |
| Eerste 100 accounts | Eén bestaande database; gerichte owner/status/indexen, paginering, begrensde payloads; queryplannen en backupomvang meten | Geen achtergrondpolling zonder zichtbare app; push als signaal, actuele inhoud via ingelogde RPC; caches en samengevoegde refreshes | Geen regressie in beloningen, retries, accountwissel of herstel; gemeten ruimte onder de waarschuwingsgrenzen |
| Naar 1.000 accounts | Volwassen inventarisprofielen testen; traagste queries optimaliseren; hotspot-locks, CPU, geheugen en verbindingspool meten; retentie correct uitvoeren | Adaptive backoff/jitter, coalescing en delta-/revision-controles; pushbatches met budget; SMTP-verzending en inschrijfpiek testen | Volledige gemengde proef voor de verwachte CCU slaagt; geprojecteerde opslag én egress passen met reserve |
| Naar 10.000 accounts | Databasecapaciteit selecteren op metingen; zo nodig grotere compute/opslag. Eerst indexen en querywerk, daarna pas replicas/partities. Schrijven en transacties blijven bij één eigenaar | Cachebare publieke catalogi buiten dure spelers-RPC's; jobs begrenzen; dagelijkse quotaprognose; grotere appdistributie controleren; herstel- en incidentbezetting regelen | 1.000-CCU-proef opnieuw groen voor dit voorbeeldscenario; kostenvoorstel apart goedgekeurd of instroom begrensd zolang €0 vereist blijft |

Bij **10.000 CCU** is de aanpak nog een stap zwaarder: een geleidelijke,
representatieve test op 100, 1.000, 3.000 en 10.000, een beoordeelde DB-/pool-
configuratie en gemeten foutmarges. Geen 10.000-accountproef rechtstreeks op
productie en geen verzonnen gratis-capaciteitsgarantie.

## Meetbare waarschwingen en stopgrenzen

- Waarschuw bij 70% van opslag of maandquota; maak bij 80% een prognose met
  de huidige daggroei. Reserveer ruimte voor onderhoud, retries en herstel.
- Gebruik voor reads als eerste acceptatiedoel p95 onder 500 ms, p99 onder
  1.500 ms en minder dan 1% fouten; bespreek afwijkingen per echt spelpad.
- Writes moeten bovendien atomair en idempotent blijven bij dubbel klikken,
  verloren antwoorden en account-/apparaatwissel. Geen dubbele beloningen.
- Een stijgende lockwachttijd, geheugenproblemen, herhaalde 429/5xx of een
  uitgeput verbindingsbudget blokkeert verdere opschaling.
- Gratis budget op: eerst oorzaak en onnodig verkeer aanpakken. Zo nodig
  inschrijvingen tijdelijk via uitnodigingen/wachtlijst begrenzen. Geen
  bestaande inventaris verwijderen, quota omzeilen of automatisch upgraden.
- Voor retentie blijven vaste claim-/instance-identiteiten behouden zodat
  oude retries nooit opnieuw beloningen kunnen aanvragen. Ledger-opschoning
  mag de afgesproken herstel- en auditgaranties niet beschadigen.

## Verificatie vóór iedere schaalstap

1. Meet een week normaal gebruik: DAU/CCU, payloadbytes, databasegroei en
   grootste inventarissen. Geen privé-inhoud of tokens in de metingen.
2. Bouw synthetische profielen met dezelfde verdeling, inclusief grote saves,
   veel eieren, oude ledgerhistorie en actieve Conclave-chat.
3. Scheid Auth-opbouw van spelbelasting. Test inschrijven en SMTP als apart
   scenario; geef de provider geen ongecontroleerde mail- of loginpiek.
4. Test lezen én relevante writes, cold/warm cache, herverbinden, retries,
   netwerkvertraging, langdurige belasting en een korte piek.
5. Vergelijk cliëntfoutfasen met CPU, geheugen, DB-verbindingen, queryduur en
   locks. De bestaande 1.000-test wordt pas opnieuw gedraaid als deze
   instrumentatie en de oorzaakonderzoeksvraag concreet zijn.
6. Bewijs cleanup, schema/lint/health en herstel. Bewaar een privacyarm rapport
   met commit, schema, scenario, stopreden en gemeten grenzen.
7. Laat betaalde capaciteit een afzonderlijke keuze blijven. Supabase Pro
   begint volgens de huidige prijslijst bij $25/maand; dat is geen totaalprijs
   of garantie voor een bepaalde CCU. Extra compute/projecten/add-ons kunnen
   kosten toevoegen. Er wordt niets daarvan geactiveerd door dit plan.

## Eerste uitvoerbare verbeteringen

- Firebase en de pushwachtrij aansluiten, met Analytics uit.
- Achtergrondpolling stoppen; bij hervatten onmiddellijk bijwerken.
- Een lokale rekentool leveren voor accounts, DAU, sessieduur, responseomvang,
  aantal saves en verwachte databasegroei.
- Een read-only capaciteitsrapport toevoegen met uitsluitend technische
  database-/opslaggetallen. Geen synthetische load aan het rapport koppelen.
- Bestaande audittests uitbreiden met privacy, uitval, accountwissel en
  quotabudgetten. Pas daarna een nieuwe capaciteitsmeting plannen.
