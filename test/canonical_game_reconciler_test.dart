import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dragon_haven/services/canonical_game_intent.dart';
import 'package:dragon_haven/services/canonical_game_intent_store.dart';
import 'package:dragon_haven/services/canonical_game_reader.dart';
import 'package:dragon_haven/services/canonical_game_reconciler.dart';
import 'package:dragon_haven/services/canonical_game_snapshot.dart';
import 'package:dragon_haven/services/canonical_game_snapshot_store.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/game_domain_probe.dart';

const _owner = '11111111-1111-4111-8111-111111111111';
const _request = '22222222-2222-4222-8222-222222222222';
const _other = '33333333-3333-4333-8333-333333333333';
late Map<String, dynamic> _data;
CanonicalGameIntent _intent({String request = _request}) => CanonicalGameIntent(
    ownerId: _owner,
    requestId: request,
    action: 'open_chests',
    payload: {'tier': 'wooden', 'count': 2},
    minimumRevision: 5);
Map<String, dynamic> _wire({int revision = 6}) => jsonDecode(jsonEncode({
      'protocol': 2,
      'owner_id': _owner,
      'server_revision': revision,
      'state_sha256': 'ab' * 32,
      'ruleset_sha256': 'cd' * 32,
      'authority_mode': 'shadow',
      'mutations_enabled': false,
      'server_time': '2026-09-07T12:00:00Z',
      'data': _data,
    })) as Map<String, dynamic>;
CanonicalGameHttpReply _receipt(
        {bool replayed = false, String owner = _owner}) =>
    CanonicalGameHttpReply(200, {
      'protocol': 2,
      'owner_id': owner,
      'request_id': _request,
      'server_revision': 6,
      'state_sha256': 'ab' * 32,
      'authority_mode': 'shadow',
      'result': {'coins': 200},
      'replayed': replayed
    });
