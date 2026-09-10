import 'dart:convert';
import 'dart:io';

class ReferenceDocumentSpec {
  const ReferenceDocumentSpec({
    required this.documentPath,
    required this.sourcePaths,
  });

  final String documentPath;
  final List<String> sourcePaths;
}

const specialContentReference = ReferenceDocumentSpec(
  documentPath: 'SPECIAL_EVENTS_CHESTS_AND_EGGS.md',
  sourcePaths: [
    'lib/domain/game_command_engine.dart',
    'lib/domain/school_attempts.dart',
    'lib/models/school_lesson_game.dart',
    'lib/models/game_input_transcript.dart',
    'lib/models/game_command_schema.dart',
    'lib/domain/game_asset_snapshot.dart',
    'lib/domain/game_state_envelope.dart',
    'lib/domain/game_import_preparation.dart',
    'lib/domain/game_public_projection.dart',
    'supabase/migrations/202609070052_canonical_game_commands.sql',
    'supabase/migrations/202609070053_canonical_import_preparation.sql',
    'lib/models/achievement.dart',
    'lib/models/adventure.dart',
    'lib/models/chest.dart',
    'lib/models/day_phase.dart',
    'lib/models/house.dart',
    'lib/models/dragon_egg.dart',
    'lib/models/dragon_sex.dart',
    'lib/models/egg_altar.dart',
    'lib/providers/egg_altar_systems.dart',
    'lib/models/dragon_lineage.dart',
    'lib/models/music_track.dart',
    'lib/models/mystic_relic.dart',
    'lib/providers/dragonhaven_systems.dart',
    'lib/providers/household_provider.dart',
    'lib/screens/adventure_hub_screen.dart',
    'lib/widgets/seasonal_app_frame.dart',
    'lib/theme/event_appearance.dart',
    'lib/services/event_branding_service.dart',
    'android/app/src/main/kotlin/nl/dragonhaven/app/EventBranding.kt',
    'android/app/src/main/AndroidManifest.xml',
    'tool/build_event_branding_icons.dart',
    'tool/halloween_trial_calibration_report.sql',
    'lib/screens/egg_altar_screen.dart',
    'lib/screens/canonical_altar_screen.dart',
    'lib/screens/canonical_eggs.dart',
    'lib/screens/canonical_adventures_screen.dart',
    'lib/screens/canonical_dragons_screen.dart',
    'lib/services/canonical_game_snapshot.dart',
    'lib/services/canonical_game_actions.dart',
    'lib/screens/inventory_screen.dart',
    'lib/widgets/egg_altar_scene.dart',
    'lib/screens/seasonal_trial_game.dart',
    'lib/models/seasonal_minigame.dart',
    'lib/models/sunwake_surf.dart',
    'lib/models/trial_random.dart',
    'lib/models/trial_input.dart',
    'lib/models/classic_trial_game.dart',
    'lib/models/seasonal_arcade_game.dart',
    'lib/models/witchlight_trace.dart',
    'lib/models/moonlit_orchard.dart',
    'lib/models/seasonal_conclave_project.dart',
    'lib/widgets/summer_trials.dart',
    'lib/widgets/seasonal_conclave_project_card.dart',
    'tool/build_sunwake_harvestmoon_music.dart',
    'lib/models/wishcake_tower.dart',
    'lib/widgets/wishcake_trial.dart',
    'tool/build_birthday_song.dart',
    'lib/widgets/seasonal_minigames.dart',
    'lib/widgets/witchlight_trial_widgets.dart',
    'lib/services/notification_service.dart',
    'supabase/migrations/202608290026_special_chest_trade_support.sql',
    'supabase/migrations/202609070040_seasonal_events.sql',
    'supabase/migrations/202609070041_seasonal_event_lint_fixes.sql',
    'supabase/migrations/202609070042_egg_altar.sql',
    'supabase/migrations/202609070043_witchlight_three_mistakes.sql',
    'supabase/migrations/202609090061_seasonal_three_strikes.sql',
    'supabase/migrations/202609090063_birthday_trial.sql',
    'supabase/migrations/202609090064_sunwake_harvestmoon.sql',
    'supabase/migrations/202609090065_seasonal_podium_chat.sql',
    'supabase/migrations/202609100066_endless_sunwake.sql',
    'supabase/migrations/202609070044_sinister_altar_rewards.sql',
    'supabase/migrations/202609070048_halloween_preview_access.sql',
    'supabase/migrations/202609080059_single_active_event_preview.sql',
    'supabase/migrations/202609090060_end_active_event.sql',
    'supabase/migrations/202609090062_seasonal_preview_access.sql',
    'supabase/migrations/202609070045_dormant_chest_opening.sql',
    'supabase/migrations/202609080058_equipment_relic_pool.sql',
    'tool/economy_chest_catalog.dart',
  ],
);

