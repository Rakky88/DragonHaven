import 'dart:io';
import 'dart:ui' as ui;

import 'package:dragon_haven/models/moonlit_orchard.dart';
import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/models/sunwake_surf.dart';
import 'package:dragon_haven/models/trial.dart';
import 'package:dragon_haven/widgets/summer_trials.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _Harness {
  _Harness(this.tester, {this.reduced = false});
  final WidgetTester tester;
  final bool reduced;
  final root = GlobalKey();
  var now = DateTime.utc(2026, 9, 9);
  final dragon = Pet(
      id: 'controls',
      firstEgg: false,
      stage: DragonStage.hatchling,
      lineageId: 'solmanta');
  final actions = <(bool, int)>[];
  late final model = MoonlitOrchard(
      seed: 8,
      might: dragon.trainingFor(TrainingFocus.might).clamp(0, 400) / 400,
      arcana: dragon.trainingFor(TrainingFocus.arcana).clamp(0, 400) / 400,
      spirit: dragon.trainingFor(TrainingFocus.spirit).clamp(0, 400) / 400);

  Future<void> mount(TrialKind kind) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(
          fontFamily: const String.fromEnvironment('EVENT_CAPTURE_FONT').isEmpty
              ? null
              : 'ControlsCapture'),
      home: RepaintBoundary(
          key: root,
          child: MediaQuery(
            data: MediaQueryData(
                size: const Size(320, 640),
                disableAnimations: reduced,
                textScaler: TextScaler.linear(reduced ? 1.35 : 1)),
            child: Scaffold(
                body: SafeArea(
                    child: SummerTrials(
                        kind: kind,
                        dragon: dragon,
                        seed: 8,
                        running: true,
                        clock: () => now,
                        onAction: (correct,
                            {required points, required completesRound}) {
                          actions.add((correct, points));
                        }))),
          )),
    ));
    await step(20);
  }

  Future<void> step(int ms) async {
    now = now.add(Duration(milliseconds: ms));
    await tester.pump(Duration(milliseconds: ms));
  }

  Offset cell(int x, int y) =>
      tester.getCenter(find.byKey(ValueKey('orchard-cell-${y * 6 + x}')));

  Future<OrchardPlacement> place(int index, int x, int y,
      {int turns = 0}) async {
    await tester.tap(find.byKey(ValueKey('orchard-tray-$index')));
    await tester.pump();
    for (var r = 0; r < turns; r++) {
      await tester.tap(find.byKey(const Key('orchard-rotate')));
      await tester.pump();
      model.rotate(index);
    }
    final result = model.place(index, x, y)!;
    await tester.tapAt(cell(x, y));
    await tester.pump();
    return result;
  }

  Future<void> capture(String name) async {
    const directory = String.fromEnvironment('EVENT_CAPTURE_DIR');
    if (directory.isEmpty) return;
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)));
    await tester.pump();
    await tester.runAsync(() async {
      final im = await (root.currentContext!.findRenderObject()!
              as RenderRepaintBoundary)
          .toImage(pixelRatio: 2);
      final data = await im.toByteData(format: ui.ImageByteFormat.png);
      await Directory(directory).create(recursive: true);
      await File('$directory/$name.png')
          .writeAsBytes(data!.buffer.asUint8List());
      im.dispose();
    });
  }

  Future<void> close() async {
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  }
}