Matcher _error(String code) =>
    throwsA(isA<CanonicalGameException>().having((e) => e.code, 'code', code));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async => _data = (await runGameDomainProbe())['projections'].first
      as Map<String, dynamic>);
  late Directory directory;
  late CanonicalGameIntentStore intents;
  late CanonicalGameSnapshotStore snapshots;
  late String owner;
  late int epoch;
  late int readRevision;
  late List<CanonicalGameSnapshot> displays;
  setUp(() async {
    directory =
        await Directory.systemTemp.createTemp('dragonhaven-canonical-intent-');
    intents = CanonicalGameIntentStore(directory);
    snapshots = CanonicalGameSnapshotStore(directory);
    owner = _owner;
    epoch = 1;
    readRevision = 6;
    displays = [];
  });
  tearDown(() async => directory.delete(recursive: true));
  CanonicalGameReconciler reconciler({
    Future<CanonicalGameHttpReply> Function(CanonicalGameIntent)? send,
    Future<void> Function(CanonicalGameSnapshot)? display,
  }) =>
      CanonicalGameReconciler(
          intents: intents,
          snapshots: snapshots,
          currentOwner: () => owner,
          sessionEpoch: () => epoch,
          reader: CanonicalGameReader(
              currentOwner: () => owner,
              sessionEpoch: () => epoch,
              invoke: (_) async => _wire(revision: readRevision)),
          send: send ?? (_) async => _receipt(),
          applyDisplay: display ?? (snapshot) async => displays.add(snapshot));

  test(
      'intent permits only exact bounded actions and preserves payload order independently',
      () {
    final input = {'count': 2, 'tier': 'wooden'};
    final intent = CanonicalGameIntent(
        ownerId: _owner,
        requestId: _request,
        action: 'open_chests',
        payload: input,
        minimumRevision: 5);
    input['count'] = 9;
    expect(intent.sameIntent(_intent()), isTrue);
    expect(intent.toRequest(10068).containsKey('ownerId'), isFalse);
    for (final (action, payload) in <(String, Map<String, dynamic>)>[
      ('complete_trial', {'score': 99999}),
      ('open_chests', {'tier': 'wooden', 'count': 11}),
      ('open_chests', {'tier': 'wooden', 'count': 2, 'secretSeed': 'mine'}),
      ('tag_egg', {'eggId': 'legacy-egg', 'tagged': 'true'}),
      ('name_dragon', {'dragonId': 'd', 'name': 'x' * 25}),
    ]) {
      expect(
          () => CanonicalGameIntent(
              ownerId: _owner,
              requestId: _request,
              action: action,
              payload: payload,
              minimumRevision: 5),
          _error('game_intent_invalid'));
    }
  });

  test(
      'one pending identity survives restarts, a corrupted copy and interrupted acknowledgement',
      () async {
    await intents.prepare(_intent());
    final primary = File('${directory.path}/intent-v2-$_owner.json');
    await primary.writeAsString('broken');
    final reopened = CanonicalGameIntentStore(directory);
    expect((await reopened.pending(_owner))!.requestId, _request);
    await reopened.prepare(_intent());
    await primary.delete(); // A crash after deleting only the first copy.
    expect((await reopened.pending(_owner))!.requestId, _request);
    await reopened.acknowledge(_owner, _request);
    expect(await reopened.pending(_owner), isNull);
  });

  test(
      'simultaneous different intents and a wrong acknowledgement never replace the first',
      () async {
    final first = intents.prepare(_intent());
    final second = intents.prepare(_intent(request: _other));
    final rejected = expectLater(second, _error('game_intent_pending'));
    await first;
    await rejected;
    await expectLater(
        intents.acknowledge(_owner, _other), _error('game_intent_mismatch'));
    expect((await intents.pending(_owner))!.requestId, _request);
  });

  test(
      'two damaged copies block replacement instead of silently issuing a new purchase',
      () async {
    await intents.prepare(_intent());
    for (final suffix in ['', '.backup']) {
      await File('${directory.path}/intent-v2-$_owner$suffix.json')
          .writeAsString('broken');
    }
    await expectLater(intents.prepare(_intent(request: _other)),
        _error('game_intent_recovery_required'));
  });

  test(
      'a lost commit response retries the same UUID and applies only absolute inventory',
      () async {
    await intents.prepare(_intent());
    final requests = <String>[];
    final sync = reconciler(send: (intent) async {
      requests.add(intent.requestId);
      if (requests.length == 1)
        throw TimeoutException('simulated lost response after commit');
      return _receipt(replayed: true);
    });
    await expectLater(sync.resume(_owner), _error('game_command_unavailable'));
    expect((await intents.pending(_owner))!.requestId, _request);
    expect(displays, isEmpty);
    final result = await sync.resume(_owner);
    expect(requests, [_request, _request]);
    expect(result!.replayed, isTrue);
    expect(displays.single.coins, _data['wallet']['coins']);
    expect(await intents.pending(_owner), isNull);
  });

  test(
      'a failed display save leaves the intent durable for reconciliation after restart',
      () async {
    await intents.prepare(_intent());
    final failed = reconciler(
        display: (_) async => throw StateError('simulated local save failure'));
    await expectLater(failed.resume(_owner), throwsStateError);
    expect((await snapshots.inspect(_owner)).minimumRevision, 6);
    expect(await intents.pending(_owner), isNotNull);
    await reconciler(send: (_) async => _receipt(replayed: true))
        .resume(_owner);
    expect(await intents.pending(_owner), isNull);
    expect(displays, hasLength(1));
  });

  test(
      'an older receipt requires a snapshot at least as new as the cached revision',
      () async {
    await intents.prepare(_intent());
    await snapshots.persistFresh(
        CanonicalGameSnapshot.parse(_wire(revision: 7), expectedOwner: _owner));
    await expectLater(
        reconciler().resume(_owner), _error('game_snapshot_stale'));
    expect(await intents.pending(_owner), isNotNull);
    readRevision = 7;
    await reconciler().resume(_owner);
    expect(displays.single.serverRevision, 7);
  });

  test(
      'account changes during HTTP and ABA login changes keep the old intent unapplied',
      () async {
    await intents.prepare(_intent());
    final sync = reconciler(send: (_) async {
      epoch += 2;
      return _receipt();
    });
    await expectLater(sync.resume(_owner), _error('game_account_changed'));
    expect(displays, isEmpty);
    expect(await intents.pending(_owner), isNotNull);
  });

  test(
      'two resume taps share one in-flight request and acknowledgement comes last',
      () async {
    await intents.prepare(_intent());
    var sends = 0;
    final sync = reconciler(send: (_) async {
      sends++;
      return _receipt();
    }, display: (snapshot) async {
      expect((await snapshots.inspect(_owner)).snapshot!.serverRevision,
          snapshot.serverRevision);
      expect(await intents.pending(_owner), isNotNull);
      displays.add(snapshot);
    });
    await Future.wait([sync.resume(_owner), sync.resume(_owner)]);
    expect(sends, 1);
    expect(displays, hasLength(1));
    expect(await intents.pending(_owner), isNull);
  });

  test('only a durably recorded refusal is acknowledged after a fresh display',
      () async {
    await intents.prepare(_intent());
    final body = {
      'error': 'egg_tagged',
      'request_id': _request,
      'replayed': true
    };
    await expectLater(
        reconciler(send: (_) async => CanonicalGameHttpReply(503, body))
            .resume(_owner),
        _error('game_command_unavailable'));
    expect(await intents.pending(_owner), isNotNull);
    final refusal =
        await reconciler(send: (_) async => CanonicalGameHttpReply(422, body))
            .resume(_owner);
    expect(refusal!.failureCode, 'egg_tagged');
    expect(displays, hasLength(1));
    expect(await intents.pending(_owner), isNull);
  });

  test(
      'cross-owner receipts and same-revision state disagreement never get applied',
      () async {
    await intents.prepare(_intent());
    await expectLater(
        reconciler(send: (_) async => _receipt(owner: _other)).resume(_owner),
        _error('game_command_unavailable'));
    final wrongHash = _receipt().body as Map<String, dynamic>;
    wrongHash['state_sha256'] = 'ef' * 32;
    await expectLater(
        reconciler(send: (_) async => CanonicalGameHttpReply(200, wrongHash))
            .resume(_owner),
        _error('game_snapshot_conflict'));
    expect(displays, isEmpty);
    expect(await intents.pending(_owner), isNotNull);
  });
}
