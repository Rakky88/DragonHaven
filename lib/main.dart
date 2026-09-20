import 'services/legacy_app_runtime.dart';
import 'account_startup_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'canonical_staging_app.dart';
import 'config/online_config.dart';
import 'config/firebase_config.dart';
import 'dragonhaven_app.dart';
import 'providers/household_provider.dart';
import 'screens/sprite_audit_screen.dart';
import 'screens/special_event_audit_screen.dart';
import 'screens/event_dragon_sprite_review_screen.dart';
import 'services/firebase_monitoring.dart';
import 'services/notification_service.dart';
import 'services/social_repository.dart';
import 'services/supabase_social_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const canonicalStaging =
      bool.fromEnvironment('DRAGONHAVEN_CANONICAL_STAGING');
  if (canonicalStaging) {
    await runCanonicalStaging(OnlineConfig.fromEnvironment());
    return;
  }
  await HavenNotifications.initializeNavigation();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  const specialEventAudit =
      bool.fromEnvironment('DRAGONHAVEN_SPECIAL_EVENT_AUDIT');
  if (specialEventAudit) {
    runApp(const SpecialEventAuditApp());
    return;
  }
  const eventDragonReview =
      bool.fromEnvironment('DRAGONHAVEN_EVENT_DRAGON_REVIEW');
  if (eventDragonReview) {
    runApp(const EventDragonSpriteReviewApp());
    return;
  }
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
  final onlineConfig = OnlineConfig.fromEnvironment();
  if (!releaseDemo &&
      !evolutionDemo &&
      !nestDemo &&
      !hatchDemo &&
      !showcase) {
    await runAccountStartup(onlineConfig);
    return;
  }
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
  await game.synchronizeNotificationPermissionWithPlatform();
  if (evolutionDemo) await game.refreshForCurrentDate();
  if (showcase && lockedCodexAudit) {
    game.discoveredForms.clear();
    game.prismaticForms.clear();
  }
  game.persistentSeasonalPreviewRewards =
      onlineConfig.environment != OnlineEnvironment.production;
  final firebase =
      await HavenFirebase.initialize(HavenFirebaseConfig.fromEnvironment());
  final diagnostics = firebase.reporter;
  SocialRepository socialRepository = const DisabledSocialRepository();
  if (onlineConfig.isConfigured) {
    await Supabase.initialize(
      url: onlineConfig.url,
      publishableKey: onlineConfig.publishableKey,
    );
    socialRepository = SupabaseSocialRepository(Supabase.instance.client);
  }
  final runtime = await createLegacyAppRuntime(
      game: game,
      socialRepository: socialRepository,
      auth: onlineConfig.isConfigured ? Supabase.instance.client : null,
      firebaseAvailable: firebase.available,
      diagnostics: diagnostics);
  final online = runtime.online;
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: game),
      ChangeNotifierProvider.value(value: online),
    ],
    child: const DragonHavenApp(),
  ));
}
