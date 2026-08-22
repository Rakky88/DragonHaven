import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'dragonhaven_app.dart';
import 'providers/household_provider.dart';
import 'services/audio_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  const showcase = bool.fromEnvironment('DRAGONHAVEN_SHOWCASE');
  const hatchDemo = bool.fromEnvironment('DRAGONHAVEN_HATCH_DEMO');
  const hatchDemoSeconds = int.fromEnvironment(
    'DRAGONHAVEN_HATCH_DEMO_SECONDS',
    defaultValue: 180,
  );
  final game = hatchDemo
      ? HouseholdProvider.createHatchDemo(
          countdown: Duration(seconds: hatchDemoSeconds),
        )
      : showcase
          ? HouseholdProvider.createShowcase()
          : await HouseholdProvider.loadFromStorage();
  await HavenAudio.applyPreferences(
    musicEnabled: game.musicEnabled,
    soundEffectsEnabled: game.soundEffectsEnabled,
  );
  final hour = DateTime.now().hour;
  await HavenAudio.setMusicScene(hour >= 21 || hour < 7
      ? HavenMusicScene.towerNight
      : HavenMusicScene.towerDay);
  runApp(ChangeNotifierProvider.value(
    value: game,
    child: const DragonHavenApp(),
  ));
}
