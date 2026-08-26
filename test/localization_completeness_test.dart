import 'dart:io';

import 'package:dragon_haven/l10n/app_strings.dart';
import 'package:dragon_haven/l10n/catalog_translations.dart';
import 'package:dragon_haven/l10n/ui_phrase_translations.dart';
import 'package:dragon_haven/models/achievement.dart';
import 'package:dragon_haven/models/adventure.dart';
import 'package:dragon_haven/models/dragon_dialogue.dart';
import 'package:dragon_haven/models/mystic_relic.dart';
import 'package:dragon_haven/models/pet.dart';
import 'package:dragon_haven/models/shop_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const translatedLanguages = ['de', 'es', 'fr', 'it', 'pt', 'zh', 'ja'];

  test('every fixed UI phrase has all seven additional translations', () {
    expect(uiPhraseTranslations.length, greaterThanOrEqualTo(260));
    for (final entry in uiPhraseTranslations.entries) {
      expect(entry.value, hasLength(7), reason: entry.key);
      expect(entry.value.every((value) => value.trim().isNotEmpty), isTrue,
          reason: entry.key);
      for (final language in translatedLanguages) {
        expect(translatedUiPhrase(entry.key, language), isNotNull,
            reason: '${entry.key} ($language)');
      }
    }
  });

  test('every fixed authored pick phrase is translated in all languages', () {
    final fixedPhrases = <String>{};
    final pickPattern = RegExp(
      r"\.pick\(\s*'((?:\\.|[^'])*)'\s*,",
      multiLine: true,
    );
    for (final file in Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))) {
      final source = file.readAsStringSync();
      for (final match in pickPattern.allMatches(source)) {
        final phrase =
            match.group(1)!.replaceAll(r"\'", "'").replaceAll(r'\\', r'\');
        if (!phrase.contains(r'$')) fixedPhrases.add(phrase);
      }
    }
    expect(fixedPhrases, isNotEmpty);
    final missingTranslations = <String>[];
    for (final phrase in fixedPhrases) {
      for (final language in translatedLanguages) {
        if (translatedUiPhrase(phrase, language) == null) {
          missingTranslations.add('$phrase ($language)');
        }
      }
    }
    expect(missingTranslations, isEmpty,
        reason: 'Missing fixed UI translations:\n'
            '${missingTranslations.join('\n')}');
  });

  test('variable UI phrases preserve values in every language', () {
    const samples = [
      '17 items · 8 of 20 rooms built',
      'Moon fern already has a place in the house.',
      'Moon fern is now in Moon garden.',
      'Moon fern purchased and placed in Moon garden!',
      'Mossprout in the Hatchling life stage',
      'Moon fern placed. Tap elsewhere to move it.',
      'Moon fern now has a place in the sanctuary.',
      '37 of 200 collected',
      '11 more coins needed.',
      '9 more gems needed.',
      '42 items shown',
      'Moon garden is ready for decorating!',
      'Gold Chest added to your rewards.',
      'A Mossprout has hatched!',
      'Acquired 22-08-2026 · identity fixed',
      'Add a floor · 125 coins',
      'Build this room for 80 star coins? Furniture and progress stay exactly where they are.',
      'CRACK 2/3',
      'Claim Whispering Ruins',
      'Discard one Gold Chest?',
      'Dragons 17/42',
      'Dragons 17',
      'Dragon families 9/42',
      'Hatches in 23:59:59',
      'GitHub could not be checked (code 503).',
      'Next form: Wyrmling',
      'Level 12 · 90 coins',
      'Pack 3 of 6',
      'Release Nova?',
      'Remove Moon fern?',
      'Selected: Moon fern. Tap the room to place it.',
      'Talk to Nova',
      'Rick has returned',
      'Nova evolved into Ascended.',
      '4 players',
      '13 / 20 unlocked',
      'You need 25 more coins.',
      'Your sanctuary reaches level 12 before this room can be built.',
      '7 / 12 roaming · maximum 3 per room',
    ];
    for (final language in translatedLanguages) {
      for (final sample in samples) {
        final translated = translatedUiPhrase(sample, language);
        expect(translated, isNotNull, reason: '$sample ($language)');
        expect(translated, isNotEmpty);
      }
    }
  });

  test('all achievements are translated in every supported language', () {
    for (final language in translatedLanguages) {
      final strings = AppStrings(language);
      for (final achievement in achievementCatalog) {
        expect(strings.achievementTitle(achievement), isNotEmpty,
            reason: '${achievement.id} title ($language)');
        expect(strings.achievementDescription(achievement), isNotEmpty,
            reason: '${achievement.id} description ($language)');
        expect(
            strings.achievementTitle(achievement), isNot(achievement.titleEn),
            reason: '${achievement.id} title fell back ($language)');
        expect(strings.achievementDescription(achievement),
            isNot(achievement.descriptionEn),
            reason: '${achievement.id} description fell back ($language)');
      }
    }
  });

  test('all 1000 generated adventures have localized content', () {
    final adventures = AdventureCatalog.byId.values;
    expect(adventures, hasLength(1000));
    for (final language in translatedLanguages) {
      final strings = AppStrings(language);
      for (final adventure in adventures) {
        expect(translatedAdventureTitle(adventure, language), isNotNull,
            reason: '${adventure.id} title ($language)');
        expect(translatedAdventureDescription(adventure, language), isNotNull,
            reason: '${adventure.id} description ($language)');
        expect(strings.adventureTitle(adventure), isNotEmpty);
        expect(strings.adventureDescription(adventure), isNotEmpty);
      }
    }
  });

  test('all 200 furniture items have localized names and descriptions', () {
    expect(shopCatalog, hasLength(200));
    for (final language in translatedLanguages) {
      final strings = AppStrings(language);
      for (final item in shopCatalog) {
        expect(translatedItemName(item, language), isNotNull,
            reason: '${item.id} name ($language)');
        expect(translatedItemDescription(item, language), isNotNull,
            reason: '${item.id} description ($language)');
        expect(strings.itemName(item), isNotEmpty);
        expect(strings.itemDescription(item), isNotEmpty);
      }
    }
  });

  test('all 300 dragon sayings are unique and translated per language', () {
    expect(dragonDialogueLines, hasLength(300));
    for (final language in translatedLanguages) {
      final localized = <String>{
        for (final line in dragonDialogueLines) line.text(language),
      };
      expect(localized, hasLength(300), reason: language);
      for (final line in dragonDialogueLines) {
        expect(line.text(language), isNot(line.text('en')),
            reason: '${line.id} ($language)');
      }
    }
  });

  test('English and Dutch authored dialogue remain complete', () {
    for (final language in const ['en', 'nl']) {
      expect(
        {for (final line in dragonDialogueLines) line.text(language)},
        hasLength(300),
      );
    }
  });

  test('all translated stage labels are available', () {
    for (final language in translatedLanguages) {
      final strings = AppStrings(language);
      for (final stage in const [
        'moonEgg',
        'spark',
        'nestDragon',
        'homeGuardian'
      ]) {
        expect(strings.petStageNameByKey(stage), isNotEmpty);
      }
    }
  });

  test('all relics, alignments and personality traits are localized', () {
    for (final language in translatedLanguages) {
      final strings = AppStrings(language);
      for (final relic in MysticRelic.values) {
        expect(strings.relicName(relic), isNot(relic.nameEn),
            reason: '${relic.name} name ($language)');
        expect(strings.relicDescription(relic), isNot(relic.descriptionEn),
            reason: '${relic.name} description ($language)');
      }
      for (final trait in dragonPersonalityTraits) {
        expect(strings.personality(trait), isNot(trait),
            reason: '$trait ($language)');
      }
      for (final value in LawAxis.values) {
        expect(strings.lawAxisName(value), isNotEmpty);
      }
      for (final value in MoralAxis.values) {
        expect(strings.moralAxisName(value), isNotEmpty);
      }
    }
  });
}
