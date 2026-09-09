import 'dart:math';
import 'package:dragon_haven/domain/game_command_engine.dart';
import 'package:dragon_haven/models/adventure.dart';
import 'package:dragon_haven/models/mystic_relic.dart';
import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/models/trial.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  final now = DateTime.utc(2026, 10, 25, 12);
  HouseholdProvider game() {
    final g = HouseholdProvider(
        persistenceEnabled: false, random: Random(82), clock: () => now);
    g.pet = Pet(
        id: 'wearer',
        favorite: true,
        stage: DragonStage.hatchling,
        firstEgg: false,
        acquiredAt: now,
        stageStartedAt: now,
        needsUpdatedAt: now);
    g.sanctuaryDragons.add(Pet(
        id: 'other',
        stage: DragonStage.hatchling,
        firstEgg: false,
        acquiredAt: now,
        stageStartedAt: now,
        needsUpdatedAt: now));
    for (final r in MysticRelic.values.where((r) => r.isEquipable)) {
      g.relicInventory[r] = 1;
      g.untradeableRelicInventory[r] = 1;
    }
    g.twinstarBroochEverObtained = true;
    addTearDown(g.dispose);
    return g;
  }

  test(
      'each brooch has one tenth the ordinary weight and owned brooches are excluded',
      () {
    final pool = mysticRelicDropPool();
    expect(pool, hasLength(64));
    for (final r in MysticRelic.values) {
      expect(
          pool.where((entry) => entry == r), hasLength(r.isEquipable ? 1 : 10));
      if (r.isEquipable) {
        expect(r.isShopAvailable, isFalse);
        expect(r.isConsumable, isFalse);
        expect(r.isAlwaysUntradeable, isTrue);
      }
    }
    final excluded = MysticRelic.values.where((r) => r.isEquipable).toSet();
    expect(mysticRelicDropPool(excluded: excluded), hasLength(60));
    for (var i = 0; i < 64; i++) {
      expect(
          trialRewardForGrade(TrialGrade.sPlus, 0, relicRoll: 0, relicChoice: i)
              .relic,
          pool[i]);
    }
  });

  test('equipment replaces one slot, moves, unequips and survives restore',
      () async {
    final g = game();
    for (final r in MysticRelic.values.where((r) => r.isEquipable)) {
      expect(await g.equipRelic(r, g.pet.id), isTrue);
      expect(g.equippedRelicFor(g.pet.id), r);
      expect(g.tradeableRelicCount(r), 0);
      expect(g.relicCount(r), 1);
    }
    expect(g.twinstarBroochDragonId, isNull);
    expect(g.equippedRelicDragonIds, hasLength(1));
    expect(await g.equipRelic(MysticRelic.soulbloomBrooch, 'other'), isTrue);
    expect(g.equippedRelicFor('wearer'), isNull);
    final restored = HouseholdProvider.forServerState(g.exportState(),
        random: Random(9), now: now, idGenerator: () => 'unused');
    addTearDown(restored.dispose);
    expect(restored.equippedRelicFor('other'), MysticRelic.soulbloomBrooch);
    expect(
        await restored.equipRelic(MysticRelic.soulbloomBrooch, null), isTrue);
    expect(restored.equippedRelicFor('other'), isNull);
    expect(
        await restored.equipRelic(MysticRelic.moralPrism, 'wearer'), isFalse);
    expect(await restored.equipRelic(MysticRelic.soulbloomBrooch, 'missing'),
        isFalse);
  });

  for (final relic
      in MysticRelic.values.where((r) => r.boostedExpertise != null)) {
    test('${relic.name} doubles only matching Trial expertise for its wearer',
        () async {
      final g = game();
      final focus = relic.boostedExpertise!;
      await g.equipRelic(relic, g.pet.id);
      final kind = switch (focus) {
        TrainingFocus.might => TrialKind.ruinBreaker,
        TrainingFocus.arcana => TrialKind.runeweaver,
        TrainingFocus.spirit => TrialKind.cavernFlight
      };
      g.trialOffers = [
        TrialOffer(id: 'equipped', kind: kind, appearedAt: now, startedAt: now),
        TrialOffer(
            id: 'unequipped', kind: kind, appearedAt: now, startedAt: now)
      ];
      final first = await g.completeTrial(
          offerId: 'equipped', dragonId: 'wearer', score: 20000);
      expect(first!.reward.statPoints, 14);
      expect(first.reward.expertiseRewards[focus], 14);
      expect(g.pet.trainingFor(focus), 14);
      expect(first.reward.xp, 69);
      final second = await g.completeTrial(
          offerId: 'unequipped', dragonId: 'other', score: 20000);
      expect(second!.reward.statPoints, 7);
      expect(g.sanctuaryDragons.single.trainingFor(focus), 7);
      expect(
          await g.completeTrial(
              offerId: 'equipped', dragonId: 'wearer', score: 20000),
          isNull);
    });

    test('${relic.name} applies once to group and seasonal adventure rewards',
        () async {
      final g = game();
      await g.equipRelic(relic, g.pet.id);
      final focus = relic.boostedExpertise!;
      final adventure = AdventureCatalog.byId.values
          .firstWhere((a) => a.kind == AdventureKind.group);
      Future<bool> claim() => g.applyOnlineGroupReward(
          lobbyId: 'lobby',
          adventureId: adventure.id,
          dragonId: g.pet.id,
          xp: 100,
          focus: focus.name,
          statPoints: 6,
          chestTier: 'gold',
          participantCount: 4);
      expect(await claim(), isTrue);
      expect(await claim(), isTrue);
      expect(g.pet.trainingFor(focus), 12);
      expect(g.pet.xp, 100);
      expect(
          await g.applyOnlineSeasonalPairReward(
              adventureId: 'pair',
              eventId: 'valentine_two_heartlights',
              dragonId: g.pet.id,
              xp: 100,
              might: 8,
              arcana: 8,
              spirit: 8,
              specialChestId: 'twinheart_keepsake_chest_v1',
              simulated: false),
          isTrue);
      for (final f in TrainingFocus.values) {
        expect(g.pet.trainingFor(f), f == focus ? 28 : 8);
      }
    });
  }

  test('Halloween S+ starts at 2000; Christmas retains its threshold', () {
    for (final entry in {
      1599: TrialGrade.b,
      1600: TrialGrade.a,
      1799: TrialGrade.a,
      1800: TrialGrade.s,
      1999: TrialGrade.s,
      2000: TrialGrade.sPlus
    }.entries) {
      expect(
          trialGradeForScore(TrialKind.witchlightWard, entry.key), entry.value);
    }
    expect(
        trialGradeForScore(TrialKind.hollyfrostGiftforge, 2500), TrialGrade.a);
  });

  test('canonical equipment command uses the same single-slot rule', () async {
    final g = game();
    await g.equipTwinstarBrooch('wearer');
    final output = await GameCommandEngine.execute(
        state: g.exportState(),
        action: 'equip_relic',
        payload: {'relic': 'emberheartBrooch', 'dragonId': 'wearer'},
        secretSeed:
            '00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff',
        now: now,
        keeperId: '00000000-0000-4000-8000-000000000001');
    expect(output['result'], true);
    expect((output['state'] as Map)['twinstarBroochDragonId'], isNull);
    expect((output['state'] as Map)['equippedRelicDragonIds'],
        {'emberheartBrooch': 'wearer'});
  });
}
