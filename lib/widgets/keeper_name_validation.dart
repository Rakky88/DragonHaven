import '../l10n/app_strings.dart';
import '../models/keeper_name_policy.dart';

String? keeperNameValidationMessage(AppStrings strings, String? value) =>
    switch (KeeperNamePolicy.issue(value ?? '')) {
      KeeperNameIssue.empty =>
        strings.pick('Choose a name first.', 'Kies eerst een naam.'),
      KeeperNameIssue.tooLong => strings.pick(
          'Use 24 characters or fewer.', 'Gebruik maximaal 24 tekens.'),
      KeeperNameIssue.controlCharacters => strings.pick(
          'Choose a name without line breaks or control characters.',
          'Kies een naam zonder regeleinden of besturingstekens.'),
      KeeperNameIssue.inappropriate => strings.pick(
          'Choose a different name. Offensive words are not allowed.',
          'Kies een andere naam. Scheldwoorden zijn niet toegestaan.'),
      null => null,
    };
