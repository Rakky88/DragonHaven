import 'dart:convert';
import 'dart:js_interop';

import 'package:dragon_haven/domain/game_command_engine.dart';

@JS('dragonhavenGameCommand')
external set _command(JSFunction value);

/// Loaded only inside the trusted Edge worker. There is no network listener
/// here and no public path accepting a saved game, entropy seed or clock.
void main() {
  _command = ((JSString input) => _execute(input.toDart).toJS).toJS;
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
