import 'dart:convert';
import 'dart:io';
import 'package:dragon_haven/account_startup_app.dart';
import 'package:dragon_haven/config/online_config.dart';
import 'package:dragon_haven/dragonhaven_app.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:dragon_haven/screens/account_save_choice_screen.dart';
import 'package:dragon_haven/screens/privacy_screen.dart';
import 'package:dragon_haven/services/account_legacy_game_storage.dart';
import 'package:dragon_haven/services/canonical_game_transport.dart';
import 'package:dragon_haven/services/storage_service.dart';
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
      if (request.url.path.endsWith('get_my_privacy_acknowledgement')) {
        return http.Response(
            jsonEncode(acknowledged.contains(auth.auth.currentUser!.id)), 200,
            request: request, headers: {'content-type': 'application/json'});
      }
      if (request.url.path.endsWith('acknowledge_my_privacy_notice')) {
        expect(jsonDecode(request.body),
            {'p_version': '2026-09-20', 'p_age_16_confirmed': true});
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
