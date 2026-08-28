# DragonHaven incident- en diagnoserunbook

Laatst bijgewerkt: **28 augustus 2026**  
Uitgangsversie: **v0.04.07 plus post-auditverbeteringen**

## Doel

Dit runbook beschrijft hoe online problemen veilig en eerst zonder betaalde
monitoring kunnen worden gevonden, begrensd en hersteld. Het behandelt Auth,
Friends, Trades, Group Adventures, cloudback-ups, database en releases.

Productie wordt nooit aangepast alleen omdat een enkele client een fout toont.
Controleer eerst bereikbaarheid, omvang, recente release/migratie en veilige
supportdiagnostiek. Plaats nooit wachtwoorden, access tokens, service-role keys,
databasewachtwoorden of volledige saves in een ticket of incidentlog.

## Gratis beschikbare bewijzen

- De app toont bij online fouten een achttekens-supportcode.
- **Account Info → Copy support diagnostics** kopieert een bewust beperkt JSON-
  rapport met appversie, Keeper ID, user UUID, veilige foutcodes, supportcodes
  en timings. E-mail, wachtwoord, tokens, inventory en save-inhoud ontbreken.
- `tool/public_server_health_check.ps1` meet de twee publieke Auth-endpoints en
  kan een JSON-rapport bewaren.
- De handmatige GitHub-workflow **Public server health check** voert dezelfde
  check uit zonder private secrets en bewaart het artifact drie dagen.
- `tool/release_server_preflight.ps1` controleert daarnaast migration parity,
  database-lint en e-mailauth op de gekoppelde server.
- De Supabase Dashboard-logs en -metrics blijven de primaire bron voor
  serverspecifieke details zolang geen externe monitoring is gekoppeld.

## Bekend free-tiergedrag

Een weinig gebruikte gratis Supabase-instance kan na rust traag op gang komen
of wegens inactiviteit worden gepauzeerd. Op 28 augustus 2026 is bij een
`ACTIVE_HEALTHY` project een eerste Auth-reactie van 24–41 seconden gemeten,
gevolgd door warme reacties onder één seconde. DragonHaven start daarom lokale
gameplay zonder online refresh af te wachten en begrenst een online actie op 75
seconden.

