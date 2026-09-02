import 'package:dragon_haven/screens/sprite_audit_screen.dart';
import 'package:dragon_haven/widgets/dragon_art.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> pumpAudit(WidgetTester tester) async {
  for (var frame = 0; frame < 8; frame++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('release repair review contains 87 forms in four runtime variants', () {
    expect(
        DragonArtwork.safeStandaloneForms.values
            .fold<int>(0, (count, forms) => count + forms.length),
        87);
    expect(releaseRepairAuditEntryIds(), hasLength(348));
    expect(masteryAuditEntryIds(), hasLength(88));
  });

  testWidgets('sprite audit follows the requested four-pass family order',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const SpriteAuditApp());
    await pumpAudit(tester);

    expect(find.text('Mossprout'), findsOneWidget);
    expect(find.text('1/4 · Normal silhouettes'), findsOneWidget);
    var artwork = tester.widgetList<DragonArt>(find.byType(DragonArt));
    expect(artwork, hasLength(6));
    expect(artwork.every((art) => art.silhouette && !art.prismatic), isTrue);

    await tester.tap(find.byKey(const Key('audit-next')));
    await pumpAudit(tester);
    expect(find.text('2/4 · Normal colors'), findsOneWidget);
    artwork = tester.widgetList<DragonArt>(find.byType(DragonArt));
    expect(artwork.every((art) => !art.silhouette && !art.prismatic), isTrue);

    await tester.tap(find.byKey(const Key('audit-next')));
    await pumpAudit(tester);
    expect(find.text('3/4 · Spectral silhouettes'), findsOneWidget);
    artwork = tester.widgetList<DragonArt>(find.byType(DragonArt));
    expect(artwork.every((art) => art.silhouette && art.prismatic), isTrue);

    await tester.tap(find.byKey(const Key('audit-next')));
    await pumpAudit(tester);
    expect(find.text('4/4 · Spectral colors'), findsOneWidget);
    artwork = tester.widgetList<DragonArt>(find.byType(DragonArt));
    expect(artwork.every((art) => !art.silhouette && art.prismatic), isTrue);
  });

  testWidgets('flagged forms persist and can be reviewed on their own',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const SpriteAuditApp());
    await pumpAudit(tester);

    await tester.tap(find.text('Hatchling'));
    await pumpAudit(tester);
    expect(find.byKey(const Key('audit-inspection-art')), findsOneWidget);
    await tester.tap(find.byKey(const Key('audit-needs-fix')));
    await pumpAudit(tester);

    expect(find.text('SELECTED FOR FIX'), findsOneWidget);
    await tester.tap(find.byKey(const Key('audit-marked-only')));
    await pumpAudit(tester);
    expect(find.byType(DragonArt), findsOneWidget);
    expect(find.textContaining('Review page 1 of 1'), findsOneWidget);
  });
}
