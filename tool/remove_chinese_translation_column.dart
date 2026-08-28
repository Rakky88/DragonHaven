import 'dart:io';

const _targets = [
  'lib/l10n/ui_phrase_translations.dart',
  'lib/l10n/notification_phrase_translations.dart',
  'lib/l10n/trial_phrase_translations.dart',
];

void main() {
  for (final path in _targets) {
    final file = File(path);
    var source = file.readAsStringSync();
    final removals = <({int start, int end})>[];
    for (var open = 0; open < source.length; open++) {
      if (source.codeUnitAt(open) != 0x5b) continue;
      final close = _matchingBracket(source, open);
      if (close == null) continue;
      final commas = _topLevelCommas(source, open + 1, close);
      if (commas.length != 7) continue; // Seven values plus a trailing comma.
      final elements = <String>[];
      var start = open + 1;
      for (final comma in commas) {
        elements.add(source.substring(start, comma).trim());
        start = comma + 1;
      }
      if (elements.length != 7 ||
          elements.any((value) => !(value.startsWith("'") ||
              value.startsWith('"') ||
              value.startsWith("r'") ||
              value.startsWith('r"')))) {
        continue;
      }
      removals.add((start: commas[4] + 1, end: commas[5] + 1));
      open = close;
    }
    for (final removal in removals.reversed) {
      source = source.replaceRange(removal.start, removal.end, '');
    }
    file.writeAsStringSync(source);
    stdout.writeln(
      '$path: removed ${removals.length} Chinese translation values',
    );
  }
}

int? _matchingBracket(String source, int open) {
  var depth = 0;
  String? quote;
  var escaped = false;
  for (var index = open; index < source.length; index++) {
    final char = source[index];
    if (quote != null) {
      if (escaped) {
        escaped = false;
      } else if (char == r'\') {
        escaped = true;
      } else if (char == quote) {
        quote = null;
      }
      continue;
    }
    if (char == "'" || char == '"') {
      quote = char;
    } else if (char == '[') {
      depth++;
    } else if (char == ']') {
      depth--;
      if (depth == 0) return index;
    }
  }
  return null;
}

List<int> _topLevelCommas(String source, int start, int end) {
  final commas = <int>[];
  var nested = 0;
  String? quote;
  var escaped = false;
  for (var index = start; index < end; index++) {
    final char = source[index];
    if (quote != null) {
      if (escaped) {
        escaped = false;
      } else if (char == r'\') {
        escaped = true;
      } else if (char == quote) {
        quote = null;
      }
      continue;
    }
    if (char == "'" || char == '"') {
      quote = char;
    } else if (char == '[' || char == '(' || char == '{') {
      nested++;
    } else if (char == ']' || char == ')' || char == '}') {
      nested--;
    } else if (char == ',' && nested == 0) {
      commas.add(index);
    }
  }
  return commas;
}
