import 'package:flutter/foundation.dart';

void registerDragonHavenThirdPartyLicenses() {
  LicenseRegistry.addLicense(() async* {
    yield const LicenseEntryWithLineBreaks(
      <String>['DragonHaven Rive chest effects'],
      '''Particle Burst by blackshadow.awesome

Source: https://rive.app/marketplace/597-1141-particle-burst/
Licence: Creative Commons Attribution 4.0 International (CC BY 4.0)
https://creativecommons.org/licenses/by/4.0/

The animation is recoloured, transformed and combined with original
DragonHaven chest artwork and Flutter-rendered effects at runtime.''',
    );
  });
}
