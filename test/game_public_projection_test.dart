import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'package:dragon_haven/domain/game_command_engine.dart';
import 'package:dragon_haven/domain/game_public_projection.dart';
import 'package:dragon_haven/domain/server_entropy.dart';
import 'package:dragon_haven/models/adventure.dart';
import 'package:dragon_haven/models/chest.dart';
import 'package:dragon_haven/models/dragon_egg.dart';
import 'package:dragon_haven/models/egg_altar.dart';
import 'package:dragon_haven/models/game_presentation.dart';
import 'package:dragon_haven/models/mystic_relic.dart';
import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:flutter_test/flutter_test.dart';

const _owner = '11111111-1111-4111-8111-111111111111';
final _now = DateTime.utc(2026, 9, 7, 12);
final _seed = 'a5' * 32;

Map<String, dynamic> _fixture(
    {AltarEggKnowledge known = const AltarEggKnowledge()}) {
  final game = HouseholdProvider(
    random: ServerEntropy(_seed, stream: 'rewards'),
    clock: () => _now,
    idGenerator: ServerEntropy(_seed, stream: 'identities').uuid,
    persistenceEnabled: false,
  );
  game.pet
    ..stage = DragonStage.hatchling
    ..firstEgg = false
    ..name = 'Mica';
  game.eggStash = [
    DragonEgg(
      id: 'egg-hidden',
      lineageId: 'thunderpuff',
      acquiredAt: _now,
      hatchSeed: 987654321,
      prismatic: true,
      lawAxis: LawAxis.chaotic,
      moralAxis: MoralAxis.good,
      sizeFactor: 1.23,
      incubationSeconds: 3600,
      altarKnowledge: known,
    )
  ];
  game.eggAltar.crafted[AltarRelic.astralLens.name] = 1;
  game.eggAltar.crafted[AltarRelic.weaveOracle.name] = 1;
  game.relicInventory[MysticRelic.soulMirror] = 1;
  final source = game.exportState();
  game.dispose();
  return source;
}