Een cold start is geen excuus om structurele fouten te negeren. Herhaalde warme
responses boven de afgesproken grens, 54x-statuscodes, veel timeouts of een
gepauzeerd project moeten als incident worden behandeld. Zie de officiële
[Supabase-documentatie over Free Plan pausing](https://supabase.com/docs/guides/platform/free-project-pausing).

## Ernstniveaus

| Niveau | Voorbeeld | Eerste reactie |
| --- | --- | --- |
| SEV-1 | Dataverlies, onbevoegde toegang, dubbele betaalde reward of alle online functies langdurig uit | Uitrol/purchases stoppen, bewijs veiligstellen, eigenaar direct informeren |
| SEV-2 | Veel spelers kunnen niet inloggen, back-uppen, traden of Group Adventures gebruiken | Health/preflight, logs en recente wijzigingen controleren; hotfix/rollback voorbereiden |
| SEV-3 | Eén account of één functie faalt herstelbaar; lokale save blijft veilig | Supportrapport verzamelen, correlation/supportcode zoeken, gericht reproduceren |
| SEV-4 | Trage cold start of cosmetische melding zonder verlies | Meten, trend vastleggen en pas escaleren bij herhaling |

## Eerste vijf minuten

1. Noteer UTC-tijd, appversie, platform, betrokken functie en aantal bekende
   spelers. Vraag om de supportcode of het bewust gekopieerde supportrapport,
   niet om wachtwoord of volledige save.
2. Voer de publieke healthcheck uit:

   ```powershell
   powershell -ExecutionPolicy Bypass -File `
     .\tool\public_server_health_check.ps1 `
     -Environment production `
     -OutputPath build\health\public-health.json
   ```

3. Herhaal eenmaal na een eerste trage reactie om cold start van blijvende
   latency te onderscheiden. Noteer beide tijden; verberg een trage eerste
   meting niet.
4. Controleer in Supabase of projectstatus, Auth, databaseverbindingen en logs
   gezond zijn. Gebruik user UUID/Keeper ID en tijdvenster, nooit alleen de
   zichtbare keepernaam.
5. Controleer of vlak ervoor een apprelease, migratie, secretrotatie of
   providerwijziging plaatsvond.

## Verdiepte controles

### Auth en nieuwe accounts

- Controleer `/auth/v1/health` en `/auth/v1/settings` plus gemeten latency.
- Controleer projectstatus en of een Free-project is gepauzeerd.
- Controleer signup-/loginfouten, rate limits, e-mailbevestiging en
  bezorgproblemen in het relevante tijdvenster.
- Laat de gebruiker bij een onbevestigd account de bevestigingsmail opnieuw
  aanvragen; vraag nooit om het wachtwoord.
- Bij alleen een cold start: lokale gameplay blijft bruikbaar; laat de speler
  de online actie na het opwarmen opnieuw proberen.

### Cloudback-up en multi-device

- Een `cloud_save_conflict` betekent dat niets is overschreven.
- Vergelijk lokale basisrevision met de remote revision uit het supportrapport
  en serverrecord.
- Adviseer **Restore cloud** alleen wanneer de speler de getoonde cloudkopie
  wil gebruiken. **Keep local for now** laat beide kanten ongewijzigd.
- Forceer geen overschrijving totdat servergeschiedenis, bewaartermijn en een
  expliciete hersteloptie zijn geïmplementeerd.
- Test restores eerst op staging en behoud altijd een lokale recovery copy.

### Eenmalige import van een bestaande save

- Controleer eerst `get_my_legacy_import_report()` voor protocolversie,
  save-schemaversie, importtijd en alleen de privacyarme aantallen/clampvelden.
- Een historisch versie-0-record betekent dat de import al vóór de uitgebreide
  auditregistratie plaatsvond; probeer die import nooit opnieuw te forceren.
- Deel de `source_sha256` of de private pre-import snapshot niet met de speler
  en kopieer de snapshot niet naar een ticket.
- Een private herstelkopie is maximaal dertig dagen beschikbaar. Er is bewust
  geen rollbackknop in de app: herstel vereist doelcontrole, een vastgelegde
  reden, stagingreproductie en expliciete productietoestemming.
- Verwijder of wijzig nooit alleen `inventory_imported_at`; dat kan een tweede
  import en daarmee dubbele serveritems veroorzaken.

### Trades en Group Adventures

- Zoek op user UUID, trade/lobby-ID, tijd en veilige foutcode.
- Controleer state, deelnemers, reserveringen en acknowledgements voordat iets
  wordt gecorrigeerd.
- Voer nooit losse inventory-updates uit zonder de bijbehorende atomaire RPC en
  auditcontext.
- Bij een clienttimeout kan de serveractie toch zijn afgerond. Eerst refreshen
  en serverstatus controleren; niet blind opnieuw belonen.

### Database en migraties

- Voer bij vermoeden van schema-afwijking de volledige preflight uit:

  ```powershell
  powershell -ExecutionPolicy Bypass -File `
    .\tool\release_server_preflight.ps1 `
    -SupabaseCli .\.tools\supabase-2.115.0\supabase.exe
  ```

- Publiceer of migreer niet wanneer migration parity of lint faalt.
- Maak vóór een risicovolle correctiemigratie een herstelplan en test haar op
  staging.
- Corrigeer productie nooit rechtstreeks met een ad-hoc query zonder review,
  doelbereik, rollback en expliciete toestemming.

## Privacyveilige supportworkflow

1. Speler levert Keeper ID, supportcode, appversie, tijd en functie.
2. Alleen als meer context nodig is gebruikt de speler **Copy support
   diagnostics** en deelt dit met vertrouwde DragonHaven-support.
3. Support zoekt via Keeper ID naar de server-user UUID en beperkt logs tot het
   relevante tijdvenster.
4. Noteer alleen noodzakelijke technische feiten. Kopieer geen volledige
   requestbody, save of inventory in een ticket.
5. Verwijder tijdelijke exports volgens de nog vast te stellen bewaartermijn.

Een toekomstige supporttool moet least-privilege zijn en iedere inzage loggen.
Tot die tijd blijft rechtstreekse productiedatabasetoegang beperkt tot de
eigenaar en gecontroleerde technische werkzaamheden.

## Release-incident

1. Pauzeer een staged rollout; publiceer geen nieuwe APK/AAB.
2. Bewaar workflowrun, commit, versie, artifacthash, signingfingerprint en
   serverpreflight.
3. Bepaal of alleen de client, alleen de server of hun compatibiliteit faalt.
4. Gebruik een app-hotfix bij clientproblemen. Gebruik een voorwaartse,
   idempotente migratie bij serverproblemen; draai een migratie alleen terug als
   het herstelpad vooraf bewezen is.
5. Voer analyzer, volledige tests, staging-E2E, preflight, versie-, signature-
   en hashcontrole opnieuw uit.
6. Hervat de rollout klein en verhoog pas wanneer Auth, RPC, database, crashes
   en support gezond blijven.

## Incidentlogtemplate

```text
Incident-ID:
Starttijd UTC:
Ernstniveau:
Gemelde appversie(s):
Getroffen functies/aantal spelers:
Supportcode(s):
Publieke healthstatus en latency (eerste/herhaling):
Supabase-projectstatus:
Recente release/migratie/configuratiewijziging:
Waarschijnlijke oorzaak:
Beperkende maatregel:
Herstelactie en toestemming:
Verificatie na herstel:
Eindtijd UTC:
Vervolgtaak/eigenaar:
```

## Wanneer een betaalde stap overwegen

Begin met de ingebouwde supportcodes, handmatige healthworkflow, Supabase-
dashboard en gratis monitoringtiers. Overweeg pas een upgrade wanneer gemeten
incidenten aantonen dat automatische alerts, langere retentie, logdrains,
back-ups of gegarandeerd niet-pauzeren nodig zijn. Leg dan eerst huidige kosten,
free-tiergrens, concrete meerwaarde en terugvaloptie vast; alleen de eigenaar
activeert de betaalde dienst.
