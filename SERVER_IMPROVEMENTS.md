# DragonHaven serververbeteringen — v0.04.09

## Releasecandidate v0.05.00 — gecontroleerde uitrol gestart

Productie staat tijdens de voorbereiding nog op migratie 29/29. Migratie
`202608310030_friend_messages_and_conclaves.sql` en een exact begrensde
29→30-workflow zijn lokaal voorbereid; productie wordt pas gewijzigd nadat de
uitgebreide staging-E2E en databasegates groen zijn.

- Friend Messages zijn uitsluitend tussen bevestigde vrienden beschikbaar,
  hebben server-side opt-out en rate limits en bewaren berichten maximaal 24
  uur.
- Conclaves ondersteunen 4–20 leden, afgeschermde rollen, aanvragen en
  uitnodigingen, een tijdelijke chat, een Conclave Chronicle en tien groeiende
  Aerie-fasen.
- RLS, ingetrokken directe tabelrechten, afgeschermde RPC's en row locks vormen
  de beveiligingsgrens. De dagelijkse Aerie-ledger voorkomt dat ledenwissels de
  daglimiet omzeilen.
- Met maximaal twintig dagelijkse bijdragen kan Aerie-fase 10 op zijn vroegst
  na 192 dagen worden bereikt; daarmee blijft de grootste vorm minimaal een
  half jaar verwijderd.
- De lokale analyzer, 347 tests, sprite-alpha-audits en de ondertekende
  v0.05.00-productie-APK zijn groen.

De stagingworkflow test naast de bestaande Friends-, trade- en volledige Group
Adventure-flow nu ook Friend Messages (ongelezen, lezen en opt-out) en Conclaves
(genormaliseerd unieke naam, join, Warden-rang, chat, Aerie-bijdrage en volledige
cleanup). De gebruiker heeft staging, productiemigratie 30 en release v0.05.00
op 31 augustus 2026 expliciet toegestaan.

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

- migraties: 24 lokaal en 24 remote;
- database lint: 0 fouten voor `extensions`, `private` en `public`;
- Auth health: HTTP 200;
- Auth settings: HTTP 200;
- e-mailauth: geconfigureerd.

