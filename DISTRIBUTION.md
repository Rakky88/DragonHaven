# DragonHaven publiceren en updaten

Voor de complete Google Play/App Store-checklist, verantwoordelijkheden,
productiebeveiliging en kostenramingen: [PUBLIC_LAUNCH.md](PUBLIC_LAUNCH.md).

De update- en kopieerknoppen in **About DragonHaven** gebruiken de nieuwste openbare GitHub Release. Android vraagt altijd zelf om bevestiging voordat een APK wordt geïnstalleerd.

## Updatecompatibiliteit

De zichtbare app en het releasebestand heten **DragonHaven**. Het vaste Android application ID is `nl.dragonhaven.app`. Dit is bewust een nieuwe app; oudere installaties met het voormalige ID mogen worden verwijderd. Alle toekomstige DragonHaven-versies moeten dit nieuwe ID behouden.

Android accepteert een update alleen wanneer iedere release met dezelfde privésleutel is ondertekend. Bewaar de bestaande keystore veilig en commit nooit de keystore of `android/key.properties`.

De releaseworkflow verwacht deze GitHub-secrets:

- `DRAGONHAVEN_KEYSTORE_BASE64`
- `DRAGONHAVEN_KEYSTORE_PASSWORD`
- `DRAGONHAVEN_KEY_ALIAS`
- `DRAGONHAVEN_KEY_PASSWORD`
- `SUPABASE_ACCESS_TOKEN`
- `SUPABASE_DB_PASSWORD`

De secret-namen blijven om compatibiliteitsredenen gelijk; ze zijn niet zichtbaar in de app.

### Eenmalige GitHub-inrichting voor productie

Open `https://github.com/Rakky88/DragonHaven`, klik bovenaan **Settings**, kies
links onder **Security** voor **Secrets and variables → Actions**, open het
tabblad **Secrets** en klik voor iedere waarde op **New repository secret**.
Vul bij **Name** exact de hieronder genoemde secretnaam in en plak bij
**Secret** alleen de bijbehorende waarde. Klik daarna op **Add secret**. Deel de
waarden niet via chat en zet ze nooit in Git.

#### `DRAGONHAVEN_KEYSTORE_BASE64`

Deze waarde staat niet als tekstbestand op de computer. Maak hem zo zonder hem
in beeld te tonen:

1. Open Windows Verkenner en ga naar
   `C:\Users\groot\python projects\ChoreQuest\.release-staging-v00109`.
2. Klik in de adresbalk, typ `powershell` en druk Enter. PowerShell opent dan in
   de juiste map.
3. Plak deze opdracht en druk Enter:

  ```powershell
  [Convert]::ToBase64String(
    [IO.File]::ReadAllBytes(
      (Resolve-Path '.\android\app\dragonhaven-release.jks')
    )
  ) | Set-Clipboard
  ```

4. Er verschijnt bewust geen tekst; de waarde staat nu op het klembord.
5. Maak in GitHub de secret `DRAGONHAVEN_KEYSTORE_BASE64`, klik in het veld
   **Secret**, druk Ctrl+V en sla hem op.

Dit gebruikt `android/app/dragonhaven-release.jks`, de bestaande releasekey.
Maak geen nieuwe keystore.

#### De drie signingvelden uit `key.properties`

1. Open in Verkenner
   `C:\Users\groot\python projects\ChoreQuest\.release-staging-v00109\android`.
2. Klik met rechts op `key.properties`, kies **Openen met → Kladblok**.
3. Maak drie GitHub-secrets en kopieer telkens alleen de tekst rechts van het
   `=`-teken, zonder `=` en zonder extra spaties:

   | Regel in `key.properties` | GitHub-secretnaam |
   | --- | --- |
   | `storePassword=...` | `DRAGONHAVEN_KEYSTORE_PASSWORD` |
   | `keyAlias=...` | `DRAGONHAVEN_KEY_ALIAS` |
   | `keyPassword=...` | `DRAGONHAVEN_KEY_PASSWORD` |

4. Sluit Kladblok zonder het bestand te wijzigen.

