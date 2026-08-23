import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'dragonhaven_app.dart';
import 'providers/household_provider.dart';
import 'screens/sprite_audit_screen.dart';
import 'services/audio_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  const spriteAudit = bool.fromEnvironment('DRAGONHAVEN_SPRITE_AUDIT');
  if (spriteAudit) {
    runApp(const SpriteAuditApp());
    return;
  }
  const showcase = bool.fromEnvironment('DRAGONHAVEN_SHOWCASE');
  const lockedCodexAudit =
      bool.fromEnvironment('DRAGONHAVEN_CODEX_AUDIT_LOCKED');
  const hatchDemo = bool.fromEnvironment('DRAGONHAVEN_HATCH_DEMO');
  const hatchDemoSeconds = int.fromEnvironment(
    'DRAGONHAVEN_HATCH_DEMO_SECONDS',
    defaultValue: 180,
  );
  const evolutionDemo = bool.fromEnvironment('DRAGONHAVEN_EVOLUTION_DEMO');
  const nestDemo = bool.fromEnvironment('DRAGONHAVEN_NEST_DEMO');
  final game = evolutionDemo
      ? HouseholdProvider.createEvolutionDemo()
      : nestDemo
          ? HouseholdProvider.createNestDemo()
          : hatchDemo
              ? HouseholdProvider.createHatchDemo(
                  countdown: Duration(seconds: hatchDemoSeconds),
                )
              : showcase
                  ? HouseholdProvider.createShowcase()
                  : await HouseholdProvider.loadFromStorage();
  if (evolutionDemo) await game.refreshForCurrentDate();
  if (showcase && lockedCodexAudit) {
    game.discoveredForms.clear();
    game.prismaticForms.clear();
  }
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
