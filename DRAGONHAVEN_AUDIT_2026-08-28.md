# DragonHaven v0.04.06 audit — 28 augustus 2026

> **Status 28 augustus 2026:** deze audit blijft het historische
> v0.04.06-baselinebewijs. v0.04.07 is daarna gepubliceerd via de volledig
> groene [release-gate 33185616650](https://github.com/Rakky88/DragonHaven/actions/runs/33185616650).
> De actuele stand, inclusief 256 groene lokale tests, negatieve online
> herstelpaden en de nog niet uitgerolde geaudite bestaande-save-import, staat
> in [DRAGONHAVEN_POST_AUDIT_PLAN.md](DRAGONHAVEN_POST_AUDIT_PLAN.md).

## Samenvatting

v0.04.06 is gecontroleerd als één samenhangende client- en serverrelease. De
releasecandidate heeft geen Flutter-analysemeldingen, alle 243 geautomatiseerde
tests slagen en de gekoppelde Supabase-omgeving doorstaat de verplichte
release-preflight. De appversie is `0.04.06`; Android gebruikt versionName
`0.4.6` en versionCode `10039`.

De grootste functionele veranderingen zijn de Jukebox met 80 expliciet
CC0/Public Domain muziekbestanden, vier nieuwe relics, strengere server-side
tradevalidatie, uitgebreidere Inventory/My Dragons-bediening, herwerkte
minigame-uitkomsten en een robuustere online opstart.

## Uitgevoerde controles

| Onderdeel | Resultaat |
| --- | --- |
| `flutter analyze --no-pub` | 0 meldingen |
| `flutter test --no-pub` | 243/243 geslaagd |
| Compacte UI en vergrote tekst | geslaagd, inclusief 320 px Inventory/My Dragons |
| Reduced-motion result transition | geslaagd |
| Sprite-bounds en transparantie | geslaagd voor UI, relics, chests, dragons, portraits en furniture |
| Muziekcatalogus | exact 80 unieke IDs, bestanden, Android mappings en bronvermeldingen |
| Chinese verwijdering | geen taaloptie en alle vaste vertaallijsten exact zes extra talen |
| Supabase migration parity | 20 lokaal / 20 remote |
| Supabase database lint | 0 fouten |
| Supabase Auth health/settings | HTTP 200 / HTTP 200 |
| E-mailauth | geconfigureerd |

## Gameplay en economie

- `Dragons` in de Draconomicon telt iedere daadwerkelijk ontdekte levensvorm;
  `Dragon families` blijft afzonderlijk families tellen.
- Wooden Chests hebben geen gem-uitkomst. Relic-kansen zijn Gold 1%, Dragon
  2%, Mythical 4% en Sinister 100%.
- Title Chests kosten 100 coins, Portrait Chests 100 gems en Music Chests 250
  gems. Ongeopende collection chests tellen mee bij de collectiegrens.
- Portrait, Title en Music Chests zijn aan client- én serverzijde niet
  ruilbaar.
- Shop-relics kosten 500 gems, zijn onbeperkt koopbaar waar van toepassing en
  worden apart als untradeable bijgehouden. Gameplaydrops van de normale relics
  blijven tradeable.
- Chronoshard bewaart zijn verkregen reductie van 10–90% als itemvariant. De
  Twinstar Brooch is uniek, permanent, altijd untradeable en verdubbelt XP
  uitsluitend voor de huidige drager.

## UI en toegankelijkheid

- My Dragons heeft gallery/list, omkeerbare sortering en combineerbare
  form/rarity/Spectral-filters. Alleen aanwezige filterwaarden worden getoond.
- Eggs en Furniture hebben tile/list, omkeerbare sortering en passende filters.
  Chest Inventory volgt altijd de vaste tier-volgorde.
- De compacte Egg-toolbar loopt ook bij 320 px en grotere tekst niet over.
- Expertise 300 toont de MAX-sprite en de Twinstar-drager is zowel op kaarten
  als in detail duidelijk gemarkeerd.
- Account Info toont alleen verzamelde totalen bij Portrait, Title en Jukebox;
  collection-capaciteit en actuele portrait odds staan bij de shopkisten.

## Minigames

- Might toont de 30 echte scoring turns prominent. De kleinere teller van drie
  misses blijft apart. Na de laatste turn vervaagt de meter één seconde voordat
  resultaat en beloning verschijnen.
- Arcana heeft bewust geen timer. Een speler kan onbeperkt doorgaan; score 15
  en hoger blijft altijd S+ met de S+-reward. Een verkeerde rune licht één
  seconde rood op voordat het draaiende resultaat verschijnt en de reward wordt
  toegepast.
- Spirit bevriest bij een botsing 250 ms en volgt daarna een duidelijke gebogen
  valbeweging. Ook hier wordt de reward pas bij de resultaattransitie toegepast.

## Timing, Adventures en terugkerende draken

- Starter Egg-taps trekken elk één seconde af, maar de laatste seconde loopt
  altijd echt af. Latere eieren zijn niet aantikbaar.
- Solo Adventures kunnen zonder beloning worden afgebroken; Group Adventures
  niet. De draak wordt na een solo-abort direct vrijgegeven.
- Adventure-notificaties worden één seconde na de claimbare eindgrens gepland,
  zodat afrondingsverschillen geen melding vóór de echte terugkomst geven.
- Vrijgelaten draken krijgen per lokale kalenderdag één persistente 10%-worp en
  bij succes een willekeurig tijdstip van die dag. Als er geen vrijgelaten
  draken zijn, wordt geen worp gedaan en de dag ook niet verbruikt.

## Online en server

De eerder waargenomen fout bij nieuwe accounts kwam overeen met een client die
de eerste volledige online refresh tijdens app-initialisatie afwachtte. Een
trage of tijdelijk vastlopende request kon daardoor de hele online UI in een
generieke foutstatus houden. v0.04.06 start lokale gameplay zonder op die eerste
refresh te blokkeren en begrenst online acties op 30 seconden met een veilige,
herstelbare melding. E-mailbevestiging blijft expliciet vereist.

Migratie `202608280020_relic_variants_and_trade_guards.sql` is op de gekoppelde
productieomgeving toegepast. Zij bewaart Chronoshard-variantdata, vergrendelt
percentage-specifieke reserveringen en weigert Music/Portrait/Title Chests,
shop-relics en Twinstar server-side bij trades.

Zie [SERVER_IMPROVEMENTS.md](SERVER_IMPROVEMENTS.md) voor de technische
servergrenzen en preflightdetails.

## Muziekrechten

De oude, niet voldoende bewezen `reverie.ogg` is vervangen. De nu gebundelde
Rêverie is een specifiek Public Domain Mark-bestand uit de conflictvrije PDMX-
selectie; het recht wordt dus niet alleen afgeleid van Debussy's compositie.

Alle 80 bestanden zijn geselecteerd uit expliciete CC0/Public Domain bronnen.
PDMX-rijen worden alleen geaccepteerd met `no_license_conflict=true`,
`license_conflict=false` en `all_valid=true`; de gevonden conflicterende
Gymnopédie III, Elite Syncopations en Tritsch-Tratsch-selecties zijn vervangen
door conflictvrije Public Domain bronnen. Exacte URLs, bestandsnamen, licenties
en selectievelden staan in
[assets/licenses/MUSIC_SOURCES.md](assets/licenses/MUSIC_SOURCES.md).

## Blijvende grenzen en risico's

- De lokale collectie/economie is nog offline-first. Trades, Friends, Group
  Adventures en backups hebben serverautoriteit, maar normale coin/gem- en
  chestacties zijn nog geen volledig server-authoritative command model.
- Cloud backup is expliciet en versiegebonden; automatische conflictresolutie
  tussen twee gelijktijdig gebruikte apparaten is niet geïmplementeerd.
- Er is nog geen Google Play Billing/receiptvalidatie. De zichtbare currency
  packs zijn spelpresentatie en geen echte aankoopstroom.
- Een geslaagde auth-healthcheck bewijst bereikbaarheid en configuratie, maar
  vervangt geen langlopende productie-observability. Auth-, RPC- en database-
  foutpercentages horen bij een publieke lancering extern gemonitord te worden.

Deze grenzen blokkeren de huidige testrelease niet, maar moeten vóór een brede
publieke storelancering als expliciete productbeslissingen worden behandeld.
