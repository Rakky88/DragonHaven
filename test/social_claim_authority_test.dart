import 'dart:convert';

import 'package:dragon_haven/domain/game_command_engine.dart';
import 'package:dragon_haven/models/mystic_relic.dart';
import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const owner = '11111111-1111-4111-8111-111111111111';
  const source = '22222222-2222-4222-8222-222222222222';
  final now = DateTime.utc(2026, 9, 10, 12);
  late Map<String, dynamic> state;
  late String dragonId;
  var commandSequence = 0;
  Map<String, dynamic> copy(Map<String, dynamic> value) =>
      jsonDecode(jsonEncode(value)) as Map<String, dynamic>;
  setUp(() {
    commandSequence = 0;
    final game = HouseholdProvider(persistenceEnabled: false, clock: () => now);
    game.pet
      ..stage = DragonStage.hatchling
      ..favorite = true
      ..firstEgg = false
      ..name = 'Social Probe';
    dragonId = game.pet.id;
    state = game.exportState();
    game.dispose();
  });
  Map<String, dynamic> context(String action, Map<String, dynamic> facts) => {
        'version': 1,
        'ownerId': owner,
        'action': action,
        'sourceId': source,
        'fingerprint': 'a5' * 32,
        'facts': facts,
      };
  Map<String, dynamic> group() => context('claim_group_reward', {
        'adventureId': 'group_1',
        'dragonId': dragonId,
        'xp': 400,
        'focus': 'spirit',
        'statPoints': 5,
        'chestTier': 'dragon',
        'participantCount': 4,
      });
  Map<String, dynamic> pair({bool simulated = false}) =>
      context('claim_pair_reward', {
        'eventId': 'valentine_two_heartlights',
        'dragonId': dragonId,
        'xp': 650,
        'might': 8,
        'arcana': 8,
        'spirit': 8,
        'specialChestId': 'twinheart_keepsake_chest_v1',
        'simulated': simulated,
      });
  Future<Map<String, dynamic>> execute(String action,
          {Map<String, dynamic>? verified, Map<String, dynamic>? input}) =>
      GameCommandEngine.execute(
          state: state,
          action: action,
          payload: input ??
              {
                switch (action) {
                  'claim_group_reward' => 'lobbyId',
                  'claim_pair_reward' => 'adventureId',
                  _ => 'prizeId',
                }: source
              },
          secretSeed:
              (128 + commandSequence++).toRadixString(16).padLeft(64, '0'),
          now: now,
          keeperId: owner,
          verifiedSocialContext: verified);
  Matcher failure(String code) => throwsA(isA<GameCommandException>()
      .having((e) => e.code, 'server refusal', code));

  test(
      'verified group offers credit only at claim, including after event close',
      () async {
    final offers = [
      {
        'id': source,
        'kind': 'group',
        'catalogId': 'group_1',
        'dragonId': dragonId,
        'position': null,
        'readyAt': DateTime.utc(2027, 1, 2).toIso8601String(),
      }
    ];
    Future<Map<String, dynamic>> run(String action) =>
        GameCommandEngine.execute(
            state: state,
            action: action,
            payload: action == 'refresh' ? {} : {'lobbyId': source},
            secretSeed: 'a1' * 32,
            now: DateTime.utc(2027, 1, 8),
            keeperId: owner,
            verifiedSocialClaims: offers,
            verifiedSocialContext: action == 'refresh' ? null : group());
    final refreshed = await run('refresh');
    state = refreshed['state'] as Map<String, dynamic>;
    expect(state['eventPointGroupIds'], isEmpty);
    final claimed = await run('claim_group_reward');
    state = claimed['state'] as Map<String, dynamic>;
    expect((state['eventProgress'] as Map).values.single['points'], 50);
    expect(state['eventPointGroupIds'], contains(source));
    final repeated = await run('claim_group_reward');
    expect((repeated['state']['eventProgress'] as Map).values.single['points'],
        50);
  });

  test(
      'group claim requires a sealed owner/source and retains brooch bonuses once',
      () async {
    state['relicInventory']['twinstarBrooch'] = 1;
    state['untradeableRelicInventory']['twinstarBrooch'] = 1;
    state['twinstarBroochEverObtained'] = true;
    state['uniqueRelicsEverObtained'] = [MysticRelic.twinstarBrooch.name];
    final equip = await GameCommandEngine.execute(
        state: state,
        action: 'equip_relic',
        payload: {'relic': 'twinstarBrooch', 'dragonId': dragonId},
        secretSeed: '7b' * 32,
        now: now,
        keeperId: owner);
    state = equip['state'] as Map<String, dynamic>;
    final beforeXp = state['pet']['xp'] as int;
    final first = await execute('claim_group_reward', verified: group());
    expect(first['result'],
        {'accepted': true, 'alreadyApplied': false, 'sourceId': source});
    state = first['state'] as Map<String, dynamic>;
    expect(state['pet']['xp'], beforeXp + 800);
    expect(state['chestInventory']['dragon'], 1);
    expect(state['totalGroupFourCompleted'], 1);
    final before = copy(state);
    final again = await execute('claim_group_reward', verified: group());
    expect(again['result']['alreadyApplied'], isTrue);
    final repeated = copy(again['state'] as Map<String, dynamic>);
    // Equal-time activity presentation order is not an economic change.
    expect(repeated.remove('activities'),
        unorderedEquals(before.remove('activities') as List));
    expect(repeated, before);
    state = again['state'] as Map<String, dynamic>;
    state['pet']['activeAdventureId'] = 'new-journey-after-legacy-claim';
    final migrated = await execute('claim_group_reward', verified: group());
    expect(migrated['result']['alreadyApplied'], isTrue);
    expect(migrated['state']['pet']['activeAdventureId'],
        'new-journey-after-legacy-claim');
    expect(migrated['state']['pet']['xp'], beforeXp + 800);
  });

  test('pair claim grants the catalog chest and all three expertises only once',
      () async {
    final before = copy(state);
    final result = await execute('claim_pair_reward', verified: pair());
    state = result['state'] as Map<String, dynamic>;
    expect(state['pet']['xp'], (before['pet']['xp'] as int) + 650);
    expect(state['specialChestInventory']['twinheart_keepsake_chest_v1'], 1);
    for (final focus in ['might', 'arcana', 'spirit']) {
      expect(state['pet']['training'][focus],
          (before['pet']['training'][focus] as int) + 8);
    }
    final again = await execute('claim_pair_reward', verified: pair());
    expect(again['state'], state);
  });

  test(
      'podium applies its server placement, chest and emote without duplicate grants',
      () async {
    final verified = context('claim_podium_prize', {
      'eventId': 'sunwake_summer_sea',
      'position': 1,
    });
    final result = await execute('claim_podium_prize', verified: verified);
    state = result['state'] as Map<String, dynamic>;
    expect(state['chestInventory']['mythical'], 1);
    expect(state['ownedDragonEmoteIds'], contains('seasonal_sunwake_gold'));
    expect(state['seasonalPodiumEmoteWinCounts']['seasonal_sunwake_gold'], 1);
    final again = await execute('claim_podium_prize', verified: verified);
    expect(again['state'], state);
  });

  test(
      'missing, foreign or forged context is rejected and cannot be smuggled through a save',
      () async {
    final original = copy(state);
    state['_verifiedSocialContext'] = group();
    await expectLater(execute('claim_group_reward'),
        failure('game_social_claim_unavailable'));
    state = copy(original);
    for (final corrupt in <void Function(Map<String, dynamic>)>[
      (c) => c['ownerId'] = source,
      (c) => c['sourceId'] = owner,
      (c) => c['action'] = 'claim_pair_reward',
      (c) => c['fingerprint'] = '',
      (c) => c['facts']['dragonId'] = 'not-owned',
      (c) => c['facts']['xp'] = 100000000,
      (c) => c['facts']['participantCount'] = 1,
      (c) => c['facts']['chestTier'] = 'special',
      (c) => c['facts']['adventureId'] = 'mini_1',
    ]) {
      final value = group();
      corrupt(value);
      await expectLater(execute('claim_group_reward', verified: value),
          failure('game_social_claim_unavailable'));
      expect(state, original);
    }
    await expectLater(
        execute('claim_group_reward', verified: group(), input: {
          'lobbyId': source,
          'xp': 99999,
        }),
        failure('invalid_command'));
  });

  test('a foreign journey and an active Trial prevent reward mutation',
      () async {
    state['pet']['activeAdventureId'] = 'online-group:other-lobby';
    await expectLater(execute('claim_group_reward', verified: group()),
        failure('game_social_claim_unavailable'));
    state['pet']['activeAdventureId'] = null;
    state['_activeGameAttempt'] = {'type': 'trial', 'id': source};
    await expectLater(execute('claim_group_reward', verified: group()),
        failure('game_attempt_in_progress'));
  });
}
