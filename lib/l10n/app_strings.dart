import 'package:flutter/material.dart';

import '../services/release_service.dart';
import 'game_strings.dart';

/// Flutter context and release-screen adapter for the shared translations.
class AppStrings extends GameStrings {
  const AppStrings(super.languageCode);

  static const supportedLanguages = GameStrings.supportedLanguages;

  static AppStrings of(BuildContext context) =>
      AppStrings(Localizations.localeOf(context).languageCode);

  String releaseError(ReleaseException error) => switch (error.code) {
        ReleaseErrorCode.notConfigured => pick(
            'The GitHub repository is not connected yet. Build with '
                '--dart-define=DRAGONHAVEN_GITHUB_OWNER=yourname.',
            'De GitHub-repository is nog niet gekoppeld. Bouw met '
                '--dart-define=DRAGONHAVEN_GITHUB_OWNER=jouwnaam.'),
        ReleaseErrorCode.noRelease => pick(
            'No public GitHub Release has been published yet.',
            'Er is nog geen openbare GitHub Release gevonden.'),
        ReleaseErrorCode.httpError => pick(
            'GitHub could not be checked (code ${error.statusCode}).',
            'GitHub kon niet worden gecontroleerd (code ${error.statusCode}).'),
        ReleaseErrorCode.invalidData => pick(
            'The latest release contains no valid version data.',
            'De nieuwste release bevat geen geldige versiegegevens.'),
        ReleaseErrorCode.offline => pick(
            'No internet connection. Please try again later.',
            'Geen internetverbinding. Probeer het later opnieuw.'),
        ReleaseErrorCode.handshake => pick(
            'The secure connection to GitHub failed.',
            'De beveiligde verbinding met GitHub is mislukt.'),
        ReleaseErrorCode.format => pick(
            'GitHub returned unexpected release data.',
            'GitHub gaf onverwachte releasegegevens terug.'),
        ReleaseErrorCode.timeout => pick('The release check took too long.',
            'Het controleren van de release duurde te lang.'),
      };
}
