import 'dart:io';
import 'dart:ui' as ui;
import 'package:dragon_haven/models/social.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:dragon_haven/screens/account_save_choice_screen.dart';
import 'package:dragon_haven/services/account_legacy_game_storage.dart';
import 'package:dragon_haven/services/social_repository.dart';
import 'package:dragon_haven/services/storage_service.dart';
import 'package:dragon_haven/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const owner = '11111111-1111-4111-8111-111111111111';

class Repository extends Fake implements SocialRepository {
  Repository(this.remote);
  final CloudGameSave remote;
  @override
  bool get isSignedIn => true;
  @override
  String get currentUserId => owner;
  @override
  Future<CloudGameSave?> loadCloudGameSave() async => remote;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    const font = String.fromEnvironment('STARTUP_REVIEW_FONT');
    if (font.isNotEmpty) {
      await (FontLoader('Roboto')
            ..addFont(File(font).readAsBytes().then(ByteData.sublistView)))
          .load();
      await (FontLoader('Ahem')
            ..addFont(File(font).readAsBytes().then(ByteData.sublistView)))
          .load();
    }
    const icons = String.fromEnvironment('STARTUP_REVIEW_ICON_FONT');
    if (icons.isNotEmpty) {
      await (FontLoader('MaterialIcons')
            ..addFont(File(icons).readAsBytes().then(ByteData.sublistView)))
          .load();
    }
  });
  for (final width in [320.0, 360.0]) {
    testWidgets('source comparison at $width keeps cloud restoration explicit',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = Size(width, 850);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final game = HouseholdProvider(persistenceEnabled: false);
      final local = game.exportState()..['accountName'] = 'My Haven';
      (local['pet'] as Map)
        ..['coins'] = 12000
        ..['gems'] = 950;
      game.dispose();
      await StorageService.save(local);
      final cloud = {
        ...local,
        'pet': {...local['pet'] as Map, 'coins': 500, 'gems': 50}
      };
      final repository = Repository(CloudGameSave(
          revision: 7,
          state: cloud,
          updatedAt: DateTime.utc(2026, 9, 12),
          deviceId: 'synthetic'));
      final review = await AccountLegacyGameStorage.reviewSources(
          repository: repository,
          owner: owner,
          currentOwner: () => owner,
          sessionEpoch: () => 1);
      final chosen = <AccountSaveChoice>[];
      final boundary = GlobalKey();
      final theme = buildAppTheme();
      await tester.pumpWidget(MaterialApp(
          theme: theme.copyWith(
              filledButtonTheme: FilledButtonThemeData(
                  style: theme.filledButtonTheme.style!.copyWith(
                      textStyle: const WidgetStatePropertyAll(TextStyle(
                          fontFamily: 'Roboto', fontWeight: FontWeight.w800)))),
              textTheme: theme.textTheme.apply(fontFamily: 'Roboto'),
              primaryTextTheme:
                  theme.primaryTextTheme.apply(fontFamily: 'Roboto')),
          locale: const Locale('nl'),
          supportedLocales: const [Locale('en'), Locale('nl')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: MediaQuery(
              data: MediaQueryData(
                  size: Size(width, 850),
                  textScaler: TextScaler.linear(width == 320 ? 1.3 : 1)),
              child: RepaintBoundary(
                  key: boundary,
                  child: AccountSaveChoiceScreen(
                      review: review,
                      onChoose: chosen.add,
                      onSignOut: () {})))));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      const output = String.fromEnvironment('STARTUP_REVIEW_OUTPUT');
      if (output.isNotEmpty) {
        final render = boundary.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
        final image =
            await tester.runAsync(() => render.toImage(pixelRatio: 2));
        final bytes = await tester
            .runAsync(() => image!.toByteData(format: ui.ImageByteFormat.png));
        await tester.runAsync(() => File('$output-${width.toInt()}.png')
            .writeAsBytes(bytes!.buffer.asUint8List()));
        image!.dispose();
      }
      await tester.scrollUntilVisible(find.byKey(const Key('choose-cloud-save')),
          200, scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('choose-cloud-save')));
      await tester.pumpAndSettle();
      expect(chosen, isEmpty);
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.descendant(
          of: find.byType(AlertDialog), matching: find.byType(FilledButton)));
      await tester.pumpAndSettle();
      expect(chosen, [AccountSaveChoice.cloud]);
      expect(await AccountLegacyGameStorage.open(owner), isNull);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
