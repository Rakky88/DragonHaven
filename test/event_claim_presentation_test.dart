import 'package:dragon_haven/models/event_progress.dart';
import 'package:dragon_haven/models/social.dart';
import 'package:dragon_haven/widgets/event_partner_control.dart';
import 'package:dragon_haven/widgets/event_point_flight.dart';
import 'package:dragon_haven/widgets/event_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('points fly after a claim; reduced motion skips particles',
      (tester) async {
    for (final reduced in [false, true]) {
      final progress = EventProgress(
          eventId: 'halloween_witchlight',
          key: 'flight',
          startsAt: DateTime.utc(2026, 10, 25),
          endsAt: DateTime.utc(2026, 11, 2),
          chestId: 'witchlight_chest_v1',
          target: 8000);
      await tester.pumpWidget(MaterialApp(
          home: MediaQuery(
              data: MediaQueryData(disableAnimations: reduced),
              child: Scaffold(
                  body: StatefulBuilder(
                      builder: (context, update) => Column(children: [
                            EventProgressBar(
                                key: ValueKey(reduced), progress: progress),
                            const Spacer(),
                            FilledButton(
                                onPressed: () =>
                                    EventPointFlight.claim(context, () async {
                                      update(() => progress.points += 5);
                                    }),
                                child: const Text('Collect adventure')),
                          ]))))));
      await tester.pump();
      await tester.tap(find.text('Collect adventure'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(progress.points, 5);
      expect(find.text('+5'), reduced ? findsNothing : findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('+5'), findsNothing);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
      'friend picker lists existing names and selects profile without code input',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    KeeperProfile friend(String name) => KeeperProfile(
        userId: name,
        keeperCode: 'DH-$name',
        displayName: name,
        title: 'title_001',
        portraitKey: 'portrait_001',
        discoveredDragonCount: 0,
        inventoryImported: false);
    KeeperProfile? selected;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Builder(
                builder: (context) => FilledButton(
                    onPressed: () async {
                      selected = await showModalBottomSheet<KeeperProfile>(
                          context: context,
                          builder: (_) => EventFriendPicker(
                              friends: [friend('Zoe'), friend('Anna')]));
                    },
                    child: const Text('Friends'))))));
    await tester.tap(find.text('Friends'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    expect(find.text('DH-Anna'), findsNothing);
    expect(tester.getTopLeft(find.text('Anna')).dy,
        lessThan(tester.getTopLeft(find.text('Zoe')).dy));
    await tester.tap(find.text('Anna'));
    await tester.pumpAndSettle();
    expect(selected?.userId, 'Anna');
    expect(tester.takeException(), isNull);
  });
}
