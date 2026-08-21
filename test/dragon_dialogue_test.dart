import 'package:dragon_haven/models/dragon_dialogue.dart';
import 'package:dragon_haven/models/pet.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the catalog has exactly 300 unique bilingual sayings', () {
    expect(dragonDialogueLines, hasLength(300));
    expect(dragonDialogueLines.map((line) => line.id).toSet(), hasLength(300));
    expect(dragonDialogueLines.map((line) => line.en).toSet(), hasLength(300));
    expect(dragonDialogueLines.map((line) => line.nl).toSet(), hasLength(300));
    expect(
      dragonDialogueLines.every((line) =>
          line.en.trim().isNotEmpty &&
          line.nl.trim().isNotEmpty &&
          line.en != line.nl),
      isTrue,
    );
  });

  test('each speaking life stage has 100 lines and all five tones', () {
    for (final stage in ['spark', 'nestDragon', 'homeGuardian']) {
      final lines =
          dragonDialogueLines.where((line) => line.stageKey == stage).toList();
      expect(lines, hasLength(100), reason: stage);
      for (final tone in DragonDialogueTone.values) {
        expect(lines.where((line) => line.tone == tone), hasLength(20),
            reason: '$stage ${tone.name}');
      }
    }
  });

  test('dialogue contains no remnants of the chore concept', () {
    final allText = dragonDialogueLines
        .expand((line) => [line.en, line.nl])
        .join(' ')
        .toLowerCase();
    expect(
      RegExp(r'\b(chore|chores|quest|quests|klus|klusjes)\b').hasMatch(allText),
      isFalse,
    );
  });

  test('dialogue selection is deterministic for the same moment', () {
    final pet = Pet(
      stage: DragonStage.hatchling,
      hatchSeed: 99,
      energy: 90,
      joy: 95,
    );
    final now = DateTime.utc(2026, 8, 1, 12, 34);
    expect(dialogueFor(pet, now).id, dialogueFor(pet, now).id);
    expect(dialogueFor(pet, now).stageKey, 'spark');
  });
}
