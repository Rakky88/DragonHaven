enum KeeperNameIssue { empty, tooLong, controlCharacters, inappropriate }

abstract final class KeeperNamePolicy {
  static const maximumLength = 24;

  static const _embeddedBlockedTerms = <String>{
    'bastard',
    'bitch',
    'bollock',
    'cunt',
    'debiel',
    'dick',
    'douchebag',
    'eikel',
    'fagg',
    'fuck',
    'godverdom',
    'hoer',
    'idioot',
    'kanker',
    'klere',
    'klote',
    'klotzak',
    'klootzak',
    'kut',
    'lul',
    'mongool',
    'motherfucker',
    'neuk',
    'nigg',
    'pussy',
    'retard',
    'shit',
    'slet',
    'slut',
    'sukkel',
    'teef',
    'tering',
    'trut',
    'twat',
    'tyfus',
    'wanker',
    'whore',
    'wijf',
  };

  static KeeperNameIssue? issue(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return KeeperNameIssue.empty;
    if (trimmed.length > maximumLength) return KeeperNameIssue.tooLong;
    if (RegExp(r'[\x00-\x1f\x7f]').hasMatch(trimmed)) {
      return KeeperNameIssue.controlCharacters;
    }

    final folded = _fold(trimmed);
    final compact = folded.replaceAll(RegExp('[^a-z0-9]'), '');
    if (_embeddedBlockedTerms.any(compact.contains)) {
      return KeeperNameIssue.inappropriate;
    }
    return null;
  }

  static bool isAllowed(String value) => issue(value) == null;

  static String normalize(String value) => value.trim();

  static String _fold(String value) {
    const replacements = <String, String>{
      '0': 'o',
      '1': 'i',
      '3': 'e',
      '4': 'a',
      '5': 's',
      '7': 't',
      '8': 'b',
      '@': 'a',
      r'$': 's',
      '!': 'i',
      'á': 'a',
      'à': 'a',
      'â': 'a',
      'ä': 'a',
      'ã': 'a',
      'å': 'a',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'í': 'i',
      'ì': 'i',
      'î': 'i',
      'ï': 'i',
      'ó': 'o',
      'ò': 'o',
      'ô': 'o',
      'ö': 'o',
      'õ': 'o',
      'ú': 'u',
      'ù': 'u',
      'û': 'u',
      'ü': 'u',
      'ç': 'c',
      'ñ': 'n',
    };
    final buffer = StringBuffer();
    for (final rune in value.toLowerCase().runes) {
      final character = String.fromCharCode(rune);
      buffer.write(replacements[character] ?? character);
    }
    return buffer.toString();
  }
}