Deze huidige productie-uitkomst is opnieuw bewezen door
[migratierun 33204827275](https://github.com/Rakky88/DragonHaven/actions/runs/33204827275)
en [release-gate 33204987488](https://github.com/Rakky88/DragonHaven/actions/runs/33204987488).
De release mag niet worden gepubliceerd wanneer deze preflight op een later
moment een mismatch of fout meldt.

### Vormspecifieke Expertise en Group Adventures

Migratie `202608280024_variable_expertise_caps.sql` bewaakt dezelfde maxima als
de client: 350 voor een normale Ascension-specialisatie, 350 op alle drie bij
Mastery, en voor Infernal 350 standaard plus 400 op de specialisatie. De
server valideert dit bij Group Adventure-draken, rewards en openbare favoriete-
draakprofielen. De exacte 23→24-dry-run en nacontrole zijn groen uitgevoerd.

### Automatische back-up en gratis monitoring

- Betekenisvolle lokale voortgang wordt na een wijziging automatisch naar de
  bestaande revision-locked cloudsave geschreven, in de voorgrond maximaal
  eenmaal per vijftien minuten en met een directe veilige flush bij achtergrond.
- De wekelijkse stagingworkflow herstelt zowel de actuele als een historische
  cloudrevisie; [run 33205758376](https://github.com/Rakky88/DragonHaven/actions/runs/33205758376)
  heeft de eerste volledige roundtrip bewezen.
- De productie-Auth-healthcheck draait ieder uur, bewaart dertig dagen bewijs
  en opent bij uitval één aan Rick toegewezen SEV-1-issue. De groene basis is
  vastgelegd in [run 33205759992](https://github.com/Rakky88/DragonHaven/actions/runs/33205759992).

## Bewuste servergrenzen

- De algemene offline economie is nog client-state. Een toekomstige
  storeversie met echte betalingen vereist server-authoritative economy-RPC's,
  idempotency keys en Google Play receiptvalidatie.
- Back-ups hebben optimistische revisievergrendeling, automatische uploads,
  maximaal vijf herstelbare revisies gedurende dertig dagen en een expliciete
  conflictkeuze, maar nog geen automatische merge van gelijktijdige
  apparaatwijzigingen.
- De app toont herstelbare fouten en timeouts; centrale error-rate-, latency- en
  capacity-alerting moet buiten de client worden ingericht.
- Account-specifieke support hoort op Keeper ID/user UUID en serverlogs te
  werken, niet op de zichtbare keepernaam alleen.

## Aanbevolen volgende serverstappen

1. Koppel na ontvangst van `google-services.json` Firebase Crashlytics en
   Performance en voeg daarna een veilige read-only applicatie-RPC aan de
   bestaande healthcheck toe.
2. Verplaats coin-, gem-, chest- en relicmutaties naar idempotente server-RPC's
   voordat echte aankopen worden geactiveerd.
3. Controleer de eerste automatisch geplande zondagse restore-integriteitsrun
   en daarna maandelijks het bewijs; RPO/RTO en automatische back-up zijn
   inmiddels vastgelegd en gebouwd.
4. Automatiseer de resterende staging-e-mailconfirmatie; Group Adventure
   starten, afronden en idempotent belonen is inmiddels volledig bewezen met
   begrensde, automatisch opgeruimde stagingfixtures.

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

Deze tranche was tijdens de eerste controle nog niet naar productie gemigreerd.
Zij is inmiddels gecontroleerd uitgerold in v0.04.08. De voorafgaande geïsoleerde
[stagingrun 33188269327](https://github.com/Rakky88/DragonHaven/actions/runs/33188269327)
paste migratie 21 toe en bewees 21/21 parity, schema-lint/preflight, analyzer,
256 tests en een staging-APK. De bevestigde-accountflow in
[run 33189927346](https://github.com/Rakky88/DragonHaven/actions/runs/33189927346)
bewees vervolgens dat importstatus en rapport-RPC coherent blijven. Een
handmatig, gecontroleerd rollbackcommando blijft apart open; de herstelkopie is
al beschikbaar, maar wordt bewust niet via de app uitvoerbaar gemaakt.

### Herstelbare cloudrevisies en expliciete conflictafhandeling

De volgende gratis, database-native back-upstap is daarna gebouwd:

- iedere cloudsave heeft een willekeurig save-ID, parent revision, apparaat-ID,
  clientversie, saveschema en servertijd;
- de huidige plus vier vorige revisies blijven herstelbaar, waarbij oude
  historie na dertig dagen fysiek wordt verwijderd door een dagelijkse
  Supabase Cron-databasejob en ook tijdens nieuwe uploads wordt opgeschoond;
- directe tabeltoegang blijft ingetrokken en uitsluitend ingelogde RPC's kunnen
  eigen revisiemetadata of een eigen herstelkopie lezen;
- een conflictvenster biedt cloud bekijken, voorlopig lokaal houden, na een
  tweede bevestiging lokaal naar cloud vervangen, of cloud herstellen;
- de vorige cloudkopie blijft na een bewuste vervanging als herstelbare revisie
  bestaan en iedere restore houdt daarnaast een lokale recovery copy;
- `tool/staging_auth_e2e.ps1` maakt twee opeenvolgende revisies, leest de vorige
  op save-ID terug en bewijst opnieuw dat een stale write atomair wordt
  geweigerd.

Migraties 21–23 zijn op 28 augustus 2026 via de apart begrensde
[productiemigratierun 33198153589](https://github.com/Rakky88/DragonHaven/actions/runs/33198153589)
uitgerold. De workflow accepteerde uitsluitend de exacte productiestand 20,
bewees eerst de dry-run en controleerde na toepassing 23/23 parity,
database-lint en publieke Auth.

[Stagingrun 33193296552](https://github.com/Rakky88/DragonHaven/actions/runs/33193296552)
bewees vervolgens 23/23 migratiepariteit, foutloze database-lint/preflight,
twee echte cloudrevisies, readback van de oudere save, atomair weigeren van een
stale write, een groene analyzer, 259 tests en een nieuwe staging-APK. De
databasejob is met de migratie geïnstalleerd; periodieke controle van de
daadwerkelijke jobuitvoering en een geplande restore-oefening blijven open.

Na het vervangen van de verouderde CI-runtimes bewees
[stagingrun 33194122823](https://github.com/Rakky88/DragonHaven/actions/runs/33194122823)
dezelfde 23/23 migratie-, lint-, test-, APK- en artifactgrens opnieuw met
`supabase/setup-cli@v3` en `actions/upload-artifact@v6`. De afzonderlijke
[productie-healthrun 33194121092](https://github.com/Rakky88/DragonHaven/actions/runs/33194121092)
controleerde de publieke Auth-endpoints read-only en bewaarde het privacyarme
bewijsartifact succesvol.

Zie [DRAGONHAVEN_POST_AUDIT_PLAN.md](DRAGONHAVEN_POST_AUDIT_PLAN.md) en
[INCIDENT_RUNBOOK.md](INCIDENT_RUNBOOK.md) voor eigenaarschap, vervolgfasen en
incidentafhandeling. De wijzigingen staan op `main`, staging en productie en
zijn uitgebracht als [v0.04.09](https://github.com/Rakky88/DragonHaven/releases/tag/v0.04.09).
De [productiegate 33204987488](https://github.com/Rakky88/DragonHaven/actions/runs/33204987488)
en [taggate 33205588983](https://github.com/Rakky88/DragonHaven/actions/runs/33205588983)
bewezen opnieuw 24/24 migraties, lint/Auth, analyzer, 270 tests en de vaste
ondertekening van de Play-ready AAB.
