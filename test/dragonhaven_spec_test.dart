import 'dart:io';

import 'package:dragon_haven/l10n/app_strings.dart';
import 'package:dragon_haven/models/adventure.dart';
import 'package:dragon_haven/models/achievement.dart';
import 'package:dragon_haven/models/account_title.dart';
import 'package:dragon_haven/models/chest.dart';
import 'package:dragon_haven/models/day_phase.dart';
import 'package:dragon_haven/models/dragon_lineage.dart';
import 'package:dragon_haven/models/music_track.dart';
import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/models/profile_portrait.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the full adventure catalog has unique requested content counts', () {
    expect(AdventureCatalog.mini, hasLength(200));
    expect(AdventureCatalog.short, hasLength(300));
    expect(AdventureCatalog.long, hasLength(200));
    expect(AdventureCatalog.group, hasLength(200));
    expect(AdventureCatalog.special, hasLength(100));

    final all = [
      ...AdventureCatalog.mini,
      ...AdventureCatalog.short,
      ...AdventureCatalog.long,
      ...AdventureCatalog.group,
      ...AdventureCatalog.special,
    ];
    expect(all.map((entry) => entry.id).toSet(), hasLength(1000));
    expect(
        AdventureCatalog.mini.every((entry) =>
            entry.duration >= const Duration(minutes: 2) &&
            entry.duration <= const Duration(minutes: 15) &&
            entry.xp >= 4 &&
            entry.statPoints >= 1 &&
            entry.knownChest == ChestTier.wooden),
        isTrue);
    expect(
        AdventureCatalog.short.every((entry) =>
            entry.duration >= const Duration(hours: 3) &&
            entry.duration <= const Duration(hours: 6)),
        isTrue);
    expect(
        AdventureCatalog.long.every((entry) =>
            entry.duration >= const Duration(days: 3) &&
            entry.duration <= const Duration(days: 6)),
        isTrue);
    expect(
        AdventureCatalog.group.every((entry) =>
            entry.duration >= const Duration(days: 3) &&
            entry.duration <= const Duration(days: 6)),
        isTrue);
    expect(AdventureCatalog.mini.first.duration, const Duration(minutes: 2));
    expect(AdventureCatalog.mini.first.xp, 4);
    expect(AdventureCatalog.mini.first.statPoints, 1);
    expect(AdventureCatalog.short.first.duration, const Duration(hours: 3));
    expect(AdventureCatalog.short.first.xp, 89);
    expect(AdventureCatalog.short.first.statPoints, 7);
    expect(AdventureCatalog.long.first.duration, const Duration(days: 3));
    expect(AdventureCatalog.long.first.xp, 710);
    expect(AdventureCatalog.long.first.statPoints, 68);
    expect(AdventureCatalog.group.first.duration, const Duration(days: 3));
    expect(AdventureCatalog.group.first.xp, 885);
    expect(AdventureCatalog.group.first.statPoints, 91);
  });

  test('lineage rarities match the 42-family distribution', () {
    int count(DragonRarity rarity) => standardDragonLineages
        .where((lineage) => lineage.rarity == rarity)
        .length;

    expect(count(DragonRarity.common), 20);
    expect(count(DragonRarity.uncommon), 10);
    expect(count(DragonRarity.rare), 6);
    expect(count(DragonRarity.veryRare), 3);
    expect(count(DragonRarity.legendary), 2);
    expect(count(DragonRarity.mythical), 1);
  });

  test('achievements have unique badges and use Common terminology', () {
    expect(achievementCatalog, hasLength(33));
    expect(
      achievementCatalog.map((achievement) => achievement.badge).toSet(),
      hasLength(achievementCatalog.length),
    );
    expect(
      achievementCatalog
          .where((achievement) => achievement.descriptionEn.contains('normal')),
      isEmpty,
    );
  });

  test('maxing all three expertises on one dragon completes its achievement',
      () {
    final provider = HouseholdProvider();
    expect(provider.achievementProgress('triple_expertise'), 0);
    for (final focus in TrainingFocus.values) {
      provider.pet.addTraining(focus, maxDragonExpertise);
    }
    expect(provider.achievementProgress('triple_expertise'), 1);
  });

  test('the secret Mastery achievement unlocks only after Mastery evolution',
      () {
    final provider = HouseholdProvider();
    provider.pet
      ..stage = DragonStage.wyrmling
      ..xp = Pet.ascendedXp
      ..training.addAll({'might': 100, 'arcana': 100, 'spirit': 100});

    expect(provider.achievementProgress('hidden_mastery'), 0);
    provider.pet.evolve(DateTime.utc(2026, 8, 24));
    expect(provider.achievementProgress('hidden_mastery'), 1);
    expect(
      achievementCatalog
          .singleWhere((item) => item.id == 'hidden_mastery')
          .secret,
      isTrue,
    );
  });

  test('all ten chest tiers and all 24 personality traits exist', () {
    expect(ChestTier.values, hasLength(10));
    expect(dragonPersonalityTraits, hasLength(24));
    expect(dragonPersonalityTraits.toSet(), hasLength(24));
    for (final entry in dragonPersonalityIncompatibilities.entries) {
      expect(dragonPersonalityIncompatibilities[entry.value], entry.key);
    }
  });

  test('adventure chest odds match the published release table exactly', () {
    const expected = <AdventureKind, Map<ChestTier, double>>{
      AdventureKind.short: {
        ChestTier.wooden: .20,
        ChestTier.silver: .40,
        ChestTier.gold: .35,
        ChestTier.dragon: .045,
        ChestTier.mythical: .005,
      },
      AdventureKind.long: {
        ChestTier.gold: .75,
        ChestTier.dragon: .23,
        ChestTier.mythical: .02,
      },
      AdventureKind.group: {
        ChestTier.gold: .70,
        ChestTier.dragon: .25,
        ChestTier.mythical: .05,
      },
    };
    for (final entry in expected.entries) {
      final chances = adventureChestChances[entry.key]!;
      expect(
        {for (final chance in chances) chance.tier: chance.probability},
        entry.value,
      );
      expect(
        chances.fold<double>(0, (sum, chance) => sum + chance.probability),
        closeTo(1, .0000001),
      );
    }
    expect(
        adventureChestForRoll(AdventureKind.short, .19999), ChestTier.wooden);
    expect(adventureChestForRoll(AdventureKind.short, .20), ChestTier.silver);
    expect(adventureChestForRoll(AdventureKind.short, .9499), ChestTier.gold);
    expect(adventureChestForRoll(AdventureKind.short, .9501), ChestTier.dragon);
    expect(
        adventureChestForRoll(AdventureKind.short, .999), ChestTier.mythical);
  });

  test('portrait catalog has the requested 100-sprite rarity distribution', () {
    expect(profilePortraitCatalog, hasLength(100));
    expect(profilePortraitCatalog.map((entry) => entry.id).toSet(),
        hasLength(100));
    int count(PortraitRarity rarity) =>
        profilePortraitCatalog.where((entry) => entry.rarity == rarity).length;
    expect(count(PortraitRarity.common), 88);
    expect(count(PortraitRarity.rare), 5);
    expect(count(PortraitRarity.veryRare), 3);
    expect(count(PortraitRarity.legendary), 2);
    expect(count(PortraitRarity.infernal), 1);
    expect(count(PortraitRarity.mythical), 1);
  });

  test('title catalog contains 500 distinct localized account titles', () {
    expect(accountTitleCatalog, hasLength(500));
    expect(
        accountTitleCatalog.map((title) => title.id).toSet(), hasLength(500));
    for (final language in AppStrings.supportedLanguages.keys) {
      final labels =
          accountTitleCatalog.map((title) => title.label(language)).toSet();
      expect(labels, hasLength(500), reason: language);
      expect(labels.every((label) => label.trim().isNotEmpty), isTrue);
    }
  });

  test('every native audio event has a non-empty bundled resource', () {
    const resources = [
      'ui_confirm.ogg',
      'chest_wooden.ogg',
      'chest_silver.ogg',
      'chest_gold.ogg',
      'chest_dragon.ogg',
      'chest_mythical.wav',
      'chest_mythical_legacy.ogg',
      'chest_sinister.wav',
      'chest_sinister_legacy.ogg',
      'chest_special.wav',
      'hatch_build.ogg',
      'hatch_crack_1.ogg',
      'hatch_crack_2.ogg',
      'hatch_crack_3.ogg',
      'hatch_reveal.wav',
      'spectral_reveal.ogg',
      'evolution_young.ogg',
      'evolution_ascended.ogg',
      'achievement.ogg',
      'adventure_start.ogg',
      'adventure_return.ogg',
      'floor_built.ogg',
      'tower_day.ogg',
      'tower_night.ogg',
      'room.ogg',
      'reveal.mp3',
    ];
    final directory = Directory('android/app/src/main/res/raw');
    final nativeBridge = File(
      'android/app/src/main/kotlin/nl/dragonhaven/app/MainActivity.kt',
    ).readAsStringSync();
    expect(directory.existsSync(), isTrue);
    for (final resource in resources) {
      final file = File('${directory.path}/$resource');
      expect(file.existsSync(), isTrue, reason: resource);
      expect(file.lengthSync(), greaterThan(4000), reason: resource);
      final resourceId = resource.substring(0, resource.lastIndexOf('.'));
      expect(nativeBridge, contains('R.raw.$resourceId'),
          reason: '$resource must be statically retained in release builds');
    }
    expect(File('${directory.path}/hatch_reveal.wav').lengthSync(),
        greaterThan(1000000),
        reason: 'The hatch reveal uses the full original cinematic fanfare.');
    final mythical = File('${directory.path}/chest_mythical.wav');
    final sinister = File('${directory.path}/chest_sinister.wav');
    final special = File('${directory.path}/chest_special.wav');
    expect(mythical.lengthSync(), greaterThan(800000));
    expect(sinister.lengthSync(), greaterThan(780000));
    expect(special.lengthSync(), greaterThan(1100000));
    expect(mythical.readAsBytesSync().take(4), [82, 73, 70, 70]);
    expect(sinister.readAsBytesSync().take(4), [82, 73, 70, 70]);
    expect(special.readAsBytesSync().take(4), [82, 73, 70, 70]);
    expect(
      mythical.lengthSync(),
      greaterThan(
          File('${directory.path}/chest_mythical_legacy.ogg').lengthSync()),
    );
    expect(
      sinister.lengthSync(),
      greaterThan(
          File('${directory.path}/chest_sinister_legacy.ogg').lengthSync()),
    );
    expect(nativeBridge, contains('"chest_dragon" -> R.raw.hatch_reveal'));
    expect(nativeBridge, contains('"chest_mythical" -> R.raw.chest_mythical'));
    expect(nativeBridge, contains('"chest_sinister" -> R.raw.chest_sinister'));
    expect(nativeBridge, contains('"chest_special" -> R.raw.chest_special'));
    expect(nativeBridge, contains('listOf("music_reverie")'));
    expect(nativeBridge, isNot(contains('previousMusicStyle')));
  });

  test('all 80 jukebox tracks have licensed native audio resources', () {
    expect(musicCatalog, hasLength(80));
    expect(musicCatalog.map((track) => track.id).toSet(), hasLength(80));
    final directory = Directory('android/app/src/main/res/raw');
    final resources = directory
        .listSync()
        .whereType<File>()
        .where((file) => file.uri.pathSegments.last.startsWith('music_'))
        .toList(growable: false);
    expect(resources, hasLength(80));
    final nativeBridge = File(
      'android/app/src/main/kotlin/nl/dragonhaven/app/MainActivity.kt',
    ).readAsStringSync();
    final licenses =
        File('assets/licenses/MUSIC_SOURCES.md').readAsStringSync();
    for (final track in musicCatalog) {
      final matches = resources.where((file) =>
          file.uri.pathSegments.last.startsWith('${track.rawResourceId}.'));
      expect(matches, hasLength(1), reason: track.rawResourceId);
      final file = matches.single;
      expect(file.lengthSync(), greaterThan(100), reason: track.rawResourceId);
      expect(nativeBridge, contains('R.raw.${track.rawResourceId}'),
          reason: '${track.rawResourceId} must survive release shrinking');
      expect(licenses, contains('`${track.rawResourceId}`'),
          reason: '${track.rawResourceId} needs an exact source record');
    }
    expect(licenses, contains('`no_license_conflict`'));
    expect(licenses, contains('`all_valid`'));
  });

  test('Android keeps hatch reminders through permission and exact-alarm paths',
      () {
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    final receiver = File(
      'android/app/src/main/kotlin/nl/dragonhaven/app/DragonHavenNotificationReceiver.kt',
    ).readAsStringSync();
    final alarmScheduler = File(
      'android/app/src/main/kotlin/nl/dragonhaven/app/DragonHavenAlarmScheduler.kt',
    ).readAsStringSync();
    final rescheduleReceiver = File(
      'android/app/src/main/kotlin/nl/dragonhaven/app/DragonHavenAlarmRescheduleReceiver.kt',
    ).readAsStringSync();
    final nativeBridge = File(
      'android/app/src/main/kotlin/nl/dragonhaven/app/MainActivity.kt',
    ).readAsStringSync();
    expect(manifest, contains('android.permission.POST_NOTIFICATIONS'));
    expect(manifest, contains('android.permission.SCHEDULE_EXACT_ALARM'));
    expect(manifest, contains('android.permission.RECEIVE_BOOT_COMPLETED'));
    expect(manifest, contains('android.intent.action.BOOT_COMPLETED'));
    expect(manifest, contains('android.intent.action.MY_PACKAGE_REPLACED'));
    expect(manifest, contains('SCHEDULE_EXACT_ALARM_PERMISSION_STATE_CHANGED'));
    expect(alarmScheduler, contains('setExactAndAllowWhileIdle'));
    expect(alarmScheduler, contains('setAndAllowWhileIdle'));
    expect(alarmScheduler,
        contains('notification.at <= System.currentTimeMillis()'));
    expect(alarmScheduler, contains('reschedulePending'));
    expect(rescheduleReceiver, contains('reschedulePending(context)'));
    expect(nativeBridge, contains('hasExactAlarmPermission'));
    expect(nativeBridge, contains('"exactAlarmGranted"'));
    expect(nativeBridge, contains('"openExactAlarmSettings"'));
    expect(nativeBridge, contains('ACTION_REQUEST_SCHEDULE_EXACT_ALARM'));
    expect(nativeBridge, contains('onRequestPermissionsResult'));
    expect(nativeBridge, contains('notificationsWaitingForPermission'));
    expect(nativeBridge,
        contains('mayAutomaticallyRequestNotificationPermission'));
    expect(nativeBridge,
        contains('packageInfo.lastUpdateTime > packageInfo.firstInstallTime'));
    expect(nativeBridge, contains('NOTIFICATION_PERMISSION_PROMPT_HANDLED'));
    expect(nativeBridge, contains('!activityInForeground'));
    expect(nativeBridge, contains('"permissionStatus"'));
    expect(nativeBridge, contains('"requestPermission"'));
    expect(nativeBridge, contains('areNotificationsEnabled()'));
    expect(nativeBridge, contains('"openNotificationSettings"'));
    expect(nativeBridge, contains('private var musicEnabled = false'));
    expect(
        nativeBridge, contains('private var flutterAppInForeground = false'));
    expect(nativeBridge, contains('private fun canPlayMusic()'));
    expect(nativeBridge, contains('"setAppForeground"'));
    expect(nativeBridge, contains('"takePendingNavigation"'));
    expect(nativeBridge, contains('override fun onNewIntent'));
    expect(nativeBridge, contains('"notificationTap"'));
    expect(receiver, contains('NOTIFICATION_KIND_EXTRA'));
    expect(receiver, contains('notificationId,'));
  });

  test('local time maps to the seven requested day phases', () {
    final day = DateTime(2026, 8, 21);
    expect(havenDayPhaseAt(day.copyWith(hour: 2)), HavenDayPhase.deepNight);
    expect(havenDayPhaseAt(day.copyWith(hour: 6)), HavenDayPhase.dawn);
    expect(havenDayPhaseAt(day.copyWith(hour: 8)), HavenDayPhase.morning);
    expect(havenDayPhaseAt(day.copyWith(hour: 12)), HavenDayPhase.day);
    expect(havenDayPhaseAt(day.copyWith(hour: 18)), HavenDayPhase.goldenHour);
    expect(havenDayPhaseAt(day.copyWith(hour: 20)), HavenDayPhase.dusk);
    expect(havenDayPhaseAt(day.copyWith(hour: 23)), HavenDayPhase.night);
  });

  test('dragon time moods are staggered and suppressible', () {
    final night = DateTime(2026, 8, 21, 23);
    final moods = {
      for (var seed = 0; seed < 24; seed++) dragonTimeMoodAt(night, seed),
    };
    expect(moods, contains(DragonTimeMood.asleep));
    expect(moods, contains(DragonTimeMood.restful));
    expect(
      dragonTimeMoodAt(night, 4, suppressed: true),
      DragonTimeMood.active,
    );
    expect(
      dragonTimeMoodAt(DateTime(2026, 8, 21, 12), 4),
      DragonTimeMood.active,
    );
  });

  test('all 27 released-dragon return tables are complete', () {
    final provider = HouseholdProvider();
    var tableCount = 0;
    for (final stage in const [
      DragonStage.hatchling,
      DragonStage.wyrmling,
      DragonStage.ascended,
    ]) {
      for (final moralAxis in MoralAxis.values) {
        for (final lawAxis in LawAxis.values) {
          final weights = provider.returnOutcomeWeightsForTesting(
            Pet(
              stage: stage,
              moralAxis: moralAxis,
              lawAxis: lawAxis,
              hatchSeed: tableCount,
            ),
          );
          expect(weights, everyElement(greaterThan(0)));
          expect(weights.fold<int>(0, (sum, weight) => sum + weight), 100);
          tableCount++;
        }
      }
    }
    expect(tableCount, 27);

    expect(
      provider.returnOutcomeWeightsForTesting(
        Pet(
          stage: DragonStage.hatchling,
          moralAxis: MoralAxis.good,
          lawAxis: LawAxis.lawful,
        ),
      ),
      [80, 15, 5],
    );
    expect(
      provider.returnOutcomeWeightsForTesting(
        Pet(
          stage: DragonStage.ascended,
          moralAxis: MoralAxis.evil,
          lawAxis: LawAxis.chaotic,
        ),
      ),
      [40, 30, 25, 5],
    );
  });

  test('Supabase stores durable social events and private profile metadata',
      () {
    final notifications = File(
      'supabase/migrations/202608260009_social_notification_inbox.sql',
    ).readAsStringSync();
    final presence = File(
      'supabase/migrations/202608260010_profile_last_online.sql',
    ).readAsStringSync();
    final friendCodex = File(
      'supabase/migrations/202608260011_friend_draconomicon.sql',
    ).readAsStringSync();
    final discoveryGuard = File(
      'supabase/migrations/202608260015_preserve_draconomicon_discoveries.sql',
    ).readAsStringSync();
    final socialCounts = File(
      'supabase/migrations/202608260016_social_summary_counts.sql',
    ).readAsStringSync();

    for (final kind in const [
      'friend_request',
      'friend_accepted',
      'trade_request',
      'trade_return',
      'trade_completed',
    ]) {
      expect(notifications, contains("'$kind'"));
    }
    expect(notifications, contains('list_social_notifications'));
    expect(notifications, contains('acknowledge_social_notifications'));
    expect(presence, contains('last_online_datetime timestamptz'));
    expect(presence, contains('profiles_touch_last_online_datetime'));
    expect(friendCodex, contains('discovered_forms text[]'));
    expect(friendCodex, contains('prismatic_forms text[]'));
    expect(friendCodex, contains('list_my_friends'));
    expect(discoveryGuard, contains('preserve_social_showcase_discoveries'));
    expect(discoveryGuard, contains('public.discovered_lineages'));
    expect(discoveryGuard, contains('greatest('));
    expect(socialCounts, contains('achievement_count integer'));
    expect(socialCounts, contains('dragon_count integer'));
    expect(socialCounts, contains('publish_social_summary_counts'));
  });

  test('online supporter frames are synchronized without breaking old apps',
      () {
    final migration = File(
      'supabase/migrations/202608300028_supporter_identity_cosmetics.sql',
    ).readAsStringSync();

    expect(migration, contains('frame_key text'));
    expect(migration, contains("frame_key = 'frame_supporter_founder'"));
    expect(
      migration,
      contains('update_my_profile(text, text, text, text)'),
    );
    expect(
      migration,
      contains('update_my_profile(text, text, text)'),
      reason: 'already released clients keep their compatible RPC overload',
    );
    expect(migration, contains('p.frame_key'));
    expect(migration, contains('from public.list_my_friends()'));
  });

  test('online keeper badges are synchronized without breaking old apps', () {
    final migration = File(
      'supabase/migrations/202608310029_keeper_badge_profiles.sql',
    ).readAsStringSync();

    expect(migration, contains('badge_key text'));
    expect(migration, contains("badge_key = 'badge_supporter_founder'"));
    expect(
      migration,
      contains('update_my_profile(text, text, text, text, text)'),
    );
    expect(
      migration,
      isNot(contains('drop function public.update_my_profile')),
      reason: 'released RPC overloads remain in place and preserve badge_key',
    );
    expect(migration, contains('p.badge_key'));
    expect(migration, contains('from public.list_my_friends()'));
  });

  test('legacy save import is versioned, audited and rollback-prepared', () {
    final migration = File(
      'supabase/migrations/202608280021_audited_legacy_inventory_import.sql',
    ).readAsStringSync();

    expect(migration, contains('legacy_inventory_import_audit'));
    expect(migration, contains('legacy_inventory_import_backups'));
    expect(migration, contains("import_version <> 1"));
    expect(migration, contains('source_schema_version'));
    expect(migration, contains('source_sha256'));
    expect(migration, contains("'coins_clamped'"));
    expect(migration, contains("'gems_clamped'"));
    expect(migration, contains("'chests_clamped'"));
    expect(migration, contains('pg_advisory_xact_lock'));
    expect(migration, contains("interval '30 days'"));
    expect(migration, contains('enable row level security'));
    expect(
      migration,
      contains('get_my_legacy_import_report'),
    );
    expect(
      migration,
      contains('revoke all on table public.legacy_inventory_import_audit'),
    );
    expect(
      migration,
      isNot(contains("'name', entry ->> 'name'")),
      reason: 'the public import report must not retain authored names',
    );
  });

  test('cloud saves retain five recoverable revisions for thirty days', () {
    final migration = File(
      'supabase/migrations/202608280022_cloud_save_revision_history.sql',
    ).readAsStringSync();

    expect(migration, contains('cloud_game_save_history'));
    expect(migration, contains('save_id uuid'));
    expect(migration, contains('parent_revision bigint'));
    expect(migration, contains('client_version text'));
    expect(migration, contains('schema_version integer'));
    expect(migration, contains("interval '30 days'"));
    expect(migration, contains('offset 4'));
    expect(migration, contains('push_cloud_game_save_v2'));
    expect(migration, contains('list_my_cloud_game_save_revisions'));
    expect(migration, contains('get_my_cloud_game_save_revision'));
    expect(migration, contains('pg_advisory_xact_lock'));
    expect(migration, contains('purge_expired_cloud_game_save_history'));
    expect(migration, contains('create extension if not exists pg_cron'));
    expect(migration, contains("'17 3 * * *'"));
    expect(migration, contains('enable row level security'));
    expect(
      migration,
      contains('revoke all on table public.cloud_game_save_history'),
    );
    final lintFix = File(
      'supabase/migrations/202608280023_fix_cloud_save_history_conflict_target.sql',
    ).readAsStringSync();
    expect(
      lintFix,
      contains(
        'on conflict on constraint cloud_game_save_history_user_id_revision_key',
      ),
    );
  });

  test('Group Adventure completion E2E is strictly staging-only', () {
    final script = File('tool/staging_social_e2e.ps1').readAsStringSync();
    final workflow = File('.github/workflows/staging.yml').readAsStringSync();

    expect(workflow, contains('social-flow-complete'));
    expect(workflow, contains(r'$parameters.CompleteGroupAdventure = $true'));
    expect(workflow, contains('STAGING_SUPABASE_ACCESS_TOKEN'));
    expect(script, contains('https://api.supabase.com/v1/projects/'));
    expect(script, contains('/database/query'));
    expect(script, contains(r"$ProjectRef -eq 'tnzathhutuwmohmjfrlo'"));
    expect(script, contains("status = 'running'"));
    expect(script, contains('Set-StagingGroupAdventureTwoPlayerFixture'));
    expect(script, contains('set required_players = 2'));
    expect(script, contains("l.status = 'waiting'"));
    expect(script, contains("interval '1 second'"));
    expect(script, contains('acknowledge_group_adventure_reward'));
    expect(script, contains('Een herhaalde Group Adventure-acknowledgement'));
    expect(script, contains('Remove-StagingGroupAdventureFixture'));
    expect(
      script,
      isNot(contains('grant execute')),
      reason: 'the time control must never become a player-callable RPC',
    );
  });

  test('production migration workflow is explicit and bounded to 21-23', () {
    final workflow =
        File('.github/workflows/production-migrate.yml').readAsStringSync();

    expect(workflow, contains('workflow_dispatch'));
    expect(workflow, contains('MIGRATE_PRODUCTION_20_TO_23'));
    expect(workflow, contains('tnzathhutuwmohmjfrlo'));
    expect(workflow, contains("'202608280020'"));
    for (final version in const [
      '202608280021',
      '202608280022',
      '202608280023',
    ]) {
      expect(workflow, contains("'$version'"));
    }
    expect(workflow, contains('Compare-Object'));
    expect(workflow, contains('db push --linked --include-all --dry-run'));
    expect(workflow, contains('release_server_preflight.ps1'));
    expect(workflow, contains('DragonHaven-production-migration-20-to-23'));
    expect(workflow, isNot(contains("tags:\n      - 'v*'")));
  });

  test('variable Expertise caps are enforced by migration 24', () {
    final migration = File(
      'supabase/migrations/202608280024_variable_expertise_caps.sql',
    ).readAsStringSync();

    expect(migration, contains('private.dragon_expertise_maximum'));
    expect(migration, contains('then 400'));
    expect(migration, contains('then 350'));
    expect(migration, contains('between 0 and 400'));
    expect(migration, contains('private.upsert_group_dragon'));
    expect(migration, contains('publish_social_showcase_v23'));
    expect(migration, contains('acknowledge_group_adventure_reward'));
    expect(migration, contains("evolution_path = 'mastery'"));
    expect(
      migration,
      contains(
        'revoke all on function private.dragon_expertise_maximum',
      ),
    );
  });

  test('production migration 24 workflow is exact and separately confirmed',
      () {
    final workflow = File(
      '.github/workflows/production-migrate-24.yml',
    ).readAsStringSync();

    expect(workflow, contains('MIGRATE_PRODUCTION_23_TO_24'));
    expect(workflow, contains("'202608280023'"));
    expect(workflow, contains("@('202608280024')"));
    expect(workflow, contains('Compare-Object'));
    expect(workflow, contains('db push --linked --include-all --dry-run'));
    expect(workflow, contains('release_server_preflight.ps1'));
    expect(workflow, contains('DragonHaven-production-migration-23-to-24'));
    expect(workflow, isNot(contains("tags:\n      - 'v*'")));
  });

  test('Infernal Mastery 400 caps are enforced by migration 25', () {
    final migration = File(
      'supabase/migrations/202608280025_infernal_mastery_and_social_form_count.sql',
    ).readAsStringSync();

    expect(migration, contains('private.dragon_expertise_maximum'));
    expect(migration, contains("p_evolution_path = 'mastery'"));
    expect(migration, contains('p_evolution_path = p_focus'));
    expect(migration, contains('then 400'));
    expect(migration, contains('publish_social_showcase_v24'));
    expect(migration, contains('cardinality(discovered_forms)'));
    expect(migration, contains('between 0 and 300'));
    expect(
      migration,
      contains(
        'revoke all on function private.dragon_expertise_maximum',
      ),
    );
  });

  test('production migration 25 workflow is exact and separately confirmed',
      () {
    final workflow = File(
      '.github/workflows/production-migrate-25.yml',
    ).readAsStringSync();

    expect(workflow, contains('MIGRATE_PRODUCTION_24_TO_25'));
    expect(workflow, contains("'202608280024'"));
    expect(workflow, contains("@('202608280025', '202608290026')"));
    expect(workflow, contains('deferred-202608290026.sql'));
    expect(workflow, contains("Compare-Object @('202608280025')"));
    expect(workflow, contains('Compare-Object'));
    expect(workflow, contains('db push --linked --include-all --dry-run'));
    expect(workflow, contains('release_server_preflight.ps1'));
    expect(workflow, contains('DragonHaven-production-migration-24-to-25'));
    expect(workflow, isNot(contains("tags:\n      - 'v*'")));
  });

  test('Special Chest trade migration and bounded workflow are explicit', () {
    final migration = File(
      'supabase/migrations/202608290026_special_chest_trade_support.sql',
    ).readAsStringSync();
    expect(migration, contains("'sinister', 'special'"));
    expect(migration, contains("r.item_key = 'special'"));
    expect(migration, contains('synchronize_trade_inventory_v25'));
    expect(migration, contains('reserve_trade_item_v25'));
    expect(migration, contains('transfer_trade_item_v25'));
    expect(migration, contains('import_legacy_inventory_v25'));

    final workflow =
        File('.github/workflows/production-migrate-26.yml').readAsStringSync();
    expect(workflow, contains('MIGRATE_PRODUCTION_25_TO_26'));
    expect(workflow, contains("\$expectedRemote = '202608280025'"));
    expect(workflow, contains("@('202608290026')"));
    expect(workflow,
        contains('supabase db push --linked --include-all --dry-run'));
    expect(workflow, contains('./tool/release_server_preflight.ps1'));
  });

  test('exact egg incubation seconds survive authoritative sync and trades',
      () {
    final migration = File(
      'supabase/migrations/202608300027_exact_egg_incubation_seconds.sql',
    ).readAsStringSync();
    expect(migration, contains('add column incubation_seconds integer'));
    expect(migration, contains('incubation_minutes * 60'));
    expect(migration, contains("'incubationSeconds'"));
    expect(migration, contains("entry ->> 'incubation_seconds'"));
    expect(migration, contains('synchronize_trade_inventory_v26'));
    expect(migration, contains('import_legacy_inventory_v26'));
    expect(migration, contains('between 60 and 1209600'));

    final workflow =
        File('.github/workflows/production-migrate-27.yml').readAsStringSync();
    expect(workflow, contains('MIGRATE_PRODUCTION_26_TO_27'));
    expect(workflow, contains("\$expectedRemote = '202608290026'"));
    expect(workflow, contains("@('202608300027')"));
    expect(workflow,
        contains('supabase db push --linked --include-all --dry-run'));
    expect(workflow, contains('./tool/release_server_preflight.ps1'));
    expect(workflow, contains('DragonHaven-production-migration-26-to-27'));
  });

  test('friend messages and Conclaves are private, bounded and durable', () {
    final migration = File(
      'supabase/migrations/202608310030_friend_messages_and_conclaves.sql',
    ).readAsStringSync();
    final ui = File('lib/screens/conclave_screen.dart').readAsStringSync();
    final workflow = File(
      '.github/workflows/production-migrate-31.yml',
    ).readAsStringSync();

    expect(migration, contains('private.are_friends'));
    expect(migration, contains("interval '24 hours'"));
    expect(migration, contains('dragonhaven-ephemeral-social-cleanup'));
    expect(migration, contains('friend_messages_allowed boolean'));
    expect(migration, contains("kind = 'friend_message'"));
    expect(migration, contains('member_limit between 4 and 20'));
    expect(migration, contains('level between 1 and 50'));
    expect(
      migration,
      contains(
        'create unique index conclaves_name_unique_idx on public.conclaves(lower(btrim(name)))',
      ),
    );
    expect(migration, contains('values (btrim(p_name)'));
    expect(migration, contains('private.prevent_conclave_name_change'));
    expect(migration, contains('conclave_name_is_immutable'));
    expect(migration, contains("raise exception 'conclave_name_immutable'"));
    expect(migration, contains('conclave_daily_contributions'));
    expect(migration, contains('contribution_on=today)>=20'));
    expect(migration, contains('((c.xp+10)/850)'));
    expect(migration, contains('private.reassign_departing_flightmaster'));
    expect(migration, contains('enable row level security'));
    expect(
      migration,
      contains('revoke all on table public.conclave_messages'),
    );
    expect(ui, isNot(contains('Flight Chronicle')));
    expect(ui, isNot(contains('Share achievements with Flight')));
    final correctiveMigration = File(
      'supabase/migrations/202608310031_fix_conclave_function_ambiguity.sql',
    ).readAsStringSync();
    expect(workflow, contains('MIGRATE_PRODUCTION_29_TO_31'));
    expect(workflow, contains("\$expectedRemote = '202608310029'"));
    expect(
      workflow,
      contains("\$expectedPending = @('202608310030', '202608310031')"),
    );
    expect(workflow,
        contains('supabase db push --linked --include-all --dry-run'));
    expect(workflow, contains('./tool/release_server_preflight.ps1'));
    expect(correctiveMigration, contains('target.sender_id = p_friend_id'));
    expect(
      correctiveMigration,
      contains('target.contribution_streak+1'),
    );

    expect(File('assets/images/ui/friends_message.png').existsSync(), isTrue);
    for (var index = 1; index <= 20; index++) {
      final suffix = index.toString().padLeft(2, '0');
      expect(
        File('assets/images/ui/conclave/conclave_emblem_$suffix.png')
            .existsSync(),
        isTrue,
      );
    }
    for (var stage = 1; stage <= 10; stage++) {
      final suffix = stage.toString().padLeft(2, '0');
      expect(
        File('assets/images/ui/conclave/aerie_stage_$suffix.png').existsSync(),
        isTrue,
      );
    }
  });

  test('public application health is read-only, private-data-free and gated',
      () {
    final migration = File(
      'supabase/migrations/202608310032_public_application_health.sql',
    ).readAsStringSync();
    final publicCheck =
        File('tool/public_server_health_check.ps1').readAsStringSync();
    final preflight =
        File('tool/release_server_preflight.ps1').readAsStringSync();
    final helper = File('tool/lib/public_auth_health.ps1').readAsStringSync();
    final parserTest =
        File('tool/test_public_application_health.ps1').readAsStringSync();
    final healthWorkflow =
        File('.github/workflows/health-check.yml').readAsStringSync();
    final migrationWorkflow = File(
      '.github/workflows/production-migrate-32.yml',
    ).readAsStringSync();

    expect(migration, contains('dragonhaven_public_health'));
    expect(migration, contains("'status', 'ok'"));
    expect(migration, contains("'service', 'dragonhaven-online'"));
    expect(migration, contains("'contract_version', 1"));
    expect(migration, contains('security invoker'));
    expect(migration, contains("set search_path = ''"));
    expect(
      migration,
      contains(
        'revoke all on function public.dragonhaven_public_health() from public',
      ),
    );
    expect(
      migration,
      contains(
        'grant execute on function public.dragonhaven_public_health() to anon, authenticated',
      ),
    );
    expect(migration, isNot(contains('security definer')));
    expect(migration, isNot(contains('from public.')));
    expect(migration, isNot(contains('auth.uid')));

    for (final script in [publicCheck, preflight]) {
      expect(script, contains('/rest/v1/rpc/dragonhaven_public_health'));
      expect(script, contains('ConvertFrom-DragonHavenApplicationHealth'));
      expect(script, contains('ApplicationHealthStatus'));
      expect(script, contains('ApplicationContractVersion'));
      expect(script, contains('ApplicationClockSkewMs'));
    }
    expect(helper, contains("[ValidateSet('GET', 'POST')]"));
    expect(helper, contains('MaximumClockSkewSeconds'));
    expect(
        helper, contains("[string]\$payload.service -ne 'dragonhaven-online'"));
    expect(parserTest, contains('invalidContractRejected'));
    expect(parserTest, contains('staleClockRejected'));
    expect(parserTest, contains('arrayRejected'));
    expect(healthWorkflow,
        contains('Check public production Auth and application endpoints'));
    expect(healthWorkflow, isNot(contains('-SkipApplicationHealth')),
        reason:
            'the scheduled production monitor must never bypass app health');
    expect(preflight, isNot(contains('SkipApplicationHealth')),
        reason: 'release preflight must always require application health');
    expect(
      File('.github/workflows/staging.yml').readAsStringSync(),
      contains('./tool/test_public_application_health.ps1'),
    );

    expect(migrationWorkflow, contains('MIGRATE_PRODUCTION_31_TO_32'));
    expect(migrationWorkflow, contains("\$expectedRemote = '202608310031'"));
    expect(
        migrationWorkflow, contains("\$expectedPending = @('202608310032')"));
    expect(migrationWorkflow, contains('-SkipApplicationHealth'));
    expect(migrationWorkflow, contains('./tool/release_server_preflight.ps1'));
    expect(migrationWorkflow,
        contains('DragonHaven-production-migration-31-to-32'));
  });
}