#### `SUPABASE_ACCESS_TOKEN`

Dit is een accounttoken voor de Supabase CLI, niet de key van de app:

1. Open `https://supabase.com/dashboard/account/tokens` en log in met het
   Supabase-account dat het productieproject bezit.
2. Klik **Generate new token**.
3. Geef hem een herkenbare naam, bijvoorbeeld
   `DragonHaven GitHub Production`.
4. Kies indien gevraagd een vervaldatum en noteer een herinnering vóór die
   datum.
5. Klik om de token te maken en kopieer de getoonde `sbp_...`-waarde meteen;
   deze is later niet opnieuw volledig zichtbaar.
6. Maak in GitHub `SUPABASE_ACCESS_TOKEN`, plak de waarde en sla hem op.

#### `SUPABASE_DB_PASSWORD`

Dit is het databasewachtwoord dat bij het aanmaken van het productieproject is
gekozen. Supabase toont het bestaande wachtwoord niet opnieuw.

1. Zoek eerst in de wachtwoordmanager of beveiligde notitie waarin het
   Supabase-productiewachtwoord destijds is opgeslagen.
2. Maak in GitHub `SUPABASE_DB_PASSWORD` en plak dat wachtwoord.
3. Als het nergens meer staat: reset het nog niet direct. Het kan via het
   productieproject onder **Project Settings → Database → Reset database
   password**, maar daarna moeten alle CLI- en databaseverbindingen tegelijk
   worden bijgewerkt. Laat Codex die rotatie eerst voorbereiden.

GitHub toont een opgeslagen secretwaarde later niet meer. Controleer alleen de
namen via **Actions secrets**; de releaseworkflow controleert zelf vroegtijdig
of alle zes waarden aanwezig zijn. Start de releaseworkflow niet alleen om dit
te testen: een afzonderlijke, niet-publicerende verificatierun wordt eerst door
Codex voorbereid en beoordeeld.

### Gratis stagingvoorbereiding

De handmatige workflow `Android staging verification` is voorbereid voor een
volledig afgescheiden Supabase-stagingproject. Hij draait niet automatisch en
kan productie niet als staging accepteren. Maak in GitHub een Environment met
de naam `staging` en plaats daar later rechtstreeks deze waarden:

- `STAGING_SUPABASE_URL`
- `STAGING_SUPABASE_PUBLISHABLE_KEY`
- `STAGING_SUPABASE_PROJECT_REF`
- `STAGING_SUPABASE_ACCESS_TOKEN`
- `STAGING_SUPABASE_DB_PASSWORD`

Begin waar mogelijk met de gratis Supabase-tier. De workflow controleert
migration parity, database-lint en Auth, voert Flutter-analyse en tests uit en
bouwt een aparte debug-APK met `DRAGONHAVEN_ENVIRONMENT=staging`. Een staging-
build weigert de vaste productieserver als fallback.

Maak staging als volgt aan:

1. Open `https://supabase.com/dashboard` en log in.
2. Klik **New project**. Kies bij **Organization** bij voorkeur dezelfde gratis
   organisatie waarin productie staat.
3. Vul bij **Project name** `dragonhaven-staging` in.
4. Maak bij **Database password** een nieuw, uniek wachtwoord. Kopieer dit nu
   naar een wachtwoordmanager met label `DragonHaven staging database`; dit
   wordt later `STAGING_SUPABASE_DB_PASSWORD`. Hergebruik productie niet.
5. Kies bij **Region** `West EU (Ireland)` en laat het project aanmaken. Kies
   geen betaalde upgrade of add-on.
6. Wacht op het projectscherm totdat het project gereed is.

Zo vind je daarna iedere stagingwaarde:

- `STAGING_SUPABASE_URL`: open het stagingproject en klik bovenaan **Connect**.
  Kopieer onder de app/API-gegevens de **Project URL**. De waarde lijkt op
  `https://abcdefghijklmnopqrst.supabase.co`.
