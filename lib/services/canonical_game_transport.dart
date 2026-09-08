import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/online_config.dart';
import '../app_info.dart';
import 'canonical_game_intent.dart';
import 'canonical_game_connection.dart';
import 'canonical_game_snapshot.dart';

/// Authenticated transport for the detached staging candidate. No service key,
/// raw save, caller-owned clock or secret seed is ever present in this client.
/// Each request owns its HTTP client so a timeout can actually close the socket.
class CanonicalGameTransport implements CanonicalGameConnection {
  CanonicalGameTransport.staging(this.authClient, OnlineConfig config,
      {http.Client Function()? httpClientFactory,
      this.timeout = const Duration(seconds: 10)})
      : _clientFactory = httpClientFactory ?? (() => http.Client()),
        _publishableKey = config.publishableKey {
    if (config.environment != OnlineEnvironment.staging ||
        config.url != stagingUrl ||
        !config.isConfigured) {
      throw const CanonicalGameException('game_staging_required');
    }
    _lastOwner = currentOwner;
    _auth = authClient.auth.onAuthStateChange.listen((event) {
      final owner = currentOwner;
      if (owner != _lastOwner ||
          event.event == AuthChangeEvent.signedIn ||
          event.event == AuthChangeEvent.signedOut) {
        _lastOwner = owner;
        _epoch++;
        if (!_changes.isClosed) _changes.add(_epoch);
      }
    }, onError: (Object _, StackTrace __) {
      _epoch++;
      if (!_changes.isClosed) _changes.add(_epoch);
    });
  }

  static const stagingUrl = 'https://vtmjkhzalalozpfnbvsd.supabase.co';
  final SupabaseClient authClient;
  final http.Client Function() _clientFactory;
  final String _publishableKey;
  final Duration timeout;
  final _changes = StreamController<int>.broadcast();
  late final StreamSubscription<AuthState> _auth;
  String? _lastOwner;
  int _epoch = 0;
  bool _disposed = false;
  Future<void>? _refresh;
  final _activeClients = <http.Client>{};

  @override
  String? get currentOwner => _disposed ||
          authClient.auth.currentSession == null ||
          authClient.auth.currentUser?.emailConfirmedAt == null
      ? null
      : authClient.auth.currentUser?.id;
  @override
  int get sessionEpoch => _epoch;
  @override
  Stream<int> get accountChanges => _changes.stream;

  @override
  Future<Object?> read(Map<String, dynamic> request) async {
    if (request.length != 3 ||
        request['protocol'] != 2 ||
        request['action'] != 'read_state' ||
        request['clientBuild'] is! int) {
      throw const CanonicalGameException('game_request_invalid');
    }
    final reply = await _invoke(request);
    if (reply.status != 200) {
      throw const CanonicalGameException('game_snapshot_unavailable');
    }
    return reply.body;
  }

  @override
  Future<CanonicalGameHttpReply> send(CanonicalGameIntent intent,
          {int clientBuild = AppInfo.buildNumber}) =>
      _invoke(intent.toRequest(clientBuild), expectedOwner: intent.ownerId);

  @override
  Future<Object?> recover(String requestId,
      {int clientBuild = AppInfo.buildNumber}) async {
    if (!CanonicalGameIntent.validOwner(requestId)) {
      throw const CanonicalGameException('game_request_invalid');
    }
    final reply = await _invoke({
      'protocol': 2,
      'clientBuild': clientBuild,
      'action': 'recover_commands',
      'requestId': requestId
    });
    if (reply.status != 200) {
      throw const CanonicalGameException('game_recovery_unavailable');
    }
    return reply.body;
  }

  Future<CanonicalGameHttpReply> _invoke(Map<String, dynamic> request,
      {String? expectedOwner}) async {
    final owner = currentOwner;
    final epoch = _epoch;
    var finished = false;
    if (owner == null) {
      throw const CanonicalGameException('game_login_required');
    }
    if (expectedOwner != null && expectedOwner != owner) {
      throw const CanonicalGameException('game_account_changed');
    }
    void requireSession() {
      if (finished) {
        throw const CanonicalGameException('game_command_unavailable');
      }
      if (currentOwner != owner || _epoch != epoch) {
        throw const CanonicalGameException('game_account_changed');
      }
    }

    http.Client? client;
    try {
      Future<CanonicalGameHttpReply> perform() async {
        requireSession();
        if (authClient.auth.currentSession!.isExpired) {
          _refresh ??= authClient.auth
              .refreshSession()
              .then<void>((_) {})
              .whenComplete(() => _refresh = null);
          await _refresh;
          requireSession();
        }
        final session = authClient.auth.currentSession;
        if (session == null || session.isExpired) {
          throw const CanonicalGameException('game_login_required');
        }
        final bytes = utf8.encode(jsonEncode(request));
        if (bytes.length > 8192) {
          throw const CanonicalGameException('game_request_invalid');
        }
        client = _clientFactory();
        _activeClients.add(client!);
        final outgoing = http.Request(
            'POST', Uri.parse('$stagingUrl/functions/v1/execute-game-command'))
          ..followRedirects = false
          ..headers.addAll({
            'authorization': 'Bearer ${session.accessToken}',
            'apikey': _publishableKey,
            'content-type': 'application/json',
            'accept': 'application/json'
          })
          ..bodyBytes = bytes;
        requireSession();
        final response = await client!.send(outgoing);
        requireSession();
        if (response.statusCode >= 300 && response.statusCode < 400 ||
            (response.contentLength ?? 0) > 9 * 1024 * 1024) {
          throw const CanonicalGameException('game_command_unavailable');
        }
        final body = BytesBuilder(copy: false);
        await for (final part in response.stream) {
          requireSession();
          if (body.length + part.length > 9 * 1024 * 1024) {
            throw const CanonicalGameException('game_command_unavailable');
          }
          body.add(part);
        }
        requireSession();
        if (response.statusCode == 401 || response.statusCode == 403) {
          throw const CanonicalGameException('game_login_required');
        }
        final decoded = jsonDecode(utf8.decode(body.takeBytes()));
        if (decoded is! Map<String, dynamic>) {
          throw const CanonicalGameException('game_command_unavailable');
        }
        return CanonicalGameHttpReply(response.statusCode, decoded);
      }

      return await perform().timeout(timeout);
    } on CanonicalGameException {
      rethrow;
    } on Object {
      // Provider errors can contain request details. Surface only fixed codes.
      throw const CanonicalGameException('game_command_unavailable');
    } finally {
      finished = true;
      client?.close();
      _activeClients.remove(client);
    }
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    _epoch++;
    for (final client in _activeClients.toList()) {
      client.close();
    }
    _activeClients.clear();
    await _auth.cancel();
    await _changes.close();
  }
}