const randomRewardsReference = ReferenceDocumentSpec(
  documentPath: 'RANDOM_REWARDS_AND_ODDS.md',
  sourcePaths: [
    'lib/domain/game_command_engine.dart',
    'lib/domain/school_attempts.dart',
    'lib/models/school_lesson_game.dart',
    'lib/models/game_input_transcript.dart',
    'lib/models/game_command_schema.dart',
    'lib/domain/game_asset_snapshot.dart',
    'lib/domain/game_state_envelope.dart',
    'lib/domain/game_import_preparation.dart',
    'lib/domain/server_entropy.dart',
    'supabase/migrations/202609070052_canonical_game_commands.sql',
    'supabase/migrations/202609070053_canonical_import_preparation.sql',
    'android/app/src/main/kotlin/nl/dragonhaven/app/MainActivity.kt',
    'android/app/src/main/kotlin/nl/dragonhaven/app/JukeboxQueue.kt',
    'lib/models/account_title.dart',
    'lib/models/adventure.dart',
    'lib/models/chest.dart',
    'lib/models/day_phase.dart',
    'lib/models/house.dart',
    'lib/models/dragon_emote.dart',
    'lib/models/egg_altar.dart',
    'lib/providers/egg_altar_systems.dart',
    'lib/screens/seasonal_trial_game.dart',
    'lib/models/seasonal_minigame.dart',
    'lib/models/sunwake_surf.dart',
    'lib/models/trial_random.dart',
    'lib/models/trial_input.dart',
    'lib/models/classic_trial_game.dart',
    'lib/models/seasonal_arcade_game.dart',
    'lib/models/witchlight_trace.dart',
    'lib/models/moonlit_orchard.dart',
    'lib/models/seasonal_conclave_project.dart',
    'lib/widgets/summer_trials.dart',
    'lib/widgets/seasonal_conclave_project_card.dart',
    'tool/build_sunwake_harvestmoon_music.dart',
    'lib/models/wishcake_tower.dart',
    'lib/widgets/wishcake_trial.dart',
    'tool/build_birthday_song.dart',
    'lib/widgets/seasonal_minigames.dart',
    'lib/widgets/witchlight_trial_widgets.dart',
    'lib/models/dragon_egg.dart',
    'lib/models/dragon_sex.dart',
    'lib/models/dragon_lineage.dart',
    'lib/models/music_track.dart',
    'lib/models/mystic_relic.dart',
    'lib/models/pet.dart',
    'lib/models/profile_portrait.dart',
    'lib/models/trial.dart',
    'lib/providers/dragonhaven_systems.dart',
    'lib/providers/household_provider.dart',
    'lib/screens/dragon_school_screen.dart',
    'lib/screens/house_screen.dart',
    'lib/screens/trial_game_screen.dart',
    'supabase/migrations/202608240007_group_adventure_duration_rules.sql',
    'supabase/migrations/202609070042_egg_altar.sql',
    'supabase/migrations/202609070043_witchlight_three_mistakes.sql',
    'supabase/migrations/202609090061_seasonal_three_strikes.sql',
    'supabase/migrations/202609090063_birthday_trial.sql',
    'supabase/migrations/202609090064_sunwake_harvestmoon.sql',
    'supabase/migrations/202609090065_seasonal_podium_chat.sql',
    'supabase/migrations/202609100066_endless_sunwake.sql',
    'supabase/migrations/202609070044_sinister_altar_rewards.sql',
    'supabase/migrations/202609070045_dormant_chest_opening.sql',
    'supabase/migrations/202609080058_equipment_relic_pool.sql',
    'tool/economy_chest_catalog.dart',
    'supabase/migrations/202609070040_seasonal_events.sql',
    'supabase/migrations/202609070041_seasonal_event_lint_fixes.sql',
  ],
);

const redeemCodesReference = ReferenceDocumentSpec(
  documentPath: 'REDEEM_CODES.md',
  sourcePaths: [
    'lib/domain/game_command_engine.dart',
    'lib/domain/school_attempts.dart',
    'lib/models/school_lesson_game.dart',
    'lib/models/game_input_transcript.dart',
    'lib/models/game_command_schema.dart',
    'lib/models/adventure.dart',
    'lib/models/dragon_emote.dart',
    'lib/models/redeem_code.dart',
    'supabase/migrations/202609070040_seasonal_events.sql',
    'supabase/migrations/202609070041_seasonal_event_lint_fixes.sql',
    'supabase/migrations/202609070048_halloween_preview_access.sql',
    'supabase/migrations/202609080059_single_active_event_preview.sql',
    'supabase/migrations/202609090060_end_active_event.sql',
    'supabase/migrations/202609090062_seasonal_preview_access.sql',
    'supabase/migrations/202609090063_birthday_trial.sql',
    'supabase/migrations/202609090064_sunwake_harvestmoon.sql',
    'supabase/migrations/202609090065_seasonal_podium_chat.sql',
    'supabase/migrations/202609100066_endless_sunwake.sql',
  ],
);

