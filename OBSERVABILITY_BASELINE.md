# DragonHaven observability- en dashboardspecificatie

Laatst bijgewerkt: **31 augustus 2026**

## Doel en gratis startpunt

Deze specificatie legt vast wat DragonHaven moet meten voordat vaste alarmen,
een betaalde logdienst of een brede Google Play-uitrol worden gekozen. Begin
met de gratis Supabase-dashboardweergaven, de handmatige GitHub-healthworkflow,
de privacyveilige clientsupportcodes en bewaarde workflowrapporten. Een upgrade
is pas nodig wanneer gemeten volume, retentie of responstijd dat rechtvaardigt.

Geen dashboard of alert mag wachtwoorden, access/refresh tokens, volledige
saves, e-mailadressen, zichtbare keepernamen, tradepayloads of inventory-inhoud
bevatten. Toegestane dimensies zijn omgeving, appversie, Androidversie,
operatienaam, vaste foutcode, HTTP/RPC-status, duurklasse en willekeurige
technische installatie- of correlation-ID.

## Dashboard 1 — bereikbaarheid en Auth

| Paneel | Bron | Weergave | Eerste beoordeling |
| --- | --- | --- | --- |
| Auth health | `public_server_health_check.ps1` | status en responstijd per run | iedere release en melding |
| Auth settings | dezelfde healthcheck | status, responstijd en e-mailauth aan/uit | iedere release |
| Applicatiehealth | dezelfde healthcheck na migratie 32 | PostgREST/database-status, responstijd, vast contract en veilige klokafwijking; nooit accountdata | iedere release en melding |
| Signup/loginfouten | Supabase Auth logs/metrics | percentage per vaste foutcode | dagelijks tijdens testuitrol |
| Loginlatency | Supabase/clientdiagnostiek | p50/p95/p99 per omgeving | na minimaal zeven representatieve dagen |
| E-mailbevestiging | Auth/e-mailprovider | aanvragen, bezorgd, bevestigd, geweigerd | dagelijks tijdens onboardingtest |

Cold starts worden afzonderlijk gemarkeerd. Eén trage eerste gratis-tierreactie
is geen incident; herhaald trage warme requests of een foutstatus wel.

## Dashboard 2 — RPC's en sociale functies

Toon per RPC en appversie: requestaantal, successen, vaste foutcodes,
timeouts, p50/p95/p99 en retries. Maak afzonderlijke rijen voor accountbootstrap,
online snapshot, Friends, trades, Group Adventure en cloudback-up.

Voor Trades en Group Adventures komen extra tellers voor reserveringsfouten,
state-conflicts, verlopen acties, apply/acknowledge-fouten en replay. Een
clienttimeout geldt als onbekende uitkomst totdat een refresh de serverstatus
heeft bevestigd; hij mag niet automatisch als definitieve serverfout of extra
reward worden geteld.

## Dashboard 3 — cloudback-up en import

| Signaal | Veilige dimensies |
| --- | --- |
| Back-upsuccessen/-fouten | omgeving, appversie, foutcode, revisionrichting |
| Conflicts | `cloud_save_conflict`, basisrevision aanwezig ja/nee |
| Restores | succes/invalid/missing en duur; nooit save-inhoud |
| Legacy-import | protocolversie, save-schemaversie, aantallen, clamp-booleans |
| Importherstel | herstelkopie aanwezig/verlopen; geen snapshot in dashboard |

`source_sha256` is uitsluitend een integriteitsbewijs voor gecontroleerde
support en geen publieke grafiekdimensie.

## Dashboard 4 — database en capaciteit

Gebruik de Supabase-projectmetrics voor CPU, geheugen, databasegrootte,
actieve/maximale verbindingen, querylatency, egress, Auth-volume en rate limits.
Leg bij een belastingstest ook gelijktijdigheid, scenarioverdeling, testduur,
appcontractversie en migratieversie vast. Test eerst 100 gebruikers; 1.000 pas
na beoordeling van de eerste meting. Meer dan 1.000 vereist expliciet budget-
en capaciteitsakkoord.

## Dashboard 5 — appversies en compatibiliteit

Toon actieve appversies alleen geaggregeerd, plus servercontractversie,
minimum ondersteunde client, foutpercentage per appversie en aandeel oude
clients. Voeg geen stabiel apparaat-ID aan een openbaar dashboard toe. Een
toekomstige compatibiliteits-RPC moet uitsluitend versies/status teruggeven en
geen accountdata vereisen.

## Dashboard 6 — release en support

Iedere release bewaart commit-SHA, appversie, versionCode, migratieaantal,
analyzer/testresultaat, AAB/APK-hash, signingfingerprint, preflightstatus en
workflowlink. Support groepeert alleen op supportcode, correlation-ID,
operatienaam, vaste foutcode en appversie. Raadpleeg
[INCIDENT_RUNBOOK.md](INCIDENT_RUNBOOK.md) voor triage en toegangsregels.

## Baseline vóór alarmdrempels

Bewaar eerst minimaal zeven representatieve testdagen en noteer per dag:

| Datum/UTC-venster | Testers/requests | Auth p95/p99 | RPC p95/p99 | Fout% | DB piekverbindingen/CPU | Egress | Incidenten |
| --- | ---: | ---: | ---: | ---: | --- | ---: | --- |
| Nog te meten | — | — | — | — | — | — | — |

Kies daarna pas waarschuwing- en escalatiedrempels. Start met waarschuwingen,
niet met automatische destructieve acties. Een voorlopige kandidaat is een
alert bij meerdere opeenvolgende mislukte synthetische checks of een duidelijk
afwijkende warme p95/fouttrend; de definitieve grens volgt uit de baseline.

## Wat Codex kan aansluiten zodra jij Firebase/monitoring hebt gemaakt

- buildversie, platform en willekeurige installatie-ID aan crash/performance-
  events koppelen;
- redaction en toegestane eventvelden afdwingen en testen;
- staging- en productiegegevens strikt scheiden;
- dashboards/alerts configureren volgens dit document;
- een gecontroleerde stagingfout en testalert uitvoeren en het bewijs in het
  post-auditplan vastleggen.

Jij blijft eigenaar van project, ontvangers, alarmuren, maandbudget,
datalocatie, retentie en de privacy/Data Safety-beslissing. Begin met het gratis
plan en activeer geen betaalde upgrade zonder nieuwe, expliciete toestemming.
