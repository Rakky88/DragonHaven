import 'dart:convert';
import 'dart:io';

import 'package:dragon_haven/models/dragon_school.dart';
import 'package:dragon_haven/models/game_input_transcript.dart';
import 'package:dragon_haven/models/school_lesson_game.dart';
import 'package:dragon_haven/screens/dragon_school_screen.dart';
import 'package:dragon_haven/services/canonical_game_session.dart';
import 'package:dragon_haven/services/canonical_game_snapshot.dart';
import 'package:dragon_haven/services/canonical_school_run_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../tool/game_domain_probe.dart';
import 'support/canonical_ui_server.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Map<String, dynamic> fixture;
  setUpAll(() async {
    fixture = (await runGameDomainProbe())['state'] as Map<String, dynamic>;
  });
  late Directory directory;
  late CanonicalUiServer server;
  late CanonicalGameSession session;
  late CanonicalSchoolRunSource source;
  final definition = dragonSchoolGameById('runeRush')!;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('dh-school-');
    server = CanonicalUiServer(
        jsonDecode(jsonEncode(fixture)) as Map<String, dynamic>);
    server.state['towerFloorRoomIds'] = List.filled(5, 'hearth');
    session = CanonicalGameSession(
        connection: CanonicalUiConnection(server), directory: directory);
    await session.synchronize();
    source = CanonicalSchoolRunSource(
        session, definition, [session.snapshot!.activeDragonId!], null);
  });
  tearDown(() async {
    source.dispose();
    session.dispose();
    await directory.delete(recursive: true);
  });
  Matcher error(String code) => throwsA(
      isA<CanonicalGameException>().having((e) => e.code, 'fixed code', code));

  test('lost start preserves seed; lost finish restores exactly one reward',
      () async {
    server.loseReply = true;
    await expectLater(source.start(), error('game_command_unavailable'));
    final storedId = server.state['_activeGameAttempt']['id'];
    final seed = await source.start();
    expect(session.snapshot!.schoolAttempt!.id, storedId);
    expect(seed, server.state['_activeGameAttempt']['seed']);
    final game = SchoolLessonGame(kind: definition.kind, seed: seed);
    for (var at = 100; at <= 3000; at += 100) {
      game.tap(game.runePoint, at);
    }
    final beforeXp = session.snapshot!.dragon(source.dragonIds.first)!.xp;
    server.now = server.now.add(const Duration(seconds: 21));
    server.loseReply = true;
    final input = SchoolInputTranscript.encode(game.inputs);
    await expectLater(source.finish(input), error('game_command_unavailable'));
    final completedRevision = server.revision;
    final result = await source.finish(input);
    expect(result.newStarsByDragon[source.dragonIds.first], 3);
    expect(server.revision, completedRevision);
    expect(session.snapshot!.dragon(source.dragonIds.first)!.xp, beforeXp + 15);
    expect(session.snapshot!.schoolAttempt, isNull);
    expect(
        session.snapshot!
            .dragon(source.dragonIds.first)!
            .schoolAttempts['runeRush'],
        1);
    await expectLater(source.finish(input), error('game_attempt_unavailable'));
  });

  testWidgets(
      'the existing sprite lesson plays against canonical pupils and saves inputs',
      (tester) async {
    var elapsed = 0;
    await tester.pumpWidget(ChangeNotifierProvider.value(
        value: session,
        child: MaterialApp(
          home: DragonSchoolGameScreen(
              definition: definition,
              dragonIds: source.dragonIds,
              source: source,
              elapsedMilliseconds: () => elapsed),
        )));
    await tester
        .runAsync(() => tester.tap(find.byKey(const Key('start-school-game'))));
    for (var i = 0; i < 80 && server.state['_activeGameAttempt'] == null; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump();
    }
    for (var i = 0;
        i < 80 &&
            find.byKey(const Key('school-rune-rush-target')).evaluate().isEmpty;
        i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump();
    }
    expect(find.byKey(const Key('school-rune-rush-target')), findsOneWidget);
    for (var i = 0; i < 28; i++) {
      elapsed += 100;
      await tester.tap(find.byKey(const Key('school-rune-rush-target')));
      await tester.pump(const Duration(milliseconds: 100));
    }
    elapsed = 20000;
    server.now = server.now.add(const Duration(seconds: 21));
    await tester.pump(const Duration(milliseconds: 50));
    for (var i = 0;
        i < 100 && find.text('Lesson complete').evaluate().isEmpty;
        i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump();
    }
    expect(find.text('Lesson complete'), findsOneWidget);
    expect(server.state['pet']['dragonSchoolStars']['runeRush'], 3);
    final command = server.sent.last;
    expect(command.action, 'finish_school');
    expect(command.payload.keys, unorderedEquals(['attemptId', 'inputs']));
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  test('account exit invalidates a lesson source and hides pupil facts',
      () async {
    await source.start();
    (session.connection as CanonicalUiConnection).signOut();
    expect(source.accountCurrent, false);
    expect(source.participants, isEmpty);
    await expectLater(source.finish(''), error('game_account_changed'));
  });
}
