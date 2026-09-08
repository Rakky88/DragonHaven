import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dragon_haven/services/canonical_game_connection.dart';
import 'package:dragon_haven/services/canonical_game_intent.dart';
import 'package:dragon_haven/services/canonical_game_intent_store.dart';
import 'package:dragon_haven/services/canonical_game_session.dart';
import 'package:dragon_haven/services/canonical_game_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/game_domain_probe.dart';

const owner = '11111111-1111-4111-8111-111111111111';
const other = '22222222-2222-4222-8222-222222222222';
const request = '33333333-3333-4333-8333-333333333333';
const recovery = '44444444-4444-4444-8444-444444444444';
late Map<String, dynamic> data;
Matcher failure(String code) =>
    throwsA(isA<CanonicalGameException>().having((e) => e.code, 'code', code));

class Connection implements CanonicalGameConnection {
  @override
  String? currentOwner = owner;
  @override
  int sessionEpoch = 1;
  final changes = StreamController<int>.broadcast(sync: true);
  @override
  Stream<int> get accountChanges => changes.stream;
  int revision = 1;
  bool enabled = true;
  bool online = true;
  bool closed = false;
  bool loseReply = false;
  final sent = <CanonicalGameIntent>[];
  final applied = <String>{};
  int recoveries = 0;
  Future<void>? holdRead;
  Future<void>? holdSend;

  void switchAccount(String? account) {
    currentOwner = account;
    sessionEpoch++;
    changes.add(sessionEpoch);
  }

  Map<String, dynamic> wire(String account) => {
        'protocol': 2,
        'owner_id': account,
        'server_revision': revision,
        'state_sha256': revision.toRadixString(16).padLeft(64, '0'),
        'ruleset_sha256': 'ab' * 32,
        'ruleset_revision': 1,
        'authority_mode': 'shadow',
        'mutations_enabled': enabled,
        'server_time': '2026-09-08T12:00:00Z',
        'data': jsonDecode(jsonEncode(data)),
      };
  @override
  Future<Object?> read(Map<String, dynamic> request) async {
    final account = currentOwner!;
    if (holdRead != null) await holdRead;
    if (!online) throw const CanonicalGameException('game_command_unavailable');
    return wire(account);
  }

  @override
  Future<CanonicalGameHttpReply> send(CanonicalGameIntent intent) async {
    sent.add(intent);
    if (holdSend != null) await holdSend;
    if (!online) throw const CanonicalGameException('game_command_unavailable');
    final replayed = applied.contains(intent.requestId);
    if (!replayed && intent.minimumRevision != revision) {
      return CanonicalGameHttpReply(422, {
        'request_id': intent.requestId,
        'replayed': false,
        'error': 'game_state_changed'
      });
    }
    if (applied.add(intent.requestId)) revision++;
    if (loseReply) {
      loseReply = false;
      throw TimeoutException('committed, response lost');
    }
    return CanonicalGameHttpReply(200, {
      'protocol': 2,
      'owner_id': intent.ownerId,
      'request_id': intent.requestId,
      'server_revision': revision,
      'state_sha256': wire(intent.ownerId)['state_sha256'],
      'authority_mode': 'shadow',
      'result': 'purchased',
      'replayed': replayed,
    });
  }

  @override
  Future<Object?> recover(String requestId) async {
    recoveries++;
    revision++;
    return {
      'protocol': 2,
      'owner_id': currentOwner,
      'request_id': requestId,
      'barrier_revision': revision,
      'cancelled_commands': 0,
      'authority_mode': 'shadow',
      'replayed': false
    };
  }

  @override
  Future<void> dispose() async {
    closed = true;
    await changes.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async => data = (await runGameDomainProbe())['projections'].first
      as Map<String, dynamic>);
  late Directory directory;
  late Connection connection;
  late CanonicalGameSession session;
  setUp(() async {
    directory =
        await Directory.systemTemp.createTemp('dragonhaven-game-session-');
    connection = Connection();
    session = CanonicalGameSession(
        connection: connection,
        directory: directory,
        requestIdGenerator: () => request);
  });
  tearDown(() async {
    session.dispose();
    await directory.delete(recursive: true);
  });

  test(
      'a fresh owner view gates commands, journals before send and applies absolute state',
      () async {
    expect(session.canAct, isFalse);
    await expectLater(session.execute('purchase_title_chest', {}),
        failure('game_refresh_required'));
    expect(connection.sent, isEmpty);
    await session.synchronize();
    expect(session.canAct, isTrue);
    final held = Completer<void>();
    connection.holdSend = held.future;
    final result = session.execute('purchase_title_chest', {});
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect((await session.intents.pending(owner))!.requestId, request);
    expect(session.canAct, isFalse);
    held.complete();
    expect((await result)!.succeeded, isTrue);
    expect(session.snapshot!.serverRevision, 2);
    expect(session.snapshot!.coins, data['wallet']['coins']);
    expect(session.canAct, isTrue);
    expect(await session.intents.pending(owner), isNull);
  });

