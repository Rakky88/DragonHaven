import 'dart:math';

import 'package:dragon_haven/domain/game_asset_snapshot.dart';
import 'package:dragon_haven/models/dragon_egg.dart';
import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/models/social.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  final now = DateTime.utc(2026, 9, 8, 12);

  test('sex is balanced and survives legacy trades, hatching and evolution',
      () {
    var males = 0;
    for (var seed = 0; seed < 65536; seed++) {
      if (DragonSex.fromSeed(seed) == DragonSex.male) males++;
    }
    expect(males, 32768);
    for (final seed in [38129, 48128, 12909388, 81023455]) {
      final egg = DragonEgg(
          id: 'egg-$seed',
          lineageId: 'clockskip',
          acquiredAt: now,
          hatchSeed: seed,
          prismatic: false);
      final traded = DragonEgg.fromJson(TradeItem.egg(egg).data);
      expect(traded.sex, egg.sex);
      final legacyTrade = Map<String, dynamic>.from(egg.toJson())
        ..remove('sex');
      expect(DragonEgg.fromJson(legacyTrade).sex, egg.sex);
      final dragon = traded.activate(coins: 0, gems: 0, activatedAt: now);
      dragon.hatch(now.add(const Duration(days: 15)));
      final saved = Pet.fromJson(dragon.toJson());
      saved.xp = Pet.ascendedXp;
      saved.addTraining(TrainingFocus.spirit, 300);
      saved.evolve(now.add(const Duration(days: 16)));
      saved.evolve(now.add(const Duration(days: 17)));
      expect(Pet.fromJson(saved.toJson()).sex, egg.sex);
    }
  });

  test(
      'old identities without a seed get a stable sex and unknown fields are ignored',
      () {
    final old = <String, dynamic>{
      'id': 'old-dragon',
      'name': 'Old friend',
      'stage': 'hatchling'
    };
    expect(Pet.fromJson(old).sex, Pet.fromJson(old).sex);
    expect(Pet.fromJson({...old, 'sex': 'female'}).sex, DragonSex.female);
    expect(
        Pet.fromJson({
          ...old,
          'highlightedExpertises': ['might', 'spirit', 'unknown', 12]
        }).highlightedExpertises,
        {TrainingFocus.might, TrainingFocus.spirit});
  });

  test('independent training highlights survive save/restore and toggle off',
      () async {
    final game = HouseholdProvider(
        persistenceEnabled: false, clock: () => now, random: Random(12));
    addTearDown(game.dispose);
    game.pet.stage = DragonStage.hatchling;
    await game.toggleDragonExpertiseHighlight(game.pet.id, TrainingFocus.might);
    await game.toggleDragonExpertiseHighlight(
        game.pet.id, TrainingFocus.spirit);
    expect(game.pet.highlightedExpertises,
        {TrainingFocus.might, TrainingFocus.spirit});
    await game.toggleDragonExpertiseHighlight(game.pet.id, TrainingFocus.might);
    final restored = HouseholdProvider.forServerState(game.exportState(),
        random: Random(9), now: now, idGenerator: () => 'unused');
    addTearDown(restored.dispose);
    expect(restored.pet.highlightedExpertises, {TrainingFocus.spirit});
    expect(restored.pet.sex, game.pet.sex);
    await restored.toggleDragonExpertiseHighlight(
        'missing', TrainingFocus.arcana);
    expect(restored.pet.highlightedExpertises, {TrainingFocus.spirit});
  });

  test(
      'old canonical saves normalize identity without loss; changed sex is detected',
      () {
    final game = HouseholdProvider(
        persistenceEnabled: false, clock: () => now, random: Random(12));
    addTearDown(game.dispose);
    final old = game.exportState();
    (old['pet'] as Map)
      ..remove('sex')
      ..remove('highlightedExpertises');
    final restored = HouseholdProvider.forServerState(old,
        random: Random(9), now: now, idGenerator: () => 'unused');
    addTearDown(restored.dispose);
    final saved = restored.exportState();
    expect(
        GameAssetSnapshot(old).hasSameAssets(GameAssetSnapshot(saved)), isTrue);
    (saved['pet'] as Map)['sex'] =
        restored.pet.sex == DragonSex.male ? 'female' : 'male';
    expect(GameAssetSnapshot(old).hasSameAssets(GameAssetSnapshot(saved)),
        isFalse);
  });
}
