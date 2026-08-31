# DragonHaven Android-appgrootteaudit

Laatst bijgewerkt: **31 augustus 2026**  
Gemeten app: **v0.05.01**  
Server tijdens meting: **productie 32/32; lokale migratie 33 niet uitgerold**

## Uitkomst

DragonHaven past volgens de actuele officiële Play Console-tabel nog binnen de
maximale base-modulegrens, maar is veel groter dan wenselijk voor installatie en
updates. De universele afbeeldingen en audio zijn samen al circa **284,99 MiB**
gecomprimeerd in de AAB. Die media zijn niet ABI- of device-afhankelijk en maken
het daarom zeer waarschijnlijk dat de uiteindelijke download op een toestel
boven de 200 MB uitkomt.

Google Play vermeldt momenteel een base-modulegrens van 500 MB, een maximale
install-time combinatie van 4 GB en een waarschuwing via mobiele data boven 200
MB. Play berekent de echte limiet op basis van de gecomprimeerde download die uit
de AAB voor een toestel wordt gegenereerd, niet op basis van alleen de AAB- of
APK-bestandsgrootte. Zie de actuele
[Play Console-groottetabel](https://support.google.com/googleplay/android-developer/answer/9859372?hl=en-GB)
en de officiële uitleg over
[Android App Bundles](https://developer.android.com/guide/app-bundle).

De officiële Android-documentatie gebruikt op enkele pagina's nog 200 MB als
grens/overstappunt voor Feature of Asset Delivery, terwijl de nieuwere Play
Console-tabel 500 MB voor de base module noemt. Daarom blijven een echte
Play Console-upload en diens per-device berekening de doorslaggevende
acceptatiecheck. Los van de harde grens adviseert Google de app zo klein mogelijk
te houden vanwege installatie- en uninstallgedrag; zie
[Reduce your app size](https://developer.android.com/topic/performance/reduce-apk-size).

## Reproduceerbare meting

De actuele AAB is lokaal opnieuw gebouwd met:

```powershell
flutter build appbundle --release --no-pub
```

Daarna is uitsluitend de ZIP-directorystructuur gemeten, nooit bestandsinhoud of
spelersdata:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass `
  -File .\tool\measure_android_artifact_size.ps1 `
  -ArtifactPath .\build\app\outputs\bundle\release\app-release.aab `
  -OutputPath .\build\app-size-audit.json
```

| Artifact | Bytes | MiB | SHA-256 |
| --- | ---: | ---: | --- |
| Actuele lokale AAB | 361.758.898 | 345,00 | `efdf18cb258418088b2e9db0fdaf272b901e74591bb9d197be6378bba2715e36` |
| Openbare v0.05.01-APK | 367.048.207 | 350,04 | `5b8ad4ea804e2765fde3b43c6a70e6ee10b8d3777fce685cc22ef7bfc7b78726` |

De AAB-archiefcompressie is een bruikbare vergelijking tussen assetgroepen,
maar is nadrukkelijk niet hetzelfde als de Play Console-downloadschatting.
Bundlemetadata en meerdere CPU-architecturen zitten in de AAB, terwijl Play die
niet allemaal aan één toestel levert.

## Grootste universele groepen

| Groep | Bestanden | AAB-gecomprimeerd | Deel van universele media |
| --- | ---: | ---: | ---: |
| Dragons (`images/dragons`) | 238 | 118,98 MiB | 41,7% |
| UI | 174 | 52,45 MiB | 18,4% |
| Android-audio | 106 | 34,43 MiB | 12,1% |
| Chests | 17 | 24,32 MiB | 8,5% |
| Relics | 68 | 15,82 MiB | 5,6% |
| Overige afbeeldingen | 42 | 12,31 MiB | 4,3% |
| Furniture | 192 | 10,97 MiB | 3,8% |
| Portraits | 100 | 8,24 MiB | 2,9% |
| Achievements | 33 | 3,08 MiB | 1,1% |
| Supporter | 7 | 2,21 MiB | 0,8% |
| Shop | 12 | 2,18 MiB | 0,8% |
| **Totaal universele media** | **989** | **284,99 MiB** | **100%** |

Daarnaast bevat de AAB circa 31,70 MiB bundlemetadata/debugsymbolen en 26,96 MiB
native libraries voor drie ABI's. Die posten verklaren een deel van de AAB zelf,
maar zijn niet het eerste optimalisatiedoel: Play splitst CPU-code per toestel en
debugsymbolen worden niet als spelcontent geleverd.

## Concrete bevindingen

- De belangrijkste winst zit in rasterkunst, niet in Dart/Kotlin-code.
- Veel WebP/PNG-bestanden comprimeren in de AAB vrijwel niet verder; alleen
  werkelijk resizen of opnieuw encoderen verlaagt de download merkbaar.
- Veel drakensprites zijn 1024×1024 terwijl zij meestal veel kleiner worden
  weergegeven. Alleen Dragons besparen bij 35% reductie al circa 41,6 MiB.
- `evolution_frame_atlas.webp` is 2560×2048 en circa 4,02 MiB.
- `chest_music_open.png` is 1600×1600 en circa 2,43 MiB.
- `order_compass.png` is 1254×1254 en circa 1,98 MiB.
- De grootste muziekbestanden zijn circa 6,71 MiB, 6,06 MiB, 4,37 MiB en
  3,85 MiB gecomprimeerd. De 80-trackcatalogus moet functioneel en qua
  CC0/Public Domain-bron intact blijven bij een eventuele audioconversie.
- `assets/images/furniture_atlases` neemt circa 10,76 MiB in de bronwerkmap in,
  maar staat niet in `pubspec.yaml` en zit dus niet in deze AAB. Verwijderen zou
  de app niet kleiner maken en kan artworktests of bouwtools breken.

## Gratis optimalisatiepad

### Stap 1 — veilige beeldpilot

Codex kan eerst tien representatieve grootste assets kopiëren naar een
afzonderlijke testset en varianten maken met kleinere pixelafmetingen en
WebP-instellingen. De pilot moet voor ieder bestand controleren:

- transparante achtergrond en bestaande alpha-veiligheidsmarge;
- geen afgesneden vleugels, kroon, staart, borst of chest glow;
- gelijke oriëntatie en compositie;
- visueel resultaat op 360×640 dp, normale telefoon en ingezoomde detailweergave;
- byteverschil en decodeerbaarheid in Flutter/Android.

Pas na een contact sheet of emulatorcontrole wordt de beste instelling in een
batch toegepast. Dit voorkomt dat een blinde massaconversie honderden sprites
zichtbaar slechter maakt.

### Stap 2 — grootste categorieën in batches

Volgorde op verwachte winst:

1. Dragons;
2. UI en Dragon Academy/trial-achtergronden;
3. open/gesloten chests;
4. relics;
5. portraits en furniture.

Iedere batch krijgt een grootteverschil, sprite-boundstest, volledige
regressieset en visuele steekproef. Bronbestanden worden niet verwijderd zolang
een generator of audittool ze nog gebruikt.

### Stap 3 — audio

Converteer alleen de grote PCM/hoog-bitrate tracks naar een Android-breed
ondersteunde Ogg Vorbis-instelling na een luistertest. Track-ID, compositienaam,
licentiebewijs, shuffle/repeat en speelduur moeten gelijk blijven. MIDI-bestanden
zijn al klein en hebben weinig prioriteit.

### Stap 4 — delivery pas wanneer nodig

Als optimalisatie onvoldoende onder de gewenste download komt, is Play Asset
Delivery een logische latere route voor muziek of zelden gebruikte grote assets.
Dat gebruikt de Play-distributie in plaats van een aparte betaalde CDN, maar
vereist wel Play Console-integratie, download-/offline-UX en extra tests. Het is
daarom niet de eerste stap.

## Interne budgetten

Deze doelen zijn strenger dan alleen “Play accepteert de upload”:

- **eerstvolgende mijlpaal:** universele media van 284,99 naar maximaal 220 MiB;
- **vóór brede Play-test:** universele media maximaal 170 MiB;
- **acceptatie:** Play Console per-device gecomprimeerde download maximaal
  200 MB, bij voorkeur maximaal 150 MB;
- **regressiegate:** geen batch mag alpha, uitsnede, oriëntatie, muziekrechten of
  runtime-decodeerbaarheid breken.

De 170-MiB-mediagrens reserveert ruimte voor één ABI, Fluttercode, resources en
overige runtimebestanden. De uiteindelijke Play Console-meting blijft leidend.

## Nog nodig

### Door Codex

- de beeldpilot en vergelijking bouwen;
- na visuele goedkeuring categoriegewijs optimaliseren;
- een waarschuwing/budgetrapport aan de releasegate koppelen;
- na iedere batch AAB, tests en per-groepmeting herhalen;
- indien nodig pas daarna Play Asset Delivery ontwerpen.

### Door Rick

- de pilot visueel goedkeuren voordat honderden sprites worden vervangen;
- later de AAB in een interne Play-track uploaden en de echte App size-meting
  delen of toegang geven;
- kiezen of download onder 200 MB een harde launchvoorwaarde wordt.

Deze audit heeft niets gepubliceerd en geen server of openbare app gewijzigd.
