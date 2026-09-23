import 'dart:convert';
import 'package:dragon_haven/domain/game_asset_snapshot.dart';
import 'package:dragon_haven/domain/game_command_engine.dart';
import 'package:dragon_haven/domain/game_account_initialization.dart';
import 'package:dragon_haven/domain/game_public_projection.dart';
import 'package:dragon_haven/domain/server_entropy.dart';
import 'package:dragon_haven/models/account_preferences.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:flutter_test/flutter_test.dart';

const owner = '11111111-1111-4111-8111-111111111111';
final now = DateTime.utc(2026, 9, 20, 12);
final seed = 'a5' * 32;

Map<String, dynamic> fresh() {
  final game = HouseholdProvider(
    persistenceEnabled: false,
    random: ServerEntropy(seed, stream: 'rewards'),
    idGenerator: ServerEntropy(seed, stream: 'identities').uuid,
    clock: () => now,
  );
  final state = game.exportState();
  game.dispose();
  return state;
}

Future<Map<String, dynamic>> execute(
        Map<String, dynamic> state, String action, Map<String, dynamic> payload,
        {DateTime? at}) =>
    GameCommandEngine.execute(
        state: state,
        action: action,
        payload: payload,
        secretSeed: seed,
        now: at ?? now,
        keeperId: owner);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
      'trusted initialization keeps the same starter identity on retry and waits for naming',
      () {
    final first = GameAccountInitialization.create(secretSeed: seed, now: now);
    final replay = GameAccountInitialization.create(secretSeed: seed, now: now);
    expect(replay, first);
    expect(first['onboardingComplete'], false);
    expect(first['pet']['firstEgg'], true);
    expect(first['pet']['stage'], 'egg');
    expect(
        GameAccountInitialization.create(secretSeed: 'b6' * 32, now: now)['pet']
            ['id'],
        isNot(first['pet']['id']));
    final public =
        GamePublicProjection.project(state: first, ownerId: owner, now: now);
    expect(jsonEncode(public), isNot(contains('hatchSeed')));
  });

  test('server preferences survive a new read without altering owned assets',
      () async {
    final state = fresh();
    final assets = GameAssetSnapshot(state);
    final result = await execute(state, 'set_preferences', {
      'changes': jsonEncode({
        'languageCode': 'nl',
        'musicEnabled': false,
        'jukeboxShuffle': true,
        'enabledMusicTrackIds': <String>[],
        'myDragonsViewMode': 'compact',
        'myDragonsSortMode': 'dragonType',
        'myDragonsSortDescending': false,
        'enabledNotificationCategories': ['eggReady'],
      })
    });
    final saved = Map<String, dynamic>.from(result['state'] as Map);
    expect(assets.hasSameAssets(GameAssetSnapshot(saved)), true);
    final view =
        GamePublicProjection.project(state: saved, ownerId: owner, now: now);
    final prefs = view['collection']['preferences'];
    expect(prefs['languageCode'], 'nl');
    expect(prefs['musicEnabled'], false);
    expect(prefs['enabledNotificationCategories'], ['eggReady']);
    expect(prefs['myDragonsViewMode'], 'compact');
    expect(prefs['myDragonsSortMode'], 'dragonType');
    expect(prefs['myDragonsSortDescending'], false);
    expect(view.toString(), isNot(contains('hatchSeed')));
    expect(state['languageCode'], 'en');
  });

  test('preferences cannot grant ownership or play unowned music', () async {
    final state = fresh();
    for (final changes in [
      {'coins': 99999},
      {
        'ownedMusicTrackIds': ['fake']
      },
      {
        'enabledMusicTrackIds': ['fake']
      },
      {'languageCode': 'unknown'},
      {'musicEnabled': 1},
      {
        'enabledNotificationCategories': ['unknown']
      },
      {
        'disabledSeasonalMusicTrackIds': ['fake']
      },
    ]) {
      await expectLater(
          execute(state, 'set_preferences', {'changes': jsonEncode(changes)}),
          throwsA(isA<GameCommandException>()));
    }
    expect(AccountPreferences.fromState(state)['musicEnabled'], true);
  });

  test('name validation cannot acknowledge a rejected oversized or blank name',
      () async {
    for (final name in [' ', '🐉' * 24]) {
      await expectLater(execute(fresh(), 'set_account_name', {'name': name}),
          throwsA(isA<GameCommandException>()));
    }
  });

  test(
      'starter taps only accelerate the owned starter and leave its last second',
      () async {
    var state = Map<String, dynamic>.from((await execute(
        fresh(), 'complete_onboarding', {'name': 'Keeper'}))['state']);
    final id = state['pet']['id'];
    final before = DateTime.parse(state['pet']['stageStartedAt']);
    state = Map<String, dynamic>.from((await execute(
        state, 'tap_starter_egg', {'eggId': id, 'taps': 30}))['state']);
    expect(DateTime.parse(state['pet']['stageStartedAt']),
        before.subtract(const Duration(seconds: 30)));
    final closeToHatch = DateTime.parse(state['pet']['stageStartedAt'])
        .add(Duration(seconds: (state['pet']['incubationSeconds'] as int) - 2));
    final last = await execute(
        state, 'tap_starter_egg', {'eggId': id, 'taps': 30},
        at: closeToHatch);
    expect(
        DateTime.parse(last['state']['pet']['stageStartedAt'])
            .add(Duration(seconds: state['pet']['incubationSeconds'] as int)),
        closeToHatch.add(const Duration(seconds: 1)));
    await expectLater(
        execute(state, 'tap_starter_egg', {'eggId': 'another', 'taps': 1}),
        throwsA(isA<GameCommandException>()));
    await expectLater(
        execute(state, 'tap_starter_egg', {'eggId': id, 'taps': 31}),
        throwsA(isA<GameCommandException>()));
    state['pet']['firstEgg'] = false;
    await expectLater(
        execute(state, 'tap_starter_egg', {'eggId': id, 'taps': 1}),
        throwsA(isA<GameCommandException>()));
  });

  test('server onboarding starts the original egg once and is safe to replay',
      () async {
    final state = fresh()..['onboardingComplete'] = false;
    final start = now.add(const Duration(days: 2));
    final result = await execute(
        state, 'complete_onboarding', {'name': ' Keeper '},
        at: start);
    final saved = Map<String, dynamic>.from(result['state'] as Map);
    expect(saved['accountName'], 'Keeper');
    expect(saved['onboardingComplete'], true);
    expect(saved['pet']['id'], state['pet']['id']);
    expect(DateTime.parse(saved['pet']['stageStartedAt']), start);
    final replay = await execute(
        saved, 'complete_onboarding', {'name': 'Changed'},
        at: start.add(const Duration(days: 1)));
    expect(replay['state']['accountName'], 'Keeper');
    expect(replay['state']['pet'], saved['pet']);
  });
}
