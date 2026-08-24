import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/online_config.dart';
import 'dragonhaven_app.dart';
import 'models/social.dart';
import 'providers/household_provider.dart';
import 'providers/online_account_provider.dart';
import 'screens/sprite_audit_screen.dart';
import 'services/audio_service.dart';
import 'services/social_repository.dart';
import 'services/supabase_social_repository.dart';

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
  const releaseDemo = bool.fromEnvironment('DRAGONHAVEN_RELEASE_DEMO');
  const lockedCodexAudit =
      bool.fromEnvironment('DRAGONHAVEN_CODEX_AUDIT_LOCKED');
  const hatchDemo = bool.fromEnvironment('DRAGONHAVEN_HATCH_DEMO');
  const hatchDemoSeconds = int.fromEnvironment(
    'DRAGONHAVEN_HATCH_DEMO_SECONDS',
    defaultValue: 180,
  );
  const evolutionDemo = bool.fromEnvironment('DRAGONHAVEN_EVOLUTION_DEMO');
  const nestDemo = bool.fromEnvironment('DRAGONHAVEN_NEST_DEMO');
  final game = releaseDemo
      ? HouseholdProvider.createReleaseDemo()
      : evolutionDemo
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
  final onlineConfig = OnlineConfig.fromEnvironment();
  SocialRepository socialRepository = const DisabledSocialRepository();
  if (onlineConfig.isConfigured) {
    await Supabase.initialize(
      url: onlineConfig.url,
      publishableKey: onlineConfig.publishableKey,
    );
    socialRepository = SupabaseSocialRepository(Supabase.instance.client);
  }
  final online = OnlineAccountProvider(
    repository: socialRepository,
    inventorySnapshot: () => OnlineInventorySnapshot.fromGame(game),
  );
  await online.initialize();
  await HavenAudio.applyPreferences(
    musicEnabled: game.musicEnabled,
    soundEffectsEnabled: game.soundEffectsEnabled,
  );
  final hour = DateTime.now().hour;
  await HavenAudio.setMusicScene(hour >= 21 || hour < 7
      ? HavenMusicScene.towerNight
      : HavenMusicScene.towerDay);
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: game),
      ChangeNotifierProvider.value(value: online),
    ],
    child: const DragonHavenApp(),
  ));
}
