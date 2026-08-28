import 'dart:io';

import 'package:dragon_haven/l10n/notification_phrase_translations.dart';
import 'package:dragon_haven/l10n/trial_phrase_translations.dart';
import 'package:dragon_haven/l10n/ui_phrase_translations.dart';

void main() {
  final maps = <String, Map<String, List<String>>>{
    'notifications': notificationPhraseTranslations,
    'trials': trialPhraseTranslations,
    'ui': uiPhraseTranslations,
  };
  var invalid = 0;
  for (final map in maps.entries) {
    for (final entry in map.value.entries) {
      if (entry.value.length == 6) continue;
      invalid++;
      stdout.writeln('${map.key}: ${entry.value.length}: ${entry.key}');
    }
  }
  if (invalid != 0) {
    throw StateError('$invalid translation entries do not contain 6 values.');
  }

  final fixedPhrases = <String>{};
  final pickPattern = RegExp(
    r"\.pick\(\s*'((?:\\.|[^'])*)'\s*,",
    multiLine: true,
  );
  for (final file in Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))) {
    for (final match in pickPattern.allMatches(file.readAsStringSync())) {
      final phrase =
          match.group(1)!.replaceAll(r"\'", "'").replaceAll(r'\\', r'\');
      if (!phrase.contains(r'$') && translatedUiPhrase(phrase, 'de') == null) {
        fixedPhrases.add(phrase);
      }
    }
  }
  if (fixedPhrases.isNotEmpty) {
    for (final phrase in fixedPhrases) {
      stdout.writeln(phrase);
    }
    throw StateError('${fixedPhrases.length} fixed phrases are untranslated.');
  }
}
