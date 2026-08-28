# DragonHaven serververbeteringen — v0.04.07

## Wat is verbeterd

### Online startup en nieuwe accounts

- App-initialisatie wacht niet langer op de eerste volledige online refresh.
  Lokale gameplay en navigatie blijven beschikbaar wanneer Supabase traag of
  tijdelijk onbereikbaar is.
- Afzonderlijke online acties hebben vanaf de post-auditverbetering een harde
  timeout van 75 seconden en tonen
  daarna dat de lokale save veilig is.
- Nieuwe accounts krijgen een expliciete e-mailbevestigingsstatus en kunnen de
  bevestigingsmail opnieuw aanvragen zonder ingelogde sessie.
- De startup- en timeoutpaden zijn met vertraagde en tijdelijk falende
  repository-implementaties getest.

### Authoritative trade guards

Migratie `202608280020_relic_variants_and_trade_guards.sql` voegt het volgende
toe:

- `item_data jsonb` voor variantdata in serverinventaris en trades;
- exacte opslag en overdracht van Chronoshard-percentages van 10 tot en met 90;
- row locking en percentage-specifieke reserveringen zodat een gereserveerde
  variant niet tegelijk kan worden gebruikt of dubbel kan worden aangeboden;
- server-side weigering van Portrait, Title en Music Chests;
- server-side weigering van shopgekochte untradeable relics en de unieke
  Twinstar Brooch;
- behoud van variantdata bij de definitieve, atomaire eigendomsoverdracht.

Clientchecks blijven aanwezig voor directe feedback, maar zijn niet de
beveiligingsgrens.

## Uitgevoerde productiepreflight

De gekoppelde Supabase-projectreferentie is `tnzathhutuwmohmjfrlo`.

Op 28 augustus 2026 is uitgevoerd:

```powershell
powershell -ExecutionPolicy Bypass -File .\tool\release_server_preflight.ps1 `
  -SupabaseCli .\.tools\supabase-2.115.0\supabase.exe
