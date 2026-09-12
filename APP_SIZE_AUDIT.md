# DragonHaven Android-appgrootteaudit

## Meting v0.05.30 ? 12 september 2026

De universele release-APK meet **628.161.582 bytes** (628,16 MB / 599,06 MiB),
SHA-256 `c3ca374d15ffa23f2b23543dde1499f784f2d8d3a492b9ead187faca138674e3`.
Deze release wijzigt eventregels en app-/servercode; er zijn voor deze release
geen artworkresoluties of audiokwaliteit verlaagd. Oudere metingen hieronder
blijven als historische vergelijking staan.

## Actuele meting: v0.05.28, 9 september 2026

Vraag van de gebruiker: kan de app kleiner **zonder kwaliteitsverlies**?
Deze actuele eis vervangt het eerdere voorstel om resolutie te verlagen of
opnieuw met verlies te comprimeren. De meting hieronder is uitgevoerd op de
exact gepubliceerde APK; er zijn geen runtimeassets of servergegevens gewijzigd.

De APK is **627.719.018 bytes** (627,72 MB / 598,64 MiB), SHA-256
`d3c4e79d4c9e17be1c89ed0ffe671e77b91f252dc48f9a26d78855674c4e57cb`.
Dit is de downloadgrootte van het universele bestand, niet het totale
opslaggebruik na installatie of de download van een Play-split.

| Onderdeel | APK-bytes | MB, decimaal |
| --- | ---: | ---: |
| Afbeeldingen in Flutter-assets | 492.594.458 | 492,59 |
| Muziek en geluid | 63.885.729 | 63,89 |
| Flutter/native code voor drie ABI's | 67.225.496 | 67,23 |
| Overige entries, exclusief ZIP/signinguitlijning | 3.570.100 | 3,57 |

Binnen afbeeldingen: draken 196,43 MB, events 86,76 MB, UI 55,13 MB,
emotes 27,66 MB, Altar 26,80 MB en kisten 25,62 MB. PNG-afbeeldingen
in de Flutter-bundel zijn samen 214,85 MB. De grootste winst zit in media;
codeopruiming alleen raakt een veel kleiner deel van de totale APK.

### Bewezen compressieproef

36 bestaande afbeeldingen uit meerdere categorieën zijn in het geheugen
opnieuw gecodeerd met lossless WebP (`lossless=True`, `quality=100`,
`method=6`, `exact=True`). Geen resize, kleurreductie of wijziging van artwork.
Iedere kandidaat is teruggedecodeerd; breedte, hoogte en **alle RGBA-bytes**
(inclusief volledig transparante pixels) zijn gelijk aan het gedecodeerde
origineel. Eventuele ICC-profielen worden doorgegeven. Alleen kleinere
kandidaten tellen als besparing; grotere uitkomsten zouden het origineel houden.

- 36 bestanden: **45.125.273 → 33.480.756 bytes**, besparing **11.644.517 bytes**
  (25,81%).
- Daarbinnen 31 PNG's: 36.049.901 bytes, besparing 10.537.779 bytes (29,23%).
- Vijf bestaande WebP's: 9.075.372 bytes, besparing 1.106.738 bytes (12,19%).
- Voorbeeld: Music Chest open **2,56 → 1,36 MB**; Solmanta Mastery
  **1,88 → 1,33 MB**; Ciderhorn Spirit **2,21 → 1,51 MB**.

Dit is een bewuste steekproef van kleine, middelgrote en grote bestanden per
categorie, geen volledige conversie en geen statistisch gegarandeerde
projectie. Circa **100–150 MB totale reductie** lijkt als werkhypothese haalbaar
met mediaoptimalisatie, opruiming en eventueel distributie per ABI samen.
De definitieve winst moet blijken uit een volledige inventarisatie en rebuild.
Een garantie op halvering of een APK onder 200 MB volgt niet uit deze meting.

### Opruiming en distributie

