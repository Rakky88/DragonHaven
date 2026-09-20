import 'dart:convert';

import 'package:dragon_haven/models/trial.dart';
import 'package:dragon_haven/models/trial_input.dart';
import 'package:dragon_haven/models/trial_run_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
      'New Year continues beyond time, score and old transcript limits; third error ends it',
      () {
    var game =
        TrialRunModel(kind: TrialKind.midnightChime, seed: 91, training: {});
    var milliseconds = 0;
    while (game.correctActions < 6500 && milliseconds < 900000) {
      milliseconds += 10;
      game.advanceTo(milliseconds);
      for (final note in game.arcade!.notes
          .where((n) => n.strikeAt <= milliseconds / 1000)
          .toList()) {
        game.apply(
            TrialInput(milliseconds, TrialControl.strikeChime, note.lane));
      }
      game.takeEvents();
      if (milliseconds % 10000 == 0) {
        final before = game.checkpoint();
        final restored =
            TrialRunModel.fromCheckpoint(jsonDecode(jsonEncode(before)));
        expect(restored.checkpoint(), before);
        expect(jsonEncode(before).length, lessThan(12000));
        game = restored;
      }
      if (game.ended)
        fail(
            'Unexpected game over at $milliseconds with ${game.mistakes} errors');
    }
    expect(game.correctActions, greaterThanOrEqualTo(6500));
    expect(game.score, greaterThan(20000));
    expect(game.elapsedMs, greaterThan(180000));
    expect(game.checkpoint(), isNot(contains('history')));
    expect(trialGradeForScore(TrialKind.midnightChime, 19999), TrialGrade.s);
    expect(
        trialGradeForScore(TrialKind.midnightChime, 20000), TrialGrade.sPlus);
    game.advanceTo(milliseconds + 10000);
    expect(game.mistakes, 3);
    expect(game.ended, isTrue);
    final finished = game.checkpoint();
    game.apply(TrialInput(milliseconds + 10001, TrialControl.strikeChime, 0));
    expect(game.checkpoint(), finished);
  });
}
