import 'package:dragon_haven/models/adventure.dart';
import 'package:dragon_haven/models/pet.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  AdventureDefinition adventure(AdventureKind kind, Duration duration) =>
      AdventureDefinition(
        id: 'duration-${kind.name}',
        kind: kind,
        titleEn: 'Duration test',
        titleNl: 'Duurtest',
        descriptionEn: 'Test',
        descriptionNl: 'Test',
        duration: duration,
        xp: 1,
        focus: TrainingFocus.might,
        statPoints: 1,
      );

  Pet dragon(int might, {int arcana = 0, int spirit = 0}) => Pet(training: {
        'might': might,
        'arcana': arcana,
        'spirit': spirit,
      });

  test('mini expertise removes seconds from the advertised duration', () {
    expect(
      expertiseAdjustedAdventureDuration(
        adventure(AdventureKind.mini, const Duration(minutes: 2)),
        [dragon(300)],
      ),
      const Duration(minutes: 1),
    );
  });

  test('short expertise removes minutes from the advertised duration', () {
    expect(
      expertiseAdjustedAdventureDuration(
        adventure(AdventureKind.short, const Duration(hours: 3)),
        [dragon(300)],
      ),
      const Duration(hours: 1),
    );
  });

  test('long expertise removes hours with a one-day minimum', () {
    expect(
      expertiseAdjustedAdventureDuration(
        adventure(AdventureKind.long, const Duration(days: 3)),
        [dragon(24)],
      ),
      const Duration(days: 2),
    );
    expect(
      expertiseAdjustedAdventureDuration(
        adventure(AdventureKind.long, const Duration(days: 3)),
        [dragon(300)],
      ),
      const Duration(days: 1),
    );
  });

  test('group adventures remove the average expertise in hours', () {
    expect(
      expertiseAdjustedAdventureDuration(
        adventure(AdventureKind.group, const Duration(days: 6)),
        [dragon(24), dragon(48)],
      ),
      const Duration(days: 4, hours: 12),
    );
  });

  test('only the adventure focus changes its duration', () {
    expect(
      expertiseAdjustedAdventureDuration(
        adventure(AdventureKind.short, const Duration(hours: 3)),
        [dragon(30, arcana: 300, spirit: 300)],
      ),
      const Duration(hours: 2, minutes: 30),
    );
  });

  test('special adventures do not receive expertise time reduction', () {
    const duration = Duration(hours: 8);
    expect(
      expertiseAdjustedAdventureDuration(
        adventure(AdventureKind.special, duration),
        [dragon(300)],
      ),
      duration,
    );
  });

  test('combined Special Adventure subtracts all three expertises in hours',
      () {
    final definition = AdventureDefinition(
      id: 'combined-special',
      kind: AdventureKind.special,
      titleEn: 'Combined',
      titleNl: 'Gecombineerd',
      descriptionEn: 'Test',
      descriptionNl: 'Test',
      duration: const Duration(days: 10),
      xp: 500,
      focus: TrainingFocus.might,
      statPoints: 0,
      combinedExpertise: true,
    );
    expect(
      expertiseAdjustedAdventureDuration(
        definition,
        [dragon(24, arcana: 24, spirit: 24)],
      ),
      const Duration(days: 7),
    );
    expect(
      expertiseAdjustedAdventureDuration(
        definition,
        [dragon(350, arcana: 350, spirit: 350)],
      ),
      const Duration(days: 1),
    );
  });
}
