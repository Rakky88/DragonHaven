import 'dart:async';
import 'dart:convert';

import 'package:dragon_haven/models/egg_altar.dart';
import 'package:dragon_haven/models/social.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:dragon_haven/services/egg_altar_repository.dart';
import 'package:dragon_haven/services/social_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _Social extends Fake implements SocialRepository {
  String owner = 'keeper-a';
  Future<void> Function()? ensure;
  int inventories = 0;
  @override
  String get currentUserId => owner;
  @override
  bool get isSignedIn => true;
  @override
  Future<void> ensureAccount() async {
    await ensure?.call();
  }

  @override
  Future<void> synchronizeTradeInventory(
      OnlineInventorySnapshot snapshot) async {
    inventories++;
  }
}

Future<void> _signIn(SupabaseClient client, String owner) async {
  final now = DateTime.now().toUtc();
  String segment(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  final token = '${segment({'alg': 'HS256', 'typ': 'JWT'})}.${segment({
        'sub': owner,
        'aud': 'authenticated',
        'exp': now.millisecondsSinceEpoch ~/ 1000 + 3600,
      })}.c3ludGhldGlj';
  await client.auth.recoverSession(jsonEncode({
    'access_token': token,
    'refresh_token': 'synthetic-refresh',
    'token_type': 'bearer',
    'expires_in': 3600,
    'user': {
      'id': owner,
      'aud': 'authenticated',
      'role': 'authenticated',
      'email': 'synthetic@example.invalid',
      'email_confirmed_at': now.toIso8601String(),
      'created_at': now.toIso8601String(),
      'app_metadata': {},
      'user_metadata': {}
    },
  }));
  await Future<void>.delayed(Duration.zero);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final unavailable = throwsA(isA<EggAltarException>()
      .having((error) => error.code, 'code', 'altar_unavailable'));

  test('retirement waits for an admitted RPC and refuses further requests',
      () async {
    final sent = Completer<void>();
    final response = Completer<http.Response>();
    var requests = 0;
    final client = SupabaseClient('https://example.test', 'test-key',
        httpClient: MockClient((request) async {
      requests++;
      sent.complete();
      final result = await response.future;
      return http.Response(result.body, result.statusCode,
          headers: result.headers, request: request);
    }));
    final social = _Social();
    final game = HouseholdProvider(persistenceEnabled: false);
    final repository = EggAltarRepository(client, social, game);
    final command = repository.command('request', 'tag', {});
    await sent.future;
    var retired = false;
    final stopping =
        repository.stopLegacyOperations().then((_) => retired = true);
    await Future<void>.delayed(Duration.zero);
    expect(retired, isFalse);
    await expectLater(repository.command('other', 'tag', {}), unavailable);
    response.complete(http.Response('{}', 200,
        headers: {'content-type': 'application/json'}));
    await command;
    await stopping;
    expect(requests, 1);
    expect(social.inventories, 1);
    game.dispose();
    await client.dispose();
  });

  test('changing account during preparation cannot publish the old inventory',
      () async {
    final entered = Completer<void>();
    final prepared = Completer<void>();
    var requests = 0;
    final client = SupabaseClient('https://example.test', 'test-key',
        httpClient: MockClient((request) async {
      requests++;
      return http.Response('{}', 200, request: request);
    }));
    final social = _Social()
      ..ensure = () {
        entered.complete();
        return prepared.future;
      };
    final game = HouseholdProvider(persistenceEnabled: false);
    final repository = EggAltarRepository(client, social, game);
    final refused =
        expectLater(repository.command('request', 'tag', {}), unavailable);
    await entered.future;
    social.owner = 'keeper-b';
    prepared.complete();
    await refused;
    expect(social.inventories, 0);
    expect(requests, 0);
    await repository.stopLegacyOperations();
    game.dispose();
    await client.dispose();
  });

  test('an old refresh cannot apply an Altar wallet to the next account',
      () async {
    final sent = Completer<void>();
    final response = Completer<http.Response>();
    final client = SupabaseClient('https://example.test', 'test-key',
        httpClient: MockClient((request) async {
      sent.complete();
      final result = await response.future;
      return http.Response(result.body, result.statusCode,
          headers: result.headers, request: request);
    }));
    final social = _Social();
    final game = HouseholdProvider(persistenceEnabled: false)
      ..altarCurrentUserId = () => social.owner;
    final repository = EggAltarRepository(client, social, game);
    final refused = expectLater(repository.refresh(), unavailable);
    await sent.future;
    social.owner = 'keeper-b';
    response.complete(http.Response(
        jsonEncode(EggAltarState(
                ownerId: 'keeper-a',
                revision: 5,
                wallet: const WeaveWallet(999, 0, 0))
            .toJson()),
        200,
        headers: {'content-type': 'application/json'}));
    await refused;
    expect(game.eggAltar.wallet.fragments, 0);
    expect(game.eggAltar.ownerId, isNull);
    await repository.stopLegacyOperations();
    game.dispose();
    await client.dispose();
  });
  test('retirement still fences a session that changes away and back',
      () async {
    final sent = Completer<void>();
    final response = Completer<void>();
    final client = SupabaseClient('https://example.test', 'test-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((request) async {
      sent.complete();
      await response.future;
      return http.Response('{}', 200,
          headers: {'content-type': 'application/json'}, request: request);
    }));
    final social = _Social();
    await _signIn(client, social.owner);
    final game = HouseholdProvider(persistenceEnabled: false);
    final repository = EggAltarRepository(client, social, game);
    final refused =
        expectLater(repository.command('request', 'tag', {}), unavailable);
    await sent.future;
    final epoch = repository.sessionEpoch;
    final stopping = repository.stopLegacyOperations();
    social.owner = 'keeper-b';
    await _signIn(client, social.owner);
    social.owner = 'keeper-a';
    await _signIn(client, social.owner);
    expect(repository.sessionEpoch, greaterThan(epoch));
    response.complete();
    await refused;
    await stopping;
    game.dispose();
    await client.dispose();
  });
}
