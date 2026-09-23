import 'dart:convert';
import 'dart:io';
import 'package:dragon_haven/account_startup_app.dart';
import 'package:dragon_haven/config/online_config.dart';
import 'package:dragon_haven/dragonhaven_app.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:dragon_haven/providers/online_account_provider.dart';
import 'package:dragon_haven/screens/account_save_choice_screen.dart';
import 'package:dragon_haven/screens/privacy_screen.dart';
import 'package:dragon_haven/services/account_legacy_game_storage.dart';
import 'package:dragon_haven/services/canonical_game_transport.dart';
import 'package:dragon_haven/services/storage_service.dart';
import 'package:dragon_haven/server_dragonhaven_app.dart';
import 'package:dragon_haven/services/canonical_game_intent.dart';
import 'support/canonical_ui_server.dart';
import 'package:provider/provider.dart';
import 'package:dragon_haven/services/canonical_game_session.dart';
import 'package:dragon_haven/services/canonical_game_snapshot.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const a = '11111111-1111-4111-8111-111111111111';
const b = '22222222-2222-4222-8222-222222222222';
const config = OnlineConfig(
    url: CanonicalGameTransport.stagingUrl,
    publishableKey: 'synthetic-public-key',
    environment: OnlineEnvironment.staging);
Map<String, dynamic> _authSession(String owner) {
  final now = DateTime.now().toUtc();
  String segment(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  final token = '${segment({'alg': 'HS256', 'typ': 'JWT'})}.${segment({
        'sub': owner,
        'aud': 'authenticated',
        'exp': now.millisecondsSinceEpoch ~/ 1000 + 3600,
      })}.c3ludGhldGlj';
  return {
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
  };
}

