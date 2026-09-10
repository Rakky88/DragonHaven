import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dragon_haven/domain/game_command_engine.dart';
import 'package:dragon_haven/domain/game_public_projection.dart';
import 'package:dragon_haven/services/canonical_game_connection.dart';
import 'package:dragon_haven/services/canonical_game_intent.dart';
import 'package:dragon_haven/services/canonical_game_snapshot.dart';

/// No network or credentials. Evaluates real rules and projections, retaining
/// committed receipts across a deliberately lost response and client restart.
class CanonicalUiServer {
  CanonicalUiServer(this.state);
  static const owner = '11111111-1111-4111-8111-111111111111';
  Map<String, dynamic> state;
  DateTime now = DateTime.utc(2026, 9, 7, 12);
  int revision = 1;
  bool enabled = true;
  bool online = true;
  bool loseReply = false;
  Future<void>? hold;
  final receipts = <String, Map<String, dynamic>>{};
  final sent = <CanonicalGameIntent>[];
  final socialContexts = <String, Map<String, dynamic>>{};
  final socialOffers = <Map<String, dynamic>>[];
  String get hash => sha256.convert(utf8.encode(jsonEncode(state))).toString();
  Map<String, dynamic> get wire => {
        'protocol': 2,
        'owner_id': owner,
        'server_revision': revision,
        'state_sha256': hash,
        'ruleset_sha256': 'ab' * 32,
        'ruleset_revision': 1,
        'authority_mode': 'shadow',
        'mutations_enabled': enabled,
        'server_time': now.toIso8601String(),
        'data': GamePublicProjection.project(
            state: state,
            ownerId: owner,
            now: now,
            verifiedSocialClaims: socialOffers),
      };
  Future<CanonicalGameHttpReply> send(CanonicalGameIntent intent) async {
    sent.add(intent);
    if (hold != null) await hold;
    if (!online) throw const CanonicalGameException('game_command_unavailable');
    final previous = receipts[intent.requestId];
    if (previous != null) {
      return CanonicalGameHttpReply(previous.containsKey('error') ? 422 : 200,
          {...previous, 'replayed': true});
    }
    if (intent.ownerId != owner || intent.minimumRevision != revision) {
      return CanonicalGameHttpReply(422, {
        'request_id': intent.requestId,
        'replayed': false,
        'error': 'game_state_changed'
      });
    }
    final Map<String, dynamic> result;
    try {
      result = await GameCommandEngine.execute(
          state: state,
          action: intent.action,
          payload: intent.payload,
          // Real workers allocate independent entropy per request. Reusing one
          // seed here would collide with the Altar's internal operation IDs.
          secretSeed: sha256
              .convert(utf8.encode('fixture:${intent.requestId}'))
              .toString(),
          now: now,
          keeperId: owner,
          verifiedSocialContext: socialContexts[intent.action] ??
              (intent.action.startsWith('claim_') && intent.payload.length == 1
                  ? socialContexts[intent.payload.values.single]
                  : null));
    } on GameCommandException catch (error) {
      final receipt = receipts[intent.requestId] = {
        'request_id': intent.requestId,
        'error': error.code,
        'replayed': false,
      };
      return CanonicalGameHttpReply(422, receipt);
    }
    state = result['state'] as Map<String, dynamic>;
    if (const {'claim_group_reward', 'claim_pair_reward', 'claim_podium_prize'}
        .contains(intent.action)) {
      final id = intent.payload.values.single;
      socialContexts.remove(id);
      socialOffers.removeWhere((offer) => offer['id'] == id);
    }
    revision++;
    final receipt = receipts[intent.requestId] = {
      'protocol': 2,
      'owner_id': owner,
      'request_id': intent.requestId,
      'server_revision': revision,
      'state_sha256': hash,
      'authority_mode': 'shadow',
      'result': result['result'],
      'replayed': false,
    };
    if (loseReply) {
      loseReply = false;
      throw TimeoutException('synthetic lost committed receipt');
    }
    return CanonicalGameHttpReply(200, receipt);
  }
}

class CanonicalUiConnection implements CanonicalGameConnection {
  CanonicalUiConnection(this.server);
  final CanonicalUiServer server;
  @override
  String? currentOwner = CanonicalUiServer.owner;
  @override
  int sessionEpoch = 1;
  final _changes = StreamController<int>.broadcast(sync: true);
  @override
  Stream<int> get accountChanges => _changes.stream;
  void signOut() {
    currentOwner = null;
    _changes.add(++sessionEpoch);
  }

  @override
  Future<Object?> read(Map<String, dynamic> request) async {
    if (!server.online) {
      throw const CanonicalGameException('game_command_unavailable');
    }
    return server.wire;
  }

  @override
  Future<CanonicalGameHttpReply> send(CanonicalGameIntent intent) =>
      server.send(intent);
  @override
  Future<Object?> recover(String requestId) => throw UnimplementedError();
  @override
  Future<void> dispose() => _changes.close();
}
