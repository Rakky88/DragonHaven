# Rewarded ads activeren

Status op 23 september 2026: de integratie is voorbereid en staat veilig uit.
De app laadt zonder expliciete productieconfiguratie geen advertenties en de
server geeft geen nieuwe advertentieclaims uit. Het configuratiescript voert
zelf geen deploy, release of serverwijziging uit.

De ingestelde beloningen zijn:

| Ad unit | Beloning | Daglimiet |
|---|---:|---:|
| Free Gems | 15 gems | 3 per UTC-dag |
| Free Coins | 150 coins | 3 per UTC-dag |

De limieten gelden apart. Alleen een geldig door Google ondertekend
server-side-verification-bericht (SSV) kan een eenmalige serverclaim
bevestigen. De app telt een lokale advertentiecallback nooit zelf als betaling.

## 1. Dit moet je zelf in Google regelen

Deze stappen gebruiken jouw Google-account. Deel geen wachtwoord, herstelcode,
identiteitsdocument, betaalgegevens, Supabase service-role-key of andere
inloggegevens.

1. Ga naar <https://admob.google.com/>, rond de accountregistratie af en
   controleer land, tijdzone en valuta voordat je bevestigt. Google kan om
   identiteits- en betalingsgegevens vragen.
2. Kies in AdMob **Apps -> Add app**, platform **Android**, naam
   **DragonHaven**, package name `nl.dragonhaven.app`. Een app kan eerst als
   niet-gepubliceerd worden toegevoegd. Koppel de openbare storevermelding
   zodra die bestaat; Google kan advertentieweergave beperken zolang de app
   niet in een ondersteunde store is geverifieerd.
3. De openbare Android app-ID voor DragonHaven is
   `ca-app-pub-3222375776323902~3757705110`.
4. Maak twee afzonderlijke ad units van het type **Rewarded**:

   | Naam in AdMob | Reward amount | Reward item |
   |---|---:|---|
   | Free Gems | 15 | `gems` |
   | Free Coins | 150 | `coins` |

   De productie-ID voor Free Gems is
   `ca-app-pub-3222375776323902/8546997361`; die voor Free Coins is
   `ca-app-pub-3222375776323902/6805531120`.
5. Laat de server-side-verification-instellingen bij beide ad units nog open
   totdat het hulpscript is uitgevoerd en de callback is gedeployed. In stap 4
   staat precies hoe je Google's **Verify URL** veilig uitvoert. In normale
   advertenties levert DragonHaven zelf een korte, willekeurige en eenmalige
   `custom_data`-waarde en wordt geen vast `user_id` meegestuurd.
6. Open **Privacy & messaging** en publiceer voor DragonHaven ten minste de
   toepasselijke Europese-regelgevingsmelding. De app gebruikt Google's User
   Messaging Platform (UMP) en vraagt toestemming voordat een advertentie
   wordt geladen.
7. Registreer de Android-telefoon waarmee je gaat controleren als
   **testapparaat** in AdMob. Gebruik bij het testen nooit gewone live
   advertentieklikken op je eigen apparaat.
8. De publisher-ID is `pub-3222375776323902`. Stel in de storevermelding
   `https://rakky88.github.io/` in als ontwikkelaarswebsite.

## 2. Laat het hulpscript alle openbare ID's controleren

Maak eerst de definitieve commit waarvan later de SSV-functie en de app worden
uitgebracht. Voer daarna vanuit de repository uit:

```powershell
./tool/configure_rewarded_ads.ps1 `
  -AndroidAppId 'ca-app-pub-3222375776323902~3757705110' `
  -GemsAdUnitId 'ca-app-pub-3222375776323902/8546997361' `
  -CoinsAdUnitId 'ca-app-pub-3222375776323902/6805531120' `
  -PublisherId 'pub-3222375776323902'
```

Het script weigert ongeldige formaten, Google's voorbeeld-ID's, gelijke ad
units en ID's uit verschillende publisheraccounts. Het leest automatisch de
volledige huidige Git-commit en maakt vier genegeerde lokale bestanden:

- `.tools/rewarded-ads-build-defines.json` voor een interne productiebuild;
- `.tools/rewarded-ads-ssv-secrets.env` voor de Supabase SSV-functie;
- `.tools/rewarded-ads-ssv-setup.json` met de tijdelijke gegevens voor Google's
  **Verify URL**-controle;
- `.tools/app-ads.txt` voor de ontwikkelaarswebsite.

De map `.tools` staat in `.gitignore`. De vier AdMob-ID's zijn openbare
configuratie; account- en serversleutels worden niet in deze bestanden gezet.
Het script print de precieze vervolgcommando's, maar voert ze niet uit. In de
eerste GitHub-opdracht blijft `DRAGONHAVEN_REWARDED_ADS_ENABLED` bewust
`false`.

