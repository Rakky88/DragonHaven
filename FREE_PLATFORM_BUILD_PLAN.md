# Kosteloze monitoring en groeiplan

Opdracht: 7 september 2026. Werkbranch: `feature/free-monitoring-and-growth`.
Publieke app: v0.05.18 / 10068; productie en staging: schema 49.

## Uitvoering

1. Firebase Core, Crashlytics, Performance en FCM integreren zonder Analytics.
   Ontbrekende configuratie mag opstarten, gameplay of bestaande meldingen niet
   blokkeren. Monitoring rapporteert uitsluitend begrensde technische gegevens.
2. Android-configuratie, ondertekenings-/symboolintegratie en CI-inrichting
   toevoegen. Productie- en stagingprojecten strikt gescheiden houden.
3. Pushregistratie per account en installatie, tokenvernieuwing, afmelden en
   meldingsvoorkeuren bouwen. Een betrouwbare serverwachtrij met retries,
   begrensde batches en generieke notificatietekst gebruiken.
4. Firebase zonder gekoppelde facturering inrichten. Geen Cloud Functions,
   BigQuery-export of betaald abonnement aanzetten. Supabase verzorgt het
   bestaande backenddeel en de begrensde pushworker binnen het gratis plan.
5. Monitoring en push testen, inclusief time-outs, ontbrekende configuratie,
   mislukte aflevering en accountwissel. Een echte stagingcrash en beëindigde-app
   push zijn pas bewezen zodra een eigen Firebase-project beschikbaar is.
6. Een onderbouwd groeiplan voor 100, 1.000 en 10.000 spelers leveren, met
   geregistreerde accounts, dagelijks actieve spelers en gelijktijdige spelers
   apart. Gebruik de bestaande loadmetingen zonder hun beperkingen te verbergen.
7. Ook de volledige resterende servereconomie bouwen: de gebruiker heeft dit
   expliciet bevestigd. Eerst volledige conversie en duurzame snapshots,
   vervolgens resterende winkels, ei-/draaklevensloop en rewardclaims.
   Representatieve stagingproeven en behoud van voortgang zijn harde poorten.

## Kosten en externe afhankelijkheid

De gebruiker wil geen kosten. Er worden geen factureringsaccounts gekoppeld,
abonnementen geüpgraded of betaalde diensten aangezet. Schaaldoelen zijn geen
toestemming om gratis quota te overschrijden of betalingen te activeren.

De gebruiker heeft bevestigd dat er nog geen Firebase-project is. Deze
werkplek heeft geen Google-aanmelding of Firebase-appconfiguratie. Code,
tests, inrichting en documentatie worden alvast gebouwd. Projecteigendom en
de eerste Google-aanmelding moeten onder het account van de gebruiker gebeuren;
er wordt geen fictief project als werkende integratie opgevoerd.

## Definitie van gereed

- De code is aangesloten op de echte app en voorzien van passende tests.
- De Android-build werkt zowel zonder als met gevalideerde Firebase-config.
- Serverwijzigingen zijn eerst op staging gerepeteerd; productiegegevens en
  de uitgeschakelde servereconomie blijven beschermd.
- Het groeiplan noemt bronnen, aannames, concrete quota en meetbare overstappen.
- Extern nog ontbrekende configuratie en nog niet uitgevoerde end-to-endproeven
  staan expliciet in de audit. Een mock is geen bewijs van echte bezorging.
