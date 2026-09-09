import 'dart:io';
import 'dart:math';

import 'package:dragon_haven/models/adventure.dart';
import 'package:dragon_haven/models/dragon_lineage.dart';
import 'package:dragon_haven/models/music_track.dart';
import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/models/redeem_code.dart';
import 'package:dragon_haven/models/trial.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  const eventIds = <String>{
    'golden_wings_birthday',
    'halloween_witchlight',
    'christmas_winter_hearth',
    'new_year_first_dawn',
    'valentine_two_heartlights',
    'pride_every_color',
  };

  test('all six event contracts are complete and internally linked', () {
    final events = specialAdventureEventCatalog
        .where((event) => eventIds.contains(event.id))
        .toList(growable: false);
    expect(events, hasLength(6));
    expect(events.map((event) => event.id).toSet(), eventIds);

    for (final event in events) {
      final adventure = AdventureCatalog.byId[event.adventureId];
      final trial = trialDefinitions[trialKindByName(event.trialKindName)];
      final chest = specialChestById(event.rewards.specialChestId);
      final egg = specialEggById(chest?.specialEggId);
      final lineage = egg == null ? null : dragonLineageById(egg.lineageId);
      final music = seasonalMusicTracksById[event.temporaryMusicTrackId];
      final code = redeemCodeDefinition(event.previewCode);

      expect(adventure, isNotNull, reason: event.id);
      expect(adventure!.seasonalSpecial, isTrue, reason: event.id);
      if (event.id != 'golden_wings_birthday') {
        expect(adventure.specialReductionPerExpertisePoint,
            const Duration(minutes: 15),
            reason: event.id);
        expect(adventure.minimumDuration, const Duration(hours: 24),
            reason: event.id);
      }
      expect(trial?.specialEventId, event.id, reason: event.id);
      expect(trial?.duration, const Duration(seconds: 75), reason: event.id);
      expect(chest, isNotNull, reason: event.id);
      expect(egg, isNotNull, reason: event.id);
      expect(lineage?.rarity, DragonRarity.specialEvent, reason: event.id);
      expect(lineage?.secret, isTrue, reason: event.id);
      expect(egg!.normalSpectralChance, .05, reason: event.id);
      expect(egg.goldenHourSpectralChance, .10, reason: event.id);
      expect(music?.temporaryEventId, event.id, reason: event.id);
      expect(code?.rewardId, event.id, reason: event.id);
      const String? expectedKeeper = null;
      expect(code?.restrictedKeeperId, expectedKeeper, reason: event.id);
      expect(event.previewOwnerKeeperId, expectedKeeper, reason: event.id);
      expect(event.previewHours, 48, reason: event.id);
      expect(event.previewRewardsSimulatedInProduction, isTrue,
          reason: event.id);
      expect(event.rankingVisibleAfterEvent, const Duration(days: 5),
          reason: event.id);
    }
  });

  test('event windows use exact Europe Amsterdam boundaries', () {
    final expected = <String, (DateTime, DateTime)>{
      'golden_wings_birthday': (
        DateTime.utc(2026, 8, 31, 22),
        DateTime.utc(2026, 9, 2, 22)
      ),
      'halloween_witchlight': (
        DateTime.utc(2026, 10, 24, 22),
        DateTime.utc(2026, 11, 1, 23),
      ),
      'christmas_winter_hearth': (
        DateTime.utc(2026, 12, 24, 23),
        DateTime.utc(2026, 12, 26, 23),
      ),
      'new_year_first_dawn': (
        DateTime.utc(2026, 12, 31, 17),
        DateTime.utc(2027, 1, 1, 23),
      ),
      'valentine_two_heartlights': (
        DateTime.utc(2027, 2, 13, 23),
        DateTime.utc(2027, 2, 14, 23),
      ),
      'pride_every_color': (
        DateTime.utc(2027, 5, 31, 22),
        DateTime.utc(2027, 6, 7, 22),
      ),
    };

    for (final entry in expected.entries) {
      expect(
        specialAdventureWindowsAt(
          entry.value.$1.subtract(const Duration(milliseconds: 1)),
        ).any((window) => window.event.id == entry.key),
        isFalse,
        reason: '${entry.key} before start',
      );
      final window = specialAdventureWindowsAt(entry.value.$1)
          .singleWhere((window) => window.event.id == entry.key);
      expect(window.startsAt, entry.value.$1, reason: entry.key);
      expect(window.endsAt, entry.value.$2, reason: entry.key);
      expect(
        specialAdventureWindowsAt(entry.value.$2)
            .any((window) => window.event.id == entry.key),
        isFalse,
        reason: '${entry.key} after close',
      );
    }
  });

  test('every seasonal Special Chest grants its exact fixed recipe', () async {
    for (final event in specialAdventureEventCatalog
        .where((event) => eventIds.contains(event.id))) {
      final chest = specialChestById(event.rewards.specialChestId)!;
      final eggDefinition = specialEggById(chest.specialEggId)!;
      final game = HouseholdProvider(
        persistenceEnabled: false,
        random: Random(event.id.hashCode),
      )..specialChestInventory[chest.id] = 1;
      final coinsBefore = game.pet.coins;
      final gemsBefore = game.pet.gems;

      final reward = await game.openSpecialChest(chest.id);

      expect(reward?.coins, chest.coins, reason: event.id);
      expect(reward?.gems, chest.gems, reason: event.id);
      expect(reward?.specialEggId, eggDefinition.id, reason: event.id);
      expect(game.pet.coins, coinsBefore + chest.coins, reason: event.id);
      expect(game.pet.gems, gemsBefore + chest.gems, reason: event.id);
      final egg = game.eggStash.single;
      expect(egg.specialEggId, eggDefinition.id, reason: event.id);
      expect(egg.lineageId, eggDefinition.lineageId, reason: event.id);
      expect(egg.incubationDuration, eggDefinition.incubation,
          reason: event.id);
      expect(egg.moralAxis, eggDefinition.fixedMoral ?? egg.moralAxis,
          reason: event.id);
      expect(egg.moralAxisKnown, eggDefinition.moralKnownAtHatch,
          reason: event.id);
      expect(game.specialChestCount(chest.id), 0, reason: event.id);
    }
  });

  test('seasonal Trial reward is balanced and never multiplies score',
      () async {
    final now = DateTime.utc(2026, 10, 25, 12);
    final game = HouseholdProvider(
      initialize: false,
      persistenceEnabled: false,
      random: Random(7),
      clock: () => now,
    )
      ..pet = Pet(
        id: 'seasonal-trial-dragon',
        stage: DragonStage.hatchling,
        firstEgg: false,
        training: const {'might': 10, 'arcana': 20, 'spirit': 30},
      )
      ..trialOffers = [
        TrialOffer(
          id: 'witchlight-offer',
          kind: TrialKind.witchlightWard,
          appearedAt: now,
          specialEventKey: 'halloween_witchlight:launch:2026',
        ),
      ]
      ..trialRefilledAt = now;

    final completion = await game.completeTrial(
      offerId: 'witchlight-offer',
      dragonId: game.pet.id,
      score: 4200,
    );

    expect(completion?.score, 4200);
    expect(completion?.reward.grade, TrialGrade.sPlus);
    expect(completion?.reward.expertiseRewards, {
      TrainingFocus.might: 3,
      TrainingFocus.arcana: 2,
      TrainingFocus.spirit: 2,
    });
    expect(game.pet.trainingFor(TrainingFocus.might), 13);
    expect(game.pet.trainingFor(TrainingFocus.arcana), 22);
    expect(game.pet.trainingFor(TrainingFocus.spirit), 32);
  });

  test('after activation seasonal Trial is an equal fourth refill candidate',
      () {
    final counts = <TrialKind, int>{
      for (final kind in TrialKind.values) kind: 0
    };
    final now = DateTime.utc(2026, 10, 25, 12);
    for (var seed = 0; seed < 500; seed++) {
      final game = HouseholdProvider(random: Random(seed), clock: () => now)
        ..lastTrialEventActivationKey =
            specialAdventureWindowsAt(now).single.key;
      for (final offer in game.availableTrials) {
        counts.update(offer.kind, (value) => value + 1);
      }
    }
    final total = counts.values.fold<int>(0, (sum, count) => sum + count);
    for (final kind in <TrialKind>[
      ...standardTrialKinds,
      TrialKind.witchlightWard,
    ]) {
      expect(counts[kind]! / total, inInclusiveRange(.20, .30),
          reason: kind.name);
    }
    for (final kind in TrialKind.values.where(
      (kind) =>
          !standardTrialKinds.contains(kind) &&
          kind != TrialKind.witchlightWard,
    )) {
      expect(counts[kind], 0, reason: kind.name);
    }
  });

  test('Valentine online reward is idempotent and grants pair badge', () async {
    final game = HouseholdProvider(
      initialize: false,
      persistenceEnabled: false,
    )..pet = Pet(
        id: 'rosebound-runner',
        stage: DragonStage.hatchling,
        firstEgg: false,
        activeAdventureId: 'online-seasonal:pair-1',
      );

    Future<bool> apply() => game.applyOnlineSeasonalPairReward(
          adventureId: 'pair-1',
          eventId: 'valentine_two_heartlights',
          dragonId: game.pet.id,
          xp: 650,
          might: 8,
          arcana: 8,
          spirit: 8,
          specialChestId: 'twinheart_keepsake_chest_v1',
          simulated: false,
        );

    expect(await apply(), isTrue);
    expect(game.ownedBadgeIds, contains('heartbound_pair'));
    expect(game.specialChestCount('twinheart_keepsake_chest_v1'), 1);
    expect(game.pet.activeAdventureId, isNull);
    final xpAfterFirstGrant = game.pet.xp;
    expect(await apply(), isTrue);
    expect(game.specialChestCount('twinheart_keepsake_chest_v1'), 1);
    expect(game.pet.xp, xpAfterFirstGrant);
  });

  test('all seasonal runtime cutouts have transparent clean corners', () {
    final cutouts = <String>{
      for (final event in specialAdventureEventCatalog
          .where((event) => eventIds.contains(event.id))) ...{
        specialChestById(event.rewards.specialChestId)!.closedAssetPath,
        specialChestById(event.rewards.specialChestId)!.openedAssetPath,
        specialEggById(
          specialChestById(event.rewards.specialChestId)!.specialEggId,
        )!
            .assetPath,
      },
      for (final folder in const [
        'halloween',
        'christmas',
        'new_year',
        'valentine',
        'pride',
      ]) ...{
        'assets/images/events/$folder/trial_icon.webp',
        for (var index = 0; index < 6; index++)
          'assets/images/events/$folder/trial_sprite_$index.webp',
        for (final medal in const ['gold', 'silver', 'bronze'])
          'assets/images/events/$folder/podium_$medal.webp',
      },
      'assets/images/events/valentine/heartbound_pair_badge.webp',
      'assets/images/events/golden_wings/trial_icon.png',
    };

    for (final path in cutouts) {
      final file = File(path);
      expect(file.existsSync(), isTrue, reason: path);
      final decoded = image.decodeImage(file.readAsBytesSync());
      expect(decoded, isNotNull, reason: path);
      final sprite = decoded!;
      final corners = [
        sprite.getPixel(0, 0).a,
        sprite.getPixel(sprite.width - 1, 0).a,
        sprite.getPixel(0, sprite.height - 1).a,
        sprite.getPixel(sprite.width - 1, sprite.height - 1).a,
      ];
      expect(corners, everyElement(lessThanOrEqualTo(8)), reason: path);
      final edgeAlpha = <num>[
        for (var x = 0; x < sprite.width; x++) ...[
          sprite.getPixel(x, 0).a,
          sprite.getPixel(x, sprite.height - 1).a,
        ],
        for (var y = 0; y < sprite.height; y++) ...[
          sprite.getPixel(0, y).a,
          sprite.getPixel(sprite.width - 1, y).a,
        ],
      ];
      expect(edgeAlpha, everyElement(lessThanOrEqualTo(96)),
          reason: '$path must not have visible artwork clipped at an edge');
    }
  });

  test('seasonal migration enforces authenticated and bounded attempts', () {
    final sql = File('supabase/migrations/202609070040_seasonal_events.sql')
        .readAsStringSync();
    expect(sql, contains('auth.uid()'));
    expect(sql, contains('enable row level security'));
    expect(sql, contains('p_score > p_correct_actions * 220'));
    expect(sql, contains("keeper_id <> 'DH-17792DC5'"));
    expect(sql, contains('on conflict (event_id, occurrence_key, user_id)'));
    expect(sql, contains('seasonal_pair_occurrences'));
    expect(sql, contains('event_window.results_end_at'));
    expect(sql, contains("raise exception 'seasonal_pair_already_active'"));
    expect(sql, contains('grant execute on function'));
    expect(sql, isNot(contains('grant select on public.seasonal_')));
  });

  test('seasonal lint fixes are forward-only and unambiguous', () {
    final sql = File(
      'supabase/migrations/202609070041_seasonal_event_lint_fixes.sql',
    ).readAsStringSync();
    expect(
      sql,
      contains(
        'on conflict on constraint seasonal_event_previews_pkey do update',
      ),
    );
    expect(sql, contains('current_occurrence_key text'));
    expect(sql, contains('a.occurrence_key = current_occurrence_key'));
    expect(sql, contains('occurrence_key := current_occurrence_key'));
    expect(sql, isNot(contains('on conflict (user_id, event_id)')));
    expect(sql, isNot(contains('a.occurrence_key = occurrence_key')));
  });

  test('seasonal server rollout is staging-first and exactly scoped', () {
    final stagingWorkflow =
        File('.github/workflows/staging-seasonal-events.yml')
            .readAsStringSync();
    final productionWorkflow =
        File('.github/workflows/production-preview-access-48.yml')
            .readAsStringSync();
    final stagingE2e =
        File('tool/staging_seasonal_events_e2e.ps1').readAsStringSync();

    final gate = File('tool/preview_access_migration.ps1').readAsStringSync();
    expect(stagingWorkflow, contains('environment: staging'));
    expect(stagingWorkflow, contains('APPLY_STAGING_HALLOWEEN_PREVIEW_48'));
    expect(stagingWorkflow, contains('group: dragonhaven-staging-load'));
    expect(
        productionWorkflow, contains('APPLY_PRODUCTION_HALLOWEEN_PREVIEW_48'));
    expect(productionWorkflow, contains('staging_run_id'));
    expect(productionWorkflow, contains("run.conclusion -ne 'success'"));
    expect(productionWorkflow, contains('git diff --exit-code'));
    expect(gate, contains("'202609070047','202609070048'"));
    expect(gate, contains('Compare-Object'));
    expect(gate, contains('halloween_preview_contract.sql'));
    expect(gate, contains('release_server_preflight.ps1'));
    expect(gate, contains('supabase db lint'));
    expect(
        gate.indexOf('Test-PreviewContract \$true'),
        lessThan(
            gate.indexOf('supabase db push --linked --include-all --yes')));
    expect(
        gate,
        contains(
            "Environment -eq 'staging' -and \$ProjectRef -eq \$production"));
    expect(gate, contains('preview-authority-after.json'));

    expect(stagingE2e,
        contains("\$productionProjectRef = 'tnzathhutuwmohmjfrlo'"));
    expect(stagingE2e, contains('all_tables_have_rls'));
    expect(stagingE2e, contains('direct_table_access_absent'));
    expect(stagingE2e, contains('Anonymous seasonal RPC access'));
    expect(stagingE2e, contains('Clean seasonal staging attempt'));
    expect(stagingE2e, contains('Restore staging Keeper code'));
  });
}
