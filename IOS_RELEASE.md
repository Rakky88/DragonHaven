# DragonHaven voor iPhone bouwen

DragonHaven heeft een iOS-project met bundle ID `nl.dragonhaven.app`. Vrijwel
alle spelcode en assets zijn gedeeld met Android. Een definitieve iPhone-build
kan technisch niet op Windows worden gemaakt: Apple vereist macOS en Xcode voor
compilatie, signing en upload.

## Eenmalig op de MacBook

1. Installeer de actuele stabiele Flutter-SDK en Xcode. Open Xcode ten minste
   eenmaal, accepteer de licentie en installeer de gevraagde componenten.
2. Clone of pull `https://github.com/Rakky88/DragonHaven` en open
   `ios/Runner.xcworkspace` in Xcode.
3. Kies **Runner → Signing & Capabilities**. Laat **Automatically manage
   signing** aan staan, kies jouw Apple Developer Team en behoud bundle ID
   `nl.dragonhaven.app`.
4. Selecteer een echt aangesloten iPhone en start eenmaal vanuit Xcode. Hiermee
   worden signing, provisioning, plugins, permissies en de layout op echte
   hardware gecontroleerd.
5. Maak de app in App Store Connect aan en richt alleen TestFlight in. De
   TestFlight-link wordt daarna de waarde van
   `DRAGONHAVEN_IOS_DOWNLOAD_URL`.

## Iedere volgende iPhone-build

Voer vanuit de repository op de Mac uit:

```bash
export DRAGONHAVEN_IOS_DOWNLOAD_URL='https://testflight.apple.com/join/...'
bash tool/build_ios_release.sh
```

Het script haalt dependencies op en maakt een ondertekend Xcode Archive en
IPA met dezelfde versie uit `pubspec.yaml`. Iedere nieuwe build wordt opnieuw
ondertekend, maar na de eenmalige automatische-signinginrichting vraagt dit
geen handmatig certificaatwerk per versie.

Upload het archive via Xcode Organizer naar App Store Connect voor TestFlight. Een
latere GitHub Actions-workflow op een macOS-runner kan build, signing en upload
automatiseren zodra App Store Connect, certificaat en provisioning veilig als
repositorysecrets zijn ingericht. Bewaar `.p12`-bestanden, wachtwoorden,
private keys en provisioningprofielen nooit in Git.

De handmatige GitHub-workflow **iOS validation** kan nu al zonder
Apple-certificaten op een macOS-runner de analyzer, platformtests en een
iPhone Simulator-build uitvoeren. Dit bewijst de Xcode-/Swift-compilatie, maar
maakt bewust nog geen installeerbare of openbare release.

Zet dezelfde publieke URL later ook als GitHub Actions-variable
`DRAGONHAVEN_IOS_DOWNLOAD_URL` onder **Settings → Secrets and variables →
Actions → Variables**. Daardoor kan een toekomstige Android-release de
iPhone-link eveneens kopiëren. Dit is een openbare URL en geen secret.

## Latere activering van de updateknop

De huidige openbare app is Android-only. **About DragonHaven** toont daarom
alleen de permanente Android-downloadlink en **Update** opent alleen de APK.
Er is bewust geen iPhone-knop zichtbaar.

Als TestFlight later wordt geactiveerd, kan de interface opnieuw een aparte
iPhone-deelknop en platformbewuste updateroute krijgen. De voorbereidende
`DRAGONHAVEN_IOS_DOWNLOAD_URL` blijft daarvoor beschikbaar in het Mac-script,
maar wordt niet in de huidige Android-release gebruikt.

## Nog te bewijzen vóór bredere iPhone-testdistributie

- een volledige `flutter build ipa` op macOS;
- starten, opslaan, cloudsync en accountflows op een echte iPhone;
- iOS-pariteit voor achtergrondmuziek, geluidseffecten en lokale/pushmeldingen;
- StoreKit plus server-side aankoopcontrole voordat echte digitale aankopen op
  iPhone worden geactiveerd.

Een openbare App Store-pagina, storescreenshots, privacylabels,
leeftijdsclassificatie en een openbare App Review zijn pas nodig wanneer
DragonHaven later werkelijk in de App Store wordt gepubliceerd. Ze zijn niet
nodig om de huidige Android-only deel- en updateknop bruikbaar te maken.