```

Resultaat:

- migraties: 20 lokaal en 20 remote;
- database lint: 0 fouten voor `extensions`, `private` en `public`;
- Auth health: HTTP 200;
- Auth settings: HTTP 200;
- e-mailauth: geconfigureerd.

De release mag niet worden gepubliceerd wanneer deze preflight op een later
moment een mismatch of fout meldt.

## Bewuste servergrenzen

- De algemene offline economie is nog client-state. Een toekomstige
  storeversie met echte betalingen vereist server-authoritative economy-RPC's,
  idempotency keys en Google Play receiptvalidatie.
- Backups hebben revisies en herstelkopieën, maar nog geen automatische merge
  van gelijktijdige apparaatwijzigingen.
- De app toont herstelbare fouten en timeouts; centrale error-rate-, latency- en
  capacity-alerting moet buiten de client worden ingericht.
- Account-specifieke support hoort op Keeper ID/user UUID en serverlogs te
  werken, niet op de zichtbare keepernaam alleen.

## Aanbevolen volgende serverstappen

1. Voeg dashboards en alerts toe voor Auth, RPC-latency, database-connecties en
   trade/group-adventure foutpercentages.
2. Verplaats coin-, gem-, chest- en relicmutaties naar idempotente server-RPC's
   voordat echte aankopen worden geactiveerd.
3. Voeg periodieke restore-tests van backups toe en definieer een expliciet
   multi-device conflictbeleid.
4. Breid de bestaande end-to-end stagingtests uit met geautomatiseerde
   e-mailconfirmatie en het starten, afronden en idempotent belonen van een
   Group Adventure, zonder een meerdaagse testactie achter te laten.

## Post-auditfundament in uitvoering

Na de v0.04.06-audit is lokaal alvast gebouwd:

- privacyveilige, begrensde in-memory diagnostiek met supportcodes en een door
  de speler te kopiëren supportrapport zonder e-mail, tokens of save-inhoud;
- persistente cloud-basisrevisies per account, zodat de client een bestaande
  remote revision niet langer stil kan overschrijven;
- een expliciete conflictmelding met veilig herstellen of lokaal doorgaan;
- een production/staging/local omgevingsgrens die staging nooit naar de vaste
  productieserver laat terugvallen;
- een handmatige, volledig afgescheiden stagingworkflow met negen afgeschermde
  Environment Secrets en vijf standen: public-only, bevestiging per account,
  een bevestigd account controleren en een tweepersoons-sociale flow;
- een echte stagingtest voor password-login, bevestigde e-mail, idempotente
  accountbootstrap, profielread, cloud-back-up/restore, stale-revisionweigering
  en veilige logout;
- een privacyveilige tweepersoons-stagingtest voor Friends request/acceptatie,
  een atomaire chest-ruil met inventariscontrole en Group Adventure
  aanmaken/lijsten/deelnemen/verlaten, inclusief veilige opruimlogica;
- een handmatige publieke healthworkflow en curl-gebaseerde health/preflight-
  metingen met latencyrapportage;
- een CI-verificatierapport met commit, appversie, versionCode, AAB-hash en
  verwachte signingfingerprint.

De productiepreflight na deze aanpassing rapporteerde opnieuw 20/20 migraties,
0 lintfouten en HTTP 200 voor Auth health/settings. De eerste Auth-response
duurde 24,5 seconden en de warme settingsresponse 0,13 seconde. Daarom is de
herstelbare clienttimeout naar 75 seconden verhoogd terwijl lokale gameplay
niet op online acties wacht.

De geïsoleerde account- en back-uprun
[`33180648232`](https://github.com/Rakky88/DragonHaven/actions/runs/33180648232)
bewees deze account- en back-upflow samen met opnieuw een groene analyzer, alle
252 tests en een staging-APK. De daaropvolgende sociale stagingrun
[`33182884493`](https://github.com/Rakky88/DragonHaven/actions/runs/33182884493)
bewees Friends, trade en de veilige wachtlobbyfase van Group Adventures met twee
bevestigde testaccounts; analyzer, 252 tests, staging-APK en bewijsartifact waren
opnieuw groen. Group Adventure starten/afronden/reward-idempotentie blijft open
totdat dit zonder een meerdaagse testactie kan worden uitgevoerd. Er is hierbij
niets op productie gewijzigd of gepubliceerd.

### Online herstelpaden en veilige bestaande-save-import

Na de openbare v0.04.07-release is in de volgende lokale bouwtranche verder
gewerkt aan de auditpunten die geen betaalde dienst vereisen:

- een getimede-out online request houdt zijn single-flight-slot vast totdat de
  onderliggende request echt klaar is, zodat snel opnieuw drukken geen
  overlappende mutatie kan veroorzaken;
- verlopen sessies worden niet als tijdelijke serverstoring driemaal herhaald
  en krijgen een expliciete, volledig vertaalde herinlogmelding;
- onbekende Auth/databasefouten worden tot een vaste veilige foutcode
  teruggebracht in plaats van een ruwe providertekst te loggen;
- timeout/herstel, dubbele taps, verlopen sessie, half afgemaakte Group Reward
  en trade-replay na lokale save plus appherstart zijn geautomatiseerd getest;
- migratie `202608280021_audited_legacy_inventory_import.sql` maakt de
  bestaande-save-import versieerbaar, bewaart een SHA-256-herkomstbewijs,
  rapporteert aantallen en toegepaste plausibiliteitslimieten zonder namen of
  save-inhoud openbaar te maken, en bewaart afgeschermd maximaal dertig dagen
  een pre-import herstelkopie;
- accounts die al vóór deze migratie geïmporteerd waren krijgen uitsluitend
  een historisch auditrecord en worden nooit opnieuw geïmporteerd.

Deze tranche is nog **niet** naar productie gemigreerd of als volgende appversie
uitgebracht. Eerst volgt een geïsoleerde stagingmigratie en importtest. Een
handmatig, gecontroleerd rollbackcommando blijft apart open; de herstelkopie is
al beschikbaar, maar wordt bewust niet via de app uitvoerbaar gemaakt.

Zie [DRAGONHAVEN_POST_AUDIT_PLAN.md](DRAGONHAVEN_POST_AUDIT_PLAN.md) en
[INCIDENT_RUNBOOK.md](INCIDENT_RUNBOOK.md) voor eigenaarschap, vervolgfasen en
incidentafhandeling. Deze lokale wijzigingen zijn nog geen nieuwe release of
productiemigratie.
