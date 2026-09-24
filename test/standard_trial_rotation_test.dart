import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dragon_haven/models/standard_trial_games.dart';
import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/models/trial.dart';
import 'package:dragon_haven/models/trial_input.dart';
import 'package:dragon_haven/models/trial_run_model.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:flutter_test/flutter_test.dart';

int _perfectShape(SpiritAlignmentGame game, int at) {
  while ((game.playerY - game.targetY).abs() >
      SpiritAlignmentGeometry.snapTolerance * .75) {
    game.advanceTo(++at);
  }
  expect(game.tap(at), isTrue);
  while ((game.playerX - game.targetX).abs() >
      SpiritAlignmentGeometry.snapTolerance * .75) {
    game.advanceTo(++at);
  }
  expect(game.tap(at), isTrue);
  expect(game.latestOverlap, 100);
  game.advanceTo(at += 700);
  return at;
}

void main() {
  test('standard rotation contains three old and three independent new Trials',
      () {
    expect(standardTrialKinds, [
      TrialKind.cavernFlight,
      TrialKind.ruinBreaker,
      TrialKind.runeweaver,
      TrialKind.spiritAlignment,
      TrialKind.ruinGuard,
      TrialKind.runeOrbit,
    ]);
    expect(standardTrialKinds.map((kind) => kind.name).toSet(), hasLength(6));
    for (final kind in const [
      TrialKind.spiritAlignment,
      TrialKind.ruinGuard,
      TrialKind.runeOrbit,
    ]) {
      expect(trialDefinitions[kind]!.isSeasonal, isFalse);
      expect(trialGradeForScore(kind, 9007199254740991), TrialGrade.sPlus);
    }
  });

  test(
      'Spirit Alignment only advances on three displayed 100s and speeds by 1.10',
      () {
    var game = SpiritAlignmentGame(seed: 41, spirit: 300);
    expect(game.targetX, .5);
    expect(game.targetY, .5);
    expect(game.playerX, lessThan(game.targetX));
    expect(trialDefinitions[TrialKind.spiritAlignment]!.isEndless, isTrue);
    var at = 0;
    for (var i = 0; i < 3; i++) {
      at = _perfectShape(game, at);
    }
    expect(game.round, 2);
    expect(game.roundSpeed, closeTo(1.10, .000001));
    expect(game.score, 300);

    game = SpiritAlignmentGame.fromCheckpoint(
      jsonDecode(jsonEncode(game.checkpoint())),
      spirit: 300,
    );
    for (var i = 0; i < 3; i++) {
      at = _perfectShape(game, at);
    }
    expect(game.round, 3);
    expect(game.roundSpeed, closeTo(1.21, .000001));
    expect(game.score, 600);

    final restored = SpiritAlignmentGame.fromCheckpoint(
      jsonDecode(jsonEncode(game.checkpoint())),
      spirit: 300,
    );
    expect(restored.checkpoint(), game.checkpoint());
    expect(restored.targetX, .5);
    expect(restored.targetY, .5);
  });

  test('added Trials map to matching Ascended specialists and Mastery', () {
    for (final entry in ascendedTrialKindByFocus.entries) {
      expect(ascendedTrialFocus(entry.value), entry.key);
      expect(
        dragonMeetsTrialFormRequirement(
          kind: entry.value,
          stage: DragonStage.ascended,
          activeEvolutionPath: entry.key.name,
        ),
        isTrue,
      );
      expect(
        dragonMeetsTrialFormRequirement(
          kind: entry.value,
          stage: DragonStage.ascended,
          activeEvolutionPath: 'mastery',
        ),
        isTrue,
      );
      expect(
        dragonMeetsTrialFormRequirement(
          kind: entry.value,
          stage: DragonStage.wyrmling,
          activeEvolutionPath: entry.key.name,
        ),
        isFalse,
      );
      expect(
        dragonMeetsTrialFormRequirement(
          kind: entry.value,
          stage: DragonStage.ascended,
          activeEvolutionPath: TrainingFocus.values
              .firstWhere((focus) => focus != entry.key)
              .name,
        ),
        isFalse,
      );
    }
  });

  test('released Ascended forms do not unlock added Trials', () {
    final game = HouseholdProvider(initialize: false, persistenceEnabled: false)
      ..pet = Pet(
        id: 'owned-wyrmling',
        stage: DragonStage.wyrmling,
        firstEgg: false,
      )
      ..releasedDragons.add(Pet(
        id: 'released-spirit',
        stage: DragonStage.ascended,
        firstEgg: false,
        evolutionPath: TrainingFocus.spirit.name,
      ));
    expect(unlockedAscendedTrialFocuses(game.ownedDragons), isEmpty);
    game.dispose();
  });

  test('two-stage rotation keeps focus odds independent of unlocked games', () {
    Map<TrainingFocus, int> sample(Set<TrainingFocus> unlocked) {
      final random = Random(unlocked.length + 90240);
      final result = {for (final focus in TrainingFocus.values) focus: 0};
      for (var draw = 0; draw < 120000; draw++) {
        final kind = chooseTrialOfferKind(
          random,
          unlockedAscendedFocuses: unlocked,
        );
        result.update(trialDefinitions[kind]!.focus, (count) => count + 1);
      }
      return result;
    }

    for (final unlocked in <Set<TrainingFocus>>[
      const {},
      const {TrainingFocus.spirit},
      TrainingFocus.values.toSet(),
    ]) {
      final counts = sample(unlocked);
      for (final count in counts.values) {
        expect(count / 120000, inInclusiveRange(.328, .339));
      }
    }
  });

  test('locked focus falls back to classic; unlocked focus splits one half',
      () {
    final random = Random(24097);
    final counts = <TrialKind, int>{};
    for (var draw = 0; draw < 180000; draw++) {
      final kind = chooseTrialOfferKind(
        random,
        unlockedAscendedFocuses: const {TrainingFocus.spirit},
      );
      counts.update(kind, (count) => count + 1, ifAbsent: () => 1);
    }
    expect(counts[TrialKind.ruinGuard] ?? 0, 0);
    expect(counts[TrialKind.runeOrbit] ?? 0, 0);
    expect(
        counts[TrialKind.ruinBreaker]! / 180000, inInclusiveRange(.328, .339));
    expect(
        counts[TrialKind.runeweaver]! / 180000, inInclusiveRange(.328, .339));
    expect(
        counts[TrialKind.cavernFlight]! / 180000, inInclusiveRange(.161, .172));
    expect(counts[TrialKind.spiritAlignment]! / 180000,
        inInclusiveRange(.161, .172));
  });

  test('an active event is exactly one first-stage category out of four', () {
    final random = Random(4097);
    final categories = <String, int>{};
    for (var draw = 0; draw < 160000; draw++) {
      final kind = chooseTrialOfferKind(
        random,
        unlockedAscendedFocuses: TrainingFocus.values.toSet(),
        activeEventKinds: const [TrialKind.witchlightWard],
      );
      final category = kind == TrialKind.witchlightWard
          ? 'event'
          : trialDefinitions[kind]!.focus.name;
      categories.update(category, (count) => count + 1, ifAbsent: () => 1);
    }
    for (final category in const ['arcana', 'spirit', 'might', 'event']) {
      expect(categories[category]! / 160000, inInclusiveRange(.245, .255),
          reason: category);
    }
  });

  test('a rendered 99 or lower ends Spirit Alignment after the three shapes',
      () {
    final game = SpiritAlignmentGame(seed: 7, spirit: 0);
    var at = 0;
    // Lock the first shape far away from its target.
    expect(game.tap(at), isTrue);
    game.advanceTo(at += 1900);
    expect(game.tap(at), isTrue);
    expect(game.latestOverlap, lessThan(100));
    game.advanceTo(at += 700);
    at = _perfectShape(game, at);
    at = _perfectShape(game, at);
    expect(game.ended, isTrue);
    expect(game.round, 1);
  });

  test('each Spirit shape reports true full, partial and zero overlap', () {
    final oneShapeAway = SpiritAlignmentGeometry.shapeExtent /
        SpiritAlignmentGeometry.travelExtent;
    for (final shape in SpiritAlignmentShape.values) {
      expect(
        SpiritAlignmentGame.overlapPercent(
          shape,
          playerX: .5,
          playerY: .5,
        ),
        100,
        reason: '${shape.name} exact',
      );
      expect(
        SpiritAlignmentGame.overlapPercent(
          shape,
          playerX: .5 + oneShapeAway * .4,
          playerY: .5,
        ),
        inInclusiveRange(1, 99),
        reason: '${shape.name} partial',
      );
      expect(
        SpiritAlignmentGame.overlapPercent(
          shape,
          playerX: .5 + oneShapeAway * 1.1,
          playerY: .5,
        ),
        0,
        reason: '${shape.name} separated',
      );
    }
  });

  test('Ruin Guard checkpoint replay preserves lane, targets and outcomes', () {
    var live = RuinGuardGame(seed: 13, might: 400);
    var restored = RuinGuardGame(seed: 13, might: 400);
    for (var at = 0; at <= 30000 && !live.ended; at += 20) {
      live.advanceTo(at);
      restored.advanceTo(at);
      if (!live.locked && live.boulderProgress < .7) {
        if (live.round < 6) {
          if (live.playerLane != live.targetLane) {
            live.tap(at);
            restored.tap(at);
          }
        } else if (live.playerLane == live.targetLane) {
          live.tap(at);
          restored.tap(at);
        }
      }
      if (at % 1000 == 0) {
        restored = RuinGuardGame.fromCheckpoint(
          jsonDecode(jsonEncode(restored.checkpoint())),
          might: 400,
        );
      }
      expect(restored.checkpoint(), live.checkpoint());
    }
    expect(live.ended, isTrue);
    expect(live.score, greaterThan(0));
    expect(live.misses, 3);
  });

  test('Rune Orbit checkpoint replay keeps its target and separate score', () {
    var model = TrialRunModel(
      kind: TrialKind.runeOrbit,
      seed: 19,
      training: const {TrainingFocus.arcana: 300},
    );
    var at = 0;
    while (model.orbit!.rounds < 5) {
      model.advanceTo(at += 20);
      final orbit = model.orbit!;
      if (orbit.accepting && orbit.gateRune == orbit.targetRune) {
        model.apply(TrialInput(at, TrialControl.tapRune, orbit.gateRune));
      }
      if (at % 1000 == 0) {
        model = TrialRunModel.fromCheckpoint(
          jsonDecode(jsonEncode(model.checkpoint())),
        );
      }
    }
    expect(model.score, 5);
    expect(model.kind, TrialKind.runeOrbit);
    expect(model.checkpoint()['orbit'], isNotNull);
    expect(model.checkpoint()['runes'], isNull);
  });

  test('migration 097 gives every added Trial an independent ranking column',
      () {
    final sql = javaScriptLikeSql();
    for (final pair in const {
      'spiritAlignment': 'spirit_alignment_best',
      'ruinGuard': 'ruin_guard_best',
      'runeOrbit': 'rune_orbit_best',
    }.entries) {
      expect(sql, contains("'${pair.key}'"));
      expect(sql, contains(pair.value));
    }
    expect(sql, contains('project_standard_trial_bests'));
    expect(sql, contains('rename to get_trial_rankings_v96'));
    expect(sql, contains('public.get_trial_rankings_v96'));
    expect(
      sql,
      contains(
        "p_trial_key not in ('spiritAlignment', 'ruinGuard', 'runeOrbit')",
      ),
    );
    expect(
      sql,
      contains("set_config('request.jwt.claim.role', 'service_role', true)"),
    );
    expect(sql, contains("coalesce(previous_role, '')"));
    expect(sql, contains('to authenticated'));
  });
}

String javaScriptLikeSql() =>
    File('supabase/migrations/202609240097_standard_trial_rotation.sql')
        .readAsStringSync();