- Exact dubbele APK-assets/audio samen leveren slechts **308.547 bytes** op.
  Identieke bestanden zijn niet automatisch ongebruikt; eerst verwijzingen
  samenvoegen voordat één kopie uit de bundel kan verdwijnen.
- Er zijn **twaalf oude `_safe.webp`-drakensprites (8.835.070 bytes)** meegeleverd
  waarvoor `DragonArtwork.secondPassStandaloneForms` inmiddels `_safe_v2.webp`
  selecteert. Dit zijn concrete uitsluitkandidaten. Controleer alle dynamische
  routes en tests vóór uitsluiting; bewaar bronnen en auditbestanden buiten de
  runtimebundel. Er is in deze analyse niets verwijderd.
- Een simpele tekstzoekactie bewijst geen ongebruik: drakenvormen, kisten,
  relics en animatiefasen construeren bestandsnamen dynamisch.
- Native libraries zijn 22.534.720 bytes ARM64, 20.631.800 bytes ARM32 en
  24.058.976 bytes x86-64. Een ARM64-specifieke APK kan daarmee ongeveer
  **44.690.776 bytes** aan andere ABI-code uitsparen, zonder beeld-/geluidsverlies.
  De bestaande universele download ondersteunt alle drie; een wijziging vereist
  correcte toestelkeuze en behoud van de andere installatievarianten.
- PCM-WAV beslaat 28,92 MB. FLAC is een mogelijke lossless vervolgstap, met
  controle op exact gelijke samples, kanalen, samplefrequentie, speelduur,
  loopgedrag en native Android-weergave. Dit is nog **niet** geconverteerd of
  gemeten. Bestaande Ogg/MP3 niet nogmaals met verlies encoderen.
- Ongebruikte projectbestanden die niet in de APK zitten verwijderen verkleint
  alleen de werkmap. Bronkunst, reviewbeelden en buildlogs tellen dus niet
  automatisch mee voor de appgrootte.

### Aanpak met behoud van kwaliteit

1. Maak een expliciete runtime-assetinventaris, inclusief dynamische paden.
   Sluit bewezen verouderde varianten uit; behoud originele bronnen apart.
2. Pas lossless beeldcompressie toe waar werkelijk kleiner, met gelijke
   RGBA-pixels/afmetingen, kleurprofielcontrole en behoud van originele artwork.
   Werk assetpaden en provenance bij; controleer Flutter/Android-decoding,
   transparante randen, detailweergave en animaties in de emulator.
3. Onderzoek daarna lossless WAV-compressie en distributie per processortype.
4. Voeg de bestaande grootteanalyse toe als rapport bij iedere release.
   Herhaal daarna de relevante asset-/speltests, volledige releasegate en
   serverpreflight. Publiceer pas met een nieuw versienummer.

Bronnen: [lossless WebP en exacte transparante pixels](https://developers.google.com/speed/webp/docs/cwebp),
[Flutter APK's per ABI](https://docs.flutter.dev/deployment/android#build-an-apk),
[Android FLAC-ondersteuning](https://developer.android.com/media/platform/supported-formats).

Reproduceerbare APK-meting: `tool/measure_android_artifact_size.ps1` met
`-ArtifactPath release/DragonHaven-v0.05.28.apk`.
Bewijs: `release/v0.05.28-app-size.json`, `release/v0.05.28-size-baseline.json`,
`release/v0.05.28-size-candidates.json`, `release/v0.05.28-lossless-probe.json`,
`release/v0.05.28-superseded-art-candidates.json` en `.tools/size_lossless_probe.py`.

## Historische baseline: 31 augustus 2026

De onderstaande v0.05.01-meting en Play-grenzen zijn historische gegevens.
De oude voorstellen voor resizen en audiocompressie met verlies passen niet
bij de huidige eis; gebruik daarvoor de actuele aanpak hierboven. Play-limieten
moeten opnieuw officieel worden gecontroleerd wanneer een Play-upload volgt.

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