void main() {
  setUpAll(() async {
    const font = String.fromEnvironment('EVENT_CAPTURE_FONT');
    if (font.isNotEmpty) {
      await (FontLoader('ControlsCapture')
            ..addFont(File(font).readAsBytes().then(ByteData.sublistView)))
          .load();
    }
  });

  testWidgets(
      'surf requires grabbing dragon, caps speed, ignores second thumb and release',
      (t) async {
    final h = _Harness(t);
    await h.mount(TrialKind.sunwakeSurf);
    final dragon = find.byKey(const Key('sunwake-dragon'));
    final water = t.getRect(find.byKey(const Key('sunwake-steering')));
    final initial = t.getCenter(dragon);
    await t.tapAt(Offset(water.right - 15, water.top + 20));
    await h.step(100);
    expect((t.getCenter(dragon).dx - initial.dx).abs(), lessThan(1));

    final thumb = await t.startGesture(t.getCenter(dragon), pointer: 1);
    final start = t.getCenter(dragon).dx;
    await thumb.moveBy(const Offset(100, 0));
    await t.pump();
    expect(t.getCenter(dragon).dx, closeTo(start, .01));
    await h.step(100);
    final moved = t.getCenter(dragon).dx - start;
    expect(moved, greaterThan(20));
    expect(
        moved,
        lessThanOrEqualTo(
            water.width * SunwakeSurf.maximumSteeringSpeed * .1 + .01));
    final other =
        await t.startGesture(Offset(water.left + 40, initial.dy), pointer: 2);
    await other.moveBy(const Offset(-20, 0));
    await other.up();
    await h.step(100);
    expect(t.getCenter(dragon).dx, greaterThan(start + moved));
    await thumb.cancel();
    final released = t.getCenter(dragon).dx;
    await h.step(100);
    expect((t.getCenter(dragon).dx - released).abs(), lessThan(2));
    await h.capture('sunwake-grab-and-drag');
    await h.close();
  });

  testWidgets(
      'board hold previews every fruit, supports movement and commits on release only',
      (t) async {
    final h = _Harness(t);
    await h.mount(TrialKind.moonlitOrchard);
    final index = h.model.tray.indexWhere((p) => p!.cells.length > 1);
    final piece = h.model.tray[index]!;
    await t.tap(find.byKey(ValueKey('orchard-tray-$index')));
    await t.pump();
    final thumb = await t.startGesture(h.cell(1, 1));
    await t.pump();
    for (final (x, y) in piece.cells) {
      expect(find.byKey(ValueKey('orchard-preview-${(y + 1) * 6 + x + 1}')),
          findsOneWidget);
    }
    expect(h.actions, isEmpty);
    await h.capture('harvestmoon-full-preview');
    await thumb.moveTo(h.cell(2, 2));
    await t.pump();
    for (final (x, y) in piece.cells) {
      expect(find.byKey(ValueKey('orchard-preview-${(y + 2) * 6 + x + 2}')),
          findsOneWidget);
    }
    await thumb.up();
    await t.pump();
    expect(h.actions, hasLength(1));
    expect(find.byKey(const Key('orchard-preview-14')), findsNothing);
    for (final (x, y) in piece.cells) {
      expect(find.byKey(ValueKey('orchard-fruit-${(y + 2) * 6 + x + 2}')),
          findsOneWidget);
    }
    final cancelled = await t.startGesture(h.cell(0, 0));
    await t.pump();
    await cancelled.cancel();
    await t.pump();
    expect(h.actions, hasLength(1));
    expect(
        find.byWidgetPredicate((w) =>
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith('orchard-preview-')),
        findsNothing);
    await h.close();
  });

  testWidgets(
      'tray drag previews full shape, rejects edge, then accepts valid anchor',
      (t) async {
    final h = _Harness(t);
    await h.mount(TrialKind.moonlitOrchard);
    final index = h.model.tray.indexWhere((p) => p!.cells.length > 1);
    final piece = h.model.tray[index]!;
    var thumb = await t
        .startGesture(t.getCenter(find.byKey(ValueKey('orchard-tray-$index'))));
    await thumb.moveTo(h.cell(5, 6));
    await t.pump();
    final invalid =
        t.widget<Container>(find.byKey(const Key('orchard-preview-41')));
    expect(
        (invalid.decoration! as BoxDecoration).color, const Color(0xC2A93232));
    await h.capture('harvestmoon-invalid-preview');
    await thumb.up();
    await t.pump();
    expect(h.actions, isEmpty);
    thumb = await t
        .startGesture(t.getCenter(find.byKey(ValueKey('orchard-tray-$index'))));
    await thumb.moveTo(h.cell(0, 0));
    await t.pump();
    for (final (x, y) in piece.cells) {
      expect(
          find.byKey(ValueKey('orchard-preview-${y * 6 + x}')), findsOneWidget);
    }
    await thumb.up();
    await t.pump();
    expect(h.actions, hasLength(1));
    await h.close();
  });

  for (final reduced in [false, true]) {
    testWidgets(
        'harvest moves rows downward; input and reduced motion are respected ($reduced)',
        (t) async {
      final h = _Harness(t, reduced: reduced);
      await h.mount(TrialKind.moonlitOrchard);
      await h.place(0, 0, 1); // Fruit above the row that will be harvested.
      OrchardPlacement? clear;
      for (var turn = 0; turn < 30 && clear == null; turn++) {
        (int, int, int, int)? choice;
        var best = -1;
        for (var i = 0; i < h.model.tray.length; i++) {
          var piece = h.model.tray[i];
          if (piece == null) continue;
          for (var r = 0; r < 4; r++) {
            for (var y = 0; y < 7; y++) {
              for (var x = 0; x < 6; x++) {
                if (!h.model.fits(piece!, x, y)) continue;
                final board = [...h.model.board];
                for (final c in piece.cells) {
                  board[(y + c.$2) * 6 + x + c.$1] = piece.fruit;
                }
                var full = 0;
                for (var row = 0; row < 7; row++) {
                  if (board.skip(row * 6).take(6).every((f) => f != null)) {
                    full++;
                  }
                }
                final score = full * 10000 +
                    piece.cells
                        .fold<int>(0, (sum, c) => sum + (y + c.$2) * 100) -
                    x;
                if (score > best) {
                  best = score;
                  choice = (i, x, y, r);
                }
              }
            }
            piece = piece!.rotated();
          }
        }
        expect(choice, isNotNull);
        final c = choice!;
        final result = await h.place(c.$1, c.$2, c.$3, turns: c.$4);
        expect(result.overflow, false);
        if (result.rows > 0) clear = result;
      }
      expect(clear, isNotNull);
      final source = List.generate(42, (i) => i).firstWhere((i) =>
          clear!.boardBeforeHarvest[i] != null &&
          !clear.clearedRows.contains(i ~/ 6) &&
          clear.clearedRows.any((row) => row > i ~/ 6));
      final destination = source +
          clear!.clearedRows.where((row) => row > source ~/ 6).length * 6;
      final from =
          t.getTopLeft(find.byKey(ValueKey('orchard-cell-$source'))).dy;
      final to =
          t.getTopLeft(find.byKey(ValueKey('orchard-cell-$destination'))).dy;
      if (reduced) {
        expect(
            t.getTopLeft(find.byKey(ValueKey('orchard-fruit-$destination'))).dy,
            closeTo(to, .01));
      } else {
        expect(t.getTopLeft(find.byKey(ValueKey('orchard-fruit-$source'))).dy,
            closeTo(from, .01));
        final earned = h.actions.length;
        await t.tapAt(h.cell(0, 0));
        await t.pump();
        expect(h.actions, hasLength(earned));
        await h.step(380);
        final middle =
            t.getTopLeft(find.byKey(ValueKey('orchard-fruit-$source'))).dy;
        expect(middle, greaterThan(from));
        expect(middle, lessThan(to));
        await h.capture('harvestmoon-rows-falling');
        await h.step(300);
        expect(
            t.getTopLeft(find.byKey(ValueKey('orchard-fruit-$destination'))).dy,
            closeTo(to, .01));
      }
      await h.capture('harvestmoon-settled-${reduced ? 'reduced' : 'normal'}');
      await h.close();
    });
  }
}