- `STAGING_SUPABASE_PUBLISHABLE_KEY`: klik linksonder op het tandwiel voor
  **Project Settings**, kies **API Keys** en zoek **Publishable key**. Kopieer
  alleen de waarde die met `sb_publishable_` begint. Gebruik niet
  `sb_secret_...`, `service_role` of een database connection string.
- `STAGING_SUPABASE_PROJECT_REF`: kies onder **Project Settings** voor
  **General** en kopieer **Reference ID**. Het is dezelfde tekenreeks die in de
  dashboard-URL direct achter `/project/` staat.
- `STAGING_SUPABASE_ACCESS_TOKEN`: ga niet naar de projectkeys, maar naar het
  accounticoon rechtsboven → **Account Preferences/Account Settings → Access
  Tokens**, of rechtstreeks naar `https://supabase.com/dashboard/account/tokens`.
  Klik **Generate new token**, noem hem `DragonHaven GitHub Staging` en kopieer
  de nieuwe `sbp_...`-waarde meteen.
- `STAGING_SUPABASE_DB_PASSWORD`: gebruik exact het wachtwoord dat in stap 4 in
  de wachtwoordmanager is gezet; het dashboard kan dit later niet terugtonen.

Zet ze daarna op de juiste plek in GitHub:

1. Open `https://github.com/Rakky88/DragonHaven/settings/environments`.
2. Klik **New environment**, typ exact `staging` en klik **Configure
   environment**.
3. Scroll naar **Environment secrets** en klik voor elke waarde op **Add
   secret**. Gebruik exact de vijf namen hierboven.
4. Controleer dat alle vijf namen zichtbaar zijn. De waarden zelf worden na
   opslaan terecht niet teruggetoond.
5. Meld alleen dat project en secrets klaarstaan; deel geen waarden. Codex kan
   dan gecontroleerd de migraties installeren, Auth configureren en de eerste
   echte staging-E2E-run uitvoeren zonder productie te raken.

Een gratis Supabase-account staat momenteel twee actieve gratis projecten toe,
waardoor productie plus staging in beginsel binnen de gratis limiet past. Een
inactief gratis project kan wel automatisch worden gepauzeerd; de stagingtest
houdt daarom rekening met opstarttijd en rapporteert een duidelijke fout als
het project eerst hervat moet worden.

De workflow `Public server health check` is eveneens alleen handmatig. Deze
gebruikt uitsluitend de openbare URL en publishable key, meet de twee Auth-
endpoints en bewaart drie dagen een rapport. Periodieke uitvoering wordt pas
aangezet nadat frequentie, meldingskanaal en CI-budget bewust zijn gekozen.

## Release

Repository: `Rakky88/DragonHaven`

Releasepagina:

```text
https://github.com/Rakky88/DragonHaven/releases/latest
```

Permanente directe Android-download:

```text
https://github.com/Rakky88/DragonHaven/releases/latest/download/DragonHaven.apk
```

Een release-tag gebruikt dezelfde weergaveversie als About, bijvoorbeeld `v0.00.09`, en bevat een asset met exact de naam `DragonHaven.apk`.

De GitHub Actions-workflow publiceert zelf geen tweede release. Hij controleert
de server en bouwt een gesigneerde `DragonHaven.aab` als tijdelijk
workflow-artifact voor Google Play. De vaste GitHub APK-release blijft via het
lokale, gecontroleerde releaseproces lopen.

### Verplichte server-preflight

Voor iedere release moet eerst de gekoppelde DragonHaven Supabase-server worden
gecontroleerd:

```powershell
.\tool\release_server_preflight.ps1 -SupabaseCli <pad-naar-supabase.exe>
```

Deze controle moet slagen voordat een tag of GitHub Release wordt gemaakt. Hij
vergelijkt alle lokale en remote migraties, lint de remote database en test de
publieke Auth health- en e-mailconfiguratie-endpoints. Publiceer niet wanneer
een van deze controles faalt.

Lokale forks kunnen `DRAGONHAVEN_GITHUB_OWNER`, `DRAGONHAVEN_GITHUB_REPO` en `DRAGONHAVEN_APP_VERSION` via `--dart-define` overschrijven.
