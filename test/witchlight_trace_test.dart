import 'package:dragon_haven/widgets/witchlight_trial_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('random paths vary while preserving length and arena padding', () {
    for (final size in [const Size(260, 240), const Size(280, 330)]) {
      double length(List<Offset> p) =>
          List.generate(p.length - 1, (i) => (p[i + 1] - p[i]).distance)
              .fold(0.0, (a, b) => a + b);
      final expected = length(WitchlightTracePath.points(size));
      final shapes = <String>{};
      for (var seed = 0; seed < 100; seed++) {
        final p = WitchlightTracePath.points(size, seed: seed);
        expect(length(p), closeTo(expected, .000001));
        expect(
            p.every((v) =>
                v.dx >= size.width * .08 &&
                v.dx <= size.width * .92 &&
                v.dy >= size.height * .08 &&
                v.dy <= size.height * .92),
            isTrue);
        shapes.add(p.toString());
      }
      expect(shapes, hasLength(100));
    }
  });
  Future<List<Offset>> mount(WidgetTester tester, List<bool> results,
      {bool mirrored = false, bool enabled = true}) async {
    await tester.pumpWidget(MaterialApp(
      home: Center(
          child: SizedBox(
        width: 260,
        height: 240,
        child: WitchlightTracePath(
            enabled: enabled,
            mirrored: mirrored,
            tolerance: 0,
            onResult: results.add),
      )),
    ));
    final origin =
        tester.getTopLeft(find.byKey(const Key('witchlight-trace-surface')));
    return WitchlightTracePath.points(const Size(260, 240), mirrored: mirrored)
        .map((p) => p + origin)
        .toList();
  }

  for (final mirrored in [false, true]) {
    testWidgets('continuous tracing completes the path (mirrored: $mirrored)',
        (tester) async {
      final results = <bool>[];
      final points = await mount(tester, results, mirrored: mirrored);
      final gesture = await tester.startGesture(points.first);
      for (final p in points.skip(1)) {
        await gesture.moveTo(p);
      }
      await gesture.up();
      expect(results, [true]);
    });
  }

  testWidgets('crossing the border fails once', (tester) async {
    final results = <bool>[];
    final points = await mount(tester, results);
    final gesture = await tester.startGesture(points.first);
    await gesture.moveBy(const Offset(-25, 0));
    await gesture.moveTo(points.last);
    await gesture.up();
    expect(results, [false]);
  });

  testWidgets('jumping straight to the lantern cannot skip bends',
      (tester) async {
    final results = <bool>[];
    final points = await mount(tester, results);
    final gesture = await tester.startGesture(points.first);
    await gesture.moveTo(points.last);
    await gesture.up();
    expect(results, [false]);
  });

  testWidgets('lifting or cancelling early fails', (tester) async {
    for (final cancel in [false, true]) {
      await tester.pumpWidget(const SizedBox.shrink());
      final results = <bool>[];
      final points = await mount(tester, results);
      final gesture = await tester.startGesture(points.first);
      await gesture.moveTo(points[1]);
      if (cancel) {
        await gesture.cancel();
      } else {
        await gesture.up();
      }
      expect(results, [false]);
    }
  });

  testWidgets('destination taps and locked input cannot finish',
      (tester) async {
    final results = <bool>[];
    final points = await mount(tester, results);
    await tester.tapAt(points.last);
    expect(results, isEmpty);
    await mount(tester, results, enabled: false);
    final gesture = await tester.startGesture(points.first);
    for (final p in points.skip(1)) {
      await gesture.moveTo(p);
    }
    await gesture.up();
    expect(results, isEmpty);
  });
}
