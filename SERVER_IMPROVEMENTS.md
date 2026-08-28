# DragonHaven serververbeteringen — v0.04.06

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
4. Voeg end-to-end stagingtests toe die signup, e-mailconfirmatie, eerste login,
   backup, Friends, trade en Group Adventure als één flow uitvoeren.

## Post-auditfundament in uitvoering

Na de v0.04.06-audit is lokaal alvast gebouwd:

- privacyveilige, begrensde in-memory diagnostiek met supportcodes en een door
  de speler te kopiëren supportrapport zonder e-mail, tokens of save-inhoud;
- persistente cloud-basisrevisies per account, zodat de client een bestaande
  remote revision niet langer stil kan overschrijven;
- een expliciete conflictmelding met veilig herstellen of lokaal doorgaan;
- een production/staging/local omgevingsgrens die staging nooit naar de vaste
  productieserver laat terugvallen;
- een handmatige, volledig afgescheiden stagingworkflow die pas werkt zodra de
  eigenaar een stagingproject en GitHub Environment Secrets toevoegt;
- een handmatige publieke healthworkflow en curl-gebaseerde health/preflight-
  metingen met latencyrapportage;
- een CI-verificatierapport met commit, appversie, versionCode, AAB-hash en
  verwachte signingfingerprint.

De productiepreflight na deze aanpassing rapporteerde opnieuw 20/20 migraties,
0 lintfouten en HTTP 200 voor Auth health/settings. De eerste Auth-response
duurde 24,5 seconden en de warme settingsresponse 0,13 seconde. Daarom is de
herstelbare clienttimeout naar 75 seconden verhoogd terwijl lokale gameplay
niet op online acties wacht.

Zie [DRAGONHAVEN_POST_AUDIT_PLAN.md](DRAGONHAVEN_POST_AUDIT_PLAN.md) en
[INCIDENT_RUNBOOK.md](INCIDENT_RUNBOOK.md) voor eigenaarschap, vervolgfasen en
incidentafhandeling. Deze lokale wijzigingen zijn nog geen nieuwe release of
productiemigratie.
