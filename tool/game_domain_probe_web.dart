import 'dart:convert';
import 'dart:js_interop';

import 'game_domain_probe.dart' show runGameDomainProbe;

@JS('dragonhavenProbe')
external set _probe(JSFunction value);

Future<JSString> _run() async {
  try {
    return jsonEncode(await runGameDomainProbe(includeTrialCommands: true))
        .toJS;
  } catch (error, stack) {
    throw StateError('domain_probe_failure: $error\n$stack');
  }
}

void main() {
  _probe = (() => _run().toJS).toJS;
}