const referenceDocuments = [
  specialContentReference,
  randomRewardsReference,
  redeemCodesReference,
];

const _markerPrefix = '<!-- reference-source-fingerprint: ';
final _markerPattern = RegExp(
  r'<!-- reference-source-fingerprint: ([0-9a-f]{16}|PENDING) -->',
);
final _fnvOffsetBasis = BigInt.parse('cbf29ce484222325', radix: 16);
final _fnvPrime = BigInt.parse('100000001b3', radix: 16);
final _uint64Mask = BigInt.parse('ffffffffffffffff', radix: 16);

String calculateReferenceFingerprint(
  ReferenceDocumentSpec spec, {
  Directory? root,
}) {
  final repository = root ?? Directory.current;
  var hash = _fnvOffsetBasis;
  final paths = [...spec.sourcePaths]..sort();
  for (final path in paths) {
    final file = File('${repository.path}${Platform.pathSeparator}$path');
    if (!file.existsSync()) {
      throw StateError('Reference source does not exist: $path');
    }
    for (final byte in utf8.encode(path)) {
      hash = ((hash ^ BigInt.from(byte)) * _fnvPrime) & _uint64Mask;
    }
    hash = ((hash ^ BigInt.zero) * _fnvPrime) & _uint64Mask;
    // Git can materialize text files with CRLF on Windows and LF on Linux.
    // Hash the normalized repository content so a documentation marker made
    // on one release workstation remains valid on every CI runner.
    final normalizedContents =
        file.readAsStringSync().replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    for (final byte in utf8.encode(normalizedContents)) {
      hash = ((hash ^ BigInt.from(byte)) * _fnvPrime) & _uint64Mask;
    }
    hash = ((hash ^ BigInt.from(0xff)) * _fnvPrime) & _uint64Mask;
  }
  return hash.toRadixString(16).padLeft(16, '0');
}

String? documentedReferenceFingerprint(
  ReferenceDocumentSpec spec, {
  Directory? root,
}) {
  final repository = root ?? Directory.current;
  final document =
      File('${repository.path}${Platform.pathSeparator}${spec.documentPath}');
  if (!document.existsSync()) return null;
  return _markerPattern.firstMatch(document.readAsStringSync())?.group(1);
}

List<String> verifyReferenceDocuments({Directory? root}) {
  final failures = <String>[];
  for (final spec in referenceDocuments) {
    final expected = calculateReferenceFingerprint(spec, root: root);
    final documented = documentedReferenceFingerprint(spec, root: root);
    if (documented != expected) {
      failures.add(
        '${spec.documentPath}: documented ${documented ?? 'missing'}, '
        'expected $expected. Review the document and run '
        '`dart run tool/reference_documentation_guard.dart --update`.',
      );
    }
  }
  return failures;
}

void updateReferenceDocuments({Directory? root}) {
  final repository = root ?? Directory.current;
  for (final spec in referenceDocuments) {
    final document =
        File('${repository.path}${Platform.pathSeparator}${spec.documentPath}');
    if (!document.existsSync()) {
      throw StateError(
          'Reference document does not exist: ${spec.documentPath}');
    }
    final fingerprint = calculateReferenceFingerprint(spec, root: repository);
    final contents = document.readAsStringSync();
    final marker = '$_markerPrefix$fingerprint -->';
    if (!_markerPattern.hasMatch(contents)) {
      throw StateError(
        '${spec.documentPath} is missing the reference fingerprint marker.',
      );
    }
    document.writeAsStringSync(contents.replaceFirst(_markerPattern, marker));
    stdout.writeln('${spec.documentPath}: $fingerprint');
  }
}

void main(List<String> arguments) {
  if (arguments.length != 1 ||
      !const {'--verify', '--update', '--print'}.contains(arguments.single)) {
    stderr.writeln(
      'Usage: dart run tool/reference_documentation_guard.dart '
      '--verify|--update|--print',
    );
    exitCode = 64;
    return;
  }

  switch (arguments.single) {
    case '--update':
      updateReferenceDocuments();
    case '--print':
      for (final spec in referenceDocuments) {
        stdout.writeln(
          '${spec.documentPath}: ${calculateReferenceFingerprint(spec)}',
        );
      }
    case '--verify':
      final failures = verifyReferenceDocuments();
      if (failures.isEmpty) {
        stdout.writeln('Reference documentation is synchronized.');
        return;
      }
      for (final failure in failures) {
        stderr.writeln(failure);
      }
      exitCode = 1;
  }
}