Als je na het uitvoeren nog een commit maakt, voer het script opnieuw uit. De
Supabase-secret `REWARDED_AD_SSV_SOURCE_REVISION` moet steeds exact gelijk zijn
aan de commit die je wilt uitbrengen. De releasecontrole vergelijkt deze waarde
met `GITHUB_SHA` en stopt veilig bij ieder verschil.

## 3. Publiceer app-ads.txt

De ontwikkelaarswebsite is:

`https://rakky88.github.io/`

De privacyverklaring staat op:

`https://rakky88.github.io/privacy.html`

Het gegenereerde `.tools/app-ads.txt` is ongewijzigd gepubliceerd op:

`https://rakky88.github.io/app-ads.txt`

Het openbare bestand bevat precies deze vorm:

```text
google.com, pub-3222375776323902, DIRECT, f08c47fec0942fa0
```

Controleer na publicatie dat er geen HTML, loginpagina of redirect naar een
ander domein wordt teruggegeven:

```powershell
(Invoke-WebRequest 'https://rakky88.github.io/app-ads.txt').Content.Trim()
```

De teruggegeven regel moet exact gelijk zijn aan `.tools/app-ads.txt`.

## 4. Veilige eerste serverinstallatie

Voer deze stappen pas uit wanneer de AdMob-ID's bestaan. Laat zowel de
server-kill-switch als de GitHub-enable-variable tijdens deze installatie uit.

1. Controleer de code lokaal:

   ```powershell
   deno check supabase/functions/rewarded-ad-ssv/index.ts
   deno test supabase/functions/rewarded-ad-ssv/
   flutter test test/rewarded_ad_test.dart test/rewarded_ads_coordinator_test.dart test/rewarded_ads_migration_contract_test.dart test/rewarded_ads_privacy_contract_test.dart
   ```

2. Voer de door het hulpscript geprinte `gh variable set`-commando's uit. Houd
   `DRAGONHAVEN_REWARDED_ADS_ENABLED` hierbij op `false`.
3. Controleer de databasemigraties eerst zonder iets toe te passen:

   ```powershell
   supabase migration list --linked --output-format json
   supabase db push --linked --dry-run
   ```

   Migratie `202609230094_rewarded_ads.sql` is al op productie toegepast. Deze
   is veilig en slapend: de server-kill-switch staat standaard op `false`.
   Migratie `202609230095_rewarded_ads_privacy_notice.sql` blijft uit totdat de
   definitieve releasecommit klaar is. De migratie bevat bewust een
   compatibiliteitsbrug: de uitgebrachte client mag via de bestaande no-arg
   RPC verklaring `2026-09-20` blijven gebruiken, de nieuwe client vraagt via
   een versiegebonden RPC exact om `2026-09-23`, en alleen die nieuwe
   bevestiging maakt rewarded ads beschikbaar. Een nieuwe bevestiging kan niet
   door een oudere client worden teruggezet. Dezelfde migratie repareert de
   JSONB-arraycontrole in het nog slapende reward-commitpad.
4. Stel de gegenereerde functieconfiguratie in en deploy de publieke
   SSV-callback. Gebruik de exacte commando's die het hulpscript print:

   ```powershell
   supabase secrets set --project-ref tnzathhutuwmohmjfrlo --env-file ".tools/rewarded-ads-ssv-secrets.env"
   supabase functions deploy rewarded-ad-ssv --project-ref tnzathhutuwmohmjfrlo --no-verify-jwt --use-api
   ```

   `--no-verify-jwt` is hier vereist omdat Google geen DragonHaven-login-token
   naar de callback stuurt. De functie accepteert pas iets nadat zij Google's
   P-256-handtekening, het ad-unit-ID en de rewardgegevens heeft gecontroleerd.
5. Controleer het openbare health-contract:

   ```powershell
   Invoke-RestMethod 'https://tnzathhutuwmohmjfrlo.supabase.co/functions/v1/rewarded-ad-ssv?health=1'
   ```

   Het antwoord moet `service: rewarded-ad-ssv`, `contractVersion: 1`, de
   huidige volledige Git-commit en exact beide productie-ad-unit-ID's tonen.