Map<String, dynamic> _project(Map<String, dynamic> state) =>
    GamePublicProjection.project(state: state, ownerId: _owner, now: _now);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('unknown egg, seed and future nested metadata never enter the display',
      () {
    final source = _fixture();
    source['futureSecrets'] = {'answer': 'DO_NOT_LEAK'};
    source['eggStash'][0]['futureEggSecrets'] = {'answer': 'DO_NOT_LEAK'};
    source['pet']['futureDragonSecrets'] = {'answer': 'DO_NOT_LEAK'};
    final before = jsonEncode(source);
    final shown = _project(source);
    final egg = shown['eggs'].single;
    expect(egg['lineageId'], isNull);
    expect(egg['rarity'], isNull);
    expect(egg['lawAxis'], isNull);
    expect(egg['moralAxis'], isNull);
    expect(egg['hints']['en'], contains('spark'));
    expect(egg['incubationSeconds'], 3600);
    final text = jsonEncode(shown);
    for (final forbidden in [
      'hatchSeed',
      '987654321',
      'DO_NOT_LEAK',
      'pendingAltarOperation',
      'returnedIds',
      'operations',
      'misses'
    ]) {
      expect(text, isNot(contains(forbidden)));
    }
    expect(jsonEncode(source), before);
    expect(_project(source), shown);
  });

  test('actual Lens and Oracle commands reveal only their earned facts',
      () async {
    var source = _fixture();
    Future<void> use(String relic) async {
      final result = await GameCommandEngine.execute(
          state: source,
          action: 'use_altar_relic',
          payload: {'relic': relic, 'eggId': 'egg-hidden'},
          secretSeed: sha256.convert(utf8.encode(relic)).toString(),
          now: _now,
          keeperId: _owner);
      source = result['state'] as Map<String, dynamic>;
    }

    await use('astralLens');
    final lens = _project(source)['eggs'].single;
    expect(lens['rarity'], isNotNull);
    expect(lens['lineageId'], isNull);
    expect(lens.containsKey('spectral'), isFalse);
    await use('weaveOracle');
    final oracle = _project(source)['eggs'].single;
    expect(oracle['lineageId'], 'thunderpuff');
    expect(oracle['lawAxis'], isNull);
    expect(oracle['moralAxis'], isNull);
    expect(oracle.containsKey('sizeFactor'), isFalse);
    expect(oracle.containsKey('hatchSeed'), isFalse);
  });

  test('known alignment and tags survive without revealing other properties',
      () {
    final shown = _project(_fixture(
        known: const AltarEggKnowledge(
            tagged: true, tagRevision: 4, moral: true, order: true)));
    final egg = shown['eggs'].single;
    expect(egg['tagged'], isTrue);
    expect(egg['returnBlockReason'], 'egg_tagged');
    expect(egg['lawAxis'], 'chaotic');
    expect(egg['moralAxis'], 'good');
    expect(egg['lineageId'], isNull);
  });

  test('nest keeps its timer and hides genetics until a real hatch succeeds',
      () async {
    var source = _fixture();
    final activated = await GameCommandEngine.execute(
        state: source,
        action: 'activate_egg',
        payload: {'eggId': 'egg-hidden'},
        secretSeed: _seed,
        now: _now,
        keeperId: _owner);
    source = activated['state'] as Map<String, dynamic>;
    final nest = _project(source)['eggs'].single;
    expect(nest['location'], 'nest');
    expect(nest['startedAt'], _now.toIso8601String());
    expect(nest['lineageId'], isNull);
    expect(nest.containsKey('spectral'), isFalse);
    final hatched = await GameCommandEngine.execute(
        state: source,
        action: 'hatch_egg',
        payload: {'eggId': 'egg-hidden'},
        secretSeed: _seed,
        now: _now.add(const Duration(hours: 2)),
        keeperId: _owner);
    expect(hatched['result'], isTrue);
    final view = _project(hatched['state']);
    expect(view['eggs'], isEmpty);
    final dragon =
        (view['dragons'] as List).singleWhere((d) => d['id'] == 'egg-hidden');
    expect(dragon['lineageId'], 'thunderpuff');
    expect(dragon['spectral'], isTrue);
    expect(dragon['personalityTraitIds'], isNull);
    expect(dragon.containsKey('hatchSeed'), isFalse);
    final revealed = await GameCommandEngine.execute(
        state: hatched['state'],
        action: 'use_relic',
        payload: {'relic': 'soulMirror', 'dragonId': 'egg-hidden'},
        secretSeed: _seed,
        now: _now.add(const Duration(hours: 2)),
        keeperId: _owner);
    final revealedDragon = (_project(revealed['state'])['dragons'] as List)
        .singleWhere((d) => d['id'] == 'egg-hidden');
    expect(revealedDragon['personalityTraitIds'], isNotEmpty);
  });

  test('Special and Sinister appearance and protection remain visible', () {
    final source = _fixture();
    source['eggStash'] = [
      DragonEgg(
              id: 'special',
              lineageId: 'gloamgourd',
              acquiredAt: _now,
              hatchSeed: 8,
              prismatic: false,
              specialEggId: 'witchlight_egg_v1')
          .toJson(),
      DragonEgg(
              id: 'sinister',
              lineageId: 'sinisterra',
              acquiredAt: _now,
              hatchSeed: 9,
              prismatic: true)
          .toJson(),
    ];
    final eggs = _project(source)['eggs'];
    expect(eggs[0]['kind'], 'special');
    expect(eggs[0]['specialEggId'], 'witchlight_egg_v1');
    expect(eggs[0]['returnBlockReason'], 'special_egg');
    expect(eggs[0]['lineageId'], isNull);
    expect(eggs[1]['kind'], 'sinister');
    expect(eggs[1]['moralAxis'], 'evil');
    expect(eggs[1]['lineageId'], isNull);
  });

  test('trade presentations also redact eggs already absent from inventory',
      () {
    final source = _fixture();
    final egg = source['eggStash'][0];
    source['eggStash'] = [];
    source['pendingPresentations'] = [
      GamePresentation(
          id: 'trade-private',
          type: GamePresentationType.trade,
          createdAt: _now,
          sortAt: _now,
          payload: {
            'sentKind': 'egg',
            'sentKey': 'egg-hidden',
            'sentData': egg,
            'receivedKind': 'chest',
            'receivedKey': 'wooden',
            'receivedData': {'secret': 'DO_NOT_LEAK'},
            'privateFuturePayload': 'DO_NOT_LEAK',
          }).toJson()
    ];
    final shown = _project(source);
    final trade = shown['presentations'].single['trade'];
    expect(trade['sent']['egg']['lineageId'], isNull);
    expect(trade['received'], {'kind': 'chest', 'catalogId': 'wooden'});
    expect(jsonEncode(shown), isNot(contains('hatchSeed')));
    expect(jsonEncode(shown), isNot(contains('DO_NOT_LEAK')));
  });

  test(
      'running adventures hide their preselected reward without advancing time',
      () {
    final source = _fixture();
    source['adventureRuns'] = [
      AdventureRun(
              status: AdventureRunStatus.running,
              id: 'run-private',
              adventureId: AdventureCatalog.byId.keys.first,
              dragonId: source['pet']['id'],
              startedAt: _now.subtract(const Duration(hours: 3)),
              endsAt: _now.subtract(const Duration(hours: 1)),
              rewardTier: ChestTier.mythical)
          .toJson()
    ];
    final shown = _project(source);
    expect(shown['adventures']['runs'].single['rewardTier'], isNull);
    expect(shown['adventures']['runs'].single['status'], 'running');
    source['adventureRuns'][0]['status'] = 'rewardReady';
    expect(_project(source)['adventures']['runs'].single['rewardTier'],
        'mythical');
  });

  test('pending reconciliation and a foreign Altar cannot be displayed', () {
    final pending = _fixture()
      ..['pendingAltarOperation'] = {'action': 'return'};
    expect(() => _project(pending), throwsFormatException);
    final foreign = _fixture();
    foreign['eggAltar']['ownerId'] = '22222222-2222-4222-8222-222222222222';
    expect(() => _project(foreign), throwsFormatException);
  });
}