  test(
      'identical taps share the request, a different pending action is refused',
      () async {
    await session.synchronize();
    final held = Completer<void>();
    connection.holdSend = held.future;
    final first = session.execute('purchase_title_chest', {});
    final second = session.execute('purchase_title_chest', {});
    expect(identical(first, second), isTrue);
    await expectLater(session.execute('purchase_portrait_chest', {}),
        failure('game_command_busy'));
    held.complete();
    await Future.wait([first, second]);
    expect(connection.sent, hasLength(1));
  });

  test('offline cached inventory stays visible but cannot authorize spending',
      () async {
    await session.synchronize();
    session.dispose();
    connection = Connection()..online = false;
    session =
        CanonicalGameSession(connection: connection, directory: directory);
    await expectLater(
        session.synchronize(), failure('game_command_unavailable'));
    expect(session.snapshot!.ownerId, owner);
    expect(session.fresh, isFalse);
    expect(session.canAct, isFalse);
    await expectLater(session.execute('purchase_title_chest', {}),
        failure('game_refresh_required'));
    expect(connection.sent, isEmpty);
  });

  test(
      'lost responses resume the exact UUID after restart and never double apply',
      () async {
    await session.synchronize();
    connection.loseReply = true;
    await expectLater(session.execute('purchase_title_chest', {}),
        failure('game_command_unavailable'));
    expect(session.canAct, isFalse);
    expect((await session.intents.pending(owner))!.requestId, request);
    session.dispose();
    final restarted = Connection()..revision = connection.revision;
    restarted.applied.addAll(connection.applied);
    connection = restarted;
    session =
        CanonicalGameSession(connection: connection, directory: directory);
    expect((await session.synchronize())!.replayed, isTrue);
    expect(connection.sent.single.requestId, request);
    expect(connection.revision, 2);
    expect(await session.intents.pending(owner), isNull);
    expect(session.canAct, isTrue);
  });

  test('account change clears cached UI immediately and fences late reads',
      () async {
    await session.synchronize();
    final held = Completer<void>();
    connection.holdRead = held.future;
    final pending = session.synchronize();
    final refused = expectLater(pending, failure('game_account_changed'));
    await Future<void>.delayed(const Duration(milliseconds: 25));
    connection.switchAccount(other);
    expect(session.snapshot, isNull);
    expect(session.canAct, isFalse);
    connection.holdRead = null;
    await session.synchronize();
    held.complete();
    await refused;
    expect(session.snapshot!.ownerId, other);
    expect(session.canAct, isTrue);
  });

  test(
      'a stale observed revision is refused and replaced with current inventory',
      () async {
    await session.synchronize();
    connection.revision = 3; // Another device committed a change.
    final result = await session.execute('purchase_title_chest', {});
    expect(result!.failureCode, 'game_state_changed');
    expect(connection.applied, isEmpty);
    expect(session.errorCode, 'game_state_changed');
    expect(session.snapshot!.serverRevision, 3);
    expect(await session.intents.pending(owner), isNull);
    expect(session.canAct, isTrue);
  });

  test(
      'corrupt journals recover through the session without dispatching an action',
      () async {
    final store = CanonicalGameIntentStore(directory);
    await store.prepare(CanonicalGameIntent(
        ownerId: owner,
        requestId: recovery,
        action: 'purchase_title_chest',
        payload: {},
        minimumRevision: 1));
    for (final suffix in ['', '.backup']) {
      await File('${directory.path}/intent-v2-$owner$suffix.json')
          .writeAsString('broken');
    }
    await session.synchronize();
    expect(connection.recoveries, 1);
    expect(connection.sent, isEmpty);
    expect(session.snapshot!.serverRevision, 2);
    expect(await store.pending(owner), isNull);
    expect(session.canAct, isTrue);
  });

  test('paused engines remain readable and do not journal new spending',
      () async {
    connection.enabled = false;
    await session.synchronize();
    expect(session.fresh, isTrue);
    expect(session.canAct, isFalse);
    await expectLater(session.execute('purchase_title_chest', {}),
        failure('game_engine_disabled'));
    expect(connection.sent, isEmpty);
    expect(await session.intents.pending(owner), isNull);
  });
}
