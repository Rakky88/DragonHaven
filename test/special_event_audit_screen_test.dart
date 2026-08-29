import 'package:dragon_haven/screens/special_event_audit_screen.dart';
import 'package:dragon_haven/widgets/dragon_art.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Special Event audit exposes every generated event asset',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const SpecialEventAuditApp());
    for (var frame = 0; frame < 10; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('Complete dragon family'), findsOneWidget);
    expect(find.byType(DragonArt), findsNWidgets(6));
    expect(find.text('Hatchling'), findsOneWidget);
    expect(find.text('Mastery Ascension'), findsOneWidget);

    await tester.drag(
      find.byKey(const Key('special-event-audit-scroll')),
      const Offset(0, -1600),
    );
    for (var frame = 0; frame < 6; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Special Chest'), findsOneWidget);
    expect(find.text('Closed'), findsOneWidget);
    expect(find.text('Opened'), findsOneWidget);
    expect(find.text('Winner, Winner, Chicken Dinner'), findsOneWidget);
  });
}
