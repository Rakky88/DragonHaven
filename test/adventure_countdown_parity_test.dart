import 'package:dragon_haven/screens/adventure_hub_screen.dart';
import 'package:dragon_haven/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final width in [360.0, 320.0]) {
    testWidgets(
        'historical card and detail countdown tick locally at width $width',
        (tester) async {
      await tester.binding.setSurfaceSize(Size(width, 820));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final now = DateTime.utc(2026, 9, 21, 12);
      await tester.pumpWidget(MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
              body: MediaQuery(
                  data: MediaQueryData(
                      size: Size(width, 820),
                      textScaler: TextScaler.linear(width == 320 ? 1.35 : 1)),
                  child: Column(children: [
                    Row(children: [
                      const SizedBox(width: 110),
                      Expanded(
                          child: RestoredAdventureCountdown(
                              key: const Key('card'),
                              endsAt: now.add(const Duration(seconds: 45)),
                              confirmedNow: now))
                    ]),
                    RestoredAdventureCountdown(
                        key: const Key('detail'),
                        detail: true,
                        endsAt: now.add(const Duration(seconds: 45)),
                        confirmedNow: now),
                    RestoredAdventureCountdown(
                        key: const Key('completed'),
                        ready: true,
                        endsAt: now.subtract(const Duration(seconds: 1)),
                        confirmedNow: now),
                  ])))));
      String label(String key) => tester
          .widget<Text>(find
              .descendant(of: find.byKey(Key(key)), matching: find.byType(Text))
              .last)
          .data!;
      final initialCard = label('card');
      final initialDetail = label('detail');
      expect(initialCard, initialDetail);
      expect(find.text('Return in'), findsOneWidget);
      expect(label('completed'), 'Ready to return');
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 1150)));
      await tester.pump(const Duration(seconds: 1));
      expect(label('card'), isNot(initialCard));
      expect(label('detail'), isNot(initialDetail));
      expect(label('completed'), 'Ready to return');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
