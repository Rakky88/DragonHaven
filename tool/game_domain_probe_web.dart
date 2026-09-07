import 'dart:convert';
import 'dart:js_interop';

import 'game_domain_probe.dart' show runGameDomainProbe;

@JS('dragonhavenProbe')
external set _probe(JSFunction value);

void main() {
  _probe = (() =>
      runGameDomainProbe().then((result) => jsonEncode(result).toJS).toJS).toJS;
}
