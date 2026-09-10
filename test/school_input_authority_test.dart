import 'dart:convert';

import 'package:dragon_haven/domain/game_command_engine.dart';
import 'package:dragon_haven/models/dragon_school.dart';
import 'package:dragon_haven/models/game_input_transcript.dart';
import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/models/school_lesson_game.dart';
import 'package:dragon_haven/services/school_run_source.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime.utc(2026, 9, 10, 12);
  Map<String, dynamic> fixture() {
    final game = HouseholdProvider(clock: () => now, persistenceEnabled: false);
    game.pet
      ..stage = DragonStage.hatchling
      ..firstEgg = false
      ..favorite = true;
    game.towerFloorRoomIds = List.filled(5, 'hearth');
    game.sanctuaryDragons.add(Pet(id: 'second', stage: DragonStage.wyrmling));
    final state = game.exportState();
    game.dispose();
    return state;
  }

  Future<Map<String, dynamic>> execute(Map<String, dynamic> state,
          String action, Map<String, dynamic> payload, {int seconds = 0}) =>
      GameCommandEngine.execute(
          state: state,
          action: action,
          payload: payload,
          secretSeed: List.filled(32, 'a1').join(),
          now: now.add(Duration(seconds: seconds)),
          keeperId: '11111111-1111-4111-8111-111111111111');
  Matcher error(String code) => throwsA(
      isA<GameCommandException>().having((e) => e.code, 'fixed code', code));

  for (final definition in dragonSchoolGames) {
    test('${definition.id}: only replayed inputs grant one lesson result',
        () async {
      final before = fixture();
      final ids = [
        before['pet']['id'] as String,
        if (definition.minimumDragons > 1) 'second'
      ];
      final started = await execute(before, 'start_school', {
        'gameId': definition.id,
        'dragonIds': jsonEncode(ids),
        'mentorId': null,
      });
      final state = started['state'] as Map<String, dynamic>;
      final attempt = started['result'] as Map<String, dynamic>;
      expect(state['pet']['xp'], before['pet']['xp']);
      expect(before.containsKey('_activeGameAttempt'), false);
      final model =
          SchoolLessonGame(kind: definition.kind, seed: attempt['seed'] as int);
      for (var t = 50; t < 20000; t += 50) {
        model.advanceTo(t);
        final target = switch (definition.kind) {
          DragonSchoolGameKind.runeRush => model.runePoint,
          DragonSchoolGameKind.emberReflex ||
          DragonSchoolGameKind.breathBalance =>
            0,
          DragonSchoolGameKind.scaleOrder =>
            model.order.indexOf(model.expected),
          DragonSchoolGameKind.safeHoard => (model.target + 1) % 6,
          DragonSchoolGameKind.constellationTrace =>
            model.constellationOrder[model.expected],
          _ => model.target,
        };
        if (definition.kind == DragonSchoolGameKind.emberReflex &&
                !model.cueReady ||
            definition.kind == DragonSchoolGameKind.sigilMemory &&
                model.memoryVisible ||
            definition.kind == DragonSchoolGameKind.breathBalance &&
                (model.phase - .5).abs() >= .12) {
          continue;
        }
        model.tap(target, t);
      }
      final inputs = SchoolInputTranscript.encode(model.inputs);
      final payload = {'attemptId': attempt['id'], 'inputs': inputs};
      await expectLater(execute(state, 'finish_school', payload, seconds: 19),
          error('game_attempt_time_invalid'));
      await expectLater(
          execute(state, 'finish_school', {...payload, 'score': 99999},
              seconds: 20),
          error('invalid_command'));
      await expectLater(
          execute(state, 'buy_starlight_treat', {'dragonId': ids.first}),
          error('game_attempt_in_progress'));
      final finished =
          await execute(state, 'finish_school', payload, seconds: 20);
      final after = finished['state'] as Map<String, dynamic>;
      final result = finished['result'] as Map<String, dynamic>;
      expect(result['score'], model.score);
      expect(model.score, greaterThanOrEqualTo(definition.goldScore));
      expect(result['newStarsByDragon'][ids.first], 3);
      expect(after['pet']['dragonSchoolAttempts'][definition.id], 1);
      expect(after['_activeGameAttempt'], isNull);
      await expectLater(execute(after, 'finish_school', payload, seconds: 21),
          error('game_attempt_unavailable'));
    });
  }

  test('cancellation consumes an attempt, and an expired attempt cannot pay',
      () async {
    final before = fixture();
    final started = await execute(before, 'start_school', {
      'gameId': 'runeRush',
      'dragonIds': jsonEncode([before['pet']['id']]),
      'mentorId': null,
    });
    final state = started['state'] as Map<String, dynamic>;
    final id = started['result']['id'];
    await expectLater(
        execute(state, 'finish_school', {'attemptId': id, 'inputs': ''},
            seconds: 601),
        error('game_attempt_time_invalid'));
    final ended =
        await execute(state, 'cancel_school', {'attemptId': id}, seconds: 601);
    expect(ended['state']['pet']['dragonSchoolAttempts']['runeRush'], 1);
    expect(ended['state']['pet']['xp'], before['pet']['xp']);
    expect(ended['result']['score'], 0);
    expect(ended['result']['cancelled'], true);
    final refreshed =
        await execute(ended['state'], 'refresh', {}, seconds: 602);
    expect(refreshed['state']['_activeGameAttempt'], isNull);
  });

  test('inputs reject reverse time, out-of-range identities and floods', () {
    for (final inputs in [
      [const SchoolTap(100, 1), const SchoolTap(90, 2)],
      [const SchoolTap(100, 1), const SchoolTap(110, 2)],
    ]) {
      expect(
          () => SchoolInputTranscript.decode(
              SchoolInputTranscript.encode(inputs)),
          throwsFormatException);
    }
    expect(() => SchoolInputTranscript.encode([const SchoolTap(20000, 0)]),
        throwsFormatException);
    expect(() => SchoolInputTranscript.decode('AQ=='), throwsFormatException);
    expect(
        () => SchoolInputTranscript.decode('A' * 3204), throwsFormatException);
    final model =
        SchoolLessonGame(kind: DragonSchoolGameKind.runeRush, seed: 5);
    model.tap(model.runePoint, 0);
    model.tap(model.runePoint, 1);
    expect(model.score, 1);
    expect(model.inputs, hasLength(1));
    model.tap(model.runePoint, 20000);
    expect(model.score, 1);
  });

  test('public pupil sprites preserve every existing stage key', () {
    for (final stage in DragonStage.values) {
      final pet = Pet(id: 'art-test', stage: stage);
      expect(SchoolStudent.fromPet(pet).stageKey, pet.stageKey);
    }
  });

  test('clock-driven windows, one mentor shield and all first cloud lanes', () {
    final protected = SchoolLessonGame(
        kind: DragonSchoolGameKind.emberReflex, seed: 1, mentor: true);
    protected.tap(0, 0);
    expect(protected.mentorShieldUsed, true);
    expect(protected.reaction, 2);
    protected.tap(0, 25);
    expect(protected.reaction, -1);
    final a =
        SchoolLessonGame(kind: DragonSchoolGameKind.breathBalance, seed: 1);
    final b =
        SchoolLessonGame(kind: DragonSchoolGameKind.breathBalance, seed: 1);
    for (var t = 0; t <= 1250; t += 5) {
      a.advanceTo(t);
    }
    b.advanceTo(1250);
    a.tap(0, 1250);
    b.tap(0, 1250);
    expect(a.score, 2);
    expect(b.score, 2);
    for (var seed = 0; seed < 40; seed++) {
      expect(
          SchoolLessonGame(kind: DragonSchoolGameKind.cloudWeave, seed: seed)
              .target,
          inInclusiveRange(0, 2));
    }
  });
}
