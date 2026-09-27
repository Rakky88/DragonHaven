import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dragon_haven/services/canonical_game_connection.dart';
import 'package:dragon_haven/services/canonical_game_intent.dart';
import 'package:dragon_haven/services/canonical_game_reconciler.dart';
import 'package:dragon_haven/services/canonical_game_session.dart';
import 'package:dragon_haven/services/canonical_game_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/game_domain_probe.dart';

const _owner = '11111111-1111-4111-8111-111111111111';
const _adRequest = '22222222-2222-4222-8222-222222222222';
const _nextRequest = '33333333-3333-4333-8333-333333333333';
const _claim = '44444444-4444-4444-8444-444444444444';

Matcher _failure(String code) => throwsA(
    isA<CanonicalGameException>().having((error) => error.code, 'code', code));

/// Keeps the recorded server refusal across a simulated client restart.
class _Server {
  _Server(this.data, this.failureCode);
  final Map<String, dynamic> data;
  final String failureCode;
  final failedRequests = <String>{};
  final sentAdRequests = <String>[];
  int revision = 1;
  bool loseFirstAdReply = true;
  bool failNextRead = false;

  Map<String, dynamic> snapshot() => {
        'protocol': 2,
        'owner_id': _owner,
        'server_revision': revision,
        'state_sha256': revision.toRadixString(16).padLeft(64, '0'),
        'ruleset_sha256': 'ab' * 32,
        'ruleset_revision': 1,
        'authority_mode': 'server',
        'mutations_enabled': true,
        'server_time': '2026-09-27T12:00:00Z',
        'data': jsonDecode(jsonEncode(data)),
      };
}

class _Connection implements CanonicalGameConnection {
  _Connection(this.server);
  final _Server server;
  final _changes = StreamController<int>.broadcast();
  @override
  String get currentOwner => _owner;
  @override
  int get sessionEpoch => 1;
  @override
  Stream<int> get accountChanges => _changes.stream;

  @override
  Future<Object?> read(Map<String, dynamic> request) async {
    if (server.failNextRead) {
      server.failNextRead = false;
      throw const CanonicalGameException('game_snapshot_unavailable');
    }
    return server.snapshot();
  }

  @override
  Future<CanonicalGameHttpReply> send(CanonicalGameIntent intent) async {
    if (intent.action == 'claim_rewarded_ad') {
      expect(intent.payload, {'claimId': _claim});
      server.sentAdRequests.add(intent.requestId);
      final replayed = !server.failedRequests.add(intent.requestId);
      if (server.loseFirstAdReply) {
        server.loseFirstAdReply = false;
        throw TimeoutException('Refusal recorded, response lost');
      }
      return CanonicalGameHttpReply(422, {
        'request_id': intent.requestId,
        'replayed': replayed,
        'error': server.failureCode,
      });
    }
    expect(intent.action, 'refresh');
    server.revision++;
    return CanonicalGameHttpReply(200, {
      'protocol': 2,
      'owner_id': _owner,
      'request_id': intent.requestId,
      'server_revision': server.revision,
      'state_sha256': server.snapshot()['state_sha256'],
      'authority_mode': 'server',
      'result': true,
      'replayed': false,
    });
  }

  @override
  Future<Object?> recover(String requestId) =>
      throw StateError('A known request must recover its original receipt');
  @override
  Future<void> dispose() => _changes.close();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Map<String, dynamic> data;
  setUpAll(() async => data = (await runGameDomainProbe())['projections'].first
      as Map<String, dynamic>);

  for (final code in [
    'rewarded_ad_claim_unavailable',
    'rewarded_ad_state_changed',
  ]) {
    test(
        '$code recovers after restart and unblocks play only after a fresh read',
        () async {
      final directory =
          await Directory.systemTemp.createTemp('rewarded-failure-recovery-');
      final server = _Server(data, code);
      CanonicalGameSession createSession(String nextId) => CanonicalGameSession(
          connection: _Connection(server),
          directory: directory,
          expectedAuthority: CanonicalGameAuthority.server,
          requestIdGenerator: () => nextId);
      var session = createSession(_adRequest);
      addTearDown(() async {
        session.dispose();
        await directory.delete(recursive: true);
      });

      await session.synchronize();
      final before = session.confirmedSnapshot!;
      await expectLater(
          session.execute('claim_rewarded_ad', {'claimId': _claim}),
          _failure('game_command_unavailable'));
      expect(session.canAct, isFalse);
      expect((await session.intents.pending(_owner))!.requestId, _adRequest);

      session.dispose();
      session = createSession(_nextRequest);
      server.failNextRead = true;
      await expectLater(
          session.synchronize(), _failure('game_snapshot_unavailable'));
      expect(session.canAct, isFalse);
      expect((await session.intents.pending(_owner))!.requestId, _adRequest);

      final receipt = await session.synchronize();
      expect(receipt!.failureCode, code);
      expect(receipt.replayed, isTrue);
      expect(await session.intents.pending(_owner), isNull);
      expect(session.canAct, isTrue);
      expect(session.confirmedSnapshot!.gems, before.gems);
      expect(session.confirmedSnapshot!.coins, before.coins);
      expect(session.confirmedSnapshot!.serverRevision, before.serverRevision);
      expect(server.failedRequests, {_adRequest});
      expect(server.sentAdRequests, [_adRequest, _adRequest, _adRequest]);

      expect((await session.execute('refresh', {}))!.succeeded, isTrue);
      expect(session.canAct, isTrue);
      expect(
          session.confirmedSnapshot!.serverRevision, before.serverRevision + 1);
    });
  }

  test('ad failure acknowledgement still rejects malformed or unknown receipts',
      () {
    final intent = CanonicalGameIntent(
        ownerId: _owner,
        requestId: _adRequest,
        action: 'claim_rewarded_ad',
        payload: {'claimId': _claim},
        minimumRevision: 1);
    final valid = <String, dynamic>{
      'request_id': _adRequest,
      'replayed': true,
      'error': 'rewarded_ad_state_changed',
    };
    for (final reply in [
      CanonicalGameHttpReply(503, valid),
      CanonicalGameHttpReply(422, {...valid, 'request_id': _nextRequest}),
      CanonicalGameHttpReply(422, {...valid, 'replayed': 'true'}),
      CanonicalGameHttpReply(422, {...valid, 'coins': 150}),
      CanonicalGameHttpReply(422, {...valid, 'error': 'unknown_failure'}),
    ]) {
      expect(() => CanonicalGameReceipt.parse(reply, intent),
          _failure('game_command_unavailable'));
    }
  });
}
