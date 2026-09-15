import 'dart:math';

import 'package:dragon_haven/l10n/app_strings.dart';
import 'package:dragon_haven/models/game_presentation.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:dragon_haven/theme/app_theme.dart';
import 'package:dragon_haven/widgets/trade_reveal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final reduced in [false, true]) {
    testWidgets(
        'completed trade reveal supports compact layout and reduced motion $reduced',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final game = HouseholdProvider(random: Random(62));
      final presentation = GamePresentation(
        id: 'trade-demo',
        type: GamePresentationType.trade,
        createdAt: DateTime(2026, 8, 26),
        sortAt: DateTime(2026, 8, 26),
        payload: const {
          'sentKind': 'chest',
          'sentKey': 'gold',
          'sentData': <String, dynamic>{},
          'receivedKind': 'relic',
          'receivedKey': 'moralPrism',
          'receivedData': <String, dynamic>{},
        },
      );
      await tester.pumpWidget(MaterialApp(
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
            child: child!),
        theme: buildAppTheme(),
        locale: const Locale('en'),
        supportedLocales: AppStrings.supportedLanguages.keys.map(Locale.new),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () => showTradeReveal(context, game, presentation),
              child: const Text('Reveal'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Reveal'));
      await tester.pump();
      for (var i = 0;
          i < 100 &&
              find.byKey(const Key('trade-complete-reveal')).evaluate().isEmpty;
          i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)));
        await tester.pump(const Duration(milliseconds: 20));
      }
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.byKey(const Key('trade-complete-reveal')), findsOneWidget);
      expect(find.text('TRADE COMPLETE!'), findsOneWidget);
      expect(find.text('Gold Chest'), findsOneWidget);
      expect(find.text('Moral Prism'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('trade-reveal-continue')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('trade-complete-reveal')), findsNothing);
      game.dispose();
    });
  }
}
