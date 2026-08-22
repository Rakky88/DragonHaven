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
  final game = showcase
      ? HouseholdProvider.createShowcase()
      : await HouseholdProvider.loadFromStorage();
  await HavenAudio.applyPreferences(
    musicEnabled: game.musicEnabled,
    soundEffectsEnabled: game.soundEffectsEnabled,
  );
  runApp(ChangeNotifierProvider.value(
    value: game,
    child: const DragonHavenApp(),
  ));
}
