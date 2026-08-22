import 'package:dragon_haven/models/achievement.dart';
import 'package:dragon_haven/widgets/achievement_reveal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('nl.dragonhaven.app/audio'),
      (_) async => true,
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('nl.dragonhaven.app/audio'),
      null,
    );
  });

  testWidgets('achievement badge spins in and leaves after a tap',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showAchievementReveal(
              context,
              achievementCatalog.first,
            ),
            child: const Text('Show'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle();

    final reveal = find.byKey(
      const Key('achievement-reveal-hello_little_one'),
    );
    expect(reveal, findsOneWidget);
    expect(find.text('ACHIEVEMENT UNLOCKED'), findsOneWidget);
    expect(find.text('Hello, Little One!'), findsOneWidget);

    await tester.tap(reveal);
    await tester.pumpAndSettle();
    expect(reveal, findsNothing);
  });
}
