import 'dart:io';

import 'package:dragon_haven/models/adventure.dart';
import 'package:dragon_haven/models/chest.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/reference_documentation_guard.dart';

void main() {
  test('living reference documents match their implementation sources', () {
    expect(
      verifyReferenceDocuments(),
      isEmpty,
      reason: 'Review and update the affected Markdown reference before '
          'accepting a new source fingerprint.',
    );
  });

  test('special content catalog names every implemented event and chest', () {
    final contents =
        File(specialContentReference.documentPath).readAsStringSync();

    for (final event in specialAdventureEventCatalog) {
      expect(contents, contains('`${event.id}`'));
      expect(contents, contains('`${event.adventureId}`'));
    }
    for (final tier in ChestTier.values) {
      expect(contents, contains('`${tier.name}`'));
    }
    for (final eggName in const [
      'Starter Egg',
      'Mysterious Egg',
      'Sinister Egg',
      'Special Egg',
    ]) {
      expect(contents, contains(eggName));
    }
  });
}