6. Verifieer nu bij **beide** rewarded ad units de SSV-callback in AdMob. Open
   **Advertentieblok -> Geavanceerde instellingen -> Server-side verification
   -> Set up and verify callback URL** en vul exact in:

   - **Callback URL:**
     `https://tnzathhutuwmohmjfrlo.supabase.co/functions/v1/rewarded-ad-ssv`
   - **User ID:** `dragonhaven-ssv-setup`
   - **Custom data:** de waarde `customData` uit
     `.tools/rewarded-ads-ssv-setup.json`

   Klik **Verify URL**, daarna **Use verified URL** en sla de ad unit op.
   Herhaal dit voor Free Gems en Free Coins. De gereserveerde user-ID en deze
   vaste custom-data zijn uitsluitend voor Google's ondertekende
   installatiecontrole. De callback controleert daarbij Google's
   handtekening, de door AdMob gebruikte test-unit en de exacte beloning, maar
   roept geen opslag- of rewardfunctie aan. Gebruik deze twee testvelden dus
   niet als speler-ID of als vaste waarden in de app; gewone
   DragonHaven-advertenties sturen geen `user_id` en gebruiken per claim andere
   `custom_data`.
7. Pas tijdens de uiteindelijke releasevoorbereiding alleen de ene verwachte
   migratie toe, terwijl `issue_enabled=false` blijft. Controleer direct erna
   dat er geen databaselintfouten zijn:

   ```powershell
   supabase db push --linked --dry-run
   supabase db push --linked
   supabase migration list --linked --output-format json
   supabase db lint --linked --level error --fail-on error --output-format json
   ```

   De dry-run moet uitsluitend
   `202609230095_rewarded_ads_privacy_notice.sql` noemen. Stop wanneer de
   pending set anders is of de lintcontrole iets teruggeeft.
8. Voer daarna de volledige serverpreflight uit. Hiervoor moeten de checkout
   aan het juiste Supabase-project gekoppeld en `SUPABASE_ACCESS_TOKEN` gezet
   zijn:

   ```powershell
   $revision = (git rev-parse HEAD).Trim()
   ./tool/release_server_preflight.ps1 `
     -RequireRewardedAds `
     -ExpectedRewardedGemsAdUnitId 'ca-app-pub-3222375776323902/8546997361' `
     -ExpectedRewardedCoinsAdUnitId 'ca-app-pub-3222375776323902/6805531120' `
     -ExpectedRewardedSsvSourceRevision $revision
   ```

De preflight controleert ook dat de functie actief en publiek bereikbaar is,
dat JWT-controle daar bewust uit staat, dat de bundle bestaat, dat database en
migraties overeenkomen en dat de overige server-healthchecks slagen.

## 5. De kill-switch bekijken, testen en terugzetten

Voer de volgende SQL in de Supabase SQL Editor uit om de huidige waarden te
bekijken:

```sql
select issue_enabled, daily_limit, gems_reward, coins_reward, claim_lifetime
from private.rewarded_ad_runtime
where singleton = true;
```

Installeer vóór de end-to-end-test een intern ondertekende releasebuild op het
geregistreerde AdMob-testapparaat:

```powershell
flutter build apk --release --dart-define-from-file=.tools/rewarded-ads-build-defines.json
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

Controleer dat AdMob het apparaat echt als testapparaat behandelt. Zet pas dan
in de SQL Editor tijdelijk nieuwe claims aan:

```sql
begin;
update private.rewarded_ad_runtime
set issue_enabled = true
where singleton = true;

select issue_enabled, daily_limit, gems_reward, coins_reward
from private.rewarded_ad_runtime
where singleton = true;
commit;
```

Test met een serveraccount ten minste eenmaal Free Gems en eenmaal Free Coins.
Controleer dat de app na de Google-bevestiging precies 15 gems respectievelijk
150 coins toevoegt, dat sluiten vóór voltooiing niets direct uitbetaalt en dat
de teller per shop afloopt. Een vertraagde SSV kan tijdelijk als
`Reward pending` verschijnen en wordt bij de volgende serverreconciliatie
alsnog eenmaal verwerkt.

Zet de server direct na deze interne test weer uit totdat een productie-uitrol
expliciet is gepland:

```sql
begin;
update private.rewarded_ad_runtime
set issue_enabled = false
where singleton = true;

