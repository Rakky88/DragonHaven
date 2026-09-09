import 'dart:io';
import 'dart:math';

import 'package:dragon_haven/dragonhaven_app.dart';
import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/models/social.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:dragon_haven/providers/online_account_provider.dart';
import 'package:dragon_haven/services/social_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpHaven(
    WidgetTester tester, {
    required Size size,
  }) async {
    await tester.binding.setSurfaceSize(size);
    final game = HouseholdProvider(
      random: Random(906),
      persistenceEnabled: false,
    )
      ..accountName = 'Tablet Keeper'
      ..onboardingComplete = true;
    game.pet
      ..stage = DragonStage.hatchling
      ..name = 'Ember';
    final online = OnlineAccountProvider(
      repository: const DisabledSocialRepository(),
      inventorySnapshot: () => OnlineInventorySnapshot.fromGame(game),
    );
    await online.initialize();
    addTearDown(online.dispose);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: game),
          ChangeNotifierProvider.value(value: online),
        ],
        child: const DragonHavenApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 450));
  }

  testWidgets(
      'opening the Android notification shade does not mark music backgrounded',
      (tester) async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('nl.dragonhaven.app/audio'),
      (call) async {
        calls.add(call);
        return true;
      },
    );
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
              const MethodChannel('nl.dragonhaven.app/audio'), null);
    });
    await pumpHaven(tester, size: const Size(430, 900));
    calls.clear();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();

    expect(
      calls.where((call) =>
          call.method == 'setAppForeground' &&
          (call.arguments as Map<Object?, Object?>)['foreground'] == false),
      isEmpty,
    );

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(
      calls.where((call) =>
          call.method == 'setAppForeground' &&
          (call.arguments as Map<Object?, Object?>)['foreground'] == false),
      isEmpty,
    );
  });

  for (final entry in <(String, Size)>[
    ('portrait', const Size(800, 1280)),
    ('landscape', const Size(1280, 800)),
  ]) {
    testWidgets('main navigation renders on an Android tablet in ${entry.$1}',
        (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await pumpHaven(tester, size: entry.$2);

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('DragonHaven'), findsOneWidget);
      expect(tester.takeException(), isNull);

      for (final destination in ['Friends', 'Adventure', 'Inventory', 'Shop']) {
        await tester.tap(find.text(destination).last);
        await tester.pump(const Duration(milliseconds: 350));
        expect(tester.takeException(), isNull,
            reason: '$destination must remain usable in ${entry.$1}');
      }
    });
  }

  test('native background gain stays fixed and interruptions pause playback',
      () {
    final bridge = File(
      'android/app/src/main/kotlin/nl/dragonhaven/app/MainActivity.kt',
    ).readAsStringSync();

    expect(bridge, contains('setVolume(MUSIC_VOLUME, MUSIC_VOLUME)'));
    expect(bridge, contains('.setWillPauseWhenDucked(true)'));
    expect(bridge, isNot(contains('fadeMusic(')));
    expect(bridge, isNot(contains('DUCKED_VOLUME')));
    expect(bridge, isNot(contains('LoudnessEnhancer')));
    expect(bridge, isNot(contains('MUSIC_GAIN_MILLIBELS')));
  });
}
