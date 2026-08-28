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
    int count(DragonRarity rarity) =>
        dragonLineages.where((lineage) => lineage.rarity == rarity).length;

    expect(count(DragonRarity.common), 20);
    expect(count(DragonRarity.uncommon), 10);
    expect(count(DragonRarity.rare), 6);
    expect(count(DragonRarity.veryRare), 3);
    expect(count(DragonRarity.legendary), 2);
    expect(count(DragonRarity.mythical), 1);
  });

  test('achievements have unique badges and use Common terminology', () {
    expect(achievementCatalog, hasLength(29));
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

  test('all nine chest tiers and all 24 personality traits exist', () {
    expect(ChestTier.values, hasLength(9));
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
    expect(mythical.lengthSync(), greaterThan(800000));
    expect(sinister.lengthSync(), greaterThan(780000));
    expect(mythical.readAsBytesSync().take(4), [82, 73, 70, 70]);
    expect(sinister.readAsBytesSync().take(4), [82, 73, 70, 70]);
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
    final nativeBridge = File(
      'android/app/src/main/kotlin/nl/dragonhaven/app/MainActivity.kt',
    ).readAsStringSync();
    expect(manifest, contains('android.permission.POST_NOTIFICATIONS'));
    expect(manifest, contains('android.permission.SCHEDULE_EXACT_ALARM'));
    expect(nativeBridge, contains('setExactAndAllowWhileIdle'));
    expect(nativeBridge, contains('setAndAllowWhileIdle'));
    expect(nativeBridge, contains('onRequestPermissionsResult'));
    expect(nativeBridge, contains('notificationsWaitingForPermission'));
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
}
