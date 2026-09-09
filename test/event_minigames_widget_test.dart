import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/models/adventure.dart';
import 'package:dragon_haven/models/seasonal_minigame.dart';
import 'package:dragon_haven/models/trial.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:dragon_haven/theme/app_theme.dart';
import 'package:dragon_haven/theme/event_appearance.dart';
import 'package:dragon_haven/widgets/seasonal_app_frame.dart';
import 'package:dragon_haven/widgets/seasonal_minigames.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final captureKey = GlobalKey();
  final actions = <(bool, int, bool)>[];
  var now = DateTime.utc(2026, 9, 9, 12);
  const seed = 23;
  const font = String.fromEnvironment('EVENT_UI_FONT');
  const captures = String.fromEnvironment('EVENT_UI_SCREENSHOTS');
  setUpAll(() async {
    if (font.isEmpty) return;
    final loader = FontLoader('EventCapture');
    loader.addFont(
        Future.value(ByteData.sublistView(File(font).readAsBytesSync())));
    await loader.load();
    final icons = FontLoader('MaterialIcons');
    icons.addFont(Future.value(ByteData.sublistView(
        File('${File(font).parent.path}/materialicons-regular.otf')
            .readAsBytesSync())));
    await icons.load();
  });
  Future<void> capture(WidgetTester tester, String name) async {
    if (captures.isEmpty) return;
    await tester.runAsync(() async {
      final boundary = captureKey.currentContext!.findRenderObject()!
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      Directory(captures).createSync(recursive: true);
      await File('$captures/$name.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  Future<void> step(WidgetTester tester, int ms) async {
    now = now.add(Duration(milliseconds: ms));
    await tester.pump(Duration(milliseconds: ms));
  }

  Future<void> mount(WidgetTester tester, TrialKind kind,
      {bool large = false}) async {
    actions.clear();
    now = DateTime.utc(2026, 9, 9, 12);
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var theme = buildAppTheme(
        event:
            EventAppearance.forEvent(trialDefinitions[kind]!.specialEventId!));
    if (font.isNotEmpty) {
      theme = theme.copyWith(
          textTheme: theme.textTheme.apply(fontFamily: 'EventCapture'));
    }
    await tester.pumpWidget(RepaintBoundary(
        key: captureKey,
        child: MaterialApp(
            theme: theme,
            debugShowCheckedModeBanner: false,
            home: MediaQuery(
                data: MediaQueryData(
                    size: const Size(320, 640),
                    disableAnimations: true,
                    textScaler: TextScaler.linear(large ? 1.35 : 1)),
                child: Scaffold(
                    backgroundColor: const Color(0xFF22283F),
                    body: SafeArea(
                        child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: SeasonalMinigames(
                              kind: kind,
                              dragon: Pet(
                                  id: 'arcade', stage: DragonStage.hatchling),
                              seed: seed,
                              running: true,
                              clock: () => now,
                              onAction: (correct,
                                      {required points,
                                      required completesRound}) =>
                                  actions
                                      .add((correct, points, completesRound)),
                            ))))))));
    await step(tester, 40);
  }

  testWidgets(
      'Christmas delivers by dragging; the wrong bay and expiry are misses',
      (tester) async {
    await mount(tester, TrialKind.hollyfrostGiftforge);
    await capture(tester, 'christmas');
    Future<void> deliver(bool correct) async {
      final parcel = find.byKey(const Key('giftforge-parcel'));
      final label = tester
          .widgetList<Semantics>(
              find.descendant(of: parcel, matching: find.byType(Semantics)))
          .map((w) => w.properties.label)
          .whereType<String>()
          .firstWhere((label) => label.startsWith('Parcel '));
      final type = int.parse(label.split(' ').last) - 1;
      final target =
          find.byKey(Key('giftforge-bay-${correct ? type : (type + 1) % 3}'));
      await tester.drag(
          parcel, tester.getCenter(target) - tester.getCenter(parcel));
      await step(tester, 400);
    }

    await deliver(true);
    expect(actions.single, (true, 120, true));
    await deliver(false);
    expect(actions.last.$1, isFalse);
    await step(tester, 5100);
    expect(actions.where((a) => !a.$1), hasLength(2));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('New Year rewards a timed chime once and penalizes a missed note',
      (tester) async {
    await mount(tester, TrialKind.midnightChime);
    await step(tester, 40); // Spawn first note; 2.1 seconds to its strike line.
    await step(tester, 2100);
    final note = find.byKey(const Key('midnight-note-0'));
    final noteCenter = tester.getCenter(note).dx;
    final lane = List.generate(4, (i) => i).reduce((a, b) =>
        (tester.getCenter(find.byKey(Key('midnight-chime-$a'))).dx - noteCenter)
                    .abs() <
                (tester.getCenter(find.byKey(Key('midnight-chime-$b'))).dx -
                        noteCenter)
                    .abs()
            ? a
            : b);
    await capture(tester, 'new-year');
    await tester.tap(find.byKey(Key('midnight-chime-$lane')));
    expect(actions.single, (true, 130, true));
    await step(tester, 200);
    await tester.tap(find.byKey(Key('midnight-chime-$lane')));
    expect(actions.where((a) => a.$1), hasLength(1));
    expect(actions.last.$1, isFalse);
    await step(tester, 4000);
    await step(tester, 2300);
    expect(actions.where((a) => !a.$1).length, greaterThanOrEqualTo(2));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Valentine arrows solve both hearts and reopen a different maze',
      (tester) async {
    await mount(tester, TrialKind.rosevowRelay, large: true);
    final random = Random(seed)..nextInt(3);
    final maze = HeartMaze.generate(random);
    await capture(tester, 'valentine-large');
    for (final direction in maze.solution()!) {
      await tester.tap(find.byKey(Key('rosevow-move-${direction.name}')));
      await step(tester, 160);
    }
    expect(actions.where((a) => a.$3), [(true, 120, true)]);
    expect(actions.every((a) => a.$1), isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('New Year plays four pitches and accepts both notes of a chord',
      (tester) async {
    final sounds = <String>[];
    const channel = MethodChannel('nl.dragonhaven.app/audio');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel,
        (call) async {
      if (call.method == 'playSound') {
        sounds.add(call.arguments['id'] as String);
      }
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));
    await mount(tester, TrialKind.midnightChime);
    var playedChord = false;
    for (var tick = 0; tick < 700 && !playedChord; tick++) {
      await step(tester, 40);
      final strikeY =
          tester.getCenter(find.byKey(const Key('midnight-strike-line'))).dy;
      final ready = find.byWidgetPredicate((w) =>
          w is Positioned &&
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('midnight-note-'));
      final lanes = <int>[];
      for (final element in ready.evaluate()) {
        final note = tester.getCenter(find.byWidget(element.widget));
        if ((note.dy - strikeY).abs() > 7) continue;
        final lane = List.generate(4, (i) => i).reduce((a, b) =>
            (tester.getCenter(find.byKey(Key('midnight-chime-$a'))).dx -
                            note.dx)
                        .abs() <
                    (tester.getCenter(find.byKey(Key('midnight-chime-$b'))).dx -
                            note.dx)
                        .abs()
                ? a
                : b);
        lanes.add(lane);
      }
      final before = actions.where((a) => a.$1).length;
      final gestures = <TestGesture>[];
      for (var i = 0; i < lanes.length; i++) {
        gestures.add(await tester.startGesture(
            tester.getCenter(find.byKey(Key('midnight-chime-${lanes[i]}'))),
            pointer: i + 1));
      }
      for (final gesture in gestures) {
        await gesture.up();
      }
      await tester.pump();
      if (lanes.length == 2) {
        expect(actions.where((a) => a.$1).length - before, 2);
        playedChord = true;
      }
    }
    expect(playedChord, isTrue);
    expect(sounds.toSet(),
        {for (var lane = 1; lane <= 4; lane++) 'event_firstlight_note_$lane'});
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
      'Pride rotates real channels, awards new light once and completes',
      (tester) async {
    await mount(tester, TrialKind.prismaticParade, large: true);
    final random = Random(seed)..nextInt(3);
    final circuit = PrismCircuit.generate(random);
    await capture(tester, 'pride-large');
    // Work from the sink backwards; the completed beam is then connected last.
    for (final solution in circuit.solutionMasks.entries.toList().reversed) {
      for (var turns = 0;
          turns < 4 && circuit.connectors[solution.key] != solution.value;
          turns++) {
        await tester.tap(find.byKey(Key('prismatic-tile-${solution.key}')));
        circuit.rotate(solution.key);
        await step(tester, 140);
      }
    }
    expect(actions.where((a) => a.$3), [(true, 120, true)]);
    expect(actions.every((a) => a.$1), isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
      'banner truncates and removes preview label before wrapping official text',
      (tester) async {
    const eventId = 'halloween_witchlight';
    final event = specialAdventureEventById(eventId)!;
    final window = SpecialAdventureWindow(
        event: event,
        key: '$eventId:preview:test',
        startsAt: now,
        endsAt: now.add(const Duration(days: 2)));
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Future<void> show(double width) async {
      tester.view.physicalSize = Size(width, 640);
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: EventCountdownBanner(window: window, now: () => now))));
      await tester.pump();
    }

    final title = find.byKey(const Key('event-countdown-title'));
    final clock = find.byKey(const Key('event-countdown-clock'));
    final label = find.byKey(const Key('event-preview-label'));
    await show(1400);
    final labelWidth = tester.getSize(label).width;
    final official = tester.getSize(title).width.ceilToDouble() +
        tester.getSize(clock).width.ceilToDouble() +
        44;
    await show(official + 35);
    expect(tester.getTopLeft(title).dy, tester.getTopLeft(clock).dy);
    expect(tester.getSize(label).width, lessThan(labelWidth));
    expect(tester.getTopLeft(label).dx - tester.getTopRight(title).dx,
        greaterThanOrEqualTo(8));
    await show(official + 3);
    expect(label, findsNothing);
    expect(tester.getTopLeft(title).dy, tester.getTopLeft(clock).dy);
    await show(official - 5);
    expect(label, findsNothing);
    expect(
        tester.getTopLeft(clock).dy, greaterThan(tester.getTopLeft(title).dy));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