select issue_enabled
from private.rewarded_ad_runtime
where singleton = true;
commit;
```

## 6. Later activeren voor een release

Gebruik voor een advertentie-release deze volgorde:

1. Maak eerst de definitieve releasecommit.
2. Voer `configure_rewarded_ads.ps1` opnieuw uit op die commit.
3. Zet de gegenereerde SSV-secrets opnieuw en deploy
   `rewarded-ad-ssv` opnieuw, ook wanneer alleen andere appcode veranderde.
4. Controleer dat `issue_enabled=false` is en blijft tijdens migratie, build en
   publicatie.
5. Laat de migratie-dry-run exact alleen migratie 95 tonen, pas deze toe en
   eis daarna nul databaselintfouten. De compatibiliteitsbrug houdt versie
   0.06.06 bruikbaar terwijl versie 0.06.07 de nieuwe verklaring vraagt.
6. Laat de rewarded-ad-serverpreflight slagen met exact die commit en ID's.
7. Test een interne, ondertekende productie-ID-build op een geregistreerd
   AdMob-testapparaat. Zet `issue_enabled` alleen voor die test kort aan en
   direct daarna weer uit.
8. Zet de GitHub Variable voor de nieuwe build aan:

   ```powershell
   gh variable set DRAGONHAVEN_REWARDED_ADS_ENABLED --body 'true'
   ```

9. Bouw, publiceer en verifieer de expliciet aangevraagde release terwijl de
   server-kill-switch nog uit staat. Installeer de gepubliceerde APK als update
   en controleer aanmelden, Account Info, Shop en de overige gameplay.
10. Zet pas na die controles `issue_enabled=true`, voer eenmaal Free Gems en
    eenmaal Free Coins uit en bewaak de functie- en serverlogs. Zet de switch
    bij iedere fout direct terug op `false`; de rest van het spel blijft dan
    beschikbaar en de reeds gepubliceerde app toont de advertentieknoppen als
    tijdelijk niet beschikbaar.

Bij iedere latere releasecommit moeten stappen 2, 3 en 6 opnieuw gebeuren,
omdat de releaseworkflow de gedeployde SSV-broncommit met `GITHUB_SHA`
vergelijkt. Migratie 95 hoeft na de eerste bijpassende release niet opnieuw.

## Directe rollback

Bij een storing stopt deze SQL onmiddellijk het uitgeven van nieuwe claims:

```sql
update private.rewarded_ad_runtime
set issue_enabled = false
where singleton = true
returning issue_enabled;
```

Zet ook de volgende build terug naar de veilige stand:

```powershell
gh variable set DRAGONHAVEN_REWARDED_ADS_ENABLED --body 'false'
```

Een al door Google bevestigde transactie blijft idempotent afhandelbaar. De
kill-switch voorkomt nieuwe advertentieserverclaims, maar maakt een geldige
lopende beloning niet dubbel en laat een replay geen tweede betaling doen.

## Veelvoorkomende blokkades

- `rewarded_ad_configuration_missing`: een functie-secret ontbreekt of de
  broncommit is geen volledige commit van 40 hextekens. Voer het hulpscript
  opnieuw uit, zet de gegenereerde secrets en deploy de functie opnieuw.
- De releasepreflight meldt een andere bron of ander ad-unit-ID: er is na de
  laatste functiedeploy nog een commit gemaakt, of AdMob en Supabase gebruiken
  verschillende ID's. Herhaal configuratie en deploy vanaf de releasecommit.
- De advertentiekaart blijft uit: controleer eerst `issue_enabled`, UMP-consent,
  AdMob app-readiness en of de geïnstalleerde build werkelijk in
  `production`-advertentiemodus is gebouwd.
- Een reward blijft tijdelijk pending: klik niet steeds opnieuw. Controleer de
  `rewarded-ad-ssv`-functielogs en open de shop opnieuw zodat de app de
  serverstatus reconcilieert.
- AdMob ziet `app-ads.txt` niet: controleer de ontwikkelaarswebsite in de
  storevermelding, HTTPS, het hoofddomein en de exacte openbare regel.

## Wat de code afdwingt

- UMP-toestemming wordt vóór een advertentieverzoek verwerkt.
- Elke advertentie krijgt een accountgebonden, korte en eenmalige serverclaim.
- Alleen een geldige Google P-256-handtekening en de twee geconfigureerde
  ad-unit-ID's worden geaccepteerd.
- Reward item en bedrag moeten exact `gems`/15 of `coins`/150 zijn.
- Een Google transaction-ID kan maar eenmaal worden verwerkt.
- De server telt maximaal drie bevestigde claims per shop per UTC-dag.
- Walletwijziging en claimverbruik gebeuren atomair in de canonieke
  servertransactie.
- Productie-ID's komen alleen in een expliciet geactiveerde productiebuild.

Officiële naslag:

- Flutter Mobile Ads: <https://developers.google.com/admob/flutter/quick-start>
- Privacy en UMP: <https://developers.google.com/admob/flutter/privacy>
- Rewarded ads: <https://developers.google.com/admob/flutter/rewarded>
- Server-side verification: <https://developers.google.com/admob/flutter/ssv>
- Testadvertenties: <https://developers.google.com/admob/flutter/test-ads>
- app-ads.txt: <https://support.google.com/admob/answer/9363762>
