import 'dart:io';

import 'package:image/image.dart' as image;
import 'package:dragon_haven/screens/event_dragon_sprite_review_screen.dart';
import 'package:dragon_haven/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('review selection resolves event or family IDs and uses shipped art',
      () {
    final families = selectEventDragonReviewFamilies('solmanta, harvestmoon');
    expect(families.map((f) => f.id), ['solmanta', 'ciderhorn']);
    expect(families.first.asset('might'),
        'assets/images/dragons/solmanta_might.png');
    expect(selectEventDragonReviewFamilies('christmas').single.asset('arcana'),
        'assets/images/dragons/hollyfrost_arcana_safe.webp');
    expect(
        () => selectEventDragonReviewFamilies('missing'), throwsArgumentError);
  });

  test('all twelve review sprites retain real alpha and complete edge pixels',
      () {
    for (final family
        in selectEventDragonReviewFamilies('sunwake,harvestmoon')) {
      for (final form in [
        'hatchling',
        'wyrmling',
        'might',
        'arcana',
        'spirit',
        'mastery'
      ]) {
        final path = family.asset(form);
        final decoded = image.decodePng(File(path).readAsBytesSync())!;
        expect(decoded.numChannels, 4, reason: path);
        for (var x = 0; x < decoded.width; x++) {
          expect(decoded.getPixel(x, 0).a, lessThanOrEqualTo(4), reason: path);
          expect(
              decoded.getPixel(x, decoded.height - 1).a, lessThanOrEqualTo(4),
              reason: path);
        }
        for (var y = 0; y < decoded.height; y++) {
          expect(decoded.getPixel(0, y).a, lessThanOrEqualTo(4), reason: path);
          expect(decoded.getPixel(decoded.width - 1, y).a, lessThanOrEqualTo(4),
              reason: path);
        }
      }
    }
  });

  testWidgets('new families remain inspectable at 320dp and large type',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(640, 1280);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        theme: buildAppTheme(),
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.35),
                disableAnimations: true),
            child: child!),
        home: EventDragonSpriteReviewScreen(
            families: selectEventDragonReviewFamilies('sunwake,harvestmoon'))));
    await tester.pumpAndSettle();
    expect(find.text('Solmanta'), findsOneWidget);
    await tester.tap(find.byKey(const Key('event-review-solmanta-hatchling')));
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('event-review-next')));
    await tester.pumpAndSettle();
    expect(find.text('Ciderhorn'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sprite approval and notes survive a review restart',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(720, 1280);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final families = selectEventDragonReviewFamilies('christmas,new_year');
    Widget app() => MaterialApp(
        theme: buildAppTheme(),
        home: EventDragonSpriteReviewScreen(families: families));
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester
        .tap(find.byKey(const Key('event-review-hollyfrost-hatchling')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Looks good'));
    await tester.pumpAndSettle();
    expect(find.text('APPROVED'), findsOneWidget);
    await tester.tap(find.byKey(const Key('event-review-hollyfrost-wyrmling')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('event-review-note')), 'Check wing edge');
    await tester.tap(find.byKey(const Key('event-review-save')));
    await tester.pumpAndSettle();
    expect(find.text('NOTE SAVED'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.text('APPROVED'), findsOneWidget);
    expect(find.text('NOTE SAVED'), findsOneWidget);
    await tester.tap(find.byKey(const Key('event-review-hollyfrost-wyrmling')));
    await tester.pumpAndSettle();
    expect(find.text('Check wing edge'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