Future<void> _signIn(SupabaseClient client, String owner) async {
  await client.auth.recoverSession(jsonEncode(_authSession(owner)));
  await Future<void>.delayed(Duration.zero);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('nl.dragonhaven.app/network'),
            (_) async => null);
  });
  TestWidgetsFlutterBinding.ensureInitialized();
  Future<void> until(WidgetTester tester, bool Function() done) async {
    final deadline = Stopwatch()..start();
    while (!done() && deadline.elapsed < const Duration(seconds: 10)) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 20));
    }
    expect(done(), true);
  }

  testWidgets(
      'fresh install asks for age and privacy before signup; never creates a guest save',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final calls = <String>[];
    final auth = SupabaseClient(config.url, config.publishableKey,
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((request) async {
      calls.add(request.url.path);
      return http.Response('{}', 500, request: request);
    }));
    final directory = (await tester
        .runAsync(() => Directory.systemTemp.createTemp('dh-first-start-')))!;
    await tester.pumpWidget(AccountStartupApp(
        config: config,
        auth: auth,
        directory: directory,
        connectionFactory: () => CanonicalGameTransport.staging(auth, config,
            httpClientFactory: () => MockClient((_) async =>
                throw StateError('No authenticated probe before login')))));
    await until(tester,
        () => find.byKey(const Key('startup-email')).evaluate().isNotEmpty);
    expect(find.byType(DragonHavenApp), findsNothing);
    expect(find.byKey(const Key('account-name-field')), findsNothing);
    expect(await StorageService.load(), isNull);
    expect(calls, isEmpty);
    Future<void> reach(String key) async {
      await tester.scrollUntilVisible(find.byKey(Key(key)), 200,
          scrollable: find.byType(Scrollable).first);
      await tester.ensureVisible(find.byKey(Key(key)));
      await tester.pumpAndSettle();
    }

    await reach('startup-authenticate');
    expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('startup-authenticate')))
            .onPressed,
        isNull);
    await reach('signup-age');
    await tester.tap(find.byKey(const Key('signup-age')));
    await tester.pump();
    expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('startup-authenticate')))
            .onPressed,
        isNull);
    await reach('signup-notice');
    await tester.tap(find.byKey(const Key('signup-notice')));
    await tester.pump();
    expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('startup-authenticate')))
            .onPressed,
        isNotNull);
    expect(calls, isEmpty);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    var disposed = false;
    final closing = auth.dispose().then((_) => disposed = true);
    await until(tester, () => disposed);
    await closing;
    await tester.runAsync(() => directory.delete(recursive: true));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'two empty installations enter the server shell without importing a local game',
      (tester) async {
    final game = HouseholdProvider(persistenceEnabled: false)
      ..onboardingComplete = true
      ..accountName = 'Restored Keeper';
    final state = game.exportState();
    state['pet']['coins'] = 12993;
    final server = CanonicalUiServer(state);
    game.dispose();
    final calls = <String>[];
    http.Response reply(http.Request request, Object? body,
            [int status = 200]) =>
        http.Response(jsonEncode(body), status,
            request: request, headers: {'content-type': 'application/json'});
    final auth = SupabaseClient(config.url, config.publishableKey,
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((request) async {
      calls.add(request.url.path);
      if (request.url.path
          .endsWith('get_my_privacy_acknowledgement_for_version')) {
        expect(jsonDecode(request.body), {'p_version': '2026-09-23'});
        return reply(request, true);
      }
      if (request.url.path.endsWith('ensure_my_online_account')) {
        return reply(request, null);
      }
      if (request.url.path.endsWith('get_online_snapshot')) {
        return reply(request, {
          'profile': {
            'user_id': a,
            'display_name': 'Restored Keeper',
            'keeper_code': 'DH-SYNTH',
            'inventory_imported': true
          },
          'group_status': {},
        });
      }
      throw StateError('Unexpected legacy/social write: ${request.url.path}');
    }));
    CanonicalGameTransport transport() =>
        CanonicalGameTransport.staging(auth, config,
            httpClientFactory: () => MockClient((request) async {
                  if (request.url.path
                      .endsWith('get_my_server_gameplay_status')) {
                    return reply(request, {
                      'owner_id': a,
                      'phase': 'active',
                      'migration_enabled': true,
                      'source_revision': null,
                      'server_revision': server.revision,
                    });
                  }
                  final input =
                      jsonDecode(request.body) as Map<String, dynamic>;
                  calls.add('edge:${input['action']}');
                  if (input['action'] == 'read_state') {
                    final wire = {...server.wire, 'authority_mode': 'server'};
                    try {
                      CanonicalGameSnapshot.parse(wire,
                          expectedOwner: a,
                          expectedAuthority: CanonicalGameAuthority.server);
                    } catch (e) {
                      calls.add('parser:$e');
                      rethrow;
                    }
                    return reply(request, wire);
                  }
                  final result = await server.send(CanonicalGameIntent(
                      ownerId: a,
                      requestId: input['requestId'],
                      action: input['action'],
                      payload: input['payload'],
                      minimumRevision: input['expectedRevision']));
                  return reply(
                      request,
                      {
                        ...result.body as Map<String, dynamic>,
                        'authority_mode': 'server'
                      },
                      result.status);
                }));
    for (var phone = 0; phone < 2; phone++) {
      SharedPreferences.setMockInitialValues({});
      final directory = (await tester.runAsync(
          () => Directory.systemTemp.createTemp('dh-server-startup-')))!;
      await tester.runAsync(() => _signIn(auth, a));
      await tester.runAsync(() => tester.pumpWidget(AccountStartupApp(
          config: config,
          auth: auth,
          directory: directory,
          connectionFactory: transport)));
      await until(tester, () {
        if (find.text('Try again').evaluate().isNotEmpty) {
          throw StateError(
              'Startup failed: $calls; ${tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).toList()}');
        }
        return find.byType(ServerDragonHavenApp).evaluate().isNotEmpty;
      });
      expect(find.byType(DragonHavenApp), findsNothing);
      expect(find.byType(AccountSaveChoiceScreen), findsNothing);
      expect(find.byKey(const Key('account-name-field')), findsNothing);
      expect(await StorageService.load(), isNull);
      expect(await AccountLegacyGameStorage.open(a), isNull);
      expect(server.state['pet']['coins'], 12993);
      final activeSession = tester
          .element(find.byType(ServerDragonHavenApp))
          .read<CanonicalGameSession>();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      for (var i = 0; i < 12; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)));
        await tester.pump(const Duration(milliseconds: 20));
      }
      var closed = false;
      final close = activeSession.close().then((_) => closed = true);
      await until(tester, () => closed);
      await close;
      await tester.runAsync(() => directory.delete(recursive: true));
    }
    expect(
        calls.where(
            (c) => c.contains('cloud_game_save') || c.contains('import')),
        isEmpty);
    var disposed = false;
    final closing = auth.dispose().then((_) => disposed = true);
    await until(tester, () => disposed);
    await closing;
  });

  testWidgets(
      'signing out and signing back into the same account reopens the server game',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final game = HouseholdProvider(persistenceEnabled: false)
      ..onboardingComplete = true
      ..accountName = 'Returning Keeper';
    final server = CanonicalUiServer(game.exportState());
    game.dispose();
    final calls = <String>[];
    http.Response reply(http.Request request, Object? body,
            [int status = 200]) =>
        http.Response(jsonEncode(body), status,
            request: request, headers: {'content-type': 'application/json'});
    final auth = SupabaseClient(config.url, config.publishableKey,
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((request) async {
      calls.add('${request.method} ${request.url.path}');
      if (request.url.path == '/auth/v1/logout') {
        return reply(request, const <String, dynamic>{});
      }
      if (request.url.path == '/auth/v1/token') {
        return reply(request, _authSession(a));
      }
      if (request.url.path
          .endsWith('get_my_privacy_acknowledgement_for_version')) {
        expect(jsonDecode(request.body), {'p_version': '2026-09-23'});
        return reply(request, true);
      }
      if (request.url.path.endsWith('ensure_my_online_account')) {
        return reply(request, null);
      }
      if (request.url.path.endsWith('get_online_snapshot')) {
        return reply(request, {
          'profile': {
            'user_id': a,
            'display_name': 'Returning Keeper',
            'keeper_code': 'DH-RETURN',
            'inventory_imported': true
          },
          'group_status': {},
        });
      }
      throw StateError('Unexpected account request: ${request.url}');
    }));
    CanonicalGameTransport transport() =>
        CanonicalGameTransport.staging(auth, config,
            httpClientFactory: () => MockClient((request) async {
                  if (request.url.path
                      .endsWith('get_my_server_gameplay_status')) {
                    return reply(request, {
                      'owner_id': a,
                      'phase': 'active',
                      'migration_enabled': true,
                      'source_revision': null,
                      'server_revision': server.revision,
                    });
                  }
                  final input =
                      jsonDecode(request.body) as Map<String, dynamic>;
                  calls.add('edge:${input['action']}');
                  if (input['action'] == 'read_state') {
                    return reply(
                        request, {...server.wire, 'authority_mode': 'server'});
                  }
                  final result = await server.send(CanonicalGameIntent(
                      ownerId: a,
                      requestId: input['requestId'],
                      action: input['action'],
                      payload: input['payload'],
                      minimumRevision: input['expectedRevision']));
                  return reply(
                      request,
                      {
                        ...result.body as Map<String, dynamic>,
                        'authority_mode': 'server'
                      },
                      result.status);
                }));
    final directory = (await tester
        .runAsync(() => Directory.systemTemp.createTemp('dh-reauth-')))!;
    await tester.runAsync(() => _signIn(auth, a));
    await tester.pumpWidget(AccountStartupApp(
        config: config,
        auth: auth,
        directory: directory,
        connectionFactory: transport));
    await until(
        tester, () => find.byType(ServerDragonHavenApp).evaluate().isNotEmpty);
    final account = tester
        .element(find.byType(ServerDragonHavenApp))
        .read<OnlineAccountProvider>();
    expect(await tester.runAsync(account.signOut), isTrue);
    await until(tester,
        () => find.byKey(const Key('startup-email')).evaluate().isNotEmpty);
    await tester.scrollUntilVisible(
        find.byKey(const Key('startup-authenticate')), 200,
        scrollable: find.byType(Scrollable).first);
    await tester
        .tap(find.widgetWithText(TextButton, 'Already have an account?'));
    await tester.pump();
    await tester.enterText(
        find.byKey(const Key('startup-email')), 'synthetic@example.invalid');
    await tester.enterText(
        find.byKey(const Key('startup-password')), 'Secret1!');
    await tester.tap(find.byKey(const Key('startup-authenticate')));
    await until(
        tester,
        () =>
            find.byType(ServerDragonHavenApp).evaluate().isNotEmpty ||
            find.text('Try again').evaluate().isNotEmpty);
    expect(find.byType(ServerDragonHavenApp), findsOneWidget,
        reason:
            'The same confirmed account must reopen its server game after reauthentication. Calls: $calls. Visible text: ${tester.widgetList<Text>(find.byType(Text)).map((text) => text.data).whereType<String>().toList()}');
    expect(find.text('Try again'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    var disposed = false;
    final closing = auth.dispose().then((_) => disposed = true);
    await until(tester, () => disposed);
    await closing;
    await tester.runAsync(() => directory.delete(recursive: true));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'normal account root resolves authority before comparing saves and retires a stale choice',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final game = HouseholdProvider(persistenceEnabled: false);
    final local = game.exportState()..['accountName'] = 'Latest device';
    game.dispose();
    await StorageService.save(local);
    final calls = <String>[];
    final acknowledged = <String>{};
    late final SupabaseClient auth;
    auth = SupabaseClient(config.url, config.publishableKey,
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((request) async {
      calls.add(request.url.path);
      if (request.url.path
          .endsWith('get_my_privacy_acknowledgement_for_version')) {
        expect(jsonDecode(request.body), {'p_version': '2026-09-23'});
        return http.Response(
            jsonEncode(acknowledged.contains(auth.auth.currentUser!.id)), 200,
            request: request, headers: {'content-type': 'application/json'});
      }
      if (request.url.path.endsWith('acknowledge_my_privacy_notice')) {
        expect(jsonDecode(request.body),
            {'p_version': '2026-09-23', 'p_age_16_confirmed': true});
        acknowledged.add(auth.auth.currentUser!.id);
        return http.Response('true', 200,
            request: request, headers: {'content-type': 'application/json'});
      }
      if (request.url.path.endsWith('get_cloud_game_save')) {
        return http.Response(
            jsonEncode([
              {
                'revision': 7,
                'state': {...local, 'accountName': 'Cloud copy'},
                'updated_at': DateTime.now().toIso8601String(),
                'device_id': 'synthetic'
              }
            ]),
            200,
            request: request,
            headers: {'content-type': 'application/json'});
      }
      return http.Response('{}', 200,
          request: request, headers: {'content-type': 'application/json'});
    }));
    final directory = (await tester
        .runAsync(() => Directory.systemTemp.createTemp('dh-startup-')))!;
    await tester.runAsync(() => _signIn(auth, a));
    final original = (await SharedPreferences.getInstance())
        .getString(StorageService.currentKey);
    await tester.pumpWidget(AccountStartupApp(
        config: config,
        auth: auth,
        directory: directory,
        connectionFactory: () => CanonicalGameTransport.staging(auth, config,
            httpClientFactory: () => MockClient((request) async {
                  calls.add('authority');
                  return http.Response(
                      jsonEncode({
                        'owner_id': auth.auth.currentUser!.id,
                        'phase': 'legacy',
                        'migration_enabled': false,
                        'source_revision': null,
                        'server_revision': null
                      }),
                      200,
                      request: request,
                      headers: {'content-type': 'application/json'});
                }))));
    await until(tester, () => find.byType(PrivacyScreen).evaluate().isNotEmpty);
    expect(find.byType(DragonHavenApp), findsNothing);
    expect(calls.any((c) => c.endsWith('get_cloud_game_save')), false);
    await tester.runAsync(tester
        .widget<PrivacyScreen>(find.byType(PrivacyScreen))
        .onAcknowledge!);
    await until(tester, () {
      if (find.text('Try again').evaluate().isNotEmpty) {
        throw StateError('Startup failure after calls: $calls');
      }
      return find.byType(AccountSaveChoiceScreen).evaluate().isNotEmpty;
    });
    expect(calls.first, 'authority');
    expect(find.byType(DragonHavenApp), findsNothing);
    expect(await AccountLegacyGameStorage.open(a), isNull);
    final old = tester
        .widget<AccountSaveChoiceScreen>(find.byType(AccountSaveChoiceScreen));
    expect(old.review.owner, a);
    await tester.runAsync(() => _signIn(auth, b));
    await until(tester, () => find.byType(PrivacyScreen).evaluate().isNotEmpty);
    expect(acknowledged, {a});
    await tester.runAsync(tester
        .widget<PrivacyScreen>(find.byType(PrivacyScreen))
        .onAcknowledge!);
    await until(
        tester,
        () =>
            find.byType(AccountSaveChoiceScreen).evaluate().isNotEmpty &&
            tester
                    .widget<AccountSaveChoiceScreen>(
                        find.byType(AccountSaveChoiceScreen))
                    .review
                    .owner ==
                b);
    expect(await AccountLegacyGameStorage.open(a), isNull);
    expect(await AccountLegacyGameStorage.open(b), isNull);
    old.onChoose(AccountSaveChoice.cloud);
    await tester.pump();
    expect(
        tester
            .widget<AccountSaveChoiceScreen>(
                find.byType(AccountSaveChoiceScreen))
            .review
            .owner,
        b);
    expect(await AccountLegacyGameStorage.open(b), isNull);
    final selected = tester
        .widget<AccountSaveChoiceScreen>(find.byType(AccountSaveChoiceScreen));
    selected.onChoose(AccountSaveChoice.local);
    await until(
        tester, () => find.byType(DragonHavenApp).evaluate().isNotEmpty);
    expect(await AccountLegacyGameStorage.open(a), isNull);
    expect(
        (await (await AccountLegacyGameStorage.open(b))!
            .load())!['accountName'],
        'Latest device');
    expect(
        (await SharedPreferences.getInstance())
            .getString(StorageService.currentKey),
        original);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(seconds: 1));
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)));
    }
    var disposed = false;
    final closing = auth.dispose().then((_) => disposed = true);
    await until(tester, () => disposed);
    await closing;
    await tester.runAsync(() => directory.delete(recursive: true));
  });
}
