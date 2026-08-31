# DragonHaven serververbeteringen — v0.05.01

## Productie v0.05.01 — gecontroleerde uitrol voltooid

Productie staat gecontroleerd op migratie 32/32. Migraties
`202608310030_friend_messages_and_conclaves.sql` en
`202608310031_fix_conclave_function_ambiguity.sql` zijn pas na de uitgebreide
staging-E2E, database-lint, dry-run en exacte 29→31-begrenzing naar productie
gebracht. Migratie 31 corrigeert idempotent de twee kolomambiguïteiten die de
eerste geïsoleerde stagingpoging na migratie 30 vond; productie is tijdens die
correctieronde onaangeraakt gebleven.

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
- Analyzer, 347 tests, sprite-alpha-audits, compacte/reduced-motion
  emulatorcontrole, de ondertekende v0.05.00-productie-APK en beide
  Play-ready AAB/signinggates zijn groen.

v0.05.01 voegt daar migratie
`202608310032_public_application_health.sql` aan toe. De publieke, read-only
`security invoker`-RPC leest geen speler-, account- of gameplaytabel en geeft
alleen vaste servicestatus, contractversie en de databaseklok terug. De
31→32-productieworkflow accepteerde uitsluitend de exact verwachte beginstand,
lintte en dry-runde vóór toepassing en eiste daarna volledige parity, Auth én
applicatiehealth. Analyzer, 349 tests, een exacte 360×640-dp/reduced-motion
emulatorcontrole, de ondertekende v0.05.01-APK en Play-ready AAB zijn groen.

Voor v0.05.00 testte de stagingworkflow naast de bestaande Friends-, trade- en
volledige Group Adventure-flow ook Friend Messages (ongelezen, lezen en opt-out)
en Conclaves (genormaliseerd unieke naam, join, Warden-rang, chat,
Aerie-bijdrage en volledige cleanup).
[Stagingrun 33396777406](https://github.com/Rakky88/DragonHaven/actions/runs/33396777406),
[productiemigratie 33397552524](https://github.com/Rakky88/DragonHaven/actions/runs/33397552524),
[productiegate 33397872901](https://github.com/Rakky88/DragonHaven/actions/runs/33397872901),
[taggate 33398718801](https://github.com/Rakky88/DragonHaven/actions/runs/33398718801)
en [post-release healthcheck 33399531445](https://github.com/Rakky88/DragonHaven/actions/runs/33399531445)
zijn groen. Die v0.05.00-preflight bewees 31/31 migratiepariteit,
0 database-lintfouten, Auth health/settings 200/200 en geconfigureerde e-mailauth.

## Applicatiehealth — op staging en productie bewezen

Migratie `202608310032_public_application_health.sql` voegt een publieke,
read-only `security invoker`-RPC toe die geen spelers-, account- of
gameplaytabel leest. Hij retourneert uitsluitend een vaste servicestatus,
contractversie en servertijd. De uurlijkse monitor en verplichte releasepreflight
controleren daarmee na activering niet alleen Auth, maar ook het echte
Supabase-gateway → PostgREST → PostgreSQL-pad en een klokafwijking van maximaal
vijf minuten.

De positieve en negatieve contracttests, PowerShell-parser, bestaande live
Auth-check, analyzer en de toenmalige 348/348 Flutter-tests zijn groen. Ook
[stagingrun 33402550922](https://github.com/Rakky88/DragonHaven/actions/runs/33402550922)
is volledig geslaagd: migratie 32, database-lint/preflight, de nieuwe endpoint-
en klokcontrole, volledige sociale en Group Adventure-E2E en staging-APK.
De exact begrensde `production-migrate-32.yml` controleerde productie op
beginstand 31, lint en dry-run, paste uitsluitend migratie 32 toe en eiste
daarna volledige preflight en applicatiehealth. Dit is groen bewezen in
[productiemigratie 33414590573](https://github.com/Rakky88/DragonHaven/actions/runs/33414590573).
De onafhankelijke preflight mat daarna 32/32 migraties, 0 lintfouten, Auth
200/200, applicatiehealth 200, contractversie 1 en 94 ms klokafwijking. De
[v0.05.01-taggate 33415060428](https://github.com/Rakky88/DragonHaven/actions/runs/33415060428)
en [post-release healthcheck 33415782470](https://github.com/Rakky88/DragonHaven/actions/runs/33415782470)
zijn eveneens groen; de uurlijkse monitor gebruikt nu standaard beide publieke
healthpaden.

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

Op 31 augustus 2026 is voor v0.05.01 uitgevoerd:

```powershell
powershell -ExecutionPolicy Bypass -File .\tool\release_server_preflight.ps1 `
  -SupabaseCli .\.tools\supabase-2.115.0\supabase.exe
```

Resultaat:

- migraties: 32 lokaal en 32 remote;
- database lint: 0 fouten voor `extensions`, `private` en `public`;
- Auth health: HTTP 200;
- Auth settings: HTTP 200;
- e-mailauth: geconfigureerd;
- applicatiehealth: HTTP 200, service `dragonhaven-online`, contractversie 1;
- databaseklokafwijking tijdens de onafhankelijke meting: 94 ms.

Deze productie-uitkomst is onafhankelijk en via CI bewezen door
[migratierun 33414590573](https://github.com/Rakky88/DragonHaven/actions/runs/33414590573),
[release-gate 33415060428](https://github.com/Rakky88/DragonHaven/actions/runs/33415060428)
en [healthrun 33415782470](https://github.com/Rakky88/DragonHaven/actions/runs/33415782470).
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
   Performance. De veilige read-only applicatie-RPC en uurlijkse gecombineerde
   healthcheck zijn inmiddels actief; bewijs nog een gecontroleerde
   niet-productie testalert.
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
