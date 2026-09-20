import 'dart:convert';

import 'package:dragon_haven/services/supabase_social_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _ownerA = '11111111-1111-4111-8111-111111111111';
const _ownerB = '22222222-2222-4222-8222-222222222222';

Map<String, dynamic> _session(String owner, String nonce) {
  final now = DateTime.now().toUtc();
  String segment(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  final token = '${segment({'alg': 'HS256', 'typ': 'JWT'})}.${segment({
        'sub': owner,
        'aud': 'authenticated',
        'exp': now.millisecondsSinceEpoch ~/ 1000 + 3600,
        'nonce': nonce,
      })}.c3ludGhldGlj';
  return {
    'access_token': token,
    'refresh_token': 'synthetic-refresh-$nonce',
    'token_type': 'bearer',
    'expires_in': 3600,
    'user': {
      'id': owner,
      'aud': 'authenticated',
      'role': 'authenticated',
      'email': 'synthetic@example.invalid',
      'email_confirmed_at': now.toIso8601String(),
      'created_at': now.toIso8601String(),
      'app_metadata': <String, dynamic>{},
      'user_metadata': <String, dynamic>{},
    },
  };
}

void main() {
  for (final switchOwner in [false, true]) {
    test(
        switchOwner
            ? 'deleting A never signs out B when the account changes during deletion'
            : 'password reauthentication can delete its owner after the old game lease retires',
        () async {
      var leaseIsCurrent = true;
      var deletionCalls = 0;
      final requestPaths = <String>[];
      String? deletionAuthorization;
      bool? deletionLease;
      final reauthenticated = _session(_ownerA, 'reauthenticated');
      late final SupabaseClient client;
      client = SupabaseClient(
          'https://synthetic.example.invalid', 'synthetic-key',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
          httpClient: MockClient((request) async {
        requestPaths.add(request.url.path);
        if (request.url.path == '/auth/v1/token') {
          // The auth event retires the old root in the actual app.
          leaseIsCurrent = false;
          return http.Response(jsonEncode(reauthenticated), 200);
        }
        if (request.url.path == '/rest/v1/rpc/delete_my_account') {
          deletionCalls++;
          deletionLease = leaseIsCurrent;
          deletionAuthorization = request.headers.entries
              .where((entry) => entry.key.toLowerCase() == 'authorization')
              .firstOrNull
              ?.value;
          if (switchOwner) {
            await client.auth
                .recoverSession(jsonEncode(_session(_ownerB, 'other-owner')));
          }
          return http.Response('', 204, request: request);
        }
        if (request.url.path == '/auth/v1/logout') {
          return http.Response('', 204);
        }
        fail('Unexpected request: ${request.url.path}');
      }));
      await client.auth
          .recoverSession(jsonEncode(_session(_ownerA, 'original')));
      final repository = SupabaseSocialRepository(client,
          sessionIsCurrent: () => leaseIsCurrent);
      try {
        try {
          await repository.deleteMyAccount('synthetic-password');
        } catch (error) {
          fail('Deletion failed: $error; paths: $requestPaths');
        }
        expect(deletionCalls, 1);
        expect(deletionLease, false);
        expect(
            deletionAuthorization, 'Bearer ${reauthenticated['access_token']}');
        expect(client.auth.currentUser?.id, switchOwner ? _ownerB : null);
      } finally {
        repository.dispose();
        await client.dispose();
      }
    });
  }
}
