import 'package:dragon_haven/models/dragon_lineage.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:dragon_haven/screens/draconomicon_screen.dart';
import 'package:dragon_haven/widgets/dragon_art.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

const _forms = <({String formKey, String stageKey, String path})>[
  (formKey: 'hatchling', stageKey: 'spark', path: 'might'),
  (formKey: 'wyrmling', stageKey: 'nestDragon', path: 'might'),
  (formKey: 'ascended:might', stageKey: 'homeGuardian', path: 'might'),
  (formKey: 'ascended:arcana', stageKey: 'homeGuardian', path: 'arcana'),
  (formKey: 'ascended:spirit', stageKey: 'homeGuardian', path: 'spirit'),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'every discovered and silhouette Draconomicon form is contained in three visual passes',
      (tester) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(() => tester.binding.platformDispatcher
        .clearAccessibilityFeaturesTestValue());
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (var pass = 1; pass <= 3; pass++) {
      for (final discovered in [false, true]) {
        final game = discovered
            ? HouseholdProvider.createShowcase()
            : HouseholdProvider(initialize: true);
        if (!discovered) {
          game.discoveredForms.clear();
          game.prismaticForms.clear();
        }
        for (var index = 0; index < dragonLineages.length; index++) {
          final lineage = dragonLineages[index];
          await tester.pumpWidget(ChangeNotifierProvider.value(
            value: game,
            child: MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: DragonLineageEntry(
                    lineage: lineage,
                    number: index + 1,
                    collection: game.discoveredForms,
                    spectral: false,
                  ),
                ),
              ),
            ),
          ));
          await tester.pump();
          final previewFinder =
              find.byKey(Key('draconomicon-preview-normal-${lineage.id}'));
          await tester.tap(previewFinder);
          await tester.pump(const Duration(milliseconds: 260));

          final preview = tester.widget<DragonArt>(previewFinder);
          expect(preview.silhouette, isNot(discovered),
              reason: 'pass $pass ${lineage.id} preview state');

          for (final form in _forms) {
            final tile = find.byKey(
                Key('draconomicon-form-normal-${lineage.id}-${form.formKey}'));
            final art = find.byKey(
                Key('draconomicon-art-normal-${lineage.id}-${form.formKey}'));
            expect(tile, findsOneWidget,
                reason: 'pass $pass ${lineage.id} ${form.formKey} tile');
            expect(art, findsOneWidget,
                reason: 'pass $pass ${lineage.id} ${form.formKey} art');
            final artWidget = tester.widget<DragonArt>(art);
            expect(artWidget.silhouette, isNot(discovered),
                reason: 'pass $pass ${lineage.id} ${form.formKey} state');
            expect(artWidget.fit, BoxFit.contain,
                reason: 'pass $pass ${lineage.id} ${form.formKey} fit');
            final filters = find.descendant(
              of: art,
              matching: find.byType(ColorFiltered),
            );
            final usesPreRenderedSilhouette = !discovered &&
                lineage.id == 'seraphscale' &&
                form.formKey == 'hatchling';
            if (!discovered && !usesPreRenderedSilhouette) {
              expect(filters, findsOneWidget,
                  reason:
                      'pass $pass ${lineage.id} ${form.formKey} silhouette filter');
              final filter = tester.widget<ColorFiltered>(filters);
              expect(
                filter.colorFilter,
                const ColorFilter.mode(Color(0xFF2D2941), BlendMode.srcIn),
                reason:
                    'pass $pass ${lineage.id} ${form.formKey} silhouette color',
              );
            } else {
              expect(filters, findsNothing,
                  reason:
                      'pass $pass ${lineage.id} ${form.formKey} direct rendering');
            }
            final tileRect = tester.getRect(tile);
            final artRect = tester.getRect(art);
            expect(artRect.width, closeTo(artRect.height, .01),
                reason: 'pass $pass ${lineage.id} ${form.formKey} ratio');
            expect(tileRect.contains(artRect.topLeft), isTrue,
                reason: 'pass $pass ${lineage.id} ${form.formKey} top-left');
            expect(tileRect.contains(artRect.bottomRight), isTrue,
                reason:
                    'pass $pass ${lineage.id} ${form.formKey} bottom-right');
          }
          expect(tester.takeException(), isNull,
              reason: 'pass $pass ${lineage.id} layout');
        }
      }
    }
  }, timeout: const Timeout(Duration(minutes: 12)));

  testWidgets('discovered forms open a contained artwork modal',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final game = HouseholdProvider.createShowcase();
    final lineage = dragonLineages.first;

    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: game,
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DragonLineageEntry(
              lineage: lineage,
              number: 1,
              collection: game.discoveredForms,
              spectral: false,
            ),
          ),
        ),
      ),
    ));
    await tester
        .tap(find.byKey(Key('draconomicon-preview-normal-${lineage.id}')));
    await tester.pump(const Duration(milliseconds: 350));

    final zoom = find
        .byKey(Key('draconomicon-zoom-normal-${lineage.id}-ascended:arcana'));
    expect(zoom, findsOneWidget);
    await tester.ensureVisible(zoom);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(zoom);
    await tester.pump(const Duration(milliseconds: 350));

    final modal = find
        .byKey(Key('draconomicon-modal-normal-${lineage.id}-ascended:arcana'));
    final modalArt = find.byKey(
        Key('draconomicon-modal-art-normal-${lineage.id}-ascended:arcana'));
    expect(modal, findsOneWidget);
    expect(modalArt, findsOneWidget);
    expect(tester.widget<DragonArt>(modalArt).fit, BoxFit.contain);
    final modalRect = tester.getRect(modal);
    final artRect = tester.getRect(modalArt);
    expect(modalRect.contains(artRect.topLeft), isTrue);
    expect(modalRect.contains(artRect.bottomRight), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('undiscovered silhouettes cannot open the artwork modal',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final game = HouseholdProvider(initialize: true)
      ..discoveredForms.clear()
      ..prismaticForms.clear();
    final lineage = dragonLineages.first;
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: game,
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DragonLineageEntry(
              lineage: lineage,
              number: 1,
              collection: game.discoveredForms,
              spectral: false,
            ),
          ),
        ),
      ),
    ));
    await tester
        .tap(find.byKey(Key('draconomicon-preview-normal-${lineage.id}')));
    await tester.pump(const Duration(milliseconds: 350));
    final zoom =
        find.byKey(Key('draconomicon-zoom-normal-${lineage.id}-hatchling'));
    await tester.ensureVisible(zoom);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(zoom);
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byType(Dialog), findsNothing);
  });
}
