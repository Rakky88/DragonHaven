import 'dart:math';
import 'dart:io';

import 'package:dragon_haven/models/dragon_egg.dart';
import 'package:dragon_haven/models/dragon_lineage.dart';
import 'package:dragon_haven/models/egg_altar.dart';
import 'package:dragon_haven/models/mystic_relic.dart';
import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/models/social.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image/image.dart' as image;

class FixedRoll implements Random {
  FixedRoll(this.rolls);
  final List<double> rolls;
  int index = 0;
  @override
  double nextDouble() => rolls[index++ % rolls.length];
  @override
  bool nextBool() => nextDouble() < .5;
  @override
  int nextInt(int max) => (nextDouble() * max).floor();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
      'Altar assets are bundled real transparent PNGs and server eligibility matches the family catalog',
      () {
    final files = Directory('assets/images/egg_altar')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.png'));
    expect(files.length, 16);
    for (final file in files) {
      final decoded = image.decodePng(file.readAsBytesSync())!;
      if (file.path.endsWith('altar_grove.png')) {
        expect(decoded.width / decoded.height, 1.5);
        expect(decoded.getPixel(0, 0).a, 255);
        continue;
      }
      expect(decoded.numChannels, 4, reason: file.path);
      for (final corner in [
        (0, 0),
        (decoded.width - 1, 0),
        (0, decoded.height - 1),
        (decoded.width - 1, decoded.height - 1)
      ]) {
        expect(decoded.getPixel(corner.$1, corner.$2).a, lessThanOrEqualTo(8),
            reason: file.path);
      }
    }
    final sql = File('supabase/migrations/202609070042_egg_altar.sql')
        .readAsStringSync();
    final allowed =
        sql.split('select p_lineage = any(array[')[1].split('])')[0];
    for (final lineage in dragonLineages) {
      expect(allowed.contains("'${lineage.id}'"),
          lineage.rarity != DragonRarity.specialEvent,
          reason: lineage.id);
    }
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));
  DragonEgg egg(String id, {String? lineage}) => DragonEgg(
      id: id,
      lineageId: lineage ?? standardDragonLineages.first.id,
      acquiredAt: DateTime(2026),
      hatchSeed: 8,
      prismatic: false);
  HouseholdProvider game() =>
      HouseholdProvider(random: Random(8), persistenceEnabled: false)
        ..pet = Pet(
            id: 'dragon',
            name: 'Ember',
            firstEgg: false,
            stage: DragonStage.hatchling)
        ..eggStash = [egg('one'), egg('two')];
  Matcher failure(String code) =>
      throwsA(isA<EggAltarException>().having((e) => e.code, 'code', code));

  test('ordinary and Sinister reward boundaries and single-heart pity', () {
    expect(
        rollWeaveReturn(FixedRoll([.24, .01]), sinister: false, misses: 0)
            .toJson(),
        {'fragments': 5, 'essence': 1, 'hearts': 1});
    expect(
        rollWeaveReturn(FixedRoll([.25, .02]), sinister: false, misses: 0)
            .toJson(),
        {'fragments': 5, 'essence': 0, 'hearts': 0});
    expect(
        rollWeaveReturn(FixedRoll([.24, .01]), sinister: true, misses: 0)
            .toJson(),
        {'fragments': 25, 'essence': 3, 'hearts': 1});
    expect(
        rollWeaveReturn(FixedRoll([.9, .9]), sinister: true, misses: 39).hearts,
        1);
    expect(
        rollWeaveReturn(FixedRoll([.9, .9]), sinister: false, misses: 39)
            .toJson(),
        {'fragments': 5, 'essence': 0, 'hearts': 1});
    expect(
        rollWeaveReturn(FixedRoll([.9, .9]), sinister: true, misses: 38).hearts,
        0);
  });

  test('Sinister always gives 3-5 Essence and a separate 10% single-heart roll',
      () {
    for (final (roll, essence) in [
      (0.0, 3),
      (1 / 3 - .000001, 3),
      (1 / 3, 4),
      (2 / 3 - .000001, 4),
      (2 / 3, 5),
      (.999999, 5),
    ]) {
      expect(
          rollWeaveReturn(FixedRoll([roll, .099999]), sinister: true, misses: 0)
              .toJson(),
          {'fragments': 25, 'essence': essence, 'hearts': 1});
      expect(
          rollWeaveReturn(FixedRoll([roll, .10]), sinister: true, misses: 0)
              .toJson(),
          {'fragments': 25, 'essence': essence, 'hearts': 0});
    }
  });

  test(
      'every Special lineage is blocked, including legacy eggs without specialEggId',
      () async {
    final g = game();
    for (final lineage
        in dragonLineages.where((d) => d.rarity == DragonRarity.specialEvent)) {
      g.eggStash = [egg('special-${lineage.id}', lineage: lineage.id)];
      await expectLater(
          g.returnEggToWeave(g.eggStash.single.id), failure('special_egg'));
      expect(g.eggStash, hasLength(1));
    }
    expect(g.eggAltar.wallet.fragments, 0);
  });

  test('tags prevent stale selections and survive nest, JSON and older backup',
      () async {
    final g = game();
    final old = g.exportState();
    await g.setEggTagged('one', true);
    await expectLater(g.returnEggToWeave('one'), failure('egg_tagged'));
    expect(await g.restoreCloudState(old), isTrue);
    expect(g.isEggTagged('one'), isTrue);
    expect(DragonEgg.fromJson(g.eggStash.first.toJson()).altarKnowledge.tagged,
        isTrue);
    expect(await g.activateEgg('one'), isTrue);
    expect(g.nestEgg!.altarKnowledge.tagged, isTrue);
    await g.setEggTagged('one', false);
    expect(g.isEggTagged('one'), isFalse);
    await expectLater(g.returnEggToWeave('one'), failure('egg_in_nest'));
  });

  test(
      'return is exactly once and old backups cannot resurrect the egg or wallet',
      () async {
    final g = game();
    final old = g.exportState();
    final reward = await g.returnEggToWeave('one');
    final second = await g.returnEggToWeave('one');
    expect(second.toJson(), reward.toJson());
    expect(g.eggAltar.totalReturned, 1);
    expect(g.eggAltar.wallet.fragments, 5);
    expect(await g.restoreCloudState(old), isTrue);
    expect(g.eggStash.map((e) => e.id), ['two']);
    expect(g.eggAltar.wallet.fragments, 5);
  });

  test('reserved eggs and unconfirmed Sinister returns consume nothing',
      () async {
    final g = game()..reservedOnlineTradeEggIds = {'one'};
    await expectLater(g.returnEggToWeave('one'), failure('egg_reserved'));
    g.eggStash.add(egg('sinister', lineage: 'sinisterra'));
    await expectLater(g.returnEggToWeave('sinister'),
        failure('sinister_confirmation_required'));
    final reward =
        await g.returnEggToWeave('sinister', sinisterConfirmed: true);
    expect(reward.fragments, 25);
    expect(reward.essence, inInclusiveRange(3, 5));
    expect(reward.hearts, inInclusiveRange(0, 1));
    expect(g.eggAltar.totalReturned, 1);
  });

  test(
      'recipes spend exact costs, crafted stock is absent from trade inventory',
      () async {
    final g = game()..eggAltar.wallet = const WeaveWallet(10, 1, 0);
    final originalDrops = [...MysticRelic.values];
    await g.craftAltarRelic(AltarRelic.nameweaversQuill);
    expect(g.eggAltar.wallet.toJson(),
        {'fragments': 0, 'essence': 0, 'hearts': 0});
    expect(g.eggAltar.count(AltarRelic.nameweaversQuill), 1);
    await expectLater(g.craftAltarRelic(AltarRelic.moralEcho),
        failure('insufficient_materials'));
    final trade = OnlineInventorySnapshot.fromGame(g).toTradeJson();
    expect((trade['relics'] as Map).containsKey('nameweaversQuill'), isFalse);
    expect(MysticRelic.values, originalDrops);
    expect(MysticRelic.astralLens.isShopAvailable, isTrue);
  });

  test(
      'Oracle preserves identity, tags, progression and discoveries; repeat use is free',
      () async {
    final g = game();
    await g.setEggTagged('one', true);
    g.eggAltar.crafted['weaveOracle'] = 2;
    final before = g.eggStash.first.toJson();
    final discoveries = {...g.discoveredForms};
    final hatched = g.totalHatched;
    await g.useAltarRelic(AltarRelic.weaveOracle, 'one');
    expect(g.eggKnowledge('one').lineage, isTrue);
    expect(g.isEggRarityKnown('one'), isTrue);
    expect(g.isEggTagged('one'), isTrue);
    expect(g.eggStash.first.hatchSeed, before['hatchSeed']);
    expect(g.discoveredForms, discoveries);
    expect(g.totalHatched, hatched);
    await expectLater(g.useAltarRelic(AltarRelic.weaveOracle, 'one'),
        failure('already_known'));
    expect(g.eggAltar.count(AltarRelic.weaveOracle), 1);
  });

  test(
      'Quill renames once, keeps first naming free, rejects invalid and unchanged names',
      () async {
    final g = game();
    g.pet.name = '';
    final named = g.totalNamed;
    expect(await g.nameDragon('dragon', 'Ember'), isTrue);
    expect(g.totalNamed, named + 1);
    expect(await g.nameDragon('dragon', 'Moss'), isFalse);
    g.eggAltar.crafted['nameweaversQuill'] = 1;
    for (final value in ['', '   ', 'Ember', 'A' * 25]) {
      expect(await g.nameDragon('dragon', value), isFalse);
      expect(g.eggAltar.count(AltarRelic.nameweaversQuill), 1);
    }
    final before = g.pet.toJson();
    final old = g.exportState();
    expect(await g.nameDragon('dragon', '  Moss  '), isTrue);
    expect(g.pet.name, 'Moss');
    expect(g.pet.id, before['id']);
    expect(g.pet.xp, before['xp']);
    expect(g.totalNamed, named + 1);
    expect(g.eggAltar.count(AltarRelic.nameweaversQuill), 0);
    await g.restoreCloudState(old);
    expect(g.pet.name, 'Moss');
    expect(g.eggAltar.count(AltarRelic.nameweaversQuill), 0);
  });

  test(
      'lost server response retries the same ID without consuming the egg locally',
      () async {
    final g = game();
    g.altarCurrentUserId = () => 'keeper';
    final ids = <String>[];
    g.altarCommand = (id, action, payload) async {
      ids.add(id);
      if (ids.length == 1) throw const EggAltarException('altar_unavailable');
      return {
        'state': EggAltarState(
            ownerId: 'keeper',
            revision: 2,
            wallet: const WeaveWallet(5, 0, 0),
            totalReturned: 1,
            returnedIds: {'one'}).toJson(),
        'receipt': {'reward': const WeaveWallet(5, 0, 0).toJson()}
      };
    };
    await expectLater(g.returnEggToWeave('one'), failure('altar_unavailable'));
    expect(g.eggStash, hasLength(2));
    expect(g.eggAltar.wallet.fragments, 0);
    expect(g.pendingAltarOperation, isNotNull);
    await g.retryPendingAltarOperation();
    expect(ids, ['return:one', 'return:one']);
    expect(g.eggStash.map((e) => e.id), ['two']);
    expect(g.eggAltar.wallet.fragments, 5);
    expect(g.pendingAltarOperation, isNull);
  });

  test(
      'a definitive server rejection clears pending operation and preserves egg',
      () async {
    final g = game()..altarCurrentUserId = () => 'keeper';
    g.altarCommand =
        (_, __, ___) async => throw const EggAltarException('egg_tagged');
    await expectLater(g.returnEggToWeave('one'), failure('egg_tagged'));
    expect(g.pendingAltarOperation, isNull);
    expect(g.eggStash, hasLength(2));
  });
}
