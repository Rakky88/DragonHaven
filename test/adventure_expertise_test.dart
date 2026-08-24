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

  Pet dragon(int might) => Pet(training: {
        'might': might,
        'arcana': 0,
        'spirit': 0,
      });

  test('mini expertise removes seconds from the advertised duration', () {
    expect(
      expertiseAdjustedAdventureDuration(
        adventure(AdventureKind.mini, const Duration(minutes: 6)),
        [dragon(300)],
      ),
      const Duration(minutes: 1),
    );
  });

  test('short expertise removes minutes from the advertised duration', () {
    expect(
      expertiseAdjustedAdventureDuration(
        adventure(AdventureKind.short, const Duration(hours: 6)),
        [dragon(300)],
      ),
      const Duration(hours: 1),
    );
  });

  test('long and group adventures use combined expertise in minutes', () {
    expect(
      expertiseAdjustedAdventureDuration(
        adventure(AdventureKind.long, const Duration(days: 6)),
        [dragon(300)],
      ),
      const Duration(days: 5, hours: 19),
    );
    expect(
      expertiseAdjustedAdventureDuration(
        adventure(AdventureKind.group, const Duration(days: 6)),
        [dragon(175), dragon(125)],
      ),
      const Duration(days: 5, hours: 19),
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
}
