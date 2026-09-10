import 'dart:convert';
import 'dart:js_interop';

import 'package:dragon_haven/domain/game_command_engine.dart';
import 'package:dragon_haven/domain/game_import_preparation.dart';
import 'package:dragon_haven/domain/game_public_projection.dart';

@JS('dragonhavenGameCommand')
external set _command(JSFunction value);

@JS('dragonhavenPrepareGameImport')
external set _prepareImport(JSFunction value);

@JS('dragonhavenProjectGame')
external set _projectGame(JSFunction value);

/// Loaded only inside the trusted Edge worker. There is no network listener
/// here and no public path accepting a saved game, entropy seed or clock.
void main() {
  _command = ((JSString input) => _execute(input.toDart).toJS).toJS;
  _prepareImport = ((JSString input) => _prepare(input.toDart).toJS).toJS;
  _projectGame = ((JSString input) => _project(input.toDart).toJS).toJS;
}

String _project(String input) {
  final data = jsonDecode(input) as Map<String, dynamic>;
  try {
    return jsonEncode(GamePublicProjection.project(
      state: data['state'] as Map<String, dynamic>,
      ownerId: data['ownerId'] as String,
      verifiedSocialClaims:
          data['verifiedSocialClaims'] as List<dynamic>? ?? const [],
      now: DateTime.parse(data['now'] as String),
    ));
  } on FormatException {
    return jsonEncode({'error': 'game_state_reconciliation_required'});
  }
}

String _prepare(String input) {
  final data = jsonDecode(input) as Map<String, dynamic>;
  try {
    final result = GameImportPreparation.prepare(
      ownerId: data['ownerId'] as String,
      source: data['source'] as Map<String, dynamic>,
      authoritativeAltar: data['authoritativeAltar'] as Map<String, dynamic>?,
      now: DateTime.parse(data['now'] as String),
      secretSeed: data['secretSeed'] as String,
    );
    return jsonEncode({
      'protocol': 2,
      'state': result.state,
      'changed_asset_kinds': result.changedAssetKinds.toList()..sort(),
      'altar_revision': result.altarRevision
    });
  } on GameImportException catch (error) {
    return jsonEncode({'error': error.code});
  } on FormatException {
    return jsonEncode({'error': 'game_import_reconciliation_required'});
  }
}

Future<JSString> _execute(String input) async {
  final data = jsonDecode(input) as Map<String, dynamic>;
  try {
    return jsonEncode(await GameCommandEngine.execute(
      state: data['state'] as Map<String, dynamic>,
      action: data['action'] as String,
      payload: data['payload'] as Map<String, dynamic>,
      secretSeed: data['secretSeed'] as String,
      now: DateTime.parse(data['now'] as String),
      keeperId: data['keeperId'] as String,
      verifiedSocialContext:
          data['verifiedSocialContext'] as Map<String, dynamic>?,
    ))
        .toJS;
  } on GameCommandException catch (error) {
    return jsonEncode({'error': error.code}).toJS;
  } on FormatException {
    // A legacy save needs explicit reconciliation. Never expose save content
    // or the normalizer's detailed exception to the caller.
    return jsonEncode({'error': 'game_state_reconciliation_required'}).toJS;
  }
}
