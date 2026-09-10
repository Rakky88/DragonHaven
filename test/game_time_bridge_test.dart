import 'dart:convert';
import 'dart:io';

import 'package:dragon_haven/domain/game_asset_snapshot.dart';
import 'package:dragon_haven/domain/game_import_preparation.dart';
import 'package:dragon_haven/domain/game_time_bridge.dart';
import 'package:dragon_haven/models/adventure.dart';
import 'package:flutter_test/flutter_test.dart';

import 'game_import_preparation_test.dart' as fixture;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
      'device upload preserves every known instant, inventory and opaque metadata',
      () {
    const local = '2026-09-07T00:25:45.123456';
    final state = fixture.source();
    state['pet']['acquiredAt'] = local;
    state['pet']['stageStartedAt'] = local;
    state['pet']['needsUpdatedAt'] = local;
    state['eggStash'][0]['acquiredAt'] = local;
    state['incubatingEgg'] = {
      ...state['pet'] as Map,
      'id': 'nest-clock',
      'stage': 'egg'
    };
    state['sanctuaryDragons'] = [
      {...state['pet'] as Map, 'id': 'sanctuary-clock'}
    ];
    state['releasedDragons'] = [
      {...state['pet'] as Map, 'id': 'released-clock'}
    ];
    state['adventureRuns'] = [
      {'id': 'clock-journey', 'startedAt': local, 'endsAt': local}
    ];
    state['trialOffers'] = [
      {'appearedAt': local, 'startedAt': local}
    ];
    state['activities'] = [
      {'createdAt': local}
    ];
    state['pendingPresentations'] = [
      {
        'createdAt': local,
        'sortAt': local,
        'payload': {'createdAt': local}
      }
    ];
    for (final key in [
      'trialRefilledAt',
      'miniAdventureRefilledAt',
      'shortAdventureRefilledAt',
      'scheduledReturningAt',
      'returningSpecialAvailableUntil'
    ]) {
      state[key] = local;
    }
    for (final key in [
      'returningVisitors',
      'rareInteractionAt',
      'seasonalEventPreviewExpiresAt',
      'seasonalEventDismissedUntil'
    ]) {
      state[key] = {'source': local};
    }
    state['longAdventureRefillDay'] = '2026-09-07';
    state['trialStreakCreditedDayKeys'] = ['2026-09-06', '2026-09-07'];
    state['futureMetadata'] = {
      'createdAt': local,
      'odds': [1, 2, 3]
    };
    final before = jsonEncode(state);
    final explicit = GameTimeBridge.forUpload(state);
    final expected = DateTime.parse(local).toUtc().toIso8601String();
    expect(explicit['pet']['acquiredAt'], expected);
    expect(explicit['incubatingEgg']['needsUpdatedAt'], expected);
    expect(explicit['sanctuaryDragons'][0]['stageStartedAt'], expected);
    expect(explicit['releasedDragons'][0]['acquiredAt'], expected);
    expect(explicit['eggStash'][0]['acquiredAt'], expected);
    expect(explicit['adventureRuns'][0]['endsAt'], expected);
    expect(explicit['trialOffers'][0]['appearedAt'], expected);
    expect(explicit['activities'][0]['createdAt'], expected);
    expect(explicit['pendingPresentations'][0]['sortAt'], expected);
    expect(explicit['returningVisitors']['source'], expected);
    expect(explicit['rareInteractionAt']['source'], expected);
    expect(explicit['seasonalEventPreviewExpiresAt']['source'], expected);
    expect(explicit['longAdventureRefillDay'], state['longAdventureRefillDay']);
    expect(explicit['trialStreakCreditedDayKeys'],
        state['trialStreakCreditedDayKeys']);
    expect(explicit['futureMetadata'], state['futureMetadata']);
    expect(explicit['pendingPresentations'][0]['payload'],
        state['pendingPresentations'][0]['payload']);
    expect(GameAssetSnapshot(state).hasSameAssets(GameAssetSnapshot(explicit)),
        isTrue);
    expect(jsonEncode(state), before);
    GameTimeBridge.requireExplicitInstants(explicit);
    expect(GameTimeBridge.forUpload(explicit), explicit);
  });

  test(
      'a captured import refuses naive times and accepts the device-resolved equivalent',
      () {
    final state = fixture.source();
    state['pet']['acquiredAt'] = '2026-09-07T00:25:00.000';
    final run = AdventureRun(
        id: 'clock-run',
        adventureId: 'mini_1',
        dragonId: state['pet']['id'] as String,
        startedAt: DateTime(2026, 9, 7, 0, 25),
        endsAt: DateTime(2026, 9, 7, 0, 26),
        status: AdventureRunStatus.running);
    state['pet']['activeAdventureId'] = run.id;
    state['adventureRuns'] = [run.toJson()];
    expect(
        () => fixture.prepare(state, fixture.altar()),
        throwsA(isA<GameImportException>().having(
            (e) => e.code, 'code', 'game_import_device_clock_required')));
    final explicit = GameTimeBridge.forUpload(state);
    final result = fixture.prepare(explicit, fixture.altar());
    expect(result.state['adventureRuns'][0]['endsAt'],
        run.endsAt.toUtc().toIso8601String());
    expect(result.changedAssetKinds, isNot(contains('adventureRuns')));
    expect(result.state['pet']['xp'], state['pet']['xp']);
    expect(result.state['pet']['coins'], state['pet']['coins']);
    expect(result.state['chestInventory'], state['chestInventory']);
  });

  test(
      'device historical offsets across DST are preserved without using today’s offset',
      () {
    if (const ['Europe/Amsterdam', 'America/New_York']
        .contains(Platform.environment['TZ'])) {
      expect(DateTime(2026, 1, 1).timeZoneOffset,
          isNot(DateTime(2026, 7, 1).timeZoneOffset));
    }
    for (final value in [
      '2026-03-06T12:15:00.000',
      '2026-03-08T03:15:00.000',
      '2026-03-29T01:15:00.000',
      '2026-03-29T03:15:00.000',
      '2026-10-25T02:15:00.000',
      '2026-11-01T01:15:00.000',
      '2026-07-01T00:15:00.000+05:30',
      '2026-01-01T00:15:00.000-05:00'
    ]) {
      final converted = GameTimeBridge.forUpload({
        'pet': {'acquiredAt': value}
      });
      expect(
          DateTime.parse(converted['pet']['acquiredAt'] as String)
              .microsecondsSinceEpoch,
          DateTime.parse(value).microsecondsSinceEpoch);
    }
  });

  test(
      'invalid timestamps are refused and the read-only check works with const maps',
      () {
    for (final invalid in [
      'not-a-date',
      '2026-09-07',
      '2026-02-30T12:00:00.000Z',
      '2026-09-07T25:00:00.000Z',
      '2026-09-07T12:00:00.000+99:99',
      42
    ]) {
      expect(
          () => GameTimeBridge.forUpload({
                'pet': {'acquiredAt': invalid}
              }),
          throwsFormatException);
    }
    const explicit = {
      'pet': {'acquiredAt': '2026-09-07T00:15:00.000Z'}
    };
    expect(() => GameTimeBridge.requireExplicitInstants(explicit),
        returnsNormally);
    expect(
        () => GameTimeBridge.requireExplicitInstants({
              'pet': {'acquiredAt': '2026-09-07T00:15:00.000'}
            }),
        throwsFormatException);
  });
}
