import 'dart:async';
import 'dart:convert';

import 'package:dragon_haven/app_info.dart';
import 'package:dragon_haven/config/online_config.dart';
import 'package:dragon_haven/services/canonical_game_intent.dart';
import 'package:dragon_haven/services/canonical_game_snapshot.dart';
import 'package:dragon_haven/services/canonical_game_transport.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _owner = '11111111-1111-4111-8111-111111111111';
const _other = '22222222-2222-4222-8222-222222222222';
const _config = OnlineConfig(
    url: CanonicalGameTransport.stagingUrl,
    publishableKey: 'synthetic-public-key',
    environment: OnlineEnvironment.staging);
const _read = {'protocol': 2, 'clientBuild': 10069, 'action': 'read_state'};
Matcher _error(String code) =>
    throwsA(isA<CanonicalGameException>().having((e) => e.code, 'code', code));

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

http.StreamedResponse _response(Object body, {int status = 200}) =>
    http.StreamedResponse(Stream.value(utf8.encode(jsonEncode(body))), status,
        headers: {'content-type': 'application/json'});

class _TrackingClient extends http.BaseClient {
  _TrackingClient(this.handler, {this.onClose});
  final Future<http.StreamedResponse> Function(http.BaseRequest) handler;
  final void Function()? onClose;
  bool closed = false;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      handler(request);
  @override
  void close() {
    closed = true;
    onClose?.call();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SupabaseClient auth;
  CanonicalGameTransport? transport;
  setUp(() {
    auth = SupabaseClient(_config.url, _config.publishableKey,
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((_) async => http.Response('{}', 200)));
  });
  tearDown(() async {
    await transport?.dispose();
    transport = null;
    await auth.dispose();
  });

  test('production endpoint requires explicit production configuration',
      () async {
    expect(() => CanonicalGameTransport.production(auth, _config),
        _error('game_production_required'));
    await _signIn(auth, _owner);
    final client = _TrackingClient((request) async {
      expect(request.url.origin, OnlineConfig.productionUrl);
      expect(request.followRedirects, isFalse);
      return _response({'synthetic': true});
    });
    transport = CanonicalGameTransport.production(
        auth,
        const OnlineConfig(
            url: OnlineConfig.productionUrl,
            publishableKey: 'synthetic-production-public-key'),
        httpClientFactory: () => client);
    await transport!.read(_read);
    expect(client.closed, isTrue);
  });

  test(
      'migration sends only a durable ID/revision and requires a live owner receipt',
      () async {
    await _signIn(auth, _owner);
    const migrationId = '33333333-3333-4333-8333-333333333333';
    var mode = 'server';
    final requests = <Map<String, dynamic>>[];
    transport = CanonicalGameTransport.staging(auth, _config,
        httpClientFactory: () => _TrackingClient((request) async {
              requests.add(jsonDecode((request as http.Request).body)
                  as Map<String, dynamic>);
              return _response({
                'protocol': 2,
                'owner_id': _owner,
                'request_id': migrationId,
                'authority_mode': mode,
                'phase': 'active',
                'server_revision': 7,
                'replayed': true
              });
            }));
    expect(
        await transport!
            .migrateAccount(requestId: migrationId, sourceRevision: 12),
        7);
    expect(requests.single, {
      'protocol': 2,
      'clientBuild': AppInfo.buildNumber,
      'action': 'migrate_account',
      'requestId': migrationId,
      'sourceRevision': 12
    });
    mode = 'shadow';
    await expectLater(
        transport!.migrateAccount(requestId: migrationId, sourceRevision: 12),
        _error('game_migration_unavailable'));
    expect(requests[1], requests[0]);
  });

  test(
      'uses the confirmed Auth session, fixed staging endpoint and no redirect forwarding',
      () async {
    await _signIn(auth, _owner);
    final client = _TrackingClient((request) async {
      expect(request.url.toString(),
          '${_config.url}/functions/v1/execute-game-command');
      expect(request.followRedirects, isFalse);
      expect(request.headers['authorization'],
          'Bearer ${auth.auth.currentSession!.accessToken}');
      expect(request.headers['apikey'], _config.publishableKey);
      expect(jsonDecode((request as http.Request).body), _read);
      return _response({'synthetic': true});
    });
    transport = CanonicalGameTransport.staging(auth, _config,
        httpClientFactory: () => client);
    expect(await transport!.read(_read), {'synthetic': true});
    expect(client.closed, isTrue);
  });

  test('production, wrong staging host and logged-out requests never open HTTP',
      () async {
    expect(
        () => CanonicalGameTransport.staging(
            auth,
            const OnlineConfig(
                url: OnlineConfig.productionUrl,
                publishableKey: 'synthetic',
                environment: OnlineEnvironment.production)),
        _error('game_staging_required'));
    expect(
        () => CanonicalGameTransport.staging(
            auth,
            const OnlineConfig(
                url: 'https://unknown.invalid',
                publishableKey: 'synthetic',
                environment: OnlineEnvironment.staging)),
        _error('game_staging_required'));
    transport = CanonicalGameTransport.staging(auth, _config,
        httpClientFactory: () => throw StateError('HTTP must not open'));
    await expectLater(transport!.read(_read), _error('game_login_required'));
  });

  test(
      'wrong intent owner and injected read arguments are rejected before HTTP',
      () async {
    await _signIn(auth, _owner);
    transport = CanonicalGameTransport.staging(auth, _config,
        httpClientFactory: () => throw StateError('HTTP must not open'));
    await expectLater(
        transport!.send(CanonicalGameIntent(
            ownerId: _other,
            requestId: _other,
            action: 'refresh',
            payload: {},
            minimumRevision: 1)),
        _error('game_account_changed'));
    await expectLater(transport!.read({..._read, 'state': {}}),
        _error('game_request_invalid'));
  });

  test(
      'ABA account switches invalidate a delayed response and close its client',
      () async {
    await _signIn(auth, _owner);
    final started = Completer<void>();
    final response = Completer<http.StreamedResponse>();
    final client = _TrackingClient((_) {
      started.complete();
      return response.future;
    });
    transport = CanonicalGameTransport.staging(auth, _config,
        httpClientFactory: () => client);
    final before = transport!.sessionEpoch;
    final future = transport!.read(_read);
    final rejected = expectLater(future, _error('game_account_changed'));
    await started.future;
    await _signIn(auth, _other);
    await _signIn(auth, _owner);
    expect(transport!.sessionEpoch, greaterThan(before));
    response.complete(_response({'synthetic': true}));
    await rejected;
    expect(client.closed, isTrue);
  });

  test('a stalled streamed body is time bounded and its HTTP client is closed',
      () async {
    await _signIn(auth, _owner);
    final stream = StreamController<List<int>>();
    final client = _TrackingClient(
        (_) async => http.StreamedResponse(stream.stream, 200),
        onClose: () => unawaited(stream.close()));
    transport = CanonicalGameTransport.staging(auth, _config,
        httpClientFactory: () => client,
        timeout: const Duration(milliseconds: 20));
    await expectLater(
        transport!.read(_read), _error('game_command_unavailable'));
    expect(client.closed, isTrue);
  });

  test(
      'oversized bodies, redirects and malformed JSON are private fixed failures',
      () async {
    await _signIn(auth, _owner);
    for (final mode in ['large', 'redirect', 'malformed']) {
      final client = _TrackingClient((_) async => switch (mode) {
            'large' => http.StreamedResponse(const Stream.empty(), 200,
                contentLength: 10 * 1024 * 1024),
            'redirect' => http.StreamedResponse(const Stream.empty(), 302,
                headers: {'location': 'https://unknown.invalid'}),
            _ => http.StreamedResponse(
                Stream.value(utf8.encode('private response details')), 200),
          });
      transport = CanonicalGameTransport.staging(auth, _config,
          httpClientFactory: () => client);
      await expectLater(
          transport!.read(_read), _error('game_command_unavailable'));
      expect(client.closed, isTrue);
      await transport!.dispose();
      transport = null;
    }
  });

  test('durable command refusals retain HTTP status and request identity',
      () async {
    await _signIn(auth, _owner);
    final body = {
      'error': 'egg_tagged',
      'request_id': _other,
      'replayed': true
    };
    transport = CanonicalGameTransport.staging(auth, _config,
        httpClientFactory: () =>
            _TrackingClient((_) async => _response(body, status: 422)));
    final result = await transport!.send(CanonicalGameIntent(
        ownerId: _owner,
        requestId: _other,
        action: 'return_egg',
        payload: {'eggId': 'legacy-egg', 'sinisterConfirmed': false},
        minimumRevision: 4));
    expect(result.status, 422);
    expect(result.body, body);
  });

  test('recovery uses the same authenticated transport and fixed request UUID',
      () async {
    await _signIn(auth, _owner);
    final proof = {
      'protocol': 2,
      'owner_id': _owner,
      'request_id': _other,
      'authority_mode': 'shadow',
      'barrier_revision': 8,
      'cancelled_commands': 1,
      'replayed': true
    };
    var requests = 0;
    transport = CanonicalGameTransport.staging(auth, _config,
        httpClientFactory: () => _TrackingClient((request) async {
              requests++;
              expect(jsonDecode((request as http.Request).body), {
                'protocol': 2,
                'clientBuild': AppInfo.buildNumber,
                'action': 'recover_commands',
                'requestId': _other,
              });
              expect(request.headers['authorization'], startsWith('Bearer '));
              expect(request.followRedirects, isFalse);
              return _response(proof);
            }));
    expect(await transport!.recover(_other), proof);
    await expectLater(
        transport!.recover('invalid'),
        throwsA(isA<CanonicalGameException>()
            .having((e) => e.code, 'code', 'game_request_invalid')));
    expect(requests, 1);
  });
}
